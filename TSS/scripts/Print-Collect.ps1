<#
  .SYNOPSIS
  Data collection tool for printing-related troubleshooting by Marius Porcolean (maporcol).

  .DESCRIPTION
  The Print-Collect.ps1 script simplifies the collection of Printing related troubleshooting
  data, making action plans easier. The tool is compliant with company policies, is signed &
  published officially, as part of the Windows CES Diag Tools repository.

  .LINK
  https://aka.ms/Print-Collect

  .LINK
  https://cesdiagtools.blob.core.windows.net/windows/Print-Collect.zip

  .PARAMETER AcceptEula
  Allows accepting the EULA without generating a GUI pop-up, for executing the script in
  non-interactive scenarios. For example, when running the script remotely on a different
  machine through a console.

  .PARAMETER DataPath
  The script saves the collected data in the folder where the script exists by default.
  If you want to save the data in another specific location, pass this parameter along
  with a destination.

  .PARAMETER Logs
  Get the 'classic' Print-Collect dataset -> dumps, event logs, registry keys, cmd outputs, etc.

  .PARAMETER NoDumps
  The script collects some memory dumps too by default. If you don't want to get the memory dumps, 
  because that will significantly increase the size of the resulting dataset, use this flag.

  .PARAMETER Trace
  Collect live printing traces, plus others, depending on the flags used.

  .PARAMETER LPD
  Add to the live trace the providers related to LPD service.
  
  .PARAMETER Network
  Collect live network packets capture, along with the printing trace, but in a separate file.

  .PARAMETER RPC
  Collect live RPC trace, on top of the printing trace, but in a separate file.

  .PARAMETER ProcMon
  Collect live Process Monitor capture.

  .PARAMETER PSR
  Activate the Problem Steps Recorder tool during the live tracing. This automatically collects 
  screenshots & information about steps performed (e.g: user left-clicked in text area of CMD.exe, 
  user clicked close on Event Viewer)

  .INPUTS
  None. You cannot pipe objects to Print-Collect.ps1.

  .OUTPUTS
  script-output.txt & script-errors.txt + the folder with the collected data.

  .EXAMPLE
  PS> .\Print-Collect.ps1
  Displays the help info.

  .EXAMPLE
  PS> .\Print-Collect.ps1 -Logs [-NoDumps]
  Collects the 'classic' static dataset, with or without dumps.

  .EXAMPLE
  PS> .\Print-Collect.ps1 -Trace [-LPD] [-RPC] [-Network] [-ProcMon] [-PSR]
  Collects Print + other optional traces, without the 'classic' static dataset.

  .EXAMPLE
  PS> .\Print-Collect.ps1 -Trace [-LPD] [-RPC] [-Network] [-ProcMon] [-PSR] -Logs [-NoDumps] 
  Collects traces (default or optionals too) and after that a 'classic' static dataset (with or without dumps).
#>
param( 
  [string]$DataPath,
  [switch]$AcceptEula,
  [switch]$Logs,
  [switch]$NoDumps,
  [switch]$Trace,
  [switch]$LPD,
  [switch]$Network,
  [switch]$RPC,
  [switch]$ProcMon,
  [switch]$PSR
)

$toolName = "Print-Collect"
$version = $toolName + " 2023-August-22"
# by Marius Porcolean (maporcol@microsoft.com) 
# using Collect-Commons module by Gianni Bragante (gbrag@microsoft.com)

$global:Root = Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path
try {
  Import-Module ($global:Root + "\Collect-Commons.psm1") -Force -DisableNameChecking -ErrorAction Stop
}
catch {
  Write-Host "Unable to import the helper module, can't continue without it! Exiting..." -ForegroundColor Red
  Write-Host ($_.Exception.Message) -ForegroundColor Red
  exit
}
Deny-IfNotAdmin

