#************************************************
# DC_NfsServer-Component.ps1
# Version 1.0.06.26.14: Created script. 
# Version 1.1.08.13.14: Updated comments. Added data collection for NIS registry value: "HKLM\system\CurrentControlSet\services\NisSvc". TFS264084
# Date: 2014
# Author: Boyd Benson (bbenson@microsoft.com)
# Description: Collects information about NFS Server.
# Called from: Main Networking Diag, etc.
#*******************************************************

Import-LocalizedData -BindingVariable ScriptVariable

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

function RunNfsAdmin([string]$NfsCommandToExecute="")
{
	Write-DiagProgress -Activity $ScriptVariable.ID_CTSSMBClient -Status "net $NfsCommandToExecute"
	
	$NfsCommandToExecuteLength = $NfsCommandToExecute.Length + 6
	"`n`n`n" + "=" * ($NfsCommandToExecuteLength) + "`r`n" + "nfsadmin $NfsCommandToExecute" + "`r`n" + "=" * ($NfsCommandToExecuteLength) | Out-File -FilePath $OutputFile -append

	$CommandToExecute = "cmd.exe /c nfsadmin.exe " + $NfsCommandToExecute + " >> $OutputFile "
	RunCmD -commandToRun $CommandToExecute  -CollectFiles $false
	"`n" | Out-File -FilePath $OutputFile -append
	"`n" | Out-File -FilePath $OutputFile -append
	"`n" | Out-File -FilePath $OutputFile -append
}

function RunPS ([string]$RunPScmd="", [switch]$ft)
{
	$RunPScmdLength = $RunPScmd.Length
	"-" * ($RunPScmdLength)		| Out-File -FilePath $OutputFile -append
	"$RunPScmd"  				| Out-File -FilePath $OutputFile -append
	"-" * ($RunPScmdLength)  	| Out-File -FilePath $OutputFile -append
	
	if ($ft)
	{
		# This format-table expression is useful to make sure that wide ft output works correctly
		Invoke-Expression $RunPScmd	|format-table -autosize -outvariable $FormatTableTempVar | Out-File -FilePath $outputFile -Width 500 -append
	}
	else
	{
		if ($RunPScmd -eq "Get-NfsSharePermission")
		{
			foreach ($NfsShare in $(Get-NfsShare).name)
			{
				Get-NfsSharePermission -Name $NfsShare | Out-File -FilePath $OutputFile -append
			}
		} 
		else 
		{
			Invoke-Expression $RunPScmd	| Out-File -FilePath $OutputFile -append
		}
	}
	"`n"	| Out-File -FilePath $OutputFile -append
	"`n"	| Out-File -FilePath $OutputFile -append
	"`n"	| Out-File -FilePath $OutputFile -append
}

# Data Collection consists of:
#  Powershell
#  NfsAdmin (none)
#  Netsh
#  Registry
#  EventLogs


# detect OS version and SKU
$wmiOSVersion = Get-CimInstance -Namespace "root\cimv2" -Class Win32_OperatingSystem
[int]$bn = [int]$wmiOSVersion.BuildNumber

# UPDATE Write-DiagProgress status here


