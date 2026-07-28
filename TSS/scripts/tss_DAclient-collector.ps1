<# Script name: tss_DAclient-collector.ps1
Purpose: - a script you can use to generate the same information that the DCA generates for DirectAccess
 see also DARA: DirectAccess troubleshooting guide https://internal.evergreen.microsoft.com/en-US/help/2921221
#>

param(
	[Parameter(Mandatory=$False,Position=0,HelpMessage='Choose a writable output folder location, i.e. C:\Temp\ ')]
	[string]$DataPath = (Split-Path $MyInvocation.MyCommand.Path -Parent)
)

$ScriptVer="1.01"	#Date: 2018-12-19
$logfile = $DataPath+"\_DirectAccessCli_"+$env:COMPUTERNAME+"_"+(Get-Date -Format yyddMMhhmm)+".txt"

Write-Host "v$ScriptVer Starting collection of debug information for DirectAccess Client on this machine ..." -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "... resulting Logfile: $logfile"
$user = whoami
write-output "v$ScriptVer - Direct Access connectivity status for user: $user is" | out-file -Encoding ascii $logfile
$date = Get-date
Write-output "DATE: $date" | Out-File -Encoding ascii -Append $logfile


# Get a List of all available DTEs
$RegDTEs = get-item hklm:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityAssistant\DTEs -EA SilentlyContinue
$DTEs=($RegDTEs).property -split ("PING:")
$DTEs= $DTEs | Where-Object {$_}
# $DTEs

# Get a List of all available Probes
# Separate them into icmp and http probes
$RegProbes = get-item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityAssistant\Probes" -EA SilentlyContinue
$probelist = ($RegProbes).property
$httpprobe = New-Object System.Collections.ArrayList
$ICMPProbe = New-Object System.Collections.ArrayList
foreach($probe in $probelist)
	{
		if($probe -match "http") {	$httpprobe = $httpprobe + $probe}
		else					 {	$ICMPProbe = $ICMPProbe + $probe}
	}
$httpprobe = $httpprobe -csplit "HTTP:"
$httpprobe = $httpprobe | Where-Object {$_}
$icmpprobe = $icmpprobe -csplit "PING:"
$icmpprobe = $icmpprobe | Where-Object {$_}

# $httpprobe
# $icmpprobe

# check if each of the probe URLs are accessible
if($httpprobe -gt 0)
{
Write-output "`n =============HTTP PROBES=============" | Out-File -Encoding ascii -Append $logfile
foreach ($URL in $httpprobe)
	{
		$result = (Invoke-WebRequest -Uri $URL).statusdescription
		Invoke-WebRequest -Uri $url -ErrorAction SilentlyContinue -ErrorVariable test
		if($result = 'OK' -and !$test)
			{    write-output "$url Pass" | Out-File -Encoding ascii -Append $logfile}
		elseif ($test -match "Unable to connect to the remote server" )
			{	write-output "$url (NAME Resolved)" | Out-File -Encoding ascii -Append $logfile}
		else 
			{	write-output "$url Failed" | Out-File -Encoding ascii -Append $logfile}
	}
}
else
{
Write-output "There are no HTTP probes configured" | Out-File -Encoding ascii -Append $logfile
}	

# check if each ICMP probe is accessible
if($icmpprobe -gt 0)
{
Write-output "`n =============ICMP PROBES=============" | Out-File -Encoding ascii -Append $logfile
foreach($ip in $icmpprobe)
	{
		$result = ping $ip -n 1
		if($result -match "Packets: Sent = 1, Received = 1, Lost = 0")
			{	write-output "$ip PASS" | Out-File -Encoding ascii -Append $logfile}
		elseif($result -match "Pinging")
			{	write-output "$ip Name resolved But ping failed" | Out-File -Encoding ascii -Append $logfile}
		else
			{	write-output "$ip Failed to resolve name" | Out-File -Encoding ascii -Append $logfile}
	}
}
else 
{
Write-output "There are no ICMP probes configured" | Out-File -Encoding ascii -Append $logfile
}

