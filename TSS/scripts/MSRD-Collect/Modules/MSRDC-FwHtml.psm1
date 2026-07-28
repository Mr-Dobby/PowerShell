<#
.SYNOPSIS
   MSRD-Collect HTML functions

.DESCRIPTION
   Module for the MSRD-Collect html functions

.NOTES
   Author     : Robert Klemencz
   Requires   : MSRD-Collect.ps1
   Version    : See MSRD-Collect.ps1 version
   Feedback   : https://aka.ms/MSRD-Collect-Feedback
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
    .circle_yellow { vertical-align:top; padding-left: 5px; border: 1px solid #a1a1a1; padding: 5px 3px; background: yellow; border-radius: 100%; width: 5px; heigth: 5px }
    .circle_red { vertical-align:top; padding-left: 5px; border: 1px solid #a1a1a1; padding: 5px 3px; background: red; border-radius: 100%; width: 5px; heigth: 5px }
    .circle_white { vertical-align:top; padding-left: 5px; border: 1px solid #a1a1a1; padding: 5px 3px; background: white; border-radius: 100%; width: 5px; heigth: 5px }
    .circle_no { vertical-align:top; padding-left: 5px; border: 1px solid white; padding: 5px 3px; background: white; border-radius: 100%; width: 5px; heigth: 5px }

    .circle_redCounter { display: inline-block; vertical-align: middle; width: 10px; height: 10px; border-radius: 50%; background-color: red; border: 1px solid #a1a1a1; margin-bottom: 2px; }
    .circle_yellowCounter { display: inline-block; vertical-align: middle; width: 10px; height: 10px; border-radius: 50%; background-color: yellow; border: 1px solid #a1a1a1; margin-bottom: 2px; }

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

    .legend-item { margin-bottom: 5px; }
    .circle { width: 10px; height: 10px; display: inline-block; margin-right: 5px; border-radius: 100%; }
    .blue { background-color: blue; border: 1px solid #a1a1a1; }
    .green { background-color: green; border: 1px solid #a1a1a1; }
    .yellow { background-color: yellow; border: 1px solid #a1a1a1; }
    .red { background-color: red; border: 1px solid #a1a1a1; }
    .white { background-color: white; border: 1px solid #a1a1a1; }
    .info { background-color: transparent; }

    .circle-with-content { width: 10px; height: 10px; display: inline-block; margin-right: 5px; border-radius: 100%; position: relative; border: 1px solid #a1a1a1; }
    .circle-with-content::before { content: 'i'; font-size: 10px; color: #a1a1a1; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }

    .legend-container { position: fixed; z-index: 1; display: none; width: 450px; padding: 10px; background-color: #fff; border: 1px solid #ccc; text-align: left; }
    .hide-show-all { display: inline-block; }
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
        if ($varsSystem[1]) { $BtnsSystem.Add("CPU Utilization and Handles", "#CPUCheck") }
        if ($varsSystem[2]) { $BtnsSystem.Add("Drives", "#DiskCheck") }
        if ($varsSystem[3]) { $BtnsSystem.Add("Graphics", "#GPUCheck") }
        if ($global:msrdTarget) {
            if ($varsSystem[4]) { $BtnsSystem.Add("Hyper-V Integration", "#HyperVCheck") }
            if ($varsSystem[5]) { $BtnsSystem.Add("OS Activation / Licensing", "#KMSCheck") }
        }
        if ($varsSystem[6]) { $BtnsSystem.Add("SSL / TLS", "#SSLCheck") }
        if ($varsSystem[7]) { $BtnsSystem.Add("User Account Control", "#UACCheck") }
        if ($varsSystem[8]) { $BtnsSystem.Add("Windows Installer", "#InstallerCheck") }
        if ($global:msrdTarget) { if ($varsSystem[9]) { $BtnsSystem.Add("Windows Search", "#SearchCheck") } }
        if ($varsSystem[10]) { $BtnsSystem.Add("Windows Update", "#WUCheck") }
        if ($varsSystem[11]) { $BtnsSystem.Add("WinRM / PowerShell", "#WinRMPSCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "System" -BtnTextAndId $BtnsSystem
    }

    #avd/rds/w365
    if ($true -in $varsAVDRDS) {
        $BtnsAVDRDS = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsAVDRDS[0]) { $BtnsAVDRDS.Add("Device and Resource Redirection", "#RedirCheck") }
        if ($global:msrdTarget) { if ($varsAVDRDS[1]) { $BtnsAVDRDS.Add("FSLogix", "#ProfileCheck") } }
        if ($varsAVDRDS[2]) { $BtnsAVDRDS.Add("Multimedia", "#MultiMedCheck") }
        if ($varsAVDRDS[3]) { $BtnsAVDRDS.Add("Quick Assist / Remote Help", "#QACheck") }
        if ($global:msrdTarget) {
            if ($varsAVDRDS[4]) { $BtnsAVDRDS.Add("RDP / Listener", "#ListenerCheck") }
            if ($global:msrdOSVer -like "*Windows Server*") {
                if ($varsAVDRDS[5]) { $BtnsAVDRDS.Add("RDS Roles", "#RolesCheck") }
            }
        }
        if ($global:msrdSource) { if ($varsAVDRDS[6]) { $BtnsAVDRDS.Add("Remote Desktop Clients", "#RDCCheck") } }

        if ($global:msrdAVD -or $global:msrdRDS) { if ($varsAVDRDS[7]) { $BtnsAVDRDS.Add("Remote Desktop Licensing", "#LicCheck") } }

        if ($global:msrdTarget) { if ($varsAVDRDS[8]) { $BtnsAVDRDS.Add("Session Time Limits", "#STLCheck") } }

        if ($global:msrdAVD -or $global:msrdW365) { if ($varsAVDRDS[9]) { $BtnsAVDRDS.Add("Teams Media Optimization", "#TeamsCheck") } }

        if ($global:msrdW365) { if ($varsAVDRDS[10]) { $BtnsAVDRDS.Add("Windows 365 Boot", "#CPCCheck") } }

        if ($global:msrdRDS) {
            msrdHtmlMenu -htmloutfile $htmloutfile -CatText "RDS" -BtnTextAndId $BtnsAVDRDS
        } elseif ($global:msrdAVD) {
            msrdHtmlMenu -htmloutfile $htmloutfile -CatText "AVD/RDS" -BtnTextAndId $BtnsAVDRDS
        } elseif ($global:msrdW365) {
            msrdHtmlMenu -htmloutfile $htmloutfile -CatText "AVD/RDS/W365" -BtnTextAndId $BtnsAVDRDS
        }
    }

    #avd infra
    if ($global:msrdAVD -or $global:msrdW365) {
        if ($true -in $varsInfra) {
            $BtnsAVDInfra = [System.Collections.Generic.Dictionary[String,String]]@{}

            if ($global:msrdTarget) {
                if ($varsInfra[0]) { $BtnsAVDInfra.Add("AVD Agents / SxS Stack", "#AgentStackCheck") }
                if ($varsInfra[1]) { $BtnsAVDInfra.Add("App Attach", "#AppAttachCheck") }
                if ($varsInfra[2]) { $BtnsAVDInfra.Add("AVD Services URI Health", "#BrokerURICheck") }
                if ($global:msrdAVD) { if ($varsInfra[3]) { $BtnsAVDInfra.Add("Azure Stack HCI", "#HCICheck") } }
                if ($varsInfra[4]) { $BtnsAVDInfra.Add("Health Checks", "#AVDHealthCheck") }
                if ($varsInfra[5]) { $BtnsAVDInfra.Add("Host Pool", "#HPCheck") }
                if ($varsInfra[6]) { $BtnsAVDInfra.Add("Monitoring", "#MonitorCheck")  }
            }
            if ($varsInfra[7]) { $BtnsAVDInfra.Add("RDP Shortpath", "#UDPCheck") }
            if ($varsInfra[8] -or ($global:msrdW365 -and $varsInfra[9])) { $BtnsAVDInfra.Add("Required Endpoints", "#URLCheck") }

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
        if ($varsNET[4]) { $BtnsNet.Add("Port Usage", "#PortUsageCheck") }
        if ($varsNET[5]) { $BtnsNet.Add("Proxy", "#ProxCheck") }
        if ($varsNET[6]) { $BtnsNet.Add("Routing", "#RoutingCheck") }
        if ($varsNET[7]) { $BtnsNet.Add("VPN", "#VPNCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Networking" -BtnTextAndId $BtnsNet
    }

    #logon/security
    if ($true -in $varsLogSec) {
        $BtnsLogSec = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsLogSec[0]) { $BtnsLogSec.Add("Authentication / Logon", "#AuthCheck") }
        if ($varsLogSec[1]) { $BtnsLogSec.Add("Security", "#SecCheck") }
        if ($varsLogSec[2]) { $BtnsLogSec.Add("Smart Card", "#SCardCheck") }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Logon / Security" -BtnTextAndId $BtnsLogSec
    }

    #known issues
    if ($true -in $varsIssues) {
        $BtnsIssues = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($varsIssues[0]) { $BtnsIssues.Add("Issues found in Event Logs over the past 5 days", "#IssuesCheck") }
        if ($global:msrdTarget) { if ($varsIssues[1]) { $BtnsIssues.Add("Potential Logon/Logoff Issue Generators", "#BlackCheck") } }

        msrdHtmlMenu -htmloutfile $htmloutfile -CatText "Known Issues" -BtnTextAndId $BtnsIssues
    }

    #other
    if ($true -in $varsOther) {
        $BtnsOther = [System.Collections.Generic.Dictionary[String,String]]@{}

        if ($global:msrdTarget) {
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
                <span class='legend-label' id='legend-label'>Legend</span> | <div class='hide-show-all'><a href='#/' id='expAll' class='col' title='Hide/Show all categories'>Hide/Show All</a></div>
                <div class='legend-container' id='legend-container'>
                    <div class='legend-item'><span class='circle white'></span> Evaluate relevance in the current troubleshooting context</div>
                    <div class='legend-item'><span class='circle green'></span> Expected value/status [OK]</div>
                    <div class='legend-item'><span class='circle yellow'></span> Carefully evaluate, might lead to issues [Warning]</div>
                    <div class='legend-item'><span class='circle red'></span> Very likely to cause issues or error retrieving information [Critical]</div>
                    <div class='legend-item'><span class='circle-with-content info'></span> Hover for additional information</div>
                </div>
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

	<tr><td style='text-align:left; font-size: 13px; padding-bottom: 5px'><b>Operating System: $global:msrdOSVer</b></td><td align='right' style='height:5px;'><a href='#/' id='expAll' class='col'>Hide/Show All</a></td></tr>
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

  <script>
    // Get elements
    var legendLabel = document.getElementById('legend-label');
    var legendContainer = document.getElementById('legend-container');

    // Show the legend container on hover and update its position
    legendLabel.addEventListener('mouseover', function(event) {
      legendContainer.style.display = 'block';
      updateLegendPosition(event);
    });

    // Hide the legend container on mouseout
    legendLabel.addEventListener('mouseout', function() {
      legendContainer.style.display = 'none';
    });

    // Update legend container position based on mouse coordinates
    function updateLegendPosition(event) {
      var x = event.clientX + 10; // Add an offset to prevent the popup from overlapping with the cursor
      var y = event.clientY + 10;

      // Adjust x position to ensure the popup stays within the visible area
      var maxX = window.innerWidth - legendContainer.clientWidth;
      x = Math.min(x, maxX);

      legendContainer.style.left = x + 'px';
      legendContainer.style.top = y + 'px';
    }

    // Update legend position on mousemove
    legendLabel.addEventListener('mousemove', function(event) {
      updateLegendPosition(event);
    });
  </script>

    <footer style='padding: 10px; font-size: 11px;'><i>Report generated on $dateOnly at $timeOnly - Script version $msrdVersion (Get the latest version from <a href='https://aka.ms/MSRD-Collect' target='_blank'>https://aka.ms/MSRD-Collect</a> - To provide feedback use <a href='https://aka.ms/MSRD-Collect-Feedback' target='_blank'>https://aka.ms/MSRD-Collect-Feedback</a>)</i><br>
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
                $info = "<div class='text-container'><span style='color: red;'>$global:msrdIssueCounter</span> source of potential problems has been identified.<br>See the menu item with a red exclamation mark [<span style='color: red;'>&#9888;</span>] and the corresponding line marked with a red [<span class='circle_redCounter'></span>] or yellow [<span class='circle_yellowCounter'></span>] circle.</div>"
            } elseif ($global:msrdIssueCounter -gt 1) {
                $info = "<div class='text-container'><span style='color: red;'>$global:msrdIssueCounter</span> sources of potential problems have been identified.<br>See the menu items with a red exclamation mark [<span style='color: red;'>&#9888;</span>] and the corresponding lines marked with a red [<span class='circle_redCounter'></span>] or yellow [<span class='circle_yellowCounter'></span>] circle.</div>"
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
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA+iidGp2tKpAwH
# 1Zss5KlDBzN6Yz7lrWAV0ksK+OasZaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBy9EtyehvODXykzL7WE9iec
# RGwXXfWXP02ljGSuJz09MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAfPN21CPS3TbghKsCLlENrntOFhMLPP82EOrYh+PTeRAN1QrQ6eDYzgZv
# hn4rmS5gYE6fusnNTnJkOS8v4LTZH26XvItk/cc4qLpZE2Zhjg0IDKSM8LUG/3EE
# 0u4oTm1PhoSOf75+S2Y3h1s+BjImHnWakPUSvEdM7f+yn0H+gw0+EQFFMCKPwvYf
# 7V1F8KfreqJ11eoNAfSQEVfBZY+RmScvjPpnwo94582jhtn2ABez+gDmsYu8uqz9
# qf48AL6xeVtN9uDphYVuZEb6qtBjAtlECZKBfKe2JORArpC6EulUM4/1WRQ+YZsl
# wNsJmlbNHDn80WWJ3/tamdy1Zoa0haGCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCBo4JlkaIeyo2R3LtClXihecjZcsRh2aGYWKki1w2YBewIGZlc8wh9P
# GBMyMDI0MDYxMjE1MDAzOS4yMTVaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# Ojg2REYtNEJCQy05MzM1MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHdXVcdldStqhsAAQAAAd0wDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMx
# MDEyMTkwNzA5WhcNMjUwMTEwMTkwNzA5WjCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo4NkRGLTRC
# QkMtOTMzNTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKhOA5RE6i53nHURH4lnfKLp
# +9JvipuTtctairCxMUSrPSy5CWK2DtriQP+T52HXbN2g7AktQ1pQZbTDGFzK6d03
# vYYNrCPuJK+PRsP2FPVDjBXy5mrLRFzIHHLaiAaobE5vFJuoxZ0ZWdKMCs8acjhH
# UmfaY+79/CR7uN+B4+xjJqwvdpU/mp0mAq3earyH+AKmv6lkrQN8zgrcbCgHwsqv
# vqT6lEFqYpi7uKn7MAYbSeLe0pMdatV5EW6NVnXMYOTRKuGPfyfBKdShualLo88k
# G7qa2mbA5l77+X06JAesMkoyYr4/9CgDFjHUpcHSODujlFBKMi168zRdLerdpW0b
# BX9EDux2zBMMaEK8NyxawCEuAq7++7ktFAbl3hUKtuzYC1FUZuUl2Bq6U17S4CKs
# qR3itLT9qNcb2pAJ4jrIDdll5Tgoqef5gpv+YcvBM834bXFNwytd3ujDD24P9Dd8
# xfVJvumjsBQQkK5T/qy3HrQJ8ud1nHSvtFVi5Sa/ubGuYEpS8gF6GDWN5/KbveFk
# dsoTVIPo8pkWhjPs0Q7nA5+uBxQB4zljEjKz5WW7BA4wpmFm24fhBmRjV4Nbp+n7
# 8cgAjvDSfTlA6DYBcv2kx1JH2dIhaRnSeOXePT6hMF0Il598LMu0rw35ViUWcAQk
# UNUTxRnqGFxz5w+ZusMDAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUbqL1toyPUdpF
# yyHSDKWj0I4lw/EwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAC5U2bINLgXIHWbM
# cqVuf9jkUT/K8zyLBvu5h8JrqYR2z/eaO2yo1Ooc9Shyvxbe9GZDu7kkUzxSyJ1I
# ZksZZw6FDq6yZNT3PEjAEnREpRBL8S+mbXg+O4VLS0LSmb8XIZiLsaqZ0fDEcv3H
# eA+/y/qKnCQWkXghpaEMwGMQzRkhGwcGdXr1zGpQ7HTxvfu57xFxZX1MkKnWFENJ
# 6urd+4teUgXj0ngIOx//l3XMK3Ht8T2+zvGJNAF+5/5qBk7nr079zICbFXvxtidN
# N5eoXdW+9rAIkS+UGD19AZdBrtt6dZ+OdAquBiDkYQ5kVfUMKS31yHQOGgmFxuCO
# zTpWHalrqpdIllsy8KNsj5U9sONiWAd9PNlyEHHbQZDmi9/BNlOYyTt0YehLbDov
# mZUNazk79Od/A917mqCdTqrExwBGUPbMP+/vdYUqaJspupBnUtjOf/76DAhVy8e/
# e6zR98PkplmliO2brL3Q3rD6+ZCVdrGM9Rm6hUDBBkvYh+YjmGdcQ5HB6WT9Rec8
# +qDHmbhLhX4Zdaard5/OXeLbgx2f7L4QQQj3KgqjqDOWInVhNE1gYtTWLHe4882d
# /k7Lui0K1g8EZrKD7maOrsJLKPKlegceJ9FCqY1sDUKUhRa0EHUW+ZkKLlohKrS7
# FwjdrINWkPBgbQznCjdE2m47QjTbMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
# bmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo4
# NkRGLTRCQkMtOTMzNTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUANiNHGWXbNaDPxnyiDbEOciSjFhCggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOoULvUwIhgPMjAyNDA2MTIyMjI4MDVaGA8yMDI0MDYxMzIyMjgwNVowdDA6Bgor
# BgEEAYRZCgQBMSwwKjAKAgUA6hQu9QIBADAHAgEAAgIDcDAHAgEAAgISpDAKAgUA
# 6hWAdQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAID
# B6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAEsES+vkY7RFE4pSdasf
# FUsfB5sIj176Yd2zfIg+0dpukCHJO0pPcS+PotSR6sgDDlSWByoCpgngzP80vUzN
# 6XraWMbKj8Z1tPZYlgAw/n3QSRlY5pPdJjwiRL8XLeACp7WHSoaCEDvuSuIsu6qK
# 7v+6t2p+OBYgNeP0C7YetvOoMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBIDIwMTACEzMAAAHdXVcdldStqhsAAQAAAd0wDQYJYIZIAWUDBAIB
# BQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
# IgQgBXuk5DB6g5nrJ7U/BEFQ5W9hDDcGr4s3lDYITIbWc8YwgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCBh/w4tmmWsT3iZnHtH0Vk37UCN02lRxY+RiON6wDFj
# ZjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB3V1X
# HZXUraobAAEAAAHdMCIEIKoFwkM2tcXe/hLiUvslXtKcxZcG0TYigMieaAZ8DoRm
# MA0GCSqGSIb3DQEBCwUABIICAEeyZQspW4JUSEl1NOKGGmFQWzpxTdh9irxeVjHB
# 0XlwNEpq0jCRhwBaJk6nagdAt3Qg0V1Hlenst6fPNvitytF3xwQ0r75fb86VzK44
# OiOxyYtAGiP5kiclvasO766RV8KlPxNPcV/k4Zo4HmibYoa5IKMJscw4j0MB7lsI
# 24JovO6tGkKPFlXMrWI0W1OfHqdlIY3d5TC5zMd7BSTvM00kvZdwXd4ds9t8H5Xm
# AWwzxp765MWTwbl9XQWrjI6vWOLWLawZ4i1kwnLZcnJ2UbEb8TiIqFZtCEeGoZpb
# Z9Gk1b7COQvIX1s7W8AcUGIvEBFqTH/H88f6bDHKdW09NbXMW7LCqTWSLzLy/W1S
# CegeYRIR90skfWC15ZRxT2T5401+koSdLMaT+9cC99GwFOSs2uOFieMrbSzq2lxN
# HMmJBcTc4mGqBTM9RY/JYtPJ24UUt2jN/z7F99aw0sq8qNh6yWwtkexsAUf6H7Vz
# vQEa9/mM24uCQcCmqEduiU4nTsqejJArTPT1EiPpDA43hvT1Ornyg+xQpDh0XQyQ
# iCBK3DedkuLUHnIE71tAUwe8hsIod3QTGqxsmRVJLOEmRfaXzSBXyuwqfbO8w/6x
# qH4GyubVgDiQw3dJ6Rps+ooUyTuQrAsV1ZaysKYwxrv+R30F+xVM/NEX/k7Qsxq+
# IP5N
# SIG # End signature block
