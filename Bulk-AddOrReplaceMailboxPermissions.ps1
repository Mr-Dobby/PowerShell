# INTERACTIVE MAILBOX PERMISSION COPY SCRIPT
# Copies Full Access, Send-As, Send-on-Behalf, and Calendar permissions
# Exports BEFORE and AFTER permission state for audit/verification

$SourceMailbox = Read-Host "Enter the SOURCE mailbox (e.g. user@domain.com)"
$TargetMailbox = Read-Host "Enter the TARGET mailbox"
$Mode = Read-Host "Choose mode: 'Add' or 'Replace'"

if ($Mode -notin @("Add", "Replace")) {
    Write-Host "Invalid mode. Must be 'Add' or 'Replace'." -ForegroundColor Red
    exit
}

# --- Setup export paths ---
$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$exportRoot = ".\PermissionExports"
$sourceExportPath = "$exportRoot\$SourceMailbox"
$targetExportPath = "$exportRoot\$TargetMailbox"

New-Item -ItemType Directory -Force -Path $sourceExportPath | Out-Null
New-Item -ItemType Directory -Force -Path $targetExportPath | Out-Null

function Export-MailboxPermissions {
    param(
        [string]$Mailbox,
        [string]$ExportPath,
        [string]$Label
    )

    Write-Host "Exporting $Label permissions for $Mailbox..." -ForegroundColor Cyan

    # Full Access
    Get-MailboxPermission $Mailbox |
        Select Identity,User,AccessRights,IsInherited |
        Export-Csv "$ExportPath\FullAccess-$Label-$timestamp.csv" -NoTypeInformation

    # Send-As
    Get-ADPermission $Mailbox |
        Where-Object { $_.ExtendedRights -like "*Send-As*" } |
        Select Identity,User,ExtendedRights |
        Export-Csv "$ExportPath\SendAs-$Label-$timestamp.csv" -NoTypeInformation

    # Send-on-Behalf
    $sob = (Get-Mailbox $Mailbox).GrantSendOnBehalfTo
    $sob | ForEach-Object {
        [PSCustomObject]@{
            Identity = $Mailbox
            User     = $_
            Right    = "SendOnBehalf"
        }
    } | Export-Csv "$ExportPath\SendOnBehalf-$Label-$timestamp.csv" -NoTypeInformation

    # Folder permissions (Calendar + others)
    $folders = @("Calendar", "Inbox", "Contacts")

    foreach ($f in $folders) {
        $path = "$Mailbox`:\$f"
        try {
            Get-MailboxFolderPermission $path |
                Select FolderName,User,AccessRights |
                Export-Csv "$ExportPath\Folder-$($f)-$Label-$timestamp.csv" -NoTypeInformation
        }
        catch {
            # Folder may not exist — ignore
        }
    }

    Write-Host "Export complete for $Mailbox ($Label)" -ForegroundColor Green
}

Export-MailboxPermissions -Mailbox $SourceMailbox -ExportPath $sourceExportPath -Label "Before"
Export-MailboxPermissions -Mailbox $TargetMailbox -ExportPath $targetExportPath -Label "Before"

Write-Host "`nApplying permissions in $Mode mode..." -ForegroundColor Yellow

# ---- Full Access ----
$sourceFA = Get-MailboxPermission $SourceMailbox | Where-Object {$_.User -notlike "NT AUTHORITY\SELF"}

if ($Mode -eq "Replace") {
    $targetFA = Get-MailboxPermission $TargetMailbox | Where-Object {$_.User -notlike "NT AUTHORITY\SELF"}
    foreach ($p in $targetFA) {
        Remove-MailboxPermission -Identity $TargetMailbox -User $p.User -AccessRights FullAccess -Confirm:$false
    }
}

foreach ($p in $sourceFA) {
    Add-MailboxPermission -Identity $TargetMailbox -User $p.User -AccessRights FullAccess -AutoMapping:$false -ErrorAction SilentlyContinue
}

# ---- Send As ----
$sourceSA = Get-ADPermission $SourceMailbox | Where-Object { $_.ExtendedRights -like "*Send-As*" }

if ($Mode -eq "Replace") {
    $targetSA = Get-ADPermission $TargetMailbox | Where-Object { $_.ExtendedRights -like "*Send-As*" }
    foreach ($p in $targetSA) {
        Remove-ADPermission -Identity $TargetMailbox -User $p.User -ExtendedRights Send-As -Confirm:$false
    }
}

foreach ($p in $sourceSA) {
    Add-ADPermission -Identity $TargetMailbox -User $p.User -ExtendedRights Send-As -ErrorAction SilentlyContinue
}

# ---- Send on Behalf ----
$sourceSOB = (Get-Mailbox $SourceMailbox).GrantSendOnBehalfTo

if ($Mode -eq "Replace") {
    Set-Mailbox $TargetMailbox -GrantSendOnBehalfTo $null
}

foreach ($user in $sourceSOB) {
    Set-Mailbox $TargetMailbox -GrantSendOnBehalfTo @{Add=$user}
}

# ---- Folder Permissions ----
# Add languages as needed, e.g. "Kalendar" for Danish, "Kalender" for German, etc.
$folders = @(
    "Calendar", "Kalendar", 
    "Inbox", "Indbakke",
    "Contacts", "Kontakter"
)

foreach ($folder in $folders) {
    $sourceFolderPerms = Get-MailboxFolderPermission "$SourceMailbox`:\$folder" -ErrorAction SilentlyContinue |
        Where-Object { $_.User -ne "Default" -and $_.User -ne "Anonymous" }

    if ($Mode -eq "Replace") {
        $targetFolderPerms = Get-MailboxFolderPermission "$TargetMailbox`:\$folder" -ErrorAction SilentlyContinue |
            Where-Object { $_.User -ne "Default" -and $_.User -ne "Anonymous" }

        foreach ($p in $targetFolderPerms) {
            Remove-MailboxFolderPermission "$TargetMailbox`:\$folder" -User $p.User -Confirm:$false
        }
    }

    foreach ($p in $sourceFolderPerms) {
        Add-MailboxFolderPermission "$TargetMailbox`:\$folder" -User $p.User -AccessRights $p.AccessRights -ErrorAction SilentlyContinue
    }
}

Write-Host "`nPermission copy completed." -ForegroundColor Green
Export-MailboxPermissions -Mailbox $SourceMailbox -ExportPath $sourceExportPath -Label "After"
Export-MailboxPermissions -Mailbox $TargetMailbox -ExportPath $targetExportPath -Label "After"
Write-Host "`nExports saved in: $exportRoot" -ForegroundColor Cyan
Write-Host "Compare BEFORE and AFTER to verify everything applied correctly." -ForegroundColor White
