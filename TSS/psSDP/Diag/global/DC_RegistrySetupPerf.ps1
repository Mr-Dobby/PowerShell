#************************************************
# DC_RegistrySetupPerf.ps1
# Version 1.1
# Date: 2009-2019
# Author:  +WalterE
# Description: Collects Registry information
# Called from: all TS_AutoAddCommands_*
#*******************************************************

Trap [Exception]
	{
	 # Handle exception and throw it to the stdout log file. Then continue with function and script.
		 $Script:ExceptionMessage = $_
		 "[info]: Exception occurred."  | WriteTo-StdOut
		 "[info]: Exception.Message $ExceptionMessage."  | WriteTo-StdOut 
		 $Error.Clear()
		 continue
		 # later use return to return the exception message to an object:   return $Script:ExceptionMessage
	}
Import-LocalizedData -BindingVariable UtilsRegistrySetupPerf

$OutputFile= $Computername + "_reg_CurrentVersion.TXT"
$CurrentVersionKeys = "HKLM\Software\Microsoft\Windows NT\CurrentVersion", 
                      "HKLM\Software\Microsoft\Windows\CurrentVersion"   
RegQuery -RegistryKeys $CurrentVersionKeys -OutputFile $OutputFile -fileDescription "CurrentVersion"

$OutputFile= $Computername + "_reg_Uninstall.TXT"
$UninstallKeys = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", 
                 "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
RegQuery -RegistryKeys $UninstallKeys -OutputFile $OutputFile -fileDescription "Uninstall" -Recursive $true

#$OutputFile= $Computername + "_reg_ProductOptions.TXT"
#RegqueryValue -RegistryKeys "HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions" -RegistryValues 'ProductSuite' -OutputFile $OutputFile -fileDescription "Product Options"


$OutputFile= $Computername + "_reg_Recovery.TXT"
$RecoveryKeys = "HKLM\System\CurrentControlSet\Control\CrashControl", 
			"HKLM\System\CurrentControlSet\Control\Session Manager",
			"HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management",
			"HKLM\Software\Microsoft\Windows NT\CurrentVersion\AeDebug"	
RegQuery -RegistryKeys $RecoveryKeys -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfRecoveryDebugInfo -AddFileToReport $false

$RecoveryKeys = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options",
			"HKLM\Software\Microsoft\Windows\Windows Error Reporting",
			"HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting"
RegQuery -RegistryKeys $RecoveryKeys -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfRecoveryDebugInfo -AddFileToReport $true -Recursive $true

$OutputFile= $Computername + "_reg_Startup.TXT"
$StartupKeys = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run", 
         "HKCU\Software\Microsoft\Windows\CurrentVersion\Runonce", 
         "HKCU\Software\Microsoft\Windows\CurrentVersion\RunonceEx", 
         "HKCU\Software\Microsoft\Windows\CurrentVersion\RunServices", 
         "HKCU\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce", 
         "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer\Run", 
         "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", 
         "HKLM\Software\Microsoft\Windows\CurrentVersion\Runonce", 
         "HKLM\Software\Microsoft\Windows\CurrentVersion\RunonceEx", 
         "HKLM\Software\Microsoft\Windows\CurrentVersion\RunServices", 
         "HKLM\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce", 
         "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad"
RegQuery -RegistryKeys $StartupKeys -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfIStartupInfo -AddFileToReport $false

$StartupKeys = "HKCU\Software\Microsoft\Windows NT\CurrentVersion",
				"HKCU\Software\Microsoft\Windows NT\CurrentVersion\Windows",
				"HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer",
				"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$StartupKeysValues = "Load", 
					 "Run", 
					 "Run", 
					 "UserInit"
RegQueryValue -RegistryKeys $StartupKeys -RegistryValues $StartupKeysValues -OutputFile $OutputFile -fileDescription "Startup Info" -CollectResultingFile $true

$OutputFile= $Computername + "_reg_Print.HIV"
RegSave -RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Print" -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfILocalPrintKey

$OutputFile= $Computername + "_reg_Policies.txt"
$PoliciesKeys =  "HKCU\Software\Policies",
				"HKLM\Software\Policies",
				"HKCU\Software\Microsoft\Windows\CurrentVersion\Policies",
				"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"
RegQuery -RegistryKeys $PoliciesKeys  -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfIPolicies -Recursive $true

$OutputFile= $Computername + "_reg_Policies_System.txt"
$PoliciesSystemKeys =  "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
RegQuery -RegistryKeys $PoliciesSystemKeys  -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfIPolicies -Recursive $true

$OutputFile= $Computername + "_reg_TimeZone.txt"
$TimezoneKeys =  "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation",
				"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones"
