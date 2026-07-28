# ***********************************************************************************************
# File: utils_ConfigMgr12-ps1
# Version 1.0
# Date: 02-17-2012 - Last edit 2022-06-01
# Author: Vinay Pamnani - vinpa@microsoft.com
# Description:  Utility Script to load common variables/functions. View utils_ConfigMgr07_ReadMe.txt for details.
# 		1. Defines commonly used functions in the Troubleshooter
# 		2. Defines global variables
# 		3. Detects Configuration Manager Client and Server Roles Installation Status
#		4. Detects Install and Log Locations for Client, Server, Admin Console and WSUS
#		5. Executes WSUSutil.exe checkhealth, if WSUS is installed.
# ***********************************************************************************************

trap [Exception]
{
	WriteTo-ErrorDebugReport -ErrorRecord $_
	continue
}

# Manifest Name - Used for Logging
Set-Variable -Name ManifestName -Value "CM12" -Scope Global
Set-Variable -Name ManifestLog -Value (Join-Path -Path ($PWD.Path) -ChildPath "..\_SDPExecution_log.txt") -Scope Global

if (Test-Path $ManifestLog) {
	Remove-Item -Path $ManifestLog -Force
}

##########################
## Function Definitions ##
##########################

function TraceOut{
	# To standardize Logging to StdOut.log
    param (
		$WhatToWrite
		)
	process
	{
			$SName = ([System.IO.Path]::GetFileName($MyInvocation.ScriptName))
			$SName = $SName.Substring(0, $SName.LastIndexOf("."))
			$SLine = $MyInvocation.ScriptLineNumber.ToString()
			$STime =Get-Date -Format G
			WriteTo-StdOut "	$STime [$ManifestName][$ComputerName][$SName][$SLine] $WhatToWrite"
			"$STime [$ManifestName][$ComputerName][$SName][$SLine] $WhatToWrite" | Out-File -FilePath $ManifestLog -Append -ErrorAction SilentlyContinue
	}
}

function AddTo-CMClientSummary (){
	# Adds the specified name/value to the appropriate CMClient PS Objects so that they can be dumped to File & Report in DC_FinishExecution.
	param (
		$Name,
		$Value,
		[switch]$NoToSummaryFile,
		[switch]$NoToSummaryReport
	)

	process {
		if(-not($NoToSummaryFile)) {
			Add-Member -InputObject $global:CMClientFileSummaryPSObject -MemberType NoteProperty -Name $Name -Value $Value
		}

		if (-not($NoToSummaryReport)) {
			Add-Member -InputObject $global:CMClientReportSummaryPSObject -MemberType NoteProperty -Name $Name -Value $Value
		}
	}
}

function AddTo-CMServerSummary (){
	# Adds the specified name/value to the appropriate CMServer PS Objects so that they can be dumped to File & Report in DC_FinishExecution.
	param (
		$Name,
		$Value,
		[switch]$NoToSummaryFile,
		[switch]$NoToSummaryReport
	)

	process {
		if(-not($NoToSummaryFile)) {
			Add-Member -InputObject $global:CMServerFileSummaryPSObject -MemberType NoteProperty -Name $Name -Value $Value
		}

		if (-not($NoToSummaryReport)) {
			Add-Member -InputObject $global:CMServerReportSummaryPSObject -MemberType NoteProperty -Name $Name -Value $Value
		}
	}
}

function AddTo-CMDatabaseSummary (){
	# Adds the specified name/value to the appropriate CMDatabase PS Objects so that they can be dumped to File & Report in DC_FinishExecution.
	param (
		$Name,
		$Value,
		[switch]$NoToSummaryFile,
		[switch]$NoToSummaryReport,
		[switch]$NoToSummaryQueries
	)

	process {
		if(-not($NoToSummaryFile)) {
			Add-Member -InputObject $global:CMDatabaseFileSummaryPSObject -MemberType NoteProperty -Name $Name -Value $Value
		}

		if (-not($NoToSummaryReport)) {
			Add-Member -InputObject $global:CMDatabaseReportSummaryPSObject -MemberType NoteProperty -Name $Name -Value $Value
		}

		if (-not($NoToSummaryQueries)) {
			Add-Member -InputObject $global:CMDatabaseQuerySummaryPSObject -MemberType NoteProperty -Name $Name -Value $Value
		}
	}
}

function Get-ADKVersion (){
	process {
		TraceOut "Get-ADKVersion: Entering"

		$UninstallKey = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
		$ADKKey = Get-ChildItem $UninstallKey -Recurse | ForEach-Object {Get-ItemProperty $_.PSPath} | Where-Object {$_.DisplayName -like '*Assessment and Deployment Kit*'}

		if ($ADKKey) {
			return $ADKKey.DisplayVersion
		}
		else {
			return "ADK Version Not Found."
		}

		TraceOut "Get-ADKVersion: Leaving"
	}
}

