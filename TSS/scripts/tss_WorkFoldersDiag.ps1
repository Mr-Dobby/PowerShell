<# Script name: tss_WorkFoldersDiag.ps1

#  Copyright (c) Microsoft Corporation.  All rights reserved.
#  
# THIS SAMPLE CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# WHETHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
# IF THIS CODE AND INFORMATION IS MODIFIED, THE ENTIRE RISK OF USE OR RESULTS IN
# CONNECTION WITH THE USE OF THIS CODE AND INFORMATION REMAINS WITH THE USER. 
#
# Author:
#     Anu Raghavan (araghav) - August, 2013
# Version: 8.1
#>

#region ::::: Script Input PARAMETERS :::::
[CmdletBinding()]param(
  [Parameter(Mandatory=$true, Position=0)] [String] $DataPath,
  [Parameter(Mandatory=$false, Position=1)] [Switch] $AdvancedMode = $false,
  [Parameter(Mandatory=$false, Position=2)] [Int] $TraceLevel = 255,
  [Parameter(Mandatory=$false, Position=3)] [Switch] $Cleanup = $false,
  [Parameter(Mandatory=$false, Position=4)] [Switch] $RunTrace = $false,
  [Parameter(Mandatory)]
  [ValidateSet("Start","Stop")]
  [string]$Stage
)
$ScriptVer="22.02.04"	#Date: 2022-02-04
$OutputDirectory = $DataPath
$LogSeparator = '################################################################################################################'
#endregion ::::: Script Input PARAMETERS :::::

function Get-EventsTxt($EventLog, $OutFile)
# SYNOPSIS: extract Eventlog content in TXT format
{	$Events = Get-WinEvent $EventLog -MaxEvents 300 -ErrorAction SilentlyContinue
    if($null -eq $Events)
    {   # Error occurred - do nothing
	    Write-Host ' $EventLog : No event log entries found.'
    }
    else
    {   'Number of event log entries collected: ' + $Events.Count | Out-File $OutFile
	    foreach($Event in $Events)
	    {   $LogSeparator | Out-File $OutFile -append
		    $Event | Out-File $OutFile -append
		    'Full message:' | Out-File $OutFile -append
		    $Event.Message | Out-File $OutFile -append
	    }
    }
}

function Get-Registry($Path, $OutFile)
# SYNOPSIS: get the content of Registry keys
{
    if ((Test-Path $Path) -eq $true)
    {
        Get-Item $Path | Out-File $OutFile -append
	    Get-ChildItem $Path -Recurse | Out-File $OutFile -append
    }
}

