#************************************************
# DC_DiskInfo.ps1
# Version 1.0
# Date: 09-05-2023
# Author: Edmund Spatariu
# Updated: 
# Description: This script obtains Disk Info and associate a drive letter with corresponding LUN, saving output to a
#              file named $ComputerName_DC_DiskInfo.txt
#************************************************
#Last Updated Date: 09-05-2023
#Updated By: 
#Description: 
#************************************************

if($debug -eq $true){[void]$shell.popup("Run DC_DiskInfo.ps1")}
Import-LocalizedData -BindingVariable DiskInfoStrings -FileName DC_DiskInfo -UICulture en-us
	
Write-DiagProgress -Activity $DiskInfoStrings.ID_DiskInfo -Status $DiskInfoStrings.ID_DiskInfoRunning

$fileDescription = $DiskInfoStrings.ID_DiskInfoOutput
$sectionDescription = $DiskInfoStrings.ID_DiskInfoOutputDesc
$OutputFile = $ComputerName + "_DiskInfo.txt"

"=============================================="	| Out-File -FilePath $OutputFile
"Associate Drive Letter with LUN"	| Out-File -FilePath $OutputFile -append
"=============================================="	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append

Get-CimInstance Win32_DiskDrive | ForEach-Object {
  $disk = $_
  $partitions = "ASSOCIATORS OF " +
                "{Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} " +
                "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
  Get-CimInstance -Query $partitions | ForEach-Object {
    $partition = $_
    $drives = "ASSOCIATORS OF " +
              "{Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} " +
              "WHERE AssocClass = Win32_LogicalDiskToPartition"
    Get-CimInstance -Query $drives | ForEach-Object {
      Write-Host ""
      New-Object -Type PSCustomObject -Property @{
        DriveLetter = $_.DeviceID
        VolumeName  = $_.VolumeName
        FileSystem  = $_.Filesystem
        Partition   = $partition.Name
        Size        = $_.Size
        FreeSpace   = $_.FreeSpace
        Disk        = $disk.DeviceID
        DiskModel   = $disk.Model
        LUN         = $disk.SCSILogicalUnit
        Port        = $disk.SCSIPort
        BUS         = $disk.SCSIBus
      }
    } | Sort-Object -Property DriveLetter |Select-Object DriveLetter, VolumeName, FileSystem, Partition, Size, FreeSpace, Disk, DiskModel, LUN, Port, BUS
  }
} | Out-File $OutputFile -append
"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append

"=============================================="	| Out-File -FilePath $OutputFile -append
"Get-CimInstance -Class Win32_DiskDrive"	| Out-File -FilePath $OutputFile -append
"=============================================="	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
Get-CimInstance -Class Win32_DiskDrive -Namespace 'root\CIMV2' | Format-List -Property * | Out-File -Append $OutputFile
"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append

"=============================================="	| Out-File -FilePath $OutputFile -append
"Get-CimInstance -Class Win32_LogicalDisk"	| Out-File -FilePath $OutputFile -append
"=============================================="	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
Get-CimInstance -Class Win32_LogicalDisk -Namespace 'root\CIMV2' | Format-List -Property * | Out-File -Append $OutputFile
"`n`n`n`n`n"	| Out-File -FilePath $OutputFile -append

"=============================================="	| Out-File -FilePath $OutputFile -append
"Get-CimInstance -Class Win32_DiskPartition"	| Out-File -FilePath $OutputFile -append
"=============================================="	| Out-File -FilePath $OutputFile -append
"`n"	| Out-File -FilePath $OutputFile -append
Get-CimInstance -Class Win32_DiskPartition -Namespace 'root\CIMV2' | Format-List -Property * | Out-File -Append $OutputFile

CollectFiles -filesToCollect $OutputFile -fileDescription $fileDescription  -sectionDescription $sectionDescription

