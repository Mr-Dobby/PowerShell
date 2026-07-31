Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Remove-AppxEverywhere {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageNamePattern
    )

    Write-Log "Removing Appx pattern: $PackageNamePattern" 'INFO'

    $appx = Get-AppxPackage -AllUsers -Name $PackageNamePattern -ErrorAction SilentlyContinue
    foreach ($pkg in $appx) {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Appx remove warning ($($pkg.Name)): $($_.Exception.Message)" 'WARN'
        }
    }

    $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $PackageNamePattern }
    foreach ($pkg in $provisioned) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Log "Provisioned remove warning ($($pkg.DisplayName)): $($_.Exception.Message)" 'WARN'
        }
    }
}

function Invoke-SystemCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Running system cleanup and bloatware removal' 'INFO'

    $targets = @(
        'Microsoft.Xbox*',
        'Clipchamp.Clipchamp',
        'Microsoft.OutlookForWindows',
        'MicrosoftTeams',
        'Microsoft.SkypeApp',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MixedReality.Portal',
        'Microsoft.WindowsMaps',
        'Microsoft.BingWeather',
        'Microsoft.BingNews',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.Getstarted',
        'Microsoft.GetHelp',
        'Microsoft.ZuneVideo',
        'Microsoft.ZuneMusic',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.549981C3F5F10'
    )

    if ($Config.RemovePhoneLink) {
        $targets += 'Microsoft.YourPhone'
    }

    foreach ($name in $targets) {
        Remove-AppxEverywhere -PackageNamePattern $name 
    }

    Write-Log 'System cleanup complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-SystemCleanup
