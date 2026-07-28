$Users = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox
$Exception = @("contoso@microsoft.com")
$Permission = "Reviewer"
$FolderCalendars = @("Calendar", "Kalender")

foreach ($User in $Users) {

    $Calendars = (Get-MailboxFolderStatistics $User.UserPrincipalName -FolderScope Calendar)

    if ($Exception -Contains ($User.UserPrincipalName)) {
        Write-Host "$User is an exception, don't touch permissions" -ForegroundColor Red
    } else {

        foreach ($Calendar in $Calendars) {
            $CalendarName = $Calendar.Name

            if ($FolderCalendars -Contains $CalendarName) {
                $Cal = "$($User.UserPrincipalName):\$CalendarName"
                $CurrentMailFolderPermission = Get-MailboxFolderPermission -Identity $Cal -User Default
                
                Set-MailboxFolderPermission -Identity $Cal -User Default -AccessRights $Permission -WarningAction:SilentlyContinue -WhatIf
                
                if ($CurrentMailFolderPermission.AccessRights -eq "$Permission") {
                    Write-Host $User.DisplayName already has the permission $CurrentMailFolderPermission.AccessRights -ForegroundColor Yellow
                }
                else {
                    Write-Host $User.DisplayName added permissions $Permission -ForegroundColor Green
                }
            }
        }
    }
}