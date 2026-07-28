<#
.SYNOPSIS
Collects basic information about the installed instance of WSUS Server

.DESCRIPTION
Collects basic information about the installed instance of WSUS Server and generates two files:
COMPUTERNAME_WSUS_BasicInfo.txt
(Optional) COMPUTERNAME_WSUS_UpdateApprovals.txt

.PARAMETER GetApprovedUpdates
(Optional) Collects a list of updates approved in the last 90 days.

.PARAMETER OutputDirectory
(Optional) Specify the output directory. If this is blank, the current working directory location is used.

.PARAMETER SilentExecution
(Optional) Use this to prevent any messages to get printed to the console host

.EXAMPLE
Get-WsusBasicInfo

.NOTES
10/04/2016 - Version 1.0 - Initial Version of the script
#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory = $false)]
	[switch]$GetApprovedUpdates,
	[Parameter(Mandatory = $false)]
	[string]$OutputDirectory,
	[Parameter(Mandatory = $false)]
	[switch]$SilentExecution
)

if (-not $OutputDirectory) {
	$OutputDirectory = $PWD.Path
}

$BasicOutputFile = Join-Path $OutputDirectory ($env:COMPUTERNAME + '_WSUS_BasicInfo.txt')
$ApprovalOutputFile = Join-Path $OutputDirectory ($env:COMPUTERNAME + '_WSUS_UpdateApprovals.txt')

$null | Out-File -FilePath $BasicOutputFile # Overwrite to empty file

if ($GetApprovedUpdates) {
	$null | Out-File -FilePath $ApprovalOutputFile # Overwrite to empty file
}

Function Write-Out {
	Param(
		[string] $text,
		[switch] $NoWriteHost,
		[switch] $IsErrorMessage,
		[string] $OutputFile
	)

	if ($OutputFile -eq $null -or $OutputFile -eq '') {
		$OutputFile = $BasicOutputFile
	}

	$text | Out-File -Append -FilePath $OutputFile

	if ($SilentExecution) {
		return
	}

	if (-not $NoWriteHost) {
		if ($IsErrorMessage) {
			LogWarn "$text"
		}
		else {
			LogInfo "$text"
		}
	}
}

Function Get-OSInfo() {
	Write-Out
	Write-Out 'WSUS SERVER INFORMATION:'
	Write-Out
	Write-Out "Server Name: $env:COMPUTERNAME"
	Write-Out "Operating System: $([environment]::OSVersion)"
	Write-Out "WSUS Version: $($updateServer.Version)"
	Write-Out
	Write-Out "Date of Report: $(Get-Date)"
	Write-Out "User Running Report: $([environment]::UserDomainName)\$([environment]::UserName)"
}

Function Get-WSUSStatus() {
	Write-Out
	Write-Out '===='

	$status = $updateServer.GetStatus()
	Write-Out "  Updates: $($status.UpdateCount)"
	Write-Out "    Approved Updates: $($status.ApprovedUpdateCount)"
	Write-Out "    Not Approved Updates: $($status.NotApprovedUpdateCount)"
	Write-Out "    Declined Updates: $($status.DeclinedUpdateCount)"
	Write-Out "    Expired Updates: $($status.ExpiredUpdateCount)"
	Write-Out "  Client Computer Count: $($status.ComputerTargetCount)"
	Write-Out "  Client Computers Needing Updates: $($status.ComputerTargetsNeedingUpdatesCount)"
	Write-Out "  Client Computers with Errors: $($status.ComputertargetsWithUpdateErrorsCount)"
	Write-Out "  Critical/Security Updates Not Approved: $($status.CriticalOrSecurityUpdatesNotApprovedForInstallCount)"
	Write-Out "  WSUS Infrastructure Updates Not Approved: $($status.WsusInfrastructureUpdatesNotApprovedForInstallCount)"
	Write-Out "  Number of Computer Target Groups: $($status.CustomComputerTargetGroupCount)"

	Write-Out "  Updates Needed by Computers: $($status.UpdatesNeededByComputersCount)"
	Write-Out "  Updates Needing Files: $($status.UpdatesNeedingFilesCount)"
}

