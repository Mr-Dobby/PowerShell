<#
.SYNOPSIS
   MSRD-Collect HTML functions

.DESCRIPTION
   Module for the MSRD-Collect html functions

.NOTES
   Author     : Robert Klemencz
   Requires   : At least PowerShell 5.1 (This module is not for stand-alone use. It is used automatically from within the main MSRD-Collect.ps1 script)
   Version    : See MSRD-Collect.ps1 version
   Feedback   : Send an e-mail to MSRDCollectTalk@microsoft.com
#>


#region HTML functions

Function msrdHtmlInit {
    param ($htmloutfile)

    #html report initialization
    msrdCreateLogFolder $global:msrdLogDir

    New-Item -Path $htmloutfile -ItemType File | Out-Null

    Set-Content $htmloutfile "<!DOCTYPE html>
<html>"
}

Function msrdHtmlHeader {
    param ($htmloutfile, $title, $fontsize)

    #html report header
Add-Content $htmloutfile "<head>
    <title>$title</title>
</head>
<style>
    .table-container { position: fixed; width: 100%; top: 0; left: 0; z-index: 1; background-color: white; }
    .WUtable-container { position: relative; display: inline-block; width: 100%; }
    BODY { font-family: Arial, Helvetica, sans-serif; font-size: $fontsize; }
    table { background-color: white; border: none; width: 100%; padding-left: 5px; padding-right: 5px; padding-bottom: 5px; }
    td { word-break: break-all; border: none; }
    th { border-bottom: solid 1px #CCCCCC; }

    .tduo { border: 1px solid #BBBBBB; background-color: white; vertical-align:top; border-radius: 5px; box-shadow: 1px 1px 2px 3px rgba(12,12,12,0.2); }
    .tduo tr:hover { background-color: #BBC3C6; }

    details > summary { background-color: #7D7E8C; color: white; cursor: pointer; padding: 5px; border:1px solid #BBBBBB; text-align: left; font-size: 13px; border-radius: 5px; }
    .detailsP { padding: 5px 5px 10px 15px; }

    .scroll { padding-top: 140px; box-sizing: border-box; }

    .cText { padding-left: 5px; }
    .cTable1-2 { padding-left: 5px; width: 12%; }
    .cTable1-3 { padding-left: 5px; width: 12%; }
    .cTable1-3b { width: 53%; }
    .cTable2-1 { padding-left: 5px; width: 65%; }
    .b2top a { color:white; float:right; text-decoration: none; }
    .menubutton { width: 150px; cursor: pointer; filter: drop-shadow(3px 3px 1px rgba(0, 0, 0, 0.25)) }

    .circle_green { vertical-align:top; padding-left: 5px; border: 1px solid #a1a1a1; padding: 5px 3px; background: #009933; border-radius: 100%; width: 5px; heigth: 5px }
    .circle_red { vertical-align:top; padding-left: 5px; border: 1px solid #a1a1a1; padding: 5px 3px; background: red; border-radius: 100%; width: 5px; heigth: 5px }
    .circle_blue { vertical-align:top; padding-left: 5px; border: 1px solid #a1a1a1; padding: 5px 3px; background: blue; border-radius: 100%; width: 5px; heigth: 5px }
    .circle_white { vertical-align:top; padding-left: 5px; border: 1px solid #a1a1a1; padding: 5px 3px; background: white; border-radius: 100%; width: 5px; heigth: 5px }
    .circle_no { vertical-align:top; padding-left: 5px; border: 1px solid white; padding: 5px 3px; background: white; border-radius: 100%; width: 5px; heigth: 5px }

    .circle_redCounter { display: inline-block; vertical-align: middle; width: 10px; height: 10px; border-radius: 50%; background-color: red; border: 1px solid #a1a1a1; margin-bottom: 2px; }

    .dropdown-wrapper { background-color: white; position: fixed; cursor: pointer; display: flex; align-items: center; flex-direction: column; left: 50%; transform: translateX(-50%); width: 100%; margin: 0 auto; padding-bottom: 10px; padding-top: 5px;}
    .dropdown { position: relative; margin-right: 5px; }
	.dropdown button { background-color: #7D7E8C; color: #fff; border: none; border-radius: 5px; padding: 8px 14px; line-height: 14px; cursor: pointer; transition: background-color 0.3s; }
	.dropdown-content { display: none; position: absolute; background-color: #fff; min-width: 160px; box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2); z-index: 1; white-space: nowrap; }
	.dropdown-content a { padding: 10px; text-decoration: none; display: block; color: #000; }
    .dropdown:hover button { background-color: #5b5b5b; }
    .dropdown:hover .dropdown-content { display: block; }
    .dropdown:hover .dropdown-content a:hover { background-color: #BBC3C6; color: #000; }
    .dropdown:last-child { margin-right: 0; }

    .buttons-container { display: flex; justify-content: center; flex-wrap: wrap; }
    .text-container { text-align: center; margin-top: 5px; }
    .right-aligned-text { text-align: right; width: 100%; margin-right: 50px; }
</style>"
}

Function msrdHtmlMenu {
    Param ($htmloutfile, [string]$CatText, [System.Collections.Generic.Dictionary[String,String]]$BtnTextAndId)

    Add-Content $htmloutfile "<div class='dropdown'><button>$CatText</button><div class='dropdown-content'>"

    foreach ($txt in $BtnTextAndId.GetEnumerator()) {
        $btnLink = $txt.Value
        $btnText = $txt.Key
        Add-Content $htmloutfile "<a href='$btnLink'>$btnText</a>"
    }

    Add-Content $htmloutfile "</div></div>"

}

Function msrdHtmlBodyDiag {
    Param ($htmloutfile, $title, [bool[]]$varsSystem, [bool[]]$varsAVDRDS, [bool[]]$varsInfra, [bool[]]$varsAD, [bool[]]$varsNET, [bool[]]$varsLogSec, [bool[]]$varsIssues, [bool[]]$varsOther)

    #html report body
    Add-Content $htmloutfile "
<body>
    <div class='table-container'>
        <div style='text-align:center;'><a name='TopDiag'></a><b><h3>$title</h3></b></div>
        <div class='dropdown-wrapper'>
            <div class='buttons-container'>
"

#region menu
    #system

    if ($true -in $varsSystem) {
        $BtnsSystem = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsSystem[0]) { $BtnsSystem.Add("Core", "#DeploymentCheck") }
        if ($varsSystem[1]) { $BtnsSystem.Add("CPU Utilization", "#CPUCheck") }
        if ($varsSystem[2]) { $BtnsSystem.Add("Drives", "#DiskCheck") }
        if ($varsSystem[3]) { $BtnsSystem.Add("Graphics", "#GPUCheck") }
        if (!($global:msrdSource)) { if ($varsSystem[4]) { $BtnsSystem.Add("OS Activation / Licensing", "#KMSCheck") } }
        if ($varsSystem[5]) { $BtnsSystem.Add("SSL / TLS", "#SSLCheck") }
        if ($varsSystem[6]) { $BtnsSystem.Add("User Account Control", "#UACCheck") }
        if ($varsSystem[7]) { $BtnsSystem.Add("Windows Installer", "#InstallerCheck") }
        if (!($global:msrdSource)) { if ($varsSystem[8]) { $BtnsSystem.Add("Windows Search", "#SearchCheck") } }
        if ($varsSystem[9]) { $BtnsSystem.Add("Windows Update", "#WUCheck") }
        if ($varsSystem[10]) { $BtnsSystem.Add("WinRM / PowerShell", "#WinRMPSCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "System" -BtnTextAndId $BtnsSystem
    }

    #avd/rds/w365
    if ($true -in $varsAVDRDS) {
        $BtnsAVDRDS = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsAVDRDS[0]) { $BtnsAVDRDS.Add("Device and Resource Redirection", "#RedirCheck") }
        if (!($global:msrdSource)) { if ($varsAVDRDS[1]) { $BtnsAVDRDS.Add("FSLogix", "#ProfileCheck") } }
        if ($varsAVDRDS[2]) { $BtnsAVDRDS.Add("Multimedia", "#MultiMedCheck") }
        if ($varsAVDRDS[3]) { $BtnsAVDRDS.Add("Quick Assist", "#QACheck") }
        if (!($global:msrdSource)) {
            if ($varsAVDRDS[4]) { $BtnsAVDRDS.Add("RDP / Listener", "#ListenerCheck") }
            if ($global:msrdOSVer -like "*Windows Server*") {
                if ($varsAVDRDS[5]) { $BtnsAVDRDS.Add("RDS Roles", "#RolesCheck") }
            }
        }
        if ($varsAVDRDS[6]) { $BtnsAVDRDS.Add("Remote Desktop Clients", "#RDCCheck") }
        if (!($global:msrdSource)) {
            if (!($global:msrdW365)) {
                if ($varsAVDRDS[7]) { $BtnsAVDRDS.Add("Remote Desktop Licensing", "#LicCheck") }
            }
            if ($varsAVDRDS[8]) { $BtnsAVDRDS.Add("Session Time Limits", "#STLCheck") }
        }
        if (!($global:msrdRDS)) {
            if ($varsAVDRDS[9]) { $BtnsAVDRDS.Add("Teams Media Optimization", "#TeamsCheck") }
        }

        if ($global:msrdRDS) {
            msrdHtmlMenu -htmloutfile $htmloutfile -CatText "RDS" -BtnTextAndId $BtnsAVDRDS
        } elseif ($global:msrdAVD) {
            msrdHtmlMenu -htmloutfile $htmloutfile -CatText "AVD/RDS" -BtnTextAndId $BtnsAVDRDS
        } elseif ($global:msrdW365) {
            msrdHtmlMenu -htmloutfile $htmloutfile -CatText "AVD/RDS/W365" -BtnTextAndId $BtnsAVDRDS
        }
    }

    #avd infra
    if (!($global:msrdRDS)) {
        if ($true -in $varsInfra) {
            $BtnsAVDInfra = [System.Collections.Generic.Dictionary[String,String]]@{}

            if (!($global:msrdSource)) {
                if ($varsInfra[0]) { $BtnsAVDInfra.Add("AVD Agents / SxS Stack", "#AgentStackCheck") }
                if ($varsInfra[1]) { $BtnsAVDInfra.Add("AVD Host Pool", "#HPCheck") }
            }
            if ($varsInfra[2]) { $BtnsAVDInfra.Add("AVD Required URLs", "#URLCheck") }

            if (!($global:msrdSource)) {
                if ($varsInfra[3]) { $BtnsAVDInfra.Add("AVD Services URI Health", "#BrokerURICheck") }
            }
            if ($global:msrdAVD -and !($global:msrdSource)) {
                if ($varsInfra[4]) { $BtnsAVDInfra.Add("Azure Stack HCI", "#HCICheck") }
            }
            if ($varsInfra[5]) { $BtnsAVDInfra.Add("RDP Shortpath", "#UDPCheck") }
            if ($global:msrdW365) {
                if ($varsInfra[6]) { $BtnsAVDInfra.Add("Windows 365 Cloud PC Required URLs", "#CPCCheck") }
            }

            if ($global:msrdW365) {
                msrdHtmlMenu -htmloutfile $htmloutfile -CatText "AVD/W365 Infra" -BtnTextAndId $BtnsAVDInfra
            } else {
                msrdHtmlMenu -htmloutfile $htmloutfile -CatText "AVD Infra" -BtnTextAndId $BtnsAVDInfra
            }
        }
    }

    #ad
    if ($true -in $varsAD) {
        $BtnsAD = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsAD[0]) { $BtnsAD.Add("Microsoft Entra Join", "#AADJCheck") }
        if ($varsAD[1]) { $BtnsAD.Add("Domain", "#DCCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Active Directory" -BtnTextAndId $BtnsAD
    }

    #networking
    if ($true -in $varsNET) {
        $BtnsNet = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsNET[0]) { $BtnsNet.Add("Core NET", "#NWCCheck") }
        if ($varsNET[1]) { $BtnsNet.Add("DNS", "#DNSCheck") }
        if ($varsNET[2]) { $BtnsNet.Add("Firewall", "#FWCheck") }
        if ($varsNET[3]) { $BtnsNet.Add("IP Addresses", "#PublicIPCheck") }
        if ($varsNET[4]) { $BtnsNet.Add("Proxy", "#ProxCheck") }
        if ($varsNET[5]) { $BtnsNet.Add("Routing", "#RoutingCheck") }
        if ($varsNET[6]) { $BtnsNet.Add("VPN", "#VPNCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Networking" -BtnTextAndId $BtnsNet
    }

    #logon/security
    if ($true -in $varsLogSec) {
        $BtnsLogSec = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsLogSec[0]) { $BtnsLogSec.Add("Authentication / Logon", "#AuthCheck") }
        if ($varsLogSec[1]) { $BtnsLogSec.Add("Security", "#SecCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Logon / Security" -BtnTextAndId $BtnsLogSec
    }

    #known issues
    if ($true -in $varsIssues) {
        $BtnsIssues = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsIssues[0]) { $BtnsIssues.Add("Issues found in Event Logs over the past 5 days", "#IssuesCheck") }
        if (!($global:msrdSource)) { if ($varsIssues[1]) { $BtnsIssues.Add("Potential Logon/Logoff Issue Generators", "#BlackCheck") } }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Known Issues" -BtnTextAndId $BtnsIssues
    }

    #other
    if ($true -in $varsOther) {
        $BtnsOther = [System.Collections.Generic.Dictionary[String,String]]@{}

        if (!($global:msrdSource)) {
            if ($varsOther[0]) { $BtnsOther.Add("Office", "#MSOCheck") }
            if ($varsOther[1]) { $BtnsOther.Add("OneDrive", "#MSODCheck") }
        }
        if ($varsOther[2]) { $BtnsOther.Add("Printing", "#PrintCheck") }
        if ($varsOther[3]) { $BtnsOther.Add("Third Party Software", "#3pCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Other" -BtnTextAndId $BtnsOther
    }
#endregion menu

Add-Content $htmloutfile "
            </div>
            <div class='right-aligned-text'>
                <div style='text-align: right;'><a href='#/' id='expAll' class='col' title='Hide/Show all categories'>Hide/Show All</a></div>
            </div>
        </div>
    </div>
    <div class='scroll'>
        <table>
            <tr><td>"
}

Function msrdHtmlBodyWU {
    Param ($htmloutfile, $title)

	Add-Content $htmloutfile "<body>
	<div class='WUtable-container'>
	<table>
		<tr><td style='text-align:center; padding-bottom: 10px;' colspan='6'><a name='TopDiag'></a><b><h2>$title</h2></b>

			<table>
				<tr>
					<td style='text-align:center;'><a href='#COM'><button class='menubutton'>Updates (COM)</button></a>&nbsp;
					<a href='#QFE'><button class='menubutton'>Other (QFE)</button></a>&nbsp;
					<a href='#REG'><button class='menubutton'>Other (Registry)</button></a></td>
				</tr>
			</table>
		</td></tr>

	<tr><td style='text-align:left; font-size: 13px; padding-bottom: 5px'><b>Operating System: $msrdGetos</b></td><td align='right' style='height:5px;'><a href='#/' id='expAll' class='col'>Hide/Show All</a></td></tr>
	<tr><td colspan='2'>
	<details open>
		<summary>
			<a name='COM'></a><b>Microsoft.Update.Session</b><span class='b2top'><a href='#'>^top</a></span>
		</summary>
		<div class='detailsP'>
			<table class='tduo'>
				<tr style='text-align: left;'>
					<th width='10px'><div class='circle_no'></div></th><th style='padding-left: 5px;'>Category</th><th>Date/Time</th><th>Operation</th><th>Result</th><th>KB</th><th>Description</th>
				</tr>
	"
}

Function msrdHtmlEnd {
    Param ($htmloutfile)

    $dateTime = Get-Date
    $dateOnly = $dateTime.ToString("MMMM d, yyyy")
    $timeOnly = $dateTime.ToString("h:mm:ss tt")

    #html report footer
    Add-Content $htmloutfile "</tbody></table></div></details>
        </td></tr>
    </table>
    </div>

    <script type='text/javascript'>
        const xa = document.getElementById('expAll');

        xa.addEventListener('click', function(e) {
            e.currentTarget.classList.toggle('exp');
            e.currentTarget.classList.toggle('col');

            const details = document.querySelectorAll('details');

            Array.from(details).forEach(function(obj, idx) {
                if (e.currentTarget.classList.contains('exp')) {
                    obj.removeAttribute('open');
                } else {
                    obj.open = true;
                }
            });
        }, false);
    </script>

    <footer style='padding: 10px; font-size: 11px;'><i>Report finished on $dateOnly at $timeOnly - Script version $msrdVersion (Get the latest version from <a href='https://aka.ms/MSRD-Collect' target='_blank'>https://aka.ms/MSRD-Collect</a> - For any feedback use <a href='https://aka.ms/MSRD-Collect-Survey' target='_blank'>https://aka.ms/MSRD-Collect-Survey</a> or email <a href='mailto:MSRDCollectTalk@microsoft.com?subject=MSRD-Collect%20Feedback'>MSRDCollectTalk@microsoft.com</a>)</i>
    <table><tr><td colspan='2'>Legend<td><tr>
    <tr><td width='10px'><div class='circle_green'></div></td><td>Expected value/status</td></tr>
    <tr><td width='10px'><div class='circle_blue'></div></td><td>Value/status should be evaluated for relevance</td></tr>
    <tr><td width='10px'><div class='circle_red'></div></td><td>Value/status is unexpected, problematic or might cause problems in certain circumstances</td></tr>
    <tr><td width='10px'><div class='circle_white'></div></td><td>Value/status not found or generic information</td></tr>
    <tr><td width='10px'><div>&#9432;</div></td><td>Hover over the icon with the mouse cursor for additional information</td></tr></table>
    </footer>
    </body>
</html>"
}

Function msrdHtmlSetMenuWarning {
    param ($MenuCat, $MenuItem, $htmloutfile)

    #html report menu item warning
    if (Test-Path -path $htmloutfile) {

        $msrdDiagFileContent = Get-Content -Path $htmloutfile
        $msrdDiagFileReplace = foreach ($diagItem in $msrdDiagFileContent) {
            if ($diagItem -match "(.*>$MenuItem</a>)$") {
                $diagItem -replace $MenuItem, "$MenuItem <span style='color: red;'>&#9888;</span>"
            } elseif ($diagItem -match "(.*<button>$MenuCat</button>.*)") {
                $diagItem -replace $MenuCat, "$MenuCat <span style='color: red;'>&#9888;</span>"
            } else {
                $diagItem
            }
        }
        $msrdDiagFileReplace | Set-Content -Path $htmloutfile
    }
}

Function msrdHtmlSetIssueCounter {
    param ($htmloutfile)

    if (Test-Path -path $htmloutfile) {

        if ($global:msrdIssueCounter -gt 0) {
            if ($global:msrdIssueCounter -eq 1) {
                $info = "<div class='text-container'><span style='color: red;'>$global:msrdIssueCounter</span> source of potential problems has been identified.<br>See the menu item with a red exclamation mark [<span style='color: red;'>&#9888;</span>] and the corresponding line marked with a red circle [<span class='circle_redCounter'></span>]</div>"
            } elseif ($global:msrdIssueCounter -gt 1) {
                $info = "<div class='text-container'><span style='color: red;'>$global:msrdIssueCounter</span> sources of potential problems have been identified.<br>See the menu items with a red exclamation mark [<span style='color: red;'>&#9888;</span>] and the corresponding lines marked with a red circle [<span class='circle_redCounter'></span>]</div>"
            }

            $msrdDiagFileContent = Get-Content -Path $htmloutfile
            $msrdDiagFileReplace = foreach ($diagItem in $msrdDiagFileContent) {
                if ($diagItem -match "<div class='right-aligned-text'>") {
                    $diagItem -replace $diagItem, "$info $diagItem"
                } else {
                    $diagItem
                }
            }
            $msrdDiagFileReplace | Set-Content -Path $htmloutfile
        }
    }
}

#endregion HTML functions

Export-ModuleMember -Function *

# SIG # Begin signature block
# MIIoOQYJKoZIhvcNAQcCoIIoKjCCKCYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBEs1INfhvKxTQU
# NQsiiQR3MTcowtCbiUAcUdWlLJ+WlKCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGgowghoGAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPxp
# zkiEx4ZF0oxDf0xA6rLeY1PGxM/SWUURP7hvS2/GMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAMjN6xCCZGDD56PcG9RSAGawuJXmcjRZsO/G9
# cl3rciFQ8jbM/GEJoIfCO5NgaF91HwN0XWUGhbK5RCOjW5c7AQtUDDW329x5+eS3
# 94PlBMKqQfu/WHnU7mGWm557wMVzXIO8Ep5AK5Tgvt5dLdfoMLv7EiEOkURl7Jke
# 9HzAJkavQzuCPu4BZNhHgjIGz0jYT70zK5FvyK7i/6DwiW+pS2KuRZ3zYHjJe50v
# 5vvm3xzRg5MNxS8LNAy9TKlgW0ees5MH+KAavRyssyagVl0tce6+6h/rl0SKYiMm
# qDredOmTVdpT25/4m+P0dbQ0xTffHz0ZXFD0X1+s4ytLDyJPXaGCF5QwgheQBgor
# BgEEAYI3AwMBMYIXgDCCF3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFSBgsqhkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCDJhhLMIOwaQbnY6Vy6waEXE+XhREKECY3x
# wPFM+S0xvgIGZkZX1jFvGBMyMDI0MDYxMjE1MDA0My41NTRaMASAAgH0oIHRpIHO
# MIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
# IFRTUyBFU046MzMwMy0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFNlcnZpY2WgghHqMIIHIDCCBQigAwIBAgITMwAAAebZQp7qAPh94QAB
# AAAB5jANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDAeFw0yMzEyMDYxODQ1MTVaFw0yNTAzMDUxODQ1MTVaMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC9vph84tgluEzm/wpNKlAj
# cElGzflvKADZ1D+2d/ieYYEtF2HKMrKGFDOLpLWWG5DEyiKblYKrE2nt540OGu35
# Zx0gXJBE0zWanZEAjCjt4eGBi+uakZsk70zHTQHHyfP+B3m2BSSNFPhgsVIPp6vo
# /9t6OeNezIwX5E5+VwEG37nZgEexQF2fQZYbxQ1AauqDvRdXsSpK1dh1UBt9EaMs
# zuucaR5nMwQN6sDjG99FzdK9Atzbn4SmlsoLUtRAh/768sKd0Y1hMmKVHwIX8/4J
# uURUBRZ0JWu0NYQBp8khku18Q8CAQ500tFB7VH3pD8zoA4lcA7JkxTGoPKrufm+l
# RZAA4iMgbcLZ2P/xSdnKFxU8vL31RoNlZJiGL5MqTXvvyBLz+MRP4En9Nye1N8x/
# lJD1stdNo5wJG+mgXsE/zfzg2GaVqQczFHg0Nl8bpIqnNFUReQRq3C1jVYMCSceg
# NzHeYtw5OmZ/7eVnRmjXlCsLvdsxOzc1YVn6nZLkQD5y31HYrB9iIHuswhaMv2hJ
# NNjVndkpWy934PIZuWTMk360kjXPFwl2Wv1Tzm9tOrCq8+l408KIL6J+efoGNkR8
# YB3M+u1tYeVDO/TcObGHxaGFB6QZxAUpnfB5N/MmBNxMOqzG1N8QiwW8gtjjMJiF
# Bf6iYYrCjtRwF7IPdQLFtQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFOUEMXntN54+
# 11ZM+Qu7Q5rg3Fc9MB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBhbuogTapRsuwS
# kaFMQ6dyu8ZCYUpWQ8iIrbi40tU2hK6pHgu0hj0z/9zFRRx5DfhukjvbjA/dS5VY
# fxz1EIbPlt897MJ2sBGO2YLYwYelfJpDwbB0XS9Zkrqpzq6X/lmDQDn3G5vcYpYQ
# CJ55LLvyFlJ195AVo4Wy8UX5p7g9W3MgNHQMpM+EV64+cszj4Ho5aQmeKGtKy7w7
# 2eRY/vWDuptrvzruFNmKCIt12UcA5BOsXp1Ptkjx2yRsCj77DSml0zVYjqW/ISWk
# rGjyeVJ+khzctxaLkklVwCxigokD6fkWby0hCEKTOTPMzhugPIAcxcHsR2sx01YR
# a9pH2zvddsuBEfSFG6Cj0QSvEZ/M9mJ+h4miaQSR7AEbVGDbyRKkYn80S+3AmRlh
# 3ZOe+BFqJ57OXdeIDSHbvHzJ7oTqG896l3eUhPsZg69fNgxTxlvRNmRE/+61Yj7Z
# 1uB0XYQP60rsMLdTlVYEyZUl5MLTL5LvqFozZlS2Xoji4BEP6ddVTzmHJ4odOZMW
# TTeQ0IwnWG98vWv/roPegCr1G61FVrdXLE3AXIft4ZN4ZkDTnoAhPw7DZNPRlSW4
# TbVj/Lw0XvnLYNwMUA9ouY/wx9teTaJ8vTkbgYyaOYKFz6rNRXZ4af6e3IXwMCff
# CaspKUXC72YMu5W8L/zyTxsNUEgBbTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKb
# SZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIy
# NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXI
# yjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjo
# YH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1y
# aa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v
# 3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pG
# ve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viS
# kR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYr
# bqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlM
# jgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSL
# W6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AF
# emzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIu
# rQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIE
# FgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWn
# G1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEW
# M2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5
# Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBi
# AEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV
# 9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3Js
# Lm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAx
# MC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2
# LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv
# 6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZn
# OlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1
# bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4
# rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU
# 6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDF
# NLB62FD+CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/
# HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdU
# CbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKi
# excdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTm
# dHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZq
# ELQdVTNYs6FwZvKhggNNMIICNQIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjMzMDMtMDVF
# MC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMK
# AQEwBwYFKw4DAhoDFQDiWNBeFJ9jvaErN64D1G86eL0mu6CBgzCBgKR+MHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hPEJTAi
# GA8yMDI0MDYxMjA2NTIyMVoYDzIwMjQwNjEzMDY1MjIxWjB0MDoGCisGAQQBhFkK
# BAExLDAqMAoCBQDqE8QlAgEAMAcCAQACAgzLMAcCAQACAhN9MAoCBQDqFRWlAgEA
# MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAI
# AgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAIAlF48QzlI0/nUHE309In7Re3wM
# MsGVjJvH8QyDFSgdoxa7iAmmbjxSHDj6ROWkpC+pwCh+5mnmtyOY+qgPJEZEcevG
# QOsMAgxSDwgFkjGjLOH10ANMGpv4Lgoff15oV0kg8+vW2w/iCzmazenro/KU2s6j
# Z27cpZ1OxWwThafsEoZaHcAVrR5ltkJExcEgSxfLnFTE9citlY/FGfJPAoPLArf9
# as9MesxZrnhwS1Rdd46zfa2R/Wt/seKge8aJHEJfs3QRx4M+hhQUVBnsyUrMImxM
# vXTW9w442Q6+6RTSZb8etmYaQLmFut1dPrTkvFtMH2B/ScfASx1jnJLzzY4xggQN
# MIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAebZ
# Qp7qAPh94QABAAAB5jANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0G
# CyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDcjT6j1knS363kXIbtddvpOCYj
# 7wNzuPfF9aGaLZVHoDCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIM+7o4ao
# HrMJaG8gnLO1q16hIYcRnoy6FnOCbnSD0sZZMIGYMIGApH4wfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAHm2UKe6gD4feEAAQAAAeYwIgQgy6KmSaER
# UFw5zM8ixrWjedEWrCkXYG0+8JQBRQ+GJXIwDQYJKoZIhvcNAQELBQAEggIAYT0R
# vuxr8kqV8dT0KqhOQypV25gytQ4/6/L3FuqWWCW+1V8ASmNEizZ9ZSA3eVsYZRYR
# H0DzNV7jqHiCpDT1VNCJ1P5Dn8Rk9p6GE+Ye9vd9KuBkCT2aT8z041PVvgVQcYbJ
# mnKTFu+KAx+WhK+v1DCvEyKFUTQqlcAGqpqdx0Uu+MxRtiBE2UauZY6eV45Tk35H
# 51empF8tx18+CA/AM5CouxgBRYwKRdMHhfO66NcIUglr7qjoZo2UMmpaONcSlt//
# aiuYuHtpAdlsaBEzSHLIkLY0FaSjHDHXIfJcW9ucaC506oJU2s4E3Qey723EFqAY
# +uITK/dlg2TQsu8iL1kZuvlD+p3l/ueuwi+WM2draIuQvXS+jdO4IfE37ZBNiW5K
# s1uayYl+UdI7oUtPxTiM6PqOvFYZbCCopXCpRAcqOqLKf22rpGcI3hfrjNd5Zi4f
# GlzGYj+4kbqOrvnQuWgp+lJFLak7sh0jhLDOjm0l1XFZIzXalAGGv78gCEEdcjbx
# qcQp0OR2uvNNOgxrolGpMbFlF9B7rzRy9l6Q0sBqyAB2EFaIP4S8TXD5h+B7g3WC
# qmco2Z5k1X4FYqSYKB1Q8hKPZeNczjru/CB7jkQYnuk9o6XO7QbZADVHWIcQeqJL
# /Qmahg1tBTl1umr16QWwKePRNEJXjPDL0laGh+U=
# SIG # End signature block
