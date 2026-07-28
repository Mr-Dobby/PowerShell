<#
.SYNOPSIS
	CCM module to extend TSS with SCCM specific scenarios.

.DESCRIPTION
	This module is used for collecting logs and traces for SCCM scenarios with TSS instead of psSDP.

.NOTES
	Dev. Lead   : lamosley
	Authors		: lamosley, sabieler
	Contributors: viki, bgonzales, lamosley, sabieler
	Requires	: PowerShell V4(Supported from Windows 8.1/Windows Server 2012 R2)
	Version		: see $global:TssVerDateMCM

.LINK
	TSS https://internal.evergreen.microsoft.com/en-us/help/4619187
#>

<# latest changes
::  2024.05.30.4 [lm] Feature 685 - collect intermediate CAs; move certificate collectiong into it's own function
::  2024.05.30.3 [lm] fix bug 745 - only collect WSUS registry key when WSUS is installed, move registry collection into it's own function
::  2024.05.30.2 [vi] Fix bug #779: function Get-SccmWsusServerInfo has a malformed catch block
::  2024.05.30.1 [vi] Fix bug #778: Get-SccmWsusServerInfo might not recover if the WSUS ContentDir cannot be accessed
::  2024.05.30.0 [vi] Fix bug #738: GetUpdateServer('<NetBIOS>') method will fail in case of https, if the PKI certificate uses FQDN
::  2024.05.14.0 [vi] Fix bug #725: skipping WSUS related data gathering if WSUS install directory is not found
::  2024.05.04.6 [vi] implemented workaround for bug #722
::  2024.05.04.5 [vi] Feature #717: generate WindowsUpdate.log
::  2024.05.04.4 [vi] added -force parameter to the trap statement handling exceptions related to "WUA version", otherwise the trap statement can cause another exception
::  2024.05.04.3 [vi] added function OutputWaitforResult
::  2024.05.04.2 [vi] fixed a typo that resulted in calling FwWaitForProcess with the wrong variable (GPresultFileZ instead of GPresultFileH)
::  2024.05.04.1 [vi] added function fn_ActionsToSkip and the related condition to most of the actions
::  2024.05.04.0 [vi] changed the scope of following variables from global to script: msinfo32NFO, GPresultFileZ, GPresultFileH
::  2024.04.25.0 [vi] fix msinfo32 when psexec can't run
::  2024.04.23.4 [vi] hiding CMD when gpresult /h gets executed
::  2024.04.23.3 [vi] fixed an output issue with CMClient_Summary.txt
::  2024.04.23.2 [vi] dumping ROOT\ccm\dcm:SMS_DesiredConfiguration WMI class
::  2024.04.23.1 [vi] extended output of WUA_Summary.txt / Default Update Source
::  2024.04.23.0 [vi] hiding msinfo32.exe window in session 0
::  2024.04.12.1 [vi] Feature 700: added SleepStudy output
::  2024.04.12.0 [sb] fixed and issue in Get-SCCMUpdateHistory
::  2024.04.11.0 [vi] Feature 699: added update sources to WUA Summary
::  2024.04.10.1 [bg] Feature 698: capture EPAMPolicy.xml, Feature 658: add slmgr.vbs output to SCCM diag data collection
::  2024.03.27.4 [lm] # Fix bug 694: Not collecting the Lantern (Microsoft Policy Platform) logs from the client
::  2024.03.14.0 [lm] # Fix bug 687: bad gpresult output,  688: script stops if exception connecting to wsus, 689: Incorrect architecture reported when run from 32-bit PoSH
::  2024.03.08.0 [lm] # Feature 668: Change VLOGS collection to top 5000 rows, drop SYNC% filter, add filter ProcedureName <> 'spCMGSProcessMessageV2'
::  2024.03.07.1 [sb] # Feature 669: SCCM TSS should collect IIS settings like Sites and their Bindings
::  2024.03.07.0 [sb] Feature 664: Remove DEVCON collection from -CollectLog MCM_Report
::  2024.03.06.4 [sb] Feature 665: Exclude CrashDumps directory collection from the SMS logs collection on a site server
::  2024.03.06.3 [lm] Remove Feature 675: Remove additional logs - these are not needed for ConfigMgr and we are overcollecting
::  2024.03.06.2 [sb] Feature 674: PatchDownloader.log under %temp%
::  2024.03.06.1 [lm] Feature 680:AlwaysOn databases reported as non-compliant in SQL_ConfigCompliance.txt, feature 679: Remove Update-DiagRootCause and Add-GenericMessage calls for -CollectLog MCM_Report
::  2024.03.06.0 [sb] Feature 678: Add SMSCFG.ini in SCCM scenario
::  2024.03.05.1 [sb] Feature 677: Add OMADM\Accounts in SCCM scenario
::  2024.03.05.0 [sb] Feature 675: Additional event logs in SCCM scenario
::  2024.03.04.0 [sb] moved Get-SCCMRoiscan to function CollectMCM_OfficeLog
::  2024.02.29.8 [sb] fix smsdpprov.log collection - feature 666
::  2024.02.29.7 [sb] renamed all occurences of CollectSCCM_ReportLog to CollectMCM_ReportLog
::  2024.02.29.6 [sb] moved deployment and upgrade related logs to Get-SCCMWindowsLogs
::  2024.02.29.5 [sb] renamed more WSUSLogsZipFile variables to a meaningful name regarding its purpose
::  2024.02.29.4 [sb] added error action ignore to function Test-RegKeyExistByPattern
::  2024.02.29.3 [sb] Feature 653: Add WSUS configuration to _WSUS_Summary.txt and collect additional logs + IIS applicationHost.config
::  2024.02.29.2 [sb] reorganized Get-SCCMLogs to not create empty folders if called when $Is_SiteServer = $false
::  2024.02.29.1 [sb] added logic to detect standalone WSUS servers
::  2024.02.29.0 [sb] changed variable name WSUSLogsZipFile to IISLogsZipFile (and VSCode auto-formatting)
::  2024.02.27.0 [lm] Rename CollectSCCM_ReportLog to CollectMCM_ReportLog as part of changing POD name to comply with 3 character limit
::  2024.02.26.1 [lm] Feature 663 and 595: Implement fixes and changes to make SQL errorlog and SMS_SITE_SQL_BACKUP log collection work
::  2024.02.26.0 [sb] Rename SCCM to SCCM_Report; add help entry
::  2024.02.23.3 [sb] Feature 620: Add "Service Connection Point" role to list of CMRoles
::  2024.02.23.2 [sb] Feature 594: Add "Site database server" role to list of CMRoles
::  2024.02.23.1 [sb] Feature 558: Collect ConfigMgr Server Archived Logs, if present
::  2024.02.23.0 [sb] removed function Get-FLTMC and using FwGetFltMcInfo instead
::  2024.02.20.3 [sb] renamed SCCM_Basic to SCCM
::  2024.02.20.2 [lm] add fltmc collection
::  2024.02.20.1 [sb] removed overhead checks if DND module has been loaded
::  2024.02.20.0 [sb] fixed bug in Set-SCCMVariables
::  2024.02.19.3 [sb] added better detection loginc for OS version
::  2024.02.19.2 [sb] Feature 494: _DND: Capture Delivery Optimization log for SCCM collection
::  2024.02.19.0 [sb] Feature 643: Collect Windows 11 upgrade keys, blocking reasons, etc for SCCM TSS
::  2024.02.13.0 [sb] added better logging in Invoke-SCCMFinalize
::  2024.02.12.6 [sb] implemented DC_FinishExecution.ps1 in function Invoke-SCCMFinalize
::  2024.02.12.5 [sb] implemented DC_HotfixRollups.ps1 in function Get-SCCMHotfixRollups
::  2024.02.12.4 [sb] implemented DC_UpdateHistory.ps1 in function Get-SCCMUpdateHistory
::  2024.02.12.3 [sb] implemented TS_CheckCCMNamespace.ps1 in function Get-SCCMNamespaceInfo
::  2024.02.12.2 [sb] implemented DC_CollectWindowsLogs.ps1 in function Get-SCCMWindowsLogs
::  2024.02.12.1 [sb] implemented DC_DsRegCmd.ps1 in function Get-SCCMDsRegCmd
::  2024.02.12.0 [sb] implemented TS_ProvisioningMode.ps1 in function Get-SCCMProvisioningMode
::  2024.02.09.5 [sb] implemented TS_CheckServiceStatus.ps1 in function Get-SCCMServiceStatus
::  2024.02.09.4 [sb] implemented DC_CollectConfigMgrLogs.ps1 in function Get-SCCMLogs
::  2024.02.09.3 [sb] implemented DC_CollectSQLErrLogs.ps1 in function Get-SCCMSQLErrLogs
::  2024.02.09.2 [sb] implemented DC_CollectIISVDirInfo.ps1 in function Get-SCCMIISvDirInfo
::  2024.02.09.1 [sb] implemented DC_IIS_Collect_Configuration.ps1 in function Get-SCCMIISConfig
::  2024.02.09.0 [sb] implemented DC_CollectIISLogs.ps1 in function Get-SCCMIISLogs
::  2024.02.08.5 [sb] changed color coding tss_SCCM_utils.ps1
::  2024.02.08.4 [sb] implemented TS_CheckSQLConfig.ps1 in function Get-SCCMSQLCfgInfo
::  2024.02.08.3 [sb] implemented DC_CM12SQLInfo.ps1 in function Get-SCCMSQLInfo
::  2024.02.08.2 [sb] implemented DC_CM12SMSProvInfo.ps1 in function Get-SCCMProviderInfo
::  2024.02.08.1 [sb] implemented GetCM12Hierarchy.ps1 in function Get-SCCMHierarchy
::  2024.02.08.0 [sb] implemented DC_CM12ServerInfo.ps1 in function Get-SCCMServerInfo
::  2024.02.07.2 [sb] implemented DC_CM12ClientInfo.ps1 in function Get-SCCMClientInfo
::  2024.02.07.1 [sb] implemented DC_ROIScan.ps1 in function Get-SCCMRoiScan
::  2024.02.07.0 [sb] implemented DC_WUAInfo.ps1 in function Get-SCCMWUAInfo
::  2024.02.02.4 [sb] modified Get-WSUSBasicInfo.ps1 for TSS usage and saved it in scripts\tss_SCCM_WSUSBasicInfo.ps1
::  2024.02.02.3 [sb] implemented DC_WSUSServerInfo.ps1 in function Get-SCCMWSUSServerInfo
::  2024.02.02.2 [sb] created function Set-SCCMVariables to initialize global variables and check which SCCM components are installed on the machine
::  2024.02.02.1 [sb] moved functions from utils_ConfigMgr12.ps1 to "$Scriptfolder\scripts\tss_SCCM_utils.ps1"
::  2024.02.02.0 [sb] outsourced SCCM utility functions to "$Scriptfolder\scripts\tss_SCCM_utils.ps1"
::  2024.02.01.1 [sb] implemented DC_UserRights.ps1 in function Get-SCCMUserPermissions
::  2024.02.01.0 [sb] implemented DC_SCCM_RegKeys.ps1 in function Get-SCCMRegistryInfo
::  2024.01.31.6 [sb] implemented DC_NetworkInfo.ps1.ps1 in function Get-SCCMNetworkInfo
::  2024.01.31.5 [sb] implemented DC_SummaryReliability.ps1 in function Get-SCCMGenericInfo
::  2024.01.31.4 [sb] implemented DC_PoolMon.ps1 in function Get-SCCMProcessInfo
::  2024.01.31.3 [sb] implemented DC_Whoami.ps1 in function Get-SCCMGenericInfo
::  2024.01.31.2 [sb] implemented DC_TaskListSvc.ps1 in function Get-SCCMGenericInfo
::  2024.01.31.1 [sb] implemented DC_Services.ps1 in function Get-SCCMServices
::  2024.01.31.0 [sb] implemented DC_BasicSystemInformationTXT.ps1 in function Get-SCCMBasicSystemInfo
::  2024.01.30.2 [sb] moved region Pstat to Get-SCCMProcessInfo
::  2024.01.30.1 [sb] implemented Get-SCCMProcessInfo to collect process info and disabled services
::  2024.01.30.0 [sb] implemented DC_ScheduleTasks.ps1 in function Get-SCCMGenericInfo
::  2024.01.29.3 [sb] the output of DC_ServerManagerInfo.ps1 is similar to 'Roles_Features.txt', skipping it
::  2024.01.29.2 [sb] implemented DC_Autoruns.ps1 in function Get-SCCMAutoRuns
::  2024.01.29.1 [sb] implemented DC_ChkSym.ps1 in function Get-SCCMChkSym via external script "$global:ScriptsFolder\tss_ChkSym.ps1"
::  2024.01.29.0 [sb] implemented DC_PStat.ps1 in function Get-SCCMGenericInfo
::  2024.01.26.1 [sb] minor changes
::  2024.01.26.0 [sb] implemented DC_GenericInfo.ps1 in function Get-SCCMGenericInfo
::  2024.01.25.1 [sb] implemented DC_NetworkingDiagnostic.ps1 in function Get-SCCMGenericInfo
::  2024.01.25.0 [sb] initial SCCM module version
#>

$global:TssVerDateMCM = '2024.05.30.1'

<#
#region --- ETW component trace Providers ---
# Normal trace -> data will be collected in a single file
$SCCM_TEST1Providers = @(
	'{CC85922F-DB41-11D2-9244-006008269001}' # LSA
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' # Kerberos
)

# Normal trace with multi etl files
# Syntax is: GUID!filename!flags!level
# GUID is mandtory
# if filename is not provided TSS will create etl using Providers name, i.e. SCCM_test2
# if flags is not provided, TSS defaults to 0xffffffff
# if level is not provided, TSS defaults to 0xff
$SCCM_TEST2Providers = @(
	'{98BF1CD3-583E-4926-95EE-A61BF3F46470}!CertCli!0xffffff!0x05'
	'{6A71D062-9AFE-4F35-AD08-52134F85DFB9}!CertificationAuthority!0xff!0x07'
	'{B40AEF77-892A-46F9-9109-438E399BB894}!CertCli!0xfffffe!0x04'
	'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xfffffffe'
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}!CertificationAuthority!0xC43EFF!0x06'
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xffffffff!0x0f'
)

# Single etl + multi flags
$SCCM_TEST3Providers = @(
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
	'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffff'
)

$SCCM_TEST4Providers = @(
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
	'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffff'
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xffffffff!0x0f'
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}!CertificationAuthority!0xC43EFF!0x06'
)

$SCCM_DemoProviders = @(
	'{CA030134-54CD-4130-9177-DAE76A3C5791}!netlogon' # NETLOGON/ NETLIB
	'{E5BA83F6-07D0-46B1-8BC7-7E669A1D31DC}!netlogon' # Microsoft-Windows-Security-Netlogon
	'{8EE3A3BF-9379-4DAC-B376-038F498B19A4}!w32time' # Microsoft.Windows.W32Time
)


#select basic or full tracing option for the same etl guids using different flags
if ($global:CustomParams){
	Switch ($global:CustomParams[0]){
		"full" {$SCCM_TEST5Providers = @(
				'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xffffffff'
				'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffffff'
				)
		}
		"basic" {$SCCM_TEST5Providers = @(
				'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
				'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xffffff'
				)
		}
		Default {$SCCM_TEST5Providers = @(
				'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!lsa!0xC43EFF'
				'{169EC169-5B77-4A3E-9DB6-441799D5CACB}!lsa!0xfffff!0x12'
				)
		}
	}
}
#endregion --- ETW component trace Providers ---
#>

<#
#region --- Scenario definitions ---

$SCCM_General_ETWTracingSwitchesStatus = [Ordered]@{
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

$SCCM_ScenarioTraceList = [Ordered]@{
	'SCCM_Scn1' = 'DEV scenario trace 1'
	'SCCM_Scn2' = 'DEV scenario trace 2'
	'SCCM_Demo'    = 'SCCM_Demo Trace, ADS_Kerb, PSR, Netsh'
}

# SCCM_Scn1
$SCCM_Scn1_ETWTracingSwitchesStatus = [Ordered]@{
	'SCCM_TEST1' = $true
	#'SCCM_TEST2' = $true   # Multi etl file trace
	#'SCCM_TEST3' = $true   # Single trace
	#'SCCM_TEST4' = $true
	#'SCCM_TEST5' = $true
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

# SCCM_Scn2
Switch (global:FwGetProductTypeFromReg){
	'WinNT' {
		$SCCM_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'SCCM_TEST1' = $true
			'SCCM_TEST2' = $true  # Multi etl file trace
			'SCCM_TEST3' = $true
			'SCCM_TEST4' = $true   # Single trace
			'SCCM_TEST5' = $False  # Disabled trace
			'UEX_Task' = $True	 # Outside of this module
		}
	}
	'ServerNT' {
		$SCCM_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'SCCM_TEST1' = $true
			'SCCM_TEST2' = $true
		}
	}
	'LanmanNT' {
		$SCCM_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'SCCM_TEST1' = $true
			'SCCM_TEST2' = $true
		}
	}
	Default {
		$SCCM_Scn2_ETWTracingSwitchesStatus = [Ordered]@{
			'SCCM_TEST1' = $true
			'SCCM_TEST2' = $true
		}
	}
}

# SCCM_Scn3 => Multi etl only
$SCCM_Scn3_ETWTracingSwitchesStatus = [Ordered]@{
	'SCCM_TEST2' = $true   # Multi etl file trace
}

$SCCM_Demo_ETWTracingSwitchesStatus = [Ordered]@{
	'SCCM_Demo' = $true
	'ADS_Kerb' = $true
	'Netsh' = $true
	'PSR' = $true
	'xray' = $true
	'noBasicLog' = $true
	'CollectComponentLog' = $True
}

#endregion --- Scenario definitions ---
#>

#region --- Functions ---

#region --- Set-SCCMVariables ---
function Set-SCCMVariables {
	# this function is used to set global variables for SCCM module
	# and to check which SCCM components are installed on the machine
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)"

	# Global Variables
	##########################################
	LogInfo 'Setting Global variables...' DarkGreen

	# Get Current Time
	Set-Variable -Name CurrentTime -Scope Global
	$Temp = Get-CimInstance -Namespace 'root\cimv2' -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
	if ($Temp -is [CimInstance]) {
		$global:CurrentTime = ($Temp.LocalDateTime).ToString()
		$Temp = Get-CimInstance -Namespace 'root\cimv2' -Class Win32_TimeZone -ErrorAction SilentlyContinue
		if ($Temp -is [CimInstance]) {
			$global:CurrentTime += " $($Temp.Description)"
			if ((Get-Date).IsDayLightSavingTime()) {
				$global:CurrentTime += ' - Daylight Saving Time'
			}
		}
	}
	else {
		$global:CurrentTime = Get-Date -Format G
	}

	# Variables
	##########################################
	Set-Variable -Name ComputerName -Value "$ENV:COMPUTERNAME" -Scope Global
	Set-Variable -Name SiteServerFQDN -Value ([System.Net.Dns]::GetHostByName(($ComputerName)).HostName) -Scope Global -ErrorAction SilentlyContinue
	Set-Variable -Name windir -Value "$Env:windir" -Scope Global
	Set-Variable -Name ProgFiles64 -Value "$ENV:ProgramFiles" -Scope Global
	Set-Variable -Name ProgFiles86 -Value "${Env:ProgramFiles(x86)}" -Scope Global
	Set-Variable -Name system32 -Value "$($windir)\system32" -Scope Global
	Set-Variable -Name SystemRoot -Value "$Env:SystemRoot" -Scope	Global
	Set-Variable -Name OS -Value (Get-CimInstance Win32_OperatingSystem) -Scope Global -ErrorAction SilentlyContinue

	# Remote Execution Status
	Set-Variable -Name RemoteStatus -Scope Global

	# Set Software\Microsoft Registry Key path
	Set-Variable -Name Reg_MS -Value 'HKLM\SOFTWARE\Microsoft' -Scope Global
	Set-Variable -Name Reg_MS6432 -Value 'HKLM\SOFTWARE\Wow6432Node\Microsoft' -Scope Global

	# Set SMS, CCM and WSUS Registry Key Path
	Set-Variable -Name Reg_CCM -Value ($REG_MS + '\CCM') -Scope Global
	Set-Variable -Name Reg_SMS -Value ($REG_MS + '\SMS') -Scope Global
	Set-Variable -Name Reg_WSUS -Value 'HKLM\Software\Microsoft\Update Services' -Scope Global

	# Log Collection Variables and Flags
	Set-Variable -Name GetCCMLogs -Value $false -Scope Global
	Set-Variable -Name GetSMSLogs -Value $false -Scope Global

	# CCMLogPaths is defined as an array since CCM Log Path could be at various locations depending on Client/Role install status
	# We'll get all possible locations and parse through Get-Unique to a single value stored in CCMLogPath later since there will only be one CCM Log Location
	Set-Variable -Name CCMLogPaths -Value @() -Scope Global
	Set-Variable -Name CCMLogPath -Scope Global
	Set-Variable -Name CCMInstallDir -Scope Global
	Set-Variable -Name CCMSetupLogPath -Scope Global

	# Set Variables for Logs for CM12 Roles
	Set-Variable -Name Is_SiteSystem -Scope Global
	Set-Variable -Name SMSLogPath -Scope Global
	Set-Variable -Name AdminUILogPath -Scope Global
	Set-Variable -Name EnrollPointLogPath -Scope Global
	Set-Variable -Name EnrollProxyPointLogPath -Scope Global
	Set-Variable -Name AppCatalogLogPath -Scope Global
	Set-Variable -Name AppCatalogSvcLogPath -Scope Global
	Set-Variable -Name CRPLogPath -Scope Global
	Set-Variable -Name SMSSHVLogPath -Scope Global
	Set-Variable -Name DPLogPath -Scope Global
	Set-Variable -Name SMSProvLogPath -Scope Global
	Set-Variable -Name SQLBackupLogPathUNC -Scope Global
	Set-Variable -Name Is_SiteDatabaseServer -Scope Global
	Set-Variable -Name Is_AlwaysOn -Scope Global		#SQL AlwaysOn Availability Group used for the database

	# Site Server Globals
	Set-Variable -Name SMSInstallDir -Scope Global
	Set-Variable -Name SMSSiteCode -Scope Global
	Set-Variable -Name SiteType -Scope Global
	Set-Variable -Name SiteBuildNumber -Scope Global
	Set-Variable -Name ConfigMgrDBServer -Scope Global
	Set-Variable -Name ConfigMgrDBName -Scope Global
	Set-Variable -Name ConfigMgrDBNameNoInstance -Scope Global
	Set-Variable -Name SMSProviderServer -Scope Global
	Set-Variable -Name SMSProviderNamespace -Scope Global

	# Database Connection Globals
	Set-Variable -Name DatabaseConnection -Scope Global
	Set-Variable -Name DatabaseConnectionError -Scope Global

	# Summary Files and Objects
	###############################
	# Summary Objects
	Set-Variable -Name SummarySectionDescription -Scope Global -Value 'ConfigMgr Data Collection Summary'
	Set-Variable -Name CMClientFileSummaryPSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMClientReportSummaryPSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMServerFileSummaryPSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMServerReportSummaryPSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMDatabaseFileSummaryPSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMDatabaseReportSummaryPSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMDatabaseQuerySummaryPSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMRolesStatusFilePSObject -Scope Global -Value (New-Object PSObject)
	Set-Variable -Name CMInstalledRolesStatusReportPSObject -Scope Global -Value (New-Object PSObject)

	# Start Execution
	#####################
	# Print Variable values
	$global:OSArchitecture = Get-ComputerArchitecture
	LogInfoFile "Global Variable - SiteServerFQDN: $SiteServerFQDN" -ShowMsg
	LogInfoFile "Global Variable - OSArchitecture: $OSArchitecture" -ShowMsg
	LogInfoFile "Global Variable - Reg_SMS: $Reg_SMS"-ShowMsg
	LogInfoFile "Global Variable - Reg_CCM: $Reg_CCM"-ShowMsg
	LogInfoFile "Global Variable - Reg_WSUS: $Reg_WSUS"-ShowMsg

	# --------------------------------------------------------------------------------------------
	# Get Remote Execution Status from Get-TSRemote. The following return values can be returned:
	#    0 - No TS_Remote environment
	#    1 - Under TS_Remote environment, but running on the local machine
	#    2 - Under TS_Remote environment and running on a remote machine
	# --------------------------------------------------------------------------------------------
	$global:RemoteStatus = (Get-TSRemote)
	LogInfoFile "Global Remote Execution Status: $RemoteStatus"-ShowMsg

	# -----------------------
	# Set CCM Setup Log Path
	# -----------------------
	$global:CCMSetupLogPath = Join-Path $Env:windir 'ccmsetup'
	LogInfoFile "Global Variable - CCMSetupLogPath: $CCMSetupLogPath"-ShowMsg

	# ---------------------------------
	# Set Site System Global Variables
	# ---------------------------------
	#$InstalledRolesStatus = New-Object PSObject # For Update-DiagReport
	#$RolesStatus = New-Object PSObject
	$RolesArray = @{
		'Client'                   = 'Configuration Manager Client'
		'SiteServer'               = 'Configuration Manager Site Server'
		'SMSProv'                  = 'SMS Provider Server'
		'AdminUI'                  = 'Configuration Manager Admin Console'
		'AWEBSVC'                  = 'Application Catalog Web Service Point'
		'PORTALWEB'                = 'Application Catalog Website Point'
		'AIUS'                     = 'Asset Intelligence Synchronization Point'
		'AMTSP'                    = 'Out of Band Service Point'
		'CRP'                      = 'Certificate Registration Point'
		'DP'                       = 'Distribution Point'
		'DWSS'                     = 'Data Warehouse Service Point'
		'ENROLLSRV'                = 'Enrollment Point'
		'ENROLLWEB'                = 'Enrollment Proxy Point'
		'EP'                       = 'Endpoint Protection Point'
		'FSP'                      = 'Fallback Status Point'
		'IIS'                      = 'IIS Web Server'
		'MCS'                      = 'Distribution Point - Multicast Enabled'
		'MP'                       = 'Management Point'
		'PullDP'                   = 'Distribution Point - Pull Distribution Point'
		'PXE'                      = 'Distribution Point - PXE Enabled'
		'SMS_SERVICE_CONNECTOR'    = 'Service Connection Point'
		'SiteDatabaseServer'      = 'Site Database Server'
		'SMP'                      = 'State Migration Point'
		'SMS_CLOUD_PROXYCONNECTOR' = 'CMG Connection Point'
		'SMSSHV'                   = 'System Health Validator Point'
		'SRSRP'                    = 'Reporting Services Point'
		'WSUS'                     = 'Software Update Point'
	}

	foreach ($Role in ($RolesArray.Keys | Sort-Object)) {
		Switch ($Role) {
			'Client' {
				$Installed = Check-RegValueExists ($Reg_SMS + '\Mobile Client') 'ProductVersion'
				if ($Installed) {
					$global:GetCCMLogs = $true
					$global:CCMLogPaths += (Get-RegValue ($Reg_CCM + '\Logging\@Global') 'LogDirectory') + '\'
				}
			}

			'SiteServer' {
				$Installed = Check-RegValueExists ($Reg_SMS + '\Setup') 'Full Version'
				if ($Installed) {
					$global:GetSMSLogs = $true ; $global:Is_SiteSystem = $true
				}
			}

			'SMSProv' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\Providers')
				if ($Installed) {
					$global:SMSProvLogPath = (Get-RegValue ($Reg_SMS + '\Providers') 'Logging Directory')
				}
			}

			'AdminUI' {
				$Installed = Check-RegKeyExists ($Reg_MS6432 + '\ConfigMgr10\AdminUI')
				if ($Installed) { $global:AdminUILogPath = (Get-RegValue ($Reg_MS6432 + '\ConfigMgr10\AdminUI') 'AdminUILog') }
			}

			'AWEBSVC' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:AppCatalogSvcLogPath = (Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging') 'AdminUILog')
					$global:Is_SiteSystem = $true
				}
			}

			'PORTALWEB' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:AppCatalogLogPath = (Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging') 'AdminUILog')
					$global:Is_SiteSystem = $true
				}
			}

			'AIUS' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:GetSMSLogs = $true ; $global:Is_SiteSystem = $true
				}
			}

			'AMTSP' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:GetSMSLogs = $true ; $global:Is_SiteSystem = $true
				}
			}

			'CRP' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:CRPLogPath = (Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging') 'AdminUILog')
					$global:Is_SiteSystem = $true
				}
			}

			'DP' {
				$Installed = Check-RegValueExists ($Reg_SMS + '\' + $Role) 'NALPath'
				if ($Installed) {
					$global:GetSMSLogs = $true ; $global:Is_SiteSystem = $true
				}
			}

			'ENROLLSRV' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:EnrollPointLogPath = (Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging') 'AdminUILog')
					$global:Is_SiteSystem = $true
				}
			}

			'ENROLLWEB' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:EnrollProxyPointLogPath = (Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging') 'AdminUILog')
					$global:Is_SiteSystem = $true
				}
			}

			'EP' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\Operations Management\Components\SMS_ENDPOINT_PROTECTION_CONTROL_MANAGER')
			}

			'FSP' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:GetCCMLogs = $true ; $global:GetSMSLogs = $true
					$global:CCMLogPaths += Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging\@Global') 'LogDirectory'
					$global:Is_SiteSystem = $true
				}
			}


			'MCS' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:GetCCMLogs = $true ; $global:GetSMSLogs = $true
					$global:CCMLogPaths += Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging\@Global') 'LogDirectory'
					$global:Is_SiteSystem = $true
				}
			}

			'MP' {
				$Installed = Check-RegValueExists ($Reg_SMS + '\' + $Role) 'MP Hostname'
				if ($Installed) {
					$global:GetCCMLogs = $true ; $global:GetSMSLogs = $true
					$global:Is_SiteSystem = $true
					$global:CCMLogPaths += (Get-RegValue ($Reg_CCM + '\Logging\@Global') 'LogDirectory') + '\'
				}
			}

			'PullDP' {
				$Temp = Get-RegValue ($Reg_SMS + '\DP') 'IsPullDP'
				if ($Temp) { $Installed = $true } else { $Installed = $false }
				if ($Installed) {
					$GetCCMLogs = $true
					$global:Is_SiteSystem = $true
					$global:CCMLogPaths += (Get-RegValue ($Reg_CCM + '\Logging\@Global') 'LogDirectory') + '\'
				}
			}

			'PXE' {
				$Temp = Get-RegValue ($Reg_SMS + '\DP') 'IsPXE'
				if ($Temp) { $Installed = $true } else { $Installed = $false }
				if ($Installed) {
					$global:GetCCMLogs = $true ; $global:GetSMSLogs = $true
					$global:Is_SiteSystem = $true
					$global:CCMLogPaths += Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging\@Global') 'LogDirectory'
				}
			}

			# Feature 620: Add "Service Connection Point" role to list of CMRoles
			'SMS_SERVICE_CONNECTOR' {
				$Installed = ((Get-RegValue ($Reg_SMS + '\Operations Management\Components\' + $Role) 'Install State') -eq '3')
				if ($Installed) {
					$global:GetCCMLogs = $true ; $global:GetSMSLogs = $true
					$global:Is_SiteSystem = $true
				}
			}

			# Feature 594: Add "Site database server" role to list of CMRoles
			'SiteDatabaseServer' {
				$Installed = Test-RegKeyExistByPattern -RegKeyBase ($Reg_SMS + "\Components") -RegKeyPattern "SMS_SITE_SQL_BACKUP"
				if ($Installed) {
					$global:GetCCMLogs = $true ; $global:GetSMSLogs = $true
					#$global:CCMLogPaths += Get-RegValue ($Reg_SMS + '\' + "\Tracing\SMS_SITE_SQL_BACKUP_$SiteServerFQDN") 'TraceFilename'
					$global:Is_SiteSystem = $true
					$global:Is_SiteDatabaseServer = $true
				}
			}

			'SMP' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$GetCCMLogs = $true ; $global:GetSMSLogs = $true
					$global:CCMLogPaths += Get-RegValue ($Reg_SMS + '\' + $Role + '\Logging\@Global') 'LogDirectory'
					$global:Is_SiteSystem = $true
				}
			}

			'SMSSHV' {
				$Installed = Check-RegKeyExists ($Reg_MS + '\' + $Role)
				if ($Installed) {
					$global:GetSMSLogs = $true
					$global:SMSSHVLogPath = (Get-RegValue ($Reg_MS + '\' + $Role + '\Logging\@Global') 'LogDirectory')
					$global:Is_SiteSystem = $true
				}
			}

			'SRSRP' {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
				if ($Installed) {
					$global:GetSMSLogs = $true ; $global:Is_SiteSystem = $true
				}
			}

			'WSUS' {
				if (Check-RegKeyExists ($Reg_SMS + '\' + $Role)) {
					$Installed = $true ; $global:GetSMSLogs = $true; $global:Is_SiteSystem = $true
				}
				elseif (Get-Service -Name 'WsusService' -ErrorAction SilentlyContinue) {
					$Installed = $true
					# Modify the element
					LogInfoFile "Standalone WSUS found" -ShowMsg
					$RolesArray['WSUS'] = 'Standalone WSUS'
				}
			}

			Default {
				$Installed = Check-RegKeyExists ($Reg_SMS + '\' + $Role)
			}
		}

		# Set a Variable for each Role and it's Install Status
		#TODO: Fix this - it is extremely opaque and makes finding where variables are set more difficult. It also makes it difficult to see what roles are installed.
		Set-Variable -Name ('Is_' + $Role) -Value $Installed -Scope Global
		Add-Member -InputObject $global:CMRolesStatusFilePSObject -MemberType NoteProperty -Name ($RolesArray.Get_Item($Role)) -Value (Get-Variable ('Is_' + $Role) -ValueOnly)
		LogInfoFile ('Global Role Variable - Is_' + $Role + ': ' + (Get-Variable ('Is_' + $Role) -ValueOnly)) -ShowMsg

		if ($Installed) {
			Add-Member -InputObject $global:CMInstalledRolesStatusReportPSObject -MemberType NoteProperty -Name ($RolesArray.Item($Role)) -Value (Get-Variable ('Is_' + $Role) -ValueOnly)
		}
	}

	#SiteSystem isn't a role, but it's a global variable that is set to true if any of the roles are installed
	LogInfoFile ("Global Role Variable - Is_SiteSystem: $Is_SiteSystem") -ShowMsg

	# Mark IIS installed, if WSUS is installed on CAS, since SMS\IIS registry is not set on CAS
	if ($global:Is_WSUS) {
		$global:Is_IIS = $true
	}

	# -----------------------------------------------------------------------------------------------------------------------------
	# Parse CCMLogPaths, and get a unique path
	# To handle collection of CCM Logs even if Client is not installed, but a Role is installed which stores logs in CCM directory
	# -----------------------------------------------------------------------------------------------------------------------------
	$global:CCMLogPath = $CCMLogPaths | Sort-Object | Get-Unique

	# Error Handling if Get-RegValue failed to obtain a valid CCMLogPath and returned null instead
	if (($CCMLogPath -eq '\') -or ($null -eq $CCMLogPath)) {
		$CCMLogPath = $null
		if ($GetCCMLogs) {
			LogWarn 'ERROR: CCM Logs need to be collected but CCM Directory not found.'
		}
		else {
			LogWarn 'WARNING: GetCCMLogs is set to False. CCM Log Path Not Required.'
		}
	}
	else {
		$global:CCMInstallDir = $global:CCMLogPath.Substring(0, $CCMLogPath.LastIndexOf('\Logs'))
		LogInfoFile "Global Variable - CCMInstallDir: $CCMInstallDir" -ShowMsg
		LogInfoFile "Global Variable - CCMLogPath: $CCMLogPath" -ShowMsg
	}

	if ($Is_Client) {
		Set-Variable -Name Is_Lantern -Scope Global -Value $true
		Set-Variable -Name LanternLogPath -Scope Global
		$global:LanternLogPath = Join-Path (Get-RegValue ($Reg_MS + '\PolicyPlatform\Client\Trace') 'LogDir') (Get-RegValue ($Reg_MS + '\PolicyPlatform\Client\Trace') 'LogFile')
		LogInfoFile "Global Variable - LanternLogPath: $global:LanternLogPath" -ShowMsg
	}

	# -----------------------------
	# Get SMSLogPath from Registry
	# -----------------------------
	if ($GetSMSLogs) {
		$global:SMSInstallDir = (Get-RegValue ($Reg_SMS + '\Identification') 'Installation Directory')

		if ($null -ne $SMSInstallDir) {
			$global:SMSLogPath = $global:SMSInstallDir + '\Logs'
			LogInfoFile "Global Variable - SMSInstallDir: $SMSInstallDir" -ShowMsg
			LogInfoFile "Global Variable - SMSLogPath: $SMSLogPath" -ShowMsg
		}
		else {
			$global:SMSLogPath = $null
			LogWarn 'ERROR: SMS Logs need to be collected but SMS Install Directory not Found'
		}
	}

	# -------------------------------
	# Get Site Server Info From Registry
	# -------------------------------
	if ($Is_SiteServer) {
		# Database Server and name
		$global:ConfigMgrDBServer = Get-RegValue ($Reg_SMS + '\SQL Server\Site System SQL Account') 'Server'			# Stored as FQDN
		$global:ConfigMgrDBName = Get-RegValue ($Reg_SMS + '\SQL Server\Site System SQL Account') 'Database Name'		# Stored as INSTANCE\DBNAME or just DBNAME if on Default instance

		# Get the database name without the Instance Name
		if ($global:ConfigMgrDBName.Contains('\')) {
			$global:ConfigMgrDBNameNoInstance = $global:ConfigMgrDBName.Substring($global:ConfigMgrDBName.IndexOf('\') + 1)
		}
		else {
			$global:ConfigMgrDBNameNoInstance = $global:ConfigMgrDBName
		}

		# Get Database connection.
		# if connection fails, DatabaseConnectionError will have the error. if connection is successful, DatabaseConnectionError will be $null.
		# Connection is closed in FinishExecution
		$global:DatabaseConnection = Get-DBConnection -DatabaseServer $ConfigMgrDBServer -DatabaseName $ConfigMgrDBName

		# Site Type
		$global:SiteType = Get-RegValue ($Reg_SMS + '\Setup') 'Type'
		$global:SiteBuildNumber = Get-RegValue ($Reg_SMS + '\Setup') 'Version'
		$global:Is_AlwaysOn = Get-RegValue ($Reg_SMS + '\SQL Server') 'Availability Group'

		# Site Code and Provider Namespace
		$global:SMSProviderServer = Get-RegValue ($Reg_SMS + '\Setup') 'Provider Location'
		$global:SMSSiteCode = Get-RegValue ($Reg_SMS + '\Identification') 'Site Code'
		if (($null -ne $global:SMSSiteCode) -and ($null -ne $global:SMSProviderServer)) {
			$global:SMSProviderNamespace = "root\sms\site_$SMSSiteCode"

		LogInfoFile "Global Variable - SiteType: $SiteType" -ShowMsg
		LogInfoFile "Global Variable - ConfigMgrDBServer: $ConfigMgrDBServer" -ShowMsg
		LogInfoFile "Global Variable - ConfigMgrDBName: $ConfigMgrDBName" -ShowMsg
		}
	}
	elseif (($false -eq $Is_SiteServer) -and ($Is_SiteDatabaseServer -and $Is_SiteSystem))	{
		# This is not a Site Server (CAS, primary, or secondary), but it is a Site System and has a Site Database Server role
		# There will be nothing in the registry to have populated either $global:ConfiMgrDBServer or $global:ConfiMgrDBName, so set them here.
		$global:ConfigMgrDBServer = $SiteServerFQDN
		$global:ConfigMgrDBName = $null			#We don't know the database name or even where it is because there is nothing in the registry, named instance?, so set it to null.
		$global:DatabaseConnection = $null 		#We dont't know the database name because there is nothing in the registry, so set the connection to null

		# Find the SMS_SITE_SQL_BACKUP tracing key - it is the in the format of SMS_SITE_SQL_BACKUP_<SiteServerFQDN>, so we can't just use the computer name, because the site server is remote and has a different name
		$Key = Get-ChildItem -Path "HKLM:\Software\Microsoft\SMS\Tracing" | Where-Object { $_.Name -like "*SMS_SITE_SQL_BACKUP_*" }
		if ($null -ne $Key) {
			if ($Key -isnot [Array]) { #TODO: We should implement logic to handle multiple SMS_SITE_SQL_BACKUP_<SiteServerFQDN> keys
				$SQLBackupLogPath = $Key.GetValue('TraceFileName')
				$global:SQLBackupLogPathUNC = $SQLBackupLogPath -replace ':', '$'
				$global:SQLBackupLogPathUNC = "\\$ConfigMgrDBServer\$global:SQLBackupLogPathUNC"
				$global:SQLBackupLogPathUNC = Split-Path $global:SQLBackupLogPathUNC
				LogInfoFile "Global Variable - ConfigMgrDBServer: $ConfigMgrDBServer" -ShowMsg
				LogInfoFile "Global Variable - SQLBackupLogPathUNC: $global:SQLBackupLogPathUNC" -ShowMsg
			}
		}
	}

	if ($Is_SiteSystem) {
		# Feature 558: Collect ConfigMgr Server Archived Logs, if present.
		# Site Server Logs archive settings - Is logs archive enabled?
		$global:ConfigMgrServerLogsArchiveEnabled = Get-RegValue ($Reg_SMS + '\Tracing') 'ArchiveEnabled'
		LogInfoFile "Global Variable - ConfigMgrServerLogsArchive: $global:ConfigMgrServerLogsArchiveEnabled" -ShowMsg
		if ($global:ConfigMgrServerLogsArchiveEnabled -eq '1') {
			# Get archive path
			$global:ConfigMgrServerLogsArchivePath = Get-RegValue ($Reg_SMS + '\Tracing') 'ArchivePath'
            LogInfoFile "Global Variable - ConfigMgrServerLogsArchive: $global:ConfigMgrServerLogsArchivePath" -ShowMsg
		}
	}


	# --------------------------------------------------------------------------------------------------------------------------
	# Set WSUS Install Directory, if WSUS is installed.
	# Execute WSUSutil checkhealth. Running it now would ensure that it's finished by the time we collect Event Logs
	# Fails to run remotely, because it runs under Anonymous. Using psexec to execute, to ensure that it runs remotely as well.
	# --------------------------------------------------------------------------------------------------------------------------
	if ($Is_WSUS) {
		$global:WSUSInstallDir = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'TargetDir'

		if ($null -ne $global:WSUSInstallDir) {
			LogInfoFile "Global Variable - WSUSInstallDir: $global:WSUSInstallDir" -ShowMsg
			LogInfo 'Running WSUSutil.exe checkhealth...'
			$Commands = @(
				"cmd /r `"$global:ScriptFolder\BIN\PsExec.exe`" -accepteula -nobanner -s `"$($global:WSUSInstallDir)Tools\WSUSutil.exe`" checkhealth | Out-File -Append $($Prefix)WSUSutil_checkhealth.txt"
			)
			RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
		}
		else {
			LogWarn 'ERROR: WSUS Role detected but WSUS Install Directory not found'
			LogWarn 'WSUS related data will not be collected'
			$global:Is_WSUS = $false
		}
	}

	# -----------------------------------------------------------------------
	# Get DP Logs Directory, if DP is installed and remote from Site Server.
	# -----------------------------------------------------------------------
	if ($Is_DP) {
			$global:DPLogPath = (Get-CimInstance Win32_Share -Filter "Name LIKE 'SMS_DP$'").path + '\sms\Logs'
			LogInfoFile "Global Variable - DPLogPath = $DPLogPath" -ShowMsg
	}

	# ----------------------
	# Remove Temp Variables
	# ----------------------
	Remove-Variable -Name Role
	Remove-Variable -Name Installed

	LogInfo 'Completed initializing SCCM variables.' DarkGreen
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Set-SCCMVariables ---

#region --- Function Get-SCCMBasicSystemInfo ---
function Get-SCCMBasicSystemInfo {
	param ( $MachineName = $null )

	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	if ($null -ne $MachineName) {
		if ($ComputerName -eq $MachineName) {
			$MachineName = '.'
		}
	}
	else {
		#$AddToHeader = ""
		$MachineName = '.'
	}

	# set variables
	$LogPrefix = 'BasicInfo'
	$UACAdminMode = 'Admin Mode'
	$UACNoPrompt = 'No Prompt'
	$UACPromptCredentials = 'Prompt for credentials'
	$UACPromptConsent = 'Prompt for consent'
	$UACPromptConsentApp = 'Prompt for consent when programs make changes'
	$UAC = 'User Account Control'
	$OS_Summary = New-Object PSObject	# Operating System Summary
	$CS_Summary = New-Object PSObject	# Computer System Summary
	$WMIOS = $null

	$WMIOS = Get-CimInstance -class 'win32_operatingsystem' -ErrorAction SilentlyContinue
	# Get all data from WMI

	if ($null -ne $WMIOS) {
		#if WMIOS is null - means connection failed. Abort script execution.

		$WMICS = Get-CimInstance -Class 'win32_computersystem'
		$WMIProcessor = Get-CimInstance -Class 'Win32_processor'
		$OSProcessorArch = $WMIOS.OSArchitecture
		$OSProcessorArchDisplay = ' ' + $OSProcessorArch
		#There is no easy way to detect the OS Architecture on pre-Windows Vista Platform
		if ($null -eq $OSProcessorArch) {
			$OSProcessorArch = $Env:PROCESSOR_ARCHITECTURE
		}
	}

	# Build OS Summary
	# Name
	Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'Machine Name' -Value $WMIOS.CSName
	Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'OS Name' -Value ($WMIOS.Caption + ' Service Pack ' + $WMIOS.ServicePackMajorVersion + $OSProcessorArchDisplay)
	Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'Build' -Value ($WMIOS.Version)
	Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'Time Zone/Offset' -Value (Replace-XMLChars -RAWString ((Get-CimInstance -Class Win32_TimeZone).Caption + '/' + $WMIOS.CurrentTimeZone))

	# Install Date
	# $date = [DateTime]::ParseExact($wmios.InstallDate.Substring(0, 8), "yyyyMdd", $null)
	# Add-Member -inputobject $OS_Summary -membertype noteproperty -name "Install Date" -value $date.ToShortDateString()
	Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'Last Reboot/Uptime' -Value (($WMIOS.LastBootUpTime).ToString() + ' (' + (GetAgeDescription(New-TimeSpan $WMIOS.LastBootUpTime)) + ')')

	# Build Computer System Summary
	# Name
	Add-Member -InputObject $CS_Summary -MemberType noteproperty -Name 'Computer Model' -Value ($WMICS.Manufacturer + ' ' + $WMICS.model)

	$numProcs = 0
	#$ProcessorType = ""
	$ProcessorName = ''
	$ProcessorDisplayName = ''

	foreach ($WMIProc in $WMIProcessor) {
		#$ProcessorType = $WMIProc.manufacturer
		switch ($WMIProc.NumberOfCores) {
			1 { $numberOfCores = 'single core' }
			2 { $numberOfCores = 'dual core' }
			4 { $numberOfCores = 'quad core' }
			$null { $numberOfCores = 'single core' }
			default { $numberOfCores = $WMIProc.NumberOfCores.ToString() + ' core' }
		}

		switch ($WMIProc.Architecture) {
			0 { $CpuArchitecture = 'x86' }
			1 { $CpuArchitecture = 'MIPS' }
			2 { $CpuArchitecture = 'Alpha' }
			3 { $CpuArchitecture = 'PowerPC' }
			6 { $CpuArchitecture = 'Itanium' }
			9 { $CpuArchitecture = 'x64' }
		}

		if ($ProcessorDisplayName.Length -eq 0) {
			$ProcessorDisplayName = ' ' + $numberOfCores + " $CpuArchitecture processor " + $WMIProc.name
		}
		else {
			if ($ProcessorName -ne $WMIProc.name) {
				$ProcessorDisplayName += '/ ' + ' ' + $numberOfCores + " $CpuArchitecture processor " + $WMIProc.name
			}
		}
		$numProcs += 1
		$ProcessorName = $WMIProc.name
	}
	$ProcessorDisplayName = "$numProcs" + $ProcessorDisplayName

	Add-Member -InputObject $CS_Summary -MemberType noteproperty -Name 'Processor(s)' -Value $ProcessorDisplayName

	if ($null -ne $WMICS.Domain) {
		Add-Member -InputObject $CS_Summary -MemberType noteproperty -Name 'Machine Domain' -Value $WMICS.Domain
	}

	if ($null -ne $WMICS.DomainRole) {
		switch ($WMICS.DomainRole) {
			0 { $RoleDisplay = 'Workstation' }
			1 { $RoleDisplay = 'Member Workstation' }
			2 { $RoleDisplay = 'Standalone Server' }
			3 { $RoleDisplay = 'Member Server' }
			4 { $RoleDisplay = 'Backup Domain Controller' }
			5 { $RoleDisplay = 'Primary Domain controller' }
		}
		Add-Member -InputObject $CS_Summary -MemberType noteproperty -Name 'Role' -Value $RoleDisplay
	}

	if ($WMIOS.ProductType -eq 1) {
		#Client
		$AntivirusProductWMI = Get-CimInstance -Query 'select companyName, displayName, versionNumber, productUptoDate, onAccessScanningEnabled FROM AntivirusProduct' -Namespace 'root\SecurityCenter'
		if ($null -ne $AntivirusProductWMI.displayName) {
			$AntivirusDisplay = $AntivirusProductWMI.companyName + ' ' + $AntivirusProductWMI.displayName + ' version ' + $AntivirusProductWMI.versionNumber
			if ($AntivirusProductWMI.onAccessScanningEnabled) {
				$AVScanEnabled = 'Enabled'
			}
			else {
				$AVScanEnabled = 'Disabled'
			}
			if ($AntivirusProductWMI.productUptoDate) {
				$AVUpToDate = 'Yes'
			}
			else {
				$AVUpToDate = 'No'
			}
			#$AntivirusStatus = "OnAccess Scan: $AVScanEnabled" + ". Up to date: $AVUpToDate"

			Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'Anti Malware' -Value $AntivirusDisplay
		}
		else {
			$AntivirusProductWMI = Get-CimInstance -Namespace root\SecurityCenter2 -Class AntiVirusProduct
			if ($null -ne $AntivirusProductWMI) {
				#$X = 0
				$Antivirus = @()
				$AntivirusProductWMI | ForEach-Object -Process {
					$ProductVersion = $null
					if ($null -ne $_.pathToSignedProductExe) {
						$AVPath = [System.Environment]::ExpandEnvironmentVariables($_.pathToSignedProductExe)
						if (($AVPath -ne $null) -and (Test-Path $AVPath)) {
							$VersionInfo = (Get-ItemProperty $AVPath).VersionInfo
							if ($null -ne $VersionInfo) {
								$ProductVersion = ' version ' + $VersionInfo.ProductVersion.ToString()
							}
						}
					}

					$Antivirus += "$($_.displayName) $ProductVersion"
				}
				if ($Antivirus.Count -gt 0) {
					Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'Anti Malware' -Value $Antivirus
				}
			}
		}
	}

	if ($MachineName -eq '.') {
		#Local Computer
		$SystemPolicies = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
		$EnableLUA = $SystemPolicies.EnableLUA
		$ConsentPromptBehaviorAdmin = $SystemPolicies.ConsentPromptBehaviorAdmin
	}
	else {
		$RemoteReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $MachineName)
		$EnableLUA = ($RemoteReg.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System')).GetValue('EnableLUA')
		$ConsentPromptBehaviorAdmin = ($RemoteReg.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System')).GetValue('ConsentPromptBehaviorAdmin')
	}

	if ($EnableLUA) {
		$UACDisplay = 'Enabled'

		switch ($ConsentPromptBehaviorAdmin) {
			0 { $UACDisplay += ' / ' + $UACAdminMode + ': ' + $UACNoPrompt }
			1 { $UACDisplay += ' / ' + $UACAdminMode + ': ' + $UACPromptCredentials }
			2 { $UACDisplay += ' / ' + $UACAdminMode + ': ' + $UACPromptConsent }
			5 { $UACDisplay += ' / ' + $UACAdminMode + ': ' + $UACPromptConsentApp }
		}
	}
	else {
		$UACDisplay = 'Disabled'
	}
	Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name $UAC -Value $UACDisplay

	if ($MachineName -eq '.') {
		#Local Computer only. Will not retrieve username from remote computers
		Add-Member -InputObject $OS_Summary -MemberType noteproperty -Name 'Username' -Value ($Env:USERDOMAIN + '\' + $Env:USERNAME)
	}

	#System Center Advisor Information
	$SCAKey = 'HKLM:\SOFTWARE\Microsoft\SystemCenterAdvisor'
	if (Test-Path($SCAKey)) {
		$CustomerID = (Get-ItemProperty -Path $SCAKey).CustomerID
		if ($null -ne $CustomerID) {
			LogInfo "System Center Advisor detected. Customer ID: $CustomerID"
			$SCA_Summary = New-Object PSObject
			$SCA_Summary | Add-Member -MemberType noteproperty -Name 'Customer ID' -Value $CustomerID
			# $SCA_Summary | ConvertTo-Xml2 | update-diagreport -id ("01_SCACustomerSummary") -name "System Center Advisor" -verbosity Informational
		}
	}
	Add-Member -InputObject $CS_Summary -MemberType NoteProperty -Name 'RAM (physical)' -Value (FormatBytes -bytes $WMICS.TotalPhysicalMemory -precision 1)

	$BasicSystemInfoFile = $Prefix + 'BasicSystemInfo.TXT'
	$sectionDescription = 'Basic System Info TXT output'
	$OS_Summary | Out-File -Append $BasicSystemInfoFile
	$CS_Summary | Out-File -Append $BasicSystemInfoFile

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMBasicSystemInfo ---


#Function to retrieve certificates from the various stores of interest to Configuration Manager 
# Parameters
# $CertificatesFile - Output filename for the certificates
function Get-SccmCertificatesFromStore {
	param (
		[Parameter(Mandatory=$true)]
    	[string]$CertificatesFile
	)

	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$CertificatesFileBase = Split-Path -Leaf $CertificatesFile

	'##############' | Out-File $CertificatesFile
	'## COMPUTER ##' | Out-File -Append $CertificatesFile
	"##############`n`n" | Out-File -Append $CertificatesFile

	'MY' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\LocalMachine\My' | Out-File -Append $CertificatesFile

	'SMS' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\LocalMachine\SMS' | Out-File -Append $CertificatesFile

	'Trusted People' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\LocalMachine\TrustedPeople' | Out-File -Append $CertificatesFile

	'Trusted Publishers' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\LocalMachine\TrustedPublisher' | Out-File -Append $CertificatesFile

	'Trusted Root CA''s' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\LocalMachine\Root' | Out-File -Append $CertificatesFile

	'Intermediate CA''s' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\LocalMachine\CA' | Out-File -Append $CertificatesFile
	
	'##############' | Out-File -Append $CertificatesFile
	'##   USER   ##' | Out-File -Append $CertificatesFile
	"##############`n`n" | Out-File -Append $CertificatesFile

	'MY' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\CurrentUser\My' | Out-File -Append $CertificatesFile

	'Trusted People' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\CurrentUser\TrustedPeople' | Out-File -Append $CertificatesFile

	'Trusted Publishers' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\CurrentUser\TrustedPublisher' | Out-File -Append $CertificatesFile

	'Trusted Root CA''s' | Out-File -Append $CertificatesFile
	'==================' | Out-File -Append $CertificatesFile
	Get-CertInfo 'Cert:\CurrentUser\Root' | Out-File -Append $CertificatesFile
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Certificates' -Value "Review $CertificatesFileBase"

	#endregion --- Certificate Information ---

	EndFunc $MyInvocation.MyCommand.Name
}

#region --- Function Get-SCCMGenericInfo ---
function Get-SCCMGenericInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	# set variables
	$LogPrefix = 'GenericInfo'
	$ComputerName = $ENV:COMPUTERNAME
	$windir = $env:windir
	$ProgFiles64 = $ENV:ProgramFiles
	$ProgFiles86 = ${env:ProgramFiles(x86)}
	$system32 = $windir + '\system32'
	$SystemRoot = $env:SystemRoot
	$OS = Get-CimInstance Win32_OperatingSystem

	# detect OS version and SKU
	try {
		LogInfo 'Get OS version and SKU.'
		$wmiOSVersion = Get-CimInstance -Namespace 'root\cimv2' -Class Win32_OperatingSystem
		[int]$bn = [int]$wmiOSVersion.BuildNumber

		$sku = $((Get-CimInstance win32_operatingsystem).OperatingSystemSKU)
		$domainRole = (Get-CimInstance -Class Win32_ComputerSystem).DomainRole	# 0 or 1: client; >1: server

		$osVerName = Get-SCCMOsVerName $bn
		LogInfo "OS is $osVerName."
		$osSkuName = Get-SCCMOsSkuName $sku
		LogInfo "$(if ($osSkuName) { 'Running' } else { 'Not running' }) on a server OS."

		$OutputFile = $Prefix + 'psSDP_DiagnosticVersion.TXT'
		"`n Diagnostic  : psSDP Diagnostic v$global:VerDate"	| Out-File -Append $OutputFile
		"Publish Date: $global:Publish_Date`n" | Out-File -Append $OutputFile
		if ($domainRole -gt 1) {
			$Server_Client = 'Server'
		}
		else {
			$Server_Client = 'Client'
		}
		"Type                         : $Server_Client" | Out-File -Append $OutputFile
		"Operating System Name        : $osVerName" | Out-File -Append $OutputFile
		"Operating System SKU         : $osSkuName" | Out-File -Append $OutputFile
		"Operating System Build Number: $bn`n`n`n" | Out-File -Append $OutputFile
		'Powershell version:' | Out-File -Append $OutputFile
		$PSVersionTable	| Format-Table -AutoSize | Out-File -Append $OutputFile
		"`n ExecutionPolicy:" | Out-File -Append $OutputFile
		Get-ExecutionPolicy -List | Out-File -Append $OutputFile

		if ($bn -gt 7600) {
			$OutputFile = $Prefix + 'Roles_Features.txt'
			LogInfo 'Evaluating OS type.'
			Get-SCCMSrvSKU | Out-Null #_#
			LogInfo 'Retrieve installed features and roles.'
			Get-SCCMSrvRole $OutputFile
		}
	}
	catch {
		LogException 'Failed to get OS version and SKU.' $_
	}

	#region --- OS summary ---
	LogInfo 'Get OS summary.'
	# Header for Client Summary File
	$OSInfoFile = $Prefix + '_OS_Summary.txt'
	'=====================================' | Out-File $OSInfoFile
	'Operating System Information Summary:' | Out-File -Append $OSInfoFile
	'=====================================' | Out-File -Append $OSInfoFile

	# PSObject to store Client information
	$OSInfo = New-Object PSObject

	# Computer Name
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Computer Name' -Value $ComputerName

	# OS information:
	$OSInfoTemp = Get-CimInstance -Namespace root\cimv2 -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
	if ($OSInfoTemp -is [CimInstance]) {
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Operating System' -Value $OSInfoTemp.Caption
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Service Pack' -Value $OSInfoTemp.CSDVersion
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Version' -Value $OSInfoTemp.Version
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Architecture' -Value $OSInfoTemp.OSArchitecture
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Last Boot Up Time' -Value $OSInfoTemp.LastBootUpTime
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Current Time' -Value $OSInfoTemp.LocalDateTime
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Total Physical Memory' -Value ([string]([math]::round($($OSInfoTemp.TotalVisibleMemorySize / 1MB), 2)) + ' GB')
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Free Physical Memory' -Value ([string]([math]::round($($OSInfoTemp.FreePhysicalMemory / 1MB), 2)) + ' GB')
	}
	else {
		LogException 'Error obtaining data from Win32_OperatingSystem WMI Class' $_
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'OS Details' -Value 'Error obtaining data from Win32_OperatingSystem WMI Class'
	}

	# Computer System Information:
	$OSInfoTemp = Get-CimInstance -Namespace root\cimv2 -Class Win32_TimeZone -ErrorAction SilentlyContinue
	if ($OSInfoTemp -is [CimInstance]) {
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Time Zone' -Value $OSInfoTemp.Description
	}
	else {
		LogException 'Error obtaining value from Win32_TimeZone WMI Class' $_
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Time Zone' -Value 'Error obtaining value from Win32_TimeZone WMI Class'
	}

	$OSInfoTemp = Get-CimInstance -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
	if ($OSInfoTemp -is [CimInstance]) {
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Daylight In Effect' -Value $OSInfoTemp.DaylightInEffect
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Domain' -Value $OSInfoTemp.Domain
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Model' -Value $OSInfoTemp.Model
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Number of Processors' -Value $OSInfoTemp.NumberOfProcessors
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Number of Logical Processors' -Value $OSInfoTemp.NumberOfLogicalProcessors
	}
	else {
		LogException 'Error obtaining value from Win32_ComputerSystem WMI Class' $_
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Computer System Details' -Value 'Error obtaining value from Win32_ComputerSystem WMI Class'
	}
	#endregion --- OS summary ---

    # SleepStudy Report
	if ($script:ActionsToSkip -notcontains 'SleepStudy') {
		LogInfo "Get SleepStudy report (if available)."
		$Commands = @(
			"cmd /c powercfg /sleepstudy /duration 7 /output $($Prefix)OS_SleepStudy.html"
		)
		RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	}

	#region --- WhoAmI ---
	LogInfo 'Get WhoAmI.'
	# Get WhoAmI.exe output
	$WhoAmIFile = $Prefix + 'OS_WhoAmI.txt'
	$WhoAmIFileBase = Split-Path -Leaf $WhoAmIFile

	# Can't use the framework function 'FwGetWhoAmI' because it doesn't take a file name
	# FwGetWhoAmI -Subfolder "SCCM_Report$LogSuffix"
	$Commands = @(
		"cmd.exe /c whoami.exe -all | Out-File -Append $WhoAmIFile"
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'WhoAmI Output' -Value "Review $WhoAmIFileBase"
	)
	RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	#endregion --- WhoAmI ---

	#region --- SystemInfo ---
	LogInfo 'Get SystemInfo.'
	# Get SystemInfo.exe output
	$SysInfoFile = $Prefix + 'OS_SysInfo.txt'
	$SysInfoFileBase = Split-Path -Leaf $SysInfoFile

	# Can't use the framework function 'FwGetSysInfo' because it doesn't take a file name
	# FwGetSysInfo -Subfolder "SCCM_Report$LogSuffix"
	$Commands = @(
		"cmd.exe /c SystemInfo.exe | Out-File -Append $SysInfoFile"
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'SysInfo Output' -Value "Review $SysInfoFileBase"
	)
	RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	#endregion --- SystemInfo ---

	#region --- Processes and Services ---
	LogInfo 'Get Processes and Services.'
	#TODO: tasklist output is collected multiple times in this script
	# Get Running Tasks List
	$TaskListFile = $Prefix + 'OS_TaskList.txt'
	$TaskListFileBase = Split-Path -Leaf $TaskListFile

	$Commands = @(
		"cmd.exe /c TaskList.exe /v /FO TABLE	| Out-File -Append $TaskListFile"
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Running Tasks List' -Value "Review $TaskListFileBase"
	)
	RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	#endregion --- Processes and Services ---

	#region --- Services Status ---
	LogInfo 'Get Services Status.'
	$ServicesFile = $Prefix + 'OS_Services.txt'
	$ServicesFileBase = Split-Path -Leaf $ServicesFile
	$ServicesTemp = Get-CimInstance Win32_Service -ErrorVariable WMIError -ErrorAction SilentlyContinue | Select-Object DisplayName, Name, State, @{name = 'Log on As'; expression = { $_.StartName } }, StartMode | `
		Sort-Object DisplayName | `
		Format-Table -AutoSize
	if ($WMIError.Count -eq 0) {
		$ServicesTemp | Out-File $ServicesFile -Width 1000
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Services Status' -Value "Review $ServicesFileBase"
	}
	else {
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Services Status' -Value "Error obtaining Services Status: $WMIError[0].Exception.Message"
		$WMIError.Clear()
	}
	#endregion --- Services Status ---

	#region ---FLTMC ouptut ---
	FwGetFltMcInfo -noSplit -Subfolder "SCCM_Report$LogSuffix" -FilePrefix "$($env:COMPUTERNAME)_OS"
	#endregion ---FLTMC ouptut ---

	#region --- MSInfo ---
	if ($script:ActionsToSkip -notcontains 'msinfo32') {
		if ($global:beta) { 
			LogInfo $(OutputWaitforResult "msinfo32")
		}
		else {
			LogInfo 'Start MSInfo and continue, we''ll wait later for it to end.'
		}
		$MSInfoFile = $Prefix + 'OS_MSInfo.NFO'
		$MSInfoFileBase = Split-Path -Leaf $MSInfoFile
		# Instead of msinfo32.exe consider PS command: Get-ComputerInfo
		# Can't use the framework function 'FwGetMsInfo32' because it doesn't take a file name
		# FwGetMsInfo32 -Subfolder "SCCM_Report$LogSuffix"
		<#
		$Commands = @(
			"cmd.exe /c start /wait MSInfo32.exe /nfo $MSInfoFile"
			Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'MSInfo Output' -Value "Review $MSInfoFileBase"
		)
		RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
		#>
		#$script:msinfo32NFO = Start-Process -FilePath 'msinfo32' -ArgumentList " /nfo `"$MSInfoFile`"" -PassThru
		# we should run msinfo32 in session 0 to hiden the window, but fall back to direct call if PsExec is not available
		try {
			$script:msinfo32NFO = Start-Process -FilePath "$global:ScriptFolder\BIN\PsExec.exe" -ArgumentList "-accepteula -nobanner -s msinfo32 /nfo `"$MSInfoFile`"" `
				-PassThru -WindowStyle Hidden -ErrorAction stop
		}
		catch {
			LogInfo 'PsExec could not be executed - falling back to direct call to msinfo32.'
			$script:msinfo32NFO = Start-Process -FilePath 'msinfo32' -ArgumentList " /nfo `"$MSInfoFile`"" -PassThru
		}
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'MSInfo Output' -Value "Review $MSInfoFileBase"
	}
	#endregion --- MSInfo ---

	#region --- GPResult ---
	if ($script:ActionsToSkip -notcontains 'gpresult') {
		LogInfo 'Get GPResult output.'
		$OutputFileZ = $Prefix + 'OS_GPResult_Computer.txt'
		$OutputFileZBase = Split-Path -Leaf $OutputFileZ
		$timeout = 120  # 2 minutes
		$startTime = Get-Date
		LogInfo "Wait for a maximum of $($timeout/60) minutes before continuing." White
		$script:GPresultFileZ = Start-Process -FilePath 'gpresult' -ArgumentList '/Z /SCOPE COMPUTER' -NoNewWindow -Wait -RedirectStandardOutput $OutputFileZ
		while ($script:GPresultFileZ.HasExited -eq $false -and ((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
			# Wait for a short duration before checking again
			Start-Sleep -Milliseconds 500
		}
		# Check if the process is still running after the timeout
		if ($script:GPresultFileZ.HasExited -eq $false) {
			# Terminate the process forcibly
			Stop-Process -Id $global:GPresultProcess.Id -Force
			Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'GPResult /Z Output /SCOPE COMPUTER' -Value "Timeout reached: The process did not finish within $($timeout/60) minutes."
		}
		else {
			Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'GPResult /Z Output /SCOPE COMPUTER' -Value "Review $OutputFileZBase"
		}

		if ($OSVersion.Major -ge 6) {
			$OutputFileH = $Prefix + 'OS_GPResult_Computer.htm'
			$OutputFileHBase = Split-Path -Leaf $OutputFileH
			$script:GPresultFileH = Start-Process -FilePath 'gpresult' -ArgumentList "/SCOPE COMPUTER /H $OutputFileH" -PassThru -WindowStyle Hidden
			Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'GPResult /SCOPE COMPUTER /H Output' -Value "Review $OutputFileHBase"
		}

		$startTime = Get-Date
		$OutputFileZ = $Prefix + 'OS_GPResult_User.txt'
		$OutputFileZBase = Split-Path -Leaf $OutputFileZ
		LogInfo "Wait for a maximum of $($timeout/60) minutes before continuing." White
		$script:GPresultFileZ = Start-Process -FilePath 'gpresult' -ArgumentList '/Z /SCOPE USER' -NoNewWindow -Wait -RedirectStandardOutput $OutputFileZ
		while ($script:GPresultFileZ.HasExited -eq $false -and ((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
			# Wait for a short duration before checking again
			Start-Sleep -Milliseconds 500
		}
		# Check if the process is still running after the timeout
		if ($script:GPresultFileZ.HasExited -eq $false) {
			# Terminate the process forcibly
			Stop-Process -Id $global:GPresultProcess.Id -Force
			Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'GPResult /Z Output /SCOPE USER' -Value "Timeout reached: The process did not finish within $($timeout/60) minutes."
		}
		else {
			Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'GPResult /Z Output /SCOPE USER' -Value "Review $OutputFileZBase"
		}
	}
	#endregion --- GPResult ---

	#region --- Environment Variables ---
	LogInfo 'Get environment variables.'
	$EnvironmentFile = $Prefix + 'OS_EnvironmentVariables.txt'
	$EnvironmentFileBase = Split-Path -Leaf $EnvironmentFile
	'-----------------' | Out-File $EnvironmentFile
	'SYSTEM VARIABLES' | Out-File -Append $EnvironmentFile
	"-----------------`n" | Out-File -Append $EnvironmentFile
	[environment]::GetEnvironmentVariables('Machine') | Out-File -Append $EnvironmentFile -Width 250
	'-----------------' | Out-File -Append $EnvironmentFile
	'USER VARIABLES' | Out-File -Append $EnvironmentFile
	'-----------------' | Out-File -Append $EnvironmentFile
	[environment]::GetEnvironmentVariables('User') | Out-File -Append $EnvironmentFile -Width 250
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Environment Variables' -Value "Review $EnvironmentFileBase"
	#endregion --- Environment Variables ---

	#region --- Pending Reboot ---
	LogInfo 'Determining if reboot is pending.'
	$RebootPendingFile = $Prefix + 'OS_RebootPending.txt'
	$RebootPendingFileBase = Split-Path -Leaf $RebootPendingFile
	Get-PendingReboot -ComputerName $ComputerName | Out-File $RebootPendingFile
	Add-Member -InputObject $OSInfoFile -MemberType NoteProperty -Name 'Reboot Pending' -Value "Review $RebootPendingFileBase"
	#endregion --- Pending Reboot ---

	#region --- Event Logs ---
	LogInfo 'Getting Event Logs.'
	#$EventLogsDestinationPath = "$OSInfoTempDir\OS_EventLogs"
	#$EventLogsZipFile = $EventLogsDestinationPath + '.zip'
	$EventLogsDestinationPath = $Prefix + 'OS_EventLogs'
	$EventLogsZipFile = $Prefix + 'OS_EventLogs.zip'
	FwCreateFolder $EventLogsDestinationPath
	# Copy files directly, it's much much faster this way. User can convert to TXT or CSV offline, as needed.
	# Feature 675: Additional event logs in SCCM scenario
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$system32\winevt\logs\Application.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-AAD%4Operational.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-Bits-Client%4Operational.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-BranchCache%4Operational.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-BranchCacheSMB%4Operational.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider%4Admin.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider%4Autopilot.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider%4Operational.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-Windows Defender%4Operational.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-Windows Defender%4WHC.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-WindowsUpdateClient%4Operational.evtx", $EventLogsDestinationPath),
		#@("$system32\winevt\logs\Microsoft-Windows-WMI-Activity%4Operational.evtx", $EventLogsDestinationPath),
		@("$system32\winevt\logs\System.evtx", $EventLogsDestinationPath),
		@("$system32\winevt\logs\Security.evtx", $EventLogsDestinationPath),
		@("$system32\winevt\logs\Setup.evtx", $EventLogsDestinationPath)
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$True

	# Compress the destination folder into a ZIP file
	try {
		LogInfo "Compressing $EventLogsDestinationPath"
		# Compress-Archive -Path "$EventLogsDestinationPath\*.*" -DestinationPath $EventLogsZipFile -Force -ErrorAction SilentlyContinue
		Add-Type -Assembly 'System.IO.Compression.FileSystem'
		[System.IO.Compression.ZipFile]::CreateFromDirectory($EventLogsDestinationPath, $EventLogsZipFile)
		# Cleanup the destination folder
		if ($EventLogsDestinationPath) {
			Remove-Item -Path $EventLogsDestinationPath -Recurse -Force
		}
	}
	catch {
		LogException "Failed to compress $EventLogsDestinationPath" $_
	}
	#endregion --- Event Logs ---

	#region --- WMI Provider Configuration ---
	LogInfo 'Getting WMI Configuration.'
	$WMIProviderConfigFile = $Prefix + 'OS_WMIProviderConfig.txt'
	$WMIProviderConfigFileBase = Split-Path -Leaf $WMIProviderConfigFile
	$WMIProviderConfigFileTemp1 = Get-CimInstance -Namespace 'root' -Class '__ProviderHostQuotaConfiguration' -ErrorAction SilentlyContinue
	if ($WMIProviderConfigFileTemp1 -is [CimInstance]) {
		LogInfo 'Connected to __ProviderHostQuotaConfiguration.'
		'------------------------' | Out-File $WMIProviderConfigFile
		'WMI Quota Configuration ' | Out-File -Append $WMIProviderConfigFile
		'------------------------' | Out-File -Append $WMIProviderConfigFile
		$WMIProviderConfigFileTemp1 | Select-Object MemoryPerHost, MemoryAllHosts, ThreadsPerHost, HandlesPerHost, ProcessLimitAllHosts | Out-File -Append $WMIProviderConfigFile
	}

	$WMIProviderConfigFileTemp2 = Get-CimInstance -Namespace 'root\cimv2' -Class 'MSFT_Providers' -ErrorAction SilentlyContinue
	if (($WMIProviderConfigFileTemp2 | Measure-Object).Count -gt 0) {
		LogInfo 'Connected to MSFT_Providers.'
		'------------------------' | Out-File -Append $WMIProviderConfigFile
		'WMI Providers' | Out-File -Append $WMIProviderConfigFile
		"------------------------`n" | Out-File -Append $WMIProviderConfigFile
		foreach ($provider in $WMIProviderConfigFileTemp2) {
			"Process ID $($provider.HostProcessIdentifier)" | Out-File -Append $WMIProviderConfigFile
			"  - Used by Provider $($provider.provider)" | Out-File -Append $WMIProviderConfigFile
			"  - Associated with Namespace $($provider.Namespace)" | Out-File -Append $WMIProviderConfigFile

			if (-not [string]::IsNullOrEmpty($provider.User)) {
				"  - By User $($provider.User)" | Out-File -Append $WMIProviderConfigFile
			}

			if (-not [string]::IsNullOrEmpty($provider.HostingGroup)) {
				"  - Under Hosting Group $($provider.HostingGroup)" | Out-File -Append $WMIProviderConfigFile
			}

			'' | Out-File -Append $WMIProviderConfigFile
		}
	}

	if ($WMIProviderConfigFileTemp1 -is [CimInstance] -or $WMIProviderConfigFileTemp2 -is [CimInstance]) {
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'WMI Provider Config' -Value "Review $WMIProviderConfigFileBase"
	}
	else {
		LogException 'Error obtaining data from WMI' $_
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'WMI Provider Config' -Value 'Error obtaining data from WMI'
	}
	#endregion --- WMI Provider Configuration ---

	#region --- Certificate Information ---
	LogInfo 'Getting Certificates.'
	if ($global:beta){
		Get-SccmCertificatesFromStore -CertificatesFile "$($Prefix)OS_Certificates.txt"
		#Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Certificates' -Value "Review $CertificatesFileBase"
	}
	else{
		$CertificatesFile = $Prefix + 'OS_Certificates.txt'
		$CertificatesFileBase = Split-Path -Leaf $CertificatesFile

		'##############' | Out-File $CertificatesFile
		'## COMPUTER ##' | Out-File -Append $CertificatesFile
		"##############`n`n" | Out-File -Append $CertificatesFile

		'MY' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\LocalMachine\My' | Out-File -Append $CertificatesFile

		'SMS' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\LocalMachine\SMS' | Out-File -Append $CertificatesFile

		'Trusted People' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\LocalMachine\TrustedPeople' | Out-File -Append $CertificatesFile

		'Trusted Publishers' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\LocalMachine\TrustedPublisher' | Out-File -Append $CertificatesFile

		'Trusted Root CA''s' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\LocalMachine\Root' | Out-File -Append $CertificatesFile

		'##############' | Out-File -Append $CertificatesFile
		'##   USER   ##' | Out-File -Append $CertificatesFile
		"##############`n`n" | Out-File -Append $CertificatesFile

		'MY' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\CurrentUser\My' | Out-File -Append $CertificatesFile

		'Trusted People' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\CurrentUser\TrustedPeople' | Out-File -Append $CertificatesFile

		'Trusted Publishers' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\CurrentUser\TrustedPublisher' | Out-File -Append $CertificatesFile

		'Trusted Root CA''s' | Out-File -Append $CertificatesFile
		'==================' | Out-File -Append $CertificatesFile
		Get-CertInfo 'Cert:\CurrentUser\Root' | Out-File -Append $CertificatesFile
		Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name 'Certificates' -Value "Review $CertificatesFileBase"
		#endregion --- Certificate Information ---
	}


	# Finally, pipe the OSInfo object information into the OSInfoFile
	$OSInfo | Out-File -Append $OSInfoFile -Width 500

	#region --- scheduled tasks ---
	if ($script:ActionsToSkip -notcontains 'schtasks.exe') {
		$LogPrefix = 'Tasks'
		LogInfo "[$LogPrefix] Getting scheduled tasks."
		$Commands = @(
			"cmd.exe /c %windir%\system32\schtasks.exe /query /fo CSV /v | Out-File -Append $($Prefix)schtasks.csv"
			"cmd.exe /c %windir%\system32\schtasks.exe /query /v | Out-File -Append $($Prefix)schtasks.txt"
		)
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	}
	#endregion --- scheduled tasks ---

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMGenericInfo ---

#region --- Function Get-SCCMChkSym ---
function Get-SCCMChkSym {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$ChkSymOutFolder
	)

	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	# set variables
	# moved function to external file to prevent overload of SCCM module
	$tss_ChkSymScriptPath = "$global:ScriptsFolder\tss_ChkSym.ps1"
	try {
		if (Test-Path "$global:ScriptsFolder\tss_ChkSym.ps1") {
			LogInfo "Running $tss_ChkSymScriptPath"
			& $tss_ChkSymScriptPath -ChkSymOutFolder $ChkSymOutFolder
		}
		else {
			LogWarn "$tss_ChkSymScriptPath is missing."
		}
	}
	catch {
		LogException "Something went wrong while executing $tss_ChkSymScriptPath" $_
	}

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMChkSym ---

#region --- Function Get-SCCMAutoRuns ---
function Get-SCCMAutoRuns {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$AutoRunsOutFolder,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$AutoRunsFormat
	)

	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'AutoRuns'
	# TODO: using old Autoruns.vbs, consider rewriting in PowerShell
	if (Test-Path -Path "$global:ScriptFolder\psSDP\Diag\global\Autoruns.vbs") {
		try {
			Push-Location -Path "$global:Scriptfolder\psSDP\Diag\global"
			$CommandToExecute = "cscript.exe //e:vbscript $global:Scriptfolder\psSDP\Diag\global\Autoruns.vbs $AutoRunsOutFolder /format:$AutoRunsFormat"
			LogInfo "[$LogPrefix] Autoruns.vbs starting..."
			LogInfoFile "[$LogPrefix] $CommandToExecute"
			Invoke-Expression -Command $CommandToExecute >$null 2>> $ErrorFile

		}
		catch { LogException ("[$LogPrefix] An Exception happend in Autoruns.vbs") $_ }
		Pop-Location
		LogInfo "[$LogPrefix] Autoruns.vbs completed."
	}
	else { LogInfo "[$LogPrefix] Autoruns.vbs not found - skipping..." }

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMAutoRuns ---

#region --- Function Get-SCCMProcessInfo ---
function Get-SCCMProcessInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'Process'

	#region ---  pstat and poolmon ---
	LogInfo 'Get Pstat.'
	# Get PStat.exe output
	$PstatFile = $Prefix + 'PStat.txt'
	$PoolMonFile = $Prefix + 'PoolMon.txt'

	if ($Env:PROCESSOR_ARCHITECTURE -eq 'x86' -or $Env:PROCESSOR_ARCHITECTURE -eq 'x64' -or $Env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
		# Run your command here
		LogInfo "Processor architecture '$($Env:PROCESSOR_ARCHITECTURE)' is supported."
		$Commands = @(
			LogInfo "Running $global:PstatExe"
			"cmd.exe /c $global:PstatExe | Out-File -Append $PstatFile"
			LogInfo "Running $global:PoolmonExe"
			"cmd.exe /c $global:PoolmonExe -t -b -r -n $PoolMonFile"
		)
		RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	}
	else {
		LogWarn "Processor architecture '$($Env:PROCESSOR_ARCHITECTURE)' is not supported."
	}
	#endregion --- pstat and poolmon ---

	#TODO: tasklist output is collected multiple times in this script
	LogInfo "[$LogPrefix] Getting process info."
	$Commands = @(
		"cmd.exe /c TaskList.exe /svc /fo list | Out-File -Append $($Prefix)Process_and_Service_Tasklist.txt"
		"cmd.exe /c TaskList.exe /svc			| Out-File -Append $($Prefix)OS_TaskListSvc_info.txt"
		"cmd.exe /c TaskList.exe /v				| Out-File -Append $($Prefix)OS_TaskListSvc_info.txt"
		"cmd.exe /c TaskList.exe /M				| Out-File -Append $($Prefix)OS_TaskListSvc_info.txt"
		"Get-CimInstance Win32_Process | fl ProcessId,Name,HandleCount,WorkingSetSize,VirtualSize,CommandLine | Out-File -Append $($Prefix)Process_and_Service_info.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	try {
		$disabledServices = Get-Service | Where-Object { $_.StartType -eq [System.ServiceProcess.ServiceStartMode]::Disabled }
		if ($disabledServices) {
			Write-Output 'This file contains a list of services that are currently disabled on this system.' | Out-File -Append "$($Prefix)Services_disabled.txt"
			Write-Output $line | Out-File -Append "$($Prefix)Services_disabled.txt"
			$disabledServices | Out-File -Append "$($Prefix)Services_disabled.txt"
		}
	}
	catch { LogException ("[$LogPrefix] An Exception happend:") $_ }

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMProcessInfo ---

#region --- Function Get-SCCMProcessInfo ---
function Get-SCCMServices {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'Services'

	LogInfo "[$LogPrefix] Getting services info."
	$Commands = @(
		"cmd.exe /c sc.exe query 						| Out-File -Append $($Prefix)Services_active_info.txt"
		"cmd.exe /c sc.exe query type= all state= all	| Out-File -Append $($Prefix)Services_info.txt"
	)
	RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMProcessInfo ---

#region --- Function Get-SCCMNetworkInfo ---

function Get-SCCMNetworkInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	# ***********************************************************************************************************************************
	# 	Collects basic Networking Information.
	#	Base script taken from SharedComponents\Scripts\NetworkBasicInfo.
	#	1. Gets IP Details.
	#	2. Gets Proxy Information
	#	3. Gets Active BITS Jobs
	#	4. Gets Enabled Firewall Rules
	#	5. Gets TCP/IP Information
	#	6. Gets SMB Information
	#	7. Summarizes all data to a text file for better readability.
	# ***********************************************************************************************************************************
	$LogPrefix = 'NetworkInfo'
	$NetInfoFile = $Prefix + '_NET_Summary.txt'

	# IP Address
	'------------'	| Out-File $NetInfoFile
	'IP Details:'	| Out-File -Append $NetInfoFile
	'------------'	| Out-File -Append $NetInfoFile
	Get-CimInstance -Namespace root\cimv2 -class Win32_NetworkAdapterConfiguration | Where-Object { $null -ne $_.IPAddress } | `
		Select-Object DNSHostName, IpAddress, DefaultIPGateway, IPSubnet, MACAddress, DHCPEnabled -Unique | `
		Out-File -Append $NetInfoFile

	# Proxy Information
	$ProxyFile = $Prefix + 'OS_ProxyInfo.txt'
	$NetTempFile = Split-Path -Leaf $ProxyFile

	'-----------------------------------' | Out-File -Append $NetInfoFile
	'Proxy Information (System and User)' | Out-File -Append $NetInfoFile
	'-----------------------------------' | Out-File -Append $NetInfoFile
	"    Review $NetTempFile" | Out-File -Append $NetInfoFile

	# System Proxy
	'==========================' | Out-File -Append $ProxyFile
	'Proxy Information (System)' | Out-File -Append $ProxyFile
	'==========================' | Out-File -Append $ProxyFile
	if ($OSVersion.Major -ge 6) {
		LogInfo "[$LogPrefix] Get Proxy Information (System)."
		$Commands = @(
			"cmd /r $global:ScriptFolder\BIN\PsExec.exe -accepteula -nobanner -s netsh winhttp show proxy | Out-File -Append $ProxyFile"
		)
		RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	}
	else {
		LogInfo "[$LogPrefix] Get Proxy Information (System)."
		$Commands = @(
			"cmd /r $global:ScriptFolder\BIN\PsExec.exe -accepteula -nobanner -s proxycfg | Out-File -Append $ProxyFile"
		)
		RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	}

	# User Proxy
	'========================' | Out-File -Append $ProxyFile
	'Proxy Information (User)' | Out-File -Append $ProxyFile
	'========================' | Out-File -Append $ProxyFile
	if ($OSVersion.Major -ge 6) {
		LogInfo "[$LogPrefix] Get Proxy Information (User)."
		$Commands = @(
			"cmd /r netsh winhttp show proxy | Out-File -Append $ProxyFile"
		)
		RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	}
	else {
		LogInfo "[$LogPrefix] Get Proxy Information (User)."
		$Commands = @(
			"cmd /r proxycfg | Out-File -Append $ProxyFile"
		)
		RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
	}

	# Proxy Information (Registry Keys)'
	LogInfo ("[$LogPrefix] Export Proxy Information (Registry Keys).")
	$RegKeys = @(
		('HKLM:Software\Microsoft\Windows\CurrentVersion\Internet Settings', "$ProxyFile"),
		('HKCU:Software\Microsoft\Windows\CurrentVersion\Internet Settings', "$ProxyFile"),
		('HKU:.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Internet Settings', "$ProxyFile")
	)
	FwExportRegistry $LogPrefix $RegKeys

	# Get Bits Transfers
	'' | Out-File -Append $NetInfoFile
	'-----------------' | Out-File -Append $NetInfoFile
	'Active BITS Jobs' | Out-File -Append $NetInfoFile
	'-----------------' | Out-File -Append $NetInfoFile
	$BitsFile = $Prefix + 'OS_BITSTransfers.txt'
	$NetTempFile = Split-Path -Leaf $BitsFile

	LogInfo "[$LogPrefix] Get BITS Transfers (System)."
	$Commands = @(
		"cmd /r $global:ScriptFolder\BIN\PsExec.exe -accepteula -nobanner -s bitsadmin.exe /RAWRETURN /list /allusers /verbose | Out-File -Append $BitsFile"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	if ($null -ne (Get-Content $BitsFile)) {
		# BitsAdmin.exe executed succesfully, and output file was not empty
		"    Review $NetTempFile" | Out-File -Append $NetInfoFile
	}
	else {
		# BitsAdmin.exe executed succesfully, but output file was empty
		'    No Active Bits Jobs Found' | Out-File -Append $NetInfoFile
	}

	# Firewall Rules
	'' | Out-File -Append $NetInfoFile
	'-----------------------' | Out-File -Append $NetInfoFile
	'Enabled Firewall Rules' | Out-File -Append $NetInfoFile
	'-----------------------' | Out-File -Append $NetInfoFile
	$FwFile = $Prefix + 'OS_EnabledFirewallRules.txt'
	$NetTempFile = Split-Path -Leaf $BitsFile
	'===================================' | Out-File -Append $FwFile -Width 1000
	$FwTemp = (Get-Service | Where-Object { $_.DisplayName -match 'Windows Firewall' } | Select-Object Status)
	'Firewall Service Status = ' + $FwTemp.Status | Out-File -Append $FwFile -Width 1000
	'===================================' | Out-File -Append $FwFile -Width 1000

	if ($OSVersion.Major -ge 6) {
		trap [Exception] {
			'    ERROR: ' + ($_.Exception.Message) | Out-File -Append $NetInfoFile
		}
		$fw = New-Object -ComObject hnetcfg.fwpolicy2 -ErrorAction SilentlyContinue -ErrorVariable FWError
		if ($FWError.Count -eq 0) {
			$fw.Rules | Where-Object { $_.Enabled } | Sort-Object Name | `
				Format-Table -Property Name, Direction, Protocol, LocalPorts, RemotePorts, LocalAddresses, RemoteAddresses, ServiceName, ApplicationName -AutoSize | `
				Out-File -Append $FwFile -Width 1000
			"    Review $NetTempFile" | Out-File -Append $NetInfoFile
		}
	}
	else {
		LogInfo "[$LogPrefix] Get Proxy Information (System)."
		$Commands = @(
			"cmd /r netsh firewall show config | Out-File -Append $FwFile"
		)
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
		"    Review $NetTempFile" | Out-File -Append $NetInfoFile
	}

	# TCP/IP and SMB Information
	$TCPIPFile = $Prefix + 'OS_TCPIP-Info.txt'
	$NetTempFile = Split-Path -Leaf $TCPIPFile
	'' | Out-File -Append $NetInfoFile
	'-------------------' | Out-File -Append $NetInfoFile
	'TCP/IP Information' | Out-File -Append $NetInfoFile
	'-------------------' | Out-File -Append $NetInfoFile
	"    Review $NetTempFile" | Out-File -Append $NetInfoFile

	LogInfo "[$LogPrefix] Get TCP/IP and SMB Information."
	$Commands = @(
		"cmd /r hostname | Out-File $TCPIPFile"
		"cmd /r ipconfig /all | Out-File -Append $TCPIPFile"
		"cmd /r arp -a | Out-File $($Prefix)OS_TCPIP-Info-arp.txt"
		"cmd /r nbtstat -n | Out-File $($Prefix)OS_TCPIP-Info-nbtstat.txt"
		"cmd /r netstat -ano | Out-File -Append $($Prefix)OS_TCPIP-Info-nbtstat.txt"
		"cmd /r netstat -anob | Out-File -Append $($Prefix)OS_TCPIP-Info-nbtstat.txt"
	)
	if ($OSVersion.Major -ge 6) {
		$Commands += @(
			"cmd /r netsh int tcp show global | Out-File $($Prefix)OS_TCPIP-Info-netsh.txt"
			"cmd /r netsh int ipv4 show offload | Out-File -Append $($Prefix)OS_TCPIP-Info-netsh.txt"
			"cmd /r netstat -nato -p tcp | Out-File $($Prefix)OS_TCPIP-Info-netstat.txt"
		)
	}
	else {
		$Commands += @(
			"cmd /r netstat -ano -p tcp | Out-File $($Prefix)OS_TCPIP-Info-netstat.txt"
		)
	}
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	LogInfo ("[$LogPrefix] Export TCP/IP Information (Registry Keys).")
	$RegKeys = @(
		('HKLM:SYSTEM\CurrentControlSet\Services\Tcpip\Parameters')
	)
	FwExportRegToOneFile $LogPrefix $RegKeys "$($Prefix)OS_TCPIP-reg.txt"

	$SMBFile = $Prefix + 'OS_SMB-Info.txt'
	$NetTempFile = Split-Path -Leaf $SMBFile
	'' | Out-File -Append $NetInfoFile
	'----------------' | Out-File -Append $NetInfoFile
	'SMB Information' | Out-File -Append $NetInfoFile
	'----------------' | Out-File -Append $NetInfoFile
	"    Review $NetTempFile" | Out-File -Append $NetInfoFile

	LogInfo "[$LogPrefix] Get SMB Information."
	$Commands = @(
		"cmd /r net sessions | Out-File -Append $SMBFile"
		"cmd /r net use | Out-File -Append $SMBFile"
		"cmd /r net accounts | Out-File -Append $SMBFile"
		"cmd /r net statistics workstation | Out-File -Append $SMBFile"
	)
	if ((Get-TSRemote) -lt 2) {
		$Commands += @(
			"cmd /r net config workstation | Out-File -Append $SMBFile"
		)
	}
	if ((Get-Service 'lanmanserver').Status -eq 'Running') {
		$Commands += @(
			"cmd /r net config server | Out-File -Append $SMBFile"
			"cmd /r net share | Out-File -Append $SMBFile"
		)
	}
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMNetworkInfo ---

#region --- Function Get-SCCMRegistryInfo ---
function Get-SCCMRegistryInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'Registry'

	LogInfo ("[$LogPrefix] Export Registry Information (Registry Keys).")
	# Feature 677: Add OMADM\Accounts in SCCM scenario
	$RegKeys = @(
		('HKLM:SOFTWARE\Microsoft\CCM', "$($Prefix)reg_CCM.txt"),
		('HKLM:SOFTWARE\Microsoft\CCMSetup', "$($Prefix)reg_CCMSetup.txt"),
		('HKLM:Software\Microsoft\COM3', "$($Prefix)reg_COM3.txt"),
		('HKLM:SOFTWARE\Microsoft\Enrollments', "$($Prefix)reg_Enrollment.txt"),
		('HKLM:SOFTWARE\Microsoft\OLE', "$($Prefix)reg_DCOM.txt"),
		('HKLM\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot', "$($Prefix)reg_Diagnostics_AutoPilot.txt"),
		('HKLM:SOFTWARE\Microsoft\Provisioning\OMADM', "$($Prefix)reg_OMADM.txt"),
		('HKLM:SOFTWARE\Microsoft\Microsoft Antimalware', "$($Prefix)reg_FEP-Defender.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows Defender', "$($Prefix)reg_FEP-Defender.txt"),
		('HKLM:SOFTWARE\Microsoft\SMS', "$($Prefix)reg_SMS.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', "$($Prefix)reg_Uninstall.txt"),
		('HKLM:SOFTWARE\Policies', "$($Prefix)reg_HKLMPolicies.txt"),
		('HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall', "$($Prefix)reg_Uninstall.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Services', "$($Prefix)reg_Services.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL', "$($Prefix)reg_SCHANNEL.txt"),
		('HKLM:SYSTEM\Setup', "$($Prefix)reg_Setup_SetupType.txt"),
		('HKCU:SOFTWARE\Policies', "$($Prefix)reg_HKCUPolicies.txt")
	)
FwExportRegistry $LogPrefix $RegKeys $ShowMessage=$True

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMRegistryInfo ---

#region --- Function Get-SCCMUserPermissions ---
function Get-SCCMUserPermissions {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'UserRights'
	$UserRightsFile = $Prefix + 'UserRights.txt'
	$ShowprivExe = "$global:ScriptFolder\psSDP\Diag\global\Showpriv.exe"

	LogInfo "[$LogPrefix] Obtain User Rights (privileges)."

	if (Test-Path $ShowprivExe) {
		# using '>' and '>>' instead of 'Out-File' to prevent RunCommands from adding headers
		# above each command and keep formatting consistent with old file
		$Commands = @(
			"Write-Output `"Defined User Rights`n===================`n`" > $UserRightsFile"
			"Write-Output `"Access Credential Manager as a trusted caller`n=============================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeTakeOwnershipPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nAccess this computer from the network`n=====================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeNetworkLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nAct as part of the operating system`n===================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeTcbPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nAdd workstations to domain`n==========================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeMachineAccountPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nAdjust memory quotas for a process`n==================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeIncreaseQuotaPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nAllow log on Locally`n=============`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeInteractiveLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nAllow logon through Remote Desktop Services`n=====================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeRemoteInteractiveLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nBack up files and directories`n=============================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeBackupPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nBypass Traverse Checking`n========================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeChangeNotifyPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nChange the system time`n======================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeSystemTimePrivilege >> $UserRightsFile"
			"Write-Output `"`n`nChange the time zone`n====================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeTimeZonePrivilege >> $UserRightsFile"
			"Write-Output `"`n`nCreate a pagefile`n=================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeCreatePagefilePrivilege >> $UserRightsFile"
			"Write-Output `"`n`nCreate a token object`n=====================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeCreateTokenPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nCreate global objects`n=====================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeCreateGlobalPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nCreate permanent shared objects`n===============================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeCreatePermanentPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nCreate Symbolic links`n=====================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeCreateSymbolicLinkPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nDebug programs`n==============`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeDebugPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nDeny access to this computer from the network`n=============================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeDenyNetworkLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nDeny log on as a batch job`n==========================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeDenyBatchLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nDeny log on as a service`n========================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeDenyServiceLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nDeny log on Locally`n==================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeDenyInteractiveLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nDeny log on through Remote Desktop Services`n====================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeDenyRemoteInteractiveLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nEnable computer and user accounts to be trusted for delegation`n==============================================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeEnableDelegationPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nForce shutdown from a remote system`n===================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeRemoteShutdownPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nGenerate security audits`n========================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeAuditPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nImpersonate a client after authentication`n=========================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeImpersonatePrivilege >> $UserRightsFile"
			"Write-Output `"`n`nIncrease a process working set`n==============================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeIncreaseWorkingSetPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nIncrease scheduling priority`n============================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeIncreaseBasePriorityPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nLoad and unload device drivers`n==============================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeLoadDriverPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nLock pages in memory`n====================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeLockMemoryPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nLog on as a batch job`n=====================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeBatchLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nLog on as a service`n===================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeServiceLogonRight >> $UserRightsFile"
			"Write-Output `"`n`nManage auditing and security log`n================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeSecurityPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nModify an object label`n==================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeRelabelPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nModify firmware environment values`n==================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeSystemEnvironmentPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nPerform volume maintenance tasks`n================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeManageVolumePrivilege >> $UserRightsFile"
			"Write-Output `"`n`nProfile single process`n======================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeProfileSingleProcessPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nProfile system performance`n==========================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeSystemProfilePrivilege >> $UserRightsFile"
			"Write-Output `"`n`nRemove computer from docking station`n====================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeUndockPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nReplace a process-level token`n=============================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeAssignPrimaryTokenPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nRestore files and directories`n=============================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeRestorePrivilege >> $UserRightsFile"
			"Write-Output `"`n`nShut down the system`n====================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeShutdownPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nSynchronize directory service data`n==================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeSynchAgentPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nTake ownership of files or other objects`n========================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeTakeOwnershipPrivilege >> $UserRightsFile"
			"Write-Output `"`n`nRead unsolicited input from a terminal device`n=============================================`" >> $UserRightsFile"
			"cmd /r $ShowprivExe SeUnsolicitedInputPrivilege >> $UserRightsFile"
		)
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	}
	LogInfo "[$LogPrefix] End User Rights (privileges)."
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMUserPermissions ---

#region --- Function Get-SCCMWsusBasicinfo - Feature 657 ---
function Get-SCCMWsusBasicinfo {
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$WsusInfoOutFolder
	)
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	if (-not $global:Is_Wsus) {
		LogWarn 'WSUS is not installed on this system.'
		EndFunc $MyInvocation.MyCommand.Name
	}
	
	if ($global:beta) {
		$LogPrefix = 'Registry'
		LogInfo ("[$LogPrefix] Export Registry Information for WSUS ")
		$RegKeys = , ('HKLM:SOFTWARE\Microsoft\Update Services', "$($Prefix)reg_WSUS.txt")
		FwExportRegistry $LogPrefix $RegKeys $ShowMessage=$True

	}
	
	try {
		if (Test-Path "$global:ScriptFolder\scripts\tss_SCCM_WSUSBasicInfo.ps1") {
			LogInfo 'Get basic WSUS Info.'
			& "$global:ScriptFolder\scripts\tss_SCCM_WSUSBasicInfo.ps1" -GetApprovedUpdates -OutputDirectory $WsusInfoOutFolder -SilentExecution
		}
		else {
			LogWarn "File `"$global:ScriptFolder\scripts\tss_SCCM_WSUSBasicInfo.ps1`" not found."
		}
	}
	catch { Logexecption "Error while running $($MyInvocation.MyCommand.Name)" $_ }

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMWsusBasicinfo - Feature 657 ---

#region --- Function Get-SccmWsusServerInfo ---
function Get-SccmWsusServerInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'WSUS'

	# Get WSUS info, if installed
	if ($Is_WSUS) {
		$WSUSInfo = New-Object PSObject

		# Summary File Header
		$WSUSFile = $Prefix + '_WSUS_Summary.txt'
		'======================' | Out-File $WSUSFile
		'Update Server Summary:' | Out-File $WSUSFile -Append
		'======================' | Out-File $WSUSFile -Append

		# Computer Name
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Computer Name' -Value $ComputerName
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Logged On User' -Value ($Env:USERDOMAIN + '\' + $Env:USERNAME)

		# Time zone information:
		$Temp = Get-CimInstance -Namespace 'root\cimv2' -Class Win32_TimeZone -ErrorAction SilentlyContinue
		if ($Temp -is [CimInstance]) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Time Zone' -Value $Temp.Description
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Time Zone' -Value 'Error obtaining value from Win32_TimeZone WMI Class'
		}

		$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
		if ($Temp -is [CimInstance]) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Daylight In Effect' -Value $Temp.DaylightInEffect
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Daylight In Effect' -Value 'Error obtaining value from Win32_ComputerSystem WMI Class'
		}

		# WUA Service Status
		$Temp = Get-Service | Where-Object { $_.Name -eq 'WsusService' } | Select-Object Status
		if ($null -ne $Temp) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Update Services Service Status' -Value $Temp.Status
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Update Services Service Status' -Value 'ERROR: Service Not found'
		}

		# WUA Service StartTime
		$Temp = Get-Process | Where-Object { ($_.ProcessName -eq 'WsusService') } | Select-Object StartTime
		if ($null -ne $Temp) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Update Services Service StartTime' -Value $Temp.StartTime
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Update Services Service StartTime' -Value 'ERROR: Service Not running'
		}

		# WSUS Registry Settings
		$Version = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'VersionString'
		if ($null -ne $Version) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Version' -Value $Version
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Version' -Value 'Error obtaining value from Registry'
		}

		$Temp = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'ContentDir'
		if ($null -ne $Temp) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Content Directory' -Value $Temp
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Content Directory' -Value 'Error obtaining value from Registry'
		}

		$Temp = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'PortNumber'
		if ($null -ne $Temp) {
			$Port = $Temp
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Port Number' -Value $Temp
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Port Number' -Value 'Error obtaining value from Registry'
		}

		$Temp = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'SqlServerName'
		if ($null -ne $Temp) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SQL Server Name' -Value $Temp
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SQL Server Name' -Value 'Error obtaining value from Registry'
		}

		$Temp = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'SqlDatabaseName'
		if ($null -ne $Temp) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SQLDatabaseName' -Value $Temp
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SQLDatabaseName' -Value 'Error obtaining value from Registry'
		}

		$Temp = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'SqlAuthenticationMode'
		if ($null -ne $Temp) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SQL Authentication Mode' -Value $Temp
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SQL Authentication Mode' -Value 'Error obtaining value from Registry'
		}

		$Temp = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'UsingSSL'
		if ($Temp -eq 1) {
			$SSL = $true
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SSL Enabled' -Value $Temp
			$Temp = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'ServerCertificateName'
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'ServerCertificateName' -Value $Temp
		}
		else {
			$SSL = $false
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'SSL Enabled' -Value 0
		}

		# Instantiate WSUS Object
		try {
			[void][reflection.assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration')
			$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer([System.Net.Dns]::GetHostEntry($ComputerName).HostName, $SSL, $Port)
		}
		catch [System.Net.WebException] {
			LogInfo "Failed to execute GetUpdateServer() using the FQDN. Trying again with the NetBIOS hostname..."
			try {
				$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($ComputerName, $SSL, $Port)
			}
			catch [System.Exception] {
				LogWarn 'Failed to connect to the WSUS Server.'
				LogException '  Error: ' $_
				$wsus = $null
			}
		}
		catch [System.Exception] {
			LogWarn 'Failed to connect to the WSUS Server.'
			LogException '  Error: ' $_
			$wsus = $null
		}
		
		# File List from WSUS ContentDirectory
		if ($null -ne $wsus) {
			$ContentPath = $wsus.GetConfiguration().LocalContentCachePath

			if (Test-Path $ContentPath) {
				$WSUSContentFile = $Prefix + 'WSUS_FileList_ContentDir.txt'
				$WSUSContentFileBase = Split-Path -Leaf $WSUSContentFile
				LogInfo "Dir through WSUS Content Directory: $ContentPath"
				Get-ChildItem ($ContentPath) -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
					Select-Object LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
					Out-File $WSUSContentFile -Width 1000
				if ($DirError.Count -eq 0) {
					Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Content File List' -Value ("Review $WSUSContentFileBase")
				}
				else {
					Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Content File List' -Value ('ERROR: ' + $DirError[0].Exception.Message)
					$DirError.Clear()
				}
			}
			else {
				LogInfo "Cannot access '$ContentPath'! Skipping WSUS Content File List." Magenta
				Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Content File List' -Value ("ERROR: Unable to access '$ContentPath'")
			}
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Content File List' -Value ('ERROR: Unable to connect to WSUS Server.')
		}
		# File List from Install Directory
		$WSUSInstallFile = $Prefix + 'WSUS_FileList_InstallDir.TXT'
		$WSUSInstallFileBase = Split-Path -Leaf $WSUSInstallFile
		LogInfo "Dir through WSUS Install Directory: $WSUSInstallDir"
		Get-ChildItem ($WSUSInstallDir) -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
			Select-Object LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
			Out-File $WSUSInstallFile -Width 1000
		if ($DirError.Count -eq 0) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Server File List' -Value ("Review $WSUSInstallFileBase")
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Server File List' -Value ('ERROR: ' + $DirError[0].Exception.Message)
			$DirError.Clear()
		}
		# Binary Versions List
		$WSUSVersionsFile = $Prefix + 'WSUS_FileVersions.TXT'
		$WSUSVersionsFileBase = Split-Path -Leaf $WSUSVersionsFile
		LogInfo "Get Binary Versions from WSUS Install Directory: $WSUSInstallDir"
		Get-ChildItem ($WSUSInstallDir) -Recurse -Include *.dll, *.exe -ErrorVariable DirError -ErrorAction SilentlyContinue | `
			ForEach-Object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_) } | `
			Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize | `
			Out-File $WSUSVersionsFile -Width 1000
		if ($DirError.Count -eq 0) {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Server File Versions' -Value ("Review $WSUSVersionsFileBase")
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'Server File Versions' -Value ('ERROR: ' + $DirError[0].Exception.Message)
			$DirError.Clear()
		}

		# Collect WSUS Logs
		$WSUSLogPath = $WSUSInstallDir + 'LogFiles'
		$WSUSLogsDestinationPath = $Prefix + 'Logs_WSUS'
		$WSUSLogsZipFile = $Prefix + 'Logs_WSUS.zip'
		LogInfo "WSUS Logs Directory: $WSUSLogPath"
		FwCreateFolder $WSUSLogsDestinationPath

		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths = @(
			@("$WSUSLogPath\*.log", "$WSUSLogsDestinationPath"),
			@("$WSUSLogPath\*.old", "$WSUSLogsDestinationPath"),
			@("$WSUSLogPath\*.xml", "$WSUSLogsDestinationPath")
		)
		# if path exists, add it to the list of files to copy
		# Feature 653: Add WSUS configuration to _WSUS_Summary.txt and collect additional logs
		if (Test-Path -Path "$env:windir\WID\Log") { FwCreateFolder "$WSUSLogsDestinationPath\WID";$SourceDestinationPaths += ,@("$env:windir\WID\Log\*.*", "$($WSUSLogsDestinationPath)\WID")}
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $WSUSLogsDestinationPath"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($WSUSLogsDestinationPath, $WSUSLogsZipFile)
			# Cleanup the destination folder
			if ($WSUSLogsDestinationPath) {
				Remove-Item -Path $WSUSLogsDestinationPath -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $WSUSLogsDestinationPath" $_
		}

		# Get WSUS Basic Info
		$WSUSBasicFileName = $Prefix + 'WSUS_BasicInfo.txt'
		$WSUSBasicFileNameBase = Split-Path -Leaf $WSUSBasicFileName
		$WSUSApprovalsFile = $Prefix + 'WSUS_UpdateApprovals.txt'
		$WSUSApprovalsFileBase = Split-Path -Leaf $WSUSApprovalsFile

		try {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Basic Info' -Value "Review $WSUSBasicFileNameBase"
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Approved Updates' -Value "Review $WSUSApprovalsFileBase"
		}
		catch [System.Exception] {
			$errMessage = $_.Exception.Message
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Basic Info' -Value $errMessage
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'WSUS Approved Updates' -Value $errMessage
		}

		# Copying IIS applicationHost.config file
		$IISConfigFile = $Prefix + 'IIS_applicationHost.config.txt'
		$IISConfigFileBase = Split-Path -Leaf $IISConfigFile
		try {
			LogInfo "[$LogPrefix] Copying IIS applicationHost.config file"
			$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
			$SourceDestinationPaths.add(@("$env:windir\system32\inetsrv\config\applicationHost.config", "$IISConfigFile"))
			FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'IIS Application Config' -Value "Review $IISConfigFileBase"
		}
		catch [System.Exception] {
			$errMessage = $_.Exception.Message
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name 'IIS Application Config' -Value $errMessage
		}

		# Output WSUSInfo PSObject to Summary File
		LogInfo 'Output WSUSInfo PSObject to Summary File'
		$WSUSInfo | Out-File $WSUSFile -Append -Width 500

		# Retrieve WSUS configuration
		# Feature 653: Add WSUS configuration to _WSUS_Summary.txt and collect additional logs
		"`n============================" | Out-File $WSUSFile -Append
		'Update Server Configuration:' | Out-File $WSUSFile -Append
		'============================' | Out-File $WSUSFile -Append

		try{
			$WSUSConfiguration = New-Object PSObject
			$WSUSServerConfig = (Get-WSUSServer).GetConfiguration()
			foreach ($property in $WSUSServerConfig | Get-Member -MemberType Properties) {
				# Extract the property name and value
				$propertyName = $property.Name
				$propertyValue = $WSUSServerConfig.$propertyName
				# Add the new property to each object
				Add-Member -InputObject $WSUSConfiguration -MemberType NoteProperty -Name $propertyName -Value $propertyValue
			}

		}
		catch [System.Exception] {
			$errMessage = $_.Exception.Message
			Add-Member -InputObject $WSUSConfiguration -MemberType NoteProperty -Name 'WSUS Configuration Info' -Value $errMessage
		}
		# Output WSUSInfo PSObject to Summary File
		LogInfo 'Output WSUSConfiguration PSObject to Summary File'
		$WSUSConfiguration | Out-File $WSUSFile -Append -Width 500
	}

	# ---------------------------------------------------
	# Collect WSUS Setup Logs (if present)
	# ---------------------------------------------------
	LogInfo 'Collect WSUS Setup Logs'
	$WSUSSetupLogPath = $Env:Temp
	$WSUSSetupLogsDestinationPath = $Prefix + 'Logs_WSUS_Setup'
	$WSUSSetupLogsZipFile = $Prefix + 'Logs_WSUS_Setup.zip'

	if (Test-Path $WSUSSetupLogPath\WSUS*.log) {
		FwCreateFolder $WSUSSetupLogsDestinationPath

		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths.add(@("$WSUSSetupLogPath\WSUS*.log", "$WSUSSetupLogsDestinationPath"))
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $WSUSSetupLogsDestinationPath"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($WSUSSetupLogsDestinationPath, $WSUSSetupLogsZipFile)
			# Cleanup the destination folder
			if ($WSUSSetupLogsDestinationPath) {
				Remove-Item -Path $WSUSSetupLogsDestinationPath -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $WSUSSetupLogsDestinationPath" $_
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SccmWsusServerInfo ---

#region --- Function Get-SCCMWUAInfo ---
function Get-SCCMWUAInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'WUA'

	$WuaInfo = New-Object PSObject
	# Summary File Header
	$WuaSummaryFile = $Prefix + '_WUA_Summary.txt'
	'===========================================' | Out-File $WuaSummaryFile
	'Windows Update Agent Configuration Summary:' | Out-File $WuaSummaryFile -Append
	'===========================================' | Out-File $WuaSummaryFile -Append

	# Computer Name
	Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'Computer Name' -Value $env:COMPUTERNAME
	LogInfo "[$LogPrefix] Get Time zone information."
	# Time zone information:
	$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_TimeZone -ErrorAction SilentlyContinue
	if ($Temp -is [CimInstance]) {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'Time Zone' -Value $Temp.Description
	}
	else {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'Time Zone' -Value 'Error obtaining value from Win32_TimeZone WMI Class'
	}
	$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
	if ($Temp -is [CimInstance]) {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'Daylight In Effect' -Value $Temp.DaylightInEffect
	}
	else {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'Daylight In Effect' -Value 'Error obtaining value from Win32_ComputerSystem WMI Class'
	}

	# WUA Service Status
	LogInfo "[$LogPrefix] Get WUA Service Status."
	$Temp = Get-Service | Where-Object { $_.Name -eq 'WuAuServ' } | Select-Object Status
	if ($null -ne $Temp) {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Service Status' -Value $Temp.Status
	}
	else {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Service Status' -Value 'ERROR: Service Not found'
	}

	# WUA Service StartTime
	LogInfo "[$LogPrefix] Get WUA Service StartTime."
	$Temp = Get-Process | Where-Object { ($_.ProcessName -eq 'SvcHost') -and ($_.Modules -match 'wuaueng.dll') } | Select-Object StartTime
	if ($null -ne $Temp) {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Service StartTime' -Value $Temp.StartTime
	}
	else {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Service StartTime' -Value 'ERROR: Service Not running'
	}

	# WUA Version
	LogInfo "[$LogPrefix] Get WUA Version."
	trap [Exception] {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Version' -Value ('ERROR: ' + ($_.Exception.Message)) -Force
	}
	$Wua = New-Object -com 'Microsoft.Update.AgentInfo' -ErrorAction SilentlyContinue -ErrorVariable WUAError
	if ($WuaError.Count -eq 0) {
		$Temp = $Wua.GetInfo('ProductVersionString')
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Version' -Value $Temp -Force
	}

	# Update Sources
	LogInfo "[$LogPrefix] Get Update Sources."
	$SUSFile = $Prefix + 'WUA_UpdateSources.txt'
	$SUSFileBase = Split-Path -Leaf $SUSFile
	$WuaRegFile = $Prefix + 'reg_WU.txt'
	$WuaRegFileBase = Split-Path -Leaf $WuaRegFile
	try { $temp = New-Object -ComObject "Microsoft.Update.ServiceManager" -ErrorAction Stop }
	catch { LogException 'Failed to get WUA update sources' $_ }
	$defaultAUService = $temp.Services | Where-Object {$_.IsDefaultAUService -eq $true} | Select-Object Name -ExpandProperty Name
	if (($defaultAUService) -and ($defaultAUService -ne "Windows Server Update Service")) {
		LogInfo "[$LogPrefix] WSUS is NOT the default update source!"
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name "Default Update Source" -Value "$($defaultAUService). Review $WuaRegFileBase and $SUSFileBase"
		$temp.Services | Out-File $SUSFile -Force
	}
	elseif ($defaultAUService) {
		Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name "Default Update Source" -Value "$($defaultAUService). Review $SUSFileBase"
		$temp.Services | Out-File $SUSFile -Force
	}

	# Convert Windows Update ETLs (if applicable)
	if ($script:ActionsToSkip -notcontains 'WindowsUpdate.log') {
		if (Test-Path $env:windir\Logs\WindowsUpdate) {
			if ($osVersion.Build -le 14393) {
				# we want to exclude Server 2016 (or previous OS) because the conversion might not succeed, even when the public symbol server can be reached
				LogInfo "[$LogPrefix] OS version is $osVersion - not converting Windows Update log."
			}
			elseif ($osVersion.Build) {
				if ($global:beta) {
					LogInfo $(OutputWaitforResult "converting Windows Update ETLs" "[$LogPrefix]")
				}
				else { LogInfo "[$LogPrefix] Start converting Windows Update ETLs and continue - we'll wait later for it to end." }
				$script:WULogsJobLog = $Prefix + "WUA_WindowsUpdateETL_Converted.log"
				$script:WULogsJob = Start-Job -ScriptBlock { Get-WindowsUpdateLog -Log $args } -ArgumentList $script:WULogsJobLog
			}
		}
	}

	# File List in SoftwareDistribution Directory
	if ($script:ActionsToSkip -notcontains 'SoftwareDistributionDirectory') {
		LogInfo "[$LogPrefix] Get File List in SoftwareDistribution Directory."
		$WuaFile = $Prefix + 'WUA_FileList.txt'
		$WuaFileBase = Split-Path -Leaf $WuaFile
		Get-ChildItem (Join-Path $env:windir 'SoftwareDistribution') -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
			Select-Object CreationTime, LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
			Out-File $WuaFile -Width 1000
		if ($DirError.Count -eq 0) {
			Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'SoftwareDistribution Directory List' -Value "Review $WuaFileBase"
		}
		else {
			$DirError.Clear()
		}
	}

	# WUA DLL Versions
	LogInfo "[$LogPrefix] Get Windows Update Agent DLL Versions."
	$WuaVersionsFile = $Prefix + 'WUA_FileVersions.txt'
	$WuaVersionsFileBase = Split-Path -Leaf $WuaVersionsFile
	Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Related File Versions' -Value "Review $WuaVersionsFileBase"
	'-----------------------------------' | Out-File $WuaVersionsFile -Append
	'Windows Update Agent DLL Versions: ' | Out-File $WuaVersionsFile -Append
	'-----------------------------------' | Out-File $WuaVersionsFile -Append
	Get-ChildItem (Join-Path $Env:windir 'system32\wu*.dll') -Exclude WUD*.dll -ErrorAction SilentlyContinue | `
		ForEach-Object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_) } | `
		Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
		Out-File $WuaVersionsFile -Append -Width 1000

	# BITS DLL Versions
	LogInfo "[$LogPrefix] Get BITS DLL Versions."
	'-------------------' | Out-File $WuaVersionsFile -Append
	'BITS DLL Versions: ' | Out-File $WuaVersionsFile -Append
	'-------------------' | Out-File $WuaVersionsFile -Append
	Get-ChildItem (Join-Path $Env:windir 'system32\bits*.dll'), (Join-Path $Env:windir 'system32\winhttp*.dll'), (Join-Path $Env:windir 'system32\qmgr*.dll') -ErrorAction SilentlyContinue | `
		ForEach-Object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_) } | `
		Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
		Out-File $WuaVersionsFile -Append -Width 1000

	# MSI DLL Versions
	LogInfo "[$LogPrefix] Get MSI DLL Versions."
	'--------------------------------' | Out-File $WuaVersionsFile -Append
	'Windows Installer DLL Versions: ' | Out-File $WuaVersionsFile -Append
	'--------------------------------' | Out-File $WuaVersionsFile -Append
	Get-ChildItem (Join-Path $Env:windir 'system32\msi*.*') -ErrorAction SilentlyContinue | `
		ForEach-Object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_) } | `
		Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
		Out-File $WuaVersionsFile -Append -Width 1000

	# MSXML DLL Versions
	LogInfo "[$LogPrefix] Get MSXML DLL Versions."
	'--------------------' | Out-File $WuaVersionsFile -Append
	'MSXML DLL Versions: ' | Out-File $WuaVersionsFile -Append
	'--------------------' | Out-File $WuaVersionsFile -Append
	Get-ChildItem (Join-Path $Env:windir 'system32\msxml*.dll') -ErrorAction SilentlyContinue | `
		ForEach-Object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_) } | `
		Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
		Out-File $WuaVersionsFile -Append -Width 1000

	# Security Descriptors
	$WuaSdFile = $Prefix + 'WUA_SecurityDesc.txt'
	$WuaFileBase = Split-Path -Leaf $WuaSdFile
	Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUA Related Security Descriptors' -Value "Review $WuaFileBase"
	'----------------------------------------------' | Out-File $WuaSdFile -Append
	'Security Descriptors for WU Related Services: ' | Out-File $WuaSdFile -Append
	"----------------------------------------------`n" | Out-File $WuaSdFile -Append
	LogInfo "[$LogPrefix] Get Security Descriptors."
	$Commands = @(
		"cmd /r sc sdshow wuauserv | Out-File -Append $WuaSdFile"
		"cmd /r sc sdshow bits | Out-File -Append $WuaSdFile"
		"cmd /r sc sdshow msiserver | Out-File -Append $WuaSdFile"
		"cmd /r sc sdshow Schedule | Out-File -Append $WuaSdFile"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	# Collect WU Registry keys
	#$WuaRegFile = $Prefix + 'reg_WU.txt' # declared in Update Sources section
	#$WuaRegFileBase = Split-Path -Leaf $WuaRegFile # declared in Update Sources section
	LogInfo ("[$LogPrefix] Export Windows Update Registry Information (Registry Keys).")
	$RegKeys = @(
		('HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate', "$WuaRegFile"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate', "$WuaRegFile")
	)
	FwExportRegistry $LogPrefix $RegKeys $ShowMessage=$True
	Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WU Registry Keys' -Value "Review $WuaRegFileBase"

	# Collect WUFB Registry keys
	$WuFBFile = $Prefix + 'reg_WUFB.txt'
	$WuFBFileBase = Split-Path -Leaf $WuFBFile
	LogInfo ("[$LogPrefix] Export Windows Update for Business Registry Information (Registry Keys).")
	$RegKeys = @(
		('HKLM:SOFTWARE\Microsoft\WindowsUpdate\UX', "$WuFBFile"),
		('HKLM:SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy', "$WuFBFile"),
		#('HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate', "$WuFBFile"),
		('HKLM:SOFTWARE\Microsoft\PolicyManager\default\Update', "$WuFBFile")
	)
	FwExportRegistry $LogPrefix $RegKeys $ShowMessage=$True
	Add-Member -InputObject $WuaInfo -MemberType NoteProperty -Name 'WUFB Registry Keys' -Value "Review $WuFBFileBase"

	# Output WUAInfo PSObject to Summary File
	$WuaInfo | Out-File $WuaSummaryFile -Append -Width 500

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMWUAInfo ---

#region --- Function Get-SCCMDoSvcInfo - Feature 494 ---
function Get-SCCMDoSvcInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'DoSvc'

	if ($OSVersion.Major -ge 10) {
		# Collect Delivery Optimization Information using the Get-DNDDoLogs function
		$RobocopyLog = $Prefix + '_robocopy.log'
		$ErrorFile = $Prefix + '_Errorout.txt'
		$Line = '--------------------------------------------------------------------------------------------------------'
		$DoSVCLogsDestinationPath = $Prefix + 'OS_DeliveryOptimization_Logs'
		$DoSVCLogsZipFile = $Prefix + 'OS_DeliveryOptimization_Logs.zip'
		$TmpPrefix = $Prefix + 'CMClient_'
		$TempDir = $DoSVCLogsDestinationPath
		LogInfo "Delivery Optimization Logs Directory: $DoSVCLogsDestinationPath"
		FwCreateFolder "$DoSVCLogsDestinationPath"

		LogInfo "[$LogPrefix] Calling Get-DNDDoLogs function."
		Get-DNDDoLogs $TmpPrefix $TempDir $RobocopyLog $ErrorFile $Line $false

		# move all files from DOSVC folder to TempDir
		if (Test-Path "$TempDir\DOSVC" -PathType Container) {
			$files = Get-ChildItem -Path "$TempDir\DOSVC" -File
			if ($files.Count -gt 0) {
				# Move all files from DOSVC folder to TempDir
				Move-Item -Path "$TempDir\DOSVC\*" -Destination $TempDir -Force
			}
			# Delete the empty DOSVC folder
			$files = Get-ChildItem -Path "$TempDir\DOSVC" -File
			if ($files.Count -eq 0) { Remove-Item -Path "$TempDir\DOSVC" -Force -Recurse }
		}

		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $DoSVCLogsDestinationPath"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($DoSVCLogsDestinationPath, $DoSVCLogsZipFile)
			# Cleanup the destination folder
			if ($DoSVCLogsDestinationPath) {
				Remove-Item -Path $DoSVCLogsDestinationPath -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $DoSVCLogsDestinationPath" $_
		}

	} else {
		LogInfo "[$LogPrefix] Delivery Optimization Service not available on this OS version."
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMDoSvcInfo - Feature 494 ---

#region --- Function Get-SCCMROIScan ---
function Get-SCCMROIScan {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$ROIScanOutFolder
	)

	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'ROIScan'
	# TODO: using old ROIScan.vbs, consider rewriting in PowerShell
	# Robust Office Inventory Scan (ROIScan.vbs)
	if (Test-Path -Path "$global:ScriptFolder\psSDP\Diag\global\ROIScan.vbs") {
		try {
			Push-Location -Path "$global:Scriptfolder\psSDP\Diag\global"
			$CommandToExecute = "cscript.exe //e:vbscript $global:Scriptfolder\psSDP\Diag\global\ROIScan.vbs /quiet /logfolder $ROIScanOutFolder"
			LogInfo "[$LogPrefix] ROIScan.vbs starting..."
			LogInfoFile "[$LogPrefix] $CommandToExecute"
			Invoke-Expression -Command $CommandToExecute >$null 2>> $ErrorFile
		}
		catch { LogException ("[$LogPrefix] An Exception happend in ROIScan.vbs") $_ }
		Pop-Location
		LogInfo "[$LogPrefix] ROIScan.vbs completed."
	}
	else { LogInfo "[$LogPrefix] ROIScan.vbs not found - skipping..." }

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMROIScan ---

#region --- Function Get-SCCMClientInfo ---
function Get-SCCMClientInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'SCCMClientInfo'
	LogInfo "[$LogPrefix] Getting Client Information"

	# Current Time:
	AddTo-CMClientSummary -Name 'Current Time' -Value $CurrentTime

	# Computer Name
	AddTo-CMClientSummary -Name 'Client Name' -Value $Env:COMPUTERNAME

	# Assigned Site Code
	$Temp = Get-RegValue ($Reg_SMS + '\Mobile Client') 'AssignedSiteCode'
	if ($null -ne $Temp) {
		AddTo-CMClientSummary -Name 'Assigned Site Code' -Value $Temp
	}
	else {
		AddTo-CMClientSummary -Name 'Assigned Site Code' -Value 'Error obtaining value from Registry'
	}

	# Current Management Point
	$Temp = Get-CimInstance -Namespace 'root\CCM' -Class SMS_Authority -ErrorAction SilentlyContinue
	if ($Temp -is [CimInstance]) {
		AddTo-CMClientSummary -Name 'Current MP' -Value $Temp.CurrentManagementPoint
	}
	else {
		AddTo-CMClientSummary -Name 'Current MP' -Value 'Error obtaining value from SMS_Authority WMI Class'
	}

	# Client Version
	$Temp = Get-CimInstance -Namespace 'root\CCM' -Class SMS_Client -ErrorAction SilentlyContinue
	if ($Temp -is [CimInstance]) {
		AddTo-CMClientSummary -Name 'Client Version' -Value $Temp.ClientVersion
	}
	else {
		AddTo-CMClientSummary -Name 'Client Version' -Value 'Error obtaining value from SMS_Client WMI Class'
	}

	# Installation Directory - defined in utils_ConfigMgr07.ps1
	if ($null -ne $CCMInstallDir) {
		AddTo-CMClientSummary -Name 'Installation Directory' -Value $CCMInstallDir
	}
	else {
		AddTo-CMClientSummary -Name 'Installation Directory' -Value 'Error obtaining value'
	}

	# Client GUID
	$Temp = Get-CimInstance -Namespace 'root\CCM' -Class CCM_Client -ErrorAction SilentlyContinue
	if ($Temp -is [CimInstance]) {
		AddTo-CMClientSummary -Name 'Client ID' -Value $Temp.ClientId
		AddTo-CMClientSummary -Name 'Previous Client ID (if any)' -Value $Temp.PreviousClientId
		AddTo-CMClientSummary -Name 'Client ID Change Date' -Value $Temp.ClientIdChangeDate
	}
	else {
		AddTo-CMClientSummary -Name 'Client ID Information' -Value 'Error Obtaining value from CCM_Client WMI Class'
	}

	# CCMExec Service Status
	$Temp = Get-Service | Where-Object { $_.Name -eq 'CCMExec' } | Select-Object Status
	if ($null -ne $Temp) {
		if ($Temp.Status -eq 'Running') {
			$Temp2 = Get-Process | Where-Object { $_.ProcessName -eq 'CCMExec' } | Select-Object StartTime
			AddTo-CMClientSummary -Name 'CCMExec Status' -Value "Running. StartTime = $($Temp2.StartTime)"
		}
		else {
			AddTo-CMClientSummary -Name 'CCMExec Status' -Value $Temp.Status
		}
	}
	else {
		AddTo-CMClientSummary -Name 'CCMExec Service Status' -Value 'ERROR: Service Not found'
	}

	LogInfo "[$LogPrefix] Getting Software Distribution and Application Execution History"

	# Software Distribution Execution History from Registry
	$Temp = ($Reg_SMS -replace 'HKLM\\', 'HKLM:\') + '\Mobile Client\Software Distribution\Execution History'
	if (Check-RegKeyExists $Temp) {
		$ExecHistory = $Prefix + 'CMClient_ExecutionHistory.txt'
		$ExecHistoryBase = Split-Path -Leaf $ExecHistory
		Get-ChildItem $Temp -Recurse `
		| ForEach-Object { Get-ItemProperty $_.PSPath } `
		| Select-Object @{name = 'Path'; exp = { $_.PSPath.Substring($_.PSPath.LastIndexOf('History\') + 8) } }, _ProgramID, _State, _RunStartTime, SuccessOrFailureCode, SuccessOrFailureReason `
		| Out-File $ExecHistory -Append -Width 500
		AddTo-CMClientSummary -Name 'ExecMgr History' -Value ("Review $ExecHistoryBase") -NoToSummaryReport
	}
	else {
		AddTo-CMClientSummary -Name 'ExecMgr History' -Value 'Execution History not found' -NoToSummaryReport
	}

	# Application Enforce Status from WMI
	$Temp = Get-CimInstance -Namespace 'root\CCM\CIModels' -Class CCM_AppEnforceStatus -ErrorVariable WMIError -ErrorAction SilentlyContinue
	if ($WMIError.Count -eq 0) {
		if ($null -ne $Temp) {
			$AppHist = $Prefix + 'CMClient_AppHistory.txt'
			$AppHistBase = Split-Path -Leaf $AppHist
			$Temp | Select-Object AppDeliveryTypeId, ExecutionStatus, ExitCode, Revision, ReconnectData `
			| Out-File $AppHist -Append -Width 250
			AddTo-CMClientSummary -Name 'App Execution History' -Value ("Review $AppHistBase") -NoToSummaryReport
		}
		else {
			AddTo-CMClientSummary -Name 'App Execution History' -Value ('Error obtaining data or no data in WMI') -NoToSummaryReport
		}
	}
	else {
		AddTo-CMClientSummary -Name 'App Execution History' -Value ('ERROR: ' + $WMIError[0].Exception.Message) -NoToSummaryReport
		$WMIError.Clear()
	}

	# Cache Information
	$Temp = Get-CimInstance -Namespace 'root\ccm\softmgmtagent' -Class CacheConfig -ErrorVariable WMIError -ErrorAction SilentlyContinue
	if ($WMIError.Count -eq 0) {
		if ($null -ne $Temp) {
			$CacheInfo = $Prefix + 'CMClient_CacheInfo.txt'
			$CacheInfoBase = Split-Path -Leaf $CacheInfo
			'Cache Config:' | Out-File $CacheInfo
			'==================' | Out-File $CacheInfo -Append
			$Temp | Select-Object Location, Size, NextAvailableId | Format-List * | Out-File $CacheInfo -Append -Width 500
			'Cache Elements:' | Out-File $CacheInfo -Append
			'===============' | Out-File $CacheInfo -Append
			$Temp = Get-CimInstance -Namespace 'root\ccm\softmgmtagent' -Class CacheInfoEx -ErrorAction SilentlyContinue
			$Temp | Select-Object Location, ContentId, CacheID, ContentVer, ContentSize, LastReferenced, PeerCaching, ContentType, ReferenceCount, PersistInCache `
			| Sort-Object -Property Location | Format-Table -AutoSize | Out-File $CacheInfo -Append -Width 500
			AddTo-CMClientSummary -Name 'Cache Information' -Value ("Review $CacheInfoBase") -NoToSummaryReport
		}
		else {
			AddTo-CMClientSummary -Name 'Cache Information' -Value 'No data found in WMI.' -NoToSummaryReport
		}
	}
	else {
		AddTo-CMClientSummary -Name 'Cache Information' -Value ('ERROR: ' + $WMIError[0].Exception.Message) -NoToSummaryReport
		$WMIError.Clear()
	}

	# Inventory Timestamps from InventoryActionStatus
	$Temp = Get-CimInstance -Namespace 'root\ccm\invagt' -Class InventoryActionStatus -ErrorVariable WMIError -ErrorAction SilentlyContinue
	if ($WMIError.Count -eq 0) {
		if ($null -ne $Temp) {
			$InvVersion = $Prefix + 'CMClient_InventoryVersions.txt'
			$InvVersionBase = Split-Path -Leaf $InvVersion
			$Temp | Select-Object InventoryActionID, @{name = 'LastCycleStartedDate(LocalTime)'; expression = { $_.LastCycleStartedDate } }, LastMajorReportversion, LastMinorReportVersion, @{name = 'LastReportDate(LocalTime)'; expression = { $_.LastReportDate } } `
			| Out-File $InvVersion -Append
			AddTo-CMClientSummary -Name 'Inventory Versions' -Value ("Review $InvVersionBase") -NoToSummaryReport
		}
		else {
			AddTo-CMClientSummary -Name 'Inventory Versions' -Value 'No data found in WMI.' -NoToSummaryReport
		}
	}
	else {
		AddTo-CMClientSummary -Name 'Inventory Versions' -Value ('ERROR: ' + $WMIError[0].Exception.Message) -NoToSummaryReport
		$WMIError.Clear()
	}

	LogInfo "[$LogPrefix] Getting Software Update Status and State Messages"
	# Update Status from CCM_UpdateStatus
	$UpdStatus = $Prefix + 'CMClient_CCM-UpdateStatus.txt'
	$UpdStatusBase = Split-Path -Leaf $UpdStatus
	'=================================' | Out-File $UpdStatus
	' CCM_UpdateStatus' | Out-File $UpdStatus -Append
	'=================================' | Out-File $UpdStatus -Append
	$Temp = Get-CimInstance -Namespace 'root\CCM\SoftwareUpdates\UpdatesStore' -Class CCM_UpdateStatus -ErrorVariable WMIError -ErrorAction SilentlyContinue
	if ($WMIError.Count -eq 0) {
		if ($null -ne $Temp) {
			$Temp	| Select-Object UniqueID, Article, Bulletin, RevisionNumber, Status, @{name = 'ScanTime(LocalTime)'; expression = { $_.ScanTime } }, ExcludeForStateReporting, Title, SourceUniqueId `
			| Sort-Object -Property Article, UniqueID -Descending | Format-Table -AutoSize | Out-File $UpdStatus -Append -Width 500
			AddTo-CMClientSummary -Name 'CCM Update Status' -Value ("Review $UpdStatusBase") -NoToSummaryReport
		}
		else {
			AddTo-CMClientSummary -Name 'CCM Update Status' -Value ('No data in WMI') -NoToSummaryReport
			Write-Output 'No data in WMI' | Out-File $UpdStatus -Append -Width 500
		}
	}
	else {
		AddTo-CMClientSummary -Name 'CCM Update Status' -Value ('ERROR: ' + $WMIError[0].Exception.Message) -NoToSummaryReport
		Write-Output "ERROR:  $WMIError[0].Exception.Message" | Out-File $UpdStatus -Append -Width 500
		$WMIError.Clear()
	}

	# State Messages from CCM_StateMsg
	$StateMsg = $Prefix + 'CMClient_CCM-StateMsg.txt'
	$StateMsgBase = Split-Path -Leaf $StateMsg
	'=================================' | Out-File $StateMsg
	' CCM_StateMsg ' | Out-File $StateMsg -Append
	'=================================' | Out-File $StateMsg -Append
	$Temp = Get-CimInstance -Namespace 'root\CCM\StateMsg' -Class CCM_StateMsg -ErrorVariable WMIError -ErrorAction SilentlyContinue
	if ($WMIError.Count -eq 0) {
		if ($null -ne $Temp) {
			$Temp	| Select-Object TopicID, TopicType, TopicIDType, StateID, Priority, MessageSent, @{name = 'MessageTime(LocalTime)'; expression = { $_.MessageTime } } `
			| Sort-Object -Property TopicType, TopicID | Format-Table -AutoSize | Out-File $StateMsg -Append -Width 500
			AddTo-CMClientSummary -Name 'CCM State Messages' -Value ("Review $StateMsgBase") -NoToSummaryReport
		}
		else {
			AddTo-CMClientSummary -Name 'CCM State Messages' -Value ('No data in WMI') -NoToSummaryReport
			Write-Output 'No data in WMI' | Out-File $StateMsg -Append -Width 500
		}
	}
	else {
		AddTo-CMClientSummary -Name 'CCM State Messages' -Value ('ERROR: ' + $WMIError[0].Exception.Message) -NoToSummaryReport
		Write-Output "ERROR:  $WMIError[0].Exception.Message" | Out-File $StateMsg -Append -Width 500
		$WMIError.Clear()
	}

	LogInfo "[$LogPrefix] Getting WMI Data from Client"

	# DCM
	$OutputFile = $Prefix + 'CMClient_CCM-DesiredConfiguration.TXT'
	$OutputFileBase = Split-Path -Leaf $OutputFile
	Get-CimOutput -Namespace 'ROOT\ccm\dcm' -ClassName SMS_DesiredConfiguration -FormatList | Sort-Object -Property DisplayName | Out-File $OutputFile -Width 200 -Append
	AddTo-CMClientSummary -Name 'Desired Configuration' -Value ("Review $OutputFileBase") -NoToSummaryReport

	# Deployments
	$OutputFile = $Prefix + 'CMClient_CCM-MachineDeployments.TXT'
	$OutputFileBase = Split-Path -Leaf $OutputFile
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -DisplayName 'Update Deployments' -Query 'SELECT AssignmentID, AssignmentAction, AssignmentName, StartTime, EnforcementDeadline, SuppressReboot, NotifyUser, OverrideServiceWindows, RebootOutsideOfServiceWindows, UseGMTTimes, WoLEnabled FROM CCM_UpdateCIAssignment' `
		-FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -DisplayName 'Application Deployments (Machine only)' -Query 'SELECT AssignmentID, AssignmentAction, AssignmentName, StartTime, EnforcementDeadline, SuppressReboot, NotifyUser, OverrideServiceWindows, RebootOutsideOfServiceWindows, UseGMTTimes, WoLEnabled FROM CCM_ApplicationCIAssignment' `
		-FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -DisplayName 'DCM Deployments (Machine only)' -Query 'SELECT AssignmentID, AssignmentAction, AssignmentName, StartTime, EnforcementDeadline, SuppressReboot, NotifyUser, OverrideServiceWindows, RebootOutsideOfServiceWindows, UseGMTTimes, WoLEnabled FROM CCM_DCMCIAssignment' `
		-FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -DisplayName 'Package Deployments (Machine only)' -Query 'SELECT PKG_PackageID, ADV_AdvertisementID, PRG_ProgramName, PKG_Name, PRG_CommandLine, ADV_MandatoryAssignments, ADV_ActiveTime, ADV_ActiveTimeIsGMT, ADV_RCF_InstallFromLocalDPOptions, ADV_RCF_InstallFromRemoteDPOptions, ADV_RepeatRunBehavior, PRG_MaxDuration, PRG_PRF_RunWithAdminRights, PRG_PRF_AfterRunning FROM CCM_SoftwareDistribution' `
		-FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -DisplayName 'Task Sequence Deployments' -Query 'SELECT PKG_PackageID, ADV_AdvertisementID, PRG_ProgramName, PKG_Name, TS_BootImageID, TS_Type, ADV_MandatoryAssignments, ADV_ActiveTime, ADV_ActiveTimeIsGMT, ADV_RCF_InstallFromLocalDPOptions, ADV_RCF_InstallFromRemoteDPOptions, ADV_RepeatRunBehavior, PRG_MaxDuration FROM CCM_TaskSequence' `
		-FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_ServiceWindow -FormatTable | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_RebootSettings -FormatTable | Out-File $OutputFile -Append
	AddTo-CMClientSummary -Name 'Machine Deployments' -Value ("Review $OutputFileBase") -NoToSummaryReport

	# Client Agent Configs
	$OutputFile = $Prefix + 'CMClient_CCM-ClientAgentConfig.TXT'
	$OutputFileBase = Split-Path -Leaf $OutputFile
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_ClientAgentConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_SoftwareUpdatesClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_ApplicationManagementClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_SoftwareDistributionClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_Logging_GlobalConfiguration -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_PolicyAgent_Configuration -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_Service_ResourceProfileConfiguration -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_ConfigurationManagementClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_HardwareInventoryClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_SoftwareInventoryClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_SuperPeerClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_EndpointProtectionClientConfig -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\Policy\Machine\ActualConfig' -ClassName CCM_AntiMalwarePolicyClientConfig -FormatList | Out-File $OutputFile -Append
	AddTo-CMClientSummary -Name 'Client Agent Configs' -Value ("Review $OutputFileBase") -NoToSummaryReport

	# Various WMI classes
	$OutputFile = $Prefix + 'CMClient_CCM-ClientMPInfo.TXT'
	$OutputFileBase = Split-Path -Leaf $OutputFile
	Get-CimOutput -Namespace 'root\CCM' -ClassName SMS_Authority -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName CCM_Authority -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName SMS_LocalMP -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName SMS_LookupMP -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName SMS_MPProxyInformation -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName CCM_ClientSiteMode -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName SMS_Client -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName ClientInfo -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName SMS_PendingReRegistrationOnSiteReAssignment -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM' -ClassName SMS_PendingSiteAssignment -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\LocationServices' -ClassName SMS_ActiveMPCandidate -FormatList | Out-File $OutputFile -Append
	Get-CimOutput -Namespace 'root\CCM\LocationServices' -DisplayName 'SMS_MPInformation' -Query 'SELECT MP, MPLastRequestTime, MPLastUpdateTime, SiteCode, Reserved2 FROM SMS_MPInformation' -FormatList | Out-File $OutputFile -Append
	AddTo-CMClientSummary -Name 'MP Information' -Value ("Review $OutputFileBase") -NoToSummaryReport

	# Write Progress
	LogInfo "[$LogPrefix] Getting File Versions"
	# Binary Versions List
	$OutputFile = $Prefix + 'CMClient_FileVersions.TXT'
	$OutputFileBase = Split-Path -Leaf $OutputFile
	Get-ChildItem ($CCMInstallDir) -Recurse -Include *.dll, *.exe -ErrorVariable DirError -ErrorAction SilentlyContinue | `
		ForEach-Object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_) } | `
		Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize | `
		Out-File $OutputFile -Width 1000
	AddTo-CMClientSummary -Name 'File Versions' -Value ("Review $OutputFileBase") -NoToSummaryReport

	#LogInfo "[$LogPrefix] Directory Errors = ${$DirError.Count}"
	if ($DirError.Count -gt 0) {
		#If there were errors report them
		$dirErrorStr = $DirError[0].Exception.Message
		for ($i = 1; $i -lt $DirError.Count; $i++) { #($e in $DirError)
			$dirErrorStr += '`n' + $DirError[$i].Exception.Message
		}
		#AddTo-CMClientSummary -Name 'Directory Errors getting File Versions' -Value ('ERROR: ' + $e.Exception.Message) -NoToSummaryReport
		AddTo-CMClientSummary -Name 'Directory Errors getting File Versions' -Value $dirErrorStr -NoToSummaryReport
		$DirError.Clear()
	}

	# Collect Client Information
	# What happens with $global:CMClientFileSummaryPSObject and $global:CMClientReportSummaryPSObject in the end?
	# Moved to DC_FinishExecution => See function Invoke-SCCMFinalize
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMClientInfo ---

#region --- Function Get-SCCMBitLockerInfo ---
function Get-SCCMBitLockerInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'BitLocker'
	LogInfo "[$LogPrefix] Getting BitLocker Information"

	# Collect BitLocker Information using the Get-DNDBitlockerInfo function
	$RobocopyLog = $Prefix + '_robocopy.log'
	$ErrorFile = $Prefix + '_Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	$BitLockerLogsDestinationPath = $Prefix + 'OS_Bitlocker_Logs'
	$BitLockerLogsZipFile = $Prefix + 'OS_Bitlocker_Logs.zip'
	$TmpPrefix = $Prefix + 'CMClient_'
	$TempDir = $BitLockerLogsDestinationPath
	LogInfo "BitLocker Logs Directory: $BitLockerLogsDestinationPath"

	LogInfo "[$LogPrefix] Getting BitLocker registry entries, keyprotector, Manage-BDE output, and MBAM registry keys, and TPM information"
	Get-DNDBitlockerInfo $TmpPrefix $TempDir $RobocopyLog $ErrorFile $Line $false

	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths.add(@("$Env:windir\system32\winevt\logs\Microsoft-Windows-BitLocker%4BitLocker Management.evtx", "$BitLockerLogsDestinationPath"))
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

	# Compress the destination folder into a ZIP file
	try {
		LogInfo "Compressing $BitLockerLogsDestinationPath"
		Add-Type -Assembly 'System.IO.Compression.FileSystem'
		[System.IO.Compression.ZipFile]::CreateFromDirectory($BitLockerLogsDestinationPath, $BitLockerLogsZipFile)
		# Cleanup the destination folder
		if ($BitLockerLogsDestinationPath) {
			Remove-Item -Path $BitLockerLogsDestinationPath -Recurse -Force
		}
	}
	catch {
		LogException "Failed to compress $BitLockerLogsDestinationPath" $_
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMBitLockerInfo ---

#region --- Get-SCCMHierarchyInfo ---
function Get-SCCMHierarchyInfo {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$HierarchyFile
	)
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'HierarchyInfo'
	LogInfo "[$LogPrefix] Getting Hierarchy Information."

	$ErrorActionPreference = 'stop'
	$provRemote = $false

	# ensure we have the site code or exit
	if (!(Test-Path variable:siteCode) -or ([string]::IsNullOrEmpty($siteCode))) {
		$siteCode = Get-RegValueWithError ($Reg_SMS + '\Identification') 'Site Code'
		if ($siteCode -like '*ERROR*') {
			LogInfo "[$LogPrefix] Site code could not be determined. Script is probably not running on a site server or SMS Provider."; return
		}
	}

	$smsProv = "ROOT\SMS\site_$siteCode"
	$localFQDN = [System.Net.Dns]::GetHostByName($env:COMPUTERNAME).HostName

	LogInfo "[$LogPrefix] Retrieving site(s) details"
	# always try local WMI, as $provServer might point to remote one in case of multiple SMS Provider
	$sites = Get-CimInstance -Namespace $smsProv -Class SMS_Site -ErrorAction SilentlyContinue -ErrorVariable SMS_Site_Err

	if (!$sites) {
		# exit in case SMS Provider could not be determined
		if (!(Test-Path variable:provServer) -or ([string]::IsNullOrEmpty($provServer))) {
			LogWarn "[$LogPrefix] Configuration Manager SMS Provider not detected, or not accessible."
			return
		}
		elseif (($SMS_Site_Err[0].Exception.HResult -eq -2146233087) -and ($provServer -ne $localFQDN)) {
			# try remote SMS Provider if local WMI namespace was not found
			try {
				$provRemote = $true
				LogInfo "No local SMS provider. Trying computer $provServer"
				$sites = Get-WmiObject -ComputerName $provServer -Namespace $smsProv -Class SMS_Site
			}
			catch {
				LogException "Exception while trying to connect to WMI at $provRemote" $_
				return
			}
		}
		else {
			LogWarn "SMS_Site_Err: $($SMS_Site_Err[0])"
			return
		}
	}

	# Type 4 = CAS, Type 2 = primary site, Type 1 = secondary site
	# do NOT change the sort order, otherwise the site map might be corrupted
	$sites = $sites | Sort-Object @{ e = 'Type'; desc = $true }, SiteCode, ServerName

	# get secondary sites
	# ensure an array is returned, as we need the count property later
	$secSites = @($sites | Where-Object Type -EQ 1 | Sort-Object ReportingSiteCode, SiteCode, ServerName)

	# check HA -> Type 8 -> (likely) passive node, and get Setup Info
	# https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/servers/configure/sms_sci_sysresuse-server-wmi-class
	LogInfo "[$LogPrefix] Retrieving setup info & passive nodes (if any)"
	try {
		if (!$provRemote) {
			# get MEMCM version and build number
			$setupInfo = [wmi]"$($smsProv):SMS_SetupInfo.id='RELEASEVERSION'"

			# get passive nodes
			$passiveNodes = Get-CimInstance -Namespace $smsProv `
				-Query "SELECT * FROM SMS_SCI_SysResUse where RoleName = 'SMS Site Server' and Type = 8"
		}
		# remote sms provider
		else {
			$setupInfo = [wmi]"\\$provServer\$($smsProv):SMS_SetupInfo.id='RELEASEVERSION'"
			$passiveNodes = Get-WmiObject -ComputerName $provServer -Namespace $smsProv `
				-Query "SELECT * FROM SMS_SCI_SysResUse where RoleName = 'SMS Site Server' and Type = 8"
		}
	}
	catch { LogException "[$LogPrefix] Retrieving setup info & passive nodes (if any)" $_ }

	### generate output ###
	$tab = ''
	$secIndex = 0
	$casFound = $false

	LogInfo "[$LogPrefix] Generating output"
	"Running on Computer: $localFQDN" | Out-File $HierarchyFile -Force

	@"
Release Version: $($setupInfo.Value1), build $($setupInfo.Value2)
Site Code: $siteCode

===================
[Hierarchy Details]
===================

"@ | Out-File $HierarchyFile -Append

	if (!(Test-Path variable:passiveNodes)) { "NOTE: Failed to check for passive nodes!`r`n" | Out-File $HierarchyFile -Append }
	foreach ($site in $sites) {

		if ($site.Type -eq 4) {
			$casFound = $true
			$siteType = 'Central Admin Site'
		}
		elseif ($site.Type -eq 2) {
			$siteType = 'Primary Site'
			if ($casFound) { $tab = "`t" }
		}
		# loop through CAS & primary sites only
		else { break }

		# CAS or primary
		Export-SiteInfo $site -ExportFile $HierarchyFile

		# passive node
		if ((Test-Path variable:passiveNodes) -and ($passiveNodes) -and ($passiveNodes.SiteCode -contains $site.SiteCode)) {
			"$($tab)Passive Node: $(($passiveNodes | Where-Object SiteCode -EQ $site.SiteCode).NetworkOSPath.Replace('\\',''))" |
			Out-File $HierarchyFile -Append
		}

		'' | Out-File $HierarchyFile -Append

		# loop through secondary sites starting with last position where we left off
		if (($secSites) -and ($site.Type -eq 2)) {

			$secSiteFound = $false

			for ($i = $secIndex; $i -lt $secSites.Count ; $i++) {
				if ($secSites[$i].ReportingSiteCode -eq $site.SiteCode) {
					$secSiteFound = $true
					Export-SiteInfo $secSites[$i] -isSec -ExportFile $HierarchyFile
					'' | Out-File $HierarchyFile -Append
				}
				elseif ($secSiteFound) { break }
			}

			if ($secSiteFound) { $secIndex = $i }
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}

#endregion --- Get-SCCMHierarchyInfo ---

#region --- Function Get-SCCMSiteServerInfo ---
function Get-SCCMSiteServerInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	if ($Is_SiteServer) {
		$LogPrefix = 'SiteServer'
		LogInfo "[$LogPrefix] Getting SiteServer Information."

		# Current Time:
		AddTo-CMServerSummary -Name 'Current Time' -Value $CurrentTime
		# Computer Name
		AddTo-CMServerSummary -Name 'Server Name' -Value $ComputerName
		# Site Code
		$Temp = Get-RegValueWithError ($Reg_SMS + '\Identification') 'Site Code'
		AddTo-CMServerSummary -Name 'Site Code' -Value $Temp
		# Site Code
		$Temp = Get-RegValueWithError ($Reg_SMS + '\Identification') 'Parent Site Code'
		AddTo-CMServerSummary -Name 'Parent Site Code' -Value $Temp

		# Site Type
		# $SiteType = Get-RegValueWithError ($Reg_SMS + '\Setup') 'Type'
		if ($SiteType -eq 8) {
			AddTo-CMServerSummary -Name 'Site Type' -Value 'Central Administration Site'
		}
		elseif ($SiteType -eq 1) {
			AddTo-CMServerSummary -Name 'Site Type' -Value 'Primary Site'
		}
		elseif ($SiteType -eq 2) {
			AddTo-CMServerSummary -Name 'Site Type' -Value 'Secondary Site'
		}
		else {
			AddTo-CMServerSummary -Name 'Site Type' -Value $SiteType
		}

		# Site Version
		$Temp = Get-RegValueWithError ($Reg_SMS + '\Setup') 'Full Version'
		AddTo-CMServerSummary -Name 'Site Version' -Value $Temp

		# Monthly Version
		if ($global:SiteType -eq 2) {
			AddTo-CMServerSummary -Name 'MonthlyReleaseVersion' -Value 'Not Available on a Secondary Site'
		}
		else {
			$Temp = Get-CimInstance -Computer $SMSProviderServer -Namespace $SMSProviderNamespace -Class SMS_Identification -ErrorAction SilentlyContinue
			if ($Temp -is [CimInstance]) {
				AddTo-CMServerSummary -Name 'MonthlyReleaseVersion' -Value $Temp.MonthlyReleaseVersion
			}
			else {
				AddTo-CMServerSummary -Name 'MonthlyReleaseVersion' -Value 'Not Available'
   }
		}

		# CU Level
		$Temp = Get-RegValueWithError ($Reg_SMS + '\Setup') 'CULevel'
		AddTo-CMServerSummary -Name 'CU Level' -Value $Temp

		# ADK Version
		$global:ADKVersion = Get-ADKVersion
		AddTo-CMServerSummary -Name 'ADK Version' -Value $global:ADKVersion

		# Installation Directory - defined in utils_ConfigMgr12.ps1
		if ($null -ne $SMSInstallDir) {
			AddTo-CMServerSummary -Name 'Installation Directory' -Value $SMSInstallDir
		}
		else {
			AddTo-CMServerSummary -Name 'Installation Directory' -Value 'Error obtaining value from Registry'
  }

		# Provider Location
		if ($global:SiteType -eq 2) {
			AddTo-CMServerSummary -Name 'Provider Location' -Value 'Not available on a Secondary Site'
		}
		else {
			if ($null -ne $global:SMSProviderServer) {
				AddTo-CMServerSummary -Name 'Provider Location' -Value $SMSProviderServer
			}
			else {
				AddTo-CMServerSummary -Name 'Provider Location' -Value 'Error obtaining value from Registry'
   }
		}

		# SQL Server
		$Temp = Get-RegValue ($Reg_SMS + '\SQL Server\Site System SQL Account') 'Server'
		AddTo-CMDatabaseSummary -Name 'SQL Server' -Value $Temp -NoToSummaryQueries

		# Database Name
		$Temp = Get-RegValueWithError ($Reg_SMS + '\SQL Server\Site System SQL Account') 'Database Name'
		AddTo-CMDatabaseSummary -Name 'Database Name' -Value $Temp -NoToSummaryQueries

		# SQL Ports
		$Temp = Get-RegValueWithError ($Reg_SMS + '\SQL Server\Site System SQL Account') 'Port'
		AddTo-CMDatabaseSummary -Name 'SQL Port' -Value $Temp -NoToSummaryQueries

		$Temp = Get-RegValueWithError ($Reg_SMS + '\SQL Server\Site System SQL Account') 'SSBPort'
		AddTo-CMDatabaseSummary -Name 'SSB Port' -Value $Temp -NoToSummaryQueries

		# SMSExec Service Status
		LogInfo "[$LogPrefix] Getting SMSExec Service Status."
		$Temp = Get-Service | Where-Object { $_.Name -eq 'SMS_Executive' } | Select-Object Status
		if ($null -ne $Temp) {
			if ($Temp.Status -eq 'Running') {
				$Temp2 = Get-Process | Where-Object { $_.ProcessName -eq 'SMSExec' } | Select-Object StartTime
				AddTo-CMServerSummary -Name 'SMS_Executive Status' -Value "Running. StartTime = $($Temp2.StartTime)"
			}
			else {
				AddTo-CMServerSummary -Name 'SMS_Executive Status' -Value $Temp.Status
			}
		}
		else {
			AddTo-CMServerSummary -Name 'SMS_Executive Status' -Value 'ERROR: Service Not found'
		}

		# SiteComp Service Status
		LogInfo "[$LogPrefix] Getting SiteComp Service Status."
		$Temp = Get-Service | Where-Object { $_.Name -eq 'SMS_SITE_COMPONENT_MANAGER' } | Select-Object Status
		if ($null -ne $Temp) {
			if ($Temp.Status -eq 'Running') {
				$Temp2 = Get-Process | Where-Object { $_.ProcessName -eq 'SiteComp' } | Select-Object StartTime
				AddTo-CMServerSummary -Name 'SiteComp Status' -Value "Running. StartTime = $($Temp2.StartTime)"
			}
			else {
				AddTo-CMServerSummary -Name 'SiteComp Status' -Value $Temp.Status
			}
		}
		else {
			AddTo-CMServerSummary -Name 'SiteComp Status' -Value 'ERROR: Service Not found'
		}

		# SMSExec Thread States
		LogInfo "[$LogPrefix] Getting SMSExec Thread States."
		$ThreadsFile = $Prefix + 'CMServer_SMSExecThreads.TXT'
		$ThreadsFileBase = Split-Path -Leaf $ThreadsFile
		Get-ItemProperty 'HKLM:\Software\Microsoft\SMS\Components\SMS_Executive\Threads\*' -ErrorAction SilentlyContinue -ErrorVariable DirError `
		| Select-Object @{Name = 'SMS_COMPONENT'; Expression = { $_.PSChildName } }, 'Current State', 'Startup Type', 'Requested Operation', DLL `
		| Sort-Object @{Expression = 'Current State'; Descending = $true }, @{Expression = 'SMS_COMPONENT'; Ascending = $true } `
		| Format-Table -AutoSize | Out-String -Width 200 | Out-File -FilePath $ThreadsFile
		if ($DirError.Count -eq 0) {
			AddTo-CMServerSummary -Name 'SMSExec Thread States' -Value "Review $ThreadsFileBase" -NoToSummaryReport
		}
		else {
			AddTo-CMServerSummary -Name 'SMSExec Thread States' -Value ('ERROR: ' + $DirError[0].Exception.Message) -NoToSummaryReport
			$DirError.Clear()
		}

		LogInfo "[$LogPrefix] Getting Site Hierarchy"
		# Hierarchy Details
		$HierarchyFile = $Prefix + 'CMServer_Hierarchy.txt'
		#DONE: implemented GetCM12Hierarchy.ps1 in Get-SCCMHierarchyInfo
		Get-SCCMHierarchyInfo -HierarchyFile $HierarchyFile

		LogInfo "[$LogPrefix] Getting File Versions: $($SMSInstallDir)\bin"
		# Binary Versions List
		$FileVersionsFile = $Prefix + 'CMServer_FileVersions.txt'
		$FileVersionsFileBase = Split-Path -Leaf $FileVersionsFile
		Get-ChildItem ($SMSInstallDir + '\bin') -Recurse -Include *.dll, *.exe -ErrorVariable DirError -ErrorAction SilentlyContinue | `
			ForEach-Object { [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_) } | `
			Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize | `
			Out-File $FileVersionsFile -Width 1000
		if ($DirError.Count -eq 0) {
			AddTo-CMServerSummary -Name 'File Versions' -Value ("Review $FileVersionsFileBase") -NoToSummaryReport
		}
		else {
			AddTo-CMServerSummary -Name 'File Versions' -Value ('ERROR: ' + $DirError[0].Exception.Message) -NoToSummaryReport
			$DirError.Clear()
		}

		# RCM Inbox File List
		LogInfo "[$LogPrefix] Getting File List for $($SMSInstallDir)\inboxes\RCM.box"
		$RCMFile = $Prefix + 'CMServer_RCMFileList.TXT'
		$RCMFileBase = Split-Path -Leaf $RCMFile
		if ($null -ne (Get-ChildItem ($SMSInstallDir + '\inboxes\RCM.box') -Recurse)) {
			LogInfo "[$LogPrefix] RCM.box is not empty."
			Get-ChildItem ($SMSInstallDir + '\inboxes\RCM.box') -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
				Select-Object CreationTime, LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
				Out-File $RCMFile -Width 1000
			if ($DirError.Count -eq 0) {
				AddTo-CMServerSummary -Name 'RCM.box File List' -Value ("Review $RCMFileBase") -NoToSummaryReport
			}
			else {
				AddTo-CMServerSummary -Name 'RCM.box File List' -Value ('ERROR: ' + $DirError[0].Exception.Message) -NoToSummaryReport
				$DirError.Clear()
			}
		}

		# What happens with $global:CMClientFileSummaryPSObject and $global:CMClientReportSummaryPSObject in the end?
		# Moved to DC_FinishExecution => See function Invoke-SCCMFinalize

		# Server Info File is collected in DC_CM12SQLInfo.ps1. Need to make sure this function runs before that.
		# $ServerInfo | Out-File $ServerInfoFile -Append -Width 200
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMSiteServerInfo ---

#region --- Function Get-SCCMProviderInfo ---
function Get-SCCMProviderInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	if ($Is_SiteServer) {
		$LogPrefix = 'SMS Provider'
		LogInfo "[$LogPrefix] Getting SMS Provider Information."

		LogInfo "[$LogPrefix] SMS Provider: $global:SMSProviderServer"
		LogInfo "[$LogPrefix] SMS Provider Namespace: $global:SMSProviderNamespace"

		# Boundaries
		LogInfo "[$LogPrefix] Getting Boundaries from SMS Provider"
		$BoundariesFile = $Prefix + 'CMServer_Boundaries.txt'
		$BoundariesFileBase = Split-Path -Leaf $BoundariesFile
		$Temp = Get-Boundaries -SMSProvServer $global:SMSProviderServer -SMSProvNamespace $global:SMSProviderNamespace
		$Temp | Out-File $BoundariesFile -Append
		AddTo-CMServerSummary -Name 'Boundaries' -Value "Review $BoundariesFileBase" -NoToSummaryReport

		# Cloud Roles
		LogInfo "[$LogPrefix] Getting Cloud Services Data from SMS Provider"
		$CloudServicesFile = $Prefix + 'CMServer_CloudServices.txt'
		$CloudServicesFileBase = Split-Path -Leaf $CloudServicesFile
		Get-WmiOutput -ClassName SMS_Azure_CloudService -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_CloudSubscription -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_IntuneAccountInfo -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_CloudProxyConnector -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_CloudProxyRoleEndpoint -FormatTable | Out-File $CloudServicesFile -Append -Width 500
		Get-WmiOutput -ClassName SMS_CloudProxyEndpointDefinition -FormatTable | Out-File $CloudServicesFile -Append -Width 500
		Get-WmiOutput -ClassName SMS_CloudProxyExternalEndpoint -FormatTable | Out-File $CloudServicesFile -Append -Width 500
		Get-WmiOutput -ClassName SMS_AzureService -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_WSfBConfigurationData -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_OMSConfigurationData -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_OMSCollection -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_ReadinessDashboardConfigurationData -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_AfwAccountStatus -FormatList | Out-File $CloudServicesFile -Append
		Get-WmiOutput -ClassName SMS_MDMAppleVppToken -FormatList | Out-File $CloudServicesFile -Append
		AddTo-CMServerSummary -Name 'Cloud Services Info' -Value "Review $CloudServicesFileBase" -NoToSummaryReport

		# What happens with $global:CMServerFileSummaryPSObject and $global:CMServerReportSummaryPSObject in the end?
		# Moved to DC_FinishExecution => See function Invoke-SCCMFinalize
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMProviderInfo ---

#region --- Function Get-SCCMSQLInfo ---
function Get-SCCMSQLInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'SQL Info'
	#Only run if this is a site server. We can't run on only a site database server, because it requires us to know the site databasename, which isn't stored on a standalone DB.
	if (-not ($Is_SiteServer)) {
		LogInfo "This is not a Site Server. Exiting."
		return
	}

	#If this is running on a Site Server, then get the SQL Server information from the registry and collect logs
	LogInfo "[$LogPrefix] Getting Configuration Manager SQL Data Information."

	LogInfo "ConfigMgr SQL Server: $global:ConfigMgrDBServer"
	LogInfo "ConfigMgr SQL Database: $global:ConfigMgrDBName"

	if ($null -ne $global:DatabaseConnectionError) {
		LogWarn "SQL Connection Failed With Error: $global:DatabaseConnectionError"
		return
	}

	$Temp = Get-SQLValueWithError -SqlQuery "SELECT name, value_in_use FROM sys.configurations WHERE name = 'max server memory (MB)'" -ColumnName 'value_in_use' -DisplayText 'Max Server Memory (MB)'
	AddTo-CMDatabaseSummary -Name 'Max Memory (MB)' -Value $Temp -NoToSummaryQueries

	$Temp = Get-SQLValueWithError -SqlQuery "SELECT name, value_in_use FROM sys.configurations WHERE name = 'max degree of parallelism'" -ColumnName 'value_in_use' -DisplayText 'MDOP'
	AddTo-CMDatabaseSummary -Name 'MDOP' -Value $Temp -NoToSummaryQueries

	# Basic SQL Queries
	$BasicFile = $Prefix + 'SQL_Basic.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT @@SERVERNAME AS [Server Name], @@VERSION AS [SQL Version]' -outFile $BasicFile -DisplayText 'SQL Version'
	Run-SQLCommandtoFile -SqlQuery 'SELECT servicename, process_id, startup_type_desc, status_desc,
	last_startup_time, service_account, is_clustered, cluster_nodename, [filename]
	FROM sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE)' -outFile $BasicFile -DisplayText 'SQL Services' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT cpu_count AS [Logical CPU Count], scheduler_count, hyperthread_ratio AS [Hyperthread Ratio],
	cpu_count/hyperthread_ratio AS [Physical CPU Count],
	physical_memory_kb/1024 AS [Physical Memory (MB)], committed_kb/1024 AS [Committed Memory (MB)],
	committed_target_kb/1024 AS [Committed Target Memory (MB)],
	max_workers_count AS [Max Workers Count], affinity_type_desc AS [Affinity Type],
	sqlserver_start_time AS [SQL Server Start Time], virtual_machine_type_desc AS [Virtual Machine Type]
	FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE)' -outFile $BasicFile -DisplayText 'SQL Server Hardware Info' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'EXEC sp_helpdb' -outFile $BasicFile -DisplayText 'Databases'
	Run-SQLCommandtoFile -SqlQuery 'EXEC sp_helprolemember' -outFile $BasicFile -DisplayText 'Role Members'
	Run-SQLCommandtoFile -SqlQuery 'SELECT uid, status, name, createdate, islogin, hasdbaccess, updatedate FROM sys.sysusers' -outFile $BasicFile -DisplayText 'Sys Users'
	Run-SQLCommandtoFile -SqlQuery 'SELECT status, name, loginname, createdate, updatedate, accdate, dbname, denylogin, hasaccess, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin, isntname, isntgroup, isntuser FROM [master].sys.syslogins' `
		-outFile $BasicFile -DisplayText 'Sys Logins ([master].sys.syslogins)' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT certificate_id, principal_id, name, subject, pvt_key_encryption_type_desc, expiry_date, start_date, is_active_for_begin_dialog, issuer_name, string_sid, thumbprint, attested_by  FROM [master].sys.certificates' `
		-outFile $BasicFile -DisplayText 'Certificates ([master].sys.certificates)' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery "SELECT * FROM sys.dm_os_loaded_modules WHERE company <> 'Microsoft Corporation' OR company IS NULL"	`
		-outFile $BasicFile -DisplayText 'Loaded Modules'

	# ------------------------------------
	# Top SP's by CPU, Elapsed Time, etc.
	# ------------------------------------
	#$OutFile= $ComputerName +  "_SQL_TopQueries.txt"
	#Run-SQLCommandtoFile -SqlQuery "SELECT TOP(50) DB_NAME(t.[dbid]) AS [Database Name], qs.creation_time AS [Creation Time],
	#qs.total_worker_time AS [Total Worker Time], qs.min_worker_time AS [Min Worker Time],
	#qs.total_worker_time/qs.execution_count AS [Avg Worker Time],
	#qs.max_worker_time AS [Max Worker Time],
	#qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time],
	# qs.execution_count AS [Execution Count],
	#qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads],
	#qs.total_physical_reads/qs.execution_count AS [Avg Physical Reads],
	#rtrim(t.[text]) AS [Query Text]
	#FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
	#CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
	#ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE)" -outFile $OutFile -DisplayText "Top 50 Queries by CPU" -HideSqlQuery
	#Run-SQLCommandtoFile -SqlQuery "SELECT TOP(50) DB_NAME(t.[dbid]) AS [Database Name], qs.creation_time AS [Creation Time],
	#qs.total_elapsed_time  AS [Total Elapsed Time],
	#qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time],
	#qs.total_worker_time AS [Total Worker Time],
	#qs.total_worker_time/qs.execution_count AS [Avg Worker Time],
	#qs.execution_count AS [Execution Count],
	#qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads],
	#qs.total_physical_reads/qs.execution_count AS [Avg Physical Reads],
	#rtrim(t.[text]) AS [Query Text]
	#FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
	#CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
	#ORDER BY qs.total_elapsed_time/qs.execution_count DESC OPTION (RECOMPILE)" -outFile $OutFile -DisplayText "Top 50 Queries by Average Elapsed Time" -HideSqlQuery

	$TopQueriesFile = $Prefix + 'SQL_TopQueries.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT TOP(50) p.name AS [SP Name], qs.total_worker_time AS [TotalWorkerTime],
	qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
	qs.execution_count,
	ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
	qs.total_elapsed_time,
	qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
	qs.cached_time
	FROM sys.procedures AS p WITH (NOLOCK)
	INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
	ON p.[object_id] = qs.[object_id]
	WHERE qs.database_id = DB_ID() AND qs.execution_count > 0
	ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE)' -outFile $TopQueriesFile -DisplayText 'Top 50 SPs by CPU' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT TOP(50) p.name AS [SP Name], qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
	qs.total_elapsed_time, qs.execution_count, ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time,
	GETDATE()), 0) AS [Calls/Minute], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
	qs.total_worker_time AS [TotalWorkerTime], qs.cached_time
	FROM sys.procedures AS p WITH (NOLOCK)
	INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
	ON p.[object_id] = qs.[object_id]
	WHERE qs.database_id = DB_ID() AND qs.execution_count > 0
	ORDER BY avg_elapsed_time DESC OPTION (RECOMPILE)' -outFile $TopQueriesFile -DisplayText 'Top 50 SPs by Average Elapsed Time' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT TOP(50) p.name AS [SP Name], qs.execution_count,
	ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
	qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], qs.total_worker_time AS [TotalWorkerTime],
	qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
	qs.cached_time
	FROM sys.procedures AS p WITH (NOLOCK)
	INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
	ON p.[object_id] = qs.[object_id]
	WHERE qs.database_id = DB_ID() AND qs.execution_count > 0
	ORDER BY qs.execution_count DESC OPTION (RECOMPILE)' -outFile $TopQueriesFile -DisplayText 'Top 50 SPs by Execution Count' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT TOP(50) p.name AS [SP Name], ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
	qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
	qs.total_elapsed_time, qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
	qs.total_worker_time AS [TotalWorkerTime], qs.execution_count, qs.cached_time
	FROM sys.procedures AS p WITH (NOLOCK)
	INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
	ON p.[object_id] = qs.[object_id]
	WHERE qs.database_id = DB_ID() AND ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) > 0  AND qs.execution_count > 0
	ORDER BY [Calls/Minute] DESC OPTION (RECOMPILE)' -outFile $TopQueriesFile -DisplayText 'Top 50 SPs by Calls Per Minute' -HideSqlQuery

	# SQL Transactions
	$TransactionsFile = $Prefix + 'SQL_Transactions.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT sp.spid, rtrim(sp.status) [status], rtrim(sp.loginame) [Login], rtrim(sp.hostname) [hostname],
	sp.blocked BlkBy, sd.name DBName, rtrim(sp.cmd) Command, sp.open_tran, sp.cpu CPUTime, sp.physical_io DiskIO, sp.last_batch LastBatch, rtrim(sp.program_name) [ProgramName], rtrim(qt.text) [Text]
	FROM master.dbo.sysprocesses sp
	JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
	OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
	WHERE sp.blocked <> 0
	ORDER BY sp.spid' -outFile $TransactionsFile -DisplayText 'Blocked SPIDs' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT sp.spid, rtrim(sp.status) [status], rtrim(sp.loginame) [Login], rtrim(sp.hostname) [hostname],
	sp.blocked BlkBy, sd.name DBName, rtrim(sp.cmd) Command, sp.open_tran, sp.cpu CPUTime, sp.physical_io DiskIO, sp.last_batch LastBatch, rtrim(sp.program_name) [ProgramName], rtrim(qt.text) [Text]
	FROM master.dbo.sysprocesses sp
	JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
	OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
	WHERE sp.spid IN (SELECT blocked FROM master.dbo.sysprocesses) AND sp.blocked = 0
	ORDER BY sp.spid' -outFile $TransactionsFile -DisplayText 'Head Blockers' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT T.*, S.blocked, rtrim(E.text) [Text]
		FROM sys.dm_tran_active_snapshot_database_transactions T
		JOIN sys.dm_exec_requests R ON T.Session_ID = R.Session_ID
		INNER JOIN sys.sysprocesses S on S.spid = T.Session_ID
		OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS E
		ORDER BY elapsed_time_seconds DESC' -outFile $TransactionsFile -DisplayText 'Active Snapshot Database Transactions' -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'EXEC sp_who2' -outFile $TransactionsFile -DisplayText 'sp_who2'

	# List of Site Systems
	$SiteSystemsFile = $Prefix + 'SQL_SiteSystems.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT SMSSiteCode, COUNT(1) AS [Number Of DPs] FROM DistributionPoints GROUP BY SMSSiteCode UNION SELECT ''Total'' AS SMSSiteCode, COUNT(1) AS [Number Of DPs] FROM DistributionPoints' `
		-outFile $SiteSystemsFile -DisplayText 'Count of All Available Distribution Points by Site'
	Run-SQLCommandtoFile -SqlQuery 'SELECT SiteCode, ServerName, COUNT(ServerName) AS [Number Of Site System Roles] FROM SysResList GROUP BY SiteCode, ServerName' `
		-outFile $SiteSystemsFile -DisplayText 'Count of All Available Site Systems by Server Name'
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM DistributionPoints ORDER BY SMSSiteCode, ServerName' `
		-outFile $SiteSystemsFile -DisplayText 'List of Distribution Points'
	Run-SQLCommandtoFile -SqlQuery 'SELECT SiteCode, RoleName, ServerName, ServerRemoteName, PublicDNSName, InternetEnabled, Shared, SslState, DomainFQDN, ForestFQDN, IISPreferredPort, IISSslPreferredPort, IsAvailable FROM SysResList ORDER BY SiteCode, ServerName, RoleName' `
		-outFile $SiteSystemsFile -DisplayText 'List of Site Systems'

	# CM Database Information
	$CMDBInfoFile = $Prefix + 'SQL_CMDBInfo.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT SiteNumber, SiteCode, TaskName, TaskType, IsEnabled, NumRefreshDays, DaysOfWeek, BeginTime, LatestBeginTime, BackupLocation, DeleteOlderThan FROM vSMS_SC_SQL_Task ORDER BY SiteCode' `
		-outFile $CMDBInfoFile -DisplayText 'ConfigMgr Maintenance Tasks Configuration'
	Run-SQLCommandtoFile -SqlQuery 'SELECT *, DATEDIFF(S, LastStartTime, LastCompletionTime) As TimeTakenInSeconds, DATEDIFF(MI, LastStartTime, LastCompletionTime) As TimeTakenInMinutes FROM SQLTaskStatus ORDER BY TimeTakenInMinutes DESC' `
		-outFile $CMDBInfoFile -DisplayText "ConfigMgr Maintenance Tasks Status ($global:SMSSiteCode)"
	Run-SQLCommandtoFile -SqlQuery 'SELECT *, DATEDIFF(S, LastStartTime, LastSuccessfulCompletionTime) As TimeTakenInSeconds, DATEDIFF(MI, LastStartTime, LastSuccessfulCompletionTime) As TimeTakenInMinutes FROM vSR_SummaryTasks ORDER BY TimeTakenInMinutes DESC' `
		-outFile $CMDBInfoFile -DisplayText "State System Summary Tasks ($global:SMSSiteCode)" -NoSecondary
	Run-SQLCommandtoFile -SqlQuery "SELECT BoundaryType, CASE WHEN BoundaryType = 0 THEN 'IPSUBNET' WHEN BoundaryType = 1 THEN 'ADSITE' WHEN BoundaryType = 2 THEN 'IPV6PREFIX' WHEN BoundaryType = 3 THEN 'IPRANGE' END AS [Type], COUNT(BoundaryType) AS [Count] FROM BoundaryEx GROUP BY BoundaryType" `
		-outFile $CMDBInfoFile -DisplayText 'Boundary Counts'

	# Site Control File
	$SiteControlFile = $Prefix + 'SQL_SiteControlFile.xml.txt'
	$ResultValue = Get-SQLValue -SqlQuery "SELECT * FROM vSMS_SC_SiteControlXML WHERE SiteCode = '$SMSSiteCode'" -ColumnName 'SiteControl' -DisplayText 'Site Control File (XML)'
	if ($null -eq $ResultValue.Error) {
		try {
			$ScfXml = Format-XML -xml $ResultValue.Value
			$ScfXml | Out-String -Width 4096 | Out-File -FilePath $SiteControlFile -Force
		}
		catch [Exception] {
			$_ | Out-File -FilePath $SiteControlFile -Force
		}
	}
	else {
		$ResultValue.Error | Out-File -FilePath $SiteControlFile -Force
	}

	# SUP Sync information
	$SUPSyncFile = $Prefix + 'SQL_SUPSync.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT CI.CategoryInstance_UniqueID, CI.CategoryTypeName, LCI.CategoryInstanceName FROM CI_CategoryInstances CI
	JOIN CI_LocalizedCategoryInstances LCI ON CI.CategoryInstanceID = LCI.CategoryInstanceID
	JOIN CI_UpdateCategorySubscription UCS ON CI.CategoryInstanceID = UCS.CategoryInstanceID
	WHERE UCS.IsSubscribed = 1
	ORDER BY CI.CategoryTypeName, LCI.CategoryInstanceName' -outFile $SUPSyncFile -DisplayText 'SUM Products/Classifications' -NoSecondary -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM  vSMS_SUPSyncStatus'-outFile $SUPSyncFile -DisplayText 'SUP Sync Status' -NoSecondary
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM WSUSServerLocations' -outFile $SUPSyncFile -DisplayText 'WSUSServerLocations'
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM Update_SyncStatus' -outFile $SUPSyncFile -DisplayText 'Update_SyncStatus'
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CI_UpdateSources' -outFile $SUPSyncFile -DisplayText 'CI_UpdateSources'

	# OSD Information
	$BootImagesFile = $Prefix + 'SQL_BootImages.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM vSMS_OSDeploymentKitInstalled' -outFile $BootImagesFile -DisplayText 'ADK Version from Database' -NoSecondary -HideSqlQuery
	'========================================' | Out-File $BootImagesFile -Append
	'-- ADK Version from Add/Remove Programs ' | Out-File $BootImagesFile -Append
	'========================================' | Out-File $BootImagesFile -Append
	'' | Out-File $BootImagesFile -Append
	($global:ADKVersion).Trim() | Out-File $BootImagesFile -Append
	"`r`n" | Out-File $BootImagesFile -Append
	Run-SQLCommandtoFile -SqlQuery 'SELECT PkgID, Name, ImageOSVersion, Version, Architecture, DefaultImage, SourceSite, SourceVersion, LastRefresh, SourceDate, SourceSize, Action, Source, ImagePath FROM vSMS_BootImagePackage_List' -outFile $BootImagesFile -DisplayText 'Boot Images' -NoSecondary
	Run-SQLCommandtoFile -SqlQuery 'SELECT ImageId, Architecture, Name, MsiComponentID, Size, IsRequired, IsManageable FROM vSMS_WinPEOptionalComponentInBootImage ORDER BY ImageId, Architecture' -outFile $BootImagesFile -DisplayText 'Optional Components' -NoSecondary

	# DRS Data
	$DRSDataDestinationPath = $Prefix + 'SQL_DRSData'
	$DRSDataZipFile = $Prefix + 'SQL_DRSData.zip'
	FwCreateFolder $DRSDataDestinationPath

	$spDiagDRSFile = Join-Path $DRSDataDestinationPath 'spDiagDRS.txt'
	Run-SQLCommandtoFileWithInfo -SqlQuery 'EXEC spDiagDRS' -outFile $spDiagDRSFile -DisplayText 'spDiagDRS' -ZipFile $DRSDataZipFile

	# Removed spDiagGetSpaceUsed as it takes a long time, and is not absolutely necessary
	# $OutFile = Join-Path $DRSDataDestinationPath "spDiagGetSpaceUsed.txt"
	# Run-SQLCommandtoFileWithInfo -SqlQuery "EXEC spDiagGetSpaceUsed" -outFile $OutFile -DisplayText "spDiagGetSpaceUsed" -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'Sites.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT SiteKey, SiteCode, SiteName, ReportToSite, Status, DetailedStatus, SiteType, BuildNumber, Version, SiteServer, InstallDir, ReplicatesReservedRanges FROM Sites' -outFile $OutFile -DisplayText 'Sites Output' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM ServerData' -outFile $OutFile -DisplayText 'ServerData Output' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT SiteKey, SiteCode, ReportToSite, SiteServer, Settings FROM Sites' -OutputWidth 2048 -outFile $OutFile -DisplayText 'Client Operational Settings' -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'RCM_Tables.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM RCM_ReplicationLinkStatus' -outFile $OutFile -DisplayText 'RCM_ReplicationLinkStatus Table Output' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM RCM_DrsInitializationTracking' -outFile $OutFile -DisplayText 'RCM_DrsInitializationTracking Table Output' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM RCM_RecoveryTracking' -outFile $OutFile -DisplayText 'RCM_RecoveryTracking' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM RCM_RecoveryPostAction' -outFile $OutFile -DisplayText 'RCM_RecoveryPostAction' -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'vReplicationLinkStatus.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM vReplicationLinkStatus' -outFile $OutFile -DisplayText 'vReplicationLinkStatus Output' -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'DRS_Tables.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT COUNT (ConflictType) [Count], TableName, ConflictType, ConflictLoserSiteCode FROM DrsConflictInfo GROUP BY TableName, ConflictType, ConflictLoserSiteCode ORDER BY [Count] DESC' -outFile $OutFile -DisplayText 'DRS Conflicts Summary (All time)' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT COUNT (ConflictType) [Count], TableName, ConflictType, ConflictLoserSiteCode FROM DrsConflictInfo WHERE ConflictTime > DATEAdd(dd,-5,GETDate()) GROUP BY TableName, ConflictType, ConflictLoserSiteCode ORDER BY [Count] DESC' -outFile $OutFile -DisplayText 'DRS Conflicts Summary (Past 5 days)' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM DrsConflictInfo WHERE ConflictTime > DATEAdd(dd,-5,GETDate()) ORDER BY ConflictTime DESC' -outFile $OutFile -DisplayText 'DRS Conflicts (Past 5 days)' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM DRSReceiveHistory WHERE ProcessedTime IS NULL' -outFile $OutFile -DisplayText 'DRSReceiveHistory Table Output' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM DRSSendHistory WHERE ProcessedTime IS NULL' -outFile $OutFile -DisplayText 'DRSSendHistory Table Output' -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'vLogs.txt'
	Run-SQLCommandtoFile -SqlQuery "SELECT TOP 5000 * FROM vLogs WHERE LogText NOT LIKE 'INFO:%' AND LogText <> 'Web Service heartbeat' AND ProcedureName <> 'spCMGSProcessMessageV2' ORDER BY LogLine DESC" -outFile $OutFile -DisplayText 'vLogs Output' -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'TransmissionQueue.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT COUNT (to_service_name) [Count], to_service_name FROM sys.transmission_queue GROUP BY to_service_name' -outFile $OutFile -DisplayText 'Transmission Queue Summary' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM sys.transmission_queue WHERE conversation_handle NOT IN (SELECT handle FROM SSB_DialogPool)' -outFile $OutFile -DisplayText 'Orphaned Messages' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM sys.transmission_queue' -outFile $OutFile -DisplayText 'Transmission Queue' -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'EndPointsAndQueues.txt'
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM sys.tcp_endpoints' -outFile $OutFile -DisplayText 'TCP Endpoints' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM sys.service_broker_endpoints' -outFile $OutFile -DisplayText 'Service Broker Endpoints' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM sys.service_queues' -outFile $OutFile -DisplayText 'Service Queues' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM sys.conversation_endpoints' -outFile $OutFile -DisplayText 'Conversation Endpoints' -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM SSB_DialogPool' -outFile $OutFile -DisplayText 'SSB Dialog Pool' -ZipFile $DRSDataZipFile

	$OutFile = Join-Path $DRSDataDestinationPath 'DRS_Config.txt'
	# Run-SQLCommandtoFile -SqlQuery "SELECT * FROM ServerData" -outFile $OutFile -DisplayText "Server Data Table" -ZipFile $DRSDataZipFile
	Run-SQLCommandtoFile -SqlQuery "SELECT SD.SiteCode,
	MAX(CASE WHEN vRSCP.Name = 'Degraded' THEN vRSCP.Value END) AS Degraded,
	MAX(CASE WHEN vRSCP.Name = 'Failed' THEN vRSCP.Value END) AS Failed,
	MAX(CASE WHEN vRSCP.Name = 'DviewForHINV' THEN vRSCP.Value END) AS DviewForHINV,
	MAX(CASE WHEN vRSCP.Name = 'DviewForSINV' THEN vRSCP.Value END) AS DviewForSINV,
	MAX(CASE WHEN vRSCP.Name = 'DviewForStatusMessages' THEN vRSCP.Value END) AS DviewForStatusMessages,
	MAX(CASE WHEN vRSCP.Name = 'SQL Server Service Broker Port' THEN vRSCP.Value END) AS BrokerPort,
	MAX(CASE WHEN vRSCP.Name = 'Send History Summarize Interval' THEN vRSCP.Value END) AS SendHistorySummarizeInterval,
	MAX(CASE WHEN vRSCP.Name = 'SQL Server Service Broker Port' THEN vRSCP.Value END) AS SSBPort,
	MAX(CASE WHEN vRSCP.Name = 'Retention Period' THEN vRSCP.Value END) AS RetentionPeriod,
	MAX(CASE WHEN vRSCP.Name = 'IsCompression' THEN vRSCP.Value END) AS IsCompression
	FROM vRcmSqlControlProperties vRSCP
	JOIN RCMSQlControl RSC ON vRSCP.ID = RSC.ID
	JOIN ServerData SD ON RSC.SiteNumber = SD.ID
	GROUP BY SD.SiteCode" -outFile $OutFile -DisplayText 'RCM Control Properties' -ZipFile $DRSDataZipFile -HideSqlQuery
	Run-SQLCommandtoFile -SqlQuery "SELECT D.name, CTD.* FROM sys.change_tracking_databases AS CTD JOIN sys.databases AS D ON D.database_id = CTD.database_id WHERE D.name = '$ConfigMgrDBNameNoInstance'" -outFile $OutFile -DisplayText 'DRS Data Retention Settings' -ZipFile $DRSDataZipFile
	# Compress the destination folder into a ZIP file
	try {
		LogInfo "Compressing $DRSDataDestinationPath"
		Add-Type -Assembly 'System.IO.Compression.FileSystem'
		[System.IO.Compression.ZipFile]::CreateFromDirectory($DRSDataDestinationPath, $DRSDataZipFile)
		# Cleanup the destination folder
		if ($DRSDataDestinationPath) {
			Remove-Item -Path $DRSDataDestinationPath -Recurse -Force
		}
	}
	catch {
		LogException "Failed to compress $DRSDataDestinationPath" $_
	}

	# Update Servicing Data
	if ($global:SiteBuildNumber -gt 8325) {
		$UpdateServicingDestinationPath = $Prefix + 'SQL_UpdateServicing'
		$UpdateServicingZipFile = $Prefix + 'SQL_UpdateServicing.zip'
		FwCreateFolder $UpdateServicingDestinationPath

		# CM_UpdatePackages
		$OutFile = Join-Path $UpdateServicingDestinationPath 'CM_UpdatePackages.txt'
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdatePackages' -outFile $OutFile -DisplayText 'CM_UpdatePackages' -ZipFile $UpdateServicingZipFile
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdatePackages_Hist ORDER BY RecordTime DESC' -outFile $OutFile -DisplayText 'CM_UpdatePackages_Hist' -ZipFile $UpdateServicingZipFile

		# CM_UpdatePackageSiteStatus
		$OutFile = Join-Path $UpdateServicingDestinationPath 'CM_UpdatePackageSiteStatus.txt'
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdatePackageSiteStatus' -outFile $OutFile -DisplayText 'CM_UpdatePackageSiteStatus' -ZipFile $UpdateServicingZipFile
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdatePackageSiteStatus_HIST ORDER BY RecordTime DESC' -outFile $OutFile -DisplayText 'CM_UpdatePackageSiteStatus_HIST' -ZipFile $UpdateServicingZipFile

		# CM_UpdatePackageInstallationStatus
		$OutFile = Join-Path $UpdateServicingDestinationPath 'CM_UpdatePackageInstallationStatus.txt'
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdatePackageInstallationStatus ORDER BY MessageTime DESC' -outFile $OutFile -DisplayText 'CM_UpdatePackageInstallationStatus' -ZipFile $UpdateServicingZipFile

		# CM_UpdateReadiness
		$OutFile = Join-Path $UpdateServicingDestinationPath 'CM_UpdateReadiness.txt'
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdateReadiness' -outFile $OutFile -DisplayText 'CM_UpdateReadiness' -ZipFile $UpdateServicingZipFile
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdateReadinessSite ORDER BY LastUpdateTime DESC' -outFile $OutFile -DisplayText 'CM_UpdateReadinessSite' -ZipFile $UpdateServicingZipFile

		# CM_UpdatePackagePrereqStatus
		$OutFile = Join-Path $UpdateServicingDestinationPath 'CM_UpdatePackagePrereqStatus.txt'
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM CM_UpdatePackagePrereqStatus' -outFile $OutFile -DisplayText 'CM_UpdatePackagePrereqStatus' -ZipFile $UpdateServicingZipFile

		# EasySetupSettings
		$OutFile = Join-Path $UpdateServicingDestinationPath 'EasySetupSettings.txt'
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM EasySetupSettings' -outFile $OutFile -DisplayText 'EasySetupSettings' -ZipFile $UpdateServicingZipFile
		Run-SQLCommandtoFile -SqlQuery 'SELECT PkgID, Name, SourceVersion, StoredPkgVersion, SourceSite, SourceSize, UpdateMask, Action, Source, StoredPkgPath, StorePkgFlag, ShareType, LastRefresh, PkgFlags, SourceDate, HashVersion FROM SMSPackages WHERE PkgID = (SELECT PackageID FROM EasySetupSettings)' -outFile $OutFile -DisplayText 'EasySetup Package' -ZipFile $UpdateServicingZipFile
		Run-SQLCommandtoFile -SqlQuery 'SELECT * FROM PkgStatus WHERE Type = 1 AND ID = (SELECT PackageID FROM EasySetupSettings)' -outFile $OutFile -DisplayText 'EasySetup Package Status' -ZipFile $UpdateServicingZipFile

		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $UpdateServicingDestinationPath"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($UpdateServicingDestinationPath, $UpdateServicingZipFile)
			# Cleanup the destination folder
			if ($UpdateServicingDestinationPath) {
				Remove-Item -Path $UpdateServicingDestinationPath -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $UpdateServicingDestinationPath" $_
		}
	}
	else {
		LogInfo "Update Servicing Data not collected because Site Build Number $global:SiteBuildNumber is less than 8325."
	}

	#TODO: Check if output is collected
	# ---------------------------
	# Collect Server Information
	# ---------------------------
	# Moved to DC_FinishExecution

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMSQLInfo ---

#region --- Function Get-SCCMSQLCfgInfo ---
function Get-SCCMSQLCfgInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'SQL Data'

	#If this is not a site server or site database server, return
	if (-not ($Is_SiteServer -or $global:Is_SiteDatabaseServer)) {
		LogInfo "This is not a Site Server or Site Database Server. Exiting."
		return
	}

	LogInfo "[$LogPrefix] Checking Configuration Manager SQL Configuration."
	Set-Variable -Name ComplianceSummary -Scope Script
	$script:ComplianceSummary = @()
	$SQLTestStatus = $Prefix + 'SQL_ConfigCompliance.txt'
	'===========================================================================================================' | Out-File $SQLTestStatus
	'SQL Configuration Checks Performed (Check UDE Messages for More Information if a Property is Not Compliant)' | Out-File $SQLTestStatus -Append
	'===========================================================================================================' | Out-File $SQLTestStatus -Append
	# Falling back to MASTER in case database is offline.
	if ($null -eq $global:DatabaseConnection) {
		LogInfo 'DatabaseConnection is null. Trying to connect to MASTER database.'
		$global:DatabaseConnection = Get-DBConnection -DatabaseServer $ConfigMgrDBServer -DatabaseName 'MASTER'
	}

	if ($null -eq $global:DatabaseConnection) {
		LogInfo "SQL Connection to ConfigMgr and MASTER databases on $ConfigMgrDBServer failed with ERROR: $DatabaseConnectionError"
		"SQL Connection to ConfigMgr and MASTER databases on $ConfigMgrDBServer failed with ERROR: $DatabaseConnectionError" | Out-File $SQLTestStatus -Append
		'All tests were skipped!' | Out-File $SQLTestStatus -Append
		return
	}

	# Tests start here
	LogDebug "[$LogPrefix] Checking SQL Configuration for $ConfigMgrDBServer and database $global:ConfigMgrDBNameNoInstance."
	$dbname = $global:ConfigMgrDBNameNoInstance

	$RootCauseName = 'RC_DbOnline'
	$sQuery = "SELECT name, state_desc FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	# Check-SQLValue $sQuery "state_desc" "eq" "ONLINE" $RootCauseName
	Check-SQLValue -Query $sQuery -ColumnName 'state_desc' -CompareOperator 'eq' -DesiredValue 'ONLINE' -RootCauseName $RootCauseName -ColumnDisplayName 'Database Online'

	$RootCauseName = 'RC_DbOwner'
	$sQuery = "SELECT name, SUSER_NAME(owner_sid) AS DbOwner FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'DbOwner' -CompareOperator 'eq' -DesiredValue 'sa' -RootCauseName $RootCauseName -ColumnDisplayName 'Database Owner'

	$RootCauseName = 'RC_UserAccess'
	$sQuery = "SELECT name, user_access_desc FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'user_access_desc' -CompareOperator 'eq' -DesiredValue 'MULTI_USER' -RootCauseName $RootCauseName -ColumnDisplayName 'User Access'

	$RootCauseName = 'RC_ReadOnly'
	$sQuery = "SELECT name, is_read_only FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'is_read_only' -CompareOperator 'eq' -DesiredValue $false -RootCauseName $RootCauseName -ColumnDisplayName 'Database Read Only'

	$RootCauseName = 'RC_RecoveryModel'
	$sQuery = "SELECT name, recovery_model_desc FROM sys.databases WHERE name = '$dbname'"
	#Check $global:Is_AlwaysOn and set $DesiredValue to 'FULL' because AO databases are always in FULL recovery mode, or 'SIMPLE' if false
	if ($true -eq $global:Is_AlwaysOn) {
		$DesiredValue = 'FULL'
	}
	else {
		$DesiredValue = 'SIMPLE'
	}
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'recovery_model_desc' -CompareOperator 'eq' -DesiredValue $DesiredValue -RootCauseName $RootCauseName -ColumnDisplayName 'Recovery Model'

	$RootCauseName = 'RC_RecursiveTriggers'
	$sQuery = "SELECT name, is_recursive_triggers_on FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'is_recursive_triggers_on' -CompareOperator 'eq' -DesiredValue $true -RootCauseName $RootCauseName -ColumnDisplayName 'Recursive Triggers'

	$RootCauseName = 'RC_BrokerEnabled'
	$sQuery = "SELECT name, is_broker_enabled FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'is_broker_enabled' -CompareOperator 'eq' -DesiredValue $true -RootCauseName $RootCauseName -ColumnDisplayName 'Broker Enabled'

	$RootCauseName = 'RC_Trustworthy'
	$sQuery = "SELECT name, is_trustworthy_on FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'is_trustworthy_on' -CompareOperator 'eq' -DesiredValue $true -RootCauseName $RootCauseName -ColumnDisplayName 'Trustworthy'

	$RootCauseName = 'RC_HonorBrokerPriority'
	$sQuery = "SELECT name, is_honor_broker_priority_on FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'is_honor_broker_priority_on' -CompareOperator 'eq' -DesiredValue $true -RootCauseName $RootCauseName -ColumnDisplayName 'Honor Broker Priority'

	$RootCauseName = 'RC_SnapshotIsolation'
	$sQuery = "SELECT name, snapshot_isolation_state_desc FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'snapshot_isolation_state_desc' -CompareOperator 'eq' -DesiredValue 'ON' -RootCauseName $RootCauseName -ColumnDisplayName 'Snapshot Isolation'

	$RootCauseName = 'RC_ReadCommittedSnapshot'
	$sQuery = "SELECT name, is_read_committed_snapshot_on FROM sys.databases WHERE name = '$dbname'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'is_read_committed_snapshot_on' -CompareOperator 'eq' -DesiredValue $true -RootCauseName $RootCauseName -ColumnDisplayName 'Read Committed Snapshot'

	$RootCauseName = 'RC_NestedTriggers'
	$sQuery = "EXEC sp_configure 'nested triggers'"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	Check-SQLValue -Query $sQuery -ColumnName 'run_value' -CompareOperator 'eq' -DesiredValue 1 -RootCauseName $RootCauseName -ColumnDisplayName 'Nested Triggers'

	$sQuery = "
	DECLARE @RetentionPeriod INT
	DECLARE @RetentionUnit VARCHAR(10)
	DECLARE @OldestSCTRowDate DATETIME
	DECLARE @OldestSCTRowDelta INT

	DECLARE @CountOfSites INT
	SELECT @CountOfSites = COUNT(1) FROM sites

	IF (@CountOfSites <= 1) BEGIN SELECT 0 AS ChangeTrackingBacklogResult; RETURN; END

	SELECT @RetentionPeriod = CTD.retention_period ,@RetentionUnit = CTD.retention_period_units_desc
	FROM sys.change_tracking_databases AS CTD
	JOIN sys.databases AS D ON D.database_id = CTD.database_id
	WHERE D.NAME = '$dbname'

	IF @@rowcount < 1 BEGIN SELECT -1 AS ChangeTrackingBacklogResult; RETURN; END -- This means we did not find the CM DB
	IF @RetentionUnit <> N'DAYS' BEGIN SELECT -2 AS ChangeTrackingBacklogResult; RETURN; END -- UI does not allow for configuring the unit
	IF @RetentionPeriod > 14 BEGIN SELECT -3 AS ChangeTrackingBacklogResult; RETURN; END -- UI allows for values between 1 and 14 days

	SELECT @OldestSCTRowDate = MIN(commit_time) FROM sys.dm_tran_commit_table
	SELECT @OldestSCTRowDelta = DATEDIFF(DAY, @OldestSCTRowDate, GetDate())

	SELECT CAST(@OldestSCTRowDelta AS VARCHAR(10)) + '.' + CAST(@RetentionPeriod AS VARCHAR(2)) AS ChangeTrackingBacklogResult; RETURN; -- Major = Backlog, Minor = Retention Days
	"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	$DRSBacklogResult = Get-SQLValue -SqlQuery $sQuery -ColumnName 'ChangeTrackingBacklogResult' -ColumnDisplayName 'Change Tracking Backlog'
	Parse-DRSBacklogResult $DRSBacklogResult

	$sQuery = "
	DECLARE @tablesizeMB float
	DECLARE @dbsizeMB float

	IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DBSchemaChangeHistory')
	BEGIN
		SELECT '0'
		RETURN
	END

	SELECT @dbsizeMB = CAST(SUM(size) * 8. / 1024 AS DECIMAL(8,0))
	FROM sys.master_files SMF WITH(NOWAIT)
	JOIN sys.databases SD on SD.database_id = SMF.database_id
	WHERE SD.name = '$dbname'

	DECLARE @InputBuffer TABLE ([name] NVARCHAR(100), [rows] INT, [reserved] NVARCHAR(100), [data] NVARCHAR(100), [index_size] NVARCHAR(100), [unused] NVARCHAR(100))
	INSERT INTO @InputBuffer EXEC sp_spaceused 'DBSchemaChangeHistory'

	SELECT @tablesizeMB = CONVERT(bigint,left(reserved,len(reserved)-3))/1024 FROM @InputBuffer

	SELECT CAST(@dbsizeMB AS VARCHAR(100)) + '.' + CAST(@tablesizeMB AS VARCHAR(100)) AS Result
	"
	LogDebug "[$LogPrefix] Running SQL Query: $sQuery"
	$DBSchemaChangeHistoryResult = Get-SQLValue -SqlQuery $sQuery -ColumnName 'Result' -ColumnDisplayName 'DBSchemaChangeHistory Size'
	Parse-DBSchemaChangeHistoryResult $DBSchemaChangeHistoryResult

	$ComplianceSummary | Format-Table -Auto | Out-File $SQLTestStatus -Append -Width 200

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMSQLCfgInfo ---

#region --- Function Get-SCCMSQLErrLogs ---
function Get-SCCMSQLErrLogs {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'SQL ErrLogs'

	#If this is not a site server or site database server, return
	if (-not ($Is_SiteServer -or $global:Is_SiteDatabaseServer)) {
		LogInfo "This is not a Site Server or Site Database Server. Exiting."
		return
	}

	$SQLServerName = $ConfigMgrDBServer
	$ZipName = $ComputerName + '_Logs_SQLError.zip'
	$ZipNameBase = Split-Path -Leaf $ZipName
	$compress = $false
	$SQLServerKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'


	LogInfo "[$LogPrefix] Collecting SQL Error Logs."
	# Get instance name for Database Server
	if ($null -ne $ConfigMgrDBName -and $ConfigMgrDBName.Contains('\')) {
		$instance = $ConfigMgrDBName.Substring(0, $ConfigMgrDBName.IndexOf('\'))
		$ConfigMgrDBName = $ConfigMgrDBName.Substring($ConfigMgrDBName.IndexOf('\') + 1)
		$SQLInstanceName = $instance		# Named instance
	}
	else {
		#We're a little lazy here and assume that the default instance if $ConfigMgrDBName is null, which it will be for a standalone site DB server.
		$SQLInstanceName = 'MSSQLSERVER'		# Default instance -
	}
	trap [Exception] {
		LogInfo "[$LogPrefix] Failed to access $SQLServerKey. Path does not exist or Access Denied." DarkRed
		AddTo-CMServerSummary 'SQL Error Logs' -Value "Failed to access $SQLServerKey. Path does not exist or Access Denied" -NoToSummaryReport
		return
	}

	$RegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $SQLServerName)
	$Key = $RegKey.OpenSubKey($SQLServerKey)
	$SQLInstance = $Key.GetValue($SQLInstanceName)
	$SQLServerInstanceKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + $SQLInstance + '\MSSQLServer\Parameters'
	$RegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $SQLServerName)
	$Key = $RegKey.OpenSubKey($SQLServerInstanceKey)

	$KeyArgs = $Key.GetValueNames()
	foreach ($Arg in $KeyArgs) {
		$value = $Key.GetValue($Arg)
		if ($value -match '^-e(.+)') {
			# -e Argument specifies the Error Log Path. $matches is set by -match and 1st element stores the second match, which is the path.
			$SqlServerLogPath = [System.IO.Path]::GetDirectoryName($matches[1])
			LogInfo "[$LogPrefix] SQL Error Log Path = $SqlServerLogPath"
			break
		}
	}

	# Convert Log Path to UNC Path
	$SqlServerLogPathUNC = $SqlServerLogPath -replace ':', '$'
	$SqlServerLogPathUNC = "\\$SQLServerName\" + $SqlServerLogPathUNC
	# Convert Log Path to UNC Path
	$SqlServerLogPathUNC = $SqlServerLogPath -replace ':', '$'
	$SqlServerLogPathUNC = "\\$SQLServerName\" + $SqlServerLogPathUNC
	LogInfo "[$LogPrefix] SQL Server Log Path UNC = $SqlServerLogPathUNC"

	# Create Temporary Destination folder to copy the logs in \Windows\Temp
	$SQLErrorDestination = $Prefix + 'Logs_SQLError'
	$SQLErrorZipFile = $Prefix + 'Logs_SQLError.zip'
	FwCreateFolder $SQLErrorDestination

	if (Test-Path $SQLErrorDestination) {
		Remove-Item -Path $SQLErrorDestination -Recurse -Force
	}
	FwCreateFolder $SQLErrorDestination

	if (Get-ChildItem $SqlServerLogPathUNC -ErrorAction SilentlyContinue -ErrorVariable AccessError) {
		Copy-Item $SqlServerLogPathUNC\ERRORLOG $SQLErrorDestination -ErrorAction SilentlyContinue
		Copy-Item $SqlServerLogPathUNC\ERRORLOG.1 $SQLErrorDestination -ErrorAction SilentlyContinue
		Copy-Item $SqlServerLogPathUNC\ERRORLOG.2 $SQLErrorDestination -ErrorAction SilentlyContinue
		Copy-Item $SqlServerLogPathUNC\*.mtxt $SQLErrorDestination -ErrorAction SilentlyContinue
		# Copy-Item $SqlServerLogPathUNC\*.mdmp $SQLErrorDestination -ErrorAction SilentlyContinue
		$compress = $true
	}
	else {
		LogInfo "[$LogPrefix] Failed to access $SqlServerLogPathUNC. Path does not exist or Access Denied"
		# AddTo-CMServerSummary "SQL Error Logs" -Value "Failed to access $SqlServerLogPathUNC. Path does not exist or Access Denied" -NoToSummaryReport
		AddTo-CMDatabaseSummary -Name 'SQL Error Logs' -Value "Failed to access $SqlServerLogPathUNC. Path does not exist or Access Denied" -NoToSummaryQueries -NoToSummaryReport
	}

	if ($compress) {
		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $SQLErrorDestination"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($SQLErrorDestination, $SQLErrorZipFile)
			# Cleanup the destination folder
			if ($SQLErrorDestination) {
				Remove-Item -Path $SQLErrorDestination -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $SQLErrorDestination" $_
		}
		AddTo-CMDatabaseSummary -Name 'SQL Error Logs' -Value "Review $ZipNameBase" -NoToSummaryQueries -NoToSummaryReport
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMSQLErrLogs ---

#region --- Function Get-SCCMIISLogs ---
function Get-SCCMIISLogs {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$IISConfigurationPath
	)

	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	if ($Is_IIS) {
		$LogPrefix = 'IIS Logs'
		$NumOfDays = 5
		Set-Variable -Name sites -Value @()
		$sites += 'Default Web Site'

		if ($Is_WSUS) {
			$siteID = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'IISTargetWebSiteIndex'
			if ($siteID -ne 1) {
				$sites += 'WSUS Administration'
			}
		}

		$DaysToCollect = 0 - $NumOfDays
		LogInfo "[$LogPrefix] OS Build - $($OSVersion.Build)"
		LogInfo "[$LogPrefix] Sites - $sites"

		if ($OSVersion.Major -ge 6) {
			# IIS 7.0 and Higher
			[System.Reflection.Assembly]::LoadFrom('C:\windows\system32\inetsrv\Microsoft.Web.Administration.dll') | Out-Null
			$serverManager = (New-Object Microsoft.Web.Administration.ServerManager)

			# Set Up Directory Structure
			$IISLogsDestinationPath = $Prefix + 'Logs_IIS\LogFiles'
			$FailedReqLogFiles = $Prefix + 'Logs_IIS\FailedReqLogFiles'
			FwCreateFolder $IISLogsDestinationPath

			$sites | ForEach-Object `
			{
				LogInfo "[$LogPrefix] Gathering IIS Logs ($sites)." White
				# Build Filename in this format SITE_APP_VDIR_Web.config
				$currentSiteName = $_
				LogInfo "[$LogPrefix] Site Found: $currentSiteName"
				$currentSite = $serverManager.Sites[$currentSiteName]
				$siteId = $currentSite.Id
				$path = $currentSite.ChildElements['logFile'].Attributes['directory'].value
				$LogFilePath = [environment]::ExpandEnvironmentVariables($path)
				$LogFilePath = Join-Path $LogFilePath ('W3SVC' + $siteId)
				LogInfo "[$LogPrefix] LogPath: $LogFilePath"
				$path = $currentSite.ChildElements['traceFailedRequestsLogging'].Attributes['directory'].value
				$FREBPath = [environment]::ExpandEnvironmentVariables($path)
				$FREBPath = Join-Path $FREBPath ('W3SVC' + $siteId)
				LogInfo "[$LogPrefix] FREB Log Path: $FREBPath"

				$dateStart = (Get-Date).AddDays($DaysToCollect)
				if (Test-Path $LogFilePath) {
					FwCreateFolder (Join-Path $IISLogsDestinationPath $currentSiteName)
					Get-ChildItem $LogFilePath | Where-Object { $_.lastwritetime -gt $dateStart } | ForEach-Object `
					{
						LogInfo "[$LogPrefix] Copying Log: $_"
						Copy-Item $_.FullName (Join-Path $IISLogsDestinationPath $currentSiteName)
					}
				}
				# Failed Request Logging
				if (Test-Path $FREBPath) {
					# Check if the folder is not empty
					if ((Get-ChildItem -Path $FREBPath -ErrorAction Ignore).Count -gt 0) {
						# Folder exists and contains items
						FwCreateFolder $FailedReqLogFiles
						FwCreateFolder (Join-Path $FailedReqLogFiles $currentSiteName)
						Get-ChildItem $FREBPath | Where-Object { $_.lastwritetime -gt $dateStart } | ForEach-Object `
						{
							LogInfo "[$LogPrefix] Copying FREB Log: $_.FullName"
							Copy-Item $_.FullName (Join-Path $FailedReqLogFiles $currentSiteName)
						}
					}
					else {
						# Folder exists but is empty
						LogInfo "[$LogPrefix] Folder $FREBPath exists but is empty."
					}
				}
				else {
					# Folder does not exist
					LogInfo "[$LogPrefix] Folder $FREBPath does not exist."
				}
			}
		}
		else {
			# IIS 6.0
			# Set Up Directory Structure
			$IISLogsDestinationPath = $Prefix + 'Logs_IIS\LogFiles'
			FwCreateFolder $IISLogsDestinationPath
			$sites | ForEach-Object `
			{
				# Write Progress
				LogInfo "[$LogPrefix] Gathering IIS Logs ($sites)." White
				$currentSiteName = $_
				LogInfo "[$LogPrefix] Site Found: $currentSiteName"
				$siteQuery = "Select * From IIsWebServerSetting Where ServerComment = '{0}'" -f $currentSiteName
				Get-CimInstance -Namespace 'root/MicrosoftIISv2' -Query $siteQuery | ForEach-Object `
				{
					$siteIdPath = $_.Name.Replace('/', '')
					$path = $_.LogFileDirectory
					$LogFilePath = [environment]::ExpandEnvironmentVariables($path)
					$LogFilePath = Join-Path $LogFilePath $siteIdPath
					LogInfo "[$LogPrefix] LogPath: $LogFilePath"

					$dateStart = (Get-Date).AddDays($DaysToCollect)
					if (Test-Path $LogFilePath) {
						FwCreateFolder (Join-Path $IISLogsDestinationPath $currentSiteName)
						Get-ChildItem $LogFilePath | Where-Object { $_.lastwritetime -gt $dateStart } | ForEach-Object `
						{
							LogInfo "[$LogPrefix] Copying Log: $_"
							Copy-Item $_.FullName (Join-Path $IISLogsDestinationPath $currentSiteName)
						}
					}
				}
			}
		}
		$IISZipSrc = $Prefix + 'Logs_IIS\'
		$IISLogsZipFile = $Prefix + 'Logs_IIS.zip'
		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $IISZipSrc"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($IISZipSrc, $IISLogsZipFile)
			# Cleanup the destination folder
			if ($IISZipSrc) {
				Remove-Item -Path $IISZipSrc -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $IISZipSrc" $_
		}

		#.\DC_IIS_Collect_Configuration.ps1 -sites $sites
		# calling Get-SCCMIISConfig to obtain IIS configuration
		Get-SCCMIISConfig -Sites $sites
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMIISLogs ---

#region --- Function Get-SCCMIISConfig ---
function Get-SCCMIISConfig {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Sites
	)
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'IIS Config'
	# Define array of files we will eventually collect
	$IISConfigurationPath = $Prefix + 'IISConfiguration'
	$IISConfigurationZipFile = $Prefix + 'IISConfiguration.zip'
	FwCreateFolder $IISConfigurationPath

	$files = @()
	# Collect machine.config and web.config for all framework versions:
	LogInfo "[$LogPrefix] Collecting ASP.NET Configuration."
	$FrameworkPath = Join-Path $env:windir 'Microsoft.Net'
	Get-ChildItem $FrameworkPath -Include web.config, machine.config, aspnet.config -Recurse | ForEach-Object `
	{
		# Strip C:\Windows\Microsoft.NET\Framework and .config
		$NewFileName = ($_.FullName.TrimStart($FrameworkPath)).TrimEnd('.config')
		# Replace the "." and "\"
		$NewFileName = $NewFileName.Replace('\', '_')
		$NewFileName = $NewFileName.Replace('.', '_')
		# Add .config
		$NewFileName = $NewFileName + '.config'
		# Copy Item for data collection
		$NewFileName = Join-Path $IISConfigurationPath $NewFileName
		Copy-Item $_.FullName $NewFileName
		# Add file to array of files to be collected
		$files += $NewFileName
	}
	#TODO: below logic needs to be verified.
	if ($OSVersion.Major -ge 6) {
		# IIS 7.0 and Higher
		# Create Server manager object
		[System.Reflection.Assembly]::LoadFrom('C:\windows\system32\inetsrv\Microsoft.Web.Administration.dll') | Out-Null
		$serverManager = (New-Object Microsoft.Web.Administration.ServerManager)
		# Copy Config files to data collection directory
		$path = (Join-Path $env:windir 'system32\inetsrv\config\applicationHost.config')
		if (Test-Path $path) { $files += $path }
		$path = (Join-Path $env:windir 'system32\inetsrv\config\administration.config')
		if (Test-Path $path) { $files += $path }
		$path = (Join-Path $env:windir 'system32\inetsrv\config\redirection.config')
		if (Test-Path $path) {
			$files += $path
			# Look for configuration redirection
			$configRedir = $serverManager.GetRedirectionConfiguration()
			$config = $configRedir.GetSection( 'configurationRedirection', 'MACHINE/REDIRECTION' )
			if ($config.Attributes['enabled'].Value -eq 'True') {
				LogInfo "[$LogPrefix] Collecting Shared Configuration"
				# Copy over the shared configuration files
				$userName = $config.Attributes['userName'].Value
				$pDub = $config.Attributes['password'].Value
				$path = $config.Attributes['path'].Value
				$net = New-Object -ComObject Wscript.Network
				$drive = (Get-NextFreeDrive)[0]
				Trap { Continue; }
				$net.MapNetworkDrive($drive, $path , $false, $userName, $pDub)
				if (Test-Path $drive) {
					$pathAppHost = Join-Path $path 'applicationHost.config'
					$pathAdmin = Join-Path $path 'administration.config'
					if (Test-Path $pathAppHost) {
						$tempFile = 'SharedConfiguration_applicationHost.config'
						$tempFile = Join-Path $IISConfigurationPath $tempFile
						Copy-Item $pathAppHost $tempFile
						$files += $tempFile
					}
					if (Test-Path $pathAdmin) {
						$tempFile = 'SharedConfiguration_administration.config'
						$tempFile = Join-Path $IISConfigurationPath $tempFile
						Copy-Item $pathAdmin $tempFile
						$files += $tempFile
					}
					$net.RemoveNetworkDrive($drive, $true, $false)
				}
			}
		}
		$sites | ForEach-Object `
		{
			# Build Filename in this format  SITE_APP_VDIR_Web.config
			LogInfo "[$LogPrefix] Collecting IIS Configuration Files for site: $_" White
			$currentSiteName = $_
			$currentSite = $serverManager.Sites[$currentSiteName]
			$currentSite.Applications | ForEach-Object `
			{
				$AppPath = $_.Path
				$_.VirtualDirectories | ForEach-Object `
				{
					$VDirPath = $_.Path
					$path = $_.PhysicalPath
					$path = (Join-Path ([environment]::ExpandEnvironmentVariables($path)) 'web.config')
					if (Test-Path $path) {
						$NewFileName = $currentSiteName + $AppPath + $VDirPath + '_web.config'
						$NewFileName = $NewFileName.Replace('/', '_')
						$NewFileName = Join-Path $IISConfigurationPath $NewFileName
						Copy-Item $path $NewFileName
						$files += $NewFileName

						# Output the effectiveConfiguration at this level as well
						# Site_App_VDir_EffectiveConfiguration.config
						$NewFileName = $currentSiteName + $AppPath + $VDirPath + '_EffectiveConfiguration.config'
						$NewFileName = $NewFileName.Replace('/', '_')
						$NewFileName = Join-Path $IISConfigurationPath $NewFileName
						$configPath = $currentSiteName + $AppPath + $VDirPath
						$configPath = $configPath.TrimEnd('/')
						$cmdToRun = $env:WinDir + '\system32\inetsrv\appcmd.exe list config "' + $configPath + '" >"' + $NewFileName + '"'
						$Commands = @(
							"cmd /r $cmdToRun"
						)
						RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
						$files += $NewFileName
					}

					# Look for administration.config at this level too
					$path = $_.PhysicalPath
					$path = (Join-Path ([environment]::ExpandEnvironmentVariables($path)) 'administration.config')
					if (Test-Path $path) {
						# Collect the administration.config
						$NewFileName = $currentSiteName + $AppPath + $VDirPath + '_administration.config'
						$NewFileName = $NewFileName.Replace('/', '_')
						$NewFileName = Join-Path $IISConfigurationPath $NewFileName
						Copy-Item $path $NewFileName
						$files += $NewFileName
					}
				}
			}
				# Feature 669: SCCM TSS should collect IIS settings like Sites and their Bindings
				# Exporting sites and bindings
				Write-Output "Site Name: $($currentSite.name)" | Out-File -FilePath "$IISConfigurationPath\$($currentSiteName)___bindings.txt" -Append
				Write-Output "Bindings:" | Out-File -FilePath "$IISConfigurationPath\$($currentSiteName)___bindings.txt" -Append

				# Get all bindings for the current site
				$bindings = $currentSite.bindings
				# Loop through each binding
				foreach ($binding in $bindings) {
					Write-Output "`tProtocol: $($binding.protocol)" 							| Out-File -FilePath "$IISConfigurationPath\$($currentSiteName)___bindings.txt" -Append
					Write-Output "`tIPAddress: $($binding.bindingInformation.split(":")[0])"	| Out-File -FilePath "$IISConfigurationPath\$($currentSiteName)___bindings.txt" -Append
					Write-Output "`tPort: $($binding.bindingInformation.split(":")[1])"			| Out-File -FilePath "$IISConfigurationPath\$($currentSiteName)___bindings.txt" -Append
					Write-Output "`tHostname: $($binding.bindingInformation.split(":")[2])`n"	| Out-File -FilePath "$IISConfigurationPath\$($currentSiteName)___bindings.txt" -Append
				}
		}
	}
	else {
		# IIS 6.0
		# Copy metabase.xml to data collection directory
		$files += (Join-Path $env:windir 'system32\inetsrv\metabase.xml')
		# Copy Web.config for each site/application to data collection directory
		$sites | ForEach-Object `
		{
			LogInfo "[$LogPrefix] Collecting IIS Configuration Files for site: $_" White
			$currentSiteName = $_
			$siteQuery = "Select * From IIsWebServerSetting Where ServerComment = '{0}'" -f $currentSiteName
			Get-CimInstance -Namespace 'root/MicrosoftIISv2' -Query $siteQuery | ForEach-Object `
			{
				$appQuery = "Select * From IIsWebVirtualDirSetting Where Name LIKE '%{0}/%'" -f $_.Name
				Get-CimInstance -Namespace 'root/MicrosoftIISv2' -Query $appQuery | ForEach-Object `
				{
					$path =	$_.Path
					$VDirPath = $_.Name
					$path = (Join-Path ([environment]::ExpandEnvironmentVariables($path)) 'web.config')
					if (Test-Path $path) {
						$NewFileName = $VDirPath + '_web.config'
						$NewFileName = $NewFileName.Replace('/', '_')
						$NewFileName = Join-Path $IISConfigurationPath $NewFileName
						Copy-Item $path $NewFileName
						$files += $NewFileName
					}
				}
			}
		}
	}
	# Compress the destination folder into a ZIP file
	try {
		LogInfo "Compressing $IISConfigurationPath"
		Add-Type -Assembly 'System.IO.Compression.FileSystem'
		[System.IO.Compression.ZipFile]::CreateFromDirectory($IISConfigurationPath, $IISConfigurationZipFile)
		# Cleanup the destination folder
		if ($IISConfigurationPath) {
			Remove-Item -Path $IISConfigurationPath -Recurse -Force
		}
	}
	catch {
		LogException "Failed to compress $IISConfigurationPath" $_
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMIISConfig ---

#region --- Function Get-SCCMIISvDirInfo ---
function Get-SCCMIISvDirInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	if ($Is_IIS) {
		$LogPrefix = 'IIS vDir'
		LogInfo "[$LogPrefix] Obtaining a list of IIS Virtual Directories."
		Set-Variable -Name sites -Value @()
		$sites += 'Default Web Site'

		if ($Is_WSUS) {
			$siteID = Get-RegValue ($Reg_WSUS + '\Server\Setup') 'IISTargetWebSiteIndex'
			if ($siteID -ne 1) {
				$sites += 'WSUS Administration'
			}
		}

		$IISInfoFile = $Prefix + 'IIS_VDirInfo.txt'
		if ($OSVersion.Major -ge 6) {
			# IIS 7.0 and Higher
			[System.Reflection.Assembly]::LoadFrom('C:\windows\system32\inetsrv\Microsoft.Web.Administration.dll') | Out-Null
			$serverManager = (New-Object Microsoft.Web.Administration.ServerManager)
			$config = $serverManager.GetApplicationHostConfiguration()
			'------------------------------------'	| Out-File $IISInfoFile
			'IIS Virtual Directories Information'	| Out-File $IISInfoFile -Append
			"------------------------------------`n"	| Out-File $IISInfoFile -Append
			'  +--WEBSITES' | Out-File $IISInfoFile -Append

			$sites | ForEach-Object `
			{
				$currentSiteName = $_
				$currentSite = $serverManager.Sites[$currentSiteName]
				'       |  |' | Out-File $IISInfoFile -Append
				'       +--' + $currentSiteName | Out-File $IISInfoFile -Append

				$currentSite.Applications | ForEach-Object `
				{
					if ($_.Path -ne '/') {
						'       |  |' | Out-File $IISInfoFile -Append
						'       |  +--APP: ' + $_.Path | Out-File $IISInfoFile -Append
						'       |  |   AppPool: ' + $_.ApplicationPoolName | Out-File $IISInfoFile -Append
						$_.VirtualDirectories | ForEach-Object { '       |  |   Physical Path: ' + $_.PhysicalPath | Out-File $IISInfoFile -Append }
						$anonymousAuthenticationSection = $config.GetSection('system.webServer/security/authentication/anonymousAuthentication', ($currentSiteName + $_.Path))
						'       |  |   Anonymous Auth Enabled: ' + $anonymousAuthenticationSection['Enabled'] | Out-File $IISInfoFile -Append
						'       |  |   Anonymous Auth UserName: ' + $anonymousAuthenticationSection['userName'] | Out-File $IISInfoFile -Append
						$windowsAuthenticationSection = $config.GetSection('system.webServer/security/authentication/windowsAuthentication', ($currentSiteName + $_.Path))
						'       |  |   Windows Auth Enabled: ' + $windowsAuthenticationSection['Enabled'] | Out-File $IISInfoFile -Append
						$accessSection = $config.GetSection('system.webServer/security/access', ($currentSiteName + $_.Path))
						'       |  |   SSL Flags: ' + (ParseSSLFlags($accessSection['sslFlags'])) | Out-File $IISInfoFile -Append
						#$handlersSection = $config.GetSection("system.webServer/handlers", ($currentSiteName + $_.Path))
						#"       |  |   Access Policy: " + $handlersSection["accessPolicy"] | Out-File $IISInfoFile -Append
					}
					else {
						$_.VirtualDirectories | ForEach-Object `
						{
							if ($_.Path -ne '/') {
								'       |  |' | Out-File $IISInfoFile -Append
								'       |  +--VDIR: ' + $_.Path | Out-File $IISInfoFile -Append
								'       |  |   AppPool: Not Applicable' | Out-File $IISInfoFile -Append
								'       |  |   Physical Path: ' + $_.PhysicalPath | Out-File $IISInfoFile -Append
								$anonymousAuthenticationSection = $config.GetSection('system.webServer/security/authentication/anonymousAuthentication', ($currentSiteName + $_.Path))
								'       |  |   Anonymous Auth Enabled: ' + $anonymousAuthenticationSection['Enabled'] | Out-File $IISInfoFile -Append
								'       |  |   Anonymous Auth UserName: ' + $anonymousAuthenticationSection['userName'] | Out-File $IISInfoFile -Append
								$windowsAuthenticationSection = $config.GetSection('system.webServer/security/authentication/windowsAuthentication', ($currentSiteName + $_.Path))
								'       |  |   Windows Auth Enabled: ' + $windowsAuthenticationSection['Enabled'] | Out-File $IISInfoFile -Append
								$accessSection = $config.GetSection('system.webServer/security/access', ($currentSiteName + $_.Path))
								'       |  |   SSL Flags: ' + (ParseSSLFlags($accessSection['sslFlags'])) | Out-File $IISInfoFile -Append
								#$handlersSection = $config.GetSection("system.webServer/handlers", ($currentSiteName + $_.Path))
								#"       |  |   Access Policy: " + $handlersSection["accessPolicy"] | Out-File $IISInfoFile -Append
							}
						}
					}
				}
			}
		}
		else {
			# IIS 6.0
			if (Test-Path -Path "$global:ScriptFolder\scripts\tss_SCCM_IISVDirInfo.vbs") {
				try {
					Push-Location -Path "$global:Scriptfolder\psSDP\Diag\global"
					$CommandToExecute = "cscript.exe //e:vbscript $global:ScriptFolder\scripts\tss_SCCM_IISVDirInfo.vbs $IISInfoFile"
					LogInfo "[$LogPrefix] tss_SCCM_IISVDirInfo.vbs starting..."
					LogInfoFile "[$LogPrefix] $CommandToExecute"
					Invoke-Expression -Command $CommandToExecute >$null 2>> $ErrorFile
				}
				catch { LogException "[$LogPrefix] An Exception happend in tss_SCCM_IISVDirInfo.vbs" $_ }
				Pop-Location
				LogInfo "[$LogPrefix] tss_SCCM_IISVDirInfo.vbs completed."
			}
			else { LogInfo "[$LogPrefix] tss_SCCM_IISVDirInfo.vbs not found - skipping..." }
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMIISvDirInfo ---

#region --- Function Get-SCCMLogs ---
function Get-SCCMLogs {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'ConfigMgr Logs'

	LogInfo "[$LogPrefix] GetCCMLogs: $GetCCMLogs" DarkGreen
	LogInfo "[$LogPrefix] GetSMSLogs: $GetSMSLogs" DarkGreen
	LogInfo "[$LogPrefix] CCMSetup Logs Directory = $CCMSetupLogPath"
	LogInfo "[$LogPrefix] AdminUI Logs Directory: $AdminUILogPath"

	$ConfigMgrDestinationPath = $Prefix + 'Logs_ConfigMgr'
	$ZipName = $Prefix + 'Logs_ConfigMgr.zip'
	$ZipNameBase = Split-Path -Leaf $ZipName
	$Compress = $false

	# CCM Logs
	if ($null -ne $CCMLogPath) {
		LogInfo "[$LogPrefix] Getting CCM Logs"
		FwCreateFolder $ConfigMgrDestinationPath
		# CCM Logs
		if (Test-Path ($CCMLogPath)) {
			
			LogInfo "[$LogPrefix] Copying CCM Logs"
			$TempDestination = Join-Path $ConfigMgrDestinationPath 'CCM_Logs'
			FwCreateFolder $TempDestination
			# Copy-Item ($CCMLogPath + "\*.lo*") ($TempDestination) -ErrorAction SilentlyContinue -Force
			Copy-FilesWithStructure -Source $CCMLogPath -Destination $TempDestination -Include *.lo*
			if (Test-Path (Join-Path $Env:windir '\WindowsUpdate.log')) {
				Copy-Item ($Env:windir + '\WindowsUpdate.log') ($TempDestination) -ErrorAction SilentlyContinue
			}
			$Compress = $true
			
			# bg: capture EPAMPolicy.xml from c:\windows\ccm during SCCM capture
			LogInfo "[$LogPrefix] Copying EPAMPolicy.xml"
			if (Test-Path ("$CCMInstallDir\EPAMPolicy.xml")) {
				Copy-Item ("$CCMInstallDir\EPAMPolicy.xml") ($TempDestination) -ErrorAction SilentlyContinue -Force
			} else {
				LogInfo "[$LogPrefix] $CCMInstallDir\EPAMPolicy.xml does not exist."
			}

		}
		else {
			LogInfo "[$LogPrefix] $CCMLogPath does not exist. CCM Logs not collected. Check Logging\@Global\LogDirectory Registry Key Value."
		}

		if ($GetCCMLogs) {
			# Software Catalog Logs
			LogInfo "[$LogPrefix] Getting Software Catalog Logs for all users"
			$TempDestination = Join-Path $ConfigMgrDestinationPath 'CCM_SoftwareCatalog_Logs'
			FwCreateFolder $TempDestination
			if ($OSVersion.Major -lt 6) {
				$ProfilePath = Join-Path $env:systemdrive 'Documents and Settings'
				$SLPath = '\Local Settings\Application Data\Microsoft\Silverlight\is'
			}
			else {
				$ProfilePath = Join-Path $env:systemdrive 'Users'
				$SLPath = '\AppData\LocalLow\Microsoft\Silverlight\is'
			}

			Get-ChildItem $ProfilePath | `
				ForEach-Object {
				if (!$_.Name.Contains('All Users') -and !$_.Name.Contains('Default') -and !$_.Name.Contains('Public') -and !$_.Name.Contains('LocalService') -and !$_.Name.Contains('NetworkService') -and !$_.Name.Contains('Classic .NET AppPool')) {
					$currentUserName = $_.Name
					LogInfo "[$LogPrefix] Checking user $currentUserName"
					Get-ChildItem -Path (Join-Path $_.FullName $SLpath) -Recurse -Filter *ConfigMgr*.lo* -ErrorAction SilentlyContinue | `
						ForEach-Object {
						LogInfo "[$LogPrefix] Copying ConfigMgr Silverlight logs for $currentUserName"
						Copy-Item -Path $_.FullName -Destination "$TempDestination\$($currentUserName)_$($_)" -Force
						$Compress = $true
					}
				}
			}
		}
	}
	else {
		LogInfo "[$LogPrefix] Client detected but CCMLogPath is set to null. CCM Logs not collected. Check Logging\@Global\LogDirectory Registry Key Value."
	}

	# SMS Logs
	if ($null -ne $SMSLogPath) {
		LogInfo "[$LogPrefix] Getting SMS Logs"
		if (Test-Path ($SMSLogPath)) {
			# SMS Logs
			LogInfo "[$LogPrefix] Copying SMS Logs."
			$SubDestination = Join-Path $ConfigMgrDestinationPath 'SMS_Logs'
			FwCreateFolder $SubDestination
			# Copy-Item ($SMSLogPath + "\*.lo*") $SubDestination
			Copy-Files -Source $SMSLogPath -Destination $SubDestination -Filter *.lo*

			# Feature 665: Exclude CrashDumps directory collection from the SMS logs collection on a site server
			# We agreed to limit the collection to 5 instead of 10.
			if (Test-Path ($SMSLogPath + '\CrashDumps')) {
                LogInfo "[$LogPrefix] Copying most recent copy of SMS CrashDumps."
                $CrashDumpsDestination = Join-Path $ConfigMgrDestinationPath 'CrashDumps'
				FwCreateFolder $CrashDumpsDestination
				$CrashDumps = Get-ChildItem ($SMSLogPath + '\CrashDumps') | Sort-Object CreationTime -Descending | Select-Object -First 5
				$i = 0
				for ($i = 0 ; $i -lt $CrashDumps.Length ; $i++) {
					# copy all files from the latest crashdump folder and  append _Full to the foldername
					if ($i -eq 0) {
                        LogInfo "[$LogPrefix] Copying all files from $($CrashDumps[$i])"
						Copy-Item $($CrashDumps[$i]).PSPath ($ConfigMgrDestinationPath + '\CrashDumps\' + $($CrashDumps[$i]) + '_Full') -Recurse
					}
					# copy crash.log from the remaining other crashdump folders (limited by 'Select-Object -First') and create the destination folder
					else {
                        LogInfo "[$LogPrefix] Copying $($CrashDumps[$i])\crash.log"
						FwCreateFolder ($ConfigMgrDestinationPath + '\CrashDumps\' + $($CrashDumps[$i]))
						Copy-Item ($($CrashDumps[$i]).PSPath + '\crash.log') ($ConfigMgrDestinationPath + '\CrashDumps\' + $($CrashDumps[$i]) + '\crash.log') -ErrorAction SilentlyContinue
					}
				}
			}
			$Compress = $true
		}
		else {
			LogInfo "[$LogPrefix] $SMSLogPath does not exist. SMS Logs not collected. Check $Reg_SMS\Identification\Installation Directory Registry Key Value."
		}
	}
	else {
		LogInfo "[$LogPrefix] SMSLogPath is set to null. SMS Logs not collected. Check $Reg_SMS\Identification\Installation Directory Registry Key Value."
	}

	# Collect SQL Backup Logs for site database server. These are already in the Logs directory if running on a site server and collected by prior calls
	if ($global:Is_SiteDatabaseServer) {
		LogInfo "[$LogPrefix] Getting SQLBackup Logs"
		if ($null -ne $global:SQLBackupLogPathUNC) {
			if (Test-Path $global:SQLBackupLogPathUNC) {
				$SubDestination = Join-Path $ConfigMgrDestinationPath ('SMSSqlBackup_' + $ConfigMgrDBServer + '_Logs')
				FwCreateFolder $SubDestination

				LogInfo "[$LogPrefix] SubDestination = $SubDestination"
				#Copy-Item ($global:SQLBackupLogPathUNC + "\*.lo*") $SubDestination
				Copy-Files -Source $global:SQLBackupLogPathUNC -Destination $SubDestination -Filter *.lo*
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $global:SQLBackupLogPathUNC does not exist or Access Denied. SMS SQL Backup Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] SQLBackupLogPathUNC is set to null. SMS SQL Backup Logs not collected."
		}
	}

	# Collect DP Logs. For CM07, DPLogPath should be null.
	if ($null -ne $DPLogPath) {
		LogInfo "[$LogPrefix] Getting DP Logs"
		if (Test-Path ($DPLogPath)) {
			FwCreateFolder ($ConfigMgrDestinationPath + '\DP_Logs')
			# Copy-Item ($DPLogPath + "\*.lo*") ($ConfigMgrDestinationPath + "\DP_Logs")
			Copy-Files -Source $DPLogPath -Destination ($ConfigMgrDestinationPath + '\DP_Logs') -Filter *.lo*
			$Compress = $true
		}
		else {
			LogInfo "[$LogPrefix] $DPLogPath does not exist. DP Logs not collected."
		}
	}
	else {
		LogInfo "[$LogPrefix] DPLogPath is set to null. DP Logs not collected."
	}

	# Collect SMSProv Log(s) if SMS Provider is installed on Remote Server.
	if ($Is_SMSProv) {
		if ($Is_SiteServer -eq $false) {
			LogInfo "[$LogPrefix] Getting SMSProv Logs"
			if (Test-Path ($SMSProvLogPath)) {
				FwCreateFolder ($ConfigMgrDestinationPath + '\SMSProv_Logs')
				# Copy-Item ($SMSProvLogPath + "\*.lo*") ($ConfigMgrDestinationPath + "\SMSProv_Logs")
				Copy-Files -Source $SMSProvLogPath -Destination ($ConfigMgrDestinationPath + '\SMSProv_Logs') -Filter *.lo*

				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $SMSProvLogPath does not exist. SMS Provider Logs not collected."
			}
		}
	}

	# Collect AdminUI Logs
	if ($Is_AdminUI -and ($RemoteStatus -ne 2)) {
		if ($null -ne $AdminUILogPath) {
			LogInfo "[$LogPrefix] Getting AdminUI Logs"
			if (Test-Path ($AdminUILogPath)) {
				LogInfo "[$LogPrefix] Copying Admin Console Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\AdminUI_Logs')
				#$FilesToCopy = Get-ChildItem ($AdminUILogPath + "\*.log") | Where-Object -FilterScript {$_.Name -notlike "*-*"}
				#Copy-Item $FilesToCopy ($ConfigMgrDestinationPath + "\AdminUI_Logs")
				Copy-Files -Source $AdminUILogPath -Destination ($ConfigMgrDestinationPath + '\AdminUI_Logs') -Filter *.lo*
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $AdminUILogPath does not exist. AdminUI Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] AdminUI detected but AdminUILogPath is set to null. AdminUI Logs not collected."
		}
	}

	# Feature 674: PatchDownloader.log under %temp%
	if (Test-Path "$env:TEMP\PatchDownloader.log") {
		LogInfo "[$LogPrefix] Copying PatchDownloader.log file"
		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths = @(
			@("$env:TEMP\PatchDownloader.log", "$($ConfigMgrDestinationPath)\TEMP_PatchDownloader.log"),
			@("$env:TEMP\PatchDownloader.lo_", "$($ConfigMgrDestinationPath)\TEMP_PatchDownloader.lo_")
		)
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	}

	# Collect Setup logs
	if (Test-Path ("$Env:SystemDrive\ConfigMgr*.log")) {
		if ($RemoteStatus -ne 2) {
			LogInfo "[$LogPrefix] Copying Configuration Manager Setup Logs."
			FwCreateFolder ($ConfigMgrDestinationPath + '\ConfigMgrSetup_Logs')
			Copy-Item ($Env:SystemDrive + '\Config*.lo*') ($ConfigMgrDestinationPath + '\ConfigMgrSetup_Logs') -Force -ErrorAction SilentlyContinue
			Copy-Item ($Env:SystemDrive + '\Comp*.lo*') ($ConfigMgrDestinationPath + '\ConfigMgrSetup_Logs') -Force -ErrorAction SilentlyContinue
			Copy-Item ($Env:SystemDrive + '\Ext*.lo*') ($ConfigMgrDestinationPath + '\ConfigMgrSetup_Logs') -Force -ErrorAction SilentlyContinue
			$Compress = $true
		}
	}

	# Collect CCM Setup Logs
	if (Test-Path ($CCMSetupLogPath)) {
		LogInfo "[$LogPrefix] Copying CCM Setup Logs."
		FwCreateFolder ($ConfigMgrDestinationPath + '\CCMSetupRTM_Logs')
		FwCreateFolder ($ConfigMgrDestinationPath + '\CCMSetup_Logs')
		Copy-Item ($CCMSetupLogPath + '\*.log') ($ConfigMgrDestinationPath + '\CCMSetupRTM_Logs') -Recurse -Force -ErrorAction SilentlyContinue
		Copy-Item ($CCMSetupLogPath + '\Logs\*.log') ($ConfigMgrDestinationPath + '\CCMSetup_Logs') -Recurse -Force -ErrorAction SilentlyContinue
		$Compress = $true
	}

	# Collect WSUS Logs
	#if ($Is_WSUS -and ($RemoteStatus -ne 2))
	#{
	#	$WSUSLogPath = $WSUSInstallDir + "LogFiles"
	#	LogInfo "[$LogPrefix] WSUS Logs Directory: $WSUSLogPath"
	#	FwCreateFolder ($ConfigMgrDestinationPath + "\WSUS_Logs")
	#	Copy-Item ($WSUSLogPath + "\*.log") ($ConfigMgrDestinationPath + "\WSUS_Logs") -Force -ErrorAction SilentlyContinue
	#	$Compress = $true
	#}

	# Collect App Catalog Service Logs
	if ($Is_AWEBSVC -and ($RemoteStatus -ne 2)) {
		LogInfo "[$LogPrefix] Getting AppCatalogSvc Logs"
		if ($null -ne $AppCatalogSvcLogPath) {
			if (Test-Path ($AppCatalogSvcLogPath)) {
				LogInfo "[$LogPrefix] Copying Application Catalog Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\AppCatalogSvc_Logs')
				$FilesToCopy = Get-ChildItem ($AppCatalogSvcLogPath + '\*.*')
				Copy-Item $FilesToCopy ($ConfigMgrDestinationPath + '\AppCatalogSvc_Logs')
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $AppCatalogSvcLogPath does not exist. App Catalog Service Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] App Catalog Service Role detected but App Catalog Service Log Path is set to null. Logs not collected."
		}
	}

	# Collect App Catalog Website Logs
	if ($Is_PORTALWEB -and ($RemoteStatus -ne 2)) {
		LogInfo "[$LogPrefix] Getting App Catalog Logs"
		if ($null -ne $AppCatalogLogPath) {
			if (Test-Path ($AppCatalogLogPath)) {
				LogInfo "[$LogPrefix] Copying Application Catalog Service Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\AppCatalog_Logs')
				$FilesToCopy = Get-ChildItem ($AppCatalogLogPath + '\*.*')
				Copy-Item $FilesToCopy ($ConfigMgrDestinationPath + '\AppCatalog_Logs')
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $AppCatalogLogPath does not exist. App Catalog Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] App Catalog Role detected but App Catalog Log Path is set to null. Logs not collected."
		}
	}

	# Collect Enrollment Point Logs
	if ($Is_ENROLLSRV -and ($RemoteStatus -ne 2)) {
		LogInfo "[$LogPrefix] Getting Enrollment Point Logs"
		if ($null -ne $EnrollPointLogPath) {
			if (Test-Path ($EnrollPointLogPath)) {
				LogInfo "[$LogPrefix] Copying Enrollment Point Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\EnrollPoint_Logs')
				$FilesToCopy = Get-ChildItem ($EnrollPointLogPath + '\*.*')
				Copy-Item $FilesToCopy ($ConfigMgrDestinationPath + '\EnrollPoint_Logs')
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $EnrollPointLogPath does not exist. Enrollment Point Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] Enrollment Point Role detected but Enrollment Point Log Path is set to null. Logs not collected."
		}
	}

	# Collect Enrollment Proxy Point Logs
	if ($Is_ENROLLWEB -and ($RemoteStatus -ne 2)) {
		LogInfo "[$LogPrefix] Getting Enrollment Proxy Point Logs"
		if ($null -ne $EnrollProxyPointLogPath) {
			if (Test-Path ($EnrollProxyPointLogPath)) {
				LogInfo "[$LogPrefix] Copying Enrollment Proxy Point Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\EnrollProxyPoint_Logs')
				$FilesToCopy = Get-ChildItem ($EnrollProxyPointLogPath + '\*.*')
				Copy-Item $FilesToCopy ($ConfigMgrDestinationPath + '\EnrollProxyPoint_Logs')
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $EnrollProxyPointLogPath does not exist. Enrollment Proxy Point Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] Enrollment Proxy Point Role detected but Enrollment Proxy Point Log Path is set to null. Logs not collected."
		}
	}

	# Collect Certificate Registration Point Logs
	if ($Is_CRP -and ($RemoteStatus -ne 2)) {
		LogInfo "[$LogPrefix] Getting Certificate Registration Point Logs"
		if ($null -ne $CRPLogPath) {
			if (Test-Path ($CRPLogPath)) {
				LogInfo "[$LogPrefix] Copying Certificate Registration Point Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\CRP_Logs')
				$FilesToCopy = Get-ChildItem ($CRPLogPath + '\*.*')
				Copy-Item $FilesToCopy ($ConfigMgrDestinationPath + '\CRP_Logs')
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $CRPLogPath does not exist. Certificate Registration Point Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] Certificate Registration Point Role detected but Certificate Registration Point Log Path is set to null. Logs not collected."
		}
	}

	if ($Is_Lantern) {
		LogInfo "[$LogPrefix] Getting Policy Platform Logs"
		if ($null -ne $global:LanternLogPath) {
			if (Test-Path ($global:LanternLogPath)) {
				LogInfo "[$LogPrefix] Copying Policy Platform Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\PolicyPlatform_Logs')
				Copy-Item $global:LanternLogPath ($ConfigMgrDestinationPath + '\PolicyPlatform_Logs')
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $global:LanternLogPath does not exist. Microsoft Policy Platform Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] Microsoft Policy Platform is Installed but Log Path is set to null. Logs not collected."
		}
	}

	if ($Is_PXE) {
		LogInfo "[$LogPrefix] Getting WDS Logs"
		FwCreateFolder ($ConfigMgrDestinationPath + '\WDS_Logs')
		Copy-Item ("$Env:windir\tracing\wds*.log") ($ConfigMgrDestinationPath + '\WDS_Logs') -Recurse -Force -ErrorAction SilentlyContinue
		$Compress = $true
	}

	# Collect System Health Validator Point Logs
	if ($Is_SMSSHV -and ($RemoteStatus -ne 2)) {
		LogInfo "[$LogPrefix] Getting System Health Validator Point Logs"
		if ($null -ne $SMSSHVLogPath) {
			if (Test-Path ($SMSSHVLogPath)) {
				LogInfo "[$LogPrefix] Copying Enrollment Proxy Point Logs."
				FwCreateFolder ($ConfigMgrDestinationPath + '\SMSSHV_Logs')
				$FilesToCopy = Get-ChildItem ($SMSSHVLogPath + '\*.*')
				Copy-Item $FilesToCopy ($ConfigMgrDestinationPath + '\SMSSHV_Logs')
				$Compress = $true
			}
			else {
				LogInfo "[$LogPrefix] $SMSSHVLogPath does not exist. System Health Validator Point Logs not collected."
			}
		}
		else {
			LogInfo "[$LogPrefix] System Health Validator Point Role detected but System Health Validator Point Log Path is set to null. Logs not collected."
		}
	}

	# Feature 558: Collect ConfigMgr Server Archived Logs, if present.
	# Collect SMS Logs Archive
	if ($ConfigMgrServerLogsArchiveEnabled -eq '1') {
		if (Test-Path $ConfigMgrServerLogsArchivePath) {
			# SMS Logs Archive
			LogInfo "[$LogPrefix] Copying SMS Logs Archive."
			$SubDestination = Join-Path $ConfigMgrDestinationPath 'SMS_Logs_Archive'
			FwCreateFolder $SubDestination
			Copy-Files -Source $ConfigMgrServerLogsArchivePath -Destination $SubDestination -Filter *.lo*
			$Compress = $true
		}
		else {
			LogInfo "[$LogPrefix] ConfigMgr Server Logs Archive not enabled or path does not exist."
		}
	}
	else {
		LogInfo "[$LogPrefix] ConfigMgr Server Logs Archive not enabled or path does not exist."
	}

	# Feature 678: Add SMSCFG.ini in SCCM scenario
	if ($Is_Client -or $Is_MP) {
		LogInfo "[$LogPrefix] Copying SMSCFG.ini file"
		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths.add(@("$env:windir\SMSCFG.ini", "$($Prefix)smscfg.ini"))
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	}

	# Compress and Collect Logs if something was copied
	if ($Compress) {
		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $ConfigMgrDestinationPath"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($ConfigMgrDestinationPath, $ZipName)
			# Cleanup the destination folder
			if ($ConfigMgrDestinationPath) {
				Remove-Item -Path $ConfigMgrDestinationPath -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $ConfigMgrDestinationPath" $_
		}
	}
}
#endregion --- Function Get-SCCMLogs ---

#region --- Function Get-SCCMServiceStatus ---
function Get-SCCMServiceStatus {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'Service Status'

	### Check if Stopped ###
	# WMI
	Get-ServiceStatus -ServiceName 'WinMgmt' -DesiredState 'Running'
	# SMS Agent Host
	Get-ServiceStatus -ServiceName 'CcmExec' -DesiredState 'Running' -DesiredStartMode 'Automatic (Delayed Start)'
	# Windows Update
	if (($OSVersion.Major -ge 6) -and ($OSVersion.Minor -ge 2)) {
		# Win8 or Above
		Get-ServiceDisabled -ServiceName 'WuAuServ' -DesiredStartMode 'Manual' -RCDescription 'If the service is Disabled, it would lead to issues with Update Deployments'
	}
	else {
		Get-ServiceStatus -ServiceName 'WuAuServ' -DesiredState 'Running' -RCDescription 'If the service is Stopped, it could lead to issues with Update Deployments'
	}
	# Microsoft Policy Platform Local Authority
	Get-ServiceDisabled -ServiceName 'lpasvc' -DesiredStartMode 'Manual'
	# Microsoft Policy Platform Processor
	Get-ServiceDisabled -ServiceName 'lppsvc' -DesiredStartMode 'Manual'
	# BITS
	Get-ServiceDisabled -ServiceName 'BITS' -DesiredStartMode 'Manual'
	# Network List Service
	Get-ServiceDisabled -ServiceName 'netprofm' -DesiredStartMode 'Manual' -RCDescription 'If the service is Disabled, it could lead to client installation issues, failures to start ccmexec, MP issues and/or other network issues'
	# Network Location Awareness
	Get-ServiceStatus -ServiceName 'NlaSvc' -DesiredState 'Running' -RCDescription 'If the service is Stopped, it could lead to client installation issues, failures to start ccmexec, MP issues and/or other network issues'
	# Windows Installer
	Get-ServiceDisabled -ServiceName 'msiserver' -DesiredStartMode 'Manual' -RCDescription 'If the service is Disabled, it would lead to issues with Application and/or Update Installations'
	# SMS_EXECUTIVE
	Get-ServiceStatus -ServiceName 'SMS_EXECUTIVE' -DesiredState 'Running'
	# CONFIGURATION_MANAGER_UPDATE
	Get-ServiceStatus -ServiceName 'CONFIGURATION_MANAGER_UPDATE' -DesiredState 'Running'
	# SMS_SITE_COMPONENT_MANAGER
	Get-ServiceStatus -ServiceName 'SMS_SITE_COMPONENT_MANAGER' -DesiredState 'Running'
	# SMS_NOTIFICATION_SERVER
	Get-ServiceDisabled -ServiceName 'SMS_NOTIFICATION_SERVER' -DesiredStartMode 'Manual'
	# SMS_SITE_BACKUP
	Get-ServiceDisabled -ServiceName 'SMS_SITE_BACKUP' -DesiredStartMode 'Manual'
	# SMS_SITE_VSS_WRITER
	Get-ServiceStatus -ServiceName 'SMS_SITE_VSS_WRITER' -DesiredState 'Running'
	if ($Is_SiteSystem) {
		# Remote Registry
		Get-ServiceDisabled -ServiceName 'RemoteRegistry' -DesiredStartMode 'Manual' -RCDescription 'If the service is Disabled, it could lead to issues on Site Servers and Site Systems.'
		# Volume Shadow Copy
		Get-ServiceDisabled -ServiceName 'VSS' -DesiredStartMode 'Manual' -RCDescription 'If the service is Disabled, it would cause issues with Backups'
		# Server
		Get-ServiceStatus -ServiceName 'LanManServer' -DesiredState 'Running' -RCDescription 'If the service is Stopped, other machines would not be able to make SMB connections to this Server.'
		# Workstation
		Get-ServiceStatus -ServiceName 'LanManWorkstation' -DesiredState 'Running' -RCDescription 'If the service is Stopped, this machine would not be able to make SMB connections to other Servers.'
	}
	if ($Is_WSUS) {
		# Update Services
		Get-ServiceStatus -ServiceName 'WsusService' -DesiredState 'Running'
	}
	if ($Is_PXE) {
		# Windows Deployment Services Server
		Get-ServiceStatus -ServiceName 'WDSServer' -DesiredState 'Running'
	}
	if ($Is_IIS) {
		# IIS Admin Service
		Get-ServiceStatus -ServiceName 'IISADMIN' -DesiredState 'Running'
		# World Wide Web Publishing Service
		Get-ServiceStatus -ServiceName 'W3SVC' -DesiredState 'Running'
	}
	#TODO: What's happening with $InformationCollected? Where should we output our findings?
	#TODO: Did not migrate functions 'Update-DiagRootCause' and 'Add-GenericMessage' from # WindowsCSSToolsDevRep\Dev\ALL\TSSv2\psSDP\Diag\global\utils_Remote.ps1
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMServiceStatus ---

#region --- Function Get-SCCMProvisioningMode ---
function Get-SCCMProvisioningMode {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'Provisioning'
	$RuleApplicable = $false
	$RootCauseDetected = $false
	$RootCauseName = 'RC_ProvisioningMode'
	$InformationCollected = New-Object PSObject
	LogInfo "[$LogPrefix] Detecting if the Client is in Provisioning Mode."

	# Data Gathering
	if ($Is_Client) {
		$RuleApplicable = $true
		$CcmExecKey = $Reg_CCM + '\CcmExec'
		$ProvisioningMode = (Get-RegValue ($CcmExecKey) 'ProvisioningMode')
		$SystemTaskExcludes = (Get-RegValue ($CcmExecKey) 'SystemTaskExcludes')


		if (($ProvisioningMode -eq 'true') -or ($SystemTaskExcludes.Length -gt 0)) {
			LogInfo "[$LogPrefix] ProvisioningMode is enabled."
			$InformationCollected | Add-Member -MemberType NoteProperty -Name 'ProvisioningMode' -Value $ProvisioningMode
			$InformationCollected | Add-Member -MemberType NoteProperty -Name 'SystemTaskExcludes' -Value $SystemTaskExcludes
			$RootCauseDetected = $true
		}
		else {
			LogInfo "[$LogPrefix] ProvisioningMode is not enabled."
		}
		#Add information to InformationCollected
		#$InformationCollected | add-member -membertype noteproperty -name "Information Collected Name" -value $Value
	}

	# Root Cause processing
	if ($RuleApplicable) {
		if ($RootCauseDetected) {
			# Red/ Yellow Light
			#TODO: Uncomment if below TODO has been resolved.
			# Update-DiagRootCause -id $RootCauseName -Detected $true
			# Add-GenericMessage -Id $RootCauseName -InformationCollected $InformationCollected
		}
		else {
			# Green Light
			# Update-DiagRootCause -id $RootCauseName -Detected $false
		}
	}
	#TODO: What's happening with $InformationCollected? Where should we output our findings?
	#TODO: Did not migrate functions 'Update-DiagRootCause' and 'Add-GenericMessage' from # WindowsCSSToolsDevRep\Dev\ALL\TSSv2\psSDP\Diag\global\utils_Remote.
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMProvisioningMode ---

#region --- Function Get-SCCMDsRegCmd ---
function Get-SCCMDsRegCmd {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$DsRegCmdPath
	)
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'DsReg'
	LogInfo "[$LogPrefix] Gathering DsRegCmd information (DsRegCmd.exe)."

	FwGetDSregCmd -Subfolder $DsRegCmdPath

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion Function Get-SCCMDsRegCmd ---

#region --- Function Get-SCCMWindowsLogs ---
function Get-SCCMWindowsLogs {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'Windows Logs'

	$WindowsLogsDestination = $Prefix + 'Logs_Windows+OSD+SMSTS+SetupComplete'
	$WindowsLogsZipFile = $Prefix + 'Logs_Windows+OSD+SMSTS+SetupComplete.zip'
	FwCreateFolder $WindowsLogsDestination

	# WINDOWS LOGS #
	LogInfo "[$LogPrefix] Gathering: WINDOWS LOGS"
	#  Windows\Temp logs
	$TempLogPath = Join-Path $Env:windir 'Temp'
	$TempDestination = Join-Path $WindowsLogsDestination 'Temp_Logs'
	Copy-FilesWithStructure -Source $TempLogPath -Destination $TempDestination -Include *.lo*

	# User Temp Logs
	$TempLogPath = (Get-Item $env:temp).FullName
	$TempDestination = Join-Path $WindowsLogsDestination ('Temp_Logs_User_' + "$env:username")
	Copy-FilesWithStructure -Source $TempLogPath -Destination $TempDestination -Include *.lo*

	# Windows Update ETL Traces (Win 10)
	# Cannot use Get-WindowsUpdateLog because it presents a prompt to accept Terms for Public Symbol Server and there doesn't appear to be a way to skip the prompt, which is absolutely stupid
	# and prevents use of this CmdLet for automation. https://connect.microsoft.com/PowerShell/Feedback/Details/1690411
	$TempLogPath = Join-Path $Env:windir 'Logs\WindowsUpdate'
	$TempDestination = Join-Path $WindowsLogsDestination 'WindowsUpdate_ETL'
	Copy-FilesWithStructure -Source $TempLogPath -Destination $TempDestination -Include *.etl
	# Verbose WindowsUpdate ETL Log
	Copy-Files -Source $env:SystemDrive -Destination $TempDestination -Filter WindowsUpdateVerbose.etl

	# Setup Clean Task Logs (Win 10)
	$TempLogPath = Join-Path $Env:windir 'Logs\SetupCleanupTask'
	$TempDestination = Join-Path $WindowsLogsDestination 'SetupCleanupTask_Logs'
	Copy-FilesWithStructure -Source $TempLogPath -Destination $TempDestination -Include *.xml, *log

	# CBS Log
	$TempLogPath = Join-Path $Env:windir 'Logs\CBS'
	$TempDestination = Join-Path $WindowsLogsDestination 'CBS_Logs'
	Copy-FilesWithStructure -Source $TempLogPath -Destination $TempDestination -Include CBS.log, *.cab

	# WindowsUpdate.log (AGAIN!)
	$TempLogPath = Join-Path $Env:windir 'SoftwareDistribution'
	Copy-Files -Source $TempLogPath -Destination $WindowsLogsDestination -Filter ReportingEvents.log
	Copy-Files -Source $Env:windir -Destination $WindowsLogsDestination -Filter WindowsUpdate.log

	# OSD LOGS #
	LogInfo "[$LogPrefix] Gathering: OSD LOGS"
	# SMSTS Logs
	LogInfo "[$LogPrefix] Gathering: SMSTS Logs"
	$SMSTSLocation1 = if ($null -ne $CCMLogPath) { $CCMLogPath } else { Join-Path $Env:windir 'CCM\Logs' }
	$SMSTSLocation2 = $SMSTSLocation1 + '\SMSTSLog'
	$SMSTSLocation3 = Join-Path $env:SystemDrive '_SMSTaskSequence'
	$SMSTSLocation4 = Join-Path $env:SystemDrive 'SMSTSLog'
	$SMSTSLocation5 = Join-Path $env:windir 'Temp'

	$TempDestination = $WindowsLogsDestination + '\SMSTS_Logs'
	FwCreateFolder $TempDestination

	Copy-Files -Source $SMSTSLocation1 -Destination $TempDestination -Filter *SMSTS*.lo* -Recurse -RenameFileToPath
	Copy-Files -Source $SMSTSLocation1 -Destination $TempDestination -Filter ZTI*.lo* -Recurse -RenameFileToPath
	Copy-Files -Source $SMSTSLocation2 -Destination $TempDestination -Filter *.lo* -Recurse -RenameFileToPath
	Copy-Files -Source $SMSTSLocation3 -Destination $TempDestination -Filter *.lo* -Recurse -RenameFileToPath
	Copy-Files -Source $SMSTSLocation4 -Destination $TempDestination -Filter *.lo* -Recurse -RenameFileToPath
	Copy-Files -Source $SMSTSLocation5 -Destination $TempDestination -Filter *SMSTS*.lo* -RenameFileToPath

	# Panther logs
	LogInfo "[$LogPrefix] Gathering: Panther Logs"

	# \Windows\Panther directory
	$PantherLocation = Join-Path $Env:windir 'Panther'
	$PantherDirNewName = ($PantherLocation -replace '\\', '_') -replace ':', ''
	$PantherDirDestination = Join-Path $WindowsLogsDestination $PantherDirNewName
	Copy-FilesWithStructure -Source $PantherLocation -Destination $PantherDirDestination -Include *.xml, *.lo*, *.etl

	# \Windows\System32\Panther directory
	$PantherLocation = Join-Path $Env:windir 'System32\sysprep\Panther'
	$PantherDirNewName = ($PantherLocation -replace '\\', '_') -replace ':', ''
	$PantherDirDestination = Join-Path $WindowsLogsDestination $PantherDirNewName
	Copy-FilesWithStructure -Source $PantherLocation -Destination $PantherDirDestination -Include *.xml, *.log, *.etl

	# \$Windows.~BT\Sources\Panther directory (Win 10)
	$PantherLocation = Join-Path $Env:systemdrive "`$Windows.~BT\Sources\Panther"
	$PantherDirNewName = ($PantherLocation -replace '\\', '_') -replace ':', ''
	$PantherDirDestination = Join-Path $WindowsLogsDestination $PantherDirNewName
	# Try using psexec to copy these files, since the user may not have taken ownership of the folder
	$CmdToRun = "psexec.exe /accepteula -s robocopy /S /NP /NC /NFL /NDL /W:5 $PantherLocation $PantherDirDestination *.xml *.log *.etl *.evt *.evtx"
	$Commands = @("cmd /r $cmdToRun")
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	# \$Windows.~BT\Sources\Rollback\ (Win 10)
	$RollbackLocation = Join-Path $Env:systemdrive "`$Windows.~BT\Sources\Rollback"
	$RollbackLocationNewName = ($RollbackLocation -replace '\\', '_') -replace ':', ''
	$RollbackLocationDestination = Join-Path $WindowsLogsDestination $RollbackLocationNewName
	# Try using psexec to copy these files, since the user may not have taken ownership of the folder
	$CmdToRun = "psexec.exe /accepteula -s robocopy /S /NP /NC /NFL /NDL /W:5 $RollbackLocation $RollbackLocationDestination *.xml *.log *.etl *.txt *.evt *.evtx"
	$Commands = @("cmd /r $cmdToRun")
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	# INF Logs
	LogInfo "[$LogPrefix] Gathering: INF Logs"
	# \Windows\inf\*.log's
	$InfLogLocation = Join-Path $Env:windir 'INF'
	$TempDestination = $WindowsLogsDestination + '\INF_Logs'
	FwCreateFolder $TempDestination
	Copy-Files -Source $InfLogLocation -Destination $TempDestination -Filter *.lo* -Recurse

	# \Windows\Logs\DISM\*.log's
	LogInfo "[$LogPrefix] Gathering: DISM Logs"
	$DismLogPath = Join-Path $Env:windir 'Logs\DISM'
	$TempDestination = $WindowsLogsDestination + '\DISM_Logs'
	FwCreateFolder $TempDestination
	Copy-Files -Source $DismLogPath -Destination $TempDestination -Filter *.lo*

	# DPX Logs (Win 10)
	LogInfo "[$LogPrefix] Gathering: DPX Logs"
	$TempLogPath = Join-Path $Env:windir 'Logs\DPX'
	$TempDestination = $WindowsLogsDestination + '\DPX_Logs'
	Copy-FilesWithStructure -Source $TempLogPath -Destination $TempDestination -Include *.xml, *lo*

	# MOSETUP Logs (Win 10)
	LogInfo "[$LogPrefix] Gathering: MOSETUP Logs"
	$TempLogPath = Join-Path $Env:windir 'Logs\MoSetup'
	$TempDestination = $WindowsLogsDestination + '\MoSetup_Logs'
	Copy-FilesWithStructure -Source $TempLogPath -Destination $TempDestination -Include *.xml, *lo*

	# \Windows\UDI\*.log's
	LogInfo "[$LogPrefix] Gathering: UDI Logs"
	$UdiLogLocation = Join-Path $Env:windir 'UDI'
	$TempDestination = $WindowsLogsDestination + '\UDI_Logs'
	FwCreateFolder $TempDestination
	Copy-FilesWithStructure -Source $UdiLogLocation -Destination $TempDestination -Include *.lo*, *.xml, *.config, *.app, *.reg

	# Netsetup.log
	$TempLogPath = Join-Path $Env:windir 'debug'
	Copy-FilesWithStructure -Source $TempLogPath -Destination $WindowsLogsDestination -Include Netsetup.log

	LogInfo "[$LogPrefix] Copying deploymentlogs, _SMSTaskSequence, minint, smsts.log, setupcomplete.log"
	FwCreateFolder "$WindowsLogsDestination\UpgradeSetup"
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:systemroot\temp\deploymentlogs\*.*", "$WindowsLogsDestination\UpgradeSetup\deploymentlogs"),
		@("$env:SystemDrive\_SMSTaskSequence\*.*", "$WindowsLogsDestination\UpgradeSetup\_SMSTaskSequence"),
		@("$env:SystemDrive\minint\*.*", "$WindowsLogsDestination\UpgradeSetup\minint"),
		@("$env:TEMP\smstslog\smsts.log", "$WindowsLogsDestination\UpgradeSetup\smsts-currentusertemp.log"),
		@("$env:SystemDrive\users\administrator\appdata\local\temp\smstslog\smsts.log", "$WindowsLogsDestination\UpgradeSetup\smsts-admintemp.log"),
		@("$env:windir\setupcomplete.log", "$WindowsLogsDestination\UpgradeSetup\setupcomplete.log")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

	#region Feature 643
	# Feature 643: Collect Windows 11 upgrade keys, blocking reasons, etc for SCCM TSS
	$RegKeys = @(
		('HKLM:SOFTWARE\Microsoft\SQMClient', "$WindowsLogsDestination\UpgradeSetup\reg_SQMClient.txt"),
		('HKLM:SOFTWARE\Microsoft\WufbDS', "$WindowsLogsDestination\UpgradeSetup\WindowsUpdate_reg_WufbDS.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$WindowsLogsDestination\UpgradeSetup\reg_LocalMachine-AppCompatFlags.txt"),
		('HKCU:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$WindowsLogsDestination\UpgradeSetup\reg_CurrentUser-AppCompatFlags.txt")
	)
	FwExportRegistry $LogPrefix $RegKeys

	# Trying to retrieve CTAC attributes
	# AnalyticsInfo.GetSystemPropertiesAsync(IIterable<String>) Method, Windows requirements Windows 10, version 1803 (introduced in 10.0.17134.0)
	# https://learn.microsoft.com/en-us/uwp/api/windows.system.profile.analyticsinfo.getsystempropertiesasync?view=winrt-22621
	if (($OSVersion.Major -eq 10 -and [int]$OSVersion.Build -ge 17763) -or ($OSVersion.Major -gt 10)) {
		try {
			<#  Async helper from https://fleexlab.blogspot.com/2018/02/using-winrts-iasyncoperation-in.html
                WinRT types can be used from PowerShell if explicitly named first. Many WinRT API methods are asynchronous, returning genericized IAsyncOperation objects that come into PowerShell as System.__ComObject.
                Trying to use any methods on such objects fails. Some people have written compiled assemblies in C# that convert async operations to standard .NET tasks and then await them, but this can be accomplished in pure PowerShell with some reflection:
            #>
			Add-Type -AssemblyName System.Runtime.WindowsRuntime
			$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
			Function Await($WinRtTask, $ResultType) {
				$asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
				$netTask = $asTask.Invoke($null, @($WinRtTask))
				$netTask.Wait(-1) | Out-Null
				$netTask.Result
			}

			# CTAC API
			[void][Windows.System.Profile.AnalyticsInfo, Windows.System, ContentType = WindowsRuntime]
			$attributes = @('+WU')
			# The parentheses around the arguments are important, otherwise PowerShell tries to be helpful and interpret them as string literals.
			$results = Await ([Windows.System.Profile.AnalyticsInfo]::GetSystemPropertiesAsync([System.Collections.Generic.IEnumerable[String]][String[]]$attributes)) ([System.Collections.Generic.IReadOnlyDictionary[string, string]])
			$results | ForEach-Object { Write-Output "$($_.Key)=$($_.Value)" } | Out-File -FilePath "$WindowsLogsDestination\UpgradeSetup\WindowsUpdate_CTAC.txt" -Append
		}
		catch { LogException ("[$LogPrefix] Common Targeting Attribute Client failed to retrieve attributes.") $_ }
	}

	$LIDFile = "$WindowsLogsDestination\UpgradeSetup\reg_LID.txt"
	$LIDregKeyPath = 'HKU:\.DEFAULT\Software\Microsoft\IdentityCRL\ExtendedProperties'
	$LIDpropertyName = 'LID'
	$psDriveName = 'HKU'
	if (-not (Test-Path -Path "Registry::$LIDregKeyPath") -and -not (Get-PSDrive -Name $psDriveName -ErrorAction SilentlyContinue)) {
		New-PSDrive -Name $psDriveName -PSProvider Registry -Root HKEY_USERS | Out-Null
	}
	if (Test-Path $LIDregKeyPath) {
		LogInfo ("[$LogPrefix] Trying to retrieve global device ID.")
		try {
			$LIDValue = Get-ItemProperty -Path $LIDregKeyPath -Name $LIDpropertyName
			# Convert the hexadecimal "LID" value to a formatted string
			$LIDFormatted = 'g:{0}' -f [Int64]"0x$($LIDValue.LID)"
			LogInfo ("[$LogPrefix] Retrieved global device ID.")
			Write-Output $LIDregKeyPath | Out-File -Append $LIDFile
			Write-Output $line | Out-File -Append $LIDFile
			Write-Output "LID (value in registry):`t$($LIDValue.LID)" | Out-File -Append $LIDFile
			Write-Output "LID (formatted):`t`t`t`t`t$LIDFormatted" | Out-File -Append $LIDFile
			Remove-PSDrive -Name HKU
		}
		catch {
			LogWarn ("[$LogPrefix] Failed to retrieve global device ID.")
		}
	}
	#endregion Feature 643


	# Compress and Collect Logs if something was copied
	if (Test-Path $WindowsLogsDestination) {
		# Compress the destination folder into a ZIP file
		try {
			LogInfo "Compressing $WindowsLogsDestination"
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
			[System.IO.Compression.ZipFile]::CreateFromDirectory($WindowsLogsDestination, $WindowsLogsZipFile)
			# Cleanup the destination folder
			if ($WindowsLogsDestination) {
				Remove-Item -Path $WindowsLogsDestination -Recurse -Force
			}
		}
		catch {
			LogException "Failed to compress $WindowsLogsDestination" $_
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMWindowsLogs ---

#region --- Function Get-SCCMNamespaceInfo ---
function Get-SCCMNamespaceInfo {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'Namespace Info'
	$IssueDetected = $false
	$RootCauseName = 'RC_CheckCCMNamespace'

	## Verify that root\CCM namespace exists if SCCM Client is installed. If it exists, verify we can connect to it
	if ($Is_Client) {
		## Root Cause Detection ##
		LogInfo "[$LogPrefix] Checking connection to root\CCM WMI namespace."

		$Error.Clear()
		$ErrorInfo = New-Object PSObject

		#	If (Get-CimInstance -Namespace root -Class __NameSpace | Where {$_.Name -match 'CCM'})
		#	{
		# CCM Namespace Exists.
		if ((Get-CimInstance -Namespace root\CCM -Class SMS_Client -ErrorAction SilentlyContinue) -isnot [CimInstance]) {
			# Connection Failed. Issue detected.
			$IssueDetected = $true
			$ErrorCode = ($Error[0].Exception.ErrorCode.value__).ToString()
			$ErrorMsg = ($Error[0].Exception.Message).Trim()
			Add-Member -InputObject $ErrorInfo -MemberType NoteProperty -Name 'Error Code' -Value $ErrorCode
			Add-Member -InputObject $ErrorInfo -MemberType NoteProperty -Name 'Error Message' -Value $ErrorMsg
		}
		#	}
		#	Else
		#	{
		#		# Namespace Does not Exist. Issue Detected.
		#		$IssueDetected = $true
		#		Add-Member -InputObject $ErrorInfo -MemberType NoteProperty -Name "Connection Error" -Value "Namespace does not exist"
		#		Add-Member -InputObject $ErrorInfo -MemberType NoteProperty -Name "Error Code" -Value "-2147217394"
		#	}


		## Root Cause Alert ##
		LogInfo "[$LogPrefix] Root Cause detected: $IssueDetected"
		if ($IssueDetected) {
			#TODO: What's happening with $InformationCollected? Where should we output our findings?
			#TODO: Did not migrate functions 'Update-DiagRootCause' and 'Add-GenericMessage' from # WindowsCSSToolsDevRep\Dev\ALL\TSSv2\psSDP\Diag\global\utils_Remote.ps1
			# Update-DiagRootCause -id $RootCauseName -Detected $true
			# Write-GenericMessage -RootCauseId $RootCauseName -Verbosity "Error" -InformationCollected $ErrorInfo -Visibility 2 -SupportTopicsID 7366
		}
		#	Else
		#	{
		#		Update-DiagRootCause -id $RootCauseName -Detected $false
		#	}

		# Test
		# Write-DiagProgress -Activity "Finishing Execution" -Status "Waiting for background processes"
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMNamespaceInfo ---

#region --- Function Get-SCCMUpdateHistory ---
function Get-SCCMUpdateHistory {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'Update History'
	trap {
		LogException "Error running function Get-SCCMUpdateHistory." $_
		continue
	}
	# Store the updates history output information in CSV, TXT, XML format
	$Script:SbCSVFormat = New-Object -TypeName System.Text.StringBuilder
	$Script:SbTXTFormat = New-Object -TypeName System.Text.StringBuilder
	$Script:SbXMLFormat = New-Object -TypeName System.Text.StringBuilder

	# Store the WU errors
	$Script:WUErrors

	# Store the Updated installed in the past $NumberOfDays days when $ExportOnly is not used
	if ($ExportOnly.IsPresent -eq $false) {
		$LatestUpdates_Summary = New-Object PSObject
		$LatestUpdates_Summary | Add-Member -MemberType NoteProperty -Name '  Date' -Value ("<table><tr><td width=`"40px`" style=`"border-bottom:1px solid #CCCCCC`">Results</td><td width=`"60px`" style=`"border-bottom:1px solid #CCCCCC`">ID</td><td width=`"300px`" style=`"border-bottom:1px solid #CCCCCC`">Category</td></tr></table>")
		[int]$Script:LatestUpdateCount = 0
	}

	LogInfo "[$LogPrefix] Obtaining Update History."

	# Get updates from the com object
	LogInfo "[$LogPrefix] Querying IUpdateSession Interface to get the Update History"

	# check if wuauserv is disabled to prevent exception during log collection
	if ((Get-Service wuauserv).StartType -ne [System.ServiceProcess.ServiceStartMode]::Disabled) {
		try {
			$Session = New-Object -ComObject Microsoft.Update.Session
			$Searcher = $Session.CreateUpdateSearcher()
			$HistoryCount = $Searcher.GetTotalHistoryCount()
			if ($HistoryCount -gt 0) {
				trap [Exception] {
					LogException 'Querying Update History' $_
					continue
				}

				$ComUpdateHistory = $Searcher.QueryHistory(1, $HistoryCount)
			}
			else {
				$ComUpdateHistory = @()
				LogInfo 'No updates found on Microsoft.Update.Session'
			}
		}
		catch { LogException "[$LogPrefixWU] Getting Update History - summary failed." $_ }

		# Get updates from the Wmi object Win32_QuickFixEngineering
		LogInfo 'Querying Win32_QuickFixEngineering to obtain updates that are not on update history'

		$QFEHotFixList = New-Object 'System.Collections.ArrayList'
		$QFEHotFixList.AddRange(@(Get-CimInstance -Class Win32_QuickFixEngineering))

		# Get updates from the regsitry keys
		LogInfo 'Querying Updates listed in the registry'
		$RegistryHotFixList = GetHotFixFromRegistry

		LogInfo "[$LogPrefix] Generating output files."
		PrintHeaderOrXMLFooter -IsHeader

		# Format each update history to the stringbuilder
		LogInfo "Generating information for $HistoryCount updates found on update history"
		foreach ($updateEntry in $ComUpdateHistory) {
			#Do not list the updates on which the $updateEntry.ServiceID = '117CAB2D-82B1-4B5A-A08C-4D62DBEE7782'. These are Windows Store updates and are bringing inconsistent results
			if ($updateEntry.ServiceID -ne '117CAB2D-82B1-4B5A-A08C-4D62DBEE7782') {
				$HotFixID = GetHotFixID $updateEntry.Title
				$HotFixIDNumber = ToNumber $HotFixID
				$strInstalledBy = ''
				$strSPLevel = ''

				if (($HotFixID -ne '') -or ($HotFixIDNumber -ne '')) {
					foreach ($QFEHotFix in $QFEHotFixList) {
						if (($QFEHotFix.HotFixID -eq $HotFixID) -or ((ToNumber $QFEHotFix.HotFixID) -eq $HotFixIDNumber)) {
							$strInstalledBy = ConvertSIDToUser $QFEHotFix.InstalledBy
							$strSPLevel = $QFEHotFix.ServicePackInEffect

							#Remove the duplicate HotFix in the QFEHotFixList
							$QFEHotFixList.Remove($QFEHotFix)
							break
						}
					}
				}

				#Remove the duplicate HotFix in the RegistryHotFixList
				if ($RegistryHotFixList.Keys -contains $HotFixID) {
					$RegistryHotFixList.Remove($HotFixID)
				}

				$strCategory = ''
				if ($updateEntry.Categories.Count -gt 0) {
					$strCategory = $updateEntry.Categories.Item(0).Name
				}

				if ([String]::IsNullOrEmpty($strCategory)) {
					$strCategory = '(None)'
				}

				$strOperation = GetUpdateOperation $updateEntry.Operation
				$strDateTime = FormatDateTime $updateEntry.Date
				$strResult = GetUpdateResult $updateEntry.ResultCode

				PrintUpdate $strCategory $strSPLevel $HotFixID $strOperation $strDateTime $updateEntry.ClientApplicationID $strInstalledBy $strResult $updateEntry.Title $updateEntry.Description $updateEntry.HResult $updateEntry.UnmappedResultCode
			}
		}

		# Out Put the Non History QFEFixes
		LogInfo "Generating information for $($QFEHotFixList.Count) updates found on Win32_QuickFixEngineering WMI class"
		foreach ($QFEHotFix in $QFEHotFixList) {
			$strInstalledBy = ConvertSIDToUser $QFEHotFix.InstalledBy
			$strDateTime = FormatDateTime $QFEHotFix.InstalledOn
			$strCategory = ''

			#Remove the duplicate HotFix in the RegistryHotFixList
			if ($RegistryHotFixList.Keys -contains $QFEHotFix.HotFixID) {
				$strCategory = $RegistryHotFixList[$QFEHotFix.HotFixID].Category
				$strRegistryDateTime = FormatDateTime $RegistryHotFixList[$QFEHotFix.HotFixID].InstalledDate
				if ([String]::IsNullOrEmpty($strInstalledBy)) {
					$strInstalledBy = $RegistryHotFixList[$QFEHotFix.HotFixID].InstalledBy
				}

				$RegistryHotFixList.Remove($QFEHotFix.HotFixID)
			}

			if ([string]::IsNullOrEmpty($strCategory)) {
				$strCategory = 'QFE hotfix'
			}
			if ($strDateTime.Length -eq 0) {
				$strDateTime = $strRegistryDateTime
			}
			if ([string]::IsNullOrEmpty($QFEHotFix.Status)) {
				$strResult = 'Completed successfully'
			}
			else {
				$strResult = $QFEHotFix.Status
			}

			PrintUpdate $strCategory $QFEHotFix.ServicePackInEffect $QFEHotFix.HotFixID 'Install' $strDateTime '' $strInstalledBy $strResult $QFEHotFix.Description $QFEHotFix.Caption
		}

		LogInfo "Generating information for $($RegistryHotFixList.Count) updates found on registry"
		foreach ($key in $RegistryHotFixList.Keys) {
			$strCategory = $RegistryHotFixList[$key].Category
			$HotFixID = $RegistryHotFixList[$key].HotFixID
			$strDateTime = $RegistryHotFixList[$key].InstalledDate
			$strInstalledBy = $RegistryHotFixList[$key].InstalledBy
			$ClientID = $RegistryHotFixList[$key].InstallerName

			if ($HotFixID.StartsWith('Q')) {
				$Description = $RegistryHotFixList[$key].Description
			}
			else {
				$Description = $RegistryHotFixList[$key].PackageName
			}

			if ([string]::IsNullOrEmpty($Description)) {
				$Description = $strCategory
			}

			PrintUpdate $strCategory '' $HotFixID 'Install' $strDateTime $ClientID $strInstalledBy 'Completed successfully' $strCategory $Description
		}

		PrintHeaderOrXMLFooter -IsXMLFooter

		LogInfo "[$LogPrefix] Generate Update Histories files and collect it."
		$FileNameWithoutExtension = $Prefix + 'Hotfixes' + $Suffix

		LogInfo 'Creating output files'
		if ($OutputFormats -contains 'CSV') {
			$Script:SbCSVFormat.ToString() | Out-File ($FileNameWithoutExtension + '.CSV') -Encoding 'UTF8'
		}

		if ($OutputFormats -contains 'TXT') {
			$Script:SbTXTFormat.ToString() | Out-File ($FileNameWithoutExtension + '.TXT') -Encoding 'UTF8'
		}

		if ($OutputFormats -contains 'HTM') {
			$Script:SbXMLFormat.ToString().replace('&', '') | Out-File ($FileNameWithoutExtension + '.XML') -Encoding 'UTF8'

			LogInfo 'Generate the HTML Updates file according the UpdateHistory.xsl and XML file'
			GenerateHTMFile $FileNameWithoutExtension
		}

		#$FileToCollects = @("$FileNameWithoutExtension.CSV", "$FileNameWithoutExtension.TXT", "$FileNameWithoutExtension.HTM")

		if ($ExportOnly.IsPresent) {
			Copy-Item $FileToCollects -Destination (Join-Path $PWD.Path 'result')
		}
		else {
			if ($Script:LatestUpdateCount -gt 0) {
				$LatestUpdates_Summary | Add-Member -MemberType NoteProperty -Name 'More Information' -Value ("<table><tr><td>For a complete list of installed updates, please open <a href= `"`#" + $FileNameWithoutExtension + ".HTM`">" + $FileNameWithoutExtension + '.HTM</a></td></tr></table>')
				#$LatestUpdates_Summary | ConvertTo-Xml2 -sortObject | update-diagreport -id 11_Updates -name "Updates installed in past $NumberOfDays days ($($Script:LatestUpdateCount))" -verbosity informational
			}

			#CollectFiles -filesToCollect $FileToCollects -fileDescription 'Installed Updates and Hotfixes' -sectionDescription 'General Information'
		}

		# --------------------------------------------------------------- added: 2019-07-15 #_#
		if ($Global:runFull -eq $True) {
			try {
				LogInfo ("[$LogPrefix] Retrieve installed updates from Win32_QuickFixEngineering class.")
				Get-CimInstance -ClassName win32_quickfixengineering | Out-File -FilePath $OutputFile
				# Get update id list with wmic, replaced
				# wmic qfe list full /format:texttable >> ($Prefix+"Hotfix-WMIC.txt") 2>> $ErrorFile
			}
			catch { LogException "[$LogPrefix] Failed to retrieve installed Updates from Win32_QuickFixEngineering class." $_ }

			#----------Get Windows Update Configuration info
			try {
				$OutputFile = $Prefix + 'WindowsUpdateConfiguration.txt'
				LogInfo 'Windows Update Configuration info'
				'===================================================='	| Out-File -FilePath $OutputFile -Append
				'Windows Update Configuration info' | Out-File -FilePath $OutputFile -Append
				'===================================================='	| Out-File -FilePath $OutputFile -Append
				$MUSM = New-Object -ComObject 'Microsoft.Update.ServiceManager'
				$MUSM.Services | Select-Object Name, IsDefaultAUService, OffersWindowsUpdates | Out-File -FilePath $OutputFile -Append
				"`n`n" | Out-File -FilePath $OutputFile -Append
				'===================================================='	| Out-File -FilePath $OutputFile -Append
				'Now get all data' | Out-File -FilePath $OutputFile -Append
				'===================================================='	| Out-File -FilePath $OutputFile -Append
				$MUSM = New-Object -ComObject 'Microsoft.Update.ServiceManager'
				$MUSM.Services | Out-File -FilePath $OutputFile -Append
			}
			catch { LogException "[$LogPrefix] Failed to retrieve Windows Update Configuration info." $_ }
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMUpdateHistory ---

#region --- Function Get-SCCMHotfixRollups ---
function Get-SCCMHotfixRollups {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."

	$LogPrefix = 'Hotfix Rollups'

	trap [Exception] {
		LogException "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)):" $_
		continue
	}

	$ReferenceCSVpath = "$global:ScriptFolder\psSDP\Diag\global\rfl_Hotfix.csv"
	if (Test-Path $ReferenceCSVpath) {
		$OutputFile = $Prefix + 'HotfixRollups.TXT'
		# get list of installed fixes only once for performance reason
		$hotfixesWMIQuery = 'SELECT * FROM Win32_QuickFixEngineering' #_# WHERE HotFixID='KB$hotfixID'"
		$script:hotfixesWMI = Get-CimInstance -Query $hotfixesWMIQuery #_# or PS > Get-HotFix

		#----------detect OS version and SKU
		$wmiOSVersion = Get-CimInstance -Namespace 'root\cimv2' -Class Win32_OperatingSystem
		[int]$bn = [int]$wmiOSVersion.BuildNumber

		$ReferenceCSV = Import-Csv $ReferenceCSVpath

		if ($bn -match 22621) {
			# Win 11 22H2 = 22621
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 11 22H2' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq 'Win1122H2') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
		}
		elseif ($bn -match 2200) {
			# Win 11 = 22000
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 11 ' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq 'Win11') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
		}
		elseif ($bn -match 20348) {
			# Server 2022 = 20348
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows Server 2022 ' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2022') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
		}
		elseif (($bn -match 19042) -or ($bn -match 19044)) {
			# 20H2 = 19042, 21H2 = 19044
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 10 20H2/21H2 and Windows Server 2019 20H2/21H2 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '201621H2') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
		}
		elseif ($bn -match 19045) {
			# 22H2 = 19045, 22H2 has C/D updates
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 10 22H2 and Windows Server 2019 22H2 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '201622H2') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
		}
		elseif ($bn -eq 17763) {
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 10 RS5 v1809 and Windows Server 2019 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2016RS5') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
			CheckForHotfix -hotfixID 5005112 -title 'KB5005112: Servicing stack update for Windows 10, version 1809: August 10, 2021'
		}
		elseif ($bn -eq 14393) {
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 10 RS1 v1607 and Windows Server 2016 RS1 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2016RS1') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
			CheckForHotfix -hotfixID 5005698 -title 'KB5005698: Servicing stack update for Windows 10, version 1607: September 14, 2021'
		}
		elseif ($bn -eq 10240) {
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 10 and Windows Server 2016 RTM Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2016') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
			CheckForHotfix -hotfixID 5001399 -title 'KB5001399: Servicing stack update for Windows 10: April 13, 2021'
		}
		elseif ($bn -eq 9600) {
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 8.1 and Windows Server 2012 R2 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2012R2') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
			CheckForHotfix -hotfixID 5001403 -title 'KB5001403: Servicing stack update for Windows 8.1, Windows RT 8.1, and Windows Server 2012 R2: April 13, 2021'
			CheckForHotfix -hotfixID 3123245 -title 'Update improves port exhaustion identification in Windows Server 2012 R2'
			CheckForHotfix -hotfixID 3179574 -title 'August 2016 update rollup for Windows RT 8.1, Windows 8.1, and Windows Server 2012 R2'
			CheckForHotfix -hotfixID 3172614 -title 'July 2016 update rollup for Windows RT 8.1, Windows 8.1, and Windows Server 2012 R2'
			CheckForHotfix -hotfixID 3013769 -title 'December 2014 update rollup for Windows RT 8.1, Windows 8.1, and Windows Server 2012 R2'
			CheckForHotfix -hotfixID 3000850 -title 'November 2014 update rollup for Windows RT 8.1, Windows 8.1, and Windows Server 2012 R2'
			CheckForHotfix -hotfixID 2919355 -title 'Windows RT 8.1, Windows 8.1, and Windows Server 2012 R2 Update: April 2014'
		}
		elseif ($bn -eq 9200) {
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows Server 2012 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2012') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
			CheckForHotfix -hotfixID 5001401 -title 'KB5001401: Servicing stack update for Windows Server 2012: April 13, 2021'
			CheckForHotfix -hotfixID 3179575 -title 'August 2016 update rollup for Windows Server 2012'
			CheckForHotfix -hotfixID 2984005 -title 'September 2014 update rollup for Windows RT, Windows 8, and Windows Server 2012'
			CheckForHotfix -hotfixID 2962407 -title 'Windows RT, Windows 8, and Windows Server 2012 update rollup: June 2014'
			CheckForHotfix -hotfixID 2934016 -title 'Windows RT, Windows 8, and Windows Server 2012 update rollup: April 2014'
			CheckForHotfix -hotfixID 2862768 -title 'Windows RT, Windows 8, and Windows Server 2012 update rollup: August 2013'
			CheckForHotfix -hotfixID 2756872 -title 'Windows 8 Client and Windows Server 2012 General Availability Update Rollup'
		}
		elseif ($bn -eq 7601) {
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows 7 and Windows Server 2008 R2 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "   (RTM=7600, SP1=7601)`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2008R2') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
			CheckForHotfix -hotfixID 3125574 -title 'Convenience roll-up update for Windows 7 SP1 and Windows Server 2008 R2 SP1' -Warn 'Yes'
			CheckForHotfix -hotfixID 4490628 -title 'Servicing stack update for Windows 7 SP1 and Windows Server 2008 R2 SP1: March 12, 2019'
			CheckForHotfix -hotfixID 4592510 -title 'Servicing stack update for Windows 7 SP1 and Server 2008 R2 SP1: December 8, 2020'
			CheckForHotfix -hotfixID 5010451 -title 'KB5010451: Servicing stack update for Windows 7 SP1 and Server 2008 R2 SP1: February 8, 2022'
			CheckForHotfix -hotfixID 4538483 -title 'Extended Security Updates (ESU) Licensing Preparation Package for Windows 7 SP1 and Windows Server 2008 R2 SP1'
			CheckForHotfix -hotfixID 2775511 -title 'An enterprise hotfix rollup is available for Windows 7 SP1 and Windows Server 2008 R2 SP1'
		}
		elseif (($bn -eq 6002) -or ($bn -eq 6003)) {
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'Windows Vista and Windows Server 2008 Rollups' | Out-File -FilePath $OutputFile -Append
			'==================================================' | Out-File -FilePath $OutputFile -Append
			'OS Build:  ' + $bn + "   (RTM=6000, SP2=6002 or 6003)`n" | Out-File -FilePath $OutputFile -Append
			'Installed   Rollup Title and Link' | Out-File -FilePath $OutputFile -Append
			'---------   ---------------------' | Out-File -FilePath $OutputFile -Append
			foreach ($line in $ReferenceCSV) {
				if ($line.OSversion -eq '2008') {
					CheckForHotfix -hotfixID $($line.Article) -title $($line.Title) -Warn $($line.Warn)
				}
			}
			CheckForHotfix -hotfixID 4517134 -title 'Servicing stack update for Windows Server 2008 SP2: September 10, 2019'
			CheckForHotfix -hotfixID 4580971 -title 'Servicing stack update for Windows Server 2008 SP2: October 13, 2020'
			CheckForHotfix -hotfixID 5010452 -title 'KB5010452: Servicing stack update for Windows Server 2008 SP2: February 8, 2022'
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMHotfixRollups ---

#region --- Function Invoke-SCCMFinalize ---
function Invoke-SCCMFinalize {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand)"

	# this function collects a few PSObjects and writes them to a file
	# $global:CMRolesStatusFilePSObject - _CMRoles_Summary.txt
	# $global:CMServerFileSummaryPSObject - _CMServer_Summary.txt
	# $global:CMDatabaseFileSummaryPSObject - _CMServer_Summary.txt
	# $global:CMDatabaseQuerySummaryPSObject - _CMServer_Summary.txt
	# $global:CMClientFileSummaryPSObject - CMClient_Summary.txt

	$LogPrefix = 'Finalize'
	trap [Exception] {
		LogException 'Error: ' $_
		continue
	}

	LogInfo "[$LogPrefix] Finalizing the script execution."

	# Collect Roles Summary Output
	if ($null -ne $global:CMRolesStatusFilePSObject) {
		$RoleSummaryFile = $Prefix + '_CMRoles_Summary.txt'
		LogInfo "[$LogPrefix] Collecting Roles Summary Output to $RoleSummaryFile"
		'===============================================' | Out-File $RoleSummaryFile -Append
		'Configuration Manager Roles Installation Status' | Out-File $RoleSummaryFile -Append
		'===============================================' | Out-File $RoleSummaryFile -Append
		$global:CMRolesStatusFilePSObject.psobject.properties | Sort-Object Name | `
			Select-Object @{name = 'Role Name'; expression = { $_.Name } }, @{name = 'Installed'; expression = { $_.Value } } | `
			Format-Table -AutoSize | Out-File $RoleSummaryFile -Append
	}

	# Update ResultReport
	# TODO: ConertToXml?
	#$global:CMInstalledRolesStatusReportPSObject | convertto-xml | update-diagreport -id "0_0_CMRolesSummary" -name ("ConfigMgr Installed Roles")  -verbosity informational

	# Get Server Summary
	if ($global:Is_SiteServer) {

		$CMServerSummaryFile = $Prefix + '_CMServer_Summary.txt'

		if ($null -ne $global:CMServerFileSummaryPSObject) {
			LogInfo "[$LogPrefix] Collecting Server Summary Output to $CMServerSummaryFile"
			'==========================================' | Out-File $CMServerSummaryFile
			'Configuration Manager Site Server Summary:' | Out-File $CMServerSummaryFile -Append
			'==========================================' | Out-File $CMServerSummaryFile -Append
			$global:CMServerFileSummaryPSObject | Format-List | Out-File $CMServerSummaryFile -Append -Width 500
		}

		if ($null -ne $global:CMDatabaseFileSummaryPSObject) {
			LogInfo "[$LogPrefix] Collecting Database Summary Output to $CMServerSummaryFile"
			'===================================================' | Out-File $CMServerSummaryFile -Append
			'Configuration Manager Database Information Summary:' | Out-File $CMServerSummaryFile -Append
			'===================================================' | Out-File $CMServerSummaryFile -Append
			$global:CMDatabaseFileSummaryPSObject | Format-List | Out-File $CMServerSummaryFile -Append -Width 500
		}
		if ($null -ne $global:CMDatabaseQuerySummaryPSObject) {
			LogInfo "[$LogPrefix] Collecting Database Query Summary Output to $CMServerSummaryFile"
			'=======================================' | Out-File $CMServerSummaryFile -Append
			'Configuration Manager Database Queries:' | Out-File $CMServerSummaryFile -Append
			'=======================================' | Out-File $CMServerSummaryFile -Append
			if ($null -ne $global:DatabaseConnectionError) {
				"SQL Data was not collected because SQL Connection Failed with Error: `r`n`r`n$global:DatabaseConnectionError" | Out-File $CMServerSummaryFile -Append -Width 500
			}
			else {
				$global:CMDatabaseQuerySummaryPSObject | Format-List | Out-File $CMServerSummaryFile -Append -Width 500
			}
		}

		# Update ResultReport
		# TODO: ConertToXml?
		#$global:CMServerReportSummaryPSObject | convertto-xml | update-diagreport -id ("0_1_CMSiteServerSummary") -name ("ConfigMgr Site Server")  -verbosity informational
		#$global:CMDatabaseReportSummaryPSObject | convertto-xml | update-diagreport -id ("0_2_CMSiteDatabaseSummary") -name ("ConfigMgr Database")  -verbosity informational
	}

	# Get Client Summary
	if ($global:Is_Client) {
		$CMClientSummaryFile = $Prefix + '_CMClient_Summary.txt'

		if ($null -ne $global:CMClientFileSummaryPSObject) {
			LogInfo "[$LogPrefix] Collecting Client Summary Output to $CMClientSummaryFile"
			'=====================================' | Out-File $CMClientSummaryFile
			'Configuration Manager Client Summary:' | Out-File $CMClientSummaryFile -Append
			'=====================================' | Out-File $CMClientSummaryFile -Append
			# TODO: ConertToXml?
			#$global:CMClientReportSummaryPSObject | convertto-xml | update-diagreport -id ("0_3_CMClientSummary") -name ("ConfigMgr Client")  -verbosity informational
			$global:CMClientFileSummaryPSObject | Out-File $CMClientSummaryFile -Append -Width 500
		}
	}

	# Close Database Connection
	if ($null -ne $global:DatabaseConnection) {
		$global:DatabaseConnection.Close()
		LogInfo "[$LogPrefix] Closed Database Conection."
	}

	# Dump Variables and Functions
	$OutputDbgFileName = $Prefix + '_Execution_log_debug.txt'
	LogInfo "[$LogPrefix] Dumping Variables and Functions to $OutputDbgFileName"
	Get-ChildItem Variable: | Select-Object Name, Value | Format-List * | Out-File $OutputDbgFileName -Width 2000
	Get-ChildItem Function: | Select-Object Name, Visibility, Parameters | Format-List * | Out-File $OutputDbgFileName -Append -Width 2000

	LogInfo "[$LogPrefix] Finalize completed"
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Invoke-SCCMFinalize ---

#region --- Function Get-SCCMDevcon ---
function Get-SCCMDevcon {
	EnterFunc $MyInvocation.MyCommand.Name
	# DEVCON OUTPUT
	LogInfo "[$LogPrefix] Gathering devices and connections information (DevCon). This may take a few minutes." White
	$devconExe = "$global:ScriptFolder\psSDP\Diag\global\devcon.exe"
	# TODO: using old devcon.exe from psSDP path
	# TODO: Is devcon really needed?
	if (Test-Path -Path "$devconExe") {
		try {
			$TempFileName = 'DevCon_Output.txt'
			$OutputFile = Join-Path $WindowsLogsDestination $TempFileName
			# using '>' and '>>' instead of 'Out-File' to prevent RunCommands from adding headers
			# above each command and keep formatting consistent with old file

			$processes = @(
				LogInfo "[$LogPrefix] DEVCON drivernodes"
				"__ DRIVER NODE INFORMATION`r`n" + '-' * 23 + "`r`n" > $OutputFile
				cmd.exe /r $devconExe drivernodes * >> $OutputFile
				LogInfo "[$LogPrefix] DEVCON hwids"
				"`r`n__ HARDWARE ID INFORMATION `r`n" + '-' * 23 + "`r`n" >> $OutputFile
				cmd.exe /r $devconExe hwids * >> $OutputFile
				LogInfo "[$LogPrefix] DEVCON resources"
				"`r`n__ HARDWARE RESOURCE USAGE INFORMATION `r`n" + '-' * 35 + "`r`n" >> $OutputFile
				cmd.exe /r $devconExe resources * >> $OutputFile
				LogInfo "[$LogPrefix] DEVCON stack"
				"`r`n__ HARDWARE STACK INFORMATION `r`n" + '-' * 35 + "`r`n" >> $OutputFile
				cmd.exe /r $devconExe stack * >> $OutputFile
				LogInfo "[$LogPrefix] DEVCON status"
				"`r`n__ HARDWARE STATUS INFORMATION `r`n" + '-' * 35 + "`r`n" >> $OutputFile
				cmd.exe /r $devconExe status * >> $OutputFile
				LogInfo "[$LogPrefix] DEVCON driverfiles"
				"`r`n__ DRIVER FILES INFORMATION `r`n" + '-' * 35 + "`r`n" >> $OutputFile
				cmd.exe /r $devconExe driverfiles * >> $OutputFile
				LogInfo "[$LogPrefix] DEVCON classes"
				"`r`n__ CLASSES INFORMATION `r`n" + '-' * 35 + "`r`n" >> $OutputFile
				cmd.exe /r $devconExe classes * >> $OutputFile
				LogInfo "[$LogPrefix] DEVCON findall"
				"`r`n__ FIND ALL INFORMATION `r`n" + '-' * 35 + "`r`n" >> $OutputFile
				cmd.exe /r $devconExe findall * >> $OutputFile
			)
			foreach ($process in $processes) {
				$p = $process
				Wait-Process -Id $p.id
			}

		}
		catch { LogException "[$LogPrefix] An Exception happend in devcon.exe" $_ }
		LogInfo "[$LogPrefix] devcon.exe completed."
	}
	else { LogInfo "[$LogPrefix] devcon.exe not found - skipping..." }

	EndFunc $MyInvocation.MyCommand.Name
}

function OutputWaitforResult {
	Param (
		[Parameter(Mandatory = $true)]
		[string]$actionName,
		[Parameter(Mandatory = $false)]
		[string]$prefix = ''
	)

	if (![string]::IsNullOrEmpty($prefix)) { $outString = $prefix + ' '	}
	else { $outString = '' }
	return "$($outString)Start $($actionName) and continue - we'll wait later for it to end."
}

function fn_ActionsToSkip {
	Param (
		[Parameter(Mandatory = $false)]
		[string]$testFile = "$PSScriptRoot\__test.tss"
	)

		if (Test-Path $testFile) {
			LogInfo "'$testFile' file found. Running data collection in test mode." Magenta
			Start-Sleep -Seconds 1
			try {
				$script:ActionsToSkip = Get-Content $testFile -ErrorAction Stop
				if ($script:ActionsToSkip.Count -eq 0) {
					LogInfo "No actions to skip found in '$testFile' file." White
				}
				else {
					foreach ($action in $script:ActionsToSkip) {
						if (($action -notlike '#*') -and (![string]::IsNullOrWhiteSpace($action))) {
							$action = $action.Trim()
							if ($action -like '$*') {
								$action = $action.Split(',')
								if ($action.Count -eq 1) { $scope = 'Script' } else { $scope = $action[1] }
								if ([bool](Get-Variable $action[0].Replace('$','') -ErrorAction SilentlyContinue)) {
									LogInfo "Setting $scope variable $($action[0]) = $false" Gray
									try { Set-Variable -Name $action[0].Replace('$','') -Value $false -Scope $scope -ErrorAction Stop }
									catch { LogInfo "Error setting variable $($action[0]) for scope '$scope'. $_.Exception.Message" Red }
								}
								else {
									LogInfo "Variable $($action[0]) is not yet declared. Skipping." Yellow
								}
							}
							else {
								LogInfo "Skipping action: '$action', if applicable" Gray
							}
						}
					}
				}
			}
			catch {
				LogInfo "Exception: $($_.Exception.Message)" Red
			}
		}
}
#endregion --- Function Get-SCCMDevcon ---

#endregion --- Functions ---


#region --- Function Get-SCCMSlmgr - Feature 658 ---
function Get-SCCMSlmgr {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	$LogPrefix = 'OS_Slmgr'

	LogInfo "[$LogPrefix] Getting Slmgr license info."
	$slmgr = @(
		"cscript.exe //Nologo `"$env:windir\system32\slmgr.vbs`" /dlv		| Out-File -Append $($Prefix)OS_Slmgr.txt"
		"cscript.exe //Nologo `"$env:windir\system32\slmgr.vbs`" /dlv all	| Out-File -Append $($Prefix)OS_Slmgr.txt"
		"cscript.exe //Nologo `"$env:windir\System32\slmgr.vbs`" /ao-list	| Out-File -Append $($Prefix)OS_Slmgr.txt"
		"Get-CimInstance -Class SoftwareLicensingService					| Out-File -Append $($Prefix)OS_Slmgr.txt"
	)
	RunCommands $LogPrefix $slmgr -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function Get-SCCMslmgr - Feature 658 ---

<#
#region --- Pre-Start / Post-Stop function for trace ---
function SCCM_TEST1PreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	# Testing FwSetEventLog
	#FwSetEventLog 'Microsoft-Windows-CAPI2/Operational' -EvtxLogSize:100000 -ClearLog
	#FwSetEventLog 'Microsoft-Windows-CAPI2/Catalog Database Debug' -EvtxLogSize:102400000
	#$PowerShellEvtLogs = @("Microsoft-Windows-PowerShell/Admin", "Microsoft-Windows-PowerShell/Operational")
	#FwSetEventLog $PowerShellEvtLogs
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_TEST1PostStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_TEST1PreStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	#LogWarn '** Will do Forced Crash now' cyan
	#FwDoCrash
	EndFunc $MyInvocation.MyCommand.Name
}

function SCCM_TEST1PostStop{SourceDestinationPaths
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	# Testing FwResetEventLog
	#FwResetEventLog 'Microsoft-Windows-CAPI2/Operational'
	#FWResetEventLog 'Microsoft-Windows-CAPI2/Catalog Database Debug'
	#$PowerShellEvtLogs = @("Microsoft-Windows-PowerShell/Admin", "Microsoft-Windows-PowerShell/Operational")
	#FwResetEventLog $PowerShellEvtLogs
	EndFunc $MyInvocation.MyCommand.Name
}

function SCCM_TEST2PreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_TEST2PostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}

function SCCM_TEST3PreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_TEST3PostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."

##	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
##	$SourceDestinationPaths = @(
##		@("$env:ProgramData\Microsoft\WlanSvc\*", "$global:LogFolder\files_ProgramData_WlanSvc"),
##		@("C:\Subst_E\test2\2_SDP_RFL", "$global:LogFolder"),
##		@("C:\Subst_E\test1\SDP_RFL", "$global:LogFolder\SDP_RFL"),
##		@("C:\Subst_E\test2\2_SDP_RFL\*", "$global:LogFolder\SDP_RFL2")
##	)
##	FwCopyFolders $SourceDestinationPaths -ShowMessage:$True

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
#region --- Pre-Start / Post-Stop function for trace ---
#>

#region --- Data Collection ---
<#
function CollectSCCM_TEST1Log{
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefix = "SCCM_TEST1"
	$LogFolderforSCCM_TEST1 = "$Logfolder\SCCM_TEST1"
	FwCreateFolder $LogFolderforSCCM_TEST1

	#<#
	#<#--- Log functions ---
	#LogDebug 'This is message from LogDebug.'
	#LogInfo 'This is message from LogInfo.'
	#LogWarn 'This is message from LogWarn.'
	#LogError 'This is message from LogError.'
	#try{
	#	Throw 'Test exception'
	#} catch {
	#	LogException "This is message from LogException" $_
	#}
	#LogInfoFile 'This is message from LogInfoFile.'
	#LogWarnFile 'This is message from LogWarnFile.'
	#LogErrorFile 'This is message from LogErrorFile.'

	#<#--- Test ExportEventLog and FwExportEventLogWithTXTFormat ---
	#FwExportEventLog 'System' $LogFolderforSCCM_TEST1
	#ExportEventLog "Microsoft-Windows-DNS-Client/Operational" $LogFolderforSCCM_TEST1
	#FwExportEventLogWithTXTFormat 'System' $LogFolderforSCCM_TEST1

	#<#--- FwSetEventLog and FwResetEventLog ---
	#$EventLogs = @(
	#	'Microsoft-Windows-WMI-Activity/Trace'
	#	'Microsoft-Windows-WMI-Activity/Debug'
	#)
	#FwSetEventLog $EventLogs
	#Start-Sleep 20
	#FwResetEventLog $EventLogs

	#<#--- FwAddEvtLog and FwGetEvtLogList ---
	#($EvtLogsBluetooth) | ForEach-Object { FwAddEvtLog $_ _Stop_}	# see #region groups of Eventlogs for FwAddEvtLog
	#_# Note: FwGetEvtLogList should be called in _Start_Common_Tasks and _Start_Common_Tasks POD functions, otherwise it is called in FW FwCollect_BasicLog/FwCollect_MiniBasicLog functions

	#<#--- FwAddRegItem and FwGetRegList ---
	#FwAddRegItem @('SNMP', 'Tcp') _Stop_	# see #region Registry Key modules for FwAddRegItem
	#_# Note: FwGetRegList should be called in _Start_Common_Tasks and _Start_Common_Tasks POD functions, otherwise it is called in FW FwCollect_BasicLog/FwCollect_MiniBasicLog functions

	#<#--- Test RunCommands --
	#$outFile = "$LogFolderforSCCM_TEST1\netinfo.txt"
	#$Commands = @(
	#	"IPCONFIG /ALL | Out-File -Append $outFile"
	#	"netsh interface IP show config | Out-File -Append $outFile"
	#)
	#RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True

	#<#--- FwCopyFiles ---
	# Case 1: Copy a single set of files
	#$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	#$SourceDestinationPaths.add(@("C:\Temp\*", "$LogFolderforSCCM_TEST1"))
	#FwCopyFiles $SourceDestinationPaths

	# Case 2: Copy a single file
	#$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	#$SourceDestinationPaths.add(@("C:\temp\test-case2.txt", "$LogFolderforSCCM_TEST1"))
	#FwCopyFiles $SourceDestinationPaths

	# Case 3: Copy multi sets of files
	#$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	#$SourceDestinationPaths = @(
	#	@("C:\temp\*", "$LogFolderforSCCM_TEST1"),
	#	@("C:\temp2\test-case3.txt", "$LogFolderforSCCM_TEST1")
	#)
	#FwCopyFiles $SourceDestinationPaths

	#<#--- FwExportRegistry and FwExportRegToOneFile ---
	#LogInfo '[$LogPrefix] testing FwExportRegistry().'
	#$RecoveryKeys = @(
	#	('HKLM:System\CurrentControlSet\Control\CrashControl', "$LogFolderforSCCM_TEST1\Basic_Registry_CrashControl.txt"),
	#	('HKLM:System\CurrentControlSet\Control\Session Manager\Memory Management', "$LogFolderforSCCM_TEST1\Basic_Registry_MemoryManagement.txt"),
	#	('HKLM:Software\Microsoft\Windows NT\CurrentVersion\AeDebug', "$LogFolderforSCCM_TEST1\Basic_Registry_AeDebug.txt"),
	#	('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Option', "$LogFolderforSCCM_TEST1\Basic_Registry_ImageFileExecutionOption.txt"),
	#	('HKLM:System\CurrentControlSet\Control\Session Manager\Power', "$LogFolderforSCCM_TEST1\Basic_Registry_Power.txt")
	#)
	#FwExportRegistry $LogPrefix $RecoveryKeys
	#
	#$StartupKeys = @(
	#	'HKCU:Software\Microsoft\Windows\CurrentVersion\Run',
	#	'HKCU:Software\Microsoft\Windows\CurrentVersion\Runonce',
	#	'HKCU:Software\Microsoft\Windows\CurrentVersion\RunonceEx'
	#)
	#FwExportRegToOneFile $LogPrefix $StartupKeys "$LogFolderforSCCM_TEST1\Basic_Registry_RunOnce_reg.txt"

	#<#---FwCaptureUserDump ---
	# Service
	#FwCaptureUserDump -Name 'Winmgmt' -DumpFolder $LogFolderforSCCM_TEST1 -IsService:$True
	# Process
	#FwCaptureUserDump -Name 'notepad' -DumpFolder $LogFolderforSCCM_TEST1
	# PID
	#FwCaptureUserDump -ProcPID 4524 -DumpFolder $LogFolderforSCCM_TEST1

	#<#---general collect functions - often used in _Start/Stop_common_tasks---
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
	#FwTest-TCPport -ComputerName 'cesdiagtools.blob.core.windows.net' -Port 80 -Timeout 900

	EndFunc $MyInvocation.MyCommand.Name
}
function CollectSCCM_TEST2Log
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>

#region --- Function CollectMCM_ReportLog ---
function CollectMCM_ReportLog {
	EnterFunc $MyInvocation.MyCommand.Name
	$global:ParameterArray += 'noBasicLog'

	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}
	# loading SCCM_utils

	$OSInfoTempDir = Join-Path $LogFolder "SCCM_Report$LogSuffix"
	FwCreateFolder $OSInfoTempDir
	$Prefix = Join-Path $OSInfoTempDir ($env:COMPUTERNAME + '_')
	$Line = '--------------------------------------------------------------------------------------------------------'

	$SCCM_Start = (Get-Date)
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	LogInfo ("[OS] Version: $_major.$_minor.$_build")

	#region --- THESE FUNCTIONS ARE NEEDED TO SET SCCM VARIABLES, DO NOT REMOVE THEM ---
	# 1st attempt to dot-source SCCM utilities
	try {
		if (-not $script:SCCM_utils) {
			. "$global:ScriptFolder\scripts\tss_SCCM_utils.ps1"
		}
	}
	catch {
		# if an error occurs during dot-sourcing, log the error and handle it
		LogException 'Error occurred while loading utils.ps1:' $_
		return
	}
	# 2nd set SCCM variables
	Set-SCCMVariables
	#endregion --- THESE FUNCTIONS ARE NEEDED TO SET SCCM VARIABLES, DO NOT REMOVE THEM ---
	
	# Exclude functionality for testing purpose
	$Script:ActionsToSkip = New-Object System.Collections.ArrayList
	if ($global:beta) {
		fn_ActionsToSkip
	}
		
	#region --- functions to execute ---
	# calling Get-SCCMBasicSystemInfo to obtain basic system information
	Get-SCCMBasicSystemInfo
	# calling Get-SCCMGenericInfo to obtain generic information
	Get-SCCMGenericInfo

	#Move log collection to earlier in the function
	# call Get-SCCMLogs to collect ConfigMgr logs
	if ($script:ActionsToSkip -notcontains 'Get-SCCMLogs') { Get-SCCMLogs }

	if ($Is_SiteServer) {
		# calling Get-SCCMSiteServerInfo to collect site server information
		Get-SCCMSiteServerInfo
		if ($SiteType -eq 2) {
			LogInfo 'Secondary Site Server detected. Skipping ConfigMgr Primary Site Server data collection.'  'Cyan'
			AddTo-CMServerSummary -Name 'Boundaries' -Value 'Not available on a Secondary Site' -NoToSummaryReport
			AddTo-CMServerSummary -Name 'Cloud Services Info' -Value 'Not available on a Secondary Site' -NoToSummaryReport
			AddTo-CMServerSummary -Name 'Features Info' -Value 'Not available on a Secondary Site' -NoToSummaryReport
		} else {
			# calling Get-SCCMProviderInfo to collect provider information
			LogInfo 'Primary Site Server detected. Collecting SMS Provider Info.' 'Cyan'
			Get-SCCMProviderInfo
		}
		<#
		# calling Get-SCCMSQLInfo to collect SQL information
		Get-SCCMSQLInfo
		# calling Get-SCCMSQLCfgInfo to collect SQL configuration information
		Get-SCCMSQLCfgInfo
		# calling Get-SCCMSQLErrLogs to collect SQL error logs
		Get-SCCMSQLErrLogs
		#>
	} else {
		LogInfo 'ConfigMgr Site Server not detected. Skipping ConfigMgr Site Server data collection.' 'Cyan'
	}
	#SQL log collection should only happen on a CAS/Primary/Secondary or a Site Database Server
	#if (($Is_SiteServer) -or (($false -eq $Is_SiteServer) -and ($Is_SiteDatabaseServer -and $Is_SiteSystem))) {
	if ($Is_SiteServer -or $Is_SiteDatabaseServer) {
		# calling Get-SCCMSQLInfo to collect SQL information
		Get-SCCMSQLInfo
		# calling Get-SCCMSQLCfgInfo to collect SQL configuration information
		Get-SCCMSQLCfgInfo
		# callingS Get-SCCMSQLErrLogs to collect SQL error logs
		Get-SCCMSQLErrLogs
	} else {
		LogInfo 'ConfigMgr Site Database Server not detected. Skipping ConfigMgr Site Database Server data collection.' 'Cyan'
	}

	# calling Get-SCCMChkSym while passing $OSInfoTempDir as parameter to redirect output to the correct folder
	if ($script:ActionsToSkip -notcontains 'Get-SCCMChkSym') { Get-SCCMChkSym -ChkSymOutFolder $OSInfoTempDir }
	# calling Get-SCCMAutoRuns
	if ($script:ActionsToSkip -notcontains 'Get-SCCMAutoruns') { Get-SCCMAutoruns -AutoRunsOutFolder $OSInfoTempDir -AutoRunsFormat 'html' }
	# calling Get-SCCMProcessInfo to collect process info
	if ($script:ActionsToSkip -notcontains 'Get-SCCMProcessInfo') { Get-SCCMProcessInfo }
	#calling Get-SCCMServices to collect services info
	if ($script:ActionsToSkip -notcontains 'Get-SCCMServices') { Get-SCCMServices }
	#calling Get-SCCMslmgr to collect os licensing info
	if ($script:ActionsToSkip -notcontains 'Get-SCCMSlmgr') { Get-SCCMSlmgr }
	# calling Get-SCCMNetworkInfo to collect basic networking information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMNetworkInfo') { Get-SCCMNetworkInfo }
	# calling Get-SCCMRegistryInfo to collect registry information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMRegistryInfo') { Get-SCCMRegistryInfo }
	# calling Get-SCCMUserPermissions to collect user permissions
	if ($script:ActionsToSkip -notcontains 'Get-SCCMUserPermissions') { Get-SCCMUserPermissions }
	# if installed, calling WSUS server information functions
	if ($Is_WSUS) {
		LogInfo "WSUS detected. Calling Get-SCCMWsusBasicInfo and Get-SCCMWsusServerInfo"
		Get-SCCMWsusBasicInfo -WsusInfoOutFolder $OSInfoTempDir
		Get-SCCMWsusServerInfo
	} else {
		LogInfo "WSUS not detected. Skipping WSUS data collection." 'Cyan'
	}
	# calling Get-SCCMWUAInfo to collect WUA information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMWUAInfo') { Get-SCCMWUAInfo }
	# calling Get-SCCMDoSvcInfo to collect delivery optimization information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMDoSvcInfo') { Get-SCCMDoSvcInfo }
	# calling get-sccmclientinfo to obtain client information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMClientInfo') { Get-SCCMClientInfo }
	# calling Get-SCCMBitLockerInfo to collect BitLocker information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMBitLockerInfo') { Get-SCCMBitLockerInfo }

	if ($Is_IIS) {
		# calling Get-SCCMIISInfo to collect IIS logs
		Get-SCCMIISLogs -IISConfigurationPath $OSInfoTempDir
		Get-SCCMIISvDirInfo
	}

	# calling Get-SCCMServiceStatus to collect service status information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMServiceStatus') { Get-SCCMServiceStatus }
	if ($Is_Client) {
		# calling Get-SCCMProvisioningMode
		Get-SCCMProvisioningMode
	}
	# calling Get-SCCMDsRegCmd to collect DsRegCmd information
	if ($script:ActionsToSkip -notcontains 'Get-SCCMDsRegCmd') { Get-SCCMDsRegCmd -DsRegCmdPath "SCCM_Report$LogSuffix" }

	# calling Get-SCCMWindowsLogs to collect Windows logs
	if ($script:ActionsToSkip -notcontains 'Get-SCCMWindowsLogs') { Get-SCCMWindowsLogs }

	# calling Get-SCCMNamespaceInfo to check namespace
	if ($script:ActionsToSkip -notcontains 'Get-SCCMNamespaceInfo') { Get-SCCMNamespaceInfo }
	# calling Get-SCCMUpdateHistory to collect update history
	if ($script:ActionsToSkip -notcontains 'Get-SCCMUpdateHistory') { Get-SCCMUpdateHistory }
	# calling Get-SCCMHotfixRollups to collect hotfix rollups
	if ($script:ActionsToSkip -notcontains 'Get-SCCMHotfixRollups') { Get-SCCMHotfixRollups }

	# calling FwGet-summaryVbsLog (SummaryReliability.vbs)
	if ($script:ActionsToSkip -notcontains 'FwGet-SummaryVbsLog') { FwGet-SummaryVbsLog -Subfolder "SCCM_Report$LogSuffix" }
	#endregion --- functions to execute ---

# ---------------------------------------------------------------------------------------------
	# Section Wait for slow things to finish
	#region --- wait for processes ---
	if ($script:msinfo32NFO.HasExited -eq $false) {

		LogInfo 'Wait for a maximum of 3 minutes for background processing(msinfo32) to complete' White
		FwWaitForProcess $script:msinfo32NFO 180
	}

	if ($script:GPresultFileH.HasExited -eq $false) {
		LogInfo 'Wait for a maximum of 30 seconds for background processing(gpresult) to complete' White
		# Only wait 30 seconds. if still not complete ignore.
		FwWaitForProcess $script:GPresultFileH 30
	}

	if ($script:WULogsJob.State -eq 'Running') {
		LogInfo 'Wait for a maximum of 2 minutes for background processing(WULogs) to complete' White
		$script:WULogsJob | Wait-Job -Timeout 120 | Remove-Job -Force -ErrorAction SilentlyContinue
		if ($script:WULogsJob.State -eq 'Running') {
			LogInfo 'WULogs job still running after 2 minutes - removing the job. This can take a few seconds...' 'Magenta'
			"Timed out. Convert the ETL files manually, if needed." |
				Out-File $script:WULogsJobLog -Force -ErrorAction SilentlyContinue
		}
	}
	if ($script:WULogsJob) { $script:WULogsJob | Remove-Job -Force -ErrorAction SilentlyContinue }
	#endregion --- wait for processes ---

	#region --- THESE FUNCTIONS ARE NEEDED TO SET SCCM VARIABLES, DO NOT REMOVE THEM ---
	# calling Invoke-SCCMFinalize
	Invoke-SCCMFinalize
	#endregion --- THESE FUNCTIONS ARE NEEDED TO SET SCCM VARIABLES, DO NOT REMOVE THEM ---

	$SCCM_End = (Get-Date)
	$SCCM_Runtime = (New-TimeSpan -Start $SCCM_Start -End $SCCM_End)
	$SCCM_hours = $SCCM_Runtime.Hours
	$SCCM_minutes = $SCCM_Runtime.Minutes
	$SCCM_seconds = $SCCM_Runtime.Seconds
	$SCCM_summary = "Overall duration: $SCCM_hours hours, $SCCM_minutes minutes and $SCCM_seconds seconds"
	LogInfo "[SCCM] $SCCM_summary" 'Gray'

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function CollectMCM_ReportLog ---


#region --- Function CollectMCM_OfficeLog ---
# TODO
function CollectMCM_OfficeLog {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."

	$global:ParameterArray += 'noBasicLog'

	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}
	# loading SCCM_utils

	$OSInfoTempDir = Join-Path $LogFolder "SCCM_Office$LogSuffix"
	FwCreateFolder $OSInfoTempDir
	$Prefix = Join-Path $OSInfoTempDir ($env:COMPUTERNAME + '_')
	$Line = '--------------------------------------------------------------------------------------------------------'

	$SCCM_Start = (Get-Date)
	LogInfo "Running $($MyInvocation.MyCommand.Name)."
	LogInfo ("[OS] Version: $_major.$_minor.$_build")

	# calling Get-SCCMROIScan to collect ROI scan information
	Get-SCCMROIScan -ROIScanOutFolder $OSInfoTempDir

	$SCCM_End = (Get-Date)
	$SCCM_Runtime = (New-TimeSpan -Start $SCCM_Start -End $SCCM_End)
	$SCCM_hours = $SCCM_Runtime.Hours
	$SCCM_minutes = $SCCM_Runtime.Minutes
	$SCCM_seconds = $SCCM_Runtime.Seconds
	$SCCM_summary = "Overall duration: $SCCM_hours hours, $SCCM_minutes minutes and $SCCM_seconds seconds"
	LogInfo "[SCCM] $SCCM_summary" 'Gray'

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion --- Function CollectMCM_OfficeLog ---

#endegion --- Data Collection ---


#region --- Diag function ---
<#
function RunSCCM_TEST1Diag {
	EnterFunc $MyInvocation.MyCommand.Name
	if ($global:Boundparameters.containskey('InputlogPath')) {
		$diagpath = $global:Boundparameters['InputlogPath']
		LogInfo "diagpath = $diagpath"
	}
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function RunSCCM_TEST2Diag
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>
#endregion --- Diag function ---

#region Scenario Functions

### Pre-Start / Post-Stop / Collect / Diag function for scenario tracing
##### Common tasks
<#
function SCCM_Start_Common_Tasks{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	#FwGetRegList _Start_
	#FwGetEvtLogList _Start_
	EndFunc $MyInvocation.MyCommand.Name
}

function SCCM_Stop_Common_Tasks{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	#FwGetRegList _Stop_
	#FwGetEvtLogList _Stop_
	EndFunc $MyInvocation.MyCommand.Name
}

##### SCCM_Scn1
function SCCM_Scn1ScenarioPreStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_Scn1ScenarioPostStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_Scn1ScenarioPreStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_Scn1ScenarioPostStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectSCCM_Scn1ScenarioLog
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function RunSCCM_Scn1ScenarioDiag
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}

##### SCCM_Scn2
function SCCM_Scn2ScenarioPreStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function SCCM_Scn2ScenarioPostStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectSCCM_Scn2ScenarioLog
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
<#
function RunSCCM_Scn2ScenarioDiag
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogMessage $Loglevel.Info "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>


#endregion Scenario Functions

#endregion Functions

#region Registry Key modules for FwAddRegItem
<#
	$global:KeysSNMP = @("HKLM:System\CurrentControlSet\Services\SNMP", "HKLM:System\CurrentControlSet\Services\SNMPTRAP")
	$global:KeysWinLAPS = @(
		'HKLM:Software\Microsoft\Policies\LAPS'
		'HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\LAPS'
		'HKLM:Software\Policies\Microsoft Services\AdmPwd'
		'HKLM:Software\Microsoft\Windows\CurrentVersion\LAPS\Config'
		'HKLM:Software\Microsoft\Windows\CurrentVersion\LAPS\State'
		'HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions\{D76B9641-3288-4f75-942D-087DE603E3EA}'
	)
#>
<# Example:
	$global:KeysHyperV = @("HKLM:Software\Microsoft\Windows NT\CurrentVersion\Virtualization", "HKLM:System\CurrentControlSet\Services\vmsmp\parameters")
	#>

# B) section of NON-recursive lists
<#
	$global:KeysDotNETFramework = @(
		'HKLM:Software\Microsoft\.NETFramework\v2.0.50727'
		'HKLM:Software\Wow6432Node\Microsoft\.NETFramework\v2.0.50727'
		'HKLM:Software\Microsoft\.NETFramework\v4.0.30319'
		'HKLM:Software\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
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
#   Deprecatedparam: parameters to be renamed or obsoleted in the future
#   Type           : Can take either 'Rename' or 'Obsolete'
#   Newparam       : Provide new parameter name for replacement only when Type=Rename. In case of Type='Obsolete', put null for the value.
$SCCM_DeprecatedparamList = @(
	<#
	@{Deprecatedparam='SCCM_kernel';Type='Rename';Newparam='WIN_kernel'}
#	@{Deprecatedparam='SCCM_SAM';Type='Rename';Newparam='SCCM_SAMsrv'} # <-- this currently fails
	@{Deprecatedparam='SCCM_Demo';Type='Rename';Newparam='SCCM_Demo'}
#>
)
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *

# SIG # Begin signature block
# MIIoKgYJKoZIhvcNAQcCoIIoGzCCKBcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCACFs4wcGB6kfss
# 5A5q5kaz2dswhVt89OS1htKZL1O5AaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHZ4nB4uHQaoGFM1XZtjYU7l
# D59243ftex7i1HrrKPa5MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAebS1CmYybGNwS/rcM+j4j2EMEfphmWmhuerYFvV8bCvlt01yfiYto04I
# rSVedudzgTtqk8TK/9f28LaTl+HU9o1Alw7TwefC2FCtXu0yTcVylwwCV9ZQO0vN
# vDDMUvqEkhdLXx7XzhsXQP1pDltBE7vj+ehXUgDoKQqBTzp1RiydycbgYrXhGqI/
# 5PTx8WMQq0W2KFSHir8nOmG7ZjGWo2OqqQFXkd78Uwd2LO2qoTEuNy9qAFSQQ95h
# 5/XvXIBFt3Y+bOTB5MF62/y77M6mp/yhiOp1b3WJO0wC+i+2ascS3/97Ez7Wvs3+
# uCR0MFvnR5TD+kYpU8nydFq2QDa8baGCF5QwgheQBgorBgEEAYI3AwMBMYIXgDCC
# F3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAf04Khx8Vujz8LRuW8OSGdIQo/3aaxPMCJq7Fd3pmt8gIGZkZGMts5
# GBMyMDI0MDYxMjE0NTg1NC4xNDdaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046RjAwMi0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHqMIIHIDCCBQigAwIBAgITMwAAAfI+MtdkrHCRlAABAAAB8jANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# NThaFw0yNTAzMDUxODQ1NThaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046RjAwMi0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC85fPLFwppYgxwYxkSEeYvQBtnYJTtKKj2FKxzHx0f
# gV6XgIIrmCWmpKl9IOzvOfJ/k6iP0RnoRo5F89Ad29edzGdlWbCj1Qyx5HUHNY8y
# u9ElJOmdgeuNvTK4RW4wu9iB5/z2SeCuYqyX/v8z6Ppv29h1ttNWsSc/KPOeuhzS
# AXqkA265BSFT5kykxvzB0LxoxS6oWoXWK6wx172NRJRYcINfXDhURvUfD70jioE9
# 2rW/OgjcOKxZkfQxLlwaFSrSnGs7XhMrp9TsUgmwsycTEOBdGVmf1HCD7WOaz5EE
# cQyIS2BpRYYwsPMbB63uHiJ158qNh1SJXuoL5wGDu/bZUzN+BzcLj96ixC7wJGQM
# BixWH9d++V8bl10RYdXDZlljRAvS6iFwNzrahu4DrYb7b8M7vvwhEL0xCOvb7WFM
# sstscXfkdE5g+NSacphgFfcoftQ5qPD2PNVmrG38DmHDoYhgj9uqPLP7vnoXf7j6
# +LW8Von158D0Wrmk7CumucQTiHRyepEaVDnnA2GkiJoeh/r3fShL6CHgPoTB7oYU
# /d6JOncRioDYqqRfV2wlpKVO8b+VYHL8hn11JRFx6p69mL8BRtSZ6dG/GFEVE+fV
# mgxYfICUrpghyQlETJPITEBS15IsaUuW0GvXlLSofGf2t5DAoDkuKCbC+3VdPmlY
# VQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFJVbhwAm6tAxBM5cH8Bg0+Y64oZ5MB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQA9S6eO4HsfB00XpOgPabcN3QZeyipgilcQ
# SDZ8g6VCv9FVHzdSq9XpAsljZSKNWSClhJEz5Oo3Um/taPnobF+8CkAdkcLQhLdk
# Shfr91kzy9vDPrOmlCA2FQ9jVhFaat2QM33z1p+GCP5tuvirFaUWzUWVDFOpo/O5
# zDpzoPYtTr0cFg3uXaRLT54UQ3Y4uPYXqn6wunZtUQRMiJMzxpUlvdfWGUtCvnW3
# eDBikDkix1XE98VcYIz2+5fdcvrHVeUarGXy4LRtwzmwpsCtUh7tR6whCrVYkb6F
# udBdWM7TVvji7pGgfjesgnASaD/ChLux66PGwaIaF+xLzk0bNxsAj0uhd6QdWr6T
# T39m/SNZ1/UXU7kzEod0vAY3mIn8X5A4I+9/e1nBNpURJ6YiDKQd5YVgxsuZCWv4
# Qwb0mXhHIe9CubfSqZjvDawf2I229N3LstDJUSr1vGFB8iQ5W8ZLM5PwT8vtsKEB
# wHEYmwsuWmsxkimIF5BQbSzg9wz1O6jdWTxGG0OUt1cXWOMJUJzyEH4WSKZHOx53
# qcAvD9h0U6jEF2fuBjtJ/QDrWbb4urvAfrvqNn9lH7gVPplqNPDIvQ8DkZ3lvbQs
# Yqlz617e76ga7SY0w71+QP165CPdzUY36et2Sm4pvspEK8hllq3IYcyX0v897+X9
# YeecM1Pb1jCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkYwMDItMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQBr
# i943cFLH2TfQEfB05SLICg74CKCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hOyfzAiGA8yMDI0MDYxMjA1Mzcw
# M1oYDzIwMjQwNjEzMDUzNzAzWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDqE7J/
# AgEAMAcCAQACAg8ZMAcCAQACAhNBMAoCBQDqFQP/AgEAMDYGCisGAQQBhFkKBAIx
# KDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
# hvcNAQELBQADggEBAI4KGyykIONgudcf/LRGsgW0wKpS2dJG/t6x8hJd01nt+SL/
# r4iDjLNvJyo/3dQF9VMlcwjnWrjShkzfkv/kh3neq+QjccvIuXFjuessVvt1Vn6A
# MBHqqnAH6a8nFkilKq885HA9QpWCx2+7ACxjYsy3+BpLc5WSgcCd9hzUQSIbF/Pp
# F2vOzP5CjCQwGMtzYwMg1grOCFh0OiPm4wg8+KQpqs+0AQZZDSHUyl0yt4/TEXeS
# znCnBEjvbwqjloieZ4k2mRwsho+dbqWwvqRvPOeiqbtbqb/T416DBZC7nB6s/M48
# pHs8ROTiJilZiYPiC+a+sBpF5Exnx+jcxvSGGqsxggQNMIIECQIBATCBkzB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAfI+MtdkrHCRlAABAAAB8jAN
# BglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8G
# CSqGSIb3DQEJBDEiBCBnLHl6gVzbrLRrnC3y9Hu9ZpEPcaMQM2mqmgTs+U2G/zCB
# +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIPjaPh0uMVJc04+Y4Ru5BUUbHE4s
# uZ6nRHSUu0XXSkNEMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAHyPjLXZKxwkZQAAQAAAfIwIgQggy2SSLEsRKVVj1ntOmiu6nMsBLMr
# YZTv8URqkr31jMswDQYJKoZIhvcNAQELBQAEggIAlSdQ3IF7lT5oze7rKYNEEQIG
# gNMiRdTK7h1/FaF/WHszNTwI3fWghMjYn8q4fM/4ijblIJ/8EXWrx6DWz8IqYrOO
# EmWqJQEp7XdOD7Oup5Mfu8Bz9B44SQfKXfVKFW97REkAgs3kexlmRzKrn+tdGO/f
# A0daJLSG+ujq2U564Bdwgw00d6uJC2EC+LyMzuIoa9x/hd/CP3jNdfU7wsIM8Hbr
# NaN49a46rZriPRKCDHBHFHEW35sP/Owk0Hz3v53mTqXreHhBNlDdYmOli/7a9Fg5
# 5E/HYlPw/X2R/mz1W2e2EEQDc/Tt+5NTo6fnlr9ZQ9XTrhjF1lbwr4ejUIJMFy6r
# wTBSERZD1JM5PHfnj/Ifks8k6C4zFV5pIjwrxIWJ1OZkj1VYaZMWTfbpIou/uZNz
# EtfIXVvIgXbY3zEYS/MjigqcmZD02U7+QvGV42wVHdDEi4t+86gVpnLdJdMIc6Sm
# vJixm9ZF66KPJFjJoTpk3UlI89AUUN4ejYaG8h+/4tDZ9XKdmGpINgCtLGlg77+N
# +Z2gqOB0gdWLbsyNctTYk+/+dEp/CjAFU18y0PqDJ9FRgS0UemO+plKVLCfKT0H6
# yalQW81YMp5HoJrrQK+xjLGJZgA/N37oxF8hbRzmjBAYui3NBvnLOfr6hRxD3m8z
# 3zkyTzsrMA2Q7vvRuQk=
# SIG # End signature block
