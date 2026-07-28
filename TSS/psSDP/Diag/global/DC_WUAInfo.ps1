# ********************************************************************************************
# Version 1.0
# Date: 03-20-2012
# Author: Vinay Pamnani - vinpa@microsoft.com
# Description:
# 		Collects Windows Update Agent Information.
#		1. Gets WUA Service Status and Start Time
#		2. Gets WUA Version
#		3. Gets WUA DLL Versions
#		4. Exports HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate Registry Key
#		5. Exports HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate Registry Key
#		6. Gets Windows Update Log
#		7. Summarizes all data to a text file for better readability.
# ********************************************************************************************

trap [Exception]
{
	WriteTo-ErrorDebugReport -ErrorRecord $_
	continue
}

TraceOut "Started"

Import-LocalizedData -BindingVariable ScriptStrings
$sectiondescription = "Windows Update Agent"

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WUAInfo -Status $ScriptStrings.ID_SCCM_WUAInfo_WUA

$WUAInfo = New-Object PSObject

# Summary File Header
$WUAFile = Join-Path $Pwd.Path ($ComputerName + "__WUA_Summary.txt")
"===========================================" | Out-File $WUAFile
"Windows Update Agent Configuration Summary:" | Out-File $WUAFile -Append
"===========================================" | Out-File $WUAFile -Append

# -------------
# Computer Name
# -------------
Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "Computer Name" -Value $ComputerName

# ----------------------
# Time zone information:
# ----------------------
$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_TimeZone -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "Time Zone" -Value $Temp.Description }
else {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "Time Zone" -Value "Error obtaining value from Win32_TimeZone WMI Class" }

$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "Daylight In Effect" -Value $Temp.DaylightInEffect }
else {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "Daylight In Effect" -Value "Error obtaining value from Win32_ComputerSystem WMI Class" }

# -----------------------
# WUA Service Status
# -----------------------
$Temp = Get-Service | Where-Object {$_.Name -eq 'WuAuServ'} | Select-Object Status
If ($null -ne $Temp) {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Service Status" -Value $Temp.Status
}
Else {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Service Status" -Value "ERROR: Service Not found"
}

# --------------------------
# WUA Service StartTime
# --------------------------
$Temp = Get-Process | Where-Object {($_.ProcessName -eq 'SvcHost') -and ($_.Modules -match 'wuaueng.dll')} | Select-Object StartTime
If ($null -ne $Temp) {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Service StartTime" -Value $Temp.StartTime
}
Else {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Service StartTime" -Value "ERROR: Service Not running"
}

# ------------
# WUA Version
# ------------
trap [Exception]
{
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Version" -Value -Value ("ERROR: " + ($_.Exception.Message))
}
$WUA = New-Object -com "Microsoft.Update.AgentInfo" -ErrorAction SilentlyContinue -ErrorVariable WUAError
If ($WUAError.Count -eq 0) {
	$Temp = $WUA.GetInfo("ProductVersionString")
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Version" -Value $Temp
}

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WUAInfo -Status $ScriptStrings.ID_SCCM_WUAInfo_SoftDist

# --------------------------------------------
# File List in SoftwraeDistribution Directory
# --------------------------------------------
$TempFileName = ($ComputerName + "_WUA_FileList.txt")
$OutputFile = join-path $pwd.path $TempFileName
Get-ChildItem (Join-Path $env:windir "SoftwareDistribution") -Recurse -ErrorVariable DirError -ErrorAction SilentlyContinue | `
	Select-Object CreationTime, LastAccessTime, FullName, Length, Mode | Sort-Object FullName | Format-Table -AutoSize | `
	Out-File $OutputFile -Width 1000
If ($DirError.Count -eq 0) {
	Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "SoftwareDistribution Directory List" -Value "Review $TempFileName"
	CollectFiles -filesToCollect $OutputFile -fileDescription "WUA File List" -sectionDescription $sectiondescription -noFileExtensionsOnDescription
}
else {
	$DirError.Clear()
}

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WUAInfo -Status $ScriptStrings.ID_SCCM_WUAInfo_FileVer

