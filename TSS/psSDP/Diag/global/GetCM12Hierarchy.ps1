# ***********************************************************************************************************
# Version 1.0
# Date: 10-09-2023
# Author: viki
# Description: Creates a tabbed list of the entire hierarchy
# ***********************************************************************************************************

function GetTimeZone {
    Param($tzi)

    # we just need the first element
    # local time = UTC - bias, where bias is represented in minutes
    # https://docs.microsoft.com/en-us/windows/win32/api/timezoneapi/ns-timezoneapi-time_zone_information

    try {
        $bias = [int32]"0x$($tzi.split(' ')[0])"
		
		if ($bias -eq 0) { "UTC" }
        elseif ($bias -lt 0) { return "UTC +$([Math]::Abs($bias)) minutes" }
        else { return "UTC -$bias minutes" }
    }
    catch { return "n/a" }
}

function Export-SiteInfo {
    Param (
        [Parameter(Mandatory = $true)]
        $obj,
        [Parameter(Mandatory = $false)]
        $t = $tab,
        [Parameter(Mandatory = $false)]
        [switch]$isSec
    )

    if ($isSec) { 
        $siteType = 'Secondary'
        $t+= "`t"
    }

    "$t$($obj.siteCode) | $siteType | $($obj.Version) | Install Directory: $($obj.InstallDir)" | Out-File $OutputFile -Append
    "$($t)Site Server: $($obj.ServerName) | Time Zone: $(GetTimeZone $obj.TimeZoneInfo)" | Out-File $OutputFile -Append
}

function TerminatingError {
    TraceOut "Aborting execution..."
    exit
}

### start execution ###
$ErrorActionPreference = 'stop'
$provRemote = $false

TraceOut "Started"

# ensure we have the site code or exit
if (!(Test-Path variable:siteCode) -or ([string]::IsNullOrEmpty($siteCode))) { 
    $siteCode = Get-RegValueWithError ($Reg_SMS + "\Identification") "Site Code"
    if ($siteCode -like "*ERROR*") {
        TraceOut "Site code could not be determined. Script is probably not running on a site server or SMS Provider."; exit
    }
}

$smsProv = "ROOT\SMS\site_$siteCode"
$localFQDN = [System.Net.Dns]::GetHostByName($env:COMPUTERNAME).HostName
$ProgressActivity = "Gathering Hierarchy Information"

$ProgressStatus = "Retrieving site(s) details"
Write-DiagProgress -Activity $ProgressActivity -Status $ProgressStatus; TraceOut $ProgressStatus

# always try local WMI, as $provServer might point to remote one in case of multiple SMS Provider
$sites = Get-WmiObject -Namespace $smsProv -Class SMS_Site -ErrorAction SilentlyContinue -ErrorVariable SMS_Site_Err

if (!$sites) {
    # exit in case SMS Provider could not be determined
    if (!(Test-Path variable:provServer) -or ([string]::IsNullOrEmpty($provServer))) {
        TraceOut "Configuration Manager SMS Provider not detected, or not accessible."
        WriteTo-ErrorDebugReport -ErrorRecord $SMS_Site_Err[0]
        TerminatingError
    }

    # try remote SMS Provider if local WMI namespace was not found
    elseif (($SMS_Site_Err[0].Exception.HResult -eq -2146233087) -and ($provServer -ne $localFQDN)) {
        try {
            $provRemote = $true
            TraceOut "No local SMS provider. Trying computer $provServer"
            $sites = Get-WmiObject -ComputerName $provServer -Namespace $smsProv -Class SMS_Site
        }
        catch {
            WriteTo-ErrorDebugReport -ErrorRecord $_ 
            TerminatingError
        }
    }
    else {
        WriteTo-ErrorDebugReport -ErrorRecord $SMS_Site_Err[0]
        TerminatingError 
    }
}

# Type 4 = CAS, Type 2 = primary site, Type 1 = secondary site
# do NOT change the sort order, otherwise the site map might be corrupted
$sites = $sites | Sort-Object @{ e = 'Type'; desc = $true }, SiteCode, ServerName

# get secondary sites
# ensure an array is returned, as we need the count property later
$secSites = @($sites | Where-Object Type -EQ 1 | Sort-Object ReportingSiteCode, SiteCode, ServerName)

