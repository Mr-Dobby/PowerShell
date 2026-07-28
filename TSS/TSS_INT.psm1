<#
.SYNOPSIS
	Biztalk Integration module for collecting traces

.DESCRIPTION
	Define ETW traces for Windows Biztalk Integration components 
	Add any custom tracing functinaliy for tracing Biztalk components
	For Developers:
	1. Component test: .\TSS.ps1 -Start -INT_TEST1
	2. Scenario test: .\TSS.ps1 -start -Scenario INT_MyScenarioTest

.NOTES
	Dev. Lead: niklase
	Authors	 : Niklas Engfelt <niklase@microsoft.com>
	Requires   : PowerShell V4 (Supported from Windows 8.1/Windows Server 2012 R2)
	Version    : see $global:TssVerDateINT

.LINK
	TSS https://internal.evergreen.microsoft.com/en-us/help/4619187
	INT https://internal.evergreen.microsoft.com/en-us/help/1234567 -todo
#>

<# latest changes (reverse chronological order)
::	2023.02.22.0 [we] add INT_MSMQ component and scenario
#>

#region --- Define local INT Variables
$global:TssVerDateINT= "2023.02.23.0"

$BinArch = "\Bin" + $global:ProcArch
$global:TMQexePath = $global:ScriptFolder + $BinArch + "\TMQ.exe"
#endregion --- Define local INT Variables

#------------------------------------------------------------
#region --- ETW component trace Providers ---
#------------------------------------------------------------

#---  Dummy Providers ---# #for components without a tracing GUID


#---  MSMQ Providers ---#
$INT_MSMQProviders = @(
	'{CE18AF71-5EFD-4F5A-9BD5-635E34632F69}' # Microsoft-Windows-MSMQ
	'{2787CC62-2654-4227-9B35-B53F838507AE}' # Microsoft-Windows-MSMQTriggers
	'{45033C79-EA31-4776-9BCD-94DB89AF3149}' # MSMQ: General
	'{322E0B22-0527-456E-A5EF-E5B591046A63}' # MSMQ: AC
	'{6E2C0612-BCF3-4028-8FF2-C60C288F1AF3}' # MSMQ: Networking
	'{DA1AF236-FAD6-4DA6-BD94-46395D8A3CF5}' # MSMQ: SRMP
	'{F8354C74-DE9F-48A5-8139-4ED1E9F20A1B}' # MSMQ: RPC
	'{5DC62C8C-BDF2-45A1-A06F-0C38CD5AF627}' # MSMQ: DS
	'{90E950BB-6ACE-4676-98E0-F6CDC1403670}' # MSMQ: Security
	'{8753D150-950B-4774-AC14-9C6CBFF56A50}' # MSMQ: Routing
	'{8FDA2BBD-347E-493C-B7D1-6B6FED88CE04}' # MSMQ: XACT_General
	'{485C37B0-9A15-4A2E-82E0-8E8C3A7B8234}' # MSMQ: XACT_Send
	'{7C916009-CF80-408B-9D91-9C2960118BE9}' # MSMQ: XACT_Receive
	'{1AC9B316-5B4E-4BBD-A2C9-1E70967A6FE1}' # MSMQ: XACT_Log
	'{A13EC7BB-D592-4B93-80DA-C783F9708BD4}' # MSMQ: Log
	'{71625F6D-559A-49C6-BA21-0AEB260DB97B}' # MSMQ: Profiling
	'{F707F440-AD58-47F8-93D3-BEA2F9E82FD2}' # MSMQ: ERRORLOGGING
)
#endregion --- ETW component trace Providers ---


#------------------------------------------------------------
#region --- Scenario definitions ---
#------------------------------------------------------------
$INT_General_ETWTracingSwitchesStatus = [Ordered]@{
	#'INT_Dummy' = $true
	#'CommonTask NET' = $True  ## <------ the commontask can take one of "Dev", "NET", "ADS", "UEX", "DnD" and "SHA", or "Full" or "Mini"
	'NetshScenario InternetClient_dbg' = $true
	'Procmon' = $true
	'WPR General' = $true
	'PerfMon ALL' = $true
	'PSR' = $true
	'Video' = $true
	'SDP Net' = $True
	'xray' = $True
	'CollectComponentLog' = $True
}

$INT_MSMQ_ETWTracingSwitchesStatus = [Ordered]@{
	'INT_MSMQ' = $true
	'CommonTask INT' = $True
#	'NetshScenario InternetClient_dbg' = $true
#	'Procmon' = $true
#	'WPR General' = $true
#	'PerfMon ALL' = $true
	'PSR' = $true
	'Video' = $true
#	'SDP Net' = $True
#	'noBasicLog' = $true
	'xray' = $True
	'CollectComponentLog' = $True
}
#endregion --- Scenario definitions ---

