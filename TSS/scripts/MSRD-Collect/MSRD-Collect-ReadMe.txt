==================
 IMPORTANT NOTICE
==================
 
This script is designed to gather information to assist Microsoft Customer Support Services (CSS) in troubleshooting issues you may be experiencing with Microsoft Remote Desktop solutions.

The collected data may contain Personally Identifiable Information (PII) and/or sensitive data, such as (but not limited to) IP addresses, PC names and user names. The script will save the collected data in a subfolder and compress the results into a ZIP file. Neither the folder nor the ZIP file is automatically sent to Microsoft.

You can send the ZIP file to Microsoft CSS using a secure file transfer tool. Please discuss this with your support professional and address any concerns you may have.

Find our privacy statement here: https://privacy.microsoft.com/en-US/privacystatement

============================================================================================================
 Table of Contents

  1. About MSRD-Collect
  2. Usage instructions
  3. Available command line parameters
  4. Advanced GUI Mode
  5. Remote Mode
  6. No internet connection available
  7. User Context (Collecting data related to a user other than the admin running the script)
  8. Presets
  9. Data collection process (What data is collected)
 10. MSRD-Diag
 11. Scheduled Tasks to run Diagnostics
 12. Tool Author
 13. Feedback
============================================================================================================


===================================
 1. About MSRD-Collect (v240517.4)
===================================

Are you experiencing issues with your Azure Virtual Desktop (AVD), Remote Desktop Services (RDS) machines, or Remote Desktop Protocol (RDP) connections? Do you find it challenging to locate the relevant logs or data on your machines for troubleshooting these issues? Or perhaps you're curious about what data could be useful for this purpose?

Maybe you're seeking a straightforward, scripted method to gather the pertinent data for troubleshooting remote desktop related issues from your machines? Or you might want to verify if your AVD or RDS machines are correctly configured or if they're encountering any known remote desktop related problems?

If you answered 'yes' to any of these questions, this tool is designed to assist you significantly.


MSRD-Collect is a PowerShell script designed to simplify the process of data collection for troubleshooting Azure Virtual Desktop, Remote Desktop Services, and Windows 365 Cloud PC related issues. It provides a convenient method for submitting and following quick & easy action plans.

The collected data can assist in troubleshooting a variety of remote desktop related issues, from deployment and configuration to session connectivity, profile (including FSLogix), media optimization for Teams, MSIX App Attach, Remote Assistance/Quick Assist/Remote Help, and more. Please note that some scenarios are only applicable for AVD deployments.

The MSRD-Diag.html diagnostics report, included in MSRD-Collect, provides a comprehensive overview of the system to quickly identify potential known issues, significantly speeding up the troubleshooting process.


=======================
 2. Usage instructions
=======================

Run the script on Windows source or target machines as required by the scenario you're investigating.

The script requires at least PowerShell version 5.1 and to be run with elevated permissions to gather all required data.

Please note that running MSRD-Collect in PowerShell ISE is not supported. Instead, execute the script in a standard elevated/admin PowerShell window.

For optimal results, execute the script while logged into the machine with a Domain Admin account and run PowerShell in the same Domain Admin account's context. A local Administrator account can also be used, but the script will lack permissions to gather domain-related information. If you're logged in with a different account than the one running the script, the gpresult collection may fail.


The script has multiple module (.psm1) files located in a "Modules" folder. This folder, along with its underlying .psm1 files, must remain in the same folder as the main MSRD-Collect.ps1 file for the script to function correctly. Download the MSRD-Collect.zip package from the official public download location (https://aka.ms/MSRD-Collect) and extract all files from it, not just the MSRD-Collect.ps1. The script will import the necessary module(s) dynamically when specific data is being invoked. Manual import of the modules is not required.

Depending on the OS and security settings of the computer where you downloaded the script, the .zip file may be "blocked" by default. If you unzip and run this blocked version, PowerShell may prompt you to confirm if you want to run the script or each of its modules. To avoid this, before unzipping the MSRD-Collect.zip file, go to the zip file's Properties, select 'Unblock' and 'Apply'. Afterward, you can unzip the script and use it.

Alternatively, you can unblock the main script file using the PowerShell command line:
	Unblock-File -Path C:\<path to the extracted script>\MSRD-Collect.ps1

MSRD-Collect.ps1 will also attempt to unblock its module files automatically at the start of the main script.


The script can be used in two ways:

	1) With a GUI: Start the script by running ".\MSRD-Collect.ps1" in an elevated PowerShell window and follow the on-screen guide. There are two GUI modes you can use: "Advanced" and "Lite".

	 - In the "Advanced" version, you can choose between different display languages: Arabic, Chinese, Czech, Dutch, English (default), French, German, Hungarian, Italian, Japanese, Portuguese, Romanian, Spanish, Turkish. These languages pertain to the text displayed in the UI. Machine types, Scenario names, collected data/diagnostics results, and potential error messages encountered during script usage are displayed in English (or in the native language of the Operating System where applicable).
    
		The Advanced Mode also provides the ability to configure various script parameters and access a range of useful documentation.

		In this mode, you can also collect data from one or more computers remotely. For more details, refer to the "Remote Mode" section below.
	
		To adjust the font size in any of the output windows, use the 'CTRL + Mouse Scroll' combination.

		For more comprehensive instructions on data collection, refer to the "Advanced GUI Mode" section below.

	  - In the "Lite" version, you have only the basic options to select the data collection scenarios and run the data collection/diagnostics. For all other aspects (e.g., user context, output location, etc.), the script uses default settings.

	2) Without a GUI: Use any combination of one or more scenario-based command line parameters, which will initiate the corresponding data collection automatically. See the available command line parameters and usage examples below.


