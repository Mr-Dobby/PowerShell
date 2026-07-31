Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Disable-OneDriveAutoStart {
    [CmdletBinding()]
    param()

    Write-Log 'Disabling OneDrive autostart' 'INFO'

    Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Value 1

    $runPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (Test-Path -Path $runPath) {
        Remove-ItemProperty -Path $runPath -Name 'OneDrive' -ErrorAction SilentlyContinue
    }
}

function Uninstall-OneDrive {
    [CmdletBinding()]
    param()

    Write-Log 'Uninstalling OneDrive' 'INFO'

    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    $candidates = @(
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    )

    foreach ($exe in $candidates) {
        if (Test-Path -Path $exe) {
            Start-Process -FilePath $exe -ArgumentList '/uninstall' -Wait -NoNewWindow
        }
    }

    Disable-OneDriveAutoStart
}

function Invoke-OneDriveAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    if ($Config.Uninstall) {
        Uninstall-OneDrive
    }
    elseif ($Config.DisableAutoStartOnly) {
        Disable-OneDriveAutoStart
    }
    else {
        Write-Log 'OneDrive action skipped by configuration' 'INFO'
    }

    Write-Log 'OneDrive action complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-OneDriveAction
