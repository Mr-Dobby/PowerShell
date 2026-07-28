
#************************************************
# DC_W32Time.ps1
# Version 1.0
# Date: 12-22-2010
# Author: clandis
# Description: Collects W32Time information
#************************************************

PARAM([string]$LogType="Full")

Import-LocalizedData -BindingVariable W32TimeStrings -FileName DC_W32Time -UICulture en-us

Write-DiagProgress -Activity $W32TimeStrings.ID_W32TimeOutput -Status $W32TimeStrings.ID_W32TimeObtaining

# If you specify a file name but not a full path for FileLogName, W32Time will try to write to %windir%\system32 but will fail with Access is Denied.
# So there is no point in checking for a file name but no full path, since it wouldn't allow debugging to actually be enabled anyway since the file wouldn't get written.

# Read the FileLogName value into the $FileLogName variable

$FileLogName = (get-itemproperty HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Config\).FileLogName

# If $FileLogName is null (because FileLogName is not set) then throw an error.
If ($null -eq $FileLogName)	{
	"FileLogName registry value is not set. W32Time debug logging is not enabled." | Out-Host 
	} 
# If $FileLogName is populated, check if the path exists and if so, copy the file to current directory, prepending the computer name.
Else {
	"FileLogName = $FileLogName" | Out-Host 
	If (Test-Path $FileLogName) {
		"Copying $FileLogName to .\" + ($ComputerName + "_W32Time.log") | Out-Host
		Copy-Item $FileLogName (".\" + $ComputerName + "_W32Time.log")
		If (Test-Path (".\" + $ComputerName + "_W32Time.log")) {
			"File copy succeeded." | Out-Host 
			}
		Else {
			"File copy failed." | Out-Host 
			}
	Else {
		"File not found." | Out-Host 
		}
	}
}

# w32tm /query /status for local machine, PDC, and authenticating DC.
$OutputFile = $ComputerName + "_W32TM_Query_Status.TXT"	#_#

$Domain = [adsi]("LDAP://RootDSE")
$AUTHDC_DNSHOSTNAME = $Domain.dnshostname
$DomainDN = $Domain.defaultNamingContext
if ($DomainDN) {
	$PDC_NTDS_DN = ([adsi]("LDAP://"+ $DomainDN)).fsmoroleowner
	$PDC_NTDS = [adsi]("LDAP://"+ $PDC_NTDS_DN)
	$PDC = $PDC_NTDS.psbase.get_parent() #_# -ErrorAction SilentlyContinue
} else { " could not resolve DomainDN ($DomainDN) via LDAP://RootDSE" | Out-File -FilePath $OutputFile -append}
if ($null -ne $PDC) { $PDC_DNSHOSTNAME = $PDC.dnshostname }

"This output is best viewed in the Support Diagnostic Console (SDC) or Internet Explorer. `n " | Out-File -FilePath $OutputFile -append

"[INFO] The following errors are expected to occur under the following conditions: " | Out-File -FilePath $OutputFile -append
"   -  'Access is Denied' is expected if MSDT was run with an account that does not have local administrative rights on the target machine. " | Out-File -FilePath $OutputFile -append
"   -  'The procedure is out of range' is expected if the target machine is not running Windows Server 2008 or later. " | Out-File -FilePath $OutputFile -append
"   -  'The RPC server is unavailable' is expected if Windows Firewall is enabled on the target machine, or the target machine is otherwise unreachable. `n `n " | Out-File -FilePath $OutputFile -append
"Output of 'w32tm /query /status /verbose' " | Out-File -FilePath $OutputFile -append
"=========================================" | Out-File -FilePath $OutputFile -append
cmd /d /c w32tm /query /status /verbose | Out-File -FilePath $OutputFile -append

"Output of 'w32tm /query /configuration' " | Out-File -FilePath $OutputFile -append
"=========================================" | Out-File -FilePath $OutputFile -append
cmd /d /c w32tm /query /configuration | Out-File -FilePath $OutputFile -append
"Output of 'w32tm /query /peers' " | Out-File -FilePath $OutputFile -append
"=========================================" | Out-File -FilePath $OutputFile -append
cmd /d /c w32tm /query /peers | Out-File -FilePath $OutputFile -append

if ($Global:skipHang -ne $true) {  #_#
	If ($null -ne $PDC_DNSHOSTNAME) {
		"`n[INFO] The PDC Emulator for this computer's domain is $PDC_DNSHOSTNAME `n " | Out-File -FilePath $OutputFile -append

		"Output of 'w32tm /query /computer:$PDC_DNSHOSTNAME /status /verbose' - " | Out-File -FilePath $OutputFile -append
		"=========================================================================== "  | Out-File -FilePath $OutputFile -append
		cmd /d /c w32tm /query /computer:$PDC_DNSHOSTNAME /status /verbose | Out-File -FilePath $OutputFile -append
		}
	Else {
		"[Error] Unable to determine the PDC Emulator for the domain. `n " | Out-File -FilePath $OutputFile -append
		}

	If ($null -ne $AUTHDC_DNSHOSTNAME) {
		"`n[INFO] This computer's authenticating domain controller is $AUTHDC_DNSHOSTNAME `n " | Out-File -FilePath $OutputFile -append

		"Output of 'w32tm /query /computer:$AUTHDC_DNSHOSTNAME' /status /verbose" | Out-File -FilePath $OutputFile -append
		"=========================================================================== "  | Out-File -FilePath $OutputFile -append
		cmd /d /c w32tm /query /computer:$AUTHDC_DNSHOSTNAME /status /verbose | Out-File -FilePath $OutputFile -append
		}
	Else {
		"[Error] Unable to determine this computer's authenticating domain controller." | Out-File -FilePath $OutputFile -append
		}

	$outStripchart = ".\" + $ComputerName + "_W32TM_Stripchart.txt"
	If ($null -ne $PDC_DNSHOSTNAME) {
		"[INFO] The PDC Emulator for this computer's domain is $PDC_DNSHOSTNAME `n " | Out-File $outStripchart -append

		"Output of 'w32tm /stripchart /computer:$PDC_DNSHOSTNAME /samples:5 /dataonly' " | Out-File $outStripchart -append
		"=========================================================================== "  | Out-File $outStripchart -append
		cmd /d /c w32tm /stripchart /computer:$PDC_DNSHOSTNAME /samples:5 /dataonly | Out-File $outStripchart -append

		}
	Else {
		"[Error] Unable to determine the PDC Emulator for the domain." | Out-File $outStripchart -append
		}

	If ($null -ne $AUTHDC_DNSHOSTNAME) {
		"`n`n[INFO] This computer's authenticating domain controller is $AUTHDC_DNSHOSTNAME `n " | Out-File $outStripchart -append

		"Output of 'w32tm /stripchart /computer:$AUTHDC_DNSHOSTNAME /samples:5 /dataonly" | Out-File $outStripchart -append
		"=========================================================================== "  | Out-File $outStripchart -append
		cmd /d /c w32tm /stripchart /computer:$AUTHDC_DNSHOSTNAME /samples:5 /dataonly | Out-File $outStripchart -append
		}
	Else {
		"[Error] Unable to determine this computer's authenticating domain controller." | Out-File $outStripchart -append
		}
} #_#
$OutputFile1 = join-path $pwd.path ($ComputerName + "_W32Time_Service_Status.txt")
$command1 = $Env:windir + "\system32\cmd.exe /d /c sc query w32time > `"$OutputFile1`""

$OutputFile2 = join-path $pwd.path ($ComputerName + "_W32Time_Service_Perms.txt")
$command2 = $Env:windir + "\system32\cmd.exe /d /c sc sdshow w32time > `"$OutputFile2`""

$OutputFile3 = join-path $pwd.path ($ComputerName + "_W32TM_Monitor.txt")
$command3 = $Env:windir + "\system32\cmd.exe /d /c w32tm /monitor > `"$OutputFile3`""

$OutputFile4 = join-path $pwd.path ($ComputerName + "_W32TM_TestIf_QPS.txt")
$command4 = $Env:windir + "\system32\cmd.exe /d /c w32tm /testif /qps > `"$OutputFile4`""

$OutputFile5 = join-path $pwd.path ($ComputerName + "_W32TM_TZ.txt")
$command5 = $Env:windir + "\system32\cmd.exe /d /c w32tm /tz > `"$OutputFile5`""

CollectFiles -filesToCollect ($ComputerName + "_W32Time.log") -fileDescription "W32Time Debug Log" -sectionDescription "W32Time" -noFileExtensionsOnDescription
RegQuery -RegistryKeys "HKLM\SYSTEM\CurrentControlSet\Services\W32Time" -OutputFile ($ComputerName + "_W32Time_Reg_Key.txt") -fileDescription "W32Time Reg Key" -sectionDescription "W32Time" -recursive $true #_# removed .\ /WalterE

Get-Acl HKLM:\SYSTEM\CurrentControlSet\services\W32Time | Format-List | Out-File (".\" + $ComputerName + "_W32Time_Reg_Key_Perms.txt")
CollectFiles -filesToCollect ($ComputerName + "_W32Time_Reg_Key_Perms.txt") -fileDescription "W32Time Reg Key Perms" -sectionDescription "W32Time" -noFileExtensionsOnDescription
RunCmD -commandToRun $command1 -sectionDescription "W32Time" -filesToCollect $OutputFile1 -fileDescription "W32Time Service Status" -noFileExtensionsOnDescription
RunCmD -commandToRun $command2 -sectionDescription "W32Time" -filesToCollect $OutputFile2 -fileDescription "W32Time Service Perms" -noFileExtensionsOnDescription

if($LogType -eq "Full"){
 if ($Global:skipHang -ne $true) {
	"__ value of Switch skipHang: $Global:skipHang  - 'True' will suppress some W32TM /Monitor output `n`n"        | WriteTo-StdOut
	Write-Host -ForegroundColor Yellow "If w32tm is stuck for a long time >1h, please abort with CTRL-C and if you need a full SDP report, run .\TSS.ps1 -SDP NET -skipSDPlist skipHang"
	Write-DiagProgress -Activity $W32TimeStrings.ID_W32TimeOutput -Status "w32tm /monitor"
	RunCmD -commandToRun $command3 -sectionDescription "W32Time" -filesToCollect $OutputFile3 -fileDescription "W32TM /Monitor" -noFileExtensionsOnDescription
	Write-DiagProgress -Activity $W32TimeStrings.ID_W32TimeOutput -Status "w32tm /testif /qps"
	RunCmD -commandToRun $command4 -sectionDescription "W32Time" -filesToCollect $OutputFile4 -fileDescription "W32TM /TestIf /QPS" -noFileExtensionsOnDescription
 }
}

### (Andret) Removed due http://bugcheck/Bugs/WindowsOSBugs/1879349 and http://bugcheck/bugs/Windows7/35226
RunCmD -commandToRun $command5 -sectionDescription "W32Time" -filesToCollect $OutputFile5 -fileDescription "W32TM /TZ" -noFileExtensionsOnDescription

CollectFiles -filesToCollect ($ComputerName + "_W32TM_Query_Status.txt") -fileDescription "W32TM Query Status" -sectionDescription "W32Time" -noFileExtensionsOnDescription
CollectFiles -filesToCollect ($ComputerName + "_W32TM_Stripchart.txt") -fileDescription "W32TM Stripchart" -sectionDescription "W32Time" -noFileExtensionsOnDescription

Trap{WriteTo-StdOut "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $_" -shortformat;Continue}


# SIG # Begin signature block
# MIInxAYJKoZIhvcNAQcCoIIntTCCJ7ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB6aqDlynRA176y
# XKWpOg3NfpKEceuoHVifTVb+jWjjlKCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOzMo4gF5v+YQJurcuNeEHDr
# 5hdwCyn9473pAIMNOwSqMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCGUROHEJjjm7rhX9bN6qfz3BrV0t9eK+wQTBcaXF+IbPK3l7h/e7RF
# A7L0DrgTDE8e/M6MaK1uV+s0SBngktbTG9pwZqqdbsnenhWOuCTVWDe5fI8Sk5BW
# z0Tpyw0/RqG9nAWwl4XEmJsh2VM6de4r2Hs7B40q9Twj4zqyfnERhPHhwOUEszOn
# U6jBZZUmHJfnWEvK2PJ0RaADjorK35GPZYrL/Swx8VbRaGr0gHC42uY+KiNSdp2U
# HKFS6471JFw4UUCMXzjwgm82nQ2tdIaf4b5Pr0wDaqE+uqFNRCuuC4xz1V2Km6FF
# baHpm0OJo5W1Ae/34LseDsaBFveJBUB/oYIXLDCCFygGCisGAQQBgjcDAwExghcY
# MIIXFAYJKoZIhvcNAQcCoIIXBTCCFwECAQMxDzANBglghkgBZQMEAgEFADCCAVkG
# CyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEID1r8U7C3aN01+rNYNJluTs1lqKxz3G4Vv6FRiJpZqWFAgZkkuYC
# /OwYEzIwMjMwNzAzMTU0NTAzLjg0N1owBIACAfSggdikgdUwgdIxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJ
# cmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBF
# U046MkFENC00QjkyLUZBMDExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFNlcnZpY2WgghF7MIIHJzCCBQ+gAwIBAgITMwAAAbHKkEPuC/ADqwABAAABsTAN
# BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0y
# MjA5MjAyMDIxNTlaFw0yMzEyMTQyMDIxNTlaMIHSMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBP
# cGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjJBRDQt
# NEI5Mi1GQTAxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAhqKrPtXsG8fsg4w8R4Mz
# ZTAKkzwvEBQ94ntS+72rRGIMF0GCyEL9IOt7f9gkGoamfbtrtdY4y+KIFR8w19/n
# U3EoWhJfrYamrfpgtFmTaE3XCKCsI7rnrPmlVOMmndDyN1gAlfeu4l5rdxx9ODEC
# BPdS/+w/jDT7JkBhrYllqVXcwGAgWLdXAoUDgKVByv5XhKkbOrPx9qppuZjKm4nf
# lmfwb/bTWkA3aMMQ67tBoMLSsbIN3BJNWZdwczjoQVXo3YXr2fB+PYNmHviCcDUM
# Hs0Vxmf7i/WSpBafsDMEn6WY7G8qtRGVX+7X0zDVg/7NVDLMqfn/iv++5hJGP+2F
# mv4WZkBS1MBpwvOi4EQ25pIG45jWTffR4ynyed1I1SxSOP+efuBx0WrN1A250lv5
# fGZHCL0vCMDT/w+U6wpNnxfDoQRY9Ut82iNK5alkxNozPP/DNI+nknTaSliaR2Xn
# SXDIZEs7lfuJYg0qahfJJ1CZF2IYxOS9FK1crEigSb8QnEJoj6ThLf4FYpYLTsRX
# lPdQbvBsVvgt++BttooznwfK0DKMOc718SLS+unwkVO0aF23CEQSStoy0ZW34K+c
# bRmUfia+k9E+4luoTnT17oKqYfDNO5Rk8UwVa8mfh8+/R3fZaz2O/ZhiYT/RZHV9
# Quz5PHGlaCfXPQ8A6zFJlE8CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBT0m2eR7w2t
# hIr18WehUTSmvQ45kzAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEA2Oc3kmql5VKE
# itAhoBCc1U6/VwMSYKQPqhC59f00Y5fbwnD+B2Qa0wnJqADSVVu6bBCVrks+EGbk
# uMhRb/lpiHNKVnuXF4PKTDnvCnYCqgwAmbttdxe0m38fJpGU3fmECEFX4OYacEhF
# wTkLZtIUVjdqwPnQpRII+YqX/Q0Vp096g2puPllSdrxUB8xIOx3F7LGOzyv/1Wmr
# LyWAhUGpGte0W3qfX4YWkn7YCM+yl887tj5j+jO/l1MRi6bl4MsN0PW2FCYeRbyz
# QEENsg5Pd351Z08ROR/nR8z+cAuQwR29ijaDKIms5IbRr1nZL/qZskFSuCuSA+nY
# eMuTJxHg2HCXrt6ECFbEkYoPaBGTzxPYopcuJEcChhNlWkduCRguykEsmz0LvtmS
# 7Fe68g4Zoh3sQkIE5VEwnKC3HwVemhK7eNYR1q7RYExfGFUDMQdO7tQpbcPD4oaB
# btFGWGu3nz1IryWs9K88zo8+eoQV/o9SxNU7Rs6TMqcLdM6C6LgmGVaWKKC0S2DV
# KU8zFx0y5z25h1ZJ7X/Zhaav1mtXVG6+lJIq8ktJgOU5/pomumdftgosxGjIp3NO
# Ry9fDUll+KQl4YmN9GzZxPYkhuI0QYriLmytBtUK+AK91hURVldVbUjP8sksr1ds
# iQwyOYQIkSxrTuhp0pw7h5329jphgEYwggdxMIIFWaADAgECAhMzAAAAFcXna54C
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
# OjJBRDQtNEI5Mi1GQTAxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQDtZLG+pANsDu/LLr1OfTA/kEbHK6CBgzCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUA
# AgUA6E00XjAiGA8yMDIzMDcwMzE5NDk1MFoYDzIwMjMwNzA0MTk0OTUwWjB3MD0G
# CisGAQQBhFkKBAExLzAtMAoCBQDoTTReAgEAMAoCAQACAgLIAgH/MAcCAQACAhEm
# MAoCBQDoToXeAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAI
# AgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAQfvzb5+FGr6D
# TJyl6LNONHo2JX8Q+vYNGOFvPx7DL8urFmFfan7Onhf+nGDmR7VUUXcV8ahTWNk3
# PpC/eraY0bZUwX5wG9giGCX1CA9zJucgo3yN0itZ2peePo6P4qWY3YhCzIghp3al
# 76ALHZdM4SHeNepSNvymzztvW/lqe3sxggQNMIIECQIBATCBkzB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAbHKkEPuC/ADqwABAAABsTANBglghkgB
# ZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3
# DQEJBDEiBCBIBwY233+ndxwiSt1QKUBv9tIenC4xYSTtCphdwD7ZmzCB+gYLKoZI
# hvcNAQkQAi8xgeowgecwgeQwgb0EIIPtDYsUW9+p4OjL2Cm7fm3p1h6usM7RwxOU
# 4iibNM9sMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
# AAGxypBD7gvwA6sAAQAAAbEwIgQg6ejCkLD0aW15554whze76HdjveZUiaov1FW8
# XTG+WvwwDQYJKoZIhvcNAQELBQAEggIAdRWdlwAKASfjXWHJvs40YKkdrIhQw4f2
# kFEpJNy9ZeeRs76b+5RxiYZFA2DwshOiVQ7h0cfz2N7RdD1FSdO3ikFz0sdaUxrt
# QO6yQo1yzHj5nkPGDIXz9Bh6x8hK7VLhHm1uFMUc9oywMd9oYXkKSfu0WQePMbwJ
# w0J8Vrgg3eQdj4/ZxTan88LkasRgMqAG1hLx8vN7jLD1rlGd3AeyVpJyns8mPdQB
# aLIMqGOVUXASPKR3/X+IiKp7rWEE3cSDWiVz5skOrbgJLUIk9K7XNJL7torhTV1I
# 8YIHwTAoco/PQipiYEDdWMDZjNAG5c2/x5DqpfNUKmP+cTUMzDpW/pkkU1FDEDdY
# KD79ESd14+SRPkCu+o2icGNnyWj/I/3mmW0GpPGLZm8jD49x/RasmGZZ2MIgiLZA
# M6AqbN0Zk+eXlxawcuGRHqmbPXQSSzS+xpH1vFaPnhQsd8wDytkhVAa7L8RJNPiT
# fxdhJGZHVayJx2XWDgbsiV3XoJGLzA8iWQwBT2Vkc/MQ34mbQHbBAQueh7EbpJh8
# 6XkCrAv+ngLK8ry6VM9bDndUct7Qz0Obth14QW1oWWkLuvFjaYc/ZaLmJuJdpXdX
# 9GRsY06kLwrhVpf79cDmslTK3MxFQLW38e6BOu2/oWtRE4IlWiq19iyJ8U6dnh+v
# /fRrglsL5Ps=
# SIG # End signature block