When launched, the script will:

	a) Display the Microsoft Diagnostic Tools End User License Agreement (EULA). You must accept the EULA before you can continue using the script.

	Once you accept the EULA, this acceptance is stored in the Windows Registry under the key HKCU\Software\Microsoft\CESDiagnosticTools. This means that you won't be prompted to accept the EULA again in future uses of the script, as long as this registry key remains in place.
	If you want to accept the EULA silently, you can use the -AcceptEula command line parameter when running the script. This can be useful in automated or scripted scenarios where you don't want to manually accept the EULA each time.
	It's important to note that this is a per-user setting. This means that each user who runs the script will need to accept the EULA once. If a different user runs the script on the same machine, they will be prompted to accept the EULA, even if another user has already accepted it.

	b) Display an internal notice that the admin needs to confirm if they agree and want to continue with the data collection.


If you find any data missing that the script should normally collect (see "Data being collected"), check the content of "*_MSRD-Collect-Log.txt" and "*_MSRD-Collect-Errors.txt" files for more information.

Once the script has started, p​​​lease read the "IMPORTANT NOTICE" message and confirm if you agree to continue with the data collection.

Depending on the amount of data that needs to be collected, the script may need to run for up to a few minutes. During this time, the operating system's built-in commands run by MSRD-Collect might not respond or take a long time to complete. Please be patient, as the tool should still be running in the background. If it is still stuck in the same place for over 5 minutes, try to close/kill it and collect data again.


PowerShell ExecutionPolicy
--------------------------

If the script does not start due to execution restrictions, then in an elevated PowerShell console run:

	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope Process

and verify with "Get-ExecutionPolicy -List" that no ExecutionPolicy with higher precedence is blocking execution of this script. The script is digitally signed with a Microsoft Code Sign certificate.

After that, run the MSRD-Collect script again.


======================================
 3. Available command line parameters
======================================

Scenario-based parameters:

	"-Core" 	 	  - Collects Core data and runs Diagnostics.

	"-Profiles" 	 	  - Collects Core data, Profiles data, and runs Diagnostics.

	"-Activation" 	 	  - Collects Core data, OS Licensing/Activation data, and runs Diagnostics.

	"-MSRA" 	 	  - Collects Core data, Remote Assistance data, and runs Diagnostics.

	"-SCard" 	 	  - Collects Core data, Smart Card/RDGW data, and runs Diagnostics.

	"-IME" 		 	  - Collects Core data, input method data, and runs Diagnostics.

	"-Teams" 	 	  - Collects Core data, Teams data, and runs Diagnostics (AVD Only).

	"-AppAttach"  	  - Collects Core data, App Attach data, and Runs Diagnostics (AVD Only).

	"-HCI" 		 	  - Collects Core data, Azure Stack HCI data, and runs Diagnostics (AVD Only).

	"-DumpPID <pid>" 	  - Generates a process dump based on the provided PID. This dump collection is part of the 'Core' dataset and works with any other scenario parameter except '-DiagOnly'.

	"-NetTrace" 	 	  - Collects a netsh network trace. If selected, it will always run first, before any other data collection/diagnostics.

	"-DiagOnly" 	 	  - The script will skip all data collection and will only run the diagnostics part (even if other parameters have been specified).
	

Other parameters:

	"-Machine" 		  - Indicates the type of machine from where data is collected. This is a mandatory parameter when not using the GUI. Based on the provided value, only data specific to that machine type will be collected. Available values are: "isAVD" (Azure Virtual Desktop), "isRDS" (Remote Desktop Services or direct RDP connections), "isW365" (Windows 365 Cloud PC).

	"-Role"   		  - Indicates the role of the machine in the selected remote desktop solution. This is a mandatory parameter when not using the GUI. Based on the provided value, only data specific to that role will be collected. Available values are: "isSource" (Source machine used to connect from, by using a Remote Desktop client), "isTarget" (Target machine used to connect to or intermediate machine in the connection chain).

	"-AcceptEula" 		  - Silently accepts the Microsoft Diagnostic Tools End User License Agreement.
	
	"-AcceptNotice" 	  - Silently accepts the internal Important Notice message on data collection.

	"-OutputDir <path>" 	  - ​​​​​​Specifies a custom directory where to store the collected files. By default, if this parameter is not specified, the script will store the collected data under "C:\MS_DATA". If the path specified does not exit, the script will attempt to create it.

	"-UserContext <username>" - Defines the context in which some of the data will be collected. MSRD-Collect needs to be run with elevated priviledges to be able to collect all the relevant data, which can sometimes be an inconvenient when troubleshooting issues occuring only with non-admin users or even different admin users than the one running the script, where you need data from the affected user's profile, not the admin's profile running the script. With this option, you can specify that some data should be collected from another user's context (e.g. RDClientAutoTrace, Teams settings). This does not apply to collecting HKCU registry keys from the other user. For now, HKCU output will still reflect the settings of the admin user running the script.
	
	"-SkipAutoUpdate" 	  - Skips the automatic update check on launch for the current instance of the script (can be used for both GUI and command line mode).

	"-LiteMode" 		  - The script will open with a GUI in "Lite Mode" regardless of the Config\MSRDC-Config.cfg settings.

	"-AssistMode" 		  - Accessibility option. The script will read out loud some of the key information and steps performed during data collection/diagnostics.

	"-SilentMode"		  - The script will not display verbose output during data collection.
 

You can combine multiple command line parameters to build your desired dataset.

Usage examples with parameters:

To collect only Core data (excluding Profiles, Teams, MSIX App Attach, MSRA, Smart Card, IME) from a machine that is used as the 'source/client' to connect to an AVD deployment:

	.\MSRD-Collect.ps1 -Machine isAVD -Role isSource -Core

