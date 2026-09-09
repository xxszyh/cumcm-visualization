#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SpecPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputBase,
    [switch]$Visible,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Convert-HexToRgbFormula([string]$Hex) {
    $clean = $Hex.Trim().TrimStart('#')
    if ($clean.Length -ne 6) { throw "Invalid color: $Hex" }
    $r = [Convert]::ToInt32($clean.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($clean.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($clean.Substring(4, 2), 16)
    "RGB($r,$g,$b)"
}

function Set-CellFormula($Shape, [string]$CellName, [string]$Formula) {
    if ($Shape.CellExistsU($CellName, 0)) {
        $Shape.CellsU($CellName).FormulaU = $Formula
    }
}

function Get-NumberOrDefault($Object, [string]$PropertyName, [double]$DefaultValue) {
    if ($null -eq $Object) { return $DefaultValue }
    $property = $Object.PSObject.Properties[$PropertyName]
    if ($null -eq $property -or $null -eq $property.Value) { return $DefaultValue }
    $text = [string]$property.Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $DefaultValue }
    return [double]$property.Value
}

function Format-PointFormula([double]$Value) {
    $number = $Value.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture)
    "$number pt"
}

function Assert-MinimumFont([string]$Role, [double]$Value, [double]$Minimum) {
    if ($Value -lt $Minimum) {
        throw "$Role final font size is $Value pt; minimum is $Minimum pt. Increase the final font target or split the figure."
    }
}

$resolvedSpec = (Resolve-Path -LiteralPath $SpecPath).Path
$spec = Get-Content -LiteralPath $resolvedSpec -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $spec.nodes -or $spec.nodes.Count -eq 0) {
    throw 'The specification must contain at least one node.'
}

$basePath = [IO.Path]::GetFullPath($OutputBase)
$parent = Split-Path -Parent $basePath
if (-not $parent) {
    $parent = (Get-Location).Path
    $basePath = Join-Path $parent $OutputBase
}
New-Item -ItemType Directory -Force -Path $parent | Out-Null
$vsdxPath = "$basePath.vsdx"
$pngPath = "$basePath.png"
$typographyPath = "$basePath.typography.json"
if (-not $Force -and ((Test-Path -LiteralPath $vsdxPath) -or (Test-Path -LiteralPath $pngPath) -or (Test-Path -LiteralPath $typographyPath))) {
    throw 'Output already exists. Use -Force only after confirming overwrite.'
}

[double]$pageWidth = Get-NumberOrDefault $spec.page 'width' 24.0
[double]$pageHeight = Get-NumberOrDefault $spec.page 'height' 16.0
[double]$finalWidth = Get-NumberOrDefault $spec.page 'final_width' 6.5
[double]$finalTitlePt = Get-NumberOrDefault $spec.typography 'title_final_pt' 13.0
[double]$finalNodePt = Get-NumberOrDefault $spec.typography 'node_final_pt' 9.5
[double]$finalEdgePt = Get-NumberOrDefault $spec.typography 'edge_final_pt' 8.0

[double]$minimumTitlePt = 10.0
[double]$minimumNodePt = 8.0
[double]$minimumEdgePt = 7.5

if ($pageWidth -le 0 -or $pageHeight -le 0) {
    throw 'Page width and height must be positive.'
}
if ($finalWidth -le 0) {
    throw 'page.final_width must be positive.'
}
Assert-MinimumFont 'Title' $finalTitlePt $minimumTitlePt
Assert-MinimumFont 'Node' $finalNodePt $minimumNodePt
Assert-MinimumFont 'Edge label' $finalEdgePt $minimumEdgePt

[double]$scaleFactor = $pageWidth / $finalWidth
[double]$titleSourcePt = $finalTitlePt * $scaleFactor
[double]$nodeSourcePt = $finalNodePt * $scaleFactor
[double]$edgeSourcePt = $finalEdgePt * $scaleFactor

$visio = $null
$doc = $null
$page = $null
$shapeMap = @{}
$nodeMap = @{}
$nodeTypography = @()
$edgeTypography = @()

