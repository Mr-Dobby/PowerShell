<#
.SYNOPSIS
   SHA module for collecting ETW traces and various custom tracing functionality

.DESCRIPTION
   Define ETW traces for Windows SHA components 
   Add any custom tracing functinaliy for tracing SHA components
   For Developers:
   1. Component test: .\TSS.ps1 -Start -SHA_TEST1
   2. Scenario test:  .\TSS.ps1 -start -Scenario SHA_MyScenarioTest

.NOTES
	Dev. Lead: ?
   Authors	: <your_alias>;WalterE; RobertVi; Kojii
   Requires : PowerShell V4 (Supported from Windows 8.1/Windows Server 2012 R2)
   Version	: see $global:TssVerDateSHA

.LINK
	TSS https://internal.evergreen.microsoft.com/en-us/help/4619187
	SHA https://internal.evergreen.microsoft.com/en-us/help/5009525
#>

<# latest changes

::  2024.03.06.0 [gr] _SHA: Feature 681 Modified the SHA_HypHost to add some file collection
::  2024.01.23.0 [ki] _SHA: renew GetEvents24.vbs from GetEvents24.vbs and Changed time notation from AM/PM to 24H in GetEvents24.vbs
::  2024.01.15.0 [ki] _SHA: fix drive letter to gether file list of dir command option in CollectSHA_support-space
::  2024.01.09.0 [ki] _SHA: remove cluster command outputs in CollectSHA_support-clusterLog, add Get-WindowsFeature in in CollectSHA_support-systemLog and add NetworkATC in CollectSHA_support-NetworkLog
::  2023.11.27.0 [ki] _SHA: imprement MSDTC Trace and add pnpstate information, ESU information and Hyper-V Replica information
::  2023.10.05.0 [ki] _SHA: delete Get-FsrmRmsTemplate from fsrm support logs
::  2023.09.14.0 [ki] _SHA: add GUID in SHA_NTFS trace, deprecate NET_NTFS trace
::  2023.08.07.0 [we] _SHA: replaced all SHA_Support_ with SHA_Support-, added Help text in _FW
::  2023.08.06.0 [we] _SHA: replaced FwCreateLogFolder with FwCreateFolder
::  2023.08.04.1 [we] _SHA: replaced $Du with $global:DuExe (defined in TSS.ps1), same for $global:ChecksymExe; replaced FwCreateLogFolder with FwCreateFolder; replaced 4x' ' with Tab
::  2023.08.04.0 [ki] _SHA: implement CollectSHA_support log options from shacollector tool.
::  2023.05.17.0 [we] _SHA: upd SHA_iSCSI providers
::  2023.04.07.0 [we] _SHA: removed un-used SHA_PnP
::  2023.03.14.0 [we] _SHA: add correlation=disabled to NET_HypHost NetSh (kb5025648)
::  2023.01.18.0 [we] _SHA: $SHA_DummyProviders = @()
::  2023.01.03.0 [we] _SHA: removed duplicate SHA_StorPort: sorting Providers alphabetically
::  2022.12.12.0 [we] _SHA: upd SHA_VSS
::  2022.12.07.0 [we] _SHA: add -Scenario SHA_General
::  2022.11.27.1 [rvi] Adding GetLogs to SHA_MSCluster 
::  2022.10.30.1 [rvi] modify $FrutiExe to Stop on end of trace
::  2022.10.24.2 [we] modify $VmlTrace_exe and $FrutiExe invocation
::  2022.10.14.0 [we] add SHA_StorageSense
::  2022.08.22.0 [rvi] SpaceDB Chkspace collection
::  2022.07.21.0 [we] SHA_fix MsCluster definition
::  2022.06.10.0 [we] add SHA_VML (use -Mode verbose to restart the Hyper-V service and get FRUTI log); upd SHA_MSCluster
::  2022.04.15.0 [ki] add ETW from shacollector
::  2022.01.24.0 [we] add SHA_ReFS
::  2022.01.24.0 [we] update SHA_Storage with all aka SAN Shotgun from Insightweb
::  2022.01.03.0 [we] mod SHA_HypHost/HypVM/ShieldedVM
::  2021.12.31.1 [we] #_# _SHA: moved NET_ ShieldedVM,HypHost,HypVM to SHA_
::  2021.12.16.0 [rvi] _SHA: fix SHA_SDDC when command was never installed
::  2021.12.09.0 [we] _SHA: fix SHA_SDDC
::  2021.12.05.0 [we] #_# _SHA: add SHA_SMS per GetSmsLogs.psm1
::  2021.11.29.0 [we] #_# moving NET_CSVspace, NET_MPIO, NET_msDSM to SHA
::  2021.11.10.0 [we] #_# replaced all 'Get-WmiObject' with 'Get-CimInstance' to be compatible with PowerShell v7
::  2021.10.26.0 [we] #_# add MSCluster; add CollectSHA_SDDCLog by calling external psSDP scripts
	ex.1: .\TSS.ps1 -Start -Scenario SHA_MSCluster
	ex.2: .\TSS.ps1 -CollectLog SHA_SDDC
#>

#region --- Define local SHA Variables
$global:TssVerDateSHA= "2024.03.06.0"
#$OSVER3 		= $global:OSVersion.build
if ($global:OSVersion.Build -ge 18362) {$FrutiExe = $global:ScriptFolder + "\BIN\fruti_1903.exe"} else {$FrutiExe = $global:ScriptFolder + "\BIN\fruti_RS1.exe"}
if ($global:OSVersion.Build -eq 9200) {$VmlTrace_exe = $global:ScriptFolder + "\BIN\VmlTrace_2012.exe"}else{$VmlTrace_exe = $global:ScriptFolder + "\BIN\VmlTrace.exe"}
#endregion --- Define local SHA Variables

#region --- ETW component trace Providers ---

<# Normal trace -> data will be collected in a sign
 $SHA_TEST1Providers = @(
 	'{CC85922F-DB41-11D2-9244-006008269001}' # LSA
 	'{6B510852-3583-4E2D-AFFE-A67F9F223438}' # Kerberos
 )

# Normal trace with multi etl files
$SHA_TEST3Providers = @(
	'{98BF1CD3-583E-4926-95EE-A61BF3F46470}!CertCli'
	'{6A71D062-9AFE-4F35-AD08-52134F85DFB9}!CertificationAuthority'
)
#>

$SHA_DummyProviders = @(	#for components without a tracing GUID
	#'{eb004a05-9b1a-11d4-9123-0050047759bc}' # Dummy tcp for switches without tracing GUID (issue #70)
)
$SHA_VMLProviders 	= @()

$SHA_MSDTCProviders 	= @()

$SHA_ATAPortProviders = @(
	'{cb587ad1-cc35-4ef1-ad93-36cc82a2d319}' # Microsoft-Windows-ATAPort
	'{d08bd885-501e-489a-bac6-b7d24bfe6bbf}' # ataport guid
)

$SHA_CDROMProviders = @(
	'{9b6123dc-9af6-4430-80d7-7d36f054fb9f}' # Microsoft-Windows-CDROM
	'{A4196372-C3C4-42D5-87BF-7EDB2E9BCC27}' # cdrom.sys
	'{944a000f-5f60-4e5a-86fd-d55b84b543e9}' # WPP_GUID_UDFD
	'{6B1DB052-734F-4E23-AF5E-6CD8AE459F98}' # WPP_GUID_UDFS
	'{F8036571-42D9-480A-BABB-DE7833CB059C}' # IMAPI2FS Tracing
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E9D}' # IMAPI2 Concatenate Stream
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E91}' # IMAPI2 Disc Master
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E93}' # IMAPI2 Disc Recorder
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E92}' # IMAPI2 Disc Recorder Enumerator
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E90}' # IMAPI2 dll
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E9E}' # IMAPI2 Interleave Stream
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E97}' # IMAPI2 Media Eraser
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E9F}' # IMAPI2 MSF
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7EA0}' # IMAPI2 Multisession Sequential
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E9C}' # IMAPI2 Pseudo-Random Stream
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E9A}' # IMAPI2 Raw CD Writer
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E98}' # IMAPI2 Standard Data Writer
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E99}' # IMAPI2 Track-at-Once CD Writer
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E94}' # IMAPI2 Utilities
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E96}' # IMAPI2 Write Engine
	'{0E85A5A5-4D5C-44B7-8BDA-5B7AB54F7E9B}' # IMAPI2 Zero Stream
)

$SHA_COMProviders = @(
	'{B46FA1AD-B22D-4362-B072-9F5BA07B046D}' # COMSVCS
	'{BDA92AE8-9F11-4D49-BA1D-A4C2ABCA692E}' # OLE32
	'{9474A749-A98D-4F52-9F45-5B20247E4F01}' # DCOMSCM
	'{9474A749-A98D-4F52-9F45-5B20247E4F01}' # DCOMSCM
	'{A0C4702B-51F7-4EA9-9C74-E39952C694B8}' # COMADMIN
)

$SHA_CSVFSProviders = @(
	'{0cfda7f5-7549-575e-d095-dcc1e4fbaa3f}' # Microsoft.Windows.Server.CsvFsCritical
	'{4e6177a5-c0a7-4d9b-a686-56ed5435a908}' # nflttrc
	'{B421540C-1FC8-4c24-90CC-C5166E1DE302}' # CSVFLT
	'{d82dba12-8b70-49ee-b844-44d0885951d2}' # CSVFLT
	'{4e6177a5-c0a7-4d9b-a686-56ed5435a904}' # VBus
	'{af14af06-a558-4ff0-a061-9080e33212d6}' # CsvCache
	'{151D3C03-E442-4C4F-AF20-BD48FF41F793}' # Microsoft-Windows-FailoverClustering-CsvFlt-Diagnostic
	'{6a86ae90-4e9b-4186-b1d1-9ce0e02bcbc1}' # Microsoft-Windows-FailoverClustering-CsvFs-Diagnostic
)

$SHA_CSVspaceProviders = @(
	'{595F7F52-C90A-4026-A125-8EB5E083F15E}' # "Microsoft-Windows-StorageSpaces-Driver"
	'{929C083B-4C64-410A-BFD4-8CA1B6FCE362}' # Spaceport
	'{E7D0AD21-B086-406D-BE46-A701A86A5F0A}' # SpTelemetry
)

$SHA_DedupProviders = @(
	'{F9FE3908-44B8-48D9-9A32-5A763FF5ED79}' # Microsoft-Windows-Deduplication
	'{1D5E499D-739C-45A6-A3E1-8CBE0A352BEB}' # Microsoft-Windows-Deduplication-Change
	'{5ebb59d1-4739-4e45-872d-b8703956d84b}' # SrmTracingProviderGuid
	'{c503ed7b-d3d1-421b-97cd-22f4e7445f2a}' # Microsoft.Windows.Deduplication.Service
	'{c503ed7b-d3d1-421b-97cd-22f4e7455f2a}' # Microsoft.Windows.Deduplication.Pipeline/Store/DataPort/Scanner
	'{611b641a-8c01-449b-ab5b-a9f18adc4e3c}' # DdpFltLogGuid
	'{767c881e-f7f5-418e-a428-a113c3a8630a}' # DdpFltTraceGuid
)

$SHA_FltmgrProviders = @(
	'{4F5D14A2-97BB-454B-B848-6F3CE0DF80F1}' # FltMgr
	'{FD66A680-C052-4375-8CC9-225F923CEF88}' # FltMgrTelemetryProvider
	'{F3C5E28E-63F6-49C7-A204-E48A1BC4B09D}' # Microsoft-Windows-FilterManager
)

$SHA_FSRMProviders = @(
	'{39af31ab-064d-494b-a0f7-cc90215bdac0}' # Microsoft.Windows.FSRM
	'{3201c659-d580-4833-b17d-1adaf643c64c}' # SrmTracingProviderGuid
	'{6e82d70f-403d-4194-b724-85109b2f2028}' # SrmTracingEventGuid
	'{1214600f-df79-4a03-94f5-65d7cab4fd16}' # Quota
	'{DB4A5343-AC92-4B83-9D84-7ED8FADD7AA5}' # Datascrn
	'{1C7BC728-8199-48BE-BD4D-406A63303C8D}' # Cbafilt
	'{F3C5E28E-63F6-49C7-A204-E48A1BC4B09D}' # Microsoft-Windows-FilterManager
)

$SHA_HyperVProviders = @(
	'{AE7E4D1D-16C7-4807-A2E4-980EDF16D031}' # Microsoft.Windows.HyperV.SysprepProvider
	'{949B9EDC-ADDA-4712-A3E7-D2DCA33E84E8}' # Microsoft.Windows.HyperV.UpgradeComplianceCheck
	'{4DDF50D0-75DE-4FBE-8F08-F8936638E7A1}' # Microsoft.Windows.HyperV.Management
	'{85A7888C-4EF7-5C56-643F-FBD6DC10FEBE}' # Microsoft.Windows.HyperV.KvpExchange
	'{d90b9468-67f0-5b3b-42cc-82ac81ffd960}' # Microsoft.Windows.Subsystem.Lxss
	'{b99cdb5a-039c-5046-e672-1a0de0a40211}' # Microsoft.Windows.Lxss.Manager
	'{06C601B3-6957-4F8C-A15F-74875B24429D}' # Microsoft.Windows.HyperV.Worker
	'{7568b40b-dc66-5a30-55a1-d0ef61b56ac8}' # Microsoft.Windows.HyperV.Worker.Intercepts
	'{5e01db5e-1944-5314-c040-c90b965ea3d3}' # Microsoft.Windows.HyperV.Worker.MemoryManager
	'{1111450B-DACC-40A3-84AB-F7DBA4A6E63A}' # Microsoft.Windows.HyperV.VID
	'{5931D877-4860-4ee7-A95C-610A5F0D1407}' # Microsoft-Windows-Hyper-V-VID
	'{f83552c4-a4e8-50f7-b2d4-a9705c474490}' # Microsoft.Windows.HyperV.TimeSync
	'{a20b1fd7-ac6e-4e79-81c9-23b3c5e97444}' # Microsoft.Windows.HyperV.PCIProxy
	'{b2ed3bdb-cd74-5b2c-f660-85079ca074b3}' # Microsoft.Windows.HyperV.Socket
	'{544d0787-9f6d-432e-8414-e035a8b0541d}' # Microsoft.Windows.HyperV.Storvsp
	'{8dfb8c22-55c0-494d-8c75-a4cc35b0c535}' # Microsoft.Windows.HyperV.Vsmb
	'{2174371b-d5f6-422b-bfc4-bb6f97ddaa84}' # Microsoft.Windows.HyperV.Storage
	'{D0E4BC17-34C7-43fc-9A72-D89A59D6979A}' # Microsoft.Windows.HostNetworkingService.PrivateCloudPlugin
	'{6C28C7E5-331B-4437-9C69-5352A2F7F296}' # Microsoft-Windows-Hyper-V-VmsIf
	'{67DC0D66-3695-47C0-9642-33F76F7BD7AD}' # Microsoft.Windows.Hyper-V.VmSwitch
	'{152FBE4B-C7AD-4f68-BADA-A4FCC1464F6C}' # Microsoft.Windows.Hyper-V.NetVsc
	'{93f693dc-9163-4dee-af64-d855218af242}' # Microsoft-Windows-Hyper-V-NetMgmt
	'{0b4745b0-c990-4780-965a-391afd9424b8}' # Microsoft.Windows.HyperV.NetworkMigrationPlugin
	'{F20F4146-DB1D-4FE8-8C86-49BF5CF7390D}' # L2BridgeTraceLoggingProvider
	'{0c885e0d-6eb6-476c-a048-2457eed3a5c1}' # Microsoft-Windows-Host-Network-Service
	'{f5bf2dc5-fd9c-546d-f37b-9cbe631a065b}' # Microsoft.Windows.HyperV.DynamicMemory
	'{4f542162-e9cf-5eca-7f74-1fb63a59a6c2}' # Microsoft.Windows.HyperV.GuestCrashDump
	'{a572eeb4-c3f7-5b0e-b669-bb200931d134}' # Microsoft.Windows.HyperV.Worker.VmbusPipeIO
	'{51ddfa29-d5c8-4803-be4b-2ecb715570fe}' # Microsoft-Windows-Virtualization-Worker
	'{e5ea3ca6-5eb0-597d-504a-2fd09ccdefda}' # ICVdevDeviceEtwTrace
	'{339aad0a-4124-4968-8147-4cbbb1f8b3d5}' # Microsoft-Windows-Virtualization-UiDevices
	'{13eae551-76ca-4ddc-b974-d3a0f8d44a03}' # Microsoft-Windows-Virtualization-Tpm
	'{7b0ea079-e3bc-424a-b2f0-e3d8478d204b}' # Microsoft-Windows-VStack-VSmb
	'{4D20DF22-E177-4514-A369-F1759FEEDEB3}' # Microsoft-Windows-VIRTDISK
	'{EDACD782-2564-4497-ADE6-7199377850F2}' # Microsoft-Windows-VStack-SynthStor
	'{6c3e21aa-36c0-5476-818a-3d71fc67c9e8}' # Microsoft-Windows-Hyper-V-NvmeDirect
	'{8f9df503-1d12-49ec-bb28-f6ec42d361d4}' # Microsoft-Windows-Virtualization-serial
	'{c29c4fb7-b60e-4fff-9af9-cf21f9b09a34}' # Microsoft-Windows-VStack-SynthNic
	'{a86e166e-7d3c-402d-8fe0-2a3e62c93864}' # Microsoft-Windows-Virtualization-Worker-GPUP
	'{B1D080A6-F3A5-42F6-B6F1-B9FD86C088DA}' # Microsoft-Windows-Hyper-V-DynMem
	'{c7c9e4f7-c41d-5c68-f104-d72a920016c7}' # Microsoft-Windows-Hyper-V-CrashDump
	'{de9ba731-7f33-4f44-98c9-6cac856b9f83}' # Microsoft-Windows-Virtualization-Chipset
	'{02f3a5e3-e742-4720-85a5-f64c4184e511}' # Microsoft-Windows-Virtualization-Config
	'{17103E3F-3C6E-4677-BB17-3B267EB5BE57}' # Microsoft-Windows-Hyper-V-Compute
	'{45F54D37-2377-4B64-B396-370E31ACB204}' # Microsoft-Windows-Hyper-V-ComputeCExec
	'{AF7FD3A7-B248-460C-A9F5-FEC39EF8468C}' # Microsoft-Windows-Hyper-V-ComputeLib
	'{6066F867-7CA1-4418-85FD-36E3F9C0600C}' # Microsoft-Windows-Hyper-V-VMMS
	'{0461BE3C-BC15-4BAD-9A9E-51F3FADFEC75}' # Microsoft-Windows-FailoverClustering-WMIProvider
	'{FF3E7036-643F-430F-B015-2933466FF0FD}' # Microsoft-Windows-FailoverClustering-WMI
	'{177D1599-9764-4E3A-BF9A-C86887AADDCE}' # Microsoft-Windows-Hyper-V-VmbusVdev
	'{09242393-1349-4F4D-9FD7-59CC79F553CE}' # Microsoft-Windows-Hyper-V-EmulatedNic
	'{2ED5C5DF-6026-4E25-9FB1-9A08701125F3}' # Microsoft.Windows.HyperV.VMBus
	'{2B74A015-3873-4C56-9928-EA80C58B2787}' # Heartbeat VDEV (vmicheartbeat)
	'{1CEB22B1-97FF-4703-BEB2-333EB89B522A}' # Microsoft-Windows-Hyper-V-VMSP (VM security process implementation)
	'{AE3F5BF8-AB9F-56D6-29C8-8C312E2FAEC2}' # Microsoft-Windows-Hyper-V-Virtual-PMEM
	'{DA5A028B-B248-4A75-B60A-024FE6457484}' # Microsoft-Windows-Hyper-V-EmulatedDevices
	'{6537FFDF-5765-517E-C03C-55A8E5A97C10}' # Microsoft-Windows-Hyper-V-KernelInt
	'{52FC89F8-995E-434C-A91E-199986449890}' # Microsoft-Windows-Hyper-V-Hypervisor
	'{82DA50E7-D261-4BD1-BBB9-3213E0EFE360}' # Microsoft.Windows.HyperV.MigrationPlugin
	'{C3A331B2-AF4F-5472-FD2F-4313035C4E77}' # Microsoft.Windows.HyperV.GpupVDev
	'{06C601B3-6957-4F8C-A15F-74875B24429D}' # VmwpTelemetryProvider (VmWpStateChange)
	'{8B0287F8-755D-4BC8-BD76-4CE327C4B78B}' # Microsoft-Windows-Hyper-V-WorkerManager
	'{9193A773-E60D-4171-8468-05C000581B71}' # Image Management Service (vhdsvc)
	'{0A18FF18-5362-4739-9671-78023D747B70}' # Virtual Network Management Service (nvspwmi)
	'{86E15E01-EDF1-4AC7-89CF-B19563FD6894}' # Emulated Storage VDEV (emulatedstor)
	'{82D60869-5ADA-4D49-B76A-309B09666584}' # KVP Exchange VDEV (vmickvpexchange)
	'{BC714241-8EDC-4CE3-8714-AA0B51F98FDF}' # Shutdown VDEV (vmicshutdown)
	'{F152DC14-A3A0-4258-BECE-69A3EE4C2DE8}' # Time Synchronization VDEV (vmictimesync)
	'{67E605EE-A4D8-4C46-AE50-893F31E13963}' # VSS VDEV (vmicvss)
	'{64E92ABC-910C-4770-BD9C-C3C54699B8F9}' # Clustering Resource DLL (vmclusres)
	'{5B621A17-3B58-4D03-94F0-314F4E9C79AE}' # Synthetic Fibre Channel VDEV (synthfcvdev)
	'{6357c13a-2eb3-4b91-b580-79682eb76986}' # Virtual FibreChannel Management Service (fcvspwmi)
	'{2ab5188c-5915-4629-9f8f-b3b20c78d1b0}' # VM Memory-Preserving Host Update DLL (vmphu)
	'{573a8439-2c0f-450b-bf98-51a86843d700}' # Dynamic Memory (guest)
	'{F96ABC17-6A5E-4A49-A3F4-A2A86FA03846}' # storvsc (guest)
	'{CB5B2C18-AD73-4EBF-8AF1-73B30B885030}' # VMBus (guest)
)

$SHA_HypVmBusProviders = @(
	'{F2E2CE31-0E8A-4E46-A03B-2E0FE97E93C2}' # Microsoft-Windows-Hyper-V-Guest-Drivers-Vmbus
	'{CB5B2C18-AD73-4EBF-8AF1-73B30B885030}' # VMBusDriverTraceGuid
	'{FA3F78FF-BA6D-4EDE-96B2-9C5BB803E3BA}' # Microsoft-Windows-Hyper-V-KMCL
)

$SHA_HypVmmsProviders = @(
	'{6066F867-7CA1-4418-85FD-36E3F9C0600C}' # Microsoft-Windows-Hyper-V-VMMS
)

$SHA_HypVmWpProviders = @(
	'{51ddfa29-d5c8-4803-be4b-2ecb715570fe}' # Microsoft-Windows-Hyper-V-Worker
	'{06C601B3-6957-4F8C-A15F-74875B24429D}' # VmwpTelemetryProvider
	'{5E01DB5E-1944-5314-C040-C90B965EA3D3}' # WorkerMemManagerProvider
)
	
$SHA_iSCSIProviders = @(
	'{1babefb4-59cb-49e5-9698-fd38ac830a91}' # iScsi
	'{13953C6E-C594-414E-8BA7-DEB4BA1878E3}' # Microsoft-Windows-iSCSITarget-Service
	'{07ABD211-DA70-4F8F-B3EF-BF825FD7B189}' # Microsoft-Windows-iSCSITarget-VSSProvider
	'{82FB2F8C-A21C-453B-ACBD-7EF49493D727}' # WinTargetWPP
	'{7D758B3E-E29E-43DA-8683-9860A1C19362}' # Microsoft-Windows-iSCSITarget-VDSProvider
	'{BBF8051F-1F47-44CA-AC73-92658CD4E4F8}' # WTLmDrvCtrlGuid
	'{B5E70289-982D-4109-BC5E-BF554BAD08F5}' # WTSmisProviderWPP
	'{81C84CFA-C80B-47A1-BECE-5CA0F1851FEB}' # WTVssProviderWPP
)

$SHA_MPIOProviders = @(
	'{8E9AC05F-13FD-4507-85CD-B47ADC105FF6}' # Storage - MPIO
	'{8B86727C-E587-4B89-8FC5-D1F24D43F69C}' # StorPort
	'{FA8DE7C4-ACDE-4443-9994-C4E2359A9EDB}' # Storage - ClassPnP
)