# -----------------
# WUA DLL Versions
# -----------------
$TempFileName = ($ComputerName + "_WUA_FileVersions.txt")
$VersionFile  = Join-Path $Pwd.Path $TempFileName
Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Related File Versions" -Value "Review $TempFileName"
"-----------------------------------" | Out-File $VersionFile -Append
"Windows Update Agent DLL Versions: " | Out-File $VersionFile -Append
"-----------------------------------" | Out-File $VersionFile -Append
Get-ChildItem (Join-Path $Env:windir "system32\wu*.dll") -Exclude WUD*.dll -ErrorAction SilentlyContinue | `
	foreach-object {[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_)} | `
	Select-Object FileName,FileVersion,ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
	Out-File $VersionFile -Append -Width 1000

# ------------------
# BITS DLL Versions
# ------------------
"-------------------" | Out-File $VersionFile -Append
"BITS DLL Versions: " | Out-File $VersionFile -Append
"-------------------" | Out-File $VersionFile -Append
Get-ChildItem (Join-Path $Env:windir "system32\bits*.dll"), (Join-Path $Env:windir "system32\winhttp*.dll"), (Join-Path $Env:windir "system32\qmgr*.dll") -ErrorAction SilentlyContinue | `
	foreach-object {[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_)} | `
	Select-Object FileName,FileVersion,ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
	Out-File $VersionFile -Append -Width 1000

# -----------------
# MSI DLL Versions
# -----------------
"--------------------------------" | Out-File $VersionFile -Append
"Windows Installer DLL Versions: " | Out-File $VersionFile -Append
"--------------------------------" | Out-File $VersionFile -Append
Get-ChildItem (Join-Path $Env:windir "system32\msi*.*") -ErrorAction SilentlyContinue | `
	foreach-object {[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_)} | `
	Select-Object FileName,FileVersion,ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
	Out-File $VersionFile -Append -Width 1000

