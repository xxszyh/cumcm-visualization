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
$coreJson = & $core -SpecPath $SpecPath -OutputBase $OutputBase -Visible:$Visible -Force:$Force
$coreResult = $coreJson | ConvertFrom-Json

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
$settingsCaptured = $false

try {
    # This is a dedicated hidden COM instance.  Its raster settings are
    # captured before the 300-DPI export and restored before the instance is
    # closed, so the user's interactive Visio settings are not retained.
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
    $settingsCaptured = $true

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

    [pscustomobject]@{
        status = 'PASS'
        vsdx = $vsdxPath
        png = $pngPath
        typography_report = $coreResult.typography_report
        nodes = $coreResult.nodes
        edges = $coreResult.edges
        final_width_in = $coreResult.final_width_in
        scale_factor = $coreResult.scale_factor
        raster_dpi = 300
    } | ConvertTo-Json
}
finally {
    if ($settings -and $settingsCaptured) {
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
