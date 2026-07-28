<#
.SYNOPSIS
   DEV Components and Scenarios module for learning and demoing TSS Framework usage.
   This is NOT related to any specific POD and not designed for learning and troubleshooting.

.DESCRIPTION
   DEV Components and Scenarios module for learning and demoing TSS Framework usage.
   This is NOT related to any specific POD and not designed for learning and troubleshooting.

.NOTES
	Dev. Lead: milanmil
   Authors     : milanmil, waltere
   Requires   : PowerShell V4(Supported from Windows 8.1/Windows Server 2012 R2)
   Version    : see $global:TssVerDateDEV

.LINK
	TSS https://internal.evergreen.microsoft.com/en-us/help/4619187
#>

<# latest changes
::  2023.08.07.0 [mm] _ADS: move ADS_EESummit to DEV_EESummit
::  2023.01.23.0 [we] _DEV: added function DevTest
::  2022.12.07.0 [we] _DEV: add -Scenario DEV_General
::  2022.01.05.0 [we] added FW function calls which were previously defined in _NET
::  2021.11.10.0 [we] #_# replaced all 'Get-WmiObject' with 'Get-CimInstance' to be compatible with PowerShell v7
#>

$global:TssVerDateDEV= "2023.08.17.0"

#region --- ETW component trace Providers ---
# Normal trace -> data will be collected in a single file
$DEV_TEST1Providers = @(
	'{CC85922F-DB41-11D2-9244-006008269001}' # LSA
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' # Kerberos
)

# Normal trace with multi etl files
# Syntax is: GUID!filename!flags!level 
# GUID is mandtory
# if filename is not provided TSS will create etl using Providers name, i.e. dev_test2 
# if flags is not provided, TSS defaults to 0xffffffff
# if level is not provided, TSS defaults to 0xff
$DEV_TEST2Providers = @(
	'{98BF1CD3-583E-4926-95EE-A61BF3F46470}!CertCli!0xffffff!0x05'
	'{6A71D062-9AFE-4F35-AD08-52134F85DFB9}!CertificationAuthority!0xff!0x07'
	'{B40AEF77-892A-46F9-9109-438E399BB894}!CertCli!0xfffffe!0x04'
	'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xfffffffe'
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}!CertificationAuthority!0xC43EFF!0x06'
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xffffffff!0x0f'
)

# Single etl + multi flags
$DEV_TEST3Providers = @(
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
	'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffff'
)

$DEV_TEST4Providers = @(
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
	'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffff'
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xffffffff!0x0f'
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}!CertificationAuthority!0xC43EFF!0x06'
)

$DEV_EESummitDemoProviders = @(
	'{CA030134-54CD-4130-9177-DAE76A3C5791}!netlogon' # NETLOGON/ NETLIB
	'{E5BA83F6-07D0-46B1-8BC7-7E669A1D31DC}!netlogon' # Microsoft-Windows-Security-Netlogon
	'{8EE3A3BF-9379-4DAC-B376-038F498B19A4}!w32time' # Microsoft.Windows.W32Time
)


#select basic or full tracing option for the same etl guids using different flags
if ($global:CustomParams){
	Switch ($global:CustomParams[0]){
		"full" {$DEV_TEST5Providers = @(
				'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xffffffff'
				'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffffff'
				)
		}
		"basic" {$DEV_TEST5Providers = @(
				'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
				'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffff'
				)
		}
		Default {$DEV_TEST5Providers = @(
				'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
				'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xfffff!0x12'
				)
		}
	}
}
#endregion --- ETW component trace Providers ---

#region --- Scenario definitions ---
 
$DEV_General_ETWTracingSwitchesStatus = [Ordered]@{
	#'NET_Dummy' = $true
	'CommonTask NET' = $True  ## <------ the commontask can take one of "Dev", "NET", "ADS", "UEX", "DnD" and "SHA", or "Full" or "Mini"
	'NetshScenario InternetClient_dbg' = $true
	'Procmon' = $true
	#'WPR General' = $true
	'PerfMon ALL' = $true
	'PSR' = $true
	'Video' = $true
	'SDP NET' = $True
	'xray' = $True
	'CollectComponentLog' = $True
}
 
$DEV_ScenarioTraceList = [Ordered]@{
	'DEV_Scn1' = 'DEV scenario trace 1'
	'DEV_Scn2' = 'DEV scenario trace 2'
	"DEV_EESummitDemo"    = "DEV_EESummitDemo Trace, ADS_Kerb, PSR, Netsh"
}

