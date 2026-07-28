3<#
.SYNOPSIS
   Scenario module for collecting Microsoft Remote Desktop Diagnostics data

.DESCRIPTION
   Runs Diagnostics checks and generates a report in .html format

.NOTES
   Author     : Robert Klemencz
   Requires   : MSRD-Collect.ps1
   Version    : See MSRD-Collect.ps1 version
   Feedback   : https://aka.ms/MSRD-Collect-Feedback
#>

#region versions
$latestRDCver = "1.2.5405.0" #Desktop client (MSRDC)
$latestw365ver = "1.3.250.0" #Windows App unified client
$latestStoreCver = "10.2.3012.0" #Old AVD store client (URDC)
$latestAvdStoreApp = "1.2.4157.0" #New AVD store client (Preview)
$latestAvdHostApp = "1.2.5450.0" #AVD host app

$latestAvdAgentVer = "1.0.8431.2300" #RDAgent

$latestWebRTCVer = "1.50.2402.29001" #Remote Desktop WebRTC
$latestMMRver = "1.0.2311.2004" #Multimedia Redirection
$minVCRverMMR = "14.32.31332.0" #Visual C++ Redistributable

[int64]$latestFSLogixVer = 29888427471 #FSLogix

$latestQAver = "2.0.30.0" #Quick Assist
$latestRHver = "5.1.1214.0" #Remote Help
#endregion versions

$msrdDiagFile = $global:msrdBasicLogFolder + "MSRD-Diag.html"
$msrdAgentpath = "$env:ProgramFiles\Microsoft RDInfra\"

$msrdUserProfilesDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name ProfilesDirectory).ProfilesDirectory
$msrdUserProfilePath = "$msrdUserProfilesDir\$global:msrdUserprof"

$script:RDClient = (Get-ItemProperty hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {(($_.DisplayName -eq "Remote Desktop") -or ($_.DisplayName -eq "Remotedesktop")) -and ($_.Publisher -like "*Microsoft*")})
$script:osLanguage = (Get-CimInstance -ClassName Win32_OperatingSystem).OSLanguage
$script:ring = ""

#region URL references
$msrdcRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/whats-new-client-windows' target='_blank'>What's new in the Remote Desktop client for Windows</a>"
$vmsizeRef = "<a href='https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/virtual-machine-recs#recommended-vm-sizes-for-standard-or-larger-environments' target='_blank'>Session host virtual machine sizing guidelines</a>"
$uwpcRef = "<a href='https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/windows-whatsnew' target='_blank'>What's new in the Remote Desktop app for Windows</a>"
$avexRef = "<a href='https://learn.microsoft.com/en-us/fslogix/overview-prerequisites#configure-antivirus-file-and-folder-exclusions' target='_blank'>Configure Antivirus file and folder exclusions</a>"
$avexTeamsRef = "<a href='https://learn.microsoft.com/en-us/microsoftteams/troubleshoot/teams-administration/include-exclude-teams-from-antivirus-dlp' target='_blank'>Exclude antivirus and DLP applications from blocking Teams</a>"
$w10proRef = "<a href='https://learn.microsoft.com/en-us/lifecycle/products/windows-10-home-and-pro' target='_blank'>Windows 10 Home and Pro</a>"
$w10entRef = "<a href='https://learn.microsoft.com/en-us/lifecycle/products/windows-10-enterprise-and-education' target='_blank'>Windows 10 Enterprise and Education</a>"
$w81Ref = "<a href='https://learn.microsoft.com/en-us/lifecycle/products/windows-81' target='_blank'>Windows 8.1</a>"
$w2008r2Ref = "<a href='https://learn.microsoft.com/en-us/lifecycle/products/windows-server-2008-r2' target='_blank'>Windows Server 2008 R2</a>"
$w2012r2Ref = "<a href='https://learn.microsoft.com/en-us/lifecycle/products/windows-server-2012-r2' target='_blank'>Windows Server 2012 R2</a>"
$avdOSRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites?tabs=portal#operating-systems-and-licenses' target='_blank'>Operating systems and licenses</a>"
$avdLicRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/apply-windows-license' target='_blank'>Apply Windows license to session host virtual machines</a>"
$fslogixRef = "<a href='https://learn.microsoft.com/en-us/fslogix/overview-release-notes' target='_blank'>FSLogix Release Notes</a>"
$cloudcacheRef = "<a href='https://learn.microsoft.com/en-us/fslogix/tutorial-cloud-cache-containers#configure-cloud-cache-for-smb' target='_blank'>Configure profile containers with Cloud Cache</a>"
$gpuRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/enable-gpu-acceleration' target='_blank'>Configure GPU acceleration for Azure Virtual Desktop</a>"
$mmrRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/whats-new-multimedia-redirection' target='_blank'>What's new in multimedia redirection?</a>"
$mmrReqRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/multimedia-redirection?tabs=edge#prerequisites' target='_blank'>Use multimedia redirection on Azure Virtual Desktop</a>"
$defenderRef = "<a href='https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/security-malware-windows-defender-disableantispyware' target='_blank'>DisableAntiSpyware</a>"
$webrtcRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/whats-new-webrtc' target='_blank'>What's new in the Remote Desktop WebRTC Redirector Service</a>"
$avdTsgRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/troubleshoot-agent' target='_blank'>Agent TSG</a>"
$spathTsgRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/troubleshoot-rdp-shortpath' target='_blank'>RDP Shortpath TSG</a>"
$fslogixTsgRef = "<a href='https://learn.microsoft.com/en-us/fslogix/troubleshooting-events-logs-diagnostics' target='_blank'>FSLogix TSG</a>"
$avdagentRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/whats-new-agent' target='_blank'>What's new in the Azure Virtual Desktop Agent?</a>"
$avdclassicRef = "<a href='https://learn.microsoft.com/en-us/azure/virtual-desktop/virtual-desktop-fall-2019/classic-retirement' target='_blank'>Azure Virtual Desktop (classic) retirement</a>"
$newTeamsFSLogixRef = "<a href='https://learn.microsoft.com/en-us/microsoftteams/new-teams-vdi-requirements-deploy#profile-and-cache-location-for-new-teams-client' target='_blank'>Upgrade to new Teams for Virtualized Desktop Infrastructure (VDI)</a>"
$newTeamsRef = "<a href='https://learn.microsoft.com/en-us/microsoftteams/new-teams-vdi-requirements-deploy#requirements' target='_blank'>Upgrade to new Teams for Virtualized Desktop Infrastructure (VDI)</a>"
$classicTeamsEoARef = "<a href='https://learn.microsoft.com/en-us/microsoftteams/new-teams-vdi-requirements-deploy#important-announcement-for-classic-teams-for-vdi' target='_blank'>Upgrade to new Teams for Virtualized Desktop Infrastructure (VDI)</a>"
#endregion URL references

#region hyperlinks
$computerName = $env:computername

$msrdErrorfileurl = "${computerName}_MSRD-Collect-Error.txt"

$agentInitinstfile = "${computerName}_AVD\${computerName}_AgentInstall_initial.txt"
$agentUpdateinstfile = "${computerName}_AVD\${computerName}_AgentInstall_updates.txt"
$agentBLinstfile = "${computerName}_AVD\${computerName}_AgentBootLoaderInstall_initial.txt"
$sxsinstfile = "${computerName}_AVD\${computerName}_SXSStackInstall.txt"
$genevainstfile = "${computerName}_AVD\${computerName}_GenevaInstall.txt"
$avdnettestfile = "${computerName}_AVD\${computerName}_avdnettest.log"
$montablesfolder = "${computerName}_AVD\Monitoring\MonTables"

$aplevtxfile = "${computerName}_EventLogs\${computerName}_Application.evtx"
$sysevtxfile = "${computerName}_EventLogs\${computerName}_System.evtx"
$rdsevtxfile = "${computerName}_EventLogs\${computerName}_RemoteDesktopServices.evtx"
$secevtxfile = "${computerName}_EventLogs\${computerName}_Security.evtx"

$fslogixfolder = "${computerName}_FSLogix"
$virtualdiskregconsfile = "${computerName}_Profiles\${computerName}_VirtualDiskRegConsistency.txt"

$fwrfile = "${computerName}_Networking\${computerName}_FirewallRules.txt"
$ipcfgfile = "${computerName}_Networking\${computerName}_Ipconfig.txt"
$routefile = "${computerName}_Networking\${computerName}_Route.txt"
$domtrustfile = "${computerName}_Networking\${computerName}_Nltest-domtrusts.txt"

$GetRDSFarmDatafile = "${computerName}_RDS\${computerName}_GetFarmData.txt"
$getcapfile = "${computerName}_RDS\${computerName}_rdgw_ConnectionAuthorizationPolicy.txt"
$getrapfile = "${computerName}_RDS\${computerName}_rdgw_ResourceAuthorizationPolicy.txt"
$gracefile = "${computerName}_RDS\${computerName}_rdsh_GracePeriod.txt"
$tslsgroupfile = "${computerName}_RDS\${computerName}_TSLSMembership.txt"
$licpakfile = "${computerName}_RDS\${computerName}_rdls_LicenseKeyPacks.html"
$licoutfile = "${computerName}_RDS\${computerName}_rdls_IssuedLicenses.html"

$permDriveCfile = "${computerName}_SystemInfo\${computerName}_Permissions-DriveC.txt"
$dxdiagfile = "${computerName}_SystemInfo\${computerName}_DxDiag.txt"
$kmsfile = "${computerName}_SystemInfo\${computerName}_KMS-Servers.txt"
$slmgrfile = "${computerName}_SystemInfo\${computerName}_slmgr-dlv.txt"
$sysinfofile = "${computerName}_SystemInfo\${computerName}_SystemInfo.txt"
$avinfofile = "${computerName}_SystemInfo\${computerName}_AntiVirusProducts.txt"
$dsregfile = "${computerName}_SystemInfo\${computerName}_Dsregcmd.txt"
$instappsfile = "${computerName}_SystemInfo\${computerName}_InstalledApplications.txt"
$instrolesfile = "${computerName}_SystemInfo\${computerName}_InstalledRoles.txt"
$updhistfile = "${computerName}_SystemInfo\${computerName}_UpdateHistory.html"
$powerfile = "${computerName}_SystemInfo\${computerName}_PowerReport.html"
$gpresfile = "${computerName}_SystemInfo\${computerName}_Gpresult.html"
$winrmcfgfile = "${computerName}_SystemInfo\${computerName}_WinRM-Config.txt"
$pnputilMousefile = "${computerName}_SystemInfo\${computerName}_PnpUtil-Devices-Mouse.txt"
$pnputilKeyboardfile = "${computerName}_SystemInfo\${computerName}_PnpUtil-Devices-Keyboard.txt"
$scinfofile = "${computerName}_SystemInfo\${computerName}_SmartCardInfo.txt"

$regCredDelegationFile = "${computerName}_RegistryKeys\${computerName}_HKLM-SW-Policies.txt"
$regDefExclFile = "${computerName}_RegistryKeys\${computerName}_HKLM-SW-MS-WinDef-Exclusions.txt"

$machineKeysFile = "${computerName}_Certificates\${computerName}_ACL-MachineKeys.txt"

if ($global:msrdRDS) {
    $listenerPermFile = "${computerName}_RDS\${computerName}_ListenerPermissions.txt"
} else {
    $listenerPermFile = "${computerName}_AVD\${computerName}_ListenerPermissions.txt"
}

#endregion hyperlinks

$rdiagmsg = msrdGetLocalizedText "rdiagmsg"
$checkmsg = msrdGetLocalizedText "checkmsg"

if (msrdTestRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -Value 'ReverseConnectionListener') {
    $script:msrdListenervalue = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -name "ReverseConnectionListener"
} else {
    $script:msrdListenervalue = ""
}

if (Test-Path $msrdAgentpath) {
    $avdcheck = $true
} else {
    $avdcheck = $false
    $avdcheckmsg = "AVD Agent <span style='color: brown'>not found</span>. This machine does not seem to be part of an AVD host pool. Skipping additional AVD host specific checks."
}

$script:isDomain = (get-ciminstance -Class Win32_ComputerSystem).PartOfDomain

$status = dsregcmd /status | Select-String -Pattern "AzureAdJoined"
if ($status -match "AzureAdJoined : YES") { $script:isAzureADJoined = $true } else { $script:isAzureADJoined = $false }

$script:registeredBrowsers = Get-Item -LiteralPath "HKLM:\SOFTWARE\Clients\StartMenuInternet" | Get-Item -ErrorAction SilentlyContinue | Get-ChildItem | ForEach-Object { $_.PSChildName }


#Azure VM query

Function msrdCheckAzVM {

    Try {
        $AzureVMquery = Invoke-RestMethod -Headers @{"Metadata"="true"} -URI 'http://169.254.169.254/metadata/instance?api-version=2023-11-15' -Method Get -TimeoutSec 30

        $script:vmloc = $AzureVMquery.Compute.location
        $script:vmsize = $AzureVMquery.Compute.vmSize
        if ($AzureVMquery.Compute.sku -eq "") { $script:vmsku = "N/A" } else { $script:vmsku = $AzureVMquery.Compute.sku }
        if ($AzureVMquery.Compute.licenseType -eq "") { $script:msrdVmlictype = "N/A" } else { $script:msrdVmlictype = $AzureVMquery.Compute.licenseType }
    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        $script:vmsku = "N/A"
        $script:vmloc = "N/A"
        $script:vmsize = "N/A"
        $script:msrdVmlictype = "N/A"
    }
}

#region Main Diag functions

Function msrdLogDiag {
    param([Int]$Level = $Loglevel.Normal, [string]$Type, [string]$DiagTag, [string]$Message, [string]$Message2, [string]$Message3, [string]$Title, [int]$col, [string]$circle, $addAssist)

    $global:msrdPerc = "{0:P}" -f ($global:msrdProgress/100)

    switch($circle) {
        'green' { $tdcircle = "circle_green" }
        'yellow' { $tdcircle = "circle_yellow" }
        'red' { $tdcircle = "circle_red" }
        'no' { $tdcircle = "circle_no" }
        default { $tdcircle = "circle_white" }
    }

    if ($global:msrdLiveDiag) {
        if ($global:msrdLiveDiagSystem)         { $liveDiagBox = $global:psBoxLiveDiagSystem }
        elseif ($global:msrdLiveDiagAVDRDS)     { $liveDiagBox = $global:psBoxLiveDiagAVDRDS }
        elseif ($global:msrdLiveDiagAVDInfra)   { $liveDiagBox = $global:psBoxLiveDiagAVDInfra }
        elseif ($global:msrdLiveDiagAD)         { $liveDiagBox = $global:psBoxLiveDiagAD }
        elseif ($global:msrdLiveDiagNet)        { $liveDiagBox = $global:psBoxLiveDiagNet }
        elseif ($global:msrdLiveDiagLogonSec)   { $liveDiagBox = $global:psBoxLiveDiagLogonSec }
        elseif ($global:msrdLiveDiagIssues)     { $liveDiagBox = $global:psBoxLiveDiagIssues }
        elseif ($global:msrdLiveDiagOther)      { $liveDiagBox = $global:psBoxLiveDiagOther }
        else                                    { Write-Output "Error: No liveDiagBox found" }
    }

    if ($global:msrdLangID -eq "AR") {
        $ARdate = Get-Date
        $ARday = $ARdate.Day.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
        $ARmonth = $ARdate.Month.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
        $ARyear = $ARdate.Year.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
        $ARhour = $ARdate.Hour.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
        $ARminute = $ARdate.Minute.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
        $ARsecond = $ARdate.Second.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
        $ARmillisecond = $ARdate.Millisecond.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
    }

    Switch($Level) {
        "0" { # Normal
            $LogConsole = $True; $MessageColor = 'Yellow'
            [decimal]$global:msrdProgress = $global:msrdProgress + $global:msrdProgstep

            if ((-not $global:msrdGUI) -and !($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible) -and $global:msrdDiagnosing -and (-not $global:msrdTSSinUse)) {
                Write-Progress -Activity "Running diagnostics. Please wait..." -Status "$global:msrdPerc complete:" -PercentComplete $global:msrdProgress
            } elseif (($global:msrdGUI -or ($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) -and $global:msrdDiagnosing) {
                $global:msrdProgbar.PerformStep()
                $global:msrdStatusBarLabel.Text = "$rdiagmsg"
            }

            if ($global:msrdLiveDiag) {
                if ($global:msrdLangID -eq "AR") { $msg = "$Message" + " :" + "$checkmsg" } else { $msg = "$checkmsg" + ": " + "$Message" }

                $paddingLength = 160 - $msg.Length
                $padding = ' ' * $paddingLength

                if ($global:msrdLangID -eq "AR") { $line = "$padding $msg <<<" } else { $line = ">>> $msg $padding" }
                $DiagMessage2Screen = "$line"

            } else {
                if ($global:msrdLangID -eq "AR") {
                    $datemsg = "${ARhour}:${ARminute}:${ARsecond}.${ARmillisecond} ${ARyear}/${ARmonth}/${ARday}"
                } else {
			        $datemsg = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
		        }

                $DiagMessage2Screen = $datemsg + " $checkmsg " + $Message
            }

            if ($DiagTag -eq "DeploymentCheck") {
                $DiagMessage = "<details open><summary style='user-select: none;'><span style='position:relative;'><a name='$DiagTag' style='position:absolute; top:-155px;'></a><b>$Message</b><span class='b2top'><a href='#'>^top</a></span></summary></span><div class='detailsP'><table class='tduo'><tbody>"
            } else {
                $DiagMessage = "</tbody></table></div></details><details open><summary style='user-select: none;'><span style='position:relative;'><a name='$DiagTag' style='position:absolute; top:-155px;'></a><b>$Message</b><span class='b2top'><a href='#'>^top</a></span></summary></span><div class='detailsP'><table class='tduo'><tbody>"
            }
        }

        "1" { # Info
            $LogConsole = $True; $MessageColor = 'White'
            [decimal]$global:msrdProgress = $global:msrdProgress + $global:msrdProgstep

            if ((-not $global:msrdGUI) -and !($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible) -and $global:msrdDiagnosing -and (-not $global:msrdTSSinUse)) {
                Write-Progress -Activity "Running diagnostics. Please wait..." -Status "$global:msrdPerc complete:" -PercentComplete $global:msrdProgress
            } elseif (($global:msrdGUI -or ($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) -and $global:msrdDiagnosing) {
                $global:msrdProgbar.PerformStep()
                $global:msrdStatusBarLabel.Text = "$rdiagmsg"
            }

            if (-not $global:msrdLiveDiag) {
                if ($global:msrdLangID -eq "AR") {
                    $datemsg = "${ARhour}:${ARminute}:${ARsecond}.${ARmillisecond} ${ARyear}/${ARmonth}/${ARday}"
                } else {
			        $datemsg = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
		        }

                $DiagMessage2Screen = $datemsg + " " + $Message
            }
        }

        "2" { $LogConsole = $True; $MessageColor = 'Magenta' } # Warning
        "3" { $LogConsole = $True; $MessageColor = 'Red' } # Error

        "9" { # Diag file only

            $MessageColor = 'Black'
            function PadWithSpaces([string]$text, [int]$desiredLength, [switch]$rtl = $false) {

                if (($null -eq $text) -or ($text -eq "")) { $text = " " }
                $currentLength = $text.Length
                $spacesNeeded = [Math]::Max(0, $desiredLength - $currentLength)
                $tabs = " " * $spacesNeeded
                if ($rtl) {
                    return "$tabs $text"
                } else {
                    return "$text $tabs"
                }
            }

            $LogConsole = $False
            if ($global:msrdLangID -eq "AR") {
                $datemsg = "${ARhour}:${ARminute}:${ARsecond}.${ARmillisecond} ${ARyear}/${ARmonth}/${ARday}"
            } else {
			    $datemsg = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
		    }

            $DiagMessage2Screen = $datemsg + " " + $Message

            if ($global:msrdLiveDiag) {
                $Message = $Message -replace '<[^>]+>', '' -replace '\(See[^)]*\)', '' -replace 'See MSRD-Collect-Error for more information.', ''
                $Message2 = $Message2 -replace '<[^>]+>', '' -replace '\(See[^)]*\)', ''
                $Message3 = $Message3 -replace '<[^>]+>', '' -replace '\(See[^)]*\)', ''

                if ($Message2 -like "Issues found in the '*") {
                    $Message3 = "Run the 'Core' or 'DiagOnly' data collection scenarios to get more details about these issues"
                }

                if ($circle -eq "red" -or $circle -eq "yellow") { $liveDiagBox.SelectionBackColor = "Yellow" }
            }

            if ((-not $global:msrdLiveDiag) -and ($circle -eq "red" -or $circle -eq "yellow")) {
                if ($Message) { $Message = "<span style='background-color: #FFFFDD'>$Message</span>" }
                if ($Message2) { $Message2 = "<span style='background-color: #FFFFDD'>$Message2</span>" }
                if ($Message3) { $Message3 = "<span style='background-color: #FFFFDD'>$Message3</span>" }
            }

            if ($Type -eq "Text") {
                if ($global:msrdLiveDiag) {
                    $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                    $liveDiagBox.SelectionLength = 0
                    $liveDiagBox.AppendText("$Message`r`n")
                    $liveDiagBox.ScrollToCaret()
                    $liveDiagBox.Refresh()
                } else {
                    $DiagMessage = "<tr><td width='10px'><div class='$tdcircle'></div></td><td class='cText' colspan='$col'>$Message</td></tr>"
                }

            } elseif ($Type -eq "Table1-2") {
                if ($global:msrdLiveDiag) {
                    $sectionLength = 30
                    $paddedMessage = PadWithSpaces $Message $sectionLength
                    $combinedMessage = "$paddedMessage$Message2"

                    $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                    $liveDiagBox.SelectionLength = 0
                    $liveDiagBox.AppendText("$combinedMessage`r`n")
                    $liveDiagBox.ScrollToCaret()
                    $liveDiagBox.Refresh()
                } else {
                    $DiagMessage = "<tr><td width='10px'><div class='$tdcircle'></div></td><td class='cTable1-2'>$Message</td><td colspan='2'>$Message2</td></tr>"
                }

            } elseif ($Type -eq "Table2-1") {
                if ($global:msrdLiveDiag) {
                    $sectionLength = 130
                    $paddedMessage = PadWithSpaces $message $sectionLength
                    $combinedMessage = "$paddedMessage$Message2"

                    $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                    $liveDiagBox.SelectionLength = 0
                    $liveDiagBox.AppendText("$combinedMessage`r`n")
                    $liveDiagBox.ScrollToCaret()
                    $liveDiagBox.Refresh()
                } else {
                    if ($Title) {
                        $DiagMessage = "<tr><td width='10px'><div class='$tdcircle'></div></td><td class='cTable2-1' colspan='2'>$Message <span title='$Title' style='cursor: pointer'>&#9432;</span></td><td class='cReg2'>$Message2</td></tr>"
                    } else {
                        $DiagMessage = "<tr><td width='10px'><div class='$tdcircle'></div></td><td class='cTable2-1' colspan='2'>$Message</td><td>$Message2</td></tr>"
                    }
                }

            } elseif ($Type -eq "Table1-3") {
                if ($global:msrdLiveDiag) {
                    $sectionLength = 30
                    $sectionLength2 = 100
                    $paddedMessage = PadWithSpaces $message $sectionLength
                    $paddedMessage2 = PadWithSpaces $message2 $sectionLength2
                    $combinedMessage = "$paddedMessage$paddedMessage2$message3"

                    $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                    $liveDiagBox.SelectionLength = 0
                    $liveDiagBox.AppendText("$combinedMessage`r`n")
                    $liveDiagBox.ScrollToCaret()
                    $liveDiagBox.Refresh()
                } else {
                    if ($Title) {
                            $DiagMessage = "<tr><td width='10px'><div class='$tdcircle'></div></td><td class='cTable1-3'>$Message</td><td class='cTable1-3b'>$Message2 <span title='$Title' style='cursor: pointer'>&#9432;</span></td><td>$Message3</td></tr>"
                    } else {
                            $DiagMessage = "<tr><td width='10px'><div class='$tdcircle'></div></td><td class='cTable1-3'>$Message</td><td class='cTable1-3b'>$Message2</td><td>$Message3</td></tr>"
                    }
                }

            } elseif ($Type -eq "HR") {
                if ($global:msrdLiveDiag) {
                    $dashChar = "-"  # The character used for the line
                    $charWidth = [System.Windows.Forms.TextRenderer]::MeasureText($dashChar, $liveDiagBox.Font).Width
                    $lineLength = [Math]::Ceiling($liveDiagBox.Width / $charWidth)
                    $line = $dashChar * $lineLength
                    $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                    $liveDiagBox.SelectionLength = 0
                    $liveDiagBox.AppendText("`r`n`n$line`r`n")
                    $liveDiagBox.ScrollToCaret()
                    $liveDiagBox.Refresh()
                } else {
                    $commonStyle = "style='height:5px; padding-left: 0px; padding-right: 0px; padding-bottom: 0px;'"
                    $hrTag = "<td><hr></td>"
                    if (!$col) { $col = 3 }
                    $hrTags = $hrTag * $col
                    $DiagMessage = "<tr $commonStyle><td></td>$hrTags</tr>"
                }

            } elseif ($Type -eq "Spacer") {
                if ($global:msrdLiveDiag) {
                    $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                    $liveDiagBox.SelectionLength = 0
                    $liveDiagBox.AppendText("`r`n")
                    $liveDiagBox.ScrollToCaret()
                    $liveDiagBox.Refresh()
                } else {
                    $DiagMessage = "<tr style='height:5px;'></tr>"
                }

            } elseif ($Type -eq "DL") {
                if ($global:msrdLiveDiag) {
                    $dashChar = "- "  # The character used for the line
                    $charWidth = [System.Windows.Forms.TextRenderer]::MeasureText($dashChar, $liveDiagBox.Font).Width
                    $lineLength = [Math]::Ceiling($liveDiagBox.Width / $charWidth)
                    $line = $dashChar * $lineLength
                    $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                    $liveDiagBox.SelectionLength = 0
                    $liveDiagBox.AppendText("`r`n$line`r`n")
                    $liveDiagBox.ScrollToCaret()
                    $liveDiagBox.Refresh()
                } else {
                    $commonStyle = "style='height:5px; padding-left: 0px; padding-right: 0px; padding-bottom: 0px;'"
                    $hrTag = "<td><hr style='border-style: dashed; border-color: gray;'></td>"
                    if (!$col) { $col = 3 }
                    $hrTags = $hrTag * $col
                    $DiagMessage = "<tr $commonStyle><td></td>$hrTags</tr>"
                }
            }
        }
    }

    If (($Color) -and $Color.Length -ne 0) { $MessageColor = $Color }

    if ($LogConsole) {
        if ($global:msrdGUI) {
            if ($global:msrdLiveDiag) {
                $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                $liveDiagBox.SelectionLength = 0
                $liveDiagBox.SelectionBackColor = "White"
                $liveDiagBox.AppendText("`r`n`n")

                if ($Level -eq $Loglevel.Normal) {
                    $currentLength = $liveDiagBox.TextLength
                    $liveDiagBox.AppendText("$DiagMessage2Screen`r`n")
                    $liveDiagBox.Select($currentLength, $DiagMessage2Screen.Length)
                    $liveDiagBox.SelectionBackColor = "#707070"
                    $liveDiagBox.SelectionColor = "White"

                    if ($global:msrdLangID -eq "AR") {
                        $liveDiagBox.SelectionAlignment = "Right"
                    } else {
                        $liveDiagBox.SelectionAlignment = "Left"
                    }
                } else {
                    $liveDiagBox.AppendText("$DiagMessage2Screen`r`n")
                    $liveDiagBox.SelectionAlignment = "Left"
                    $liveDiagBox.SelectionBackColor = "White"
                }

                $liveDiagBox.AppendText("`r`n")
                $liveDiagBox.ScrollToCaret()
                $liveDiagBox.Refresh()
            } else {
                $msrdPsBox.SelectionStart = $msrdPsBox.TextLength
                $msrdPsBox.SelectionLength = 0
                $msrdPsBox.SelectionColor = $MessageColor
                if (($global:msrdSilentMode -eq 1) -and ($global:msrdCollecting -or $global:msrdDiagnosing) -and ($Color -ne "Cyan") -and ($global:msrdAudioAssistMode -eq 0)) {
                    $msrdPsBox.AppendText(".")
                } else {
                    $msrdPsBox.AppendText("$DiagMessage2Screen`r`n")
                }
                $msrdPsBox.ScrollToCaret()
                $msrdPsBox.Refresh()
            }
        } else {
            $host.ui.RawUI.ForegroundColor = $MessageColor
                if (($global:msrdSilentMode -eq 1) -and ($global:msrdCollecting -or $global:msrdDiagnosing) -and ($Color -ne "Cyan") -and ($global:msrdAudioAssistMode -eq 0)) {
                    Write-Host "." -NoNewline
                } else {
                    Write-Output $DiagMessage2Screen
                }
            $host.ui.RawUI.ForegroundColor = $global:msrdConsoleColor
        }
    }

    if ((($Level -eq $Loglevel.Normal) -or ($Level -eq $Loglevel.Info)) -and (-not $global:msrdLiveDiag)) {
        $DiagMessage2Screen | Out-File -Append $global:msrdOutputLogFile
    } elseif (($Level -eq $Loglevel.Warning) -and (-not $global:msrdLiveDiag)) {
        $DiagMessage2Screen | Out-File -Append $global:msrdWarningLogFile
    }

    if ((($global:msrdAudioAssistMode -eq 1) -or $addAssist) -and ($Level -eq $Loglevel.Normal)) { msrdLogMessageAssistMode "$checkmsg $Message" }

    if (($Level -ne $Loglevel.Info) -and (-not $global:msrdLiveDiag)) { Add-Content $msrdDiagFile $DiagMessage }
}

Function msrdCheckRegKeyValue {
    Param([string]$RegPath, [string]$RegKey, [string]$RegValue, [string]$OptNote, [switch]$skipValue, [switch]$addWarning, [switch]$warnMissing = $false, $linkToReg, [string]$warnIfValue, [string]$warnColor = "red")

    if (msrdTestRegistryValue -path $RegPath -value $RegKey) {

        if ($RegPath -like "HKLM*") {
			$searchPath = [Microsoft.Win32.Registry]::LocalMachine
		} elseif ($RegPath -like "HKCU*") {
			$searchPath = [Microsoft.Win32.Registry]::CurrentUser
        } elseif ($RegPath -like "HKU*") {
            $searchPath = [Microsoft.Win32.Registry]::Users
        }

        (Get-ItemProperty -path $RegPath).PSChildName | foreach-object -process {
            $RegPathShort = $RegPath.Substring($RegPath.IndexOf("\") + 1)
            $keyInfo = $searchPath.OpenSubKey($RegPathShort)
            $keyValue = $keyInfo.GetValue($RegKey)
            $keyType = $keyInfo.GetValueKind($RegKey)

            if ($keyType -like "*Word*") {
                $keyValue = [System.Convert]::ToUInt32($keyValue.ToString("X"), 16)
                $hexkey = "0x{0:x8}" -f $keyValue
                $key2 = "$keyValue ($hexkey)"
            } elseif ($keyType -like "*Binary*") {
                $hexkey = ($keyValue | ForEach-Object { "{0:X2}" -f $_ }) -join ' '
                $key2 = $hexkey
            } else {
                $key2 = $keyValue
            }

            if ($linkToReg) {
                $regfilecheck = Test-Path -Path ($global:msrdLogDir + $linkToReg)
                if ($regfilecheck) { $key2 += " (See: <a href='$linkToReg' target='_blank'>Reg export</a>)" }
            }

            if ($global:msrdLiveDiag) {
                $key3 = "[Type: $keyType]   Value: $key2"
            } else {
                $key3 = "[Type: $keyType] &nbsp; Value: $key2"
            }
            if ($RegValue) {
                if ($keyValue -eq $RegValue) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath<span style='color: blue'>$RegKey</span>" -Message2 $key3 -Title "$OptNote" -circle "green"
                } else {
                    if ($warnColor -eq "red" -or $warnColor -eq "yellow") { $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; }
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath<span style='color: blue'>$RegKey</span>" -Message2 "$key3 (Expected: $RegValue)" -Title "$OptNote" -circle $warnColor
                }
            } else {
                if ($skipValue) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath<span style='color: blue'>$RegKey</span>" -Message2 "<span style='color: blue'>found</found>" -Title "$OptNote" -circle "white"
                } else {
                    if ($addWarning -or ($warnIfValue -and ($keyValue -eq $warnIfValue))) {
                        if ($warnColor -eq "red" -or $warnColor -eq "yellow") { $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; }
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath<span style='color: blue'>$RegKey</span>" -Message2 $key3 -Title "$OptNote" -circle $warnColor
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath<span style='color: blue'>$RegKey</span>" -Message2 $key3 -Title "$OptNote" -circle "white"
                    }
                }
            }
        }
    } else {
        if ($warnMissing) {
            if ($warnColor -eq "red" -or $warnColor -eq "yellow") { $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath<span style='color: blue'>$RegKey</span>" -Message2 "not found" -Title "$OptNote" -circle $warnColor
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath<span style='color: blue'>$RegKey</span>" -Message2 "not found" -Title "$OptNote" -circle "white"
        }
    }
}

function msrdTestTCP {
    param([string]$Address,[int]$Port,[int]$Timeout = 20000)

    try {
        $Socket = New-Object System.Net.Sockets.TcpClient
        $Result = $Socket.BeginConnect($Address, $Port, $null, $null)
        $WaitHandle = $Result.AsyncWaitHandle
        if (!$WaitHandle.WaitOne($Timeout)) {
            throw [System.TimeoutException]::new('Connection Timeout')
        }
        $Socket.EndConnect($Result) | Out-Null
        $Connected = $Socket.Connected
        $remoteEndPoint = $Socket.Client.RemoteEndPoint
        $remoteIPAddress = $remoteEndPoint.Address.IPAddressToString
    } catch {
        $FailedCommand = $MyInvocation.Line.TrimStart()
        $FailedCommand = $FailedCommand -replace [regex]::Escape("`$url"), $Address -replace [regex]::Escape("`$port"), $Port
        msrdLogException ("$(msrdGetLocalizedText 'errormsg') $FailedCommand") -ErrObj $_
    } finally {
        if ($Socket) { $Socket.Dispose() }
        if ($WaitHandle) { $WaitHandle.Dispose() }
    }

    $Connected
    $remoteIPAddress
}

Function msrdCheckServicePort {
    param ([String]$service, [String[]]$tcpports, [String[]]$udpports, [int]$skipWarning, [switch]$stopWarning, $linkmsg, [string]$warnColor = "red", [string]$expectedAccount, [string]$extraNotification)

    #check service status and port access
    $serv = Get-CimInstance Win32_Service -Filter "name = '$service'" | Select-Object Name, ProcessId, State, StartMode, StartName, DisplayName, Description

    if ($serv) {
        $msg3 = "$($serv.State) ($($serv.StartMode)) ($($serv.StartName))"
        if ($expectedAccount -and ($serv.StartName -ne $expectedAccount)) {
            $msg3 += " (Expected: $expectedAccount)"
        }
        if ($linkmsg) { $msg3 += " (See: $linkmsg)" }

        if (($serv.StartMode -eq "Disabled") -or (($serv.State -eq "Stopped") -and $stopWarning) -or ($expectedAccount -and ($serv.StartName -ne $expectedAccount))) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Service" -Message2 "<b>$service</b> - $($serv.DisplayName)" -Message3 "$msg3" -Title "$($serv.Description)" -circle $warnColor
        } elseif ($serv.State -eq "Running") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Service" -Message2 "<b>$service</b> - $($serv.DisplayName)" -Message3 "$msg3" -Title "$($serv.Description)" -circle "green"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Service" -Message2 "<b>$service</b> - $($serv.DisplayName)" -Message3 "$msg3" -Title "$($serv.Description)" -circle "white"
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        if ($extraNotification -and $warnColor) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$extraNotification" -circle $warnColor
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        }

        #dependencies
        $dependsOn = (Get-Service -Name "$service").RequiredServices
        if ($dependsOn) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$service depends on the following system components" -circle "no"
            foreach ($dep in $dependsOn) {
                $depConfig = Get-CimInstance Win32_Service -Filter "name = '$($dep.Name)'" | Select-Object State, StartMode, StartName, DisplayName, Description
                if ($depConfig) {
                    if ($depConfig.State -eq "Running") {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($dep.Name) - $($depConfig.DisplayName)" -Message3 "$($depConfig.State) ($($depConfig.StartMode)) ($($depConfig.StartName))" -circle "green" -Title "$($depConfig.Description)"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($dep.Name) - $($depConfig.DisplayName)" -Message3 "$($depConfig.State) ($($depConfig.StartMode)) ($($depConfig.StartName))" -circle "white" -Title "$($depConfig.Description)"
                    }
                } else {
                    $depConfig = Get-Service "$($dep.Name)" | Select-Object Status, StartType, DisplayName
                    if ($depConfig.Status -eq "Running") {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($dep.Name) - $($depConfig.DisplayName)" -Message3 "$($depConfig.Status) ($($depConfig.StartType))" -circle "green"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($dep.Name) - $($depConfig.DisplayName)" -Message3 "$($depConfig.Status) ($($depConfig.StartType))" -circle "white"
                    }
                }
            }
        }

        $othersDepend = (Get-Service -Name "$service").DependentServices
        if ($othersDepend) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message ("System components depending on $service") -circle "no"
            foreach ($other in $othersDepend) {
                $otherConfig = Get-CimInstance Win32_Service -Filter "name = '$($other.Name)'" | Select-Object State, StartMode, StartName, DisplayName, Description
                if ($otherConfig) {
                    if ($otherConfig.State -eq "Running") {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($other.Name) - $($otherConfig.DisplayName)" -Message3 "$($otherConfig.State) ($($otherConfig.StartMode)) ($($otherConfig.StartName))" -circle "green" -Title "$($otherConfig.Description)"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($other.Name) - $($otherConfig.DisplayName)" -Message3 "$($otherConfig.State) ($($otherConfig.StartMode)) ($($otherConfig.StartName))" -circle "white" -Title "$($otherConfig.Description)"
                    }
                } else {
                    $otherConfig = Get-Service "$($other.Name)" | Select-Object Status, StartType, DisplayName
                    if ($otherConfig.Status -eq "Running") {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($other.Name) - $($otherConfig.DisplayName)" -Message3 "$($otherConfig.Status) ($($otherConfig.StartType))" -circle "green"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($other.Name) - $($otherConfig.DisplayName)" -Message3 "$($otherConfig.Status) ($($otherConfig.StartType))" -circle "white"
                    }
                }
            }
        }

        #recovery settings
        $outcmd = sc.exe qfailure $service
        if ($outcmd) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$service recovery settings" -circle "no"
            foreach ($fsout in $outcmd) {
                if (($fsout -like "*RESET*") -or ($fsout -like "*REBOOT*") -or ($fsout -like "*COMMAND*") -or ($fsout -like "*FAILURE*") -or ($fsout -like "*RUN PROCESS*") -or ($fsout -like "*RESTART*")) {
                    $fsrec1 = $fsout.Split(":")[0]; if ($fsrec1) { $fsrec1 = $fsrec1.Trim() }
                    $fsrec2 = $fsout.Split(":")[1]; if ($fsrec2) { $fsrec2 = $fsrec2.Trim() }
                    if ($fsrec2) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$fsrec1" -Message3 "$fsrec2" -circle "white"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message3 "$fsrec1" -circle "white"
                    }
                }
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not retrieve $service service failure settings" -circle "red"
        }

        #ports
        If (!($global:msrdOSVer -like "*Server*2008*")) {
            if ($tcpports) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                foreach ($port in $tcpports) {
                    $exptcplistener = Get-NetTCPConnection -OwningProcess $serv.ProcessId -LocalPort $port -ErrorAction Continue 2>>$global:msrdErrorLogFile

                    if ($exptcplistener) {
                        foreach ($tcpexp in $exptcplistener) {
                            $tcpexpaddr = $tcpexp.LocalAddress
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$service is listening on port" -Message2 "$port (TCP) (LocalAddress: $tcpexpaddr)" -circle "green"
                        }
                    } else {
                        $tcphijackpid = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess
                        if ($tcphijackpid) {
                            foreach ($tcppid in $tcphijackpid) {
                                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                                $tcpaddress = $tcppid.LocalAddress
                                $tcphijackproc = (Get-WmiObject Win32_service | Where-Object ProcessId -eq "$tcppid").Name
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$service is not listening on TCP port $port (LocalAddress: $tcpaddress). The TCP port $port is being used by" -Message2 "$tcphijackproc ($tcppid)" -circle "red"
                            }
                        } else {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No process is listening on TCP port $port." -circle "red"
                        }
                    }
                }
            }

            if (!($global:msrdOSVer -like "*Server*2012*")) {
                if ($udpports) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                    foreach ($port in $udpports) {
                        $expudplistener = Get-NetUDPEndpoint -OwningProcess $serv.ProcessId -LocalPort $port -ErrorAction Continue 2>>$global:msrdErrorLogFile

                        if ($expudplistener) {
                            foreach ($udpexp in $expudplistener) {
                                $udpexpaddr = $udpexp.LocalAddress
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$service is listening on port" -Message2 "$port (UDP) (LocalAddress: $udpexpaddr)" -circle "green"
                            }
                        } else {
                            $udphijackpid = (Get-NetUDPEndpoint -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess
                            if ($udphijackpid) {
                                foreach ($udppid in $udphijackpid) {
                                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                                    $udpaddress = $udppid.LocalAddress
                                    $udphijackproc = (Get-WmiObject Win32_service | Where-Object ProcessId -eq "$udphijackpid").Name
                                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$service is not listening on UDP port $port (LocalAddress: $udpaddress). The UDP port $port is being used by" -Message2 "$udphijackproc ($udppid)" -circle "red"
                                }
                            } else {
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No process is listening on UDP port $port." -circle "white"
                            }
                        }
                    }
                }
            }
        }

    } else {
        if ($skipWarning -eq 1) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Service" -Message2 "$service" -Message3 "not found"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Service" -Message2 "$service" -Message3 "not found" -circle "red"
        }
    }
}

function msrdGetAppxInstallationDate {
    param (
        [string]$packageName
    )

    $appxPackage = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue

    if ($appxPackage) {
        $packageFolder = Get-Item -LiteralPath $appxPackage.InstallLocation -ErrorAction SilentlyContinue

        if ($packageFolder) {
            $installationDateTime = $packageFolder.CreationTime
            $installationDate = $installationDateTime.ToString("yyyy/MM/dd")
        } else {
            $installationDate = "N/A"
        }

    } else {
        $installationDate = "N/A"
    }

    return $installationDate
}

#endregion Main Diag functions


#region System diag functions

Function msrdDiagDeployment {

    #deployment diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Core"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "DeploymentCheck" -Message $menuitemmsg

    if ($global:msrdLiveDiag) { msrdCheckAzVM }

    $sysinfofileExists = Test-Path -Path ($global:msrdLogDir + $sysinfofile)
    $instappsfileExists = Test-Path -Path ($global:msrdLogDir + $instappsfile)
    $gpresfileExists = Test-Path -Path ($global:msrdLogDir + $gpresfile)
    $existingFiles = @()
    if ($sysinfofileExists) { $existingFiles += "<a href='$sysinfofile' target='_blank'>SystemInfo</a>" }
    if ($instappsfileExists) { $existingFiles += "<a href='$instappsfile' target='_blank'>InstalledApps</a>" }
    if ($gpresfileExists) { $existingFiles += "<a href='$gpresfile' target='_blank'>Gpresult</a>" }

    if ($existingFiles.Count -eq 0) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "FQDN" -Message2 "$global:msrdFQDN"
    } else {
        $filesString = $existingFiles -join " / "
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "FQDN" -Message2 "$global:msrdFQDN" -Message3 "(See: $filesString)"
    }

    if (-not $script:isDomain) {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        if ($script:isAzureADJoined) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "This machine is not connected to a domain, but it is joined to Microsoft Entra." -circle "yellow"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "This machine is not connected to a domain, nor is it joined to Microsoft Entra." -circle "red"
        }
    }

    if (($global:msrdOSVer -like "*Server*") -and (Test-Path -Path ($global:msrdLogDir + $instrolesfile))) {
        $script:vmsku = "$script:vmsku (See: <a href='$instrolesfile' target='_blank'>InstalledRoles</a>)"
    }

    $OSArc = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture

    if (!($global:msrdOSVer -like "*Windows 7*")) {

        if (($global:msrdOSVer -like "*Server*2008*") -or ($global:msrdOSVer -like "*Server*2012*")) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "OS" -Message2 "$global:msrdOSVer $OSArc (Build: $global:WinVerMajor.$global:WinVerBuild.$global:WinVerRevision)" -Message3 "SKU: $script:vmsku"
        } else {
            if ($global:WinVerMajor -like "*10*") {
                [string]$shortver = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "OS" -Message2 "$global:msrdOSVer $shortver $OSArc (Build: $global:WinVerMajor.$global:WinVerMinor.$global:WinVerBuild.$global:WinVerRevision)" -Message3 "SKU: $script:vmsku"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "OS" -Message2 "$global:msrdOSVer $OSArc (Build: $global:WinVerMajor.$global:WinVerMinor.$global:WinVerBuild.$global:WinVerRevision)" -Message3 "SKU: $script:vmsku"
            }
        }

        $unsupportedMsg = "This OS version is no longer supported. See: {0}. Please upgrade the machine to a more current, in-service, and supported Windows release."
        if ((($global:WinVerMajor -like "*10*") -and (@("10240", "10586", "14393", "15063", "16299", "17134", "17763", "18362", "18363", "19041", "19042", "19043") -contains $global:WinVerBuild) -and !($global:msrdOSVer -like "*Server*")) -or ($global:msrdOSVer -like "*Windows 8.1*")) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            $ref = switch -Wildcard ($global:msrdOSVer) {
                "*Pro*" { $w10proRef }
                "*Home*" { $w10proRef }
                "*Enterprise*" { $w10entRef }
                "*Education*" { $w10entRef }
                "*Windows 8.1*" { $w81Ref }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 ($unsupportedMsg -f $ref) -circle "red"
        }

        if (($global:msrdOSVer -like "*Server 2008 R2*") -or ($global:msrdOSVer -like "*Server 2012 R2*")) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            $ref = switch -Wildcard ($global:msrdOSVer) {
                "*Server 2008 R2*" { $w2008r2Ref }
                "*Server 2012 R2*" { $w2012r2Ref }
            }
            if (($global:msrdOSVer -like "*2012 R2*") -and ($global:msrdAVD)) {
                $unsupportedMsg += " See the list of supported OS for AVD: $avdOSRef"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 ($unsupportedMsg -f $ref) -circle "red"
        }

        if (($global:WinVerMajor -like "*10*") -and (@("19044", "22000") -contains $global:WinVerBuild) -and (($global:msrdOSVer -like "*Pro*") -or ($global:msrdOSVer -like "*Home*"))) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            $ref = switch -Wildcard ($global:msrdOSVer) {
                "*Pro*" { $w10proRef }
                "*Home*" { $w10proRef }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 ($unsupportedMsg -f $ref) -circle "red"
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "OS" -Message2 "$global:msrdOSVer (Build: $global:WinVerMajor.$global:WinVerBuild.$global:WinVerRevision)" -Message3 "SKU: $script:vmsku"
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        $w7message = $unsupportedMsg
        if ($global:msrdAVD) {
            $w7message += " See the list of supported OS for AVD: $avdOSRef"
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 $w7message -circle "red"
    }

    if ($global:msrdAVD -and $global:msrdTarget) {
        if (($global:msrdOSVer -like "*Pro*") -or ($global:msrdOSVer -like "*Enterprise N*") -or ($global:msrdOSVer -like "*LTSB*") -or ($global:msrdOSVer -like "*LTSC*") -or ($global:msrdOSVer -like "*Enterprise KN*")) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "If this machine is intended to be an AVD host, then this OS is not supported. See the list of supported operating systems for AVD hosts: $avdOSRef" -circle "red"
        }
    }

    #image type
    if ($avdcheck) {
        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -value "AzureVmImageType") {
            $azvmtype = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -name "AzureVmImageType"
            if ($azvmtype -eq "Marketplace") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Image Type" -Message2 "$azvmtype" -circle "green"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Image Type" -Message2 "$azvmtype" -circle "white"
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Image Type" -Message2 "N/A"
        }
    }

    #SystemProductName
    if (msrdTestRegistryValue -path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -value "SystemProductName") {
        $sysprodname = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -name "SystemProductName"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Model" -Message2 "$sysprodname"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Model" -Message2 "N/A"
    }

    #check number of vCPUs
    $vCPUs = (Get-CimInstance -Namespace "root\cimv2" -Query "select NumberOfLogicalProcessors from Win32_ComputerSystem" -ErrorAction SilentlyContinue).NumberOfLogicalProcessors
    $vMemInit = (Get-CimInstance -Namespace "root\cimv2" -Query "select TotalPhysicalMemory from Win32_ComputerSystem" -ErrorAction SilentlyContinue).TotalPhysicalMemory
    $vMem = ("{0:N0}" -f ($vMemInit/1gb)) + " GB"

    if (($global:msrdOSVer -like "*Virtual Desktops*") -or ($global:msrdOSVer -like "*multi-session*") -or ($global:msrdOSVer -like "*Server*")) {
        if (($vCPUs -lt 4) -or ($vCPUs -gt 24)) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Size" -Message2 "$script:vmsize ($vCPUs vCPUs / $vMem RAM). Recommended is to have between 4 and 24 vCPUs for multi-session VMs. See $vmsizeRef" -circle "yellow"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Size" -Message2 "$script:vmsize ($vCPUs vCPUs / $vMem RAM)"
        }
    } else {
        if ($vCPUs -lt 4) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Size" -Message2 "$script:vmsize ($vCPUs vCPUs / $vMem RAM). Recommended is to have at least 4 vCPUs for single-session VMs. See $vmsizeRef" -circle "yellow"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Size" -Message2 "$script:vmsize ($vCPUs vCPUs / $vMem RAM)"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Location" -Message2 "$script:vmloc"

    #get timezone
    $ltz = Get-ItemPropertyValue -path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -name "TimeZoneKeyName" -ErrorAction SilentlyContinue
    if ($ltz) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "System Time Zone" -Message2 "$ltz"
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "System Time Zone could not be retrieved" -circle "red"
    }
    $rtz = (Get-TimeZone).Id + " [" + (Get-TimeZone).DisplayName + "]"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "In-session Time Zone" -Message2 "$rtz"

    #culture
    $cul = Get-Culture | Select-Object Name, DisplayName, KeyboardLayoutId
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Culture" -Message2 "$($cul.DisplayName)" -Message3 "$($cul.Name) ($($cul.KeyboardLayoutId))"

    $muilang = (Get-WmiObject -Class Win32_OperatingSystem).MUILanguages
    $muilist = ""
    foreach ($ml in $muilang) {
        $muilist += $ml
        if ($ml -ne $muilang[-1]) { $muilist += "; " }
    }
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "MUI Language(s)" -Message2 "$muilist"

    #Azure resource id
    if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -value "AzureResourceId") {
        $arid = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -name "AzureResourceId"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Azure Resource Id" -Message2 "$arid"
    }

    #Azure VM id
    if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -value "AzureVmId") {
        $avmid = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -name "AzureVmId"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Azure VM Id" -Message2 "$avmid"
    }

    #AVD host GUID
    if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -value "GUID") {
        $hguid = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -name "GUID"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "AVD Host GUID" -Message2 "$hguid"
    }

    #OS install date
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    $OSinstallDate = (Get-CimInstance Win32_OperatingSystem).InstallDate
    $OSinstallDiff = [datetime]::Now - $OSinstallDate
    $OSage = "$($OSinstallDiff.Days)d $($OSinstallDiff.Hours)h $($OSinstallDiff.Minutes)m ago"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "OS installation date/time" -Message2 "$OSinstallDate ($OSage)"

    #check last boot up time
    $lboott = (Get-CimInstance -ClassName win32_operatingsystem).lastbootuptime
    $lboottdif = [datetime]::Now - $lboott
    $sincereboot = "$($lboottdif.Days)d $($lboottdif.Hours)h $($lboottdif.Minutes)m ago"

    if ($lboottdif.TotalHours -gt 168) {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        if (Test-Path ($global:msrdLogDir + $powerfile)) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Last boot up date/time" -Message2 "$lboott ($sincereboot)" -circle "yellow" -Message3 "(See: <a href='$powerfile' target='_blank'>SystemPowerReport</a>)"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Last boot up date/time" -Message2 "$lboott ($sincereboot)" -circle "yellow"
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "While optional, rebooting more frequently could help clean out stuck sessions or avoid potential profile load issues." -circle "yellow"
    } else {
        if (Test-Path ($global:msrdLogDir + $powerfile)) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Last boot up date/time" -Message2 "$lboott ($sincereboot)" -Message3 "(See: <a href='$powerfile' target='_blank'>PowerReport</a>)"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Last boot up date/time" -Message2 "$lboott ($sincereboot)"
        }
    }

    #check .Net Framework (https://learn.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies)
    $dotnet = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
    if ($dotnet -ge 533320) { $dotnetver = "4.8.1 or later" }
    elseif (($dotnet -ge 528040) -and ($dotnet -lt 533320)) { $dotnetver = "4.8" }
    elseif (($dotnet -ge 461808) -and ($dotnet -lt 528040)) { $dotnetver = "4.7.2" }
    elseif (($dotnet -ge 461308) -and ($dotnet -lt 461808)) { $dotnetver = "4.7.1" }
    elseif (($dotnet -ge 460798) -and ($dotnet -lt 461308)) { $dotnetver = "4.7" }
    elseif (($dotnet -ge 394802) -and ($dotnet -lt 460798)) { $dotnetver = "4.6.2" }
    elseif (($dotnet -ge 394254) -and ($dotnet -lt 394802)) { $dotnetver = "4.6.1" }
    elseif (($dotnet -ge 393295) -and ($dotnet -lt 394254)) { $dotnetver = "4.6" }
    elseif (($dotnet -ge 379893) -and ($dotnet -lt 393295)) { $dotnetver = "4.5.2" }
    elseif (($dotnet -ge 378675) -and ($dotnet -lt 379893)) { $dotnetver = "4.5.1" }
    elseif (($dotnet -ge 378389) -and ($dotnet -lt 378675)) { $dotnetver = "4.5" }
    else { $dotnetver = "No .NET Framework 4.5 or later" }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    if ($global:msrdAVD -or $global:msrdW365) {
        if ($dotnet -lt 461808) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $dotNetcircle = "red"
        } else {
            $dotNetcircle = "green"
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message ".Net Framework version" -Message2 "$dotnetver" -circle $dotNetcircle
        if ($dotnet -lt 461808) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "AVD/W365 requires .NET Framework 4.7.2 or later" -circle $dotNetcircle
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message ".Net Framework" -Message2 "$dotnetver"
    }

    #check for Intune extension
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    $intuneExt = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Microsoft Intune Management Extension%'" -ErrorAction SilentlyContinue | Select-Object Name, Version
    if ($intuneExt) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$($intuneExt.Name)" -Message2 "$($intuneExt.Version)"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Microsoft Intune Management Extension" -Message2 "not found"
    }

    #checking for useful reg keys
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\Setup\' -RegKey 'OOBEInProgress' -RegValue '0' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\Setup\' -RegKey 'SystemSetupInProgress' -RegValue '0' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\Setup\' -RegKey 'SetupPhase' -RegValue '0' -warnColor "yellow"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Control Panel\International\' -RegKey 'RestrictLanguagePacksAndFeaturesInstall' -OptNote 'Computer Policy: Restrict Language Pack and Language Feature Installation'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\MUI\Settings\' -RegKey 'MachineUILock' -OptNote 'Computer Policy: Force selected system UI language to overwrite the user UI language'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\MUI\Settings\' -RegKey 'PreferredUILanguages' -OptNote 'Computer Policy: Restricts the UI language Windows uses for all logged users'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Control Panel\Desktop\' -RegKey 'MultiUILanguageID' -OptNote 'User Policy: Restrict selection of Windows menus and dialogs language'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Control Panel\Desktop\' -RegKey 'PreferredUILanguages' -OptNote 'User Policy: Restricts the UI languages Windows should use for the selected user'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Control Panel\International\' -RegKey 'RestrictLanguagePacksAndFeaturesInstall' -OptNote 'User Policy: Restrict Language Pack and Language Feature Installation'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagCPU {

    #CPU diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "CPU Utilization and Handles"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "CPUCheck" -Message $menuitemmsg

    $procs = Get-Process | Select-Object ProcessName, Id, CPU, Handles, NPM, PM, WS, Description

    $Top10CPU = $procs | Sort-Object CPU -desc | Select-Object -first 10
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "Top 10 processes using the most <span style='color: blue'>CPU time</span> on all processors" -col 7 -circle "no"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

    if (-not $global:msrdLiveDiag) {
        Add-Content $msrdDiagFile "<tr align='center'><th width='10px'><div class='circle_no'></div></th><th>Process</th><th>Id</th><th>CPU(s)</th><th>Handles</th><th>NPM(K)</th><th>PM(K)</th><th>WS(K)</th></tr>"
    }

    foreach ($entry in $Top10CPU) {
        if ($entry.Description) {
            $desc = $entry.Description
        } else {
            $desc = "N/A"
        }

        if ($global:msrdLiveDiag) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 7 -Message "Process: $($entry.ProcessName) ($desc) - Id: $($entry.Id) - CPU(s): $($entry.CPU) - Handles: $($entry.Handles) - NPM(K): $($entry.NPM) - NPM(K): $($entry.PM) - WS(K): $($entry.WS)"
        } else {
            Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_white'></div></td><td align='left' width='25%'>$($entry.ProcessName) ($desc)</td><td align='right'>$($entry.Id)</td><td align='right'><span style='color: blue'>$($entry.CPU)</span></td><td align='right'>$($entry.Handles)</td><td align='right'>$($entry.NPM)</td><td align='right'>$($entry.PM)</td><td align='right'>$($entry.WS)</td></tr>"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR" -col 7

    $Top10Handles = $procs | Sort-Object Handles -desc | Select-Object -first 10
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "Top 10 processes using the most <span style='color: blue'>handles</span>" -col 7 -circle "no"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

    if (-not $global:msrdLiveDiag) {
        Add-Content $msrdDiagFile "<tr align='center'><th width='10px'><div class='circle_no'></div></th><th>Process</th><th>Id</th><th>CPU(s)</th><th>Handles</th><th>NPM(K)</th><th>PM(K)</th><th>WS(K)</th></tr>"
    }

    foreach ($entry in $Top10Handles) {
        if ($entry.Description) {
            $desc = $entry.Description
        } else {
            $desc = "N/A"
        }

        if ($global:msrdLiveDiag) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 7 -Message "Process: $($entry.ProcessName) ($desc) - Id: $($entry.Id) - CPU(s): $($entry.CPU) - Handles: $($entry.Handles) - NPM(K): $($entry.NPM) - NPM(K): $($entry.PM) - WS(K): $($entry.WS)"
        } else {
            if ($entry.Handles -gt 50000) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_yellow'></div></td><td align='left' width='25%'>$($entry.ProcessName) ($desc)</td><td align='right'>$($entry.Id)</td><td align='right'>$($entry.CPU)</td><td align='right'>$($entry.Handles)</td><td align='right'>$($entry.NPM)</td><td align='right'>$($entry.PM)</td><td align='right'>$($entry.WS)</td></tr>"
            } else {
                Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_white'></div></td><td align='left' width='25%'>$($entry.ProcessName) ($desc)</td><td align='right'>$($entry.Id)</td><td align='right'>$($entry.CPU)</td><td align='right'><span style='color: blue'>$($entry.Handles)</span></td><td align='right'>$($entry.NPM)</td><td align='right'>$($entry.PM)</td><td align='right'>$($entry.WS)</td></tr>"
            }
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagDrives {

    #disk diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Drives"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "DiskCheck" -Message $menuitemmsg

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Local/Network drives" -circle "no"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

    $drvtype = "Unknown", "No Root Directory", "Removable Disk", "Local Disk", "Network Drive", "Compact Disc", "RAM Disk"
    $Vol = Get-CimInstance -NameSpace "root\cimv2" -Query "select * from Win32_LogicalDisk" -ErrorAction Continue 2>>$global:msrdErrorLogFile

    if (-not $global:msrdLiveDiag) {
        Add-Content $msrdDiagFile "<tr align='center'><th width='10px'><div class='circle_no'></div></th><th>Drive</th><th>Type</th><th>Total space (MB)</th><th>Free space (MB)</th><th>Percent free space</th></tr>"
    }

    foreach ($disk in $vol) {
        if ($null -ne $disk.Size) { $PercentFreeSpace = $disk.FreeSpace*100/$disk.Size }
        else { $PercentFreeSpace = 0 }

        $driveid = $disk.DeviceID
        $drivetype = $drvtype[$disk.DriveType]
        $ts = [math]::Round($disk.Size/1MB,2)
        $fs = [math]::Round($disk.FreeSpace/1MB,2)
        $pfs = [math]::Round($PercentFreeSpace,2)

        #warn if free space is below 5% of disk size
        if (($PercentFreeSpace -gt 1 -and $PercentFreeSpace -lt 5) -and (($drivetype -eq "Local Disk") -or ($drivetype -eq "Network Drive"))) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            if ($driveid -eq "C:") {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Drive: $driveid - Type: $drivetype - Total space (MB): $ts - Free space (MB): $fs - Percent free space: $pfs%"
                } else {
                    if (Test-Path ($global:msrdLogDir + $permDriveCfile)) {
                        Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_yellow'></div></td><td>$driveid (See: <a href='$permDriveCfile' target='_blank'>Permissions</a>)</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td><span style='color: red'>$pfs%</span></td></tr>"
                    } else {
                        Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_yellow'></div></td><td>$driveid</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td><span style='color: red'>$pfs%</span></td></tr>"
                    }
                }
            } else {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Drive: $driveid - Type: $drivetype - Total space (MB): $ts - Free space (MB): $fs - Percent free space: $pfs%"
                } else {
                    Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_yellow'></div></td><td>$driveid</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td><span style='color: red'>$pfs%</span></td></tr>"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "You are running low on free space (less than 5%) on drive: $driveid" -col 5 -circle "red"
        } elseif (($PercentFreeSpace -le 1) -and (($drivetype -eq "Local Disk") -or ($drivetype -eq "Network Drive"))) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            if ($driveid -eq "C:") {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Drive: $driveid - Type: $drivetype - Total space (MB): $ts - Free space (MB): $fs - Percent free space: $pfs%"
                } else {
                    if (Test-Path ($global:msrdLogDir + $permDriveCfile)) {
                        Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_red'></div></td><td>$driveid (See: <a href='$permDriveCfile' target='_blank'>Permissions</a>)</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td><span style='color: red'>$pfs%</span></td></tr>"
                    } else {
                        Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_red'></div></td><td>$driveid</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td><span style='color: red'>$pfs%</span></td></tr>"
                    }
                }
            } else {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Drive: $driveid - Type: $drivetype - Total space (MB): $ts - Free space (MB): $fs - Percent free space: $pfs%"
                } else {
                    Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_red'></div></td><td>$driveid</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td><span style='color: red'>$pfs%</span></td></tr>"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "You are running low on free space (less than 5%) on drive: $driveid" -col 5 -circle "red"
        } else {
            if ($driveid -eq "C:") {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Drive: $driveid - Type: $drivetype - Total space (MB): $ts - Free space (MB): $fs - Percent free space: $pfs%"
                } else {
                    if (Test-Path ($global:msrdLogDir + $permDriveCfile)) {
                        Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_white'></div></td><td>$driveid (See: <a href='$permDriveCfile' target='_blank'>Permissions</a>)</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td>$pfs%</td></tr>"
                    } else {
                        Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_white'></div></td><td>$driveid</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td>$pfs%</td></tr>"
                    }
                }
            } else {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Drive: $driveid - Type: $drivetype - Total space (MB): $ts - Free space (MB): $fs - Percent free space: $pfs%"
                } else {
                    Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_white'></div></td><td>$driveid</td><td>$drivetype</td><td>$ts</td><td>$fs</td><td>$pfs%</td></tr>"
                }
            }
        }
    }

    #rdp redirected drives
    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR" -col 5
        $rdpdrives = net use
        if ($rdpdrives -and ($rdpdrives -like "*tsclient*")) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Remote Desktop redirected drives" -circle "no"
            foreach ($rdpd in $rdpdrives) {
                if ($rdpd -like "*tsclient*") {
                    $rdpdregex1 = [regex]::new("\\\\[^ ]+")
                    $drive = $rdpdregex1.Match($rdpd).Value

                    $rdpdregex2 = [regex]::new("\\\\[^ ]+ *(.+)$")
                    $network = $rdpdregex2.Match($rdpd).Groups[1].Value
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$drive" -Message3 "$network" -circle "white"
                }
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 5 -Message "Remote Desktop redirected drives not found"
        }
    }

    #client side redirection
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR" -col 5
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableDriveRedirection' -RegValue '0'

    #host side redirection
    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCdm' -RegValue '0' -OptNote 'Computer Policy: Do not allow drive redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableCdm' -RegValue '0'
        if ($global:msrdAVD -or $global:msrdW365) {
            if ($script:msrdListenervalue) {
                msrdCheckRegKeyValue ('HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' + $script:msrdListenervalue + '\') -RegKey 'fDisableCdm' -RegValue '0'
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Active AVD listener configuration not found" -circle "red"
            }
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }

}

Function msrdGetDispScale {

    #get display scale %
$code2 = @'
  using System;
  using System.Runtime.InteropServices;
  using System.Drawing;

  public class DPI {
    [DllImport("gdi32.dll")]
    static extern int GetDeviceCaps(IntPtr hdc, int nIndex);

    public enum DeviceCap { VERTRES = 10, DESKTOPVERTRES = 117 }

    public static float scaling() {
      Graphics g = Graphics.FromHwnd(IntPtr.Zero);
      IntPtr desktop = g.GetHdc();
      int LogicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.VERTRES);
      int PhysicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.DESKTOPVERTRES);
      return (float)PhysicalScreenHeight / (float)LogicalScreenHeight;
    }
  }
'@

if ($PSVersionTable.PSVersion.Major -eq 5) {
    Add-Type -TypeDefinition $code2 -ReferencedAssemblies 'System.Drawing.dll'
} else {
    Add-Type -TypeDefinition $code2 -ReferencedAssemblies 'System.Drawing.dll','System.Drawing.Common'
}

    $DScale = [Math]::round([DPI]::scaling(), 2) * 100
    if ($DScale) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Primary display scaling rate" -Message2 "$DScale%"
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "Primary display scaling rate could not be determined." -col 3 -circle "red"
    }
}

function msrdCheckRDPSession {

    # Check if the current session is an RDP session
    $sessionType = (Get-WmiObject -Class Win32_LogonSession | Where-Object { $_.LogonType -eq 10 }).LogonType
    if ($sessionType -eq 10) {
        return $true
    } else {
        return $false
    }
}

function msrdGetRDPResolution {

try {
        # Define the Windows API function signature
Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class User32 {
        [DllImport("user32.dll")]
        public static extern int GetSystemMetrics(int nIndex);
    }
"@

        # Define the index constants for width and height
        $SM_CXSCREEN = 0
        $SM_CYSCREEN = 1

        # Get the width and height of the RDP window
        $width = [User32]::GetSystemMetrics($SM_CXSCREEN)
        $height = [User32]::GetSystemMetrics($SM_CYSCREEN)

        # Output the resolution
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote session resolution" -Message2 "${width}x${height}"
    } catch {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote session resolution could not be retrieved" -circle "yellow"
    }

}

Function msrdDiagGraphics {

    #graphics diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Graphics"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "GPUCheck" -Message $menuitemmsg

    if (!($global:msrdOSVer -like "*Server*2008*") -and !($global:msrdOSVer -like "*Server*2012*")) {

        if ($global:msrdLiveDiag) { msrdCheckAzVM }

        if ($script:vmsize -ne "N/A") {
            if (($script:vmsize -like "*NV*") -or ($script:vmsize -like "*NC*")) {
                if (Test-Path ($global:msrdLogDir + $dxdiagfile)) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "A GPU optimized Azure VM size has been detected." -Message2 "$($script:vmsize) (See: <a href='$dxdiagfile' target='_blank'>DxDiag</a>)" -circle "green"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "A GPU optimized Azure VM size has been detected." -Message "$($script:vmsize)" 3 -circle "green"
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "Make sure all the prerequisites are met to take full advantage of the GPU capabilities. See $gpuRef" -col 3 -circle "white"
                $GPUreq = $true
            } else {
                if (Test-Path ($global:msrdLogDir + $dxdiagfile)) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "This machine is not a GPU enabled Azure VM." -Message2 "$($script:vmsize) (See: <a href='$dxdiagfile' target='_blank'>DxDiag</a>)" -circle "white"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "This machine is not a GPU enabled Azure VM." -Message2 "$($script:vmsize)" -circle "white"
                }
                $GPUreq = $false
            }
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "GPU-accelerated rendering and encoding are not supported for this OS version." -col 3 -circle "white"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

    $gfx = Get-CimInstance -Class Win32_VideoController | Select-Object Name, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution
    $gfxdriverfound = $false
    if ($gfx) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Video Controllers" -circle "no"
        foreach ($item in $gfx) {
            $gfxname = $item.Name
            $gfxdriver = $item.DriverVersion
            if ($item.CurrentHorizontalResolution -and $item.CurrentVerticalResolution) {
                $gfxresolution = " (" + $item.CurrentHorizontalResolution + "x" + $item.CurrentVerticalResolution + ")"
            } else { $gfxresolution = ""}

            if ($gfxname -like "*radeon*" -or $gfxname -like "*nvidia*") { $gfxdriverfound = $true }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$gfxname$gfxresolution" -Message3 "$gfxdriver"
        }
    }

    if (($script:vmsize -like "*NV*" -or $script:vmsize -like "*NC*") -and (-not $gfxdriverfound)) {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The VM size is GPU optimized but could not find any AMD or NVidia drivers installed." -circle "red"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Monitors" -circle "no"

    $Monitors = Get-WmiObject WmiMonitorID -Namespace root\wmi -ErrorAction Continue 2>>$global:msrdErrorLogFile
    if ($Monitors) {
        ForEach ($Monitor in $Monitors) {
            $Manufacturer = ($Monitor.ManufacturerName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ""
            $Name = ($Monitor.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ""
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$Manufacturer" -Message3 "$Name"
        }
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not retrieve monitor information. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdGetDispScale  #Get display scale

    if (msrdCheckRDPSession) {
        msrdGetRDPResolution #Get RDP window resolution
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'EnableAdvancedRemoteFXRemoteAppSupport'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'EnableAdvancedRemoteFXRemoteAppSupport'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client\' -RegKey 'EnableHardwareMode' -OptNote "Computer Policy: Do not allow hardware accelerated decoding"

    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

        if ($GPUreq) {
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'bEnumerateHWBeforeSW' -RegValue '1' -OptNote 'Computer Policy: Use hardware graphics adapters for all Remote Desktop Services sessions' -warnMissing
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'AVCHardwareEncodePreferred' -RegValue '1' -OptNote 'Computer Policy: Configure H.264/AVC hardware encoding for Remote Desktop Connections' -warnMissing
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'AVC444ModePreferred' -RegValue '1' -OptNote 'Computer Policy: Prioritize H.264/AVC 444 graphics mode for Remote Desktop Connections' -warnMissing
        } else {
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'bEnumerateHWBeforeSW' -RegValue '1' -OptNote 'Computer Policy: Use hardware graphics adapters for all Remote Desktop Services sessions'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'AVCHardwareEncodePreferred' -RegValue '1' -OptNote 'Computer Policy: Configure H.264/AVC hardware encoding for Remote Desktop Connections'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'AVC444ModePreferred' -RegValue '1' -OptNote 'Computer Policy: Prioritize H.264/AVC 444 graphics mode for Remote Desktop Connections'
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableWddmDriver' -OptNote 'Computer Policy: Use WDDM graphics display driver for Remote Desktop Connections'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableRemoteFXAdvancedRemoteApp' -OptNote 'Computer Policy: Use advanced RemoteFX graphics for RemoteApp'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxMonitors' -OptNote 'Computer Policy: Limit number of monitors'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxXResolution' -OptNote 'Computer Policy: Limit maximum display resolution'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxYResolution' -OptNote 'Computer Policy: Limit maximum display resolution'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\H264Encoding\' -RegKey 'EnableAlwaysChroma'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -RegKey 'DWMFRAMEINTERVAL'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -RegKey 'fEnableRemoteFXAdvancedRemoteApp'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -RegKey 'IgnoreClientDesktopScaleFactor'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MaxMonitors'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MaxXResolution'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MaxYResolution'
    }

    if (($global:msrdAVD -or $global:msrdW365) -and $global:msrdTarget) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs\' -RegKey 'MaxMonitors'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs\' -RegKey 'MaxXResolution'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs\' -RegKey 'MaxYResolution'
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RdpCloudStackSettings\' -RegKey 'RAILDVCActivateThreshold'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RdpCloudStackSettings\' -RegKey 'AVCMaxChromaKeyFrameDistance'
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\' -RegKey 'PreferExternalManifest'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Display\' -RegKey 'DisableGdiDPIScaling' -OptNote 'Computer Policy: Turn off GdiDPIScaling for applications'
    msrdCheckRegKeyValue -RegPath 'HKCU:\Control Panel\Desktop\' -RegKey 'DesktopDPIOverride'
    msrdCheckRegKeyValue -RegPath 'HKCU:\Control Panel\Desktop\' -RegKey 'LogPixels'
    msrdCheckRegKeyValue -RegPath 'HKCU:\Control Panel\Desktop\' -RegKey 'UserPreferencesMask'
    msrdCheckRegKeyValue -RegPath 'HKCU:\Control Panel\Desktop\' -RegKey 'Win8DpiScaling'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagHyperVIntegration {

    #Hyper-V Integration status
    $global:msrdSetWarning = $false
    $menuitemmsg = "Hyper-V Integration"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "HyperVCheck" -Message $menuitemmsg

    #windows feature
    $winOptFeat = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -ErrorAction SilentlyContinue
    if ($winOptFeat) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Windows Feature" -Message2 "$($winOptFeat.DisplayName)" -Message3 "$($winOptFeat.State)" -OptNote "$($winOptFeat.Description)"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Windows Feature" -Message2 "Microsoft-Hyper-V" -Message3 "not found"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmicguestinterface
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmicheartbeat
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmickvpexchange
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmicrdv -skipWarning 1
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmicshutdown
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmictimesync
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmicvmsession
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service vmicvss -skipWarning 1

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagActivation {

    #activation diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "OS Activation / Licensing"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "KMSCheck" -Message $menuitemmsg

    try {
        $activ = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" -Property Name, Description, licensestatus -OperationTimeoutSec 30 -ErrorAction Stop | Where-Object licensestatus -eq 1
        if ($activ) {
            if (Test-Path ($global:msrdLogDir + $slmgrfile)) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Product Name" -Message2 "$($activ.Name)" -Message3 "(See: <a href='$slmgrfile' target='_blank'>slmgr-dlv</a>)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Product Name" -Message2 "$($activ.Name)"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Product Description" -Message2 "$($activ.Description)"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Product Name" -Message2 "N/A"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Product Description" -Message2 "N/A"
        }
    } catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An error occurred while trying to retrieve SoftwareLicensingProduct information. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
    }

    #kms
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    if (Test-Path ($global:msrdLogDir + $kmsfile)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "KMS information" -Message2 "(See: <a href='$kmsfile' target='_blank'>KMS-Servers</a>)" -circle "no"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "KMS information" -Message2 "$kmsurl" -circle "no"
    }

    $kms = Get-CimInstance SoftwareLicensingService | Select-Object DiscoveredKeyManagementServiceMachineName, DiscoveredKeyManagementServiceMachinePort, DiscoveredKeyManagementServiceMachineIpAddress, KeyManagementServiceMachine, KeyManagementServicePort -ErrorAction Continue 2>>$global:msrdErrorLogFile
    if ($kms) {
        foreach ($line in $kms) {
            foreach ($item in $line.PSObject.Properties) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($item.Name)" -Message3 "$($item.Value)"
            }
        }

        if ($kms.DiscoveredKeyManagementServiceMachineName) { $kmsDiscoveredUrl = $kms.DiscoveredKeyManagementServiceMachineName }
        if ($kms.DiscoveredKeyManagementServiceMachinePort) { $kmsDiscoveredPort = $kms.DiscoveredKeyManagementServiceMachinePort }
        if ($kms.KeyManagementServiceMachine) { $kmsUrl = $kms.KeyManagementServiceMachine }
        if ($kms.KeyManagementServicePort) { $kmsPort = $kms.KeyManagementServicePort }
        if ($kms.DiscoveredKeyManagementServiceMachineIpAddress) { $kmsIP = $kms.DiscoveredKeyManagementServiceMachineIpAddress }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        Try {
            if ($kmsDiscoveredUrl -and ($kmsDiscoveredUrl -ne "")) {
                $kmsconTest = msrdTestTCP "$kmsDiscoveredUrl" "$kmsDiscoveredPort"
                if ($kmsconTest[0] -eq "True") {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test to Discovered KMS server '$kmsDiscoveredUrl' ($kmsIP)" -Message2 "TCP $kmsDiscoveredPort`: <span style='color: green'>Reachable</span>" -circle "green"
                } else {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test to Discovered KMS server '$kmsDiscoveredUrl' ($kmsIP)" -Message2 "TCP $kmsDiscoveredPort`: <span style='color: red'>Not reachable</span>" -circle "red"
                }
            }
        } Catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        }

        Try {
            if ($kmsUrl -and ($kmsUrl -ne "")) {
                $kmsconTest = msrdTestTCP "$kmsUrl" "$kmsport"
                if ($kmsconTest[0] -eq "True") {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test to KMS server '$kmsUrl' ($kmsIP)" -Message2 "TCP $kmsPort`: <span style='color: green'>Reachable</span>" -circle "green"
                } else {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test to KMS server '$kmsUrl' ($kmsIP)" -Message2 "TCP $kmsPort`: <span style='color: red'>Not reachable</span>" -circle "red"
                }
            }
        } Catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        }

        if (($global:msrdOSVer -like "*virtu*" -or $global:msrdOSVer -like "*multi*session*") -and $kmsUrl -notlike "*kms.core.windows.net" -and $kmsDiscoveredUrl -notlike "*kms.core.windows.net") {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "You are not using Azure KMS for this machine's activation. An AVD multi-session OS requires Azure KMS for proper activation." -circle "red"
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No KMS information found"
    }

    #avd licensing
    if (($global:msrdAVD -or $global:msrdW365) -and $global:msrdTarget) {

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if ($global:msrdLiveDiag) { msrdCheckAzVM }

        if ($script:msrdVmlictype -eq "Windows_Client") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "License Type" -Message2 "$script:msrdVmlictype" -circle "green"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "License Type" -Message2 "$script:msrdVmlictype" -circle "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "This is not the expected license type for an AVD/W365 machine. See: $avdLicRef" -circle "red"
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagSSLTLS {

    #SSL/TLS diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "SSL / TLS"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "SSLCheck" -Message $menuitemmsg

    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002\' -RegKey 'Functions' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002\' -RegKey 'EccCurves' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010003\' -RegKey 'Functions' -addWarning

    if ($script:registeredBrowsers -like "*Chrome*") {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Google\Chrome\' -RegKey 'SSLVersionMin'
    }
    if ($script:registeredBrowsers -like "*Edge*") {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'SSLVersionMin'
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727\' -RegKey 'SchUseStrongCrypto' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727\' -RegKey 'SystemDefaultTlsVersions' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\' -RegKey 'SchUseStrongCrypto' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\' -RegKey 'SystemDefaultTlsVersions' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727\' -RegKey 'SchUseStrongCrypto' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727\' -RegKey 'SystemDefaultTlsVersions' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319\' -RegKey 'SchUseStrongCrypto' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319\' -RegKey 'SystemDefaultTlsVersions' -RegValue '1'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client\' -RegKey 'Enabled'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client\' -RegKey 'DisabledByDefault'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client\' -RegKey 'Enabled' -RegValue '0' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client\' -RegKey 'DisabledByDefault' -RegValue '1' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client\' -RegKey 'Enabled' -RegValue '0' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client\' -RegKey 'DisabledByDefault' -RegValue '1' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client\' -RegKey 'Enabled' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client\' -RegKey 'DisabledByDefault' -RegValue '0'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client\' -RegKey 'Enabled'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client\' -RegKey 'DisabledByDefault'

    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server\' -RegKey 'Enabled'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server\' -RegKey 'DisabledByDefault'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server\' -RegKey 'Enabled' -RegValue '0' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server\' -RegKey 'DisabledByDefault' -RegValue '1' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server\' -RegKey 'Enabled' -RegValue '0' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server\' -RegKey 'DisabledByDefault' -RegValue '1' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server\' -RegKey 'Enabled' -RegValue '1'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server\' -RegKey 'DisabledByDefault' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server\' -RegKey 'Enabled'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server\' -RegKey 'DisabledByDefault'
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\' -RegKey 'ForceDefaultSecureProtocols' -addWarning -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\' -RegKey 'EnableInsecureTlsFallback' -addWarning -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'EnableInsecureTlsFallback' -addWarning -warnColor "yellow"

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagUAC {

    #User Access Control diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "User Account Control"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "UACCheck" -Message $menuitemmsg

    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'EnableLUA' -RegValue '1' -OptNote 'Computer Policy: User Account Control: Run all administrators in Admin Approval Mode' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'PromptOnSecureDesktop' -RegValue '1' -OptNote 'Computer Policy: User Account Control: Switch to the secure desktop when prompting for elevation' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'ConsentPromptBehaviorAdmin' -RegValue '5' -OptNote 'Computer Policy: User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'ConsentPromptBehaviorUser' -RegValue '3' -OptNote 'Computer Policy: User Account Control: Behavior of the elevation prompt for standard users' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'EnableUIADesktopToggle' -RegValue '0' -OptNote 'Computer Policy: User Account Control: Allow UIAccess applications to prompt for elevation without using the secure desktop' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'EnableInstallerDetection' -OptNote 'Computer Policy: User Account Control: Detect application installations and prompt for elevation' -warnColor "yellow"

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagInstaller {

    #Windows Installer diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Windows Installer"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "InstallerCheck" -Message $menuitemmsg

    msrdCheckServicePort -service msiserver

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\Software\Policies\Microsoft\Windows\Installer\' -RegKey 'disablemsi' -OptNote 'Computer Policy: Turn off Windows Installer'
    msrdCheckRegKeyValue -RegPath 'HKLM:\Software\Policies\Microsoft\Windows\Installer\' -RegKey 'Logging'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagSearch {

    #Windows Search diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Windows Search"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "SearchCheck" -Message $menuitemmsg

    msrdCheckServicePort -service wsearch -warnColor "yellow"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows Search\' -RegKey 'EnablePerUserCatalog'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Apps\' -RegKey 'RoamSearch'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'RoamSearch'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'RoamSearch'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagWU {

    #Windows Update diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Windows Update"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "WUCheck" -Message $menuitemmsg

    if (Test-Path ($global:msrdLogDir + $updhistfile)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "OS Build" -Message2 ($global:WinVerMajor + "." + $global:WinVerMinor + "." + $global:WinVerBuild + "." + $global:WinVerRevision) -Message3 "(See: <a href='$updhistfile' target='_blank'>UpdateHistory</a>)" -circle "white"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "OS Build" -Message2 ($global:WinVerMajor + "." + $global:WinVerMinor + "." + $global:WinVerBuild + "." + $global:WinVerRevision) -circle "white"
    }

    $unsupportedMsg = "This OS version is no longer supported. Upgrade the OS to a supported version. See: {0}"

    if (($global:WinVerMajor -like "*10*") -and (@("10240", "10586", "14393", "15063", "16299", "17134", "17763", "18362", "18363", "19041", "19042", "19043") -contains $global:WinVerBuild) -and !($global:msrdOSVer -like "*Server*")) {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1
        $ref = switch -Wildcard ($global:msrdOSVer) {
            "*Pro*" { $w10proRef }
            "*Home*" { $w10proRef }
            "*Enterprise*" { $w10entRef }
            "*Education*" { $w10entRef }
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 ($unsupportedMsg -f $ref) -circle "red"
    }

    if (($global:msrdOSVer -like "*Server 2008 R2*") -or ($global:msrdOSVer -like "*Server 2012 R2*")) {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        $ref = switch -Wildcard ($global:msrdOSVer) {
            "*Server 2008 R2*" { $w2008r2Ref }
            "*Server 2012 R2*" { $w2012r2Ref }
        }
        if (($global:msrdOSVer -like "*2012 R2*") -and ($global:msrdAVD)) {
            $unsupportedMsg += " See the list of supported OS for AVD: $avdOSRef"
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 ($unsupportedMsg -f $ref) -circle "red"
    }

    if (($global:WinVerMajor -like "*10*") -and (@("19044", "22000") -contains $global:WinVerBuild) -and (($global:msrdOSVer -like "*Pro*") -or ($global:msrdOSVer -like "*Home*"))) {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1
        $ref = switch -Wildcard ($global:msrdOSVer) {
            "*Pro*" { $w10proRef }
            "*Home*" { $w10proRef }
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 ($unsupportedMsg -f $ref) -circle "red"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "OS Language" -Message2 $script:osLanguage -circle "white"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    Try {
        $session = New-Object -ComObject "Microsoft.Update.Session"
        $searcher = $session.CreateUpdateSearcher()
	} Catch {
        msrdLogMessage $LogLevel.Error ("Error collecting updates information from Microsoft.Update.Session" + $_.Exception.Message)
    }

    #get latest installed Windows Update if OS is English
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Latest Installed Monthly Rollup/Cumulative Update for Windows" -circle "no"
    if ($script:osLanguage -eq "1033") {
        try {
            $historyCount = $searcher.GetTotalHistoryCount()
        } catch {
            $historyCount = 0
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        }

        if ($historyCount -gt 0) {
            $history = $searcher.QueryHistory(0, $historyCount)
            $monthlyUpdatesInstalled = $history | Where-Object { ($_.Title -like "*Monthly Rollup*" -or $_.Title -like "*Quality Rollup*" -or $_.Title -like "*Cumulative Update*System*") -and $_.Title -notlike "*.NET Framework*" -and $_.HResult -eq 0 }
            $latestInstalledUpdate = $monthlyUpdatesInstalled | Sort-Object -Property Date | Select-Object -Last 1
        } else {
            $latestInstalledUpdate = $null
        }

        if ($null -ne $latestInstalledUpdate) {
            $latestInstalledTitle = $latestInstalledUpdate.Title -replace '\s\(KB\d+\)$'
            $latestInstalledKB = [regex]::Match($latestInstalledUpdate.Title, '\(KB(\d+)\)').Groups[1].Value
            $latestInstalledDate = $latestInstalledUpdate.Date
            $latestInstalledUrl = $latestInstalledUpdate.SupportUrl

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$latestInstalledTitle" -Message3 "KB: <a href='$latestInstalledUrl' target='_blank'>$latestInstalledKB</a> (Installed on: $latestInstalledDate)" -circle "white"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "No Monthly Rollup/Cumulative Updates found on your machine." -circle "red"
        }
    } else {
        $latestInstalledUpdate = $null
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not retrieve information on the latest Monthly Rollup/Cumulative Update installed on this machine. This information is only available for English OS (1033)" -circle "yellow"
    }

    #get latest available Windows Update online
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Latest Available Monthly Rollup/Cumulative Update for Windows" -circle "no"
    try {
        $resultAvailable = $searcher.Search("Type='Software'")
        $monthlyUpdatesAvailable = $resultAvailable.Updates | Where-Object { ($_.Title -like "*Monthly Rollup*" -or $_.Title -like "*Quality Rollup*" -or $_.Title -like "*Cumulative Update*System*") -and $_.Title -notlike '*.NET Framework*' }
        $latestAvailableUpdate = $monthlyUpdatesAvailable | Sort-Object -Property LastDeploymentChangeTime | Select-Object -Last 1
    } catch {
        $latestAvailableUpdate = $null
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
    }

    if ($null -ne $latestAvailableUpdate) {
        $latestAvailableTitle = $latestAvailableUpdate.Title -replace '\s\(KB\d+\)$'
        $latestAvailableKB = $latestAvailableUpdate.KBArticleIDs[0]
        $latestAvailableUrl = $latestAvailableUpdate.SupportUrl

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$latestAvailableTitle" -Message3 "KB: <a href='$latestAvailableUrl' target='_blank'>$latestAvailableKB</a>" -circle "white"
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not retrieve information on the latest Monthly Rollup/Cumulative Update available online. You may have limited or no internet access. Make sure the system is fully updated." -circle "yellow"
    }

    $showUpdatesURL = $false
    if (($null -ne $latestInstalledUpdate) -and ($null -ne $latestAvailableUpdate)) {
        if ($latestInstalledUpdate.Date -lt $latestAvailableUpdate.LastDeploymentChangeTime) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The latest installed Monthly Rollup/Cumulative Update on this machine is older than the latest Monthly Rollup/Cumulative Update available online. Please consider updating the OS." -circle "red"
            $showUpdatesURL = $true
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "You have the latest available Monthly Rollup/Cumulative Update installed." -circle "green"
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Verify if you have the latest Monthly Rollup/Cumulative Update installed." -circle "yellow"
        $showUpdatesURL = $true
    }

    if ($showUpdatesURL -and (-not $global:msrdLiveDiag)) {
        if ($global:WinVerMajor -like "*10*") {
            $buildlist = @{
                "14393" = "<a href='https://support.microsoft.com/en-us/help/4000825' target='_blank'>Windows 10 and Windows Server 2016 update history</a>"
                "17763" = "<a href='https://support.microsoft.com/en-us/help/4464619' target='_blank'>Windows 10 and Windows Server 2019 update history</a>"
                "19044" = "<a href='https://support.microsoft.com/en-us/help/5008339' target='_blank'>Windows 10, version 21H2 update history</a>"
                "20348" = "<a href='https://support.microsoft.com/en-us/help/5005454' target='_blank'>Windows Server 2022 update history</a>"
                "22000" = "<a href='https://support.microsoft.com/en-us/help/5006099' target='_blank'>Windows 11, version 21H2 update history</a>"
                "22621" = "<a href='https://support.microsoft.com/en-us/help/5018680' target='_blank'>Windows 11, version 22H2 update history</a>"
                "22631" = "<a href='https://support.microsoft.com/en-us/help/5031682' target='_blank'>Windows 11, version 23H2 update history</a>"
            }

            foreach ($buildver in $buildlist.GetEnumerator()) {
                $buildnr = $buildver.Key
                $PatchURL = $buildver.Value

                if ($global:WinVerBuild -like "*$buildnr*") {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                    $PatchHistory = "Check $PatchURL for more information on the available updates for this OS build."
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$PatchHistory" -circle "white"
                }
            }
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\' -RegKey 'WUServer' -OptNote 'Computer Policy: Specify intranet Microsoft update service location'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\' -RegKey 'WUStatusServer' -OptNote 'Computer Policy: Specify intranet Microsoft update service location'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\' -RegKey 'NoAutoUpdate' -OptNote 'Computer Policy: Configure Automatic Updates'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\' -RegKey 'AUOptions' -OptNote 'Computer Policy: Configure Automatic Updates'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\' -RegKey 'UseWUServer'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\' -RegKey 'RebootInProgress'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\' -RegKey 'RebootPending'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\' -RegKey 'RebootRequired'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\' -RegKey 'PostRebootReporting'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\' -RegKey 'IsOOBEInProgress'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagWinRMPS {

    #WinRM/PowerShell diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "WinRM / PowerShell"
    $menucatmsg = "System"
    msrdLogDiag $LogLevel.Normal -DiagTag "WinRMPSCheck" -Message $menuitemmsg

    msrdCheckServicePort -service WinRM

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    if (Test-Path ($global:msrdLogDir + $winrmcfgfile)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "WinRM Configuration" -Message2 "(See: <a href='$winrmcfgfile' target='_blank'>WinRM-Config</a>)" -circle "white"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    }

    $servstatus = (Get-CimInstance Win32_Service -Filter "name = 'WinRM'" -ErrorAction SilentlyContinue).State
    if ($servstatus -eq "Running") {
        $ipfilter = Get-Item WSMan:\localhost\Service\IPv4Filter
        if ($ipfilter.Value) {
            $msg3 = $ipfilter.Value
            if ($ipfilter.Value -eq "*") {
                $ipfcircle = "green"
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                $msg3 += " (Expected: *)"; $ipfcircle = "red"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "IPv4Filter" -Message3 "$msg3" -circle $ipfcircle
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "IPv4Filter" -Message3 "Empty value, WinRM will not listen on IPv4." -circle "red"
        }

        $ipfilter = Get-Item WSMan:\localhost\Service\IPv6Filter
        if ($ipfilter.Value) {
            $msg3 = $ipfilter.Value
            if ($ipfilter.Value -eq "*") {
                $ipfcircle = "green"
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                $msg3 += " (Expected: *)"; $ipfcircle = "red"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "IPv6Filter" -Message3 "$msg3" -circle $ipfcircle
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "IPv6Filter" -Message3 "Empty value, WinRM will not listen on IPv6." -circle "red"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    $fwrules5 = (Get-NetFirewallPortFilter -Protocol TCP | Where-Object { $_.localport -eq '5985' } | Get-NetFirewallRule)
    if ($fwrules5.count -eq 0) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for TCP port 5985" -Message2 "not found"
    } else {
        if (Test-Path ($global:msrdLogDir + $fwrfile)) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for TCP port 5985" -Message2 "found (See: <a href='$fwrfile' target='_blank'>FirewallRules</a>)" -circle "white"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for TCP port 5985" -Message2 "found" -circle "white"
        }
    }


    $fwrules6 = (Get-NetFirewallPortFilter -Protocol TCP | Where-Object { $_.localport -eq '5986' } | Get-NetFirewallRule)
    if ($fwrules6.count -eq 0) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for TCP port 5986" -Message2 "not found"
    } else {
        if (Test-Path $fwrfile) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for TCP port 5986" -Message2 "found (See: <a href='$fwrfile' target='_blank'>FirewallRules</a>)" -circle "white"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for TCP port 5986" -Message2 "found" -circle "white"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    if ($script:isDomain) {
        $DSsearch = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
        $DSsearch.filter = "(samaccountname=WinRMRemoteWMIUsers__)"
        try {
            $results = $DSsearch.Findall()
        } catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        }

        if ($results.count -gt 0) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Found $($results.Properties.distinguishedname)" -circle "green"
            if ($results.Properties.grouptype -eq  -2147483644) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "WinRMRemoteWMIUsers__ is a Domain local group." -circle "green"
            } elseif ($results.Properties.grouptype -eq -2147483646) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "WinRMRemoteWMIUsers__ is a Global group." -circle "red"
            } elseif ($results.Properties.grouptype -eq -2147483640) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "WinRMRemoteWMIUsers__ is a Universal group." -circle "red"
            }
            if (get-ciminstance -query "select * from Win32_Group where Name = 'WinRMRemoteWMIUsers__' and Domain = '$env:computername'") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The group WinRMRemoteWMIUsers__ is also present as machine local group." -circle "green"
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The WinRMRemoteWMIUsers__ was not found in the domain."
            if (get-ciminstance -query "select * from Win32_Group where Name = 'WinRMRemoteWMIUsers__' and Domain = '$env:computername'") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The group WinRMRemoteWMIUsers__ is present as machine local group." -circle "green"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "WinRMRemoteWMIUsers__ group was not found as machine local group."
            }
        }
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "This machine is not joined to a domain." -circle "yellow"
        if (get-ciminstance -query "select * from Win32_Group where Name = 'WinRMRemoteWMIUsers__' and Domain = '$env:computername'") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The group WinRMRemoteWMIUsers__ is present as machine local group." -circle "green"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "WinRMRemoteWMIUsers__ group was not found as machine local group."
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\WinRS\' -RegKey 'AllowRemoteShellAccess' -OptNote 'Computer Policy: Allow Remote Shell Access'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters\' -RegKey 'MaxRequestBytes'

    #security protocol
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $secprot = [System.Net.ServicePointManager]::SecurityProtocol
    if ($secprot) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "[Net.ServicePointManager]::SecurityProtocol" -Message2 "$secprot" -circle "white"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "[Net.ServicePointManager]::SecurityProtocol" -Message2 "not found" -circle "white"
    }

    #PowerShell
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    $PSlock = $ExecutionContext.SessionState.LanguageMode
    if ($PSlock -eq "FullLanguage") {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "PowerShell" -Message2 "Running Mode" -Message3 "$PSlock" -circle "green"
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "PowerShell" -Message2 "Running Mode" -Message3 "$PSlock" -circle "red"
    }

    $pssexec = Get-ExecutionPolicy -List
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Execution policies" -circle "no"
    foreach ($entrypss in $pssexec) {
        $mode = $entrypss.ExecutionPolicy
        if ($mode -like "*Undefined*") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($entrypss.Scope)" -Message3 "$mode"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($entrypss.Scope)" -Message3 "$mode" -circle "white"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Modules" -circle "no"

    #PowerShell modules for AVD/W365 deployment management from Source side
    if ($global:msrdSource -and ($global:msrdAVD -or $global:msrdW365)) {
        $instmodulelist = "Az.Accounts", "Az.Resources", "Az.DesktopVirtualization", "Microsoft.RDInfra.RDPowerShell"
        $instmodulelist | ForEach-Object -Process {
            $instmod = Get-InstalledModule -Name $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($instmod) {
                $instmodver = [string]$instmod.Version
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "$instmodver" -circle "white"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
            }
        }
    }

    #Other relevant PowerShell modules
    $modulelist = "PowerShellGet", "PSReadLine"
    $modulelist | ForEach-Object -Process {
        $mod = Get-Module -Name $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if ($mod) {
            $modver = [string]$mod.Version
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "$modver" -circle "white"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion System diag functions


#region AVD/RDS diag functions

Function msrdDiagRedirection {

    #RD Redirection diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Device and Resource Redirection"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "RedirCheck"

    #client side redirections
    if ($global:msrdSource) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableClipboardRedirection' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableClipboardRedirection' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableDriveRedirection' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisablePrinterRedirection' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisablePrinterRedirection' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableWebAuthnRedirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fUsbRedirectionEnableMode' -OptNote 'Computer Policy: Allow RDP redirection of other supported RemoteFX USB devices from this computer'
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

    #host side redirections
    if ($global:msrdTarget) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableAudioCapture' -RegValue '0' -OptNote 'Computer Policy: Allow audio recording redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCam' -RegValue '0' -OptNote 'Computer Policy: Allow audio and video playback redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCameraRedir' -RegValue '0' -OptNote 'Computer Policy: Do not allow video capture redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCcm' -RegValue '0' -OptNote 'Computer Policy: Do not allow COM port redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCdm' -RegValue '0' -OptNote 'Computer Policy: Do not allow drive redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableClip' -RegValue '0' -OptNote 'Computer Policy: Do not allow clipboard redirection'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableClip' -RegValue '0' -OptNote 'User Policy: Do not allow clipboard redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCpm' -RegValue '0' -OptNote 'Computer Policy: Do not allow client printer redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableLPT' -RegValue '0' -OptNote 'Computer Policy: Do not allow LPT port redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisablePNPRedir' -RegValue '0' -OptNote 'Computer Policy: Do not allow supported Plug and Play device redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableWebAuthn' -RegValue '0' -OptNote 'Computer Policy: Do not allow WebAuthn redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableSmartCard' -RegValue '1' -OptNote 'Computer Policy: Do not allow smart card device redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableTimeZoneRedirection' -OptNote 'Computer Policy: Allow time zone redirection'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableTimeZoneRedirection' -OptNote 'User Policy: Allow time zone redirection'

        #unidirectional clipboard redirection
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'CSClipLevel' -OptNote 'Computer Policy: Restrict clipboard transfer from client to server'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'CSClipLevel' -OptNote 'User Policy: Restrict clipboard transfer from client to server'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SCClipLevel' -OptNote 'Computer Policy: Restrict clipboard transfer from server to client'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SCClipLevel' -OptNote 'User Policy: Restrict clipboard transfer from server to client'

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'fEnableSmartCard'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableAudioCapture' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableCam' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableCcm' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableCdm' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableClip' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableCpm' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableLPT' -RegValue '0'

        if ($global:msrdAVD -or $global:msrdW365) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            if ($avdcheck) {
                $listenerregpath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\" + $script:msrdListenervalue + "\"
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fDisableAudioCapture' -RegValue '0'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fDisableCam' -RegValue '0'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fDisableCcm' -RegValue '0'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fDisableCdm' -RegValue '0'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fDisableClip' -RegValue '0'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fDisableCpm' -RegValue '0'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fDisableLPT' -RegValue '0'
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout\' -RegKey 'IgnoreRemoteKeyboardLayout'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System\' -RegKey 'IoEnableSessionZeroAccessCheck' -RegValue '1'
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdTestAVExclusion {
    Param([string]$ExclPath, [array]$ExclValue, $Scope)

    #Antivirus Exclusion diagnostics
    if (Test-Path $ExclPath) {
        if ((Get-Item $ExclPath).Property) {

            $exclComp = Compare-Object -ReferenceObject(@((Get-Item $ExclPath).Property)) -DifferenceObject(@($ExclValue))

            if ($exclComp) {
                $ExtraValues = ($exclComp | Where-Object {$_.SideIndicator -eq '<='}).InputObject
                if ($ExtraValues) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The following values are configured but are not part of the public list of recommended exclusions for $Scope" -circle "no"
                    foreach ($entry in $ExtraValues) {

                        # Get the value type of the specified value
                        $shortPath = $ExclPath.Substring($ExclPath.IndexOf("\") + 1)
                        $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$shortPath")
                        $regType = $regKey.GetValueKind($entry)

                        $value = (Get-ItemProperty -Path $ExclPath -Name $entry).$entry
                        if ($global:msrdLiveDiag) {
                            $msg2 = "[Type: $regType]   Value: $value"
                        } else {
                            $msg2 = "[Type: $regType] &nbsp; Value: $value"
                        }
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$ExclPath\$entry" -Message2 $msg2 -circle "yellow"
                    }
                }
            }
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $ExclPath -Message2 "not found" -circle "white"
    }
}

Function msrdDiagFSLogix {

    #FSLogix diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "FSLogix"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -DiagTag "ProfileCheck" -Message $menuitemmsg

    $cmd = "$env:ProgramFiles\fslogix\apps\frx.exe"

    if (Test-path -path "$env:ProgramFiles\FSLogix\apps") {

        if (Test-Path -path $cmd) {
            $frxverlow = 0
            $frxvermissing = 0
            $cmdout = & $cmd version
            $cmdout | ForEach-Object -Process {
                $fsv1 = $_.Split(":")[0]
                $fsv2 = $_.Split(":")[-1]

                if ($fsv1 -like "*version*") {
                    if ($fsv2 -like "*unknown*") {
                        $script:frxverstrip = "unknown"
                    } else {
                        [int64]$script:frxverstrip = $fsv2.Replace(".","")
                    }
                }

                if ($script:frxverstrip -eq "unknown") {
                    $frxvermissing += 1
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $fsv1 -Message2 "unknown" -circle "red"
                } else {
                    if ($script:frxverstrip -lt $latestFSLogixVer) {
                        $frxverlow += 1
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $fsv1 -Message2 "$fsv2" -circle "red"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $fsv1 -Message2 "$fsv2" -circle "green"
                    }
                }
            }

            if ($frxverlow -ne 0) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "You are not using the latest available FSLogix release. Please consider updating. See: $fslogixRef" -circle "red"
            }
            if ($frxvermissing -ne 0) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not retrieve all FSLogix version information" -circle "red"
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "FSLogix seems to be installed, but $cmd could not be found" -col 3 -circle "red"
        }

        #services
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service frxsvc -stopWarning
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service frxccds

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service defragsvc
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service smphost

        #apps & other
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'AdsComputerGroup' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'DriverInterface' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'Font' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'FrxLauncher' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'IEPlugin' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'JavaRuleEditor' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'LoggingEnabled' -RegValue '2'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'LogDir' -RegValue '%ProgramData%\FSLogix\Logs'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'LogFileKeepingPeriod' -RegValue '2'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'LoggingLevel' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'ConfigTool' -RegValue '1'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'Network' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'ODFC' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'Printer' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'ProcessStart' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'Profile' -RegValue '1'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'RuleCompilation' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'RuleEditor' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'Search' -RegValue '1'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'SearchPlugin' -RegValue '0'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Logging\' -RegKey 'Service' -RegValue '0'

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Apps\' -RegKey 'CleanupInvalidSessions' -RegValue '1'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Apps\' -RegKey 'RoamRecycleBin'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Apps\' -RegKey 'RoamSearch'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Apps\' -RegKey 'VHDCompactDisk'

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -RegKey 'SpecialRoamingOverrideAllowed'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\' -RegKey 'DisablePersonalDirChange' -addWarning
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters\' -RegKey 'CloudKerberosTicketRetrievalEnabled' -OptNote 'Computer Policy: Allow retrieving the Microsoft Entra Kerberos Ticket Granting Ticket during logon'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters\' -RegKey 'SupportedEncryptionTypes' -OptNote 'Computer Policy: Network security: Configure encryption types allowed for Kerberos' '' -addWarning -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\AzureADAccount\' -RegKey 'LoadCredKeyFromProfile'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters\' -RegKey 'CloudKerberosTicketRetrievalEnabled' -OptNote 'Computer Policy: Allow retrieving the Microsoft Entra Kerberos Ticket Granting Ticket during logon'


        #profile container
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if (Test-Path -Path ($global:msrdLogDir + $fslogixfolder) -PathType Container) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Profile container</b>" -Message2 "(See: <a href='$fslogixfolder' target='_blank'>FSLogix logs</a>)"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>Profile container</b>" -circle "no"
        }

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'Enabled' -RegValue '1'

        if (!(msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "Enabled")) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "FSLogix <span style='color: blue'>Profile</span> Container 'Enabled' reg key <span style='color: brown'>not found</span>. Profile Container is not enabled." -circle "white"
        }

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "VHDLocations") {
            $pvhd = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\FSLogix\Profiles\" -name "VHDLocations"

            $var1P = $pvhd -split ";"
            $var2P = foreach ($varItemP in $var1P) {
                        if ($varItemP -like "AccountName=*") { $varItemP = "AccountName=xxxxxxxxxxxxxxxx"; $varItemP }
                        elseif ($varItemP -like "AccountKey=*") { $varItemP = "AccountKey=xxxxxxxxxxxxxxxx"; $varItemP }
                        else { $varItemP }
                    }
            $var3P = $var2P -join ";"
            $pvhd = $var3P

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "HKLM:\SOFTWARE\FSLogix\Profiles\<span style='color: blue'>VHDLocations</span>" -Message2 "$pvhd" -circle "white"

            $pconPath = $pvhd.split("\")[2]
            if ($pconPath) {
                $pconout = msrdTestTCP $pconPath 445
                if ($pconout[0] -eq "True") {
                    if ($pconout[1]) {
                        $pconip = $pconout[1]
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test for Profile storage location '$pconPath' ($pconip)" -Message2 "TCP 445: <span style='color: green'>Reachable</span>" -circle "green"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test for Profile storage location '$pconPath'" -Message2 "TCP 445: <span style='color: green'>Reachable</span>" -circle "green"
                    }
                }
                if ($pconout.PingSucceeded) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test for Profile storage location '$pconPath'" -Message2 "TCP 445: <span style='color: red'>Not reachable</span>" -circle "red"
                }
            }
        } else {
            if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "Enabled") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "HKLM:\SOFTWARE\FSLogix\Profiles\<span style='color: blue'>VHDLocations</span>" -Message2 "not found" -circle "red"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "HKLM:\SOFTWARE\FSLogix\Profiles\<span style='color: blue'>VHDLocations</span>" -Message2 "not found"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'CCDLocations' -skipValue

        if ((msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "VHDLocations") -and (msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "CCDLocations")) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Both Profile VHDLocations and Profile Cloud Cache CCDLocations reg keys are present. If you want to use Profile Cloud Cache, remove any setting for Profile 'VHDLocations'. See: $cloudcacheRef" -circle "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        }

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'ConcurrentUserSessions' -RegValue '0' -OptNote 'Computer Policy: Allow concurrent user sessions'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'DeleteLocalProfileWhenVHDShouldApply' -RegValue '1' -OptNote 'Computer Policy: Delete local profile when FSLogix Profile should apply'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'FlipFlopProfileDirectoryName' -RegValue '1' -OptNote 'Computer Policy: Swap directory name components'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'InstallAppxPackages'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'LockedRetryCount' -RegValue '3'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'LockedRetryInterval' -RegValue '15'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'NoProfileContainingFolder' -RegValue '0' -OptNote 'Computer Policy: No containing folder'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'OutlookCachedMode' -OptNote 'Computer Policy: Set Outlook cached mode on successful container attach'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'ProfileType' -RegValue '0' -OptNote 'Computer Policy: Profile type'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'ReAttachIntervalSeconds' -RegValue '15'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'ReAttachRetryCount' -RegValue '3'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'RebootOnUserLogoff' -RegValue '0' -OptNote 'Computer Policy: Reboot computer when user logs off'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'RedirectType' -RegValue '2'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'RedirXMLSourceFolder' -OptNote 'Computer Policy: Provide RedirXML file to customize redirections'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'RoamSearch'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'ShutdownOnUserLogoff' -RegValue '0' -OptNote 'Computer Policy: Shutdown computer when user logs off'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'SizeInMBs' -RegValue '30000' -OptNote 'Computer Policy: Size in MBs'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'VolumeType' -RegValue 'VHDX' -OptNote 'Computer Policy: Virtual disk type'

        #office container
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>Office container</b>" -circle "no"

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'Enabled'

        if (!(msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -value "Enabled")) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "FSLogix <span style='color: blue'>Office</span> Container 'Enabled' reg key <span style='color: brown'>not found</span>. Office Container is not enabled." -circle "white"
        }

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -value "VHDLocations") {
            $ovhd = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -name "VHDLocations"

            $var1O = $ovhd -split ";"
            $var2O = foreach ($varItemO in $var1O) {
                        if ($varItemO -like "AccountName=*") { $varItemO = "AccountName=xxxxxxxxxxxxxxxx"; $varItemO }
                        elseif ($varItemO -like "AccountKey=*") { $varItemO = "AccountKey=xxxxxxxxxxxxxxxx"; $varItemO }
                        else { $varItemO }
                    }
            $var3O = $var2O -join ";"
            $ovhd = $var3O

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\<span style='color: blue'>VHDLocations</span>" -Message2 "$ovhd" -circle "white"

            $oconPath = $ovhd.split("\")[2]
            if ($oconPath) {
                $oconout = msrdTestTCP $oconPath 445
                if ($oconout[0] -eq "True") {
                    if ($oconout[1]) {
                        $oconip = $oconout[1]
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test for ODFC storage location '$oconPath - $oconip'" -Message2 "TCP 445: Reachable" -circle "green"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test for ODFC storage location '$oconPath'" -Message2 "TCP 445: Reachable" -circle "green"
                    }
                }
                if ($oconout.PingSucceeded) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Connection test for ODFC storage location '$oconPath'" -Message2 "TCP 445: Not reachable" -circle "red"
                }
            }
        } else {
            if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -value "Enabled") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\<span style='color: blue'>VHDLocations</span>" -Message2 "not found" -circle "red"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\<span style='color: blue'>VHDLocations</span>" -Message2 "not found"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'CCDLocations' -skipValue

        if ((msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -value "VHDLocations") -and (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -value "CCDLocations")) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Both Office VHDLocations and Office Cloud Cache CCDLocations reg keys are present. If you want to use Office Cloud Cache, remove any setting for Office 'VHDLocations'. See: $cloudcacheRef" -circle "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        }

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'IncludeOfficeActivation' -OptNote 'Computer Policy: Include Office activation data in container'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'DeleteLocalProfileWhenVHDShouldApply' -RegValue '1' -OptNote 'Computer Policy: Delete local profile when FSLogix Profile should apply'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'FlipFlopProfileDirectoryName' -RegValue '1' -OptNote 'Computer Policy: Swap directory name components'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'NoProfileContainingFolder' -RegValue '0' -OptNote 'Computer Policy: No containing folder'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'OutlookCachedMode' -OptNote 'Computer Policy: Set Outlook cached mode on successful container attach'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'RoamSearch'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'SizeInMBs' -RegValue '30000' -OptNote 'Computer Policy: Size in MBs'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'VHDAccessMode' -OptNote 'Computer Policy: VHD access type'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'VolumeType' -RegValue 'VHDX' -OptNote 'Computer Policy: Virtual dksik type'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\outlook\ost\' -RegKey 'NoOST' -OptNote 'Computer Policy: Do not allow an OST file to be created'

        #AV exclusions
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if (Test-Path ($global:msrdLogDir + $regDefExclFile)) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Windows Defender antivirus exclusions for FSLogix</b> ($avexRef)" -Message2 "(See: <a href='$regDefExclFile' target='_blank'>Defender Exclusions</a>)" -circle "white"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>Windows Defender antivirus exclusions for FSLogix</b> ($avexRef)" -circle "no"
        }

        #building search array
        $vhdKey = "VHDLocations"
        $pVHDpath = "HKLM:\SOFTWARE\FSLogix\Profiles\"
        $pPathValue = msrdTestRegistryValue -path $pVHDpath -value $vhdKey
        $oVHDpath = "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\"
        $oPathValue = msrdTestRegistryValue -path $oVHDpath -value $vhdKey
        $keyExtensions = @(
            "\*\*.VHD",
            "\*\*.VHD.lock",
            "\*\*.VHD.meta",
            "\*\*.VHD.metadata",
            "\*\*.VHDX",
            "\*\*.VHDX.lock",
            "\*\*.VHDX.meta",
            "\*\*.VHDX.metadata"
        )

        $avRec = @("%TEMP%\*\*.VHD","%TEMP%\*\*.VHDX","%Windir%\TEMP\*\*.VHD","%Windir%\TEMP\*\*.VHDX")
        $ccdRec = @("%ProgramData%\FSLogix\Cache\*","%ProgramData%\FSLogix\Proxy\*")

        $keyArray = @()
        if ($pPathValue) {
            $pkey = (Get-ItemPropertyValue -Path $pVHDpath -name $vhdKey).replace("`n","")
            foreach ($extension in $keyExtensions) {
                $keyArray += ($pkey + $extension)
            }

            if ($oPathValue -and ($oPathValue -ne $pPathValue)) {
                $okey = (Get-ItemPropertyValue -Path $oVHDpath -name $vhdKey).replace("`n","")
				foreach ($extension in $keyExtensions) {
					$keyArray += ($okey + $extension)
				}
            } elseif (-not $oPathValue) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$vhdKey for Office container is not set." -circle "white"
            }
        } else {
            if ($oPathValue) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$vhdKey for Profiles container is not set." -circle "white"
                $okey = (Get-ItemPropertyValue -Path $oVHDpath -name $vhdKey).replace("`n","")
				foreach ($extension in $keyExtensions) {
					$keyArray += ($okey + $extension)
				}
            } else {
				msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$vhdKey for both Profile and Office container are not set." -circle "white"
			}
        }

        $ccdVHDkey = "CCDLocations"
        if (msrdTestRegistryValue -path $pVHDpath -value $ccdVHDkey) {
            $ccdkey = $True
        } else {
            $ccdkey = $false
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Cloud Cache is not enabled." -circle "white"
        }

        $recAVexclusionsPaths = $avRec + $keyArray + $ccdRec

        #checking exclusions
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        if (-not $global:msrdLiveDiag) { $lconf = "<span style='color: blue'>(local config)</span>" } else { $lconf = "(local config)" }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows Defender Paths exclusions $lconf" -circle "no"
        foreach ($item in $recAVexclusionsPaths) {
            $islocal = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths\" -value $item
            $isgpo = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths\" -value $item
            if ((-not $ccdkey) -and ($ccdRec -contains $item)) {
				$avcircle = "white" #override warning
			} elseif (-not $islocal -and -not $isgpo) {
                $avcircle = "red"
            } elseif (-not $islocal -or -not $isgpo) {
				$avcircle = "white" #override warning
            }
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths\' -RegKey $item -RegValue '0' -warnMissing -warnColor $avcircle
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdTestAVExclusion -ExclPath "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths" -ExclValue $recAVexclusionsPaths -Scope "FSLogix" -color "yellow"
        
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if (-not $global:msrdLiveDiag) { $pconf = "<span style='color: blue'>(policy config)</span>" } else { $pconf = "(policy config)" }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows Defender Paths exclusions $pconf" -circle "no"
        foreach ($item in $recAVexclusionsPaths) {
            $islocal = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths\" -value $item
            $isgpo = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths\" -value $item
            if ((-not $ccdkey) -and ($ccdRec -contains $item)) {
				$avcircle = "white" #override warning
			} elseif (-not $islocal -and -not $isgpo) {
                $avcircle = "red"
            } elseif (-not $islocal -or -not $isgpo) {
				$avcircle = "white" #override warning
            }
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths\' -RegKey $item -RegValue '0' -warnMissing -warnColor $avcircle
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdTestAVExclusion -ExclPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" -ExclValue $recAVexclusionsPaths -Scope "FSLogix" -color "yellow"
        
        #Java
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>Java installation(s)</b>" -circle "no"

        $fsjava = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Java%' and (Vendor like '%Oracle%' or Vendor like '%Microsoft%' or Vendor like '%FSLogix%')" -ErrorAction SilentlyContinue | Select-Object Name, Vendor, Version
        if ($fsjava) {
            foreach ($fsj in $fsjava) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($fsj.Name) ($($fsj.Vendor))" -Message3 "$($fsj.Version)" -circle "white"
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Java installation(s) not found"
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "FSLogix installation <span style='color: brown'>not found</span>."
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagMultimedia {

    #Multimedia diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Multimedia"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "MultiMedCheck"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows Features" -circle "no"

    $mmFeatureList = "MediaPlayback", "WindowsMediaPlayer"
    foreach ($mmf in $mmFeatureList) {
        $mmFeature = Get-WindowsOptionalFeature -Online -FeatureName "$mmf" -ErrorAction Continue 2>>$global:msrdErrorLogFile
        if ($mmFeature) {
            if ($mmFeature.State -eq "Enabled") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($mmFeature.DisplayName)" -Message3 "$($mmFeature.State)" -circle "green"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($mmFeature.DisplayName)" -Message3 "$($mmFeature.State)" -circle "white"
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$mmf" -Message3 "not found" -circle "yellow"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\' -RegKey 'Value' -RegValue 'Allow' -OptNote 'Microphone access - general'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\NonPackaged\' -RegKey 'Value' -RegValue 'Allow' -OptNote 'Microphone access - desktop apps'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\' -RegKey 'Value' -RegValue 'Allow' -OptNote 'Camera access - general'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\NonPackaged\' -RegKey 'Value' -RegValue 'Allow' -OptNote 'Camera access - desktop apps'

    if ($script:registeredBrowsers -like "*Edge*") {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'AudioCaptureAllowed' -RegValue '1' -OptNote 'Computer Policy: Allow or block audio capture'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'AudioCaptureAllowed' -RegValue '1' -OptNote 'User Policy: Allow or block audio capture'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'VideoCaptureAllowed' -RegValue '1' -OptNote 'Computer Policy: Allow or block video capture'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'VideoCaptureAllowed' -RegValue '1' -OptNote 'User Policy: Allow or block video capture'
    }

    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableAudioCapture' -RegValue '0' -OptNote 'Computer Policy: Allow audio recording redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCam' -RegValue '0' -OptNote 'Computer Policy: Allow audio and video playback redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCameraRedir' -RegValue '0' -OptNote 'Computer Policy: Do not allow video capture redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableCam' -RegValue '0'
        if ($global:msrdAVD -or $global:msrdW365) {
            if ($script:msrdListenervalue) {
                msrdCheckRegKeyValue ('HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' + $script:msrdListenervalue + '\') -RegKey 'fDisableCam' -RegValue '0'
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Active AVD listener configuration not found" -circle "red"
            }
        }
    }

    if ($global:msrdAVD -or $global:msrdW365) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if ($script:RDClient) {
            msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\MMR\' -RegKey 'AllowCallRedirectionAllSites'
            msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\MSRDC\FeatureFlags\' -RegKey 'EnableMsMmrDVCPlugin'
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        }

        function msrdCheckVCRInstall {
            param ( [switch]$noMMRinst )

            $instreg = @("hklm:\software\microsoft\windows\currentversion\uninstall\*", "hklm:\software\wow6432node\microsoft\windows\currentversion\uninstall\*")
            $instfound = $false
            $reqVCRfound = 0
            foreach ($instkey in $instreg) {
                $vcrinst = Get-ItemProperty $instkey | Where-Object { $_.DisplayName -like "*Microsoft Visual C++*Redistributable*" } -ErrorAction SilentlyContinue | Select-Object DisplayName, DisplayVersion
                if ($vcrinst) {
                    $instfound = $true
                    foreach ($vcr in $vcrinst) {
                        $reqVCR = 0
                        $regex = "(?<!@{DisplayName=}).*?(?=\s*-\s*[^\-]*$)"
                        $vcrdn = [regex]::Match($vcr.DisplayName.ToString(), $regex).Value.Trim()
                        $vcrVer = $vcr.DisplayVersion

                        # Split the versions into their components
                        $minverComponents = $minVCRverMMR -split '\.'
                        $versionToCheckComponents = $vcrVer -split '\.'

                        for ($i = 0; $i -lt $minverComponents.Count; $i++) {
                            $minComponent = [int]$minverComponents[$i]
                            $checkComponent = [int]$versionToCheckComponents[$i]

                            if ($minComponent -gt $checkComponent) {
                                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                                $circle = "yellow"
                                break
                            } elseif ($minComponent -eq $checkComponent) {
                                $circle = "green"
                                $reqVCR++
                            } else {
                                $circle = "green"
                                $reqVCR = 4
                                break
                            }
                        }
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $vcrdn -Message2 $vcrVer -circle $circle
                        if ($reqVCR -eq 4) { $reqVCRfound += 1 }
                    }
                }
            }

            if ($instfound) {
                if ($reqVCRfound -eq 0) {
                    if ($global:msrdLiveDiag) {
                        $vcrmsg = "The Microsoft Visual C++ Redistributable installation does not meet the minimum required version for AVD Multimedia Redirection. Please consider updating."
                    } else {
                        $vcrmsg = "The Microsoft Visual C++ Redistributable installation does not meet the minimum required version for AVD Multimedia Redirection. Please consider updating. See: $mmrReqRef"
                    }
                    $vcrcircle = "red"
                } else {
                    $vcrmsg = "The Microsoft Visual C++ Redistributable installation meets the minimum required version for AVD Multimedia Redirection."
                    $vcrcircle = "green"
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Col 3 -Message $vcrmsg -Circle $vcrcircle
            }

            if (-not $instfound) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                $novcrmsg = "Microsoft Visual C++ Redistributable installation not found. AVD Multimedia Redirection requirements are not met."
                if ($noMMRinst) { $noMMRcircle = "yellow" } else { $noMMRcircle = "red" }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Col 3 -Message $novcrmsg -Circle $noMMRcircle
            }
        }

        if ($global:msrdSource) { msrdCheckVCRInstall -noMMRinst }

        if ($global:msrdTarget) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            if (Test-Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader') {

                $path= "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
                if (Test-Path $path) {
                    $MMRver = (Get-ChildItem -Path $path -ErrorAction Continue 2>>$global:msrdErrorLogFile | Get-ItemProperty | Select-Object DisplayName, DisplayVersion | Where-Object DisplayName -like "Remote Desktop Multimedia*").DisplayVersion
                    if ($MMRver) {
                        # Split the versions into their components
                        $latestverComponents = $latestMMRver -split '\.'
                        $versionToCheckComponents = $MMRver -split '\.'

                        # Ensure that both versions have the same number of components
                        if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Version number mismatch (latest version: $latestMMRver / current version: $MMRver)." -circle $circle
                        } else {
                            $isNewer = $false
                            for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                                $latestComponent = [int]$latestverComponents[$i]
                                $checkComponent = [int]$versionToCheckComponents[$i]

                                if ($latestComponent -gt $checkComponent) {
                                    $isNewer = $true
                                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                                    break
                                } else {
                                    $circle = "green"
                                }
                            }
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Multimedia Redirection Service installation found" -Message2 "$MMRver" -circle $circle

                            if ($isNewer) {
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Older Remote Desktop Multimedia Redirection Service version found installed on this machine. Please consider updating. See: $mmrRef" -circle "red"
                            }
                        }
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop Multimedia Redirection Service installation <span style='color: brown'>not found</span>."
                        $MMRver = "N/A"
                    }
                } else {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Error retrieving Remote Desktop Multimedia Redirection Service information" -circle "red"
                    $MMRver = "N/A"
                }

                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                if ($MMRver -eq "N/A") { msrdCheckVCRInstall -noMMRinst } else { msrdCheckVCRInstall }

                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Google\Chrome\' -RegKey 'ExtensionSettings'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'ExtensionSettings'

            } else {
                if ($global:msrdTarget) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
                }
            }
        }

        # Check if cmd.exe is blocked by AppLocker
        $blockedApps = Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" -MaxEvents 1000 -ErrorAction SilentlyContinue | Where-Object { $_.Message -match "Denied" -and $_.Message -match "cmd.exe" }

        if ($blockedApps) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "cmd.exe is being blocked by AppLocker. Multimedia redirection won't work as expected if cmd.exe is blocked." -circle "red"
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagQA {

    #Quick Assist diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Quick Assist / Remote Help"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "QACheck"

    #quick assist
    $qa = Get-AppxPackage -Name "MicrosoftCorporationII.QuickAssist" -ErrorAction SilentlyContinue | Select-Object Name, Version, InstallLocation

    if ($qa) {
        $QAver = $qa.Version

        # Split the versions into their components
        $latestverComponents = $latestQAver -split '\.'
        $versionToCheckComponents = $QAver -split '\.'

        # Ensure that both versions have the same number of components
        if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Quick Assist version number mismatch (latest version: $latestQAver / current version: $QAver)." -circle $circle
        } else {
            $isNewer = $false
            for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                $latestComponent = [int]$latestverComponents[$i]
                $checkComponent = [int]$versionToCheckComponents[$i]

                if ($latestComponent -gt $checkComponent) {
                    $isNewer = $true
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                    break
                } else {
                    $circle = "green"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Quick Assist ($($qa.Name))" -Message2 "$($qa.version) (Installed on: $(msrdGetAppxInstallationDate 'MicrosoftCorporationII.QuickAssist'))" -circle $circle
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$($qa.InstallLocation)" -circle "white"

            if ($isNewer) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Quick Assist version is installed on this machine. Please consider updating." -circle "red"
            }
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Quick Assist installation <span style='color: brown'>not found</span>."
    }

    #remote help
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    $rh = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Remote Help*"}

    if ($rh) {
        $RHver = $rh.DisplayVersion

        # Split the versions into their components
        $newVerComponents = $latestRHver -split '\.'
        $installedVerComponents = $RHver -split '\.'

        # Ensure that both versions have the same number of components
        if ($newVerComponents.Count -ne $installedVerComponents.Count) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Help version number mismatch (latest version: $latestRHver / current version: $RHver)." -circle $circle
        } else {
            $isNewer = $false
            for ($i = 0; $i -lt $newVerComponents.Count; $i++) {
                $newComponent = [int]$newVerComponents[$i]
                $installedComponent = [int]$installedVerComponents[$i]
                if ($newComponent -gt $installedComponent) {
                    $isNewer = $true
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                    break
                } elseif ($newComponent -lt $installedComponent) {
                    $circle = "green"
                    break
                }else {
                    $circle = "green"
                }
            }

            if ($rh.InstallLocation) {
                $rhloc = $rh.InstallLocation
            } elseif (Test-Path -Path "$env:ProgramFiles\Remote Help\RemoteHelp.exe") {
			    $rhloc = "$env:ProgramFiles\Remote Help\RemoteHelp.exe"
		    } else {
			    $rhloc = "N/A"
		    }

            $RHdate = $rh.InstallDate
            $RHdate = [datetime]::ParseExact($RHdate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Help" -Message2 "$($rh.DisplayVersion) (Installed on: $RHdate)" -circle $circle
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$rhloc" -circle "white"

            if ($isNewer) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Remote Help version is installed on this machine. Please consider updating." -circle "red"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckServicePort -service "Remote Help"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Help installation <span style='color: brown'>not found</span>."
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath "HKCU:\SOFTWARE\Microsoft\QuickAssist\" -RegKey "EndpointRH" -RegValue "https://remotehelp.microsoft.com"

    #url checks in case either QA or RH are present
    if ($qa -or $rh) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Required Endpoints" -circle "no"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Shared by both Quick Assist and Remote Help" -circle "no"
        $QARHurls = [Ordered]@{
            "aria.microsoft.com" = @()
            "events.data.microsoft.com" = @(443)
            "flightproxy.skype.com" = @()
            "monitor.azure.com" = @()
            "registrar.skype.com" = @()
            "support.services.microsoft.com" = @()
            "trouter.skype.com" = @()
            "aadcdn.msauth.net" = @(443)
            "edge.skype.com" = @(443)
            "login.microsoftonline.com" = @(443)
            "remoteassistanceprodacs.communication.azure.com" = @(443)
        }
        msrdReqURLCheck -urls $QARHurls

        if ($qa) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Quick Assist specific" -circle "no"
            $QAurls = [Ordered]@{
                "remoteassistance.support.services.microsoft.com" = @(443)
                "cc.skype.com" = @()
                "live.com" = @(443)
                "turn.azure.com" = @(443)
            }
            msrdReqURLCheck -urls $QAurls
        }

        if ($rh) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Help specific" -circle "no"
            $RHurls = [Ordered]@{
                "aadcdn.msftauth.net" = @(443)
                "graph.microsoft.com" = @(443)
                "alcdn.msauth.net" = @(443)
                "wcpstatic.microsoft.com" = @(443)
                "remotehelp.microsoft.com" = @(443)
                "trouter.teams.microsoft.com" = @()
                "trouter.communication.microsoft.com" = @()
            }
            msrdReqURLCheck -urls $RHurls

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Help specific for web pubsub" -circle "no"
            $RHurlsWebPubsub = [Ordered]@{
                "webpubsub.azure.com" = @()
                "AMSUA0101-RemoteAssistService-pubsub.webpubsub.azure.com" = @(443)
            }
            msrdReqURLCheck -urls $RHurlsWebPubsub

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Help specific for GCC" -circle "no"
            $RHurlsGCC = [Ordered]@{
                "remoteassistanceweb-gcc.usgov.communication.azure.us" = @(443)
                "gcc.remotehelp.microsoft.com" = @(443)
                "gcc.relay.remotehelp.microsoft.com" = @()
                "gov.teams.microsoft.us" = @(443)
            }
            msrdReqURLCheck -urls $RHurlsGCC
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Microsoft Edge WebView2 Runtime" -circle "no"
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\' -RegKey 'pv'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\' -RegKey 'pv'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\' -RegKey 'pv'
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagRDPListener {

    #RDP/RD Listener diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "RDP / Listener"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "ListenerCheck"

    if ($global:msrdAVD -or $global:msrdW365) {
        $winOptFeat = Get-WindowsOptionalFeature -Online -FeatureName "AppServerClient" -ErrorAction SilentlyContinue
        if ($winOptFeat) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Windows Feature" -Message2 "$($winOptFeat.DisplayName)" -Message3 "$($winOptFeat.State)" -OptNote "$($winOptFeat.Description)" -circle "green"
        } else {
            if ($global:msrdOSVer -like "*Windows 1*Virtual Desktops*" -or $global:msrdOSVer -like "*Windows 1*multi-session*") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $wfcircle = "red"
            } else {
                $wfcircle = "white"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Windows Feature" -Message2 "AppServerClient" -Message3 "not found" -circle $wfcircle
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    }

    $linkmsg = ""
    if (Test-Path ($global:msrdLogDir + $listenerPermFile)) {
        $linkmsg = "<a href='$listenerPermFile' target='_blank'>Permissions</a>"
    }

    if (Test-Path ($global:msrdLogDir + $machineKeysFile)) {
        if ($linkmsg -ne "") { $linkmsg += " / " }
        $linkmsg += "<a href='$machineKeysFile' target='_blank'>MachineKeys</a>"
    }

    if ($linkmsg -ne "") {
        msrdCheckServicePort -service TermService -tcpports 3389 -udpports 3389 -stopWarning -linkmsg $linkmsg -expectedAccount "NT Authority\NetworkService"
    } else {
        msrdCheckServicePort -service TermService -tcpports 3389 -udpports 3389 -stopWarning -expectedAccount "NT Authority\NetworkService"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service SessionEnv -stopWarning
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service UmRdpService -stopWarning
    
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckServicePort -service CertPropSvc -stopWarning
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service KeyIso -stopWarning
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service CryptSvc -stopWarning

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDenyTSConnections' -RegValue '0' -OptNote 'Computer Policy: Allow users to connect remotely by using Remote Desktop Services'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableAutoReconnect' -OptNote 'Computer Policy: Automatic reconnection'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fPromptForPassword' -OptNote 'Computer Policy: Always prompt for password upon connection'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fSingleSessionPerUser' -OptNote 'Computer Policy: Restrict RDS users to a single RDS session'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxInstanceCount' -OptNote 'Computer Policy: Limit number of connections'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SecurityLayer' -RegValue '2' -OptNote 'Computer Policy: Require use of specific security layer for remote (RDP) connections'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SelectTransport' -RegValue '0' -OptNote 'Computer Policy: Select RDP transport protocols'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'UserAuthentication' -RegValue '1' -OptNote 'Computer Policy: Require user authentication for remote connections by using Network Level Authentication'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'fDenyTSConnections' -RegValue '0'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'fSingleSessionPerUser' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'IgnoreRegUserConfigErrors'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'KeepAliveInterval'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'KeepAliveEnable'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -RegKey 'SelfSignedCertificate'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -RegKey 'SelfSignedCertStore' -RegValue 'Remote Desktop'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'CitrixBackupRdpTcpLoadableProtocolObject' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fEnableWinStation' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'InitialProgram'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MaxInstanceCount' -RegValue '4294967295'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'LoadableProtocol_Object'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'PortNumber' -RegValue '3389'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'SecurityLayer' -RegValue '2'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'SSLCertificateSHA1Hash'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fAllowSecProtocolNegotiation' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MinEncryptionLevel'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'UserAuthentication' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'WebSocketListenerPort' -RegValue '3387'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'WebSocketTlsListenerPort' -RegValue '3392'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'WebSocketURI'

    if ($global:msrdAVD -or $global:msrdW365) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        #checking if multiple AVD listener reg keys are present
        if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs*') {

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            $SxSlisteners = (Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs*').PSChildName
            $SxSlisteners | foreach-object -process {
                if ($_ -ne "rdp-sxs") {
                    msrdCheckRegKeyValue -RegPath ('HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' + $_ + '\') -RegKey 'fEnableWinStation'
                }
            }
        }
        else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "AVD listener (HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs*) reg keys <span style='color: brown'>not found</span>. This machine is either not a AVD VM or the AVD listener is not configured properly." -circle "red"
        }

        #checking for the current AVD listener version and "fReverseConnectMode"
        if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations') {
            if ($script:msrdListenervalue) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>The AVD listener currently in use is: $script:msrdListenervalue</b>"
                msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'SessionDirectoryListener' -RegValue $script:msrdListenervalue
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

                $listenerregpath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\" + $script:msrdListenervalue + "\"
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fReverseConnectMode' -RegValue '1'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'InitialProgram'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'MaxInstanceCount' -RegValue '4294967295'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'SecurityLayer' -RegValue '2'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'SSLCertificateSHA1Hash'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fAllowSecProtocolNegotiation' -RegValue '1'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'MinEncryptionLevel'
                msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'UserAuthentication' -RegValue '1'
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\ReverseConnectionListener' <span style='color: brown'>not found</span>. This machine is either not a AVD VM or the AVD listener is not configured properly." -circle "red"
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations' <span style='color: brown'>not found</span>. This machine is not properly configured for either AVD or RDS connections." -circle "red"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Quota System\' -RegKey 'EnableCpuQuota' -RegValue "1" -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\TSFairShare\Disk\' -RegKey 'EnableFairShare'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\TSFairShare\NetFS\' -RegKey 'EnableFairShare'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagRDSRoles {

    #RDS Roles diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "RDS Roles"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "RolesCheck"

    #$script:foundRDS = (Get-WindowsFeature -Name RDS-* -ErrorAction Continue 2>>$global:msrdErrorLogFile) | Where-Object { $_.InstallState -eq "Installed" }

    Try {
        $script:foundRDS = (Get-WindowsFeature -Name RDS-* -ErrorAction Continue 2>>$global:msrdErrorLogFile) | Where-Object { $_.InstallState -eq "Installed" }
    } Catch {
        #if (-not $global:msrdLiveDiag) {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        #}
        $script:foundRDS = "n/a"
	}

    Function msrdDotNetTrustCheck {
        param([string] $pspath)

        $tcheck = (Get-WebConfiguration -Filter '/system.web/trust' -PSPath "$pspath" -ErrorAction Continue 2>>$global:msrdErrorLogFile).level
        if ($tcheck) {
            if ($tcheck -eq "Full") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$pspath" -Message3 $tcheck -circle "green"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$pspath" -Message3 $tcheck -circle "red"
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$pspath" -Message3 "Error retrieving or value not found" -circle "red"
        }
    }

    #gateway
    if ($script:foundRDS.Name -eq "RDS-GATEWAY") {
        if ((Test-Path ($global:msrdLogDir + $getcapfile)) -and (Test-Path ($global:msrdLogDir + $getrapfile))) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Gateway role</b>" -Message2 "Installed (See: <a href='$getcapfile' target='_blank'>CAP</a> / <a href='$getrapfile' target='_blank'>RAP</a>)" -circle "green"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Gateway role</b>" -Message2 "Installed" -circle "green"
        }
        if ($global:msrdAVD -and $global:msrdTarget) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Having the Remote Desktop Gateway role installed on an AVD host is not supported" -circle "red"
        }

        if ($script:foundRDS.Name -eq "RSAT-RDS-Gateway") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Gateway Tools" -Message2 "Installed" -circle "green"
		} else {
			msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Gateway Tools" -Message2 "not found"
		}

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckServicePort -service TSGateway -udpports 3391 -stopWarning

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "IIS .Net Trust Levels"

        Import-Module WebAdministration

        msrdDotNetTrustCheck "MACHINE/WEBROOT"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST/Default Web Site"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST/Default Web Site/Rpc"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST/Default Web Site/RpcWithCert"

        Remove-Module WebAdministration

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Gateway role" -Message2 "not found"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Gateway\' -RegKey 'SkipMachineNameAttribute'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\TerminalServerGateway\Config\Core\' -RegKey 'EnforceChannelBinding'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\TerminalServerGateway\Config\Core\' -RegKey 'IasTimeout'

    #web access
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    if ($script:foundRDS.Name -eq "RDS-WEB-ACCESS") {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Web Access role</b>" -Message2 "Installed" -circle "green"
        if ($global:msrdAVD -and $global:msrdTarget) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Having the Remote Desktop Web Access role installed on an AVD host is not supported" -circle "red"
        }

        if ($script:foundRDS.Name -eq "Web-WebServer") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Web Server" -Message2 "Installed" -circle "green"
	    } else {
		    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Web Server" -Message2 "not found"
	    }
        if ($script:foundRDS.Name -eq "Web-Mgmt-Console") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "IIS Management Console" -Message2 "Installed" -circle "green"
	    } else {
		    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "IIS Management Console" -Message2 "not found"
	    }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckServicePort -service W3SVC  -stopWarning

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "IIS .Net Trust Levels"

        Import-Module WebAdministration

        msrdDotNetTrustCheck "MACHINE/WEBROOT"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST/Default Web Site"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST/Default Web Site/RDWeb"
        msrdDotNetTrustCheck "MACHINE/WEBROOT/APPHOST/Default Web Site/RDWeb/Pages"

        Remove-Module WebAdministration

        #RDWeb client components
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

        $isWebClientModule = Get-Module -ListAvailable -Name RDWebClientManagement

        if ($isWebClientModule) {
            try {
                $rdwcver = (Get-RDWebClientPackage -ErrorAction SilentlyContinue).Version
                if ($rdwcver) {
                    foreach ($wcver in $rdwcver) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Client" -Message2 "$wcver" -circle "white"
                    }
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Client" -Message2 "not found"
                }
            } catch {
                $failedCommand = $_.InvocationInfo.Line.TrimStart()
                msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Client" -Message2 "not found"
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop Web Client PowerShell prerequisites"

            $rdwcProvs = "NuGet"
            $rdwcProvs | ForEach-Object -Process {
                try {

                    if ($_ -eq "NuGet") {
                        if (!(Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq 'NuGet' } -ErrorAction SilentlyContinue)) {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
                            return
                        }
                    }

                    $rdwcProvVer = [String](Get-PackageProvider -Name $_ -ErrorAction SilentlyContinue).Version
                    if ($rdwcProvVer) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "$rdwcProvVer" -circle "white"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
                    }
                } catch {
                    $failedCommand = $_.InvocationInfo.Line.TrimStart()
                    msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
                }
            }

            $rdwcMods = "PackageManagement", "PowerShellGet"
            $rdwcMods | ForEach-Object -Process {
                try {
                    $rdwcmodver = [String](Get-Module -Name $_ -ErrorAction SilentlyContinue).Version
                    if ($rdwcmodver) {
                        if (($_ -eq "PowerShellGet") -and ($rdwcmodver -eq "1.0.0.1")) {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "$rdwcmodver" -circle "red"
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "This $_ version does not support installing the web client management module" -circle "red"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "$rdwcmodver" -circle "white"
                        }
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
                    }
                } catch {
                    $failedCommand = $_.InvocationInfo.Line.TrimStart()
                    msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
                }
            }

            $rdwcMods = "RDWebClientManagement"
            $rdwcMods | ForEach-Object -Process {
                try {
                    $rdwcmodver = [String](Get-InstalledModule -Name $_ -ErrorAction SilentlyContinue).Version
                    if ($rdwcmodver) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "$rdwcmodver" -circle "white"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
                    }
                } catch {
                    $failedCommand = $_.InvocationInfo.Line.TrimStart()
                    msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$_" -Message3 "not found"
                }
            }

            try {
                $rdwcconfig = Get-RDWebClientDeploymentSetting -ErrorAction SilentlyContinue | Select-Object Name, Value
                if ($rdwcconfig) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop Web Client Deployment Settings"
                    foreach ($wcconfig in $rdwcconfig) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($wcconfig.Name)" -Message3 "$($wcconfig.Value)"
                    }
                } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Client Deployment Settings" -Message2 "not found"
                }
            } catch {
                $failedCommand = $_.InvocationInfo.Line.TrimStart()
                msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Client Deployment Settings" -Message2 "not found"
            }

            try {
                $rdwccert = Get-RDWebClientBrokerCert -ErrorAction SilentlyContinue | Select-Object Subject, Thumbprint, NotAfter
                if ($rdwccert) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop Web Client Broker Certificate"
                    $wcthresholdDate = (Get-Date).AddDays(30)
                    if ($rdwccert.NotAfter) {
                        $wcexpdate = Get-Date ($rdwccert.NotAfter)
                        $wcexpdiff = $wcexpdate - $wcthresholdDate
                        if ($wcexpdiff -lt "30") {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Expires on: $wcexpdate" -Message3 "Subject: $($rdwccert.Subject)" -circle "red"
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Thumbprint: $($rdwccert.Thumbprint)" -circle "red"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Expires on: $wcexpdate" -Message3 "Subject: $($rdwccert.Subject)"
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Thumbprint: $($rdwccert.Thumbprint)"
                        }
                    } else {
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop Web Client Broker Certificate information could not be retrieved" -circle "red"
                    }
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Client Broker Certificate information" -Message2 "not found"
                }
            } catch {
                $failedCommand = $_.InvocationInfo.Line.TrimStart()
                msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Client Broker Certificate information" -Message2 "not found"
            }

        } else {
			msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop Web Client PowerShell management module not found. Skipping further RD Web Client checks."
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Web Access role" -Message2 "not found"
    }

    #broker
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    if ($script:foundRDS.Name -eq "RDS-CONNECTION-BROKER") {
        if (Test-Path ($global:msrdLogDir + $GetRDSFarmDatafile)) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Connection Broker role</b>" -Message2 "Installed (See: <a href='$GetRDSFarmDatafile' target='_blank'>GetRDSFarmData</a>)" -circle "green"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Connection Broker role</b>" -Message2 "Installed" -circle "green"
        }
        if ($global:msrdAVD -and $global:msrdTarget) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Having the Remote Desktop Connection Broker role installed on an AVD host is not supported" -circle "red"
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckServicePort -service Tssdis -stopWarning
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service RDMS -stopWarning
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service TScPubRPC -tcpports 5504 -stopWarning
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service 'MSSQL$MICROSOFT##WID'

        # DB access
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        $HighAvailabilityBroker = Get-RDConnectionBrokerHighAvailability -ErrorAction SilentlyContinue
        If ($null -eq $HighAvailabilityBroker) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The Connection Broker is not configured for High Availability"

            #checking disk sector size for WID considerations
            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            #disk sector size (for RDCB WID)
            $commandOutput = Get-Disk -ErrorAction SilentlyContinue | Get-Partition | Sort-Object -Property DriveLetter | ForEach-Object {
                $partition = $_.DriveLetter
                if ($partition) {
                    Write-Output "Sector info drive $($partition):"
                    fsutil fsinfo sectorinfo "$($partition):"
                }
            }

            $commandOutput | ForEach-Object {
                if ($_ -match "(?<!FileSystemEffective)PhysicalBytesPerSectorForAtomicity|PhysicalBytesPerSectorForPerformance") {
                    # Extract the value after the parameter name
                    $value = $_ -split ':', 2 | Select-Object -Last 1
                    $value = $value.Trim()
                    $parameter = $_ -split ':', 2 | Select-Object -First 1
                    $parameter = $parameter.Trim()
                    # Check if the value is different from 4096
                    if ($value -ne "4096") {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$parameter" -Message3 "$value" -circle "yellow"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$parameter" -Message3 "$value" -circle "green"
                    }
                } elseif ($_ -match "Sector info drive ") {
                  msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -Message "$_" -circle "white"
                }
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device\' -RegKey 'ForcedPhysicalSectorSizeInBytes'

        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The Connection Broker is configured for High Availability"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Client Access Name (Round Robin DNS)" -Message2 $HighAvailabilityBroker.ClientAccessName
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "ActiveManagementServer" -Message2 $HighAvailabilityBroker.ActiveManagementServer
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "DatabaseConnectionString" -Message2 $HighAvailabilityBroker.DatabaseConnectionString
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "DatabaseSecondaryConnectionString" -Message2 $HighAvailabilityBroker.DatabaseSecondaryConnectionString
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "DatabaseFilePath" -Message2 $HighAvailabilityBroker.DatabaseFilePath
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

        # Certificates
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "RDS deployment certificates" -circle "no"
        $rdscert = Get-RDCertificate -ErrorAction Continue 2>>$global:msrdErrorLogFile | Select-Object Role, Level, ExpiresOn, Subject, SubjectAlternateName, Thumbprint
        if ($rdscert) {
            $thresholdDate = (Get-Date).AddDays(30)
            foreach ($cert in $rdscert) {
                $certlvl = $cert.Level
                if ($cert.ExpiresOn) {
                    $expdate = Get-Date ($cert.ExpiresOn)
                    $expdiff = $expdate - $thresholdDate
                    if (($expdiff -lt "30") -or ($certlvl -ne "Trusted")) {
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "$($cert.Role)" -Message2 "$certlvl - Expires on: $expdate" -Message3 "Subject: $($cert.Subject)" -circle "red"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Thumbprint: $($cert.Thumbprint)" -Message3 "SAN: $($cert.SubjectAlternateName)" -circle "red"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "$($cert.Role)" -Message2 "$certlvl - Expires on: $expdate" -Message3 "Subject: $($cert.Subject)"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Thumbprint: $($cert.Thumbprint)" -Message3 "SAN: $($cert.SubjectAlternateName)"
                    }
                } else {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "$($cert.Role)" -Message2 "$certlvl" -circle "red"
                }
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop certificates information not found or could not be retrieved" -circle "red"
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Connection Broker role" -Message2 "not found"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\CentralizedPublishing\' -RegKey 'Redirector'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\CentralizedPublishing\' -RegKey 'RedirectorAlternateAddress'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\CentralizedPublishing\' -RegKey 'Port'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'DeploymentServerName'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Wbem\CIMOM\' -RegKey 'ArbThrottlingEnabled'

    #session host
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    if ($script:foundRDS.Name -eq "RDS-RD-Server") {
        if (Test-Path ($global:msrdLogDir + $gracefile)) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Session Host role</b>" -Message2 "Installed (See: <a href='$gracefile' target='_blank'>GracePeriod</a>)" -circle "green"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Session Host role</b>" -Message2 "Installed" -circle "green"
        }
    } else {
        if ($global:msrdAVD -and ($global:msrdOSVer -like "*Windows*Server*")) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Session Host role" -Message2 "not found" -circle "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "This machine is running a Windows Server OS but the Remote Desktop Session Host role is not installed. This role is required for AVD VMs running Windows Server OS." -circle "red"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Session Host role" -Message2 "not found"
        }
    }

    if ($script:foundRDS.Name -eq "RSAT-RDS-Licensing-Diagnosis-UI") {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Licensing Diagnoser Tools" -Message2 "Installed" -circle "green"
	} else {
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Licensing Diagnoser Tools" -Message2 "not found"
	}

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'CertTemplateName' -OptNote 'Computer Policy: Server authentication certificate template'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SessionDirectoryLocation' -OptNote 'Computer Policy: Configure RD Connection Broker server name'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SessionDirectoryClusterName' -OptNote 'Computer Policy: Configure RD Connection Broker farm name'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'ParticipateInLoadBalancing' -OptNote 'Computer Policy: Use RD Connection Broker load balancing'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SessionDirectoryActive' -OptNote 'Computer Policy: Join RD Connection Broker'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SessionDirectoryExposeServerIP' -OptNote 'Computer Policy: Use IP Address Redirection'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'SessionDirectoryActive'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'TSServerDrainMode' -RegValue '0'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'SessionDirectoryClusterName'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'SessionDirectoryLocation'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'SessionDirectoryRedirectionIP'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'ParticipateInLoadBalancing'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'ServerWeight'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'UvhdEnabled'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings\' -RegKey 'UvhdShareUrl'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\TSAppSrv\VirtualIP\' -RegKey 'EnableVirtualIP' -OptNote 'Computer Policy: Turn on Remote Desktop IP Virtualization'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\TSAppSrv\VirtualIP\' -RegKey 'VirtualMode' -OptNote 'Computer Policy: Turn on Remote Desktop IP Virtualization'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\TSAppSrv\VirtualIP\' -RegKey 'PerApp' -OptNote 'Computer Policy: Turn on Remote Desktop IP Virtualization'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\TSAppSrv\VirtualIP\' -RegKey 'VIPAdapter' -OptNote 'Computer Policy: Select the network adapter to be used for Remote Desktop IP Virtualization'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\TSAppSrv\VirtualIP\' -RegKey 'PromptOnIPLeaseFail' -OptNote 'Computer Policy: Do not use Remote Desktop Session Host server IP address when virtual IP address is not available'

    if ($global:msrdRDS -and $global:msrdTarget) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\WinSock2\Parameters\AppId_Catalog\2C69D9F1\' -RegKey 'AppFullPath'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\WinSock2\Parameters\AppId_Catalog\2C69D9F1\' -RegKey 'PermittedLspCategories'
    }

    #virtualization host
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    if ($script:foundRDS.Name -eq "RDS-Virtualization") {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Virtualization Host role</b>" -Message2 "Installed" -circle "green"

		msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        If ($global:msrdTarget -and ($global:msrdOSVer -like "*Windows*Server*")) {
            $winOptFeat = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -ErrorAction SilentlyContinue
            if ($winOptFeat) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Windows Feature" -Message2 "$($winOptFeat.DisplayName)" -Message3 "$($winOptFeat.State)" -circle "green"
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Windows Feature" -Message2 "Microsoft-Hyper-V" -Message3 "not found" -circle "red"
            }
        }

		msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
		msrdCheckServicePort -service VMMS -stopWarning
    } else {
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Virtualization Host role" -Message2 "not found"
	}

    #license server
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    if ($script:foundRDS.Name -eq "RDS-Licensing") {
        if ((Test-Path ($global:msrdLogDir + $licpakfile)) -and (Test-Path ($global:msrdLogDir + $licoutfile))) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Licensing role</b>" -Message2 "Installed (See: <a href='$licpakfile' target='_blank'>LicenseKeyPacks.html</a> / <a href='$licoutfile' target='_blank'>IssuedLicenses.html</a>)" -circle "green"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Remote Desktop Licensing role</b>" -Message2 "Installed" -circle "green"
        }

        if ($script:foundRDS.Name -eq "RDS-Licensing-UI") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Licensing Tools" -Message2 "Installed" -circle "green"
		} else {
			msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Licensing Tools" -Message2 "not found"
		}

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckServicePort -service TermServLicensing -stopWarning

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        $licactivation = (Invoke-CimMethod -ClassName Win32_TSLicenseServer -MethodName GetActivationStatus -ErrorAction Continue 2>>$global:msrdErrorLogFile).ActivationStatus
        if ($null -ne $licactivation) {
            if ($licactivation -eq 0) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop license server activation status" -Message2 "Activated" -circle "green"
            } elseif ($licactivation -eq 1) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop license server activation status" -Message2 "Not activated" -circle "red"
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop license server activation status: An unknown error occurred. It is not known whether the Remote Desktop license server is activated" -circle "red"
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop license server activation status could not be retrieved" -circle "red"
        }

        $licTSLSG = (Invoke-CimMethod -ClassName Win32_TSLicenseServer -MethodName IsLSinTSLSGroup -ErrorAction Continue 2>>$global:msrdErrorLogFile).IsMember
        if ($licTSLSG) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop license server is a member of the Terminal Server License Servers group in the domain." -circle "green"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop license server is either not a member of the Terminal Server License Servers group in the domain, not joined to a domain or the domain cannot be contacted." -circle "red"
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fSecureLicensing' -OptNote 'Computer Policy: License server security group'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fPreventLicenseUpgrade' -OptNote 'Computer Policy: Prevent license upgrade'

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Licensing role" -Message2 "not found"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagRDClient {

    #RD Client diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Remote Desktop Clients"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "RDCCheck"

    #Remote Desktop Connection client (MSTSC)
    $mstscVer = (Get-Item $env:windir\System32\mstsc.exe).VersionInfo.ProductVersion
    if ($mstscVer) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Connection client (MSTSC)" -Message2 "$mstscVer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$env:windir\System32\mstsc.exe"
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Connection client (MSTSC)" -Message2 "not found" -circle "red"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Workspaces\' -RegKey 'DefaultConnectionURL'

    #Remote Desktop client (MSRDC)
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    if ($script:RDClient) {
        foreach ($RDCitem in $script:RDClient) {
            $RDCver = $RDCitem.DisplayVersion
            if ($RDCitem.InstallDate) {
                $RDCdate = $RDCitem.InstallDate
                $RDCdate = [datetime]::ParseExact($RDCdate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
            } else {
                $RDCdate = "N/A"
            }
            if ($RDCitem.InstallLocation) { $RDCloc = $RDCitem.InstallLocation } else { $RDCloc = "N/A" }

            # Split the versions into their components
            $latestverComponents = $latestRDCver -split '\.'
            $versionToCheckComponents = $RDCver -split '\.'

            # Ensure that both versions have the same number of components
            if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Version number mismatch (latest version: $latestRDCver / current version: $RDCver)." -circle $circle
            } else {
                $isNewer = $false
                for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                    $latestComponent = [int]$latestverComponents[$i]
                    $checkComponent = [int]$versionToCheckComponents[$i]

                    if ($latestComponent -gt $checkComponent) {
                        $isNewer = $true
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                        break
                    } else {
                        $circle = "green"
                    }
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop client (MSRDC)" -Message2 "$RDCver (Installed on: $RDCdate)" -circle $circle
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$RDCloc"

                if ($isNewer) {
                    if ($global:msrdLiveDiag) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older (no longer supported) Remote Desktop client (MSRDC) version is installed on this machine. Please update to the latest Public or Insider version." -circle "red"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older (no longer supported) Remote Desktop client (MSRDC) version is installed on this machine. Please update to the latest Public or Insider version. See: $msrdcRef" -circle "red"
                    }
                }
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        }

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\MSRDC\Policies\' -RegKey 'AutomaticUpdates'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\MSRDC\Policies\' -RegKey 'ReleaseRing' -addWarning
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\MSRDC\Settings\' -RegKey 'SuppressAppInstalledFromStoreError'

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop client (MSRDC)" -Message2 "not found"
    }

    #Azure Virtual Desktop Store app
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $avdStoreApp = Get-AppxPackage -name MicrosoftCorporationII.AzureVirtualDesktopClient -ErrorAction SilentlyContinue
    $avdStoreAppVer = $avdStoreApp.Version
    if ($avdStoreApp.InstallLocation) { $avdStoreAppLoc = $avdStoreApp.InstallLocation } else { $avdStoreAppLoc = "N/A" }

    if ($avdStoreApp) {
        # Split the versions into their components
        $latestverComponents = $latestAvdStoreApp -split '\.'
        $versionToCheckComponents = $avdStoreAppVer -split '\.'

        # Ensure that both versions have the same number of components
        if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Version number mismatch (latest version: $latestAvdStoreApp / current version: $avdStoreAppVer)." -circle $circle
        } else {
            $isNewer = $false
            for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                $latestComponent = [int]$latestverComponents[$i]
                $checkComponent = [int]$versionToCheckComponents[$i]

                if ($latestComponent -gt $checkComponent) {
                    $isNewer = $true
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                    break
                } else {
                    $circle = "green"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Azure Virtual Desktop Store app" -Message2 "$avdStoreAppVer (Installed on: $(msrdGetAppxInstallationDate 'MicrosoftCorporationII.AzureVirtualDesktopClient'))" -circle $circle
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$avdStoreAppLoc"

            if ($isNewer) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Azure Virtual Desktop Store app version is installed on this machine. Please consider updating." -circle "red"
            }
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Azure Virtual Desktop Store app" -Message2 "not found"
    }

    #Azure Virtual Desktop HostApp (Store)
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $avdHostApp = Get-AppxPackage -name MicrosoftCorporationII.AzureVirtualDesktopHostApp -ErrorAction SilentlyContinue
    $avdHostAppVer = $avdHostApp.Version
    if ($avdHostApp.InstallLocation) { $avdHostAppLoc = $avdHostApp.InstallLocation } else { $avdHostAppLoc = "N/A" }

    if ($avdHostApp) {
        # Split the versions into their components
        $latestverComponents = $latestAvdHostApp -split '\.'
        $versionToCheckComponents = $avdHostAppVer -split '\.'

        # Ensure that both versions have the same number of components
        if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Version number mismatch (latest version: $latestAvdHostApp / current version: $avdHostAppVer)." -circle $circle
        } else {
            $isNewer = $false
            for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                $latestComponent = [int]$latestverComponents[$i]
                $checkComponent = [int]$versionToCheckComponents[$i]

                if ($latestComponent -gt $checkComponent) {
                    $isNewer = $true
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                    break
                } else {
                    $circle = "green"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Azure Virtual Desktop HostApp (Store)" -Message2 "$avdHostAppVer (Installed on: $(msrdGetAppxInstallationDate 'MicrosoftCorporationII.AzureVirtualDesktopHostApp'))" -circle $circle
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$avdHostAppLoc"

            if ($isNewer) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Azure Virtual Desktop HostApp (Store) version is installed on this machine. Please consider updating." -circle "red"
            }
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Azure Virtual Desktop HostApp (Store)" -Message2 "not found"
    }

    #Windows App (Store)
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $w365client = Get-AppxPackage -name MicrosoftCorporationII.Windows365 -ErrorAction SilentlyContinue
    $w365ver = $w365client.Version
    if ($w365client.InstallLocation) { $w365loc = $w365client.InstallLocation } else { $w365loc = "N/A" }

    if ($w365client) {
        # Split the versions into their components
        $latestverComponents = $latestw365ver -split '\.'
        $versionToCheckComponents = $w365ver -split '\.'

        # Ensure that both versions have the same number of components
        if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Version number mismatch (latest version: $latestw365ver / current version: $w365ver)." -circle $circle
        } else {
            $isNewer = $false
            for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                $latestComponent = [int]$latestverComponents[$i]
                $checkComponent = [int]$versionToCheckComponents[$i]

                if ($latestComponent -gt $checkComponent) {
                    $isNewer = $true
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                    break
                } else {
                    $circle = "green"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows App (Store)" -Message2 "$w365ver (Installed on: $(msrdGetAppxInstallationDate 'MicrosoftCorporationII.Windows365'))" -circle $circle
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$w365loc"

            if ($isNewer) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Windows App (Store) version is installed on this machine. Please consider updating." -circle "red"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKCU:\Software\Microsoft\Windows365\' -RegKey 'Environment'
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows App (Store)" -Message2 "not found"
    }

    #Windows App (Web)
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows App (Web)" -circle "no"
    $WAwebclienturls = [Ordered]@{
        "windows.cloud.microsoft" = @()
        "windows365.microsoft.com" = @()
    }
    msrdReqURLCheck -urls $WAwebclienturls

    #Remote Desktop Store app (URDC)
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $StoreClient = Get-AppxPackage -name microsoft.remotedesktop -ErrorAction SilentlyContinue
    $StoreCver = $StoreClient.Version
    $StoreCloc = $StoreClient.InstallLocation

    if ($StoreClient) {
        # Split the versions into their components
        $latestverComponents = $latestStoreCver -split '\.'
        $versionToCheckComponents = $StoreCver -split '\.'

        # Ensure that both versions have the same number of components
        if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Version number mismatch (latest version: $latestStoreCver / current version: $StoreCver)." -circle $circle
        } else {
            $isNewer = $false
            for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                $latestComponent = [int]$latestverComponents[$i]
                $checkComponent = [int]$versionToCheckComponents[$i]

                if ($latestComponent -gt $checkComponent) {
                    $isNewer = $true
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                    break
                } else {
                    $circle = "green"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Store app (URDC)" -Message2 "$StoreCver (Installed on: $(msrdGetAppxInstallationDate 'microsoft.remotedesktop'))" -circle $circle
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$StoreCloc"

            if ($isNewer) {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Remote Desktop Store app (URDC) version is installed on this machine. Please consider updating." -circle "red"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Remote Desktop Store app (URDC) version is installed on this machine. Please consider updating. See: $uwpcRef" -circle "red"
                }
            }
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop Store app (URDC)" -Message2 "not found"
    }

    #RD web client
    if ($global:msrdSource -and ($global:msrdAVD -or $global:msrdW365)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Remote Desktop Web Client for AVD" -circle "no"
        $webclienturls = [Ordered]@{
            "client.wvd.microsoft.com" = @()
            "rdweb.wvd.azure.us" = @()
            "rdweb.wvd.azure.cn" = @()
        }
        msrdReqURLCheck -urls $webclienturls
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableUDPTransport'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'EnableCredSSPSupport'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'RDGClientTransport'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Web browsers registered on this system" -circle "no"
    if ($script:registeredBrowsers.Count -gt 0) {
        $script:registeredBrowsers | ForEach-Object {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 $_
        }
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No registered web browsers found" -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagLicensing {

    #RD Licensing diagnostics
    $global:msrdSetWarning = $false
    msrdLogDiag $LogLevel.Normal -Message "Remote Desktop Licensing" -DiagTag "LicCheck"

    if ($global:msrdSource -and ($global:msrdAVD -or $global:msrdRDS)) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\MSLicensing\HardwareID\' -RegKey 'ClientHWID'

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        $countregValues = @('HKLM:\SOFTWARE\Microsoft\MSLicensing\HardwareID\Store')
        foreach ($vreg in $countregValues) {
            if (Test-Path -Path $vreg) {
                $valueCount = (Get-ItemProperty -Path $vreg | Get-Member -MemberType NoteProperty).Count
                if ($valueCount -eq 1) { $msg = "key" } else { $msg = "keys" }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$vreg" -Message2 "$valueCount LICENSExxx $msg found"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$vreg" -Message2 "No LICENSExxx keys found"
            }
        }
    }

    if ($global:msrdTarget) {
        if (($script:foundRDS.Name -eq "RDS-Licensing") -or ($script:foundRDS.Name -eq "RDS-RD-Server")) {
            if (Test-Path ($global:msrdLogDir + $tslsgroupfile)) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "RD Session Host and/or RD Licensing role(s) detected" -Message2 "(See: <a href='$tslsgroupfile' target='_blank'>TSLSMembership</a>)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            }
        }

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'LicenseServers' -OptNote 'Computer Policy: Use the specified Remote Desktop license servers'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'LicensingMode' -OptNote 'Computer Policy: Set the Remote Desktop licensing mode'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\'-RegKey  'fDisableTerminalServerTooltip' -OptNote 'Computer Policy: Hide notifications about RD Licensing problems that affect the RD Session Host server'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\TermService\Parameters\LicenseServers\' -RegKey 'SpecifiedLicenseServers'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\Licensing Core\' -RegKey 'LicensingMode'

        if ($global:msrdOSVer -like "*Windows Server*") {
            msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\' -RegKey 'X509 Certificate' -skipValue
            msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\' -RegKey 'X509 Certificate ID' -skipValue
            msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\' -RegKey 'X509 Certificate2' -skipValue
            msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\TermServLicensing\Parameters\' -RegKey 'MaxVerPages'
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagTimeLimits {

    #Session Time Limit diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Session Time Limits"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "STLCheck"

    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxIdleTime' -OptNote 'Computer Policy: Set time limit for active but idle RDS sessions'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxIdleTime' -OptNote 'User Policy: Set time limit for active but idle RDS sessions'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxConnectionTime' -OptNote 'Computer Policy: Set time limit for active RDS sessions'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxConnectionTime' -OptNote 'User Policy: Set time limit for active RDS sessions'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxDisconnectionTime' -OptNote 'Computer Policy: Set time limit for disconnected sessions'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'MaxDisconnectionTime' -OptNote 'User Policy: Set time limit for disconnected sessions'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'RemoteAppLogoffTimeLimit' -OptNote 'Computer Policy: Set time limit for logoff of RemoteApp sessions'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'RemoteAppLogoffTimeLimit' -OptNote 'User Policy: Set time limit for logoff of RemoteApp sessions'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fResetBroken' -OptNote 'Computer Policy: End session when time limits are reached'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fResetBroken' -OptNote 'User Policy: End session when time limits are reached'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MaxIdleTime'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MaxConnectionTime'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'MaxDisconnectionTime'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fResetBroken'

    if ($global:msrdAVD -or $global:msrdW365) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        if ($avdcheck) {
            $listenerregpath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\" + $script:msrdListenervalue + "\"
            msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'MaxIdleTime'
            msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'MaxConnectionTime'
            msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'MaxDisconnectionTime'
            msrdCheckRegKeyValue -RegPath $listenerregpath -RegKey 'fResetBroken'
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'InactivityTimeoutSecs' -OptNote 'Computer Policy: Interactive logon: Machine inactivity limit'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop\' -RegKey 'ScreenSaveTimeOut' -OptNote 'User Policy: Screen saver timeout'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\' -RegKey '\AutoDisconnect' -OptNote 'Computer Policy: Microsoft network server: Amount of idle time required before suspending session'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagTeams {

    #Microsoft Teams diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Teams Media Optimization"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "TeamsCheck"

    if ($global:msrdOSVer -like "*Windows 1*") {

        if ($global:msrdSource) {
            msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'IsSwapChainRenderingEnabled'
            msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\Default\AddIns\WebRTC Redirector\' -RegKey 'UseHardwareEncoding'
            msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\Default\AddIns\WebRTC Redirector\' -RegKey 'DisableHWDecoder'
            msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\Default\AddIns\WebRTC Redirector\' -RegKey 'SettingsEnabled'
        }

        if ($global:msrdTarget) {
            if ($avdcheck) {
                #Checking Teams deployment
                $verpath = $msrdUserProfilePath + "\AppData\Roaming\Microsoft\Teams\settings.json"

                if (Test-Path $verpath) {
                    if ($PSVersionTable.PSVersion -like "*5.1*") {
                        $response = Get-Content $verpath -ErrorAction Continue
                        $response = $response -creplace 'enableIpsForCallingContext','enableIPSForCallingContext'
                        $response = $response | ConvertFrom-Json
                        $TeamsVer = $response.version
                        if ($response.ring) { $TeamsRing = $response.ring } else { $TeamsRing = "N/A" }
                        $TeamsEnv = $response.environment
                    } else {
                        $TeamsVer = (Get-Content $verpath -ErrorAction Continue | ConvertFrom-Json -AsHashTable).version
                        $TeamsRing = (Get-Content $verpath -ErrorAction Continue | ConvertFrom-Json -AsHashTable).ring
                        $TeamsEnv = (Get-Content $verpath -ErrorAction Continue | ConvertFrom-Json -AsHashTable).environment
                    }
                } else {
					$TeamsVer = "N/A"
					$TeamsRing = "N/A"
					$TeamsEnv = "N/A"
                }

                #Checking Classic Teams installation info
                $TeamsUserPath = $msrdUserProfilePath + "\AppData\Local\Microsoft\Teams\current\Teams.exe"
                if (Test-Path $TeamsUserPath) {
                    if ($global:msrdW365) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Classic Teams 'per-user' installation <span style='color: blue'>found</span>" -Message2 "$TeamsVer"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$TeamsUserPath"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Ring" -Message2 "$TeamsRing"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Environment" -Message2 "$TeamsEnv"
                    } else {
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Classic Teams 'per-user' installation <span style='color: blue'>found</span>" -Message2 "$TeamsVer" -circle "red"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$TeamsUserPath" -circle "red"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Classic Teams per-user installation only works on personal host pools. If your deployment uses pooled host pools, it is recommended to use per-machine installation instead." -circle "red"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Ring" -Message2 "$TeamsRing"
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Environment" -Message2 "$TeamsEnv"
                    }
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Classic Teams 'per-user' installation for the current user <span style='color: brown'>not found</span>"
                }

                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                $TeamsMachinePath = "${env:ProgramFiles(x86)}\Microsoft\Teams\current\Teams.exe"
                if (Test-Path $TeamsMachinePath) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Classic Teams 'per-machine' installation <span style='color: blue'>found</span>" -Message2 "$TeamsVer"
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$TeamsMachinePath"
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Ring" -Message2 "$TeamsRing"
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Environment" -Message2 "$TeamsEnv"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Classic Teams 'per-machine' installation <span style='color: brown'>not found</span>"
                }

                if ((Test-Path $TeamsUserPath) -or (Test-Path $TeamsMachinePath)) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The classic Teams for VDI will reach end of service on October 1, 2024, and end of availability on July 1, 2025. Please consider switching to the new Teams for VDI. See: $classicTeamsEoARef" -circle "yellow"
                }

                #Checking (New) Teams MSIX installation info
                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
                $script:TeamsNewInfo = Get-AppxPackage -name "msteams" -ErrorAction SilentlyContinue | Select-Object Version, InstallLocation
                if ($script:TeamsNewInfo) {
					$TeamsNewVer = $script:TeamsNewInfo.Version
					$TeamsNewLoc = $script:TeamsNewInfo.InstallLocation
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "New Teams installation <span style='color: blue'>found</span>" -Message2 "$TeamsNewVer"
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Path" -Message2 "$TeamsNewLoc"

                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                    if (Test-path -path "$env:ProgramFiles\FSLogix\apps") {
                        if (($script:frxverstrip -lt 29871630241) -and (!($script:frxverstrip -eq "unknown"))) {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "You are running an older version of FSLogix. The new Teams for VDI requires at least FSLogix version 2.9.8716.30241 for proper integration. Please consider updating. See: $newTeamsFSLogixRef" -circle "red"
                        }
                    }

                    If ($global:msrdOSVer -like "*Server*2016*") {
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The new Teams for VDI is not supported on Windows Server 2016. Please consider upgrading. See: $newTeamsRef" -circle "red"
                    }
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "New Teams installation <span style='color: brown'>not found</span>"
                }

                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
                $path= "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
                if (Test-Path $path) {
                    $WebRTC = Get-ChildItem -Path $path -ErrorAction Continue 2>>$global:msrdErrorLogFile | Get-ItemProperty | Select-Object DisplayName, DisplayVersion, InstallDate | Where-Object DisplayName -eq "Remote Desktop WebRTC Redirector Service"
                    if ($WebRTC) {
                        $WebRTCver = $WebRTC.DisplayVersion

                        if ($WebRTC.InstallDate) {
                            $WebRTCdate = $WebRTC.InstallDate
                            $WebRTCdate = [datetime]::ParseExact($WebRTCdate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
                        } else {
                            $WebRTCdate = "N/A"
                        }

                        # Split the versions into their components
                        $latestverComponents = $latestWebRTCVer -split '\.'
                        $versionToCheckComponents = $WebRTCver -split '\.'

                        # Ensure that both versions have the same number of components
                        if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Version number mismatch (latest version: $latestWebRTCVer / current version: $WebRTCver)." -circle $circle
                        } else {
                            $isNewer = $false
                            for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                                $latestComponent = [int]$latestverComponents[$i]
                                $checkComponent = [int]$versionToCheckComponents[$i]

                                if ($latestComponent -gt $checkComponent) {
                                    $isNewer = $true
                                    $circle = "red"
                                    break
                                } else {
                                    $circle = "green"
                                }
                            }
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Remote Desktop WebRTC Redirector Service" -Message2 "$WebRTCver (Installed on: $WebRTCdate)" -circle $circle

                            if ($isNewer) {
                                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "You are not using the latest available Remote Desktop WebRTC Redirector Service version. Please consider updating. See: $webrtcRef" -circle "red"
                            }
                        }
                    } else {
                        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Error retrieving Remote Desktop WebRTC Redirector Service information" -circle "red"
                    }
                } else {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Error retrieving Remote Desktop WebRTC Redirector Service information" -circle "red"
                }

                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

                msrdCheckServicePort -service RDWebRTCSvc -tcpports 9500

                #Checking reg keys
                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
                msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Office\Teams\' -RegKey 'DisableFallback'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Teams\' -RegKey 'disableAutoUpdate'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Teams\' -RegKey 'DisableFallback'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Teams\' -RegKey 'IsWVDEnvironment' -RegValue '1'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\' -RegKey 'TeamsProvisionRunKey'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns\WebRTC Redirector\' -RegKey 'Enabled' -RegValue '1'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns\WebRTC Redirector\Policy\' -RegKey 'DisableRAILAppSharing'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns\WebRTC Redirector\Policy\' -RegKey 'DisableRAILScreenSharing'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\AddIns\WebRTC Redirector\Policy\' -RegKey 'ShareClientDesktop'
                
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                msrdCheckRegPath 'HKLM:\SOFTWARE\Citrix\PortICA' 'This path should not exist on an AVD-only deployment'
                msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Citrix\HDXMediaStream\' -RegKey 'MSTeamsRedirSupport' -RegValue '1'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Citrix\WebSocketService\' -RegKey 'ProcessWhitelist' -RegValue 'msedgewebview2.exe '
                
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                msrdCheckRegPath 'HKLM:\SOFTWARE\VMware, Inc.\VMware VDM\Agent' 'This path should not exist on an AVD-only deployment'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\VMware, Inc.\VMware WebRTCRedir\' -RegKey 'teamsEnabled' -RegValue '1'

                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Microsoft Edge WebView2 Runtime" -circle "no"
                msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\' -RegKey 'pv'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\' -RegKey 'pv'
                msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\' -RegKey 'pv'

                #Teams AV Exclusions
                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
                if (Test-Path ($global:msrdLogDir + $regDefExclFile)) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "<b>Windows Defender antivirus exclusions for Teams</b> ($avexTeamsRef)" -Message2 "(See: <a href='$regDefExclFile' target='_blank'>Defender Exclusions</a>)"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>Windows Defender antivirus exclusions for Teams</b> ($avexTeamsRef)" -circle "no"
                }

                $recTeamsAVexclusionsProcs = @(
                    "$msrdUserProfilesDir\*\AppData\Local\Microsoft\Teams\current\teams.exe",
                    "$msrdUserProfilesDir\*\AppData\Local\Microsoft\Teams\update.exe",
                    "$msrdUserProfilesDir\*\AppData\Local\Microsoft\Teams\current\squirrel.exe",
                    "$msrdUserProfilesDir\*\AppData\Local\Microsoft\TeamsMeetingAddin",
                    "ms-teams.exe",
                    "ms-teamsupdate.exe"
                )

                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                if (-not $global:msrdLiveDiag) { $lconf = "<span style='color: blue'>(local config)</span>" } else { $lconf = "(local config)" }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows Defender Processes exclusions $lconf" -circle "no"
                foreach ($item in $recTeamsAVexclusionsProcs) {
                    $islocal = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes\" -value $item
                    $isgpo = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Processes\" -value $item
			        if (-not $islocal -and -not $isgpo) {
                        $avcircle = "red"
                    } elseif (-not $islocal -or -not $isgpo) {
				        $avcircle = "white" #override warning
                    }
                    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes\' -RegKey $item -RegValue '0' -warnMissing -warnColor $avcircle
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                msrdTestAVExclusion -ExclPath "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes" -ExclValue $recTeamsAVexclusionsProcs -Scope "Teams" -color "yellow"

                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
                if (-not $global:msrdLiveDiag) { $pconf = "<span style='color: blue'>(policy config)</span>" } else { $pconf = "(policy config)" }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows Defender Processes exclusions $pconf" -circle "no"
                foreach ($item in $recTeamsAVexclusionsProcs) {
                    $islocal = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes\" -value $item
                    $isgpo = msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Processes\" -value $item
			        if (-not $islocal -and -not $isgpo) {
                        $avcircle = "red"
                    } elseif (-not $islocal -or -not $isgpo) {
				        $avcircle = "white" #override warning
                    }
                    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Processes\' -RegKey $item -RegValue '0' -warnMissing -warnColor $avcircle
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                msrdTestAVExclusion -ExclPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Processes" -ExclValue $recTeamsAVexclusionsProcs -Scope "Teams" -color "yellow"

            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
            }
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "OS not supported for AVD Teams Media Optimization. Skipping check (not applicable)."
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagW365 {

    #Windows 365 diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Windows 365 Boot"
    $menucatmsg = $script:msrdMenuCat
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "CPCCheck"

    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\CloudDesktop\' -RegKey 'BootToCloudMode' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\WindowsLogon\' -RegKey 'OverrideShellProgram' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedPC\' -RegKey '01' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedPC\' -RegKey '18' -RegValue '1'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion AVD/RDS diag functions


#region AVD Infra functions

Function msrdDiagAgentStack {

    #AVD Agent/Stack diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "AVD Agents / SxS Stack"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -DiagTag "AgentStackCheck" -Message $menuitemmsg

    if ($avdcheck) {
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader') {

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            if (msrdTestRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\' -Value 'CurrentBootLoaderVersion') {
                $AVDBLA = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\' -name "CurrentBootLoaderVersion"
                $AVDbootloaderdate = (Get-ItemProperty  hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -eq "Remote Desktop Agent Boot Loader" -and $_.DisplayVersion -eq $AVDBLA)}).InstallDate
                $AVDbootloaderdate = [datetime]::ParseExact($AVDbootloaderdate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")

                if (Test-Path ($global:msrdLogDir + $agentBLinstfile)) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Agent BootLoader" -Message2 "Current version" -Message3 "$AVDBLA (Installed on: $AVDbootloaderdate) (See: <a href='$agentBLinstfile' target='_blank'>AgentBootLoaderInstall</a>)"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Agent BootLoader" -Message2 "Current version" -Message3 "$AVDBLA (Installed on: $AVDbootloaderdate)"
                }

            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Agent BootLoader" -Message2 "'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\CurrentBootLoaderVersion' <span style='color: brown'>not found</span>." -circle "red"
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdCheckServicePort -service RDAgentBootLoader -stopWarning

            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            if (msrdTestRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\' -Value 'DefaultAgent') {

                $AVDagent = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\' -name "DefaultAgent"
                $AVDagentver = $AVDagent.split("_")[1]
                $AVDagentdate = (Get-ItemProperty  hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -eq "Remote Desktop Services Infrastructure Agent" -and $_.DisplayVersion -eq $AVDagentver)}).InstallDate
                $AVDagentdate = [datetime]::ParseExact($AVDagentdate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")

                # Split the versions into their components
                $latestverComponents = $latestAvdAgentVer -split '\.'
                $versionToCheckComponents = $AVDagentver -split '\.'

                # Ensure that both versions have the same number of components
                $isNewer = $false
                if ($latestverComponents.Count -ne $versionToCheckComponents.Count) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "AVD Agent version number mismatch (latest version: $latestAvdAgentVer / current version: $AVDagentver)." -circle $circle
                } else {
                    for ($i = 0; $i -lt $latestverComponents.Count; $i++) {
                        $latestComponent = [int]$latestverComponents[$i]
                        $checkComponent = [int]$versionToCheckComponents[$i]

                        if ($latestComponent -gt $checkComponent) {
                            $isNewer = $true
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $circle = "red"
                            break
                        } elseif ($latestComponent -lt $checkComponent) {
                            $circle = "white"
                            break
                        } else {
                            $circle = "white"
                        }
                    }
                }

                $agentInitExists = Test-Path ($global:msrdLogDir + $agentInitinstfile)
                $agentUpdateExists = Test-Path -Path ($global:msrdLogDir + $agentUpdateinstfile)
                $montablesExists = Test-Path -Path ($global:msrdLogDir + $montablesfolder) -PathType Container

                $AVDagentverMsg3 = $AVDagentver + " (Installed on: " + $AVDagentdate + ")"

                if ($agentInitExists) {
                    $AVDagentverMsg3 += " (See: <a href='$agentInitinstfile' target='_blank'>AgentInstall</a>"
                    if ($agentUpdateExists) { $AVDagentverMsg3 += " / <a href='$agentUpdateinstfile' target='_blank'>AgentUpdates</a>" }
                    if ($montablesExists) { $AVDagentverMsg3 += " / <a href='$montablesfolder' target='_blank'>MonTables</a>" }
                    $AVDagentverMsg3 += ")"
                } elseif ($agentUpdateExists) {
                    $AVDagentverMsg3 += " (See: <a href='$agentUpdateinstfile' target='_blank'>AgentInstall</a>"
                    if ($montablesExists) { $AVDagentverMsg3 += " / <a href='$montablesfolder' target='_blank'>MonTables</a>" }
                    $AVDagentverMsg3 += ")"
                } elseif ($montablesExists) {
                    $AVDagentverMsg3 += " (See: <a href='$montablesfolder' target='_blank'>MonTables</a>)"
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "AVD Agent" -Message2 "Current version" -Message3 "$AVDagentverMsg3" -circle $circle

                if ($isNewer -and ($script:ring -ne "" -and $script:ring -ne "R0")) {
                    if ($global:msrdLiveDiag) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The current AVD Agent is not the latest available version. You might be using Scheduled Agent Update or the latest version has not been rolled out to your session host yet. If this persists long term, additional investigation may be required. " -circle "red"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The current AVD Agent is not the latest available version. You might be using Scheduled Agent Update or the latest version has not been rolled out to your session host yet. If this persists long term, additional investigation may be required. See: $avdagentRef" -circle "red"
                    }
                }

                if (msrdTestRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\' -Value 'PreviousAgent') {
                    $AVDagentpre = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\' -name "PreviousAgent"
                    $AVDagentverpre = $AVDagentpre.split("_")[1]
                    $AVDagentdatepre = (Get-ItemProperty  hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -eq "Remote Desktop Services Infrastructure Agent" -and $_.DisplayVersion -eq $AVDagentverpre)}).InstallDate
                    $AVDagentdatepre = [datetime]::ParseExact($AVDagentdatepre, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
                } else {
                    $AVDagentverpre = "N/A"
                    $AVDagentdatepre = "N/A"
                }
                if ($AVDagentverpre -eq "N/A") {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Previous version" -Message3 "$AVDagentverpre"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Previous version" -Message3 "$AVDagentverpre (Installed on: $AVDagentdatepre)"
                }
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\DefaultAgent' <span style='color: brown'>not found</span>. This machine is either not part of an AVD host pool or it is not configured properly." -circle "red"
            }

        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "RDAgentBootLoader configuration <span style='color: brown'>not found</span>. This machine is either not part of an AVD host pool or it is not configured properly." -circle "red"
            if ($hp) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "VM is part of host pool '$hp' but the HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader registry key could not be found. You may have issues accessing this VM through AVD." -circle "red"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\' -RegKey 'IsRegistered' -RegValue '1' -warnMissing
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\' -RegKey 'RegistrationToken'

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent') {

            if (msrdTestRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\SxsStack\' -Value 'CurrentVersion') {
                $sxsstack = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\SxsStack' -name "CurrentVersion"
                $sxsstackpath = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\SxsStack' -name $sxsstack
                $sxsstackver = $sxsstackpath.split("-")[1].trimend(".msi")
                $sxsstackdate = (Get-ItemProperty  hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -eq "Remote Desktop Services SxS Network Stack" -and $_.DisplayVersion -eq $sxsstackver)}).InstallDate
                $sxsstackdate = [datetime]::ParseExact($sxsstackdate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")

                if (Test-Path ($global:msrdLogDir + $sxsinstfile)) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "SxS Stack" -Message2 "Current version" -Message3 "$sxsstackver (Installed on: $sxsstackdate) (See: <a href='$sxsinstfile' target='_blank'>SxSStackInstall</a>)"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "SxS Stack" -Message2 "Current version" -Message3 "$sxsstackver (Installed on: $sxsstackdate)"
                }

            } else {
                $sxsstackver = "N/A"
                $sxsstackdate = "N/A"
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "SxS Stack" -Message2 "Current version: <span style='color: brown'>not found</span>. Check if the SxS Stack was installed properly." -circle "red"
            }

            if (msrdTestRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\SxsStack\' -Value 'PreviousVersion') {
                $sxsstackpre = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\SxsStack' -name "PreviousVersion"
                if (($sxsstackpre) -and ($sxsstackpre -ne "")) {
                    $sxsstackpathpre = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\SxsStack' -name $sxsstackpre
                    $sxsstackverpre = $sxsstackpathpre.split("-")[1].trimend(".msi")
                    $sxsstackdatepre = (Get-ItemProperty  hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -eq "Remote Desktop Services SxS Network Stack" -and $_.DisplayVersion -eq $sxsstackverpre)}).InstallDate
                    $sxsstackdatepre = [datetime]::ParseExact($sxsstackdatepre, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
                } else {
                    $sxsstackverpre = "N/A"
                    $sxsstackdatepre = "N/A"
                }
            } else {
                $sxsstackverpre = "N/A"
                $sxsstackdatepre = "N/A"
            }
            if ($sxsstackverpre -eq "N/A") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Previous version" -Message3 "$sxsstackverpre"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Previous version" -Message3 "$sxsstackverpre (Installed on: $sxsstackdatepre)"
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "RDInfraAgent configuration <span style='color: brown'>not found</span>. This machine is either not part of an AVD host pool or it is not configured properly." -circle "red"
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\ByPass\' -RegKey 'EnableStackVersionBypass'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\ByPass\' -RegKey 'StackByPassVersion'

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent') {
            if (msrdTestRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent\' -Value 'CurrentVersion') {
                $genevaver = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent' -name "CurrentVersion"
                $genevadate = (Get-ItemProperty hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -like "*Remote Desktop Services Infrastructure Geneva Agent*" -and $_.DisplayVersion -eq $genevaver)} -ErrorAction SilentlyContinue).InstallDate
                if ($genevadate) {
                    $genevadate = [datetime]::ParseExact($genevadate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
                    $circle = "white"
                } else {
                    $genevadate = "N/A - Possible installation failure"
                    $circle = "red"; $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                }

                if (Test-Path ($global:msrdLogDir + $genevainstfile)) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "AVD Geneva Agent" -Message2 "Current version" -Message3 "$genevaver (Installed on: $genevadate) (See: <a href='$genevainstfile' target='_blank'>GenevaInstall</a>)" -circle $circle
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "AVD Geneva Agent" -Message2 "Current version" -Message3 "$genevaver (Installed on: $genevadate)" -circle $circle
                }

            } else {
                $genevaver = "N/A"
                $genevadate = "N/A"
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "AVD Geneva Agent" -Message2 "Current version: <span style='color: brown'>not found</span>. Check if the AVD Geneva Monitoring Agent was installed properly." -circle "red"
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "RDMonitoringAgent configuration <span style='color: brown'>not found</span>. This machine is either not part of an AVD host pool or it is not configured properly." -circle "red"
        }

    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}


function msrdDiagAppAttach {

    #App Attach info
    $global:msrdSetWarning = $false
    $menuitemmsg = "App Attach"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "AppAttachCheck"

    #https://learn.microsoft.com/en-us/azure/virtual-desktop/app-attach-setup?tabs=portal&pivots=msix-app-attach#disable-automatic-updates
    msrdCheckRegKeyValue -RegPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore\" -RegKey "AutoDownload" -RegValue "2" -warnColor "yellow" -OptNote "Disables Microsoft Store automatic update"
    msrdCheckRegKeyValue -RegPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" -RegKey "PreInstalledAppsEnabled" -RegValue "0" -warnColor "yellow" -OptNote "Disables content delivery automatic download"
    msrdCheckRegKeyValue -RegPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug\" -RegKey "ContentDeliveryAllowedOverride" -RegValue "2" -warnColor "yellow" -OptNote "Disables content delivery automatic download"

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagMonitoring {

    #Azure Monitoring
    $global:msrdSetWarning = $false
    $menuitemmsg = "Monitoring"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "MonitorCheck"

    #Microsoft Monitoring Agent
    $mmaExtension = Get-ChildItem -Path "C:\Packages\Plugins\Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent\" -Recurse -Filter "Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent_*.zip" -ErrorAction SilentlyContinue
    if ($mmaExtension) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Microsoft Monitoring Agent extension package found" -Message2 "$mmaExtension"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Microsoft Monitoring Agent extension package not found"
    }

    $mmainfo = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Where-Object {($_.DisplayName -like "*Microsoft Monitoring Agent*")})

    if ($mmainfo) {
        $mmaversion = $mmainfo.DisplayVersion
		$mmadate = $mmainfo.InstallDate
		$mmadate = [datetime]::ParseExact($mmadate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
	} else {
		$mmaversion = "N/A"
		$mmadate = "N/A"
    }
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Microsoft Monitoring Agent" -Message2 "Current version (Installed on: $mmadate)" -Message3 "$mmaversion"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    Try {
        $mmaworkspaces = (New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg').GetCloudWorkspaces()
    } Catch {
        $mmaworkspaces = "n/a"
    }

    if ($mmaworkspaces -ne "n/a") {
        foreach ($property in $mmaworkspaces | Get-Member -MemberType Property) {
            $propertyName = $property.Name
            $propertyValue = $mmaworkspaces | Select-Object -ExpandProperty $propertyName
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "$propertyName" -Message2 "$propertyValue"
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The legacy Log Analytics agent will be deprecated by August 2024. After this date, Microsoft will no longer provide any support for the Log Analytics agent. Migrate to Azure Monitor agent before August 2024 to continue ingesting data." -circle "yellow"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service HealthService
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service MMAExtensionHeartbeatService

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\' -RegKey 'Persistence Cache Maximum'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    #https://learn.microsoft.com/en-us/azure/azure-monitor/agents/log-analytics-agent#firewall-requirements
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Microsoft Monitoring Agent required endpoints" -circle "no"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure (all)" -circle "no"
    $MMAurls = [Ordered]@{
        "ods.opinsights.azure.com" = @()
        "oms.opinsights.azure.com" = @()
        "blob.core.windows.net" = @()
        "azure-automation.net" = @()
    }
    msrdReqURLCheck -urls $MMAurls

    #Azure Monitor Agent
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $amaExtension = Get-ChildItem -Path "C:\Packages\Plugins\Microsoft.Azure.Monitor.AzureMonitorWindowsAgent\" -Recurse -Filter "Microsoft.Azure.Monitor.AzureMonitorWindowsAgent_*.zip" -ErrorAction SilentlyContinue
    if ($amaExtension) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Azure Monitor Agent extension package found" -Message2 "$amaExtension"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure Monitor Agent extension package not found"
    }

    $amaextensionInstalled = Get-ChildItem -Path "C:\Packages\Plugins\Microsoft.Azure.Monitor.AzureMonitorWindowsAgent\" -Recurse -Filter "AzureMonitorAgentExtension.exe" -ErrorAction SilentlyContinue
    if ($amaextensionInstalled) {
        $amaextensionVer = $amaextensionInstalled.VersionInfo.ProductVersion
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Azure Monitor Agent extension installed" -Message2 "$amaextensionVer"
	} else {
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure Monitor Agent extension not installed"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service WindowsAzureGuestAgent

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdProcessCheck -proc "MonAgentCore" -intName "Azure Monitor Agent" -noSpacer1
    msrdProcessCheck -proc "MonAgentHost" -intName "Azure Monitor Agent"
    msrdProcessCheck -proc "MonAgentLauncher" -intName "Azure Monitor Agent"
    msrdProcessCheck -proc "MonAgentManager" -intName "Azure Monitor Agent"
    msrdProcessCheck -proc "AMAExtHealthMonitor" -intName "Azure Monitor Agent" -noSpacer2

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    #https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-data-collection-endpoint?tabs=PowerShellWindows#firewall-requirements
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure Monitor Agent required endpoints" -circle "no"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure (all)" -circle "no"
    $AMAurls = [Ordered]@{
        "global.handler.control.monitor.azure.com" = @(443)
        "handler.control.monitor.azure.com" = @()
        "ods.opinsights.azure.com" = @()
        "management.azure.com" = @(443)
        "monitoring.azure.com" = @()
        "ingest.monitor.azure.com" = @()
    }
    msrdReqURLCheck -urls $AMAurls

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure Government specific" -circle "no"
    $AMAGovurls = [Ordered]@{
        "global.handler.control.monitor.azure.us" = @(443)
        "handler.control.monitor.azure.us" = @()
        "ods.opinsights.azure.us" = @()
        "management.azure.us" = @()
        "monitoring.azure.us" = @()
        "ingest.monitor.azure.us" = @()
    }
    msrdReqURLCheck -urls $AMAGovurls

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure China specific" -circle "no"
    $AMAGovurls = [Ordered]@{
        "global.handler.control.monitor.azure.cn" = @(443)
        "handler.control.monitor.azure.cn" = @()
        "ods.opinsights.azure.cn" = @()
        "management.azure.cn" = @()
        "monitoring.azure.cn" = @()
        "ingest.monitor.azure.cn" = @()
    }
    msrdReqURLCheck -urls $AMAGovurls

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagHP {

    #AVD host pool diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "AVD Host Pool"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "HPCheck"

    If (Test-Path 'HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent') {
        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -value "SessionHostPool") {
            $script:hp = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -name "SessionHostPool"
        } else { $hp = $false }

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -value "Geography") {
            $geo = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -name "Geography"
        } else { $geo = "N/A" }

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -value "Tenant") {
            $rg = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -name "Tenant"
        } else { $rg = "N/A" }

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -value "Cluster") {
            $cluster = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -name "Cluster"
        } else { $cluster = "N/A" }

        if ($hp) {
            if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -value "Ring") {
                $script:ring = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -name "Ring"
            } else { $script:ring = "N/A" }

            if (-not $global:msrdLiveDiag) {
                Add-Content $msrdDiagFile "<tr align='center'><th width='10px'><div class='circle_no'></div></th><th>Host Pool</th><th>Ring</th><th>Resource Group</th><th>Geography</th><th>Cluster</th></tr>"
            }

            if ($script:ring -eq "R0") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 4 -Message "Host Pool: $hp - Ring: $($script:ring) (Validation) - Resource Group: $rg - Geography: $geo - Cluster: $cluster"
                } else {
                   Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_red'></div></td><td>$hp</td><td>$($script:ring) (Validation)</td><td>$rg</td><td>$geo</td><td>$cluster</td></tr>"
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 4 -Message "This host pool is in the validation ring (R0). Validation ring deployments are intended for testing, not for production use!" -circle "red"
            } else {
                if ($global:msrdLiveDiag) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 4 -Message "Host Pool: $hp - Ring: $($script:ring) (Production) - Resource Group: $rg - Geography: $geo - Cluster: $cluster"
                } else {
                    Add-Content $msrdDiagFile "<tr align='center'><td width='10px'><div class='circle_white'></div></td><td>$hp</td><td>$($script:ring) (Production)</td><td>$rg</td><td>$geo</td><td>$cluster</td></tr>"
                }
            }

            if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -value "HostPoolArmPath") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                $armpath = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -name "HostPoolArmPath"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Host pool ARM path" -Message2 "$armpath"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'HostPoolArmPath' not found. This machine is either not registered as an AVD VM or it is part of an AVD Classic deployment. AVD Classic will retire on September 30, 2026. If this VM is part of an AVD Classic deployment then you should transition to the ARM-based Azure Virtual Desktop before that date. See: $avdclassicRef"
            }

        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 4 -Message "'HKLM\SOFTWARE\Microsoft\RDMonitoringAgent' reg key found, but this machine is not part of an AVD host pool. It might have host pool registration issues." -circle "red"
        }

    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 4 -Message "'HKLM\SOFTWARE\Microsoft\RDMonitoringAgent' reg key not found. This machine is either not part of an AVD host pool or it is not configured properly." -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}


Function msrdDiagHealthCheck {

    #AVD latest Health Check results
    $global:msrdSetWarning = $false
    $menuitemmsg = "Health Checks"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -DiagTag "AVDHealthCheck" -Message $menuitemmsg

    if ($avdcheck) {
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent\HealthCheckReport') {

            $HCjsonString = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\HealthCheckReport\" -Name "AgentHealthCheckReport"
            $HCjsonObject = ConvertFrom-Json $HCjsonString
            $HCresults = $HCjsonObject.PSObject.Properties
            
            $HCresultsCount = @($HCresults).Count
            $HCresultsCountMinusOne = $HCresultsCount - 1
            $index = 0

            foreach ($entry in $HCresults) {
                $healthCheck = $entry.Value

                $lastHealthCheckInUTC = $healthCheck.AdditionalFailureDetails.LastHealthCheckInUTC
                try {
                    $dateTimeFromString = Get-Date $lastHealthCheckInUTC
                } catch {
                    msrdLogException ("$(msrdGetLocalizedText "errormsg") Invoke-WebRequest $dateTimeFromString") -ErrObj $_
                    continue  # Skip to the next iteration of the loop
                }
                $currentDateTime = Get-Date
                $age = $currentDateTime - $dateTimeFromString
                $lastHealthCheckInUTC = $lastHealthCheckInUTC -replace 'T', ' ' -replace 'Z', ''
                $lastHealthCheckInUTC += " ($($age.Days)d $($age.Hours)h $($age.Minutes)m $($age.Seconds)s ago)"

                $healthCheckResult = $healthCheck.HealthCheckResult
                $message = $healthCheck.AdditionalFailureDetails.Message
                $errorCode = $healthCheck.AdditionalFailureDetails.ErrorCode

                # Display ErrorCode only if it's different from 0
                if ($errorCode -ne 0) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    $HCcircle = "red"
                } else {
                    if ($healthCheckResult -eq 1) { $HCcircle = "green" } else { $HCcircle = "white" }
                }

                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>$($entry.Name)</b>" -circle $HCcircle
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "LastHealthCheckInUTC" -Message2 $lastHealthCheckInUTC
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "HealthCheckResult" -Message2 $healthCheckResult -circle $HCcircle
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Message" -Message2 $message -circle $HCcircle

                if ($errorCode -ne 0) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "ErrorCode" -Message2 $errorCode -circle $HCcircle
                }

                if ($index -ne $HCresultsCountMinusOne) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
                }
                $index++
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Health Check Report not found" -circle "red"
        }
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}


function msrdReqURLCheck {
	param(
        [ValidateNotNullOrEmpty()]$urls
    )

    $sortedKeys = [Ordered]@{}
    $urls.Keys | Sort-Object | ForEach-Object { $sortedKeys[$_] = $urls[$_] }

    foreach ($key in $sortedKeys.Keys) {
        $url = $key
        $ports = $sortedKeys[$key]
        $errcounter = 0

        if ($url -notlike "1*") {
            try {
                $dnscheck = Resolve-DnsName -Name $url -QuickTimeout -ErrorAction SilentlyContinue
                if ($dnscheck) { $msg3dns = "DNS resolution: <span style='color: green'>Successful</span>" } else { $msg3dns = "DNS resolution: <span style='color: red'>Failed</span>"; $errcounter += 1 }
            } catch {
                $failedCommand = $_.InvocationInfo.Line.TrimStart()
                $failedCommand = $failedCommand -replace [regex]::Escape("`$url"), $url

                msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                $msg3dns = "DNS resolution: <span style='color: red'>Failed</span>"; $errcounter += 1
            }
        } else {
            $msg3dns = ""
        }

        $msg3tcp = "";
        if ($ports.Count -gt 0) {
            foreach ($port in $ports) {
				$tcpcheck = msrdTestTCP -address $url -port $port
				if ($tcpcheck[0] -eq "True") { $msg3tcp += "TCP $port" + ": <span style='color: green'>Reachable</span>" } else { $msg3tcp += "TCP $port" + ": <span style='color: red'>Not reachable</span>"; $errcounter += 1 }
                if ($port -ne $ports[-1]) { $msg3tcp += " / " }
			}
        }

        if ($errcounter -gt 0) { $msg3tcp += " (See: <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a>)" }

        if (($dnscheck -or ($msg3dns -eq "")) -and (($errcounter -eq 0) -or ($ports.Count -eq 0))) {
            $urlcircle = "green"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            $urlcircle = "red"
        }

        if ($msg3dns -ne "") {
            if ($ports.Count -gt 0) { $message3 = "$msg3dns / $msg3tcp" } else { $message3 = $msg3dns }
        } elseif ($ports.Count -gt 0) {
            $message3 = $msg3tcp
        } else {
			$message3 = "No information available"
            $urlcircle = "red"
		}
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 $url -Message3 $message3 -circle $urlcircle
    }
}

Function msrdDiagURL {

    #AVD required URLs diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Required Endpoints"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "URLCheck"

    if ($global:msrdSource) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>AVD Client Endpoints</b>" -circle "no"

        #https://learn.microsoft.com/en-us/azure/virtual-desktop/required-fqdn-endpoint?tabs=azure#end-user-devices
        $RDCUrlsAzAll = [Ordered]@{
            "go.microsoft.com" = @(443)
            "aka.ms" = @(443)
            "privacy.microsoft.com" = @(443)
            "query.prod.cms.rt.microsoft.com" = @(443)
            "learn.microsoft.com" = @(443)
        }

        $RDCUrlsAzCloud = [Ordered]@{
            "login.microsoftonline.com" = @(443)
            "wvd.microsoft.com" = @()
            "servicebus.windows.net" = @()
        }

        $RDCUrlsAzUSGov = [Ordered]@{
            "login.microsoftonline.us" = @(443)
            "wvd.azure.us" = @()
            "servicebus.usgovcloudapi.net" = @()
        }

        #https://docs.azure.cn/zh-cn/virtual-desktop/safe-url-list#remote-desktop-clients
        $RDCUrlsAzChina = [Ordered]@{
            "wvd.azure.cn" = @()
            "servicebus.chinacloudapi.cn" = @()
        }

        #https://learn.microsoft.com/en-us/windows-app/admins/required-urls
        $w365clienturls = [Ordered]@{
            "azure.com" = @(80,443)
            "graph.microsoft.com" = @(443)
            "microsoft.com" = @(80,443)
            "msauth.net" = @()
            "msedge.net" = @()
            "msftauth.net" = @()
            "msocdn.com" = @()
            "office.com" = @(80,443)
            "office.net" = @()
            "office365.com" = @(80,443)
            "outlook.live.com" = @(80,443)
            "windows.cloud.microsoft" = @(443)
            "windows365.microsoft.com" = @(443)
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure (all)" -circle "no"
        msrdReqURLCheck -urls $RDCUrlsAzAll
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure Cloud specific" -circle "no"
        msrdReqURLCheck -urls $RDCUrlsAzCloud
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure for US Government specific" -circle "no"
        msrdReqURLCheck -urls $RDCUrlsAzUSGov
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure China specific" -circle "no"
        msrdReqURLCheck -urls $RDCUrlsAzChina
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows App specific" -circle "no"
        msrdReqURLCheck -urls $w365clienturls
    }

    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>AVD Host Endpoints</b>" -circle "no"
        #https://learn.microsoft.com/en-us/azure/virtual-desktop/required-fqdn-endpoint?tabs=azure

        $AVDUrlsAzAll = [Ordered]@{
            "169.254.169.254" = @(80)
            "168.63.129.16" = @(80)
        }

        $AVDUrlsAzCloud = [Ordered]@{
            "login.microsoftonline.com" = @(443)
            "wvd.microsoft.com" = @()
            "prod.warm.ingest.monitor.core.windows.net" = @()
            "catalogartifact.azureedge.net" = @(443)
            "gcs.prod.monitoring.core.windows.net" = @(443)
            "kms.core.windows.net" = @(1688)
            "azkms.core.windows.net" = @(1688)
            "mrsglobalsteus2prod.blob.core.windows.net" = @(443)
            "wvdportalstorageblob.blob.core.windows.net" = @(443)
            "oneocsp.microsoft.com" = @(80)
            "www.microsoft.com" = @(80)
        }

        $AVDUrlsAzUSGov = [Ordered]@{
            "login.microsoftonline.us" = @(443)
            "wvd.azure.us" = @()
            "prod.warm.ingest.monitor.core.usgovcloudapi.net" = @()
            "gcs.monitoring.core.usgovcloudapi.net" = @(443)
            "kms.core.usgovcloudapi.net" = @(1688)
            "mrsglobalstugviffx.blob.core.usgovcloudapi.net" = @(443)
            "wvdportalstorageblob.blob.core.usgovcloudapi.net" = @(443)
            "ocsp.msocsp.com" = @(80)
        }

        #https://docs.azure.cn/zh-cn/virtual-desktop/safe-url-list#session-host-virtual-machines
        $AVDUrlsAzChina = [Ordered]@{
            "login.partner.microsoftonline.cn" = @(443)
            "wvd.azure.cn" = @()
            "mooncake.warmpath.chinacloudapi.cn" = @(443)
            "monitoring.core.chinacloudapi.cn" = @(443)
            "blob.core.chinacloudapi.cn" = @()
            "servicebus.chinacloudapi.cn" = @()
            "table.core.chinacloudapi.cn" = @()
            "queue.core.chinacloudapi.cn" = @()
            "kms.core.chinacloudapi.cn" = @(1688)
            "mrsglobalstcne2mc.blob.core.chinacloudapi.cn" = @(443)
            "wvdportalcontainer.blob.core.chinacloudapi.cn" = @(443)
            "crl.digicert.cn" = @(443)
            "microsoft.com" = @(443)
            "prod.warm.ingest.monitor.core.chinacloudapi.cn" = @()
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure (all)" -circle "no"
        msrdReqURLCheck -urls $AVDUrlsAzAll
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure Cloud specific" -circle "no"
        msrdReqURLCheck -urls $AVDUrlsAzCloud
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure for US Government specific" -circle "no"
        msrdReqURLCheck -urls $AVDUrlsAzUSGov
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure China specific" -circle "no"
        msrdReqURLCheck -urls $AVDUrlsAzChina

        #wvdagenturltool output
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        If ($avdcheck) {
            $toolfolder = Get-ChildItem $msrdAgentpath -Directory | Foreach-Object {If (($_.psiscontainer) -and ($_.fullname -like "*RDAgent_*")) { $_.Name }} | Select-Object -Last 1
            $URLCheckToolPath = $msrdAgentpath + $toolfolder + "\WVDAgentUrlTool.exe"

            if (Test-Path $URLCheckToolPath) {
                Try {
                    $urlout = & $URLCheckToolPath
                    $urlna = $false
                    foreach ($urlline in $urlout) {
                        if (!($urlline -eq "") -and !($urlline -like "*===========*") -and !($urlline -like $null) -and ($urlline -ne "WVD") -and !($urlline -like "*Acquired on*") -and !($urlline -like "*Agent URL Tool*") -and !($urlline -like "*Copyright*")) {

                            if ($urlline -like "*Not Accessible*") { $urlna = $true }

                            if ($urlline -like "*Version*") {
                                $uver = $urlline.Split(" ")[1]
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Azure Virtual Desktop Agent URL Tool" -Message2 "$uver"

                            } elseif (($urlline -like "*.com") -or ($urlline -like "*.net") -or ($urlline -like "*.us") -or ($urlline -like "*.cn")) {
                                if ($urlna) {
                                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "$urlline" -circle "red"
                                } else {
                                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "$urlline" -circle "green"
                                }

                            } elseif ($urlline -like "UrlsAccessibleCheck*") {
                                $urlc2 = $urlline.Split(": ")[-1]
                                $urlc1 = $urlline.Trimend($urlc2)
                                if ($urlc2 -like "*HealthCheckSucceeded*") {
                                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$urlc1" -Message2 "$urlc2" -circle "green"
                                } else {
                                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$urlc1" -Message2 "$urlc2" -circle "red"
                                }

                            } elseif (($urlline -like "*Unable to extract*") -or ($urlline -like "*Failed to connect to the Agent*") -or ($urlline -like "*Tool failed with*")) {
                                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$urlline" -circle "red"

                            } else {
                                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$urlline"
                            }
                        }
                    }
                } Catch {
                    $failedCommand = $_.InvocationInfo.Line.TrimStart()
                    msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
                    Continue
                }
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$msrdAgentpath found, but 'WVDAgentUrlTool.exe' is missing, skipping check. You should be running agent version 1.0.2944.1200 or higher." -circle "red"
            }

        } else {
            if ($global:msrdTarget) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>Optional endpoints that session host virtual machines might also need to access other services</b>" -circle "no"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "This list doesn't include FQDNs and endpoints for other services such as Microsoft Entra ID, Office 365, custom DNS providers or time services. Microsoft Entra FQDNs and endpoints can be found under ID 56, 59 and 125 in <a href='https://learn.microsoft.com/en-us/office365/enterprise/urls-and-ip-address-ranges#microsoft-365-common-and-office-online' target='_blank'>Office 365 URLs and IP address ranges</a>." -circle "no"

        $optionalUrlsAzAll = [Ordered]@{
            "events.data.microsoft.com" = @(443)
            "www.msftconnecttest.com" = @(443)
            "prod.do.dsp.mp.microsoft.com" = @()
            "oneclient.sfx.ms" = @(443)
            "digicert.com" = @(80, 443)
            "azure-dns.com" = @()
            "azure-dns.net" = @()
        }

        $optionalurls = [Ordered]@{
            "login.windows.net" = @(443)
            "servicebus.windows.net" = @()
        }

        $optionalurlsChina = [Ordered]@{
            "login.chinacloudapi.cn" = @(443)
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure (all)" -circle "no"
        msrdReqURLCheck -urls $optionalUrlsAzAll
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure Cloud specific" -circle "no"
        msrdReqURLCheck -urls $optionalurls
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Azure China specific" -circle "no"
        msrdReqURLCheck -urls $optionalurlsChina


        if ($global:msrdW365) {
            #Windows 365 Cloud PC required URLs
            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "<b>Windows 365 Endpoints</b>" -circle "no"

            #https://learn.microsoft.com/en-us/windows-365/enterprise/requirements-network?tabs=enterprise%2Cent
            $w365EntUrls = [Ordered]@{
                "windows365.microsoft.com" = @(443)
                "cpcsaamssa1prodprap01.blob.core.windows.net" = @(443)
                "cpcsaamssa1prodprau01.blob.core.windows.net" = @(443)
                "cpcsaamssa1prodpreu01.blob.core.windows.net" = @(443)
                "cpcsaamssa1prodpreu02.blob.core.windows.net" = @(443)
                "cpcsaamssa1prodprna01.blob.core.windows.net" = @(443)
                "cpcsaamssa1prodprna02.blob.core.windows.net" = @(443)
                "cpcstcnryprodprap01.blob.core.windows.net" = @(443)
                "cpcstcnryprodprau01.blob.core.windows.net" = @(443)
                "cpcstcnryprodpreu01.blob.core.windows.net" = @(443)
                "cpcstcnryprodpreu02.blob.core.windows.net" = @(443)
                "cpcstcnryprodprna01.blob.core.windows.net" = @(443)
                "cpcstcnryprodprna02.blob.core.windows.net" = @(443)
                "cpcstprovprodpreu01.blob.core.windows.net" = @(443)
                "cpcstprovprodpreu02.blob.core.windows.net" = @(443)
                "cpcstprovprodprna01.blob.core.windows.net" = @(443)
                "cpcstprovprodprna02.blob.core.windows.net" = @(443)
                "cpcstprovprodprap01.blob.core.windows.net" = @(443)
                "cpcstprovprodprau01.blob.core.windows.net" = @(443)
                "prna01.prod.cpcgateway.trafficmanager.net" = @(443)
                "prna02.prod.cpcgateway.trafficmanager.net" = @(443)
                "preu01.prod.cpcgateway.trafficmanager.net" = @(443)
                "preu02.prod.cpcgateway.trafficmanager.net" = @(443)
                "prap01.prod.cpcgateway.trafficmanager.net" = @(443)
                "prau01.prod.cpcgateway.trafficmanager.net" = @(443)
                "endpointdiscovery.cmdagent.trafficmanager.net" = @(443)
                "registration.prna01.cmdagent.trafficmanager.net" = @(443)
                "registration.preu01.cmdagent.trafficmanager.net" = @(443)
                "registration.prap01.cmdagent.trafficmanager.net" = @(443)
                "registration.prau01.cmdagent.trafficmanager.net" = @(443)
                "registration.prna02.cmdagent.trafficmanager.net" = @(443)
                "login.microsoftonline.com" = @(443)
                "login.live.com" = @(443)
                "enterpriseregistration.windows.net" = @(443)
                "global.azure-devices-provisioning.net" = @(443, 5671)
                "hm-iot-in-prod-prap01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-prod-prau01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-prod-preu01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-prod-prna01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-prod-prna02.azure-devices.net" = @(443, 5671)
                "hm-iot-in-2-prod-preu01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-2-prod-prna01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-3-prod-preu01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-3-prod-prna01.azure-devices.net" = @(443, 5671)
                "hm-iot-in-4-prod-prna01.azure-devices.net" = @(443, 5671)
            }

            $w365GovUrls = [Ordered]@{
                "ghp01.ghp.cpcgateway.usgovtrafficmanager.net" = @(443)
                "gcp01.gcp.cpcgateway.usgovtrafficmanager.net" = @(443)
                "cpcstprovghpghp01.blob.core.usgovcloudapi.net" = @(443)
                "cpcsaamssa1ghpghp01.blob.core.usgovcloudapi.net" = @(443)
                "cpcstcnryghpghp01.blob.core.usgovcloudapi.net" = @(443)
                "cpcsacnrysa1ghpghp01.blob.core.usgovcloudapi.net" = @(443)
                "cpcstprovgcpgcp01.blob.core.usgovcloudapi.net" = @(443)
                "cpcsaamssa1gcpgcp01.blob.core.usgovcloudapi.net" = @(443)
                "cpcstcnrygcpgcp01.blob.core.usgovcloudapi.net" = @(443)
                "cpcsacnrysa1gcpgcp01.blob.core.usgovcloudapi.net" = @(443)
                "windows365.microsoft.us" = @(443)
                "portal.manage.microsoft.us" = @(443)
                "m.manage.microsoft.us" = @(443)
                "mam.manage.microsoft.us" = @(443)
                "wip.mam.manage.microsoft.us" = @(443)
                "Fef.FXPASU01.manage.microsoft.us" = @(443)
                "portal.manage.microsoft.com" = @(443)
                "m.manage.microsoft.com" = @(443)
                "fef.msuc03.manage.microsoft.com" = @(443)
                "mam.manage.microsoft.com" = @(443)
                "wip.mam.manage.microsoft.com" = @(443)
                "login.microsoftonline.us" = @(443)
                "login.live.com" = @(443)
                "login.microsoftonline.com" = @(443)
                "global.azure-devices-provisioning.us" = @(443, 5671)
                "hm-iot-in-ghp-ghp01.azure-devices.us" = @(443, 5671)
                "hm-iot-in-gcp-gcp01.azure-devices.us" = @(443, 5671)
                "endpointdiscovery.ghp.cmdagent.usgovtrafficmanager.net" = @(443)
                "endpointdiscovery.gcp.cmdagent.usgovtrafficmanager.net" = @(443)
                "registration.ghp01.cmdagent.usgovtrafficmanager.net" = @(443)
                "registration.gcp01.cmdagent.usgovtrafficmanager.net" = @(443)
                "hm-iot-in-gcb-gcb01.azure-devices.us" = @(443, 5671)
                "hm-iot-in-ghb-ghb01.azure-devices.us" = @(443, 5671)
                "rdweb.wvd.azure.us" = @(443)
                "rdbroker.wvd.azure.us" = @(443)
                "rdweb.wvd.microsoft.com" = @(443)
                "rdbroker.wvd.microsoft.com" = @(443)
                "download.microsoft.com" = @(443)
                "software-download.microsoft.com" = @(443)
            }

            #https://learn.microsoft.com/en-us/mem/intune/fundamentals/intune-endpoints?tabs=north-america
            $w365IntuneUrls = [Ordered]@{
                "manage.microsoft.com" = @(80, 443)
                "EnterpriseEnrollment.manage.microsoft.com" = @(80, 443)
                "do.dsp.mp.microsoft.com" = @()
                "emdl.ws.microsoft.com" = @()
                "kv801.prod.do.dsp.mp.microsoft.com" = @(80, 443)
                "geo.prod.do.dsp.mp.microsoft.com" = @(443)
                "2.dl.delivery.mp.microsoft.com" = @(80, 443)
                "bg.v4.emdl.ws.microsoft.com" = @()
                "swda01-mscdn.azureedge.net" = @(443)
                "swda02-mscdn.azureedge.net" = @(443)
                "swdb01-mscdn.azureedge.net" = @(443)
                "swdb02-mscdn.azureedge.net" = @(443)
                "swdc01-mscdn.azureedge.net" = @(443)
                "swdc02-mscdn.azureedge.net" = @(443)
                "swdd01-mscdn.azureedge.net" = @(443)
                "swdd02-mscdn.azureedge.net" = @(443)
                "swdin01-mscdn.azureedge.net" = @(443)
                "swdin02-mscdn.azureedge.net" = @(443)
                "download.windowsupdate.com" = @(443)
                "windowsupdate.com" = @()
                "dl.delivery.mp.microsoft.com" = @(443)
                "prod.do.dsp.mp.microsoft.com" = @()
                "delivery.mp.microsoft.com" = @()
                "update.microsoft.com" = @(443)
                "tsfe.trafficshaping.dsp.mp.microsoft.com" = @(443)
                "au.download.windowsupdate.com" = @(443)
                "catalog.update.microsoft.com" = @(443)
                "time.windows.com" = @()
                "www.msftncsi.com" = @(443)
                "www.msftconnecttest.com" = @(443)
                "clientconfig.passport.net" = @(443)
                "windowsphone.com" = @(443)
                "s-microsoft.com" = @()
                "c.s-microsoft.com" = @(443)
                "ekcert.spserv.microsoft.com" = @(443)
                "ekop.intel.com" = @(443)
                "ftpm.amd.com" = @(443)
                "lgmsapeweu.blob.core.windows.net" = @(443)
                "notify.windows.com" = @()
                "wns.windows.com" = @(443)
                "sinwns1011421.wns.windows.com" = @()
                "sin.notify.windows.com" = @(443)
                "approdimedatapri.azureedge.net" = @(443)
                "approdimedatasec.azureedge.net" = @(443)
                "approdimedatahotfix.azureedge.net" = @(443)
                "euprodimedatapri.azureedge.net" = @(443)
                "euprodimedatasec.azureedge.net" = @(443)
                "euprodimedatahotfix.azureedge.net" = @(443)
                "naprodimedatapri.azureedge.net" = @(443)
                "naprodimedatasec.azureedge.net" = @(443)
                "naprodimedatahotfix.azureedge.net" = @(443)
                "itunes.apple.com" = @(443)
                "mzstatic.com" = @(443)
                "phobos.apple.com" = @(443)
                "phobos.itunes-apple.com.akadns.net" = @(443)
                "5-courier.push.apple.com" = @(443)
                "ocsp.apple.com" = @(443)
                "ax.itunes.apple.com" = @(443)
                "ax.itunes.apple.com.edgesuite.net" = @(443)
                "s.mzstatic.com" = @(443)
                "a1165.phobos.apple.com" = @(443)
                "intunecdnpeasd.azureedge.net" = @(443)
            }

            #https://learn.microsoft.com/en-us/mem/intune/fundamentals/intune-us-government-endpoints
            $w365IntuneGovUrls = [Ordered]@{
                "directory.microsoftazure.us" = @(80, 443)
                "directoryproxy.microsoftazure.us" = @(80, 443)
                "enterpriseregistration.microsoftonline.us" = @(80, 443)
                "graph.microsoft.us" = @(80, 443)
                "graph.microsoftazure.us" = @(80, 443)
                "intune.microsoft.us" = @(80, 443)
                "manage.microsoft.us" = @(80, 443)
                "portal.azure.us" = @(80, 443)
                "portal.office365.us" = @(80, 443)
                "portal.manage.microsoft.us" = @(80, 443)
                "sovereignprodimedatapri.azureedge.net" = @(80, 443)
                "sovereignprodimedatasec.azureedge.net" = @(80, 443)
                "sovereignprodimedatahotfix.azureedge.net" = @(80, 443)
                "syncservice.gov.us.microsoftonline.com" = @(80, 443)
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows 365 Enterprise" -circle "no"
            msrdReqURLCheck -urls $w365EntUrls
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows 365 Government" -circle "no"
            msrdReqURLCheck -urls $w365GovUrls
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Intune" -circle "no"
            msrdReqURLCheck -urls $w365IntuneUrls
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Intune Government" -circle "no"
            msrdReqURLCheck -urls $w365IntuneGovUrls
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }


}

function msrdCheckSiteURLStatus {
    Param([Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$URIkey, [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$URL)

    try {
        $request = Invoke-WebRequest -Uri $URL -UseBasicParsing -TimeoutSec 30

        if ($request) {
            if ($request.StatusCode -eq "200") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message $URIkey -Message2 "$URL" -Message3 "Reachable ($($request.StatusDescription) - $($request.StatusCode))" -circle "green"
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message $URIkey -Message2 "$URL" -Message3 "Not reachable ($($request.StatusDescription) - $($request.StatusCode))" -circle "red"
            }
        }
    } catch {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message $URIkey -Message2 "$URL" -Message3 "Not reachable" -circle "red"
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
    }
}

Function msrdDiagURIHealth {

    #AVD service URI diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "AVD Services URI Health"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "BrokerURICheck"

    $brokerURIregpath = "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\"

    if (Test-Path $brokerURIregpath) {
        $brokerURIregkey = "BrokerURI"
            if (msrdTestRegistryValue -path $brokerURIregpath -value $brokerURIregkey) {
                $brokerURI = Get-ItemPropertyValue -Path $brokerURIregpath -name $brokerURIregkey
                $brokerURI = $brokerURI + "api/health"
                msrdCheckSiteURLStatus $brokerURIregkey $brokerURI
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'$brokerURIregpath$brokerURIregkey' <span style='color: brown'>not found</span>. This machine doesn't seem to be a AVD VM or it is not configured properly." -circle "red"
            }

        $brokerURIGlobalregkey = "BrokerURIGlobal"
            if (msrdTestRegistryValue -path $brokerURIregpath -value $brokerURIGlobalregkey) {
                $brokerURIGlobal = Get-ItemPropertyValue -Path $brokerURIregpath -name $brokerURIGlobalregkey
                $brokerURIGlobal = $brokerURIGlobal + "api/health"
                msrdCheckSiteURLStatus $brokerURIGlobalregkey $brokerURIGlobal
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'$brokerURIregpath$brokerURIGlobalregkey' <span style='color: brown'>not found</span>. This machine doesn't seem to be a AVD VM or it is not configured properly." -circle "red"
            }

        $diagURIregkey = "DiagnosticsUri"
            if (msrdTestRegistryValue -path $brokerURIregpath -value $diagURIregkey) {
                $diagURI = Get-ItemPropertyValue -Path $brokerURIregpath -name $diagURIregkey
                $diagURI = $diagURI + "api/health"
                msrdCheckSiteURLStatus $diagURIregkey $diagURI
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'$brokerURIregpath$diagURIregkey' <span style='color: brown'>not found</span>. This machine doesn't seem to be a AVD VM or it is not configured properly." -circle "red"
            }

        $BrokerResourceIdURIGlobalregkey = "BrokerResourceIdURIGlobal"
            if (msrdTestRegistryValue -path $brokerURIregpath -value $diagURIregkey) {
                $BrokerResourceIdURIGlobal = Get-ItemPropertyValue -Path $brokerURIregpath -name $BrokerResourceIdURIGlobalregkey
                $BrokerResourceIdURIGlobal = $BrokerResourceIdURIGlobal + "api/health"
                msrdCheckSiteURLStatus $BrokerResourceIdURIGlobalregkey $BrokerResourceIdURIGlobal
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "'$brokerURIregpath$BrokerResourceIdURIGlobalregkey' <span style='color: brown'>not found</span>. This machine doesn't seem to be a AVD VM or it is not configured properly." -circle "red"
            }

    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagHCI {

    #AVD Azure Stack HCI diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Azure Stack HCI"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -Message "Azure Stack HCI" -DiagTag "HCICheck"

    if ($avdcheck) {
        msrdCheckServicePort -service GCArcService -skipWarning 1
        msrdCheckServicePort -service ExtensionService -skipWarning 1
        msrdCheckServicePort -service himds -skipWarning 1
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

function msrdAVDShortpathCheck {

    if ($global:avdnettestpath -ne "") {
        $avdok = $false
        try {
            cmd /c $global:avdnettestpath | Out-File "avdnettesttemp.txt"
            $avdout = Get-Content "avdnettesttemp.txt"
            Remove-Item "avdnettesttemp.txt" -Force

            $avdout = $avdout -split "`n" | Where-Object { $_ -ne "" }
            $avdpattern = '(?i)\b(?:https?://|www\.)\S+\b'

            if ($avdout) {
                foreach ($avdline in $avdout) {
                    if ($avdline -like "*AVD Network Test Version*") {
                        $aver = $avdline.Split(" ")[-1]
                        if (Test-Path -Path ($global:msrdLogDir + $avdnettestfile)) {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "AVD Network Test Version" -Message2 "$aver (See: <a href='$avdnettestfile' target='_blank'>avdnettest</a>)"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "AVD Network Test Version" -Message2 "$aver"
                        }
                    } elseif ($avdline -like "*...*") {
                        $avdc2 = $avdline.Split("... ")[-1]
                        $avdc1 = $avdline.Trimend($avdc2)
                        if ($avdc2 -like "*OK*") {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$avdc1" -Message2 "$avdc2" -circle "green"
                        } else {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$avdc1" -Message2 "$avdc2" -circle "red"
                        }
                    } elseif (($avdline -like "*cone shaped*") -or ($avdline -like "*you have access to TURN servers*")) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdline" -circle "green"
                        $avdok = $true
                    } else {
                        if ($avdline -match $avdpattern) {
                            $avdreplace = "<a href='https://go.microsoft.com/fwlink/?linkid=2204021' target='_blank'>https://go.microsoft.com/fwlink/?linkid=2204021</a>"
                            $avdline = $avdline -replace $avdpattern, $avdreplace
                        }

                        if ($avdok) {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdline" -circle "green"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdline" -circle "red"
                        }
                    }
                }
            }

        } catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
            Continue
        }
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        $notfoundmsg = "avdnettest.exe could not be found. Skipping check. Information on RDP Shortpath for AVD availability will be incomplete. Make sure you download and unpack the full package of MSRD-Collect or TSS."
        if ($global:msrdGUI) {
            msrdAddOutputBoxLine ("$notfoundmsg") "Magenta"
        } else {
            msrdLogMessage $LogLevel.Warning $notfoundmsg
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$notfoundmsg" -circle "red"
    }
}

Function msrdDiagShortpath {

    #AVD Shortpath diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "RDP Shortpath"
    if ($global:msrdW365) { $menucatmsg = "AVD/W365 Infra" } else { $menucatmsg = "AVD Infra" }
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "UDPCheck"

    if ($global:msrdSource) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client\' -RegKey 'fClientDisableUDP'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableUDPTransport'
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    }

    If (!($global:msrdOSVer -like "*Server*2008*")) {
        #Checking if there are Firewall rules for UDP 3390
        $fwrulesUDP = (Get-NetFirewallPortFilter -Protocol UDP | Where-Object { $_.localport -eq '3390' } | Get-NetFirewallRule)
        if ($fwrulesUDP.count -eq 0) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for UDP port 3390" -Message2 "not found"
        } else {
            if (Test-Path $fwrfile) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for UDP port 3390" -Message "found (See: <a href='$fwrfile' target='_blank'>FirewallRules</a>)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall rule(s) for UDP port 3390" -Message2 "found"
            }
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        # Checking Teredo configuration
        $teredo = Get-NetTeredoConfiguration
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Teredo configuration" -circle "no"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Type" -Message3 "$($teredo.Type)"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ServerName" -Message3 "$($teredo.ServerName)"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "RefreshIntervalSeconds" -Message3 "$($teredo.RefreshIntervalSeconds)"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ClientPort" -Message3 "$($teredo.ClientPort)"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ServerVirtualIP" -Message3 "$($teredo.ServerVirtualIP)"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "DefaultQualified" -Message3 "$($teredo.DefaultQualified)"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ServerShunt" -Message3 "$($teredo.ServerShunt)"
    }

    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

        if ($avdcheck) {
            #Checking for events 131 in the past 5 days
            $StartTimeSP = (Get-Date).AddDays(-5)
            If (Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV/Operational"; id="131"; StartTime=$StartTimeSP} -MaxEvents 1 -ErrorAction SilentlyContinue | where-object { $_.Message -like '*UDP*' }) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "UDP events 131 <span style='color: green'>have been found</span> in the 'Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV/Operational' event logs" -Message2 "RDP Shortpath <span style='color: green'>has been used</span> within the last 5 days" -circle "green"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "UDP events 131 <span style='color: brown'>have not been found</span> in the 'Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV/Operational' event logs" -Message2 "RDP Shortpath <span style='color: brown'>has not been used</span> within the last 5 days"
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "RDP Shortpath for <span style='color: blue'>managed</span> networks" -circle "no"
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fUseUdpPortRedirector' -RegValue '1' -OptNote 'Computer Policy: Enable RDP Shortpath for managed networks'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'UdpRedirectorPort' -RegValue '3390' -OptNote 'Computer Policy: Enable RDP Shortpath for managed networks'

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            # Checking if TermService is listening for UDP
            $udplistener = Get-NetUDPEndpoint -OwningProcess ((get-ciminstance win32_service -Filter "name = 'TermService'").ProcessId) -LocalPort 3390 -ErrorAction SilentlyContinue

            if ($udplistener) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "TermService is listening on UDP port 3390."
            } else {
                # Checking the process occupying UDP port 3390
                $procpid = (Get-NetUDPEndpoint -LocalPort 3390 -LocalAddress 0.0.0.0 -ErrorAction SilentlyContinue).OwningProcess

                if ($procpid) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "TermService is NOT listening on UDP port 3390. RDP Shortpath is not configured properly. The UDP port 3390 is being used by" -circle "red"
                    tasklist /svc /fi "PID eq $procpid" | Out-File -Append $msrdDiagFile
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No process is listening on UDP port 3390. RDP Shortpath for managed networks is not enabled."
                }
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "RDP Shortpath for <span style='color: blue'>public</span> networks" -circle "no"
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'SelectTransport' -RegValue '0' -OptNote 'Computer Policy: Select RDP transport protocols'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' -RegKey 'ICEControl'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'ICEEnableClientPortRange'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'ICEClientPortBase'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'ICEClientPortRange'

        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
        }
    }

    #Checking STUN server connectivity and NAT type
    if ($global:msrdAVD -or $global:msrdW365) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdAVDShortpathCheck
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion AVD Infra functions


#region AD functions

Function msrdDiagEntraJoin {

    #Microsoft Entra join diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Microsoft Entra Join"
    $menucatmsg = "Active Directory"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "AADJCheck"

    if (!($global:msrdOSVer -like "*Server*2008*") -and !($global:msrdOSVer -like "*Server*2012*")) {
        try {
            $script:DsregCmdStatus = dsregcmd /status
        } catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An error occurred during 'dsregcmd /status'. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
            Continue
        }

        Function msrdGetDsregcmdInfo {
            Param([Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$dsregentry, [switch]$file = $false)

            $global:msrdSetWarning = $false
            $menuitemmsg = "Microsoft Entra Join"
            $menucatmsg = "Active Directory"

            foreach ($entry in $script:DsregCmdStatus) {
                $ds1 = $entry.Split(":")[0]
                $ds1 = $ds1.Trim()
                if ($ds1 -like "*$dsregentry*") {
                    $ds2 = $entry -split ":" | Select-Object -Skip 1
                    if (($ds2 -like "*FAILED*") -or ($ds2 -like "*Error*")) { $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $dsregcircle = "red" } else { $dsregcircle = "white" }
                    if ($file) {
                        if (Test-Path ($global:msrdLogDir + $dsregfile)) {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message $ds1 -Message2 "$ds2" -Message3 "(See: <a href='$dsregfile' target='_blank'>Dsregcmd</a>)" -circle $dsregcircle
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message $ds1 -Message2 "$ds2" -circle $dsregcircle
                        }
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message $ds1 -Message2 "$ds2" -circle $dsregcircle
                    }
                }
            }

            if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
        }

        if ($script:DsregCmdStatus) {
            msrdGetDsregcmdInfo 'AzureAdJoined' -file
            msrdGetDsregcmdInfo 'WorkplaceJoined'
            msrdGetDsregcmdInfo 'DeviceAuthStatus'
            msrdGetDsregcmdInfo 'TenantName'
            msrdGetDsregcmdInfo 'TenantId'
            msrdGetDsregcmdInfo 'DeviceID'
            msrdGetDsregcmdInfo 'DeviceCertificateValidity'
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u\' -RegKey 'AllowOnlineID' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\' -RegKey 'AzureVmComputeMetadataEndpoint' -RegValue 'http://169.254.169.254/metadata/instance/compute'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\' -RegKey 'AzureVmMsiTokenEndpoint' -RegValue 'http://169.254.169.254/metadata/identity/oauth2/token'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\' -RegKey 'AzureVmTenantIdEndpoint' -RegValue 'http://169.254.169.254/metadata/identity/info'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin\' -RegKey 'BlockAADWorkplaceJoin'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin\' -RegKey 'autoWorkplaceJoin'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\IdentityStore\LoadParameters\{B16898C6-A148-4967-9171-64D755DA8520}\' -RegKey 'Enabled'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdGetDCInfo {

        Try {
            $vmdomain = [System.Directoryservices.Activedirectory.Domain]::GetComputerDomain()
            $trusteddc = nltest /sc_query:$vmdomain

            foreach ($entry in $trusteddc) {
                if (!($entry -like "The command completed*") -and !($entry -like "*correctement*") -and !($entry -like "*correctamente*") -and !($entry -like "*Befehl wurde *")) {
                    if (($entry -like "*Trusted DC Name*") -or ($entry -like "*Nom du contrôleur de domaine approuvé*") -or ($entry -like "*Nombre DC de confianza*") -or ($entry -like "*Vertrauenswürdiger Domänencontrollername*")) {
                        $tdcn = $entry.Split(" ")[3]
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Trusted DC Name" -Message2 "$tdcn"
                    } elseif (($entry -like "*Connection Status*") -or ($entry -like "*Statut de la connexion*") -or ($entry -like "*Estado de conexión*")) {
                        $tdccs = $entry.Split(" ")[-1]
                        if ($tdccs -like "*Success*") {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Trusted DC Connection Status" -Message2 "$tdccs" -circle "green"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Trusted DC Connection Status" -Message2 "$tdccs"
                        }
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$entry"
                    }
                }
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            $alldc = nltest /dnsgetdc:$vmdomain
            foreach ($dcentry in $alldc) {
                if (!($dcentry -like "The command completed*") -and !($dcentry -like "*correctement*") -and !($dcentry -like "*correctamente*") -and !($dcentry -like "*Befehl wurde *")) {
                    if (($dcentry -like "*DCs in pseudo-random order*") -or ($dcentry -like "*Site specific*") -or ($dcentry -like "*dans un ordre pseudo*") -or ($dcentry -like "*Nom spécifique*") -or ($dcentry -like "*en orden pseudoaleatorio*") -or ($dcentry -like "*específico del*") -or ($dcentry -like "*Liste der Domänencontroller in*") -or ($dcentry -like "*standortspezifisch*")) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$dcentry" -circle "no"
                    } else {
                        $dc0 = $dcentry.split(" ")[0]
                        $dc1 = $dcentry.split(" ")[1]
                        $dc2 = $dcentry.split(" ")[2]
                        if (($dc0 -eq "") -and ($dc1 -eq "") -and ($dc2 -eq "")) {
                            $dcfqdn = $dcentry.split(" ")[3]
                            $dcip = $dcentry.TrimStart("$dc0 + $dc1 + $dc2")
                            $dcip2 = $dcip.TrimStart("$dcfqdn")
                            if ($dcip2) {
                                $dcip2 = $dcip2.TrimStart()
                                if ($global:msrdLiveDiag) { $dcip2 = $dcip2 -replace '\s+', ' / ' } else { $dcip2 = $dcip2 -replace '\s+', '<br>' }
                            }

                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$dcfqdn" -Message3 "$dcip2"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "$dcentry"
                        }
                    }
                }
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            $alltrust = nltest /domain_trusts /all_trusts
            foreach ($trustentry in $alltrust) {
                if (!($trustentry -like "The command completed*") -and !($trustentry -like "*correctement*") -and !($trustentry -like "*correctamente*") -and !($trustentry -like "*Befehl wurde *")) {
                    if (($trustentry -like "*List of domain trusts*") -or ($trustentry -like "*Liste des approbations*")) {
                        if (Test-Path ($global:msrdLogDir + $domtrustfile)) {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$trustentry" -Message2 "(See: <a href='$domtrustfile' target='_blank'>Nltest-domtrust</a>)"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$trustentry"
                        }
                    } else {
                        $trust1 = $trustentry.split("(")[0]; if ($trust1) { $trust1 = $trust1.TrimStart() }
                        $trust2 = $trustentry.trimstart($trust1)
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$trust1" -Message3 "$trust2"
                    }
                }
            }
        } Catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An error occurred while trying to retrieve DC information. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
        }
}

Function msrdDiagDC {

    #Domain diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Domain"
    $menucatmsg = "Active Directory"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "DCCheck"

    if ($script:isDomain) {

        Try {
            $outcmd = Test-ComputerSecureChannel -Verbose 4>&1
            foreach ($outopt in $outcmd) {
                if ($outopt -like "False") {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1"-Message "Domain secure channel connection" -Message2 "$outopt" -circle "red"
                } elseif ($outopt -like "True") {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Domain secure channel connection" -Message2 "$outopt" -circle "green"
                } elseif ($outopt -like "*broken*") {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$outopt" -circle "red"
                } elseif (($outopt -like "*good condition*") -or ($outopt -like "*guten Zustand*")) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$outopt" -circle "green"
                } elseif (!($outopt -like "*Performing the operation*") -and !($outopt -like "*Ausführen des Vorgangs*")) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$outopt"
                }
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        } Catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not test secure channel connection. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        }

        msrdGetDCInfo

    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "This machine is not joined to a domain." -circle "yellow"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion AD functions


#region Networking functions

Function msrdGetDNSInfo {

    Try {
        $dnsip = Get-DnsClientServerAddress -AddressFamily IPv4
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Local network interface DNS configuration" -circle "no"
        foreach ($entry in $dnsip) {
            if (!($entry.InterfaceAlias -like "Loopback*")) {
                $ip = $entry.ServerAddresses
                if ($global:msrdLiveDiag) { $ip = $ip -join " / " } else { $ip = $ip -join "<br>" }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($entry.InterfaceAlias)" -Message3 "$ip"
            }
        }
    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        Continue
    }

    Try {
        $vmdomain = [System.Directoryservices.Activedirectory.Domain]::GetComputerDomain()

        if ($vmdomain) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            $dcdns = $vmdomain | ForEach-Object {$_.DomainControllers} |
                ForEach-Object {
                    $hostEntry= [System.Net.Dns]::GetHostByName($_.Name)
                    New-Object -TypeName PSObject -Property @{
                            Name = $_.Name
                            IPAddress = $hostEntry.AddressList[0].IPAddressToString
                        }
                    } | Select-Object Name, IPAddress

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "DNS servers available in the domain '$($vmdomain.Name)'" -circle "no"
            foreach ($dcentry in $dcdns) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($dcentry.Name)" -Message3 "$($dcentry.IPAddress)"
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
			msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not retrieve DNS servers in the domain. This machine is not joined to a domain." -circle "yellow"
        }
    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
    }
}

Function msrdDiagDNS {

    #DNS diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "DNS"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "DNSCheck"

    msrdGetDNSInfo

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\' -RegKey 'EnableNetbios' -OptNote 'Computer Policy: Configure NetBIOS settings'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdGetFirewallInfo {

    msrdCheckServicePort -service mpssvc

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $FWProfiles = Get-NetFirewallProfile -PolicyStore ActiveStore

    if (Test-Path ($global:msrdLogDir + $fwrfile)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Windows Firewall profiles" -Message2 "(See: <a href='$fwrfile' target='_blank'>FirewallRules</a>)"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Windows Firewall profiles"
    }

    $FWProfiles | ForEach-Object -Process {
        If ($_.Enabled -eq "True") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($_.Name) profile" -Message3 "Enabled" -circle "green"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($_.Name) profile" -Message3 "Disabled" -circle "yellow"
        }
    }

    Try {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        $3fw = Get-CimInstance -NameSpace "root\SecurityCenter2" -Query "select * from FirewallProduct" -ErrorAction SilentlyContinue
        if ($3fw) {
            foreach ($3fwentry in $3fw) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Third party firewall found: $($3fwentry.displayName)"
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Third party firewall(s) <span style='color: brown'>not found</span>"
        }

    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An error occurred while trying to retrieve third party firewall information. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
        Continue
    }
}

Function msrdDiagFirewall {

    #Firewall diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Firewall"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "FWCheck"

    msrdGetFirewallInfo

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagProxy {

    #Proxy diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Proxy"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "ProxCheck"

    
    msrdCheckServicePort -service WinHttpAutoProxySvc
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    $binval = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name WinHttpSettings).WinHttPSettings
    $proxylength = $binval[12]
    if ($proxylength -gt 0) {
        $proxy = -join ($binval[(12+3+1)..(12+3+1+$proxylength-1)] | ForEach-Object {([char]$_)})
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "NETSH WINHTTP proxy is configured" -Message2 "$proxy" -circle "red"
        $bypasslength = $binval[(12+3+1+$proxylength)]

        if ($bypasslength -gt 0) {
            $bypasslist = -join ($binval[(12+3+1+$proxylength+3+1)..(12+3+1+$proxylength+3+1+$bypasslength)] | ForEach-Object {([char]$_)})
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Bypass list" -Message2 "$bypasslist" -circle "red"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Bypass list" -Message2 "<span style='color:red'>Not configured</span>" -circle "red"
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "NETSH WINHTTP proxy configuration" -Message2 "not found"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

    # Query for the WPAD records
    $dnsResult = Resolve-DnsName -Name "wpad" -ErrorAction SilentlyContinue

    if ($dnsResult) {
        $CNAMEdnsResult = $dnsResult | Where-Object { $_.QueryType -eq "CNAME" }
        $AdnsResult = $dnsResult | Where-Object { $_.QueryType -eq "A" }

        if ($CNAMEdnsResult) {
            $CNAMEname = $CNAMEdnsResult.Name
		    $CNAMEnameHost = $CNAMEdnsResult.NameHost
            $CNAMEttl = $CNAMEdnsResult.TTL
        } else {
            $CNAMEname = "N/A"
			$CNAMEnameHost = "N/A"
			$CNAMEttl = "N/A"
        }
        
        if ($AdnsResult) {
            $Aname = $AdnsResult.Name
            $AipAddress = $AdnsResult.IPAddress
            $Attl = $AdnsResult.TTL
        } else {
            $Aname = "N/A"
			$AipAddress = "N/A"
			$Attl = "N/A"
        }

		$global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "WPAD (CNAME record)" -Message2 "$CNAMEname ($CNAMEnameHost)" -Message3 "TTL: $CNAMEttl" -circle "red"
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "WPAD (A record)" -Message2 "$Aname ($AipAddress)" -Message3 "TTL: $Attl" -circle "red"
	} else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "WPAD (CNAME record)" -Message2 "not found"
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "WPAD (A record)" -Message2 "not found"
	}

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    function GetBitsadmin {
        Param([string]$batype)

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Device-wide IE proxy configuration ($batype)" -circle "no"
        $outcmd = bitsadmin /util /getieproxy $batype
        foreach ($outopt in $outcmd) {
            if (($outopt -like "*Proxy usage:*") -or ($outopt -like "*Auto discovery script URL:*") -or ($outopt -like "*Proxy list:*") -or ($outopt -like "*Proxy bypass:*")) {
                $p1 = $outopt.Split(":")[0]
                $p2 = $outopt.Trim($p1 + ": ")
                if ($p2 -like "*AUTODETECT*") {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 $p1 -Message3 "$p2"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 $p1 -Message3 "$p2" -circle "red"
                }
            }
        }
    }

    GetBitsadmin "LOCALSERVICE"
    GetBitsadmin "LOCALSYSTEM"
    GetBitsadmin "NETWORKSERVICE"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'DisableProxyAuthenticationSchemes'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxyEnable' -RegValue "0"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxyEnable' -RegValue "0"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxyServer' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxyServer' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxyOverride'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxyOverride'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'AutoConfigURL' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'AutoConfigURL' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\' -RegKey 'WinHttpSettings'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\' -RegKey 'DefaultConnectionSettings'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\' -RegKey 'DisableWpad'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\' -RegKey 'TcpAutotuning'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxySettingsPerUser' -OptNote "Computer Policy: Make proxy settings per-machine (rather than per-user)"
    msrdCheckRegKeyValue -RegPath 'HKU:\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\' -RegKey 'ProxyEnable' -RegValue "0"
    msrdCheckRegKeyValue -RegPath 'HKU:\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\' -RegKey 'DefaultConnectionSettings'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'ProxySettings' -OptNote 'Computer Policy: Configure address or URL of proxy server' -addWarning -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'ProxySettings' -OptNote 'User Policy: Configure address or URL of proxy server' -addWarning -warnColor "yellow"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation\' -RegKey 'DProxiesAuthoritive' -OptNote 'Computer Policy: Proxy definitions are authoritative' -addWarning -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation\' -RegKey 'DomainProxies' -OptNote 'Computer Policy: Internet proxy servers for apps' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation\' -RegKey 'DomainLocalProxies' -OptNote 'Computer Policy: Intranet proxy servers for apps' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation\' -RegKey 'CloudResources' -OptNote 'Computer Policy: Enterprise resource domains hosted in the cloud' -addWarning -warnColor "yellow"

    #zscaler
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    try {
        $ZScalerCheck = Invoke-RestMethod -Uri "https://ip.zscaler.com" -Method Get -TimeoutSec 30

        if ($ZScalerCheck) {
            $ZScalerResponse = [regex]::Match($ZScalerCheck, '<div class="headline">(.*?)</div>').Groups[1].Value -replace '<span.*?>(.*?)</span>', '$1'.Trim()
            $ZScalerDetails = [regex]::Match($ZScalerCheck, '<div class="details">(.*?)</div>').Groups[1].Value -replace '<span.*?>(.*?)</span>', '$1'.Trim()

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "ZScaler information (based on <a href='https://ip.zscaler.com' target='_blank'>https://ip.zscaler.com</a>)" -circle "no"
            if ($ZscalerResponse -like "*you are not going through the Zscaler proxy service*") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "[ZScaler reply] $ZScalerResponse" -circle "green"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "[ZScaler reply] $ZScalerResponse" -circle "red"
            }
            $zs = $false
            foreach ($Zitem in $ZScalerDetails) {
                if ($Zitem -like "*You are accessing the Internet via Zscaler*") {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    $zs = $true
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "[ZScaler reply] $Zitem" -circle "red"
                } elseif ($zs) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "[ZScaler reply] $Zitem" -circle "red"
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "[ZScaler reply] $Zitem" -circle "green"
                }
            }

        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "ZScaler information (based on <a href='https://ip.zscaler.com' target='_blank'>https://ip.zscaler.com</a>) could not be retrieved." -circle "red"
        }
    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        $zerrmsg = "$($_.CategoryInfo.Reason): $($_.Exception.Message)"

        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An error occurred during the ZScaler usage check ($zerrmsg). See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
    }

    #checking for proxy in nslookup wpad
    $nslookupOutput = nslookup wpad 2>$null
    $outputLines = $nslookupOutput -split "`r`n"
    $server = ""
    $address = ""
    $proxyEntries = @()

    # Process each line of the output
    $index = 0
    while ($index -lt $outputLines.Length) {
        $line = $outputLines[$index]
        if ($line -match '^Server:') {
            $server = $line -replace '^Server:\s+', ''
            $address = $outputLines[$index + 1] -replace '^Address:\s+', ''
        }
        elseif ($line -match '^Name:\s+proxy') {
            $name = $line -replace '^Name:\s+', ''
            $addressAndAliases = @($outputLines[($index + 1)..($index + 3)] -replace 'Address:\s{2}', 'Address: ' -replace 'Aliases:\s{2}', 'Aliases: ')
            $proxyEntries += @{
                Name = $name
                AddressAndAliases = $addressAndAliases
            }
        }

        $index++
    }

    # Output the extracted data
    if ($proxyEntries.Count -gt 0) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Found proxy reference in nslookup output"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "Server: $server ($address)"
        foreach ($entry in $proxyEntries) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "Name: $($entry.Name) ($($entry.AddressAndAliases[0])) - $($entry.AddressAndAliases[1..($entry.AddressAndAliases.Length - 1)])"
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagNWCore {

    $global:msrdSetWarning = $false
    $menuitemmsg = "Core NET"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "NWCCheck"

    msrdCheckServicePort -service lmhosts -stopWarning #TCP/IP NetBIOS Helper
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Rpc\Internet\' -RegKey 'Ports'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Rpc\Internet\' -RegKey 'PortsInternetAvailable'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Rpc\Internet\' -RegKey 'UseInternetPorts'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectionStatusIndicator\' -RegKey 'NoActiveProbe' -RegValue 0
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\NlaSvc\Parameters\Internet\' -RegKey 'EnableActiveProbing' -RegValue 1
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'DefaultTTL'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'DhcpNameServer'
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'MaxUserPort'
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'KeepAliveInterval'
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'KeepAliveTime'
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'TcpMaxDataRetransmissions' -RegValue '5'
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'TcpNumConnections'
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'TcpTimedWaitDelay'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\' -RegKey 'MaxNegativeCacheTtl'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NetLogon\Parameters\' -RegKey 'NegativeCachePeriod'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\' -RegKey 'AlwaysExpectDomainController'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagRouting {

    $global:msrdSetWarning = $false
    $menuitemmsg = "Routing"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "RoutingCheck"

    #route
    if ((Test-Path ($global:msrdLogDir + $routefile)) -and (-not $global:msrdLiveDiag)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Route information" -Message3 "(See: <a href='$routefile' target='_blank'>Route</a>)"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    }

    #default gateway
    $defaultGateway = Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Select-Object -ExpandProperty NextHop
    if ($global:msrdLiveDiag) { $defaultGateway = $defaultGateway -join " / " } else { $defaultGateway = $defaultGateway -join "<br>" }
    if ($defaultGateway) {
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Default gateway" -Message2 "$defaultGateway"
	} else {
		$global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Default gateway could not be retrieved." -circle "red"
	}

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\' -RegKey 'IpEnableRouter'
    msrdCheckRegKeyValue -RegPath 'HKLM:\Software\Policies\Microsoft\Windows\TCPIP\v6Transition\' -RegKey 'force_Tunneling'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagIPAddresses {

    #IP address diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "IP Addresses"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "PublicIPCheck"

    if ((Test-Path ($global:msrdLogDir + $ipcfgfile)) -and (-not $global:msrdLiveDiag)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Local IP addresses" -Message2 "(See: <a href='$ipcfgfile' target='_blank'>Ipconfig</a>)"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Local IP addresses" -circle "no"
    }

    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=true" -ErrorAction SilentlyContinue
    if ($networkAdapters) {
        foreach ($adapter in $networkAdapters) {
            $adapterName = $adapter.Description
            $ipAddresses = $adapter.IPAddress
            $adapterId = $adapter.SettingID
            $connectionProfile = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.InstanceID -eq $adapterId }
            if ($connectionProfile) {
                $networkName = $connectionProfile.Name
                $networkCategory = $connectionProfile.NetworkCategory
            } else {
                $networkName = "N/A"
                $networkCategory = "N/A"
            }

            if ($global:msrdLiveDiag) { $ipAddresses = $ipAddresses -join " / " } else { $ipAddresses = $ipAddresses -join "<br>" }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$adapterName (Network: $networkName - Category: $networkCategory)" -Message3 $ipAddresses
        }
    } else {
		$global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Could not find any network adapters with associated IP addresses." -circle "red"
    }
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Public IP information (based on <a href='https://ipinfo.io/json' target='_blank'>https://ipinfo.io/json</a>)" -circle "no"

    try {
        $pubip = Invoke-RestMethod -Uri "https://ipinfo.io/json" -Method Get -TimeoutSec 30

        if ($pubip) {
            foreach ($pip in $pubip) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Public IP" -Message3 "$($pubip.ip)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "City/Region" -Message3 "$($pubip.city)/$($pubip.region)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Country" -Message3 "$($pubip.country)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Organization" -Message3 "$($pubip.org)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Timezone" -Message3 "$($pubip.timezone)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            }
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Public IP information could not be retrieved." -circle "red"
        }

    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Public IP information could not be retrieved. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}


Function msrdDiagPortUsage {

    #Top 5 TCP/UDP consumers
    $global:msrdSetWarning = $false
    $menuitemmsg = "Port Usage"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "PortUsageCheck"

    #Function to get services for svchost process
    function GetSvchostServices {
        param ($ProcessId)

        $tasklistOutput = tasklist /svc /fi "imagename eq svchost.exe" | findstr /C:"$ProcessId"
        ($tasklistOutput -split '\s+', 3)[-1].Trim()
    }

    # Function to process netstat output
    function GetNetstatProcesses {
        param ($Protocol)

        netstat -anobq | Select-String $Protocol | ForEach-Object {
            $line       = $_.Line -split '\s+'
            $processId  = $line[-1]
            $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName

            if ($processName -notin 'Idle', 'System') {
                $port = $line[2] -replace '(.+):(\d+)', '$2'
                $properties = @{
                    Protocol = $Protocol
                    ProcessName = if ($processName -eq 'svchost') {
                        "svchost ($(GetSvchostServices -ProcessId $processId))"
                    } else {
                        $processName
                    }
                    ProcessId = $processId
                    Port = $port
                }

                [PSCustomObject]$properties
            }
        } | Group-Object ProcessName | ForEach-Object {
            $processName = $_.Name
            $uniqueProcessIds = $_.Group.ProcessId | Select-Object -Unique
            $uniquePorts = $_.Group.Port | Select-Object -Unique
            $totalPortCount = $uniquePorts.Count
            $individualCounts = $_.Group | Group-Object ProcessId | ForEach-Object {
                    "$($_.Name)"
            }
            [PSCustomObject]@{
                Protocol = $Protocol
                ProcessName = "$processName"
                ProcessPortCount = "is using a total of $totalPortCount $($Protocol) $(If ($totalPortCount -eq 1) { 'port' } else { 'ports' })"
                ProcessPIDs = "across $($individualCounts.Count) PID$(If ($individualCounts.Count -eq 1) { '' } else { 's' }) ($($individualCounts -join ', '))"
                Count = $totalPortCount
            }

        } | Sort-Object Count -Descending | Select-Object -First 5
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "These values represent a snapshot of the system's status at the time the script was executed and are intended only as a reference point. Keep in mind that network port usage can fluctuate rapidly, and the information may change in a matter of seconds." -circle "no"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

    $tcpData = Get-NetTCPConnection -ErrorAction SilentlyContinue
    if ($tcpData) {
        $totalTCPPorts = ($tcpData | Group-Object LocalPort).Count
        $totalTCPPortsBound = ($tcpData | Where-Object { $_.State -eq 'Bound' } | Group-Object LocalPort).Count
        $totalTCPPortsTimeWait = ($tcpData | Where-Object { $_.State -eq 'TimeWait' } | Group-Object LocalPort).Count
        $totalTCPPortsCloseWait = ($tcpData | Where-Object { $_.State -eq 'CloseWait' } | Group-Object LocalPort).Count

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Total TCP ports in use across all local IP addresses" -Message2 "$totalTCPPorts"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Total TCP ports in BOUND state" -Message2 "$totalTCPPortsBound"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Total TCP ports in TIME_WAIT state" -Message2 "$totalTCPPortsTimeWait"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Total TCP ports in CLOSE_WAIT state" -Message2 "$totalTCPPortsCloseWait"

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Top 5 processes using the most TCP ports" -circle "no"

        $tcpProcesses = GetNetstatProcesses -Protocol 'TCP'
        if ($tcpProcesses) {
            $tcpProcesses | ForEach-Object {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "$($_.ProcessName)" -Message2 "$($_.ProcessPortCount)" -Message3 "$($_.ProcessPIDs)"
            }
        } else {
		    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No processes found using TCP ports"
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No TCP connections found"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    $udpData = Get-NetUDPEndpoint -ErrorAction SilentlyContinue
    if ($udpData) {
        $totalUDPPorts = ($udpData | Group-Object LocalPort).Count

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Total UDP Ports in use across all local IP addresses" -Message2 "$totalUDPPorts"

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
	    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Top 5 processes using the most UDP ports" -circle "no"

        $udpProcesses = GetNetstatProcesses -Protocol 'UDP'
	    if ($udpProcesses) {
		    $udpProcesses | ForEach-Object {
			    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "$($_.ProcessName)" -Message2 "$($_.ProcessPortCount)" -Message3 "$($_.ProcessPIDs)"
		    }
	    } else {
		    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No processes found using UDP ports"
	    }

    } else {
		msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No UDP connections found"
    }

	if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagVPN {

    #VPN diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "VPN"
    $menucatmsg = "Networking"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "VPNCheck"

    try {
        $vpn = Get-VpnConnection -ErrorAction Continue 2>>$global:msrdErrorLogFile
        if ($vpn) {
            foreach ($v in $vpn) {
                if (($v.ConnectionStatus -eq "Connected") -and ($v.IdleDisconnectSeconds -ne 0)) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    $vpncircle = "yellow"
                } else {
                    $vpncircle = "white"
                }
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Name" -Message2 "$($v.Name)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "ServerAddress" -Message2 "$($v.ServerAddress)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "DnsSuffix" -Message2 "$($v.DnsSuffix)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Guid" -Message2 "$($v.Guid)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "ConnectionStatus" -Message2 "$($v.ConnectionStatus)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "RememberCredentials" -Message2 "$($v.RememberCredential)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "SplitTunneling" -Message2 "$($v.SplitTunneling)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "IdleDisconnectSeconds" -Message2 "$($v.IdleDisconnectSeconds)" -circle $vpncircle
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "PlugInApplicationID" -Message2 "$($v.PlugInApplicationID)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "ProfileType" -Message2 "$($v.ProfileType)"
                if ($v.Proxy -and ($v.Proxy -ne "")) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Proxy" -Message2 "$($v.Proxy)" -circle $vpncircle
                } else {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message "Proxy" -Message2 "$($v.Proxy)"
                }

                if ($v -ne $vpn[-1]) { msrdLogDiag $LogLevel.DiagFileOnly -Type "HR" }
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "VPN connection profile information <span style='color: brown'>not found</span>"
        }

    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "VPN information could not be retrieved. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion Networking functions


#region Logon/Security functions

Function msrdDiagAuth {

    #Authentication/Logon diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Authentication / Logon"
    $menucatmsg = "Logon / Security"
    msrdLogDiag $LogLevel.Normal -DiagTag "AuthCheck" -Message $menuitemmsg

    $adminUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    if ($adminUser) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Script launched as" -Message2 "$adminUser ($global:msrdAdminlevel)"
    }
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Script user context" -Message2 "$global:msrdUserprof"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\Policies\Microsoft\Windows\System\' -RegKey 'DefaultCredentialProvider'

    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI') {
        if (msrdTestRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\' -Value 'LastLoggedOnProvider') {
            $logonprov = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI' -name "LastLoggedOnProvider"
            $credprovpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\$logonprov"
            if (Test-Path $credprovpath) {
                $credprov = Get-ItemPropertyValue -Path $credprovpath -name "(Default)"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Last Logged On Credential Provider used" -Message2 "$credprov"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Last Logged On Credential Provider used" -Message2 "<span style='color: brown'>not found</span>"
            }
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableWebAuthnRedirection'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisableWebAuthnRedirection'

    if ($global:msrdTarget) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableWebAuthn' -RegValue '0' -OptNote 'Computer Policy: Do not allow WebAuthn redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -RegKey 'bAllowFastReconnect'
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters\' -RegKey 'MaxTokenSize'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'AppSetup'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'AutoAdminLogon'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'ForceAutoLogon' -RegValue '0' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'ReportControllerMissing'

    if ($global:msrdTarget) {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -RegKey 'ProcessTSUserLogonAsync' -OptNote 'Computer Policy: Allow asynchronous user Group Policy processing when logging on through Remote Desktop Services'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fQueryUserConfigFromDC'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fQueryUserConfigFromLocalMachine'
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'AllowDefaultCredentials' -OptNote 'Computer Policy: Allow delegating default credentials' -linkToReg $regCredDelegationFile
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'AllowDefCredentialsWhenNTLMOnly' -OptNote 'Computer Policy: Allow delegating default credentials with NTLM-only server authentication' -linkToReg $regCredDelegationFile
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'DenyDefaultCredentials' -OptNote 'Computer Policy: Deny delegating default credentials' -linkToReg $regCredDelegationFile
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'AllowFreshCredentials' -OptNote 'Computer Policy: Allow delegating fresh credentials' -linkToReg $regCredDelegationFile
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'AllowFreshCredentialsWhenNTLMOnly' -OptNote 'Computer Policy: Allow delegating fresh credentials with NTLM-only server authentication' -linkToReg $regCredDelegationFile
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'DenyFreshCredentials' -OptNote 'Computer Policy: Deny delegating fresh credentials' -linkToReg $regCredDelegationFile
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'AllowSavedCredentials' -OptNote 'Computer Policy: Allow delegating saved credentials' -linkToReg $regCredDelegationFile
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'AllowSavedCredentialsWhenNTLMOnly' -OptNote 'Computer Policy: Allow delegating saved credentials with NTLM-only server authentication' -linkToReg $regCredDelegationFile
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'DenySavedCredentials' -OptNote 'Computer Policy: Deny delegating saved credentials' -linkToReg $regCredDelegationFile
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'RestrictedRemoteAdministration' -OptNote 'Computer Policy: Restrict delegation of credentials to remote servers'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'RestrictedRemoteAdministrationType' -OptNote 'Computer Policy: Restrict delegation of credentials to remote servers'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters\' -RegKey 'MaxTicketAge' -OptNote 'Computer Policy: Maximum lifetime for service ticket' -RegValue '600' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters\' -RegKey 'MaxUserTicketLifetime' -OptNote 'Computer Policy: Maximum lifetime for user ticket' -RegValue '10' -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters\' -RegKey 'MaxRenewAge' -OptNote 'Computer Policy: Maximum lifetime for user ticket renewal' -RegValue '7' -warnColor "yellow"

    #checking if there are stored entries in credential manager for MSTSC or AVD (source machine only)
    if ($global:msrdSource) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

        $credentialList = cmdkey /list
        $filteredCredentials = $credentialList | Where-Object { $_ -match "Target: .*TERMSRV.*|.*RDPClient.*" }

        if ($filteredCredentials) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "TERMSRV/RDPClient entries stored in Credential Manager for the current user"

            $redactedCredentials = $filteredCredentials -replace '(?<=:UID:)[^:]*|:UID:[^:]*', ''
            foreach ($cred in $redactedCredentials) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 $cred
            }
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No TERMSRV or RDPClient entries have been found stored in Credential Manager for the current user."
        }
        $credentialList = $null
        $filteredCredentials = $null
        $redactedCredentials = $null
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }


}

Function msrdGetAntivirusInfo {

    #get Antivirus information
    Try {
        $AVprod = (Get-CimInstance -Namespace root\SecurityCenter2 -Class AntiVirusProduct -ErrorAction SilentlyContinue).displayName | Select-Object -Unique

        if ($AVprod) {
            if (Test-Path ($global:msrdLogDir + $avinfofile)) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Antivirus software" -Message3 "(See: <a href='$avinfofile' target='_blank'>AntiVirusProducts</a>)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Antivirus software"
            }
            foreach ($AVPentry in $AVprod) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "$AVPentry"
            }
        } else {
            if ($global:msrdOSVer -like "*Windows*Server*") {
                $serverAV = Get-Service | Where-Object { $_.Name -like "*WinDefend*" }
                if ($serverAV) {
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Antivirus software" -circle "no"
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 "Windows Defender"
			    } else {
				    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
				    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Antivirus software installation <span style='color: brown'>not found or could not be retrieved</span>." -circle "yellow"
                }
			} else {
				$global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
				msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Antivirus software installation <span style='color: brown'>not found</span>." -circle "yellow"
            }
        }
    } Catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_

        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An error occurred while trying to retrieve Antivirus information. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
        Continue
    }

    If (!($global:msrdOSVer -like "*Server*2008*") -and !($global:msrdOSVer -like "*Server*2012*")) {
        $DefPreference = Get-MpPreference | Select-Object DisableAutoExclusions, RandomizeScheduleTaskTimes, SchedulerRandomizationTime, ProxyServer, ProxyPacUrl, ProxyBypass, ForceUseProxyOnly, ScanScheduleTime, ScanScheduleQuickScanTime, ScanOnlyIfIdleEnabled
        if ($DefPreference) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Defender settings" -circle "no"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3"  -Message2 "DisableAutoExclusions" -Message3 "$($DefPreference.DisableAutoExclusions)"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3"  -Message2 "RandomizeScheduleTaskTimes" -Message3 "$($DefPreference.RandomizeScheduleTaskTimes)"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3"  -Message2 "SchedulerRandomizationTime" -Message3 "$($DefPreference.SchedulerRandomizationTime)"

            if ($DefPreference.ProxyServer) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ProxyServer" -Message3 "$($DefPreference.ProxyServer)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ProxyServer" -Message3 "$($DefPreference.ProxyServer)"
            }

            if ($DefPreference.ProxyPacUrl) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ProxyPacUrl" -Message3 "$($DefPreference.ProxyPacUrl)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ProxyPacUrl" -Message3 "$($DefPreference.ProxyPacUrl)"
            }

            if ($DefPreference.ProxyBypass) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ProxyBypass" -Message3 "$($DefPreference.ProxyBypass)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ProxyBypass" -Message3 "$($DefPreference.ProxyBypass)"
            }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ForceUseProxyOnly" -Message3 "$($DefPreference.ForceUseProxyOnly)"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ScanScheduleTime" -Message3 "$($DefPreference.ScanScheduleTime)"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ScanScheduleQuickScanTime" -Message3 "$($DefPreference.ScanScheduleQuickScanTime)"
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "ScanOnlyIfIdleEnabled" -Message3 "$($DefPreference.ScanOnlyIfIdleEnabled)"
        }
    }
}

function msrdGetUserRights {

    #get User Rights policy information
    [array]$localrights = $null

    function msrdGetSecurityPolicy {

        # Fail script if we can't find SecEdit.exe
        $SecEdit = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::System)) "SecEdit.exe"
        if (-not (Test-Path $SecEdit)) {
            msrdLogException ("File not found - '$SecEdit'") -ErrObj $_
            return
        }
        # LookupPrivilegeDisplayName Win32 API doesn't resolve logon right display names, so use this hashtable
        $UserLogonRights = @{
"SeBatchLogonRight"				    = "Log on as a batch job"
"SeDenyBatchLogonRight"			    = "Deny log on as a batch job"
"SeDenyInteractiveLogonRight"	    = "Deny log on locally"
"SeDenyNetworkLogonRight"		    = "Deny access to this computer from the network"
"SeDenyRemoteInteractiveLogonRight" = "Deny log on through Remote Desktop Services"
"SeDenyServiceLogonRight"		    = "Deny log on as a service"
"SeInteractiveLogonRight"		    = "Allow log on locally"
"SeNetworkLogonRight"			    = "Access this computer from the network"
"SeRemoteInteractiveLogonRight"	    = "Allow log on through Remote Desktop Services"
"SeServiceLogonRight"			    = "Log on as a service"
}

        # Create type to invoke LookupPrivilegeDisplayName Win32 API
        $Win32APISignature = @'
[DllImport("advapi32.dll", SetLastError=true)]
public static extern bool LookupPrivilegeDisplayName(
string systemName,
string privilegeName,
System.Text.StringBuilder displayName,
ref uint cbDisplayName,
out uint languageId
);
'@

        $AdvApi32 = Add-Type advapi32 $Win32APISignature -Namespace LookupPrivilegeDisplayName -PassThru

        # Use LookupPrivilegeDisplayName Win32 API to get display name of privilege (except for user logon rights)

        function msrdGetPrivilegeDisplayName {
        param ([String]$name)

            $displayNameSB = New-Object System.Text.StringBuilder 1024
            $languageId = 0
            $ok = $AdvApi32::LookupPrivilegeDisplayName($null, $name, $displayNameSB, [Ref]$displayNameSB.Capacity, [Ref]$languageId)

            if ($ok) { $displayNameSB.ToString() }
            else {
                # Doesn't lookup logon rights, so use hashtable for that
                if ($UserLogonRights[$name]) { $UserLogonRights[$name] }
                else { $name }
            }
        }

        # Translates a SID in the form *S-1-5-... to its account name;
        function msrdGetAccountName {
        param ([String]$principal)

            try {
                $sid = New-Object System.Security.Principal.SecurityIdentifier($principal.Substring(1))
                $sid.Translate([Security.Principal.NTAccount])
            } catch { $principal }
        }

        $TemplateFilename = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        $LogFilename = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        $StdOut = & $SecEdit /export /cfg $TemplateFilename /areas USER_RIGHTS /log $LogFilename

        if ($LASTEXITCODE -eq 0) {
            $dtable = $null
            $dtable = New-Object System.Data.DataTable
            $dtable.Columns.Add("Privilege", "System.String") | Out-Null
            $dtable.Columns.Add("PrivilegeName", "System.String") | Out-Null
            $dtable.Columns.Add("Principal", "System.String") | Out-Null

            Select-String '^(Se\S+) = (\S+)' $TemplateFilename | Foreach-Object {
                $Privilege = $_.Matches[0].Groups[1].Value
                $Principals = $_.Matches[0].Groups[2].Value -split ','
                foreach ($Principal in $Principals) {
                    $nRow = $dtable.NewRow()
                    $nRow.Privilege = $Privilege
                    $nRow.PrivilegeName = msrdGetPrivilegeDisplayName $Privilege
                    $nRow.Principal = msrdGetAccountName $Principal
                    $dtable.Rows.Add($nRow)
                }
                return $dtable
            }
        } else {
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $StdOut") -ErrObj $_
        }
        Remove-Item $TemplateFilename, $LogFilename -ErrorAction SilentlyContinue
    }

    $localrights += msrdGetSecurityPolicy
    $localrights = $localrights | Select-Object Privilege, PrivilegeName, Principal -Unique | Where-Object { ($_.Privilege -like "*NetworkLogonRight") -or ($_.Privilege -like "*RemoteInteractiveLogonRight")}

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "User Rights policies" -circle "no"
    Foreach ($LR in $localrights) {
        if (!($LR -like "Privilege*")) {
            $lrprincipal = $LR.Principal
            $lrprivilege = $LR.Privilege
            if ($lrprivilege -like "*SeRemoteInteractiveLogonRight*") {
                if ($lrprincipal -like "*BUILTIN\Remote Desktop Users*" -or $lrprincipal -like "*BUILTIN\Administrators*") { $lrcircle = "green" } else { $lrcircle = "white" }
            } elseif ($lrprivilege -like "*SeDenyRemoteInteractiveLogonRight*") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                if ($lrprincipal -like "*BUILTIN\Remote Desktop Users*" -or $lrprincipal -like "*BUILTIN\Administrators*") { $lrcircle = "red" } else { $lrcircle = "yellow" }
            } else { $lrcircle = "white" }

            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($LR.PrivilegeName) ($lrprivilege)" -Message3 "$lrprincipal" -circle $lrcircle
        }
    }
}

Function msrdDiagSecurity {

    #Security diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Security"
    $menucatmsg = "Logon / Security"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "SecCheck"

    #check TPM
    $tpmInfo = Get-Tpm -ErrorAction SilentlyContinue | Select-Object TpmPresent, TpmReady, TpmEnabled, TpmActivated, TpmOwned, ManufacturerVersion
    $expectedProperties = @('TpmPresent', 'TpmReady', 'TpmEnabled', 'TpmActivated', 'TpmOwned', 'ManufacturerVersion')

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Trusted Platform Module (TPM)" -circle "no"
    foreach ($expectedProperty in $expectedProperties) {
        $property = $tpmInfo.PSObject.Properties | Where-Object { $_.Name -eq $expectedProperty }

        if ($property) { $tpmCircle = "green" } else { $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1; $tpmCircle = "white" }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($property.Name)" -Message3 "$($property.Value)" -circle $tpmcircle
    }

    $tmpwmi = (Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue).SpecVersion
    if ($tmpwmi) { $TpmSpecVersion = $tmpwmi; $tpmcircle = "green" } else { $TpmSpecVersion = "N/A"; $tpmcircle = "white" }

    if ($global:msrdLiveDiag) { msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer" }
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "SpecVersion" -Message3 "$TpmSpecVersion" -circle $tpmcircle

    #check secure boot
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    try {
        $secboot = Confirm-SecureBootUEFI
        if ($secboot) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Secure Boot" -Message3 "Enabled" -circle "green"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Secure Boot" -Message3 "Not enabled" -circle "yellow"
        }
    } catch {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "Secure Boot" -Message3 "Not supported" -circle "yellow"
    }

    #check Windows features
    If ($global:msrdTarget -and $global:msrdOSVer -notlike "*Server*2008*") {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        $winfeat = "IsolatedUserMode", "Containers-DisposableClientVM"
        foreach ($wf in $winfeat) {
            $winOptFeat = Get-WindowsOptionalFeature -Online -FeatureName "$wf" -ErrorAction SilentlyContinue
            if ($winOptFeat) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "$($winOptFeat.DisplayName)" -Message3 "$($winOptFeat.State)" -OptNote "$($winOptFeat.Description)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message "$wf" -Message3 "not found"
            }
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdGetAntivirusInfo  #get antivirus software information

    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdGetUserRights  #get user rights policies information
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    if ($global:msrdOSVer -like "*Windows Server*") {
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\' -RegKey 'DisableAntiSpyware' -RegValue 'false' -warnColor "yellow"

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\" -value "DisableAntiSpyware") {
            $key = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\" -name "DisableAntiSpyware"
            if ($key -eq "true") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "It is not recommended to disable Windows Defender, unless you are using another Antivirus software. See: $defenderRef" -circle "red"
            }
        }
    }

    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\' -RegKey 'ImpersonateCheckProtection' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\' -RegKey 'LmCompatibilityLevel'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\' -RegKey 'RestrictRemoteSam'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\' -RegKey 'RestrictRemoteSamAuditOnlyMode'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'DisableLockWorkstation' -OptNote 'Computer Policy: Remove Lock Computer'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters\' -RegKey 'AllowEncryptionOracle' -OptNote 'Computer Policy: Encryption Oracle Remediation'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters\' -RegKey 'SupportedEncryptionTypes' -OptNote 'Computer Policy: Network security: Configure encryption types allowed for Kerberos' -addWarning -warnColor "yellow"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard\' -RegKey 'EnableVirtualizationBasedSecurity' -OptNote 'Computer Policy: Turn On Virtualization Based Security (Device Guard)'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard\' -RegKey 'LsaCfgFlags' -OptNote 'Computer Policy: Turn On Virtualization Based Security (Device Guard)'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard\' -RegKey 'RequirePlatformSecurityFeatures' -OptNote 'Computer Policy: Turn On Virtualization Based Security (Device Guard)'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\' -RegKey 'EnableVirtualizationBasedSecurity'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\' -RegKey 'RequirePlatformSecurityFeatures'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\' -RegKey 'LsaCfgFlags'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'RestrictedRemoteAdministration' -OptNote 'Computer Policy: Restrict delegation of credentials to remote servers'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\' -RegKey 'RestrictedRemoteAdministrationType' -OptNote 'Computer Policy: Restrict delegation of credentials to remote servers'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\' -RegKey 'DisableRestrictedAdmin'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\' -RegKey 'AuditReceivingNTLMTraffic' -OptNote 'Computer Policy: Network security: Restrict NTLM: Audit Incoming NTLM Traffic'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\' -RegKey 'ClientAllowedNTLMServers' -OptNote 'Computer Policy: Network security: Restrict NTLM: Add remote server exceptions for NTLM authentication'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\' -RegKey 'RestrictReceivingNTLMTraffic' -OptNote 'Computer Policy: Network security: Restrict NTLM: Incoming NTLM traffic'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\' -RegKey 'RestrictSendingNTLMTraffic' -OptNote 'Computer Policy: Network security: Restrict NTLM: Outgoing NTLM traffic to remote servers'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\' -RegKey 'AuditNTLMInDomain' -OptNote 'Computer Policy: Network security: Restrict NTLM: Audit NTLM authentication in this domain'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\' -RegKey 'DCAllowedNTLMServers' -OptNote 'Computer Policy: Network security: Restrict NTLM: Add server exceptions in this domain'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\' -RegKey 'RestrictNTLMInDomain' -OptNote 'Computer Policy: Network security: Restrict NTLM: NTLM authentication in this domain'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Browser\' -RegKey 'AllowSmartScreen'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\device\Browser\AllowSmartScreen\' -RegKey 'value'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\SmartScreen\EnableSmartScreenInShell\' -RegKey 'value'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -RegKey 'SmartScreenEnabled'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'SmartScreenEnabled' -OptNote 'Computer Policy: Configure Microsoft Defender SmartScreen'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'SmartScreenEnabled' -OptNote 'User Policy: Configure Microsoft Defender SmartScreen'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -RegKey 'EnableSmartScreen' -OptNote 'Computer Policy: Configure Windows Defender SmartScreen'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Edge\' -RegKey 'SmartScreenEnabled'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop\' -RegKey 'ScreenSaveActive' -OptNote 'User Policy: Enable screen saver'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop\' -RegKey 'ScreenSaverIsSecure' -OptNote 'User Policy: Password protect the screen saver'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'ScreenSaverGracePeriod'

    if (($global:msrdAVD -or $global:msrdW365) -and $global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        if ($avdcheck) {
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableScreenCaptureProtect' -OptNote 'Computer Policy: Enable screen capture protection'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableWatermarking' -OptNote 'Computer Policy: Enable watermarking'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'WatermarkingHeightFactor' -OptNote 'Computer Policy: Enable watermarking'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'WatermarkingOpacity' -OptNote 'Computer Policy: Enable watermarking'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'WatermarkingQrScale' -OptNote 'Computer Policy: Enable watermarking'
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'WatermarkingWidthFactor' -OptNote 'Computer Policy: Enable watermarking'
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
        }
    }

    if ($script:registeredBrowsers -like "*Edge*") {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'ScreenCaptureAllowed' -RegValue '1' -OptNote 'Computer Policy: Allow or block screen capture'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\' -RegKey 'ScreenCaptureAllowed' -RegValue '1' -OptNote 'User Policy: Allow or block screen capture'
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\' -RegKey 'DisallowRun' -OptNote 'User Policy: Do not run specified Windows applications'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\' -RegKey 'RestrictRun' -OptNote 'User Policy: Run only specified Windows applications'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\System\' -RegKey 'DisableCMD' -OptNote 'User Policy: Prevent access to the command prompt'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx\' -RegKey 'BlockNonAdminUserInstall' -OptNote 'Computer Policy: Prevent non-admin users from installing packaged Windows apps' -addWarning

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'DisableRegistryTools' -OptNote 'User Policy: Prevent access to registry editing tools'
    msrdCheckRegKeyValue -RegPath 'HKU:\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'DisableRegistryTools'
    msrdCheckRegKeyValue -RegPath 'HKU:\S-1-5-18\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'DisableRegistryTools'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service AppIDSvc

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}


Function msrdDiagSmartCard {

    #Smartcard diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Smart Card"
    $menucatmsg = "Logon / Security"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "SCardCheck"

    function msrdDiagSmartCardDetails { #workaround due to unreliable Get-PnPEntity and Get-PnPDevice output in a remote session

        $output = certutil -scinfo -silent
        $output = $output -split "`n"

        # Find the index of the first occurrence of "======================================================="
        $separatorIndex = $output.IndexOf("=======================================================")

        if ($separatorIndex -ge 0) {
            # Filter out lines containing "ATR:" or lines with hex values separated by spaces
            $filteredLines = $output[0..($separatorIndex - 1)] | Where-Object { $_ -notmatch "ATR:" -and $_ -notmatch "(\b[0-9a-fA-F]{2}\b\s*)+" }

            # Remove empty lines and "---"
            $filteredLines = $filteredLines | Where-Object { $_ -ne '' }
            $output = ($filteredLines -replace "^---", "").Trim()

            return $output
        } else {
            return $output[0..2]
        }
    }

    $scdetails = msrdDiagSmartCardDetails

    # Iterate through each line of the output and process it as needed
    foreach ($line in $scdetails) {
        if ($line -like "Current reader*") {
            if (Test-Path ($global:msrdLogDir + $scinfofile)) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $line -Message2 "(See: <a href='$scinfofile' target='_blank'>SmartCardInfo</a>)"
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message $line -circle "no"
            }
        } elseif (($line -like "Readers:*") -or ($line -like "Reader:*") -or ($line -like "Status:*") -or ($line -like "Card:*")) {
            $value1 = $line.Split(":")[0]; if ($value1) { $value1 = $value1.Trim() }
            $value2 = $line.Split(":")[1]; if ($value2) { $value2 = $value2.Trim() }
            if ($line -like "Reader:*") {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message $value1 -Message2 $value2
        } elseif ($line -match "^\d+:") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message2 $line
        } elseif ($line -like "*is running*") {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message $line -circle "green"
        } elseif (($line -notlike "*CertUtil:*")) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message $line
        }
    }

    $scdetails = $null

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service SCardSvr
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service ScDeviceEnum -warnColor "yellow"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service SCPolicySvc -warnColor "yellow"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fEnableSmartCard' -RegValue '1' -OptNote 'Computer Policy: Do not allow smart card device redirection'
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Cryptography\Calais\' -RegKey 'TransactionTimeoutDelay'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Base Smart Card Crypto Provider\' -RegKey 'TransactionTimeoutMilliseconds'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Cryptography\Defaults\Provider\Microsoft Base Smart Card Crypto Provider\' -RegKey 'TransactionTimeoutMilliseconds'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Cryptography\Providers\Microsoft Smart Card Key Storage Provider\' -RegKey 'TransactionTimeoutMilliseconds'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion Logon/Security functions


#region Known Issues

Function msrdDiagIssues {
    Param([Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$IssueType, [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$LogName,
        [array]$LogID, [array]$Message, [array]$Provider, [string]$lvl, [string]$helpurl, [string]$evtxfile)

    #diagnostics of potential issues showing up in Event logs (based on messages)
    if ($lvl -eq "Full") { $evlvl = @(1,2,3,4) } elseif ($lvl -eq "None") { $evlvl = @(0) } else { $evlvl = @(1,2,3) }

    msrdLogDiag $LogLevel.Info -Message "[Diag] '$IssueType' issues in '$LogName' event logs"

    $StartTimeA = (Get-Date).AddDays(-5)
    if ($LogID) { $geteventDiag = Get-WinEvent -FilterHashtable @{logname="$LogName"; id=$LogID; StartTime=$StartTimeA; Level=$evlvl} -ErrorAction SilentlyContinue }
    else { $geteventDiag = Get-WinEvent -FilterHashtable @{logname="$LogName"; StartTime=$StartTimeA; Level=$evlvl} -ErrorAction SilentlyContinue }

    if ($IssueType -eq "Agent") { $issuefile = "MSRD-Diag-AgentIssues.txt" }
    elseif ($IssueType -eq "MSIXAA") { $issuefile = "MSRD-Diag-MSIXAAIssues.txt" }
    elseif ($IssueType -eq "FSLogix") { $issuefile = "MSRD-Diag-FSLogixIssues.txt" }
    elseif ($IssueType -eq "Shortpath") { $issuefile = "MSRD-Diag-ShortpathIssues.txt" }
    elseif ($IssueType -eq "Crash") { $issuefile = "MSRD-Diag-Crashes.txt" }
    elseif ($IssueType -eq "ProcessHang") { $issuefile = "MSRD-Diag-ProcessHangs.txt" }
    elseif ($IssueType -eq "BlackScreen") { $issuefile = "MSRD-Diag-PotentialBlackScreens.txt" }
    elseif ($IssueType -eq "TCP") { $issuefile = "MSRD-Diag-TCPIssues.txt" }
    elseif ($IssueType -eq "RDLicensing") { $issuefile = "MSRD-Diag-RDLicensingIssues.txt" }
    elseif ($IssueType -eq "RDGateway") { $issuefile = "MSRD-Diag-RDGatewayIssues.txt" }
    elseif ($IssueType -eq "DomainTrust") { $issuefile = "MSRD-Diag-DomainTrustIssues.txt" }
    elseif ($IssueType -eq "FailedLogon") { $issuefile = "MSRD-Diag-FailedLogons.txt" }

    $exportfile = $global:msrdBasicLogFolder + $issuefile
    $issuefileurl = $global:msrdLogFilePrefix + $issuefile
    $issuefiledisp = $issuefile.Split("-")[2].Split(".")[0]
    $issuefilelink = "<a href='$issuefileurl' target='_blank'>$issuefiledisp</a>"

    $evtxfilelink = "<a href='$evtxfile' target='_blank'>$LogName Event Logs</a>"

    $pad = 13
    $counter = 0

    If ($geteventDiag) {
        if ($Message) {
            foreach ($eventItem in $geteventDiag) {
                foreach ($msg in $Message) {
                    if ($eventItem.Message -like "*$msg*") {
                        $counter = $counter + 1
                         if (-not $global:msrdLiveDiag) {
                            "TimeCreated".PadRight($pad) + " : " + $eventItem.TimeCreated 2>&1 | Out-File -Append ($exportfile)
                            "EventLog".PadRight($pad) + " : " + $LogName 2>&1 | Out-File -Append ($exportfile)
                            "ProviderName".PadRight($pad) + " : " + $eventItem.ProviderName 2>&1 | Out-File -Append ($exportfile)
                            "Id".PadRight($pad) + " : " + $eventItem.Id 2>&1 | Out-File -Append ($exportfile)
                            "Level".PadRight($pad) + " : " + $eventItem.LevelDisplayName 2>&1 | Out-File -Append ($exportfile)
                            "Message".PadRight($pad) + " : " + $eventItem.Message 2>&1 | Out-File -Append ($exportfile)
                            "" 2>&1 | Out-File -Append ($exportfile)
                         }
                    }
                }
            }
        } elseif ($Provider) {
            foreach ($eventItem in $geteventDiag) {
                foreach ($prv in $Provider) {
                    if ($eventItem.ProviderName -eq $prv) {
                        $counter = $counter + 1
                         if (-not $global:msrdLiveDiag) {
                            "TimeCreated".PadRight($pad) + " : " + $eventItem.TimeCreated 2>&1 | Out-File -Append ($exportfile)
                            "EventLog".PadRight($pad) + " : " + $LogName 2>&1 | Out-File -Append ($exportfile)
                            "ProviderName".PadRight($pad) + " : " + $eventItem.ProviderName 2>&1 | Out-File -Append ($exportfile)
                            "Id".PadRight($pad) + " : " + $eventItem.Id 2>&1 | Out-File -Append ($exportfile)
                            "Level".PadRight($pad) + " : " + $eventItem.LevelDisplayName 2>&1 | Out-File -Append ($exportfile)
                            "Message".PadRight($pad) + " : " + $eventItem.Message 2>&1 | Out-File -Append ($exportfile)
                            "" 2>&1 | Out-File -Append ($exportfile)
                         }
                    }
                }
            }
        } else {
			foreach ($eventItem in $geteventDiag) {
				$counter = $counter + 1
				 if (-not $global:msrdLiveDiag) {
					"TimeCreated".PadRight($pad) + " : " + $eventItem.TimeCreated 2>&1 | Out-File -Append ($exportfile)
					"EventLog".PadRight($pad) + " : " + $LogName 2>&1 | Out-File -Append ($exportfile)
					"ProviderName".PadRight($pad) + " : " + $eventItem.ProviderName 2>&1 | Out-File -Append ($exportfile)
					"Id".PadRight($pad) + " : " + $eventItem.Id 2>&1 | Out-File -Append ($exportfile)
					"Level".PadRight($pad) + " : " + $eventItem.LevelDisplayName 2>&1 | Out-File -Append ($exportfile)
					"Message".PadRight($pad) + " : " + $eventItem.Message 2>&1 | Out-File -Append ($exportfile)
					"" 2>&1 | Out-File -Append ($exportfile)
				 }
			}
        }
    }

    if ($counter -gt 0) {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        if ($evtxfile) {
            if ($helpurl) { $msg3 = "(See: $issuefilelink / $evtxfilelink / $helpurl)" } else { $msg3 = "(See: $issuefilelink / $evtxfilelink)" }
        } else {
            if ($helpurl) { $msg3 = "(See: $issuefilelink / $helpurl)" } else { $msg3 = "(See: $issuefilelink)" }
        }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message $IssueType -Message2 "Issues found in the '$LogName' event logs" -Message3 $msg3 -circle "red"
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-2" -Message $IssueType -Message2 "No known issues found in the '$LogName' event logs" -circle "green"
    }

    [System.GC]::Collect()
}

function msrdDiagAVDIssueEvents {

    #AVD events issues
    $global:msrdSetWarning = $false
    $menuitemmsg = "Issues found in Event Logs over the past 5 days"
    $menucatmsg = "Known Issues"
    if ($avdcheck) {
        msrdDiagIssues -IssueType 'Agent' -LogName 'Application' -LogID @(3019,3277,3389,3703) -Message @('Transport received an exception','ENDPOINT_NOT_FOUND','INVALID_FORM','INVALID_REGISTRATION_TOKEN','NAME_ALREADY_REGISTERED','DownloadMsiException','InstallationHealthCheckFailedException','InstallMsiException','AgentLoadException','BootLoader exception','Unable to retrieve DefaultAgent from registry','MissingMethodException','RD Gateway Url') -lvl 'Full' -helpurl $avdTsgRef -evtxfile $aplevtxfile
        msrdDiagIssues -IssueType 'Agent' -LogName 'RemoteDesktopServices' -LogID @(0) -Message @('IMDS not accessible','Monitoring Agent Launcher file path was NOT located','NOT ALL required URLs are accessible!','SessionHost unhealthy','Unable to connect to the remote server','Unhandled status [ConnectFailure] returned for url','System.ComponentModel.Win32Exception (0x80004005)','Unable to extract and validate URLs','PingHost: Could not PING url','Unable to locate running process') -lvl 'Full' -helpurl $avdTsgRef -evtxfile $rdsevtxfile
        msrdDiagIssues -IssueType 'Shortpath' -LogName 'Microsoft-Windows-RemoteDesktopServices-RdpCoreCDV/Operational' -LogID @(135,226) -Message @('UDP Handshake Timeout','UdpEventErrorOnMtReqComplete') -lvl 'Full' -helpurl $spathTsgRef
        msrdDiagIssues -IssueType 'Shortpath' -LogName 'RemoteDesktopServices' -LogID @(0) -Message @('TURN check threw exception','TURN relay health check failed') -lvl 'Full' -evtxfile $rdsevtxfile -helpurl $spathTsgRef

        if ($global:msrdAVD -or $global:msrdRDS) {
            if ($global:WinVerBuild -lt 19041) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "MSIX App Attach requires Windows 10 Enterprise or Windows 10 Enterprise multi-session, version 20H2 or later. Skipping check for MSIX App Attach issues (not applicable)."
            } else {
                msrdDiagIssues -IssueType 'MSIXAA' -LogName 'RemoteDesktopServices' -LogID @(0) -Provider @('Microsoft.RDInfra.AppAttach.AgentAppAttachPackageListServiceImpl','Microsoft.RDInfra.AppAttach.AppAttachServiceImpl','Microsoft.RDInfra.AppAttach.SysNtfyServiceImpl','Microsoft.RDInfra.AppAttach.UserImpersonationServiceImpl','Microsoft.RDInfra.RDAgent.AppAttach.CimVolume','Microsoft.RDInfra.RDAgent.AppAttach.ImagedMsixExtractor','Microsoft.RDInfra.RDAgent.AppAttach.MsixProcessor','Microsoft.RDInfra.RDAgent.AppAttach.VhdVolume','Microsoft.RDInfra.RDAgent.AppAttach.VirtualDiskManager','Microsoft.RDInfra.RDAgent.Service.AppAttachHealthCheck', 'Microsoft.RDInfra.RDAgent.EtwReader.AppAttachProcessParser') -evtxfile $rdsevtxfile
            }
        }

    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$avdcheckmsg" -circle "red"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

function msrdDiagRDIssueEvents {

    #RD events issues
    $global:msrdSetWarning = $false
    $menuitemmsg = "Issues found in Event Logs over the past 5 days"
    $menucatmsg = "Known Issues"

    msrdDiagIssues -IssueType 'BlackScreen' -LogName 'Application' -LogID @(4005) -Message @('The Windows logon process has unexpectedly terminated') -evtxfile $aplevtxfile
    msrdDiagIssues -IssueType 'BlackScreen' -LogName 'System' -LogID @(7011,10020) -Message @('was reached while waiting for a transaction response from the AppReadiness service','The machine wide Default Launch and Activation security descriptor is invalid') -evtxfile $sysevtxfile
    msrdDiagIssues -IssueType 'FailedLogon' -LogName 'Security' -LogID @(4625) -lvl 'None' -evtxfile $secevtxfile

    if (Test-path -path "$env:ProgramFiles\FSLogix\apps") {
        msrdDiagIssues -IssueType 'FSLogix' -LogName 'Microsoft-FSLogix-Apps/Admin' -Provider @('Microsoft-FSLogix-Apps') -helpurl $fslogixTsgRef
        msrdDiagIssues -IssueType 'FSLogix' -LogName 'Microsoft-FSLogix-Apps/Operational' -Provider @('Microsoft-FSLogix-Apps') -helpurl $fslogixTsgRef
        msrdDiagIssues -IssueType 'FSLogix' -LogName 'RemoteDesktopServices' -LogID @(0) -Message @('The disk detach may have invalidated handles','ErrorCode: 743') -lvl 'Full' -evtxfile $rdsevtxfile -helpurl $fslogixTsgRef
        msrdDiagIssues -IssueType 'FSLogix' -LogName 'System' -LogID @(4) -Message @('The Kerberos client received a KRB_AP_ERR_MODIFIED error from the server') -lvl 'Full' -evtxfile $sysevtxfile -helpurl $fslogixTsgRef
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "FSLogix installation <span style='color: brown'>not found</span>. Skipping check for FSLogix issues (not applicable)." -circle "white"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

function msrdDiagCommonIssueEvents {

    #common issues
    $global:msrdSetWarning = $false
    $menuitemmsg = "Issues found in Event Logs over the past 5 days"
    $menucatmsg = "Known Issues"
    msrdDiagIssues -IssueType 'Crash' -LogName 'Application' -LogID @(1000) -Message @('Faulting application name') -evtxfile $aplevtxfile
    msrdDiagIssues -IssueType 'Crash' -LogName 'System' -LogID @(41,6008) -Message @('The system rebooted without cleanly shutting down first','was unexpected') -evtxfile $sysevtxfile
    msrdDiagIssues -IssueType 'DomainTrust' -LogName 'System' -LogID @(5719) -Message @('not able to set up a secure session with a domain controller') -evtxfile $sysevtxfile
    msrdDiagIssues -IssueType 'ProcessHang' -LogName 'Application' -LogID @(1002) -Message @('stopped interacting with Windows') -evtxfile $aplevtxfile
    msrdDiagIssues -IssueType 'TCP' -LogName 'System' -LogID @(4227,4231) -Message @('TCP/IP failed to establish','port space has failed') -evtxfile $sysevtxfile

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

function msrdDiagRDLicensingIssueEvents {

    #RD Licensing issues
    $global:msrdSetWarning = $false
    $menuitemmsg = "Issues found in Event Logs over the past 5 days"
    $menucatmsg = "Known Issues"
    msrdDiagIssues -IssueType 'RDLicensing' -LogName 'System' -Provider @('Microsoft-Windows-TerminalServices-Licensing') -evtxfile $sysevtxfile
    msrdDiagIssues -IssueType 'RDLicensing' -LogName 'Microsoft-Windows-TerminalServices-Licensing/Admin'
    msrdDiagIssues -IssueType 'RDLicensing' -LogName 'Microsoft-Windows-TerminalServices-Licensing/Operational'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

function msrdDiagRDGatewayIssueEvents {

    #RD Gateway issues
    $global:msrdSetWarning = $false
    $menuitemmsg = "Issues found in Event Logs over the past 5 days"
    $menucatmsg = "Known Issues"
    msrdDiagIssues -IssueType 'RDGateway' -LogName 'Microsoft-Windows-TerminalServices-Gateway/Admin'
    msrdDiagIssues -IssueType 'RDGateway' -LogName 'Microsoft-Windows-TerminalServices-Gateway/Operational'

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagLogonIssues {

    #potential logon issues diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Potential Logon/Logoff Issue Generators"
    $menucatmsg = "Known Issues"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "BlackCheck"

    #Checking System Hive size
    $hivePath = "$env:windir\System32\Config\SYSTEM"
    if (Test-Path $hivePath) {
        $hiveSize = (Get-Item $hivePath).length
        $hiveSizeMB = $hiveSize / 1MB
        if ($hiveSizeMB -gt 1000) {
            $hiveCircle = "red"; $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        } elseif ($hiveSizeMB -lt 300) { $hiveCircle = "green" } else { $hiveCircle = "white" }
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "SYSTEM registry hive size" -Message2 "$hiveSizeMB MB" -circle $hiveCircle
    } else {
        $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The SYSTEM registry hive file could not be found at $hivePath" -circle "red"
    }

    # checking VHDX configuration consistency (RDS and AVD)
    if ($global:msrdAVD -or $global:msrdRDS) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        if (Test-Path ($global:msrdLogDir + $virtualdiskregconsfile)) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Virtual Disk registry consistency check" -Message2 "(See: <a href='$virtualdiskregconsfile' target='_blank'>VirtualDiskRegConsistency</a>)" -circle "white"
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Virtual Disk registry consistency check" -circle "no"
        }

        $registryPath = "HKLM:\System\CurrentControlSet\Enum\SCSI\Disk&Ven_Msft&Prod_Virtual_Disk"
        $diskInfo = Get-ChildItem -Path $registryPath -ErrorAction SilentlyContinue
 
        if ($diskInfo) {
            $missingCounter = 0
            foreach ($item in $diskInfo) {
                $missingValues = @()

                $classGuidValue = $item.GetValue("ClassGUID")
                if ($classGuidValue -eq $null) { $missingValues += "ClassGUID" } 

                $MfgValue = $item.GetValue("Mfg")
                if ($MfgValue -eq $null) { $missingValues += "Mfg" }

                $ServiceValue = $item.GetValue("Service")
                if ($ServiceValue -eq $null) { $missingValues += "Service" }

                if ($classGuidValue -eq $null -or $MfgValue -eq $null -or $ServiceValue -eq $null) {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    $missingString = $missingValues -join " / "
                    if ($missingCounter -eq 0) {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Missing critical registry values under '$registryPath'\ (relevant for mounting UPD or FSlogix profile disks)" -circle "red"
                    }
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Affected subkey: $($item.PSChildName)" -Message3 "Missing: $missingString" -circle "red"
                    $missingCounter += 1
                }
            }

            if ($missingCounter -eq 0) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "No missing registry values found under '$registryPath' (relevant for UPD or FSlogix profile disk mounting)" -circle "green"
            }
        } else {
			msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "The registry path '$registryPath' (relevant for UPD or FSlogix profile disk mounting) could not be found" -circle "white"
        }

        #SAN policy status
        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        $sanpolicy = (Get-StorageSetting -ErrorAction SilentlyContinue).NewDiskPolicy
        if ($sanpolicy) {
            if ($sanpolicy -eq "OfflineAll") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                $sancircle = "red"
            } elseif ($sanpolicy -eq "OnlineAll") {
                $sancircle = "green"
            } else {
                $sancircle = "white"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Storage Area Network (SAN) policy status" -Message2 "$sanpolicy" -circle $sancircle
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
			msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Storage Area Network (SAN) policy status" -Message2 "not found" -circle "red"
        }
            
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    if (Test-path -path "$env:ProgramFiles\FSLogix\apps") {
        if (($script:frxverstrip -lt $latestFSLogixVer) -and (!($script:frxverstrip -eq "unknown"))) {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "You are not using the latest available FSLogix release. Please consider updating. See: $fslogixRef" -circle "red"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\' -RegKey 'DisableFRAdminPin'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'AppData(Roaming) folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Desktop folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Start Menu folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{FDD39AD0-238F-46AF-ADB4-6C85480369C7}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Documents folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{33E28130-4E1E-4676-835A-98395C3BC3BB}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Pictures folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{4BD8D571-6D19-48D3-BE97-422220080E43}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Music folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{18989B1D-99B5-455B-841C-AB7C74E4DDFC}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Videos folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{1777F761-68AD-4D8A-87BD-30B759FA33DD}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Favorites folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{56784854-C6CB-462b-8169-88E350ACB882}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Contacts folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{374DE290-123F-4565-9164-39C4925E467B}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Downloads folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{BFB9D5E0-C6A9-404C-B2B2-AE6DB6AF4968}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Links folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{7D1D3A04-DEBB-4115-95CF-2F29DA2920DA}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Searches folder redirection'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\NetCache\{4C5C32FF-BB9D-43B0-B5B4-2D72E54EAAA4}\' -RegKey 'DisableFRAdminPinByFolder' -OptNote 'Saved Games folder redirection'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4340}\' -RegKey 'IsInstalled'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'AVCHardwareEncodePreferred' -OptNote 'Computer Policy: Configure H.264/AVC hardware encoding for Remote Desktop Connections'
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata\' -RegKey 'PreventDeviceMetadataFromNetwork' -OptNote 'Computer Policy: Prevent device metadata retrieval from the Internet' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\' -RegKey 'DenyDeviceClasses' -OptNote 'Computer Policy: Prevent Installation of devices using drivers that match these device setup classes' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\' -RegKey 'DenyDeviceIDs' -OptNote 'Computer Policy: Prevent Installation of devices that match any of these device IDs' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\' -RegKey 'DenyInstanceIDs' -OptNote 'Computer Policy: Prevent Installation of devices that match any of these device instance IDs' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\' -RegKey 'DenyRemovableDevices' -OptNote 'Computer Policy: Prevent Installation of Removable Devices' -addWarning
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\' -RegKey 'DenyUnspecified' -OptNote 'Computer Policy: Prevent installation of devices not described by other policy settings' -addWarning

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -RegKey 'AppReadinessPreShellTimeoutMs'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' -RegKey 'AppReadinessGlobalTimeoutMs'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'FirstLogonTimeout'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\' -RegKey 'DelayedDesktopSwitchTimeout'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'Shell' -RegValue 'explorer.exe'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'ShellAppRuntime' -RegValue 'ShellAppRuntime.exe'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' -RegKey 'Userinit' -RegValue "$env:windir\system32\userinit.exe,"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -RegKey 'AllowBlockingAppsAtShutdown' -RegValue "0" -OptNote "Computer Policy: Turn off automatic termination of applications that block or cancel shutdown" -warnColor "yellow"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\AllUserInstallAgent\' -RegKey 'LogonWaitForPackageRegistration' -OptNote "Computer Policy: Suspend user sign-in to complete app registration"

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\LSA\' -RegKey 'CrashOnAuditFail' -OptNote 'Computer Policy: Audit: Shut down system immediately if unable to log security audits' -warnIfValue '2'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKCU:\Control Panel\Desktop\' -RegKey 'AutoEndTasks'
    msrdCheckRegKeyValue -RegPath 'HKCU:\Control Panel\Desktop\' -RegKey 'HungAppTimeout'
    msrdCheckRegKeyValue -RegPath 'HKCU:\Control Panel\Desktop\' -RegKey 'WaitToKillAppTimeout'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\' -RegKey 'WaitToKillServiceTimeout'
    msrdCheckRegKeyValue -RegPath 'HKU:\.DEFAULT\Control Panel\Desktop\' -RegKey 'AutoEndTasks'
    msrdCheckRegKeyValue -RegPath 'HKU:\.DEFAULT\Control Panel\Desktop\' -RegKey 'HungAppTimeout'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service AppXSvc

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service AppReadiness

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckServicePort -service smphost

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"

    $countregKeys = @('HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\DefaultRules', 'HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSetRules')
    foreach ($kreg in $countregKeys) {
        if (Test-Path -Path $kreg) {
            $keyCountBloat = Get-ChildItem -Path $creg | Measure-Object | Select-Object -ExpandProperty Count
            if ($keyCountBloat -gt 5000) { $kCircle = "red" } else { $kCircle = "white" }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$kreg" -Message2 "$keyCountBloat keys found" -circle $kCircle
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $kreg -Message2 "not found"
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    $countregValues = @('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Notifications','HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\VolatileNotifications','HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules', 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedInterfaces\IfIso\FirewallRules', 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\AppIso\FirewallRules')
    foreach ($vreg in $countregValues) {
        if (Test-Path -Path $vreg) {
            $valueCountBloat = (Get-ItemProperty -Path $vreg | Get-Member -MemberType NoteProperty).Count
            if ($valueCountBloat -gt 5000) { $vCircle = "red" } else { $vCircle = "white" }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$vreg" -Message2 "$valueCountBloat values found" -circle $vCircle
        } else {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message $vreg -Message2 "not found"
        }
    }
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\' -RegKey 'DeleteRoamingCache' -RegValue '1'
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\' -RegKey 'DeleteUserAppContainersOnLogoff' -RegValue '1'

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\DriverDatabase\DeviceIds\TS_INPT\TS_KBD\' -RegKey 'termkbd.inf' -warnMissing
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\DriverDatabase\DeviceIds\TS_INPT\TS_MOU\' -RegKey 'termmou.inf' -warnMissing

    if ($global:msrdTarget) {
        if ($global:msrdAVD -or $global:msrdW365) {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\TERMINPUT_BUS\UMB\", "HKLM:\SYSTEM\CurrentControlSet\Enum\TERMINPUT_BUS_SXS\UMB\"
        } else {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\TERMINPUT_BUS\UMB\"
        }
        foreach ($regP in $regPath) {

            if (Test-Path -Path $regP) {
                if ($regP -eq "HKLM:\SYSTEM\CurrentControlSet\Enum\TERMINPUT_BUS\UMB\") {
                    $umbfile = "${computerName}_RegistryKeys\${computerName}_HKLM-System-CCS-Enum-TERMINPUT_BUS.txt"
                    $umbname = "TERMINPUT_BUS\UMB\"
                } elseif ($regP -eq "HKLM:\SYSTEM\CurrentControlSet\Enum\TERMINPUT_BUS_SXS\UMB\") {
                    $umbfile = "${computerName}_RegistryKeys\${computerName}_HKLM-System-CCS-Enum-TERMINPUT_BUS_SXS.txt"
                    $umbname = "TERMINPUT_BUS_SXS\UMB\"
                }

                $keyNames = Get-ChildItem -Path $regP -Name -ErrorAction SilentlyContinue

                if ($keyNames) {
                    $sessions = @{}
                    foreach ($keyName in $keyNames) {
                        $match = $keyName -match "^(\d+)&(\w+)&(\w+)&Session(\d+)(Keyboard|Mouse)(\d+)$"
                        if ($match) {
                            $sessionId = [int]$matches[4]
                            $deviceType = $matches[5]
                            $deviceId = [int]$matches[6]
                            if (!$sessions.ContainsKey($sessionId)) {
                                $sessions[$sessionId] = @{
                                    "keyboardIds" = @()
                                    "mouseIds" = @()
                                }
                            }
                            if ($deviceType -eq "Keyboard") {
                                $sessions[$sessionId]["keyboardIds"] += $deviceId
                            } elseif ($deviceType -eq "Mouse") {
                                $sessions[$sessionId]["mouseIds"] += $deviceId
                            }
                        } else {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Error retrieving information from '$keyName'" -circle "red"
                        }
                    }

                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                    # File paths
                    $UMBpath1 = $umbfile; $tag1 = "$umbname registry"
                    $UMBpath2 = $pnputilKeyboardfile; $tag2 = "Pnputil Keyboard"
                    $UMBpath3 = $pnputilMousefile; $tag3 = "Pnputil Mouse"

                    # Check file availability
                    $availableFiles = @()
                    if (Test-Path -Path ($global:msrdLogDir + $UMBpath1)) { $availableFiles += $UMBpath1 } else { $availableFiles += "n/a" }
                    if (Test-Path -Path ($global:msrdLogDir + $UMBpath2)) { $availableFiles += $UMBpath2 } else { $availableFiles += "n/a" }
                    if (Test-Path -Path ($global:msrdLogDir + $UMBpath3)) { $availableFiles += $UMBpath3 } else { $availableFiles += "n/a" }

                    # Build HTML for clickable hyperlinks
                    $htmlFiles = foreach ($file in $availableFiles) {
                        if ($file -ne "n/a") {
                            $tagVariableName = "tag" + ([array]::IndexOf($availableFiles, $file) + 1)
                            $tag = Get-Variable -Name $tagVariableName -ValueOnly
                            $link = "<a href='$file' target='_blank'>$tag</a>"
                            $link
                        }
                    }

                    # Display message
                    if ($availableFiles.Count -gt 0) {
                        $htmlFilesList = $htmlFiles -join ' / '
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Keyboard and mouse entries per remote session under $regP" -Message2 "(See: $htmlFilesList)" -circle "white"
                    } else {
                        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Keyboard and mouse entries per remote session under $regP"
                    }

                    foreach ($session in $sessions.Keys) {
                        $keyboardCount = $sessions[$session]["keyboardIds"].Count
                        $mouseCount = $sessions[$session]["mouseIds"].Count
                        $msgwarn = $false

                        $keyboardIds = $sessions[$session]["keyboardIds"] -join ", "
                        if ($keyboardIds -eq "") { $keyboardIds = "N/A" }
                        if ($keyboardCount -ne 1) {
                            $msgwarn = $true
                            if ($sessions[$session]["keyboardIds"] -notcontains 0) {
                                $msgkeyboard = "Keyboard entries found: $keyboardCount (Expected: 1) [Value(s): $keyboardIds] (Keyboard 0 not found)"
                            } else {
                                $msgkeyboard = "Keyboard entries found: $keyboardCount (Expected: 1) [Value(s): $keyboardIds]"
                            }
                        } else {
                            if ($sessions[$session]["keyboardIds"] -notcontains 0) {
                                $msgwarn = $true
                                $msgkeyboard = "Keyboard entries found: $keyboardCount [Value(s): $keyboardIds] (Keyboard 0 not found)"
                            } else {
                                $msgkeyboard = "Keyboard entries found: $keyboardCount [Value(s): $keyboardIds]"
                            }
                        }

                        $mouseIds = $sessions[$session]["mouseIds"] -join ", "
                        if ($mouseIds -eq "") { $mouseIds = "N/A" }
                        if ($mouseCount -ne 1) {
                            $msgwarn = $true
                            if ($sessions[$session]["mouseIds"] -notcontains 0) {
                                $msgmouse = "Mouse entries found: $mouseCount (Expected: 1) [Value(s): $mouseIds] (Mouse 0 not found)"
                            } else {
                                $msgmouse = "Mouse entries found: $mouseCount (Expected: 1) [Value(s): $mouseIds]"
                            }
                        } else {
                            if ($sessions[$session]["mouseIds"] -notcontains 0) {
                                $msgwarn = $true
                                $msgmouse = "Mouse entries found: $mouseCount [Value(s): $mouseIds] (Mouse 0 not found)"
                            } else {
                                $msgmouse = "Mouse entries found: $mouseCount [Value(s): $mouseIds]"
                            }
                        }

                        if ($msgwarn) {
                            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Session ID: $session" -Message3 "$msgkeyboard" -circle "red"
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message3 "$msgmouse" -circle "red"
                        } else {
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "Session ID: $session" -Message3 "$msgkeyboard" -circle "green"
                            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message3 "$msgmouse" -circle "green"
                        }
                    }
                } else {
                    $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$regP found but Session Keyboard/Mouse information could not be retrieved. See <a href='$msrdErrorfileurl' target='_blank'>MSRD-Collect-Error</a> for more information." -circle "red"
                }
            } else {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$regP" -Message2 "not found"
            }
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion Known Issues


#region Other

Function msrdDiagOffice {

    #Microsoft Office diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Office"
    $menucatmsg = "Other"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "MSOCheck"

    $oversion = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\O365ProPlusRetail* -ErrorAction Continue 2>>$global:msrdErrorLogFile

    if ($oversion) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Office installation(s)" -circle "no"
        foreach ($oitem in $oversion) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($oitem.Displayname)" -Message3 "$($oitem.DisplayVersion)" -circle "white"
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service "ClickToRunSvc"

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\common\' -RegKey 'InsiderSlabBehavior' -RegValue '2' -OptNote 'Computer Policy: Show the option for Office Insider' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode\' -RegKey 'enable' -RegValue '1'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode\' -RegKey 'syncwindowsetting' -RegValue '1' -OptNote 'Computer Policy: Cached Exchange Mode Sync Settings'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode\' -RegKey 'CalendarSyncWindowSetting' -RegValue '1' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode\' -RegKey 'CalendarSyncWindowSettingMonths' -RegValue '1' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate\' -RegKey 'hideupdatenotifications' -RegValue '1' -OptNote 'Computer Policy: Hide Update Notifications' -warnColor "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate\' -RegKey 'hideenabledisableupdates' -RegValue '1' -OptNote 'Computer Policy: Hide option to enable or disable updates' -warnColor "yellow"

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Office installation <span style='color: brown'>not found</span>."
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagOD {

    #Microsoft OneDrive diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "OneDrive"
    $menucatmsg = "Other"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "MSODCheck"

    $ODM86 = "${env:ProgramFiles(x86)}\Microsoft OneDrive" + '\OneDrive.exe'
    $ODM = "$env:ProgramFiles\Microsoft OneDrive" + '\OneDrive.exe'
    $ODU = "$ENV:localappdata" + '\Microsoft\OneDrive\OneDrive.exe'

    $ODM86test = Test-Path $ODM86
    $ODMtest = Test-Path $ODM
    $ODUtest = Test-Path $ODU

    if (($ODM86test) -or ($ODMtest) -or ($ODUtest)) {

        if ($ODMtest) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "OneDrive installation ($ODM)" -Message2 "per-machine" -circle "white"
        } elseif ($ODM86test) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "OneDrive installation ($ODM86)" -Message2 "per-machine" -circle "white"
        } else {
            $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "OneDrive installation ($ODU)" -Message2 "per-user" -circle "red"
        }

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckServicePort -service "OneDrive Updater Service"

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdProcessCheck -proc "OneDrive" -intName "OneDrive" -noSpacer1
        msrdProcessCheck -proc "shellappruntime" -intName "ShellAppRuntime" -noSpacer2

        msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\OneDrive\' -RegKey 'AllUsersInstall' -RegValue '1'

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'ConcurrentUserSessions' -RegValue '0' -OptNote 'Computer Policy: Allow concurrent user sessions'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\FSLogix\Profiles\' -RegKey 'ProfileType' -RegValue '0' -OptNote 'Computer Policy: Profile type'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC\' -RegKey 'VHDAccessMode' -RegValue '0' -OptNote 'Computer Policy: VHD access type'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\' -RegKey 'WarningMinDiskSpaceLimitInMB' -OptNote 'Computer Policy: Warn users who are low on disk space'

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\' -RegKey 'OneDrive'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\' -RegKey 'OneDrive'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\' -RegKey 'OneDrive'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\' -RegKey 'OneDrive'

        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\' -RegKey 'DisableLocalMachineRun' -warnIfValue -color "yellow"
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\' -RegKey 'DisableCurrentUserRun' -warnIfValue -color "yellow"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\' -RegKey 'DisableLocalMachineRunOnce' -warnIfValue -color "yellow"
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\' -RegKey 'DisableCurrentUserRunOnce' -warnIfValue -color "yellow"

        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RailRunonce\' -RegKey 'OneDrive'

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "OneDrive installation <span style='color: brown'>not found</span>."
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdDiagPrinting {

    #Printing diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Printing"
    $menucatmsg = "Other"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "PrintCheck"

    msrdCheckServicePort -service spooler

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    $printlist = Get-Printer | Select-Object Name, DriverName -ErrorAction Continue | Sort-Object Name 2>>$global:msrdErrorLogFile
    if ($printlist) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Printer(s)" -circle "no"
        foreach ($printitem in $printlist) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table1-3" -Message2 "$($printitem.Name)" -Message3 "$($printitem.DriverName)"
        }
    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Printers <span style='color: brown'>not found</span>"
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisablePrinterRedirection' -RegValue '0'
    msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client\' -RegKey 'DisablePrinterRedirection' -RegValue '0'

    if ($global:msrdTarget) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\' -RegKey 'RemovePrintersAtLogoff'
        msrdCheckRegKeyValue -RegPath 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows\' -RegKey 'MaintainDefaultPrinter'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC\' -RegKey 'RpcNamedPipeAuthentication'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\' -RegKey 'RpcAuthnLevelPrivacyEnabled'

        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\' -RegKey 'fDisableCpm' -RegValue '0' -OptNote 'Computer Policy: Do not allow client printer redirection'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -RegKey 'fDisableCpm' -RegValue '0'

        if ($global:msrdAVD -or $global:msrdW365) {
            if ($script:msrdListenervalue) {
                msrdCheckRegKeyValue -RegPath ('HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\' + $script:msrdListenervalue + '\') -RegKey 'fDisableCpm' -RegValue '0'
            } else {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Active AVD listener configuration not found" -circle "red"
            }
        }
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

Function msrdProcessCheck {
    Param([Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$proc, [string]$intName, [switch]$noSpacer1, [switch]$noSpacer2, [string]$flag, $warnMessage)

    try {
        $check = Get-Process $proc -ErrorAction SilentlyContinue
        if ($null -eq $check) {
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$intName ($proc)" -Message2 "not found"
        } else {
            $counter = ($check | Group-Object -Property ProcessName).Count

            if ($flag -eq "Warning") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                $pcCircle = "yellow"
            } elseif ($flag -eq "Critical") {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                $pcCircle = "red"
            } else {
                $pcCircle = "white"
            }

            if (-not $noSpacer1) { msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer" }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Process '$proc' was found running on this system in $counter instance(s)" -circle $pcCircle
            foreach ($entry in $check) {
                $vendor = ($entry | Group-Object -Property Company).Name
                if (($null -eq $vendor) -or ($vendor -eq "")) { $vendor = "N/A" }
                $desc = ($entry | Group-Object -Property Description).Name
                $path = ($entry | Group-Object -Property Path).Name
                $prodver = ($entry | Group-Object -Property ProductVersion).Name
                if (($null -eq $desc) -or ($desc -eq "")) { $desc = "N/A" }
                if (($null -eq $prodver) -or ($prodver -eq "")) { $prodver = "N/A" }
                if (($null -eq $path) -or ($path -eq "")) { $path = "N/A" }

                msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$vendor ($desc)" -Message2 "$prodver" -circle $pcCircle
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Path: $path" -circle $pcCircle
            }
            if ($warnMessage) {
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "$warnMessage" -circle $pcCircle
            }
            if (-not $noSpacer2) { msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer" }
        }
    } catch {
        $FailedCommand = $MyInvocation.Line.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText 'errormsg') $FailedCommand") -ErrObj $_
    }
}

Function msrdCheckRegPath {
    Param([Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$RegPath, [string]$OptNote)

    $isPath = Test-Path -path $RegPath
    if ($isPath) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath" -Message2 "found" -Title "$OptNote" -circle "yellow"
    }
    else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$RegPath" -Message2 "not found" -Title "$OptNote"
    }
}

Function msrdDiagCitrix3P {

    #Citrix and other 3rd party software diagnostics
    $global:msrdSetWarning = $false
    $menuitemmsg = "Third Party Software"
    $menucatmsg = "Other"
    msrdLogDiag $LogLevel.Normal -Message $menuitemmsg -DiagTag "3pCheck"

    $CitrixProd = (Get-ItemProperty  hklm:\software\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -like "*Citrix*")})
    $CitrixProd2 = (Get-ItemProperty  hklm:\software\wow6432node\microsoft\windows\currentversion\uninstall\* | Where-Object {($_.DisplayName -like "*Citrix*")})

    if ($CitrixProd -or $CitrixProd2) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Citrix products"
    }

    if ($CitrixProd) {
        foreach ($cprod in $CitrixProd) {
            if ($cprod.DisplayVersion) { $cprodDisplayVersion = $cprod.DisplayVersion } else { $cprodDisplayVersion = "N/A" }
            if ($cprod.InstallDate) {
                $cprodInstallDate = $cprod.InstallDate
                $cprodInstallDate = [datetime]::ParseExact($cprodInstallDate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
            } else {
                $cprodInstallDate = "N/A"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$($cprod.DisplayName)" -Message2 "$cprodDisplayVersion (Installed on: $cprodInstallDate)" -circle "white"

            if (($CitrixProd -like "*Citrix Virtual Apps and Desktops*") -and (($cprodDisplayVersion -eq "1912.0.4000.4227") -or ($cprodDisplayVersion -like "2109.*") -or ($cprodDisplayVersion -like "2112.*"))) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Citrix Virtual Apps and Desktops version has been found. Please consider updating. You could be running into issues described in: https://support.citrix.com/article/CTX338807" -circle "red"
            }
        }
    } elseif ($CitrixProd2) {
        foreach ($cprod2 in $CitrixProd2) {
            if ($cprod2.DisplayVersion) { $cprod2DisplayVersion = $cprod2.DisplayVersion } else { $cprod2DisplayVersion = "N/A" }
            if ($cprod2.InstallDate) {
                $cprod2InstallDate = $cprod2.InstallDate
                $cprod2InstallDate = [datetime]::ParseExact($cprod2InstallDate, "yyyyMMdd", $null).ToString("yyyy/MM/dd")
            } else {
                $cprod2InstallDate = "N/A"
            }
            msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "$($cprod2.DisplayName)" -Message2 "$cprod2DisplayVersion (Installed on: $cprod2InstallDate)" -circle "white"

            if (($CitrixProd2 -like "*Citrix Virtual Apps and Desktops*") -and (($cprod2DisplayVersion -eq "1912.0.4000.4227") -or ($cprod2DisplayVersion -like "2109.*") -or ($cprod2DisplayVersion -like "2112.*"))) {
                $global:msrdSetWarning = $true; $global:msrdIssueCounter += 1;
                msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "An older Citrix Virtual Apps and Desktops version has been found. Please consider updating. You could be running into issues described in: https://support.citrix.com/article/CTX338807" -circle "red"
            }
        }

    } else {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Table2-1" -Message "Citrix products" -Message2 "not found"
    }

    if (($CitrixProd) -or ($CitrixProd2)) {
        msrdLogDiag $LogLevel.DiagFileOnly -Type "Spacer"
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Citrix\Graphics\' -RegKey 'SetDisplayRequiredMode'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Citrix\GroupPolicy\' -RegKey 'GpoCacheEnabled'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Citrix\GroupPolicy\' -RegKey 'CacheGpoExpireInHours'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Citrix\Ica\GroupPolicy\' -RegKey 'EnforceUserPolicyEvaluationSuccess'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Citrix\Reconnect\' -RegKey 'DisableGPCalculation'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Citrix\Reconnect\' -RegKey 'FastReconnect'
        msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\services\CtxUvi\' -RegKey 'UviProcessExcludes'
        if ($global:msrdW365) {
            msrdCheckRegKeyValue -RegPath 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent\' -RegKey 'NgsConnected'
        }
    }

    msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
    msrdLogDiag $LogLevel.DiagFileOnly -Type "Text" -col 3 -Message "Third party processes and settings which could potentially interfere with remote desktop connections" -circle "no"
    msrdProcessCheck -proc "aakore" -intName "Acronis Cyber Protect" -noSpacer1 -flag "Warning"
    msrdProcessCheck -proc "cyber-protect-service" -intName "Acronis Cyber Protect" -flag "Warning"
    msrdProcessCheck -proc "WebCompanion" -intName "Adaware" -flag "Warning"
    msrdProcessCheck -proc "DefendpointService" -intName "BeyondTrust" -flag "Warning"
    msrdProcessCheck -proc "vpnagent" -intName "Cisco AnyConnect" -flag "Warning"
    msrdProcessCheck -proc "csagent" -intName "CrowdStrike" -flag "Warning"
    msrdProcessCheck -proc "csfalconservice" -intName "CrowdStrike Falcon Sensor" -flag "Warning"
    msrdProcessCheck -proc "secureconnector" -intName "ForeScout SecureConnector" -flag "Warning"
    msrdProcessCheck -proc "hwtag" -intName "Forcepoint Endpoint Security Agent" -flag "Warning"
    msrdProcessCheck -proc "sgpm" -intName "Forcepoint Stonesoft VPN" -flag "Warning"
    msrdProcessCheck -proc "mcshield" -intName "McAfee" -flag "Warning"
    msrdProcessCheck -proc "stAgentSvc" -intName "Netskope Client" -flag "Warning"
    msrdProcessCheck -proc "NVDisplay.Container" -intName "NVIDIA" -flag "Warning"
    msrdProcessCheck -proc "GpVpnApp" -intName "Palo Alto GlobalProtect" -flag "Warning"
    msrdProcessCheck -proc "PanGPA" -intName "Palo Alto GlobalProtect" -flag "Warning"
    msrdProcessCheck -proc "PanGPS" -intName "Palo Alto GlobalProtect" -flag "Warning"
    msrdProcessCheck -proc "sentinelagent" -intName "SentinelOne Agent" -flag "Warning"
    msrdProcessCheck -proc "SAVService" -intName "Sophos Anti-Virus" -flag "Warning"
    msrdProcessCheck -proc "SEDService" -intName "Sophos Endpoint Defense Service" -flag "Warning"
    msrdCheckRegKeyValue -RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Sophos Endpoint Defense\EndpointFlags\' -RegKey 'modernweb.offloading.enabled' -addWarning -warnColor "yellow"
    msrdProcessCheck -proc "SophosNtpService" -intName "Sophos Network Threat Protection" -flag "Warning"
    msrdProcessCheck -proc "SSPService" -intName "Sophos System Protection Service" -flag "Warning"
    msrdProcessCheck -proc "swi_fc" -intName "Sophos Web Intelligence Service" -flag "Warning"
    msrdProcessCheck -proc "wssad" -intName "Symantec WSS Agent" -flag "Warning"
    msrdProcessCheck -proc "nessusd" -intName "Tenable Nessus" -flag "Warning"
    msrdProcessCheck -proc "TSPrintManagementService" -intName "TerminalWorks TSPrint Server" -flag "Warning"
    msrdProcessCheck -proc "tmiacagentsvc" -intName "Trend Micro Application Control" -flag "Warning"
    msrdProcessCheck -proc "endpointbasecamp" -intName "Trend Micro Endpoint Basecamp" -flag "Warning"
    msrdProcessCheck -proc "tmbmsrv" -intName "Trend Micro Unauthorized Change Prevention" -flag "Warning"
    msrdProcessCheck -proc "ivpagent" -intName "Trend Micro Vulnerability Protection" -flag "Warning"

    if ($global:msrdOSVer -like "*virtu*") {
        msrdProcessCheck -proc "ZSAService" -intName "Zscaler" -noSpacer2 -flag "Critical" -warnMessage "As of January 2022, Zscaler does not support using the Zscaler Client Connector on multi-session OS. This is valid until further notice. See the <a href='https://help.zscaler.com/downloads/zscaler-technology-partners/data/zscaler-and-azure-traffic-forwarding-deployment-guide/Zscaler-Azure-Traffic-Forwarding-Deployment-Guide-FINAL.pdf' target='_blank'>Zscaler documentation</a> for Zscaler's latest statement. Starting December 2023, ZScaler also offers a ZScaler VDI Agent for multi-session deployments. Consider engaging ZScaler support for any information regarding their new agent. See: <a href='https://help.zscaler.com/cloud-branch-connector/what-zscaler-vdi-agent' target='_blank'>What Is Zscaler VDI Agent?</a>"
    } else {
        msrdProcessCheck -proc "ZSAService" -intName "Zscaler" -noSpacer2 -flag "Warning"
    }

    if (($global:msrdSetWarning) -and (-not $global:msrdLiveDiag)) { msrdHtmlSetMenuWarning -htmloutfile "$msrdDiagFile" -MenuItem $menuitemmsg -MenuCat $menucatmsg }
}

#endregion Other


#start
Function msrdRunUEX_RDDiag {
    param ([bool[]]$varsSystem, [bool[]]$varsAVDRDS, [bool[]]$varsInfra, [bool[]]$varsAD, [bool[]]$varsNET, [bool[]]$varsLogSec, [bool[]]$varsIssues, [bool[]]$varsOther)

    #main Diag
    if ($global:msrdAVD) { $script:msrdMenuCat = "AVD/RDS" } elseif ($global:msrdRDS) { $script:msrdMenuCat = "RDS" } elseif ($global:msrdW365) { $script:msrdMenuCat = "AVD/RDS/W365" }

    $global:msrdIssueCounter = 0

    msrdLogMessage $LogLevel.Info -Message "$rdiagmsg" -Color "Cyan"

    msrdCreateLogFolder $global:msrdLogDir

    if ($global:msrdSource) { $TitleRole = "Source" } elseif ($global:msrdTarget) { $TitleRole = "Target" }
    if ($global:msrdW365) {
        $TitleScenario = "W365 $TitleRole"
    } elseif ($global:msrdAVD) {
        $TitleScenario = "AVD $TitleRole"
    } elseif ($global:msrdRDS) {
        $TitleScenario = "RDS $TitleRole"
    }

    if (-not $global:msrdLiveDiag) { msrdCheckAzVM }

    msrdHtmlInit $msrdDiagFile
    msrdHtmlHeader -htmloutfile $msrdDiagFile -title "MSRD-Diag ($TitleScenario): $($env:computername)" -fontsize "small"
    msrdHtmlBodyDiag -htmloutfile $msrdDiagFile -title "Microsoft CSS Remote Desktop Diagnostics Report ($TitleScenario)" -varsSystem $varsSystem -varsAVDRDS $varsAVDRDS -varsInfra $varsInfra -varsAD $varsAD -varsNET $varsNET -varsLogSec $varsLogSec -varsIssues $varsIssues -varsOther $varsOther

    #system
    if ($varsSystem[0]) { msrdDiagDeployment }
    if ($varsSystem[1]) { msrdDiagCPU }
    if ($varsSystem[2]) { msrdDiagDrives }
    if ($varsSystem[3]) { msrdDiagGraphics }
    if ($global:msrdTarget) {
        if ($varsSystem[4]) { msrdDiagHyperVIntegration }
        if ($varsSystem[5]) { msrdDiagActivation }
    }
    if ($varsSystem[6]) { msrdDiagSSLTLS }
    if ($varsSystem[7]) { msrdDiagUAC }
    if ($varsSystem[8]) { msrdDiagInstaller }
    if ($global:msrdTarget) { if ($varsSystem[9]) { msrdDiagSearch } }
    if ($varsSystem[10]) { msrdDiagWU }
    if ($varsSystem[11]) { msrdDiagWinRMPS }

    #avd/rds/w365
    if ($varsAVDRDS[0]) { msrdDiagRedirection }
    if ($global:msrdTarget -and ($global:msrdAVD -or $global:msrdRDS)) { if ($varsAVDRDS[1]) { msrdDiagFSLogix } }
    if ($varsAVDRDS[2]) { msrdDiagMultimedia }
    if ($varsAVDRDS[3]) { msrdDiagQA }
    if ($global:msrdTarget) {
        if ($varsAVDRDS[4]) { msrdDiagRDPListener }
        if ($global:msrdOSVer -like "*Windows*Server*") { if ($varsAVDRDS[5]) { msrdDiagRDSRoles } }
    }
    if ($global:msrdSource) { if ($varsAVDRDS[6]) { msrdDiagRDClient } }
    if ($varsAVDRDS[7]) { msrdDiagLicensing }
    if ($global:msrdTarget) { if ($varsAVDRDS[8]) { msrdDiagTimeLimits } }
    if ($global:msrdAVD -or $global:msrdW365) { if ($varsAVDRDS[9]) { msrdDiagTeams } }

    if ($global:msrdW365) { if ($varsAVDRDS[10]) { msrdDiagW365 } }

    #avd infra
    if ($global:msrdAVD -or $global:msrdW365) {
        if ($global:msrdTarget) {
            if ($varsInfra[0]) { msrdDiagAgentStack }
            if ($varsInfra[1]) { msrdDiagAppAttach }
            if ($varsInfra[2]) { msrdDiagURIHealth }
            if ($global:msrdAVD) { if ($varsInfra[3]) { msrdDiagHCI } }
            if ($varsInfra[4]) { msrdDiagHealthCheck }
            if ($varsInfra[5]) { msrdDiagHP }
            if ($varsInfra[6]) { msrdDiagMonitoring }
            
        }
        if ($varsInfra[7]) { msrdDiagShortpath }
        if ($varsInfra[8] -or ($global:msrdW365 -and $varsInfra[9])) { msrdDiagURL }
    }

    #ad
    if ($varsAD[0]) { msrdDiagEntraJoin }
    if ($varsAD[1]) { msrdDiagDC }

    #networking
    if ($varsNET[0]) { msrdDiagNWCore }
    if ($varsNET[1]) { msrdDiagDNS }
    if ($varsNET[2]) { msrdDiagFirewall }
    if ($varsNET[3]) { msrdDiagIPAddresses }
    if ($varsNET[4]) { msrdDiagPortUsage }
    if ($varsNET[5]) { msrdDiagProxy }
    if ($varsNET[6]) { msrdDiagRouting }
    if ($varsNET[7]) { msrdDiagVPN }

    #logon/security
    if ($varsLogSec[0]) { msrdDiagAuth }
    if ($varsLogSec[1]) { msrdDiagSecurity }
    if ($varsLogSec[2]) { msrdDiagSmartCard }

    #known issues
    if ($varsIssues[0]) {
        msrdLogDiag $LogLevel.Normal -Message "Issues identified in Event Logs over the past 5 days" -DiagTag "IssuesCheck"
        if ($global:msrdTarget) {
            if ($global:msrdAVD -or $global:msrdW365) {
                msrdDiagAVDIssueEvents
                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            }

            $needDL = $false
            if ($script:foundRDS.Name -eq "RDS-Licensing") { msrdDiagRDLicensingIssueEvents; $needDL = $true }
            if ($script:foundRDS.Name -eq "RDS-GATEWAY") { msrdDiagRDGatewayIssueEvents; $needDL = $true }
            if ($needDL) { msrdLogDiag $LogLevel.DiagFileOnly -Type "HR" }
            msrdDiagRDIssueEvents
            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        }

        msrdDiagCommonIssueEvents
    }
    
    if ($global:msrdTarget) { if ($varsIssues[1]) { msrdDiagLogonIssues } }

    #other
    if ($global:msrdTarget) {
        if ($varsOther[0]) { msrdDiagOffice }
        if ($varsOther[1]) { msrdDiagOD }
    }
    if ($varsOther[2]) { msrdDiagPrinting }
    if ($varsOther[3]) { msrdDiagCitrix3P }

    msrdHtmlEnd $msrdDiagFile
    msrdHtmlSetIssueCounter -htmloutfile "$msrdDiagFile"
}

Export-ModuleMember -Function *
# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCChLamuG7TNuDMt
# MMIAISFD4e4sYymQg5GPLj16ZxMRBqCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBt4JVBjT93qrjbC9kIVxHfE
# BAeRyxbt2aQ0yERdb/3qMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAll86CYwXC7AwcqKpE5HQ7aM1IYTETYHjKRsAq8iKvnIkJIeI1i61JeoT
# v43RdO7FQllqEVNxAvVIiq+WeV9+RBjQNQpY9PM66cpvJAW1N0T9+1nDsny2G1mD
# XyRoHSBsATkkB38fOhSICPDX5Xwd5fLYzmWyRkN0/uoE9q3Uob7GJMAouAXjepuT
# 8aFgLe7u7DBQ1QKDKc8bfcRa1MrbblTu8e2whumbYqg9v22f+Dxz/8woVfhPZrLs
# oo8dKohjUwsZAj+88cH1eGuPOaoU6rhbp3dRcJYHRW7T0zbbfHkaIyh7hIUOdnmR
# x0QgnRjf122DMnu5T/xWswF4ma0cQKGCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCCg2piZm3ybKLisULnCEhieVBOW2Usj/c1MrU8+FVFgCgIGZlPX9RhT
# GBMyMDI0MDYxMjE1MDA0MS40MzNaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OjJBRDQtNEI5Mi1GQTAxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHenkielp8oRD0AAQAAAd4wDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMx
# MDEyMTkwNzEyWhcNMjUwMTEwMTkwNzEyWjCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjoyQUQ0LTRC
# OTItRkEwMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALSB9ByF9UIDhA6xFrOniw/x
# sDl8sSi9rOCOXSSO4VMQjnNGAo5VHx0iijMEMH9LY2SUIBkVQS0Ml6kR+TagkUPb
# aEpwjhQ1mprhRgJT/jlSnic42VDAo0en4JI6xnXoAoWoKySY8/ROIKdpphgI7OJb
# 4XHk1P3sX2pNZ32LDY1ktchK1/hWyPlblaXAHRu0E3ynvwrS8/bcorANO6Djuysy
# S9zUmr+w3H3AEvSgs2ReuLj2pkBcfW1UPCFudLd7IPZ2RC4odQcEPnY12jypYPnS
# 6yZAs0pLpq0KRFUyB1x6x6OU73sudiHON16mE0l6LLT9OmGo0S94Bxg3N/3aE6fU
# bnVoemVc7FkFLum8KkZcbQ7cOHSAWGJxdCvo5OtUtRdSqf85FklCXIIkg4sm7nM9
# TktUVfO0kp6kx7mysgD0Qrxx6/5oaqnwOTWLNzK+BCi1G7nUD1pteuXvQp8fE1Kp
# TjnG/1OJeehwKNNPjGt98V0BmogZTe3SxBkOeOQyLA++5Hyg/L68pe+DrZoZPXJa
# GU/iBiFmL+ul/Oi3d83zLAHlHQmH/VGNBfRwP+ixvqhyk/EebwuXVJY+rTyfbRfu
# h9n0AaMhhNxxg6tGKyZS4EAEiDxrF9mAZEy8e8rf6dlKIX5d3aQLo9fDda1ZTOw+
# XAcAvj2/N3DLVGZlHnHlAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUazAmbxseaapg
# dxzK8Os+naPQEsgwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAOKUwHsXDacGOvUI
# gs5HDgPs0LZ1qyHS6C6wfKlLaD36tZfbWt1x+GMiazSuy+GsxiVHzkhMW+FqK8gr
# uLQWN/sOCX+fGUgT9LT21cRIpcZj4/ZFIvwtkBcsCz1XEUsXYOSJUPitY7E8bbld
# mmhYZ29p+XQpIcsG/q+YjkqBW9mw0ru1MfxMTQs9MTDiD28gAVGrPA3NykiSChvd
# qS7VX+/LcEz9Ubzto/w28WA8HOCHqBTbDRHmiP7MIj+SQmI9VIayYsIGRjvelmNa
# 0OvbU9CJSz/NfMEgf2NHMZUYW8KqWEjIjPfHIKxWlNMYhuWfWRSHZCKyIANA0aJL
# 4soHQtzzZ2MnNfjYY851wHYjGgwUj/hlLRgQO5S30Zx78GqBKfylp25aOWJ/qPhC
# +DXM2gXajIXbl+jpGcVANwtFFujCJRdZbeH1R+Q41FjgBg4m3OTFDGot5DSuVkQg
# jku7pOVPtldE46QlDg/2WhPpTQxXH64sP1GfkAwUtt6rrZM/PCwRG6girYmnTRLL
# sicBhoYLh+EEFjVviXAGTk6pnu8jx/4WPWu0jsz7yFzg82/FMqCk9wK3LvyLAyDH
# N+FxbHAxtgwad7oLQPM0WGERdB1umPCIiYsSf/j79EqHdoNwQYROVm+ZX10RX3n6
# bRmAnskeNhi0wnVaeVogLMdGD+nqMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
# bmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjoy
# QUQ0LTRCOTItRkEwMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUAaKBSisy4y86pl8Xy22CJZExE2vOggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOoUFbMwIhgPMjAyNDA2MTIyMDQwMTlaGA8yMDI0MDYxMzIwNDAxOVowdDA6Bgor
# BgEEAYRZCgQBMSwwKjAKAgUA6hQVswIBADAHAgEAAgIEhzAHAgEAAgIRVzAKAgUA
# 6hVnMwIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAID
# B6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAGFL59YCBkRtE/kXIuqT
# DDn0DN2V20S2IbSdC98/D0FKpVG5fdXi03xaWiKcs6+VzTW7+lrZ4tyjqzst4W4U
# gT7kAyomUZYUlQxJcVtvzpQ4Qw6htGl5jioomd1Ksn21I2eRx31ZLqjDqiR867EV
# zm3J9wxEYZ+lTfab54SYX1fUMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBIDIwMTACEzMAAAHenkielp8oRD0AAQAAAd4wDQYJYIZIAWUDBAIB
# BQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
# IgQgDVV4/SmDVmxS7IL7vPgJlRvq0FCP5kr5fwdDTDRHce4wgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCCOPiOfDcFeEBBJAn/mC3MgrT5w/U2z81LYD44Hc34d
# ezCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB3p5I
# npafKEQ9AAEAAAHeMCIEIADg4pUha2+tmkZaUGNLbqkao2c16edPXDl4uEQ80Loj
# MA0GCSqGSIb3DQEBCwUABIICAAC8SLJGVro1oamlLEMCqRpp7pXvEEnXZMhTiBWB
# 2ioqk3qrGxKOHfPMGo5fTTxcK02tS5IAIkSGV3eJ6GtVfbRIlFkhceEB3CxDhOXG
# YWC0X6R4OeKsYoUnY1kpfKC6PJ9s7ThBVrjvchNOcGcYx8GXo5+xpYsFODmAdCfs
# xekmSMR9peNqCfgdQx/OScQ/zehnhtgjJ4kipUIE++tWQA9qzwQgdVjEVSEheTh+
# GfTn56iZLNnqAxVaFK4QIIckqIHvHTIiAqvoySjDXQD2CQqSXaDwkW+aL55GgOL+
# 1PZLOAQq3pSS/j7lTbb2u6D3lFLv1a/HXwJiXQ6vNN0H4XbwqWDThjuyUiq1wb5c
# XWyPyTH02iNTz3vQw5RiZQEA/QQooAnCuLZuk39Mgt2NQw9pvWyiuc85Bb4DCNxY
# mG4Cqyk1qEvwy3GIHHleVZUAtwzLQz6ULj8CG2SjtHX88dULCq8NU8DyNPSj3XM+
# c0s2BP2L7izAIFRfiLWQF2voG/tML04Nk/zcGmrQCjwNUyOscylxz+oJQFtvZKTZ
# UDJ890QYDNz7PcRIyOnIuf8t8nE1jXSdwc1TuIm/cXDKNi7AZ+X3/c1VBCHul0lE
# FrWoQtNBH7W+1n2OFhp5JO0YsKhagwF0tOKFi11WBtjpnPZfCCEpCrM+gQB6DBBa
# 0LTX
# SIG # End signature block
