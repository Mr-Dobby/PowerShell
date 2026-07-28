trap [Exception]
{
	WriteTo-ErrorDebugReport -ErrorRecord $_
	continue
}

TraceOut "Started"
$sectionDescription = "System Information"

Import-LocalizedData -BindingVariable ScriptStrings

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_GenericInfo -Status $ScriptStrings.ID_SCCM_GenericInfo_OSInfo

# Header for Client Summary File
$OSInfoFile = Join-Path $Pwd.Path ($ComputerName + "__OS_Summary.txt")
"=====================================" | Out-File $OSInfoFile
"Operating System Information Summary:" | Out-File $OSInfoFile -Append
"=====================================" | Out-File $OSInfoFile -Append

# PSObject to store Client information
$OSInfo = New-Object PSObject

TraceOut "    Getting OS information..."

# -------------
# Computer Name
# -------------
Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Computer Name" -Value $ComputerName

# ----------------------
# OS information:
# ----------------------
$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Operating System" -Value $Temp.Caption
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Service Pack" -Value $Temp.CSDVersion
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Version" -Value $Temp.Version
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Architecture" -Value $OSArchitecture
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Last Boot Up Time" -Value $Temp.LastBootUpTime
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Current Time" -Value $Temp.LocalDateTime
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Total Physical Memory" -Value  ([string]([math]::round($($Temp.TotalVisibleMemorySize/1MB), 2)) + " GB")
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Free Physical Memory" -Value  ([string]([math]::round($($Temp.FreePhysicalMemory/1MB), 2)) + " GB")
}
else {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "OS Details" -Value "Error obtaining data from Win32_OperatingSystem WMI Class" }