# SIG # Begin signature block
# MIIniAYJKoZIhvcNAQcCoIIneTCCJ3UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCEYyWUGOQJapkS
# WT32K2spdXRX9g6KVh+pEYPLkGtU/6CCDagwggaGMIIEbqADAgECAhMTAco/dC5Q
# cPJI+xeWAAIByj90MA0GCSqGSIb3DQEBCwUAMBUxEzARBgNVBAMTCk1TSVQgQ0Eg
# WjEwHhcNMjMwMzE1MTgzMjAzWhcNMjQwMzE0MTgzMjAzWjCBiDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IENv
# cnBvcmF0aW9uIChJbnRlcm5hbCBVc2UgT25seSkwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCQYBfKibbl9ijRUzADGwC6KHKeiLth59ys4HUa8RhK8IvW
# Kbl3o4xtynwFVek/HQSf6mqSLnCZN1w+ywxO5soFhN191qc6RGUxylW2RPlYnwfV
# fpAv2qmHjzL6bDRo+HJAvRXIfM0jHPK0Y4AmcYURlPv2vwgWzLOlG7HiWqUNOSir
# sz8Fz5O6koqPxaeiHTXHvr31Fsqq6xkk51xVDlOrpbBCJdiAhuBwfBvK9sf8mxr1
# hhYDv1ddQEJ06yLX9kkjR16azvxlnEwIHIK73lgWiSFC/gsy2BkE4qpRLxkO62le
# yiYMcRGs+GICsmvfMJw02rWKOQgyz/B5LipwwUC5AgMBAAGjggJZMIICVTALBgNV
# HQ8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFCMX8ABN4YKA
# 2VmKCpidrwZFcbZhMEUGA1UdEQQ+MDykOjA4MR4wHAYDVQQLExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xFjAUBgNVBAUTDTIzMDg1Nis1MDA0MzYwHwYDVR0jBBgwFoAU
# EBoXBhTSBgIdQfjhF3WMQhH4a6Iwgb4GA1UdHwSBtjCBszCBsKCBraCBqoYoaHR0
# cDovL2NvcnBwa2kvY3JsL01TSVQlMjBDQSUyMFoxKDIpLmNybIY/aHR0cDovL21z
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL21zY29ycC9jcmwvTVNJVCUyMENBJTIwWjEo
# MikuY3Jshj1odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL21zY29ycC9jcmwv
# TVNJVCUyMENBJTIwWjEoMikuY3JsMIGLBggrBgEFBQcBAQR/MH0wNAYIKwYBBQUH
# MAKGKGh0dHA6Ly9jb3JwcGtpL2FpYS9NU0lUJTIwQ0ElMjBaMSgyKS5jcnQwRQYI
# KwYBBQUHMAKGOWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvbXNjb3JwL01T
# SVQlMjBDQSUyMFoxKDIpLmNydDA+BgkrBgEEAYI3FQcEMTAvBicrBgEEAYI3FQiH
# 2oZ1g+7ZAYLJhRuBtZ5hhfTrYIFdgZvHJ4aMmUcCAWQCAQwwGwYJKwYBBAGCNxUK
# BA4wDDAKBggrBgEFBQcDAzANBgkqhkiG9w0BAQsFAAOCAgEAY9O9M5muekwNj6Fn
# x0yRoVkQD4X2fe8Iwq/QqUgGLqg12O+C0qQEvT5znQ1KdqL3K+JkazSL2JnxVtlZ
# bdKezIrMpjowW8OCB2137KHIQekUymGvO8AsK2ObaXl93ddhg6G+e+ctjUA02HBp
# qHHHycIHtX92YacyKILAYAYknV/xoW9S/Psc6+Y0N0B5ECrHjnaOgcE8E7dzGzcO
# 0gjtLpSu7wCuMfb6t6uXKWPU0KKeAZ8zogmdFYherPy7LO7bHhz9ImvmWG5K5o4O
# loWY/LQi+e6UZlfG8IOx3uJaV5yW7MbyGZN3ID4Iwt0KXD0L0ckOtHuj8usQJa24
# Chlc3YIFg8IDD2TI/x1rCKVHjcvsnDZgKS4THfYK/zc7tZWw5OAukIqrwN84Rcle
# +biCRGsRCubf4ybONKBLauIjsx9SvRatUVmrFb9/b6Q2Jh6bOyVdjNIVSre0OaZh
# C0F/+5sko9pAUKRslaxUcSBpgTZnJm+W1zJlvp3gY7v1gZo6lGjdf9mgDX57UOXx
# Yf5N9/Q3QAmFOpVoTCqCawa3taIsFDnUcZkqiqhGhoy6JhW+AIwE//qNCcAInFXR
# NPT9NjOEIti+moXvYqNHh46nxnhp/ZLSmTageyCatRoVC+em6bEeVhqpw6otrsxN
# SCdFOk8WtaZMPyPMKT0vQ+OaNYwwggcaMIIFAqADAgECAhNlAAAAYS/15SnDsI3s
# AAAAAABhMA0GCSqGSIb3DQEBCwUAMCwxKjAoBgNVBAMTIU1pY3Jvc29mdCBJbnRl
# cm5hbCBDb3Jwb3JhdGUgUm9vdDAeFw0yMTAzMDQwMzEyMzBaFw0yNTAyMjAwMzEy
# MzBaMBUxEzARBgNVBAMTCk1TSVQgQ0EgWjEwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQDcG7XWS6S9JjSbgAy37HubeIGQ8RUr6gXMizTC+jSfuEHu+xKP
# 9YJoiMKtb6z5vHXEboCpJyNPAb9JFl1W4Bhyu/ZMSlo3zuyHBFNef2nHmXwalNig
# W86m8SmzQDOJ9ahqLP7TbH2RD4a9RV2Poizk6ZlGVEbajNmsWSSocZAZayxcvSvv
# zpicgJ124X+EQ5I27GJX0DtMEVBqp4ZvZFBjn9CiKsVpJtX4MM1IPTj8tCnm8Iql
# qnYo2g3sjoUbTJxa7GevdFrc8AsVOe+ZtKNi1n0zvjHSQzz2b8fnpkqGpclX8LGA
# CrE5FHnheikdpbnuQayzc8CCz/bDps3hpG8V6z9APPrWsePJeW++zcuw9RYw4bYk
# Sy6SgnMvbJhnOIbNvWprEOs1qzrbw1Ebnt/fWOlQqglCJzkQMLW9Gye1dm1Fl6+m
# wCwvDf5SfSoBHARhjaYPFE0MRMaf3ancmfwns4kebYkzzYVbZ+d2utcADdR58+Eq
# 5X52ZPSHw7AkXXNTbecLjBQf+M/CAuJLctwiIkbbO7VHedkCqQtL5/NVl7MKerIh
# CHUMwoOV7c4SfSJLr0nqmuA9h0pHnTyL0k8YDmStD7DVTbhGtD0GAZRazE/zeWB4
# II5o4ldoz1/+QsChP4x/WNGCCnEMLtKH/Gtim0Z39Yvqs9uxX+IkWq/TFwIDAQAB
# o4ICSjCCAkYwEgYJKwYBBAGCNxUBBAUCAwIAAjAjBgkrBgEEAYI3FQIEFgQU2DMF
# WZrs3wWqsEuDdm8BPtZJoeowHQYDVR0OBBYEFBAaFwYU0gYCHUH44Rd1jEIR+Gui
# MGkGA1UdJQRiMGAGCCsGAQUFBwMDBggrBgEFBQcDDgYIKwYBBQUHAwEGBysGAQUC
# AwUGCisGAQQBgjcUAgIGCSsGAQQBgjcVBQYIKwYBBQUHAwIGCisGAQQBgjcqAgUG
# CisGAQQBgjcqAgYwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQD
# AgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0jBBgwFoAU2+wKZKjOwA7piFQO
# 6cjexHhLemEwgaYGA1UdHwSBnjCBmzCBmKCBlaCBkoYgaHR0cDovL2NvcnBwa2kv
# Y3JsL21zaW50Y3JjYS5jcmyGN2h0dHA6Ly9tc2NybC5taWNyb3NvZnQuY29tL3Br
# aS9tc2NvcnAvY3JsL21zaW50Y3JjYS5jcmyGNWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvbXNjb3JwL2NybC9tc2ludGNyY2EuY3JsMHsGCCsGAQUFBwEBBG8w
# bTAsBggrBgEFBQcwAoYgaHR0cDovL2NvcnBwa2kvYWlhL21zaW50Y3JjYS5jcnQw
# PQYIKwYBBQUHMAKGMWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvbXNjb3Jw
# L21zaW50Y3JjYS5jcnQwDQYJKoZIhvcNAQELBQADggIBAHMsjcOQsc8T41D5KWfg
# aox36kg4ax0UliRTA7TXnlthAen26d+RSY7Vi3RXoZb+u4Y2EwnXjAO8iEfN9tqr
# MAQRT8Mmg4bON3nkuAxPK5yEPbBfu5kMgw1k41zKg8q/zE7TMHefAlPPsSWUHHCy
# kAQNDV5WFnm89uoqF8GOGu4gq2Q5MsHWNrwd13EopVLNYaAVmHff2tTI+e29x7QM
# 8P5WJu3O01E1WiY0yZU9lzFy7Hf4MvuLYINKLDXJBg9F2BYpxWeAgVE7tkoQO+Ga
# oaAsMY81YE7uCNW4xTiLmuyg9J7CtXuRUxkLzzzwavW79a2z/GsQUfAX7gUyC5mb
# 2hIWo0cyYpcI5uKjdFaRX5LTJZBBDEVpyn51mcOSD9YWDAZWCoZY94fobcpJJ0sE
# V5J/9fWtRn5KvELUznMCZS+JUgMv9hymkK/uozJCs984743NYM0213EpvvQkVJk1
# ZFSVrG/suG80YO6UaxR/ssLupUaMRWNswvMy30+D0lsYrDfCRUSmOyX5mxqk0X/9
# H6AKhPP6xTL4QtupBbIRI+Sm6jyHnZCMYolkINh1HjC/ASwD0toHPt+2hD8xFrZW
# vFxtQl41vXtZbvyV/b3zQqpfejiaEId2npQA32W6oEdu4DBDnAMrVlvc0q9fIK/i
# nCYhtUEHsxHuVnNlUl0+BVwnMYIZNjCCGTICAQEwLDAVMRMwEQYDVQQDEwpNU0lU
# IENBIFoxAhMTAco/dC5QcPJI+xeWAAIByj90MA0GCWCGSAFlAwQCAQUAoIGwMBkG
# CSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
# AYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCEGDiiT222z3M2U242a5JKT/FD1EGAZwFS
# +J9GJraGmzBEBgorBgEEAYI3AgEMMTYwNKAUgBIATQBpAGMAcgBvAHMAbwBmAHSh
# HIAaaHR0cHM6Ly93d3cubWljcm9zb2Z0LmNvbSAwDQYJKoZIhvcNAQEBBQAEggEA
# TvfqUfr84YSAtXAiLJ05CK92KYSZ99YbnBzZ3veSJjuYkMADv6gLcsIurItJxFMz
# apn6iA+c9LzOgeboLHmMfbUi3UxnmxVXE55kAKPKJ6cSSfDU9p5f2AkC4dVglwEJ
# etDLybyTN6oiFGmJ3j5VdrI+dXD+f+oleXF/UxPX9iZpF0WoFnK9HnBN2NUv0iSN
# r5TWijbpxUVUks9CKz92fg4Pi+YBycH56EhA3zXkvEPQ5Zd4t+0lNgybY1ChMO4F
# u3DTA/aq13RQF5BxOzwQz137u+yxJBxC7MqRz7RY8D0N5swfbF4Ofzn7VrG35YZS
# u6p0UqDJO2sfPdFgluFYIqGCFygwghckBgorBgEEAYI3AwMBMYIXFDCCFxAGCSqG
# SIb3DQEHAqCCFwEwghb9AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsqhkiG9w0B
# CRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUA
# BCA5W7jIvS6+Eyf8/oWcPZnq76emV9Dlwgtt8x/9h3ooVQIGZN5TcwTlGBMyMDIz
# MDkwNjA4NTUwNy42MThaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBP
# cGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjA4NDIt
# NEJFNi1DMjlBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRdzCCBycwggUPoAMCAQICEzMAAAGybkADf26plJIAAQAAAbIwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjIwOTIwMjAy
# MjAxWhcNMjMxMjE0MjAyMjAxWjCB0jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
# cyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjowODQyLTRCRTYtQzI5
# QTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAMqiZTIde/lQ4rC+Bml5f/Wuq/xKTxrf
# bG23HofmQ+qZAN4GyO73PF3y9OAfpt7Qf2jcldWOGUB+HzBuwllYyP3fx4MY8zvu
# AuB37FvoytnNC2DKnVrVlHOVcGUL9CnmhDNMA2/nskjIf2IoiG9J0qLYr8duvHdQ
# J9Li2Pq9guySb9mvUL60ogslCO9gkh6FiEDwMrwUr8Wja6jFpUTny8tg0N0cnCN2
# w4fKkp5qZcbUYFYicLSb/6A7pHCtX6xnjqwhmJoib3vkKJyVxbuFLRhVXxH95b0L
# HeNhifn3jvo2j+/4QV10jEpXVW+iC9BsTtR69xvTjU51ZgP7BR4YDEWq7JsylSOv
# 5B5THTDXRf184URzFhTyb8OZQKY7mqMh7c8J8w1sEM4XDUF2UZNy829NVCzG2tfd
# EXZaHxF8RmxpQYBxyhZwY1rotuIS+gfN2eq+hkAT3ipGn8/KmDwDtzAbnfuXjApg
# eZqwgcYJ8pDJ+y/xU6ouzJz1Bve5TTihkiA7wQsQe6R60Zk9dPdNzw0MK5niRzuQ
# ZAt4GI96FhjhlUWcUZOCkv/JXM/OGu/rgSplYwdmPLzzfDtXyuy/GCU5I4l08g6i
# ifXypMgoYkkceOAAz4vx1x0BOnZWfI3fSwqNUvoN7ncTT+MB4Vpvf1QBppjBAQUu
# vui6eCG0MCVNAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUmfIngFzZEZlPkjDOVluB
# SDDaanEwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgw
# VjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
# cm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUF
# BwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgx
# KS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBANxHtu3FzIabaDbWqswdKBlA
# hKXRCN+5CSMiv2TYa4i2QuWIm+99piwAhDhADfbqor1zyLi95Y6GQnvIWUgdeC7o
# L1ZtZye92zYK+EIfwYZmhS+CH4infAzUvscHZF3wlrJUfPUIDGVP0lCYVse9mguv
# G0dqkY4ayQPEHOvJubgZZaOdg/N8dInd6fGeOc+0DoGzB+LieObJ2Q0AtEt3XN3i
# X8Cp6+dZTX8xwE/LvhRwPpb/+nKshO7TVuvenwdTwqB/LT6CNPaElwFeKxKrqRTP
# MbHeg+i+KnBLfwmhEXsMg2s1QX7JIxfvT96md0eiMjiMEO22LbOzmLMNd3LINowA
# nRBAJtX+3/e390B9sMGMHp+a1V+hgs62AopBl0p/00li30DN5wEQ5If35Zk7b/T6
# pEx6rJUDYCti7zCbikjKTanBnOc99zGMlej5X+fC/k5ExUCrOs3/VzGRCZt5LvVQ
# SdWqq/QMzTEmim4sbzASK9imEkjNtZZyvC1CsUcD1voFktld4mKMjE+uDEV3IddD
# +DrRk94nVzNPSuZXewfVOnXHSeqG7xM3V7fl2aL4v1OhL2+JwO1Tx3B0irO1O9qb
# NdJk355bntd1RSVKgM22KFBHnoL7Js7pRhBiaKmVTQGoOb+j1Qa7q+cixGo48Vh9
# k35BDsJS/DLoXFSPDl4mMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAA
# FTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0
# aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9s
# SuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3
# po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2
# vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GP
# sjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3
# rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDP
# c31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8F
# A6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q
# 6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1f
# MHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLv
# jflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGj
# ggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+
# ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIw
# XAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsG
# A1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJc
# YmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9z
# b2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIz
# LmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0
# MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5H
# ZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2
# HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1
# JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8
# F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99J
# o3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4K
# WN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZ
# kWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58
# oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w
# /ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+
# 7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1iz
# oXBm8qGCAtMwggI8AgEBMIIBAKGB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjowODQyLTRC
# RTYtQzI5QTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIj
# CgEBMAcGBSsOAwIaAxUAjhJ+EeySRfn2KCNsjn9cF9AUSTqggYMwgYCkfjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOih3G4w
# IhgPMjAyMzA5MDYwMDU3MThaGA8yMDIzMDkwNzAwNTcxOFowczA5BgorBgEEAYRZ
# CgQBMSswKTAKAgUA6KHcbgIBADAGAgEAAgFrMAcCAQACAhI5MAoCBQDooy3uAgEA
# MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAI
# AgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAXUHIDBvE34d0QbGiVf3vQsz3dJ2a
# tcrRJNwD159WfDbmTMuW5vT0+oP7nq/pmgm8mohgNfnoymxogsHmfgw6i+TPBpW0
# Mgwugxm33ZBLnPZ9exwYv8r9DM+TFzo1C/UZdxPNG3ZTVk0D6UurDLAHhbWLvlm9
# 2NGPCSRSo+Ax5YkxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMAITMwAAAbJuQAN/bqmUkgABAAABsjANBglghkgBZQMEAgEFAKCCAUow
# GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCAsP6Bj
# azp9OhR9anfhErUyWcr65LlPWyb6rp0cTZk1ozCB+gYLKoZIhvcNAQkQAi8xgeow
# gecwgeQwgb0EIFN4zjzn4T63g8RWJ5SgUpfs9XIuj+fO76G0k8IbTj41MIGYMIGA
# pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGybkADf26plJIA
# AQAAAbIwIgQg5ZzsnuKaTMlWC3kHMiePEspL8xDIQkccMXMFCPm2XIUwDQYJKoZI
# hvcNAQELBQAEggIAbrwV07rBD7aJYDEPMoMf1dvAigFGj+d/9aUAjx9TuIrfT3Fw
# wL71QB7kAApU+DTlutQY38RVZri4LYm+AaAvWU4MK+5IGuTBBdkJvts0nN1swNPO
# 71mB91bfc9w/oqZys9BuuaVQvsUKytjtNvGh7qQfOgIgYeiP1M0jq76HNYF0QgF0
# bpsIf8Clnjw+T/LJwaSDCfbbrd3k3JZ9X00yDJLlgyAJy1Anw5OgB0fhui+Dh5mA
# N+RqIPdh1kECy2tGM5N4w6Ylr22hHccCj7i7yXZRUpJWGFjswYwmp+llqM2NyBjt
# apRMkOzaBylMJ7Ym4zfKmbtwPyoMxbl0CqwmTOudgUOmjnOTJgkajL1O8yq19hLP
# qudqjl4koFv4bYoMCDuN9fZmFpxsHJt7wH7ueTN6ddsZrAvWEFwMi0pzGxY3Xna+
# xLCq1blDjOTRkT2VPFHt7El01iYx19gdxt9IBertU6Onxd8DeUDb0aPFzVoG3Hy+
# gHfMZfkrNwOuXCEx0Mm8EpHTGrXqSpH8tlVNpisv6iqIMLdQdIwtDQLCwD6eH/MP
# tGuJK1aIbAzDT615Ep7pD4OCqOe8B7z99sNETkyAiUSX1WJKLbn6JainMVFGTvn2
# IfoPvVHhKzj8wxhAGXQuzc8bU8I++C+SPgP2Cgs5DbpB5pMUiLCPT3UA14M=
# SIG # End signature block
