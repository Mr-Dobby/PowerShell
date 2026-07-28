#########################
#			#
#     Made by RALBE	#
#			#
#########################

$mailboxes = Get-Mailbox -ResultSize Unlimited

# Array to store mailbox rules
$rulesArray = @()

foreach ($mailbox in $mailboxes) {
    $mailboxRules = Get-InboxRule -Mailbox $mailbox.Identity

    foreach ($rule in $mailboxRules) {
        $ruleInfo = [PSCustomObject]@{
            MailboxName     = $mailbox.Name
            RuleName        = $rule.Name
            Description     = $rule.Description
            Priority        = $rule.Priority
        }

        $rulesArray += $ruleInfo
    }
}

$rulesArray | ft