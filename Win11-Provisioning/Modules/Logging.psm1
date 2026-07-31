Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:LogFile = Join-Path -Path $env:ProgramData -ChildPath 'Win11-Provisioning.log'
$script:TranscriptPath = Join-Path -Path $env:ProgramData -ChildPath 'Win11-Provisioning-transcript.txt'

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'ERROR'   { Write-Host $line -ForegroundColor Red }
        'WARN'    { Write-Host $line -ForegroundColor Yellow }
        'SUCCESS' { Write-Host $line -ForegroundColor Green }
        default   { Write-Host $line -ForegroundColor Cyan }
    }

    Add-Content -Path $script:LogFile -Value $line
}

function Set-RegistryDword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

function Set-RegistryString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
}

function Start-ProvisioningTranscript {
    [CmdletBinding()]
    param()

    try {
        Start-Transcript -Path $script:TranscriptPath -Append -ErrorAction Stop | Out-Null
        Write-Log "Transcript started: $script:TranscriptPath" 'INFO'
    }
    catch {
        Write-Log "Could not start transcript: $($_.Exception.Message)" 'WARN'
    }
}

function Stop-ProvisioningTranscript {
    [CmdletBinding()]
    param()

    try {
        Stop-Transcript | Out-Null
    }
    catch {
        # Safe no-op
    }
}

Export-ModuleMember -Function Write-Log, Set-RegistryDword, Set-RegistryString, Start-ProvisioningTranscript, Stop-ProvisioningTranscript