# check if DTEs are pingable
Write-output "`n =============DTEs=============" | Out-File -Encoding ascii -Append $logfile
if ($DTEs) {
  foreach($ip in $DTEs)
	{
		$result = ping $ip -n 1
		if($result -match "Packets: Sent = 1, Received = 1, Lost = 0")
			{	write-output "DTE: $ip PASS" | Out-File -Encoding ascii -Append $logfile}
		else
			{	write-output "DTE: $ip Fail" | Out-File -Encoding ascii -Append $logfile}
	}		
  }
  else
			{	write-output "There are no DTE's to test configured in `n HKLM\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityAssistant\DTEs " | Out-File -Encoding ascii -Append $logfile}

Write-output "`n _____ IP Configuration (Get-NetIPConfiguration -All -Detailed)" | Out-File -Encoding ascii -Append $logfile
Get-NetIPConfiguration -All -Detailed | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ System Info (systeminfo)" | Out-File -Encoding ascii -Append $logfile
systeminfo | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ 6to4 State (Netsh int 6to4 show state)" | Out-File -Encoding ascii -Append $logfile
Netsh int 6to4 show state | Out-File -Encoding ascii -Append $logfile
Write-output "`n _____ teredo State (Netsh int teredo show state)" | Out-File -Encoding ascii -Append $logfile
Netsh int teredo show state | Out-File -Encoding ascii -Append $logfile
Write-output "`n _____ httpstunnel Int (Netsh int httpstunnel show int)" | Out-File -Encoding ascii -Append $logfile
Netsh int httpstunnel show int | Out-File -Encoding ascii -Append $logfile
Write-output "`n _____ dnsclient State (Netsh dnsclient show state)" | Out-File -Encoding ascii -Append $logfile
Netsh dnsclient show state | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ 6to4 Configuration (Get-Net6to4Configuration)" | Out-File -Encoding ascii -Append $logfile
Get-Net6to4Configuration | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Proxy Configuration (netsh winhttp show proxy)" | Out-File -Encoding ascii -Append $logfile
netsh winhttp show proxy | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Teredo Configuration (Get-NetTeredoConfiguration)" | Out-File -Encoding ascii -Append $logfile
Get-NetTeredoConfiguration | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Teredo State (Get-NetTeredoState)" | Out-File -Encoding ascii -Append $logfile
Get-NetTeredoState | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ HTTPs Configuration (Get-NetIPHttpsConfiguration)" | Out-File -Encoding ascii -Append $logfile
Get-NetIPHttpsConfiguration | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ IP-HTTPs State (Get-NetIPHttpsState)" | Out-File -Encoding ascii -Append $logfile
Get-NetIPHttpsState | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Certificate Store (root) (certutil -store root)" | Out-File -Encoding ascii -Append $logfile
certutil -store root | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ NRPT Policy (Get-DnsClientNrptPolicy)" | Out-File -Encoding ascii -Append $logfile
Get-DnsClientNrptPolicy | Out-File -Encoding ascii -Append $logfile
Write-output "`n _____ NCSI Policy (Get-NCSIPolicyConfiguration)" | Out-File -Encoding ascii -Append $logfile
Get-NCSIPolicyConfiguration | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Winsock Catalog (netsh winsock show catalog)" | Out-File -Encoding ascii -Append $logfile
netsh winsock show catalog | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ WFP Netevents (netsh wfp show netevents file=-)" | Out-File -Encoding ascii -Append $logfile
netsh wfp show netevents file=- | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ IPsec Rules (Show-NetIPsecRule -PolicyStore ActiveStore)" | Out-File -Encoding ascii -Append $logfile
Show-NetIPsecRule -PolicyStore ActiveStore | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ IPsec Main Mode SA's (Get-NetIPsecMainModeSA)" | Out-File -Encoding ascii -Append $logfile
Get-NetIPsecMainModeSA | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ IPsec Quick Mode SA's (Get-NetIPsecQuickModeSA)" | Out-File -Encoding ascii -Append $logfile
Get-NetIPsecQuickModeSA | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ IP Address (Get-NetIPAddress)" | Out-File -Encoding ascii -Append $logfile
Get-NetIPAddress | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Route (Get-NetRoute)" | Out-File -Encoding ascii -Append $logfile
Get-NetRoute | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ DA Multisite (Get-DAEntryPointTableItem)" | Out-File -Encoding ascii -Append $logfile
Get-DAEntryPointTableItem | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ DA ConnectionStatus (Get-DAConnectionStatus)" | Out-File -Encoding ascii -Append $logfile
$DaStat_Temp = Get-DAConnectionStatus -EA SilentlyContinue
if ($DaStat_Temp) {
		Get-DAConnectionStatus | Out-File -Encoding ascii -Append $logfile}
