[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias('UPN','UserPrincipalName','Mailbox')]
    [string]$UserEmailAddress,
    [string]$ExportPath = "C:\Path\To\CSV\File.csv"
)

$memberOfGroups = Get-DistributionGroup -ResultSize Unlimited | where { Get-DistributionGroupMember $_.Identity | where { $_.PrimarySmtpAddress -eq $UserEmailAddress } }

$results = @()

foreach ($group in $memberOfGroups) {
    $result = [PSCustomObject]@{
        UserEmail       = $UserEmailAddress
        GroupDisplayName= $group.DisplayName
        GroupAlias      = $group.Alias
        GroupEmail      = $group.PrimarySmtpAddress
    }
    $results += $result
}

$results | Export-Csv -Path $ExportPath -NoTypeInformation