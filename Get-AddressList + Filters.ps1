Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

Get-AddressList
Get-GlobalAddressList

((Alias -ne $null) -and (((((ObjectCategory -like 'person') -and (ObjectClass -eq 'contact'))) -or (Office -eq 'External'))))
((Alias -ne $null) -and (((ObjectCategory -like 'person') -and (ObjectClass -eq 'contact'))))
((Alias -ne $null) -and (((ObjectClass -eq 'contact')) -or (Office -eq 'External')))
((Alias -ne $null) -and (((ObjectCategory -like 'person') -and (ObjectClass -eq 'contact'))))
Remove-GlobalAddressList "All Groups"
((Alias -ne $null) -and (((((((((((ObjectClass -eq 'user') -or (ObjectClass -eq 'contact'))) -or (ObjectClass -eq 'msExchSystemMailbox'))) -or (ObjectClass -eq 'msExchDynamicDistributionList'))) -or (ObjectClass -eq 'group'))) -or (ObjectClass -eq 'publicFolder'))))
New-GlobalAddressList -Name 'Offline Global Address List' -RecipientFilter {((Alias -ne $null) -and (((((((((((ObjectClass -eq 'user') -or (ObjectClass -eq 'contact'))) -or (ObjectClass -eq 'msExchSystemMailbox'))) -or (ObjectClass -eq 'msExchDynamicDistributionList'))) -or (ObjectClass -eq 'group'))) -or (ObjectClass -eq 'publicFolder'))))}
((Alias -ne $null) -and (((ObjectClass -eq 'user') -or (ObjectClass -eq 'contact') -or (ObjectClass -eq 'msExchSystemMailbox') -or (ObjectClass -eq 'msExchDynamicDistributionList') -or (ObjectClass -eq 'group') -or (ObjectClass -eq 'publicFolder'))))
$AL = Get-AddressList -Identity "Eksterne"; Get-Recipient -ResultSize unlimited -RecipientPreviewFilter $AL.RecipientFilter | select Name,PrimarySmtpAddress,HiddenFromAddressListsEnabled





