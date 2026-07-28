<#
.SYNOPSIS
   MSRD-Collect graphical user interface (Lite version)

.DESCRIPTION
   Module for the MSRD-Collect graphical user interface (Lite version)

.NOTES
   Author     : Robert Klemencz
   Requires   : MSRD-Collect.ps1
   Version    : See MSRD-Collect.ps1 version
   Feedback   : https://aka.ms/MSRD-Collect-Feedback
#>

#region config variables
$script:varsCore = @(,$true * 12)
$script:vCore = $script:varsCore

$script:varsProfiles = @(,$true * 5)
$script:varsActivation = @(,$true * 3)
$script:varsMSRA = @(,$true * 6)
$script:varsSCard = @(,$true * 3)
$script:varsIME = @(,$true * 3)
$script:varsTeams = @(,$true * 4)
$script:varsMSIXAA = @(,$true * 1)
$script:varsHCI = @(,$true * 1)

$script:varsNO = $false

$script:varsSystem = @(,$true * 12)
$script:varsAVDRDS = @(,$true * 11)
$script:varsInfra = @(,$true * 10)
$script:varsAD = @(,$true * 2)
$script:varsNET = @(,$true * 8)
$script:varsLogSec = @(,$true * 3)
$script:varsIssues = @(,$true * 2)
$script:varsOther = @(,$true * 4)

$script:dumpProc = $False; $script:pidProc = ""
$script:traceNet = $False; $global:onlyDiag = $false
#endregion config variables


#region GUI functions

function msrdStartBtnCollect {
    if (-not $global:btnTeamsClick) {
        $TeamsLogs = msrdGetLocalizedText "teamsnote"
        $wshell = New-Object -ComObject Wscript.Shell
        $teamstitle = msrdGetLocalizedText "teamstitle"
        $answer = $wshell.Popup("$TeamsLogs",0,"$teamstitle",5+48)
        if ($answer -eq 4) { $GetTeamsLogs = $false } else { $GetTeamsLogs = $true }
    } else {
        $GetTeamsLogs = $false
    }

    msrdInitFolders

    if (-not $GetTeamsLogs) {
        $btnStart.Text = msrdGetLocalizedText "Running"
        if (-not $global:onlyDiag) {
            $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "rdcmsg"
        } else {
			$global:msrdStatusBarLabel.Text = msrdGetLocalizedText "rdiagmsg"
		}

        msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues1a) $global:msrdVersion $(msrdGetLocalizedText initvalues1b) $global:msrdScriptpath ($global:msrdAdminlevel)"
        msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues1c) $global:msrdCmdLine"
        msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues2)"
        msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues3) $global:msrdLogRoot"
        msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues4) $global:msrdUserprof`n"
        msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText dpidtext3) $script:pidProc"

        $selectedScenarios = @()

        $checkboxes = @(
            $TbAVD, $TbRDS, $TbW365,
            $TbSource, $TbTarget,
            $TbCore, $TbProfiles, $TbActivation, $TbMSRA, $TbSCard, $TbIME, $TbTeams, $TbMSIXAA, $TbHCI, $TbProcDump, $TbNetTrace, $TbDiagOnly
        )

        foreach ($checkbox in $checkboxes) {
            if ($checkbox.Checked) {
                $selectedScenarios += $checkbox.Text
            }
        }

        $selectedScenariosString = $selectedScenarios -join ", "

        msrdLogMessage $LogLevel.InfoLogFileOnly "Selected parameters for data collection/diagnostics: $selectedScenariosString`n"

        if (-not $global:onlyDiag) {
            #data collection
            $parameters = @{
                varsCore = $script:vCore
                varsProfiles = $script:vProfiles
                varsActivation = $script:vActivation
                varsMSRA = $script:vMSRA
                varsSCard = $script:vSCard
                varsIME = $script:vIME
                varsTeams = $script:vTeams
                varsMSIXAA = $script:vMSIXAA
                varsHCI = $script:vHCI
                traceNet = $script:traceNet
                dumpProc = $script:dumpProc
                pidProc = $script:pidProc
            }
            msrdCollectData @parameters
        }

        #diagnostics
        $parameters = @{
            varsSystem = $script:varsSystem
            varsAVDRDS = $script:varsAVDRDS
            varsInfra = $script:varsInfra
            varsAD = $script:varsAD
            varsNET = $script:varsNET
            varsLogSec = $script:varsLogSec
            varsIssues = $script:varsIssues
            varsOther = $script:varsOther
        }
        msrdCollectDataDiag @parameters

        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "archmsg"
        msrdArchiveData -varsCore $script:vCore
        $btnStart.Text = msrdGetLocalizedText "Start"
        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
    }
}

Function msrdInitMachines {
    param ([bool[]]$Machine = @($false, $false, $false))

    if ($Machine[0]) { $global:msrdAVD = $true; $global:msrdRDS = $False; $global:msrdW365 = $False }
    elseif ($Machine[1]) { $global:msrdAVD = $False; $global:msrdRDS = $true; $global:msrdW365 = $False }
    elseif ($Machine[2]) { $global:msrdAVD = $False; $global:msrdRDS = $False; $global:msrdW365 = $true }
    else { $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False }
}

Function msrdInitRoles {
    param ([bool[]]$Role = @($false, $false))

    if ($Role[0]) { $global:msrdSource = $true; $global:msrdTarget = $False }
    elseif ($Role[1]) { $global:msrdSource = $False; $global:msrdTarget = $true }
    else {
        $global:msrdSource = $false; $global:msrdTarget = $false
    }
}

Function msrdShowHideItems {
    param ($category, $show=$false)

    if ($category -eq "Role") {
        if ($show) {
			$roleLabel.Visible = $true; $btnSource.Visible = $true; $btnTarget.Visible = $true
            $scenarioLabel.Visible = $false; $btnCore.Visible = $false; $btnDiagOnly.Visible = $false
            $btnProfiles.Visible = $false; $btnActivation.Visible = $false; $btnMSRA.Visible = $false; $btnSCard.Visible = $false; $btnIME.Visible = $false; $btnTeams.Visible = $false; $btnMSIXAA.Visible = $false; $btnHCI.Visible = $false
            $btnStart.Visible = $false
		} else {
			$roleLabel.Visible = $false; $btnSource.Visible = $false; $btnTarget.Visible = $false
            $scenarioLabel.Visible = $false; $btnCore.Visible = $false; $btnDiagOnly.Visible = $false
            $btnProfiles.Visible = $false; $btnActivation.Visible = $false; $btnMSRA.Visible = $false; $btnSCard.Visible = $false; $btnIME.Visible = $false; $btnTeams.Visible = $false; $btnMSIXAA.Visible = $false; $btnHCI.Visible = $false
            $btnStart.Visible = $false
		}
    } elseif ($category -eq "Scenario") {
		if ($show) {
            $scenarioLabel.Visible = $true; $btnCore.Visible = $true; $btnDiagOnly.Visible = $true
            $btnProfiles.Visible = $true; $btnActivation.Visible = $true; $btnMSRA.Visible = $true; $btnSCard.Visible = $true; $btnIME.Visible = $true; $btnTeams.Visible = $true; $btnMSIXAA.Visible = $true; $btnHCI.Visible = $true
            $btnStart.Visible = $true
        } else {
            $scenarioLabel.Visible = $false; $btnCore.Visible = $false; $btnDiagOnly.Visible = $false
            $btnProfiles.Visible = $false; $btnActivation.Visible = $false; $btnMSRA.Visible = $false; $btnSCard.Visible = $false; $btnIME.Visible = $false; $btnTeams.Visible = $false; $btnMSIXAA.Visible = $false; $btnHCI.Visible = $false
            $btnStart.Visible = $false
        }
    } elseif ($category -eq "Start") {
        if ($show) {
			$startLabel.Visible = $true
		} else {
			$startLabel.Visible = $false
		}
	}

}

