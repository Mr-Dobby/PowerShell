<#
.SYNOPSIS
Network scanner launcher script.

.DESCRIPTION
Scans an IPv4 subnet/range and can export TXT, CSV, JSON, and HTML reports.
PowerShell 7+ uses parallel scanning. Windows PowerShell 5.1 uses sequential fallback.

.EXAMPLE
.\NetworkScanner.ps1 -CIDR 192.168.1.0/24

.EXAMPLE
.\NetworkScanner.ps1 -Subnet 192.168.1 -Start 100 -End 150 -Threads 100

.EXAMPLE
.\NetworkScanner.ps1 -CIDR 10.0.0.0/24 -SaveTxt -SaveCsv -SaveJson -SaveHtml

.EXAMPLE
.\NetworkScanner.ps1 -CIDR 192.168.1.0/24 -ShowOffline -ScanPorts -Ports 22,80,443,3389
#>
[CmdletBinding(DefaultParameterSetName = 'CIDR')]
param(
    [Parameter(Mandatory, ParameterSetName = 'CIDR')]
    [string]$CIDR,

    [Parameter(Mandatory, ParameterSetName = 'Range')]
    [string]$Subnet,

    [Parameter(ParameterSetName = 'Range')]
    [ValidateRange(0, 255)]
    [int]$Start = 1,

    [Parameter(ParameterSetName = 'Range')]
    [ValidateRange(0, 255)]
    [int]$End = 254,

    [ValidateRange(1, 1024)]
    [int]$Threads = 50,

    [ValidateRange(50, 20000)]
    [int]$Timeout = 700,

    [switch]$ResolveDNS,
    [switch]$ShowMac,
    [switch]$ShowOffline,

    [switch]$ScanPorts,
    [int[]]$Ports = @(22, 80, 443, 3389),

    [switch]$SaveTxt,
    [switch]$SaveCsv,
    [switch]$SaveJson,
    [switch]$SaveHtml,

    [string]$OutputFolder = (Join-Path $PSScriptRoot 'Reports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'NetworkScanner.psm1') -Force -DisableNameChecking

function Show-ResultTable {
    param([Parameter(Mandatory)][array]$Results)

    if (-not $Results -or $Results.Count -eq 0) {
        Write-Host 'No results to display.' -ForegroundColor Yellow
        return
    }

    $header = '{0,-16} {1,-8} {2,-35} {3,8} {4,-19} {5}' -f 'IP Address', 'Status', 'Hostname', 'Ping(ms)', 'MAC Address', 'Open Ports'
    Write-Host ''
    Write-Host $header -ForegroundColor Cyan
    Write-Host ('-' * 115) -ForegroundColor DarkGray

    foreach ($item in $Results) {
        $icon = if ($item.Status -eq 'Online') { '🟢' } else { '🔴' }
        $latency = if ($null -ne $item.ResponseTime -and "$($item.ResponseTime)" -ne '') { [string]$item.ResponseTime } else { '-' }
        $line = '{0,-16} {1,-8} {2,-35} {3,8} {4,-19} {5}' -f $item.IPAddress, "$icon $($item.Status)", $item.Hostname, $latency, $item.MACAddress, $item.OpenPorts

        if ($item.Status -eq 'Online') {
            Write-Host $line -ForegroundColor Green
        }
        else {
            Write-Host $line -ForegroundColor DarkGray
        }
    }
}

try {
    Write-Host ''
    Write-Host '=== NetworkScanner ===' -ForegroundColor Cyan
    Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor DarkCyan

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host 'Running in compatibility mode (sequential scanning on Windows PowerShell 5.1).' -ForegroundColor Yellow
    }
    else {
        Write-Host "Parallel scanning enabled (Threads: $Threads)." -ForegroundColor DarkCyan
    }

    $scanParams = @{
        Threads     = $Threads
        Timeout     = $Timeout
        ResolveDNS  = $ResolveDNS
        ShowMac     = $ShowMac
        ShowOffline = $ShowOffline
        ScanPorts   = $ScanPorts
        Ports       = $Ports
    }

    if ($PSCmdlet.ParameterSetName -eq 'CIDR') {
        $scanParams.CIDR = $CIDR
        Write-Host "Target CIDR: $CIDR" -ForegroundColor DarkCyan
    }
    else {
        $scanParams.Subnet = $Subnet
        $scanParams.Start = $Start
        $scanParams.End = $End
        Write-Host "Target range: $Subnet.$Start - $Subnet.$End" -ForegroundColor DarkCyan
    }

    Write-Host "Timeout: $Timeout ms" -ForegroundColor DarkCyan
    Write-Host "Resolve DNS: $([bool]$ResolveDNS) | Resolve MAC: $([bool]$ShowMac) | Port Scan: $([bool]$ScanPorts)" -ForegroundColor DarkCyan

    $results = Start-NetworkScan @scanParams

    $online = (@($results | Where-Object Status -eq 'Online')).Count
    $offline = (@($results | Where-Object Status -eq 'Offline')).Count

    Write-Host ''
    Write-Host "Scan completed. Online: $online | Offline: $offline | Returned: $(@($results).Count)" -ForegroundColor Green

    Show-ResultTable -Results $results

    if ($SaveTxt -or $SaveCsv -or $SaveJson -or $SaveHtml) {
        $saved = Export-NetworkScan -Results $results -OutputFolder $OutputFolder -Txt:$SaveTxt -Csv:$SaveCsv -Json:$SaveJson -Html:$SaveHtml
        if (@($saved).Count -gt 0) {
            Write-Host ''
            Write-Host 'Reports saved:' -ForegroundColor Cyan
            foreach ($file in @($saved)) {
                Write-Host " - $file" -ForegroundColor Green
            }
        }
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