$SHA_MsClusterProviders = @(	# was $UEX_FailoverClusteringProviders
	'{9F7FE238-9505-4B84-8B33-268C9204268E}' # Microsoft.Windows.Clustering.ClusterResource
	'{50d577a6-b3e7-4642-9e4d-05200376a5cf}' # Microsoft.Windows.Server.FailoverClustering.Failure
	'{f40422bd-f483-449a-99c7-c4546950112c}' # Microsoft.Windows.Server.FailoverClusteringDevelop
	'{3122168f-2432-45f0-b91c-3af363c14999}' # ClusApiTraceLogProvider
	'{8bdb2a89-5d40-4a5f-afd8-8b1e0ce3abc9}' # Microsoft-Windows-WSDR
	'{baf908ea-3421-4ca9-9b84-6689b8c6f85f}' # Microsoft-Windows-FailoverClustering
	'{a82fda5d-745f-409c-b0fe-18ae0678a0e0}' # Microsoft-Windows-FailoverClustering-Client
	'{0DAD9561-2E3B-49BB-93D7-B49603BA6173}' # DVFLT
	'{b529c110-72ba-4e7f-8ba7-366e3f5faeb0}' # Microsoft.Windows.Clustering.WmiProvider
	'{282968B4-215F-4568-B4A5-C2E5467C301E}' # Microsoft.Windows.Clustering.ClusterService
	'{60431de6-ecae-4926-8e10-0918d219a0a1}' # Microsoft.Windows.Server.FailoverClustering.Set.Critical
	'{49F59745-7F56-4082-A01A-83BC089D1ADD}' # Microsoft.Windows.Health
	'{372968B4-215F-4568-B4A5-C2E5467C301E}' # Microsoft.Windows.Clustering.EbodTargetMgr
	'{1de9cea2-60ce-49fa-a8b7-84139ac12b31}' # Microsoft.Windows.Clustering.S2DCache
	'{0461be3c-bc15-4bad-9a9e-51f3fadfec75}' # Microsoft-Windows-FailoverClustering-WMIProvider	# included in SHA_HyperV
	'{ff3e7036-643f-430f-b015-2933466ff0fd}' # Microsoft-Windows-FailoverClustering-WMI			# included in SHA_HyperV
	'{11B3C6B7-E06F-4191-BBB9-7099FFF55614}' # Microsoft-Windows-FailoverClustering-Manager
	'{f0a43898-4017-4d3b-acac-ff7fb8ac63cd}' # Microsoft-Windows-Health
	'{C1FCCEB3-3F19-42A9-95B9-27B550FA1FBA}' # Microsoft-Windows-FailoverClustering-NetFt
	'{10629806-46F2-4366-9092-53025E067E8C}' # Microsoft-Windows-ClusterAwareUpdating
	'{9B9E93D6-5569-4179-8C8A-5201CB2B9536}' # Microsoft-Windows-ClusterAwareUpdating-Management
	'{7FEF367F-E76C-4592-9912-E12B36A99780}' # Microsoft-Windows-FailoverClustering-ClusDisk-Diagnostic
	'{5d9e8ca1-8634-457b-8d0b-3ba944bc2ff0}' # Microsoft-Windows-FailoverClustering-TargetMgr-Diagnostic
	'{6F0771DD-4096-4E5E-A549-FC1238F5A1B2}' # Microsoft-Windows-FailoverClustering-ClusTflt-Diagnostic
	'{29c07d0e-e5a0-4e85-a004-1f668531ce22}' # Microsoft-Windows-FailoverClustering-Clusport-Diagnostic
	'{4339CD79-93D6-4F55-A96A-F7762E8AF2DE}' # Microsoft-Windows-FailoverClustering-ClusPflt-Diagnostic
	'{40CB8729-8896-4CAB-90E0-2A3AEBA730C2}' # Microsoft-Windows-FailoverClustering-ClusHflt-Diagnostic
	'{E68AB9C0-49F4-4786-A6E0-F323E0BE590C}' # Microsoft-Windows-FailoverClustering-ClusDflt-Diagnostic
	'{53A840C4-8E2B-4D39-A3F6-708834AA4620}' # Microsoft-Windows-FailoverClustering-ClusCflt-Diagnostic
	'{923BCB94-58D2-42BE-BBA9-B1315F363838}' # Microsoft-Windows-FailoverClustering-ClusBflt-Diagnostic
	'{0ac0708a-a44e-49ef-aa7e-fbe8ccc603a6}' # Microsoft-Windows-FailoverClustering-SoftwareStorageBusTarget
	'{7F8DA3B5-A58F-481E-9637-D41435AE6D8B}' # Microsoft-Windows-SDDC-Management
	'{6e580567-c67c-4b96-934e-fc2996e103ae}' # ClusDiskLogger									# included in SHA_Storage
	'{BBB672F4-E56A-4529-90C0-1421E27DE4BE}' # svhdxpr
	'{b6c164c7-4152-4b94-af14-0dac3d0556a3}' # StorageQoSTraceGuid
	'{7e66368d-b895-45f2-811f-fb37940421a6}' # NETFT
	'{8a391cc0-6303-4a25-833f-e7db345941d6}' # VBus
	'{f8f6ae53-b3b3-451f-b204-6b62550efb5c}' # cbflt
	'{EB94F195-9596-49EC-825D-6329F48BD6E9}' # cdflt
	'{7ba7dbd4-e7a9-47db-ac47-4ac1182a82f5}' # cbflt
	'{88AE0E2D-0377-48A1-85C5-FBCC32ACB6BA}' # SddcResGuid
	'{4FA1102E,CC1D,4509,A69F,121E2CC96F9C}' # SddcWmiGuid
	'{FEBD78F8-DDC5-484D-848C-982F1F483278}' # Microsoft-Windows-FailoverClustering-Replication
)
<#
#separated: 
$SHA_MsClusterProviders += @(
	$SHA_iSCSIProviders
	$SHA_MPIOProviders 	# included in SHA_StorageProvider
	$SHA_msDSMProviders 
	$SHA_StorageReplicaProviders 
	$SHA_StorageSpaceProviders 
	$SHA_StorportProviders 
	$SHA_StorageProviders # includes SHA_iSCSI, SHA_MPIO
)
#>

$SHA_MSDSMProviders = @(
	'{DEDADFF5-F99F-4600-B8C9-2D4D9B806B5B}' # Storage - MSDSM
	'{C9C5D896-6FA9-49CD-9BFD-BF5C232C1124}' # MsdsmTraceLoggingProvider
	'{CBC7357A-D802-4950-BB14-817EAD7E0176}' # Reliability DataVerFilter
)

$SHA_NFSProviders = @(	# NET_NFScli + NET_NFSsrv
	'{3c33d8b3-66fa-4427-a31b-f7dfa429d78f}' # NfsSvrNfsGuid
	'{fc33d8b3-66fa-4427-a31b-f7dfa429d78f}' # NfsSvrNfsGuid2
	'{57294EFD-C387-4e08-9144-2028E8A5CB1A}' # NfsSvrNlmGuid
	'{CC9A5284-CC3E-4567-B3F6-3EB24E7CFEC5}' # MsNfsFltGuid
	'{f3bb9731-1d9f-4b8e-a42e-203bf1a32300}' # Nfs4SvrGuid
	'{53c16bac-175c-440b-a266-1e5d5f38313b}' # OncRpcXdrGuid
	'{94B45058-6F59-4696-B6BC-B23B7768343D}' # rpcxdr
	'{e18a05dc-cce3-4093-b5ad-211e4c798a0d}' # PortMapGuid
	'{355c2284-61cb-47bb-8407-4be72b5577b0}' # NfsRdrGuid
	'{6361f674-c2c0-4f6b-ae19-8c62f47ae3fb}' # NfsClientGuid
	'{c4c52165-ad74-4b70-b62f-a8d35a135e7a}' # NfsClientGuid
	'{746A1133-BC1E-47c7-8C95-3D52C39114F9}' # Microsoft-Windows-ServicesForNFS-Client
	'{6E1CBBE9-8C4B-4003-90E2-0C2D599A3EDC}' # Microsoft-Windows-ServicesForNFS-Portmapper
	'{F450221A-07E5-403A-A396-73923DFB2CAD}' # Microsoft-Windows-ServicesForNFS-NFSServerService
	'{3D888EE4-5A93-4633-91E7-FFF8AFD89A7B}' # Microsoft-Windows-ServicesForNFS-ONCRPC
	'{A0CC474A-06CA-427C-BDFF-84733163E262}' # Microsoft-Windows-ServicesForNFS-Cluster
)

$SHA_NTFSProviders = @(
	'{B2FC00C4-2941-4D11-983B-B16E8AA4E25D}' # NtfsLog
	'{DD70BC80-EF44-421B-8AC3-CD31DA613A4E}' # Ntfs
	'{E9B319E4-0030-40A7-91CB-04D6A8EF7E09}' # Microsoft-Windows-Ntfs-SQM
	'{8E6A5303-A4CE-498F-AFDB-E03A8A82B077}' # Microsoft-Windows-Ntfs-UBPM
	'{FFD1D811-6488-4D44-82AF-C31D372609A9}' # NtfsTelemetryProvider
	'{740F3C34-57DF-4BAD-8EEA-72AC69AD5DF5}' # Ntfs_ProtogonWmiLog
	'{3FF37A1C-A68D-4D6E-8C9B-F79E8B16C482}' # Microsoft-Windows-Ntfs
)

$SHA_RPCProviders = @(
	'{272A979B-34B5-48EC-94F5-7225A59C85A0}' # Microsoft-Windows-RPC-Proxy-LBS
	'{879B2576-39D1-4C0F-80A4-CC086E02548C}' # Microsoft-Windows-RPC-Proxy
	'{536CAA1F-798D-4CDB-A987-05F79A9F457E}' # Microsoft-Windows-RPC-LBS
	'{6AD52B32-D609-4BE9-AE07-CE8DAE937E39}' # Microsoft-Windows-RPC 
	'{F4AED7C7-A898-4627-B053-44A7CAA12FCD}' # Microsoft-Windows-RPC-Events
	'{D8975F88-7DDB-4ED0-91BF-3ADF48C48E0C}' # Microsoft-Windows-RPCSS
)

$SHA_ReFSProviders = @(
	'{CD9C6198-BF73-4106-803B-C17D26559018}' # Microsoft-Windows-ReFS
	'{740F3C34-57DF-4BAD-8EEA-72AC69AD5DF5}' # RefsWppTrace
	'{059F0F37-910E-4FF0-A7EE-AE8D49DD319B}' # Microsoft-Windows-ReFS-v1
	'{6D2FD9C5-8BD8-4A5D-8AA8-01E5C3B2AE23}' # Refsv1WppTrace
	'{F9A81F79-369B-443C-9428-FC1DD98316F6}' # Microsoft.Windows.FileSystem.ReFSUtil
	'{61D5C496-C69B-5B72-DE0A-29248A17CACE}' # RefsTelemetryProvider
	'{036647D2-2FB0-4E32-8349-3F5C19C16E5E}' # ReFS
	'{740F3C34-57DF-4BAD-8EEA-72AC69AD5DF5}' # Ntfs_ProtogonWmiLog
	'{AF20A152-62E5-4AA3-A264-48EB87549B75}' # Microsoft-Windows-Minstore-v1
)

$SHA_ShieldedVMProviders = @(
	'{7DEE1FDC-FFA8-4087-912A-95189D6A2D7F}' # Microsoft-Windows-HostGuardianService-Client
	'{0F39F1F2-65CC-4164-83B9-9BCADEDBAF18}' # Microsoft-Windows-ShieldedVM-ProvisioningService
	'{5D0B0AB2-1640-40E4-81F6-05403AF6C38B}' # Microsoft-Windows-ShieldedVM-ProvisioningSecureProcess
	'{5D487FAD-104B-5CA6-CA4E-14C206850501}' # Microsoft-Windows-HostGuardianClient-Service
)

$SHA_StorageProviders = @(
	'{F96ABC17-6A5E-4A49-A3F4-A2A86FA03846}' # StorVspDriverTraceGuid (SAN shotgun)
	'{8B86727C-E587-4B89-8FC5-D1F24D43F69C}' # StorPort (SAN shotgun)
	'{8E9AC05F-13FD-4507-85CD-B47ADC105FF6}' # Storage - MPIO (SAN shotgun)
	'{DEDADFF5-F99F-4600-B8C9-2D4D9B806B5B}' # Storage - MSDSM (SAN shotgun)
	'{1BABEFB4-59CB-49E5-9698-FD38AC830A91}' # iScsi (SAN shotgun)
	'{945186BF-3DD6-4F3F-9C8E-9EDD3FC9D558}' # Storage - Disk Class Driver Tracing Provider (SAN shotgun)
	'{FA8DE7C4-ACDE-4443-9994-C4E2359A9EDB}' # Storage - ClassPnP Driver Tracing Provider (SAN shotgun)
	#'{13953C6E-C594-414E-8BA7-DEB4BA1878E3}' # Microsoft-Windows-iSCSITarget-Service (SAN shotgun) # excluded on purpose?
	'{467C1914-37F0-4C7D-B6DB-5CD7DFE7BD5E}' # Mountmgr
	'{E3BAC9F8-27BE-4823-8D7F-1CC320C05FA7}' # Microsoft-Windows-MountMgr
	'{F5204334-1420-479B-8389-54A4A6BF6EF8}' # VolMgr
	'{9f7b5df4-b902-48bc-bc94-95068c6c7d26}' # Microsoft-Windows-Volume
	'{0BEE3BC5-A50C-4EC3-A0E0-5AD11F2455A3}' # Partmgr
	'{da58fbef-c209-4bee-84ed-027c421f31bf}' # Volsnap(wpp)
	'{67FE2216-727A-40CB-94B2-C02211EDB34A}' # Microsoft-Windows-VolumeSnapshot-Driver
	'{CB017CD2-1F37-4E65-82BC-3E91F6A37559}' # Volsnap(manifest based)
	'{6E580567-C67C-4B96-934E-FC2996E103AE}' # ClusDiskLogger
	'{C9C5D896-6FA9-49CD-9BFD-BF5C232C1124}' # Microsoft.Windows.Storage.Msdsm
	'{2CC00407-E9D9-4B5E-A760-F4217C9B0170}' # Microsoft.Windows.Storage.Mpio
	'{cc7b00d3-75c9-42cc-ae56-bf6d66a9d15d}' # Microsoft-Windows-MultipathIoControlDriver
	'{9282168F-2432-45F0-B91C-3AF363C149DD}' # StorageWMI
	'{1B992FD1-0CDD-4D6A-B55E-08C61E78D2C2}' # Microsoft.Windows.Storage.MiSpace
)

$SHA_StorageSenseProviders = @(
	'{3A245D5A-F00F-48F6-A94B-C51CDD290F18}' # 
	'{830A1F34-7797-4E31-9B75-C82056330051}' # 
	'{AEA3A1A8-EA43-4802-B750-2DD678910779}' # StorageServiceProvider
	'{B7AFA6AF-AAAB-4F50-B7DC-B61D4DDBE34F}' # Microsoft.Windows.Analog.Shell.SystemSettings.SettingsAppActivity
	'{057597DF-6FD8-438B-BF6D-190CBF0A914C}' # 
)

$SHA_StorageSpaceProviders = @(
	'{595f7f52-c90a-4026-a125-8eb5e083f15e}' # Microsoft-Windows-StorageSpaces-Driver
	'{aa4c798d-d91b-4b07-a013-787f5803d6fc}' # Microsoft-Windows-StorageSpaces-ManagementAgent
	'{69c8ca7e-1adf-472b-ba4c-a0485986b9f6}' # Microsoft-Windows-StorageSpaces-SpaceManager
	'{A9C7961E-96A0-4E3F-9066-7734A13101C1}' # Microsoft.Windows.Storage.SpaceControl
	'{0254f21f-4809-477e-ad36-c812a8c631a1}' # Microsoft.Windows.Storage.Spaceman
	'{e7d0ad21-b086-406d-be46-a701a86a5f0a}' # Microsoft.Windows.Storage.Spaceport
	'{929c083b-4c64-410a-bfd4-8ca1b6fce362}' # Spaceport
)

$SHA_StorageReplicaProviders = @(
	'{35a2925c-30a3-43eb-b737-03e9659955e2}' # Microsoft-Windows-StorageReplica-Cluster
	'{f661b376-6e59-4483-89f8-d5aca1816ead}' # Microsoft-Windows-StorageReplica
	'{ce171fd7-a5ba-4d95-926b-6dc4d89e8171}' # Microsoft-Windows-StorageReplica-Service
	'{fadca505-ad5e-47a8-9047-b3888ba4a8fc}' # WvrCimGuid
	'{634af965-fe67-49cf-8268-af99f62d1a3e}' # WvrFltGuid
	'{8e37fc9c-8656-46da-b40d-34d97a532d09}' # WvrFltGuid
	'{0e0d5a31-e93f-40d6-83bb-e7663a4f54e3}' # Microsoft.Windows.Server.StorageReplicaCritical
)

$SHA_StorportProviders = @(
	'{8B86727C-E587-4B89-8FC5-D1F24D43F69C}' # storport
	'{4EEB8774-6C4C-492F-8F2F-5EE4721B7BF7}' # Microsoft.Windows.Storage.Storport
	'{C4636A1E-7986-4646-BF10-7BC3B4A76E8E}' # Microsoft-Windows-StorPort
)

$SHA_StorsvcProviders = @(
	'{AEA3A1A8-EA43-4802-B750-2DD678910779}' # StorageServiceProvider
	'{A963A23C-0058-521D-71EC-A1CCE6173F21}' # Microsoft-Windows-Storsvc	
)

$SHA_USBProviders = @(
	'{C88A4EF5-D048-4013-9408-E04B7DB2814A}' # Microsoft-Windows-USB-USBPORT
	'{7426a56b-e2d5-4b30-bdef-b31815c1a74a}' # Microsoft-Windows-USB-USBHUB
	'{D75AEDBE-CFCD-42B9-94AB-F47B224245DD}' # usbport
	'{B10D03B8-E1F6-47F5-AFC2-0FA0779B8188}' # usbhub
	'{30e1d284-5d88-459c-83fd-6345b39b19ec}' # Microsoft-Windows-USB-USBXHCI
	'{36da592d-e43a-4e28-af6f-4bc57c5a11e8}' # Microsoft-Windows-USB-UCX
	'{AC52AD17-CC01-4F85-8DF5-4DCE4333C99B}' # Microsoft-Windows-USB-USBHUB3
	'{6E6CC2C5-8110-490E-9905-9F2ED700E455}' # USBHUB3
	'{6fb6e467-9ed4-4b73-8c22-70b97e22c7d9}' # UCX
	'{9F7711DD-29AD-C1EE-1B1B-B52A0118A54C}' # USBXHCI
	'{04b3644b-27ca-4cac-9243-29bed5c91cf9}' # UsbNotificationTask
	'{468D9E9D-07F5-4537-B650-98389559206E}' # UFX01000
	'{8650230d-68b0-476e-93ed-634490dce145}' # SynopsysWPPGuid
	'{B83729F3-8D84-4BEA-897B-CD9FD667BA01}' # UsbFnChipidea
	'{0CBB6922-F6B6-4ACA-8BF0-81624B491364}' # UsbdTraceGuid
	'{bc6c9364-fc67-42c5-acf7-abed3b12ecc6}' # USBCCGP
	'{3BBABCCA-A210-4570-B501-0E34D88A88FB}' # SDFUSBXHCI
	'{f3006b12-1d83-48d2-948d-6bcd002c14dc}' # UDEHID
	# There are too many GUIDs for USB. So need review on which GUIDs is helpful.
)

$SHA_VDSProviders = @(
	'{012F855E-CC34-4DA0-895F-07AF2826C03E}' # VDS
	'{EAD10F56-E9D4-4B29-A44F-C97299DE5085}' # Microsoft.Windows.Storage.VDS.Service
	'{F5204334-1420-479B-8389-54A4A6BF6EF8}' # volmgr
	'{945186BF-3DD6-4F3F-9C8E-9EDD3FC9D558}' # WPP_GUID_DISK
	'{467C1914-37F0-4C7D-B6DB-5CD7DFE7BD5E}' # Mount Manager Trace
	'{A8169755-BD1C-49a4-B346-4602BCB940AA}' # DISKMGMT
	'{EAD10F56-E9D4-4B29-A44F-C97299DE5086}' # Microsoft.Windows.Storage.DiskManagement
	'{EAD10F56-E9D4-4B29-A44F-C97299DE5088}' # Microsoft.Windows.Storage.DiskRaid
	'{EAD10F56-E9D4-4B29-A44F-C97299DE5090}' # Microsoft.Windows.Storage.VDS.BasicDisk
)

$SHA_VHDMPProviders = @(
	'{A9AB8791-8619-4FFF-9F24-E1BB60075972}' # Microsoft-Windows-Hyper-V-VHDMP(WinBlue)
	'{3C70C3B0-2FAE-41D3-B68D-8F7FCAF79ADB}' # Microsoft-Windows-Hyper-V-VHDMP
	'{e14dcdd9-d1ec-4dc3-8395-a606df8ef115}' # virtdisk
	'{9193A773-E60D-4171-8468-05C000581B71}' # Image Management Service (vhdsvc)
	'{f96abc17-6a5e-4a49-a3f4-a2a86fa03846}' # storvsp
	'{52323364-b587-4b4c-9293-ca9904a5c04f}' # storqosflt
)

$SHA_VmConfigProviders = @(
	'{02f3a5e3-e742-4720-85a5-f64c4184e511}' # Microsoft-Windows-Hyper-V-Config
)

$SHA_VMMProviders = @(
	'{43526B7E-9EE3-41A7-B023-D586F355C00B}' # Microsoft-VirtualMachineManager-Debug
)

$SHA_VSSProviders = @(
	'{9138500E-3648-4EDB-AA4C-859E9F7B7C38}' # VSS tracing provider
	'{77D8F687-8130-4A14-B8A6-3B922E05B99C}' # VSS tracing event
	'{f3625a85-421c-4a1e-a54f-6b65c0276c1c}' # VirtualBus
	'{6407345b-94f2-44c8-b3db-4e076be46816}' # WPP_GUID_ASR
	'{89300202-3cec-4981-9171-19f59559e0f2}' # Microsoft-Windows-FileShareShadowCopyProvider
	'{a0d45273-3386-4f3a-b344-0d8fee74e06a}' # Microsoft-Windows-FileShareShadowCopyAgent
	'{67FE2216-727A-40CB-94B2-C02211EDB34A}' # Microsoft-Windows-VolumeSnapshot-Driver
	'{CB017CD2-1F37-4E65-82BC-3E91F6A37559}' # Volsnap(manifest based)
	'{060172E8-4F15-45D3-9774-0BD258DF6AB4}' # FileShareSnapshotLog
	'{07ABD211-DA70-4F8F-B3EF-BF825FD7B189}' # Microsoft-Windows-iSCSITarget-VSSProvider
	'{9122168F-2432-45F0-B91C-3AF363C149DD}' # VSSTraceLogProvider
	'{C8723CFF-B58C-4D16-89CF-FE45B0505CD7}' # DPS: VssArchivalAgent
	'{B4660A01-86A0-56A2-525D-595CDCC0DC4D}' # Microsoft.Windows.Wintarget.VSSProvider
	'{67E605EE-A4D8-4C46-AE50-893F31E13963}' # Microsoft-Windows-Hyper-V-Integration-VSS
)

$SHA_WSBProviders = @(
	'{6B1DB052-734F-4E23-AF5E-6CD8AE459F98}' # WPP_GUID_UDFS
	'{944a000f-5f60-4e5a-86fd-d55b84b543e9}' # WPP_GUID_UDFD
	'{6407345b-94f2-44c8-b3db-4e076be46816}' # WPP_GUID_ASR
	'{7e9fb43e-a801-430c-9f36-c1146a51ed07}' # WPP_GUID_DSM
	'{4B966436-6781-4906-8035-9AF94B32C3F7}' # WPP_GUID_SPP
	'{1DB28F2E-8F80-4027-8C5A-A11F7F10F62D}' # Microsoft-Windows-Backup
	'{5602c36e-b813-49d1-a1aa-a0c2d43b4f38}' # BLB
	'{864d2d93-276f-4a88-8bce-d8d174e39c4d}' # Microsoft.Windows.SystemImageBackup.Engine
	'{9138500E-3648-4EDB-AA4C-859E9F7B7C38}' # VSS tracing provider
	'{67FE2216-727A-40CB-94B2-C02211EDB34A}' # Microsoft-Windows-VolumeSnapshot-Driver
	'{CB017CD2-1F37-4E65-82BC-3E91F6A37559}' # Volsnap(manifest based)
)

#endregion --- ETW component trace Providers


#region --- Scenario definitions ---  
$SHA_ScenarioTraceList = [Ordered]@{
	"SHA_HypHost"   = "PSR, SDP:HyperV, LBFO,NDIS,VmSwitch,SMBcli,SMBsrv,VMM,HyperV-Host,VMbus,Vmms,VmWp,VmConfig, ETL log(s), VMM-debug, PerfMon:SMB, trace scenario=NetConnection"
	"SHA_HypVM"	 = "PSR, SDP:Net, NET_NDIS,HypVM,HyperV-VirtualMachine ETL log(s), trace scenario=InternetClient_dbg"
	"SHA_MScluster" = "PSR, SDP:Cluster, MsCluster,CSVFS,StorPort,AfdTcp,LBFo,iSCSI,-MPIO,-msDSM,-StorageReplica,-StorageSpace,-Storport,-Storage ETL log(s), Perfmon:ALL, trace scenario=NetConnection"
}

