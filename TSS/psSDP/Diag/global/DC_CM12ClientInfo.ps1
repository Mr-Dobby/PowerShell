# *********************************************************************************************************************
# Version 1.0
# Date: 02-29-2012
# Author: Vinay Pamnani - vinpa@microsoft.com
# Description:
# 		Collects Configuration Manager Client Information
#		1. Gets CCMExec service Status, Start time, Install Directory, Assigned Site, MP, Client Version and GUID.
# 		2. Gets Software Distribution Execution History.
#		3. Gets Cache Size, Location and Elements.
#		4. Gets Inventory Timestamps
#		5. Gets Update Installation Status
#		6. Gets State Message Data
#		7. Gets File Versions from Client Install Directory
#		8. Summarizes all data in a PSObject, then dumps to a text file for better readability.
# *********************************************************************************************************************

trap [Exception]
{
	WriteTo-ErrorDebugReport -ErrorRecord $_
	continue
}

If (!$Is_Client) {
	TraceOut "ConfigMgr Client not detected. This script gathers data only from a Client. Exiting."
	exit 0
}

function Get-WmiOutput {
	Param(
		[Parameter(Mandatory=$true)]
	    [string]$Namespace,
		[Parameter(Mandatory=$false)]
	    [string]$ClassName,
		[Parameter(Mandatory=$false)]
	    [string]$Query,
		[Parameter(Mandatory=$false)]
	    [string]$DisplayName,
		[Parameter(Mandatory=$false)]
		[switch]$FormatList,
		[Parameter(Mandatory=$false)]
		[switch]$FormatTable
	)

	if ($DisplayName) {
		$DisplayText = $DisplayName
	}
	else {
		$DisplayText = $ClassName
	}

	$results =  "`r`n=================================`r`n"
	$results += " $DisplayText `r`n"
	$results += "=================================`r`n`r`n"

	if ($ClassName) {
		$Temp = Get-WmiData -Namespace $Namespace -ClassName $ClassName
	}

	if ($Query) {
		$Temp = Get-WmiData -Namespace $Namespace -Query $Query
	}

	if ($Temp) {
		if ($FormatList) {
			$results += ($Temp | Format-List | Out-String -Width 500).Trim()
		}

		if ($FormatTable) {
			$results += ($Temp | Format-Table -AutoSize | Out-String -Width 500).Trim()
		}

		$results += "`r`n"
	}
	else {
		$results += "    No Instances.`r`n"
	}

	return $results
}

function Get-WmiData{
	Param(
		[Parameter(Mandatory=$true)]
	    [string]$Namespace,
	    [Parameter(Mandatory=$false)]
	    [string]$ClassName,
		[Parameter(Mandatory=$false)]
	    [string]$Query
	)

	if ($ClassName) {
		$Temp = Get-CimInstance -Namespace $Namespace -Class $ClassName -ErrorVariable WMIError -ErrorAction SilentlyContinue
	}

	if ($Query) {
		$Temp = Get-CimInstance -Namespace $Namespace -Query $Query -ErrorVariable WMIError -ErrorAction SilentlyContinue
	}

	if ($WMIError.Count -ne 0) {
		if ($WMIError[0].Exception.Message -eq "") {
			$results = $WMIError[0].Exception.ToString()
		}
		else {
			$results = $WMIError[0].Exception.Message
		}
		$WMIError.Clear()
		return $results
	}

	if (($Temp | Measure-Object).Count -gt 0) {
		$results = $Temp | Select-Object * -ExcludeProperty __GENUS, __CLASS, __SUPERCLASS, __DYNASTY, __RELPATH, __PROPERTY_COUNT, __DERIVATION, __SERVER, __NAMESPACE, __PATH, PSComputerName, Scope, Path, Options, ClassPath, Properties, SystemProperties, Qualifiers, Site, Container
	}
	else {
		$results = $null
	}

	return $results
}

TraceOut "Started"

Import-LocalizedData -BindingVariable ScriptStrings
$sectiondescription = "Configuration Manager Client Information"

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ClientInfo -Status $ScriptStrings.ID_SCCM_CM07ClientInfo_ClientInfo

TraceOut "    Getting Client Information"