Function Start-Traces {
  Invoke-CustomCommand "ipconfig /flushdns"
  Invoke-CustomCommand "nbtstat -R"
  Invoke-CustomCommand "KList purge"

  Invoke-CustomCommand "logman create trace 'Print-Trace' -ow -o '$($TracesDir)Print-Trace-$($env:COMPUTERNAME).etl' -p 'Microsoft-Windows-PrintService' 0xFFFFFFFFFFFFFFFF 0xFF -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 2048 -ets"

  # Spooler WPP Trace Control Guids
  # SPOOLSV
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A9E-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # SPOOLSS
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A9F-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # LOCALSPL
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A01-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # PrintPLM
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{d2e1bab1-eb9b-4ba7-9123-19c01ddc4f78}' 0x7FFFFFFF 0xFF -ets"
  # WINSPOOL
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A02-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # WIN32SPL
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A03-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # BIDISPL
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A04-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # SPLWOW64
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A05-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # SPLLIB
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A06-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # PERFLIB
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A07-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # ASYNCNTFY
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A08-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # #NTFY
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A09-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # GPPRNEXT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A0A-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # SANDBOX
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A0B-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # SANDBOXHOST
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C9BF4A0C-D547-4d11-8242-E03A18B5BE01}' 0x7FFFFFFF 0xFF -ets"
  # PIPELINE
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{AEFE45F4-8548-42B4-B1C8-25673B07AD8B}' 0x7FFFFFFF 0xFF -ets"
  # NTPRINT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{B795C7DF-07BC-4362-938E-E8ABD81A9A01}' 0x7FFFFFFF 0xFF -ets"
  # LPRHELP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{9e6d0d9b-1ce5-44b5-8b98-f32ed89077ec}' 0x7FFFFFFF 0xFF -ets"
  # LPRMON
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{f30fab8e-84bb-48d4-8e80-f8967ef0fe6a}' 0x7FFFFFFF 0xFF -ets"
  # USBJSCRIPT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{B48AE058-218A-4338-9B97-9F5F9E4EB5D2}' 0x7FFFFFFF 0xFF -ets"
  # USBMOn
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{99F5F45C-FD1E-439F-A910-20D0DC759D28}' 0x7FFFFFFF 0xFF -ets"
  # TCPMIB
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{D3A10B55-1EAD-453d-8FC7-35DA3D6A04D2}' 0x7FFFFFFF 0xFF -ets"
  # TCPMON
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{62A0EB6C-3E3E-471d-960C-7C574A72534C}' 0x7FFFFFFF 0xFF -ets"
  # WSDPRINT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{9558985e-3bc8-45ef-a2fd-2e6ff06fb886}' 0x7FFFFFFF 0xFF -ets"
  # WSDMON
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{836767A6-AF31-4938-B4C0-EF86749A9AEF}' 0x7FFFFFFF 0xFF -ets"
  # WSDPPROXY
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{6D1E0446-6C52-4b85-840D-D2CB10AF5C63}' 0x7FFFFFFF 0xFF -ets"
  # DAFWSD
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{4ea56ff9-fc2a-4f0c-8d6e-c345bc452c80}' 0x7FFFFFFF 0xFF -ets"
  # FDWSD
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{7e2dbfc7-41e8-4987-bca7-76cadfad765f}' 0x7FFFFFFF 0xFF -ets"
  # FDPrint
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{79b3b0b7-f082-4cec-91bc-5e4b9cc3033a}' 0x7FFFFFFF 0xFF -ets"
  # WSDAPI - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{75454210-b231 - 4fea-b2b4-2cc66d7ae8aa}' 0x7FFFFFFF 0xFF -ets"
  # FindNetPrinters
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{A1607A05-8D8A-4d74-82C7-460DD790648E}' 0x7FFFFFFF 0xFF -ets"
  # XPSPRINT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{CA478AB1-8B38-451D-90E4-8534EB50B9D3}' 0x7FFFFFFF 0xFF -ets"
  # MicrosoftRenderFilter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{A6D25EF4-A3B3-4E5F-A872-24E71103FBDC}' 0x7FFFFFFF 0xFF -ets"
  # BTHPRINT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{eb3b6950-120c-4575-af39-2f713248e8a3}' 0x7FFFFFFF 0xFF -ets"
  # DAFBTH
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{8bbe74b4-d9fc-4052-905e-92d01579e3f1}' 0x7FFFFFFF 0xFF -ets"
  # BTHUSER
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{afa85d6c-0ea6-4c6a-99b7-5be1c9f3c7a1}' 0x7FFFFFFF 0xFF -ets"
  # BTHPORT - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{D88ACE07-CAC0-11D8-A4C6-000D560BCBA5}' 0x7FFFFFFF 0xFF -ets"
  # DOXXPS
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{0dc96237-bbd4-4bc9-8184-46df83b1f1f0}' 0x7FFFFFFF 0xFF -ets"
  # DOXPKG - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{0675cf90-f2b8-11db-bb42-0013729b82c4}' 0x7FFFFFFF 0xFF -ets"
  # XpsRchVw
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{986de178-ea3f-4e27-bbee-34e0f61535dd}' 0x7FFFFFFF 0xFF -ets"
  # XpsIFilter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{64f02056-afd9-42d9-b221-6c94733b09b1}' 0x7FFFFFFF 0xFF -ets"
  # XpsShellExt
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{2beade0b-84cd-44a5-90a7-5b6fb2ff83c8}' 0x7FFFFFFF 0xFF -ets"
  # XpsRender
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{aaacb431-6067-4a42-8883-3c01526dd43a}' 0x7FFFFFFF 0xFF -ets"
  # inet3pp
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{c9bf4a9e-d547-4d11-8242-e03a18b5beee}' 0x7FFFFFFF 0xFF -ets"
  
  # PrintUI WPP Trace Control Guids
  # PRINTUI
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{A83C80B9-AE01-4981-91C6-94F00C0BB8AA}' 0x7FFFFFFF 0xFF -ets"
  # PRNNTFY
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{09737B09-A25E-44D8-AA75-07F7572458E2}' 0x7FFFFFFF 0xFF -ets"
  # PRNCACHE - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{34F7D4F8-CD95-4b06-8BF6-D929DE4AD9DE}' 0x7FFFFFFF 0xFF -ets"
  # PRNFLDR - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{883dfb21-94ee-4c9b-9922-d5c42b552e09}' 0x7FFFFFFF 0xFF -ets"

  # PrintDriver WPP Trace Controls
  # PrintExtension
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{19E93940-A1BD-497F-BC58-CA333880BAB4}' 0x7FFFFFFF 0xFF -ets"

  # JScriptLib WPP Trace Controls
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{C59DA080-9CCE-4415-A77D-08457D7A059F}' 0x7FFFFFFF 0xFF -ets"

  # Roaming WPP Trace Controls
  # DAFPRINT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{3048407B-56AA-4D41-82B2-7d5F4b1CDD39}' 0x7FFFFFFF 0xFF -ets"
  # DAS
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{19E464A4-7408-49BD-B960-53446AE47820}' 0x7FFFFFFF 0xFF -ets"

  # Driver WPP Trace Controls
  # MSXpsFilters
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{9B4A618C-07B8-4182-BA5A-5B1943A92EA1}' 0x7FFFFFFF 0xFF -ets"

  # MXDC WPP Trace Controls
  # MXDC
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{FCA72EBA-CBB3-467c-93BC-1DB4978C398D}' 0x7FFFFFFF 0xFF -ets"

  # PrintDialog WPP Trace Controls
  # PREFDLG
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{3FB15E5D-DF1A-46FC-BEFE-27A4B82D75EE}' 0x7FFFFFFF 0xFF -ets"
  # DLGHOST
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{02EA8EB9-9811-46d6-AEEE-430ADCC2AA18}' 0x7FFFFFFF 0xFF -ets"

  # Windows.Graphics.Printing WPP Trace Controls
  # MODERNPRINT
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{DD6A31CB-C9C6-4EF9-B738-F306C29352F4}' 0x7FFFFFFF 0xFF -ets"
  # PrinterExtensions
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{EC08D605-5A20-4ED0-AE54-E8C4BFFF2EEB}' 0x7FFFFFFF 0xFF -ets"
  # AAD Cloud AP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{556045FD-58C5-4A97-9881-B121F68B79C5}' 0x7FFFFFFF 0xFF -ets"

  # PSMWPP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{4a743cbb-3286-435c-a674-b428328940e4}' 0x7FFFFFFF 0xFF -ets"
  # PLMWPP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{9C6FC32A-E17A-11DF-B1C4-4EBADFD72085}' 0x7FFFFFFF 0xFF -ets"
  # SEBWPP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{e8109b99-3a2c-4961-aa83-d1a7a148ada8}' 0x7FFFFFFF 0xFF -ets"

  # Scan
  # ScanRT WPP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{E6F8A5FC-7FCE-4095-8661-B8E0CB7D9410}' 0x7FFFFFFF 0xFF -ets"
  # DeviceEnumeration WPP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{1B42986F-288F-4DD7-B7F9-120297715C1E}' 0x7FFFFFFF 0xFF -ets"
  # PrintBRM (BRMENGINE) WPP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{12DFC189-A85B-4B19-847B-D9AC6B716DB8}' 0x7FFFFFFF 0xFF -ets"

  # TraceLogging Providers - Level = default (0xFFFFFFFFFFFFFFFF for TraceLogging)

  # Workflow and PrintSupport
  # "Microsoft.Windows.Print.Workflow.API"
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{744372de-ba26-443b-ba10-712c1a041234}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # "Microsoft.Windows.Print.Workflow.Broker"
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{1bf554be-03c5-4f49-9b57-f3c0cbad589a}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # "Microsoft.Windows.Print.Workflow.PrintSupport"
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{08fad69b-3394-5632-97ef-ff9c5a842b1f}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # "Microsoft.Windows.Print.Workflow.Source"
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{be5f8487-3a5d-4477-b0c2-020679b81e56}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # "Microsoft.Windows.Print.PrintSupport"
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{7faee4d5-95c1-5987-54c6-a7c3dfb6e56e}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # "Microsoft.Windows.Print.WorkFlowBroker"
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{F69D3E6C-298B-466C-B84F-486E1F21E347}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # "Microsoft.Windows.Print.WorkFlowRT"
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{cae6f32b-2553-5c24-f999-e63dde138b9f}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"

  # Microsoft.Windows.PrintCore
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{a4f32eea-babb-59b2-3828-ce92e4e20765}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-Mobile-Print-Plugins
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{6de9ba0e-9e72-53d2-229a-dc09205a27ea}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-Print-Platform
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{fd6b6ae4-7563-550d-46a4-da9fe46cad57}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrintConfig
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{fdcab703-6402-4959-b618-f5c3c279ef3d}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.DriverUI
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{ffdb1efb-602c-5725-c85c-f3f1a065d72a}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.DeviceCenter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{4c7e30ea-beaf-5b10-ae30-451fb529c653}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrintDeviceCapabilities
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{FD6EC121-DC51-42FD-A559-BA984D345E2B}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrintCoreConfig
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{3d9d790d-fb07-539d-b66e-5a2ffb7899ca}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Shell.PrintDialog
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{b0f40491-9ea6-5fd5-ccb1-0ec63be8b674}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Shell.PrintManager
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{c6dba857-03f1-5c5b-350c-ef08dbd04572}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-LifetimeManager - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{072665fb-8953-5a85-931d-d06aeab3d109}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Das
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{ab4d9355-341e-435d-b3d2-4b0e46354e2c}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-WSD-DafProvider
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{e4d412ab-4c22-49ef-83ca-eafb90768512}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.WSDMon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{BC2DAB59-AC78-487A-903E-DB3C343C0BE3}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-WSD-WSDApi
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{29b47072-00ff-4d9d-852d-0eafc181a9a3}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrintScanService
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{cb730350-b8b7-56d7-6fa4-90e0ea74a9bb}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Shell.ServiceProvider
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{15584c9b-7d86-5fe0-a123-4a0f438a82c0}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Windows.Internal.Shell.ModalExperience
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{8BFE6B98-510E-478D-B868-142CD4DEDC1A}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Mobile.Shell.ServiceProvider
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{97ff6b54-144c-524b-5fec-82b610461390}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.XpsPrint
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{73cf4d38-21a5-41dc-93d5-c8ec31d84b70}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.XpsDocumentTargetPrint
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{095da8da-2182-5c9a-53cd-07eca93a04ef}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppMon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{6fb61ac3-3455-4da4-8313-c1a855ee64c5}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.APMon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{e73d49d6-9eda-5059-74d1-b879b18cf9ae}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.WsdAdapter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{40dd7897-9206-5dc5-d21b-2de290ca181a}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.DafIpp
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{6d5ca4bb-df8e-41bc-b554-8aeab241f206}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.DafIppUsb
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{dd212385-31e6-541c-5587-3c469bb6470a}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppCommon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{acf1e4a7-9241-4fbf-9555-c27638434f8d}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppCommonDll
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{e9e3a474-c716-56f4-f6f2-5d5f181c46ab}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppOneCore
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{a08e69ca-2172-5c18-fe96-a2ac30857b97}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppConfigConverter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{6184BC1F-417E-4443-BCCE-9F65BF844AA7}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.HttpRest
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{49868e3d-77fb-5083-9e09-61e3f37e0309}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppEmulator
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{05af8001-5e28-5ebb-0329-a20fab346b76}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.Mopria.Service
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{38ae712f-fad1-528e-9721-6ebefea1ab2b}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.Ecp.Service
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{ec5b420f-d2ec-50b4-5119-083a4da63982}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.GetPrinterConfig
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{7e247d3c-42fa-5e08-6427-f98478081d24}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.GetIppAttributes
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{9594011E-FE68-4D05-9F06-C68A0EBE4822}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.JScriptLib
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{2974da9a-e1f3-5c5f-2abe-f7f20f6448bc}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"

  # Microsoft.Windows.Security.TokenBroker - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{077b8c4a-e425-578d-f1ac-6fdf1220ff68}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.AAD.TokenBrokerPlugin.Provider - commented out in PrintTrace.cmd
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{bfed9100-35d7-45d4-bfea-6c1d341d4c6b}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PwgRenderFilter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{e98cb748-3d93-4719-8209-95e0bc46eec7}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PCLmRenderFilter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{15fc363b-e2b4-5e55-f1d3-3b0ff726203d}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrintToPDF
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{63a87ca3-6662-4925-a0a8-f7bb94ef104e}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.TiffRenderFilter
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{7617c8d5-b61c-5f45-dd42-02c19bd5f387}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.RenderFilterCommon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{ac521649-5ec6-5397-d1c5-749cbf5ea79b}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.USBMon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{3fc887c9-c23f-59cd-88b5-a6086f4bbc9e}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.Usbprint
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{99d90395-1bb0-5932-720a-21d1be94eba3}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.DAFMCP
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{bf3eac2a-65ca-5ecc-2076-e23c6420a687}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.CloudPrintHelper
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{44050ea2-419d-5526-923b-b038e0f1e715}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppAdapterCore
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{48111f99-b3d5-5f69-587d-be4ed8e22647}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.IppAdapterCommon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{fbfbd628-251d-551d-c4dd-c7820af723e4}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrintScanDiscoveryManagement
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{e0d2f15a-3875-5388-2239-23f2538b7636}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PDMUtilities
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{0aef9116-5ab8-5c05-0eb3-c0721ba93354}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.WinspoolCore
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{81d45b93-a5ff-5459-26ff-c092864200c6}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.ApMonPortMig
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{d758d01c-7402-5923-6a27-44bdcc59a5c5}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.UsbPortMig
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{201eb0f8-12f0-5b34-c99b-75c1541f3479}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.McpManagement
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{7cdc2341-4d44-54aa-2899-ddb05ecf0adb}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.McpManagementUtil
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{402d7aed-ded3-5536-3112-a2ce8baa1fdc}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.McpIppChannel
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{ee8c758e-2e70-574f-8149-266b77c8d56a}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.McpEvtSrc
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{b145b5c6-1a9d-50c5-7f76-39f208ed09c9}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.McpLppHelper
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{0e46cee6-dd9a-5b24-67c6-be3a88c3f894}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.ProxyApp
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{e604ec58-ad08-5a2c-3ecb-704c8c024881}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.GDI
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{bad46242-e75f-541f-c2d2-ab35489f27e4}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.GpdParser
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{c5488b38-f338-51d9-1046-be7b050f3198}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.UniLib
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{24a149d9-e7af-59b9-10c7-b2115913ea92}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrvSpoolss
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{8325bcbd-4d99-5255-0722-d4387890d3c3}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.CSPs.UPPrinterInstalls
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{5000d5f2-f6c7-59e0-eda8-c5126f0eefcd}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.EsclScan
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{2e008da9-e1b6-5cb5-0607-82066afcfff4}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.EsclWiaDriver
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{93603fbe-a752-550d-b87e-f202b0f27f9e}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.EsclProtocol
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{27a7ea23-db5c-5487-b775-89c06c43039b}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.DafEscl
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{f25e0650-deff-5306-ca0d-40abb8b107dd}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.EsclEmulator
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{3e617461-4ad0-5bb1-ce2d-796bf4794fbf}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.Plugins
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{4e880362-c4e8-5c62-7a2e-db0ee6a8f9a8}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.EsclWiaCore
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{c7c2a97e-3d49-5f78-bd33-22d8c22a7cf3}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.Runtime
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{df6dca70-9918-455f-86fe-983adc74fa0d}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Scan.WindowsImageAcquisition
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{4a892232-6efc-54c1-1f0a-1b916a719612}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.DeviceControl
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{5fef3144-ec00-5072-ee6b-5d0a02bb656c}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.XGC
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{0a82e916-4637-4998-83bf-8b0f4792a7c9}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.DeviceConfiguration
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{d43cc295-539f-5e64-77ce-78ef0e51825c}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrinterAssociationCommon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{8288e29d-0fc0-56b8-03ed-7fa253155f20}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  # Microsoft.Windows.Print.PrintUtil
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{ee6271a2-f93c-566a-b4a1-4eacdbce3ad3}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"


  # ETW providers - Level = 0xFFFFFFFF

  # Microsoft-Windows-PrintDialogs
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{27E76321-1E5B-4a82-BA0C-26E978F15072}' 0xFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-PrintDrivers
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{0E173F13-4266-4EFD-883C-79B24789B1BC}' 0xFFFFFFFF 0xFF -ets"
  # microsoft-windows-printservice-usbmon
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{7f812073-b28d-4afc-9ced-b8010f914ef6}' 0xFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-PrintService
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{747EF6FD-E535-4d16-B510-42C90F6873A1}' 0xFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-ProcessStateManager
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{d49918cf-9489-4bf1-9d7b-014d864cf71f}' 0xFFFFFFFF 0xFF -ets"
  # Microsoft-Windows-SystemEventsBroker
  Invoke-CustomCommand "logman update trace 'print-trace' -p '{B6BFCC79-A3AF-4089-8D4D-0EECB1B80779}' 0xFFFFFFFF 0xFF -ets"

  # Adding LPD service providers following discussion with engineer Luis Canete, who was a case related to LPD. 
  # We don't have them yet in the big list from PrintTrace.cmd, so adding extra via script parameter.
  if ($LPD) {
    # LPDSVC
    Invoke-CustomCommand "logman update trace 'print-trace' -p '{3EA31F33-8F51-481D-AEB7-4CA37AB12E48}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
    # Microsoft-Windows-Spooler-LPDSVC
    Invoke-CustomCommand "logman update trace 'print-trace' -p '{9F44821F-1FD9-46BF-A09A-C7F751159AAF}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  }

  # start RPC trace if selected
  if ($RPC) {
    Invoke-CustomCommand "reg add HKEY_LOCAL_MACHINE\Software\Microsoft\OLE\Tracing /v ExecutablesToTrace /t REG_MULTI_SZ /d * /f"
    Invoke-CustomCommand "logman create trace 'rpc-trace' -ow -o '$($TracesDir)RPC-Trace-$($env:COMPUTERNAME).etl' -p '{B46FA1AD-B22D-4362-B072-9F5BA07B046D}' 0xFFFFFFFFFFFFFFFF 0xFF -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 1024 -ets"
    Invoke-CustomCommand "logman update trace 'rpc-trace' -p '{A0C4702B-51F7-4ea9-9C74-E39952C694B8}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
    Invoke-CustomCommand "logman update trace 'rpc-trace' -p '{9474a749-a98d-4f52-9f45-5b20247e4f01}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
    Invoke-CustomCommand "logman update trace 'rpc-trace' -p '{bda92ae8-9f11-4d49-ba1d-a4c2abca692e}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
    Invoke-CustomCommand "logman update trace 'rpc-trace' -p '{6AD52B32-D609-4BE9-AE07-CE8DAE937E39}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
    Invoke-CustomCommand "logman update trace 'rpc-trace' -p '{F4AED7C7-A898-4627-B053-44A7CAA12FCD}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
    Invoke-CustomCommand "logman update trace 'rpc-trace' -p '{D8975F88-7DDB-4ED0-91BF-3ADF48C48E0C}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
  }
  if ($Network) {
    Invoke-CustomCommand "netsh trace start capture=yes scenario=netconnection maxsize=1024 report=disabled tracefile='$($TracesDir)NETCAP-$($env:COMPUTERNAME).etl'"
  }  
  if ($ProcMon) {
    Invoke-CustomCommand "start $($Root)\Procmon.exe '/AcceptEula /Quiet /Minimized /BackingFile $($TracesDir)$($env:COMPUTERNAME).PML'"
  }
  if ($PSR) {
    Invoke-CustomCommand "psr.exe /start /output $($TracesDir)PSR_$($env:COMPUTERNAME)_.zip /maxsc 99 /sc 1 /gui 1"
    Write-Host -ForegroundColor Yellow "WARNING: You selected the -PSR flag. This activates the Problem Steps Recorder tool, which automatically collects screenshots & information about steps performed (e.g: user left-clicked in text area of CMD.exe, user clicked close on Event Viewer, etc). Please avoid displaying sensitive information like passwords or other things."
  }

  Write-Log "Live captures started"
}