#endregion GUI functions

Function msrdAVDCollectGUILite {

    $global:msrdGUIformLite = New-Object System.Windows.Forms.Form

    $global:msrdGUIformLite.Size = New-Object System.Drawing.Size(630, 500)
    $global:msrdGUIformLite.StartPosition = "CenterScreen"
    $global:msrdGUIformLite.BackColor = "#eeeeee"
    $global:msrdGUIformLite.MaximizeBox = $false
    $global:msrdGUIformLite.Icon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\Config\MSRDC-Icons.dll", 12, $true))
    if ($script:msrdDevLevel -eq "Insider") {
        $global:msrdGUIformLite.Text = 'MSRD-Collect Lite (v' + $global:msrdVersion + ') INSIDER Build - For Testing Purposes Only !'
    } else {
        $global:msrdGUIformLite.Text = 'MSRD-Collect Lite (v' + $global:msrdVersion + ')'
    }
    $global:msrdGUIformLite.TopLevel = $true
    $global:msrdGUIformLite.TopMost = $false
    $global:msrdGUIformLite.FormBorderStyle = "FixedDialog"

    #region GUI elements
    $machineLabel = New-Object System.Windows.Forms.Label
    $machineLabel.Size = New-Object System.Drawing.Size(610, 20)
    $machineLabel.Location = New-Object System.Drawing.Point(0, 20)
    $machineLabel.Text = msrdGetLocalizedText "LiteModeMachine" # Machine type
    $machineLabel.TextAlign = "MiddleCenter"
    $machineLabel.Font = New-Object Drawing.Font($machineLabel.Font, [Drawing.FontStyle]::Bold)
    $global:msrdGUIformLite.Controls.Add($machineLabel)

    $global:btnColor = ""
    $global:btnIdleColor = "Lightgray"

    $btnAVD = New-Object System.Windows.Forms.Button
    $btnAVD.Size = New-Object System.Drawing.Size(150, 40)
    $btnAVD.Location = New-Object System.Drawing.Point(70, 40)
    $btnAVD.BackColor = "Lightblue"
    $btnAVD.Text = "Azure Virtual Desktop"
    $btnAVDToolTip = New-Object System.Windows.Forms.ToolTip
    $btnAVDToolTip.SetToolTip($btnAVD, $(msrdGetLocalizedText "btnTooltipAVD"))
    $global:msrdGUIformLite.Controls.Add($btnAVD)

    $global:btnAVDclick = $true
    $btnAVD.Add_Click({
        $global:btnColor = "Lightblue"
        msrdInitScenarioVars

        if ($global:btnAVDclick) {
            msrdShowHideItems -category "Role" -show $true
            msrdInitMachines -Machine @($true, $false, $false)

            $btnRDS.Enabled = $false; $btnW365.Enabled = $false
            $btnRDS.ResetBackColor(); $btnW365.ResetBackColor()
            $btnSource.Enabled = $true; $btnTarget.Enabled = $true
            $btnSource.BackColor = $global:btnColor; $btnTarget.BackColor = $global:btnColor

            $btnTarget.Text = msrdGetLocalizedText "LiteModeTarget"
            $btnTargetToolTip.SetToolTip($btnTarget, $(msrdGetLocalizedText "LiteModeTargetTooltip"))
        } else {
            msrdInitMachines
            msrdInitRoles

            $btnRDS.Enabled = $true; $btnW365.Enabled = $true
            $btnRDS.BackColor = "Pink"; $btnW365.BackColor = "Lightyellow"
            $btnSource.Enabled = $false; $btnTarget.Enabled = $false
            $btnSource.ResetBackColor(); $btnTarget.ResetBackColor()

            $global:btnSourceClick = $true; $global:btnTargetClick = $true;
            $global:btnProfilesClick = $true; $global:btnActivationClick = $true; $global:btnMSRAClick = $true; $global:btnSCardClick = $true;
            $global:btnIMEClick = $true; $global:btnTeamsClick = $true; $global:btnMSIXAAClick = $true; $global:btnHCIClick = $true;
            $global:btnDiagOnlyClick = $true
            $btnProfiles.Enabled = $false; $btnActivation.Enabled = $false; $btnMSRA.Enabled = $false; $btnSCard.Enabled = $false;
            $btnIME.Enabled = $false; $btnTeams.Enabled = $false; $btnMSIXAA.Enabled = $false; $btnHCI.Enabled = $false;
            $btnProfiles.ResetBackColor(); $btnActivation.ResetBackColor(); $btnMSRA.ResetBackColor(); $btnSCard.ResetBackColor();
            $btnIME.ResetBackColor(); $btnTeams.ResetBackColor(); $btnMSIXAA.ResetBackColor(); $btnHCI.ResetBackColor(); $btnDiagOnly.ResetBackColor(); $btnCore.ResetBackColor();

            $btnStart.Enabled = $false; $btnStart.ResetBackColor();

            $global:onlyDiag = $false
            $script:vCore = $script:varsCore
            msrdShowHideItems -category "Role" -show $false
        }
        $global:btnAVDclick = (-not $global:btnAVDclick)
    })

    $btnRDS = New-Object System.Windows.Forms.Button
    $btnRDS.Size = New-Object System.Drawing.Size(150, 40)
    $btnRDS.Location = New-Object System.Drawing.Point(230, 40)
    $btnRDS.BackColor = "Pink"
    $btnRDS.Text = "Remote Desktop Services"
    $btnRDSToolTip = New-Object System.Windows.Forms.ToolTip
    $btnRDSToolTip.SetToolTip($btnRDS, $(msrdGetLocalizedText "btnTooltipRDS"))
    $global:msrdGUIformLite.Controls.Add($btnRDS)

    $global:btnRDSclick = $true
    $btnRDS.Add_Click({
        $global:btnColor = "Pink"
        msrdInitScenarioVars

        if ($global:btnRDSclick) {
            msrdShowHideItems -category "Role" -show $true
            msrdInitMachines -Machine @($false, $true, $false)

            $btnAVD.Enabled = $false; $btnW365.Enabled = $false
            $btnAVD.ResetBackColor(); $btnW365.ResetBackColor()
            $btnSource.Enabled = $true; $btnTarget.Enabled = $true
            $btnSource.BackColor = $global:btnColor; $btnTarget.BackColor = $global:btnColor

            $btnTarget.Text = msrdGetLocalizedText "LiteModeTarget2"
            $btnTargetToolTip.SetToolTip($btnTarget, $(msrdGetLocalizedText "LiteModeTargetTooltip2"))
        } else {
            msrdInitMachines
            msrdInitRoles

            $btnAVD.Enabled = $true; $btnW365.Enabled = $true
            $btnAVD.BackColor = "Lightblue"; $btnW365.BackColor = "Lightyellow"
            $btnSource.Enabled = $false; $btnTarget.Enabled = $false
            $btnSource.ResetBackColor(); $btnTarget.ResetBackColor()

            $global:btnSourceClick = $true; $global:btnTargetClick = $true;
            $global:btnProfilesClick = $true; $global:btnActivationClick = $true; $global:btnMSRAClick = $true; $global:btnSCardClick = $true;
            $global:btnIMEClick = $true; $global:btnTeamsClick = $true; $global:btnMSIXAAClick = $true; $global:btnHCIClick = $true;
            $global:btnDiagOnlyClick = $true
            $btnProfiles.Enabled = $false; $btnActivation.Enabled = $false; $btnMSRA.Enabled = $false; $btnSCard.Enabled = $false;
            $btnIME.Enabled = $false; $btnTeams.Enabled = $false; $btnMSIXAA.Enabled = $false; $btnHCI.Enabled = $false; $btnDiagOnly.Enabled = $false;
            $btnProfiles.ResetBackColor(); $btnActivation.ResetBackColor(); $btnMSRA.ResetBackColor(); $btnSCard.ResetBackColor();
            $btnIME.ResetBackColor(); $btnTeams.ResetBackColor(); $btnMSIXAA.ResetBackColor(); $btnHCI.ResetBackColor(); $btnDiagOnly.ResetBackColor(); $btnCore.ResetBackColor();

            $btnStart.Enabled = $false; $btnStart.ResetBackColor();

            $global:onlyDiag = $false
            $script:vCore = $script:varsCore
            $btnTarget.Text = "Target machine / Host"
            msrdShowHideItems -category "Role" -show $false
        }
        $global:btnRDSclick = (-not $global:btnRDSclick)
    })

    $btnW365 = New-Object System.Windows.Forms.Button
    $btnW365.Size = New-Object System.Drawing.Size(150, 40)
    $btnW365.Location = New-Object System.Drawing.Point(390, 40)
    $btnW365.BackColor = "Lightyellow"
    $btnW365.Text = "Windows 365 Cloud PC"
    $btnW365ToolTip = New-Object System.Windows.Forms.ToolTip
    $btnW365ToolTip.SetToolTip($btnW365, $(msrdGetLocalizedText "btnTooltipW365"))
    $global:msrdGUIformLite.Controls.Add($btnW365)

    $global:btnW365click = $true
    $btnW365.Add_Click({
        $global:btnColor = "Lightyellow"
        msrdInitScenarioVars

        if ($global:btnW365click) {
            msrdShowHideItems -category "Role" -show $true
            msrdInitMachines -Machine @($false, $false, $true)

            $btnAVD.Enabled = $false; $btnRDS.Enabled = $false
            $btnAVD.ResetBackColor(); $btnRDS.ResetBackColor()
            $btnSource.Enabled = $true; $btnTarget.Enabled = $true
            $btnSource.BackColor = $global:btnColor; $btnTarget.BackColor = $global:btnColor

            $btnTarget.Text = msrdGetLocalizedText "LiteModeTarget"
            $btnTargetToolTip.SetToolTip($btnTarget, $(msrdGetLocalizedText "LiteModeTargetTooltip"))
        } else {
            msrdInitMachines
            msrdInitRoles

            $btnAVD.Enabled = $true; $btnRDS.Enabled = $true
            $btnAVD.BackColor = "Lightblue"; $btnRDS.BackColor = "Pink"
            $btnSource.Enabled = $false; $btnTarget.Enabled = $false
            $btnSource.ResetBackColor(); $btnTarget.ResetBackColor()

            $global:btnSourceClick = $true; $global:btnTargetClick = $true;
            $global:btnProfilesClick = $true; $global:btnActivationClick = $true; $global:btnMSRAClick = $true; $global:btnSCardClick = $true;
            $global:btnIMEClick = $true; $global:btnTeamsClick = $true; $global:btnMSIXAAClick = $true; $global:btnHCIClick = $true;
            $global:btnDiagOnlyClick = $true
            $btnProfiles.Enabled = $false; $btnActivation.Enabled = $false; $btnMSRA.Enabled = $false; $btnSCard.Enabled = $false;
            $btnIME.Enabled = $false; $btnTeams.Enabled = $false; $btnMSIXAA.Enabled = $false; $btnHCI.Enabled = $false; $btnDiagOnly.Enabled = $false;
            $btnProfiles.ResetBackColor(); $btnActivation.ResetBackColor(); $btnMSRA.ResetBackColor(); $btnSCard.ResetBackColor();
            $btnIME.ResetBackColor(); $btnTeams.ResetBackColor(); $btnMSIXAA.ResetBackColor(); $btnHCI.ResetBackColor(); $btnDiagOnly.ResetBackColor(); $btnCore.ResetBackColor();

            $btnStart.Enabled = $false; $btnStart.ResetBackColor();

            $global:onlyDiag = $false
            $script:vCore = $script:varsCore
            msrdShowHideItems -category "Role" -show $false
        }
        $global:btnW365click = (-not $global:btnW365click)
    })

    $roleLabel = New-Object System.Windows.Forms.Label
    $roleLabel.Size = New-Object System.Drawing.Size(610, 20)
    $roleLabel.Location = New-Object System.Drawing.Point(0, 100)
    $roleLabel.Text = msrdGetLocalizedText "LiteModeRole" # "Role"
    $roleLabel.Textalign = "MiddleCenter"
    $roleLabel.Font = New-Object Drawing.Font($roleLabel.Font, [Drawing.FontStyle]::Bold)
    $global:msrdGUIformLite.Controls.Add($roleLabel)

    $btnSource = New-Object System.Windows.Forms.Button
    $btnSource.Size = New-Object System.Drawing.Size(150, 40)
    $btnSource.Location = New-Object System.Drawing.Point(150, 120)
    $btnSource.Text = msrdGetLocalizedText "LiteModeSource"
    $btnSourceToolTip = New-Object System.Windows.Forms.ToolTip
    $btnSourceToolTip.SetToolTip($btnSource, $(msrdGetLocalizedText "LiteModeSourceTooltip"))
    $global:msrdGUIformLite.Controls.Add($btnSource)

    $global:btnSourceClick = $true
    $btnSource.Add_Click({
        msrdInitScenarioVars

        if ($global:btnSourceClick) {
            msrdShowHideItems -category "Scenario" -show $true
            msrdShowHideItems -category "Start" -show $true
            msrdInitRoles -Role @($true, $false)

            $btnTarget.Enabled = $false
            $btnTarget.ResetBackColor()

            $btnCore.BackColor = $global:btnColor;
            $btnProfiles.Enabled = $false; $btnActivation.Enabled = $false; $btnMSRA.Enabled = $false; $btnSCard.Enabled = $false;
            $btnIME.Enabled = $false; $btnTeams.Enabled = $false; $btnMSIXAA.Enabled = $false; $btnHCI.Enabled = $false; $btnDiagOnly.Enabled = $false;
            $btnProfiles.ResetBackColor(); $btnActivation.ResetBackColor(); $btnMSRA.ResetBackColor(); $btnSCard.ResetBackColor();
            $btnIME.ResetBackColor(); $btnTeams.ResetBackColor(); $btnMSIXAA.ResetBackColor(); $btnHCI.ResetBackColor();
            $btnDiagOnly.Enabled = $true; $btnDiagOnly.BackColor = $global:btnIdleColor;
            $btnStart.Enabled = $true; $btnStart.BackColor = $global:btnColor;
        } else {
            msrdInitRoles

            $btnTarget.Enabled = $true
            $btnTarget.BackColor = $global:btnColor
            $global:btnDiagOnlyClick = $true

            $btnCore.ResetBackColor();
            $btnProfiles.Enabled = $false; $btnActivation.Enabled = $false; $btnMSRA.Enabled = $false; $btnSCard.Enabled = $false;
            $btnIME.Enabled = $false; $btnTeams.Enabled = $false; $btnMSIXAA.Enabled = $false; $btnHCI.Enabled = $false;
            $btnProfiles.ResetBackColor(); $btnActivation.ResetBackColor(); $btnMSRA.ResetBackColor(); $btnSCard.ResetBackColor();
            $btnIME.ResetBackColor(); $btnTeams.ResetBackColor(); $btnMSIXAA.ResetBackColor(); $btnHCI.ResetBackColor();
            $btnDiagOnly.Enabled = $false; $btnDiagOnly.ResetBackColor();
            $btnStart.Enabled = $false; $btnStart.ResetBackColor();

            $global:onlyDiag = $false
            $script:vCore = $script:varsCore
            msrdShowHideItems -category "Scenario" -show $false
            msrdShowHideItems -category "Start" -show $false
        }
        $global:btnSourceClick = (-not $global:btnSourceClick)
    })

    $btnTarget = New-Object System.Windows.Forms.Button
    $btnTarget.Size = New-Object System.Drawing.Size(150, 40)
    $btnTarget.Location = New-Object System.Drawing.Point(310, 120)
    $btnTarget.Text = msrdGetLocalizedText "LiteModeTarget"
    $btnTargetToolTip = New-Object System.Windows.Forms.ToolTip
    $global:msrdGUIformLite.Controls.Add($btnTarget)

    $global:btnTargetClick = $true
    $btnTarget.Add_Click({
        msrdInitScenarioVars

        if ($global:btnTargetClick) {
            msrdShowHideItems -category "Scenario" -show $true
            msrdShowHideItems -category "Start" -show $true
            msrdInitRoles -Role @($false, $true)

            $btnSource.Enabled = $false
            $btnSource.ResetBackColor()

            if (-not $global:btnAVDClick) {
                $btnMSRA.Enabled = $true; $btnTeams.Enabled = $true;  $btnMSIXAA.Enabled = $true; $btnHCI.Enabled = $true;
                $btnMSRA.BackColor = $global:btnIdleColor; $btnTeams.BackColor = $global:btnIdleColor; $btnMSIXAA.BackColor = $global:btnIdleColor; $btnHCI.BackColor = $global:btnIdleColor;
            } elseif (-not $global:btnRDSClick) {
                $btnMSRA.Enabled = $true;
                $btnMSRA.BackColor = $global:btnIdleColor;
            } elseif (-not $global:btnW365Click) {
                $btnTeams.Enabled = $true;
                $btnTeams.BackColor = $global:btnIdleColor;
            }

            $btnCore.BackColor = $global:btnColor;
            $btnProfiles.Enabled = $true; $btnActivation.Enabled = $true; $btnSCard.Enabled = $true; $btnIME.Enabled = $true;
            $btnProfiles.BackColor = $global:btnIdleColor; $btnActivation.BackColor = $global:btnIdleColor; $btnSCard.BackColor = $global:btnIdleColor; $btnIME.BackColor = $global:btnIdleColor;
            $btnDiagOnly.Enabled = $true; $btnDiagOnly.BackColor = $global:btnIdleColor;
            $btnStart.Enabled = $true; $btnStart.BackColor = $global:btnColor;

        } else {
            msrdInitRoles

            $btnSource.Enabled = $true
            $btnSource.BackColor = $global:btnColor
            $global:btnDiagOnlyClick = $true

            $btnCore.ResetBackColor();
            $btnProfiles.Enabled = $false; $btnActivation.Enabled = $false; $btnMSRA.Enabled = $false; $btnSCard.Enabled = $false;
            $btnIME.Enabled = $false; $btnTeams.Enabled = $false; $btnMSIXAA.Enabled = $false; $btnHCI.Enabled = $false;
            $btnProfiles.ResetBackColor(); $btnActivation.ResetBackColor(); $btnMSRA.ResetBackColor(); $btnSCard.ResetBackColor();
            $btnIME.ResetBackColor(); $btnTeams.ResetBackColor(); $btnMSIXAA.ResetBackColor(); $btnHCI.ResetBackColor();
            $btnDiagOnly.Enabled = $false; $btnDiagOnly.ResetBackColor();
            $btnStart.Enabled = $false; $btnStart.ResetBackColor();

            $global:onlyDiag = $false
            $script:vCore = $script:varsCore
            msrdShowHideItems -category "Scenario" -show $false
            msrdShowHideItems -category "Start" -show $false
        }
        $global:btnTargetClick = (-not $global:btnTargetClick)
    })

    $scenarioLabel = New-Object System.Windows.Forms.Label
    $scenarioLabel.Size = New-Object System.Drawing.Size(610, 20)
    $scenarioLabel.Location = New-Object System.Drawing.Point(0, 180)
    $scenarioLabel.Text = msrdGetLocalizedText "LiteModeScenarios" # "Scenarios"
    $scenarioLabel.TextAlign = "MiddleCenter"
    $scenarioLabel.Font = New-Object Drawing.Font($scenarioLabel.Font, [Drawing.FontStyle]::Bold)
    $global:msrdGUIformLite.Controls.Add($scenarioLabel)

    $btnCore = New-Object System.Windows.Forms.Button
    $btnCore.Size = New-Object System.Drawing.Size(100, 40)
    $btnCore.Location = New-Object System.Drawing.Point(35, 200)
    $btnCore.Text = "Core"
    $btnCore.Enabled = $false
    $global:msrdGUIformLite.Controls.Add($btnCore)

    $btnProfiles = New-Object System.Windows.Forms.Button
    $btnProfiles.Size = New-Object System.Drawing.Size(100, 40)
    $btnProfiles.Location = New-Object System.Drawing.Point(145, 200)
    $btnProfiles.Text = "Profiles"
    $btnProfilesToolTip = New-Object System.Windows.Forms.ToolTip
    $btnProfilesToolTip.SetToolTip($btnProfiles, "$(msrdGetLocalizedText 'btnTooltipProfiles')")
    $global:msrdGUIformLite.Controls.Add($btnProfiles)

    $global:btnProfilesClick = $true
    $btnProfiles.Add_Click({
        if ($global:btnProfilesClick) {
            $script:vProfiles = $script:varsProfiles; $btnProfiles.BackColor = $global:btnColor;
        } else {
            $script:vProfiles = $varsNO; $btnProfiles.ResetBackColor();
        }
        $global:btnProfilesClick = (-not $global:btnProfilesClick)
    })

    $btnActivation = New-Object System.Windows.Forms.Button
    $btnActivation.Size = New-Object System.Drawing.Size(100, 40)
    $btnActivation.Location = New-Object System.Drawing.Point(255, 200)
    $btnActivation.Text = "Activation"
    $btnActivationToolTip = New-Object System.Windows.Forms.ToolTip
    $btnActivationToolTip.SetToolTip($btnActivation, "$(msrdGetLocalizedText 'btnTooltipActivation')")
    $global:msrdGUIformLite.Controls.Add($btnActivation)

    $global:btnActivationClick = $true
    $btnActivation.Add_Click({
        if ($global:btnActivationClick) {
            $script:vActivation = $script:varsActivation; $btnActivation.BackColor = $global:btnColor;
        } else {
            $script:vActivation = $varsNO; $btnActivation.ResetBackColor();
        }
        $global:btnActivationClick = (-not $global:btnActivationClick)
    })

    $btnMSRA = New-Object System.Windows.Forms.Button
    $btnMSRA.Size = New-Object System.Drawing.Size(100, 40)
    $btnMSRA.Location = New-Object System.Drawing.Point(365, 200)
    $btnMSRA.Text = "Remote Assistance"
    $btnMSRAToolTip = New-Object System.Windows.Forms.ToolTip
    $btnMSRAToolTip.SetToolTip($btnMSRA, "$(msrdGetLocalizedText 'btnTooltipMSRA')")
    $global:msrdGUIformLite.Controls.Add($btnMSRA)

    $global:btnMSRAClick = $true
    $btnMSRA.Add_Click({
        if ($global:btnMSRAClick) {
            $script:vMSRA = $script:varsMSRA; $btnMSRA.BackColor = $global:btnColor;
        } else {
            $script:vMSRA = $varsNO; $btnMSRA.ResetBackColor();
        }
        $global:btnMSRAClick = (-not $global:btnMSRAClick)
    })

    $btnSCard = New-Object System.Windows.Forms.Button
    $btnSCard.Size = New-Object System.Drawing.Size(100, 40)
    $btnSCard.Location = New-Object System.Drawing.Point(475, 200)
    $btnSCard.Text = "Smart Card"
    $btnSCardToolTip = New-Object System.Windows.Forms.ToolTip
    $btnSCardToolTip.SetToolTip($btnSCard, "$(msrdGetLocalizedText 'btnTooltipSCard')")
    $global:msrdGUIformLite.Controls.Add($btnSCard)

    $global:btnSCardClick = $true
    $btnSCard.Add_Click({
        if ($global:btnSCardClick) {
            $script:vSCard = $script:varsSCard; $btnSCard.BackColor = $global:btnColor;
        } else {
            $script:vSCard = $varsNO; $btnSCard.ResetBackColor();
        }
        $global:btnSCardClick = (-not $global:btnSCardClick)
    })

    $btnIME = New-Object System.Windows.Forms.Button
    $btnIME.Size = New-Object System.Drawing.Size(100, 40)
    $btnIME.Location = New-Object System.Drawing.Point(35, 250)
    $btnIME.Text = "IME"
    $btnIMEToolTip = New-Object System.Windows.Forms.ToolTip
    $btnIMEToolTip.SetToolTip($btnIME, "$(msrdGetLocalizedText 'btnTooltipIME')")
    $global:msrdGUIformLite.Controls.Add($btnIME)

    $global:btnIMEClick = $true
    $btnIME.Add_Click({
        if ($global:btnIMEClick) {
            $script:vIME = $script:varsIME; $btnIME.BackColor = $global:btnColor;
        } else {
            $script:vIME = $varsNO; $btnIME.ResetBackColor();
        }
        $global:btnIMEClick = (-not $global:btnIMEClick)
    })

    $btnTeams = New-Object System.Windows.Forms.Button
    $btnTeams.Size = New-Object System.Drawing.Size(100, 40)
    $btnTeams.Location = New-Object System.Drawing.Point(145, 250)
    $btnTeams.Text = "Teams"
    $btnTeamsToolTip = New-Object System.Windows.Forms.ToolTip
    $btnTeamsToolTip.SetToolTip($btnTeams, "$(msrdGetLocalizedText 'btnTooltipTeams')")
    $global:msrdGUIformLite.Controls.Add($btnTeams)

    $global:btnTeamsClick = $true
    $btnTeams.Add_Click({
        if ($global:btnTeamsClick) {
            $script:vTeams = $script:varsTeams; $btnTeams.BackColor = $global:btnColor;
        } else {
            $script:vTeams = $varsNO; $btnTeams.ResetBackColor();
        }
        $global:btnTeamsClick = (-not $global:btnTeamsClick)
    })

    $btnMSIXAA = New-Object System.Windows.Forms.Button
    $btnMSIXAA.Size = New-Object System.Drawing.Size(100, 40)
    $btnMSIXAA.Location = New-Object System.Drawing.Point(255, 250)
    $btnMSIXAA.Text = "App Attach"
    $btnMSIXAAToolTip = New-Object System.Windows.Forms.ToolTip
    $btnMSIXAAToolTip.SetToolTip($btnMSIXAA, "$(msrdGetLocalizedText 'btnTooltipMSIXAA')")
    $global:msrdGUIformLite.Controls.Add($btnMSIXAA)

    $global:btnMSIXAAClick = $true
    $btnMSIXAA.Add_Click({
        if ($global:btnMSIXAAClick) {
            $script:vMSIXAA = $script:varsMSIXAA; $btnMSIXAA.BackColor = $global:btnColor;
        } else {
            $script:vMSIXAA = $varsNO; $btnMSIXAA.ResetBackColor();
        }
        $global:btnMSIXAAClick = (-not $global:btnMSIXAAClick)
    })

    $btnHCI = New-Object System.Windows.Forms.Button
    $btnHCI.Size = New-Object System.Drawing.Size(100, 40)
    $btnHCI.Location = New-Object System.Drawing.Point(365, 250)
    $btnHCI.Text = "Azure Stack HCI"
    $btnHCIToolTip = New-Object System.Windows.Forms.ToolTip
    $btnHCIToolTip.SetToolTip($btnHCI, "$(msrdGetLocalizedText 'btnTooltipHCI')")
    $global:msrdGUIformLite.Controls.Add($btnHCI)

    $global:btnHCIClick = $true
    $btnHCI.Add_Click({
        if ($global:btnHCIClick) {
            $script:vHCI = $script:varsHCI; $btnHCI.BackColor = $global:btnColor;
        } else {
            $script:vHCI = $varsNO; $btnHCI.ResetBackColor();
        }
        $global:btnHCIClick = (-not $global:btnHCIClick)
    })

    $btnDiagOnly = New-Object System.Windows.Forms.Button
    $btnDiagOnly.Size = New-Object System.Drawing.Size(100, 40)
    $btnDiagOnly.Location = New-Object System.Drawing.Point(475, 250)
    $btnDiagOnly.Text = "Diagnostics Only"
    $btnDiagOnlyToolTip = New-Object System.Windows.Forms.ToolTip
    $btnDiagOnlyToolTip.SetToolTip($btnDiagOnly, "$(msrdGetLocalizedText 'btnTooltipDiagOnly')")
    $global:msrdGUIformLite.Controls.Add($btnDiagOnly)

    $global:btnDiagOnlyClick = $true
    $btnDiagOnly.Add_Click({
        if ($global:btnDiagOnlyClick) {
            $global:onlyDiag = $true
            $script:vCore = $script:varsNO

            $btnDiagOnly.BackColor = $global:btnColor; $btnCore.ResetBackColor();
            $btnProfiles.Enabled = $false; $btnActivation.Enabled = $false; $btnMSRA.Enabled = $false; $btnSCard.Enabled = $false;
            $btnIME.Enabled = $false; $btnTeams.Enabled = $false; $btnMSIXAA.Enabled = $false; $btnHCI.Enabled = $false;
            $btnProfiles.ResetBackColor(); $btnActivation.ResetBackColor(); $btnMSRA.ResetBackColor(); $btnSCard.ResetBackColor();
            $btnIME.ResetBackColor(); $btnTeams.ResetBackColor(); $btnMSIXAA.ResetBackColor(); $btnHCI.ResetBackColor();
        } else {
            $global:onlyDiag = $false
            $script:vCore = $script:varsCore

            if (-not $btnTargetClick) {
                if (-not $global:btnAVDClick) {
                    $btnMSRA.Enabled = $true; $btnTeams.Enabled = $true;  $btnMSIXAA.Enabled = $true; $btnHCI.Enabled = $true;
                    $btnMSRA.BackColor = $global:btnIdleColor; $btnTeams.BackColor = $global:btnIdleColor; $btnMSIXAA.BackColor = $global:btnIdleColor; $btnHCI.BackColor = $global:btnIdleColor;
                } elseif (-not $global:btnRDSClick) {
                    $btnMSRA.Enabled = $true;
                    $btnMSRA.BackColor = $global:btnIdleColor;
                } elseif (-not $global:btnW365Click) {
                    $btnTeams.Enabled = $true;
                    $btnTeams.BackColor = $global:btnIdleColor;
                }
                $btnProfiles.Enabled = $true; $btnActivation.Enabled = $true; $btnSCard.Enabled = $true; $btnIME.Enabled = $true;
                $btnProfiles.BackColor = $global:btnIdleColor; $btnActivation.BackColor = $global:btnIdleColor; $btnSCard.BackColor = $global:btnIdleColor; $btnIME.BackColor = $global:btnIdleColor;
            }

            $global:btnProfilesClick = $true; $global:btnActivationClick = $true; $global:btnMSRAClick = $true; $global:btnSCardClick = $true;
            $global:btnIMEClick = $true; $global:btnTeamsClick = $true; $global:btnMSIXAAClick = $true; $global:btnHCIClick = $true;
            $btnDiagOnly.BackColor = $global:btnIdleColor; $btnCore.BackColor = $global:btnColor;
        }
        $global:btnDiagOnlyClick = (-not $global:btnDiagOnlyClick)
    })

    $startLabel = New-Object System.Windows.Forms.Label
    $startLabel.Size = New-Object System.Drawing.Size(610, 20)
    $startLabel.Location = New-Object System.Drawing.Point(0, 310)
    $startLabel.Text = msrdGetLocalizedText "LiteModeStart" # "Start"
    $startLabel.TextAlign = "MiddleCenter"
    $startLabel.Font = New-Object Drawing.Font($startLabel.Font, [Drawing.FontStyle]::Bold)
    $global:msrdGUIformLite.Controls.Add($startLabel)

    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Size = New-Object System.Drawing.Size(120, 40)
    $btnStart.Location = New-Object System.Drawing.Point(245, 330)
    $btnStart.Text = msrdGetLocalizedText "Start"
    $btnStartToolTip = New-Object System.Windows.Forms.ToolTip
    $btnStartToolTip.SetToolTip($btnStart, "$(msrdGetLocalizedText 'RunMenu')")
    $global:msrdGUIformLite.Controls.Add($btnStart)

    $btnStart.Add_Click({ msrdStartBtnCollect })

    msrdShowHideItems -category "Role" -show $false
    msrdShowHideItems -category "Scenario" -show $false
    msrdShowHideItems -category "Start" -show $false

    # Create the "Show console" checkbox and label
    $checkBoxShowConsole = New-Object System.Windows.Forms.CheckBox
    $checkBoxShowConsole.Text = msrdGetLocalizedText "LiteModeHideConsole"
    $checkBoxShowConsole.Location = New-Object System.Drawing.Point(20, 385)
    $checkBoxShowConsole.Size = New-Object System.Drawing.Size(150, 20)
    $global:msrdGUIformLite.Controls.Add($checkBoxShowConsole)
    $checkBoxShowConsole.Add_Click({
        if ($checkBoxShowConsole.Checked) {
            msrdStartShowConsole
            $checkBoxShowConsole.Checked = $true
        } else {
            msrdStartHideConsole
            $checkBoxShowConsole.Checked = $false
        }
    })

    # Create the "Advanced Mode" checkbox and label
    $checkBoxAdvancedMode = New-Object System.Windows.Forms.CheckBox
    $checkBoxAdvancedMode.Text = msrdGetLocalizedText "LiteModeAdvanced" # Advanced Mode
    $checkBoxAdvancedMode.Location = New-Object System.Drawing.Point(495, 385)
    $checkBoxAdvancedMode.Size = New-Object System.Drawing.Size(150, 20)
    $global:msrdGUIformLite.Controls.Add($checkBoxAdvancedMode)
    $checkBoxAdvancedMode.Add_Click({
        if ($checkBoxAdvancedMode.Checked) {
            try {
                $ScriptFile = $global:msrdScriptpath + "\MSRD-Collect.ps1"
                Start-Process PowerShell.exe -ArgumentList "$ScriptFile" -NoNewWindow
                msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "UILiteMode" -value 0
                If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
                If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
                if (($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) { $global:msrdGUIformLite.Close() } else { Exit }
            } catch {
                $failedCommand = $_.InvocationInfo.Line.TrimStart()
                msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
            }
        }
    })


    # Iterate through all controls on the form
    foreach ($control in $global:msrdGUIformLite.Controls) {
        # Check if the control is a Button
        if (($control -is [System.Windows.Forms.Button]) -or ($control -is [System.Windows.Forms.CheckBox])) {
            $control.Add_MouseEnter({ $this.Cursor = [System.Windows.Forms.Cursors]::Hand })
            $control.Add_MouseLeave({ $this.Cursor = [System.Windows.Forms.Cursors]::Default })
        }
    }
    #endregion GUI elements


    #region BottomOptions

    $global:msrdStatusBar = New-Object System.Windows.Forms.StatusStrip
    $global:msrdStatusBarLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
    $global:msrdStatusBar.Items.Add($global:msrdStatusBarLabel) | Out-Null
    $global:msrdGUIformLite.Controls.Add($global:msrdStatusBar)

    $global:msrdProgbar = New-Object System.Windows.Forms.ProgressBar
    $global:msrdProgbar.Location  = New-Object System.Drawing.Point(10,415)
    $global:msrdProgbar.Size = New-Object System.Drawing.Size(595,15)
    $global:msrdProgbar.Anchor = 'Left,Bottom'
    $global:msrdProgbar.DataBindings.DefaultDataSourceUpdateMode = 0
    $global:msrdProgbar.Step = 1
    $global:msrdGUIformLite.Controls.Add($global:msrdProgbar)

    $feedbackLinkLite = New-Object System.Windows.Forms.LinkLabel
    $feedbackLinkLite.Location = [System.Drawing.Point]::new(195, 385)
    $feedbackLinkLite.Size = [System.Drawing.Point]::new(180, 20)
    $feedbackLinkLite.LinkColor = [System.Drawing.Color]::Blue
    $feedbackLinkLite.ActiveLinkColor = [System.Drawing.Color]::Red
    $feedbackLinkLite.Text = msrdGetLocalizedText "feedbackLink"
    $feedbackLinkLite.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $feedbackLinkLite.Add_Click({ [System.Diagnostics.Process]::Start('https://aka.ms/MSRD-Collect-Feedback') })
    $feedbackLinkLiteToolTip = New-Object System.Windows.Forms.ToolTip
    $feedbackLinkLiteToolTip.SetToolTip($feedbackLinkLite, "$(msrdGetLocalizedText 'feedbackLink')")
    $global:msrdGUIformLite.Controls.Add($feedbackLinkLite)

    #endregion BottomOptions

    if ($ShowConsole -eq 1) {
        msrdStartShowConsole
        $checkBoxShowConsole.Checked = $true
    } else {
        msrdStartHideConsole
        $checkBoxShowConsole.Checked = $false
    }

    $global:msrdGUIformLite.Add_Shown({
        $btnSource.Enabled = $false
        $btnTarget.Enabled = $false
        $btnProfiles.Enabled = $false
        $btnActivation.Enabled = $false
        $btnMSRA.Enabled = $false
        $btnSCard.Enabled = $false
        $btnIME.Enabled = $false
        $btnTeams.Enabled = $false
        $btnMSIXAA.Enabled = $false
        $btnHCI.Enabled = $false
        $btnStart.Enabled = $false
    })

    $global:msrdGUIformLite.Add_Closing({
        If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
        If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
    })

    $global:msrdGUIformLite.ShowDialog() | Out-Null
    msrdStartShowConsole -nocfg $true
}


Export-ModuleMember -Function msrdAVDCollectGUILite
# SIG # Begin signature block
# MIInzgYJKoZIhvcNAQcCoIInvzCCJ7sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA2z92a37/Uymsc
# RPyZbuTApDbncLtaiYyBP9FjZVaNvKCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHgr
# oDzpjRFXB6OIwxGPYRaOCOWhbjbrS6vxma5z9XKBMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAVoVas9iW66TxhmiaCgOwBQR/fFeV2CEIOuLi
# 9lOO9izE1Xgyx8oKY+DIcxHTs6Wt0VAYY/KpIIALGdJAUKZeIJoUk1WBS9SYsKjW
# ygtGO0xwyZhUd58v/zLkR04BjRvuCU4BFVo984ZvQyzdTnW6yNfsfCI7friyblEh
# rQNKvxoOj0m57KwKSG2uCeiqZ/kgSge3pZfVz2r6fZoUurUD+dzn1lmkYH3+JQsv
# AywRFRCi3/R2r5CkP1khF2RAV0g1U0LBDEqayko/AuTDJPQ/VTjmeM4BpKRsWWuv
# JyvzFqCe5hmjHTL6SUqfNHU/wRoOOdB3tBUOoMVZFPAmMtLjW6GCFykwghclBgor
# BgEEAYI3AwMBMYIXFTCCFxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFZBgsqhkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCCFJ5+a7zfYz8B1oa6I1MZcu0ocG2c7xJaz
# tmz2Njmg1gIGZlUmjP3AGBMyMDI0MDYxMjE1MDA0MC41MTVaMASAAgH0oIHYpIHV
# MIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOjA4NDItNEJFNi1DMjlBMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHajtXJ
# WgDREbEAAQAAAdowDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwHhcNMjMxMDEyMTkwNjU5WhcNMjUwMTEwMTkwNjU5WjCB0jELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9z
# b2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjowODQyLTRCRTYtQzI5QTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJOQ
# Bgh2tVFR1j8jQA4NDf8bcVrXSN080CNKPSQo7S57sCnPU0FKF47w2L6qHtwm4EnC
# lF2cruXFp/l7PpMQg25E7X8xDmvxr8BBE6iASAPCfrTebuvAsZWcJYhy7prgCuBf
# 7OidXpgsW1y8p6Vs7sD2aup/0uveYxeXlKtsPjMCplHkk0ba+HgLho0J68Kdji3D
# M2K59wHy9xrtsYK+X9erbDGZ2mmX3765aS5Q7/ugDxMVgzyj80yJn6ULnknD9i4k
# UQxVhqV1dc/DF6UBeuzfukkMed7trzUEZMRyla7qhvwUeQlgzCQhpZjz+zsQgpXl
# PczvGd0iqr7lACwfVGog5plIzdExvt1TA8Jmef819aTKwH1IVEIwYLA6uvS8kRdA
# 6RxvMcb//ulNjIuGceyykMAXEynVrLG9VvK4rfrCsGL3j30Lmidug+owrcCjQagY
# mrGk1hBykXilo9YB8Qyy5Q1KhGuH65V3zFy8a0kwbKBRs8VR4HtoPYw9z1DdcJfZ
# BO2dhzX3yAMipCGm6SmvmvavRsXhy805jiApDyN+s0/b7os2z8iRWGJk6M9uuT24
# 93gFV/9JLGg5YJJCJXI+yxkO/OXnZJsuGt0+zWLdHS4XIXBG17oPu5KsFfRTHREl
# oR2dI6GwaaxIyDySHYOtvIydla7u4lfnfCjY/qKTAgMBAAGjggFJMIIBRTAdBgNV
# HQ4EFgQUoXyNyVE9ZhOVizEUVwhNgL8PX0UwHwYDVR0jBBgwFoAUn6cVXQBeYl2D
# 9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
# LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQAD
# ggIBALmDVdTtuI0jAEt41O2OM8CU237TGMyhrGr7FzKCEFaXxtoqk/IObQriq1ca
# HVh2vyuQ24nz3TdOBv7rcs/qnPjOxnXFLyZPeaWLsNuARVmUViyVYXjXYB5DwzaW
# ZgScY8GKL7yGjyWrh78WJUgh7rE1+5VD5h0/6rs9dBRqAzI9fhZz7spsjt8vnx50
# WExbBSSH7rfabHendpeqbTmW/RfcaT+GFIsT+g2ej7wRKIq/QhnsoF8mpFNPHV1q
# /WK/rF/ChovkhJMDvlqtETWi97GolOSKamZC9bYgcPKfz28ed25WJy10VtQ9P5+C
# /2dOfDaz1RmeOb27Kbegha0SfPcriTfORVvqPDSa3n9N7dhTY7+49I8evoad9hdZ
# 8CfIOPftwt3xTX2RhMZJCVoFlabHcvfb84raFM6cz5EYk+x1aVEiXtgK6R0xn1wj
# MXHf0AWlSjqRkzvSnRKzFsZwEl74VahlKVhI+Ci9RT9+6Gc0xWzJ7zQIUFE3Jiix
# 5+7KL8ArHfBY9UFLz4snboJ7Qip3IADbkU4ZL0iQ8j8Ixra7aSYfToUefmct3dM6
# 9ff4Eeh2Kh9NsKiiph589Ap/xS1jESlrfjL/g/ZboaS5d9a2fA598mubDvLD5x5P
# P37700vm/Y+PIhmp2fTvuS2sndeZBmyTqcUNHRNmCk+njV3nMIIHcTCCBVmgAwIB
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
# aGFsZXMgVFNTIEVTTjowODQyLTRCRTYtQzI5QTElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAQqIfIYljHUbNoY0/
# wjhXRn/sSA2ggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOoUEtswIhgPMjAyNDA2MTIyMDI4MTFaGA8yMDI0MDYx
# MzIwMjgxMVowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6hQS2wIBADAHAgEAAgIF
# 1DAHAgEAAgISijAKAgUA6hVkWwIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
# AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GB
# AJ0z9uE0NDS0k2uBbxoaKWPhQaeAEqKNUzFisEFCoSf+F726aRTDz1Nz4h9qKyvW
# SR295/nX7xRXU+w5RYIOPuOzauItthdHlTntO+rLgR992WuO3/I8SzHGnY8J5Igs
# YvcEUox7mi3zuTTlnT4S644yTSJoq3ZGNl0pZsrbXCQ9MYIEDTCCBAkCAQEwgZMw
# fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHajtXJWgDREbEAAQAA
# AdowDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAvBgkqhkiG9w0BCQQxIgQgK+v+v4avPj7sRXmTqu9Aduzfrmcuu1Eq8MvULnTj
# JJMwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAipaNpYsDvnqTe95Dj1C09
# 020I5ljibrW/ndICOxg9xjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAAB2o7VyVoA0RGxAAEAAAHaMCIEICrzuvWZNlHyXVa2qUUf7AZf
# PvZri8IdhDezfur4sbhNMA0GCSqGSIb3DQEBCwUABIICAFHSjbrHLHcwtuYrzYR/
# t58tVWct5MA3Ge9yzCF9njA9JqjHEtEHnuKv5tebfgM6brKyztBLtX4vQ2MO648u
# z7eMEQ8bz+iSkY8PcrW1Xo3HW12p3pgZIZfMZzr7CWxXz4KPJA+kXnd5ygLnfafh
# u3MsVzjCboKwFXE91C80BBc9cFidOJ7Q8S0gWnvqt7Z7hae46SEBbOFA3PEepYr+
# ce/SRQf0ncyJjLlvnCd6WTFMn94vkkSUotyMYsAus66Jgezdh4/3qCINx09vviXk
# pm6Kt0Gk+sVYRfWekDMI+7lD8s1ETu1R83VSzTBVvu+uyUSHHS2lvPGbK8CdPFc4
# txUJvm9T0qMSzV97Gowal04+XspCLQRdqno61XyG5MOB1grK60Oq606kgoNfAdAb
# vUHmt7tk6ybSuHzBqh+mnjnff1Hjuqd1hFV1HI1/Ta9VCCTE3U30bL82R8oDsnjU
# es3wZN1EiDjF4JrlLhBHwz1E1retGjfZfq2XeNZz7Ce0KVaHswHRLIA6xf0+AtsV
# h3s218LT4uSXDXLL39NuhvgdRG97zuEDuyLU6SZqq5+U/yFSyf+J7AYsaRLE4MsP
# Sl4Mgn58Ufnu59eB6sIWNAXn/d2z1x5cKiR6bA5Bn49gi6gOLkBzu4dbWRZxnjUa
# nl9y8P2gYFi3YqmS35Sk21LZ
# SIG # End signature block