# DEV_Scn1
$DEV_Scn1_ETWTracingSwitchesStatus = [Ordered]@{
	'DEV_TEST1' = $true
	#'DEV_TEST2' = $true   # Multi etl file trace
	#'DEV_TEST3' = $true   # Single trace
	#'DEV_TEST4' = $true 
	#'DEV_TEST5' = $true
	#'Netsh' = $true
	#'Netsh capturetype=both captureMultilayer=yes provider=Microsoft-Windows-PrimaryNetworkIcon provider={1701C7DC-045C-45C0-8CD6-4D42E3BBF387}' = $true
	#'NetshMaxSize 4096' = $true
	#'Procmon' = $true
	#'ProcmonFilter ProcmonConfiguration.pmc' = $True
	#'ProcmonPath C:\tools' = $True
	#'WPR memory' = $true
	#'WPR memory -onoffproblemdescription "test description"' = $true
	#'skippdbgen' = $true
	#'PerfMon smb' = $true
	#'PerfIntervalSec 20' = $true
	#'PerfMonlong general' = $true
	#'PerfLongIntervalMin 40' = $true
	#'NetshScenario InternetClient_dbg' = $true
	#'NetshScenario InternetClient_dbg,dns_wpp' = $true
	#'NetshScenario InternetClient_dbg,dns_wpp capturetype=both captureMultilayer=yes provider=Microsoft-Windows-PrimaryNetworkIcon provider={1701C7DC-045C-45C0-8CD6-4D42E3BBF387}' = $true
	#'PSR' = $true
	#'WFPdiag' = $true
	#'RASdiag' = $true
	#'PktMon' = $true
	#'AddDescription' = $true
	#'SDP rds' = $True
	#'SDP setup,perf' = $True
	#'SkipSDPList noNetadapters,skipBPA' = $True
	#'xray' = $True
	#'Video' = $True
	#'SysMon' = $True
	#'CommonTask Mini' = $True
	#'CommonTask Full' = $True
	#'CommonTask Dev' = $True
	#'noBasicLog' = $True
	#'noPSR' = $True
	#'noVideo' = $True
	#'Mini' = $True
	#'NoSettingList noSDP,noXray,noBasiclog,noVideo,noPSR' = $True
	#'Xperf Pool' = $True
	#'XPerfMaxFile 4096' = $True
	#'XperfTag TcpE+AleE+AfdE+AfdX' = $True
	#'XperfPIDs 100' = $True
	#'LiveKD Both' = $True
	#'WireShark' = $True
	#'TTD notepad.exe' = $True   # Single process [<processname.exe>|<PID>]
	#'TTD notepad.exe,cmd.exe' = $True   # Multiple processes
	#'TTD tokenbroker' = $True   # Service name
	#'TTD Microsoft.Windows.Photos' = $True  # AppX
	#"TTDPath $env:userprofile\Desktop\PartnerTTDRecorder_x86_x64\amd64\TTD" = $True	# for downlevel OS TTD will find Partner tttracer in \Bin** folder
	#'TTDMode Ring' = $True   # choose [Full|Ring|onLaunch]
	#'TTDMaxFile 2048' = $True
	#'TTDOptions XXX' = $True
	#'CollectComponentLog' = $True
	#'Discard' = $True
	#'ProcDump notepad.exe,mspaint.exe,tokenbroker' = $true
	#'ProcDumpOption Both' = $true
	#'ProcDumpInterval 3:10' = $True
	#'GPResult Both' = $True
	#'PoolMon Both' = $True
	#'Handle Both' = $True
}

# DEV_Scn2
Switch (global:FwGetProductTypeFromReg){
	"WinNT" {
		$DEV_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'DEV_TEST1' = $true
			'DEV_TEST2' = $true  # Multi etl file trace
			'DEV_TEST3' = $true
			'DEV_TEST4' = $true   # Single trace
			'DEV_TEST5' = $False  # Disabled trace
			'UEX_Task' = $True	 # Outside of this module
		}
	}
	"ServerNT" {
		$DEV_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'DEV_TEST1' = $true
			'DEV_TEST2' = $true
		}
	}
	"LanmanNT" {
		$DEV_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'DEV_TEST1' = $true
			'DEV_TEST2' = $true
		}
	}
	Default {
		$DEV_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'DEV_TEST1' = $true
			'DEV_TEST2' = $true
		}
	}
}

# Dev_Scn3 => Multi etl only
$DEV_Scn3_ETWTracingSwitchesStatus = [Ordered]@{
	'DEV_TEST2' = $true   # Multi etl file trace
}

$DEV_EESummitDemo_ETWTracingSwitchesStatus = [Ordered]@{
	'DEV_EESummitDemo' = $true
	'ADS_Kerb' = $true
	'Netsh' = $true
	'PSR' = $true
	'xray' = $true
	'noBasicLog' = $true
	'CollectComponentLog' = $True
}

#endregion --- Scenario definitions ---



#region Functions

#region Components Functions
#region -------------- DevTest -----------
# IMPORTANT: this trace should be used only for development and testing purposes

function DevTestPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfoFile "[$($MyInvocation.MyCommand.Name)] .. started"
	global:FwCollect_BasicLog

	#### Various EVENT LOG  actions ***
	# A simple way for exporting EventLogs in .evtx and .txt format is done by function FwAddEvtLog ($EvtLogsLAPS array is defined at bottom of this file)
	# Ex: ($EvtLogsLAPS) | ForEach-Object { FwAddEvtLog $_ _Stop_}
	
	#Event Log - Set Log - Enable
	$EventLogSetLogListOn = New-Object 'System.Collections.Generic.List[Object]'
	$EventLogSetLogListOn = @(  #LogName, enabled, retention, quiet, MaxSize
		@("Microsoft-Windows-CAPI2/Operational", "true", "false", "true", "102400000"),
		@("Microsoft-Windows-Kerberos/Operational", "true", "", "", "")
	)
	ForEach ($EventLog in $EventLogSetLogListOn)
	{
	 global:FwEventLogsSet $EventLog[0] $EventLog[1] $EventLog[2] $EventLog[3] $EventLog[4]
	}

	#Event Log - Export Log
	$EventLogExportLogList = New-Object 'System.Collections.Generic.List[Object]'
	$EventLogExportLogList = @(  #LogName, filename, overwrite
		@("Microsoft-Windows-CAPI2/Operational", "c:\dev\Capi2_Oper.evtx", "true"),
		@("Microsoft-Windows-Kerberos/Operational", "c:\dev\Kerberos_Oper.evtx", "true")
	)
	ForEach ($EventLog in $EventLogExportLogList)
	{
	 global:FwExportSingleEventLog $EventLog[0] $EventLog[1] $EventLog[2] 
	}
	#Event Log - Set Log - Disable
	$EventLogSetLogListOff = New-Object 'System.Collections.Generic.List[Object]'
	$EventLogSetLogListOff = @(  #LogName, enabled, retention, quiet, MaxSize
		@("Microsoft-Windows-CAPI2/Operational", "false", "", "", ""),
		@("Microsoft-Windows-Kerberos/Operational", "false", "", "", "")
	)
	ForEach ($EventLog in $EventLogSetLogListOff)
	{
	 global:FwEventLogsSet $EventLog[0] $EventLog[1] $EventLog[2] $EventLog[3] $EventLog[4]
	}

	#Event Log - Clear Log
	$EventLogClearLogList = New-Object 'System.Collections.Generic.List[Object]'
	$EventLogClearLogList = @(  #LogName, enabled, retention, quiet, MaxSize
		@("Microsoft-Windows-CAPI2/Operational"),
		@("Microsoft-Windows-Kerberos/Operational")
	)
	ForEach ($EventLog in $EventLogClearLogList)
	{
		global:FwEventLogClear $EventLog[0] 
	}


	#### Various REGISTRY manipulaiton functions ***
	# A simple way for exporting Regisgtry keys is done by function FwAddRegItem with a registry array defined at bottom of this file ($global:KeysWinLAPS)
	# Ex.: FwAddRegItem @("WinLAPS") _Stop_
	
	# RegAddValues
	$RegAddValues = New-Object 'System.Collections.Generic.List[Object]'

	$RegAddValues = @(  #RegKey, RegValue, Type, Data
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\My Key", "my test1", "REG_DWORD", "0x1"),
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\My Key", "my test2", "REG_DWORD", "0x2")
	)

	ForEach ($regadd in $RegAddValues)
	{
		global:FwAddRegValue $regadd[0] $regadd[1] $regadd[2] $regadd[3]
	}

	# RegExport in TXT
	LogInfo "[$global:TssPhase ADS Stage:] Exporting Reg.keys .. " "gray"
	$RegExportKeyInTxt = New-Object 'System.Collections.Generic.List[Object]'
	$RegExportKeyInTxt = @(  #Key, ExportFile, Format (TXT or REG)
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\My Key", "C:\Dev\regtestexportTXT1.txt", "TXT"),
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL", "C:\Dev\regtestexportTXT2.txt", "TXT")
	)
 
	ForEach ($regtxtexport in $RegExportKeyInTxt)
	{
		global:FwExportRegKey $regtxtexport[0] $regtxtexport[1] $regtxtexport[2]
	}

	# RegExport in REG
	$RegExportKeyInReg = New-Object 'System.Collections.Generic.List[Object]'
	$RegExportKeyInReg = @(  #Key, ExportFile, Format (TXT or REG)
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\My Key", "C:\Dev\regtestexportREG1.reg", "REG"),
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL", "C:\Dev\regtestexportREG2.reg", "REG")
	)
	ForEach ($regregexport in $RegExportKeyInReg)
	{
		global:FwExportRegKey $regregexport[0] $regregexport[1] $regregexport[2]
	}

	# RegDeleteValues
	$RegDeleteValues = New-Object 'System.Collections.Generic.List[Object]'
	$RegDeleteValues = @(  #RegKey, RegValue
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\My Key", "my test1"),
		@("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\My Key", "my test2")
	)
	ForEach ($regdel in $RegDeleteValues)
	{
		global:FwDeleteRegValue $regdel[0] $regdel[1] 
	}
 

	#### FILE COPY Operations ***
	# Create Dest. Folder
	FwCreateFolder $global:LogFolder\Files_test2
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(  #source (* wildcard is supported) and destination
		@("C:\Dev\my folder\test*", "$global:LogFolder\Files_test2"), 		#this will copy all files that match * criteria into dest folder
		@("C:\Dev\my folder\test1.txt", "$global:LogFolder\Files_test2") 	#this will copy test1.txt to destination file name and add logprefix
	)
	global:FwCopyFiles $SourceDestinationPaths
	EndFunc $MyInvocation.MyCommand.Name
}

function DevTestPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfoFile "[$($MyInvocation.MyCommand.Name)] .. started"
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion -------------- DevTest -----------

### Pre-Start / Post-Stop / Collect / Diag function for Components tracing

