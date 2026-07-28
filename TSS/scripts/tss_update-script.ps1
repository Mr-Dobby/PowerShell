# Name: tss_update-script.ps1 for TSS (former TSSv2)

<# 
.SYNOPSIS
	Script to [auto-]update TSS to latest version or download latest zip from CesdiagTools/GitHub.

.DESCRIPTION
	Script will search on "https://microsoft.githubenterprise.com/css-windows/WindowsCSSToolsDevRep/releases/tag" for latest TSS version
	If local version does not match the remote CesdiagTools/GitHub version, it will download and replace TSS with latest version
	Script gets the current version from $global:TssVerDate or by running ".\TSS -version" and compares to version 'https://cesdiagtools.blob.core.windows.net/windows/TSS.ver'.

.PARAMETER tss_action
	choose action from allowed values: "Download" or "Update" or "Version"
		Download	= download latest CesdiagTools/GitHub version
		Update		= update current local version
		Version		= decide based on local version, try AutoUpdate if local version is lower than CesdiagTools/GitHub version
	Ex: -tss_action "Download"
	
.PARAMETER tss_file
	Specify filename from allowed values: "TSS.zip" , "TSS_TTD.zip" , "TSS_diff.zip" or "TSSLite.zip"
	Ex: -tss_file "TSS.zip"
	
.PARAMETER TSS_path
	Specify the local path where TSS.ps1 is located.
	Ex: -TSS_path "C:\TSS"

.PARAMETER UpdMode
	Specify the mode: 
		Online  = complete package (TSS.zip) from aka.ms/getTSS
		Full    = complete package (TSS.zip) from CesdiagTools/GitHub
		Quick   = differential package only (TSS_diff.zip): replace only TSS.ps1, TSS_[POD].psm1 and config\tss_config.cfg files; will not update \BIN* folders
		Force   = run a Full update, regardless of current installed version

.PARAMETER tss_arch
	Specify the System Architecture.
	Allowed values:
		x64 - For 64-bit systems
		x86 - For 32-bit systems
	Ex: -tss_arch "x64"

.EXAMPLE
	.\tss_update-script.ps1 -tss_action "Update" -TSS_path "C:\TSS" -tss_file "TSS.zip"
	Example 1: Update TSS in folder C:\TSS
	
.LINK
	https://microsoft.githubenterprise.com/css-windows/WindowsCSSToolsDevRep/releases/tag
	Public Download: TSS: https://cesdiagtools.blob.core.windows.net/windows/TSS.zip -or- https://aka.ms/getTSS
#>


param(
	[ValidateSet("download","update","version")]
	[Parameter(Mandatory=$False,Position=0,HelpMessage='Choose from: download|update|version')]
	[string]$tss_action 	= "download"
	,
	[string]$TSS_path 		= (Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent),
	[ValidateSet("Online","Full","Quick","Force","Lite")]
	[string]$UpdMode 		= "Online"
	,
	$verOnline
	,
	[ValidateSet("TSS.zip","TSS_diff.zip","TSSLite.zip","TSS_ttd.zip")]
	[string]$tss_file 		= "TSS.zip"
	,
	[ValidateSet("x64","x86")]
	[string]$tss_arch 		= "x64",
	[string]$CentralStore	= "",								# updating from Central Enterprise Store
	[switch]$AutoUpd		= $False,							# 
	[switch]$UseExitCode 	= $true								# This will cause the script to bail out after the error is logged if an error occurs.
)

