Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-AppxKeep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        [Parameter(Mandatory)]
        [string[]]$KeepPatterns
    )

    foreach ($pattern in $KeepPatterns) {
        if ($PackageName -like $pattern) {
            return $true
        }
    }

    return $false
}

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
        '*Xbox*',
        '*GamingApp*',
        'Clipchamp.Clipchamp',
        'Microsoft.OutlookForWindows',
        'Microsoft.Outlook*',
        'MicrosoftTeams',
        'MSTeams*',
        'Microsoft.SkypeApp',
        '*Skype*',
        '*LinkedIn*',
        '7EE7776C.LinkedInforWindows',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.Office.OneNote',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.Whiteboard',
        'Microsoft.Todos',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MixedReality.Portal',
        'Microsoft.WindowsMaps',
        'Microsoft.BingWeather',
        'Microsoft.BingNews',
        'Microsoft.News',
        'MicrosoftCorporationII.QuickAssist',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.Getstarted',
        'Microsoft.GetHelp',
        'Microsoft.ZuneVideo',
        'Microsoft.ZuneMusic',
        'Microsoft.People',
        'Microsoft.YourPhone',
        'Microsoft.PhoneLink',
        'Microsoft.549981C3F5F10',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.BingSearch',
        'Microsoft.BingFinance',
        'Microsoft.BingSports',
        'Microsoft.WindowsAlarms',
        'Microsoft.WindowsCamera',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.ScreenSketch',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftJournal',
        'Microsoft.Minecraft*',
        '*Disney*',
        '*Spotify*',
        '*TikTok*',
        '*Instagram*',
        '*Facebook*',
        '*Twitter*',
        '*Netflix*',
        '*Amazon*',
        '*eBay*',
        '*Walmart*',
        '*AliExpress*',
        '*Wish*',
        '*Pinterest*',
        'Microsoft.549981C3F5F10'
    )

    if ($Config.RemovePhoneLink) {
        $targets += 'Microsoft.YourPhone'
    }

    foreach ($name in $targets) {
        Remove-AppxEverywhere -PackageNamePattern $name
    }

    if ($Config.AggressiveRemove) {
        Write-Log 'Running aggressive Appx cleanup (keep-only mode)' 'INFO'

        $keepPatterns = @(
            'Microsoft.WindowsStore',
            'Microsoft.StorePurchaseApp',
            'Microsoft.DesktopAppInstaller',
            'Microsoft.MicrosoftEdge*',
            'Microsoft.Edge*',
            'Microsoft.Win32WebViewHost',
            'Microsoft.SecHealthUI',
            'Microsoft.WindowsDefender*',
            'Microsoft.VCLibs*',
            'Microsoft.UI.Xaml*',
            'Microsoft.NET.Native.Framework*',
            'Microsoft.NET.Native.Runtime*',
            'Microsoft.WindowsTerminal*',
            '*PowerShell*'
        )

        if ($Config.ContainsKey('KeepPackages') -and $Config.KeepPackages) {
            $keepPatterns = $Config.KeepPackages
        }

        $installed = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        foreach ($pkg in $installed) {
            if (-not (Test-AppxKeep -PackageName $pkg.Name -KeepPatterns $keepPatterns)) {
                Remove-AppxEverywhere -PackageNamePattern $pkg.Name
            }
        }

        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        foreach ($pkg in $provisioned) {
            if (-not (Test-AppxKeep -PackageName $pkg.DisplayName -KeepPatterns $keepPatterns)) {
                Remove-AppxEverywhere -PackageNamePattern $pkg.DisplayName
            }
        }
    }

    Write-Log 'System cleanup complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-SystemCleanup
