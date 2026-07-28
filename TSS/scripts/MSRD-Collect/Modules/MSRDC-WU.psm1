<#
.SYNOPSIS
   Module for extended installed Windows Updates report

.DESCRIPTION
   Collects information on installed Windows Updates and generates a report in .html format

.NOTES
   Author     : Robert Klemencz
   Requires   : MSRD-Collect.ps1
   Version    : See MSRD-Collect.ps1 version
   Feedback   : https://aka.ms/MSRD-Collect-Feedback
#>

$msrdLogPrefix = "Core"
$WUFile = $global:msrdSysInfoLogFolder + $global:msrdLogFilePrefix + "UpdateHistory.html"
$Script:WUErrors

Function msrdPrintUpdate ([string]$Category,[string]$ID,[string]$Operation,[string]$Date,[string]$ClientID,[string]$InstalledBy,[string]$OperationResult,[string]$Title,[string]$Description,[string]$HResult,[string]$UnmappedResultCode) {

	$Category = if ($Category -eq "QFE hotfix") { "Other updates not listed in history" } else { $Category }

	if (-not [String]::IsNullOrEmpty($ID)) {
		$NumberHotFixID = msrdToNumber $ID
		if ($NumberHotFixID.Length -gt 5) { $SupportLink = "http://support.microsoft.com/kb/$NumberHotFixID" }
	} else {
		$ID = ""
		$SupportLink = ""
	}

	if (-not [String]::IsNullOrEmpty($Title)) {
		if (($Title -like "*Security Update*System*") -or ($Title -like "*Cumulative Update*System*") -or ($Title -like "*Mise à jour cumulative*Windows*")) {
			$Title = "<b>" + $Title.Trim() + "</b>"
		} else {
			$Title = $Title.Trim()
		}
	} else {
		$Title = ""
	}

	$Description = if (-not [String]::IsNullOrEmpty($Description)) { $Description.Trim() } else { "" }

	$tdcircle = switch($OperationResult) {
        'Completed successfully' { "circle_green" }
        'Operation was aborted' { "circle_red" }
		'Completed with errors' { "circle_red" }
		'Failed to complete' { "circle_red" }
        'In progress' { "circle_white" }
        default { "circle_white" }
	}

	if ((-not [String]::IsNullOrEmpty($HResult)) -and ($HResult -ne 0)) {
		$HResultHex = msrdConvertToHex $HResult
		$HResultArray = msrdGetWUErrorCodes $HResultHex

		$errmsg = "Error code: $HResultHex"

		if ($null -ne $HResultArray) {
			$errmsg = $errmsg + " (" + $HResultArray[0] + " - " + $HResultArray[1] + ")"
		}

		$HResultHex2 = msrdConvertToHex $UnmappedResultCode
		$errmsg = "<tr><td width='10px'><div class='circle_red'></div></td><td colspan='3'></td><td colspan='3' style='background-color: #FFFFDD'>$errmsg [$HResultHex2]</td></tr>"
	}

	$DiagMessage = "<tr>
		<td width='10px'><div class='$tdcircle'></div></td>
		<td width='17%' style='padding-left: 5px;'>$Category</td>
		<td width='11%'>$Date</td>
		<td width='6%'>$Operation</td>
		<td width='11%'>$OperationResult</td>
		<td width='7%'><a href='$SupportLink' target='_blank'>$ID</a></td>
		<td><span title='$Description' style='cursor: pointer'>$Title</span></td>
	</tr>"

	Add-Content $WUFile $DiagMessage
	if ($errmsg) { Add-Content $WUFile $errmsg }
}

