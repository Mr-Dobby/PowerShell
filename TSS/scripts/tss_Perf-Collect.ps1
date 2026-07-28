<# File tss_Perf-Collect.ps1 [Folderpath]
#>

param(
	[string]$Folderpath = (Split-Path $MyInvocation.MyCommand.Path -Parent)
)

#region  ::::: Configruation parameters ----------------------------------------------#
$VerDate = "2021.04.30.0"
#endregion ::::: Configruation parameters --------------------------------------------#

#region  [Initialisations] -----------------------------------------------------------#

$version = "Perf-Collect (20180307) v" + $VerDate
# by Gianni Bragante - gbrag@microsoft.com
# mod by WalterE 2021-04-30

Function Write-Log {
  param( [string] $msg )
  $msg = (get-date).ToString("yyyyMMdd HH:mm:ss.fff") + " " + $msg
  Write-Host $msg
  $msg | Out-File -FilePath $outfile -Append
}

Function ExecQuery {
  param(
    [string] $NameSpace,
    [string] $Query
  )
  Write-Log ("Executing query " + $Query)
  if ($PSVersionTable.psversion.ToString() -ge "3.0") {
    $ret = Get-CimInstance -Namespace $NameSpace -Query $Query -ErrorAction Continue 2>>$errfile
  } else {
    $ret = Get-CimInstance -Namespace $NameSpace -Query $Query -ErrorAction Continue 2>>$errfile
  }
  Write-Log (($ret | Measure-Object).count.ToString() + " results")
  return $ret
}

$tbPerfV1 = New-Object system.Data.DataTable “Perf”
$col = New-Object system.Data.DataColumn Name,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn Open,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn Close,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn Collect,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn Library,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn InstallType,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn PerfIniFile,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn IniExists,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn Disabled,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn FirstCounter,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn FirstHelp,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn LastCounter,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn LastHelp,([string])
$tbPerfV1.Columns.Add($col)
$col = New-Object system.Data.DataColumn ObjectList,([string])
$tbPerfV1.Columns.Add($col)

$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
  Write-Output "This script needs to be run as Administrator"
  #exit
}

if ($Folderpath) { $Root = $Folderpath }
else { $Root = Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path }

$resName = "Perf-" + $env:computername +"-" + $(get-date -f yyyyMMdd_HHmmss)
$resDir = $Root + "\" + $resName
$outfile = $resDir + "\script-output.txt"
$errfile = $resDir + "\script-errors.txt"
$RdrOut =  " >>""" + $outfile + """"
$RdrErr =  " 2>>""" + $errfile + """"
$SysInfoFile = ($resDir + "\SystemInfo.txt")

New-Item -itemtype directory -path $resDir | Out-Null

Write-Log $version 

$cult = Get-Culture
$cultHex = ('{0:X4}' -f $cult.LCID)

Copy-Item ($env:SystemRoot + "\system32\perfc*.dat") $resDir
Copy-Item ($env:SystemRoot + "\system32\perfd*.dat") $resDir
Copy-Item ($env:SystemRoot + "\system32\perfh*.dat") $resDir
Copy-Item ($env:SystemRoot + "\system32\perfi*.dat") $resDir

(get-itemproperty -ErrorAction SilentlyContinue -literalpath ("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage")).Counter | Out-File ($resDir + "\Counter.txt")
(get-itemproperty -ErrorAction SilentlyContinue -literalpath ("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage")).Help | Out-File ($resDir + "\Help.txt")

Write-Log "Exporting registry key HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services"
$cmd = "reg export ""HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services"" """ + $resDir + "\Services.reg.txt"" /y " + $RdrOut + $RdrErr
Write-Log $cmd
Invoke-Expression $cmd

Write-Log "Exporting registry key HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib"
$cmd = "reg export ""HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib"" """ + $resDir + "\Perflib.reg.txt"" /y " + $RdrOut + $RdrErr
Write-Log $cmd
Invoke-Expression $cmd

Write-Log "Saving registry key HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib"
$cmd = "reg save ""HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib"" """ + $resDir + "\Perflib.hiv"" /y " + $RdrOut + $RdrErr
Write-Log $cmd
Invoke-Expression $cmd

