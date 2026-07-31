Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-NetworkingTweaks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying networking tweaks' 'INFO'

    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' -Name 'AutoConnectAllowedOEM' -Value 0
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' -Name 'value' -Value 0
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' -Name 'value' -Value 0
    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -Value 0

    Write-Log 'Networking tweaks complete' 'SUCCESS'
}

function Invoke-PowerTweaks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying power settings' 'INFO'

    if ($Config.DeviceType -eq 'Desktop') {
        powercfg /S SCHEME_MIN | Out-Null
        Write-Log 'Set power plan to High performance' 'INFO'
    }
    else {
        powercfg /S SCHEME_BALANCED | Out-Null
        Write-Log 'Set power plan to Balanced' 'INFO'
    }

    if ($Config.DisableFastStartup) {
        Set-RegistryDword -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0
        Write-Log 'Disabled Fast Startup' 'INFO'
    }

    Write-Log 'Power settings complete' 'SUCCESS'
}

function Invoke-QualityOfLifeTweaks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying quality-of-life tweaks' 'INFO'

    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 1
    Set-RegistryDword -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name 'InitialKeyboardIndicators' -Value 2
    Set-RegistryDword -Path 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name 'Flags' -Value 506
    Set-RegistryDword -Path 'HKCU:\Control Panel\Accessibility\Keyboard Response' -Name 'Flags' -Value 122
    Set-RegistryString -Path 'HKCU:\AppEvents\Schemes\Apps\.Default\SystemStart\.Current' -Name '(Default)' -Value ''

    if ($Config.DisableMouseAcceleration) {
        Set-RegistryString -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseSpeed' -Value '0'
        Set-RegistryString -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold1' -Value '0'
        Set-RegistryString -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold2' -Value '0'
    }

    Write-Log 'Quality-of-life tweaks complete' 'SUCCESS'
}

function Invoke-OptionalFeatureCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    if (-not $Config.Enabled) {
        Write-Log 'Optional feature cleanup skipped' 'INFO'
        return
    }

    Write-Log 'Removing optional Windows features' 'INFO'

    $features = @(
        'Internet-Explorer-Optional-amd64',
        'XPS.Viewer',
        'FaxServicesClientPackage',
        'WorkFolders-Client',
        'Printing-XPSServices-Features',
        'Hello-Face-Package'
    )

    if ($Config.RemovePrintToPDF) {
        $features += 'Printing-PrintToPDFServices-Features'
    }

    foreach ($feature in $features) {
        try {
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Log "Optional feature warning ($feature): $($_.Exception.Message)" 'WARN'
        }
    }

    Write-Log 'Optional feature cleanup complete' 'SUCCESS'
}

function Invoke-FinalCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Final cleanup: restarting Explorer process' 'INFO'
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe

    Write-Log 'Final cleanup complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-NetworkingTweaks, Invoke-PowerTweaks, Invoke-QualityOfLifeTweaks, Invoke-OptionalFeatureCleanup, Invoke-FinalCleanup
