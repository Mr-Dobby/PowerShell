[CmdletBinding()]
param(
    [string]$ExportPath = "C:\LicensedUserMailboxes.csv",
    [string[]]$Scopes = @(
    "User.Read.All",
    "Directory.Read.All"
    )
)

Import-Module Microsoft.Graph
Connect-MgGraph -Scopes $Scopes

#Select-MgProfile -Name "v1.0"

$LicensedUsers = Get-MgUser `
    -All `
    -Filter "assignedLicenses/$count ne 0" `
    -ConsistencyLevel eventual `
    -Property Id,DisplayName,UserPrincipalName,Mail,AssignedLicenses

$MailboxUsers = $LicensedUsers | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_.Mail)
}

$Output = $MailboxUsers | Select-Object `
    DisplayName,
    UserPrincipalName,
    Mail,
    @{Name="LicenseCount";Expression={$_.AssignedLicenses.Count}}

$Output | Export-Csv $ExportPath -NoTypeInformation -Encoding UTF8

Disconnect-MgGraph
Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Yellow
