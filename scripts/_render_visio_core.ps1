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
if (-not $Force -and ((Test-Path -LiteralPath $vsdxPath) -or (Test-Path -LiteralPath $pngPath))) {
    throw 'Output already exists. Use -Force only after confirming overwrite.'
}

$visio = $null
$doc = $null
$page = $null
$shapeMap = @{}
$nodeMap = @{}

try {
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = [bool]$Visible
    $doc = $visio.Documents.Add('')
    $page = $visio.ActivePage

    [double]$pageWidth = if ($spec.page.width) { $spec.page.width } else { 24.0 }
    [double]$pageHeight = if ($spec.page.height) { $spec.page.height } else { 16.0 }
    $page.PageSheet.CellsU('PageWidth').ResultIU = $pageWidth
    $page.PageSheet.CellsU('PageHeight').ResultIU = $pageHeight

    if ($spec.title) {
        $title = $page.DrawRectangle(1.0, ($pageHeight - 1.2), ($pageWidth - 1.0), ($pageHeight - 0.2))
        $title.Text = [string]$spec.title
        Set-CellFormula $title 'FillPattern' '0'
        Set-CellFormula $title 'LinePattern' '0'
        Set-CellFormula $title 'Char.Size' '18 pt'
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
        [double]$w = if ($node.w) { $node.w } else { 4.5 }
        [double]$h = if ($node.h) { $node.h } else { 1.1 }
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
        Set-CellFormula $shape 'Char.Size' '11 pt'
        Set-CellFormula $shape 'Char.Color' (Convert-HexToRgbFormula '#1F1F1F')
        Set-CellFormula $shape 'Para.HorzAlign' '1'
        Set-CellFormula $shape 'VerticalAlign' '1'
        $shapeMap[$id] = $shape
        $nodeMap[$id] = @{ x = $x; y = $y }
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
            $line.Text = [string]$edge.label
            Set-CellFormula $line 'Char.Size' '9 pt'
        }
        try { $line.SendToBack() } catch { }
    }

    $doc.SaveAs($vsdxPath)
    $page.Export($pngPath)
    $doc.Close()
    $doc = $null
    $visio.Quit()

    [pscustomobject]@{
        status = 'PASS'
        vsdx = $vsdxPath
        png = $pngPath
        nodes = $spec.nodes.Count
        edges = @($spec.edges).Count
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