# -----------------
# MSXML DLL Versions
# -----------------
"--------------------" | Out-File $VersionFile -Append
"MSXML DLL Versions: " | Out-File $VersionFile -Append
"--------------------" | Out-File $VersionFile -Append
Get-ChildItem (Join-Path $Env:windir "system32\msxml*.dll") -ErrorAction SilentlyContinue | `
	foreach-object {[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_)} | `
	Select-Object FileName,FileVersion,ProductVersion | Format-Table -AutoSize -HideTableHeaders | `
	Out-File $VersionFile -Append -Width 1000

CollectFiles -filesToCollect $VersionFile -fileDescription "WUA File Versions"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_WUAInfo -Status $ScriptStrings.ID_SCCM_WUAInfo_SecDesc

# ---------------------
# Security Descriptors
# ---------------------
$TempFileName = ($ComputerName + "_WUA_SecurityDesc.txt")
$SDFile  = Join-Path $Pwd.Path $TempFileName
Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUA Related Security Descriptors" -Value "Review $TempFileName"
"----------------------------------------------" | Out-File $SDFile -Append
"Security Descriptors for WU Related Services: " | Out-File $SDFile -Append
"----------------------------------------------" | Out-File $SDFile -Append
"" | Out-File $SDFile -Append
"WUAUServ: " | Out-File $SDFile -Append
$CmdToRun = "cmd /c sc sdshow wuauserv >> $SDFile"
RunCmd -commandToRun $CmdToRun -collectFiles $false
"" | Out-File $SDFile -Append
"BITS: " | Out-File $SDFile -Append
$CmdToRun = "cmd /c sc sdshow bits >> $SDFile"
RunCmd -commandToRun $CmdToRun -collectFiles $false
"" | Out-File $SDFile -Append
"Windows Installer: " | Out-File $SDFile -Append
$CmdToRun = "cmd /c sc sdshow msiserver >> $SDFile"
RunCmd -commandToRun $CmdToRun -collectFiles $false
"" | Out-File $SDFile -Append
"Task Scheduler: " | Out-File $SDFile -Append
$CmdToRun = "cmd /c sc sdshow Schedule >> $SDFile"
RunCmd -commandToRun $CmdToRun -collectFiles $false

CollectFiles -filesToCollect $SDFile -fileDescription "WUA Security Descriptors"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# ---------------------------
# Collect WU Registry keys
# ---------------------------
$TempFileName = $ComputerName + "_Reg_WU.txt"
$RegFileWU = Join-Path $Pwd.Path $TempFileName

$TempKey = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Export-RegKey -RegKey $TempKey -outFile $RegFileWU -fileDescription "WU Registry Key" -collectFiles $false

$TempKey = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate"
Export-RegKey -RegKey $TempKey -outFile $RegFileWU -fileDescription "WU Registry Key" -collectFiles $false

Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WU Registry Keys" -Value "Review $TempFileName"
CollectFiles -filesToCollect $RegFileWU -fileDescription "WU Registry Keys"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# ---------------------------
# Collect WUFB Registry keys
# ---------------------------
$TempFileName = $ComputerName + "_Reg_WUFB.txt"
$RegFileWUFB = Join-Path $Pwd.Path $TempFileName

$TempKey = "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX"
Export-RegKey -RegKey $TempKey -outFile $RegFileWUFB -fileDescription "WUFB Registry Keys" -collectFiles $false

$TempKey = "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy"
Export-RegKey -RegKey $TempKey -outFile $RegFileWUFB -fileDescription "WUFB Registry Keys" -collectFiles $false

$TempKey = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Export-RegKey -RegKey $TempKey -outFile $RegFileWUFB -fileDescription "WUFB Registry Keys" -collectFiles $false

$TempKey = "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Update"
Export-RegKey -RegKey $TempKey -outFile $RegFileWUFB -fileDescription "WUFB Registry Keys" -collectFiles $false

Add-Member -InputObject $WUAInfo -MemberType NoteProperty -Name "WUFB Registry Keys" -Value "Review $TempFileName"
CollectFiles -filesToCollect $RegFileWUFB -fileDescription "WUFB Registry Keys"  -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# ----------------------------------------
# Output WUAInfo PSObject to Summary File
# ----------------------------------------
$WUAInfo | Out-File $WUAFile -Append -Width 500

# --------------------
# Collect WUA Summary
# --------------------
CollectFiles -filesToCollect $WUAFile -fileDescription "WUA Summary"  -sectionDescription $global:SummarySectionDescription -noFileExtensionsOnDescription

TraceOut "Completed"

# SIG # Begin signature block
# MIInwQYJKoZIhvcNAQcCoIInsjCCJ64CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC7SJZjsvZ/QpOD
# H7Vsg2aQpY3srzQxqnhlDSBnCxPnmKCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGaEwghmdAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAANOtTx6wYRv6ysAAAAAA04wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPXW8IuIcoti/T5otyDDuqWU
# urPRf/u+M32LZnS/o3ppMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQAtV23WmjKC9PegPNkwW4Pvy/YvhCVvdVw1zekPbr5ce7lMs+kohoS0
# aitKM2USyckoPcIs+H9Ff1RMVGZAbRBLHy5IV5V/rcpNy/USd8RIcol6BraKpOlU
# HdnfE0Ymi8Zw3dE6vUnkYZ3ehkxPlkzEqlInCvJh8zPjWn1I3XhAG0Kje7QCBb5e
# KSXc0C0is3K448r19CcndX3hcp7g8ejywp2NAiJEWrtwYu4qPaD7p5Y4qoMqA3gK
# IU/MOI4tDNB4wUrcm8myW53kn2iQNWe4i0qDfTXseRHatw8MOXBSEFs22Q1obge9
# h14x1z0HnVEH0DX13D0oFjLr5GIQQGbDoYIXKTCCFyUGCisGAQQBgjcDAwExghcV
# MIIXEQYJKoZIhvcNAQcCoIIXAjCCFv4CAQMxDzANBglghkgBZQMEAgEFADCCAVkG
# CyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIM8dwkc10v1kS2sF3693/hKFsPF1Gocvz4/v3tPjLgrTAgZk3l48
# IVcYEzIwMjMwODMwMDkxNTEwLjg2NlowBIACAfSggdikgdUwgdIxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJ
# cmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBF
# U046OEQ0MS00QkY3LUIzQjcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFNlcnZpY2WgghF4MIIHJzCCBQ+gAwIBAgITMwAAAbP+Jc4pGxuKHAABAAABszAN
# BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0y
# MjA5MjAyMDIyMDNaFw0yMzEyMTQyMDIyMDNaMIHSMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBP
# cGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjhENDEt
# NEJGNy1CM0I3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtHwPuuYYgK4ssGCCsr2N
# 7eElKlz0JPButr/gpvZ67kNlHqgKAW0JuKAy4xxjfVCUev/eS5aEcnTmfj63fvs8
# eid0MNvP91T6r819dIqvWnBTY4vKVjSzDnfVVnWxYB3IPYRAITNN0sPgolsLrCYA
# KieIkECq+EPJfEnQ26+WTvit1US+uJuwNnHMKVYRri/rYQ2P8fKIJRfcxkadj8CE
# PJrN+lyENag/pwmA0JJeYdX1ewmBcniX4BgCBqoC83w34Sk37RMSsKAU5/BlXbVy
# Du+B6c5XjyCYb8Qx/Qu9EB6KvE9S76M0HclIVtbVZTxnnGwsSg2V7fmJx0RP4bfA
# M2ZxJeVBizi33ghZHnjX4+xROSrSSZ0/j/U7gYPnhmwnl5SctprBc7HFPV+BtZv1
# VGDVnhqylam4vmAXAdrxQ0xHGwp9+ivqqtdVVDU50k5LUmV6+GlmWyxIJUOh0xzf
# Qjd9Z7OfLq006h+l9o+u3AnS6RdwsPXJP7z27i5AH+upQronsemQ27R9HkznEa05
# yH2fKdw71qWivEN+IR1vrN6q0J9xujjq77+t+yyVwZK4kXOXAQ2dT69D4knqMlFS
# sH6avnXNZQyJZMsNWaEt3rr/8Nr9gGMDQGLSFxi479Zy19aT/fHzsAtu2ocBuTqL
# VwnxrZyiJ66P70EBJKO5eQECAwEAAaOCAUkwggFFMB0GA1UdDgQWBBTQGl3CUWdS
# DBiLOEgh/14F3J/DjTAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAWoa7N86wCbjA
# Al8RGYmBZbS00ss+TpViPnf6EGZQgKyoaCP2hc01q2AKr6Me3TcSJPNWHG14pY4u
# hMzHf1wJxQmAM5Agf4aO7KNhVV04Jr0XHqUjr3T84FkWXPYMO4ulQG6j/+/d7gqe
# zjXaY7cDqYNCSd3F4lKx0FJuQqpxwHtML+a4U6HODf2Z+KMYgJzWRnOIkT/od0oI
# Xyn36+zXIZRHm7OQij7ryr+fmQ23feF1pDbfhUSHTA9IT50KCkpGp/GBiwFP/m1d
# rd7xNfImVWgb2PBcGsqdJBvj6TX2MdUHfBVR+We4A0lEj1rNbCpgUoNtlaR9Dy2k
# 2gV8ooVEdtaiZyh0/VtWfuQpZQJMDxgbZGVMG2+uzcKpjeYANMlSKDhyQ38wboAi
# vxD4AKYoESbg4Wk5xkxfRzFqyil2DEz1pJ0G6xol9nci2Xe8LkLdET3u5RGxUHam
# 8L4KeMW238+RjvWX1RMfNQI774ziFIZLOR+77IGFcwZ4FmoteX1x9+Bg9ydEWNBP
# 3sZv9uDiywsgW40k00Am5v4i/GGiZGu1a4HhI33fmgx+8blwR5nt7JikFngNuS83
# jhm8RHQQdFqQvbFvWuuyPtzwj5q4SpjO1SkOe6roHGkEhQCUXdQMnRIwbnGpb/2E
# sxadokK8h6sRZMWbriO2ECLQEMzCcLAwggdxMIIFWaADAgECAhMzAAAAFcXna54C
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
# ahC0HVUzWLOhcGbyoYIC1DCCAj0CAQEwggEAoYHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OjhENDEtNEJGNy1CM0I3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQBxi0Tolt0eEqXCQl4qgJXUkiQOYaCBgzCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUA
# AgUA6JlVSTAiGA8yMDIzMDgzMDEzNDIzM1oYDzIwMjMwODMxMTM0MjMzWjB0MDoG
# CisGAQQBhFkKBAExLDAqMAoCBQDomVVJAgEAMAcCAQACAgaBMAcCAQACAhI9MAoC
# BQDomqbJAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEA
# AgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEALpj9jGko+iKJAs1V
# dLQGpnGKqPQ5EZukJZyTxWFWh4CW8xgCXqwL52r4g+l7zw370tkAzhQ02/RzE6Fp
# 4Tz2lXRdvh8n/9DEDlbuT+SqnMQKKGWBInhc7k64zi/i2FSa6buyS6QxdWzlOU4R
# IS5IzsgFw39OA8JytKgvFyOc4GIxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAbP+Jc4pGxuKHAABAAABszANBglghkgBZQME
# AgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJ
# BDEiBCC7F4+o4uoEPWNguLcwrr1Y6Fh3wVFxbdAOgyKEyx9kejCB+gYLKoZIhvcN
# AQkQAi8xgeowgecwgeQwgb0EIIahM9UqENIHtkbTMlBlQzaOT+WXXMkaHoo6Gfvq
# T79CMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGz
# /iXOKRsbihwAAQAAAbMwIgQgGjjbCTETqVZkR66h0szM/VGZ+otnfRJB947bGBJE
# NK0wDQYJKoZIhvcNAQELBQAEggIADIqczz/uitSoD7sLJW9ehmQv+MPqZEq5J/+1
# LvSdtt0Juaemf5j66cKBDAUH5lpBMyb5ZlC+ubPJTQ1btjWO/stZ6fWDFBXVdcR2
# cPIpsex9ylFbmZcyB3xdcWrSQYs0f+ArB2MZMVF+9ioNcOyWy8p6qb1gUnZhSgaH
# GtTgqvMsmXPMBVPMZTA4VEsrJUChM7nn4K3eILPWkHFPT5UCcdlcgEIMt/Hv9QyK
# Ed9D5aGd6xb/vwIf4QLpJR7iO1Zq5AAEA4hJXDuU6QTbgSDPnhb00L9Q+0H0NdWz
# W/wIXvkID2K++N/t5Ocn3hH45kuwywWikxCbZyY2pZs/TB7dXyTb7QAQIVOOadLf
# epTqwg9M6M+l3RkgbAXQoSe+OYfpoIpPwi1UqEINKKgVbiXz3kQjr4O1df6zUHTs
# ipam/vXQBn4NeDQlRfCpUrzOXST+c7xxP9IWzH0xGCzm1EUXvtIeAtVOlemjlDQq
# AGXuV+zu9DSMeFJz95dq/WmfCxXsE/lwpT23jh6pcUwMfyX9EWpGeqi3Tbigy/g5
# ekKNezCDhsxTuP7vgmfXdRR22ThG9BKtusCM7BIiRZOWEXMw0vS12XQ0k2oQKq2h
# wYFUdQ4jyG8TOzbMvOS9ZFphAq6UOF2iE764NUZ+qPdYu2mVsSpijZeQIvvebN31
# 9b2RsNE=
# SIG # End signature block
