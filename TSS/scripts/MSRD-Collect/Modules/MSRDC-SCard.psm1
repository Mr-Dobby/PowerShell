<#
.SYNOPSIS
   Scenario module for collecting Microsoft Remote Desktop Smart Card related data

.DESCRIPTION
   Collect Smart Card related troubleshooting data

.NOTES
   Author     : Robert Klemencz
   Requires   : MSRD-Collect.ps1
   Version    : See MSRD-Collect.ps1 version
   Feedback   : https://aka.ms/MSRD-Collect-Feedback
#>

$msrdLogPrefix = "SCard"

Function msrdGetSCardEventLogs {

    msrdCreateLogFolder $global:msrdEventLogFolder
    $logs = @{
        'Microsoft-Windows-SmartCard-Audit/Authentication' = 'SmartCard-Audit-Auth'
        'Microsoft-Windows-SmartCard-DeviceEnum/Operational' = 'SmartCard-DeviceEnum-Operational'
        'Microsoft-Windows-SmartCard-TPM-VCard-Module/Admin' = 'SmartCard-TPM-Admin'
        'Microsoft-Windows-SmartCard-TPM-VCard-Module/Operational' = 'SmartCard-TPM-Operational'
    }
    msrdGetEventLogs -LogPrefix $msrdLogPrefix -EventHashtable $logs
}

function msrdGetRDGW {

    #get RD Gateway information
    msrdLogMessage $LogLevel.Normal ("[SCard] msrdGetRDGW")
    $RDSGWRAP = msrdGetRDRoleInfo Win32_TSGatewayResourceAuthorizationPolicy root\cimv2\TerminalServices
    if ($RDSGWRAP) { $RDSGWRAP | Out-File -Append ($global:msrdRDSLogFolder + $global:msrdLogFilePrefix + "rdgw_ResourceAuthorizationPolicy.txt") }
    else { msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "[WARNING] Failed to get Win32_TSGatewayResourceAuthorizationPolicy." }

    $RDSGWCAP = msrdGetRDRoleInfo Win32_TSGatewayConnectionAuthorizationPolicy root\cimv2\TerminalServices
    if ($RDSGWCAP) { $RDSGWCAP | Out-File -Append ($global:msrdRDSLogFolder + $global:msrdLogFilePrefix + "rdgw_ConnectionAuthorizationPolicy.txt") }
    else { msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "[WARNING] Failed to get Win32_TSGatewayConnectionAuthorizationPolicy." }

    $RDSGWS = msrdGetRDRoleInfo Win32_TSGatewayServerSettings root\cimv2\TerminalServices
    if ($RDSGWS) { $RDSGWS | Out-File -Append ($global:msrdRDSLogFolder + $global:msrdLogFilePrefix + "rdgw_ServerSettings.txt") }
    else { msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "[WARNING] Failed to get Win32_TSGatewayServerSettings." }
}

Function msrdGetKDCRDGWInfo {

    $logs = @{
        'Microsoft-Windows-Kerberos-KDCProxy/Operational' = 'Kerberos-KDCProxy-Operational'
    }
    msrdGetEventLogs -LogPrefix $msrdLogPrefix -EventHashtable $logs

    #Collecting RDGW information
    $isRDGW = (Get-WindowsFeature -Name RDS-GATEWAY).InstallState
    if ($isRDGW -eq "Installed") {
        " " | Out-File -Append $global:msrdOutputLogFile
        msrdLogMessage $LogLevel.Info ('Collecting Remote Desktop Gateway information')

        msrdCreateLogFolder $global:msrdRDSLogFolder
        msrdGetRDGW

    } else {
        msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "RD Gateway role not found. Skipping collection of RD Gateway information"
    }
}

# Collecting Smart Card troubleshooting data
Function msrdCollectUEX_AVDSCardLog {
    param( [bool[]]$varsSCard )

    if ($true -contains $varsSCard) {
        if ($global:msrdSilentMode -eq 1) { msrdLogMessage $LogLevel.Normal "`n" -NoDate } else { " " | Out-File -Append $global:msrdOutputLogFile }
        msrdLogMessage $LogLevel.Info ("$(msrdGetLocalizedText "scardmsg")") -silentException
        msrdCreateLogFolder $global:msrdSysInfoLogFolder
    }

    if ($varsSCard[0]) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collecting Smart Card related event logs" }
        msrdGetSCardEventLogs
    } #get event logs

    if ($varsSCard[1]) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collecting Smart Card information" }
        $Commands = @(
            "certutil -scinfo -silent 2>&1 | Out-File -Append '" + $global:msrdSysInfoLogFolder + $global:msrdLogFilePrefix + "SmartCardInfo.txt'"
        )
        msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
    }

    if ($varsSCard[2] -and $global:msrdTarget -and ($global:msrdOSVer -like "*Windows Server*")) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collecting KDCProxy and RD Gateway information" }
        msrdGetKDCRDGWInfo
    } #get KDCProxy and RD Gateway information
}