Function msrdGetHotFixFromRegistry {
	$RegistryHotFixList = @{}
	$UpdateRegistryKeys = @("HKLM:\SOFTWARE\Microsoft\Updates")

	#if $OSArchitecture -ne X86 , should be 64-bit machine. we also need to check HKLM:\SOFTWARE\Wow6432Node\Microsoft\Updates
	if($OSArchitecture -ne "X86")
	{
		$UpdateRegistryKeys += "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Updates"
	}

	foreach($RegistryKey in $UpdateRegistryKeys) {
		If(Test-Path $RegistryKey) {
			$AllProducts = Get-ChildItem $RegistryKey -Recurse | Where-Object {$_.Name.Contains("KB") -or $_.Name.Contains("Q")}

			foreach($subKey in $AllProducts) {
				if($subKey.Name.Contains("KB") -or $subKey.Name.Contains("Q")) {
					$HotFixID = msrdGetHotFixID $subKey.Name

					if($RegistryHotFixList.Keys -notcontains $HotFixID) {
						$Category = [regex]::Match($subKey.Name,"Updates\\(?<Category>.*?)[\\]").Groups["Category"].Value
						$HotFix = @{HotFixID=$HotFixID;Category=$Category}
						foreach($property in $subKey.Property)
						{
							$HotFix.Add($property,$subKey.GetValue($property))
						}
						$RegistryHotFixList.Add($HotFixID,$HotFix)
					}
				}
			}
		}
	}
	return $RegistryHotFixList
}

Function msrdGetHotFixID ($strContainID) {
	return [System.Text.RegularExpressions.Regex]::Match($strContainID,"(KB|Q)\d+(v\d)?").Value
}

Function msrdToNumber ($strHotFixID) {
	return [System.Text.RegularExpressions.Regex]::Match($strHotFixID,"([0-9])+").Value
}

Function msrdFormatStr ([string]$strValue,[int]$NumberofChars) {

	if([String]::IsNullOrEmpty($strValue)) {
		$strValue = " "
		return $strValue.PadRight($NumberofChars," ")
	} else {
		if($strValue.Length -lt $NumberofChars) {
			return $strValue.PadRight($NumberofChars," ")
		} else {
			return $strValue.Substring(0,$NumberofChars)
		}
	}
}

# dates with dd/mm/yy hh:mm:ss
Function msrdFormatDateTime ($dtLocalDateTime,[Switch]$SortFormat) {

	if([string]::IsNullOrEmpty($dtLocalDateTime)) { return "" }

	if($SortFormat.IsPresent) {
		# Obtain dates on yyyymmdddhhmmss
		return Get-Date -Date $dtLocalDateTime -Format "yyyyMMddHHmmss"
	} else {
		return Get-Date -Date $dtLocalDateTime -Format G
	}
}

Function msrdValidatingDateTime ($dateTimeToValidate) {

	if([String]::IsNullOrEmpty($dateTimeToValidate)) { return $false }

	$ConvertedDateTime = Get-Date -Date $dateTimeToValidate

	if($null -ne $ConvertedDateTime) {
		if(((Get-Date) - $ConvertedDateTime).Days -le $NumberOfDays) { return $true }
	}

	return $false
}