Function Stop-Traces {
  Write-Log "Stopping live captures..."
  Invoke-CustomCommand "logman stop 'Print-Trace' -ets"
  
  if ($RPC) {
    Invoke-CustomCommand "reg delete HKEY_LOCAL_MACHINE\Software\Microsoft\OLE\Tracing /v ExecutablesToTrace /f"
    Invoke-CustomCommand "logman stop 'rpc-trace' -ets"
  }
  if ($Network) {
    Invoke-CustomCommand "netsh trace stop"
  }  
  if ($ProcMon) {
    Invoke-CustomCommand "start $($Root)\Procmon.exe '/Terminate'"
  }
  if ($PSR) {
    Invoke-CustomCommand "psr.exe /stop"
  }

  Invoke-CustomCommand "tasklist /svc" -DestinationFile ("Traces\tasklist-$env:COMPUTERNAME.txt")
}

# Check parameters
# Reject execution if tracing parameters are specified without the main trace flag
if (!$Trace -and ($RPC -or $Network -or $PSR -or $ProcMon)) {
  Write-Host -ForegroundColor Yellow "WARNING: You selected a parameter for tracing, but did not specify the main -Trace flag. Please try again, including -Trace. Consider also checking out the examples, following the instructions in the REMARKS section below."
}
# Reject execution if -NoDumps is specified without -Logs, as it makes no sense
if (!$Logs -and $NoDumps) {
  Write-Host -ForegroundColor Yellow "WARNING: You selected the NoDumps parameter, but did not specify the main -Logs flag. Please try again, including -Logs. Consider also checking out the examples, following the instructions in the REMARKS section below."
}
# Display info, if no main parameters specified
if (!$Trace -and !$Logs) {
  Get-Help $MyInvocation.MyCommand.Definition
  exit
}