##### Pre-Start / Post-Stop function for trace
function DEV_TEST1PreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	# Testing FwSetEventLog
	#FwSetEventLog "Microsoft-Windows-CAPI2/Operational" -EvtxLogSize:100000 -ClearLog
	#FwSetEventLog 'Microsoft-Windows-CAPI2/Catalog Database Debug' -EvtxLogSize:102400000
	#$PowerShellEvtLogs = @("Microsoft-Windows-PowerShell/Admin", "Microsoft-Windows-PowerShell/Operational")
	#FwSetEventLog $PowerShellEvtLogs
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_TEST1PostStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_TEST1PreStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	#LogWarn "** Will do Forced Crash now" cyan
	#FwDoCrash
	EndFunc $MyInvocation.MyCommand.Name
}

function DEV_TEST1PostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	# Testing FwResetEventLog
	#FwResetEventLog 'Microsoft-Windows-CAPI2/Operational'
	#FWResetEventLog 'Microsoft-Windows-CAPI2/Catalog Database Debug'
	#$PowerShellEvtLogs = @("Microsoft-Windows-PowerShell/Admin", "Microsoft-Windows-PowerShell/Operational")
	#FwResetEventLog $PowerShellEvtLogs
	EndFunc $MyInvocation.MyCommand.Name
}


function DEV_TEST2PreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_TEST2PostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}

function DEV_TEST3PreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_TEST3PostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
<#
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:ProgramData\Microsoft\WlanSvc\*", "$global:LogFolder\files_ProgramData_WlanSvc"),
		@("C:\Subst_E\test2\2_SDP_RFL", "$global:LogFolder"),
		@("C:\Subst_E\test1\SDP_RFL", "$global:LogFolder\SDP_RFL"),
		@("C:\Subst_E\test2\2_SDP_RFL\*", "$global:LogFolder\SDP_RFL2")
	)
	FwCopyFolders $SourceDestinationPaths -ShowMessage:$True
