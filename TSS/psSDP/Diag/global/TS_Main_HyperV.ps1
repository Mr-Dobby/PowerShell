# Load Common Library
# Load Reporting Utilities
#$debug = $false

. ./utils_cts.ps1
. ./TS_RemoteSetup.ps1

# 2023-02-20 WalterE mod Trap #we#
trap [Exception]{
	WriteTo-StdOut "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $_" -shortformat; continue
	Write-Host "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $_"
}

$FirstTimeExecution = FirstTimeExecution

if ($FirstTimeExecution) {
	if (Test-Path 'HKLM:\Cluster'){
		#_#[Array] $NodeNames = .\TS_SelectClusterNodes.ps1
		[Array] $NodeNames = (Get-ClusterNode -ErrorAction SilentlyContinue | where-object {$_.State -match "up"}).Nodename  #_# -EA added 2020-08-20
		if (-not $NodeNames) {$NodeNames = $ComputerName}	#_#added 2020-08-20
	}else{
		$NodeNames = $ComputerName
	}
	if ($Global:localNodeOnly -ne $true) {
		if ($null -ne $NodeNames) {
			$ExpressionArray = @()
			$ItemNumber = 0	
			
			$ExpressionToRunOnMachine = @'
			Run-DiagExpression .\DC_BasicSystemInformation.ps1 -MachineName $Env:COMPUTERNAME
			Run-DiagExpression .\DC_ClusterLogs.ps1 #_#-LocalOnly
			Run-DiagExpression .\TS_DumpCollector.ps1 -CopyWERMinidumps -CopyWERFulldumps -CopyOnlyUserDumpsFrom "vmms.exe" -SkipAlertsForCategories "machinedumpconfig"
			.\TS_AutoAddCommands_HyperV.ps1
			Run-DiagExpression .\DC_SummaryReliability.ps1
'@	

			#_#if (($NodeNames.Count -eq 1) -and ($NodeNames[0] = $ComputerName))
			if (($NodeNames -is [string]) -or (($NodeNames.Count -eq 1) -and ($NodeNames[0] -eq $ComputerName))){
				if ($NodeNames.Count -eq 1){
					$ExpressionToRunOnMachine += "`r`n Run-DiagExpression .\TS_BasicClusterInfo.ps1"
				}
				Invoke-Expression $ExpressionToRunOnMachine
			}else{
				foreach ($MachineName in $NodeNames){
					if ($ItemNumber -eq 0) {
						#Execute TS_BasicClusterInfo only in one node
						$ExpressionArray += ($ExpressionToRunOnMachine + "`r`n Run-DiagExpression .\TS_BasicClusterInfo.ps1")
					}else{
						$ExpressionArray += $ExpressionToRunOnMachine
					}
					$ItemNumber += 1
				}
				"Running package using TS_Remote on $NodeNames" | WriteTo-StdOut -ShortFormat #_#
				#_#ExecuteRemoteExpression -ComputerNames $NodeNames -Expression $ExpressionArray -ShowDialog
				ExecuteRemoteExpression -ComputerNames $NodeNames -Expression $ExpressionArray
			}
			if ($NodeNames -contains $ComputerName){
				#TS_ClusterValidationTests.ps1 can be executed only locally due the issue with double hop authentication.
				"Running ClusterValidationTests on $ComputerName" | WriteTo-StdOut -ShortFormat #_#
				Run-DiagExpression .\TS_ClusterValidationTests.ps1
			}
		}
	}else{ # run on localNodeOnly
		"User/script selected localNodeOnly. Running package locally instead of using TS_Remote" | WriteTo-StdOut -ShortFormat
		"User/script selected localNodeOnly." | Write-host
		Run-DiagExpression .\TS_BasicClusterInfo.ps1
		Run-DiagExpression .\DC_BasicSystemInformation.ps1 -MachineName $Env:COMPUTERNAME
		Run-DiagExpression .\DC_ClusterLogs.ps1 #_#-LocalOnly
		.\TS_AutoAddCommands_HyperV.ps1
		Run-DiagExpression .\DC_SummaryReliability.ps1
		"Running ClusterValidationTests on $ComputerName" | WriteTo-StdOut -ShortFormat #_#
		Run-DiagExpression .\TS_ClusterValidationTests.ps1
		if ($Global:skipNetview -ne $true) {
			Write-Host -BackgroundColor Gray -ForegroundColor Black -Object "--- $(Get-Date -Format 'HH:mm:ss') ...Start of Get-NetView (to skip this step, use skipNetview)"
			& "$global:ToolsPath`\GetNetView.ps1" -OutputDirectory $global:savePathTmp
			Write-Host -BackgroundColor Gray -ForegroundColor Black -Object "--- $(Get-Date -Format 'HH:mm:ss') ...  End of Get-NetView"
		}
		if ($Global:skipSddcDiag -ne $true) {
			if ((test-path variable:psversiontable) -and ($PSVersionTable.PSVersion.Major -ge 5)) {
				#-# PrivateCloud.DiagnosticInfo
				Write-Host -BackgroundColor Gray -ForegroundColor Black -Object "--- $(Get-Date -Format 'HH:mm:ss') ... Start of SddcDiagnostic"
				& "$global:ToolsPath`\GetSddcDiagnosticInfo.ps1" -WriteToPath $($global:savePath + "\HealthTest") -ZipPrefix $($global:savePathTmp + "\_Sddc-Diag")
				Write-Host -BackgroundColor Gray -ForegroundColor Black -Object "--- $(Get-Date -Format 'HH:mm:ss') ...  End of SddcDiagnostic"
			}
		}
	}
	EndDataCollection

}else{
	#2nd execution. Delete the temporary flag file then exit
	EndDataCollection -DeleteFlagFile $True
}