Write-output "`n _____ DA Settings (Get-DAClientExperienceConfiguration)" | Out-File -Encoding ascii -Append $logfile
Get-DAClientExperienceConfiguration | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Prefix Policy Table (Get-NetPrefixPolicy)" | Out-File -Encoding ascii -Append $logfile
Get-NetPrefixPolicy | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Certificate Store (my) (certutil -silent -store -user my)" | Out-File -Encoding ascii -Append $logfile
certutil -silent -store -user my | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ Groups (whoami /all)" | Out-File -Encoding ascii -Append $logfile
whoami /all | Out-File -Encoding ascii -Append $logfile

Write-output "`n _____ === END of DAclient collector ===" | Out-File -Encoding ascii -Append $logfile	

Write-Host "$(Get-Date -Format 'HH:mm:ss') Done - tss_DAclient-collector`n" -ForegroundColor White -BackgroundColor DarkGreen
# SIG # Begin signature block
# MIInzgYJKoZIhvcNAQcCoIInvzCCJ7sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB3WXR7ETQ8wSNt
# k9DhPmXNG7AVJOPwgtQnBS/BFuA6saCCDYUwggYDMIID66ADAgECAhMzAAADri01
# UchTj1UdAAAAAAOuMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwODU5WhcNMjQxMTE0MTkwODU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQD0IPymNjfDEKg+YyE6SjDvJwKW1+pieqTjAY0CnOHZ1Nj5irGjNZPMlQ4HfxXG
# yAVCZcEWE4x2sZgam872R1s0+TAelOtbqFmoW4suJHAYoTHhkznNVKpscm5fZ899
# QnReZv5WtWwbD8HAFXbPPStW2JKCqPcZ54Y6wbuWV9bKtKPImqbkMcTejTgEAj82
# 6GQc6/Th66Koka8cUIvz59e/IP04DGrh9wkq2jIFvQ8EDegw1B4KyJTIs76+hmpV
# M5SwBZjRs3liOQrierkNVo11WuujB3kBf2CbPoP9MlOyyezqkMIbTRj4OHeKlamd
# WaSFhwHLJRIQpfc8sLwOSIBBAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhx/vdKmXhwc4WiWXbsf0I53h8T8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMTgzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AGrJYDUS7s8o0yNprGXRXuAnRcHKxSjFmW4wclcUTYsQZkhnbMwthWM6cAYb/h2W
# 5GNKtlmj/y/CThe3y/o0EH2h+jwfU/9eJ0fK1ZO/2WD0xi777qU+a7l8KjMPdwjY
# 0tk9bYEGEZfYPRHy1AGPQVuZlG4i5ymJDsMrcIcqV8pxzsw/yk/O4y/nlOjHz4oV
# APU0br5t9tgD8E08GSDi3I6H57Ftod9w26h0MlQiOr10Xqhr5iPLS7SlQwj8HW37
# ybqsmjQpKhmWul6xiXSNGGm36GarHy4Q1egYlxhlUnk3ZKSr3QtWIo1GGL03hT57
# xzjL25fKiZQX/q+II8nuG5M0Qmjvl6Egltr4hZ3e3FQRzRHfLoNPq3ELpxbWdH8t
# Nuj0j/x9Crnfwbki8n57mJKI5JVWRWTSLmbTcDDLkTZlJLg9V1BIJwXGY3i2kR9i
# 5HsADL8YlW0gMWVSlKB1eiSlK6LmFi0rVH16dde+j5T/EaQtFz6qngN7d1lvO7uk
# 6rtX+MLKG4LDRsQgBTi6sIYiKntMjoYFHMPvI/OMUip5ljtLitVbkFGfagSqmbxK
# 7rJMhC8wiTzHanBg1Rrbff1niBbnFbbV4UDmYumjs1FIpFCazk6AADXxoKCo5TsO
# zSHqr9gHgGYQC2hMyX9MGLIpowYCURx3L7kUiGbOiMwaMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGZ8wghmbAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFNK
# TdcdsD6DzZv95MJssIfJxfp0Uqu8ssWbLnUeu6uDMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAdSAucEtWRbPRu6F79esLeHewwRgMIVcg+dqE
# WdxKWDLzRvAXB0ybtco27uVhUO0g9adllht9zi2o9tmvfx2GW2auM4knOMmd4cKF
# Ol1ILtyrg+gB8dKV34FoNnXWl5mtUPfDHTGtANQY2TdMXwU5a54lRK+haGMuBXTG
# k1kChhtrcP2CazmmjOUsMGg/Q4LBYB7NV4du8mC8eqoUUmGUG6MVqzezVgZ9Ut3w
# x0JohFFgYvaULyZO15WY9TsvP4m7rlreVKYiHj1unrLJ6YUXGUtxkQXuprOE3GsM
# ea9paRh1AZ2vGrkXh3eHbmJUFTeh63bbbjysnfpyKux2frZDkqGCFykwghclBgor
# BgEEAYI3AwMBMYIXFTCCFxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFZBgsqhkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCDBlCzbxYiUfSXOZf4fyQvXVFRH3kE9RQDk
# RZjHFQYTwQIGZlUmjP3tGBMyMDI0MDYxMjE1MDA0MS4yODNaMASAAgH0oIHYpIHV
# MIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOjA4NDItNEJFNi1DMjlBMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHajtXJ
# WgDREbEAAQAAAdowDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwHhcNMjMxMDEyMTkwNjU5WhcNMjUwMTEwMTkwNjU5WjCB0jELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9z
# b2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjowODQyLTRCRTYtQzI5QTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJOQ
# Bgh2tVFR1j8jQA4NDf8bcVrXSN080CNKPSQo7S57sCnPU0FKF47w2L6qHtwm4EnC
# lF2cruXFp/l7PpMQg25E7X8xDmvxr8BBE6iASAPCfrTebuvAsZWcJYhy7prgCuBf
# 7OidXpgsW1y8p6Vs7sD2aup/0uveYxeXlKtsPjMCplHkk0ba+HgLho0J68Kdji3D
# M2K59wHy9xrtsYK+X9erbDGZ2mmX3765aS5Q7/ugDxMVgzyj80yJn6ULnknD9i4k
# UQxVhqV1dc/DF6UBeuzfukkMed7trzUEZMRyla7qhvwUeQlgzCQhpZjz+zsQgpXl
# PczvGd0iqr7lACwfVGog5plIzdExvt1TA8Jmef819aTKwH1IVEIwYLA6uvS8kRdA
# 6RxvMcb//ulNjIuGceyykMAXEynVrLG9VvK4rfrCsGL3j30Lmidug+owrcCjQagY
# mrGk1hBykXilo9YB8Qyy5Q1KhGuH65V3zFy8a0kwbKBRs8VR4HtoPYw9z1DdcJfZ
# BO2dhzX3yAMipCGm6SmvmvavRsXhy805jiApDyN+s0/b7os2z8iRWGJk6M9uuT24
# 93gFV/9JLGg5YJJCJXI+yxkO/OXnZJsuGt0+zWLdHS4XIXBG17oPu5KsFfRTHREl
# oR2dI6GwaaxIyDySHYOtvIydla7u4lfnfCjY/qKTAgMBAAGjggFJMIIBRTAdBgNV
# HQ4EFgQUoXyNyVE9ZhOVizEUVwhNgL8PX0UwHwYDVR0jBBgwFoAUn6cVXQBeYl2D
# 9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
# LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQAD
# ggIBALmDVdTtuI0jAEt41O2OM8CU237TGMyhrGr7FzKCEFaXxtoqk/IObQriq1ca
# HVh2vyuQ24nz3TdOBv7rcs/qnPjOxnXFLyZPeaWLsNuARVmUViyVYXjXYB5DwzaW
# ZgScY8GKL7yGjyWrh78WJUgh7rE1+5VD5h0/6rs9dBRqAzI9fhZz7spsjt8vnx50
# WExbBSSH7rfabHendpeqbTmW/RfcaT+GFIsT+g2ej7wRKIq/QhnsoF8mpFNPHV1q
# /WK/rF/ChovkhJMDvlqtETWi97GolOSKamZC9bYgcPKfz28ed25WJy10VtQ9P5+C
# /2dOfDaz1RmeOb27Kbegha0SfPcriTfORVvqPDSa3n9N7dhTY7+49I8evoad9hdZ
# 8CfIOPftwt3xTX2RhMZJCVoFlabHcvfb84raFM6cz5EYk+x1aVEiXtgK6R0xn1wj
# MXHf0AWlSjqRkzvSnRKzFsZwEl74VahlKVhI+Ci9RT9+6Gc0xWzJ7zQIUFE3Jiix
# 5+7KL8ArHfBY9UFLz4snboJ7Qip3IADbkU4ZL0iQ8j8Ixra7aSYfToUefmct3dM6
# 9ff4Eeh2Kh9NsKiiph589Ap/xS1jESlrfjL/g/ZboaS5d9a2fA598mubDvLD5x5P
# P37700vm/Y+PIhmp2fTvuS2sndeZBmyTqcUNHRNmCk+njV3nMIIHcTCCBVmgAwIB
# AgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1
# WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O
# 1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
# hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t
# 1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxq
# D89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmP
# frVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSW
# rAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv
# 231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zb
# r17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYcten
# IPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQc
# xWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17a
# j54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
# n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJ
# oEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01p
# Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYB
# BQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9v
# Q2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3h
# LB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x
# 5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
# y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1A
# oL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbC
# HcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB
# 9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNt
# yo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3
# rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcV
# v7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A24
# 5oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lw
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAtQwggI9AgEBMIIBAKGB2KSB1TCB
# 0jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMk
# TWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjowODQyLTRCRTYtQzI5QTElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAQqIfIYljHUbNoY0/
# wjhXRn/sSA2ggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOoUEtswIhgPMjAyNDA2MTIyMDI4MTFaGA8yMDI0MDYx
# MzIwMjgxMVowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6hQS2wIBADAHAgEAAgIF
# 1DAHAgEAAgISijAKAgUA6hVkWwIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
# AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GB
# AJ0z9uE0NDS0k2uBbxoaKWPhQaeAEqKNUzFisEFCoSf+F726aRTDz1Nz4h9qKyvW
# SR295/nX7xRXU+w5RYIOPuOzauItthdHlTntO+rLgR992WuO3/I8SzHGnY8J5Igs
# YvcEUox7mi3zuTTlnT4S644yTSJoq3ZGNl0pZsrbXCQ9MYIEDTCCBAkCAQEwgZMw
# fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHajtXJWgDREbEAAQAA
# AdowDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAvBgkqhkiG9w0BCQQxIgQgKTAKn1ktyZzASeYOpTOveLhqnFK1aD8FyY1m57Rk
# M94wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAipaNpYsDvnqTe95Dj1C09
# 020I5ljibrW/ndICOxg9xjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAAB2o7VyVoA0RGxAAEAAAHaMCIEICrzuvWZNlHyXVa2qUUf7AZf
# PvZri8IdhDezfur4sbhNMA0GCSqGSIb3DQEBCwUABIICADKCly3Hpxv2uUDbMxF5
# ghHV+4WisrcQYCe8gUbxycK1mmRNPD1JYMLV664NRjEW3DaQDlzttSOvUhxWYJY+
# nzWA7xEZVhIPAGy+/OKRQui4+F9aiYr057yjZNz8yS0iBWTp4y5+ig9S8jfYJOLe
# r7HQcXxBExbmNWk7CMr29Yb4mt7eQ++uVgLOl44n/qXVKwh/lb0rj4o6aBKUJhmV
# XltUxg+aacVB3cUQntNwA99RbFiwlvs/OWYTmVd3QU3JyVcdSIgegwRdKiQ55bBQ
# QALO3rC7t5//ev1+yS1U18lXXvVfrFocHWZnCKKOb9IEp0FZY+lCTq4gdvGIf0Yp
# CItfpcUVM2D3eqzQN7swAHX/lVDLmIRLoPAAA7vAudHhr7n1BDyuWBJ5VRBE26tj
# coGGNc+5NRlahKIfBOZBP5JUvI/gWliu98Nlnx9D/0okWX8nSmXwalliQuBmWPDR
# A43URKuldAB0TseW07G50KM7k0qX4nj694SjzrWofpjwPrMup4k4+XDADrn0TBAp
# BUjr6ZuJ+ZREJUvOx6tsubK9ApzKTKHBbQqMC7f0+N+T3DibvWamYepqqUOVptHz
# SusaiNp7/UT/I4zgbPr9p17UUhnFyoTxtjedG3vo23Ut5sE0gkj5e98WN5Exc1n2
# 2U38r9KRM1g+RxwIIqDWfmF0
# SIG # End signature block