try {
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = [bool]$Visible
    $doc = $visio.Documents.Add('')
    $page = $visio.ActivePage

    $page.PageSheet.CellsU('PageWidth').ResultIU = $pageWidth
    $page.PageSheet.CellsU('PageHeight').ResultIU = $pageHeight

    if ($spec.title) {
        $title = $page.DrawRectangle(1.0, ($pageHeight - 1.2), ($pageWidth - 1.0), ($pageHeight - 0.2))
        $title.Text = [string]$spec.title
        Set-CellFormula $title 'FillPattern' '0'
        Set-CellFormula $title 'LinePattern' '0'
        Set-CellFormula $title 'Char.Size' (Format-PointFormula $titleSourcePt)
        Set-CellFormula $title 'Char.Style' '1'
        Set-CellFormula $title 'Para.HorzAlign' '1'
        Set-CellFormula $title 'VerticalAlign' '1'
    }

    foreach ($node in $spec.nodes) {
        $id = [string]$node.id
        if ([string]::IsNullOrWhiteSpace($id) -or $shapeMap.ContainsKey($id)) {
            throw "Node ids must be non-empty and unique: $id"
        }
        [double]$x = $node.x
        [double]$y = $node.y
        [double]$w = Get-NumberOrDefault $node 'w' 4.5
        [double]$h = Get-NumberOrDefault $node 'h' 1.1
        [double]$nodeFinal = Get-NumberOrDefault $node 'font_final_pt' $finalNodePt
        Assert-MinimumFont "Node '$id'" $nodeFinal $minimumNodePt
        [double]$nodeSource = $nodeFinal * $scaleFactor
        $kind = if ($node.kind) { [string]$node.kind } else { 'process' }

        switch ($kind) {
            'terminal' {
                $shape = $page.DrawOval(($x - $w / 2), ($y - $h / 2), ($x + $w / 2), ($y + $h / 2))
                $fill = '#E8F1FB'
            }
            'decision' {
                [double[]]$points = @(
                    $x, ($y + $h / 2),
                    ($x + $w / 2), $y,
                    $x, ($y - $h / 2),
                    ($x - $w / 2), $y,
                    $x, ($y + $h / 2)
                )
                $shape = $page.DrawPolyline($points, 0)
                $fill = '#FFF2CC'
            }
            default {
                $shape = $page.DrawRectangle(($x - $w / 2), ($y - $h / 2), ($x + $w / 2), ($y + $h / 2))
                $fill = if ($kind -eq 'data') { '#E2F0D9' } else { '#D9E2F3' }
            }
        }

        if ($node.fill) { $fill = [string]$node.fill }
        $shape.Text = [string]$node.text
        Set-CellFormula $shape 'FillForegnd' (Convert-HexToRgbFormula $fill)
        Set-CellFormula $shape 'LineColor' (Convert-HexToRgbFormula '#44546A')
        Set-CellFormula $shape 'LineWeight' '1.2 pt'
        Set-CellFormula $shape 'Char.Size' (Format-PointFormula $nodeSource)
        Set-CellFormula $shape 'Char.Color' (Convert-HexToRgbFormula '#1F1F1F')
        Set-CellFormula $shape 'Para.HorzAlign' '1'
        Set-CellFormula $shape 'VerticalAlign' '1'
        $shapeMap[$id] = $shape
        $nodeMap[$id] = @{ x = $x; y = $y }
        $nodeTypography += [pscustomobject]@{
            id = $id
            final_pt = [math]::Round($nodeFinal, 3)
            source_pt = [math]::Round($nodeSource, 3)
        }
    }

    foreach ($edge in @($spec.edges)) {
        $fromId = [string]$edge.from
        $toId = [string]$edge.to
        if (-not $shapeMap.ContainsKey($fromId) -or -not $shapeMap.ContainsKey($toId)) {
            throw "Edge references an unknown node: $fromId -> $toId"
        }
        $from = $nodeMap[$fromId]
        $to = $nodeMap[$toId]
        $line = $page.DrawLine([double]$from.x, [double]$from.y, [double]$to.x, [double]$to.y)
        Set-CellFormula $line 'LineColor' (Convert-HexToRgbFormula '#5B6573')
        Set-CellFormula $line 'LineWeight' '1.1 pt'
        Set-CellFormula $line 'EndArrow' '13'
        if ($edge.dashed) { Set-CellFormula $line 'LinePattern' '2' }
        if ($edge.label) {
            [double]$edgeFinal = Get-NumberOrDefault $edge 'font_final_pt' $finalEdgePt
            Assert-MinimumFont "Edge '$fromId -> $toId'" $edgeFinal $minimumEdgePt
            [double]$edgeSource = $edgeFinal * $scaleFactor
            $line.Text = [string]$edge.label
            Set-CellFormula $line 'Char.Size' (Format-PointFormula $edgeSource)
            $edgeTypography += [pscustomobject]@{
                from = $fromId
                to = $toId
                final_pt = [math]::Round($edgeFinal, 3)
                source_pt = [math]::Round($edgeSource, 3)
            }
        }
        try { $line.SendToBack() } catch { }
    }

    $doc.SaveAs($vsdxPath)
    $page.Export($pngPath)

    $report = [pscustomobject]@{
        status = 'PASS'
        page_width_in = [math]::Round($pageWidth, 3)
        page_height_in = [math]::Round($pageHeight, 3)
        final_width_in = [math]::Round($finalWidth, 3)
        scale_factor = [math]::Round($scaleFactor, 6)
        minimum_final_pt = [pscustomobject]@{
            title = $minimumTitlePt
            node = $minimumNodePt
            edge_label = $minimumEdgePt
        }
        default_typography = [pscustomobject]@{
            title_final_pt = [math]::Round($finalTitlePt, 3)
            title_source_pt = [math]::Round($titleSourcePt, 3)
            node_final_pt = [math]::Round($finalNodePt, 3)
            node_source_pt = [math]::Round($nodeSourcePt, 3)
            edge_final_pt = [math]::Round($finalEdgePt, 3)
            edge_source_pt = [math]::Round($edgeSourcePt, 3)
        }
        nodes = $nodeTypography
        labelled_edges = $edgeTypography
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $typographyPath -Encoding UTF8

    $doc.Close()
    $doc = $null
    $visio.Quit()

    [pscustomobject]@{
        status = 'PASS'
        vsdx = $vsdxPath
        png = $pngPath
        typography_report = $typographyPath
        nodes = $spec.nodes.Count
        edges = @($spec.edges).Count
        final_width_in = [math]::Round($finalWidth, 3)
        scale_factor = [math]::Round($scaleFactor, 6)
    } | ConvertTo-Json
}
finally {
    if ($doc) { try { $doc.Close() } catch { } }
    if ($visio) { try { $visio.Quit() } catch { } }
    foreach ($comObject in @($page, $doc, $visio)) {
        if ($comObject -and [Runtime.InteropServices.Marshal]::IsComObject($comObject)) {
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject)
        }
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