#region ### Pre-Start / Post-Stop / Collect functions for trace components and scenarios 
#------------------------------------------------------------
#--- Platform Trace ---#
function INT_MSMQPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	#noop
	EndFunc $MyInvocation.MyCommand.Name
}
function INT_MSMQPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	#noop
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectINT_MSMQLog{
	EnterFunc $MyInvocation.MyCommand.Name
	FwAddRegItem @("MSMQ") _Stop_
	LogInfo "[$($MyInvocation.MyCommand.Name)] collecting MSMQInfo at $TssPhase"
	$outFile = $PrefixTime + "MSMQInfo" + $TssPhase + ".txt"
	$Commands = @(
		"Get-WindowsFeature | ? Name -match `"msmq`" | ft -AutoSize | Out-File -Append $outFile"
		"Get-WindowsOptionalFeature -Online | ? FeatureName -match `"msmq`" | select FeatureName,State | ft -AutoSize | Out-File -Append $outFile"
		"Get-WinSystemLocale | Out-File -Append $outFile"
		"Get-WinUserLanguageList | Out-File -Append $outFile"
		"(dir C:\windows\system32\mqqm.dll).VersionInfo | fl | Out-File -Append $outFile"
		"(dir C:\windows\system32\drivers\mqac.sys).VersionInfo | fl | Out-File -Append $outFile"
		"(Get-Acl 'HKLM:\Software\Microsoft\MSMQ').Access | fl | Out-File -Append $outFile"
		"(Get-Acl 'C:\Windows\System32\MSMQ').Access | fl | Out-File -Append $outFile"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False

	If($IsServerSKU){
		if (Get-WindowsFeature | Where-Object {($_.Name -eq "RSAT-AD-PowerShell") -and ($_.installed -eq $true)}){
			LogInfo "RSAT AD tools are installed" "Green"
			$fRSATinst=$True
		}else{ 
			LogWarn "[$($MyInvocation.MyCommand.Name)] RSAT AD tools are missing. 'RSAT-AD-PowerShell' module is not installed."
			LogInfo "Please run: Install-WindowsFeature RSAT-AD-PowerShell" "Cyan"
		}
	} else {
		If($OSBuild -ge 9200) {
			if (Get-WindowsOptionalFeature -Online | Where-Object {($_.Name -eq "RSAT-AD-PowerShell") -and ($_.installed -eq $true)}){
				LogInfo "RSAT AD tools are installed" "Green"
				$fRSATinst=$True
			}else{ 
				LogWarn "[$($MyInvocation.MyCommand.Name)] RSAT AD tools are missing."
				LogInfo "Please run:`
		Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
		Import-Module -Name ActiveDirectory" "Cyan"
			}
		}
	}
	If($fRSATinst -eq "True"){
		# Get local computer object
		$cnObj = Get-ADComputer -Identity $env:COMPUTERNAME
		$ou = $cnObj.DistinguishedName		  # $ou = (Get-ADComputer $env:COMPUTERNAME).DistinguishedName	# $ou = "CN=MYCOMPUTERxxxx,CN=Computers,DC=mydomain,DC=local"
		$outFile = $PrefixTime + "MSMQ.Computer.objects" + $TssPhase + ".txt"
		$Commands = @(
			"AD-object properties: $ou | Out-File -Append $outFile"
			"Get-ADObject -Identity $ou -Properties * | fl | Out-File -Append $outFile"
			"Get-ADObject -Identity `"CN=msmq,$ou`" -Properties * | fl | Out-File -Append $outFile"
			)
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	}
	FwGet-SummaryVbsLog
	getTMQinfo
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion ### Pre-Start / Post-Stop / Collect functions for trace components and scenarios 

#region --- HelperFunctions ---
function INT_start_common_tasks {
	#collect info for all tss runs at _Start_
	EnterFunc $MyInvocation.MyCommand.Name
	LogDebug "___switch Mini: $global:Mini" "cyan"
	if ($global:Mini -ne $true) {
		#LogInfoFile "PATH: $Env:Path"
		FwGetSysInfo _Start_
		FwGetSVC _Start_
		FwGetSVCactive _Start_ 
		FwGetTaskList _Start_
		FwGetSrvWkstaInfo _Start_
		FwGetNltestDomInfo _Start_
		FwGetKlist _Start_ 
		FwGetBuildInfo
		if ($global:noClearCache -ne $true) { FwClearCaches _Start_ } else { LogInfo "[$($MyInvocation.MyCommand.Name) skip FwClearCaches" }
		FwGetRegList _Start_
		FwGetPoolmon _Start_
		FwGetSrvRole
	}
	FwGetLogmanInfo _Start_
	LogInfoFile "___ INT_start_common_tasks DONE"
	EndFunc $MyInvocation.MyCommand.Name
}
function INT_stop_common_tasks {
	#collect info for all tss runs at _Stop_
	EnterFunc $MyInvocation.MyCommand.Name
	if ($global:Mini -ne $true) {
		FwGetDFScache _Stop_
		FwGetSVC _Stop_
		FwGetSVCactive _Stop_ 
		FwGetTaskList _Stop_
		FwGetKlist _Stop_
		FwGetWhoAmI _Stop_
		FwGetDSregCmd
		FwGetHotfix
		FwGetPoolmon _Stop_
		FwGetLogmanInfo _Stop_
		FwGetNltestDomInfo _Stop_
		FwListProcsAndSvcs _Stop_
		FwGetRegList _Stop_
		writeTesting "___ FwGetEvtLogList"
		("System", "Application") | ForEach-Object { FwAddEvtLog $_ _Stop_}
		FwGetEvtLogList _Stop_
	}
	FwGetSrvWkstaInfo _Stop_
	FwGetRegHives _Stop_
	FwCopyMemoryDump -DaysBack 2
	LogInfoFile "___ INT_stop_common_tasks DONE"
	EndFunc $MyInvocation.MyCommand.Name
}

function getTMQinfo{
	param(
		[Parameter(Mandatory=$False)]
		[String]$TssPhase = $global:TssPhase				# _Start_ or _Stop_
	)
	EnterFunc ($MyInvocation.MyCommand.Name + " at $TssPhase")
	if (!$global:IsLiteMode){
		if (Test-Path $global:TMQexePath){
			LogInfo "[$($MyInvocation.MyCommand.Name)] collecting TMQ.exe info at $TssPhase"
			$ClusterServiceKey="HKLM:\SYSTEM\CurrentControlSet\Services\ClusDisk"
			if (Test-Path $ClusterServiceKey){
				#In case of clustered MSMQ, we need to know the MSMQ cluster name (perhaps as optional input -clustername {MSMQClusteredServiceName} ), or if more advanced get all clustered resources and check if of type MSMQ and then issue following commands per MSMQ resource found. 
				$MSMQClusteredServiceName = Read-Host -Prompt "Please enter the MSMQClusteredServiceName, or hit ENTER to skip this step"
				LogInfoFile "[MSMQClusteredServiceName: User provided answer:] $MSMQClusteredServiceName"
				If(!([String]::IsNullOrEmpty($MSMQClusteredServiceName))) {
					$Commands = @(
						"$global:TMQexePath  state -s $MSMQClusteredServiceName -v -f -r | Out-File $PrefixTime`TMQ-state-cluster.txt"
						"$global:TMQexePath  site -s $MSMQClusteredServiceName -v -d | Out-File -Append $PrefixTime`TMQ-site-cluster.txt"
						"$global:TMQexePath  store -d -v -s $MSMQClusteredServiceName | Out-File -Append $PrefixTime`TMQ-store-cluster.txt"
					)
				}
			}else{
				$outFile = $PrefixTime + "tmqstate" + $TssPhase + ".txt"
				$Commands = @(
					"$global:TMQexePath  state -d -v | Out-File -Append $outFile"
					"$global:TMQexePath  site -d -v | Out-File -Append $outFile"
					"$global:TMQexePath  store -d -v | Out-File -Append $outFile"
				)
			}
			if($Commands){RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False}
		}else{LogWarn "[$($MyInvocation.MyCommand.Name)] 'TMQ.exe' not found in PATH"}
	}else{ LogInfo "Skipping TMQ.exe info in Lite mode"}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- HelperFunctions ---

