<#
.SYNOPSIS
   MSRD-Collect graphical user interface (Lite version)

.DESCRIPTION
   Module for the MSRD-Collect graphical user interface (Lite version)

.NOTES
   Author     : Robert Klemencz
   Requires   : At least PowerShell 5.1 (This module is not for stand-alone use. It is used automatically from within the main MSRD-Collect.ps1 script)
   Version    : See MSRD-Collect.ps1 version
   Feedback   : Send an e-mail to MSRDCollectTalk@microsoft.com
#>

#region config variables
$varsCore = @(,$true * 10)
$vCore = $varsCore

$varsProfiles = @(,$true * 4)
$varsActivation = @(,$true * 3)
$varsMSRA = @(,$true * 5)
$varsSCard = @(,$true * 3)
$varsIME = @(,$true * 2)
$varsTeams = @(,$true * 2)
$varsMSIXAA = @(,$true * 1)
$varsHCI = @(,$true * 1)

$varsNO = $false

$varsSystem = @(,$true * 11)
$varsAVDRDS = @(,$true * 10)
$varsInfra = @(,$true * 7)
$varsAD = @(,$true * 2)
$varsNET = @(,$true * 7)
$varsLogSec = @(,$true * 2)
$varsIssues = @(,$true * 2)
$varsOther = @(,$true * 4)

$dumpProc = $False; $pidProc = ""
$traceNet = $False; $global:onlyDiag = $false
#endregion config variables


#region code
#Load dlls into context of the current console session
 Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
#endregion code

#region languages

# Create a dropdown menu
$dropdown = New-Object System.Windows.Forms.ComboBox
$dropdown.Location = New-Object System.Drawing.Point(20, 150)
$dropdown.Width = 50

# Add items to the dropdown
$items = "DE", "EN", "FR", "HU", "IT", "PT", "RO"
foreach ($item in $items) {
    $dropdown.Items.Add($item)
}

# Add the dropdown to the form
#$global:msrdGUIformLite.Controls.Add($dropdown)

#endregion languages

#region GUI functions
Add-Type -AssemblyName System.Windows.Forms

function msrdStartShowConsole {
    param ($nocfg)

    try {
        $PSConsole = [Console.Window]::GetConsoleWindow()
        [Console.Window]::ShowWindow($PSConsole, 5) | Out-Null
        Write-Output "$(msrdGetLocalizedText "conVisible")`n"
        if (!($nocfg)) {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "ShowConsoleWindow" -value 1
        }
    } catch {
        Write-Warning "Error showing console window: $($_.Exception.Message)"
    }
}