RegQuery -RegistryKeys $TimezoneKeys  -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfRegTimeZoneInfo -Recursive $true

$OutputFile= $Computername + "_reg_TermServices.txt"
$TSKeys =  "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server",
			"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server",
			"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server Web Access",
			"HKLM\SYSTEM\CurrentControlSet\Services\TermService",
			"HKLM\SYSTEM\CurrentControlSet\Services\TermDD"
RegQuery -RegistryKeys $TSKeys -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfRegTS -Recursive $true

$OutputFile= $Computername + "_reg_CrashDump.TXT"
$CrashDumpKeys = "HKLM\System\CurrentControlSet\Services\i8042prt\crashdump"	
RegQuery -RegistryKeys $CrashDumpKeys -OutputFile $OutputFile -fileDescription $UtilsRegistrySetupPerf.ID_RegSetupPerfRegCrashDump -AddFileToReport $true


# SIG # Begin signature block
# MIIoNwYJKoZIhvcNAQcCoIIoKDCCKCQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAlAZGC7UyxiyVS
# wEt72enCMWJ8GHkk9OgQ7Jpj9tkd8aCCDYUwggYDMIID66ADAgECAhMzAAADTU6R
# phoosHiPAAAAAANNMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMwMzE2MTg0MzI4WhcNMjQwMzE0MTg0MzI4WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDUKPcKGVa6cboGQU03ONbUKyl4WpH6Q2Xo9cP3RhXTOa6C6THltd2RfnjlUQG+
# Mwoy93iGmGKEMF/jyO2XdiwMP427j90C/PMY/d5vY31sx+udtbif7GCJ7jJ1vLzd
# j28zV4r0FGG6yEv+tUNelTIsFmmSb0FUiJtU4r5sfCThvg8dI/F9Hh6xMZoVti+k
# bVla+hlG8bf4s00VTw4uAZhjGTFCYFRytKJ3/mteg2qnwvHDOgV7QSdV5dWdd0+x
# zcuG0qgd3oCCAjH8ZmjmowkHUe4dUmbcZfXsgWlOfc6DG7JS+DeJak1DvabamYqH
# g1AUeZ0+skpkwrKwXTFwBRltAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUId2Img2Sp05U6XI04jli2KohL+8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMDUxNzAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# ACMET8WuzLrDwexuTUZe9v2xrW8WGUPRQVmyJ1b/BzKYBZ5aU4Qvh5LzZe9jOExD
# YUlKb/Y73lqIIfUcEO/6W3b+7t1P9m9M1xPrZv5cfnSCguooPDq4rQe/iCdNDwHT
# 6XYW6yetxTJMOo4tUDbSS0YiZr7Mab2wkjgNFa0jRFheS9daTS1oJ/z5bNlGinxq
# 2v8azSP/GcH/t8eTrHQfcax3WbPELoGHIbryrSUaOCphsnCNUqUN5FbEMlat5MuY
# 94rGMJnq1IEd6S8ngK6C8E9SWpGEO3NDa0NlAViorpGfI0NYIbdynyOB846aWAjN
# fgThIcdzdWFvAl/6ktWXLETn8u/lYQyWGmul3yz+w06puIPD9p4KPiWBkCesKDHv
# XLrT3BbLZ8dKqSOV8DtzLFAfc9qAsNiG8EoathluJBsbyFbpebadKlErFidAX8KE
# usk8htHqiSkNxydamL/tKfx3V/vDAoQE59ysv4r3pE+zdyfMairvkFNNw7cPn1kH
# Gcww9dFSY2QwAxhMzmoM0G+M+YvBnBu5wjfxNrMRilRbxM6Cj9hKFh0YTwba6M7z
# ntHHpX3d+nabjFm/TnMRROOgIXJzYbzKKaO2g1kWeyG2QtvIR147zlrbQD4X10Ab
# rRg9CpwW7xYxywezj+iNAc+QmFzR94dzJkEPUSCJPsTFMIIHejCCBWKgAwIBAgIK
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGggwghoEAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAANNTpGmGiiweI8AAAAA
# A00wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOYl
# 38+tazP4AHHI8lmZ6m5f2jAwCLGMT9eY/4YbDJ//MEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAfDFzcl4QIr6telYGh7yYC66UwTQcCU0AWVbI
# 3ix5x0O5HaOnzL3owN2P/e+HzUXYVykrvIfvLurf/ZtT6wtybV/GtyY0Mzkwa45c
# U87vEZohDUOyzeLQWcJJgDwM+jfdR9PQPx3pRFKCNhdOGxV6zXamsmTew10wYLpz
# auE0HZ/efU2DnTeq4nrX1v/zAU59hbB1GnxpplHWg1gH1phVFdIlXSqvRybWLx+5
# j4NALv3zpcoacWawrlhcU4zQRU4mXe1/R995rNQLoHCrTsUFsK8P7YWimCkp9FSg
# BCYkuqjL89NRJKa/UtwbIK8VrYJXuVg6xfqkSWMyzPC0rtNqhaGCF5IwgheOBgor
# BgEEAYI3AwMBMYIXfjCCF3oGCSqGSIb3DQEHAqCCF2swghdnAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFQBgsqhkiG9w0BCRABBKCCAT8EggE7MIIBNwIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCCIYshPBANp/rIbbX+BGTv9S9ClBARz0z8Y
# FkTF0GND2AIGZVbC5QtmGBEyMDIzMTIwODE5MTk1OC4yWjAEgAIB9KCB0aSBzjCB
# yzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMc
# TWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBU
# U1MgRVNOOkE0MDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1T
# dGFtcCBTZXJ2aWNloIIR6jCCByAwggUIoAMCAQICEzMAAAHWJ2n/ci1WyK4AAQAA
# AdYwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAw
# HhcNMjMwNTI1MTkxMjM0WhcNMjQwMjAxMTkxMjM0WjCByzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE0MDAtMDVF
# MC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzyzNjpvK+bt33GwxDl8nSbW5
# FuVN+ChWn7QvvEMjaqZTCM0kwtU6BNM3MHkArzyH6WLcjwd47enz0aa74cApLFMP
# adDn5mc1jw75LeNAVErbvNd0Ja5aEXaZS89saZNvYyDmePqwWymmZAT2eEeC10IZ
# JB53tGP2IfOWajDEWjFpATOp1MFeWg4sF6nRPScpdItWlmGwqs8AUXTewk5QCcay
# eO6L97n/5RYPYZ1UHKkGIEa0RaQzRTDj9IMM+TY+mtuBmZ3BRBkZisCJi/uSlj51
# YL2nSUkaemaq2FdxZmwZmbbBdIUpVYy0DvJ8XpRle076iCEiLL9m0DIFAVRM/MBx
# clN/Ot4B4/AQmxKSc5u+XyybC9z+upSVDUTewkbHzRGx3V/3eo6KVThcBe6Jpk0I
# 6VN+wP+2EdMCQ07embF1Po/8GJaPW9trdalLYao0bN9qBn9k0UwqEFi4SXt3ACGE
# ZZWv4BCpW7gw7Bt/dusuBDBxcU47I63GRGw1sIwd8K6ddQ8oNUCnA8i1LNmpwaJb
# 0MCUzdJjDrlzvLQc9tJ4P/l8PuMPlvTzJL1tX2mIuN+VYykWbB38SD4yM2dMH+BY
# m5lTyR2fmk8RrFST8cnQob7xgn+H3vF32GPT+ZW5/UnCnOGnU3eOBgqwZSfyTrKA
# ODrzR2Olvl3ClXCCBlsCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBRhmlQ2O00AYjAi
# oNvo/80U3GLGTjAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Ny
# bC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYI
# KwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
# MDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEA1L/kYzYncCcUmzJN
# SL0vC38TTPFWlYacUdUpFvhUWOgCpJ9rNzp9vZxhFZWrW5SL9alUypK1MS2DGdM/
# kQOppn17ntmO/2AW8zOZFHlIFNstTJm4p+sWnU/Q8xAnhOxOPt5Ng5mcblfhixWE
# LKpA23vKMu/twUolNvasmQGE/b0QwCz1AuWcMqD5DXym6o5d1YBU6iLmxEK+ejNG
# HTFpagqqtMlZZ/Zj24Rx81xzo2kLLq6IRwn+1U/HLe/aaN+BXfF3LKpsoXSgctY3
# cpJ64pPhd7xJf/dKmqJ+TfCk2aBrThZWiRT52dg6kLW9llpH7gKBlqxkgONzMpe/
# j2G1LK4vzazLwHfWfifRZarDMF0BcQAe7oyYuIT/AR/I+qpJsuLrpVOUkkGul5BJ
# XGikGEqSXEo5I8kwyDqX+i2QU2hcennqKg2dJVEYYkajvtcqPLlzvPXupIAXgvLd
# VjeSE6l546HGIA78haabbFA4J0VIiNTP0JfztvfVZLTJCC+9oukHeAQbK492foix
# Jyj/XqVMKLD9Ztzdr/coV0NR4rrCZetyH1yMnwSWlr0A4FNyZOHiGUq/9iiI+KbV
# 7ePegkYh04tNdZHMA6XY0CwEIgr6I9absoX8FX9huWcAabSF4rzUW2t+CpA+aKph
# KBdckRUPOIg7H/4Isp/1yE+2GP8wggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZ
# AAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVa
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1
# V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9
# alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmv
# Haus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928
# jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3t
# pK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEe
# HT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26o
# ElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4C
# vEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ug
# poMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXps
# xREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0C
# AwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYE
# FCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtT
# NRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5o
# dG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
# AEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZW
# y4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5t
# aWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAt
# MDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0y
# My5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pc
# FLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpT
# Td2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0j
# VOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3
# +SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmR
# sqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSw
# ethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5b
# RAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmx
# aQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsX
# HRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0
# W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0
# HVUzWLOhcGbyoYIDTTCCAjUCAQEwgfmhgdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNh
# IE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNDAwLTA1RTAt
# RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEB
# MAcGBSsOAwIaAxUA+a9w1UaQBkKPbEy1B3gQvOzaSvqggYMwgYCkfjB8MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAOkdl40wIhgP
# MjAyMzEyMDgxMzI0MjlaGA8yMDIzMTIwOTEzMjQyOVowdDA6BgorBgEEAYRZCgQB
# MSwwKjAKAgUA6R2XjQIBADAHAgEAAgIJyTAHAgEAAgITyzAKAgUA6R7pDQIBADA2
# BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIB
# AAIDAYagMA0GCSqGSIb3DQEBCwUAA4IBAQCRJvDt3rjHXjFKp3OOOkbfvjbC4xHa
# fMOrkc38REngj7Pfpy3ypyzED/EBv6lfMnh+Ifao9RxX/giG5/XuQVDmvlh9Z4Ro
# S7HhnsXLZ2ymliHv/oVE3xYYqfRrsjksXLVK+oln4imggwmfko0SqBwvCYPuEtju
# 4hHHWpIuxHiOxNOGkiDjl4Oj8J/f8xWjGyq6M/2k54vDd3vH6jWJ9zlfUaIZ9SKw
# +hN4PTUOs8iFrWBSO1i3HMhazUtGWCr4eAG+WyZ/gmRTdwHlRrnklylNmDbd+i40
# lEi/tr7LaxySOYmpqDt1Apm5622rFer6RYsYYxo/yD3lidyUy+j4uOKpMYIEDTCC
# BAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHWJ2n/
# ci1WyK4AAQAAAdYwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsq
# hkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgdbnVxhffAeo6/JhaOSgRfoicR7OE
# 1iqdt2CdgbPKa9owgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDWy00NV3jT
# PhAYpzhCTI2XdIzDQ7q/gCvjvD9do+Uk/DCBmDCBgKR+MHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwAhMzAAAB1idp/3ItVsiuAAEAAAHWMCIEIPm/C5BqCTN9
# wSKaNY8oL/vF5rjqPI2PIPJ8c/NFurhPMA0GCSqGSIb3DQEBCwUABIICALl09bUx
# kEqKTBX8t8daz3vUzIJ8uAHRf9OgI9uwE51lgEwOR9MxZ5TD4AuGvU+o+oiTO+k+
# KT9dHlgNwGpO+i3HQJN4cMmvi40ZvX1Hv/a6S4TVWDlzVKoVspKL4RWB+q5gn4hr
# L0/dE0sfcXC1uzGnNSCj9VtrcKmAOV6Racy8JSL4m1g+OFZJ1J8zASMPe9RTgTbd
# GaOTXh+YKWZICyWvXzJGYBWgbefNiG9339EYm4yseqW92+n0XE8NFaPc8fQdome8
# gBA01rN/ENRDaG7pzLRVEgpyiLhobZ76j3vsHFPAojmWGuvWcaJpfLGz+WnYv4yo
# 00Didj1o5VGJm4Uqb8zi3SVw+yZ8WYa5BZY+YmCA6W9R8gLNQM5pauDyIQtmjk0a
# sZSJdD0PHcrp1sOyiGP/ZxgdFCjNVcVAvyTm41i0gUL64qM7eQRDzLfP1WH78Oi1
# NTEDgKX/ekCL1lsYIRd2Y0P9UH63dc7Q0W3vgi32+OrLcYwQ5ICse2zwP92Xko4D
# kD0SaZ1hXeQOhWqcJ7CLNsJmEo1m2H+S9Zoqnvi42BdW5SbbS+7au4VlEH1aieS9
# qNg3LPaOHQAd/VtSNh9uAG77YGdJy8XB60+YCmXCxZb9VjdnGyUtY/cKEWbuhfQU
# DvbutRoovnyCv7Upmjj8Ea6i1lGG6qv4WjU7
# SIG # End signature block
