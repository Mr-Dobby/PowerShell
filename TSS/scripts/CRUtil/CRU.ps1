 ############################ version information begin #######################################
# Script "cru.ps1" 
# current status: version, v2.0
# cru.ps1 release from: 26.02.2018
############################ version information end #######################################

#region ############ reading script parameters if provided ############
param(
		[string]$dumpconfig,
		[string]$username,
		[string]$eventlog,
		[string]$installcmdlet,
		[string]$getcredroamlocaluserdata,
		[string]$getcredroamlvrdata,
		[string]$getcredroamaddata,
		[string]$getcredroamstatus,
		[string]$dctouse,
		[string]$verbose,
        [switch]$AcceptEula
)
#endregion ############ reading script parameters if provided ############

#region ############ variable declaration - can be changed ############
Invoke-Expression "Set-Variable -Name CMDletDLLInstallPath -scope script -value '${env:systemdrive}\CredRoamUtil'"
#endregion ############ can be changed ############

#region ############# variable declaration - do not change #############
$DumpLocalCfg = ""
$OSVersion = ""
$ProcessorArchitecture = ""
$NetFrameworkVersion = ""
$UserDomain = ""
$UserNameNoDomain = ""
$UserTaskRoam = ""
$userSID = ""
$UserProfilePath = ""
$UserProfileStateFolder = ""
$UserDimsKeyRoamingSettings = ""
$UserProfileRoaming = ""
$UserWinlgogonExludeDirs = ""
$UserProfileRoamingExcludeDirs = ""
$UserShellFoldersAppData = ""
$ShellFoldersAppData = ""
$evtxexportpath = ""
$path = ""
$dll = ""
$Adderr = ""
$global:userElevated = "True"
#endregion ############# variable declaration - do not change #############

############################ function definition begin #######################################

# ------------------------------------------------------------------------------
# Get the version of the operating system
# currently supported OS types (major versions): 5 = Windows XP, 6 = Windows Vista, 7 = Windows 7
# ------------------------------------------------------------------------------
function GetOSVersion() 
{
    $OSVersion = [system.environment]::osversion.version 
	$OSVersion = $OSVersion.ToString()
	Invoke-Expression "Set-Variable -Name OSVersion -scope script -value $OSVersion"
} 

# ------------------------------------------------------------------------------
# Get OS platform (x86 or AMD64) in order to devide the action items that are different on these platforms
# ------------------------------------------------------------------------------

function GetProcessorArchitecture()
{
    $ProcessorArchitecture = ${env:PROCESSOR_ARCHITECTURE}
	Invoke-Expression "Set-Variable -Name ProcessorArchitecture -scope script -value $ProcessorArchitecture"
	
	if ($ProcessorArchitecture -ne "x86" -AND $ProcessorArchitecture -ne "AMD64")
	{
		write-warning "The processor architecture is unknown: $ProcessorArchitecture . Cannot proceed."
	#	exit -1
	}
}

# ------------------------------------------------------------------------------
# Get .NET Framework version, we need .Net version 4.0 for some CMDlet functionalities
# ------------------------------------------------------------------------------

function GetNetFrameWorkVersion()
{
    if (Get-Item "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4.0")
	{
		$NetFrameworkVersion = "4.0"
		Invoke-Expression "Set-Variable -Name NetFrameworkVersion -scope script -value $NetFrameworkVersion"
	}
	else
	{
		write-warning "In order to run the required CMDlets, we need .Net Framework 4.0. Please install .Net Framework 4.0 or higher and re-run this command."
		exit -1
	}
}

# ------------------------------------------------------------------------------
# This function is replaced with GetNetFrameWorkVersion() for detecting .Net version 4.0...
# and renamed to GetNetFrameWorkVersionLegacy()
# Get .NET Framework version, we need .Net version 3.5 for some CMDlet functionalities
# ------------------------------------------------------------------------------

function GetNetFrameWorkVersionLegacy()
{
	
    if (Get-Item "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5")
	{
		$NetFrameworkVersion = "3.5"
		Invoke-Expression "Set-Variable -Name NetFrameworkVersion -scope script -value $NetFrameworkVersion"
	}
	else
	{
		write-warning "In order to run the required CMDlets, we need .Net Framework 3.5. Please install .Net Framework 3.5 or higher and re-run this command."
		exit -1
	}
}


# ------------------------------------------------------------------------------
# Convert the current logged username or the provided "-UserName" to domain SID
# ------------------------------------------------------------------------------
function ConvertTo-SID($username)
{
	$SID = new-object system.security.principal.NtAccount($UserName)
	$SID = $SID.translate([system.security.principal.securityidentifier])	
	$SID.value.ToString()
}


