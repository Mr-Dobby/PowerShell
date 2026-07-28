trap [Exception]
{
	WriteTo-ErrorDebugReport -ErrorRecord $_
	continue
}

If (!$Is_SiteServer) {
	TraceOut "ConfigMgr Site Server not detected. This script gathers data only from a Site Server. Exiting."
	exit 0
}

TraceOut "Started"

Import-LocalizedData -BindingVariable ScriptStrings
$sectiondescription = "Configuration Manager Server Information"

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ServerInfo -Status $ScriptStrings.ID_SCCM_CM07ServerInfo_ServerInfo
TraceOut "    Getting Server Information"

# ----------------------
# Current Time:
# ----------------------
AddTo-CMServerSummary -Name "Current Time" -Value $CurrentTime

# -------------
# Computer Name
# -------------
AddTo-CMServerSummary -Name "Server Name" -Value $ComputerName

# ----------
# Site Code
# ----------
$Temp = Get-RegValueWithError ($Reg_SMS + "\Identification") "Site Code"
AddTo-CMServerSummary -Name "Site Code" -Value $Temp

# ----------
# Site Code
# ----------
$Temp = Get-RegValueWithError ($Reg_SMS + "\Identification") "Parent Site Code"
AddTo-CMServerSummary -Name "Parent Site Code" -Value $Temp

# ----------
# Site Type
# ----------
# $SiteType = Get-RegValueWithError ($Reg_SMS + "\Setup") "Type"
If ($SiteType -eq 8) {
	AddTo-CMServerSummary -Name "Site Type" -Value "Central Administration Site" }
ElseIf ($SiteType -eq 1) {
	AddTo-CMServerSummary -Name "Site Type" -Value "Primary Site" }
ElseIf ($SiteType -eq 2) {
	AddTo-CMServerSummary -Name "Site Type" -Value "Secondary Site" }
else {
	AddTo-CMServerSummary -Name "Site Type" -Value $SiteType
}

# -------------
# Site Version
# -------------
$Temp = Get-RegValueWithError ($Reg_SMS + "\Setup") "Full Version"
AddTo-CMServerSummary -Name "Site Version" -Value $Temp

# ----------------
# Monthly Version
# ----------------
if ($global:SiteType -eq 2) {
	AddTo-CMServerSummary -Name "MonthlyReleaseVersion" -Value "Not Available on a Secondary Site"
}
else {
	$Temp = Get-CimInstance -Computer $SMSProviderServer -Namespace $SMSProviderNamespace -Class SMS_Identification -ErrorAction SilentlyContinue
	If ($Temp -is [CimInstance]) {
		AddTo-CMServerSummary -Name "MonthlyReleaseVersion" -Value $Temp.MonthlyReleaseVersion }
	else {
		AddTo-CMServerSummary -Name "MonthlyReleaseVersion" -Value "Not Available" }
}

# -------------
# CU Level
# -------------
$Temp = Get-RegValueWithError ($Reg_SMS + "\Setup") "CULevel"
AddTo-CMServerSummary -Name "CU Level" -Value $Temp

# -------------
# ADK Version
# -------------
$global:ADKVersion = Get-ADKVersion
AddTo-CMServerSummary -Name "ADK Version" -Value $global:ADKVersion

# ----------------------------------------------------------
# Installation Directory - defined in utils_ConfigMgr12.ps1
# ----------------------------------------------------------
If ($null -ne $SMSInstallDir) {
	AddTo-CMServerSummary -Name "Installation Directory" -Value $SMSInstallDir }
else {
	AddTo-CMServerSummary -Name "Installation Directory" -Value "Error obtaining value from Registry" }

# -----------------
# Provider Location
# -----------------
if ($global:SiteType -eq 2) {
	AddTo-CMServerSummary -Name "Provider Location" -Value "Not available on a Secondary Site"
}
else {
	If ($null -ne $global:SMSProviderServer) {
		AddTo-CMServerSummary -Name "Provider Location" -Value $SMSProviderServer }
	else {
		AddTo-CMServerSummary -Name "Provider Location" -Value "Error obtaining value from Registry" }
}

# -----------
# SQL Server
# -----------
$Temp = Get-RegValue ($Reg_SMS + "\SQL Server\Site System SQL Account") "Server"
AddTo-CMDatabaseSummary -Name "SQL Server" -Value $Temp -NoToSummaryQueries

# --------------
# Database Name
# --------------
$Temp = Get-RegValueWithError ($Reg_SMS + "\SQL Server\Site System SQL Account") "Database Name"
AddTo-CMDatabaseSummary -Name "Database Name" -Value $Temp -NoToSummaryQueries

