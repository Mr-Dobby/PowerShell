Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-DanishConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying Danish locale configuration' 'INFO'

    try {
        Set-WinSystemLocale -SystemLocale $Config.Language
        Set-Culture -CultureInfo $Config.Language
        Set-WinHomeLocation -GeoId 61

        $langList = New-WinUserLanguageList -Language $Config.Language
        Set-WinUserLanguageList -LanguageList $langList -Force
        Set-WinUILanguageOverride -Language $Config.Language

        Set-WinDefaultInputMethodOverride -InputTip '0406:00000406'
        Set-TimeZone -Id $Config.TimeZone

        if ($Config.Use24HourClock) {
            Set-RegistryString -Path 'HKCU:\Control Panel\International' -Name 'sShortTime' -Value 'HH:mm'
            Set-RegistryString -Path 'HKCU:\Control Panel\International' -Name 'sTimeFormat' -Value 'HH:mm:ss'
        }
    }
    catch {
        Write-Log "Locale configuration warning: $($_.Exception.Message)" 'WARN'
    }

    Write-Log 'Danish locale configuration complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-DanishConfiguration
