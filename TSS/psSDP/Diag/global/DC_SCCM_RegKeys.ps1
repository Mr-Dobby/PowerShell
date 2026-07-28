# *********************************************************************
# Version 1.0
# Date: 03-27-2012, 2021
# Author: Vinay Pamnani - vinpa@microsoft.com
# Description:
#		Gets SMS, CCM and WSUS Registry Keys
#		Uses Export-RegKey function (defined in utils_Shared.ps1)
# replaced _RegistryKey_ with _Reg_
# *********************************************************************

trap [Exception]
{
	WriteTo-ErrorDebugReport -ErrorRecord $_
	continue
}

TraceOut "Started"

# ----------------------
# Get WSUS Registry Key
# ----------------------
$TempFileName = $ComputerName + "_Reg_WSUS.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
if ($OSVersion.Major -ge 6) {
	# Get Reg Keys in Decimal format
	Export-RegKey -RegKey $Reg_WSUS -outFile $RegFile -fileDescription "WSUS Registry Key" -collectFiles $true
}
Else {
# Get Reg Keys using Reg.exe since Export-RegKey doesn't work in Background with PS 1.0
RegQuery -RegistryKeys $Reg_WSUS -Recursive $true -outputFile $RegFile -fileDescription "WSUS Registry Key" -sectionDescription "Registry Keys"
}

# ---------------------
# Get SMS Registry Key
# ---------------------
$TempFileName = $ComputerName + "_Reg_SMS.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $Reg_SMS -outFile $RegFile -fileDescription "SMS Registry Key" -collectFiles $true

# ---------------------
# Get CCM Registry Key
# ---------------------

$TempFileName = $ComputerName + "_Reg_CCM.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $Reg_CCM -outFile $RegFile -fileDescription "CCM Registry Key" -collectFiles $true

# -----------------------------------------------------
# Collect HKLM\Software\Microsoft\CCMSetup
# -----------------------------------------------------
$TempFileName = $ComputerName + "_Reg_CCMSetup.txt"
Write-DiagProgress -Activity $ScriptStrings.ID_SCCM_ACTIVITY_CM07ClientInfo -Status $ScriptStrings.ID_SCCM_CM07ClientInfo_CM07ClientInfo
TraceOut "    Getting HKLM\Software\Microsoft\CCMSetup registry key"
$TempKey = "HKLM\SOFTWARE\Microsoft\CCMSetup"
Export-RegKey -RegKey $TempKey -outFile $TempFileName -fileDescription "CCMSetup Registry Key" -collectFiles $false


# --------------------------------------------------------
# Get HKLM\SYSTEM\CurrentControlSet\Services Registry Key
# --------------------------------------------------------
$TempKey = "HKLM\SYSTEM\CurrentControlSet\Services"
$TempFileName = $ComputerName + "_Reg_Services.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "Services Registry Key" -collectFiles $true -ForceRegExe $true # Use Reg.EXE as it is a LOT quicker than ExportReg.ps1

# --------------------------------------------------------
# Get HKEY_LOCAL_MACHINE\SOFTWARE\Policies Registry Key
# --------------------------------------------------------
$TempKey = "HKLM\SOFTWARE\Policies"
$TempFileName = $ComputerName + "_Reg_HKLMPolicies.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "HKLM Policies Reg Key" -collectFiles $true -ForceRegExe $true

# --------------------------------------------------------
# Get HKEY_CURRENT_USER\Software\Policies Registry Key
# --------------------------------------------------------
$TempKey = "HKCU\SOFTWARE\Policies"
$TempFileName = $ComputerName + "_Reg_HKCUPolicies.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "HKCU Policies Reg Key" -collectFiles $true -ForceRegExe $true

# ----------------------------------------------------------------------------------------
# Get HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall Registry Key
# ----------------------------------------------------------------------------------------
$TempKey = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$TempFileName = $ComputerName + "_Reg_Uninstall.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "Uninstall Registry Key" -collectFiles $false	-ForceRegExe $true # Use Reg.EXE as it is a LOT quicker than ExportReg.ps1

If ($OSArchitecture -eq "AMD64" ) {
	$TempKey = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
	$TempFileName = $ComputerName + "_Reg_Uninstall.txt"
	$RegFile = Join-Path $Pwd.Path $TempFileName
	Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "Uninstall Registry Key" -collectFiles $false -ForceRegExe $true # Use Reg.EXE as it is a LOT quicker than ExportReg.ps1
}
CollectFiles -filesToCollect $RegFile -fileDescription "Uninstall Registry Key" -sectionDescription "Registry Keys" -noFileExtensionsOnDescription

