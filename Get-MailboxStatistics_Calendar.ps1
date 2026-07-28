Get-MailboxFolderStatistics <Identity> | Select Name, FolderPath, Foldertype, Identity
Set-MailboxFolderPermission -Identity <Identity>:\<FolderType> -User Default -AccessRights LimitedDetails