# check HA -> Type 8 -> (likely) passive node, and get Setup Info
# https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/servers/configure/sms_sci_sysresuse-server-wmi-class

$ProgressStatus = "Retrieving setup info & passive nodes (if any)"
Write-DiagProgress -Activity $ProgressActivity -Status $ProgressStatus; TraceOut $ProgressStatus
try {
    if (!$provRemote) {
        # get MEMCM version and build number
        $setupInfo = [wmi]"$($smsProv):SMS_SetupInfo.id='RELEASEVERSION'"

        # get passive nodes
        $passiveNodes = Get-WmiObject -Namespace $smsProv `
            -Query "SELECT * FROM SMS_SCI_SysResUse where RoleName = 'SMS Site Server' and Type = 8"
    }
    # remote sms provider
    else {
        $setupInfo = [wmi]"\\$provServer\$($smsProv):SMS_SetupInfo.id='RELEASEVERSION'"
        $passiveNodes = Get-WmiObject -ComputerName $provServer -Namespace $smsProv `
            -Query "SELECT * FROM SMS_SCI_SysResUse where RoleName = 'SMS Site Server' and Type = 8"
    }
}
catch { Write-Log $_.Exception.Message }

### generate output ###
$tab = ''
$secIndex = 0
$casFound = $false

$ProgressStatus = "Generating output"
Write-DiagProgress -Activity $ProgressActivity -Status $ProgressStatus; TraceOut $ProgressStatus
"Running on Computer: $localFQDN" | Out-File $OutputFile -Force

@"
Release Version: $($setupInfo.Value1), build $($setupInfo.Value2)
Site Code: $siteCode

===================
[Hierarchy Details]
===================

"@ | Out-File $OutputFile -Append

if (!(Test-Path variable:passiveNodes)) { "NOTE: Failed to check for passive nodes!`r`n" | Out-File $OutputFile -Append }

foreach ($site in $sites) {

    if ($site.Type -eq 4) {
        $casFound = $true 
        $siteType = "Central Admin Site"
    }
    elseif ($site.Type -eq 2) { 
        $siteType = "Primary Site" 
        if ($casFound) { $tab = "`t" }
    }
    # loop through CAS & primary sites only
    else { break }

    # CAS or primary
    Export-SiteInfo $site

    # passive node
    if ((Test-Path variable:passiveNodes) -and ($passiveNodes) -and ($passiveNodes.SiteCode -contains $site.SiteCode)) { 
        "$($tab)Passive Node: $(($passiveNodes | Where-Object SiteCode -EQ $site.SiteCode).NetworkOSPath.Replace('\\',''))" |
        Out-File $OutputFile -Append
    } 

    '' | Out-File $OutputFile -Append

    # loop through secondary sites starting with last position where we left off
    if (($secSites) -and ($site.Type -eq 2)) {

        $secSiteFound = $false

        for ($i = $secIndex; $i -lt $secSites.Count ; $i++) {
            if ($secSites[$i].ReportingSiteCode -eq $site.SiteCode) {
                $secSiteFound = $true
                Export-SiteInfo $secSites[$i] -isSec
                '' | Out-File $OutputFile -Append
            }
            elseif ($secSiteFound) { break }
        }
        
        if ($secSiteFound) { $secIndex = $i }
    }
}

TraceOut "Completed"