To collect Core + Profiles + MSIX App Attach + IME data ('Core' is collected implicitly when other scenarios are specified) from an AVD host:

	.\MSRD-Collect.ps1 -Machine isAVD -Role isTarget -Profiles -AppAttach -IME

To only run Diagnostics without collecting Core or scenario based data from an RDS server (or a target machine of a non-AVD remote connection):

	.\MSRD-Collect.ps1 -Machine isRDS -Role isTarget -DiagOnly

To store the resulting files in a different folder than C:\MS_DATA:

	.\MSRD-Collect.ps1 -OutputDir "E:\AVDdata\"

To collect Core data and also generate a process dump for a running process, based on the process PID (e.g. in this case a process with PID = 13380), from an AVD host:

	.\MSRD-Collect.ps1 -Machine isAVD -Role isTarget -Core -DumpPID 13380

To start the script with the GUI (all additional parameters can be set also via the UI):

	.\MSRD-Collect.ps1


======================
 4. Advanced GUI Mode
======================

This guide is also displayed in the UI when you start the script in Advanced GUI Mode.

	Step 1: [Optional] In the 'Computer(s)' field, enter one or more computer names (NetBIOS or FQDN), separated by a semicolon, from which you want to collect data.
		The local computer's name is used as the default value. If multiple machines are specified, the data will be collected from each computer sequentially.

	Step 2: Select the context/environment in which the machine(s) operate:

		AVD		  - Azure Virtual Desktop
		RDS		  - Remote Desktop Services or direct (non-AVD/non-W365) RDP connection
		W365		  - Windows 365 Cloud PC

	Step 3: Select the role of the machine(s) within the given context/environment:

		Source		  - Source machine from where you connect to other machines using a Remote Desktop client
		Target		  - Target machine to which you connect to or any RDS server in an RDS deployment

For data collection:

	Step 4a: [Optional] Select one or more available scenarios:

		Profiles	  - Collect data for troubleshooting 'User Profiles' issues
		Activation	  - Collect data for troubleshooting 'OS Licensing/Activation' issues
		MSRA		  - Collect data for troubleshooting 'Remote Assistance', 'Quick Assist' or 'Remote Help' issues
		SCard	          - Collect data for troubleshooting 'Smart Card' issues
		IME		  - Collect data for troubleshooting 'Input Method' issues
		Teams		  - Collect data for troubleshooting 'Teams Media Optimization' issues (AVD/W365 only)
		AppAttach	  - Collect data for troubleshooting 'App Attach' issues (AVD only)
		HCI		  - Collect data for troubleshooting 'Azure Stack HCI' issues (AVD only)
		DumpPID		  - Collect a Process Dump of an existing process
		NetTrace	  - Collect a network trace (netsh)
		DiagOnly	  - Generate a Diagnostics report only

	Step 5a: Click the 'Start' button when ready. Data collection/diagnostics may take several minutes. 

For live diagnostics (only available for the local computer):

	Step 4b: Select the 'LiveDiag' option.

	Step 5b: Select the desired diagnostics category tab.

	Step 6: Click on the desired button within the selected tab to run the coresponding diagnostics check.


================
 5. Remote Mode
================

In the "Advanced" GUI mode, you can specify one or more computer names (NetBIOS or FQDN) from which you want to collect data.

By default, the script uses the name of the local computer where it was initiated. You can modify this by adjusting the value in the 'Computer(s)' text box.

Requirements for remote data collection:

	• Network connectivity between the local and remote machines
	• Compatible PowerShell version on both the local and remote machines (at least PowerShell 5.1)
	• WinRM enabled and properly configured on both the local and remote machines
	• Windows Firewall or any third-party firewalls should allow WinRM traffic
	• Administrative privileges on both the local and remote machines to establish a remote PowerShell session
	• Implicit acceptance of the EULA and Notice for running the script on all the remote machines
	• When specifying multiple computer names, separate them using a semicolon (e.g.: computer1; computer2; computer3)
	
In Remote Mode, the script will:

	• Copy itself to the target computer under C:\MS_DATA\
	• Initiate a Remote PowerShell session to the target computer
		o The script will first try to create the session using the current admin user privileges. If that fails, it will prompt for admin credentials for the remote computer
	• Execute itself on the target computer, redirecting the text output to the local GUI (the collected data remain on the remote computer, only the displayed messages are sent to the local GUI)
	• Open a File Explorer window when done, pointing to the location of the collected data on the remote computer (\\<RemoteComputer>\C$\MS_DATA\)
	
When specifying multiple computer names, the script executes synchronously, collecting data from each computer one at a time in the given order.
If any of the provided computers is not reachable or a remote PowerShell session cannot be established to it, the script will display an error message and move on to the next computer in the list.
	
This feature is using 'Get-Credential' to ask for the credentials required to access the remote computer.
Credentials are not saved by the script and are only used to establish the remote PowerShell session.
Get-Credential stores the credentials in a PSCredential object and the password as a SecureString.
For more information about SecureString data protection, see: https://learn.microsoft.com/en-us/dotnet/api/system.security.securestring?view=net-7.0#how-secure-is-securestring
	
Current limitations (may be lifted in future releases):

	• This feature is only available through the advanced UI
	• This feature is available for AVD and W365 scenarios only - when selecting 'RDS' the 'Computer(s)' text box is disabled and defaults to the local computer name
	• Remote LiveDiag is not available - when selecting 'LiveDiag' the 'Computer(s)' text box is disabled and defaults to the local computer name
	• Any filtering done through the 'Configure data collection' or 'Configure diagnostics' options do not apply to remote data collection/diagnostics
	• While collecting data on a remote computer, the progress bar indicator is only available in the local PowerShell console window, not the MSRD-Collect UI


=====================================
 6. No internet connection available
=====================================

By default, the script checks for updates upon launch and prompts you to download the latest version if available.

