<#
.SYNOPSIS
   MSRD-Collect graphical user interface

.DESCRIPTION
   Module for the MSRD-Collect graphical user interface

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
$varsAVDRDS = @(,$true * 11)
$varsInfra = @(,$true * 7)
$varsAD = @(,$true * 2)
$varsNET = @(,$true * 7)
$varsLogSec = @(,$true * 2)
$varsIssues = @(,$true * 2)
$varsOther = @(,$true * 4)

$dumpProc = $False; $pidProc = ""
$traceNet = $False; $global:onlyDiag = $false
$global:msrdLiveDiag = $false

$msrdUserProfilesDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name ProfilesDirectory).ProfilesDirectory

#region GUI
Add-Type -AssemblyName System.Windows.Forms

#Load dlls into context of the current console session (for show/hide console)
 Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

#prepare icons
$iconCount = 43
$icons = @()

for ($i = 0; $i -lt $iconCount; $i++) {
    $icons += [System.IconExtractor]::Extract("$global:msrdScriptpath\MSRD-Collect.dll", $i, $true)
}

$abouticon = $icons[0]
$alwaysontopicon = $icons[1]
$azureicon = $icons[2]
$configicon = $icons[3]
$consoleicon = $icons[4]
$diagreporticon = $icons[5]
$docsicon = $icons[6]
$downloadicon = $icons[7]
$exiticon = $icons[8]
$feedbackicon = $icons[9]
$foldericon = $icons[10]
$litemodeicon = $icons[12]
$machineavdicon = $icons[13]
$machinerdsicon = $icons[14]
$machinew365icon = $icons[15]
$maximizedicon = $icons[16]
$msrdcicon = $icons[17]
$readmeicon = $icons[18]
$rolesourceicon = $icons[19]
$roletargeticon = $icons[20]
$scenarioactivationicon = $icons[21]
$scenariocoreicon = $icons[22]
$scenariohciicon = $icons[23]
$scenarioimeicon = $icons[24]
$scenariolivediagicon = $icons[25]
$scenariomsixaaicon = $icons[26]
$scenariomsraicon = $icons[27]
$scenarionettraceicon = $icons[28]
$scenarioprocdumpicon = $icons[29]
$scenarioprofilesicon = $icons[30]
$scenariodiagonlyicon = $icons[31]
$scenarioscardicon = $icons[32]
$scenarioteamsicon = $icons[33]
$scheduledtaskicon = $icons[34]
$searchicon = $icons[35]
$soundassisticon = $icons[36]
$soundsystemicon = $icons[37]
$starticon = $icons[38]
$uilanguageicon = $icons[39]
$updateicon = $icons[40]
$usercontexticon = $icons[41]
$whatsnewicon = $icons[42]

#create menu items
function msrdCreateMenu([string]$Text) {

    $Menu = New-Object System.Windows.Forms.ToolStripMenuItem
    $Menu.Text = $Text
    $Menu.Add_MouseEnter({ $this.Owner.Cursor = [System.Windows.Forms.Cursors]::Hand })
    $Menu.Add_MouseLeave({ $this.Owner.Cursor = [System.Windows.Forms.Cursors]::Default })

    return $Menu
}

#create menu buttons (panel, button area, buttons)
$buttonRibbon = New-Object Windows.Forms.Panel
$buttonRibbon.Location = New-Object Drawing.Point(0, 25)
$buttonRibbon.Size = New-Object System.Drawing.Size(1366, 82)
$buttonRibbon.BackColor = "#C0C0C0"
if ($global:msrdLangID -eq "AR") {
    $buttonRibbon.RightToLeft = "Yes"
    $buttonRibbon.Anchor = [Windows.Forms.AnchorStyles]::Top, [Windows.Forms.AnchorStyles]::Right, [Windows.Forms.AnchorStyles]::Left
} else {
    $buttonRibbon.RightToLeft = "No"
    $buttonRibbon.Anchor = [Windows.Forms.AnchorStyles]::Top, [Windows.Forms.AnchorStyles]::Left, [Windows.Forms.AnchorStyles]::Right
}

function msrdCreateButtons {
    param (
        [string]$name,
        $elements,
        $xPosStart,
        [switch]$addSeparator,
        [switch]$maxWidth,
        $xOffsetAR
    )
    
    # Define the dictionary for storing buttons
    $ButtonDictionary = @{}

    $xPos = 0
    $buttonHeight = 60
    $buttonVerticalOffset = 22  # Vertical offset for buttons

    $buttonArea = New-Object Windows.Forms.Panel

    if ($global:msrdLangID -eq "AR") {
        $arlocx = $global:msrdForm.ClientSize.Width - $xPosStart - $xOffsetAR
        $buttonArea.Location = New-Object Drawing.Point($arlocx, 0)
        $buttonArea.Anchor = 'Top,Right'
    } else {
        $buttonArea.Location = New-Object Drawing.Point($xPosStart, 0)    
    }
    
    $buttonArea.BackColor = "Transparent"
    $buttonRibbon.Controls.Add($buttonArea)
    
    $elements.GetEnumerator() | ForEach-Object -Process {
        $elementName = $_.Key
        $elementIcon = $_.Value

        $button = New-Object Windows.Forms.Button
        $button.Width = 65
        $button.Height = $buttonHeight
        $button.FlatStyle = 'Flat'
        $button.Font = New-Object System.Drawing.Font($button.Font.FontFamily, 8)
        $button.FlatAppearance.BorderSize = 0
        $button.ImageAlign = [System.Drawing.ContentAlignment]::TopCenter  # Align image to the top center
        $button.TextAlign = [System.Drawing.ContentAlignment]::BottomCenter  # Align text to the bottom center
        $button.Location = New-Object Drawing.Point($xPos, 0)
        $xPos += $button.Width

        $button.Image = $elementIcon.ToBitmap() # Load the icon from the file
        $button.Text = $elementName
        $button.TextImageRelation = "ImageAboveText"  # Display the image above the text
        $button.BackColor = "Transparent"

        # Attach the MouseEnter event handler
        $button.add_MouseEnter({
            $this.Cursor = [System.Windows.Forms.Cursors]::Hand
        })

        # Attach the MouseLeave event handler
        $button.add_MouseLeave({
            $this.Cursor = [System.Windows.Forms.Cursors]::Default
        })

        # Add the button to the dictionary
        $ButtonDictionary[$elementName] = $button

        $buttonArea.Controls.Add($button)
    }
    
    $buttonArea.Width = $xPos + 2
    $buttonArea.Height = $buttonHeight + $buttonVerticalOffset  # Include offset in height

    # Calculate the label position to center it within the buttonArea below the buttons
    $label = New-Object Windows.Forms.Label
    $label.Text = $name
    $label.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
    $label.Width = $buttonArea.Width - 4
    $labelHeight = $label.PreferredHeight
    $labelLocationX = ($buttonArea.Width - $label.Width) / 2
    $labelLocationY = $buttonHeight # Adjust vertical position to be just below the buttons
    $label.Location = New-Object Drawing.Point($labelLocationX, $labelLocationY)
    $buttonArea.Controls.Add($label)  # Add the label to the buttonArea
    $label.BackColor = "Transparent"

    if ($AddSeparator) {
        # Add a separator (vertical line) after the last button
        $separator = New-Object Windows.Forms.Label
        $separator.BackColor = "Gray"
        $separator.Width = 1  # Width of the separator
        $separator.Height = $buttonHeight + $labelLocationY
        $separator.Location = New-Object Drawing.Point($xPos, 0)  # Position the separator after the last button
        $buttonArea.Controls.Add($separator)
    }

    # Return the dictionary of buttons
    return $ButtonDictionary, $label
}

#initialize machine settings
function msrdSetMachine {
    param (
		[string]$Machine
	)

    $msrdComputerBox.Enabled = $true

    #AVD
    if ($Machine -eq "AVD") {
        if (-not $global:msrdAVD) {
            $global:msrdAVD = $true; $global:msrdRDS = $False; $global:msrdW365 = $False
            $MachineDictionary["AVD"].BackColor = "LightBlue"
            $MachineDictionary["RDS"].BackColor = "Transparent"
            $MachineDictionary["W365"].BackColor = "Transparent"
            msrdInitButtons -ButtonDictionary $RoleDictionary -status $true
            $MachineDictionary["RDS"].Enabled = $False
            $MachineDictionary["W365"].Enabled = $False
        } else {
            $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False
            if ($script:pidProc) {
                msrdAdd-OutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
                $dumppidBox.SelectedValue = ""
                $script:pidProc = ""
            }

            $MachineDictionary["AVD"].BackColor = "Transparent"
            $MachineDictionary["RDS"].BackColor = "Transparent"
            $MachineDictionary["W365"].BackColor = "Transparent"
            msrdInitButtons -ButtonDictionary $MachineDictionary -status $true
            $global:msrdSource = $false; $global:msrdTarget = $false
            msrdInitButtons -ButtonDictionary $RoleDictionary -status $false
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            msrdResetScenarioVariables
            $ActionDictionary["Start"].Enabled = $false
            $global:liveDiagTab.Visible = $false
            $msrdPsBox.Visible = $true
            $global:msrdLiveDiag = $False
        }

    #RDS
    } elseif ($Machine -eq "RDS") {
        if (-not $global:msrdRDS) {
            $global:msrdAVD = $False; $global:msrdRDS = $true; $global:msrdW365 = $False
            $MachineDictionary["AVD"].BackColor = "Transparent"
            $MachineDictionary["RDS"].BackColor = "LightBlue"
            $MachineDictionary["W365"].BackColor = "Transparent"
            msrdInitButtons -ButtonDictionary $RoleDictionary -status $true
            $MachineDictionary["AVD"].Enabled = $False
            $MachineDictionary["W365"].Enabled = $False

            $msrdComputerBox.Enabled = $false
            $msrdComputerBox.Text = $env:computerName
        } else {
            $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False
            if ($script:pidProc) {
                msrdAdd-OutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
                $dumppidBox.SelectedValue = ""
                $script:pidProc = ""
            }

            $MachineDictionary["AVD"].BackColor = "Transparent"
            $MachineDictionary["RDS"].BackColor = "Transparent"
            $MachineDictionary["W365"].BackColor = "Transparent"
            msrdInitButtons -ButtonDictionary $MachineDictionary -status $true
            $global:msrdSource = $false; $global:msrdTarget = $false
            msrdInitButtons -ButtonDictionary $RoleDictionary -status $false
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            msrdResetScenarioVariables
            $ActionDictionary["Start"].Enabled = $false
            $global:liveDiagTab.Visible = $false
            $msrdPsBox.Visible = $true
            $global:msrdLiveDiag = $False

            $msrdComputerBox.Enabled = $true
            $msrdComputerBox.Text = $env:computerName
        }

    #W365
    } elseif ($Machine -eq "W365") {
        if (-not $global:msrdW365) {
            $global:msrdAVD = $False; $global:msrdRDS = $False; $global:msrdW365 = $true
            $MachineDictionary["AVD"].BackColor = "Transparent"
            $MachineDictionary["RDS"].BackColor = "Transparent"
            $MachineDictionary["W365"].BackColor = "LightBlue"
            msrdInitButtons -ButtonDictionary $RoleDictionary -status $true
            $MachineDictionary["AVD"].Enabled = $False
            $MachineDictionary["RDS"].Enabled = $False
        } else {
            $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False
            if ($script:pidProc) {
                msrdAdd-OutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
                $dumppidBox.SelectedValue = ""
                $script:pidProc = ""
            }

            $MachineDictionary["AVD"].BackColor = "Transparent"
            $MachineDictionary["RDS"].BackColor = "Transparent"
            $MachineDictionary["W365"].BackColor = "Transparent"
            msrdInitButtons -ButtonDictionary $MachineDictionary -status $true
            $global:msrdSource = $false; $global:msrdTarget = $false
            msrdInitButtons -ButtonDictionary $RoleDictionary -status $false
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            msrdResetScenarioVariables
            $ActionDictionary["Start"].Enabled = $false
            $global:liveDiagTab.Visible = $false
            $msrdPsBox.Visible = $true
            $global:msrdLiveDiag = $False
        }
    }
}

#initialize role settings
function msrdSetRole {
    param (
		[string]$Role
	)

    if (-not $global:msrdRDS) { $msrdComputerBox.Enabled = $true }

    #source
    if ($Role -eq "Source") {
        msrdResetScenarioVariables
        if (-not $global:msrdSource) {
            $global:msrdSource = $true; $global:msrdTarget = $False
            $RoleDictionary["Source"].BackColor = "LightBlue"
            $RoleDictionary["Target"].BackColor = "Transparent"
            $RoleDictionary["Target"].Enabled = $false
            $ScenarioDictionary["Core"].BackColor = "LightBlue"
            $ScenarioDictionary["SCard"].Enabled = $true
            $ScenarioDictionary["ProcDump"].Enabled = $true
            $ScenarioDictionary["NetTrace"].Enabled = $true
            $ScenarioDictionary["DiagOnly"].Enabled = $true
            $LiveDictionary["LiveDiag"].Enabled = $true
            $ActionDictionary["Start"].Enabled = $true
            $RunMenuItem.Enabled = $true
        } else {
            $global:msrdSource = $false; $global:msrdTarget = $false
            $RoleDictionary["Source"].BackColor = "Transparent"
            $RoleDictionary["Target"].BackColor = "Transparent"
            $RoleDictionary["Target"].Enabled = $true
            $ScenarioDictionary["Core"].BackColor = "Transparent"
            $ScenarioDictionary["SCard"].Enabled = $false
            $ScenarioDictionary["ProcDump"].Enabled = $false
            $ScenarioDictionary["NetTrace"].Enabled = $false
            $ScenarioDictionary["DiagOnly"].Enabled = $false
            $LiveDictionary["LiveDiag"].Enabled = $false
            $LiveDictionary["LiveDiag"].BackColor = "Transparent"
            $ActionDictionary["Start"].Enabled = $false
            $RunMenuItem.Enabled = $false
            $global:liveDiagTab.Visible = $false
            $msrdPsBox.Visible = $true
            $global:msrdLiveDiag = $False
        }
        $ScenarioDictionary["DiagOnly"].BackColor = "Transparent"

    #target
    } elseif ($Role -eq "Target") {
        msrdResetScenarioVariables
        if (-not $global:msrdTarget) {
            $global:msrdSource = $False; $global:msrdTarget = $true
            $RoleDictionary["Source"].BackColor = "Transparent"
            $RoleDictionary["Target"].BackColor = "LightBlue"
            $RoleDictionary["Source"].Enabled = $false
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $true
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $true
            $ScenarioDictionary["Core"].BackColor = "LightBlue"
            $ScenarioDictionary["Core"].Enabled = $false
            $ActionDictionary["Start"].Enabled = $true
            $RunMenuItem.Enabled = $true

            if ($global:msrdRDS) {
                $ScenarioDictionary["Teams"].Enabled = $false
                $ScenarioDictionary["MSIXAA"].Enabled = $false
                $ScenarioDictionary["HCI"].Enabled = $false
            } elseif ($global:msrdW365) {
                $ScenarioDictionary["MSIXAA"].Enabled = $false
                $ScenarioDictionary["HCI"].Enabled = $false
            }
        } else {
            $global:msrdSource = $false; $global:msrdTarget = $false
            $RoleDictionary["Source"].BackColor = "Transparent"
            $RoleDictionary["Target"].BackColor = "Transparent"
            $RoleDictionary["Source"].Enabled = $true
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            $ScenarioDictionary["Core"].BackColor = "Transparent"
            $ScenarioDictionary["Core"].Enabled = $false
            $ActionDictionary["Start"].Enabled = $false
            $RunMenuItem.Enabled = $false
            $global:liveDiagTab.Visible = $false
            $msrdPsBox.Visible = $true
            $global:msrdLiveDiag = $False
        }
    }
}


#initialize scenario settings
function msrdSetScenario {
    param ( [array]$Scenario, $Status )

    foreach ($scen in $scenario) {
        $variableName = "v$scen"
        if ($status) {
            $value = (Get-Variable -Name "vars$scen" -Scope Script).Value 
            $ScenarioDictionary["$scen"].BackColor = "LightBlue"
        } else {
            $value = $varsNO
            $ScenarioDictionary["$scen"].BackColor = "Transparent"
        }
        Set-Variable -Name $variableName -Value $value -Scope Script
    }
}

#initialize button status
function msrdInitButtons {
    param ($ButtonDictionary, $status)

    $ButtonDictionary.Values | ForEach-Object {
        $_.BackColor = "Transparent"
        $_.Enabled = $status
    }

    $global:msrdPsBox.Visible = $true
}

#reset all
function msrdResetAll {
    $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False
    if ($script:pidProc) {
        msrdAdd-OutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
        $dumppidBox.SelectedValue = ""
        $script:pidProc = ""
    }

    $MachineDictionary["AVD"].BackColor = "Transparent"
    $MachineDictionary["RDS"].BackColor = "Transparent"
    $MachineDictionary["W365"].BackColor = "Transparent"
    msrdInitButtons -ButtonDictionary $MachineDictionary -status $true
    $global:msrdSource = $false; $global:msrdTarget = $false
    msrdInitButtons -ButtonDictionary $RoleDictionary -status $false
    msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
    msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
    msrdResetScenarioVariables
    $ActionDictionary["Start"].Enabled = $false
    $global:liveDiagTab.Visible = $false
    $msrdPsBox.Visible = $true
    $global:msrdLiveDiag = $False
}

#reset scenario variables
function msrdResetScenarioVariables {
    $script:vCore = $script:varsCore
    $script:vProfiles = $varsNO
    $script:vActivation = $varsNO
    $script:vMSRA = $varsNO
    $script:vSCard = $varsNO
    $script:vIME = $varsNO
    $script:vTeams = $varsNO
    $script:vMSIXAA = $varsNO
    $script:vHCI = $varsNO
    $script:dumpProc = $False
    $script:traceNet = $False
}

#write to output box only
function SwitchLiveDiagToPsBox {

    if ($global:msrdLiveDiag) {
        $global:msrdLiveDiag = $False
        if ($global:msrdTarget) {
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $true
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $true
            $ScenarioDictionary["Core"].Enabled = $false
        } else {
            $ScenarioDictionary["DiagOnly"].Enabled = $true
        }
		$LiveDictionary["LiveDiag"].BackColor = "Transparent"
        $ScenarioDictionary["Core"].BackColor = "LightBlue"
        $ActionDictionary["Start"].Enabled = $true
        $msrdPsBox.Visible = $true
        $global:liveDiagTab.Visible = $false
        Remove-Module MSRDC-Diag
    }
}

Function msrdAdd-OutputBoxLine {
    param ([string[]]$Message, $Color, $switchColor, [switch]$noNewLine, $outputFile, $addAssist)

    if ($Color) { $txtColor = $Color } else { $txtColor = "White" }
    if ($switchColor) { $swColor = $switchColor } else { $swColor = "Yellow" }

    if ($global:msrdLiveDiag) {
        if ($global:msrdLiveDiagSystem) {
            $mainPsBox = $liveDiagPsBoxSystem
        } elseif ($global:msrdLiveDiagAVDRDS) {
            $mainPsBox = $liveDiagPsBoxAVDRDS
        } elseif ($global:msrdLiveDiagAVDInfra) {
            $mainPsBox = $liveDiagPsBoxAVDInfra
        } elseif ($global:msrdLiveDiagAD) {
            $mainPsBox = $liveDiagPsBoxAD
        } elseif ($global:msrdLiveDiagNet) {
            $mainPsBox = $liveDiagPsBoxNet
        } elseif ($global:msrdLiveDiagLogonSec) {
            $mainPsBox = $liveDiagPsBoxLogonSec
        } elseif ($global:msrdLiveDiagIssues) {
            $mainPsBox = $liveDiagPsBoxIssues
        } elseif ($global:msrdLiveDiagOther) {
            $mainPsBox = $liveDiagPsBoxOther
        }
    } else {
        $mainPsBox = $msrdPsBox
        if ($global:msrdLangID -eq "AR") { $mainPsBox.RightToLeft = "Yes" } else { $mainPsBox.RightToLeft = "No" }
    }

    foreach ($msg in $Message) {
        if ($noNewLine) { $line = "$msg" } else { $line = "$msg`r`n" }

        if ($switchColor) {
            $patterns = @("Step \d:", "Step \d+[a-zA-Z]:", #EN
                "Schritt \d:", "Schritt \d+[a-zA-Z]:", #DE
                "Étape \d:", "Étape \d+[a-zA-Z]:", #FR
                "Lépés \d:", "Lépés \d+[a-zA-Z]:", #HU
                "Stap \d:", "Stap \d+[a-zA-Z]:", #NL
                "Passo \d:", "Passo \d+[a-zA-Z]:", #IT
                "Pasul \d:", "Pasul \d+[a-zA-Z]:", #RO
                "ステップ \d:", "ステップ \d+[a-zA-Z]:", #JA
                "الخطوة \d:", "الخطوة \d+[\u0600-\u06FF]:", #AR
                "Adım \d:", "Adım \d+[a-zA-Z]:") #TR

            # Find matches of the pattern in the line
            $linematches = foreach ($pattern in $patterns) {
                [regex]::Matches($line, $pattern)
            }

            # Set the default color for the entire line
            $mainPsBox.SelectionStart = $mainPsBox.TextLength
            $mainPsBox.SelectionLength = 0
            $mainPsBox.SelectionColor = $txtColor
            $mainPsBox.AppendText($line)

            # Set the color for each matched pattern
            foreach ($linematch in $linematches) {
                $startIndex = $linematch.Index
                $length = $linematch.Length
                $mainPsBox.Select($mainPsBox.TextLength - $line.Length + $startIndex, $length)
                $mainPsBox.SelectionColor = $swColor
                $mainPsBox.SelectionLength = 0
            }
        } else {
            $mainPsBox.SelectionStart = $mainPsBox.TextLength
            $mainPsBox.SelectionLength = 0
            $mainPsBox.SelectionColor = $txtColor
            $mainPsBox.AppendText($line)
        }

        if ($addAssist) {
            msrdLogMessageAssistMode $line
        }

        $mainPsBox.SelectionStart = $mainPsBox.TextLength
        $mainPsBox.ScrollToCaret()
        $mainPsBox.Refresh()
    }
}

#display the initial how to steps
function msrdInitHowTo {

    # How To Steps
    msrdAdd-OutputBoxLine -Message ("$(msrdGetLocalizedText 'howtouse')`n") -switchColor "Cyan"
    $global:msrdPsBox.ReadOnly = $true
}

#reset the output box
function msrdResetOutputBox {
    $global:msrdPsBox.Clear()
    msrdInitScript -Type GUI
    msrdInitHowTo
    $global:msrdPsBox.Refresh()
    $global:msrdPsBox.ScrollToCaret()
}

#show the console window
function msrdStartShowConsole {
    param ($nocfg)

    try {
        $PSConsole = [Console.Window]::GetConsoleWindow()
        [Console.Window]::ShowWindow($PSConsole, 5) | Out-Null
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "conVisible")`n"
        $ConsoleMenuItem.Checked = $true
        if (!($nocfg)) {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "ShowConsoleWindow" -value 1
        }
    } catch {
        msrdAdd-OutputBoxLine "Error showing console window: $($_.Exception.Message)"
    }
}

#hide the console window
function msrdStartHideConsole {
    try {
        $PSConsole = [Console.Window]::GetConsoleWindow()
        [Console.Window]::ShowWindow($PSConsole, 0) | Out-Null
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "conHidden")`n"
        $ConsoleMenuItem.Checked = $false
        msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "ShowConsoleWindow" -value 0
    } catch {
        msrdAdd-OutputBoxLine "Error hiding console window: $($_.Exception.Message)"
    }
}

