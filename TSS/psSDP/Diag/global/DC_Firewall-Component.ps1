#************************************************
# DC_Firewall-Component.ps1
# Version 1.0
# Version 1.1: Altered the runPS function correctly a column width issue.
# Date: 2009, 2014, 2020/waltere: add NetworkIsolation
# Author: Boyd Benson (bbenson@microsoft.com)
# Description: Collects information about the Windows Firewall.
# Called from: Main Networking Diag
#*******************************************************

param(
		[switch]$before,
		[switch]$after
	)

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

Import-LocalizedData -BindingVariable ScriptVariable
Write-DiagProgress -Activity $ScriptVariable.ID_CTSFirewall -Status $ScriptVariable.ID_CTSFirewallDescription

# detect OS version and SKU
$wmiOSVersion = Get-CimInstance -Namespace "root\cimv2" -Class Win32_OperatingSystem
[int]$bn = [int]$wmiOSVersion.BuildNumber

function RunNetSH ([string]$NetSHCommandToExecute=""){
	Write-DiagProgress -Activity $ScriptVariable.ID_CTSFirewall -Status "netsh $NetSHCommandToExecute"
	$NetSHCommandToExecuteLength = $NetSHCommandToExecute.Length + 6
	"-" * ($NetSHCommandToExecuteLength)	| Out-File -FilePath $outputFile -append
	"netsh $NetSHCommandToExecute"			| Out-File -FilePath $outputFile -append
	"-" * ($NetSHCommandToExecuteLength)	| Out-File -FilePath $outputFile -append
	$CommandToExecute = "cmd.exe /c netsh.exe " + $NetSHCommandToExecute + " >> $outputFile "
	RunCmD -commandToRun $CommandToExecute  -CollectFiles $false
	"`n`n`n"	| Out-File -FilePath $OutputFile -append
}

function RunPS ([string]$RunPScmd="", [switch]$ft){
	$RunPScmdLength = $RunPScmd.Length
	"-" * ($RunPScmdLength)		| Out-File -FilePath $OutputFile -append
	"$RunPScmd"  				| Out-File -FilePath $OutputFile -append
	"-" * ($RunPScmdLength)  	| Out-File -FilePath $OutputFile -append
	
	if ($ft)	{
		# This format-table expression is useful to make sure that wide ft output works correctly
		Invoke-Expression $RunPScmd	|format-table -autosize -outvariable $FormatTableTempVar | Out-File -FilePath $outputFile -Width 500 -append
	}
	else	{
		Invoke-Expression $RunPScmd	| Out-File -FilePath $OutputFile -append
	}
	"`n`n`n"	| Out-File -FilePath $OutputFile -append
}

$sectionDescription = "Firewall"

#Handle suffix of file name
	if ($before){
		$suffix = "_BEFORE"
	}
	elseif ($after){
		$suffix = "_AFTER"
	}
	else{
		$suffix = ""
	}