# Initialize some global variables & output folder
$resName = "$($ToolName -replace "Collect","Results")-" + $env:computername + "-" + $(get-date -f yyyyMMdd_HHmmss)
# Check if a destination folder was explicitly requested
if ($DataPath) {
  if (-not (Test-Path $DataPath)) {
    $answer = Read-Host "The destination folder ${DataPath} does not exist. Do you want to create it now? y/n"
    if ($answer -eq 'y') {
      New-Item -ItemType "directory" -Path $DataPath -Force | Out-Null
    }
    else {
      exit
    }
  }
  $global:resDir = $DataPath + "\" + $resName
}
else {
  $global:resDir = $global:Root + "\" + $resName
}
New-Item -ItemType "directory" -Path $global:resDir | Out-Null

$global:outfile = $global:resDir + "\script-output.txt"
$global:errfile = $global:resDir + "\script-errors.txt"
$global:RdrOut = " >>""" + $global:outfile + """"
$global:RdrErr = " 2>>""" + $global:errfile + """"
# $fqdn = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
# $OSVer = ([environment]::OSVersion.Version.Major) + ([environment]::OSVersion.Version.Minor) / 10

Write-Log $version

# License Agreement
if ($AcceptEula) {
  Write-Log "AcceptEula switch specified, silently continuing"
  $eula = ShowEULAIfNeeded $ToolName 2
}
else {
  $eula = ShowEULAIfNeeded $ToolName 0
  if ($eula -ne "Yes") {
    Write-Log "EULA declined, exiting"
    exit
  }
}
Write-Log "EULA accepted, continuing"

# Start traces if "selected"
if ($Trace) {
  $TracesDir = $global:resDir + "\Traces\"
  New-Item -itemtype directory -path $TracesDir | Out-Null
  Start-Traces
  Write-Host -ForegroundColor Cyan "Press ENTER to stop the live captures, after reproducing the issue..." 
  Read-Host
  Stop-Traces
  if (-not $Logs) {
    exit
  }
}

# Collect dumps if not disabled
if ($NoDumps) {
  Write-Log "We have the NoDumps flag, skipping collection of process dumps."
}
else {
  Write-Log "Collecting dump of the Spooler service"
  $pidSpooler = FindServicePid "Spooler"
  if ($pidSpooler) {
    CreateProcDump $pidSpooler $global:resDir "spoolsv"
  }

  Write-Log "Collecing the dumps of splwow64 if they exist"
  $list = get-process -Name "splwow64" -ErrorAction SilentlyContinue 2>>$global:errfile
  if (($list | Measure-Object).count -gt 0) {
    foreach ($proc in $list) {
      Write-Log ("Found splwow64.exe with PID " + $proc.Id)
      CreateProcDump $proc.Id $global:resDir "splwow64-$($proc.Id)"
    }
  }
  else {
    Write-Log "No splwow64 process found"
  }

  Write-Log "Collecing the dumps of PrintIsolationHost.exe processes"
  $list = get-process -Name "PrintIsolationHost.exe" -ErrorAction SilentlyContinue 2>>$global:errfile
  if (($list | Measure-Object).count -gt 0) {
    foreach ($proc in $list) {
      Write-Log ("Found PrintIsolationHost.exe with PID " + $proc.Id)
      CreateProcDump $proc.Id $global:resDir "PrintIsolationHost-$($proc.Id)"
    }
  }
  else {
    Write-Log "No PrintIsolationHost.exe process found"
  }
}

# Get printers information via PowerShell cmdlet
Get-Printer -ErrorAction SilentlyContinue 2>>$global:errfile | Out-File $global:resDir\Get-Printer.txt
Get-Printer -ErrorAction SilentlyContinue 2>>$global:errfile | Format-List * | Out-File $global:resDir\Get-Printer.txt -Append

# Export relevant User registry settings
Export-RegistryKey -KeyPath "HKCU:\Printers" -DestinationFile "reg-HKCU-printers.txt"
Export-RegistryKey -KeyPath "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Devices" -DestinationFile "reg-HKCU-devices.txt"
Export-RegistryKey -KeyPath "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\PrinterPorts" -DestinationFile "reg-HKCU-printer-ports.txt"
Export-RegistryKey -KeyPath "HKCU:\Printers\ConvertUserDevModesCount" -DestinationFile "reg-HKCU-printers-DevModesCount.txt"

# Export relevant Machine registry settings
Export-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print" -DestinationFile "reg-HKLM-Software-Print.txt"
Export-RegistryKey -KeyPath "HKLM:\Software\Policies\Microsoft\Windows NT\Printers" -DestinationFile "reg-HKLM-Software-Print-Policies.txt"
Export-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider" -DestinationFile "reg-HKLM-Software-CSR.txt"
Export-RegistryKey -KeyPath "HKLM:\System\CurrentControlSet\Control\Print" -DestinationFile "reg-HKLM-System-Print-service.txt"
Export-RegistryKey -KeyPath "HKLM:\System\CurrentControlSet\Control\DeviceClasses" -DestinationFile "reg-HKLM-System-DeviceClasses.txt"
Export-RegistryKey -KeyPath "HKLM:\System\CurrentControlSet\Control\DeviceContainers" -DestinationFile "reg-HKLM-System-DeviceContainers.txt"
Export-RegistryKey -KeyPath "HKLM:\System\CurrentControlSet\Enum\USBPRINT" -DestinationFile "reg-HKLM-System-Enum-USBPRINT.txt"
Export-RegistryKey -KeyPath "HKLM:\System\CurrentControlSet\Enum\SWD\PRINTENUM" -DestinationFile "reg-HKLM-System-Enum-SWD-PRINTENUM.txt"
Export-RegistryKey -KeyPath "HKLM:\System\DriverDatabase" -DestinationFile "reg-HKLM-System-DriverDatabase.txt"
Export-RegistryKey -KeyPath "HKLM:\DRIVERS\DriverDatabase" -DestinationFile "reg-HKLM-Drivers-DriverDatabase.txt"

# Export spooler service configuration key
Export-RegistryKey -KeyPath "HKLM:\System\CurrentControlSet\Services\Spooler" -DestinationFile "reg-HKLM-System-Services-Spooler.txt"

# Get any KIR overrides configured on this device
Export-RegistryKey -KeyPath "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" -DestinationFile "reg-KIR-Overrides.txt"

# Export relevant event logs
Export-EventLog -LogName "Application"
Export-EventLog -LogName "System"
Export-EventLog -LogName "Microsoft-Windows-PrintService/Operational"
Export-EventLog -LogName "Microsoft-Windows-PrintService/Admin"
Export-EventLog -LogName "Microsoft-Windows-PrintBRM/Admin"
Export-EventLog -LogName "Microsoft-Windows-DeviceSetupManager/Admin"
Export-EventLog -LogName "Microsoft-Windows-DeviceSetupManager/Operational"
Export-EventLog -LogName "Microsoft-Windows-TerminalServices-Printers/Admin"
Export-EventLog -LogName "Microsoft-Windows-TerminalServices-Printers/Operational"

# Grab also these Universal Print event logs if they exist
Export-EventLog -LogName "Microsoft-Windows-PrintConnector/Operational"
Export-EventLog -LogName "Microsoft-Windows-PrintConnectorUpdater/Admin"
Export-EventLog -LogName "Microsoft-Windows-PrintConnectorUpdater/Session"

# Get some additional information (Spooler service config, setupapi, netstat, ipconfig, gpresult)
Write-Log "Copying some relevant files from %windir%\INF"
New-Item -ItemType "directory" -Path "$global:resDir\Inf-SetupApi" -Force | Out-Null
New-Item -ItemType "directory" -Path "$global:resDir\Inf-OEM" -Force | Out-Null
Copy-Item "$env:windir\inf\Setupapi*" -Destination "$global:resDir\Inf-SetupApi" -Force
Copy-Item "$env:windir\Inf\oem*.inf" -Destination "$global:resDir\Inf-OEM" -Force

Invoke-CustomCommand -Command "sc.exe queryex spooler" -DestinationFile "Spooler_ServiceConfig.txt"
Invoke-CustomCommand -Command "netstat -anob" -DestinationFile "netstat.txt"
Invoke-CustomCommand -Command "ipconfig /all" -DestinationFile "ipconfig.txt"
Invoke-CustomCommand -Command "driverquery /v" -DestinationFile "drivers.txt"

Invoke-CustomCommand -Command "cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prndrvr.vbs -l" -DestinationFile "prndrvr_en.txt"
Invoke-CustomCommand -Command "cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prnmngr.vbs -l" -DestinationFile "prnmngr_en.txt"
Invoke-CustomCommand -Command "cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prnjobs.vbs -l" -DestinationFile "prnjobs_en.txt"
Invoke-CustomCommand -Command "cscript $env:windir\System32\Printing_Admin_Scripts\en-US\prnport.vbs -l" -DestinationFile "prnport_en.txt"
Invoke-CustomCommand -Command "tree $env:windir\Inf /f" -DestinationFile "tree_inf.txt"
Invoke-CustomCommand -Command "tree $env:windir\System32\DriverStore /f" -DestinationFile "tree_DriverStore.txt"
Invoke-CustomCommand -Command "tree $env:windir\System32\spool /f" -DestinationFile "tree_spool.txt"
Invoke-CustomCommand -Command "pnputil -e" -DestinationFile "pnputil_e.txt"
Invoke-CustomCommand -Command "pnputil /export-pnpstate ""${global:resDir}\pnputil_pnpstate.pnp"""

