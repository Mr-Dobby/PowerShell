#requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath 'Config.psd1'),
    [switch]$DisableOneDriveAutoStart,
    [switch]$SkipOptionalFeatures
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
$modules = @(
    'Logging.psm1',
    'Bloatware.psm1',
    'Privacy.psm1',
    'Explorer.psm1',
    'StartMenu.psm1',
    'Taskbar.psm1',
    'Appearance.psm1',
    'Locale.psm1',
    'OneDrive.psm1',
    'Winget.psm1',
    'WindowsUpdate.psm1',
    'Cleanup.psm1'
)

foreach ($module in $modules) {
    Import-Module (Join-Path -Path $modulePath -ChildPath $module) -Force
}

if (-not (Test-Path -Path $ConfigPath)) {
    throw "Config file not found at: $ConfigPath"
}

$config = Import-PowerShellDataFile -Path $ConfigPath

if ($DisableOneDriveAutoStart) {
    $config.OneDrive.Uninstall = $false
    $config.OneDrive.DisableAutoStartOnly = $true
}

if ($SkipOptionalFeatures) {
    $config.OptionalFeatures.Enabled = $false
}

Start-ProvisioningTranscript
Write-Log "Starting Win11 provisioning using config: $ConfigPath" 'INFO'

try {
    Invoke-SystemCleanup -Config $config.SystemCleanup

    Invoke-PrivacyHardening -Config $config.Privacy
    Invoke-Windows11Cleanup -Config $config.Windows11Cleanup

    Invoke-ExplorerTweaks -Config $config.Explorer
    Invoke-TaskbarTweaks -Config $config.Taskbar
    Invoke-StartMenuTweaks -Config $config.StartMenu
    Invoke-AppearanceTweaks -Config $config.Appearance

    Invoke-DanishConfiguration -Config $config.Locale

    Invoke-OneDriveAction -Config $config.OneDrive

    Invoke-NetworkingTweaks -Config $config.Networking
    Invoke-PowerTweaks -Config $config.Power
    Invoke-QualityOfLifeTweaks -Config $config.QualityOfLife

    Invoke-WingetSoftwareInstall -Config $config.Winget
    Invoke-WindowsMaintenance -Config $config.WindowsUpdate

    Invoke-OptionalFeatureCleanup -Config $config.OptionalFeatures
    Invoke-FinalCleanup -Config $config.Cleanup

    Write-Log 'Provisioning completed successfully. A reboot is recommended.' 'SUCCESS'
}
catch {
    Write-Log "Provisioning failed: $($_.Exception.Message)" 'ERROR'
    throw
}
finally {
    Stop-ProvisioningTranscript
}
