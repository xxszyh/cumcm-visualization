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

function Release-ComObject($Object) {
    if ($Object -and [Runtime.InteropServices.Marshal]::IsComObject($Object)) {
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($Object)
    }
}

$core = Join-Path $PSScriptRoot '_render_visio_core.ps1'
& $core -SpecPath $SpecPath -OutputBase $OutputBase -Visible:$Visible -Force:$Force

$basePath = [IO.Path]::GetFullPath($OutputBase)
$vsdxPath = "$basePath.vsdx"
$pngPath = "$basePath.png"
$visio = $null
$settings = $null
$doc = $null
$page = $null
$previousResolution = 0
$previousWidth = 0.0
$previousHeight = 0.0
$previousUnits = 0

try {
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = $false
    $settings = $visio.Settings

    $resolutionRef = [ref]$previousResolution
    $widthRef = [ref]$previousWidth
    $heightRef = [ref]$previousHeight
    $unitsRef = [ref]$previousUnits
    $settings.GetRasterExportResolution(
        $resolutionRef,
        $widthRef,
        $heightRef,
        $unitsRef
    )
    $previousResolution = $resolutionRef.Value
    $previousWidth = $widthRef.Value
    $previousHeight = $heightRef.Value
    $previousUnits = $unitsRef.Value

    $settings.SetRasterExportResolution(3, 300.0, 300.0, 0)
    $doc = $visio.Documents.Open($vsdxPath)
    $page = $doc.Pages.Item(1)
    $page.Export($pngPath)
    $settings.SetRasterExportResolution(
        $previousResolution,
        $previousWidth,
        $previousHeight,
        $previousUnits
    )
    $doc.Close()
    $doc = $null
    $visio.Quit()
}
finally {
    if ($settings) {
        try {
            $settings.SetRasterExportResolution(
                $previousResolution,
                $previousWidth,
                $previousHeight,
                $previousUnits
            )
        } catch { }
    }
    if ($doc) { try { $doc.Close() } catch { } }
    if ($visio) { try { $visio.Quit() } catch { } }
    foreach ($comObject in @($page, $doc, $settings, $visio)) {
        Release-ComObject $comObject
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