#>	
	#FwCreateFolder $global:LogFolder\Test2
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("C:\Subst_E\folder-missing\*", "$global:LogFolder\folder-missing\"),
		@("C:\Subst_E\test1\file-missing.txt", "$global:LogFolder\file-missing\"),
		@("C:\Subst_E\test1\SDP_RFL\*", "$global:LogFolder\test1-SDP-RFL"),	#<== don't forget the comma when having multi-line arrays!
		@("C:\Subst_E\test2\2_SDP_RFL\Win10*.txt", "$global:LogFolder\Test2\"),
		@("C:\Subst_E\test3\SDP_RFL\WIN10-22H2_230630-181531__Log-transcript.txt", "$global:LogFolder\Test3\my-new.txt")
	)
	FwCopyFiles  $SourceDestinationPaths -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

##### Data Collection
function CollectDEV_TEST1Log{
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefix = "Dev_TEST1"
	$LogFolderforDEV_TEST1 = "$Logfolder\Dev_TEST1"
	FwCreateFolder $LogFolderforDEV_TEST1

	<#
	<#--- Log functions ---#>
	#LogDebug "This is message from LogDebug."
	#LogInfo "This is message from LogInfo."
	#LogWarn "This is message from LogWarn."
	#LogError "This is message from LogError."
	#Try{
	#	Throw "Test exception"
	#}Catch{
	#	LogException "This is message from LogException" $_
	#}
	#LogInfoFile "This is message from LogInfoFile."
	#LogWarnFile "This is message from LogWarnFile."
	#LogErrorFile "This is message from LogErrorFile."

	<#--- Test ExportEventLog and FwExportEventLogWithTXTFormat ---#>
	#FwExportEventLog 'System' $LogFolderforDEV_TEST1
	#ExportEventLog "Microsoft-Windows-DNS-Client/Operational" $LogFolderforDEV_TEST1
	#FwExportEventLogWithTXTFormat 'System' $LogFolderforDEV_TEST1

	<#--- FwSetEventLog and FwResetEventLog ---#>
	#$EventLogs = @(
	#	'Microsoft-Windows-WMI-Activity/Trace'
	#	'Microsoft-Windows-WMI-Activity/Debug'
	#)
	#FwSetEventLog $EventLogs
	#Start-Sleep 20
	#FwResetEventLog $EventLogs

	<#--- FwAddEvtLog and FwGetEvtLogList ---#>  
	#($EvtLogsBluetooth) | ForEach-Object { FwAddEvtLog $_ _Stop_}	# see #region groups of Eventlogs for FwAddEvtLog
	#_# Note: FwGetEvtLogList should be called in _Start_Common_Tasks and _Start_Common_Tasks POD functions, otherwise it is called in FW FwCollect_BasicLog/FwCollect_MiniBasicLog functions
		
	<#--- FwAddRegItem and FwGetRegList ---#>
	#FwAddRegItem @("SNMP", "Tcp") _Stop_	# see #region Registry Key modules for FwAddRegItem
	#_# Note: FwGetRegList should be called in _Start_Common_Tasks and _Start_Common_Tasks POD functions, otherwise it is called in FW FwCollect_BasicLog/FwCollect_MiniBasicLog functions

	<#--- Test RunCommands --#>
	#$outFile = "$LogFolderforDEV_TEST1\netinfo.txt"
	#$Commands = @(
	#	"IPCONFIG /ALL | Out-File -Append $outFile"
	#	"netsh interface IP show config | Out-File -Append $outFile"
	#)
	#RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True

	<#--- FwCopyFiles ---#>
	# Case 1: Copy a single set of files
	#$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	#$SourceDestinationPaths.add(@("C:\Temp\*", "$LogFolderforDEV_TEST1"))
	#FwCopyFiles $SourceDestinationPaths

	# Case 2: Copy a single file
	#$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	#$SourceDestinationPaths.add(@("C:\temp\test-case2.txt", "$LogFolderforDEV_TEST1"))
	#FwCopyFiles $SourceDestinationPaths

	# Case 3: Copy multi sets of files
	#$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	#$SourceDestinationPaths = @(
	#	@("C:\temp\*", "$LogFolderforDEV_TEST1"),
	#	@("C:\temp2\test-case3.txt", "$LogFolderforDEV_TEST1")
	#)
	#FwCopyFiles $SourceDestinationPaths

	<#--- FwExportRegistry and FwExportRegToOneFile ---#>
	#LogInfo '[$LogPrefix] testing FwExportRegistry().'
	#$RecoveryKeys = @(
	#	('HKLM:System\CurrentControlSet\Control\CrashControl', "$LogFolderforDEV_TEST1\Basic_Registry_CrashControl.txt"),
	#	('HKLM:System\CurrentControlSet\Control\Session Manager\Memory Management', "$LogFolderforDEV_TEST1\Basic_Registry_MemoryManagement.txt"),
	#	('HKLM:Software\Microsoft\Windows NT\CurrentVersion\AeDebug', "$LogFolderforDEV_TEST1\Basic_Registry_AeDebug.txt"),
	#	('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Option', "$LogFolderforDEV_TEST1\Basic_Registry_ImageFileExecutionOption.txt"),
	#	('HKLM:System\CurrentControlSet\Control\Session Manager\Power', "$LogFolderforDEV_TEST1\Basic_Registry_Power.txt")
	#)
	#FwExportRegistry $LogPrefix $RecoveryKeys
	#
	#$StartupKeys = @(
	#	"HKCU:Software\Microsoft\Windows\CurrentVersion\Run",
	#	"HKCU:Software\Microsoft\Windows\CurrentVersion\Runonce",
	#	"HKCU:Software\Microsoft\Windows\CurrentVersion\RunonceEx"
	#)
	#FwExportRegToOneFile $LogPrefix $StartupKeys "$LogFolderforDEV_TEST1\Basic_Registry_RunOnce_reg.txt"

	<#---FwCaptureUserDump ---#>
	# Service
	#FwCaptureUserDump -Name "Winmgmt" -DumpFolder $LogFolderforDEV_TEST1 -IsService:$True
	# Process
	#FwCaptureUserDump -Name "notepad" -DumpFolder $LogFolderforDEV_TEST1
	# PID
	#FwCaptureUserDump -ProcPID 4524 -DumpFolder $LogFolderforDEV_TEST1
	
	<#---general collect functions - often used in _Start/Stop_common_tasks---#>
	#FwClearCaches _Start_ 
	#FwCopyWindirTracing IPhlpSvc 
	#FwDoCrash 
	#FwGetCertsInfo _Stop_ Basic
	#FwGetEnv 
	#FwGetGPresultAS 
	#FwGetKlist 
	#FwGetMsInfo32 
	#FwGetNltestDomInfo 
	#FwGetPoolmon 
	#FwGetProxyInfo 
	#FwGetQwinsta 
	#FwGetRegHives 
	#FwRestartInOwnSvc WebClient
	#FwGetSVC 
	#FwGetSVCactive 
	#FwGetSysInfo 
	#FwGetTaskList 
	#FwGetWhoAmI
	#FwTest-TCPport -ComputerName "cesdiagtools.blob.core.windows.net" -Port 80 -Timeout 900
	
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectDEV_TEST2Log
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}

##### Diag function
function RunDEV_TEST1Diag
{
	EnterFunc $MyInvocation.MyCommand.Name
	If($global:BoundParameters.containskey('InputlogPath')){
		$diagpath = $global:BoundParameters['InputlogPath']
		LogInfo "diagpath = $diagpath"
	}
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
<#
function RunDEV_TEST2Diag
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>
#endregion Components Functions

#region Scenario Functions

### Pre-Start / Post-Stop / Collect / Diag function for scenario tracing
##### Common tasks
function DEV_Start_Common_Tasks{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	#FwGetRegList _Start_
	#FwGetEvtLogList _Start_
	EndFunc $MyInvocation.MyCommand.Name
}

function DEV_Stop_Common_Tasks{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	#FwGetRegList _Stop_
	#FwGetEvtLogList _Stop_
	EndFunc $MyInvocation.MyCommand.Name
}

##### DEV_Scn1
function DEV_Scn1ScenarioPreStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_Scn1ScenarioPostStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_Scn1ScenarioPreStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_Scn1ScenarioPostStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectDEV_Scn1ScenarioLog
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function RunDEV_Scn1ScenarioDiag
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}

##### DEV_Scn2
function DEV_Scn2ScenarioPreStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function DEV_Scn2ScenarioPostStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectDEV_Scn2ScenarioLog
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
<#
function RunDEV_Scn2ScenarioDiag
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>


#region DEV_EESummitDemo
function DEV_EESummitDemoPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] .. Enabling Netlogon service debug log"
	FwAddRegValue "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" "DbFlag" "REG_DWORD" "$global:NetLogonFlag"
	EndFunc $MyInvocation.MyCommand.Name
}

