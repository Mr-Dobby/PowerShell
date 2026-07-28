[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias('Mailbox','UPN','UserPrincipalName')]
    [string]$User,
    [Parameter(Mandatory = $true)]
    [string]$SearchChar,
    [string]$AccessRights = "Editor"
)

# Use the Get-Mailbox cmdlet and Where-Object to find mailboxes containing the specified character in DisplayName
$mailboxes = Get-Mailbox | Where-Object { $_.DisplayName -like "*$SearchChar*" }

# Use a foreach loop to remove calendar permissions and sharing permission flags for each mailbox from the specified user
foreach ($mailbox in $mailboxes) {
    $calendar = $mailbox.Name + ":\calendar"

    # Run Set-MailboxFolderPermission first, then Remove-MailboxFolderPermission if needed.
    #Set-MailboxFolderPermission -Identity $calendar -User $User -AccessRights $AccessRights -SharingPermissionFlags None
    #Remove-MailboxFolderPermission -Identity $calendar -User $User #-Confirm $true
}