# --------------------------------------------------------
# Get HKLM\Software\Microsoft\OLE Registry Key
# --------------------------------------------------------
$TempKey = "HKLM\Software\Microsoft\OLE"
$TempFileName = $ComputerName + "_Reg_DCOM.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "DCOM Registry Key" -collectFiles $true -ForceRegExe $true

# --------------------------------------------------------
# Get HKLM\Software\Microsoft\COM3 Registry Key
# --------------------------------------------------------

$TempKey = "HKLM\Software\Microsoft\COM3"
$TempFileName = $ComputerName + "_Reg_COM3.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "COM3 Registry Key" -collectFiles $true -ForceRegExe $true

# ---------------------------
# Collect SCHANNEL key
# ---------------------------
$TempKey = "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL"
$TempFileName = $ComputerName + "_Reg_SCHANNEL.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "SCHANNEL Registry Key" -collectFiles $true -ForceRegExe $true

# ---------------------------
# Collect FEP/Defender key
# ---------------------------
$TempKey = "HKLM\SOFTWARE\Microsoft\Windows Defender"
$TempFileName = $ComputerName + "_Reg_FEP-Defender.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "FEP/Defender Registry Key" -collectFiles $false -ForceRegExe $true

$TempKey = "HKLM\SOFTWARE\Microsoft\Microsoft Antimalware"
$TempFileName = $ComputerName + "_Reg_FEP-Defender.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "FEP/Defender Registry Key" -collectFiles $false -ForceRegExe $true

# ---------------------------
# Collect Setup\SetupType value, Setup\CmdLine value, and Setup\State\ImageState value
# ---------------------------
$tempStrings = @()
$TempKey = "HKLM\SYSTEM\Setup"
$valueToRetrieve = "SetupType"
#$TempFileName = $ComputerName + "_Reg_Setup_SetupType.txt"
#$RegFile = Join-Path $Pwd.Path $TempFileName
#Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "Setup\SetupType Registry Key" -collectFiles $true -ForceRegExe $true
 $value = Get-RegValue($TempKey) $valueToRetrieve

 if ($null -eq $value)
 {
 	$tempStrings += $TempKey + '\' +  $valueToRetrieve + ":      Not present"
 }
 else
 {
 
 	$tempStrings += $TempKey + '\' +  $valueToRetrieve + ":      " + $value
 }


 $valueToRetrieve = "CmdLine"
 $value = Get-RegValue($TempKey) $valueToRetrieve
 if ($null -eq $value)
 {
	$tempStrings += $TempKey + '\' +  $valueToRetrieve + ":      Not present"
 }
 else
 {
  	$tempStrings += $TempKey + '\' +  $valueToRetrieve + ":      " + $value
 }

 $TempKey = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"
 $valueToRetrieve = "ImageState"
 $value = Get-RegValue($TempKey) $valueToRetrieve
 if ($null -eq $value)
 {
	$tempStrings += $TempKey + '\' +  $valueToRetrieve + ":      Not present"
 }
 else
 {
  	$tempStrings += $TempKey + '\' +  $valueToRetrieve + ":      " + $value
 }

$TempFileName = $ComputerName + "_Reg_Setup_SetupType.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
$tempStrings | Out-File $RegFile -Append

# ---------------------------
# Collect Setup\Microsoft\Enrollment
# ---------------------------
$TempKey = "HKLM\SOFTWARE\Microsoft\Enrollments"
$TempFileName = $ComputerName + "_Reg_Enrollment.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "Enrollments Registry Key" -collectFiles $true -ForceRegExe $true

# ---------------------------
# Collect Setup\Microsoft\Enrollment
# ---------------------------
$TempKey = "HKLM\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"
$TempFileName = $ComputerName + "_Reg_Diagnostics_AutoPilot.txt"
$RegFile = Join-Path $Pwd.Path $TempFileName
Export-RegKey -RegKey $TempKey -outFile $RegFile -fileDescription "Provisioning\Diagnostics\AutoPilot Registry Key" -collectFiles $true -ForceRegExe $true


CollectFiles -filesToCollect $RegFile -fileDescription "FEP/Defender Reg Key" -sectionDescription "Registry Keys" -noFileExtensionsOnDescription

