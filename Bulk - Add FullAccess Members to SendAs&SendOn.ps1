# Connect to Exchange Online
#Connect-ExchangeOnline
$SharedMailbox = "mailbox@contoso.com"
# Get Full Access users

$Users = Get-MailboxPermission -Identity $SharedMailbox |

Where-Object {
    $_.AccessRights -contains "FullAccess" -and
    $_.IsInherited -eq $false -and
    $_.User -notlike "NT AUTHORITY\SELF"
}

foreach ($User in $Users) {
    Write-Host ""
    Write-Host "Mailbox : $SharedMailbox" -ForegroundColor Cyan
    Write-Host "User    : $($User.User)" -ForegroundColor Yellow
    $Confirm = Read-Host "Grant SendAs and SendOnBehalf? (Y/N)"

    if ($Confirm -notmatch '^(Y|YES)$') {
        Write-Host "Skipped" -ForegroundColor Gray
        continue
    }

    # Send As
    try {
        Add-RecipientPermission -Identity $SharedMailbox -Trustee $User.User -AccessRights SendAs -Confirm:$false
        Write-Host "✓ SendAs added" -ForegroundColor Green
    }
    catch {
        Write-Warning "SendAs: $($_.Exception.Message)"
    }

    # Send On Behalf
    try {
        Set-Mailbox -Identity $SharedMailbox -GrantSendOnBehalfTo @{Add=$User.User}
        Write-Host "✓ SendOnBehalf added" -ForegroundColor Green
    }
    catch {
        Write-Warning "SendOnBehalf: $($_.Exception.Message)"
    }
}