If the computer running the script lacks internet access, the script won't be able to check for updates or download the latest version. In this scenario, the script will display a warning message and a popup window asking if you'd like to disable the automatic update check.

If you select 'Yes', the script will no longer check for updates in future launches. Regardless of your selection, the script will continue with the current execution.


=============================================================================================
 7. User Context (Collecting data related to a user other than the admin running the script)
=============================================================================================

MSRD-Collect requires elevated privileges to collect all relevant data. Therefore, when collecting certain user-specific data (e.g., AVD Desktop client traces, Teams settings), the script, by default, collects data from the admin user's profile who launched the script.

This approach works as long as the admin user can reproduce the issue. However, when troubleshooting issues occurring only with non-admin users or different admin users, you need data from the affected user's profile, not the admin's profile running the script. To do this, you need to specify the user context within the script:
	• through the advanced UI ('Tools\Set user context' option)
	• or when launching the script with command line parameters, add: "-UserContext <username>"

For example, if you run the script as 'adminA', it will look for user-specific logs inside the profile of 'adminA'. If the issue is with 'userB', then:
	• 'userB' would need to be an admin too, and start the script as 'userB'
	• or if that's not possible and you have to start the script as 'adminA', then change the user context within the script to 'userB', either through the UI or command line parameter

This will result in the script still running as admin (e.g., 'adminA'), but it will collect the user-specific logs/traces only from the profile folder of the specified user (e.g., 'userB').

Note: This does not apply to collecting HKCU registry keys or gpresult from the other user. Currently HKCU and gpresult output will still be the ones from the admin user who launched the script.

Important: The profile folder of 'userB' has to exist on the system. If it doesn't exist, the script will display an error message and will not continue with the data collection.


============
 8. Presets
============

When using the advanced UI, if you're uncertain about which options to choose (machine type, machine role, scenarios), consider using the 'Presets' menu. This menu offers predefined settings tailored for specific troubleshooting scenarios.

If a preset aligns with the scenario you're troubleshooting, simply select it, and the script will automatically configure the necessary options for you. Once a preset is selected, all you need to do is click the 'Start' button to initiate the data collection/diagnostics process.


=====================================================
 9. Data collection process (What data is collected)
=====================================================

The data gathered by the script is stored in a subfolder within C:\MS_DATA\. Upon completion of the data collection, the results are compressed into a .zip file, also located under C:\MS_DATA\. Please note that no data is automatically transmitted to Microsoft.

You have the option to modify the default C:\MS_DATA\ location. This can be done either through the GUI (navigate to Tools/Set Output Location...) or by using the command line parameter "-OutputDir <location>".

The script is designed to collect data relevant to the selected machine type (AVD, RDS or W365) and role (Source or Target). The following lists detail all the data that can be collected by the available scenarios, irrespective of the selected machine type and role.