# ----------------------
# Current Time:
# ----------------------
AddTo-CMClientSummary -Name "Current Time" -Value $CurrentTime

# -------------
# Computer Name
# -------------
AddTo-CMClientSummary -Name "Client Name" -Value $ComputerName

# ------------------
# Assigned Site Code
# ------------------
$Temp = Get-RegValue ($Reg_SMS + "\Mobile Client") "AssignedSiteCode"
If ($null -ne $Temp) {
	AddTo-CMClientSummary -Name "Assigned Site Code" -Value $Temp}
else {
	AddTo-CMClientSummary -Name "Assigned Site Code" -Value "Error obtaining value from Registry"}

# ------------------------
# Current Management Point
# ------------------------
$Temp = Get-CimInstance -Namespace root\CCM -Class SMS_Authority -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	AddTo-CMClientSummary -Name "Current MP" -Value $Temp.CurrentManagementPoint }
else {
	AddTo-CMClientSummary -Name "Current MP" -Value "Error obtaining value from SMS_Authority WMI Class" }

# --------------
# Client Version
# --------------
$Temp = Get-CimInstance -Namespace root\CCM -Class SMS_Client -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	AddTo-CMClientSummary -Name "Client Version" -Value $Temp.ClientVersion }
else {
	AddTo-CMClientSummary -Name "Client Version" -Value "Error obtaining value from SMS_Client WMI Class" }

# ----------------------------------------------------------
# Installation Directory - defined in utils_ConfigMgr07.ps1
# ----------------------------------------------------------
If ($null -ne $CCMInstallDir) {
	AddTo-CMClientSummary -Name "Installation Directory" -Value $CCMInstallDir }
else {
	AddTo-CMClientSummary -Name "Installation Directory" -Value "Error obtaining value" }

# ------------
# Client GUID
# ------------
$Temp = Get-CimInstance -Namespace root\CCM -Class CCM_Client -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	AddTo-CMClientSummary -Name "Client ID" -Value $Temp.ClientId
	AddTo-CMClientSummary -Name "Previous Client ID (if any)" -Value $Temp.PreviousClientId
	AddTo-CMClientSummary -Name "Client ID Change Date" -Value $Temp.ClientIdChangeDate }
else {
	AddTo-CMClientSummary -Name "Client ID Information" -Value "Error Obtaining value from CCM_Client WMI Class" }

# -----------------------
# CCMExec Service Status
# -----------------------
$Temp = Get-Service | Where-Object {$_.Name -eq 'CCMExec'} | Select-Object Status
If ($null -ne $Temp) {
	if ($Temp.Status -eq 'Running') {
		$Temp2 = Get-Process | Where-Object {$_.ProcessName -eq 'CCMExec'} | Select-Object StartTime
		AddTo-CMClientSummary -Name "CCMExec Status" -Value "Running. StartTime = $($Temp2.StartTime)"
	}
	else {
		AddTo-CMClientSummary -Name "CCMExec Status" -Value $Temp.Status
	}
}
Else {
	AddTo-CMClientSummary -Name "CCMExec Service Status" -Value "ERROR: Service Not found"
}

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ClientInfo -Status $ScriptStrings.ID_SCCM_CM07ClientInfo_History

TraceOut "    Getting Software Distribution and Application Execution History"