Function Get-ComponentsWithErrors {
	Write-Out
	Write-Out '===='
	Write-Out 'COMPONENTS WITH ERRORS'
	Write-Out

	$componentsWithErrors = $updateServer.GetComponentsWithErrors()
	if ($componentsWithErrors.Count -gt 0) {
		foreach ($component in $componentsWithErrors) {
			Write-Out "  $component"
		}
	}
	else {
		Write-Out '  None.'
	}
}

Function Get-WSUSConfiguration {
	Write-Out
	Write-Out '===='
	Write-Out 'WSUS SERVER CONFIGURATION INFORMATION'
	Write-Out

	$database = $updateServer.GetDatabaseConfiguration()
	Write-Out 'Database Settings'
	Write-Out "  Database Server: $($database.ServerName)"
	Write-Out "  Database Name: $($database.DatabaseName)"
	Write-Out "  Using Windows Internal Database: $($database.IsUsingWindowsInternalDatabase)"
	Write-Out

	$config = $updateServer.GetConfiguration()
	Write-Out 'Proxy Settings:'
	Write-Out "  Use Proxy: $($config.UseProxy)"
	Write-Out "  Allow Proxy Credentials to be sent over non-SSL links: $($config.AllowProxyCredentialsOverNonSsl)"
	Write-Out "  Anonymous Proxy Access: $($config.AnonymousProxyAccess)"
	Write-Out "  Proxy Name: $($config.ProxyName)"
	Write-Out "  Proxy Server Port: $($config.ProxyServerPort)"
	Write-Out "  Proxy User Domain: $($config.ProxyUserDomain)"
	Write-Out "  Proxy User Name: $($config.ProxyUserName)"
	Write-Out "  Has Proxy Password: $($config.HasProxyPassword)"
	Write-Out

	$enabledLanguages = $config.GetEnabledUpdateLanguages()
	Write-Out 'Updates Settings:'
	Write-Out "  Auto Approve WSUS Infrastructure Updates: $($config.AutoApproveWsusInfrastructureUpdates)"
	Write-Out "  Auto Refresh Update Approvals: $($config.AutoRefreshUpdateApprovals)"
	Write-Out "  Download Express Packages: $($config.DownloadExpressPackages)"
	Write-Out "  Download Update Binaries As Needed: $($config.DownloadUpdateBinariesAsNeeded)"
	Write-Out "  Host Binaries on Microsoft Update: $($config.HostBinariesOnMicrosoftUpdate)"
	Write-Out "  Local Content Cache Path: $($config.LocalContentCachePath)"
	Write-Out "  All Update Languages Enabled: $($config.AllUpdateLanguagesEnabled)"
	$temp = '  Enabled Update Languages:'
	foreach ($language in $enabledLanguages) {
		$temp = $temp + " $language"
	}
	Write-Out $temp
	Write-Out

	Write-Out 'Synchronization Settings:'
	Write-Out "  Sync from Microsoft Update: $($config.SyncFromMicrosoftUpdate)"
	Write-Out "  Upstream WSUS Server Name: $($config.UpstreamWsusServerName)"
	Write-Out "  Upstream WSUS Server Port: $($config.UpstreamWsusServerPortNumber)"
	Write-Out "  Upstream WSUS Server, Use SSL: $($config.UpstreamWsusServerUseSsl)"
	Write-Out "  Is Replica Server: $($config.IsReplicaServer)"
	Write-Out

	Write-Out 'Miscellaneous Settings:'
	Write-Out "  Client Event Expiration Time: $($config.ClientEventExpirationTime)"
	Write-Out "  Expired Event Detection Period: $($config.ExpiredEventDetectionPeriod)"
	Write-Out "  Last Configuration Change: $($config.LastConfigChange)"
	Write-Out "  Server Event Expiration Time: $($config.ServerEventExpirationTime)"
	Write-Out "  Server ID: $($config.ServerId)"
	Write-Out "  Targeting Mode: $($config.TargetingMode)"
}

Function Get-SubscriptionList {
	Write-Out
	Write-Out '===='
	Write-Out 'SUBSCRIPTIONS'

	$subscription = $updateServer.GetSubscription()
	$categories = $subscription.GetUpdateCategories()
	$classifications = $subscription.GetUpdateClassifications()

	Write-Out
	Write-Out '  Update Categories:'
	Write-Out
	foreach ($category in $categories) {
		Write-Out "    $($category.Title)"
	}

	Write-Out
	Write-Out '  Update Classifications:'
	Write-Out
	foreach ($classification in $classifications) {
		Write-Out "    $($classification.Title)"
	}
}

