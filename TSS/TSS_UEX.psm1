<# File: TSS_UEX.psm1
.SYNOPSIS
   UEX module for collecting ETW traces and various custom tracing functionality

.DESCRIPTION
   Define ETW traces for Windows UEX components
   Add any custom tracing functionality for tracing UEX components

.NOTES
   Dev. Lead  : Robert Klemencz
   Authors	  : Ryutaro Hayashi (ryhayash@microsoft.com); milanmil; Yasuhiro Takahashi; Garabier; cnaudy; Robert Klemencz, Marius Porcolean
   Requires   : PowerShell V4 (Supported from Windows 8.1/Windows Server 2012 R2)
   Version	  : see $global:TssVerDateUEX

.LINK
	TSS : https://internal.evergreen.microsoft.com/en-us/help/4619187
	UEX : https://internal.evergreen.microsoft.com/en-us/help/5013201
#>

<# latest changes
::  2024.06.05.0 [gb] _UEX: Evt-Collect lists all ETW sessions
::  2024.06.04.0 [mp] _UEX: Print: Feature #738 - Create scenarios for Printing
::  2024.06.03.0 [gb] _UEX: WMI: Added support for WMI arbitrator dump in Windows Server 2025
::  2024.05.31.1 [gr] _UEX: #671 Remove C:\programdata\App-V  from AppV Collect
::  2024.05.31.0 [gr] _UEX: Removed UEX_WinRM Collect and add collectlog to UEX_TSched Scenario
::  2024.05.29.0 [gr] _UEX: Removed urgently UEX_WinRM and UEX_WMI as deprecated feature has a bug
::  2024.05.28.1 [gr] _UEX: FEATURE #772 : Merge UEX_Evt and UEX_EventLog
::  2024.05.28.0 [gb] _UEX: Added tasklist in PreStart/PostStop for WMIBase, WMIAdvanced, WinRMBase, WinRMAdvanced, TSched
::  2024.05.27.0 [gr] _UEX: Re-enable UEX_WMI Scenario with WMI Advanced
::  2024.05.24.0 [gr] _UEX: M&S: Feature #739 review M&S Scenarios + Feature 764 : comment old UEX functions which have moved to PRF
::  2024.05.21.0 [gb] _UEX: WMI/WinRM: Added ARB and ESS export for WMI in Windows Server 2025, removed Run_UEX_WinRMDiag function
::  2024:06.20.0 [mp] _UEX: COM: Feature #743 - Add / integrate new external script COM-Collect
::  2024.05.17.1 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 240517.4 (See \Scripts\MSRD-Collect\MSRD-Collect-ReleaseNotes.txt for details)
::  2024:05.17.0 [gb] _UEX: Adjusted UEX_TSched etl providers
::  2024:05.14.3 [mp] _UEX: Print: Feature #737 - Improve Printing data collection
::  2024.05.14.2 [gb] _UEX: Added WinRM tracing, minor changes in the external scripts
::  2024.05.13.0 [gb] _UEX: WMI : added WMI_Report
::  2024:05:10.0 [mp] _UEX: MGMT: Feature #730 Update UEX-MGMT external scripts to latest versions
::  2024.04.02.0 [gr] _UEX: Applocker : merged AppId to Applocker, + add eventlogs for Applocker
::  2024.03.28.0 [rk] _UEX: #695 Added 'PowerShellCore/Operational' event log collection to UEX_PowerShell
::  2024.03.21.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 240321.7 - See \Scripts\MSRD-Collect\MSRD-Collect-ReleaseNotes.txt for details
::  2024.02.15.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 240215.11 - See \Scripts\MSRD-Collect\MSRD-Collect-ReleaseNotes.txt for details; AVD: Deprecated UEX_AVDMSIXAA, use UEX_AVDAppAttach instead
::  2024.02.12.0 [rk] _UEX: RDS: added new lserver provider
::  2024.01.31.0 [gr] _UEX: QuickAssist: added msra in the scenario for the providers.
::  2024.01.22.0 [gr] _UEX: QuickAssist: added procmon in the scenario.
::  2024.01.22.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 240119.4 - See \Scripts\MSRD-Collect\MSRD-Collect-ReleaseNotes.txt for details; Adjusted AVD/RDS CollectLog functions; Added FSLogix providers to UEX_RDSsrv; Added UEX_FSLogix scenario
::  2024.01.15.0 [rk] _UEX: AVD: Added new tracing scenarios 'UEX_AVDcli' and 'UEX_AVDsrv'; AVD/RDS: Defined -switches for AVD and RDS as workaround for the -CollectLog limitation when combined with -Scenario; Updated MSRD-Collect to version 240112.6 - See \Scripts\MSRD-Collect\MSRD-Collect-ReleaseNotes.txt for details
::  2024.01.10.1 [rk] _UEX: AVD/RDS: Updated AVD and RDS CollectLog datasets
::  2024.01.10.0 [sb] _UEX: using robocopy to collect FSLogix logs
::  2023.12.28.0 [sb] _UEX: typo fix in FSLogix logs collection + LogInfo for FSLogix logs collection
::  2023.12.22.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 231222.8 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.12.11.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 231211.4 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.11.24.0 [rk] _UEX: RDS: Added 'Procmon' to UEX_RDSsrv scenario
::  2023.11.15.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 231115.5 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.11.11.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 231110.6 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.11.01.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 231031.22 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.09.29.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 230929.7 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.09.23.0 [rk] _UEX: RDS: Temporarily enabling -UEX_RDS again for Autologger scenarios
::  2023.09.21.0 [rk] _UEX: RDS: Deprecated UEX_RDS, use UEX_RDScli (for client/source side tracing) or UEX_RDSsrv (for RDS server/target side tracing) instead
::  2023.09.19.0 [rk] _UEX: RDS: Updated RDS and MSRA providers, added Shadowing providers; AVD/RDS: Updated MSRD-Collect to version 230910.1
::  2023.08.24.0 [cn] _UEX: MDAG: Fixed Network gathering for Host and container and adapted GUIDS
::  2023.08.17.0 [rk] _UEX: AVD/RDS: Updated MSRD-Collect to version 230817.3 + changed the data collection method in the AVD and RDS CollectLog functions + removed UEX_RDS from UEX_Logon scenario
::  2023.08.12.0 [we] _UEX: replaced $UEX_DummyProviders with @()
::  2023.08.11.0 [rk] _UEX: AVD: Updated UEX_AVDSource to get source type Diagnostics instead of host type; RDS: Updated UEX_RDSSource and UEX_RDScli to get source type Diagnostics instead of host type
::  2023.08.10.0 [rk] _UEX: AVD: Updated MSRD-Collect to version 230808.6 + added 'xray' to the AVD data collection scenarios + added 'UEX_AVDSource' Scenario and CollectLog for client side data collection; RDS: Added MSRD-Collect for 'RDS' data collection (UEX_RDSSource, UEX_RDSCore, UEX_RDSProfiles, UEX_RDSActivation, UEX_RDSMSRA, UEX_RDSSCard, UEX_RDSIME, UEX_RDSDiag) + updated 'UEX_RDScli' to include 'UEX_RDSSource' and 'UEX_RDSDiag' + updated 'UEX_RDSsrv' to include 'UEX_RDSCore' and 'UEX_RDSDiag' + documented RDS providers
::  2023.08.03.4 [we] _UEX: deprecated all NET_RDS* components/scenarios -> use UEX_RDS*
::  2023.08.03.2 [es] _UEX: fixed CollectUEX_AppVLog #522
::  2023.08.03.1 [we] _UEX: add scenario UEX_AppV #488
::  2023.07.31.0 [rk] _UEX: AVD: Updated MSRD-Collect to version 230731.8 and adjusted invoke parameters - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.07.21.0 [gr] _UEX: TSched : Removed UEX_Task, UEX_Sched; Added tracing to UEX_TSched.
::  2023.07.18.0 [rk] _UEX: AVD: Updated MSRD-Collect to version 230717.10 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.07.07.0 [gr] _UEX: AppV : Added EventLogs
::  2023.07.04.0 [gr] _UEX: Telemetry : Started moving data to dedicated folder
::  2023.07.03.0 [gr] _UEX: Telemetry : Minor change for Events handling.
::  2023.06.30.0 [gr] _UEX: Telemetry : Added the Telemetry eventlog for the collect + renamed registry key with the prefix Telemetry
::  2023.06.28.0 [rk] _UEX: AVD: Updated MSRD-Collect to version 230627.10 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.06.16.0 [cn] _UEX: MDAG: removed external script reference and implemented the gathering
::  2023.06.15.0 [gbrag] _UEX: improved WMI tracing
::  2023.06.14.0 [we] _UEX: replaced ADS_kernel with WIN_kernel
::  2023.06.13.0 [rk] _UEX: AVD: Updated MSRD-Collect to version 230613.3 - See \Scripts\MSRD-Collect\MSRD-Collect-RevisionHistory.txt for details
::  2023.06.09.0 [rk] _UEX: Moved UEX_Search to PRF_Search and deprecated UEX_Search + Sorted UEX components alphabetically per technology for better code overview
::  2023.06.08.0 [rk] _UEX: AVD: Updated MSRD-Collect to version 230608.10 and adjusted invoke parameters
::  2023.06.07.0 [gr] _UEX: UEX_Telemetry : add a create folder prior to the copy
::  2023.06.01.0 [gr] _UEX: UEX_Telemetry : update RegKey names depending on the function called
::  2023.05.29.0 [gbrag] _UEX: Updated calls to WinRM-Collect and Sched-Collect
::  2023.05.19.3 [tfairman] _NET: Move SCM component to TSS_PRF
::  2023.05.19.0 [rk] _UEX: Added MSRD-Collect for 'AVD host' data collection (UEX_AVDCore, UEX_AVDProfiles, UEX_AVDActivation, UEX_AVDMSRA, UEX_AVDSCard, UEX_AVDIME, UEX_AVDTeams, UEX_AVDMSIXAA, UEX_AVDHCI, UEX_AVDDiag)
::  2023.05.18.1 [hk] _UEX: UEX_Print : added GUID
::  2023.05.18.0 [hk] _UEX: UEX_AppCompat : added GUID
::  2023.05.10.0 [gr] _UEX: Telemetry: Added Appcompat folder,Use of the FW function to add/Remove registry values
::  2023.04.24.0 [cn] _UEX: MDAG: Adding more providers and added some collection
::  2023.04.19.0 [gr] _UEX: UEX_Telemetry : PostOp : Modified AppRaiser, add as is M365HandlerLog, DisableAppRaiserVerboseMode and RestartDiagTrack
::  2023.04.18.0 [gr] _UEX: UEX_Telemetry : Appraiser in PostOp
::  2023.04.14.0 [cn] _UEX: paths with space bug fixes
::  2023.04.13.1 [gr] _UEX: UEX_Telemetry : added census
::  2023.04.13.0 [cn] _UEX: Adding MDAG Containers data collection and fixed few bugs (reg size exported)
::  2023.04.12.0 [yn] _UEX: UEX_AppId : added GUID and CollectLogs
::  2023.04.11.0 [gr] _UEX: UEX_Telemetry : added the ConnectivityDiagnosis
::  2023.04.07.0 [rh] _UEX: Move previous UEX components to PERF and add deprecated param list to show friendly error message
::  2023.04.05.0 [cn] _UEX: Adding more etl and solving minor bugs.
::  2023.04.04.1 [gr] _UEX: UEX_Telemetry : Improved the function
::  2023.04.04.0 [cn] _UEX: Adding MDAG collection
::  2023.04.03.1 [gr] _UEX: UEX_Telemetry : Added the registry keys to export
::  2023.04.02.0 [rh] _UEX: Merge NET_PrintSvc functions into UEX_Print(Feature#362)
::  2023.03.31.2 [gr] _UEX: UEX_Telemetry : Started the Function Telemetry with the add of the ETL Tracing Providers
::  2023.03.31.1 [gr] _UEX: UEX_WMIHighCPU : Removed UEX_Kernel trace and use WIN_kernel one
::  2023.03.31.0 [rh] _UEX: Merge GUIDs in PrintTrace.cmd into UEX_Print(Feature#362)
::  2023.03.30.0 [gr] _UEX: UEX_WMIHighCPU : Added the WMIK instead of WMI provider + NoBasicLogs
::  2023.03.27.0 [cn] _UEX: Adding MDAG Host ETL tracing
::  2023.03.20.0 [gr] _UEX: Adding the WMI HighCPU Scenario
::  2023.03.17.0 [gr] _UEX: Adding UEX_Fusion and adding UEX_MMC Scenario
::  2023.03.15.0 [rh] _UEX: merge UEX_Mgmt to UEX module
::  2023.02.23.0 [rh] _UEX: comment out CollectUEX_WMILog and CollectUEX_WinRMLog to avoid duplication with UEX_Mgmt module
::  2023.02.21.0 [gr] _UEX: Add WinRM collect to UEX_Winrm scenario + MMC Collect
::  2023.02.07.0 [we] _UEX: add UEX_MMCSS
::  2022.12.07.0 [we] _UEX: add -Scenario UEX_General
::  2022.11.28.0 [we] consolidating NET/UEX *_WMI and *_AppV tracing
::  2022.07.27.0 [rh] add Get-StartApps to -UEX_Logon
::  2022.06.08.0 [rh] add AssignedAccess registries to -UEX_Logon
::  2022.05.31.0 [we] #_# fixed typos, replaced FileVersion with FwFileVersion
::  2022.05.29.0 [rh] remove CollectUEX_BasicLog() as it was replaced with -Basiclog
::  2022.05.16.0 [we] use FW functions like FwGetMsInfo32, FwCollect_BasicLog
::  2022.04.28.0 [rh] add shell CSP provider to UEX_Shell and UEX_DM
::  2022.04.19.0 [we] add UEX_PrintEx, UEX_DSC, UEX_Evt, UEX_Tsched dummy providers
::  2021.12.29.0 [we] fix #381 for Get-Timezone on Srv2012
::  2021.12.08.0 [we] add collect -UEX_PrintEx -> change later to UEX_Print, once SME's decide to remove current UEX_Print component
::  2021.10.22.0 [we] call external \scripts\*-collect.ps1 for UEX_DSC, UEX_Evt, UEX_TSched
#>

#Requires -Version 4

$global:TssVerDateUEX = "2024.06.05.0"

#region --- ETW component trace Providers ---
$UEX_DummyProviders = @(
	'{eb004a05-9b1a-11d4-9123-0050047759bc}' ## Dummy tcp for switches without tracing GUID (issue #70)
)
# note, an empty list @() should work as well, instead of $UEX_DummyProviders, this would eliminate the need to deleate the dummy ETL file
$UEX_DSCProviders = @()
#$UEX_EvtProviders = @() # Commented on May 2024 by garabier
#$UEX_TSchedProviders = $UEX_DummyProviders

$UEX_AVDSourceProviders = @()
$UEX_AVDCoreProviders = @()
$UEX_AVDProfilesProviders = @()
$UEX_AVDActivationProviders = @()
$UEX_AVDMSIXAAProviders = @() #deprecated
$UEX_AVDAppAttachProviders = @()
$UEX_AVDTeamsProviders = @()
$UEX_AVDSCardProviders = @()
$UEX_AVDMSRAProviders = @()
$UEX_AVDIMEProviders = @()
$UEX_AVDHCIProviders = @()
$UEX_AVDDiagProviders = @()

$UEX_RDSSourceProviders = @()
$UEX_RDSCoreProviders = @()
$UEX_RDSProfilesProviders = @()
$UEX_RDSActivationProviders = @()
$UEX_RDSMSIXAAProviders = @()
$UEX_RDSTeamsProviders = @()
$UEX_RDSSCardProviders = @()
$UEX_RDSMSRAProviders = @()
$UEX_RDSIMEProviders = @()
$UEX_RDSDiagProviders = @()

#region--- AppLocker PROVIDERS ---#
$UEX_AppLockerProviders = @(
	'{CBDA4DBF-8D5D-4F69-9578-BE14AA540D22}' # Microsoft-Windows-AppLocker
	'{77FE4532-3F5C-5786-632B-FB3201BCE29B}' # Microsoft.Windows.Security.AppIdLogger
	'{1C15C3C7-20B4-446C-8D5E-3BBEC6461664}' # AppIDLog
	'{3CB2A168-FE19-4A4E-BDAD-DCF422F13473}' # "Microsoft-Windows-AppID"
	'{D02A9C27-79B8-40D6-9B97-CF3F8B7B5D60}' # "Microsoft-Windows-AppIDServiceTrigger"
	'{CF84DA43-F447-42DE-AD48-4FEEEA03247D}' # Microsoft.Windows.Security.EDPPolicyMgrApplockerTask
	'{63665931-A4EE-47B3-874D-5155A5CFB415}' # AuthzTraceProvider
	'{B997E40D-0880-4ED6-B7DF-84DF3305FE2B}' #
	'{76df1e7b-74d9-547f-1f87-affa9542809a}' #
	'{5AF61464-71AD-4419-A92A-7766E9A5ABC3}' # Microsoft-Windows-AppID-AppRep
)

#endregion--- AppLocker PROVIDERS ---#

#region--- APP-V PROVIDERS ---#
$UEX_AppVProviders = @(
	'{E4F68870-5AE8-4E5B-9CE7-CA9ED75B0245}' # Microsoft-AppV-Client
	'{0D21725F-A0BD-4D1D-AE8E-6910F1093419}' # Microsoft-AppV-Sequencer
	'{7561449A-FC50-469B-B76E-88F43CF79ECF}' # Microsoft-AppV-Sequencer-Debug
	'{9CC69D1C-7917-4ACD-8066-6BF8B63E551B}' # Microsoft-AppV-ServiceLog
	'{FB4A19EE-EB5A-47A4-BC52-E71AAC6D0859}' # Microsoft-AppV-SharedPerformance
	'{C901E37D-B5F4-4582-AE6E-C1459F358B30}' # Microsoft-AppV-Sequencer-PRS
	'{271aebf7-e83b-580f-7525-5e9563fe161a}' # Microsoft.Windows.AppMan.AppV
	'{582C6A21-F5B4-4E52-B592-0E8229BF1737}' # Microsoft.Windows.AppMan.Shared.Logging
	'{df9b8c8f-ed83-5cd0-acec-4790d087c32b}' # Microsoft.Windows.AppMan.AppV.Sequencer
	'{28CB46C7-4003-4E50-8BD9-442086762D12}' # Microsoft-AppV-Client-StreamingUX
	'{34BEC984-F11F-4F1F-BB9B-3BA33C8D0132}' # this is ADS Bio provider, just for testing guid conflicts
	'{86f50c0c-6a4c-4b9c-a370-62b45ebe6e85}' # Microsoft-AppV-Server-Management
	'{84D85C22-6552-4A3F-BC85-C525B952861B}' # Microsoft-AppV-Server-Management-Private
	'{825C7963-9E32-4E3B-B74A-DF2CC3B6822B}' # Microsoft-AppV-Server-Publishing
	'{213B8D98-9A5E-4453-A2AB-A9B68A3C3EEA}' # Microsoft-AppV-Server-Publishing-Private
	'{1BEAA11B-B9C8-4D95-B567-D12C799C7D6E}' # Microsoft-AppV-Server-Reporting
	'{ECE17739-6097-4CC6-9B1C-FE40258A442B}' # Microsoft-AppV-Server-Reporting-Private
)
#endregion--- APP-V PROVIDERS ---#


#region--- AVD PROVIDERS ---#
$UEX_WVDProviders = @(						 # keeping this for legacy UEX_WVD usage
	'{C3B02229-FF93-4D28-ACFC-4FB28AC6CDB5}' # RdClientWinRT
	'{97A820E5-5F64-4573-8114-99B450D0B067}' # RDCoreApp
	'{6FA2A01C-9F89-474B-A71A-A783925EFE45}' # RDCoreNanoCom
	'{CA341B3C-B9D2-4D0F-9BD3-D88183596DB9}' # RDP.ServerStack.Diagnostics
	'{6CBE573A-121B-4E02-A09D-6C0B6B96D676}' # RDP.ServerStack.QOE
	'{50134CDD-5FE1-4315-8C8D-50900921ACCE}' # Microsoft.Windows.HVSI.RDP
	'{080656C2-C24F-4660-8F5A-CE83656B0E7C}' # Microsoft.Windows.RemoteDesktop.ClientCore
	'{48EF6C18-022B-4394-BEE5-7B822B42AE4C}' # Microsoft.RDS.Windows.Client.MSRDC
	'{335934AA-6DD9-486C-88A5-F8D6A7D2BAEF}' # Microsoft.RDS.Windows.Client.AX
	'{43471865-f3ee-5dcf-bf8b-193fcbbe0f37}' # Microsoft.Windows.RemoteDesktopServices.RailPlugin
	'{FB9FF164-54F0-43DD-BF86-1C761FAB3052}' # msrdcsh
	'{E80ADCF1-C790-4108-8BB9-8A5CA3466C04}' # Microsoft-Windows-TerminalServices-RDP-AvcSoftwareDecoder
	'{eb6594d8-6fad-53f7-350e-f4e4c531f68c}' # Microsoft.Windows.RDP.NamedPipe
	'{7756e5a6-21b2-4c40-855e-88cf2b13c7cb}' # RDP.MSTSCAXTelemetry
	'{76de1e7b-74d5-575e-1f81-4ffe6a42777b}' # RDWin32ClientAxTelemetryProvider
	'{D953B8D8-7EA7-44B1-9EF5-C34AF653329D}' # RDP.Graphics
	'{8A633D91-8B07-4AAE-9A00-D07E2AFD29D6}' # RDP.Transport
	'{a8f457b8-a2b8-56cc-f3f5-3c00430937bb}' # RDPEmulationTraceLogging
	'{93C56D9B-7FDB-4E06-8DED-26000EEE0F60}' # MSTSCFeedbackHub
	'{4f50731a-89cf-4782-b3e0-dce8c90476ba}' # Microsoft Telemetry provider group
	'{140C2428-F60D-43F9-9B07-3E5F622438A0}' # CacNxTraceGuid(WPP)
	'{eca5427c-f28f-4942-a54b-7e86da46bdbe}' # TSUrbUtils(WPP)
	'{7211ae02-1eb0-454a-88fa-ea16632dcb45}' # TSUsbBusFilter(WPP)
	'{39a585ff-6c36-492b-93c0-35b71e65a345}' # TSUsbGenericDriver(WPP)
	'{a0674fb6-ba0d-456f-b079-a2b029d8342c}' # TSUsbHubTrace(WPP)
	'{48738267-0545-431d-8087-7349127811d0}' # TSUsbRedirectionServiceTrace(WPP)
)

$UEX_RDWebRTCProviders = @(				     # keeping this for legacy UEX_WVD usage
	'{E75983D3-3045-49D7-9E5D-6E7EECC45261}' # RDPWebRTCRedirectorClient
	'{AAA1F55E-F99C-45CB-B318-FAEB798DB8E0}' # RDPWebRTCRedirectorHost
	'{2EFD4CDE-32FD-4A55-A310-2DB9A49D4262}' # CTRLGUID_RDC_WEBRTC_REDIRECTOR
)

$UEX_AvdRDWebRTCProviders = @(				 # for the new UEX_AVDcli/UEX_AVDsrv
	'{E75983D3-3045-49D7-9E5D-6E7EECC45261}!AvdRDWebRTC' # RDPWebRTCRedirectorClient
	'{AAA1F55E-F99C-45CB-B318-FAEB798DB8E0}!AvdRDWebRTC' # RDPWebRTCRedirectorHost
	'{2EFD4CDE-32FD-4A55-A310-2DB9A49D4262}!AvdRDWebRTC' # CTRLGUID_RDC_WEBRTC_REDIRECTOR
)
#endregion--- AVD PROVIDERS ---#


#region--- FSLOGIX PROVIDERS ---#
$UEX_FSLogixProviders = @(
	'{9a2c09eb-fbd6-5127-090f-402799cb18a2}' # Microsoft.FSLogix.Frxsvc
	'{5f7d6ea0-7bfa-5c0a-4674-acce76757f19}' # Microsoft.FSLogix.Frxccds
	'{83afe79f-c9c6-5152-3636-05de47c1fa72}' # Microsoft.FSLogix.Search
	'{65fa0e9f-db27-5053-a4e0-e40c42ba5271}' # Microsoft.FSLogix.UsermodeDll
	'{578c4cac-e98c-5315-f3e6-fbc0a97b286f}' # Microsoft.FSLogix.ConfigurationTool
	'{048a4a25-ff60-5d27-8f58-71c0f9d3fc92}' # Microsoft.FSLogix.RuleEditor
	'{f1a8d80a-2d4d-5dfc-7c26-88b5cce761c9}' # Microsoft.FSLogix.JavaRuleEditor
	'{6d14bf0a-be6f-592f-cbcc-61b5e8d18c5c}' # Microsoft.FSLogix.IE_Plugin
	'{f9317b16-badc-55b3-a0cf-9a0a126e12fd}' # Microsoft.FSLogix.FrxLauncher
	'{220d0827-a763-50ac-6999-a59a7ca5d316}' # Microsoft.FSLogix.TrayTool
	'{e5cd7d19-e708-5957-ba97-11858c57eb80}' # Microsoft.FSLogix.Frxdrvvt
	'{6352de6a-8fc2-5afe-a709-fb70e825dc24}' # Microsoft.FSLogix.Frxdrv
	'{becf2b11-c4a9-5e4c-e0d2-c22092799316}' # Microsoft.FSLogix.Diagnostic
	'{5d97526b-4987-550f-4bee-347e84c5a5c6}' # Microsoft.FSLogix.Frxccd
	'{EE5D17C5-1B3E-4792-B0F9-F8C5FC6AC22A}' # Azure Storage
)
#endregion--- FSLOGIX PROVIDERS ---#


#region--- Management and Scripting PROVIDERS ---#

#--- COM/DCOM/WinRT/RPC PROVIDERS ---#
$UEX_COMProviders = @(
	'{9474a749-a98d-4f52-9f45-5b20247e4f01}' # DCOMSCM
	'{bda92ae8-9f11-4d49-ba1d-a4c2abca692e}' # OLE32(combase.dll)
	'{d4263c98-310c-4d97-ba39-b55354f08584}' # Microsoft-Windows-COM(advapi32.dll)
	'{0f177893-4a9c-4709-b921-f432d67f43d5}' # Microsoft-Windows-Complus(comres.dll)
	'{1B562E86-B7AA-4131-BADC-B6F3A001407E}' # Microsoft-Windows-DistributedCOM(combase.dll)
	'{B46FA1AD-B22D-4362-B072-9F5BA07B046D}' # COMSVCS(COM+)
	'{A0C4702B-51F7-4ea9-9C74-E39952C694B8}' # COMADMIN(COM+)
	'{1AFF6089-E863-4D36-BDFD-3581F07440BE}' # CombaseTraceLoggingProvider
	'{6AD52B32-D609-4BE9-AE07-CE8DAE937E39}' # Microsoft-Windows-RPC(rpcrt4.dll)
	'{F4AED7C7-A898-4627-B053-44A7CAA12FCD}' # Microsoft-Windows-RPC-Events(rpcrt4.dll)
	'{d8975f88-7ddb-4ed0-91bf-3adf48c48e0c}' # Microsoft-Windows-RPCSS(RpcEpMap.dll)
	'{097d1686-4038-46be-b551-10fda0387165}' # CLBCATQ
	'{A86F8471-C31D-4FBC-A035-665D06047B03}' # Microsoft-Windows-WinRT-Error
	'{bf406804-6afa-46e7-8a48-6c357e1d6d61}' # Microsoft-Windows-COMRuntime
	'{7913ac64-a5cd-40cd-b096-4e8c4028eaab}' # Microsoft-Windows-WinTypes-Perf
	'{f0558438-f56a-5987-47da-040ca757ef05}' # Microsoft.Windows.WinRtClassActivation
	'{53201895-60E8-4fb0-9643-3F80762D658F}' # COM+ Services
	'{272A979B-34B5-48EC-94F5-7225A59C85A0}' # Microsoft-Windows-RPC-Proxy-LBS
	'{879b2576-39d1-4c0f-80a4-cc086e02548c}' # Microsoft-Windows-RPC-Proxy
	'{536caa1f-798d-4cdb-a987-05f79a9f457e}' # Microsoft-Windows-RPC-LBS
)

#--- EVENTLOG PROVIDERS ---#
$UEX_EvtProviders = @(
	'{FC65DDD8-D6EF-4962-83D5-6E5CFE9CE148}' # Microsoft-Windows-Eventlog
	'{B0CA1D82-539D-4FB0-944B-1620C6E86231}' # WMI EventLogTrace
	'{565BBECA-5B04-49BB-81C6-3E21527FCC8A}' # Microsoft-Windows-Eventlog-ForwardPlugin
	'{35AC6CE8-6104-411D-976C-877F183D2D32}' # Microsoft-Windows-EventLog-WMIProvider
	'{899DAACE-4868-4295-AFCD-9EB8FB497561}' # Microsoft-Windows-EventSystem
)

#--- MMC PROVIDERS ---#
$UEX_FusionProviders = @()

$UEX_MMCProviders = @(
	'{9C88041D-349D-4647-8BFD-2C0A167BFE58}' # MMC
)

#--- POWERSHELL PROVIDERS ---#
$UEX_PowerShellProviders = @(
	'{A0C1853B-5C40-4B15-8766-3CF1C58F985A}' # Microsoft-Windows-PowerShell
	'{EAD6595B-5613-414C-A5EE-069BB1ECA485}' # Microsoft-Windows-PowerShellWebAccess
)

#--- SERVERMANAGER PROVIDERS ---#
$UEX_ServerManagerProviders = @(
	'{C2E6D0D9-5DF8-4C77-A82B-C96C84579543}' # Microsoft-Windows-ServerManager-ManagementProvider
	'{D8D37081-10BD-4A89-A971-1CDA6899BDB3}' # Microsoft-Windows-ServerManager-MultiMachine
	'{66AF9A38-2D94-11E0-A076-8534E0D72085}' # Microsoft-Windows-ServerManager-DeploymentProvider
	'{6e27f02d-8a55-477e-88b5-6f1ba07e14b4}' # Microsoft-Windows-ServerManager-ConfigureSMRemoting
)

#--- TASKSCHEDULER PROVIDERS ---#
$UEX_TSchedProviders = @(
	'{077E5C98-2EF4-41D6-937B-465A791C682E}' # Microsoft-Windows-DesktopActivityBroker
	'{6A187A25-2325-45F4-A928-B554329EBD51}' # Scheduler
	'{047311A9-FA52-4A68-A1E4-4E289FBB8D17}' # TaskEng_JobCtlGuid
	'{10FF35F4-901F-493F-B272-67AFB81008D4}' # Microsoft.Windows.TaskScheduler
	'{19043218-3029-4BE2-A6C1-B6763CECB3CC}' # EventAggregation
	'{DE7B24EA-73C8-4A09-985D-5BDADCFA9017}' # Microsoft-Windows-TaskScheduler
	'{0657ADC1-9AE8-4E18-932D-E6079CDA5AB3}' # Microsoft-Windows-TimeBroker
	'{E8109B99-3A2C-4961-AA83-D1A7A148ADA8}' # System/TimeBroker WPP
	'{A7C8D6F2-1088-484B-A516-1AE0C3BF8216}' # SchedWmiGuid
	'{42695762-EA50-497A-9068-5CBBB35E0B95}' # Windows Notification Facility Provider
	'{1D665082-C852-4AB0-A1B2-C26488454C41}' # UBPM
	'{B6BFCC79-A3AF-4089-8D4D-0EECB1B80779}' # Microsoft-Windows-SystemEventsBroker
	'{E6835967-E0D2-41FB-BCEC-58387404E25A}' # Microsoft-Windows-BrokerInfrastructure
)

#--- TELEMETRY PROVIDERS ---#
$UEX_TelemetryProviders = @(
	'{43AC453B-97CD-4B51-4376-DB7C9BB963A}'  # Microsoft.Windows.DiagTrack
	'{56DC463B-97E8-4B59-E836-AB7C9BB96301}' # Microsoft-Windows-DiagTrack
)

#--- WMI PROVIDERS ---#
# Commented on May 2024 by garabier
<#$UEX_WMIProviders = @(  # To be decommissioned, replace by WMIBase and WMIAdvanced
	'{1FF6B227-2CA7-40F9-9A66-980EADAA602E}' # WMI_Tracing_Guid WBEMCOMM
	'{8E6B6962-AB54-4335-8229-3255B919DD0E}' # WMI_Tracing_Client_Operations_Info_Guid
	'{1418EF04-B0B4-4623-BF7E-D74AB47BBDAA}' # Microsoft-Windows-WMI-Activity
	'{2CF953C0-8DF7-48E1-99B9-6816A2FBDC9F}' # Microsoft-Windows-WMIAdapter
	'{1EDEEE53-0AFE-4609-B846-D8C0B2075B1F}' # Microsoft-Windows-WMI
)#> 

$UEX_WMIProvStorage = @(
	'{595F33EA-D4AF-4F4D-B4DD-9DACDD17FC6E}' # Microsoft-Windows-StorageManagement-WSP-Host
	'{88C09888-118D-48FC-8863-E1C6D39CA4DF}' # Microsoft-Windows-StorageManagement-WSP-Spaces
	'{C6281CF0-7253-4185-9A91-486327931BDC}' # SxControlGuid
	'{9282168F-2432-45F0-B91C-3AF363C149DD}' # TRACELOG_PROVIDER_NAME_STORAGEWMI
	'{7E58E69A-E361-4F06-B880-AD2F4B64C944}' # Microsoft-Windows-StorageManagement
	'{88B892C2-FCCD-4881-946A-032897F954B0}' # Provider Passthru
	'{E14DCDD9-D1EC-4DC3-8395-A606DF8EF115}' # virtdisk
	'{4D20DF22-E177-4514-A369-F1759FEEDEB3}' # virtdisk
	'{C24D82FA-8E22-46C8-9D79-4D763EA059D0}' # storagewmi
	'{80DF111F-178D-44FB-AFB4-5D179DE9D4EC}' # storagewmi
	'{4FA1102E-CC1D-4509-A69F-121E2CC96F9C}' # SDDC
	'{7F8DA3B5-A58F-481E-9637-D41435AE6D8B}' # Microsoft-Windows-SDDC-Management
	'{6D09BA4F-D4D0-49DD-8BDD-DEB59A33DFA8}' # TRACELOG_PROVIDER_NAME_SMPHOST
)

$UEX_WMIProvCluster = @(
	'{0461BE3C-BC15-4BAD-9A9E-51F3FADFEC75}' # Microsoft-Windows-FailoverClustering-WMIProvider
	'{FF3E7036-643F-430F-B015-2933466FF0FD}' # Microsoft-Windows-FailoverClustering-WMI
	'{D82DBA12-8B70-49EE-B844-44D0885951D2}' # CSVFLT
)

$UEX_WMIProvDCOM = @(
	'{B46FA1AD-B22D-4362-B072-9F5BA07B046D}' # comsvcs
	'{A0C4702B-51F7-4ea9-9C74-E39952C694B8}' # comadmin
	'{9474a749-a98d-4f52-9f45-5b20247e4f01}' # dcomscm
	'{bda92ae8-9f11-4d49-ba1d-a4c2abca692e}' # ole32 - This also requires "reg add HKEY_LOCAL_MACHINE\Software\Microsoft\OLE\Tracing /v ExecutablesToTrace /t REG_MULTI_SZ /d * /f"
)

$UEX_WMIProvRPC = @(
	'{6AD52B32-D609-4BE9-AE07-CE8DAE937E39}' # Microsoft-Windows-RPC
	'{F4AED7C7-A898-4627-B053-44A7CAA12FCD}' # Microsoft-Windows-RPC-Events
	'{D8975F88-7DDB-4ED0-91BF-3ADF48C48E0C}' # Microsoft-Windows-RPCSS
)

$UEX_WMIProvMDM = @(
	'{0A8E17FD-ED19-4C54-A1E7-5A2829BF507F}' # DMCmnUtils
	'{F1201B5A-E170-42B6-8D20-B57AC57E6416}' # Microsoft-Windows-DeviceManagement-Pushrouter
	'{9FBF7B95-0697-4935-ADA2-887BE9DF12BC}' # Microsoft-Windows-DM-Enrollment-Provider
	'{3DA494E4-0FE2-415C-B895-FB5265C5C83B}' # Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider
	'{E74EFD1A-B62D-4B83-AB00-66F4A166A2D3}' # Microsoft.Windows.EMPS.Enrollment
	'{F9E3B648-9AF1-4DC3-9A8E-BF42C0FBCE9A}' # Microsoft.Windows.EnterpriseManagement.Enrollment
	'{86625C04-72E1-4D36-9C86-CA142FD0A946}' # Microsoft.Windows.DeviceManagement.OmaDmApiProvider
	'{7D85C2D0-6490-4BB4-BAC1-247D0BD06F10}' # Microsoft-WindowsPhone-OMADMAPI-Provider
	'{EF614386-F019-4323-85A1-D6EBAF9CDE12}' # WPPCtrlGuid
	'{A76DBA2C-9683-4BA7-8FE4-C82601E117BB}' # WMIBRIDGE_TRACE_LOGGING_PROVIDER
)

$UEX_WMIProvPerf = @(
	'{BFFB9DBD-5983-4197-BB1A-243798DDBEC7}' # WMIPerfClass
	'{970406AD-6475-45DA-AA30-57E0037770E4}' # WMIPerfInst
	'{62841F33-387A-4674-94A4-485C418C57EE}' # Pdh
	'{04D66358-C4A1-419B-8023-23B73902DE2C}' # Microsoft-Windows-PDH
	'{E1A5FA6F-2E74-4C70-B292-D34C4338D54C}' # LoadperfDll
	'{BC44FFCD-964B-5B85-8662-0BA87EDAF07A}' # Microsoft-Windows-Perflib
	'{13B197BD-7CEE-4B4E-8DD0-59314CE374CE}' # Microsoft-Windows-Perflib
	'{970407AD-6485-45DA-AA30-58E0037770E4}' # PerfLib
)

$UEX_WMIProvRDMS = @(
	'{FB750AD9-8544-427F-B284-8ED9C6C221AE}' # Microsoft-Windows-Rdms-UI
	'{05DA6B40-219E-4F17-92E6-D663FD87CBA8}' # Microsoft-Windows-Remote-Desktop-Management-Service
	'{D8975F88-7DDB-4ED0-91BF-3ADF48C48E0C}' # Microsoft-Windows-RPCSS
)

$UEX_WMIProvRDSPub = @(
	'{81B84BCE-06B4-40AE-9840-8F04DD7A8DF7}' # TSCPubWmiProvider
	'{0CEA2AEE-1A4C-4DE7-B11F-161F3BE94669}' # TSPublishingIconHelperTrace
	'{1B9B72FC-678A-41C1-9365-824658F887E9}' # TSPublishingAppFilteringTrace
	'{7ADA0B31-F4C2-43F4-9566-2EBDD3A6B604}' # TSCentralPublishingTrace
)

$UEX_WMIProvSCM = @(
	'{EBCCA1C2-AB46-4A1D-8C2A-906C2FF25F39}' # ScReg
	'{0063715B-EEDA-4007-9429-AD526F62696E}' # Microsoft-Windows-Services
	'{06184C97-5201-480E-92AF-3A3626C5B140}' # Microsoft-Windows-Services-Svchost
	'{555908D1-A6D7-4695-8E1E-26931D2012F4}' # Service Control Manager
)

$UEX_WMIBaseProviders = @(
	'{1EDEEE53-0AFE-4609-B846-D8C0B2075B1F}' # Microsoft-Windows-WMI
	'{1418EF04-B0B4-4623-BF7E-D74AB47BBDAA}' # Microsoft-Windows-WMI-Activity
)

$UEX_WMIAdvancedProviders = @(
    $UEX_WMIBaseProviders
	'{2CF953C0-8DF7-48E1-99B9-6816A2FBDC9F}' # Microsoft-Windows-WMIAdapter
	'{1FF6B227-2CA7-40F9-9A66-980EADAA602E}' # WMI_Tracing
	'{8E6B6962-AB54-4335-8229-3255B919DD0E}' # WMI_Tracing_Client_Operations_Info_Guid
)

foreach ($suffix in $global:WMIProvList) {
    $variableName = "UEX_WMIProv" + $suffix
    if (Get-Variable -Name $variableName -ErrorAction SilentlyContinue) {
        $UEX_WMIBaseProviders += Get-Variable -ValueOnly -Name $variableName
        $UEX_WMIAdvancedProviders += Get-Variable -ValueOnly -Name $variableName
    }
}

# Commented on 2024-05-24 by garabier
#$UEX_WMIActivityProviders = @(  # To be decommissioned
#	'{1FF6B227-2CA7-40F9-9A66-980EADAA602E}' # WMI_Tracing
#	'{1418EF04-B0B4-4623-BF7E-D74AB47BBDAA}' # Microsoft-Windows-WMI-Activity
#) 

# Commented on 2024-05-24 by garabier
#$UEX_WMIBridgeProviders = @(  # To be decommissioned
#	'{A76DBA2C-9683-4BA7-8FE4-C82601E117BB}' # Microsoft.Windows.DeviceManagement.WmiBridge
#)

#--- WINRM PROVIDERS ---#
<# Deprecated. Commented on May 2024 by garabier
$UEX_WinRMProviders = @(
	'{A7975C8F-AC13-49F1-87DA-5A984A4AB417}' # Microsoft-Windows-WinRM
	'{04C6E16D-B99F-4A3A-9B3E-B8325BBC781E}' # WinRM(WPP)
	'{72B18662-744E-4A68-B816-8D562289A850}' # Windows HTTP Services
	'{7D44233D-3055-4B9C-BA64-0D47CA40A232}' # Microsoft-Windows-WinHttp
	'{B3A7698A-0C45-44DA-B73D-E181C9B5C8E6}' # WinHttp(WPP)
	'{4E749B6A-667D-4C72-80EF-373EE3246B08}' # WinInet(WPP)
	'{DD5EF90A-6398-47A4-AD34-4DCECDEF795F}' # Microsoft-Windows-HttpService
	'{20F61733-57F1-4127-9F48-4AB7A9308AE2}' # UxWppGuid(HTTP.sys - WPP)
	'{C42A2738-2333-40A5-A32F-6ACC36449DCC}' # Microsoft-Windows-HttpLog
	'{DD5EF90A-6398-47A4-AD34-4DCECDEF795F}' # Microsoft-Windows-HttpService
	'{7B6BC78C-898B-4170-BBF8-1A469EA43FC5}' # Microsoft-Windows-HttpEvent
	'{F5344219-87A4-4399-B14A-E59CD118ABB8}' # Microsoft-Windows-Http-SQM-Provider
	'{c0a36be8-a515-4cfa-b2b6-2676366efff7}' # WinRSMgr
	'{f1cab2c0-8beb-4fa2-90e1-8f17e0acdd5d}' # WinRSexe
	'{03992646-3dfe-4477-80e3-85936ace7abb}' # WinRSCmd
	'{651d672b-e11f-41b7-add3-c2f6a4023672}' # IPMIPrv
	'{D5C6A3E9-FA9C-434e-9653-165B4FC869E4}' # IpmiDrv
	'{6e1b64d7-d3be-4651-90fb-3583af89d7f1}' # WSManProvHost
	'{D5C6A3E9-FA9C-434e-9653-165B4FC869E4}' # IpmiDrv
	'{6FCDF39A-EF67-483D-A661-76D715C6B008}' # Event Forwarding
)
#>

$UEX_WinRMBaseProviders = @(
	'{A7975C8F-AC13-49F1-87DA-5A984A4AB417}' # Microsoft-Windows-WinRM
	'{04C6E16D-B99F-4A3A-9B3E-B8325BBC781E}' # Windows Remote Management Trace
	'{72B18662-744E-4A68-B816-8D562289A850}' # Windows HTTP Services
	'{DD5EF90A-6398-47A4-AD34-4DCECDEF795F}' # HTTP Service Trace
)
$UEX_WinRMAdvancedProviders = @(
	'{A7975C8F-AC13-49F1-87DA-5A984A4AB417}' # Microsoft-Windows-WinRM
	'{04C6E16D-B99F-4A3A-9B3E-B8325BBC781E}' # Windows Remote Management Trace
	'{699E309C-E782-4400-98C8-E21D162D7B7B}' # Microsoft-Windows-Forwarding
	'{B977CF02-76F6-DF84-CC1A-6A4B232322B6}' # Microsoft-Windows-EventCollector
	'{F1CAB2C0-8BEB-4FA2-90E1-8F17E0ACDD5D}' # RemoteShellClient
	'{03992646-3DFE-4477-80E3-85936ACE7ABB}' # RemoteShell
	'{7D44233D-3055-4B9C-BA64-0D47CA40A232}' # Microsoft-Windows-WinHttp
	'{B3A7698A-0C45-44DA-B73D-E181C9B5C8E6}' # WinHttp
	'{5BBCA4A8-B209-48DC-A8C7-B23D3E5216FB}' # Microsoft-Windows-CAPI2
	'{B3A7698A-0C45-44DA-B73D-E181C9B5C8E6}' # WinHttp
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' # Kerberos Authentication
	'{BBA3ADD2-C229-4CDB-AE2B-57EB6966B0C4}' # Kerberos Client
	'{98E6CFCB-EE0A-41E0-A57B-622D4E1B30B1}' # Microsoft-Windows-Security-Kerberos
	'{6165F3E2-AE38-45D4-9B23-6B4818758BD9}' # TSPkg
	'{AC43300D-5FCC-4800-8E99-1BD3F85F0320}' # Microsoft-Windows-NTLM
	'{C92CF544-91B3-4DC0-8E11-C580339A0BF8}' # NTLM Security Protocol
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}' # NTLM Authentication
	'{1F678132-5938-4686-9FDC-C8FF68F15C85}' # Schannel
	'{37D2C3CD-C5D4-4587-8531-4696C44244C8}' # SchannelWppGuid
)

$UEX_WinRMProvFwd = @(
	'{699E309C-E782-4400-98C8-E21D162D7B7B}' # Microsoft-Windows-Forwarding
	'{B977CF02-76F6-DF84-CC1A-6A4B232322B6}' # Microsoft-Windows-EventCollector
)
$UEX_WinRMProvRemShell = @(
	'{F1CAB2C0-8BEB-4FA2-90E1-8F17E0ACDD5D}' # RemoteShellClient
	'{03992646-3DFE-4477-80E3-85936ACE7ABB}' # RemoteShell
)
$UEX_WinRMProvHTTPSYS = @(
	'{F5344219-87A4-4399-B14A-E59CD118ABB8}' # Microsoft-Windows-Http-SQM-Provider
	'{08F93B14-1608-4A72-9CFA-457EECEDBBA7}' # WebIo
	'{C42A2738-2333-40A5-A32F-6ACC36449DCC}' # Microsoft-Windows-HttpLog
	'{7B6BC78C-898B-4170-BBF8-1A469EA43FC5}' # Microsoft-Windows-HttpEvent
	'{20F61733-57F1-4127-9F48-4AB7A9308AE2}' # HttpSysGuid
	'{B1945E15-4933-460F-8103-AA611DDB663A}' # HttpSysProvider
)
$UEX_WinRMProvWinHTTP = @(
	'{7D44233D-3055-4B9C-BA64-0D47CA40A232}' # Microsoft-Windows-WinHttp
	'{B3A7698A-0C45-44DA-B73D-E181C9B5C8E6}' # WinHttp
)

$UEX_WinRMProvCAPI2 = @(
	'{5BBCA4A8-B209-48DC-A8C7-B23D3E5216FB}' # Microsoft-Windows-CAPI2
)

$UEX_WinRMProvKerberos = @(
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' # Kerberos Authentication
	'{BBA3ADD2-C229-4CDB-AE2B-57EB6966B0C4}' # Kerberos Client
	'{98E6CFCB-EE0A-41E0-A57B-622D4E1B30B1}' # Microsoft-Windows-Security-Kerberos
)

$UEX_WinRMProvCredSSP = @(
	'{6165F3E2-AE38-45D4-9B23-6B4818758BD9}' # TSPkg
)

$UEX_WinRMProvNTLM = @(
	'{AC43300D-5FCC-4800-8E99-1BD3F85F0320}' # Microsoft-Windows-NTLM
	'{C92CF544-91B3-4DC0-8E11-C580339A0BF8}' # NTLM Security Protocol
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}' # NTLM Authentication
)

$UEX_WinRMProvPKU2U = @(
	'{2A6FAF47-5449-4805-89A3-A504F3E221A6}' # Pku2u Authentication
	'{B1108F75-3252-4B66-9239-80FD47E06494}' # IdentityCommonLib
	'{D93FE84A-795E-4608-80EC-CE29A96C8658}' # IdentityListenerControlGuid
	'{82C7D3DF-434D-44FC-A7CC-453A8075144E}' # IDStore
)

$UEX_WinRMProvSchannel = @(
	'{1F678132-5938-4686-9FDC-C8FF68F15C85}' # Schannel
	'{37D2C3CD-C5D4-4587-8531-4696C44244C8}' # SchannelWppGuid
)

$UEX_WinRMProvFwdCli = @(
	'{9D11915C-C654-4D73-A6D6-591570E011A0}' # EvtFwdrWpp
	'{6FCDF39A-EF67-483D-A661-76D715C6B008}' # ForwarderTrace
)

$UEX_WinRMProvEventLog = @(
	'{FC65DDD8-D6EF-4962-83D5-6E5CFE9CE148}' # Microsoft-Windows-Eventlog
	'{B0CA1D82-539D-4FB0-944B-1620C6E86231}' # EventlogTrace
)

foreach ($suffix in $global:WinRMProvList) {
    $variableName = "UEX_WinRMProv" + $suffix
    if (Get-Variable -Name $variableName -ErrorAction SilentlyContinue) {
        $UEX_WinRMBaseProviders += Get-Variable -ValueOnly -Name $variableName
        $UEX_WinRMAdvancedProviders += Get-Variable -ValueOnly -Name $variableName
    }
}

#endregion--- Management and Scripting PROVIDERS ---#

#region--- MDAG PROVIDERS ---#
$UEX_MDAGProviders = @(
	# RDP
	'{0C51B20C-F755-48a8-8123-BF6DA2ADC727}!MDAGHost!0xF000FFFFFFFF!0xff' #mstsc.exe
	'{DAA6CAF5-6678-43f8-A6FE-B40EE096E06E}!MDAGHost!0xF000FFFFFFFF!0xff' #mstscax.dll
	'{ea605ac7-d9de-434a-8271-682fee6d59ca}!MDAGHost!0xF000FFFFFFFF!0xff' #TSClientTrace
	'{D4197645-41DE-4ad5-9D71-A612C508FDD8}!MDAGHost!0xF000FFFFFFFF!0xff' #rdpxclient.exe
	'{8C74CED2-9899-4E01-A6D2-F924045DE932}!MDAGHost!0xF000FFFFFFFF!0xff' #rendrdp.dll
	'{70DB53D8-B6F3-428d-AA33-5B2CE56718C5}!MDAGHost!0xF000FFFFFFFF!0xff' #aaclient.dll
	'{936FF90C-7CC4-40d8-8A04-77B281C73AB9}!MDAGHost!0xF000FFFFFFFF!0xff' #aaclient.dll
	'{070f54b9-7eb0-4c99-8dfa-2aa8d8ab0d89}!MDAGHost!0xF000FFFFFFFF!0xff' #tsworkspace.dll
	'{3D3E7039-99DF-4446-8C81-4AD5A8560E7B}!MDAGHost!0xF000FFFFFFFF!0xff' #wkspbroker.exe
	'{3E3E7039-99DF-4446-8C81-4AD5A8560E7B}!MDAGHost!0xF000FFFFFFFF!0xff' #wkspbrokerAx.dll
	'{3C3E7039-99CF-4446-8D81-4AC5A8560E7B}!MDAGHost!0xF000FFFFFFFF!0xff' #wksprt.exe
	'{70A43AE8-E131-42bd-89E0-23704FB27C6A}!MDAGHost!0xF000FFFFFFFF!0xff' #tswbprxy.exe
	'{43471865-f3ee-5dcf-bf8b-193fcbbe0f37}!MDAGHost!0xffffffff!0x05'	 #Microsoft.Windows.RemoteDesktopServices.RailPlugin
	'{080656c2-c24f-4660-8f5a-ce83656b0e7c}!MDAGHost!0xffffffff!0x05'	 #Microsoft.Windows.RemoteDesktop.ClientCore
	'{cbdedbe0-b5c2-4ff6-905b-7a5ec0ebf8ed}!MDAGHost!0xffffffff!0x05'	 # radcui.dll
	'{7b919abb-998b-46a9-b8f3-d4a49e8074da}!MDAGHost!0xffffffff!0x05'	 # rdpnano.dll

	#HVSI
	'{b29d9185-a1eb-4740-84c3-b06f85d89341}!MDAGHost!0xffffffff!0xff'	 #hvsi service WPP
	'{7061B8A0-53F0-481D-9B10-BA98EFB69436}!MDAGHost!0xffffffff!0xff'	 #hvsi manager WPP
	'{483705FD-030A-4F15-8333-1B6BEF8E41CB}!MDAGHost!0xffffffff!0xff'	 #HvsiSettingsProvider WPP
	'{31a02453-ca69-48d4-a17e-97d08518f45c}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.HVSI.ContainerService
	'{5e3f60ef-a60f-45a9-84ae-e224f761baa3}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.HVSI.Manager
	'{c4ded72b-549f-4c21-8470-cb218a625a9e}!MDAGHost!0xffffffff!0x06'	 #Microsoft.Windows.Hvsi.Filter
	'{106e9835-2e81-5341-fd84-ab263098e7d3}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.HVSI.Settings
	'{372e8999-7d93-5961-0479-d472d9fe23f7}!MDAGHost!0x00000000!0xff'	 #Microsoft.Windows.HVSI.AppLauncher
	'{594ed7cb-28c9-4720-92d5-83e18518e364}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.HVSI.AuditSettings
	'{c76678a6-e4d0-4c49-b276-fb31d83f9b68}!MDAGHost!0x00000000!0x00'	 #Microsoft.Windows.HVSI.ChromeExtension
	'{3686a7c1-8c7a-442d-ae1c-b498470968c2}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.HVSI.CSP
	'{0b8d083d-254e-56d3-34df-d2134ce309e6}!MDAGHost!0x00000000!0xff'	 #Microsoft.Windows.HVSI.FileTrustFilter
	'{a2a602d5-1865-4a1f-bcd7-d67847deb021}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.HVSI.HvsiTask
	'{12a9c970-7843-482a-9c1b-fd39d4f3533a}!MDAGHost!0x00000000!0xff'	 #Microsoft.Windows.HVSI.PolicyEvaluator
	'{50134cdd-5fe1-4315-8c8d-50900921acce}!MDAGHost!0x00000000!0xff'	 #Microsoft.Windows.HVSI.RDP
	'{afc8a033-e28a-415c-acff-030e4b113a35}!MDAGHost!0xffffffff!0x05'	 #Microsoft.Streaming.Basix

	#Containers and VM
	'{9498441b-f0e0-4331-a5ad-a3e77e0ff2f4}!MDAGHost!0x0fffffff!0x07'	 #VMUSRV
	'{cb5b2c18-ad73-4ebf-8af1-73b30b885030}!MDAGHost!0x01100000!0x05'	 #VMBusDriverTraceGuid
	'{22267b1c-b979-5c81-9e24-0db386a62dd1}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.Containers.Setup
	'{80ce50de-d264-4581-950d-abadeee0d340}!MDAGHost!0x7fffffff!0x06'	 #Microsoft.Windows.HyperV.Compute - also used in netsh
	'{67eb0417-9297-42ae-a1d9-98bfeb359059}!MDAGHost!0x7fffffff!0xff'	 #Microsoft.Windows.Containers.Library
	'{6e31f252-a41c-41d7-a9e2-3a20162247ec}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.Containers.Wcifs
	'{AEC5C129-7C10-407D-BE97-91A042C61AAA}!MDAGHost!0xffffffff!0xff'	 #Microsoft-Windows-Containers-Wcifs
	'{8ce2286c-3705-4a2a-8e36-134eae9ca147}!MDAGHost!0x00000000!0x00'	 #Microsoft.Windows.Containers.DynamicImage
	'{74c975b8-6693-4aef-a440-13a4def639a6}!MDAGHost!0x00000000!0x00'	 #Microsoft.Windows.Containers.ImageWorker
	'{9d911ddb-d45f-41c3-b766-d566d2655c4a}!MDAGHost!0x00000000!0x00'	 #Microsoft.Windows.Containers.Manager
	'{1111450b-dacc-40a3-84ab-f7dba4a6e63a}!MDAGHost!0x00000000!0x00'	 #Microsoft.Windows.HyperV.VID
	'{b2ed3bdb-cd74-5b2c-f660-85079ca074b3}!MDAGHost!0x00000000!0x00'	 #Microsoft.Windows.HyperV.Socket
	'{06c601b3-6957-4f8c-a15f-74875b24429d}!MDAGHost!0xffffffff!0x05'	 #Microsoft.Windows.HyperV.Worker

	#Network
	<# removed as we trace in net trace
	'{66c07ecd-6667-43fc-93f8-05cf07f446ec}!MDAGNetComponents!0xffffffff!0x05'	  #Microsoft-Windows-WinNat
	'{aa7387cf-3639-496a-b3bf-dc1e79a6fc5a}!MDAGNetComponents!0xffffffff!0x06'	  #WinNat WPP
	'{07b7592c-a848-4520-89da-1ab26bc4629f}!MDAGNetComponents!0xffffffff!0xff'	  #Microsoft.Windows.Networking.EDP
	'{0c885e0d-6eb6-476c-a048-2457eed3a5c1}!MDAGNetComponents!0xffffffff!0x06'	  #Microsoft-Windows-Host-Network-Service
	'{93f693dc-9163-4dee-af64-D855218af242}!MDAGNetComponents!0xffffffff!0x05'	  #Microsoft-Windows-Host-Network-Management
	'{564368D6-577B-4af5-AD84-1C54464848E6}!MDAGNetComponents!0xffffffff!0x06'	  # Microsoft-Windows-Overlay-HNSPlugin
	'{D0E4BC17-34C7-43fc-9A72-D89A59D6979A}!MDAGNetComponents!0xffffffff!0x06'    # Microsoft.Windows.HostNetworkingService.PrivateCloudPlugin
	'{A6F32731-9A38-4159-A220-3D9B7FC5FE5D}!MDAGNetComponents!0xffffffff!0x06'	  # Microsoft-Windows-SharedAccess_NAT
	'{6C28C7E5-331B-4437-9C69-5352A2F7F296}!MDAGNetComponents!0xffffffff!0x06'	  # Microsoft.Windows.Hyper.V.VmsIf
	'{C29C4FB7-B60E-4FFF-9AF9-CF21F9B09A34}!MDAGNetComponents!0xffffffff!0x06'	  # Microsoft-Windows-Hyper-V-SynthNic
	# VmSwitch Enable ETW and WPP Events - Control Path Only
	'{1F387CBC-6818-4530-9DB6-5F1058CD7E86}!MDAGNetComponents!0xFFDFFFFB!0x06'	  # vmswitch
	'{67DC0D66-3695-47c0-9642-33F76F7BD7AD}!MDAGNetComponents!0xFFFFFFDD!0x06'	  # Microsoft-Windows-Hyper-V-VmSwitch
	'{9F2660EA-CFE7-428F-9850-AECA612619B0}!MDAGNetComponents!0x00410000!0x06'	  # Microsoft-Windows-Hyper-V-VfpExt
	# available starting in build 19041. Will check later
	#'{9F2660EA-CFE7-428F-9850-AECA612619B0}!MDAGNetComponents!0x00410000!0x06'    # Microsoft.Windows.Hyper.V.NetSetupHelper
	#>

	#Others
	'{d82215e3-bddf-54fa-895b-685099453b1c}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.BackgroundActivityModerator
	'{4e2b1375-f519-50a6-bfae-8c8a1a82d708}!MDAGHost!0xffffffff!0xff'	 #Microsoft.Windows.Shell.BackgroundActivityModerator

	#Firewall
	'{5EEFEBDB-E90C-423A-8ABF-0241E7C5B87D}!HostFirewall!0xffffffff!0xff'
	'{D8FA2E77-A77C-4494-9297-ACE3C12907F6}!HostFirewall!0xffffffff!0xff'
	'{28C9F48F-D244-45A8-842F-DC9FBC9B6494}!HostFirewall!0xffffffff!0xff'
	'{106B464A-8043-46B1-8CB8-E92A0CD7A560}!HostFirewall!0xffffffff!0xff'
	'{0C478C5B-0351-41B1-8C58-4A6737DA32E3}!HostFirewall!0xffffffff!0xff'
	'{AD33FA19-F2D2-46D1-8F4C-E3C3087E45AD}!HostFirewall!0xffffffff!0xff'
	'{5A1600D2-68E5-4DE7-BCF4-1C2D215FE0FE}!HostFirewall!0xffffffff!0xff'

	#Too verbose
	#'{7e9e8b9c-406c-5d73-e566-0f50ea3ade3e}!MDAGHost!0xffffffff!0x05'	 #EventProvider-Microsoft-Windows-Kernel-MemoryManager
	#'{D1D93EF7-E1F2-4F45-9943-03D245FE6C00}!MDAGHost!0xffffffff!0x05'	 #Microsoft-Windows-Kernel-Memory
)
#endregion--- MDAG PROVIDERS ---#


#region--- MSRA/QuickAssist/Shadowing PROVIDERS
$UEX_MSRAProviders = @(
	'{5b0a651a-8807-45cc-9656-7579815b6af0}!REMASSIST!0x0!0xff' # Microsoft-Windows-RemoteAssistance
	'{BBBC81CF-E219-469C-A405-F820EE496194}!REMASSIST!0x0!0xff' # Microsoft-Windows-P2P-PNRP
	'{D4199645-41BE-4FD5-9D71-A612C508FDC7}!REMASSIST!0xffffffff!0xf' #  RDPEnCom/ExCom (Remote Assistance)
	'{DAA6CAF5-6678-43f8-A6FE-B40EE096E00E}!REMASSIST!0xffffffff!0xf' #  Remote Assistance (rdp4vs)
	'{D4199645-41BE-4FD5-9D71-A612C508FDC6}!REMASSIST!0xffffffff!0xf' #  Remote Assistance (RdpCore)
	'{140C2428-F60D-43F9-9B07-3E5F622438A0}!REMASSIST!0xffffffff!0xf' #  Remote Assistance (RdpXCore)
)

$UEX_QuickAssistProviders = @(
	'{91558F59-B78A-4994-8B64-8067B33BDD71}' # Microsoft.RemoteAssistance
)

$UEX_ShadowingProviders = @(
	'{08D99868-34E8-4EF2-BF79-1EF3F3CD20E0}!REMASSIST!0xffffffff!0xf' # 2012 R2 Shadowing (RdpSA/ProxyUAC)
	'{E7C53BC0-EFF4-4DEE-993B-D48CB69766BD}!REMASSIST'                # Microsoft-Windows-DesktopSharing-Sharer
	'{642DF441-8193-4514-869F-7815DCA48372}!REMASSIST'                # Microsoft-Windows-DesktopSharing-Viewer
)
#endregion--- MSRA/QuickAssist/Shadowing PROVIDERS


#region--- PRINT PROVIDERS ---#
$UEX_PrintProviders = @(
	'{05af8001-5e28-5ebb-0329-a20fab346b76}' # Microsoft.Windows.Print.IppEmulator
	#'{077b8c4a-e425-578d-f1ac-6fdf1220ff68}' # Microsoft.Windows.Security.TokenBroker (commented out in PrintTrace.cmd)
	#'{bfed9100-35d7-45d4-bfea-6c1d341d4c6b}' # Microsoft.AAD.TokenBrokerPlugin.Provider (commented out in PrintTrace.cmd)
	'{08fad69b-3394-5632-97ef-ff9c5a842b1f}' # Microsoft.Windows.Print.Workflow.PrintSupport
	'{095da8da-2182-5c9a-53cd-07eca93a04ef}' # Microsoft.Windows.Print.XpsDocumentTargetPrint
	'{0aef9116-5ab8-5c05-0eb3-c0721ba93354}' # Microsoft.Windows.Print.PDMUtilities
	'{0E173F13-4266-4EFD-883C-79B24789B1BC}' # Microsoft-Windows-PrintDrivers
	'{15584c9b-7d86-5fe0-a123-4a0f438a82c0}' # Microsoft.Windows.Shell.ServiceProvider
	'{15fc363b-e2b4-5e55-f1d3-3b0ff726203d}' # Microsoft.Windows.Print.PCLmRenderFilter
	'{19E464A4-7408-49BD-B960-53446AE47820}' # DAS
	'{1bf554be-03c5-4f49-9b57-f3c0cbad589a}' # Microsoft.Windows.Print.Workflow.Broker
	'{201eb0f8-12f0-5b34-c99b-75c1541f3479}' # Microsoft.Windows.Print.UsbPortMig
	'{27a7ea23-db5c-5487-b775-89c06c43039b}' # Microsoft.Windows.Scan.EsclProtocol
	'{2974da9a-e1f3-5c5f-2abe-f7f20f6448bc}' # Microsoft.Windows.Print.JScriptLib
	'{29b47072-00ff-4d9d-852d-0eafc181a9a3}' # Microsoft-Windows-WSD-WSDApi
	'{2e008da9-e1b6-5cb5-0607-82066afcfff4}' # Microsoft.Windows.Scan.EsclScan
	'{38ae712f-fad1-528e-9721-6ebefea1ab2b}' # Microsoft.Windows.Print.Mopria.Service
	'{3d9d790d-fb07-539d-b66e-5a2ffb7899ca}' # Microsoft.Windows.Print.PrintCoreConfig
	'{3e617461-4ad0-5bb1-ce2d-796bf4794fbf}' # Microsoft.Windows.Scan.EsclEmulator
	'{3fc887c9-c23f-59cd-88b5-a6086f4bbc9e}' # Microsoft.Windows.Print.USBMon
	'{402d7aed-ded3-5536-3112-a2ce8baa1fdc}' # Microsoft.Windows.Print.McpManagementUtil
	'{44050ea2-419d-5526-923b-b038e0f1e715}' # Microsoft.Windows.Print.CloudPrintHelper
	'{48111f99-b3d5-5f69-587d-be4ed8e22647}' # Microsoft.Windows.Print.IppAdapterCore
	'{49868e3d-77fb-5083-9e09-61e3f37e0309}' # Microsoft.Windows.Print.HttpRest
	'{4a743cbb-3286-435c-a674-b428328940e4}' # PSMWPP
	'{4a892232-6efc-54c1-1f0a-1b916a719612}' # Microsoft.Windows.Scan.WindowsImageAcquisition
	'{4e880362-c4e8-5c62-7a2e-db0ee6a8f9a8}' # Microsoft.Windows.Scan.Plugins
	'{4ea56ff9-fc2a-4f0c-8d6e-c345bc452c80}' # DAFWSD
	'{556045FD-58C5-4A97-9881-B121F68B79C5}' # AAD Cloud AP
	'{6184BC1F-417E-4443-BCCE-9F65BF844AA7}' # Microsoft.Windows.Print.IppConfigConverter
	'{63a87ca3-6662-4925-a0a8-f7bb94ef104e}' # Microsoft.Windows.Print.PrintToPDF
	'{6d5ca4bb-df8e-41bc-b554-8aeab241f206}' # Microsoft.Windows.Print.DafIpp
	'{6de9ba0e-9e72-53d2-229a-dc09205a27ea}' # Microsoft-Windows-Mobile-Print-Plugins
	'{6fb61ac3-3455-4da4-8313-c1a855ee64c5}' # Microsoft.Windows.Print.IppMon
	'{73cf4d38-21a5-41dc-93d5-c8ec31d84b70}' # Microsoft.Windows.Print.XpsPrint
	'{744372de-ba26-443b-ba10-712c1a041234}' # Microsoft.Windows.Print.Workflow.API
	'{7cdc2341-4d44-54aa-2899-ddb05ecf0adb}' # Microsoft.Windows.Print.McpManagement
	'{7e247d3c-42fa-5e08-6427-f98478081d24}' # Microsoft.Windows.Print.GetPrinterConfig
	'{7e2dbfc7-41e8-4987-bca7-76cadfad765f}' # FDWSD
	'{7faee4d5-95c1-5987-54c6-a7c3dfb6e56e}' # Microsoft.Windows.Print.PrintSupport
	'{81d45b93-a5ff-5459-26ff-c092864200c6}' # Microsoft.Windows.Print.WinspoolCore
	'{8bbe74b4-d9fc-4052-905e-92d01579e3f1}' # DAFBTH
	'{8BFE6B98-510E-478D-B868-142CD4DEDC1A}' # indows.Internal.Shell.ModalExperience
	'{93603fbe-a752-550d-b87e-f202b0f27f9e}' # Microsoft.Windows.Scan.EsclWiaDriver
	'{9594011E-FE68-4D05-9F06-C68A0EBE4822}' # Microsoft.Windows.Print.GetIppAttributes
	'{97ff6b54-144c-524b-5fec-82b610461390}' # Microsoft.Windows.Mobile.Shell.ServiceProvider
	'{9C6FC32A-E17A-11DF-B1C4-4EBADFD72085}' # PLMWPP
	'{a08e69ca-2172-5c18-fe96-a2ac30857b97}' # Microsoft.Windows.Print.IppOneCore
	'{A1607A05-8D8A-4d74-82C7-460DD790648E}' # FindNetPrinters
	'{a4f32eea-babb-59b2-3828-ce92e4e20765}' # Microsoft.Windows.PrintCore
	'{ab4d9355-341e-435d-b3d2-4b0e46354e2c}' # Microsoft.Windows.Das
	'{ac521649-5ec6-5397-d1c5-749cbf5ea79b}' # Microsoft.Windows.Print.RenderFilterCommon
	'{acf1e4a7-9241-4fbf-9555-c27638434f8d}' # Microsoft.Windows.Print.IppCommon
	'{afa85d6c-0ea6-4c6a-99b7-5be1c9f3c7a1}' # BTHUSER
	'{b0f40491-9ea6-5fd5-ccb1-0ec63be8b674}' # Microsoft.Windows.Shell.PrintDialog
	'{b145b5c6-1a9d-50c5-7f76-39f208ed09c9}' # Microsoft.Windows.Print.McpEvtSrc
	'{B4D2914C-FF23-403B-BABF-F0755FB060FE}' # Microsoft.Windows.Print.SpoolerService
	'{B6BFCC79-A3AF-4089-8D4D-0EECB1B80779}' # Microsoft-Windows-SystemEventsBroker
	'{BA4936A1-31DB-4EDC-89CE-9190E3C0653B}' # Microsoft.Windows.Print.LocalSpooler
	'{bad46242-e75f-541f-c2d2-ab35489f27e4}' # Microsoft.Windows.Print.GDI
	'{BC2DAB59-AC78-487A-903E-DB3C343C0BE3}' # Microsoft.Windows.Print.WSDMon
	'{be5f8487-3a5d-4477-b0c2-020679b81e56}' # Microsoft.Windows.Print.Workflow.Source
	'{bf3eac2a-65ca-5ecc-2076-e23c6420a687}' # Microsoft.Windows.Print.DAFMCP
	'{C69CB70A-3133-4CCA-AB0E-046848EFFCDA}' # Microsoft.Windows.Print.Winspool
	'{c6dba857-03f1-5c5b-350c-ef08dbd04572}' # Microsoft.Windows.Shell.PrintManager
	'{c7c2a97e-3d49-5f78-bd33-22d8c22a7cf3}' # Microsoft.Windows.Scan.EsclWiaCore
	'{CA478AB1-8B38-451D-90E4-8534EB50B9D3}' # XPSPRINT
	'{cae6f32b-2553-5c24-f999-e63dde138b9f}' # Microsoft.Windows.Print.WorkFlowRT
	'{cb730350-b8b7-56d7-6fa4-90e0ea74a9bb}' # Microsoft.Windows.Print.PrintScanService
	'{D2E1BAB1-EB9B-4BA7-9123-19C01DDC4F78}' # LOCALSPLPLM
	'{D2E1BAB2-EB9B-4BA7-9123-19C01DDC4F78}' # SPOOLERPLM
	'{d49918cf-9489-4bf1-9d7b-014d864cf71f}' # Microsoft-Windows-ProcessStateManager
	'{d758d01c-7402-5923-6a27-44bdcc59a5c5}' # Microsoft.Windows.Print.ApMonPortMig
	'{dd212385-31e6-541c-5587-3c469bb6470a}' # Microsoft.Windows.Print.DafIppUsb
	'{DDF2CC14-A470-4449-AB03-F8B95FC8294B}' # Microsoft.Windows.Print.XpsPrint
	'{df6dca70-9918-455f-86fe-983adc74fa0d}' # Microsoft.Windows.Scan.Runtime
	'{e0d2f15a-3875-5388-2239-23f2538b7636}' # Microsoft.Windows.Print.PrintScanDiscoveryManagement
	'{e4d412ab-4c22-49ef-83ca-eafb90768512}' # Microsoft-Windows-WSD-DafProvider
	'{e604ec58-ad08-5a2c-3ecb-704c8c024881}' # Microsoft.Windows.Print.ProxyApp
	'{E6F8A5FC-7FCE-4095-8661-B8E0CB7D9410}' # ScanRT/DeviceEnumeration WPP
	'{e73d49d6-9eda-5059-74d1-b879b18cf9ae}' # Microsoft.Windows.Print.APMon
	'{e8109b99-3a2c-4961-aa83-d1a7a148ada8}' # SEBWPP
	'{e98cb748-3d93-4719-8209-95e0bc46eec7}' # Microsoft.Windows.Print.PwgRenderFilter
	'{eb3b6950-120c-4575-af39-2f713248e8a3}' # BTHPRINT
	'{EC08D605-5A20-4ED0-AE54-E8C4BFFF2EEB}' # PrinterExtensions
	'{ec5b420f-d2ec-50b4-5119-083a4da63982}' # Microsoft.Windows.Print.Ecp.Service
	'{ee8c758e-2e70-574f-8149-266b77c8d56a}' # Microsoft.Windows.Print.McpIppChannel
	'{f25e0650-deff-5306-ca0d-40abb8b107dd}' # Microsoft.Windows.Scan.DafEscl
	'{F69D3E6C-298B-466C-B84F-486E1F21E347}' # Microsoft.Windows.Print.WorkFlowBroker
	'{fbfbd628-251d-551d-c4dd-c7820af723e4}' # Microsoft.Windows.Print.IppAdapterCommon
	'{FCA72EBA-CBB3-467c-93BC-1DB4978C398D}' # MXDC
	'{fd6b6ae4-7563-550d-46a4-da9fe46cad57}' # Microsoft-Windows-Print-Platform
	'{fdcab703-6402-4959-b618-f5c3c279ef3d}' # Microsoft.Windows.Print.PrintConfig
	# Original UEX_Print
	'{C9BF4A01-D547-4D11-8242-E03A18B5BE01}' # LOCALSPL
	'{C9BF4A02-D547-4D11-8242-E03A18B5BE01}' # WINSPOOL
	'{C9BF4A03-D547-4D11-8242-E03A18B5BE01}' # WIN32SPL
	'{C9BF4A04-D547-4D11-8242-E03A18B5BE01}' # BIDISPL
	'{C9BF4A05-D547-4D11-8242-E03A18B5BE01}' # SPLWOW64
	'{C9BF4A06-D547-4D11-8242-E03A18B5BE01}' # SPLLIB
	'{C9BF4A07-D547-4D11-8242-E03A18B5BE01}' # PERFLIB
	'{C9BF4A08-D547-4D11-8242-E03A18B5BE01}' # ASYNCNTFY
	'{C9BF4A09-D547-4D11-8242-E03A18B5BE01}' # REMNTFY
	'{C9BF4A0A-D547-4D11-8242-E03A18B5BE01}' # GPPRNEXT
	'{C9BF4A0B-D547-4D11-8242-E03A18B5BE01}' # SANDBOX
	'{C9BF4A0C-D547-4D11-8242-E03A18B5BE01}' # SANDBOXHOST
	'{C9BF4A0D-D547-4d11-8242-E03A18B5BE01}' # MSW3PRT
	'{C9BF4A9E-D547-4D11-8242-E03A18B5BE01}' # SPOOLSV
	'{C9BF4A9F-D547-4D11-8242-E03A18B5BE01}' # SPOOLSS
	'{09737B09-A25E-44D8-AA75-07F7572458E2}' # PRNNTFY
	'{301CCC25-D58B-4C5E-B6A5-15BCF8B0077F}' # INETPPUI
	'{34F7D4F8-CD95-4B06-8BF6-D929DE4AD9DE}' # PRNCACHE
	'{528F557E-A4D4-4063-A17A-9F45FAF8C042}' # HGPRINT
	'{3EA31F33-8F51-481D-AEB7-4CA37AB12E48}' # LPDSVC
    '{9F44821F-1FD9-46BF-A09A-C7F751159AAF}' # Microsoft-Windows-Spooler-LPDSVC
	'{62A0EB6C-3E3E-471D-960C-7C574A72534C}' # TCPMon
	'{6D1E0446-6C52-4B85-840D-D2CB10AF5C63}' # WSDPrPxy
	'{836767A6-AF31-4938-B4C0-EF86749A9AEF}' # WSDMON
	'{9558985E-3BC8-45EF-A2FD-2E6FF06FB886}' # WSDPRINT
	'{9677DFEF-EACF-4173-8977-FFB0086B11E6}' # BridgeGuid
	'{99F5F45C-FD1E-439F-A910-20D0DC759D28}' # USBMon
	'{9E6D0D9B-1CE5-44B5-8B98-F32ED89077EC}' # LPRHelp
	'{A83C80B9-AE01-4981-91C6-94F00C0BB8AA}' # printui
	'{AAED978E-5B0C-4F71-B35C-16E9C0794FF9}' # CommonGuid
	'{B42BD277-C2BA-468B-AB3D-05B1A1714BA3}' # PRINTLIB
	'{B795C7DF-07BC-4362-938E-E8ABD81A9A01}' # NTPRINT
	'{C9BF4A9E-D547-4D11-8242-E03A18B5BEEE}' # INETPP
	'{CE444D6A-F287-4977-BBBD-89A0DD65B71D}' # CDIGuid
	'{D34AE79A-15FB-44F9-9FD8-3098E6FFFD49}' # D34AE79A
	'{EB4C6075-0B67-4A79-A0A3-7CD9DF881194}' # XpsRasFilter
	'{EE7E960D-5E42-4C28-8F61-D8FA8B0DD84D}' # ServerGuid
	'{F30FAB8E-84BB-48D4-8E80-F8967EF0FE6A}' # LPRMon
	'{F4DF4FA4-66C2-4C14-ABB1-19D099D7E213}' # COMPONENTGuid
	'{883DFB21-94EE-4C9B-9922-D5C42B552E09}' # PRNFLDR
	'{3048407B-56AA-4D41-82B2-7D5F4B1CDD39}' # DAFPRINT
	'{2F6A026F-D4C4-41B8-A59E-2EC834419B67}' # PUIOBJ
	'{79B3B0B7-F082-4CEC-91BC-5E4B9CC3033A}' # FDPRINT
	'{CAC16EB2-12D0-46B8-B484-F179C900772B}' # PMCSNAP
	'{0DC96237-BBD4-4BC9-8184-46DF83B1F1F0}' # DOXXPS
	'{0675CF90-F2B8-11DB-BB42-0013729B82C4}' # DOXPKG
	'{986DE178-EA3F-4E27-BBEE-34E0F61535DD}' # XpsRchVw
	'{64F02056-AFD9-42D9-B221-6C94733B09B1}' # XpsIFilter
	'{2BEADE0B-84CD-44A5-90A7-5B6FB2FF83C8}' # XpsShellExt
	'{AAACB431-6067-4A42-8883-3C01526DD43A}' # XpsRender
	'{12DC38E3-E395-4C8E-9156-B5642057F5FA}' # Microsoft-Windows-PrintDialogs3D
	'{27E76321-1E5B-4A82-BA0C-26E978F15072}' # Microsoft-Windows-PrintDialogs
	'{747EF6FD-E535-4D16-B510-42C90F6873A1}' # Microsoft-Windows-PrintService
	'{7F812073-B28D-4AFC-9CED-B8010F914EF6}' # Microsoft-Windows-PrintService-USBMon
	'{952773BF-C2B7-49BC-88F4-920744B82C43}' # Microsoft-Windows-TerminalServices-Printers
	'{0ED38D2B-4ACC-4E23-A8EC-D0DACBC34637}' # tsprint
	'{9B4A618C-07B8-4182-BA5A-5B1943A92EA1}' # MSXpsFilters
	'{A6D25EF4-A3B3-4E5F-A872-24E71103FBDC}' # MicrosoftRenderFilter
	'{AEFE45F4-8548-42B4-B1C8-25673B07AD8B}' # PrintFilterPipelinesvc
	'{BE967569-E3C8-425B-AD0E-4F2C790B1848}' # Microsoft-Windows-Graphics-Printing3D
	'{CF3F502E-B40D-4071-996F-00981EDF938E}' # Microsoft-Windows-PrintBRM
	'{E7AA32FB-77D0-477F-987D-7E83DF1B7ED0}' # Microsoft-Windows-Graphics-Printing
	'{7672778D-86FE-41D0-85C8-82CAA8CE6168}' # ESUPDATE(Maybe not used now)
	'{7663DA2F-1594-4C33-83DD-D5C64BBED68A}' # ObjectsGuid
	'{5ED940EB-18F9-4227-A454-8EF1CE5B3272}' # SetupLPR
	'{27239FD0-425E-11D8-9E39-000039252FD8}' # COMMONGuid
	'{04160794-60B6-4EC7-96FF-4953691F94AA}' # SetupIPP
	'{C59DA080-9CCE-4415-A77D-08457D7A059F}' # JScriptLib
	'{19E93940-A1BD-497F-BC58-CA333880BAB4}' # PrintExtension
	'{DD6A31CB-C9C6-4EF9-B738-F306C29352F4}' # MODERNPRINT
	'{3FB15E5D-DF1A-46FC-BEFE-27A4B82D75EE}' # PREFDLG
	'{02EA8EB9-9811-46d6-AEEE-430ADCC2AA18}' # DLGHOST
	'{D3A10B55-1EAD-453d-8FC7-35DA3D6A04D2}' # TCPMIB
	'{B48AE058-218A-4338-9B97-9F5F9E4EB5D2}' # USBJSCRIPT
  
    # Function Discovery
    '{2A1B2634-D069-4A57-B465-EB75B413E495}' # SyncTraceGuid
    '{B0CF9782-1FDF-4E2E-B00D-B0437E36C9A2}' # RingtoneTraceGuid
    '{F7155847-D7FA-413A-809F-CFB02894905C}' # DevCtrTraceGuid
    '{4244C025-536E-4A36-9D92-5D67F3C1FF44}' # Microsoft.Windows.DSM.DeviceMetadataRetrievalClient
    '{888DC41F-CC0C-49F8-A2A5-7809F155F197}' # Microsoft.Windows.DSM.FdDDO
    '{9DB0FDB5-3B21-440E-A94B-63738A4BE5DE}' # Microsoft-Windows-FunctionDiscovery
    '{538CBBAD-4877-4EB2-B26E-7CAEE8F0F8CB}' # Microsoft-Windows-FunctionDiscoveryHost

    ### Extra from Print-Collect
    '{1B42986F-288F-4DD7-B7F9-120297715C1E}'    # DeviceEnumeration WPP
    '{12DFC189-A85B-4B19-847B-D9AC6B716DB8}'    # PrintBRM (BRMENGINE) WPP
    '{ffdb1efb-602c-5725-c85c-f3f1a065d72a}'    # Microsoft.Windows.Print.DriverUI
    '{4c7e30ea-beaf-5b10-ae30-451fb529c653}'    # Microsoft.Windows.Print.DeviceCenter
    '{FD6EC121-DC51-42FD-A559-BA984D345E2B}'    # Microsoft.Windows.Print.PrintDeviceCapabilities
    #'{072665fb-8953-5a85-931d-d06aeab3d109}'    # Microsoft-Windows-LifetimeManager - commented out in PrintTrace.cmd
    '{40dd7897-9206-5dc5-d21b-2de290ca181a}'    # Microsoft.Windows.Print.WsdAdapter
    '{e9e3a474-c716-56f4-f6f2-5d5f181c46ab}'    # Microsoft.Windows.Print.IppCommonDll
    '{7617c8d5-b61c-5f45-dd42-02c19bd5f387}'    # Microsoft.Windows.Print.TiffRenderFilter
    '{99d90395-1bb0-5932-720a-21d1be94eba3}'    # Microsoft.Windows.Print.Usbprint
    '{0e46cee6-dd9a-5b24-67c6-be3a88c3f894}'    # Microsoft.Windows.Print.McpLppHelper
    '{c5488b38-f338-51d9-1046-be7b050f3198}'    # Microsoft.Windows.Print.GpdParser
    '{24a149d9-e7af-59b9-10c7-b2115913ea92}'    # Microsoft.Windows.Print.UniLib
    '{8325bcbd-4d99-5255-0722-d4387890d3c3}'    # Microsoft.Windows.Print.PrvSpoolss
    '{5000d5f2-f6c7-59e0-eda8-c5126f0eefcd}'    # Microsoft.Windows.Print.CSPs.UPPrinterInstalls
    '{5fef3144-ec00-5072-ee6b-5d0a02bb656c}'    # Microsoft.Windows.Print.DeviceControl
    '{0a82e916-4637-4998-83bf-8b0f4792a7c9}'    # Microsoft.Windows.Print.XGC
    '{d43cc295-539f-5e64-77ce-78ef0e51825c}'    # Microsoft.Windows.Print.DeviceConfiguration
    '{8288e29d-0fc0-56b8-03ed-7fa253155f20}'    # Microsoft.Windows.Print.PrinterAssociationCommon
    '{ee6271a2-f93c-566a-b4a1-4eacdbce3ad3}'    # Microsoft.Windows.Print.PrintUtil
)
#endregion--- PRINT PROVIDERS ---#


#region--- RDS PROVIDERS ---#
$UEX_RDSProviders = @( # new version, to be removed after autologger clarified
	'{5A966D1C-6B48-11DA-8BDE-F66BAD1E3F3A}' 		# Rdp Sound End Point Trace
	'{e27950eb-1768-451f-96ac-cc4e14f6d3d0}' 		# AudioSrv/Ses (RDP Audio)
	'{E80ADCF1-C790-4108-8BB9-8A5CA3466C04}' 		# Microsoft-Windows-TerminalServices-RDP-AvcSoftwareDecoder(From WS2019)
	'{3f7b2f99-b863-4045-ad05-f6afb62e7af1}' 		# Microsoft-Windows-TerminalServices-MediaRedirection(tsmf.dll)
	'{b1c94ed9-ac9b-410e-aa48-4ffc5e45f4e3}' 		# Microsoft-Windows-TerminalServices-MediaRedirection-DShow(DShowRdpFilter.dll) (WS2008R2)
	'{6165F3E2-AE38-45D4-9B23-6B4818758BD9}' 		# CredSSP (tspkg)
	'{60A7AB7A-BC57-43E9-B78A-A1D516577AE3}' 		# KerbComm
	'{FACB33C4-4513-4C38-AD1E-57C1F6828FC0}' 		# KerbClientSharedTraceControlGuid
	'{97A38277-13C0-4394-A0B2-2A70B465D64F}' 		# Microsoft-Windows-KPSSVC-WPP
	'{52BF9EC6-69F5-49E6-9ECC-D3B994C40142}' 		# CapiProvider (certificates)
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' 		# Kerberos
	'{5AF52B0D-E633-4EAD-828A-4B85B8DAAC2B}' 		# NegoExts
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}' 		# msv1/NTLM
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}' 		# LsaSrv
	'{37D2C3CD-C5D4-4587-8531-4696C44244C8}' 		# Schannel-WPP
	'{FB1A70CC-BE28-40C1-BD6A-47671538383A}' 		# Microsoft.Windows.RemoteDesktop.CertManager(From WS2019)
	'{5BBCA4A8-B209-48DC-A8C7-B23D3E5216FB}' 		# Microsoft-Windows-CAPI2
	'{98E6CFCB-EE0A-41E0-A57B-622D4E1B30B1}' 		# Microsoft-Windows-Security-Kerberos
	'{AC43300D-5FCC-4800-8E99-1BD3F85F0320}' 		# Microsoft-Windows-NTLM
	'{91CC1150-71AA-47E2-AE18-C96E61736B6F}' 		# Schannel
	'{1f678132-5938-4686-9fdc-c8ff68f15c85}' 		# Schannel-2K8
	'{02F3A5E3-E742-4720-85A5-F64C4184E511}' 		# Microsoft-Windows-Hyper-V-Config
	'{51DDFA29-D5C8-4803-BE4B-2ECB715570FE}' 		# Microsoft-Windows-Hyper-V-Worker
	'{6066F867-7CA1-4418-85FD-36E3F9C0600C}' 		# Microsoft-Windows-Hyper-V-VMMS
	'{FDFF33EC-70AA-46D3-BA65-7210009FA2A7}' 		# Microsoft-Windows-Hyper-V-Integration-RDV
	'{09242393-1349-4F4D-9FD7-59CC79F553CE}' 		# Microsoft-Windows-Hyper-V-EmulatedNic
	'{0B9FDCCC-451C-449C-9BD8-6756FCC6091A}' 		# Microsoft-Windows-Hyper-V-Guest-Drivers-Storage-Filter
	'{10B3D268-9782-49A4-AACC-A93C5482CB6F}' 		# Microsoft-Windows-Hyper-V-StorageVSP
	'{13EAE551-76CA-4DDC-B974-D3A0F8D44A03}' 		# Microsoft-Windows-Hyper-V-Tpm
	'{152FBE4B-C7AD-4F68-BADA-A4FCC1464F6C}' 		# Microsoft-Windows-Hyper-V-Netvsc
	'{17103E3F-3C6E-4677-BB17-3B267EB5BE57}' 		# Microsoft-Windows-Hyper-V-Compute
	'{177D1599-9764-4E3A-BF9A-C86887AADDCE}' 		# Microsoft-Windows-Hyper-V-VmbusVdev
	'{1CEB22B1-97FF-4703-BEB2-333EB89B522A}' 		# Microsoft-Windows-Hyper-V-VMSP
	'{2B74A015-3873-4C56-9928-EA80C58B2787}' 		# Microsoft-Windows-Hyper-V-Integration
	'{339AAD0A-4124-4968-8147-4CBBB1F8B3D5}' 		# Microsoft-Windows-Hyper-V-UiDevices
	'{52FC89F8-995E-434C-A91E-199986449890}' 		# Microsoft-Windows-Hyper-V-Hypervisor
	'{5931D877-4860-4EE7-A95C-610A5F0D1407}' 		# Microsoft-Windows-Hyper-V-VID
	'{5B621A17-3B58-4D03-94F0-314F4E9C79AE}' 		# Microsoft-Windows-Hyper-V-SynthFcVdev
	'{67DC0D66-3695-47C0-9642-33F76F7BD7AD}' 		# Microsoft-Windows-Hyper-V-VmSwitch
	'{7B0EA079-E3BC-424A-B2F0-E3D8478D204B}' 		# Microsoft-Windows-Hyper-V-VSmb
	'{86E15E01-EDF1-4AC7-89CF-B19563FD6894}' 		# Microsoft-Windows-Hyper-V-EmulatedStor
	'{8F9DF503-1D12-49EC-BB28-F6EC42D361D4}' 		# Microsoft-Windows-Hyper-V-Serial
	'{9F2660EA-CFE7-428F-9850-AECA612619B0}' 		# Microsoft-Windows-Hyper-V-VfpExt
	'{AE3F5BF8-AB9F-56D6-29C8-8C312E2FAEC2}' 		# Microsoft-Windows-Hyper-V-Virtual-PMEM
	'{AF7FD3A7-B248-460C-A9F5-FEC39EF8468C}' 		# Microsoft-Windows-Hyper-V-ComputeLib
	'{B1D080A6-F3A5-42F6-B6F1-B9FD86C088DA}' 		# Microsoft-Windows-Hyper-V-DynMem
	'{BA2FFB5C-E20A-4FB9-91B4-45F61B4B66A0}' 		# Microsoft-Windows-Hyper-V-Guest-Drivers-Dynamic-Memory
	'{C18672D1-DC18-4DFD-91E4-170CF37160CF}' 		# Microsoft-Windows-Hyper-V-Guest-Drivers-IcSvc
	'{C29C4FB7-B60E-4FFF-9AF9-CF21F9B09A34}' 		# Microsoft-Windows-Hyper-V-SynthNic
	'{C7C9E4F7-C41D-5C68-F104-D72A920016C7}' 		# Microsoft-Windows-Hyper-V-CrashDump
	'{DA5A028B-B248-4A75-B60A-024FE6457484}' 		# Microsoft-Windows-Hyper-V-EmulatedDevices
	'{DE9BA731-7F33-4F44-98C9-6CAC856B9F83}' 		# Microsoft-Windows-Hyper-V-Chipset
	'{EDACD782-2564-4497-ADE6-7199377850F2}' 		# Microsoft-Windows-Hyper-V-SynthStor
	'{EDED5085-79D0-4E31-9B4E-4299B78CBEEB}' 		# Microsoft-Windows-Hyper-V-Debug
	'{F2E2CE31-0E8A-4E46-A03B-2E0FE97E93C2}' 		# Microsoft-Windows-Hyper-V-Guest-Drivers-Vmbus
	'{301779E2-227D-4FAF-AD44-664501302D03}'		# Winlogon Notify (WlClNtfy)
	'{D451642C-63A6-11D7-9720-00B0D03E0347}' 		# Winlogon Core
	'{d9391d66-ee23-4568-b3fe-876580b31530}' 		# Winlogon StateMachine
	'{A789EFEB-FC8A-4C55-8301-C2D443B933C0}'		# Security (UmsHlpr)
	'{19D78D7D-476C-47B6-A484-285D1290A1F3}' 		# Winlogon Notify (SysNtfy)
	'{C2BA06E2-F7CE-44AA-9E7E-62652CDEFE97}' 		# WinInit
	'{d138f9a7-0013-46a6-adcc-a3ce6c46525f}'		# WMsgSrv
	'{EB7428F5-AB1F-4322-A4CC-1F1A9B2C5E98}' 		# Profile Service
	'{2AC96968-C174-4cd5-A2E5-D86495DDB4F2}' 		# Profile Trace
	'{2955E23C-4E0B-45CA-A181-6EE442CA1FC0}' 		# Auth UI
	'{D1D7D72D-00D5-4E56-8BAC-23FAC0F9ED4E}' 		# Auth UI-IC
	'{CEC2553A-8961-4D34-92CA-AB2ECEF646C5}' 		# Auth UI-ImgVal
	'{012616AB-FF6D-4503-A6F0-EFFD0523ACE6}' 		# Auth UI-CredAPI
	'{A323CDC2-81B0-48B2-80C8-B749A221478A}' 		# Auth UI-HG
	'{169CC90F-317A-4CFB-AF1C-25DB0B0BBE35}' 		# Auth UI
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' 		# Kerberos Client
	'{5B4F9E61-4334-409F-B8F8-73C94A2DBA41}' 		# Userinit
	'{6b6c257f-5643-43e8-8e5a-c66343dbc650}' 		# UserProfileService.dll
	'{6035d7f9-6e24-44bf-b540-3ade030d001a}' 		# winsrvext.dll
	'{3ec987dd-90e6-5877-ccb7-f27cdf6a976b}' 		# Microsoft.Windows.LogonUI.WinlogonRPC
	'{c0ac3923-5cb1-5e37-ef8f-ce84d60f1c74}' 		# Microsoft.Windows.TSSessionUX
	'{89B1E9F0-5AFF-44A6-9B44-0A07A7CE5845}' 		# Microsoft-Windows-User Profiles Service
	'{DB00DFB6-29F9-4A9C-9B3B-1F4F9E7D9770}' 		# Microsoft-Windows-User Profiles General
	'{DBE9B383-7CF3-4331-91CC-A3CB16A3B538}' 		# Microsoft-Windows-Winlogon
	'{AEA1B4FA-97D1-45F2-A64C-4D69FFFD92C9}' 		# Microsoft-Windows-GroupPolicy
	'{63D2BB1D-E39A-41B8-9A3D-52DD06677588}' 		# Microsoft-Windows-Shell-AuthUI
	'{FCA72EBA-CBB3-467C-93BC-1DB4978C398D}'  		# XPS Document Writer for EasyPrint (MXDWDRV)
	'{C9BF4A08-D547-4D11-8242-E03A18B5BE01}' 		# ASYNCNTFY
	'{C9BF4A01-D547-4D11-8242-E03A18B5BE01}' 		# LOCALSPL
	'{C9BF4A06-D547-4D11-8242-E03A18B5BE01}' 		# SPLLIB
	'{C9BF4A04-D547-4D11-8242-E03A18B5BE01}' 		# BIDISPL
	'{C9BF4A02-D547-4D11-8242-E03A18B5BE01}' 		# WINSPOOL
	'{C9BF4A03-D547-4D11-8242-E03A18B5BE01}' 		# WIN32SPL
	'{C9BF4A9F-D547-4D11-8242-E03A18B5BE01}' 		# SPOOLSS
	'{C9BF4A9E-D547-4D11-8242-E03A18B5BE01}' 		# SPOOLSV
	'{C9BF4A05-D547-4D11-8242-E03A18B5BE01}' 		# SPLWOW64
	'{747EF6FD-E535-4D16-B510-42C90F6873A1}' 		# Microsoft-Windows-PrintService
	'{EE7E960D-5E42-4C28-8F61-D8FA8B0DD84D}' 		# ProviderGuid / ServerGuid
	'{CE444D6A-F287-4977-BBBD-89A0DD65B71D}' 		# CDIGuid
	'{D34AE79A-15FB-44F9-9FD8-3098E6FFFD49}' 		# CASGuid
	'{27239FD0-425E-11D8-9E39-000039252FD8}' 		# COMMONGuid
	'{F4DF4FA4-66C2-4C14-ABB1-19D099D7E213}' 		# COMPONENTGuid
	'{7663DA2F-1594-4C33-83DD-D5C64BBED68A}' 		# ObjectsGuid
	'{AAED978E-5B0C-4F71-B35C-16E9C0794FF9}' 		# CommonGuid
	'{9677DFEF-EACF-4173-8977-FFB0086B11E6}' 		# BridgeGuid
	'{CF3F502E-B40D-4071-996F-00981EDF938E}' 	  	# Microsoft-Windows-PrintBRM
	'{301CCC25-D58B-4C5E-B6A5-15BCF8B0077F}' 		# INETPPUI
	'{C9BF4A9E-D547-4D11-8242-E03A18B5BEEE}' 		# INETPP
	'{04160794-60B6-4EC7-96FF-4953691F94AA}' 		# SetupIPP
	'{3EA31F33-8F51-481D-AEB7-4CA37AB12E48}' 		# LPDSVC
	'{9F44821F-1FD9-46BF-A09A-C7F751159AAF}' 		# Microsoft-Windows-Spooler-LPDSVC
	'{9E6D0D9B-1CE5-44B5-8B98-F32ED89077EC}' 		# LPRHelp
	'{F30FAB8E-84BB-48D4-8E80-F8967EF0FE6A}' 		# LPRMon
	'{DC82DA8E-2290-449D-9062-21EF70D36E22}' 		# Microsoft-Windows-Spooler-LPRMON
	'{5ED940EB-18F9-4227-A454-8EF1CE5B3272}' 		# SetupLPR
	'{99F5F45C-FD1E-439F-A910-20D0DC759D28}' 		# USBMon
	'{CAD2D809-03D9-4F46-9CF4-72AA4F04B6B9}' 		# Microsoft-Windows-SpoolerTCPMon
	'{62A0EB6C-3E3E-471D-960C-7C574A72534C}' 		# TCPMon
	'{9558985E-3BC8-45EF-A2FD-2E6FF06FB886}' 		# WSDPRINT
	'{836767A6-AF31-4938-B4C0-EF86749A9AEF}' 		# WSDMON
	'{7672778D-86FE-41D0-85C8-82CAA8CE6168}' 		# SetupWSD
	'{6D1E0446-6C52-4B85-840D-D2CB10AF5C63}' 		# WSDPrPxy
	'{B795C7DF-07BC-4362-938E-E8ABD81A9A01}' 		# NTPRINT
	'{09737B09-A25E-44D8-AA75-07F7572458E2}' 		# PRNNTFY
	'{34F7D4F8-CD95-4B06-8BF6-D929DE4AD9DE}' 		# PRNCACHE
	'{B42BD277-C2BA-468B-AB3D-05B1A1714BA3}' 		# PRINTLIB
	'{A83C80B9-AE01-4981-91C6-94F00C0BB8AA}' 		# printui
	'{EB4C6075-0B67-4A79-A0A3-7CD9DF881194}' 		# XpsRasFilter
	'{0ed38d2b-4acc-4e23-a8ec-d0dacbc34637}' 		# RD Printing (tsprint)
	'{747EF6FD-E535-4D16-B510-42C90F6873A1}' 		# Microsoft-Windows-PrintService
	'{C127C1A8-6CEB-11DA-8BDE-F66BAD1E3F3A}' 		# RemoteApp Shell (RAIL RdpInit)
	'{BFA655DC-6C51-11DA-8BDE-F66BAD1E3F3A}' 		# RemoteApp Shell (RAIL RdpShell)
	'{39825FFA-F1B4-41B7-8221-20D4B8DBE57E}' 		# RemoteApp Shell (RAIL RdpShell)
	'{43471865-f3ee-5dcf-bf8b-193fcbbe0f37}' 		# RAIL XPlat (RAIL RdpShell)
	'{73C5EC49-C807-489D-9E45-D36D72235F84}' 		# User Mode Port Redirector (UMRDP)
	'{82A94E1C-C1B3-4E4A-AC87-43BD802E458E}' 		# Device redirection (KDynVC)
	'{73BFB78F-12B5-4738-A66C-A77BCD55FA12}' 		# R2 RDPDR
	'{600be610-f0e8-4912-b397-d2cc76060114}' 		# USB Redirection
	'{BFA655DC-6C51-11DA-8BDE-F66BAD1E3F30}' 		# rdpshell.exe (rdprail\rdpshell\clouddvs\objfre\amd64)
	'{4A49AFE3-776E-467A-ACA0-71F9C6C8499F}' 		# Microsoft.Windows.RemoteDesktop.RAIL.RdpInit
	'{DC1A94A6-0A1A-433E-B470-3C72353B7309}' 		# Microsoft.Windows.RemoteDesktop.RAIL.Server.Diagnostics(From RS5)
	'{C10870A3-617D-42E9-80C7-1C4BE2709E06}' 		# VmPluginTrace
	'{3C3E7089-99CF-4446-8D81-4AC5A8560E6A}' 		# SessionBrokerTrace
	'{FA801570-83A9-11DF-B3A9-8C26DFD72085}' 	  	# RdCentralDbPlugin
	'{C29D637F-AFB5-43F9-96F8-936429371F32}' 		# RdvVmCore
	'{D1737620-6A25-4BEF-B07B-AAC3DF44EFC9}' 		# Microsoft-Windows-TerminalServices-SessionBroker
	'{77B0D57B-97B8-4F42-83B0-4FDA12D3D79A}' 		# Microsoft-Windows-RemoteApp and Desktop Connection Management
	'{7ADA0B31-F4C2-43F4-9566-2EBDD3A6B604}' 		# TSCPUBSvr.dll
	'{BF936B9C-DA45-4494-A236-101FE5A2A51D}'		# tspubfilter.dll
	'{81B84BCE-06B4-40AE-9840-8F04DD7A8DF7}' 		# TSCPubWmiProvider
	'{1FD4C5A9-27B7-418B-8DFC-216E7FA7B990}' 		# tscpubStub.dll
	'{0CEA2AEE-1A4C-4DE7-B11F-161F3BE94669}' 		# TSPublishingIconHelperTrace
	'{E43CAB68-0AB4-4F47-BF30-E61CAC7BBD8A}' 		# TSPublishingWmiProvider
	'{D33E545F-59C3-423F-9051-6DC4983393A8}' 		# Winsta Client (API)
	'{0046a6b4-a24c-40d5-b0e6-c8ec031bd82a}' 		# TS RPC
	'{DAA6CAF5-6678-43F8-A6FE-B40EE096E06E}' 		# RD Client Core Trace (MSTSCAX)
	'{0C51B20C-F755-48A8-8123-BF6DA2ADC727}' 		# RD Client Shell Trace (MSTSC)
	'{936FF90C-7CC4-40d8-8A04-77B281C73AB9}' 		# RD Client Gateway QEC
	'{70DB53D8-B6F3-428D-AA33-5B2CE56718C5}' 		# RD Client Gateway Core
	'{fac7fcce-62fc-4be0-bd67-311750b5bcff}' 		# RD Client Print (XPSClientPlgin)
	'{D4197645-41DE-4ad5-9D71-A612C508FDD8}' 		# rdpxclient
	'{ea605ac7-d9de-434a-8271-682fee6d59ca}' 		# RemoteFX Codec
	'{080656C2-C24F-4660-8F5A-CE83656B0E7C}' 		# ClientCore
	'{7211AE02-1EB0-454A-88FA-EA16632DCB45}' 		# TS USB Filter
	'{8C74CED2-9899-4E01-A6D2-F924045DE932}' 		# rendrdp.dll
	'{cbdedbe0-b5c2-4ff6-905b-7a5ec0ebf8ed}' 		# radcui.dll
	'{C3B02229-FF93-4D28-ACFC-4FB28AC6CDB5}' 		# rdclientwinrt.dll
	'{91A2900E-DB4C-41E9-A6D8-945F40451BB3}' 		# RdClient.Windows.exe
	'{76de1e7b-74d9-585f-1f85-affa9242808c}' 		# RDWin32ClientAxTelemetryProvider
	'{61dd194a-b8cb-4de5-a018-4c7f6f9e9988}' 		# RDP.MSTSCTelemetry
	'{76de1e7b-74d5-575e-1f81-4ffe6a42777b}' 		# RDWin32ClientAxTelemetryProvider
	'{7756e5a6-21b2-4c40-855e-88cf2b13c7cb}' 		# RDP.MSTSCAXTelemetry
	'{660cfa71-2a70-4e80-bdf3-f1424919d01c}' 		# Microsoft.RDS.RdClient.Client.FeedSubscription
	'{55184039-1cbe-4d35-9f9e-85d0075943df}' 		# Microsoft.RDS.RADC.FeedSubscription
	'{48EF6C18-022B-4394-BEE5-7B822B42AE4C}' 		# Microsoft.RDS.Windows.Client.MSRDC
	'{335934AA-6DD9-486C-88A5-F8D6A7D2BAEF}' 		# Microsoft.RDS.Windows.Client.AX
	'{5F328364-2E3D-4F73-B099-0D5C839E32A0}' 		# CredentialsPlugin
	'{28AA95BB-D444-4719-A36F-40462168127E}' 		# Microsoft-Windows-TerminalServices-ClientActiveXCore
	'{1B8B402D-78DC-46FB-BF71-46E64AEDF165}' 		# Microsoft-Windows-RemoteApp and Desktop Connections
	'{6E400999-5B82-475F-B800-CEF6FE361539}' 		# Microsoft-Windows-TerminalServices-ClientUSBDevices
	'{6F539394-F34F-45FD-B4CA-BD5C547B0BCB}' 		# AaEdgeServiceTrace
	'{909ED641-D5EF-4299-B898-F13451A59F50}' 		# AaTsPPTrace
	'{EB4AC9D0-AE00-4963-8435-5163ABD35572}' 		# Microsoft.Windows.RemoteDesktop.Gateway
	'{4D5AE6A1-C7C8-4E6D-B840-4D8080B42E1B}' 		# Microsoft-Windows-TerminalServices-Gateway
	'{1B9B72FC-678A-41C1-9365-824658F887E9}' 		# RDMS (RD Managment Service)
	'{9F58B00C-09C7-4cbc-8D19-969DCD5D5A6D}' 		# MMC Snapin
	'{05da6b40-219e-4f17-92e6-d663fd87cba8}' 		# Microsoft-Windows-Remote-Desktop-Management-Service
	'{fb750ad9-8544-427f-b284-8ed9c6c221ae}' 		# Microsoft-Windows-Rdms-UI
	'{302383D5-5DC2-4BEA-AC7E-4154A1272583}'		# Microsoft.Windows.RemoteDesktop.MultiPoint
	'{A489F3D1-F149-4968-BDCE-4F7D93516DA8}'		# lserver
	'{A489F3D1-F149-4968-BDCE-4F7D93516DA9}'		# lserver
	'{da539211-d525-422a-8a92-bcbe4367159c}' 		# Microsoft.Windows.RemoteDesktop.RDSLSTelemetry
	'{F8FCF9E0-535A-4BA6-975F-7AC82FBDC631}' 		# TLSBrandTrace / TLSWmiTrace
	'{4D99F017-0EB1-4B52-8419-14AEBD13D770}' 		# Microsoft-Windows-TerminalServices-Licensing
	'{796F204A-44FC-47DF-8AE4-77C210BD5AF4}' 		# RDPCLIP
	'{D4199645-41BE-4FD5-9D73-A612C508FDC6}' 		# RdpCoreTS
	'{140C2428-F60D-43F9-9B07-3E5F622438A0}' 		# RdpCoreTS
	'{97e97a1e-c0a9-4b8d-87c4-42105a957d7b}' 		# RdsDWMDirect
	'{62F277AE-2CCF-4AA9-A8AA-32752200BC18}' 		# CtDwm
	'{5795AAB9-B0E3-419E-B0EF-7AEF943CFFA8}' 		# Microsoft.Windows.RemoteDesktop.Base
	'{8375996D-5801-4FE9-B0AE-F5C428758960}' 		# Microsoft.Windows.RemoteDesktop.ServerBase
	'{7b7a87d4-6d7c-4c87-8e3d-29f31bff02b8}' 		# Microsoft.Windows.Rdp.Graphics.RdpIdd
	'{D92BCB52-FA78-406F-A9A5-2037509FADEA}' 		# DxKernel Indirect Display: IddCx
	'{AFC8A033-E28A-415C-ACFF-030E4B113A35}' 		# Microsoft.Streaming.Basix
	'{3d491de6-531b-3b95-9404-e13c072c5a6c}' 		# TermSrv:ThreadPool
	'{3bf63c52-b1bd-3bd7-4dd0-af57fba7d43d}' 		# TermSrv:tscryptutils
	'{C5615DDA-2DAC-479B-83AB-F18C95601774}' 		# RdpInput (Replaces TermDD in 2012 R2)
	'{fb750ad9-8544-427f-b284-8ed9c6c221ae}' 		# Microsoft-Windows-Rdms-UI
	'{6CBE573A-121B-4E02-A09D-6C0B6B96D676}' 		# RDP.ServerStack.QOE
	'{1139c61b-b549-4251-8ed3-27250a1edec8}' 		# Microsoft-Windows-RemoteDesktopServices-RdpCoreTS
	'{C1BB27C2-F176-499C-A932-D453051E8B0B}'        # rdpcorets.dll
	'{c8e6dc53-660c-44ee-8d00-e47f189db87f}' 		# Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV
	'{D4199645-41BE-4FD5-9D71-A612C508FDC6}' 		# RDPApiTrace
	'{28AA9132-5ED1-46B9-916A-FD24C188C316}' 		# rdpnotify.exe
	'{3C734565-80DB-4168-8B16-B15393154F69}' 		# rdvcloud.dll
	'{16e72985-266a-490e-8523-fb5ff5da188e}' 		# rdpavenc.dll
	'{7b919abb-998b-46a9-b8f3-d4a49e8074da}'		# rdpnano.dll
	'{05875a0b-efdf-4c4a-8d3c-098a15dc483d}' 		# mohoroGateway.dll
	'{8A99FD17-7D82-45D9-A965-F9A3F9FA85E5}' 		# RdpFilterTrace
	'{26771A7F-04D4-4597-BBF6-3AF9F7818B25}' 		# Microsoft.Windows.RemoteDesktop.Virtualization
	'{F115DDAF-E07E-4B15-9721-427134B41EBA}' 		# RDP(RDPEncryption)
	'{a8f457b8-a2b8-56cc-f3f5-3c00430937bb}' 		# RDP(RDPEmulation)
	'{8A633D91-8B07-4AAE-9A00-D07E2AFD29D6}' 		# RDP.Transport
	'{10AB3154-C36A-4F24-9D91-FFB5BCD331EF}' 		# Microsoft-Windows-RemoteDesktopServices-RemoteFX-SessionLicensing(LSClientService.dll)
	'{8bddcf41-9630-47e8-914a-d4952112ea19}' 		# Microsoft-Windows-RemoteDesktopServices-RemoteFX-SessionManager(rdvgsm.dll)(WS2012R2 or earlier)
	'{7bfcf102-7378-431c-9284-0b968258991a}' 		# Microsoft-Windows-RemoteDesktopServices-RemoteDesktopSessionManager(RDPWD.sys)(WS2012 or ealier)
	'{48DAB7B6-34F4-44C8-8355-35124FE39BFF}' 		# RdpXTraceProvider
	'{CC3716F0-0336-44FB-A442-86276F4B712C}' 		# RdpWinTraceProvider
	'{28711274-D721-465E-9C7E-D359422E96CD}' 		# lsclientservice
	'{26C7EAC9-9675-43CB-9EF1-B9CD4564595F}' 		# lscspolicyloader
	'{97166ECD-4F97-442F-A909-9EB9AE6D2458}' 		# lscsvmbuspipechannel
	'{15D9261C-EFDF-4C4A-8D3C-098A15DC483D}' 		# RdpNetEmu*
	'{3EF15ADF-1300-44A1-B85C-2A83549F5B9E}' 		# Microsoft.Windows.RemoteDesktop.Legacy*
	'{0B938561-4D72-4312-ACF6-109D34C26148}' 		# CMProxyGuest*
	'{5CE9C675-02A0-4B9D-89E6-77C13EF68E75}' 		# CMProxyHost*
	'{59906E55-0817-4CDA-BA3B-D34E33ED4EE7}' 		# TokenValTrace*
	'{6E530C0D-677F-488B-B163-0415CB65883D}' 		# VMMWSFilterPluginTrace*
	'{A0674FB6-BA0D-456F-B079-A2B029D8342C}' 		# TS USB Hub
	'{39A585FF-6C36-492B-93C0-35B71E65A345}' 		# TS USB Generic Device
	'{73C5EC49-C807-489D-9E45-D36D72235F84}' 		# UMRDPTrace
	'{82A94E1C-C1B3-4E4A-AC87-43BD802E458E}' 		# KernVc - KernUtil
	'{73BFB78F-12B5-4738-A66C-A77BCD55FA12}' 		# Rdpdr Sys
	'{600be610-f0e8-4912-b397-d2cc76060114}' 		# USBDRTrace
	'{3f7b2f99-b863-4045-ad05-f6afb62e7af1}' 		# Microsoft-Windows-TerminalServices-MediaRedirection(tsmf.dll)
	'{b1c94ed9-ac9b-410e-aa48-4ffc5e45f4e3}' 		# Microsoft-Windows-TerminalServices-MediaRedirection-DShow(DShowRdpFilter.dll) (WS2008R2)
	'{48738267-0545-431D-8087-7349127811D0}' 		# TSUsbRedirectionServiceTrace
	'{A1F3B16A-C510-41C1-8B58-E695880F3A80}' 		# tsscan
	'{C14F3000-0B2D-4464-99AC-FA764AF708CF}' 		# rdpbus
	'{ECA5427C-F28F-4942-A54B-7E86DA46BDBE}' 		# TSUrbUtils
	'{D33E545F-59C3-423F-9051-6DC4983393A8}' 		# Winsta Client (API)
	'{0046a6b4-a24c-40d5-b0e6-c8ec031bd82a}' 		# TS RPC
	'{40423FDC-C9EC-4D34-9E72-8DE793CDB22E}'    	# RDPCore KMTS
	'{557D257B-180E-4AAE-8F06-86C4E46E9D00}'    	# Local Session Manager (LSM)
	'{5283D5F6-65B5-425F-A30B-F16C057D6B57}'    	# Remote Connection Manager (TermService)
	'{449E4E69-329E-4EB1-9DDF-809D17A2E0C1}'    	# Broker 'Client' (on RDSH)
	'{986CC918-7434-4FAB-B37F-C4BA7AD1E293}'    	# Broker 'Server' (on RDSH)
	'{9ed727c4-4ab6-4b66-92d7-2072e87c9124}'		# CM Licensing (tssrvlic)
	'{ae8ab061-654e-4d72-9f4b-c799ba919ec8}' 		# RD Message Server (SessionMsg)
	'{59de359d-ec83-445c-9323-b75e2056d5a5}' 	    # Session Configuration (SessionEnv)
	'{9EA2030F-DB66-47EF-BF2C-619CC76F3E1B}' 		# RCM Licensing Policy (LSCSHostPolicy)
	'{D2E990DA-8504-4702-A5E5-367FC2F823BF}' 	 	# RdpAppXHelp
	'{C0C89C53-DD3F-4782-00A7-8F537811A835}' 	 	# Net Fair Share (RdpNetFS)
	'{588F5E4C-6853-4FCB-BD7D-75F926276C20}' 	 	# TSAllowTrace
	'{C6FDD8E3-770B-4964-9F0C-227457146B49}' 		# RDP(SessEnvRpcTelemetry)
	'{89d48904-939f-4177-aad4-2fdb26b8329f}' 		# Microsoft.Windows.RemoteDesktop.RDSHFarm.UVhd
	'{D9F94C5A-94F8-4CD0-A054-A1EE67A2DA6B}' 		# Microsoft.Windows.RemoteDesktop.SessionHost
	'{997FB36F-0208-4ED7-865B-E19816C3782D}' 		# Microsoft.Windows.RemoteDesktop.SessionConfig(From WS2019)
	'{78be48bd-5d52-4e39-823d-226cd5551f37}' 		# RDP.ServerStack(From WS2019)
	'{CA341B3C-B9D2-4D0F-9BD3-D88183596DB9}' 		# RDP.ServerStack.Diagnostics(From WS2019)
	'{D2B9C1C5-0C37-47EB-AA79-CD0CF0CE2FA6}' 		# TSFairShare
	'{c0c89c53-dd3f-4782-a78f-5378111a8305}' 		# RDSNetFairshare
	'{5D896912-022D-40AA-A3A8-4FA5515C76D7}' 		# Microsoft-Windows-TerminalServices-LocalSessionManager
	'{27A8C1E2-EB19-463E-8424-B399DF27A216}' 		# Microsoft-Windows-TerminalServices-PnPDevices
	'{952773BF-C2B7-49BC-88F4-920744B82C43}' 		# Microsoft-Windows-TerminalServices-Printers
	'{C76BAA63-AE81-421C-B425-340B4B24157F}' 		# Microsoft-Windows-TerminalServices-RemoteConnectionManager
	'{2184B5C9-1C83-4304-9C58-A9E76F718993}' 		# Microsoft-Windows-TerminalServices-SessionBroker-Client
	'{4199EE71-D55D-47D7-9F57-34A1D5B2C904}' 		# TerminalServer-MediaFoundationPlugin
	'{32817E55-7BFE-45E0-AF68-A413FA6E0083}' 		# Microsoft-Windows-TerminalServices-TSAppSrv-TSMSI
	'{f1394de0-32c7-4a76-a6de-b245e48f4615}' 		# Microsoft-Windows-RemoteDesktopServices-SessionServices
	'{1139c61b-b549-4251-8ed3-27250a1edec8}' 		# Microsoft-Windows-RemoteDesktopServices-RdpCoreTS
	'{741c6be3-f74b-4e4d-88e7-5ce3a35faeb3}' 		# Microsoft-Windows-RemoteDesktopServices-RemoteFX-VM-User-Mode-Transport
	'{127e0dc5-e13b-4935-985e-78fd508b1d80}' 		# Microsoft-Windows-TerminalServices-RdpSoundDriver
	'{6BA29EDF-A2F4-4212-B06B-6D5712210652}' 		# Microsoft-Windows-TerminalServices-TSAppSrv-TSVIP
	'{8d83aec0-01de-4772-a317-2093b6dc3bab}' 		# Microsoft-Windows-TerminalServices-TSFairShare-Events
	'{c8e6dc53-660c-44ee-8d00-e47f189db87f}' 		# Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV
	'{DCBE5AAA-16E2-457C-9337-366950045F0A}' 		# Microsoft-Windows-TerminalServices-PnPDevices
	'{84214511-602B-4456-9CB9-7800ED3432F6}' 		# RemoteFX Virtual Graphics Manager
	'{140C2428-F60D-43F9-9B07-3E5F622438A0}' 		# RemoteFX Virtual Graphics Manager
	'{C51286E1-F923-404D-B68B-8D0DAB0976B0}' 		# RemoteFX Virtual Graphics Manager
	'{F09A9A18-0C87-47AC-8A99-5C2D4BB82117}' 		# RemoteFX Virtual Graphics Manager
	'{482F83D3-E8CB-4727-8A28-FC51544C5A28}' 		# RemoteFX VM Bus (RdvVMXPort)
	'{8CDC2BE7-58CD-4760-B344-422B893BFF08}' 		# synth3dvsp.sys
	'{80342309-054F-4E2E-9D3D-FCCFBDCAA92F}' 		# rfxvmt.dll
	'{e76c0d10-97b8-477d-a0ae-e8fa5870a695}' 		# rdvgogl.dll
	'{1148F9BD-F5FF-482D-B08A-F289F3E928E0}' 		# rdvgocl.dll
	'{0c79e960-6bd5-4206-bf5d-578cedb8df2a}' 		# rdvgumd.dll
	'{6CDD992D-B35C-40A6-AF1E-D727C11DECFD}' 		# rdvgkmd.exe
	'{6AABAEA6-DF19-4528-97D8-3A420CEE69A0}' 		# rdvgu11.dll
	'{2A11472B-451F-4FCA-8590-9724D41C604E}' 		# RDVVGHelper
	'{432EEF91-C605-482B-83BE-0963604F1397}' 		# RDVGSMSTrace (WS2012R2 or earlier)
	'{62F277AE-2CCF-4AA9-A8AA-32752200BC18}' 		# CtDwm
	'{204AE8F0-42F7-4A13-97CD-B490927CB725}' 		# Microsoft.Windows.VGPU.RDVGM
	'{D953B8D8-7EA7-44B1-9EF5-C34AF653329D}' 		# RDP.Graphics(From WS2019)
	'{9512fdbc-24e6-44fa-a8a3-af44d3447216}' 		# RDP.Graphics(From WS2019)
	'{E80ADCF1-C790-4108-8BB9-8A5CA3466C04}' 		# Microsoft-Windows-TerminalServices-RDP-AvcSoftwareDecoder(From WS2019)
	'{1B4F0E96-6876-49c8-BFBA-072DAE6543B3}' 		# Microsoft-Windows-RemoteDesktopServices-vGPU-KModeDriver(rdvgkmd.sys)
	'{5AE63087-6A35-40b0-AE15-CEA95A71A8C0}' 		# Microsoft-Windows-RemoteDesktopServices-vGPU-UModeDriver(rdvgumd32.dll)
	'{1deb930f-e136-4b08-9761-d7e3a5d14faa}' 		# Microsoft-Windows-RemoteDesktopServices-vGPU-UModeDriver64(rdvgumd64.dll)
	'{3f7b2f99-b863-4045-ad05-f6afb62e7af1}' 		# Microsoft-Windows-TerminalServices-MediaRedirection(tsmf.dll)
	'{b1c94ed9-ac9b-410e-aa48-4ffc5e45f4e3}' 		# Microsoft-Windows-TerminalServices-MediaRedirection-DShow(DShowRdpFilter.dll) (WS2008R2)
	'{0C38D54D-EF5F-4179-95FA-6D4EDA073000}' 		# RDVVGHelperSerivce (WS2012R2 or earlier)
	'{4BDD50B0-BF12-4991-8B11-C455F14289DB}' 		# rdpvideominiport
	'{10D520E2-205C-4C22-B25C-AC7A779C55B2}' 		# Microsoft-Windows-RemoteDesktopServices-RemoteFX-Manager
	'{508371b1-7651-4b33-4b33-5884f824bd1b}' 		# IP Virtualization 'Client' (TSVIPCli)
	'{AE4C5843-A9A3-4EB9-81F3-65D57D250180}' 		# IP Virtualization Pool (TSVIPPool)
	'{bd5c97d6-3d8f-5779-7872-09ad6dcad49b}' 		# Microsoft.Windows.Rds.VirtualIP.Driver
	'{6BA29EDF-A2F4-4212-B06B-6D5712210652}' 		# Microsoft-Windows-TerminalServices-TSAppSrv-TSVIP
	'{00508371-7651-4b33-4b33-5884f824bd1b}' 		# TSVIPCli
	'{0ba29edf-a2f4-4212-b06b-6d5712210652}' 		# TSVIPSrv
	'{2A0A7EC8-5E2B-47AB-B553-32E1C7AEF0EF}'		# VmHostAgentTrace
	'{92618A87-2F6A-4B75-9AE2-E77BE7EAF43C}'		# VmHostAgentTrace
	'{8E6B6962-AB54-4335-8229-3255B919DD0E}' 		# WMI Client
	'{1ff6b227-2ca7-40f9-9a66-980eadaa602e}' 		# WMI Verbose
	'{7ADA0B31-F4C2-43F4-9566-2EBDD3A6B604}' 		# TSCPUBSvr.dll
	'{81B84BCE-06B4-40AE-9840-8F04DD7A8DF7}' 		# TSCPubWmiProvider
	'{E43CAB68-0AB4-4F47-BF30-E61CAC7BBD8A}' 		# TSPublishingWmiProvider
	'{F8FCF9E0-535A-4BA6-975F-7AC82FBDC631}' 		# TLSBrandTrace / TLSWmiTrace
	'{1418EF04-B0B4-4623-BF7E-D74AB47BBDAA}' 		# Microsoft-Windows-WMI-Activity
	'{A7975C8F-AC13-49F1-87DA-5A984A4AB417}' 		# Microsoft-Windows-WinRM
	'{1EDEEE53-0AFE-4609-B846-D8C0B2075B1F}' 		# Microsoft-Windows-WMI
	'{70A43AE8-E131-42BD-89E0-23704FB27C6A}' 		# Client RDWeb Workspace Proxy
	'{070f54b9-7eb0-4c99-8dfa-2aa8d8ab0d89}' 		# Client Workspace (RemoteApp & Desktop Connections/RDWeb SSO) (tsworkspace)
	'{3D3E7039-99CF-4446-8C81-4AD5A8560E7B}' 		# Client Workspace (RemoteApp & Desktop Connections/RDWeb SSO) (wkspbroker)
	'{3D3E7039-99DF-4446-8C81-4AD5A8560E7B}' 		# wkspbroker.exe
	'{3E3E7039-99DF-4446-8C81-4AD5A8560E7B}' 		# WorkspaceBrokerAxTrace(wkspbrokerAx.dll)
	'{3C3E7039-99CF-4446-8D81-4AC5A8560E7B}' 		# WorkspaceRuntimeTrace(wksprt.exe)
)


#audio
$UEX_RdsAudioProviders = @(
	'{5A966D1C-6B48-11DA-8BDE-F66BAD1E3F3A}!RdsRDAUDIO!0xffffffff!0xf' 		# Rdp Sound End Point Trace
	'{e27950eb-1768-451f-96ac-cc4e14f6d3d0}!RdsRDAUDIO!0xffffffff!0xf' 		# AudioSrv/Ses (RDP Audio)
	'{E80ADCF1-C790-4108-8BB9-8A5CA3466C04}!RdsRDAUDIO' 					# Microsoft-Windows-TerminalServices-RDP-AvcSoftwareDecoder(From WS2019)
	'{3f7b2f99-b863-4045-ad05-f6afb62e7af1}!RdsRDAUDIO' 					# Microsoft-Windows-TerminalServices-MediaRedirection(tsmf.dll)
	'{b1c94ed9-ac9b-410e-aa48-4ffc5e45f4e3}!RdsRDAUDIO' 					# Microsoft-Windows-TerminalServices-MediaRedirection-DShow(DShowRdpFilter.dll) (WS2008R2)
)

#auth
$UEX_RdsAuthProviders = @(
	'{6165F3E2-AE38-45D4-9B23-6B4818758BD9}!RdsAUTH!0xffffffff!0xff' 		# CredSSP (tspkg)
	'{60A7AB7A-BC57-43E9-B78A-A1D516577AE3}!RdsAUTH!0xffffff!0xff' 			# KerbComm
	'{FACB33C4-4513-4C38-AD1E-57C1F6828FC0}!RdsAUTH!0xffffffff!0xff' 		# KerbClientSharedTraceControlGuid
	'{97A38277-13C0-4394-A0B2-2A70B465D64F}!RdsAUTH!0xff!0xff' 				# Microsoft-Windows-KPSSVC-WPP
	'{52BF9EC6-69F5-49E6-9ECC-D3B994C40142}!RdsAUTH!0x1f!0xff' 				# CapiProvider (certificates)
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}!RdsAUTH!0x3fffffff!0xff' 		# Kerberos
	'{5AF52B0D-E633-4EAD-828A-4B85B8DAAC2B}!RdsAUTH!0xff!0xff' 				# NegoExts
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}!RdsAUTH!0x7ffff!0xff' 			# msv1/NTLM
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}!RdsAUTH!0x3ffffff!0xff' 		# LsaSrv
	'{37D2C3CD-C5D4-4587-8531-4696C44244C8}!RdsAUTH!0xffffffff!0xff' 		# Schannel-WPP
	'{FB1A70CC-BE28-40C1-BD6A-47671538383A}!RdsAUTH' 						# Microsoft.Windows.RemoteDesktop.CertManager(From WS2019)
)
$UEX_RdsAuthManProviders = @(
	'{5BBCA4A8-B209-48DC-A8C7-B23D3E5216FB}!RdsMAN-AUTH!0x0!0xff' 			# Microsoft-Windows-CAPI2
	'{98E6CFCB-EE0A-41E0-A57B-622D4E1B30B1}!RdsMAN-AUTH!0x0!0xff' 			# Microsoft-Windows-Security-Kerberos
	'{AC43300D-5FCC-4800-8E99-1BD3F85F0320}!RdsMAN-AUTH!0x0!0xff' 			# Microsoft-Windows-NTLM
	'{91CC1150-71AA-47E2-AE18-C96E61736B6F}!RdsMAN-AUTH!0x0!0xff' 			# Schannel
	'{1f678132-5938-4686-9fdc-c8ff68f15c85}!RdsMAN-AUTH!0x0!0xff' 			# Schannel-2K8
)

#hyper-v (rdvh)
$UEX_RdsHypervManProviders = @(
	'{02F3A5E3-E742-4720-85A5-F64C4184E511}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Config
	'{51DDFA29-D5C8-4803-BE4B-2ECB715570FE}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Worker
	'{6066F867-7CA1-4418-85FD-36E3F9C0600C}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-VMMS
	'{FDFF33EC-70AA-46D3-BA65-7210009FA2A7}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Integration-RDV
	'{09242393-1349-4F4D-9FD7-59CC79F553CE}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-EmulatedNic
	'{0B9FDCCC-451C-449C-9BD8-6756FCC6091A}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Guest-Drivers-Storage-Filter
	'{10B3D268-9782-49A4-AACC-A93C5482CB6F}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-StorageVSP
	'{13EAE551-76CA-4DDC-B974-D3A0F8D44A03}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Tpm
	'{152FBE4B-C7AD-4F68-BADA-A4FCC1464F6C}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Netvsc
	'{17103E3F-3C6E-4677-BB17-3B267EB5BE57}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Compute
	'{177D1599-9764-4E3A-BF9A-C86887AADDCE}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-VmbusVdev
	'{1CEB22B1-97FF-4703-BEB2-333EB89B522A}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-VMSP
	'{2B74A015-3873-4C56-9928-EA80C58B2787}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Integration
	'{339AAD0A-4124-4968-8147-4CBBB1F8B3D5}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-UiDevices
	'{52FC89F8-995E-434C-A91E-199986449890}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Hypervisor
	'{5931D877-4860-4EE7-A95C-610A5F0D1407}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-VID
	'{5B621A17-3B58-4D03-94F0-314F4E9C79AE}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-SynthFcVdev
	'{67DC0D66-3695-47C0-9642-33F76F7BD7AD}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-VmSwitch
	'{7B0EA079-E3BC-424A-B2F0-E3D8478D204B}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-VSmb
	'{86E15E01-EDF1-4AC7-89CF-B19563FD6894}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-EmulatedStor
	'{8F9DF503-1D12-49EC-BB28-F6EC42D361D4}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Serial
	'{9F2660EA-CFE7-428F-9850-AECA612619B0}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-VfpExt
	'{AE3F5BF8-AB9F-56D6-29C8-8C312E2FAEC2}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Virtual-PMEM
	'{AF7FD3A7-B248-460C-A9F5-FEC39EF8468C}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-ComputeLib
	'{B1D080A6-F3A5-42F6-B6F1-B9FD86C088DA}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-DynMem
	'{BA2FFB5C-E20A-4FB9-91B4-45F61B4B66A0}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Guest-Drivers-Dynamic-Memory
	'{C18672D1-DC18-4DFD-91E4-170CF37160CF}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Guest-Drivers-IcSvc
	'{C29C4FB7-B60E-4FFF-9AF9-CF21F9B09A34}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-SynthNic
	'{C7C9E4F7-C41D-5C68-F104-D72A920016C7}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-CrashDump
	'{DA5A028B-B248-4A75-B60A-024FE6457484}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-EmulatedDevices
	'{DE9BA731-7F33-4F44-98C9-6CAC856B9F83}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Chipset
	'{EDACD782-2564-4497-ADE6-7199377850F2}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-SynthStor
	'{EDED5085-79D0-4E31-9B4E-4299B78CBEEB}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Debug
	'{F2E2CE31-0E8A-4E46-A03B-2E0FE97E93C2}!RdsMAN-HYPERV!0x0!0xf' 			# Microsoft-Windows-Hyper-V-Guest-Drivers-Vmbus
)

#logon
$UEX_RdsUsrLogonProviders = @(
	'{301779E2-227D-4FAF-AD44-664501302D03}!RdsUSRLOGON!0xffffffff!0xff'	# Winlogon Notify (WlClNtfy)
	'{D451642C-63A6-11D7-9720-00B0D03E0347}!RdsUSRLOGON!0xffffffff!0xff' 	# Winlogon Core
	'{d9391d66-ee23-4568-b3fe-876580b31530}!RdsUSRLOGON!0xffffffff!0xff' 	# Winlogon StateMachine
	'{A789EFEB-FC8A-4C55-8301-C2D443B933C0}!RdsUSRLOGON!0xffffffff!0xff'	# Security (UmsHlpr)
	'{19D78D7D-476C-47B6-A484-285D1290A1F3}!RdsUSRLOGON!0xffffffff!0xff' 	# Winlogon Notify (SysNtfy)
	'{C2BA06E2-F7CE-44AA-9E7E-62652CDEFE97}!RdsUSRLOGON!0xffffffff!0xff' 	# WinInit
	'{d138f9a7-0013-46a6-adcc-a3ce6c46525f}!RdsUSRLOGON!0xffffffff!0xff'	# WMsgSrv
	'{EB7428F5-AB1F-4322-A4CC-1F1A9B2C5E98}!RdsUSRLOGON!0xffffffff!0xff' 	# Profile Service
	'{2AC96968-C174-4cd5-A2E5-D86495DDB4F2}!RdsUSRLOGON!0xffffffff!0xff' 	# Profile Trace
	'{2955E23C-4E0B-45CA-A181-6EE442CA1FC0}!RdsUSRLOGON!0x2f!0xff' 			# Auth UI
	'{D1D7D72D-00D5-4E56-8BAC-23FAC0F9ED4E}!RdsUSRLOGON!0xffffffff!0xff' 	# Auth UI-IC
	'{CEC2553A-8961-4D34-92CA-AB2ECEF646C5}!RdsUSRLOGON!0xffffffff!0xff' 	# Auth UI-ImgVal
	'{012616AB-FF6D-4503-A6F0-EFFD0523ACE6}!RdsUSRLOGON!0xffffffff!0xff' 	# Auth UI-CredAPI
	'{A323CDC2-81B0-48B2-80C8-B749A221478A}!RdsUSRLOGON!0xffffffff!0xff' 	# Auth UI-HG
	'{169CC90F-317A-4CFB-AF1C-25DB0B0BBE35}!RdsUSRLOGON!0x2f!0xff' 			# Auth UI
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}!RdsUSRLOGON!0xffffffff!0xff' 	# Kerberos Client
	'{5B4F9E61-4334-409F-B8F8-73C94A2DBA41}!RdsUSRLOGON' 					# Userinit
	'{6b6c257f-5643-43e8-8e5a-c66343dbc650}!RdsUSRLOGON' 					# UserProfileService.dll
	'{6035d7f9-6e24-44bf-b540-3ade030d001a}!RdsUSRLOGON' 					# winsrvext.dll
	'{3ec987dd-90e6-5877-ccb7-f27cdf6a976b}!RdsUSRLOGON' 					# Microsoft.Windows.LogonUI.WinlogonRPC
	'{c0ac3923-5cb1-5e37-ef8f-ce84d60f1c74}!RdsUSRLOGON' 					# Microsoft.Windows.TSSessionUX
)
$UEX_RdsUsrLogonManProviders = @(
	'{89B1E9F0-5AFF-44A6-9B44-0A07A7CE5845}!RdsMAN-USRLOGON!0x0!0xff' 		# Microsoft-Windows-User Profiles Service
	'{DB00DFB6-29F9-4A9C-9B3B-1F4F9E7D9770}!RdsMAN-USRLOGON!0x0!0xff' 		# Microsoft-Windows-User Profiles General
	'{DBE9B383-7CF3-4331-91CC-A3CB16A3B538}!RdsMAN-USRLOGON!0x0!0xff' 		# Microsoft-Windows-Winlogon
	'{AEA1B4FA-97D1-45F2-A64C-4D69FFFD92C9}!RdsMAN-USRLOGON!0x0!0xff' 		# Microsoft-Windows-GroupPolicy
	'{63D2BB1D-E39A-41B8-9A3D-52DD06677588}!RdsMAN-USRLOGON!0x0!0xff' 		# Microsoft-Windows-Shell-AuthUI
)

#printing
$UEX_RdsPrintSpoolProviders = @(
	'{FCA72EBA-CBB3-467C-93BC-1DB4978C398D}!RdsPRNTSPOOL!0xffffffff!0xf'  	# XPS Document Writer for EasyPrint (MXDWDRV)
	'{C9BF4A08-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# ASYNCNTFY
	'{C9BF4A01-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# LOCALSPL
	'{C9BF4A06-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# SPLLIB
	'{C9BF4A04-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# BIDISPL
	'{C9BF4A02-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# WINSPOOL
	'{C9BF4A03-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# WIN32SPL
	'{C9BF4A9F-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# SPOOLSS
	'{C9BF4A9E-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# SPOOLSV
	'{C9BF4A05-D547-4D11-8242-E03A18B5BE01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# SPLWOW64
	'{747EF6FD-E535-4D16-B510-42C90F6873A1}!RdsPRNTSPOOL!0x0!0xff' 		  	# Microsoft-Windows-PrintService
	'{EE7E960D-5E42-4C28-8F61-D8FA8B0DD84D}!RdsPRNTSPOOL!0xffffffff!0xff' 	# ProviderGuid / ServerGuid
	'{CE444D6A-F287-4977-BBBD-89A0DD65B71D}!RdsPRNTSPOOL!0xffffffff!0xff' 	# CDIGuid
	'{D34AE79A-15FB-44F9-9FD8-3098E6FFFD49}!RdsPRNTSPOOL!0xffffffff!0xff' 	# CASGuid
	'{27239FD0-425E-11D8-9E39-000039252FD8}!RdsPRNTSPOOL!0xffffffff!0xff' 	# COMMONGuid
	'{F4DF4FA4-66C2-4C14-ABB1-19D099D7E213}!RdsPRNTSPOOL!0xffffffff!0xff' 	# COMPONENTGuid
	'{7663DA2F-1594-4C33-83DD-D5C64BBED68A}!RdsPRNTSPOOL!0xffffffff!0xff' 	# ObjectsGuid
	'{AAED978E-5B0C-4F71-B35C-16E9C0794FF9}!RdsPRNTSPOOL!0xffffffff!0xff' 	# CommonGuid
	'{9677DFEF-EACF-4173-8977-FFB0086B11E6}!RdsPRNTSPOOL!0xffffffff!0xff' 	# BridgeGuid
	'{CF3F502E-B40D-4071-996F-00981EDF938E}!RdsPRNTSPOOL!0x0!0xff' 		  	# Microsoft-Windows-PrintBRM
	'{301CCC25-D58B-4C5E-B6A5-15BCF8B0077F}!RdsPRNTSPOOL!0xffffffff!0xff' 	# INETPPUI
	'{C9BF4A9E-D547-4D11-8242-E03A18B5BEEE}!RdsPRNTSPOOL!0xffffffff!0xff' 	# INETPP
	'{04160794-60B6-4EC7-96FF-4953691F94AA}!RdsPRNTSPOOL!0xffffffff!0xff' 	# SetupIPP
	'{3EA31F33-8F51-481D-AEB7-4CA37AB12E48}!RdsPRNTSPOOL!0xffffffff!0xff' 	# LPDSVC
	'{9F44821F-1FD9-46BF-A09A-C7F751159AAF}!RdsPRNTSPOOL!0x0!0xff' 		  	# Microsoft-Windows-Spooler-LPDSVC
	'{9E6D0D9B-1CE5-44B5-8B98-F32ED89077EC}!RdsPRNTSPOOL!0xffffffff!0xff' 	# LPRHelp
	'{F30FAB8E-84BB-48D4-8E80-F8967EF0FE6A}!RdsPRNTSPOOL!0xffffffff!0xff' 	# LPRMon
	'{DC82DA8E-2290-449D-9062-21EF70D36E22}!RdsPRNTSPOOL!0x0!0xff' 		  	# Microsoft-Windows-Spooler-LPRMON
	'{5ED940EB-18F9-4227-A454-8EF1CE5B3272}!RdsPRNTSPOOL!0xffffffff!0xff' 	# SetupLPR
	'{99F5F45C-FD1E-439F-A910-20D0DC759D28}!RdsPRNTSPOOL!0xffffffff!0xff' 	# USBMon
	'{CAD2D809-03D9-4F46-9CF4-72AA4F04B6B9}!RdsPRNTSPOOL!0x0!0xff' 		  	# Microsoft-Windows-SpoolerTCPMon
	'{62A0EB6C-3E3E-471D-960C-7C574A72534C}!RdsPRNTSPOOL!0xffffffff!0xff' 	# TCPMon
	'{9558985E-3BC8-45EF-A2FD-2E6FF06FB886}!RdsPRNTSPOOL!0xffffffff!0xff' 	# WSDPRINT
	'{836767A6-AF31-4938-B4C0-EF86749A9AEF}!RdsPRNTSPOOL!0xffffffff!0xff' 	# WSDMON
	'{7672778D-86FE-41D0-85C8-82CAA8CE6168}!RdsPRNTSPOOL!0xffffffff!0xff' 	# SetupWSD
	'{6D1E0446-6C52-4B85-840D-D2CB10AF5C63}!RdsPRNTSPOOL!0xffffffff!0xff' 	# WSDPrPxy
	'{B795C7DF-07BC-4362-938E-E8ABD81A9A01}!RdsPRNTSPOOL!0xffffffff!0xff' 	# NTPRINT
	'{09737B09-A25E-44D8-AA75-07F7572458E2}!RdsPRNTSPOOL!0xffffffff!0xff' 	# PRNNTFY
	'{34F7D4F8-CD95-4B06-8BF6-D929DE4AD9DE}!RdsPRNTSPOOL!0xffffffff!0xff' 	# PRNCACHE
	'{B42BD277-C2BA-468B-AB3D-05B1A1714BA3}!RdsPRNTSPOOL!0xffffffff!0xff' 	# PRINTLIB
	'{A83C80B9-AE01-4981-91C6-94F00C0BB8AA}!RdsPRNTSPOOL!0xffffffff!0xff' 	# printui
	'{EB4C6075-0B67-4A79-A0A3-7CD9DF881194}!RdsPRNTSPOOL!0xffffffff!0xff' 	# XpsRasFilter
	'{0ed38d2b-4acc-4e23-a8ec-d0dacbc34637}!RdsPRNTSPOOL!0xffffffff!0xff' 	# RD Printing (tsprint)
)
$UEX_RdsPrintSpoolManProviders = @(
	'{747EF6FD-E535-4D16-B510-42C90F6873A1}!RdsMAN-PRNTSPOOL!0x0!0xff' 		# Microsoft-Windows-PrintService
)

#RAIL
$UEX_RdsRailProviders = @(
	'{C127C1A8-6CEB-11DA-8BDE-F66BAD1E3F3A}!RdsRAIL!0xffffffff!0xf' 		# RemoteApp Shell (RAIL RdpInit)
	'{BFA655DC-6C51-11DA-8BDE-F66BAD1E3F3A}!RdsRAIL!0xffffffff!0xf' 		# RemoteApp Shell (RAIL RdpShell)
	'{39825FFA-F1B4-41B7-8221-20D4B8DBE57E}!RdsRAIL!0xffffffff!0xf' 		# RemoteApp Shell (RAIL RdpShell)
	'{43471865-f3ee-5dcf-bf8b-193fcbbe0f37}!RdsRAIL!0xffffffff!0xf' 		# RAIL XPlat (RAIL RdpShell)
	'{73C5EC49-C807-489D-9E45-D36D72235F84}!RdsRAIL!0xffffffff!0xf' 		# User Mode Port Redirector (UMRDP)
	'{82A94E1C-C1B3-4E4A-AC87-43BD802E458E}!RdsRAIL!0xffffffff!0xf' 		# Device redirection (KDynVC)
	'{73BFB78F-12B5-4738-A66C-A77BCD55FA12}!RdsRAIL!0xffffffff!0xf' 		# R2 RDPDR
	'{600be610-f0e8-4912-b397-d2cc76060114}!RdsRAIL!0xffffffff!0xf' 		# USB Redirection
	'{BFA655DC-6C51-11DA-8BDE-F66BAD1E3F30}!RdsRAIL' 						# rdpshell.exe (rdprail\rdpshell\clouddvs\objfre\amd64)
	'{4A49AFE3-776E-467A-ACA0-71F9C6C8499F}!RdsRAIL' 						# Microsoft.Windows.RemoteDesktop.RAIL.RdpInit
	'{DC1A94A6-0A1A-433E-B470-3C72353B7309}!RdsRAIL' 						# Microsoft.Windows.RemoteDesktop.RAIL.Server.Diagnostics(From RS5)
)

#RDBroker/AppPublishing
$UEX_RdsRdBrokerProviders = @(
	'{C10870A3-617D-42E9-80C7-1C4BE2709E06}!RdsRDBROKER!0xffffffff!0xf' 	# VmPluginTrace
	'{3C3E7089-99CF-4446-8D81-4AC5A8560E6A}!RdsRDBROKER!0xffffffff!0xf' 	# SessionBrokerTrace
	'{FA801570-83A9-11DF-B3A9-8C26DFD72085}!RdsRDBROKER!0xffff!0xff' 	  	# RdCentralDbPlugin
	'{C29D637F-AFB5-43F9-96F8-936429371F32}!RdsRDBROKER' 					# RdvVmCore
)
$UEX_RdsRdBrokerManProviders = @(
	'{D1737620-6A25-4BEF-B07B-AAC3DF44EFC9}!RdsMAN-RDBROKER' 				# Microsoft-Windows-TerminalServices-SessionBroker
	'{77B0D57B-97B8-4F42-83B0-4FDA12D3D79A}!RdsMAN-RDBROKER' 				# Microsoft-Windows-RemoteApp and Desktop Connection Management
)
$UEX_RdsAppPubProviders = @(
	'{7ADA0B31-F4C2-43F4-9566-2EBDD3A6B604}!APPPUB!0xffffffff!0xf' 			# TSCPUBSvr.dll
	'{BF936B9C-DA45-4494-A236-101FE5A2A51D}!APPPUB!0xffffffff!0xf'			# tspubfilter.dll
	'{81B84BCE-06B4-40AE-9840-8F04DD7A8DF7}!APPPUB!0xffffffff!0xf' 			# TSCPubWmiProvider
	'{1FD4C5A9-27B7-418B-8DFC-216E7FA7B990}!APPPUB!0xffffffff!0xf' 			# tscpubStub.dll
	'{0CEA2AEE-1A4C-4DE7-B11F-161F3BE94669}!APPPUB' 						# TSPublishingIconHelperTrace
	'{E43CAB68-0AB4-4F47-BF30-E61CAC7BBD8A}!APPPUB' 						# TSPublishingWmiProvider
)

#RDClient
$UEX_RdsRdClientProviders = @(
	'{D33E545F-59C3-423F-9051-6DC4983393A8}!RdsRDCLIENT!0xffffffff!0xff' 	# Winsta Client (API)
	'{0046a6b4-a24c-40d5-b0e6-c8ec031bd82a}!RdsRDCLIENT!0xffffffff!0xff' 	# TS RPC
	'{DAA6CAF5-6678-43F8-A6FE-B40EE096E06E}!RdsRDCLIENT!0xffffffff!0xf' 	# RD Client Core Trace (MSTSCAX)
	'{0C51B20C-F755-48A8-8123-BF6DA2ADC727}!RdsRDCLIENT!0xffffffff!0xf' 	# RD Client Shell Trace (MSTSC)
	'{936FF90C-7CC4-40d8-8A04-77B281C73AB9}!RdsRDCLIENT!0xffffffff!0xf' 	# RD Client Gateway QEC
	'{70DB53D8-B6F3-428D-AA33-5B2CE56718C5}!RdsRDCLIENT!0xffffffff!0xf' 	# RD Client Gateway Core
	'{fac7fcce-62fc-4be0-bd67-311750b5bcff}!RdsRDCLIENT!0xffffffff!0xf' 	# RD Client Print (XPSClientPlgin)
	'{D4197645-41DE-4ad5-9D71-A612C508FDD8}!RdsRDCLIENT!0xffffffff!0xf' 	# rdpxclient
	'{ea605ac7-d9de-434a-8271-682fee6d59ca}!RdsRDCLIENT!0xffffffff!0xf' 	# RemoteFX Codec
	'{080656C2-C24F-4660-8F5A-CE83656B0E7C}!RdsRDCLIENT!0xffffffff!0xf' 	# ClientCore
	'{7211AE02-1EB0-454A-88FA-EA16632DCB45}!RdsRDCLIENT!0xffffffff!0xf' 	# TS USB Filter
	'{8C74CED2-9899-4E01-A6D2-F924045DE932}!RdsRDCLIENT' 					# rendrdp.dll
	'{cbdedbe0-b5c2-4ff6-905b-7a5ec0ebf8ed}!RdsRDCLIENT' 					# radcui.dll
	'{C3B02229-FF93-4D28-ACFC-4FB28AC6CDB5}!RdsRDCLIENT' 					# rdclientwinrt.dll
	'{91A2900E-DB4C-41E9-A6D8-945F40451BB3}!RdsRDCLIENT' 					# RdClient.Windows.exe
	'{76de1e7b-74d9-585f-1f85-affa9242808c}!RdsRDCLIENT' 					# RDWin32ClientAxTelemetryProvider
	'{61dd194a-b8cb-4de5-a018-4c7f6f9e9988}!RdsRDCLIENT' 					# RDP.MSTSCTelemetry
	'{76de1e7b-74d5-575e-1f81-4ffe6a42777b}!RdsRDCLIENT' 					# RDWin32ClientAxTelemetryProvider
	'{7756e5a6-21b2-4c40-855e-88cf2b13c7cb}!RdsRDCLIENT' 					# RDP.MSTSCAXTelemetry
	'{660cfa71-2a70-4e80-bdf3-f1424919d01c}!RdsRDCLIENT' 					# Microsoft.RDS.RdClient.Client.FeedSubscription
	'{55184039-1cbe-4d35-9f9e-85d0075943df}!RdsRDCLIENT' 					# Microsoft.RDS.RADC.FeedSubscription
	'{48EF6C18-022B-4394-BEE5-7B822B42AE4C}!RdsRDCLIENT' 					# Microsoft.RDS.Windows.Client.MSRDC
	'{335934AA-6DD9-486C-88A5-F8D6A7D2BAEF}!RdsRDCLIENT' 					# Microsoft.RDS.Windows.Client.AX
	'{5F328364-2E3D-4F73-B099-0D5C839E32A0}!RdsRDCLIENT' 					# CredentialsPlugin
	'{93C56D9B-7FDB-4E06-8DED-26000EEE0F60}!RdsRDCLIENT'					# MSTSCFeedbackHub
	'{FB9FF164-54F0-43DD-BF86-1C761FAB3052}!RdsRDCLIENT'					# msrdcsh
	'{97A820E5-5F64-4573-8114-99B450D0B067}!RdsRDCLIENT'					# RDCoreApp
)
$UEX_RdsRdClientManProviders = @(
	'{28AA95BB-D444-4719-A36F-40462168127E}!RdsMAN-RDCLIENT!0x0!0xff' 		# Microsoft-Windows-TerminalServices-ClientActiveXCore
	'{1B8B402D-78DC-46FB-BF71-46E64AEDF165}!RdsMAN-RDCLIENT!0x0!0xff' 		# Microsoft-Windows-RemoteApp and Desktop Connections
	'{6E400999-5B82-475F-B800-CEF6FE361539}!RdsMAN-RDCLIENT!0x0!0xff' 		# Microsoft-Windows-TerminalServices-ClientUSBDevices
)

#RDGateway
$UEX_RdsRdGwProviders = @(
	'{6F539394-F34F-45FD-B4CA-BD5C547B0BCB}!RdsRDGW' 						# AaEdgeServiceTrace
	'{909ED641-D5EF-4299-B898-F13451A59F50}!RdsRDGW' 						# AaTsPPTrace
	'{EB4AC9D0-AE00-4963-8435-5163ABD35572}!RdsRDGW' 						# Microsoft.Windows.RemoteDesktop.Gateway
)
$UEX_RdsRdGwManProviders = @(
	'{4D5AE6A1-C7C8-4E6D-B840-4D8080B42E1B}!RdsMAN-RDGW' 					# Microsoft-Windows-TerminalServices-Gateway
)

#RDMS
$UEX_RdsRdmsProviders = @(
	'{1B9B72FC-678A-41C1-9365-824658F887E9}!RdsRDMS!0xffffffff!0xf' 		# RDMS (RD Managment Service)
	'{9F58B00C-09C7-4cbc-8D19-969DCD5D5A6D}!RdsRDMS!0xffffffff!0xf' 		# MMC Snapin
)
$UEX_RdsRdmsManProviders = @(
	'{05da6b40-219e-4f17-92e6-d663fd87cba8}!RdsMAN-RDMS!0x0!0xff' 			# Microsoft-Windows-Remote-Desktop-Management-Service
	'{fb750ad9-8544-427f-b284-8ed9c6c221ae}!RdsMAN-RDMS!0x0!0xff' 			# Microsoft-Windows-Rdms-UI
)

#MultiPoint
$UEX_RdsMultiPointProviders = @(
	'{302383D5-5DC2-4BEA-AC7E-4154A1272583}!RdsMULTIPOINT'					# Microsoft.Windows.RemoteDesktop.MultiPoint
)

#RDLicenseServer
$UEX_RdsRdLserverProviders = @(
	'{A489F3D1-F149-4968-BDCE-4F7D93516DA8}!RdsLSERVER!0xffffffff!0xf'		# lserver
	'{da539211-d525-422a-8a92-bcbe4367159c}!RdsLSERVER' 					# Microsoft.Windows.RemoteDesktop.RDSLSTelemetry
	'{F8FCF9E0-535A-4BA6-975F-7AC82FBDC631}!RdsLSERVER' 					# TLSBrandTrace / TLSWmiTrace
	'{A489F3D1-F149-4968-BDCE-4F7D93516DA9}!RdsLSERVER!0xffffffff!0xf'		# lserver
)
$UEX_RdsRdLserverManProviders = @(
	'{4D99F017-0EB1-4B52-8419-14AEBD13D770}!RdsMAN-LSERVER!0x0!0xff' 		# Microsoft-Windows-TerminalServices-Licensing
)

#rdp clipboard
$UEX_RdsRdpClipProviders = @(
	'{796F204A-44FC-47DF-8AE4-77C210BD5AF4}!RdsRDPCLIP' 					# RDPCLIP
)

#rdpcore
$UEX_RdsRdpCoreProviders = @(
	'{D4199645-41BE-4FD5-9D73-A612C508FDC6}!RdsRDPCORE!0xffffffff!0xff' 	# RdpCoreTS
	'{140C2428-F60D-43F9-9B07-3E5F622438A0}!RdsRDPCORE!0xffffffff!0xff' 	# RdpCoreTS
	'{97e97a1e-c0a9-4b8d-87c4-42105a957d7b}!RdsRDPCORE!0xffffffff!0xff' 	# RdsDWMDirect
	'{62F277AE-2CCF-4AA9-A8AA-32752200BC18}!RdsRDPCORE' 					# CtDwm
	'{5795AAB9-B0E3-419E-B0EF-7AEF943CFFA8}!RdsRDPCORE!0xffffffff!0xff' 	# Microsoft.Windows.RemoteDesktop.Base
	'{8375996D-5801-4FE9-B0AE-F5C428758960}!RdsRDPCORE!0xffffffff!0xff' 	# Microsoft.Windows.RemoteDesktop.ServerBase
	'{7b7a87d4-6d7c-4c87-8e3d-29f31bff02b8}!RdsRDPCORE!0xffffffff!0xff' 	# Microsoft.Windows.Rdp.Graphics.RdpIdd
	'{D92BCB52-FA78-406F-A9A5-2037509FADEA}!RdsRDPCORE!0xffffffff!0xff' 	# DxKernel Indirect Display: IddCx
	'{AFC8A033-E28A-415C-ACFF-030E4B113A35}!RdsRDPCORE!0xffffffff!0xff' 	# Microsoft.Streaming.Basix
	'{3d491de6-531b-3b95-9404-e13c072c5a6c}!RdsRDPCORE!0xffffffff!0xff' 	# TermSrv:ThreadPool
	'{3bf63c52-b1bd-3bd7-4dd0-af57fba7d43d}!RdsRDPCORE!0xffffffff!0xff' 	# TermSrv:tscryptutils
	'{C5615DDA-2DAC-479B-83AB-F18C95601774}!RdsRDPCORE!0xffffffff!0xff' 	# RdpInput (Replaces TermDD in 2012 R2)
	'{fb750ad9-8544-427f-b284-8ed9c6c221ae}!RdsRDPCORE!0x0!0xff' 			# Microsoft-Windows-Rdms-UI
	'{6CBE573A-121B-4E02-A09D-6C0B6B96D676}!RdsRDPCORE' 					# RDP.ServerStack.QOE
	'{1139c61b-b549-4251-8ed3-27250a1edec8}!RdsRDPCORE!0x0!0xff' 			# Microsoft-Windows-RemoteDesktopServices-RdpCoreTS
	'{C1BB27C2-F176-499C-A932-D453051E8B0B}!RdsRDPCORE'                 	# rdpcorets.dll
	'{c8e6dc53-660c-44ee-8d00-e47f189db87f}!RdsRDPCORE' 					# Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV
	'{D4199645-41BE-4FD5-9D71-A612C508FDC6}!RdsRDPCORE' 					# RDPApiTrace
	'{28AA9132-5ED1-46B9-916A-FD24C188C316}!RdsRDPCORE' 					# rdpnotify.exe
	'{3C734565-80DB-4168-8B16-B15393154F69}!RdsRDPCORE' 					# rdvcloud.dll
	'{16e72985-266a-490e-8523-fb5ff5da188e}!RdsRDPCORE' 					# rdpavenc.dll
	'{7b919abb-998b-46a9-b8f3-d4a49e8074da}!RdsRDPCORE'						# rdpnano.dll
	'{05875a0b-efdf-4c4a-8d3c-098a15dc483d}!RdsRDPCORE' 					# mohoroGateway.dll
	'{8A99FD17-7D82-45D9-A965-F9A3F9FA85E5}!RdsRDPCORE' 					# RdpFilterTrace
	'{26771A7F-04D4-4597-BBF6-3AF9F7818B25}!RdsRDPCORE' 					# Microsoft.Windows.RemoteDesktop.Virtualization
	'{F115DDAF-E07E-4B15-9721-427134B41EBA}!RdsRDPCORE' 					# RDP(RDPEncryption)
	'{a8f457b8-a2b8-56cc-f3f5-3c00430937bb}!RdsRDPCORE' 					# RDP(RDPEmulation)
	'{8A633D91-8B07-4AAE-9A00-D07E2AFD29D6}!RdsRDPCORE' 					# RDP.Transport
	'{10AB3154-C36A-4F24-9D91-FFB5BCD331EF}!RdsRDPCORE' 					# Microsoft-Windows-RemoteDesktopServices-RemoteFX-SessionLicensing(LSClientService.dll)
	'{8bddcf41-9630-47e8-914a-d4952112ea19}!RdsRDPCORE' 					# Microsoft-Windows-RemoteDesktopServices-RemoteFX-SessionManager(rdvgsm.dll)(WS2012R2 or earlier)
	'{7bfcf102-7378-431c-9284-0b968258991a}!RdsRDPCORE' 					# Microsoft-Windows-RemoteDesktopServices-RemoteDesktopSessionManager(RDPWD.sys)(WS2012 or ealier)
	'{48DAB7B6-34F4-44C8-8355-35124FE39BFF}!RdsRDPCORE' 					# RdpXTraceProvider
	'{CC3716F0-0336-44FB-A442-86276F4B712C}!RdsRDPCORE' 					# RdpWinTraceProvider
	'{28711274-D721-465E-9C7E-D359422E96CD}!RdsRDPCORE' 					# lsclientservice
	'{26C7EAC9-9675-43CB-9EF1-B9CD4564595F}!RdsRDPCORE' 					# lscspolicyloader
	'{97166ECD-4F97-442F-A909-9EB9AE6D2458}!RdsRDPCORE' 					# lscsvmbuspipechannel
	'{15D9261C-EFDF-4C4A-8D3C-098A15DC483D}!RdsRDPCORE' 					# RdpNetEmu*
	'{3EF15ADF-1300-44A1-B85C-2A83549F5B9E}!RdsRDPCORE' 					# Microsoft.Windows.RemoteDesktop.Legacy*
	'{0B938561-4D72-4312-ACF6-109D34C26148}!RdsRDPCORE' 					# CMProxyGuest*
	'{5CE9C675-02A0-4B9D-89E6-77C13EF68E75}!RdsRDPCORE' 					# CMProxyHost*
	'{59906E55-0817-4CDA-BA3B-D34E33ED4EE7}!RdsRDPCORE' 					# TokenValTrace*
	'{6E530C0D-677F-488B-B163-0415CB65883D}!RdsRDPCORE' 					# VMMWSFilterPluginTrace*
	'{6FA2A01C-9F89-474B-A71A-A783925EFE45}!RdsRDPCORE'						# RDCoreNanoCom
	'{50134CDD-5FE1-4315-8C8D-50900921ACCE}!RdsRDPCORE'						# Microsoft.Windows.HVSI.RDP
	'{eb6594d8-6fad-53f7-350e-f4e4c531f68c}!RdsRDPCORE'						# Microsoft.Windows.RDP.NamedPipe
	'{4f50731a-89cf-4782-b3e0-dce8c90476ba}!RdsRDPCORE'						# Microsoft Telemetry provider group
)

#rdpdr
$UEX_RdsRdpDrProviders = @(
	'{A0674FB6-BA0D-456F-B079-A2B029D8342C}!RdsRDPDR!0xffffffff!0xf' 		# TS USB Hub
	'{39A585FF-6C36-492B-93C0-35B71E65A345}!RdsRDPDR!0xffffffff!0xf' 		# TS USB Generic Device
	'{73C5EC49-C807-489D-9E45-D36D72235F84}!RdsRDPDR!0xffffffff!0xf' 		# UMRDPTrace
	'{82A94E1C-C1B3-4E4A-AC87-43BD802E458E}!RdsRDPDR!0xffffffff!0xf' 		# KernVc - KernUtil
	'{73BFB78F-12B5-4738-A66C-A77BCD55FA12}!RdsRDPDR!0xffffffff!0xf' 		# Rdpdr Sys
	'{600be610-f0e8-4912-b397-d2cc76060114}!RdsRDPDR!0xffffffff!0xf' 		# USBDRTrace
	'{3f7b2f99-b863-4045-ad05-f6afb62e7af1}!RdsRDPDR' 						# Microsoft-Windows-TerminalServices-MediaRedirection(tsmf.dll)
	'{b1c94ed9-ac9b-410e-aa48-4ffc5e45f4e3}!RdsRDPDR' 						# Microsoft-Windows-TerminalServices-MediaRedirection-DShow(DShowRdpFilter.dll) (WS2008R2)
	'{48738267-0545-431D-8087-7349127811D0}!RdsRDPDR' 						# TSUsbRedirectionServiceTrace
	'{A1F3B16A-C510-41C1-8B58-E695880F3A80}!RdsRDPDR' 						# tsscan
	'{C14F3000-0B2D-4464-99AC-FA764AF708CF}!RdsRDPDR' 						# rdpbus
	'{ECA5427C-F28F-4942-A54B-7E86DA46BDBE}!RdsRDPDR' 						# TSUrbUtils
)

#RDSH
$UEX_RdsRdshProviders = @(
	'{D33E545F-59C3-423F-9051-6DC4983393A8}!RdsRDSH!0xffffffff!0xff' 		# Winsta Client (API)
	'{0046a6b4-a24c-40d5-b0e6-c8ec031bd82a}!RdsRDSH!0xffffffff!0xff' 		# TS RPC
	'{40423FDC-C9EC-4D34-9E72-8DE793CDB22E}!RdsRDSH!0xffffffff!0xf'    		# RDPCore KMTS
	'{557D257B-180E-4AAE-8F06-86C4E46E9D00}!RdsRDSH!0xffffffff!0xf'    		# Local Session Manager (LSM)
	'{5283D5F6-65B5-425F-A30B-F16C057D6B57}!RdsRDSH!0xffffffff!0xf'    		# Remote Connection Manager (TermService)
	'{449E4E69-329E-4EB1-9DDF-809D17A2E0C1}!RdsRDSH!0xffffffff!0xf'    		# Broker 'Client' (on RDSH)
	'{986CC918-7434-4FAB-B37F-C4BA7AD1E293}!RdsRDSH!0xffffffff!0xf'    		# Broker 'Server' (on RDSH)
	'{9ed727c4-4ab6-4b66-92d7-2072e87c9124}!RdsRDSH!0x1ff!0xf'		 		# CM Licensing (tssrvlic)
	'{ae8ab061-654e-4d72-9f4b-c799ba919ec8}!RdsRDSH!0x1ff!0xf' 				# RD Message Server (SessionMsg)
	'{59de359d-ec83-445c-9323-b75e2056d5a5}!RdsRDSH!0xffff!0xf' 	    	# Session Configuration (SessionEnv)
	'{9EA2030F-DB66-47EF-BF2C-619CC76F3E1B}!RdsRDSH!0x0!0xff' 			 	# RCM Licensing Policy (LSCSHostPolicy)
	'{D2E990DA-8504-4702-A5E5-367FC2F823BF}!RdsRDSH!0xffffffff!0xff' 	 	# RdpAppXHelp
	'{C0C89C53-DD3F-4782-00A7-8F537811A835}!RdsRDSH!0xffffffff!0xff' 	 	# Net Fair Share (RdpNetFS)
	'{588F5E4C-6853-4FCB-BD7D-75F926276C20}!RdsRDSH' 	 					# TSAllowTrace
	'{C6FDD8E3-770B-4964-9F0C-227457146B49}!RdsRDSH' 						# RDP(SessEnvRpcTelemetry)
	'{89d48904-939f-4177-aad4-2fdb26b8329f}!RdsRDSH' 						# Microsoft.Windows.RemoteDesktop.RDSHFarm.UVhd
	'{D9F94C5A-94F8-4CD0-A054-A1EE67A2DA6B}!RdsRDSH' 						# Microsoft.Windows.RemoteDesktop.SessionHost
	'{997FB36F-0208-4ED7-865B-E19816C3782D}!RdsRDSH' 						# Microsoft.Windows.RemoteDesktop.SessionConfig(From WS2019)
	'{78be48bd-5d52-4e39-823d-226cd5551f37}!RdsRDSH' 						# RDP.ServerStack(From WS2019)
	'{CA341B3C-B9D2-4D0F-9BD3-D88183596DB9}!RdsRDSH' 						# RDP.ServerStack.Diagnostics(From WS2019)
	'{D2B9C1C5-0C37-47EB-AA79-CD0CF0CE2FA6}!RdsRDSH' 						# TSFairShare
	'{c0c89c53-dd3f-4782-a78f-5378111a8305}!RdsRDSH' 						# RDSNetFairshare
)
$UEX_RdsRdshManProviders = @(
	'{5D896912-022D-40AA-A3A8-4FA5515C76D7}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-LocalSessionManager
	'{27A8C1E2-EB19-463E-8424-B399DF27A216}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-PnPDevices
	'{952773BF-C2B7-49BC-88F4-920744B82C43}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-Printers
	'{C76BAA63-AE81-421C-B425-340B4B24157F}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-RemoteConnectionManager
	'{2184B5C9-1C83-4304-9C58-A9E76F718993}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-SessionBroker-Client
	'{4199EE71-D55D-47D7-9F57-34A1D5B2C904}!RdsMAN-RDSH!0x0!0xff' 			# TerminalServer-MediaFoundationPlugin
	'{32817E55-7BFE-45E0-AF68-A413FA6E0083}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-TSAppSrv-TSMSI
	'{f1394de0-32c7-4a76-a6de-b245e48f4615}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-RemoteDesktopServices-SessionServices
	'{1139c61b-b549-4251-8ed3-27250a1edec8}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-RemoteDesktopServices-RdpCoreTS
	'{741c6be3-f74b-4e4d-88e7-5ce3a35faeb3}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-RemoteDesktopServices-RemoteFX-VM-User-Mode-Transport
	'{127e0dc5-e13b-4935-985e-78fd508b1d80}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-RdpSoundDriver
	'{6BA29EDF-A2F4-4212-B06B-6D5712210652}!RdsMAN-RDSH!0xffffffff!0xf' 	# Microsoft-Windows-TerminalServices-TSAppSrv-TSVIP
	'{8d83aec0-01de-4772-a317-2093b6dc3bab}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-TSFairShare-Events
	'{c8e6dc53-660c-44ee-8d00-e47f189db87f}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV
	'{DCBE5AAA-16E2-457C-9337-366950045F0A}!RdsMAN-RDSH!0x0!0xff' 			# Microsoft-Windows-TerminalServices-PnPDevices
)

#RemoteFX
$UEX_RdsRdVgfxProviders = @(
	'{84214511-602B-4456-9CB9-7800ED3432F6}!RdsRDVGFX!0xffffffff!0xff' 		# RemoteFX Virtual Graphics Manager
	'{140C2428-F60D-43F9-9B07-3E5F622438A0}!RdsRDVGFX!0xffffffff!0xff' 		# RemoteFX Virtual Graphics Manager
	'{C51286E1-F923-404D-B68B-8D0DAB0976B0}!RdsRDVGFX!0xffffffff!0xff' 		# RemoteFX Virtual Graphics Manager
	'{F09A9A18-0C87-47AC-8A99-5C2D4BB82117}!RdsRDVGFX!0xffffffff!0xff' 		# RemoteFX Virtual Graphics Manager
	'{482F83D3-E8CB-4727-8A28-FC51544C5A28}!RdsRDVGFX!0xffffffff!0xff' 		# RemoteFX VM Bus (RdvVMXPort)
	'{8CDC2BE7-58CD-4760-B344-422B893BFF08}!RdsRDVGFX' 						# synth3dvsp.sys
	'{80342309-054F-4E2E-9D3D-FCCFBDCAA92F}!RdsRDVGFX' 						# rfxvmt.dll
	'{e76c0d10-97b8-477d-a0ae-e8fa5870a695}!RdsRDVGFX' 						# rdvgogl.dll
	'{1148F9BD-F5FF-482D-B08A-F289F3E928E0}!RdsRDVGFX' 						# rdvgocl.dll
	'{0c79e960-6bd5-4206-bf5d-578cedb8df2a}!RdsRDVGFX' 						# rdvgumd.dll
	'{6CDD992D-B35C-40A6-AF1E-D727C11DECFD}!RdsRDVGFX' 						# rdvgkmd.exe
	'{6AABAEA6-DF19-4528-97D8-3A420CEE69A0}!RdsRDVGFX' 						# rdvgu11.dll
	'{2A11472B-451F-4FCA-8590-9724D41C604E}!RdsRDVGFX' 						# RDVVGHelper
	'{432EEF91-C605-482B-83BE-0963604F1397}!RdsRDVGFX' 						# RDVGSMSTrace (WS2012R2 or earlier)
	'{62F277AE-2CCF-4AA9-A8AA-32752200BC18}!RdsRDVGFX' 						# CtDwm
	'{204AE8F0-42F7-4A13-97CD-B490927CB725}!RdsRDVGFX' 						# Microsoft.Windows.VGPU.RDVGM
	'{D953B8D8-7EA7-44B1-9EF5-C34AF653329D}!RdsRDVGFX' 						# RDP.Graphics(From WS2019)
	'{9512fdbc-24e6-44fa-a8a3-af44d3447216}!RdsRDVGFX' 						# RDP.Graphics(From WS2019)
	'{E80ADCF1-C790-4108-8BB9-8A5CA3466C04}!RdsRDVGFX' 						# Microsoft-Windows-TerminalServices-RDP-AvcSoftwareDecoder(From WS2019)
	'{1B4F0E96-6876-49c8-BFBA-072DAE6543B3}!RdsRDVGFX' 						# Microsoft-Windows-RemoteDesktopServices-vGPU-KModeDriver(rdvgkmd.sys)
	'{5AE63087-6A35-40b0-AE15-CEA95A71A8C0}!RdsRDVGFX' 						# Microsoft-Windows-RemoteDesktopServices-vGPU-UModeDriver(rdvgumd32.dll)
	'{1deb930f-e136-4b08-9761-d7e3a5d14faa}!RdsRDVGFX' 						# Microsoft-Windows-RemoteDesktopServices-vGPU-UModeDriver64(rdvgumd64.dll)
	'{3f7b2f99-b863-4045-ad05-f6afb62e7af1}!RdsRDVGFX' 						# Microsoft-Windows-TerminalServices-MediaRedirection(tsmf.dll)
	'{b1c94ed9-ac9b-410e-aa48-4ffc5e45f4e3}!RdsRDVGFX' 						# Microsoft-Windows-TerminalServices-MediaRedirection-DShow(DShowRdpFilter.dll) (WS2008R2)
	'{0C38D54D-EF5F-4179-95FA-6D4EDA073000}!RdsRDVGFX' 						# RDVVGHelperSerivce (WS2012R2 or earlier)
	'{4BDD50B0-BF12-4991-8B11-C455F14289DB}!RdsRDVGFX' 						# rdpvideominiport
)
$UEX_RdsRdVgfxManProviders = @(
	'{10D520E2-205C-4C22-B25C-AC7A779C55B2}!RdsMAN-RDVGFX!0x0!0xff' 		# Microsoft-Windows-RemoteDesktopServices-RemoteFX-Manager
)

#Virtual IP
$UEX_RdsVipProviders = @(
	'{508371b1-7651-4b33-4b33-5884f824bd1b}!RdsVIP!0xffffffff!0xf' 			# IP Virtualization 'Client' (TSVIPCli)
	'{AE4C5843-A9A3-4EB9-81F3-65D57D250180}!RdsVIP!0xffffffff!0xf' 			# IP Virtualization Pool (TSVIPPool)
	'{bd5c97d6-3d8f-5779-7872-09ad6dcad49b}!RdsVIP!0xffffffff!0xff' 		# Microsoft.Windows.Rds.VirtualIP.Driver
	'{6BA29EDF-A2F4-4212-B06B-6D5712210652}!RdsVIP!0xffffffff!0xf' 			# Microsoft-Windows-TerminalServices-TSAppSrv-TSVIP
	'{00508371-7651-4b33-4b33-5884f824bd1b}!RdsVIP' 						# TSVIPCli
	'{0ba29edf-a2f4-4212-b06b-6d5712210652}!RdsVIP' 						# TSVIPSrv
)

#vmagent (Hyper-V host for VDI)
$UEX_RdsVmAgentProviders = @(
	'{2A0A7EC8-5E2B-47AB-B553-32E1C7AEF0EF}!RdsVMAGENT!0xffffffff!0xf'		# VmHostAgentTrace
)
$UEX_RdsVmAgentManProviders = @(
	'{92618A87-2F6A-4B75-9AE2-E77BE7EAF43C}!RdsMAN-VMAGENT!0x0!0xff'		# VmHostAgentTrace
)

#WMI/WinRM
$UEX_RdsWmiProviders = @(
	'{8E6B6962-AB54-4335-8229-3255B919DD0E}!RdsWMI!0x1!0xf' 				# WMI Client
	'{1ff6b227-2ca7-40f9-9a66-980eadaa602e}!RdsWMI!0x7!0xf' 				# WMI Verbose
	'{7ADA0B31-F4C2-43F4-9566-2EBDD3A6B604}!RdsWMI!0xffffffff!0xf' 			# TSCPUBSvr.dll
	'{81B84BCE-06B4-40AE-9840-8F04DD7A8DF7}!RdsWMI!0xffffffff!0xf' 			# TSCPubWmiProvider
	'{E43CAB68-0AB4-4F47-BF30-E61CAC7BBD8A}!RdsWMI' 						# TSPublishingWmiProvider
	'{F8FCF9E0-535A-4BA6-975F-7AC82FBDC631}!RdsWMI' 						# TLSBrandTrace / TLSWmiTrace
)
$UEX_RdsWmiManProviders = @(
	'{1418EF04-B0B4-4623-BF7E-D74AB47BBDAA}!RdsMAN-WMI!0x0!0xff' 			# Microsoft-Windows-WMI-Activity
)
$UEX_RdsWmiWinRmManProviders = @(
	'{A7975C8F-AC13-49F1-87DA-5A984A4AB417}!RdsMAN-WMI-WinRM!0x0!0xff' 		# Microsoft-Windows-WinRM
	'{1EDEEE53-0AFE-4609-B846-D8C0B2075B1F}!RdsMAN-WMI-WinRM!0x0!0xff' 		# Microsoft-Windows-WMI
)

#Workspace
$UEX_RdsWrkspcProviders = @(
	'{70A43AE8-E131-42BD-89E0-23704FB27C6A}!RdsWRKSPC!0xffffffff!0xf' 		# Client RDWeb Workspace Proxy
	'{070f54b9-7eb0-4c99-8dfa-2aa8d8ab0d89}!RdsWRKSPC!0xffffffff!0xf' 		# Client Workspace (RemoteApp & Desktop Connections/RDWeb SSO) (tsworkspace)
	'{3D3E7039-99CF-4446-8C81-4AD5A8560E7B}!RdsWRKSPC!0xffffffff!0xf' 		# Client Workspace (RemoteApp & Desktop Connections/RDWeb SSO) (wkspbroker)
	'{3D3E7039-99DF-4446-8C81-4AD5A8560E7B}!RdsWRKSPC' 						# wkspbroker.exe
	'{3E3E7039-99DF-4446-8C81-4AD5A8560E7B}!RdsWRKSPC' 						# WorkspaceBrokerAxTrace(wkspbrokerAx.dll)
	'{3C3E7039-99CF-4446-8D81-4AC5A8560E7B}!RdsWRKSPC' 						# WorkspaceRuntimeTrace(wksprt.exe)
)
#endregion--- RDS PROVIDERS ---#


#region---  UE-V PROVIDERS ---#
$UEX_UEVProviders = @(
	"{1ED6976A-4171-4764-B415-7EA08BC46C51}" # Microsoft-User Experience Virtualization-App Agent
	"{21D79DB0-8E03-41CD-9589-F3EF7001A92A}" # Microsoft-User Experience Virtualization-IPC
	"{57003E21-269B-4BDC-8434-B3BF8D57D2D5}" # Microsoft-User Experience Virtualization-SQM Uploader
	"{61BC445E-7A8D-420E-AB36-9C7143881B98}" # Microsoft-User Experience Virtualization-Admin
	"{e4dda0af-d7b4-5d40-4174-4d0be05ae338}" # Microsoft.Windows.AppMan.UEV
)
#endregion---  UE-V PROVIDERS ---#


#region--- PROVIDER GROUPS ---#

#AVD
$UEX_AvdCommonProviders = @(
	$UEX_RdsAuthProviders			#
	$UEX_RdsAuthManProviders		#
	$UEX_RdsRdpCoreProviders
	$UEX_AvdRDWebRTCProviders
)

$UEX_AvdCliProviders = @(
	$UEX_RdsRdClientProviders		#
	$UEX_RdsRdClientManProviders	#
)

$UEX_AvdSrvProviders = @(
	$UEX_RdsAudioProviders
	$UEX_RdsHypervManProviders
	$UEX_RdsPrintSpoolProviders		#
	$UEX_RdsPrintSpoolManProviders	#
	$UEX_RdsRailProviders
	$UEX_RdsRdLserverProviders		#
	$UEX_RdsRdLserverManProviders	#
	$UEX_RdsRdpClipProviders
	$UEX_RdsRdpDrProviders
	$UEX_RdsRdshProviders				#
	$UEX_RdsRdshManProviders			#
	$UEX_RdsRdVgfxProviders			#
	$UEX_RdsRdVgfxManProviders		#
	$UEX_RdsUsrLogonProviders			#
	$UEX_RdsUsrLogonManProviders		#
	$UEX_RdsWmiProviders				#
	$UEX_RdsWmiManProviders				#
	$UEX_RdsWmiWinRmManProviders
	$UEX_FSLogixProviders
)

#RDS
$UEX_RdsCommonProviders = @(
	$UEX_RdsAuthProviders			#
	$UEX_RdsAuthManProviders		#
	$UEX_RdsRdpCoreProviders
)

$UEX_RdsCliProviders = @(
	$UEX_RdsRdClientProviders		#
	$UEX_RdsRdClientManProviders	#
	$UEX_RdsWrkspcProviders
)

$UEX_RdsSrvProviders = @(
	$UEX_RdsAppPubProviders
	$UEX_RdsAudioProviders
	$UEX_RdsHypervManProviders
	$UEX_RdsMultiPointProviders
	$UEX_RdsPrintSpoolProviders		#
	$UEX_RdsPrintSpoolManProviders	#
	$UEX_RdsRailProviders
	$UEX_RdsRdBrokerProviders			#
	$UEX_RdsRdBrokerManProviders		#
	$UEX_RdsRdGwProviders			#
	$UEX_RdsRdGwManProviders		#
	$UEX_RdsRdmsProviders				#
	$UEX_RdsRdmsManProviders			#
	$UEX_RdsRdLserverProviders		#
	$UEX_RdsRdLserverManProviders	#
	$UEX_RdsRdpClipProviders
	$UEX_RdsRdpDrProviders
	$UEX_RdsRdshProviders				#
	$UEX_RdsRdshManProviders			#
	$UEX_RdsRdVgfxProviders			#
	$UEX_RdsRdVgfxManProviders		#
	$UEX_RdsUsrLogonProviders			#
	$UEX_RdsUsrLogonManProviders		#
	$UEX_RdsVipProviders
	$UEX_RdsVmAgentProviders		#
	$UEX_RdsVmAgentManProviders		#
	$UEX_RdsWmiProviders				#
	$UEX_RdsWmiManProviders				#
	$UEX_RdsWmiWinRmManProviders
	$UEX_FSLogixProviders
)
#endregion--- PROVIDER GROUPS ---#


#region--- OTHER PROVIDERS ---#

#region---  DS PROVIDERS ---#
$UEX_LogonProviders = @(
	'{D451642C-63A6-11D7-9720-00B0D03E0347}' # WinLogon
	'{a789efeb-fc8a-4c55-8301-c2d443b933c0}' # UmsHlpr
	'{301779e2-227d-4faf-ad44-664501302d03}' # WlClNtfy
	'{5B4F9E61-4334-409F-B8F8-73C94A2DBA41}' # Userinit
	'{c2ba06e2-f7ce-44aa-9e7e-62652cdefe97}' # WinInit
	'{855ed56a-6120-4564-b083-34cb9d598a22}' # SetupLib
	'{d138f9a7-0013-46a6-adcc-a3ce6c46525f}' # WMsgSrv
	'{19d78d7d-476c-47b6-a484-285d1290a1f3}' # SysNtfy
	'{557D257B-180E-4AAE-8F06-86C4E46E9D00}' # LSM
	'{EB7428F5-AB1F-4322-A4CC-1F1A9B2C5E98}' # UserProfileService
	'{9891e0a7-f966-547f-eb21-d98616bf72ee}' # Microsoft.Windows.Shell.UserProfiles
	'{9959adbd-b5ac-5758-3ffa-ee0da5b8fe4b}' # Microsoft.Windows.ProfileService
	'{40654520-7460-5c90-3c10-e8b6c8b430c1}' # Microsoft.Windows.ProfExt
	'{D33E545F-59C3-423F-9051-6DC4983393A8}' # winsta
	'{b39b8cea-eaaa-5a74-5794-4948e222c663}' # Microsoft.Windows.Security.Winlogon
	'{8db3086d-116f-5bed-cfd5-9afda80d28ea}' # Microsoft-OSG-OSS-CredProvFramework
	'{5AA2DC10-E0E7-4BB2-A186-D230D79442D7}' # Microsoft.CAndE.ADFabric.CDJ.Recovery
	'{7ae961f7-1262-48e2-b237-acba331cc970}' # Microsoft.CAndE.ADFabric.CDJ.AzureSecureVMJoin
	'{fb3cd94d-95ef-5a73-b35c-6c78451095ef}' # Microsoft.Windows.CredProvDataModel
	'{a6c5c84d-c025-5997-0d82-e608d1abbbee}' # Microsoft.Windows.CredentialProvider.PicturePassword
	'{41ad72c3-469e-5fcf-cacf-e3d278856c08}' # Microsoft.Windows.BlockedShutdown
	'{df350158-0f8f-555d-7e4f-f1151ed14299}' # Microsoft.Windows.BioFeedback
	'{D33E545F-59C3-423F-9051-6DC4983393A8}' # winsta
	'{557D257B-180E-4AAE-8F06-86C4E46E9D00}' # LSM(From WS2019)
	'{4f7c073a-65bf-5045-7651-cc53bb272db5}' # Microsoft.Windows.LogonController
	'{3ec987dd-90e6-5877-ccb7-f27cdf6a976b}' # Microsoft.Windows.LogonUI.WinlogonRPC
	'{c0ac3923-5cb1-5e37-ef8f-ce84d60f1c74}' # Microsoft.Windows.TSSessionUX
	'{DBE9B383-7CF3-4331-91CC-A3CB16A3B538}' # Microsoft-Windows-Winlogon(Manifest)
	'{63D2BB1D-E39A-41b8-9A3D-52DD06677588}' # Microsoft-Windows-Shell-AuthUI(credprovhost.dll)
	'{DB00DFB6-29F9-4A9C-9B3B-1F4F9E7D9770}' # Microsoft-Windows-User Profiles General
	'{89B1E9F0-5AFF-44A6-9B44-0A07A7CE5845}' # Microsoft-Windows-User Profiles Service
	'{B059B83F-D946-4B13-87CA-4292839DC2F2}' # Microsoft-Windows-User-Loader
	'{EEA178E3-E9D4-41CA-BB56-CEDE1A476629}' # Microsoft-Windows-User-PnP
	'{1941DE80-2226-413B-AFA4-164FD76914C1}' # Microsoft.Windows.Desktop.Shell.WindowsUIImmersive.LockScreen
	'{176cd9c5-c90c-5471-38ba-0eeb4f7e0bd0}' # Microsoft.Windows.UI.Logon
	'{74cc4a0b-f577-5929-abcb-aa4bea374cb3}' # Microsoft.Windows.Shell.LockAppHost
	'{f8e28969-b1df-57fa-23f6-42260c77135c}' # Microsoft.Windows.ImageSanitization
	'{1915117c-a61c-54d4-6548-56cac6dbfede}' # Microsoft.Windows.Shell.AboveLockActivationManager
	'{e58f5f9c-3abb-5fc1-5ae5-dbe956bdbd33}' # Microsoft.Windows.Shell.AboveLockShellComponent
	'{b2149bc3-9dfd-5866-92a7-b556b3a6aed0}' # Microsoft.Windows.Shell.DefaultLockApp
	'{9ca921e3-25a4-5d34-39da-a59bd8bdf7a2}' # Microsoft.Windows.Shell.LockAppBroker
	'{b93d4107-dc22-5d11-c2e1-afba7a88d694}' # Microsoft.Windows.Shell.Tracing.LockAppBroker
	'{96319132-2f52-5969-f14c-0d0a171b357a}' # Microsoft.Windows.Shell.LockFrameworkUAP
	'{4191edaf-80c5-5ae3-49aa-325bd25cab2e}' # Microsoft.Windows.ComposableShell.Components.LockScreenHost.LockScreenShow
	'{355d4f62-3d5b-5372-213f-6d9d804c75df}' # Microsoft.Windows.AssignedAccess.MdmAlert
	'{94097d3d-2a5a-5b8a-cdbd-194dd2e51a00}' # Microsoft.Windows.AssignedAccess
	'{8530DB6E-51C0-43D6-9D02-A8C2088526CD}' # Microsoft-Windows-AssignedAccess
	'{F2311B48-32BE-4902-A22A-7240371DBB2C}' # Microsoft-Windows-AssignedAccessBroker
	'{5e85651d-3ff2-4733-b0a2-e83dfa96d757}' # UserMgrSvcTraceLoggingProvider
	'{077b8c4a-e425-578d-f1ac-6fdf1220ff68}' # Microsoft.Windows.Security.TokenBroker
	'{7acf487e-104b-533e-f68a-a7e9b0431edb}' # Microsoft.Windows.Security.TokenBroker.BrowserSSO
	'{BB86E31D-F955-40F3-9E68-AD0B49E73C27}' # Microsoft-Windows-User-UserManager-Events
	'{076a2c5c-40e9-5a75-73b0-8d7697c282b2}' # Microsoft.Windows.Security.Vault.RoamingSecurity
	'{a15c1ac4-a508-59ae-3158-275f96f30cb8}' # Microsoft.Windows.Security.Vault.Roaming
	'{98177d7f-7d3a-51ef-2d41-2414bb2c0bdb}' # Microsoft.Windows.Security.Wininit
	'{1ef1b3bd-ba20-5fd6-68c1-beb652b5d0c2}' # Microsoft.Windows.Shell.LockScreenContent
	'{b45275fa-3b9c-40f2-aaad-10060f77f0c0}' # Microsoft.Windows.Shell.CloudExperienceHost.DatVPrep
	'{F1C13488-91AC-4350-94DE-5F060589C584}' # Microsoft.Windows.Shell.LockScreenBoost
	'{3D14CA27-6EB2-4789-9B52-33EC88ECF5B0}' # Microsoft.Windows.Shell.LockScreenData
	'{1f44367c-cd89-5c01-ad03-bf60b9588564}' # Microsoft.Windows.LockAppBroker
	'{be69781c-b63b-41a1-8e24-a4fc7b3fc498}' # Microsoft-Windows-Sens
	'{A0CA1D82-539D-4FB0-944B-1620C6E86231}' # Microsoft-Windows-Sens/Debug
	'{2D710779-B24B-4ADB-81EF-CD6DED5A9B2A}' # Microsoft.Windows.Shell.LockScreenController
	'{75816B5C-ECD1-4DBC-B38A-47A9646E60BE}' # Microsoft.Windows.Shell.LockScreenExperienceManager
	'{68767976-7ddc-57d7-4318-9a6db4625165}' # Microsoft.Windows.Shell.WelcomeScreen
)

$UEX_KerberosProviders = @(
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' # Kerberos
	)

$UEX_AuthProviders = @(
	'{6165F3E2-AE38-45D4-9B23-6B4818758BD9}' # TSPkg
	'{37D2C3CD-C5D4-4587-8531-4696C44244C8}' # schannel(schannel.dll)
	'{5BBB6C18-AA45-49B1-A15F-085F7ED0AA90}' # NTLM
	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' # Kerberos
	'{BBA3ADD2-C229-4CDB-AE2B-57EB6966B0C4}' # Kerberos Client
	'{CC85922F-DB41-11D2-9244-006008269001}' # LSA
	'{F33959B4-DBEC-11D2-895B-00C04F79AB69}' # NetLogon
	'{C5D1EB66-79E9-47C3-A578-A6F25DA14D49}' # SpapiWBLog
	'{5bbca4a8-b209-48dc-a8c7-b23d3e5216fb}' # Microsoft-Windows-CAPI2(crypt32.dll)
	'{1f678132-5938-4686-9fdc-c8ff68f15c85}' # Schannel(lsasrv.dll)
	'{91CC1150-71AA-47E2-AE18-C96E61736B6F}' # Microsoft-Windows-Schannel-Events(Manifest)
	'{4C88AF3D-5D47-458A-8624-515C122B7188}' # Microsoft.Windows.OneCoreUap.Shell.Auth.CredUX
	'{4b8b1947-ae4d-54e2-826a-1aee78ef05b2}' # Microsoft.Windows.WinBioDataModel
	'{a55d5a23-1a5b-580a-2be5-d7188f43fae1}' # Microsoft.Windows.Shell.BioEnrollment
	'{DC3B5BCF-BF7B-42CE-803C-71AF48F0F546}' # Microsoft.Windows.CredProviders.PasswordProvider
	'{fb3cd94d-95ef-5a73-b35c-6c78451095ef}' # Microsoft.Windows.CredProvDataModel
	'{5a4dad98-5dce-5efb-a9b2-54e8de8af594}' # Microsoft.Windows.Shell.Auth.LocalServiceCredUIBroker
	'{3bb1472f-46dc-5a12-4916-25706f703352}' # Microsoft.Windows.CredDialogBroker
	'{f2018623-63ac-5837-7cfb-f67ec5c39961}' # Microsoft.Windows.Shell.CredDialogHost
	'{d30325be-5b5e-508c-d76a-2d5e5fe60a5c}' # Microsoft.Windows.CredentialEnrollmentManager
	'{f245121c-b6d1-5f8a-ea55-498504b7379e}' # Microsoft.Windows.DeviceLockSettings
	'{350b80a3-32c3-47b3-9e58-32e5a48ce66f}' # Microsoft.Windows.SuggestedUsersDataModel
	'{c11d96bf-1615-4d64-ada3-5803cdbac698}' # Microsoft.Windows.Shell.Auth.CredUI
	'{1D86A602-D4EE-48FA-94B1-59EE686D07D0}' # MicrosoftWindowsShellAuthCredUI
	'{04063501-1c04-5e01-5e72-4e2400121550}' # Microsoft-Windows-UserTrustedSignals-CredProv
	'{5512152d-88f8-5f1e-ed9f-6412175a39dc}' # Microsoft.Windows.UI.PicturePassword
	'{462a094c-fc89-4378-b250-de552c6872fd}' # Microsoft.Windows.Shell.Auth.CredUIBroker
	'{24532ca4-409f-5d6c-3ded-e11946573f56}' # Microsoft.Windows.CredUXController
	'{4f7c073a-65bf-5045-7651-cc53bb272db5}' # Microsoft.Windows.LogonController
	'{9a7b2945-e29a-5477-e857-794ae72a85d9}' # Microsoft.Windows.AuthExt
	'{f0c781fb-3451-566e-121c-9020159a5306}' # Microsoft.Windows.SharedPC.AccountManager
	'{80B3FF7A-BAB0-4ED1-958C-E89A6D5557B3}' # Microsoft.Windows.Shell.SystemSettings.WorkAccessHandlers
	'{7fdd167c-79e5-4403-8c84-b7c0bb9923a1}' # VaultGlobalDebugTraceControlGuid
)

$UEX_LSAProviders = @(
	'{D0B639E0-E650-4D1D-8F39-1580ADE72784}' # LsaTraceControlGuid
	'{DAA76F6A-2D11-4399-A646-1D62B7380F15}' # LsaAuditTraceControlGuid
	'{169EC169-5B77-4A3E-9DB6-441799D5CACB}' # LsaDsTraceControlGuid
	'{0D4FDC09-8C27-494A-BDA0-505E4FD8ADAE}' # Microsoft-Windows-Directory-Services-SAM
	'{BD8FEA17-5549-4B49-AA03-1981D16396A9}' # Microsoft-Windows-Directory-Services-SAM-Utility
	'{9A7D7195-B713-4092-BDC5-58F4352E9563}' # SamLib
	'{44415D2B-56DC-437D-AEB2-482A480183A5}' # OFFLINESAM
	'{F2969C49-B484-4485-B3B0-B908DA73CEBB}' # SamSrv
	'{548854b9-da55-403e-b2c7-c3fe8ea02c3c}' # SamSrv2
	'{8e598056-8993-11d2-819e-0000f875a064}' # SampControlGuid
)

$UEX_CRYPTProviders = @(
	'{5BBCA4A8-B209-48DC-A8C7-B23D3E5216FB}' # Microsoft-Windows-CAPI2
	'{80DF111F-178D-44FB-AFB4-5D179DE9D4EC}' # WPP_CRYPT32_CONTROL_GUID
	'{EAC19293-76ED-48C3-97D3-70D75DA61438}' # WPP_CRYPTTPMEKSVC_CONTROL_GUID
	'{9B52E09F-0C58-4eaf-877F-70F9B54A7946}' # WPP_CHAT_CONTROL_GUID
	'{A74EFE00-14BE-4ef9-9DA9-1484D5473301}' # CNGTraceControlGuid
	'{A74EFE00-14BE-4ef9-9DA9-1484D5473302}' # CNGTraceControlGuid
	'{A74EFE00-14BE-4ef9-9DA9-1484D5473303}' # CNGTraceControlGuid
	'{A74EFE00-14BE-4ef9-9DA9-1484D5473304}' # CNGTraceControlGuid
	'{EA3F84FC-03BB-540e-B6AA-9664F81A31FB}' # DPAPIGlobalDebugTraceControlGuid
	'{9D2A53B2-1411-5C1C-D88C-F2BF057645BB}' # Microsoft.Windows.Security.Dpapi
	'{89FE8F40-CDCE-464E-8217-15EF97D4C7C3}' # Microsoft-Windows-Crypto-DPAPI
)
#endregion---  DS PROVIDERS ---#


$UEX_CldFltProviders = @(
	'{d8de3faf-8a2e-4a80-aedb-c86c7cc02a73}' # CldFltLogGuid
)

$UEX_ContactSupportProviders = @(
	'{B6CC0D55-9ECC-49A8-B929-2B9022426F2A}' # Microsoft-Client-Licensing-Platform-Instrumentation
	'{8127F6D4-59F9-4ABF-8952-3E3A02073D5F}' # Microsoft-Windows-AppXDeployment
	'{3F471139-ACB7-4A01-B7A7-FF5DA4BA2D43}' # Microsoft-Windows-AppXDeployment-Server
	'{8FD4B82B-602F-4470-8577-CBB56F702EBF}' # Microsoft.Windows.AppXDeploymentClient.WPP
	'{FE762FB1-341A-4DD4-B399-BE1868B3D918}' # Microsoft.Windows.AppXDeploymentServer
	'{BA44067A-3C4B-459C-A8F6-18F0D3CF0870}' # DEPLOYMENT_WPP_GUID
	'{B9DA9FE6-AE5F-4F3E-B2FA-8E623C11DC75}' # Microsoft-Windows-SetupPlatform-AutoLogger
	'{9213C3E1-0D6C-52DD-78EA-F3B082111406}' # Microsoft-Windows-PriResources-Deployment
	'{06184C97-5201-480E-92AF-3A3626C5B140}' # Microsoft-Windows-Services-Svchost
	'{89592015-D996-4636-8F61-066B5D4DD739}' # Microsoft.Windows.StateRepository
	'{551FF9B3-0B7E-4408-B008-0068C8DA2FF1}' # Microsoft.Windows.StateRepository.Service
	'{DB00DFB6-29F9-4A9C-9B3B-1F4F9E7D9770}' # Microsoft-Windows-User Profiles General
	'{6AF9E939-1D95-430A-AFA3-7526FADEE37D}' # ClipSvcProvider
	'{B94D76C5-9D56-454A-8D1B-6CA30898160E}' # Microsoft.ClipSvc
	'{9A2EDB8F-5883-499F-ACED-6E4B69D43DDF}' # WldpTraceLoggingProvider
	'{A323CDC2-81B0-48B2-80C8-B749A221478A}' # Castle(WPP)
	'{A74EFE00-14BE-4EF9-9DA9-1484D5473302}' # CNGTraceControlGuid
	'{F0558438-F56A-5987-47DA-040CA75AEF05}' # Microsoft.Windows.WinRtClassActivation
	'{F25BCD2E-2690-55DC-3BC4-07B65B1B41C9}' # Microsoft.Windows.User32
	'{30336ED4-E327-447C-9DE0-51B652C86108}' # Microsoft-Windows-Shell-Core
	'{1AFF6089-E863-4D36-BDFD-3581F07440BE}' # ComBaseTraceLoggingProvider
	'{6AD52B32-D609-4BE9-AE07-CE8DAE937E39}' # Microsoft-Windows-RPC
	'{F4AED7C7-A898-4627-B053-44A7CAA12FCD}' # Microsoft-Windows-RPC-Events
	'{A86F8471-C31D-4FBC-A035-665D06047B03}' # Microsoft-Windows-WinRT-Error
	'{BDA92AE8-9F11-4D49-BA1D-A4C2ABCA692E}' # Microsoft-Windows-COMbase
)

$UEX_WPNProviders = @(
	'{F0AE506B-805E-434A-A005-7971D555179C}' # Wpn(WPP)
	'{4ff58fbe-3d4d-447a-ac26-7da2c51f4b7d}' # WpnSrum(WPP)
	'{2FDB1F25-8DE1-4BC1-BAC2-E445E5B38743}' # Microsoft.Windows.Notifications.WpnApps
	'{B92D1FF0-92EC-444D-B7EC-C016F971C000}' # Microsoft.Windows.Notifications.WpnCore
	'{EE845016-EBE1-41EB-BE52-5E3AE58339F2}' # WNSCP
	'{833c9bbd-6422-59cb-83bb-c695934a0cf5}' # Microsoft.Windows.PerProcessSystemDpi
	'{5cad3597-5fec-4c62-9ce1-9d7abc723d3a}' # Microsoft-Windows-PushNotifications-Developer
	'{815a1f4a-3f8d-4b37-9b31-5142f9d724a5}' # Microsoft-Windows-PushNotifications-InProc
	'{88cd9180-4491-4640-b571-e3bee2527943}' # Microsoft-Windows-PushNotifications-Platform
	'{eb3540f2-1909-5d51-b72d-a3ecb0b9bf08}' # Microsoft.Windows.Shell.NotificationController
	'{33b3eaa6-d8dd-5096-8687-6f520d32fc9e}' # Microsoft.Windows.Shell.NotificationSettings
	'{4bfe0fde-99d6-5630-8a47-da7bfaefd876}' # Microsoft-Windows-Shell-NotificationCenter
	'{7145ABF9-99F5-4CCF-A2B6-C9B2E05BA8B3}' # Microsoft.Windows.Shell.NotificationQuietHours
	'{ce575084-01be-5ef2-75f2-2d822e70cec9}' # Microsoft.Windows.Internal.Shell.Session.WnfPolicy
	'{1870FBB0-2247-44D8-BF46-B02130A8A477}' # Microsoft.Windows.Notifications.WpnApis
)

$UEX_Win32kProviders = @(
	'{e75a83ec-ef30-4e3c-a5fb-1e7626e48f43}' # Win32kPalmMetrics
	'{72a4952f-db5c-4d90-8f9d-0ed3465b315e}' # Win32kDeadzonePalmTelemetryProvider
	'{7e6b69b9-2aec-4fb3-9426-69a0f2b61a86}' # Microsoft.Windows.Win32kBase.Input
	'{ce20d1cc-faee-4ef6-9bf2-2837cef71258}' # Win32kSyscallLogging
	'{deb96c0a-d2d9-5868-a5d5-50ee13513c8b}' # Microsoft.Windows.Graphics.Display
	'{703fcc13-b66f-5868-ddd9-e2db7f381ffb}' # Microsoft.Windows.TlgAggregateInternal
	'{aad8d3a1-0ce4-4c7e-bf32-15b2836659b7}' # Microsoft.Windows.WER.MTT
	'{6d1b249d-131b-468a-899b-fb0ad9551772}' # TelemetryAssert
	'{03914E49-F3DD-40B9-BB7F-9445BF46D43E}' # Microsoft.Windows.Win32kMin.WPP
	'{0F81EC00-9E52-48E6-B899-EB3BBEEDE741}' # Microsoft.Windows.Win32kBase.WPP
	'{335D5E04-5638-4E58-AA36-7ED1CFE76FD6}' # Microsoft.Windows.Win32kFull.WPP
	'{9C648335-6987-470C-B588-3DE7A6A1FDAC}' # Microsoft.Windows.Win32kNs.WPP
	'{487D6E37-1B9D-46D3-A8FD-54CE8BDF8A53}' # Microsoft.Windows.Win32k.TraceLogging
	'{8C416C79-D49B-4F01-A467-E56D3AA8234C}' # Microsoft.Windows.Win32k.UIF
)

$UEX_AppCompatProviders = @(
	'{EEF54E71-0661-422d-9A98-82FD4940B820}' # Microsoft-Windows-Application-Experience
	'{4CB314DF-C11F-47d7-9C04-65FB0051561B}' # Microsoft-Windows-Program-Compatibility-Assistant
	'{DD17FA14-CDA6-7191-9B61-37A28F7A10DA}' # Microsoft.Windows.Appraiser.General
	'{03A70C9D-084B-4905-B341-F6377E734858}' # Microsoft.Windows.Appraiser.Instrumentation
	'{CAEA06A5-D164-4AFA-8CDF-444E3AE008A0}' # Microsoft.Windows.Appraiser.Critical
	'{F5647876-050D-4CF0-BA2F-C498B41C152A}' # DPIScalingProvider
	'{1f87779d-1ad0-45cd-8d2e-0ac9406bc878}' # Microsoft.Windows.Compatibility.Inventory.Agent
	'{32c3bee9-e3f4-4757-95a3-90e6d43299ec}' # Microsoft.Windows.Compatibility.Inventory.WMI
	'{9EFCB348-D13C-4B3A-8AB1-869AAB424C34}' # Microsoft.Windows.Inventory.General
	'{45D5CCD7-6E27-4318-82DD-69BD83A8F672}' # Microsoft.Windows.Inventory.Indicators
	'{407C75AC-661F-4C74-A4B0-ACDD9A643E42}' # Microsoft.Windows.PCA.PushApphelp
	'{95ABB8AF-1790-48BD-85AC-5FEED398DD9E}' # Microsoft.Windows.PCA.Siuf
	'{511A5C98-B374-446E-9625-108624A3CCAA}' # Microsoft.Windows.Compatibility.PCA
	'{74791F71-8F1E-4D6A-AA73-AE7FB15B0D24}' # Microsoft.Windows.AppHelp.Dialog
	'{E7558269-3FA5-46ed-9F4D-3C6E282DDE55}' # Microsoft-Windows-UAC
	'{b059b83f-d946-4b13-87ca-4292839dc2f2}' # Microsoft-Windows-User-Loader
	'{c02afc2b-e24e-4449-ad76-bcc2c2575ead}' # Microsoft-Windows-UAC-FileVirtualization
	'{AD8AA069-A01B-40A0-BA40-948D1D8DEDC5}' # Microsoft-Windows-WER-Diagnostics
	'{A0EF609D-0A14-424C-9270-3B2691A0A394}' # ErcLuaSupportTracingGuid
	'{996D3F20-43BD-40FF-9CC9-D67E5FFFD964}' # LUA
	'{CBB61B6D-A2CF-471A-9A58-A4CD5C08FFBA}' # UACLog
	'{A868CF57-6875-4EF9-8B42-C3CB590CA756}' # Microsoft.Windows.Compatibility.Luafv
	'{DAB3B18C-3C0F-43E8-80B1-E44BC0DAD901}' # Microsoft-Windows-AxInstallService
	'{0F81EC00-9E52-48E6-B899-EB3BBEEDE741}' # Microsoft.Windows.Win32kBase.WPP
	'{335D5E04-5638-4E58-AA36-7ED1CFE76FD6}' # Microsoft.Windows.Win32kFull.WPP
)

$UEX_VANProviders = @(
	'{111FFC99-3987-4bf8-8398-61853120CB3D}' # PNIandNetcenterGUID
	'{9A59814D-6DF5-429c-BD0D-2D41B4A5E9D3}' # PNIandNetcenterGUID
	'{2c929297-cd5c-4187-b508-51a2754a95a3}' # VAN WPP
	'{e6dec100-4e0f-4927-92be-e69d7c15c821}' # WlanMM WPP
)

$UEX_UserDataAccessProviders = @(
	'{D1F688BF-012F-4AEC-A38C-E7D4649F8CD2}' # Microsoft-Windows-UserDataAccess-UserDataUtils
	'{fb19ee2c-0d22-4a2e-969e-dd41ae0ce1a9}' # Microsoft-Windows-UserDataAccess-UserDataService
	'{56f519ab-9df6-4345-8491-a4ba21ac825b}' # Microsoft-Windows-UserDataAccess-UnifiedStore
	'{99C66BA7-5A97-40D5-AA01-8A07FB3DB292}' # Microsoft-Windows-UserDataAccess-PimIndexMaintenance
	'{B9B2DE3C-3FBD-4F42-8FF7-33C3BAD35FD4}' # Microsoft-Windows-UserDataAccess-UserDataApis
	'{0BD19909-EB6F-4b16-8074-6DCE803F091D}' # Microsoft-Windows-UserDataAccess-Poom
	'{83A9277A-D2FC-4b34-BF81-8CEB4407824F}' # Microsoft-Windows-UserDataAccess-CEMAPI
	'{f5988abb-323a-4098-8a34-85a3613d4638}' # Microsoft-Windows-UserDataAccess-CallHistoryClient
	'{15773AD5-AA2F-422A-9129-4A83F4C19DB0}' # Microsoft.Windows.UserDataAccess.UserDataService
	'{cb76d769-a1ed-4fb1-98c3-266951610fd8}' # Microsoft.Windows.UserDataAccess.Unistore
	'{0a0a7808-8dda-4ba0-a656-b2c740ab9108}' # Microsoft.Windows.UserDataAccess.UserDataApisBase
	'{553ebe04-ceb2-47ee-b394-bb83b97de219}' # Microsoft.Windows.UserDataAccess.UserDataAccounts
	'{d6eac963-c24f-434d-be23-4aa21904148f}' # Microsoft.Windows.UserDataAccess.TaskApis
	'{ee3112cb-4b76-49eb-a73b-712ad05e18cb}' # Microsoft.Windows.UserDataAccess.EmailApis
	'{3f7fafe6-1dd2-4720-b75b-e3268a0e6120}' # Microsoft.Windows.UserDataAccess.ContactApis
	'{412f73f7-ebf9-466f-90e7-606accdbcd15}' # Microsoft.Windows.UserDataAccess.Cemapi
	'{a94f431e-5460-465f-bf2e-6245b56d6ce9}' # Microsoft.Windows.UserDataAccess.AppointmentApis
	'{E0A18F5C-07F3-4A44-B149-0F8F13EF6887}' # Microsoft.Windows.ApplicationModel.Chat.ChatMessageBlocking
	'{FCC174D3-8890-434A-812D-BDED72EDE356}' # Microsoft.Windows.Unistack.FailureTrigger
	'{870ac05a-7777-5c66-c3f0-c1f6b7129ef6}' # Microsoft.Windows.Messaging.Service
	'{1e2462be-b025-48da-8c1f-7b60b8ccae53}' # microsoft-windows-appmodel-messagingdatamodel
	'{3da5aa05-5152-551f-a243-80a4e743c70e}' # Microsoft.Windows.Messaging.App
)

$UEX_WERProviders = @(
	'{E46EEAD8-0C54-4489-9898-8FA79D059E0E}' # Microsoft-Windows-Feedback-Service-TriggerProvider
	'{2E4201B6-4891-4912-A139-23268D5EB46E}' # WerFaultTracingGuid
	'{31EC0DFD-E734-4181-9C80-C9974C40BCEB}' # TpClientWppGuid
	'{36082273-7635-44A5-8D35-D2A266538B00}' # WerMgrTracingGuid
	'{3E19A300-75D9-4027-86BA-948B70416220}' # WerConsoleTracingGuid
	'{5EF9EC44-FB87-4F51-AF4E-CED084013281}' # FaultRepTracingGuid
	'{6851ADEB-79DA-4250-A440-F1F52D28711D}' # WerSvcTracingGuid
	'{75638A28-E9ED-42B2-9F8F-C2B1F89CF5EE}' # InfraTracingGuid
	'{7930F74B-E328-4350-89C6-11FD93771488}' # WerFaultTracingGuid
	'{9760D9C2-2FBF-4CDA-889F-8DAB2BDD98B0}' # DWTracingGuid
	'{A0EF609D-0A14-424C-9270-3B2691A0A394}' # ErcLuaSupportTracingGuid
	'{DC02AB24-0AA6-4499-8D86-A8E5F83741F5}' # HangRepTracingGuid
	'{E2821408-C59D-418F-AD3F-AA4E792AEB79}' # SqmClientTracingGuid
	'{F904D5CC-2CCA-47B0-A3CE-A05944692545}' # WerFaultSilentProcessExitLibTracingGuid
	'{FCD00FEF-04FA-41C0-889E-AE613D97602B}' # WerUITracingGuid
	'{1377561D-9312-452C-AD13-C4A1C9C906E0}' # FaultReportingTracingGuid
	'{CC79CF77-70D9-4082-9B52-23F3A3E92FE4}' # WindowsErrorReportingTracingGuid
	'{97945555-b04c-47c0-b399-e453d509a5f0}' # WERSecureVerticalTracingGuid
	'{2b87e57e-7bd0-43a3-a278-02e62d59b2b1}' # WERVerticalTracingGuid
	'{3E0D88DE-AE5C-438A-BB1C-C2E627F8AECB}' # HangReporting
	'{4A743CBB-3286-435C-A674-B428328940E4}' # PSMTracingGuid
	'{D2440861-BF3E-4F20-9FDC-E94E88DBE1F6}' # BrokerInfrastructureWPP
	'{9C6FC32A-E17A-11DF-B1C4-4EBADFD72085}' # PLM WPP tracing
	'{EB65A492-86C0-406A-BACE-9912D595BD69}' # Microsoft-Windows-AppModel-Exec
)

$UEX_WSCProviders = @(
	'{1B0AC240-CBB8-4d55-8539-9230A44081A5}' # SecurityCenter
	'{9DAC2C1E-7C5C-40eb-833B-323E85A1CE84}' # WSCInterop
	'{e6b5b34f-bd4d-5cdc-8346-ef4dc6cf1927}' # Microsoft.Windows.Security.WSC
	'{6d357dbe-57a2-5317-7970-19192e402ae6}' # Microsoft.Windows.Defender.Shield
	'{3a47280f-ef8d-41af-9288-64db7a9890d3}' # Microsoft.Windows.Defender.SecurityHealthAgent
	'{7a01e7fb-b6a4-4585-b1a8-ea2094ecb4c5}' # Microsoft.Antimalware.Scan.Interface
)

$UEX_LicenseManagerProviders = @(
	'{5e30c57a-8730-4809-945e-0d5df7aa58e5}' # Microsoft.ClientLicensing.InheritedActivation
	'{CFBEA673-BF20-4BD8-B595-29B82D43DF39}' # Microsoft.ClipUp
	'{466F3B39-9929-45E6-B891-D867BD20B738}' # Microsoft.Windows.Licensing.UpgradeSubscription
	'{B94D76C5-9D56-454A-8D1B-6CA30898160E}' # Microsoft.ClipSvc
	'{4b0cf5b8-5962-479b-9635-7dfb7c8265bc}' # ClipCLoggingProvider
	'{961d7772-0a35-4869-89ad-056fbfc0e51f}' # Microsoft.Windows.LicensingCSP
	'{B4B126DE-32FE-4591-9AC5-B0778D79A0E7}' # Microsoft.ClipSp
	'{ED0C10A5-5396-4A96-9EE3-6F4AA0D1120D}' # Microsoft.ClipC
)

$UEX_ESENTProviders = @(
	'{478EA8A8-00BE-4BA6-8E75-8B9DC7DB9F78}' # Microsoft-ETW-ESE
	'{02f42b1b-4b78-48ce-8cdf-d98f8b443b93}' # Microsoft.Windows.ESENT.TraceLogging
)

$UEX_CloudSyncProviders = @(
	'{278c595e-310c-5d49-0cca-546ce8745f9e}' # Microsoft.Windows.Shell.SyncOperation
	'{c906ed7b-d3d9-435b-97cd-22f4e7445f2a}' # Microsoft.Windows.WorkFolders
	'{885735DA-EFA7-4042-B9BC-195BDFA8B7E7}' # Microsoft.Windows.BackupAndRoaming.AzureSyncEngine
	'{95EA8EB8-6F34-45BC-8FA3-BAFEAF6C9915}' # Microsoft.Windows.BackupAndRoaming.SyncEngine
	'{49B5ED52-D5A9-47A6-9BFB-4C6C6AA200CE}' # Microsoft.Windows.BackupAndRoaming.Diagnostics
	'{40BA871E-4C49-41BC-A90C-753FF294F160}' # Microsoft.Windows.BackupAndRoaming.SyncOperations
	'{06ee5c69-51c7-5ebe-0c8f-a049cc071d3f}' # Microsoft.Windows.BackupAndRoaming.AzureWilProvider
	'{D84556B5-1EBE-5073-BCBE-F34AFDF8094D}' # Microsoft.Windows.SettingSync.AzureTracingProvide
	'{3c1be35c-79fd-55ec-2d51-2d7b19e1d377}' # Microsoft.Windows.BackupAndRoaming.WilProvider
	'{83D6E83B-900B-48a3-9835-57656B6F6474}' # Microsoft-Windows-SettingSync
	'{1284e99b-ff7a-405a-a60f-a46ec9fed1a7}' # MSF_MDS_ESE_WPP_CONTROL_GUID
	'{111157cb-ee69-427f-8b4e-ef0feaeaeef2}' # ECS_WPP_CONTROL_GUID
)

$UEX_DeviceStoreProviders = @(
	'{F7155847-D7FA-413A-809F-CFB02894905C}' # Microsoft\Shell\DeviceCenter
)

$UEX_RestartManagerProviders = @(
	'{0888E5EF-9B98-4695-979D-E92CE4247224}' # Microsoft-Windows-RestartManager
)

$UEX_MMCSSProviders = @(
	'{36008301-E154-466C-ACEC-5F4CBD6B4694}' # Microsoft-Windows-MMCSS
	'{F64BF471-CBDE-4203-8974-AFC7381A2862}' # MmcssTrace
	'{F8F10121-B617-4A56-868B-9DF1B27FE32C}' # MMCSS
)

#endregion--- OTHER PROVIDERS ---#

#endregion --- ETW component trace Providers ---

#region --- Scenario definitions ---
$UEX_General_ETWTracingSwitchesStatus = [Ordered]@{
	#'NET_Dummy' = $True
	'CommonTask NET' = $True  ## <------ the commontask can take one of "Dev", "NET", "ADS", "UEX", "DnD" and "SHA", or "Full" or "Mini"
	'NetshScenario InternetClient_dbg' = $True
	'Procmon' = $True
	#'WPR General' = $True
	'PerfMon ALL' = $True
	'PSR' = $True
	'Video' = $True
	'SDP NET' = $True
	'xray' = $True
	'CollectComponentLog' = $True
}

#region AppV SCENARIOS
$UEX_AppV_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AppV' = $True
	'NetshScenario InternetClient_dbg' = $True
	'Procmon' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}
#endregion AppV SCENARIOS

#region AVD SCENARIOS
$UEX_AVDcli_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDcommon' = $true
	'UEX_AVDcli' = $true
	'CommonTask NET' = $True
	'NetshScenario NetConnection' = $true
	'Procmon' = $true
	'PSR' = $true
	'Video' = $true
	'UEX_AVDSource' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
 }

$UEX_AVDsrv_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDcommon' = $true
	'UEX_AVDsrv' = $true
	'CommonTask NET' = $True
	'NetshScenario NetConnection' = $true
	'Procmon' = $true
	'PSR' = $true
	'UEX_AVDCore' = $True
	'UEX_AVDDiag' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
 }

$UEX_AVDSource_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDSource' = $True
	'noRepro' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDCore_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDProfiles_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDProfiles' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDActivation_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDActivation' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDMSRA_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDMSRA' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDSCard_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDSCard' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDIME_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDIME' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDTeams_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDTeams' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDMSIXAA_ETWTracingSwitchesStatus = [Ordered]@{ #deprecated, use UEX_AVDAppAttach_ETWTracingSwitchesStatus
	'UEX_AVDCore' = $True
	'UEX_AVDAppAttach' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDAppAttach_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDAppAttach' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDHCI_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDCore' = $True
	'UEX_AVDHCI' = $True
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_AVDDiag_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_AVDDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}
#endregion AVD SCENARIOS


#region FSLOGIX SCENARIOS

$UEX_FSLogix_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_FSLogix' = $true
	'CommonTask NET' = $True
	'NetshScenario NetConnection' = $true
	'Procmon' = $true
	'PSR' = $true
	'UEX_RDSDiag' = $True
	'xray' = $True
	'CollectComponentLog' = $True
 }

#endregion FSLOGIX SCENARIOS


#region Management and Scripting SCENARIOS

# Contact Garabier for the MMC scenario
$UEX_MMC_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_MMC' = $True
	'UEX_Fusion' = $True
	'Procmon' = $True
	'PSR' = $true
	'CollectComponentLog' = $True
}

$UEX_PowerShell_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_PowerShell' = $true
	'UEX_WinRMBase' = $true
	'NetshScenario NetConnection' = $true
	'Procmon' = $true
	'PSR' = $true
	'CollectComponentLog' = $True
}

$UEX_ServerManager_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_WinRMBase' = $True
	'UEX_WMIBase' = $True
	'UEX_ServerManager' = $True
	'Netsh' = $true
	'PSR' = $true
	'CollectComponentLog' = $True
}

$UEX_TSched_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_TSched' = $True
	'PRF_Shell' = $True
	'UEX_Logon' = $True
	'WPR General' = $true
	'Procmon' = $true
	'PSR' = $true
	'CollectComponentLog' = $True
}

$UEX_WinRM_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_WinRMAdvanced' = $True
	'UEX_WMIBase' = $True
	'Netsh' = $true
	'PSR' = $true
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}


$UEX_WMI_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_WMIAdvanced' = $True
	'UEX_COM' = $True
	'Netsh' = $true
	#'WPR General' = $true
	'PSR' = $true
	'CollectComponentLog' = $True
}

# Contact garabier for any change
$UEX_WMIHighCPU_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_WMIBase' = $True
	'WIN_Kernel' = $True
	'WPR CPU' = $true
	'PSR' = $true
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}
#endregion Management and Scripting SCENARIOS

#region MDAG SCENARIOS
$UEX_MDAG_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_MDAG' = $True
	'NET_HNSProviders' = $True
	'NET_FirewallProviders' = $True
	'NetshScenario virtualization,wireless_dbg,InternetClient_dbg provider={66C07ECD-6667-43FC-93F8-05CF07F446EC} level=5 keyword=0x7fffffff provider={aa7387cf-3639-496a-b3bf-dc1e79a6fc5a} level=5 keyword=0x7fffffff provider={07b7592c-a848-4520-89da-1ab26bc4629f} level=5 keyword=0x7fffffff provider={22267B1C-B979-5C81-9E24-0DB386A62DD1} level=6 keyword=0x7fffffff provider={0c885e0d-6eb6-476c-a048-2457eed3a5c1} level=6 keyword=0x7fffffff provider={D0E4BC17-34C7-43fc-9A72-D89A59D6979A} level=6 keyword=0x7fffffff provider={93f693dc-9163-4dee-af64-d855218af242} level=6 keyword=0x7fffffff provider={564368D6-577B-4af5-AD84-1C54464848E6} level=6 keyword=0x7fffffff provider={C29C4FB7-B60E-4FFF-9AF9-CF21F9B09A34} level=6 keyword=0x7fffffff provider={662abf07-6dda-5b25-c2c5-345236dbb2d2} level=6 keyword=0x7fffffff provider={A111F1C0-5923-47C0-9A68-D0BAFB577901} level=6 keyword=0x7fffffff provider={1F387CBC-6818-4530-9DB6-5F1058CD7E86} level=6 keyword=0x7fffffff provider={AE3F6C6D-BF2A-4291-9D07-59E661274EE3} level=255 keyword=0xFFFFFFFFFFFFFFFF provider={A6F32731-9A38-4159-A220-3D9B7FC5FE5D} level=255 keyword=0xFFFFFFFFFFFFFFFF provider={D8FA2E77-A77C-4494-9297-ACE3C12907F6} level=255 keyword=0xFFFFFFFFFFFFFFFF provider={28C9F48F-D244-45A8-842F-DC9FBC9B6494} level=255 keyword=0xFFFFFFFFFFFFFFFF'= $true
	'Procmon' = $true
	'PSR' = $true
	'Video' = $true
	'CollectComponentLog' = $True
}
#endregion MDAG SCENARIOS

#region MSRA/QuickAssist SCENARIOS
$UEX_MSRA_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_MSRA' = $True
	'UEX_Shadowing' = $True
	'UEX_COM' = $True
	'Netsh' = $True
	'ADS_Auth' = $true
	'Procmon' = $true
	'PSR' = $true
}

$UEX_QuickAssist_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_QuickAssist' = $True
	'UEX_MSRA' = $True
	'NetshScenario InternetClient_dbg' = $true
	'PSR' = $true
	'Procmon' = $true
	'CollectComponentLog' = $True
}
#endregion MSRA/QuickAssist SCENARIOS


#region DS SCENARIOS
$UEX_Logon_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_Logon' = $True
	'PRF_Shell' = $True
	#'UEX_RDS' = $True
	'ADS_LSA' = $True
}
#endregion DS SCENARIOS

#region Print SCENARIOS
$UEX_Print_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_Print' = $true
	'xray' = $False
	'CollectComponentLog' = $True
	'noBasicLog' = $True
 }

 $UEX_PrintFull_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_Print' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
	'NetshScenario NetConnection' = $true
	'Procmon' = $true
	'PSR' = $true
 }
#endregion Print SCENARIOS

#region RDS SCENARIOS
$UEX_RDScli_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDScommon' = $true
	'UEX_RDScli' = $true
	'CommonTask NET' = $True
	'NetshScenario NetConnection' = $true
	'Procmon' = $true
	'PSR' = $true
	'Video' = $true
	'UEX_RDSSource' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
 }

$UEX_RDSsrv_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDScommon' = $true
	'UEX_RDSsrv' = $true
	'CommonTask NET' = $True
	'NetshScenario NetConnection' = $true
	'Procmon' = $true
	'PSR' = $true
	'UEX_RDSCore' = $True
	'UEX_RDSDiag' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
 }

$UEX_RDSSource_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSSource' = $True
	'noRepro' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_RDSCore_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSCore' = $True
	'UEX_RDSDiag' = $True
	'noRepro' = $True
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_RDSProfiles_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSCore' = $True
	'UEX_RDSProfiles' = $True
	'UEX_RDSDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_RDSActivation_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSCore' = $True
	'UEX_RDSActivation' = $True
	'UEX_RDSDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_RDSMSRA_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSCore' = $True
	'UEX_RDSMSRA' = $True
	'UEX_RDSDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_RDSSCard_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSCore' = $True
	'UEX_RDSSCard' = $True
	'UEX_RDSDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_RDSIME_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSCore' = $True
	'UEX_RDSIME' = $True
	'UEX_RDSDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}

$UEX_RDSDiag_ETWTracingSwitchesStatus = [Ordered]@{
	'UEX_RDSDiag' = $True
	'noRepro' = $true
	'xray' = $True
	'CollectComponentLog' = $True
	'noBasicLog' = $True
}
#endregion RDS SCENARIOS

#endregion --- Scenario definitions ---


#region --- performance counters | POD specific ---
$UEX_SupportedPerfCounter = @{
	'UEX_Print' = 'General counters + Print related counters'
	'UEX_RDS' = 'General counters + counter for RDCB'
	'UEX_WMIPrvSE' = 'WMIPrvSE processes resource usage'
}

$UEX_PrintCounters = @(
	$global:GeneralCounters
	'\Paging File(*)\*'
	'\Cache(*)\*'
	'\Network Adapter(*)\*'
	'\Network Interface(*)\*'
	'\Server(*)\*'
	'\Server Work Queues(*)\*'
	'\Print Queue(*)\*'
)

$UEX_WMIPrvSECounters = @(
    '\Process(WmiPrvSE*)\ID Process'
    '\Process(WmiPrvSE*)\Thread Count'
    '\Process(WmiPrvSE*)\Handle Count'
    '\Process(WmiPrvSE*)\Working Set'
    '\Process(WmiPrvSE*)\% Processor Time'
)

$UEX_WinRMCounters = @(
    '\Process(*)\*'
    '\Processor(*)\*'
    '\PhysicalDisk(*)\*'
    '\Event Tracing for Windows Session(EventLog-*)\Events Lost'
    '\Event Tracing for Windows Session(EventLog-*)\Events Logged per sec'
	'\HTTP Service Request Queues(*)\*'
)

$UEX_RDSCounters = @(
	$global:GeneralCounters
	'\Terminal Services\*'
	'\Remote Desktop Connection Broker Counterset(*)\*'
	'\Remote Desktop Connection Broker Redirector Counterset(*)\*'
)
#endregion --- performance counters | POD specific ---


#region ### Pre-Start / Post-Stop / Collect functions for trace components and scenarios

#region General UEX parameters

#region AVD/RDS parameters

$script:msrdDotSourced = $false
$script:msrdFoldersInitialized = $false
if ($global:ParameterArray -Contains "Assist") { $global:msrdAudioAssistMode = 1 } else { $global:msrdAudioAssistMode = 0 }
if ($global:ParameterArray -Contains "VerboseMode") { $global:msrdSilentMode = 0 } else { $global:msrdSilentMode = 1 }

#endregion AVD/RDS parameters

#endregion General UEX parameters


#region Shared UEX functions

Function UEX_NoTraceCleanup { #delete dummy trace files
	param([string]$tech)

	$FilePattern = "*UEX_$tech*Trace.etl"
	$FilesToDelete = Get-ChildItem -Path $global:LogFolder -Filter $FilePattern | Where-Object { $_.Name -notlike "*TSS*.etl" }
	if ($FilesToDelete) {
		foreach ($File in $FilesToDelete) {
			LogInfoFile "Removing dummy trace file: $File"	
			Remove-Item -Path $File.FullName -Force
		}
	}
}

#endregion Shared UEX functions


#region APP-V FUNCTIONS
Function CollectUEX_AppVLog {
	EnterFunc $MyInvocation.MyCommand.Name
	FwAddRegItem @("AppV") _Stop_
	($EvtLogsAppV, "System", "Security") | ForEach-Object { FwAddEvtLog $_ _Stop_}
	FwGetTaskList _Stop_
	FwGetGPresultAS _Stop_
	LogInfoFile "[$($MyInvocation.MyCommand.Name)] .. Copy AppV related log files" -ShowMsg
	#("ProgamData_AppV","ProgamData_Client_Catalog","AppData_Client_Catalog","AppData_ShortCutBackups","AppData_Client_VFS","LocalAppData_Client_VFS","AppData_roaming_Client_Catalog","AppData_ShortCutBackup") | ForEach-Object {FwCreateFolder $global:LogFolder\$_}
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		#@("$Env:ProgramData\App-V\*", "$global:LogFolder\ProgamData_AppV\"),
		@("$Env:ProgramData\Microsoft\AppV\Client\Catalog\*", "$global:LogFolder\ProgamData_Client_Catalog\"),
		@("$Env:AppData\Microsoft\AppV\Client\Catalog\*", "$global:LogFolder\AppData_Client_Catalog\"),
		@("$Env:AppData\Microsoft\AppV\Client\Integration\ShortCutBackups\*", "$global:LogFolder\AppData_ShortCutBackups\"),
		@("$Env:AppData\Microsoft\AppV\Client\VFS\*", "$global:LogFolder\AppData_Client_VFS\"),
		@("$Env:LocalAppData\Microsoft\AppV\Client\VFS\*", "$global:LogFolder\LocalAppData_Client_VFS\"),
		@("$Env:AppData\roaming\Microsoft\AppV\Client\Catalog\*", "$global:LogFolder\AppData_roaming_Client_Catalog\")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion APP-V FUNCTIONS


#region AppCompat FUNCTIONS
Function CollectUEX_AppCompatLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$AppCompatLogFolder = "$LogFolder\AppCompatLog$LogSuffix"
	$LogPrefix = 'AppCompat'
	Try{
		FwCreateFolder $AppCompatLogFolder
	}Catch{
		LogException ("Unable to create $AppCompatLogFolder.") $_
		Return
	}
	$AppCompatRegistries = @(
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$AppCompatLogFolder\AppCompatFlags-HKLM-Reg.txt"),
		('HKCU:Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags', "$AppCompatLogFolder\AppCompatFlags-HKCU-Reg.txt")
	)
	FwExportRegistry $LogPrefix $AppCompatRegistries
	REG SAVE 'HKLM\System\CurrentControlSet\Control\Session Manager\AppCompatCache' "$AppCompatLogFolder\AppCompatCache.HIV" 2>&1 | Out-Null
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion AppCompat FUNCTIONS


#region AppLocker FUNCTIONS
Function CollectUEX_AppLockerLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogPrefix = "AppLocker"
	$AppLockerLogFolder = "$LogFolder\AppLockerLog$LogSuffix"

	Try{
		FwCreateFolder $AppLockerLogFolder
		Get-AppLockerPolicy -Effective -Xml | Out-File "$AppLockerLogFolder\AppLockerPolicy.xml"
		xcopy $env:SystemRoot\System32\AppLocker "$AppLockerLogFolder\$LogPrefix-System32_AppLocker" /I /E /Y /H /C /Q
		($global:EvtLogsAppLocker) | ForEach-Object { FwAddEvtLog $_ _Stop_}
		(Get-Item -Path Registry::HKEY_USERS\S-1-5-19\SOFTWARE\Microsoft\SystemCertificates\CA).GetAccessControl() | Format-List -Property * | Out-File "$AppLockerLogFolder\$LogPrefix-ACL-SystemCertificates_CA.txt"
		(Get-Item -Path Registry::HKEY_USERS\S-1-5-19\SOFTWARE\Microsoft\SystemCertificates\CA).GetAccessControl().Access | Format-List -Property * | Out-File "$AppLockerLogFolder\$LogPrefix-ACL-Access-SystemCertificates_CA.txt"
	}Catch{
		LogException ("Error Collect UEX_AppLockerLog.") $_
		Return
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion AppLocker FUNCTIONS


#region AVD FUNCTIONS

Function CollectUEX_AVDSourceLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $true; $global:msrdTarget = $false
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$true * 12)

	$parameters = @{
        varsSystem = @(,$true * 12)
        varsAVDRDS = @(,$true * 11)
        varsInfra = @(,$true * 10)
        varsAD = @(,$true * 2)
        varsNET = @(,$true * 8)
        varsLogSec = @(,$true * 3)
        varsIssues = @(,$true * 2)
        varsOther = @(,$true * 4)
    }
    msrdCollectDataDiag @parameters
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDCoreLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$true * 12) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDProfilesLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsProfiles @(,$true * 5) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDActivationLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsActivation @(,$true * 3) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDMSRALog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsMSRA @(,$true * 6) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDSCardLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsSCard @(,$true * 3) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDIMELog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsIME @(,$true * 3) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDTeamsLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsTeams @(,$true * 4) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDMSIXAALog{ #deprecated

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsMSIXAA @(,$true * 1) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDAppAttachLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsMSIXAA @(,$true * 1) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDHCILog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsHCI @(,$true * 1) -skipDiagCounter
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_AVDDiagLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }

    $global:onlyDiag = $true
	$parameters = @{
        varsSystem = @(,$true * 12)
        varsAVDRDS = @(,$true * 11)
        varsInfra = @(,$true * 10)
        varsAD = @(,$true * 2)
        varsNET = @(,$true * 8)
        varsLogSec = @(,$true * 3)
        varsIssues = @(,$true * 2)
        varsOther = @(,$true * 4)
    }
    msrdCollectDataDiag @parameters
	UEX_NoTraceCleanup -tech AVD

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion AVD FUNCTIONS


#region Management and Scripting FUNCTIONS
Function UEX_COMPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	If($EnableCOMDebug.IsPresent){
		$COMDebugRegKey = "HKLM:Software\Microsoft\OLE\Tracing"
		If(!(Test-Path -Path "$COMDebugRegKey")){
			Try{
				LogInfo ("[COM] Creating `'HKLM\Software\Microsoft\OLE\Tracing`' key.")
				New-Item $COMDebugRegKey -ErrorAction Stop | Out-Null
			}Catch{
				LogMessage $LogLevel.Error ("Unable to creat `'HKLM\Software\Microsoft\OLE\Tracing`' key.")
				Return
			}
		}

		Try{
			LogInfo ("[COM] Enabling COM debug and setting `'ExecutablesToTrace`' to `'*`'.")
			Set-Itemproperty -path $COMDebugRegKey -Name 'ExecutablesToTrace' -value '*' -Type String -ErrorAction Stop
		}Catch{
			LogException ("Unable to set `'ExecutablesToTrace`' registry.") $_
			LogMessage $LogLevel.Warning ("[COM] COM trace will continue with normal level.")
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_COMPostStop{
	$COMDebugRegKey = "HKLM:Software\Microsoft\OLE\Tracing"
	If(Test-Path -Path "$COMDebugRegKey"){
		$TracingKey = Get-ItemProperty -Path "HKLM:Software\Microsoft\OLE\Tracing" -ErrorAction Stop
		If($Null -ne $TracingKey.ExecutablesToTrace){
			Try{
				LogInfo ("[COM] Deleting `'ExecutablesToTrace`' registry.")
				Remove-ItemProperty -Path $COMDebugRegKey -Name 'ExecutablesToTrace' -ErrorAction Stop
			}Catch{
				LogException ("Unable to delete `'ExecutablesToTrace`' registry.") $_
				LogMessage $LogLevel.Warning ("[COM] Please remove `'ExecutablesToTrace`' under HKLM\Software\Microsoft\OLE\Tracing key manually.")
			}
		}
	}
}

Function CollectUEX_COMLog{
	# invokes external script until fully integrated into TSS
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Calling COM-Collect.ps1"
	.\scripts\COM-Collect.ps1 -DataPath $global:LogFolder -AcceptEula
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done COM-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_DSCLog{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling DSC-Collect.ps1"
	.\scripts\DSC-Collect.ps1 -DataPath $global:LogFolder -AcceptEula
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done DSC-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}

<# Commented on 2024-05-28 by garabier. Please delete this in August 2024
Function CollectUEX_EventLogLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$EventLogFolder = "$LogFolder\EventLog$LogSuffix"
	$EventLogDumpFolder = "$EventLogFolder\Process dump"
	$EventLogSubscriptionFolder = "$EventLogFolder\WMISubscriptions"

	Try{
		FwCreateFolder $EventLogFolder
		FwCreateFolder $EventLogDumpFolder
		FwCreateFolder $EventLogSubscriptionFolder
	}Catch{
		LogException ("Unable to create $EventLogFolder.") $_
		Return
	}

	# Process dump
	FwCaptureUserDump "EventLog" $EventLogDumpFolder -IsService:$True

	# Settings and registries
	$Commands =@(
		"auditpol /get /category:* | Out-File -Append $EventLogFolder\auditpol.txt",
		"reg export HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\WMI\Autologger $EventLogFolder\WMI-Autologger.reg.txt",
		"reg export HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels $EventLogFolder\WINEVT-Channels.reg.txt",
		"reg export HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers $EventLogFolder\WINEVT-Publishers.reg.txt",
		"reg export HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\EventLog $EventLogFolder\EventLog-Policies.reg.txt",
		"reg export HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog $EventLogFolder\EventLogService.reg.txt",
		"cacls C:\Windows\System32\winevt\Logs | Out-File -Append $EventLogFolder\Permissions.txt",
		"cacls C:\Windows\System32\LogFiles\WMI\RtBackup | Out-File -Append $EventLogFolder\Permissions.txt",
		"Copy-Item C:\Windows\System32\LogFiles\WMI\RtBackup -Recurse $EventLogFolder",
		"Get-ChildItem $env:windir\System32\winevt\Logs -Recurse | Out-File -Append $EventLogFolder\WinEvtLogs.txt",
		"logman -ets query `"EventLog-Application`" | Out-File -Append $EventLogFolder\EventLog-Application.txt",
		"logman -ets query ""EventLog-System"" | Out-File -Append $EventLogFolder\EventLog-System.txt",
		"logman query providers | Out-File -Append $EventLogFolder\QueryProviders.txt",
		"logman query -ets | Out-File -Append $EventLogFolder\QueryETS.txt",
		"wevtutil el | Out-File -Append $EventLogFolder\EnumerateLogs.txt",
		"Get-ChildItem $env:windir\System32\LogFiles\WMI\RtBackup -Recurse | Out-File -Append $EventLogFolder\RTBackup.txt"

	)
	RunCommands "Eventlog" $Commands -ThrowException:$False -ShowMessage:$True

	FwExecWMIQuery -Namespace "root\subscription" -Query "select * from ActiveScriptEventConsumer" | Export-Clixml -Path ($EventLogSubscriptionFolder + "\ActiveScriptEventConsumer.xml")
	FwExecWMIQuery -Namespace "root\subscription" -Query "select * from __eventfilter" | Export-Clixml -Path ($EventLogSubscriptionFolder + "\__eventfilter.xml")
	FwExecWMIQuery -Namespace "root\subscription" -Query "select * from __IntervalTimerInstruction" | Export-Clixml -Path ($EventLogSubscriptionFolder + "\__IntervalTimerInstruction.xml")
	FwExecWMIQuery -Namespace "root\subscription" -Query "select * from __AbsoluteTimerInstruction" | Export-Clixml -Path ($EventLogSubscriptionFolder + "\__AbsoluteTimerInstruction.xml")
	FwExecWMIQuery -Namespace "root\subscription" -Query "select * from __FilterToConsumerBinding" | Export-Clixml -Path ($EventLogSubscriptionFolder + "\__FilterToConsumerBinding.xml")

	If((Get-Service EventLog).Status -eq "Running"){
		$EventLogs = @(
			"System",
			"Application",
			"Microsoft-Windows-Kernel-EventTracing/Admin"
		)
		FwExportEventLog $EventLogs $EventLogFolder
		("Application", "System", "Security", "HardwareEvents", "Internet Explorer", "Key Management Service", "Windows PowerShell") | ForEach-Object { FwEvtLogDetails $_ $EventLogFolder}
#		FwEvtLogDetails "Application" $EventLogFolder
#		FwEvtLogDetails "System" $EventLogFolder
#		FwEvtLogDetails "Security" $EventLogFolder
#		FwEvtLogDetails "HardwareEvents" $EventLogFolder
#		FwEvtLogDetails "Internet Explorer" $EventLogFolder
#		FwEvtLogDetails "Key Management Service" $EventLogFolder
#		FwEvtLogDetails "Windows PowerShell" $EventLogFolder
	}Else{
		$Commands =@(
			"Copy-Item C:\Windows\System32\winevt\Logs\Application.evtx $EventLogFolder\$env:computername-Application.evtx"
			"Copy-Item C:\Windows\System32\winevt\Logs\System.evtx $EventLogFolder\$env:computername-System.evtx"
		)
		RunCommands "Eventlog" $Commands -ThrowException:$False -ShowMessage:$True
	}
	EndFunc $MyInvocation.MyCommand.Name
}#>

Function CollectUEX_EvtLog{
	# using external script
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling Evt-Collect.ps1"
	.\scripts\Evt-Collect.ps1 -DataPath $global:LogFolder -AcceptEula
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done Evt-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_FusionPreStart{
	# Contact Garabier for the Fusion Functions
	EnterFunc $MyInvocation.MyCommand.Name
	FwCreateFolder $global:LogFolder\FusionLogs

	$RegistryKey = "HKLM\SOFTWARE\Microsoft\Fusion"
		FwAddRegValue "$RegistryKey" "ForceLog" "REG_DWORD" "0x1"
		FwAddRegValue "$RegistryKey" "LogFailures" "REG_DWORD" "0x1"
		FwAddRegValue "$RegistryKey" "LogResourceBinds" "REG_DWORD" "0x1"
		FwAddRegValue "$RegistryKey" "EnableLog" "REG_DWORD" "0x1"
		FwAddRegValue "$RegistryKey" "LogPath" "REG_SZ" "$global:LogFolder\FusionLogs"
		Write-Host -ForegroundColor cyan "Please close and reopen the executable for which you want to collect Fusion logs."
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectUEX_FusionLog {
	EnterFunc $MyInvocation.MyCommand.Name
	$RegistryKey = "HKLM\SOFTWARE\Microsoft\Fusion"
	"ForceLog","LogFailures","LogResourceBinds","EnableLog","LogPath" | ForEach-Object { FwDeleteRegValue "$RegistryKey" $_ }
	Remove-Item "$global:LogFolder\*_UEX_FusionTrace.etl" -Force
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_MMCLog {
	# Function CollectUEX_MMC : Contact Garabier for any change
  EnterFunc $MyInvocation.MyCommand.Name

	# SnapIns
  $outFile = $PrefixTime + "MMC_Snapins.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting SnapIns information"
  Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\MMC\SnapIns > $outFile

 # .NET Files
  $outFile = $PrefixTime + "MMC_DotNetFiles.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting .NET files information"
  Get-ChildItem -Path C:\Windows\Microsoft.NET -Recurse | Select * > $outFile

 # .NET Versions installed
  $outFile = $PrefixTime + "MMC_DotNetVersions.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting .NET Version installation information"
  Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" > $outFile
}

Function CollectUEX_PowerShellLog {
	#Contact Garabier for the Powershell Collect
  EnterFunc $MyInvocation.MyCommand.Name
  ($global:EvtLogsPowerShell) | ForEach-Object { FwAddEvtLog $_ _Stop_}

  # Get installed Modules
  $outFile = $PrefixTime + "Powershell_InstalledModules.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting installed modules information"
  get-installedmodule | Select-Object Name,Version,InstalledDate,PublishedDate,InstalledLocation,RepositorySourceLocation,Repository,PackageManagementProvider > $outFile

  # Get Modules
  $outFile = $PrefixTime + "Powershell_Modules.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting modules information"
  get-module | Select-Object Name,Version,RootModule,PowerShellVersion,ClrVersion,AccessMode,ModuleType,RepositorySourceLocation,ModuleBase,Path > $outFile

  # Repositories
  $outFile = $PrefixTime + "Powershell_Repositories.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting repositories information"
  Get-PSRepository | Select-Object * > $outFile

  # PSVersionTable
  $outFile = $PrefixTime + "Powershell_PSVersionTable.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting PSVersionTable"
  $psversiontable > $outFile

  # Variables
  $outFile = $PrefixTime + "Powershell_Variables.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting variables"
  get-variable > $outFile

  # Profile Script
  $outFile = $PrefixTime + "Powershell_ProfileScript.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting Profile Script if existing"
  If (Test-Path $Profile) {get-content $Profile > $outFile}

  # PSDrives
  $outFile = $PrefixTime + "Powershell_PSdrives.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting PSDrives information"
  Get-PSDrive > $outFile

  # PSHost Process Info
  $outFile = $PrefixTime + "Powershell_PSHostProcessInfo.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting PS Process information"
  Get-PSHostProcessInfo > $outFile

  # Provider
  $outFile = $PrefixTime + "Powershell_Provider.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting Providers information"
  Get-PSProvider > $outFile

  # Execution Context
  $outFile = $PrefixTime + "Powershell_ExecutionContext.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting Execution Context"
  Write-Output "Host" > $outFile
  $ExecutionContext.Host >> $outFile
  Write-Output "" >> $outFile
  Write-Output "Events" >> $outFile
  $ExecutionContext.Events >> $outFile
  Write-Output "" >> $outFile
  Write-Output "InvokeProvider" >> $outFile
  $ExecutionContext.InvokeProvider >> $outFile
  Write-Output "" >> $outFile
  Write-Output "SessionState" >> $outFile
  $ExecutionContext.SessionState >> $outFile
  Write-Output "" >> $outFile
  Write-Output "InvokeCommand" >> $outFile
  $ExecutionContext.InvokeCommand >> $outFile

  # Powershell Configuration
  $outFile = $PrefixTime + "Powershell_Configuration.json"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting Powershell Config"
  If (Test-Path $PSHOME\powershell.config.json) {Get-Content $PSHOME\powershell.config.json > $outFile}

  # Execution Policy
  $outFile = $PrefixTime + "Powershell_ExecutionPolicy.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting Powershell Execution Policy"
  Get-ExecutionPolicy -List > $outFile

  # Powershell Commands
  $outFile = $PrefixTime + "Powershell_Commands.txt"
  LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting all Powershell commands"
  Get-Command > $outFile

  EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_TSchedLog{
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling Sched-Collect.ps1"
	.\scripts\Sched-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done Sched-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_TSchedPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	FwGetTaskList _Start_
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_TSchedPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	FwGetTaskList _Stop_
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_TelemetryPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	$RegistryKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser"
	FwAddRegValue "$RegistryKey" "VerboseMode" "REG_DWORD" "0x1"
	FwAddRegValue "$RegistryKey" "TestHooksEnabled" "REG_DWORD" "0x1"
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_TelemetryPostStart{
	EnterFunc $MyInvocation.MyCommand.Name
	Stop-Service diagtrack
	LogInfo "[$($MyInvocation.MyCommand.Name)] Stopping Service diagtrack"
	$RegistryKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\currentversion\diagnostics\diagtrack\testhooks"
	FwAddRegValue "$RegistryKey" "ResetEventStore" "REG_DWORD" "0x1"
	Start-Service diagtrack
	LogInfo "[$($MyInvocation.MyCommand.Name)] Starting Service diagtrack"
	FwDeleteRegValue "$RegistryKey" "ResetEventStore"
	#Census
	$CensusRunRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Census"
	if($(Test-Path $CensusRunRegKey) -eq $false)
	{
	New-Item -Path $CensusRunRegKey -ItemType Key | Out-Null
	}
	# Turn Census FullSync mode on
	LogInfo "[$($MyInvocation.MyCommand.Name)]Setting property: FullSync to value 1 at registry key path $censusRunRegKey to turn on Census FullSync mode"
    $CensusRunRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Census"
	FwAddRegValue $CensusRunRegKey 'FullSync' "REG_DWORD" "1"
    $CensusRunRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Census"
	If ( $(FwGet-RegistryValue -RegistryKey $CensusRunRegKey -RegistryValue RunCounter) -eq $null)
	{
		FwAddRegValue $CensusRunRegKey "RunCounter" "REG_DWORD" "0"
	}
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_TelemetryPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	#AppRaiser : Code posted as is. Need to improve it later on
	LogInfo "[$($MyInvocation.MyCommand.Name)]Start: RunAppraiser"
	LogInfo "[$($MyInvocation.MyCommand.Name)]Attempting to run inventory...This may take a few minutes to complete, please do not cancel the script."
	do
	{
		& CompatTelRunner.exe -m:appraiser.dll -f:DoScheduledTelemetryRun ent | out-null
		$appraiserLastExitCode = $LASTEXITCODE
		$appraiserLastExitCodeHex = "{0:X}" -f $appraiserLastExitCode
		if($appraiserLastExitCode -eq 0x80070021)
		{
			LogInfo "[$($MyInvocation.MyCommand.Name)]RunAppraiser needs to run CompatTelRunner.exe, but it is already running. Waiting for 60 seconds before retry."
			If ($NoOfAppraiserRetries -eq 3)
				{
					LogInfo "[$($MyInvocation.MyCommand.Name)]Last attempt."
				}
			Start-Sleep -Seconds 60
			$NoOfAppraiserRetries+=1
		}
		else
		{
			$NoOfAppraiserRetries-=1
		}
	}While(($NoOfAppraiserRetries -gt 0) -and ($NoOfAppraiserRetries -lt 4))

	if ($appraiserLastExitCode -ne 0x0)
	{
		if ($appraiserLastExitCode -lt 0x0)
		{
			LogInfo "[$($MyInvocation.MyCommand.Name)]RunAppraiser failed. CompatTelRunner.exe exited with last error code: 0x$appraiserLastExitCodeHex."
		}
		else
		{
			LogInfo "[$($MyInvocation.MyCommand.Name)]RunAppraiser succeeded with a return code: 0x$appraiserLastExitCodeHex."
		}
	}
	else
	{
		LogInfo "[$($MyInvocation.MyCommand.Name)]Passed: RunAppraiser"
	}

	# M365AHandlerLog
	LogInfo "[$($MyInvocation.MyCommand.Name)]Start: CollectM365AHandlerLog"
	Try
	{
		$propertyPath = "HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global"
		if(Test-Path -Path $propertyPath)
		{
			if ((Get-ItemProperty -Path $propertyPath -Name LogDirectory -ErrorAction SilentlyContinue) -eq $null)
			{
				LogInfo "[$($MyInvocation.MyCommand.Name)]Could not find registry key LogDirectory at path HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global"
			}
			else
			{
				Try
				{
					$logDirectoryKeyM365 = Get-ItemProperty -Path $propertyPath -Name LogDirectory
					$logDirectoryM365 = $logDirectoryKeyM365.LogDirectory
					Copy-Item "$logDirectoryM365\M365AHandler.log" -Destination $Global:LogFolder | Out-Null
					LogInfo "[$($MyInvocation.MyCommand.Name)]Passed: CollectM365AHandlerLog"
			}
			Catch
				{
					LogInfo "[$($MyInvocation.MyCommand.Name)]Error getting logs at registry key LogDirectory at path HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global" "Warning" $null "CollectM365AHandlerLog" $_.Exception.HResult $_.Exception.Message
					return
			}
			}
		}
	}
	Catch
	{
		LogInfo "[$($MyInvocation.MyCommand.Name)]Error getting logs at registry key LogDirectory at path HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global" "Warning" $null "CollectM365AHandlerLog" $_.Exception.HResult $_.Exception.Message
	}

	#DisableAppRaiserVerboseMode
	LogInfo "[$($MyInvocation.MyCommand.Name)]Start: DisableAppraiserVerboseMode"
    Try
    {
		if (FwTestRegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" "VerboseMode" )
        {
	    Try
            {
				global:FwDeleteRegValue "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" "VerboseMode"
	    }
	    Catch
            {
				LogInfo "[$($MyInvocation.MyCommand.Name)]DisableAppraiserVerboseMode failed deleting VerboseMode property at registry key path: $vAppraiserPath. This is not fatal, script will continue." "Warning" $null "DisableAppraiserVerboseMode" $_.Exception.HResult $_.Exception.Message
	    }
        }
        else
        {
			LogInfo "[$($MyInvocation.MyCommand.Name)]Appraiser VerboseMode key already deleted"
        }

        LogInfo "[$($MyInvocation.MyCommand.Name)]Passed: DisableAppraiserVerboseMode"
    }
    Catch
    {
		LogInfo "[$($MyInvocation.MyCommand.Name)]DisableAppraiserVerboseMode failed with unexpected exception. This is not fatal, script will continue." "Warning" $null "DisableAppraiserVerboseMode" $_.Exception.HResult $_.Exception.Message
    }
	#RestartDiagTrack
	LogInfo "[$($MyInvocation.MyCommand.Name)]Start: RestartDiagtrack"
    Try
    {
        & Net stop diagtrack | Out-Null
		FwAddRegValue "HKEY_LOCAL_MACHINE\software\microsoft\windows\currentversion\diagnostics\diagtrack\testhooks" "ResetEventStore" "REG_DWORD" "0x1"
        & Net start diagtrack | Out-Null
		global:FwDeleteRegValue "HKEY_LOCAL_MACHINE\software\microsoft\windows\currentversion\diagnostics\diagtrack\testhooks" "ResetEventStore"
        LogInfo "[$($MyInvocation.MyCommand.Name)]Passed: RestartDiagtrack"
    }
    Catch
    {
        LogInfo "[$($MyInvocation.MyCommand.Name)]RestartDiagtrack failed to execute - script will continue." "Warning" $null "RestartDiagtrack" $_.Exception.HResult $_.Exception.Message
        return
    }
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_TelemetryLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$TelemetryLogFolder = "$LogFolder\TelemetryLog$LogSuffix"
	Try{
		FwCreateFolder $TelemetryLogFolder
	}Catch{
		LogException  ("Unable to create $TelemetrLogFolder.") $_
		Return
	}
	$TelemetryRegistries = @(
		("HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags","$TelemetryLogFolder\REG_AppCompatFlags.txt"),
	 	("HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Census","$TelemetryLogFolder\REG_Census.txt"),
		("HKLM:SOFTWARE\Microsoft\SQMClient","$TelemetryLogFolder\REG_SQM.txt"),
		("HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack","$TelemetryLogFolder\REG_DiagTrack.txt"),
		("HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection","$TelemetryLogFolder\REG_PoliciesDataCollection.txt"),
		("HKLM:SOFTWARE\Policies\Microsoft\Windows\DataCollection","$TelemetryLogFolder\REG_DataCollection.txt")
	)
	FwExportRegistry "Telemetry" $TelemetryRegistries
	$outFile = "$TelemetryLogFolder\SMSClientVersion.txt"
	LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting SMS Client Version" # Export SCCM Client Version
	FwGet-RegistryValue -RegistryKey "HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client" -RegistryValue "SmsClientVersion" > $outFile
	$RegistryKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser"
	"VerboseMode","TestHooksEnabled" | ForEach-Object { FwDeleteRegValue "$RegistryKey" $_ }
	$ConnectivityDiagnosisTool = Join-Path $global:ScriptFolder "BIN\ConnectivityDiagnosis.exe"
	Try {
		& $ConnectivityDiagnosisTool -verbose > "$PrefixTime`_Telemetry_ConnectivityDiagnosis.txt"
	}
	Catch {
		LogError "Error running RunConnectivityDiagnosis"
	}
	# Copy AppCompat Folder
	LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting AppCompatFolder"
	FwCreateFolder $TelemetryLogFolder\AppCompat
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths.add(@("$env:windir\appcompat\*", "$TelemetryLogFolder\AppCompat"))
	FwCopyFiles $SourceDestinationPaths

	# Get Telemetry Event logs
	($EvtLogsTelemetry) | ForEach-Object { FwAddEvtLog $_ _Stop_}
	EndFunc $MyInvocation.MyCommand.Name
}

<# CollectUEX_WinRMLog Deprecated. Commented on May 2024 by garabier
Function CollectUEX_WinRMLog{
	# using external script WinRM-Collect.ps1
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WinRM-Collect.ps1"
	.\scripts\WinRM-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WinRM-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}
#>
Function CollectUEX_WinRMBaseLog{
	# using external script WinRM-Collect.ps1
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WinRM-Collect.ps1"
	.\scripts\WinRM-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WinRM-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_WinRMBasePreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	FwGetTaskList _Start_
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_WinRMBasePostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	FwGetTaskList _Stop_
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_WinRMAdvancedLog{
	# using external script WinRM-Collect.ps1
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WinRM-Collect.ps1"
	.\scripts\WinRM-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WinRM-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_WinRMAdvancedPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	FwGetTaskList _Start_
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_WinRMAdvancedPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	FwGetTaskList _Stop_
	EndFunc $MyInvocation.MyCommand.Name
}

<# Commented on 2024-05-24 by garabier
Function UEX_WMIPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	LogDebug ('Enabling analytic logs for WMI')
	Try{
		FwSetEventLog 'Microsoft-Windows-WMI-Activity/Trace'
		FwSetEventLog 'Microsoft-Windows-WMI-Activity/Debug'
	}Catch{
		$ErrorMessage = 'An exception happened in FwSetEventLog.'
		LogException $ErrorMessage $_ $fLogFileOnly
		Throw ($ErrorMessage)
	}
	EndFunc $MyInvocation.MyCommand.Name
}#

Function UEX_WMIPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	LogDebug ('Disabling analytic logs for WMI')

	Try{
		FwResetEventLog 'Microsoft-Windows-WMI-Activity/Trace'
		FwResetEventLog 'Microsoft-Windows-WMI-Activity/Debug'
	}Catch{
		$ErrorMessage = 'An exception happened in FwResetEventLog.'
		LogException $ErrorMessage $_ $fLogFileOnly
		Throw ($ErrorMessage)
	}
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_WMILog{  # Todo repolace with alias of CollectUEX_WMI
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WMI-Collect.ps1"
	.\scripts\WMI-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WMI-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}#>

Function CollectUEX_WMIReportLog{  
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WMI-Report.ps1"
	.\scripts\WMI-Report.ps1 -DataPath $global:LogFolder -AcceptEula
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WMI-Report.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_WMIBaseLog{  # Todo repolace with alias of CollectUEX_WMI
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WMI-Collect.ps1"
	.\scripts\WMI-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WMI-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_WMIBasePreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	if (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber) -ge 26063) {
		$outFile = $PrefixTime + "UEX_WMIBaseTrace.arb.txt"
		$cmd = "winmgmt /dumptasks arb 1 LogFile:""" + $outFile + """"
		LogInfo "[$($MyInvocation.MyCommand.Name)] Running $cmd"
		$scriptBlock = {
		  Invoke-Expression ($using:cmd)
		}
		$job = Start-Job -Name "ArbDumpJob" -ScriptBlock $scriptBlock
	}	
	FwGetTaskList _Start_
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_WMIBasePostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	if (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber) -ge 26063) {
		LogInfo "[$($MyInvocation.MyCommand.Name)] . Ensuring ArbDumpJob is no longer running"
		$arbJob = Wait-Job -Name "ArbDumpJob"
		$jobResult = Receive-Job -Name "ArbDumpJob" -Keep
		if ($jobResult.State -eq 'Failed') {
			LogInfo "Job failed. Error details:"
		  $errorDetails = $jobResult.ChildJobs[0].JobStateInfo.Reason
		  if ($errorDetails) {
			LogInfo $errorDetails
		  } else {
			LogInfo "No error details available."
		  }
		} else {
			LogInfo "Job completed successfully."
		}	 
	}
	FwGetTaskList _Stop_
	EndFunc $MyInvocation.MyCommand.Name
}
Function CollectUEX_WMIAdvancedLog{  # Todo repolace with alias of CollectUEX_WMI
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WMI-Collect.ps1"
	.\scripts\WMI-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WMI-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_WMIAdvancedPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	if (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber) -ge 26063) {
		$outFile = $PrefixTime + "UEX_WMIBaseTrace.arb.txt"
		$cmd = "winmgmt /dumptasks arb 1 LogFile:""" + $outFile + """"
		LogInfo "[$($MyInvocation.MyCommand.Name)] Running $cmd"
		$scriptBlock = {
		  Invoke-Expression ($using:cmd)
		}
		$job = Start-Job -Name "ArbDumpJob" -ScriptBlock $scriptBlock
	}	
	FwGetTaskList _Start_
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_WMIAdvancedPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	if (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber) -ge 26063) {
		LogInfo "[$($MyInvocation.MyCommand.Name)] . Ensuring ArbDumpJob is no longer running"
		$arbJob = Wait-Job -Name "ArbDumpJob"
		$jobResult = Receive-Job -Name "ArbDumpJob" -Keep
		if ($jobResult.State -eq 'Failed') {
			LogInfo "Job failed. Error details:"
		  $errorDetails = $jobResult.ChildJobs[0].JobStateInfo.Reason
		  if ($errorDetails) {
			LogInfo $errorDetails
		  } else {
			LogInfo "No error details available."
		  }
		} else {
			LogInfo "Job completed successfully."
		}	 
	}
	FwGetTaskList _Stop_
	EndFunc $MyInvocation.MyCommand.Name
}

<#Function CollectUEX_WMIActivityLog{ # Todo repolace with alias of CollectUEX_WMI
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling WMI-Collect.ps1"
	.\scripts\WMI-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done WMI-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}#> #Commented on 2024-05-24 by garabier
#endregion Management and Scripting FUNCTIONS


#region FSLOGIX FUNCTIONS
Function CollectUEX_FSLogixLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$FSLogixLogFolder = "$global:LogFolder\FSLogix$global:LogSuffix"
	$LogPrefix = "FSLogix"
	$FSLogixLogs = 'C:\ProgramData\FSLogix\Logs'
	$RobocopyLog = "$FSLogixLogFolder\Robocopy.log"

	Try{
		FwCreateFolder "$FSLogixLogFolder\Logs"
	}Catch{
		LogException "Unable to create $FSLogixLogFolder." $_
		Return
	}

	# Eveng logs
	$EventLogsWithTextFmt = @(
		"Microsoft-Windows-TerminalServices-LocalSessionManager/Operational",
		"Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin",
		"Microsoft-FSLogix-Apps/Admin",
		"Microsoft-FSLogix-Apps/Operational",
		"Microsoft-FSLogix-CloudCache/Admin",
		"Microsoft-FSLogix-CloudCache/Operational",
		"Microsoft-Windows-GroupPolicy/Operational",
		"Microsoft-Windows-User Profile Service/Operational"
	)
	FwExportEventLog $EventLogsWithTextFmt $FSLogixLogFolder

	$EventLogsEvtxOnly = @(
		"Microsoft-Windows-VHDMP-Operational",
		"Microsoft-Windows-SMBClient/Operational",
		"Microsoft-Windows-SMBClient/Connectivity",
		"Microsoft-Windows-SMBClient/Security",
		"Microsoft-Windows-SMBServer/Operational",
		"Microsoft-Windows-SMBServer/Connectivity",
		"Microsoft-Windows-SMBServer/Security"
	)
	FwExportEventLog $EventLogsEvtxOnly $FSLogixLogFolder -NoExportWithText

	# frx
	$frxcmd = "$env:ProgramFiles\fslogix\apps\frx.exe"
	if (Test-Path $frxcmd) {
		LogInfo "[$LogPrefix] Collecting output from frx.exe."
		# As command path contains space, we need to use '&' operator to run the command
		$Commands = @(
			"& '$frxcmd' version | Out-File -Append -FilePath $FSLogixLogFolder\frx-list.txt",
			"& '$frxcmd' list-redirects | Out-File -Append -FilePath $FSLogixLogFolder\frx-list.txt",
			"& '$frxcmd' list-rules | Out-File -Append -FilePath $FSLogixLogFolder\frx-list.txt"
		)
		RunCommands $LogPrefix $Commands -ShowMessage:$True
	}

	# Log files
	LogInfo "[$LogPrefix] Collecting FSLogix logs."
	if (Test-Path $FSLogixLogs) {
			robocopy.exe "$FSLogixLogs" "$FSLogixLogFolder\Logs" /W:1 /R:1 /NP /E *.log /LOG+:$RobocopyLog /S
	}

	# Registry
	Loginfo "[$LogPrefix] Exporting FSLogix related registry keys may take some time; please remain patient." "Magenta"
	$RegKeys = @(
		('HKLM:SOFTWARE\FSLogix', "$FSLogixLogFolder\Reg-SW-FSLogix.txt"),
		('HKLM:SOFTWARE\Policies\FSLogix', "$FSLogixLogFolder\Reg-SW-Policies-FSLogix.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows Defender\Exclusions', "$FSLogixLogFolder\Reg-SW-MS-WinDef-Exclusions.txt"),
		('HKLM:SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions', "$FSLogixLogFolder\Reg-SW-GPO-MS-WinDef-Exclusions.txt"),
		('HKCU:SOFTWARE\Microsoft\Office', "$FSLogixLogFolder\Reg-SW-MS-Office.txt"),
		('HKCU:Software\Policies\Microsoft\office', "$FSLogixLogFolder\Reg-SW-Policies-MS-Office.txt"),
		('HKCU:SOFTWARE\Microsoft\OneDrive', "$FSLogixLogFolder\Reg-SW-MS-OneDrive.txt"),
		('HKLM:SOFTWARE\Microsoft\OneDrive', "$FSLogixLogFolder\Reg-SW-MS-OneDrive.txt"),
		('HKLM:SOFTWARE\Policies\Microsoft\OneDrive', "$FSLogixLogFolder\Reg-SW-Pol-MS-OneDrive.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows Search', "$FSLogixLogFolder\Reg-SW-MS-WindowsSearch.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList', "$FSLogixLogFolder\Reg-SW-MS-WinNT-CV-ProfileList.txt"),
		('HKCU:Volatile Environment', "$FSLogixLogFolder\Reg-VolatileEnvironment.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers', "$FSLogixLogFolder\Reg-SW-MS-Win-CV-Auth-CredProviders.txt")
	)
	FwExportRegistry "FSLogix" $RegKeys

	# Below registies have binary data. So exporting them as hive format
	LogInfo "[$LogPrefix] Exporting FSLogix related registry hives."
	REG SAVE 'HKCU\SOFTWARE\Microsoft\Office' "$FSLogixLogFolder\Reg-SW-MS-Office.hiv" 2>&1 | Out-Null
	REG SAVE 'HKLM\SOFTWARE\Microsoft\Windows Search' "$FSLogixLogFolder\Reg-SW-MS-WindowsSearch.hiv" 2>&1 | Out-Null
	REG SAVE 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' "$FSLogixLogFolder\Reg-SW-MS-WinNT-CV-ProfileList.hiv" 2>&1 | Out-Null

	#Collecting user/profile information
	RunCommands $LogPrefix "Whoami /all 2>&1 | Out-File -Append $FSLogixLogFolder\WhoAmI-all.txt" -ShowMessage:$True

	#Collecting FSLogix group memberships
	LogInfo "[$LogPrefix] Collecting FSLogix group memberships."
	$Commands = @()
	if ([ADSI]::Exists("WinNT://localhost/FSLogix ODFC Exclude List")) {
		$Commands += "& net localgroup 'FSLogix ODFC Exclude List' 2>&1 | Out-File -Append -FilePath $FSLogixLogFolder\LocalGroupsMembership.txt"
	} else {
		LogWarnFile "[$LogPrefix] 'FSLogix ODFC Exclude List' group not found."
	}

	if ([ADSI]::Exists("WinNT://localhost/FSLogix ODFC Include List")) {
		$Commands += "net localgroup 'FSLogix ODFC Include List' 2>&1 | Out-File -Append -FilePath $FSLogixLogFolder\LocalGroupsMembership.txt"
	} else {
		LogWarnFile "[$LogPrefix] 'FSLogix ODFC Include List' group not found."
	}

	if ([ADSI]::Exists("WinNT://localhost/FSLogix Profile Exclude List")) {
		$Commands += "net localgroup 'FSLogix Profile Exclude List' 2>&1 | Out-File -Append -FilePath $FSLogixLogFolder\LocalGroupsMembership.txt"
	} else {
		LogWarnFile "[$LogPrefix] 'FSLogix Profile Exclude List' group not found."
	}

	if ([ADSI]::Exists("WinNT://localhost/FSLogix Profile Include List")) {
		$Commands += "net localgroup 'FSLogix Profile Include List' 2>&1 | Out-File -Append -FilePath $FSLogixLogFolder\LocalGroupsMembership.txt"
	} else {
		LogWarnFile "[$LogPrefix] 'FSLogix Profile Include List' group not found."
	}

	If($Commands.count -gt 0){
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$False
	}
}
#endregion FSLOGIX FUNCTIONS


#region OTHER FUNCTIONS
Function CollectUEX_LogonLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogonLogFolder = "$LogFolder\LogonLog$LogSuffix"
	$LogPrefix = 'Logon'
	Try{
		FwCreateFolder $LogonLogFolder
	}Catch{
		LogException  ("Unable to create $LogonLogFolder.") $_
		Return
	}

	$LogonRegistries = @(
		('HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication', "$LogonLogFolder\Logon_Reg.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', "$LogonLogFolder\Winlogon_Reg.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\AssignedAccessConfiguration', "$LogonLogFolder\AssignedAccess_Reg.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\AssignedAccessCsp', "$LogonLogFolder\AssignedAccessCsp_Reg.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows Embedded\Shell Launcher', "$LogonLogFolder\ShellLauncher_Reg.txt"),
		('HKLM:SOFTWARE\Microsoft\Provisioning\Diagnostics\ConfigManager\AssignedAccess', "$LogonLogFolder\ConfigManager_AssignedAccess_Reg.txt"),
		('HKLM:SOFTWARE\Microsoft\Windows\EnterpriseResourceManager\AllowedNodePaths\CSP\AssignedAccess', "$LogonLogFolder\CSP_AssignedAccess_Reg.txt"),
		('HKLM:SYSTEM\CurrentControlSet\Services\AssignedAccessManagerSvc', "$LogonLogFolder\AssignedAccessManagerSvc_Reg.txt")
	)
	FwExportRegistry $LogPrefix $LogonRegistries

	Try{
		Get-AssignedAccess -ErrorAction Stop| Out-File -Append "$LogonLogFolder\Get-AssignedAccess.txt"
		Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-File -Append "$LogonLogFolder\Get-AppxPackage-AllUsers.txt"
		(Get-StartApps -ErrorAction SilentlyContinue).AppId | Out-File -Append "$LogonLogFolder\Get-StartApps.txt"
	}Catch{
		LogException  ("An error happened in Get-AssignedAccess") $_ $fLogFileOnly
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion OTHER FUNCTIONS


#region MDAG FUNCTIONS
##MDAG
Function enableContainer(){
	$containerList = Invoke-Expression "hcsdiag.exe list"
	$foundValidContainer = $false
	if ($null -ne $containerList){
		$containerListSplit = $containerList.split("`n");
		for($i = 1; $i -lt $containerListSplit.Count; $i++){
			if(($containerListSplit[$i] -match "HVSI" -or $containerListSplit[$i] -match "CmService") -and -not($containerListSplit[$i] -match "SavedAs")){
				$foundValidContainer = $true
				$ValidContainerId = $containerListSplit[$i - 1]
				$containerState = $containerListSplit[$i].split(",").trim()[1]
				break
			}
		}
	}

	if ($foundValidContainer){
		LogInfo "[MDAG] Container is in $containerState state"
		if($containerState -ne "Running"){
			$resumeContainer = "C:\Windows\System32\wdagtool.exe resume $ValidContainerId"
			LogInfo "[MDAG] Running command: $resumeContainer "
			Invoke-Expression $resumeContainer
			LogInfo "[MDAG] $resumeContainer Done"
		}
		return $ValidContainerId
	} else{
		LogInfoFile "[MDAG] Error: Can not collect Container trace because container is not setup yet."
		return $null
	}
}

Function UEX_MDAGPreStart{
	EnterFunc $MyInvocation.MyCommand.Name

	#Get Containers List at start
	$GetContainersListCmd = "hcsdiag.exe list"
	Invoke-Expression $GetContainersListCmd | Out-File $global:LogFolder\HcsdiagList_Sart.txt

	#set DisableResetContainer regkey to 1
	$setDisableResetContainer = 'reg.exe add HKLM\Software\Microsoft\HVSI /v DisableResetContainer /t REG_DWORD /d 1 /f'
	Runcommands "MDAG" $setDisableResetContainer -ThrowException:$False -ShowMessage:$True

	# start container trace
	$SharedFolderInContainer = "C:\SharedFolderInContainer"
	#$containerUser = "NT AUTHORITY\SYSTEM"

	#Get containerId
	$containerId = enableContainer

	if($null -ne $containerId){
		#Share host folder to the container
		$SharedFolderInContainerCmd = "C:\Windows\System32\hcsdiag.exe share $containerId '$global:LogFolder' '$SharedFolderInContainer'"

		LogInfo "[MDAG] Running command: $SharedFolderInContainerCmd"
		Runcommands "MDAG" $SharedFolderInContainerCmd -ThrowException:$False -ShowMessage:$True

		if ($lastexitcode -eq '-2147024809'){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode): Probably already shared before with same query: $SharedFolderInContainerCmd"
		}

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode): $SharedFolderInContainerCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $SharedFolderInContainerCmd"
		}

		#Copy container providers to container
		$copyContainerProvidersFilesCmd = "C:\Windows\System32\hcsdiag.exe write  -user 'NT AUTHORITY\SYSTEM' $containerId '$global:ScriptFolder\Config\ContainerProviders.wprp' c:\programdata\Microsoft\Windows\ContainerProviders_customized.wprp"
		LogInfo "[MDAG] Running command: $copyContainerProvidersFilesCmd "
		Runcommands "MDAG" $copyContainerProvidersFilesCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode): $copyContainerProvidersFilesCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $copyContainerProvidersFilesCmd"
		}

		#Start container trace
		$startContainerTracecmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId wpr.exe -start c:\programdata\Microsoft\Windows\ContainerProviders_customized.wprp -instancename ContainerLogger"
		LogInfo "[MDAG] Running command: $startContainerTracecmd "
		Runcommands "MDAG" $startContainerTracecmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode): $startContainerTracecmd"
		} else{
			LogInfo "[MDAG] Succeeded: $startContainerTracecmd "
		}

		#Start COntainer net trace
		$startContainerTraceNetworkCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId netsh.exe trace start InternetClient_dbg overwrite=yes maxSize=1024 capture=yes traceFile=C:\windows\temp\ContainerNetTrace.etl report=disabled"

		LogInfo "[MDAG] Running command: $startContainerTraceNetworkCmd "
		Runcommands "MDAG" $startContainerTraceNetworkCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode): $startContainerTraceNetworkCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $startContainerTraceNetworkCmd "
		}
	}

	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_MDAGPostStop{
	EnterFunc $MyInvocation.MyCommand.Name

	 ## stop Container trace
	$containerId = enableContainer
	if( $null -ne $containerId){
		#Stop wpr trace in container
		$stopContainerTraceCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId wpr.exe -stop C:\windows\temp\ContainerTrace.etl -instancename ContainerLogger"
		LogInfo "[MDAG] Running command: $stopContainerTraceCmd "
		Runcommands "MDAG" $stopContainerTraceCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $stopContainerTraceCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $stopContainerTraceCmd "
		}

		#Get File from container
		$readContainerTraceEtlCmd = "hcsdiag.exe read -user 'NT AUTHORITY\SYSTEM' $containerId C:\windows\temp\ContainerTrace.etl '$global:LogFolder\ContainerTrace.etl'"
		LogInfo "[MDAG] Running command: $readContainerTraceEtlCmd "
		Runcommands "MDAG" $readContainerTraceEtlCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $readContainerTraceEtlCmd"
		}else{
			LogInfo "[MDAG] Succeeded: $readContainerTraceEtlCmd "
		}

		#Stop container Net Trace
		$stopContainerNetTraceCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId netsh.exe trace stop"
		LogInfo "[MDAG] Running command: $stopContainerNetTraceCmd "
		Runcommands "MDAG" $stopContainerNetTraceCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $stopContainerNetTraceCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $stopContainerNetTraceCmd "
		}

		#Get Container Net Trace
		$readContainerNetTraceCmd = "hcsdiag.exe read -user 'NT AUTHORITY\SYSTEM' $containerId C:\windows\temp\ContainerNetTrace.etl '$global:LogFolder\ContainerNetTrace.etl'"
		LogInfo "[MDAG] Running command: $readContainerNetTraceCmd "
		Runcommands "MDAG" $readContainerNetTraceCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $readContainerNetTraceCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $readContainerNetTraceCmd "
		}

		#Get Ipconfig from the container
		$containerIpconfigCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId ipconfig.exe -allcompartments -all 2>&1 > '$global:LogFolder\Container_ipconfig.log'"
		LogInfo "[MDAG] Running command: $containerIpconfigCmd "
		Runcommands "MDAG" $containerIpconfigCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $containerIpconfigCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $containerIpconfigCmd "
		}

		#Get tasklist flavors from the container
		$containerTaskListconfigCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId tasklist 2>&1 > '$global:LogFolder\Container_TaskList.log'"
		LogInfo "[MDAG] Running command: $containerTaskListconfigCmd "
		Runcommands "MDAG" $containerTaskListconfigCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $containerTaskListconfigCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $containerTaskListconfigCmd "
		}

		$containerTaskListsvcconfigCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId tasklist /svc 2>&1 > '$global:LogFolder\Container_TaskListsvc.log'"
		LogInfo "[MDAG] Running command: $containerTaskListsvcconfigCmd "
		Runcommands "MDAG" $containerTaskListsvcconfigCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $containerTaskListsvcconfigCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $containerTaskListsvcconfigCmd "
		}

		$containerTaskListappsconfigCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId tasklist /apps 2>&1 > '$global:LogFolder\Container_TaskListapps.log'"
		LogInfo "[MDAG] Running command: $containerTaskListappsconfigCmd "
		Runcommands "MDAG" $containerTaskListappsconfigCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $containerTaskListappsconfigCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $containerTaskListappsconfigCmd "
		}

		#Generate System evtx in container
		$containerEvtxSystemCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId wevtutil.exe epl System '$env:ProgramData\Microsoft\Diagnosis\container_evtx_system.evtx' /ow:true"
		LogInfo "[MDAG] Running command: $containerEvtxSystemCmd "
		Runcommands "MDAG" $containerEvtxSystemCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $containerEvtxSystemCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $containerEvtxSystemCmd "
		}

		#Get System evtx from container
		$GetContainerEvtxSystemCmd = "hcsdiag.exe read -user 'NT AUTHORITY\SYSTEM' $containerId '$env:ProgramData\Microsoft\Diagnosis\container_evtx_system.evtx'  '$global:LogFolder\container_evtx_system.evtx'"
		LogInfo "[MDAG] Running command: $GetContainerEvtxSystemCmd "
		Runcommands "MDAG" $GetContainerEvtxSystemCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $GetContainerEvtxSystemCmd "
		} else{
			LogInfo "[MDAG] Succeeded: $GetContainerEvtxSystemCmd  "
		}

		#Generate Application evtx in container
		$ContainerEvtxApplicationCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId wevtutil.exe epl Application '$env:ProgramData\Microsoft\Diagnosis\container_evtx_application.evtx' /ow:true"
		LogInfo "[MDAG] Running command: $ContainerEvtxApplicationCmd "
		Runcommands "MDAG" $ContainerEvtxApplicationCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $ContainerEvtxApplicationCmd "
		} else{
			LogInfo "[MDAG] Succeeded: $ContainerEvtxApplicationCmd  "
		}

		#Get Application evtx from container
		$GetContainerEvtxApplicationCmd = "hcsdiag.exe read -user 'NT AUTHORITY\SYSTEM' $containerId '$env:ProgramData\Microsoft\Diagnosis\container_evtx_application.evtx'  '$global:LogFolder\container_evtx_application.evtx'"
		LogInfo "[MDAG] Running command: $GetContainerEvtxApplicationCmd "
		Runcommands "MDAG" $GetContainerEvtxApplicationCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $GetContainerEvtxApplicationCmd "
		} else{
			LogInfo "[MDAG] Succeeded: $GetContainerEvtxApplicationCmd  "
		}

		#Generate AppXDeploymentServer evtx in container
		$ContainerEvtxAppXDeploymentServerCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId wevtutil.exe epl Microsoft-Windows-AppXDeploymentServer/Operational '$env:ProgramData\Microsoft\Diagnosis\container_evtx_AppXDeploymentServer.evtx' /ow:true"
		LogInfo "[MDAG] Running command: $ContainerEvtxAppXDeploymentServerCmd "
		Runcommands "MDAG" $ContainerEvtxAppXDeploymentServerCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $ContainerEvtxAppXDeploymentServerCmd "
		} else{
			LogInfo "[MDAG] Succeeded: $ContainerEvtxAppXDeploymentServerCmd  "
		}

		#Get AppXDeploymentServer evtx from container
		$GetContainerEvtxAppXDeploymentServerCmd = "hcsdiag.exe read -user 'NT AUTHORITY\SYSTEM' $containerId '$env:ProgramData\Microsoft\Diagnosis\container_evtx_AppXDeploymentServer.evtx'  '$global:LogFolder\container_evtx_AppXDeploymentServer.evtx'"
		LogInfo "[MDAG] Running command: $GetContainerEvtxAppXDeploymentServerCmd "
		Runcommands "MDAG" $GetContainerEvtxAppXDeploymentServerCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $GetContainerEvtxAppXDeploymentServerCmd "
		} else{
			LogInfo "[MDAG] Succeeded: $GetContainerEvtxAppXDeploymentServerCmd  "
		}

		#Generate CodeIntegrity evtx in container
		$ContainerEvtxCodeIntegrityCmd= "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId wevtutil.exe epl Microsoft-Windows-CodeIntegrity/Operational '$env:ProgramData\Microsoft\Diagnosis\container_evtx_CodeIntegrity.evtx' /ow:true"
		LogInfo "[MDAG] Running command: $ContainerEvtxCodeIntegrityCmd "
		Runcommands "MDAG" $ContainerEvtxCodeIntegrityCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $ContainerEvtxCodeIntegrityCmd "
		} else{
			LogInfo "[MDAG] Succeeded: $ContainerEvtxCodeIntegrityCmd  "
		}

		#Get CodeIntegrity evtx from container
		$GetContainerEvtxCodeIntegrityCmd= "hcsdiag.exe read -user 'NT AUTHORITY\SYSTEM' $containerId '$env:ProgramData\Microsoft\Diagnosis\container_evtx_CodeIntegrity.evtx'  '$global:LogFolder\container_evtx_CodeIntegrity.evtx'"
		LogInfo "[MDAG] Running command: $GetContainerEvtxCodeIntegrityCmd "
		Runcommands "MDAG" $GetContainerEvtxCodeIntegrityCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $GetContainerEvtxCodeIntegrityCmd "
		} else{
			LogInfo "[MDAG] Succeeded: $GetContainerEvtxCodeIntegrityCmd  "
		}

		<# Failing at the moment on my box...
		#Generate wscollect.cab from container
		$wscollectContainerCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId wscollect.exe C:\programdata\Microsoft\Windows\WsCollect.cab"
		LogInfo "[MDAG] Running command: $wscollectContainerCmd "
		Runcommands "MDAG" $wscollectContainer -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735'))
		{
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode): $wscollectContainer"
		}
		else
		{
			LogInfo "[MDAG] Succeeded: $wscollectContainer "
		}
		#>

		#Generate LicensingLogs.cab in container
		$licensingdiagContainerCmd = "hcsdiag.exe exec -user 'NT AUTHORITY\SYSTEM' $containerId licensingdiag.exe /cab C:\programdata\Microsoft\Windows\LicensingLogs.cab /q"
		LogInfo "[MDAG] Running command: $licensingdiagContainerCmd "
		Runcommands "MDAG" $licensingdiagContainerCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode): $licensingdiagContainerCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $licensingdiagContainerCmd "
		}

		#Get LicensingLogs.cab from container
		$readContainerlicensingdiagCmd = "hcsdiag.exe read -user 'NT AUTHORITY\SYSTEM' $containerId C:\programdata\Microsoft\Windows\LicensingLogs.cab '$global:LogFolder\LicensingLogs.cab'"
		LogInfo "[MDAG] Running command: $readContainerlicensingdiagCmd "
		Runcommands "MDAG" $readContainerlicensingdiagCmd -ThrowException:$False -ShowMessage:$True

		if(($lastexitcode -ne '0') -and ($lastexitcode -ne '-2147022882') -and ($lastexitcode -ne '-2147024735')){
			LogInfoFile "[MDAG] Failed (Error Code $lastexitcode):  $readContainerlicensingdiagCmd"
		} else{
			LogInfo "[MDAG] Succeeded: $readContainerlicensingdiagCmd "
		}
	}

	#set DisableResetContainer regkey to 1
	$setEnableResetContainer = 'reg.exe add HKLM\Software\Microsoft\HVSI /v DisableResetContainer /t REG_DWORD /d 0 /f'
	Runcommands "MDAG" $setEnableResetContainer -ThrowException:$False -ShowMessage:$True

	#Get Containers List at stop
	$GetContainersListstopCmd = "hcsdiag.exe list"
	Invoke-Expression $GetContainersListstopCmd | Out-File $global:LogFolder\HcsdiagList_Stop.txt

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_MDAGLog{
	EnterFunc $MyInvocation.MyCommand.Name

	# Event log
	($EvtLogsDocker,$EvtLogsWDAG) | ForEach-Object { FwAddEvtLog $_ _Stop_}

	# Commands
	$scQueryLog = "$PrefixTime`Service_Query.log"
	$Commands = @(
			"sc.exe query winnat | Out-File -Append $scQueryLog",
			"sc.exe query hns | Out-File -Append $scQueryLog",
			"sc.exe query vfpext | Out-File -Append $scQueryLog",
			"sc.exe query iphlpsvc | Out-File -Append $scQueryLog",
			"sc.exe query vmcompute | Out-File -Append $scQueryLog",
			"sc.exe query dnscache | Out-File -Append $scQueryLog",
			"sc.exe query sharedaccess | Out-File -Append $scQueryLog",
			"sc.exe query BFE | Out-File -Append $scQueryLog",
			"sc.exe query Dhcp | Out-File -Append $scQueryLog",
			"sc.exe query NetSetupSvc | Out-File -Append $scQueryLog",
			"sc.exe query mpssvc | Out-File -Append $scQueryLog",
			"sc.exe query nvagent | Out-File -Append $scQueryLog",
			"sc.exe query nsi | Out-File -Append $scQueryLog",
			"sc.exe query CmService | Out-File -Append $scQueryLog",
			"sc.exe query vmms | Out-File -Append $scQueryLog",
			"sc.exe query hvsics | Out-File -Append $scQueryLog"
	)
	Runcommands "MDAG" $Commands -ThrowException:$False -ShowMessage:$True

	# Registries
	FwAddRegItem @("MDAG_HKLM_SW_MS_HVSI", "MDAG_HKLM_SW_POL_MS", "MDAG_HKLM_SW_Browsers_LookAside", "MDAG_HKLM_SW_MS_EDP_Policies", "MDAG_HKLM_SW_MS_Enrollments", "MDAG_HKLM_SW_MS_PolicyManager_NetworkIsolation", "MDAG_HKLM_System_CCS_Services", "MDAG_HKLM_System_CCS_Control_GraphicsAndGpu", "MDAG_HKLM_System_CCS_HNS") _Stop_
	#For later
	#FwAddRegItem @("") _Stop_ -noRecursive

	#Get HNS CollectLogs

	<# This way of doing is not good as it requires net connection, and uses non signed scripts and output in another location etc...
	Discussed this with Milan and he also agrees we should avoid this.
	$OutDir = $global:LogFolder
	Try{
		Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/debug/collectlogs.ps1" -Outfile HNS_collectlogs.ps1
		(Get-Content "HNS_collectlogs.ps1").Replace('$outDir = [io.Path]::Combine($ScriptPath, [io.Path]::GetRandomFileName())',"`$outDir = '$OutDir'") | Set-Content "HNS_collectlogs.ps1"
		Start-Process "powershell" -ArgumentList ".\HNS_collectlogs.ps1" -NoNewWindow
	}Catch{
		LogWarn "Failed to run HNS_collectlogs.ps1"
		Continue
	}
	End this way of doing #>

	#Get HNS Networks
	Get-HnsNetwork | Select Name, Type, Id,@{Name="AddressPrefix"; Expression={$_.Ipams.Subnets.IpAddressPrefix}} | Out-File $global:LogFolder\HNSNetworks.txt
	Get-hnsnetwork | Convertto-json -Depth 20 | Out-File -Append $global:LogFolder\HNSNetworks.txt
	Get-hnsnetwork | % { Get-HnsNetwork -Id $_.ID -Detailed } | Convertto-json -Depth 20 | Out-File $global:LogFolder\networkdetailed.txt


    #Get HNS Endpoints
    Get-HnsEndpoint | Select @{Name="IpAddress"; Expression={$_.IpConfigurations.IpAddress}}, MacAddress, @{Name="IsRemoteEndpoint"; Expression={(Get-HNSEndpoint -Version 1 -Id $_.ID).IsRemoteEndpoint}}, @{Name="State"; Expression={(Get-HNSEndpoint -Version 1 -Id $_.ID).State}} | Out-File $global:LogFolder\HNSEndpoint.txt
    Get-hnsendpoint | Convertto-json -Depth 20 | Out-File -Append $global:LogFolder\HNSEndpoint.txt

    #Get HNS  Namespaces
    Get-HnsNamespace | Select ID, @{Name="CompartmentID"; Expression={$_.NamespaceId}}, @{Name="CompartmentGuid"; Expression={$_.NamespaceGuid}}, Type, @{Name="EndpointID"; Expression={$_.Resources.Data.Id}} | Out-File $global:LogFolder\HNSnamespaces.txt
	Get-HnsNamespace | Convertto-json -Depth 20 | Out-File -Append $global:LogFolder\HNSnamespaces.txt

	#Get HNS Load Balancers
	$HNSLoadBalancers = "Get-HnsLoadBalancer | Convertto-json -Depth 20 | Out-File $global:LogFolder\HNSLoadBalancers.txt"
	Runcommands "MDAG" $HNSLoadBalancers -ThrowException:$False -ShowMessage:$True

	#Get VMSwitch Ports
	$vfpctrlPorts = "vfpctrl.exe /list-vmswitch-port | Out-File $global:LogFolder\Ports.txt"
	Runcommands "MDAG" $vfpctrlPorts -ThrowException:$False -ShowMessage:$True

	# Loop through ports.txt file
	$ports = @()
	foreach($line in (Get-Content $global:LogFolder\Ports.txt)){
    $nline = $line.Split(":")
    if ($nline[0].contains('Port name'))
    {
        $ports += $nline[1]
    }
	}

	# For each port, we want to call get-port-counter
	foreach($port in $ports)
	{
    	"Get-port-counter for port: $port" | Out-File -Append $global:LogFolder\Ports.txt
    	vfpctrl /port $port.trim() /get-port-counter | Out-File -Append $global:LogFolder\Ports.txt
	}

	#Get IP Info from host
	ipconfig /allcompartments /all | Out-File $global:LogFolder\Host_ip.txt
	Get-NetIPAddress -IncludeAllCompartments | Out-File -Append $global:LogFolder\Host_ip.txt
	Get-NetIPInterface -IncludeAllCompartments | Out-File -Append $global:LogFolder\Host_ip.txt

	#Get Routes
	route print | Out-File $global:LogFolder\Host_routes.txt
	Get-NetRoute -IncludeAllCompartments | Out-File -Append $global:LogFolder\Host_routes.txtt

	#Get MTU, NVSPInfo, NMSCRUB, ARP
	netsh int ipv4 sh int | Out-File $global:LogFolder\Host_mtu.txt
	nvspinfo -a -i -h -D -p -d -m -q | Out-File $global:LogFolder\Host_nvspinfo.txt
	nmscrub -a -n -t | Out-File $global:LogFolder\Host_nmscrub.txt
	nmbind | Out-File $global:LogFolder\Host_nmbind.txt
	arp -a | Out-File $global:LogFolder\Host_arp.txt
	Get-NetNeighbor -IncludeAllCompartments | Out-File -Append $global:LogFolder\Host_arp.txt

	Get-NetAdapter -IncludeHidden | Out-File $global:LogFolder\Host_netadapter.txt

	New-Item -Path $global:LogFolder\adapters -ItemType Directory
	$arrInvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
	$invalidChars = [RegEx]::Escape(-join $arrInvalidChars)

	Get-NetAdapter -IncludeHidden  | foreach {
    	$ifindex=$_.IfIndex;
    	$ifName=$_.Name;
    	$fileName="${ifName}_int.txt";
    	$fileName=[RegEx]::Replace($fileName, "[$invalidChars]", ' ');
    	netsh int ipv4 sh int $ifindex | Out-File -FilePath "$global:LogFolder\adapters\$fileName" -Encoding ascii;
    	$_ | FL * | Out-File -Append -FilePath "$global:LogFolder\adapters\$fileName" -Encoding ascii
    }

	#Get Firewall Rules
	Get-NetFirewallRule -PolicyStore ActiveStore | Out-File $global:LogFolder\Host_firewall.txt

	New-Item -Path $global:LogFolder\Host_wfp -ItemType Directory
	Set-Location $global:LogFolder\Host_wfp
	netsh wfp show netevents
	netsh wfp show state
	netsh wfp show filters
	Set-Location $global:LogFolder

	#Get hnsdiag, hcsdiag, ctr.exe
	$res = Get-Command hnsdiag.exe -ErrorAction SilentlyContinue
	if ($res)
	{
		hnsdiag list all -d | Out-File $global:LogFolder\Host_hnsdiag.txt
		hnsdiag list networks | Out-File $global:LogFolder\Host_hnsdiag_Networks.txt
		hnsdiag list PortRanges | Out-File $global:LogFolder\Host_hnsdiag_PortRanges.txt
	}

	hcsdiag list  | Out-File $global:LogFolder\Host_hcsdiag.txt

	$res = Get-Command ctr.exe -ErrorAction SilentlyContinue
	if ($res)
	{
		ctr -n "k8s.io" c ls | Out-File $global:LogFolder\Host_containers.txt
	}

	#Get netsh info
	netsh int ipv4 sh excludedportrange TCP | Out-File $global:LogFolder\Host_excludedportrange.txt
	netsh int ipv4 sh excludedportrange UDP | Out-File -Append $global:LogFolder\Host_excludedportrange.txt
	netsh int ipv4 sh dynamicportrange TCP | Out-File $global:LogFolder\Host_dynamicportrange.txt
	netsh int ipv4 sh dynamicportrange UDP | Out-File -Append $global:LogFolder\Host_dynamicportrange.txt
	netsh int ipv4 sh tcpconnections | Out-File $global:LogFolder\Host_tcpconnections.txt

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion MDAG FUNCTIONS


#region PRINT FUNCTIONS
Function UEX_PrintPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	Try{
		FwSetEventLog 'Microsoft-Windows-PrintService/Admin'
		FwSetEventLog 'Microsoft-Windows-PrintService/Operational'
		FwSetEventLog 'Microsoft-Windows-PrintService/Debug'
	}Catch{
		$ErrorMessage = 'An exception happened in FwSetEventLog'
		LogException $ErrorMessage $_ $fLogFileOnly
		Throw ($ErrorMessage)
	}

	LogInfo " .. collecting BuildLab Registry settings"
	$RegKeys = @(
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion', 'BuildLab', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion', 'BuildLabEx', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion', 'EditionId', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion', 'InstallationType', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\SQMClient', 'MachineId', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion', 'UBR', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion', 'ProductName', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\Windows\CurrentVersion\AppModel', 'Version', "$global:PrefixCn`Reg_BuildInfo.txt"),
		('HKLM:Software\Microsoft\Windows NT\CurrentVersion\Print\PrinterExtensionAssociations', "$global:PrefixCn`Reg_BuildInfo.txt")
	)
	FwExportRegistry "BuildInfo" $RegKeys -ShowMessage:$False
	$outFile = $PrefixTime + "Printerdriver_Start_.txt"
	$Commands = @(
		"REG QUERY `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\PrinterExtensionAssociations`" /s | Out-File -Append $outFile"
		"get-printer -full |fl; get-printerdriver |fl | Out-File -Append $outFile"
		"tasklist /svc | Out-File -Append $global:LogFolder\tasklist_PreStart.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_PrintPostStop{
	EnterFunc $MyInvocation.MyCommand.Name
	$fResult = $True
	Try{
		FwResetEventLog 'Microsoft-Windows-PrintService/Admin'
		FwResetEventLog 'Microsoft-Windows-PrintService/Operational'
		FwResetEventLog 'Microsoft-Windows-PrintService/Debug'
	}Catch{
		$ErrorMessage = 'An exception happened in FwResetEventLog'
		LogException $ErrorMessage $_ $fLogFileOnly
		Throw ($ErrorMessage)
	}
	$Commands = @(
		"tasklist /svc | Out-File -Append $global:LogFolder\tasklist_PostStop.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_PrintLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$PrintLogFolder = "$LogFolder\PrintLog$global:LogSuffix"
	$PrintLogDumpFolder = "$PrintLogFolder\Process dump"
	$PrintLogInfFolder = "$PrintLogFolder\inf"
	$PrintLogPrefixCn = "$PrintLogFolder\$Env:Computername" + "_"
	Try{
		FwCreateFolder $PrintLogFolder
		FwCreateFolder $PrintLogDumpFolder
		FwCreateFolder $PrintLogInfFolder
	}Catch{
		LogException ("Unable to create $PrintLogFolder.") $_
		Return
	}

	# Event log
	$EventLogs = @(
		"System",
		"Application",
		"Microsoft-Windows-DeviceSetupManager/Admin",
		"Microsoft-Windows-DeviceSetupManager/Operational",
		"Microsoft-Windows-PrintService/Admin",
		"Microsoft-Windows-PrintService/Operational",
		"Microsoft-Windows-PrintBRM/Admin",
		"Microsoft-Windows-TerminalServices-Printers/Admin",
		"Microsoft-Windows-TerminalServices-Printers/Operational",

		# plus Universal Print related event logs
		"Microsoft-Windows-PrintConnector/Operational",
		"Microsoft-Windows-PrintConnectorUpdater/Admin",
		"Microsoft-Windows-PrintConnectorUpdater/Session"
	)
	FwExportEventLog $EventLogs $PrintLogFolder

	# File version
	LogInfo ("[Printing] Getting file version of printing modules")
	FwFileVersion -FilePath "$env:windir\System32\localspl.dll" | Out-File -Append "$($PrintLogPrefixCn)FileVersions.csv"
	FwFileVersion -FilePath "$env:windir\system32\spoolsv.exe" | Out-File -Append "$($PrintLogPrefixCn)FileVersions.csv"
	FwFileVersion -FilePath "$env:windir\system32\win32spl.dll" | Out-File -Append "$($PrintLogPrefixCn)FileVersions.csv"
	FwFileVersion -FilePath "$env:windir\system32\spoolss.dll" | Out-File -Append "$($PrintLogPrefixCn)FileVersions.csv"
	FwFileVersion -FilePath "$env:windir\system32\PrintIsolationProxy.dll" | Out-File -Append "$($PrintLogPrefixCn)FileVersions.csv"
	FwFileVersion -FilePath "$env:windir\system32\winspool.drv" | Out-File -Append "$($PrintLogPrefixCn)FileVersions.csv"
	FwFileVersion -FilePath "$env:windir\system32\spool\drivers\x64\3\unidrv.dll" | Out-File -Append "$($PrintLogPrefixCn)FileVersions.csv"

	# Other commands
	$Commands = @(
		# relevant User registry settings
		"reg query `'HKCU\Printers`' /s | Out-File $($PrintLogPrefixCn)reg-HKCU-Printers.txt",
		"reg query `'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Devices`' /s | Out-File $($PrintLogPrefixCn)reg-HKCU-devices.txt",
		"reg query `'HKCU\Software\Microsoft\Windows NT\CurrentVersion\PrinterPorts`' /s | Out-File $($PrintLogPrefixCn)reg-HKCU-printer-ports.txt",
		"reg query `'HKCU\Printers\ConvertUserDevModesCount`' /s | Out-File $($PrintLogPrefixCn)reg-HKCU-printers-DevModesCount.txt",
		"reg query `'HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows`' /s | Out-File $($PrintLogPrefixCn)reg-HKCU-Windows.txt",

		# relevant Machine registry settings
		"reg query `'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-Software-Print.txt",
		"reg query `'HKLM\Software\Policies\Microsoft\Windows NT\Printers`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-Software-Print-Policies.txt",
		"reg query `'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-Software-CSR.txt",
		"reg query `'HKLM\SYSTEM\CurrentControlSet\Control\Print`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-System-Print.txt",
		"reg query `'HKLM\SYSTEM\CurrentControlSet\Control\DeviceClasses`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-System-DeviceClasses.txt",
		"reg query `'HKLM\SYSTEM\CurrentControlSet\Control\DeviceContainers`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-System-DeviceContainers.txt",
		"reg query `'HKLM\SYSTEM\CurrentControlSet\Enum\USBPRINT`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-System-USBPRINT.txt",
		"reg query `'HKLM\SYSTEM\CurrentControlSet\Enum\SWD`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-System-SWD.txt",
		"reg query `'HKLM\SYSTEM\DriverDatabase`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-System-DriverDatabase.txt",
		"reg query `'HKLM\DRIVERS\DriverDatabase`' /s | Out-File $($PrintLogPrefixCn)reg-HKLM-Drivers-DriverDatabase.txt",

		# KIR registry overrides
		"reg query `'HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides`' /s | Out-File $($PrintLogPrefixCn)reg-KIR-Overrides.txt",

		# external cmds
		"sc.exe queryex spooler | Out-File -Append $($PrintLogPrefixCn)Spooler_ServiceConfig.txt",
		"netstat -anob | Out-File -Append $($PrintLogPrefixCn)netstat.txt",
		"ipconfig /all | Out-File -Append $($PrintLogPrefixCn)ipconfig.txt",
		"driverquery /v | Out-File -Append $($PrintLogPrefixCn)drivers.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prndrvr.vbs -l | Out-File -Append $($PrintLogPrefixCn)prndrvr_en.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prnmngr.vbs -l | Out-File -Append $($PrintLogPrefixCn)prnmngr_en.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prnjobs.vbs -l | Out-File -Append $($PrintLogPrefixCn)prnjobs_en.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prnport.vbs -l | Out-File -Append $($PrintLogPrefixCn)prnport_en.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\ja-JP\prndrvr.vbs -l | Out-File -Append $($PrintLogPrefixCn)prndrvr_ja.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\ja-JP\prnmngr.vbs -l | Out-File -Append $($PrintLogPrefixCn)prnmngr_ja.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\ja-JP\prnjobs.vbs -l | Out-File -Append $($PrintLogPrefixCn)prnjobs_ja.txt",
		"cscript $env:windir\System32\Printing_Admin_Scripts\ja-JP\prnport.vbs -l | Out-File -Append $($PrintLogPrefixCn)prnport_ja.txt",
		"tree $env:windir\Inf /f | Out-File -Append $($PrintLogPrefixCn)tree_inf.txt",
		"tree $env:windir\System32\DriverStore /f | Out-File -Append $($PrintLogPrefixCn)tree_DriverStore.txt",
		"tree $env:windir\System32\spool /f | Out-File -Append $($PrintLogPrefixCn)tree_spool.txt",
		"pnputil /export-pnpstate $($PrintLogPrefixCn)pnputil_pnpstate.pnp",
		"pnputil -e | Out-File -Append $($PrintLogPrefixCn)pnputil_e.txt",

		# copy files
		"Copy-Item `"$env:windir\Inf\oem*.inf`" $PrintLogInfFolder",
		"Copy-Item `"$env:windir\Inf\Setupapi*`" $PrintLogInfFolder"
	)
	RunCommands "Printing" $Commands -ThrowException:$False -ShowMessage:$True

	# Process dump
	FwCaptureUserDump "spoolsv" $PrintLogDumpFolder -IsService:$False
	FwCaptureUserDump "splwow64" $PrintLogDumpFolder -IsService:$False
	FwCaptureUserDump "PrintIsolationHost" $PrintLogDumpFolder -IsService:$False

	# From NET_PrintSvc
	$outFile = $PrefixTime + "Printerdriver_Stop_.txt"
	$Commands = @(
	"get-printer -full |fl; get-printerdriver |fl | Out-File -Append $outFile"
	"REG QUERY `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\PrinterExtensionAssociations`" /s | Out-File -Append $outFile"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	LogInfoFile "[$($MyInvocation.MyCommand.Name)] .. Copy WiaTrace"
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths.add(@("$Env:windir\debug\WIA\wiatrace.log", "$($PrintLogPrefixCn)wiatrace.log"))
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	LogInfo " .. collecting inf\setupapi*.log"
	LogInfoFile "[$($MyInvocation.MyCommand.Name)] .. Copy upgrade logs"
	$SourceDestinationPaths = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestinationPaths = @(
		@("$Env:windir\inf\setupapi.app.log", "$($PrintLogPrefixCn)setupapi.app.log"),
		@("$Env:windir\inf\setupapi.dev.log", "$($PrintLogPrefixCn)setupapi.dev.log"),
		@("$Env:windir\inf\setupapi.offline.log", "$($PrintLogPrefixCn)setupapi.offline.log"),
		@("$Env:windir\inf\setupapi.setup.log", "$($PrintLogPrefixCn)setupapi.setup.log"),
		@("$Env:windir\inf\setupapi.upgrade.log", "$($PrintLogPrefixCn)setupapi.upgrade.log")
	)
	FwCopyFiles $SourceDestinationPaths -ShowMessage:$False
	# Note: This will not be collected in case of -Collectlog
	FwAddRegItem @("Print") _Stop_ # Registries will be saved in XXX_Reg_Print_Stop_.txt in $global:LogFolder.
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_PrintCollectLog{
	# invokes external script until fully integrated into TSS
	EnterFunc $MyInvocation.MyCommand.Name
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling Print-Collect.ps1"
	.\scripts\Print-Collect.ps1 -DataPath $global:LogFolder -AcceptEula -Logs
	LogInfo "[$($MyInvocation.MyCommand.Name)] . Done Print-Collect.ps1"
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion PRINT FUNCTIONS


#region RDS FUNCTIONS
Function UEX_RDSPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS /t REG_DWORD /v EnableDeploymentUILog /d 1 /f | Out-Null
	reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS  /t REG_DWORD /v EnableUILog /d 1 /f | Out-Null
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_RDSPostStop {
	EnterFunc $MyInvocation.MyCommand.Name
	If(Test-Path -Path "C:\Windows\Logs\RDMSDeploymentUI.txt"){
		LogInfo ('[RDS] Copying RDMS-Deplyment log')
		Copy-Item "C:\Windows\Logs\RDMSDeploymentUI.txt" $LogFolder -Force -ErrorAction SilentlyContinue
	}
	If(Test-Path -Path "$env:temp\RdmsUI-trace.log"){
		LogInfo ('[RDS] Copying RDMS-UI log')
		Copy-Item "$env:temp\RdmsUI-trace.log" $LogFolder -Force -ErrorAction SilentlyContinue
	}
	reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS /F | Out-Null
	EndFunc $MyInvocation.MyCommand.Name
}

Function UEX_RDSsrvPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS /t REG_DWORD /v EnableDeploymentUILog /d 1 /f | Out-Null
	reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS  /t REG_DWORD /v EnableUILog /d 1 /f | Out-Null
	EndFunc $MyInvocation.MyCommand.Name
}
Function UEX_RDSsrvPostStop {
	EnterFunc $MyInvocation.MyCommand.Name
	If(Test-Path -Path "C:\Windows\Logs\RDMSDeploymentUI.txt"){
		LogInfo ('[RDS] Copying RDMS-Deplyment log')
		Copy-Item "C:\Windows\Logs\RDMSDeploymentUI.txt" $LogFolder -Force -ErrorAction SilentlyContinue
	}
	If(Test-Path -Path "$env:temp\RdmsUI-trace.log"){
		LogInfo ('[RDS] Copying RDMS-UI log')
		Copy-Item "$env:temp\RdmsUI-trace.log" $LogFolder -Force -ErrorAction SilentlyContinue
	}
	reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS /F | Out-Null
	EndFunc $MyInvocation.MyCommand.Name
}

function UEX_RDScommonPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	FwSetEventLog "Microsoft-Windows-CAPI2/Operational" -EvtxLogSize $global:EvtxLogSize
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectUEX_RDScommonLog {
	EnterFunc $MyInvocation.MyCommand.Name
	FwResetEventLog @("Microsoft-Windows-CAPI2/Operational")
	("Microsoft-Windows-CAPI2/Operational") | ForEach-Object { FwAddEvtLog $_ _Stop_}
	EndFunc $MyInvocation.MyCommand.Name
}

#Function CollectUEX_RDSLog{
<#
	EnterFunc $MyInvocation.MyCommand.Name
	$RDSLogFolder = "$LogFolder\RDSLog$LogSuffix"
	Try{
		FwCreateFolder $RDSLogFolder
	}Catch{
		LogException  ("Unable to create $RDSLogFolder.") $_
		Return
	}
	# For future use
	#$RDSobject = Get-CimInstance -Class Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices -ErrorAction SilentlyContinue
	#$RDSGateWay = Get-CimInstance -Class Win32_TSGatewayServer -Namespace root\cimv2\TerminalServices -ErrorAction SilentlyContinue
	#$RDSCB = Get-CimInstance -Class Win32_SessionDirectoryServer -Namespace root\cimv2 -ErrorAction SilentlyContinue
	#$RDSLS = Get-CimInstance -Class Win32_TSLicenseServer -Namespace root\cimv2 -ErrorAction SilentlyContinue

	# Event log
	$RDSEventLogs = Get-WinEvent -ListLog "*TerminalServices*" -ErrorAction SilentlyContinue
	$RDSEventLogs += Get-WinEvent -ListLog "*RemoteApp*" -ErrorAction SilentlyContinue
	$RDSEventLogs += Get-WinEvent -ListLog "*RemoteDesktop*" -ErrorAction SilentlyContinue
	$RDSEventLogs += Get-WinEvent -ListLog "*Rdms*" -ErrorAction SilentlyContinue
	$RDSEventLogs += Get-WinEvent -ListLog "*Hyper-V-Guest-Drivers*" -ErrorAction SilentlyContinue
	$EventLogs = @()
	ForEach($RDSEventLog in $RDSEventLogs){
		$EventLogs += $RDSEventLog.LogName
	}
	FwExportEventLog $EventLogs $RDSLogFolder

	# Registries
	$RDSRegistries = @(
		("HKCU:Software\Microsoft\Terminal Server Client", "$RDSLogFolder\Reg-HKCU-Terminal_Server_Client.txt"),
		("HKLM:Software\Microsoft\Terminal Server Client", "$RDSLogFolder\Reg-HKLM-Terminal_Server_Client.txt"),
		("HKLM:SOFTWARE\Policies\Microsoft\SystemCertificates", "$RDSLogFolder\Reg-HKLM-SystemCertificates.txt"),
		("HKLM:SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings", "$RDSLogFolder\Reg-HKLM-Internet_Settings.txt"),
		("HKLM:SYSTEM\CurrentControlSet\Control\Keyboard Layouts", "$RDSLogFolder\Reg-HKLM-Keyboard_Layouts.txt"),
		("HKLM:SYSTEM\CurrentControlSet\Services\i8042prt", "$RDSLogFolder\Reg-HKLM-i8042prt.txt"),
		("HKLM:SYSTEM\CurrentControlSet\Control\terminal Server", "$RDSLogFolder\Reg-HKLM-terminal_Server.txt"),
		("HKLM:Softwar\Microsoft\Windows NT\CurrentVersion\TerminalServerGateway", "$RDSLogFolder\Reg-HKLM-TerminalServerGateway.txt"),
		("HKCU:Software\Microsoft\Terminal Server Gateway", "$RDSLogFolder\Reg-HKCU-Terminal_Server_Gateway.txt"),
		("HKLM:Software\Policies\Microsoft\Windows NT\Terminal Services", "$RDSLogFolder\Reg-HKLM-Terminal_Services.txt"),
		("HKCU:Software\Policies\Microsoft\Windows NT\Terminal Services", "$RDSLogFolder\Reg-HKCU-Terminal_Services.txt"),
		("HKLM:SOFTWARE\Microsoft\MSLicensing", "$RDSLogFolder\Reg-HKLM-MSLicensing.txt")
	)
	FwExportRegistry "RDS" $RDSRegistries

	# Commands
	$Commands = @(
		"certutil -store `"Remote Desktop`" | Out-File -Append $RDSLogFolder\RDPcert.txt",
		"qwinsta  | Out-File -Append $RDSLogFolder\qwinsta.txt"
	)
	Runcommands "RDS" $Commands -ThrowException:$False -ShowMessage:$True

	# !!! Below section only work on RDCB !!!
	# Get Servers of the farm:
	Try{
		$RDDeploymentServer = Get-RDServer -ErrorAction Stop
	}Catch{
		LogInfo ("[RDS] This system would not be RD Conection Broker and skipping collecting data for RD deployment.")
		Return
	}

	LogInfo ("[RDS] Getting RD deployment info. This may take a while.")
	$LogFile = "$RDSLogFolder\RDDeployment-info.txt"
	$BrokerServers = @()
	$WebAccessServers = @()
	$RDSHostServers = @()
	$GatewayServers = @()

	ForEach($Server in $RDDeploymentServer){
		Switch($Server.Roles){
			"RDS-CONNECTION-BROKER" {$BrokerServers += $Server.Server}
			"RDS-WEB-ACCESS" {$WebAccessServers += $Server.Server}
			"RDS-RD-SERVER" {$RDSHostServers += $Server.Server}
			"RDS-GATEWAY" {$GatewayServers += $Server.Server}
		}
	}
	Write-Output ("Machines involved in the deployment : " + $servers.Count) | Out-File -Append $LogFile
	Write-Output ("	-Broker(s) : " + $BrokerServers.Count) | Out-File -Append $LogFile

	ForEach($BrokerServer in $BrokerServers){
		$ServicesStatus = Get-CimInstance -ComputerName $BrokerServer -Query "Select * from Win32_Service where Name='rdms' or Name='tssdis' or Name='tscpubrpc'"
		ForEach ($stat in $ServicesStatus){
			Write-Output ("			  - " + $stat.Name + " service is " + $stat.State) | Out-File -Append $LogFile
		}
	}

	Write-Output ("`n	-RDS Host(s) : " + $RDSHostServers.Count) | Out-File -Append $LogFile
	ForEach($RDSHostServer in $RDSHostServers){
		Write-Output ("		" +	$RDSHostServer) | Out-File -Append $LogFile
		$ServicesStatus = Get-CimInstance -ComputerName $RDSHostServer -Query "Select * from Win32_Service where Name='TermService'"
		ForEach($stat in $ServicesStatus){
			Write-Output ("			  - " + $stat.Name +  "service is " + $stat.State) | Out-File -Append $LogFile
		}
	}

	Write-Output ("`n	-Web Access Server(s) : " + $WebAccessServers.Count) | Out-File -Append $LogFile
	ForEach($WebAccessServer in $WebAccessServers){
		Write-Output ("		" +	$WebAccessServer) | Out-File -Append $LogFile
	}

	Write-Output ("`n	-Gateway server(s) : " + $GatewayServers.Count) | Out-File -Append $LogFile
	ForEach($GatewayServer in $GatewayServers){
		Write-Output ("		" +	$GatewayServer) | Out-File -Append $LogFile
		$ServicesStatus = Get-CimInstance -ComputerName $GatewayServer -Query "Select * from Win32_Service where Name='TSGateway'"
		ForEach($stat in $ServicesStatus){
			Write-Output ("			  - " + $stat.Name + " service is " + $stat.State) | Out-File -Append $LogFile
		}
	}

	#Get active broker server.
	$ActiveBroker = Invoke-WmiMethod -Path ROOT\cimv2\rdms:Win32_RDMSEnvironment -Name GetActiveServer
	$ConnectionBroker = $ActiveBroker.ServerName
	Write-Output ("`nActiveManagementServer (broker) : " +	$ActiveBroker.ServerName) | Out-File -Append $LogFile

	# Deployment Properties
	Write-Output ("`nDeployment details : ") | Out-File -Append $LogFile
	# Is Broker configured in High Availability?
	$HighAvailabilityBroker = Get-RDConnectionBrokerHighAvailability
	$BoolHighAvail = $false
	If($null -eq $HighAvailabilityBroker)
	{
		$BoolHighAvail = $false
		Write-Output ("	Is Connection Broker configured for High Availability : " + $BoolHighAvail) | Out-File -Append $LogFile
	}Else{
		$BoolHighAvail = $true
		Write-Output ("	Is Connection Broker configured for High Availability : " + $BoolHighAvail) | Out-File -Append $LogFile
		Write-Output ("		- Client Access Name (Round Robin DNS) : " + $HighAvailabilityBroker.ClientAccessName) | Out-File -Append $LogFile
		Write-Output ("		- DatabaseConnectionString : " + $HighAvailabilityBroker.DatabaseConnectionString) | Out-File -Append $LogFile
		Write-Output ("		- DatabaseSecondaryConnectionString : " + $HighAvailabilityBroker.DatabaseSecondaryConnectionString) | Out-File -Append $LogFile
		Write-Output ("		- DatabaseFilePath : " + $HighAvailabilityBroker.DatabaseFilePath) | Out-File -Append $LogFile
	}

	#Gateway Configuration
	$GatewayConfig = Get-RDDeploymentGatewayConfiguration -ConnectionBroker $ConnectionBroker
	Write-Output ("`n	Gateway Mode : " + $GatewayConfig.GatewayMode) | Out-File -Append $LogFile
	If($GatewayConfig.GatewayMode -eq "custom"){
		Write-Output ("		- LogonMethod : " + $GatewayConfig.LogonMethod) | Out-File -Append $LogFile
		Write-Output ("		- GatewayExternalFQDN : " + $GatewayConfig.GatewayExternalFQDN) | Out-File -Append $LogFile
		Write-Output ("		- GatewayBypassLocal : " + $GatewayConfig.BypassLocal) | Out-File -Append $LogFile
		Write-Output ("		- GatewayUseCachedCredentials : " + $GatewayConfig.UseCachedCredentials) | Out-File -Append $LogFile
	}

	# RD Licencing
	$LicencingConfig = Get-RDLicenseConfiguration -ConnectionBroker $ConnectionBroker
	Write-Output ("`n	Licencing Mode : " + $LicencingConfig.Mode) | Out-File -Append $LogFile
	If($LicencingConfig.Mode -ne "NotConfigured"){
		Write-Output ("		- Licencing Server(s) : " + $LicencingConfig.LicenseServer.Count) | Out-File -Append $LogFile
		foreach ($licserver in $LicencingConfig.LicenseServer)
		{
			Write-Output ("			   - Licencing Server : " + $licserver) | Out-File -Append $LogFile
		}
	}
	# RD Web Access
	Write-Output ("`n	Web Access Server(s) : " + $WebAccessServers.Count) | Out-File -Append $LogFile
	ForEach($WebAccessServer in $WebAccessServers){
		Write-Output ("		 - Name : " + $WebAccessServer) | Out-File -Append $LogFile
		Write-Output ("		 - Url : " + "https://" + $WebAccessServer + "/rdweb") | Out-File -Append $LogFile
	}

	# Certificates
	#Get-ChildItem -Path cert:\LocalMachine\my -Recurse | Format-Table -Property DnsNameList, EnhancedKeyUsageList, NotAfter, SendAsTrustedIssuer
	Write-Output ("`n	Certificates ") | Out-File -Append $LogFile
	$certificates = Get-RDCertificate -ConnectionBroker $ConnectionBroker
	ForEach($certificate in $certificates){
	Write-Output ("		- Role : " + $certificate.Role) | Out-File -Append $LogFile
	Write-Output ("			- Level : " + $certificate.Level) | Out-File -Append $LogFile
	Write-Output ("			- Expires on : " + $certificate.ExpiresOn) | Out-File -Append $LogFile
	Write-Output ("			- Issued To : " + $certificate.IssuedTo) | Out-File -Append $LogFile
	Write-Output ("			- Issued By : " + $certificate.IssuedBy) | Out-File -Append $LogFile
	Write-Output ("			- Thumbprint : " + $certificate.Thumbprint) | Out-File -Append $LogFile
	Write-Output ("			- Subject : " + $certificate.Subject) | Out-File -Append $LogFile
	Write-Output ("			- Subject Alternate Name : " + $certificate.SubjectAlternateName) | Out-File -Append $LogFile
	}

	#RDS Collections
	$collectionnames = Get-RDSessionCollection
	$client = $null
	$connection = $null
	$loadbalancing = $null
	$Security = $null
	$UserGroup = $null
	$UserProfileDisks = $null

	Write-Output ("`nRDS Collections : ") | Out-File -Append $LogFile
	ForEach($Collection in $collectionnames){
		$CollectionName = $Collection.CollectionName
		Write-Output ("	Collection : " +  $CollectionName) | Out-File -Append $LogFile
		Write-Output ("		Resource Type : " + $Collection.ResourceType) | Out-File -Append $LogFile
		If($Collection.ResourceType -eq "RemoteApp programs"){
			Write-Output ("			Remote Apps : ")
			$remoteapps = Get-RDRemoteApp -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName
			foreach ($remoteapp in $remoteapps){
				Write-Output ("			- DisplayName : " + $remoteapp.DisplayName) | Out-File -Append $LogFile
				Write-Output ("				- Alias : " + $remoteapp.Alias) | Out-File -Append $LogFile
				Write-Output ("				- FilePath : " + $remoteapp.FilePath) | Out-File -Append $LogFile
				Write-Output ("				- Show In WebAccess : " + $remoteapp.ShowInWebAccess) | Out-File -Append $LogFile
				Write-Output ("				- CommandLineSetting : " + $remoteapp.CommandLineSetting) | Out-File -Append $LogFile
				Write-Output ("				- RequiredCommandLine : " + $remoteapp.RequiredCommandLine) | Out-File -Append $LogFile
				Write-Output ("				- UserGroups : " + $remoteapp.UserGroups) | Out-File -Append $LogFile
			}
		}

		# $rdshServers
		$rdshservers = Get-RDSessionHost -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName
		Write-Output ("`n		Servers in that collection : ") | Out-File -Append $LogFile
		ForEach ($rdshServer in $rdshservers){
			Write-Output ("			- SessionHost : " + $rdshServer.SessionHost) | Out-File -Append $LogFile
			Write-Output ("				- NewConnectionAllowed : " + $rdshServer.NewConnectionAllowed) | Out-File -Append $LogFile
		}

		$client = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -Client
		Write-Output ("		Client Settings : ") | Out-File -Append $LogFile
		Write-Output ("			- MaxRedirectedMonitors : " + $client.MaxRedirectedMonitors) | Out-File -Append $LogFile
		Write-Output ("			- RDEasyPrintDriverEnabled : " + $client.RDEasyPrintDriverEnabled) | Out-File -Append $LogFile
		Write-Output ("			- ClientPrinterRedirected : " + $client.ClientPrinterRedirected) | Out-File -Append $LogFile
		Write-Output ("			- ClientPrinterAsDefault : " + $client.ClientPrinterAsDefault) | Out-File -Append $LogFile
		Write-Output ("			- ClientDeviceRedirectionOptions : " + $client.ClientDeviceRedirectionOptions) | Out-File -Append $LogFile

		$connection = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -Connection
		Write-Output ("`n		Connection Settings : ") | Out-File -Append $LogFile
		Write-Output ("			- DisconnectedSessionLimitMin : " + $connection.DisconnectedSessionLimitMin) | Out-File -Append $LogFile
		Write-Output ("			- BrokenConnectionAction : " + $connection.BrokenConnectionAction) | Out-File -Append $LogFile
		Write-Output ("			- TemporaryFoldersDeletedOnExit : " + $connection.TemporaryFoldersDeletedOnExit) | Out-File -Append $LogFile
		Write-Output ("			- AutomaticReconnectionEnabled : " + $connection.AutomaticReconnectionEnabled) | Out-File -Append $LogFile
		Write-Output ("			- ActiveSessionLimitMin : " + $connection.ActiveSessionLimitMin) | Out-File -Append $LogFile
		Write-Output ("			- IdleSessionLimitMin : " + $connection.IdleSessionLimitMin) | Out-File -Append $LogFile

		$loadbalancing = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -LoadBalancing
		Write-Output ("`n		Load Balancing Settings : ") | Out-File -Append $LogFile
		ForEach($SessHost in $loadbalancing){
			Write-Output ("			- SessionHost : " + $SessHost.SessionHost) | Out-File -Append $LogFile
			Write-Output ("				- RelativeWeight : " + $SessHost.RelativeWeight) | Out-File -Append $LogFile
			Write-Output ("				- SessionLimit : " + $SessHost.SessionLimit) | Out-File -Append $LogFile
		}

		$Security = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -Security
		Write-Output ("`n		Security Settings : ") | Out-File -Append $LogFile
		Write-Output ("			- AuthenticateUsingNLA : " + $Security.AuthenticateUsingNLA) | Out-File -Append $LogFile
		Write-Output ("			- EncryptionLevel : " + $Security.EncryptionLevel) | Out-File -Append $LogFile
		Write-Output ("			- SecurityLayer : " + $Security.SecurityLayer) | Out-File -Append $LogFile

		$UserGroup = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -UserGroup
		Write-Output ("`n		User Group Settings : ") | Out-File -Append $LogFile
		Write-Output ("			- UserGroup  : " + $UserGroup.UserGroup) | Out-File -Append $LogFile

		$UserProfileDisks = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName -UserProfileDisk
		Write-Output ("		User Profile Disk Settings : ") | Out-File -Append $LogFile
		Write-Output ("			- EnableUserProfileDisk : " + $UserProfileDisks.EnableUserProfileDisk) | Out-File -Append $LogFile
		Write-Output ("			- MaxUserProfileDiskSizeGB : " + $UserProfileDisks.MaxUserProfileDiskSizeGB) | Out-File -Append $LogFile
		Write-Output ("			- DiskPath : " + $UserProfileDisks.DiskPath) | Out-File -Append $LogFile
		Write-Output ("			- ExcludeFilePath : " + $UserProfileDisks.ExcludeFilePath) | Out-File -Append $LogFile
		Write-Output ("			- ExcludeFolderPath : " + $UserProfileDisks.ExcludeFolderPath) | Out-File -Append $LogFile
		Write-Output ("			- IncludeFilePath : " + $UserProfileDisks.IncludeFilePath) | Out-File -Append $LogFile
		Write-Output ("			- IncludeFolderPath : " + $UserProfileDisks.IncludeFolderPath) | Out-File -Append $LogFile

		$CustomRdpProperty = Get-RDSessionCollectionConfiguration -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName
		Write-Output ("`n		Custom Rdp Properties : " + $CustomRdpProperty.CustomRdpProperty) | Out-File -Append $LogFile

		$usersConnected = Get-RDUserSession -ConnectionBroker $ConnectionBroker -CollectionName $CollectionName
		Write-Output ("`n		Users connected to this collection : ") | Out-File -Append $LogFile
		Foreach($userconnected in $usersConnected){
			Write-Output ("			User : " + $userConnected.DomainName + "\" + $userConnected.UserName) | Out-File -Append $LogFile
			Write-Output ("				- HostServer : " + $userConnected.HostServer) | Out-File -Append $LogFile
			Write-Output ("				- UnifiedSessionID : " + $userConnected.UnifiedSessionID) | Out-File -Append $LogFile
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}#>

Function CollectUEX_RDSSourceLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $true; $global:msrdTarget = $false
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$true * 12)

	$parameters = @{
        varsSystem = @(,$true * 12)
        varsAVDRDS = @(,$true * 11)
        varsInfra = @(,$true * 10)
        varsAD = @(,$true * 2)
        varsNET = @(,$true * 8)
        varsLogSec = @(,$true * 3)
        varsIssues = @(,$true * 2)
        varsOther = @(,$true * 4)
    }
    msrdCollectDataDiag @parameters
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_RDSCoreLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$true * 12) -skipDiagCounter
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_RDSProfilesLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsProfiles @(,$true * 5) -skipDiagCounter
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_RDSActivationLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsActivation @(,$true * 3) -skipDiagCounter
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_RDSMSRALog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsMSRA @(,$true * 6) -skipDiagCounter
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_RDSSCardLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsSCard @(,$true * 3) -skipDiagCounter
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_RDSIMELog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }
	msrdInitScenarioVars
    msrdCollectData -varsCore @(,$false * 1) -varsIME @(,$true * 3) -skipDiagCounter
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectUEX_RDSDiagLog{

	EnterFunc $MyInvocation.MyCommand.Name

	$global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false
	$global:msrdSource = $false; $global:msrdTarget = $true
	$global:msrdScriptpath = "$global:ScriptFolder\scripts\MSRD-Collect"

	if (-not $script:msrdDotSourced) { . .\scripts\MSRD-Collect\MSRD-Collect.ps1; $script:msrdDotSourced = $true }
	if (-not $script:msrdFoldersInitialized) { msrdInitFolders; $script:msrdFoldersInitialized = $true }

    $global:onlyDiag = $true
	$parameters = @{
        varsSystem = @(,$true * 12)
        varsAVDRDS = @(,$true * 11)
        varsInfra = @(,$true * 10)
        varsAD = @(,$true * 2)
        varsNET = @(,$true * 8)
        varsLogSec = @(,$true * 3)
        varsIssues = @(,$true * 2)
        varsOther = @(,$true * 4)
    }
    msrdCollectDataDiag @parameters
	UEX_NoTraceCleanup -tech RDS

	EndFunc $MyInvocation.MyCommand.Name
}
#endregion PRINT FUNCTIONS


#region UE-V FUNCTIONS
Function CollectUEX_UEVLog{
	EnterFunc $MyInvocation.MyCommand.Name
	Try{
		$Status = Get-UevStatus -ErrorAction SilentlyContinue
	}Catch{
		LogInfo ("Get-UevStatus failed. Probably this system does not have UE-V feature.")
		Return
	}
	If($Null -ne $Status -and !$Status.UevEnabled){
		LogMessage $LogLevel.Warning ("UEV is not enabled.")
		Return
	}

	$UEVTasks =@(
		"Monitor Application Settings",
		"Sync Controller Application",
		"Synchronize Settings at Logoff",
		"Template Auto Update"
	)

	$UEVLogFolder = "$LogFolder\UEVLog$LogSuffix"
	Try{
		FwCreateFolder $UEVLogFolder
	}Catch{
		LogException  ("Unable to create $UEVLogFolder.") $_
		Return
	}

	Try{
		$RegistryFolder = Join-Path $UEVLogFolder "Registry"
		New-Item $RegistryFolder -ItemType Directory -ErrorAction Stop | Out-Null
		$SchedulerFolder = Join-Path $UEVLogFolder "TaskScheduler"
		New-Item $SchedulerFolder -ItemType Directory -ErrorAction Stop | Out-Null
		$TemplateFolder = Join-Path $UEVLogFolder "UEV-Templates"
		New-Item $TemplateFolder -ItemType Directory -ErrorAction Stop | Out-Null
		$PackageFolder = Join-Path $UEVLogFolder "UEV-Packages"
		New-Item $PackageFolder -ItemType Directory -ErrorAction Stop | Out-Null
		#$EventLogFolder = Join-Path $UEVLogFolder "EventLogs"
		#New-Item $EventLogFolder -ItemType Directory | Out-Null
	}Catch{
		LogException ("An exception happened during creation of logfoler") $_
		Return
	}

	LogInfo ("[UEV] Exporting UE-V regstries.")
	reg export "HKLM\SOFTWARE\Microsoft\UEV" (Join-Path $RegistryFolder "UEV.reg") | Out-Null
	reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule" (Join-Path $RegistryFolder "Schedule.reg")| Out-Null
	reg save "HKLM\SYSTEM" (Join-Path $RegistryFolder "SYSTEM.hiv")| Out-Null
	reg save "HKLM\Software" (Join-Path $RegistryFolder "Software.hiv")| Out-Null

	# UEV Tasks
	LogInfo ("[UEV] Exporting UE-V tasks.")
	ForEach($UEVTask in $UEVTasks){
		schtasks /query /xml /tn ("\Microsoft\UE-V\" + $UEVTask) > ($SchedulerFolder + "\" + $UEVTask + ".xml")
	}

	# UEV configuration
	LogInfo ("[UEV] Running UE-V commandlets")
	Get-UEVStatus | Out-File (Join-Path $UEVLogFolder "Get-UevStatus.txt")
	Get-UEVConfiguration | Out-File (Join-Path $UEVLogFolder "Get-UEVConfiguration.txt")
	Get-UEVTemplate  | Out-File (Join-Path $UEVLogFolder "Get-UEVTemplate.txt")

	# UEV template
	LogInfo ("[UEV] Copying all templates to log folder.")
	Copy-Item  ("C:\ProgramData\Microsoft\UEV\Templates\*") $TemplateFolder -Recurse

	# UEV package
	$UEVConfig = Get-UEVConfiguration

	If($UEVConfig.SettingsStoragePath.Length -ne 0){
		$PackagePath = [System.Environment]::ExpandEnvironmentVariables($UEVConfig.SettingsStoragePath + "\SettingsPackages")

		If($PackagePath -ne $Null){
			LogInfo ("[UEV] Found package path: $PackagePath")
			If(Test-Path -Path $PackagePath){
				$PackageFiles = Get-ChildItem $PackagePath "*.pkgx" -Recurse -Depth 5
				If($PackageFiles.Length -ne 0 -and $Null -ne $PackageFiles){
					LogInfo ('[UEV] Copying UE-V packages')
					ForEach($PackageFile in $PackageFiles){
						Copy-Item  $PackageFile.fullname $PackageFolder -Recurse
					}
				}
			}
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}
#endregion UE-V FUNCTIONS

#endregion ### Pre-Start / Post-Stop / Collect functions for trace components and scenarios


#region example special Functions - not used so far
ForEach ($UEX_ETWSwitchStatus in $ETWTracingSwitchesStatus){
	switch ($UEX_ETWSwitchStatus){
		"UEX_Scenario1" {Start-UEX_Scenario1 ('1', '2')}
		"UEX_Scenario2" {Start-UEX_Scenario2 ('dummy parameter')}
		"UEX_Robert" {Start-UEX_Robert ('dummy parameter')}
		default{Write-Host "No match found in Start-UEX* module functions of TSS_UEX.psm1."}
	}
}
#Implementations of the specific data collection scenario
function Start-UEX_Scenario1{
	# -------------- UEX_Scenario1 ---------------
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullorEmpty()]
		[Array]$UEX_Scenario1_params
	)
	#register stop function
	$global:StopModuleCallbackFunctions += 'Stop-UEX_Scenario1'
	#add your custom code
}
function Stop-UEX_Scenario1{
	#add your custom code
	Write-Host "Stop UEX_Scenario_1"
}
function Start-UEX_Scenario2{
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullorEmpty()]
		[Array]$UEX_Scenario2_params
	)

	#register stop function
	$global:StopModuleCallbackFunctions += 'Stop-UEX_Scenario2'
	#add your custom code
}
function Stop-UEX_Scenario2{
	#add your custom code
	Write-Host "Stop UEX_Scenario_2"
}
function Start-UEX_Robert{
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullorEmpty()]
		[Array]$UEX_Rober_params
	)
	#register stop function
	$global:StopModuleCallbackFunctions += 'Stop-UEX_Scenario2'
	#add your custom code
}
function Stop-UEX_Robert{
	#add your custom code
	Write-Host "Stop UEX_Robert"
}
#endregion example special Functions - not used so far


#region Registry Key modules for FwAddRegItem
	$global:KeysAppV = @("HKLM:Software\Microsoft\AppV", "HKCU:Software\Microsoft\AppV", "HKCU:Software\Classes\AppV")
	$global:KeysFSLogix = @("HKLM:Software\FSLogix", "HKLM:Software\Policies\Fslogix")

	# RegKeys MDAG
	$global:KeysMDAG_HKLM_SW_Browsers_LookAside = @("HKLM:SOFTWARE\Google\Chrome\NativeMessagingHosts\com.microsoft.wdagcore", "HKLM:SOFTWARE\Mozilla\NativeMessagingHosts\com.microsoft.wdagcore","HKLM:SOFTWARE\Microsoft\Edge", "HKLM:SOFTWARE\Microsoft\Edge Beta", "HKLM:SOFTWARE\Microsoft\Edge Dev", "HKLM:SOFTWARE\Microsoft\Edge SxS")
	$global:KeysMDAG_HKLM_SW_MS_EDP_Policies = @("HKLM:SOFTWARE\Microsoft\EnterpriseDataProtection\Policies")
	$global:KeysMDAG_HKLM_SW_MS_Enrollments = @("HKLM:SOFTWARE\Microsoft\Enrollments")
	$global:KeysMDAG_HKLM_SW_MS_HVSI = @("HKLM:SOFTWARE\Microsoft\HVSI", "HKLM:SOFTWARE\Microsoft\HVSICSP", "HKLM:SOFTWARE\Microsoft\HVSIGP", "HKLM:SOFTWARE\Microsoft\HvsiDeployment")
	$global:KeysMDAG_HKLM_SW_MS_PolicyManager_NetworkIsolation =@("HKLM:SOFTWARE\Microsoft\PolicyManager\current\device\")
	$global:KeysMDAG_HKLM_SW_POL_MS = @("HKLM:SOFTWARE\Policies\Microsoft\AppHVSI", "HKLM:SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions", "HKLM:SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation")
	$global:KeysMDAG_HKLM_System_CCS_Services = @("HKLM:SYSTEM\CurrentControlSet\Services\WinNat", "HKLM:SYSTEM\CurrentControlSet\Services\hns", "HKLM:SYSTEM\CurrentControlSet\Services\vmsmp\parameters\SwitchList", "HKLM:SYSTEM\CurrentControlSet\Services\vmsmp\parameters\NicList" )
	$global:KeysMDAG_HKLM_System_CCS_Control_GraphicsAndGpu = @("HKLM:SYSTEM\CurrentControlSet\Control\GraphicsDrivers", "HKLM:SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}")
	$global:KeysMDAG_HKLM_System_CCS_HNS = @("HKLM:SYSTEM\CurrentControlSet\Services\HNS")

#endregion Registry Key modules


#region groups of Eventlogs for FwAddEvtLog
	$global:EvtLogsPowerShell = @("Microsoft-Windows-PowerShell/Admin", "Microsoft-Windows-PowerShell/Operational", "PowerShellCore/Operational")
	$global:EvtLogsWDAG=("Microsoft-Windows-WDAG-Manager/Operational", "Microsoft-Windows-WDAG-PolicyEvaluator-CSP/Operational","Microsoft-Windows-WDAG-PolicyEvaluator-GP/Operational","Microsoft-Windows-WDAG-Service/Operational")
	$global:EvtLogsTelemetry = @("Microsoft-Windows-UniversalTelemetryClient/Operational")
	$global:EvtLogsAppV=("Microsoft-AppV-Client/Admin","Microsoft-AppV-Client/Operational","Microsoft-AppV-Client/Virtual Applications","Microsoft-AppV-Server-Management/Admin","Microsoft-AppV-Server-Publishing/Operational")
	$global:EvtLogsAppLocker=("Microsoft-Windows-AppLocker/EXE and DLL", "Microsoft-Windows-AppLocker/MSI and Script", "Microsoft-Windows-AppLocker/Packaged app-Deployment", "Microsoft-Windows-AppLocker/Packaged app-Execution")
#endregion groups of Eventlogs

#region Deprecated parameter list. Property array of deprecated/obsoleted params.
#   DeprecatedParam: Parameters to be renamed or obsoleted in the future
#   Type		   : Can take either 'Rename' or 'Obsolete'
#   NewParam	   : Provide new parameter name for replacement only when Type=Rename. In case of Type='Obsolete', put null for the value.
$UEX_DeprecatedParamList = @(
	@{DeprecatedParam='UEX_Alarm';Type='Rename';NewParam='PRF_Alarm'} #To Delete in August 2024
	@{DeprecatedParam='UEX_AppX';Type='Rename';NewParam='PRF_AppX'} #To Delete in August 2024
	@{DeprecatedParam='UEX_AVDMSIXAA';Type='Rename';NewParam='UEX_AVDAppAttach'}
	@{DeprecatedParam='UEX_Calc';Type='Rename';NewParam='PRF_Calc'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Camera';Type='Rename';NewParam='PRF_Camera'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Clipboard';Type='Rename';NewParam='PRF_Clipboard'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Cortana';Type='Rename';NewParam='PRF_Cortana'} #To Delete in August 2024
	@{DeprecatedParam='UEX_DM';Type='Rename';NewParam='PRF_DM'} #To Delete in August 2024
	@{DeprecatedParam='UEX_DWM';Type='Rename';NewParam='PRF_DWM'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Font';Type='Rename';NewParam='PRF_Font'} # To Delete in August 2024
	@{DeprecatedParam='UEX_IME';Type='Rename';NewParam='PRF_IME'} #To Delete in August 2024
	@{DeprecatedParam='UEX_ImmersiveUI';Type='Rename';NewParam='PRF_ImmersiveUI'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Media';Type='Rename';NewParam='PRF_Media'} #To Delete in August 2024
	@{DeprecatedParam='UEX_NLS';Type='Rename';NewParam='PRF_NLS'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Photo';Type='Rename';NewParam='PRF_Photo'} #To Delete in August 2024
	@{DeprecatedParam='UEX_PrintEx';Type='Rename';NewParam='UEX_Print'}
	@{DeprecatedParam='UEX_RDS$';Type='Rename';NewParam='"UEX_RDScli|UEX_RDSsrv"'}
	@{DeprecatedParam='UEX_SCM';Type='Rename';NewParam='PRF_SCM'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Shell';Type='Rename';NewParam='PRF_Shell'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Search';Type='Rename';NewParam='PRF_Search'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Sched';Type='Rename';NewParam='UEX_TSched'}
	@{DeprecatedParam='UEX_Shutdown';Type='Rename';NewParam='PRF_Shutdown'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Speech';Type='Rename';NewParam='PRF_Speech'} #To Delete in August 2024
	@{DeprecatedParam='UEX_StartMenu';Type='Rename';NewParam='PRF_StartMenu'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Store';Type='Rename';NewParam='PRF_Store'} #To Delete in August 2024
	@{DeprecatedParam='UEX_SystemSettings';Type='Rename';NewParam='PRF_SystemSettings'} #To Delete in August 2024
	@{DeprecatedParam='UEX_Task';Type='Rename';NewParam='UEX_TSched'}
	#@{DeprecatedParam='UEX_WinRM';Type='Rename';NewParam='UEX_WinRMBase'} # Added on MAy 2024 by Garabier
	#@{DeprecatedParam='UEX_WMI';Type='Rename';NewParam='UEX_WMIBase'} # Added on MAy 2024 by Garabier
	@{DeprecatedParam='UEX_XAML';Type='Rename';NewParam='PRF_XAML'} #To Delete in August 2024
	@{DeprecatedParam='UEX_EventLog';Type='Rename';NewParam='UEX_Evt'} #Added in May 2024 by Garabier

	
)
#endregion Deprecated parameter list.

Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *

# SIG # Begin signature block
# MIIoKgYJKoZIhvcNAQcCoIIoGzCCKBcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAgCx8myjBX+gv/
# vlGqCauYfNVCA/PDVRhsd0qIQLCA3KCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP5zML5JpkmKEqy9cyFsncGo
# mOaxrj+/dMCdftQa5NVaMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAErrzjbl0e33agltnJEGPxn1xoXIGSX3og9ax4LS6hRb4sSwkZhI0JJR0
# 5hIV4My54kDQ6GkwrA6bwHfUHS1pEr3GMPWrWb49x5mxit4lr3ljgHRHK7INamkC
# NBY1iY6R0VR/wrdqAfmIowtMvKUEe3jpxBoWJi6IY5VCI1WxFcFjCgMOOKmqdyme
# trs/11KKg2xpU4f0dNCPswTaaGotAWjbLJDkCOi1EmYsLic8hjoXv0bxqdtYr1gX
# hTHQYGSvWhq2eCNeI9ZdDGa9CH+D2ZO8QrJ2XbMDZG8N6Lk7W8Th3k8A4Dya6eLx
# Bu8myLOl9axZlAPEnZiSF3FqTLzJFaGCF5QwgheQBgorBgEEAYI3AwMBMYIXgDCC
# F3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCBMPdx9sZBz0XovFj+RzXGDelqze4GmJKmAoQxZjOvIfAIGZkZOOeFa
# GBMyMDI0MDYxMjE0NTg0OS40NTFaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046RTAwMi0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHqMIIHIDCCBQigAwIBAgITMwAAAe4F0wIwspqdpwABAAAB7jANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# NDRaFw0yNTAzMDUxODQ1NDRaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046RTAwMi0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC+8byl16KEia8xKS4vVL7REOOR7LzYCLXEtWgeqyOV
# lrzuEz+AoCa4tBGESjbHTXECeMOwP9TPeKaKalfTU5XSGjpJhpGx59fxMJoTYWPz
# zD0O2RAlyBmOBBmiLDXRDQJL1RtuAjvCiLulVQeiPI8V7+HhTR391TbC1beSxwXf
# dKJqY1onjDawqDJAmtwsA/gmqXgHwF9fZWcwKSuXiZBTbU5fcm3bhhlRNw5d04Ld
# 15ZWzVl/VDp/iRerGo2Is/0Wwn/a3eGOdHrvfwIbfk6lVqwbNQE11Oedn2uvRjKW
# EwerXL70OuDZ8vLzxry0yEdvQ8ky+Vfq8mfEXS907Y7rN/HYX6cCsC2soyXG3OwC
# tLA7o0/+kKJZuOrD5HUrSz3kfqgDlmWy67z8ZZPjkiDC1dYW1jN77t5iSl5Wp1HK
# Bp7JU8RiRI+vY2i1cb5X2REkw3WrNW/jbofXEs9t4bgd+yU8sgKn9MtVnQ65s6QG
# 72M/yaUZG2HMI31tm9mooH29vPBO9jDMOIu0LwzUTkIWflgd/vEWfTNcPWEQj7fs
# WuSoVuJ3uBqwNmRSpmQDzSfMaIzuys0pvV1jFWqtqwwCcaY/WXsb/axkxB/zCTdH
# SBUJ8Tm3i4PM9skiunXY+cSqH58jWkpHbbLA3Ofss7e+JbMjKmTdcjmSkb5oN8qU
# 1wIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFBCIzT8a2dwgnr37xd+2v1/cdqYIMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQB3ZyAva2EKOWSVpBnYkzX8f8GZjaOs577F
# 9o14Anh9lKy6tS34wXoPXEyQp1v1iI7rJzZVG7rpUznay2n9csfn3p6y7kYkHqtS
# ugCGmTiiBkwhFfSByKPI08MklgvJvKTZb673yGfpFwPjQwZeI6EPj/OAtpYkT7IU
# XqMki1CRMJKgeY4wURCccIujdWRkoVv4J3q/87KE0qPQmAR9fqMNxjI3ZClVxA4w
# iM3tNVlRbF9SgpOnjVo3P/I5p8Jd41hNSVCx/8j3qM7aLSKtDzOEUNs+ZtjhznmZ
# gUd7/AWHDhwBHdL57TI9h7niZkfOZOXncYsKxG4gryTshU6G6sAYpbqdME/+/g1u
# er7VGIHUtLq3W0Anm8lAfS9PqthskZt54JF28CHdsFq/7XVBtFlxL/KgcQylJNni
# a+anixUG60yUDt3FMGSJI34xG9NHsz3BpqSWueGtJhQ5ZN0K8ju0vNVgF+Dv05si
# rPg0ftSKf9FVECp93o8ogF48jh8CT/B32lz1D6Truk4Ezcw7E1OhtOMf7DHgPMWf
# 6WOdYnf+HaSJx7ZTXCJsW5oOkM0sLitxBpSpGcj2YjnNznCpsEPZat0h+6d7ulRa
# WR5RHAUyFFQ9jRa7KWaNGdELTs+nHSlYjYeQpK5QSXjigdKlLQPBlX+9zOoGAJho
# Zfrpjq4nQDCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkUwMDItMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQCI
# o6bVNvflFxbUWCDQ3YYKy6O+k6CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hO6iTAiGA8yMDI0MDYxMjA2MTEy
# MVoYDzIwMjQwNjEzMDYxMTIxWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDqE7qJ
# AgEAMAcCAQACAhjHMAcCAQACAhNuMAoCBQDqFQwJAgEAMDYGCisGAQQBhFkKBAIx
# KDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
# hvcNAQELBQADggEBAFxYjTZUlz7PWdLzwkrOQ7RLBD0OqYAOMtcyedD9PpwAJpfl
# 5YCAn1YlfRMKNFHCxcaKXb1Y0DJ0pTLKYpsMqHGyYFKm+uenYrCHjNYmeXeeLGtf
# Md2ihT1k6s8ei42ZRjxghe+zguP6kw4sAaD9QQ8a1WC3Z8jBeCuRYVJzbk1oHcFf
# ZjxZJ7tDXkkagXbmJ391+SYApiGe6ak7UU3HxlV2LMAbqk4ebDRRGj3MZKLNo2YG
# CBiMX50EmzRDVc5jHGdrMfepj6fVWSvF5TE+OQeDIHgvIOXDXzSxOS6gwqooHt3v
# y+ovVSNC+l4dP1skexBUCmfVTbGj+kYDbKcUMGAxggQNMIIECQIBATCBkzB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAe4F0wIwspqdpwABAAAB7jAN
# BglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8G
# CSqGSIb3DQEJBDEiBCAAF0jt79aIsYQT5kdTZq8BUqoYFgc7UepvUaVFefH6rzCB
# +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIE9QdxSVhfq+Vdf+DPs+5EIkBz9o
# CS/OQflHkVRhfjAhMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAHuBdMCMLKanacAAQAAAe4wIgQg2SaSToU0YvztJJOK0/jyPzMSAdnj
# dqHXXs0fd5SMr5owDQYJKoZIhvcNAQELBQAEggIAEDVX1s3Dleqc1Df/zb7sMNs5
# sph8KuF1Rzw9V7lDW1IQrUqeAhuq+8vy/PiSrhMnsmBO8MxdKSGZ4IZ8MPupAHfz
# hNcotXctCpP3fKfrpLF6o+UWgAxYoXKahf4Z1JV6sGNHLKIbqgI9OhR/D7Wz1ai3
# UpAzhJOg3I/g3LYU7I+d7TVU+gyNSje/DaKJY+cxH8xyd+i3YcgBCYON/7hj2LaR
# Ez+cZX3opkIen1kBqnKCfHnTP1dpxCOjf1oBUW+4ECrC4vi47c50VJGv+mArCCY6
# I2GUZYICokGnt5lyPgH7hQJyzpmYDiUyf2WGKebGFCstvvpy3YuCRnHQzlE0SY4i
# hEzB5lQAjZxlEtDeN2ZD3G1poLHll2lhCrTR2IKoPeno2n2++Gc0K96HmAT/sOn4
# 1yqHOCzxfGO9kYmfbrT8eAHz7FFxxfT/Mu+kr3AjCt0VIakV4bDcUHue0G7m2aAj
# liSvCPeGAYGszDMIkdJVTjqxodPZ8ixX1S/cToCs+yL0Qf62sSs7OhUVDNocER2A
# indq9GMwY4NS8ZRmw/MCr5HbJUYDUEH5SjgE3/dAHmI0dDtcE55knobpszqY64hH
# bAVGqtiOT0Iac/3CIfHUk7ckZGLQwGWkEz0eEyaMsxyHR4YPGutk0B5uMcupqQVB
# mmM4d/DBonYGIMXW3EM=
# SIG # End signature block