Export-ModuleMember -Function msrdCollectUEX_AVDSCardLog
# SIG # Begin signature block
# MIIoKQYJKoZIhvcNAQcCoIIoGjCCKBYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAapAC9Ry9lGCD9
# XeiiWOGrtFmoX/GCXXf0QdJVrNgkp6CCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgkwghoFAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINDgm2mNaMPkI96uY6K7iiRm
# 6zvNFTDyOOgZ+fvyenUJMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEArdj+nVw8rjLyzi8L/JzRf9LBmmc/DprpZsNecnIPUdKWp8KwM9hb0bP6
# sER7ZNPNNzydGWyeyqIK7XFOg2p3N3PsPJILF5bj/DvlsyeLuGfn7CnS/Ep4i691
# obEf5Ysa9XLFB9l0BCsxuDOECsTcxS2zKlZATNJTTsMbnoSq4HvtNVc1mc21AfqA
# cXUXGO7DV2B3CjmZOrbkeKMW6MzQQWLHHWC5YprFrRsPfSFeDHeynZStV0uUgwku
# vHReZ6OBOOFslUz4M0XQ24Fq+pxplUcZPGuqg58Work1a19yvD4LrWDAxuoPvHoE
# c3nmghxRity1gGUOfBUyxQhlfua7mqGCF5MwghePBgorBgEEAYI3AwMBMYIXfzCC
# F3sGCSqGSIb3DQEHAqCCF2wwghdoAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFRBgsq
# hkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAtyp4qFvcDo3T9pWFT8dcC5N+PTrbX0BpoFw42AgoYHQIGZkX6RBE6
# GBIyMDI0MDYxMjE1MDA0NS4zMlowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5MjAwLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCC
# EeowggcgMIIFCKADAgECAhMzAAAB5y6PL5MLTxvpAAEAAAHnMA0GCSqGSIb3DQEB
# CwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4NDUx
# OVoXDTI1MDMwNTE4NDUxOVowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMx
# JzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5MjAwLTA1RTAtRDk0NzElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAMJXny/gi5Drn1c8zUO1pYy/38dFQLmR2IQXz1gE/r9G
# fuSOoyRnkRJ6Z/kSWLgIu1BVJ59GkXWPtLkssqKwxY4ZFotxpVsZN9yYjW8xEnW3
# MzAI0igKr+/LxYfxB1XUH8Bvmwr5D3Ii/MbDjtN9c8TxGWtq7Ar976dafAy3TrRq
# QRmIknPVWHUuFJgpqI/1nbcRmYYRMJaKCQpty4CeG+HfKsxrz24F9p4dBkQcZCp2
# yQzjwQFxZJZ2mJJIGIDHKEdSRuSeX08/O0H9JTHNFmNTNYeD1t/WapnRwiIBYLQS
# Mrs42GVB8pJEdUsos0+mXf/5QvheNzRi92pzzyA4tSv/zhP3/Ermvza6W9GnYDz9
# qv1wbhbvrnS4poDFECaAviEqAhfn/RogCxvKok5ro4gZIX1r4N9eXUulA80pHv3a
# xwXu2MPlarAi6J9L1hSIcy9EuOMqTRJIJX+alcLQGg+STlqx/GuslsKwl48dI4Ru
# WknNGbNo/o4xfBFytvtNcVA6xOQq6qRa+9gg+9XMLrxQz4yyQs+V3V6p044wrtJt
# t/a0ZJl/f6I7BZAxxZcH2DDmArcAhgrTxaQkm7LM+p+K2C5t1EKZiv0JWw065b7A
# cNgaFyIkMXYuSuOQVSNRxdIgl31/ayxiK1n0K6sZXvgFBx+vGO+TUvyO+03ua6Uj
# AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUz/7gmICfNjh2kR/9mWuHUrvej1gwHwYD
# VR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZO
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# VGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
# BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0
# cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYD
# VR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
# B4AwDQYJKoZIhvcNAQELBQADggIBAHSh8NuT6WVaLVwLqex+J7km2nT2jpvoBEKm
# +0M+rYoU/6GL5Q00/ssZyIq5ySpcKYFMUiF8F4ZLG+TrJyiR1CvfzXmkQ5phZOce
# 9DT7yErLzqvUXit8G7igcHlxPLTxPiiGsb85gb8H+A2fPQ6Xq/u7+oSPPjzNdnpm
# XEobJnAqYplZoF3YNgTDMql0uQHGzoDp6dZlHSNj6rkV1tXjmCEZMqBKvkQIA6cs
# PieMnB+MirSZFlbANlChe0lJpUdK7aUdAvdgcQWKS6dtRMl818EMsvsa/6xOZGIN
# mTLk4DGgsbaBpN+6IVt+mZJ89yCXkI5TN8xCfOkp9fr4WQjRBA2+4+lawNTyxH66
# eLZWYOjuuaomuibiKGBU10tox81Sq8EvlmJIrXOZoQsEn1r5g6MTmmZJqtbmwZuf
# uJWQXZb0lAg4fq0ZYsUlLkezfrNqGSgeHyIP3rct4aNmqQW6wppRbvbIyP/LFN4Y
# QM6givfmTBfGvVS77OS6vbL4W41jShmOmnOn3kBbWV6E/TFo76gFXVd+9oK6v8Hk
# 9UCnbHOuiwwRRwDCkmmKj5Vh8i58aPuZ5dwZBhYDxSavwroC6j4mWPwh4VLqVK8q
# GpCmZ0HMAwao85Aq3U7DdlfF6Eru8CKKbdmIAuUzQrnjqTSxmvF1k+CmbPs7zD2A
# cu7JkBB7MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG
# 9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIw
# MTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az
# /1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V2
# 9YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oa
# ezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkN
# yjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7K
# MtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRf
# NN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SU
# HDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoY
# WmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5
# C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8
# FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TAS
# BgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1
# Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUw
# UzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIB
# hjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fO
# mhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9w
# a2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggr
# BgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3
# DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEz
# tTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJW
# AAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G
# 82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/Aye
# ixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI9
# 5ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1j
# dEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZ
# KCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xB
# Zj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuP
# Ntq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvp
# e784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCA00w
# ggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OTIwMC0wNUUwLUQ5NDcxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVALNy
# BOcZqxLB792u75w97U0X+/BDoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDqFA9LMCIYDzIwMjQwNjEyMTIxMjU5
# WhgPMjAyNDA2MTMxMjEyNTlaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOoUD0sC
# AQAwBwIBAAICETowBwIBAAICE7EwCgIFAOoVYMsCAQAwNgYKKwYBBAGEWQoEAjEo
# MCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkqhkiG
# 9w0BAQsFAAOCAQEAVrJuq+5s19lNmyetx2f622N+lTJee/WLETTUvAL92CPlBQlH
# aszm7CSrc5OposS/0hfJ8Ga5NpEQQF+Dy+IkccGFR+9fcFk23HT/5KIYNIF+8QcA
# OJdDAwXMeaemKK/VulD1OgEJWPWVF3hOd7NgLgQ3FwB36uX8u/kXTpLENECGZYgu
# JQPhBrWT9ruUxViUA8nRjN2HW45N+kyyQitA9fxE2yaSJbNXMUbAl8qSfBWQkCgY
# smOUUc5lbpiBTCU20UxJwe6qlBypnZh+aOK4RyH7XP/+sT2JPhj2hSnuxkEScxHU
# Yv9R7Ivo2bFkNXi9Q7aPyPSIiCU5C69Rxc5NuzGCBA0wggQJAgEBMIGTMHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB5y6PL5MLTxvpAAEAAAHnMA0G
# CWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJ
# KoZIhvcNAQkEMSIEIHn0Ei0xrUelv7RAV6VHxI8QoQuk70fJ6zSjdW92iPxcMIH6
# BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg5TZdDXZqhv0N4MVcz1QUd4RfvgW/
# QAG9AwbuoLnWc60wgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MAITMwAAAecujy+TC08b6QABAAAB5zAiBCC9mzaeNps7MpLko5AVSPYWS9hCdHpW
# 7hFEZEyfw6h75jANBgkqhkiG9w0BAQsFAASCAgC3U0OQBamuqu2WCIRybAYHTUnL
# iI4pHQ6BFS7W0McX+UWfVeHQUwGWcNPMt99ZJaPTuYBn96nySjx5LIavKlUHAqoX
# 9QQd4luQzfRhRiY8pkQ3M8cFQhYtHlxNy4qyY7GoaRUkwoqB1KVJrSiwVchy4ALn
# PakkFHBS+EyTVProo4kkYsuhaWDLzAQ24/E3fMPwZHlaZl+xA7dv8i0nwNSeskz5
# QH6NuPhWOMvmugtzTvrxxgn9fSCwnsJ6HBOsMn86iSOarcKevqWG0ltwyK3y/bke
# CKfdLgxa3N/xJlkOjXU2IBUCYTGGac/+xq6jbHiS2NUSMunU1yv308GwbVYi5+JZ
# oO0WJGspgtdfgT7847y3VUoa8vjjjV+09ly404aYAUwDGMVcMJfKAWoPB7KbaJma
# GRFGGdTNS8QyC8r6NeVrFLDn3b4XGilkgc2ZD1EqxosJGygo9flf+O7oUc8D4OhW
# HNUnmhVTwYUOVitRhX8jUNKGsd1NUWrqbpUbIO2mX6GSIzqXcX0kwSX1gAbPEf7M
# L81Sf6K6hE1COwMC2Ck9pCSzWE7ETeiReUv9A78gBhRGwkSjs1+y9cklezu3FcUW
# WfNJvtR+cPVbTru9MbxbLLChklKuYvjlh8CfaLPNEyYJF3tp20DEHbOJwD0QneU1
# dkN+JZcadw9754xo4w==
# SIG # End signature block
