Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-PrivacyHardening {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying privacy hardening' 'INFO'

    try {
      Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0
      Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Value 1
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353698Enabled' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0
      Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0
      Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0

      if ($Config.DisableLocation) {
          Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' -Name 'DisableLocation' -Value 1
      }

      Set-RegistryDword -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Value 0
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

    Write-Log 'Privacy hardening complete' 'SUCCESS'
}

function Invoke-Windows11Cleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying Windows 11 cleanup policies' 'INFO'

    try {
      Set-RegistryDword -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0
      Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Value 0

      if ($Config.DisableRecallIfAvailable) {
          Set-RegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'TurnOffSavingSnapshots' -Value 1
      }

      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338393Enabled' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338387Enabled' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenEnabled' -Value 0
      Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenOverlayEnabled' -Value 0

    Write-Log 'Windows 11 cleanup complete' 'SUCCESS'
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
}

Export-ModuleMember -Function Invoke-PrivacyHardening, Invoke-Windows11Cleanup