# Check version of some relevant print-related files
Write-Log "Collecting versions of some printing-related files"
FileVersion -Filepath ($env:windir + "\system32\localspl.dll") -Log $true
FileVersion -Filepath ($env:windir + "\system32\spoolsv.exe") -Log $true
FileVersion -Filepath ($env:windir + "\system32\win32spl.dll") -Log $true
FileVersion -Filepath ($env:windir + "\system32\spoolss.dll") -Log $true 
FileVersion -Filepath ($env:windir + "\system32\PrintIsolationProxy.dll") -Log $true 
FileVersion -Filepath ($env:windir + "\system32\winspool.drv") -Log $true 
FileVersion -Filepath ($env:windir + "\system32\spool\drivers\x64\3\unidrv.dll") -Log $true 

# Get running processes
Write-Log "Collecting details about running processes"
if (ListProcsAndSvcs) {
  CollectSystemInfoWMI
  ExecQuery -Namespace "root\cimv2" -Query "select * from Win32_Product" | Sort-Object Name | Format-Table -AutoSize -Property Name, Version, Vendor, InstallDate | Out-String -Width 400 | Out-File -FilePath ($global:resDir + "\products.txt")

  Write-Log "Collecting the list of installed hotfixes"
  Get-HotFix -ErrorAction SilentlyContinue 2>>$global:errfile | Sort-Object -Property InstalledOn -ErrorAction SilentlyContinue | Out-File $global:resDir\hotfixes.txt

  # Notice that for gpresult /h we don't specify a -Destinationfile, because it has a dedicated output file
  # no need to redirect the console output stream, which in this case doesn't work anyway
  Invoke-CustomCommand -Command "gpresult /h ""${global:resDir}\gpresult.html"""
  Invoke-CustomCommand -Command "gpresult /r" -DestinationFile "gpresult.txt"
}
else {
  Write-Log "WMI is not working"
  $proc = Get-Process | Where-Object { $_.Name -ne "Idle" }
  $proc | Format-Table -AutoSize -property id, name, @{N = "WorkingSet"; E = { "{0:N0}" -f ($_.workingset / 1kb) }; a = "right" },
  @{N = "VM Size"; E = { "{0:N0}" -f ($_.VirtualMemorySize / 1kb) }; a = "right" },
  @{N = "Proc time"; E = { ($_.TotalProcessorTime.ToString().substring(0, 8)) } }, @{N = "Threads"; E = { $_.threads.count } },
  @{N = "Handles"; E = { ($_.HandleCount) } }, StartTime, Path | 
  Out-String -Width 300 | Out-File -FilePath ($global:resDir + "\processes.txt")
  CollectSystemInfoNoWMI
}