#########################################
## SMS Provider and Database Functions ##
#########################################

function Get-DBConnection (){
	param (
		$DatabaseServer,
		$DatabaseName
	)

	process {
		TraceOut "Get-DBConnection: Entering"
		try {
			# Get NetBIOS name of the Database Server
			If ($DatabaseServer.Contains(".")) {
				$DatabaseServer = $DatabaseServer.Substring(0,$DatabaseServer.IndexOf("."))
			}

			# Prepare a Connection String
			If ($DatabaseName.Contains("\")) {
				$InstanceName = $DatabaseName.Substring(0,$DatabaseName.IndexOf("\"))
				$DatabaseName = $DatabaseName.Substring($DatabaseName.IndexOf("\")+1)
				$strConnString = "Integrated Security=SSPI; Application Name=ConfigMgr Diagnostics; Server=$DatabaseServer\$InstanceName; Database=$DatabaseName"
			}
			Else {
				$strConnString = "Integrated Security=SSPI; Application Name=ConfigMgr Diagnostics; Server=$DatabaseServer; Database=$DatabaseName"
			}

			$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
			$SqlConnection.ConnectionString = $strConnString
			TraceOut "SQL Connection String: $strConnString"

			$Error.Clear()
			$SqlConnection.Open()
			TraceOut "Get-DBConnection: Successful"

			# Reset Error Variable only when we're connecting to SCCM database and the connection is successful.
			# If SCCM database connection failed, TS_CheckSQLConfig will retry connection to MASTER, but we don't want to reset Error Variable in that case, if connection succeeds.
			if ($DatabaseName.ToUpper() -ne "MASTER") {
				$global:DatabaseConnectionError = $null
			}
		}
		catch [Exception] {
			$global:DatabaseConnectionError = $_
			$SqlConnection = $null
			TraceOut "Get-DBConnection: Failed with Error: $global:DatabaseConnectionError"
		}

		TraceOut "Get-DBConnection: Leaving"
		return $SqlConnection
	}
}

######################
## Global Variables ##
######################

TraceOut "Script Started"
TraceOut "Setting Global Variables..."

# Get Current Time
Set-Variable -Name CurrentTime -Scope Global
$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	$CurrentTime = ($Temp.LocalDateTime).ToString()
	$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_TimeZone -ErrorAction SilentlyContinue
	If ($Temp -is [CimInstance]) {
		$CurrentTime += " $($Temp.Description)"
		if ((Get-Date).IsDayLightSavingTime()) {
			$CurrentTime += " - Daylight Saving Time"
		}
	}
}
else {
	$CurrentTime = Get-Date -Format G
}

# Remote Execution Status
Set-Variable RemoteStatus -Scope Global

# Set Software\Microsoft Registry Key path
Set-Variable Reg_MS -Value "HKLM\SOFTWARE\Microsoft" -Scope Global
Set-Variable Reg_MS6432 -Value "HKLM\SOFTWARE\Wow6432Node\Microsoft" -Scope Global

# Set SMS, CCM and WSUS Registry Key Path
Set-Variable -Name Reg_CCM -Value ($REG_MS + "\CCM") -Scope Global
Set-Variable -Name Reg_SMS -Value ($REG_MS + "\SMS") -Scope Global
Set-Variable -Name Reg_WSUS -Value "HKLM\Software\Microsoft\Update Services" -Scope Global

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

###############################
## Summary Files and Objects ##
###############################
# Summary Objects
Set-Variable -Name SummarySectionDescription -Scope Global -Value "ConfigMgr Data Collection Summary"
Set-Variable -Name CMClientFileSummaryPSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMClientReportSummaryPSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMServerFileSummaryPSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMServerReportSummaryPSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMDatabaseFileSummaryPSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMDatabaseReportSummaryPSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMDatabaseQuerySummaryPSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMRolesStatusFilePSObject -Scope Global -Value (New-Object PSObject)
Set-Variable -Name CMInstalledRolesStatusReportPSObject -Scope Global -Value (New-Object PSObject)

#####################
## Start Execution ##
#####################

Import-LocalizedData -BindingVariable ScriptStrings
Write-DiagProgress -Activity $ScriptStrings.ID_ACTIVITY_Utils -Status $ScriptStrings.ID_Utils_Init

# Print Variable values
TraceOut "Global Variable - OSArchitecture: $OSArchitecture" # $OSArchitecture is defined in utils_CTS.ps1
TraceOut "Global Variable - Reg_SMS: $Reg_SMS"
TraceOut "Global Variable - Reg_CCM: $Reg_CCM"
TraceOut "Global Variable - Reg_WSUS: $Reg_WSUS"

# --------------------------------------------------------------------------------------------
# Get Remote Execution Status from Get-TSRemote. The following return values can be returned:
#    0 - No TS_Remote environment
#    1 - Under TS_Remote environment, but running on the local machine
#    2 - Under TS_Remote environment and running on a remote machine
# --------------------------------------------------------------------------------------------
$RemoteStatus = (Get-TSRemote)
TraceOut "Global Remote Execution Status: $RemoteStatus"

# -----------------------
# Set CCM Setup Log Path
# -----------------------
$CCMSetupLogPath = Join-Path $Env:windir "ccmsetup"
TraceOut "Global Variable - CCMSetupLogPath: $CCMSetupLogPath"

# ---------------------------------
# Set Site System Global Variables
# ---------------------------------
#$InstalledRolesStatus = New-Object PSObject # For Update-DiagReport
#$RolesStatus = New-Object PSObject
$RolesArray = @{
"Client" = "Configuration Manager Client";
"SiteServer" = "Configuration Manager Site Server";
"SMSProv" = "SMS Provider Server";
"AdminUI" = "Configuration Manager Admin Console";
"AWEBSVC" = "Application Catalog Web Service Point";
"PORTALWEB" = "Application Catalog Website Point";
"AIUS" = "Asset Intelligence Synchronization Point";
"AMTSP" = "Out of Band Service Point";
"CRP" = "Certificate Registration Point";
"DP" = "Distribution Point";
"DWSS" = "Data Warehouse Service Point";
"ENROLLSRV" = "Enrollment Point";
"ENROLLWEB" = "Enrollment Proxy Point";
"EP" = "Endpoint Protection Point";
"FSP" = "Fallback Status Point";
"IIS" = "IIS Web Server";
"MCS" = "Distribution Point - Multicast Enabled";
"MP" = "Management Point";
"PullDP" = "Distribution Point - Pull Distribution Point";
"PXE" = "Distribution Point - PXE Enabled";
"SMP" = "State Migration Point";
"SMS_CLOUD_PROXYCONNECTOR" = "CMG Connection Point";
"SMSSHV" = "System Health Validator Point";
"SRSRP" = "Reporting Services Point";
"WSUS" = "Software Update Point"
}

foreach ($Role in ($RolesArray.Keys | Sort-Object))
{
	Switch ($Role)
	{
		"Client"
		{
			$Installed = Check-RegValueExists ($Reg_SMS + "\Mobile Client") "ProductVersion"
			If ($Installed) {
				$GetCCMLogs = $true
				$CCMLogPaths += (Get-RegValue ($Reg_CCM + "\Logging\@Global") "LogDirectory") + "\"
			}
		}

		"SiteServer"
		{
			$Installed = Check-RegValueExists ($Reg_SMS + "\Setup") "Full Version"
			If ($Installed) {
				$GetSMSLogs = $true ; $Is_SiteSystem = $true
			}
		}

		"SMSProv"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\Providers")
			If ($Installed) {
				$SMSProvLogPath = (Get-RegValue ($Reg_SMS + "\Providers") "Logging Directory")
			}
		}

		"AdminUI"
		{
			$Installed = Check-RegKeyExists ($Reg_MS6432 + "\ConfigMgr10\AdminUI")
			If ($Installed) {$AdminUILogPath = (Get-RegValue ($Reg_MS6432 + "\ConfigMgr10\AdminUI") "AdminUILog")}
		}

		"AWEBSVC"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$AppCatalogSvcLogPath = (Get-RegValue ($Reg_SMS + "\" + $Role + "\Logging") "AdminUILog")
				$Is_SiteSystem = $true
			}
		}

		"PORTALWEB"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$AppCatalogLogPath = (Get-RegValue ($Reg_SMS + "\" + $Role + "\Logging") "AdminUILog")
				$Is_SiteSystem = $true
			}
		}

		"AIUS"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$GetSMSLogs = $true ; $Is_SiteSystem = $true
			}
		}

		"AMTSP"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$GetSMSLogs = $true ; $Is_SiteSystem = $true
			}
		}

		"CRP"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$CRPLogPath = (Get-RegValue ($Reg_SMS + "\" + $Role + "\Logging") "AdminUILog")
				$Is_SiteSystem = $true
			}
		}

		"DP"
		{
			$Installed = Check-RegValueExists ($Reg_SMS + "\" + $Role) "NALPath"
			If ($Installed) { $GetSMSLogs = $true ; $Is_SiteSystem = $true }
		}

		"ENROLLSRV"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$EnrollPointLogPath = (Get-RegValue ($Reg_SMS + "\" + $Role + "\Logging") "AdminUILog")
				$Is_SiteSystem = $true
			}
		}

		"ENROLLWEB"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$EnrollProxyPointLogPath = (Get-RegValue ($Reg_SMS + "\" + $Role + "\Logging") "AdminUILog")
				$Is_SiteSystem = $true
			}
		}

		"EP"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\Operations Management\Components\SMS_ENDPOINT_PROTECTION_CONTROL_MANAGER")
		}

		"FSP"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$GetCCMLogs = $true ; $GetSMSLogs = $true
				$CCMLogPaths += Get-RegValue ($Reg_SMS + "\" + $Role +"\Logging\@Global") "LogDirectory"
				$Is_SiteSystem = $true
			}
		}

		"MCS"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$GetCCMLogs = $true ; $GetSMSLogs = $true ;
				$CCMLogPaths += Get-RegValue ($Reg_SMS + "\" + $Role +"\Logging\@Global") "LogDirectory"
				$Is_SiteSystem = $true
			}
		}

		"MP"
		{
			$Installed = Check-RegValueExists ($Reg_SMS + "\" + $Role) "MP Hostname"
			If ($Installed) {
				$GetCCMLogs = $true ; $GetSMSLogs = $true ;
				$Is_SiteSystem = $true
				$CCMLogPaths += (Get-RegValue ($Reg_CCM + "\Logging\@Global") "LogDirectory") + "\"
			}
		}

		"PullDP"
		{
			$Temp = Get-RegValue ($Reg_SMS + "\DP") "IsPullDP"
			If ($Temp) { $Installed = $true } Else { $Installed = $false }
			If ($Installed) {
				$GetCCMLogs = $true
				$Is_SiteSystem = $true
				$CCMLogPaths += (Get-RegValue ($Reg_CCM + "\Logging\@Global") "LogDirectory") + "\"
			}
		}

		"PXE"
		{
			$Temp = Get-RegValue ($Reg_SMS + "\DP") "IsPXE"
			If ($Temp) { $Installed = $true } Else { $Installed = $false }
			If ($Installed) {
				$GetCCMLogs = $true ; $GetSMSLogs = $true ;
				$Is_SiteSystem = $true
				$CCMLogPaths += Get-RegValue ($Reg_SMS + "\" + $Role +"\Logging\@Global") "LogDirectory"
			}
		}

		"SMP"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$GetCCMLogs = $true ; $GetSMSLogs = $true ;
				$CCMLogPaths += Get-RegValue ($Reg_SMS + "\" + $Role +"\Logging\@Global") "LogDirectory"
				$Is_SiteSystem = $true
			}
		}

		"SMSSHV"
		{
			$Installed = Check-RegKeyExists ($Reg_MS + "\" + $Role)
			If ($Installed) {
				$GetSMSLogs = $true
				$SMSSHVLogPath = (Get-RegValue ($Reg_MS + "\" + $Role + "\Logging\@Global") "LogDirectory")
				$Is_SiteSystem = $true
			}
		}

		"SRSRP"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$GetSMSLogs = $true ; $Is_SiteSystem = $true
			}
		}

		"WSUS"
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
			If ($Installed) {
				$GetSMSLogs = $true ; $Is_SiteSystem = $true
			}
		}

		Default
		{
			$Installed = Check-RegKeyExists ($Reg_SMS + "\" + $Role)
		}
	}

	# Set a Variable for each Role and it's Install Status
	Set-Variable -Name ("Is_" + $Role) -Value $Installed -Scope Global
	Add-Member -InputObject $global:CMRolesStatusFilePSObject -MemberType NoteProperty -Name ($RolesArray.Get_Item($Role)) -Value (Get-Variable ("Is_" + $Role) -ValueOnly)
	TraceOut ("Global Role Variable - Is_" + $Role + ": " + (Get-Variable ("Is_" + $Role) -ValueOnly))

	if ($Installed) {
		Add-Member -InputObject $global:CMInstalledRolesStatusReportPSObject -MemberType NoteProperty -Name ($RolesArray.Item($Role)) -Value (Get-Variable ("Is_" + $Role) -ValueOnly)
	}
}

