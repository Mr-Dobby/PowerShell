Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-WingetSoftwareInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Installing common software via winget' 'INFO'

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Log 'winget not found. Skipping software install.' 'WARN'
        return
    }

    foreach ($packageId in $Config.Packages) {
        Write-Log -Message ('Installing package ' + $packageId) -Level 'INFO'
        $argumentLine = 'install --id {0} --exact --silent --accept-package-agreements --accept-source-agreements' -f $packageId
        Start-Process -FilePath 'winget.exe' -ArgumentList $argumentLine -Wait -NoNewWindow
    }
}

Export-ModuleMember -Function Invoke-WingetSoftwareInstall
