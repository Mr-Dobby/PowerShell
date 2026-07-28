<#
.SYNOPSIS
	DND module for collecting ETW traces and various custom tracing functionality

.DESCRIPTION
	Define ETW traces for Windows DND components
	Add any custom tracing functinaliy for tracing DND components
	For Developers:
	1. Switch test: .\TSS.ps1 -Start -DND_TEST1
	2. Scenario test: .\TSS.ps1 -start -Scenario DND_MyScenarioTest

.NOTES
	Dev. Lead: sabieler
	Authors    : sabieler; cleng; mamakigu
	Requires   : PowerShell V4 (Supported from Windows 8.1/Windows Server 2012 R2)
	Version    : see $global:TssVerDateDND

.LINK
	TSS https://internal.evergreen.microsoft.com/en-us/help/4619187
	DND https://internal.evergreen.microsoft.com/en-us/help/4643331
#>

<# latest changes
  2024.03.18.0 [il] _DND: Added more information to Get-DNDWUfBReport
  2024.03.11.0 [mm] _DND: DND_Setup, added log collection for UBR, PolicyManager, Sysprep, SessionPending and UUS.
  2024.02.27.0 [il] _DND: Add logs collection into DND_WULogs to mimic copylogs.exe
  2024.02.23.0 [sb] _DND: using function FwGetFltMcInfo
  2024.02.19.0 [sb] _DND: alligned document format
  2024.02.16.0 [il] _DND: Add Basic as supported Telemetry level for WuFB report
  2024.02.13.0 [sb] _DND: collecting OneSettings for appraiser in Get-DNDMiscInfo
  2024.02.09.2 [il] _DND: Added more WDI logs to Get-DNDCbsPnpInfo
  2024.02.09.1 [sb] _DND: fixed Bug 654: Access violation during file compression caused by MSINFO32
  2024.02.09.0 [sb] _DND: Fixed error handling in function CollectDND_TPMLog
  2024.01.16.1 [il] _DND: Fixed Dism get-packageinfo for non-english OS in _dism_GetPackages.txt
  2024.01.16.0 [il] _DND: added 23H2 build number in Check for Windows 11 versions and later
  2024.01.11.0 [sb] _DND: added "Feature 640: _DND: Add Azure Arc ESU information"
  2024.01.10.1 [il] _DND: update reg_Reliability filename
  2024.01.10.0 [sb] _DND: collect only log files from _SMSTaskSequence folder
  2023.12.28.3 [sb] _DND: fixed Bug 635: _DND: Bloated TSS setup report due to _SMSTaskSequence collection
  2023.12.28.2 [sb] _DND: moved commands from misc to CBS/PNP function
  2023.12.28.1 [sb] _DND: added Feature 632: _DND: Collect CURL details
  2023.12.28.0 [sb] _DND: shortened filenames in Get-DNDWindowsUpdateInfo
  2023.11.28.0 [sb] _DND: added evtx collection to DND_WUfBReport
  2023.11.27.0 [sb] _DND: added error handling in Get-DNDWindowsDiagnosticDataUpload
  2023.11.23.0 [sb] _DND: fixed error in Get-DNDBitLockerInfo
  2023.11.16.0 [sb] _DND: changed logic to determine if LID key exists in registry
  2023.11.07.3 [sb] _DND: removed typos
  2023.11.07.2 [sb] _DND: Added Feature 605: DnD - WinRE information
  2023.11.07.1 [sb] _DND: Get-DNDSetupLogs: Copy SCM trace, if found
  2023.11.07.0 [sb] _DND: Changed output in Get-DNDProcessInfo from format-table to format-list
  2023.10.22.3 [aj] _DND: Added CollectDND_SAReports to collect Subscription Activation logs along with html report.
  2023.10.13.3 [sb] _DND: Determine the .NET Framework security updates and hotfixes that are installed
  2023.10.13.2 [sb] _DND: Moved order of output in Get-DNDBitLockerInfo
  2023.10.13.1 [sb] _DND: Modified Get-DNDBitLockerInfo to retrive SPN and FVE policy key in separate file
  2023.10.13.0 [sb] _DND: Modified Get-DNDSurfaceInfo to collect Win32_BIOS, Win32_SystemEnclosure and ComputerInfo, Feature 590: Collect output of WMI Win32_BIOS class
  2023.10.12.0 [sb] _DND: updated Get-DNDWindowsUpdateInfo to collect 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Update'
  2023.10.06.2 [sb] _DND: running "tpmtool parsetcglogs" on Windows 10 only, since it has been removed in Windows 11
  2023.10.05.2 [sb] _DND: added function Get-DNDDriverSearch to WUfB report
  2023.10.05.1 [sb] _DND: moved all power related commands to function Get-DNDPowerInfo
  2023.10.05.0 [sb] _DND: added -Scenario DND_PowerWPR
  2023.10.02.1 [sb] _DND: Improved Test-DNDURL code
  2023.10.02.0 [sb] _DND: Fix: Test-DNDURL returned always $true
  2023.09.28.1 [sb] _DND: query session on devices with MBAM agent installed
  2023.09.28.0 [sb] _DND: adjusting WUfB report, added more URLs and changed default layout
  2023.09.27.0 [sb] _DND: reorganized WUfB report related commands into its own function Get-DNDWUfBReport
  2023.09.26.1 [sb] _DND: added DisableOneSettingsDownloads to policy checks in WUFReport
  2023.09.26.0 [sb] _DND: move MDM info to seperate function and extended WUfBReport with MDM info
  2023.09.25.0 [sb] _DND: added # Feature 553: check WUfB requirements
  2023.09.12.0 [sb] _DND: added # Feature 572: Bootmgfw.efi Version Info Collection  (_FileVersions_EFI.txt)
  2023.08.17.0 [we] _FW: renamed -DNDmenu to -Menu; _DND: removed $global:beta condition for -Menu; added Enable/Disable All button (#539)
  2023.08.17.0 [sb] _DND: DND_SETUPReport, added console logging in Get-DNDCbsPnpInfo
  2023.08.14.0 [sb] _DND: DND_SETUPReport, collect GlobalDeviceID from registry (g:xxxxxxxxxxxxxxxx)
  2023.08.12.0 [we] _DND: add '\Process V2(*)\*' PerfCounter; add function ShowDNDmenu; _FW: add switch -DNDmenu to collect selected DND items only - curentl hidden/activated by switch -beta
  2023.08.06.0 [we] _DND: replaced FwCreateLogFolder with FwCreateFolder
  2023.08.04.0 [we] _DND: renamed $global:PstatPath to $global:PstatExe
  2023.07.31.0 [sb] _DND: DND_SETUPReport, adding CloudManagedUpdate logs to Get-DNDWindowsUpdateInfo
  2023.07.24.0 [sb] _DND: DND_SETUPReport, wrapped poqexec.log conversion into try / catch block
  2023.07.14.0 [sb] _DND: DND_SETUPReport, added CI registry key in function Get-DNDDeviceGuard
  2023.07.13.2 [sb] _DND: DND_SETUPReport, collecting SCCM setupcomplete.log
  2023.07.13.1 [sb] _DND: DND_SETUPReport, removed unnecessary folder from Get-DNDDeploymentLogs
  2023.07.13.0 [sb] _DND: DND_SETUPReport, improved Get-DNDSetupLogs to collect logs from existing folders only
  2023.07.04.0 [sb] _DND: DND_SETUPReport, collecting disabled services in file services_disabled.txt
  2023.06.29.0 [sb] _DND: DND_SETUPReport, added export of DeviceGuard registry keys to function Get-DNDDeviceGuard
  2023.06.23.0 [sb] _DND: DND_SETUPReport, fixed type cast bug in logic to evaluate variables retrieved from tss_config.cfg
  2023.06.13.0 [sb] _DND: DND_SETUPReport, extended output of function Get-DNDBitLockerInfo (Get-BitLockerVolume and out of WMI class Win32_EncryptableVolume)
  2023.05.23.0 [sb] _DND: DND_SETUPReport, added logic to check drivers in SYSTEM\DriverDatabase against DriverStore\FileRepository.
  2023.05.18.0 [mm] _DND: DND_Setup, fix an issue that exception (0x80070020) may occur while calling FwGetMsInfo32 function.
  2023.05.11.0 [sb] _DND: improved Get-DNDDeploymentLogs to collect MDT logs if they haven't been moved to 'C:\Windows\Temp\DeploymentLogs'
  2023.05.09.0 [mm] _DND: replaced "DND_Setup" code with "DND_SetupEx" code and remove "DND_SetupEx" function to avoid confusion, commented "DND_SETUPDiag" out since it is no longer in use
  2023.05.06.0 [mm] _DND: added a collection function "DND_SetupEx" which will replace the previously released collection function "DND_Setup".
  2023.05.05.0 [sb] _DND: Feature 404: collect USB\AutomaticSurpriseRemoval\AttemptRecoveryFromUsbPowerDrain
  2023.05.02.1 [sb] _DND: Feature 404: _DND: Decode MBAM event log on customer machines (which has MBAM server installed)
  2023.05.02.0 [sb] _DND: Feature 404: _DND: Decode MBAM event log on customer machines (which has MBAM agent installed)
  2023.04.21.1 [sb] _DND: improving Get-DNDWindowsUpdateInfo
  2023.04.21.0 [sb] _DND: using framework function 'FwExportFileVerToCsv' to collect UUS file versions
  2023.04.21.0 [sb] _DND: adding powercfg commands (DEVICEQUERY, LASTWAKE, REQUESTS)
  2023.04.19.3 [sb] _DND: fixed an issue with data type conversion (int/string) and OS detection, improved WU log collection from Windows.old
  2023.04.19.2 [sb] _DND: enhanced readability, set back FlushLogs default to 0
  2023.04.19.0 [sb] _DND: collecting UUS file versions
  2023.04.18.0 [sb] _DND: replaced logic to evaluate variables retrieved from tss_config.cfg, re-formatted misc file, corrected indenting, replaced double-quotes by single-quotes where possible
  2023.04.17.0 [sb] _DND: code optimizations
  2023.04.12.0 [sb] _DND: moved OS detection logic out of functions
  2023.04.11.0 [sb] _DND: added Windows.old evtx logs
  2023.04.07.0 [we] _DND: add CollectDND_PnPLog (consolidate NET_PnP)
  2023.03.31.0 [sb] _DND: improved ReservedStorageState output
  2023.03.29.0 [sb] _DND: fixed typo in DND_WULogs
  2023.03.27.1 [sb] _DND: replacing redirect with Out-File
  2023.03.27.0 [sb] _DND: building dynamic disk part script and execute it
  2023.03.22.4 [sb] _DND: adding mandatory parameter to LogException calls
  2023.03.22.3 [sb] _DND: displaying hint when downloading symbols
  2023.03.22.2 [sb] _DND: satisfy CTAC query requirements (AnalyticsInfo.GetSystemPropertiesAsync was introduced in 10.0.17134.0)
  2023.03.22.1 [sb] _DND: improved symbol server detection
  2023.03.22.0 [sb] _DND: if folder Windows.~WS is present, collect panther logs
  2023.03.21.0 [sb] _DND: extended proxy output and cleaned up for readability
  2023.03.20.0 [sb] _DND: added method to retrieve CTAC attributes
  2023.03.14.0 [sb] _DND: increased sleepstudy days to maximum of 28 days
  2023.03.13.0 [sb] _DND: replaced "timeout" with "Start-Sleep"
  2023.03.09.0 [sb] _DND: added collection of Get-DeliveryOptimizationPerfSnapThisMonth
  2023.03.06.0 [sb] _DND: renamed files Hotfixes.csv Hotfix-WindowsUpdateDatabase.txt to WindowsUpdate_Hotfixes.csv WindowsUpdate-Database.txt
  2023.01.30.0 [sb] _DND: added waketimers output to Get-DNDEnergyInfo
  2023.01.25.0 [sb] _DND: added Windows Update per user reg key collection
  2023.01.20.0 [sb] _DND: added delivery optimization cmdLets
  2023.01.16.0 [sb] _DND: add -Scenario DND_AudioETW which collects audio ETW traces
  2023.01.12.0 [sb] _DND: Get-DNDPBRLogs: added AppxLogs
  2023.01.11.0 [sb] _DND: add -Scenario DND_AudioWPR which collects audio traces the old fashioned way, https://matthewvaneerde.wordpress.com/2017/01/09/collecting-audio-logs-the-old-fashioned-way/
  2023.01.10.0 [sb] Get-DNDPBRLogs: fixed escape issue and replaced xcopy with robocopy
  2022.12.07.0 [we] _DND: add -Scenario DND_General
  2022.12.06.1 [sb] #_# DND_SETUPReport, added InstallService\State
  2022.12.06.0 [sb] #_# DND_WULogs, added symbol server check for winver 1607
  2022.12.06.0 [sb] #_# DND_SETUPReport, added ReservedStorageState output, modified Windows detection logic
  2022.11.29.0 [sb] #_# DND_SETUPReport, improved mounting of system partition
  2022.11.28.0 [sb] #_# DND_SETUPReport, added function to collect Device Guard specific information
  2022.11.22.1 [sb] #_# DND_SETUPReport, added Windows 11 detection logic
  2022.11.22.0 [sb] #_# DND_SETUPReport, added CHID export from registry
  2022.10.14.1 [sb] #_# DND_SETUP, fixed path error for systeminfo output
  2022.10.14.0 [sb] #_# Get-DNDEventLogs, re-adding "Microsoft-Windows-Store/Operational","Microsoft-Client-Licensing-Platform/Admin" to TXT export
  2022.10.11.0 [il] #_# Get-DNDWindowsUpdateInfo, Remove RedirectUrls:System.__ComObject from output of WindowsUpdateConfiguration.txt
  2022.10.10.0 [sb] #_# wrapped "standalone" Get-CimInstance in try / catch block, fixed minor bugs
  2022.10.07.0 [il] #_# Get-DNDWindowsUpdateInfo, translate UpdateID,Category fields and remove Uninstallation fields
  2022.10.04.0 [sb] #_# DND_WULogs, added computer name to file names
  2022.09.23.0 [we] #_# add DND_WU as provider tracing in FW
  2022.09.15.0 [we] #_# DND_SETUPReport, added results.xml to make RFLckeck happy
  2022.08.01.0 [we] _NET: add var $PublicSymSrv to make PSScriptAnalyzer happy
  2022.07.25.1 [sb] #_# added new function to retrieve AppLocker policy
  2022.07.25.0 [sb] #_# added info from storage cmdLets
  2022.07.11.0 [sb] #_# enabled _NETBASIC
  2022.07.04.0 [sb] #_# Get-DNDSetupLogs, moving back to robocopy to leverage filters
  2022.07.01.0 [sb] #_# FwCopyFiles, changed wildcard usage from "*.*"" to "*"
  2022.06.29.0 [sb] #_# Get-DNDWindowsUpdateInfo, fixed typo
  2022.06.28.1 [sb] #_# CollectDND_WULogsLog, fixed typo
  2022.06.28.0 [sb] #_# Get-DNDMiscInfo, reg_Drivers.hiv no longer overwrites reg_Components.hiv
  2022.06.21.1 [sb] #_# Get-DNDEventLogs, exclude archived event logs, Get-DNDWindowsUpdateInfo added 1607 detection logic
  2022.06.21.0 [sb] #_# Get-DNDCbsPnpInfo, re-added files
  2022.06.20.0 [sb] #_# [Get-DNDDeploymentLogs] fixed output filename
  2022.06.17.0 [sb] #_# [Get-DNDEnergyInfo] change output for system power report to Powercfg-systempowerreport.html
  2022.06.06.0 [we] #_# [DND_WUlogs] fix msinfo/systeminfo
  2022.06.03.0 [we] #_# fix While loop in [Get-DNDMiscInfo], use FW function FwGet-SummaryVbsLog
  2022.05.31.0 [we] #_# replaced LogMessage .. with LogInfo/LogDebug; replaced some code with FW functions i.e. using FwExportFileVerToCsv
	FYI: RunCommands will mirror each commandline in output file, if last item separated by space ' ' is a output file-name; FW functions have better error handling
  2022.05.25.0 [sb] #_# DND_SETUPReport, enhanced configuration granularity through tss_config.cfg
  2022.05.24.3 [sb] #_# DND_SETUPReport, replaced  [System.ServiceProcess.ServiceControllerStatus] with [System.ServiceProcess.ServiceStartMode]
  2022.05.24.2 [sb] #_# DND_SETUPReport, added try block to Get-DNDWindowsUpdateInfo
  2022.05.24.1 [sb] #_# DND_SETUPReport, added abnormal sleepstudy ETLs
  2022.05.24.0 [sb] #_# DND_SETUPReport, minor changes in Get-DNDNetworkBasic
  2022.04.13.0 [cl] #_# DND_SETUPLog and DND_WULogs  replaced WMIC with Get-CimInstance
  2022.03.14.0 [sb] #_# DND_SETUPReport, adding extra logging to Get-DNDEventLogs
  2022.02.21.0 [sb] #_# DND_SETUPReport, adding pattern to servicing state query
  2022.02.16.0 [sb] #_# DND_SETUPReport, removed function placeholder
  2022.02.15.0 [sb] #_# DND_SETUPReport, added servicing scenario "-Scenario DND_ServicingProcmon"
  2022.02.09.1 [sb] #_# DND_SETUPReport, added function Get-DNDRFLCheckPrereqs
  2022.02.09.0 [sb] #_# DND_SETUPReport, fixed bug in Get-DNDWindowsUpdateInfo
  2022.02.06.0 [we] #_# added description for DND_SETUPReport in framework
  2022.02.03.1 [sb] #_# DND_SETUPReport, split network functions into Get-DNDNetworkBasic and Get-DNDNetworkSetup
  2022.02.03.0 [sb] #_# DND_SETUPReport, check if wuauserv is disabled before querying it to prevent runtime exception
  2022.02.02.0 [sb] #_# DND_SETUPReport, removed duplicate collection of reg_SoftwareProctectionPlatform.txt, fixed typo and moved collection from Get-DNDMiscInfo into Get-DNDActivationState
  2022.02.01.0 [sb] #_# DND_SETUPReport, added parameters to tss_config.cfg and use them to be more flexible
  2022.01.26.1 [sb] #_# DND_SETUPReport, disabled progress display from Test-NetConnection
  2022.01.26.0 [sb] #_# DND_SETUPReport, added hours to runtime calculation
  2022.01.20.0 [sb] #_# DND_SETUPReport, added connection test to public symbol server msdl.microsoft.com to prevent long running Get-WindowsUpdateLog cmdLet
  2022.01.07.2 [sb] #_# DND_SETUPReport, removed xray overwrite to have telemetry working
  2022.01.07.1 [sb] #_# DND_WULogs, added noBasicLog to global parameter array to skip basic log collection, ($global:ParameterArray += 'noBasicLog')
  2022.01.07.0 [sb] #_# DND_SETUPReport, added noBasicLog to global parameter array to skip basic log collection, ($global:ParameterArray += 'noBasicLog')
  2022.01.05.0 [sb] #_# typo in "Token Activation" section and output certutil info into new text file.
  2022.01.04.0 [sb] #_# added storage cmdLets for Windows 8 and higher
  2022.01.02.0 [we] #_# _NET: moved NET_ '_WinUpd' to _DND, https://microsoft.ghe.com/css-windows/WindowsCSSToolsDevRep/pull/394
  2021.12.23.0 [sb] #_# split up DND_SETUPReport  collection into functions in preparation of different log collection purposes or scenarios
  2021.12.20.0 [sb] #_# surface log collection: removed unneeded closing brace, escaped pipeline variable
  2021.12.02.1 [sb] #_# migrating common CMD commands to use TSS framework functions (section: activation, directory listing, surface, slow processing)
  2021.12.02.0 [sb] #_# added cidiag to scenario "-DND_CodeIntegrity", example: .\TSS.ps1 -Start -DND_CodeIntegrity -noBasicLog -noUpdate
  2021.11.30.0 [sb] #_# migrating common CMD commands to use TSS framework functions (section: network)
  2021.11.27.0 [cl] #_# added variuos taracing GUIDs
  2021.11.10.0 [we] #_# replaced all 'Get-WmiObject' with 'Get-CimInstance' to be compatible with PowerShell v7
  2021.03.23.0 [cl] #_# initial version of TSS DND module
#>
$global:TssVerDateDND = '2024.03.11.0'

# ----- Setup initial stuff
$PublicSymSrv = 'msdl.microsoft.com'

# OS Version checks
$_osVersion = [environment]::OSVersion.Version
$_major = $_osVersion.Major
$_minor = $_osVersion.Minor
$_build = $_osVersion.Build
$_ubr = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR

# Check for Windows 8 or later
$_WIN8_OR_LATER = (([int]$_osVersion.Major -eq 6) -and ([int]$_osVersion.Minor -ge 2)) -or ([int]$_osVersion.Major -ge 6)
$_WINBLUE_OR_LATER = ([int]$_osVersion.Major -ge 6)

# Check for Windows 10 or later
$_WIN10 = [int]($_osVersion.Major -eq 10)
$_WIN10_OR_LATER = ($_WIN10) -or ([int]$_osVersion.Major -gt 10)

# Check for Windows 10 versions and later
$_WIN10_1607 = ($_WIN10) -and ([int]$_osVersion.Build -eq 14393)
$_WIN10_1607_OR_LATER = ($_WIN10_1607) -or ([int]$_osVersion.Build -gt 14393)
$_WIN10_1809_OR_LATER = ($_WIN10_1607_OR_LATER) -and ([int]$_osVersion.Build -ge 17763)
$_WIN10_1909_OR_LATER = ($_WIN10_1809_OR_LATER) -and ([int]$_osVersion.Build -ge 18363)
$_WIN10_2004_OR_LATER = ($_WIN10_1909_OR_LATER) -and ([int]$_osVersion.Build -ge 19041)

# Check for Windows 11 versions and later
$_WIN11_OR_LATER = ($_WIN10_2004_OR_LATER) -and ([int]$_osVersion.Build -ge 22000)
$_WIN11_21H2 = ($_WIN11_OR_LATER) -and ([int]$_osVersion.Build -eq 22000)
$_WIN11_22H2 = ($_WIN11_OR_LATER) -and ([int]$_osVersion.Build -eq 22621)
$_WIN11_23H2 = ($_WIN11_OR_LATER) -and ([int]$_osVersion.Build -eq 22631)

$_PS4ormore = 0
#$_PS5=0
# Get Powershell version
$_PS4ormore = [int]($PSVersionTable.PSVersion.Major -ge 4)
#$_PS5 = [int]($PSVersionTable.PSVersion.Major -eq 5)

#region --- ETW component trace Providers ---
$DND_AudioETWProviders = @(
	'{F3F14FF3-7B80-4868-91D0-D77E497B025E}' # Microsoft-Windows-WMP
	'{AE4BD3BE-F36F-45B6-8D21-BDD6FB832853}' # Microsoft-Windows-Audio
	'{7C314E58-8246-47D1-8F7A-4049DC543E0B}' # Microsoft-Windows-WMPNSSUI
	'{614696C9-85AF-4E64-B389-D2C0DB4FF87B}' # Microsoft-Windows-WMPNSS-PublicAPI
	'{BE3A31EA-AA6C-4196-9DCC-9CA13A49E09F}' # Microsoft-Windows-Photo-Image-Codec
	'{02012A8A-ADF5-4FAB-92CB-CCB7BB3E689A}' # Microsoft-Windows-ShareMedia-ControlPanel
	'{B20E65AC-C905-4014-8F78-1B6A508142EB}' # Microsoft-Windows-MediaFoundation-Performance-Core
	'{3F7B2F99-B863-4045-AD05-F6AFB62E7AF1}' # Microsoft-Windows-TerminalServices-MediaRedirection
	'{42D580DA-4673-5AA7-6246-88FDCAF5FFBB}' # Microsoft.Windows.CastQuality
	'{1F930302-F484-4E01-A8A7-264354C4B8E3}' # Microsoft.Windows.Cast.MiracastLogging
	'{596426A4-3A6D-526C-5C63-7CA60DB99F8F}' # Microsoft.Windows.WindowsMediaPlayer
	'{E27950EB-1768-451F-96AC-CC4E14F6D3D0}' # AudioTrace
	'{A9C1A3B7-54F3-4724-ADCE-58BC03E3BC78}' # Windows Media Player Trace
	'{E2821408-C59D-418F-AD3F-AA4E792AEB79}' # SqmClientTracingGuid
	'{6E7B1892-5288-5FE5-8F34-E3B0DC671FD2}' # Microsoft.Windows.Audio.Client
	'{AAC97853-E7FC-4B93-860A-914ED2DEEE5A}' # MediaServer
	'{E1CCD9F8-6E9F-43ad-9A32-8DBEBE72A489}' # WMPDMCCoreGuid
	'{d3045008-e530-485e-81b7-c6d54dbd9044}' # CTRLGUID_EVR_WPP
	'{00000000-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_PLATFORM
	'{00000001-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_PIPELINE
	'{00000002-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_CORE_SINKS
	'{00000003-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_CORE_SOURCES
	'{00000004-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_NETWORK
	'{00000005-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_CORE_MFTS
	'{00000006-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_PLAY
	'{00000007-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_CAPTURE_ENGINE
	'{00000008-0dc9-401d-b9b8-05e4eca4977e}' # CTRLGUID_MF_VIDEO_PROCESSOR
	'{C9C074D2-FF9B-410F-8AC6-81C7B8E60D0F}' # MediaEngineCtrlGuid
	'{982824E5-E446-46AE-BC74-836401FFB7B6}' # Microsoft-Windows-Media-Streaming
	'{8F2048E0-F260-4F57-A8D1-932376291682}' # Microsoft-Windows-MediaEngine
	'{8F0DB3A8-299B-4D64-A4ED-907B409D4584}' # Microsoft-Windows-Runtime-Media
	'{DD2FE441-6C12-41FD-8232-3709C6045F63}' # Microsoft-Windows-DirectAccess-MediaManager
	'{D2402FDE-7526-5A7B-501A-25DC7C9C282E}' # Microsoft-Windows-Media-Protection-PlayReady-Performance
	'{B8197C10-845F-40CA-82AB-9341E98CFC2B}' # Microsoft-Windows-MediaFoundation-MFCaptureEngine
	'{4B7EAC67-FC53-448C-A49D-7CC6DB524DA7}' # Microsoft-Windows-MediaFoundation-MFReadWrite
	'{A4112D1A-6DFA-476E-BB75-E350D24934E1}' # Microsoft-Windows-MediaFoundation-MSVProc
	'{F404B94E-27E0-4384-BFE8-1D8D390B0AA3}' # Microsoft-Windows-MediaFoundation-Performance
	'{BC97B970-D001-482F-8745-B8D7D5759F99}' # Microsoft-Windows-MediaFoundation-Platform
	'{B65471E1-019D-436F-BC38-E15FA8E87F53}' # Microsoft-Windows-MediaFoundation-PlayAPI
	'{323DAD74-D3EC-44A8-8B9D-CAFEB4999274}' # Microsoft-Windows-WLAN-MediaManager
	'{F4C9BE26-414F-42D7-B540-8BFF965E6D32}' # Microsoft-Windows-WWAN-MediaManager
	'{4199EE71-D55D-47D7-9F57-34A1D5B2C904}' # TSMFTrace
	'{A9C1A3B7-54F3-4724-ADCE-58BC03E3BC78}' # CtlGuidWMP
	'{3CC2D4AF-DA5E-4ED4-BCBE-3CF995940483}' # Microsoft-Windows-DirectShow-KernelSupport
	'{968F313B-097F-4E09-9CDD-BC62692D138B}' # Microsoft-Windows-DirectShow-Core
	'{9A010476-792D-57BE-6AF9-8DE32164F021}' # Microsoft.Windows.DirectShow.FilterGraph
	'{E5E16361-C9F0-4BF4-83DD-C3F30E37D773}' # VmgTraceControlGuid
	'{A0386E75-F70C-464C-A9CE-33C44E091623}' # DXVA2 (DirectX Video Acceleration 2)
	'{86EFFF39-2BDD-4EFD-BD0B-853D71B2A9DC}' # Microsoft-Windows-MPEG2_DLNA-Encoder
	'{AE5CF422-786A-476A-AC96-753B05877C99}' # Microsoft-Windows-MSMPEG2VDEC
	'{51311DE3-D55E-454A-9C58-43DC7B4C01D2}' # Microsoft-Windows-MSMPEG2ADEC
	'{0A95E01D-9317-4506-8796-FB946ACD7016}' # CodecLogger
	'{EA6D6E3B-7014-4AB1-85DB-4A50CDA32A82}' # Codec
	'{7F2BD991-AE93-454A-B219-0BC23F02262A}' # Microsoft-Windows-MP4SDECD
	'{2A49DE31-8A5B-4D3A-A904-7FC7409AE90D}' # Microsoft-Windows-MFH264Enc
	'{55BACC9F-9AC0-46F5-968A-A5A5DD024F8A}' # Microsoft-Windows-wmvdecod
	'{313B0545-BF9C-492E-9173-8DE4863B8573}' # Microsoft-Windows-WMVENCOD
	'{3293F985-41D3-4B6A-B187-2FF4AA91F2FC}' # Multimedia-HEVCDECODER / Microsoft-OneCore-Multimedia-HEVCDECODER
	'{D17B213A-C505-49C9-98CC-734253EF65D4}' # Microsoft-Windows-msmpeg2venc
	'{B6C06841-5C8C-47A6-BEDE-6159F4D4A701}' # MyDriver1TraceGuid
	'{E80ADCF1-C790-4108-8BB9-8A5CA3466C04}' # Microsoft-Windows-TerminalServices-RDP-AvcSoftwareDecoder
	'{3f7b2f99-b863-4045-ad05-f6afb62e7af1}' # Microsoft-Windows-TerminalServices-MediaRedirection(tsmf.dll)
)

$DND_AudioWPRProviders = @(
)

$DND_PowerWPRProviders = @(
)

$DND_WUProviders = @(
	'{0b7a6f19-47c4-454e-8c5c-e868d637e4d8}' # WUTraceLogging
	'{9906081d-e45a-4f41-a53f-2ac2e0225de1}' # SIHTraceLoggingProviderGuid
	'{5251FD36-A05A-4033-ADAD-FA409644E282}' # SIHTraceLoggingSessionGuid
	'{D48679EB-8AA3-4138-BE24-F1648C874E49}' # SoftwareUpdateClientTelemetry
)

$DND_CBSProviders = @(
	'{5fc48aed-2eb8-4cd4-9c87-54700c4b7b26}' # CbsServicingProvider
	'{bd12f3b8-fc40-4a61-a307-b7a013a069c1}' # Microsoft-Windows-Servicing
	'{34c6b9f6-c1cf-4fe5-a133-df6cb085ec67}' # CBSTRACEGUID
)

$DND_CodeIntegrityProviders = @(
	'{DDD9464F-84F5-4536-9F80-03E9D3254E5B}' # MicrosoftWindowsCodeIntegrityTraceLoggingProvider
	'{2e1eb30a-c39f-453f-b25f-74e14862f946}' # MicrosoftWindowsCodeIntegrityAuditTraceLoggingProvider
	'{4EE76BD8-3CF4-44a0-A0AC-3937643E37A3}' # Microsoft-Windows-CodeIntegrity
	'{EB65A492-86C0-406A-BACE-9912D595BD69}' # Microsoft-Windows-AppModel-Exec
	'{EF00584A-2655-462C-BC24-E7DE630E7FBF}' # Microsoft.Windows.AppLifeCycle
	'{382B5E24-181E-417F-A8D6-2155F749E724}' # Microsoft.Windows.ShellExecute
	'{072665fb-8953-5a85-931d-d06aeab3d109}' # Microsoft.Windows.ProcessLifetimeManager
)

$DND_PNPProviders = @(
	'{63aeffcd-648e-5fc0-b4e7-a39a4e6612f8}' # Microsoft.Windows.InfRemove
	'{2E5950B2-1F5D-4A52-8D1F-4E656C915F57}' # Microsoft.Windows.PNP.DeviceManager
	'{F52E9EE1-03D4-4DB3-B2D4-1CDD01C65582}' # PnpInstall
	'{9C205A39-1250-487D-ABD7-E831C6290539}' # Microsoft-Windows-Kernel-PnP
	'{8c8ebb7e-a4b7-4336-bddb-4a0aea0f535a}' # Microsoft.Windows.Sysprep.PnP
	'{0e0fe12b-e926-44d2-8cf1-8a62a6d44036}' # Microsoft.Windows.DriverStore
	'{139299bb-9394-5058-dd33-9422e5903fc3}' # Microsoft.Windows.SetupApi
	'{a23bd382-12ab-4f02-a0d7-273153f8b65a}' # Microsoft.Windows.DriverInstall
	'{059a2460-1077-4446-bdeb-5221de48b9e4}' # Microsoft.Windows.DriverStore.DriverPackage
	'{96F4A050-7E31-453C-88BE-9634F4E02139}' # Microsoft-Windows-UserPnp
	'{A676B545-4CFB-4306-A067-502D9A0F2220}' # PlugPlay
	'{84051b98-f508-4e54-82fa-8865c697c3b1}' # Microsoft-Windows-PnPMgrTriggerProvider
	'{D5EBB80C-4407-45E4-A87A-015F6AF60B41}' # Microsoft-Windows-Kernel-PnPConfig
	'{FA8DE7C4-ACDE-4443-9994-C4E2359A9EDB}' # claspnp
	'{F5D05B38-80A6-4653-825D-C414E4AB3C68}' # Microsoft-Windows-StorDiag
	'{5590bf8b-9781-5d78-961f-5bb8b21fbaf6}' # Microsoft.Windows.Storage.Classpnp
	'{B3A0C2C8-83BB-4DDF-9F8D-4B22D3C38AD7}' # Microsoft-Windows-Kernel-PnP-Rundown
)

$DND_TPMProviders = @(
	'{1B6B0772-251B-4D42-917D-FACA166BC059}' # TPM
	'{3A8D6942-B034-48E2-B314-F69C2B4655A3}' # TpmCtlGuid
	'{470baa67-2d7f-4c9c-8bf4-b1b3226f7b17}' # Microsoft.Tpm.ProvisioningTask
	'{7D5387B0-CBE0-11DA-A94D-0800200C9A66}' # Microsoft-Windows-TPM-WMI
	'{84FF4863-8173-5F91-9E83-B4C3B38042D5}' # Microsoft.Tpm.Drv_20
	'{6FCC5608-58C2-56AE-5ACD-B2A70F6323CF}' # Microsoft.Tpm.Drv_12
	'{61D3C72E-6B1B-454C-A34D-B39EB95B8D99}' # Microsoft.Tpm.Tbs
)
#endregion --- ETW component trace Providers ---


#region --- Scenario definitions ---
$DND_ServicingProviders = @( # all Providers need to be defined already above
	$DND_CBSProviders
	$DND_PNPProviders
	$DND_WUProviders
)

$DND_AudioETW_ETWTracingSwitchesStatus = [Ordered]@{
	'DND_AudioETW'        = $true
	'noBasicLog'          = $true
	'CollectComponentLog' = $true
}

$DND_AudioWPR_ETWTracingSwitchesStatus = [Ordered]@{
	'DND_AudioWPR'        = $true
	'noBasicLog'          = $true
	'CollectComponentLog' = $true
}

$DND_General_ETWTracingSwitchesStatus = [Ordered]@{
	'CommonTask NET'                   = $True  ## <------ the commontask can take one of "Dev", "NET", "ADS", "UEX", "DnD" and "SHA", or "Full" or "Mini"
	'NetshScenario InternetClient_dbg' = $true
	'Procmon'                          = $true
	#'WPR General' = $true
	'PerfMon ALL'                      = $true
	'PSR'                              = $true
	'Video'                            = $true
	'SDP NET'                          = $True
	'xray'                             = $True
	'CollectComponentLog'              = $True
}

$DND_Servicing_ETWTracingSwitchesStatus = [Ordered]@{
	'DND_Servicing'       = $True
	'Procmon'             = $True
	'noBasicLog'          = $True
	'CollectComponentLog' = $True
}

$DND_PowerWPR_ETWTracingSwitchesStatus = [Ordered]@{
	'DND_PowerWPR'        = $true
	'noBasicLog'          = $true
	'CollectComponentLog' = $true
}
#endregion --- Scenario definitions ---

#region Functions

function CollectDND_PnPLog {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] exporting PNP info"
	$outFile = $PrefixTime + 'PnP_info_Stop_.txt'
	'/enum-devices /problem', '/enum-devices' | ForEach-Object {
		$Commands = @("pnputil.exe $_ | Out-File -Append $outFile"); RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False }
	EndFunc $MyInvocation.MyCommand.Name
}

# [we] _NET: moved NET_ '_WinUpd' to _DND, #394
function CollectDND_WinUpdLog {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] collecting 'Get-WindowsUpdateLog -LogPath WindowsUpdate.log'"
	$Commands = @(
		'Set-Alias Out-Default Out-Null'
		"Get-WindowsUpdateLog -LogPath $PrefixCn`WindowsUpdate.log"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	EndFunc $MyInvocation.MyCommand.Name
}

########## CollectLog Function ############
#For CopyLogs.cmd
Function CollectDND_WULogsLog {
	EnterFunc $MyInvocation.MyCommand.Name
	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}

	# Skipping unneccessary basic log collection
	$global:ParameterArray += 'noBasicLog'

	# $TempDir="$LogFolder\WU_Logs$LogSuffix"
	# Create a string variable named $TempDir that concatenates the values of two variables $LogFolder and $LogSuffix.
	# The -join operator is used for joining the strings, which is faster and more memory-efficient than string concatenation.
	$TempDir = "$LogFolder\WU_Logs$LogSuffix" -join ''

	FwCreateFolder $TempDir
	$Prefix = Join-Path $TempDir $env:COMPUTERNAME'_'
	$RobocopyLog = $Prefix + 'robocopy.log'
	$ErrorFile = $Prefix + 'Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	$validValues = '0', '1'
	# use tss_config.cfg to modify these parameters on the fly as you need them
	# Flush Windows Update logs by stopping services before copying...usually not needed.
	# $global:DND_SETUPReport_FlushLogs set in tss_config.cfg?
	$FlushLogs = if ($DND_SETUPReport_FlushLogs -in $validValues) { $DND_SETUPReport_FlushLogs } else { 0 }

	$_WUETLPATH = "$env:windir\Logs\WindowsUpdate"
	$_SIHETLPATH = "$env:windir\Logs\SIH"
	$_WUOLDETLPATH = "$env:windir.old\Windows\Logs\WindowsUpdate"
	$_OLDPROGRAMDATA = "$env:windir.old\ProgramData"
	$_OLDLOCALAPPDATA = $env:LOCALAPPDATA -replace '^.{2}', "$env:windir.old"

	LogInfo ("[OS] Version: $_major.$_minor.$_build")

	# starting MsInfo early
	FwGetMsInfo32 'nfo' -Subfolder "WU_Logs$LogSuffix"
	FwGetSysInfo -Subfolder "WU_Logs$LogSuffix"

	Write-Output '-------------------------------------------'
	Write-Output 'Copying logs ...'
	Write-Output '-------------------------------------------'
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:windir\windowsupdate.log", "$($Prefix)WindowsUpdate.log"),
		@("$env:windir\SoftwareDistribution\ReportingEvents.log", "$($Prefix)WindowsUpdate_ReportingEvents.log"),
		@("$env:LOCALAPPDATA\microsoft\windows\windowsupdate.log", "$($Prefix)WindowsUpdatePerUser.log"),
		@("$env:windir\windowsupdate (1).log", "$($Prefix)WindowsUpdate(1).log"),
		@("$env:windir.old\Windows\windowsupdate.log", "$($Prefix)WindowsUpdate.old.log"),
		@("$env:windir.old\Windows\SoftwareDistribution\ReportingEvents.log", "$($Prefix)ReportingEvents.old.log"),
		@("$_OLDLOCALAPPDATA\microsoft\windows\windowsupdate.log", "$($Prefix)WindowsUpdatePerUser.old.log"),
		@("$env:windir\SoftwareDistribution\Plugins\7D5F3CBA-03DB-4BE5-B4B36DBED19A6833\TokenRetrieval.log", "$($Prefix)WindowsUpdate_TokenRetrieval.log")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

	# -------------------------------------------------------------
	# CBS & PNP logs
	$Commands = @(
		"robocopy.exe `"$env:windir\logs\cbs`" 	$TempDir\CBS *.log /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\logs\cbs`" 	$TempDir\CBS *.cab /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\logs\dpx`" 	$TempDir\CBS *.log /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\inf`" 		$TempDir\CBS *.log /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\WinSxS`" 	$TempDir\CBS poqexec.log /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\WinSxS`" 	$TempDir\CBS pending.xml /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\servicing\sessions`" $TempDir\CBS\Sessions /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
	)
	RunCommands 'CBS_PNP' $Commands -ThrowException:$False -ShowMessage:$True

	# UUP logs and action list xmls
	if ((Test-Path -Path "$env:windir\SoftwareDistribution\Download\*.log") -or (Test-Path -Path "$env:windir\SoftwareDistribution\Download\*.xml")) {
		robocopy "$env:windir\SoftwareDistribution\Download" "$TempDir\UUP" *.log *.xml /W:1 /R:1 /NP /LOG+:$RobocopyLog
	}

	# -------------------------------------------------------------
	# Windows Store logs.
	cmd /r copy "$env:TEMP\winstore.log" "$($Prefix)winstore-Broker.log" /y >$null 2>&1
	robocopy "$env:USERPROFILE\AppData\Local\Packages\WinStore_cw5n1h2txyewy\AC\Temp" "$TempDir winstore.log" /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null

	# -------------------------------------------------------------
	# WU ETLs for Win10+
	# Newer build has multiple ETLs
	if (Test-Path -Path $_WUETLPATH) {
		$LogPrefixFlushLogs = 'FlushLogs'
		LogInfo ("[$LogPrefixFlushLogs] Flushing USO/WU logs")
		$CommandsFlushLogs = @(
			'Stop-Service -Name usosvc'
			'Stop-Service -Name wuauserv'
		)
		RunCommands $LogPrefixFlushLogs $CommandsFlushLogs -ThrowException:$False -ShowMessage:$True

		robocopy $_WUETLPATH $TempDir\WU *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null

		$LogPrefixWU = 'WU'
		if ($_WIN10_1607) {
			LogInfo ("[$LogPrefixWU] Public symbol server: Trying to connect...")
			# temporarily save $ProgressPreference
			$OriginalProgressPreference = $Global:ProgressPreference
			$Global:ProgressPreference = 'SilentlyContinue'
			$pubsymsrvcon = Test-NetConnection -ComputerName $PublicSymSrv -CommonTCPPort HTTP -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
			# reset $ProgressPreference
			$Global:ProgressPreference = $OriginalProgressPreference

			if (($false -eq ($pubsymsrvcon).TcpTestSucceeded)) {
				LogWarn ("[$LogPrefixWU] Public symbol server: Connection failed.")
				@("Public symbol server: Wasn't able to connect to $PublicSymSrv.", 'Please convert ETL files from logs\WindowsUpdate instead.', 'Use a internet connected Windows Server 2016 to convert logs with Get-WindowsUpdateLog.', $Line, $pubsymsrvcon) | Out-File -FilePath ($Prefix + 'WindowsUpdateETL_PublicSymbolsFailed.log') -Append
			}
			# only run if public symbol server is reachable
			elseif ($true -eq ($pubsymsrvcon).TcpTestSucceeded) {
				LogInfo ("[$LogPrefixWU] Public symbol server: Connected.")
				@("Public symbol server: Successfully connected to $PublicSymSrv.", $Line, $pubsymsrvcon) | Out-File -FilePath ($Prefix + 'WindowsUpdateETL_PublicSymbolsConnected.log') -Append
				LogInfo ("[$LogPrefixWU] Getting Windows Update log.")
				LogInfo ("[$LogPrefixWU] tracerpt.exe retrieving public symbols for ETL conversion - this might take a while...") 'Cyan'
				# Suppress script output by using a job
				$WULogsJobLog = "$($Prefix)WindowsUpdateETL_Converted.log"
				$WULogsJob = Start-Job -ScriptBlock { Get-WindowsUpdateLog -Log $args } -ArgumentList $WULogsJobLog
				$WULogsJob | Wait-Job | Remove-Job
				#  robocopy "$env:SystemDrive\ $TempDir\$_WINDOWSUPDATE WindowsUpdateVerbose.etl" /W:1 /R:1 /NP /LOG+:$RobocopyLog
			}
		}
		elseif ($_WIN10_1607_OR_LATER) {
			LogInfo ("[$LogPrefixWU] Getting Windows Update log.")
			# Suppress script output by using a job
			$WULogsJobLog = "$($Prefix)WindowsUpdateETL_Converted.log"
			$WULogsJob = Start-Job -ScriptBlock { Get-WindowsUpdateLog -Log $args } -ArgumentList $WULogsJobLog
			$WULogsJob | Wait-Job | Remove-Job
		}

	}

	# Copy SIH ETLs
	if (Test-Path -Path $_SIHETLPATH) {
		robocopy $_SIHETLPATH $TempDir\SIH *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	}

	# Older build has ETL in windir
	if (Test-Path -Path "$env:windir\windowsupdate.etl") {
		# windowsupdate.etl is not flushed until service is stopped.
		$LogPrefixFlushLogs = 'FlushLogs'
		LogInfo ("[$LogPrefixFlushLogs] Flushing USO/WU logs")
		$CommandsFlushLogs = @(
			'Stop-Service -Name usosvc'
			'Stop-Service -Name wuauserv'
		)
		RunCommands $LogPrefixFlushLogs $CommandsFlushLogs -ThrowException:$False -ShowMessage:$True

		robocopy "$env:windir" $TempDir windowsupdate.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	}

	# Verbose Logging redirects WU ETL to systemdrive in newer builds
	if (Test-Path -Path "$env:SystemDrive\windowsupdateverbose.etl") {
		# windowsupdateverbose.etl is not flushed until service is stopped.
		$LogPrefixFlushLogs = 'FlushLogs'
		LogInfo ("[$LogPrefixFlushLogs] Flushing USO/WU logs")
		$CommandsFlushLogs = @(
			'Stop-Service -Name usosvc'
			'Stop-Service -Name wuauserv'
		)
		RunCommands $LogPrefixFlushLogs $CommandsFlushLogs -ThrowException:$False -ShowMessage:$True

		robocopy $env:SystemDrive $TempDir windowsupdateverbose.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	}

	Write-Output '-------------------------------------------'
	Write-Output 'Copying upgrade logs'
	Write-Output '-------------------------------------------'
	cmd /r mkdir "$TempDir\UpgradeSetup" >$null 2>&1
	cmd /r mkdir "$TempDir\UpgradeSetup\NewOS" >$null 2>&1
	cmd /r mkdir "$TempDir\UpgradeSetup\UpgradeAdvisor" >$null 2>&1

	robocopy "$env:SystemDrive\Windows10Upgrade" "$TempDir\UpgradeSetup\UpgradeAdvisor" Upgrader_default.log /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	robocopy $env:SystemDrive\Windows10Upgrade "$TempDir\UpgradeSetup\UpgradeAdvisor" Upgrader_win10.log /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	robocopy "$env:SystemDrive\$GetCurrent\logs" "$TempDir\UpgradeSetup\UpgradeAdvisor" *.* /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	robocopy "$env:windir\logs\mosetup" "$TempDir\UpgradeSetup" *.log /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	cmd /r copy "$env:windir.old\Windows\logs\mosetup\*.log" "$TempDir\UpgradeSetup\bluebox_windowsold.log" /y >$null 2>&1
	robocopy "$env:windir\Panther\NewOS" "$TempDir\UpgradeSetup\NewOS" *.log /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	robocopy "$env:windir\Panther\NewOS" "$TempDir\UpgradeSetup\NewOS" miglog.xml /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	robocopy "$env:windir\Panther" "$TempDir\UpgradeSetup" *.log /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	robocopy "$env:windir\Panther" "$TempDir\UpgradeSetup" miglog.xml /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	cmd /r copy "$env:SystemDrive\`$Windows.~BT\Sources\Panther\setupact.log" "$TempDir\UpgradeSetup\setupact_tildabt.log" /y >$null 2>&1
	cmd /r copy "$env:SystemDrive\`$Windows.~BT\Sources\Panther\setuperr.log" "$TempDir\UpgradeSetup\setuperr_tildabt.log" /y >$null 2>&1
	cmd /r copy "$env:SystemDrive\`$Windows.~BT\Sources\Panther\miglog.xml" "$TempDir\UpgradeSetup\miglog_tildabt.xml" /y >$null 2>&1
	if (Test-Path -Path "$env:SystemDrive\`$Windows.~BT\Sources\Rollback") {
		robocopy "$env:SystemDrive\`$Windows.~BT\Sources\Rollback" "$TempDir\UpgradeSetup\Rollback" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S >$null
	}
	if (Test-Path -Path "$env:windir\Panther\NewOS") {
		robocopy "$env:windir\Panther\NewOS" "$TempDir\UpgradeSetup\PantherNewOS" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S >$null
	}

	# Copying the datastore file
	if (Test-Path -Path "$env:windir\softwaredistribution\datastore\datastore.edb") {
		Write-Output 'Copying WU datastore ...'
		Stop-Service -Name usosvc >$null 2>&1
		Stop-Service -Name wuauserv >$null 2>&1
		robocopy "$env:windir\softwaredistribution\datastore" $TempDir DataStore.edb /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	}

	# Also copy ETLs pre-upgrade
	if (Test-Path -Path $_WUOLDETLPATH) {
		robocopy $_WUOLDETLPATH "$TempDir\Windows.old\WU" *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	}

	# -------------------------------------------------------------
	# Copy DISM Logs and DISM output
	robocopy "$env:windir\logs\dism" $TempDir\DISM * /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	dism /english /online /get-packages /format:table > $Prefix'DISM_GetPackages.txt'
	dism /english /online /get-features /format:table > $Prefix'DISM_GetFeatures.txt'

	# -------------------------------------------------------------
	# MUSE logs for Win10+
	if ($null -ne (Get-Service -Name usosvc -ErrorAction SilentlyContinue)) {
		Write-Output 'Copying MUSE logs ...'
		Stop-Service -Name usosvc >$null 2>&1
		robocopy "$env:ProgramData\UsoPrivate\UpdateStore" "$TempDir\MUSE" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S >$null
		robocopy "$env:ProgramData\USOShared\Logs" "$TempDir\MUSE" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S >$null
		SCHTASKS /query /v /TN \Microsoft\Windows\UpdateOrchestrator\ > "$TempDir\MUSE\updatetaskschedules.txt"
		robocopy "$_OLDPROGRAMDATA\USOPrivate\UpdateStore" "$TempDir\Windows.old\MUSE" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S >$null
		robocopy "$_OLDPROGRAMDATA\USOShared\Logs" "$TempDir\Windows.old\MUSE" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S >$null
	}

	# -------------------------------------------------------------
	# DO logs for Win10+
	if ($_WIN10_OR_LATER) {
		Get-DNDDoLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# -------------------------------------------------------------
	# WU BVT logs.
	$bvtPaths = "$env:SystemDrive\wubvt", "$env:SystemDrive\dcatebvt", "$env:SystemDrive\wuappxebvt", "$env:SystemDrive\wuuxebvt", "$env:SystemDrive\wuauebvt", "$env:SystemDrive\WUE2ETest", "$env:SystemDrive\taef\wubvt", "$env:SystemDrive\taef\wuappxebvt", "$env:SystemDrive\taef\wuuxebvt", "$env:SystemDrive\taef\wuauebvt", "$env:SystemDrive\taef\WUE2ETest", "$env:SystemDrive\taef\WUE2ETest"
	foreach ($bvtPath in $bvtPaths) {
		if (Test-Path $bvtPath) {
			FwCreateFolder $TempDir\BVT
			robocopy $bvtPath $TempDir\BVT *.log /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
		}
	}
	Write-Output '-------------------------------------------'
	Write-Output 'Copying token cache and license store ...'
	Write-Output '-------------------------------------------'
	robocopy "$env:windir\ServiceProfiles\LocalService\AppData\Local\Microsoft\WSLicense" $TempDir tokens.dat /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null
	robocopy "$env:windir\SoftwareDistribution\Plugins\7D5F3CBA-03DB-4BE5-B4B36DBED19A6833" $TempDir 117CAB2D-82B1-4B5A-A08C-4D62DBEE7782.cache /W:1 /R:1 /NP /LOG+:$RobocopyLog >$null

	Write-Output '-------------------------------------------'
	Write-Output 'Copying event logs ...'
	Write-Output '-------------------------------------------'
	$_event_logs = 'Application', 'Microsoft-Windows-AppXDeployment/Operational', 'Microsoft-Windows-AppXDeploymentServer/Operational', 'Microsoft-Windows-AppXDeploymentServer/Restricted', 'Microsoft-Windows-AppxPackaging/Operational', 'Microsoft-Windows-Bits-Client/Operational', 'Microsoft-Windows-Kernel-PnP/Configuration', 'Microsoft-Windows-Store/Operational', 'Microsoft-Windows-WindowsUpdateClient/Operational', 'System'
	$EVTX = $false
	$_format = '/TXT'
	Get-DNDEventLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs $_event_logs $EVTX $_format
	$_event_logs = ($_event_logs).replace('/', '%4')
	foreach ($_event_log in $_event_logs) {
		if (Test-Path "$env:windir\System32\winevt\Logs\$($_event_log).evtx") {
			Copy-Item "$env:windir\System32\winevt\Logs\$($_event_log).evtx" "$($Prefix)evt_$(($_event_log).replace('Microsoft-Windows-','')).evtx"
		}
	}

    # -------------------------------------------------------------
	# Copy WaasMedic ETL SRT, PBR, SYsreset, ReAgentc WINREAgent
	$Commands = @(
		"robocopy.exe `"$env:windir\System32\Logfiles\SRT`" 	$TempDir\SRT * /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\logs\PBR`" 	$TempDir\PBR * /W:1 /R:1 /NP /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `'$env:systemdrive\`$Sysreset\Logs`' 	$TempDir\SysReset * /W:1 /R:1 /NP /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\logs\ReAgent`" 		$TempDir\ReAgent * /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"
		"robocopy.exe `"$env:windir\logs\WinREAgent`" 	$TempDir\WinREAgent * /W:1 /R:1 /NP /LOG+:$RobocopyLog | Out-Null"

	)
	if (Test-Path -Path "$env:windir\Logs\WAASMEDIC") {
        if ((Get-ChildItem -Path "$env:windir\Logs\WAASMEDIC" -ErrorAction Ignore).Count -gt 0) {
            $Commands += @("robocopy `"$env:windir\Logs\WAASMEDIC`" $TempDir\WaaSMedic *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog  | Out-Null")
        }
    }
	RunCommands 'Misc_Recovery' $Commands -ThrowException:$False -ShowMessage:$True



	Write-Output '-------------------------------------------'
	Write-Output 'Logging registry ...'
	Write-Output '-------------------------------------------'
	$RegKeysMiscInfoExport = @(
		('HKLM:Software\Microsoft\Windows\CurrentVersion\WindowsUpdate', "$($Prefix)reg_wu.txt"),
		('HKLM:Software\Policies\Microsoft\Windows\WindowsUpdate', "$($Prefix)reg_wupolicy.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\MUI\UILanguages', "$($Prefix)reg_langpack.txt"),
		('HKLM:Software\Policies\Microsoft\WindowsStore', "$($Prefix)reg_StorePolicy.txt"),
		('HKLM:Software\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate', "$($Prefix)reg_StoreWUApproval.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\FirmwareResources', "$($Prefix)reg_FirmwareResources.txt"),
		('HKLM:Software\Microsoft\WindowsSelfhost', "$($Prefix)reg_WindowsSelfhost.txt"),
		('HKLM:Software\Microsoft\WindowsUpdate', "$($Prefix)reg_wuhandlers.txt"),
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion\Superfetch', "$($Prefix)reg_superfetch.txt"),
		('HKLM:Software\Setup', "$($Prefix)reg_Setup.txt"),
		('HKCU:Software\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate', "$($Prefix)reg_peruser_wupolicy.txt"),
		('HKLM:Software\Microsoft\PolicyManager\current\device\Update', "$($Prefix)reg_wupolicy_mdm.txt"),
		('HKLM:Software\Microsoft\WindowsUpdate\UX\Settings', "$($Prefix)reg_wupolicy_ux.txt"),
		('HKLM:Software\Microsoft\Windows\CurrentVersion\WaaSAssessment', "$($Prefix)reg_WaasAssessment.txt"),
		('HKLM:Software\Microsoft\sih', "$($Prefix)reg_sih.txt"),
		('HKLM:Software\Microsoft\Windows\CurrentVersion\Appx', "$($Prefix)reg_Appx.txt"),
		('HKLM:SOFTWARE\Microsoft\SQMClient', "$($Prefix)reg_SQMClient.txt")
	)
	FwExportRegistry 'MiscInfo' $RegKeysMiscInfoExport -RealExport $true

	$RegKeysMiscInfoProperty = @(
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'BuildLab', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'BuildLabEx', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'UBR', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'ProductName', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel', 'Version', "$($Prefix)reg_AppModelVersion.txt")
	)
	FwExportRegistry 'MiscInfo' $RegKeysMiscInfoProperty

	Write-Output '-------------------------------------------'
	Write-Output 'Collecting other stuff ...'
	Write-Output '-------------------------------------------'
	Write-Output 'Getting networking configs ...'
	$Commands = @(
		"ipconfig /all													| Out-File -Append $($Prefix)ipconfig.txt"
		"cmd /r netsh winhttp show proxy								| Out-File -Append $($Prefix)winhttp_proxy.txt"
		"cmd /r copy `"$env:windir\System32\drivers\etc\hosts`" `"$($Prefix)hosts_file.txt`" /y"
	)
	RunCommands 'Network_config' $Commands -ThrowException:$False -ShowMessage:$True

	Write-Output 'Getting directory lists ...'
	$Commands = @(
		"cmd /r dir $env:windir\SoftwareDistribution /s					| Out-File -Append $($Prefix)dir_softwaredistribution.txt"
		"cmd /r dir $env:windir\SoftwareDistribution /ah				| Out-File -Append $($Prefix)dir_softwaredistribution_hidden.txt"
	)
	RunCommands 'directory_lists' $Commands -ThrowException:$False -ShowMessage:$True

	Write-Output 'Getting app list ...'
	if ($_WIN8_OR_LATER) {
		try { Import-Module appx; Get-AppxPackage -AllUsers | Out-File -FilePath $Prefix'GetAppxPackage.log' }
		catch { LogException ('Get-Appxpackage failed') $_ }
	}
	if ($_WINBLUE_OR_LATER) {
		try { Get-AppxPackage -packagetype bundle | Out-File -FilePath $Prefix'GetAppxPackageBundle.log' }
		catch { LogException ('Get-Appxpackage failed') $_ }
	}
	Write-Output 'Getting download list ...'
	bitsadmin /list /allusers /verbose > $Prefix'bitsadmin.log'

	Write-Output 'Getting certificate list ...'
	certutil -store root > $Prefix'certs.txt' 2>&1

	Write-Output 'Getting installed update list ...'
	$Commands = @(
		"Get-CimInstance -ClassName win32_quickfixengineering			| Out-File -Append $($Prefix)InstalledUpdates.log"
		"sc.exe query wuauserv											| Out-File -Append $($Prefix)wuauserv-state.txt"
		"SCHTASKS /query /v /TN \Microsoft\Windows\WindowsUpdate\		| Out-File -Append $($Prefix)WUScheduledTasks.log"
	)
	RunCommands 'installed_update' $Commands -ThrowException:$False -ShowMessage:$True

	Write-Output '-------------------------------------------'
	Write-Output 'Collecting file versions ...'
	Write-Output '-------------------------------------------'

	$binaries = @('wuaext.dll', 'wuapi.dll', 'wuaueng.dll', 'wucltux.dll', 'wudriver.dll', 'wups.dll', 'wups2.dll', 'wusettingsprovider.dll', 'wushareduxresources.dll', 'wuwebv.dll', 'wuapp.exe', 'wuauclt.exe', 'storewuauth.dll', 'wuuhext.dll', 'wuuhmobile.dll', 'wuau.dll', 'wuautoappupdate.dll')
	foreach ($file in $binaries) {
		FwFileVersion -Filepath ("$env:windir\system32\$file") | Out-File -FilePath "$($Prefix)FilesVersion.txt" -Append
	}

	$muis = @('wuapi.dll.mui', 'wuaueng.dll.mui', 'wucltux.dll.mui', 'wusettingsprovider.dll.mui', 'wushareduxresources.dll.mui')
	foreach ($file in $muis) {
		FwFileVersion -Filepath ("$env:windir\system32\en-US\$file")	| Out-File -FilePath ($Prefix + 'FilesVersion.txt') -Append
	}

	# end
	Write-Output '-------------------------------------------'
	Write-Output 'Restarting services ...'
	Write-Output '-------------------------------------------'
	$Commands = @(
		'Start-Service -Name dosvc'
		'Start-Service -Name usosvc'
		'Start-Service -Name wuauserv'
	)
	RunCommands 'Restart_services' $Commands -ThrowException:$False -ShowMessage:$True

	FwWaitForProcess $global:msinfo32NFO 300
	Write-Output '-------------------------------------------'
	Write-Output 'Finished DND_WUlogs!'
	Write-Output '-------------------------------------------'

	EndFunc $MyInvocation.MyCommand.Name
}

#For SetupReport
Function CollectDND_SETUPReportLog {
	EnterFunc $MyInvocation.MyCommand.Name
	# Skipping unneccessary basic log collection
	$global:ParameterArray += 'noBasicLog'

	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			$GETWINSXS
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}

	$TempDir = Join-Path $LogFolder "Setup_Report$LogSuffix"
	FwCreateFolder $TempDir
	$Prefix = Join-Path $TempDir ($env:COMPUTERNAME + '_')
	$RobocopyLog = $Prefix + 'robocopy.log'
	$ErrorFile = $Prefix + 'Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	# use tss_config.cfg to modify these parameters on the fly as you need them
	$validValues = '0', '1'
	# check if only activation logs are wanted
	$ACTONLY = if ($DND_SETUPReport_ACTONLY -in $validValues) { $DND_SETUPReport_ACTONLY } else { 0 }

	if ($(!$global:Menu)) {
		LogInfoFile 'Feature -Menu was NOT activated.' 'Yellow' -ShowMsg
		# configure defaults in int so that it can be converted to boolean, too
		@(
			('FlushLogs',	'0'),
			('DATASTORE',	'0'),
			('UPGRADE', '1'),
			('DXDIAG', '0'),
			('GETWINSXS',	'0'),
			('APPCOMPAT',	'0'),
			('POWERCFG',	'0'),
			('Min', '0'),
			('Max', '0'),
			('SURFACE', '0'),
			('Summary', '1'),
			('NETDETAIL',	'0'),
			('RFLCHECK',	'1'),
			('WU', '1'),
			('CBSPNP', '1'),
			('EVTX', '1'),
			('PERMPOL', '1'),
			('ACTIVATION',	'1'),
			('BITLOCKER',	'1'),
			('DIR', '1'),
			('SLOW', '1'),
			('PERF', '1'),
			('DO', '1'),
			('TWS', '1'),
			('PROCESS', '1'),
			('STORAGE', '1'),
			('MISC', '1'),
			('NETBASIC',	'1'),
			('DEFENDER',	'1'),
			('FILEVERSION',	'1'),
			('APPLOCKER',	'1'),
			('DEVICEGUARD',	'1'),
			('MDM', '1'),
			('WINRE', '0')
		) | ForEach-Object {
			# if $global:DND_SETUPReport_ACTONLY is set, disable anything else
			if ($ACTONLY) {
				if ($_[0] -eq 'ACTIVATION') { Set-Variable -Name $_[0] -Value ([int]1) } else { Set-Variable -Name $_[0] -Value ([int]0) }
				#Get-Variable $($_[0])
			}
			else {
				# evaluate settings from tss_config.cfg and set variables accordingly
				$DND_SETUPReport_TssConfig = (Get-Variable $('DND_SETUPReport_' + $_[0]) -ErrorAction Ignore).Value
				if ($DND_SETUPReport_TssConfig -in $validValues) { Set-Variable -Name $_[0] -Value ([int]$DND_SETUPReport_TssConfig) } else { Set-Variable -Name $_[0] -Value ([int]$_[1]) }
				#Get-Variable $($_[0])
			}
		}
	}
	else { LogInfoFile "skipped 'configure defaults in int' block with -Menu switch" 'Yellow' -ShowMsg }

	if ($Global:Menu) {
		LogInfo '** Please select or unselect your desired DND items from the PS popup window. **' 'Cyan' -noDate
		ShowMenu
		#Write-Host "Global:DND_SETUPReport_POWERCFG $Global:DND_SETUPReport_POWERCFG -- local POWERCFG: $POWERCFG -- script POWERCFG: $script:POWERCFG -APPCOMPAT $APPCOMPAT"
		#exit ## <- uncomment for TESTING only
	}

	# Get MBAM info
	$MBAM_SYSTEM = 0

	$DND_SETUPReport_Start = (Get-Date)
	LogInfo ('[DND_SETUPReport] Starting...')
	LogInfo ("[OS] Version: $_major.$_minor.$_build")
	# =================================================================================================================================================
	# Section For things that need to be started early
	# - Write script version info to MiscInfo
	Write-Output "TssVerDateDND:`t`t$global:TssVerDateDND" | Out-File -FilePath ($Prefix + 'MiscInfo.txt')
	# - Now lets setup Error output file header
	Write-Output $Line | Out-File -FilePath ($Prefix + 'MiscInfo.txt') -Append
	#Write-Output "Beginning error recording"											| Out-File -FilePath ($Prefix+"MiscInfo.txt") -Append
	#Write-Output $Line																	| Out-File -FilePath ($Prefix+"MiscInfo.txt") -Append
	Write-Output ("Starting at`t`t`t`t$DND_SETUPReport_Start")	| Out-File -FilePath ($Prefix + 'MiscInfo.txt') -Append
	# =================================================================================================================================================
	# New logic flow with functions

	# Determine if Surface by seeing if manufacturer is Microsoft
	$LogPrefixComputerSystem = 'ComputerSystem'
	try {
		LogInfo ("[$LogPrefixComputerSystem] Trying to determine if this is a Surface device.")
		$_manufacturer = (Get-CimInstance -Class:Win32_ComputerSystem).Manufacturer
		$_isVirtual = (Get-CimInstance -Class:Win32_ComputerSystem).Model.Contains('Virtual')
	}
	catch { LogException ("[$LogPrefixComputerSystem] Failed to query Win32_ComputerSystem class.") $_ }

	if ((($_manufacturer -eq 'microsoft') -or ($_manufacturer -eq 'microsoft corporation')) -and ($_isVirtual -ne $true)) { $SURFACE = 1 }
	if ($SURFACE -and !($ACTONLY)) { $POWERCFG = 1 }
	if ($SURFACE) {
		# call function SurfaceInfo
		Get-DNDSurfaceInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	if ($DXDIAG) {
		# call function dxdiag
		Get-DNDDxDiag $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# - App Compat check
	if ($APPCOMPAT -or $Max) {
		#------------------AppcompatFunc--------------------------
		# call function appcompat info
		Get-DNDAppCompatInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function Windows Update
	if ($WU) {
		Get-DNDWindowsUpdateInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# Get Datastore if set
	if ($DATASTORE) {
		Get-DNDDatastore $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function MDM Info
	if ($MDM) {
		Get-DNDMDMInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function delivery optimization logs
	if ($_WIN10_1809_OR_LATER) {
		if ($DO) {
			Get-DNDDoLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}
	}

	# call function general file info
	if ($_PS4ormore -and $FILEVERSION) {
		Get-DNDGeneralFileVersionInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	if ($GETWINSXS) { $_WINSXSVER = 1 }
	if (!($_PS4ormore)) { $_WINSXSVER = 0 }
	if ($_WINSXSVER) {
		# call function WinSxS version info
		Get-DNDWinSxSVersionInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function CBS and PNP
	if ($CBSPNP) {
		Get-DNDCbsPnpInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	if ($_WIN8_OR_LATER) {
		if ((Test-Path "$env:SystemRoot\system32\appxdeploymentserver.dll") -and ($TWS)) {
			# call function store info
			Get-DNDStoreInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}
	}

	if ($UPGRADE -or $Max) {
		# Windows Setup/Upgrade logs
		# call function upgrade logs
		Get-DNDSetupLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs

		# call function PBR logs
		Get-DNDPbrLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs

		# call function deployment logs
		Get-DNDDeploymentLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function event logs
	if ($EVTX) {
		Get-DNDEventLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs $_event_logs $EVTX $_format
	}

	# call function PermissionsAndPolicies
	if ($PERMPOL) {
		Get-DNDPermissionsAndPolicies $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function BitLockerInfo
	if ($BITLOCKER) {
		Get-DNDBitLockerInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function ReliabilitySummary
	if ($Summary -or $Max) {
		Get-DNDReliabilitySummary $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function ActivationState
	if ($ACTIVATION) {
		Get-DNDActivationState $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function DirInfo
	if ($DIR) {
		Get-DNDDirInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	#call function EnergyInfo
	Get-DNDEnergyInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs

	if (!$Min) {
		# call function StorageInfo
		if ($STORAGE) {
			Get-DNDStorageInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}

		# call function ProcessInfo
		if ($PROCESS) {
			Get-DNDProcessInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}

		# call function MiscInfo
		if ($MISC) {
			Get-DNDMiscInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}

		# call function NetworkSetup
		if ($NETBASIC) {
			Get-DNDNetworkBasic $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}

		if ($NETDETAIL) {
			# call function NetworkSetup
			Get-DNDNetworkSetup $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}
	}

	if ($_WIN10_OR_LATER) {
		# call function defender info
		if ($DEFENDER) {
			Get-DNDDefenderInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}

		# call function device guard
		if ($DEVICEGUARD) {
			Get-DNDDeviceGuard $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}
	}

	if (Test-Path $env:windir\Minidump) {
		# call funciton minidumps$ErrorFile$Line
		Get-DNDMiniDumps $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# call function SlowProcessing
	if ($SLOW) {
		Get-DNDSlowProcessing $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}
	# call function WinRE info
	if ($WINRE) {
		Get-DNDWinREInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	LogInfo ('[DND_SETUPReport] Finalizing.')

	# LEAVE THIS HERE AT END OF FILE AND RUN EVEN ON MIN OUTPUT
	# call function 15 sec perfmon
	if ($PERF) {
		Get-DNDGeneralPerfmon $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	if ($RFLCHECK) {
		# call function RFLcheck prereqs
		Get-DNDRFLCheckPrereqs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}

	# Windows 10 1607 or higher
	if ($_WIN10_1607_OR_LATER) {
		# call function applocker function
		if ($APPLOCKER) {
			# call function applocker prereqs
			Get-DNDAppLocker $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		}
	}

	# ---------------------------------------------------------------------------------------------
	# Section Wait for slow things to finish
	if (-not(Test-Path -Path ($Prefix + 'gpresult.htm'))) {
		if ($global:GPresultHTM) {
			LogInfo 'Waiting  30 seconds for background processing(GPresult) to complete' White
			FwWaitForProcess $global:GPresultHTM 30
		}
	}
	if (($global:msinfo32TXT.HasExited -eq $false) -or ($global:msinfo32NFO.HasExited -eq $false)) {
		FwWaitForProcess $global:msinfo32TXT 300
		FwWaitForProcess $global:msinfo32NFO 300
	}

	$DND_SETUPReport_End = (Get-Date)
	$DND_SETUPReport_Runtime = (New-TimeSpan -Start $DND_SETUPReport_Start -End $DND_SETUPReport_End)
	$DND_SETUPReport_hours = $DND_SETUPReport_Runtime.Hours
	$DND_SETUPReport_minutes = $DND_SETUPReport_Runtime.Minutes
	$DND_SETUPReport_seconds = $DND_SETUPReport_Runtime.Seconds
	$DND_SETUPReport_summary = "Overall duration: $DND_SETUPReport_hours hours, $DND_SETUPReport_minutes minutes and $DND_SETUPReport_seconds seconds"
	LogInfo "[DND_SETUPReport] $DND_SETUPReport_summary" 'Gray'
	Write-Output ("Completed at`t`t`t$DND_SETUPReport_End") | Out-File -Append ($Prefix + 'MiscInfo.txt')
	Write-Output ($Line)	| Out-File -FilePath ($Prefix + 'MiscInfo.txt') -Append
	Write-Output ($DND_SETUPReport_summary)	| Out-File -FilePath ($Prefix + 'MiscInfo.txt') -Append
	EndFunc $MyInvocation.MyCommand.Name
}
###END DND_SETUPReport

#################### FUNCTION DXDIAGFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDxDiag {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixDXDiag = 'DXDiag'
	$CommandsDXDiag = @(
		"dxdiag /t `"$($Prefix)DxDiag.txt`""
	)
	RunCommands $LogPrefixDXDiag $CommandsDXDiag -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DXDIAGFunc ####################

#################### FUNCTION AUDIOINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDAudioInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixAudioLogs = 'AudioLogs'
	# Taken from product managers blog: https://matthewvaneerde.wordpress.com/2017/01/09/collecting-audio-logs-the-old-fashioned-way/
	Import-Module "$Scriptfolder\config\DND_RegistryToXml.psm1"
	$system32 = "${env:windir}\system32"
	# check for WOW64
	if ($null -ne $env:PROCESSOR_ARCHITEW6432) {
		Write-Host 'WARNING: script is running WOW64'
		$system32 = "${env:windir}\sysnative"
	}
	# Dump registry keys
	LogInfo "[$LogPrefixAudioLogs] Export by querying registry keys."
	@(
		([Microsoft.Win32.RegistryHive]::CurrentUser, 'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore', "$($Prefix)CapabilityAccessManager-ConsentStore-HKCU.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SOFTWARE\Microsoft\SQMClient', "$($Prefix)SQMClient.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Audio', "$($Prefix)CurrentVersionAudio.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore', "$($Prefix)CapabilityAccessManager-ConsentStore-HKLM.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices', "$($Prefix)MMDevices.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}', "$($Prefix)MediaDeviceConfig.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SYSTEM\CurrentControlSet\Control\Class\{c166523c-fe0c-4a94-a586-f1a80cfbbf3e}', "$($Prefix)AudioEndpointClass.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SYSTEM\CurrentControlSet\Control\DeviceClasses\{2EEF81BE-33FA-4800-9670-1CD474972C3F}', "$($Prefix)DeviceInterfaceAudioCapture.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SYSTEM\CurrentControlSet\Control\DeviceClasses\{6994AD04-93EF-11D0-A3CC-00A0C9223196}', "$($Prefix)MediaDeviceTopography.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SYSTEM\CurrentControlSet\Control\DeviceClasses\{E6327CAD-DCEC-4949-AE8A-991E976A79D2}', "$($Prefix)DeviceInterfaceAudioRender.xml"),
		([Microsoft.Win32.RegistryHive]::LocalMachine, 'SYSTEM\CurrentControlSet\Services\ksthunk', "$($Prefix)ksthunk.xml")
	) | ForEach-Object {
		$hive = $_[0]
		$subkey = $_[1]
		$file = $_[2]
		LogInfo "[$LogPrefixAudioLogs] Dumping registry from $hive\$subkey."
		$xml = Get-RegKeyQueryXml -hive $hive -subkey $subkey
		$xml.Save("$file")
	}

	# Copy files
	LogInfo "[$LogPrefixAudioLogs] Getting Audio logs"
	FwCreateFolder $TempDir\SetupapiLogs
	FwCreateFolder $TempDir\WindowsSetupLogs
	FwCreateFolder $TempDir\PantherLogs
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$system32\winevt\logs\Application.evtx", "$($Prefix)Application.evtx"),
		@("$system32\winevt\logs\Microsoft-Windows-UserPnp%4DeviceInstall.evtx", "$($Prefix)Microsoft-Windows-UserPnp%4DeviceInstall.evtx"),
		@("$system32\winevt\logs\Microsoft-Windows-Kernel-PnP%4Configuration.evtx", "$($Prefix)Microsoft-Windows-Kernel-PnP%4Configuration.evtx"),
		@("$system32\winevt\logs\System.evtx", "$($Prefix)System.evtx"),
		@("$env:windir\INF\setupapi*.log", "$TempDir\SetupapiLogs\"),
		@("$env:windir\setup*.log", "$TempDir\WindowsSetupLogs\"),
		@("$env:windir\Panther\setup*.log", "$TempDir\PantherLogs\")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$True

	#robocopy $env:windir\SoftwareDistribution\Download $TempDir\UUP *.log *.xml /W:1 /R:1 /NP /LOG+:$RobocopyLog

	# Run command lines
	LogInfo "[$LogPrefixAudioLogs] Collecting additional audio info"
	@(
		('ddodiag', "$system32\ddodiag.exe", "-o `"$($Prefix)ddodiag.xml`""),
		('dispdiag', "$system32\dispdiag.exe", "-out `"$($Prefix)dispdiag.dat`""),
		('dxdiag (text)', "$system32\dxdiag.exe", "/t `"$($Prefix)dxdiag.txt`""),
		('dxdiag (XML)', "$system32\dxdiag.exe", "/x `"$($Prefix)dxdiag.xml`""),
		('pnputil', "$system32\pnputil.exe", "/export-pnpstate `"$($Prefix)pnpstate.pnp`" /force")
	) | ForEach-Object {
		LogInfo ("[$LogPrefixAudioLogs] $($_[0])")
		$proc = Start-Process $_[1] -ArgumentList $_[2] -NoNewWindow -PassThru
		$timeout = 60; # seconds
		$proc | Wait-Process -TimeoutSec $timeout -ErrorAction Ignore
		if (!$proc.HasExited) {
			LogInfo "[$LogPrefixAudioLogs] $($_[0]) took longer than $timeout seconds, skipping."
			taskkill /T /F /PID $proc.ID
		}
	}

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION AUDIOINFOFunc ####################

#################### FUNCTION APPCOMPATINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDAppCompatInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	# Section for App Compat Info  Only run if flag set
	# Exporting App Compat Info related registry keys
	$LogPrefixAppCompatInfo = 'AppCompatInfo'
	FwCreateFolder $TempDir\Appcompat
	LogInfo ("[$LogPrefixAppCompatInfo] Exporting registries.")
	$RegKeysAppCompatInfo = @(
		('HKCU:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$TempDir\Appcompat\reg_CurrentUser-AppCompatFlags.txt"),
		('HKCU:SOFTWARE', "$TempDir\Appcompat\reg_CurrentUser-Software.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$TempDir\Appcompat\reg_LocalMachine-AppCompatFlags.txt"),
		('HKLM:SOFTWARE\ODBC', "$TempDir\Appcompat\reg_ODBC-Drivers.txt"),
		('HKLM:SOFTWARE\WOW6432Node\ODBC', "$TempDir\Appcompat\reg_ODBC-WOW6432Node-Drivers.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Installer', "$TempDir\Appcompat\reg_WindowsInstaller.txt")
	)
	FwExportRegistry $LogPrefixAppCompatInfo $RegKeysAppCompatInfo -RealExport $true

	$CommandsAppCompatInfo = @(
		"REG SAVE HKLM\SOFTWARE $TempDir\Appcompat\reg_LocalMachine-Software.hiv /Y"
		"cmd /r dir /a /s /r `"C:\Program Files (x86)`"	| Out-File -Append $TempDir\Appcompat\dir_ProgramFiles_x86.txt"
		"cmd /r dir /a /s /r `"C:\Program Files`"		| Out-File -Append $TempDir\Appcompat\dir_ProgramFiles.txt"
		"cmd /r dir /a /s /r `"C:\Program Files (Arm)`"	| Out-File -Append $TempDir\Appcompat\dir_ProgramFiles_Arm.txt"
		"cmd /r dir /a /s /r $env:windir\fonts			| Out-File -Append $TempDir\Appcompat\dir_Fonts.txt"
		"xcopy.exe `"$env:windir\System32\Winevt\Logs\*compatibility*.evtx`" `"$TempDir\Appcompat`" /Y /H"
		"xcopy.exe `"$env:windir\System32\Winevt\Logs\*inventory*.evtx`" `"$TempDir\Appcompat`" /Y /H"
		"xcopy.exe `"$env:windir\System32\Winevt\Logs\*program-telemetry*.evtx`" `"$TempDir\Appcompat`" /Y /H"
		"cmd /r copy `"$env:windir\AppPatch\CompatAdmin.log`" `"$TempDir\Appcompat\Apppatch-CompatAdmin.log`" /Y"
		"cmd /r copy `"$env:windir\AppPatch64\CompatAdmin.log`" `"$TempDir\Appcompat\Apppatch64-CompatAdmin.log`" /Y"
	)
	RunCommands $LogPrefixAppCompatInfo $CommandsAppCompatInfo -ThrowException:$False -ShowMessage:$True

	# - Powershell for font info
	[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-File -FilePath "$TempDir\Appcompat\FontInfo1.txt"
	(New-Object System.Drawing.Text.InstalledFontCollection).Families | Out-File -Append -FilePath "$TempDir\Appcompat\FontInfo1.txt"
	Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'	| Out-File -FilePath "$TempDir\Appcompat\FontInfo2.txt"
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION APPCOMPATINFOFunc ####################

#################### FUNCTION WINDOWSUPDATEFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDWindowsUpdateInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	# SECTION - Windows Update
	# Put everything except ETL's in the main folder
	$LogPrefixWU = 'WU'
	LogInfo ("[$LogPrefixWU] Getting Windows Update info")
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:windir\windowsupdate.log", "$($Prefix)WindowsUpdate.log"),
		@("$env:windir\SoftwareDistribution\ReportingEvents.log", "$($Prefix)WindowsUpdate_ReportingEvents.log"),
		@("$env:LOCALAPPDATA\microsoft\windows\windowsupdate.log", "$($Prefix)WindowsUpdatePerUser.log"),
		@("$env:windir\windowsupdate (1).log", "$($Prefix)WindowsUpdate(1).log"),
		@("$env:windir\SoftwareDistribution\Plugins\7D5F3CBA-03DB-4BE5-B4B36DBED19A6833\TokenRetrieval.log", "$($Prefix)WindowsUpdate_TokenRetrieval.log"),
		@("$env:SystemDrive\WindowsUpdateVerbose.etl", "$($Prefix)WindowsUpdateVerbose.etl")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

	$CommandsWU = @(
		"cmd /r dir $env:windir\SoftwareDistribution /a /s /r		| Out-File -Append $($Prefix)WindowsUpdate_dir_softwaredistribution.txt"
		"bitsadmin /list /allusers /verbose							| Out-File -Append $($Prefix)bitsadmin.log"
		"SCHTASKS /query /v /TN \Microsoft\Windows\WindowsUpdate\ 	| Out-File -Append $($Prefix)WindowsUpdate_ScheduledTasks.log"
		"reg save HKLM\SOFTWARE\Microsoft\sih `"$($Prefix)reg_SIH.hiv`""
	)
	RunCommands $LogPrefixWU $CommandsWU -ThrowException:$False -ShowMessage:$True

	LogInfo ("[$LogPrefixWU] Export by querying registry keys.")
	# FwExportRegistry is using the /s (recursive) switch by default and appends to an existing file
	$RegKeysWU = @(
		('HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate', "$($Prefix)WindowsUpdate_reg_wupolicy.txt"),
		('HKLM:SOFTWARE\Microsoft\CloudManagedUpdate', "$($Prefix)WindowsUpdate_reg_CloudManagedUpdate.txt"),
		('HKLM:SOFTWARE\Microsoft\PolicyManager\current\device\Update', "$($Prefix)WindowsUpdate_reg_wupolicy-mdm.txt"),
		('HKLM:SOFTWARE\Microsoft\sih', "$($Prefix)reg_SIH.txt"),
		('HKLM:Software\microsoft\windows\currentversion\oobe', "$($Prefix)reg_oobe.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate', "$($Prefix)WindowsUpdate_reg_CurrentVersion_Windows.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Wosc\Client\Persistent\ClientState', "$($Prefix)WindowsUpdate_reg_Onesettings.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Update', "$($Prefix)WindowsUpdate_reg_CurrentVersion_Windows_NT.txt"),
		('HKLM:SOFTWARE\Microsoft\WindowsSelfHost\OneSettings', "$($Prefix)WindowsUpdate_reg_Onesettings.txt"),
		('HKLM:SOFTWARE\Microsoft\WindowsUpdate', "$($Prefix)WindowsUpdate_reg_wuhandlers.txt"),
		('HKLM:SOFTWARE\Microsoft\WufbDS', "$($Prefix)WindowsUpdate_reg_WufbDS.txt"),
		('HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate', "$($Prefix)WindowsUpdate_reg_peruser_wupolicy.txt")
	)
	FwExportRegistry $LogPrefixWU $RegKeysWU

	# UUP logs and action list xmls
	# robocopy $env:windir\SoftwareDistribution\Download $TempDir\UUP *.log *.xml /W:1 /R:1 /NP /LOG+:$RobocopyLog

	# WU ETLs for Win10+
	$_WUETLPATH = "$env:windir\Logs\WindowsUpdate"
	if (Test-Path $_WUETLPATH) {

		if ($FlushLogs) {
			LogInfo ("[$LogPrefixWU] Flushing USO/WU logs.")
			$CommandsFlushLogs = @(
				'Stop-Service -Name usosvc'
				'Stop-Service -Name wuauserv'
			)
			RunCommands $LogPrefixWU $CommandsFlushLogs -ThrowException:$False -ShowMessage:$True
		}

		$_WULOGS = "$env:windir\Logs\WindowsUpdate"
		if (Test-Path -Path $_WULOGS) {
			FwCreateFolder $TempDir\logs\WindowsUpdate
			LogInfo ("[$LogPrefixWU] Copying Windows Update ETLs.")
			$CommandsWULogs = @(
				"robocopy `"$_WULOGS`" `"$TempDir\logs\WindowsUpdate`" *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog /S /MAXAGE:30 | Out-Null"
			)
			RunCommands $LogPrefixWU $CommandsWULogs -ThrowException:$False -ShowMessage:$True
		}

		if ($_WIN10_1607) {
			LogInfo ("[$LogPrefixWU] Public symbol server: Trying to connect...")
			# temporarily save $ProgressPreference
			$OriginalProgressPreference = $Global:ProgressPreference
			$Global:ProgressPreference = 'SilentlyContinue'
			$pubsymsrvcon = Test-NetConnection -ComputerName $PublicSymSrv -CommonTCPPort HTTP -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
			# reset $ProgressPreference
			$Global:ProgressPreference = $OriginalProgressPreference

			if (($false -eq ($pubsymsrvcon).TcpTestSucceeded)) {
				LogWarn ("[$LogPrefixWU] Public symbol server: Connection failed.")
				@("Public symbol server: Wasn't able to connect to $PublicSymSrv.", 'Please convert ETL files from logs\WindowsUpdate instead.', 'Use a internet connected Windows Server 2016 to convert logs with Get-WindowsUpdateLog.', $Line, $pubsymsrvcon) | Out-File -FilePath ($Prefix + 'WindowsUpdateETL_PublicSymbolsFailed.log') -Append
			}
			# only run if public symbol server is reachable
			elseif ($true -eq ($pubsymsrvcon).TcpTestSucceeded) {
				LogInfo ("[$LogPrefixWU] Public symbol server: Connected.")
				@("Public symbol server: Successfully connected to $PublicSymSrv.", $Line, $pubsymsrvcon) | Out-File -FilePath ($Prefix + 'WindowsUpdateETL_PublicSymbolsConnected.log') -Append
				LogInfo ("[$LogPrefixWU] Converting Windows Update log.")
				LogInfo ("[$LogPrefixWU] tracerpt.exe retrieving public symbols for ETL conversion - this might take a while...") 'Cyan'
				# Suppress script output by using a job
				$WULogsJobLog = "$($Prefix)WindowsUpdateETL_Converted.log"
				$WULogsJob = Start-Job -ScriptBlock { Get-WindowsUpdateLog -Log $args } -ArgumentList $WULogsJobLog
				$WULogsJob | Wait-Job | Remove-Job
				#  robocopy "$env:SystemDrive\ $TempDir\$_WINDOWSUPDATE WindowsUpdateVerbose.etl" /W:1 /R:1 /NP /LOG+:$RobocopyLog
			}
		}
		elseif ($_WIN10_1607_OR_LATER) {
			LogInfo ("[$LogPrefixWU] Converting Windows Update log.")
			# Suppress script output by using a job
			$WULogsJobLog = "$($Prefix)WindowsUpdateETL_Converted.log"
			$WULogsJob = Start-Job -ScriptBlock { Get-WindowsUpdateLog -Log $args } -ArgumentList $WULogsJobLog
			$WULogsJob | Wait-Job | Remove-Job
		}
	}

	if ($_PS4ormore) {
		# Begin Windows Update file versions-----------------------------------
		LogInfo ("[$LogPrefixWU] Getting Windows Update file versions.")
		$binaries = @('wuaext.dll', 'wuapi.dll', 'wuaueng.dll', 'wucltux.dll', 'wudriver.dll', 'wups.dll', 'wups2.dll', 'wusettingsprovider.dll', 'wushareduxresources.dll', 'wuwebv.dll', 'wuapp.exe', 'wuauclt.exe', 'storewuauth.dll', 'wuuhext.dll', 'wuuhmobile.dll', 'wuau.dll', 'wuautoappupdate.dll')
		foreach ($file in $binaries) {
			if (Test-Path "$env:windir\system32\$file") {
				$version = (Get-Command "$env:windir\system32\$file").FileVersionInfo
				Write-Output "$file : $($version.FileMajorPart).$($version.FileMinorPart).$($version.FileBuildPart).$($version.FilePrivatePart)" | Out-File -FilePath ($Prefix + 'WindowsUpdate_FileVersions.txt') -Append
			}
		}

		$muis = @('wuapi.dll.mui', 'wuaueng.dll.mui', 'wucltux.dll.mui', 'wusettingsprovider.dll.mui', 'wushareduxresources.dll.mui')
		foreach ($file in $muis) {
			if (Test-Path "$env:windir\system32\en-US\$file") {
				$version = (Get-Command "$env:windir\system32\en-US\$file").FileVersionInfo
				Write-Output "$file : $($version.FileMajorPart).$($version.FileMinorPart).$($version.FileBuildPart).$($version.FilePrivatePart)" | Out-File -FilePath ($Prefix + 'WindowsUpdate_FileVersions.txt') -Append
			}
		}
		# End Windows Update file versions---------------------------------
	}

	# -------------------------------------------------------------
	# MUSE logs for Win10+
	if ($null -ne (Get-Service -Name usosvc -ErrorAction SilentlyContinue)) {
		$LogPrefixUSO = 'USO'
		if ($FlushLogs) {
			LogInfo ("[$LogPrefixUSO] Flushing USO logs.")
			$CommandsFlushLogs = @(
				'Stop-Service -Name usosvc'
			)
			RunCommands $LogPrefixUSO $CommandsFlushLogs -ThrowException:$False -ShowMessage:$True
		}

		$_OLDPROGRAMDATA = "$env:windir.old\ProgramData"
		FwCreateFolder $TempDir\MUSE
		if (Test-Path "$_OLDPROGRAMDATA\USOShared\Logs") { FwCreateFolder $TempDir\Windows.old }
		LogInfo ("[$LogPrefixUSO] Copying USO logs.")
		$CommandsUSO = @(
			"SCHTASKS /query /v /TN \Microsoft\Windows\UpdateOrchestrator\| Out-File -Append $TempDir\MUSE\UpdateOrchestratorTasks.txt"
		)
		if (Test-Path "$env:ProgramData\UsoPrivate\UpdateStore") { $CommandsUSO += @("robocopy `"$env:ProgramData\UsoPrivate\UpdateStore`" `"$TempDir\MUSE`" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null") }
		if (Test-Path "$env:ProgramData\USOShared\Logs") { $CommandsUSO += @("robocopy `"$env:ProgramData\USOShared\Logs`" `"$TempDir\MUSE`" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null") }
		if (Test-Path "$_OLDPROGRAMDATA\USOPrivate\UpdateStore") { $CommandsUSO += @("robocopy `"$_OLDPROGRAMDATA\USOPrivate\UpdateStore`" `"$TempDir\Windows.old\MUSE`" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null") }
		if (Test-Path "$_OLDPROGRAMDATA\USOShared\Logs") { $CommandsUSO += @("robocopy `"$_OLDPROGRAMDATA\USOShared\Logs`" `"$TempDir\Windows.old\MUSE`" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null") }
		RunCommands $LogPrefixUSO $CommandsUSO -ThrowException:$False -ShowMessage:$True

		# Begin Undocked Update Stack file versions-----------------------------------
		if ($_WIN11_OR_LATER) {
			LogInfo ("[$LogPrefixUSO] Getting UUS file versions.")
			$currentDir = Split-Path $TempDir -Leaf
			FwExportFileVerToCsv 'uus' 'DLL', 'EXE', 'MUI' -Subfolder "$currentDir"
		}
		# End Undocked Update Stack file versions----------------------------------
	}
	# Also copying ETLs pre-upgrade to see history
	$_OLDLOCALAPPDATA = $env:LOCALAPPDATA -replace '^.{2}', "$env:windir.old"
	$_WUOLDETLPATH = "$env:windir.old\Windows\Logs\WindowsUpdate"
	if (Test-Path -Path $_WUOLDETLPATH) {
		$LogPrefixWUOld = 'WUOld'
		LogInfo ("[$LogPrefixWUOld] Copying ETLs pre-upgrade.")
		$CommandsWUOld = @(
			"robocopy `"$_WUOLDETLPATH`" `"$TempDir\Windows.old\WU`" *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null",
			"cmd /r copy `"$env:windir.old\Windows\windowsupdate.log`" `"$TempDir\Windows.old\WindowsUpdate.log`" /Y",
			"cmd /r copy `"$env:windir.old\Windows\SoftwareDistribution\ReportingEvents.log`" `"$TempDir\Windows.old\ReportingEvents.log`" /Y",
			"cmd /r copy `"$_OLDLOCALAPPDATA\microsoft\windows\windowsupdate.log`" `"$TempDir\Windows.old\WindowsUpdatePerUser.log`" /Y"
		)
		RunCommands $LogPrefixWUOld $CommandsWUOld -ThrowException:$False -ShowMessage:$True
	}

	# Trying to retrieve CTAC attributes
	# AnalyticsInfo.GetSystemPropertiesAsync(IIterable<String>) Method, Windows requirements Windows 10, version 1803 (introduced in 10.0.17134.0)
	# https://learn.microsoft.com/en-us/uwp/api/windows.system.profile.analyticsinfo.getsystempropertiesasync?view=winrt-22621
	if ($_WIN10_1809_OR_LATER) {
		try {
			<#	Async helper from https://fleexlab.blogspot.com/2018/02/using-winrts-iasyncoperation-in.html
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
			$results | ForEach-Object { Write-Output "$($_.Key)=$($_.Value)" } | Out-File -FilePath ($Prefix + 'WindowsUpdate_CTAC.txt') -Append
		}
		catch { LogException ("[$LogPrefixWU] Common Targeting Attribute Client failed to retrieve attributes.") $_ }

		# Retrieve
		try {
			LogInfo ("[$LogPrefixWU] Retrieve installed updates from Win32_QuickFixEngineering class.")
			@($Line, 'This file contains the output from WMI class "win32_quickfixengineering"', $Line) | Out-File -FilePath ($Prefix + 'WindowsUpdate_Hotfixes.txt')
			Get-CimInstance -ClassName win32_quickfixengineering | Out-File -FilePath "$($Prefix)WindowsUpdate_Hotfixes.txt " -Append
			# Get update id list with wmic, replaced
			# wmic qfe list full /format:texttable >> ($Prefix+"Hotfix-WMIC.txt") 2>> $ErrorFile
		}
		catch { LogException ("[$LogPrefixWU] Failed to retrieve installed Updates from Win32_QuickFixEngineering class.") $_ }
	}

	# Determine the .NET Framework security updates and hotfixes that are installed
	# https://learn.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-net-framework-updates-are-installed#use-powershell-to-query-the-registry
	try {
		LogInfo ("[$LogPrefixWU] Determine .NET Framework security updates and hotfixes.")
		$DotNetVersions = Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Updates | Where-Object { $_.name -like '*.NET Framework*' }

		ForEach ($Version in $DotNetVersions) {
			$Updates = Get-ChildItem $Version.PSPath
			$Version.PSChildName | Out-File -Append "$($Prefix)WindowsUpdate_.NET_Hotfixes.txt"
			ForEach ($Update in $Updates) {
				$Update.PSChildName | Out-File -Append "$($Prefix)WindowsUpdate_.NET_Hotfixes.txt"
			}
		}
	}
	catch { LogException ("[$LogPrefixWU] Encountered an error while determining .NET Framework security updates and hotfixes.") $_ }

	# check if wuauserv is disabled to prevent exception during log collection
	if ((Get-Service wuauserv).StartType -ne [System.ServiceProcess.ServiceStartMode]::Disabled) {
		try {
			$Session = New-Object -ComObject 'Microsoft.Update.Session'
			$Searcher = $Session.CreateUpdateSearcher()
			$historyCount = $Searcher.GetTotalHistoryCount()
			if ($historyCount -gt 0) {
				# Get Windows Update History info - Summary First
				LogInfo ("[$LogPrefixWU] Getting Update History - summary.")
				@($Line, 'This file contains the summary output of Windows Update history and full output of Windows Update history', $Line, 'Windows Update history Summary', 'Operation 1=Installation 2=Uninstallation 3=Other', $Line) | Out-File -FilePath ($Prefix + 'WindowsUpdate_Database.txt') -Append
				$null = $Searcher.QueryHistory(0, $historyCount) | Select-Object Date, Operation, Title | Out-File ($Prefix + 'WindowsUpdate_Database.txt') -Append
				# Get Windows Update History Info - All fields
				LogInfo ("[$LogPrefixWU] Getting Update History - all.")
				@("`n", $Line, 'Get all fields in Windows Update database', $Line ) | Out-File -FilePath ($Prefix + 'WindowsUpdate_Database.txt') -Append
				$null = $Searcher.QueryHistory(0, $historyCount) | Select-Object -Property *, @{Name = 'UpdateIdentityGUID'; Expression = { $_.UpdateIdentity.UpdateID } }, @{Name = 'CategoryName'; Expression = { $_.categories | Select-Object -First 1 -ExpandProperty Name } } -ExcludeProperty UpdateIdentity, Categories, UninstallationSteps, UninstallationNotes | Out-File -FilePath ($Prefix + 'WindowsUpdate_Database.txt') -Append
			}
			# Get Windows Update Configuration info
			LogInfo ("[$LogPrefixWU] Getting configuration info.")
			$MUSM = New-Object -ComObject 'Microsoft.Update.ServiceManager'
			$MUSM.Services | Select-Object Name, IsDefaultAUService, OffersWindowsUpdates | Out-File -FilePath ($Prefix + 'WindowsUpdateConfiguration.txt') 2>> $ErrorFile
			Write-Output $Line | Out-File -FilePath ($Prefix + 'WindowsUpdateConfiguration.txt') -Append
			Write-Output '		 Now get all data' | Out-File -FilePath ($Prefix + 'WindowsUpdateConfiguration.txt') -Append
			Write-Output $Line | Out-File -FilePath ($Prefix + 'WindowsUpdateConfiguration.txt') -Append
			$MUSM = New-Object -ComObject 'Microsoft.Update.ServiceManager'
			$MUSM.Services | Select-Object * -ExcludeProperty RedirectUrls | Out-File -FilePath ($Prefix + 'WindowsUpdateConfiguration.txt') -Append 2>> $ErrorFile
		}
		catch { LogException ("[$LogPrefixWU] Getting Update History - summary failed.") $_ }
	}
	else {
		LogInfo ("[$LogPrefixWU] Getting Update History - skipped (wuauserv disabled).")
		Write-Output 'Windows Update history Summary' | Out-File -FilePath ($Prefix + 'WindowsUpdate_Database.txt') -Append
		Write-Output 'Skipped, because service wuauserv is disabled.' | Out-File -FilePath ($Prefix + 'WindowsUpdate_Database_SKIPPED.txt') -Append

		LogInfo ("[$LogPrefixWU] Getting configuration info - skipped (wuauserv disabled).")
		Write-Output 'Skipped, because service wuauserv is disabled.' | Out-File -FilePath ($Prefix + 'WindowsUpdateConfiguration_SKIPPED.txt') -Append
	}

	# https://techcommunity.microsoft.com/t5/windows-it-pro-blog/troubleshooting-expedited-updates/ba-p/2595615
	$_WUHEALTHLOGS = "$env:ProgramFiles\Microsoft Update Health Tools\Logs"
	if (Test-Path -Path $_WUHEALTHLOGS) {
		$LogPrefixWUHealth = 'WUHealth'
		FwCreateFolder $TempDir\logs\WindowsUpdateHealthTools
		LogInfo ("[$LogPrefixWUHealth] Copying Microsoft Update Health Tools ETLs.")
		$CommandsWUHealth = @(
			"robocopy `"$_WUHEALTHLOGS`" `"$TempDir\logs\WindowsUpdateHealthTools`" *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog /S /MAXAGE:30 | Out-Null"
		)
		RunCommands $LogPrefixWUHealth $CommandsWUHealth -ThrowException:$False -ShowMessage:$True
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WINDOWSUPDATEFunc ####################

#################### FUNCTION DATASTOREFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDatastore {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixWU = 'WU'
	FwCreateFolder $TempDir\datastore
	LogInfo ("[$LogPrefixWU] Copying datastore.")
	$CommandsDatastore = @(
		'Stop-Service -Name wuauserv'
		"xcopy.exe `"$env:windir\softwaredistribution\datastore\*.*`" `"$TempDir\datastore`" /Y /H"
	)
	RunCommands $LogPrefixWU $CommandsDatastore -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DATASTOREFunc ####################

#################### FUNCTION FILEVERSIONINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDGeneralFileVersionInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# Calling FwGetMsInfo32 without passing a format will create both, the NFO and the TXTfile.
	# Don't forget to call FwWaitForProcess for both processes, $global:msinfo32NFO and $global:msinfo32TXT
	FwGetMsInfo32 -Subfolder "Setup_Report$LogSuffix"
	FwGetWhoAmI -Subfolder "Setup_Report$LogSuffix"
	FwGetSysInfo -Subfolder "Setup_Report$LogSuffix"

	$global:GPresultHTM = Start-Process -FilePath 'gpresult' -ArgumentList "/H $($Prefix)GPResult.htm" -PassThru

	# SECTION for general file version info
	LogInfo '[GeneralInfo] Getting general file version info. Please be patient... ' 'cyan'
	FwFileVersion -Filepath ("$env:windir\system32\wbem\wbemcore.dll") | Out-File -FilePath ($Prefix + 'FilesVersion.csv') -Append
	FwExportFileVerToCsv 'system32' 'DLL', 'EXE', 'SYS' -Subfolder "Setup_Report$LogSuffix"
	# Now get syswow64 files if on 64bit Windows
	if (Test-Path "$env:windir\syswow64\comctl32.dll") {
		FwExportFileVerToCsv 'SysWOW64' 'DLL', 'EXE', 'SYS' -Subfolder "Setup_Report$LogSuffix"
	}
	#FwWaitForProcess $global:msinfo32NFO 300

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION FILEVERSIONINFOFunc ####################


#################### FUNCTION WINSXSINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDWinSxSVersionInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo '[FwExportFileVerToCsv] Getting general fileversion info. Please be patient... ' 'cyan'
	FwExportFileVerToCsv 'WinSxS' 'DLL', 'EXE', 'SYS' -Subfolder "Setup_Report$LogSuffix"
	FwExportFileVerToCsv 'Microsoft.NET' 'DLL' -Subfolder "Setup_Report$LogSuffix"
	# Begin Reference Assemblies DLL File Versions-----------------------------------
	#FwExportFileVerToCsv "$env:programfiles\Reference Assemblies" "DLL" -Subfolder "Setup_Report$LogSuffix"
	LogInfo ("[$LogPrefixWinSxS] Getting Reference Assemblies files version info.")
	Get-ChildItem -Path "$env:programfiles\Reference Assemblies" -Filter *.dll -Recurse -ea 0 | ForEach-Object {
		[pscustomobject]@{
			Name            = $_.FullName
			Version         = $_.VersionInfo.FileVersion
			DateModified    = $_.LastWriteTime
			Length          = $_.length
			CompanyName     = $_.VersionInfo.CompanyName
			FileDescription = $_.VersionInfo.FileDescription
		}
	} | Export-Csv -NoTypeInformation -Path ($Prefix + 'File_Versions_Reference_Assemblies.csv') 2>> $ErrorFile
	# End Reference Assemblies DLL File Versions--------------------------------
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WINSXSINFOFunc ####################

#################### FUNCTION CBSPNPINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDCbsPnpInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# SECTION CBS & PNP info, components hive, SideBySide hive, Iemain.log
	$LogPrefixCBS = 'CBS'
	LogInfo ("[$LogPrefixCBS] Getting CBS and servicing info.")


	try {
		LogInfo "[$LogPrefixCBS] waiting max 50 sec to succeed on copy $env:windir\system32\config\components" 'Gray'
		$StopWait = $False
		$attempt = 0
		While (($StopWait -eq $False) -and ($attempt -lt 10)) {
			$attempt += 1
			$Result = (cmd /r copy "$env:windir\system32\config\components" "$($Prefix)reg_Components.hiv" 2>&1)
			if ($Result -match '1 file') { $StopWait = $True; LogInfo "[$LogPrefixCBS] - Result: $Result (@attempt=$attempt)" 'Green' } else { $StopWait = $False ; LogErrorFile "[$LogPrefixCBS] waiting +5 sec  - Result: $Result (@attempt=$attempt)"; Start-Sleep -Milliseconds 5000 }
		}
		if ($Result -match '0 file') { LogInfo "[$LogPrefixCBS] - Result: $Result (@attempt=$attempt) - copy $env:windir\system32\config\components FAILED after $attempt attempts" 'Magenta' }
	}
	catch { LogException ("[$LogPrefixCBS] copying $env:windir\system32\config\components failed") $_ }

	# Copy logs
	LogInfo "[$LogPrefixCBS] Getting servicing related logs and output from DISM commands."
	$CommandsCBS = @(
		"robocopy `"$env:windir\logs`" `"$TempDir\logs`" /W:1 /R:1 /NP /E /XD PowerShell /LOG+:$RobocopyLog /S | Out-Null"
		"robocopy `"$env:windir\System32\LogFiles\setupcln`" `"$TempDir\System32-Logfiles\setupcln`" /W:1 /R:1 /NP /E /LOG+:$RobocopyLog /S | Out-Null"
		"robocopy `"$env:windir\System32\LogFiles\wmi`" `"$TempDir\System32-Logfiles\wmi`" /W:1 /R:1 /NP /E /LOG+:$RobocopyLog /S | Out-Null"
		"robocopy `"$env:windir\System32\WDI\LogFiles`" `"$TempDir\System32-Logfiles\WDI\LogFiles`" /W:1 /R:1 /NP /E /LOG+:$RobocopyLog /S | Out-Null"
		#		"xcopy `"$env:windir\servicing\sessions\*.*`" `"$TempDir\logs\cbs\Sessions`" /y /h"
		"dism /english /online /Get-TargetEditions				| Out-File -Append $($Prefix)dism_EditionInfo.txt"
		"cmd /r dir `"$env:windir\WinSxS\temp`" /s /a /r		| Out-File -Append $($Prefix)dir_WinSxSTEMP.txt"
		"cmd /r dir `"$env:windir\WinSxS`" /s /a /r				| Out-File -Append $($Prefix)dir_WinSxS.txt"
		"cmd /r dir `"$env:windir\servicing\*.*`" /s /a /r		| Out-File -Append $($Prefix)dir_servicing.txt"
		"cmd /r dir `"$env:windir\system32\dism\*.*`" /s /a /r	| Out-File -Append $($Prefix)dir_dism.txt"
		"dism /english /online /Get-Packages /Format:Table		| Out-File -Append $($Prefix)dism_GetPackages.txt"
		"dism /english /online /Get-Packages					| Out-File -Append $($Prefix)dism_GetPackages.txt"
		"dism /english /online /Cleanup-Image /CheckHealth		| Out-File -Append $($Prefix)dism_CheckHealth.txt"
		"dism /english /online /Get-Features /Format:Table		| Out-File -Append $($Prefix)dism_GetFeatures.txt"
		"dism /english /online /Get-Intl						| Out-File -Append $($Prefix)dism_GetInternationalSettings.txt"
		"dism /english /online /Get-Capabilities /Format:Table	| Out-File -Append $($Prefix)dism_GetCapabilities.txt"
		"dism /english /online /Get-CurrentEdition				| Out-File -Append $($Prefix)dism_EditionInfo.txt"
		"dism /english /online /get-drivers /Format:Table		| Out-File -Append $($Prefix)dism_3rdPartyDrivers.txt"
		"Get-CimInstance Win32_PnPEntity						| Out-File -Append $($Prefix)drivers_WMIQuery.txt"
		#		"cmd /r copy `"$env:windir\system32\config\components`" `"$($Prefix)reg_Components.hiv`""
	)
	RunCommands $LogPrefixCBS $CommandsCBS -ThrowException:$False -ShowMessage:$True

	LogInfo "[$LogPrefixCBS] Getting setupapi logs and servicing sessions."
	FwCreateFolder $TempDir\logs\CBS\sessions
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:windir\iemain.log", "$TempDir"),
		@("$env:windir\inf\*.log", "$TempDir\logs\cbs"),
		@("$env:windir\WinSxS\poqexec.log", "$TempDir\logs\cbs"),
		@("$env:windir\WinSxS\pending.xml", "$TempDir\logs\cbs"),
		@("$env:windir\servicing\sessions\*.xml", "$TempDir\logs\cbs\sessions"),
		@("$env:windir\Logs\MoSetup\UpdateAgent.log", "$TempDir\logs\cbs"),
		@("$env:windir\temp\lpksetup.log", "$TempDir\logs\cbs\lpksetup.log")
		#@("$env:windir\system32\config\components", "$($Prefix)reg_Components.hiv")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

	# Powershell way Get-CimInstance Win32_OptionalFeature | Foreach {Write-host( "Name:{0}, InstallState:{1}" -f $_.Name,($_.InstallState -replace 1, "Installed" -replace 2, "Disabled" -replace 3, "Absent"))}

	LogInfo ("[$LogPrefixCBS] Getting packages info.")
	dism /english /online /Get-Packages | ForEach-Object {
		if ( $_ -match 'Package Identity') {
			$DismPackage = $_.substring(19)
			dism /english /online /get-packageinfo /packagename:$DismPackage
		}
	} | Out-File -FilePath ($Prefix + 'dism_GetPackages.txt') -Append 2>> $ErrorFile
	LogDebug "[$LogPrefixCBS] done Getting packages info "

	# Dump out any servicing packages not in current state of 80 (superseded) or 112 (Installed)
	# Build header for output file
	LogInfo ("[$LogPrefixCBS] Getting CBS packages status.")
	Write-Output 'CBS servicing states, as seen on https://docs.microsoft.com/en-us/archive/blogs/tip_of_the_day/tip-of-the-day-cbs-servicing-states-chart-refresher'	| Out-File -FilePath ($Prefix + 'Servicing_PackageState.txt')
	Write-Output 'This will list any packages not in a state of 80 (superseded) or 112 (Installed)' | Out-File -FilePath ($Prefix + 'Servicing_PackageState.txt') -Append
	Write-Output 'If blank then none were found' | Out-File -FilePath ($Prefix + 'Servicing_PackageState.txt') -Append
	Write-Output $Line | Out-File -FilePath ($Prefix + 'Servicing_PackageState.txt') -Append
	# Build PS script
	$regPATH = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
	$brokenUpdates = Get-ChildItem -Path $regPATH -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Rollup|ServicingStack' } #matches any Cumulative Update or Monthly Rollup
	$brokenUpdates | Get-ItemProperty | Where-Object { $_.CurrentState -ne '80' -and $_.CurrentState -ne '112' } | Select-Object @{N = 'Cumulative/rollup package(s) in broken state'; E = { $_.PSChildName }; } | Format-Table -Wrap -AutoSize	| Out-File -FilePath ($Prefix + 'Servicing_PackageState.txt') -Append
	$brokenUpdates = Get-ChildItem -Path $regPATH -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Package_for_KB[0-9]{7}~31bf3856ad364e35' } #matches any standalone KBs
	$brokenUpdates | Get-ItemProperty | Where-Object { $_.CurrentState -ne '80' -and $_.CurrentState -ne '112' } | Select-Object @{N = 'Standalone package(s) in broken state'; E = { $_.PSChildName }; } | Format-Table -Wrap -AutoSize | Out-File -FilePath ($Prefix + 'Servicing_PackageState.txt') -Append

	# ----------------------------------------------------------------------
	# Now do a converted poqexec if it exist
	try {
		if (Test-Path "$TempDir\logs\cbs\poqexec.log") {
			LogInfo ("[$LogPrefixCBS] Collecting poqexec info.")
			$OutputFile = "$TempDir\logs\CBS\poqexec_Converted.log"
			Set-Content -Path $OutputFile -Value 'poqexec.log with FileTime converted to Date and Time'
			Add-Content -Path $OutputFile -Value ''
			Add-Content -Path $OutputFile -Value 'Date       Time     Entry'
			$poqexeclog = "$TempDir\logs\CBS\poqexec.log"
			$ProcessingData = Get-Content $poqexeclog
			$ProcessingData | ForEach-Object {
				$ProcessingLine = $_
				$DateString = $ProcessingLine.substring(0, 15)
				# Check if the extracted string is in Int64 date format (16-character hexadecimal string)
				if ($DateString -match '^[0-9a-fA-F]{15}$') {
					[Int64]$FileTime = '0x' + $DateString
					$ConvertedDate = [DateTime]::FromFileTime($FileTime)
					Add-Content -Path $OutputFile -Value "$ConvertedDate`t$ProcessingLine"
				}
				else {
					# Output the line as is since the first 0-15 characters are not in Int64 date format
					Add-Content -Path $OutputFile -Value $ProcessingLine
				}
			}
		}
	}
 catch { LogException ("[$LogPrefixCBS] Convert poqexec.log failed.") $_ }

	if ($_Win10) {
		$LogPrefixPnpState = 'PNP'
		LogInfo ("[$LogPrefixPnpState] Getting PNP info.")
		$CommandsPNP = @(
			"pnputil.exe /export-pnpstate `"$($Prefix)drivers_pnpstate.pnp`""
			"driverquery /si | Out-File -Append $($Prefix)Driver_signing.txt"
		)
		RunCommands $LogPrefixPnpState $CommandsPNP -ThrowException:$False -ShowMessage:$True

		LogInfo ("[$LogPrefixPnpState] Export by querying registry keys.")
		$RegKeysCbsPnpInfo = @(
			('HKLM:SYSTEM\HardwareConfig\Current\ComputerIds')
		)
		FwExportRegToOneFile $LogPrefixPnpState $RegKeysCbsPnpInfo "$($Prefix)reg_ComputerIds_CHIDs.txt"
	}



	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION CBSPNPINFOFunc ####################

#################### FUNCTION STOREINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDStoreInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# Section Windows Store info
	# Only run if Appx Server exist
	if (Test-Path "$env:SystemRoot\system32\appxdeploymentserver.dll") {
		$_WINSTORE = 'Winstore'
		$LogPrefixTWS = 'TWS'
		FwCreateFolder $TempDir\$_WINSTORE
		LogInfo ("[$LogPrefixTWS] Getting Windows Store/Appx data.")
		$RegKeysTWS = @(
			('HKLM:SOFTWARE\Policies\Microsoft\WindowsStore', "$TempDir\$_WINSTORE\reg_StorePolicy.txt"),
			('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Appx', "$TempDir\$_WINSTORE\reg_appx.txt"),
			('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\InstallService\State', "$TempDir\$_WINSTORE\reg_InstallServiceState.txt")
		)
		FwExportRegistry $LogPrefixTWS $RegKeysTWS -RealExport $true
		#"REG SAVE HKLM\SOFTWARE $TempDir\Appcompat\reg_LocalMachine-Software.hiv /Y"
		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths = @(
			@("$env:TEMP\winstore.log", "$TempDir\$_WINSTORE\winstore-Broker.log"),
			@("$env:USERPROFILE\AppData\Local\Packages\WinStore_cw5n1h2txyewy\AC\Temp\winstore.log", "$TempDir\$_WINSTORE")
		)
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
		LogInfo ("[$LogPrefixTWS] Running  Get-AppxPackage.")
		try { Import-Module appx; Get-AppxPackage -AllUsers	| Out-File -FilePath "$TempDir\$_WINSTORE\GetAppxPackage.txt" }
		catch { LogException ('Get-AppxPackage failed.') $_ }
		if ($_WINBLUE_OR_LATER) {
			try { Get-AppxPackage -packagetype bundle | Out-File -FilePath "$TempDir\$_WINSTORE\GetAppxPackageBundle.txt" }
			catch { LogException ('Get-AppxPackage failed.') $_ }
			dism /english /online /Get-ProvisionedAppxPackages > "$TempDir\$_WINSTORE\Dism_GetAppxProvisioned.txt" 2>> $ErrorFile
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION STOREINFOFunc ####################

#################### FUNCTION DOLOGSFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDoLogs {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# Section Delivery Optimizaton logs and powershell for Win10+
	$LogPrefixDO = 'DOSVC'
	if ($null -ne (Get-Service -Name dosvc -ErrorAction SilentlyContinue)) {
		if ($FlushLogs) {
			LogInfo ("[$LogPrefixDO] Flushing DO/USO/WU logs.")
			$CommandsFlushLogs = @(
				'Stop-Service -Name dosvc'
				'Stop-Service -Name usosvc'
				'Stop-Service -Name wuauserv'
			)
			RunCommands $LogPrefixDO $CommandsFlushLogs -ThrowException:$False -ShowMessage:$True
		}
		FwCreateFolder $TempDir\DOSVC
		LogInfo ("[$LogPrefixDO] Getting DeliveryOptimization logs.")
		$CommandsDOSVC = @(
			"robocopy `"$env:windir\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Logs`" `"$TempDir\dosvc`" *.log *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null"
			"robocopy `"$env:windir\SoftwareDistribution\DeliveryOptimization\SavedLogs`" `"$TempDir\dosvc`" *.log *.etl /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null"
		)
		RunCommands $LogPrefixDO $CommandsDOSVC -ThrowException:$False -ShowMessage:$True

		LogInfo ("[$LogPrefixDO] Getting DeliveryOptimization registry.")
		$RegKeysDOSVC = @(
			('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization')
			('HKLM:SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization')
			('HKLM:SOFTWARE\Microsoft\PolicyManager\current\device\DeliveryOptimization')
			#('HKLM:SOFTWARE\Microsoft\PolicyManager\default\DeliveryOptimization')
		)
		FwExportRegToOneFile $LogPrefixDO $RegKeysDOSVC "$TempDir\dosvc\DeliveryOptimization_reg.txt"

		LogInfo ("[$LogPrefixDO] Getting DeliveryOptimization perf data.")
		$outfile = "$TempDir\dosvc\DeliveryOptimization_info.txt"
		Write-Output "Use 'Get-DeliveryOptimizationLogAnalysis -Path .\dosvc.*.etl -Verbose' to analyse ETLs" | Out-File -FilePath $outfile -Append
		Write-Output $Line | Out-File -FilePath $outfile -Append
		$Commands = @(
			"Get-DOConfig									| Out-File -Append $outfile"
			"Get-DeliveryOptimizationPerfSnap				| Out-File -Append $outfile"
			"Get-DeliveryOptimizationPerfSnapThisMonth		| Out-File -Append $outfile"
			"Get-DeliveryOptimizationStatus					| Out-File -Append $outfile"
			"Get-DeliveryOptimizationStatus -PeerInfo		| Out-File -Append $outfile"
		)
		RunCommands $LogPrefixDO $Commands -ThrowException:$False -ShowMessage:$True
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DOLOGSFunc ####################


#################### FUNCTION SETUPLOGSFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDSetupLogs {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixSetup = 'Setup'
	$LogPrefixUpgrade = 'IPU'
	$LogPrefixPBR = 'PBR'
	FwCreateFolder $TempDir\UpgradeSetup
	if (Test-Path "$env:windir\Panther") { FwCreateFolder $TempDir\UpgradeSetup\win_Panther }
	if (Test-Path "$env:windir\system32\sysprep\panther") { FwCreateFolder $TempDir\UpgradeSetup\sysprep_Panther }
	if (Test-Path "$env:windir\setup\") { FwCreateFolder $TempDir\UpgradeSetup\win_Setup }

	LogInfo ("[$LogPrefixSetup] Copying Windows Setup / Feature Update logs.")
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:windir\logs\mosetup\bluebox.log", "$TempDir\UpgradeSetup\"),
		@("$env:windir.old\windows\logs\mosetup\bluebox.log", "$TempDir\UpgradeSetup\bluebox_windowsold.log"),
		@("$env:windir.old\windows\logs\mosetup\UpdateAgent.log", "$TempDir\UpgradeSetup\UpdateAgent_windowsold.log"),
		@("$env:windir\Panther\*", "$TempDir\UpgradeSetup\win_Panther"),
		@("$env:windir\system32\sysprep\panther\*", "$TempDir\UpgradeSetup\sysprep_Panther"),
		@("$env:windir\setup\*", "$TempDir\UpgradeSetup\win_Setup"),
		@("$env:windir\setupact.log", "$TempDir\UpgradeSetup\setupact-windows.log"),
		@("$env:windir\System32\LogFiles\SCM\*.EVM*", "$TempDir\UpgradeSetup\"),
		@("$env:windir\System32\LogFiles\setupcln\setupact.log", "$TempDir\UpgradeSetup\setupact-setupcln.log")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

	"$env:SystemDrive", 'D:' | ForEach-Object {
		if (Test-Path "$_\`$Windows.~BT") {
			LogInfo ("[$LogPrefixUpgrade] Found `"$_\`$Windows.~BT`".")
			if (Test-Path "$_\`$Windows.~BT\Sources\Panther") {
				$BT_PANTHER = [int]1
				FwCreateFolder $TempDir\UpgradeSetup\~bt_Panther
			}
			if (Test-Path "$_\`$Windows.~BT\Sources\Rollback") {
				$BT_ROLLBACK = [int]1
				FwCreateFolder $TempDir\UpgradeSetup\~bt_Rollback
			}
			LogInfo ("[$LogPrefixUpgrade] Copying Feature Update logs.")

			$CommandsUpgrade = @(
				#"robocopy `'$env:SystemDrive\`$Windows.~BT\Sources\Panther`' `"$TempDir\UpgradeSetup\~bt_Panther`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null"
				#"robocopy `'$env:SystemDrive\`$Windows.~BT\Sources\Rollback`' `"$TempDir\UpgradeSetup\~bt_Rollback`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null"
				"cmd /r dir /a /s /r '$_\`$Windows.~BT`' | Out-File -Append $TempDir\UpgradeSetup\Dir_WindowsBT.txt"
				"robocopy.exe `"$env:windir\system32\security\logs`" `"$TempDir\security`" /W:1 /R:1 /NP /E /LOG+:$RobocopyLog /S | Out-Null"
			)
			if ($BT_PANTHER) { $CommandsUpgrade += @("robocopy `'$_\`$Windows.~BT\Sources\Panther`' `"$TempDir\UpgradeSetup\~bt_Panther`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null") }
			if ($BT_ROLLBACK) { $CommandsUpgrade += @("robocopy `'$_\`$Windows.~BT\Sources\Rollback`' `"$TempDir\UpgradeSetup\~bt_Rollback`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null") }
			RunCommands $LogPrefixUpgrade $CommandsUpgrade -ThrowException:$False -ShowMessage:$True
		}

		if (Test-Path "$_\`$Windows.~WS") {
			LogInfo ("[$LogPrefixUpgrade] Found `"$_\`$Windows.~WS`".")
			if (Test-Path "$_\`$Windows.~WS\Sources\Panther") {
				$WS_PANTHER = [int]1
				FwCreateFolder $TempDir\UpgradeSetup\~ws_Panther
			}
			if (Test-Path "$_\`$Windows.~Sw\Sources\Rollback") {
				$WS_ROLLBACK = [int]1
				FwCreateFolder $TempDir\UpgradeSetup\~ws_Panther
			}
			LogInfo ("[$LogPrefixUpgrade] Copying Feature Update logs.")

			$CommandsUpgrade = @(
				#"xcopy /s /e /c `"$env:SystemDrive\`$Windows.~WS\Sources\Panther\*.*`" `"$TempDir\UpgradeSetup\~ws_Panther`" /y"
				#"xcopy /s /e /c `"$env:SystemDrive\`$Windows.~WS\Sources\Rollback\*.*`" `"$TempDir\UpgradeSetup\~ws_Rollback`" /y"
				"robocopy `'$env:SystemDrive\`$Windows.~WS\Sources\Panther`' `"$TempDir\UpgradeSetup\~ws_Panther`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null"
				"robocopy `'$env:SystemDrive\`$Windows.~WS\Sources\Rollback`' `"$TempDir\UpgradeSetup\~ws_Rollback`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null"
				"cmd /r dir /a /s /r '$_\`$Windows.~WS`' | Out-File -Append $TempDir\UpgradeSetup\Dir_WindowsWS.txt"
				"robocopy.exe `"$env:windir\system32\security\logs`" `"$TempDir\security`" /W:1 /R:1 /NP /E /LOG+:$RobocopyLog /S | Out-Null"
			)
			if ($WS_PANTHER) { $CommandsUpgrade += @("robocopy `'$_\`$Windows.~WS\Sources\Panther`' `"$TempDir\UpgradeSetup\~ws_Panther`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null") }
			if ($WS_ROLLBACK) { $CommandsUpgrade += @("robocopy `'$_\`$Windows.~WS\Sources\Rollback`' `"$TempDir\UpgradeSetup\~ws_Rollback`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S | Out-Null") }
			RunCommands $LogPrefixUpgrade $CommandsUpgrade -ThrowException:$False -ShowMessage:$True
		}
	}

	if (Test-Path "$env:USERPROFILE\Local Settings\Application Data\Microsoft\WebSetup\Panther") {
		$LogPrefixWebSetup = 'WebSetup'
		FwCreateFolder $TempDir\UpgradeSetup\WebSetup-Panther
		LogInfo ("[$LogPrefixWebSetup] Copying WebSetup logs.")
		$CommandsWebSetup = @(
			"robocopy `"$env:USERPROFILE\Local Settings\Application Data\Microsoft\WebSetup\Panther`" `"$TempDir\UpgradeSetup\WebSetup-Panther`" *.* /MIR /XF *.png *.js *.tmp *.exe"
		)
		RunCommands $LogPrefixWebSetup $CommandsWebSetup -ThrowException:$False -ShowMessage:$True
	}

	if (Test-Path "$env:USERPROFILE\Local Settings\Application Data\Microsoft\WebSetup\Panther") {
		FwCreateFolder $TempDir\UpgradeSetup\PurchaseWindowsLicense
		LogInfo ('[PurchWinLic] Copying PurchaseWindowsLicense logs.')
		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths.add(@("$env:LocalAppdata\microsoft\Microsoft\Windows\PurchaseWindowsLicense\PurchaseWindowsLicense.log", "$TempDir\UpgradeSetup\PurchaseWindowsLicense"))
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	}

	if (Test-Path "$env:USERPROFILE\Local Settings\Application Data\Microsoft\WebSetup\Panther") {
		FwCreateFolder $TempDir\UpgradeSetup\WindowsAnytimeUpgrade
		LogInfo ('[AnyUpgr] Copying Anytime Upgrade logs.')
		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths.add(@("$env:LocalAppdata\microsoft\Microsoft\Windows\Windows Anytime Upgrade\upgrade.log", "$TempDir\UpgradeSetup\WindowsAnytimeUpgrade"))
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION SETUPLOGSFunc ####################

##################### FUNCTION PBRLOGSFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDPBRLogs {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# - Get Sysrest logs for PBR issues
	if (Test-Path "C:\`$SysReset\Logs") {
		$LogPrefixSysReset = 'SysReset'
		FwCreateFolder $TempDir\UpgradeSetup\SysReset
		LogInfo ("[$LogPrefixSysReset] Copying SysReset logs.")
		$CommandsSysReset = @(
			#"cmd /r xcopy /s /e /c `"c:\```$SysReset\Logs\*.*`" `"$TempDir\UpgradeSetup\SysReset`""
			"robocopy 'c:\`$SysReset\AppxLogs' `"$TempDir\UpgradeSetup\SysReset\AppxLogs`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S"
			"robocopy 'c:\`$SysReset\Logs' `"$TempDir\UpgradeSetup\SysReset\Logs`" /S /COPY:DT /XF *.esd *.wim *.dll *.sdi *.mui *.png *.ttf /LOG+:$RobocopyLog /S"
		)
		RunCommands $LogPrefixSysReset $CommandsSysReset -ThrowException:$False -ShowMessage:$True
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION PBRLOGSFunc ####################

#################### FUNCTION DEPLOYMENTLOGSFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDeploymentLogs {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# MDT logs
	# Bug 635: _DND: Bloated TSS setup report due to _SMSTaskSequence collection, added file exclusions
	$LogPrefixMDT = 'MDT'
	@(
		("$env:SystemDrive\MININT", "$TempDir\UpgradeSetup\minint"),
		("$env:systemroot\temp\deploymentlogs", "$TempDir\UpgradeSetup\deploymentlogs"),
		("$env:SystemDrive\_SMSTaskSequence", "$TempDir\UpgradeSetup\SMSTaskSequence")
	) | ForEach-Object {
		if (Test-Path $_[0] ) {
			FwCreateFolder $_[1]
			LogInfo "[$LogPrefixMDT] Collecting: $($_[0])"
			robocopy.exe `"$($_[0])`" `"$($_[1])`" /W:1 /R:1 /NP /E *.log /LOG+:$RobocopyLog /S | Out-Null
		}
	}

	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:TEMP\smstslog\smsts.log", "$TempDir\UpgradeSetup\curentusertemp-smsts.log"),
		@("$env:SystemDrive\users\administrator\appdata\local\temp\smstslog\smsts.log", "$TempDir\UpgradeSetup\admintemp-smsts.log"),
		@("$env:windir\setupcomplete.log", "$TempDir\UpgradeSetup\SCCM_setupcomplete.log")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False

	# Windows Recovery Environment (Windows RE) and system reset configuration
	$Commands = @(
		"ReAgentc.exe /info | Out-File -Append $($Prefix)ReAgentc.txt"
	)
	RunCommands 'MDT' $Commands -ThrowException:$False -ShowMessage:$True
	# ========================================================================================================================
	# Section WDS
	if (Test-Path $env:windir\system32\wdsutil.exe) {
		$LogPrefixWDS = 'WDS'
		FwCreateFolder $TempDir\WDS
		LogInfo ("[$LogPrefixWDS] Getting WDS info.")
		$CommandsWDS = @(
			"xcopy `"$env:windir\System32\winevt\Logs\*deployment-services*.*`" `"$TempDir\WDS`" /Y /H"
			"WDSUTIL /get-server /show:all /detailed	| Out-File -Append $TempDir\WDS\WDS-Get-Server.txt"
			"WDSUTIL /get-transportserver /show:config	| Out-File -Append $TempDir\WDS\WDS-Get-Transportserver.txt"
		)
		RunCommands $LogPrefixWDS $CommandsWDS -ThrowException:$False -ShowMessage:$True
	}

	# -----------------------------------------------------------------------------
	# Get some SCCM logs and other data if they exist
	if (Test-Path "$env:windir\ccm\logs\ccmexec.log") {
		$LogPrefixSCCM = 'SCCM'
		FwCreateFolder $TempDir\SCCM
		LogInfo ("[$LogPrefixSCCM] Copying SCCM logs.")
		$CommandsSCCM = @(
			"xcopy `"$env:windir\ccm\logs\*.*`" `"$TempDir\sccm`" /y /s /e /c"
			"Get-CimInstance -Namespace 'root\ccm\Policy\Machine\ActualConfig' -Class CCM_SoftwareUpdatesClientConfig | Out-File -Append $TempDir\sccm\_CCM_SoftwareUpdatesClientConfig.txt"
		)
		RunCommands $LogPrefixSCCM $CommandsSCCM -ThrowException:$False -ShowMessage:$True
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DEPLOYMENTLOGSFunc ####################

#################### FUNCTION PERMISSIONSANDPOLICIESFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDPermissionsAndPolicies {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# Section Policies and Permissions
	$LogPrefixPermPol = 'PermPol'
	LogInfo ("[$LogPrefixPermPol] Permissions and Policies section.")
	$outfile = "$($Prefix)File_Icacls_Permissions.txt"
	$CommandsPermPol = @(
		"icacls C:\								| Out-File -Append $outfile"
		"icacls C:\windows						| Out-File -Append $outfile"
		"icacls C:\windows\serviceProfiles /t	| Out-File -Append $outfile"
		"secedit /export /cfg `"$($Prefix)User_Rights.txt`""
	)
	RunCommands $LogPrefixPermPol $CommandsPermPol -ThrowException:$False -ShowMessage:$True

	LogInfo ("[$LogPrefixPermPol] Querying registry keys.")
	# FwExportRegistry using -RealExport will overwrite any existing file
	$RegKeysPermPol = @(
		('HKCU:Software\Policies', "$($Prefix)reg_Policies.txt"),
		('HKLM:Software\Policies', "$($Prefix)reg_Policies.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies', "$($Prefix)reg_Policies.txt"),
		('HKLM:System\CurrentControlSet\Policies', "$($Prefix)reg_Policies.txt")
	)
	FwExportRegistry $LogPrefixPermPol $RegKeysPermPol

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION PERMISSIONSANDPOLICIESFunc ####################

#################### FUNCTION STORAGEFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDStorageInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# Section Storage and Device info
	$LogPrefix = 'Storage'
	LogInfo ("[$LogPrefix] Getting Storage and Device info.")
	$Commands = @(
		"vssadmin.exe list volumes			| Out-File -Append $($Prefix)VSSAdmin.txt"
		"vssadmin.exe list writers			| Out-File -Append $($Prefix)VSSAdmin.txt"
		"vssadmin.exe list providers		| Out-File -Append $($Prefix)VSSAdmin.txt"
		"vssadmin.exe list shadows			| Out-File -Append $($Prefix)VSSAdmin.txt"
		"vssadmin.exe list shadowstorage	| Out-File -Append $($Prefix)VSSAdmin.txt"
		"reg.exe save `"HKLM\System\MountedDevices`" `"$($Prefix)reg_MountedDevices.hiv`""
	)
	if ($_WIN10_2004_OR_LATER) {
		if ((Get-WindowsReservedStorageState).ReservedStorageState -eq $true) {
			$Commands += @(
				"Get-WindowsReservedStorageState | Out-File -Append $($Prefix)Storage_ReservedStorageState.txt"
				"fsutil storagereserve query $env:SystemDrive | Out-File -Append $($Prefix)Storage_ReservedStorageState.txt"
			)
		}
	}
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	# get filter drivers
	LogInfo ("[$LogPrefix] Getting filter driver info.")
	$TempDir = Split-Path -Leaf $TempDir
	FwGetFltMcInfo -noSplit -Subfolder $TempDir -FilePrefix $env:COMPUTERNAME

	LogInfo ("[$LogPrefix] Querying registry keys.")
	# FwExportRegistry using -RealExport will overwrite any existing file
	$RegKeys = @(
		('HKCU:Software\Policies', "$($Prefix)reg_Policies.txt"),
		('HKLM:System\MountedDevices', "$($Prefix)reg_MountedDevices.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Services\iScsiPrt', "$($Prefix)reg_iSCSI.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Enum', "$($Prefix)reg_Enum.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager', "$($Prefix)reg_ReservedStorageState.txt")
	)
	FwExportRegistry $LogPrefix $RegKeys

	if ($_WIN8_OR_LATER) {
		Write-Output 'EFI system partition GUID: c12a7328-f81f-11d2-ba4b-00a0c93ec93b' | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
		Write-Output 'https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/set-id' | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage.txt') -Append

		try {
			LogInfo ("[$LogPrefix] Get capacity and free space.")
			$diskobj = @()
			Get-CimInstance Win32_Volume -Filter "DriveType='3'" | ForEach-Object {
				$volobj = $_
				$parobj = Get-Partition | Where-Object { $_.AccessPaths -contains $volobj.DeviceID }
				if ( $parobj ) {
					$efi = $null
					if ($parObj.GptType -match '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}') { $efi = $true }
					$diskobj += [pscustomobject][ordered]@{
						DiskID          = $([string]$($parobj.DiskNumber) + '-' + [string]$($parobj.PartitionNumber)) -as [string]
						Mountpoint      = $volobj.Name
						Letter          = $volobj.DriveLetter
						Label           = $volobj.Label
						FileSystem      = $volobj.FileSystem
						'Capacity(GB)'  = ([Math]::Round(($volobj.Capacity / 1GB), 2))
						'FreeSpace(GB)' = ([Math]::Round(($volobj.FreeSpace / 1GB), 2))
						'Free(%)'       = ([Math]::Round(((($volobj.FreeSpace / 1GB) / ($volobj.Capacity / 1GB)) * 100), 0))
						Type            = $parObj.Type
						GptType         = $parObj.GptType
						EFI             = $efi
						'Boot'          = $VolObj.BootVolume
						Active          = $parObj.IsActive
					}
				}
			}
			$diskobj | Sort-Object DiskID | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
		}
		catch { LogException ("[$LogPrefix] Failed to get capacity and free space.") $_ }

		LogInfo ("[$LogPrefix] Get volume and partition info.")
		Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
			$volobj = $_
			$parobj = Get-Partition | Where-Object { $_.AccessPaths -contains $volobj.Path }
			if ( $parobj ) {
				if ($($volobj.FileSystemLabel) -ne '') {
					Write-Output "------ volume $($volobj.FileSystemLabel), partition #$($parobj.PartitionNumber), disk #$($parobj.DiskNumber) -------"	| Out-File -FilePath ($Prefix + 'Storage.txt') -Append
				}
				else {
					Write-Output "------ volume (no label), partition #$($parobj.PartitionNumber), disk #$($parobj.DiskNumber) -------" | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
				}
				$volobj | Select-Object -Property * | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
				Write-Output "------ partition #$($parobj.PartitionNumber), disk #$($parobj.DiskNumber) -------" | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
				$parobj | Select-Object -Property * | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
			}
		}

		LogInfo ("[$LogPrefix] Get powershell storage cmdLets info.")
		Get-Disk | Out-File -FilePath ($Prefix + 'Storage_get-disk.txt')
		Write-Output '------ Get disk objects -------' | Out-File -FilePath ($Prefix + 'Storage_get-disk.txt') -Append
		Get-Disk | Select-Object * | Out-File -FilePath ($Prefix + 'Storage_get-disk.txt') -Append
		Get-PhysicalDisk | Out-File -FilePath ($Prefix + 'Storage_get-physicaldisk.txt')
		Write-Output '------ Get physical disk objects -------' | Out-File -FilePath ($Prefix + 'Storage_get-physicaldisk.txt') -Append
		Get-PhysicalDisk | Select-Object * | Out-File -FilePath ($Prefix + 'Storage_get-physicaldisk.txt') -Append
		Get-VirtualDisk | Out-File -FilePath ($Prefix + 'Storage_get-virtualdisk.txt')
		Write-Output '------ Get virtual disk objects -------' | Out-File -FilePath ($Prefix + 'Storage_get-virtualdisk.txt') -Append
		Get-VirtualDisk | Select-Object * | Out-File -FilePath ($Prefix + 'Storage_get-virtualdisk.txt') -Append
		Get-Partition | Out-File -FilePath ($Prefix + 'Storage_get-partition.txt')
		Write-Output '------ Get partition objects -------' | Out-File -FilePath ($Prefix + 'Storage_get-partition.txt') -Append
		Get-Partition | Select-Object * | Out-File -FilePath ($Prefix + 'Storage_get-partition.txt') -Append
		Get-Volume | Out-File -FilePath ($Prefix + 'Storage_get-volume.txt')
		Write-Output '------ Get volume objects -------' | Out-File -FilePath ($Prefix + 'Storage_get-volume.txt') -Append
		Get-Volume | Select-Object * | Out-File -FilePath ($Prefix + 'Storage_get-volume.txt') -Append

		try {
			LogInfo ("[$LogPrefix] Retrieve storage info from Win32_DiskDrive class.")
			Get-CimInstance Win32_DiskDrive | Out-File -FilePath ($Prefix + 'Storage_Win32_DiskDrive.txt')
			Get-CimInstance Win32_DiskPartition | Out-File -FilePath ($Prefix + 'Storage_Win32_DiskPartition.txt')
			Get-CimInstance Win32_LogicalDiskToPartition | Out-File -FilePath ($Prefix + 'Storage_Win32_LogicalDiskToPartition.txt')
			Get-CimInstance Win32_LogicalDisk | Out-File -FilePath ($Prefix + 'Storage_Win32_LogicalDisk.txt')
			Get-CimInstance Win32_Volume | Out-File -FilePath ($Prefix + 'Storage_Win32_Volume.txt')
		}
		catch { LogException ("[$LogPrefix] Failed to retrieve storage info from Win32_DiskDrive class.") $_ }

		LogInfo ("[$LogPrefix] Get disk health.")
		# Begin Disk Info script-----------------------------------
		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage_Reliability.txt') -Append
		Write-Output '------ Get disk health -------' | Out-File -FilePath ($Prefix + 'Storage_Reliability.txt') -Append
		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage_Reliability.txt') -Append

		LogInfo ("[$LogPrefix] Get disk reliability.")
		$Pdisk = Get-PhysicalDisk
		foreach ( $LDisk in $PDisk ) {
			$LDisk.FriendlyName | Out-File -FilePath ($Prefix + 'Storage_Reliability.txt') -Append
			$LDisk.HealthStatus | Out-File -FilePath ($Prefix + 'Storage_Reliability.txt') -Append
			# performance: ~24 sec.
			# $LDisk | Get-StorageReliabilityCounter | Select-Object * | Format-List | Out-File -FilePath ($Prefix+"Storage_Reliability.txt") -append
			Write-Output '==================' | Out-File -FilePath ($Prefix + 'Storage_Reliability.txt') -Append
		}
		# End Disk Info--------------------------------

		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
		Write-Output '------ Get physical disk info -------' | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage.txt') -Append
		Get-PhysicalDisk | Select-Object * | Out-File -FilePath ($Prefix + 'Storage.txt') -Append

		# try to build diskpart script and execute it
		try {
			LogInfo ("[$LogPrefix] Build diskpart script.")
			# - Diskpart info
			Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append
			Write-Output '------ Get disk info using diskpart -------'	| Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append
			Write-Output '------ Note that a failure finding a disk in the command file will end the query so there will be error at the end of the output -------'	| Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append
			Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append

			# - Build the command file
			$disks = Get-Disk
			Write-Output 'list disk' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII

			foreach ($disk in $disks) {
				Write-Output "select disk $(($disk).Number)" | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
				Write-Output 'list partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
				$number_partitions = (Get-Disk -Number ($disk).Number | Get-Partition).count
				if ($number_partitions -eq $null) { $number_partitions = 1 }
				for ( $partition = 1; $partition -le $number_partitions; ++$partition ) {
					Write-Output "select partition $partition" | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
					Write-Output 'detail partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
				}
			}

			Write-Output 'list volume' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
			$number_volumes = (Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' }).count - 1
			for ( $volume = 0; $volume -le $number_volumes; ++$volume ) {
				Write-Output "select volume $volume" | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
				Write-Output 'detail volume' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
			}
			# - Done building command file

			LogInfo ("[$LogPrefix] Running diskpart to retrieve info.")
			diskpart /s ($Prefix + 'pscommand.txt') | Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') | Wait-Process
			Remove-Item ($Prefix + 'pscommand.txt') -Force
		}
		catch { LogException ("[$LogPrefix] Failed to retrieve storage info from diskpart.") $_ }
	}
	else {
		LogInfo ("[$LogPrefix] Build diskpart script.")
		# - Diskpart info
		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append
		Write-Output '------ Get disk info using diskpart -------'	| Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append
		Write-Output '------ Note that a failure finding a disk in the command file will end the query so there will be error at the end of the output -------'	| Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append
		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append

		# - Build the command file
		Write-Output 'list disk' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII
		Write-Output 'select disk 0' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'list volume' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'list partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select partition 1' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select partition 2' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select partition 3' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'list volume' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select volume 1' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail volume' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select volume 2' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail volume' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select disk 1' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'list partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select partition 1' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select partition 2' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'select partition 3' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		Write-Output 'detail partition' | Out-File -FilePath ($Prefix + 'pscommand.txt') -Encoding ASCII -Append
		# - Done building command file

		LogInfo ("[$LogPrefix] Running diskpart to retrieve info.")
		diskpart /s ($Prefix + 'pscommand.txt') >> ($Prefix + 'Storage_diskpart.txt') 2>> $ErrorFile
		Write-Output $Line | Out-File -FilePath ($Prefix + 'Storage_diskpart.txt') -Append
		Remove-Item ($Prefix + 'pscommand.txt') -Force
	}
	LogInfo ("[$LogPrefix] End Storage and Device info.")

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION STORAGEINFOFunc ####################

#################### FUNCTION PROCESSINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDProcessInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# replaced wmic
	#"wmic process get * /format:texttable  > $($Prefix)Process_and_Service_info.txt"

	# Section Running process info
	LogInfo ('[Process] Getting process info.')
	$Commands = @(
		"tasklist /svc /fo list | Out-File -Append $($Prefix)Process_and_Service_Tasklist.txt"
		"Get-CimInstance Win32_Process | fl ProcessId,Name,HandleCount,WorkingSetSize,VirtualSize,CommandLine | Out-File -Append $($Prefix)Process_and_Service_info.txt"
	)
	RunCommands 'Process' $Commands -ThrowException:$False -ShowMessage:$True

	try {
		$disabledServices = Get-Service | Where-Object { $_.StartType -eq [System.ServiceProcess.ServiceStartMode]::Disabled }
		if ($disabledServices) {
			Write-Output 'This file contains a list of services that are currently disabled on this system.' | Out-File -Append "$($Prefix)Services_disabled.txt"
			Write-Output $line | Out-File -Append "$($Prefix)Services_disabled.txt"
			$disabledServices | Out-File -Append "$($Prefix)Services_disabled.txt"
		}
	}
 catch {}

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION PROCESSINFOFunc ####################

#################### FUNCTION BITLOCKERINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDBitLockerInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$MBAM_SYSTEM = 0

	# Section BitLocker and MBAM
	$LogPrefixBitLocker = 'BitLocker'
	LogInfo ("[$LogPrefixBitLocker] Querying registry keys.")
	# FwExportRegistry using -RealExport will overwrite any existing file
	$RegKeysBitLocker = @(
		('HKLM:SOFTWARE\Policies\Microsoft\FVE', "$($Prefix)Bitlocker_MBAM_reg.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Policies\Microsoft\FVE', "$($Prefix)Bitlocker_MBAM_reg.txt"),
		('HKLM:SOFTWARE\Policies\Microsoft\TPM', "$($Prefix)Bitlocker_MBAM_reg.txt"),
		('HKLM:SOFTWARE\Microsoft\BitLockerCsp', "$($Prefix)Bitlocker_MBAM_reg.txt"),
		('HKLM:SOFTWARE\Microsoft\MBAM', "$($Prefix)Bitlocker_MBAM_reg.txt"),
		('HKLM:SOFTWARE\Microsoft\MBAMPersistent', "$($Prefix)Bitlocker_MBAM_reg.txt"),
		('HKLM:SOFTWARE\Microsoft\MBAM Server', "$($Prefix)Bitlocker_MBAM_reg.txt")
	)
	FwExportRegistry $LogPrefixBitLocker $RegKeysBitLocker

	LogInfo ("[$LogPrefixBitLocker] Getting BitLocker and MBAM info.")
	if (Test-Path $env:windir\system32\manage-bde.exe) {
		LogInfo ("[$LogPrefixBitLocker] Retrieve ManageBDE and BitLocker PowerShell cmdLets info.")
		Write-Output '0 = OSVolume, 1 = FixedDataVolume, 2 = PortableDataVolume' | Out-File -Append "$($Prefix)BitLocker_Win32_EncryptableVolume.txt"
		Write-Output '' | Out-File -Append "$($Prefix)BitLocker_Win32_EncryptableVolume.txt"
		$CommandsBitLocker = @(
			"manage-bde -status																							| Out-File -Append $($Prefix)BitLocker_manage-bde.txt"
			"manage-bde -protectors c: -get																				| Out-File -Append $($Prefix)BitLocker_manage-bde.txt"
			"Get-BitLockerVolume | Format-List *																		| Out-File -Append $($Prefix)BitLocker_Volume.txt"
			"Get-BitLockerVolume | Select-Object -ExpandProperty KeyProtector MountPoint 								| Out-File -Append $($Prefix)BitLocker_KeyProtector.txt"
			"Get-CimInstance -Namespace root/CIMV2/Security/MicrosoftVolumeEncryption -Class Win32_EncryptableVolume	| Out-File -Append $($Prefix)BitLocker_Win32_EncryptableVolume.txt"
		)
		RunCommands $LogPrefixBitLocker $CommandsBitLocker -ThrowException:$False -ShowMessage:$True
	}

	if (Test-Path "$env:ProgramFiles\Microsoft\MDOP MBAM\mbamagent.exe") {
		try {
			LogInfo ('[MBAM] Retrieve info from MBAM_Volume class.')
			Get-CimInstance -class mbam_volume -Namespace root\microsoft\mbam | Out-File -Append ($Prefix + 'BitLocker_MBAM-WMINamespace.txt')
		}
		catch { LogException ('[MBAM] Failed to retrieve info from MBAM_Volume class.') $_ }
		# Feature 404: _DND: Decode MBAM event log on customer machines (which has MBAM agent installed)
		$_event_logs = 'Microsoft-Windows-MBAM/Admin', 'Microsoft-Windows-MBAM/Operational'
		$EVTX = $false
		$_format = '/TXT'
		Get-DNDEventLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs $_event_logs $EVTX $_format

		# Feature 580: Session information for BitLocker/MBAM
		LogInfo ("[$LogPrefixBitLocker] Retrieve sessions info on MBAM managed device.")
		$CommandsBitLocker = @(
			"query session | Out-File -Append $($Prefix)BitLocker_QuerySession.txt"
		)
		RunCommands $LogPrefixBitLocker $CommandsBitLocker -ThrowException:$False -ShowMessage:$True
	}

	if ($_PS4ormore) {
		try { Get-Tpm | Out-File -Append ($Prefix + 'BitLocker_GetTPM.txt') }
		catch { LogException ("[$LogPrefixTPM] Get-Tpm failed") $_ }
	}

	if (Test-Path "$env:windir\system32\tpmtool.exe") {
		$LogPrefixTPM = 'TPM'
		LogInfo ("[$LogPrefixTPM] Getting TPM info.")
		FwCreateFolder $TempDir\tpmtool
		$CommandsTPM = @(
			"tpmtool gatherlogs `"$TempDir\tpmtool`""
			"tpmtool getdeviceinformation	| Out-File -Append $TempDir\tpmtool\getdeviceinformation.txt"
		)
		if ($_WIN10) { $CommandsTPM += @("tpmtool parsetcglogs | Out-File -Append $TempDir\tpmtool\parsetcglogs.txt") }
		RunCommands $LogPrefixTPM $CommandsTPM -ThrowException:$False -ShowMessage:$True
	}
	else {
		LogWarn ("[$LogPrefixTPM] TPM not present.")
	}

	# Check for MBAM
	if ((Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\MBAM Server') -or (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\MBAM')) { $MBAM_SYSTEM = 1 }

	# - If MBAM server then gather this
	if ($MBAM_SYSTEM) {
		LogInfo ('[MBAM] Getting MBAM server info.')
		$outFile = "$($Prefix)BitLocker-MBAM_Info.txt"
		$MBAM = @(
			"Get-MbamCMIntegration							| Out-File -Append $outFile"
			"Get-MbamReport									| Out-File -Append $outFile"
			"Get-MbamWebApplication -AdministrationPortal	| Out-File -Append $outFile"
			"Get-MbamWebApplication -AgentService			| Out-File -Append $outFile"
			"Get-MbamWebApplication -SelfServicePortal		| Out-File -Append $outFile"
		)
		RunCommands 'MBAM' $MBAM -ThrowException:$False -ShowMessage:$True

		$_event_logs = 'Microsoft-Windows-MBAM-Web/Operational', 'Microsoft-Windows-MBAM-Setup/Admin', 'Microsoft-Windows-MBAM-Setup/Operational', 'Microsoft-Windows-MBAM-Web/Admin'
		$EVTX = $false
		$_format = '/TXT'
		Get-DNDEventLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs $_event_logs $EVTX $_format

		try {
			$MBAMWebAdministration = (Get-Module -Name WebAdministration -ListAvailable)
			if ($MBAMWebAdministration) {
				LogInfo ('[MBAM] Try to retrieve data from MBAM WebAdministration.')
				Import-Module WebAdministration
				$MBAMAppPool = Get-ChildItem -Path IIS:\AppPools\ | Where-Object { $_.Name -match 'mbam' }
				$MBAMSPNReg = $MBAMAppPool.ChildElements | Where-Object { $_.ElementTagName -eq 'processModel' } | Select-Object -ExpandProperty Attributes | Where-Object { $_.Name -eq 'userName' } | Select-Object Value
				setspn -l $MBAMSPNReg.Value | Out-File -Append "$($Prefix)BitLocker-MBAM_SPN.txt"
			}
			else { LogWarn ('[MBAM] MBAM WebAdministration module not found.') }
		}
		catch { LogException ('[MBAM] Failed to retrieve data from MBAM WebAdministration.') $_ }
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION BITLOCKERINFOFunc ####################
#################### FUNCTION RELIABILITYSUMMARYFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDReliabilitySummary {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	#Use good old SummaryReliability.vbs
	if ($Summary) {
		FwGet-SummaryVbsLog -Subfolder "Setup_Report$LogSuffix"
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION RELIABILITYSUMMARYFunc ####################

#################### FUNCTION ACTIVATIONSTATEFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDActivationState {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixActivation = 'Activation'
	# Get Licensing info
	try {
		LogInfo ("[$LogPrefixActivation] Getting licensing info.")
		$outFile = "$($Prefix)KMSActivation.txt"
		$Domain = (Get-CimInstance -Class Win32_ComputerSystem).Domain
		$KMSDNSEntry = '_vlmcs._tcp.' + $Domain
		$Activation = @(
			#"nslookup -type=all _vlmcs._tcp								| Out-File -Append $outFile"
			"Resolve-DnsName $KMSDNSEntry -type SRV -ErrorAction Ignore		| Out-File -Append $outFile"
			"licensingdiag.exe -report `"$($Prefix)lic_diag.txt`" -log `"$($Prefix)lic_logs.cab`""
			"icacls c:\windows\system32\spp /t								| Out-File -Append $($Prefix)File_Icacls_Permissions_SPP.txt"
		)
		RunCommands $LogPrefixActivation $Activation -ThrowException:$False -ShowMessage:$True
	}
	catch { LogException ("[$LogPrefixActivation] Failed to retrieve domain from Win32_ComputerSystem.") $_ }

	FwGetDSregCmd -Subfolder "Setup_Report$LogSuffix"

	LogInfo ("[$LogPrefixActivation] slmgr section.")
	$slmgr = @(
		"cscript.exe //Nologo `"$env:windir\system32\slmgr.vbs`" /dlv		| Out-File -Append $outFile"
		"cscript.exe //Nologo `"$env:windir\system32\slmgr.vbs`" /dlv all	| Out-File -Append $outFile"
		"cscript.exe //Nologo `"$env:windir\System32\slmgr.vbs`" /ao-list	| Out-File -Append $outFile"
		"Get-CimInstance -Class SoftwareLicensingService					| Out-File -Append $outFile"
	)
	RunCommands $LogPrefixActivation $slmgr -ThrowException:$False -ShowMessage:$True

	# Token Activation
	LogInfo ("[$LogPrefixActivation] Token section.")
	$outFile = "$($Prefix)Token_ACT.txt"
	$Commands = @(
		"Cscript.exe //Nologo `"$env:windir\system32\slmgr.vbs`" /dlv		| Out-File -Append $outFile"
		"Cscript.exe //Nologo `"$env:windir\system32\slmgr.vbs`" /lil		| Out-File -Append $outFile"
		"Cscript.exe //Nologo `"$env:windir\system32\slmgr.vbs`" /ltc		| Out-File -Append $outFile"
	)
	RunCommands $LogPrefixActivation $Commands -ThrowException:$False -ShowMessage:$True
	$outFile = "$($Prefix)Token_ACT_CERT.txt"
	$Commands = @(
		"Certutil -store ca													| Out-File -Append $outFile"
		"Certutil -store my													| Out-File -Append $outFile"
		"Certutil -store root												| Out-File -Append $outFile"
	)
	RunCommands $LogPrefixActivation $Commands -ThrowException:$False -ShowMessage:$True

	LogInfo ("[$LogPrefixActivation] Querying registry keys.")
	# FwExportRegistry using -RealExport will overwrite any existing file
	$RegKeysActivation = @(
		('HKLM:SYSTEM\WPA', "$($Prefix)reg_System-wpa.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform', "$($Prefix)reg_SoftwareProtectionPlatform.txt"),
		('HKU:\S-1-5-20\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform', "$($Prefix)reg_SoftwareProtectionPlatform.txt")
	)
	FwExportRegistry $LogPrefixActivation $RegKeysActivation

	# Feature 640: _DND: Add Azure Arc ESU information
	if (Test-Path "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe") {
		LogInfo ("[$LogPrefixActivation] Getting Azure Connected Machine info.")
		$Commands = @(
			"$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe show | Out-File -Append $($Prefix)AzureConnectedMachine.txt"
		)
		RunCommands $LogPrefixActivation $Commands -ThrowException:$False -ShowMessage:$True

		LogInfo ("[$LogPrefixActivation] Querying Azure Connected Machine Agent registry keys.")
		$RegKeysAzureConnectedMachineAgent = @(
			('HKLM:SOFTWARE\Microsoft\Azure Connected Machine Agent')
		)
		FwExportRegToOneFile $LogPrefixActivation $RegKeysAzureConnectedMachineAgent "$($Prefix)reg_AzureConnectedMachine.txt"
	}

	# Office token activation
	$officeVersions = @('14', '15', '16')
	foreach ($version in $officeVersions) {
		$x86Path = "$env:ProgramFiles(x86)\Microsoft Office\Office$version\ospp.vbs"
		$x64Path = "$env:ProgramFiles\Microsoft Office\Office$version\ospp.vbs"

		if (Test-Path $x86Path) {
			LogInfo ("[$LogPrefixActivation] Getting Office$version x86 Token info.")
			Write-Output "Checking for Office$version x86`n$Line" | Out-File -Append ($Prefix + 'Token_ACT.txt')
			Cscript.exe $x86Path /dtokils | Out-File -Append ($Prefix + 'Token_ACT.txt')
			Cscript.exe $x86Path /dtokcerts | Out-File -Append ($Prefix + 'Token_ACT.txt')
		}

		if (Test-Path $x64Path) {
			LogInfo ("[$LogPrefixActivation] Getting Office$version x64 Token info.")
			Write-Output "Checking for Office$version x64`n$Line" | Out-File -Append ($Prefix + 'Token_ACT.txt')
			Cscript.exe $x64Path /dtokils | Out-File -Append ($Prefix + 'Token_ACT.txt')
			Cscript.exe $x64Path /dtokcerts | Out-File -Append ($Prefix + 'Token_ACT.txt')
		}
	}
	# -------------------------------Removed as we should never need---------------------------
	# Write-Output -------------------------------------------
	# Write-Output Copying token cache and license store ...
	# Write-Output -------------------------------------------
	# cmd /r copy $env:windir\ServiceProfiles\LocalService\AppData\Local\Microsoft\WSLicense\tokens.dat $TempDir /y
	# cmd /r copy $env:windir\SoftwareDistribution\Plugins\7D5F3CBA-03DB-4BE5-B4B36DBED19A6833\117CAB2D-82B1-4B5A-A08C-4D62DBEE7782.cache $TempDir /y
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION ACTIVATIONSTATEFunc ####################

#################### FUNCTION DIRINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDirInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixDIR = 'DIR'
	LogInfo ("[$LogPrefixDIR] Getting directory listing of key files.")
	$Commands = @(
		"cmd /r dir /a /r C:\ 									| Out-File -Append $($Prefix)dir_driveroot.txt"
		"cmd /r dir /a /s /r $env:windir\system32\drivers		| Out-File -Append $($Prefix)dir_win32-drivers.txt"
		"cmd /r dir /a /s /r $env:TEMP							| Out-File -Append $($Prefix)dir_temp.txt"
		"cmd /r dir /a /s /r $env:windir\temp					| Out-File -Append $($Prefix)dir_temp.txt"
		"cmd /r dir /a /s /r $env:windir\inf					| Out-File -Append $($Prefix)dir_INF.txt"
		"cmd /r dir /a /s /r $env:windir\system32\catroot		| Out-File -Append $($Prefix)dir_catroot.txt"
		"cmd /r dir /a /s /r $env:windir\system32\catroot2		| Out-File -Append $($Prefix)dir_catroot.txt"
		"cmd /r dir /a /s /r $env:windir\system32\config\*.*	| Out-File -Append $($Prefix)dir_registry_list.txt"  # Get registry size info including Config and profile info
		"cmd /r dir /a /s /r c:\users\ntuser.dat				| Out-File -Append $($Prefix)dir_registry_list.txt"
	)
	if (Test-Path d:\) { $Commands += "cmd /r dir /a /r D:\																									| Out-File -Append $($Prefix)dir_driveroot.txt" }
	if (Test-Path e:\) { $Commands += "cmd /r dir /a /r E:\																									| Out-File -Append $($Prefix)dir_driveroot.txt" }
	if (Test-Path "$env:windir\boot") { $Commands += "cmd /r dir /a /s /r C:\windows\boot																	| Out-File -Append $($Prefix)dir_boot.txt" }
	if (Test-Path "$env:windir\LiveKernelReports") { $Commands += "cmd /r dir /a /s /r C:\Windows\LiveKernelReports											| Out-File -Append $($Prefix)dir_LiveKernelReports.txt" }
	if (Test-Path "$env:windir\System32\DriverStore\FileRepository") { $Commands += "cmd /r dir /a /s /r $env:windir\System32\DriverStore\FileRepository	| Out-File -Append $($Prefix)dir_win32-driverstore.txt" }
	if (Test-Path "$env:windir\systemapps") { $Commands += "cmd /r dir /a /s /r $env:windir\systemapps														| Out-File -Append $($Prefix)dir_systemapps.txt" }
	# Feature 572: Bootmgfw.efi Version Info Collection
	if ($_PS4ormore) {
		$binaries = @('bootmgfw.efi', 'bootmgr.efi')
		foreach ($file in $binaries) {
			if (Test-Path "$env:windir\boot\EFI\$file") {
				LogInfo ("[$LogPrefixDIR] Getting '$env:windir\boot\EFI\$file' file version.")
				$Commands += $version = (Get-Command "$env:windir\boot\EFI\$file").FileVersionInfo
				$Commands += Write-Output "$env:windir\boot\EFI\$file `t`t: $($version.FileMajorPart).$($version.FileMinorPart).$($version.FileBuildPart).$($version.FilePrivatePart)" | Out-File -FilePath ($Prefix + 'FileVersions_EFI.txt') -Append
			}
		}
	}
	RunCommands $LogPrefixDIR $Commands -ThrowException:$False -ShowMessage:$True

	if ($env:firmware_type -eq 'UEFI') {
		LogInfo ("[$LogPrefixDIR] Getting system partition (EFI) directory listing.")
		try {
			# retrieve system partition
			$uefiPartition = Get-Partition | Where-Object { $_.GptType -eq '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}' }
			# retrieve unused drive letter
			$freeDriveLetter = Get-ChildItem function:[d-z]: -n | Where-Object { !(Test-Path $_) } | Get-Random
			$freeDriveLetter = ($freeDriveLetter).Replace(':', '')
			if ($null -ne $freeDriveLetter) {
				# this adds a drive letter no matter if the partition is already mounted or not
				$uefiPartition | Set-Partition -NewDriveLetter $freeDriveLetter
				# has system partition a drive letter assigned now?
				$uefiPartition = Get-Partition | Where-Object { $_.GptType -eq '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}' }
				if ($null -ne $uefiPartition.DriveLetter) {
					Write-Output 'System partition (EFI) directory listing.' | Out-File "$($Prefix)dir_EFI.txt" -Append
					Write-Output "Mapped drive letter ($($uefiPartition.DriveLetter):) is random."	| Out-File "$($Prefix)dir_EFI.txt" -Append
					Write-Output $Line "`n" | Out-File "$($Prefix)dir_EFI.txt" -Append
					cmd /r dir "$($uefiPartition.DriveLetter):" /a /s /r | Out-File "$($Prefix)dir_EFI.txt" -Append
					# getting file versions of bootmgfw.efi and bootmgr.efi
					# Feature 572: Bootmgfw.efi Version Info Collection
					if ($_PS4ormore) {
						$binaries = @('bootmgfw.efi', 'bootmgr.efi')
						Write-Output "Mapped drive letter ($($uefiPartition.DriveLetter):) is random."	| Out-File -FilePath ($Prefix + 'FileVersions_EFI.txt') -Append
						foreach ($file in $binaries) {
							if (Test-Path "$($uefiPartition.DriveLetter):\EFI\Microsoft\Boot\$file") {
								LogInfo ("[$LogPrefixDIR] Getting '$($uefiPartition.DriveLetter):\EFI\Microsoft\Boot\$file' file version.")
								$version = (Get-Command "$($uefiPartition.DriveLetter):\EFI\Microsoft\Boot\$file").FileVersionInfo
								Write-Output "$($uefiPartition.DriveLetter):\EFI\Microsoft\Boot\$file `t: $($version.FileMajorPart).$($version.FileMinorPart).$($version.FileBuildPart).$($version.FilePrivatePart)" | Out-File -FilePath ($Prefix + 'FileVersions_EFI.txt') -Append
							}
						}
					}
					# dismount system partition
					mountvol "$($uefiPartition.DriveLetter):" /d
				}
			}
			else { Write-Host 'No free drive letter.' | Out-File "$($Prefix)dir_EFI.txt" }
		}
		catch { Write-Host 'Something went wrong while trying to DIR over EFI partition.' | Out-File "$($Prefix)dir_EFI.txt" }
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DIRINFOFunc ####################


#################### FUNCTION ENERGYINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDEnergyInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixPowerCfg = 'PowerCfg'

	# Power - general info
	LogInfo ("[$LogPrefixPowerCfg] Getting general powercfg info.")
	$outFile = "$($Prefix)Powercfg_Settings.txt"
	$Power = @(
		"powercfg /L		| Out-File -Append $outFile"
		"powercfg /aliases	| Out-File -Append $outFile"
		"Powercfg /a		| Out-File -Append $outFile"
		"powercfg /qh		| Out-File -Append $outFile"
	)
	if (-not ($POWERCFG -or $Max -or $POWERWPR)) { $Power += @("powercfg /SYSTEMPOWERREPORT /OUTPUT $($Prefix)Powercfg-systempowerreport.html") }
	RunCommands $LogPrefixPowerCfg $Power -ThrowException:$False -ShowMessage:$True

	# - Generate detail battery, sleep and power info.
	# - Only run if flag set
	if ($POWERCFG -or $Max -or $POWERWPR) {
		LogInfo ("[$LogPrefixPowerCfg] Getting detailed powercfg info and generate powercfg reports.")
		$CommandsPowerCfg = @(
			"powercfg /BATTERYREPORT /duration 14 /output $($Prefix)Powercfg-batteryreport.html"
			"powercfg /DEVICEQUERY wake_armed | Out-File -Append $($Prefix)Powercfg-wake_armed.txt"
			"powercfg /ENERGY /output $($Prefix)Powercfg-energy.html"
			"powercfg /LASTWAKE | Out-File -Append $($Prefix)Powercfg-lastwake.txt"
			"powercfg /REQUESTS | Out-File -Append $($Prefix)Powercfg-requests.txt"
			"powercfg /SLEEPSTUDY /duration 28 /output $($Prefix)Powercfg-sleepstudy.html"
			"powercfg /SRUMUTIL /output $($Prefix)Powercfg-srumdbout.xml /xml"
			# deprecated
			# "powercfg /SYSTEMSLEEPDIAGNOSTICS /OUTPUT $($Prefix)Powercfg-system-sleep-diagnostics.html"
			# same like SLEEPSTUDY, but for 3 days only
			# "powercfg /SYSTEMPOWERREPORT /OUTPUT $($Prefix)Powercfg-systempowerreport.html"
			"powercfg /WAKETIMERS | Out-File -Append $($Prefix)Powercfg-waketimers.txt"
		)
		if (Test-Path $env:windir\system32\sleepstudy\*abnormal*) {
			FwCreateFolder $TempDir\sleepstudy
			$CommandsPowerCfg += @("xcopy /chrky $env:windir\system32\sleepstudy\*abnormal*.etl $TempDir\sleepstudy\")
		}
		RunCommands $LogPrefixPowerCfg $CommandsPowerCfg -ThrowException:$False -ShowMessage:$True
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION ENERGYINFOFunc ####################

#################### FUNCTION SURFACEINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDSurfaceInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# - Microsoft Surface Specific info.
	# - Drivers
	# Feature 590: Collect output of WMI Win32_BIOS class
	$LogPrefixSurface = 'Surface'
	LogInfo ("[$LogPrefixSurface] Manufacturer: $_manufacturer")
	LogInfo ("[$LogPrefixSurface] Collecting manufacturer specific information.")
	$Surface = @(
		"Get-CimInstance Win32_PnPSignedDriver | Select-Object devicename,driverversion,HardwareID | Where-Object {`$_.devicename -like `"*intel*`" -or `$_.devicename -like `"*surface*`" -or `$_.devicename -like `"*Nvidia*`" -or `$_.devicename -like `"*microsoft*`" -or `$_.devicename -like `"*marvel*`" -or `$_.devicename -like `"*qualcomm*`" -or `$_.devicename -like `"*realtek*`"} | Sort-object -property devicename | Export-Csv -path $($Prefix)Surface_drivers.csv",
		"Get-ComputerInfo | Out-File -Append $($Prefix)Surface_ComputerInfo.txt",
		"Get-CimInstance -Class Win32_SystemEnclosure | Out-File -Append $($Prefix)Surface_Win32_SystemEnclosure.txt",
		"Get-CimInstance -Class Win32_BIOS | Out-File -Append $($Prefix)Surface_Win32_BIOS.txt"
	)
	RunCommands $LogPrefixSurface $Surface -ThrowException:$False -ShowMessage:$True

	# - Registry keys
	LogInfo ("[$LogPrefixSurface] Querying registry keys.")
	# FwExportRegistry using -RealExport will overwrite any existing file
	$RegKeysSurface = @(
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\SurfaceDockFwUpdate', "$($Prefix)Surface_Registry.txt"),
		('HKLM:SOFTWARE\Microsoft\Surface\OSImage', "$($Prefix)Surface_Registry.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\Power', "$($Prefix)Surface_Registry.txt")
	)
	FwExportRegistry $LogPrefixSurface $RegKeysSurface
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION SURFACEINFOFunc ####################

#################### FUNCTION EVENTLOGSFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDEventLogs {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null,

		[Parameter()]
		[array] $_event_logs = $null,

		[Parameter()]
		[bool] $EVTX = $true,

		[Parameter()]
		[string] $_format = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	if ($EVTX) {
		# - Get all event logs and convert some if getevents script is available
		$LogPrefixEventLogs = 'Events'
		FwCreateFolder $TempDir\eventlogs
		LogInfo ("[$LogPrefixEventLogs] Getting event logs.")
		$_EVTXOLDPATH = "$env:windir.old\Windows\System32\Winevt\Logs"
		if (Test-Path "$_EVTXOLDPATH") { FwCreateFolder $TempDir\Windows.old }
		$CommandsEventLogs = @(
			"robocopy.exe `"$env:windir\system32\winevt\logs`" `"$TempDir\eventlogs`" /W:1 /R:1 /NP /E /XF Archive*.evtx /LOG+:$RobocopyLog /S | Out-Null"
		)
		if (Test-Path "$_EVTXOLDPATH") { $CommandsEventLogs += @("robocopy `"$_EVTXOLDPATH`" `"$TempDir\Windows.old\eventlogs`" /W:1 /R:1 /NP /LOG+:$RobocopyLog /S | Out-Null") }
		RunCommands $LogPrefixEventLogs $CommandsEventLogs -ThrowException:$False -ShowMessage:$True
	}

	#Use good old GetEvents.vbs
	$ExclusionList = ''
	# Long list
	# $EventLogNames = "System","Application","Setup","Microsoft-Windows-WMI-Activity/Operational","Microsoft-Windows-Setup/Analytic","General Logging","HardwareEvents","Microsoft-Windows-Crashdump/Operational","Microsoft-Windows-Dism-Api/Analytic","Microsoft-Windows-EventLog-WMIProvider/Debug","Microsoft-Windows-EventLog/Analytic","Microsoft-Windows-EventLog/Debug","Microsoft-Windows-Store/Operational","Microsoft-Windows-Store/Operational","Microsoft-Client-Licensing-Platform/Admin"
	if ($_event_logs) { $EventLogNames = $_event_logs }
	else {
		# Short list
		$EventLogNames = 'System', 'Application', 'Setup', 'Microsoft-Windows-WMI-Activity/Operational', 'Microsoft-Windows-TaskScheduler/Operational', 'Microsoft-Windows-Store/Operational', 'Microsoft-Client-Licensing-Platform/Admin'
	}

	if ($_format) { $OutputFormatCMD = $_format }
	else { $OutputFormatCMD = '/TXT /CSV' }

	$Days = ''
	$EventLogAdvisorXMLCMD = ''
	$Query = $null
	$Suffix = $null
	$DisplayToAdd = ''
	$LogPrefixSDP = 'psSDP'
	if (Test-Path -Path "$Scriptfolder\psSDP\Diag\global\GetEvents.vbs") {
		try {
			LogInfo "[$LogPrefixSDP] GetEvents.vbs starting..."
			Push-Location -Path "$Scriptfolder\psSDP\Diag\global"
			foreach ($EventLogName in $EventLogNames) {
				$CommandsVerifyEventLogs = @(
					"wevtutil gl `"$EventLogName`""
				)
				RunCommands $LogPrefixSDP $CommandsVerifyEventLogs -ThrowException:$False -ShowMessage:$True

				if ($LASTEXITCODE -eq 0) {
					if ($ExclusionList -notcontains $EventLogName) {
						$CommandToExecute = "cscript.exe //e:vbscript $Scriptfolder\psSDP\Diag\global\GetEvents.vbs `"$EventLogName`" /channel $Days $OutputFormatCMD $EventLogAdvisorXMLCMD `"$TempDir`" /noextended $Query $Prefix $Suffix"
						LogInfo "[$LogPrefixSDP] GetEvents.vbs Exporting event log: `"$EventLogName`""
						Invoke-Expression -Command $CommandToExecute >$null 2>> $ErrorFile
					}
				}

				if ($LASTEXITCODE -eq '15007') {
					LogWarn "[$LogPrefixSDP] GetEvents.vbs the specified channel could not be found: `"$EventLogName`""
				}
			}
		}
		catch { LogException ("[$LogPrefixSDP] An Exception happend in GetEvents.VBS") $_ }
		Pop-Location
		LogInfo "[$LogPrefixSDP] GetEvents.vbs event log export completed"
	}
	else { LogInfo "[$LogPrefixSDP] GetEvents.vbs not found - skipping..." }

	<#
	#Use built-in TSS function FwExportEventLogWithTXTFormat
	FwExportEventLogWithTXTFormat System ($TempDir)
	FwExportEventLogWithTXTFormat Application $TempDir
	FwExportEventLogWithTXTFormat Setup $TempDir
	FwExportEventLogWithTXTFormat Microsoft-Windows-WMI-Activity/Operational $TempDir
	FwExportEventLogWithTXTFormat Microsoft-Windows-TaskScheduler/Operational $TempDir
	FwExportEventLogWithTXTFormat Microsoft-Windows-Store/Operational $TempDir
	FwExportEventLogWithTXTFormat Microsoft-Client-Licensing-Platform/Admin $TempDir
	#>
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION EVENTLOGSFunc ####################

#################### FUNCTION MISCINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDMiscInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	#$LogPrefixMiscInfo = "MiscInfo"
	LogInfo ('[MiscInfo] Native export registry keys.')
	# FwExportRegistry using -RealExport will overwrite any existing file
	# removed reg_CurrentVersion_Windows* due to performance when running recursively (~3 minutes)
	# added non-recursive in $CommandsMiscInfo
	# ('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', "$($Prefix)reg_CurrentVersion_Windows_NT.txt"),
	# ('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion', "$($Prefix)reg_CurrentVersion_Windows.txt")

	$RegKeysMiscInfoExport = @(
		('HKLM:SYSTEM\CurrentControlSet\Control\FirmwareResources', "$($Prefix)reg_FirmwareResources.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\MUI\UILanguages', "$($Prefix)reg_langpack.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Services', "$($Prefix)reg_services.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$($Prefix)reg_LocalMachine-AppCompatFlags.txt")
	)
	FwExportRegistry 'MiscInfo' $RegKeysMiscInfoExport -RealExport $true

	LogInfo ('[MiscInfo] Export registry properties.')
	# FwExportRegistry property values
	$RegKeysMiscInfoProperty = @(
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'BuildLab', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'BuildLabEx', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'UBR', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'ProductName', "$($Prefix)reg_BuildInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel', 'Version', "$($Prefix)reg_AppModelVersion.txt")
	)
	FwExportRegistry 'MiscInfo' $RegKeysMiscInfoProperty

	LogInfo ('[MiscInfo] Export by querying registry keys.')
	# FwExportRegistry is using the /s (recursive) switch by default and appends to an existing file
	$RegKeysMiscInfoQuery = @(
		('HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP', "$($Prefix)reg_.NET-Setup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList', "$($Prefix)reg_ProfileList.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Superfetch', "$($Prefix)reg_superfetch.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\SvcHost', "$($Prefix)reg_SVCHost.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones', "$($Prefix)reg_TimeZone.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication', "$($Prefix)reg_Software_Authentication.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp', "$($Prefix)reg_SecurityInfo.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\OneSettings\compat\appraiser\Settings', "$($Prefix)reg_OneSettings_appraiser.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad', "$($Prefix)reg_Startup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Reliability', "$($Prefix)reg_Reliability.txt"),
		('HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Run', "$($Prefix)reg_Startup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Runonce', "$($Prefix)reg_Startup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE', "$($Prefix)reg_Setup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State', "$($Prefix)reg_Setup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Sysprep', "$($Prefix)reg_Setup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\SysPrepExternal', "$($Prefix)reg_Setup.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', "$($Prefix)reg_Uninstall.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\winevt', "$($Prefix)reg_Winevt.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\Windows Error Reporting', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp', "$($Prefix)reg_SecurityInfo.txt"),
		('HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall', "$($Prefix)reg_Uninstall.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\CrashControl', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\Power', "$($Prefix)reg_Power.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders', "$($Prefix)reg_SecurityInfo.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\Session Manager', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Power', "$($Prefix)reg_Power.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\Terminal Server', "$($Prefix)reg_TermServices.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\TimeZoneInformation', "$($Prefix)reg_TimeZone.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\WMI', "$($Prefix)reg_WMI.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Services\kbdhid', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Services\i8042prt', "$($Prefix)reg_Recovery.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\USB\AutomaticSurpriseRemoval', "$($Prefix)reg_Power.txt"),
		('HKLM:SYSTEM\DriverDatabase', "$($Prefix)reg_DriverDatabase_System.txt"),
		('HKLM:SYSTEM\Setup', "$($Prefix)reg_Setup.txt"),
		('HKCU:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$($Prefix)reg_CurrentUser-AppCompatFlags.txt")
	)
	FwExportRegistry 'MiscInfo' $RegKeysMiscInfoQuery

	LogInfo ('[MiscInfo] Getting Misc info.')
	$CommandsMiscInfo = @(
		"reg.exe save `"HKLM\SYSTEM\CurrentControlSet\services`" `"$($Prefix)reg_services.hiv`""
		"reg.exe save `"HKLM\SYSTEM\DriverDatabase`" `"$($Prefix)reg_DriverDatabase_System.hiv`""
		"reg.exe save `"HKLM\SOFTWARE\Microsoft\Windows\currentversion\winevt`" `"$($Prefix)reg_Winevt.hiv`""
		"reg.exe query `"HKLM\Software\Microsoft\Windows NT\CurrentVersion`"	| Out-File -Append $($Prefix)reg_CurrentVersion_Windows_NT.txt"
		"reg.exe query `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion`"		| Out-File -Append $($Prefix)reg_CurrentVersion_Windows.txt"
		"verifier.exe /query													| Out-File -Append $($Prefix)verifier.txt"
		#"cmd /r copy `"$env:windir\system32\config\drivers`" `"$($Prefix)drivers.hiv`""
	)
	RunCommands 'MiscInfo' $CommandsMiscInfo -ThrowException:$False -ShowMessage:$True

	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$env:windir\system32\netsetupmig.log", "$($Prefix)netsetupmig.log"),
		@("$env:windir\dpinst.log", "$($Prefix)dpinst.log"),
		@("$env:windir\certutil.log", "$($Prefix)certutil.log"),
		@("$env:windir\System32\catroot2\dberr.txt", "$($Prefix)dberr.txt"),
		@('c:\users\public\documents\sigverif.txt', "$($Prefix)sigverif.txt")
		#@("$env:windir\system32\config\drivers", "$($Prefix)drivers.hiv")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	try {
		LogInfo "[Get-DNDMiscInfo] waiting max 50 sec to succeed on copy $env:windir\system32\config\drivers" 'Gray'
		$StopWait = $False
		$attempt = 0
		While (($StopWait -eq $False) -and ($attempt -lt 10)) {
			$attempt += 1
			$Result = (cmd /r copy "$env:windir\system32\config\drivers" "$($Prefix)reg_Drivers.hiv" 2>&1)
			if ($Result -match '1 file') { $StopWait = $True; LogInfo "[Get-DNDMiscInfo] - Result: $Result (@attempt=$attempt)" 'Green' } else { $StopWait = $False ; LogErrorFile "[Get-DNDCbsPnpInfo] waiting +5 sec - Result: $Result (@attempt=$attempt)"; Start-Sleep -Milliseconds 5000 }
		}
		if ($Result -match '0 file') { LogInfo "[Get-DNDMiscInfo] - Result: $Result (@attempt=$attempt) - copy $env:windir\system32\config\drivers FAILED after $attempt attempts" 'Magenta' }
	}
	catch { LogException ("[Get-DNDMiscInfo] copying $env:windir\system32\config\drivers failed") $_ }

	# Get All Scheduled Task on the system
	LogInfo ('[MiscInfo] Get all scheduled task on the system.')
	$outFile = "$($Prefix)ScheduledTask.txt"
	'This file contains scheduled task info first in summary and then in verbose format'	| Out-File -Append $outFile
	Write-Output $Line | Out-File -Append $outFile
	$Commands = @(
		"SCHTASKS /query									| Out-File -Append $($Prefix)ScheduledTask.txt"
		"SCHTASKS /query /v									| Out-File -Append $($Prefix)ScheduledTask.txt"
		"bcdedit.exe /enum 2>&1								| Out-File -Append $($Prefix)BCDEdit.txt"
		"bcdedit.exe /enum all 2>&1							| Out-File -Append $($Prefix)BCDEdit.txt"
		"bcdedit.exe /enum all /v 2>&1						| Out-File -Append $($Prefix)BCDEdit.txt"
		#"Dism /english /online /get-drivers /Format:Table	| Out-File -Append $($Prefix)dism_3rdPartyDrivers.txt"
		#"Get-CimInstance Win32_PnPEntity					| Out-File -Append $($Prefix)drivers_WMIQuery.txt"
	)
	RunCommands 'MiscInfo' $Commands -ThrowException:$False -ShowMessage:$True

	# - Get .Net info
	LogInfo ('[MiscInfo] Getting .Net info.')
	Write-Output $Line | Out-File -Append ($Prefix + 'reg_.NET-Setup.txt')
	Write-Output 'Get .Net info using PS script'	| Out-File -Append ($Prefix + 'reg_.NET-Setup.txt')
	Write-Output $Line | Out-File -Append ($Prefix + 'reg_.NET-Setup.txt')

	$DotNetVersions = Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Updates | Where-Object { $_.name -like '*.NET Framework*' }
	foreach ($Version in $DotNetVersions) {
		$Updates = Get-ChildItem $Version.PSPath
		$Version.PSChildName	| Out-File -Append ($Prefix + 'reg_.NET-Setup.txt')
		foreach ($Update in $Updates) {
			$Update.PSChildName	| Out-File -Append ($Prefix + 'reg_.NET-Setup.txt')
		}
	}

	# Collect curl verion information
	# Feature 632: _DND: Collect CURL details
	if (Test-Path "$env:SystemRoot\system32\curl.exe") {
		LogInfo ('[MiscInfo] Get curl version on the system.')
		$outCurl = "$($Prefix)curl.txt"
		'This file contains information about curl on this system.'	| Out-File -Append $outCurl
		'https://curl.se/windows/microsoft.html.' | Out-File -Append $outCurl
		Write-Output $Line | Out-File -Append $outCurl
		$Commands = @(
			"cmd /r curl --version									| Out-File -Append $outCurl"
			"fsutil hardlink list c:\windows\system32\curl.exe		| Out-File -Append $outCurl"
		)
		if (Test-Path "$env:SystemRoot\SysWOW64\curl.exe") { $Commands += @("fsutil hardlink list C:\windows\SysWOW64\curl.exe | Out-File -Append $outCurl") }
		RunCommands 'MiscInfo' $Commands -ThrowException:$False -ShowMessage:$True
	}

	#################### END OF FUNCTION MISCFunc ####################

	#################### SECTION Powershell commands for Win10 Only ####################
	# Skip for now
	if ($_WIN10 -eq 3) {
		$outFile = $Prefix + 'MiscInfo.txt'
		$Commands = @(
			"Get-computerinfo -verbose | Format-list	| Out-File -Append $outFile"
			"Get-localgroup | Format-list				| Out-File -Append $outFile"
			"Get-localuser								| Out-File -Append $outFile"
			"Get-WUIsPendingReboot						| Out-File -Append $outFile"
			"Get-WUAVersion								| Out-File -Append $outFile"
			"Get-WULastInstallationDate					| Out-File -Append $outFile"
			"Get-WULastScanSuccessDate					| Out-File -Append $outFile"
		)
		RunCommands 'MiscInfo' $Commands -ThrowException:$False -ShowMessage:$True
	}
	#################### END SECTION Powershell commands for Win10 Only ####################
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION MISCINFOFunc ####################

#################### FUNCTION DEFENDERINFOFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDefenderInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	# - Get Windows Defender info if running on Windows 10
	if ($_WIN10) {
		$LogPrefixWindowsDefender = 'WindowsDefender'
		LogInfo ("[$LogPrefixWindowsDefender] Windows Defender info.")
		$RegKeysWindowsDefender = @(
			('HKLM:SOFTWARE\Microsoft\Windows Defender')
		)
		FwExportRegToOneFile $LogPrefixWindowsDefender $RegKeysWindowsDefender "$($Prefix)reg_Defender.txt"
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DEFENDERINFOFunc ####################

#################### FUNCTION MINIDUMPSFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDMiniDumps {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	# Get mini dumps
	if (Test-Path $env:windir\Minidump) {
		$LogPrefixDMP = 'DMP'
		LogInfo ("[$LogPrefixDMP] Collecting mini dumps.")
		FwCreateFolder $TempDir\Minidump
		$CommandsDMP = @(
			"xcopy /cherky $env:windir\Minidump\*.* `"$TempDir\Minidump\`""
		)
		RunCommands $LogPrefixDMP $CommandsDMP -ThrowException:$False -ShowMessage:$True
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION MINIDUMPSFunc ####################

#################### FUNCTION NETWORKBasicFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDNetworkBasic {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixNetwork = 'Network'
	LogInfo ("[$LogPrefixNetwork] Getting basic network info.")
	$CommandsNetworkBasic = @(
		"cmd /r copy `"$env:windir\System32\drivers\etc\hosts`" `"$($Prefix)NETWORK_hosts.txt`" /y"
		"ipconfig /all										| Out-File -Append $($Prefix)NETWORK_TCPIP_info.txt"
		"cmd /r route print									| Out-File -Append $($Prefix)NETWORK_TCPIP_info.txt"
		"cmd /r netstat -nato								| Out-File -Append $($Prefix)NETWORK_TCPIP_info.txt"
		"cmd /r netstat -anob								| Out-File -Append $($Prefix)NETWORK_TCPIP_info.txt"
		"cmd /r netstat -es									| Out-File -Append $($Prefix)NETWORK_TCPIP_info.txt"
		"cmd /r arp -a										| Out-File -Append $($Prefix)NETWORK_TCPIP_info.txt"
		"cmd /r netsh winhttp show proxy					| Out-File -Append $($Prefix)NETWORK_Proxy.txt"
		"cmd /r bitsadmin /util /getieproxy localsystem 	| Out-File -Append $($Prefix)NETWORK_Proxy.txt"
		"cmd /r bitsadmin /util /getieproxy networkservice  | Out-File -Append $($Prefix)NETWORK_Proxy.txt"
		"cmd /r bitsadmin /util /getieproxy localservice 	| Out-File -Append $($Prefix)NETWORK_Proxy.txt"
		"cmd /r ipconfig.exe /displaydns					| Out-File -Append $($Prefix)NETWORK_DnsClient_ipconfig-displaydns.txt"
	)
	RunCommands $LogPrefixNetwork $CommandsNetworkBasic -ThrowException:$False -ShowMessage:$True

	LogInfo ("[$LogPrefixNetwork] Querying basic network registry keys.")
	# FwExportRegistry using -RealExport will overwrite any existing file
	$RegKeysNetwork = @(
		('HKLM:SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}', "$($Prefix)NETWORK_NetworkAdapters_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\Network', "$($Prefix)NETWORK_NetworkAdapters_reg_output.txt")
	)
	FwExportRegistry $LogPrefixNetwork $RegKeysNetwork

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION NETWORKBasicFunc ####################

#################### FUNCTION NETWORKSETUPFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDNetworkSetup {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixNetwork = 'Network'
	LogInfo ("[$LogPrefixNetwork] Getting detailed network info.")
	$CommandsNetworkSetup = @(
		"netsh int tcp show global							| Out-File -Append $($Prefix)NETWORK_TCPIP_OFFLOAD.txt"
		"netsh int ipv4 show offload						| Out-File -Append $($Prefix)NETWORK_TCPIP_OFFLOAD.txt"
		"netstat -nato -p tcp								| Out-File -Append $($Prefix)NETWORK_TCPIP_OFFLOAD.txt"
		"netsh int show int									| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"netsh int ip show int								| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"netsh int ip show address							| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"netsh int ip show config							| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"netsh int ip show dns								| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"netsh int ip show joins							| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"netsh int ip show offload							| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"netsh int ip show wins								| Out-File -Append $($Prefix)NETWORK_TCPIP_netsh_info.txt"
		"nbtstat.exe -c										| Out-File -Append $($Prefix)NETWORK_WinsClient_nbtstat-output.txt"
		"nbtstat.exe -n										| Out-File -Append $($Prefix)NETWORK_WinsClient_nbtstat-output.txt"
		"net.exe config workstation							| Out-File -Append $($Prefix)NETWORK_SmbClient_info_net.txt"
		"net.exe statistics workstation						| Out-File -Append $($Prefix)NETWORK_SmbClient_info_net.txt"
		"net.exe use										| Out-File -Append $($Prefix)NETWORK_SmbClient_info_net.txt"
		"net.exe accounts									| Out-File -Append $($Prefix)NETWORK_SmbClient_info_net.txt"
		"net.exe accounts									| Out-File -Append $($Prefix)NETWORK_SmbServer_info_net.txt"
		"net.exe config server								| Out-File -Append $($Prefix)NETWORK_SmbServer_info_net.txt"
		"net.exe session									| Out-File -Append $($Prefix)NETWORK_SmbServer_info_net.txt"
		"net.exe files										| Out-File -Append $($Prefix)NETWORK_SmbServer_info_net.txt"
		"net.exe share										| Out-File -Append $($Prefix)NETWORK_SmbServer_info_net.txt"
		"netsh.exe rpc show int								| Out-File -Append $($Prefix)NETWORK_RPC_netsh_output.txt"
		"netsh.exe rpc show settings						| Out-File -Append $($Prefix)NETWORK_RPC_netsh_output.txt"
		"netsh.exe rpc filter show filter					| Out-File -Append $($Prefix)NETWORK_RPC_netsh_output.txt"
		"netsh.exe firewall show allowedprogram				| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show config						| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show currentprofile				| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show icmpsetting				| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show logging					| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show multicastbroadcastresponse	| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show notifications				| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show opmode						| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show portopening				| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show service					| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe firewall show state						| Out-File -Append $($Prefix)NETWORK_Firewall_netsh.txt"
		"netsh.exe ipsec dynamic show all					| Out-File -Append $($Prefix)NETWORK_IPsec_netsh_dynamic.txt"
		"netsh.exe ipsec static show all					| Out-File -Append $($Prefix)NETWORK_IPsec_netsh_static.txt"
		"netsh.exe ipsec static exportpolicy `"$($Prefix)NETWORK_IPsec_netsh_LocalPolicyExport.ipsec.txt`""
		"netsh.exe wlan show all							| Out-File -Append $($Prefix)NETWORK_Wireless_netsh.txt"
	)
	RunCommands $LogPrefixNetwork $CommandsNetworkSetup -ThrowException:$False -ShowMessage:$True

	LogInfo ("[$LogPrefixNetwork] Querying network registry keys.")
	# FwExportRegistry using -RealExport will overwrite any existing file
	$RegKeysNetwork = @(
		('HKCU:Network', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SOFTWARE\Policies\Microsoft\Windows\IPSec', "$($Prefix)NETWORK_IPsec_reg_.txt"),
		('HKLM:SOFTWARE\Microsoft\Rpc', "$($Prefix)NETWORK_RPC_reg.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Control\NetworkProvider', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\Dhcp', "$($Prefix)NETWORK_DhcpClient_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\Dnscache', "$($Prefix)NETWORK_DnsClient_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\IKEEXT', "$($Prefix)NETWORK_IPsec_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\iphlpsvc', "$($Prefix)NETWORK_TCPIP_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\LanManWorkstation', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\LanManServer', "$($Prefix)NETWORK_SmbServer_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\lmhosts', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\MrxSmb', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\MrxSmb10', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\MrxSmb20', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\MUP', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\NetBIOS', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\NetBT', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\PolicyAgent', "$($Prefix)NETWORK_IPsec_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\Rdbss', "$($Prefix)NETWORK_SmbClient_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\SharedAccess', "$($Prefix)NETWORK_Firewall_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\SRV2', "$($Prefix)NETWORK_SmbServer_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\SRVNET', "$($Prefix)NETWORK_SmbServer_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\TCPIP', "$($Prefix)NETWORK_TCPIP_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\Tcpip6', "$($Prefix)NETWORK_TCPIP_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\tcpipreg', "$($Prefix)NETWORK_TCPIP_reg_output.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\RpcEptMapper', "$($Prefix)NETWORK_RPC_reg.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\RpcLocator', "$($Prefix)NETWORK_RPC_reg.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\RpcSs', "$($Prefix)NETWORK_RPC_reg.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmbus', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\VMBusHID', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmicguestinterface', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmicheartbeat', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmickvpexchange', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmicrdv', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmicshutdown', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmictimesync', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt"),
		('HKLM:SYSTEM\CurrentControlSet\services\vmicvss', "$($Prefix)NETWORK_HyperVNetworking_reg_.txt")
	)
	FwExportRegistry $LogPrefixNetwork $RegKeysNetwork
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION NETWORKSETUPFunc ####################

#################### FUNCTION SLOWPROCESSINGFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDSlowProcessing {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# - Move things here that are not as critical, take a long time or are more prone to failure
	$LogPrefixSLOW = 'SLOW'
	LogInfo "[$LogPrefixSLOW] enter Slow processing section."
	LogInfo "[$LogPrefixSLOW]  Exporting servicing registry hives...may take several minutes." 'Cyan'
	LogInfo "[$LogPrefixSLOW]  Note, if this takes more than 15 minutes please stop the script and zip and upload all the data that have been captured to this point." 'Cyan'
	LogInfo "[$LogPrefixSLOW]  Data will be in folder $TempDir" 'Cyan'

	$Commands = @(
		"reg.exe save `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide`" `"$($Prefix)reg_SideBySide.hiv`""
		"reg.exe save `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing`" `"$($Prefix)reg_Component_Based_Servicing.hiv`""
		"reg.exe query `"HKLM\SYSTEM\CurrentControlSet\services\TrustedInstaller`" /s | Out-File -Append $($Prefix)reg_TrustedInstaller.txt"
		"reg.exe export `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide`" `"$($Prefix)reg_SideBySide.txt`""
	)
	RunCommands $LogPrefixSLOW $Commands -ThrowException:$False -ShowMessage:$True

	LogInfo "[$LogPrefixSLOW] checking drivers in SYSTEM\DriverDatabase against DriverStore\FileRepository."
	try {
		$systemDriverDatabase = 'HKLM:SYSTEM\DriverDatabase\DriverInfFiles'
		$property = 'Active'
		$driverInfFilesKeys = Get-ChildItem -Path $systemDriverDatabase
		FwCreateFolder $TempDir\logs\cbs

		foreach ($driverInfFilesKey in $driverInfFilesKeys) {
			$driverInfFilesKeyPath = $driverInfFilesKey.PSChildName
			$driverInfActiveProperty = ((Get-ItemProperty -Path "$systemDriverDatabase\$driverInfFilesKeyPath" -Name $property -ErrorAction SilentlyContinue).$property).Trim()
			$infName = ($driverInfActiveProperty -split '\.inf')[-2] + '.inf'

			if ($null -ne $driverInfActiveProperty) {
				if (!(Test-Path "$env:windir\System32\DriverStore\FileRepository\$driverInfActiveProperty")) {
					Write-Output "Missing DIR: $env:windir\System32\DriverStore\FileRepository\$driverInfActiveProperty" | Out-File -Append "$TempDir\logs\cbs\_missingInFileRepository.txt"
				}
				if (!(Test-Path "$env:windir\System32\DriverStore\FileRepository\$driverInfActiveProperty\$infName")) {
					Write-Output "Missing INF: $env:windir\System32\DriverStore\FileRepository\$driverInfActiveProperty\$infName" | Out-File -Append "$TempDir\logs\cbs\_missingInFileRepository.txt"
				}
			}
		}
	}
	catch { LogException ("[$LogPrefixSLOW] Something went wrong checking drivers in SYSTEM\DriverDatabase against DriverStore\FileRepository.") $_ }

	<#
	$sessionsXMLFile = "$env:windir\servicing\Sessions\Sessions.xml"
	if (Test-Path $sessionsXMLFile)
	{
		$sessionsXMLSize = (Get-Item $sessionsXMLFile).length/1MB
		$sessionsXMLSize = [math]::Round($sessionsXMLSize,2)
		if ($sessionsXMLSize -lt 150)
		{
			try
			{
				LogInfo ("[$LogPrefixCBS] sessions.xml size is $sessionsXMLSize MB - scanning for problematic sessions.")
				if ($size -gt 150)
				{
					LogInfo ("[$LogPrefixCBS] Processing of sessions.xml might take some time due to its size - please be patient.")
				}
				[xml]$data = Get-Content $sessionsXMLFile
				$sessionobj = @()
				foreach ($session in $data.sessions.session) {
					if (($session.status -ne '0x0') -and ($session.status -ne '0x800f0816') -and ($session.status -ne '0x800f0841')) {
						$sessionobj += [PsCustomObject]@{
							Date = $session.started
							Id = $session.tasks.phase.package.id
							KB = $session.tasks.phase.package.name
							Targetstate = $session.tasks.phase.package.targetState
							Status = $session.status
							Client = $session.client
						}
					}
				}
				if (0 -ne $sessionobj.Count) { $sessionobj | Sort-Object Date | Format-Table -Property * -AutoSize | Out-File "$TempDir\logs\cbs\CBS_sessions_xml_sum.txt" }
				elseif (0 -eq $sessionobj.Count) { Write-Output "No problematic session found." | Out-File "$TempDir\logs\cbs\CBS_sessions_xml_sum.txt" }
			}
			# catch "The input document has exceeded a limit set by MaxCharactersInDocument.")
			catch { LogException ("[$LogPrefixCBS] sessions.xml") $_ }
		}
		else {
			LogInfo ("[$LogPrefixCBS] sessions.xml is too big ($sessionsXMLSize MB), it would need too much time to process - skipping.")
			Write-Output "sessions.xml is too big ($sessionsXMLSize MB), it would need too much time to process - skipping." | Out-File "$TempDir\logs\cbs\CBS_sessions_xml_sum.txt"
		}
	}
#>
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION SLOWPROCESSINGFunc ####################

#################### FUNCTION GENERALPERFMONFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDGeneralPerfmon {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo ('[DND_SETUPReport] Getting 15 Seconds PerfMon_Setup-15sec')
	Logman.exe create counter PerfMon_Setup-15sec -o ($Prefix + 'PerfLog-Short.blg') -f bincirc -v mmddhhmm -max 300 -c '\LogicalDisk(*)\*' '\Memory\*' '\Cache\*' '\Network Interface(*)\*' '\Paging File(*)\*' '\PhysicalDisk(*)\*' '\Processor(*)\*' '\Processor Information(*)\*' '\Process(*)\*' '\Process V2(*)\*' '\Redirector\*' '\Server\*' '\System\*' '\Server Work Queues(*)\*' '\Terminal Services\*"' -si 00:00:01 >$null 2>> $ErrorFile
	Logman.exe start PerfMon_Setup-15sec >$null 2>>$ErrorFile
	Start-Sleep -Seconds 15
	Logman.exe stop PerfMon_Setup-15sec >$null 2>>$ErrorFile
	Logman.exe delete PerfMon_Setup-15sec >$null 2>>$ErrorFile
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION GENERALPERFMONFunc ####################

#################### FUNCTION RFLCheckPrereqsFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDRFLCheckPrereqs {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixRFL = 'RFL'
	LogInfo ("[$LogPrefixRFL] Getting RFLcheck prereqs.")

	if (!$global:IsLiteMode) {
		try {
			$outfile = "$($Prefix)Pstat.txt"
			$Commands = @(
				"$global:PstatExe | Out-File -Append $outfile"
			)
			RunCommands $LogPrefixRFL $Commands -ThrowException:$False -ShowMessage:$True
		}
		catch { LogException ("[$LogPrefixRFL] An Exception happend when running $global:PstatExe") $_ }
	}
	else { LogInfo 'Skipping Pstat in Lite mode' }

	# Make RFLcheck happy, create dummy _sym_.txt file, collect hotfix
	Write-Output $Line | Out-File -Append ($Prefix + 'sym_.csv')
	if (Test-Path $Scriptfolder\psSDP\Diag\global\results_SETUPreport.xml) { Copy-Item $Scriptfolder\psSDP\Diag\global\results_SETUPreport.xml $LogFolder`\results.xml -Force } #we#

	Get-CimInstance -ClassName win32_quickfixengineering | Out-File -FilePath "$($Prefix)Hotfix-WMIC.txt"
	if (Test-Path -Path "$($Prefix)Hotfix-WMIC.txt") {
		LogInfo ("[$LogPrefixRFL] Copying Hotfix-WMIC.txt")
		$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
		$SourceDestinationPaths.add(@("$($Prefix)Hotfix-WMIC.txt", "$($Prefix)Hotfixes.csv"))
		FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	}
	else {
		try {
			LogInfo ("[$LogPrefixRFL] Retrieve installed updates from Win32_QuickFixEngineering class.")
			Get-CimInstance -ClassName win32_quickfixengineering | Out-File -Append "$($Prefix)Hotfixes.csv"
		}
		catch { LogException ("[$LogPrefixRFL] Failed to retrieve installed updates from Win32_QuickFixEngineering class.") $_ }
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION GENERALPERFMONFunc ####################

#################### FUNCTION AppLockerFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDAppLocker {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixAppLocker = 'AppLocker'
	LogInfo ("[$LogPrefixAppLocker] Getting Applocker policy.")
	Get-AppLockerPolicy -Effective -Xml | Out-File -Append "$($Prefix)AppLockerPolicy.xml"

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION AppLockerFunc ####################

#################### FUNCTION DeviceGuardFunc ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDeviceGuard {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixCodeIntegrity = 'CodeIntegrity'
	$HVCIValue = 2
	$CIStateOff = 0
	$IsCIActive = $false
	$DGObj = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace 'root\Microsoft\Windows\DeviceGuard'

	if ($null -ne $DGObj) {
		try {
			for ($i = 0; $i -lt $DGObj.SecurityServicesRunning.length; $i++) {
				if ($DGObj.SecurityServicesRunning[$i] -eq $HVCIValue) {
					# HVCI is running
					$IsCIActive = $true
				}
			}

			for ($i = 0; $i -lt $DGObj.SecurityServicesConfigured.length; $i++) {
				if ($DGObj.SecurityServicesConfigured[$i] -eq $HVCIValue) {
					# HVCI is configured
					$IsCIActive = $true
				}
			}

			if ($DGObj.UsermodeCodeIntegrityPolicyEnforcementStatus -ne $CIStateOff) {
				# Usermode CI is running
				$IsCIActive = $true
			}

			if ($DGObj.CodeIntegrityPolicyEnforcementStatus -ne $CIStateOff) {
				# Kernelmode CI is running
				$IsCIActive = $true
			}

			# collect CIDIag output if anything above returned true
			if ($false -ne $IsCIActive) {
				FwCreateFolder $TempDir\CodeIntegrity
				LogInfo ("[$LogPrefixCodeIntegrity] Collect CIDiag output.")
				$CodeIntegrity = @(
					"CIDiag.exe /stop $TempDir\CodeIntegrity"
					"xcopy /s /e /c /i `"$env:windir\system32\CodeIntegrity\*.*`" `"$TempDir\CodeIntegrity`" /y"
				)
				RunCommands $LogPrefixCodeIntegrity $CodeIntegrity -ThrowException:$False -ShowMessage:$True

				# FwExportRegistry using -RealExport will overwrite any existing file
				$RegKeysDeviceGuard = @(
					('HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard', "$($Prefix)reg_DeviceGuard.txt"),
					('HKLM:SYSTEM\CurrentControlSet\Control\CI', "$TempDir\CodeIntegrity\reg_CI.txt")
				)
				FwExportRegistry $LogPrefixCodeIntegrity $RegKeysDeviceGuard
			}
		}
		catch {}
	}

	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DeviceGuardFunc ####################

#################### FUNCTION WUfBReport ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDWUfBReport {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixWUfBReport = 'WUfBReport'
	$WUfB_outfile = "$($Prefix)WUfB_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

	# Create the CSS style for the report
	$cssStyle = @'
	<style>
		body {
			font-family: Arial, sans-serif;
			padding: 20px;
			font-size: 14px;
			line-height: 1.6;
		}
		h1 {
			color: #336699;
			font-size: 2em;
		}
		h2 {
			color: #666666;
			font-size: 1.5em;
			margin-bottom: 5px;
		}
		p {
			color: #333333;
			font-size: 1em;
			margin: 5px 0;
		}
		.noconfig {
			color: #545454;
		}
		.success {
			color: #00aa00;
		}
		.warning {
			color: #f0ad4e;
		}
		.error {
			color: #ff0000;
		}
		.top {
			padding-top: 10px;
		}
	</style>
'@
	# Start logging
	LogInfo "[$LogPrefixWUfBReport] WUfB report diagnostic started."

	try {
		# Prepare the HTML content
		$htmlContent = @"
		<!DOCTYPE html>
		<html>
		<head>
			<meta charset="UTF-8">
			<title>WUfB Reporting Diagnostic Report</title>
			$cssStyle
		</head>
		<body>
			<h1>WUfB Reporting Diagnostic Report</h1>
			<p>[OS] Version: $_build.$_ubr</p>
			<p>[Info] Computer Name: $env:COMPUTERNAME </p>
"@

		$htmlContent += '<h2>Basic Requirement:</h2>'

		# Check if the device is AAD joined
		$IsAADJoined = Get-DNDAADStatus $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		if ($IsAADJoined) {
			$htmlContent += '<div class="success"><p>The device is Azure AD joined.</p></div>'
		}
		else {
			$htmlContent += '<div class="error"><p>The device is not Azure AD joined.</p></div>'
		}

		# Get Windows Required diagnostic data setting
		$DiagnosticDataSetting = Get-DNDWindowsDiagnosticDataSettings $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		if ($DiagnosticDataSetting) {
			if ($DiagnosticDataSetting -match "\b(?:Enhanced|Optional|Basic)\b") {
				$htmlContent += "<div class='success'><p>Windows Required diagnostic data setting is set to: <span class='success'>$DiagnosticDataSetting</span></p></div>"
			}
			else {
				$htmlContent += "<div class='success'><p>Windows Required diagnostic data setting is set to: <span class='error'>$DiagnosticDataSetting</span> <span>This needs to be Basic, Optional or Enhanced. Check https://aka.ms/uc-enrollment for more information.</span></p></div>"
			}
		}
		else {
			$htmlContent += "<div class='warning'><p>Failed to retrieve the Required diagnostic data setting.</p></div>"
		}

		$DiagnosticDataUpload = Get-DNDWindowsDiagnosticDataUpload $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		if ($DiagnosticDataUpload) {
			$htmlContent += "<div class='success'><p>Last successful DiagTrack upload (UTC): <span class='success'>$DiagnosticDataUpload</span></p></div>"
		}
		else {
			$htmlContent += "<div class='warning'><p>Last successful DiagTrack upload (UTC): <span class='error'>No telemetry data has been uploaded yet.</span></p></div>"
		}

		$RequiredPolicyResults = Get-DNDWUfBRequiredPolicies $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
				$htmlContent += '<h2>Required Policies Check:</h2>'
				foreach ($PolicyName in $RequiredPolicyResults.Keys) {
					$PolicyValue = $RequiredPolicyResults[$PolicyName]
					if ($PolicyValue -eq 'Disabled') {
						$htmlContent += "<div><b>$PolicyName</b> <span class='error'>$PolicyValue</span> (This policy should not be disabled, see: <a href='https://learn.microsoft.com/en-us/windows/deployment/update/wufb-reports-prerequisites#diagnostic-data-requirements'>Windows Update for Business reports prerequisites</a>)</p></div>"
					}
					elseif ($PolicyValue -eq 'Not Configured') {
						$htmlContent += "<div><b>$PolicyName</b> <span class='error'>$PolicyValue</span></div>"
					}
					else {
						$htmlContent += "<div><b>$PolicyName</b> <span class='success'>$PolicyValue</span></div>"
					}
				}
			# Adding DisableOneSettingsDownloads
				$CheckDisableOneSettingsDownloads = Get-DNDRegistryPolicy $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs -RegistryPath 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -ValueName 'DisableOneSettingsDownloads' -CheckValueData
		
				if ($CheckDisableOneSettingsDownloads -eq 1) {
					$htmlContent += '<h2>Found Not Recommended Policy Configured:</h2>'
					$htmlContent += "<div><b>OneSettings downloads are <span class='error'>disabled per policy.</span></b> </div>"
					$htmlContent += "<div class='error'><p>Disable OneSettings Downloads policy is enabled. (This policy should not be enabled, see: <a href='https://learn.microsoft.com/en-us/windows/deployment/update/wufb-reports-prerequisites#diagnostic-data-requirements'>Windows Update for Business reports prerequisites</a>)</p></div>"
				}
		


		$PolicyResults = Get-DNDWUfBRecommendedPolicies $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		$htmlContent += '<h2>Recommended Policies Check:</h2>'
		foreach ($PolicyName in $PolicyResults.Keys) {
			$PolicyValue = $PolicyResults[$PolicyName]
			if ($PolicyValue -eq 'Disabled') {
				$htmlContent += "<div><b>$PolicyName</b> <span class='warning'>$PolicyValue</span></div>"
			}
			elseif ($PolicyValue -eq 'Not Configured') {
				$htmlContent += "<div><b>$PolicyName</b> <span class='noconfig'>$PolicyValue</span></div>"
			}
			else {
				$htmlContent += "<div><b>$PolicyName</b> <span class='success'>$PolicyValue</span></div>"
			}
		}

		$DriverSearchResults = Get-DNDDriverSearch $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
		$htmlContent += '<h2>Driver Search / Update Policies Check:</h2>'
		foreach ($DriverKeyName in $DriverSearchResults.GetEnumerator()) {
			if ($DriverKeyName.Value -eq 'Disabled') {
				$htmlContent += "<div><b>$($DriverKeyName.Name)</b> <span class='success'>$($DriverKeyName.Value)</span></div>"
			}
			elseif ($DriverKeyName.Value -eq 'Not Configured') {
				$htmlContent += "<div><b>$($DriverKeyName.Name)</b> <span class='noconfig'>$($DriverKeyName.Value)</span></div>"
			}
			else {
				$htmlContent += "<div><b>$($DriverKeyName.Name)</b> <span class='warning'>$($DriverKeyName.Value)</span></div>"
			}
		}

		# Check wlidsvc and diagtrack service status
		$ServicesToCheck = @('wlidsvc', 'DiagTrack')
		$htmlContent += '<h2>Service Status:</h2>'
		foreach ($ServiceName in $ServicesToCheck) {
			$ServiceStatus = Get-DNDServiceStatus $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs -ServiceName $ServiceName
			if ($ServiceStatus) {
				$htmlContent += "<div><b>Service '$ServiceName':</b> <span class='success'>Enabled and running.</span></div>"
			}
			else {
				$htmlContent += "<div><b>Service '$ServiceName':</b> <span class='error'>Disabled or not running.</span></div>"
			}
		}

		# URLs to test
		$URLsToTest = @(
			'settings-win.data.microsoft.com',
			# depending on the address of the aad tenant (EU/EMEA vs. ROW)
			'eu-v10c.events.data.microsoft.com',
			'us-v10c.events.data.microsoft.com',
			'eu-watsonc.events.data.microsoft.com',
			# these were used on older (read now unsupported) versions of windows when the processor configuration was done via GPOs
			# "kmwatsonc.events.data.microsoft.com"
			# "umwatsonc.events.data.microsoft.com",
			# the default telemetry configuration
			'v10c.events.data.microsoft.com',
			'v20c.events.data.microsoft.com',
			'mystorageaccount.blob.core.windows.net'
		)
		# https://learn.microsoft.com/en-us/windows/privacy/manage-windows-11-endpoints
		# not related to the windows diagnostic data processor configuration
		#if ($_WIN11_OR_LATER) { $URLsToTest += @("self.events.data.microsoft.com") }

		$htmlContent += "<h2>Required URLs Test ($env:USERNAME):</h2>"
		foreach ($URL in $URLsToTest) {
			$status = Test-DNDURL $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs -URL $URL
			if ($status) {
				$htmlContent += "<div><b>$($URL.Replace('mystorageaccount','*')) - </b> <span class='success'>Reachable </span></div>"
			}
			else {
				$htmlContent += "<div class='error'><b>$($URL.Replace('mystorageaccount','*')) - </b> <span class='error'>Unreachable</span></div>"
			}
		}

		$htmlContent += '<h2>Required URLs Test (SYSTEM):</h2>'
		foreach ($URL in $URLsToTest) {
			$status = Test-DNDURL $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs -URL $URL -System
			if ($status) {
				$htmlContent += "<div><b>$($URL.Replace('mystorageaccount','*')) - </b> <span class='success'>Reachable </span></div>"
			}
			else {
				$htmlContent += "<div class='error'><b>$($URL.Replace('mystorageaccount','*')) - </b> <span class='error'>Unreachable</span></div>"
			}
		}

		
		# Successful execution message
		# $htmlContent += "<div class='success top'><p><b>Diagnostic report created successfully.</b> Log file path: $WUfB_outfile</p></div>"

		# Close the HTML content
		$htmlContent += @'
		</body>
		</html>
'@
		# Write the HTML content to the log file
		Add-Content -Path $WUfB_outfile -Value $htmlContent
	}
	catch {
		LogWarn "[$LogPrefixWUfBReport] an error occurred: $_"
	}
	finally {
		LogInfo "[$LogPrefixWUfBReport] Log file path: $WUfB_outfile"
		LogInfo "[$LogPrefixWUfBReport] WUfB report diagnostic finished."
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WUfBReport ####################

#################### FUNCTION AADStatus ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDAADStatus {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixAADStatus = 'AAD'
	LogInfo ("[$LogPrefixAADStatus] Getting AAD status.")
	try {
		# Use dsregcmd to get the device registration status
		$status = dsregcmd /status

		# Check if the device is Azure AD joined
		if ($status -match 'AzureAdJoined\s*:\s*YES') {
			# If the device is Azure AD joined, return true
			return $true
		}
		else {
			# If the device is not Azure AD joined, return false
			return $false
		}
	}
	catch {}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION AADStatus ####################

#################### FUNCTION WindowsDiagnosticDataSettings ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDWindowsDiagnosticDataSettings {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixWindowsDiagnosticDataSettings = 'WindowsDiagnosticDataSettings'
	LogInfo ("[$LogPrefixWindowsDiagnosticDataSettings] Getting Windows Diagnostic Data Settings.")
	try {
		# Define the registry paths to check for telemetry level values
		$DataCollection_GPO = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
		$DataCollection_default = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'

		# Check the minimum telemetry level value from GPO
		$GPOMinimumTelemetryLevel = Get-ItemProperty -Path $DataCollection_GPO -Name 'AllowTelemetry' -ErrorAction SilentlyContinue |
		Select-Object -ExpandProperty AllowTelemetry

		# Check the minimum telemetry level value from Intune
		$IntuneMinimumTelemetryLevel = Get-ItemProperty -Path $DataCollection_GPO -Name 'AllowTelemetry_PolicyManager' -ErrorAction SilentlyContinue |
		Select-Object -ExpandProperty AllowTelemetry_PolicyManager

		# Check the minimum telemetry level value from the default registry path
		$MinimumTelemetryLevel = Get-ItemProperty -Path $DataCollection_default -Name 'AllowTelemetry' -ErrorAction SilentlyContinue |
		Select-Object -ExpandProperty AllowTelemetry

		# Determine the TelemetryLevel based on priority: GPO > Intune > Default
		if ($GPOMinimumTelemetryLevel -ne $null) {
			$TelemetryLevel = $GPOMinimumTelemetryLevel
		}
		elseif ($IntuneMinimumTelemetryLevel -ne $null) {
			$TelemetryLevel = $IntuneMinimumTelemetryLevel
		}
		elseif ($MinimumTelemetryLevel -ne $null) {
			$TelemetryLevel = $MinimumTelemetryLevel
		}
		else {
			$TelemetryLevel = $null
		}

		# Return the telemetry level based on its value
		switch ($TelemetryLevel) {
			0 { return 'Security' }
			1 { return 'Basic' }
			2 { return 'Enhanced' }
			3 { return 'Optional' }
			default { return 'Unknown' }
		}
	}
	catch {}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WindowsDiagnosticDataSettings ####################

#################### FUNCTION WUfBRecommendedPolicies ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDWUfBRecommendedPolicies {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixWUfBRecommendedPolicies = 'WUfBReport'
	LogInfo ("[$LogPrefixWUfBRecommendedPolicies] Evaluating WUfB recommended Policies.")
	try {
		# Define the registry path to check
		$DataCollection_GPO = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'

		# Define the recommended policies to check
		$RecommendedPolicies = @(
			
			'DisableTelemetryOptInSettingsUx',
			'DisableTelemetryOptInChangeNotification'
		)

		# Create a hashtable to store the results
		$Results = @{}

		# Check if the registry path exists
		if (Test-Path -Path $DataCollection_GPO -ErrorAction SilentlyContinue) {
			# Get the properties only if the path exists
			$PolicyProperties = Get-ItemProperty -Path $DataCollection_GPO -ErrorAction SilentlyContinue

			# Loop through the recommended policies
			foreach ($Policy in $RecommendedPolicies) {
				# Check if the policy is configured
				if ($PolicyProperties -and $PolicyProperties.PSObject.Properties.Name -contains $Policy) {
					# If the policy is configured, check its value
					if ($PolicyProperties.$Policy -eq 0) {
						$Results[$Policy] = 'Disabled'
					}
					else {
						$Results[$Policy] = 'Enabled'
					}
				}
				else {
					# If the policy is not configured, set the result to "Not Configured"
					$Results[$Policy] = 'Not Configured'
				}
			}
		}
		else {
			# If the registry path does not exist, write a warning message
			Write-Warning "Registry path not found: $DataCollection_GPO"
		}

		# Return the results hashtable
		return $Results
	}
	catch {}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WUfBRecommendedPolicies ####################

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDWUfBRequiredPolicies {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixWUfBRequiredPolicies = 'WUfBReport'
	LogInfo ("[$LogPrefixWUfBRequiredPolicies] Evaluating WUfB required Policies.")
	try {
		# Define the registry path to check
		$DataCollection_GPO = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'

		# Define the required policies to check
		$requiredPolicies = @(
			'AllowDeviceNameInTelemetry'
		)

		# Create a hashtable to store the results
		$Results = @{}

		# Check if the registry path exists
		if (Test-Path -Path $DataCollection_GPO -ErrorAction SilentlyContinue) {
			# Get the properties only if the path exists
			$PolicyProperties = Get-ItemProperty -Path $DataCollection_GPO -ErrorAction SilentlyContinue

			# Loop through the required policies
			foreach ($Policy in $requiredPolicies) {
				# Check if the policy is configured
				if ($PolicyProperties -and $PolicyProperties.PSObject.Properties.Name -contains $Policy) {
					# If the policy is configured, check its value
					if ($PolicyProperties.$Policy -eq 0) {
						$Results[$Policy] = 'Disabled'
					}
					else {
						$Results[$Policy] = 'Enabled'
					}
				}
				else {
					# If the policy is not configured, set the result to "Not Configured"
					$Results[$Policy] = 'Not Configured'
				}
			}
		}
		else {
			# If the registry path does not exist, write a warning message
			Write-Warning "Registry path not found: $DataCollection_GPO"
		}

		# Return the results hashtable
		return $Results
	}
	catch {}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WUfBRequiredPolicies ####################

#################### FUNCTION DriverSearch ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDDriverSearch {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixDriverSearch = 'DriverSearch'
	LogInfo ("[$LogPrefixDriverSearch] Evaluating driver search and update configuration.")

	try {
		# Define the registry paths to check
		$DriverSearching_GPO = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching'
		$Update_GPO = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update'
		$WindowsUpdate_GPO = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
		$DSS_Enrollment = 'HKLM:\SOFTWARE\Microsoft\WufbDS'

		# Define the recommended policies to check
		$DriverSearchPolicies = @(
			'DontPromptForWindowsUpdate',
			'DriverServerSelection',
			'DontSearchWindowsUpdate',
			'SearchOrderConfig'
		)

		# Create a hashtable to store the results
		$results = @{}

		# Check if the DriverSearching_GPO registry path exists
		if (Test-Path -Path $DriverSearching_GPO -ErrorAction SilentlyContinue) {
			# Get the properties only if the path exists
			$PolicyProperties = Get-ItemProperty -Path $DriverSearching_GPO -ErrorAction SilentlyContinue

			# Loop through the recommended policies
			foreach ($Policy in $DriverSearchPolicies) {
				# Check if the policy is configured
				if ($PolicyProperties -and $PolicyProperties.PSObject.Properties.Name -contains $Policy) {
					# If the policy is configured, add its name and value to the results hashtable
					$results[$Policy] = $PolicyProperties.$Policy
				}
				else {
					# If the policy is not configured, set the result to "Not Configured"
					$results[$Policy] = 'Not Configured'
				}
			}
		}
		else {
			# If the DriverSearching_GPO registry path does not exist, add a message to the results hashtable indicating that driver search is not configured
			$results['DriverSearch'] = 'Not Configured'
		}

		# Define an array of registry paths to check for the ExcludeWUDriversInQualityUpdate policy
		$UpdatePaths = @($Update_GPO, $WindowsUpdate_GPO)

		# Loop through the registry paths and check if the ExcludeWUDriversInQualityUpdate policy is enabled
		foreach ($Path in $UpdatePaths) {
			if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
				# Get the properties only if the path exists
				$PolicyProperties = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue

				# Check if the ExcludeWUDriversInQualityUpdate policy is enabled
				if ($PolicyProperties -and $PolicyProperties.PSObject.Properties.Name -contains 'ExcludeWUDriversInQualityUpdate') {
					if ($PolicyProperties.ExcludeWUDriversInQualityUpdate -eq 1) {
						$results['ExcludeWUDriversInQualityUpdate'] = 'Enabled'
						break
					}
					elseif ($PolicyProperties.ExcludeWUDriversInQualityUpdate -eq 0) {
						$results['ExcludeWUDriversInQualityUpdate'] = 'Disabled'
						break
					}
				}
			}
		}

		# If the ExcludeWUDriversInQualityUpdate policy is not enabled, set the result to "Not Configured"
		if (!$results.ContainsKey('ExcludeWUDriversInQualityUpdate')) {
			$results['ExcludeWUDriversInQualityUpdate'] = 'Not Configured'
		}

		# Check if the system is enrolled into DSS for driver updates
		if (Test-Path -Path $DSS_Enrollment -ErrorAction SilentlyContinue) {
			$DSSProperties = Get-ItemProperty -Path $DSS_Enrollment -ErrorAction SilentlyContinue
			if ($DSSProperties -and $DSSProperties.PSObject.Properties.Name -contains 'DriversUpdate') {
				$results['DriversUpdateDSSenrolled'] = 'Enabled'
			}
		}

		# If the system is not enrolled into DSS for driver updates, set the result to "Not Configured"
		if (!$results.ContainsKey('DriversUpdateDSSEnrolled')) {
			$results['DriversUpdateDSSEnrolled'] = 'Not Configured'
		}

		return $results

	}
 catch {
		# If an error occurs, write a warning message and return an empty hashtable
		LogWarn "An error occurred while checking the registry path: $($_.Exception.Message)"
		return @{}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION DriverSearch ####################

#################### FUNCTION ServiceStatus ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDServiceStatus {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null,

		[Parameter()]
		[string] $ServiceName
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixServiceStatus = 'ServiceState'
	LogInfo ("[$LogPrefixServiceStatus] Getting Service status for '$ServiceName'.")
	# Try to get the service with the specified name
	try {
		$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

		# If the service exists, check if its start type is not Disabled
		if ($service) {
			return $service.StartType -ne [System.ServiceProcess.ServiceStartMode]::Disabled
		}
		else {
			# If the service does not exist, return false
			return $false
		}
	}
	catch {
		# If an exception occurs, return false
		return $false
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION ServiceStatus ####################

#################### FUNCTION Test-URL ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Test-DNDURL {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null,

		[Parameter()]
		[string] $URL,

		[Parameter()]
		[switch]$System
	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixURL = 'URL'
	$PsExec = "$global:ScriptFolder\BIN\PsExec.exe"
	# Try to test the network connection to the specified URL and port
	try {
		if ($System -and (Test-Path $PsExec)) {
			LogInfo ("[$LogPrefixURL][SYSTEM] Testing connection to '$URL'.")
			# Use the Test-NetConnection cmdlet to test the connection to the URL and port
			$psexecOutput = Invoke-Expression "$PsExec -s -accepteula -nobanner powershell -c 'Test-NetConnection $URL -Port 443'" 2>$null

			# Extract the value of TcpTestSucceeded using a regular expression
			$tcpTestSucceededValue = $psexecOutput | Select-String -Pattern '\b(True|False)\b' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
			$tcpTestSucceeded = [bool]::Parse($tcpTestSucceededValue)

			# Create a custom PowerShell object with the extracted information
			$response = [PSCustomObject]@{
				TcpTestSucceeded = $tcpTestSucceeded
			}
			# Now $psExecResult is a PowerShell object that you can work with
			# $response.TcpTestSucceeded
		}
		else {
			LogInfo ("[$LogPrefixURL] Testing connection to '$URL'.")
			# Use the Test-NetConnection cmdlet to test the connection to the URL and port
			$response = Test-NetConnection $URL -Port 443
		}
		if ($response.TcpTestSucceeded) {
			# If the connection test succeeds, return true
			return $true
		}
		else {
			return $false
		}
	}
	catch {
		# If an exception occurs, return false
		return $false
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION Test-URL ####################

#################### FUNCTION RegistryPolicy ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDRegistryPolicy {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null,

		[Parameter()]
		[string]$RegistryPath,

		[Parameter()]
		[string]$ValueName,

		[Parameter()]
		[switch]$CheckValueData

	)
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefixRegistryPolicy = 'RegistryPolicy'
	LogInfo ("[$LogPrefixRegistryPolicy] Getting Registry Policy for '$RegistryPath'.")
	# Check if the registry path exists
	if (Test-Path -Path $RegistryPath) {
		# Try to get the registry value
		try {
			$value = (Get-ItemProperty -Path $RegistryPath).$ValueName

			# Check if the value is not null
			if ($value -ne $null) {
				# If CheckValueData is true, return the value
				if ($CheckValueData) {
					return $value
				}
				else {
					# Otherwise, return true
					return $true
				}
			}
			else {
				# If the value is null, return false
				return $false
			}
		}
		catch {
			# If an exception occurs, return false
			return $false
		}
	}
	else {
		# If the registry path does not exist, return false
		return $false
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION RegistryPolicy ####################

#################### FUNCTION WindowsDiagnosticDataUpload ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDWindowsDiagnosticDataUpload {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixWindowsDiagnosticDataSettings = 'WindowsDiagnosticDataSettings'
	LogInfo ("[$LogPrefixWindowsDiagnosticDataSettings] Getting Windows Diagnostic 'LastSuccessfulNormalUploadTime'.")
	try {
		$LastSuccessfulNormalUploadTime = $null
		# Define the registry path to check
		$DiagTrack = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack'

		if (Test-Path -Path $DiagTrack -ErrorAction SilentlyContinue) {
			<#
			# Example if the exported value in a text file is hex(b):26,49,8a,d2,f4,12,d6,01 -> (dec) 01d612f4d28a4926 -> (UTC)  Wednesday, April 15, 2020 7:09:36 AM
			# https://stackoverflow.com/questions/32202411/read-registery-value-and-convert-to-date
			# Define the encoded registry value as a string
			$DiagTrackUploadEncoded = '26,49,8a,d2,f4,12,d6,01'
			# Split the encoded string into an array of bytes
			$DiagTrackUploadEncoded = $DiagTrackUploadEncoded.Split(',')
			# Reverse the byte order in the array
			[array]::reverse($DiagTrackUploadEncoded)
			# Join the bytes back into a single string
			$DiagTrackUploadEncoded = $DiagTrackUploadEncoded -join ''
			# Convert the hexadecimal string to a decimal number
			$asDecimal = [System.Convert]::ToInt64($DiagTrackUploadEncoded, 16)
			# Convert the decimal number to a DateTime object
			$date = [DateTime]::FromFileTime($asDecimal)
			# Convert the DateTime object to UTC time and output it
			($date).ToUniversalTime()
		#>
			$LastSuccessfulNormalUploadTime = Get-ItemProperty -Path $DiagTrack -Name 'LastSuccessfulNormalUploadTime' -ErrorAction SilentlyContinue |
			Select-Object -ExpandProperty LastSuccessfulNormalUploadTime
			try {
				$LastSuccessfulNormalUploadTime = ([DateTime]::FromFileTime($LastSuccessfulNormalUploadTime)).ToUniversalTime()
				# if the year is 1601, the upload did not happen yet, return $null
				if ($LastSuccessfulNormalUploadTime -like '*1601*') {
					$LastSuccessfulNormalUploadTime = $null
					return $LastSuccessfulNormalUploadTime
				}
				else {
					return $LastSuccessfulNormalUploadTime
				}
			}
			catch [System.ArgumentException] {
				# Write-Host "Error: Argument types do not match. Please check the value of `$LastSuccessfulNormalUploadTime`."
				$LastSuccessfulNormalUploadTime = 'Wrong argument type.'
				return $LastSuccessfulNormalUploadTime
			}
		}
		else {
			# If the registry path does not exist, write a warning message
			return $LastSuccessfulNormalUploadTime
		}
	}
	catch {}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WindowsDiagnosticDataUpload ####################

#################### FUNCTION MDMInfo ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function Get-DNDMDMInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixMDMinfo = 'MDMInfo'
	LogInfo ("[$LogPrefixMDMinfo] Getting MDM related info.")
	try {
		# Get MDM Info
		if (Test-Path $env:windir\system32\MDMDiagnosticsTool.exe) {
			FwCreateFolder $TempDir\MDMDiag
			LogInfo ("[$LogPrefixMDMinfo] Running MDMDiagnosticsTool.")
			$MDM = @(
				"cmd /r $env:windir\system32\MDMDiagnosticsTool.exe -out $TempDir\MDMDiag\"
				"cmd /r $env:windir\system32\MDMDiagnosticsTool.exe -area 'Autopilot;DeviceEnrollment' -cab $TempDir\MDMDiag\AutopilotDeviceEnrollmentTpmDiag.cab"
			)
			RunCommands $LogPrefixMDMinfo $MDM -ThrowException:$False -ShowMessage:$True

			#Specifying TMP causes error on non-TPM machines. Removing it
			#cmd /r "$env:windir\system32\MDMDiagnosticsTool.exe" -area 'Autopilot;DeviceEnrollment;Tpm' -cab "$TempDir\MDMDiag\AutopilotDeviceEnrollmentTpmDiag.cab" >$null 2>>$null
			<# duplicate, see below
			LogInfo ("[$LogPrefixMDMinfo] Querying MDM PolicyManager keys.")
			$RegKeysMDM = @(
				('HKLM:SOFTWARE\Microsoft\PolicyManager')
			)
			FwExportRegToOneFile $LogPrefixMDMinfo $RegKeysMDM "$TempDir\MDMDiag\REG_PolicyManager.txt"
			#>
		}

		LogInfo ("[$LogPrefixMDMinfo] Export by querying registry keys.")
		# FwExportRegistry is using the /s (recursive) switch by default and appends to an existing file
		$RegKeysMDMInfoQuery = @(
			('HKLM:SOFTWARE\Microsoft\PolicyManager', "$($Prefix)reg_PolicyManager.txt"),
			('HKLM:SOFTWARE\Microsoft\SQMClient', "$($Prefix)reg_SQMClient.txt")
		)
		FwExportRegistry $LogPrefixMDMinfo $RegKeysMDMInfoQuery

		$LIDregKeyPath = 'HKU:\.DEFAULT\Software\Microsoft\IdentityCRL\ExtendedProperties'
		$LIDpropertyName = 'LID'
		$psDriveName = 'HKU'
		if (-not (Test-Path -Path "Registry::$LIDregKeyPath") -and -not (Get-PSDrive -Name $psDriveName -ErrorAction SilentlyContinue)) {
			New-PSDrive -Name $psDriveName -PSProvider Registry -Root HKEY_USERS | Out-Null
		}
		if (Test-Path $LIDregKeyPath) {
			LogInfo ("[$LogPrefixMDMinfo] Trying to retrieve global device ID.")
			try {
				$LIDValue = Get-ItemProperty -Path $LIDregKeyPath -Name $LIDpropertyName
				# Convert the hexadecimal "LID" value to a formatted string
				$LIDFormatted = 'g:{0}' -f [Int64]"0x$($LIDValue.LID)"
				LogInfo ('[MiscInfo] Retrieved global device ID.')
				Write-Output $LIDregKeyPath | Out-File -Append ($Prefix + 'reg_LID.txt')
				Write-Output $line | Out-File -Append ($Prefix + 'reg_LID.txt')
				Write-Output "LID (value in registry):`t$($LIDValue.LID)" | Out-File -Append ($Prefix + 'reg_LID.txt')
				Write-Output "LID (formatted):`t`t`t`t`t$LIDFormatted" | Out-File -Append ($Prefix + 'reg_LID.txt')
				Remove-PSDrive -Name HKU
			}
			catch {
				LogWarn ("[$LogPrefixMDMinfo] Failed to retrieve global device ID.")
			}
		}
	}
	catch {}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION MDMInfo ####################


#################### FUNCTION WinREInfo ####################
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Feature 605: DnD - WinRE information
function Get-DNDWinREInfo {
	Param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string] $Prefix,

		[Parameter()]
		[string] $TempDir = $null,

		[Parameter()]
		[string] $RobocopyLog = $null,

		[Parameter()]
		[string] $ErrorFile = $null,

		[Parameter()]
		[string] $Line = $null,

		[Parameter()]
		[int] $FlushLogs = $null
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefixWinRE = 'WinRE'
	LogInfo ("[$LogPrefixWinRE] Getting WinRE related info.")

	try {
		# Get WinRE info, instead of using reagentc /mountre which is available only from VB / Windows 10 2004
		$WinREInfo = Reagentc /info
		$findLocation = $False
		foreach ($line in $WinREInfo) {
			$params = $line.Split(':')
			if ($params.count -le 1) {
				continue
			}
			if ($params[1].Lenght -eq 0) {
				continue
			}
			$content = $params[1].Trim()
			if ($content.Lenght -eq 0) {
				continue
			}
			$index = $content.IndexOf('\\?\')
			if ($index -ge 0) {
				LogInfo ("[$LogPrefixWinRE] Find \\?\ at $index for [`"$content`"]")
				$WinRELocation = $content
				$findLocation = $True
			}
		}
		if (!$findLocation) {
			LogWarn ("[$LogPrefixWinRE] WinRE Disabled")
		}
		LogInfo ("[$LogPrefixWinRE] WinRE Enabled. WinRE location: $WinRELocation")
		$WinREFile = $WinRELocation + '\winre.wim'

		LogInfo ("[$LogPrefixWinRE] Use default path from temporary directory")
		$workDir = [System.IO.Path]::GetTempPath()

		LogInfo ("[$LogPrefixWinRE] Working Dir: $workDir")
		$name = 'd5a7d3dc-d775-491f-8d8b-6b5818ee670e_WinRE_mount'
		$mountDir = Join-Path $workDir $name

		LogInfo ("[$LogPrefixWinRE] MountDir: $mountdir")
		# Delete existing mount directory
		if (Test-Path $mountDir) {
			LogInfo ("[$LogPrefixWinRE] Mount directory: $mountDir already exists")
			LogInfo ("[$LogPrefixWinRE] Try to unmount it")
			$CommandsWinRE = @(
				"dism /unmount-image /mountDir:$mountDir /discard"
			)
			RunCommands $LogPrefixWinRE $CommandsWinRE -ThrowException:$False -ShowMessage:$True
			if (!($LASTEXITCODE -eq 0)) {
				LogException ("[$LogPrefixWinRE] Warning: unmount failed: $LASTEXITCODE")
			}
			LogInfo ("[$LogPrefixWinRE] Delete existing mount directory: $mountDir")
			Remove-Item $mountDir -Recurse
		}
		# Create mount directory
		LogInfo ("[$LogPrefixWinRE] Create mount directory  $mountDir and set ACLs")
		FwCreateFolder $mountDir
		$CommandsWinRE = @(
			"icacls $mountDir /inheritance:r"
			"icacls $mountDir /grant:r SYSTEM:`"(OI)(CI)(F)`""
			"icacls $mountDir /grant:r *S-1-5-32-544:`"(OI)(CI)(F)`""
		)
		RunCommands $LogPrefixWinRE $CommandsWinRE -ThrowException:$False -ShowMessage:$True

		# Mount WinRE
		LogInfo ("[$LogPrefixWinRE] Mount WinRE: $WinREFile")
		$CommandsWinRE = @(
			"dism /mount-image /imagefile:$WinREFile /index:1 /mountdir:$mountDir"
		)
		RunCommands $LogPrefixWinRE $CommandsWinRE -ThrowException:$False -ShowMessage:$True
		if ($LASTEXITCODE -eq 0) {
			LogInfo "[$LogPrefixWinRE] Getting packages from: $mountDir"
			$CommandsWinRE = @(
				"dism /english /image:$mountDir /Get-Packages /Format:Table		| Out-File -Append $($Prefix)dism_WinRE_GetPackages.txt"
				"dism /english /image:$mountDir /Get-Packages					| Out-File -Append $($Prefix)dism_WinRE_GetPackages.txt"
			)
			RunCommands $LogPrefixWinRE $CommandsWinRE -ThrowException:$False -ShowMessage:$True

			LogInfo ("[$LogPrefixWinRE] Unmounting image: $WinREFile")
			$CommandsWinRE = @(
				"dism /unmount-image /mountDir:$mountDir /discard"
			)
			RunCommands $LogPrefixWinRE $CommandsWinRE -ThrowException:$False -ShowMessage:$True
			if (!($LASTEXITCODE -eq 0)) {
				LogException ("[$LogPrefixWinRE] Unmount failed: $LASTEXITCODE")
			}
		}
		else {
			LogInfo ("[$LogPrefixWinRE] Mount failed: " + $LASTEXITCODE)
		}
		# Cleanup Mount directory in the end
		LogInfo ("[$LogPrefixWinRE] Delete mount directory: $mountDir")
		Remove-Item $mountDir -Recurse
	}
	catch {
		LogWarn ("[$LogPrefixWinRE] ERROR: at $($_.InvocationInfo.ScriptLineNumber)")
		LogWarn ("[$LogPrefixWinRE] Message: $($_.Exception.Message)")
	}
	EndFunc $MyInvocation.MyCommand.Name
}
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#################### END OF FUNCTION WinREInfo ####################


#For DnDCollector
# "DnDCollector" replace the previously released script "SetupCollector".
Function CollectDND_SETUPLog {
	EnterFunc $MyInvocation.MyCommand.Name
	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}

	$global:ParameterArray += 'noBasicLog'

	# =================================================================
	# Create Output Folder and Log File
	# =================================================================
	LogInfo '>>> Creating Output Folder' 'White'
	LogInfoFile '>>> Create Output Folder'

	$_EXPORTDIR = "$LogFolder\DnDLog$LogSuffix"
	FwCreateFolder $_EXPORTDIR

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'

	# =================================================================
	# Collect System information
	# =================================================================
	LogInfo '>>> Collecting System information' 'White'
	LogInfoFile '>>> Collecting System information'

	$null = New-Item -Path ($_EXPORTDIR + '\System') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	#General
	LogInfo '  > phase 1/4' 'White'
	gpresult /h ($_EXPORTDIR + '\System\gpresult.html') >> ($global:ErrorLogFile) 2>&1
	try {
		FwGetMsInfo32 'nfo' -Subfolder "DnDLog$LogSuffix\System"
	}
	catch { LogInfoFile 'Failed to collect MsInfo32' }
	systeminfo > ($_EXPORTDIR + '\System\systeminfo.txt') 2>&1
	Write-Output $global:OperatingSystemInfo | Out-File -Append ($_EXPORTDIR + '\System\ver.txt') 2>&1
	Write-Output "UBR: $_ubr" | Out-File -Append ($_EXPORTDIR + '\System\ver.txt') 2>&1

	whoami.exe /all > ($_EXPORTDIR + '\System\whoami_all.txt') 2>&1
	net user > ($_EXPORTDIR + '\System\net_user.txt') 2>&1

	Get-HotFix | Select-Object * | Out-File -Append ($_EXPORTDIR + '\System\Get-Hotfix.txt') 2>&1
	Get-WmiObject Win32_QuickFixEngineering | Format-Table -AutoSize | Out-File -Append ($_EXPORTDIR + '\System\wmic_qfe_list.txt') >> ($global:ErrorLogFile) 2>&1

	bcdedit /enum all > ($_EXPORTDIR + '\System\bcdedit_enum_all.txt') 2>&1
	reagentc /info > ($_EXPORTDIR + '\System\reagentc_info.txt') 2>&1
	compact /CompactOS:query > ($_EXPORTDIR + '\System\compactos_query.txt') 2>&1
	Get-WinUserLanguageList | Format-List * | Out-File -Append ($_EXPORTDIR + '\System\Get-WinUserLanguageList.txt') 2>&1

	schtasks /query /v > ($_EXPORTDIR + '\System\schtasks_query_v.txt') 2>&1
	schtasks /query /v /FO CSV > ($_EXPORTDIR + '\System\schtasks_query_v.csv') 2>&1
	Get-ScheduledTask | Select-Object * | Out-File -Append ($_EXPORTDIR + '\System\Get-ScheduledTask.txt') 2>&1
	tasklist > ($_EXPORTDIR + '\System\tasklist.txt') 2>&1
	tasklist /M > ($_EXPORTDIR + '\System\tasklist_M.txt') 2>&1
	tasklist /V > ($_EXPORTDIR + '\System\tasklist_V.txt') 2>&1
	tasklist /SVC > ($_EXPORTDIR + '\System\tasklist_SVC.txt') 2>&1
	Get-Process | Format-Table -Property 'Handles', 'NPM', 'PM', 'WS', 'VM', 'CPU', 'Id', 'ProcessName', 'StartTime', @{ Label = 'Running Time'; Expression = { (GetAgeDescription -TimeSpan (New-TimeSpan $_.StartTime)) } } -AutoSize | Out-File -Append ($_EXPORTDIR + '\System\Get-Process.txt') 2>&1
	Get-WmiObject Win32_Process | Format-List * | Out-File -Width 4096 -Append ($_EXPORTDIR + '\System\Win32_Process.txt') 2>&1

	# Cert
	LogInfo '  > phase 2/4' 'White'
	certutil -store root > ($_EXPORTDIR + '\System\certutil_store_root.txt') 2>&1
	cmd /r copy ($env:windir + '\System32\catroot2\dberr.txt') ($_EXPORTDIR + '\System\catroot2_dberr.txt') >> ($global:ErrorLogFile) 2>&1

	# Network
	LogInfo '  > phase 3/4' 'White'
	bitsadmin /list /AllUsers /Verbose > ($_EXPORTDIR + '\System\BitsAdmin.txt') 2>&1
	ipconfig /all > ($_EXPORTDIR + '\System\ipconfig-all.txt') 2>&1
	netsh advfirewall firewall show rule name=all > ($_EXPORTDIR + '\System\firewall.txt') 2>&1
	netsh winhttp show proxy > ($_EXPORTDIR + '\System\winhttp_show_proxy.txt') 2>&1
	cmd /r copy ($env:windir + '\System32\drivers\etc\hosts') ($_EXPORTDIR + '\System\hosts.txt') >> ($global:ErrorLogFile) 2>&1

	# Other
	LogInfo '  > phase 4/4' 'White'
	if ( $OperatingSystemInfo.OSVersion -ge 10 ) {
		pnputil.exe /export-pnpstate ($_EXPORTDIR + '\System\pnpstate.pnp') >> ($global:ErrorLogFile) 2>&1
		MdmDiagnosticsTool.exe -area DeviceEnrollment -cab ($_EXPORTDIR + '\System\MDMDiagReport.cab') >> ($global:ErrorLogFile) 2>&1
		dsregcmd /status > ($_EXPORTDIR + '\System\dsregcmd_status.txt') 2>&1
	}
	Get-CimInstance -ClassName Win32_PnPSignedDriver | Select-Object * | Out-File -Append ($_EXPORTDIR + '\System\Win32_PnPSignedDriver.txt') 2>&1
	dispdiag.exe -out ($_EXPORTDIR + '\System\DispDiag.dat') >> ($global:ErrorLogFile) 2>&1
	powercfg /a > ($_EXPORTDIR + '\System\power_a.txt') 2>&1
	powercfg /qh > ($_EXPORTDIR + '\System\power_qh.txt') 2>&1
	powercfg /list > ($_EXPORTDIR + '\System\power_l.txt') 2>&1
	powercfg /sleepstudy /duration 28 /OUTPUT ($_EXPORTDIR + '\System\power_sleepstudy.html') >> ($global:ErrorLogFile) 2>&1
	powercfg /batteryreport /duration 14 /OUTPUT ($_EXPORTDIR + '\System\power_batteryreport.html') >> ($global:ErrorLogFile) 2>&1
	powercfg /energy /duration 1 /OUTPUT ($_EXPORTDIR + '\System\power_energy.html') >> ($global:ErrorLogFile) 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect DISM information
	# =================================================================
	LogInfo '>>> Collect DISM information' 'White'
	LogInfoFile '>>> Collect DISM information'

	$null = New-Item -Path ($_EXPORTDIR + '\Dism') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/1' 'White'
	Dism /english /Online /Get-Intl > ($_EXPORTDIR + '\Dism\Get-Intl.txt') 2>&1
	Dism /english /Online /Get-Packages /Format:Table > ($_EXPORTDIR + '\Dism\Get-Packages.txt') 2>&1
	Dism /english /Online /Get-Features /Format:Table > ($_EXPORTDIR + '\Dism\Get-Features.txt') 2>&1
	Dism /english /Online /Get-Capabilities /Format:Table > ($_EXPORTDIR + '\Dism\Get-Capabilities.txt') 2>&1
	Dism /english /Online /Get-OSUninstallWindow > ($_EXPORTDIR + '\Dism\Get-OSUninstallWindow.txt') 2>&1
	Dism /english /Online /Get-DefaultAppAssociations > ($_EXPORTDIR + '\Dism\Get-DefaultAppAssociations.txt') 2>&1
	Dism /english /Online /Export-DefaultAppAssociations:"$_EXPORTDIR\Dism\Export-DefaultAppAssociations.xml" >> ($global:ErrorLogFile) 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect Disk information
	# =================================================================
	LogInfo '>>> Collect Disk information' 'White'
	LogInfoFile '>>> Collect Disk information'

	$null = New-Item -Path ($_EXPORTDIR + '\Disk') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/1' 'White'
	Get-Disk | Select-Object * | Out-File -Append ($_EXPORTDIR + '\Disk\Get-Disk.txt') 2>&1
	Get-PhysicalDisk | Select-Object * | Out-File -Append ($_EXPORTDIR + '\Disk\Get-Physicaldisk.txt') 2>&1
	Get-VirtualDisk | Select-Object * | Out-File -Append ($_EXPORTDIR + '\Disk\Get-VirtualDisk.txt') 2>&1
	Get-Partition | Select-Object * | Out-File -Append ($_EXPORTDIR + '\Disk\Get-Partition.txt') 2>&1
	Get-Volume | Select-Object * | Out-File -Append ($_EXPORTDIR + '\Disk\Get-Volume.txt') 2>&1

	Get-WmiObject Win32_DiskDrive | Format-List * | Out-File -Append ($_EXPORTDIR + '\Disk\Win32_DiskDrive.txt') 2>&1
	Get-WmiObject Win32_DiskPartition | Format-List * | Out-File -Append ($_EXPORTDIR + '\Disk\Win32_DiskPartition.txt') 2>&1
	Get-WmiObject Win32_LogicalDiskToPartition | Format-List * | Out-File -Append ($_EXPORTDIR + '\Disk\Win32_LogicalDiskToPartition.txt') 2>&1
	Get-WmiObject Win32_LogicalDisk | Format-List * | Out-File -Append ($_EXPORTDIR + '\Disk\Win32_LogicalDisk.txt') 2>&1
	Get-WmiObject Win32_Volume | Format-List * | Out-File -Append ($_EXPORTDIR + '\Disk\Win32_Volume.txt') 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect BitLocker information
	# =================================================================
	LogInfo '>>> Collect BitLocker information' 'White'
	LogInfoFile '>>> Collect BitLocker information'

	$null = New-Item -Path ($_EXPORTDIR + '\BitLocker') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/1' 'White'
	if (Test-Path $env:windir\system32\manage-bde.exe) {
		manage-bde -status > ($_EXPORTDIR + '\BitLocker\manage-bde_status.txt') 2>&1
	}
	else {
		LogInfoFile "couldn't find manage-bde.exe"
	}

	try {
		Get-BitLockerVolume | Format-List * | Out-File -Append ($_EXPORTDIR + '\BitLocker\Get-BitLockerVolume.txt') 2>&1
		Get-BitLockerVolume | Select-Object -ExpandProperty KeyProtector MountPoint | Out-File -Append ($_EXPORTDIR + '\BitLocker\Get-BitLockerVolume_KeyProtector.txt') 2>&1
		Get-WmiObject -Namespace root/CIMV2/Security/MicrosoftVolumeEncryption -Class Win32_EncryptableVolume | Out-File -Append ($_EXPORTDIR + '\BitLocker\Win32_EncryptableVolume.txt') 2>&1
	}
	catch { LogInfoFile 'Failed to collect Get-BitLockerVolume or Win32_EncryptableVolume class' }

	try {
		Get-Tpm | Out-File -Append ($_EXPORTDIR + '\BitLocker\Get-Tpm.txt') 2>&1
		Get-WmiObject -Namespace root/CIMV2/Security/MicrosoftTpm -Class Win32_TPM | Out-File -Append ($_EXPORTDIR + '\BitLocker\Win32_TPM.txt') 2>&1
	}
	catch { LogInfoFile 'Failed to collect Get-Tpm or MicrosoftTpm class' }

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect License information
	# =================================================================
	LogInfo '>>> Collect License information' 'White'
	LogInfoFile '>>> Collect License information'

	$null = New-Item -Path ($_EXPORTDIR + '\License') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/2' 'White'
	cscript ($env:windir + '\System32\slmgr.vbs') /dlv > ($_EXPORTDIR + '\License\slmgr_dlv.txt') 2>&1
	cscript ($env:windir + '\System32\slmgr.vbs') /dlv all > ($_EXPORTDIR + '\License\slmgr_dlv_all.txt') 2>&1
	Get-WmiObject SoftwareLicensingService | Out-File -Append ($_EXPORTDIR + '\License\SoftwareLicensingService.txt') 2>&1
	nslookup '-type=srv' '_vlmcs._tcp' > ($_EXPORTDIR + '\License\kms_srv.txt') 2>&1
	(Get-Acl REGISTRY::HKEY_USERS\S-1-5-20).Access | Out-File -Append ($_EXPORTDIR + '\License\acl_hkcu.txt') 2>&1
	(Get-Acl REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\WPA).Access | Out-File -Append ($_EXPORTDIR + '\License\acl_wpa.txt') 2>&1

	LogInfo '  > phase 2/2' 'White'
	cscript 'C:\Program Files\Microsoft Office\Office15\OSPP.vbs' /dstatus > ($_EXPORTDIR + '\License\office2013x64_license_slmgr_dstatus.txt') 2>&1
	cscript 'C:\Program Files (x86)\Microsoft Office\Office15\OSPP.vbs' /dstatus > ($_EXPORTDIR + '\License\office2013x86_license_slmgr_dstatus.txt') 2>&1
	cscript 'C:\Program Files\Microsoft Office\Office16\OSPP.vbs' /dstatus > ($_EXPORTDIR + '\License\office20162019x64_license_slmgr_dstatus.txt') 2>&1
	cscript 'C:\Program Files (x86)\Microsoft Office\Office16\OSPP.vbs' /dstatus > ($_EXPORTDIR + '\License\office20162019x86_license_slmgr_dstatus.txt') 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect Service information
	# =================================================================
	LogInfo '>>> Collect Service information' 'White'
	LogInfoFile '>>> Collect Service information'

	$null = New-Item -Path ($_EXPORTDIR + '\Service') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/1' 'White'
	sc.exe queryex > ($_EXPORTDIR + '\Service\sc_queryex.txt') 2>&1
	sc.exe sdshow TrustedInstaller > ($_EXPORTDIR + '\Service\sc_sdshow_TrustedInstaller.txt') 2>&1
	sc.exe sdshow wuauserv > ($_EXPORTDIR + '\Service\sc_sdshow_wuauserv.txt') 2>&1
	Copy-Item -Path "$env:windir\System32\LogFiles\SCM\*.EVM*" -Destination "$_EXPORTDIR\Service" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1


	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect Registry information
	# =================================================================
	LogInfo '>>> Collect Registry information' 'White'
	LogInfoFile '>>> Collect Registry information'

	$null = New-Item -Path ($_EXPORTDIR + '\Registry') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/1' 'White'
	REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies' ($_EXPORTDIR + '\Registry\Policies.reg') >> ($global:ErrorLogFile) 2>&1
	REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\current' ($_EXPORTDIR + '\Registry\PolicyManager.reg') >> ($global:ErrorLogFile) 2>&1
	REG EXPORT 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings' ($_EXPORTDIR + "\Registry\IEProxy_$env:USERNAME") >> ($global:ErrorLogFile) 2>&1

	REG LOAD 'HKEY_LOCAL_MACHINE\COMPONENTS' ($env:windir + '\System32\config\COMPONENTS') >> ($global:ErrorLogFile) 2>&1
	REG SAVE 'HKEY_LOCAL_MACHINE\COMPONENTS' ($_EXPORTDIR + '\Registry\COMPONENTS.hiv') >> ($global:ErrorLogFile) 2>&1

	REG LOAD 'HKEY_LOCAL_MACHINE\DRIVERS' ($env:windir + '\System32\config\DRIVERS') >> ($global:ErrorLogFile) 2>&1
	REG SAVE 'HKEY_LOCAL_MACHINE\DRIVERS' ($_EXPORTDIR + '\Registry\DRIVERS.hiv') >> ($global:ErrorLogFile) 2>&1

	REG SAVE 'HKEY_LOCAL_MACHINE\BCD00000000' ($_EXPORTDIR + '\Registry\BCD00000000.hiv') >> ($global:ErrorLogFile) 2>&1
	REG SAVE 'HKEY_USERS\S-1-5-20' ($_EXPORTDIR + '\Registry\S-1-5-20.hiv') >> ($global:ErrorLogFile) 2>&1
	REG SAVE 'HKEY_LOCAL_MACHINE\SOFTWARE' ($_EXPORTDIR + '\Registry\SOFTWARE.hiv') >> ($global:ErrorLogFile) 2>&1
	REG SAVE 'HKEY_LOCAL_MACHINE\SYSTEM' ($_EXPORTDIR + '\Registry\SYSTEM.hiv') >> ($global:ErrorLogFile) 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect Event Log information
	# =================================================================
	LogInfo '>>> Collect Event Log information' 'White'
	LogInfoFile '>>> Collect Event Log information'

	$null = New-Item -Path ($_EXPORTDIR + '\EventLog') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/2' 'White'
	wevtutil export-log System ($_EXPORTDIR + '\EventLog\System.evtx') 2>&1
	wevtutil archive-log ($_EXPORTDIR + '\EventLog\System.evtx') /locale:ja 2>&1
	wevtutil query-events System /f:text > ($_EXPORTDIR + '\eventlog\System.txt') 2>&1

	wevtutil export-log Application ($_EXPORTDIR + '\EventLog\Application.evtx') 2>&1
	wevtutil archive-log ($_EXPORTDIR + '\EventLog\Application.evtx') /locale:ja 2>&1
	wevtutil query-events Application /f:text > ($_EXPORTDIR + '\EventLog\Application.txt') 2>&1

	wevtutil export-log Setup ($_EXPORTDIR + '\EventLog\Setup.evtx')
	wevtutil archive-log ($_EXPORTDIR + '\EventLog\Setup.evtx') /locale:ja
	wevtutil query-events Setup /f:text > ($_EXPORTDIR + '\EventLog\Setup.txt') 2>&1

	wevtutil export-log Microsoft-Windows-TaskScheduler/Operational ($_EXPORTDIR + '\EventLog\TaskScheduler-Operational.evtx') 2>&1
	wevtutil archive-log ($_EXPORTDIR + '\EventLog\TaskScheduler-Operational.evtx') /locale:ja 2>&1
	wevtutil query-events Microsoft-Windows-TaskScheduler/Operational /f:text > ($_EXPORTDIR + '\EventLog\TaskScheduler-Operational.txt') 2>&1

	LogInfo '  > phase 2/2' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\EventLog\Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:windir + '\System32\winevt\Logs') ($_EXPORTDIR + '\EventLog\Logs') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'

	# =================================================================
	# Collect Setup information
	# =================================================================
	LogInfo '>>> Collect Setup information' 'White'
	LogInfoFile '>>> Collect Setup information'

	LogInfo '  > phase 1/3' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\Setup') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	$null = New-Item -Path ($_EXPORTDIR + '\Setup\C_WINDOWS_Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	net stop usosvc >> ($global:ErrorLogFile) 2>&1
	net stop wuauserv >> ($global:ErrorLogFile) 2>&1

	robocopy ($env:windir + '\Logs') ($_EXPORTDIR + '\Setup\C_WINDOWS_Logs') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 2/3' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\Setup\C_WINDOWS_servicing_sessions') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	Copy-Item -Path "$env:windir\servicing\sessions\*.*" -Destination "$_EXPORTDIR\Setup\C_WINDOWS_servicing_sessions" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1

	#for installation
	Copy-Item -Path "$env:windir\inf\Setupapi.*" -Destination "$_EXPORTDIR\Setup" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Copy-Item -Path "$env:windir\WinSXS\pending.xml.*" -Destination "$_EXPORTDIR\Setup" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Copy-Item -Path "$env:windir\WinSXS\poqexec.log" -Destination "$_EXPORTDIR\Setup" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1

	LogInfo '  > phase 3/3' 'White'
	#for sysprep
	$null = New-Item -Path ($_EXPORTDIR + '\Setup\Sysprep_Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	Copy-Item -Path "$env:windir\system32\sysprep\Panther\*" -Destination "$_EXPORTDIR\Setup\Sysprep_Logs" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Get-AppxProvisionedPackage -Online | Out-File ($_EXPORTDIR + '\Setup\Sysprep_Logs\AppxProvisionedPackage.txt') >> ($global:ErrorLogFile) 2>&1
	Get-AppxProvisionedPackage -Online | Format-Table DisplayName, PackageName | Out-File ($_EXPORTDIR + '\Setup\Sysprep_Logs\AppxProvisionedPackageTable.txt') >> ($global:ErrorLogFile) 2>&1
	Get-AppxPackage -Alluser | Out-File ($_EXPORTDIR + '\Setup\Sysprep_Logs\AppxPackage.txt') >> ($global:ErrorLogFile) 2>&1

	#for Browser
	$null = New-Item -Path ($_EXPORTDIR + '\Setup\Browser') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	Copy-Item -Path "$env:windir\IE11_main.log" -Destination "$_EXPORTDIR\Setup\Browser" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Copy-Item -Path "$env:windir\Temp\msedge_installer.log" -Destination "$_EXPORTDIR\Setup\Browser" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Copy-Item -Path "$env:ALLUSERSPROFILE\Microsoft\EdgeUpdate\Log\MicrosoftEdgeUpdate.log" -Destination "$_EXPORTDIR\Setup\Browser" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'

	# =================================================================
	# Collect Windows Update information
	# =================================================================
	LogInfo '>>> Collect Windows Update information' 'White'
	LogInfoFile '>>> Collect Windows Update information'

	LogInfo '  > phase 1/3' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\WU') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	Copy-Item -Path "$env:windir\SoftwareDistribution\ReportingEvents.log" -Destination "$_EXPORTDIR\WU" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Copy-Item -Path "$env:windir\WindowsUpdate.log" -Destination "$_EXPORTDIR\WU" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1


	#for windows update - run Get-WindowsUpdateLog cmdlet for Windows10-based OS
	if ( $OperatingSystemInfo.OSVersion -ge 10 ) {
		Get-WindowsUpdateLog -LogPath ($_EXPORTDIR + '\WU\Get-WindowsUpdateLog.log') | Out-Null | Out-File -Append $global:ErrorLogFile 2>&1
	}

	LogInfo '  > phase 2/3' 'White'
	#for USOShared and USOPrivate
	$null = New-Item -Path ($_EXPORTDIR + '\WU\USOShared') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	$null = New-Item -Path ($_EXPORTDIR + '\WU\USOPrivate') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	net stop usosvc >> ($global:ErrorLogFile) 2>&1
	net stop wuauserv >> ($global:ErrorLogFile) 2>&1

	robocopy ($env:ProgramData + '\USOShared\Logs') ($_EXPORTDIR + '\WU\USOShared') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:ProgramData + '\UsoPrivate\UpdateStore') ($_EXPORTDIR + '\WU\USOPrivate') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1

	Copy-Item -Path "$env:windir\SoftwareDistribution\Plugins\7D5F3CBA-03DB-4BE5-B4B36DBED19A6833\TokenRetrieval.log" -Destination "$_EXPORTDIR\WU" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Copy-Item -Path "$env:LOCALAPPDATA\microsoft\windows\windowsupdate.log" -Destination "$_EXPORTDIR\WU\WindowsUpdatePerUser.log" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1
	Copy-Item -Path "$env:windir\windowsupdate (1).log" -Destination "$_EXPORTDIR\WU" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1


	LogInfo '  > phase 3/3' 'White'
	# UUP logs and action list xmls
	$null = New-Item -Path ($_EXPORTDIR + '\WU\UUP_Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:windir + '\SoftwareDistribution\Download') ($_EXPORTDIR + '\WU\UUP_Logs *.log *.xml') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1

	# export registry related to WU
	REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsSelfhost' ($_EXPORTDIR + '\WU\WindowsSelfthost.reg') >> ($global:ErrorLogFile) 2>&1
	REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate' ($_EXPORTDIR + '\WU\WindowsUpdate.reg') >> ($global:ErrorLogFile) 2>&1
	REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\SessionsPending' ($_EXPORTDIR + '\WU\SessionsPending.reg') >> ($global:ErrorLogFile) 2>&1

	# check dual scan
	(New-Object -ComObject 'Microsoft.Update.ServiceManager').Services | Format-Table Name, IsDefaultAUService > ($_EXPORTDIR + '\WU\DualScan.txt') 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect DO information
	# =================================================================
	if ( $OperatingSystemInfo.OSVersion -ge 10 ) {

		LogInfo '>>> Collect DO information' 'White'
		LogInfoFile '>>> Collect DO information'

		LogInfo '  > phase 1/2' 'White'
		$null = New-Item -Path ($_EXPORTDIR + '\DO') -ItemType directory >> ($global:ErrorLogFile) 2>&1

		net start dosvc >> ($global:ErrorLogFile) 2>&1
		if ($OperatingSystemInfo.ReleaseId -ge 1703) {
			Get-DeliveryOptimizationStatus -Verbose | Out-File ($_EXPORTDIR + '\DO\DOStatus.txt') >> ($global:ErrorLogFile) 2>&1
			Get-DeliveryOptimizationPerfSnap -WarningAction SilentlyContinue | Out-File ($_EXPORTDIR + '\DO\DOPerfSnap.txt') >> ($global:ErrorLogFile) 2>&1
		}
		if ($OperatingSystemInfo.ReleaseId -ge 1803) {
			Get-DeliveryOptimizationLog | Set-Content ($_EXPORTDIR + '\DO\DOLog.txt') >> ($global:ErrorLogFile) 2>&1
			Get-DeliveryOptimizationPerfSnapThisMonth | Out-File ($_EXPORTDIR + '\DO\DOPerfSnapThisMonth.txt') >> ($global:ErrorLogFile) 2>&1
		}
		if ($OperatingSystemInfo.ReleaseId -ge 1809) {
			Get-DOConfig -Verbose | Out-File ($_EXPORTDIR + '\DO\DOConfig.txt') >> ($global:ErrorLogFile) 2>&1
		}
		if ($OperatingSystemInfo.ReleaseId -ge 2004) {
			Get-DeliveryOptimizationStatus -PeerInfo | Out-File ($_EXPORTDIR + '\DO\DOStatus-peer.txt') >> ($global:ErrorLogFile) 2>&1
		}
		net stop dosvc >> ($global:ErrorLogFile) 2>&1

		LogInfo '  > phase 2/2' 'White'
		$null = New-Item -Path ($_EXPORTDIR + '\DO\Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1
		robocopy ($env:windir + '\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Logs') ($_EXPORTDIR + '\DO\Logs') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1

		REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization' ($_EXPORTDIR + '\DO\Registry_DO_HLKM_Config.reg') >> ($global:ErrorLogFile) 2>&1
		REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' ($_EXPORTDIR + '\DO\Registry_DO_Policies_Config.reg') >> ($global:ErrorLogFile) 2>&1
		REG EXPORT 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\current\device\DeliveryOptimization' ($_EXPORTDIR + '\DO\Registry_DO_MDM_Config.reg') >> ($global:ErrorLogFile) 2>&1
		REG EXPORT 'HKEY_USERS\S-1-5-20\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization' ($_EXPORTDIR + '\DO\Registry_DO_HKU_Config.reg') >> ($global:ErrorLogFile) 2>&1

		LogInfo '<<< done.' 'White'
		LogInfoFile '<<< done.'
	}


	# =================================================================
	# Collect Upgrade information
	# =================================================================
	LogInfo '>>> Collect Upgrade information' 'White'
	LogInfoFile '>>> Collect Upgrade information'

	LogInfo '  > phase 1/5' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	Copy-Item -Path "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini" -Destination "$_EXPORTDIR\Upgrade" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1

	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_$Windows.~BT_Sources') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:SystemDrive + '\$Windows.~BT\Sources') ($_EXPORTDIR + '\Upgrade\C_$Windows.~BT_Sources') ($_EXPORTDIR + '\Upgrade\C_$Windows.~BT_Sources') /e /COPY:DT /R:1 /W:1 /NP /xf '*.esd' '*.wim' '*.dll' '*.sdi' '*.mui' >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_$Windows.~WS_Sources') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:SystemDrive + '\$Windows.~WS\Sources') ($_EXPORTDIR + '\Upgrade\C_$Windows.~WS_Sources') ($_EXPORTDIR + '\Upgrade\C_$Windows.~WS_Sources') /e /COPY:DT /R:1 /W:1 /NP /xf '*.esd' '*.wim' '*.dll' '*.sdi' '*.mui' >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 2/5' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_Windows_Panther') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:windir + '\Panther') ($_EXPORTDIR + '\Upgrade\C_Windows_Panther') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 3/5' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_Windows.old_Windows_System32_Winevt_Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:SystemDrive + '\Windows.old\Windows\System32\Winevt\Logs') ($_EXPORTDIR + '\Upgrade\C_Windows.old_Windows_System32_Winevt_Logs') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 4/5' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_Windows.old_Windows_Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:SystemDrive + '\Windows.old\Windows\Logs') ($_EXPORTDIR + '\Upgrade\C_Windows.old_Windows_Logs') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_Windows.old_ProgramData_USOShared_Logs') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:SystemDrive + '\Windows.old\ProgramData\USOShared\Logs') ($_EXPORTDIR + '\Upgrade\C_Windows.old_ProgramData_USOShared_Logs') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_Windows.old_ProgramData_USOPrivate_UpdateStore') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:SystemDrive + '\Windows.old\ProgramData\USOPrivate\UpdateStore') ($_EXPORTDIR + '\Upgrade\C_Windows.old_ProgramData_USOPrivate_UpdateStore') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 5/5' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\Upgrade\C_$SysReset') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	robocopy ($env:SystemDrive + '\$SysReset') ($_EXPORTDIR + '\Upgrade\C_$SysReset') /e /COPY:DT /R:1 /W:1 /NP >> ($global:ErrorLogFile) 2>&1
	Start-Sleep 3 >> ($global:ErrorLogFile) 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'


	# =================================================================
	# Collect UUS information
	# =================================================================
	LogInfo '>>> Collect UUS information' 'White'
	LogInfoFile '>>> Collect UUS information'

	LogInfo '  > phase 1/1' 'White'
	$null = New-Item -Path ($_EXPORTDIR + '\UUS') -ItemType directory >> ($global:ErrorLogFile) 2>&1
	Copy-Item -Path "$env:ProgramData\Microsoft\Windows\UUS\State\_active.uusver" -Destination "$_EXPORTDIR\UUS" -ErrorAction SilentlyContinue -ErrorVariable ErrorMsg -Force >> $global:ErrorLogFile 2>&1


	# =================================================================
	# Collect File information
	# =================================================================
	LogInfo '>>> Collect File information' 'White'
	LogInfoFile '>>> Collect File information'

	$null = New-Item -Path ($_EXPORTDIR + '\File') -ItemType directory >> ($global:ErrorLogFile) 2>&1

	LogInfo '  > phase 1/7' 'White'
	cmd /r dir /t:c /a /s /c /n ($env:windir + '\System32\config\') > ($_EXPORTDIR + '\File\dir_C_WINDOWS_System32_config.txt') 2>&1
	icacls ($env:windir + '\System32\config') /t /c > ($_EXPORTDIR + '\File\icacls_C_WINDOWS_System32_config.txt') 2>&1

	LogInfo '  > phase 2/7' 'White'
	cmd /r dir /t:c /a /s /c /n ($env:windir + '\System32\Drivers\') > ($_EXPORTDIR + '\File\dir_C_WINDOWS_System32_Drivers.txt') 2>&1
	icacls ($env:windir + '\System32\Drivers') /t /c > ($_EXPORTDIR + '\File\icacls_C_WINDOWS_System32_Drivers.txt') 2>&1

	LogInfo '  > phase 3/7' 'White'
	cmd /r dir /t:c /a /s /c /n ($env:windir + '\SoftwareDistribution\') > ($_EXPORTDIR + '\File\dir_C_WINDOWS_SoftwareDistribution.txt') 2>&1
	icacls ($env:windir + '\SoftwareDistribution') /t /c > ($_EXPORTDIR + '\File\icacls_C_WINDOWS_SoftwareDistribution.txt') 2>&1

	LogInfo '  > phase 4/7' 'White'
	cmd /r dir /t:c /a /s /c /n ($env:windir + '\inf\') > ($_EXPORTDIR + '\File\dir_C_WINDOWS_inf.txt') 2>&1
	icacls ($env:windir + '\inf') /t /c > ($_EXPORTDIR + '\File\icacls_C_WINDOWS_inf.txt') 2>&1

	LogInfo '  > phase 5/7' 'White'
	cmd /r dir /t:c /a /s /c /n ($env:windir + '\WinSXS\') > ($_EXPORTDIR + '\File\dir_C_WINDOWS_WinSXS.txt') 2>&1
	icacls ($env:windir + '\winsxs\catalogs') /t /c > ($_EXPORTDIR + '\File\icacls_C_WINDOWS_WinSXS_catalogs.txt') 2>&1

	LogInfo '  > phase 6/7' 'White'
	cmd /r dir /t:c /a /s /c /n ($env:windir + '\servicing\Packages') > ($_EXPORTDIR + '\File\dir_C_WINDOWS_servicing_Packages.txt') 2>&1
	icacls ($env:windir + '\servicing\Packages') /t /c > ($_EXPORTDIR + '\File\icacls_C_servicing_Packages.txt') 2>&1

	LogInfo '  > phase 7/7' 'White'
	cmd /r dir /t:c /a /s /c /n C:\ > ($_EXPORTDIR + '\File\dir_C.txt') 2>&1
	icacls C:\ > ($_EXPORTDIR + '\File\icacls_C.txt') 2>&1

	LogInfo '<<< done.' 'White'
	LogInfoFile '<<< done.'

	EndFunc $MyInvocation.MyCommand.Name
}


# prevent FwCollect_MiniBasicLog from running by using the -noBasicLog switch
# example: .\TSS.ps1 -Start -DND_CodeIntegrity -noBasicLog -noUpdate
<#
function CollectDND_CodeIntegrityLog
{
	EnterFunc $MyInvocation.MyCommand.Name
	$global:ParameterArray = @($global:ParameterArray, 'noBasicLog')
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>

function CollectDND_AudioETWLog {
	EnterFunc $MyInvocation.MyCommand.Name

	$global:ParameterArray += 'noBasicLog'
	$TempDir = "$LogFolder\audioDiagnostics$LogSuffix"
	FwCreateFolder $TempDir
	$Prefix = "$TempDir\$env:COMPUTERNAME" + '_'
	$RobocopyLog = $Prefix + 'robocopy.log'
	$ErrorFile = $Prefix + 'Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	# use tss_config.cfg to modify these parameters on the fly as you need them
	# Flush Windows Update logs by stopping services before copying...usually not needed.
	$FlushLogs = 0

	Get-DNDAudioInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs

	EndFunc $MyInvocation.MyCommand.Name
}

function DND_AudioWPRScenarioPostStart {
	EnterFunc $MyInvocation.MyCommand.Name

	$wprp = 'DND_audio-info.wprp'
	# Profile in wprp file to use for repro trace
	$profile = 'audio-info.Verbose'
	$LogPrefix = 'Audio'
	LogInfo "[$LogPrefix] Starting: WPR.exe -start `"$Scriptfolder\config\$wprp!$profile`""
	$Commands = @("WPR.exe -start `"$Scriptfolder\config\$wprp!$profile`"")
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}

function DND_AudioWPRPostStop {
	EnterFunc $MyInvocation.MyCommand.Name

	#$audioETLPath = $LogFolder + "\" + $env:COMPUTERNAME + "_audio-info.Verbose.etl"
	$audioETLPath = "$global:LogFolder\$LogPrefix" + 'audio-info.Verbose.etl'
	$dummyETLPath = "$global:LogFolder\$LogPrefix" + "$($ScenarioName)Trace.etl"
	$LogPrefix = 'AudioLogs'
	LogInfo "[$LogPrefix] Stopping: WPR.exe -stop $audioETLPath"
	$Commands = @(
		"WPR.exe -stop $audioETLPath"
		# removing empty "DND_AudioWPR" dummy trace file, see $DND_AudioWPRProviders
		"Remove-Item -Path $dummyETLPath -Force"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}

function CollectDND_AudioWPRLog {
	EnterFunc $MyInvocation.MyCommand.Name

	$global:ParameterArray += 'noBasicLog'
	$TempDir = "$LogFolder\audioDiagnostics$LogSuffix"
	FwCreateFolder $TempDir
	$Prefix = "$TempDir\$env:COMPUTERNAME" + '_'
	$RobocopyLog = $Prefix + 'robocopy.log'
	$ErrorFile = $Prefix + 'Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	# use tss_config.cfg to modify these parameters on the fly as you need them
	# Flush Windows Update logs by stopping services before copying...usually not needed.
	$FlushLogs = 0

	Get-DNDAudioInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs

	EndFunc $MyInvocation.MyCommand.Name
}

function DND_PowerWPRScenarioPostStart {
	EnterFunc $MyInvocation.MyCommand.Name

	$LogPrefix = 'powerWPR'
	LogInfo "[$LogPrefix] Starting: WPR.exe -start power"
	$Commands = @('WPR.exe -start power')
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}

function DND_PowerWPRPostStop {
	EnterFunc $MyInvocation.MyCommand.Name

	$powerETLPath = "$global:LogFolder\$LogPrefix" + 'power-info.etl'
	$dummyETLPath = "$global:LogFolder\$LogPrefix" + "$($ScenarioName)Trace.etl"
	$LogPrefix = 'powerWPR'
	LogInfo "[$LogPrefix] Stopping: WPR.exe -stop $powerETLPath"
	$Commands = @(
		"WPR.exe -stop $powerETLPath"
		# removing empty "DND_PowerWPR" dummy trace file, see $DND_PowerWPRProviders
		"Remove-Item -Path $dummyETLPath -Force"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}

function CollectDND_PowerWPRLog {
	EnterFunc $MyInvocation.MyCommand.Name

	$POWERWPR = '1'
	CollectDND_SETUPReportLog

	EndFunc $MyInvocation.MyCommand.Name
}

function CollectDND_WUfBReportLog {
	EnterFunc $MyInvocation.MyCommand.Name
	$global:ParameterArray += 'noBasicLog'
	$TempDir = "$LogFolder\WUfBReport$LogSuffix"
	FwCreateFolder $TempDir
	$Prefix = "$TempDir\$env:COMPUTERNAME" + '_'
	$RobocopyLog = $Prefix + 'robocopy.log'
	$ErrorFile = $Prefix + 'Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	# use tss_config.cfg to modify these parameters on the fly as you need them
	# Flush Windows Update logs by stopping services before copying...usually not needed.
	$FlushLogs = 0

	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}

	$LogPrefixWUfBReport = 'WUfBReport'
	$currentDir = Split-Path $TempDir -Leaf
	FwGetWhoAmI -Subfolder $currentDir

	$DND_WUfBReport_Start = (Get-Date)
	LogInfo ("[$LogPrefixWUfBReport] Starting...")
	LogInfo ("[OS] Version: $_major.$_minor.$_build")

	Get-DNDWUfBReport $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs

	LogInfo ("[$LogPrefixWUfBReport] Querying DataCollection reg keys.")
	$RegKeysDataCollection = @(
		('HKLM:SOFTWARE\Policies\Microsoft\Windows\DataCollection')
	)
	FwExportRegToOneFile $LogPrefixWUfBReport $RegKeysDataCollection "$($Prefix)reg_DataCollection.txt"

	$EVTX = $true
	Get-DNDEventLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs $_event_logs $EVTX $_format
	Get-DNDWindowsUpdateInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	Get-DNDMDMInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	Get-DNDNetworkBasic $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	<#
	# call function delivery optimization logs
	if ($_WIN10_1809_OR_LATER) {
		Get-DNDDoLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	}
	Get-DNDCbsPnpInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	Get-DNDMiscInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	#>

	$DND_WUfBReport_End = (Get-Date)
	$DND_WUfBReport_Runtime = (New-TimeSpan -Start $DND_WUfBReport_Start -End $DND_WUfBReport_End)
	$DND_WUfBReport_hours = $DND_WUfBReport_Runtime.Hours
	$DND_WUfBReport_minutes = $DND_WUfBReport_Runtime.Minutes
	$DND_WUfBReport_seconds = $DND_WUfBReport_Runtime.Seconds
	$DND_WUfBReport_summary = "Overall duration: $DND_WUfBReport_hours hours, $DND_WUfBReport_minutes minutes and $DND_WUfBReport_seconds seconds"
	LogInfo "[$LogPrefixWUfBReport] $DND_WUfBReport_summary" 'Gray'

	EndFunc $MyInvocation.MyCommand.Name
}

function DND_CodeIntegrityPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."

	$LogPrefixCodeIntegrity = 'CodeIntegrity'
	LogInfo ("[$LogPrefixCodeIntegrity] Starting CIDiag.")
	$CodeIntegrity = @(
		'CIDiag.exe /start'
	)
	RunCommands $LogPrefixCodeIntegrity $CodeIntegrity -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}

function  DND_CodeIntegrityPostStop {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."

	#$TempDir = "$LogFolder\Setup_Report$LogSuffix"
	FwCreateFolder $LogFolder\CIDiag
	$LogPrefixCodeIntegrity = 'CodeIntegrity'
	LogInfo ("[$LogPrefixCodeIntegrity] Stopping CIDiag.")
	$CodeIntegrity = @(
		"CIDiag.exe /stop $LogFolder\CIDiag"
	)
	RunCommands $LogPrefixCodeIntegrity $CodeIntegrity -ThrowException:$False -ShowMessage:$True

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectDND_ServicingLog {
	EnterFunc $MyInvocation.MyCommand.Name
	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}

	$global:ParameterArray += 'noBasicLog'

	$TempDir = "$LogFolder\Servicing$LogSuffix"
	FwCreateFolder $TempDir

	$Prefix = "$TempDir\$env:COMPUTERNAME" + '_'
	$RobocopyLog = $Prefix + 'robocopy.log'
	$ErrorFile = $Prefix + 'Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	# use tss_config.cfg to modify these parameters on the fly as you need them
	$validValues = '0', '1'
	# Flush Windows Update logs by stopping services before copying...usually not needed.
	$FlushLogs = 0
	# $global:DND_SETUPReport_FlushLogs set in tss_config.cfg?
	if ($DND_SETUPReport_FlushLogs -in $validValues) { $FlushLogs = $DND_SETUPReport_FlushLogs }

	# starting MsInfo early
	FwGetMsInfo32 'nfo' -Subfolder "Servicing$LogSuffix"
	FwGetSysInfo -Subfolder "Servicing$LogSuffix"
	# call function CBS and PNP
	Get-DNDCbsPnpInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
	Get-DNDSlowProcessing $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectDND_TPMLog {
	EnterFunc $MyInvocation.MyCommand.Name
	# do we run elevated?
	if (!(FwIsElevated) -or ($Host.Name -match 'ISE Host')) {
		if ($Host.Name -match 'ISE Host') {
			LogInfo 'Exiting on ISE Host.' 'Red'
		}
		LogInfo 'This script needs to run from elevated command/PowerShell prompt.' 'Red'
		return
	}
	$global:ParameterArray += 'noBasicLog'

	$TempDir = "$LogFolder\TPM$LogSuffix"
	FwCreateFolder $TempDir

	$Prefix = "$TempDir\$env:COMPUTERNAME" + '_'
	$RobocopyLog = $Prefix + 'robocopy.log'
	$ErrorFile = $Prefix + 'Errorout.txt'
	$Line = '--------------------------------------------------------------------------------------------------------'
	$LogPrefix = 'TPM'

	if ($_WIN8_OR_LATER) {
		try {
			$tpmInfo = Get-Tpm -ErrorAction Stop
			if ($tpmInfo.TpmPresent) {
				# TPM is present (we do not check if $tpmInfo.TpmReady)
				# starting MsInfo early
				FwGetMsInfo32 -Subfolder "TPM$LogSuffix" #-Formats TXT
				FwGet-SummaryVbsLog -Subfolder "TPM$LogSuffix"
				FwGetWhoAmI -Subfolder "TPM$LogSuffix"
				FwGetSysInfo -Subfolder "TPM$LogSuffix"
				# call function BitLockerInfo
				Get-DNDReliabilitySummary $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
				Get-DNDEventLogs $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs $_event_logs $EVTX $_format
				Get-DNDBitLockerInfo $Prefix $TempDir $RobocopyLog $ErrorFile $Line $FlushLogs
				if (($global:msinfo32TXT.HasExited -eq $false) -or ($global:msinfo32NFO.HasExited -eq $false)) {
					FwWaitForProcess $global:msinfo32TXT 300
					FwWaitForProcess $global:msinfo32NFO 300
				}
			}
			else {
				# TPM is not present
				LogWarn "[$LogPrefix] TPM not present. Aborting."
			}
		}
		catch {
			if ($_.Exception.HResult -eq 0x80131500) {
				# 0x80284008 TBS_E_SERVICE_NOT_RUNNING, https://learn.microsoft.com/en-us/windows/win32/tbs/tbs-return-codes
				LogInfo 'ERROR: TPM management is not supported on this platform. Aborting.'
				LogWarn 'ERROR: 0x80284008 TBS_E_SERVICE_NOT_RUNNING'
				exit 0
			}
			else {
				LogException 'Error occurred:' $_
				# Handle other exceptions
			}
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}

<#
### Diag function
function RunDND_SETUPDiag {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	$PathToLogFolder = "$LogFolder\SetupLog$LogSuffix"
	LogInfo "log folder is $PathToLogFolder"

	$filelist = New-Object System.Collections.ArrayList($NULL)

	LogInfo ('Searching log files under ' + $PathToLogFolder)
	#--------------------------
	#For SetupCollector
	#--------------------------
	#search for cbs logs and add them
	$cbsPath = Join-Path $PathToLogFolder '\Setup\C_WINDOWS_Logs\CBS\'
	if (Test-Path $cbsPath) {
		# expand .cab files and add to filelist.
		Write-Output ("Expanding .cab files under $cbsPath")
		foreach ($file in (Expand-CabFiles -FolderPath $cbsPath)) {
			Write-Output ('Adding file ' + $file)
			$NULL = $filelist.Add($file)
		}
		$cbsFiles = Get-ChildItem -Path ($cbsPath + '\cbs*.log')
		foreach ($file in $cbsFiles) {
			$fullPath = $cbsPath + $file.Name
			# skip expanded CBS files which has been included in filelist
			if ($filelist.Contains($fullPath)) {
				continue
			}
			Write-Output ('Adding file ' + $fullPath)
			$NULL = $filelist.Add($fullPath)
		}
	}
	#add  panther logs
	$fullPath = Join-Path $PathToLogFolder '\Upgrade\C_Windows_Panther\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder '\Upgrade\C_Windows_Panther\NewOs\Panther\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder "\Upgrade\C_`$Windows.~BT_Sources\Panther\setupact.log"
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder "\Upgrade\C_`$Windows.~BT_Sources\Rollback\setupact.log"
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}

	#add  OOBE logs
	$fullPath = Join-Path $PathToLogFolder '\Upgrade\C_Windows_Panther\UnattendGC\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder "\Upgrade\C_`$Windows.~BT_Sources\Panther\UnattendGC\setupact.log"
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}

	#add SYSPREP logs
	$fullPath = Join-Path $PathToLogFolder '\Setup\Syprep_Logs\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}

	foreach ($filename in $filelist) {
		Analyze-File($filename)
	}
	if ($filelist) {
		Cleanup-TempFolder -FileList $filelist
	}

	LogInfo 'Finished analyzing everything. Thank you for using this tool!!!'
	EndFunc $MyInvocation.MyCommand.Name
}
#>

function RunDND_SETUPReportDiagNotWantedAsOfNow {
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	$PathToLogFolder = "$LogFolder\Setup_Report$LogSuffix"
	LogInfo "log folder is $PathToLogFolder"

	$filelist = New-Object System.Collections.ArrayList($NULL)

	LogInfo ('Searching log files under ' + $PathToLogFolder)
	#--------------------------
	#For SetupReport
	#--------------------------
	#search for cbs logs and add them
	$cbsPath = Join-Path $PathToLogFolder '\Logs\CBS\'
	if (Test-Path $cbsPath) {
		# expand .cab files and add to filelist.
		Write-Output ("Expanding .cab files under $cbsPath")
		foreach ($file in (Expand-CabFiles -FolderPath $cbsPath)) {
			Write-Output ('Adding file ' + $file)
			$NULL = $filelist.Add($file)
		}
		$cbsFiles = Get-ChildItem -Path ($cbsPath + '\cbs*.log')
		foreach ($file in $cbsFiles) {
			$fullPath = $cbsPath + $file.Name
			# skip expanded CBS files which has been included in filelist
			if ($filelist.Contains($fullPath)) {
				continue
			}
			Write-Output ('Adding file ' + $fullPath)
			$NULL = $filelist.Add($fullPath)
		}
	}
	#add  panther logs
	$fullPath = Join-Path $PathToLogFolder '\UpgradeSetup\win_Panther\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder '\UpgradeSetup\win_Panther\NewOs\Panther\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder '\UpgradeSetup\~bt_Panther\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder '\UpgradeSetup\~bt_Rollback\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	#add  OOBE logs
	$fullPath = Join-Path $PathToLogFolder '\UpgradeSetup\win_Panther\UnattendGC\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	$fullPath = Join-Path $PathToLogFolder '\UpgradeSetup\~bt_Panther\UnattendGC\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}
	#add SYSPREP logs
	$fullPath = Join-Path $PathToLogFolder '\UpgradeSetup\sysprep_Panther\setupact.log'
	if (Test-Path $fullPath) {
		Write-Output ('Adding file ' + $fullPath)
		$NULL = $filelist.Add($fullPath)
	}

	foreach ($filename in $filelist) {
		Analyze-File($filename)
	}
	if ($filelist) {
		Cleanup-TempFolder -FileList $filelist
	}

	LogInfo 'Finished analyzing everything. Thank you for using this tool!!!'
	EndFunc $MyInvocation.MyCommand.Name
}

<#
class CbsProcessingStartEnd
{
	[bool]   $isStart
	[string] $time
	[string] $info

	CbsProcessingStartEnd([bool]$isStart, [string] $time, [string] $info) {
		$this.isStart = $isStart
		$this.time = $time
		$this.info = $info
	}
}
#>
#------- start of Parse-UpgradeLog -------
Function Parse-UpgradeLog() {
	param(
		[parameter(Mandatory)]
		[System.IO.StreamReader]$infile
	)


	$upgrade_begin_time = $NULL
	$upgrade_end_time = $NULL
	$upgrade_failed_time = $NULL
	$upgrade_failed_phase = $NULL
	#$source_os_language = $NULL
	$host_os_edition = $NULL
	$host_os_version = $NULL
	$host_os_build = $NULL
	#$host_os_langid = $NULL
	$host_os_arch = $NULL
	$target_os_edition = $NULL
	$target_os_version = $NULL
	$target_os_lang = $NULL
	$target_os_arch = $NULL
	$has_hardblock = $FALSE
	$has_Conexant_ISST_Audio = $FALSE
	$l_missing_packages = New-Object System.Collections.ArrayList($NULL)
	$l_executing_phases = New-Object System.Collections.ArrayList($NULL)

	Write-Verbose 'in Parse-UpgradeLog'

	while ( $NULL -ne ($line = $infile.ReadLine()) ) {

		if ($line -Match 'SetupHost::Initialize: CmdLine') {
			if ($line -Match '/Install') {
				$upgrade_begin_time = ($line -Split ',')[0]
			}
			elseif ($line -Match '/Success') {
				$upgrade_end_time = ($line -Split ',')[0]
			}
		}

		elseif ($line -Match 'Failed execution phase') {
			$upgrade_failed_time = ($line -split ',')[0]
			$upgrade_failed_phase = ($line -split 'Failed execution phase ')[1]
			$upgrade_failed_phase = ($upgrade_failed_phase -split '\.')[0]
		}

		elseif (($line -Match 'Setup phase change:') -and ($line -Match '-> \[SetupPhaseError\]')) {
			$upgrade_failed_time = ($line -split ',')[0]
			$upgrade_failed_phase = ($line -split 'Setup phase change: \[')[1]
			$upgrade_failed_phase = ($upgrade_failed_phase -split '\]')[0]
		}
		elseif ( ($line -Match 'Target OS: Detected Source Edition') -And ($NULL -eq $host_os_edition) ) {
			$host_os_edition = ($line -Split '\[')[1]
			$host_os_edition = '[' + ($host_os_edition -Split "`n")[0]
		}
		elseif ( ($line -Match 'Target OS: Detected Source Version') -And ($NULL -eq $host_os_version) ) {
			$host_os_version = ($line -Split '\[')[1]
			$host_os_version = '[' + ($host_os_version -Split "`n")[0]
		}
		elseif (($line -match 'Host OS Build String') -and ($null -eq $host_os_build)) {
			$host_os_build = ($line -split '\[')[1]
			$host_os_build = '[' + ($host_os_build -split "`n")[0]
		}
		elseif (($line -match 'Target OS: Detected Source Arch') -and ($null -eq $host_os_arch)) {
			$host_os_arch = ($line -split '\[')[1]
			$host_os_arch = '[' + ($host_os_arch -split "`n")[0]
		}
		elseif (($line -match 'Target OS: Edition') -and ($null -eq $target_os_edition)) {
			$target_os_edition = ($line -split '\[')[1]
			$target_os_edition = '[' + ($target_os_edition -split "`n")[0]
		}
		elseif (($line -match 'Target OS: Version') -and ($null -eq $target_os_version)) {
			$target_os_version = ($line -split '\[')[1]
			$target_os_version = '[' + ($target_os_version -split "`n")[0]
		}
		elseif (($line -match 'Target OS: Language') -and ($null -eq $target_os_lang)) {
			$target_os_lang = ($line -split '\[')[1]
			$target_os_lang = '[' + ($target_os_lang -split "`n")[0]
		}
		elseif (($line -match 'Target OS: Architecture') -and ($null -eq $target_os_arch)) {
			$target_os_arch = ($line -split '\[')[1]
			$target_os_arch = '[' + ($target_os_arch -split "`n")[0]
		}

		elseif ($line -match 'Executing phase') {
			if ($line -Match '\[.*\]') {
				foreach ($phase in $Matches[0]) {
					$time = ($line -split ',')[0]
					$phase = $time + ' ' + $phase
					if ($l_executing_phases -NotContains $phase) {
						$null = $l_executing_phases.add($phase)
					}
				}
			}
		}
		elseif ($line -match "SetupManager: Skipping ActionList supplied path as it doesn\'t exist") {
			$packageName = ($line -split '\[')[1]
			$packageName = ($packageName -split '\]')[0]
			$null = $l_missing_packages.add($packageName)
		}

		#case #1001
		elseif (($line -match 'CSetupHost::OnProgressChanged') -and ($line -match '0x800704C7')) {
			$time = ($line -split ',')[0]
			if ($NULL -ne $upgrade_begin_time) {
				Write-Output ("`nProblem:`n" + $time + ' Upgrade is cancelled by client. Installation start time: ' + $upgrade_begin_time)
			}
			else {
				Write-Output ("`nProblem:`n" + $time + ' Upgrade is cancelled by client')
			}
			Write-Output "`nSolution:`nIf you are using SCCM, set the timeout of SCCM to a larger value.`nOr consider upgrading locally using OS image media"
		}

		#case #1002
		elseif (($line -match 'TargetLanguageIsCompatibleForUpgrade') -and ($line -match 'not compatible')) {
			$time = ($line -split ',')[0]
			if ($line -match 'Target language') {
				$targetLanguage = ($line -split 'Target language ')[1]
				$targetLanguage = ($targetLanguage -split ' ')[0]
				Write-Output ("`nProblem:`n" + $time + ' Upgrade failed because the target language [', $targetLanguage, '] is not compatible with the host language')
			}
			else {
				Write-Output ("`nProblem:`n" + $time + ' Upgrade failed because the target language is not compatible with the host language')
			}
			Write-Output "`nSolution:`nUse an install image that is of the same language as the host system"
		}


		#case #1003
		elseif ($line -match 'SetupUI: Logging EndSession') {
			$time = ($line -split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Upgrade is terminated because of logoff or OS shutdown/reboot')
			Write-Output "`nSolution:`nDo not manually logoff or shutdown/reboot the OS during OS upgrade"
		}

		#case #1004
		elseif ($line -match 'checked FeaturesOnDemandDetected, found HardBlock') {
			$time = ($line -split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' the following packages are missing (may be due to download failure)')
			foreach ( $packageName in $l_missing_packages) {
				Write-Output ('	' + $packageName)
			}
			Write-Output "`nSolution:`nTry install the FeatureOnDemand packages in the list first and then retry the upgrade"
		}

		#case #1005
		elseif ($line -match 'Provider wsc:wica: reports HardBlock') {
			$has_hardblock = $True
		}
		elseif (($has_hardblock -eq $True) -and ($line -match '0xC1900208')) {
			#0xC1900208 is MOSETUP_E_COMPAT_INSTALLREQ_BLOCK
			$time = ($line -split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' The system did not pass the compatibility check for the upgrade.(0xc1900208 MOSETUP_E_COMPAT_INSTALLREQ_BLOCK)')
			Write-Output "`nSolution:`nLook at ScanResult.xml to find out what application(s) failed to pass the compatibility check."
			$has_hardblock = $FALSE
		}


		#case #1006
		elseif (($line -match 'Error 183 while applying object ') -and ($line -match 'Shell application requested abort')) {
			$time = ($line -split ',')[0]
			$folderName = ($line -split 'object ')[1]
			$folderName = ($folderName -split ' \[')[0]
			$objName = ($line -split '\[')[1]
			$objName = ($objName -split '\]')[0]
			Write-Output ("`nProblem: `n" + $time + " `"" + $objName + "`" under " + $folderName + ' might be corrupted and is causing unexpected error in the Windows shell component')
			Write-Output "`nSolution: `nPlease delete this file and try again"
		}


		#case #1007
		elseif ($line -match 'Conexant ISST Audio') {
			$has_Conexant_ISST_Audio = $True
		}
		elseif (($has_Conexant_ISST_Audio -eq $True) -and ($line -match '0x800704C7')) {
			$time = ($line -split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Incompatible Conexant ISST audio drivers are detected that failed the upgrade.')
			Write-Output "`nSolution:`nCheck the device manufacturer to see if an updated driver of Conexant ISST Audio is available, or just uninstall the driver."
			$has_Conexant_ISST_Audio = $False
		}


		#case #1008
		#		   elif 'User profile suffix mismatch' in line:
		#				print('\nWarning: ')
		#				print(line)
		#				if supportingFunctions.check_error(line) == '0x000007E7' and 'Error' in line:
		#					time = line.split(',')[0]
		#					print('\nProblem: \n' + time + ' User profile suffix mismatch.')
		#					print('\nSolution: \nPlease check if more than one ProfilePath is linked to a single ProfileList. Reference SR: 120082126002557')

		#case #1009
		elseif (($line -match 'InsufficientSystemPartitionDiskSpace') -and ($line -match 'HardBlock')) {
			$time = ($line -split ',')[0]
			$volumeName = ($line -split 'partition \[')[1]
			$volumeName = ($volumeName -split '\] ')[0]
			Write-Output ("`nProblem:`n" + $time + ' Insufficient disk space on system partition ' + $volumeName)
			Write-Output "`nSolution:`nSome 3rd party softwares may have added data to the system partition. `nMount the system partition with `"mountvol {driveletter:} /S`" and then check, under the `"EFI`" folder on the mounted drive, if there are folders other than `"Microsoft`" and `"BOOT`""
			Write-Output 'Contact the 3rd party software vendor to check if that folder can be deleted'
		}

		#case #1010
		elseif ($line -match 'User profile suffix mismatch: upgrade asked for') {
			$time = ($line -split ',')[0]
			$profileName = ($line -split 'upgrade asked for ')[1]
			$profileName = ($profileName -split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Upgrade failed because the profile folder for ' + $profileName + ' already exists')
			Write-Output "`nSolution:`nThere are many possible causes for this problem. Below are some of the known causes"
			Write-Output '1. HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\ProfileList contains multiple SIDs with the same user name'
			Write-Output '   If this is the case, remove the duplicated entries'
			Write-Output '2. HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\WMI\Autologger contains autologger entries for which the FileName is set to be under this profile folder'
			Write-Output '   If this is the case, remove that autologger entry'
			Write-Output '3. Some special shell folder, like CSIDL_COMMON_DESKTOPDIRECTORY, are redirected to somewhere under this profile folder'
			Write-Output '   If this is the case, stop redirecting or redirect it to somewhere else'
		}


		#case #1011
		elseif ($line -match 'BFSVC: BCD Error: Failed to set boot entry order') {
			$time = ($line -split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Error when accessing BCD - Boot Configuration Data')
			Write-Output "`nSolution:`nThe device's firmware is restricting access to BCD storage. Please contact device maker for instructions on how to unlock it"
		}

		#case 1012
		elseif ($line -match 'AppxUpgradeMigrationPlugin.dll:Gather - plugin call timed out') {
			$time = ($line -split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Plugin call timed out for AppxUpgradeMigrationPlugin.dll, maybe due to too many user profile.')
			Write-Output "`nSolution:`nChange the timeout value and/or reduce number of user profiles"
			Write-Output '1. Run cmd.exe as administrator and use the following command to change the timeout values'
			Write-Output 'SETX MIG_PLUGIN_CALL_TIMEOUT 90 /M'
			Write-Output 'SETX MIG_PLUGIN_CALL_TIMEOUT_INTERVALS 60;10 /M'
			Write-Output '2. Delete no longer used user profiles.'
		}
		#case 1013
		elseif ($line -Match 'BCD: BcdExportStore: Failed clone BCD') {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + 'BCD: BcdExportStore: Failed clone BCD')
			Write-Output "`nSolution:`You may be affected by a filter driver from a third party product, or a drive that is not a system volume may be recognized as a system volume."
			Write-Output 'Try the following actions'
			Write-Output '1. execute FU with USB memory removed'
			Write-Output '2. Disable or uninstall any third-party security products or third-party anti-virus software, and then perform FU.'
		}
		#case 1014 is used outside the loop.
		#use case 1015 for next case
	}

	#case 1014
	#special case. The log ends up with processing the audio driver
	if (($has_Conexant_ISST_Audio) -and ($l_executing_phases.Count -eq 0)) {
		Write-Output ("`nProblem:`nIncompatible Conexant ISST audio driver causing hang in upgrade.")
		Write-Output "`nSolution:`nCheck the device manufacturer to see if an updated driver of Conexant ISST Audio is available, or just uninstall the driver."
	}

	if ($AdditionalLogInformation) {
		if (($null -ne $host_os_edition) -and ($null -ne $target_os_edition)) {
			Write-Output "`nSummary information:"					  #-ForegroundColor Yellow
			Write-Output '		 Edition	  Arch	 Version	   Lang'
			Write-Output ('Host:   ' + $host_os_edition + ' ' + $host_os_arch + ' ' + $host_os_version)
			Write-Output ('Target: ' + $target_os_edition + ' ' + $target_os_arch + ' ' + $target_os_version + ' ' + $target_os_lang + "`n")

			if ($null -ne $upgrade_begin_time) {
				Write-Output ('Upgrade start time:  ' + $upgrade_begin_time)
			}
			if ($l_executing_phases.Count -ne 0) {
				$i = 1
				$phaseString = "Upgrade phases:`n"
				foreach ($phase in $l_executing_phases) {
					if ($i -ne $l_executing_phases.Count) {
						$phaseString += '					 ' + $phase + "`n"
					}
					else {
						$phaseString += '					 ' + $phase
					}
					$i++
				}
				Write-Output $phaseString
			}
			else {
				Write-Warning 'no executing phase found - upgrade was terminated before [Safe OS] phase'
			}

			if ($null -ne $upgrade_end_time) {
				Write-Output ('Upgrade end time:	' + $upgrade_end_time)
			}
			elseif ($null -ne $upgrade_failed_time) {
				if ($null -ne $upgrade_failed_phase) {
					Write-Output ('Upgrade failed time: ' + $upgrade_failed_time + " `(At " + $upgrade_failed_phase + " phase`)")
				}
				else {
					Write-Output ('  Upgrade failed time: ' + $upgrade_failed_time)
				}
			}
			else {
				Write-Warning "didn't find upgrade end time"
			}
		}
		else {
			Write-Output $host_os_edition
			Write-Output $target_os_edition
		}

	}
}

#-------   end of Parse-UpgradeLog() -------




#------- Start of Parse-SysprepLog -------
Function Parse-SysprepLog() {
	param(
		[parameter(Mandatory)]
		[System.IO.StreamReader]$infile
	)
	$has_package_blocking_sysprep = $FALSE
	$l_package_blocking_sysprep = New-Object System.Collections.ArrayList($NULL)

	Write-Verbose 'in Parse-SysprepLog'

	while ( $NULL -ne ($line = $infile.ReadLine()) ) {


		#case #3001
		if ($line -Match 'was installed for a user, but not provisioned for all users. This package will not function properly in the sysprep image') {
			$has_package_blocking_sysprep = $TRUE
			$packageName = ($line -Split 'SYSPRP Package ')[1]
			$packageName = ($packageName -Split ' ')[0]
			$addToList = $TRUE
			foreach ($item in $l_package_blocking_sysprep) {
				if ($item -eq $packageName) {
					$addToList = $FALSE
					break
				}
			}
			if ($addToList -eq $TRUE) {
				$NULL = $l_package_blocking_sysprep.Add($packageName)
			}
		}
		#case #3002
		elseif ( ($line -Match 'SYSPRP Failed while deleting repository files') -And ($line -Match '0x80070005') ) {
			$time = ($line -Split ',' )[0]
			Write-Output ("`nProblem:`n" + $time + ' ERROR_ACCESS_DENIED when deleting repository files.')
			Write-Output "`nSolution:`nMake sure you are using the built-in Administrator account to run SYSPREP.`nPlease also check https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--system-preparation--overview#unsupported-scenarios"
		}


		#case #3003
		elseif ( ($line -Match "Audit mode can\'t be turned on if there is an active scenario") -And ($line -Match '0x800F0975') ) {
			$time = ($line -Split ',' )[0]
			Write-Output ("`nProblem:`n" + $time + ' SYSPREP failed to enter Audit mode, probably because Windows Update is currently using reserved storage.')
			Write-Output "`nSolution:`nTry disconnect the device from network, then carry out the following steps to cancel any in-progress Windows Update session, and rerun SYSPREP:"
			Write-Output "1. Go to Settings -> Update & Security -> Windows Update -> Advanced options -> Pause updates, and Set `"Pause until`" to anytime in the future"
			Write-Output "2. Set `"ActiveScenario`" under `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager`" to 0 "
		}

		#case #3004
		elseif ( ($line -Match 'Failure occurred while executing') -And ($line -Match 'clipc.dll') -And ($line -Match '0xc0020036') ) {
			$time = ($line -Split ',' )[0]
			Write-Output ("`nProblem:`n" + $time + ' SYSPREP failed probably because Client License Service (ClipSVC) is disabled.')
			Write-Output "`nSolution:`nPlease enable Client License Service (ClipSVC)"
		}

		#case #3005
		elseif ($line -Match 'Failed to delete Authentication key subtree') {
			$time = ($line -Split ',' )[0]
			Write-Output ("`nProblem:`n" + $time + ' SYSPREP failed to delete registry subtree under HKCU\Software\Microsoft\Windows\CurrentVersion\Authentication')
			Write-Output "`nSolution:`nCheck if the Administrators group is not given full control access to any of the subkeys under HKCU\Software\Microsoft\Windows\CurrentVersion\Authentication"
			Write-Output 'If not, add full control access for the Adminstrators group to that key'
		}

		#case #3006
		elseif ($line -Match 'Failed to remove staged package') {
			$time = ($line -Split ',' )[0]
			$packageName = ($line -Split 'Failed to remove staged package ')[1]
			$packageName = ($packageName -Split ':')[0]
			Write-Output ("`nProblem:`n" + $time + ' SYSPREP failed to remove staged package ' + $packageName + '.')
			Write-Output ("`nSolution:`nRemove the " + $packageName + ' package manually.')
			Write-Output "If the package is not a system app, then you can use `"Remove-AppxPackage -Package {pakcagename}`" powershell command to remove it."
			Write-Output 'If the package is a system app, please contact Microsoft support on how to remove it.'
		}

	}

	if ( $has_package_blocking_sysprep -eq $TRUE ) {
		Write-Output "`nProblem:`nThe following packages are installed but not provisioned for all users, and some of them are causing errors in SYSPREP."
		foreach ($item in $l_package_blocking_sysprep) {
			Write-Output ('	' + $item)
		}
		Write-Output "`nSolution:`nTry uninstalling these packages with powershell command `"Get-AppxPackage -Name {package-name} | Remove-AppxPackage`""
	}
}
#------- End of Parse-SysprepLog -------


#------- Start of Parse-OobeLog() -------
Function Parse-OobeLog() {
	param(
		[parameter(Mandatory)]
		[System.IO.StreamReader]$infile
	)

	Write-Verbose 'in Parse-OobeLog'

	while ( $NULL -ne ($line = $infile.ReadLine()) ) {

		#case #2001
		if ($line -Match 'Not allowed to run the Setupcomplete.cmd, will not run SetupComplete.cmd') {
			$time = ($line -Split ',' )[0]
			Write-Output ("`nProblem:`n" + $time + ' You are using OEM product key for which SetupComplete.cmd is disabled. This may become a problem if you are using SCCM task sequence to upgrade the OS.')
			Write-Output "`nSolution:`nCheck https://support.microsoft.com/en-in/help/4494015 for solutions if you are using SCCM."
		}

		#case #2002
		elseif ($line -Match 'Failed to read in time zone information for time zone') {
			$time = ($line -Split ',' )[0]
			$timezoneName = ($line -Split 'for time zone ')[1]
			$timezoneName = ($timezoneName -Split ' with')[0]
			Write-Output ("`nProblem:`n" + $time + " The time zone information for `"" + $timezoneName + "`" under `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones`" is not in correct format.")
			Write-Output "`nSolution:`nFill in correct data in the above registry setting for the time zone, or delete it."
		}
	}
}
#-------   End of Parse-OobeLog() -------

#-------   Start of Parse-CbsLog() -------
Function Parse-Cbslog {
	param(
		[parameter(Mandatory)]
		[System.IO.StreamReader]$infile
	)

	$has_manifest_mismatch = $FALSE
	$loading_user_account = $FALSE
	$loading_user_account_sid = $NULL
	$profile_unloaded_sid = $NULL
	$l_corrupt_manifest = New-Object System.Collections.ArrayList($NULL)
	$l_corrupt_files = New-Object System.Collections.ArrayList($NULL)
	#[CbsProcessingStartEnd]$cbsStart
	#$l_cbsprocessing_startend = New-Object System.Collections.ArrayList($NULL)

	$font_detector_has_component = $FALSE
	$font_detector_has_installer = $FALSE
	$font_detector_already_detected = $FALSE

	$EFI_GUID_detector_already_detected = $FALSE

	$network_driver_detector_has_installer = $FALSE
	$network_driver_detector_already_detected = $FALSE

	Write-Verbose 'in Parse-CbsLog'

	while ( $NULL -ne ($line = $infile.ReadLine()) ) {
		<#
			if($line -match "Exec: Processing started")
			{
				$time = ($line -Split "," )[0]
				$info = "Session " + ($line -Split "Session" )[1]
				$cbsStart = [CbsProcessingStartEnd]::new($TRUE, $time, $info)
				$null = $l_cbsprocessing_startend.add($cbsStart)

			}
			elseif($line -match "Exec: Processing complete")
			{
				$time = ($line -Split "," )[0]
				$info = "Session " + ($line -Split "Session" )[1]
				$cbsEnd = [CbsProcessingStartEnd]::new($FALSE, $time, $info)
				$null = $l_cbsprocessing_startend.add($cbsEnd)
			}
			#>

		#case #1
		#Disable this one for now because it is too noisy.
		#			if 'Higher version found for package: Package_for_RollupFix' in line:
		#				#only choose the RollupFix ones for this case. It looks like the lower version of FoD packages are retried and it causes noises.
		#				time = line.split(',')[0]
		#				InstalledVersion = line.split('Version on system:')[1]
		#				InstalledVersion = InstalledVersion.split(')')[0]
		#				KBVersion = line.split('Higher version found for package:')[1]
		#				KBVersion = KBVersion.split(',')[0]
		#				print('\nProblem: \n' + time + ' Windows Update package', KBVersion, 'failed to install because a newer version of KB ', InstalledVersion, ' is already installed on this machine')
		#				print('\nSolution: \nYou do not need to install this KB')

		#case #2
		if (($line -Match 'Error') -and ($line -Match 'requires Servicing Stack')) {
			$time = ($line -Split ',' )[0]
			$SSUVersion = ($line -Split 'requires Servicing Stack')[1]
			$SSUVersion = ($SSUVersion -Split ' ')[1]
			$KBVersion = ($line -Split "`"")[1]
			$KBVersion = ($KBVersion -Split "`"")[0]
			Write-Output ("`nProblem:`n" + $time + ' Windows Update package ' + $KBVersion + ' failed to install because a newer version of Service Stack Update is required')
			Write-Output ("`nSolution:`nInstall SSU version " + $SSUVersion + ' and then retry installing the Windows Update package')
		}

		#case #3
		elseif ($line -Match 'applicable state: Installed Invalid') {
			$time = ($line -Split ',' )[0]
			$KBNumber = ($line -Split '_for_')[1]
			$KBNumber = ($KBNumber -Split '~')[0]
			Write-Output ("`nProblem:`n" + $time + ' Some sub-packages of ' + $KBNumber + ' that is installed on this machine is marked as InstalledButInvalid')
			Write-Output "`nSolution:`nIn regedit.exe, under `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages`", find all instances of `"CurrentState`" that is set to 0xffffff90, and change all the values from  0xffffff90 to 0x70, then reboot and retry the installation"
		}
		#case #4
		elseif ( ($line -Match 'SupplementalServicing') -And ($line -Match 'This machine is not eligible for supplemental servicing') ) {
			$time = ($line -Split ',' )[0]
			Write-Output ("`nProblem:`n" + $time + ' Trying to install KB on Windows that is out of support')
			Write-Output "`nSolution:`nPlease upgrade to newer, supported versions of Windows 10"
		}
		#case #5
		elseif ($line -Match 'A possible hang was detected on the last boot') {
			$time = ($line -Split ',' )[0]
			Write-Output ("`nProblem:`n" + $time + ' Hang was detected in CBS startup processing')
			Write-Output "`nSolution:`nNeed to troubleshoot why the CBS startup processing is not finished in time."
		}


		#case #6
		elseif ($line -Match 'Manifest hash mismatch') {
			$has_manifest_mismatch = $True
			if ($line -Match "'.*'") {
				foreach ($filename in $Matches[0]) {
					if ($l_corrupt_manifest -NotContains $filename) {
						$null = $l_corrupt_manifest.add($filename)
					}
				}
			}
		}

		#case #7
		elseif ($line -Match 'Failed while processing critical primitive operations queue') {
			$time = ($line -Split ',' )[0]
			$errorCode = ($line -Split 'HRESULT = ')[1]
			$errorCode = ($errorCode -Split "`]")[0]
			Write-Output ("`nProblem:`n" + $time + ' Error (' + $errorCode + ') occurred when carrying out primitive operations (operations on files or registries)')
			Write-Output "`nSolution:`n3rd party filesystem filter drivers may cause this problem. Please uninstall 3rd party security softwares and try again"
		}
		#case #8
		elseif ($line -Match 'FOD: Mismatched package') {
			$time = ($line -Split ',' )[0]
			$cabFile = ($line -Split 'Mismatched package: ')[1]
			$cabFile = ($cabFile -Split ',')[0]
			$fodVersion = ($line -Split 'FOD identity:')[1]
			$fodVersion = ($fodVersion -Split ',')[0]
			$fodVersion = ($fodVersion -Split '~~')[1]
			$cabVersion = ($line -Split 'cab identity:')[1]
			$cabVersion = ($cabVersion -Split "`n")[0]
			$cabVersion = ($cabVersion -Split '~~')[1]
			Write-Output ("`nProblem:`n" + $time + " The version of the FOD package `"" + $cabFile + "`" is not correct. Version of the package provided: " + $cabVersion + '. Version needed: ' + $fodVersion)
			Write-Output ("`nSolution:`nDownload the FOD package with version " + $fodVersion + ' and try again')
		}

		#case #9
		elseif ( ($line -Match 'Failed to add package') -And ($line -Match 'ERROR_DISK_FULL') ) {
			$time = ($line -Split ',' )[0]
			$packageFile = ($line -Split 'Failed to add package: ')[1]
			$packageFile = ($packageFile -Split ' \[')[0]
			Write-Output ("`nProblem:`n" + $time + ' ERROR_DISK_FULL error when installing ' + $packageFile)
			Write-Output "`nSolution:`nCleanup the system disk with the Disk Cleanup tool to make more free spaces"
		}


		#case #10
		elseif ($line -Match 'Store corruption, manifest missing for package:') {
			$time = ($line -Split ',')[0]
			$packageFile = ($line -Split 'Store corruption, manifest missing for package: ')[1]
			$packageFile = ($packageFile -Split "`n")[0]
			Write-Output ("`nProblem:`n" + $time + ' Manifest missing for package: ' + $packageFile)
			Write-Output "`nSolution:`nDownload the standalone KB package, expand it and install the expanded cab file with `"Dism /online /Add-Package /PackagePath:{full-path-to-the-expanded-cab-file}`""
		}


		#case #11
		elseif ($line -Match 'Exec: Some sessions are pended with exclusive flag set') {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\SessionsPending:Exclusive is not 0. Windows Update will not be installed correctly in this state')
			Write-Output "`nSolution:`nChange the above reg setting to 0 in regedit.exe, and retry installing Windows Update packages"
		}


		#case #12
		elseif (($line -Match 'STATUS_DELETE_PENDING') -And ($line -Match 'SysCreateFile') -And ($line -Match 'on:\[') ) {
			$info_list = $line -Split ','
			$time = $info_list[0]
			foreach ($item in $info_list) {
				if (($item -Match 'on:') -and ($item -Match "'.*'")) {
					foreach ($filename in $Matches[0]) {
						Write-Output ("`nProblem:`n" + $time + ' STATUS_DELETE_PENDING error when opening ' + $filename)
						Write-Output "`nSolution: `nTroubleshoot this file/directory open error using Process Monitor or other filesystem utilities"
					}
				}
			}
		}

		#case #13
		elseif ($line -Match 'Loading user account SID') {
			$loading_user_account = $TRUE
			$loading_user_account_sid = ($line -Split 'SID ')[1]
			$loading_user_account_sid = ($loading_user_account_sid -Split "`n")[0]
		}
		elseif ( ($line -Match 'Loaded') -And ($line -Match "'user account profiles") ) {
			$loading_user_account = $FALSE
		}
		elseif ( ($line -Match 'Error') -And ($line -Match 'AutoHive::Load') ) {
			if ( ($loading_user_account -Eq $TRUE) -And ($NULL -ne $loading_user_account_sid) ) {
				$time = ($line -Split ',')[0]
				$errorString = ($line -Split ': Error ')[1]
				$errorString = ($errorString -Split ' ')[0]
				Write-Output ("`nProblem:`n" + $time + ' ' + $errorString + ' error when loading user profile for user ' + $loading_user_account_sid)
				Write-Output "`nSolution:`nTroubleshoot this profile load error with Process Monitor or other filesystem activity monitoring tools"
			}
		}

		#case #14
		elseif ($line -Match 'STATUS_FILE_CORRUPT_ERROR') {
			$info_list = $line -Split ','
			$time = $info_list[0]
			foreach ($item in $info_list) {
				if (($item -Match 'on:') -and ($item -Match "`".*`"")) {
					foreach ($filename in $Matches[0]) {
						if ($l_corrupt_files -NotContains $filename) {
							$null = $l_corrupt_files.add($filename)
							Write-Output ("`nProblem:`n" + $time + ' Component store file corruption detected. File name is: ' + $filename)
							Write-Output "`nSolution: `nRepair the corrupted files by using DISM.exe /Online /Cleanup-image /retorehealth"
						}
					}
				}
			}
		}
		#case #15
		elseif ( ($line -Match 'Error') -And ($line -Match 'failed to perform Synchronous Cleanup operation') -And ($line -Match '0x80070002') ) {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Error 0x80070002 was detected in component cleanup during Cab file compression.')
			Write-Output "`nSolution:`nThis is a known issue in Windows 10 Version 1607 or earlier. You can ignore this error."
			Write-Output 'Please check https://docs.microsoft.com/ja-jp/archive/blogs/askcorejp/componentcleanup_win10 for more details'
		}

		#case #16
		elseif ( ( ($line -Match 'Failed to pin deployment while resolving Update') -And ($line -Match 'ERROR_SXS_ASSEMBLY_MISSING') -And ($line -Match 'Package_') ) -Or ( ($line -Match 'Failed to resolve execution package') -And ($line -Match 'ERROR_SXS_ASSEMBLY_MISSING') -And ($line -Match 'Package_') ) ) {
			$time = ($line -Split ',')[0]
			$kbName = ($line -Split '_for_')[1]
			$kbName = ($kbName -Split '~')[0]
			Write-Output ("`nProblem:`n" + $time + ' Some components are missing for ' + $kbName)
			Write-Output ("`nSolution:`nDownload the standalone " + $kbName + " package, expand it and install the expanded cab file with `"Dism /online /Add-Package /PackagePath:{full-path-to-the-expanded-cab-file}`"")
		}

		#			elseif( ($line -Match "Failed to resolve execution package") -And ($line -Match "ERROR_SXS_ASSEMBLY_MISSING") -And ($line -Match "Package_") )
		#			{
		#				$time = ($line -Split ",")[0]
		#				$kbName = ($line -Split "_for_")[1]
		#				$kbName = ($kbName -Split "~")[0]
		#				Write-Output "`nProblem:"
		#				Write-Output time,  "Some components are missing for", $kbName
		#				Write-Output "`nSolution:`nDownload the standalone", $kbName, "package, expand it and install the expanded cab file with `"Dism /online /Add-Package /PackagePath:{full-path-to-the-expanded-cab-file}`""
		#			}
		#case #17
		##			elif 'Manifest hash for component' in line and 'does not match expected value' in line:
		##				time = line.split(',')[0]
		##				componentName = None
		##				if '\"' in line:
		##					componentName = line.split('\"')[1]
		##				elif '\'' in line:
		##					componentName = line.split('\'')[1]
		##				if componentName is None:
		##					print('\nProblem: \n' + time + ' Found incorrect manifest hash value for components in the component store')
		##				else:
		##					print('\nProblem: \n' + time + ' Found incorrect manifest hash value for ' + componentName + ' in the component store')
		##				print('\nSolution: \nPlease fix component store corruptions with the \"Dism /Online /Cleanup-Image /RestoreHealth\" command')
		##				print('Check https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image for more details')

		#case #18
		elseif ($line -Match 'Store corruption detected in function') {
			$time = ($line -Split ',')[0]
			$line = $infile.readline() # read the next line because it contains the resource name
			if ($null -eq $line) {
				break
			}
			if ($line -Match 'on resource') {
				$resourceName = $NULL
				if ($line -Match "`"") {
					$resourceName = ($line -Split "`"")[1]
				}
				elseif ($line -Match "`'") {
					$resourceName = ($line -Split "`'")[1]
				}

				if ($NULL -eq $resourceName) {
					Write-Output ("`nProblem:`n" + $time + ' Found corruption in the component store')
					Write-Output "`nSolution:`nPlease fix component store corruptions with the `"Dism /Online /Cleanup-Image /RestoreHealth`" command"
					Write-Output 'Check https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image for more details'
				}
				elseif ($resourceName -eq '\Registry\Machine\COMPONENTS\\StoreDirty') {
					Write-Output ("`nProblem:`n" + $time + ' StoreDirty flag is set in component store')
					Write-Output "`nSolution:`nRun the following commands in an elevated command prompt to delete the StoreDirty flag"
					Write-Output '1. REG LOAD HKLM\COMPONENTS C:\Windows\System32\config\components'
					Write-Output '2. REG Delete HKLM\COMPONENTS /v StoreDirty /f'
				}
				else {
					Write-Output ("`nProblem:`n" + $time + ' Found corruption in the component store. Resource name is ' + $resourceName)
					Write-Output "`nSolution:`nPlease fix component store corruptions with the `"Dism /Online /Cleanup-Image /RestoreHealth`" command"
					Write-Output 'Check https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image for more details'
				}
			}
		}


		#case #19
		elseif ( ($line -Match 'STATUS_OBJECT_NAME_NOT_FOUND') -And ($line -Match 'SysOpenKey') -And ($line -Match '\\REGISTRY\\USER\\') ) {
			$profile_unloaded_sid = ($line -Split '\\REGISTRY\\USER\\')[1]
			$profile_unloaded_sid = ($profile_unloaded_sid -Split "`'")[0]
		}
		elseif ( ($line -Match 'STATUS_OBJECT_NAME_NOT_FOUND') -And ($line -Match 'OpenProfileRootKey') -And ($NULL -ne $profile_unloaded_sid) ) {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Cannot access user profile for ' + $profile_unloaded_sid)
			Write-Output "`nSolution:`nPlease check if there are scheduler tasks that uses the `"At startup`" trigger and the user account for that task is set to the above user"
			Write-Output 'If there are such tasks, consider changing the settings for those tasks as follows'
			Write-Output '1. Change the user account to System'
			Write-Output '2. Temporarily disable these tasks when installing Windows updates'
			Write-Output "3. Temporarily enable the `"Do not forcefully unload the users registry at user logoff`" policy under `"Computer Configuration\Administrative Templates\System\User Profiles`""
		}

		#case #20
		elseif ( ($line -Match 'AppX Registration Installer') -And ($line -Match '1058') ) {
			#1058 == ERROR_SERVICE_DISABLED
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + " Failed to run Appx Registration Installer because the `"App Readiness`" service is disabled")
			Write-Output "`nSolution:`nPlease set the startup type of the `"App Readiness`" service to `"Manual`""
		}

		#case #21
		elseif ($line -Match 'Font') {
			$font_detector_has_component = $TRUE
		}
		elseif ($line -Match 'CSI Cleanup Cache Installer') {
			$font_detector_has_installer = $TRUE
		}
		elseif ( ($line -Match 'Error') -And ($line -Match 'MarkFileDeletePending') -And ($font_detector_has_component -Eq $TRUE) -And ($font_detector_has_installer -Eq $TRUE) -And ($font_detector_already_detected -Eq $FALSE) ) {
			$font_detector_already_detected = $TRUE
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Failed to uninstall Font by CSI Cleanup Cache Installer.')
			Write-Output "`nSolution:`nPlease delete font cache C:\\Windows\\System32\\FNTCACHE.DAT in administrator mode and try again."
			Write-Output "If it cannot be deleted, stop (not disable) the `"Windows Font Cache Service`" service and try again."
		}
		#case #22
		elseif ( ($line -Match 'Failed to get system partition! Last Error = 0x3bc3') -And ($EFI_GUID_detector_already_detected -Eq $FALSE) ) {
			$EFI_GUID_detector_already_detected = $TRUE
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + " Failed to update BCD related component as the system partition's attribute is basic, not EFI.")
			Write-Output "`nSolution:`nPlease reallocate EFI GUID to the system partition."
		}

		#case #23
		elseif ( ($line -Match 'Network Drivers') -And ($network_driver_detector_has_installer -Eq $FALSE) ) {
			$network_driver_detector_has_installer = $TRUE
		}
		elseif ( ($line -Match 'Error') -And ($line -Match '800106d9') -And ($network_driver_detector_has_installer -Eq $TRUE) -And ($network_driver_detector_already_detected -Eq $FALSE) ) {
			if ( ($line -Match 'Failed execution of queue item Installer: Network Drivers') -Or ($line -Match 'Network Drivers') ) {
				$network_driver_detector_already_detected = $TRUE
				$time = ($line -Split ',')[0]
				Write-Output ("`nProblem:`n" + $time + ' Failed to update Network Driver.')
				Write-Output "`nSolution:`nPlease isolate Network Setup Service by running this command below and try installing the KB again."
				Write-Output '<sc config netsetupsvc type= own>'
				Write-Output 'When finished, run the command below to restore the original setting'
				Write-Output '<sc config netsetupsvc type= share>'
			}
		}

		#case #24
		elseif ( ($line -Match 'Doqe: Recording result') -And ($line -Match 'for Inf') ) {
			$time = ($line -Split ',')[0]
			$errorCode = ($line -Split 'result: ')[1]
			$errorCode = ($errorCode -Split ',')[0]
			$infName = ($line -Split 'for Inf: ')[1]
			$infName = ($infName -Split '\n')[0]
			Write-Output ("`nProblem:`n" + $time + ' Driver update failed for ' + $infName + ' with error ' + $errorCode)
			Write-Output "`nSolution:`nPlease check $env:windir\inf\setupapi.dev.log for error details, and also check the registry settings for this driver"
		}


		#case #25
		elseif ($line -Match 'c01a001d') {
			#STATUS_LOG_FULL
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' STATUS_LOG_FULL error occurred')
			Write-Output "`nSolution:`nUse the following steps to reset the transaction logs under %windir%\system32\config\txr"
			Write-Output '1. Download the MoveFile tool from https://docs.microsoft.com/en-us/sysinternals/downloads/movefile'
			Write-Output '2. Run cmd.exe as administrator'
			Write-Output '3. Run the 2 commands below to make the transaction files accessible'
			Write-Output '   cd /d %windir%\system32\config\txr'
			Write-Output '   attrib -r -s -h *'
			Write-Output '4. Move to the folder that contains the Movefile tool, and then run the following commands'
			Write-Output "   movefile.exe `"%windir%\System32\config\TxR\{711988c4-afbd-11e6-80c9-782bcb3928e1}.TxR.0.regtrans-ms`" `"`""
			Write-Output "   movefile.exe `"%windir%\System32\config\TxR\{711988c4-afbd-11e6-80c9-782bcb3928e1}.TxR.1.regtrans-ms`" `"`""
			Write-Output "   movefile.exe `"%windir%\System32\config\TxR\{711988c4-afbd-11e6-80c9-782bcb3928e1}.TxR.2.regtrans-ms`" `"`""
			Write-Output "   movefile.exe `"%windir%\System32\config\TxR\{711988c4-afbd-11e6-80c9-782bcb3928e1}.TxR.blf`" `"`""
			Write-Output "   movefile.exe `"%windir%\System32\config\TxR\{711988c4-afbd-11e6-80c9-782bcb3928e1}.TM.blf`" `"`""
			Write-Output "   movefile.exe `"%windir%\System32\config\TxR\{711988c4-afbd-11e6-80c9-782bcb3928e1}.TMContainer00000000000000000001.regtrans-ms`" `"`""
			Write-Output "   movefile.exe `"%windir%\System32\config\TxR\{711988c4-afbd-11e6-80c9-782bcb3928e1}.TMContainer00000000000000000002.regtrans-ms`" `"`""
			Write-Output '5. Restart your machine'
		}

		#case #26
		elseif ($line -Match 'PerfCounterInstaller Error: Counter database is corrupted') {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' Performace Counter database is corrupt')
			Write-Output "`nSolution:`nUse the following steps to repair the Performance Counter databese"
			Write-Output '1.Run cmd.exe as administrator'
			Write-Output '2. C:\Windows\System32\lodctr /R'
			Write-Output '3. C:\Windows\SysWOW64\lodcrt /R'
		}

		#case #27

		elseif ( ($line -Match 'Failed to pre- stage package') -And ($line -Match '0x800f0988') ) {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' PSFX_E_INVALID_DELTA_COMBINATION error occurred due to file corruption')
			Write-Output "`nSolution:`nPlease run StartComponentCleanup and Restorehealth"
			Write-Output '1. Run cmd.exe as administrator'
			Write-Output '2. DISM.exe /Online /cleanup-image /StartComponentCleanup'
			Write-Output '3. DISM.exe /Online /Cleanup-image /Restorehealth'
		}

		#case #28
		elseif ($line -Match 'ESU: Failed to Get PKey Info c004f014') {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' ESU: Failed to find product key (SL_E_PKEY_NOT_INSTALLED)')
			Write-Output "`nSolution:`nTry rebuilding the Tokens.dat file with the following steps"
			Write-Output '1. Run cmd.exe as administrator'
			Write-Output '2. net stop sppsvc'
			Write-Output '3. For Windows 10, Windows Server 2016 and later versions of Windows:'
			Write-Output '	 cd %windir%\system32\spp\store\2.0'
			Write-Output '   For Windows Server 2012 and Windows Server 2012 R2:'
			Write-Output '	 cd %windir%\ServiceProfiles\LocalService\AppData\Local\Microsoft\WSLicense'
			Write-Output '   For Windows 7, Windows Server 2008 and Windows Server 2008 R2:'
			Write-Output '	 cd %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform'
			Write-Output '4. ren tokens.dat tokens.bar'
			Write-Output '5. net start sppsvc'
			Write-Output '6. cscript.exe %windir%\system32\slmgr.vbs /rilc'
			Write-Output '7. Restart the computer'
			Write-Output 'PLease also check https://docs.microsoft.com/en-US/troubleshoot/windows-server/deployment/rebuild-tokens-dotdat-file'
		}
		#case #29
		elseif ($line -Match 'Failed to get user security token') {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + 'Failed to get user security token')
			Write-Output "`nSolution:`nUse the following steps to check your DCOM Settings"
			Write-Output '1. Run the below command as Administrator to open the component service'
			Write-Output 'dcomcnfg.exe '
			Write-Output '2. Open Component Services -> Computers -> My Computer -> Properties -> Default Properties, please check if Default Authentication Level is set to Connect, if not, please correct it. The Default Authentication Level is set to none on the issue server'
		}
		#case #30

		#case #31
		elseif (($line -Match ' Failed execution of queue item Installer: Extended Security Updates AI installer ') -And ($line -Match 'CRYPT_E_NOT_FOUND')) {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' CRYPT_E_NOT_FOUND')
			Write-Output "`nSolution:`nYou may be experiencing a TLS certificate problem. Import additional certificates and apply the update again."
			Write-Output 'Download and import the certificates (Microsoft RSA TLS CA 01.crt and Microsoft RSA TLS CA 02.crt) from the URL below.'
			Write-Output 'URL : microsoft.com/pki/mscorp/cps/default.htm'
		}

		#case #32
		elseif (($line -Match 'ESU: not eligible') -And ($line -Match 'HRESULT_FROM_WIN32\(1633\)')) {
			$time = ($line -Split ',')[0]
			Write-Output ("`nProblem:`n" + $time + ' ESU license has not been activated')
			Write-Output "`nSolution:`nYou need to install and activate ESU license."
			Write-Output 'PLease check https://techcommunity.microsoft.com/t5/windows-it-pro-blog/obtaining-extended-security-updates-for-eligible-windows-devices/ba-p/1167091'
		}

		#case #33
		elseif ($line -Match 'Failed execution of queue item') {
			#this is the general handler of this error. There are 2 specific errors above (#23 #31)
			$time = ($line -Split ',')[0]
			$strItem = ($line -Split 'queue item ')[1]
			$strItem = ($strItem -Split ' with')[0]
			$strError = ($line -Split 'HRESULT_FROM_WIN32')[1]
			$strError = ($strError -Split '. ')[0]
			Write-Output ("`nProblem:`n" + $time + ' Error ' + $strError + ' when executing ' + $strItem)
			Write-Output "`nSolution:`nNeed to further investigate this error in details"
		}

	}


	#Out of the read-fileline loop
	#manifest mismatch
	if ($has_manifest_mismatch -Eq $TRUE) {
		Write-Output "`nProblem: `nThe following manifests' hashes are incorrect"
		foreach ( $item in $l_corrupt_manifest) {
			Write-Output ('	' + $item )
		}
		Write-Output "`nSolution: Please fix component store corruptions with the `"Dism /Online /Cleanup-Image /RestoreHealth`" command"
		Write-Output 'Check https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image for more details'
	}

	if ($AdditionalLogInformation) {
		<#
		if($l_cbsprocessing_startend.Count -ne 0)
		{
			Write-Output "`nSummary information:"			   #-ForegroundColor Yellow

			foreach( $cbsStartEnd in $l_cbsprocessing_startend)
			{
				if($cbsStartEnd.isStart)
				{
					Write-Output ("`nCBS Session Start: " + $cbsStartEnd.time + "  Info: " + $cbsStartEnd.info)
				}
				else
				{
					Write-Output ("CBS Session end:   " + $cbsStartEnd.time + "  Info: " + $cbsStartEnd.info)
				}
			}
		}
		#>
	}
	<#
	if has_manifest_mismatch:
		print('\nProblem: \nManifest hash mismatch')
		with open('corrupted_manifest.txt', 'w') as f:
			for item in set(flat_list):
				f.write("%s\n" % item)
		if hivename is None:
			print('\nSuggestion1: See Corrupted_manifest.txt for mismatched manifests. ')
			print('\nSuggestion2: Please also specify .hiv of HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion and rerun as Administrator for further investigation. E.g.: -hiv path_to_software.hiv')
		else
		{
			# Retrieve .reg from .hiv. This needs to be done in Administrator mode.
			temp_hiv = "HKLM\\Temp"
			cbs_hiv = "HKLM\\Temp\\Component Based Servicing"
			os.makedirs('./tmp', exist_ok=True)
			reg_path = "./tmp/CBS_hiv.reg"
			print(hivename.replace('\\', '/'))
			subprocess.run(['reg.exe', 'load', temp_hiv, hivename.replace('\\', '/')])
			subprocess.run(["reg.exe", "export", cbs_hiv, reg_path])
			subprocess.run(["reg.exe", "unload", temp_hiv])

			#testloc = r".\demolog\Component Based Servicing2.reg" #cleng thoughts - need to automate this - retrieve reg file from software.hiv
			# Create registry parser.
			regdata = configparser.ConfigParser()
			with open(reg_path, "r", encoding="utf-16") as f:
				f.readline()  # skip version info in first line
				regdata.read_file(f)
			OCCURANCE = 3
			with open('corrupted_component.csv', 'w') as f:
				f.write('Comp Name, Reg Name, Comp Version, Related KB\n')
				for idx, comp_item in enumerate(set(flat_list)):
					groups = comp_item.split('_')
					comp_name, comp_ver= '_'.join(groups[:OCCURANCE]),'_'.join(groups[OCCURANCE:OCCURANCE+1])
					# Find the related KB specified in the registry.
					for reg_key in regdata.sections():
						if comp_name in reg_key:
							for (each_key, each_val) in regdata.items(reg_key):
								if comp_ver in each_val:
									package_groups = each_key.split('_')
									related_KB = '_'.join(package_groups[OCCURANCE:OCCURANCE+1])
									related_KB = related_KB.split('~')[0]
									print ("processing %d out of %d manifest corruptions." % (idx+1, len(set(flat_list))),end="")
									supportingFunctions.backline()
									f.write('%s,%s,%s,%s\n' % (comp_item, reg_key, comp_ver,related_KB))
			if os.path.isfile(reg_path):
				os.remove(reg_path)
			print('\n\nSolution: \nCorrupted components with their KB numbers are saved in corrupted_component.csv. Please restore these KBs using "Dism /Online /Cleanup-Image /RestoreHealth /Source:C:\\KBtmp\\cab\\ex /LimitAccess"')
		}
#>
}
#-------   end of Parse-Cbslog() -------



#-------   start of Analyze-File() -------
Function Analyze-File {
	param(
		[parameter(Mandatory)]
		[String[]]$FileName
	)
	Write-Output ("`n*** Analyzing " + $FileName + ' ***')

	$stream_reader = New-Object System.IO.StreamReader -ArgumentList $FileName
	$current_line = $stream_reader.ReadLine()
	if ($NULL -ne $current_line) {
		if ( ($current_line -Match 'CBS') -Or ($current_line -Match 'CSI') ) {
			Parse-Cbslog($stream_reader)
		}
		elseif ($current_line -Match 'MOUPG') {
			Parse-UpgradeLog($stream_reader)
		}
		elseif ( ($current_line -Match 'windeploy.exe') -Or ($current_line -Match 'oobe') ) {
			Parse-OobeLog($stream_reader)
		}
		elseif ($current_line -Match 'SYSPRP') {
			Parse-SysprepLog($stream_reader)
		}
		else {
			Write-Output 'File type unknown. Going to run all parsers'
			Parse-Cbslog($stream_reader)
			Parse-Upgradelog($stream_reader)
			Parse-OobeLog($stream_reader)
			Parse-SysprepLog($stream_reader)
		}
	}
	$stream_reader.Close()
	Write-Output "`n*** done ***"
}
#-------   end of Analyze-File() -------

#------- start of Expand-CabFiles() -------
Function Expand-CabFiles {
	param(
		[parameter(Mandatory)]
		[String]$FolderPath
	)

	$cabFiles = Get-ChildItem -Path $FolderPath -Name '*.cab'
	$cabFilePaths = @()
	foreach ($cabFile in $cabFiles) {
		# expand cab to LogFolder
		$outFile = Join-Path $FolderPath $cabFile.Replace('.cab', '.log')
		if (Test-Path $outFile) {
			Write-Verbose 'skip expand cab'
		}
		else {
			$NULL = expand (Join-Path $FolderPath $cabFile) $outFile
		}
		if (Test-Path $outFile) {
			$cabFilePaths += $outFile
		}
		# expand cab to Local TEMP Folder
		else {
			$outFile = Join-Path $env:TEMP $cabFile.Replace('.cab', '.log')
			$NULL = expand (Join-Path $FolderPath $cabFile) $outFile
			if (Test-Path $outFile) {
				$cabFilePaths += $outFile
			}
		}
	}

	return $cabFilePaths
}
#------- end of Expand-CabFiles() -------

#------- start of Cleanup-TempFolder() -------
function Cleanup-TempFolder {
	param(
		[parameter(Mandatory)]
		[String[]]$FileList
	)
	#	Write-Output ("Cleanup TEMP Folder.")
	foreach ($file in $FileList) {
		if ($file.Contains($env:TEMP)) {
			Write-Output ('Deleting temporary file ' + $file)
			Remove-Item $file -Force
		}
	}
}
#------- end of Cleanup-TempFolder() -------


#------- start of Unzip-Files() -------
function Unzip-Files {
	param(
		[Parameter(Mandatory)]$rootPath
	)
	EnterFunc $MyInvocation.MyCommand.Name
	Write-Verbose 'Entering Unzip-Folder function.'

	$zipFiles = Get-ChildItem -Path $rootPath -Filter *.zip

	foreach ($zipFile in $zipFiles) {
		$ExpandDestinationPath = $zipFile.FullName.Replace('.zip', '')

		if ((Test-Path $ExpandDestinationPath) -eq $false) {
			Write-Verbose ('Unzip file : ' + $zipFile.FullName)
			try {
				Expand-Archive -Path $zipFile.FullName -DestinationPath $ExpandDestinationPath -ErrorAction Stop
			}
			catch {
				Write-Error ('ERROR: Sorry, failed to unzip the file : ' + $zipFile.FullName)
				if (Test-Path $ExpandDestinationPath) {
					Remove-Item $ExpandDestinationPath -Confirm:$false -Force
				}
				continue
			}
		}
		else {
			Write-Verbose ('Skip unzip : ' + $zipFile.FullName)
		}

		if (Test-Path $ExpandDestinationPath) {
			if ((Get-ChildItem $ExpandDestinationPath).Count -eq 0) {
				continue
			}

			# if the folder name is duplicated.
			if (($tempDir = Get-ChildItem $ExpandDestinationPath -Directory).Count) {
				Move-Item -Path ($tempDir[0].FullName + '\*') -Destination $ExpandDestinationPath -Force
				Remove-Item $tempDir[0].FullName -Confirm:$false -Force
			}
		}
	}

	Write-Verbose 'Leaving Unzip-Folder function.'

	return (Get-ChildItem -Path $rootPath -Directory).FullName
	EndFunc $MyInvocation.MyCommand.Name
}
#------- end of Unzip-Files() -------

### Pre-Start / Post-Stop function for trace
<#
function DND_TEST1PreStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}

function DND_TEST1PostStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>

Function DND_WUPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	$WUServices = @('uosvc', 'wuauserv')
	$WUTraceKey = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Trace'
	foreach ($WUService in $WUServices) {
		$Service = Get-Service -Name $WUService -ErrorAction SilentlyContinue
		if ($Null -eq $Service) {
			LogDebug ('[WindowsUpdate] ' + $WUService + ' does not exist in this system.')
			continue
		}
		if ($Service.Status -eq 'Running') {
			LogInfo ('[WindowsUpdate] Stopping ' + $Service.Name + ' service to enable verbose mode.')
			Stop-Service -Name $Service.Name
			$Service.WaitForStatus('Stopped', '00:01:00')
		}
		$Service = Get-Service -Name $Service.Name
		if ($Service.Status -ne 'Stopped') {
			$ErrorMessage = ('[WindowsUpdate] Failed to stop ' + $Service.Name + ' service. Skipping Windows Update trace.')
			LogException $ErrorMessage $_ $fLogFileOnly
			throw ($ErrorMessage)
		}
		LogDebug ('[WindowsUpdate] ' + $WUService + ' was stopped.')
	}

	if (!(Test-Path -Path $WUTraceKey)) {
		try {
			New-Item -Path $WUTraceKey -ErrorAction Stop | Out-Null
		}
		catch {
			$ErrorMessage = 'An exception happened in New-ItemProperty'
			LogException $ErrorMessage $_ $fLogFileOnly
			throw ($ErrorMessage)
		}
	}

	try {
		New-ItemProperty -Path $WUTraceKey -Name 'WPPLogDisabled' -PropertyType DWord -Value 1 -Force -ErrorAction Stop | Out-Null
	}
	catch {
		$ErrorMessage = 'An exception happened in New-ItemProperty'
		LogException $ErrorMessage $_ $fLogFileOnly
		throw ($ErrorMessage)
	}
	LogDebug ('[WindowsUpdate] ' + $WUTraceKey + '\WPPLogDisabled was set to 1.')
	EndFunc $MyInvocation.MyCommand.Name
}

Function DND_WUPostStop {
	EnterFunc $MyInvocation.MyCommand.Name
	$WUTraceKey = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Trace'
	try {
		Remove-Item -Path $WUTraceKey -Recurse -Force -ErrorAction Stop | Out-Null
	}
	catch {
		$ErrorMessage = ("[WUStopTrace] Unable to delete $WUTraceKey")
		LogException $ErrorMessage $_ $fLogFileOnly
		throw ($ErrorMessage)
	}
	LogDebug ('[WindowsUpdate] ' + $WUTraceKey + ' was deleted.')

	$WUServices = @('uosvc', 'wuauserv')
	foreach ($WUService in $WUServices) {
		$Service = Get-Service -Name $WUService -ErrorAction SilentlyContinue
		if ($Null -eq $Service) {
			LogDebug ('[WindowsUpdate] ' + $WUService + ' does not exist in this system.')
			continue
		}
		if ($Service.Status -eq 'Running') {
			LogInfo ('[WindowsUpdate] Stopping ' + $Service.Name + ' service to disable verbose mode.')
			Stop-Service -Name $Service.Name
			$Service.WaitForStatus('Stopped', '00:01:00')
		}
		$Service = Get-Service -Name $Service.Name
		if ($Service.Status -ne 'Stopped') {
			$ErrorMessage = ('[WindowsUpdate] Failed to stop ' + $Service.Name + ' service. Skipping Windows Update trace.')
			LogException $ErrorMessage $_ $fLogFileOnly
			throw ($ErrorMessage)
		}
		LogDebug ('[WindowsUpdate] ' + $Service.Name + ' service was stopped.')
	}
	EndFunc $MyInvocation.MyCommand.Name
}

#################################################################################################
##### START ####### Subscription Activation Diag function
###################################################
Function CollectDND_SAReportLog {
	EnterFunc $MyInvocation.MyCommand.Name
	$SADiagFolder = "$LogFolder\SALog"
	$Prefix = Join-Path $SADiagFolder ($env:COMPUTERNAME + '_')
	$SA_DiagFile = $Prefix + 'SA-Diag.html'
	Try {
		FwCreateFolder $SADiagFolder
	}
	Catch {
		LogMessage ("Unable to create $SADiagFolder") $_
		return
	}
	### Implement your diag code ###
	$MFA_Issue = $false
	$STORE_KNOWN_Limitation_Issue = $false
	$disable_MSA_Service = $false
	$WAMCache = $false
	$html = @'
<!DOCTYPE html>
<html>

<head>
	<title>Summary</title>
	<style>
		body {
			font-family: 'Segoe UI', Arial, sans-serif;
			background-color: #f2f2f2;
			margin: 0;
			padding: 20px;
			color: #333;
		}

		.container {
			max-width: 950px;
			margin: 0 auto;
			background-color: #fff;
			padding: 20px;
			border-radius: 5px;
			box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
			text-align: center;
			/* Center the container */
		}

		h1 {
			font-size: 24px;
			color: #333;
			margin-top: 0;
		}

		h2 {
			font-size: 18px;
			color: #333;
			margin-top: 20px;
			/* Add margin-top for consistent spacing */
			margin-bottom: 10px;
		}

		p {
			font-size: 16px;
			line-height: 1.5;
			margin-bottom: 10px;
		}

		table {
			width: 100%;
			border-collapse: collapse;
			margin-bottom: 20px;
			text-align: center;
			/* Center the table */
		}

		th,
		td {
			border: 1px solid #ccc;
			padding: 10px;
		}

		th {
			background-color: #f2f2f2;
			font-weight: bold;
			color: #333;
		}

		.info {
			color: #555;
		}

		.error {
			color: #ffffff;
			background-color: #cc0000;
		}

		.warning {
			background-color: #ff0000;
			color: #ffffff;
		}

		.success {
			background-color: #52c41a;
			color: #ffffff;
		}

		.successtext {
			color: #52c41a;
		}

		.errortext {
			color: #cc0000;
		}

		a {
			color: #1890ff;
			text-decoration: none;
		}

		a:hover {
			text-decoration: underline;
		}
	</style>
</head>

<body>
	<div class="container">
		<table border="1" cellpadding="1" cellspacing="1">
			<tbody>
				<tr>
'@

	LogInfo 'Online Mode'
	Loginfo 'Checking ComputerName'

	$html += "<td style='text-align:center;'><span style='font-size:14px;'><strong>$env:COMPUTERNAME Subscription Activation Diagnostic Report (UserName : $env:USERDOMAIN\$env:USERNAME)</strong></span></td>"

	$html += @'
	</tr>
	</tbody>
	</table>
'@

	$html += '<h2>Basic Information</h2>'

	$html += @'
	<table border="1" cellpadding="1" cellspacing="1">
		<tr>
			<th>Message</th>
			<th>Comment</th>
			<th>Output</th>
		</tr>
		<tr>
'@

	$html += @"
	<td><strong>INFO</strong></td>
	<td>ComputerName</td>
	<td>$env:COMPUTERNAME</td>
	</tr>
	<tbody>
"@

	Loginfo 'Checking Current Edition'

	$currentEdition = (Get-ComputerInfo | Select-Object 'WindowsProductName').WindowsProductName

	$html += @"
	<tr>
	<td><strong>INFO</strong></td>
	<td>CurrentEdition</td>
	<td>$currentEdition</td>
</tr>
"@

	# Checking Licensing Diag Info
	Loginfo 'Checking Licensing Diag Info'

	$Lic_DiagFileName = "$Env:TEMP\$((Get-Date).ToString('MMddyyyhhmm'))_ldiag.cab"
	$Tmp_Command = "C:\windows\System32\licensingdiag.exe -log $Lic_DiagFileName | Out-Null"
	$lic_Logs_D = "$env:TEMP\Lic_Diag"
	Invoke-Expression -Command:$Tmp_Command

	if (Test-Path $lic_Logs_D) {
		Remove-Item $lic_Logs_D -Force -Recurse
	}

	New-Item -Path $env:TEMP -Name 'Lic_Diag' -ItemType Directory | Out-Null
	$Extract_C = "C:\Windows\System32\expand.exe -F:* $Lic_DiagFileName $lic_Logs_D"
	Invoke-Expression -Command:$Extract_C | Out-Null
	[XML]$Lic_XML = Get-Content "$lic_Logs_D\SPP\SppDiagReport.xml"

	$licensingStatus = $Lic_XML.DiagReport.LicensingData.LicensingStatus
	if ($licensingStatus -eq 'SL_LICENSING_STATUS_LICENSED' -or $licensingStatus -eq 'SL_LICENSING_STATUS_NOTIFICATION') {

		$statusColor = 'info'
	}
	else {
		$statusColor = 'error'
	}

	if ($statusColor -eq 'info') { $temp_licensingStatus_Status = 'INFO' }else { $temp_licensingStatus_Status = 'ERROR' }
	$html += @"
	<tr>
		<td class=$statusColor><strong>$($temp_licensingStatus_Status)</strong></td>
		<td>Current Base License Status</td>
		<td class=$statusColor>$licensingStatus</td>
	</tr>
"@

	$licensingStatusReason = $Lic_XML.DiagReport.LicensingData.LicensingStatusReason

	if ($licensingStatusReason -eq '0x4004f401') {

		$html += @"
	<tr>
		<td><strong>INFO</strong></td>
		<td>Current Partial ProductKey</td>
		<td>$licensingStatusReason</td>
	</tr>
"@

	}
	else {

		$html += @"
	<tr>
		<td><strong>INFO</strong></td>
		<td>Current Partial ProductKey</td>
		<td>$licensingStatusReason</td>
	</tr>
"@
	}
	$html += @"
	<tr>
		<td><strong>INFO</strong></td>
		<td>Current SKU Description</td>
		<td>$($Lic_XML.DiagReport.LicensingData.ActiveSkuDescription)</td>
	</tr>
"@

	$dsregCmdOutput = (dsregcmd.exe /status)
	#getUsername
	$UserName = ($dsregCmdOutput | Select-String 'Executing Account Name :').ToString().Trim()
	$html += @"
	<tr>
		<td><strong>INFO</strong></td>
		<td>UserName</td>
		<td>$($UserName.ToString().Replace('Executing Account Name :','').Trim())</td>
	</tr>
	</tbody>
	</table>
	<h2>DSREG output</h2>
"@

	# Checking DsRegCmd output
	Loginfo 'Checking DsRegCmd output'
	$AzureAdJoined = ($dsregCmdOutput | Select-String 'AzureAdJoined :').ToString().Trim()
	if ($AzureAdJoined -like '*YES*') {
		$html += @"
	<table border="1" cellpadding="1" cellspacing="1">
		<tbody>
			<tr>
				<th>Message</th>
				<th>Comment</th>
				<th>Output</th>
			</tr>

			<tr>
				<td><strong>INFO</strong></td>
				<td>AzureAdJoined</td>
				<td>$AzureAdJoined</td>
			</tr>
"@
	}
	else {
		$html += @"
	<table border="1" cellpadding="1" cellspacing="1">
		<tbody>
			<tr>
				<td class="error"><strong>ERROR</strong></td>
				<td>AzureAdJoined</td>
				<td>$AzureAdJoined</td>
			</tr>
"@
	}


	$DomainJoined = ($dsregCmdOutput | Select-String 'DomainJoined :').ToString().Trim()
	if ($DomainJoined -like '*YES*') {
		$html += @"
	<tbody>
		<tr>
			<td><strong>INFO</strong></td>
			<td>DomainJoined</td>
			<td>$DomainJoined</td>
		</tr>
"@
	}

	$AzureAdPrt = ($dsregCmdOutput | Select-String 'AzureAdPrt :').ToString().Trim()
	if ($AzureAdPrt -like '*YES*') {
		$html += @"
                <tbody>
                	<tr>
                		<td><strong>INFO</strong></td>
                		<td>AzureAdPrt</td>
                		<td>$AzureAdPrt</td>
                	</tr>
"@

	}
	else {
		$html += @"
          <tbody>
          	<tr>
          		<td class="error><strong>ERROR</strong></td>
             <td>AzureAdPrt</td>
             <td>$AzureAdPrt</td>
 </tr>
"@
	}

	$WamDefaultSet = ($dsregCmdOutput | Select-String 'WamDefaultSet :').ToString().Trim()

	if ($WamDefaultSet -like '*YES*') {
		$html += @"
                <tbody>
                	<tr>
                		<td><strong>INFO</strong></td>
                		<td>WamDefaultSet</td>
                		<td>$WamDefaultSet</td>
                	</tr>
"@
	}
	else {
		$html += @"
                <tbody>
      	<tr>
      		<td class="error"><strong>ERROR</strong></td>
      		<td>WamDefaultSet</td>
      		<td>$WamDefaultSet</td>
      	</tr>
"@
	}

	$DeviceAuthStatus = ($dsregCmdOutput | Select-String 'DeviceAuthStatus' | Out-String).TrimStart().Trim('DeviceAuthStatus').TrimStart(' :')

	if ($DeviceAuthStatus -like '*SUCCESS*') {
		$html += @"
                <tbody>
            	<tr>
            		<td><strong>INFO</strong></td>
            		<td>DeviceAuthStatus</td>
            		<td>$DeviceAuthStatus</td>
            	</tr>
"@
	}
	else {
		$html += @"
             <tbody>
   	<tr>
   		<td class="error"><strong>ERROR</strong></td>
   		<td>DeviceAuthStatus</td>
   		<td>$DeviceAuthStatus</td>
   	</tr>
"@
	}

	if (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate') {

		$DoNotConnectToWindowsUpdateInternetLocations = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DoNotConnectToWindowsUpdateInternetLocations' -ErrorAction SilentlyContinue
		if ($DoNotConnectToWindowsUpdateInternetLocations -eq '1') {
			$Known_issues_WindowsUpdate = $true
		}
		else {
			$Known_issues_WindowsUpdate = $false
		}
	}
	$html += @'
</tbody>
</table>
<h2>Services Status</h2>
<table border="1" cellpadding="1" cellspacing="1">
	<thead>
		<thead>
			<tr>
				<th>Name</th>
				<th>StartMode</th>
				<th>State</th>
				<th>Status</th>
			</tr>
		</thead>
'@
	Loginfo 'Checking Service'
	$Service_MASA = Get-WmiObject -Class Win32_Service | Where-Object { $_.name -eq 'wlidsvc' }
	if ($Service_MASA.StartMode -eq 'Disabled') {
		$statusColor = 'error'
		$disable_MSA_Service = $true
	}
	else {
		$statusColor = 'info'
		$disable_MSA_Service = $false
	}
	$html += @"
<tbody>
	<tr>
		<td>$($Service_MASA.name)</td>
		<td class=$statusColor>$($Service_MASA.StartMode)</td>
		<td>$($Service_MASA.State)</td>
		<td>$($Service_MASA.Status)</td>
	</tr>
</tbody>
</table>
"@
	$AdminYes = $false
	Loginfo 'ClipRenew'
	$ClipRenew_Command = 'C:\windows\system32\ClipRenew.exe'
	Invoke-Expression -Command:$ClipRenew_Command
	Loginfo 'Sleeping..: 30 Seconds'
	Start-Sleep 30

	Loginfo 'Reviewing :  Store and AAD Logs'
	$html += @'
<h2>Store logs and AAD logs summary</h2>
<table border="1" cellpadding="1" cellspacing="1">
	<tbody>
'@
	$CurrentActivityID = $GetStoreEvent.ActivityID
	$CurrentActivityID = $null
	$AuthFailure = $null
	$StoreLogs_FirstEvent = Get-WinEvent 'Microsoft-Windows-Store/Operational' | Where-Object { $_.message -like '*Invalidating cache for 8d419748-b6f9-41a8-e3d0-ebd7a8880244*' } | Select-Object -First 1
	$CurrentActivityID = $StoreLogs_FirstEvent.ActivityId

	if ($CurrentActivityID) {
		$CurrentActivityID_Events = Get-WinEvent 'Microsoft-Windows-Store/Operational' | Where-Object { $_.ActivityId -like $CurrentActivityID }
	}

	[array]$SearchStrings = @(
		'Getting user tickets for',
		'No authenticated user, no ticket',
		'Captured * MSA tickets and * AAD tickets for',
		'Requesting license for 8d419748-b6f9-41a8-e3d0-ebd7a8880244',
		'Service Fault: status:',
		'License Response: * leases, * keys for contentId 8d419748-b6f9-41a8-e3d0-ebd7a888024',
		'Satisfaction error from service: *: *'
	)

	$gettingTicketEventTime = $null

	foreach ($SearchString in $SearchStrings) {
		$StoreLogs_Content = $null
		if ($CurrentActivityID_Events) {
			$StoreLogs_Content = $CurrentActivityID_Events | Where-Object { $_.Message -like "*$SearchString*" } | Select-Object -First 1
		}
		else {
			$StoreLogs_Content = Get-WinEvent 'Microsoft-Windows-Store/Operational' | Where-Object { $_.Message -like "*$SearchString*" -and $_.timecreated -gt $($StoreLogs_FirstEvent.timecreated) } | Select-Object -First 1
		}

		if ($StoreLogs_Content) {
			if ($searchstring -like 'Getting user tickets for') {
				$gettingTicketEventTime = $StoreLogs_Content[0].TimeCreated
				$html += @"
            <tr>
            	<th>Message</th>
            	<th>Comment</th>
            	<th>Event Message</th>
            </tr>
            <tr>
            	<td><strong>INFO</strong></td>
            	<td>Obtaining tickets for the user</td>
            	<td> $($StoreLogs_Content.Message)</td>
            </tr>
"@
			}
			if ($SearchString -like 'No authenticated user, no ticket') {
				$html += @"
            <tr>
                    <td class="error"><strong>ERROR</strong></td>
                    <td>Failure in getting Ticket for the User</td>
                    <td class"errortext"> $($StoreLogs_Content.Message)</td>
                </tr>
   </tbody>
</table>
"@
			}
			if ($StoreLogs_Content.Message -like '*No authenticated user, no ticket*') {
				$AuthFailure = $true
				Loginfo 'Reviewing: Checking Azure AD logs due to authentication failure in Store logs.'

				if (!$AdminYes) {
					$AADEventlogs = Get-WinEvent -LogName 'Microsoft-Windows-AAD/Operational' | Where-Object {
						$_.TimeCreated -ge $gettingTicketEventTime.AddMinutes(-2) -and
						($_.message -like '*onestore*' -and $_.levelDisplayName -eq 'Error')
					}
				}

				if ($AADEventlogs) {
					Loginfo 'Reviewing: We encountered a problem while trying to sign in to the Microsoft Store service. This indicates a failure in the Store.'
					$html += @"
			<h2>AAD Logs Summary</h2>
			<p>Since there is an authentication failure, we encountered a problem while trying to sign in to the Microsoft Store service. This indicates a failure in the Store.</p>
			<table border="1" cellpadding="1" cellspacing="1">
				<tbody>
					<tr>
						<th><strong>TimeCreated</strong></th>
						<th><strong>Failure Message</strong></th>
					</tr>
			"@
					foreach ($event in $AADEventlogs) {
						$timeCreated = $event.TimeCreated
						$message = $event.Message
						$html += @"
					<tr>
						<td>$timeCreated</td>
						<td class="errortext">$message</td>
					</tr>
			"@
					}
					$html +=
@"
				</tbody>
			</table>
"@
				}
				else {
					if (!$AdminYes) {
						$AADEventlogs = Get-WinEvent -LogName 'Microsoft-Windows-AAD/Operational' | Where-Object {
							$_.timecreated -ge $gettingTicketEventTime -and $_.message -like '*onestore'
						}
					}
					if ($AADEventlogs) {
						$html += @'
			<h2>AAD Logs Summary</h2>
			<p>We couldn't find error event related to authentication failure, searching for OneStore.Microsoft.com.</p>
			<table border="1" cellpadding="1" cellspacing="1">
				<tbody>
					<tr>
						<th><strong>TimeCreated</strong></th>
						<th><strong>Failure Message</strong></th>
					</tr>
'@
						foreach ($event in $AADEventlogs) {
							$timeCreated = $event.TimeCreated
							$message = $event.Message
							$html += @"
					<tr>
						<td>$timeCreated</td>
						<td class="errortext">$message</td>
					</tr>
"@
						}
						$html += @'
				</tbody>
			</table>
'@
					}
					else {
						if (!$AdminYes) {
							$AADEventlogs = Get-WinEvent -LogName 'Microsoft-Windows-AAD/Operational' | Where-Object {
								$_.timecreated -ge $gettingTicketEventTime -and $_.message -like '*0x4AA50081 An application specific account is loading in cloud joined session'
							}
						}
						if ($AADEventlogs) {
							$html +=
							@'
			<h2>AAD Logs Summary</h2>
			<p>We found WAM corruption-related events. It's possible the machine may be impacted by WAM cache corruption. To verify if the machine has WAM corruption, go to Shared Experience and click on the 'Fix now' prompt. If you see the prompt is stuck or closing out automatically, it means the machine is impacted by WAM cache corruption.</p>
			<table border="1" cellpadding="1" cellspacing="1">
				<tbody>
					<tr>
						<th><strong>TimeCreated</strong></th>
						<th><strong>Failure Message</strong></th>
					</tr>
'@
							foreach ($event in $AADEventlogs) {
								$timeCreated = $event.TimeCreated
								$message = $event.Message
								$html +=
								@"
					<tr>
						<td>$timeCreated</td>
						<td class="errortext">$message</td>
					</tr>
"@
							}
							$html +=
							@'
				</tbody>
			</table>
'@
						}
					}
				}

				if ($AADEventlogs | Where-Object { $_.message -like '*Error: 0xCAA2000C The request requires user interaction.*' }) {
					$MFA_Issue = $true
				}
				if ($AADEventlogs | Where-Object { $_.message -like '*0x4AA50081 An application specific account is loading in cloud joined session' }) {
					$WAMCache = $true
				}
			}

			if ($SearchString -like 'Captured * MSA tickets and * AAD tickets for') {
				$html +=
				@"
            <tr>
            	<td class="success"><strong>SUCCESS</strong></td>
            	<td>Captured Ticket for the user</td>
            	<td class="successtext">$($StoreLogs_Content.Message)</td>
            </tr>
"@
			}
			if ($SearchString -like 'Requesting license for 8d419748-b6f9-41a8-e3d0-ebd7a8880244') {
				if ($AuthFailure -eq $true) {
					$html +=
					@"
			<table border="1" cellpadding="1" cellspacing="1" style="width:100%">
				<tbody>
					<tr>
						<th>Message</th>
						<th>Comment</th>
						<th>Event Message</th>
					</tr>
					<tr>
						<td><strong>INFO</strong></td>
						<td>Requesting license for 8d419748-b6f9-41a8-e3d0-ebd7a8880244</td>
						<td> $($StoreLogs_Content.Message)</td>
					</tr>
"@

				}
				else {
					$html +=
					@"
            <tr>
           	<td><strong>INFO</strong></td>
           	<td>Requesting license for 8d419748-b6f9-41a8-e3d0-ebd7a8880244</td>
           	<td> $($StoreLogs_Content.Message)</td>
           </tr>
"@
				}

			}
			if ($SearchString -like 'Service Fault: status:') {
				$html =
				@"
            <tr>
                    <td class="error"><strong>ERROR</strong></td>
                    <td>Service Fault: status</td>
                    <td class="errortext">$($StoreLogs_Content.Message)</td>
                </tr>
"@
				if ($StoreLogs_Content[0].message -like '*SingleTenantIdExpectedForAadUsers*') {
					$STORE_KNOWN_Limitation_Issue = $true
				}
			}
			if ($searchstring -like 'License Response: * leases, * keys for contentId 8d419748-b6f9-41a8-e3d0-ebd7a888024') {
				if ($StoreLogs_Content.Message -like '*License Response: 0 leases, 0*') {
					$html +=
					@"
            <tr>
                    <td class="error"><strong>ERROR</strong></td>
                    <td>License Response:</td>
                    <td class="errortext">$($StoreLogs_Content.Message)</td>
                </tr>
"@
				}
				if ($StoreLogs_Content.Message -like '*License Response: 1 leases, 1*') {
					$html +=
					@"
            <tr>
                    <td class="success"><strong>SUCCESS</strong></td>
                    <td>License Response:</td>
                    <td class="successtext">$($StoreLogs_Content.Message)</td>
                </tr>
"@
				}
			}
			if ($SearchString -like 'Satisfaction error from service: *: *') {
				if ($($StoreLogs_Content.message) -like '*Satisfaction error from service: 4096*') {
					$userLicenseMising = $true
				}
				else {
					$userLicenseMising = $false

				}
				$html +=
				@"
            <tr>
                    <td class="error"><strong>ERROR</strong></td>
                    <td>Satisfaction error:</td>
                    <td class="errortext">$($StoreLogs_Content.Message)</td>
                </tr>
                </tbody>
                </table>
"@
			}

		}
	}

	Loginfo 'Reviewing :  Done Reviewing Store and AAD Logs'

	$html += '<h2>Summary</h2>'

	if ($disable_MSA_Service -eq $true) {

		$html += '<p>We found that <Strong>Microsoft Account Sign-in Assistant</strong> is disable, Please enable the service to use Subscription Activation</p>'

	}

	if ($Known_issues_WindowsUpdate -eq $true) {

		$html += '<p>We found that <Strong>Do not connect to any Windows Update Internet locations</strong> is Enabled, Please remove the policy to use Subscription Activation</p>'

	}

	if ($userLicenseMising -eq $true) {
		$html += '<p>We found that <Strong>User does not have license assigned</strong> Please assign the license and try again.</p>'

	}
	if ($MFA_Issue -eq $true) {
		$html += "<p>We discovered a known MFA issue affecting the subscription activation process. To remediate this issue, you must exclude 'Universal Store Service APIs and Web Application' from the Conditional Access policy. For more information, visit: <a href='https://learn.microsoft.com/en-us/windows/deployment/windows-10-subscription-activation'>Link</a></p>"
	}

	if ($WAMCache -eq $true) {
		$html += "<p>We have identified a potential issue with this device, which may involve WAM cache corruption. To confirm, please log in with the affected user account and search for the shared Experience. If you encounter a 'Fix Now' prompt that either closes automatically, becomes unresponsive, or continuously spins, it is likely an indication of WAM cache corruption on the device.</p>"
	}

	if ($STORE_KNOWN_Limitation_Issue -eq $true) {
		$html += '<p>We found that subscription activation failed due to a known limitation of the subscription</p>'
		$html += '<p>The current subscription activation does not support having two AADs added from two different tenants, causing the activation to fail.</p>'

		$html += '<p class=font-bold>[To Fix]:</p>'
		$html += '<p>Remove the additional Work &amp; School Account: Go to Setting --&gt; Accounts --&gt; Work &amp; School Account</p>'
	}

	# Save the HTML log to a file
	$html | Out-File -FilePath $SA_DiagFile -Encoding UTF8

	# Display the log file path
	Loginfo 'Diagnostic report Exported'

	Loginfo 'Collecting Get-DNDActivationState'

	Get-DNDActivationState $Prefix

	Loginfo 'Collecting collecting AAD logs'

	wevtutil.exe export-log 'Microsoft-Windows-AAD/Operational' "$($Prefix + 'Aad_Operational.evtx')"


}

#################################################################################################
##### END ####### Subscription Activation Diag function
#################################################################################################


Function ShowMenu {
	# .SYNOPSIS this function will present a popup menu with selectable DND items
	$MenuItems = [ordered]@{	#$True = selected
		'ACTIVATION'  = 1
		'APPCOMPAT'   = 0
		'APPLOCKER'   = 1
		'BITLOCKER'   = 1
		'CBSPNP'      = 1
		'DATASTORE'   = 0
		'DEFENDER'    = 1
		'DeviceGUARD' = 1
		'DIR'         = 1
		'DO'          = 1
		'DXDIAG'      = 0
		'EVTX'        = 1
		'FILEVERSION' = 1
		'FlushLogs'   = 0
		'GETWINSXS'   = 0
		'Max'         = 0
		'MDM'         = 1
		'Min'         = 0
		'MISC'        = 1
		'NETBASIC'    = 1
		'NETDETAIL'   = 0
		'PERF'        = 1
		'PERMPOL'     = 1
		'POWERCFG'    = 0
		'PROCESS'     = 1
		'RFLCHECK'    = 1
		'SLOW'        = 1
		'STORAGE'     = 1
		'Summary'     = 1
		'SURFACE'     = 0
		'TWS'         = 1
		'UPGRADE'     = 1
		'WINRE'       = 0
		'WU'          = 1
	}

	$OKbuttonyPos = $($MenuItems.count * 20)
	$DisAllButtonyPos = $($MenuItems.count * 20 - 40)
	$EnaAllButtonyPos = $($MenuItems.count * 20 - 80)
	$DNDFormHight = $($MenuItems.count * 20 + 80)
	#Write-Host "yPos: $OKbuttonyPos FormHight: $DNDFormHight"

	# Load the assembly
	#[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
	# Import the System.Windows.Forms assembly
	Add-Type -AssemblyName System.Windows.Forms

	# Create a DNDSetupRepForm
	$DNDSetupRepForm = New-Object System.Windows.Forms.Form
	$DNDSetupRepForm.Text = 'Select your DND options to collect:'
	$DNDSetupRepForm.Width = 400
	$DNDSetupRepForm.Height = $DNDFormHight
	$DNDSetupRepForm.StartPosition = 'CenterScreen'

	#Define checkboxes ArrayList
	$checkboxes = New-Object System.Collections.ArrayList

	# Create check-boxes
	for ($i = 0; $i -lt $($MenuItems.count); $i++) {
		$checkbox = New-Object System.Windows.Forms.CheckBox
		$checkbox.Text = $($MenuItems.Keys)[$i]
		$checkbox.Name = $($MenuItems.Keys)[$i]
		$checkbox.Location = New-Object System.Drawing.Point(10, (10 + ($i * 20)))
		#$checkBox.Size = New-Object System.Drawing.Size(260, 30)
		if ($($MenuItems.Values)[$i]) { $checkbox.Checked = $True } # $true if you want some items to be checked by default
		$DNDSetupRepForm.Controls.Add($checkbox)
		$checkboxes.add( $checkbox ) | Out-Null
	}
	# Create a OK button
	$OKbutton = New-Object System.Windows.Forms.Button
	$OKbutton.Text = 'OK'
	$OKbutton.Location = New-Object System.Drawing.Point(150, $OKbuttonyPos)
	$OKbutton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$DNDSetupRepForm.AcceptButton = $OKbutton
	$DNDSetupRepForm.Controls.Add($OKbutton)

	# Buttons
	# Create a new button object
	$DisButton = New-Object System.Windows.Forms.Button
	$EnaButton = New-Object System.Windows.Forms.Button

	# Set the button properties
	$DisButton.Text = 'Disable all'
	$EnaButton.Text = 'Enable all'
	$DisButton.Location = New-Object System.Drawing.Point(150, $DisAllButtonyPos)
	$EnaButton.Location = New-Object System.Drawing.Point(150, $EnaAllButtonyPos)
	$DisButton.Size = New-Object System.Drawing.Size(150, 30)
	$EnaButton.Size = New-Object System.Drawing.Size(150, 30)

	# Create a function to enable or disable all checkboxes
	function EnableDisableCheckboxes($state) {
		# Loop through the checkboxes array
		foreach ($checkbox in $checkboxes) {
			# Set all checkbox state
			$checkbox.Checked = $state
		}
	}

	# Add click events to the buttons
	$DisButton.Add_Click({ EnableDisableCheckboxes($false) })
	$EnaButton.Add_Click({ EnableDisableCheckboxes($true) })

	# Add the two buttons to the form window
	$DNDSetupRepForm.Controls.Add($DisButton)
	$DNDSetupRepForm.Controls.Add($EnaButton)

	$result = $DNDSetupRepForm.ShowDialog()

	# If the result is OK, loop through the check-boxes and store the checked ones in a variable or an array
	if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		$script:checkedItems = @() # Create an empty array
		$script:UnCheckedItems = @()
		foreach ($control in $DNDSetupRepForm.Controls) {
			# Loop through the controls in the form
			if ($control -is [System.Windows.Forms.CheckBox]) {
				# If the control is a check-box
				if ($control.Checked) {
					# If the check-box is checked
					$script:checkedItems += $control.Name # Add its name to the array
				}
				else {
					$script:UnCheckedItems += $control.Name
				}
			}
		}
		Write-Host "You have $($script:checkedItems.count) DND items selected: $($script:checkedItems -join ', ')" # Display the selected items
		Write-Host " Total selected items: $($script:checkedItems.count)"
		ForEach ($Item in $script:checkedItems) {
			#ForEach ($Item in $MenuItems){
			Set-Variable -Name "DND_SETUPReport_$Item" -Scope Global -Force -Value 1 -ErrorAction Ignore #we# using Set-Variable (instead of New-Variable), as they can already exist in tss_config.cfg
			New-Variable -Name "$Item" -Scope Script -Force -Value 1 -ErrorAction Ignore
			$x = Get-Variable -Name DND_SETUPReport_$Item -ValueOnly
			$y = Get-Variable -Name $Item -ValueOnly
			#			Write-Host "  [x]   DND_SETUPReport_$Item = $x	-- $Item = $y"
		}
		Write-Host " Total unselected items: $($script:UnCheckedItems.count)"
		ForEach ($Item in $script:UnCheckedItems) {
			Set-Variable -Name "DND_SETUPReport_$Item" -Scope Global -Force -Value 0 -ErrorAction Ignore
			New-Variable -Name "$Item" -Scope Script -Force -Value 0 -ErrorAction Ignore
			$x = Get-Variable -Name DND_SETUPReport_$Item -ValueOnly
			$y = Get-Variable -Name $Item -ValueOnly
			#			Write-Host "  [ ]   DND_SETUPReport_$Item = $x	-- $Item = $y"
		}
	}
}

<# ### Pre-Start / Post-Stop function for scenario trace
function DND_MyScenarioTestScenarioPreStart
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}

function DND_MyScenarioTestScenarioPostStop
{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "$($MyInvocation.MyCommand.Name) is called."
	EndFunc $MyInvocation.MyCommand.Name
}
#>
#endregion Functions

#region Registry Key modules for FwAddRegItem
<# Example:
	$global:KeysHyperV = @("HKLM:Software\Microsoft\Windows NT\CurrentVersion\Virtualization", "HKLM:System\CurrentControlSet\Services\vmsmp\Parameters")
	#>
#endregion Registry Key modules

#region groups of Eventlogs for FwAddEvtLog
<# Example:
	$global:EvtLogsEFS		= @("Microsoft-Windows-NTFS/Operational", "Microsoft-Windows-NTFS/WHC")
	#>
#endregion groups of Eventlogs

# Deprecated parameter list. Property array of deprecated/obsoleted params.
#   DeprecatedParam: Parameters to be renamed or obsoleted in the future
#   Type           : Can take either 'Rename' or 'Obsolete'
#   NewParam       : Provide new parameter name for replacement only when Type=Rename. In case of Type='Obsolete', put null for the value.
$DND_DeprecatedParamList = @(
	#@{DeprecatedParam='DND_SetupEx';Type='Rename';NewParam='DND_Setup'}
	#@{DeprecatedParam='DND_Setup';Type='Rename';NewParam='DND_SetupReport'}
)
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *
# SIG # Begin signature block
# MIIoKQYJKoZIhvcNAQcCoIIoGjCCKBYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDKO05BsfGsuyw/
# Iy2BVFEPPuPGOzNASfN/DL0aMcxTw6CCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgkwghoFAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINadXemMUu+lXBZjtT1ELpSn
# 01Q51y7ONkI4JAcW55e6MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAQov04tRhy+FA17BZiFtPXLq2sHMFDKbm4qpcFDQeu1qatQRtVYwbGN5y
# qUsWzC3lEadKYDg2QtHWM7jOIwXURrm40ivByA/l7tJ3TrOLQZ4bote4P+Oc9PRP
# FVGy7P3A3GWunrwIRhDvhShp+zUSNIaWfTy8oPyD3BF91D4cJKvbUxICVsXJZada
# DozkJUDy3s3po2Hn2UHci1k5j21tSPAKkU7RYYBZ7n4w537YzNYPmaNR/+UVC86Y
# NGGMdZt0hgqWDM1vvpa18tQm9wsUiYJYqZWBh2Y9IR/+NP4z1TJen2Bi2wrRwBrQ
# lSyt+VAChShCpTE+M6uoP01/qS4Af6GCF5MwghePBgorBgEEAYI3AwMBMYIXfzCC
# F3sGCSqGSIb3DQEHAqCCF2wwghdoAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFRBgsq
# hkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAGGhrvDRNtId4s/geWmnB947LAs9OSbMDlx0qoaBzP2QIGZkZGMtrZ
# GBIyMDI0MDYxMjE0NTg0OS4wMlowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpGMDAyLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCC
# EeowggcgMIIFCKADAgECAhMzAAAB8j4y12SscJGUAAEAAAHyMA0GCSqGSIb3DQEB
# CwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4NDU1
# OFoXDTI1MDMwNTE4NDU1OFowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMx
# JzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpGMDAyLTA1RTAtRDk0NzElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBALzl88sXCmliDHBjGRIR5i9AG2dglO0oqPYUrHMfHR+B
# XpeAgiuYJaakqX0g7O858n+TqI/RGehGjkXz0B3b153MZ2VZsKPVDLHkdQc1jzK7
# 0SUk6Z2B6429MrhFbjC72IHn/PZJ4K5irJf+/zPo+m/b2HW201axJz8o8566HNIB
# eqQDbrkFIVPmTKTG/MHQvGjFLqhahdYrrDHXvY1ElFhwg19cOFRG9R8PvSOKgT3a
# tb86CNw4rFmR9DEuXBoVKtKcazteEyun1OxSCbCzJxMQ4F0ZWZ/UcIPtY5rPkQRx
# DIhLYGlFhjCw8xsHre4eInXnyo2HVIle6gvnAYO79tlTM34HNwuP3qLELvAkZAwG
# LFYf1375XxuXXRFh1cNmWWNEC9LqIXA3OtqG7gOthvtvwzu+/CEQvTEI69vtYUyy
# y2xxd+R0TmD41JpymGAV9yh+1Dmo8PY81WasbfwOYcOhiGCP26o8s/u+ehd/uPr4
# tbxWifXnwPRauaTsK6a5xBOIdHJ6kRpUOecDYaSImh6H+vd9KEvoIeA+hMHuhhT9
# 3ok6dxGKgNiqpF9XbCWkpU7xv5VgcvyGfXUlEXHqnr2YvwFG1Jnp0b8YURUT59Wa
# DFh8gJSumCHJCURMk8hMQFLXkixpS5bQa9eUtKh8Z/a3kMCgOS4oJsL7dV0+aVhV
# AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUlVuHACbq0DEEzlwfwGDT5jrihnkwHwYD
# VR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZO
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# VGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
# BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0
# cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYD
# VR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
# B4AwDQYJKoZIhvcNAQELBQADggIBAD1Lp47gex8HTRek6A9ptw3dBl7KKmCKVxBI
# NnyDpUK/0VUfN1Kr1ekCyWNlIo1ZIKWEkTPk6jdSb+1o+ehsX7wKQB2RwtCEt2RK
# F+v3WTPL28M+s6aUIDYVD2NWEVpq3ZAzffPWn4YI/m26+KsVpRbNRZUMU6mj87nM
# OnOg9i1OvRwWDe5dpEtPnhRDdji49heqfrC6dm1RBEyIkzPGlSW919YZS0K+dbd4
# MGKQOSLHVcT3xVxgjPb7l91y+sdV5RqsZfLgtG3DObCmwK1SHu1HrCEKtViRvoW5
# 0F1YztNW+OLukaB+N6yCcBJoP8KEu7Hro8bBohoX7EvOTRs3GwCPS6F3pB1avpNP
# f2b9I1nX9RdTuTMSh3S8BjeYifxfkDgj7397WcE2lREnpiIMpB3lhWDGy5kJa/hD
# BvSZeEch70K5t9KpmO8NrB/Yjbb03cuy0MlRKvW8YUHyJDlbxkszk/BPy+2woQHA
# cRibCy5aazGSKYgXkFBtLOD3DPU7qN1ZPEYbQ5S3VxdY4wlQnPIQfhZIpkc7Hnep
# wC8P2HRTqMQXZ+4GO0n9AOtZtvi6u8B+u+o2f2UfuBU+mWo08Mi9DwORneW9tCxi
# qXPrXt7vqBrtJjTDvX5A/XrkI93NRjfp63ZKbim+ykQryGWWrchhzJfS/z3v5f1h
# 55wzU9vWMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG
# 9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIw
# MTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az
# /1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V2
# 9YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oa
# ezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkN
# yjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7K
# MtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRf
# NN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SU
# HDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoY
# WmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5
# C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8
# FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TAS
# BgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1
# Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUw
# UzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIB
# hjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fO
# mhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9w
# a2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggr
# BgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3
# DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEz
# tTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJW
# AAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G
# 82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/Aye
# ixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI9
# 5ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1j
# dEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZ
# KCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xB
# Zj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuP
# Ntq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvp
# e784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCA00w
# ggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046RjAwMi0wNUUwLUQ5NDcxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAGuL
# 3jdwUsfZN9AR8HTlIsgKDvgIoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDqE7J/MCIYDzIwMjQwNjEyMDUzNzAz
# WhgPMjAyNDA2MTMwNTM3MDNaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOoTsn8C
# AQAwBwIBAAICDxkwBwIBAAICE0EwCgIFAOoVA/8CAQAwNgYKKwYBBAGEWQoEAjEo
# MCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkqhkiG
# 9w0BAQsFAAOCAQEAjgobLKQg42C51x/8tEayBbTAqlLZ0kb+3rHyEl3TWe35Iv+v
# iIOMs28nKj/d1AX1UyVzCOdauNKGTN+S/+SHed6r5CNxy8i5cWO56yxW+3VWfoAw
# EeqqcAfprycWSKUqrzzkcD1ClYLHb7sALGNizLf4GktzlZKBwJ32HNRBIhsX8+kX
# a87M/kKMJDAYy3NjAyDWCs4IWHQ6I+bjCDz4pCmqz7QBBlkNIdTKXTK3j9MRd5LO
# cKcESO9vCqOWiJ5niTaZHCyGj51upbC+pG8856Kpu1upv9PjXoMFkLucHqz8zjyk
# ezxE5OImKVmJg+IL5r6wGkXkTGfH6NzG9IYaqzGCBA0wggQJAgEBMIGTMHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB8j4y12SscJGUAAEAAAHyMA0G
# CWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJ
# KoZIhvcNAQkEMSIEIKpEvrpiVegdnG+zOL9xex1+cJo+I7E+2ci/kSnsl9IWMIH6
# BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg+No+HS4xUlzTj5jhG7kFRRscTiy5
# nqdEdJS7RddKQ0QwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MAITMwAAAfI+MtdkrHCRlAABAAAB8jAiBCCDLZJIsSxEpVWPWe06aK7qcywEsyth
# lO/xRGqSvfWMyzANBgkqhkiG9w0BAQsFAASCAgBbpqYFHFn6jg4/doOxfkCVUp+b
# DqjhN8cKrpiTd9shQ2n7PlQA4ru0gjsss+ytphFXx7tdb2JvLMZD1TB3TybHYt6Q
# TyLchizjz0eg2kDyqzVfrmcAxqveo5nW2eFe7OEuk0gr1Dorc8tX2HgFPNFRoGwB
# xjD8boz8eBaTGQDMnzphIFqnebNiZwJJhvD1EUarHQbpjhxdbCl0iPJyRao1C1K5
# rWLAR7t8mEBML8kWRd2uRE4g5IUpQ7VWlJU6V1PoN24qSfOrXZXCCgEljiARPG2Z
# 6tLu+vMmN1fpkGDdJ+Mze0zDl6hlXxMjWqG8OGh9Ce0KuSyaFiuPsNRLUsYsU80/
# 84+7hlgJo5CyHbPXOZn2opl8I2N6mMPQKOLQ+Mp+sQOznAr94xkBKvEHtP1sVdoD
# U2WIhsq5jZZLR0/U+Si+w41AqnX99sVrnqnxsLDs59VoG/byC55CshRNLVecDCGq
# yL2cjhOERFs8VR9v1hTHvJ9x8KjWHd0XA89Rdx9pelwG8m9lZFBdV32ghCk41H8z
# qRCgajBOs+5wtjIuJVhKJwQ3OTGBRS4gQFVlvX0Wh0k7dRc2b/de/O6F4Rvz3HvB
# j5/4NaAtJHNki6xIerfTWchbierWxrd7t4/v1wrNULc19oM7mikQo/7KTKndxI1i
# 4EAnit82l3d0OG6j2w==
# SIG # End signature block