Write-Log "Exporting registry key HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup"
$cmd = "reg export ""HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup"" """ + $resDir + "\FWSetup.reg.txt"" /y " + $RdrOut + $RdrErr
Write-Log $cmd
Invoke-Expression $cmd

$svc = "HKLM:\SYSTEM\CurrentControlSet\Services"
New-PSDrive -PSProvider registry -Root HKEY_LOCAL_MACHINE -Name HKLM -ErrorAction SilentlyContinue | Out-Null
$Keys = Get-ChildItem $svc
ForEach ($Item in $Keys) {
  $perf = ($svc + "\" + $item.PSChildName + "\Performance")
  $reg = Get-ItemProperty $perf -ErrorAction SilentlyContinue
  if ($reg) {    
    Write-Log $item.PSChildName

    $row = $tbPerfV1.NewRow()

    if ($reg.PerfIniFile) {
      $inipath = ($env:windir + "\INF\" + $item.PSChildName + "\" + $cultHex + "\" + $reg.PerfIniFile).TrimEnd([char]0)
      if (Test-Path $inipath) {
        $row.IniExists = "Yes"
      } else {
        $row.IniExists = "No"
      }
    } else {
      $row.IniExists = ""
    }

    $row.Name = $item.PSChildName
    $row.Open = $reg.Open
    $row.Close = $reg.Close
    $row.Collect = $reg.Collect
    $row.Library = $reg.Library
    $row.InstallType = $reg.InstallType
    $row.PerfIniFile = $reg.PerfIniFile
    $row.Disabled = $reg.'Disable Performance Counters'
    $row.FirstCounter = $reg.'First Counter'
    $row.FirstHelp = $reg.'First Help'
    $row.LastCounter = $reg.'Last Counter'
    $row.LastHelp = $reg.'Last Help'
    $row.ObjectList = $reg.'Object List'
    $tbPerfV1.Rows.Add($row)
  }
}
$tbPerfV1 | Export-Csv $resDir"\PerfV1.csv" -noType

Write-Log "Enumerating performance counters"
$cmd = "typeperf.exe -q > """ + $resDir + "\typeperf.txt""" + $RdrErr
Write-Log $cmd
Invoke-Expression ($cmd) | Out-File -FilePath $outfile -Append

Write-Log "Enumerating performance counters with instances"
$cmd = "typeperf.exe -qx > """ + $resDir + "\typeperf-inst.txt""" + $RdrErr
Write-Log $cmd
Invoke-Expression ($cmd) | Out-File -FilePath $outfile -Append

Write-Log "Enumerating 32bit performance counters"
$cmd = $env:windir + "\SysWOW64\typeperf.exe -q > """ + $resDir + "\typeperf32.txt""" + $RdrErr
Write-Log $cmd
Invoke-Expression ($cmd) | Out-File -FilePath $outfile -Append

Write-Log "Enumerating 32bit performance counters"
$cmd = $env:windir + "\SysWOW64\typeperf.exe -qx > """ + $resDir + "\typeperf32-inst.txt""" + $RdrErr
Write-Log $cmd
Invoke-Expression ($cmd) | Out-File -FilePath $outfile -Append

Write-Log "Enumerating WMI performance classes"
Get-CimInstance -Query "select * from meta_class where __CLASS like '%Win32_Perf%'" | Select-Object -Property __CLASS | Sort-Object -Property __CLASS | Out-File ($resDir + "\WMIPerfClasses.txt")

<# #_# 2021-04-30
Write-Log "Exporting Application log"
$cmd = "wevtutil epl Application """+ $resDir + "\" + $env:computername + "-Application.evtx""" + $RdrOut + $RdrErr
Write-Log $cmd
Invoke-Expression $cmd

Write-Log "Exporting System log"
$cmd = "wevtutil epl System """+ $resDir + "\" + $env:computername + "-System.evtx""" + $RdrOut + $RdrErr
Write-Log $cmd
Invoke-Expression $cmd
#>

Write-Log "Collecting system information"
$pad = 27
$OS = ExecQuery -Namespace "root\cimv2" -Query "select Caption, CSName, OSArchitecture, BuildNumber, InstallDate, LastBootUpTime, LocalDateTime, TotalVisibleMemorySize, FreePhysicalMemory, SizeStoredInPagingFiles, FreeSpaceInPagingFiles from Win32_OperatingSystem"
$CS = ExecQuery -Namespace "root\cimv2" -Query "select Model, Manufacturer, SystemType, NumberOfProcessors, NumberOfLogicalProcessors, TotalPhysicalMemory, DNSHostName, Domain from Win32_ComputerSystem"
$BIOS = ExecQuery -Namespace "root\cimv2" -query "select BIOSVersion, Manufacturer, ReleaseDate, SMBIOSBIOSVersion from Win32_BIOS"
$TZ = ExecQuery -Namespace "root\cimv2" -Query "select Description from Win32_TimeZone"
$PR = ExecQuery -Namespace "root\cimv2" -Query "select Name, Caption from Win32_Processor"


"Computer name".PadRight($pad) + " : " + $OS.CSName | Out-File -FilePath $SysInfoFile -Append
"Model".PadRight($pad) + " : " + $CS.Model | Out-File -FilePath $SysInfoFile -Append
"Manufacturer".PadRight($pad) + " : " + $CS.Manufacturer | Out-File -FilePath $SysInfoFile -Append
"BIOS Version".PadRight($pad) + " : " + $BIOS.BIOSVersion | Out-File -FilePath $SysInfoFile -Append
"BIOS Manufacturer".PadRight($pad) + " : " + $BIOS.Manufacturer | Out-File -FilePath $SysInfoFile -Append
"BIOS Release date".PadRight($pad) + " : " + $BIOS.ReleaseDate | Out-File -FilePath $SysInfoFile -Append
"SMBIOS Version".PadRight($pad) + " : " + $BIOS.SMBIOSBIOSVersion | Out-File -FilePath $SysInfoFile -Append
"SystemType".PadRight($pad) + " : " + $CS.SystemType | Out-File -FilePath $SysInfoFile -Append
"Processor".PadRight($pad) + " : " + $PR.Name + " / " + $PR.Caption | Out-File -FilePath $SysInfoFile -Append
"Processors physical/logical".PadRight($pad) + " : " + $CS.NumberOfProcessors + " / " + $CS.NumberOfLogicalProcessors | Out-File -FilePath $SysInfoFile -Append
"Memory physical/visible".PadRight($pad) + " : " + ("{0:N0}" -f ($CS.TotalPhysicalMemory/1mb)) + " MB / " + ("{0:N0}" -f ($OS.TotalVisibleMemorySize/1kb)) + " MB" | Out-File -FilePath $SysInfoFile -Append
"Free physical memory".PadRight($pad) + " : " + ("{0:N0}" -f ($OS.FreePhysicalMemory/1kb)) + " MB" | Out-File -FilePath $SysInfoFile -Append
"Paging files size / free".PadRight($pad) + " : " + ("{0:N0}" -f ($OS.SizeStoredInPagingFiles/1kb)) + " MB / " + ("{0:N0}" -f ($OS.FreeSpaceInPagingFiles/1kb)) + " MB" | Out-File -FilePath $SysInfoFile -Append
"Operating System".PadRight($pad) + " : " + $OS.Caption + " " + $OS.OSArchitecture | Out-File -FilePath $SysInfoFile -Append
"Build Number".PadRight($pad) + " : " + $OS.BuildNumber | Out-File -FilePath $SysInfoFile -Append
"Time zone".PadRight($pad) + " : " + $TZ.Description | Out-File -FilePath $SysInfoFile -Append
"Install date".PadRight($pad) + " : " + $OS.InstallDate | Out-File -FilePath $SysInfoFile -Append
"Last boot time".PadRight($pad) + " : " + $OS.LastBootUpTime | Out-File -FilePath $SysInfoFile -Append
"Local time".PadRight($pad) + " : " + $OS.LocalDateTime | Out-File -FilePath $SysInfoFile -Append
"DNS Hostname".PadRight($pad) + " : " + $CS.DNSHostName | Out-File -FilePath $SysInfoFile -Append
"Domain".PadRight($pad) + " : " + $CS.Domain | Out-File -FilePath $SysInfoFile -Append

# SIG # Begin signature block
# MIInzgYJKoZIhvcNAQcCoIInvzCCJ7sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA0cNPmmhStC95x
# YKdwoFt/XvVwVaxYdhBURvHmGXzP5KCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGZ8wghmbAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKSv
# 7Kn0dJWgF1vEqG3//k6psvxkb02BVkZ7BEcHc5EqMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEA6GpWRScNOfdgXRBpyrKSewyBucd+tsq/LYF9
# 5HQKO7bBJI+B71JNHdYATTVcxr9faAMkiVk/orQTxkipqqHhbBTiXko4D42VJyvn
# 7YthUd23s4laX9BOvae0Ia6YX5ACp0V2Ff6pKmVLnDfsaZ1wLkid/N5Wk7keOp0C
# WW6KiSgTJ7d8KpXUE+D1HO6/UTrHZnb/K59ntP6TYqM7ebZo6lKoy+2MRqSrN3+m
# qVBq4KQftpFtatNhy5QeSqyoa76jx597Q0iIYvZCufQ45bsYMLGWJq4m7FCnUMya
# yYLOfIDRMz4fPt+F+vIyZj0rzfbVc9MiPn6voTOAkaiHPycv5qGCFykwghclBgor
# BgEEAYI3AwMBMYIXFTCCFxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFZBgsqhkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCD1lCWOTr+JjFeLWpMS0aKgf43rVSWiQO2z
# WF6F4hvI2AIGZldTgNdfGBMyMDI0MDYxMjE1MDA0MC41NThaMASAAgH0oIHYpIHV
# MIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOkZDNDEtNEJENC1EMjIwMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHimZmV
# 8dzjIOsAAQAAAeIwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwHhcNMjMxMDEyMTkwNzI1WhcNMjUwMTEwMTkwNzI1WjCB0jELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9z
# b2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjpGQzQxLTRCRDQtRDIyMDElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALVj
# tZhV+kFmb8cKQpg2mzisDlRI978Gb2amGvbAmCd04JVGeTe/QGzM8KbQrMDol7DC
# 7jS03JkcrPsWi9WpVwsIckRQ8AkX1idBG9HhyCspAavfuvz55khl7brPQx7H99UJ
# bsE3wMmpmJasPWpgF05zZlvpWQDULDcIYyl5lXI4HVZ5N6MSxWO8zwWr4r9xkMmU
# Xs7ICxDJr5a39SSePAJRIyznaIc0WzZ6MFcTRzLLNyPBE4KrVv1LFd96FNxAzwne
# tSePg88EmRezr2T3HTFElneJXyQYd6YQ7eCIc7yllWoY03CEg9ghorp9qUKcBUfF
# cS4XElf3GSERnlzJsK7s/ZGPU4daHT2jWGoYha2QCOmkgjOmBFCqQFFwFmsPrZj4
# eQszYxq4c4HqPnUu4hT4aqpvUZ3qIOXbdyU42pNL93cn0rPTTleOUsOQbgvlRdth
# FCBepxfb6nbsp3fcZaPBfTbtXVa8nLQuMCBqyfsebuqnbwj+lHQfqKpivpyd7KCW
# ACoj78XUwYqy1HyYnStTme4T9vK6u2O/KThfROeJHiSg44ymFj+34IcFEhPogaKv
# NNsTVm4QbqphCyknrwByqorBCLH6bllRtJMJwmu7GRdTQsIx2HMKqphEtpSm1z3u
# fASdPrgPhsQIRFkHZGuihL1Jjj4Lu3CbAmha0lOrAgMBAAGjggFJMIIBRTAdBgNV
# HQ4EFgQURIQOEdq+7QdslptJiCRNpXgJ2gUwHwYDVR0jBBgwFoAUn6cVXQBeYl2D
# 9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
# LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQAD
# ggIBAORURDGrVRTbnulfsg2cTsyyh7YXvhVU7NZMkITAQYsFEPVgvSviCylr5ap3
# ka76Yz0t/6lxuczI6w7tXq8n4WxUUgcj5wAhnNorhnD8ljYqbck37fggYK3+wEwL
# hP1PGC5tvXK0xYomU1nU+lXOy9ZRnShI/HZdFrw2srgtsbWow9OMuADS5lg7okrX
# a2daCOGnxuaD1IO+65E7qv2O0W0sGj7AWdOjNdpexPrspL2KEcOMeJVmkk/O0gan
# hFzzHAnWjtNWneU11WQ6Bxv8OpN1fY9wzQoiycgvOOJM93od55EGeXxfF8bofLVl
# UE3zIikoSed+8s61NDP+x9RMya2mwK/Ys1xdvDlZTHndIKssfmu3vu/a+BFf2uIo
# ycVTvBQpv/drRJD68eo401mkCRFkmy/+BmQlRrx2rapqAu5k0Nev+iUdBUKmX/iO
# aKZ75vuQg7hCiBA5xIm5ZIXDSlX47wwFar3/BgTwntMq9ra6QRAeS/o/uYWkmvqv
# E8Aq38QmKgTiBnWSS/uVPcaHEyArnyFh5G+qeCGmL44MfEnFEhxc3saPmXhe6MhS
# gCIGJUZDA7336nQD8fn4y6534Lel+LuT5F5bFt0mLwd+H5GxGzObZmm/c3pEWtHv
# 1ug7dS/Dfrcd1sn2E4gk4W1L1jdRBbK9xwkMmwY+CHZeMSvBMIIHcTCCBVmgAwIB
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
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAtQwggI9AgEBMIIBAKGB2KSB1TCB
# 0jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMk
# TWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjpGQzQxLTRCRDQtRDIyMDElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAFpuZafp0bnpJdIhf
# iB1d8pTohm+ggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOoTm/4wIhgPMjAyNDA2MTIxMjAxMDJaGA8yMDI0MDYx
# MzEyMDEwMlowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6hOb/gIBADAHAgEAAgIU
# +DAHAgEAAgISGTAKAgUA6hTtfgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
# AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GB
# AJ/FJuetAVWJI9zIVgs/G6PJb2Htizs7thkptzHLKrRyIkqJv/q6dRq8CoHs3W9P
# BVpwGoeYDNFqHTXGjcScJjSLFlL8KdtZ2Xe1nwjxChR8Ta+kTgfbll+of7DjBs4h
# ou5X0dKwo0yyYMSYERBYeeIbZsDaI5CElxB95kDskp2pMYIEDTCCBAkCAQEwgZMw
# fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHimZmV8dzjIOsAAQAA
# AeIwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAvBgkqhkiG9w0BCQQxIgQgSN29J+YcN1Xf/y1lojGtDl/Uv5UXmxfYbQoDyR8c
# c1IwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAriSpKEP0muMbBUETODoL4
# d5LU6I/bjucIZkOJCI9//zCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAAB4pmZlfHc4yDrAAEAAAHiMCIEIFXEVszJvDLGPe6VS+bkhFGz
# m96spv2wtK27KDsu4aKpMA0GCSqGSIb3DQEBCwUABIICAATANfOW6mY9bIN6MkQ4
# 8M3y3mXH8n2rimjMXO1i1CmUC7+qsL/LCkJo8RsRmbwVNK+XA/yjxb1UdLzWHPw2
# RRuiuZlD+ooKeZww0ECDnXW/IIoBrtm9cFKGJxwG+ycfJLZ/h/JLwUfeyKLw+UlC
# +K4P+jBaYEddKV4t9sSjoPy2u2iNhIzqXH6kGnaevW085mkF3AVYccQK4NaeYb5Y
# 7/iBVEu1Bto3v0NXPn9+BRyXf+hd4NWtIuK6wZKQfbxx2vdJxbh2L/I72vm0AxhP
# wdxXnlrqtylg3tUr9g8KPgHejN09QUoUL2nKhIwZiYh7LJJX+5qplY7j2V0WeayI
# CyB+NgmCEVCgG8qWjPxplniK3+PiUC/Bvmi8ZpGaboheApET6Sa+RGbjsjnSPqdV
# SVlvJzoeGqqcfDgbuMUpnnElFMrSzwZqQNPJoD6ZK8N5rRY4T4DMNA7p2IHqXdYs
# o/fE3d1+kPZo1FVGArTxBZE3ltzfLrR57r2PFmoGNZUQA8Fup1+VhZPdlAm48+C+
# ph+S1Yk4XdXnLB0pHO9/dzoWLig1oqlLGEIBV6ibuSjF5f45DU9wynAdmgmkSeOK
# QKqg93Vus9F+frwD6RYeh4LDWRUQNwEShWKkmnxJqBrVz7K+fhRMXuFXXGPLLmIq
# aWthX8Z/rnc3t4XGaYQFOv5Z
# SIG # End signature block