$sectionDescription = "NFS Server"
$outputFile= $Computername + "_NfsServer_info_pscmdlets.TXT"
"===================================================="	| Out-File -FilePath $OutputFile -append
"NFS Server Powershell Cmdlets"							| Out-File -FilePath $OutputFile -append
"===================================================="	| Out-File -FilePath $OutputFile -append
"Overview" 												| Out-File -FilePath $OutputFile -append
"----------------------------------------------------"	| Out-File -FilePath $OutputFile -append
"   1. Get-NfsServerConfiguration"						| Out-File -FilePath $OutputFile -append
"   2. Get-NfsMappingStore"								| Out-File -FilePath $OutputFile -append
"   3. Get-NfsShare"									| Out-File -FilePath $OutputFile -append
"   4. Get-NfsSharePermission"							| Out-File -FilePath $OutputFile -append
"   5. Get-NfsMappedIdentity (Users)"					| Out-File -FilePath $OutputFile -append
"   6. Get-NfsMappedIdentity (Groups)"					| Out-File -FilePath $OutputFile -append
"   7. Get-NfsMountedClient"							| Out-File -FilePath $OutputFile -append
"   8. Get-NfsNetgroupStore"							| Out-File -FilePath $OutputFile -append
"   9. Get-NfsOpenFile"									| Out-File -FilePath $OutputFile -append
"  10. Get-NfsSession"									| Out-File -FilePath $OutputFile -append
"  11. Get-NfsStatistics"								| Out-File -FilePath $OutputFile -append
"  12. Get-NfsClientgroup"								| Out-File -FilePath $OutputFile -append
"===================================================="	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
$SvcKey = "HKLM:\System\CurrentControlSet\services\NfsServer"
if (Test-Path $SvcKey) 
{
	runPS "Get-NfsServerConfiguration"							# fl
	runPS "Get-NfsMappingStore" 								# fl
	runPS "Get-NfsShare | fl *" 								# unknown
	runPS "Get-NfsSharePermission"								# ft
	runPS "Get-NfsMappedIdentity -AccountType User | ft *" 		# ft
	runPS "Get-NfsMappedIdentity -AccountType Group | ft *" 	# ft
	runPS "Get-NfsMountedClient" 								# unknown
	runPS "Get-NfsNetgroupStore" 								# fl
	runPS "Get-NfsOpenFile"										# unknown
	runPS "Get-NfsSession"										# unknown
	runPS "Get-NfsStatistics" 									# ft
	runPS "Get-NfsClientgroup"									# unknown
	# Get-NfsNetgroup 			# server, takes argument [exception]
}
else
{
	"The `"Server for NFS`" service does not exist."	| Out-File -FilePath $OutputFile -append
}

CollectFiles -filesToCollect $OutputFile -fileDescription "NFS Server Powershell cmdlets" -SectionDescription $sectionDescription



$sectionDescription = "NFS Server"
$outputFile= $Computername + "_NfsServer_NfsAdmin.TXT"
"===================================================="	| Out-File -FilePath $OutputFile -append
"NfsAdmin Server"										| Out-File -FilePath $OutputFile -append
"===================================================="	| Out-File -FilePath $OutputFile -append
"Overview" 												| Out-File -FilePath $OutputFile -append
"----------------------------------------------------"	| Out-File -FilePath $OutputFile -append
"   1. NfsAdmin Server"									| Out-File -FilePath $OutputFile -append
"   2. NfsAdmin Mapping"									| Out-File -FilePath $OutputFile -append
"===================================================="	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
$SvcKey = "HKLM:\System\CurrentControlSet\services\NfsServer"
if (Test-Path $SvcKey) 
{
	RunNFSAdmin "server"
	RunNFSAdmin "mapping"
}
else
{
	"The `"Server for NFS`" service does not exist."	| Out-File -FilePath $OutputFile -append
}

"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
CollectFiles -filesToCollect $OutputFile -fileDescription "NfsAdmin Output" -SectionDescription $sectionDescription




# ===================================================
# Netsh
# ===================================================
# no commands available






# ===================================================
# Registry
# ===================================================

$sectionDescription = "NFS Server"
#----------NfsServer Registry
$OutputFile= $Computername + "_NfsServer_reg_output.TXT"

$CurrentVersionKeys =   "HKLM\system\CurrentControlSet\services\NfsServer",
						"HKLM\system\CurrentControlSet\services\NfsService",
						"HKLM\system\CurrentControlSet\services\NisSvc",
						"HKLM\SOFTWARE\Microsoft\ServerForNfs"
RegQuery -RegistryKeys $CurrentVersionKeys -Recursive $true -OutputFile $OutputFile -fileDescription "NFS Server registry output" -SectionDescription $sectionDescription
CollectFiles -filesToCollect $OutputFile -fileDescription "NFS Server" -SectionDescription $sectionDescription






# ===================================================
# Eventlogs
# ===================================================

#W8/WS2012 and later
if ($bn -gt 9000)
{
	#----------NfsServer
	# ServicesForNFS-ONCRPC
	# Operational		#disabled by default
	# 
	# ServicesForNFS-Portmapper
	# Admin				#disabled by default
	#
	# ServicesForNFS-Server
	# Admin				#enabled by default
	# IdentityMapping	#enabled by default
	# Notifications		#disabled by default
	# Operational		#enabled by default
	#----------
	$sectionDescription = "NfsServer EventLogs"
	$EventLogNames = 	"Microsoft-Windows-ServicesForNFS-ONCRPC/Operational",
						"Microsoft-Windows-ServicesForNFS-Portmapper/Admin",
						"Microsoft-Windows-ServicesForNFS-ServicesForNFS-Server/Admin",
						"Microsoft-Windows-ServicesForNFS-ServicesForNFS-Server/IdentityMapping",
						"Microsoft-Windows-ServicesForNFS-ServicesForNFS-Server/Notifications",
						"Microsoft-Windows-ServicesForNFS-ServicesForNFS-Server/Operational"
	$Prefix = ""
	$Suffix = "_evt_"
	.\TS_GetEvents.ps1 -EventLogNames $EventLogNames -SectionDescription $sectionDescription -Prefix $Prefix -Suffix $Suffix
}




