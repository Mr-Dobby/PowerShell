Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Remove-StartMenuPromotedLinks {
    [CmdletBinding()]
    param()

    $paths = @(
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    )

    $keywords = @(
        'LinkedIn',
        'Skype',
        'Teams',
        'Outlook',
        'Office',
        'OneNote',
        'Clipchamp',
        'Maps',
        '3D Viewer',
        'Weather',
        'News',
        'Solitaire',
        'Phone Link',
        'Get Help',
        'Get Started'
    )

    foreach ($path in $paths) {
        if (-not (Test-Path -Path $path)) {
            continue
        }

        $links = Get-ChildItem -Path $path -Recurse -File -Include '*.lnk', '*.url' -ErrorAction SilentlyContinue
        foreach ($link in $links) {
            foreach ($keyword in $keywords) {
                if ($link.BaseName -like "*$keyword*") {
                    try {
                        Remove-Item -Path $link.FullName -Force -ErrorAction Stop
                        Write-Log "Removed Start menu link: $($link.Name)" 'INFO'
                    }
                    catch {
                        Write-Log "Could not remove Start menu link $($link.Name): $($_.Exception.Message)" 'WARN'
                    }
                    break
                }
            }
        }
    }
}

function Invoke-StartMenuTweaks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying Start menu cleanup' 'INFO'

    Set-RegistryDword -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection' -Value 1
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackDocs' -Value 0

    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-353694Enabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEnabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEverEnabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'OemPreInstalledAppsEnabled' -Value 0

    Remove-StartMenuPromotedLinks

    Write-Log 'Start menu cleanup complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-StartMenuTweaks
