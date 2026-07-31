Set-StrictMode -Version Latest

function Invoke-CortanaTweaks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Applying Cortana tweaks' 'INFO'

    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0
    Set-RegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0

    Write-Log 'Cortana tweaks complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-CortanaTweaks