# SIG # Begin signature block
# MIIoLgYJKoZIhvcNAQcCoIIoHzCCKBsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDzyqkfeixApuj7
# dOFd4ACyiX+7EB0yEYmhxHNhQBSyUaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
# DkyjTQVBAAAAAAOvMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwOTAwWhcNMjQxMTE0MTkwOTAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOS8s1ra6f0YGtg0OhEaQa/t3Q+q1MEHhWJhqQVuO5amYXQpy8MDPNoJYk+FWA
# hePP5LxwcSge5aen+f5Q6WNPd6EDxGzotvVpNi5ve0H97S3F7C/axDfKxyNh21MG
# 0W8Sb0vxi/vorcLHOL9i+t2D6yvvDzLlEefUCbQV/zGCBjXGlYJcUj6RAzXyeNAN
# xSpKXAGd7Fh+ocGHPPphcD9LQTOJgG7Y7aYztHqBLJiQQ4eAgZNU4ac6+8LnEGAL
# go1ydC5BJEuJQjYKbNTy959HrKSu7LO3Ws0w8jw6pYdC1IMpdTkk2puTgY2PDNzB
# tLM4evG7FYer3WX+8t1UMYNTAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQURxxxNPIEPGSO8kqz+bgCAQWGXsEw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMTgyNjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAISxFt/zR2frTFPB45Yd
# mhZpB2nNJoOoi+qlgcTlnO4QwlYN1w/vYwbDy/oFJolD5r6FMJd0RGcgEM8q9TgQ
# 2OC7gQEmhweVJ7yuKJlQBH7P7Pg5RiqgV3cSonJ+OM4kFHbP3gPLiyzssSQdRuPY
# 1mIWoGg9i7Y4ZC8ST7WhpSyc0pns2XsUe1XsIjaUcGu7zd7gg97eCUiLRdVklPmp
# XobH9CEAWakRUGNICYN2AgjhRTC4j3KJfqMkU04R6Toyh4/Toswm1uoDcGr5laYn
# TfcX3u5WnJqJLhuPe8Uj9kGAOcyo0O1mNwDa+LhFEzB6CB32+wfJMumfr6degvLT
# e8x55urQLeTjimBQgS49BSUkhFN7ois3cZyNpnrMca5AZaC7pLI72vuqSsSlLalG
# OcZmPHZGYJqZ0BacN274OZ80Q8B11iNokns9Od348bMb5Z4fihxaBWebl8kWEi2O
# PvQImOAeq3nt7UWJBzJYLAGEpfasaA3ZQgIcEXdD+uwo6ymMzDY6UamFOfYqYWXk
# ntxDGu7ngD2ugKUuccYKJJRiiz+LAUcj90BVcSHRLQop9N8zoALr/1sJuwPrVAtx
# HNEgSW+AKBqIxYWM4Ev32l6agSUAezLMbq5f3d8x9qzT031jMDT+sUAoCw0M5wVt
# CUQcqINPuYjbS1WgJyZIiEkBMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGg4wghoKAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINdL0/vRBoNoZlBRuCl/YyOK
# 3ruL+YQ1zwbyTrItWcVUMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCgjJ9+fu3X/vuEO609azGSkysby+btzE2dhkXiSmxawJZZCNFPQd3E
# oHrz6ZTk9/15XRDND1a4+LiEyhsGW9f1lE5XYkV1Eikp6vOQJ/kP2HR4b87sGxMw
# a5a4aBz0g3X7wyFWEEj3pfOvGCOD6uYzdsa5dXCWW/W6WFVRSI2N5gFbsikSA0iu
# c9tZ0pCZ6MtI7ug9uMef9UGrfrZ4OMpljJAWuW3yyctLsIQoO3Y/huNtqyqyHJxG
# cWLJhfJgCBT/RTLS9HL25aQt4rJVD9147ncZ14HKlQsaOY2NiOQxXfiQ6Hrpk0Ji
# YZO4PovIsgqAsFo1jYvgIFQJBR59e7GzoYIXljCCF5IGCisGAQQBgjcDAwExgheC
# MIIXfgYJKoZIhvcNAQcCoIIXbzCCF2sCAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIEX5CiWElKxD11Kla6QP5ZE+FR3LcLBvnHSZ80uPoSvQAgZl8uGe
# GG8YEjIwMjQwMzIyMTMxNTA3LjA5WjAEgAIB9KCB0aSBzjCByzELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE5MzUt
# MDNFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIR7TCCByAwggUIoAMCAQICEzMAAAHpD3Ewfl3xEjYAAQAAAekwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMxMjA2MTg0
# NTI2WhcNMjUwMzA1MTg0NTI2WjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE5MzUtMDNFMC1EOTQ3MSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEArJqMMUEVYKeE0nN502usqwDyZ1egO2mWJ08P8sfd
# LtQ0h/PZ730Dc2/uX5gSvKaR++k5ic4x1HCJnfOOQP6b2WOTvDwgbuxqvseV3uqZ
# ULeMcFVFHECE8ZJTmdUZvXyeZ4fIJ8TsWnsxTDONbAyOyzKSsCCkDMFw3LWCrwsk
# MupDtrFSwetpBfPdmcHGKYiFcdy09Sz3TLdSHkt+SmOTMcpUXU0uxNSaHJd9DYHA
# YiX6pzHHtOXhIqSLEzuAyJ//07T9Ucee1V37wjvDUgofXcbMr54NJVFWPrq6vxvE
# ERaDpf+6DiNEX/EIPt4cmGsh7CPcLbwxxp099Da+Ncc06cNiOmVmiIT8DLuQ73ZB
# Bs1e72E97W/bU74mN6bLpdU+Q/d/PwHzS6mp1QibT+Ms9FSQUhlfoeumXGlCTsaW
# 0iIyJmjixdfDTo5n9Z8A2rbAaLl1lxSuxOUtFS0cqE6gwsRxuJlt5qTUKKTP1NVi
# Z47LFkJbivHm/jAypZPRP4TgWCrNin3kOBxu3TnCvsDDmphn8L5CHu3ZMpc5vAXg
# FEAvC8awEMpIUh8vhWkPdwwJX0GKMGA7cxl6hOsDgE3ihSN9LvWJcQ08wLiwytO9
# 3J3TFeKmg93rlwOsVDQqM4O64oYh1GjONwJm/RBrkZdNtvsj8HJZspLLJN9GuEad
# 7/UCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSRfjOJxQh2I7iI9Frr/o3I7QfsTjAf
# BgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQ
# hk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQl
# MjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
# MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAM
# BgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQE
# AwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAVrEqfq5rMRS3utQBPdCnp9lz4EByQ4ku
# Emy4b831Ywzw5jnURO+bkKIWIRTHRsBym1ZiytJR1dQKc/x3ImaKMnqAL5B0Gh5i
# 4cARpKMgAFcXGmlJxzSFEvS73i9ND8JnEgy4DdFfxcpNtEKRwxLpMCkfJH2gRF/N
# wMr0M5X/26AzaFihIKXQLC/Esws1xS5w6M8wiRqtEc8EIHhAa/BOCtsENllyP2Sc
# WUv/ndxXcBuBKwRc81Ikm1dpt8bDD93KgkRQ7SdQt/yZ41zAoZ5vWyww9cGie0z6
# ecGHb9DpffmjdLdQZjswo/A5qirlMM4AivU47cOSlI2jukI3oB853V/7Wa2O/dnX
# 0QF6+XRqypKbLCB6uq61juD5S9zkvuHIi/5fKZvqDSV1hl2CS+R+izZyslyVRMP9
# RWzuPhs/lOHxRcbNkvFML6wW2HHFUPTvhZY+8UwHiEybB6bQL0RKgnPv2Mc4SCpA
# PPEPEISSlA7Ws2rSR+2TnYtCwisIKkDuB/NSmRg0i5LRbzUYYfGQQHp59aVvuVAR
# mM9hqYHMVVyk9QrlGHZR0fQ+ja1YRqnYRk4OzoP3f/KDJTxt2I7qhcYnYiLKAMNv
# jISNc16yIuereiZCe+SevRfpZIfZsiSaTZMeNbEgdVytoyVoKu1ZQbj9Qbl42d6o
# Mpva9cL9DLUwggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqG
# SIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkg
# MjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
# AgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4X
# YDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTz
# xXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7
# uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlw
# aQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedG
# bsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXN
# xF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03
# dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9
# ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5
# UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReT
# wDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZ
# MBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8
# RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAE
# VTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAww
# CgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQD
# AgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb
# 186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29t
# L3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoG
# CCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZI
# hvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9
# MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2Lpyp
# glYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OO
# PcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8
# DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA
# 0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1Rt
# nWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjc
# ZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq7
# 7EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJ
# C4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328
# y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYID
# UDCCAjgCAQEwgfmhgdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMx
# JzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBOTM1LTAzRTAtRDk0NzElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA
# q2mH9cQ5NqzJ1P1SaNhhitZ8aPGggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAOmn60YwIhgPMjAyNDAzMjIxMTM0
# MzBaGA8yMDI0MDMyMzExMzQzMFowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA6afr
# RgIBADAKAgEAAgIGyAIB/zAHAgEAAgITxzAKAgUA6ak8xgIBADA2BgorBgEEAYRZ
# CgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0G
# CSqGSIb3DQEBCwUAA4IBAQAzx6EPVaISKo/CRWP9GYw5QxydWzxuFX8iYFN1L6x5
# 80Ehbeaq/X2+QP6CgCrNI1hSgBxYv9P32jiqARRdjqkavBvZrAEqAZxYL33XXO3T
# 5gMC04YW/5Dv53IhLD903+BDBe61MvQqmPii7jvNJi+m4D3KkGRqo4tVO82JR8j8
# D/owK2EVU8/vl7IKGIeJsf6vx9TDjWwY4CpsW9OS55RGLWhcsPaGdlJgl2QvdSWv
# VnmxVdC5luFxRFqEonrGpU4mnOpxxqCqEdcKRGZGX081OTkbCtxahIT+2iIi+eZ7
# X/QJP2GSaL9/grMmlGIdGOmOARFxju2jyUL0oH3gyKMJMYIEDTCCBAkCAQEwgZMw
# fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHpD3Ewfl3xEjYAAQAA
# AekwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAvBgkqhkiG9w0BCQQxIgQgG/GQUKF90t56A/N3egg5aSNlE3ofTyDubACcyn8N
# PwwwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCCkkJJ4l2k3Jo9UykFhfsdl
# OK4laKxg/E8JoFWzfarEJTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAAB6Q9xMH5d8RI2AAEAAAHpMCIEIB39RkkjOzrs1twzm4/BeDqa
# W5eICg8CNB+ds7asTQtEMA0GCSqGSIb3DQEBCwUABIICAKBiqGDseAJozgtGx3eR
# kR5d4l3a8xesawNxHNPujkPUxLmIBJ8RCfuUVYeqj+QVcKrhQR4Q++tnz3bY0hLU
# IAdeKxQg/cDnIvBkmCDhuv5Rx+Ez8KCLfwT4+kUT0ZPWoE+TFQCbK8H6N1zSZDGh
# ndBJWe/51mYBiX1B11WLni9/Nmr/wYPY63MM81CPzR3gdYtOZyDXx670IXIon6ek
# H6opWFner8jLe8ljPvAW8Gqgq4ysevBWGC4c19TOAEIatrX8O06ZoP3dLWF7Rj3y
# dJtJBT3YH8WxMeGWNYeZEv5y4tti2E0XfiCJ+jzupNGkQLU/2NB5IPIBkcN/yzGu
# rj14Ht5OA4Oxht8udCuhYujx+88lyo0ibWqDd/GXQuzvnP4Sz0N08YmLrR8qATfA
# tnNWi0FIF7BmkuSh3j8Mo8KI1a/yiAkt2YE9UokmhXvhlS2l1GglRdvdPu80vgSW
# 1OaqfByZa5vnMPc0v6WTGyVejPMtA0F3zcVrfWTDUpCx1x8iVmXgVwCb74708AN0
# Uhmb5dnP/66Q3qzs+AxxN9SAgjmgmVFnPWiAJyei3aelvFYrmk+VdckBOvktIGT5
# lJ4b1P2M3TH3bxGD9fbXUCidEpnzzbpqbetuCbMeEV5edRtvPegHDuc9X7Oyx3/F
# QzJmzmyA3hgEQXxgIXfvCypD
# SIG # End signature block