Data collected in the "Core" scenario:

	• Log files
		o C:\Packages\Plugins\Microsoft.Azure.ActiveDirectory.AADLoginForWindows\
		o C:\Packages\Plugins\Microsoft.Compute.JsonADDomainExtension\<version>\Status\
		o C:\Packages\Plugins\Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent\<version>\Status\
		o C:\Packages\Plugins\Microsoft.Powershell.DSC\<version>\Status\​​​​​​​
		o %programfiles%\Microsoft RDInfra\AgentInstall.txt
		o %programfiles%\Microsoft RDInfra\​GenevaInstall.txt
		o %programfiles%\Microsoft RDInfra\MsRdcWebRTCSvc.txt
		o %programfiles%\Microsoft RDInfra\MsRdcWebRTCSvcMsiInstall.txt
		o %programfiles%\Microsoft RDInfra\MsRdcWebRTCSvcMsiUninstall.txt
		o %programfiles%\Microsoft RDInfra\​SXSStackInstall.txt
		o %programfiles%\Microsoft RDInfra\WVDAgentManagerInstall.txt
		o %programfiles%\MsRDCMMRHost\MsRDCMMRHostInstall.log
		o <default user profile location>\AgentInstall.txt
		o <default user profile location>\AgentBootLoaderInstall.txt
		o <default user profile location>\<username running the script>\AppData\Local\Temp\RDMSUI-trace.log
		o %windir%\debug\NetSetup.log
		o %windir%\Temp\MsRDCMMRHostInstall.log
		o %windir%\Temp\ScriptLog.log
		o C:\WindowsAzure\Logs\MonitoringAgent.log
		o C:\WindowsAzure\Logs\TransparentInstaller.log
		o C:\WindowsAzure\Logs\WaAppAgent.log
		o C:\WindowsAzure\Logs\Plugins\
		o %windir%\Logs\RDMSDeploymentUI.txt
		o %windir%\System32\tssesdir\*.xml
		o %windir%\web\rdweb\App_Data\rdweb.log
		• %windir%\inf\setupapi.dev.log and %windir%\inf\setupapi.app.log
		• %windir%\panther\Setupact.log
		• %windir%\Logs\CBS\CBS.log
		• CCM client logs from C:\Windows\CCM\Logs\ (all, except the ones containing '*SCClient*', '*SCNotify*', '*SCToastNotification*')
	• Local group membership information
		o Remote Desktop Users
		o RDS Management Servers (if available and 'RDS' machine type selected)
		o RDS Remote Access Servers (if available and 'RDS' machine type selected)
		o RDS Endpoint Servers (if available and 'RDS' machine type selected)
	• The content of the "<default user profile location>\%username%\AppData\Local\Temp\DiagOutputDir\RdClientAutoTrace" folder (available on devices used as source clients to connect to AVD hosts) from the past 5 days, containing:
		o AVD remote desktop client connection ETL traces
		o AVD remote desktop client application ETL traces
		o AVD remote desktop client upgrade log (MSI.log)
	• "%localappdata%\rdclientwpf\ISubscription.json" file
	• "Qwinsta /counter" output
	• DxDiag output in .txt format with no WHQL check
	• Geneva, Remote Desktop and Remote Assistance Scheduled Task information
	• "Azure Instance Metadata service endpoint" request info
	• Convert existing .tsf files on AVD hosts from under "%windir%\System32\config\systemprofile\AppData\Roaming\Microsoft\Monitoring\Tables" into .csv files and collect the resulting .csv files
	• AVD Monitoring Agent environment variables
	• Output of "%programfiles%\Microsoft Monitoring Agent\Agent\TestCloudConnection.exe"
	• "dsregcmd /status" output
	• AVD Services API health check (BrokerURI, BrokerURIGlobal, DiagnosticsUri, BrokerResourceIdURIGlobal)
	• Event Logs
		o Application
		o Microsoft-Windows-AAD/Operational
		o Microsoft-Windows-AppLocker/EXE and DLL
		o Microsoft-Windows-AppLocker/Packaged app-Execution
		o Microsoft-Windows-AppLocker/Packaged app-Deployment
		o Microsoft-Windows-AppLocker/MSI and Script
		o Microsoft-Windows-AppModel-Runtime/Admin
		o Microsoft-Windows-AppReadiness/Admin
		o Microsoft-Windows-AppReadiness/Operational
		o Microsoft-Windows-AppXDeployment/Operational
		o Microsoft-Windows-AppXDeploymentServer/Operational
		o Microsoft-Windows-AppXDeploymentServer/Restricted
		o Microsoft-Windows-AppxPackaging/Operational
		o Microsoft-Windows-CAPI2/Operational
		o Microsoft-Windows-Diagnostics-Performance/Operational
		o Microsoft-Windows-DSC/Operational
		o Microsoft-Windows-GroupPolicy/Operational
		o Microsoft-Windows-HelloForBusiness/Operational
		o Microsoft-Windows-Kernel-PnP/Device Configuration
		o Microsoft-Windows-Kernel-PnP/Device Management
		o Microsoft-Windows-NetworkProfile/Operational
		o Microsoft-Windows-NTLM/Operational
		o Microsoft-Windows-PowerShell/Operational
		o Microsoft-Windows-RemoteDesktopServices
		o Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV/Admin
		o Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV/Operational
		o Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Admin
		o Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational
		o Microsoft-Windows-RemoteDesktopServices-SessionServices/Operational
		o Microsoft-Windows-Resource-Exhaustion-Detector/Operational
		o Microsoft-Windows-Shell-Core/Operational
		o Microsoft-Windows-SMBClient/Connectivity
		o Microsoft-Windows-SMBClient/Operational
		o Microsoft-Windows-SMBClient/Security
		o Microsoft-Windows-SMBServer/Connectivity
		o Microsoft-Windows-SMBServer/Operational
		o Microsoft-Windows-SMBServer/Security
		o Microsoft-Windows-TaskScheduler/Operational
		o Microsoft-Windows-TerminalServices-LocalSessionManager/Admin
		o Microsoft-Windows-TerminalServices-LocalSessionManager/Operational
		o Microsoft-Windows-TerminalServices-PnPDevices/Admin
		o Microsoft-Windows-TerminalServices-PnPDevices/Operational
		o Microsoft-Windows-TerminalServices-RDPClient/Operational
		o Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin
		o Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational
		o Microsoft-Windows-TerminalServices-TSV-VmHostAgent/Admin
		o Microsoft-Windows-TerminalServices-TSV-VmHostAgent/Operational
		o Microsoft-Windows-User Device Registration/Admin
		o Microsoft-Windows-WER-Diagnostics/Operational
		o Microsoft-Windows-WinINet-Config/ProxyConfigChanged
		o Microsoft-Windows-Winlogon/Operational
		o Microsoft-Windows-WinRM/Operational
		o Microsoft-Windows-WMI-Activity/Operational
		o Microsoft-Windows-Workplace Join/Admin
		o Microsoft-WindowsAzure-Diagnostics/Bootstrapper
		o Microsoft-WindowsAzure-Diagnostics/GuestAgent
		o Microsoft-WindowsAzure-Diagnostics/Heartbeat
		o Microsoft-WindowsAzure-Diagnostics/Runtime
		o Microsoft-WindowsAzure-Status/GuestAgent
		o Microsoft-WindowsAzure-Status/Plugins
		o PowerShellCore/Operational
		o Security
		o Setup
		o System
	• Registry keys
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\MSRDC
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\RdClientRadc
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Remote Desktop​
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Terminal Server Client
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings
		o HKEY_CURRENT_USER\SOFTWARE\Policies
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Azure\DSC
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSRDC
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Ole
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDAgentBootLoader
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMonitoringAgent
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSLicensing
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Ole
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Terminal Server Client
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\TermServLicensing
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies
		o ​​​​​​​HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
		o ​​​​​​​HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\TerminalServerGateway
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
		o HKEY_LOCAL_MACHINE\SOFTWARE\Policies
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CoDeviceInstallers
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Cryptography
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server​​
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\TERMINPUT_BUS
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\TERMINPUT_BUS_SXS
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services
		o HKEY_LOCAL_MACHINE\SYSTEM\DriverDatabase\DeviceIds\TS_INPT
		o HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings
	• Filtered NPS event logs if available, when the RD Gateway role is detected
	• Networking information (firewall rules, ipconfig /all, network profiles, netstat -anob, proxy configuration, route table, winsock show catalog, Get-NetIPInterface, netsh interface Teredo show state, public IP related information)
	• Details of the running processes and services
	• List of installed software (on both machine and user level)
	• Information on installed AntiVirus products
	• List of top 10 processes using CPU at the moment when the script is running
	• "gpresult /h" and "gpresult /r /v" output
	• "fltmc filters" and "fltmc volumes" output
	• File versions of the currently running binaries
	• File versions of key binaries (Windows\System32\*.dll, Windows\System32\*.exe, Windows\System32\*.sys, Windows\System32\drivers\*.sys)
	• Basic system information
	• .NET Framework information
	• "Get-DscConfiguration" and "Get-DscConfigurationStatus" output
	• Msinfo32 output (.nfo)
	• PowerShell version
	• WinRM configuration information
	• WMI ProviderHostQuotaConfiguration
	• Windows Update History
	• Output of "Test-DscConfiguration -Detailed"
	• Output of "%programfiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe" (if the NVIDIA GPU drivers are already installed on the machine)
	• Certificate store information ('My' and 'AAD Token Issuer')
	• Certificate thumbprint information ('My', 'AAD Token Issuer', 'Remote Desktop')
	• SPN information (WSMAN, TERMSRV)
	• "nltest /sc_query:<domain>" and "nltest /dnsgetdc:<domain>" output
	• Remote Desktop Gateway related information, incl. RAP and CAP policies (if RDGW role is installed - for Server OS deployments)
	• Remote Desktop Web Access related information, incl. IIS Server configuration (if RDWA role is installed - for Server OS deployments)
	• Remote Desktop Connection Broker related information, incl. GetRDSFarmData output (if RDCB role is installed - for Server OS deployments)
	• Remote Desktop Session Host related information (if RDSH role is installed - for Server OS deployments)
	• Remote Desktop License Server related information, incl. installed and issued licenses (if RDLS role is installed - for Server OS deployments)
	• "fsutil fsinfo sectorinfo" output for each disk drive, for RDCB WID scenarios (only when the RD Connection Broker role is detected)
	• Tree output of the "%windir%\RemotePackages" and "%programfiles%\Microsoft RDInfra" folder's content
	• "tasklist /v" output
	• ACL for "%programdata%\Microsoft\Crypto\RSA\MachineKeys" and "%programdata%\Microsoft\Crypto\RSA\MachineKeys\f686aace6942fb7f7ceb231212eef4a4_"
	• ACL for 'HKLM\SOFTWARE\Microsoft\SystemCertificates\Remote Desktop'
	• ACL for 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM' (if the RD Session Host role is installed)
	• List of AppLocker rules collections
	• Information on installed Firewall products
	• Information on Power Settings ('powercfg /list', 'powercfg /query', 'powercfg /systempowerreport')
	• Verbose list of domain trusts
	• NTFS permissions from the C:\ drive
	• "pnputil /e" output
	• Members of the 'Terminal Server License Servers' group in the domain, if the machine is domain-joined and has either the RD Session Host or RD Licensing role installed
	• Environment variables
	• Debug log for RDP Shortpath availability using 'avdnettest.exe'
	• Output of the WVDAgentUrlTool on AVD and W365 hosts
	• "Get-PnpDevice -PresentOnly" output
	• General 'PermissionsAllowed' and 'PermissionsDenied' information on the available listeners (RDP, SxS, ICA) for the assigned users/groups and granular information for the current user
	• MDM diagnostic information (results of: mdmdiagnosticstool.exe -area "DeviceEnrollment;DeviceProvisioning;Autopilot")
	• TlsWarning (termsrv\licensing) scheduled task information, if the RD Session Host role is installed
	• "MSI*.log" files corresponding to the 'Geneva' and 'MsRDCMMRHost' installations for AVD/W365, if available
	• Windows 365 app logs from '<default user profile location>\%username%\AppData\Local\Temp\DiagOutputDir\Windows365\Logs'
	• WMI query output for 'Win32_TerminalServiceSetting', 'Win32_Terminal', 'Win32_TSClientSetting', 'Win32_TSPermissionsSetting', 'Win32_TSEnvironmentSetting', 'Win32_TSGeneralSetting', 'Win32_TSLogonSetting', 'Win32_TSNetworkAdapterSetting', 'Win32_TSRemoteControlSetting', 'Win32_TSSessionSetting', 'Win32_TSSessionDirectory', 'Win32_TSDiscoveredLicenseServer', 'Win32_TSVirtualIP'
	• 'tree' output of '%windir%\System32\config\systemprofile\AppData\Roaming\Microsoft\Monitoring', if available
	• 'netsh interface tcp show global' and 'netsh interface udp show global' output
	• PsPing output for:
		o 8.8.8.8:443
		o rdweb.wvd.microsoft.com:443 (if 'AVD' or 'W365' machine type and 'Source' machine role are selected)
		o rdbroker.wvd.microsoft.com:443 (if 'AVD' or 'W365' machine type and 'Target' machine role are selected)
	• Wired and Wireless LAN settings (only when using the 'Source' machine role)
	• Wireless network report for the past 5 days (only when using the 'Source' machine role)
	• "net time" and "w32tm /query /status /verbose" output


