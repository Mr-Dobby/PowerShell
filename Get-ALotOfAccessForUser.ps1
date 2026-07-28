#Connect-ExchangeOnline
#Connect-MicrosoftTeams
#Connect-AzureAD

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias('Mailbox','UPN','UserPrincipalName')]
    [string]$User
)

$mailbox = Get-Mailbox -Identity $User
$mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox,SharedMailbox,RoomMailbox,EquipmentMailbox
Write-Host "`nMailbox Type: $($mailbox.RecipientTypeDetails)"

foreach ($mb in $mailboxes) {
    $fullAccess = Get-MailboxPermission -Identity $mb.Identity -ErrorAction SilentlyContinue | Where {
        $_.User -like $User -and $_.AccessRights -contains "FullAccess"
    }

    $sendAs = Get-RecipientPermission -Identity $mb.Identity -ErrorAction SilentlyContinue | Where {
        $_.Trustee -like $User -and $_.AccessRights -contains "SendAs"
    }

    $sendOnBehalf = ($mb.GrantSendOnBehalfTo -contains $User)

    if ($fullAccess -or $sendAs -or $sendOnBehalf) {
        Write-Host "`nMailbox: $($mb.PrimarySmtpAddress)"
        if ($fullAccess) { Write-Host " ✓ Full Access" }
        if ($sendAs) { Write-Host " ✓ Send As" }
        if ($sendOnBehalf) { Write-Host " ✓ Send on Behalf" }
    }
}

Write-Host "`nAzure AD Groups:"
Get-AzureADUserMembership -ObjectId $User | Select DisplayName | ft -AutoSize

Write-Host "`nMicrosoft Teams Memberships:"
$teams = Get-Team
foreach ($team in $teams) {
    $members = Get-TeamUser -GroupId $team.GroupId
    if ($members.User -contains $User) {
        Write-Host "$($team.DisplayName)"
    }
}

Write-Host "`nDistribution Group Memberships:"
Get-DistributionGroup | Where {
    (Get-DistributionGroupMember $_.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue).PrimarySmtpAddress -contains $User
} | Select DisplayName,PrimarySmtpAddress,GroupType | ft -AutoSize