#find folder for output location
function msrdFind-Folder {
    Param ([ValidateScript({Test-Path $_ -PathType Container})][string]$DefaultFolder = 'C:\MS_DATA\', $AppliesTo)

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = $DefaultFolder
    $browse.ShowNewFolderButton = $true
    $browse.Description = msrdGetLocalizedText "location1"

    $result = $browse.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($AppliesTo -eq "Script") {
            $global:msrdLogRoot = $browse.SelectedPath
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "location2") $global:msrdLogRoot`n" -Color Yellow
        } elseif ($AppliesTo -eq "ScheduledTask") {
            $outputLocationTextBox.Text = $browse.SelectedPath
        }
    }
    else {
        if ($AppliesTo -eq "Script") {
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "location2") $global:msrdLogRoot`n" -Color Yellow
        }
        return
    }

    $browse.SelectedPath
    $browse.Dispose()
}

#create the main menu entries
function msrdCreateMenu([string]$Text) {

    $Menu = New-Object System.Windows.Forms.ToolStripMenuItem
    $Menu.Text = msrdGetLocalizedText $Text
    $Menu.Add_MouseEnter({ $this.Owner.Cursor = [System.Windows.Forms.Cursors]::Hand })
    $Menu.Add_MouseLeave({ $this.Owner.Cursor = [System.Windows.Forms.Cursors]::Default })

    return $Menu
}

#create the items under the main menu entries
function msrdCreateMenuItem([System.Windows.Forms.ToolStripMenuItem]$Menu, [string]$Text, $Icon, [switch]$SkipLocalizedText) {

    if ($Text -eq "---") {
        $MenuItem = New-Object System.Windows.Forms.ToolStripSeparator
    } else {
        $MenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
        if (!($SkipLocalizedText)) {
            $MenuItem.Text = msrdGetLocalizedText $Text
        } else {
            $MenuItem.Text = $Text
        }
        $MenuItem.Add_MouseEnter({ $this.Owner.Cursor = [System.Windows.Forms.Cursors]::Hand })
        $MenuItem.Add_MouseLeave({ $this.Owner.Cursor = [System.Windows.Forms.Cursors]::Default })
        if ($Icon) {
            $MenuItem.Image = $Icon.ToBitmap()
        }
    }

    [void]$Menu.DropDownItems.Add($MenuItem)

    return $menuItem
}

#remote data collection
function msrdRun-RemoteScript {
    param (
        [string]$RemoteComputer
    )

    try {
        # Create a PSSession to the remote computer
        $PSSession = try {
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'remotePSinitLocalCred') $RemoteComputer" -Color Yellow
            New-PSSession -ComputerName $RemoteComputer -ErrorAction Stop -EnableNetworkAccess
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'remotePSinitLocalCredSuccess') $RemoteComputer" -Color Lightgreen

        } catch [System.Management.Automation.RuntimeException] {
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'remotePSinitLocalCredFail') $RemoteComputer" -Color Yellow
                if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }

                try {
                    New-PSSession -ComputerName $RemoteComputer -Credential (Get-Credential -Message "$(msrdGetLocalizedText 'remotePSenterCred') $RemoteComputer" -Verbose $null) -ErrorAction Stop
                    msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'remotePSinitProvCredSuccess') $RemoteComputer" -Color Lightgreen
                } catch {
                    $failedCommand = $_.InvocationInfo.Line.TrimStart()
			        $errorMessage = $_.Exception.Message.TrimStart()
			        msrdAdd-OutputBoxLine -Message "Error in $failedCommand $errorMessage`n" -Color Magenta
                    if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
			        return
                }
		} catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
			$errorMessage = $_.Exception.Message.TrimStart()
			msrdAdd-OutputBoxLine -Message "Error in $failedCommand $errorMessage`n" -Color Magenta
            if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
			return
        }

        #copying script files to remote computer
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "remotePScopy") $RemoteComputer" -Color Yellow
    
        $sourcePath = $global:msrdScriptpath
        $destinationPath = "\\$RemoteComputer\C`$\MS_DATA\MSRD-Collect"

        # Check if the destination directory exists, and create it if necessary
        if (-not (Test-Path -Path $destinationPath -PathType Container)) {
            New-Item -ItemType Directory -Path $destinationPath -Force
        } else {
            msrdAdd-OutputBoxLine "'$destinationPath' $(msrdGetLocalizedText 'remotePScopyExists') $RemoteComputer" -Color Yellow
        }

        # Get all files and subdirectories in the source path
        $items = Get-ChildItem -Path $sourcePath -Recurse

        foreach ($item in $items) {
            $relativePath = $item.FullName.Substring($sourcePath.Length + 1)
            $destinationItemPath = Join-Path -Path $destinationPath -ChildPath $relativePath

            # Get the file objects
            $sourceItem = Get-Item $item.FullName
            $destinationItem = Get-Item $destinationItemPath -ErrorAction SilentlyContinue

            # Compare file size and last write time
            if (($sourceItem.Length -ne $destinationItem.Length) -or ($sourceItem.LastWriteTime -gt $destinationItem.LastWriteTime)) {
                # Copy the file because it's different or newer
                Copy-Item -Path $item.FullName -Destination $destinationItemPath -Force
            }
        }

        # Run MSRD-Collect.ps1 on the remote machine
        $ScriptPath = "C:\MS_DATA\MSRD-Collect\MSRD-Collect.ps1"
        if ($global:msrdAVD) { $remoteMachine = "isAVD" } elseif ($global:msrdRDS) { $remoteMachine = "isRDS" } elseif ($global:msrdW365) { $remoteMachine = "isW365" }
        if ($global:msrdSource) { $remoteRole = "isSource" } elseif ($global:msrdTarget) { $remoteRole = "isTarget" }

        $dynamicParameters = [Ordered]@{
            AcceptEula = $true
            AcceptNotice = $true
            SkipAutoUpdate = $true
        }

        switch ($true) {
            { $global:msrdAVD } { $dynamicParameters += @{ Machine = 'isAVD' } }
            { $global:msrdRDS } { $dynamicParameters += @{ Machine = 'isRDS' } }
            { $global:msrdW365 } { $dynamicParameters += @{ Machine = 'isW365' } }
            { $global:msrdSource } { $dynamicParameters += @{ Role = 'isSource' } }
            { $global:msrdTarget } { $dynamicParameters += @{ Role = 'isTarget' } }
            { $script:vCore -ne $varsNO }       { $dynamicParameters += @{ Core = $true } }
            { $script:vProfiles -ne $varsNO }   { $dynamicParameters += @{ Profiles = $true } }
            { $script:vActivation -ne $varsNO } { $dynamicParameters += @{ Activation = $true } }
            { $script:vMSRA -ne $varsNO }       { $dynamicParameters += @{ MSRA = $true } }
            { $script:vSCard -ne $varsNO }      { $dynamicParameters += @{ SCard = $true } }
            { $script:vIME -ne $varsNO }        { $dynamicParameters += @{ IME = $true } }
            { $script:vTeams -ne $varsNO }      { $dynamicParameters += @{ Teams = $true } }
            { $script:vMSIXAA -ne $varsNO }     { $dynamicParameters += @{ MSIXAA = $true } }
            { $script:vHCI -ne $varsNO }        { $dynamicParameters += @{ HCI = $true } }
            { $script:dumpProc -and $script:pidProc -ne "" } { $dynamicParameters += @{ DumpPID = $script:pidProc } }
            { $script:traceNet }                { $dynamicParameters += @{ NetTrace = $true } }
            { $global:onlyDiag }                { $dynamicParameters += @{ DiagOnly = $true } }
        }

        $parametersString = $dynamicParameters | ConvertTo-Json

        # Run the script remotely and capture the output
        msrdAdd-OutputBoxLine "`n$(msrdGetLocalizedText 'remotePSlaunch1')`n$(msrdGetLocalizedText 'initvalues1c') $ScriptPath $parametersString`n" -Color Yellow
        Invoke-Command -Session $PSSession -ScriptBlock {
            param($ScriptPath, $dynamicParameters)

            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope Process
            & $ScriptPath @dynamicParameters

        } -ArgumentList $ScriptPath, $dynamicParameters | ForEach-Object {
            $global:msrdPsBox.AppendText("[$RemoteComputer] $_`r`n")
            $global:msrdPsBox.ScrollToCaret()
            $global:msrdPsBox.Refresh()
        }

        # Close the PSSession
        msrdAdd-OutputBoxLine "`n$(msrdGetLocalizedText 'remotePScomplete') $RemoteComputer`n" -Color Yellow
        Remove-PSSession -Session $PSSession

        # Open File Explorer on the remote machine
        Invoke-Command -ScriptBlock {
            Start-Process explorer.exe -ArgumentList "\\$RemoteComputer\C`$\MS_DATA\"
        }

    } catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        $errorMessage = $_.Exception.Message.TrimStart()
        msrdAdd-OutputBoxLine -Message "`nError in $failedCommand $errorMessage`n" -Color Magenta
        if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
    }

}

#action on pressing the start button
function msrdStartBtnCollect {
    param (
        $RemoteComputer
    )

    # Split the string into an array of computer names and trim spaces
    $computerArray = $RemoteComputer -split ';' | ForEach-Object { $_.Trim() }

    foreach ($target in $computerArray) {
        if ($target -ne $env:computerName) {

            if (($target.Trim() -eq "") -or ($target.Trim() -like "* *") -or ($target -like "*,*")) {
                msrdAdd-OutputBoxLine -Message "`nThe 'Computer(s)' field contains an invalid computer name: $target`nIf you want to provide multiple computer names, delimit them using a semicolon.`n" -Color Magenta
                if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
                continue
            }

            # Check if the computer is reachable

            if (Test-Connection -ComputerName $target -Count 1 -Quiet) {
                msrdAdd-OutputBoxLine -Message "`nThe specified computer ($target) is reachable. Continuing with data collection/diagnostics.`n" -Color Lightgreen

                msrdRun-RemoteScript -RemoteComputer $target

            } else {
                msrdAdd-OutputBoxLine -Message "`nThe specified computer ($target) is not reachable.`nPlease make sure that the computer name is correct and that it is reachable over the network.`nYou might need to 'Turn on file and printer sharing' on the remote computer if not done already.`n" -Color Magenta
                if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
            }

        } else {
            if ($script:vTeams -eq $varsTeams) {
                $TeamsLogs = msrdGetLocalizedText "teamsnote"
                $wshell = New-Object -ComObject Wscript.Shell
                $teamstitle = msrdGetLocalizedText "teamstitle"
                $answer = $wshell.Popup("$TeamsLogs",0,"$teamstitle",5+48)
                if ($answer -eq 4) { $GetTeamsLogs = $false } else { $GetTeamsLogs = $true }
            } else {
                $GetTeamsLogs = $false
            }

            if (-not $GetTeamsLogs) {
                $ActionDictionary["Start"].Text = msrdGetLocalizedText "Running"
                $ActionDictionary["Start"].BackColor = "LightBlue"
                msrdInitFolders

                $global:msrdProgbar.Visible = $true

                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues1a) $global:msrdVersion $(msrdGetLocalizedText initvalues1b) $global:msrdScriptpath"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues1c) $global:msrdCmdLine"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues2)"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues3) $global:msrdLogRoot"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues4) $global:msrdUserprof`n"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText dpidtext3) $script:pidProc"

                $selectedOptions = @()

                $options = @(
                    $machineDictionary["AVD"], $machineDictionary["RDS"], $machineDictionary["W365"]
                )

                foreach ($option in $options) {
                    if ($options.BackColor -eq "LightBlue") {
                        $selectedOptions += $option.Text
                    }
                }

                $selectedOptionsString = $selectedOptions -join ", "

                msrdLogMessage $LogLevel.InfoLogFileOnly "Selected parameters for data collection/diagnostics: $selectedOptionsString`n"

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
                $allVars = $script:varsSystem + $script:varsAVDRDS + $script:varsInfra + $script:varsAD + $script:varsNET + $script:varsLogSec + $script:varsIssues + $script:varsOther
                $allAreFalse = $allVars -notcontains $true
                if ($allAreFalse) {
                    msrdLogMessage $LogLevel.Info -Message "No diagnostics checks are selected. Skipping diagnostic report generation.`n" -Color "Cyan"
                } else {
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
                }

                msrdArchiveData -varsCore $script:vCore
                $ActionDictionary["Start"].Text = msrdGetLocalizedText "Start"
                $ActionDictionary["Start"].BackColor = "Transparent"

                $global:msrdProgbar.Visible = $false
            }
        }
    }
}