Function Get-SubscriptionInfo {
	Param(
		[int] $NumberOfDays
	)

	Write-Out
	Write-Out '===='
	Write-Out 'WSUS SUBSCRIPTION INFORMATION'
	Write-Out

	$subscription = $updateServer.GetSubscription()
	$lastSyncInfo = $subscription.GetLastSynchronizationInfo()
	Write-Out "  Last synch start time: $($lastSyncInfo.StartTime)"
	Write-Out "  Last synch end time: $($lastSyncInfo.EndTime)"
	Write-Out "  Last synch error: $($lastSyncInfo.Error)"
	Write-Out "  Last synch error text: $($lastSyncInfo.ErrorText)"
	Write-Out "  Last synch result: $($lastSyncInfo.Result)"
	Write-Out "  Last synch was manual: $($lastSyncInfo.StartedManually)"

	$updateErrors = $lastSyncInfo.UpdateErrors
	if ($updateErrors.Count -lt 1) {
		Write-Out '  Last synch got all updates!'
	}
	else {
		Write-Out
		Write-Out 'Last synch failed to get following updates:'
		foreach ($updateErrorInfo in $updateErrors) {
			$update = $updateServer.GetUpdate($updateErrorInfo.UpdateId)
			Write-Out "  Update ID: $($update.Title)"
			Write-Out "  Error: $($updateErrorInfo.Error)"
			Write-Out "  Error Text: $($updateErrorInfo.ErrorText)"
		}
	}

	$since = [DateTime]::Now.AddDays(-$NumberOfDays)
	Write-Out
	Write-Out '===='
	Write-Out "WSUS SUBSCRIPTION HISTORY FOR LAST $NumberOfDays DAYS (since $since):"
	Write-Out
	$eventHistory = $subscription.GetEventHistory($since, [DateTime]::Now)

	if ($eventHistory.Count -lt 1) {
		Write-Out '  None.'
		return
	}

	foreach ($event in $eventHistory) {
		Write-Out "  $($event.CreationDate) - $($event.Message)"
	}
}

Function Get-ComputersNotCheckingIn {
	Param(
		[int] $NumberOfDays
	)

	$since = [DateTime]::Now.AddDays(-$NumberOfDays)
	Write-Out
	Write-Out '===='
	Write-Out "COMPUTERS THAT HAVE NOT CONTACTED THE WSUS SERVER FOR $NumberOfDays DAYS OR MORE (since $since):"
	Write-Out
	$computerTargets = $updateServer.GetComputerTargets()
	$count = 0
	foreach ($computerTarget in $computerTargets) {
		if ($computerTarget.LastReportedStatusTime -lt $since) {
			Write-Out "  $($computerTarget.FullDomainName) last checked in: $($computerTarget.LastReportedStatusTime)"
			$count++
		}
	}

	if ($count -eq 0) {
		Write-Out '  None.'
	}
	else {
		Write-Out
		Write-Out "  Total: $count"
	}
}

Function Get-TargetGroupList {
	Param(
		[switch] $ListComputersInGroup
	)

	Write-Out
	Write-Out '===='

	if ($ListComputersInGroup) {
		Write-Out 'CLIENT COMPUTER LIST'
	}
	else {
		Write-Out 'COMPUTER TARGETING GROUPS'
	}

	Write-Out
	$computerTargetGroups = $updateServer.GetComputerTargetGroups()
	if ($computerTargetGroups.Count -lt 1) {
		Write-Out '  None.'
		return
	}

	foreach ($targetGroup in $computerTargetGroups) {
		$targets = $targetGroup.GetComputerTargets()
		Write-Out '  ----'
		Write-Out "  Target Group: $($targetGroup.Name)"
		Write-Out "    Number of computers in group: $($targets.Count)"

		if ($ListComputersInGroup) {
			foreach ($computer in $targets) {
				$temp = "      Computer: $($computer.FullDomainName)`t"
				#$temp += " ($($computer.IPAddresss))"
				$temp += " LastStatus: $($computer.LastReportedStatusTime)"
				$temp += " LastSync: $($computer.LastSyncTime)"
				$temp += " (OS Build $($computer.OSInfo.Version.Build)"
				$temp += " Version $($computer.OSInfo.Version.Major).$($computer.OSInfo.Version.Minor) SP$($computer.OSInfo.Version.ServicePackMajor))"
				Write-Out $temp
			}
		}

		Write-Out
	}
}