# SIG # Begin signature block
# MIIoLAYJKoZIhvcNAQcCoIIoHTCCKBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBG0Z7+lCRQyLpW
# +ZDa0/sspoilXqLkoN4XJ6N76SfAI6CCDXYwggX0MIID3KADAgECAhMzAAADTrU8
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAANOtTx6wYRv6ysAAAAAA04wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMTllkOl49UFHzEyAO+pDjeL
# uNYg8n4KL4NT20QN5QDwMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCVZg77P7jjHfzhVdKPMpjsQxaU8cikkTwCRZW2jl9OuAP2oE1KVk7N
# DgW/COjAKpJHPY+GTHusbGzfmR1oRNp+Gl1JM06wk6szpYA7qvVn5g3ELbvvLKTR
# azWbFmoSncpSrzqyyutroosRihLYsMpFR1wF7ThjprJpSLW7vdFaUTzmmASwVNGe
# JnttbKxhdzQTT07rR29SexsqKPt/014w4fxDpLPowOKM34uxODqnV1Gfsds7iz1U
# vqvBhdcZOfuqYFeVPL31tAmYuSYW19itUtzoFHttMB4vUF/UmkKbrVQp7lE6zfv1
# sxyF+Elr3mX6kCGYd0/OJsOFnagvDaf3oYIXlDCCF5AGCisGAQQBgjcDAwExgheA
# MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglghkgBZQMEAgEFADCCAVIG
# CyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIHjNpUy08a+049wW28ftu2aizjhzMeqwCFV78PCqbwvuAgZlKG/N
# 25EYEzIwMjMxMDIwMTQyNTA4LjAzN1owBIACAfSggdGkgc4wgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBMDAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCEeowggcgMIIFCKADAgECAhMzAAAB0HcIqu+jF8bdAAEAAAHQMA0GCSqGSIb3
# DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMDUyNTE5
# MTIxNFoXDTI0MDIwMTE5MTIxNFowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlv
# bnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBMDAwLTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAN8yV+ffl+8zRcBRKYjmqIbRTE+LbkeRLIGDOTfO
# lg7fXV3U4QQXPRCkArbezV0kWuMHmAP5IzDnPoTDELgKtdT0ppDhY0eoeuFZ+2mC
# jcyQl7H1+uY70yV1R+NQbnqwhbphUXpiNf72tPUkN0IMdujmdmJqwyKAYprAZvYe
# oPv+SNFHrtG9WHtDidq0BW7jpl/kwu+JHTE3lw0bbTHAHCC21pgSTleVQtoEfk6d
# fPZ5agjH5KMM7sG3kG4AFZjxK+ZFB8HJPZymkTNOO39+zTGngHVwAdUPCUbBm6/1
# F9zed13GAWsoDwxYdskXT5pZRRggFHwXLaC4VUegd47N7sixvK9GtrH//zeBiqjx
# zln/X+7uSMtxOCKmLJnxcRGwsQQInmjHUEEtjoCOZuADMN02XYt56P6oht0Gv9JS
# 8oQL5fDjGMUw5NRVYpZ6a3aSHCd1R8E1Hs3O7XP0vRa/tMBj+/6/qk2EB6iE8wIU
# lz5qTq4wPxMpLNYWPDloAOSYP2Ya4LzrK9IqQgjgxrLOhR2x5PSd+TxjR8+O13DZ
# ad6OXrMse5hfBwNq7Y7UMy6iJ501WNMXftQSZhP6jEL84VdQY8MRC323OBtH2Dwc
# u1R8R5Y6w4QPnGBvmvDJ+8iyzsf9x0cVwiIhzPNCBiewvIQZ6mhkOQqFIxHl4IHo
# py/9AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUM+EBhZLSgD6U60hN+Mm3KXSSdFEw
# HwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
# UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAw
# XjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8E
# BAMCB4AwDQYJKoZIhvcNAQELBQADggIBAJeH5yQKRloDTpI1b6rG1L2AdCnjHsb6
# B2KSeAoi0Svyi2RciuZY9itqtFYGVj3WWoaKKUfIiVneI0FRto0SZooAYxnlhxLs
# hlQo9qrWNTSazKX7yiDS30L9nbr5q3He+yEesVC5KDBMdlWnO/uTwJicFijF2EjW
# 4aGofn3maou+0yzEQ3/WyjtT5vdTosKvLm7DBzPn6Pw6PQZRfdv6JmD4CzTFM3pP
# RBrwE15z8vBzKpg0RoyRbZUAquaG9Yfw4INNxeA42ecAFAcF9cr98sBscUZLVc06
# 2vrb+JocEYCSsIaXoGLw9/Czp+z7D6wT2veFf1WDSCxEygdG4xqJeysaYay5icuf
# cDBOC4xq3D1HxTm8m1ZKW7UIU7k/QsS9BCIxnXaxBKxACQ0NOz2tONU2OMhSChnp
# c8zGVw8gNyPHDxt95vjLjADEzZFGhZzGmTH7ogh/Yv5vuAse0HFcJYnlsxbtbBQL
# YuW1u6tTAG/RKCOkO1sSrD+4OBYF6sJP5m3Lc1z3ruIZpCPJhAfof+H1dzyyabaf
# pWPJJHHazCdbeGvpDHrdT/Fj0cvoU2GsaIUQPtlEqufC+9e8xVBQgSQHsZQR43qF
# 5jyAcu3SMtXfLMOJADxHynlgaAYBW30wTCAAk1jWIe8f/y/OElJkU2Qfyy9HO07+
# LdO8quNvxnHCMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+
# F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU
# 88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqY
# O7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzp
# cGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0Xn
# Rm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1
# zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZN
# N3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLR
# vWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTY
# uVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUX
# k8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB
# 2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKR
# PEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0g
# BFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQ
# W9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNv
# bS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBa
# BggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqG
# SIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOX
# PTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6c
# qYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/z
# jj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz
# /AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyR
# gNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdU
# bZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo
# 3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4K
# u+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10Cga
# iQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9
# vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGC
# A00wggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTAwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
# ALy3yFPwopRf3WVTkWpE/0J+70yJoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDo3NChMCIYDzIwMjMxMDIwMTAx
# MDQxWhgPMjAyMzEwMjExMDEwNDFaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOjc
# 0KECAQAwBwIBAAICFDcwBwIBAAICEmkwCgIFAOjeIiECAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEANBuyICBJ1OHrQBWXRNCRh9x+J0Iy6TQrT9vmb9StvgrT
# v9RJz775AWbA+qxap3ap1qxW7Y74hY4c6q671QkcjMo7KcxxD3fhFY6kLQNAHy5o
# QYAydqLDjJ+vJOjm1IKc1ZJCfDkm2u+Kd6tSSuptlUB97UyG12ZjyiV/7UvkfrKu
# TCwFwTKKwD67JNyqjokZu0EWcGon1vSwXD0fvKfg4GfcMfyFJdB0USmLpcDKuljY
# YN5pCjKWz7oIIPDp2igeUY3ppPjV1bzYdUPpEB8MaGVNZLdmfvXRIav89V02QVW+
# +AhuLvylnEVbkvbXhsjNQuiB7b/3xkGeQw6uYH8YVDGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB0HcIqu+jF8bdAAEAAAHQ
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIGQ1ci/YpMiVN/eg5OOCYqj/tlRlQAYLCCX00ORMwQkF
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgCJVABl+00/8x3UTZjD58Fdr3
# Dp+OZNnlYB6utNI/CdcwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAdB3CKrvoxfG3QABAAAB0DAiBCAqo1MsfKSJR5Q9Z6OosvBYr5NG
# oBBhSXl0xJXEG/Xz6TANBgkqhkiG9w0BAQsFAASCAgB5t8Azdnwxa3vEw3tGTiPa
# hTCktSLOmwSJJEunzC9uPUEnmvOprpYpG564C6sUcqVyoD5ylIBVRxZss3EE7ejE
# ldbu9NGyL4Su75y0Lpzc2KQO5MvVmbXTvdLnInN9axzBRBrwV0l+ztVmzh2pCCT6
# ROGnUcJsTtcvZPc2a24vZgx8RO4ClkBe6KSxMYZr5LKMk5GAnh57IG+hD/l792Pi
# R7lo3l918eI8edRHy6RFB+zPFv56C1U0hDX0N5+E+bmXsi3oaJnkiOuf83pgLmZR
# BIgxx1ciZ3tKhewkf+u/zzRHJRVd3i5r18kH093TDhJRARc1Ng2wcXpCt51S0vtV
# jNmIso2p4xmAdG+nExpmdeVxJTSA6MrNd/SLVbsmiLeC3VN9vpXw4m/+jhprWtyp
# MoEw4dGLhMq/5FwVkgx0g2zobYFz5wJU15bjlH7MV0qwzwycYIiSuJ/LYSb+HvVW
# E/EJNtPQeL17Di+1zurwckT0WREFyCyO8lQA7Ksm8ahBdsGKZF1Lb3asVwpTdPf6
# Do61mdJj/ZSjg8ibCa0krbKxsQu392Xtgnk/S+CuDzGGfI9t+Hiis4VjMQI1DQbZ
# NcPz1ulNnXF+sN/+G1CkMoHrAPtaauJT7uILH44dqxEMieBN0uwRv7M4JnPTKx3o
# OMDFswDaVsiC1eW1VdAtWA==
# SIG # End signature block