# ----------------
# SQL Ports
# ----------------
$Temp = Get-RegValueWithError ($Reg_SMS + "\SQL Server\Site System SQL Account") "Port"
AddTo-CMDatabaseSummary -Name "SQL Port" -Value $Temp -NoToSummaryQueries

$Temp = Get-RegValueWithError ($Reg_SMS + "\SQL Server\Site System SQL Account") "SSBPort"
AddTo-CMDatabaseSummary -Name "SSB Port" -Value $Temp -NoToSummaryQueries

# -----------------------
# SMSExec Service Status
# -----------------------
$Temp = Get-Service | Where-Object {$_.Name -eq 'SMS_Executive'} | Select-Object Status
If ($null -ne $Temp) {
	if ($Temp.Status -eq 'Running') {
		$Temp2 = Get-Process | Where-Object {$_.ProcessName -eq 'SMSExec'} | Select-Object StartTime
		AddTo-CMServerSummary -Name "SMS_Executive Status" -Value "Running. StartTime = $($Temp2.StartTime)"
	}
	else {
		AddTo-CMServerSummary -Name "SMS_Executive Status" -Value $Temp.Status
	}
}
Else {
	AddTo-CMServerSummary -Name "SMS_Executive Status" -Value "ERROR: Service Not found"
}

# -----------------------
# SiteComp Service Status
# -----------------------
$Temp = Get-Service | Where-Object {$_.Name -eq 'SMS_SITE_COMPONENT_MANAGER'} | Select-Object Status
If ($null -ne $Temp) {
	if ($Temp.Status -eq 'Running') {
		$Temp2 = Get-Process | Where-Object {$_.ProcessName -eq 'SiteComp'} | Select-Object StartTime
		AddTo-CMServerSummary -Name "SiteComp Status" -Value "Running. StartTime = $($Temp2.StartTime)"
	}
	else {
		AddTo-CMServerSummary -Name "SiteComp Status" -Value $Temp.Status
	}
}
Else {
	AddTo-CMServerSummary -Name "SiteComp Status" -Value "ERROR: Service Not found"
}

