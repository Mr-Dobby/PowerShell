# Name tss_GetLockoutEvents.ps1

<# 
.SYNOPSIS
 Script to find Account Lockout: PowerShell script collects Security events from all DCs related with Bad Password attempts

.DESCRIPTION
 PowerShell script sample to assist in troubleshooting account lockout issues. It can be used to collect Security Events from all DCs in a given forest or domain.
 It collects events like 4625, 4771, 4776 with error codes 0x18 and c000006a respectively.
 You do not have to run the script elevated. However you have to run it with *domain admin* privileges.
 It can be run against any domain in the forest you logon to run the script. Running against a different domain may need you to run the script with other domain admin privileges or Enterprise Admin.
 Script can also detect trusted domains and collect events from remote DCs. Make sure that the domain admin running the script has the permission to collect events remotely from trusted domains.

.PARAMETER UserName
 Please enter the UserName (sAMAccountName)
 
.PARAMETER DomainName
 Please enter the NetBIOS or FQDN of any domain in the forest
 
.PARAMETER DataPath
 This switch determines the path for output files
 
.EXAMPLE
 .\tss_GetLockoutEvents.ps1 -UserName "User1" -DomainName "Contoso" -DataPath "C:\MS_DATA" 
 Example 1:  for User1 in domain Contoso
 
.LINK
 https://internal.evergreen.microsoft.com/en-us/help/4498703
 https://microsoft.sharepoint.com/teams/HybridIdentityPOD/_layouts/15/Doc.aspx?sourcedoc={5bec59af-bf31-4073-9111-a63486fcdf0c}&action=view&wd=target%28Account%20Lockouts.one%7C9a46c4f5-38af-4648-93f2-8a976a91c463%2FWorkflow%20Account%20Lockout%20Data%20Collection%20-%20Reactive%7Cdc03d719-fff5-4bdf-b46e-15456c2521f1%2F%29
 
 Author: Ahmed Fouad (v-ahfoua@microsoft.com)
#>


# Version 1.4 - 2020.03.25 WalterE

[CmdletBinding()]
PARAM (
    [Parameter(Mandatory=$True,Position=0,HelpMessage='Enter user sAMAccountName')]
	[string]$UserName
	,
	[Parameter(Mandatory=$True,Position=1,HelpMessage='Enter DomainName')]
	[string]$DomainName
	,
	[string]$DataPath = (Split-Path $MyInvocation.MyCommand.Path -Parent)
)

#region helper functions
function CheckDomain
{	# Check domain and user variables
	try 
	{
	  Write-Host "..Checking whether domain $DomainName exists" 
	  if (Get-ADDomain $DomainName) 
	   {
		Write-Host "Domain '$DomainName' exists" -fore Green
	   }

	}
	catch 
	{
		 Write-Host $_.Exception.Message -fore Red
		 break 
	}
}

function CheckUser
{	# Check whether the user exist or not
	try
	{
	   Write-Host "..Checking whether AD user $UserName exists" 
	   if (Get-ADUser -Identity $UserName -Server $DomainName) 
		{
		 Write-Host "AD user '$UserName' exists in '$DomainName' domain" -fore Green
		}
	}
	catch 
	{
		Write-Host  $_.Exception.Message -fore Red
		break 
	}
}

