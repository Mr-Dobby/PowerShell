$user = "mailbox@contoso.com"
$searchChar = "CPH"�# Use the Get-Mailbox cmdlet and Where-Object to find mailboxes containing the specified character in DisplayName
$mailboxes = Get-Mailbox | Where-Object {$_.DisplayName -like "*$searchChar*"}
$accessRights = "Editor"�# Use a foreach loop to remove calendar permissions and sharing permission flags for each mailbox from the specified user
foreach ($mailbox in $mailboxes) {
��� $calendar = $mailbox.Name + ":\calendar"

    #K�r F�RST Set-MailboxFolderPermissions, N�ST Remove-MailboxFolderPermission, s� har brugeren ikke l�ngere rettigheder

    #Set-MailboxFolderPermission -Identity $calendar -User $user -AccessRights Editor -SharingPermissionFlags None
��� #Remove-MailboxFolderPermission -Identity $calendar -User $user #-Confirm $true
}