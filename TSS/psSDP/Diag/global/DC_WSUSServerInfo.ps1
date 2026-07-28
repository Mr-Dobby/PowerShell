# ***********************************************************************************************************
# Version 1.0
# Date: 11-12-2012
# Author: Vinay Pamnani - vinpa@microsoft.com
# Description:
#
# ***********************************************************************************************************

trap [Exception]
{
	WriteTo-ErrorDebugReport -ErrorRecord $_
	continue
}

TraceOut "Started"

Import-LocalizedData -BindingVariable ScriptStrings
$sectiondescription = "WSUS Server Information"

If ($Is_WSUS)
{
	# ----------------
	# Write Progress
	# ----------------
	Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WSUSInfo -Status $ScriptStrings.ID_SCCM_WSUSInfo_WSUS

	$WSUSInfo = New-Object PSObject

	# Summary File Header
	$WSUSFile = Join-Path $Pwd.Path ($ComputerName + "__WSUS_Summary.txt")
	"======================" | Out-File $WSUSFile
	"Update Server Summary:" | Out-File $WSUSFile -Append
	"======================" | Out-File $WSUSFile -Append

	# -------------
	# Computer Name
	# -------------
	Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Computer Name" -Value $ComputerName
	Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Logged On User" -Value ($Env:USERDOMAIN + "\" + $Env:USERNAME)

	# ----------------------
	# Time zone information:
	# ----------------------
	$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_TimeZone -ErrorAction SilentlyContinue
	If ($Temp -is [CimInstance]) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Time Zone" -Value $Temp.Description }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Time Zone" -Value "Error obtaining value from Win32_TimeZone WMI Class" }

	$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
	If ($Temp -is [CimInstance]) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Daylight In Effect" -Value $Temp.DaylightInEffect }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Daylight In Effect" -Value "Error obtaining value from Win32_ComputerSystem WMI Class" }

	# -----------------------
	# WUA Service Status
	# -----------------------
	$Temp = Get-Service | Where-Object {$_.Name -eq 'WsusService'} | Select-Object Status
	If ($null -ne $Temp) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Update Services Service Status" -Value $Temp.Status
	}
	Else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Update Services Service Status" -Value "ERROR: Service Not found"
	}

	# --------------------------
	# WUA Service StartTime
	# --------------------------
	$Temp = Get-Process | Where-Object {($_.ProcessName -eq 'WsusService')} | Select-Object StartTime
	If ($null -ne $Temp) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Update Services Service StartTime" -Value $Temp.StartTime
	}
	Else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Update Services Service StartTime" -Value "ERROR: Service Not running"
	}

	# --------------------------
	# WSUS Registry Settings
	# --------------------------
	$Version = Get-RegValue ($Reg_WSUS + "\Server\Setup") "VersionString"
	If ($null -ne $Version) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Version" -Value $Version }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Version" -Value "Error obtaining value from Registry" }

	$Temp = Get-RegValue ($Reg_WSUS + "\Server\Setup") "ContentDir"
	If ($null -ne $Temp) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Content Directory" -Value $Temp }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Content Directory" -Value "Error obtaining value from Registry" }

	$Temp = Get-RegValue ($Reg_WSUS + "\Server\Setup") "PortNumber"
	If ($null -ne $Temp) {
		$Port = $Temp
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Port Number" -Value $Temp }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Port Number" -Value "Error obtaining value from Registry" }

	$Temp = Get-RegValue ($Reg_WSUS + "\Server\Setup") "SqlServerName"
	If ($null -ne $Temp) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SQL Server Name" -Value $Temp }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SQL Server Name" -Value "Error obtaining value from Registry" }

	$Temp = Get-RegValue ($Reg_WSUS + "\Server\Setup") "SqlDatabaseName"
	If ($null -ne $Temp) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SQLDatabaseName" -Value $Temp }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SQLDatabaseName" -Value "Error obtaining value from Registry" }

	$Temp = Get-RegValue ($Reg_WSUS + "\Server\Setup") "SqlAuthenticationMode"
	If ($null -ne $Temp) {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SQL Authentication Mode" -Value $Temp }
	else {
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SQL Authentication Mode" -Value "Error obtaining value from Registry" }

	$Temp = Get-RegValue ($Reg_WSUS + "\Server\Setup") "UsingSSL"
	If ($Temp -eq 1) {
		$SSL = $true
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SSL Enabled" -Value $Temp
		$Temp = Get-RegValue ($Reg_WSUS + "\Server\Setup") "ServerCertificateName"
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "ServerCertificateName" -Value $Temp }
	else {
		$SSL = $false
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "SSL Enabled" -Value 0 }

	# --------------------------
	# Instantiate WSUS Object
	# --------------------------
	try {
		[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
		$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($ComputerName,$SSL,$Port)
	}
	catch [System.Exception]
	{
		TraceOut "Failed to connect to the WSUS Server."
		TraceOut "  Error:" $_.Exception.Message
		$wsus = $null
	}

	If ($ManifestName -eq "WSUS") {
		# ----------------
		# Write Progress
		# ----------------
		Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WSUSInfo -Status $ScriptStrings.ID_SCCM_WSUSInfo_FileListContent

		# ------------------------------------
		# File List from WSUS ContentDirectory
		# ------------------------------------
		if ($null -ne $wsus) {
			$ContentPath = $wsus.GetConfiguration().LocalContentCachePath
			$TempFileName = ($ComputerName + "_WSUS_FileList_ContentDir.TXT")
			$OutputFile = join-path $pwd.path $TempFileName
			Get-ChildItem ($ContentPath) -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
				Select-Object LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
				Out-File $OutputFile -Width 1000
			If ($DirError.Count -eq 0) {
				CollectFiles -filesToCollect $OutputFile -fileDescription "WSUS Content File List" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
				Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "WSUS Content File List" -Value ("Review $TempFileName")
			}
			else {
				Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "WSUS Content File List" -Value ("ERROR: " + $DirError[0].Exception.Message)
				$DirError.Clear()
			}
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "WSUS Content File List" -Value ("ERROR: Unable to connect to WSUS Server.")
		}

		# ----------------
		# Write Progress
		# ----------------
		Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WSUSInfo -Status $ScriptStrings.ID_SCCM_WSUSInfo_FileListInstall

		# --------------------------------
		# File List from Install Directory
		# --------------------------------
		$TempFileName = ($ComputerName + "_WSUS_FileList_InstallDir.TXT")
		$OutputFile = join-path $pwd.path $TempFileName
		Get-ChildItem ($WSUSInstallDir) -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
			Select-Object LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
			Out-File $OutputFile -Width 1000
		If ($DirError.Count -eq 0) {
			CollectFiles -filesToCollect $OutputFile -fileDescription "Server File List" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Server File List" -Value ("Review $TempFileName")
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Server File List" -Value ("ERROR: " + $DirError[0].Exception.Message)
			$DirError.Clear()
		}

		# ----------------
		# Write Progress
		# ----------------
		Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WSUSInfo -Status $ScriptStrings.ID_SCCM_WSUSInfo_FileVer

		# ---------------------
		# Binary Versions List
		# ---------------------
		$TempFileName = ($ComputerName + "_WSUS_FileVersions.TXT")
		$OutputFile = join-path $pwd.path $TempFileName
		Get-ChildItem ($WSUSInstallDir) -recurse -include *.dll,*.exe -ErrorVariable DirError -ErrorAction SilentlyContinue | `
			ForEach-Object {[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_)} | `
			Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize | `
			Out-File $OutputFile -Width 1000
		If ($DirError.Count -eq 0) {
			CollectFiles -filesToCollect $OutputFile -fileDescription "Server File Versions" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Server File Versions" -Value ("Review $TempFileName")
		}
		else {
			Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "Server File Versions" -Value ("ERROR: " + $DirError[0].Exception.Message)
			$DirError.Clear()
		}
	}

	# ----------------
	# Write Progress
	# ----------------
	Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WSUSInfo -Status $ScriptStrings.ID_SCCM_WSUSInfo_Logs

	# ------------------
	# Collect WSUS Logs
	# ------------------
	$filesDescription = "WSUS Logs"
	$WSUSLogPath = $WSUSInstallDir + "LogFiles"
	$Destination = Join-Path $Env:windir ("\Temp\" + $ComputerName + "_Logs_WSUS")
	$ZipName = "Logs_WSUS.zip"
	TraceOut "WSUS Logs Directory: $WSUSLogPath"

	# Remove temp destination directory if it exists
	If (Test-Path $Destination)	{
		Remove-Item -Path $Destination -Recurse
	}

	# Copy Logs, if they exist.
	If (Test-Path $WSUSLogPath) {
		# ----------------
		# Write Progress
		# ----------------
		Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WSUSInfo -Status $ScriptStrings.ID_SCCM_WSUSInfo_Compress

		New-Item -ItemType "Directory" $Destination | Out-Null #_#
		Copy-Item ($WSUSLogPath + "\*.log") ($Destination) -Force -ErrorAction SilentlyContinue

		# --------------------------
		# Compress and Collect Logs
		# --------------------------
		compressCollectFiles -DestinationFileName $ZipName -filesToCollect $Destination -sectionDescription $sectionDescription -fileDescription $filesDescription -ForegroundProcess -noFileExtensionsOnDescription
		Remove-Item -Path $Destination -Recurse
	}

	# ----------------
	# Write Progress
	# ----------------
	Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WSUSInfo -Status $ScriptStrings.ID_SCCM_WSUSInfo_BasicInfo

	# --------------------------
	# Get WSUS Basic Info
	# --------------------------
	$TempFileName = ($ComputerName + "_WSUS_BasicInfo.txt")
	$TempFileName2 = ($ComputerName + "_WSUS_UpdateApprovals.txt")
	$WSUSBasicInfoFile = Join-Path $PWD.Path $TempFileName
	$ApprovalsFile = Join-Path $Pwd.Path $TempFileName2

	try {
		.\Get-WSUSBasicInfo.ps1 -GetApprovedUpdates -OutputDirectory $PWD.Path -SilentExecution
		CollectFiles -filesToCollect $WSUSBasicInfoFile -fileDescription "WSUS Basic Info" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
		CollectFiles -filesToCollect $ApprovalsFile -fileDescription "WSUS Approved Updates" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "WSUS Basic Info" -Value "Review $TempFileName"
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "WSUS Approved Updates" -Value "Review $TempFileName2"
	}
	catch [System.Exception]
	{
		$errMessage = $_.Exception.Message
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "WSUS Basic Info" -Value $errMessage
		Add-Member -InputObject $WSUSInfo -MemberType NoteProperty -Name "WSUS Approved Updates" -Value $errMessage
	}

	# --------------------------
	# Collect WSUS Summary File
	# --------------------------
	# Output WSUSInfo PSObject to Summary File
	$WSUSInfo | Out-File $WSUSFile -Append -Width 500
	CollectFiles -filesToCollect $WSUSFile -fileDescription "WSUS Summary" -sectionDescription $global:SummarySectionDescription -noFileExtensionsOnDescription
}

# ---------------------------------------------------
# Collect WSUS Setup Logs (If not older than 30 days)
# ---------------------------------------------------
$filesDescription = "WSUS Setup Logs"
$Destination = Join-Path $Env:windir ("\Temp\" + $ComputerName + "_Logs_WSUSSetup")
$ZipName = "Logs_WSUSSetup.zip"

# Remove temp destination directory if it exists
If (Test-Path $Destination)
{
	Remove-Item -Path $Destination -Recurse
}

# Copy Logs, if they exist and are not older than 30 days
New-Item -ItemType "Directory" $Destination | Out-Null #_#
$dateStart = (Get-Date).AddDays(0-30)
Get-ChildItem $Env:Temp -Recurse -Include "WSUS*.log" | ForEach-Object {
	Copy-Item $_.FullName $Destination
}
compressCollectFiles -DestinationFileName $ZipName -filesToCollect $Destination -sectionDescription $sectionDescription -fileDescription $filesDescription -ForegroundProcess -noFileExtensionsOnDescription
Remove-Item -Path $Destination -Recurse

TraceOut "Completed"


# SIG # Begin signature block
# MIInmAYJKoZIhvcNAQcCoIIniTCCJ4UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB7Vs9oRJmm4Vm2
# XGrN04qg5X1fMgZ0TXMw1lZg9w52faCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGXgwghl0AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAANOtTx6wYRv6ysAAAAAA04wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILvJ0adFkJCA4QFxYLZHzfpc
# fnqR7VXGreikVQ8R4THMMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCXJK436a9nU1j0IekMlcILjUmJ4slyDjOcEpd/wSYITgjzxLi1itpm
# n+GzYYZGSSZ+GUdHRZw1dyHal2AK8XXVCYyUhS2bm+Su1t290r5u4VqKTv8GNsE3
# aI1+pHHn9WsO+03rDcldYNVxQM2QT9ofoRhAMNu/ToURO7+xVBr1TYC+zhcAkUx8
# WDra4DtRM7SrF9n2sPNqussfJmOXhJq0e9s/UJ53euBH3srH5Yle5SAnmdKQMV0z
# 1jnw36RT9ooUcbhhOTMcysK8oKq+6NfQJdCOUjxZz9iUnf7kDu3wNURhkCuOKWLO
# /m6YZLe7FHYEkYl0G1/z99lqVzu1Sz8soYIXADCCFvwGCisGAQQBgjcDAwExghbs
# MIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIGhqsQ1BRPi4f0Yjwm3s9B815KpkYRR5vQ+kDoZN1ia1AgZki1im
# w1YYEzIwMjMwNzEwMDc0MDE1LjM5NVowBIACAfSggdCkgc0wgcoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkFFMkMt
# RTMyQi0xQUZDMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRVzCCBwwwggT0oAMCAQICEzMAAAG/3265BBVSKFgAAQAAAb8wDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjIxMTA0MTkw
# MTI0WhcNMjQwMjAyMTkwMTI0WjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046QUUyQy1FMzJCLTFBRkMxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC4TGHSfVTEozMG+Q8d6vjuevIPhQrYZXLVfps5UL6E
# tWEOWwhZDW5f/1rwhEjfNej/LWhMO6P6skfJfg5lCfjYTSK7vHqzA+8zfjMg5I+f
# yWCdbMYQCxG3P3MGstb37jD9iFaVcjyG9zui+q6m4vdNe17wFuY05QNIv467ZsF8
# 5sbOwffJj8EQu+rA7Xcpn1nU7EppyeqrW70T1GFqL3RJOiDbaVHYxVFLHnkUeL96
# adkD8gq+wC0QfYromaA7JDv+YNCtY0QDmuhSOFCotDDX/fDP8Ii9z34U/FfZ3FHS
# e+9h7lUuq/xD31w6Q7rPpXiy0YPIUO47wLC2JK8ILdCs466ACXfdo8P1hmzDLBZG
# T5gbIsj4XD6QIJRjqHWo6NOPmCXPR6yZ2ze57jlZojaEj26wWiszyDL//m0NlePQ
# opTUHEDTjGl8TL3VFlRtzql0C8SSlis3aOWleEy9MPumB1jLGRVJpZm/uRannL02
# NY/8JMMZdMLoNaIZxfA9A7rpB1U1bG6IZ2l89oRSdZdwqcNW5rWSEEDE7ib3CD/W
# ozp/sfBd/+keJ8x6P6oHtJRk6IlJxf7UeZ9+ZlEAWIldLSpQOTRkBlbehfbEvKXT
# Tjh4cjtj3kY9rDw6VJN42I0AqX4zIfk5qJ+xS7JUc5/iuysT5nIC5L170RGq7kf/
# XQIDAQABo4IBNjCCATIwHQYDVR0OBBYEFFUCiVRPd5XfAr/4u5//BrAI8xinMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQAD
# ggIBACMJES+NPrJfAlh2+QVSpMYaHpGLMBj5yK4HpQ4FSbTKqrlAL7mkIRr1ZIy9
# tQbPEMIQUGAP3eBYaeSLJhwcJrOWBkr4TtbG0jds/74VvhElmJYuj8gL2FfXaEJl
# nBhcgZXML0FUBw3H/OwWoj/27y79uEaMMc9p3jsLg5A0IeuQ2rMZjFvgZCro+zDq
# jtwS3LcxTcl3i7MFrNoWE9G+YF9Kf5R93qlM1kuAhf0GOsuZluVz93YsgC6sSvlb
# b1Z9blExEgRnM71Noyv/PN2Zb9xXpV1oNPKDLmDg7dRdp23UOtpSmfmNwPXRNVY2
# fLP+lp6V4eiOsYIKSyp7Gl6UyRSyJg/Qdf2kVSA2CVZTXSvXATMXBkz1pfZGqrd8
# VGs3eC7y0Jf4fWcorYChtbW+awotMfo/JfUuTK9HBOPjlrWlp4chHxMbObf6JjvC
# kLUwe7OoCoB0N5ohV1WVyHzTtUkniEOK97oCI5AJX0zCJTKF/m/g/yNMah/wKqMN
# vc+cuU1KcWbYEWExnfmg1MSixzfsZkdJwzzeFM3UTjzWwtgmuuGFx21zI0HrSO4y
# OoZQPq5D/sNsy+2/3e0WPlaPFWEwKSRjroQRiCl8Us4JvaeAklYW4kIgawKIN8PE
# bAThFVgCegXOhrY59KqKNiDZ2t1l+mm1FG8rEywDO7ejGRL9MIIHcTCCBVmgAwIB
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
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEBMIH4oYHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjpBRTJDLUUzMkItMUFGQzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAOAR34k2unh2m8UoxmL3W3Ft+Jzeg
# gYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
# AQUFAAIFAOhWI0swIhgPMjAyMzA3MTAxNDI3MjNaGA8yMDIzMDcxMTE0MjcyM1ow
# dzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA6FYjSwIBADAKAgEAAgINIwIB/zAHAgEA
# AgIRwjAKAgUA6Fd0ywIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMC
# oAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAAU7WYSU
# qQ0oKMjts+BbGUKjL8AG+8Q0b8GXZaqOlvQKOlp3+Q7zDH9UukhysLZsPDvdmAcN
# hKROTfPS3kQlD7Lvl2P/nYr9WPWHxkX7sF9RTXgbcEO+eQtH/IqVpUblbtQKi6mB
# SuO8rFiYLOU7xECd4OxibUexUHhIUnONIiTzMYIEDTCCBAkCAQEwgZMwfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAG/3265BBVSKFgAAQAAAb8wDQYJ
# YIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkq
# hkiG9w0BCQQxIgQg78PbOYA4GXFbd03ZdR1Jmq35w1kIQiU9mNPBJ2P3Y6MwgfoG
# CyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCD9Di1HPrcSJGPgr7X3I1TCiAEg6ynj
# gIi4F+dkcK8FrjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# AhMzAAABv99uuQQVUihYAAEAAAG/MCIEIBZpUmvxvVSlLttmVsMPjgUXqP69XHsg
# IsAxPEJjErq+MA0GCSqGSIb3DQEBCwUABIICACe/UHB2HvTVneHRFjtxrGjmC44S
# KOr4uSQMQ/AedTjj04Nhk5G1PNKnwMsuGCumklHArgprsUfwr5ftNfh+TkzOB1hk
# zdlHsBw1QKZkJIR7ZvPx5F3Gievq2duxLEV9LYR9raAqwjOuEtyzA9um+9hNzEjO
# UfzaY/ntsfw7gPO1kYAQDFIQJ/1hr/4FwYvXqfw+BF7gF6IpOqk2dV/VyUuHjBk7
# F9dCgjfuSN5eElCMcHM3/DvZLxNTcmIc+8Bn8mnyFaBLdVwPFnodWV0L835lgCte
# UEB4GephnYgKLJzbSa/rOuGZVpbHeUz42Cz9CnaIhuCx9ks7+/6PykeS6Z0N534u
# mkHu7fwnKKudV8iMespUoOjugaiaAx0291DlSbQqugY8A000eiJ5c3OOK8T/lPRG
# cuSr+SGBYY7sGFQUI3bdyulGIS7Eh5zOM26ryYaTt+vrkErzdoEe3HLXRDEUsL1e
# Atc0yY4szcGKvN9zQmAVRy0fFEjlFkOqBF7Vxhld0LhBfLeIgaXbzhTIctd7oXiA
# Yf6nzJqtFg1asGCYHlyjqjqXBSHS3WD/cB9Pflyn4igel56hJ7/sLbIEdQAB27NR
# rRK67edj0eRoOXoZIuVghgEq+R2k5Xpc2I38c2eQMNpW/Cyl5LFgUrcyyx4IjAaO
# TERXw4YXL4WoQz8i
# SIG # End signature block