# -----------------------------------------------------
# Software Distribution Execution History from Registry
# -----------------------------------------------------
$Temp = ($Reg_SMS -replace "HKLM\\", "HKLM:\") + "\Mobile Client\Software Distribution\Execution History"
If (Check-RegKeyExists $Temp) {
	$TempFileName = ($ComputerName + "_CMClient_ExecutionHistory.txt")
	$ExecHistory = Join-Path $Pwd.Path $TempFileName
	Get-ChildItem $Temp -Recurse `
	| ForEach-Object {Get-ItemProperty $_.PSPath} `
	| Select-Object @{name="Path";exp={$_.PSPath.Substring($_.PSPath.LastIndexOf("History\") + 8)}}, _ProgramID, _State, _RunStartTime, SuccessOrFailureCode, SuccessOrFailureReason `
	| Out-File $ExecHistory -Append -Width 500
	AddTo-CMClientSummary -Name "ExecMgr History" -Value ("Review $TempFileName") -NoToSummaryReport
	CollectFiles -filesToCollect $ExecHistory -fileDescription "ExecMgr History"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription
}
else {
	AddTo-CMClientSummary -Name "ExecMgr History" -Value "Execution History not found" -NoToSummaryReport
}

# -----------------------------------------------------
# Application Enforce Status from WMI
# -----------------------------------------------------
$Temp = Get-CimInstance -Namespace root\CCM\CIModels -Class CCM_AppEnforceStatus -ErrorVariable WMIError -ErrorAction SilentlyContinue
If ($WMIError.Count -eq 0)
{
	If ($null -ne $Temp) {
		$TempFileName = ($ComputerName + "_CMClient_AppHistory.txt")
		$AppHist = Join-Path $Pwd.Path $TempFileName
		$Temp | Select-Object AppDeliveryTypeId, ExecutionStatus, ExitCode, Revision, ReconnectData `
		| Out-File $AppHist -Append -Width 250
		AddTo-CMClientSummary -Name "App Execution History" -Value ("Review $TempFileName") -NoToSummaryReport
		CollectFiles -filesToCollect $AppHist -fileDescription "Application History"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	}
	else {
		AddTo-CMClientSummary -Name "App Execution History" -Value ("Error obtaining data or no data in WMI") -NoToSummaryReport
	}
}
Else {
	AddTo-CMClientSummary -Name "App Execution History" -Value ("ERROR: " + $WMIError[0].Exception.Message) -NoToSummaryReport
	$WMIError.Clear()
}

# -----------------
# Cache Information
# -----------------
$Temp = Get-CimInstance -Namespace root\ccm\softmgmtagent -Class CacheConfig -ErrorVariable WMIError -ErrorAction SilentlyContinue
If ($WMIError.Count -eq 0)
{
	If ($null -ne $Temp) {
		$TempFileName = ($ComputerName + "_CMClient_CacheInfo.txt")
		$CacheInfo = Join-Path $Pwd.Path $TempFileName
		"Cache Config:" | Out-File $CacheInfo
		"==================" | Out-File $CacheInfo -Append
		$Temp | Select-Object Location, Size, NextAvailableId | Format-List * | Out-File $CacheInfo -Append -Width 500
		"Cache Elements:" | Out-File $CacheInfo -Append
		"===============" | Out-File $CacheInfo -Append
		$Temp = Get-CimInstance -Namespace root\ccm\softmgmtagent -Class CacheInfoEx -ErrorAction SilentlyContinue
		$Temp | Select-Object Location, ContentId, CacheID, ContentVer, ContentSize, LastReferenced, PeerCaching, ContentType, ReferenceCount, PersistInCache `
			| Sort-Object -Property Location | Format-Table -AutoSize | Out-File $CacheInfo -Append -Width 500
		AddTo-CMClientSummary -Name "Cache Information" -Value ("Review $TempFileName") -NoToSummaryReport
		CollectFiles -filesToCollect $CacheInfo -fileDescription "Cache Information"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	}
	Else {
		AddTo-CMClientSummary -Name "Cache Information" -Value "No data found in WMI." -NoToSummaryReport
	}
}
Else {
	AddTo-CMClientSummary -Name "Cache Information" -Value ("ERROR: " + $WMIError[0].Exception.Message) -NoToSummaryReport
	$WMIError.Clear()
}

# -----------------------------------------------
# Inventory Timestamps from InventoryActionStatus
# -----------------------------------------------
$Temp = Get-CimInstance -Namespace root\ccm\invagt -Class InventoryActionStatus -ErrorVariable WMIError -ErrorAction SilentlyContinue
If ($WMIError.Count -eq 0)
{
	If ($null -ne $Temp) {
		$TempFileName = ($ComputerName + "_CMClient_InventoryVersions.txt")
		$InvVersion = Join-Path $Pwd.Path $TempFileName
		$Temp | Select-Object InventoryActionID, @{name="LastCycleStartedDate(LocalTime)";expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}}, LastMajorReportversion, LastMinorReportVersion, @{name="LastReportDate(LocalTime)";expression={$_.ConvertToDateTime($_.LastReportDate)}} `
		| Out-File $InvVersion -Append
		AddTo-CMClientSummary -Name "Inventory Versions" -Value ("Review $TempFileName") -NoToSummaryReport
		CollectFiles -filesToCollect $InvVersion -fileDescription "Inventory Versions"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	}
	else {
		AddTo-CMClientSummary -Name "Inventory Versions" -Value "No data found in WMI." -NoToSummaryReport
	}
}
Else {
	AddTo-CMClientSummary -Name "Inventory Versions" -Value ("ERROR: " + $WMIError[0].Exception.Message) -NoToSummaryReport
	$WMIError.Clear()
}

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ClientInfo -Status $ScriptStrings.ID_SCCM_CM07ClientInfo_Updates

TraceOut "    Getting Software Update Status and State Messages"

# -----------------------------------
# Update Status from CCM_UpdateStatus
# -----------------------------------
$TempFileName = ($ComputerName + "_CMClient_CCM-UpdateStatus.txt")
$UpdStatus = Join-Path $Pwd.Path $TempFileName
"=================================" | Out-File $UpdStatus
" CCM_UpdateStatus" | Out-File $UpdStatus -Append
"=================================" | Out-File $UpdStatus -Append
$Temp = Get-CimInstance -Namespace root\CCM\SoftwareUpdates\UpdatesStore -Class CCM_UpdateStatus -ErrorVariable WMIError -ErrorAction SilentlyContinue
If ($WMIError.Count -eq 0)
{
	If ($null -ne $Temp) {
		$Temp | Select-Object UniqueID, Article, Bulletin, RevisionNumber, Status, @{name="ScanTime(LocalTime)";expression={$_.ConvertToDateTime($_.ScanTime)}}, ExcludeForStateReporting, Title, SourceUniqueId `
		  | Sort-Object -Property Article, UniqueID -Descending | Format-Table -AutoSize | Out-File $UpdStatus -Append -Width 500
		AddTo-CMClientSummary -Name "CCM Update Status" -Value ("Review $TempFileName") -NoToSummaryReport
		CollectFiles -filesToCollect $UpdStatus -fileDescription "CCM Update Status"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	}
	else {
		AddTo-CMClientSummary -Name "CCM Update Status" -Value ("No data in WMI") -NoToSummaryReport
	}
}
Else {
	AddTo-CMClientSummary -Name "CCM Update Status" -Value ("ERROR: " + $WMIError[0].Exception.Message) -NoToSummaryReport
	$WMIError.Clear()
}

# --------------------------------
# State Messages from CCM_StateMsg
# --------------------------------
$TempFileName = ($ComputerName + "_CMClient_CCM-StateMsg.txt")
$StateMsg = Join-Path $Pwd.Path $TempFileName
"=================================" | Out-File $StateMsg
" CCM_StateMsg " | Out-File $StateMsg -Append
"=================================" | Out-File $StateMsg -Append
$Temp = Get-CimInstance -Namespace root\CCM\StateMsg -Class CCM_StateMsg -ErrorVariable WMIError -ErrorAction SilentlyContinue
If ($WMIError.Count -eq 0)
{
	If ($null -ne $Temp) {
		$Temp | Select-Object TopicID, TopicType, TopicIDType, StateID, Priority, MessageSent, @{name="MessageTime(LocalTime)";expression={$_.ConvertToDateTime($_.MessageTime)}} `
		 | Sort-Object -Property TopicType, TopicID | Format-Table -AutoSize | Out-File $StateMsg -Append -Width 500
		AddTo-CMClientSummary -Name "CCM State Messages" -Value ("Review $TempFileName") -NoToSummaryReport
		CollectFiles -filesToCollect $StateMsg -fileDescription "State Messages"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	}
	else {
		AddTo-CMClientSummary -Name "CCM State Messages" -Value ("No data in WMI") -NoToSummaryReport
	}
}
Else {
	AddTo-CMClientSummary -Name "CCM State Messages" -Value ("ERROR: " + $WMIError[0].Exception.Message) -NoToSummaryReport
	$WMIError.Clear()
}

TraceOut "    Getting WMI Data from Client"
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ClientInfo -Status $ScriptStrings.ID_SCCM_CM07ClientInfo_WMIData

# --------------------------------
# Deployments
# --------------------------------
$TempFileName = ($ComputerName + "_CMClient_CCM-MachineDeployments.TXT")
$OutputFile = join-path $pwd.path $TempFileName
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -DisplayName "Update Deployments" -Query "SELECT AssignmentID, AssignmentAction, AssignmentName, StartTime, EnforcementDeadline, SuppressReboot, NotifyUser, OverrideServiceWindows, RebootOutsideOfServiceWindows, UseGMTTimes, WoLEnabled FROM CCM_UpdateCIAssignment" `
  -FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -DisplayName "Application Deployments (Machine only)" -Query "SELECT AssignmentID, AssignmentAction, AssignmentName, StartTime, EnforcementDeadline, SuppressReboot, NotifyUser, OverrideServiceWindows, RebootOutsideOfServiceWindows, UseGMTTimes, WoLEnabled FROM CCM_ApplicationCIAssignment" `
  -FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -DisplayName "DCM Deployments (Machine only)" -Query "SELECT AssignmentID, AssignmentAction, AssignmentName, StartTime, EnforcementDeadline, SuppressReboot, NotifyUser, OverrideServiceWindows, RebootOutsideOfServiceWindows, UseGMTTimes, WoLEnabled FROM CCM_DCMCIAssignment" `
  -FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -DisplayName "Package Deployments (Machine only)" -Query "SELECT PKG_PackageID, ADV_AdvertisementID, PRG_ProgramName, PKG_Name, PRG_CommandLine, ADV_MandatoryAssignments, ADV_ActiveTime, ADV_ActiveTimeIsGMT, ADV_RCF_InstallFromLocalDPOptions, ADV_RCF_InstallFromRemoteDPOptions, ADV_RepeatRunBehavior, PRG_MaxDuration, PRG_PRF_RunWithAdminRights, PRG_PRF_AfterRunning FROM CCM_SoftwareDistribution" `
  -FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -DisplayName "Task Sequence Deployments" -Query "SELECT PKG_PackageID, ADV_AdvertisementID, PRG_ProgramName, PKG_Name, TS_BootImageID, TS_Type, ADV_MandatoryAssignments, ADV_ActiveTime, ADV_ActiveTimeIsGMT, ADV_RCF_InstallFromLocalDPOptions, ADV_RCF_InstallFromRemoteDPOptions, ADV_RepeatRunBehavior, PRG_MaxDuration FROM CCM_TaskSequence" `
  -FormatTable | Sort-Object -Property AssignmentID | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_ServiceWindow -FormatTable | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_RebootSettings -FormatTable | Out-File $OutputFile -Append

AddTo-CMClientSummary -Name "Machine Deployments" -Value ("Review $TempFileName") -NoToSummaryReport
CollectFiles -filesToCollect $OutputFile -fileDescription "Machine Deployments" -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# --------------------------------
# Client Agent Configs
# --------------------------------
$TempFileName = ($ComputerName + "_CMClient_CCM-ClientAgentConfig.TXT")
$OutputFile = join-path $pwd.path $TempFileName

Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_ClientAgentConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_SoftwareUpdatesClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_ApplicationManagementClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_SoftwareDistributionClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_Logging_GlobalConfiguration -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_PolicyAgent_Configuration -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_Service_ResourceProfileConfiguration -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_ConfigurationManagementClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_HardwareInventoryClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_SoftwareInventoryClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_SuperPeerClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_EndpointProtectionClientConfig -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\Policy\Machine\ActualConfig -ClassName CCM_AntiMalwarePolicyClientConfig -FormatList | Out-File $OutputFile -Append

AddTo-CMClientSummary -Name "Client Agent Configs" -Value ("Review $TempFileName") -NoToSummaryReport
CollectFiles -filesToCollect $OutputFile -fileDescription "Client Agent Configs" -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# --------------------------------
# Various WMI classes
# --------------------------------

$TempFileName = ($ComputerName + "_CMClient_CCM-ClientMPInfo.TXT")
$OutputFile = join-path $pwd.path $TempFileName

Get-WmiOutput -Namespace root\CCM -ClassName SMS_Authority -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName CCM_Authority -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName SMS_LocalMP -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName SMS_LookupMP -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName SMS_MPProxyInformation -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName CCM_ClientSiteMode -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName SMS_Client -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName ClientInfo -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName SMS_PendingReRegistrationOnSiteReAssignment -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM -ClassName SMS_PendingSiteAssignment -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\LocationServices -ClassName SMS_ActiveMPCandidate -FormatList | Out-File $OutputFile -Append
Get-WmiOutput -Namespace root\CCM\LocationServices -DisplayName "SMS_MPInformation" -Query "SELECT MP, MPLastRequestTime, MPLastUpdateTime, SiteCode, Reserved2 FROM SMS_MPInformation" -FormatList | Out-File $OutputFile -Append

AddTo-CMClientSummary -Name "MP Information" -Value ("Review $TempFileName") -NoToSummaryReport
CollectFiles -filesToCollect $OutputFile -fileDescription "MP Information" -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ClientInfo -Status $ScriptStrings.ID_SCCM_CM07ClientInfo_FileVer
TraceOut "    Getting File Versions"

# ---------------------
# Binary Versions List
# ---------------------
$TempFileName = ($ComputerName + "_CMClient_FileVersions.TXT")
$OutputFile = join-path $pwd.path $TempFileName
Get-ChildItem ($CCMInstallDir) -recurse -include *.dll,*.exe -ErrorVariable DirError -ErrorAction SilentlyContinue | `
	ForEach-Object {[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_)} | `
	Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize | `
	Out-File $OutputFile -Width 1000
	CollectFiles -filesToCollect $OutputFile -fileDescription "Client File Versions" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	AddTo-CMClientSummary -Name "File Versions" -Value ("Review $TempFileName") -NoToSummaryReport

#TraceOut "     Directory Errors = ${$DirError.Count}"
If ($DirError.Count -gt 0) {		#If there were errors report them
	$dirErrorStr = $DirError[0].Exception.Message
	for ($i = 1; $i -lt $DirError.Count; $i++) #($e in $DirError)
	{
		$dirErrorStr += "`n" + $DirError[$i].Exception.Message
	}
	#AddTo-CMClientSummary -Name "Directory Errors getting File Versions" -Value ("ERROR: " + $e.Exception.Message) -NoToSummaryReport
	AddTo-CMClientSummary -Name "Directory Errors getting File Versions" -Value $dirErrorStr -NoToSummaryReport
	$DirError.Clear()
}

# ---------------------------
# Collect Client Information
# ---------------------------
# Moved to DC_FinishExecution

Traceout "Completed"
# SIG # Begin signature block
# MIInxAYJKoZIhvcNAQcCoIIntTCCJ7ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCyxc/W9cUXPo+I
# oRdAdTd/Rd9URyxLTGBdMcAoRgdB4qCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGaQwghmgAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAANOtTx6wYRv6ysAAAAAA04wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBQVUlrhkqnlz6aDdQlsWzPe
# KEAh0xCpk6v7ksuL+8zsMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCsb8M9BqZf7n1H7OjVI2q0J90zre6t+Oqug81VvASC9wDfeI/AtGW4
# PdqvErW6oj0xAmqFr636chV1s7heMy6WrjJHxV+5MUquQNeNJ7fSWz0GJuZ/EBR/
# aKqWuL7cHCVkzgRVYdwoknbLKaKldcOLbNWpK4Dkx3KeJ9f0kpLhtkwY8ef6fTvE
# sEAU2YUCLxLdNPu/WfRMN8skmoTzHIV4Y77AijXRybvarytJd2CAmsUM2yCk7Skj
# nq9bxhsjGUNdBPW5UaV7DqN5FeRYUxGB79FEurxqJwUOIGm49UAXTkz/oF7cKb87
# smII6ccORWo9YyVB1NphPQsT7oSDwKpzoYIXLDCCFygGCisGAQQBgjcDAwExghcY
# MIIXFAYJKoZIhvcNAQcCoIIXBTCCFwECAQMxDzANBglghkgBZQMEAgEFADCCAVkG
# CyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIE0/CM2IomafWkBY0fSPlgPLEufr5UOEn+dZ1SoPeed1AgZk38yj
# dV8YEzIwMjMwOTA3MTczNTA4LjEwOFowBIACAfSggdikgdUwgdIxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJ
# cmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBF
# U046RDA4Mi00QkZELUVFQkExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFNlcnZpY2WgghF7MIIHJzCCBQ+gAwIBAgITMwAAAbofPxn3wXW9fAABAAABujAN
# BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0y
# MjA5MjAyMDIyMTlaFw0yMzEyMTQyMDIyMTlaMIHSMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBP
# cGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkQwODIt
# NEJGRC1FRUJBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAiE4VgzOSNYAT1RWdcX2F
# Ea/TEFHFz4jke7eHFUVfIre7fzG6wRvSkuTCOAa0OxostuuUzGpfe0Vv/cGAQ8QL
# cvTBfvqAPzMe37CIFXmarkFainb2pGuAwkooI9ylCdKOz0H/hcwUW+ul0+JxkO/j
# cUuDP18eoyrQskPDkkAcYNLfRMJj04Xjc/h3jhn2UTsJpVLakkwXcvjncxcHnJgr
# 8oNuKWERE/WPGfbKX60YJGC4gCwwbSh46FdrDy5IY6FLoAJIdv55uLTTfwwUfKhM
# 2Ep/5Jijg6lJjfE/j6zAEFMoOhg/XAf4J/EbqH1/KYElA9Blqp+XSuKIMuOYO6dC
# 0fUYPrgCKvmT0l3CGrnAuZJZePIVUv4gN86l2LEnp/mj4yETofi3fXD6mvKAeZ3Z
# QdDrntQbHoU27PAL5KkAeZXvoxlhpzi4CFOBo/js/Z55LWhyS/KGX3Jr70nM98yS
# 6DfF6/MUANaItEyvTroQxXurclJECycJL0ZDTwLgUo9tKHw48zfcueDR9/EA2ccA
# Bf8MTtwdzHuX2NpXcByaSPuiqKvgSHa7ljHCJpMTftdoy6ZfYRLc8nk0Fperth0s
# nDJIP5T2mT+2Xh1DW38R6ju4NOWI7JCQPwjvjGlUHRPfX/rsod+QGQVW/LrDJ7bV
# X70gLy5IP75GAPdHC03aQT8CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSKYubxAx4l
# rbmP0xZ5psjYdK9k5TAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAX8jxTqFtmG8N
# yf3qdnq2RtISNc+8pnrCuhpdyCy0SGmBp4TCV4u49ccvMRa24m5jPh6yGaFeoWvj
# 2VsBxflI3n9wSw/TF0VrJvtTk/3gll3ceMW+lZE2g0GEXdIMzQDfywjYf6GOEH9V
# 9fVdxmJ6LVE48DIIdwGAcvJCsS7qadvceFsh2vyHRNrtYXKUaEtIVbrCbMq6w/po
# 6WacZJpzk0x+VrqVG9Ngd3byttsKB9KbVGFOChmP5bwNMq2IQzC5scneYg8qajzG
# 0khZc+derpcqCV2svlzKcsxf/RZfrk65ZsdXkZMQt19a8ZXcNpmsc9RD9Q/fUp6p
# vbGNUJvfQtXCBuMi9hLvs3V0BGQ3wX/2knWA7gi9lYzDIyUooUaiM7V/XBuNJZwD
# /nu2xz63ZuWsxaBI0eDMOvTWNs9K6lGPLce31lmzjE3TZ6Jfd4bb3s2u0LqXhz+D
# OfbR6qipbH+4dbGZOAHQXmiwG5Mc57vsPIQDS6ECsaWAo/3WOCGC385UegfrmDRC
# oK2Bn7fqacISDog6EWgWsJzR8kUZWZvX7XuAR74dEwzuMGTg7Ton4iigWsjd7c8m
# M+tBqej8zITeH7MC4FYYwNFxSU0oINTt0ada8fddbAusIIhzP7cbBFQywuwN09bY
# 5W/u/V4QmIxIhnY/4zsvbRDxrOdTg4AwggdxMIIFWaADAgECAhMzAAAAFcXna54C
# m0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZp
# Y2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMy
# MjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
# yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY
# 6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9
# cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN
# 7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDua
# Rr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74
# kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2
# K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5
# TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZk
# i1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9Q
# BXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3Pmri
# Lq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
# BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJl
# pxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9y
# eS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUA
# YgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU
# 1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2Ny
# bC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIw
# MTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
# Ni0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/yp
# b+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
# ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM
# 9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECW
# OKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4
# FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3Uw
# xTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPX
# fx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVX
# VAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGC
# onsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU
# 5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEG
# ahC0HVUzWLOhcGbyoYIC1zCCAkACAQEwggEAoYHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OkQwODItNEJGRC1FRUJBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQB2o0d7XXeAInztpkgZrlAFSojC8qCBgzCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUA
# AgUA6KP+2jAiGA8yMDIzMDkwNzE1NDg0MloYDzIwMjMwOTA4MTU0ODQyWjB3MD0G
# CisGAQQBhFkKBAExLzAtMAoCBQDoo/7aAgEAMAoCAQACAgZNAgH/MAcCAQACAhG3
# MAoCBQDopVBaAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAI
# AgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEABWsHIqWZy4wA
# bqgaWgkXMesAnvgVSMcDvZXS4v4qv4V9EtbxKUpO2WGfcm3wGimr6q+S3e/oKHko
# MKWntXRX4YtZapMNez0xnNa4cKr1mOnKMkindi4DJS16R++yrgSl0L/2ZbqGijLQ
# 5clmukdGv+Sg4QaM4cnwmLMnhoPq03AxggQNMIIECQIBATCBkzB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAbofPxn3wXW9fAABAAABujANBglghkgB
# ZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3
# DQEJBDEiBCAm2bWSrVA/pLfuou5EFdntKVUzMALm5l5LfW8zgSf2UjCB+gYLKoZI
# hvcNAQkQAi8xgeowgecwgeQwgb0EIClVvTwzbnD61gZayaUa2nWDLWc9ypZ+qAwX
# eeVZhXMFMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
# AAG6Hz8Z98F1vXwAAQAAAbowIgQgR4fgOq5PYEgY2vpxh6Z9AtAehi420Jr+bfPM
# Em0ib/kwDQYJKoZIhvcNAQELBQAEggIAYs/y+/gabJcrSbQOXS5e4F49WOiRokY9
# wPvb0STk8b2SCCumEYDXKRTr3rbCRUKIzDvkYW8RaQQ2LHuqGKluz9sPQf/rsP8H
# 4zEK0RFgI1VM/LaUU6hHYEIR+NMcgx9M5E/q/NP94nXfafwFRBmkwWzthV2Yz5FD
# QGkmPuHbxqRcBASCk4ceodyY+jS7NZGxk0Piwt70PI9g51ZTujDjSy3hGa7+hVJ5
# rv/UI7i5I6+gx6E44BfOsq+ETA+kuA/G7eL6WbBG5J9aICxBofDUSs/R0QwbPvFz
# zqlibsZAF4YWp0DoLGKq8mzQgdxal8BI14OoH8gfC+S9ASO29QAEqZ0gg6X/0HjS
# HuHN+Q6kG80ooH3Lancx57katV1hhQ0yE1f9jrMP4XN4DIttMZIstIIQYSMRRhM/
# bj5sBBV8bGcYy+2naqidUzmSXhnfrykA34kANEg9x0IpTmZzh9WOZpnT8vqXEori
# UQ+cvn4fvThowOvyBtWORXe/mOhouvhN6aMj9Lnv3RfmoHNuchZaAu1VXWDc63iL
# evwVCaWku492R0a5z3Z6AtiwFg+A9SqeTu7dLcutYOw5Ti4u8AriFCUJ+DoZEq/I
# 4ePAGoyPZG2mWm/x/VDWyv/lJbCpBarq7WPYKVv68wDOQgXW2H6GkmD2nSvjJlfZ
# 4DChX0xopQ8=
# SIG # End signature block