#W8/WS2012+
if ($bn -gt 9000){	
	"[info]: Firewall-Component W8/WS2012+"  | WriteTo-StdOut 

	$outputFile= $Computername + "_Firewall_info_pscmdlets" + $suffix + ".TXT"
	"========================================"				| Out-File -FilePath $OutputFile -append
	"Firewall Powershell Cmdlets"							| Out-File -FilePath $OutputFile -append
	"========================================"				| Out-File -FilePath $OutputFile -append
	"Overview"												| Out-File -FilePath $OutputFile -append
	"----------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Powershell Cmdlets"							| Out-File -FilePath $OutputFile -append
	"   1. Show-NetIPsecRule -PolicyStore ActiveStore"		| Out-File -FilePath $OutputFile -append
	"   2. Get-NetIPsecMainModeSA"							| Out-File -FilePath $OutputFile -append
	"   3. Get-NetIPsecQuickModeSA"							| Out-File -FilePath $OutputFile -append
	"   4. Get-NetFirewallProfile"							| Out-File -FilePath $OutputFile -append
	"   5. Get-NetFirewallRule"								| Out-File -FilePath $OutputFile -append
	"   6. Show-NetFirewallRule"							| Out-File -FilePath $OutputFile -append
	"   7. Show-NetFirewallRule -PolicyStore ActiveStore"	| Out-File -FilePath $OutputFile -append
	"========================================"				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"											| Out-File -FilePath $OutputFile -append
	"========================================"				| Out-File -FilePath $OutputFile -append
	"Firewall Powershell Cmdlets"							| Out-File -FilePath $OutputFile -append
	"========================================"				| Out-File -FilePath $OutputFile -append
	runPS "Show-NetIPsecRule -PolicyStore ActiveStore"		# W8/WS2012, W8.1/WS2012R2	# fl
	runPS "Get-NetIPsecMainModeSA"							# W8/WS2012, W8.1/WS2012R2	# fl
	runPS "Get-NetIPsecQuickModeSA"							# W8/WS2012, W8.1/WS2012R2	# fl				
	runPS "Get-NetFirewallProfile"							# W8/WS2012, W8.1/WS2012R2	# fl
	runPS "Get-NetFirewallRule"								# W8/WS2012, W8.1/WS2012R2	# fl
	runPS "Show-NetFirewallRule"							# W8/WS2012, W8.1/WS2012R2	# fl
	runPS "Show-NetFirewallRule -PolicyStore ActiveStore"	# W8/WS2012, W8.1/WS2012R2	# fl

	CollectFiles -filesToCollect $outputFile -fileDescription "Firewall Information PS cmdlets" -SectionDescription $sectionDescription
}