#main GUI function for easier external reference
Function msrdAVDCollectGUI {

    $global:msrdForm = New-Object Windows.Forms.Form
    $global:msrdForm.Width = 1366
    $global:msrdForm.Height = 768
    $global:msrdForm.StartPosition = "CenterScreen"
    $global:msrdForm.BackColor = "#eeeeee"
    $global:msrdForm.Icon = $msrdcicon
    if ($global:msrdDevLevel -eq "Insider") {
        $global:msrdForm.Text = 'MSRD-Collect (v' + $global:msrdVersion + ') INSIDER Build - For Testing Purposes Only !'
    } else {
        $global:msrdForm.Text = 'MSRD-Collect (v' + $global:msrdVersion + ')'
    }
    $global:msrdForm.TopLevel = $true
    $global:msrdForm.TopMost = $false

    $global:msrdFormMenu = new-object System.Windows.Forms.MenuStrip
    $global:msrdFormMenu.Location = new-object System.Drawing.Point(0, 0)
    $global:msrdFormMenu.Size = new-object System.Drawing.Size(200, 24)
    $global:msrdFormMenu.BackColor = [System.Drawing.Color]::White
    
    if ($global:msrdLangID -eq "AR") { $global:msrdFormMenu.RightToLeft = "Yes" } else { $global:msrdFormMenu.RightToLeft = "No" }

    #region File menu
    $FileMenu = msrdCreateMenu -Text "FileMenu"

    $RunMenuItem = msrdCreateMenuItem -Menu $FileMenu -Text "RunMenu" -Icon $starticon
    $RunMenuItem.Enabled = $false
    $RunMenuItem.Add_Click({
        
        if ($env:computerName -eq $msrdComputerBox.Text) {
            msrdStartBtnCollect -RemoteComputer $msrdComputerBox.Text
        } else {
            $msg = "$(msrdGetLocalizedText 'remoteModeNotice1')`n`n$(msrdGetLocalizedText 'remoteModeNotice2')`n`n$(msrdGetLocalizedText 'remoteModeNotice3')`n`n$(msrdGetLocalizedText 'remoteModeNotice4')`n`n$(msrdGetLocalizedText 'remoteModeNotice5')"
			$result = [Windows.Forms.MessageBox]::Show($msg, "$(msrdGetLocalizedText 'popupWarning')", [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
			if ($result -eq "Yes") {
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'remoteMode')" -Color "Yellow"
                $global:msrdPsBox.BackColor = "black"
                $global:msrdStatusBarLabel.Text = "$(msrdGetLocalizedText 'remoteModeRunning')"
				msrdStartBtnCollect -RemoteComputer $msrdComputerBox.Text
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'localMode')`n" -Color "Yellow"
                $global:msrdPsBox.BackColor = "#012456"
                $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
			}
        }
    })

    $FileSeparator1 = msrdCreateMenuItem -Menu $FileMenu -Text "---"

    $CheckUpdMenuItem = msrdCreateMenuItem -Menu $FileMenu -Text "UpdateMenu" -Icon $searchicon
    $CheckUpdMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($global:msrdScriptSelfUpdate -eq 1) {
            msrdCheckVersion($msrdVersion) -selfUpdate
        } else {
            msrdCheckVersion($msrdVersion)
        }
    })

    $LiteModeMenuItem = msrdCreateMenuItem -Menu $FileMenu -Text "LiteMode" -Icon $litemodeicon
    $LiteModeMenuItem.Add_Click({
        try {
            $ScriptFile = $global:msrdScriptpath + "\MSRD-Collect.ps1"
            Start-Process PowerShell.exe -ArgumentList "$ScriptFile -LiteMode" -NoNewWindow
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "UILiteMode" -value 1
            If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
            If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
            if ($global:msrdGUI) { $global:msrdForm.Close() } else { Exit }
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
    })

    $FileSeparator2 = msrdCreateMenuItem -Menu $FileMenu -Text "---"

    $ExitMenuItem = msrdCreateMenuItem -Menu $FileMenu -Text "ExitMenu" -Icon $exiticon
    $ExitMenuItem.Add_Click({
        $global:msrdCollectcount = 0
        If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
        If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
        $global:msrdForm.Close()
    })
    #endregion File menu

    #region View menu
    $ViewMenu = msrdCreateMenu -Text "ViewMenu"

    $ConsoleMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "HideConsole" -Icon $consoleicon
    $ConsoleMenuItem.CheckOnClick = $True
    $ConsoleMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($ConsoleMenuItem.Checked) { msrdStartShowConsole } else { msrdStartHideConsole }
    })

    $MaximizeMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "MaximizeWindow" -Icon $maximizedicon
    $MaximizeMenuItem.CheckOnClick = $True
    $MaximizeMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($MaximizeMenuItem.Checked) {
            $global:msrdForm.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'openMaximized')`n"
            $MaximizeMenuItem.Checked = $true
            if (!($nocfg)) {
                msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "MaximizeWindow" -value 1
            }
        } else {
            $global:msrdForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'openWindowed')`n"
            $MaximizeMenuItem.Checked = $false
            if (!($nocfg)) {
                msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "MaximizeWindow" -value 0
            }
        } 
    })

    $OnTopMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "AlwaysOnTop" -Icon $alwaysontopicon
    $OnTopMenuItem.CheckOnClick = $True
    $OnTopMenuItem.Checked = $false
    $OnTopMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($OnTopMenuItem.Checked) {
            $global:msrdForm.TopMost = $true
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'ontop')`n"
        } else {
            $global:msrdForm.TopMost = $false
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'ontopNot')`n"
        }
    })

    $ResultsMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "OutputLocation" -Icon $foldericon
    $ResultsMenuItem.Add_Click({
        If (Test-Path $global:msrdLogRoot) {
            explorer $global:msrdLogRoot
        } else {
            msrdAdd-OutputBoxLine "`n$(msrdGetLocalizedText 'outputNotFound')" "Yellow"
        }
    })

    #update text on menu items based on selected language
    Function msrdRefreshUILang {
        Param ($id)

        SwitchLiveDiagToPsBox
        $global:msrdLangID = $id
        msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "UILanguage" -value $id

        $langName = "UILanguage$id"
        $lang = Get-Variable -Name $langName -ValueOnly
        $lang.Checked = $true
    }

    $UILanguageMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "UILang" -Icon $uilanguageicon

    $UILanguageAR = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "ara" -Icon $uilanguageicon
    $UILanguageAR.CheckOnClick = $True
    $UILanguageAR.Add_Click({
        msrdRefreshUILang -id "AR"
        msrdRestart
    })

    $UILanguageCS = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "cze" -Icon $uilanguageicon
    $UILanguageCS.CheckOnClick = $True
    $UILanguageCS.Add_Click({
        msrdRefreshUILang -id "CS"
        msrdRestart
    })

    $UILanguageNL = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "dut" -Icon $uilanguageicon
    $UILanguageNL.CheckOnClick = $True
    $UILanguageNL.Add_Click({
        msrdRefreshUILang -id "NL"
        msrdRestart
    })

    $UILanguageEN = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "eng" -Icon $uilanguageicon
    $UILanguageEN.CheckOnClick = $True
    $UILanguageEN.Add_Click({
        msrdRefreshUILang -id "EN"
        msrdRestart
    })
    
    $UILanguageFR = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "fre" -Icon $uilanguageicon
    $UILanguageFR.CheckOnClick = $True
    $UILanguageFR.Add_Click({
        msrdRefreshUILang -id "FR"
        msrdRestart
    })

    $UILanguageDE = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "ger" -Icon $uilanguageicon
    $UILanguageDE.CheckOnClick = $True
    $UILanguageDE.Add_Click({
        msrdRefreshUILang -id "DE"
        msrdRestart
    })

    $UILanguageHU = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "hun" -Icon $uilanguageicon
    $UILanguageHU.CheckOnClick = $True
    $UILanguageHU.Add_Click({
        msrdRefreshUILang -id "HU"
        msrdRestart
    })

    $UILanguageIT = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "ita" -Icon $uilanguageicon
    $UILanguageIT.CheckOnClick = $True
    $UILanguageIT.Add_Click({
        msrdRefreshUILang -id "IT"
        msrdRestart
    })
    
    $UILanguageJP = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "jpn" -Icon $uilanguageicon
    $UILanguageJP.CheckOnClick = $True
        $UILanguageJP.Add_Click({
        msrdRefreshUILang -id "JP"
        msrdRestart
    })

    $UILanguagePT = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "por" -Icon $uilanguageicon
    $UILanguagePT.CheckOnClick = $True
    $UILanguagePT.Add_Click({
        msrdRefreshUILang -id "PT"
        msrdRestart
    })
    
    $UILanguageRO = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "rom" -Icon $uilanguageicon
    $UILanguageRO.CheckOnClick = $True
    $UILanguageRO.Add_Click({
        msrdRefreshUILang -id "RO"
        msrdRestart
    })

    $UILanguageES = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "spa" -Icon $uilanguageicon
    $UILanguageES.CheckOnClick = $True
    $UILanguageES.Add_Click({
        msrdRefreshUILang -id "ES"
        msrdRestart
    })

    #$UILanguageTR = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "tur" -Icon $uilanguageicon
    #$UILanguageTR.CheckOnClick = $True
    #$UILanguageTR.Add_Click({
    #    msrdRefreshUILang -id "TR"
    #    msrdRestart
    #})

    $ViewSeparator1 = msrdCreateMenuItem -Menu $ViewMenu -Text "---"

    #diagnostic reports
    $ReportsMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "DiagReports" -Icon $diagreporticon

    function addReportItems {

        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'outputLoc1') ($global:msrdLogRoot)." -Color "Yellow"
        if (Test-Path $global:msrdLogRoot -PathType Container) {
            $RepFiles = Get-ChildItem $global:msrdLogRoot -Recurse -Include *MSRD-Diag.html* | ForEach-Object { $_.FullName }
            # add file names to menu
            if ($RepFiles) {
                $RepMenuItems = @()
                foreach ($RepFile in $RepFiles) {
                    $RepFolderName = Split-Path $RepFile -Parent | Split-Path -Leaf
                    if ($RepFolderName -match "^MSRD-Results-(.+)$") {
                        $RepMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
                        $RepMenuItem.Text = $Matches[1]
                        $RepMenuItem.Tag = $RepFile
                        $Icon = $diagreporticon
                        $RepMenuItem.Image = $Icon.ToBitmap()
                        $RepMenuItem.Add_Click({
                            if (Test-Path -Path $this.Tag) {
                                Invoke-Item $this.Tag
                            } else {
                                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'outputLoc2')`n" -Color "Red"
                            }
                        })
                        $RepMenuItems += $RepMenuItem
                        $RepMenuItems | Sort-Object -Descending Text | ForEach-Object { [void] $ReportsMenuItem.DropDownItems.Add($_) }
                    }
                }

                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'outputLoc3')`n" -Color "Lightgreen"
            } else {
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'outputLoc4') ($global:msrdLogRoot).`n$(msrdGetLocalizedText 'outputLoc5')`n" -Color "Yellow"
            }
        } else {
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'outputLoc6') ($global:msrdLogRoot).`n$(msrdGetLocalizedText 'outputLoc5')`n" -Color "Yellow"
        }
    }

    $ReportsMenuItem.Add_MouseEnter({
        $ReportsMenuItem.DropDownItems.Clear()
        addReportItems
    })

    #endregion View menu

    #region Tools menu
    $ToolsMenu = msrdCreateMenu -Text "ToolsMenu"

    $OutputMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "SetOutputLocation" -Icon $foldericon
    $OutputMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        msrdFind-Folder -DefaultFolder "C:\" -AppliesTo "Script"
    })

    $UserContextMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "SetUserContext" -Icon $usercontexticon
    $UserContextMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        $userContextForm.ShowDialog() | Out-Null
    })

    $ToolsSeparator1 = msrdCreateMenuItem -Menu $ToolsMenu -Text "---"

    $ConfigCollectMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "ConfigDataCollection" -Icon $configicon
    $ConfigCollectMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        $selectCollectForm.ShowDialog() | Out-Null
    })

    $ConfigDiagMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "ConfigDiag" -Icon $configicon
    $ConfigDiagMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        $selectDiagForm.ShowDialog() | Out-Null
    })

    $ToolsSeparator2 = msrdCreateMenuItem -Menu $ToolsMenu -Text "---"

    $ConfigSchedTaskMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "ConfigSchedTask" -Icon $scheduledtaskicon
    $ConfigSchedTaskMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        $staskForm.ShowDialog() | Out-Null
    })

    $OpenTaskSchedMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "OpenTaskSched" -Icon $scheduledtaskicon
    $OpenTaskSchedMenuItem.Add_Click({
        Start-Process -FilePath "taskschd.msc"
    })

    $ToolsSeparator3 = msrdCreateMenuItem -Menu $ToolsMenu -Text "---"

    $global:AutoVerCheckMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "AutoVerCheck" -Icon $updateicon
    $global:AutoVerCheckMenuItem.CheckOnClick = $True
    if ($global:msrdAutoVerCheck -eq 1) {
        $global:AutoVerCheckMenuItem.Checked = $True
    }
    $global:AutoVerCheckMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($global:AutoVerCheckMenuItem.Checked) {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "AutomaticVersionCheck" -value 1
            $global:msrdAutoVerCheck = 1
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'autoUpdate') $(msrdGetLocalizedText 'enabled')`n"
        } else {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "AutomaticVersionCheck" -value 0
            $global:msrdAutoVerCheck = 0
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'autoUpdate') $(msrdGetLocalizedText 'disabled')`n"
        }
    })

    $PlaySoundsMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "PlaySounds" -Icon $soundsystemicon
    $PlaySoundsMenuItem.CheckOnClick = $True
    if ($global:msrdPlaySounds -eq 1) {
        $PlaySoundsMenuItem.Checked = $True
    }
    $PlaySoundsMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($PlaySoundsMenuItem.Checked) {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "PlaySounds" -value 1
            $global:msrdPlaySounds = 1
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'playSnd') $(msrdGetLocalizedText 'enabled')`n"
        } else {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "PlaySounds" -value 0
            $global:msrdPlaySounds = 0
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'playSnd') $(msrdGetLocalizedText 'disabled')`n"
        }
    })

    $AssistModeMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "AssistMode" -Icon $soundassisticon
    $AssistModeMenuItem.CheckOnClick = $True
    if ($global:msrdAssistMode -eq 1) {
        $AssistModeMenuItem.Checked = $True
    }
    $AssistModeMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($AssistModeMenuItem.Checked) {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "AssistMode" -value 1
            $global:msrdAssistMode = 1
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'aaMode') $(msrdGetLocalizedText 'enabled')`n"
        } else {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "AssistMode" -value 0
            $global:msrdAssistMode = 0
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'aaMode') $(msrdGetLocalizedText 'disabled')`n"
        }
    })
    #endregion Tools menu

    #region Help menu
    $HelpMenu = msrdCreateMenu -Text "HelpMenu"

    $ReadMeMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "ReadMe" -Icon $readmeicon
    $ReadMeMenuItem.Add_Click({
        $readmepath = (Get-Item .).FullName + "\MSRD-Collect-ReadMe.txt"
        notepad $readmepath
    })

    $WhatsNewMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "WhatsNew" -Icon $whatsnewicon
    $WhatsNewMenuItem.Add_Click({
        $readmepath = (Get-Item .).FullName + "\MSRD-Collect-RevisionHistory.txt"
        notepad $readmepath
    })

    #download menu
    $downloadicon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\MSRD-Collect.dll", 7, $true))

    $DownloadMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "Download" -Icon $downloadicon
    $DownloadMenuItemMSRDC = msrdCreateMenuItem -Menu $DownloadMenuItem -Text "DownloadMSRDC" -Icon $downloadicon
    $DownloadMenuItemMSRDC.Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/MSRD-Collect") })
    $DownloadMenuItemRDSTr = msrdCreateMenuItem -Menu $DownloadMenuItem -Text "DownloadRDSTracing" -Icon $downloadicon
    $DownloadMenuItemRDSTr.Add_Click({ [System.Diagnostics.Process]::start("http://aka.ms/RDSTracing") })
    $DownloadMenuItemTSS = msrdCreateMenuItem -Menu $DownloadMenuItem -Text "DownloadTSS" -Icon $downloadicon
    $DownloadMenuItemTSS.Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/getTSS") })

    $HelpSeparator1 = msrdCreateMenuItem -Menu $HelpMenu -Text "---"

    #azure submenu
    $AzureMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "AzureMenu" -Icon $azureicon

    $AzureMenuItemOutageNote = msrdCreateMenuItem -Menu $AzureMenuItem -Text "AzOutageNotification" -Icon $azureicon
    $AzureMenuItemOutageNote.Add_Click({ Start-Process https://docs.microsoft.com/azure/azure-monitor/platform/alerts-activity-log-service-notifications })

    $AzureMenuItemStatus = msrdCreateMenuItem -Menu $AzureMenuItem -Text "AzStatus" -Icon $azureicon
    $AzureMenuItemStatus.Add_Click({ Start-Process https://status.azure.com })

    $AzureMenuItemStatusHist = msrdCreateMenuItem -Menu $AzureMenuItem -Text "AzStatusHist" -Icon $azureicon
    $AzureMenuItemStatusHist.Add_Click({ Start-Process https://azure.status.microsoft/en-us/status/history/ })

    $AzureMenuItemServHealth = msrdCreateMenuItem -Menu $AzureMenuItem -Text "AzServHealth" -Icon $azureicon
    $AzureMenuItemServHealth.Add_Click({ Start-Process https://portal.azure.com/#blade/Microsoft_Azure_Health/AzureHealthBrowseBlade })

    $HelpSeparator2 = msrdCreateMenuItem -Menu $HelpMenu -Text "---"

    #docs submenu
    $docsicon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\MSRD-Collect.dll", 6, $true))

    $DocsMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "MSDocs" -Icon $docsicon
    $DocsMenuItemAVD = msrdCreateMenuItem -Menu $DocsMenuItem -Text "AVD" -Icon $docsicon
    $DocsMenuItemAVD.Add_Click({ Start-Process https://aka.ms/avddocs })

    $DocsMenuItemFSLogix = msrdCreateMenuItem -Menu $DocsMenuItem -Text "FSLogix" -Icon $docsicon
    $DocsMenuItemFSLogix.Add_Click({ Start-Process https://aka.ms/fslogix })

    $DocsMenuItemRDS = msrdCreateMenuItem -Menu $DocsMenuItem -Text "RDS" -Icon $docsicon
    $DocsMenuItemRDS.Add_Click({ Start-Process https://aka.ms/rds })

    $DocsMenuItemW365 = msrdCreateMenuItem -Menu $DocsMenuItem -Text "365" -Icon $docsicon
    $DocsMenuItemW365.Add_Click({ Start-Process https://aka.ms/w365docs })

    #techcommunity submenu
    $TCMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "TechCommunity" -Icon $docsicon
    $TCMenuItemAVD = msrdCreateMenuItem -Menu $TCMenuItem -Text "TCAVD" -Icon $docsicon
    $TCMenuItemAVD.Add_Click({ Start-Process https://aka.ms/avdtechcommunity })

    $TCMenuItemFSLogix = msrdCreateMenuItem -Menu $TCMenuItem -Text "TCFSLogix" -Icon $docsicon
    $TCMenuItemFSLogix.Add_Click({ Start-Process https://techcommunity.microsoft.com/t5/fslogix/bd-p/FSLogix })

    $TCMenuItemW365 = msrdCreateMenuItem -Menu $TCMenuItem -Text "TC365" -Icon $docsicon
    $TCMenuItemW365.Add_Click({ Start-Process https://aka.ms/Community/Windows365 })

    $HelpSeparator4 = msrdCreateMenuItem -Menu $HelpMenu -Text "---"

    $Feedback1MenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "FeedbackEmail" -Icon $feedbackicon
    $Feedback1MenuItem.Add_Click({ [System.Diagnostics.Process]::start("mailto:MSRDCollectTalk@microsoft.com?subject=MSRD-Collect%20Feedback") })

    $Feedback2MenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "FeedbackSurvey" -Icon $feedbackicon
    $Feedback2MenuItem.Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/MSRD-Collect-Survey") })

    $HelpSeparator3 = msrdCreateMenuItem -Menu $HelpMenu -Text "---"

    $AboutMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "About" -Icon $abouticon
    $AboutMenuItem.Add_Click({
    [Windows.Forms.MessageBox]::Show("Microsoft CSS
Remote Desktop Data Collection and Diagnostics Script`n
Version:
        $msrdVersion`n
Author:
        Robert Klemencz (Microsoft CSS)`n
Contact:
        MSRDCollectTalk@microsoft.com
        https://aka.ms/MSRD-Collect-Survey", "About", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
    })
    #endregion Help menu



    #region Presets menu
    function msrdSetPreset {
        param ( $Machine, $Role, [array]$Scenario, $Text )

        msrdResetAll
        msrdSetMachine -Machine $Machine
        msrdSetRole -Role $Role
        msrdSetScenario -Scenario $Scenario -Status $true
        $txt = msrdGetLocalizedText "$Text"
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'presetLoaded1'): " -Color Cyan -noNewLine
        msrdAdd-OutputBoxLine "$txt"
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'contextLabel'): " -Color Cyan -noNewLine
        msrdAdd-OutputBoxLine "$Machine"
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'roleLabel'): " -Color Cyan -noNewLine
        msrdAdd-OutputBoxLine "$Role"
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'scenarioLabel'): " -Color Cyan -noNewLine
        msrdAdd-OutputBoxLine "$Scenario"
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'presetLoaded2')`n" -Color Yellow
    }

    $PresetsMenu = msrdCreateMenu -Text "PresetsMenu"
    
    #avd
    $avdPresetMenuItem = msrdCreateMenuItem -Menu $PresetsMenu -Text "AVD" -Icon $machineavdicon

    $avdPresetErrcon1MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetErrcon1" -Icon $machineavdicon #cannot connect source
    $avdPresetErrcon1MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Source -Scenario @("Core") -Text "presetErrcon1" })

    $avdPresetErrcon2MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetErrcon2" -Icon $machineavdicon #cannot connect target
    $avdPresetErrcon2MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core") -Text "presetErrcon2" })

    $avdPresetLogon1MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetLogon1" -Icon $machineavdicon #logon source
    $avdPresetLogon1MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Source -Scenario @("Core") -Text "presetLogon1" })

    $avdPresetLogon2MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetLogon2" -Icon $machineavdicon #logon target
    $avdPresetLogon2MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core", "Profiles") -Text "presetLogon2" })

    $avdPresetScard1MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetScard1" -Icon $machineavdicon #scard source
    $avdPresetScard1MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Source -Scenario @("Core", "SCard") -Text "presetScard1" })

    $avdPresetScard2MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetScard2" -Icon $machineavdicon #scard target
    $avdPresetScard2MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core", "Profiles", "SCard") -Text "presetScard2" })

    $avdPresetMsixaaMenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetMsixaa" -Icon $machineavdicon #msixaa target
    $avdPresetMsixaaMenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core", "Profiles", "MSIXAA") -Text "presetMsixaa" })

    $avdPresetLic3MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetLic3" -Icon $machineavdicon #rd licensing target
    $avdPresetLic3MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core") -Text "presetLic3" })

    $avdPresetDiscon1MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetDiscon1" -Icon $machineavdicon #unexpected disconnect source
    $avdPresetDiscon1MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Source -Scenario @("Core") -Text "presetDiscon1" })

    $avdPresetDiscon2MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetDiscon2" -Icon $machineavdicon #unexpected disconnect target
    $avdPresetDiscon2MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core") -Text "presetDiscon2" })


    #rds
    $rdsPresetMenuItem = msrdCreateMenuItem -Menu $PresetsMenu -Text "RDS" -Icon $machinerdsicon

    $rdsPresetErrcon1MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetErrcon1" -Icon $machinerdsicon #cannot connect source
    $rdsPresetErrcon1MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Source -Scenario @("Core") -Text "presetErrcon1" })

    $rdsPresetErrcon2MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetErrcon2" -Icon $machinerdsicon #cannot connect target
    $rdsPresetErrcon2MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Target -Scenario @("Core") -Text "presetErrcon2" })

    $rdsPresetLogon1MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetLogon1" -Icon $machinerdsicon #logon source
    $rdsPresetLogon1MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Source -Scenario @("Core") -Text "presetLogon1" })

    $rdsPresetLogon2MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetLogon2" -Icon $machinerdsicon #logon target
    $rdsPresetLogon2MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Target -Scenario @("Core", "Profiles") -Text "presetLogon2" })

    $rdsPresetScard1MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetScard1" -Icon $machinerdsicon #scard source
    $rdsPresetScard1MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Source -Scenario @("Core", "SCard") -Text "presetScard1" })

    $rdsPresetScard2MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetScard2" -Icon $machinerdsicon #scard target
    $rdsPresetScard2MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Target -Scenario @("Core", "Profiles", "SCard") -Text "presetScard2" })

    $rdsPresetLic1MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetLic1" -Icon $machinerdsicon #rd licensing source
    $rdsPresetLic1MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Source -Scenario @("Core") -Text "presetLic1" })

    $rdsPresetLic2MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetLic2" -Icon $machinerdsicon #rd licensing target
    $rdsPresetLic2MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Target -Scenario @("Core") -Text "presetLic2" })

    $rdsPresetDiscon1MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetDiscon1" -Icon $machinerdsicon #unexpected disconnect source
    $rdsPresetDiscon1MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Source -Scenario @("Core") -Text "presetDiscon1" })

    $rdsPresetDiscon2MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetDiscon2" -Icon $machinerdsicon #unexpected disconnect target
    $rdsPresetDiscon2MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Target -Scenario @("Core") -Text "presetDiscon2" })


    #w365
    $w365PresetMenuItem = msrdCreateMenuItem -Menu $PresetsMenu -Text "365" -Icon $machinew365icon

    $w365PresetErrcon1MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetErrcon1" -Icon $machinew365icon #cannot connect source
    $w365PresetErrcon1MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Source -Scenario @("Core") -Text "presetErrcon1" })

    $w365PresetErrcon2MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetErrcon2" -Icon $machinew365icon #cannot connect target
    $w365PresetErrcon2MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Target -Scenario @("Core") -Text "presetErrcon2" })

    $w365PresetLogon1MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetLogon1" -Icon $machinew365icon #logon source
    $w365PresetLogon1MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Source -Scenario @("Core") -Text "presetLogon1" })

    $w365PresetLogon2MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetLogon2" -Icon $machinew365icon #logon target
    $w365PresetLogon2MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Target -Scenario @("Core", "Profiles") -Text "presetLogon2" })

    $w365PresetScard1MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetScard1" -Icon $machinew365icon #scard source
    $w365PresetScard1MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Source -Scenario @("Core", "SCard") -Text "presetScard1" })

    $w365PresetScard2MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetScard2" -Icon $machinew365icon #scard target
    $w365PresetScard2MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Target -Scenario @("Core", "Profiles", "SCard") -Text "presetScard2" })

    $w365PresetDiscon1MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetDiscon1" -Icon $machinew365icon #unexpected disconnect source
    $w365PresetDiscon1MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Source -Scenario @("Core") -Text "presetDiscon1" })

    $w365PresetDiscon2MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetDiscon2" -Icon $machinew365icon #unexpected disconnect target
    $w365PresetDiscon2MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Target -Scenario @("Core") -Text "presetDiscon2" })


    $PresetsSeparator1 = msrdCreateMenuItem -Menu $PresetsMenu -Text "---"

    $PresetResetMenuItem = msrdCreateMenuItem -Menu $PresetsMenu -Text "presetReset"
    $PresetResetMenuItem.Add_Click({ msrdResetAll })

    #endregion Presets menu

    $global:msrdFormMenu.Items.AddRange(@($FileMenu, $ViewMenu, $ToolsMenu, $PresetsMenu, $HelpMenu))

    if ($global:msrdMaximizeWindow -eq 1) {
        $global:msrdForm.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
        $MaximizeMenuItem.Checked = $true
    } else {
        $global:msrdForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
        $MaximizeMenuItem.Checked = $false
    }    

    #computerbox
    $msrdComputerLabel = New-Object System.Windows.Forms.Label
    if ($global:msrdLangID -eq "AR") {
        $locx = $global:msrdForm.ClientSize.Width - 95
        $msrdComputerLabel.Location = New-Object System.Drawing.Point($locx, 117)
        $msrdComputerLabel.RightToLeft = "Yes"
        $msrdComputerLabel.Anchor = 'Top,Right'
    } else {
        $msrdComputerLabel.Location = New-Object System.Drawing.Point(5, 117)
        $msrdComputerLabel.Anchor = 'Top,Left'
    }
    
    $msrdComputerLabel.Size = New-Object System.Drawing.Size(90, 20)
    $msrdComputerLabel.Text = msrdGetLocalizedText "CompLabel"

    $global:msrdForm.Controls.Add($msrdComputerLabel)

    $msrdComputerBox = New-Object System.Windows.Forms.TextBox
    if ($global:msrdLangID -eq "AR") {
        $msrdComputerBox.RightToLeft = "Yes"
        $msrdComputerBox.Location = New-Object System.Drawing.Point(5, 114)
    } else {
        $msrdComputerBox.Location = New-Object System.Drawing.Point(95, 114)
    }

    $msrdComputerBox.Width = $global:msrdForm.ClientSize.Width - 105
    $msrdComputerBox.Anchor = 'Top,Left,Bottom,Right'
    $msrdComputerBox.Text = $env:computerName
    
    $msrdComputerBox.Add_MouseEnter({
        $btnTooltip.SetToolTip($msrdComputerBox, "$(msrdGetLocalizedText 'btnTooltipComputer')")
    })
    $global:msrdForm.Controls.Add($msrdComputerBox)

    #psbox
    $global:msrdPsBox = New-Object System.Windows.Forms.RichTextBox
    $global:msrdPsBox.Location = New-Object System.Drawing.Point(0, 140)
    
    if ($global:msrdLangID -eq "JP") {
        $global:msrdPsBox.Font = New-Object System.Drawing.Font("MS Gothic", 10) 
    } else {
        $global:msrdPsBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    }
    
    if ($global:msrdLangID -eq "AR") { $global:msrdPsBox.RightToLeft = "Yes" } else { $global:msrdPsBox.RightToLeft = "No" }

    $global:msrdPsBox.Height = $global:msrdForm.ClientSize.Height - 162
    $global:msrdPsBox.Width = $global:msrdForm.ClientSize.Width
    $global:msrdPsBox.Multiline = $True
    $global:msrdPsBox.ScrollBars = "Vertical"
    $global:msrdPsBox.BackColor = "#012456"
    $global:msrdPsBox.ForeColor = "White"
    $global:msrdPsBox.Anchor = 'Top,Left,Bottom,Right'
    $global:msrdPsBox.SelectionIndent = 10
    $global:msrdPsBox.SelectionRightIndent = 10

    $global:msrdForm.Controls.Add($global:msrdPsBox)

    # Create elements
    if ($global:msrdLangID -eq "AR") {
        $MachineElements = [Ordered]@{ "W365" = $machinew365icon; "RDS" = $machinerdsicon; "AVD" = $machineavdicon }
        $RoleElements = [Ordered]@{ "Target" = $roletargeticon; "Source" = $rolesourceicon }
        $ScenarioElements = [Ordered]@{
            "DiagOnly" = $scenariodiagonlyicon; "NetTrace" = $scenarionettraceicon; "ProcDump" = $scenarioprocdumpicon; "HCI" = $scenariohciicon
            "MSIXAA" = $scenariomsixaaicon; "Teams" = $scenarioteamsicon; "IME" = $scenarioimeicon; "SCard" = $scenarioscardicon
            "MSRA" = $scenariomsraicon; "Activation" = $scenarioactivationicon; "Profiles" = $scenarioprofilesicon; "Core" = $scenariocoreicon
        }
        $ActionElements = [Ordered]@{ "$(msrdGetLocalizedText 'Survey')" = $feedbackicon; "Start" = $starticon }

    } else {
        $MachineElements = [Ordered]@{ "AVD" = $machineavdicon; "RDS" = $machinerdsicon; "W365" = $machinew365icon }
        $RoleElements = [Ordered]@{ "Source" = $rolesourceicon; "Target" = $roletargeticon }
        $ScenarioElements = [Ordered]@{
            "Core" = $scenariocoreicon; "Profiles" = $scenarioprofilesicon; "Activation" = $scenarioactivationicon; "MSRA" = $scenariomsraicon
            "SCard" = $scenarioscardicon; "IME" = $scenarioimeicon; "Teams" = $scenarioteamsicon; "MSIXAA" = $scenariomsixaaicon
            "HCI" = $scenariohciicon; "ProcDump" = $scenarioprocdumpicon; "NetTrace" = $scenarionettraceicon; "DiagOnly" = $scenariodiagonlyicon
        }
        $ActionElements = [Ordered]@{ "Start" = $starticon; "$(msrdGetLocalizedText 'Survey')" = $feedbackicon }
    }

    $LiveElements = [Ordered]@{ "LiveDiag" = $scenariolivediagicon }

    if ($global:msrdLangID -eq "AR") {
        $MachineDictionary, $MachineLabel = msrdCreateButtons -name "$(msrdGetLocalizedText 'contextLabel')" -elements $MachineElements -xPosStart 0 -xOffsetAR 197
        $RoleDictionary, $RoleLabel = msrdCreateButtons -name "$(msrdGetLocalizedText 'roleLabel')" -elements $RoleElements -xPosStart 198 -addSeparator -xOffsetAR 132
        $ScenarioDictionary, $ScenarioLabel = msrdCreateButtons -name "$(msrdGetLocalizedText 'scenarioLabel')" -elements $ScenarioElements -xPosStart 331 -addSeparator -xOffsetAR 782
        $LiveDictionary, $LiveLabel = msrdCreateButtons -elements $LiveElements -xPosStart 1114 -addSeparator -xOffsetAR 67
        $ActionDictionary, $ActionLabel = msrdCreateButtons -elements $ActionElements -xPosStart 1182 -addSeparator -xOffsetAR 132
    } else {
        $MachineDictionary, $MachineLabel = msrdCreateButtons -name "$(msrdGetLocalizedText 'contextLabel')" -elements $MachineElements -xPosStart 0 -addSeparator
        $RoleDictionary, $RoleLabel = msrdCreateButtons -name "$(msrdGetLocalizedText 'roleLabel')" -elements $RoleElements -xPosStart 198 -addSeparator
        $ScenarioDictionary, $ScenarioLabel = msrdCreateButtons -name "$(msrdGetLocalizedText 'scenarioLabel')" -elements $ScenarioElements -xPosStart 331 -addSeparator
        $LiveDictionary, $LiveLabel = msrdCreateButtons -elements $LiveElements -xPosStart 1114 -addSeparator
        $ActionDictionary, $ActionLabel = msrdCreateButtons -elements $ActionElements -xPosStart 1182
    }

    $btnTooltip = New-Object Windows.Forms.ToolTip

    #Machine type events
    $machineDictionary["AVD"].Add_Click({ msrdSetMachine -Machine AVD })
    $btnTooltip.SetToolTip($machineDictionary["AVD"], "$(msrdGetLocalizedText 'btnTooltipAVD')")

    $machineDictionary["RDS"].Add_Click({ msrdSetMachine -Machine RDS })
    $btnTooltip.SetToolTip($machineDictionary["RDS"], "$(msrdGetLocalizedText 'btnTooltipRDS')")

    $machineDictionary["W365"].Add_Click({ msrdSetMachine -Machine W365 })
    $btnTooltip.SetToolTip($machineDictionary["W365"], "$(msrdGetLocalizedText 'btnTooltipW365')")


    #Role type events
    $RoleDictionary["Source"].Add_Click({ msrdSetRole -Role Source })
    $btnTooltip.SetToolTip($RoleDictionary["Source"], "$(msrdGetLocalizedText 'btnTooltipSource')")

    $RoleDictionary["Target"].Add_Click({ msrdSetRole -Role Target })
    $btnTooltip.SetToolTip($RoleDictionary["Target"], "$(msrdGetLocalizedText 'btnTooltipTarget')")

    #Scenario type events
    $ScenarioDictionary["Profiles"].Add_Click({
        if ($script:vProfiles -ne $varsProfiles) {
            msrdSetScenario -Scenario @("Profiles") -Status $true
        } else {
            msrdSetScenario -Scenario @("Profiles") -Status $false
        }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["Profiles"], "$(msrdGetLocalizedText 'btnTooltipProfiles')")

    $ScenarioDictionary["Activation"].Add_Click({
	    if ($script:vActivation -ne $varsActivation) {
            msrdSetScenario -Scenario @("Activation") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("Activation") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["Activation"], "$(msrdGetLocalizedText 'btnTooltipActivation')")

    $ScenarioDictionary["MSRA"].Add_Click({
	    if ($script:vMSRA -ne $varsMSRA) {
		    msrdSetScenario -Scenario @("MSRA") -Status $true
	    } else {
		    $script:vMSRA = $varsNO
		    msrdSetScenario -Scenario @("MSRA") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["MSRA"], "$(msrdGetLocalizedText 'btnTooltipMSRA')")

    $ScenarioDictionary["SCard"].Add_Click({
	    if ($script:vSCard -ne $varsSCard) {
		    msrdSetScenario -Scenario @("SCard") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("SCard") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["SCard"], "$(msrdGetLocalizedText 'btnTooltipSCard')")

    $ScenarioDictionary["IME"].Add_Click({
	    if ($script:vIME -ne $varsIME) {
		    msrdSetScenario -Scenario @("IME") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("IME") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["IME"], "$(msrdGetLocalizedText 'btnTooltipIME')")

    $ScenarioDictionary["Teams"].Add_Click({
	    if ($script:vTeams -ne $varsTeams) {
		    msrdSetScenario -Scenario @("Teams") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("Teams") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["Teams"], "$(msrdGetLocalizedText 'btnTooltipTeams')")

    $ScenarioDictionary["MSIXAA"].Add_Click({
	    if ($script:vMSIXAA -ne $varsMSIXAA) {
		    msrdSetScenario -Scenario @("MSIXAA") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("MSIXAA") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["MSIXAA"], "$(msrdGetLocalizedText 'btnTooltipMSIXAA')")

    $ScenarioDictionary["HCI"].Add_Click({
	    if ($script:vHCI -ne $varsHCI) {
		    msrdSetScenario -Scenario @("HCI") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("HCI") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["HCI"], "$(msrdGetLocalizedText 'btnTooltipHCI')")

    $ScenarioDictionary["ProcDump"].Add_Click({
	    if ($script:dumpProc -ne $True) {
            GetProcDumpPID
            $dumppidForm.ShowDialog() | Out-Null
		    $script:dumpProc = $True
		    $ScenarioDictionary["ProcDump"].BackColor = "LightBlue"
	    } else {
		    $script:dumpProc = $False
		    $ScenarioDictionary["ProcDump"].BackColor = "Transparent"
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["ProcDump"], "$(msrdGetLocalizedText 'btnTooltipProcDump')")

    $ScenarioDictionary["NetTrace"].Add_Click({
	    if ($script:traceNet -ne $True) {
		    $script:traceNet = $True
		    $ScenarioDictionary["NetTrace"].BackColor = "LightBlue"
	    } else {
		    $script:traceNet = $False
		    $ScenarioDictionary["NetTrace"].BackColor = "Transparent"
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["NetTrace"], "$(msrdGetLocalizedText 'btnTooltipNetTrace')")

    $ScenarioDictionary["DiagOnly"].Add_Click({
	    if ($global:onlyDiag -ne $True) {
		    $global:onlyDiag = $true
		    $ScenarioDictionary["DiagOnly"].BackColor = "LightBlue"
            msrdSetScenario -Scenario @("Core") -Status $false
	    } else {
		    $global:onlyDiag = $false
		    $ScenarioDictionary["DiagOnly"].BackColor = "Transparent"
            msrdSetScenario -Scenario @("Core") -Status $True
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["DiagOnly"], "$(msrdGetLocalizedText 'btnTooltipDiagOnly')")

    $LiveDictionary["LiveDiag"].Add_Click({
        if ($global:msrdRDS) {
            $global:liveDiagTab.TabPages.Clear()
            $global:liveDiagTab.TabPages.AddRange(@($liveDiagTabSystem, $liveDiagTabAVDRDS, $liveDiagTabAD, $liveDiagTabNet, $liveDiagTabLogonSec, $liveDiagTabIssues, $liveDiagTabOther))
        } else {
            $global:liveDiagTab.TabPages.Clear()
            $global:liveDiagTab.TabPages.AddRange(@($liveDiagTabSystem, $liveDiagTabAVDRDS, $liveDiagTabAVDInfra, $liveDiagTabAD, $liveDiagTabNet, $liveDiagTabLogonSec, $liveDiagTabIssues, $liveDiagTabOther))
        }

        if ($global:msrdAVD) {
            $msg = "AVD/RDS"
        } elseif ($global:msrdRDS) {
            $msg = "RDS"
	    } elseif ($global:msrdW365) {
            $msg = "AVD/RDS/W365"
        }
        $liveDiagTabAVDRDS.Text = $msg

	    if ($global:msrdLiveDiag -ne $True) {
		    $global:msrdLiveDiag = $True
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            $LiveDictionary["LiveDiag"].Enabled = $true
		    $LiveDictionary["LiveDiag"].BackColor = "LightBlue"
            $ScenarioDictionary["Core"].BackColor = "Transparent"
            $ActionDictionary["Start"].Enabled = $false
            $msrdPsBox.Visible = $false
            $global:liveDiagTab.Visible = $true

            $msrdComputerBox.Enabled = $false
            $msrdComputerBox.Text = $env:computerName
            Import-Module -Name "$PSScriptRoot\MSRDC-Diag" -DisableNameChecking -Force

	    } else {
		    $global:msrdLiveDiag = $False
            if ($global:msrdTarget) {
                msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $true
                msrdInitButtons -ButtonDictionary $LiveDictionary -status $true
                $ScenarioDictionary["Core"].Enabled = $false
            } else {
                $ScenarioDictionary["DiagOnly"].Enabled = $true
            }
		    $LiveDictionary["LiveDiag"].BackColor = "Transparent"
            $ScenarioDictionary["Core"].BackColor = "LightBlue"
            $ActionDictionary["Start"].Enabled = $true
            $msrdPsBox.Visible = $true
            $global:liveDiagTab.Visible = $false

            if ($global:msrdRDS) {
                $msrdComputerBox.Enabled = $false
                $msrdComputerBox.Text = $env:computerName
            } else {
                $msrdComputerBox.Enabled = $true
                $msrdComputerBox.Text = $env:computerName
            }

            Remove-Module MSRDC-Diag
	    }
    })
    $btnTooltip.SetToolTip($LiveDictionary["LiveDiag"], "$(msrdGetLocalizedText 'btnTooltipLiveDiag')")

    msrdInitButtons -ButtonDictionary $RoleDictionary -status $false
    msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
    msrdInitButtons -ButtonDictionary $LiveDictionary -status $false

    $ActionDictionary["Start"].Enabled = $false
    $ActionDictionary["Start"].Add_Click({
        
        if ($env:computerName -eq $msrdComputerBox.Text) {
            msrdStartBtnCollect -RemoteComputer $msrdComputerBox.Text
        } else {
            $msg = "$(msrdGetLocalizedText 'remoteModeNotice1')`n`n$(msrdGetLocalizedText 'remoteModeNotice2')`n`n$(msrdGetLocalizedText 'remoteModeNotice3')`n`n$(msrdGetLocalizedText 'remoteModeNotice4')`n`n$(msrdGetLocalizedText 'remoteModeNotice5')"
			$result = [Windows.Forms.MessageBox]::Show($msg, "$(msrdGetLocalizedText 'popupWarning')", [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
			if ($result -eq "Yes") {
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'remoteMode')" -Color "Yellow"
                $global:msrdPsBox.BackColor = "black"
                $global:msrdStatusBarLabel.Text = "$(msrdGetLocalizedText 'remoteModeRunning')"
				msrdStartBtnCollect -RemoteComputer $msrdComputerBox.Text
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'localMode')`n" -Color "Yellow"
                $global:msrdPsBox.BackColor = "#012456"
                $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
			}
        }
    })
    $btnTooltip.SetToolTip($ActionDictionary["Start"], "$(msrdGetLocalizedText 'RunMenu')")

    $ActionDictionary["$(msrdGetLocalizedText 'Survey')"].Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/MSRD-Collect-Survey") })
    $btnTooltip.SetToolTip($ActionDictionary["$(msrdGetLocalizedText 'Survey')"], "$(msrdGetLocalizedText 'btnTooltipSurvey')")

    #region BottomOptions
    $global:msrdStatusBar = New-Object System.Windows.Forms.StatusStrip
    $global:msrdStatusBarLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $global:msrdStatusBarLabel.Text = "Ready"
    $global:msrdStatusBarLabel.Spring = $true
    $global:msrdStatusBarLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $global:msrdForm.Controls.Add($global:msrdStatusBar)

    $global:msrdProgbar = New-Object System.Windows.Forms.ToolStripProgressBar
    $global:msrdProgbar.Style = [Windows.Forms.ProgressBarStyle]::Continuous
    $global:msrdProgbar.Visible = $false  # Initially not visible
    $global:msrdProgbar.Step = 1
    $global:msrdProgbar.Size = New-Object System.Drawing.Size(300, 10)

    if ($global:msrdLangID -eq "AR") { $global:msrdStatusBar.RightToLeft = "Yes" } else { $global:msrdStatusBar.RightToLeft = "No" }
    $global:msrdStatusBar.Items.AddRange(@($global:msrdStatusBarLabel, $global:msrdProgbar)) | Out-Null
    #endregion BottomOptions


    #region dump
    function GetProcDumpPID {
        $script:datatable = New-Object system.Data.DataTable

        $col1 = New-Object system.Data.DataColumn "ProcPid",([string])
        $col2 = New-Object system.Data.DataColumn "ProcName",([string])
        $script:datatable.columns.add($col1)
        $script:datatable.columns.add($col2)
        $ddlist = Get-Process
        $excludedNames = @("Idle", "System", "Secure System", "csrss", "smss", "Registry")
        foreach ($dditem in $ddlist) {
            if ($dditem.Name -notin $excludedNames) {
                $datarow = $script:datatable.NewRow()
                $test = $dditem.Name + " (" + $dditem.Id + ")"
                $datarow.ProcPid = $dditem.Id
                $datarow.ProcName = $test
                $script:datatable.Rows.Add($datarow)
            }
        }

        $datarow0 = $script:datatable.NewRow()
        $datarow0.ProcPid = ""
        $defaultProc = msrdGetLocalizedText "dpidtext2"
        $datarow0.ProcName = $script:defaultProc
        $script:datatable.Rows.InsertAt($datarow0,0)

        $dumppidBox.Datasource = $script:datatable
        $dumppidBox.ValueMember = "ProcPid"
        $dumppidBox.DisplayMember = "ProcName"
    }

    #region DumpPID
    $dumppidForm = New-Object System.Windows.Forms.Form
    $dumppidForm.Width = 480
    $dumppidForm.Height = 110
    $dumppidForm.StartPosition = "CenterScreen"
    $dumppidForm.ControlBox = $False
    $dumppidForm.BackColor = "#eeeeee"
    $dumppidForm.Text = msrdGetLocalizedText "dpidtext1" #Select the running process to dump

    $dumppidBox = New-Object System.Windows.Forms.ComboBox
    $dumppidBox.Location  = New-Object System.Drawing.Point(25,25)
    $dumppidBox.Size  = New-Object System.Drawing.Point(250,30)
    $dumppidBox.DropDownWidth = 250
    $dumppidBox.DropDownStyle = "DropDownList"
    $dumppidBox.Items.Clear()
    $dumppidBox.Cursor = [System.Windows.Forms.Cursors]::Hand
    $dumppidBoxToolTip = New-Object System.Windows.Forms.ToolTip
    $dumppidBoxToolTip.SetToolTip($dumppidBox, "$(msrdGetLocalizedText "dpidtext1")")
    $dumppidForm.Controls.Add($dumppidBox)

    $dumppidOK = New-Object System.Windows.Forms.Button
    $dumppidOK.Location = New-Object System.Drawing.Size(300,21)
    $dumppidOK.Size = New-Object System.Drawing.Size(60,30)
    $dumppidOK.Text = "OK"
    $dumppidOK.BackColor = "#e6e6e6"
    $dumppidOK.Cursor = [System.Windows.Forms.Cursors]::Hand
    $dumppidForm.Controls.Add($dumppidOK)
    $dumppidOK.Add_Click({
        $dumppidForm.Close()
        if ($dumppidBox.SelectedValue -ne "") {
            $ScenarioDictionary["ProcDump"].BackColor = "LightBlue"
            $script:pidProc = $dumppidBox.SelectedValue
            $selectedIndex = $dumppidBox.SelectedIndex
            $nameProc = $script:datatable.Rows[$selectedIndex][1]
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "dpidtext3") $nameProc`n" "Yellow"
        } else {
            $ScenarioDictionary["ProcDump"].BackColor = "Transparent"
            $script:pidProc = ""
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "dpidtext4")`n" "Yellow"
            $script:dumpProc = $False
        }
    })

    $dumppidCancel = New-Object System.Windows.Forms.Button
    $dumppidCancel.Location = New-Object System.Drawing.Size(370,21)
    $dumppidCancel.Size = New-Object System.Drawing.Size(60,30)
    $dumppidCancel.Text = "Cancel"
    $dumppidCancel.BackColor = "#e6e6e6"
    $dumppidCancel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $dumppidForm.Controls.Add($dumppidCancel)
    $dumppidCancel.Add_Click({
        $dumppidForm.Close()
        if ($script:pidProc -ne "") {
            $ScenarioDictionary["ProcDump"].BackColor = "LightBlue"
            $dumppidBox.SelectedValue = $script:pidProc
            $selectedIndex = $dumppidBox.SelectedIndex
            $nameProc = $script:datatable.Rows[$selectedIndex][1]
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "dpidtext3") $nameProc`n" "Yellow"
        } else {
            $ScenarioDictionary["ProcDump"].BackColor = "Transparent"
            $script:pidProc = ""
            $dumppidBox.SelectedValue = $script:pidProc
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "dpidtext4")`n" "Yellow"
            $script:dumpProc = $False
        }
    })
    #endregion DumpPID


    #region data collection configuration form
    $selectCollectForm = New-Object System.Windows.Forms.Form
    $selectCollectForm.Width = 480
    $selectCollectForm.Height = 340
    $selectCollectForm.StartPosition = "CenterScreen"
    $selectCollectForm.MinimizeBox = $False
    $selectCollectForm.MaximizeBox = $False
    $selectCollectForm.BackColor = "#eeeeee"
    $selectCollectForm.Text = msrdGetLocalizedText "selectCollect1"
    $selectCollectForm.Icon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\MSRD-Collect.dll", 3, $true))

    $selectCollectLabel = New-Object System.Windows.Forms.Label
    $selectCollectLabel.Location  = New-Object System.Drawing.Point(10,10)
    $selectCollectLabel.Size  = New-Object System.Drawing.Point(470,30)
    $selectCollectLabel.Text = msrdGetLocalizedText "selectCollect2"
    $selectCollectForm.Controls.Add($selectCollectLabel)

    # Tab master control
    $MainCollectTab = New-Object System.Windows.Forms.TabControl
    $MainCollectTab.Location = New-Object System.Drawing.Size(10,40)
    $MainCollectTab.Size = New-Object System.Drawing.Size(445,240)
    $MainCollectTab.Multiline = $true
    $MainCollectTab.AutoSize = $true
    $MainCollectTab.Anchor = 'Top,Left,Bottom,Right'

    # Tab pages
    function msrdAddCfgCheckbox {
        param( $cboxtab, [string]$text, [int]$locX, [int]$locY )

        $cbox = New-Object System.Windows.Forms.CheckBox
        $cbox.Location = New-Object System.Drawing.Size($locX,$locY)
        $cbox.Size = New-Object System.Drawing.Size(200,30)
        $cbox.Text = $text
        $cbox.Cursor = [System.Windows.Forms.Cursors]::Hand
        $cbox.Checked = $true
        $cboxtab.Controls.Add($cbox)

        return $cbox
    }

    $CollectTabCore = New-Object System.Windows.Forms.TabPage
    $CollectTabCore.Text = 'Core'

        $core1cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "Core AVD/RDS Information" -locX 20 -locY 20
        $core1cb.Add_CheckStateChanged({ if ($core1cb.Checked) { $script:varsCore[0] = $true } else { $script:varsCore[0] = $false } })

        $core2cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "Event Logs" -locX 20 -locY 50
        $core2cb.Add_CheckStateChanged({
            if ($core2cb.Checked) {
                $script:varsCore[1] = $true; $core2Acb.Checked = $true; $script:varsCore[2] = $true
            } else {
                $script:varsCore[1] = $false; $core2Acb.Checked = $false; $script:varsCore[2] = $false
            }
        })

        $core2Acb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "Security Event Logs" -locX 40 -locY 75
        $core2Acb.Add_CheckStateChanged({ if ($core2Acb.Checked) { $script:varsCore[2] = $true } else { $script:varsCore[2] = $false } })

        $core3cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "Registry Keys" -locX 20 -locY 110
        $core3cb.Add_CheckStateChanged({ if ($core3cb.Checked) { $script:varsCore[3] = $true } else { $script:varsCore[3] = $false } })

        $core4cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "RDP, Network and AD Information" -locX 20 -locY 140
        $core4cb.Add_CheckStateChanged({
            if ($core4cb.Checked) {
                $script:varsCore[4] = $true; $core4Acb.Checked = $true; $script:varsCore[5] = $true
            } else {
                $script:varsCore[4] = $false; $core4Acb.Checked = $false; $script:varsCore[5] = $false
            }
        })

        $core4Acb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "'dsregcmd /status' Information" -locX 40 -locY 165
        $core4Acb.Add_CheckStateChanged({ if ($core4Acb.Checked) { $script:varsCore[5] = $true } else { $script:varsCore[5] = $false } })

        $core5cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "Scheduled Tasks Information" -locX 240 -locY 20
        $core5cb.Add_CheckStateChanged({ if ($core5cb.Checked) { $script:varsCore[6] = $true } else { $script:varsCore[6] = $false } })

        $core6cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "System Information" -locX 240 -locY 50
        $core6cb.Add_CheckStateChanged({ if ($core6cb.Checked) { $script:varsCore[7] = $true } else { $script:varsCore[7] = $false } })

        $core7cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "RDS Roles Information" -locX 240 -locY 80
        $core7cb.Add_CheckStateChanged({ if ($core7cb.Checked) { $script:varsCore[8] = $true } else { $script:varsCore[8] = $false } })

        $core8cb = msrdAddCfgCheckbox -cboxtab $CollectTabCore -text "RDP Listener granular permissions" -locX 240 -locY 110
        $core8cb.Add_CheckStateChanged({ if ($core8cb.Checked) { $script:varsCore[9] = $true } else { $script:varsCore[9] = $false } })

    $CollectTabProfiles = New-Object System.Windows.Forms.TabPage
    $CollectTabProfiles.Text = 'Profiles'

        $profiles1cb = msrdAddCfgCheckbox -cboxtab $CollectTabProfiles -text "Event Logs" -locX 20 -locY 20
        $profiles1cb.Add_CheckStateChanged({ if ($profiles1cb.Checked) { $script:varsProfiles[0] = $true } else { $script:varsProfiles[0] = $false } })

        $profiles2cb = msrdAddCfgCheckbox -cboxtab $CollectTabProfiles -text "Registry Keys" -locX 20 -locY 50
        $profiles2cb.Add_CheckStateChanged({ if ($profiles2cb.Checked) { $script:varsProfiles[1] = $true } else { $script:varsProfiles[1] = $false } })

        $profiles3cb = msrdAddCfgCheckbox -cboxtab $CollectTabProfiles -text "WhoAmI Information" -locX 20 -locY 80
        $profiles3cb.Add_CheckStateChanged({ if ($profiles3cb.Checked) { $script:varsProfiles[2] = $true } else { $script:varsProfiles[2] = $false } })

        $profiles4cb = msrdAddCfgCheckbox -cboxtab $CollectTabProfiles -text "FSLogix Information" -locX 20 -locY 110
        $profiles4cb.Add_CheckStateChanged({ if ($profiles4cb.Checked) { $script:varsProfiles[3] = $true } else { $script:varsProfiles[3] = $false } })

    $CollectTabActivation = New-Object System.Windows.Forms.TabPage
    $CollectTabActivation.Text = 'Activation'

        $activation1cb = msrdAddCfgCheckbox -cboxtab $CollectTabActivation -text "'licensingdiag' Information" -locX 20 -locY 20
        $activation1cb.Add_CheckStateChanged({ if ($activation1cb.Checked) { $script:varsActivation[0] = $true } else { $script:varsActivation[0] = $false } })

        $activation2cb = msrdAddCfgCheckbox -cboxtab $CollectTabActivation -text "'slmgr /dlv' Information" -locX 20 -locY 50
        $activation2cb.Add_CheckStateChanged({ if ($activation2cb.Checked) { $script:varsActivation[1] = $true } else { $script:varsActivation[1] = $false } })

        $activation3cb = msrdAddCfgCheckbox -cboxtab $CollectTabActivation -text "List of domain KMS servers" -locX 20 -locY 80
        $activation3cb.Add_CheckStateChanged({ if ($activation3cb.Checked) { $script:varsActivation[2] = $true } else { $script:varsActivation[2] = $false } })

    $CollectTabMSRA = New-Object System.Windows.Forms.TabPage
    $CollectTabMSRA.Text = 'MSRA'

        $msra1cb = msrdAddCfgCheckbox -cboxtab $CollectTabMSRA -text "Event Logs" -locX 20 -locY 20
        $msra1cb.Add_CheckStateChanged({ if ($msra1cb.Checked) { $script:varsMSRA[0] = $true } else { $script:varsMSRA[0] = $false } })

        $msra2cb = msrdAddCfgCheckbox -cboxtab $CollectTabMSRA -text "Registry Keys" -locX 20 -locY 50
        $msra2cb.Add_CheckStateChanged({ if ($msra2cb.Checked) { $script:varsMSRA[1] = $true } else { $script:varsMSRA[1] = $false } })

        $msra3cb = msrdAddCfgCheckbox -cboxtab $CollectTabMSRA -text "Groups Membership Information" -locX 20 -locY 80
        $msra3cb.Add_CheckStateChanged({ if ($msra3cb.Checked) { $script:varsMSRA[2] = $true } else { $script:varsMSRA[2] = $false } })

        $msra4cb = msrdAddCfgCheckbox -cboxtab $CollectTabMSRA -text "Permissions" -locX 20 -locY 110
        $msra4cb.Add_CheckStateChanged({ if ($msra4cb.Checked) { $script:varsMSRA[3] = $true } else { $script:varsMSRA[3] = $false } })

        $msra5cb = msrdAddCfgCheckbox -cboxtab $CollectTabMSRA -text "Scheduled Task Information" -locX 20 -locY 140
        $msra5cb.Add_CheckStateChanged({ if ($msra5cb.Checked) { $script:varsMSRA[4] = $true } else { $script:varsMSRA[4] = $false } })

    $CollectTabSCard = New-Object System.Windows.Forms.TabPage
    $CollectTabSCard.Text = 'SCard'

        $scard1cb = msrdAddCfgCheckbox -cboxtab $CollectTabSCard -text "Event Logs" -locX 20 -locY 20
        $scard1cb.Add_CheckStateChanged({ if ($scard1cb.Checked) { $script:varsSCard[0] = $true } else { $script:varsSCard[0] = $false } })

        $scard2cb = msrdAddCfgCheckbox -cboxtab $CollectTabSCard -text "'certutil' Information" -locX 20 -locY 50
        $scard2cb.Add_CheckStateChanged({ if ($scard2cb.Checked) { $script:varsSCard[1] = $true } else { $script:varsSCard[1] = $false } })

        $scard3cb = msrdAddCfgCheckbox -cboxtab $CollectTabSCard -text "KDCProxy / RD Gateway Information" -locX 20 -locY 80
        $scard3cb.Add_CheckStateChanged({ if ($scard3cb.Checked) { $script:varsSCard[2] = $true } else { $script:varsSCard[2] = $false } })

    $CollectTabIME = New-Object System.Windows.Forms.TabPage
    $CollectTabIME.Text = 'IME'

        $ime1cb = msrdAddCfgCheckbox -cboxtab $CollectTabIME -text "Registry Keys" -locX 20 -locY 20
        $ime1cb.Add_CheckStateChanged({ if ($ime1cb.Checked) { $script:varsIME[0] = $true } else { $script:varsIME[0] = $false } })

        $ime2cb = msrdAddCfgCheckbox -cboxtab $CollectTabIME -text "Tree Output of IME Folders" -locX 20 -locY 50
        $ime2cb.Add_CheckStateChanged({ if ($ime2cb.Checked) { $script:varsIME[1] = $true } else { $script:varsIME[1] = $false } })

    $CollectTabTeams = New-Object System.Windows.Forms.TabPage
    $CollectTabTeams.Text = 'Teams'

        $teams1cb = msrdAddCfgCheckbox -cboxtab $CollectTabTeams -text "Registry Keys" -locX 20 -locY 20
        $teams1cb.Add_CheckStateChanged({ if ($teams1cb.Checked) { $script:varsTeams[0] = $true } else { $script:varsTeams[0] = $false } })

        $teams2cb = msrdAddCfgCheckbox -cboxtab $CollectTabTeams -text "Teams Logs" -locX 20 -locY 50
        $teams2cb.Add_CheckStateChanged({ if ($teams2cb.Checked) { $script:varsTeams[1] = $true } else { $script:varsTeams[1] = $false } })

    $CollectTabMSIXAA = New-Object System.Windows.Forms.TabPage
    $CollectTabMSIXAA.Text = 'MSIXAA'

        $msixaa1cb = msrdAddCfgCheckbox -cboxtab $CollectTabMSIXAA -text "Event Logs" -locX 20 -locY 20
        $msixaa1cb.Add_CheckStateChanged({ if ($msixaa1cb.Checked) { $script:varsMSIXAA[0] = $true } else { $script:varsMSIXAA[0] = $false } })

    $CollectTabHCI = New-Object System.Windows.Forms.TabPage
    $CollectTabHCI.Text = 'HCI'

        $hci1cb = msrdAddCfgCheckbox -cboxtab $CollectTabHCI -text "HCI Logs" -locX 20 -locY 20
        $hci1cb.Add_CheckStateChanged({ if ($hci1cb.Checked) { $script:varsHCI[0] = $true } else { $script:varsHCI[0] = $false } })

    # Add tabs to tab control
    $MainCollectTab.Controls.AddRange(@($CollectTabCore,$CollectTabProfiles,$CollectTabActivation,$CollectTabMSRA,$CollectTabSCard,$CollectTabIME,$CollectTabTeams,$CollectTabMSIXAA,$CollectTabHCI))
    $selectCollectForm.Controls.Add($MainCollectTab)
    #endregion data collection configuration form

    #region diagnostics configuration form
    $selectDiagForm = New-Object System.Windows.Forms.Form
    $selectDiagForm.Width = 600
    $selectDiagForm.Height = 340
    $selectDiagForm.StartPosition = "CenterScreen"
    $selectDiagForm.MinimizeBox = $False
    $selectDiagForm.MaximizeBox = $False
    $selectDiagForm.BackColor = "#eeeeee"
    $selectDiagForm.Text = msrdGetLocalizedText "selectDiag1"
    $selectDiagForm.Icon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\MSRD-Collect.dll", 3, $true))

    $selectDiagLabel = New-Object System.Windows.Forms.Label
    $selectDiagLabel.Location  = New-Object System.Drawing.Point(10,10)
    $selectDiagLabel.Size  = New-Object System.Drawing.Point(470,30)
    $selectDiagLabel.Text = msrdGetLocalizedText "selectDiag2"
    $selectDiagForm.Controls.Add($selectDiagLabel)

    # Tab master control
    $MainDiagTab = New-Object System.Windows.Forms.TabControl
    $MainDiagTab.Location = New-Object System.Drawing.Size(10,40)
    $MainDiagTab.Size = New-Object System.Drawing.Size(570,240)
    $MainDiagTab.Multiline = $true
    $MainDiagTab.AutoSize = $true
    $MainDiagTab.Anchor = 'Top,Left,Bottom,Right'

    # Tab pages
    $DiagTabSystem = New-Object System.Windows.Forms.TabPage
    $DiagTabSystem.Text = 'System'

        $system1cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "Core" -locX 20 -locY 20
        $system1cb.Add_CheckStateChanged({ if ($system1cb.Checked) { $script:varsSystem[0] = $true } else { $script:varsSystem[0] = $false } })

        $system2cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "CPU Utilization" -locX 20 -locY 50
        $system2cb.Add_CheckStateChanged({ if ($system2cb.Checked) { $script:varsSystem[1] = $true } else { $script:varsSystem[1] = $false } })

        $system3cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "Drives" -locX 20 -locY 80
        $system3cb.Add_CheckStateChanged({ if ($system3cb.Checked) { $script:varsSystem[2] = $true } else { $script:varsSystem[2] = $false } })

        $system4cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "Graphics" -locX 20 -locY 110
        $system4cb.Add_CheckStateChanged({ if ($system4cb.Checked) { $script:varsSystem[3] = $true } else { $script:varsSystem[3] = $false } })

        $system5cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "OS Activation / Licensing" -locX 20 -locY 140
        $system5cb.Add_CheckStateChanged({ if ($system5cb.Checked) { $script:varsSystem[4] = $true } else { $script:varsSystem[4] = $false } })

        $system6cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "SSL / TLS" -locX 20 -locY 170
        $system6cb.Add_CheckStateChanged({ if ($system6cb.Checked) { $script:varsSystem[5] = $true } else { $script:varsSystem[5] = $false } })

        $system7cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "Windows Installer" -locX 240 -locY 20
        $system7cb.Add_CheckStateChanged({ if ($system7cb.Checked) { $script:varsSystem[6] = $true } else { $script:varsSystem[6] = $false } })

        $system8cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "Windows Search" -locX 240 -locY 50
        $system8cb.Add_CheckStateChanged({ if ($system8cb.Checked) { $script:varsSystem[7] = $true } else { $script:varsSystem[7] = $false } })

        $system9cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "Windows Updates" -locX 240 -locY 80
        $system9cb.Add_CheckStateChanged({ if ($system9cb.Checked) { $script:varsSystem[8] = $true } else { $script:varsSystem[8] = $false } })

        $system10cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "User Access Control (UAC)" -locX 240 -locY 110
        $system10cb.Add_CheckStateChanged({ if ($system10cb.Checked) { $script:varsSystem[9] = $true } else { $script:varsSystem[9] = $false } })

        $system11cb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "WinRM / PowerShell" -locX 240 -locY 140
        $system11cb.Add_CheckStateChanged({ if ($system11cb.Checked) { $script:varsSystem[10] = $true } else { $script:varsSystem[10] = $false } })

        $systemAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabSystem -text "All" -locX 480 -locY 170
        $systemAllcb.Add_CheckStateChanged({ if ($systemAllcb.Checked) {
            $script:varsSystem = @(,$true * 11)
            $system1cb.Checked = $true; $system2cb.Checked = $true; $system3cb.Checked = $true; $system4cb.Checked = $true;
            $system5cb.Checked = $true; $system6cb.Checked = $true; $system7cb.Checked = $true; $system8cb.Checked = $true;
            $system9cb.Checked = $true; $system10cb.Checked = $true; $system11cb.Checked = $true
        } else {
            $script:varsSystem = @(,$false * 11)
            $system1cb.Checked = $false; $system2cb.Checked = $false; $system3cb.Checked = $false; $system4cb.Checked = $false;
            $system5cb.Checked = $false; $system6cb.Checked = $false; $system7cb.Checked = $false; $system8cb.Checked = $false;
            $system9cb.Checked = $false; $system10cb.Checked = $false; $system11cb.Checked = $false
        } })


    $DiagTabAVDRDS = New-Object System.Windows.Forms.TabPage
    $DiagTabAVDRDS.Text = 'AVD/RDS/W365'

        $avdrds1cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Redirection" -locX 20 -locY 20
        $avdrds1cb.Add_CheckStateChanged({ if ($avdrds1cb.Checked) { $script:varsAVDRDS[0] = $true } else { $script:varsAVDRDS[0] = $false } })

        $avdrds2cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "FSLogix" -locX 20 -locY 50
        $avdrds2cb.Add_CheckStateChanged({ if ($avdrds2cb.Checked) { $script:varsAVDRDS[1] = $true } else { $script:varsAVDRDS[1] = $false } })

        $avdrds3cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Multimedia" -locX 20 -locY 80
        $avdrds3cb.Add_CheckStateChanged({ if ($avdrds3cb.Checked) { $script:varsAVDRDS[2] = $true } else { $script:varsAVDRDS[2] = $false } })

        $avdrds4cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Quick Assist" -locX 20 -locY 110
        $avdrds4cb.Add_CheckStateChanged({ if ($avdrds4cb.Checked) { $script:varsAVDRDS[3] = $true } else { $script:varsAVDRDS[3] = $false } })

        $avdrds5cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "RDP / Listener" -locX 20 -locY 140
        $avdrds5cb.Add_CheckStateChanged({ if ($avdrds5cb.Checked) { $script:varsAVDRDS[4] = $true } else { $script:varsAVDRDS[4] = $false } })

        $avdrds6cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "RDS Roles" -locX 20 -locY 170
        $avdrds6cb.Add_CheckStateChanged({ if ($avdrds6cb.Checked) { $script:varsAVDRDS[5] = $true } else { $script:varsAVDRDS[5] = $false } })

        $avdrds7cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Remote Desktop Client" -locX 240 -locY 20
        $avdrds7cb.Add_CheckStateChanged({ if ($avdrds7cb.Checked) { $script:varsAVDRDS[6] = $true } else { $script:varsAVDRDS[6] = $false } })

        $avdrds8cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Remote Desktop Licensing" -locX 240 -locY 50
        $avdrds8cb.Add_CheckStateChanged({ if ($avdrds8cb.Checked) { $script:varsAVDRDS[7] = $true } else { $script:varsAVDRDS[7] = $false } })

        $avdrds9cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Session Time Limits" -locX 240 -locY 80
        $avdrds9cb.Add_CheckStateChanged({ if ($avdrds9cb.Checked) { $script:varsAVDRDS[8] = $true } else { $script:varsAVDRDS[8] = $false } })

        $avdrds10cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Teams media optimization" -locX 240 -locY 110
        $avdrds10cb.Add_CheckStateChanged({ if ($avdrds10cb.Checked) { $script:varsAVDRDS[9] = $true } else { $script:varsAVDRDS[9] = $false } })

        $avdrds11cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "Windows 365 Cloud PC Required URLs" -locX 240 -locY 140
        $avdrds11cb.Add_CheckStateChanged({ if ($avdrds11cb.Checked) { $script:varsAVDRDS[10] = $true } else { $script:varsAVDRDS[10] = $false } })

        $avdrdsAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDRDS -text "All" -locX 480 -locY 170
        $avdrdsAllcb.Add_CheckStateChanged({ if ($avdrdsAllcb.Checked) {
            $script:varsAVDRDS = @(,$true * 11)
            $avdrds1cb.Checked = $true; $avdrds2cb.Checked = $true; $avdrds3cb.Checked = $true; $avdrds4cb.Checked = $true;
            $avdrds5cb.Checked = $true; $avdrds6cb.Checked = $true; $avdrds7cb.Checked = $true; $avdrds8cb.Checked = $true;
            $avdrds9cb.Checked = $true; $avdrds10cb.Checked = $true; $avdrds11cb.Checked = $true;
        } else {
            $script:varsAVDRDS = @(,$false * 11)
            $avdrds1cb.Checked = $false; $avdrds2cb.Checked = $false; $avdrds3cb.Checked = $false; $avdrds4cb.Checked = $false;
            $avdrds5cb.Checked = $false; $avdrds6cb.Checked = $false; $avdrds7cb.Checked = $false; $avdrds8cb.Checked = $false;
            $avdrds9cb.Checked = $false; $avdrds10cb.Checked = $false; $avdrds11cb.Checked = $false;
        } })


    $DiagTabAVDInfra = New-Object System.Windows.Forms.TabPage
    $DiagTabAVDInfra.Text = 'AVD Infra'

        $infra1cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDInfra -text "AVD Agent/Stack" -locX 20 -locY 20
        $infra1cb.Add_CheckStateChanged({ if ($infra1cb.Checked) { $script:varsInfra[0] = $true } else { $script:varsInfra[0] = $false } })

        $infra2cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDInfra -text "AVD Host Pool" -locX 20 -locY 50
        $infra2cb.Add_CheckStateChanged({ if ($infra2cb.Checked) { $script:varsInfra[1] = $true } else { $script:varsInfra[1] = $false } })

        $infra3cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDInfra -text "AVD Required URLs" -locX 20 -locY 80
        $infra3cb.Add_CheckStateChanged({ if ($infra3cb.Checked) { $script:varsInfra[2] = $true } else { $script:varsInfra[2] = $false } })

        $infra4cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDInfra -text "AVD Service URI Health" -locX 20 -locY 110
        $infra4cb.Add_CheckStateChanged({ if ($infra4cb.Checked) { $script:varsInfra[3] = $true } else { $script:varsInfra[3] = $false } })

        $infra5cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDInfra -text "Azure Stack HCI" -locX 20 -locY 140
        $infra5cb.Add_CheckStateChanged({ if ($infra5cb.Checked) { $script:varsInfra[4] = $true } else { $script:varsInfra[4] = $false } })

        $infra6cb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDInfra -text "RDP Shortpath" -locX 20 -locY 170
        $infra6cb.Add_CheckStateChanged({ if ($infra6cb.Checked) { $script:varsInfra[5] = $true } else { $script:varsInfra[5] = $false } })

        $infraAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabAVDInfra -text "All" -locX 480 -locY 170
        $infraAllcb.Add_CheckStateChanged({ if ($infraAllcb.Checked) {
            $script:varsInfra = @(,$true * 6)
            $infra1cb.Checked = $true; $infra2cb.Checked = $true; $infra3cb.Checked = $true; $infra4cb.Checked = $true;
            $infra5cb.Checked = $true; $infra6cb.Checked = $true
        } else {
            $script:varsInfra = @(,$false * 6)
            $infra1cb.Checked = $false; $infra2cb.Checked = $false; $infra3cb.Checked = $false; $infra4cb.Checked = $false;
            $infra5cb.Checked = $false; $infra6cb.Checked = $false
        } })


    $DiagTabAD = New-Object System.Windows.Forms.TabPage
    $DiagTabAD.Text = 'Active Directory'

        $ad1cb = msrdAddCfgCheckbox -cboxtab $DiagTabAD -text "Microsoft Entra Join" -locX 20 -locY 20
        $ad1cb.Add_CheckStateChanged({ if ($ad1cb.Checked) { $script:varsAD[0] = $true } else { $script:varsAD[0] = $false } })

        $ad2cb = msrdAddCfgCheckbox -cboxtab $DiagTabAD -text "Domain Controller" -locX 20 -locY 50
        $ad2cb.Add_CheckStateChanged({ if ($ad2cb.Checked) { $script:varsAD[1] = $true } else { $script:varsAD[1] = $false } })

        $adAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabAD -text "All" -locX 480 -locY 170
        $adAllcb.Add_CheckStateChanged({ if ($adAllcb.Checked) {
            $script:varsAD = @(,$true * 7)
            $ad1cb.Checked = $true; $ad2cb.Checked = $true
        } else {
            $script:varsAD = @(,$false * 7)
            $ad1cb.Checked = $false; $ad2cb.Checked = $false
        } })


    $DiagTabNet = New-Object System.Windows.Forms.TabPage
    $DiagTabNet.Text = 'Networking'

        $net1cb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "Core" -locX 20 -locY 20
        $net1cb.Add_CheckStateChanged({ if ($net1cb.Checked) { $script:varsNET[0] = $true } else { $script:varsNET[0] = $false } })

        $net2cb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "DNS" -locX 20 -locY 50
        $net2cb.Add_CheckStateChanged({ if ($net1cb.Checked) { $script:varsNET[1] = $true } else { $script:varsNET[1] = $false } })

        $net3cb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "Firewall" -locX 20 -locY 80
        $net3cb.Add_CheckStateChanged({ if ($net2cb.Checked) { $script:varsNET[2] = $true } else { $script:varsNET[2] = $false } })

        $net4cb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "IP Addresses" -locX 20 -locY 110
        $net4cb.Add_CheckStateChanged({ if ($net3cb.Checked) { $script:varsNET[3] = $true } else { $script:varsNET[3] = $false } })

        $net5cb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "Proxy" -locX 20 -locY 140
        $net5cb.Add_CheckStateChanged({ if ($net4cb.Checked) { $script:varsNET[4] = $true } else { $script:varsNET[4] = $false } })

        $net6cb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "Routing" -locX 20 -locY 170
        $net6cb.Add_CheckStateChanged({ if ($net5cb.Checked) { $script:varsNET[5] = $true } else { $script:varsNET[5] = $false } })

        $net7cb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "VPN" -locX 240 -locY 20
        $net7cb.Add_CheckStateChanged({ if ($net5cb.Checked) { $script:varsNET[6] = $true } else { $script:varsNET[6] = $false } })

        $netAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabNet -text "All" -locX 480 -locY 170
        $netAllcb.Add_CheckStateChanged({ if ($netAllcb.Checked) {
            $script:varsNET = @(,$true * 7)
            $net1cb.Checked = $true; $net2cb.Checked = $true; $net3cb.Checked = $true; $net4cb.Checked = $true;
            $net5cb.Checked = $true; $net6cb.Checked = $true; $net7cb.Checked = $true
        } else {
            $script:varsNET = @(,$false * 7)
            $net1cb.Checked = $false; $net2cb.Checked = $false; $net3cb.Checked = $false; $net4cb.Checked = $false;
            $net5cb.Checked = $false; $net6cb.Checked = $false; $net7cb.Checked = $false
        } })


    $DiagTabLogSec = New-Object System.Windows.Forms.TabPage
    $DiagTabLogSec.Text = 'Logon/Security'

        $logsec1cb = msrdAddCfgCheckbox -cboxtab $DiagTabLogSec -text "Authentication / Logon" -locX 20 -locY 20
        $logsec1cb.Add_CheckStateChanged({ if ($logsec1cb.Checked) { $script:varsLogSec[0] = $true } else { $script:varsLogSec[0] = $false } })

        $logsec2cb = msrdAddCfgCheckbox -cboxtab $DiagTabLogSec -text "Security" -locX 20 -locY 50
        $logsec2cb.Add_CheckStateChanged({ if ($logsec2cb.Checked) { $script:varsLogSec[1] = $true } else { $script:varsLogSec[1] = $false } })

        $logsecAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabLogSec -text "All" -locX 480 -locY 170
        $logsecAllcb.Add_CheckStateChanged({ if ($logsecAllcb.Checked) {
            $script:varsLogSec = @(,$true * 2)
            $logsec1cb.Checked = $true; $logsec2cb.Checked = $true
        } else {
            $script:varsLogSec = @(,$false * 2)
            $logsec1cb.Checked = $false; $logsec2cb.Checked = $false
        } })


    $DiagTabIssues = New-Object System.Windows.Forms.TabPage
    $DiagTabIssues.Text = 'Known Issues'

        $issues1cb = msrdAddCfgCheckbox -cboxtab $DiagTabIssues -text "Known Issues: Event Logs" -locX 20 -locY 20
        $issues1cb.Add_CheckStateChanged({ if ($issues1cb.Checked) { $script:varsIssues[0] = $true } else { $script:varsIssues[0] = $false } })

        $issues2cb = msrdAddCfgCheckbox -cboxtab $DiagTabIssues -text "Known Issues: Logon" -locX 20 -locY 50
        $issues2cb.Add_CheckStateChanged({ if ($issues2cb.Checked) { $script:varsIssues[1] = $true } else { $script:varsIssues[1] = $false } })

        $issuesAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabIssues -text "All" -locX 480 -locY 170
        $issuesAllcb.Add_CheckStateChanged({ if ($issuesAllcb.Checked) {
            $script:varsIssues = @(,$true * 2)
            $issues1cb.Checked = $true; $issues2cb.Checked = $true
        } else {
            $script:varsIssues = @(,$false * 2)
            $issues1cb.Checked = $false; $issues2cb.Checked = $false
        } })

    $DiagTabOther = New-Object System.Windows.Forms.TabPage
    $DiagTabOther.Text = 'Other'

        $other1cb = msrdAddCfgCheckbox -cboxtab $DiagTabOther -text "Microsoft Office" -locX 20 -locY 20
        $other1cb.Add_CheckStateChanged({ if ($other1cb.Checked) { $script:varsOther[0] = $true } else { $script:varsOther[0] = $false } })

        $other2cb = msrdAddCfgCheckbox -cboxtab $DiagTabOther -text "Microsoft OneDrive" -locX 20 -locY 50
        $other2cb.Add_CheckStateChanged({ if ($other2cb.Checked) { $script:varsOther[1] = $true } else { $script:varsOther[1] = $false } })

        $other3cb = msrdAddCfgCheckbox -cboxtab $DiagTabOther -text "Printing" -locX 20 -locY 80
        $other3cb.Add_CheckStateChanged({ if ($other3cb.Checked) { $script:varsOther[2] = $true } else { $script:varsOther[2] = $false } })

        $other4cb = msrdAddCfgCheckbox -cboxtab $DiagTabOther -text "Third Party" -locX 20 -locY 110
        $other4cb.Add_CheckStateChanged({ if ($other4cb.Checked) { $script:varsOther[3] = $true } else { $script:varsOther[3] = $false } })

        $otherAllcb = msrdAddCfgCheckbox -cboxtab $DiagTabOther -text "All" -locX 480 -locY 170
        $otherAllcb.Add_CheckStateChanged({ if ($otherAllcb.Checked) {
            $script:varsOther = @(,$true * 7)
            $other1cb.Checked = $true; $other2cb.Checked = $true; $other3cb.Checked = $true; $other4cb.Checked = $true
        } else {
            $script:varsOther = @(,$false * 7)
            $other1cb.Checked = $false; $other2cb.Checked = $false; $other3cb.Checked = $false; $other4cb.Checked = $false
        } })

    # Add tabs to tab control
    $MainDiagTab.Controls.AddRange(@($DiagTabSystem,$DiagTabAVDRDS,$DiagTabAVDInfra,$DiagTabAD,$DiagTabNet,$DiagTabLogSec,$DiagTabIssues,$DiagTabOther))
    $selectDiagForm.Controls.Add($MainDiagTab)
    #endregion diagnostics configuration form



    #region scheduled task configuration form

    # Create the form
    $staskForm = New-Object System.Windows.Forms.Form
    $staskForm.Text = msrdGetLocalizedText "schedTaskCreate"
    $staskForm.Icon = $scheduledtaskicon
    $staskForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $staskForm.MinimizeBox = $false
    $staskForm.MaximizeBox = $false
    $staskForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $staskForm.Width = 500
    $staskForm.Height = 400

    # Create the controls
    $startDatePickerLabel = New-Object System.Windows.Forms.Label
    $startDatePickerLabel.Location  = New-Object System.Drawing.Point(10,10)
    $startDatePickerLabel.Size = New-Object System.Drawing.Size(100,20)
    $startDatePickerLabel.Text = msrdGetLocalizedText "schedTaskInfo2"
    $staskForm.Controls.Add($startDatePickerLabel)

    $startDatePicker = New-Object System.Windows.Forms.DateTimePicker
    $startDatePicker.Location  = New-Object System.Drawing.Point(120,10)
    $staskForm.Controls.Add($startDatePicker)


    $startTimePickerLabel = New-Object System.Windows.Forms.Label
    $startTimePickerLabel.Location  = New-Object System.Drawing.Point(10,40)
    $startTimePickerLabel.Size = New-Object System.Drawing.Size(100,20)
    $startTimePickerLabel.Text = msrdGetLocalizedText "schedTaskInfo3"
    $staskForm.Controls.Add($startTimePickerLabel)

    $startTimePicker = New-Object System.Windows.Forms.DateTimePicker
    $startTimePicker.Location  = New-Object System.Drawing.Point(120,40)
    $startTimePicker.Size = New-Object System.Drawing.Size(120,20)
    $startTimePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
    $startTimePicker.CustomFormat = "HH:mm"
    $startTimePicker.ShowUpDown = $true
    $staskForm.Controls.Add($startTimePicker)


    $frequencyComboBoxLabel = New-Object System.Windows.Forms.Label
    $frequencyComboBoxLabel.Location  = New-Object System.Drawing.Point(10,70)
    $frequencyComboBoxLabel.Size = New-Object System.Drawing.Size(100,20)
    $frequencyComboBoxLabel.Text = msrdGetLocalizedText "schedTaskInfo4"
    $staskForm.Controls.Add($frequencyComboBoxLabel)

    $frequencyComboBox = New-Object System.Windows.Forms.ComboBox
    $frequencyComboBox.Location  = New-Object System.Drawing.Point(120,70)
    $frequencyComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $frequencyComboBox.Items.AddRange(@("Once", "Daily", "Weekly", "Monthly"))
    $staskForm.Controls.Add($frequencyComboBox)
    $frequencyComboBox.Add_SelectedIndexChanged({ UpdateFields })


    $dayOfWeekComboBoxLabel = New-Object System.Windows.Forms.Label
    $dayOfWeekComboBoxLabel.Location  = New-Object System.Drawing.Point(10,100)
    $dayOfWeekComboBoxLabel.Size = New-Object System.Drawing.Size(100,20)
    $dayOfWeekComboBoxLabel.Text = msrdGetLocalizedText "schedTaskInfo5"
    $staskForm.Controls.Add($dayOfWeekComboBoxLabel)

    $dayOfWeekComboBox = New-Object System.Windows.Forms.ComboBox
    $dayOfWeekComboBox.Location  = New-Object System.Drawing.Point(120,100)
    $dayOfWeekComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $dayOfWeekComboBox.Items.AddRange(@("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
    $staskForm.Controls.Add($dayOfWeekComboBox)
    $dayOfWeekComboBox.Add_SelectedIndexChanged({ UpdateFields })


    $weekOfMonthComboBoxLabel = New-Object System.Windows.Forms.Label
    $weekOfMonthComboBoxLabel.Location  = New-Object System.Drawing.Point(10,130)
    $weekOfMonthComboBoxLabel.Size = New-Object System.Drawing.Size(100,20)
    $weekOfMonthComboBoxLabel.Text = msrdGetLocalizedText "schedTaskInfo12"
    $staskForm.Controls.Add($weekOfMonthComboBoxLabel)

    $weekOfMonthComboBox = New-Object System.Windows.Forms.ComboBox
    $weekOfMonthComboBox.Location  = New-Object System.Drawing.Point(120,130)
    $weekOfMonthComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $weekOfMonthComboBox.Items.AddRange(@("First", "Second", "Third", "Fourth", "Last"))
    $staskForm.Controls.Add($weekOfMonthComboBox)
    $weekOfMonthComboBox.Add_SelectedIndexChanged({ UpdateFields })


    $machineTypeComboBoxLabel = New-Object System.Windows.Forms.Label
    $machineTypeComboBoxLabel.Location  = New-Object System.Drawing.Point(10,170)
    $machineTypeComboBoxLabel.Size = New-Object System.Drawing.Size(100,20)
    $machineTypeComboBoxLabel.Text = msrdGetLocalizedText "schedTaskInfo6"
    $staskForm.Controls.Add($machineTypeComboBoxLabel)

    $machineTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $machineTypeComboBox.Location  = New-Object System.Drawing.Point(120,170)
    $machineTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $machineTypeComboBox.Items.AddRange(@("AVD", "RDS", "W365"))
    $staskForm.Controls.Add($machineTypeComboBox)
    $machineTypeComboBox.Add_SelectedIndexChanged({ UpdateFields })


    $roleComboBoxLabel = New-Object System.Windows.Forms.Label
    $roleComboBoxLabel.Location  = New-Object System.Drawing.Point(10,200)
    $roleComboBoxLabel.Size = New-Object System.Drawing.Size(100,20)
    $roleComboBoxLabel.Text = msrdGetLocalizedText "schedTaskInfo7"
    $staskForm.Controls.Add($roleComboBoxLabel)

    $roleComboBox = New-Object System.Windows.Forms.ComboBox
    $roleComboBox.Location  = New-Object System.Drawing.Point(120,200)
    $roleComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $roleComboBox.Items.AddRange(@("Source", "Target"))
    $staskForm.Controls.Add($roleComboBox)
    $roleComboBox.Add_SelectedIndexChanged({ UpdateFields })


    $scriptLocationTextBoxLabel = New-Object System.Windows.Forms.Label
    $scriptLocationTextBoxLabel.Location  = New-Object System.Drawing.Point(10,230)
    $scriptLocationTextBoxLabel.Size = New-Object System.Drawing.Size(100,20)
    $scriptLocationTextBoxLabel.Text = msrdGetLocalizedText "schedTaskInfo8"
    $staskForm.Controls.Add($scriptLocationTextBoxLabel)

    $scriptLocationTextBox = New-Object System.Windows.Forms.TextBox
    $scriptLocationTextBox.Location  = New-Object System.Drawing.Point(120,230)
    $scriptLocationTextBox.Size = New-Object System.Drawing.Size(200,20)
    $scriptLocationTextBox.Text = "$global:msrdScriptpath\MSRD-Collect.ps1"
    $staskForm.Controls.Add($scriptLocationTextBox)

    $scriptLocationBrowseButton = New-Object System.Windows.Forms.Button
    $scriptLocationBrowseButton.Location  = New-Object System.Drawing.Point(330,230)
    $scriptLocationBrowseButton.Text = "Browse"
    $scriptLocationBrowseButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "PowerShell Scripts (MSRD-Collect.ps1)|MSRD-Collect.ps1"
        $openFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')

        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $scriptLocationTextBox.Text = $openFileDialog.FileName
        }
    })
    $staskForm.Controls.Add($scriptLocationBrowseButton)


    $outputLocationTextBoxLabel = New-Object System.Windows.Forms.Label
    $outputLocationTextBoxLabel.Location  = New-Object System.Drawing.Point(10,270)
    $outputLocationTextBoxLabel.Size = New-Object System.Drawing.Size(100,20)
    $outputLocationTextBoxLabel.Text = msrdGetLocalizedText "schedTaskInfo9"
    $staskForm.Controls.Add($outputLocationTextBoxLabel)

    $outputLocationTextBox = New-Object System.Windows.Forms.TextBox
    $outputLocationTextBox.Location  = New-Object System.Drawing.Point(120,270)
    $outputLocationTextBox.Size = New-Object System.Drawing.Size(200,20)
    $outputLocationTextBox.Text = "C:\MS_DATA"
    $staskForm.Controls.Add($outputLocationTextBox)

    $outputLocationBrowseButton = New-Object System.Windows.Forms.Button
    $outputLocationBrowseButton.Location  = New-Object System.Drawing.Point(330,270)
    $outputLocationBrowseButton.Text = "Browse"
    $outputLocationBrowseButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $outputLocationTextBox.Text = $folderBrowser.SelectedPath
        }
    })
    $staskForm.Controls.Add($outputLocationBrowseButton)


    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location  = New-Object System.Drawing.Point(320,320)
    $okButton.Text = "OK"
    $okButton.Enabled = $false
    $staskForm.Controls.Add($okButton)

    function Show-ErrorMessage {
        param([string]$message)

        $caption = "Error"
        $buttons = [System.Windows.Forms.MessageBoxButtons]::OK
        $icon = [System.Windows.Forms.MessageBoxIcon]::Error

        [System.Windows.Forms.MessageBox]::Show($message, $caption, $buttons, $icon)
    }

    $okButton.Add_Click({
        $outputLocation = $outputLocationTextBox.Text
        $scriptLocation = $scriptLocationTextBox.Text

        if ([string]::IsNullOrWhiteSpace($outputLocation)) {
            $message = msrdGetLocalizedText "schedTaskEmpty1"
            Show-ErrorMessage -message $message

        } elseif ([string]::IsNullOrWhiteSpace($scriptLocation)) {
            $message = msrdGetLocalizedText "schedTaskEmpty2"
            Show-ErrorMessage -message $message

        } else {
            $isOutputLocationValid = Test-Path -Path $outputLocation
            $isScriptLocationValid = Test-Path -Path $scriptLocation

            if ($isOutputLocationValid -and $isScriptLocationValid) {
                $confirmed = Show-ConfirmationDialog
                if ($confirmed) {
                    CreateScheduledTask
                }
            } else {
                if (-not $isOutputLocationValid) {
                    $message = msrdGetLocalizedText "schedTaskNotFound1"
                    Show-ErrorMessage -message $message
                }

                if (-not $isScriptLocationValid) {
                    $message = msrdGetLocalizedText "schedTaskNotFound2"
                    Show-ErrorMessage -message $message
                }
            }
        }
    })

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location  = New-Object System.Drawing.Point(400,320)
    $cancelButton.Text = "Cancel"
    $staskForm.Controls.Add($cancelButton)

    $cancelButton.Add_Click({ $staskForm.Close() })


    # Function to update the enabled state of fields based on selected frequency
    function UpdateFields() {
        $frequency = if ($frequencyComboBox.SelectedItem) { $frequencyComboBox.SelectedItem.ToString() }

        switch ($frequency) {
            'Once' {
                    $dayOfWeekComboBox.Enabled = $false; $dayOfWeekComboBox.SelectedIndex = -1; $dayOfWeekComboBox.Text = "";
                    $weekOfMonthComboBox.Enabled = $false; $weekOfMonthComboBox.SelectedIndex = -1; $weekOfMonthComboBox.Text = "";
                    if ($startDatePicker.Text -ne "" -and $startTimePicker.Text -ne "" -and $frequencyComboBox.Text -ne "" -and
                        $machineTypeComboBox.Text -ne "" -and $roleComboBox.Text -ne "" -and $scriptLocationTextBox.Text -ne "" -and $outputLocationTextBox.Text -ne "") {
                        $okButton.Enabled = $true;
                    } else {
                        $okButton.Enabled = $false;
                    }
                }
            'Daily' {
                    $dayOfWeekComboBox.Enabled = $false; $dayOfWeekComboBox.SelectedIndex = -1; $dayOfWeekComboBox.Text = "";
                    $weekOfMonthComboBox.Enabled = $false; $weekOfMonthComboBox.SelectedIndex = -1; $weekOfMonthComboBox.Text = "";
                    if ($startDatePicker.Text -ne "" -and $startTimePicker.Text -ne "" -and $frequencyComboBox.Text -ne "" -and
                        $machineTypeComboBox.Text -ne "" -and $roleComboBox.Text -ne "" -and $scriptLocationTextBox.Text -ne "" -and $outputLocationTextBox.Text -ne "") {
                        $okButton.Enabled = $true;
                    } else {
                        $okButton.Enabled = $false;
                    }
                }
            'Weekly' {
                    $dayOfWeekComboBox.Enabled = $true;
                    $weekOfMonthComboBox.Enabled = $false; $weekOfMonthComboBox.SelectedIndex = -1; $weekOfMonthComboBox.Text = "";
                    if ($startDatePicker.Text -ne "" -and $startTimePicker.Text -ne "" -and $frequencyComboBox.Text -ne "" -and $dayOfWeekComboBox.Text -ne "" -and
                        $machineTypeComboBox.Text -ne "" -and $roleComboBox.Text -ne "" -and $scriptLocationTextBox.Text -ne "" -and $outputLocationTextBox.Text -ne "") {
                        $okButton.Enabled = $true;
                    } else {
                        $okButton.Enabled = $false;
                    }
                }
            'Monthly' {
                    $dayOfWeekComboBox.Enabled = $true;
                    $weekOfMonthComboBox.Enabled = $true;
                    if ($startDatePicker.Text -ne "" -and $startTimePicker.Text -ne "" -and $frequencyComboBox.Text -ne "" -and $dayOfWeekComboBox.Text -ne "" -and $weekOfMonthComboBox.Text -ne "" -and
                        $machineTypeComboBox.Text -ne "" -and $roleComboBox.Text -ne "" -and $scriptLocationTextBox.Text -ne "" -and $outputLocationTextBox.Text -ne "") {
                        $okButton.Enabled = $true;
                    } else {
                        $okButton.Enabled = $false;
                    }
                }
        }
    }


    function Get-ShortFileName {
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)][Alias("FullName")][string]$Path
        )

        Add-Type -TypeDefinition @'
        using System;
        using System.Runtime.InteropServices;
        public class Win32Utils {
            [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
            public static extern uint GetShortPathName(
                [MarshalAs(UnmanagedType.LPTStr)] string lpszLongPath,
                [MarshalAs(UnmanagedType.LPTStr)] System.Text.StringBuilder lpszShortPath,
                uint cchBuffer);
        }
'@

        $shortPath = New-Object System.Text.StringBuilder 256
        $result = [Win32Utils]::GetShortPathName($Path, $shortPath, $shortPath.Capacity)
        if ($result -gt 0) {
            return $shortPath.ToString().TrimEnd("`0")
        } else {
            throw "Failed to retrieve the short file name for '$Path'"
        }
    }

    function Show-ConfirmationDialog {
        $message = "You are about to create a scheduled task on this machine, which will run MSRD-Collect Diagnostics and generate a MSRD-Diag.html report.`n`nAre you sure you want to continue?"
        $caption = "Confirmation"
        $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
        $icon = [System.Windows.Forms.MessageBoxIcon]::Warning

        $result = [System.Windows.Forms.MessageBox]::Show($message, $caption, $buttons, $icon)
        return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
    }

    Function CreateScheduledTask {

        $trigger = $null
        $frequency = $frequencyComboBox.SelectedItem.ToString()
        $taskName = "MSRD-Collect Diagnostics Report ($frequency)"
        $selectedDate = $startDatePicker.Value.Date
        $selectedTime = $startTimePicker.Value.ToString("HH:mm")

        $machineType = $machineTypeComboBox.SelectedItem.ToString()
        $machineRole = $roleComboBox.SelectedItem.ToString()
        $outputLocation = $outputLocationTextBox.Text
        $scriptLocation = $scriptLocationTextBox.Text

        if (($frequency -eq "Weekly") -or ($frequency -eq "Monthly")) {
            $daysOfWeek = $dayOfWeekComboBox.SelectedItem.ToString()
        }
        if ($frequency -eq "Monthly") {
            $daysOfWeek = $daysOfWeek.Substring(0,3)
        }

        $selectedWeekOfMonth = $weekOfMonthComboBox.SelectedItem

        switch ($frequency) {
            "Once" {
                $trigger = New-ScheduledTaskTrigger -Once -At $selectedDate.Add($selectedTime)
            }
            "Daily" {
                $trigger = New-ScheduledTaskTrigger -Daily -At $selectedDate.Add($selectedTime)
            }
            "Weekly" {
                $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $daysOfWeek -At $selectedDate.Add($selectedTime)
            }
        }

        $scriptParameters = "-Machine is$machineType -Role is$machineRole -DiagOnly -AcceptEula -AcceptNotice -SkipAutoUpdate -OutputDir `"$outputLocation`""

        if ($trigger) {
            $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy RemoteSigned -File `"$scriptLocation`" $scriptParameters"
            $action2 = "PowerShell.exe -ExecutionPolicy RemoteSigned -File `"$scriptLocation`" $scriptParameters"
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -RunOnlyIfNetworkAvailable -StartWhenAvailable
            Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -User "NT AUTHORITY\SYSTEM" -Force
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo1')" -Color Yellow
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo2') " -Color Cyan -noNewLine
            $selectedDate = $selectedDate.ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
            msrdAdd-OutputBoxLine "$selectedDate"
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo3') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "$selectedTime"
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo4') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "$frequency"
            if ($frequency -eq "Weekly") {
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo5') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$daysOfWeek"
            }
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo6') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "$machineType"
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo7') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "$machineRole"
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo8') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "$scriptLocation"
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo9') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "$outputLocation"
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo10') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "NT AUTHORITY\SYSTEM"
            msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo14') " -Color Cyan -noNewLine
            msrdAdd-OutputBoxLine "$action2`n`n"

        } else {
            if ($frequency -eq "Monthly") {

                # Generate the 8.3 short file name for the script location
                $shortScriptLocation = Get-ShortFileName -Path $scriptLocation
                $shortOutputLocation = Get-ShortFileName -Path $outputLocation

                $scriptParameters2 = "-Machine is$machineType -Role is$machineRole -DiagOnly -AcceptEula -AcceptNotice -SkipAutoUpdate -OutputDir $shortOutputLocation"
                $action2 = "PowerShell.exe -ExecutionPolicy Bypass -File $shortScriptLocation $scriptParameters2"

                $command = "schtasks.exe /Create /TN '" + $taskName + "' /SC MONTHLY /D " + $daysOfWeek + " /F /ST " + $selectedTime + " /MO " + $selectedWeekOfMonth + " /TR '" + $action2 + "' /RU 'NT AUTHORITY\SYSTEM'"
                Invoke-Expression "cmd /c $command"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo11')" -Color Yellow
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo2') " -Color Cyan -noNewLine
                $selectedDate = $selectedDate.ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
                msrdAdd-OutputBoxLine "$selectedDate"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo3') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$selectedTime"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo4') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$frequency"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo5') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$daysOfWeek"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo12') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$selectedWeekOfMonth"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo6') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$machineType"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo7') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$machineRole"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo8') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$scriptLocation"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo9') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$outputLocation"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo10') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "NT AUTHORITY\SYSTEM"
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo14') " -Color Cyan -noNewLine
                msrdAdd-OutputBoxLine "$action2`n`n"
            } else {
                msrdAdd-OutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo13')" -Color Red
            }
        }

        # Clean up
        $staskForm.Close()
    }

    # Add event handler to update the enabled state of fields on form load
    $staskForm.Add_Load({ UpdateFields })

    #endregion scheduled task configuration form


    #region UserContext
    $userContextForm = New-Object System.Windows.Forms.Form
    $userContextForm.Width = 400
    $userContextForm.Height = 150
    $userContextForm.StartPosition = "CenterScreen"
    $userContextForm.MinimizeBox = $False
    $userContextForm.MaximizeBox = $False
    $userContextForm.BackColor = "#eeeeee"
    $userContextForm.Text = msrdGetLocalizedText "context1"
    $userContextForm.Icon = $usercontexticon

    $userContextLabel = New-Object System.Windows.Forms.Label
    $userContextLabel.Location  = New-Object System.Drawing.Point(20,20)
    $userContextLabel.Size  = New-Object System.Drawing.Point(350,30)
    $userContextLabel.Text = msrdGetLocalizedText "context2"
    $userContextForm.Controls.Add($userContextLabel)

    $userContextBox = New-Object System.Windows.Forms.TextBox
    $userContextBox.Location  = New-Object System.Drawing.Point(20,60)
    $userContextBox.Size  = New-Object System.Drawing.Point(170,30)
    $userContextBox.Cursor = [System.Windows.Forms.Cursors]::Hand
    if ($global:msrdUserprof) {
        $userContextBox.Text = $global:msrdUserprof
    } else {
        $userContextBox.Text = [System.Environment]::UserName; $global:msrdUserprof = [System.Environment]::UserName
    }
    if ($global:msrdLangID -eq "AR") { $userContextBox.RightToLeft = "Yes" } else { $userContextBox.RightToLeft = "No" }

    $userContextForm.Controls.Add($userContextBox)

    $userContextOK = New-Object System.Windows.Forms.Button
    $userContextOK.Location = New-Object System.Drawing.Size(230,58)
    $userContextOK.Size = New-Object System.Drawing.Size(60,25)
    $userContextOK.Text = "OK"
    $userContextOK.BackColor = "white"
    $userContextOK.Cursor = [System.Windows.Forms.Cursors]::Hand
    $userContextForm.Controls.Add($userContextOK)
    $userContextOK.Add_Click({
        if ($userContextBox.Text) {
            $tempUserprof = $userContextBox.Text
            if (Test-Path -Path "$msrdUserProfilesDir\$tempUserprof") {
                $global:msrdUserprof = $userContextBox.Text
            } else {
                if ($global:msrdUserprof) {
                    $userContextBox.Text = $global:msrdUserprof
                } else {
                    $userContextBox.Text = [System.Environment]::UserName; $global:msrdUserprof = [System.Environment]::UserName
                }
                [System.Windows.Forms.MessageBox]::Show("No local profile found for the specificed '$tempUserprof' user under the default user profile location '$msrdUserProfilesDir'.`nUser context has been reset to: $($userContextBox.Text)", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
        } else {
            $userContextBox.Text = [System.Environment]::UserName; $global:msrdUserprof = [System.Environment]::UserName
        }
        $userContextForm.Close()
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "context3") $($userContextBox.Text)`n" "Yellow"
    })

    $userContextCancel = New-Object System.Windows.Forms.Button
    $userContextCancel.Location = New-Object System.Drawing.Size(300,58)
    $userContextCancel.Size = New-Object System.Drawing.Size(60,25)
    $userContextCancel.Text = "Cancel"
    $userContextCancel.BackColor = "white"
    $userContextCancel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $userContextForm.Controls.Add($userContextCancel)
    $userContextCancel.Add_Click({
        if ($global:msrdUserprof) {
            $userContextBox.Text = $global:msrdUserprof
        } else {
            $userContextBox.Text = [System.Environment]::UserName; $global:msrdUserprof = [System.Environment]::UserName
        }
        $userContextForm.Close()
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "context3") $($userContextBox.Text)`n" "Yellow"
    })
    #endregion UserContext


    #region LiveDiag

    $global:liveDiagTab = New-Object System.Windows.Forms.TabControl
    $global:liveDiagTab.Location = New-Object System.Drawing.Point(0, 140)
    $global:liveDiagTab.Height = $global:msrdForm.ClientSize.Height - 162
    $global:liveDiagTab.Width = $global:msrdForm.ClientSize.Width
    $global:liveDiagTab.Multiline = $true
    $global:liveDiagTab.AutoSize = $true
    $global:liveDiagTab.Appearance = "FlatButtons"

    if ($global:msrdLangID -eq "AR") {
        $global:liveDiagTab.Anchor = 'Top,Right,Left,Bottom'
        $global:liveDiagTab.RightToLeft = "Yes"
        $global:liveDiagTab.RightToLeftLayout = $true
    } else {
        $global:liveDiagTab.Anchor = 'Top,Left,Right,Bottom'
        $global:liveDiagTab.RightToLeft = "No"
        $global:liveDiagTab.RightToLeftLayout = $false
    }

    $liveDiagTabSystem = New-Object System.Windows.Forms.TabPage
    $liveDiagTabSystem.Text = 'System'
    $liveDiagTabSystem.RightToLeft = "No"

    $liveDiagTabAVDRDS = New-Object System.Windows.Forms.TabPage
    $liveDiagTabAVDRDS.RightToLeft = "No"

    $liveDiagTabAVDInfra = New-Object System.Windows.Forms.TabPage
    $liveDiagTabAVDInfra.Text = 'AVD Infra'
    $liveDiagTabAVDInfra.RightToLeft = "No"

    $liveDiagTabAD = New-Object System.Windows.Forms.TabPage
    $liveDiagTabAD.Text = 'Active Directory'
    $liveDiagTabAD.RightToLeft = "No"

    $liveDiagTabNet = New-Object System.Windows.Forms.TabPage
    $liveDiagTabNet.Text = 'Networking'
    $liveDiagTabNet.RightToLeft = "No"

    $liveDiagTabLogonSec = New-Object System.Windows.Forms.TabPage
    $liveDiagTabLogonSec.Text = 'Logon/Security'
    $liveDiagTabLogonSec.RightToLeft = "No"

    $liveDiagTabIssues = New-Object System.Windows.Forms.TabPage
    $liveDiagTabIssues.Text = 'Known Issues'
    $liveDiagTabIssues.RightToLeft = "No"

    $liveDiagTabOther = New-Object System.Windows.Forms.TabPage
    $liveDiagTabOther.Text = 'Other'
    $liveDiagTabOther.RightToLeft = "No"

    $global:liveDiagTab.Visible = $false


    function Create-RichTextBox {
        param (
            [string]$Name,
            $Anchor,
            [System.Windows.Forms.Control]$Container
        )

        $richTextbox = New-Object System.Windows.Forms.RichTextBox
        $richTextbox.Name = $Name
        $richTextbox.Location = [System.Drawing.Point]::new(0, 30)
        $richTextbox.Font = [System.Drawing.Font]::new("Consolas", 10)
        $richTextbox.Height = $Anchor.ClientSize.Height - 30
        $richTextbox.Width = $Anchor.ClientSize.Width
        $richTextbox.Multiline = $true
        $richTextbox.ScrollBars = "Vertical"
        $richTextbox.BackColor = "White"
        $richTextbox.Anchor = 'Top,Left,Bottom,Right'
        $richTextbox.SelectionIndent = 10
        $richTextbox.SelectionRightIndent = 10
        $richTextbox.ReadOnly = $true

        $Container.Controls.Add($richTextbox)

        return $richTextbox
    }

    $global:liveDiagPsBoxSystem = Create-RichTextBox -Name "liveDiagPsBoxSystem" -Anchor $liveDiagTabSystem -container $liveDiagTabSystem
    $global:liveDiagPsBoxAVDRDS = Create-RichTextBox -Name "liveDiagPsBoxAVDRDS" -Anchor $liveDiagTabAVDRDS -container $liveDiagTabAVDRDS
    $global:liveDiagPsBoxAVDInfra = Create-RichTextBox -Name "liveDiagPsBoxAVDInfra" -Anchor $liveDiagTabAVDInfra -container $liveDiagTabAVDInfra
    $global:liveDiagPsBoxAD = Create-RichTextBox -Name "liveDiagPsBoxAD" -Anchor $liveDiagTabAD -container $liveDiagTabAD
    $global:liveDiagPsBoxNet = Create-RichTextBox -Name "liveDiagPsBoxNet" -Anchor $liveDiagTabNet -container $liveDiagTabNet
    $global:liveDiagPsBoxLogonSec = Create-RichTextBox -Name "liveDiagPsBoxLogonSec" -Anchor $liveDiagTabLogonSec -container $liveDiagTabLogonSec
    $global:liveDiagPsBoxIssues = Create-RichTextBox -Name "liveDiagPsBoxIssues" -Anchor $liveDiagTabIssues -container $liveDiagTabIssues
    $global:liveDiagPsBoxOther = Create-RichTextBox -Name "liveDiagPsBoxOther" -Anchor $liveDiagTabOther -container $liveDiagTabOther

    $global:msrdForm.Controls.Add($liveDiagTab)

    function Create-TabButton {
        param (
            [string]$Name,
            [System.Windows.Forms.Control]$Container,
            $XPosition
        )

        $tabButton = New-Object System.Windows.Forms.Button
        $tabButton.Width = 70
        $tabButton.Text = "$Name"

        if ($global:msrdLangID -eq "AR") {
            $xlocbtn = 840 - $XPosition - $tabButton.Width
            $tabButton.Location = [System.Drawing.Point]::new($xlocbtn, 5)
		} else {
            $tabButton.Location = [System.Drawing.Point]::new($XPosition, 5)
		}
        $Container.Controls.Add($tabButton)

        return $tabButton
    }

    function msrdLiveDiagSection {
        param (
            [System.Windows.Forms.Control]$psBox,
            [string]$msgCheck,
            [string]$action
        )

        if ($action -eq "Start") {
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
            $global:msrdDiagnosing = $true
		    $psBox.Clear()
            $psBox.SelectionBackColor = "LightBlue"
            
            if ($global:msrdLangID -eq "AR") {
                $liveDiagText1a = "$(msrdGetLocalizedText 'liveDiag1') "

                $date = Get-Date
                $day = $date.Day.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $month = $date.Month.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $year = $date.Year.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $hour = $date.Hour.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $minute = $date.Minute.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $second = $date.Second.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $millisecond = $date.Millisecond.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $liveDiagText1b = "${hour}:${minute}:${second}.${millisecond} ${year}/${month}/${day}" + "`r`n"

                $currentLength1 = $psBox.TextLength
                $psBox.AppendText($liveDiagText1a)
                $psBox.AppendText($liveDiagText1b)
                $psBox.Select($currentLength1, 0)
                $psBox.SelectionAlignment = "Right"
            } else {
                $liveDiagText1 = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " $(msrdGetLocalizedText 'liveDiag1')`r`n"
                $psBox.AppendText($liveDiagText1)
                $psBox.SelectionAlignment = "Left"
            }
            
            if ($global:msrdAssistMode -eq 1) {
                msrdLogMessageAssistMode "$(msrdGetLocalizedText 'liveDiag1')"
            }

            $psBox.SelectionBackColor = "Transparent"
		    $psBox.Refresh()

        } elseif ($action -eq "Stop") {
            $global:msrdDiagnosing = $false
            $psBox.AppendText("`n`n`n")
            $psBox.SelectionBackColor = "LightBlue"

            if ($global:msrdLangID -eq "AR") {
                $liveDiagText2a = "$(msrdGetLocalizedText 'liveDiag2') "
                
                $date = Get-Date
                $day = $date.Day.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $month = $date.Month.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $year = $date.Year.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $hour = $date.Hour.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $minute = $date.Minute.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $second = $date.Second.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $millisecond = $date.Millisecond.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $liveDiagText2b = "${hour}:${minute}:${second}.${millisecond} ${year}/${month}/${day}"

                $currentLength2 = $psBox.TextLength
                $psBox.AppendText($liveDiagText2a)
                $psBox.AppendText($liveDiagText2b)
                $psBox.Select($currentLength2, 0)
                $psBox.SelectionAlignment = "Right"
            } else {
                $liveDiagText2 = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " $(msrdGetLocalizedText 'liveDiag2')"
                $psBox.AppendText($liveDiagText2)
                $psBox.SelectionAlignment = "Left"
            }

            if ($global:msrdAssistMode -eq 1) {
                msrdLogMessageAssistMode "$(msrdGetLocalizedText 'liveDiag2')"
            }

            $psBox.SelectionBackColor = "Transparent"
            $psBox.ScrollToCaret()
            $psBox.Refresh()
            $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
		}
    }

    #region System tab
    $systemBtnPanel = New-Object System.Windows.Forms.Panel
    $systemBtnPanel.Height = 30
    $systemBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $systemBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $systemBtnPanel.Anchor = 'Top,Right'
	} else {
        $systemBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $systemBtnPanel.Anchor = 'Top,Left'
	}
    $liveDiagTabSystem.Controls.Add($systemBtnPanel)

    $liveDiagSystemBtn = Create-TabButton -Name "Run all" -container $systemBtnPanel -XPosition 0
    $liveDiagSystemBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System" -action "Start"
        
        msrdDiagDeployment
        msrdDiagCPU
        msrdDiagDrives
        msrdDiagGraphics
        if (!($global:msrdSource)) { msrdDiagActivation }
        msrdDiagSSLTLS
        msrdDiagUAC
        msrdDiagInstaller
        if (!($global:msrdSource)) { msrdDiagSearch }
        msrdDiagWU
        msrdDiagWinRMPS

        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})
    
    $liveDiagSystemCoreBtn = Create-TabButton -Name "Core" -container $systemBtnPanel -XPosition 70
    $liveDiagSystemCoreBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Core" -action "Start"
        msrdDiagDeployment
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Core" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemCPUBtn = Create-TabButton -Name "CPU" -container $systemBtnPanel -XPosition 140
    $liveDiagSystemCPUBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > CPU" -action "Start"
        msrdDiagCPU
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > CPU" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemDrivesBtn = Create-TabButton -Name "Drives" -container $systemBtnPanel -XPosition 210
    $liveDiagSystemDrivesBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Drives" -action "Start"
        msrdDiagDrives
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Drives" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemGfxBtn = Create-TabButton -Name "Graphics" -container $systemBtnPanel -XPosition 280
    $liveDiagSystemGfxBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Graphics" -action "Start"
        msrdDiagGraphics
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Graphics" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemActivationBtn = Create-TabButton -Name "Activation" -container $systemBtnPanel -XPosition 350
    $liveDiagSystemActivationBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Activation" -action "Start"
        msrdDiagActivation
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Activation" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemSSLTLSBtn = Create-TabButton -Name "SSL/TLS" -container $systemBtnPanel -XPosition 420
    $liveDiagSystemSSLTLSBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > SSL/TLS" -action "Start"
        msrdDiagSSLTLS
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > SSL/TLS" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemUACBtn = Create-TabButton -Name "UAC" -container $systemBtnPanel -XPosition 490
    $liveDiagSystemUACBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > UAC" -action "Start"
        msrdDiagUAC
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > UAC" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemWInstallerBtn = Create-TabButton -Name "Installer" -container $systemBtnPanel -XPosition 560
    $liveDiagSystemWInstallerBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Windows Installer" -action "Start"
        msrdDiagInstaller
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Windows Installer" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemWSearchBtn = Create-TabButton -Name "Search" -container $systemBtnPanel -XPosition 630
    $liveDiagSystemWSearchBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Windows Search" -action "Start"
        msrdDiagSearch
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Windows Search" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemWUpdateBtn = Create-TabButton -Name "Update" -container $systemBtnPanel -XPosition 700
    $liveDiagSystemWUpdateBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Windows Update" -action "Start"
        msrdDiagWU
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > Windows Update" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})

    $liveDiagSystemWinRMPSBtn = Create-TabButton -Name "WinRM/PS" -container $systemBtnPanel -XPosition 770
    $liveDiagSystemWinRMPSBtn.Add_Click({
        $global:msrdLiveDiagSystem = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > WinRM/PS" -action "Start"
        msrdDiagWinRMPS
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxSystem -msgCheck "System > WinRM/PS" -action "Stop"
        $global:msrdLiveDiagSystem = $false
	})
    #endregion System tab

    #region AVD/RDS tab
    function InitLiveDiagAVDRDS {
        if ($global:msrdAVD) { $script:AVDRDSmsg = "AVD/RDS" } elseif ($global:msrdRDS) { $script:AVDRDSmsg = "RDS" } elseif ($global:msrdW365) { $script:AVDRDSmsg = "AVD/RDS/W365" }

        return $AVDRDSmsg
    }

    $avdrdsBtnPanel = New-Object System.Windows.Forms.Panel
    $avdrdsBtnPanel.Height = 30
    $avdrdsBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $avdrdsBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $avdrdsBtnPanel.Anchor = 'Top,Right'
	} else {
        $avdrdsBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $avdrdsBtnPanel.Anchor = 'Top,Left'
	}
    $liveDiagTabAVDRDS.Controls.Add($avdrdsBtnPanel)

    $liveDiagAVDRDSBtn = Create-TabButton -Name "Run all" -container $avdrdsBtnPanel -XPosition 0
    $liveDiagAVDRDSBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg" -action "Start"

        msrdDiagRedirection
        if (!($global:msrdSource)) { msrdDiagFSLogix }
        msrdDiagMultimedia
        msrdDiagQA
        if (!($global:msrdSource)) {
            msrdDiagRDPListener
            if ($global:msrdOSVer -like "*Windows Server*") { msrdDiagRDSRoles }
        }
        msrdDiagRDClient
        if (!($global:msrdSource)) {
            msrdDiagLicensing
            msrdDiagTimeLimits
        }
        if (!($global:msrdRDS)) { msrdDiagTeams }

        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSRedirectionBtn = Create-TabButton -Name "Redirection" -container $avdrdsBtnPanel -XPosition 70
    $liveDiagAVDRDSRedirectionBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Redirection" -action "Start"
        msrdDiagRedirection
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Redirection" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSFSLogixBtn = Create-TabButton -Name "FSLogix" -container $avdrdsBtnPanel -XPosition 140
    $liveDiagAVDRDSFSLogixBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > FSLogix" -action "Start"
        msrdDiagFSLogix
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > FSLogix" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSMultimediaBtn = Create-TabButton -Name "Multimedia" -container $avdrdsBtnPanel -XPosition 210
    $liveDiagAVDRDSMultimediaBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Multimedia" -action "Start"
        msrdDiagMultimedia
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Multimedia" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSQABtn = Create-TabButton -Name "QA" -container $avdrdsBtnPanel -XPosition 280
    $liveDiagAVDRDSQABtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Quick Assist" -action "Start"
        msrdDiagQA
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Quick Assist" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSRDPListenerBtn = Create-TabButton -Name "Listener" -container $avdrdsBtnPanel -XPosition 350
    $liveDiagAVDRDSRDPListenerBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RDP/Listener" -action "Start"
        msrdDiagRDPListener
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RDP/Listener" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSRDSRolesBtn = Create-TabButton -Name "RDS Roles" -container $avdrdsBtnPanel -XPosition 420
    $liveDiagAVDRDSRDSRolesBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RDS Roles" -action "Start"
        if ($global:msrdOSVer -like "*Windows Server*") {
            msrdDiagRDSRoles
        } else {
            $msg = "`nThis machine is not running a Server OS. Skipping RDS Roles check (not applicable)."
            $liveDiagPsBoxAVDRDS.AppendText($msg)
		    $liveDiagPsBoxAVDRDS.Refresh()
        }
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RDS Roles" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSRDClientBtn = Create-TabButton -Name "RD Client" -container $avdrdsBtnPanel -XPosition 490
    $liveDiagAVDRDSRDClientBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RD Client" -action "Start"
        msrdDiagRDClient
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RD Client" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSLicensingBtn = Create-TabButton -Name "Licensing" -container $avdrdsBtnPanel -XPosition 560
    $liveDiagAVDRDSLicensingBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RD Licensing" -action "Start"
        msrdDiagLicensing
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > RD Licensing" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSTimeLimitsBtn = Create-TabButton -Name "Time Limits" -container $avdrdsBtnPanel -XPosition 630
    $liveDiagAVDRDSTimeLimitsBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Session Time Limits" -action "Start"
        msrdDiagTimeLimits
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Session Time Limits" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})

    $liveDiagAVDRDSTeamsBtn = Create-TabButton -Name "Teams" -container $avdrdsBtnPanel -XPosition 700
    $liveDiagAVDRDSTeamsBtn.Add_Click({
        InitLiveDiagAVDRDS
        $global:msrdLiveDiagAVDRDS = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Teams" -action "Start"
        msrdDiagTeams
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDRDS -msgCheck "$script:AVDRDSmsg > Teams" -action "Stop"
        $global:msrdLiveDiagAVDRDS = $false
	})
    #endregion AVD/RDS tab

    #region AVD Infra tab
    $avdinfraBtnPanel = New-Object System.Windows.Forms.Panel
    $avdinfraBtnPanel.Height = 30
    $avdinfraBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $avdinfraBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $avdinfraBtnPanel.Anchor = 'Top,Right'
	} else {
        $avdinfraBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $avdinfraBtnPanel.Anchor = 'Top,Left'
	}
    $liveDiagTabAVDInfra.Controls.Add($avdinfraBtnPanel)

    $liveDiagAVDInfraBtn = Create-TabButton -Name "Run all" -container $avdinfraBtnPanel -XPosition 0
    $liveDiagAVDInfraBtn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra" -action "Start"
        if ($global:msrdAVD -or $global:msrdW365) {
            if (!($global:msrdSource)) {
                msrdDiagAgentStack
                msrdDiagHP
            }
        }
        if (!($global:msrdRDS)) { msrdDiagURL }
        if (!($global:msrdSource)) {
            if ($global:msrdAVD -or $global:msrdW365) { msrdDiagURIHealth }
            if ($global:msrdAVD) { msrdDiagHCI }
        }
        if (!($global:msrdRDS)) { msrdDiagShortpath }
        if ($global:msrdW365) { msrdDiagW365 }
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})

    $liveDiagAVDInfraAgentStackBtn = Create-TabButton -Name "Agents" -container $avdinfraBtnPanel -XPosition 70
    $liveDiagAVDInfraAgentStackBtn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Agents/Stack" -action "Start"
        msrdDiagAgentStack
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Agents/Stack" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})

    $liveDiagAVDInfraHPBtn = Create-TabButton -Name "Host Pool" -container $avdinfraBtnPanel -XPosition 140
    $liveDiagAVDInfraHPBtn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Host Pool" -action "Start"
        msrdDiagHP
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Host Pool" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})

    $liveDiagAVDInfraReqURLBtn = Create-TabButton -Name "Req. URLs" -container $avdinfraBtnPanel -XPosition 210
    $liveDiagAVDInfraReqURLBtn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > AVD Required URLs" -action "Start"
        msrdDiagURL
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > AVD Required URLs" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})

    $liveDiagAVDInfraURIBtn = Create-TabButton -Name "URI Health" -container $avdinfraBtnPanel -XPosition 280
    $liveDiagAVDInfraURIBtn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > AVD Services URI Health" -action "Start"
        msrdDiagURIHealth
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > AVD Services URI Health" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})

    $liveDiagAVDInfraHCIBtn = Create-TabButton -Name "HCI" -container $avdinfraBtnPanel -XPosition 350
    $liveDiagAVDInfraHCIBtn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Azure Stack HCI" -action "Start"
        msrdDiagHCI
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Azure Stack HCI" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})

    $liveDiagAVDInfraShortpathBtn = Create-TabButton -Name "Shortpath" -container $avdinfraBtnPanel -XPosition 420
    $liveDiagAVDInfraShortpathBtn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > RDP Shortpath" -action "Start"
        msrdDiagShortpath
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > RDP Shortpath" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})

    $liveDiagAVDInfraW365Btn = Create-TabButton -Name "W365" -container $avdinfraBtnPanel -XPosition 490
    $liveDiagAVDInfraW365Btn.Add_Click({
        $global:msrdLiveDiagAVDInfra = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Windows 365 Cloud PC Required URLs" -action "Start"
        msrdDiagW365
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAVDInfra -msgCheck "AVD Infra > Windows 365 Cloud PC Required URLs" -action "Stop"
        $global:msrdLiveDiagAVDInfra = $false
	})
    #endregion AVD Infra tab

    #region AD tab
    $adBtnPanel = New-Object System.Windows.Forms.Panel
    $adBtnPanel.Height = 30
    $adBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $adBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $adBtnPanel.Anchor = 'Top,Right'
	} else {
        $adBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $adBtnPanel.Anchor = 'Top,Left'
	}
    $liveDiagTabAD.Controls.Add($adBtnPanel)

    $liveDiagADBtn = Create-TabButton -Name "Run all" -container $adBtnPanel -XPosition 0
    $liveDiagADBtn.Add_Click({
        $global:msrdLiveDiagAD = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAD -msgCheck "Active Directory" -action "Start"
        msrdDiagEntraJoin
        msrdDiagDC
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAD -msgCheck "Active Directory" -action "Stop"
        $global:msrdLiveDiagAD = $false
	})

    $liveDiagADAADJBtn = Create-TabButton -Name "Entra Join" -container $adBtnPanel -XPosition 70
    $liveDiagADAADJBtn.Add_Click({
        $global:msrdLiveDiagAD = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAD -msgCheck "Active Directory > Microsoft Entra Join" -action "Start"
        msrdDiagEntraJoin
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAD -msgCheck "Active Directory > Microsoft Entra Join" -action "Stop"
        $global:msrdLiveDiagAD = $false
	})

    $liveDiagADDCBtn = Create-TabButton -Name "DC" -container $adBtnPanel -XPosition 140
    $liveDiagADDCBtn.Add_Click({
        $global:msrdLiveDiagAD = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAD -msgCheck "Active Directory > Domain" -action "Start"
        msrdDiagDC
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxAD -msgCheck "Active Directory > Domain" -action "Stop"
        $global:msrdLiveDiagAD = $false
	})
    #endregion AD tab

    #region Networking tab
    $netBtnPanel = New-Object System.Windows.Forms.Panel
    $netBtnPanel.Height = 30
    $netBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $netBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $netBtnPanel.Anchor = 'Top,Right'
    } else {
        $netBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $netBtnPanel.Anchor = 'Top,Left'
    }
    $liveDiagTabNet.Controls.Add($netBtnPanel)

    $liveDiagNetBtn = Create-TabButton -Name "Run all" -container $netBtnPanel -XPosition 0
    $liveDiagNetBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking" -action "Start"
        msrdDiagNWCore
        msrdDiagDNS
        msrdDiagFirewall
        msrdDiagIPAddresses
        msrdDiagProxy
        msrdDiagRouting
        msrdDiagVPN
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})

    $liveDiagNetNWCoreBtn = Create-TabButton -Name "Core NET" -container $netBtnPanel -XPosition 70
    $liveDiagNetNWCoreBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Core NET" -action "Start"
        if ($varsNET[0]) { msrdDiagNWCore }
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Core NET" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})

    $liveDiagNetDNSBtn = Create-TabButton -Name "DNS" -container $netBtnPanel -XPosition 140
    $liveDiagNetDNSBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > DNS" -action "Start"
        msrdDiagDNS
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > DNS" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})

    $liveDiagNetFirewallBtn = Create-TabButton -Name "Firewall" -container $netBtnPanel -XPosition 210
    $liveDiagNetFirewallBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Firewall" -action "Start"
        msrdDiagFirewall
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Firewall" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})

    $liveDiagNetIPBtn = Create-TabButton -Name "IPs" -container $netBtnPanel -XPosition 280
    $liveDiagNetIPBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > IP Addresses" -action "Start"
        msrdDiagIPAddresses
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > IP Addresses" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})

    $liveDiagNetProxyBtn = Create-TabButton -Name "Proxy" -container $netBtnPanel -XPosition 350
    $liveDiagNetProxyBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Proxy" -action "Start"
        msrdDiagProxy
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Proxy" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})

    $liveDiagNetRoutingBtn = Create-TabButton -Name "Routing" -container $netBtnPanel -XPosition 420
    $liveDiagNetRoutingBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Routing" -action "Start"
        msrdDiagRouting
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > Routing" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})

    $liveDiagNetVPNBtn = Create-TabButton -Name "VPN" -container $netBtnPanel -XPosition 490
    $liveDiagNetVPNBtn.Add_Click({
        $global:msrdLiveDiagNet = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > VPN" -action "Start"
        msrdDiagVPN
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxNet -msgCheck "Networking > VPN" -action "Stop"
        $global:msrdLiveDiagNet = $false
	})
    #endregion Networking tab

    #region Logon/Security tab
    $logonSecBtnPanel = New-Object System.Windows.Forms.Panel
    $logonSecBtnPanel.Height = 30
    $logonSecBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $logonSecBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $logonSecBtnPanel.Anchor = 'Top,Right'
    } else {
        $logonSecBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $logonSecBtnPanel.Anchor = 'Top,Left'
    }
    $liveDiagTabLogonSec.Controls.Add($logonSecBtnPanel)

    $liveDiagLogonSecBtn = Create-TabButton -Name "Run all" -container $logonSecBtnPanel -XPosition 0
    $liveDiagLogonSecBtn.Add_Click({
        $global:msrdLiveDiagLogonSec = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxLogonSec -msgCheck "Logon/Security" -action "Start"
        msrdDiagAuth
        msrdDiagSecurity
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxLogonSec -msgCheck "Logon/Security" -action "Stop"
        $global:msrdLiveDiagLogonSec = $false
	})

    $liveDiagLogonSecAuthBtn = Create-TabButton -Name "Auth" -container $logonSecBtnPanel -XPosition 70
    $liveDiagLogonSecAuthBtn.Add_Click({
        $global:msrdLiveDiagLogonSec = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxLogonSec -msgCheck "Logon/Security > Authentication/Logon" -action "Start"
        msrdDiagAuth
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxLogonSec -msgCheck "Logon/Security > Authentication/Logon" -action "Stop"
        $global:msrdLiveDiagLogonSec = $false
	})

    $liveDiagLogonSecSecurityBtn = Create-TabButton -Name "Security" -container $logonSecBtnPanel -XPosition 140
    $liveDiagLogonSecSecurityBtn.Add_Click({
        $global:msrdLiveDiagLogonSec = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxLogonSec -msgCheck "Logon/Security > Security" -action "Start"
        msrdDiagSecurity
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxLogonSec -msgCheck "Logon/Security > Security" -action "Stop"
        $global:msrdLiveDiagLogonSec = $false
	})
    #endregion Logon/Security tab
    
    #region Known Issues tab
    $issuesBtnPanel = New-Object System.Windows.Forms.Panel
    $issuesBtnPanel.Height = 30
    $issuesBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $issuesBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $issuesBtnPanel.Anchor = 'Top,Right'
    } else {
        $issuesBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $issuesBtnPanel.Anchor = 'Top,Left'
    }
    $liveDiagTabIssues.Controls.Add($issuesBtnPanel)

    $liveDiagLogonIssuesBtn = Create-TabButton -Name "Run all" -container $issuesBtnPanel -XPosition 0
    $liveDiagLogonIssuesBtn.Add_Click({
        $global:msrdLiveDiagIssues = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxIssues -msgCheck "Known Issues" -action "Start"
        msrdLogDiag $LogLevel.Normal -Message "Issues identified in Event Logs over the past 5 days" -DiagTag "IssuesCheck"
        if (!($global:msrdSource)) {
            if ($global:msrdAVD -or $global:msrdW365) {
                msrdDiagAVDIssueEvents
                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            }

            $needHR = $false
            if ($script:foundRDS.Name -eq "RDS-Licensing") { msrdDiagRDLicensingIssueEvents; $needHR = $true }
            if ($script:foundRDS.Name -eq "RDS-GATEWAY") { msrdDiagRDGatewayIssueEvents; $needHR = $true }
            if ($needHR) { msrdLogDiag $LogLevel.DiagFileOnly -Type "HR" }
            msrdDiagRDIssueEvents
            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        }

        msrdDiagCommonIssueEvents
        if (!($global:msrdSource)) { msrdDiagLogonIssues }
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxIssues -msgCheck "Known Issues" -action "Stop"
        $global:msrdLiveDiagIssues = $false
	})

    $liveDiagLogonIssuesIdentifiedBtn = Create-TabButton -Name "Last 5 days" -container $issuesBtnPanel -XPosition 70
    $liveDiagLogonIssuesIdentifiedBtn.Add_Click({
        $global:msrdLiveDiagIssues = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxIssues -msgCheck "Known Issues > Issues identified in Event Logs over the past 5 days" -action "Start"
        msrdLogDiag $LogLevel.Normal -Message "Issues identified in Event Logs over the past 5 days" -DiagTag "IssuesCheck"
        if (!($global:msrdSource)) {
            if ($global:msrdAVD -or $global:msrdW365) {
                msrdDiagAVDIssueEvents
                msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
            }

            $needHR = $false
            if ($script:foundRDS.Name -eq "RDS-Licensing") { msrdDiagRDLicensingIssueEvents; $needHR = $true }
            if ($script:foundRDS.Name -eq "RDS-GATEWAY") { msrdDiagRDGatewayIssueEvents; $needHR = $true }
            if ($needHR) { msrdLogDiag $LogLevel.DiagFileOnly -Type "HR" }
            msrdDiagRDIssueEvents
            msrdLogDiag $LogLevel.DiagFileOnly -Type "HR"
        }

        msrdDiagCommonIssueEvents
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxIssues -msgCheck "Known Issues > Issues identified in Event Logs over the past 5 days" -action "Stop"
        $global:msrdLiveDiagIssues = $false
	})

    $liveDiagLogonIssuesLogonBtn = Create-TabButton -Name "Logon" -container $issuesBtnPanel -XPosition 140
    $liveDiagLogonIssuesLogonBtn.Add_Click({
        $global:msrdLiveDiagIssues = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxIssues -msgCheck "Known Issues > Potential Logon Issue Generators' Diagnostics completed" -action "Start"
        msrdDiagLogonIssues
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxIssues -msgCheck "Known Issues > Potential Logon Issue Generators' Diagnostics completed" -action "Stop"
        $global:msrdLiveDiagIssues = $false
	})
    #endregion Known Issues tab

    #region Other tab
    $otherBtnPanel = New-Object System.Windows.Forms.Panel
    $otherBtnPanel.Height = 30
    $otherBtnPanel.Width = 850
    if ($global:msrdLangID -eq "AR") {
        $xloc = $global:msrdForm.ClientSize.Width - 1990
        $otherBtnPanel.Location = New-Object System.Drawing.Point($xloc, 0)
        $otherBtnPanel.Anchor = 'Top,Right'
    } else {
        $otherBtnPanel.Location = New-Object System.Drawing.Point(0, 0)
        $otherBtnPanel.Anchor = 'Top,Left'
    }
    $liveDiagTabOther.Controls.Add($otherBtnPanel)

    $liveDiagOtherBtn = Create-TabButton -Name "Run all" -container $otherBtnPanel -XPosition 0
    $liveDiagOtherBtn.Add_Click({
        $global:msrdLiveDiagOther = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other' Diagnostics completed" -action "Start"
        if (!($global:msrdSource)) {
            msrdDiagOffice
            msrdDiagOD
        }
        msrdDiagPrinting
        msrdDiagCitrix3P
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other" -action "Stop"
        $global:msrdLiveDiagOther = $false
	})

    $liveDiagOtherOfficeBtn = Create-TabButton -Name "Office" -container $otherBtnPanel -XPosition 70
    $liveDiagOtherOfficeBtn.Add_Click({
        $global:msrdLiveDiagOther = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > Office' Diagnostics completed" -action "Start"
        msrdDiagOffice
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > Office" -action "Stop"
        $global:msrdLiveDiagOther = $false
	})

    $liveDiagOtherODBtn = Create-TabButton -Name "OneDrive" -container $otherBtnPanel -XPosition 140
    $liveDiagOtherODBtn.Add_Click({
        $global:msrdLiveDiagOther = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > OneDrive' Diagnostics completed" -action "Start"
        msrdDiagOD
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > OneDrive" -action "Stop"
        $global:msrdLiveDiagOther = $false
	})

    $liveDiagOtherPrintingBtn = Create-TabButton -Name "Printing" -container $otherBtnPanel -XPosition 210
    $liveDiagOtherPrintingBtn.Add_Click({
        $global:msrdLiveDiagOther = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > Printing' Diagnostics completed" -action "Start"
        msrdDiagPrinting
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > Printing" -action "Stop"
        $global:msrdLiveDiagOther = $false
	})

    $liveDiagOtherCitrix3PBtn = Create-TabButton -Name "Citrix/3P" -container $otherBtnPanel -XPosition 280
    $liveDiagOtherCitrix3PBtn.Add_Click({
        $global:msrdLiveDiagOther = $true
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > Citrix/Third Party' Diagnostics completed" -action "Start"
        msrdDiagCitrix3P
        msrdLiveDiagSection -psBox $global:liveDiagPsBoxOther -msgCheck "Other > Printing" -action "Stop"
        $global:msrdLiveDiagOther = $false
	})
    #endregion LiveDiag

    $global:msrdForm.Controls.Add($global:msrdFormMenu)
    $global:msrdForm.MainMenuStrip = $global:msrdFormMenu
    $global:msrdForm.Controls.Add($buttonRibbon)

    $global:msrdForm.Add_Shown({

        $global:msrdPsBox.Focus()

        #check tools
        if ($global:avdnettestpath -eq "") {
            msrdAdd-OutputBoxLine ("avdnettest.exe could not be found. Information on RDP Shortpath for AVD availability will be incomplete. Make sure you download and unpack the full package of MSRD-Collect or TSS`n") -Color "Red"
        }

        if ($global:msrdForm -and $global:msrdForm.Visible) {
            $global:msrdGUI = $true
        } else {
            $global:msrdGUI = $false
        }

        if ($global:msrdAutoVerCheck -eq 1) {
            if ($global:msrdScriptSelfUpdate -eq 1) {
                msrdCheckVersion($msrdVersion) -selfUpdate
            } else {
                msrdCheckVersion($msrdVersion)
            }
        } else {
            msrdAdd-OutputBoxLine "Automatic update check on script launch is Disabled"
        }

        msrdInitScript -Type GUI
        msrdInitHowTo
    })

    if ($global:msrdShowConsole -eq 1) { msrdStartShowConsole } else { msrdStartHideConsole }
    msrdRefreshUILang $global:msrdLangID

    $global:msrdForm.Add_Closing({
        $global:msrdLiveDiag = $false
        $global:msrdCollectcount = 0
        If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
        If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
    })

    $global:msrdForm.ShowDialog() | Out-Null
    msrdStartShowConsole -nocfg $true
}

Export-ModuleMember -Function msrdAdd-OutputBoxLine, msrdFind-Folder, msrdAVDCollectGUI
# SIG # Begin signature block
# MIInwQYJKoZIhvcNAQcCoIInsjCCJ64CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDYoiIoFSY7oFvt
# 7oDnV9A7dj+0lzO3mCy2gzbK9E/htaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGaEwghmdAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINcThVXBN2bHh6lq7nvg6cpT
# roY1VLi5aZeY8ojeAZZ7MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAu2hC8yp40ircq4XrlvtszQXkygkEfOM8xyK9H7ycoTyxHTTFF8yfMPCi
# Ko22LpXAbWewHZXVJAYQ9BOceJEvwOaNm9grvCmzErWG0vr5YA8mdD5UfECklO+R
# f0jl07Pu0GEUyQ7FrRpNaZmB52JInskM29CfcSmVpBal/TMqNOZ5LIDtVgwxmltW
# wAW7z7buxvpYEe9VevTZxUH/hIWpciGgsFRoWWpveiOp+dDgJZymJZcSgHqaCuZk
# yfoXEMJiGfR+CXn4bzQHxMd2pwBVQGM/LiupfGP1qjTWuBRo1Azo5eW3dgzRLurr
# KF8DZqCyNKKbxVx6jmJ3bcdzPWj+s6GCFyswghcnBgorBgEEAYI3AwMBMYIXFzCC
# FxMGCSqGSIb3DQEHAqCCFwQwghcAAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCBWDT/CMmR9hLTKCB66freWTrWG+RNuT+EHYB/K/dMgVQIGZlddmE9c
# GBMyMDI0MDYxMjE1MDA0MC4yNzdaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OkQwODItNEJGRC1FRUJBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIRejCCBycwggUPoAMCAQICEzMAAAHcweCMwl9YXo4AAQAAAdwwDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMx
# MDEyMTkwNzA2WhcNMjUwMTEwMTkwNzA2WjCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpEMDgyLTRC
# RkQtRUVCQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAIvIsyA1sjg9kSKJzelrUWF5
# ShqYWL83amn3SE5JyIVPUC7F6qTcLphhHZ9idf21f0RaGrU8EHydF8NxPMR2KVNi
# AtCGPJa8kV1CGvn3beGB2m2ltmqJanG71mAywrkKATYniwKLPQLJ00EkXw5TSwfm
# JXbdgQLFlHyfA5Kg+pUsJXzqumkIvEr0DXPvptAGqkdFLKwo4BTlEgnvzeTfXukz
# X8vQtTALfVJuTUgRU7zoP/RFWt3WagahZ6UloI0FC8XlBQDVDX5JeMEsx7jgJDdE
# nK44Y8gHuEWRDq+SG9Xo0GIOjiuTWD5uv3vlEmIAyR/7rSFvcLnwAqMdqcy/iqQP
# MlDOcd0AbniP8ia1BQEUnfZT3UxyK9rLB/SRiKPyHDlg8oWwXyiv3+bGB6dmdM61
# ur6nUtfDf51lPcKhK4Vo83pOE1/niWlVnEHQV9NJ5/DbUSqW2RqTUa2O2KuvsyRG
# MEgjGJA12/SqrRqlvE2fiN5ZmZVtqSPWaIasx7a0GB+fdTw+geRn6Mo2S6+/bZEw
# S/0IJ5gcKGinNbfyQ1xrvWXPtXzKOfjkh75iRuXourGVPRqkmz5UYz+R5ybMJWj+
# mfcGqz2hXV8iZnCZDBrrnZivnErCMh5Flfg8496pT0phjUTH2GChHIvE4SDSk2hw
# WP/uHB9gEs8p/9Pe/mt9AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQU6HPSBd0OfEX3
# uNWsdkSraUGe3dswHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBANnrb8Ewr8eX/H1s
# Kt3rnwTDx4AqgHbkMNQo+kUGwCINXS3y1GUcdqsK/R1g6Tf7tNx1q0NpKk1JTupU
# JfHdExKtkuhHA+82lT7yISp/Y74dqJ03RCT4Q+8ooQXTMzxiewfErVLt8Wefebnc
# ST0i6ypKv87pCYkxM24bbqbM/V+M5VBppCUs7R+cETiz/zEA1AbZL/viXtHmryA0
# CGd+Pt9c+adsYfm7qe5UMnS0f/YJmEEMkEqGXCzyLK+dh+UsFi0d4lkdcE+Zq5JN
# jIHesX1wztGVAtvX0DYDZdN2WZ1kk+hOMblUV/L8n1YWzhP/5XQnYl03AfXErn+1
# Eatylifzd3ChJ1xuGG76YbWgiRXnDvCiwDqvUJevVRY1qy4y4vlVKaShtbdfgPyG
# eeJ/YcSBONOc0DNTWbjMbL50qeIEC0lHSpL2rRYNVu3hsHzG8n5u5CQajPwx9Pzp
# sZIeFTNHyVF6kujI4Vo9NvO/zF8Ot44IMj4M7UX9Za4QwGf5B71x57OjaX53gxT4
# vzoHvEBXF9qCmHRgXBLbRomJfDn60alzv7dpCVQIuQ062nyIZKnsXxzuKFb0TjXW
# w6OFpG1bsjXpOo5DMHkysribxHor4Yz5dZjVyHANyKo0bSrAlVeihcaG5F74SZT8
# FtyHAW6IgLc5w/3D+R1obDhKZ21WMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
# tB1VM1izoXBm8qGCAtYwggI/AgEBMIIBAKGB2KSB1TCB0jELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxh
# bmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpE
# MDgyLTRCRkQtRUVCQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUAHDn/cz+3yRkIUCJfSbL3djnQEqaggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOoTpw0wIhgPMjAyNDA2MTIxMjQ4MTNaGA8yMDI0MDYxMzEyNDgxM1owdjA8Bgor
# BgEEAYRZCgQBMS4wLDAKAgUA6hOnDQIBADAJAgEAAgFGAgH/MAcCAQACAhEtMAoC
# BQDqFPiNAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEA
# AgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAPvJGnJSZLNo56HeJ
# 3cyRbGz7USSNr/JjnVlpx6BGU156d5HHnv3Q0iraNXqCwSPAz0HZDlmvJ0a1rrdd
# PIIVo5bRPk6TXA7juDsAGgkK1gt7DGttFGfBNm2QC/4NEdun8kT3Crg95ldiveHH
# Z6N/LIAiG9IDmQSptE5EQ4zM0GkxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAdzB4IzCX1hejgABAAAB3DANBglghkgBZQME
# AgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJ
# BDEiBCCeZ32vu558svtRUfrN3PYyNfbsMulAgd4FccDuLGCw0TCB+gYLKoZIhvcN
# AQkQAi8xgeowgecwgeQwgb0EIFOnF4pq2UQ/jLypnOO5YvQ67QirEQsOFfZMvKXE
# gg03MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHc
# weCMwl9YXo4AAQAAAdwwIgQgSfMVTLRnPEpnLjm71akIKYjbspPV12GU+ZBoRqI9
# 90gwDQYJKoZIhvcNAQELBQAEggIAQdJahjqeH/N7UetI68eySeFioeCEmzUe3MFo
# RbwHpp6i1YyKi4t11bEAResvQNdcXXyaQjI4/0JUGEFoYIGyTJeUYBwx2gH/boHh
# ny/rxEGrwy1jVDnLWiBEK3e8FG/A2INGQ2pKZTY1HFVGb2qOrbWsec9EaLp3ABs5
# G31oj3wt91rPWakl1jjwZBidbAYmWYGTmMUJFvEWcjly0QnwYJbAzvH6hw7BZVaq
# U9qnFMhF1KP5634ThQ5Ce3RNbP9wsmxLJ1h8Ef/IRsrEENd1MZY75r2D+IWU4dl6
# QOJ8+4AjKK219pnU8S4bjrKor5cL11RUHwVhYgw7A5cAVb9EORLv6DcZ1qIvVzMb
# I/Mo8U6mNuj+gZ+V6002HWy6JUdlzqcEpLQDVZfrWGpsvGybNZZ64t5ZecSGVMaT
# LAKcYcMHjORr4hmcYacCMz6mon+6zLx8jFjzbjnuXMgeoImXKu4s1vgLqkY9pRlU
# Ljz0pOX5T1bal+pe3kCJUjEfAFaL8t5TZ5EhPDyPSkeAlwCge5F/OMhRzY61kSL8
# SdgMGOIzHzDNI4qBCvOMYl2qG7MoovMDzhKr/3acu1K96iEPTLUm5BAnJEcetQpO
# Qem0gvdfXX2gUqwBKEUh0BbVnDQNymRzN2zOh8zeFfFhg1WqaQff3UuG6bIB2GIa
# kq5USjI=
# SIG # End signature block