function msrdStartHideConsole {
    try {
        $PSConsole = [Console.Window]::GetConsoleWindow()
        [Console.Window]::ShowWindow($PSConsole, 0) | Out-Null
        Write-Output "$(msrdGetLocalizedText "conHidden")`n"
        msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "ShowConsoleWindow" -value 0
    } catch {
        Write-Warning "Error hiding console window: $($_.Exception.Message)"
    }
}

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

    if (-not $GetTeamsLogs) {
        $btnStart.Text = msrdGetLocalizedText "Running"
        if (-not $global:onlyDiag) {
            $global:msrdStatusBar.Text = "Starting data collection/diagnostics"
        } else {
			$global:msrdStatusBar.Text = "Starting diagnostics"
		}
        msrdInitFolders

        msrdLogMessage $LogLevel.InfoLogFileOnly "Script version $global:msrdVersion launched from: $global:msrdScriptpath"
        msrdLogMessage $LogLevel.InfoLogFileOnly "Command line: $global:msrdCmdLine"
        msrdLogMessage $LogLevel.InfoLogFileOnly "EULA and Notice accepted"
        msrdLogMessage $LogLevel.InfoLogFileOnly "Output location: $global:msrdLogRoot"
        msrdLogMessage $LogLevel.InfoLogFileOnly "User context: $global:msrdUserprof"
        msrdLogMessage $LogLevel.InfoLogFileOnly "PID selected for process dump: $script:pidProc"

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

        msrdArchiveData -varsCore $script:vCore
        $btnStart.Text = msrdGetLocalizedText "Start"
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
    $global:msrdGUIformLite.Icon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\MSRD-Collect.dll", 12, $true))
    if ($global:msrdDevLevel -eq "Insider") {
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
    $btnRDS.Text = "Remote Desktop Services`n(incl. direct RDP)"
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
    $btnProfilesToolTip.SetToolTip($btnProfiles, "Collect data for troubleshooting 'User Profiles' issues")
    $global:msrdGUIformLite.Controls.Add($btnProfiles)

    $global:btnProfilesClick = $true
    $btnProfiles.Add_Click({
        if ($global:btnProfilesClick) {
            $script:vProfiles = $varsProfiles; $btnProfiles.BackColor = $global:btnColor;
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
    $btnActivationToolTip.SetToolTip($btnActivation, "Collect data for troubleshooting 'OS Licensing/Activation' issues")
    $global:msrdGUIformLite.Controls.Add($btnActivation)

    $global:btnActivationClick = $true
    $btnActivation.Add_Click({
        if ($global:btnActivationClick) {
            $script:vActivation = $varsActivation; $btnActivation.BackColor = $global:btnColor;
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
    $btnMSRAToolTip.SetToolTip($btnMSRA, "Collect data for troubleshooting 'Remote Assistance' issues")
    $global:msrdGUIformLite.Controls.Add($btnMSRA)

    $global:btnMSRAClick = $true
    $btnMSRA.Add_Click({
        if ($global:btnMSRAClick) {
            $script:vMSRA = $varsMSRA; $btnMSRA.BackColor = $global:btnColor;
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
    $btnSCardToolTip.SetToolTip($btnSCard, "Collect data for troubleshooting 'Smart Card' issues")
    $global:msrdGUIformLite.Controls.Add($btnSCard)

    $global:btnSCardClick = $true
    $btnSCard.Add_Click({
        if ($global:btnSCardClick) {
            $script:vSCard = $varsSCard; $btnSCard.BackColor = $global:btnColor;
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
    $btnIMEToolTip.SetToolTip($btnIME, "Collect data for troubleshooting 'Input Method' issues")
    $global:msrdGUIformLite.Controls.Add($btnIME)

    $global:btnIMEClick = $true
    $btnIME.Add_Click({
        if ($global:btnIMEClick) {
            $script:vIME = $varsIME; $btnIME.BackColor = $global:btnColor;
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
    $btnTeamsToolTip.SetToolTip($btnTeams, "Collect data for troubleshooting 'Teams on AVD/W365' issues")
    $global:msrdGUIformLite.Controls.Add($btnTeams)

    $global:btnTeamsClick = $true
    $btnTeams.Add_Click({
        if ($global:btnTeamsClick) {
            $script:vTeams = $varsTeams; $btnTeams.BackColor = $global:btnColor;
        } else {
            $script:vTeams = $varsNO; $btnTeams.ResetBackColor();
        }
        $global:btnTeamsClick = (-not $global:btnTeamsClick)
    })

    $btnMSIXAA = New-Object System.Windows.Forms.Button
    $btnMSIXAA.Size = New-Object System.Drawing.Size(100, 40)
    $btnMSIXAA.Location = New-Object System.Drawing.Point(255, 250)
    $btnMSIXAA.Text = "MSIX App Attach"
    $btnMSIXAAToolTip = New-Object System.Windows.Forms.ToolTip
    $btnMSIXAAToolTip.SetToolTip($btnMSIXAA, "Collect data for troubleshooting 'MSIX App Attach' issues")
    $global:msrdGUIformLite.Controls.Add($btnMSIXAA)

    $global:btnMSIXAAClick = $true
    $btnMSIXAA.Add_Click({
        if ($global:btnMSIXAAClick) {
            $script:vMSIXAA = $varsMSIXAA; $btnMSIXAA.BackColor = $global:btnColor;
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
    $btnHCIToolTip.SetToolTip($btnHCI, "Collect data for troubleshooting 'AVD on Azure Stack HCI' issues")
    $global:msrdGUIformLite.Controls.Add($btnHCI)

    $global:btnHCIClick = $true
    $btnHCI.Add_Click({
        if ($global:btnHCIClick) {
            $script:vHCI = $varsHCI; $btnHCI.BackColor = $global:btnColor;
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
    $btnDiagOnlyToolTip.SetToolTip($btnDiagOnly, "Generate a Diagnostics report only")
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
    $btnStartToolTip.SetToolTip($btnStart, "Start Data Collection/Diagnostics")
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
        } else {
            msrdStartHideConsole
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
                msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "UILiteMode" -value 0
                If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
                If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
                if (($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) { $global:msrdGUIformLite.Close() } else { Exit }
            } catch {
                $failedCommand = $_.InvocationInfo.Line.TrimStart()
                $errorMessage = $_.Exception.Message.TrimStart()
                msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_ -fErrorLogFileOnly
                if ($global:msrdGUI) {
                    msrdAdd-OutputBoxLine -Message "Error in $failedCommand $errorMessage" -Color Magenta
                } else {
                    msrdLogMessage $LogLevel.Warning ("Error in $failedCommand $errorMessage")
                }
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
    $global:msrdStatusBarLabel.Text = "Ready"
    $global:msrdStatusBar.Items.Add($global:msrdStatusBarLabel) | Out-Null
    $global:msrdGUIformLite.Controls.Add($global:msrdStatusBar)

    $global:msrdProgbar = New-Object System.Windows.Forms.ProgressBar
    $global:msrdProgbar.Location  = New-Object System.Drawing.Point(10,415)
    $global:msrdProgbar.Size = New-Object System.Drawing.Size(595,15)
    $global:msrdProgbar.Anchor = 'Left,Bottom'
    $global:msrdProgbar.DataBindings.DefaultDataSourceUpdateMode = 0
    $global:msrdProgbar.Step = 1
    $global:msrdGUIformLite.Controls.Add($global:msrdProgbar)

    $surveyLinkLite = New-Object System.Windows.Forms.LinkLabel
    $surveyLinkLite.Location = [System.Drawing.Point]::new(195, 385)
    $surveyLinkLite.Size = [System.Drawing.Point]::new(180, 20)
    $surveyLinkLite.LinkColor = [System.Drawing.Color]::Blue
    $surveyLinkLite.ActiveLinkColor = [System.Drawing.Color]::Red
    $surveyLinkLite.Text = msrdGetLocalizedText "surveyLink"
    $surveyLinkLite.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $surveyLinkLite.Add_Click({ [System.Diagnostics.Process]::Start('https://aka.ms/MSRD-Collect-Survey') })
    $surveyLinkLiteToolTip = New-Object System.Windows.Forms.ToolTip
    $surveyLinkLiteToolTip.SetToolTip($surveyLinkLite, "How do you like this script?")
    $global:msrdGUIformLite.Controls.Add($surveyLinkLite)

    #endregion BottomOptions

    if ($global:msrdShowConsole -eq 1) {
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
        $global:msrdCollectcount = 0
        If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
        If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
    })

    $global:msrdGUIformLite.ShowDialog() | Out-Null
    msrdStartShowConsole -nocfg $true
}


Export-ModuleMember -Function msrdAVDCollectGUILite
# SIG # Begin signature block
# MIIoKgYJKoZIhvcNAQcCoIIoGzCCKBcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAc/X8SVtl/YiQU
# iMfDO6AcvVWhANmOQKPvrsX2FTeo86CCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgowghoGAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIclZgnrr5raIncyfleDLdz+
# 3YxivIVu1tYRIPIklTCTMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAmoha8+8dkKXtKAIHtV4ScBDAGQE333ORA4ttk/t6jTFD6ane3kpzxmtj
# MLWO6gtQQvSAWVyh6oVBryuY4jBawAdGcDn24UvryjDUf9HuFFeQmXhTvpLRnT3e
# vhou5JncWm4rH40TEKRz5lHMvO0jS/xDV76eplKUyZARjbdG0gEIeNTeCpjDdEGa
# 4BjqXnYtM52Qg/TCmEm0nnsU7YQmKZzBtG24Xm3Hk7zmZf+hVxTqGtM0pEDnG881
# 3/IFnW5at+5bWuTi5yo1rf2EmJHJgZILsXSMs6LwchasDP3E4rnR7cvVHiL5agOn
# VbS9h+7E1gg0jnmoHZRehQBe210ew6GCF5QwgheQBgorBgEEAYI3AwMBMYIXgDCC
# F3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCDpsvNLhHs3fpbAcqkrJBEoNX/mcJDwBgBnJpu2qy8I9wIGZkXzAp18
# GBMyMDI0MDYxMjE1MDA0Mi4yODNaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTkzNS0w
# M0UwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHqMIIHIDCCBQigAwIBAgITMwAAAekPcTB+XfESNgABAAAB6TANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# MjZaFw0yNTAzMDUxODQ1MjZaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTkzNS0wM0UwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCsmowxQRVgp4TSc3nTa6yrAPJnV6A7aZYnTw/yx90u
# 1DSH89nvfQNzb+5fmBK8ppH76TmJzjHUcImd845A/pvZY5O8PCBu7Gq+x5Xe6plQ
# t4xwVUUcQITxklOZ1Rm9fJ5nh8gnxOxaezFMM41sDI7LMpKwIKQMwXDctYKvCyQy
# 6kO2sVLB62kF892ZwcYpiIVx3LT1LPdMt1IeS35KY5MxylRdTS7E1Jocl30NgcBi
# JfqnMce05eEipIsTO4DIn//TtP1Rx57VXfvCO8NSCh9dxsyvng0lUVY+urq/G8QR
# FoOl/7oOI0Rf8Qg+3hyYayHsI9wtvDHGnT30Nr41xzTpw2I6ZWaIhPwMu5DvdkEG
# zV7vYT3tb9tTviY3psul1T5D938/AfNLqanVCJtP4yz0VJBSGV+h66ZcaUJOxpbS
# IjImaOLF18NOjmf1nwDatsBouXWXFK7E5S0VLRyoTqDCxHG4mW3mpNQopM/U1WJn
# jssWQluK8eb+MDKlk9E/hOBYKs2KfeQ4HG7dOcK+wMOamGfwvkIe7dkylzm8BeAU
# QC8LxrAQykhSHy+FaQ93DAlfQYowYDtzGXqE6wOATeKFI30u9YlxDTzAuLDK073c
# ndMV4qaD3euXA6xUNCozg7rihiHUaM43Amb9EGuRl022+yPwclmykssk30a4Rp3v
# 9QIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFJF+M4nFCHYjuIj0Wuv+jcjtB+xOMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBWsSp+rmsxFLe61AE90Ken2XPgQHJDiS4S
# bLhvzfVjDPDmOdRE75uQohYhFMdGwHKbVmLK0lHV1Apz/HciZooyeoAvkHQaHmLh
# wBGkoyAAVxcaaUnHNIUS9LveL00PwmcSDLgN0V/Fyk20QpHDEukwKR8kfaBEX83A
# yvQzlf/boDNoWKEgpdAsL8SzCzXFLnDozzCJGq0RzwQgeEBr8E4K2wQ2WXI/ZJxZ
# S/+d3FdwG4ErBFzzUiSbV2m3xsMP3cqCRFDtJ1C3/JnjXMChnm9bLDD1waJ7TPp5
# wYdv0Ol9+aN0t1BmOzCj8DmqKuUwzgCK9Tjtw5KUjaO6QjegHzndX/tZrY792dfR
# AXr5dGrKkpssIHq6rrWO4PlL3OS+4ciL/l8pm+oNJXWGXYJL5H6LNnKyXJVEw/1F
# bO4+Gz+U4fFFxs2S8UwvrBbYccVQ9O+Flj7xTAeITJsHptAvREqCc+/YxzhIKkA8
# 8Q8QhJKUDtazatJH7ZOdi0LCKwgqQO4H81KZGDSLktFvNRhh8ZBAenn1pW+5UBGY
# z2GpgcxVXKT1CuUYdlHR9D6NrVhGqdhGTg7Og/d/8oMlPG3YjuqFxidiIsoAw2+M
# hI1zXrIi56t6JkJ75J69F+lkh9myJJpNkx41sSB1XK2jJWgq7VlBuP1BuXjZ3qgy
# m9r1wv0MtTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggNN
# MIICNQIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEn
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE5MzUtMDNFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQCr
# aYf1xDk2rMnU/VJo2GGK1nxo8aCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hQIBjAiGA8yMDI0MDYxMjExNDE1
# OFoYDzIwMjQwNjEzMTE0MTU4WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDqFAgG
# AgEAMAcCAQACAhPVMAcCAQACAhMCMAoCBQDqFVmGAgEAMDYGCisGAQQBhFkKBAIx
# KDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
# hvcNAQELBQADggEBAIdJ3H8lxwthusjqAkkjXGz/MgtYqWj50nO7TYU29nq+IoVW
# Z1XZ4eLrvGIFVHfaJ9JoYj+zY2/BgHj8ZIEoVG+DsVTeNhQuTNi2pCahOLUe9M2T
# mRebyqwxJ+jxw38tLlFDjkE371sC2QtHI+6AEl1psJqzSoyWArGvzXPZN6M1dGxx
# vvT+bMpzHchI6s3R+ulZWI0XE7orSNDborSowu/R8YmQARq71i8axMKWOm+/06L7
# hr8ijTSWwRogLh8X45hhzB0jOgHufMFVxqA/C0nLYX9BegMdEmF2WIvQUI/kgHUZ
# AykG7SdUKmFcAQAWWerNtX+uQF1UOinsBvVgxDYxggQNMIIECQIBATCBkzB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAekPcTB+XfESNgABAAAB6TAN
# BglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8G
# CSqGSIb3DQEJBDEiBCBMejcy8giFLYA2t8YSZfwkXeesUfnmnHiLUTqlMhl0VTCB
# +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIKSQkniXaTcmj1TKQWF+x2U4riVo
# rGD8TwmgVbN9qsQlMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAHpD3Ewfl3xEjYAAQAAAekwIgQgpjosHXnvuKWhM9RXFq/hJ935itrv
# qJZdLBOLHNhuqWUwDQYJKoZIhvcNAQELBQAEggIAVFJTLkxI4PPH09IU/5RpvFGH
# wBQ/GHNX1yU93fDiHFHE+IxCRKgPE9GMb3Sms3QU71RhwaJZ0vjY9Q2ZWUteUYhC
# 3Z1rJb6KVGuAL6K/ziDUgjODHRoq/xNvu4r/7McLW8STO7aA79PDBA+m98Ma1krV
# y3/FLcVo8h5X/xikyrquyFSoMRUbA5JPdclyiZZDAKJmvvzoMu3sFLYjWokI6qgl
# 06a3uuWynxIU1TEPWFF3lJzACxIhwKteJxVfHcJq4mcmCfggsmRi2zanRNgxVScf
# oZDXd66N07jc+pWAG/7i/Zq3C3yfOEMxq6diahNJQ6rXjXfvZTRVmC+vdf5W8rnf
# CAzNktLxxwss/TXP8tLFKJCa7JZ6Pccwt96PuPW0fSw1az/8a+5qoz5iABqUegL9
# ymdGcLw1kX9RloGaAUB8tSjnYCxsHEZo0sLzKaYlgJSxlMIBgLmIXlZI72Ri/Uxu
# tONDdbUE4QX2m8gQmEDy3EPVoBY2/VWompswq4J2RRSrJOmnN27AfqiLQbGFiNCx
# zKjlb2j9tELBXvCmCqLprxSn64Gwt6+jjyx/GfbJqVhO4zfYrTY6Svou3amU4eVW
# qZKD3hs4KLbNpvXJCXBdOaIcvpXx12bUCu/7MHHDGlWMHKKTFLNIzjrHuzLufN30
# yg0uDm24+PjZpz5gSNI=
# SIG # End signature block
