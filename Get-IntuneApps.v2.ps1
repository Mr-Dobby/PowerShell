# Get-IntuneApps.v2.ps1 (Enhanced v2)
# by ralbe @ itm8

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

Connect-MgGraph -Scopes "DeviceManagementApps.Read.All","DeviceManagementManagedDevices.Read.All"

Write-Host "Connected to Graph" -ForegroundColor Green

$ctx = Get-MgContext
Write-Host "Tenant: $($ctx.TenantId)" -ForegroundColor Green

$typeMap = @{
		"windows" = "Windows"
		"mac"     = "macOS"
		"ios"     = "iOS"
		"android" = "Android"
}

$normalizedTypes = @()
if ($Type) {
		$normalizedTypes = $Type | ForEach-Object {
				$k = $_.ToLower()
				if ($typeMap.ContainsKey($k)) { $typeMap[$k] }
		}
}

Write-Host "Loading managed apps..."

$managedApps = Get-MgDeviceAppManagementMobileApp -All |
		Where-Object DisplayName |
		Select-Object -ExpandProperty DisplayName

$managedAppsLower = $managedApps | ForEach-Object { $_.ToLower() }

Write-Host "Loading devices..."

$devices = Get-MgDeviceManagementManagedDevice -All | ForEach-Object {
		[PSCustomObject]@{
				Id              = $_.Id
				DeviceName      = $_.DeviceName
				OperatingSystem = $_.OperatingSystem
		}
}

Write-Host "Devices found: $($devices.Count)"

if ($devices.Count -eq 0) {
		throw "No devices matched filters"
}

$results = New-Object System.Collections.Generic.List[object]

$counter = 0
$total = $devices.Count

foreach ($device in $devices) {

		$counter++
		Write-Host "[$counter/$total] $($device.DeviceName)"

		try {
				$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.Id)/detectedApps"
				$response = Invoke-MgGraphRequest -Uri $uri -Method GET
				$apps = $response.value
		}
		catch {
				Write-Host "Failed device: $($device.DeviceName)" -ForegroundColor Yellow
				continue
		}

		if (-not $apps) { continue }

		foreach ($app in $apps) {

				if (-not $app.displayName) { continue }

				if ($Match -and $app.displayName -notlike "*$Match*") { continue }

				$nameLower = $app.displayName.ToLower()

				$isManaged = $false
				foreach ($m in $managedAppsLower) {
						if ($nameLower -like "*$m*" -or $m -like "*$nameLower*") {
								$isManaged = $true
								break
						}
				}

				if (-not $All -and $isManaged) { continue }

				$risk = 0

				if ($nameLower -match "teamviewer|anydesk|vnc|rustdesk|screenconnect") { $risk += 8 }
				if ($nameLower -match "keygen|crack|cheat|nmap|burp|fiddler") { $risk += 10 }
				if ($nameLower -match "crypto|miner|bitcoin|ethereum") { $risk += 10 }

				if ([string]::IsNullOrWhiteSpace($app.publisher)) { $risk += 3 }

				if ($risk -gt 10) { $risk = 10 }

				$results.Add([PSCustomObject]@{
						DeviceName      = $device.DeviceName
						OperatingSystem = $device.OperatingSystem
						AppName         = $app.displayName
						Version         = $app.version
						Publisher       = $app.publisher
						ManagedByIntune = $isManaged
						RiskScore       = $risk
				})
		}
}

Write-Host "Generating outputs..."

$timestamp = Get-Date -Format "yyyyMMdd-HHmm"

$csvPath = "AppInventory_$timestamp.csv"
$jsonPath = "AppInventory_$timestamp.json"
$htmlPath = "AppDashboard_$timestamp.html"

$results | Export-Csv $csvPath -NoTypeInformation
$results | ConvertTo-Json -Depth 5 | Set-Content $jsonPath

$totalApps = $results.Count
$managed = ($results | Where-Object ManagedByIntune).Count
$unmanaged = $totalApps - $managed

$html = @"
<!DOCTYPE html>
<html>
<head>
<title>Intune App Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
body { font-family: Segoe UI; margin: 20px; background:#f4f4f4; }
.card { display:inline-block; background:white; padding:15px; margin:10px; border-radius:8px; }
table { width:100%; border-collapse:collapse; background:white; }
th,td { border:1px solid #ddd; padding:6px; font-size:12px; }
th { background:#1f4e79; color:white; }
</style>
</head>
<body>

<h1>Intune App Intelligence Dashboard</h1>

<div class="card">Total Records: <b>$totalApps</b></div>
<div class="card">Managed: <b>$managed</b></div>
<div class="card">Unmanaged: <b>$unmanaged</b></div>

<h2>Apps</h2>

<table>
<tr>
<th>Device</th><th>App</th><th>OS</th><th>Managed</th><th>Risk</th>
</tr>
"@

foreach ($r in $results) {
		$html += "<tr>
<td>$($r.DeviceName)</td>
<td>$($r.AppName)</td>
<td>$($r.OperatingSystem)</td>
<td>$($r.ManagedByIntune)</td>
<td>$($r.RiskScore)</td>
</tr>"
}

$html += @"
</table>

</body>
</html>
"@

$html | Set-Content $htmlPath -Encoding UTF8

Write-Host "Done!"
Write-Host "CSV: $csvPath"
Write-Host "JSON: $jsonPath"
Write-Host "HTML: $htmlPath"
Write-Host "Total records: $totalApps"