Function Get-ApprovedUpdates {
	Param(
		[int] $NumberOfDays
	)

	$since = [DateTime]::Now.AddDays(-$NumberOfDays)

	Write-Out -OutputFile $ApprovalOutputFile
	Write-Out '====' -OutputFile $ApprovalOutputFile
	Write-Out "UPDATES (LATEST REVISION) APPROVED IN LAST $NumberOfDays DAYS (since $since)" -OutputFile $ApprovalOutputFile
	Write-Out -OutputFile $ApprovalOutputFile

	$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
	$updateScope.FromArrivalDate = $since
	$updateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved
	$approvedUpdates = $updateServer.GetUpdateApprovals($updateScope)

	if ($approvedUpdates.Count -lt 1) {
		Write-Out '  None.' -OutputFile $ApprovalOutputFile
		return
	}

	foreach ($updateApproval in $approvedUpdates) {
		$updateInfo = $updateServer.GetUpdate($updateApproval.UpdateId)
		Write-Out -OutputFile $ApprovalOutputFile
		Write-Out "Update ID: $($updateInfo.Id.UpdateId), Revision Number: $($updateInfo.Id.RevisionNumber), Title: $($updateInfo.Title)" -OutputFile $ApprovalOutputFile
		Write-Out "  Classification: $($updateInfo.UpdateClassificationTitle)" -OutputFile $ApprovalOutputFile
		Write-Out "  Action: $($updateApproval.Action), State: $($updateApproval.State), ComputerTargetGroup: $($updateApproval.GetComputerTargetGroup().Name)" -OutputFile $ApprovalOutputFile
		Write-Out "  ApprovalDate: $($updateApproval.CreationDate), GoLiveTime: $($updateApproval.GoLiveTime), Deadline: $($updateApproval.Deadline)" -OutputFile $ApprovalOutputFile
	}
}

# Main script