# ----------------------
# Computer System Information:
# ----------------------
$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_TimeZone -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Time Zone" -Value $Temp.Description }
else {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Time Zone" -Value "Error obtaining value from Win32_TimeZone WMI Class" }

$Temp = Get-CimInstance -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
If ($Temp -is [CimInstance]) {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Daylight In Effect" -Value $Temp.DaylightInEffect
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Domain" -Value $Temp.Domain
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Model" -Value $Temp.Model
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Number of Processors" -Value $Temp.NumberOfProcessors
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Number of Logical Processors" -Value $Temp.NumberOfLogicalProcessors
}
else {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Computer System Details" -Value "Error obtaining value from Win32_ComputerSystem WMI Class" }

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_GenericInfo -Status $ScriptStrings.ID_SCCM_GenericInfo_SysInfo

# --------------------------
# Get SystemInfo.exe output
# --------------------------
$TempFileName = $ComputerName + "_OS_SysInfo.txt"
$SysInfoFile = Join-Path $Pwd.Path $TempFileName
$CmdToRun = "cmd.exe /c SystemInfo.exe /S $ComputerName > $SysInfoFile"
RunCmd -commandToRun $CmdToRun -filesToCollect $SysInfoFile -fileDescription "SysInfo Output"  -sectionDescription $sectionDescription -BackgroundExecution -noFileExtensionsOnDescription
Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "SysInfo Output" -Value "Review $TempFileName"

TraceOut "    Getting Processes and Services..."

# -----------------------
# Get Running Tasks List
# -----------------------
$TempFileName = $ComputerName + "_OS_TaskList.txt"
$TaskListFile = Join-Path $Pwd.Path $TempFileName
$CmdToRun = "cmd.exe /c TaskList.exe /v /FO TABLE /S $ComputerName > $TaskListFile"
RunCmd -commandToRun $CmdToRun -filesToCollect $TaskListFile -fileDescription "Running Tasks List"  -sectionDescription $sectionDescription -noFileExtensionsOnDescription
Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Running Tasks List" -Value "Review $TempFileName"

# ----------------
# Services Status
#-----------------
$TempFileName = $ComputerName + "_OS_Services.txt"
$ServicesFile = Join-Path $Pwd.Path $TempFileName
$Temp = Get-CimInstance Win32_Service -ErrorVariable WMIError -ErrorAction SilentlyContinue  | Select-Object DisplayName, Name, State, @{name="Log on As";expression={$_.StartName}}, StartMode | `
			Sort-Object DisplayName | `
			Format-Table -AutoSize
If ($WMIError.Count -eq 0) {
	$Temp | Out-File $ServicesFile -Width 1000
	CollectFiles -filesToCollect $ServicesFile -fileDescription "Services Status" -sectionDescription $sectionDescription -noFileExtensionsOnDescription
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Services Status" -Value "Review $TempFileName"
}
Else {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Services Status" -Value "Error obtaining Services Status: $WMIError[0].Exception.Message"
	$WMIError.Clear()
}

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_GenericInfo -Status $ScriptStrings.ID_SCCM_GenericInfo_MSInfo

# ------------------
# Get MSInfo output
# ------------------
$TempFileName = $ComputerName + "_OS_MSInfo.NFO"
$MSInfoFile = Join-Path $Pwd.Path $TempFileName
$CmdToRun = "cmd.exe /c start /wait MSInfo32.exe /nfo $MSInfoFile /computer $ComputerName"
RunCmd -commandToRun $CmdToRun -filesToCollect $MSInfoFile -fileDescription "MSInfo Output"  -sectionDescription $sectionDescription -BackgroundExecution
Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "MSInfo Output" -Value "Review $TempFileName"

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_GenericInfo -Status $ScriptStrings.ID_SCCM_GenericInfo_RSoP

# --------------------
# Get GPResult Output
# --------------------
TraceOut "    Getting GPResult..."
$CommandToExecute = "$Env:windir\system32\cmd.exe"

$OutputFileZ = $ComputerName + "_OS_GPResult.txt"
$Arg =  "/c $Env:windir\system32\gpresult.exe /Z > `"" + $PWD.Path + "\$OutputFileZ`""
Runcmd -fileDescription "GPResult /Z output" -commandToRun ($CommandToExecute + " " + $Arg) -filesToCollect $OutputFileZ -sectionDescription $sectionDescription -noFileExtensionsOnDescription
Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "GPResult /Z Output" -Value "Review $OutputFileZ"

If ($OSVersion.Major -ge 6) {
	$OutputFileH = $ComputerName + "_OS_GPResult.htm"
	$Arg =  "/c $Env:windir\system32\gpresult.exe /H `"" + $PWD.Path + "\$OutputFileH`" /F"
	Runcmd -fileDescription "GPResult /H output" -commandToRun ($CommandToExecute + " " + $Arg) -filesToCollect $OutputFileH -sectionDescription $sectionDescription -noFileExtensionsOnDescription
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "GPResult /H Output" -Value "Review $OutputFileH"
}

# ----------------
# Write Progress
# ----------------
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_GenericInfo -Status $ScriptStrings.ID_SCCM_GenericInfo_EnvVar

# ----------------------
# Environment Variables
# ----------------------
TraceOut "    Getting environment variables..."
$TempFileName = $ComputerName + "_OS_EnvironmentVariables.txt"
$OutputFile = join-path $pwd.path $TempFileName
"-----------------" | Out-File $OutputFile
"SYSTEM VARIABLES" | Out-File $OutputFile -Append
"-----------------" | Out-File $OutputFile -Append
 [environment]::GetEnvironmentVariables("Machine") | Out-File $OutputFile -Append -Width 250
"" | Out-File $OutputFile -Append
"-----------------" | Out-File $OutputFile -Append
"USER VARIABLES" | Out-File $OutputFile -Append
"-----------------" | Out-File $OutputFile -Append
 [environment]::GetEnvironmentVariables("User") | Out-File $OutputFile -Append -Width 250
 CollectFiles -filesToCollect $OutputFile -fileDescription "Environment Variables"  -sectionDescription $sectionDescription -noFileExtensionsOnDescription
 Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Environment Variables" -Value "Review $TempFileName"

# ----------------------
# Pending Reboot
# ----------------------
TraceOut "    Determining if reboot is pending..."
$TempFileName = $ComputerName + "_OS_RebootPending.txt"
$OutputFile = join-path $pwd.path $TempFileName
Get-PendingReboot -ComputerName $ComputerName | Out-File $OutputFile
CollectFiles -filesToCollect $OutputFile -fileDescription "Reboot Pending"  -sectionDescription $sectionDescription -noFileExtensionsOnDescription
Add-Member -InputObject $OSInfoFile -MemberType NoteProperty -Name "Reboot Pending" -Value "Review $TempFileName"

# ---------------------------------
# Get event logs
# ---------------------------------
TraceOut "    Getting Event Logs..."
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_GenericInfo -Status ($ScriptStrings.ID_SCCM_GenericInfo_EventLog)

$ZipName = $ComputerName + "_OS_EventLogs.zip"
$Destination = Join-Path $Env:windir ("\Temp\" + $ComputerName + "_OS_EventLogs")
$fileDescription = "Event Logs"

If (Test-Path $Destination) {
	Remove-Item -Path $Destination -Recurse -Force
}
New-Item -ItemType "Directory" $Destination | Out-Null #_#

# Copy files directly, it's much much faster this way. User can convert to TXT or CSV offline, as needed.
$TempLogPath = Join-Path $Env:windir "system32\winevt\logs"
Copy-Files -Source $TempLogPath -Destination $Destination -Filter Application.evtx
Copy-Files -Source $TempLogPath -Destination $Destination -Filter System.evtx
Copy-Files -Source $TempLogPath -Destination $Destination -Filter Security.evtx
Copy-Files -Source $TempLogPath -Destination $Destination -Filter Setup.evtx

compressCollectFiles -DestinationFileName $ZipName -filesToCollect ($Destination + "\*.*") -sectionDescription $sectionDescription -fileDescription $fileDescription -Recursive -ForegroundProcess -noFileExtensionsOnDescription
Remove-Item -Path $Destination -Recurse -Force

# --------------------------------
# Get WMI Provider Configuration
# --------------------------------
TraceOut "    Getting WMI Configuration..."
$TempFileName = $ComputerName + "_OS_WMIProviderConfig.txt"
$OutputFile = join-path $pwd.path $TempFileName
$Temp1 = Get-CimInstance -Namespace root -Class __ProviderHostQuotaConfiguration -ErrorAction SilentlyContinue
If ($Temp1 -is [CimInstance]) {
	TraceOut "      Connected to __ProviderHostQuotaConfiguration..."
	"------------------------" | Out-File $OutputFile
	"WMI Quota Configuration " | Out-File $OutputFile -Append
	"------------------------" | Out-File $OutputFile -Append
	$Temp1 | Select-Object MemoryPerHost, MemoryAllHosts, ThreadsPerHost, HandlesPerHost, ProcessLimitAllHosts | Out-File $OutputFile -Append
}

$Temp2 = Get-CimInstance -Namespace root\cimv2 -Class MSFT_Providers -ErrorAction SilentlyContinue
if (($Temp2 | Measure-Object).Count -gt 0) {
	TraceOut "      Connected to MSFT_Providers..."
	"------------------------" | Out-File $OutputFile -Append
	"WMI Providers " | Out-File $OutputFile -Append
	"------------------------`r`n" | Out-File $OutputFile -Append
	foreach($provider in $Temp2) {
		"Process ID $($provider.HostProcessIdentifier)" | Out-File $OutputFile -Append
		"  - Used by Provider $($provider.provider)" | Out-File $OutputFile -Append
		"  - Associated with Namespace $($provider.Namespace)" | Out-File $OutputFile -Append

		if (-not [string]::IsNullOrEmpty($provider.User)) {
			"  - By User $($provider.User)" | Out-File $OutputFile -Append
		}

		if (-not [string]::IsNullOrEmpty($provider.HostingGroup)) {
			"  - Under Hosting Group $($provider.HostingGroup)" | Out-File $OutputFile -Append
		}

		"" | Out-File $OutputFile -Append
	}
}

if ($Temp1 -is [CimInstance] -or $Temp2 -is [CimInstance]) {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "WMI Provider Config" -Value "Review $TempFileName"
	CollectFiles -filesToCollect $OutputFile -fileDescription "WMI Provider Config" -sectionDescription $sectiondescription -noFileExtensionsOnDescription }
else {
	Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "WMI Provider Config" -Value "Error obtaining data from WMI" }

# --------------------------------
# Collect Certificate Information
# --------------------------------
TraceOut "    Getting Certificates..."
$TempFileName = ($ComputerName + "_OS_Certificates.txt")
$OutputFile = join-path $pwd.path $TempFileName

"##############" | Out-File $OutputFile
"## COMPUTER ##" | Out-File $OutputFile -Append
"##############`r`n`r`n" | Out-File $OutputFile -Append

"MY" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\LocalMachine\My | Out-File $OutputFile -Append

"SMS" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\LocalMachine\SMS | Out-File $OutputFile -Append

"Trusted People" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\LocalMachine\TrustedPeople | Out-File $OutputFile -Append

"Trusted Publishers" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\LocalMachine\TrustedPublisher | Out-File $OutputFile -Append

"Trusted Root CA's" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\LocalMachine\Root | Out-File $OutputFile -Append

"##############" | Out-File $OutputFile -Append
"##   USER   ##" | Out-File $OutputFile -Append
"##############`r`n`r`n" | Out-File $OutputFile -Append

"MY" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\CurrentUser\My | Out-File $OutputFile -Append

"Trusted People" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\CurrentUser\TrustedPeople | Out-File $OutputFile -Append

"Trusted Publishers" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\CurrentUser\TrustedPublisher | Out-File $OutputFile -Append

"Trusted Root CA's" | Out-File $OutputFile -Append
"==================" | Out-File $OutputFile -Append
Get-CertInfo Cert:\CurrentUser\Root | Out-File $OutputFile -Append

Add-Member -InputObject $OSInfo -MemberType NoteProperty -Name "Certificates" -Value "Review $TempFileName"
CollectFiles -filesToCollect $OutputFile -fileDescription "Certificates" -sectionDescription $sectiondescription -noFileExtensionsOnDescription

# ---------------------------
# Collect OS Information
# ---------------------------
$OSInfo | Out-File $OSInfoFile -Append -Width 500
CollectFiles -filesToCollect $OSInfoFile -fileDescription "OS Summary"  -sectionDescription $global:SummarySectionDescription -noFileExtensionsOnDescription

TraceOut "Completed"


# SIG # Begin signature block
# MIInxAYJKoZIhvcNAQcCoIIntTCCJ7ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB5kFiExdhlDPQs
# X57wgYtkX3V3WtpfXsg0z8fWqD+yFaCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP/JI58ttoadHZaSCe4Y8gmR
# T37ueaw6GbCWm+knhIoQMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCALNitAUgejlSAtLjP71ti9dZLeNxM4sYpWAZbIk7yV/GrHkyjWLQ3
# ytO113Oe/vw4p++gM3SZS+rMP/d40x7AMVPrk7ho9voPQbnfGKQ++ZLt6ThSk+XM
# L3uzrb/7TG6N2q0Vt9cMU23KPpZzU/PCIHrDpvGLUfbw0/srCO4fAwxHvj06b682
# dwa6vj53ytCMbQ7wtE9H8qQV0FDbg5unNvlve35ssRS/EX+0aYHAq6CXpdTj6aQc
# 2nxnJZFFISJx+RCvmGWb8pIgSS2DsDzHvPI9rJKBRBMEQjjWUbWNJKRQnm/9uczT
# LirjuCt9FvgNvnSSvaVqaABPAD9uHF/roYIXLDCCFygGCisGAQQBgjcDAwExghcY
# MIIXFAYJKoZIhvcNAQcCoIIXBTCCFwECAQMxDzANBglghkgBZQMEAgEFADCCAVkG
# CyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIIy56peEXNSpfWiDo/kH/xniA3HwHVe1jgzJAimhgpogAgZkkwUS
# iToYEzIwMjMwNzEwMDc0MDEzLjM5NFowBIACAfSggdikgdUwgdIxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJ
# cmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBF
# U046M0JENC00QjgwLTY5QzMxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFNlcnZpY2WgghF7MIIHJzCCBQ+gAwIBAgITMwAAAbT7gAhEBdIt+gABAAABtDAN
# BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0y
# MjA5MjAyMDIyMDlaFw0yMzEyMTQyMDIyMDlaMIHSMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBP
# cGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjNCRDQt
# NEI4MC02OUMzMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtEemnmUHMkIfvOiu27K8
# 6ZbwWhksGwV72Dl1uGdqr2pKm+mfzoT+Yngkq9aLEf+XDtADyA+2KIZU0iO8WG79
# eJjzz29flZpBKbKg8xl2P3O9drleuQw3TnNfNN4+QIgjMXpE3txPF7M7IRLKZMiO
# t3FfkFWVmiXJAA7E3OIwJgphg09th3Tvzp8MT8+HOtG3bdrRd/y2u8VrQsQTLZiV
# wTZ6qDYKNT8PQZl7xFrSSO3QzXa91LipZnYOl3siGJDCee1Ba7X1i13dQFHxKl5F
# f4JzDduOBZ85e2VrpyFy1a3ayGUzBrIw59jhMbjIw9YVcQt9kUWntyCmNk15WybC
# S+hXpEDDLVj1X5W9snmoW1qu03+unprQjWQaVuO7BfcvQdNVdyKSqAeKy1eT2Hcc
# 5n1aAVeXFm6sbVJmZzPQEQR3Jr7W8YcTjkqC5hT2qrYuIcYGOf3Pj4OqdXm1Qqhu
# wtskxviv7yy3Z+PxJpxKx+2e6zGRaoQmIlLfg/a42XNVHTf6Wzr5k7Q1w7v0uA/s
# FsgyKmI7HzKHX08xDDSmJooXA5btD6B0lx/Lqs6Qb4KthnA7N2IEdJ5sjMIhyHZw
# Br7fzDskU/+Sgp2UnfqrN1Vda/gb+pmlbJwi8MphvElYzjT7PZK2Dm4eorcjx7T2
# QVe3EIelLuGbxzybblZoRTkCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBTLRIXl8ZS4
# Opy7Eii3Tt44zDLZfjAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAEtEPBYwpt4Ji
# oSq0joGzwqYX6SoNH7YbqpgArdlnrdt6u3ukKREluKEVqS2XajXxx0UkXGc4Xi9d
# p2bSxpuyQnTkq+IQwkg7p1dKrwAa2vdmaNzz3mrSaeUEu40yCThHwquQkweoG4eq
# RRZe19OtVSmDDNC3ZQ6Ig0qz79vivXgy5dFWk4npxA5LxSGR4wBaXaIuVhoEa06v
# d/9/2YsQ99bCiR7SxJRt1XrQ5kJGHUi0Fhgz158qvXgfmq7qNqfqfTSmsQRrtbe4
# Zv/X+qPo/l6ae+SrLkcjRfr0ONV0vFVuNKx6Cb90D5LgNpc9x8V/qIHEr+JXbWXW
# 6mARVVqNQCmXlVHjTBjhcXwSmadR1OotcN/sKp2EOM9JPYr86O9Y/JAZC9zug9ql
# jKTroZTfYA7LIdcmPr69u1FSD/6ivL6HRHZd/k2EL7FtZwzNcRRdFF/VgpkOxHIf
# qvjXambwoMoT+vtGTtqgoruhhSk0bM1F/pBpi/nPZtVNLGTNaK8Wt6kscbC9G6f0
# 9gz/wBBJOBmvTLPOOT/3taCGSoJoDABWnK+De5pie4KX8BxxKQbJvxz7vRsVJ5R6
# mGx+Bvav5AjsxvZZw6eQmkI0vPRckxL9TCVCfWS0uyIKmyo6TdosnbBO/osre7r0
# jS9AH8spEqVlhFcpQNfOg/CvdS2xNVMwggdxMIIFWaADAgECAhMzAAAAFcXna54C
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
# OjNCRDQtNEI4MC02OUMzMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQBlnNiQ85uX9nN4KRJt/gHkJx4JCKCBgzCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUA
# AgUA6FXmEDAiGA8yMDIzMDcxMDEwMDYwOFoYDzIwMjMwNzExMTAwNjA4WjB3MD0G
# CisGAQQBhFkKBAExLzAtMAoCBQDoVeYQAgEAMAoCAQACAhaFAgH/MAcCAQACAhFo
# MAoCBQDoVzeQAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAI
# AgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAD/tscjZ6JbaL
# BbknQHyHO3tLthr8TsIGEohW+EZCjiVdKBJN+STBC4LSYzj+EhcKshR0hqtyl/dO
# o7M1nvRL/FFLbkz4vxwdoScUzMcxY4mDF5cw/7mewP3dQribAI0LTyERpGLx6KK/
# /Ri6ZBXjPEZ+EiQzV9/S+T2MbFc7oZAxggQNMIIECQIBATCBkzB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAbT7gAhEBdIt+gABAAABtDANBglghkgB
# ZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3
# DQEJBDEiBCDZaeAurp2uN7RlfydciGE6h1KcQheC28ewhPWWH1EbPDCB+gYLKoZI
# hvcNAQkQAi8xgeowgecwgeQwgb0EINPI93vmozBwBlFxvfr/rElreFPR4ux7vXKx
# 2ni3AfcGMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
# AAG0+4AIRAXSLfoAAQAAAbQwIgQgSHhtICWv5c6B74VqYSnFoYDg/pzwv0n45ZAK
# lR1J+6cwDQYJKoZIhvcNAQELBQAEggIANAr8JCzXYDTcw6gwhV38Wt338P//Kor0
# zcp4j88uvkwpIXDjSVd3n/CJmzrnUzT3NItGR5fLAlAnZ/yn/HAV5nCAmzMSoCGV
# FFXysJW/OzAbi23wEfF5GeISv5PWQlNGndDohZPAaYx4A3XaCVV84vVrC4n6Mlfb
# P5YdcWGuxDuO7pWyWkrreRdfP843gapxVmdP9GEYoqO2qyuZWTGATbihgNoFk3P5
# vYP3oed0CkMew1EO0OopnrLBh6fmo1gewYrMoSOXeOAZdoEjOOm1ou+pbg7qrJtx
# 6fK+d2zS3QZ+NW6+v8iyl8j8AthYupKkdcboFdO7DEwykoYsb2YAdlCvqEtIMBvN
# XkumzQaeHLYnZM8yuV1WPtpYv695gh4OTzE+Pj1+7fkYfMs6rxPKg5IJBQIkjh4h
# 6dx0Bs5/RBcIFolCnMPJGikn6OdCtNpY1AhYrGf1f8zYAsKpfUcSn3VNQvrPAnDO
# g245f0+34KrINK4arjGHeBoPfKcqTKnjnW9dODcwNykNlZfmLfIKz8+NHmtnQlbV
# vPc5ClHS69SUbEFjfPbDNAG2xQVow06unBpWwB9I6QVK9NcRf1lXOlx1MwV1CJgk
# 0vmDeyQKu7gv+LMxrLPLiEuD+hv35pPi14Rvs706vg8corPpVEhf+wGZW0n8ZkSI
# A3oX7D2bgUs=
# SIG # End signature block