function DEV_EESummitDemoPostStop {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] .. Disabling Netlogon service debug log"
	FwAddRegValue "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" "DbFlag" "REG_DWORD" "0x0"
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectDEV_EESummitDemoLog {
EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] Collecting DEV_EESummitDemo logs started."
	# init variables
	$ComputerSystem = Get-WmiObject -Namespace "root\CIMv2" -Class Win32_ComputerSystem
	if (!([string]::IsNullOrEmpty($ComputerSystem))) {
		#$ComputerDomain = $ComputerSystem.Domain
		$DomainRole = $ComputerSystem.DomainRole
	} else {
		#$ComputerDomain = "WORKGROUP"
		$DomainRole = 0
	}
	$RootDSE = [ADSI]"LDAP://RootDSE"
	$DefaultNamingContext = $RootDSE.defaultNamingContext
	if ($Null -ne $DefaultNamingContext) {
		$ConfigurationNamingContext = $RootDSE.configurationNamingContext
		$DCAccessible = $True
	} else {
		$DCAccessible = $False
	}

	#setting commands to execute
	if (($DomainRole -eq 1) -Or ($DomainRole -eq 3) -Or ($DomainRole -eq 4) -Or ($DomainRole -eq 5)) { # Member Workstation, Member Server, BDC, or PDC
		if ($DCAccessible -eq $True) {
			$Commands = @(
				"nltest /dclist: | Out-File -Append $($PrefixTime)nltest_dclist.txt"
				"nltest /dsgetsite | Out-File -Append $($PrefixTime)nltest_dsgetsite.txt"
				"nltest /domain_trusts /all_trusts /v | Out-File -Append $($PrefixTime)nltest_domain_trusts_all_trusts_v.txt"
				"nltest /trusted_domains | Out-File -Append $($PrefixTime)nltest_trusted_domains.txt"
				"w32tm /query /status /verbose | Out-File -Append $($PrefixTime)w32tm_query_status.txt"
				"w32tm /query /configuration | Out-File -Append $($PrefixTime)w32tm_query_config.txt"
				"w32tm /query /peers /verbose | Out-File -Append $($PrefixTime)w32tm_query_peers.txt"
			)
		} else {
			#do nothing
		}
	}
	# executing commands:
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False

	# FW conveniance function for GPO relevant data
	FwGetGPresultAS 

	# files to copy: source , destination
	$SourceDestinationPaths = @(
		@("$Env:SYSTEMROOT\debug\dcpromo.log", "$($PrefixTime)dcpromo.log"),
		@("$Env:SYSTEMROOT\debug\dcpromoui.log", "$($PrefixTime)dcpromoui.log"),
		@("$Env:SYSTEMROOT\debug\netlogon.log", "$($PrefixTime)netlogon.log"),
		@("$Env:SYSTEMROOT\debug\netsetup.log", "$($PrefixTime)netsetup.log")
	)
	# copying files
	FwCopyFiles $SourceDestinationPaths

	# export registry
	$global:KeysEESummitDemo = @(
		"HKLM:System\CurrentControlSet\Services\W32Time"
		"HKLM:Software\Policies\Microsoft\W32Time"
		"HKLM:System\CurrentControlSet\Services\Netlogon\Parameters"
		"HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions\{D76B9641-3288-4f75-942D-087DE603E3EA}"
	)
	FwAddRegItem @("EESummitDemo") _Stop_

	#export event logs
	$EvtEESummitDemo = @("Application", "System", "Directory Service")
	($EvtEESummitDemo) | ForEach-Object { FwAddEvtLog $_ _Stop_}

	LogInfo "[$($MyInvocation.MyCommand.Name)] Collecting DEV_EESummit logs ended."
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectDEV_EESummitDemoScenarioLog{
	LogInfo "[$($MyInvocation.MyCommand.Name)] Collecting DEV_EESummitDemoScenario logs started."
	CollectDEV_EESummitDemoLog
}
#endregion DEV_EESummitDemo


#endregion Scenario Functions

#endregion Functions

#region Registry Key modules for FwAddRegItem
<#
	$global:KeysSNMP = @("HKLM:System\CurrentControlSet\Services\SNMP", "HKLM:System\CurrentControlSet\Services\SNMPTRAP")
	$global:KeysWinLAPS = @(
		"HKLM:Software\Microsoft\Policies\LAPS"
		"HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\LAPS"
		"HKLM:Software\Policies\Microsoft Services\AdmPwd"
		"HKLM:Software\Microsoft\Windows\CurrentVersion\LAPS\Config"
		"HKLM:Software\Microsoft\Windows\CurrentVersion\LAPS\State"
		"HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions\{D76B9641-3288-4f75-942D-087DE603E3EA}"
	)
#>
	<# Example:
	$global:KeysHyperV = @("HKLM:Software\Microsoft\Windows NT\CurrentVersion\Virtualization", "HKLM:System\CurrentControlSet\Services\vmsmp\Parameters")
	#>

 # B) section of NON-recursive lists
 <#
 	$global:KeysDotNETFramework = @(
		"HKLM:Software\Microsoft\.NETFramework\v2.0.50727"
		"HKLM:Software\Wow6432Node\Microsoft\.NETFramework\v2.0.50727"
		"HKLM:Software\Microsoft\.NETFramework\v4.0.30319"
		"HKLM:Software\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"
	)