try {
	[reflection.assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration') | Out-Null
	$updateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
}
catch [Exception] {
	Write-Out
	Write-Out '  Failed to connect to the WSUS Server.' -IsErrorMessage
	Write-Out "  Error: $($_.Exception.Message)" -IsErrorMessage
	Write-Out
	exit 2
}

try {
	Get-OSInfo
	Get-WSUSStatus
	Get-ComponentsWithErrors
	Get-WSUSConfiguration
	Get-SubscriptionList
	Get-SubscriptionInfo -NumberOfDays 7
	Get-ComputersNotCheckingIn -NumberOfDays 7
	Get-ComputersNotCheckingIn -NumberOfDays 30
	Get-TargetGroupList
	Get-TargetGroupList -ListComputersInGroup
	if ($GetApprovedUpdates) { Get-ApprovedUpdates -NumberOfDays 30 }
}
catch [Exception] {
	Write-Out 'An unexpected error occurred during execution.' -IsErrorMessage
	Write-Out "Exception: $($_.Exception.Message)" -IsErrorMessage
	if ($null -ne $_.Exception.ErrorRecord) {
		if ($null -ne (Get-Member -InputObject $_.Exception.ErrorRecord -Name ScriptStackTrace)) {
			Write-Out 'Stack Trace: ' -IsErrorMessage
			Write-Out $($_.Exception.ErrorRecord.ScriptStackTrace) -IsErrorMessage
		}
	}
}
Write-Out
# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBUzpBwWfWaUNda
# pJw4CM1MII2ppWAKw4CRU1DqWOFTBKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGZ8wghmbAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO8sgZ8ZEjz1rlm30G0gbjrV
# bedF+xkg8Er0jgzMmGt8MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAduzg3TG9GQG02IhLacrcPF9UExAounI1v/wZRBYtcGOnaiMgXLrRGBty
# d/c+i1h500iE/EbxbsgNR7yO/akNdjq1VSG12ZeUK1DGPo5v16f2VtESQbcY9BiZ
# +XvfimBOgaBeaCvqIvOhYmZ03DumzPy6gmVAnGmyBq/nlYzNXVcWBGSoULneOkMX
# g5/HHw2u28aKWKgchsay+TX/lC48ieBcRb6apkfJQIyLxWouI2G0LSP+Bv7RSPoe
# c99nnzsEm8fEi6mHkdWQCvtfb3MC2sPeiKImmHuctjKv4RV3+r4E7ThMgJfIvHg9
# ay+TbjgX3clnbKlcrsWIY6rMFe+BkqGCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAfrtR+51XYTN0F0nOTyc3+P/RpAhMTB9CCRW8jaWC/sgIGZlcnzsnn
# GBMyMDI0MDYxMjE1MDAzNy4yNzVaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OjE3OUUtNEJCMC04MjQ2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHg1PwfExUffl0AAQAAAeAwDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMx
# MDEyMTkwNzE5WhcNMjUwMTEwMTkwNzE5WjCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjoxNzlFLTRC
# QjAtODI0NjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKyHnPOhxbvRATnGjb/6fuBh
# h3ZLzotAxAgdLaZ/zkRFUdeSKzyNt3tqorMK7GDvcXdKs+qIMUbvenlH+w53ssPa
# 6rYP760ZuFrABrfserf0kFayNXVzwT7jarJOEjnFMBp+yi+uwQ2TnJuxczceG5FD
# HrII6sF6F879lP6ydY0BBZkZ9t39e/svNRieA5gUnv/YcM/bIMY/QYmd9F0B+ebF
# Yi+PH4AkXahNkFgK85OIaRrDGvhnxOa/5zGL7Oiii7+J9/QHkdJGlfnRfbQ3QXM/
# 5/umBOKG4JoFY1niZ5RVH5PT0+uCjwcqhTbnvUtfK+N+yB2b9rEZvp2Tv4ZwYzEd
# 9A9VsYMuZiCSbaFMk77LwVbklpnw4aHWJXJkEYmJvxRbcThE8FQyOoVkSuKc5OWZ
# 2+WM/j50oblA0tCU53AauvUOZRoQBh89nHK+m5pOXKXdYMJ+ceuLYF8h5y/cXLQM
# OmqLJz5l7MLqGwU0zHV+MEO8L1Fo2zEEQ4iL4BX8YknKXonHGQacSCaLZot2kyJV
# RsFSxn0PlPvHVp0YdsCMzdeiw9jAZ7K9s1WxsZGEBrK/obipX6uxjEpyUA9mbVPl
# jlb3R4MWI0E2xI/NM6F4Ac8Ceax3YWLT+aWCZeqiIMLxyyWZg+i1KY8ZEzMeNTKC
# EI5wF1wxqr6T1/MQo+8tAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUcF4XP26dV+8S
# usoA1XXQ2TDSmdIwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAMATzg6R/A0ldO7M
# qGxD1VJji5yVA1hHb0Hc0Yjtv7WkxQ8iwfflulX5Us64tD3+3NT1JkphWzaAWf2w
# KdAw35RxtQG1iON3HEZ0X23nde4Kg/Wfbx5rEHkZ9bzKnR/2N5A16+w/1pbwJzdf
# RcnJT3cLyawr/kYjMWd63OP0Glq70ua4WUE/Po5pU7rQRbWEoQozY24hAqOcwuRc
# m6Cb0JBeTOCeRBntEKgjKep4pRaQt7b9vusT97WeJcfaVosmmPtsZsawgnpIjbBa
# 55tHfuk0vDkZtbIXjU4mr5dns9dnanBdBS2PY3N3hIfCPEOszquwHLkfkFZ/9bxw
# 8/eRJldtoukHo16afE/AqP/smmGJh5ZR0pmgW6QcX+61rdi5kDJTzCFaoMyYzUS0
# SEbyrDZ/p2KOuKAYNngljiOlllct0uJVz2agfczGjjsKi2AS1WaXvOhgZNmGw42S
# FB1qaloa8Kaux9Q2HHLE8gee/5rgOnx9zSbfVUc7IcRNodq6R7v+Rz+P6XKtOgyC
# qW/+rhPmp/n7Fq2BGTRkcy//hmS32p6qyglr2K4OoJDJXxFs6lwc8D86qlUeGjUy
# o7hVy5VvyA+y0mGnEAuA85tsOcUPlzwWF5sv+B5fz35OW3X4Spk5SiNulnLFRPM5
# XCsSHqvcbC8R3qwj2w1evPhZxDuNMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
# mQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNh
# dGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1
# WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjK
# NVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhg
# fWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJp
# rx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/d
# vI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka9
# 7aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKR
# Hh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9itu
# qBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyO
# ArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItb
# oKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6
# bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6t
# AgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQW
# BBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacb
# UzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYz
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnku
# aHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIA
# QwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2
# VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEw
# LTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYt
# MjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/q
# XBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6
# U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVt
# I1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis
# 9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTp
# kbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0
# sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138e
# W0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJ
# sWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7
# Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0
# dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQ
# tB1VM1izoXBm8qGCAtQwggI9AgEBMIIBAKGB2KSB1TCB0jELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxh
# bmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjox
# NzlFLTRCQjAtODI0NjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUAbfPR1fBX6HxYfyPx8zYzJU5fIQyggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOoUGgEwIhgPMjAyNDA2MTIyMDU4NDFaGA8yMDI0MDYxMzIwNTg0MVowdDA6Bgor
# BgEEAYRZCgQBMSwwKjAKAgUA6hQaAQIBADAHAgEAAgIEvDAHAgEAAgIUKzAKAgUA
# 6hVrgQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAID
# B6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBACToQXhWD/jH5G0yrjam
# LTj9kg5KMB26ayfneVhdBUxUeoW31cekBCLnSohPS8Yx9IkAzAWKja+10sQuyc13
# yEEOVEX8EdV7gHUOzQtdWV9bVksam19bahHns05Le1mZBdHSSh7xYy+koFAFMkvh
# K4vTCpq0OgMXSXBmYH96/4aqMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBIDIwMTACEzMAAAHg1PwfExUffl0AAQAAAeAwDQYJYIZIAWUDBAIB
# BQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
# IgQgpEK6p2VyvvSqSdgM69tjmDm7JsR7+w6WJ2RXvseuCygwgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCDj7lK/8jnlbTjPvc77DCCSb4TZApY9nJm5whsK/2kK
# wTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB4NT8
# HxMVH35dAAEAAAHgMCIEIBK+R19hlkqbyKr5f+AF7nKaaM8vhI/JAkiuiRxigzTT
# MA0GCSqGSIb3DQEBCwUABIICACwrRrDOBoGV0PyA9yyT5QqHOc2mjQsS2WV6y4XI
# 5Cm0Ic+ZwD95Y/CJ4w1M1UxUrDo/q4xi5qGjMRCPSJcisfXztLicUPxebtrBbwVl
# qK4ZUg1Os9mYBPkjYrZEj2ldDVzPis0bzAsK4hR4bmXfdQGttr0SHk9mu7p9qyoi
# DMb4z+JqfwQqgA34MoRI7aS6TL/vuyGBJy/d5Wp/akO+HGo3+LaXbRIWWH+/pd9o
# PV6yOf5yKm5e4RnDMX32nNotJ1oUATkXeW9ESbdqCo51KQxQgVpdAb/Hh59uw/PN
# /5mG3xwoj4PIDefvtbRgtoGYfCm+TrWqvKWVI+kRhBPsu4Z813Em7a9xeCCYf0UX
# YtEmb4NBwFWyy5ogSqPjSvWSMJpbNVret+mVHKMFCdQesr4EeL/MHVPhQmBVEQ8j
# HZJUguig5GJLopVHXJI3TcpCFPykDUnHhAYHZt7xB1pAbN1k525x4HAokLDBKsVB
# SU0oEBzGtaaqtVDv0cE+iiMFy7q/TCh8+5Zm5zZ1PvLyRzleOOnqrmPjJAlOCLCk
# +kg+k+/u62ZO4srZOAu5UJXpSrnaqufYtLeLLk9i+TCjxNt/lN1teBN1SC3K1qo1
# TuBKrMIS6GNO9oV4vb2thN8XSGvhltPONNrDiLXG2vVs5nJ1TCAfU4X+FFHWNpYn
# 0zRq
# SIG # End signature block