# Query SID of an object using WMI and return the account name
Function msrdConvertSIDToUser([string]$strSID)  {

	if([string]::IsNullOrEmpty($strSID)) { return }

	if($strSID.StartsWith("S-1-5")) {
		$UserSIDIdentifier = New-Object System.Security.Principal.SecurityIdentifier `
    	($strSID)
		$UserNTAccount = $UserSIDIdentifier.Translate( [System.Security.Principal.NTAccount])
		if($UserNTAccount.Value.Length -gt 0) {
			return $UserNTAccount.Value
		} else {
			return $strSID
		}
	}
	return $strSID
}

Function msrdConvertToHex([int]$number) {
	return ("0x{0:x8}" -f $number)
}

Function msrdGetUpdateOperation($Operation) {

	switch ($Operation) {
		1 { return "Install" }
		2 { return "Uninstall" }
		Default { return "Unknown("+$Operation+")" }
	}
}

Function msrdGetUpdateResult($ResultCode) {

	switch ($ResultCode) {
		0 { return "Not started" }
		1 { return "In progress" }
		2 { return "Completed successfully" }
		3 { return "Completed with errors" }
		4 { return "Failed to complete" }
		5 { return "Operation was aborted" }
		Default { return "Unknown("+$ResultCode+")" }
	}
}

Function msrdGetWUErrorCodes($HResult) {

	if ($null -eq $Script:WUErrors) {

		$WUErrorsFilePath = "$global:msrdScriptpath\Config\MSRDC-WU.xml"

		if(Test-Path -Path $WUErrorsFilePath) {
			[xml] $Script:WUErrors = Get-Content $WUErrorsFilePath
		} else {
			"[Warning]: Did not find the Config\MSRDC-WU.xml file, cannot load all WU error code information" | Out-File -Append ($global:msrdErrorLogFile)
		}
	}

	$WUErrorNode = $Script:WUErrors.ErrV1.err | Where-Object {$_.n -eq $HResult}

	if ($null -ne $WUErrorNode) {
		$WUErrorCode = @()
		$WUErrorCode += $WUErrorNode.name
		$WUErrorCode += $WUErrorNode."#text"
		return $WUErrorCode
	}
	return $null
}


# Start here
Function msrdRunUEX_MSRDWU {

	msrdCreateLogFolder $global:msrdSysInfoLogFolder
	msrdLogMessage $LogLevel.Normal -LogPrefix $msrdLogPrefix -Message "Exporting Windows Update history"

	msrdHtmlInit $WUFile
	msrdHtmlHeader -htmloutfile $WUFile -title "Update History : $($env:computername)" -fontsize "11px"
    msrdHtmlBodyWU -htmloutfile $WUFile -title "Update History for $global:msrdFQDN"

	# Get updates from the com object
	Try {
		$Session = New-Object -ComObject Microsoft.Update.Session
		$Searcher = $Session.CreateUpdateSearcher()
		$HistoryCount = $Searcher.GetTotalHistoryCount()
	} Catch {
        msrdLogMessage $LogLevel.Error ("Error collecting updates information from Microsoft.Update.Session" + $_.Exception.Message)
		$HistoryCount = 0
    }

	if ($HistoryCount -gt 0) {
		$ComUpdateHistory = $Searcher.QueryHistory(1,$HistoryCount)
	} else {
		$ComUpdateHistory = @()
		"`nNo updates found on Microsoft.Update.Session`n" | Out-File -Append $global:msrdOutputLogFile
	}

	# Get updates from the Wmi object Win32_QuickFixEngineering
	$QFEHotFixList = New-Object "System.Collections.ArrayList"
	$QFEHotFixList.AddRange(@(Get-WmiObject -Class Win32_QuickFixEngineering))

	# Get updates from the regsitry keys
	$RegistryHotFixList = msrdGetHotFixFromRegistry

	# Format each update history to the stringbuilder
	foreach($updateEntry in $ComUpdateHistory) {

		# Do not list the updates on which the $updateEntry.ServiceID = '117CAB2D-82B1-4B5A-A08C-4D62DBEE7782' or '855e8a7c-ecb4-4ca3-b045-1dfa50104289'. These are Windows Store updates and are bringing inconsistent results
		if (($updateEntry.ServiceID -ne '117CAB2D-82B1-4B5A-A08C-4D62DBEE7782') -and ($updateEntry.ServiceID -ne '855e8a7c-ecb4-4ca3-b045-1dfa50104289')) {

			$HotFixID = msrdGetHotFixID $updateEntry.Title
			$HotFixIDNumber = msrdToNumber $HotFixID
			$strInstalledBy = ""

			if(($HotFixID -ne "") -or ($HotFixIDNumber -ne "")) {
				foreach($QFEHotFix in $QFEHotFixList) {
					if(($QFEHotFix.HotFixID -eq $HotFixID) -or ((msrdToNumber $QFEHotFix.HotFixID) -eq $HotFixIDNumber)) {
						$strInstalledBy = msrdConvertSIDToUser $QFEHotFix.InstalledBy

						#Remove the duplicate HotFix in the QFEHotFixList
						$QFEHotFixList.Remove($QFEHotFix)
						break
					}
				}
			}

			# Remove the duplicate HotFix in the RegistryHotFixList
			if ($RegistryHotFixList.Keys -contains $HotFixID) { $RegistryHotFixList.Remove($HotFixID) }

			$strCategory = ""
			if($updateEntry.Categories.Count -gt 0) { $strCategory = $updateEntry.Categories.Item(0).Name }

			if ([String]::IsNullOrEmpty($strCategory)) { $strCategory = "(None)" }

			$strOperation = msrdGetUpdateOperation $updateEntry.Operation
			$strDateTime = msrdFormatDateTime $updateEntry.Date
			$strResult = msrdGetUpdateResult $updateEntry.ResultCode

			msrdPrintUpdate -Category $strCategory -ID $HotFixID -Operation $strOperation -Date $strDateTime -ClientID $updateEntry.ClientApplicationID -InstalledBy $strInstalledBy -OperationResult $strResult -Title $updateEntry.Title -Description $updateEntry.Description -HResult $updateEntry.HResult -UnmappedResultCode $updateEntry.UnmappedResultCode
		}
	}

	Add-Content $WUFile "</table></div></details>
	<details open>
		<summary>
			<a name='QFE'></a><b>Other - QFE</b><span class='b2top'><a href='#'>^top</a></span>
		</summary>
		<div class='detailsP'>
			<table class='tduo'>
				<tr style='text-align: left;'>
					<th width='10px'><div class='circle_no'></div></th><th style='padding-left: 5px;'>Category</th><th>Date/Time</th><th>Operation</th><th>Result</th><th>KB</th><th>Description</th>
				</tr>"
	# Output the Non History QFEFixes
	foreach($QFEHotFix in $QFEHotFixList) {
		$strInstalledBy = msrdConvertSIDToUser $QFEHotFix.InstalledBy
		$strDateTime = msrdFormatDateTime $QFEHotFix.InstalledOn
		$strCategory = ""

		# Remove the duplicate HotFix in the RegistryHotFixList
		if($RegistryHotFixList.Keys -contains $QFEHotFix.HotFixID) {
			$strCategory = $RegistryHotFixList[$QFEHotFix.HotFixID].Category
			$strRegistryDateTime = msrdFormatDateTime $RegistryHotFixList[$QFEHotFix.HotFixID].InstalledDate

			if ([String]::IsNullOrEmpty($strInstalledBy)) {
				$strInstalledBy = $RegistryHotFixList[$QFEHotFix.HotFixID].InstalledBy
			}

			$RegistryHotFixList.Remove($QFEHotFix.HotFixID)
		}

		if ([string]::IsNullOrEmpty($strCategory)) {
			$strCategory = "QFE hotfix"
		}

		if ($strDateTime.Length -eq 0) {
			$strDateTime = $strRegistryDateTime
		}

		if ([string]::IsNullOrEmpty($QFEHotFix.Status)) {
			$strResult = "Completed successfully"
		} else {
			$strResult = $QFEHotFix.Status
		}

		msrdPrintUpdate -Category $strCategory -ID $QFEHotFix.HotFixID -Operation "Install" -Date $strDateTime -ClientID "" -InstalledBy $strInstalledBy -OperationResult $strResult -Title $QFEHotFix.Description -Description $QFEHotFix.Caption
	}

	Add-Content $WUFile "</table></div></details>
	<details open>
		<summary>
			<a name='REG'></a><b>Other - Registry</b><span class='b2top'><a href='#'>^top</a></span>
		</summary>
		<div class='detailsP'>
			<table class='tduo'>
				<tr style='text-align: left;'>
					<th width='10px'><div class='circle_no'></div></th><th style='padding-left: 5px;'>Category</th><th>Date/Time</th><th>Operation</th><th>Result</th><th>KB</th><th>Description</th>
				</tr>"
	# Generating information for updates found on registry
	foreach ($key in $RegistryHotFixList.Keys) {
		$strCategory = $RegistryHotFixList[$key].Category
		$HotFixID = $RegistryHotFixList[$key].HotFixID
		$strDateTime = $RegistryHotFixList[$key].InstalledDate
		$strInstalledBy = $RegistryHotFixList[$key].InstalledBy
		$ClientID = $RegistryHotFixList[$key].InstallerName

		if ($HotFixID.StartsWith("Q")) {
			$Description = $RegistryHotFixList[$key].Description
		} else {
			$Description = $RegistryHotFixList[$key].PackageName
		}

		if ([string]::IsNullOrEmpty($Description)) {
			$Description = $strCategory
		}

		msrdPrintUpdate -Category $strCategory -ID $HotFixID -Operation "Install" -Date $strDateTime -ClientID $ClientID -InstalledBy $strInstalledBy -OperationResult "Completed successfully" -Title $strCategory -Description $Description
	}

	# Creating output files
	msrdHtmlEnd $WUFile

	$Session = $null
}

Export-ModuleMember -Function msrdRunUEX_MSRDWU
# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjhLnaV/w5fDR6
# VGM9FO0FI5xzAjS9IgplUFIvEZLLLaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHoh8IMLJgM1oRdiGTU7KHQH
# s5eft1xxFpiVASmxk+lOMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAsMd+03hd5HIpDenhUb8QqUZ4ri9EOhGGEI0hH2CkmVtBTkxZRq/Sd/i+
# AmOCsrQjQe3Pvd0S+tCr/hkrT4xcphyNMIP2CBXxTGIzQfVttLXx7uN5ySCXxPZr
# D6vCSAz9lw4K7XftpU5dEi3JmxfjmM9/7ZEe2GxuIWZ6MG+3xbUbB+3bj1YJ4qPZ
# +1ldRaAc55in1yw09TNJh9DXbMEWQytNhJc4RrzraI65X0qGf5QK1sYLz2G593rT
# 3saAlj/I3/0uzfQ+V6Tc05ibnKhA/7sGsixn9tC2x30XHqVuz04G/GWSUFUjr53s
# qudU2+EhJ+7zNfEsSL3AP5fPAmTMa6GCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCCubTQ3m1jc+uhQZN2/B73LGcfyyP83A9LEwzbykNenwwIGZlcnzsos
# GBMyMDI0MDYxMjE1MDAzOS4wNjNaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
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
# IgQgy/m+0WZE5OG+pE95CIaAfrNr9G8OOgP8M53H+4TowBEwgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCDj7lK/8jnlbTjPvc77DCCSb4TZApY9nJm5whsK/2kK
# wTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB4NT8
# HxMVH35dAAEAAAHgMCIEIBK+R19hlkqbyKr5f+AF7nKaaM8vhI/JAkiuiRxigzTT
# MA0GCSqGSIb3DQEBCwUABIICAE8E5IRyST0pSYbEpCMxQytk85ifEAppuvtkOH2G
# ozzStdFHu0sQLtWCWJOI6oXYgVIyladZuVLKFgJBve9Zc+C150GCgMtq+/XeO3S+
# 6jMGZi5fZOaRJIOng3BWnZ/lerhM5aXdhC+cacYkk2Ktz33AY7TDi/Wl+RYYyFRf
# 3sa9+GUPCBb102Dl6pwLjnhIYKRIhzzHGsDJ+XJXh6FrUAA3z9dWg7db+raAuknM
# CGHdQOKx7YkAjg64iGUwx+zaiZyB/0r2p5d6rdhW7ZCldaltAAfxF8HpJ9Q3SWq5
# xd5GczJF6CBS43V1h4cMbLv3e0JbLrs11/PuGluCaIKsERkz23WNZRgfz+7dMSIM
# 5ga4wYiL4alSAIjsizpJcorCpJks1yasnwMfqrflYR2Vo4y1261SVuRHvSqc1iLn
# 2dLvEcserV30GLN3QShcXrIeuQo3QxuEadl30wuC1doJB0lnQpdZpnK6zf7XYfvc
# X8u2jnfw2L2V+vDtuHiJkS9bwCTIIORrKbc/bgA4tBSNiF4rNdkEaj3ahsEj5+E1
# /9ef10ssaYlxn5ui+A36/rkUvLzVJOhq18bNGdvGPmyNtyW7K0MSowHU9xDxfK/o
# z3nzMpMOTsJNrFYt9NbJnG52F3hScaOj9kt39qtMCnNSIpoyln+4U/dz1D6Wi7f/
# DIlx
# SIG # End signature block