#WV/WS2008+
if ($bn -gt 6000){
	"[info]: Firewall-Component WV/WS2008+"  | WriteTo-StdOut 

	#----------Netsh
	$outputFile = $ComputerName + "_Firewall_netsh_advfirewall" + $suffix + ".TXT"
	"========================================"			| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Output"					| Out-File -FilePath $OutputFile -append
	"========================================"			| Out-File -FilePath $OutputFile -append
	"Overview"											| Out-File -FilePath $OutputFile -append
	"----------------------------------------"			| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Output"					| Out-File -FilePath $OutputFile -append
	"   1. netsh advfirewall show allprofiles"			| Out-File -FilePath $OutputFile -append
	"   2. netsh advfirewall show allprofiles state"	| Out-File -FilePath $OutputFile -append
	"   3. netsh advfirewall show currentprofile"		| Out-File -FilePath $OutputFile -append
	"   4. netsh advfirewall show domainprofile"		| Out-File -FilePath $OutputFile -append
	"   5. netsh advfirewall show global"				| Out-File -FilePath $OutputFile -append
	"   6. netsh advfirewall show privateprofile"		| Out-File -FilePath $OutputFile -append
	"   7. netsh advfirewall show publicprofile"		| Out-File -FilePath $OutputFile -append
	"   8. netsh advfirewall show store"				| Out-File -FilePath $OutputFile -append
	"========================================"			| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	"========================================"			| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Output"					| Out-File -FilePath $OutputFile -append
	"========================================"			| Out-File -FilePath $OutputFile -append
	RunNetSH -NetSHCommandToExecute "advfirewall show allprofiles"
	RunNetSH -NetSHCommandToExecute "advfirewall show allprofiles state"
	RunNetSH -NetSHCommandToExecute "advfirewall show currentprofile"
	RunNetSH -NetSHCommandToExecute "advfirewall show domainprofile"
	RunNetSH -NetSHCommandToExecute "advfirewall show global"
	RunNetSH -NetSHCommandToExecute "advfirewall show privateprofile"
	RunNetSH -NetSHCommandToExecute "advfirewall show publicprofile"
	RunNetSH -NetSHCommandToExecute "advfirewall show store"
	CollectFiles -filesToCollect $outputFile -fileDescription "Firewall Advfirewall" -SectionDescription $sectionDescription

	#-----WFAS export
	$filesToCollect = $ComputerName + "_Firewall_netsh_advfirewall-export" + $suffix + ".wfw"
	$commandToRun = "netsh advfirewall export " +  $filesToCollect
	RunCMD -CommandToRun $commandToRun -filesToCollect $filesToCollect -fileDescription "Firewall Export" -sectionDescription $sectionDescription 

	#-----WFAS ConSec rules (all)
	$outputFile = $ComputerName + "_Firewall_netsh_advfirewall-consec-rules" + $suffix + ".TXT"
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall ConSec Rules Output"					| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Overview"															| Out-File -FilePath $OutputFile -append
	"----------------------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall ConSec Rules Output"					| Out-File -FilePath $OutputFile -append
	"   1. netsh advfirewall consec show rule all any dynamic verbose"	| Out-File -FilePath $OutputFile -append
	"   2. netsh advfirewall consec show rule all any static verbose"	| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall ConSec Rules Output"					| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	# 3/5/2013: Through feedback from Markus Sarcletti, this command has been removed because it is an invalid command:
	#   "advfirewall consec show rule name=all"
	RunNetSH -NetSHCommandToExecute "advfirewall consec show rule all any dynamic verbose"
	RunNetSH -NetSHCommandToExecute "advfirewall consec show rule all any static verbose"
	CollectFiles -filesToCollect $outputFile -fileDescription "Advfirewall ConSec Rules" -SectionDescription $sectionDescription

if ($Global:skipHang -ne $true) {
	"__ value of Switch skipHang: $Global:skipHang  - 'True' will suppress some WFAS output `n`n"        | WriteTo-StdOut
	#-----WFAS ConSec rules (active)
	# 3/5/2013: Through feedback from Markus Sarcletti, adding active ConSec rules
	$outputFile = $ComputerName + "_Firewall_netsh_advfirewall-consec-rules-active" + $suffix + ".TXT"
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall ConSec Rules (ACTIVE)"					| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Overview"															| Out-File -FilePath $OutputFile -append
	"----------------------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall ConSec Rules (ACTIVE)"					| Out-File -FilePath $OutputFile -append
	"   1. netsh advfirewall monitor show consec verbose"				| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall ConSec Rules (ACTIVE)"					| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	RunNetSH -NetSHCommandToExecute "advfirewall monitor show consec verbose"
	CollectFiles -filesToCollect $outputFile -fileDescription "Advfirewall ConSec Rules" -SectionDescription $sectionDescription

	#-----WFAS Firewall rules (all)
	$outputFile = $ComputerName + "_Firewall_netsh_advfirewall-firewall-rules" + $suffix + ".TXT"
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Firewall Rules"							| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Overview"															| Out-File -FilePath $OutputFile -append
	"----------------------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Firewall Rules"							| Out-File -FilePath $OutputFile -append
	"   1. netsh advfirewall monitor show show rule name=all"			| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Firewall Rules (all)"					| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	RunNetSH -NetSHCommandToExecute "advfirewall firewall show rule name=all"
	CollectFiles -filesToCollect $outputFile -fileDescription "Advfirewall Firewall Rules" -SectionDescription $sectionDescription

	#-----WFAS Firewall rules all (active)
	# 3/5/2013: Through feedback from Markus Sarcletti, adding active Firewall Rules
	$outputFile = $ComputerName + "_Firewall_netsh_advfirewall-firewall-rules-active" + $suffix + ".TXT"
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Firewall Rules (ACTIVE)"				| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Overview"															| Out-File -FilePath $OutputFile -append
	"----------------------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Firewall Rules (ACTIVE)"				| Out-File -FilePath $OutputFile -append
	"   1. netsh advfirewall monitor show firewall verbose"				| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh AdvFirewall Firewall Rules (ACTIVE)"				| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	RunNetSH -NetSHCommandToExecute "advfirewall monitor show firewall verbose"
	CollectFiles -filesToCollect $outputFile -fileDescription "Advfirewall Firewall Rules" -SectionDescription $sectionDescription	
}
	#-----Netsh WFP	

	#-----Netsh WFP show netevents file=
	$outputFile = $ComputerName + "_Firewall_netsh_wfp-show-netevents" + $suffix + ".XML"
	$commandToRun = "netsh wfp show netevents file= " +  $outputFile
	RunCMD -CommandToRun $commandToRun -filesToCollect $outputFile -fileDescription "Netsh WFP Show Netevents" -sectionDescription $sectionDescription 
	
	#-----Netsh WFP show BoottimePolicy file=
	$outputFile = $ComputerName + "_Firewall_netsh_wfp-show-boottimepolicy" + $suffix + ".XML"
	$commandToRun = "netsh wfp show boottimepolicy file= " +  $outputFile
	RunCMD -CommandToRun $commandToRun -filesToCollect $outputFile -fileDescription "Netsh WFP Show BootTimePolicy" -sectionDescription $sectionDescription 

	#-----Netsh wfp show Filters file=
	$outputFile = $ComputerName + "_Firewall_netsh_wfp-show-filters" + $suffix + ".XML"
	$commandToRun = "netsh wfp show filters file= " +  $outputFile
	RunCMD -CommandToRun $commandToRun -filesToCollect $outputFile -fileDescription "Netsh WFP Show Filters" -sectionDescription $sectionDescription 
	
	#-----Netsh wfp show Options optionsfor=keywords
	$outputFile = $ComputerName + "_Firewall_netsh_wfp-show-options" + $suffix + ".TXT"
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh WFP Show Options"									| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Overview"															| Out-File -FilePath $OutputFile -append
	"----------------------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh WFP Show Options"									| Out-File -FilePath $OutputFile -append
	"   1. netsh wfp show options optionsfor=keywords"					| Out-File -FilePath $OutputFile -append
	"   2. netsh wfp show options optionsfor=netevents"					| Out-File -FilePath $OutputFile -append
	"   3. netsh wfp show options optionsfor=txnwatchdog"				| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh WFP Show Options"									| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	RunNetSH -NetSHCommandToExecute "wfp show options optionsfor=keywords"
	RunNetSH -NetSHCommandToExecute "wfp show options optionsfor=netevents"
	RunNetSH -NetSHCommandToExecute "wfp show options optionsfor=txnwatchdog"
	CollectFiles -filesToCollect $outputFile -fileDescription "Netsh WFP Show Options" -SectionDescription $sectionDescription

	#-----Netsh wfp show Security netevents
	$outputFile = $ComputerName + "_Firewall_netsh_wfp-show-security-netevents" + $suffix + ".TXT"
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh WFP Show Security Netevents"						| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Overview"															| Out-File -FilePath $OutputFile -append
	"----------------------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh WFP Show Security Netevents"						| Out-File -FilePath $OutputFile -append
	"   1. netsh wfp show security netevents"							| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh WFP Show Security Netevents"						| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	RunNetSH -NetSHCommandToExecute "wfp show security netevents"
	"`n`n`n"	| Out-File -FilePath $OutputFile -append
	CollectFiles -filesToCollect $outputFile -fileDescription "Netsh WFP Show Security NetEvents" -SectionDescription $sectionDescription

	#-----Netsh wfp show State file=
	$outputFile = $ComputerName + "_Firewall_netsh_wfp-show-state" + $suffix + ".XML"
	$commandToRun = "netsh wfp show state file= " +  $outputFile
	RunCMD -CommandToRun $commandToRun -filesToCollect $outputFile -fileDescription "Netsh WFP Show State" -sectionDescription $sectionDescription 
	
	#-----Netsh wfp show Sysports file=
	$outputFile = $ComputerName + "_Firewall_netsh_wfp-show-sysports" + $suffix + ".XML"
	$commandToRun = "netsh wfp show sysports file= " +  $outputFile
	RunCMD -CommandToRun $commandToRun -filesToCollect $outputFile -fileDescription "Netsh WFP Show Sysports" -sectionDescription $sectionDescription 

	#----------Netsh
	$outputFile = $ComputerName + "_Firewall_netsh_firewall.TXT"	
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh Firewall"											| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"Overview"															| Out-File -FilePath $OutputFile -append
	"----------------------------------------------------"				| Out-File -FilePath $OutputFile -append
	"Firewall Netsh Firewall"											| Out-File -FilePath $OutputFile -append
	"   1. netsh firewall show allowedprogram"							| Out-File -FilePath $OutputFile -append
	"   2. netsh firewall show config"									| Out-File -FilePath $OutputFile -append
	"   3. netsh firewall show currentprofile"							| Out-File -FilePath $OutputFile -append
	"   4. netsh firewall show icmpsetting"								| Out-File -FilePath $OutputFile -append
	"   5. netsh firewall show logging"									| Out-File -FilePath $OutputFile -append
	"   6. netsh firewall show multicastbroadcastresponse"				| Out-File -FilePath $OutputFile -append
	"   7. netsh firewall show notifications"							| Out-File -FilePath $OutputFile -append
	"   8. netsh firewall show opmode"									| Out-File -FilePath $OutputFile -append
	"   9. netsh firewall show portopening"								| Out-File -FilePath $OutputFile -append
	"  10. netsh firewall show service"									| Out-File -FilePath $OutputFile -append
	"  11. netsh firewall show state"									| Out-File -FilePath $OutputFile -append
	"===================================================="				| Out-File -FilePath $OutputFile -append
	"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append
	RunNetSH -NetSHCommandToExecute "firewall show allowedprogram"
	RunNetSH -NetSHCommandToExecute "firewall show config"
	RunNetSH -NetSHCommandToExecute "firewall show currentprofile"
	RunNetSH -NetSHCommandToExecute "firewall show icmpsetting"
	RunNetSH -NetSHCommandToExecute "firewall show logging"
	RunNetSH -NetSHCommandToExecute "firewall show multicastbroadcastresponse"
	RunNetSH -NetSHCommandToExecute "firewall show notifications"
	RunNetSH -NetSHCommandToExecute "firewall show opmode"
	RunNetSH -NetSHCommandToExecute "firewall show portopening"
	RunNetSH -NetSHCommandToExecute "firewall show service"
	RunNetSH -NetSHCommandToExecute "firewall show state"
	CollectFiles -filesToCollect $outputFile -fileDescription "Firewall" -SectionDescription $sectionDescription

	#----------Registry
	$outputFile= $Computername + "_Firewall_reg_" + $suffix + ".TXT"
	$CurrentVersionKeys =	"HKLM\Software\Policies\Microsoft\WindowsFirewall",
							"HKLM\SYSTEM\CurrentControlSet\Services\BFE",
							"HKLM\SYSTEM\CurrentControlSet\Services\IKEEXT",
							"HKLM\SYSTEM\CurrentControlSet\Services\MpsSvc",
							"HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess",
							"HKLM\Software\Policies\Microsoft\Windows\NetworkIsolation"
	$sectionDescription = "Firewall"
	RegQuery -RegistryKeys $CurrentVersionKeys -Recursive $true -outputFile $outputFile -fileDescription "Firewall Registry Keys" -SectionDescription $sectionDescription


	#----------EventLogs
	if (($suffix -eq "") -or ($suffix -eq "_AFTER")){
		#----------WFAS Event Logs
		$sectionDescription = "Firewall EventLogs"
		#WFAS CSR
		$EventLogNames = "Microsoft-Windows-Windows Firewall With Advanced Security/ConnectionSecurity"
		$Prefix = ""
		$Suffix = "_evt_"
		.\TS_GetEvents.ps1 -EventLogNames $EventLogNames -SectionDescription $sectionDescription -Prefix $Prefix -Suffix $Suffix

		#WFAS CSR Verbose
		$EventLogNames = "Microsoft-Windows-Windows Firewall With Advanced Security/ConnectionSecurityVerbose"
		$Prefix = ""
		$Suffix = "_evt_"
		.\TS_GetEvents.ps1 -EventLogNames $EventLogNames -SectionDescription $sectionDescription -Prefix $Prefix -Suffix $Suffix

		#WFAS FW
		$EventLogNames = "Microsoft-Windows-Windows Firewall With Advanced Security/Firewall"
		$Prefix = ""
		$Suffix = "_evt_"
		.\TS_GetEvents.ps1 -EventLogNames $EventLogNames -SectionDescription $sectionDescription -Prefix $Prefix -Suffix $Suffix

		#WFAS FW Verbose
		$EventLogNames = "Microsoft-Windows-Windows Firewall With Advanced Security/FirewallVerbose"
		$Prefix = ""
		$Suffix = "_evt_"
		.\TS_GetEvents.ps1 -EventLogNames $EventLogNames -SectionDescription $sectionDescription -Prefix $Prefix -Suffix $Suffix
	}
}
#Windows Server 2003
else{
	"[info]: Firewall-Component XP/WS2003"  | WriteTo-StdOut 
	#----------Registry
	$outputFile= $Computername + "_Firewall_reg_.TXT"
	$CurrentVersionKeys =	"HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall",
							"HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess"
	$sectionDescription = "Firewall"
	RegQuery -RegistryKeys $CurrentVersionKeys -Recursive $true -outputFile $outputFile -fileDescription "Firewall Registry Keys" -SectionDescription $sectionDescription
	
	#----------Netsh
	$outputFile = $ComputerName + "_Firewall_netsh.TXT"
	RunNetSH -NetSHCommandToExecute "firewall show allowedprogram"
	RunNetSH -NetSHCommandToExecute "firewall show config"
	RunNetSH -NetSHCommandToExecute "firewall show currentprofile"
	RunNetSH -NetSHCommandToExecute "firewall show icmpsetting"
	RunNetSH -NetSHCommandToExecute "firewall show logging"
	RunNetSH -NetSHCommandToExecute "firewall show multicastbroadcastresponse"
	RunNetSH -NetSHCommandToExecute "firewall show notifications"
	RunNetSH -NetSHCommandToExecute "firewall show opmode"
	RunNetSH -NetSHCommandToExecute "firewall show portopening"
	RunNetSH -NetSHCommandToExecute "firewall show service"
	RunNetSH -NetSHCommandToExecute "firewall show state"
	CollectFiles -filesToCollect $outputFile -fileDescription "Firewall" -SectionDescription $sectionDescription
}


