<# Filename: tss_EventCreate.ps1 [-EventID -EvtLogName] [-Computername]
:: Purpose:  create an Event log entry in [EvtLogName] with [Event ID]
::           the tss.cmd script has a switch to stop data collection upon such event.
:: Example: tss_EventCreate.cmd 999 System
::
::  Copyright ^(C^) Microsoft. All rights reserved.
::  THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
::  IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
::
:: Last-Update by waltere: 2022-10-06

The tss_EventCreate.cmd can only write event ID 0 - 1000 using EVENTCREATE.exe

:: in Powershell 
:: 1.  do this once to register a new Event Source ( not needed for writing events with a known Source: 
   New-EventLog –LogName "System" –Source 'TSS'
:: 2.  Write-EventLog -LogName "System" -Source "TSS" -EventID 15004 -EntryType Information -Message "TSS added this EventID as stop trigger." -Category 1 -RawData 10,20 -ComputerName $Env:Computername
:: in CMD script you would invoke: Powershell "Write-EventLog -LogName 'System' -Source 'TSS' -EventID 999 -EntryType Information -Message 'TSS added this EventID as stop trigger.' -Category 1 -RawData 10,20 -ComputerName $Env:Computername"

:: for testing it is sufficient to specify an exiting "Source", just look up an existing eventlog entry
example:
  Write-EventLog -LogName "System" -Source "Outlook" -EventID 59 -EntryType Information -Message "Test this EventID as stop trigger." -Category 1 -RawData 10,20 -ComputerName $Env:Computername
#>

<#
.SYNOPSIS
	Write any EventID into any Eventlog file, i.e. for testing a TSS.ps1 -WaitEvent Evt:<ID> trigger
	see Get-Help Write-EventLog -detailed
	for registering an own source, use: New-EventLog –LogName "System" –Source 'TSS'

.DESCRIPTION  
	Script will write any EventID into any Eventlog file, i.e. for testing a TSS.ps1 -WaitEvent Evt:<ID> trigger
	You can also register a new event Source 'TSS', but this source will be bound to the eventlog name. so if you change the eventlog name you need to specify a new source-name, or use Unregister-Event.
	Please look up any existing event in the <eventlog>.evtx file you are interested in and remember the ID and Source

.NOTES

.PARAMETER LogName
 	Specify the name of the Windows Event Log, default = "System"
	Default is current folder
.PARAMETER Source
	The Event Source, which is known to exist in the given EventLog, default = "Outlook"
.PARAMETER EntryType
	The type of Event, default = "Warning"
.PARAMETER Message
	The Event message you want to log, example "Testing this EventID as stop trigger. Event-ID was sent by computer $Env:Computername"
.PARAMETER Computername
	Which computer do you want to write the eventlog, default = $Env:Computername	
.PARAMETER EventID
	default EventID = 999, because TSS listens always to EventID 999 in addition to other IDs specified in trigger Stop:Evt:<ID>
	
.PARAMETER UseExitCode
	 This switch will cause the script to close after the error is logged if an error occurs.
	 It is used to pass the error number back to the task scheduler or CMD script.

.EXAMPLE
	Write-EventLog -LogName "System" -Source "Outlook" -EventID 59 -EntryType Information -Message "Test this EventID as stop trigger." -Category 1 -RawData 10,20 -ComputerName $Env:Computername
	Example 1: will  write the EventID 59 into local or remote computers "System" Eventlog with the given informational message
#>

param(
	[string]$LogName 	= 'System',								# Application","System",""
	[string]$Source 	= "EventLog",							# Source module, which is known to exist in the given EventLog
	[string]$EntryType 	= "Warning",							# "Information","Warning","Error"
	[string]$Computername = "$Env:Computername",				# Remote Computername
	[string]$Username 	= "$Env:USERDOMAIN\$Env:Username",		# (domain) user who has permission to write into the remote computer'S eventlog
	[string]$Message 	= "StopMe Event ID: $EventID test from script $scriptName in order to stop data collection. Event was sent by user $Username on computer $Env:Computername at $SendTimeStamp UTC",
	[int32]$EventID 	= 999,									# Event ID number
	[string]$Folderpath = $global:LogFolder,					# $(Split-Path $MyInvocation.MyCommand.Path -Parent),
	[switch]$UseExitCode = $true								# This will cause the script to bail out after the error is logged if an error occurs.
)


#region: customization section of script, logging configuration ----------------------#
	$LogFileScript 	= $Folderpath +"\"+ $ENV:ComputerName + "__WriteEventLog.txt"
	$ErrorThrown 	= $null
	$ScriptVersion	= 1.00	#2022-10-06
#endregion: customization section of script, logging configuration ------------------#
$scriptName = $MyInvocation.MyCommand.Name
$ScriptBeginTimeStamp = Get-Date
#New-EventLog –LogName "System" –Source 'TSS'

#region: Helper Functions -----------------------------------------------------------#
function ExitWithCode ($Ecode) {
	# set ErrorLevel to be picked up by invoking CMD script
	if ( $UseExitCode ) {
		WriteInfo "Return Code $Ecode"
		#error.clear()	# clear script errors
		exit $Ecode
		} #end UseExitCode
}
#endregion: Helper Functions

#region: MAIN
try {
	$SendTimeStamp = (Get-Date).ToUniversalTime().ToString("yyMMdd-HHmmss.fffffff")
	Write-Host "...sending Event ID $EventID Type $EntryType to $LogName eventlog on $Computername, sent by $Username at $SendTimeStamp UTC from $Env:Computername"
	#Write-EventLog -LogName $LogName -EntryType $EntryType -Source $Source -EventID $EventID -Message "This is StopMe Event ID: $EventID from script $scriptName in order to stop data collection. Event was sent by user $Username on computer $Env:Computername at $SendTimeStamp UTC" -Category 1 -ComputerName $Env:Computername
	Write-EventLog -LogName $LogName -EntryType $EntryType -Source "EventLog" -EventId $EventID -Message "This is user initiated StopMe Event ID: $EventID from script $scriptName in order to stop data collection. Event was sent by user $Env:username on computer $Env:Computername at $SendTimeStamp UTC" -Category 1 -ComputerName $Env:Computername
}
catch {
	Write-Host -ForegroundColor Red -BackgroundColor Black "An Error occured"
	Write-Host -ForegroundColor Red -BackgroundColor Black $error[0].Exception.Message
	$ErrorThrown = $true
}
finally {
	$ScriptEndTimeStamp = Get-Date
	$LogLevel = 0
	Write-Host -ForegroundColor Black -BackgroundColor Gray "`nScript $scriptName v$ScriptVersion execution finished. Duration interaction: $(New-TimeSpan -Start $ScriptBeginTimeStamp -End $ScriptEndTimeStamp)"

  if($ErrorThrown) {Throw $error[0].Exception.Message}
}
#endregion: MAIN


# SIG # Begin signature block
# MIIoOQYJKoZIhvcNAQcCoIIoKjCCKCYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCoknJDGTGkYGQS
# dbTiDZ7IAt/O4bExM2fgW8UDCa1XHqCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGgowghoGAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINFt
# S40i+kHZ0C3lnaNHl4aR/b64t45QYOMJRf6G3qc7MEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAvrE2mNuBWJ+boWyyeBrOOzsqcs8iIW8YAdTa
# lU9GpKo+5hbHPQtHuo/nfRTgo8PatW7LBqP8fjlyPqd2j0L4Q7kjfTTVizsONV8B
# UMF5qwcWocdGIBwMZ667O9+Har42xS3Gk9+sH10qr2X84vbH+VISfwJkGb02+D8H
# TxJuaJv+iLICitneI3avgPdERACSSaE8OhUPXnZ2Iqx+TEa7OJtgg+7afsTenjFF
# lPB06U0P/gF515afZ3zV3ZNnmWTMC67KIc8+ihgdbgi0yOHGgi7eyKQOojEdz8o9
# 8HXxE+niVnSHTtFiI+d2LRfG+Yva3c9+C2L+TM7jUXXmkxkFSqGCF5QwgheQBgor
# BgEEAYI3AwMBMYIXgDCCF3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFSBgsqhkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCBePnbjj1Urx5DRPGlTe4l1RNTg7XzuVT8K
# dB1w2LpxwwIGZkZX1jFFGBMyMDI0MDYxMjE1MDA0Mi4xODRaMASAAgH0oIHRpIHO
# MIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
# IFRTUyBFU046MzMwMy0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFNlcnZpY2WgghHqMIIHIDCCBQigAwIBAgITMwAAAebZQp7qAPh94QAB
# AAAB5jANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDAeFw0yMzEyMDYxODQ1MTVaFw0yNTAzMDUxODQ1MTVaMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC9vph84tgluEzm/wpNKlAj
# cElGzflvKADZ1D+2d/ieYYEtF2HKMrKGFDOLpLWWG5DEyiKblYKrE2nt540OGu35
# Zx0gXJBE0zWanZEAjCjt4eGBi+uakZsk70zHTQHHyfP+B3m2BSSNFPhgsVIPp6vo
# /9t6OeNezIwX5E5+VwEG37nZgEexQF2fQZYbxQ1AauqDvRdXsSpK1dh1UBt9EaMs
# zuucaR5nMwQN6sDjG99FzdK9Atzbn4SmlsoLUtRAh/768sKd0Y1hMmKVHwIX8/4J
# uURUBRZ0JWu0NYQBp8khku18Q8CAQ500tFB7VH3pD8zoA4lcA7JkxTGoPKrufm+l
# RZAA4iMgbcLZ2P/xSdnKFxU8vL31RoNlZJiGL5MqTXvvyBLz+MRP4En9Nye1N8x/
# lJD1stdNo5wJG+mgXsE/zfzg2GaVqQczFHg0Nl8bpIqnNFUReQRq3C1jVYMCSceg
# NzHeYtw5OmZ/7eVnRmjXlCsLvdsxOzc1YVn6nZLkQD5y31HYrB9iIHuswhaMv2hJ
# NNjVndkpWy934PIZuWTMk360kjXPFwl2Wv1Tzm9tOrCq8+l408KIL6J+efoGNkR8
# YB3M+u1tYeVDO/TcObGHxaGFB6QZxAUpnfB5N/MmBNxMOqzG1N8QiwW8gtjjMJiF
# Bf6iYYrCjtRwF7IPdQLFtQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFOUEMXntN54+
# 11ZM+Qu7Q5rg3Fc9MB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBhbuogTapRsuwS
# kaFMQ6dyu8ZCYUpWQ8iIrbi40tU2hK6pHgu0hj0z/9zFRRx5DfhukjvbjA/dS5VY
# fxz1EIbPlt897MJ2sBGO2YLYwYelfJpDwbB0XS9Zkrqpzq6X/lmDQDn3G5vcYpYQ
# CJ55LLvyFlJ195AVo4Wy8UX5p7g9W3MgNHQMpM+EV64+cszj4Ho5aQmeKGtKy7w7
# 2eRY/vWDuptrvzruFNmKCIt12UcA5BOsXp1Ptkjx2yRsCj77DSml0zVYjqW/ISWk
# rGjyeVJ+khzctxaLkklVwCxigokD6fkWby0hCEKTOTPMzhugPIAcxcHsR2sx01YR
# a9pH2zvddsuBEfSFG6Cj0QSvEZ/M9mJ+h4miaQSR7AEbVGDbyRKkYn80S+3AmRlh
# 3ZOe+BFqJ57OXdeIDSHbvHzJ7oTqG896l3eUhPsZg69fNgxTxlvRNmRE/+61Yj7Z
# 1uB0XYQP60rsMLdTlVYEyZUl5MLTL5LvqFozZlS2Xoji4BEP6ddVTzmHJ4odOZMW
# TTeQ0IwnWG98vWv/roPegCr1G61FVrdXLE3AXIft4ZN4ZkDTnoAhPw7DZNPRlSW4
# TbVj/Lw0XvnLYNwMUA9ouY/wx9teTaJ8vTkbgYyaOYKFz6rNRXZ4af6e3IXwMCff
# CaspKUXC72YMu5W8L/zyTxsNUEgBbTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKb
# SZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIy
# NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXI
# yjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjo
# YH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1y
# aa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v
# 3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pG
# ve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viS
# kR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYr
# bqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlM
# jgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSL
# W6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AF
# emzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIu
# rQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIE
# FgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWn
# G1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEW
# M2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5
# Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBi
# AEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV
# 9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3Js
# Lm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAx
# MC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2
# LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv
# 6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZn
# OlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1
# bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4
# rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU
# 6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDF
# NLB62FD+CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/
# HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdU
# CbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKi
# excdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTm
# dHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZq
# ELQdVTNYs6FwZvKhggNNMIICNQIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjMzMDMtMDVF
# MC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMK
# AQEwBwYFKw4DAhoDFQDiWNBeFJ9jvaErN64D1G86eL0mu6CBgzCBgKR+MHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hPEJTAi
# GA8yMDI0MDYxMjA2NTIyMVoYDzIwMjQwNjEzMDY1MjIxWjB0MDoGCisGAQQBhFkK
# BAExLDAqMAoCBQDqE8QlAgEAMAcCAQACAgzLMAcCAQACAhN9MAoCBQDqFRWlAgEA
# MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAI
# AgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAIAlF48QzlI0/nUHE309In7Re3wM
# MsGVjJvH8QyDFSgdoxa7iAmmbjxSHDj6ROWkpC+pwCh+5mnmtyOY+qgPJEZEcevG
# QOsMAgxSDwgFkjGjLOH10ANMGpv4Lgoff15oV0kg8+vW2w/iCzmazenro/KU2s6j
# Z27cpZ1OxWwThafsEoZaHcAVrR5ltkJExcEgSxfLnFTE9citlY/FGfJPAoPLArf9
# as9MesxZrnhwS1Rdd46zfa2R/Wt/seKge8aJHEJfs3QRx4M+hhQUVBnsyUrMImxM
# vXTW9w442Q6+6RTSZb8etmYaQLmFut1dPrTkvFtMH2B/ScfASx1jnJLzzY4xggQN
# MIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAebZ
# Qp7qAPh94QABAAAB5jANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0G
# CyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCBUX49xxKX1EqMzwlzFH3Ap5rph
# v3r0b+d/Aa/egTu/MzCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIM+7o4ao
# HrMJaG8gnLO1q16hIYcRnoy6FnOCbnSD0sZZMIGYMIGApH4wfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAHm2UKe6gD4feEAAQAAAeYwIgQgy6KmSaER
# UFw5zM8ixrWjedEWrCkXYG0+8JQBRQ+GJXIwDQYJKoZIhvcNAQELBQAEggIAC1VR
# 97AqmSuj6lfbzG2bRlGmpR2Sd7mGq+ouQ64/fV8xTVSi5IMEJK33Tgw6mxlixEW5
# LpA55e7AhwQoI4kQQBOJCeQuI2uww+NQYhxrWgO+PVWKCbFfPPu/2k827bwrAL/I
# AWddKLmgSodFlJNnnwokdiQCInIjXKcUol1zTE2KDNXjeEAj4LJKM3VzZYZ01mQL
# AxqWdiBoz/4ShUPq8ZLyEymNzZlp31S8aMZ8jk97JC/5fEjE8oYiBNTibzoS1m+6
# XgTg51+8fmkBvBudxIHDKjG+zZf3b30ZhWIC79khKVd/IdZwiry2fr9cMd/R4ir7
# 5/77ZzPueGzhkmQqZtg29wIT0Gf4nT5LprI2MDU6vw1xK3f1+62L5rWengPo7naW
# v03MbvFSo2RnD4j7Fpizy/LUuVi59aE94Sk349muIxP9A2Os2aOO+0yyssBu5lKN
# UNKiL5SC0NXoNR8nJ5HNTrepyINiI1tBJjnXTqBT4jdX2AJ5ZygUt4bN6lXpg8j6
# wo8Pe8pRR3xNeMbfxHrJYYdmwl+/ff4XqfHCixzf7p2nOVDNYdqDtVKW+cu2yrgL
# qeUXBC2Hp2xWYM7kzSUGn3nMs1B8stBBGwK7oNIgT+rtHxAcGHH38C0PDYSDvpO3
# GU2wrBh6R3xwr4EJPs5ZbUO1zuGmSkPkio59RCg=
# SIG # End signature block