# ----------------------
# SMSExec Thread States
# ----------------------
$TempFileName = $ComputerName + "_CMServer_SMSExecThreads.TXT"
$OutputFile = join-path $Env:windir ("TEMP\" + $TempFileName)
Get-ItemProperty HKLM:\Software\Microsoft\SMS\Components\SMS_Executive\Threads\* -ErrorAction SilentlyContinue -ErrorVariable DirError `
	| Select-Object PSChildName, 'Current State', 'Startup Type', 'Requested Operation', DLL `
	| Sort-Object @{Expression='Current State';Descending=$true}, @{Expression='PSChildName';Ascending=$true} `
	| Format-Table -AutoSize | Out-String -Width 200 | Out-File -FilePath $OutputFile
If ($DirError.Count -eq 0) {
	CollectFiles -filesToCollect $OutputFile -fileDescription "SMSExec Thread States" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	AddTo-CMServerSummary -Name "SMSExec Thread States" -Value "Review $TempFileName" -NoToSummaryReport
	Remove-Item $OutputFile -Force
}
else {
	AddTo-CMServerSummary -Name "SMSExec Thread States" -Value ("ERROR: " + $DirError[0].Exception.Message) -NoToSummaryReport
	$DirError.Clear()
}

# -----------------
# SQL Server SPN's
# -----------------
#TraceOut "    Getting SQL SPNs"
#$TempFileName = ($ComputerName + "_CMServer_SQLSPN.TXT")
#$FileToCollect = join-path $pwd.Path $TempFileName
#$CmdToRun = ".\psexec.exe /accepteula -s $pwd\ldifde2K3x86.exe -f $FileToCollect -l serviceprincipalname -r `"(serviceprincipalname=MSSQLSvc/$ConfigMgrDBServer*)`" -p subtree"

#RunCmD -commandToRun $CmdToRun -collectFiles $false
#If (Test-Path $FileToCollect) {
#	If ((Get-Content $FileToCollect) -ne $null) {
#		If ((Get-Content $FileToCollect) -ne "") {
#			CollectFiles -filesToCollect $FileToCollect -fileDescription "SQL SPNs"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription
#			AddTo-CMServerSummary -Name "SQL Server SPNs" -Value ("Review $TempFileName") -NoToSummaryReport
#		}
#		Else {
#			TraceOut "    No SPN's found. Output file was null."
#			# AddTo-CMServerSummary -Name "SQL Server SPNs" -Value ("Error. No SPNs found!") -NoToSummaryReport
#		}
#	}
#	Else {
#		TraceOut "    No SPN's found. Output file was empty."
#		# AddTo-CMServerSummary -Name "SQL Server SPNs" -Value ("Error. No SPNs found!") -NoToSummaryReport
#	}
#}
#Else {
#	TraceOut "    No SPN's found. Output file was not found."
#	AddTo-CMServerSummary -Name "SQL Server SPNs" -Value ("Error. SPN Query Failed!") -NoToSummaryReport
#}

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ServerInfo -Status $ScriptStrings.ID_SCCM_CM07ServerInfo_Hierarchy
TraceOut "    Getting Site Hierarchy"

# ------------------
# Hierarchy Details
# ------------------
$TempFileName = $ComputerName + "_CMServer_Hierarchy.txt"
$OutputFile = join-path $Env:windir ("TEMP\" + $TempFileName)
Run-DiagExpression .\GetCM12Hierarchy.ps1

IF (Test-Path $OutputFile) {
	CollectFiles -filesToCollect $OutputFile -fileDescription "Hierarchy Details" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	AddTo-CMServerSummary -Name "Hierarchy Details" -Value ("Review $TempFileName") -NoToSummaryReport
	Remove-Item $OutputFile -Force
}

<#
$CommandLineToExecute = $Env:windir + "\system32\cscript.exe GetCM12Hierarchy.VBS"
If (($RemoteStatus -eq 0) -or ($RemoteStatus -eq 1)) {
	# Local Execution
	If ($null -eq $global:DatabaseConnectionError) {
		RunCmD -commandToRun $CommandLineToExecute -sectionDescription $sectiondescription -filesToCollect $OutputFile -fileDescription "Hierarchy Details" -noFileExtensionsOnDescription
		AddTo-CMServerSummary -Name "Hierarchy Details" -Value ("Review $TempFileName") -NoToSummaryReport
		Remove-Item $OutputFile -Force
	}
	Else {
		AddTo-CMServerSummary -Name "Hierarchy Details" -Value $DatabaseConnectionError -NoToSummaryReport
	}
}
#>

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ServerInfo -Status $ScriptStrings.ID_SCCM_CM07ServerInfo_FileVer
TraceOut "    Getting File Versions"

# ---------------------
# Binary Versions List
# ---------------------
$TempFileName = ($ComputerName + "_CMServer_FileVersions.TXT")
$OutputFile = join-path $pwd.path $TempFileName
Get-ChildItem ($SMSInstallDir + "\bin") -recurse -include *.dll,*.exe -ErrorVariable DirError -ErrorAction SilentlyContinue | `
	ForEach-Object {[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_)} | `
	Select-Object FileName, FileVersion, ProductVersion | Format-Table -AutoSize | `
	Out-File $OutputFile -Width 1000
If ($DirError.Count -eq 0) {
	CollectFiles -filesToCollect $OutputFile -fileDescription "Server File Versions" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
	AddTo-CMServerSummary -Name "File Versions" -Value ("Review $TempFileName") -NoToSummaryReport
}
else {
	AddTo-CMServerSummary -Name "File Versions" -Value ("ERROR: " + $DirError[0].Exception.Message) -NoToSummaryReport
	$DirError.Clear()
}

# --------------------
# RCM Inbox File List
# --------------------
TraceOut "    Getting File List for RCM.box"
$TempFileName = ($ComputerName + "_CMServer_RCMFileList.TXT")
$OutputFile = join-path $pwd.path $TempFileName
Get-ChildItem ($SMSInstallDir + "\inboxes\RCM.box") -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
	Select-Object CreationTime, LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
	Out-File $OutputFile -Width 1000
If ($DirError.Count -eq 0) {
	AddTo-CMServerSummary -Name "RCM.box File List" -Value ("Review $TempFileName") -NoToSummaryReport
	CollectFiles -filesToCollect $OutputFile -fileDescription "RCM.box File List" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
}
else {
	AddTo-CMServerSummary -Name "RCM.box File List" -Value ("ERROR: " + $DirError[0].Exception.Message) -NoToSummaryReport
	$DirError.Clear()
}

# Server Info File is collected in DC_CM12SQLInfo.ps1. Need to make sure this script runs before that.
# $ServerInfo | Out-File $ServerInfoFile -Append -Width 200

TraceOut "Completed"


# SIG # Begin signature block
# MIIoLAYJKoZIhvcNAQcCoIIoHTCCKBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBuLz0GycFAQ7KQ
# LfpRFMTYdSduKXDIMT/Km56vXh0X9aCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAANOtTx6wYRv6ysAAAAAA04wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINN2r62K9efzFqmqClW8HZZ4
# EiEUDo7jgH7RuqUeykhVMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCxkH5fHm4guNi6zEhxE3p5If/lVGVcKgbl7xqsXgzWA2CQWJV2YGK9
# T5B6YEU0brUak9xHSUFelbzdlLpZ40zRYZGvF5RE5vDkLgnqsoilQBHEDbFzFf51
# MNRF4P+IYMxBKz7ueeyTztSzc0sc6ybRYuAKgqPTOzf9Fn+k1+R95yaV+1H6C6CR
# T3fZlfEmN/5cERxPefMg0bN5jp9Fh5qrZaWbFeLPnbaUgb748I07RJmiC1mgM3by
# 3UVq1zZSGu9Knv5oS84RBTt+Y1nx725z9VKFuyMJzVheEjbmcBe6CJmi7HMvI3/j
# fpMdqZJlWB57B6yXrl32Up4kC4Tg5rQNoYIXlDCCF5AGCisGAQQBgjcDAwExgheA
# MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglghkgBZQMEAgEFADCCAVIG
# CyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIPIys/8fa03Ruv4hcsZ/XTi2Ui3byZlx5h953vqVnL8JAgZlKJ4Y
# L0gYEzIwMjMxMDIwMTQyNTA1LjA3NVowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjozNzAz
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCEeowggcgMIIFCKADAgECAhMzAAAB1OTpAy/ArGmsAAEAAAHUMA0GCSqGSIb3
# DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMDUyNTE5
# MTIyN1oXDTI0MDIwMTE5MTIyN1owgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlv
# bnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjozNzAzLTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAJhT3i2bAiSXfndJZ6PXJtZxIBu7wUvBMS06/De5
# cylrUOcNcPBu2Qtz6hPwE22Ly37fxPCS1+CgAz038E4fJPgKlcHUfCfVhii+5i6O
# hBX2SbJToPpC21Mgo3t9lOOg20iEjkIGTBL4yTALB1o3LJK+PA+9m7EfxE1w44Hw
# AEOEkf6/D+N6/4bbQcTQbBp3fbfHi4Di0uQTR73JoPvH+zUXeW3s2LjukkwYwupl
# AIrtQJR5Zq5YX3Bkg1Djn21I8h7/Erq20vJgfN3cN5FEvFA//tzug8k8MWClsYHY
# dEloTSm5FEOiIM/sknFiv5METGEja6VlZuAvgJ9ZrDBvUuwmYVYkduoavqjSKtbs
# ioOR/aoRsxFPVZQzXkXmgFzkuDXyVvexRbuRE+8rCZ9pEGSuaKXQf+2/cdjIToDj
# 3RkURw+Tp3NgAp8J7e8qlFUTh0+gMpWcItRMuSrV/+me4P9kYcnZxu4h6v26ZBi7
# 8XPUMGt4LwJGzfMmbjwchLett4tRi78L3eNUgk6WsoC/+qZhHKaMOal/Nm9+8YEZ
# Rs6nH7ih/CoFMu6EB87sVnPffw22yMPOreyJHRw/vin1S41fVOnPgpkszwaXNkuN
# 7dod8Pea6Ws8gyKmdWoGSRjXZrayWxsiWN7e6rwFKuPvbn/AcK3gfJdbhaBMY+LP
# ITFNAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUPNqMx3C0BnoSgHkd51yyu7QMdkkw
# HwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
# UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAw
# XjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8E
# BAMCB4AwDQYJKoZIhvcNAQELBQADggIBALTFQ8/7K3CS11GFiVn0GTj9svMs7Or7
# BwLtUBpFAcZFL4g/JT/w4uJWhdyjIooqJFDsr1z3Q50z6ovg+LMqdK0sMGxZP52z
# WFrI2RPCeFVxl4DUQYqU1m92VOwJTEnkLvKhlCYD7aWmTTg8aNwWEfWAZGmHP61w
# M0r8K0on4+sS42PuyCYGin8kVBxjKaI/++v5252spB5K1xNX1bXdybYUPkX9dY7f
# tOL4bhODUGRTblED63xEJbL8ge6DeutjOpRx1VGrtSBGXjRgiRM2e5yjqfLu8QGZ
# YWNyvtKS+j9Ba547w0C8/Zkp/dAx+J2YfXG/HH2H3BVTqu8RD89QmLemiliytAq6
# iCmF0+odnmP06hD4SMAJR+AmUeefwZVs9bfEamUKRdvIQeF5A139rdf/bOlLARE4
# 5zLVhp5Cq5+UaKUB/TLjQAUqpbZDXJNvX1xFcGlHNtlU75FdQHgDpQvUTVeO3Ov9
# v2rP1ThQ1XzDLxi//TtuneEAV/EHiafRz4875gW/ZixW9gBNUjaXAv1ANIS3wXRF
# bot6TE9+9uSZVJHA/ql/kBR+Sqigprql+pMKd2kZPvUfKKW16VoyFFSw1WRorMAm
# tSgRJKPuxM/VkaJL0mAj6ncA7l+cyG3eYscyDrwazNIfhbLe9QMmmNRNgu1pNaRC
# 3PpSpk83tZeGMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
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
# AC0zXZaOjbHEDmx27MH/cd3NmaJIoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDo3P9RMCIYDzIwMjMxMDIwMTMy
# OTUzWhgPMjAyMzEwMjExMzI5NTNaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOjc
# /1ECAQAwBwIBAAICR24wBwIBAAICE6QwCgIFAOjeUNECAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEASHbBTxcT6p28TZWNSu/b0FKGpDirV6qCAG0UVYvrzSq+
# x9FbhRvwmf1nTAv3SrpD4PwPkXjeZwaWSA83YuH0NOAqOqHtFdzyNaR4S4IZ1i0P
# qbjLYuhnpsHLgxPXsBeHlaQAhDCK6gI2t0MrOxDHnK9WbeyXP9hLNMexsPTNQJ1y
# K5UFUn0pE0xkpxLVZcaj2I7pnA4fLd+uFxZ7WOw/ubalu2wGOsVjvxnaD9GFj+GC
# DaTo9Ha0a+4hAOKT6YtEpsvFcPmv0+ZH85eMI4LGUnCk2myGjSUQS/l0u3wUikRM
# LD0kSJ/7VB+pv2lsm/YhZhmgFJBnm4LLGk5rmlCSjTGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB1OTpAy/ArGmsAAEAAAHU
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIDny3dV8UM2+bs3s7a7ItIa8hnooBhHmE728Qvpi/qKm
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgzOqH+tgUpc6XO9ZLnEK0+L1p
# T58FSTEiuJenZZM9YjcwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAdTk6QMvwKxprAABAAAB1DAiBCBDtMpQoFLMQ4DB2viomJc1FutU
# GArb2PNLJKHibj5QVzANBgkqhkiG9w0BAQsFAASCAgBXP2wOt2SW5mWaqVxET4RM
# mw+PV360Hoi693w1hYG4KH6mfmXWV6aeoHGhPqlHHW7NcUxSCEezErAjHfl9n4Mi
# 4dbIewDCEYGmiO+VjXVOzdHt5/u994g3gzK40p04BgoGRjZxLMaV9B2IDtyTwVgV
# n0D+LpGh3J33AUGIy4gOm6Y4TGJGHpLz8qkSOJ/hUwZQ/kM/lLPHdumBDFZ0b+/O
# 0RuE+1OWPbMJ5wN86LJUDLiPO2CrGfTY0rFMfAoE0S2Mr6vZwnyg6rqQ3yUGuNt1
# YGjHrtLmsNDAkKB7tiZ1b5FxyTHM9UWhs0xVjLocOfSmjnA/mSxwjIXBsoxxCAXI
# k/IccZ5qDwuXCDtOomQkX62ZFQCCj8nbN8TpEVGj6VmcKn7jS2MPI2nn5tDixUOO
# dYfK/GSSWW1weZUCoUMjmvpegJ+McQWCceJjo5FaXkl65b1KaTb6lQ/sQvFXpBVw
# VtHv6DoRphf8ZaXrU5ndqnHhlNF11q5hzs8mRH1e4KX6inRODkGQo02m6VdDaSdP
# dIHSEhqx2muHUuJx0GZOtOWpUIRb6Wj5a40P/6YKoZpEZrQDcl2ybxt3VW3bPaCg
# Ww6imtscf8MRfHGLoygZHLEGHRzm7xpfidubHefPrpovj/lTQn9wAqbrdUIrqb13
# gTcW0FHs5KCIxqgki7UOVw==
# SIG # End signature block