# ------------------------------------------------------------------------------
# Create the necessary UserEnvironment variables that will be used in different script functions
# ------------------------------------------------------------------------------
function GetUserNameAndSid()
{
# ------------------------------------------------------------------------------
# IF A USERNAME WAS PROVIDED, WE WILL EXPORT THE SETTINGS FOR THIS USER (local profile must be present)
# ------------------------------------------------------------------------------

	if ($UserName -ne "") 
	{
		$userSID = ConvertTo-SID($UserName)
	}
	else
	{
		$userSID = ConvertTo-SID("${env:userdomain}\${env:username}")
		$username = "${env:userdomain}\${env:username}"
	}
	Invoke-Expression "Set-Variable -Name UserName -scope script -value '$UserName'"
	Invoke-Expression "Set-Variable -Name userSID -scope script -value $userSID"
	
# ------------------------------------------------------------------------------
# Split the domain part from user part in $UserName (DOMAIN\username)
# set the appropriate vars for username and domain name
# ------------------------------------------------------------------------------		
	$UserNameSplit = $UserName.split('\')
	if ($UserNameSplit.count -ne 2)
	{
		write-warning "The username '$UserName' seems to be not in the correct format (DOMAIN\sAMAccountName). Please ensure that you use the correct and try again."
		exit -1
	}
	
	$UserDomain = $UserNameSplit[0]
	$UserNameNoDomain = $UserNameSplit[1]
	Invoke-Expression "Set-Variable -Name UserDomain -scope script -value $UserDomain"
	Invoke-Expression "Set-Variable -Name UserNameNoDomain -scope script -value '$UserNameNoDomain'"
}


function GetUserEnvironment()
{
# ------------------------------------------------------------------------------
# If we were able to translate the username into a SID, we will set the necessary vars
# ------------------------------------------------------------------------------		
	if ($UserSID -ne "")
	{
		Invoke-Expression "Set-Variable -Name UserCertificateAutoenrollment -scope script -value 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID\SOFTWARE\Microsoft\Cryptography\AutoEnrollment'"
		Invoke-Expression "Set-Variable -Name UserDimsGPOSettings -scope script -value 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment'"
		Invoke-Expression "Set-Variable -Name UserDimsKeyRoamingSettings -scope script -value 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID\SOFTWARE\Microsoft\Cryptography\DIMS\KeyRoaming'"
		
# ------------------------------------------------------------------------------
# Check if the provided user has a local profile and if so set the appropriate vars for later use
# ------------------------------------------------------------------------------			
		# The profile list shows us which users were logged on to this machine and where we can find their user profile
		if (Test-Path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID")
		{
			$UserProfilePath = (Get-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSID" -name "ProfileImagePath").ProfileImagePath
			
			# if the profile path is a network path (UNC), the user has a roaming / central profile
			if ($UserProfilePath -like "\\*")
			{
				Invoke-Expression "Set-Variable -Name UserProfileRoaming -scope script -value 'True'"
				$UserProfileRoamingExludeDirs = (Get-ItemProperty -path "Microsoft.PowerShell.Core\Registry::Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID\SOFTWARE\Policies\Microsoft\Windows\System" -name "ExcludeProfileDirs").ExcludeProfileDirs
				
				# set vars with the exlusion directories that are not roamed
				if ($UserProfileRoamingExludeDirs)
				{
					Invoke-Expression "Set-Variable -Name UserProfileRoamingExludeDirs -scope script -value '$UserProfileRoamingExludeDirs'"
				}
			}
			else
			{
				Invoke-Expression "Set-Variable -Name UserProfileRoaming -scope script -value 'False'"
			}
							
			Invoke-Expression "Set-Variable -Name UserProfilePath -scope script -value '$UserProfilePath'"
			
			# we have to use different Application Data pathes for Windows XP ("Application Data") and Windows Vista ("AppData") and later OS
			if ($OSVersion -lt 6)
			{
				Invoke-Expression "Set-Variable -Name UserProfileStateFolder -scope script -value '$UserProfilePath\Local Settings\Application Data\Microsoft\DIMS'"
				Invoke-Expression "Set-Variable -Name AppData -scope script -value '$UserProfilePath\Application Data'"			
			}
			else
			{
				Invoke-Expression "Set-Variable -Name UserProfileStateFolder -scope script -value '$UserProfilePath\AppData\Local\Microsoft\DIMS'"
				Invoke-Expression "Set-Variable -Name AppData -scope script -value '$UserProfilePath\AppData\Roaming'"
			}
			
			Invoke-Expression "Set-Variable -Name Credentials -scope script -value '$AppData\Microsoft\Credentials'"
			Invoke-Expression "Set-Variable -Name Crypto -scope script -value '$AppData\Microsoft\Crypto\RSA\$UserSID'"
			Invoke-Expression "Set-Variable -Name Protect -scope script -value '$AppData\Microsoft\Protect\$UserSID'"
			Invoke-Expression "Set-Variable -Name SystemCertificatesMyCertificates -scope script -value '$AppData\Microsoft\SystemCertificates\My\Certificates'"
			Invoke-Expression "Set-Variable -Name SystemCertificatesMyRequests -scope script -value '$AppData\Microsoft\SystemCertificates\Request\Certificates'"			
			
			# we can specify additional roaming profile exclusion directories in Winlogon hive, not using GPOs
			$UserWinlgogonExludeDirs = (Get-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "ExcludeProfileDirs").ExcludeProfileDirs
			Invoke-Expression "Set-Variable -Name UserWinlgogonExludeDirs -scope script -value '$UserWinlgogonExludeDirs'"
			
			# check the Shell Folders for the current pathes for AppData - maybe we have a folder redirection here, which causes problems in Windows XP (no problems in Vista and later OS)
			$UserShellFoldersAppData  = (Get-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -name "AppData").AppData
			Invoke-Expression "Set-Variable -Name UserShellFoldersAppData -scope script -value '$UserShellFoldersAppData'"
			
			$ShellFoldersAppData  = (Get-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$UserSID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -name "AppData").AppData
			Invoke-Expression "Set-Variable -Name ShellFoldersAppData -scope script -value '$ShellFoldersAppData'"				
		}
		else
		{
			# if there is no local profile for the provided user we cannot check for registry settings as well as filesystem data etc.
			write-warning "There is no local profile for the user '$UserName' with the SID $UserSID. Therefore we cannot check the local config. Please provide a user who is currently logged on to this machine and a local user profile is present or do not use the -username parameter --> if so we will use the currently logged on user for the ckecks."
			exit -1
		}
	}
	else
	{
		Write-Warning "No user SID available. Cannot proceed."
		exit -1
	}
}

# ------------------------------------------------------------------------------
# DumpLocalCfg dumps the Credential Roaming relevant configuration (e.g. registry values, file versions, ACLs) of the user / computer in order to check for potential problems
# ------------------------------------------------------------------------------
function DumpLocalCfg() 
{
  
	write "------------------------------------------------------------------------"
	
#----------------------------
# dump forest mode in order to check if linked value replication is enabled
#----------------------------
	GetForestMode
	write "Forest Functional Level for forest '$RootDomain':"
	switch ($ForestMode)
	{
	# http://msdn.microsoft.com/en-us/library/cc223743(PROT.13).aspx
		0 {write "0 - DS_BEHAVIOR_WIN2000"}
		1 {write "1 - DS_BEHAVIOR_WIN2003_WITH_MIXED_DOMAINS"}
		2 {write "2 - DS_BEHAVIOR_WIN2003"}
		3 {write "3 - DS_BEHAVIOR_WIN2008"}
		4 {write "4 - DS_BEHAVIOR_WIN2008R2"}
	}
	write "------------------------------------------------------------------------"
	write ""
		
#----------------------------
# dump Credential Roaming Winlogon notifiers (XP) or schedules task (Vista or higher), these notifiers and scheduled tasks will trigger Credential Roaming process
#----------------------------
	write "------------------------------------------------------------------------"
	switch ($OSVersion)
	{
		# if OS is Windows XP / 2003, we use Winlogon notifiers for Credential Roaming triggers
		{$_ -like "5*"} 
		{
			$WinlogonDimsNtfy = "Microsoft.PowerShell.Core\Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify\dimsntfy"
			$WinLogonDimsNtfy
			
			if (Test-Path $WinLogonDimsNtfy)
			{
				Get-ItemProperty $WinLogonDimsNtfy | Select-Object PSChildName, DllName, Startup, Shutdown, Logon, Logoff, StartShell, Lock, UnLock
			}
			else 
			{
				write "WARNING:"
				write "The Credential Roaming Winlogon notifiers are not present."
				write "Maybe KB907247 is not installed?"
				write "CREDENTIAL ROAMING WILL NOT WORK ON THIS MACHINE!"
				write ""
			}
		}
		# in Vista / 2008 and later OS, we use scheduled tasks for Credential Roaming triggers
		{($_ -like "6*" -AND $_ -gt 6) -OR ($_ -like "10*")} 
		{
			write "Scheduled Credential Roaming Tasks for Vista and higher OS"
			# in Vista it is not possible to use Win32_ScheduledTask WMI class, so we have to use "COM"
			$TaskScheduler = New-Object -com("Schedule.Service")
		
			# using "localhost" for the moment, may be changed in future releases if remote access should be possible
			$TaskScheduler.connect("localhost")
		
			$TaskSchedulerRoot = $TaskScheduler.getfolder("\Microsoft\Windows\CertificateServicesClient")		
			$ScheduledTasks = $TaskSchedulerRoot.GetTasks(0)

			# dump only the relevant scheduled task "UserTask-Roam"
			foreach ($task in $ScheduledTasks)
			{
				if ($task.name -eq "UserTask-Roam" -OR $task.name -eq "UserTask")
				{
					$TaskName = $task.name.ToString()
					write "TaskName: `t $TaskName"
					
					$LastRunTime = $task.lastruntime.ToString()
					write "LastRunTime: `t $LastRunTime"
					
					$Enabled = $task.enabled.ToString()
					write "Enabled: `t $Enabled"
					
					$UserTaskRoam = "TRUE"
				}
				write ""
			}
			
			# if "UserTask-Roam" is not present, we have a problem
			if ($UserTaskRoam -ne "TRUE")
			{
					write "WARNING:"
					write "The UserTask-Roam in Task 'Scheduler\Microsoft\Windows\CertificateServicesClient' is not present."
					write "CREDENTIAL ROAMING WILL NOT WORK CORRECTLY ON THIS MACHINE!"
			}
		}
		default
		{
			# maybe later use, if there are changes in later OS releases
			write "WARNING:"
			write "Not a supported OS type ('$OSVersion')"
		}

	}
	write "------------------------------------------------------------------------"
	write ""	

# ------------------------------------------------------------------------------
# dump optional KeyRoaming settings, especially "Disabled" is relevant:
# ------------------------------------------------------------------------------
	write "------------------------------------------------------------------------"
	$UserDimsKeyRoamingSettings
	write ""
	if (Test-Path $UserDimsKeyRoamingSettings)
	{
		Get-ItemProperty $UserDimsKeyRoamingSettings | Select-Object Disabled, LastTick
	
		write "Disabled: 0x00000000 = Credential Roaming enabled"
		write "Disabled: 0x00000001 = Credential Roaming in 'self-healing mode'"
		write "Disabled: 0xFFFFFFFF = Credential Roaming is disabled for this user (overrides GPO settings)"
		write ""
	}
	write "------------------------------------------------------------------------"
	write ""
	
# ------------------------------------------------------------------------------
# dump if user has a roaming profile	
# ------------------------------------------------------------------------------
	write "------------------------------------------------------------------------"
	write "User Roaming Profile status:"
	write ""
	
	# here we can check if the appropriate folder are ecxluded from roaming profile as needed (e.g. Crypto, Protect, SystemCertificates, Credentials)
	if ($UserProfileRoaming -eq "True") 
	{
		write "User has a Roaming Profile."
		write "Policy ExcludeDirs: $UserProfileRoamingExludeDirs"
		write "Winlogon ExcludeDirs: $UserWinlgogonExludeDirs"
		write ""
	}
	else
	{
		write "User has a local profile, no Roaming Profile in use."
	}
	write "------------------------------------------------------------------------"
	write ""

# ------------------------------------------------------------------------------
# dump user shell folders which is needed to check if there is a folder redirection for AppData (which is a problem in Windows XP / 2003)	
# ------------------------------------------------------------------------------
	write "------------------------------------------------------------------------"
	write "User shell folders status:"
	write ""

######### TO DO:
######### known issue: if the directory is a var like %username% the script running user is resolved and not the value is written to PowerShell export --> THIS SHOULD BE FIXED
	write "WARNING:"
	write "This export maybe wrong if the query is run against another user than the currently logged on user."
	write ""
	write "User Shell Folders: '$UserShellFoldersAppData'"
	write "Shell Folders: '$ShellFoldersAppData'"
	write "UserProfile ENV: '${env:userprofile}'"
	write "------------------------------------------------------------------------"
	write ""
	
# ------------------------------------------------------------------------------
# dump user certificate autoenrollment settings, shows us if autoenrollment is enabled, indirect relevant for credential roaming
# ------------------------------------------------------------------------------
	write "------------------------------------------------------------------------"
	$UserCertificateAutoenrollment
	write ""
	if (Test-Path $UserCertificateAutoenrollment) 
	{
		Get-ItemProperty $UserCertificateAutoenrollment | Select-Object PSChildName, AEFlags
	}
	else 
	{
		write "The Certificate Autoenrollment Registry Key for the user does not exist. Not a critical issue."
		write ""
	}
	write "------------------------------------------------------------------------"
	write ""

# ------------------------------------------------------------------------------
# dump Credential Roaming GPO settings, if not enabled Credential Roaming will not work for this user
# ------------------------------------------------------------------------------
	write "------------------------------------------------------------------------"
	$UserDimsGPOSettings
	write ""
	if (Test-Path $UserDimsGPOSettings) 
	{
		Get-ItemProperty $UserDimsGPOSettings | Select-Object PSChildName, DIMSRoaming, DIMSRoamingTombstoneDays, DIMSRoamingMaxNumTokens, DIMSRoamingMaxTokenSize, AEPolicy
		write-host ""
	}
	else 
	{
		write "WARNING:"
		write "There are no DIMS GPO settings defined (respectively the Registry key does not exist). May be the user is currently not logged on to this machine?"
		write "If the user is logged on and this message appears: CREDENTIAL ROAMING WILL NOT WORK FOR THIS USER SINCE NO CREDENTIAL ROAMING POLICY IS DEFINED FOR THIS USER!"
		write ""
	}
	write "------------------------------------------------------------------------"
	write ""

#----------------------------
# dump Credential Roaming folder ACL and state.dat file ACL
#----------------------------
	write "------------------------------------------------------------------------"
	if (Test-Path $UserProfileStateFolder) 
	{
		write "'$UserProfileStateFolder' ACL:"
		(Get-Acl $UserProfileStateFolder).access
		write ""
		
		write "'$UserProfileStateFolder\state.dat' ACL:"
		(Get-Acl $UserProfileStateFolder\state.dat).access
		write ""
				
		write "'$UserProfileStateFolder\state.dat' last change date/time:"
		(Get-Item $UserProfileStateFolder\state.dat -force).lastWriteTime | Select-Object DateTime
		
		write "'$UserProfileStateFolder\state.da~' ACL:"
		(Get-Acl $UserProfileStateFolder\state.da~).access
		write ""
				
		write "'$UserProfileStateFolder\state.da~' last change date/time:"
		(Get-Item $UserProfileStateFolder\state.da~ -force).lastWriteTime | Select-Object DateTime
	}
	else 
	{
		write "WARNING:"
		write "There is no folder '$UserProfileStateFolder'." 
		write "CREDENTIAL ROAMING WILL NOT WORK CORRECTLY FOR THIS USER!"
	}
	write "------------------------------------------------------------------------"
	write ""

	if ($verbose -eq "enable")
	{			
		foreach ($path in $Credentials, $Crypto, $Protect, $SystemCertificatesMyCertificates, $SystemCertificatesMyRequests)
		{
			#----------------------------
			# dump Credential Roaming relevant roamed folders ACLs
			#----------------------------
			write "------------------------------------------------------------------------"
			if (Test-Path $path) 
			{
				write "ACL: '$path'"
				(Get-Acl $path).access
				write ""
				
				write "'last change date/time: $path'"
				(Get-Item $path -force).lastWriteTime | Select-Object DateTime
				
				$files = Get-ChildItem $path -force
				if ($files)
				{
					write "'$path' files ACLs and change date/time:"
					$files | ForEach-Object {
						write ""
						write "ACL: '$_'"
						write ""
						(Get-Acl $_.fullname).access
						write "last change date/time: $_"
						write ""
						$_.lastWriteTime | Select-Object DateTime
					}
				}			
			}
			else 
			{
				write "WARNING:"
				write "There is no '$path' folder for this user." 
			}
			write "------------------------------------------------------------------------"
			write ""
		}
	}

# ------------------------------------------------------------------------------
# dump file version of Credential Roaming relevant DLLs for troubleshooting purposes
# ------------------------------------------------------------------------------
	write "------------------------------------------------------------------------"
	$dimsroamdll = (Get-Item env:Systemroot).value + "\system32\dimsroam.dll"
	$dimsjobdll = (Get-Item env:Systemroot).value + "\system32\dimsjob.dll"
	$adproviderdll = (Get-Item env:Systemroot).value + "\system32\adprovider.dll"
	$capiproviderdll = (Get-Item env:Systemroot).value + "\system32\capiprovider.dll"
	$cngproviderdll = (Get-Item env:Systemroot).value + "\system32\cngprovider.dll"
	$dpapiproviderdll = (Get-Item env:Systemroot).value + "\system32\dpapiprovider.dll"
	$wincredproviderdll = (Get-Item env:Systemroot).value + "\system32\wincredprovider.dll"
	
	# in Windows XP we have only dimsroam.dll
	if (($OSVersion -gt 4) -OR ($OSVersion -like "10*"))
	{
		if (Test-Path $dimsroamdll) 
		{
			$dimsroamdll
			[System.Diagnostics.FileVersionInfo]::GetVersionInfo($dimsroamdll).FileVersion
			write ""
		}
		else 
		{
			write "WARNING:"
			write "'$dimsroamdll' not present."
			write "CREDENTIAL ROAMING WILL NOT WORK ON THIS MACHINE!"
		}
	}
	
	#since Vista we additionally use dimsjob.dll
	if ($OSVersion -like "6*")
	{
		if (Test-Path $dimsjobdll) 
		{
			$dimsjobdll
			[System.Diagnostics.FileVersionInfo]::GetVersionInfo($dimsjobdll).FileVersion
		}
		else 
		{
			write "WARNING:"
			write "'$dimsjobdll' not present."
			write "CREDENTIAL ROAMING WILL NOT WORK ON THIS MACHINE!"
		}
	}
	
	# in Windows 7 there are some more DLLs that are relevant for Credential Roaming
	if (($OSVersion -like "6.1*") -OR ($OSVersion -like "7*") -OR ($OSVersion -like "8*") -OR ($OSVersion -like "10*"))

	{
		foreach ($dll in $adproviderdll, $capiproviderdll, $cngproviderdll, $dpapiproviderdll, $wincredproviderdll)
		{
			if (Test-Path $dll) 
			{
				write ""
				$dll
				[System.Diagnostics.FileVersionInfo]::GetVersionInfo($dll).FileVersion
			}
			else 
			{
				write ""
				write "WARNING:"
				write "'$dll' not present."
				write "CREDENTIAL ROAMING WILL NOT WORK ON THIS MACHINE!"
			}
		}
	}
	
	write "------------------------------------------------------------------------"
	write ""

}

# ------------------------------------------------------------------------------
# The EventLog function allows us to enable the Credetial Roaming EventLog
# ------------------------------------------------------------------------------
function EventLog()
{

	# "wevtutil" is used for the actions, which is a builtin tool in Vista and higher OS
	if (($OSVersion -like "6*") -OR ($OSVersion -gt 6) -OR ($OSVersion -like "7*") -OR ($OSVersion -like "8*") -OR ($OSVersion -like "10*"))
	{
		switch ($EventLog)
		{
			# enable the operational Credential Roaming event logging
			enable
			{
				Invoke-Expression "wevtutil sl Microsoft-Windows-CertificateServicesClient-CredentialRoaming/Operational /e:TRUE"
			}
			# disable the operational Credential Roaming event logging
			disable
			{
				Invoke-Expression "wevtutil sl Microsoft-Windows-CertificateServicesClient-CredentialRoaming/Operational /e:FALSE"
			}
			# export the operational Credential Roaming event log, you have to provide the complete path including the file type (*.evtx)
			export
			{
				#$evtxexportpath = read-host "Path for EventLog export file (normally should be an *.evtx file in format 'myfile.evtx')"
				#Invoke-Expression "wevtutil epl Microsoft-Windows-CertificateServicesClient-CredentialRoaming/Operational $evtxexportpath"		
                Invoke-Expression "wevtutil /ow:true epl Microsoft-Windows-CertificateServicesClient-CredentialRoaming/Operational CertificateServicesClient-CredentialRoaming.evtx"
                Invoke-Expression "wevtutil /ow:true epl Microsoft-Windows-TaskScheduler/Operational TaskScheduler.evtx" 
			}
			default
			{
				write-warning "No Eventlog action defined. Use .\cru.ps1 to get help."
			}
		}
	}
	# "wevutil" is not available in XP / 2003
	else
	{
		write ""
		write "WARNING:"
		write "The Credential Roaming Eventlog is available only in Vista and higher OS."
		write "Cannot perform this operation."
		write ""
	}
}


# ------------------------------------------------------------------------------
# since there are many action items in this script that need an elevated PowerShell, this function checks if we are in an elevated PowerShell
# ------------------------------------------------------------------------------
function Elevated()
{
	$elevated = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
	if (!$elevated)
	{
		write "WARNING:"
		write "In order to get the complete dataset, this script has to be started in an elevated PowerShell."
		write "If possible, elevate this shell and restart this script."
		write ""
		#exit -1
        $global:userElevated = "False"
	}
}

# ------------------------------------------------------------------------------
# Register and install / add the necessary CMDlet DLLs, each DLL in one go depending on the script arguments
# ------------------------------------------------------------------------------
function InstallCMDlet()
{
	# we have 3 CMDlets at the moment, we can regsiter each of them without enabling the others
	switch ($InstallCMDlet)
	{
		CredRoamLocalUserData
		{	
			$CMDletName = "CredRoamLocalUserData"
			$CMDletDLL = "CredRoamLocalUserData.dll"
		}
		CredRoamLVRData
		{	
			$CMDletName = "CredRoamLVRData"
			if ($ProcessorArchitecture -eq "x86")
			{
				$CMDletDLL = "CredRoamLVRCMDlet.dll"
			}
			elseif ($ProcessorArchitecture -eq "AMD64")
			{
				$CMDletDLL = "CredRoamLVRCMDletAMD64.dll"
			}
		}
		CredRoamADUserData
		{	
			$CMDletName = "CredRoamADData"
			if ($ProcessorArchitecture -eq "x86")
			{
				$CMDletDLL = "CredRoamADUserCMDlet.dll"
			}
			elseif ($ProcessorArchitecture -eq "AMD64")
			{
				$CMDletDLL = "CredRoamADUserCMDletAMD64.dll"
			}
		}
	}
		
	# if the appropriate CMDlet is registered, we do not have to register it but we have to add it to the current PowerShell session
	if (Get-PSSnapin -registered | where {$_.name -eq $CMDletName})
	{
		write "$CMDletName already registered..."
		if (Get-PSSnapin | where {$_.name -eq "$CMDletName"})
		{
			write "$CMDletName already installed..."
		}
		else
		{
			write "Adding PSSnapin now..."
			Add-PSSnapin $CMDletName
		}
	}
	# if the CMDlet was not registered or installed, we have to copy it into the install folder and install / register it
	else
	{
		write "$CMDletName not registered..."
		
		$currentpath = Invoke-Expression "Get-Location"
		if (Test-Path $currentpath\$CMDletDLL)
		{
			if (!(Test-Path $CMDletDLLInstallPath))
			{
				mkdir $CMDletDLLInstallPath
			}
			Invoke-Expression "Copy-Item -path '$currentpath\$CMDletDLL' -destination '$CMDletDLLInstallPath' -force"
			$CMDletDLL = "$CMDletDLLInstallPath\$CMDletDLL"
						
			# we use the .NET install utility to install the DLLs as CMDlet
			if ($ProcessorArchitecture -eq "x86")
			{
				$installutil = Get-ChildItem -recurse -path ${env:systemroot}\Microsoft.NET\Framework -include installutil.exe
			}
			elseif ($ProcessorArchitecture -eq "AMD64")
			{
				$installutil = Get-ChildItem -recurse -path ${env:systemroot}\Microsoft.NET\Framework64 -include installutil.exe
			}
			else
			{
				write-warning "Failed while identifiying the .NET Framework 'installutil.exe'. Cannot proceed with the installation of the CMDlets."
				exit -1
			}
						
			$newestinstallutilversion = ""
			$newestinstallutil = ""
		
			# since we want to use the latest version of the install utility, we check each of the existing .NET installations of the machine and select the newest installutil.exe version
			foreach ($version in $installutil)
			{				
				$tempversion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($version.fullname).FileVersion
				if ($newestinstallutilversion -lt $tempversion)
				{
					$newestinstallutil = $version.fullname
					$newestinstallutilversion = $tempversion
				}				
			}
			
			# now we install / register / add the DLL as CMDlet using the latest installutil.exe
			$installutil = $newestinstallutil
			Invoke-Expression "$installutil $CMDletDLL"
			write "Adding PSSnapin now..."
			Invoke-Expression "Add-PSSnapin $CMDletName"
		}
		else
		{
			
			write-warning "$CMDletDLL not found in '$currentpath'."
			write-warning "Please copy the *.dll into the same folder as the cru.ps1 script is located (currently running from '$currentpath')."
		}	
	}
}


# ------------------------------------------------------------------------------
# GetCredRoamLocalUserData dumps the local key containers in the filesystem and the statefile information
# ------------------------------------------------------------------------------
function GetCredRoamLocalUserData
{
	# if the parameter "statefile" is given, we will dump the statefile data
	if ($GetCredRoamLocalUserData -eq "statefile")
	{
		# we use the "Get-CredRoamLocalUserData CMDlet for the dump, therefore we provide the necessary parameters
		$stateFilePresent = Test-Path "$UserProfileStateFolder\state.dat"
		if ($stateFilePresent -ne $true)
		{
			write-warning "$($UserProfileStateFolder)\state.dat not present. Either Credential Roaming is not enabled or it will not work correctly."
		}
		else
		{
			$file = Invoke-Expression "Get-CredRoamLocalUserData -user '$UserName' -statefile '$UserProfileStateFolder\state.dat'"
			
			# since we do not need all parameters, we will filter the output for the relevant data
			$file | Select-Object Version, LastSyncTime, LocalLastChange, NetLastCHange, NetLastRef, NetLastGUID, LastDimsRoamFlags, Flags, UserGUID, NumberOfTokens
			
			# we have to read each token from the export with different properties
			foreach ($token in $file.tokens)
			{						
			# ------------------------------------------------------------------------------
			# the IDString tells us which credential type the current credential is (e.g. Preferred File, DPAPI Master Key etc.)
			# from statefile we get the string in format "%0\FF893B9..." GUID, therefore we have to split it into pieces
			# ------------------------------------------------------------------------------			
				$IDStringSplit = $token.IDString.Split('\')
				if ($IDStringSplit.count -ne 2)
				{
					write-warning "The IDString has not the correct format. This may result a wrong 'TokenType':"
				}
				# from array position "0" we get the key type
				switch ($IDStringSplit[0])
				{
					"%0"
					{
						if ($IDStringSplit[1] -eq "Preferred")
						{
							$token | Add-Member -Name TokenType -MemberType NoteProperty -Value ("PreferredFile")
						}
						else
						{
							$token | Add-Member -Name TokenType -MemberType NoteProperty -Value ("TYPE_DPAPI")
						}
					}
					"%1"
					{
						$token | Add-Member -Name TokenType -MemberType NoteProperty -Value ("TYPE_RSA_KEY")
					}
					"%2"
					{
						$token | Add-Member -Name TokenType -MemberType NoteProperty -Value ("NetworkCredential")
					}
					"%3"
					{
						$token | Add-Member -Name TokenType -MemberType NoteProperty -Value ("TYPE_MY_STORE")
					}
				}
				# from array position "1" we get the IDString / filename
				$token | Add-Member -Name IDStringSplit1 -MemberType NoteProperty -Value $IDStringSplit[1]
			}
			$file.tokens
		}
	}
	# if parameter "filesystem" was provided, we will read the certificates, private keys, network credentials etc. directly from the filesystem (user profile)
	elseif ($GetCredRoamLocalUserData -eq "filesystem")
	{
		# we use the same CMDlet "Get-CredRoamLocalUserData" with other parameters
		$store = Invoke-Expression "Get-CredRoamLocalUserData -user '$UserName' -appdata '$AppData'"
		
		# export each token with the according property values
		foreach ($token in $store) 
		{
			if ( $token.token_type -eq "TYPE_MY_STORE" ) 
			{
				$token | Add-Member -Name Subject -MemberType NoteProperty -Value (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $token.FileName).Subject
				$token | Add-Member -Name Issuer -MemberType NoteProperty -Value (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $token.FileName).Issuer
				$token | Add-Member -Name SerialNumber -MemberType NoteProperty -Value (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $token.FileName).SerialNumber
				$token | Add-Member -Name ThumbPrint -MemberType NoteProperty -Value (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $token.FileName).ThumbPrint
				$token | Add-Member -Name Archived -MemberType NoteProperty -Value (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $token.FileName).Archived
			}
		}
		
		$store | where-object {$_.Token_Type -like "TYPE_MY_STORE"} | Select-Object -Property DataType,FileData,Token_Type,Token_Size,Subject,Issuer,SerialNumber,ThumbPrint,Archived
		$store | where-object {$_.Token_Type -notlike "TYPE_MY_STORE"} | Select-Object -Property DataType,FileData,Token_Type,Token_Size
		
		
	}
	# if we have an unknown parameter, we will throw the following message
	else
	{
		write ""
		write-warning "The option '$GetCredRoamLocalUserData' is unknown. Please use type '.\cru.ps1' in order to get help."
		write ""
	}	
}

 


# ------------------------------------------------------------------------------
# GetCredRoamLVRData dumps the Credential Roaming data of a user object using linked value replication metadata of the user object
# linked value replication is available only in Forest Functional Level "Windows Server 2003" and later FFL
# the forest functional level is checked in the "main" (see below) section before calling this function
# ------------------------------------------------------------------------------
function GetCredRoamLVRData
{
	# if no DC name was provided that should be used for the query we get this message
	if ($DcToUse -eq "")
	{
		write ""
		write-warning "Please specify a DC that should be used for the Get-CredRoamLVRData query using the '-DcToUse' switch."
		write ""
		exit -1
	}

# ------------------------------------------------------------------------------
# if "attribute" was chosen for the export, we will dump the content of the Credential Roaming attributes on the user object
# ------------------------------------------------------------------------------	
	if ($GetCredRoamLVRData -eq "attribute")
	{
		# we use the CMDlet "CredRoamLVRData" for this export, therefore we have to provide the necessary information / parameters
		$LVRAttributeData = Invoke-Expression "Get-CredRoamLVRData -UserName '$UserNameNoDomain' -DomainName $UserDomain -DcToUse $DcToUse -OutType attribute"
		
        $LVRAttributeData | % {
           #Add-Member -InputObject $_ -NotePropertyName 'Cert_Subject' -NotePropertyValue 'token_data is not a cert'
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "Cert_Subject" -Value "token_data is not a cert"
		   #Add-Member -InputObject $_ -NotePropertyName "Cert_Issuer" -NotePropertyValue "token_data is not a cert"
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "Cert_Issuer" -Value "token_data is not a cert"
           #Add-Member -InputObject $_ -NotePropertyName "Cert_Template" -NotePropertyValue "token_data is not a cert"
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "Cert_Template" -Value "token_data is not a cert"
            if (($_.Token_Type -eq "TYPE_MY_STORE") -or ($_.Token_Type -eq "TYPE_CNG_MY_STORE"))
            {
			try {
				$cert = $null
				$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2] $_.Token_Data
				if ($cert -ne $null) {
                    $_.Cert_Template = "not defined"
                    $Template = "not defined"
					$_.Cert_Issuer = $cert.Issuer
					if ($cert.Issuer -eq $cert.Subject) {
						$_.Cert_Issuer = "self signed"
					}
                    $_.Cert_Subject = $cert.Subject

                    #if ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.21.7"}) {
                     #   $Template = ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.21.7"}).Format(0) -replace "(.+)?=(.+)\((.+)?", '$2'
                    #}
                    #elseif  ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.20.2"}) {
                     #   $Template = ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.20.2"}).Format(0) -replace "(.+)?=(.+)\((.+)?", '$2'
                    #}
                    #else {
                    #    $Template = "not defined"
                    #}
                    foreach ($ext in $cert.Extensions) {
                        if (($ext.oid.Value -match "1.3.6.1.4.1.311.20.2") -OR ($ext.oid.value -match "1.3.6.1.4.1.311.21.7")) {    
                           $Template = ($ext).Format(0) -replace "(.+)?=(.+)\((.+)?", '$2'
                            }    
                        }
                    $_.Cert_Template = $Template

				}
               
			}
			catch {
                write-warning "can't extract data from the certificate"
			}
        
        }


        }

        $LVRAttributeData | Select-Object DataType, AD_Status, DIMS_Roaming_Status, Token_Type, Token_ID, Token_Size, Last_Roamed, Local_USN, Original_USN, Time_Created, Time_Deleted, Time_LastOrigChange, Size_bytes, Key_Info, Cert_Subject, Cert_Issuer, Cert_Template
	    $LVRAttributeData | Select-Object DataType, AD_Status, DIMS_Roaming_Status, Token_Type, Token_ID, Token_Size, Last_Roamed, Local_USN, Original_USN, Time_Created, Time_Deleted, Time_LastOrigChange, Size_bytes, Key_Info, Cert_Subject, Cert_Issuer, Cert_Template | export-csv -Delimiter "`t" -Encoding unicode -NoTypeInformation .\UserCRLVRData.csv
    }
	
# ------------------------------------------------------------------------------
# if "object" was chosen we will dump only the AD metadata of the user object itself, not the Credential Roaming data
# ------------------------------------------------------------------------------	
	elseif ($GetCredRoamLVRData -eq "object")
	{
		# we use the CMDlet "CredRoamLVRData" for this export, therefore we have to provide the necessary information / parameters
		$LVRObjectData = Invoke-Expression "Get-CredRoamLVRData -UserName '$UserNameNoDomain' -DomainName $UserDomain -DcToUse $DcToUse -OutType object"
		$LVRObjectData
	}
	# if we have an unknown parameter, we will trow the following message
	else
	{
		write-warning "The option '$GetCredRoamLVRData' is unknown. Please use type '.\cru.ps1' in order to get help."
	}
}

# ------------------------------------------------------------------------------
# GetCredRoamADData will use non-LVR data for the export, it dumps the Credential Roaming attribute content without using LVR data
# ------------------------------------------------------------------------------
function GetCredRoamADData
{
	# if no DC name was provided that should be used for the query we get this message
	if ($DcToUse -eq "")
	{
		write ""
		write-warning "Please specify a DC that should be used for the Get-CredRoamADData query using the '-DcToUse' switch."
		write ""
		exit -1
	}
	
# ------------------------------------------------------------------------------
# if "attribute" was chosen for the export, we will dump the content of the Credential Roaming attributes on the user object
# ------------------------------------------------------------------------------	
	if ($GetCredRoamADData -eq "attribute")
	{
		# we use the CMDlet "CredRoamADData" for this export, therefore we have to provide the necessary information / parameters
		$ADAttributeData = Invoke-Expression "Get-CredRoamADData -UserName '$UserNameNoDomain' -DomainName $UserDomain -DcToUse $DcToUse -OutType attribute"
		$ADAttributeData | % {
           # Add-Member -InputObject $_ -NotePropertyName 'Cert_Subject' -NotePropertyValue 'token_data is not a cert'
           Add-Member -InputObject $_ -MemberType NoteProperty -Name "Cert_Subject" -Value "token_data is not a cert"
		   #Add-Member -InputObject $_ -NotePropertyName "Cert_Issuer" -NotePropertyValue "token_data is not a cert"
           Add-Member -InputObject $_ -MemberType NoteProperty -Name "Cert_Issuer" -Value "token_data is not a cert"
           # Add-Member -InputObject $_ -NotePropertyName "Cert_Template" -NotePropertyValue "token_data is not a cert"
           Add-Member -InputObject $_ -MemberType NoteProperty -Name "Cert_Template" -Value "token_data is not a cert"
         
            if (($_.Token_Type -eq "TYPE_MY_STORE") -or ($_.Token_Type -eq "TYPE_CNG_MY_STORE"))
            {
			try {
				$cert = $null
				$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2] $_.Token_Data
                
				if ($cert -ne $null) {
                    $_.Cert_Template = "not defined"
                    $Template = "not defined"
					$_.Cert_Issuer = $cert.Issuer
					if ($cert.Issuer -eq $cert.Subject) {
						$_.Cert_Issuer = "self signed"
					}
                    $_.Cert_Subject = $cert.Subject

                    #if ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.21.7"}) {
                        #$Template = ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.21.7"}).Format(0) -replace "(.+)?=(.+)\((.+)?", '$2'
                    #}
                    #elseif  ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.20.2"}) {
                    #    $Template = ($cert.Extensions | ?{$_.oid.value -match "1.3.6.1.4.1.311.20.2"}).Format(0) -replace "(.+)?=(.+)\((.+)?", '$2'
                    #}
                    #else {
                   #     $Template = "not defined"
                   # }
                   
                    foreach ($ext in $cert.Extensions) {
                        if (($ext.oid.Value -match "1.3.6.1.4.1.311.20.2") -OR ($ext.oid.value -match "1.3.6.1.4.1.311.21.7")) {    
                           $Template = ($ext).Format(0) -replace "(.+)?=(.+)\((.+)?", '$2'
                            }    
                        }
                    $_.Cert_Template = $Template 
				}
               
			}
			catch {
                write-warning "can't extract data from the certificate"
			}
        
        }


        

        }

    # for the dump, we do not want all information to be exported, therefore we filter the export with the relevant information / properties
    $ADAttributeData | Select-Object DataType, DIMS_Roaming_Status, Token_Type, Token_ID, Token_Size, Last_Roamed, Key_Info, Cert_Subject, Cert_Issuer, Cert_Template
    $ADAttributeData | Select-Object DataType, DIMS_Roaming_Status, Token_Type, Token_ID, Token_Size, Last_Roamed, Key_Info, Cert_Subject, Cert_Issuer, Cert_Template | export-csv -Delimiter "`t" -Encoding unicode -NoTypeInformation .\UserCRADData.csv

    }
# ------------------------------------------------------------------------------
# if "object" was chosen we will dump only the AD metadata of the user object
# ------------------------------------------------------------------------------
	elseif ($GetCredRoamADData -eq "object")
	{
		# we use the CMDlet "CredRoamADData" for this export
		$ADObjectData = Invoke-Expression "Get-CredRoamADData -UserName '$UserNameNoDomain' -DomainName $UserDomain -DcToUse $DcToUse -OutType object"
		$ADObjectData
	}
	# if we have an unknown parameter, we will trow the following message
	else
	{
		write-warning "The option '$GetCredRoamADData' is unknown. Please use type '.\cru.ps1' in order to get help."
	}
}



# ------------------------------------------------------------------------------
# GetCredRoamStatus will compare the local flesystem, statefile and users' AD data and tell us if the credentials are present in all locations or if they are missing
# ------------------------------------------------------------------------------
function GetCredRoamStatus()
{
	# crrently there are thos two options
	if ($GetCredRoamStatus -ne "compare" -AND $GetCredRoamStatus -ne "all")
	{
		write ""
		write-warning "The option '$GetCredRoamStatus' is unknown. Please use type '.\cru.ps1' in order to get help."
		write ""
		exit -1
	}
	# if no DC name was provided that should be used for the query we get this message
	if ($DcToUse -eq "")
	{
		write ""
		write-warning "Please specify a DC that should be used for the GetCredRoamStatus query using the '-DcToUse' switch."
		write ""
		exit -1
	}
	
	# we collect all necessary data using the Credential Roaming Util CMDlets and put them into vars for later use
	$CredRoamADData = Invoke-Expression "Get-CredRoamADData -UserName '$UserNameNoDomain' -DomainName $UserDomain -DcToUse $DcToUse -OutType attribute" | where-object {$_.DIMS_Roaming_Status -notlike "*TOKEN_FLAG_TOMBSTONE*"}
	$CredRoamAppData = Invoke-Expression "Get-CredRoamLocalUserData -user '$UserName' -appdata '$AppData'"
	$CredRoamStatefileData = Invoke-Expression "Get-CredRoamLocalUserData -user '$UserName' -statefile '$UserProfileStateFolder\state.dat'"
	
	# now we compare each filesystem object with the data we gathered from AD
	foreach ($AppDataToken in $CredRoamAppData)
	{
		# if we have an AD attribute value that matches the filename in the local filesystem of the current user profile, we will mark this token as FS present
		$obj = $CredRoamADData | where-object {$_.Token_ID -eq $AppdataToken.FileData.Name}

		if ($obj)
		{
			$obj.FS_Present = "True"
			$AppDataToken.DataType = "*Found in AD*" # mark entry
		}		
	}
	
	# now we compare the AD attribute value with statefile information
	foreach ($StateDataToken in $CredRoamStatefiledata.Tokens)
	{
		# we have to split the statefile token data, since we get it in format "%0\FF839B...", we only need the part after the backslash
		$IDStringSplit = $StateDataToken.IDString.Split('\')
		if ($IDStringSplit.count -ne 2)
		{
			write-warning "The IDString '$IDStringSplit' has not the correct format."
		}
		
		# if we have an AD attribute value that matches the filename in the statefile of the current user profile, we will mark this token as "statefile present"
		$obj = $CredRoamADData | where-object {$_.Token_ID -eq $IDStringSplit[1]}
		if ($obj)
		{
			$StateDataToken.DataType = "*Found in AD*" # mark entry
			$obj.State_Present = "True"
		}		
	}

	##Now we check the results
	
	# query all objects in state.dat which are not present in the AD
	$ResultOnlyInStateDat = ($CredRoamStatefileData.Tokens  | where-object {$_.dataType -ne "*Found in AD*"})
	$ResultOnlyInStateDat = ($ResultOnlyInStateDat | where-object {$_.Flags -notlike "*TOKEN_FLAG_TOMBSTONE*"})
	
	# query all local tokens not found in AD
	$ResultOnlyLocally = $CredRoamAppData  | where-object {$_.dataType -ne "*Found in AD*" -AND $_.Flags -notlike "*TOKEN_FLAG_TOMBSTONE*"}
	if ($ResultOnlyLocally)
	{
		$ResultOnlyLocally | % {$_.dataType = "False"}
	}
	
	# query all objects in AD which are not found in FileSystem
	$ResultADOnlyFS = $CredRoamADData  | where-object {$_.FS_Present -ne "True"}
	if ($ResultADOnlyFS) 
	{
		$ResultADOnlyFS | % {$_.FS_Present = "False"}
	}
	
	# query all objects in AD which are not found in state.dat
	$ResultADOnlyState = $CredRoamADData  | where-object {$_.State_Present -ne "True"}
	if ($ResultADOnlyState)
	{
		$ResultADOnlyState | % {$_.State_Present = "False"}
	}
	
	## Export the results
	write ""
	write "============================================================="
	write "Statistics for the user '$UserName'"
	write "NO TOMBSTONED TOKENS INCLUDED."
	write "============================================================="
	write ""
	
	$CredRoamADDataCount = $CredRoamADData.count
	write "Total amount of roaming tokens in AD           : $CredRoamADDataCount"
	
	$TempAllTokensSize = [int]"0"
	foreach ($TempToken in $CredRoamADData)
	{	
		[int]$TempAllTokensSize += [int]$TempToken.Token_Size
	}
	$TempAllTokensSizeRounded = ([math]::round(([int]$TempAllTokensSize / 1024),2))
	write "Total size of roaming tokens in AD             : $TempAllTokensSizeRounded KB"
	write ""
	
	$CredRoamAppDataCount = $CredRoamAppData.count
	write "Total amount of roaming tokens in filesystem   : $CredRoamAppDataCount"
	
	$TempAllTokensSize = [int]"0"
	foreach ($TempToken in $CredRoamAppData)
	{	
		[int]$TempAllTokensSize += [int]$TempToken.Token_Size
	}
	
	$TempAllTokensSizeRounded = ([math]::round(([int]$TempAllTokensSize / 1024),2))
	write "Total size of all roaming tokens in filesystem : $TempAllTokensSizeRounded KB"
	write ""
	
	$CredRoamStatefiledataTokens = ($CredRoamStatefiledata.Tokens | where-object {$_.Flags -notlike "*TOKEN_FLAG_TOMBSTONE*"}).count
	write "Amount of roaming tokens in statefile          : $CredRoamStatefiledataTokens"
	write ""
	
	if ($ResultOnlyInStateDat  -or $ResultOnlyLocally -or $ResultADOnlyFS -or $ResultADOnlyState)
	{
		# Houston we have a problem: there are differences in AD user object, statefile or filesystem
		write ""
		write "==================="
		write "INCONSISTENCY FOUND"
		write "==================="
		write ""
		if ($OSVersion -lt 6)
		{
			write "HINT:"
			write "Bear in mind, that Windows XP and Windows Server 2003 cannot roam Network Credentials."
			write "If present, these tokens may be marked as missing on a Windows XP / 2003 machine. "
			write ""
		}
		
		
		if ($ResultOnlyInStateDat)
		{
			write ""
			write "Following tokens only found in $UserProfileStateFolder\state.dat and not in AD:"
			write ""
			$ResultOnlyInStateDat | Select-Object DataType, LastChangeTime, Flags, Extra, IDstring, HashHex
		}

		if ($ResultOnlyLocally)
		{
			write "Following tokens only found in local filesystem ($AppData) and not in AD:"
			write ""
			$ResultOnlyLocally			
		}

		if ($ResultADOnlyFS)
		{
			write "Following tokens found in AD but not in filesystem ($AppData\[...]):"
			write ""
			$ResultADOnlyFS | Select-Object DataType, DIMS_Roaming_Status, Token_Type, Token_ID, Token_Size, Last_Roamed, AD_Present, FS_Present, State_Present
		}

		if ($ResultADOnlyState)
		{
			write "Following tokens only found in AD but not in $UserProfileStateFolder\state.dat:"
			write ""
			$ResultADOnlyState | Select-Object DataType, DIMS_Roaming_Status, Token_Type, Token_ID, Token_Size, Last_Roamed, AD_Present, FS_Present, State_Present
		}
	}
	
	# if there are no differences, everything is fine and the stores (AD and local) are in sync as well as the statefile information
	else
	{
		write ""
		write "No differences found in AD, $UserProfileStateFolder\state.dat and filesystem ($AppData\[...])."
		write ""
		write "ALL STORES ARE IN SYNC."
		write ""
	}
	
	# if the parameter "all" was provided, additionally we will dump the information of AD, statefile and filesystem
	if ($GetCredRoamStatus -eq "all")
	{
		write ""
		write "------------------------------------------------------------------------"
		write ""
		write "Stafile data:"
		write "============="
		$CredRoamStatefileData.Tokens | Select-Object LastChangeTime, Flags, Extra, IDstring, HashHex
		write ""
		write "Filesystem data:"
		write "================"
		$CredRoamAppData | Select-Object Filename, FileData, Token_Type, Token_Size
		write ""
		write "AD user object data:"
		write "===================="
		$CredRoamADData | Select-Object DataType, DIMS_Roaming_Status, Token_Type, Token_ID, Token_Size, Last_Roamed
		write ""			
	}
}

# ------------------------------------------------------------------------------
# in order to use the CMDlets we have to add them in the current PowerShell session
# ------------------------------------------------------------------------------
function AddPSSnapin($snapin)
{
	# if the appropriate CMDlet was not added in the current session we will try to add it
	$addpssnapin = Invoke-Expression "Get-PSSnapin $snapin -ErrorVariable err -ErrorAction SilentlyContinue" 
	if ($err)
	{
		Invoke-Expression "Add-PSSnapin $snapin -ErrorVariable Adderr -ErrorAction SilentlyContinue"
		
		# if we were not able to add the CMDlet, we will throw this error message
		if ($Adderr)
		{
			write "An error occured while adding the PSSnapin '$snapin'. It seems as if the CMDlet was not installed. Please use the '.\cru.ps1 -installcmdlet' command in order to install the CMDlet and run this command again."
			exit -1
		}
	}
}

# ------------------------------------------------------------------------------
# in order to check for linked value replication and we have to read the current Forest Funtional Level
# linked value replication is only available for FFL Windows Server 2003 and higher
# ------------------------------------------------------------------------------
function GetForestMode()
{
if ($Elevated  -eq "True") 
{
	$rootDSE = [ADSI]"LDAP://rootDSE"
	$rootdomain = $rootDSE.RootDomainNamingContext
	Invoke-Expression "Set-Variable -Name RootDomain -scope script -value $RootDomain"
	
	$forestmode = $rootDSE.ForestFunctionality
	Invoke-Expression "Set-Variable -Name ForestMode -scope script -value $forestmode"
}
}

# ------------------------------------------------------------------------------
# if no parameters were provided (or the wrong ones), we will provide the following script help
# ------------------------------------------------------------------------------
function Help() 
{
	write ""
    write "Credential Roaming Util Help"
	write "============================"
    write ""
    write "  Commands:"
    write ""
    write "  .\cru.ps1 -dumpconfig <local> [-username <username>] [-verbose enable]"
    write ""
	write "  .\cru.ps1 -eventlog <enable / disable / export>"
	write ""
	write "  .\cru.ps1 -installcmdlet <CredRoamLocalUserData / CredRoamADUserData / CredRoamLVRData>"
    write ""
	write ""
	write "  .\cru.ps1 -GetCredRoamLocalUserData <statefile / filesystem>" 
	write ""
	write "  .\cru.ps1 -GetCredRoamLVRData <attribute / object> -DcToUse <DC_NAME> [-username <DOMAIN\sAMAccountName>]"
	write ""
	write "  .\cru.ps1 -GetCredRoamADData <attribute / object> -DcToUse <DC_NAME> [-username <DOMAIN\sAMAccountName>]"
	write ""
	write "  .\cru.ps1 -GetCredRoamStatus <compare / all> -DcToUse <DC_NAME> [-username <DOMAIN\sAMAccountName>]"
	write ""
	write "  .\cru.ps1 -help"
	write ""
	write ""
    write "-dumpconfig `t`t Which configuration should be dumped?" 
	write "`t`t`t Possible parameters: 'local'"
	write "`t`t`t Additional parameters: '-verbose enable' to get the ACLs and change dates of all roamed files in local filesystem"
    write ""
	write "-GetCredRoamLocalUserData `t`t Dumps the local user data (shows keyfiles or statefile information)."
	write "`t`t`t Possible parameters: 'statefile', 'filesystem'"
	write ""
	write "-GetCredRoamLVRData `t Dumps the credential roaming LVR data of the user object in AD."
	write "`t`t`t Possible parameters: 'attribute', 'object'"
	write ""
	write "-GetCredRoamADData `t Dumps the credential roaming non-LVR data of the user object in AD."
	write "`t`t`t Possible parameters: 'attribute', 'object'"
	write ""
	write "-GetCredRoamStatus `t Dumps the credential roaming status of a user object for local filesystem, AD and state.dat."
	write "`t`t`t Possible parameters: 'compare', 'all'"
	write ""
	write "-username `t`t Which user should be targeted?"
	write "`t`t`t Has to use the format 'DOMAIN\sAMAccountName'."
	write "`t`t`t The user must be currently logged on to the machine in order to read the user settings. "
	write ""    
	write "-eventlog `t`t You can do the following with Credential Roaming Eventlog:" 
	write "`t`t`t enable - enable the Credential Roaming Eventlog"
	write "`t`t`t disable - disable the Credential Roaming Eventlog"
	write "`t`t`t export - export the Credential Roaming Eventlog"
	write ""
	write "-installcmdlet `t`t Installs the necessary CMDlet DLLs and registers them."
	write "`t`t`t You have to provide the CMDlet to install, 'CredRoamLocalUserData', 'CredRoamADUserData' or 'CredRoamLVRData' can be used."
    write ""
    write "-help `t`t`t Show this help."
    write ""
	write ""
	write "If using only the '-dumpconfig' or '-eventlog' parameter you do not have to install the PowerShell CMDlets. Otherwise the CMDlets are needed and you have to install them depending on your needs."
	write ""
	write "If you do not provide a username we consider the logged on user to be targeted for the query. If you want to use another logged on user, you have to use the '-username' switch."
	write ""
    write ""       
}


#region Common utilities
[void][System.Reflection.Assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')

function ShowEULAPopup($mode)
{
    $EULA = New-Object -TypeName System.Windows.Forms.Form
    $richTextBox1 = New-Object System.Windows.Forms.RichTextBox
    $btnAcknowledge = New-Object System.Windows.Forms.Button
    $btnCancel = New-Object System.Windows.Forms.Button

    $EULA.SuspendLayout()
    $EULA.Name = "EULA"
    $EULA.Text = "Microsoft Diagnostic Tools End User License Agreement"

    $richTextBox1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $richTextBox1.Location = New-Object System.Drawing.Point(12,12)
    $richTextBox1.Name = "richTextBox1"
    $richTextBox1.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $richTextBox1.Size = New-Object System.Drawing.Size(776, 397)
    $richTextBox1.TabIndex = 0
    $richTextBox1.ReadOnly=$True
    $richTextBox1.Add_LinkClicked({Start-Process -FilePath $_.LinkText})
    $richTextBox1.Rtf = @"
{\rtf1\ansi\ansicpg1252\deff0\nouicompat{\fonttbl{\f0\fswiss\fprq2\fcharset0 Segoe UI;}{\f1\fnil\fcharset0 Calibri;}{\f2\fnil\fcharset0 Microsoft Sans Serif;}}
{\colortbl ;\red0\green0\blue255;}
{\*\generator Riched20 10.0.19041}{\*\mmathPr\mdispDef1\mwrapIndent1440 }\viewkind4\uc1 
\pard\widctlpar\f0\fs19\lang1033 MICROSOFT SOFTWARE LICENSE TERMS\par
Microsoft Diagnostic Scripts and Utilities\par
\par
{\pict{\*\picprop}\wmetafile8\picw26\pich26\picwgoal32000\pichgoal15 
0100090000035000000000002700000000000400000003010800050000000b0200000000050000
000c0202000200030000001e000400000007010400040000000701040027000000410b2000cc00
010001000000000001000100000000002800000001000000010000000100010000000000000000
000000000000000000000000000000000000000000ffffff00000000ff040000002701ffff0300
00000000
}These license terms are an agreement between you and Microsoft Corporation (or one of its affiliates). IF YOU COMPLY WITH THESE LICENSE TERMS, YOU HAVE THE RIGHTS BELOW. BY USING THE SOFTWARE, YOU ACCEPT THESE TERMS.\par
{\pict{\*\picprop}\wmetafile8\picw26\pich26\picwgoal32000\pichgoal15 
0100090000035000000000002700000000000400000003010800050000000b0200000000050000
000c0202000200030000001e000400000007010400040000000701040027000000410b2000cc00
010001000000000001000100000000002800000001000000010000000100010000000000000000
000000000000000000000000000000000000000000ffffff00000000ff040000002701ffff0300
00000000
}\par
\pard 
{\pntext\f0 1.\tab}{\*\pn\pnlvlbody\pnf0\pnindent0\pnstart1\pndec{\pntxta.}}
\fi-360\li360 INSTALLATION AND USE RIGHTS. Subject to the terms and restrictions set forth in this license, Microsoft Corporation (\ldblquote Microsoft\rdblquote ) grants you (\ldblquote Customer\rdblquote  or \ldblquote you\rdblquote ) a non-exclusive, non-assignable, fully paid-up license to use and reproduce the script or utility provided under this license (the "Software"), solely for Customer\rquote s internal business purposes, to help Microsoft troubleshoot issues with one or more Microsoft products, provided that such license to the Software does not include any rights to other Microsoft technologies (such as products or services). \ldblquote Use\rdblquote  means to copy, install, execute, access, display, run or otherwise interact with the Software. \par
\pard\widctlpar\par
\pard\widctlpar\li360 You may not sublicense the Software or any use of it through distribution, network access, or otherwise. Microsoft reserves all other rights not expressly granted herein, whether by implication, estoppel or otherwise. You may not reverse engineer, decompile or disassemble the Software, or otherwise attempt to derive the source code for the Software, except and to the extent required by third party licensing terms governing use of certain open source components that may be included in the Software, or remove, minimize, block, or modify any notices of Microsoft or its suppliers in the Software. Neither you nor your representatives may use the Software provided hereunder: (i) in a way prohibited by law, regulation, governmental order or decree; (ii) to violate the rights of others; (iii) to try to gain unauthorized access to or disrupt any service, device, data, account or network; (iv) to distribute spam or malware; (v) in a way that could harm Microsoft\rquote s IT systems or impair anyone else\rquote s use of them; (vi) in any application or situation where use of the Software could lead to the death or serious bodily injury of any person, or to physical or environmental damage; or (vii) to assist, encourage or enable anyone to do any of the above.\par
\par
\pard\widctlpar\fi-360\li360 2.\tab DATA. Customer owns all rights to data that it may elect to share with Microsoft through using the Software. You can learn more about data collection and use in the help documentation and the privacy statement at {{\field{\*\fldinst{HYPERLINK https://aka.ms/privacy }}{\fldrslt{https://aka.ms/privacy\ul0\cf0}}}}\f0\fs19 . Your use of the Software operates as your consent to these practices.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 3.\tab FEEDBACK. If you give feedback about the Software to Microsoft, you grant to Microsoft, without charge, the right to use, share and commercialize your feedback in any way and for any purpose.\~ You will not provide any feedback that is subject to a license that would require Microsoft to license its software or documentation to third parties due to Microsoft including your feedback in such software or documentation. \par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 4.\tab EXPORT RESTRICTIONS. Customer must comply with all domestic and international export laws and regulations that apply to the Software, which include restrictions on destinations, end users, and end use. For further information on export restrictions, visit {{\field{\*\fldinst{HYPERLINK https://aka.ms/exporting }}{\fldrslt{https://aka.ms/exporting\ul0\cf0}}}}\f0\fs19 .\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360\qj 5.\tab REPRESENTATIONS AND WARRANTIES. Customer will comply with all applicable laws under this agreement, including in the delivery and use of all data. Customer or a designee agreeing to these terms on behalf of an entity represents and warrants that it (i) has the full power and authority to enter into and perform its obligations under this agreement, (ii) has full power and authority to bind its affiliates or organization to the terms of this agreement, and (iii) will secure the permission of the other party prior to providing any source code in a manner that would subject the other party\rquote s intellectual property to any other license terms or require the other party to distribute source code to any of its technologies.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360\qj 6.\tab DISCLAIMER OF WARRANTY. THE SOFTWARE IS PROVIDED \ldblquote AS IS,\rdblquote  WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL MICROSOFT OR ITS LICENSORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\par
\pard\widctlpar\qj\par
\pard\widctlpar\fi-360\li360\qj 7.\tab LIMITATION ON AND EXCLUSION OF DAMAGES. IF YOU HAVE ANY BASIS FOR RECOVERING DAMAGES DESPITE THE PRECEDING DISCLAIMER OF WARRANTY, YOU CAN RECOVER FROM MICROSOFT AND ITS SUPPLIERS ONLY DIRECT DAMAGES UP TO U.S. $5.00. YOU CANNOT RECOVER ANY OTHER DAMAGES, INCLUDING CONSEQUENTIAL, LOST PROFITS, SPECIAL, INDIRECT, OR INCIDENTAL DAMAGES. This limitation applies to (i) anything related to the Software, services, content (including code) on third party Internet sites, or third party applications; and (ii) claims for breach of contract, warranty, guarantee, or condition; strict liability, negligence, or other tort; or any other claim; in each case to the extent permitted by applicable law. It also applies even if Microsoft knew or should have known about the possibility of the damages. The above limitation or exclusion may not apply to you because your state, province, or country may not allow the exclusion or limitation of incidental, consequential, or other damages.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 8.\tab BINDING ARBITRATION AND CLASS ACTION WAIVER. This section applies if you live in (or, if a business, your principal place of business is in) the United States.  If you and Microsoft have a dispute, you and Microsoft agree to try for 60 days to resolve it informally. If you and Microsoft can\rquote t, you and Microsoft agree to binding individual arbitration before the American Arbitration Association under the Federal Arbitration Act (\ldblquote FAA\rdblquote ), and not to sue in court in front of a judge or jury. Instead, a neutral arbitrator will decide. Class action lawsuits, class-wide arbitrations, private attorney-general actions, and any other proceeding where someone acts in a representative capacity are not allowed; nor is combining individual proceedings without the consent of all parties. The complete Arbitration Agreement contains more terms and is at {{\field{\*\fldinst{HYPERLINK https://aka.ms/arb-agreement-4 }}{\fldrslt{https://aka.ms/arb-agreement-4\ul0\cf0}}}}\f0\fs19 . You and Microsoft agree to these terms. \par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 9.\tab LAW AND VENUE. If U.S. federal jurisdiction exists, you and Microsoft consent to exclusive jurisdiction and venue in the federal court in King County, Washington for all disputes heard in court (excluding arbitration). If not, you and Microsoft consent to exclusive jurisdiction and venue in the Superior Court of King County, Washington for all disputes heard in court (excluding arbitration).\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 10.\tab ENTIRE AGREEMENT. This agreement, and any other terms Microsoft may provide for supplements, updates, or third-party applications, is the entire agreement for the software.\par
\pard\sa200\sl276\slmult1\f1\fs22\lang9\par
\pard\f2\fs17\lang2057\par
}
"@
    $richTextBox1.BackColor = [System.Drawing.Color]::White
    $btnAcknowledge.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnAcknowledge.Location = New-Object System.Drawing.Point(544, 415)
    $btnAcknowledge.Name = "btnAcknowledge";
    $btnAcknowledge.Size = New-Object System.Drawing.Size(119, 23)
    $btnAcknowledge.TabIndex = 1
    $btnAcknowledge.Text = "Accept"
    $btnAcknowledge.UseVisualStyleBackColor = $True
    $btnAcknowledge.Add_Click({$EULA.DialogResult=[System.Windows.Forms.DialogResult]::Yes})

    $btnCancel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnCancel.Location = New-Object System.Drawing.Point(669, 415)
    $btnCancel.Name = "btnCancel"
    $btnCancel.Size = New-Object System.Drawing.Size(119, 23)
    $btnCancel.TabIndex = 2
    if($mode -ne 0)
    {
	    $btnCancel.Text = "Close"
    }
    else
    {
	    $btnCancel.Text = "Decline"
    }
    $btnCancel.UseVisualStyleBackColor = $True
    $btnCancel.Add_Click({$EULA.DialogResult=[System.Windows.Forms.DialogResult]::No})

    $EULA.AutoScaleDimensions = New-Object System.Drawing.SizeF(6.0, 13.0)
    $EULA.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    $EULA.ClientSize = New-Object System.Drawing.Size(800, 450)
    $EULA.Controls.Add($btnCancel)
    $EULA.Controls.Add($richTextBox1)
    if($mode -ne 0)
    {
	    $EULA.AcceptButton=$btnCancel
    }
    else
    {
        $EULA.Controls.Add($btnAcknowledge)
	    $EULA.AcceptButton=$btnAcknowledge
        $EULA.CancelButton=$btnCancel
    }
    $EULA.ResumeLayout($false)
    $EULA.Size = New-Object System.Drawing.Size(800, 650)

    Return ($EULA.ShowDialog())
}

function ShowEULAIfNeeded($toolName, $mode)
{
	$eulaRegPath = "HKCU:Software\Microsoft\CESDiagnosticTools"
	$eulaAccepted = "No"
	$eulaValue = $toolName + " EULA Accepted"
	if(Test-Path $eulaRegPath)
	{
		$eulaRegKey = Get-Item $eulaRegPath
		$eulaAccepted = $eulaRegKey.GetValue($eulaValue, "No")
	}
	else
	{
		$eulaRegKey = New-Item $eulaRegPath
	}
	if($mode -eq 2) # silent accept
	{
		$eulaAccepted = "Yes"
       		$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
	}
	else
	{
		if($eulaAccepted -eq "No")
		{
			$eulaAccepted = ShowEULAPopup($mode)
			if($eulaAccepted -eq [System.Windows.Forms.DialogResult]::Yes)
			{
	        		$eulaAccepted = "Yes"
	        		$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
			}
		}
	}
	return $eulaAccepted
}


############################ function definition end #######################################

############################ main section begin #######################################

## EULA

# Show EULA if needed.
If($AcceptEULA.IsPresent){
    $eulaAccepted = ShowEULAIfNeeded "Credential Roaming PS Tool" 2  # Silent accept mode.
}Else{
    $eulaAccepted = ShowEULAIfNeeded "Credential Roaming PS Tool" 0  # Show EULA popup at first run.
}


if ($eulaAccepted -eq "No")
{
    write "EULA not accepted, exiting!"
    exit -1
}


if ($script:args -eq "-help")
{
    Help
    exit -1
}

# ------------------------------------------------------------------------------
# before we start we have to check if the prequisites are met in order to run the script correctly
# additionally we collect the necessary environment data and put the data into script wide usable vars
# ------------------------------------------------------------------------------
Elevated
if ($global:userElevated -eq "True")
{
GetOSVersion
GetProcessorArchitecture
}
GetUserNameAndSid

# ------------------------------------------------------------------------------
# now we check the command lines in order to get the information which action item should be performed
# ------------------------------------------------------------------------------
if ($InstallCMDlet -ne "")
{
	if ($global:userElevated -eq "True")
    {
    InstallCMDlet
	exit 1
    }
	if ($global:userElevated -eq "False")
    {
    write "CMD installation works only in elevated mode. Please logon as local admin"
    exit -1
    }
}

if ($DumpConfig -eq "local") 
{
	
	GetUserEnvironment
	if ($global:userElevated -eq "True")
    {
    DumpLocalCfg
    }
    Invoke-Expression "certutil -silent -v -store -user my > certutilmystore_verbose.txt"
    Invoke-Expression "certutil -silent -store -user my > certutilmystore.txt"
    $SystemCertificates = ${env:userprofile} + "\AppData\Roaming\Microsoft\SystemCertificates"
    Get-ChildItem -Path $SystemCertificates –Recurse -Force > SystemCertificateLocalFolder.txt
    $PrivKeys = ${env:userprofile} + "\AppData\Roaming\Microsoft\Crypto"
    Get-ChildItem -Path $PrivKeys –Recurse -Force > CryptoLocalFolder.txt
    $MasterKeys = ${env:userprofile} + "\AppData\Roaming\Microsoft\Protect"
    Get-ChildItem -Path $MasterKeys –Recurse -Force > ProtectLocalFolder.txt

	exit 1
}

if ($EventLog -ne "") 
{
	if ($global:userElevated -eq "True")
    {
    EventLog
    }
	exit 1
}

if ($GetCredRoamLocalUserData -ne "") 
{
	# in order to use the CMDlets we have to add them in the current session before starting
	AddPSSnapin("CredRoamLocalUserData")
	GetUserEnvironment
	GetCredRoamLocalUserData
	exit 1
}

if ($GetCredRoamLVRData -ne "") 
{
# ------------------------------------------------------------------------------
# LVR is only available for Forest Functional Level or higher, therefore we perform this check before starting with this CMDlet
# ------------------------------------------------------------------------------
	if ($global:userElevated -eq "True")
    {
    GetForestMode
    }
    GetNetFrameWorkVersion
	#if (($forestmode -gt "1"))  Windows Server 2003 is not supported
    if ($TRUE)
	{
		# in order to use the CMDlets we have to add them in the current session before starting
		AddPSSnapin("CredRoamLVRData")
		GetCredRoamLVRData
		exit 1
	}
	else
	{
		write ""
		write "WARNING:"
		write "Linked Value Replication is available only in Forest Functional Level 'Windows Server 2003' and higher."
		write "Cannot proceed since the Forest Functional Level is below 'Windows Server 2003'."
		write ""
		exit -1
	}
}

if ($GetCredRoamADData -ne "") 
{
	# in order to use the CMDlets we have to add them in the current session before starting
	GetNetFrameWorkVersion
	AddPSSnapin("CredRoamADData")
	GetCredRoamADData
	exit 1
}

if ($GetCredRoamStatus -ne "") 
{
	# in order to use the CMDlets we have to add them in the current session before starting, this function needs two CMDlets
	GetNetFrameWorkVersion
	AddPSSnapin("CredRoamLocalUserData")
	AddPSSnapin("CredRoamADData")
	GetUserEnvironment
	GetCredRoamStatus
	exit 1
}
Write-Host ""
write-Warning "Error: No known parameters provided."
write-Warning "Use '.\cru.ps1 -help' to get help with this script."
Write-Host

############################ main section end #######################################
# SIG # Begin signature block
# MIIoPAYJKoZIhvcNAQcCoIIoLTCCKCkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBUIXN2uwgEZReG
# +7kU/OoADZVLWLs27ExlsCWQ6p3mG6CCDYUwggYDMIID66ADAgECAhMzAAADri01
# UchTj1UdAAAAAAOuMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwODU5WhcNMjQxMTE0MTkwODU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQD0IPymNjfDEKg+YyE6SjDvJwKW1+pieqTjAY0CnOHZ1Nj5irGjNZPMlQ4HfxXG
# yAVCZcEWE4x2sZgam872R1s0+TAelOtbqFmoW4suJHAYoTHhkznNVKpscm5fZ899
# QnReZv5WtWwbD8HAFXbPPStW2JKCqPcZ54Y6wbuWV9bKtKPImqbkMcTejTgEAj82
# 6GQc6/Th66Koka8cUIvz59e/IP04DGrh9wkq2jIFvQ8EDegw1B4KyJTIs76+hmpV
# M5SwBZjRs3liOQrierkNVo11WuujB3kBf2CbPoP9MlOyyezqkMIbTRj4OHeKlamd
# WaSFhwHLJRIQpfc8sLwOSIBBAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhx/vdKmXhwc4WiWXbsf0I53h8T8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMTgzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AGrJYDUS7s8o0yNprGXRXuAnRcHKxSjFmW4wclcUTYsQZkhnbMwthWM6cAYb/h2W
# 5GNKtlmj/y/CThe3y/o0EH2h+jwfU/9eJ0fK1ZO/2WD0xi777qU+a7l8KjMPdwjY
# 0tk9bYEGEZfYPRHy1AGPQVuZlG4i5ymJDsMrcIcqV8pxzsw/yk/O4y/nlOjHz4oV
# APU0br5t9tgD8E08GSDi3I6H57Ftod9w26h0MlQiOr10Xqhr5iPLS7SlQwj8HW37
# ybqsmjQpKhmWul6xiXSNGGm36GarHy4Q1egYlxhlUnk3ZKSr3QtWIo1GGL03hT57
# xzjL25fKiZQX/q+II8nuG5M0Qmjvl6Egltr4hZ3e3FQRzRHfLoNPq3ELpxbWdH8t
# Nuj0j/x9Crnfwbki8n57mJKI5JVWRWTSLmbTcDDLkTZlJLg9V1BIJwXGY3i2kR9i
# 5HsADL8YlW0gMWVSlKB1eiSlK6LmFi0rVH16dde+j5T/EaQtFz6qngN7d1lvO7uk
# 6rtX+MLKG4LDRsQgBTi6sIYiKntMjoYFHMPvI/OMUip5ljtLitVbkFGfagSqmbxK
# 7rJMhC8wiTzHanBg1Rrbff1niBbnFbbV4UDmYumjs1FIpFCazk6AADXxoKCo5TsO
# zSHqr9gHgGYQC2hMyX9MGLIpowYCURx3L7kUiGbOiMwaMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEfa
# HOdEz58g6vv8Cqkadtk/tcQw9sYV5zX6lL4jf2cdMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAEzmNBxJiGQiS5BPBVtWHV3y30IMUAVGK7jtZ
# 4pkACldxFuAKfvaaO6eZ7a/pJFnBi/Nyle3W3hzHrkUSShxUwlcEYPDbE6Agp00G
# 2rw5ny4UGGZbdatlA2mSJ9S/0lehQCi4K21reDQa2XxbFQ2cWlt0liqLNMUz207V
# kPaDWpH+JNMwHSO8wGlvyX4r7oFckrC0DPdkdTwlMHpI9CrvSW7orVfy2bFZIwxJ
# 2EVzM1kQ4W09gUqswQobO/g/FsTYlOlEE+BkUg3W4bNPQb+1KfmmLQddzNkAVmJv
# MN+MDDUNPLPGZVVnf0l5Jxh22SqLdYIrC8sqz4xe2ZzuH3SUSaGCF5cwgheTBgor
# BgEEAYI3AwMBMYIXgzCCF38GCSqGSIb3DQEHAqCCF3AwghdsAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFSBgsqhkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCA/9rMIbKnEhtjhBKoK7fW/ruUo9K+cTKW2
# Syeb23T+IwIGZfxqW670GBMyMDI0MDQwNDEzMzIzNS41MDVaMASAAgH0oIHRpIHO
# MIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
# IFRTUyBFU046MzcwMy0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFNlcnZpY2WgghHtMIIHIDCCBQigAwIBAgITMwAAAeqaJHLVWT9hYwAB
# AAAB6jANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDAeFw0yMzEyMDYxODQ1MzBaFw0yNTAzMDUxODQ1MzBaMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzcwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC1C1/xSD8gB9X7Ludoo2rW
# b2ksqaF65QtJkbQpmsc6G4bg5MOv6WP/uJ4XOJvKX/c1t0ej4oWBqdGD6VbjXX4T
# 0KfylTulrzKtgxnxZh7q1uD0Dy/w5G0DJDPb6oxQrz6vMV2Z3y9ZxjfZqBnDfqGo
# n/4VDHnZhdas22svSC5GHywsQ2J90MM7L4ecY8TnLI85kXXTVESb09txL2tHMYrB
# +KHCy08ds36an7IcOGfRmhHbFoPa5om9YGpVKS8xeT7EAwW7WbXL/lo5p9KRRIjA
# lsBBHD1TdGBucrGC3TQXSTp9s7DjkvvNFuUa0BKsz6UiCLxJGQSZhd2iOJTEfJ1f
# xYk2nY6SCKsV+VmtV5aiPzY/sWoFY542+zzrAPr4elrvr9uB6ci/Kci//EOERZEU
# TBPXME/ia+t8jrT2y3ug15MSCVuhOsNrmuZFwaRCrRED0yz4V9wlMTGHIJW55iNM
# 3HPVJJ19vOSvrCP9lsEcEwWZIQ1FCyPOnkM1fs7880dahAa5UmPqMk5WEKxzDPVp
# 081X5RQ6HGVUz6ZdgQ0jcT59EG+CKDPRD6mx8ovzIpS/r/wEHPKt5kOhYrjyQHXc
# 9KHKTWfXpAVj1Syqt5X4nr+Mpeubv+N/PjQEPr0iYJDjSzJrqILhBs5pytb6vyR8
# HUVMp+mAA4rXjOw42vkHfQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFCuBRSWiUebp
# F0BU1MTIcosFblleMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQAog61WXj9+/nxV
# bX3G37KgvyoNAnuu2w3HoWZj3H0YCeQ3b9KSZThVThW4iFcHrKnhFMBbXJX4uQI5
# 3kOWSaWCaV3xCznpRt3c4/gSn3dvO/1GP3MJkpJfgo56CgS9zLOiP31kfmpUdPqe
# kZb4ivMR6LoPb5HNlq0WbBpzFbtsTjNrTyfqqcqAwc6r99Df2UQTqDa0vzwpA8Cx
# iAg2KlbPyMwBOPcr9hJT8sGpX/ZhLDh11dZcbUAzXHo1RJorSSftVa9hLWnzxGzE
# GafPUwLmoETihOGLqIQlCpvr94Hiak0Gq0wY6lduUQjk/lxZ4EzAw/cGMek8J3Qd
# iNS8u9ujYh1B7NLr6t3IglfScDV3bdVWet1itTUoKVRLIivRDwAT7dRH13Cq32j2
# JG5BYu/XitRE8cdzaJmDVBzYhlPl9QXvC+6qR8I6NIN/9914bTq/S4g6FF4f1dix
# UxE4qlfUPMixGr0Ft4/S0P4fwmhs+WHRn62PB4j3zCHixKJCsRn9IR3ExBQKQdMi
# 5auiqB6xQBADUf+F7hSKZfbA8sFSFreLSqhvj+qUQF84NcxuaxpbJWVpsO18IL4Q
# bt45Cz/QMa7EmMGNn7a8MM3uTQOlQy0u6c/jq111i1JqMjayTceQZNMBMM5EMc5D
# r5m3T4bDj9WTNLgP8SFe3EqTaWVMOTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKb
# SZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIy
# NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXI
# yjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjo
# YH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1y
# aa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v
# 3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pG
# ve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viS
# kR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYr
# bqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlM
# jgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSL
# W6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AF
# emzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIu
# rQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIE
# FgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWn
# G1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEW
# M2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5
# Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBi
# AEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV
# 9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3Js
# Lm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAx
# MC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2
# LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv
# 6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZn
# OlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1
# bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4
# rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU
# 6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDF
# NLB62FD+CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/
# HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdU
# CbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKi
# excdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTm
# dHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZq
# ELQdVTNYs6FwZvKhggNQMIICOAIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjM3MDMtMDVF
# MC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMK
# AQEwBwYFKw4DAhoDFQCJ2x7cQfjpRskJ8UGIctOCkmEkj6CBgzCBgKR+MHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6bizojAi
# GA8yMDI0MDQwNDA1MDUzOFoYDzIwMjQwNDA1MDUwNTM4WjB3MD0GCisGAQQBhFkK
# BAExLzAtMAoCBQDpuLOiAgEAMAoCAQACAhTwAgH/MAcCAQACAhKRMAoCBQDpugUi
# AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSCh
# CjAIAgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAHGEu6Md+1Twaah2vSeVe/i9
# 2GmGd0s31Zv+ghIuwp0DQ4v/CeTQZYvaWyFSmRPt0+i9pwt4jJUKhCdmYae5ZFaW
# hBxUIZKpkaLY3SSp9GamiyilVFqqK0ZXBRxF6Kr1G8UsZf8PNBDRfOrZhzOfsuVC
# sjJiGdL6p1nZ4NBg2XCOASLIrCA7egHoZ1mMk5R1hdYoQ1d39LsezzvrC2fbD669
# wsmFwnrnBiDc9p4yI91/dEBqkmzLdgv7lsMTbE033d/XZHHD5/xlIGSCaFt/5or0
# 4PA688pP30mVmLu9kIzd/ISLVwGn7v4+9EjVFYFgvTicswjkjc5X0tJh87QI0aYx
# ggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAA
# AeqaJHLVWT9hYwABAAAB6jANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkD
# MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCABbCs5Dwc6jkbQ2GjCGN3l
# w65FhBU/2tYIo/J2lg3/JjCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EICmP
# odXjZDR4iwg0ltLANXBh5G1uKqKIvq8sjKekuGZ4MIGYMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHqmiRy1Vk/YWMAAQAAAeowIgQg/Ilw
# X3Qq5Og1YskkJiiPLOtdFp+fV3gbq5Y5DJcjYXcwDQYJKoZIhvcNAQELBQAEggIA
# QwlXLye8uIQziRcst9I29cuUTwav2Ozcd9orFaZBd6pLnigBMy4olyLCmVvt8lCE
# s4cu22+0pH5ONV8aOCt0Frx3jzYBdii/ILKilZlbv8f1D6kTP65qJhGHC53jmHRO
# pcbfKa1uqTyLw11+EyTJ70k8irp/hksDbtiRNZ0hXQTeV8bH4qmt5uMfUvL/bbfA
# JXP6Na3QTuBJl1X9rrpJA//0Oyp4x7okjdQh5jGsKDGT2US3a6xNgn8PmUdfJ+oX
# xfol6caGpUFtuYgHR0OY6ML7LlNYXZOa4xEhP8aU3Qh0WIEBCoAh1QTBHlFWOjoV
# o+ssO8zmX7IK2Wbi9Us06GVM9UnCV5xi4MOEv8kuNf7mFbaYnVDidQDQKOgMylgC
# J6S5VkituigN7rFWalEMpqFnwkpUMVaIhYmi9BJrqt+8htfMWj9L8+zyxeMAnFW0
# eOoadCUkr+ZdzlrP5FWp81nzSAOGtl1OnGBJ985Kf8T8EHbmQL14xHfTwKzQIzy8
# aZSWyXTD4AYEST65eowCAor07oI/RaEDaf2vcERTkBzRXxs62XzJzw8oZZQWipon
# ReAWaVHwtoIuGP/4CHoNbfARU6yyhoPWlq4sCRNIwXGxKSz1i0IQA1wyUhIGOief
# Bd9XkyV0l151AdLh5qIiB6v9oW0lMlcHmOvHmD0x1qo=
# SIG # End signature block
