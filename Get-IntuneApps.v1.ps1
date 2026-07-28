# Get-IntuneApps.ps1 by RALBE
<#
.SYNOPSIS
    Retrieves installed applications from Intune devices and identifies apps not deployed via Intune.

.DESCRIPTION
    This script connects to Microsoft Graph and retrieves:
    - Intune managed apps
    - Detected apps across devices
    - Device associations for each app

    It compares detected apps against managed apps to identify:
    - Applications not deployed via Intune (potentially unmanaged)

    Supports filtering by:
    - App name
    - Device name
    - Device type (OS)

.PARAMETER Match
    Filters applications by name (partial match).

.PARAMETER Device
    Filters results to a specific device name (partial match supported).

.PARAMETER Type
    Filters devices by operating system.
    Accepted values: Windows, Mac, iOS, Android

.PARAMETER All
    Includes ALL apps (including Intune-managed apps).
    By default, only non-Intune apps are returned.

.PARAMETER ThrottleLimit
    Controls parallel execution threads.
    Lower values reduce Graph API throttling risk.

.EXAMPLE
    Get all non-Intune apps across all devices
    .\Get-IntuneApps.ps1

.EXAMPLE
    Get ALL apps (including Intune-managed)
    .\Get-IntuneApps.ps1 -All

.EXAMPLE
    Find apps matching "Chrome"
    .\Get-IntuneApps.ps1 -Match "Chrome"

.EXAMPLE
    Get apps for a specific device
    .\Get-IntuneApps.ps1 -Device "LAPTOP-123"

.EXAMPLE
    Get apps for Windows devices only
    .\Get-IntuneApps.ps1 -Type Windows

.EXAMPLE
    Get apps for Mac and Windows devices
    .\Get-IntuneApps.ps1 -Type Mac,Windows

.EXAMPLE
    Combine filters (device + app name)
    .\Get-IntuneApps.ps1 -Device "LAPTOP" -Match "Zoom"

.EXAMPLE
    Reduce throttling (safer for large environments)
    .\Get-IntuneApps.ps1 -ThrottleLimit 2

.NOTES
    Author: RALBE @ itm8
    Requires: Microsoft.Graph PowerShell Module

    Recommended:
    - Run in PowerShell 7+
    - Use lower ThrottleLimit if experiencing API throttling
    - Recommended to be run by Global Admin. Need to consent MSGraph for tenant.

    Limitations:
    - App name matching is not always exact
    - iOS/Android app inventory may be limited
#>

param(
    [string]$Match,
    [string]$Device,
    [string[]]$Type,
    [switch]$All,
    [int]$ThrottleLimit = 3
)

function Invoke-GraphSafe {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 5
    )

    $attempt = 0

    while ($attempt -lt $MaxRetries) {
        try {
            return & $ScriptBlock
        }
        catch {
            if ($_.Exception.Message -match "429") {
                $wait = [math]::Pow(2, $attempt)
                Write-Host "Throttled. Waiting $wait sec..." -ForegroundColor Yellow
                Start-Sleep -Seconds $wait
                $attempt++
            }
            else {
                throw $_
            }
        }
    }

    throw "Max retries reached."
}

$typeMap = @{
    "windows" = "Windows"
    "mac"     = "macOS"
    "macos"   = "macOS"
    "ios"     = "iOS"
    "ipad"    = "iPadOS"
    "android" = "Android"
}

$normalizedTypes = @()

if ($Type) {
    foreach ($t in $Type) {
        $key = $t.ToLower()
        if ($typeMap.ContainsKey($key)) {
            $normalizedTypes += $typeMap[$key]
        }
    }

    Write-Host "Filtering by OS: $($normalizedTypes -join ', ')" -ForegroundColor Cyan
}

Connect-MgGraph -Scopes "DeviceManagementApps.Read.All","DeviceManagementManagedDevices.Read.All"

Write-Host "Connected to Graph" -ForegroundColor Green
Write-Host "Fetching managed apps..."
$managedAppNames = Invoke-GraphSafe {
    Get-MgDeviceAppManagementMobileApp -All |
        Where-Object DisplayName |
        Select-Object -ExpandProperty DisplayName -Unique
}

Write-Host "Fetching devices..."
$deviceTable = @{}

$devices = Invoke-GraphSafe {
    Get-MgDeviceManagementManagedDevice -All |
        Select-Object Id, DeviceName, OperatingSystem
}

foreach ($d in $devices) {

    # Device name filter
    if ($Device -and ($d.DeviceName -notlike "*$Device*")) {
        continue
    }

    # OS filter
    if ($normalizedTypes.Count -gt 0) {
        if ($normalizedTypes -notcontains $d.OperatingSystem) {
            continue
        }
    }

    $deviceTable[$d.Id] = @{
        Name = $d.DeviceName
        OS   = $d.OperatingSystem
    }
}

if ($deviceTable.Count -eq 0) {
    Write-Host "No matching devices found." -ForegroundColor Red
    return
}

Write-Host "Fetching detected apps..."
$detectedApps = Invoke-GraphSafe {
    Get-MgDeviceManagementDetectedApp -All
}

# Thread-safe collection
$results = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

Write-Host "Processing apps in parallel (Throttle=$ThrottleLimit)..."
$detectedApps | ForEach-Object -Parallel {

    # Local copies (required for parallel)
    $deviceTableLocal     = $using:deviceTable
    $managedAppNamesLocal = $using:managedAppNames
    $matchFilter          = $using:Match
    $includeAll           = $using:All
    $resultsBag           = $using:results

    if (-not $_.DisplayName) { return }

    if ($matchFilter -and ($_.DisplayName -notlike "*$matchFilter*")) { return }

    if (-not $includeAll -and ($managedAppNamesLocal -contains $_.DisplayName)) { return }

    # Retry logic
    $attempt = 0
    $maxRetries = 3

    while ($attempt -lt $maxRetries) {
        try {
            $appDevices = Get-MgDeviceManagementDetectedAppManagedDevice -DetectedAppId $_.Id -All
            break
        }
        catch {
            if ($_.Exception.Message -match "429") {
                Start-Sleep -Seconds ([math]::Pow(2, $attempt))
                $attempt++
            }
            else {
                return
            }
        }
    }

    foreach ($dev in $appDevices) {
        if ($deviceTableLocal.ContainsKey($dev.Id)) {

            $deviceInfo = $deviceTableLocal[$dev.Id]

            $resultsBag.Add([PSCustomObject]@{
                DeviceName      = $deviceInfo.Name
                OperatingSystem = $deviceInfo.OS
                AppName         = $_.DisplayName
                Version         = $_.Version
                Publisher       = $_.Publisher
                ManagedByIntune = ($managedAppNamesLocal -contains $_.DisplayName)
            })
        }
    }

} -ThrottleLimit $ThrottleLimit

$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$outputPath = "AppInventory_$timestamp.csv"

$results |
    Sort-Object DeviceName, AppName |
    Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "Export complete: $outputPath" -ForegroundColor Green
Write-Host "Total records: $($results.Count)"