#region  ::::: [Variables] -----------------------------------------------------------#
$updScriptVersion	= "2023.10.06"
$UpdLogfile 		= $TSS_path + "\_tss_Update-Log.txt"
$script:ChkFailed	= $FALSE
$invocation 		= (Get-Variable MyInvocation).Value
$ScriptGrandParentPath 	= $MyInvocation.MyCommand.Path | Split-Path -Parent | Split-Path -Parent
$scriptName 		= $invocation.MyCommand.Name
if ($UpdMode -match 'Online') {
	$TssReleaseServer = "cesdiagtools.blob.core.windows.net"
	$tss_release_url  = "https://cesdiagtools.blob.core.windows.net/windows"
}else{
	$TssReleaseServer = "api.Github.com"
	$tss_release_url  = "https://api.github.com/repos/walter-1/TSSv2/releases"
}
$NumExecutable = (Get-ChildItem "$global:ScriptFolder\BIN\" -Name "*.exe" -ErrorAction Ignore).count 
If($NumExecutable -lt 20){
	$LiteMode=$True
}Else{
	$LiteMode=$False
}
#endregion  ::::: [Variables] --------------------------------------------------------#

$ScriptBeginTimeStamp = Get-Date

# Check if last "\" was provided in $TSS_path, if it was not, add it
if (-not $TSS_path.EndsWith("\")){
	$TSS_path = $TSS_path + "\"
}

#region  ::::: [Functions] -----------------------------------------------------------#
function ExitWithCode ($Ecode) {
	# set ErrorLevel to be picked up by invoking CMD script
	if ( $UseExitCode ) {
		Write-Verbose "[Update] Return Code: $Ecode"
		#error.clear()	# clear script errors
		exit $Ecode
		}
}

function get_local_tss_version {
	<#
	.SYNOPSIS
		Function returns current or LKG TSS version locally from "$TSS_ps1_script -ver" command.
	#>
	param($type="current")
	switch ($type) {
        "current"  	{ $TSS_ps1_script = "TSS.ps1" }
        "LKG" 		{ $TSS_ps1_script = "TSS-LKG.ps1" }
	}
	if ( -not (Test-Path $TSS_ps1_script)) {
		$TSS_ps1_script = "TSS.ps1"
	}  
	Get-Content ..\$TSS_ps1_script | Where-Object {$_ -match 'global:TssVerDate ='} | ForEach-Object { $v2version=($_ -Split '\s+')[3] }
	$TSSversion = $v2version.Replace("""","")
	Write-verbose "[get_local_tss_version] TSSversion= $TSSversion"
	return [version]$TSSversion
}

function get_latest_tss_version {
	<#
	.SYNOPSIS
		Function will get latest version from CesdiagTools/GitHub Release page
	.LINK
		https://github.com/walter-1/TSSv2/releases
		https://cesdiagtools.blob.core.windows.net/windows/TSS.zip
	#>
	EnterFunc ($MyInvocation.MyCommand.Name + "(URL: $RFL_release_url)" )
	if ($UpdMode -match 'Online') {
		return $verOnline # = TSS.ver
	}else{
		# GitHub: Get web content and convert from JSON
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		try { $web_content = Invoke-WebRequest -Uri $tss_release_url -UseBasicParsing | ConvertFrom-Json } catch { "`n$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') *** Failure during TSS update. Exception Message:`n $($_.Exception.Message)" | Out-File $UpdLogfile -Append }
		if ($web_content.tag_name) {
			[version]$expected_latest_tss_version = $web_content.tag_name.replace("v","")
			write-verbose "$UpdateSource Version of '$tss_release_url': --> $expected_latest_tss_version"
			return $expected_latest_tss_version
		}
		else 
		{ Write-Host -ForegroundColor Red "[ERROR] cannot securely access $TssReleaseServer. Please download https://aka.ms/getTSS"
			"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [ERROR] cannot securely access $TssReleaseServer. Please download https://aka.ms/getTSS" | Out-File $UpdLogfile -Append
			$script:ChkFailed=$TRUE
			return 2022.0.0.0
		}
	}
	EndFunc $MyInvocation.MyCommand.Name
}

function DownloadFileFromGitHubRelease {
	param(
		$action = "download", 
		$file, 
		$installedTSSver)
	# Download latest TSS release from CesdiagTools/GitHub
	$repo = "walter-1/TSSv2"
	$releases = "https://api.github.com/repos/$repo/releases"
	#Determining latest release , Set TLS to 1.2
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$tag = (Invoke-WebRequest $releases -UseBasicParsing | ConvertFrom-Json)[0].tag_name
	$downloadURL = "https://github.com/$repo/releases/download/$tag/$file"
	Write-Verbose "downloadURL: $downloadURL"
	$name = $file.Split(".")[0]
	$zip = "$name-$tag.zip"
	$TmpDir = "$name-$tag"
	Write-Verbose "Name: $name - Zip: $zip - Dir: $TmpDir - Tag/version: $tag"
	
	#_# faster Start-BitsTransfer $downloadURL -Destination $zip # is not allowed for GitHub
	Write-Host ".. Secure download of latest release: $downloadURL"
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	Invoke-WebRequest $downloadURL -OutFile $zip

	if ($action -match "download") {
		Write-Host -ForegroundColor Green "[Info] Downloaded version to folder: $TSS_path`scripts\$tss_file"
		}
	if ($action -match "update") {
		#save current script and expand
		Write-Host "... saving a copy of current installed TSS.ps1 to $($TSS_path + "TSS.ps1_v" + $installedTSSver)"
		Copy-Item ($TSS_path + "TSS.ps1") ($TSS_path + "TSS.ps1_v" + $installedTSSver) -Force -ErrorAction SilentlyContinue
		Write-Host "... saving a copy of current \config\tss_config.cfg to $($TSS_path + "config\tss_config.cfg_backup")"
		Copy-Item ($TSS_path + "config\tss_config.cfg") ($TSS_path + "config\tss_config.cfg_backup") -Force -ErrorAction SilentlyContinue
		Write-Host "[Expand-Archive] Extracting release files from $zip"
		Expand-Archive  -Path $zip -DestinationPath $ENV:temp\$TmpDir -Force
		Write-Host ".. Cleaning up .."
		Write-Verbose "Cleaning up target dir: Remove-Item $name -Recurse"
		Write-Verbose "Copying from temp dir: $ENV:temp\$TmpDir to target dir: $TSS_path"
		Copy-Item $ENV:temp\$TmpDir\* -Destination $TSS_path -Recurse -Force
		Write-Verbose "Removing temp file: $zip and folder $TmpDir"
		Remove-Item $zip -Force
		Write-Verbose "Remove-Item $ENV:temp\$TmpDir -Recurse"
		Remove-Item $ENV:temp\$TmpDir -Recurse -Force -ErrorAction SilentlyContinue
		Write-Host -ForegroundColor Gray "[Info] Updated with latest TSS version $script:expected_latest_tss_version"
	}
}

function DownloadTssZipFromCesdiagRelease {
	param(
		$file	# TSS.zip or TSSLite.zip
	)
	switch ($file) {
        "TSS.zip"  	{ $downloadURL = $tss_release_url + "/TSS.zip" }
        "TSSLite.zip" { $downloadURL = $tss_release_url + "/TSSLite.zip"  }
	}
	
	Try {
		"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') .. Secure download of latest release: $downloadURL" | Out-File $UpdLogfile -Append
		Write-Host ".. Secure download of latest release: $downloadURL"
		# faster Start-BitsTransfer; even more faster: 
		# Start-BitsTransfer $downloadURL -Destination "$ENV:temp\TSS_download.zip"
		$webClient = New-Object System.Net.WebClient
		$webClient.DownloadFile($downloadURL, "$ENV:temp\TSS_download.zip")
	}Catch{
		Write-Host -ForegroundColor Red "Failure during TSS download. Exception Message:`n $($_.Exception.Message)"
		"`n$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') *** Failure during TSS download. Exception Message:`n $($_.Exception.Message)" | Out-File $UpdLogfile -Append 
		EXIT 1
	}
	#save current script and expand
	If(Test-Path "$ENV:temp\TSS_download.zip"){
		"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [Info] ... saving a copy of current installed TSS.ps1 to $($TSS_path + "TSS.ps1_v" + $installedTSSver)" | Out-File $UpdLogfile -Append
		Write-Host "... saving a copy of current installed TSS.ps1 to $($TSS_path + "TSS.ps1_v" + $installedTSSver)"
		Copy-Item ($TSS_path + "TSS.ps1") ($TSS_path + "TSS.ps1_v" + $installedTSSver) -Force -ErrorAction SilentlyContinue
		Write-Host "... saving a copy of current \config\tss_config.cfg to $($TSS_path + "config\tss_config.cfg_backup")"
		Copy-Item ($TSS_path + "config\tss_config.cfg") ($TSS_path + "config\tss_config.cfg_backup") -Force -ErrorAction SilentlyContinue
		Write-Host "[Expand-Archive] Extracting release files from $ENV:temp\TSS_download.zip"
		"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [Info] [Expand-Archive] Extracting release files from $ENV:temp\TSS_download.zip" | Out-File $UpdLogfile -Append
		expand-archive -LiteralPath "$ENV:temp\TSS_download.zip" -DestinationPath $TSS_path -force
		"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [Info] [Expand-Archive] .. done LASTEXITCODE: $LASTEXITCODE" | Out-File $UpdLogfile -Append	
		#ToDo
	}
}
#endregion  ::::: [Functions] --------------------------------------------------------#


#region  ::::: [MAIN] ----------------------------------------------------------------#
# detect OS version and SKU # Note: gwmi / Get-WmiObject is no more supportd in PS v7 -> use Get-CimInstance
If($Host.Version.Major -ge 7){
	[Reflection.Assembly]::LoadWithPartialName("System.ServiceProcess.servicecontroller") | Out-Null
	$wmiOSVersion = Get-CimInstance -Namespace "root\cimv2" -Class Win32_OperatingSystem
}else{$wmiOSVersion = Get-WmiObject -Namespace "root\cimv2" -Class Win32_OperatingSystem}
[int]$bn = [int]$wmiOSVersion.BuildNumber
#Write-verbose "installed-version: $(get_local_tss_version current) - Build: $bn"
$installedTSSver = New-Object System.Version([version]$(get_local_tss_version "current"))
Write-verbose "installedTSSver: $installedTSSver"
"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [Info] Running TSS -update : installedTSSver: $installedTSSver" | Out-File $UpdLogfile

## :: Criteria to use Quick vs. Online update: Quick if UpdMode = Quick; Online = if updates in xray or psSDP are needed, ...
# Choose download file based on $UpdMode (and current installed TSS build)
If($LiteMode) {$tss_file = "TSSLite.zip"}else{$tss_file = "TSS.zip" }
switch ($UpdMode) {
        "Quick"	{ 	$tss_file = "TSS_diff.zip"
					$UpdateSource= "GitHub"}
        "Lite"	{ 	$tss_file = "TSSLite.zip"
					$UpdateSource= "GitHub"}
		"Online"{ 	#$tss_file = "TSS.zip"
					$UpdateSource= "CesdiagTools"}
#		"Force" { 	$tss_file = "TSS.zip" }	# always perform a Full update
        default	{ 	#$tss_file = "TSS.zip"
					$UpdateSource= "CesdiagTools"}
}
		
# Check for Internet connectivity // Test-NetConnection does not work for Win7
$checkConn = FwTestConnWebSite $TssReleaseServer -ErrorAction SilentlyContinue
if ( $checkConn -eq "True") {
	"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [Info] CheckConn($checkConn) installedTSSver: $installedTSSver" | Out-File $UpdLogfile -Append
	# Determine which edition we need, ? based on existence of .\x64\TTTracer.exe # + ToDo Lite based on existence/number of *.exe in \BIN folder
	if ($UpdMode -Notmatch "Online") {
		$script:expectedVersion = New-Object System.Version(get_latest_tss_version)
	}
	if ("$($script:expectedVersion)" -eq "0.0") {
		Write-Verbose "Bail out: $script:expectedVersion"; ExitWithCode 20
		"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [Info] Bail out: $script:expectedVersion ExitWithCode 20" | Out-File $UpdLogfile -Append
	}
	# Check if TSS exists in $TSS_path
	if (-not (Test-Path ($TSS_path + "TSS.ps1"))){
		Write-Host -ForegroundColor Red "[Warning] TSS.ps1 could not be located in $TSS_path"
		DownloadFileFromGitHubRelease "update" $tss_file $installedTSSver
	}

	if (Test-Path ($TSS_path + "TSS.ps1")){
		if ($UpdMode -match "Online") {
			DownloadTssZipFromCesdiagRelease -File "TSS.zip"
		}
		elseif ($UpdMode -match "Force") {	# update regardless of current local version
		Write-Host -ForegroundColor Cyan "[Forced update:] to latest version $script:expectedVersion from $UpdateSource`n"
		 if (Test-Path ($TSS_path + "x64\TTTracer.exe")) { Write-Host -ForegroundColor Yellow "[note:] This procedure will not refresh iDNA part"}
									DownloadFileFromGitHubRelease "update" $tss_file $installedTSSver
		}else{
			Write-Host "[Info] checking current version $installedTSSver in $TSS_path against latest released $UpdateSource version $script:expectedVersion."
			if ($($installedTSSver.CompareTo($script:expectedVersion)) -eq 0) { 		# If versions match, display message
				"`n$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff')  [Info] Latest TSS version $script:expectedVersion is installed. " | Out-File $UpdLogfile -Append
				Write-Host -ForegroundColor Cyan "[Info] Latest TSS version $script:expectedVersion is installed.`n"}
			elseif ($($installedTSSver.CompareTo($script:expectedVersion)) -lt 0) {	# if installed current version is lower than latest $UpdateSource Release version
				"`n$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff')  [Action: $tss_action -[Warning] Actually installed TSS version $installedTSSver is outdated] " | Out-File $UpdLogfile -Append
				Write-Host -ForegroundColor red "[Warning] Actually installed TSS version $installedTSSver is outdated"
				Write-Host "[Info] Expected latest TSS version on $($UpdateSource) = $script:expectedVersion"
				Write-Host -ForegroundColor yellow "[Warning] ** Update will overwrite customized configuration, latest \config\tss_config.cfg is preserved in \config\tss_config.cfg_backup. ** "
				switch($tss_action)
					{
					"download"		{ 	Write-Host "[download:] latest $tss_file"
										DownloadFileFromGitHubRelease "download" $tss_file $installedTSSver
									}
					"update"		{ 	Write-Host "[update:] to latest version $script:expectedVersion from $UpdateSource " 
										 if (Test-Path ($TSS_path + "x64\TTTracer.exe")) { Write-Host -ForegroundColor Yellow "[note:] This procedure will not refresh iDNA/TTD part"}
										DownloadFileFromGitHubRelease "update" $tss_file $installedTSSver
									}
					"version"		{ 	Write-Host -background darkRed "[version:] installed TSS version is outdated, please run 'TSS Update', trying AutoUpate" # or answer next question with 'Yes'"
										Write-Host -ForegroundColor Cyan "[Info] running AutoUpdate now... (to avoid updates, append TSS switch 'noUpdate')"
										DownloadFileFromGitHubRelease "update" $tss_file $installedTSSver
									}
					}
					"`n$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff')  [Action: $tss_action - OK] " | Out-File $UpdLogfile -Append
			}else{	# if installed current version is greater than latest CesdiagTools/GitHub Release version
				if ($script:ChkFailed) {Write-Host -ForegroundColor Gray "[Info] Version check failed! Expected version on $($UpdateSource) = $script:expectedVersion. Please download https://aka.ms/getTSS `n"}
				Write-Verbose "Match: Current installed TSS version:  $installedTSSver"
				Write-Verbose "Expected latest TSS version on $($UpdateSource) = $script:expectedVersion"
			}
		}
	}
}else{
	"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [failed update] Missing secure internet connection to $TssReleaseServer. Please download https://aka.ms/getTSS" | Out-File $UpdLogfile -Append
	Write-Host -ForegroundColor Red "[failed update] Missing secure internet connection to $TssReleaseServer. Please download https://aka.ms/getTSS `n"
}

$ScriptEndTimeStamp = Get-Date
$Duration = $(New-TimeSpan -Start $ScriptBeginTimeStamp -End $ScriptEndTimeStamp)
"$(Get-Date -f 'yyyy-MM-dd HH.mm.ss.fff') [Info] Script $scriptName v$updScriptVersion execution finished. Duration: $Duration" | Out-File $UpdLogfile -Append

Write-Host -ForegroundColor Black -background gray "[Info] Script $scriptName v$updScriptVersion execution finished. Duration: $Duration"
if ($AutoUpd) { Write-Host -ForegroundColor Yellow  "[AutoUpdate done] .. Please repeat your TSS command now."}
#endregion  ::::: [MAIN] -------------------------------------------------------------#

#region  ::::: [ToDo] ----------------------------------------------------------------#
<# 
 ToDo: 
 - save any CX changed file like \config\tss_config.cfg into a [backup_v...] subfolder with prev. version, --> easy restoration, if there is no schema change
	see "...saving a copy of installed TSS.ps1  ..."
 - allow TSS to update from CX Central Enterprise store \\server\share\tss defined in \config\tss_config.cfg, if update from CesdiagTools/GitHub fails
 
- Implement a scheduled task for periodic update check
Example one-line command: schtasks.exe /Create /SC DAILY /MO 1 /TN "tss Updater" /TR "powershell \path\to\script\get-latest-tss.ps1 -TSS_path 'path\to\where\tss\is' -tss_arch 'x64'" /ST 12:00 /F
	[/SC DAILY]: Run daily
	[/MO 1]: Every Day
	[/TN "tss Updater"]: Task Name
	[/TR "powershell \path\to\script\get-latest-tss.ps1 -TSS_path 'path\to\where\tss\is' -tss_arch 'x64'"]: Command to run
	[/ST 12:00]: Run at 12 PM
	[/F]: Force update
#>
#endregion  ::::: [ToDo] ----------------------------------------------------------------#


# SIG # Begin signature block
# MIIoOQYJKoZIhvcNAQcCoIIoKjCCKCYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCATivE+bB5w/UTK
# 082jszlwEqCDH713qgRrblFpYmYdhaCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGgowghoGAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEmY
# N/EqebgwQWcX4DY5wD1u4qmhRgq61+NVGfvA+jmfMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEA4DtkLNJK3c6Chv0Tsrb0wYSdEF02QCGDr7AO
# D5kWeVchIng2D9vGjNoMFP3jImuJhEzUkiD6d6oOWt48upiUChTRUwHKTn+zMsgO
# KC6yiZkXvd3gEe+wB0mrQL+/0XE0XgqIFdm2h6Yw+7LV16xFN8OaQlY6GeaXxucI
# c05dFycw8tbE7cfFkVBIHgpS2H8OJvuky+qNuuJglQf3+UZo40LzS120JV9q0fdI
# hY5EZn3bx76e13PIzqpbmXrPlnGTUEOCa6UBM+rVUpTUz2vRywuWEE2fpg4Tl8oy
# 0p1bMSvDcot9MFptg0vIhVAfCSUNH/cwYi+PvBTRx6fWrhXdA6GCF5QwgheQBgor
# BgEEAYI3AwMBMYIXgDCCF3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFSBgsqhkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCBD9NRyODJ/8eMR03iS90wDgsE07/FFwtSY
# NQ7qUqHMxAIGZkZX1jGtGBMyMDI0MDYxMjE1MDA0NS4xMzZaMASAAgH0oIHRpIHO
# MIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
# IFRTUyBFU046MzMwMy0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFNlcnZpY2WgghHqMIIHIDCCBQigAwIBAgITMwAAAebZQp7qAPh94QAB
# AAAB5jANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDAeFw0yMzEyMDYxODQ1MTVaFw0yNTAzMDUxODQ1MTVaMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC9vph84tgluEzm/wpNKlAj
# cElGzflvKADZ1D+2d/ieYYEtF2HKMrKGFDOLpLWWG5DEyiKblYKrE2nt540OGu35
# Zx0gXJBE0zWanZEAjCjt4eGBi+uakZsk70zHTQHHyfP+B3m2BSSNFPhgsVIPp6vo
# /9t6OeNezIwX5E5+VwEG37nZgEexQF2fQZYbxQ1AauqDvRdXsSpK1dh1UBt9EaMs
# zuucaR5nMwQN6sDjG99FzdK9Atzbn4SmlsoLUtRAh/768sKd0Y1hMmKVHwIX8/4J
# uURUBRZ0JWu0NYQBp8khku18Q8CAQ500tFB7VH3pD8zoA4lcA7JkxTGoPKrufm+l
# RZAA4iMgbcLZ2P/xSdnKFxU8vL31RoNlZJiGL5MqTXvvyBLz+MRP4En9Nye1N8x/
# lJD1stdNo5wJG+mgXsE/zfzg2GaVqQczFHg0Nl8bpIqnNFUReQRq3C1jVYMCSceg
# NzHeYtw5OmZ/7eVnRmjXlCsLvdsxOzc1YVn6nZLkQD5y31HYrB9iIHuswhaMv2hJ
# NNjVndkpWy934PIZuWTMk360kjXPFwl2Wv1Tzm9tOrCq8+l408KIL6J+efoGNkR8
# YB3M+u1tYeVDO/TcObGHxaGFB6QZxAUpnfB5N/MmBNxMOqzG1N8QiwW8gtjjMJiF
# Bf6iYYrCjtRwF7IPdQLFtQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFOUEMXntN54+
# 11ZM+Qu7Q5rg3Fc9MB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBhbuogTapRsuwS
# kaFMQ6dyu8ZCYUpWQ8iIrbi40tU2hK6pHgu0hj0z/9zFRRx5DfhukjvbjA/dS5VY
# fxz1EIbPlt897MJ2sBGO2YLYwYelfJpDwbB0XS9Zkrqpzq6X/lmDQDn3G5vcYpYQ
# CJ55LLvyFlJ195AVo4Wy8UX5p7g9W3MgNHQMpM+EV64+cszj4Ho5aQmeKGtKy7w7
# 2eRY/vWDuptrvzruFNmKCIt12UcA5BOsXp1Ptkjx2yRsCj77DSml0zVYjqW/ISWk
# rGjyeVJ+khzctxaLkklVwCxigokD6fkWby0hCEKTOTPMzhugPIAcxcHsR2sx01YR
# a9pH2zvddsuBEfSFG6Cj0QSvEZ/M9mJ+h4miaQSR7AEbVGDbyRKkYn80S+3AmRlh
# 3ZOe+BFqJ57OXdeIDSHbvHzJ7oTqG896l3eUhPsZg69fNgxTxlvRNmRE/+61Yj7Z
# 1uB0XYQP60rsMLdTlVYEyZUl5MLTL5LvqFozZlS2Xoji4BEP6ddVTzmHJ4odOZMW
# TTeQ0IwnWG98vWv/roPegCr1G61FVrdXLE3AXIft4ZN4ZkDTnoAhPw7DZNPRlSW4
# TbVj/Lw0XvnLYNwMUA9ouY/wx9teTaJ8vTkbgYyaOYKFz6rNRXZ4af6e3IXwMCff
# CaspKUXC72YMu5W8L/zyTxsNUEgBbTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKb
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
# ELQdVTNYs6FwZvKhggNNMIICNQIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjMzMDMtMDVF
# MC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMK
# AQEwBwYFKw4DAhoDFQDiWNBeFJ9jvaErN64D1G86eL0mu6CBgzCBgKR+MHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hPEJTAi
# GA8yMDI0MDYxMjA2NTIyMVoYDzIwMjQwNjEzMDY1MjIxWjB0MDoGCisGAQQBhFkK
# BAExLDAqMAoCBQDqE8QlAgEAMAcCAQACAgzLMAcCAQACAhN9MAoCBQDqFRWlAgEA
# MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAI
# AgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAIAlF48QzlI0/nUHE309In7Re3wM
# MsGVjJvH8QyDFSgdoxa7iAmmbjxSHDj6ROWkpC+pwCh+5mnmtyOY+qgPJEZEcevG
# QOsMAgxSDwgFkjGjLOH10ANMGpv4Lgoff15oV0kg8+vW2w/iCzmazenro/KU2s6j
# Z27cpZ1OxWwThafsEoZaHcAVrR5ltkJExcEgSxfLnFTE9citlY/FGfJPAoPLArf9
# as9MesxZrnhwS1Rdd46zfa2R/Wt/seKge8aJHEJfs3QRx4M+hhQUVBnsyUrMImxM
# vXTW9w442Q6+6RTSZb8etmYaQLmFut1dPrTkvFtMH2B/ScfASx1jnJLzzY4xggQN
# MIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAebZ
# Qp7qAPh94QABAAAB5jANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0G
# CyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCBk6x+eunr5FF/U5y5BFQd0xOZw
# QiMbmi7mxH9CL6JvtDCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIM+7o4ao
# HrMJaG8gnLO1q16hIYcRnoy6FnOCbnSD0sZZMIGYMIGApH4wfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAHm2UKe6gD4feEAAQAAAeYwIgQgy6KmSaER
# UFw5zM8ixrWjedEWrCkXYG0+8JQBRQ+GJXIwDQYJKoZIhvcNAQELBQAEggIAbOmt
# xi1vxCLdbYZHVBX2HY60BUGhB72n04H7g7WD5o6Jy77ii7nRMGF90KnJDl0lYbOy
# aP8nD5F7+fQmxH5Us/nbyqv/b9NBuYZOyJlUgEdLmv97Yc300hVnP9tmlwKx7iEw
# N4pMRERYcWzMokQ3K/fVuCgnDz5y6OjEAlP9nmSy7fUL3/GoKkx1ekhgbJ+vm6zM
# CXx2DlSBFZdTll40bliPgQrKLPVgcUBulzSHFKksIzKL/DPmccLCvQ5Fh/toPuEz
# wFEiEKShnzHMDOUS2kLtaKxNKFPCrIG6UxhzL8MjYBgC9bPm0U4iGwaZIe9IWalB
# 3k8FTo3v+8vMA+oyVlz9VATocO6RkkJ4y8F9Sy8fSSdNfKRpWAqyU5peh9KyTp+N
# D+i2vdKYXxLtpI1uN0d4wDNHyp8mHF4tZcZ8kntxc9Xb3SsvhiocVQNXcipoIKkB
# a2GF2nCQSuDVRCurDyFwpAXg+EXuXTRNeF097b5yiGRnZVDEZYc0zRCIowdhWcbE
# GFXTwISI5J+G5hAE7mLA6ON6aPgUL6elJMgW1Is+k/Ipnt1DWW2Kt0NObKZcIZK+
# keZhqLOjHYq0eGpms4qiMXpw+Radl7UmVHkKjS8PUiZ6en9rGErCuAOQ3X7O0I+j
# 0PfQ5MNINlszdJOt03CEPkMZC9LLIUrhtyWeq4g=
# SIG # End signature block