#region Registry Key modules for FwAddRegItem
	$global:KeysMSMQ = @("HKLM:Software\Microsoft\MSMQ")
#endregion Registry Key modules

#region groups of Eventlogs for FwAddEvtLog
	<# Example:
	$global:EvtLogsEFS		= @("Microsoft-Windows-NTFS/Operational", "Microsoft-Windows-NTFS/WHC")
	#>
#endregion groups of Eventlogs

Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *
# SIG # Begin signature block
# MIIoLQYJKoZIhvcNAQcCoIIoHjCCKBoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAV3e2kuEOckKhe
# NsVSUNHULWAqUHoEUzCnrqBFxYNXW6CCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKQSAiLTXGYFzmudpRJqAu6w
# IcZon+plG7ECnE7gmkUcMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAV7iExWyoH83KuU4xot3C4CiKyCnzbcZ80D6u5kL3omN+wQz/0fDeO09b
# fAvoMkq1E7kWetgJtBy2FVhjG6neqReUR9cYfFtFY8o9c57HC9KPMql6FFE5SyuV
# FsB2FRwomolBk+Txtj+0hiW9iapa9jGLOz8a1cu3xVMLJYcqX7MXcKBsCpxAXbT9
# nex7eRJ9FQemK0Nv+o6HMwZeYOVKk7vqf3m5VkBi9f5KqQetDcFaNscbsqROWdcx
# xX3DLz2kWcXO44bvt8W21uJ8lcvDsdLVAz20YrsV6ecHuOBM0hmKiIUceFlFn0fn
# oFUFJphaXP2zyuSMKS9aeCV7qTFzKqGCF5cwgheTBgorBgEEAYI3AwMBMYIXgzCC
# F38GCSqGSIb3DQEHAqCCF3AwghdsAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAul8KzOPpWxwpVePw0yCwCA8BqX3XN0RjoAq1aWKq9KwIGZkYsf+mz
# GBMyMDI0MDYxMjE0NTg1NC4xOTVaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046ODkwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHtMIIHIDCCBQigAwIBAgITMwAAAe3hX8vV96VdcwABAAAB7TANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# NDFaFw0yNTAzMDUxODQ1NDFaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046ODkwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCoMMJskrrqapycLxPC1H7zD7g88NpbEaQ6SjcTIRbz
# CVyYQNsz8TaL1pqFTEAPL1X7ojL4/EaEW+UjNqZs/ayMyW4YIpFPZP2x4FBMVCdd
# seF2i+aMMjDHi0LcTQZxM2s3mFMrCZAWSfLYXYDIimFBz8j0oLWGy3VgLmBTKM4x
# Lqv7DZUz8B2SoAmbEtp62ngSl0hOoN73SFwE+Y24SvGQMWhykpG+vXDwcpWvwDe+
# TgnrLR7ATRFXN5JS26dm2yy6SYFMRYnME3dMHCQ/UQIQQNC8nLmIvdKkAoWEMXtJ
# sGEo3QrM2S2SBv4PpHRzRukzTtP+UAceGxM9JyrwUQP5OCEmW6YchEyRDSwP4hU9
# f7B0Ayh14Pw9vJo7jewNjeMPIkmneyLSi0ruv2ox/xRGtcJ9yBNC5BaRktjz7stP
# aojR+PDA2fuBtCo8xKlkt53mUb7AY+CZHHqhLm76pdMF6BHv2TvwlVBeQRN22Xja
# VVRwCgjgJnNewt7PejcrpUn0qHLgLq+1BN1DzYukWkTr7wT0zl0iXr+NtqUkWSOn
# WRfe8N21tB6uv3VkW8nFdChtbbZZz24peLtJEZuNrN8Xf9PTPMzZXDJBI1EciR/9
# 1QcGoZFmVbFVb2rUIAs01+ZkewvbhmGVDefX9oZG4/K4gGUsTvTW+r1JZMxUT2Mw
# qQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFM4b8Oz33hAqBEfKlAZf0NKh4CIZMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQCd1gK2Rd+eGL0eHi+iE6/qDY8sbbsO4ema
# ncp6KPN+xq5ZAatiBR4jmRRhm+9Vik0Fo0DLWi/N28bFI7dXYw09p3vCipbjy4Eo
# ifm0Nud7/4U30i9+7RvW7XOQ3rx37+U7vq9lk6yYpGCNp0jlJ188/CuRPgqJnfq5
# EdeafH2AoG46hKWTeB7DuXasGt6spJOenGedSre34MWZqeTIQ0raOItZnFuGDy4+
# xoD1qRz2QW+u2gCHaG8AQjhYUM4uTi9t6kttj6c7Xamr2zrWuceDhz7sKLttLTJ7
# ws5YrA2I8cTlbMAf2KW0GVjKbYGd+LZGduEK7/7fs4GUkMqc51FsNdG1n+zgc7zH
# u2oGGeCBg4s8ZR0ZFyx7jsgm9sSFCKQ5CsbAvlr/60Ndk5TeMR8Js2kNUicu2CqZ
# 03833TsvTgk7iD1KLgfS16HEvjN6m4VKJKgjJ7OJJzabtS4JQgUnJrIZfyosk4D1
# 8rZni9pUwN03WgTmd10WTwiZOu4g8Un6iKcPMY/iFqTu4ntkzFUxBBpbFG6k1CIN
# ZmoirEWmCtG3lyZ2IddmjtIefTkIvGWb4Jxzz7l2m/E2kGOixDJHsahZVmwsoNvh
# y5ku/inU++dXHzw+hlvqTSFT89rIFVhcmsWPDJPNRSSpMhoJ33V2Za/lkKcbkUM0
# SbQgS9qsdzCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
# hvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# MjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAy
# MDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25Phdg
# M/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPF
# dvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6
# GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBp
# Dco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50Zu
# yjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3E
# XzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0
# lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1q
# GFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ
# +QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PA
# PBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkw
# EgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxG
# NSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARV
# MFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAK
# BggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
# zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
# cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYI
# KwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG
# 9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0x
# M7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmC
# VgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449
# xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wM
# nosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDS
# PeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2d
# Y3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxn
# GSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+Crvs
# QWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokL
# jzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggNQ
# MIICOAIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjg5MDAtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQDu
# HayKTCaYsYxJh+oWTx6uVPFw+aCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hOYyTAiGA8yMDI0MDYxMjAzNDcy
# MVoYDzIwMjQwNjEzMDM0NzIxWjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDqE5jJ
# AgEAMAoCAQACAg0jAgH/MAcCAQACAhQIMAoCBQDqFOpJAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAAnN29mCTsByvBaE9DHLX1tZzeZuhEvl95ghsWfASCab
# Y11vqbdDwRIZTOXUsY8PE6utYCmQuSWpLulcxY9l59Wvu4Ei9lHmbXxdyHVzKI/y
# twVSZzR9j5Lv597FURwSiG3o1BrJFyxL7FVUJH5kyGW26sWOO2/Kl/wdX13JKcz3
# 7pJfQhCc4Ht5nj90I9L8AuShOw7JvA00v+CWLiVaRgzxZowwV3Vy6zZ/GbbgTg6M
# sONlfYUetXyHiWyX+wKiL3bpuja6NQlSaMd6ZFlqJqQOEqwaavCRLBOlYFqu5V3w
# zs51KGym+bOYFOx6AwKC2HRUafa6+IE7kiqsaajRoAgxggQNMIIECQIBATCBkzB8
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAe3hX8vV96VdcwABAAAB
# 7TANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEE
# MC8GCSqGSIb3DQEJBDEiBCCnjwpBxgyrFAlanxhqSLPqwMQhefX7v5UJtTN9D35M
# rjCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EII0uDWg0CFseKxK3A16l1wrI
# wrsSDrXZ6xSf0F4xbMo5MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTACEzMAAAHt4V/L1felXXMAAQAAAe0wIgQg78GZUuvOaAxFZfQzyWJdNbhw
# SWZv3xxQFU3XxQWbtOkwDQYJKoZIhvcNAQELBQAEggIAjz/uMgzi3gWQjbytH9At
# i5A/1cb5VpmcXBEseOMrZ7r2CGkdHQep/DBvx1rm/yR3lnFcMAhBvf6Odk4PYONZ
# ircT7YeCoIBbHLF3aYe9HqkL25qoi0GuaSAp//dg46KlGZKSakveyzvLDl0BmDuP
# 41h3yiHwgJiufT9ejyTKuH0ASoGftFZFJ1aZo1iNnR6KYYH8XL/gttCX4ND+ilHU
# K4Uy7w1ftMVkDG8aFR0TOlKggsPttfsWoFdtEt1wDSu6SoKh1ozo8EMsZ8jN7k78
# Mw65m98baRI+HdSDLIHANSaMha+eHQyTEpfwPkEEbdfzipAdzq3jwmNwecGjm1Z0
# SgDgRYq4e5kMn5cc4lCet2RL0G8f7+1MXPnPXD6RbdGFzwMYDMwQW0fLxM76+RUZ
# msukpx4fE19xlh5GqNbSvwqF28Ta/YtzrCO8zMyRbs/KgAA9IUz9pyC0p1KTySvw
# KdkSSfH0PvKqUumNEHbLh5F0dAAwHQwAmDL50DzmLnfseoCdg6twd4HTMbPoTPU1
# jQxi033+jfqNy4d92MmDxG4v1UlipwHhM1p1rUwEIZCLuKytXFeY/Y67xsxRCQWo
# 1Yp0RX5VMw6z94pTAwvMuNr9knFdLKA5iTxXKyZpaj2L1uK/5APib9KF4tI5EijX
# ypDkkEROEHSrtMx1YuEHPyo=
# SIG # End signature block
