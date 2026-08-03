Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Disable-OneDriveAutoStart {
    [CmdletBinding()]
    param()

    Write-Log 'Disabling OneDrive autostart' 'INFO'

    Set-RegistryDword -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Value 1
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name "DisableFileSync" -Value 1 -Type DWord

    $runPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (Test-Path -Path $runPath) {
        Remove-ItemProperty -Path $runPath -Name 'OneDrive' -ErrorAction SilentlyContinue
    }
}

function Uninstall-OneDrive {
    [CmdletBinding()]
    param()

    Write-Log 'Uninstalling OneDrive' 'INFO'

    try {
      Stop-Process -Name "OneDrive*" -Force -ErrorAction SilentlyContinue
      if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
          Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
      } else {
          Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
      }

      Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
      Remove-Item "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
      remove-Item "Registry::HKEY_CLASSES_ROOT\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue

      $candidates = @(
          "$env:SystemRoot\System32\OneDriveSetup.exe",
          "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
      )

      foreach ($exe in $candidates) {
          if (Test-Path -Path $exe) {
              Start-Process -FilePath $exe -ArgumentList '/uninstall' -Wait -NoNewWindow
          }
      }
    }
    catch [System.UnauthorizedAccessException] {
      # Catches permission issues (e.g., trying to write to HKLM without admin rights)
      Write-Error "Permission Denied: Run PowerShell as an Administrator. Details: $_"
    }
    catch [System.IO.IOException] {
        # Catches issues where the path or data structure is invalid
        Write-Error "I/O Error: Ensure the path is correct. Details: $_"
    }
    catch {
        # Generic catch-all for any other unexpected failures
        Write-Error "Unexpected error: $_"
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
