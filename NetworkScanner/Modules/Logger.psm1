function Write-Log {
    param(
        [string]$Message,
        [string]$Folder = "$PSScriptRoot\..\Logs"
    )

    if (!(Test-Path $Folder)) {
        New-Item `
            -ItemType Directory `
            -Path $Folder | Out-Null
    }

    $File = Join-Path $Folder "$(Get-Date -Format yyyy-MM-dd).log"

    "$(Get-Date -Format HH:mm:ss) $Message" |
        Add-Content $File
}

Export-ModuleMember -Function Write-Log