Data collected additionally to the "Core" dataset, depending on the selected scenario or command line parameter(s) used:

When using "-Profiles" scenario/parameter:

	• Log files
		o %programdata%\FSLogix\Logs (or from the location specified in the registry under HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Logging\LogDir)
	• FSLogix tool output (frx list-redirects, frx list-rules, frx version)
	• Registry keys
		o HKEY_CURRENT_USER\SOFTWARE\FSLogix
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Office​
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\OneDrive
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
		o HKEY_CURRENT_USER\Volatile Environment
		o HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\SCSI\Disk&Ven_Msft&Prod_Virtual_Disk
	• Output of 'whoami /all'
	• Event Logs
		o Microsoft-FSLogix-Apps/Admin
		o Microsoft-FSLogix-Apps/Operational
		o Microsoft-FSLogix-CloudCache/Admin
		o Microsoft-FSLogix-CloudCache/Operational
		o Microsoft-Windows-Ntfs/Operational (filtered output for events 4 and 142 only)
		o Microsoft-Windows-User Profile Service/Operational
		o Microsoft-Windows-VHDMP/Operational
	• Local group membership information
		o FSLogix ODFC Exclude List
		o FSLogix ODFC Include List
		o FSLogix Profile Exclude List
		o FSLogix Profile Include List
	• ACL for the FSLogix Profiles and ODFC storage locations
	• 'klist get krbtgt' output
	• 'klist get cifs/<FSLogix Profiles VHDLocations storage>' output
	• A filtered output of the VHD Disk Compaction metric events for FSLogix for the past 5 days
	• The content of the '%programfiles%\FSLogix\Apps\Rules' folder
	• 'tree' output of '%programfiles%\FSLogix\Apps\Rules', if available
	• 'tree' output of '%programfiles%\FSLogix\Apps\CompiledRules', if available
	• Consistency check for the subkeys under 'HKLM\System\CurrentControlSet\Enum\SCSI\Disk&Ven_Msft&Prod_Virtual_Disk\' (relevant for mounting UPD or FSlogix profile disks)
	• pnputil /export-pnpstate (when FSLogix is used for profile management)


