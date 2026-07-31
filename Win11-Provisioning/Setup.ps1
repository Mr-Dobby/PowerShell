[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath 'Config.psd1'),
    [switch]$DisableOneDriveAutoStart,
    [switch]$SkipOptionalFeatures
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    [CmdletBinding()]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-ElevatedSelf {
    [CmdletBinding()]
    param()

    $hostExe = (Get-Process -Id $PID).Path
    $argumentList = @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        ('"{0}"' -f $PSCommandPath)
    ) + $MyInvocation.UnboundArguments

    Start-Process -FilePath $hostExe -Verb RunAs -ArgumentList $argumentList | Out-Null
}

function Unblock-ProvisioningFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RootPath
    )

    $patterns = @('*.ps1', '*.psm1', '*.psd1')
    $files = Get-ChildItem -Path $RootPath -Recurse -File -Include $patterns -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        Unblock-File -Path $file.FullName -ErrorAction SilentlyContinue
    }
}

if (-not (Test-IsAdministrator)) {
    Write-Host 'Not running as administrator. Relaunching elevated...' -ForegroundColor Yellow
    Start-ElevatedSelf
    exit
}

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction Stop
}
catch {
    # Ignore if constrained by policy; we'll still unblock local files below.
}

Unblock-ProvisioningFiles -RootPath $PSScriptRoot

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
    'Cleanup.psm1',
    'Cortana.psm1'
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
    Invoke-CortanaTweaks -Config $config.Cortana
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