function Get-WorkFoldersInfo
# SYNOPSIS: collect WorkFolder client and server info
{
	param (
	  [Parameter(Mandatory=$true, Position=0)] [String] $OutputDirectory,
	  [Parameter(Mandatory=$false, Position=1)] [Switch] $AdvancedMode = $false,
	  [Parameter(Mandatory=$false, Position=2)] [Int] $TraceLevel = 255,
	  [Parameter(Mandatory=$false, Position=3)] [Switch] $Cleanup = $True,
	  [Parameter(Mandatory=$false, Position=4)] [Switch] $RunTrace = $false,
	  [Parameter(Mandatory)]
        [ValidateSet("Start","Stop")]
        [string]$Stage
	)

	$OldErrorActionPreference = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"

	# Validate input
	$Done = $false
	while ($Done -eq $false)
	{
		if ($null -eq $OutputDirectory)	{	$Done = $false	}
		elseif ((Test-Path $OutputDirectory) -eq $false) {	$Done = $false	}
		else {	$Done = $true	}

		if ($Done -eq $false)
		{	Write-Error "Path selected is invalid."
			$OutputDirectory = Read-Host "Specify another path for OutputDirectory [Note that all contents already present in this directory will be erased.]"
		}
	}
	while (($TraceLevel -lt 1) -or ($TraceLevel -gt 255))
	{	$TraceLevel = Read-Host "Invalid trace level specified. Please specify a value between 1 and 255"}

	# Create Temp directory structure to accumulate output + Collect generic info
	$Script:TempOutputPath = $OutputDirectory + '\Temp'
	$Script:GeneralDirectory = $Script:TempOutputPath + '\General'
	$Script:IsServer = Test-Path ($env:Systemroot + '\System32\SyncShareSvc.dll')
	$Script:IsClient = Test-Path ($env:Systemroot + '\System32\WorkFoldersSvc.dll')
	
if ($Stage -eq "Start") 
{ 
	Write-Host "v$ScriptVer Starting collection of debug information for Work Folders on this machine ..." -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host "$(Get-Date -Format 'HH:mm:ss') Setting up WorkFoldersDiag environment ..."
	if ($AdvancedMode) {  	Write-Host "... running in AdvancedMode" }

	New-Item $Script:TempOutputPath -type directory | Out-Null
	New-Item $Script:GeneralDirectory -type directory | Out-Null
	$GeneralInfoFile = $Script:GeneralDirectory + '\' + $env:COMPUTERNAME + '_MachineInfo.txt'
	$LocalVolumesFile = $Script:GeneralDirectory + '\' + $env:COMPUTERNAME + '_LocalVolumes.txt'
	$ClusterVolumesFile = $Script:GeneralDirectory + '\' + $env:COMPUTERNAME + '_ClusterVolumes.txt'
	'VersionString: ' + [System.Environment]::OSVersion.VersionString | Out-File $GeneralInfoFile
	'Version: ' + [System.Environment]::OSVersion.Version | Out-File $GeneralInfoFile -append
	'ServicePack: ' + [System.Environment]::OSVersion.ServicePack | Out-File $GeneralInfoFile -append
	'Platform: ' + [System.Environment]::OSVersion.Platform | Out-File $GeneralInfoFile -append

	$OS = Get-CimInstance -class win32_OperatingSystem
	if ($OS.ProductType -gt 1)
	{	'OS SKU Type: Server' | Out-File $GeneralInfoFile -append
		try { $Cluster = Get-Cluster -EA Ignore}
		catch { 
			#Write-host "...not running on cluster environment"
			}
		$IsCluster = $null -ne $Cluster
		if ($IsCluster) {  'This machine is part of a cluster' | Out-File $GeneralInfoFile -append }
		else {    'This machine is a stand alone machine, it is not part of a cluster' | Out-File $GeneralInfoFile -append }
	}
	else
	{	'OS SKU Type: Client' | Out-File $GeneralInfoFile -append}


	if ($Script:IsServer) {
		'Work Folders server component is installed on this machine.' | Out-File $GeneralInfoFile -append 
		'List of versions of binaries for the Work Folders server component:' | Out-File $GeneralInfoFile -append
		$ServerBinaries = @(
		($env:Systemroot + '\System32\SyncShareSvc.dll'),
		($env:Systemroot + '\System32\SyncShareSrv.dll'),
		($env:Systemroot + '\System32\SyncShareTTLib.dll'),
		($env:Systemroot + '\System32\SyncShareTTSvc.exe')
		)
		Foreach($Binary in $ServerBinaries)
		{ 	[System.Diagnostics.FileVersionInfo]::GetVersionInfo($Binary) | Format-List | Out-File $GeneralInfoFile -append }
		Copy-Item ($env:Systemroot + '\System32\SyncShareSvc.config') $Script:GeneralDirectory
		$WFmode = "Server"
	}
	if ($Script:IsClient) {
		'Work Folders client component is installed on this machine.' | Out-File $GeneralInfoFile -append
		'List of versions of binaries for the Work Folders client component:' | Out-File $GeneralInfoFile -append
		$ClientBinaries = @(
		($env:Systemroot + '\System32\WorkFoldersShell.dll'),
		($env:Systemroot + '\System32\WorkFoldersGPExt.dll'),
		($env:Systemroot + '\System32\WorkFoldersControl.dll'),
		($env:Systemroot + '\System32\WorkFoldersSvc.dll'),
		($env:Systemroot + '\System32\WorkFolders.exe')
		)
		Foreach($Binary in $ClientBinaries)
		{ 	[System.Diagnostics.FileVersionInfo]::GetVersionInfo($Binary) | Format-List | Out-File $GeneralInfoFile -append }
		$WFmode = "Client"
	}
	
	$WFmodeDirectory = $null
	$WFmodeDirectory = $Script:TempOutputPath + '\' + $WFmode
	New-Item $WFmodeDirectory -type directory | Out-Null
		
	"List of local volumes:" | Out-File $LocalVolumesFile -append
	Get-WmiObject Win32_Volume | Out-File $LocalVolumesFile -append

	if ($IsCluster)
	{
		"List of cluster volumes:" | Out-File $ClusterVolumesFile -append
		Get-WmiObject MSCluster_Resource -Namespace root/mscluster | where-object{$_.Type -eq 'Physical Disk'} |
			ForEach-Object{ Get-WmiObject -Namespace root/mscluster -Query "Associators of {$_} Where ResultClass=MSCluster_Disk" } |
			ForEach-Object{ Get-WmiObject -Namespace root/mscluster -Query "Associators of {$_} Where ResultClass=MSCluster_DiskPartition" } |
			Out-File $ClusterVolumesFile -append
	}

	if ($RunTrace) {  	Write-Host "... Start Work Folders tracing" 
		### Start Work Folders tracing
		#Write-Host "$(Get-Date -Format 'HH:mm:ss') Start Work Folders $WFmode tracing ..."
		$TracesDirectory = $Script:TempOutputPath + '\Traces'
		New-Item $TracesDirectory -type directory | Out-Null
		$TracingCommand = 'logman start WorkFoldersTrace -o "$TracesDirectory\WorkFoldersTrace.etl" --max -ets -p "{111157cb-ee69-427f-8b4e-ef0feaeaeef2}" 0xffffffff ' + $TraceLevel
		Invoke-Expression $TracingCommand | Out-Null # start traces
		$TracingCommand = 'logman start WorkFoldersTraceEFS -o "$TracesDirectory\WorkFoldersTraceEFS.etl" --max -ets -p "{C755EF4D-DE1C-4E7D-A10D-B8D1E26F5035}" 0xffffffff ' + $TraceLevel
		Invoke-Expression $TracingCommand | Out-Null # start EFS traces
		$TracingCommand = 'logman start WorkFoldersTraceESE -o "$TracesDirectory\WorkFoldersTraceESE.etl" --max -ets -p "{1284E99B-FF7A-405A-A60F-A46EC9FED1A7}" 0xffffffff ' + $TraceLevel
		Invoke-Expression $TracingCommand | Out-Null # start ESE traces
		Write-Host "$(Get-Date -Format 'HH:mm:ss') Work Folders $WFmode Tracing started."
		
		### Start Interactive Repro
		Write-Host "`n === Please reproduce the WorkFolder problem then press the 's' key to stop tracing. ===`n" -ForegroundColor Green
		do {
			$UserDone = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		} until ($UserDone.Character -ieq 's')
		###
		Write-Host "$(Get-Date -Format 'HH:mm:ss') Collecting WorkFolder traces with TraceLevel $TraceLevel ..."

		Start-Sleep(5) # Allow time to make sure traces get written

		Invoke-Expression 'logman stop WorkFoldersTrace -ets' | Out-Null # stop traces
		Invoke-Expression 'logman stop WorkFoldersTraceEFS -ets' | Out-Null # stop EFS traces
		Invoke-Expression 'logman stop WorkFoldersTraceESE -ets' | Out-Null # stop ESE traces

		Write-Host "$(Get-Date -Format 'HH:mm:ss') WorkFolder Tracing stopped."
	}
}
if ($Stage -eq "Stop") 
{	
	###
	if ($Script:IsClient) {$WFmode = "Client"}
	if ($Script:IsServer)
	{
		$ServerSetting = Get-SyncServerSetting
		$Shares = Get-SyncShare
		$WFmode = "Server"
	}
	
	$WFmodeDirectory = $Script:TempOutputPath + '\' + $WFmode
	
	if ($AdvancedMode)
	{ #_# Stopping Service WorkFolderssvc
		if ($Script:IsClient) { Write-Host "$(Get-Date -Format 'HH:mm:ss') Stopping Service WorkFolderssvc."
						Stop-Service WorkFolderssvc }
		if ($Script:IsServer) { Write-Host "$(Get-Date -Format 'HH:mm:ss') Stopping Services SyncShareSvc, SyncShareTTSvc."
						Stop-Service SyncShareSvc
						Stop-Service SyncShareTTSvc }
	}

	Write-Host "$(Get-Date -Format 'HH:mm:ss') Saving WorkFolders $WFmode configuration information ..."
	$ConfigDirectory = $WFmodeDirectory + '\Config'
	New-Item $ConfigDirectory -type directory | Out-Null
	$RegConfigFile = $ConfigDirectory + '\' + $env:COMPUTERNAME + '_RegistryConfig.txt'
	$MetadataDirectory = $WFmodeDirectory + '\' + $WFmode + 'Metadata'
	if ($AdvancedMode) { New-Item $MetadataDirectory -type directory | Out-Null   }

	if ($Script:IsServer)
	{
		Get-Registry 'hklm:\SYSTEM\CurrentControlSet\Services\SyncShareSvc' $RegConfigFile
		Get-Registry 'hklm:\SYSTEM\CurrentControlSet\Services\SyncShareTTSvc' $RegConfigFile
		$SyncShareSrvHive = 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\SyncShareSrv'
		if ($IsCluster) { $SyncShareSrvHive = 'hklm:\Cluster\SyncShareSrv' }
		Get-Registry $SyncShareSrvHive $RegConfigFile

		$ConfigFile = $ConfigDirectory + '\' + $env:COMPUTERNAME + '_CmdletConfig.txt'
		$LogSeparator | Out-File $ConfigFile -append
		'Config for sync server:' | Out-File $ConfigFile -append
		$LogSeparator | Out-File $ConfigFile -append
		$ServerSetting | Out-File $ConfigFile -append
		$LogSeparator | Out-File $ConfigFile -append
		'End config for sync server:' | Out-File $ConfigFile -append
		$LogSeparator | Out-File $ConfigFile -append

		foreach ($Share in $Shares)
		{
			$LogSeparator | Out-File $ConfigFile -append
			'Config for sync share ' + $Share.Name | Out-File $ConfigFile -append
			$LogSeparator | Out-File $ConfigFile -append
			$Share | Out-File $ConfigFile -append

			$acl = Get-Acl $Share.Path -EA SilentlyContinue
			'ACLs on ' + $Share.Path + ':' | Out-File $ConfigFile -append
			$acl | Out-File $ConfigFile -append
			$acl.Access | Out-File $ConfigFile -append

			$acl = Get-Acl $Share.StagingFolder -EA SilentlyContinue
			'ACLs on ' + $Share.StagingFolder + ':' | Out-File $ConfigFile -append
			$acl | Out-File $ConfigFile -append
			$acl.Access | Out-File $ConfigFile -append

			$MetadataFolder = $Share.StagingFolder + '\Metadata'
			$acl = Get-Acl $MetadataFolder -EA SilentlyContinue
			'ACLs on ' + $MetadataFolder + ':' | Out-File $ConfigFile -append
			$acl | Out-File $ConfigFile -append
			$acl.Access | Out-File $ConfigFile -append

			if ($AdvancedMode) { Get-ChildItem $MetadataFolder | ForEach-Object{ Copy-Item $_.FullName $MetadataDirectory } }
			
			foreach ($user in $Share.User)
			{
				'Full list of users on this sync share:' | Out-File $ConfigFile -append
				$user | Out-File $ConfigFile -append
			}

			$LogSeparator | Out-File $ConfigFile -append
			'End config for sync share ' + $Share.Name | Out-File $ConfigFile -append
			$LogSeparator | Out-File $ConfigFile -append
		}
	}

	if ($Script:IsClient)
	{
		Get-Registry 'hklm:SOFTWARE\Microsoft\Windows\CurrentVersion\WorkFolders' $RegConfigFile
		Get-Registry 'hkcu:SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\WorkFolders' $RegConfigFile
		Get-Registry 'hkcu:SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings' $RegConfigFile
		if ($AdvancedMode) { Get-ChildItem ($env:LOCALAPPDATA + '\Microsoft\Windows\WorkFolders\Metadata') | ForEach-Object{ Copy-Item $_.FullName $MetadataDirectory } }
	}

	### event log entries
	Write-Host "$(Get-Date -Format 'HH:mm:ss') Collecting WorkFolders $WFmode event log entries ..."
	$EventLogDirectory = $WFmodeDirectory + '\' + $WFmode + 'EventLogs'
	New-Item $EventLogDirectory -type directory | Out-Null

	if ($Script:IsServer)
	{
		Get-EventsTxt Microsoft-Windows-SyncShare/Operational ($EventLogDirectory + '\' + $env:COMPUTERNAME + '_SyncShare_Operational.txt')
		#_# ToDo: Get-EventsTxt Microsoft-Windows-SyncShare/Debug ($EventLogDirectory + '\' + $env:COMPUTERNAME + '_SyncShare_Debug.txt')
		Get-EventsTxt Microsoft-Windows-SyncShare/Reporting ($EventLogDirectory + '\' + $env:COMPUTERNAME + '_SyncShare_Reporting.txt')
	}

	if ($Script:IsClient)
	{
		Get-EventsTxt Microsoft-Windows-WorkFolders/Operational ($EventLogDirectory + '\' + $env:COMPUTERNAME + '_WorkFolders_Operational.txt')
		#_# ToDo: Get-EventsTxt Microsoft-Windows-WorkFolders/Debug ($EventLogDirectory + '\' + $env:COMPUTERNAME + '_WorkFolders_Debug.txt')
		#_# ToDo: Get-EventsTxt Microsoft-Windows-WorkFolders/Analytic ($EventLogDirectory + '\' + $env:COMPUTERNAME + '_WorkFolders_Analytic.txt')
		Get-EventsTxt Microsoft-Windows-WorkFolders/WHC ($EventLogDirectory + '\' + $env:COMPUTERNAME + '_WorkFolders_ManagementAgent.txt')
	}
	Write-Host "$(Get-Date -Format 'HH:mm:ss') Collection of WorkFolders $WFmode event log entries done."

	if ($AdvancedMode)
	{ #_# Starting Service WorkFolderssvc
		if ($Script:IsClient) {  Write-Host "$(Get-Date -Format 'HH:mm:ss') Restarting Service WorkFolderssvc"
						Start-Service WorkFolderssvc }
		if ($Script:IsServer) {  Write-Host "$(Get-Date -Format 'HH:mm:ss') Restarting Services SyncShareSvc, SyncShareTTSvc"
						Start-Service SyncShareSvc
						Start-Service SyncShareTTSvc }
	}
	### Compress data
	Write-Host "$(Get-Date -Format 'HH:mm:ss') Finalizing/Zipping output ..."
	# In the output directory, remove the system and hidden attributes from files
	attrib ($Script:TempOutputPath + '\*') -H -S /s
	# Zip the output directory
	Add-Type -AssemblyName System.IO.Compression
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$OutputZipFile = $OutputDirectory + '\' + $env:COMPUTERNAME + '_WorkFoldersDiagOutput.zip'
	[System.IO.Compression.ZipFile]::CreateFromDirectory($Script:TempOutputPath, $OutputZipFile)
	Write-Host "All information have been saved in $OutputZipFile." -ForegroundColor Green 

	###
	Write-Host "Cleaning up environment ..."
	if ($Cleanup) { Write-Host "$(Get-Date -Format 'HH:mm:ss') Cleaning output directory $Script:TempOutputPath ..."
					Remove-Item $Script:TempOutputPath -Recurse -Force }

	$ErrorActionPreference = $OldErrorActionPreference
	Write-Host "$(Get-Date -Format 'HH:mm:ss') Done - tss_WorkFoldersDiag" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host " "
}
} # end of function Get-WorkFoldersInfo

#region ::::: MAIN ::::
Get-WorkFoldersInfo -OutputDirectory $dataPath $AdvancedMode -TraceLevel $TraceLevel -Stage $Stage
#endregion ::::: MAIN :::::


# SIG # Begin signature block
# MIInvgYJKoZIhvcNAQcCoIInrzCCJ6sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBO3X5nRSPI+pqT
# fVFpR+EvNb4WJQN5JztzJfBjdAQZ6KCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGZ4wghmaAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEvtH5WImO30R+uO3z/vnhj0
# HbkyOaig9CYZOVJtqelQMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEATwghFoFdUo4MvKkazQSS6Ou+PKd15jAR5EkRzEvqjAge5a4GbYFgtEEW
# tQSB8wLZfkTgYRCziqlQBSC0fVm36u99G69qvMDyTmQ7HvRnCzz3+xDLcAg8r2D8
# DZ++EOR63NxRNr7LCJ4fY0oKZo7vussHTH7nMHb4xVbKzf/nl3PQrzxMDW7SlNBa
# fACqjTpd48h7OOjJonghF97KUzQOLh/pmPC+cz2Xi3husu1xI7Vm6IMOiw8XwQDU
# qo/Y34KpCDtWIic+b5YXFtfRPabALuRrH3lPm8Mv29DJaU5V4Oy4boZnRm3rPyHy
# JRB+6pV6K6phaz0BampN4xLTMjzAdaGCFygwghckBgorBgEEAYI3AwMBMYIXFDCC
# FxAGCSqGSIb3DQEHAqCCFwEwghb9AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFYBgsq
# hkiG9w0BCRABBKCCAUcEggFDMIIBPwIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCDdTyg1oaHQcL73aQ81G3LXQtYPIpRTDYXL05WbZTSRHwIGZlUmjP19
# GBIyMDI0MDYxMjE1MDAzOC4xMVowBIACAfSggdikgdUwgdIxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVs
# YW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046
# MDg0Mi00QkU2LUMyOUExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2WgghF4MIIHJzCCBQ+gAwIBAgITMwAAAdqO1claANERsQABAAAB2jANBgkq
# hkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEw
# MTIxOTA2NTlaFw0yNTAxMTAxOTA2NTlaMIHSMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVy
# YXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjA4NDItNEJF
# Ni1DMjlBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAk5AGCHa1UVHWPyNADg0N/xtx
# WtdI3TzQI0o9JCjtLnuwKc9TQUoXjvDYvqoe3CbgScKUXZyu5cWn+Xs+kxCDbkTt
# fzEOa/GvwEETqIBIA8J+tN5u68CxlZwliHLumuAK4F/s6J1emCxbXLynpWzuwPZq
# 6n/S695jF5eUq2w+MwKmUeSTRtr4eAuGjQnrwp2OLcMzYrn3AfL3Gu2xgr5f16ts
# MZnaaZffvrlpLlDv+6APExWDPKPzTImfpQueScP2LiRRDFWGpXV1z8MXpQF67N+6
# SQx53u2vNQRkxHKVruqG/BR5CWDMJCGlmPP7OxCCleU9zO8Z3SKqvuUALB9UaiDm
# mUjN0TG+3VMDwmZ5/zX1pMrAfUhUQjBgsDq69LyRF0DpHG8xxv/+6U2Mi4Zx7LKQ
# wBcTKdWssb1W8rit+sKwYvePfQuaJ26D6jCtwKNBqBiasaTWEHKReKWj1gHxDLLl
# DUqEa4frlXfMXLxrSTBsoFGzxVHge2g9jD3PUN1wl9kE7Z2HNffIAyKkIabpKa+a
# 9q9GxeHLzTmOICkPI36zT9vuizbPyJFYYmToz265Pbj3eAVX/0ksaDlgkkIlcj7L
# GQ785edkmy4a3T7NYt0dLhchcEbXug+7kqwV9FMdESWhHZ0jobBprEjIPJIdg628
# jJ2Vru7iV+d8KNj+opMCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBShfI3JUT1mE5WL
# MRRXCE2Avw9fRTAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Ny
# bC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYI
# KwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
# MDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAuYNV1O24jSMAS3jU
# 7Y4zwJTbftMYzKGsavsXMoIQVpfG2iqT8g5tCuKrVxodWHa/K5DbifPdN04G/uty
# z+qc+M7GdcUvJk95pYuw24BFWZRWLJVheNdgHkPDNpZmBJxjwYovvIaPJauHvxYl
# SCHusTX7lUPmHT/quz10FGoDMj1+FnPuymyO3y+fHnRYTFsFJIfut9psd6d2l6pt
# OZb9F9xpP4YUixP6DZ6PvBEoir9CGeygXyakU08dXWr9Yr+sX8KGi+SEkwO+Wq0R
# NaL3saiU5IpqZkL1tiBw8p/Pbx53blYnLXRW1D0/n4L/Z058NrPVGZ45vbspt6CF
# rRJ89yuJN85FW+o8NJref03t2FNjv7j0jx6+hp32F1nwJ8g49+3C3fFNfZGExkkJ
# WgWVpsdy99vzitoUzpzPkRiT7HVpUSJe2ArpHTGfXCMxcd/QBaVKOpGTO9KdErMW
# xnASXvhVqGUpWEj4KL1FP37oZzTFbMnvNAhQUTcmKLHn7sovwCsd8Fj1QUvPiydu
# gntCKncgANuRThkvSJDyPwjGtrtpJh9OhR5+Zy3d0zr19/gR6HYqH02wqKKmHnz0
# Cn/FLWMRKWt+Mv+D9luhpLl31rZ8Dn3ya5sO8sPnHk8/fvvTS+b9j48iGanZ9O+5
# Layd15kGbJOpxQ0dE2YKT6eNXecwggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZ
# AAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVa
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1
# V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9
# alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmv
# Haus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928
# jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3t
# pK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEe
# HT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26o
# ElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4C
# vEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ug
# poMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXps
# xREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0C
# AwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYE
# FCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtT
# NRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5o
# dG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
# AEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZW
# y4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5t
# aWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAt
# MDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0y
# My5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pc
# FLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpT
# Td2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0j
# VOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3
# +SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmR
# sqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSw
# ethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5b
# RAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmx
# aQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsX
# HRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0
# W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0
# HVUzWLOhcGbyoYIC1DCCAj0CAQEwggEAoYHYpIHVMIHSMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFu
# ZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjA4
# NDItNEJFNi1DMjlBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
# aWNloiMKAQEwBwYFKw4DAhoDFQBCoh8hiWMdRs2hjT/COFdGf+xIDaCBgzCBgKR+
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA
# 6hQS2zAiGA8yMDI0MDYxMjIwMjgxMVoYDzIwMjQwNjEzMjAyODExWjB0MDoGCisG
# AQQBhFkKBAExLDAqMAoCBQDqFBLbAgEAMAcCAQACAgXUMAcCAQACAhKKMAoCBQDq
# FWRbAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMH
# oSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAnTP24TQ0NLSTa4FvGhop
# Y+FBp4ASoo1TMWKwQUKhJ/4XvbppFMPPU3PiH2orK9ZJHb3n+dfvFFdT7DlFgg4+
# 47Nq4i22F0eVOe076suBH33Za47f8jxLMcadjwnkiCxi9wRSjHuaLfO5NOWdPhLr
# jjJNImirdkY2XSlmyttcJD0xggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
# dGFtcCBQQ0EgMjAxMAITMwAAAdqO1claANERsQABAAAB2jANBglghkgBZQMEAgEF
# AKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEi
# BCBnyE8CyIaoHE/567+6JtwtmsaQFK1zg9Gig/6HrDrSzzCB+gYLKoZIhvcNAQkQ
# Ai8xgeowgecwgeQwgb0EICKlo2liwO+epN73kOPULT3TbQjmWOJutb+d0gI7GD3G
# MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHajtXJ
# WgDREbEAAQAAAdowIgQgKvO69Zk2UfJdVrapRR/sBl8+9muLwh2EN7N+6vixuE0w
# DQYJKoZIhvcNAQELBQAEggIACyCp+xvL/GFM7/Dadf8Kwtqjxybwg+Lc6b1xSFW8
# Ao8LKsr+KR3/n2JN2CNwcelug4YpEFgt2rNRijUU5VnWxKv9GTnMxqRQfx/FuyA+
# jhzWQv0UelWe2E9Hc3CQRgXpuhr9OkVgL0Q1+Zv5Fz3eBTlSfq+OJ6AkC97wYHGv
# m1Zr5K8/aIzdZue9HeINSLdijGn8rM2qfF7d0TvheDJ9tDe+lI3zBwieb2ZnCb7x
# NBAwWeLoGbrM+rrhtBmSSIvx956R5ecA4Au59Y2N+mHvGwYji9RgA0bPOHpGUpTe
# GZGrhIUsYUnovniBzEir2/VkBYYXCeb6q3GbeX0XgdW+CwyYwx38B1bQUVqMUnhR
# GYU//M2vbjk9I6SDjs5fGony7fKruhdPk5AWnGsMHEcPSAeToSOrHEeLAdZt44f4
# fSbkfZ4HuS1ZVvpXlqouU75XQtiVTRVDiuv5rIW6JbN4tY6Z0Xx6aUh/XNMuOWpm
# HGzu5X8AU6FxJ7+Yzc4w/GJWAhk79tnrLbcfYFU/I4MTCRH9JbHuuHKYDbjNMn/s
# NF1hp/deKmTa+3HI+oUDgQxEMYCaK7b7ux9Tq3B2s3lNYtBCojTYk7ZsiD4cn2sG
# u3FJgOYau/y8hXo/eltckiiCeQdHUyqeFEDM1k201TBpziCNuV99cOvQ7X6/txd4
# Ir8=
# SIG # End signature block