When using "-Activation" scenario/parameter:
	• 'licensingdiag.exe' output
	• 'slmgr.vbs /dlv' output
	• List of available KMS servers in the VM's domain (if domain joined)

		
When using "-MSIXAA" or "-AppAttach" scenario/parameter:

	• Event Logs
		o Microsoft-Windows-AppXDeploymentServer/Operational
		o Microsoft-Windows-RemoteDesktopServices (filtered for MSIX App Attach events only)


When using "-Teams" scenario/parameter:

	• Log files, if available in the selected user's context
		o %appdata%\Microsoft\Teams\logs.txt
		o %programfiles(x86)%\Microsoft\Teams\SquirrelSetup.log
		o %programfiles(x86)%\Microsoft\Teams\current\SquirrelSetup.log
		o %localappdata%\Microsoft\Teams\current\SquirrelSetup.log
		o %localappdata%\Microsoft\Teams\current\current\SquirrelSetup.log
		o %userprofile%\Downloads\MSTeams Diagnostics Logs*
		o %userprofile%\Downloads\PROD-WebLogs*
	• Registry keys
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams
	• Event Logs
		o Microsoft-Windows-AppxPackaging/Operational
		o Microsoft-Windows-AppXDeploymentServer/Operational
	• Output of 'Get-AppxPackage' for '*MSTeams*' and '*MicrosoftTeams*'


When using "-MSRA" scenario/parameter:

	• Local group membership information
		o Distributed COM Users
		o Offer Remote Assistance Helpers
	• Registry keys
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance
	• Event Logs
		o Microsoft-Windows-RemoteAssistance/Admin
		o Microsoft-Windows-RemoteAssistance/Operational
		o Microsoft-Windows-RemoteHelp/Operational
	• Information on the COM Security permissions
	• Remote Help installation logs
	• The available Remote Help Correlation Vector (cV) history


When using "-SCard" scenario/parameter:

	• Event Logs
		o Microsoft-Windows-Kerberos-KDCProxy/Operational
		o Microsoft-Windows-SmartCard-Audit/Authentication
		o Microsoft-Windows-SmartCard-DeviceEnum/Operational
		o Microsoft-Windows-SmartCard-TPM-VCard-Module/Admin
		o Microsoft-Windows-SmartCard-TPM-VCard-Module/Operational
	• "certutil -scinfo -silent" output
	• RD Gateway information when ran on the KDC Proxy server and the RD Gateway role is present
		o Server Settings, Resource Authorization Policy, Connection Authorization Policy


When using "-IME" scenario/parameter:

	• Registry keys
		o HKEY_CURRENT_USER\Control Panel\International
		o HKEY_CURRENT_USER\Keyboard Layout
		o HKEY_CURRENT_USER\SOFTWARE\AppDataLow\Software\Microsoft\IME
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\CTF
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\IMEMIP
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\IMEJP
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Input
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\InputMethod
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Keyboard
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Speech
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Speech Virtual
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Speech_OneCore
		o HKEY_CURRENT_USER\SOFTWARE\Microsoft\Spelling
		o HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layouts
		o HKEY_LOCAL_MACHINE\SYSTEM\Keyboard Layout
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CTF
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IME
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IMEJP
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IMEKR
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IMETC
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Input
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\InputMethod
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MTF
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MTFFuzzyFactors
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MTFInputType
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MTFKeyboardMappings
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore
		o HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Spelling
	• 'tree' output for the following folders:
		o %APPDATA%\Microsoft\IME
		o %APPDATA%\Microsoft\InputMethod
		o %LOCALAPPDATA%\Microsoft\IME
		o %windir%\System32\IME
		o %windir%\IME
	• 'Get-Culture' and 'Get-WinUserLanguageList' output


When using "-HCI" scenario/parameter:
	• Log files
		o %programdata%\AzureConnectedMachineAgent\Log\himds.log
		o %programdata%\AzureConnectedMachineAgent\Log\azcmagent.log
		o %programdata%\GuestConfig\arc_policy_logs\gc_agent.log
		o %programdata%\GuestConfig\ext_mgr_logs\gc_ext.log
	• Information on Azure Instance Metadata Service (IMDS) endpoint accessibility specific for Azure Stack HCI


When using "-NetTrace" scenario/parameter (If selected, it will always run first, before any other data collection/diagnostics):
	• 'klist' and 'klist -li 0x3e7' output
	• 'netsh' trace (netsh trace start scenario=netconnection maxsize=2048 filemode=circular overwrite=yes report=yes)