$SHA_General_ETWTracingSwitchesStatus = [Ordered]@{
	#'NET_Dummy' = $true
	'CommonTask NET' = $True  ## <------ the commontask can take one of "Dev", "NET", "ADS", "UEX", "DnD" and "SHA", or "Full" or "Mini"
	'NetshScenario InternetClient_dbg' = $true
	'Procmon' = $true
	#'WPR General' = $true
	'PerfMon ALL' = $true
	'PSR' = $true
	'Video' = $true
	'SDP Cluster' = $True
	'xray' = $True
	'CollectComponentLog' = $True
}

$SHA_HypHost_ETWTracingSwitchesStatus = [Ordered]@{
	'SHA_HypVmBus' = $true
	'SHA_HypVmms' = $true
	'SHA_HypVmWp' = $true
	'SHA_VMM' = $true
	'SHA_VmConfig' = $true
	'NET_LBFo' = $true
	'NET_NDIS' = $true
	'NET_VmSwitch' = $true
	'NET_SMBcli' = $true
	'NET_SMBsrv' = $true
	'CommonTask SHA' = $True 
	'NetshScenario NetConnection capturetype=both correlation=disabled' = $true
	'PerfMon SMB' = $true
	'PSR' = $true
	'SDP HyperV' = $True
	'xray' = $True
	'CollectComponentLog' = $True
 }
 
 $SHA_HypVM_ETWTracingSwitchesStatus = [Ordered]@{
	'NET_HypVM' = $true
	'NET_NDIS' = $true
	'CommonTask SHA' = $True 
	'NetshScenario InternetClient_dbg' = $true
	'PSR' = $true
	'SDP NET' = $True
	'xray' = $True
	'CollectComponentLog' = $True
 }
 
$SHA_MScluster_ETWTracingSwitchesStatus = [Ordered]@{
	'SHA_MsCluster' = $true
	'SHA_iSCSI' = $true
	'SHA_MPIO' = $true
	'SHA_msDSM' = $true
	'SHA_StorageReplica' = $true
	'SHA_StorageSpace' = $true
	'SHA_CSVFS' = $true
	'SHA_StorPort' = $true
	'SHA_Storage' = $true
	'NET_LBFo' = $true
	'CommonTask SHA' = $True 
	'NetshScenario NetConnection' = $true
	'PerfMon ALL' = $true
	#'Procmon' = $true
	'PSR' = $true
	#'Video' = $true
	'SDP Cluster' = $True
	'xray' = $True
	'CollectComponentLog' = $True
 }
#endregion --- Scenario definitions ---

#region --- performance counters ---
$SHA_SupportedPerfCounter = @{
	'SHA_HyperV' = 'General counters + counter for Hyper-V'
}
$SHA_HyperVCounters = @(
	$global:HyperVCounters
	# Others => Comment out when you want to add
	#'\Hyper-V Dynamic Memory Integration Service(*)\*'
	#'\Hyper-V Hypervisor(*)\*'
	#'\Hyper-V Replica VM(*)\*'
	#'\Hyper-V Virtual Machine Bus(*)\*'
	#'\Hyper-V Virtual Machine Health Summary(*)\*'
	#'\Hyper-V VM Remoting(*)\*'
	#'\Hyper-V VM Save, Snapshot, and Restore(*)\*'
)
#endregion --- performance counters ---

<#
Switch (FwGetProductTypeFromReg)
{
	"WinNT" {
		$SHA_MyScenarioTest_ETWTracingSwitchesStatus = [Ordered]@{
			'SHA_TEST1' = $true
			'SHA_TEST2' = $true
			'SHA_TEST3' = $true   # Multi files
			'UEX_Task' = $True   # Outside of this module
		}
	}
	"ServerNT" {
		$SHA_MyScenarioTest_ETWTracingSwitchesStatus = [Ordered]@{
			'SHA_TEST1' = $true
			'SHA_TEST2' = $true
		}
	}
	"LanmanNT" {
		$SHA_MyScenarioTest_ETWTracingSwitchesStatus = [Ordered]@{
			'SHA_TEST1' = $true
			'SHA_TEST2' = $true
		}
	}
	Default {
		$SHA_MyScenarioTest_ETWTracingSwitchesStatus = [Ordered]@{
			'SHA_TEST1' = $true
			'SHA_TEST2' = $true
		}
	}
}
#>


#region ### Pre-Start / Post-Stop / Collect functions for trace components and scenarios 
function SHA_start_common_tasks {
	#collect info for all tss runs at _Start_
	EnterFunc $MyInvocation.MyCommand.Name
	LogDebug "___switch Mini: $global:Mini" "cyan"
	if ($global:Mini -ne $true) {
		FwGetSysInfo _Start_
		FwGetSVC _Start_
		FwGetSVCactive _Start_ 
		FwGetTaskList _Start_
		FwGetSrvWkstaInfo _Start_
		FwGetNltestDomInfo _Start_
		FwGetDFScache _Start_
		FwGetKlist _Start_ 
		FwGetBuildInfo
		if ($global:noClearCache -ne $true) { FwClearCaches _Start_ } else { LogInfo "[$($MyInvocation.MyCommand.Name) skip FwClearCaches" }
		FwGetRegList _Start_
		FwGetPoolmon _Start_
		FwGetSrvRole
	}
	FwGetLogmanInfo _Start_
	LogInfoFile "___ SHA_start_common_tasks DONE"
	EndFunc $MyInvocation.MyCommand.Name
}
function SHA_stop_common_tasks {
	#collect info for all tss runs at _Stop_
	EnterFunc $MyInvocation.MyCommand.Name
	if ($global:Mini -ne $true) {
		FwGetDFScache _Stop_
		FwGetSVC _Stop_
		FwGetSVCactive _Stop_ 
		FwGetTaskList _Stop_
		FwGetKlist _Stop_
		FwGetDSregCmd
		FwGetPowerCfg
		FwGetHotfix
		FwGetPoolmon _Stop_
		FwGetLogmanInfo _Stop_
		FwGetNltestDomInfo _Stop_
		FwGetRegList _Stop_
		("System", "Application") | ForEach-Object { FwAddEvtLog $_ _Stop_}
		FwGetEvtLogList _Stop_
	}
	FwGetSrvWkstaInfo _Stop_
	FwGetRegHives _Stop_
	LogInfoFile "___ SHA_stop_common_tasks DONE"
	EndFunc $MyInvocation.MyCommand.Name
}

function SHA_HypHostPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	FwGetNetAdapter _Start_
	FwFwGetVMNetAdapter _Start_
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectSHA_HypHostLog {
	EnterFunc $MyInvocation.MyCommand.Name
	($EvtLogsShaHypHost, $global:EvtLogsSMBcli ) | ForEach-Object { FwAddEvtLog $_ _Stop_}
	if ($global:OSVersion.Build -gt 9600) { $global:EvtLogsSMBcliOpt | ForEach-Object { FwAddEvtLog $_ _Stop_} }
	FwAddRegItem @("HyperV") _Stop_
	FwGetNetAdapter _Stop_
	FwGetVMNetAdapter _Stop_
	LogInfo "[$($MyInvocation.MyCommand.Name)] exporting the Hyper-V configuration"
	Invoke-Command -ScriptBlock { Get-VMHost | Export-Clixml -LiteralPath $global:LogFolder\$($LogPrefix)HyperV_Config.xml }
	LogInfo "[$($MyInvocation.MyCommand.Name)] exporting data.vmcx file"
	$SourceDestination = New-Object 'System.Collections.Generic.List[Object]'
	$SourceDestination.add(@("C:\programdata\Microsoft\Windows\Hyper-V\data.vmcx", "$global:LogFolder"))
	FwCopyFiles $SourceDestination
	$outFile = $PrefixTime + "HypHost_DirHV.txt"
	LogInfo "[$($MyInvocation.MyCommand.Name)] Exporting files name located in %programdata%\Microsoft\Windows\Hyper-V"
	Get-ChildItem C:\programdata\Microsoft\Windows\Hyper-V > $outFile
	EndFunc $MyInvocation.MyCommand.Name
}