TraceOut "Completed"
# SIG # Begin signature block
# MIInxAYJKoZIhvcNAQcCoIIntTCCJ7ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC2aUQ61cxjKKJu
# MrmK/2Ok8raNrJWQqLgYsZ8bTh6+mqCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPGQuyMUjWAu2xQ5Nb8DevE5
# 1UbveV/w3IEQvhlH6FhqMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQBJSU9NTfWEKSZEWOg4FTRdVCfm/Q8hgZfJxdI67IM2mIIkwj1UGOAo
# VFm1XEN2V32TUjGts9cS44Bp/210LeJZI9sbrx3JznhncytpkURBN8wuZv573KzR
# fbFD2kKb/1jOfny45KYctp4KBaoNOiB8872i6z/CUoyVxgKtpve0npAl893+q3jy
# ZlW4opUFgyeIsLR9+Y9Ex8KXJe/bp8sMCnTpdU9JzPGG0C/JolzsAcZmzCNn5Izz
# LiTQFo6iNn9Da7XJnxdNWtH/4S74CBCeiDZxDPqdqX+wngVIrl4ATij11wCzFPAJ
# PsVGMkeejsSBXvxHIdNgQXNUdmlvlJvEoYIXLDCCFygGCisGAQQBgjcDAwExghcY
# MIIXFAYJKoZIhvcNAQcCoIIXBTCCFwECAQMxDzANBglghkgBZQMEAgEFADCCAVkG
# CyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIACFqqqYjyy+9cRs8pyDIQ4TEf78J8FUZgmQjoLU4wzRAgZk3lRM
# ZfcYEzIwMjMwOTExMTA1NTA0LjY0OVowBIACAfSggdikgdUwgdIxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJ
# cmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBF
# U046MDg0Mi00QkU2LUMyOUExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFNlcnZpY2WgghF7MIIHJzCCBQ+gAwIBAgITMwAAAbJuQAN/bqmUkgABAAABsjAN
# BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0y
# MjA5MjAyMDIyMDFaFw0yMzEyMTQyMDIyMDFaMIHSMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBP
# cGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjA4NDIt
# NEJFNi1DMjlBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyqJlMh17+VDisL4GaXl/
# 9a6r/EpPGt9sbbceh+ZD6pkA3gbI7vc8XfL04B+m3tB/aNyV1Y4ZQH4fMG7CWVjI
# /d/HgxjzO+4C4HfsW+jK2c0LYMqdWtWUc5VwZQv0KeaEM0wDb+eySMh/YiiIb0nS
# otivx268d1An0uLY+r2C7JJv2a9QvrSiCyUI72CSHoWIQPAyvBSvxaNrqMWlROfL
# y2DQ3RycI3bDh8qSnmplxtRgViJwtJv/oDukcK1frGeOrCGYmiJve+QonJXFu4Ut
# GFVfEf3lvQsd42GJ+feO+jaP7/hBXXSMSldVb6IL0GxO1Hr3G9ONTnVmA/sFHhgM
# RarsmzKVI6/kHlMdMNdF/XzhRHMWFPJvw5lApjuaoyHtzwnzDWwQzhcNQXZRk3Lz
# b01ULMba190RdlofEXxGbGlBgHHKFnBjWui24hL6B83Z6r6GQBPeKkafz8qYPAO3
# MBud+5eMCmB5mrCBxgnykMn7L/FTqi7MnPUG97lNOKGSIDvBCxB7pHrRmT10903P
# DQwrmeJHO5BkC3gYj3oWGOGVRZxRk4KS/8lcz84a7+uBKmVjB2Y8vPN8O1fK7L8Y
# JTkjiXTyDqKJ9fKkyChiSRx44ADPi/HXHQE6dlZ8jd9LCo1S+g3udxNP4wHhWm9/
# VAGmmMEBBS6+6Lp4IbQwJU0CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSZ8ieAXNkR
# mU+SMM5WW4FIMNpqcTAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEA3Ee27cXMhpto
# NtaqzB0oGUCEpdEI37kJIyK/ZNhriLZC5Yib732mLACEOEAN9uqivXPIuL3ljoZC
# e8hZSB14LugvVm1nJ73bNgr4Qh/BhmaFL4IfiKd8DNS+xwdkXfCWslR89QgMZU/S
# UJhWx72aC68bR2qRjhrJA8Qc68m5uBllo52D83x0id3p8Z45z7QOgbMH4uJ45snZ
# DQC0S3dc3eJfwKnr51lNfzHAT8u+FHA+lv/6cqyE7tNW696fB1PCoH8tPoI09oSX
# AV4rEqupFM8xsd6D6L4qcEt/CaERewyDazVBfskjF+9P3qZ3R6IyOIwQ7bYts7OY
# sw13csg2jACdEEAm1f7f97f3QH2wwYwen5rVX6GCzrYCikGXSn/TSWLfQM3nARDk
# h/flmTtv9PqkTHqslQNgK2LvMJuKSMpNqcGc5z33MYyV6Plf58L+TkTFQKs6zf9X
# MZEJm3ku9VBJ1aqr9AzNMSaKbixvMBIr2KYSSM21lnK8LUKxRwPW+gWS2V3iYoyM
# T64MRXch10P4OtGT3idXM09K5ld7B9U6dcdJ6obvEzdXt+XZovi/U6Evb4nA7VPH
# cHSKs7U72ps10mTfnlue13VFJUqAzbYoUEeegvsmzulGEGJoqZVNAag5v6PVBrur
# 5yLEajjxWH2TfkEOwlL8MuhcVI8OXiYwggdxMIIFWaADAgECAhMzAAAAFcXna54C
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
# OjA4NDItNEJFNi1DMjlBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQCOEn4R7JJF+fYoI2yOf1wX0BRJOqCBgzCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUA
# AgUA6KkcrTAiGA8yMDIzMDkxMTEyNTcxN1oYDzIwMjMwOTEyMTI1NzE3WjB3MD0G
# CisGAQQBhFkKBAExLzAtMAoCBQDoqRytAgEAMAoCAQACAgGJAgH/MAcCAQACAhBR
# MAoCBQDoqm4tAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAI
# AgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAGRSiU4aa+nCk
# CIyDDOMxgG0sPd34tBKTxsFCan3ze/zC+5DMQbh7xQ8w9Yv0Hbo0lM/Nc2BjWZzy
# s4O8R+ULBKr/x1nfwFu18g8uhgaTemYStz6mehmMHXFJ8IugCZ+jFsjZzR5ZwSNv
# 59m+yAt6G7yzfFXZBmN56n98lmi2Ig8xggQNMIIECQIBATCBkzB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAbJuQAN/bqmUkgABAAABsjANBglghkgB
# ZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3
# DQEJBDEiBCCXi39+hvs6ZiommNfo1Ml5/5eA1l/GRG7hzgiRJ5z+xDCB+gYLKoZI
# hvcNAQkQAi8xgeowgecwgeQwgb0EIFN4zjzn4T63g8RWJ5SgUpfs9XIuj+fO76G0
# k8IbTj41MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
# AAGybkADf26plJIAAQAAAbIwIgQgV6WUCtRuUjtwbnpccIdjcYSafrysACe+Shwt
# 2F3dCTswDQYJKoZIhvcNAQELBQAEggIAJLGtNgFUuCZ8EIPINDd/6uP++NioPHAK
# cfysGzWZ3Tu0f8JhYSF/mKwGKf2cSt7DofCKcIQ+tNO7f9fpS4hbxEXDoB1VFap1
# l2oViV7TnSWCEoneuDmqFrIVl0YrRi88CaS6EkkcrqvVH9WwXUPz4YjwTyaQ05Ct
# XnWSK/RFLD5+q5QtI5kq7nkBOYARQyoBZLIzUVmRNZO5NvZtSzx5m2p0nb6Z5kGH
# ZETxMHTZ2oHZ6yQ7YA4bzl+fjryh5FGpzwmy53H9kDte49/C6ETb9P+vWHtfrB17
# WKXXm1n9lQnikb3jQcIIj3DTEdv18BWsvnLKm/b//zfDmurCtYU/LCu7o9uvizjo
# wxa6vynrNLSYZjZ6l7ZOwrv2cCRRn/mWTPzKsX2PhgLhzzYhrNty7xqcG/fNjfrk
# YC2X9SukE7VLLTJ4e9SHLZr82hlQJNX2oKBcyVFMF4N4SqbKJzf1IHAH4rjf0L54
# 00t/VTnX+FmaXMYbh72c1zA+EVLkVfp2nVs6aXEzR9y5EMjUZ67q7HvZweRtN9GJ
# GBp1ZSfklYEDYboCxYXfVmIhici0fEbtfLi2L3yZmEUFOX02HT5InHpBKakHduj3
# 59YaRTI8LQB2R44ma3YAnKRI+88jbZtUZrucg4hrY9K6Elzkm470MQN2VKArpxkm
# NGZL+bI8kNY=
# SIG # End signature block