function CheckDomainAdmin
{
	Write-Host "..Checking whether the current user $env:Username has domain admin privilege" 

	if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("$DomainName\Domain Admins") -and  (-not  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Enterprise Admins") ) ) 
	  {
		Write-Host "Sorry you '$env:Username' don't have domain admin privilege to run this script" -fore Red
		Break
	  }
	Else 
	  {
		Write-Host "User '$UserName' is member of '$DomainName\Domain Admins'" -fore Green 
	  }
}
#endregion helper functions


#region variables

[xml]$xmlfilter = "<QueryList> 
           <Query Id='0'> 
              <Select Path='Security'> 
                 *[EventData[Data[@Name='TargetUserName'] and (Data='$username')]] 
                  and 
                 *[EventData[Data[@Name='status'] and (Data='0x18')]] 
                 and
                 *[System[(EventID='4771' or EventID='4768' or EventID='4769' )]]
              </Select> 
           </Query> 
<Query Id='1'> 
              <Select Path='Security'> 
               *[EventData[Data[@Name='TargetUserName'] and (Data='$username')]] 
               and  
               *[EventData[Data[@Name='substatus'] and (Data='0xc000006a')]] 
                  and
               *[System[(EventID='4625' )]] 
               </Select> 
           </Query> 
<Query Id='2'> 
              <Select Path='Security'> 
               *[EventData[Data[@Name='TargetUserName'] and (Data='$username')]] 
                  and
               *[System[(EventID='4740' or EventID='4767' )]] 
               </Select> 
           </Query> 
<Query Id='3'> 
              <Select Path='Security'> 
               *[EventData[Data[@Name='TargetUserName'] and (Data='$username')]] 
               and  
               *[EventData[Data[@Name='Status'] and (Data='0xc000006a')]] 
                  and
               *[System[(EventID='4776' )]] 
               </Select> 
           </Query> 

</QueryList>"

#_# $DataPath = read-host "Please enter the path of the report (leave it blank to use the default path)"

if ($DataPath)
    {
      $fullpath = $DataPath
      New-Item -ItemType Directory -Path $fullpath\LockoutLogs -ErrorAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
    }
Else 
    {
     $fullpath = (get-location).path
     New-Item -ItemType Directory -Path $fullpath\LockoutLogs -ErrorAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
    
    }

$CSVPath = $fullpath + "\LockoutLogs\Report.csv" 


$AllEvents = @()
$SourceMachines = @()
$ExchangeServersIPv4 = @()

foreach ($ExchangeServer in $ExchangeServers ) 
{
   $ExchangeServersIPv4 += (Resolve-DnsName $ExchangeServer.name).IPAddress

}

#endregion variables

function GetEventsFromAllDCs
{
	$Dcs = Get-ADDomainController -Filter * -Server $DomainName
	#get events from all domain controllers
	foreach ($dc in $Dcs)
	{
	$serverName = $dc.HostName
	Write-Host "Checking connectivity to DC:" $serverName 
	$PingStatus = Get-WmiObject win32_pingStatus -Filter "Address = '$serverName'"

	if ($PingStatus.StatusCode -eq 0)
		{  
		  Write-Host $serverName  " is Online" -fore Green
		  Write-Host "Collecting logs from:" $serverName
		  $Events = get-winevent -FilterXml $xmlfilter -ComputerName $serverName -ErrorAction SilentlyContinue  
		  foreach ($event in $events)
		  {
		   $eventxml = [xml]$event.ToXml()

		   if ($event.Id -eq "4771")
			 {
			  $ipv4 = ($eventxml.Event.EventData.Data[6].'#text').Split(":")
			  $myObject = New-Object System.Object
			  $myObject | Add-Member -type NoteProperty -name "Source Machine" -Value $ipv4[($ipv4.length -1 )]
			  $myObject | Add-Member -type NoteProperty -name "Event ID" -Value "4771"
			  $SourceMachines += $myObject
			 } 
		   if ($event.Id -eq "4776")
			 {
			  $ipv4 = Resolve-DnsName ($eventxml.Event.EventData.Data[2].'#text')
			  $myObject = New-Object System.Object
			  $myObject | Add-Member -type NoteProperty -name "Source Machine" -Value $ipv4.IPAddress
			  $myObject | Add-Member -type NoteProperty -name "Event ID" -Value "4776"
			  $SourceMachines += $myObject
			   
			 }
		   if ($event.Id -eq "4625")
			 {
			  $ipv4 = Resolve-DnsName ($eventxml.Event.EventData.Data[2].'#text')
			  $myObject = New-Object System.Object
			  $myObject | Add-Member -type NoteProperty -name "Source Machine" -Value $ipv4.IPAddress
			  $myObject | Add-Member -type NoteProperty -name "Event ID" -Value "4625"
			  $SourceMachines += $myObject
			 }
		  }
		  if ($($Events.count) -eq 0) {
			Write-Host "[Info] Found $($Events.count) Events on $serverName for $UserName" -ForegroundColor Cyan
		  } else { Write-Host "[Warning] Found $($Events.count) Events on $serverName for $UserName" -BackgroundColor Red}
 		  
		  $AllEvents += $Events
		}
	Else 
	   {
		 Write-Host "$serverName is offline" -fore Red
	   }
	}

	# save the report 
	if ($AllEvents -ne 0)
	   { 
		 $AllEvents | Select-Object MachineName,TimeCreated,ProviderName,Id,@{n='Message';e={$_.Message -replace '\s+', " "}} | Export-Csv -Path  $CSVPath -NoTypeInformation
	   }
	if ($($AllEvents.count) -eq 0) {
		Write-Host "[Info] $($AllEvents.count) events found on all domain controllers `n" -ForegroundColor green
	} else { Write-Host "[Warning] $($AllEvents.count) events found on all domain controllers `n" -BackgroundColor Red}
	Write-Verbose "$AllEvents"

	if ($SourceMachines.Count -gt 0 )
	  {
		Write-Host "Summary of source machines for the bad password `n" -BackgroundColor Green -ForegroundColor Red
		$SourceMachines | Group-Object "Source Machine","Event ID"  -NoElement   | Sort-Object -Property Count -Descending
		$ExchangeServersIncluded = Compare-Object -ReferenceObject $SourceMachines."Source Machine"  -DifferenceObject $ExchangeServersIPv4  -IncludeEqual -ExcludeDifferent
		if ($ExchangeServersIncluded.InputObject.Length -gt 0 ) 
		   { 
			 Write-Host "`n Below Exchange Servers included in bad password source machines list `n" -BackgroundColor Green -ForegroundColor Red
			 $ExchangeServersIncluded.InputObject

			 $ExportExchangeLogs = read-host "`nDo you want to export IIS logs from mentioned Exchange servers (Yes/No)" 
			 if ($ExportExchangeLogs = "yes ")
				{
				  foreach ($ip in $ExchangeServersIncluded.InputObject)
					{
					  New-Item -ItemType Directory -Path "$fullpath\Exchange_$ip" -InformationAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
					  Copy-Item -Path \\$ip\c$\inetpub\logs\LogFiles -Destination "$fullpath\LockoutLogs\Exchange_$ip" -Recurse -Force
					}
				}
		   }
	  }
} # end GetEventsFromAllDCs

# MAIN 
CheckDomainAdmin
CheckDomain
CheckUser
GetEventsFromAllDCs

# SIG # Begin signature block
# MIIoLQYJKoZIhvcNAQcCoIIoHjCCKBoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCV9X7iY0J1Ljw6
# a6UMQsQUWFOX9OJvc0StkGsCFp6826CCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILKNZaCdNULfheYi0zLz0pWU
# 9fWoYnKFq4Oow6vCB3GfMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAdxnTgU1XVWobcBL9z/bvgoLS2umH9nw+ZN564m+tfivA/FXKFoUDq6qe
# 4rnNaxmuQFB1UeQL2mgVXcbFH9hsc1kDoH2h57vdptxxvgsexPx0uNv5GgNyH3Z0
# BO6yM8e3F3O3qt2hvLbq/I7i/tZTHmkcMOG53KxI/1uOVtjuyjk0lVEMdp2Jf13j
# 8UKEQK370OALtnqTAMrnShXqP1KAvcjrrHW7uZ3YkcCfA1zJ/kWXqJbHPs7Mz5vp
# 58SbmmLW6I74lnI3c14ELV0z2YustuVYhWRlUAjWe8F53ebytE+l9ZePIIk+cOgY
# nFsoc1+1mClgLbe+TTBXDfxmS+i6/qGCF5cwgheTBgorBgEEAYI3AwMBMYIXgzCC
# F38GCSqGSIb3DQEHAqCCF3AwghdsAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCBxtIZgzFm68hFUomkiDVRxga3o5OsI5zB0zx4r03wdsgIGZkYsf+8N
# GBMyMDI0MDYxMjE1MDAzOC4yODhaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046ODkwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHtMIIHIDCCBQigAwIBAgITMwAAAe3hX8vV96VdcwABAAAB7TANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# NDFaFw0yNTAzMDUxODQ1NDFaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046ODkwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCoMMJskrrqapycLxPC1H7zD7g88NpbEaQ6SjcTIRbz
# CVyYQNsz8TaL1pqFTEAPL1X7ojL4/EaEW+UjNqZs/ayMyW4YIpFPZP2x4FBMVCdd
# seF2i+aMMjDHi0LcTQZxM2s3mFMrCZAWSfLYXYDIimFBz8j0oLWGy3VgLmBTKM4x
# Lqv7DZUz8B2SoAmbEtp62ngSl0hOoN73SFwE+Y24SvGQMWhykpG+vXDwcpWvwDe+
# TgnrLR7ATRFXN5JS26dm2yy6SYFMRYnME3dMHCQ/UQIQQNC8nLmIvdKkAoWEMXtJ
# sGEo3QrM2S2SBv4PpHRzRukzTtP+UAceGxM9JyrwUQP5OCEmW6YchEyRDSwP4hU9
# f7B0Ayh14Pw9vJo7jewNjeMPIkmneyLSi0ruv2ox/xRGtcJ9yBNC5BaRktjz7stP
# aojR+PDA2fuBtCo8xKlkt53mUb7AY+CZHHqhLm76pdMF6BHv2TvwlVBeQRN22Xja
# VVRwCgjgJnNewt7PejcrpUn0qHLgLq+1BN1DzYukWkTr7wT0zl0iXr+NtqUkWSOn
# WRfe8N21tB6uv3VkW8nFdChtbbZZz24peLtJEZuNrN8Xf9PTPMzZXDJBI1EciR/9
# 1QcGoZFmVbFVb2rUIAs01+ZkewvbhmGVDefX9oZG4/K4gGUsTvTW+r1JZMxUT2Mw
# qQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFM4b8Oz33hAqBEfKlAZf0NKh4CIZMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQCd1gK2Rd+eGL0eHi+iE6/qDY8sbbsO4ema
# ncp6KPN+xq5ZAatiBR4jmRRhm+9Vik0Fo0DLWi/N28bFI7dXYw09p3vCipbjy4Eo
# ifm0Nud7/4U30i9+7RvW7XOQ3rx37+U7vq9lk6yYpGCNp0jlJ188/CuRPgqJnfq5
# EdeafH2AoG46hKWTeB7DuXasGt6spJOenGedSre34MWZqeTIQ0raOItZnFuGDy4+
# xoD1qRz2QW+u2gCHaG8AQjhYUM4uTi9t6kttj6c7Xamr2zrWuceDhz7sKLttLTJ7
# ws5YrA2I8cTlbMAf2KW0GVjKbYGd+LZGduEK7/7fs4GUkMqc51FsNdG1n+zgc7zH
# u2oGGeCBg4s8ZR0ZFyx7jsgm9sSFCKQ5CsbAvlr/60Ndk5TeMR8Js2kNUicu2CqZ
# 03833TsvTgk7iD1KLgfS16HEvjN6m4VKJKgjJ7OJJzabtS4JQgUnJrIZfyosk4D1
# 8rZni9pUwN03WgTmd10WTwiZOu4g8Un6iKcPMY/iFqTu4ntkzFUxBBpbFG6k1CIN
# ZmoirEWmCtG3lyZ2IddmjtIefTkIvGWb4Jxzz7l2m/E2kGOixDJHsahZVmwsoNvh
# y5ku/inU++dXHzw+hlvqTSFT89rIFVhcmsWPDJPNRSSpMhoJ33V2Za/lkKcbkUM0
# SbQgS9qsdzCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
# hvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# MjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAy
# MDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25Phdg
# M/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPF
# dvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6
# GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBp
# Dco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50Zu
# yjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3E
# XzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0
# lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1q
# GFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ
# +QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PA
# PBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkw
# EgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxG
# NSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARV
# MFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAK
# BggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
# zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
# cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYI
# KwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG
# 9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0x
# M7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmC
# VgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449
# xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wM
# nosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDS
# PeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2d
# Y3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxn
# GSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+Crvs
# QWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokL
# jzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggNQ
# MIICOAIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjg5MDAtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQDu
# HayKTCaYsYxJh+oWTx6uVPFw+aCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hOYyTAiGA8yMDI0MDYxMjAzNDcy
# MVoYDzIwMjQwNjEzMDM0NzIxWjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDqE5jJ
# AgEAMAoCAQACAg0jAgH/MAcCAQACAhQIMAoCBQDqFOpJAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAAnN29mCTsByvBaE9DHLX1tZzeZuhEvl95ghsWfASCab
# Y11vqbdDwRIZTOXUsY8PE6utYCmQuSWpLulcxY9l59Wvu4Ei9lHmbXxdyHVzKI/y
# twVSZzR9j5Lv597FURwSiG3o1BrJFyxL7FVUJH5kyGW26sWOO2/Kl/wdX13JKcz3
# 7pJfQhCc4Ht5nj90I9L8AuShOw7JvA00v+CWLiVaRgzxZowwV3Vy6zZ/GbbgTg6M
# sONlfYUetXyHiWyX+wKiL3bpuja6NQlSaMd6ZFlqJqQOEqwaavCRLBOlYFqu5V3w
# zs51KGym+bOYFOx6AwKC2HRUafa6+IE7kiqsaajRoAgxggQNMIIECQIBATCBkzB8
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAe3hX8vV96VdcwABAAAB
# 7TANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEE
# MC8GCSqGSIb3DQEJBDEiBCBlWgykZBvylsrxKT0eKhumf8ptv1DieDUutLZjW4pM
# NjCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EII0uDWg0CFseKxK3A16l1wrI
# wrsSDrXZ6xSf0F4xbMo5MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTACEzMAAAHt4V/L1felXXMAAQAAAe0wIgQg78GZUuvOaAxFZfQzyWJdNbhw
# SWZv3xxQFU3XxQWbtOkwDQYJKoZIhvcNAQELBQAEggIAWrxJNs7oA7TY0tcXicPn
# V3ap/LYDM5jFmDdlJB0xueDeut3iXvGvzxQn+byti7b3UM8iEAmF7XcBqeENmkhu
# xyxsyf1MAo+DqpmixRSs5NKhw5j491cXnPgN7/WvJDm5Yp8NZJvgc99RfhJlFGT1
# J75T9btRJ4oZb1L3HG3oRdIh5C2jUWzL9AM6vz8jh9+xN+tn5D6Qal/qLveZf5Xb
# mCqkcbWbJLV0f+7SSzr4soJUFTLk14RDnU5UhcXY9cGbqNhptzt2LMU+Q+264ujb
# 5i/GJcAc7HnUbI3u72/yF7+NinJF6Ly/IqcLFKQ/PWV6yGvTKLzOPOoHq+eBOydN
# USv4S6izu7eagnFwjmQmiKrLORmvdwm4+ltFkPyYXISTTIFolQmLYXwqSJcarOzZ
# 0M3tJJtQRNSgNUkYpEw5NUCWYGQGqDj/Z9kKMH5f8kHW0exrXvogdhhyRuKTOU85
# N3eUqyZCwRD2m36auQFAdYuOlEJvsBG5IvABxkbFCyaAHR9rq7YMEXzxsv4yeEcK
# zzu50xaMrgsILmT7GMdl9wL2JngoMpdeZmn56utWu601vau8eb2xO+A8lTGIQF4q
# We4IQGNg4fjTH0dNgOv19Em6fePkgrOCvgwiitx0GgW2iOCJVUy8XCp1Y0jY0WdN
# ylUwQi49klPsW7l2mSjNI+E=
# SIG # End signature block