function SHA_HypVMPreStart {
	EnterFunc $MyInvocation.MyCommand.Name
	FwSetEventLog "Microsoft-Windows-Hyper-V-NETVSC/Diagnostic"
	LogInfo "[$($MyInvocation.MyCommand.Name)] *** [Hint] Consider running FRUTI.exe for Hyper-V replication issues."
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectSHA_HypVMLog {
	EnterFunc $MyInvocation.MyCommand.Name
	FwResetEventLog @("Microsoft-Windows-Hyper-V-NETVSC/Diagnostic")
	("Microsoft-Windows-Hyper-V-NETVSC/Diagnostic") | ForEach-Object { FwAddEvtLog $_ _Stop_}
	EndFunc $MyInvocation.MyCommand.Name
}

Function Register_SDDC{
	EnterFunc $MyInvocation.MyCommand.Name
	$ispresent = get-command Get-PCStorageDiagnosticInfo -ErrorAction SilentlyContinue
	if ($null -eq $ispresent) {
			$module = 'PrivateCloud.DiagnosticInfo'; $branch = 'master'
			#Remove old version
			if (Test-Path $env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\$module) {
				Remove-Item -Recurse $env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\$module -ErrorAction Stop
				Remove-Module $module -ErrorAction SilentlyContinue
			}

			$md = "$env:ProgramFiles\WindowsPowerShell\Modules"
		   	Copy-Item -Recurse $global:ScriptFolder\psSDP\Diag\global\PrivateCloud.DiagnosticInfo $md -Force -ErrorAction Stop

			$ispresent = get-command Get-PCStorageDiagnosticInfo -ErrorAction SilentlyContinue
	} 
	EndFunc $MyInvocation.MyCommand.Name
}

function SHA_MSDTCPreStart {
	EnterFunc $MyInvocation.MyCommand.Name

	$LogFolder = "$global:LogFolder\MSDTC"
	FwCreateFolder $LogFolder
	$enableAll = 0xFF 
	$value = $enableAll
	$options = ("TRACE_MISC",
				"TRACE_CM",
				"TRACE_TRACE",
				"TRACE_SVC",
				"TRACE_GATEWAY",
				"TRACE_UI",
				"TRACE_CONTACT",
				"TRACE_UTIL",
				"TRACE_CLUSTER",
				"TRACE_RESOURCE",
				"TRACE_TIP",
				"TRACE_XA",
				"TRACE_LOG",
				"TRACE_MTXOCI",
				"TRACE_ETWTRACE",
				"TRACE_PROXY",
				"TRACE_KTMRM",
				"TRACE_VSSBACKUP",
				"TRACE_PERFMON",
				"TRACE_WMI")
	LogInfo " .. enabling MSDTC service traces."
	$options | foreach {
		$property = $_
		set-itemproperty "HKLM:\SOFTWARE\Microsoft\MSDTC\Tracing\Sources" -name $property -Value $value
	}
	
	set-itemproperty "HKLM:\SOFTWARE\Microsoft\MSDTC\Tracing\Output" -name TraceFilePath -Value $LogFolder
	set-itemproperty "HKLM:\SOFTWARE\Microsoft\MSDTC\Tracing\Output" -name ImageNameInTraceFileNameEnabled -Value 0x1   
	
	LogInfo " .. restarting MSDTC service."
	Net stop msdtc 
	Net start msdtc

	LogInfo " .. will start dummy SHA_MSDTCtrace.etl"
	EndFunc $MyInvocation.MyCommand.Name

}

function CollectSHA_MSDTCLog {
	EnterFunc $MyInvocation.MyCommand.Name

	$LogFolder = "$global:LogFolder\MSDTC"
	FwCreateFolder $LogFolder
	$disableAll = 0x00  
	$value = $disableAll
	$options = ("TRACE_MISC",
				"TRACE_CM",
				"TRACE_TRACE",
				"TRACE_SVC",
				"TRACE_GATEWAY",
				"TRACE_UI",
				"TRACE_CONTACT",
				"TRACE_UTIL",
				"TRACE_CLUSTER",
				"TRACE_RESOURCE",
				"TRACE_TIP",
				"TRACE_XA",
				"TRACE_LOG",
				"TRACE_MTXOCI",
				"TRACE_ETWTRACE",
				"TRACE_PROXY",
				"TRACE_KTMRM",
				"TRACE_VSSBACKUP",
				"TRACE_PERFMON",
				"TRACE_WMI")
	LogInfo " .. disabling MSDTC service traces."
	$options | foreach {
		$property = $_
		remove-itemproperty "HKLM:\SOFTWARE\Microsoft\MSDTC\Tracing\Sources" -name $property
	}
	 
	remove-itemproperty "HKLM:\SOFTWARE\Microsoft\MSDTC\Tracing\Output" -name TraceFilePath
	remove-itemproperty "HKLM:\SOFTWARE\Microsoft\MSDTC\Tracing\Output" -name ImageNameInTraceFileNameEnabled

	LogInfo " .. restarting MSDTC service."
	Net stop msdtc 
	Net start msdtc

	CollectSHA_support-clusterLog
	CollectSHA_support-diskLog
	CollectSHA_support-mpioLog
	CollectSHA_support-vssLog
	CollectSHA_support-diskshadowLog
	CollectSHA_support-driverinfoLog
	CollectSHA_support-fltmcLog
	CollectSHA_support-handleLog
	CollectSHA_support-iscsiLog
	CollectSHA_support-networkLog
	CollectSHA_support-registryLog
	CollectSHA_support-setupLog
	CollectSHA_support-taskschedulerLog
	CollectSHA_support-eventlogLog
	CollectSHA_support-systemLog

	EndFunc $MyInvocation.MyCommand.Name
}


### Data Collection
Function CollectSHA_SDDCLog{
	# invokes external script for PrivateCloud.DiagnosticInfo
	EnterFunc $MyInvocation.MyCommand.Name
	Register_SDDC
	LogInfo "[$($MyInvocation.MyCommand.Name)] . calling GetSddcDiagnosticInfo.ps1"
	if (Test-Path -path "$global:ScriptFolder\psSDP\Diag\global\GetSddcDiagnosticInfo.ps1") {
		LogInfoFile "--- $(Get-Date -Format 'HH:mm:ss') ..starting .\psSDP\Diag\global\GetSddcDiagnosticInfo.ps1 -WriteToPath $global:LogFolder\HealthTest -ZipPrefix $global:LogFolder\_Sddc-Diag"
		& Get-PCStorageDiagnosticInfo -WriteToPath $global:LogFolder\HealthTest -ZipPrefix $global:LogFolder\_Sddc-Diag
		#& "$global:ScriptFolder\psSDP\Diag\global\GetSddcDiagnosticInfo.ps1" -WriteToPath $global:LogFolder\HealthTest -ZipPrefix $global:LogFolder\_Sddc-Diag
		LogInfoFile "--- $(Get-Date -Format 'HH:mm:ss') ...Finished SDDC Diagnostics Data (PrivateCloud.DiagnosticInfo)"
		LogInfo "[$($MyInvocation.MyCommand.Name)] . Done GetSddcDiagnosticInfo.ps1"
	} else { LogWarn "Script GetSddcDiagnosticInfo.ps1 not found!" cyan} 

	# SpaceDB ChkSpace
	if ((!$global:IsLiteMode) -and (Test-Path  $global:SpaceDBExe)){ 
		LogInfo "[$($MyInvocation.MyCommand.Name)] . calling spacedb Chkspace"
		$outFile = $PrefixTime + "SPACEDB_Chkspace" +".txt"
		$Commands = @(
						"$global:SpaceDBExe Chkspace| Out-File -Append $outfile")
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
		LogInfo "[$($MyInvocation.MyCommand.Name)] running SpaceDB Chkspace"
	}
	else {
		LogInfo "[$($MyInvocation.MyCommand.Name)] skipped SpaceDB Chkspace"
	}
	EndFunc $MyInvocation.MyCommand.Name
}

Function SHA_MsClusterScenarioPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	#_# if "%_LiveDmp_analytic%" equ "1" call :Start_LiveDump_Analytic_logs
	EndFunc $MyInvocation.MyCommand.Name
}
Function CollectSHA_MsClusterScenarioLog{
	EnterFunc $MyInvocation.MyCommand.Name
	#_# if "%_LiveDmp_analytic%" equ "1" call :Stop_LiveDump_Analytic_logs
	GetClusterRegHives _Stop_

	LogInfo "[$($MyInvocation.MyCommand.Name)] Running Cluster GetLogs from all nodes "
	$GetLogsPath = $global:LogFolder + "\ClusterLogs"
	
	.\scripts\tss_Cluster_GetLogs.ps1 -LogPath $GetLogsPath

	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_ShieldedVMLog {
	EnterFunc $MyInvocation.MyCommand.Name
	$Commands = @(
		"Get-HgsTrace -RunDiagnostics -Detailed -Path $global:LogFolder\ShieldedVM"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	($EvtLogsShieldedVm) | ForEach-Object { FwAddEvtLog $_ _Stop_}
	EndFunc $MyInvocation.MyCommand.Name
}

Function CollectSHA_SmsLog{
	# invokes external script GetSmsLogs.psm1 until fully integrated into TSS
	EnterFunc $MyInvocation.MyCommand.Name
	Try{
		$Global:fServerSKU = (Get-CimInstance -Class CIM_OperatingSystem -ErrorAction Stop).Caption -like "*Server*"
	}Catch{
		LogException "An exception happened in Get-CimInstance for CIM_OperatingSystem" $_ $fLogFileOnly
		$Global:fServerSKU = $False
	}
	if ($Global:fServerSKU) {
		LogInfo "[$($MyInvocation.MyCommand.Name)] . calling GetSmsLogs.psm1"
		Import-Module .\scripts\GetSmsLogs.psm1 -DisableNameChecking
		Get-SmsLogs -Path $global:LogFolder #-AcceptEula
		LogInfo "[$($MyInvocation.MyCommand.Name)] . Done GetSmsLogs.psm1"
	} else { LogWarn " Computer $env:Computername is not running Server SKU"}
	EndFunc $MyInvocation.MyCommand.Name
}

Function SHA_VMLPreStart{
	EnterFunc $MyInvocation.MyCommand.Name
	if ($global:Mode -iMatch "Verbose") {
		LogInfo ".. will restart the Hyper-V service now with script tss_VMLVerbosity.ps1 -set 'Verbose'"
		.\scripts\tss_VMLverbosity.ps1 -set "Verbose"
	}
	if (!$global:IsLiteMode){
		LogInfo ".. starting $VmlTrace_exe $global:VmltraceCmd in circular mode"	# _VmltraceCmd is defined in tss_config.cfg
		$Commands = @(
			"$VmlTrace_exe $global:VmltraceCmd /l $PrefixTime`Vmltrace.etl /n ms_VmlTraceSession 2>&1 | Out-File -Append $global:ErrorLogFile"
		)
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
		if ($global:OSVersion.Build -ge 14393) {
			$outFile = $PrefixTime + "FRuti.txt"
			#LogInfo ".. starting $frutiExe /t /LN 1001 /f /v /lp $outFile"
			# START !_FrutiExe! /t /LN 1001 /f /v /lp !_PrefixT!FRuti.txt
			$ArgumentList = " /t /LN 1001 /f /v /lp `"$outFile`""
			LogInfo ".. starting $frutiExe $ArgumentList"
			$global:FrutiExeProc = Start-Process -FilePath $FrutiExe -ArgumentList $ArgumentList -PassThru
				
			#$Commands = @(	"$frutiExe /t /LN 1001 /f /v /lp $outFile | Out-File -Append $global:ErrorLogFile")
			#RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
		}
	}else{ LogInfo "Skipping Start of $VmlTrace_exe and $FrutiExe in Lite mode"}
	LogInfo " .. will start dummy SHA_VMLtrace.etl"
	EndFunc $MyInvocation.MyCommand.Name
}
Function CollectSHA_VMLLog{
	EnterFunc $MyInvocation.MyCommand.Name

	if (!$global:IsLiteMode){
		LogInfo ".. stoppping and converting VmlTrace.etl"
		$Commands = @(
			"$VmlTrace_exe /s /n ms_VmlTraceSession 2>&1 | Out-File -Append $global:ErrorLogFile"
		)
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
		if ($global:OSVersion.Build -ge 14393) {
			#Ending Fruti trace session
			LogInfo ".. running LogMan stop FrutiLog -ets"
			$global:FrutiExeProc = Start-Process -FilePath "logman.exe" -ArgumentList "stop FrutiLog -ets"

			if(Test-path "$PrefixTime`Vmltrace.etl") {
				$Commands = @("netsh trace convert $PrefixTime`Vmltrace.etl 2>&1 | Out-File -Append $global:ErrorLogFile")
				RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
			}
		}
	}else{ LogInfo "Skipping Stop of $VmlTrace_exe and $FrutiExe in Lite mode"}
	if ($global:Mode -iMatch "Verbose") {
		LogInfo ".. will restart the Hyper-V service now with script tss_VMLVerbosity.ps1 -set 'Standard'"
		.\scripts\tss_VMLverbosity.ps1 -set "Standard"
	}
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-clusterLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$ClusterFile = "C:\Windows\Cluster\clussvc.exe"
	if ( -not (Test-Path $ClusterFile)) {
		LogInfo "skip collect cluster information."
		Return
	}
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\cluster"
	FwCreateFolder $LogFolder
	$Commands = @(
		"$global:ChecksymExe -F c:\Windows\cluster -R | Out-File ${LogFolder}\${Env:COMPUTERNAME}_clustermoduleChecksym.log",
		"REG EXPORT HKLM\Cluster ${LogFolder}\${Env:COMPUTERNAME}_Cluster.reg",
		"REG SAVE HKLM\Cluster ${LogFolder}\${Env:COMPUTERNAME}_Cluster.hiv",
		"Get-Cluster | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-cluster.txt",
		"Get-Cluster | Get-ClusterParameter | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-cluster-parameter.txt",
		"Get-Cluster | Get-ClusterParameter | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-cluster-parameter-all.txt",
		"Get-ClusterNode | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusternode.txt",
		"Get-ClusterGroup | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustergroup.txt",
		"Get-ClusterSharedVolumeState | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustersharedvolumestate.txt",
		"Get-ClusterGroup | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustergroup-all.txt",
		"Get-ClusterResource | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusterresource.txt",
		"Get-ClusterResource | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusterresource-all.txt",
		"Get-ClusterResource | Get-ClusterParameter | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusterresource-with-parameter.txt",
		"Get-ClusterResource | Get-ClusterParameter | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusterresource-with-parameter-all.txt",
		"Get-ClusterS2D | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-cluster-s2d.txt",
		"Get-SmbConnection -SmbInstance SBL | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbconnection-smbinstance-sbl.txt",
		"Get-SmbServerConfiguration | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbserverconfiguration.txt",
		"Get-SmbServerNetworkInterface | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbservernetworkinterface.txt",
		"Get-SmbSession | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbsession.txt",
		"Get-SmbShare | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbshare-all.txt",
		"Get-SmbShare -SmbInstance SBL | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbshare-smbinstance-sbl.txt",
		"Get-SmbShare | Get-SmbShareAccess | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbshare-smbshareaccess.txt",
		"Get-SmbWitnessClient | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-smbwitnessclient.txt",
		"Get-StorageSubSystem Cluster* | Debug-StorageSubsystem | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_debug-storagesubsystem.txt",
		"Get-StorageSubSystem Cluster* | Get-StorageHealthReport | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagehealthreport.txt",
		"Get-CimInstance -Namespace root\wmi -ClassName ClusBfltDeviceInformation | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_clusbflt-deviceinformation.txt",
		"Get-CimInstance -Namespace root\wmi -ClassName ClusPortDeviceInformation | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_clusport-deviceinformation.txt",
		"Get-ClusterNetwork | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusternetwork.txt",
		"Get-ClusterNetworkInterface | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusternetworkinterface.txt",
		"Get-ClusterNetwork | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusternetwork-all.txt",
		"Get-ClusterSharedVolume | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustersharedvolume.txt",
		"Get-ClusterSharedVolume | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustersharedvolume-all.txt",
		"Get-ClusterSharedVolume | select -Property Name -ExpandProperty SharedVolumeInfo | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustersharedvolume-sharedvolumeinfo.txt",
		"Get-ClusterSharedVolume | Get-ClusterParameter | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustersharedvolume-clusterparameter.txt",
		"Get-ClusterSharedVolume | Get-ClusterParameter | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clustersharedvolume-clusterparameter-all.txt",
		"Get-ClusterQuorum | fl * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-clusterquorum-all.txt",
		"Save-CauDebugTrace -Path ${LogFolder}\${Env:COMPUTERNAME}_CauDebugTrace.zip"
		"Get-Clusterlog -Node localhost",
		"Get-Clusterlog -Node localhost -Health",
		"xcopy /s C:\Windows\Cluster\Reports\* ${LogFolder}"
		"Rename-Item ${LogFolder}\Cluster.log ${Env:COMPUTERNAME}_Cluster.log"
		"Rename-Item ${LogFolder}\ClusterHealth.log ${Env:COMPUTERNAME}_ClusterHealth.log"
		)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-diskLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\disk"
	$DiskPartCommands = "${LogFolder}\${Env:COMPUTERNAME}_diskpart-info.txt"
	FwCreateFolder $LogFolder
	Write-Output "list disk" | Out-File $DiskPartCommands -Append -Encoding ascii
	Write-Output "list volume" | Out-File $DiskPartCommands -Append -Encoding ascii
	Write-Output "list vdisk" | Out-File $DiskPartCommands -Append -Encoding ascii
	Write-Output "automount" | Out-File $DiskPartCommands -Append -Encoding ascii
	Write-Output "san" | Out-File $DiskPartCommands -Append -Encoding ascii

	$Commands = @(
		"Get-Disk | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-disk.txt",
		"Get-Disk | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-disk-detail.txt",
		"Get-PhysicalDisk | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-physicaldisk.txt",
		"Get-PhysicalDisk | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-physicaldisk-detail.txt",
		"Get-VirtualDisk | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-virtualdisk.txt",
		"Get-VirtualDisk | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-virtualdisk-detail.txt",
		"Get-StoragePool | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagepool.txt",
		"Get-StoragePool | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagepool-detail.txt",
		"Get-StorageTier | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagetier.txt",
		"Get-StorageTier | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagetier-detail.txt",
		"Get-StorageJob | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagejob.txt",
		"Get-StorageJob | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagejob-detail.txt",
		"Get-Partition | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-partition.txt",
		"Get-Partition | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-partition-detail.txt",
		"Get-Volume | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-volume.txt",
		"Get-Volume | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-volume-detail.txt",
		"Get-StorageEnclosure | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storageenclosure.txt",
		"Get-StorageEnclosure | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storageenclosure-detail.txt",
		"Get-StorageFaultDomain | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagefaultdomain.txt",
		"Get-StorageFaultDomain | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagefaultdomain-detail.txt",
		"Get-StorageSubsystem | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagesubsystem.txt",
		"Get-StorageSubsystem | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-storagesubsystem-detail.txt",  
		"diskpart /s $DiskPartCommands | Out-File ${LogFolder}\${Env:COMPUTERNAME}_diskpart.txt",
		"mountvol | Out-File ${LogFolder}\${Env:COMPUTERNAME}_mountvol.txt",	
		"manage-bde -status | Out-File ${LogFolder}\${Env:COMPUTERNAME}_manage-bde-status.txt",
		"net session | Out-File ${LogFolder}\${Env:COMPUTERNAME}_net_session.txt",
		"OPENFILES /Query /FO csv /V | Out-File ${LogFolder}\${Env:COMPUTERNAME}_openfiles.txt",

		"$global:ScriptFolder\psSDP\Diag\global\dosdev.exe -a | Out-File ${LogFolder}\${Env:COMPUTERNAME}_dosdev.txt",
		"$global:ScriptFolder\psSDP\Diag\global\SAN.exe ${LogFolder}"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}
function CollectSHA_support-mpioLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\mpio"
	$mpioFile = "c:\windows\system32\mpclaim.exe"
	if ( -not (Test-Path $mpioFile)) {
		LogInfo "skip collect mpio information."
		Return
	}
	FwCreateFolder $LogFolder
	Get-MPIOSetting | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-MPIOSetting.txt
	Get-MSDSMAutomaticClaimSettings | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-MSDSMAutomaticClaimSettings.txt
	Get-MPIOAvailableHW | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-MPIOAvailableHW.txt
	Get-MSDSMSupportedHW | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-MSDSMSupportedHW.txt
	mpclaim -s -d | Out-File ${LogFolder}\${Env:COMPUTERNAME}_mpclaim-s-d.txt

	$disks = (Get-CimInstance -Namespace root\wmi -Classname MPIO_DISK_INFO).NumberDrives
	for ($a = 0; $a -lt $disks; $a++) {
	   mpclaim -s -d $a | Out-File ${LogFolder}\${Env:COMPUTERNAME}_mpclaim-s-d-all.txt -Append -encoding UTF8
	}
#	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-dedupLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\mpio"
	if ( -not ((Get-WindowsFeature -Name FS-Data-Deduplication).Installed)) {
		LogInfo "skip collect dedup information."
		Return
	}
	FwCreateFolder $LogFolder
	$Commands = @(
		"Get-DedupJob | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-dedupjob.txt",
		"Get-DedupMetadata | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-dedupMetadata.txt",
		"Get-DedupSchedule | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-dedupSchedule.txt",
		"Get-DedupStatus | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-dedupstatus.txt",
		"Get-DedupStatus | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-dedupstatus-detail.txt",
		"Get-DedupVolume | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-dedupvolume.txt",
		"Get-DedupVolume | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-dedupvolume-detail.txt"	
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-diskshadowLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$diskshadowFile = "c:\windows\system32\diskshadow.exe"
	if ( -not (Test-Path $diskshadowFile)) {
		LogInfo "skip collect diskshadow information."
		Return
	}
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\diskshadow"
	$DiskShadowAllCommands = "${LogFolder}\${Env:COMPUTERNAME}_list_shadows_all.dat"
	$DiskShadowWritersCommands = "${LogFolder}\${Env:COMPUTERNAME}_list_writers_detailed.dat"
	FwCreateFolder $LogFolder
	Write-Output "list shadows all" | Out-File $DiskShadowAllCommands -Encoding ascii
	Write-Output "list writers detailed" | Out-File $DiskShadowWritersCommands -Encoding ascii
	$Commands = @(
		"diskshadow /s $DiskShadowAllCommands /l ${LogFolder}\${Env:COMPUTERNAME}_diskshadow_list_shadows_all.txt",
		"diskshadow /s $DiskShadowWritersCommands /l ${LogFolder}\${Env:COMPUTERNAME}_diskshadow_list_writers_detailed.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-driverinfoLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\driverinfo"
	FwCreateFolder $LogFolder
	$Commands = @(
		"driverquery /v | Out-File ${LogFolder}\${Env:COMPUTERNAME}_driverinfo.txt",
		"driverquery /fo csv /v | Out-File ${LogFolder}\${Env:COMPUTERNAME}_driverinfo.csv",
		"driverquery /si | Out-File ${LogFolder}\${Env:COMPUTERNAME}_driverinfo-si.txt",
		"$global:ChecksymExe -F c:\Windows\System32 -R | Out-File ${LogFolder}\${Env:COMPUTERNAME}_system32Checksym.log",
		"$global:ChecksymExe -F c:\Windows\System32\drivers -R | Out-File ${LogFolder}\${Env:COMPUTERNAME}_system32driversChecksym.log",
		"Get-CimInstance -ClassName Win32_PnPSignedDriver | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Win32_PnPSignedDriver.log"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-eventlogLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\eventlog"
	$LogFolderEvtx = "$LogFolder\evtx"
	$LogFolderCsv = "$LogFolder\csv"
	$LogFolderEtl = "$LogFolder\etl"
	FwCreateFolder $LogFolder
	FwCreateFolder $LogFolderEvtx
	FwCreateFolder $LogFolderCsv
	FwCreateFolder $LogFolderEtl
	$CommandToExecuteEvtx = "cscript.exe //e:vbscript $global:Scriptfolder\scripts\GetEvents24.VBS /channel $LogFolderEvtx /allevents /evtx /except:Security"
	$CommandToExecuteEtl = "cscript.exe //e:vbscript $global:Scriptfolder\scripts\GetEvents24.VBS /channel $LogFolderEtl /allevents /etl /except:Security"
	$CommandToExecuteCsv = "cscript.exe //e:vbscript $global:Scriptfolder\scripts\GetEvents24.VBS /channel $LogFolderCsv /allevents /csv /except:Security"

	Invoke-Expression -Command $CommandToExecuteEvtx | Out-Null
	Invoke-Expression -Command $CommandToExecuteCsv | Out-Null
	Invoke-Expression -Command $CommandToExecuteEtl | Out-Null

#	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-fltmcLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\fltmc"
	FwCreateFolder $LogFolder
	$Commands = @(
		"fltmc filters | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fltmc-filters.log",
		"fltmc volumes | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fltmc-volumes.log",
		"fltmc instances | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fltmc-instances.log"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-fsrmLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$fsrmFile = "C:\Windows\system32\srmsvc.dll"
	if ( -not (Test-Path $fsrmFile)) {
		LogInfo "skip collect fsrm information."
		Return
	}
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\fsrm"
	FwCreateFolder $LogFolder
	$Commands = @(
		"Get-FsrmAutoQuota | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmAutoQuota.txt",
		"Get-FsrmClassification | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmClassification.txt",
		"Get-FsrmClassificationPropertyDefinition | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmClassificationPropertyDefinition.txt",
		"Get-FsrmClassificationRule | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmClassificationRule.txt",
		"Get-FsrmFileGroup | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmFileGroup.txt",
		"Get-FsrmFileManagementJob | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmFileManagementJob.txt",
		"Get-FsrmFileScreen | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmFileScreen.txt",
		"Get-FsrmFileScreenException | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmFileScreenException.txt",
		"Get-FsrmFileScreenTemplate | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmFileScreenTemplate.txt",
		"Get-FsrmMgmtProperty | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmMgmtProperty.txt",
		"Get-FsrmQuota | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmQuota.txt",
		"Get-FsrmQuotaTemplate | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmQuotaTemplate.txt",
		"Get-FsrmSetting | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmSetting.txt",
		"Get-FsrmStorageReport | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-FsrmStorageReport.txt",
		"dirquota quota list | Out-File ${LogFolder}\${Env:COMPUTERNAME}_dirquota-quota-list.txt",
		"filescrn screen list | Out-File ${LogFolder}\${Env:COMPUTERNAME}_filescrn-screen-list.txt",
		"storrept reports list | Out-File ${LogFolder}\${Env:COMPUTERNAME}_storrept-reports-list.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-handleLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\handle"
	FwCreateFolder $LogFolder
	$Commands = @(
		"$global:ScriptFolder\BIN\handle.exe -a /AcceptEula | Out-File ${LogFolder}\${Env:COMPUTERNAME}_handle.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-HyperVLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$hypervFile = "C:\Windows\system32\vmms.exe"
	if ( -not (Test-Path $hypervFile)) {
		LogInfo "skip collect hyper-v information."
		Return
	}
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\hyper-v"
	FwCreateFolder $LogFolder
	$Commands = @(
		"Get-VMHost | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMHost.txt",
		"Get-VMHostNumaNode | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMHostNumaNode.txt",
		"Get-VMHostNumaNodeStatus | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMHostNumaNodeStatus.txt",
		"Get-VMHostSupportedVersion | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMHostSupportedVersion.txt",
		"Get-VMMigrationNetwork | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMMigrationNetwork.txt",
		"Get-VMSwitch | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMSwitch.txt",
		"Get-VMNetworkAdapter -All | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMNetworkAdapter-All.txt",
		"Get-VM | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VM.txt",
		"Get-VM | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VM-all.txt",
		"Get-VM | Get-VMIntegrationService | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMIntegrationService.txt",
		"Get-VM | Get-VMNetworkAdapter | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMNetworkAdapter.txt",
		"Get-VM | Get-VMNetworkAdapterVlan | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMNetworkAdapterVlan.txt",
		"Get-VM | Get-VMprocessor | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMprocessor.txt",
		"Get-VM | Get-VMSnapshot | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMSnapshot.txt",
		"Get-VM | Get-VMSecurity | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMSecurity.txt",
		"Get-VM | Get-VMBios | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMBios.txt",
		"Get-VM | Get-VMFirmware | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMFirmware.txt",
		"Get-VMHostNumaNode | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMHostNumaNode.txt",
		"Get-VMReplication | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMReplication.txt",
		"Get-VMReplication | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMReplication-all.txt",
		"Get-VMReplicationAuthorizationEntry | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMReplicationAuthorizationEntry.txt",
		"Get-VMReplicationServer | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMReplicationServer.txt",
		"Get-ClusterGroup | ? {$_.GroupType -eq 'VirtualMachine' } | Get-VM | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-ClusterGroup_Get-VM-all.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-HyperV-detailLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$hypervFile = "C:\Windows\system32\vmms.exe"
	if ( -not (Test-Path $hypervFile)) {
		LogInfo "skip collect hyper-v detail information."
		Return
	}
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\hyper-v"
	FwCreateFolder $LogFolder
	$FileDescription = "Text File containing Hyper-V basic settings and configuration information."
	$SectionDescription = "Hyper-V Basic Information"
	$Outputfile = "$LogFolder\${Env:COMPUTERNAME}_Hyper-VBasicInfo.txt"
	Filter Import-CimXml
	{
		# Create new XML object from input
		$CimXml = [Xml]$_
		$CimObj = New-Object -TypeName System.Object
		# Iterate over the data and pull out just the value name and data for each entry
		ForEach ($CimProperty in $CimXml.SelectNodes("/INSTANCE/PROPERTY[@NAME='Name']")){
			$CimObj | Add-Member -MemberType NoteProperty -Name $CimProperty.NAME -Value $CimProperty.VALUE
		}
		ForEach ($CimProperty in $CimXml.SelectNodes("/INSTANCE/PROPERTY[@NAME='Data']")){
			$CimObj | Add-Member -MemberType NoteProperty -Name $CimProperty.NAME -Value $CimProperty.VALUE
		}
		# Display output
		$CimObj
	}

	Function showHVGlobalSettings{
		$VSMgtServiceSettingData = $args[0]
		("Hyper-V Global Settings") | Out-File $Outputfile  -Append -encoding UTF8
		("----------------------------------------") | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8

		("Hyper-V Settings:") | Out-File $Outputfile  -Append -encoding UTF8
		("	Virtual Hard Disks: " + $VSMgtServiceSettingData.DefaultVirtualHardDiskPath) | Out-File $Outputfile  -Append -encoding UTF8
		("	Virtual Machines: " + $VSMgtServiceSettingData.DefaultExternalDataRoot) | Out-File $Outputfile  -Append -encoding UTF8
		("	Physical GPUs: ") | Out-File $Outputfile  -Append -encoding UTF8
		("	NUMA Spanning: " + $VSMgtServiceSettingData.NumaSpanningEnabled) | Out-File $Outputfile  -Append -encoding UTF8

		### Live migrations
		$VSMigrationService = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_VirtualSystemMigrationService' 
		$VSMigServiceSettingData = $VSMigrationService.GetRelated('Msvm_VirtualSystemMigrationServiceSettingData') 
		("	Live Migrations:") | Out-File $Outputfile  -Append -encoding UTF8
		("		Enable incoming and outgoing live migrations: " + $VSMigServiceSettingData.EnableVirtualSystemMigration) | Out-File $Outputfile  -Append -encoding UTF8

		switch ($VSMigServiceSettingData.AuthenticationType){
			0   {$AuthTypeStr = "CredSSP(0)"}
			1   {$AuthTypeStr = "Kerberos(1)"}
		}
		("		Authentication protocol: " + $AuthTypeStr) | Out-File $Outputfile  -Append -encoding UTF8
		("		Simultaneous live migrations: " + $VSMigServiceSettingData.MaximumActiveVirtualSystemMigration) | Out-File $Outputfile  -Append -encoding UTF8
		("		Incoming live migrations: ") | Out-File $Outputfile  -Append -encoding UTF8

		$MigNetworksSettings = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_VirtualSystemMigrationNetworkSettingData' 
		$NetworksSet = 0

		ForEach($MigNetworksSetting in $MigNetworksSettings){
			For($i=0; $i -lt $MigNetworksSetting.Tags.Count; $i++){
				If($MigNetworksSetting.Tags[$i] -eq "Microsoft:UserManagedAllNetworks"){
					$NetworksSet++
				}
			}
		}
		
		If($NetworksSet -gt 0){
			$NetworkOptionStr = "Use any available network for live migration"
		}Else{
			$NetworkOptionStr = "Use these IP addresses for live migration"
			$IPList = $VSMigrationService.MigrationServiceListenerIPAddressList
			For($y=0; $y -lt $IPLIst.count; $y++){
				$IPListStr = $IPListStr + " " + $IPList[$y]
			}
		}

		("			Option: " + $NetworkOptionStr) | Out-File $Outputfile  -Append -encoding UTF8

		If($NetworksSet -eq 0){
			("				Network List: " + $IPListStr) | Out-File $Outputfile  -Append -encoding UTF8
		}

		#### Storage Migrations
		("	Storage Migrations:") | Out-File $Outputfile  -Append -encoding UTF8
		("		Simultaneous storage migrations: " + $VSMigServiceSettingData.MaximumActiveStorageMigration) | Out-File $Outputfile  -Append -encoding UTF8

		### Replication Configuration
		("	Replication Configuration:") | Out-File $Outputfile  -Append -encoding UTF8
		$HVRServiceSettingData = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ReplicationServiceSettingData'

		If ($HVRServiceSettingData.RecoveryServerEnabled){
		switch ($HVRServiceSettingData.AllowedAuthenticationType){
				0   {$AllowedAuthenticationType = "Not defined"}
				1   {$AllowedAuthenticationType = "Use kerberos (HTTP)"}
				2   {$AllowedAuthenticationType = "Use certificate-based Authentication"}
				3   {$AllowedAuthenticationType = "Both certificate based authentication and integrated authentication"}
			}

			("		Authentication and ports:") | Out-File $Outputfile  -Append -encoding UTF8
			("			Authentication Type: " + $AllowedAuthenticationType) | Out-File $Outputfile  -Append -encoding UTF8 
			("			HttpPort(Kerberos) : " + $HVRServiceSettingData.HttpPort) | Out-File $Outputfile  -Append -encoding UTF8
			("			HttpsPort(Certificate): " + $HVRServiceSettingData.HttpsPort) | Out-File $Outputfile  -Append -encoding UTF8

			$HVRAuthSettingData = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ReplicationAuthorizationSettingData'
			$AuthEntryCount = ($HVRAuthSettingData | Measure-Object).count

			("		Authentication and Storage:") | Out-File $Outputfile  -Append -encoding UTF8
	
			If($AuthEntryCount -eq 1 -and $HVRAuthSettingData.AllowedPrimaryHostSystem -eq "*")
			{
				$AuthServerStr = "Type: Allow replication from any authenticated server"
				("			" + $AuthServerStr) | Out-File $Outputfile  -Append -encoding UTF8
				("			Storage location: " + $HVRAuthSettingData.ReplicaStorageLocation) | Out-File $Outputfile  -Append -encoding UTF8
			}Else{
				$AuthServerStr = "Type: Allow replication from specifed servers"
				("			" + $AuthServerStr) | Out-File $Outputfile  -Append -encoding UTF8
				ForEach($HVRAuthSetting in $HVRAuthSettingData){
					("				Primary server: " + $HVRAuthSetting.AllowedPrimaryHostSystem + " | Storage location: "  + $HVRAuthSetting.ReplicaStorageLocation + " | TrustGroup: " + $HVRAuthSetting.TrustGroup) | Out-File $Outputfile  -Append -encoding UTF8
				}
			}
		}Else{
			("		Hyper-V Replica is not configured as replica server.") | Out-File $Outputfile  -Append -encoding UTF8
		}

		### Enhanced Session Mode Policy (WS2012R2 or later)
		If($VSMgtServiceSettingData.EnhancedSessionModeEnabled -eq $null){
			$EnhancedSessionMode = "N/A (Enhanced session mode is supported from Windows Server 2012 R2)"
		}Else{
			$EnhancedSessionMode = $VSMgtServiceSettingData.EnhancedSessionModeEnabled	 
		}

		("	Enhanced session mode policy: " + $EnhancedSessionMode) | Out-File $Outputfile  -Append -encoding UTF8

		### Memory reserve
		$memReserveRegKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\"
		$memReserveReg = Get-ItemProperty $memReserveRegKey
		$memoryReserve = $memReserveReg."MemoryReserve"

		If($memoryReserve -ne $null){
			("	Memory Reserve: " + $memoryReserve + " MB(WARNING: Memory reserve is set)") | Out-File $Outputfile  -Append -encoding UTF8
		}

		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showNUMAinfo(){

		("NUMA Information") | Out-File $Outputfile  -Append -encoding UTF8
		("----------------------------------------") | Out-File $Outputfile  -Append -encoding UTF8

		$hostName = hostname
		$hostComputer = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -eq $hostname}
		$numaNodes = $hostComputer.GetRelated("Msvm_NumaNode")
		
		Foreach($numaNode in $numaNodes) {
			("") | Out-File $Outputfile  -Append -encoding UTF8 
			($numaNode.ElementName + ":") | Out-File $Outputfile  -Append -encoding UTF8
			("	EnabledState				   : " + $numaNode.EnabledState) | Out-File $Outputfile  -Append -encoding UTF8
			("	HealthState					: " + $numaNode.HealthState) | Out-File $Outputfile  -Append -encoding UTF8
			("	NumberOfLogicalProcessors	  : " + $numaNode.NumberOfLogicalProcessors) | Out-File $Outputfile  -Append -encoding UTF8
			("	NumberOfProcessorCores		 : " + $numaNode.NumberOfProcessorCores) | Out-File $Outputfile  -Append -encoding UTF8
			("	CurrentlyConsumableMemoryBlocks: " + $numaNode.CurrentlyConsumableMemoryBlocks) | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8
			
			$Memory = $numaNode.GetRelated("Msvm_Memory") | Where-Object { $_.SystemName -eq $hostName}
			$MemSizeGB = ($Memory.ConsumableBlocks * $Memory.BlockSize / 1024 / 1024 / 1024)
			$MemSizeGB2 = [math]::round($MemSizeGB, 2)
			$MemSizeMB = ($Memory.ConsumableBlocks * $Memory.BlockSize / 1024 / 1024)

			("	==== " + $Memory.ElementName + " ====") | Out-File $Outputfile  -Append -encoding UTF8
			("	BlockSize					  : " + $Memory.BlockSize) | Out-File $Outputfile  -Append -encoding UTF8
			("	ConsumableBlocks			   : " + $Memory.ConsumableBlocks) | Out-File $Outputfile  -Append -encoding UTF8
			("	Size						   : " + $MemSizeMB + "MB / " + $MemSizeGB2 + "GB") | Out-File $Outputfile  -Append -encoding UTF8
			("	EnabledState				   : " + $Memory.EnabledState) | Out-File $Outputfile  -Append -encoding UTF8
			("	HealthState					: " + $Memory.HealthState) | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8
		}
	}

	Function showVMBasicinfo(){
		$VM = $args[0]
		$VSSettingData = $args[1]
		("Basic information:") | Out-File $Outputfile  -Append -encoding UTF8
		("	GUID: " + $VM.Name) | Out-File $Outputfile  -Append -encoding UTF8

		If($VM.ProcessID -eq $null){
			$procId = "N/A => Virtual Machine is not running."
		}Else{
			$procId = $VM.ProcessID
		}

		("	PID: " + $procId) | Out-File $Outputfile  -Append -encoding UTF8

		### VM Version
		("	Version: " + $VSSettingData.Version) | Out-File $Outputfile  -Append -encoding UTF8

		### VM Generation
		$vmGgeneration = getVmGeneration $VSSettingData  
		("	Generation: " + $vmGgeneration) | Out-File $Outputfile  -Append -encoding UTF8

		### Enabled state
		$vmStatus = getVMEnabledState $VM.EnabledState
		("	State: " + $vmStatus) | Out-File $Outputfile  -Append -encoding UTF8

		### Heartbeat
		$heartbeatComponent = Get-WmiObject  -namespace 'root\virtualization\v2' -query "associators of {$VM} where ResultClass = Msvm_HeartbeatComponent"

		If($heartbeatComponent -eq $null){
			$heartbeartStr = "N/A(Virtual Machine is not running)"
		}ElseIf($heartbeatComponent.EnabledState -eq 3){
			$heartbeartStr = "N/A(Heartbeat service is not enabled)"
		}Else{
			$hbStatusStr1 = getHBOperationalStatus $heartbeatComponent.OperationalStatus[0]
			$hbStatusStr2 = getHBSecondaryStatus $heartbeatComponent.OperationalStatus[1]
			$heartbeartStr = $hbStatusStr1 + "(Application state - " + $hbStatusStr2 + ")"
		}

		("	Heartbeat: " + $heartbeartStr) | Out-File $Outputfile  -Append -encoding UTF8

		### Health state
		switch ($VM.HealthState){
			# https://msdn.microsoft.com/en-us/library/hh850116(v=vs.85).aspx
			5   {$healthState = "OK" + "(" + $VM.HealthState + ")"}
			20   {$healthState = "Major Failure" + "(" + $VM.HealthState + ")"}
			25   {$healthState = "Critical failure)" + "(" + $VM.HealthState + ")"}
		}

		("	Health state: " + $healthState) | Out-File $Outputfile  -Append -encoding UTF8

		### Uptime
		$uptimeSeconds = $VM.OnTimeInMilliseconds / 1000
		$uptimeMinutes = $uptimeSeconds / 60
		$seconds = [math]::Truncate($uptimeSeconds % 60)
		$minutes = [math]::Truncate($uptimeMinutes % 60)
		$hours = [math]::Truncate($uptimeSeconds / 3600)

		("	Uptime: " + $hours + ":" + $minutes +  ":" + $seconds) | Out-File $Outputfile  -Append -encoding UTF8
	
		### IC version
		If($VM.EnabledState -eq 2){
			$KvpExchangeComponent = $VM.GetRelated("Msvm_KvpExchangeComponent")

			If($KvpExchangeComponent.count -eq 0){
				$versionString = "Unable to retrieve IC version. VM would not be started."
			}ElseIf($KvpExchangeComponent.GuestIntrinsicExchangeItems -ne $null){
				$IntrinsicItems = $KvpExchangeComponent.GuestIntrinsicExchangeItems | Import-CimXml 
				$icVersionItem = $IntrinsicItems | Where {$_.Name -eq "IntegrationServicesVersion"}

				If($icVersionItem.Data -ne $null){
					$versionString = $icVersionItem.Data
					$icVersionExist = $True
				}Else{
					$versionString = "Unable to retrieve IC version. Key exchange service would not be running in guest."
				}
			}Else{
				$versionString = "Unable to retrieve IC version. Key exchange service would not be running in guest."
			}
		}Else{
			$versionString = "N/A(VM is not running)"
		}

		$icRegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\GuestInstaller\Version\"
		
		if (test-path $icRegistryKey){
			$icReg = Get-ItemProperty $icRegistryKey
			$hostICVersion =  $icReg."Microsoft-Hyper-V-Guest-Installer-Win6x-Package"

			If($hostICVersion -eq $icVersionItem.Data){
				("	Integration Service Version: " + $versionString + " => IC version is same with host version.") | Out-File $Outputfile  -Append -encoding UTF8
			}ElseIf($icVersionExist){
				("	Integration Service Version: " + $versionString + " => WARNING: IC version is not same with host version(" + $hostICVersion + ").") | Out-File $Outputfile  -Append -encoding UTF8
			}Else{
				("	Integration Service Version: " + $versionString) | Out-File $Outputfile  -Append -encoding UTF8
			}
		}

		If($VM.EnhancedSessionModeState -ne $null){
			switch ($VM.EnhancedSessionModeState){
				2   {$EnhancedSessionModeState = "Enhanced mode is allowed and available on the virtual machine(2)"}
				3   {$EnhancedSessionModeState = "Enhanced mode is not allowed on the virtual machine(3)"}
				6   {$EnhancedSessionModeState = "Enhanced mode is allowed and but not currently available on the virtual machine(6)"}
				default {$EnhancedSessionModeState = "Unknown"}
			}
			("	EnhancedSession Mode:  " + $EnhancedSessionModeState) | Out-File $Outputfile  -Append -encoding UTF8
		}

		("	Number of NUMA nodes: " + $VM.NumberOfNumaNodes) | Out-File $Outputfile  -Append -encoding UTF8

		### Configuration file
		$configPath = $VSSettingData.ConfigurationDataRoot + "\" + $VSSettingData.ConfigurationFile
		("	Configuration File: " + $configPath) | Out-File $Outputfile  -Append -encoding UTF8

		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showKVPItems(){
		$VM = $args[0]
		$VSSettingData = $args[1]

		$KvpExchangeComponent = $VM.GetRelated("Msvm_KvpExchangeComponent")
		$KvpExchangeComponentSettingData = $VSSettingData.GetRelated("Msvm_KvpExchangeComponentSettingData")

		("KVP Items:") | Out-File $Outputfile  -Append -encoding UTF8
		("	Guest intrinsic items:") | Out-File $Outputfile  -Append -encoding UTF8

		If($KvpExchangeComponent.count -eq 0){
			("		Unable to retrieve guest items. VM would not be started.") | Out-File $Outputfile  -Append -encoding UTF8
		}ElseIf($KvpExchangeComponent.GuestIntrinsicExchangeItems -ne $null){
			$IntrinsicItems = $KvpExchangeComponent.GuestIntrinsicExchangeItems | Import-CimXml 
			ForEach($IntrinsicItem in $IntrinsicItems){
				("		" + $IntrinsicItem.Name + ": " + $IntrinsicItem.Data) | Out-File $Outputfile  -Append -encoding UTF8
			}
			("") | Out-File $Outputfile  -Append -encoding UTF8
		}Else{
			("		Unable to retrieve guest items. Key exchange service would not be running in guest.") | Out-File $Outputfile  -Append -encoding UTF8
		}

		("") | Out-File $Outputfile  -Append -encoding UTF8
		("	Host only items:") | Out-File $Outputfile  -Append -encoding UTF8

		If($KvpExchangeComponentSettingData.HostOnlyItem -eq $null){
			("		No host only items.") | Out-File $Outputfile  -Append -encoding UTF8
		}Else{
			$HostItems = $KvpExchangeComponentSettingData.HostOnlyItems | Import-CimXml 
		
			If($HostItems.count -eq 0){
				("		No host only items are registerd.") | Out-File $Outputfile  -Append -encoding UTF8
			}Else{
				ForEach($HostItem in $HostItems){
					("		" + $HostItem.Name + ": " + $HostItem.Data) | Out-File $Outputfile  -Append -encoding UTF8
				}
			}
		}
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showBIOSinfo{
		$VSSettingData = $args[0]

		("BIOS:") | Out-File $Outputfile  -Append -encoding UTF8
		("	Num Lock: " + $VSSettingData.BIOSNumLock) | Out-File $Outputfile  -Append -encoding UTF8

		For($i=0; $i -lt $VSSettingData.BootOrder.length; $i++){
			switch ($VSSettingData.BootOrder[$i]){
				0   {$deviceStr = "Floppy"}
				1   {$deviceStr = "CD-ROM"}
				2   {$deviceStr = "Hard Drive"}
				3   {$deviceStr = "PXE Boot"}
			}

			$BootOrderStr = $BootOrderStr + $deviceStr

			If($i -lt ($VSSettingData.BootOrder.length-1)){
				$BootOrderStr = $BootOrderStr + " -> "
			}
		}

		("	Startup order: " + $BootOrderStr) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showMeminfo{
		$VSSettingData = $args[0]
		$MemSettingData = $VSSettingData.GetRelated('Msvm_MemorySettingData')
		("Memory:") | Out-File $Outputfile  -Append -encoding UTF8
		("	Startup RAM: " + $MemSettingData.VirtualQuantity + "MB") | Out-File $Outputfile  -Append -encoding UTF8
		("	Enable Dynamic Memory: " + $MemSettingData.DynamicMemoryEnabled) | Out-File $Outputfile  -Append -encoding UTF8

		If($MemSettingData.DynamicMemoryEnabled){
			("		Minimum RAM: " + $MemSettingData.Reservation + "MB") | Out-File $Outputfile  -Append -encoding UTF8
			("		Maximum RAM: " + $MemSettingData.Limit + "MB") | Out-File $Outputfile  -Append -encoding UTF8
			("		Memory Buffer: " + $MemSettingData.TargetMemoryBuffer) | Out-File $Outputfile  -Append -encoding UTF8
		}

		("	Memory Weight: " + $MemSettingData.Weight) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showCPUinfo{
		$VSSettingData = $args[0]
		$ProcSettingData = $VSSettingData.GetRelated('Msvm_ProcessorSettingData')
		("Processor:") | Out-File $Outputfile  -Append -encoding UTF8
		("	Number of Virtual Processors: " + $ProcSettingData.VirtualQuantity) | Out-File $Outputfile  -Append -encoding UTF8
		("	Resource control: ") | Out-File $Outputfile  -Append -encoding UTF8
		("		Virtual machine reserve: " + $ProcSettingData.Reservation / 1000) | Out-File $Outputfile  -Append -encoding UTF8
		("		Virtual machine limit  : " + $ProcSettingData.Limit / 1000) | Out-File $Outputfile  -Append -encoding UTF8
		("		Relative weight		: " + $ProcSettingData.Weight) | Out-File $Outputfile  -Append -encoding UTF8
		("	Compatibility: ") | Out-File $Outputfile  -Append -encoding UTF8
		("		Migrate to physical computer with a differnet processor version: " + $ProcSettingData.LimitProcessorFeatures) | Out-File $Outputfile  -Append -encoding UTF8
		("	NUMA: ") | Out-File $Outputfile  -Append -encoding UTF8
		("		Maximum number of virtual processors  : " + $ProcSettingData.MaxProcessorsPerNumaNode) | Out-File $Outputfile  -Append -encoding UTF8

		$MemSettingData = $VSSettingData.GetRelated('Msvm_MemorySettingData')
		("		MaxMemoryBlocksPerNumaNode			: " + $MemSettingData.MaxMemoryBlocksPerNumaNode + " MB") | Out-File $Outputfile  -Append -encoding UTF8
		("		Maximum NUMA nodes allowed on a socket: " + $ProcSettingData.MaxNumaNodesPerSocket) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showIDEHardDriveinfo{
		$VM = $args[0]

		("IDE Controller :") | Out-File $Outputfile  -Append -encoding UTF8

		$hardDrives = Get-VMHardDiskDrive -VMName $VM.ElementName | Where-Object {$_.ControllerType -eq "IDE" }

		If($hardDrives.count -eq 0){
			("	No IDE drive attached.") | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8
			return
		}

		ForEach($hardDrive in $hardDrives){
			If($hardDrive.ControllerType -eq "IDE"){
				("	Virtual Hard Disks: ") | Out-File $Outputfile  -Append -encoding UTF8

				If( $hardDrive.Path -eq $null){
					("		WARNING: Disk path is null. Probably the disk is removed or deleted.")  | Out-File $Outputfile  -Append -encoding UTF8
					continue
				}Else{
					("		- " + $hardDrive.Path) | Out-File $Outputfile  -Append -encoding UTF8
					("			Location: " + $hardDrive.Name) | Out-File $Outputfile  -Append -encoding UTF8
				}

				If(!(Test-Path $hardDrive.Path)){
					("		WARNING: the file does not exist.") | Out-File $Outputfile  -Append -encoding UTF8
					continue
				}

				$vhdInfo = Get-VHD -Path $hardDrive.Path
				$property = Get-ChildItem $hardDrive.Path
				$fileSize = [math]::round($property.Length / 1GB , 3)
				$maxFileSize = [math]::round($vhdInfo.Size / 1GB , 3)
				$ACL = Get-ACL $hardDrive.Path

				("			VhdType: " + $vhdInfo.VhdType) | Out-File $Outputfile  -Append -encoding UTF8
				("			Creation time: " + $property.CreationTime + "	" + "Last write time: " + $property.LastWriteTime) | Out-File $Outputfile  -Append -encoding UTF8
				("			Current size: " + $fileSize + " GB" + "  /  Max file size: " + $maxFileSize + " GB") | Out-File $Outputfile  -Append -encoding UTF8
				("			LogicalSectorSize: " + $vhdInfo.LogicalSectorSize + " bytes  /  PhysicalSectorSize: " + $vhdInfo.PhysicalSectorSize + " bytes") | Out-File $Outputfile  -Append -encoding UTF8
				("			Owner: " + $ACL.Owner) | Out-File $Outputfile  -Append -encoding UTF8
				("			ACL: ") | Out-File $Outputfile  -Append -encoding UTF8

				$AccessRules = $ACL.GetAccessRules($true,$true, [System.Security.Principal.NTAccount])

				ForEach($AccessRule in $AccessRules){
					("				" + $AccessRule.IdentityReference + " => " + $AccessRule.FileSystemRights) | Out-File $Outputfile  -Append -encoding UTF8
				}
				("			ID: " + $hardDrive.ID) | Out-File $Outputfile  -Append -encoding UTF8
				("") | Out-File $Outputfile  -Append -encoding UTF8

				### Advanced Features(Windows Server 2012 R2 or later)
				("	Advanced Features:") | Out-File $Outputfile  -Append -encoding UTF8

				$StorageAllocationSettingData = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_StorageAllocationSettingData' | Where-Object { $_.HostResource  -eq $hardDrive.Path}
				
				If($StorageAllocationSettingData.IOPSLimit -eq $null){
					$isStorageQoSEnabled = $false
					$StorageQoSStr = "This feature is supported from Windows Server 2012 R2."
				}ElseIf($StorageAllocationSettingData.IOPSLimit -eq 0){
					$isStorageQoSEnabled = $false
					$StorageQoSStr = "Disabled"
				}Else{
					$isStorageQoSEnabled = $true
					$StorageQoSStr = "Enabled"
				}

				("		Enable Quality of Service management: " + $StorageQoSStr)  | Out-File $Outputfile  -Append -encoding UTF8
	
				If($isStorageQoSEnabled){
					("			Minimum: " + $StorageAllocationSettingData.IOPSReservation) | Out-File $Outputfile  -Append -encoding UTF8
					("			Maximum: " + $StorageAllocationSettingData.IOPSLimit) | Out-File $Outputfile  -Append -encoding UTF8
				}
			}
			("") | Out-File $Outputfile  -Append -encoding UTF8
		}
	}

	Function showSCSIHardDriveinfo{
		$VM = $args[0]
		("SCSI Controller :") | Out-File $Outputfile  -Append -encoding UTF8

		$hardDrives = Get-VMHardDiskDrive -VMName $VM.ElementName | Where-Object {$_.ControllerType -eq "SCSI" }
		If($hardDrives.count -eq 0){
			("	No SCSI drive attached.") | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8
			return
		}

		ForEach($hardDrive in $hardDrives){
			If($hardDrive.ControllerType -eq "SCSI"){
				("	Virtual Hard Disks: ") | Out-File $Outputfile  -Append -encoding UTF8

				If( $hardDrive.Path -eq $null){
					("		WARNING: Disk path is null. Probably the disk is detached or deleted.")  | Out-File $Outputfile  -Append -encoding UTF8
					continue  
				}Else{  
					("		- " + $hardDrive.Path) | Out-File $Outputfile  -Append -encoding UTF8
					("			Location: " + $hardDrive.Name) | Out-File $Outputfile  -Append -encoding UTF8
				}

				If(!(Test-Path $hardDrive.Path)){
					("			WARNING: above file does not exist.") | Out-File $Outputfile  -Append -encoding UTF8
					continue
				}

				$vhdInfo = Get-VHD -Path $hardDrive.Path 
				$property = Get-ChildItem $hardDrive.Path
				$fileSize = [math]::round($property.Length / 1GB , 3)
				$maxFileSize = [math]::round($vhdInfo.Size / 1GB , 3)
				$ACL = Get-ACL $hardDrive.Path			

				("			VhdType: " + $vhdInfo.VhdType) | Out-File $Outputfile  -Append -encoding UTF8
				("			Creation time: " + $property.CreationTime + "	" + "Last write time: " + $property.LastWriteTime) | Out-File $Outputfile  -Append -encoding UTF8
				("			Current size: " + $fileSize + " GB" + "  /  Max file size: " + $maxFileSize + " GB") | Out-File $Outputfile  -Append -encoding UTF8
				("			LogicalSectorSize: " + $vhdInfo.LogicalSectorSize + " bytes  /  PhysicalSectorSize: " + $vhdInfo.PhysicalSectorSize + " bytes") | Out-File $Outputfile  -Append -encoding UTF8
				("			Owner: " + $ACL.Owner) | Out-File $Outputfile  -Append -encoding UTF8
				("			ACL: ") | Out-File $Outputfile  -Append -encoding UTF8

				$AccessRules = $ACL.GetAccessRules($true,$true, [System.Security.Principal.NTAccount])

				ForEach($AccessRule in $AccessRules){
					("				" + $AccessRule.IdentityReference + " => " + $AccessRule.FileSystemRights) | Out-File $Outputfile  -Append -encoding UTF8
				}
				("			ID: " + $hardDrive.ID) | Out-File $Outputfile  -Append -encoding UTF8
				("") | Out-File $Outputfile  -Append -encoding UTF8

				### Advanced Features(Windows Server 2012 R2 or later)
				("	Advanced Features:") | Out-File $Outputfile  -Append -encoding UTF8

				$StorageAllocationSettingData = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_StorageAllocationSettingData' | Where-Object { $_.HostResource  -eq $hardDrive.Path}
				
				# Storage Qos
				If($StorageAllocationSettingData.IOPSLimit -eq $null){
					$isStorageQoSEnabled = $false
					$StorageQoSStr = "This feature is supported from Windows Server 2012 R2."
				}ElseIf($StorageAllocationSettingData.IOPSLimit -eq 0){
					$isStorageQoSEnabled = $false
					$StorageQoSStr = "Disabled"
				}Else{
					$isStorageQoSEnabled = $true
					$StorageQoSStr = "Enabled"
				}

				("		Enable Quality of Service management: " + $StorageQoSStr) | Out-File $Outputfile  -Append -encoding UTF8
	
				If($isStorageQoSEnabled){
					("			Minimum: " + $StorageAllocationSettingData.IOPSReservation) | Out-File $Outputfile  -Append -encoding UTF8
					("			Maximum: " + $StorageAllocationSettingData.IOPSLimit) | Out-File $Outputfile  -Append -encoding UTF8
					("") | Out-File $Outputfile  -Append -encoding UTF8
				}

				# Shared disk support
				If($StorageAllocationSettingData.PersistentReservationsSupported -eq $null){
					$sharedDiskStr = "This feature is supported from Windows Server 2012 R2."
				}ElseIf($StorageAllocationSettingData.PersistentReservationsSupported){
					$sharedDiskStr = "Enabled"
				}Else{
					$sharedDiskStr = "Disabled"
				}
				("		Enable virtual hard disk sharing: " + $sharedDiskStr) | Out-File $Outputfile  -Append -encoding UTF8
			}
			("") | Out-File $Outputfile  -Append -encoding UTF8
		}
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showNetworkAdapterinfo{
		$VSSettingData = $args[0]
		$EthernetPortAllocationSettings = $VSSettingData.GetRelated('Msvm_EthernetPortAllocationSettingData')

		ForEach($EthernetPortAllocationSetting in $EthernetPortAllocationSettings){
			### Get GUID for vSwitch
			$VirtualEthernetSwitch = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_VirtualEthernetSwitch' | Where-Object { $_.__PATH -eq $EthernetPortAllocationSetting.HostResource}

			("Network Adapter :") | Out-File $Outputfile  -Append -encoding UTF8

			If ($VirtualEthernetSwitch -ne $null){
				$switchName = $VirtualEthernetSwitch.ElementName
			}Else{
				$switchName = "Not Connected"
			}
			("	Virtual Switch: " + $switchName) | Out-File $Outputfile  -Append -encoding UTF8

			### VLAN Info
			$EthernetSwitchPortVlanSettingData = $EthernetPortAllocationSetting.GetRelated('Msvm_EthernetSwitchPortVlanSettingData')

			If($EthernetSwitchPortVlanSettingData -ne $NULL){
				switch ($EthernetSwitchPortVlanSettingData.OperationMode){
					0   {$VlanMode = "None(0)"}
					1   {$VlanMode = "Access(1)"}
					2   {$VlanMode = "Trunk(2)"}
					3   {$VlanMode = "Private(3)"}
					default {$VlanMode = "Disabled"}
				}
				("	Enable virtual LAN identification: " + $VlanMode) | Out-File $Outputfile  -Append -encoding UTF8
				("	VLAN ID: " + $EthernetSwitchPortVlanSettingData.AccessVlanId) | Out-File $Outputfile  -Append -encoding UTF8
			}Else{
				("	Enable virtual LAN identification: Disabled") | Out-File $Outputfile  -Append -encoding UTF8
			}
			("") | Out-File $Outputfile  -Append -encoding UTF8

			### Bandwidth Management Info
			$EthernetSwitchPortBandwidthSettingData = $EthernetPortAllocationSetting.GetRelated('Msvm_EthernetSwitchPortBandwidthSettingData')

			("	Bandwitdth Management:") | Out-File $Outputfile  -Append -encoding UTF8

			If($EthernetSwitchPortBandwidthSettingData -ne $NULL){
				("		Enable bandwidth management: True") | Out-File $Outputfile  -Append -encoding UTF8
				("		Minimum bandwidth		  : " + $EthernetSwitchPortBandwidthSettingData.Reservation / 1000000.0 + " Mbps") | Out-File $Outputfile  -Append -encoding UTF8
				("		Maximum bandwidth		  : " + $EthernetSwitchPortBandwidthSettingData.Limit / 1000000.0 + " Mbps") | Out-File $Outputfile  -Append -encoding UTF8
			}Else{
				("		Enable bandwidth management: False") | Out-File $Outputfile  -Append -encoding UTF8
			}
			("") | Out-File $Outputfile  -Append -encoding UTF8

			### Hardware Acceleration
			$EthernetSwitchPortOffloadSettingData = $EthernetPortAllocationSetting.GetRelated('Msvm_EthernetSwitchPortOffloadSettingData')

			("	Hardware Acceleration:") | Out-File $Outputfile  -Append -encoding UTF8

			If($EthernetSwitchPortOffloadSettingData.VMQOffloadWeight -ne 0){
				$VMQEnabled = "True(VMQOffloadWeight=" + $EthernetSwitchPortOffloadSettingData.VMQOffloadWeight +")"
			}Else{
				$VMQEnabled = "False"
			}

			("		Enable virtual machine queue: " +$VMQEnabled) | Out-File $Outputfile  -Append -encoding UTF8

			If($EthernetSwitchPortOffloadSettingData.IPSecOffloadLimit -ne 0){
				$IPSecEnabled = "True(Maximum Number = " + $EthernetSwitchPortOffloadSettingData.IPSecOffloadLimit +" Offloaded SA)"
			}Else{
				$IPSecEnabled = "False"
			}

			("		IPSec task offloading: " +$IPSecEnabled) | Out-File $Outputfile  -Append -encoding UTF8

			If($EthernetSwitchPortOffloadSettingData.IOVOffloadWeight -ne 0){
				$SRIOVEnabled = "True(IOVOffloadWeight = " + $EthernetSwitchPortOffloadSettingData.IOVOffloadWeight + ")"
			}Else{
				$SRIOVEnabled = "False"
			}

			("		Enable SR-IOV: " +$SRIOVEnabled) | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8

			### Failover TCP/IP
			$SyntheticEthernetPortSettings = $VSSettingData.GetRelated('Msvm_SyntheticEthernetPortSettingData')

			# Get Msvm_SyntheticEthernetPortSettingData corresponding to the current Msvm_EthernetPortAllocationSetting
			ForEach($SyntheticEthernetPortSetting in $SyntheticEthernetPortSettings){
				If($EthernetPortAllocationSetting.InstanceID.Contains($SyntheticEthernetPortSetting.InstanceID)){
					$SyntheticPort = $SyntheticEthernetPortSetting
					break
				}
			}

			If($SyntheticPort -eq $null){
				("	WARNING: Failed to retrieve Msvm_SyntheticEthernetPortSettingData.") | Out-File $Outputfile  -Append -encoding UTF8
				("") | Out-File $Outputfile  -Append -encoding UTF8 

				### As Msvm_SyntheticEthernetPortSettingData is not found, we cannot show any info on vNIC.
				return 
			}

			("	Failover TCP/IP: ") | Out-File $Outputfile  -Append -encoding UTF8

			$FailoverNetworkAdapterSettingData = $SyntheticPort.GetRelated('Msvm_FailoverNetworkAdapterSettingData')

			If($FailoverNetworkAdapterSettingData -ne $null){
				If($FailoverNetworkAdapterSettingData.DHCPEnabled){
					("		IPv4/IPv6 TCP/IP Settings: DHCP(No static IP address is specified)") | Out-File $Outputfile  -Append -encoding UTF8
				}Else{
					("		IPv4 TCP/IP Settings:") | Out-File $Outputfile  -Append -encoding UTF8
					("			IPv4 Address   : " + $FailoverNetworkAdapterSettingData.IPAddresses[0]) | Out-File $Outputfile  -Append -encoding UTF8
					("			Subnet mask	: " + $FailoverNetworkAdapterSettingData.Subnets[0]) | Out-File $Outputfile  -Append -encoding UTF8
					("			Default gateway: " + $FailoverNetworkAdapterSettingData.DefaultGateways[0]) | Out-File $Outputfile  -Append -encoding UTF8
					("			Prefferred DNS server: " + $FailoverNetworkAdapterSettingData.DNSServers[0]) | Out-File $Outputfile  -Append -encoding UTF8
					("			Alternate DNS server : " + $FailoverNetworkAdapterSettingData.DNSServers[1]) | Out-File $Outputfile  -Append -encoding UTF8
					("") | Out-File $Outputfile  -Append -encoding UTF8

					If($FailoverNetworkAdapterSettingData.IPAddresses.length -eq 2){
						("		IPv6 TCP/IP Settings:") | Out-File $Outputfile  -Append -encoding UTF8
						("			IPv4 Address   : " + $FailoverNetworkAdapterSettingData.IPAddresses[1]) | Out-File $Outputfile  -Append -encoding UTF8
						("			Subnet mask	: " + $FailoverNetworkAdapterSettingData.Subnets[1]) | Out-File $Outputfile  -Append -encoding UTF8
						("			Default gateway: " + $FailoverNetworkAdapterSettingData.DefaultGateways[1]) | Out-File $Outputfile  -Append -encoding UTF8
						("			Prefferred DNS server: " + $FailoverNetworkAdapterSettingData.DNSServers[2]) | Out-File $Outputfile  -Append -encoding UTF8
						("			Alternate DNS server : " + $FailoverNetworkAdapterSettingData.DNSServers[3]) | Out-File $Outputfile  -Append -encoding UTF8
					}
				}
			}Else{
				("		Hyper-V replica is not configured.") | Out-File $Outputfile  -Append -encoding UTF8
			}

			("") | Out-File $Outputfile  -Append -encoding UTF8

			### Advanced Feature
			("	Advanced Features:") | Out-File $Outputfile  -Append -encoding UTF8

			If($SyntheticPort.StaticMacAddress){
				$MACAddr = "Static (" + $SyntheticPort.address + ")" 
			}Else{
				$MACAddr = "Dynamic (" + $SyntheticPort.address + ")" 

			}

			("		MAC Address: " + $MACAddr) | Out-File $Outputfile  -Append -encoding UTF8

			$EthernetSwitchPortSecuritySettingData = $EthernetPortAllocationSetting.GetRelated('Msvm_EthernetSwitchPortSecuritySettingData')
			
			If($EthernetSwitchPortSecuritySettingData.AllowMacSpoofing -ne $null){
				$MACAddressSpoofing = $EthernetSwitchPortSecuritySettingData.AllowMacSpoofing
			}Else{
				$MACAddressSpoofing = "False"
			}

			("		Enable MAC address spoofing: " + $MACAddressSpoofing) | Out-File $Outputfile  -Append -encoding UTF8

			### DHCP guard
			If($EthernetSwitchPortSecuritySettingData.EnableDhcpGuard -ne $null){
				$DHCPGuard = $EthernetSwitchPortSecuritySettingData.EnableDhcpGuard
			}Else{
				$DHCPGuard = "False"
			}

			("		Enable DHCP guard: " + $DHCPGuard) | Out-File $Outputfile  -Append -encoding UTF8

			### Router guard
			If($EthernetSwitchPortSecuritySettingData.EnableRouterGuard -ne $null){
				$RouterGuard = $EthernetSwitchPortSecuritySettingData.EnableRouterGuard
			}Else{
				$RouterGuard = "False"
			}

			("		Enable router advertisement guard: " + $RouterGuard) | Out-File $Outputfile  -Append -encoding UTF8

			### Port mirroring
			If($EthernetSwitchPortSecuritySettingData.MonitorMode -ne $null){
				switch ($EthernetSwitchPortSecuritySettingData.MonitorMode){
					0   {$MonitorMode = "None (0)"}
					1   {$MonitorMode = "Destination (1)"}
					2   {$MonitorMode = "Source (2)"}
					default {$MonitorMode = "False"}
				}
			}Else{
				$MonitorMode = "False"
			}
			("		Mirrorring mode: " + $MonitorMode) | Out-File $Outputfile  -Append -encoding UTF8

			### Proctected Netowrk(WS2012R2 or later)
			If($SyntheticPort.ClusterMonitored -ne $null){
				("		Protected network: " + $SyntheticPort.ClusterMonitored) | Out-File $Outputfile  -Append -encoding UTF8
			}

			### NIC Teaming
			If($EthernetSwitchPortSecuritySettingData.AllowTeaming -ne $null){
				$AllowTeaming = $EthernetSwitchPortSecuritySettingData.AllowTeaming
			}Else{
				$AllowTeaming = "False"
			}

			("		Enable this network adapter to be partof a team in the guest operating system: " + $AllowTeaming) | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8
		}
	}

	Function showComPortinfo{
		$VM = $args[0]

		$ComPorts = Get-VMComPort -VMName $VM.ElementName

		("COM Port:") | Out-File $Outputfile  -Append -encoding UTF8

		Foreach ($ComPort in $ComPorts){
			("	" + $ComPort.Name + ": " + $ComPort.Path) | Out-File $Outputfile  -Append -encoding UTF8
		}
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showFloppyDriveinfo{
		$VM = $args[0]
		$loppyDrive = Get-VMFloppyDiskDrive -VMName $VM.ElementName
		("Diskette Drive:") | Out-File $Outputfile  -Append -encoding UTF8
		("	Path: " + $floppyDrive.Path) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showICinfo{
		$VSSettingData = $args[0]

		("Integration Services:") | Out-File $Outputfile  -Append -encoding UTF8

		$ShutdownComponentSettingData = $VSSettingData.GetRelated('Msvm_ShutdownComponentSettingData')
		$enabledState = getStateString($ShutdownComponentSettingData.EnabledState)
		("	Operating system shutdown: " + $enabledState) | Out-File $Outputfile  -Append -encoding UTF8

		$TimeSyncComponentSettingData = $VSSettingData.GetRelated('Msvm_TimeSyncComponentSettingData')
		$enabledState = getStateString($TimeSyncComponentSettingData.EnabledState)
		("	Time synchronization	 : " + $enabledState) | Out-File $Outputfile  -Append -encoding UTF8

		$KvpExchangeComponentSettingData = $VSSettingData.GetRelated('Msvm_KvpExchangeComponentSettingData')
		$enabledState = getStateString($KvpExchangeComponentSettingData.EnabledState)
		("	Data Exchange			: " + $enabledState) | Out-File $Outputfile  -Append -encoding UTF8

		$HeartbeatComponentSettingData = $VSSettingData.GetRelated('Msvm_HeartbeatComponentSettingData')
		$enabledState = getStateString($HeartbeatComponentSettingData.EnabledState)
		("	Heartbeat				: " + $enabledState) | Out-File $Outputfile  -Append -encoding UTF8

		### Show heartbeat interval if it is enabled.
		If($HeartbeatComponentSettingData.EnabledState -eq 2){
			("		Interval	  : " + $HeartbeatComponentSettingData.Interval + " ms") | Out-File $Outputfile  -Append -encoding UTF8
			("		Latency	   : " + $HeartbeatComponentSettingData.Latency + " ms") | Out-File $Outputfile  -Append -encoding UTF8
			("		ErrorThreshold: " + $HeartbeatComponentSettingData.ErrorThreshold + " times") | Out-File $Outputfile  -Append -encoding UTF8
		}

		$VssComponentSettingData = $VSSettingData.GetRelated('Msvm_VssComponentSettingData')
		$enabledState = getStateString($VssComponentSettingData.EnabledState)
		("	Backup (volume snapshot) : " + $enabledState) | Out-File $Outputfile  -Append -encoding UTF8

		### Guest service(Windows server 2012 R2 or later)
		$GuestServiceInterfaceComponentSettingData = $VSSettingData.GetRelated('Msvm_GuestServiceInterfaceComponentSettingData')
		$enabledState = getStateString($GuestServiceInterfaceComponentSettingData.EnabledState)
		("	Guest service			: " + $enabledState) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function getStateString{
		$enabledState = $args[0]
		switch ($enabledState){
			2   {$enabledStateStr = "Enabled(2)"}
			3   {$enabledStateStr = "Disabled(3)"}
			default {$enabledStateStr = "Unknown"}
		}
		return $enabledStateStr
	}

	Function showSnapshotFileinfo{
		$VSSettingData = $args[0]
		("Snapshot File Location(File Location for xml):") | Out-File $Outputfile  -Append -encoding UTF8
		("	Path: " + $VSSettingData.SnapshotDataRoot) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showSmartPagingFileinfo{
		$VSSettingData = $args[0]
		("Smart Paging File Location:") | Out-File $Outputfile  -Append -encoding UTF8
		("	Path: " + $VSSettingData.SwapFileDataRoot) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showAutomaticActioninfo{
		$VSSettingData = $args[0]
		("Automatic Start Action:") | Out-File $Outputfile  -Append -encoding UTF8
		switch ($VSSettingData.AutomaticStartupAction){
			2   {$startActionStr = "Nothing(2)"}
			3   {$startActionStr = "Automatically start if it was running when the service stopped(3)"}
			4   {$startActionStr = "Always start this virtual machine automatically(4)"}
			default {$startActionStr = "Unknown"}
		}
		("	Action: " + $startActionStr) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8

		("Automatic Stop Action:") | Out-File $Outputfile  -Append -encoding UTF8
		switch ($VSSettingData.AutomaticShutdownAction){
			2   {$shutdownActionStr = "Turn off the virtual machine(2)"}
			3   {$shutdownActionStr = "Save the virtual machine state(3)"}
			4   {$shutdownActionStr = "Shut down the guest operating system(4)"}
			default {$shutdownActionStr = "Unknown"}
		}
		("	Action: " + $shutdownActionStr) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showSnapshotInfo{
		$VM = $args[0]
		("Snapshot: ") | Out-File $Outputfile  -Append -encoding UTF8
		$Snapshots =  Get-VMSnapshot -VMName $VM.ElementName

		If($Snapshots.length -eq 0){
			("	No snapshots in this VM.") | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8
			return
		}

		("	-----------------------------------------------------") | Out-File $Outputfile  -Append -encoding UTF8

		ForEach($Snapshot in $Snapshots){ 
			$VirtualSystemSettingData = $VM.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.ElementName -eq $Snapshot.Name }

			If($VirtualSystemSettingData.count -gt 1){
				### Sometimes there are two same Msvm_StorageAllocationSettingData. So we get first one. Probably this is a bug...
				$HardDrives = $VirtualSystemSettingData[0].GetRelated('Msvm_StorageAllocationSettingData') 
			}Else{
				$HardDrives = $VirtualSystemSettingData.GetRelated('Msvm_StorageAllocationSettingData') 
			}

			("	Name		 : " + $Snapshot.Name) | Out-File $Outputfile  -Append -encoding UTF8
			("	Type		 : " + $Snapshot.SnapshotType) | Out-File $Outputfile  -Append -encoding UTF8
			("	Creation Time: " + $Snapshot.CreationTime) | Out-File $Outputfile  -Append -encoding UTF8
			("	Parent	   : " + $Snapshot.ParentSnapshotName) | Out-File $Outputfile  -Append -encoding UTF8
			("	File List	: ") | Out-File $Outputfile  -Append -encoding UTF8

			If($HardDrives -eq $null){
				continue  # No drives attached to this snapshot.
			}

			# Get ACL and file property.
			ForEach($HardDrive in $HardDrives){
				If(($HardDrive.HostResource[0]).Contains("vhd")){
					("		- " + $HardDrive.HostResource) | Out-File $Outputfile  -Append -encoding UTF8
				}Else{
					continue  ### Probably physical drive or ISO file
				}

				If(!(Test-Path $HardDrive.HostResource)){
					("			!!! WARNING: above file does not exist !!!") | Out-File $Outputfile  -Append -encoding UTF8
					continue
				}

				$vhdInfo = Get-VHD -Path $HardDrive.HostResource[0] 
				$property = Get-ChildItem $HardDrive.HostResource[0]
				$fileSize = [math]::round($property.Length / 1GB , 3)
				$maxFileSize = [math]::round($vhdInfo.Size / 1GB , 3)
				$ACL = Get-ACL $HardDrive.HostResource[0]			

				("			VhdType: " + $vhdInfo.VhdType) | Out-File $Outputfile  -Append -encoding UTF8
				("			Creation time: " + $property.CreationTime + "	" + "Last write time: " + $property.LastWriteTime) | Out-File $Outputfile  -Append -encoding UTF8
				("			Current size: " + $fileSize + " GB" + "  /  Max file size: " + $maxFileSize + " GB") | Out-File $Outputfile  -Append -encoding UTF8
				("			LogicalSectorSize: " + $vhdInfo.LogicalSectorSize + " bytes  /  PhysicalSectorSize: " + $vhdInfo.PhysicalSectorSize + " bytes") | Out-File $Outputfile  -Append -encoding UTF8
				("			Owner: " + $ACL.Owner) | Out-File $Outputfile  -Append -encoding UTF8
				("			ACL: ") | Out-File $Outputfile  -Append -encoding UTF8

				$AccessRules = $ACL.GetAccessRules($true,$true, [System.Security.Principal.NTAccount])

				ForEach($AccessRule in $AccessRules){
					("				" + $AccessRule.IdentityReference + " => " + $AccessRule.FileSystemRights) | Out-File $Outputfile  -Append -encoding UTF8
				}
			}
			("	-----------------------------------------------------") | Out-File $Outputfile  -Append -encoding UTF8
		}
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showReplicationinfo{
		$VM = $args[0]
		$VirtualSystemSettingData = $VM.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }

		switch ($VM.ReplicationState)		{
			0   {$ReplicationState = "Disabled"}
			1   {$ReplicationState = "Ready for replication"}
			2   {$ReplicationState = "Waiting to complete initial replication"}
			3   {$ReplicationState = "Replicating"}
			4   {$ReplicationState = "Synced replication complete"}
			5   {$ReplicationState = "Recovered"}
			6   {$ReplicationState = "Committed"}
			7   {$ReplicationState = "Suspended"}
			8   {$ReplicationState = "Critical"}
			9   {$ReplicationState = "Waiting to start resynchronization"}
			10   {$ReplicationState = "Resynchronizing"}
			11   {$ReplicationState = "Resynchronization suspended"}
			12   {$ReplicationState = "Failover in progress"}
			13   {$ReplicationState = "Failback in progress"}
			14   {$ReplicationState = "Failback complete"}
		}

		switch ($VM.FailedOverReplicationType){
			0   {$FailedOverReplicationType = "None"}
			1   {$FailedOverReplicationType = "Regular"}
			2   {$FailedOverReplicationType = "Application consistent"}
			3   {$FailedOverReplicationType = "Planned"}
		}

		switch ($VM.ReplicationHealth){
			0   {$ReplicationHealth = "Not applicable"}
			1   {$ReplicationHealth = "Ok"}
			2   {$ReplicationHealth = "Warning"}
			3   {$ReplicationHealth = "Critical"}
		}

		switch ($VM.ReplicationMode){
			0   {$ReplicationMode = "None"}
			1   {$ReplicationMode = "Primary"}
			2   {$ReplicationMode = "Recovery"}
			3   {$ReplicationMode = "Replica"}
			4   {$ReplicationMode = "Extended Replica"}
		}

		### Sometimes there are two same Msvm_ReplicationSettingData. So we get first one. 
		$ReplicationSettingData = $VM.GetRelated('Msvm_ReplicationSettingData') | Select-Object -first 1

		switch ($ReplicationSettingData.AuthenticationType){
			1   {$AuthenticationType = "Kerberos authentication"}
			2   {$AuthenticationType = "Certificate based authentication"}
		}

		$HVRConfiRoot = $VirtualSystemSettingData.ConfigurationDataRoot.ToString()
		$HVRConfigFile = $VirtualSystemSettingData.ConfigurationFile.ToString()
		$VHD = get-vhd -vmid $VM.Name

		If($ReplicationSettingData.ReplicationInterval -eq $null){
			$ReplicationInterval = 300
		}Else{
			$ReplicationInterval = $ReplicationSettingData.ReplicationInterval
		}

		("Replication:") | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
		("	Replication:") | Out-File $Outputfile  -Append -encoding UTF8
		("		This virtual machinge is configured as " + $ReplicationMode + " virtual machine.") | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
		("		Port on the Replica server  : " + $ReplicationSettingData.RecoveryServerPortNumber) | Out-File $Outputfile  -Append -encoding UTF8
		("		Authentication Type		 : " + $AuthenticationType) | Out-File $Outputfile  -Append -encoding UTF8
		("		Compression the data that is transmitted over the network: " + $ReplicationSettingData.CompressionEnabled) | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8
		("	Recovery Points:") | Out-File $Outputfile  -Append -encoding UTF8

		If($ReplicationSettingData.RecoveryHistory -eq 0){
			("		Only the latest point for recovery") | Out-File $Outputfile  -Append -encoding UTF8
		}Else{
			("		Additional recovery points") | Out-File $Outputfile  -Append -encoding UTF8
			("			Number of recovery point: " + $ReplicationSettingData.RecoveryHistory) | Out-File $Outputfile  -Append -encoding UTF8

			$isVssReplicaEnabled = $True
			If($ReplicationSettingData.ApplicationConsistentSnapshotInterval -eq 0)
			{
				$isVssReplicaEnabled = $False
			}

			("		Application consistent replication: " + $isVssReplicaEnabled) | Out-File $Outputfile  -Append -encoding UTF8

			If($isVssReplicaEnabled){
				("		Replicate incremental VSS copy every: "  + $ReplicationSettingData.ApplicationConsistentSnapshotInterval + " hour(s)") | Out-File $Outputfile  -Append -encoding UTF8
			}
		}

		### Windows Server 2012 R2 or later
		### We don't show resync setting if it is RecoveryVM as it is not available.
		If($VM.ReplicationMode -eq 1){
			("") | Out-File $Outputfile  -Append -encoding UTF8
			("	Resynchronization:") | Out-File $Outputfile  -Append -encoding UTF8

			$resyncIntervalEnd = [System.Management.ManagementDateTimeConverter]::Totimespan($ReplicationSettingData.AutoResynchronizeIntervalEnd)
			$resyncIntervalStart = [System.Management.ManagementDateTimeConverter]::Totimespan($ReplicationSettingData.AutoResynchronizeIntervalStart)
			$oneSecond = New-TimeSpan -Seconds 1
			$endPlusOneSec = $resyncIntervalEnd + $oneSecond

			If($ReplicationSettingData.AutoResynchronizeEnabled){
				If(($resyncIntervalStart.Hours -eq $endPlusOneSec.Hours) -and ($resyncIntervalStart.Minutes -eq $endPlusOneSec.Minutes) -and ($resyncIntervalStart.Seconds -eq $endPlusOneSec.Seconds)){
					("		Automatically start resynchronization") | Out-File $Outputfile  -Append -encoding UTF8
				}Else{
					("		Automatically start resynchronization only during the follwing hours:") | Out-File $Outputfile  -Append -encoding UTF8
					("			From: " + $resyncIntervalStart.Hours.ToString("00") + $resyncIntervalStart.Minutes.ToString("\:00")) | Out-File $Outputfile  -Append -encoding UTF8
					("			  To: " + $resyncIntervalEnd.Hours.ToString("00") + $resyncIntervalEnd.Minutes.ToString("\:00")) | Out-File $Outputfile  -Append -encoding UTF8
				}
			}Else{
				("		Manually") | Out-File $Outputfile  -Append -encoding UTF8
			}
		}

		("") | Out-File $Outputfile  -Append -encoding UTF8
		("	Other replication info: ") | Out-File $Outputfile  -Append -encoding UTF8
		("		VM GUID					 : " + $VM.Name) | Out-File $Outputfile  -Append -encoding UTF8
		("		Configuration file		  : " + $HVRConfiRoot + "\" + $HVRConfigFile) | Out-File $Outputfile  -Append -encoding UTF8
		("		Included VHD files		  : ") | Out-File $Outputfile  -Append -encoding UTF8

		ForEach($includedDisk in $ReplicationSettingData.IncludedDisks){
			("			- " + $includedDisk) | Out-File $Outputfile  -Append -encoding UTF8
		}

		("		Primary server			  : " + $ReplicationSettingData.PrimaryHostSystem) | Out-File $Outputfile  -Append -encoding UTF8
		("		Primary connection point	: " + $ReplicationSettingData.PrimaryConnectionPoint) | Out-File $Outputfile  -Append -encoding UTF8
		("		Replica server			  : " + $ReplicationSettingData.RecoveryHostSystem) | Out-File $Outputfile  -Append -encoding UTF8
		("		Replication interval		: " + $ReplicationInterval + " seconds") | Out-File $Outputfile  -Append -encoding UTF8
		("		ReplicationHealth		   : " + $ReplicationHealth) | Out-File $Outputfile  -Append -encoding UTF8
		("		ReplicationMode			 : " + $ReplicationMode) | Out-File $Outputfile  -Append -encoding UTF8
		("		ReplicationState			: " + $ReplicationState) | Out-File $Outputfile  -Append -encoding UTF8
		("		Last update time			: " + $VM.LastReplicationTime) | Out-File $Outputfile  -Append -encoding UTF8
		("		Last update time(VSS)	   : " + $VM.LastApplicationConsistentReplicationTime) | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function showHVFileVersion{
		$system32Files = dir "C:\Windows\System32\vm*"
		$hypervisorFiles = dir "C:\Windows\System32\hv*"
		$driversFiles = dir "C:\Windows\System32\drivers\vm*"
		$fileArray = ($system32Files, $driversFiles, $hypervisorFiles)
		("File version:") | Out-File $Outputfile  -Append -encoding UTF8
		ForEach($files in $fileArray){
			ForEach($file in $files){
				$ext = (Get-ChildItem $File).get_Extension()

				If($ext -ne ".dll" -and $ext -ne ".sys" -and $ext -ne ".exe"){
					continue
				}

				("	" + $file.Name + "	" + $file.VersionInfo.FileVersion) | Out-File $Outputfile  -Append -encoding UTF8
			}
		}
		("") | Out-File $Outputfile  -Append -encoding UTF8
	}

	Function getVmGeneration{
		$VSSettingData = $args[0]
		If($VSSettingData.VirtualSystemSubType -eq $null) ### WS2012
		{
			$vmGgeneration = "1"
		}
		Else ### WS2012R2 or later
		{
			$subType = $VSSettingData.VirtualSystemSubType.split(":")
			$vmGgeneration = $subType[3]
		}
		return $vmGgeneration
	}

	Function getHeartBeatInfo{
		$heartbeatComponent = $args[0]
		If ( $heartbeatComponent.StatusDescriptions -ne $null ){
			$heartbeat = $HeartbeatComponent.OperationalStatus[0]
			$strhbPrimaryStatus = getHBOperationalStatus($heartbeat)
		}
	}

	Function getVMEnabledState{
		$vmStatus = $args[0]

		# http://msdn.microsoft.com/en-us/library/hh850116(v=vs.85).aspx
		switch ($vmStatus){
			0   {$EnabledState = "Unknown"}
			1   {$EnabledState = "Other"}
			2   {$EnabledState = "Running(Enabled - 2)"}
			3   {$EnabledState = "Off(Disabled - 3)"}
			4   {$EnabledState = "Shutting down(4)"}
			5   {$EnabledState = "Not Applicable(5)"}
			6   {$EnabledState = "Saved(Enabled but Offline - 6)"}
			7   {$EnabledState = "In Test(7)"}
			8   {$EnabledState = "Deferred(8)"}
			9   {$EnabledState = "Quiesce(9)"}
			10   {$EnabledState = "Starting(10)"}
		}
		return $EnabledState
	}

	Function getHBOperationalStatus{
		$hbStatus = $args[0]

		# http://msdn.microsoft.com/en-us/library/hh850157(v=vs.85).aspx
		switch ($hbStatus){
			2   {$hbPrimaryStatus = "OK"}
			3   {$hbPrimaryStatus = "Degraded"}
			7   {$hbPrimaryStatus = "Non-Recoverable Error"}
			12   {$hbPrimaryStatus = "No Contact"}
			13   {$hbPrimaryStatus = "Lost Communication"}
			15   {$hbPrimaryStatus = "Paused"}
		default {$hbPrimaryStatus = "N/A"}
		}
		return $hbPrimaryStatus
	}

	Function getHBSecondaryStatus{
		$hbStatus2 = $args[0]

		# http://msdn.microsoft.com/en-us/library/hh850157(v=vs.85).aspx
		switch ($hbStatus2){
				2   {$hbSecondaryStatus = "OK"}
			32775   {$hbSecondaryStatus = "Protocol Mismatch"}
			32782   {$hbSecondaryStatus = "Application Critical State"}
			32783   {$hbSecondaryStatus = "Communication Timed Out"}
			32784   {$hbSecondaryStatus = "Communication Failed"}
			default {$hbSecondaryStatus = "N/A"}
		}
		return $hbSecondaryStatus
	}

	Get-Date | Out-File $Outputfile -encoding UTF8
	$osVersion = [environment]::OSVersion.Version
	$TestPath = Test-Path "C:\Windows\System32\vmms.exe"
	If (($TestPath -eq $False) -or ($osVersion.Build -lt 9200)){
		"Hyper-V basic information cannot be collected on this system."  | WriteTo-StdOut
		"Hyper-V is installed: $TestPath"  | WriteTo-StdOut
		"OS version is build $OSVersion"  | WriteTo-StdOut
	}Else{
		$hostName = hostname
		$VMs = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -ne $hostName}
		$VSMgtServiceSettingData = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_VirtualSystemManagementServiceSettingData'

		showHVGlobalSettings $VSMgtServiceSettingData
		showNUMAinfo
		
		("Virtual Machine Settings") | Out-File $Outputfile  -Append -encoding UTF8
		("----------------------------------------") | Out-File $Outputfile  -Append -encoding UTF8
		("") | Out-File $Outputfile  -Append -encoding UTF8 
		
		ForEach ($VM in $VMs){
			$VirtualSystemSettingData = $VM.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }
			
			("<<<<<<<<<< " + $VM.elementName + " >>>>>>>>>>") | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8
			
			showVMBasicinfo $VM $VirtualSystemSettingData
			
			### Hyper-V UI settings
			showBIOSinfo $VirtualSystemSettingData
			showMeminfo $VirtualSystemSettingData
			showCPUinfo $VirtualSystemSettingData
			
			# We don't get IDE info in case of Gen2VM as IDE does not exist.
			$vmGeneration = getVmGeneration $VirtualSystemSettingData
			If($vmGeneration -eq "1"){
				showIDEHardDriveinfo $VM
			}

			showSCSIHardDriveinfo $VM
			showNetworkAdapterinfo $VirtualSystemSettingData
			showComPortinfo $VM 

			If($vmGeneration -eq "1"){
				showFloppyDriveinfo $VM
			}

			showICinfo $VirtualSystemSettingData
			showSnapshotFileinfo $VirtualSystemSettingData
			showSmartPagingFileinfo $VirtualSystemSettingData
			showAutomaticActioninfo $VirtualSystemSettingData

			### Additional info
			showSnapshotInfo $VM
			showKVPItems $VM $VirtualSystemSettingData

			# Get replication info if it is enabled
			if ($VM.ReplicationState -ne 0){
				("Detected Hyper-V replica enabled...") | Out-File $Outputfile  -Append -encoding UTF8
				("") | Out-File $Outputfile  -Append -encoding UTF8
				showReplicationinfo $VM
			}

			("") | Out-File $Outputfile  -Append -encoding UTF8
			("================================================================================") | Out-File $Outputfile  -Append -encoding UTF8
			("") | Out-File $Outputfile  -Append -encoding UTF8

		}
		showHVFileVersion
	}
	EndFunc $MyInvocation.MyCommand.Name
}


function CollectSHA_support-iscsiLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\iscsi"
	FwCreateFolder $LogFolder
	$Commands = @(
		"iscsicli.exe ListInitiators | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ListInitiators.txt",
		"iscsicli.exe ListTargetPortals | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ListTargetPortals.txt",
		"iscsicli.exe SessionList | Out-File ${LogFolder}\${Env:COMPUTERNAME}_SessionList.txt",
		"iscsicli.exe ListPersistentTargets | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ListPersistentTargets.txt",
		"iscsicli.exe ReportTargetMappings | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ReportTargetMappings.txt",
		"iscsicli.exe ListiSNSServers | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ListiSNSServers.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-networkLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\network"
	FwCreateFolder $LogFolder
	FwCreateFolder "${LogFolder}\etc"
	$Commands = @(
		"arp -a | Out-File ${LogFolder}\${Env:COMPUTERNAME}_arp.txt",
		"ipconfig /all | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipconfig-all.txt",
		"ipconfig /displaydns | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipconfig-displaydns.txt",
		"netstat -ano | Out-File ${LogFolder}\${Env:COMPUTERNAME}_netstat.txt",	
		"netsh advfirewall monitor show consec | Out-File ${LogFolder}\${Env:COMPUTERNAME}_advfirewall_consec.txt",
		"netsh advfirewall monitor show mmsa | Out-File ${LogFolder}\${Env:COMPUTERNAME}_advfirewall_mmsa.txt",
		"netsh advfirewall monitor show qmsa | Out-File ${LogFolder}\${Env:COMPUTERNAME}_advfirewall_qmsa.txt",
		"netsh advfirewall monitor show firewall | Out-File ${LogFolder}\${Env:COMPUTERNAME}_advfirewall_firewall.txt",
		"netsh advfirewall show store | Out-File ${LogFolder}\${Env:COMPUTERNAME}_advfirewall_store.txt",
		"netsh int ipv4 show dynamicport tcp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv4-dynamicport-tcp.txt",
		"netsh int ipv4 show dynamicport udp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv4-dynamicport-udp.txt",
		"netsh int ipv6 show dynamicport tcp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv6-dynamicport-tcp.txt",
		"netsh int ipv6 show dynamicport udp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv6-dynamicport-udp.txt",
		"netsh int ipv4 show excludedportrange tcp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv4-excludedportrange-tcp.txt",
		"netsh int ipv4 show excludedportrange udp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv4-excludedportrange-udp.txt",
		"netsh int ipv6 show excludedportrange tcp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv6-excludedportrange-udp.txt",
		"netsh int ipv6 show excludedportrange udp | Out-File ${LogFolder}\${Env:COMPUTERNAME}_ipv6-excludedportrange-tcp.txt",
		"netsh interface tcp show global | Out-File ${LogFolder}\${Env:COMPUTERNAME}_interface-tcp-show-global.txt",
		"netsh winhttp show proxy | Out-File ${LogFolder}\${Env:COMPUTERNAME}_WinHTTPProxy.txt",
		"route print | Out-File ${LogFolder}\${Env:COMPUTERNAME}_route-print.txt",
		"xcopy /s C:\Windows\System32\drivers\etc\* ${LogFolder}\etc",
		"Get-DnsClientCache | ft -AutoSize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-DnsClientCache.txt",
		"Get-DnsClientGlobalSetting | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-DnsClientGlobalSetting.txt",
		"Get-NetAdapter | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapter.txt",
		"Get-NetAdapterAdvancedProperty | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterAdvancedProperty.txt",
		"Get-NetAdapterBinding | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterBinding.txt",
		"Get-NetAdapterChecksumOffload | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterChecksumOffload.txt",
		"Get-NetAdapterHardwareInfo | ft -AutoSize -wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterHardwareInfo.txt",
		"Get-NetAdapterIPsecOffload | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterIPsecOffload.txt",
		"Get-NetAdapterLso | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterLso.txt",
		"Get-NetAdapterPacketDirect | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterPacketDirect.txt",
		"Get-NetAdapterRdma | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterRdma.txt",
		"Get-NetAdapterRsc | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterRsc.txt",
		"Get-NetAdapterRss | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterRss.txt",
		"Get-NetAdapterVMQ | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterVMQ.txt",
		"Get-NetAdapterVMQqueue | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetAdapterVMQqueue.txt",
		"Get-NetConnectionProfile | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetConnectionProfile.txt",
		"Get-NetIpAddress | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetIpAddress.txt",
		"Get-NetIPv4Protocol | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetIPv4Protocol.txt",
		"Get-NetIPv6Protocol | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetIPv6Protocol.txt",
		"Get-NetLbfoTeam | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetLbfoTeam.txt",
		"Get-NetLbfoTeamMember | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetLbfoTeamMember.txt",
		"Get-NetLbfoTeamNic | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetLbfoTeamNic.txt",
		"Get-NetNeighbor | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetNeighbor.txt",
		"Get-NetOffloadGlobalSetting | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetOffloadGlobalSetting.txt",
		"Get-NetPrefixPolicy | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetPrefixPolicy.txt",
		"Get-NetQosPolicy | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetQosPolicy.txt",
		"Get-NetRoute | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetRoute.txt",
		"Get-NetTcpConnection | ft -Autosize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetTcpConnection.txt",
		"Get-NetTcpSetting | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetTcpSetting.txt",
		"Get-NetFirewallProfile | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetFirewallProfile.txt",
		"Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Machine_WinInetProxy.txt",
		"Get-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Machine_Policies_WinInetProxy.txt",
		"Get-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_User_Policies_WinInetProxy.txt.txt",
		"Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_User_WinInetProxy.txt",
		"Get-SmbConnection | ft -AutoSize -wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SmbConnection.txt",
		"Get-SmbClientConfiguration | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SmbClientConfiguration.txt",
		"Get-SmbClientNetworkInterface | ft -AutoSize -wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SmbClientNetworkInterface.txt",
		"Get-VMNetworkAdapterIsolation -ManagementOS | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMNetworkAdapterIsolation.txt",
		"Get-VMNetworkAdapterTeamMapping -ManagementOS | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMNetworkAdapterTeamMapping.txt",
		"Get-VMNetworkAdapterVlan | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMNetworkAdapterVlan.txt",
		"Get-VMSwitchTeam | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMSwitchTeam.txt",
		"Show-NetFirewallRule | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Show-NetFirewallRule.txt"
	)
 
	If($IsServerSKU){
		if ((Get-WindowsFeature -Name NetworkATC).installed -eq $true) {
			Get-NetIntentStatus | ft IntentName,Host,IsComputeIntentSet,IsManagementIntentSet,IsStorageIntentSet,IsStretchIntentSet,ConfigurationStatus,ProvisioningStatus | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetIntentStatus-summary.txt
			Get-NetIntentStatus | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetIntentStatus-all.txt
			Get-NetIntent | ft IntentName,Scope,NetAdapterNamesAsList,IsComputeIntentSet,IsStorageIntentSet,IsOnlyStorage,IsManagementIntentSet,IsNetworkIntentType | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetIntent-summary.txt
			Get-NetIntent | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-NetIntent-all.txt
		}
	}

	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-registryLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\registry"
	FwCreateFolder $LogFolder
	$Commands = @(
		"reg save HKLM\HARDWARE\DEVICEMAP ${LogFolder}\${Env:COMPUTERNAME}_HKLM_HARDWARE_devicemap.hiv",
		"reg save HKLM\HARDWARE\DESCRIPTION ${LogFolder}\${Env:COMPUTERNAME}_HKLM_HARDWARE_DESCRIPTION.hiv",
		"reg save HKLM\Software ${LogFolder}\${Env:COMPUTERNAME}_HKLM_Software.hiv",
		"reg load HKLM\COMPONENTS C:\Windows\System32\config\components",
		"reg save HKLM\COMPONENTS ${LogFolder}\${Env:COMPUTERNAME}_HKLM_COMPONENTS.hiv",
		"reg save HKLM\System\mounteddevices ${LogFolder}\${Env:COMPUTERNAME}_HKLM_System_MountedDevices.hiv",
		"reg save HKLM\SYSTEM\CurrentControlSet ${LogFolder}\${Env:COMPUTERNAME}_HKLM_SYSTEM_CurrentControlSet.hiv",
		"reg save HKLM\SYSTEM\DriverDatabase ${LogFolder}\${Env:COMPUTERNAME}_HKLM_DriverDatabase.hiv",
		"reg save HKEY_CLASSES_ROOT\CID ${LogFolder}\${Env:COMPUTERNAME}_HKCL_cid.hiv",
		"reg save HKEY_CLASSES_ROOT\CID.local ${LogFolder}\${Env:COMPUTERNAME}_HKCL_cid-local.hiv",
		"reg save HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy ${LogFolder}\${Env:COMPUTERNAME}_HKCU_Software_PStorageSense.hiv",
		"reg save HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense ${LogFolder}\${Env:COMPUTERNAME}_HKLM_Software_Policies_StorageSenseGPO.hiv",
		"reg export HKLM\System\mounteddevices ${LogFolder}\${Env:COMPUTERNAME}_HKLM_System_MountedDevices.reg",
		"reg export HKLM\HARDWARE\DEVICEMAP ${LogFolder}\${Env:COMPUTERNAME}_HKLM_HARDWARE_devicemap.reg",
		"reg export HKLM\HARDWARE\DESCRIPTION ${LogFolder}\${Env:COMPUTERNAME}_HKLM_HARDWARE_DESCRIPTION.reg",
		"reg export HKLM\Software\Policies ${LogFolder}\${Env:COMPUTERNAME}_HKLM_ComputerPolicies.reg",
		"reg export HKCU\Software\Policies ${LogFolder}\${Env:COMPUTERNAME}_HKCU_UserPolicies.reg",
		"reg export HKLM\COMPONENTS ${LogFolder}\${Env:COMPUTERNAME}_HKLM_COMPONENTS.reg",
		"reg export HKLM\SYSTEM\CurrentControlSet ${LogFolder}\${Env:COMPUTERNAME}_HKLM_SYSTEM_CurrentControlSet.reg",
		"reg export HKEY_CLASSES_ROOT\CID ${LogFolder}\${Env:COMPUTERNAME}_HKCL_cid.reg",
		"reg export HKEY_CLASSES_ROOT\CID.local ${LogFolder}\${Env:COMPUTERNAME}_HKCL_cid-local.reg",
		"reg export HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft ${LogFolder}\${Env:COMPUTERNAME}_HKLM_SOFTWARE_Microsoft.reg",
		"reg export HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy ${LogFolder}\${Env:COMPUTERNAME}_HKCU_Software_Policies_StorageSense.reg",
		"reg export HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense ${LogFolder}\${Env:COMPUTERNAME}_HKLM_Software_PStorageSenseGPO.reg"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-setupLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\setup"
	$LogFolderCBS = "$LogFolder\CBS"
	$LogFolderDISM = "$LogFolder\DISM"
	$LogFolderWindowsServerBackup = "$LogFolder\WindowsServerBackup"
	$LogFolderWindowsBackup = "$LogFolder\WindowsBackup"
	$LogFoldersetupcln = "$LogFolder\setupcln"
	$LogFolderUSOSharedLogs = "$LogFolder\USOSharedLogs"
	FwCreateFolder $LogFolder
	FwCreateFolder $LogFolderCBS
	FwCreateFolder $LogFolderDISM
	FwCreateFolder $LogFolderWindowsServerBackup
	FwCreateFolder $LogFolderWindowsBackup
	FwCreateFolder $LogFoldersetupcln
	FwCreateFolder $LogFolderUSOSharedLogs
	$Commands = @(
		"Get-CimInstance Win32_QuickFixEngineering | Select-Object * | Sort-Object -Property InstalledOn | Format-Table -AutoSize -Wrap | Out-File ${LogFolder}\${Env:COMPUTERNAME}_qfe.txt",
		"Get-HotFix | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-hotfix.log",
		"xcopy /s /e /c C:\Windows\Logs\CBS\* $LogFolderCBS",
		"xcopy /s /e /c C:\Windows\Logs\DISM\* $LogFolderDISM",
		"xcopy /s /e /c C:\Windows\Logs\WindowsServerBackup\* $LogFolderWindowsServerBackup",
		"xcopy /s /e /c C:\Windows\Logs\WindowsBackup\* $LogFolderWindowsBackup",
		"xcopy /s /e /c C:\Windows\System32\LogFiles\setupcln\* $LogFoldersetupcln",
		"Copy C:\Windows\WindowsUpdate.log $LogFolder",
		"Copy C:\Windows\SoftwareDistribution\ReportingEvents.log $LogFolder",
		"Copy C:\Windows\IE11_main.log $LogFolder",
		"Copy C:\Windows\inf\setupapi.* $LogFolder",
		"Copy C:\Windows\WinSXS\pending.xml.* $LogFolder",
		"Copy C:\Windows\WinSXS\poqexec.log $LogFolder",
		"Copy C:\Windows\System32\LogFiles\SCM\*.EVM*  $LogFolder",
		"xcopy /s /e /c C:\ProgramData\USOShared\Logs $LogFolderUSOSharedLogs",
		"BitsAdmin /list /AllUsers /Verbose | Out-File ${LogFolder}\${Env:COMPUTERNAME}_BitsAdmin.log",
		"cmd /c 'dir /t:c /a /s /c /n C:\' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_dir-Windows.log",
		"bcdedit /enum all | Out-File ${LogFolder}\${Env:COMPUTERNAME}_BCDedit.log",
		"dism /Online /Get-intl | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get_intl.log",
		"dism /Online /Get-Packages /Format:Table | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-Packages.log",
		"dism /Online /Get-Features /Format:Table | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-Features.log",
		"icacls C:\ | Out-File ${LogFolder}\${Env:COMPUTERNAME}_c-driveicacls.log",
		"icacls %SystemRoot%\System32\config /t /c | Out-File ${LogFolder}\${Env:COMPUTERNAME}_configicacls.log",
		"icacls %SystemRoot%\inf /t /c | Out-File ${LogFolder}\${Env:COMPUTERNAME}_inficacls.log",
		"icacls %SystemRoot%\SoftwareDistribution /t /c | Out-File ${LogFolder}\${Env:COMPUTERNAME}_SoftwareDistributionicacls.log",
		"icacls C:\Windows\winsxs\catalogs /t /c  | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Winsxsicacls.log",
		"cmd /c 'sc queryex' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_sc_queryex.log",
		"cmd /c 'sc sdshow TrustedInstaller' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_TrustedInstaller_sdshow.log",
		"cmd /c 'sc sdshow wuauserv' | Out-File ${LogFolder}\${Env:COMPUTERNAME}_wuauserv_sdshow.log",
		"cscript c:\windows\system32\slmgr.vbs /dlv | Out-File ${LogFolder}\${Env:COMPUTERNAME}_slmgr_dlv.log"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-storagereplicaLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\storagereplica"
	FwCreateFolder $LogFolder
	$Commands = @(
		"Get-SRGroup | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SRGroup.txt",
		"(Get-SRGroup).replicas | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SRGroup-replicas.txt",
		"Get-SRAccess | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SRAccess.txt",
		"Get-SRNetworkConstraint | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SRNetworkConstraint.txt",
		"Get-SRPartnership | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-SRPartnership.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-systemLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\system"
	FwCreateFolder $LogFolder
	$Commands = @(
		"klist | Out-File ${LogFolder}\${Env:COMPUTERNAME}_klist.txt",
		"Nltest /SC_VERIFY:$env:USERDNSDomain | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Nltest.txt",
		"systeminfo | Out-File ${LogFolder}\${Env:COMPUTERNAME}_systeminfo.txt",
		"Get-CimInstance Win32_Product | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Win32_Product.txt",
		"verifier /query | Out-File ${LogFolder}\${Env:COMPUTERNAME}_verifier-query.txt",
		"verifier /querysettings | Out-File ${LogFolder}\${Env:COMPUTERNAME}_verifier-querysettings.txt",
		"tasklist | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklist.txt",
		"tasklist /M | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklist-M.txt",
		"tasklist /SVC | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklist-SVC.txt",
		"Get-Process | Format-Table -Property Handles,NPM,PM,WS,VM,CPU,Id,ProcessName,StartTime,@{ Label = 'Running Time';Expression={(GetAgeDescription -TimeSpan (new-TimeSpan $_.StartTime))}} -AutoSize | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-process.txt",
		"Get-MpPreference | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_defender_config.txt",
		"gpresult /H ${LogFolder}\${Env:COMPUTERNAME}_gpresult.html",
		"$global:ScriptFolder\BIN\Coreinfo.exe -accepteula | Out-File ${LogFolder}\${Env:COMPUTERNAME}_coreinfo.txt",
		"$global:ScriptFolder\BIN\Coreinfo.exe -accepteula -v | Out-File ${LogFolder}\${Env:COMPUTERNAME}_coreinfo-v.txt",
		"w32tm /query /status /verbose | Out-File ${LogFolder}\${Env:COMPUTERNAME}_w32tm-status.txt",
		"w32tm /query /configuration /verbose | Out-File ${LogFolder}\${Env:COMPUTERNAME}_w32tm-config.txt",
		"w32tm /query /peers | Out-File ${LogFolder}\${Env:COMPUTERNAME}_w32tm-peers.txt",
		"pnputil.exe /export-pnpstate ${LogFolder}\${Env:COMPUTERNAME}_pnpstate.pnp",
		"cscript c:\Windows\system32\slmgr.vbs /dlv c0a2ea62-12ad-435b-ab4f-c9bfab48dbc4 | Out-File ${LogFolder}\${Env:COMPUTERNAME}_2012_ESU_Year1.txt",
		"cscript c:\Windows\system32\slmgr.vbs /dlv e3e2690b-931c-4c80-b1ff-dffba8a81988 | Out-File ${LogFolder}\${Env:COMPUTERNAME}_2012_ESU_Year2.txt",
		"cscript c:\Windows\system32\slmgr.vbs /dlv 55b1dd2d-2209-4ea0-a805-06298bad25b3 | Out-File ${LogFolder}\${Env:COMPUTERNAME}_2012_ESU_Year3.txt",
		"msinfo32 /nfo ${LogFolder}\${Env:COMPUTERNAME}_msinfo32.nfo"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True

	If($IsServerSKU){
		Get-WindowsFeature | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-WindowsFeature.txt
	}

	Wait-Process msinfo32 -Timeout 600
	$Process = Get-Process msinfo32 2>$null
	if($Process){
		Stop-Process -Name msinfo32 -Force
	}
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-system-noMsinfoLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\system"
	FwCreateFolder $LogFolder
	$Commands = @(
		"klist | Out-File ${LogFolder}\${Env:COMPUTERNAME}_klist.txt",
		"Nltest /SC_VERIFY:$env:USERDNSDomain | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Nltest.txt",
		"systeminfo | Out-File ${LogFolder}\${Env:COMPUTERNAME}_systeminfo.txt",
		"Get-CimInstance Win32_Product | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Win32_Product.txt",
		"verifier /query | Out-File ${LogFolder}\${Env:COMPUTERNAME}_verifier-query.txt",
		"verifier /querysettings | Out-File ${LogFolder}\${Env:COMPUTERNAME}_verifier-querysettings.txt",
		"tasklist | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklist.txt",
		"tasklist /M | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklist-M.txt",
		"tasklist /SVC | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklist-SVC.txt",
		"Get-Process | Format-Table -Property Handles,NPM,PM,WS,VM,CPU,Id,ProcessName,StartTime,@{ Label = 'Running Time';Expression={(GetAgeDescription -TimeSpan (new-TimeSpan $_.StartTime))}} -AutoSize | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-process.txt",
		"Get-MpPreference | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_defender_config.txt",
		"gpresult /H ${LogFolder}\${Env:COMPUTERNAME}_gpresult.html",
		"$global:ScriptFolder\BIN\Coreinfo.exe -accepteula | Out-File ${LogFolder}\${Env:COMPUTERNAME}_coreinfo.txt",
		"$global:ScriptFolder\BIN\Coreinfo.exe -accepteula -v | Out-File ${LogFolder}\${Env:COMPUTERNAME}_coreinfo-v.txt",
		"w32tm /query /status /verbose | Out-File ${LogFolder}\${Env:COMPUTERNAME}_w32tm-status.txt",
		"w32tm /query /configuration /verbose | Out-File ${LogFolder}\${Env:COMPUTERNAME}_w32tm-config.txt",
		"w32tm /query /peers | Out-File ${LogFolder}\${Env:COMPUTERNAME}_w32tm-peers.txt",
		"cscript c:\Windows\system32\slmgr.vbs /dlv c0a2ea62-12ad-435b-ab4f-c9bfab48dbc4 | Out-File ${LogFolder}\${Env:COMPUTERNAME}_2012_ESU_Year1.txt",
		"cscript c:\Windows\system32\slmgr.vbs /dlv e3e2690b-931c-4c80-b1ff-dffba8a81988 | Out-File ${LogFolder}\${Env:COMPUTERNAME}_2012_ESU_Year2.txt",
		"cscript c:\Windows\system32\slmgr.vbs /dlv 55b1dd2d-2209-4ea0-a805-06298bad25b3 | Out-File ${LogFolder}\${Env:COMPUTERNAME}_2012_ESU_Year3.txt",
		"pnputil.exe /export-pnpstate ${LogFolder}\${Env:COMPUTERNAME}_pnpstate.pnp"
		)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-taskschedulerLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\taskscheduler"
	FwCreateFolder $LogFolder
	$Commands = @(
		"schtasks /query /v /FO CSV | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklog.csv",
		"schtasks /query /v | Out-File ${LogFolder}\${Env:COMPUTERNAME}_tasklog.txt",
		"Get-ScheduledTask | select * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_get-scheduledtask.log"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-virtualfcLog{
	EnterFunc $MyInvocation.MyCommand.Name

	$ToolFolder = "$global:ScriptFolder\BIN$Global:ProcArch"
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\virtualfc"
	FwCreateFolder $LogFolder
	$Commands = @(
		"$ToolFolder\fcinfo.exe /details | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fcinfo-details.txt",
		"$ToolFolder\fcinfo.exe /ports | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fcinfo-ports.txt",
		"$ToolFolder\fcinfo.exe /ports /details | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fcinfo-ports-details.txt",
		"$ToolFolder\fcinfo.exe /top | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fcinfo-top.txt",
		"$ToolFolder\fcinfo.exe /stats | Out-File ${LogFolder}\${Env:COMPUTERNAME}_fcinfo-stats.txt",
		"$global:ScriptFolder\BIN\npivtool.exe -listallports | Out-File ${LogFolder}\${Env:COMPUTERNAME}_npivtool-listallports.txt",
		"$global:ScriptFolder\BIN\npivtool.exe -showlunmappings | Out-File ${LogFolder}\${Env:COMPUTERNAME}_npivtool-showlunmappings.txt",
		"Get-WmiObject -Namespace root\wmi -Class MSFC_FibrePortHbaAttributes | Out-File ${LogFolder}\${Env:COMPUTERNAME}_MSFC_FibrePortHbaAttributes.txt",
		"Get-WmiObject -Namespace root\wmi -Class MSFC_FibrePortNPIVAttributes | Out-File ${LogFolder}\${Env:COMPUTERNAME}_MSFC_FibrePortNPIVAttributes.txt",
		"Get-VMSan | fl * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMSan.txt",
		"Get-VM | Get-VMFibreChannelHba | fl * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_Get-VMFibreChannelHba.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-vssLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix\vss"
	FwCreateFolder $LogFolder
	$Commands = @(
		"vssadmin list Providers | Out-File ${LogFolder}\${Env:COMPUTERNAME}_vssadmin_list_providers.txt",
		"vssadmin list Shadows | Out-File ${LogFolder}\${Env:COMPUTERNAME}_vssadmin_list_shadows.txt",
		"vssadmin list ShadowStorage | Out-File ${LogFolder}\${Env:COMPUTERNAME}_vssadmin_list_shadowstorage.txt",
		"vssadmin list Volumes | Out-File ${LogFolder}\${Env:COMPUTERNAME}_vssadmin_list_volumes.txt",
		"vssadmin list Writers  | Out-File ${LogFolder}\${Env:COMPUTERNAME}_vssadmin_list_writers.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-allLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix"
	FwCreateFolder $LogFolder
	CollectSHA_support-clusterLog
	CollectSHA_support-diskLog
	CollectSHA_support-mpioLog
	CollectSHA_support-vssLog
	CollectSHA_support-diskshadowLog
	CollectSHA_support-driverinfoLog
	CollectSHA_support-fltmcLog
	CollectSHA_support-fsrmLog
	CollectSHA_support-handleLog
	CollectSHA_support-iscsiLog
	CollectSHA_support-networkLog
	CollectSHA_support-registryLog
	CollectSHA_support-setupLog
	CollectSHA_support-storagereplicaLog
	CollectSHA_support-taskschedulerLog
	CollectSHA_support-eventlogLog
	CollectSHA_support-systemLog
	CollectSHA_support-HyperVLog
	CollectSHA_support-HyperV-detailLog

	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-all-noMsinfoLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix"
	FwCreateFolder $LogFolder
	CollectSHA_support-clusterLog
	CollectSHA_support-diskLog
	CollectSHA_support-mpioLog
	CollectSHA_support-vssLog
	CollectSHA_support-diskshadowLog
	CollectSHA_support-driverinfoLog
	CollectSHA_support-fltmcLog
	CollectSHA_support-fsrmLog
	CollectSHA_support-handleLog
	CollectSHA_support-iscsiLog
	CollectSHA_support-networkLog
	CollectSHA_support-registryLog
	CollectSHA_support-setupLog
	CollectSHA_support-storagereplicaLog
	CollectSHA_support-taskschedulerLog
	CollectSHA_support-eventlogLog
	CollectSHA_support-HyperVLog
	CollectSHA_support-HyperV-detailLog
	CollectSHA_support-system-noMsinfoLog

	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-all-noHyperVLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$LogFolder = "$global:LogFolder\support$global:LogSuffix"
	FwCreateFolder $LogFolder
	CollectSHA_support-clusterLog
	CollectSHA_support-diskLog
	CollectSHA_support-mpioLog
	CollectSHA_support-vssLog
	CollectSHA_support-diskshadowLog
	CollectSHA_support-driverinfoLog
	CollectSHA_support-fltmcLog
	CollectSHA_support-fsrmLog
	CollectSHA_support-handleLog
	CollectSHA_support-iscsiLog
	CollectSHA_support-networkLog
	CollectSHA_support-registryLog
	CollectSHA_support-setupLog
	CollectSHA_support-storagereplicaLog
	CollectSHA_support-taskschedulerLog
	CollectSHA_support-eventlogLog
	CollectSHA_support-systemLog
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-fsiLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$drive = Read-Host "Please Input Drive Name (C or D etc.)"
	$drivename = $drive + ":"
	$LogFolder = "$global:LogFolder\support\fsi$global:LogSuffix"
	FwCreateFolder $LogFolder
	fsutil file queryoptimizemetadata ${drive}`:\`$secure`:`$SDS | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_queryoptimizemetadata.txt
	$Commands = @(
		"fsutil usn queryjournal $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_queryjournal.txt",
		"fsutil fsinfo ntfsinfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_ntfsinfo.txt",
		"fsutil fsInfo sectorInfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_sectorInfo.txt",
		"fsutil fsInfo volumeInfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_volumeInfo.txt",
		"fsutil volume allocationReport $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_allocationReport.txt",
		"fsutil volume diskfree $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_diskfree.txt",
		"fsutil volume fileLayout $drivename * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_fileLayout.txt",
		"fsutil volume thinProvisioningInfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_thinProvisioningInfo.txt",
		"fsutil 8dot3name query $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_8dot3name_query.txt",
		"fsutil dirty query $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_dirty_query.txt",
		"fsutil fsInfo drivetype $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_fsInfodrivetype.txt",
		"fsutil quota query $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_quota.txt",
		"compact /s:$drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_%drive%_compact.txt",
		"defrag $drivename /A /V | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_defrag.txt",
		"chkdsk $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_chkdsk.txt"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

function CollectSHA_support-spaceLog{
	EnterFunc $MyInvocation.MyCommand.Name
	$drive = Read-Host "Please Input Drive Letter (C or D etc.)"
	$drivename = $drive + ":\"
	$LogFolder = "$global:LogFolder\support\space$global:LogSuffix"
	$PsExec = "$global:ScriptFolder\BIN\PsExec.exe"
	FwCreateFolder $LogFolder
	$Commands = @(
		"$PsExec -s -i -accepteula cmd.exe /c `"dir /a /r /s /c /n $drivename > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_dir_priv.txt`"",
		"$PsExec -s -i -accepteula cmd.exe /c `"dir /a /r /s /c /t:c /n $drivename > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_dir-createdate_priv.txt`"",
		"$PsExec -s -i -accepteula cmd.exe /c `"$global:DuExe -accepteula -q $drivename\ > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_du-priv.txt`"",
		"$PsExec -s -i -accepteula cmd.exe /c `"$global:DuExe -accepteula -q -l 1 $drivename\ > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_du-l1-priv.txt`"",
		"$PsExec -s -i -accepteula cmd.exe /c `"$global:DuExe -accepteula -q -v $drivename\ > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_du-v-priv.txt`"",
		"dir /a /r /s /c /n $drivename > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_dir.txt",
		"dir /a /r /s /c /t:c /n $drivename > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_dir.txt",
		"$global:DuExe -accepteula -q $drivename\ > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_du.txt",
		"$global:DuExe -accepteula -q -l 1 $drivename\ > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_du-l1.txt",
		"$global:DuExe -accepteula -q -v $drivename\ > ${LogFolder}\${Env:COMPUTERNAME}_${drive}_du-v.txt",
		"fsutil usn queryjournal $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_queryjournal.txt",
		"fsutil fsinfo ntfsinfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_ntfsinfo.txt",
		"fsutil fsInfo sectorInfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_sectorInfo.txt",
		"fsutil fsInfo volumeInfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_volumeInfo.txt",
		"fsutil fsInfo statistics $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_statistics.txt",
		"fsutil storageReserve query $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_storageReserve.txt",
		"fsutil storageReserve query findByID $drivename * | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_storageReserve_findByID.txt",
		"fsutil volume allocationReport $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_allocationReport.txt",
		"fsutil volume diskfree $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_diskfree.txt",
		"fsutil volume thinProvisioningInfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_thinProvisioningInfo.txt",
		"fsutil 8dot3name query $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_8dot3name_query.txt",
		"fsutil dirty query $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_dirty_query.txt",
		"fsutil fsInfo drivetype $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_fsInfodrivetype.txt",
		"fsutil quota query $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_quota.txt",
		"fsutil volume thinProvisioningInfo $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_fsutil_thinProvisioningInfo.txt",
		"chkdsk $drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_chkdsk.txt",
		"defrag $drivename /A /V | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_defrag.txt",
		"vssadmin list Shadows | Out-File ${LogFolder}\${Env:COMPUTERNAME}_vssadmin_list_shadows.txt",
		"vssadmin list ShadowStorage | Out-File ${LogFolder}\${Env:COMPUTERNAME}_vssadmin_list_shadowstorage.txt",
		"compact /s:$drivename | Out-File ${LogFolder}\${Env:COMPUTERNAME}_${drive}_compact.txt",
		"GetDiskUsageInformation ${LogFolder}"
	)
	RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$True
	EndFunc $MyInvocation.MyCommand.Name
}

#endregion ### Pre-Start / Post-Stop / Collect functions for trace components and scenarios 

#region --- HelperFunctions ---
function GetClusterRegHives {
	param(
		[Parameter(Mandatory=$False)]
		[String]$global:TssPhase				# _Start_ or _Stop_
	)
	EnterFunc ($MyInvocation.MyCommand.Name + " at $global:TssPhase")
	if (-not (Test-Path "$PrefixCn`RegHive_Cluster.hiv")) {
		LogInfoFile "... collecting Cluster Registry Hives"
		$Commands = @(
			"REG SAVE HKLM\cluster $PrefixCn`RegHive_Cluster.hiv /Y"
		)
		RunCommands $LogPrefix $Commands -ThrowException:$False -ShowMessage:$False
	}
	EndFunc $MyInvocation.MyCommand.Name
}

function GetDiskUsageInformation {
	Param(
		[Parameter()]
		[String] $Path
	)
	Write-Host $Path
	$OutputEncoding = [Text.Encoding]::Default
	$DuVPrivFile = Get-ChildItem $Path -include "*du-v-priv.txt" -Recurse | ?{ $_.Length -ne $null } | Select-Object Fullname
	if ($DuVPrivFile.Length -eq 0){
		"Error: There is no data-set."
   		exit 
	}
	if ($DuVPrivFile.Length -gt 1){
   		"Error: There are two or more data-set."
   		Write-Host "Number of data-set: "  $DuVPrivFile.Length
   		exit
	}

	$fileName = $DuVPrivFile.Fullname
	$file = Get-Content $fileName | Sort-Object -Descending
	$ResultDir = Split-Path $fileName -parent

	$date = Get-Date -Format "yyyy-MMdd-HHmmss"
	$ResultFile = $ResultDir + "\Du_sort_$date.txt"
	$ResultFile2 = $ResultDir + "\AnalysisResult_$date.txt"

	Write-Output $file | Out-File -LiteralPath $ResultFile -Encoding Default

	$file = Get-Content $fileName | Sort-Object -Descending | select-object  -First 25

	Write-Output "====================================" | Add-Content $ResultFile2 -Encoding Default
	Write-Output "Analysis Results"					 | Add-Content $ResultFile2 -Encoding Default
	Write-Output "====================================" | Add-Content $ResultFile2 -Encoding Default

	if ($null -eq $file){
   		"Error: null array" 
	} else {
   		Write-Output  $file  | Add-Content $ResultFile2 -Encoding Default
	} 

	Write-Output "====================================" | Add-Content $ResultFile2 -Encoding Default
	Write-Output "Possible Cause"					   | Add-Content $ResultFile2 -Encoding Default
	Write-Output "====================================" | Add-Content $ResultFile2 -Encoding Default

	$FlgWF1 = 0
	$FlgWF2 = 0
	$FlgWF3 = 0
	$FlgWF4 = 0
	$FlgWF5 = 0

	for ($i=0; $i -lt 25; $i++){
		# Work Flow 1: WinSxS
   		if ($file[$i] -imatch "c:\\windows\\winsxs"){
   			if ($FlgWF1 -eq 0){
   				Write-Output ""| Add-Content $ResultFile2 -Encoding Default
				Write-Output "[Possible Cause] WinSxS folder" | Add-Content $ResultFile2 -Encoding Default
	   			Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				$FlgWF1 = 1
			}
			Write-Output  $file[$i] | Add-Content $ResultFile2 -Encoding Default
		}
	
		# Work Flow 2: Installer
		if ($file[$i] -imatch "c:\\Windows\\installer"){
			if ($FlgWF2 -eq 0){
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "[Possible Cause] Installer folder" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				$FlgWF2 = 1
			}
			Write-Output  $file[$i] | Add-Content $ResultFile2 -Encoding Default
		}
	
		# Work Flow 3: IIS log
		if ($file[$i] -imatch "inetpub"){
			if ($FlgWF3 -eq 0){
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "[Possible Cause] IIS log folder" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "  Reference:" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "  https://docs.microsoft.com/en-us/iis/manage/provisioning-and-managing-iis/managing-iis-log-file-storage" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				$FlgWF3 = 1
			}
			Write-Output  $file[$i] | Add-Content $ResultFile2 -Encoding Default
		}
	
		# Work Flow 4: WSUS database
		if ($file[$i] -imatch "c:\\Windows\\WID\\Data"){
			if ($FlgWF4 -eq 0){
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "[Possible Cause] WSUS database" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				$FlgWF4 = 1
			}
			Write-Output  $file[$i] | Add-Content $ResultFile2 -Encoding Default
		}
	
		# Work Flow 5: Azure backup cache
		if ($file[$i] -imatch "c:\\Program Files\\Microsoft Azure Recovery Services Agent\\Scratch"){
			if ($FlgWF5 -eq 0){
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "[Possible Cause] Azure backup cache" | Add-Content $ResultFile2 -Encoding Default
				Write-Output "" | Add-Content $ResultFile2 -Encoding Default
				$FlgWF5 = 1
			}
			Write-Output  $file[$i] | Add-Content $ResultFile2 -Encoding Default
		}
	}

	# Work Flow 7: USN jounal
	$USNPrivFile = Get-ChildItem $Path -include "*fsutil_queryjournal.txt" -Recurse | ?{ $_.Length -ne $null } | Select-Object Fullname
	$fileName = $USNPrivFile.Fullname
	$file = Get-Content $fileName

	if ($file[2] -imatch "0x00000ffffffe0000"){
				Write-Output ""												  | Add-Content $ResultFile2 -Encoding Default
				Write-Output "[Possible Cause] USN Jounal."					 | Add-Content $ResultFile2 -Encoding Default
				Write-Output "  -> The nuxt usn jounal is over 16 TB (0x00000ffffffe0000)"				 | Add-Content $ResultFile2 -Encoding Default
				Write-Output ""												  | Add-Content $ResultFile2 -Encoding Default
				Write-Output $file | Add-Content $ResultFile2 -Encoding Default 
	}
}
#endregion --- HelperFunctions ---


#region Registry Key modules for FwAddRegItem
	$global:KeysHyperV = @("HKLM:Software\Microsoft\Windows NT\CurrentVersion\Virtualization", "HKLM:System\CurrentControlSet\Services\vmsmp\Parameters")
#endregion Registry Key modules

#region groups of Eventlogs for FwAddEvtLog
	$EvtLogsShaHypHost	= @("Microsoft-Windows-Hyper-V-VMMS-Admin", "Microsoft-Windows-Hyper-V-VMMS-operational", "Microsoft-Windows-Hyper-V-Worker-Admin", "Microsoft-Windows-Hyper-V-VMMS-Networking", "Microsoft-Windows-Hyper-V-EmulatedNic-Admin", "Microsoft-Windows-Hyper-V-Hypervisor-Admin", "Microsoft-Windows-Hyper-V-Hypervisor-Operational", "Microsoft-Windows-Hyper-V-SynthNic-Admin", "Microsoft-Windows-Hyper-V-VmSwitch-Operational", "Microsoft-Windows-MsLbfoProvider/Operational")
	$EvtLogsShieldedVm	= @("Microsoft-Windows-HostGuardianService-Client/Operational", "Microsoft-Windows-HostGuardianService-Client/Admin", "Microsoft-Windows-HostGuardianService-CA/Operational", "Microsoft-Windows-HostGuardianService-CA/Admin", "Microsoft-Windows-HostGuardianService-KeyProtection/Admin", "Microsoft-Windows-HostGuardianService-KeyProtection/Operational", "Microsoft-Windows-HostGuardianService-Attestation/Admin", "Microsoft-Windows-HostGuardianService-Attestation/Operational", "Microsoft-Windows-HostGuardianClient-Service/Operational", "Microsoft-Windows-HostGuardianClient-Service/Admin")
#endregion groups of Eventlogs

# Deprecated parameter list. Property array of deprecated/obsoleted params.
#   DeprecatedParam: Parameters to be renamed or obsoleted in the future
#   Type		   : Can take either 'Rename' or 'Obsolete'
#   NewParam	   : Provide new parameter name for replacement only when Type=Rename. In case of Type='Obsolete', put null for the value.
$SHA_DeprecatedParamList = @(
#	@{DeprecatedParam='NET_iSCSI';Type='Rename';NewParam='SHA_iSCSI'}
)
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *



# SIG # Begin signature block
# MIIoKgYJKoZIhvcNAQcCoIIoGzCCKBcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1r3ig4/sW2XjK
# UF0Nct/33BZ1ju/jhzaWZ/cI9swOiaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAjvFM0IuXnkF4ycXai8QP4X
# /cvgT8IwVv60H+JC/vpbMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAuai5n4GO5cG+cnr0H+OPipU5jxUkYMnyrJSITVcQY7UpBVyQwYLuIPQZ
# sNZiQSmOaZqURNIvLL7BKyJyVZUxOw1Q6I25jVvRLj5asw/AQLZ0Tp2oqVfjAMEd
# DHYA+0aNrandD5otdeuEwfNSTvQ/sKITbKdxcG9QtLjQBsPFY/ohiIs7VmmQ4MDN
# 1X3li/A9d6e6exPxK6uaRjKi/ty3J8uswoBA8sNFPPrtbuRtSPX24rA1KY0zxzpa
# /Fqf+ik0fBI6FrSmZe2rU3TkuvlViyehyY2xmR+jPzbBqbmp0j0DTLFhzc7fsTDc
# PS6waQyYtv0ZQyzOMxkbAYqL7tqiFKGCF5QwgheQBgorBgEEAYI3AwMBMYIXgDCC
# F3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCDRnhd23JT/YU15aJQT6mNQl9qtBTec47ce8esos45vEgIGZkZX1iuW
# GBMyMDI0MDYxMjE0NTg0OS42NzZaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHqMIIHIDCCBQigAwIBAgITMwAAAebZQp7qAPh94QABAAAB5jANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# MTVaFw0yNTAzMDUxODQ1MTVaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC9vph84tgluEzm/wpNKlAjcElGzflvKADZ1D+2d/ie
# YYEtF2HKMrKGFDOLpLWWG5DEyiKblYKrE2nt540OGu35Zx0gXJBE0zWanZEAjCjt
# 4eGBi+uakZsk70zHTQHHyfP+B3m2BSSNFPhgsVIPp6vo/9t6OeNezIwX5E5+VwEG
# 37nZgEexQF2fQZYbxQ1AauqDvRdXsSpK1dh1UBt9EaMszuucaR5nMwQN6sDjG99F
# zdK9Atzbn4SmlsoLUtRAh/768sKd0Y1hMmKVHwIX8/4JuURUBRZ0JWu0NYQBp8kh
# ku18Q8CAQ500tFB7VH3pD8zoA4lcA7JkxTGoPKrufm+lRZAA4iMgbcLZ2P/xSdnK
# FxU8vL31RoNlZJiGL5MqTXvvyBLz+MRP4En9Nye1N8x/lJD1stdNo5wJG+mgXsE/
# zfzg2GaVqQczFHg0Nl8bpIqnNFUReQRq3C1jVYMCScegNzHeYtw5OmZ/7eVnRmjX
# lCsLvdsxOzc1YVn6nZLkQD5y31HYrB9iIHuswhaMv2hJNNjVndkpWy934PIZuWTM
# k360kjXPFwl2Wv1Tzm9tOrCq8+l408KIL6J+efoGNkR8YB3M+u1tYeVDO/TcObGH
# xaGFB6QZxAUpnfB5N/MmBNxMOqzG1N8QiwW8gtjjMJiFBf6iYYrCjtRwF7IPdQLF
# tQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFOUEMXntN54+11ZM+Qu7Q5rg3Fc9MB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBhbuogTapRsuwSkaFMQ6dyu8ZCYUpWQ8iI
# rbi40tU2hK6pHgu0hj0z/9zFRRx5DfhukjvbjA/dS5VYfxz1EIbPlt897MJ2sBGO
# 2YLYwYelfJpDwbB0XS9Zkrqpzq6X/lmDQDn3G5vcYpYQCJ55LLvyFlJ195AVo4Wy
# 8UX5p7g9W3MgNHQMpM+EV64+cszj4Ho5aQmeKGtKy7w72eRY/vWDuptrvzruFNmK
# CIt12UcA5BOsXp1Ptkjx2yRsCj77DSml0zVYjqW/ISWkrGjyeVJ+khzctxaLkklV
# wCxigokD6fkWby0hCEKTOTPMzhugPIAcxcHsR2sx01YRa9pH2zvddsuBEfSFG6Cj
# 0QSvEZ/M9mJ+h4miaQSR7AEbVGDbyRKkYn80S+3AmRlh3ZOe+BFqJ57OXdeIDSHb
# vHzJ7oTqG896l3eUhPsZg69fNgxTxlvRNmRE/+61Yj7Z1uB0XYQP60rsMLdTlVYE
# yZUl5MLTL5LvqFozZlS2Xoji4BEP6ddVTzmHJ4odOZMWTTeQ0IwnWG98vWv/roPe
# gCr1G61FVrdXLE3AXIft4ZN4ZkDTnoAhPw7DZNPRlSW4TbVj/Lw0XvnLYNwMUA9o
# uY/wx9teTaJ8vTkbgYyaOYKFz6rNRXZ4af6e3IXwMCffCaspKUXC72YMu5W8L/zy
# TxsNUEgBbTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjMzMDMtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQDi
# WNBeFJ9jvaErN64D1G86eL0mu6CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hPEJTAiGA8yMDI0MDYxMjA2NTIy
# MVoYDzIwMjQwNjEzMDY1MjIxWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDqE8Ql
# AgEAMAcCAQACAgzLMAcCAQACAhN9MAoCBQDqFRWlAgEAMDYGCisGAQQBhFkKBAIx
# KDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
# hvcNAQELBQADggEBAIAlF48QzlI0/nUHE309In7Re3wMMsGVjJvH8QyDFSgdoxa7
# iAmmbjxSHDj6ROWkpC+pwCh+5mnmtyOY+qgPJEZEcevGQOsMAgxSDwgFkjGjLOH1
# 0ANMGpv4Lgoff15oV0kg8+vW2w/iCzmazenro/KU2s6jZ27cpZ1OxWwThafsEoZa
# HcAVrR5ltkJExcEgSxfLnFTE9citlY/FGfJPAoPLArf9as9MesxZrnhwS1Rdd46z
# fa2R/Wt/seKge8aJHEJfs3QRx4M+hhQUVBnsyUrMImxMvXTW9w442Q6+6RTSZb8e
# tmYaQLmFut1dPrTkvFtMH2B/ScfASx1jnJLzzY4xggQNMIIECQIBATCBkzB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAebZQp7qAPh94QABAAAB5jAN
# BglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8G
# CSqGSIb3DQEJBDEiBCB3tfBwsiefX0rlaFt8wtH4pQfP5C41S0aPvC71NADhSDCB
# +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIM+7o4aoHrMJaG8gnLO1q16hIYcR
# noy6FnOCbnSD0sZZMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAHm2UKe6gD4feEAAQAAAeYwIgQgy6KmSaERUFw5zM8ixrWjedEWrCkX
# YG0+8JQBRQ+GJXIwDQYJKoZIhvcNAQELBQAEggIAsT3/tuETJ/AR0bWuIrKO9tSi
# 1f/2B15QRtiXyynY0fgF+iQogs5NvS2ywJHt6ZMveBMNNSBrKgxdAomFfNgrUcAa
# GViSRuJV284vcpK94cfDbLygXBfbIYnG8KBwPayijIjC0TA0tRyOdAU6iDvD/0he
# OjFQiWw+ygsx262ozgMAXkiZ5STcCiNYD6F5IiZ4Z/QRYUWSU5Tpgmum5X9Q6Qv5
# Qtu+6hUQK+/Icjn83VmuIw7qRtU6u1neSgwJheiiYSFrPacfLUGilZ2CbsfdwXjp
# 47zFq9oKyaAW2ogUjz661DyPKlJXSn49Tb8CE3q+4IYEl5wRW+2DThD1Ctuk22Wn
# khNCTFQQBTHn5TybV9aRlbKVHugv+ivWFBNy0sMDVjt/Gapo6hu8n2fQGkTbuz7a
# 8Rr6D4GA3urH5e0VhZ1NL6toxDiH1NqfcBy+tF7yjslpDWZHY9fz/I6NvKvoVRBy
# VBtjIZ6y69lJ62cBvVQ8P5kcq2CyY2rpr/Qy545pMFEFQMJAB9vyHbpRp32E9S4S
# Fgqq1tOanrZxCIfYII/brT2Gn9kXdciwenGiWLySxeP/Dunpga84s6JN6t+nLxUu
# pOOYl609ZV4bJD+E0rm5XH9M2Lv3MmTl5N3lb7ByQCAQNOJogVWrORkI7CY+5lL4
# FQ7Rcof0vomEar8rnqA=
# SIG # End signature block