# ZIP the current output folder & delete it
if ($global:resDir) {
  Write-Log "Zipping the results folder..."
  try {
    Compress-Archive -Path "$global:resDir" -DestinationPath "$global:resDir.zip" -Force
    Write-Host "Finished! Upload the ZIP archive to the secure case workspace." -ForegroundColor Green
  }
  catch {
    Write-Host "Finished! But couldn't create the ZIP archive, please do that manually & upload to the secure case workspace." -ForegroundColor Yellow
    exit
  }

  # Clean up the current results folder, to minimize disk space impact
  Remove-Item -Path "$global:resDir" -Recurse -Force
}
# SIG # Begin signature block
# MIInwQYJKoZIhvcNAQcCoIInsjCCJ64CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDuxe7Y6YD0iGWa
# KvsOzXh0x8M2MQP3Yn84a7QHhu/wEKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGaEwghmdAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJ5WHTyahRHShZSO7S0k/WaX
# V6eaa8YezV64wL0Aqy5DMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAepd1hTD/nHaNeX69DzcHJuSuS858iICMC/dDpqEmIQevDeBaBF1eT3Vu
# QWih4lbEA3hrYHK1m0eOligGJNFauHWFkgqNIP3KshrmmQbGuYTu/LPukGmfAHyY
# Ow8PKy9vG58GgMKrrI+hkhMydTJklyOzSb3dU0MWVoQz4Kl3TeWraUIF8XVTCo4F
# hg4kNGeUhC3a7UZfmSdLKO5VBuu1YP8UnWg4G3TR0/8ZSuckm/KcqcU2N78D9Drm
# gEpqYCq5WXj/jBuILgj8aieP6peMOB7iC2Iwqrnv9gtd7QO5zSRp8fupjA6EFPki
# pSiIB39/0cg+Z5nMwNlD/o10v3HLHaGCFyswghcnBgorBgEEAYI3AwMBMYIXFzCC
# FxMGCSqGSIb3DQEHAqCCFwQwghcAAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCApChsJNsA2P4/K2MyNglEqXMtjq5SIIMYQrqID3P+2KQIGZlddmE+O
# GBMyMDI0MDYxMjE1MDA0MS4wMDdaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OkQwODItNEJGRC1FRUJBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIRejCCBycwggUPoAMCAQICEzMAAAHcweCMwl9YXo4AAQAAAdwwDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMx
# MDEyMTkwNzA2WhcNMjUwMTEwMTkwNzA2WjCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpEMDgyLTRC
# RkQtRUVCQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAIvIsyA1sjg9kSKJzelrUWF5
# ShqYWL83amn3SE5JyIVPUC7F6qTcLphhHZ9idf21f0RaGrU8EHydF8NxPMR2KVNi
# AtCGPJa8kV1CGvn3beGB2m2ltmqJanG71mAywrkKATYniwKLPQLJ00EkXw5TSwfm
# JXbdgQLFlHyfA5Kg+pUsJXzqumkIvEr0DXPvptAGqkdFLKwo4BTlEgnvzeTfXukz
# X8vQtTALfVJuTUgRU7zoP/RFWt3WagahZ6UloI0FC8XlBQDVDX5JeMEsx7jgJDdE
# nK44Y8gHuEWRDq+SG9Xo0GIOjiuTWD5uv3vlEmIAyR/7rSFvcLnwAqMdqcy/iqQP
# MlDOcd0AbniP8ia1BQEUnfZT3UxyK9rLB/SRiKPyHDlg8oWwXyiv3+bGB6dmdM61
# ur6nUtfDf51lPcKhK4Vo83pOE1/niWlVnEHQV9NJ5/DbUSqW2RqTUa2O2KuvsyRG
# MEgjGJA12/SqrRqlvE2fiN5ZmZVtqSPWaIasx7a0GB+fdTw+geRn6Mo2S6+/bZEw
# S/0IJ5gcKGinNbfyQ1xrvWXPtXzKOfjkh75iRuXourGVPRqkmz5UYz+R5ybMJWj+
# mfcGqz2hXV8iZnCZDBrrnZivnErCMh5Flfg8496pT0phjUTH2GChHIvE4SDSk2hw
# WP/uHB9gEs8p/9Pe/mt9AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQU6HPSBd0OfEX3
# uNWsdkSraUGe3dswHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBANnrb8Ewr8eX/H1s
# Kt3rnwTDx4AqgHbkMNQo+kUGwCINXS3y1GUcdqsK/R1g6Tf7tNx1q0NpKk1JTupU
# JfHdExKtkuhHA+82lT7yISp/Y74dqJ03RCT4Q+8ooQXTMzxiewfErVLt8Wefebnc
# ST0i6ypKv87pCYkxM24bbqbM/V+M5VBppCUs7R+cETiz/zEA1AbZL/viXtHmryA0
# CGd+Pt9c+adsYfm7qe5UMnS0f/YJmEEMkEqGXCzyLK+dh+UsFi0d4lkdcE+Zq5JN
# jIHesX1wztGVAtvX0DYDZdN2WZ1kk+hOMblUV/L8n1YWzhP/5XQnYl03AfXErn+1
# Eatylifzd3ChJ1xuGG76YbWgiRXnDvCiwDqvUJevVRY1qy4y4vlVKaShtbdfgPyG
# eeJ/YcSBONOc0DNTWbjMbL50qeIEC0lHSpL2rRYNVu3hsHzG8n5u5CQajPwx9Pzp
# sZIeFTNHyVF6kujI4Vo9NvO/zF8Ot44IMj4M7UX9Za4QwGf5B71x57OjaX53gxT4
# vzoHvEBXF9qCmHRgXBLbRomJfDn60alzv7dpCVQIuQ062nyIZKnsXxzuKFb0TjXW
# w6OFpG1bsjXpOo5DMHkysribxHor4Yz5dZjVyHANyKo0bSrAlVeihcaG5F74SZT8
# FtyHAW6IgLc5w/3D+R1obDhKZ21WMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
# mQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNh
# dGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1
# WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjK
# NVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhg
# fWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJp
# rx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/d
# vI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka9
# 7aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKR
# Hh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9itu
# qBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyO
# ArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItb
# oKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6
# bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6t
# AgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQW
# BBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacb
# UzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYz
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnku
# aHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIA
# QwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2
# VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEw
# LTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYt
# MjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/q
# XBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6
# U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVt
# I1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis
# 9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTp
# kbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0
# sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138e
# W0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJ
# sWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7
# Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0
# dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQ
# tB1VM1izoXBm8qGCAtYwggI/AgEBMIIBAKGB2KSB1TCB0jELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxh
# bmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpE
# MDgyLTRCRkQtRUVCQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUAHDn/cz+3yRkIUCJfSbL3djnQEqaggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOoTpw0wIhgPMjAyNDA2MTIxMjQ4MTNaGA8yMDI0MDYxMzEyNDgxM1owdjA8Bgor
# BgEEAYRZCgQBMS4wLDAKAgUA6hOnDQIBADAJAgEAAgFGAgH/MAcCAQACAhEtMAoC
# BQDqFPiNAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEA
# AgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAPvJGnJSZLNo56HeJ
# 3cyRbGz7USSNr/JjnVlpx6BGU156d5HHnv3Q0iraNXqCwSPAz0HZDlmvJ0a1rrdd
# PIIVo5bRPk6TXA7juDsAGgkK1gt7DGttFGfBNm2QC/4NEdun8kT3Crg95ldiveHH
# Z6N/LIAiG9IDmQSptE5EQ4zM0GkxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAdzB4IzCX1hejgABAAAB3DANBglghkgBZQME
# AgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJ
# BDEiBCDigm6LK+rmbz6ccS7mqMLku4yqpthAwKLXGDbV7UK+bDCB+gYLKoZIhvcN
# AQkQAi8xgeowgecwgeQwgb0EIFOnF4pq2UQ/jLypnOO5YvQ67QirEQsOFfZMvKXE
# gg03MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHc
# weCMwl9YXo4AAQAAAdwwIgQgSfMVTLRnPEpnLjm71akIKYjbspPV12GU+ZBoRqI9
# 90gwDQYJKoZIhvcNAQELBQAEggIAWihZ/4QF7lSjnIC0knximto5euIXs3jQvUTa
# 1MDr4BBd70ba6cJY2kf3++Qvz/5fzTNU+bfVcA55co/yacUMRILh+q7u/qfZLHsM
# RarjKp+mbhzSXaJQcv0lAoi4/Abe45RJkapv8C1ndFqPr1dnbzTGLu8ACwSRkU3G
# HKAwffBVd2+kPkjrX9RwwnqNAfzwFJIRPb1SpXJSQQcgPG0dnghMFyQAtJK3fsaR
# WRRb9uvDdZdRFaNSeJ/XVuqyw4bXMjYsXjUICRpUndQcYIkSf0uBvvofL94MIvzu
# jLDm743SszsXUblOz0geviNaQAfIP0x081Els+MTa6/hw+lgKPejRcd6r9gC6BhZ
# QR357yxL4W9ilOapKsIkvztTTz2Jg52ZGYhmEq9OLAb6WxJrAGlBertF85vg3GGE
# ZyAw+3jif1GYXmUZskoOVbkf7AZAGBsqh0dqQ2f3ZuGcJCHS0s19b/duMoHh5puJ
# c75TV2mD4vy1PD7psjXCVqQ9xtyxpBUQlx6QD0gz1aPSbZNe0lpA2OpsQ5b9klNG
# 7lPOg2FT/R58WsTMciHdA+s7MAY/Qd9BL5NK5IEs61U2DYvjclbbCWTUkUnMugcV
# JpBoq7u5SjxHAELKKN8VKf0pUkykSzoFEk1XCBfAZD74qIhv7VdNWjeUKbPX2Ael
# Myw9OBs=
# SIG # End signature block