When using "-DumpPID" scenario/parameter:
	• Generates a process dump of the process corresponding to the provided PID using ProcDump from SysInternals (ProcDump.exe -AcceptEula -ma <PID>)


===============
 10. MSRD-Diag
===============

In addition to data collection, MSRD-Collect also generates diagnostic reports. These reports provide a comprehensive system overview, enabling quick identification of several known issues, thereby significantly accelerating the troubleshooting process. 

Please note that the reports may include checks for options or features that are not available on the system. This is expected as the diagnostics aim to cover as many topics as possible. Always interpret the results in the correct troubleshooting context.

New diagnostic checks may be added with each new release. Therefore, to ensure the best troubleshooting experience, always use the latest version of the script.

Important: MSRD-Diag is not a substitute for a full data analysis. Depending on the scenario, additional data collection and analysis may be required.

You can access the diagnostics results in two ways:

1) As an HTML report:

	When collecting data based on any scenario, or when using the 'DiagOnly' scenario, the script generates a *_MSRD-Diag.html file containing the results of the diagnostic checks. Additional output files may also be generated, based on the type of issues identified over the past 5 days (e.g., for AVD Agent, FSLogix, MSIX App Attach, RDP Shortpath, Black Screen, TCP, process hang, or system crash).

2) Live, through the Advanced GUI:

	When using the 'LiveDiag' feature in the advanced GUI, you can run the diagnostic checks per category directly in the UI for more granularity. In this case, no files are generated.


The script performs the following diagnostics, grouped into categories, from the perspective of Remote Desktop (AVD/RDS/W365):

	• System
		o Overview of the system the script is running on ('Core' information)
		o Top 10 processes using the most CPU time on all processors and top 10 processes using the most handles
		o Drives information for local, network and remote desktop redirected disk drives
		o Graphics configuration
		o Hyper-V Integration (if the Hyper-V role is installed and the status of the Hyper-V Integration Services and their dependencies)
		o OS activation / licensing
		o SSL/TLS configuration
		o User Account Control (UAC) configuration
		o Windows Installer information
		o Windows Search information
		o Windows Update information
		o WinRM and PowerShell configuration / requirements
	
	• AVD/RDS/W365
		o Remote Desktop device and resource redirection configuration
		o FSLogix configuration
		o Multimedia configuration (Multimedia Redirection and Audio/Video privacy settings)
		o Quick Assist and Remote Help information
		o RDP and Remote Desktop listener settings, and related services and their dependencies
		o Remote Desktop client information
		o Remote Desktop licensing configuration
		o RDS deployment information and individual RDS roles configuration
		o Remote Desktop 'Session Time Limits' and other network time limit policy settings
		o AVD media optimization configuration for Teams and basic Teams installation information
		o Windows 365 Cloud PC Boot related information

	• AVD Infra
		o Agents and SxS Stack information	
		o App Attach information
		o AVD Services URI health status (BrokerURI, BrokerURIGlobal, DiagnosticsUri, BrokerResourceIdURIGlobal)
		o Azure Stack HCI configuration
		o Health Check (status of the latest health checks performed by the AVD agent)
		o Host pool information
		o Monitoring information (Microsoft Monitoring Agent and Azure Monitor Agent)
	    o RDP ShortPath configuration for both managed and public networks
		o Required endpoints accessibility (for AVD and Windows 365)

	• Active Directory
		o Microsoft Entra Join configuration
		o Domain and Domain Controller information
		
	• Networking
		• Core networking registry keys and services status
		• DNS configuration (Windows 10+ and Server OS)
		• Firewall configuration (Firewall software available inside the VM - does not apply to external firewalls)
		• Public IP address information
		• Port Usage (total number of TCP/UDP ports in use + top 5 processes using the most TCP/UDP ports)
		• Proxy configuration
		• Routing information
		• VPN connection profile information

	• Logon/Security
		o Authentication and Logon information
		o TPM and Secure Boot status information
		o Antivirus information
		o Remote Desktop related security settings and requirements
		o List of available smart card readers and presence of smart cards
		o Status of the Smart Card services and their dependencies
		o Smart Card redirection configuration

	• Known Issues
		o Filtered event log entries from over the past 5 days, for the following scenarios:
			o AVD agent related issues
			o Black Screen issues
			o Domain Trust issues
			o Failed Logon issues
			​​​​o FSLogix related issues
			o MSIX App Attach related issues
			o Process and system crashes
			o Process hangs
			o RD Licensing related issues (when the RD Licensing role is installed)
			o RD Gateway related issues (when the RD Gateway role is installed)
			o RDP ShortPath issues
			o TCP issues
		o Potential logon/logoff issue generators (like black screens, delays, disappearing remote desktop windows)

	• Other
		• Microsoft Office information
		• OneDrive configuration and requirements for FSLogix compatibility
		• Printing information (spooler service status, available printers)
		• Installed Citrix components and some other 3rd party software which may be relevant in various troubleshooting scenarios


========================================
 11. Scheduled Tasks to run Diagnostics
========================================

The Advanced Mode GUI provides an option to set up scheduled tasks for running diagnostic checks and generating the MSRD-Diag.html report. You can find this option under "Tools\Create scheduled task...". The available frequencies for scheduling tasks are: Once, Daily, Weekly, and Monthly. Please note that the Scheduled Tasks will execute under the "NT AUTHORITY\SYSTEM" account.


=================
 12. Tool Author
=================

This tool was developed by Robert Klemencz from Microsoft Customer Service and Support (CSS).


==============
 13. Feedback
==============

We value your feedback on MSRD-Collect. Please share your thoughts and suggestions using our feedback form at: https://aka.ms/MSRD-Collect-Feedback.

