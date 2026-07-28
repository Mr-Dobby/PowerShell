$userEmailAddress = ""
$memberOfGroups = Get-DistributionGroup -ResultSize Unlimited | where { Get-DistributionGroupMember $_.Identity | where { $_.PrimarySmtpAddress -eq $userEmailAddress } }

$results = @()

foreach ($group in $memberOfGroups) {
    $result = [PSCustomObject]@{
        UserEmail       = $userEmailAddress
        GroupDisplayName= $group.DisplayName
        GroupAlias      = $group.Alias
        GroupEmail      = $group.PrimarySmtpAddress
    }
    $results += $result
}

$results | Export-Csv -Path "C:\Path\To\CSV\File.csv" -NoTypeInformation