# SIG # Begin signature block
# MIIoLAYJKoZIhvcNAQcCoIIoHTCCKBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBF28c58v08SnzH
# u8yLL5ynJ/D5o6pDI6d1UofgWVtLkKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGO4Aw14rR87c8fuogzdQ739
# O0O1mq7TScJFKF1tU7PLMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQAH5+oINOli8X/jvE6XyQRxvj/Utj4NNzJdfQWCjEhTpp95kuqxoDh1
# mB9L82cnG3vY+nesqZtrMedXnZxbr/8xyiN+FWrxwFL2PsIzli5MP5sIxDVu/aKc
# 2kcnqy0x++5vgjEWwfFZwXhluM0VFAJ2X9t1OqeExEwBc2T0xRlG6V5e2SIG9oWW
# OKi/asyfhqWakwjsuZ9X6+/vbutaNQ+JaLV+H/L5zH3KL6EMktYTmmqTS7K9MiQ3
# WLp9ekhMscAFhjgAU5EyAe7fnVvOXbgaDHkLTXGomHtxYnJn7Uwn2tl4acwyyeiV
# KQTuZayT7yvI2fNnfRe6tLZO6tsUihoRoYIXlDCCF5AGCisGAQQBgjcDAwExgheA
# MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglghkgBZQMEAgEFADCCAVIG
# CyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIKy5xV+WEx9GcjuRVc1EmQo0pyWlyzgzlfnOQ1f2EzIsAgZlzjJg
# gu0YEzIwMjQwMjI4MTU0MDA1LjgzN1owBIACAfSggdGkgc4wgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjozNzAz
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCEeowggcgMIIFCKADAgECAhMzAAAB6pokctVZP2FjAAEAAAHqMA0GCSqGSIb3
# DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4
# NDUzMFoXDTI1MDMwNTE4NDUzMFowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlv
# bnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjozNzAzLTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALULX/FIPyAH1fsu52ijatZvaSypoXrlC0mRtCma
# xzobhuDkw6/pY/+4nhc4m8pf9zW3R6PihYGp0YPpVuNdfhPQp/KVO6WvMq2DGfFm
# HurW4PQPL/DkbQMkM9vqjFCvPq8xXZnfL1nGN9moGcN+oaif/hUMedmF1qzbay9I
# LkYfLCxDYn3Qwzsvh5xjxOcsjzmRddNURJvT23Eva0cxisH4ocLLTx2zfpqfshw4
# Z9GaEdsWg9rmib1galUpLzF5PsQDBbtZtcv+Wjmn0pFEiMCWwEEcPVN0YG5ysYLd
# NBdJOn2zsOOS+80W5RrQEqzPpSIIvEkZBJmF3aI4lMR8nV/FiTadjpIIqxX5Wa1X
# lqI/Nj+xagVjnjb7POsA+vh6Wu+v24HpyL8pyL/8Q4RFkRRME9cwT+Jr63yOtPbL
# e6DXkxIJW6E6w2ua5kXBpEKtEQPTLPhX3CUxMYcglbnmI0zcc9UknX285K+sI/2W
# wRwTBZkhDUULI86eQzV+zvzzR1qEBrlSY+oyTlYQrHMM9WnTzVflFDocZVTPpl2B
# DSNxPn0Qb4IoM9EPqbHyi/MilL+v/AQc8q3mQ6FiuPJAddz0ocpNZ9ekBWPVLKq3
# lfiev4yl65u/438+NAQ+vSJgkONLMmuoguEGzmnK1vq/JHwdRUyn6YADiteM7Dja
# +Qd9AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUK4FFJaJR5ukXQFTUxMhyiwVuWV4w
# HwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
# UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAw
# XjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8E
# BAMCB4AwDQYJKoZIhvcNAQELBQADggIBACiDrVZeP37+fFVtfcbfsqC/Kg0Ce67b
# DcehZmPcfRgJ5Ddv0pJlOFVOFbiIVwesqeEUwFtclfi5AjneQ5ZJpYJpXfELOelG
# 3dzj+BKfd287/UY/cwmSkl+CjnoKBL3Ms6I/fWR+alR0+p6RlviK8xHoug9vkc2W
# rRZsGnMVu2xOM2tPJ+qpyoDBzqv30N/ZRBOoNrS/PCkDwLGICDYqVs/IzAE49yv2
# ElPywalf9mEsOHXV1lxtQDNcejVEmitJJ+1Vr2EtafPEbMQZp89TAuagROKE4Yuo
# hCUKm+v3geJqTQarTBjqV25RCOT+XFngTMDD9wYx6TwndB2I1Ly726NiHUHs0uvq
# 3ciCV9JwNXdt1VZ63WK1NSgpVEsiK9EPABPt1EfXcKrfaPYkbkFi79eK1ETxx3No
# mYNUHNiGU+X1Be8L7qpHwjo0g3/33XhtOr9LiDoUXh/V2LFTETiqV9Q8yLEavQW3
# j9LQ/h/CaGz5YdGfrY8HiPfMIeLEokKxGf0hHcTEFApB0yLlq6KoHrFAEANR/4Xu
# FIpl9sDywVIWt4tKqG+P6pRAXzg1zG5rGlslZWmw7XwgvhBu3jkLP9AxrsSYwY2f
# trwwze5NA6VDLS7pz+OrXXWLUmoyNrJNx5Bk0wEwzkQxzkOvmbdPhsOP1ZM0uA/x
# IV7cSpNpZUw5MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+
# F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU
# 88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqY
# O7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzp
# cGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0Xn
# Rm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1
# zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZN
# N3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLR
# vWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTY
# uVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUX
# k8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB
# 2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKR
# PEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0g
# BFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQ
# W9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNv
# bS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBa
# BggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqG
# SIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOX
# PTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6c
# qYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/z
# jj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz
# /AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyR
# gNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdU
# bZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo
# 3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4K
# u+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10Cga
# iQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9
# vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGC
# A00wggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzcwMy0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
# AInbHtxB+OlGyQnxQYhy04KSYSSPoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDpiStAMCIYDzIwMjQwMjI4MDM0
# NzEyWhgPMjAyNDAyMjkwMzQ3MTJaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOmJ
# K0ACAQAwBwIBAAICA6EwBwIBAAICE2wwCgIFAOmKfMACAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEAvgipQRyPEthc319ejhbid+hJ1sXCTs1K06o+WxevdTkk
# 9TYbPkhyyQSYRIzn6k03fyzP+YLoTiqNPA0mMHumA+rPtjwqquFXQyWRUlccTz3i
# ljN4gDLBR4hABvzWw62r1AabqvcHNuUEug7eQV/HjcXYnG1ALeflhTFKX0c9cCiH
# sq1YrWzwUMNsONINTZAoQxmNylWnKbFYK3bUovQU43rpUL9cdaaJhnbDVtQkQaoN
# 3m2I7EMfcVVMK1ftGvEBjB59bLnfLz5LEC3sF69Xe/jOtXyYGXMeJ3tcZ6X28zyT
# qHQyCHE14y59MniKnY4zlGDC5f0FARLQ0Edu/Q8aqTGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB6pokctVZP2FjAAEAAAHq
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEILLa3ukQMDPxprA2Y8lEkEmYm3mJPw4l4q5odTT3bZlJ
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgKY+h1eNkNHiLCDSW0sA1cGHk
# bW4qooi+ryyMp6S4ZngwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAeqaJHLVWT9hYwABAAAB6jAiBCAaC9Ai9R9lWb/vEIYMP5HYnO2x
# jkiccsF9wOHr32HtyTANBgkqhkiG9w0BAQsFAASCAgA+2FbrtbzDceeKVuXRft2M
# kn76t8TMaVd3HOdxeoAVMQ78yx3W5b/v7nT7+qcVmk6fXdd9t6kTRkGXWpBC890w
# nILrF0tG08/UB2VT/EN+hkpKr5dl0RnpLY6qBfUYFpcEx7eSAjUImyYAautA5Ke6
# xYMfOv/Jb0GBI93cJ7FLiTwB1Qs117OlaJXfwezq7zaC5TeEZGWLxgS1VKmHceaw
# HEjDJROwjztcpgHjPaoxy+cM+0t9HFV6z80D1p3mpE9c+Mw7jWzhfu0LbkfPDfjG
# pTJfUrSTFhiDJicf6DWRsuePB9Mw1DUQO0AgJi7TinMx9UKImiay5YiQi47PUQR4
# sE45sVri42AZ2IYc6M28yi2OIAygz0HCsK4UT5wifmXT7yS/DU+0FhqRmKfevVgc
# +Cbr7ANDMWB2wNQ7QfjGbFTi+FSc+Fw4wNPRbJbjEOGcgfSByidgM2TrfCK6ubaB
# HlPRbxGdEt+SijstWP3NOMgOc9ncW9AFx/F20NHHkUiZ55pI1nsIec2CPvCSXnQ5
# Q1LmRdrCww5l6V3xUxfOIMjye3h7yFUFAux6kWtGYb9rj/vBPGoX9ZfpZfafM0fy
# 5fTrR0nFyPY5amE7mzaNvpfoghBhwS7obOMrX/GFlpDmecrB0xPoUSQKfA8H+dAs
# GbVCM7HhlVTWLbfnmwBHHg==
# SIG # End signature block