# SIG # Begin signature block
# MIInlQYJKoZIhvcNAQcCoIInhjCCJ4ICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBrWd1BPgHgxLwi
# AMdN7Yrf/rr+kLxK66XV7FA6vEH6GaCCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGXUwghlxAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAANOtTx6wYRv6ysAAAAAA04wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMmC1Q1fCJs2DC9nEJaNAxm0
# C5cWj7Al4khwyeWoqi+AMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCmKYyswRpnu3P4IxzEYVNH1D3aeWyzv1g0sbQim7KOJF7BMhik9Yi7
# 2HlOjgVp8NvrSP6GCn68XubMH3a6iGUR9EfZSfG+PC3vqNIN07nvAa/lPDpZGMjT
# r/gcZ35+oR153gR2PlJaQIMx0/pbvOBRWcsQLTcLjevaS9NRn6JbBNf+VacDMj8p
# pla/nVfloWr+fhT7S8M7kTKVB5856uVnMu22OdyKh7GaY5P8mITU48AVa8xxS2Mu
# OL8ADuiriMalo6hHUhCj+OS2uoBGcIOs4iC+ps2j1oYl80mpvTKcG92vwlHBxoWw
# a8zNTkPBaTeAnsPc/mYBYWWJH/4S0LHhoYIW/TCCFvkGCisGAQQBgjcDAwExghbp
# MIIW5QYJKoZIhvcNAQcCoIIW1jCCFtICAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIGT6AbHrGzg7UzLsJp4JA5lPJGMFe/2Fo6Z0wdC9K1C9AgZki1CJ
# McYYEzIwMjMwNjI4MTkwNTEyLjc5M1owBIACAfSggdCkgc0wgcoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkU1QTYt
# RTI3Qy01OTJFMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRVDCCBwwwggT0oAMCAQICEzMAAAG+9CCi7pbWINYAAQAAAb4wDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjIxMTA0MTkw
# MTIyWhcNMjQwMjAyMTkwMTIyWjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTVBNi1FMjdDLTU5MkUxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQClX/LbPsNrucy7S3KQtjyiWHtnTcSoU3PeIWUyn2A5
# 9WZkAGaF4JzztG491DY/44dQmKoJABY241Kgj9DWLETD0ADrnuV0Pxnf8SS2mbEo
# cdq86HBBIU9ylMYVVcjEoLCg7zbiCLIc8bzh1+F2LpZTt/sP7zkto8HR06w8coow
# aUL2nrou/3JDO8CFkYWYWGW6wLL96CvPolf84c5P2oLC6CGsvQg9/jtQt7WlBIQS
# KHLjfwnBL6tlTgBXK9BzOUwLbpexO4M+ARAqXPH2u7sS81X32X8oJT1tsV/lKeQ3
# WahSApSrT01aUrHMsYS+GR7ZA0yimfzomHV+X89V683/GtlKlXbesziUHuWHtdKw
# I94WyVNiiMo3aKg4LqncHLuQSa9kKHqsCw8qwBEkhJ3MpAIyr6aoO6I/qav8u+5Y
# qKc/7ZkaYr8LX+yS+VOO0h6G7nTKhc0OWHUI30HdAuCVBj5QIESomiD8HECfelZ1
# HTWj/rpchpyBcj93TAbb/HQ61uMQYCRpx9CWbDRsNzTZ2FAWSL/VD1VvCHiQLtWA
# CIkDxsLnMQhhYc1TsL4d7r0Hj/Z1mlGOB3mkSkdsX05iIB/uzkydgScc3/mj9sY7
# RqMBvtUjh/1q/rawLrG+EpMHlHiWHEQxYXTPi/sFDkIfIw2Qv6hOfMkuqctV1ee4
# zQIDAQABo4IBNjCCATIwHQYDVR0OBBYEFOsqIBahhEGg8a1vC9uGFfprb6KqMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQAD
# ggIBAMeV+71zQiaF0GKzXKPnpsG85LIakL+tJK3L7UXj1N/p+YUR6rGHBNMdUc54
# hE13yBwMtLPR3v2ZcKqrzKerqAmDLa7gvLICvYubDMVW67GgZVHxi5SdG2+wMfkn
# 66fJ7+cyTAeIL4bzaHe5Dx9waP7YfSco+ZSlS19Cu4xRe/MuNXk3JGMOIIvlz9/l
# 5ybPTV2emcK8TqQjP8VOmS855UmTbYjZqQVmE/PbgPo5PoqRO3AFGlIQcNioJDhx
# n7tJfHuPPN3tv7Sn28NuioLLtLBaAqkZAb7BVsqtObiEqRkPNx0ASBip6FfPvwbT
# SZgguINPJSKTBCmhntqb2kDoF1M9j6jW/oJHNyd4g6clhqcdbPRH4oRH9lEW0sLI
# Ey8vNIcSfSxHT7SQuSWdwqMZ0DVgDjbM5vrXVR4gbK1n1WE3CfjCzkYnqfo8mYw8
# 77I8SQ7LZ/w4GK6FqqWKmJaHMa23lSwLSB4bSxb2rBrhABbWxBYiuFKXbgw45XA2
# X8Cb39mq8tFavXHie6l5Hwbv4M3KfgxODbzIVlFTWS1K/IExRK83Yr30E7qnWBLH
# /C9KxHjl0bfc8Mbl8qoc6APFy2MFTltfj14mqM0vtL9Sd0sXtLQ5Yv2Z2T+M9Uc/
# Yjpe03QrhWN1HC8iCveM2JvcZnIYmc5Gn9kxtjYO/WYpzHt1MIIHcTCCBVmgAwIB
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
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAsswggI0AgEBMIH4oYHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjpFNUE2LUUyN0MtNTkyRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAaK1aUve8+7wQ04B76Lb7jB9MwHug
# gYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
# AQUFAAIFAOhG8ZgwIhgPMjAyMzA2MjkwMTUxMjBaGA8yMDIzMDYzMDAxNTEyMFow
# dDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6EbxmAIBADAHAgEAAgIE7jAHAgEAAgIS
# vTAKAgUA6EhDGAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAow
# CAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAGUsLKfYGdg+
# /BCpi1N/AU0v2VJrti5sj6qGY+5ycFnjUU+fyk9lbyzO+uQMo9mdJVK4UAnxjzPj
# InPRSDmG8rOe9NHxqx6fTMkCOffSzYPJRVZ2TR9wQ1OX7HO8ArKnnqU9PudqceJp
# GFqosz8RKgxyS9Km/g/lUWdddtGM6EEFMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAG+9CCi7pbWINYAAQAAAb4wDQYJYIZI
# AWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
# 9w0BCQQxIgQgxzmL2cNeccKD7edZEd1g5D0SB2gHFtuqoI0gqm/GX5MwgfoGCyqG
# SIb3DQEJEAIvMYHqMIHnMIHkMIG9BCCU7oqvrfb87L1ltc+uEQ+J00CD8V5/srdJ
# mD4PGOEMLzCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAABvvQgou6W1iDWAAEAAAG+MCIEIGtcQV/286B3ppxTHXxy8EGU3PYvFwdwvQhT
# aMVusaS7MA0GCSqGSIb3DQEBCwUABIICAI6gTkN/l2sX9w3O2O+PXzKvfpa99TLB
# OoA4MhHVOv8J8cjFOJgK/H9pS+M6fOosoBcPYtFxRQsK1aB9WvpaCMfAD0e2Cgd0
# AXzogPUqM1qMgBPaMY4Bwjnwrqmu+HB6b/+NLdTuIknDY5GfLqVCZ1w+EQ52xyjD
# HJcSEoAarC/bYtPYUNqK49vRZY10jEH9sboyjHo77K+Sw8za4cBYXhUh2S7dbu+0
# aCxsDoa1UlUT1hANL8OJRb4TxRIpPXfY54F02sVsMs6r1wNwbp0sLXSgZaHLCS5d
# k1IbI45XkredgmTQ+Iml3hA7B/3B5z/sqjm4XChA5/CnSmKavm3q5UAFClm78zid
# 515aHfmTIwr0SBcjErUBbKf+KB/GwR6d0F8MSfyCc31I8sETk0zsyVDlFfrRkA1A
# 14fyGZof7Pzz1nWBZfvej3XM43R+8VC/7ILaAAQtQJx3l+ULlXAnAyp4OZOdFlGL
# KGHbZO35bqThFopvXln3wzi59sHhprq6qFwcKRQHMlTiatKvWy5AkqSiglVLMMH2
# lZWSHmPWnHipsaNkIN9JgSjPV0LTKn9UQC4orcGihr3dQt11OoBvtD+g1N7J5QiG
# hA1ZTAmjX5pO308HZHzlgNoZ/jGOUwUN2OAzeYThrmkKN3HEbn4Z420AI61UANno
# VNj2pvOVKxrS
# SIG # End signature block
