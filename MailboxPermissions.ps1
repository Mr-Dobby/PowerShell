[CmdletBinding()]
param(
	[string]$CsvPath = ("C:\\MailboxesUserHasAccessTo_" + ((Get-Date -format "MMM-dd hh-mm-ss tt").ToString()) + ".csv")
)

Connect-ExchangeOnline

Get-Mailbox | 
Get-MailboxPermission | 
where {$_.user.tostring() -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false} | 
Select Identity,User,@{Name='Access Rights';Expression={[string]::join(', ', $_.AccessRights)}} | 
Export-Csv -NoTypeInformation $CsvPath

Disconnect-ExchangeOnline
####################################################################