# Mark IIS installed, if WSUS is installed on CAS, since SMS\IIS registry is not set on CAS
if ($Is_WSUS) {
	$Is_IIS = $true
}

# -----------------------------------------------------------------------------------------------------------------------------
# Parse CCMLogPaths, and get a unique path
# To handle collection of CCM Logs even if Client is not installed, but a Role is installed which stores logs in CCM directory
# -----------------------------------------------------------------------------------------------------------------------------
$CCMLogPath = $CCMLogPaths | Sort-Object | Get-Unique

# Error Handling if Get-RegValue failed to obtain a valid CCMLogPath and returned null instead
If (($CCMLogPath -eq "\") -or ($null -eq $CCMLogPath)) {
	$CCMLogPath = $null
	If ($GetCCMLogs) {
		TraceOut "ERROR: CCM Logs need to be collected but CCM Directory not found."
	}
	Else {
		TraceOut "WARNING: GetCCMLogs is set to False. CCM Log Path Not Required."
	}
}
Else {
	$CCMInstallDir = $CCMLogPath.Substring(0, $CCMLogPath.LastIndexOf("\Logs"))
	TraceOut "Global Variable - CCMInstallDir: $CCMInstallDir"
	TraceOut "Global Variable - CCMLogPath: $CCMLogPath"
}

If ($Is_Client) {
	Set-Variable -Name Is_Lantern -Scope Global -Value $true
	Set-Variable -Name LanternLogPath -Scope Global
	$LanternLogPath = Join-Path (Get-RegValue ($Reg_MS + "\PolicyPlatform\Client\Trace") "LogDir") (Get-RegValue ($Reg_MS + "\PolicyPlatform\Client\Trace") "LogFile")
	TraceOut "Global Variable - LanternLogPath: $LanternLogPath"
}

# -----------------------------
# Get SMSLogPath from Registry
# -----------------------------
If ($GetSMSLogs) {
	$SMSInstallDir = (Get-RegValue ($Reg_SMS + "\Identification") "Installation Directory")

	If ($null -ne $SMSInstallDir) {
		$SMSLogPath = $SMSInstallDir + "\Logs"
		TraceOut "Global Variable - SMSInstallDir: $SMSInstallDir"
		TraceOut "Global Variable - SMSLogPath: $SMSLogPath"
	}
	Else {
		$SMSLogPath = $null
		TraceOut "ERROR: SMS Logs need to be collected but SMS Install Directory not Found"
	}
}

# -------------------------------
# Get Site Server Info From Registry
# -------------------------------
If ($Is_SiteServer) {
	# Database Server and name
	$ConfigMgrDBServer = Get-RegValue ($Reg_SMS + "\SQL Server\Site System SQL Account") "Server"			# Stored as FQDN
	$ConfigMgrDBName = Get-RegValue ($Reg_SMS + "\SQL Server\Site System SQL Account") "Database Name"		# Stored as INSTANCE\DBNAME or just DBNAME if on Default instance

	# Get the database name without the Instance Name
	If ($ConfigMgrDBName.Contains("\")) {
		$ConfigMgrDBNameNoInstance = $ConfigMgrDBName.Substring($ConfigMgrDBName.IndexOf("\")+1)
	}
	Else {
		$ConfigMgrDBNameNoInstance = $ConfigMgrDBName
	}

	# Get Database connection.
	# If connection fails, DatabaseConnectionError will have the error. If connection is successful, DatabaseConnectionError will be $null.
	# Connection is closed in FinishExecution
	$global:DatabaseConnection = Get-DBConnection -DatabaseServer $ConfigMgrDBServer -DatabaseName $ConfigMgrDBName

	# Site Type
	$global:SiteType = Get-RegValue ($Reg_SMS + "\Setup") "Type"
	$global:SiteBuildNumber = Get-RegValue ($Reg_SMS + "\Setup") "Version"

	# Site Code and Provider Namespace
	$global:SMSProviderServer = Get-RegValue ($Reg_SMS + "\Setup") "Provider Location"
	$global:SMSSiteCode = Get-RegValue ($Reg_SMS + "\Identification") "Site Code"
	If (($null -ne $global:SMSSiteCode) -and ($null -ne $global:SMSProviderServer)) {
		$global:SMSProviderNamespace = "root\sms\site_$SMSSiteCode"
	}

	# Site Server FQDN
	$SiteServerFQDN = [System.Net.Dns]::GetHostByName(($ComputerName)).HostName

	# SQLBackup Log Location (SqlBkup.log)
	$RegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ConfigMgrDBServer)
	$Key = $RegKey.OpenSubKey("SOFTWARE\Microsoft\SMS\Tracing\SMS_SITE_SQL_BACKUP_$SiteServerFQDN")
	if ($Key -ne $null) {
		$SQLBackupLogPath = $Key.GetValue("TraceFileName")
		$SQLBackupLogPathUNC = $SQLBackupLogPath -replace ":","$"
		$SQLBackupLogPathUNC = "\\$ConfigMgrDBServer\$SQLBackupLogPathUNC"
		$SQLBackupLogPathUNC = Split-Path $SQLBackupLogPathUNC
	}

	TraceOut "Global Variable - SiteType: $SiteType"
	TraceOut "Global Variable - SQLBackupLogPathUNC: $SQLBackupLogPathUNC"
	TraceOut "Global Variable - ConfigMgrDBServer: $ConfigMgrDBServer"
	TraceOut "Global Variable - ConfigMgrDBName: $ConfigMgrDBName"
}

# --------------------------------------------------------------------------------------------------------------------------
# Set WSUS Install Directory, if WSUS is installed.
# Execute WSUSutil checkhealth. Running it now would ensure that it's finished by the time we collect Event Logs
# Fails to run remotely, because it runs under Anonymous. Using psexec to execute, to ensure that it runs remotely as well.
# --------------------------------------------------------------------------------------------------------------------------
If ($Is_WSUS) {
	$WSUSInstallDir = Get-RegValue ($Reg_WSUS + "\Server\Setup") "TargetDir"

	If ($null -ne $WSUSInstallDir) {
		TraceOut "Global Variable - WSUSInstallDir: $WSUSInstallDir"
		TraceOut "Running WSUSutil.exe checkhealth..."
		$CmdToRun = "psexec.exe /accepteula -s `"" + $WSUSInstallDir + "Tools\WSUSutil.exe`" checkhealth"
		RunCmd -commandToRun $CmdToRun -collectFiles $false
	}
	Else {
		TraceOut "ERROR: WSUS Role detected but WSUS Install Directory not found"
	}
}

# -----------------------------------------------------------------------
# Get DP Logs Directory, if DP is installed and remote from Site Server.
# -----------------------------------------------------------------------
If ($Is_DP) {
	If ($Is_SiteServer -eq $false) {
		$DPLogPath = (Get-CimInstance Win32_Share -filter "Name LIKE 'SMS_DP$'").path + "\sms\Logs"
		TraceOut "Global Variable - DPLogPath = $DPLogPath"
	}
}

# ----------------------
# Remove Temp Variables
# ----------------------
Remove-Variable -Name Role
Remove-Variable -Name Installed

TraceOut "Completed"


# SIG # Begin signature block
# MIInlQYJKoZIhvcNAQcCoIInhjCCJ4ICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC0q14USZymFauO
# Cz7bFCzBT6EhOcFr1gRHKV29itfWgqCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
# esGEb+srAAAAAANOMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMwMzE2MTg0MzI5WhcNMjQwMzE0MTg0MzI5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDdCKiNI6IBFWuvJUmf6WdOJqZmIwYs5G7AJD5UbcL6tsC+EBPDbr36pFGo1bsU
# p53nRyFYnncoMg8FK0d8jLlw0lgexDDr7gicf2zOBFWqfv/nSLwzJFNP5W03DF/1
# 1oZ12rSFqGlm+O46cRjTDFBpMRCZZGddZlRBjivby0eI1VgTD1TvAdfBYQe82fhm
# WQkYR/lWmAK+vW/1+bO7jHaxXTNCxLIBW07F8PBjUcwFxxyfbe2mHB4h1L4U0Ofa
# +HX/aREQ7SqYZz59sXM2ySOfvYyIjnqSO80NGBaz5DvzIG88J0+BNhOu2jl6Dfcq
# jYQs1H/PMSQIK6E7lXDXSpXzAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUnMc7Zn/ukKBsBiWkwdNfsN5pdwAw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMDUxNjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAD21v9pHoLdBSNlFAjmk
# mx4XxOZAPsVxxXbDyQv1+kGDe9XpgBnT1lXnx7JDpFMKBwAyIwdInmvhK9pGBa31
# TyeL3p7R2s0L8SABPPRJHAEk4NHpBXxHjm4TKjezAbSqqbgsy10Y7KApy+9UrKa2
# kGmsuASsk95PVm5vem7OmTs42vm0BJUU+JPQLg8Y/sdj3TtSfLYYZAaJwTAIgi7d
# hzn5hatLo7Dhz+4T+MrFd+6LUa2U3zr97QwzDthx+RP9/RZnur4inzSQsG5DCVIM
# pA1l2NWEA3KAca0tI2l6hQNYsaKL1kefdfHCrPxEry8onJjyGGv9YKoLv6AOO7Oh
# JEmbQlz/xksYG2N/JSOJ+QqYpGTEuYFYVWain7He6jgb41JbpOGKDdE/b+V2q/gX
# UgFe2gdwTpCDsvh8SMRoq1/BNXcr7iTAU38Vgr83iVtPYmFhZOVM0ULp/kKTVoir
# IpP2KCxT4OekOctt8grYnhJ16QMjmMv5o53hjNFXOxigkQWYzUO+6w50g0FAeFa8
# 5ugCCB6lXEk21FFB1FdIHpjSQf+LP/W2OV/HfhC3uTPgKbRtXo83TZYEudooyZ/A
# Vu08sibZ3MkGOJORLERNwKm2G7oqdOv4Qj8Z0JrGgMzj46NFKAxkLSpE5oHQYP1H
# tPx1lPfD7iNSbJsP6LiUHXH1MIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGXUwghlxAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAANOtTx6wYRv6ysAAAAAA04wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEs6Q9KAQxU8qUSw+EvxNKTq
# TEkKjGQMeIOioS64LGRKMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQAZ2Xh/k+oXCQIHPaJU/IAaw7+bzEf9/7smlaCku1+xsaQ1pGPTSQx+
# BwZVQCuKsyQL/34F9KC3nFxTT65FdRFt7hcNe1GHnxEvcNO+b4pnKb39J6vL659I
# nKNZ6i4puK+8JXpdihFeLCka3/WoNNdwSvaXm+glLGoDr0PdqHEY/U9OxUHGocuS
# RayXCqylipCpm/oLQKetlEA6lwf+WPCqIjD8dzuVagHpWWYP/44aHvTcRatLtNfE
# Ueyu1QP+PadqdmF80Gj8nELaCBfp1QrS6t4iT54QjqWfgnQGMFR6GjswLVtjXYsH
# +eswtgCUmASUoHpvlbCtFIeHK79OtkNnoYIW/TCCFvkGCisGAQQBgjcDAwExghbp
# MIIW5QYJKoZIhvcNAQcCoIIW1jCCFtICAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIF9B7ronvQjGeJqpD1zXQdREfohb+R+gCZmIf3yFtBwzAgZkiywF
# Em4YEzIwMjMwNzEwMDc0MDI4LjI4MlowBIACAfSggdCkgc0wgcoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjNFN0Et
# RTM1OS1BMjVEMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRVDCCBwwwggT0oAMCAQICEzMAAAHJ+tWOJSB0Al4AAQAAAckwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjIxMTA0MTkw
# MTM4WhcNMjQwMjAyMTkwMTM4WjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046M0U3QS1FMzU5LUEyNUQxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDWcuLljm/Pwr5ajGGTuoZb+8LGLl65MzTVOIRsU4by
# DtIUHRUyNiCjpOJHOA5D4I3nc4E4qXIwdbNEvjG9pLTdmUiB60ggtiIBKiCwS2WP
# MSVEc7t8MYMVZx3P6UI1iYmjO1sbc8yufFuVQcdSSvgLsQEdvZjTsZ3kYkGA/z7k
# Bk2xOWwcZzMezjmaY/utSBwyf/9zxD8ZhKp1Pg5cQunneH30SfIXjNyx3ZkWPF2P
# WU/xAbBllLgXzYkEZ7akKtJqTIWNPHMUpQ7BxB6vAFH9hpCXLua0Ktrg81zIRCb6
# f8sNx79VWJBrw4zacFkcrDoLIyoTMUknLkeLPPxnrGuqosq2Ly+IlRDQW2qRNdJH
# f//Dw8ArIGW8hhMUX8vLcmHdxtV46BKa5s5XC/ycx6FxBvYC3FxT+V3IRSrLz+2E
# QchY1pvMdfHk70Phu1Lqgl2AuYfGtMG0axxVCrHTPn99QiQsTu1vB+irzhwX9REs
# TLDernspXZTiA6FzfnpdgRVB0lejpUVYFANhvNqdDbnNjbVQKSPzbULIP3SCqs7e
# tA+VxCjp6vBbYMXZ+yaABtWrNCzPpGSZp/Pit7XuSbup7T0+7AfDl7fHlkgYShWV
# 82cm/r7znW7ApfoClkXE/N5Cjtb/kG1pOaRkSHBjkB0I+A+/RpogRCfaoXsy8XAJ
# ywIDAQABo4IBNjCCATIwHQYDVR0OBBYEFAVvnWdGwjyhvng6FMV5UXtELjLLMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQAD
# ggIBADaoupxm30eKQgdyPsCWceGOi7FKM54FpMT4QrxpdxUub1wDwPb9ljY5Sli8
# 52G4MRX2ESVWbOimIm6T/EFiHp1YlNGGZLuFWOsa2rNIVbQt9+xHKyPGSm6rKEeI
# EPExcwZnoZ3NR+pU/Zl3Y74n8FhAmCz00djP8IzhdpE/5PZUzckTWZI7Wotr6Z8H
# jbtCIuP8kLtNRiCHhFj6gswVW5Alm9diX+MhMV9SmkmgBqQGvRVzavWQ/kOIlo29
# lYn9y5hqJZDiT3GnDrAbPeqrvEBaeUbOxrDAWGO3CrkQf+zfssJ96HK4LDxlEn1b
# e2BIV6kBUzuxQT4+vdS76I+8FXhOxMM0UvQJUg9f7Vc4nphEZgnaQcamgZz/myAD
# YgpByX3tkNgkiqLGDAo1+3I3vQ7QBNulNWGxs3TUVWWLQf6+BwaHLOTqOkDLAc8N
# JD/GgR4ZTj7o8VNcxE798zMZxRx/RkepkybRSGgfy062TXyToHvkoldO1jdkzulN
# +6tK/ZCu/nPMIGLLKy04/D8gkj6T2ilOBq2sLf0vr38rDK0PTHu3SOZNe2Utloa+
# hKWN3LKvpANFWSqwJotRJKwCJZ5q/mqDrhTeYuZ56SjQT1MnnLO03+NyLOUfHRey
# A643qy5vcI9XsAAwyIqil1BiqI9e70jG+pdPsIT9IwLalw3JMIIHcTCCBVmgAwIB
# AgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1
# WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O
# 1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
# hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t
# 1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxq
# D89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmP
# frVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSW
# rAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv
# 231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zb
# r17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYcten
# IPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQc
# xWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17a
# j54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
# n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJ
# oEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01p
# Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYB
# BQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9v
# Q2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3h
# LB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x
# 5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
# y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1A
# oL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbC
# HcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB
# 9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNt
# yo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3
# rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcV
# v7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A24
# 5oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lw
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAsswggI0AgEBMIH4oYHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjozRTdBLUUzNTktQTI1RDElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAfemLy/4eAZuNVCzgbfp1HFYG3Q6g
# gYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
# AQUFAAIFAOhV9nIwIhgPMjAyMzA3MTAxMTE2MDJaGA8yMDIzMDcxMTExMTYwMlow
# dDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6FX2cgIBADAHAgEAAgIJ2TAHAgEAAgIR
# wjAKAgUA6FdH8gIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAow
# CAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBADW2KBnQ8k7B
# jCV138yRnoKcyohMQxDzhVpcc1a4EsmtpD8fnrsmMFpACTSVLYUcfJe24ezhjAU0
# XeZxLmhMO1DQzyDSXDyruSSO5KzaSb81yS5qrGN5ICID0Z9kkLZJfMWuKUrvPWXK
# foUQUYQmKHKEKS+ojxHD1JsheCIBfg6RMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHJ+tWOJSB0Al4AAQAAAckwDQYJYIZI
# AWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
# 9w0BCQQxIgQg1hmyvdmnj/66/Td4mfEG8r3CpL0Yd8D4zRt/W9yYgdMwgfoGCyqG
# SIb3DQEJEAIvMYHqMIHnMIHkMIG9BCCBdc5/Ut1RSxAneCnYf2ANIyGJAP/NfeFd
# fOHZOXb9gTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAAByfrVjiUgdAJeAAEAAAHJMCIEICYzR8bdwMKq+2g9of+1vG+U7Ejm165BiXnw
# uRFwnXB9MA0GCSqGSIb3DQEBCwUABIICAL1x6zre4RH/EoVMgoiPvHCYrB8HgYJi
# utJEhdCBAMAtyO49LNV6cY9mbIn1G7egG6CM/8YLPUUvSot1FVNbEFDzxfwe5TWP
# pG7hf9VPNlIuSY0SHM5MtQGaC0fzf0MbffdufkRT/rAaUl+4LBP2rzbUv6TzZQbI
# U5288jVP3D1nvUgJOa/S534ESa90iFvXIh2niPS33Cj/uYpr7NUplqLA1ZD5DddR
# U8G4dKZvk4X3cvF6BVP0meZFRmK674JjwzecPdOcgLiAaMVvZaBErBVQDrbJvqiK
# 2PxyRSBmD5GRQv6VWsyvjBA7ZaqJYm2+zXfnk8M3EdvIoepeDyJ4d5wtjSgnkYqw
# Wfq5SBF/n50L8xa78RP4s+v84/0kwrpXzODYqwwtPj3MbQ9bqkx80CoJ6QnCzdkq
# kIANc63dfsPifN+p9ZHrUzSyGt8q2NgpBuXLWRpOL3xdpS2Ot6ZxgKtSuGP2GDY4
# T/UWJ2d9G9N5hP87enawhB424jbxFv1yo3SU2Acf+RcjgwCtUpQma8sE8nF+Y5dw
# VQ8hv5Hs1ZwKbHxPFgxT9iaD0tOwYRZp0p7md72JgE5uoKEVwvuwNO+Pv6DfgSLP
# uggstyqmOesVp5wspigPCurdzrmVNP0XlKeLzOWSmaHLyxBEm0TfKG/nXDntW1L9
# 9QHaDOl6wiWh
# SIG # End signature block