#>

#endregion Registry Key modules


#endregion Registry Key modules

#region groups of Eventlogs for FwAddEvtLog
<#
	$EvtLogsBluetooth 	= @("Microsoft-Windows-Bluetooth-BthLEPrepairing/Operational", "Microsoft-Windows-Bluetooth-MTPEnum/Operational")
#	$EvtLogsLAPS		= @("Microsoft-Windows-LAPS-Operational", "Microsoft-Windows-LAPS/Operational")
	<# Example:
	$global:EvtLogsEFS	= @("Microsoft-Windows-NTFS/Operational", "Microsoft-Windows-NTFS/WHC")
	#>
#endregion groups of Eventlogs

# Deprecated parameter list. Property array of deprecated/obsoleted params.
#   DeprecatedParam: Parameters to be renamed or obsoleted in the future
#   Type           : Can take either 'Rename' or 'Obsolete'
#   NewParam       : Provide new parameter name for replacement only when Type=Rename. In case of Type='Obsolete', put null for the value.
$DEV_DeprecatedParamList = @(
<#
	@{DeprecatedParam='DEV_kernel';Type='Rename';NewParam='WIN_kernel'}
#	@{DeprecatedParam='DEV_SAM';Type='Rename';NewParam='DEV_SAMsrv'} # <-- this currently fails
	@{DeprecatedParam='DEV_EEsummitDemo';Type='Rename';NewParam='DEV_EEsummitDemo'}
#>
)
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *



