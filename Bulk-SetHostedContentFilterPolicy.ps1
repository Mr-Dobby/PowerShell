<# 
    Multi-Tenant Anti-Spam Block List Automation
    --------------------------------------------------
    Requirements:
    - PartnerCenter module
    - ExchangeOnlineManagement module
    - GDAP or DAP delegated admin access
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Tenants,
    [string]$SenderToBlock
)

Import-Module PartnerCenter
Import-Module ExchangeOnlineManagement

# Ask which sender to block
if ([string]::IsNullOrWhiteSpace($SenderToBlock)) {
    $SenderToBlock = Read-Host "Enter email address to block"
}

# Login to Partner Center (only once)
Write-Host "`nConnecting to Partner Center..." -ForegroundColor Cyan
Connect-PartnerCenter -UseDeviceAuthentication

foreach ($TenantDomain in $Tenants) {

    Write-Host "`n==============================" -ForegroundColor Yellow
    Write-Host "Processing tenant: $TenantDomain" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Yellow
    
    try {
        # Connect to EXO using delegated admin
        Connect-ExchangeOnline -DelegatedOrganization $TenantDomain -ShowBanner:$false -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to connect to $TenantDomain - $_" -ForegroundColor Red
        continue
    }

    # Retrieve all Hosted Content Filter Policies
    $Policies = Get-HostedContentFilterPolicy

    if ($Policies.Count -eq 0) {
        Write-Host "No spam policies found in $TenantDomain" -ForegroundColor Red
        Disconnect-ExchangeOnline -Confirm:$false
        continue
    }

    # List policies
    Write-Host "`nAvailable Content Filter Policies:"
    $i = 1
    foreach ($policy in $Policies) {
        Write-Host "[$i] $($policy.Identity)  (Priority: $($policy.Priority))"
        $i++
    }

    # Prompt user to choose
    $Selection = Read-Host "`nEnter the number of the policy to modify"
    $Selection = [int]$Selection

    if ($Selection -lt 1 -or $Selection -gt $Policies.Count) {
        Write-Host "Invalid selection - skipping $TenantDomain" -ForegroundColor Red
        Disconnect-ExchangeOnline -Confirm:$false
        continue
    }

    $ChosenPolicy = $Policies[$Selection - 1]

    Write-Host "`nSelected Policy: $($ChosenPolicy.Identity)" -ForegroundColor Green

    # Add blocked sender
    try {
        Set-HostedContentFilterPolicy -Identity $ChosenPolicy.Identity `
            -BlockedSenders @{Add=$SenderToBlock} -ErrorAction Stop

        Write-Host "Successfully added block for $SenderToBlock in $TenantDomain" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to modify policy in $TenantDomain - $_" -ForegroundColor Red
    }

    Disconnect-ExchangeOnline -Confirm:$false
}

Write-Host "`nFinished processing all tenants." -ForegroundColor Cyan
