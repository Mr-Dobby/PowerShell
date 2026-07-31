Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-WindowsMaintenance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    Write-Log 'Running update maintenance tasks' 'INFO'

    if ($Config.RunWindowsUpdate) {
        try {
            Write-Log 'Triggering Windows Update scan/download/install (USOClient)' 'INFO'
            Start-Process -FilePath 'UsoClient.exe' -ArgumentList 'StartScan' -WindowStyle Hidden
            Start-Process -FilePath 'UsoClient.exe' -ArgumentList 'StartDownload' -WindowStyle Hidden
            Start-Process -FilePath 'UsoClient.exe' -ArgumentList 'StartInstall' -WindowStyle Hidden
        }
        catch {
            Write-Log "Windows Update trigger warning: $($_.Exception.Message)" 'WARN'
        }
    }

    if ($Config.UpdateMicrosoftStoreApps) {
        try {
            Write-Log 'Updating Microsoft Store apps via winget upgrade --source msstore' 'INFO'
            & winget upgrade --all --source msstore --silent --accept-source-agreements --accept-package-agreements | Out-Null
        }
        catch {
            Write-Log "Store update warning: $($_.Exception.Message)" 'WARN'
        }
    }

    if ($Config.UpgradeWingetPackages) {
        try {
            Write-Log 'Upgrading installed winget packages' 'INFO'
            & winget upgrade --all --silent --accept-source-agreements --accept-package-agreements | Out-Null
        }
        catch {
            Write-Log "Winget upgrade warning: $($_.Exception.Message)" 'WARN'
        }
    }

    Write-Log 'Update maintenance complete' 'SUCCESS'
}

Export-ModuleMember -Function Invoke-WindowsMaintenance