# SIG # Begin signature block
# MIIoKgYJKoZIhvcNAQcCoIIoGzCCKBcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCMmVHHsIA2ii6u
# GDXO3Plyn8H5L3n1LVa9MPEzey4MZqCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgowghoGAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICRg6A5+sa4uyZ/QTkpu/eaW
# 6pSVMBBIW1wdF0BfhBGVMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAT47fr0l1F9c+1Q3StSgWN9P0I8HrDru/d5+jyVBLp39AXBnVrf4XEMfS
# hhJfpG4lUy9TxOYmVyQYi25LDu8+tddNujbYABq3KhBEIJwwn1P0OEqyLxgW2kNe
# rw82mXB9cgKKZ+Y5lZfQte62F46eU8dOlNHcahNmcL/qLGcLMJn4c/ImSrcuow/3
# MyyQSuNhjlPDXdVqKdbfEIRLLDA+MLIZ6zctWwlgqdSNSj3h7oQB+67i9UUHy6bV
# b7bVvvEPGlDiA9Nzua/qvWTXHB4gTq6RwXQINCLOPtTlAR0CdnNv/PiPeKN0yw8n
# 2lWW4IuKSv+p6tmLWqYRAQqOzTBZB6GCF5QwgheQBgorBgEEAYI3AwMBMYIXgDCC
# F3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCBvZabKFzfw90+8kcBiB3yQr9/T8sQaFvjuE0esKbgBvAIGZkYSOqaI
# GBMyMDI0MDYxMjE0NTg0OS41MzhaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046ODYwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHqMIIHIDCCBQigAwIBAgITMwAAAfGzRfUn6MAW1gABAAAB8TANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# NTVaFw0yNTAzMDUxODQ1NTVaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046ODYwMy0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCxulCZttIf8X97rW9/J+Q4Vg9PiugB1ya1/DRxxLW2
# hwy4QgtU3j5fV75ZKa6XTTQhW5ClkGl6gp1nd5VBsx4Jb+oU4PsMA2foe8gP9bQN
# PVxIHMJu6TYcrrn39Hddet2xkdqUhzzySXaPFqFMk2VifEfj+HR6JheNs2LLzm8F
# DJm+pBddPDLag/R+APIWHyftq9itwM0WP5Z0dfQyI4WlVeUS+votsPbWm+RKsH4F
# QNhzb0t/D4iutcfCK3/LK+xLmS6dmAh7AMKuEUl8i2kdWBDRcc+JWa21SCefx5SP
# hJEFgYhdGPAop3G1l8T33cqrbLtcFJqww4TQiYiCkdysCcnIF0ZqSNAHcfI9SAv3
# gfkyxqQNJJ3sTsg5GPRF95mqgbfQbkFnU17iYbRIPJqwgSLhyB833ZDgmzxbKmJm
# dDabbzS0yGhngHa6+gwVaOUqcHf9w6kwxMo+OqG3QZIcwd5wHECs5rAJZ6PIyFM7
# Ad2hRUFHRTi353I7V4xEgYGuZb6qFx6Pf44i7AjXbptUolDcVzYEdgLQSWiuFajS
# 6Xg3k7Cy8TiM5HPUK9LZInloTxuULSxJmJ7nTjUjOj5xwRmC7x2S/mxql8nvHSCN
# 1OED2/wECOot6MEe9bL3nzoKwO8TNlEStq5scd25GA0gMQO+qNXV/xTDOBTJ8zBc
# GQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFLy2xe59sCE0SjycqE5Erb4YrS1gMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQDhSEjSBFSCbJyl3U/QmFMW2eLPBknnlsfI
# D/7gTMvANEnhq08I9HHbbqiwqDEHSvARvKtL7j0znICYBbMrVSmvgDxU8jAGqMyi
# LoM80788So3+T6IZV//UZRJqBl4oM3bCIQgFGo0VTeQ6RzYL+t1zCUXmmpPmM4xc
# ScVFATXj5Tx7By4ShWUC7Vhm7picDiU5igGjuivRhxPvbpflbh/bsiE5tx5cuOJE
# JSG+uWcqByR7TC4cGvuavHSjk1iRXT/QjaOEeJoOnfesbOdvJrJdbm+leYLRI67N
# 3cd8B/suU21tRdgwOnTk2hOuZKs/kLwaX6NsAbUy9pKsDmTyoWnGmyTWBPiTb2rp
# 5ogo8Y8hMU1YQs7rHR5hqilEq88jF+9H8Kccb/1ismJTGnBnRMv68Ud2l5LFhOZ4
# nRtl4lHri+N1L8EBg7aE8EvPe8Ca9gz8sh2F4COTYd1PHce1ugLvvWW1+aOSpd8N
# nwEid4zgD79ZQxisJqyO4lMWMzAgEeFhUm40FshtzXudAsX5LoCil4rLbHfwYtGO
# pw9DVX3jXAV90tG9iRbcqjtt3vhW9T+L3fAZlMeraWfh7eUmPltMU8lEQOMelo/1
# ehkIGO7YZOHxUqeKpmF9QaW8LXTT090AHZ4k6g+tdpZFfCMotyG+E4XqN6ZWtKEB
# QiE3xL27BDCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggNN
# MIICNQIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjg2MDMtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQD7
# n7Bk4gsM2tbU/i+M3BtRnLj096CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hQnQjAiGA8yMDI0MDYxMjEzNTUx
# NFoYDzIwMjQwNjEzMTM1NTE0WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDqFCdC
# AgEAMAcCAQACAgzBMAcCAQACAhLIMAoCBQDqFXjCAgEAMDYGCisGAQQBhFkKBAIx
# KDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
# hvcNAQELBQADggEBABEUsXwTzWLKrIFEGFil+a16Dcx/YVDkZt3NVa+qI8oKfR1H
# yxIqEzSo09YKJ5TZPpxfMWtptd7aKoFLhfF9ciql0MZ24aYMK7xCB8om5N8+vTqv
# KdS0wEFXWfzbwnTCroMn2zl4C8uiQnWOL3thnwZIFlwu6BWd7kiN38MjvAZKxdSE
# TwSQ6s/GIL6MygETpMobICcuIZdEWi/bF66kds7a6x89gJYxN2hYU804/ugXgNrr
# UcvlvT+54azkUZlNioI/LNNu9sbH/JDFZKLDbW33SeRkcD7s2B6VNA1W5vLMWnba
# l2uD+fx+1NT5QuC0SfMTqbMd/DvplbAKR/K+JuAxggQNMIIECQIBATCBkzB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAfGzRfUn6MAW1gABAAAB8TAN
# BglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8G
# CSqGSIb3DQEJBDEiBCDePsRuxjop1Al55exnpWgKc/lAIF67Lq+x+pBaLfBNOzCB
# +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EINV3/T5hS7ijwao466RosB7wwEib
# t0a1P5EqIwEj9hF4MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAHxs0X1J+jAFtYAAQAAAfEwIgQgQdQxzrw1JZ/jFeRei5ywaMgWhn+I
# e8cj7H/1NlVkem4wDQYJKoZIhvcNAQELBQAEggIAa2ynkvvQJ7un8aM9qMI0Rm+l
# Jj4TmZXeVjkzoYVsrX860TZ5yHQcqf760P/Qn6Nrlye+zZJ9OsZTVNZSXJdScMrQ
# qJqGHYolGcq+ayu8m231lwHTg7lQYoevUnAtV3b0q4X+vGpRaBTi7+cDw7RkM5j7
# 8JZIWyObKVjgui8vi57pd3jSeJiz1GIKYbem+iXWTBw8l6qoQAhc2cDxBF4i2Hm1
# 3OStyitJDJ8quhtyFHC4f+W0RUXo8X5SgM8clMOZAEnYXs3txBoKqhDzl1a0Y28f
# L5zNxekcCycga/znaUSuapqXad/3BHxPd7MgTy0xoRx5R19TbEkyHlQTm7TgCz1J
# qP3FMbB0FgHHywH9zNlTgsWLDaRA7KNPjU7Xx+c3PM3J6ZDssHUQz3f8zMH6EjWY
# Ad4JhkVJ73FOqMb/9Q8yiFd7B62mSUBMqTMMxAWd1ujS0ZINDv3rWlcI8jsjX3gh
# ZW43ucUzRS0x4QfrM9Nt7FDGhERKztRWK++gEh0UzvC6QiDONtvROcogtW9n8bQT
# g8II9MuDeH41KExkqHypIBc+ufq7Rnl1sDCbzdHvuXlHfNawelvCfR6m36fNcIxm
# FifzyflP+MjNquugkqmRL/uhtPzNUcooy1rILb/xzbFN36pu/guxkAQ1leNaKqhc
# TBSORGdK+xxtJhfL0tc=
# SIG # End signature block
