<#
.SYNOPSIS
   MSRD-Collect graphical user interface

.DESCRIPTION
   Module for the MSRD-Collect graphical user interface

.NOTES
   Author     : Robert Klemencz
   Requires   : MSRD-Collect.ps1
   Version    : See MSRD-Collect.ps1 version
   Feedback   : https://aka.ms/MSRD-Collect-Feedback
#>

#Config variables
$script:varsCore = @(,$true * 12); $script:vCore = $script:varsCore

$script:varsProfiles = @(,$true * 5)
$script:varsActivation = @(,$true * 3)
$script:varsMSRA = @(,$true * 6)
$script:varsSCard = @(,$true * 3)
$script:varsIME = @(,$true * 3)
$script:varsTeams = @(,$true * 4)
$script:varsMSIXAA = @(,$true * 1)
$script:varsHCI = @(,$true * 1)

$script:varsSystem = @(,$true * 12)
$script:varsAVDRDS = @(,$true * 11)
$script:varsInfra = @(,$true * 10)
$script:varsAD = @(,$true * 2)
$script:varsNET = @(,$true * 8)
$script:varsLogSec = @(,$true * 3)
$script:varsIssues = @(,$true * 2)
$script:varsOther = @(,$true * 4)

$script:varsNO = $false

$script:dumpProc = $False; $script:pidProc = ""
$script:traceNet = $False
$global:onlyDiag = $false; $global:msrdLiveDiag = $false
$global:msrdRemoteMode = $false

$msrdUserProfilesDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name ProfilesDirectory).ProfilesDirectory


#GUI

#prepare icons
$iconCount = 43
$icons = @()

for ($i = 0; $i -lt $iconCount; $i++) {
    $icons += [System.IconExtractor]::Extract("$global:msrdScriptpath\Config\MSRDC-Icons.dll", $i, $true)
}

$abouticon = $icons[0]; $alwaysontopicon = $icons[1]; $azureicon = $icons[2]; $configicon = $icons[3]
$consoleicon = $icons[4]; $diagreporticon = $icons[5]; $docsicon = $icons[6]; $downloadicon = $icons[7]
$exiticon = $icons[8]; $feedbackicon = $icons[9]; $foldericon = $icons[10]; $litemodeicon = $icons[12]
$machineavdicon = $icons[13]; $machinerdsicon = $icons[14]; $machinew365icon = $icons[15]; $maximizedicon = $icons[16]
$msrdcicon = $icons[17]; $readmeicon = $icons[18]; $rolesourceicon = $icons[19]; $roletargeticon = $icons[20]
$scenarioactivationicon = $icons[21]; $scenariocoreicon = $icons[22]; $scenariohciicon = $icons[23]; $scenarioimeicon = $icons[24]
$scenariolivediagicon = $icons[25]; $scenariomsixaaicon = $icons[26]; $scenariomsraicon = $icons[27]; $scenarionettraceicon = $icons[28]
$scenarioprocdumpicon = $icons[29]; $scenarioprofilesicon = $icons[30]; $scenariodiagonlyicon = $icons[31]; $scenarioscardicon = $icons[32]
$scenarioteamsicon = $icons[33]; $scheduledtaskicon = $icons[34]; $searchicon = $icons[35]; $soundassisticon = $icons[36]
$soundsystemicon = $icons[37]; $starticon = $icons[38]; $uilanguageicon = $icons[39]; $updateicon = $icons[40]
$usercontexticon = $icons[41]; $whatsnewicon = $icons[42]

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
        $xOffsetAR
    )

    # Define the dictionary for storing buttons
    $ButtonDictionary = @{}

    $xPos = 0
    $buttonHeight = 58
    $buttonVerticalOffset = 25  # Vertical offset for buttons

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
    $buttonArea.Height = $buttonHeight + $buttonVerticalOffset # Include offset in height

    # Calculate the label position to center it within the buttonArea below the buttons
    $label = New-Object Windows.Forms.Label
    $label.Text = $name
    $label.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
    $label.Width = $buttonArea.Width - 4
    $label.Height = $label.PreferredHeight
    $labelLocationX = ($buttonArea.Width - $label.Width) / 2
    $labelLocationY = $buttonHeight + 5 # Adjust vertical position to be just below the buttons
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
            msrdResetOutputBox
            $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False
            if ($script:pidProc) {
                msrdAddOutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
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
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
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
            msrdResetOutputBox
            $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False
            if ($script:pidProc) {
                msrdAddOutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
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
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
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
            msrdResetOutputBox
            $global:msrdAVD = $false; $global:msrdRDS = $false; $global:msrdW365 = $False
            if ($script:pidProc) {
                msrdAddOutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
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
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
            $global:liveDiagTab.Visible = $false
            $msrdPsBox.Visible = $true
            $global:msrdLiveDiag = $False
        }
    }
}

#initialize role settings
function msrdSetRole {
    param (
		[string]$Role, [switch]$LiveReset
	)

    if ($global:msrdAVD -or $global:msrdW365) { $msrdComputerBox.Enabled = $true }

    #source
    if ($Role -eq "Source") {
        msrdResetScenarioVariables
        $RoleDictionary["Target"].BackColor = "Transparent"

        if (-not $global:msrdSource -or $LiveReset) {
            $global:msrdSource = $true; $global:msrdTarget = $false
            $RoleDictionary["Source"].BackColor = "LightBlue"
            $RoleDictionary["Target"].Enabled = $false
            $ScenarioDictionary["MSRA"].Enabled = $true
            $ScenarioDictionary["SCard"].Enabled = $true
            $ScenarioDictionary["ProcDump"].Enabled = $true
            $ScenarioDictionary["NetTrace"].Enabled = $true
            $ScenarioDictionary["DiagOnly"].Enabled = $true
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $true
            $ScenarioDictionary["Core"].BackColor = "LightBlue"
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $true
            $RunMenuItem.Enabled = $true
        } else {
            $global:msrdSource = $false; $global:msrdTarget = $false
            $RoleDictionary["Source"].BackColor = "Transparent"
            $RoleDictionary["Target"].Enabled = $true
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            $ScenarioDictionary["Core"].BackColor = "Transparent"
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
            $RunMenuItem.Enabled = $false
        }

        $ScenarioDictionary["DiagOnly"].BackColor = "Transparent"
        $ScenarioDictionary["Core"].Enabled = $false
        $global:liveDiagTab.Visible = $false
        $msrdPsBox.Visible = $true
        $global:msrdLiveDiag = $False

    #target
    } elseif ($Role -eq "Target") {
        msrdResetScenarioVariables
        $RoleDictionary["Source"].BackColor = "Transparent"

        if (-not $global:msrdTarget -or $LiveReset) {
            $global:msrdSource = $false; $global:msrdTarget = $true
            $RoleDictionary["Target"].BackColor = "LightBlue"
            $RoleDictionary["Source"].Enabled = $false
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $true
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $true
            $ScenarioDictionary["Core"].BackColor = "LightBlue"
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $true
            $RunMenuItem.Enabled = $true

            if ($global:msrdRDS) {
                $ScenarioDictionary["Teams"].Enabled = $false
                $ScenarioDictionary["AppAttach"].Enabled = $false
                $ScenarioDictionary["HCI"].Enabled = $false
            } elseif ($global:msrdW365) {
                $ScenarioDictionary["AppAttach"].Enabled = $false
                $ScenarioDictionary["HCI"].Enabled = $false
            }
        } else {
            $global:msrdSource = $false; $global:msrdTarget = $false
            $RoleDictionary["Target"].BackColor = "Transparent"
            $RoleDictionary["Source"].Enabled = $true
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            $ScenarioDictionary["Core"].BackColor = "Transparent"
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
            $RunMenuItem.Enabled = $false
        }

        $ScenarioDictionary["Core"].Enabled = $false
        $global:liveDiagTab.Visible = $false
        $msrdPsBox.Visible = $true
        $global:msrdLiveDiag = $False
    }
}


#initialize scenario settings
function msrdSetScenario {
    param ( [array]$Scenario, $Status )

    foreach ($scen in $scenario) {
        if ($scen -eq "AppAttach") {
            $variableName = "vMSIXAA"
        } else {
            $variableName = "v$scen"
        }
        if ($Status) {
            $ScenarioDictionary["$scen"].BackColor = "LightBlue"
        } else {
            $ScenarioDictionary["$scen"].BackColor = "Transparent"
        }
        Set-Variable -Name $variableName -Value $Status -Scope Script
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
        msrdAddOutputBoxLine "Previous PID selection reset - no process dump will be generated`n" "Yellow"
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
    $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
    $global:liveDiagTab.Visible = $false
    $msrdPsBox.Visible = $true
    $global:msrdLiveDiag = $False
}

#reset scenario variables
function msrdResetScenarioVariables {
    $script:vCore = $script:varsCore
    $script:vProfiles = $script:varsNO
    $script:vActivation = $script:varsNO
    $script:vMSRA = $script:varsNO
    $script:vSCard = $script:varsNO
    $script:vIME = $script:varsNO
    $script:vTeams = $script:varsNO
    $script:vMSIXAA = $script:varsNO
    $script:vHCI = $script:varsNO
    $script:dumpProc = $False
    $script:traceNet = $False
    $global:onlyDiag = $False
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
        $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $true
        $msrdPsBox.Visible = $true
        $global:liveDiagTab.Visible = $false
        Remove-Module MSRDC-Diagnostics
    }
}

Function msrdAddOutputBoxLine {
    param ([string[]]$Message, $Color, $switchColor, [switch]$noNewLine, $outputFile, $addAssist)

    if ($Color) { $txtColor = $Color } else { $txtColor = "White" }
    if ($switchColor) { $swColor = $switchColor } else { $swColor = "Yellow" }

    if ($global:msrdLiveDiag) {
        if ($global:msrdLiveDiagSystem) {
            $psBoxMain = $global:psBoxLiveDiagSystem
        } elseif ($global:msrdLiveDiagAVDRDS) {
            $psBoxMain = $global:psBoxLiveDiagAVDRDS
        } elseif ($global:msrdLiveDiagAVDInfra) {
            $psBoxMain = $global:psBoxLiveDiagAVDInfra
        } elseif ($global:msrdLiveDiagAD) {
            $psBoxMain = $global:psBoxLiveDiagAD
        } elseif ($global:msrdLiveDiagNet) {
            $psBoxMain = $global:psBoxLiveDiagNet
        } elseif ($global:msrdLiveDiagLogonSec) {
            $psBoxMain = $global:psBoxLiveDiagLogonSec
        } elseif ($global:msrdLiveDiagIssues) {
            $psBoxMain = $global:psBoxLiveDiagIssues
        } elseif ($global:msrdLiveDiagOther) {
            $psBoxMain = $global:psBoxLiveDiagOther
        }
    } else {
        $psBoxMain = $msrdPsBox
        if ($global:msrdLangID -eq "AR") { $psBoxMain.RightToLeft = "Yes" } else { $psBoxMain.RightToLeft = "No" }
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
                "Adım \d:", "Adım \d+[a-zA-Z]:", #TR
                "步骤 \d:", "步骤 \d+[a-zA-Z]:" #CN
            )

            # Find matches of the pattern in the line
            $linematches = foreach ($pattern in $patterns) {
                [regex]::Matches($line, $pattern)
            }

            # Set the default color for the entire line
            $psBoxMain.SelectionStart = $psBoxMain.TextLength
            $psBoxMain.SelectionLength = 0
            $psBoxMain.SelectionColor = $txtColor
            if (($global:msrdSilentMode -eq 1) -and ($global:msrdCollecting -or $global:msrdDiagnosing) -and (-not $global:msrdLiveDiag) -and ($global:msrdAudioAssistMode -eq 0)) {
                if ($txtColor -eq "Magenta") {
                    $psBoxMain.AppendText("e")
                } else {
                    $psBoxMain.AppendText(".")
                }
            } else {
                $psBoxMain.AppendText($line)
            }

            # Set the color for each matched pattern
            foreach ($linematch in $linematches) {
                $startIndex = $linematch.Index
                $length = $linematch.Length
                $psBoxMain.Select($psBoxMain.TextLength - $line.Length + $startIndex, $length)
                $psBoxMain.SelectionColor = $swColor
                $psBoxMain.SelectionLength = 0
            }
        } else {
            $psBoxMain.SelectionStart = $psBoxMain.TextLength
            $psBoxMain.SelectionLength = 0
            $psBoxMain.SelectionColor = $txtColor
            if (($global:msrdSilentMode -eq 1) -and ($global:msrdCollecting -or $global:msrdDiagnosing) -and (-not $global:msrdLiveDiag) -and ($global:msrdAudioAssistMode -eq 0)) {
                if ($txtColor -eq "Magenta") {
                    $psBoxMain.AppendText("e")
                } else {
                    $psBoxMain.AppendText(".")
                }
            } else {
                $psBoxMain.AppendText($line)
            }
        }

        if ($addAssist) {
            msrdLogMessageAssistMode $line
        }

        $psBoxMain.SelectionStart = $psBoxMain.TextLength
        $psBoxMain.ScrollToCaret()
        $psBoxMain.Refresh()
    }
}

#display the initial how to steps
function msrdInitHowTo {

    # How To Steps
    msrdAddOutputBoxLine -Message ("$(msrdGetLocalizedText 'howtouse')`n") -switchColor "Cyan"
    $global:msrdPsBox.ReadOnly = $true
}

#reset the output box
function msrdResetOutputBox {
    param ( [switch]$noInit = $false )

    #SwitchLiveDiagToPsBox
    msrdToggleFontSizeChecked $global:msrdPsBoxFont

    if (-not $global:msrdLiveDiag) {
        $global:msrdPsBox.Clear()
        if ($global:msrdLangID -eq "JP") {
            $global:msrdPsBox.Font = New-Object System.Drawing.Font("MS Gothic", $global:msrdPsBoxFont)
        } else {
		    $global:msrdPsBox.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        }

        if (-not $noInit) {
            msrdInitScript -Type GUI
            msrdInitHowTo
        }
        $global:msrdPsBox.Refresh()
        $global:msrdPsBox.ScrollToCaret()
    } else {
        $global:psBoxLiveDiagSystem.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        $global:psBoxLiveDiagAVDRDS.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        $global:psBoxLiveDiagAVDInfra.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        $global:psBoxLiveDiagAD.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        $global:psBoxLiveDiagNet.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        $global:psBoxLiveDiagLogonSec.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        $global:psBoxLiveDiagIssues.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
        $global:psBoxLiveDiagOther.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
    }
}

#find folder for output location
function msrdFindFolder {
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
            msrdAddOutputBoxLine "$(msrdGetLocalizedText "location2") $global:msrdLogRoot`n" -Color Yellow
        } elseif ($AppliesTo -eq "ScheduledTask") {
            $outputLocationTextBox.Text = $browse.SelectedPath
        }
    }
    else {
        if ($AppliesTo -eq "Script") {
            msrdAddOutputBoxLine "$(msrdGetLocalizedText "location2") $global:msrdLogRoot`n" -Color Yellow
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
function msrdRunRemoteScript {
    param (
        [string]$RemoteComputer
    )

    try {
        # Create a PSSession to the remote computer
        $PSSession = try {
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'remotePSinitLocalCred') $RemoteComputer" -Color Yellow
            New-PSSession -ComputerName $RemoteComputer -ErrorAction Stop -EnableNetworkAccess
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'remotePSinitLocalCredSuccess') $RemoteComputer" -Color Lightgreen

        } catch [System.Management.Automation.RuntimeException] {
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'remotePSinitLocalCredFail') $RemoteComputer" -Color Yellow
                if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }

                try {
                    New-PSSession -ComputerName $RemoteComputer -Credential (Get-Credential -Message "$(msrdGetLocalizedText 'remotePSenterCred') $RemoteComputer" -Verbose $null) -ErrorAction Stop
                    msrdAddOutputBoxLine "$(msrdGetLocalizedText 'remotePSinitProvCredSuccess') $RemoteComputer" -Color Lightgreen
                } catch {
                    $failedCommand = $_.InvocationInfo.Line.TrimStart()
			        $errorMessage = $_.Exception.Message.TrimStart()
			        msrdAddOutputBoxLine -Message "Error in $failedCommand $errorMessage`n" -Color Magenta
                    if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
			        return
                }
		} catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
			$errorMessage = $_.Exception.Message.TrimStart()
			msrdAddOutputBoxLine -Message "Error in $failedCommand $errorMessage`n" -Color Magenta
            if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
			return
        }

        #copying script files to remote computer
        msrdAddOutputBoxLine "$(msrdGetLocalizedText "remotePScopy") $RemoteComputer" -Color Yellow

        $sourcePath = $global:msrdScriptpath
        $destinationPath = "\\$RemoteComputer\C`$\MS_DATA\MSRD-Collect"

        # Check if the destination directory exists, and create it if necessary
        if (-not (Test-Path -Path $destinationPath -PathType Container)) {
            New-Item -ItemType Directory -Path $destinationPath -Force
        } else {
            msrdAddOutputBoxLine "'$destinationPath' $(msrdGetLocalizedText 'remotePScopyExists') $RemoteComputer" -Color Yellow
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
            { $script:vCore -ne $script:varsNO }       { $dynamicParameters += @{ Core = $true } }
            { $script:vProfiles -ne $script:varsNO }   { $dynamicParameters += @{ Profiles = $true } }
            { $script:vActivation -ne $script:varsNO } { $dynamicParameters += @{ Activation = $true } }
            { $script:vMSRA -ne $script:varsNO }       { $dynamicParameters += @{ MSRA = $true } }
            { $script:vSCard -ne $script:varsNO }      { $dynamicParameters += @{ SCard = $true } }
            { $script:vIME -ne $script:varsNO }        { $dynamicParameters += @{ IME = $true } }
            { $script:vTeams -ne $script:varsNO }      { $dynamicParameters += @{ Teams = $true } }
            { $script:vMSIXAA -ne $script:varsNO }     { $dynamicParameters += @{ AppAttach = $true } }
            { $script:vHCI -ne $script:varsNO }        { $dynamicParameters += @{ HCI = $true } }
            { $script:dumpProc -and $script:pidProc -ne "" } { $dynamicParameters += @{ DumpPID = $script:pidProc } }
            { $script:traceNet }                { $dynamicParameters += @{ NetTrace = $true } }
            { $global:onlyDiag }                { $dynamicParameters += @{ DiagOnly = $true } }
        }

        $parametersString = $dynamicParameters | ConvertTo-Json

        # Run the script remotely and capture the output
        msrdAddOutputBoxLine "`n$(msrdGetLocalizedText 'remotePSlaunch1')`n$(msrdGetLocalizedText 'initvalues1c') $ScriptPath $parametersString`n" -Color Yellow
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
        msrdAddOutputBoxLine "`n$(msrdGetLocalizedText 'remotePScomplete') $RemoteComputer`n" -Color Yellow
        Remove-PSSession -Session $PSSession

        # Open File Explorer on the remote machine
        Invoke-Command -ScriptBlock {
            Start-Process explorer.exe -ArgumentList "\\$RemoteComputer\C`$\MS_DATA\"
        }

    } catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        $errorMessage = $_.Exception.Message.TrimStart()
        msrdAddOutputBoxLine -Message "`nError in $failedCommand $errorMessage`n" -Color Magenta
        if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
    }

}

#action on pressing the start button
function msrdStartBtnCollect {
    param (
        $RemoteComputer
    )

    msrdResetOutputBox -noInit

    if ($global:msrdRemoteMode) {
        $global:msrdStatusBarLabel.Text = "$(msrdGetLocalizedText 'remoteModeRunning')"
        msrdAddOutputBoxLine -Message "$(msrdGetLocalizedText 'remoteMode')" -Color "Yellow"
    }
    # Split the string into an array of computer names and trim spaces
    $computerArray = $RemoteComputer -split ';' | ForEach-Object { $_.Trim() }

    foreach ($target in $computerArray) {
        if ($target -ne $env:computerName) {

            if (($target.Trim() -eq "") -or ($target.Trim() -like "* *") -or ($target -like "*,*")) {
                msrdAddOutputBoxLine -Message "`n$(msrdGetLocalizedText 'remoteInvalidComp') $target`n" -Color Magenta
                if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
                continue
            }

            # Check if the computer is reachable
            if (Test-Connection -ComputerName $target -Count 1 -Quiet) {
                msrdAddOutputBoxLine -Message "`n$(msrdGetLocalizedText 'remoteReach1') ($target) $(msrdGetLocalizedText 'remoteReach2')`n" -Color Lightgreen

                msrdRunRemoteScript -RemoteComputer $target

            } else {
                msrdAddOutputBoxLine -Message "`n$(msrdGetLocalizedText 'remoteReach1') ($target) $(msrdGetLocalizedText 'remoteReach3')`n" -Color Magenta
                if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
            }

        } else {
            if ($script:vTeams -eq $script:varsTeams) {
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
                $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Text = msrdGetLocalizedText "Running"
                $ActionDictionary["$(msrdGetLocalizedText 'Start')"].BackColor = "LightBlue"

                $global:msrdProgbar.Visible = $true

                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues1a) $global:msrdVersion $(msrdGetLocalizedText initvalues1b) $global:msrdScriptpath ($global:msrdAdminlevel)"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues1c) $global:msrdCmdLine"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues2)"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues3) $global:msrdLogRoot"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText initvalues4) $global:msrdUserprof`n"
                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText dpidtext3) $script:pidProc"

                $selectedOptions = @()

                $options = @(
                    $machineDictionary["AVD"], $machineDictionary["RDS"], $machineDictionary["W365"],
                    $RoleDictionary["Source"], $RoleDictionary["Target"],
                    $ScenarioDictionary["Core"], $ScenarioDictionary["Profiles"], $ScenarioDictionary["Activation"], $ScenarioDictionary["MSRA"], $ScenarioDictionary["SCard"],
                    $ScenarioDictionary["IME"], $ScenarioDictionary["Teams"], $ScenarioDictionary["AppAttach"], $ScenarioDictionary["HCI"], $ScenarioDictionary["ProcDump"],
                    $ScenarioDictionary["NetTrace"], $ScenarioDictionary["DiagOnly"]
                )

                $selectedOptions = $options |
                    Where-Object { $_.BackColor -eq "LightBlue" } |
                    ForEach-Object { $_.Text }

                $selectedOptionsString = $selectedOptions -join ", "

                msrdLogMessage $LogLevel.InfoLogFileOnly "$(msrdGetLocalizedText 'selectedParam') $selectedOptionsString`n"

                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor

                if (-not $global:onlyDiag) {
                    if ($script:vProfiles -eq $true) { $script:vProfiles = $script:varsProfiles }
                    if ($script:vActivation -eq $true) { $script:vActivation = $script:varsActivation }
                    if ($script:vMSRA -eq $true) { $script:vMSRA = $script:varsMSRA }
                    if ($script:vSCard -eq $true) { $script:vSCard = $script:varsSCard }
                    if ($script:vIME -eq $true) { $script:vIME = $script:varsIME }
                    if ($script:vTeams -eq $true) { $script:vTeams = $script:varsTeams }
                    if ($script:vMSIXAA -eq $true) { $script:vMSIXAA = $script:varsMSIXAA }
                    if ($script:vHCI -eq $true) { $script:vHCI = $script:varsHCI }

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
                if ($allVars -notcontains $true) {
                    msrdLogMessage $LogLevel.Info -Message "$(msrdGetLocalizedText 'noDiagmsg')`n" -Color "Cyan"
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
                $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Text = msrdGetLocalizedText "Start"
                $ActionDictionary["$(msrdGetLocalizedText 'Start')"].BackColor = "Transparent"

                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default

                $global:msrdProgbar.Visible = $false
            }
        }
    }

    if ($global:msrdRemoteMode) {
        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
        msrdAddOutputBoxLine "$(msrdGetLocalizedText 'localMode')`n" -Color "Yellow"
    }
}


#main GUI function for easier external reference
Function msrdAVDCollectGUI {
    param ( $ShowConsole, $MaximizeWindow )

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
                $global:msrdRemoteMode = $true
				msrdStartBtnCollect -RemoteComputer $msrdComputerBox.Text
                $global:msrdRemoteMode = $false
			}
        }
    })

    msrdCreateMenuItem -Menu $FileMenu -Text "---" | Out-Null

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
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "UILiteMode" -value 1
            If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
            If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
            if ($global:msrdGUI) { $global:msrdForm.Close() } else { Exit }
        } catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        }
    })

    msrdCreateMenuItem -Menu $FileMenu -Text "---" | Out-Null

    $ExitMenuItem = msrdCreateMenuItem -Menu $FileMenu -Text "ExitMenu" -Icon $exiticon
    $ExitMenuItem.Add_Click({
        If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
        If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
        $global:msrdForm.Close()
    })
    #endregion File menu

    #region View menu
    $ViewMenu = msrdCreateMenu -Text "ViewMenu"

    #show console window
    $ConsoleMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "HideConsole" -Icon $consoleicon
    $ConsoleMenuItem.CheckOnClick = $True
    $ConsoleMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($ConsoleMenuItem.Checked) { msrdStartShowConsole; $ConsoleMenuItem.Checked = $true } else { msrdStartHideConsole; $ConsoleMenuItem.Checked = $false }
    })

    #start maximized
    $MaximizeMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "MaximizeWindow" -Icon $maximizedicon
    $MaximizeMenuItem.CheckOnClick = $True
    $MaximizeMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($MaximizeMenuItem.Checked) {
            $global:msrdForm.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'openMaximized')`n"
            $MaximizeMenuItem.Checked = $true
            if (!($nocfg)) {
                msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "MaximizeWindow" -value 1
            }
        } else {
            $global:msrdForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'openWindowed')`n"
            $MaximizeMenuItem.Checked = $false
            if (!($nocfg)) {
                msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "MaximizeWindow" -value 0
            }
        }
    })

    #always on top
    $OnTopMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "AlwaysOnTop" -Icon $alwaysontopicon
    $OnTopMenuItem.CheckOnClick = $True
    $OnTopMenuItem.Checked = $false
    $OnTopMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($OnTopMenuItem.Checked) {
            $global:msrdForm.TopMost = $true
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'ontop')`n"
        } else {
            $global:msrdForm.TopMost = $false
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'ontopNot')`n"
        }
    })

    #silent mode
    $SilentModeMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "SilentMode"
    $SilentModeMenuItem.CheckOnClick = $True
    $SilentModeMenuItem.Checked = $false
    $SilentModeMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($SilentModeMenuItem.Checked) {
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "SilentMode" -value 1
            $global:msrdSilentMode = 1
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'SilentModeOn')`n"
        } else {
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "SilentMode" -value 0
            $global:msrdSilentMode = 0
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'SilentModeOff')`n"
        }
    })

    msrdCreateMenuItem -Menu $ViewMenu -Text "---" | Out-Null

    #font size
    $FontSizeMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "FontSize" -Icon ([System.IconExtractor]::Extract("imageres.dll", 118, $true))
    $FontSize10MenuItem = msrdCreateMenuItem -Menu $FontSizeMenuItem -Text "10" -Icon ([System.IconExtractor]::Extract("imageres.dll", 118, $true)) -SkipLocalizedText
    $FontSize10MenuItem.CheckOnClick = $True
    $FontSize12MenuItem = msrdCreateMenuItem -Menu $FontSizeMenuItem -Text "12" -Icon ([System.IconExtractor]::Extract("imageres.dll", 118, $true)) -SkipLocalizedText
    $FontSize12MenuItem.CheckOnClick = $True
    $FontSize14MenuItem = msrdCreateMenuItem -Menu $FontSizeMenuItem -Text "14" -Icon ([System.IconExtractor]::Extract("imageres.dll", 118, $true)) -SkipLocalizedText
    $FontSize14MenuItem.CheckOnClick = $True
    $FontSize16MenuItem = msrdCreateMenuItem -Menu $FontSizeMenuItem -Text "16" -Icon ([System.IconExtractor]::Extract("imageres.dll", 118, $true)) -SkipLocalizedText
    $FontSize16MenuItem.CheckOnClick = $True

    function msrdToggleFontSizeChecked($size) {

        $fontBtnName = "FontSize" + $size + "MenuItem"
        $fontbtn = Get-Variable -Name $fontBtnName -ValueOnly

        $fontList = @($FontSize10MenuItem, $FontSize12MenuItem, $FontSize14MenuItem, $FontSize16MenuItem)

        foreach ($fontsize in $fontList) {
            if ($fontsize -ne $fontbtn) { $fontsize.Checked = $false }
        }

        $selectedFontOption = $fontList | Where-Object { $_ -eq $fontbtn }
        $selectedFontOption.Checked = $true
    }

    $FontSize10MenuItem.Add_Click({
        $global:msrdPsBoxFont = 10
        msrdResetOutputBox
        msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "PsBoxFont" -value 10
    })
    $FontSize12MenuItem.Add_Click({
        $global:msrdPsBoxFont = 12
        msrdResetOutputBox
        msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "PsBoxFont" -value 12
    })
    $FontSize14MenuItem.Add_Click({
        $global:msrdPsBoxFont = 14
        msrdResetOutputBox
        msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "PsBoxFont" -value 14
    })
    $FontSize16MenuItem.Add_Click({
        $global:msrdPsBoxFont = 16
        msrdResetOutputBox
        msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "PsBoxFont" -value 16
    })


    #update text on menu items based on selected language
    Function msrdRefreshUILang {
        Param ($id, [switch]$restart)

        SwitchLiveDiagToPsBox
        $global:msrdOldLangID = $global:msrdLangID
        $global:msrdLangID = $id
        msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "UILanguage" -value $id

        $langName = "UILanguage$id"
        $lang = Get-Variable -Name $langName -ValueOnly
        $lang.Checked = $true

        if ($restart) { msrdRestart }
    }

    #ui language
    $UILanguageMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "UILang" -Icon $uilanguageicon

    $UILanguageAR = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "ara" -Icon $uilanguageicon
    $UILanguageAR.CheckOnClick = $True
    $UILanguageAR.Add_Click({ msrdRefreshUILang -id "AR" -restart $true })

    $UILanguageCN = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "chi" -Icon $uilanguageicon
    $UILanguageCN.CheckOnClick = $True
    $UILanguageCN.Add_Click({ msrdRefreshUILang -id "CN" -restart $true })

    $UILanguageCS = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "cze" -Icon $uilanguageicon
    $UILanguageCS.CheckOnClick = $True
    $UILanguageCS.Add_Click({ msrdRefreshUILang -id "CS" -restart $true })

    $UILanguageNL = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "dut" -Icon $uilanguageicon
    $UILanguageNL.CheckOnClick = $True
    $UILanguageNL.Add_Click({ msrdRefreshUILang -id "NL" -restart $true })

    $UILanguageEN = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "eng" -Icon $uilanguageicon
    $UILanguageEN.CheckOnClick = $True
    $UILanguageEN.Add_Click({ msrdRefreshUILang -id "EN" -restart $true })

    $UILanguageFR = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "fre" -Icon $uilanguageicon
    $UILanguageFR.CheckOnClick = $True
    $UILanguageFR.Add_Click({ msrdRefreshUILang -id "FR" -restart $true })

    $UILanguageDE = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "ger" -Icon $uilanguageicon
    $UILanguageDE.CheckOnClick = $True
    $UILanguageDE.Add_Click({ msrdRefreshUILang -id "DE" -restart $true })

    $UILanguageHU = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "hun" -Icon $uilanguageicon
    $UILanguageHU.CheckOnClick = $True
    $UILanguageHU.Add_Click({ msrdRefreshUILang -id "HU" -restart $true })

    $UILanguageIT = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "ita" -Icon $uilanguageicon
    $UILanguageIT.CheckOnClick = $True
    $UILanguageIT.Add_Click({ msrdRefreshUILang -id "IT" -restart $true })

    $UILanguageJP = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "jpn" -Icon $uilanguageicon
    $UILanguageJP.CheckOnClick = $True
    $UILanguageJP.Add_Click({ msrdRefreshUILang -id "JP" -restart $true })

    $UILanguagePT = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "por" -Icon $uilanguageicon
    $UILanguagePT.CheckOnClick = $True
    $UILanguagePT.Add_Click({ msrdRefreshUILang -id "PT" -restart $true })

    $UILanguageRO = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "rom" -Icon $uilanguageicon
    $UILanguageRO.CheckOnClick = $True
    $UILanguageRO.Add_Click({ msrdRefreshUILang -id "RO" -restart $true })

    $UILanguageES = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "spa" -Icon $uilanguageicon
    $UILanguageES.CheckOnClick = $True
    $UILanguageES.Add_Click({ msrdRefreshUILang -id "ES" -restart $true })

    $UILanguageTR = msrdCreateMenuItem -Menu $UILanguageMenuItem -Text "tur" -Icon $uilanguageicon
    $UILanguageTR.CheckOnClick = $True
    $UILanguageTR.Add_Click({ msrdRefreshUILang -id "TR" -restart $true })

    msrdCreateMenuItem -Menu $ViewMenu -Text "---" | Out-Null

    #open output location
    $ResultsMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "OutputLocation" -Icon $foldericon
    $ResultsMenuItem.Add_Click({
        If (Test-Path $global:msrdLogRoot) {
            explorer $global:msrdLogRoot
        } else {
            msrdAddOutputBoxLine "`n$(msrdGetLocalizedText 'outputNotFound')" "Yellow"
        }
    })

    #diagnostic reports
    $ReportsMenuItem = msrdCreateMenuItem -Menu $ViewMenu -Text "DiagReports" -Icon $diagreporticon

    function addReportItems {

        msrdAddOutputBoxLine "$(msrdGetLocalizedText 'outputLoc1') ($global:msrdLogRoot)." -Color "Yellow"
        if (Test-Path $global:msrdLogRoot -PathType Container) {
            $RepFiles = Get-ChildItem $global:msrdLogRoot -Recurse -Include *MSRD-Diag.html | ForEach-Object { $_.FullName }
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
                                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'outputLoc2')`n" -Color "Red"
                            }
                        })
                        $RepMenuItems += $RepMenuItem
                        $RepMenuItems | Sort-Object -Descending Text | ForEach-Object { [void] $ReportsMenuItem.DropDownItems.Add($_) }
                    }
                }

                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'outputLoc3')`n" -Color "Lightgreen"
            } else {
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'outputLoc4') ($global:msrdLogRoot).`n$(msrdGetLocalizedText 'outputLoc5')`n" -Color "Yellow"
            }
        } else {
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'outputLoc6') ($global:msrdLogRoot).`n$(msrdGetLocalizedText 'outputLoc5')`n" -Color "Yellow"
        }
    }

    $ReportsMenuItem.Add_MouseEnter({
        if ($global:msrdLiveDiag) {
            if ($global:msrdTarget) { msrdSetRole -Role Target -LiveReset } else { msrdSetRole -Role Source -LiveReset }
		    $global:msrdLiveDiag = $False

            if ($global:msrdRDS) {
                $msrdComputerBox.Enabled = $false
                $msrdComputerBox.Text = $env:computerName
            } else {
                $msrdComputerBox.Enabled = $true
                $msrdComputerBox.Text = $env:computerName
            }
        }

        $ReportsMenuItem.DropDownItems.Clear()
        addReportItems
    })

    #endregion View menu

    #region Tools menu
    $ToolsMenu = msrdCreateMenu -Text "ToolsMenu"

    $OutputMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "SetOutputLocation" -Icon $foldericon
    $OutputMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        msrdFindFolder -DefaultFolder "C:\" -AppliesTo "Script"
    })

    $UserContextMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "SetUserContext" -Icon $usercontexticon
    $UserContextMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        $userContextForm.ShowDialog() | Out-Null
    })

    msrdCreateMenuItem -Menu $ToolsMenu -Text "---" | Out-Null

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

    msrdCreateMenuItem -Menu $ToolsMenu -Text "---" | Out-Null

    $ConfigSchedTaskMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "ConfigSchedTask" -Icon $scheduledtaskicon
    $ConfigSchedTaskMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        $staskForm.ShowDialog() | Out-Null
    })

    $OpenTaskSchedMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "OpenTaskSched" -Icon $scheduledtaskicon
    $OpenTaskSchedMenuItem.Add_Click({
        Start-Process -FilePath "taskschd.msc"
    })

    msrdCreateMenuItem -Menu $ToolsMenu -Text "---" | Out-Null

    $global:AutoVerCheckMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "AutoVerCheck" -Icon $updateicon
    $global:AutoVerCheckMenuItem.CheckOnClick = $True
    if ($global:msrdAutoVerCheck -eq 1) {
        $global:AutoVerCheckMenuItem.Checked = $True
    }
    $global:AutoVerCheckMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($global:AutoVerCheckMenuItem.Checked) {
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "AutomaticVersionCheck" -value 1
            $global:msrdAutoVerCheck = 1
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'autoUpdate') $(msrdGetLocalizedText 'enabled')`n"
        } else {
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "AutomaticVersionCheck" -value 0
            $global:msrdAutoVerCheck = 0
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'autoUpdate') $(msrdGetLocalizedText 'disabled')`n"
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
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "PlaySounds" -value 1
            $global:msrdPlaySounds = 1
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'playSnd') $(msrdGetLocalizedText 'enabled')`n"
        } else {
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "PlaySounds" -value 0
            $global:msrdPlaySounds = 0
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'playSnd') $(msrdGetLocalizedText 'disabled')`n"
        }
    })

    $AssistModeMenuItem = msrdCreateMenuItem -Menu $ToolsMenu -Text "AudioAssistMode" -Icon $soundassisticon
    $AssistModeMenuItem.CheckOnClick = $True
    if ($global:msrdAudioAssistMode -eq 1) {
        $AssistModeMenuItem.Checked = $True
    }
    $AssistModeMenuItem.Add_Click({
        SwitchLiveDiagToPsBox
        if ($AssistModeMenuItem.Checked) {
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "AudioAssistMode" -value 1
            $global:msrdAudioAssistMode = 1
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'aaMode') $(msrdGetLocalizedText 'enabled')`n"
        } else {
            msrdUpdateConfigFile -configFile "Config\MSRDC-Config.cfg" -key "AudioAssistMode" -value 0
            $global:msrdAudioAssistMode = 0
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'aaMode') $(msrdGetLocalizedText 'disabled')`n"
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
        $readmepath = (Get-Item .).FullName + "\MSRD-Collect-ReleaseNotes.txt"
        notepad $readmepath
    })

    #download menu
    $downloadicon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\Config\MSRDC-Icons.dll", 7, $true))

    $DownloadMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "Download" -Icon $downloadicon
    $DownloadMenuItemMSRDC = msrdCreateMenuItem -Menu $DownloadMenuItem -Text "DownloadMSRDC" -Icon $downloadicon
    $DownloadMenuItemMSRDC.Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/MSRD-Collect") })
    $DownloadMenuItemRDSTr = msrdCreateMenuItem -Menu $DownloadMenuItem -Text "DownloadRDSTracing" -Icon $downloadicon
    $DownloadMenuItemRDSTr.Add_Click({ [System.Diagnostics.Process]::start("http://aka.ms/RDSTracing") })
    $DownloadMenuItemRDSTr = msrdCreateMenuItem -Menu $DownloadMenuItem -Text "DownloadSaRA" -Icon $downloadicon
    $DownloadMenuItemRDSTr.Add_Click({ [System.Diagnostics.Process]::start("https://diagnostics.outlook.com/") })
    $DownloadMenuItemTSS = msrdCreateMenuItem -Menu $DownloadMenuItem -Text "DownloadTSS" -Icon $downloadicon
    $DownloadMenuItemTSS.Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/getTSS") })

    msrdCreateMenuItem -Menu $HelpMenu -Text "---" | Out-Null

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

    $AzureMenuItemAVDExpEstimator = msrdCreateMenuItem -Menu $AzureMenuItem -Text "AVDExpEstimator" -Icon $azureicon
    $AzureMenuItemAVDExpEstimator.Add_Click({ Start-Process https://azure.microsoft.com/en-gb/products/virtual-desktop/assessment })

    msrdCreateMenuItem -Menu $HelpMenu -Text "---" | Out-Null

    #docs submenu
    $docsicon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\Config\MSRDC-Icons.dll", 6, $true))

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

    msrdCreateMenuItem -Menu $HelpMenu -Text "---" | Out-Null

    $FeedbackMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "FeedbackForm" -Icon $feedbackicon
    $FeedbackMenuItem.Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/MSRD-Collect-Feedback") })

    msrdCreateMenuItem -Menu $HelpMenu -Text "---" | Out-Null

    $AboutMenuItem = msrdCreateMenuItem -Menu $HelpMenu -Text "About" -Icon $abouticon
    $AboutMenuItem.Add_Click({
    [Windows.Forms.MessageBox]::Show("Microsoft Remote Desktop Collect
Microsoft CSS Data Collection and Diagnostics script for AVD, RDS, W365`n
Version:
        $msrdVersion`n
Author:
        Robert Klemencz (Microsoft CSS)`n
Contact:
        https://aka.ms/MSRD-Collect-Feedback", "About", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
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
        msrdAddOutputBoxLine "$(msrdGetLocalizedText 'presetLoaded1'): " -Color Cyan -noNewLine
        msrdAddOutputBoxLine "$txt"
        msrdAddOutputBoxLine "$(msrdGetLocalizedText 'contextLabel'): " -Color Cyan -noNewLine
        msrdAddOutputBoxLine "$Machine"
        msrdAddOutputBoxLine "$(msrdGetLocalizedText 'roleLabel'): " -Color Cyan -noNewLine
        msrdAddOutputBoxLine "$Role"
        msrdAddOutputBoxLine "$(msrdGetLocalizedText 'scenarioLabel'): " -Color Cyan -noNewLine
        msrdAddOutputBoxLine "$Scenario"
        msrdAddOutputBoxLine "$(msrdGetLocalizedText 'presetLoaded2')`n" -Color Yellow
    }

    $PresetsMenu = msrdCreateMenu -Text "PresetsMenu"

    #avd
    $avdPresetMenuItem = msrdCreateMenuItem -Menu $PresetsMenu -Text "AVD" -Icon $machineavdicon

    $avdPresetMsixaaMenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetMsixaa" -Icon $machineavdicon #msixaa target
    $avdPresetMsixaaMenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core", "Profiles", "AppAttach") -Text "presetMsixaa" })

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

    $avdPresetLic3MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetLic3" -Icon $machineavdicon #rd licensing target
    $avdPresetLic3MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core") -Text "presetLic3" })

    $avdPresetMSRA1MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetMSRA1" -Icon $machineavdicon #MSRA, QA or RH issues / source
    $avdPresetMSRA1MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Source -Scenario @("Core", "MSRA") -Text "presetMSRA1" })

    $avdPresetMSRA2MenuItem = msrdCreateMenuItem -Menu $avdPresetMenuItem -Text "presetMSRA2" -Icon $machineavdicon #MSRA, QA or RH issues / target
    $avdPresetMSRA2MenuItem.Add_Click({ msrdSetPreset -Machine AVD -Role Target -Scenario @("Core", "MSRA") -Text "presetMSRA2" })

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

    $rdsPresetMSRA1MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetMSRA1" -Icon $machinerdsicon #MSRA, QA or RH issues / source
    $rdsPresetMSRA1MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Source -Scenario @("Core", "MSRA") -Text "presetMSRA1" })

    $rdsPresetMSRA2MenuItem = msrdCreateMenuItem -Menu $rdsPresetMenuItem -Text "presetMSRA2" -Icon $machinerdsicon #MSRA, QA or RH issues / target
    $rdsPresetMSRA2MenuItem.Add_Click({ msrdSetPreset -Machine RDS -Role Target -Scenario @("Core", "MSRA") -Text "presetMSRA2" })

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

    $w365PresetMSRA1MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetMSRA1" -Icon $machinew365icon #MSRA, QA or RH issues / source
    $w365PresetMSRA1MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Source -Scenario @("Core", "MSRA") -Text "presetMSRA1" })

    $w365PresetMSRA2MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetMSRA2" -Icon $machinew365icon #MSRA, QA or RH issues / target
    $w365PresetMSRA2MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Target -Scenario @("Core", "MSRA") -Text "presetMSRA2" })

    $w365PresetDiscon1MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetDiscon1" -Icon $machinew365icon #unexpected disconnect source
    $w365PresetDiscon1MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Source -Scenario @("Core") -Text "presetDiscon1" })

    $w365PresetDiscon2MenuItem = msrdCreateMenuItem -Menu $w365PresetMenuItem -Text "presetDiscon2" -Icon $machinew365icon #unexpected disconnect target
    $w365PresetDiscon2MenuItem.Add_Click({ msrdSetPreset -Machine W365 -Role Target -Scenario @("Core") -Text "presetDiscon2" })

    msrdCreateMenuItem -Menu $PresetsMenu -Text "---" | Out-Null

    $PresetResetMenuItem = msrdCreateMenuItem -Menu $PresetsMenu -Text "presetReset"
    $PresetResetMenuItem.Add_Click({ msrdResetAll })
    #endregion Presets menu

    $global:msrdFormMenu.Items.AddRange(@($FileMenu, $ViewMenu, $ToolsMenu, $PresetsMenu, $HelpMenu))

    if ($MaximizeWindow -eq 1) {
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
        $global:msrdPsBox.Font = New-Object System.Drawing.Font("MS Gothic", $global:msrdPsBoxFont)
    } else {
		$global:msrdPsBox.Font = New-Object System.Drawing.Font("Consolas", $global:msrdPsBoxFont)
    }
    msrdToggleFontSizeChecked $global:msrdPsBoxFont

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
            "AppAttach" = $scenariomsixaaicon; "Teams" = $scenarioteamsicon; "IME" = $scenarioimeicon; "SCard" = $scenarioscardicon
            "MSRA" = $scenariomsraicon; "Activation" = $scenarioactivationicon; "Profiles" = $scenarioprofilesicon; "Core" = $scenariocoreicon
        }
        $ActionElements = [Ordered]@{ "$(msrdGetLocalizedText 'Feedback')" = $feedbackicon; "$(msrdGetLocalizedText 'Start')" = $starticon }

    } else {
        $MachineElements = [Ordered]@{ "AVD" = $machineavdicon; "RDS" = $machinerdsicon; "W365" = $machinew365icon }
        $RoleElements = [Ordered]@{ "Source" = $rolesourceicon; "Target" = $roletargeticon }
        $ScenarioElements = [Ordered]@{
            "Core" = $scenariocoreicon; "Profiles" = $scenarioprofilesicon; "Activation" = $scenarioactivationicon; "MSRA" = $scenariomsraicon
            "SCard" = $scenarioscardicon; "IME" = $scenarioimeicon; "Teams" = $scenarioteamsicon; "AppAttach" = $scenariomsixaaicon
            "HCI" = $scenariohciicon; "ProcDump" = $scenarioprocdumpicon; "NetTrace" = $scenarionettraceicon; "DiagOnly" = $scenariodiagonlyicon
        }
        $ActionElements = [Ordered]@{ "$(msrdGetLocalizedText 'Start')" = $starticon; "$(msrdGetLocalizedText 'Feedback')" = $feedbackicon }
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
        if ($script:vProfiles -ne $script:varsProfiles) {
            msrdSetScenario -Scenario @("Profiles") -Status $true
        } else {
            msrdSetScenario -Scenario @("Profiles") -Status $false
        }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["Profiles"], "$(msrdGetLocalizedText 'btnTooltipProfiles')")

    $ScenarioDictionary["Activation"].Add_Click({
	    if ($script:vActivation -ne $script:varsActivation) {
            msrdSetScenario -Scenario @("Activation") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("Activation") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["Activation"], "$(msrdGetLocalizedText 'btnTooltipActivation')")

    $ScenarioDictionary["MSRA"].Add_Click({
	    if ($script:vMSRA -ne $script:varsMSRA) {
		    msrdSetScenario -Scenario @("MSRA") -Status $true
	    } else {
		    $script:vMSRA = $script:varsNO
		    msrdSetScenario -Scenario @("MSRA") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["MSRA"], "$(msrdGetLocalizedText 'btnTooltipMSRA')")

    $ScenarioDictionary["SCard"].Add_Click({
	    if ($script:vSCard -ne $script:varsSCard) {
		    msrdSetScenario -Scenario @("SCard") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("SCard") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["SCard"], "$(msrdGetLocalizedText 'btnTooltipSCard')")

    $ScenarioDictionary["IME"].Add_Click({
	    if ($script:vIME -ne $script:varsIME) {
		    msrdSetScenario -Scenario @("IME") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("IME") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["IME"], "$(msrdGetLocalizedText 'btnTooltipIME')")

    $ScenarioDictionary["Teams"].Add_Click({
	    if ($script:vTeams -ne $script:varsTeams) {
		    msrdSetScenario -Scenario @("Teams") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("Teams") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["Teams"], "$(msrdGetLocalizedText 'btnTooltipTeams')")

    $ScenarioDictionary["AppAttach"].Add_Click({
	    if ($script:vMSIXAA -ne $script:varsMSIXAA) {
		    msrdSetScenario -Scenario @("AppAttach") -Status $true
	    } else {
		    msrdSetScenario -Scenario @("AppAttach") -Status $false
	    }
    })
    $btnTooltip.SetToolTip($ScenarioDictionary["AppAttach"], "$(msrdGetLocalizedText 'btnTooltipMSIXAA')")

    $ScenarioDictionary["HCI"].Add_Click({
	    if ($script:vHCI -ne $script:varsHCI) {
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
            $global:onlyDiag = $True
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $False
            $ScenarioDictionary["DiagOnly"].Enabled = $true
		    $ScenarioDictionary["DiagOnly"].BackColor = "LightBlue"
            msrdSetScenario -Scenario @("Core") -Status $False
	    } else {
		    $global:onlyDiag = $False
            if ($global:msrdTarget) {
                msrdSetRole -Role Target -LiveReset
            } else {
                msrdSetRole -Role Source -LiveReset
            }
            if ($global:msrdRDS) {
                $msrdComputerBox.Enabled = $false
                $msrdComputerBox.Text = $env:computerName
            } else {
                $msrdComputerBox.Enabled = $true
                $msrdComputerBox.Text = $env:computerName
            }
	    }
        $ScenarioDictionary["DiagOnly"].Enabled = $True
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

        if ($global:msrdSource) {
            $liveDiagSystemActivationBtn.Enabled = $false
            $liveDiagSystemWSearchBtn.Enabled = $False
            $liveDiagAVDRDSFSLogixBtn.Enabled = $false
            $liveDiagAVDRDSRDPListenerBtn.Enabled = $false
            $liveDiagAVDRDSRDSRolesBtn.Enabled = $false
            $liveDiagAVDRDSTimeLimitsBtn.Enabled = $false
            $liveDiagAVDInfraHPBtn.Enabled = $false
            $liveDiagAVDInfraAgentStackBtn.Enabled = $false
            $liveDiagAVDInfraAppAttachBtn.Enabled = $false
            $liveDiagAVDInfraHCheckBtn.Enabled = $false
            $liveDiagAVDInfraMonBtn.Enabled = $false
            $liveDiagAVDInfraURIBtn.Enabled = $false
            $liveDiagAVDInfraHCIBtn.Enabled = $false
            $liveDiagKnownIssuesLogonBtn.Enabled = $false
            $liveDiagOtherOfficeBtn.Enabled = $false
            $liveDiagOtherODBtn.Enabled = $false
            $liveDiagAVDRDSRDClientBtn.Enabled = $true

            if ($global:msrdAVD -or $global:msrdRDS) {
                $liveDiagAVDRDSW365Btn.Enabled = $false
                $liveDiagAVDRDSLicensingBtn.Enabled = $true
            } else {
				$liveDiagAVDRDSW365Btn.Enabled = $true
                $liveDiagAVDRDSLicensingBtn.Enabled = $false
			}

            if ($global:msrdAVD -or $global:msrdW365) {
                $liveDiagAVDRDSTeamsBtn.Enabled = $true
            } else {
                $liveDiagAVDRDSTeamsBtn.Enabled = $false
            }
        } else {
            $liveDiagSystemActivationBtn.Enabled = $true
			$liveDiagSystemWSearchBtn.Enabled = $true
			$liveDiagAVDRDSRDPListenerBtn.Enabled = $true
			$liveDiagAVDRDSLicensingBtn.Enabled = $true
			$liveDiagAVDRDSTimeLimitsBtn.Enabled = $true
			$liveDiagKnownIssuesLogonBtn.Enabled = $true
            $liveDiagAVDInfraMonBtn.Enabled = $true
            $liveDiagAVDRDSRDClientBtn.Enabled = $false

            if ($global:msrdRDS -or $global:msrdW365) {
                $liveDiagAVDInfraHCIBtn.Enabled = $false
            } else {
                $liveDiagAVDInfraHCIBtn.Enabled = $true
                $liveDiagAVDInfraAppAttachBtn.Enabled = $true
            }

			if ($global:msrdAVD -or $global:msrdRDS) {
                $liveDiagAVDRDSW365Btn.Enabled = $false
                $liveDiagAVDRDSFSLogixBtn.Enabled = $true
    			$liveDiagAVDRDSRDSRolesBtn.Enabled = $true
            } else {
                $liveDiagAVDRDSW365Btn.Enabled = $true
                $liveDiagAVDRDSFSLogixBtn.Enabled = $false
                $liveDiagAVDRDSRDSRolesBtn.Enabled = $false
            }

			if ($global:msrdAVD -or $global:msrdW365) {
                $liveDiagAVDRDSTeamsBtn.Enabled = $true
			    $liveDiagAVDInfraHPBtn.Enabled = $true
			    $liveDiagAVDInfraAgentStackBtn.Enabled = $true
			    $liveDiagAVDInfraHCheckBtn.Enabled = $true
			    $liveDiagAVDInfraURIBtn.Enabled = $true
                $liveDiagOtherOfficeBtn.Enabled = $true
			    $liveDiagOtherODBtn.Enabled = $true
            } else {
                $liveDiagAVDRDSTeamsBtn.Enabled = $false
                $liveDiagAVDInfraHPBtn.Enabled = $false
                $liveDiagAVDInfraAgentStackBtn.Enabled = $false
                $liveDiagAVDInfraHCheckBtn.Enabled = $false
                $liveDiagAVDInfraURIBtn.Enabled = $false
                $liveDiagOtherOfficeBtn.Enabled = $false
                $liveDiagOtherODBtn.Enabled = $false
            }
        }

	    if ($global:msrdLiveDiag -ne $True) {
		    $global:msrdLiveDiag = $True
            msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
            msrdInitButtons -ButtonDictionary $LiveDictionary -status $false
            $LiveDictionary["LiveDiag"].Enabled = $true
		    $LiveDictionary["LiveDiag"].BackColor = "LightBlue"
            $ScenarioDictionary["Core"].BackColor = "Transparent"
            $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
            $msrdPsBox.Visible = $false
            $global:liveDiagTab.Visible = $true

            $msrdComputerBox.Enabled = $false
            $msrdComputerBox.Text = $env:computerName
            Import-Module -Name "$PSScriptRoot\MSRDC-Diagnostics" -DisableNameChecking -Force

	    } else {
            if ($global:msrdTarget) {
                msrdSetRole -Role Target -LiveReset
            } else {
                msrdSetRole -Role Source -LiveReset
            }
		    $global:msrdLiveDiag = $False

            if ($global:msrdRDS) {
                $msrdComputerBox.Enabled = $false
                $msrdComputerBox.Text = $env:computerName
            } else {
                $msrdComputerBox.Enabled = $true
                $msrdComputerBox.Text = $env:computerName
            }

            Remove-Module MSRDC-Diagnostics
	    }
    })
    $btnTooltip.SetToolTip($LiveDictionary["LiveDiag"], "$(msrdGetLocalizedText 'btnTooltipLiveDiag')")

    msrdInitButtons -ButtonDictionary $RoleDictionary -status $false
    msrdInitButtons -ButtonDictionary $ScenarioDictionary -status $false
    msrdInitButtons -ButtonDictionary $LiveDictionary -status $false

    $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Enabled = $false
    $ActionDictionary["$(msrdGetLocalizedText 'Start')"].Add_Click({

        if ($env:computerName -eq $msrdComputerBox.Text) {
            msrdStartBtnCollect -RemoteComputer $msrdComputerBox.Text
        } else {
            $msg = "$(msrdGetLocalizedText 'remoteModeNotice1')`n`n$(msrdGetLocalizedText 'remoteModeNotice2')`n`n$(msrdGetLocalizedText 'remoteModeNotice3')`n`n$(msrdGetLocalizedText 'remoteModeNotice4')`n`n$(msrdGetLocalizedText 'remoteModeNotice5')"
			$result = [Windows.Forms.MessageBox]::Show($msg, "$(msrdGetLocalizedText 'popupWarning')", [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
			if ($result -eq "Yes") {
                $global:msrdRemoteMode = $true
				msrdStartBtnCollect -RemoteComputer $msrdComputerBox.Text
                $global:msrdRemoteMode = $false
			}
        }
    })
    $btnTooltip.SetToolTip($ActionDictionary["$(msrdGetLocalizedText 'Start')"], "$(msrdGetLocalizedText 'RunMenu')")

    $ActionDictionary["$(msrdGetLocalizedText 'Feedback')"].Add_Click({ [System.Diagnostics.Process]::start("https://aka.ms/MSRD-Collect-Feedback") })
    $ActionDictionary["$(msrdGetLocalizedText 'Feedback')"].BackColor = "LightYellow"
    $btnTooltip.SetToolTip($ActionDictionary["$(msrdGetLocalizedText 'Feedback')"], "$(msrdGetLocalizedText 'btnTooltipFeedback')")

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
            msrdAddOutputBoxLine "$(msrdGetLocalizedText "dpidtext3") $nameProc`n" "Yellow"
        } else {
            $ScenarioDictionary["ProcDump"].BackColor = "Transparent"
            $script:pidProc = ""
            msrdAddOutputBoxLine "$(msrdGetLocalizedText "dpidtext4")`n" "Yellow"
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
            msrdAddOutputBoxLine "$(msrdGetLocalizedText "dpidtext3") $nameProc`n" "Yellow"
        } else {
            $ScenarioDictionary["ProcDump"].BackColor = "Transparent"
            $script:pidProc = ""
            $dumppidBox.SelectedValue = $script:pidProc
            msrdAddOutputBoxLine "$(msrdGetLocalizedText "dpidtext4")`n" "Yellow"
            $script:dumpProc = $False
        }
    })
    #endregion DumpPID


    #region data collection configuration form
    $selectCollectForm = New-Object System.Windows.Forms.Form
    $selectCollectForm.Width = 660
    $selectCollectForm.Height = 430
    $selectCollectForm.StartPosition = "CenterScreen"
    $selectCollectForm.MinimizeBox = $False
    $selectCollectForm.MaximizeBox = $False
    $selectCollectForm.BackColor = "#eeeeee"
    $selectCollectForm.Text = msrdGetLocalizedText "selectCollect1"
    $selectCollectForm.Icon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\Config\MSRDC-Icons.dll", 3, $true))
    $selectCollectForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

    $selectCollectLabel = New-Object System.Windows.Forms.Label
    $selectCollectLabel.Location  = New-Object System.Drawing.Point(10,10)
    $selectCollectLabel.Size  = New-Object System.Drawing.Point(620,50)
    $selectCollectLabel.Text = msrdGetLocalizedText "selectCollect2"
    if ($global:msrdLangID -eq "AR") { $selectCollectLabel.RightToLeft = "Yes" } else { $selectCollectLabel.RightToLeft = "No" }
    $selectCollectForm.Controls.Add($selectCollectLabel)

    # Label above the left box
    $lblIncludedC = New-Object System.Windows.Forms.Label
    $lblIncludedC.Location = New-Object System.Drawing.Point(20, 60)
    $lblIncludedC.Size = New-Object System.Drawing.Size(260, 20)
    $lblIncludedC.Text = msrdGetLocalizedText "selectCollect3"
    if ($global:msrdLangID -eq "AR") { $lblIncludedC.RightToLeft = "Yes" } else { $lblIncludedC.RightToLeft = "No" }
    $selectCollectForm.Controls.Add($lblIncludedC)

    # Create and populate left list with a hashtable
    $leftListC = New-Object System.Windows.Forms.ListBox
    $leftListC.Location = New-Object System.Drawing.Point(20,80)
    $leftListC.Size = New-Object System.Drawing.Size(250,300)
    $leftListC.HorizontalScrollbar  = $true
    $leftListC.SelectionMode = "MultiExtended"

    $leftItemsC = @(
        @("Activation", "Activation > 'licensingdiag' information", 0),
        @("Activation", "Activation > 'slmgr /dlv' information", 1),
        @("Activation", "Activation > List of domain KMS servers", 2),
        @("Core", "Core > Core AVD/RDS information", 0),
        @("Core", "Core > Event logs", 1),
        @("Core", "Core > Security event logs", 2),
        @("Core", "Core > Registry keys", 3),
        @("Core", "Core > RDP, network and AD information", 4),
        @("Core", "Core > 'dsregcmd /status' information", 5),
        @("Core", "Core > Scheduled tasks information", 6),
        @("Core", "Core > System information", 7),
        @("Core", "Core > Windows Update history", 8),
        @("Core", "Core > MDM information", 9),
        @("Core", "Core > RDS roles information", 10),
        @("Core", "Core > RDP listener granular permissions", 11)
        @("HCI", "HCI > HCI logs", 0),
        @("IME", "IME > Registry keys", 0),
        @("IME", "IME > Tree output of IME folders", 1),
        @("IME", "IME > Culture and language list", 2),
        @("MSIXAA", "AppAttach > Event logs", 0),
        @("MSRA", "MSRA > Event logs", 0),
        @("MSRA", "MSRA > Registry keys", 1),
        @("MSRA", "MSRA > Groups membership information", 2),
        @("MSRA", "MSRA > Permissions", 3),
        @("MSRA", "MSRA > Scheduled task information", 4),
        @("MSRA", "MSRA > Remote Help logs", 5),
        @("Profiles", "Profiles > Event logs", 0),
        @("Profiles", "Profiles > Registry keys", 1),
        @("Profiles", "Profiles > WhoAmI information", 2),
        @("Profiles", "Profiles > FSLogix information", 3),
        @("Profiles", "Profiles > Virtual Disk registry consistency", 4),
        @("SCard", "SCard > Event logs", 0),
        @("SCard", "SCard > 'certutil' information", 1),
        @("SCard", "SCard > KDCProxy / RD Gateway information", 2),
        @("Teams", "Teams > Registry keys", 0),
        @("Teams", "Teams > Event logs", 1),
        @("Teams", "Teams > Teams log files", 2),
        @("Teams", "Teams > Teams appx package information", 3)
    )

    foreach ($pairC in $leftItemsC) { $leftListC.Items.Add($pairC[1]) | Out-Null }

    # Label above the right box
    $lblExcludedC = New-Object System.Windows.Forms.Label
    $lblExcludedC.Location = New-Object System.Drawing.Point(370, 60)
    $lblExcludedC.Size = New-Object System.Drawing.Size(260, 20)
    $lblExcludedC.Text = msrdGetLocalizedText "selectCollect4"
    if ($global:msrdLangID -eq "AR") { $lblExcludedC.RightToLeft = "Yes" } else { $lblExcludedC.RightToLeft = "No" }
    $selectCollectForm.Controls.Add($lblExcludedC)

    $rightListC = New-Object System.Windows.Forms.ListBox
    $rightListC.Location = New-Object System.Drawing.Point(370,80)
    $rightListC.Size = New-Object System.Drawing.Size(250,300)
    $rightListC.HorizontalScrollbar  = $true
    $rightListC.SelectionMode = "MultiExtended"

    $categoriesToVarsC = @{
        "Activation"  = $script:varsActivation
        "Core"        = $script:varsCore
        "IME"         = $script:varsIME
        "HCI"         = $script:varsHCI
        "MSIXAA"      = $script:varsMSIXAA
        "MSRA"        = $script:varsMSRA
        "Profiles"    = $script:varsProfiles
        "SCard"       = $script:varsSCard
        "Teams"       = $script:varsTeams
    }

    # Create buttons
    $btnAddC = New-Object System.Windows.Forms.Button
    $btnAddC.Location = New-Object System.Drawing.Point(290,120)
    $btnAddC.Size = New-Object System.Drawing.Size(60,23)
    $btnAddC.Text = ">"
    $btnAddC.Add_Click({
        $selectedItemsC = $leftListC.SelectedItems
        $itemsToAddC = @()

        foreach ($selectedItemC in $selectedItemsC) {
            $optionC = $leftItemsC | Where-Object { $_[1] -eq $selectedItemC }
            $categoryC = $optionC[0]
            $selectedVarsC = $categoriesToVarsC[$categoryC]
            if ($null -ne $selectedVarsC) {
                $selectedVarsC[$optionC[2]] = $false
            }

            $itemsToAddC += $selectedItemC
        }

        $rightListC.Items.AddRange($itemsToAddC)
        foreach ($itemC in $itemsToAddC) {
            $leftListC.Items.Remove($itemC)
        }

        $rightListC.Sorted = $true
    })

    $btnRemoveC = New-Object System.Windows.Forms.Button
    $btnRemoveC.Location = New-Object System.Drawing.Point(290,160)
    $btnRemoveC.Size = New-Object System.Drawing.Size(60,23)
    $btnRemoveC.Text = "<"
    $btnRemoveC.Add_Click({
        $selectedItemsC = $rightListC.SelectedItems
        $itemsToAddBackC = @()

        foreach ($selectedItemC in $selectedItemsC) {
            $optionC = $leftItemsC | Where-Object { $_[1] -eq $selectedItemC }
            $categoryC = $optionC[0]
            $selectedVarsC = $categoriesToVarsC[$categoryC]
            if ($null -ne $selectedVarsC) {
                $selectedVarsC[$optionC[2]] = $true
            }

            $itemsToAddBackC += $selectedItemC
        }

        $leftListC.Items.AddRange($itemsToAddBackC)
        foreach ($itemC in $itemsToAddBackC) {
            $rightListC.Items.Remove($itemC)
        }

        $leftListC.Sorted = $true
    })

    # Add controls to form
    $selectCollectForm.Controls.Add($leftListC)
    $selectCollectForm.Controls.Add($rightListC)
    $selectCollectForm.Controls.Add($btnAddC)
    $selectCollectForm.Controls.Add($btnRemoveC)

    #endregion data collection configuration form

    #region diagnostics configuration form
    $selectDiagForm = New-Object System.Windows.Forms.Form
    $selectDiagForm.Width = 660
    $selectDiagForm.Height = 430
    $selectDiagForm.StartPosition = "CenterScreen"
    $selectDiagForm.MinimizeBox = $False
    $selectDiagForm.MaximizeBox = $False
    $selectDiagForm.BackColor = "#eeeeee"
    $selectDiagForm.Text = msrdGetLocalizedText "selectDiag1"
    $selectDiagForm.Icon = ([System.IconExtractor]::Extract("$global:msrdScriptpath\Config\MSRDC-Icons.dll", 3, $true))
    $selectDiagForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

    $selectDiagLabel = New-Object System.Windows.Forms.Label
    $selectDiagLabel.Location  = New-Object System.Drawing.Point(10,10)
    $selectDiagLabel.Size  = New-Object System.Drawing.Point(620,50)
    $selectDiagLabel.Text = msrdGetLocalizedText "selectDiag2"
    if ($global:msrdLangID -eq "AR") { $selectDiagLabel.RightToLeft = "Yes" } else { $selectDiagLabel.RightToLeft = "No" }
    $selectDiagForm.Controls.Add($selectDiagLabel)

    # Label above the left box
    $lblIncludedD = New-Object System.Windows.Forms.Label
    $lblIncludedD.Location = New-Object System.Drawing.Point(20, 60)
    $lblIncludedD.Size = New-Object System.Drawing.Size(260, 20)
    $lblIncludedD.Text = msrdGetLocalizedText "selectDiag3"
    if ($global:msrdLangID -eq "AR") { $lblIncludedD.RightToLeft = "Yes" } else { $lblIncludedD.RightToLeft = "No" }
    $selectDiagForm.Controls.Add($lblIncludedD)

    # Create and populate left list with a hashtable
    $leftListD = New-Object System.Windows.Forms.ListBox
    $leftListD.Location = New-Object System.Drawing.Point(20,80)
    $leftListD.Size = New-Object System.Drawing.Size(250,300)
    $leftListD.HorizontalScrollbar  = $true
    $leftListD.SelectionMode = "MultiExtended"

    $leftItemsD = @(
        @("Active Directory", "Active Directory > Microsoft Entra Join", 0),
        @("Active Directory", "Active Directory > Domain Controller", 1),
        @("AVD Infra", "AVD Infra > Agents/SxS Stack", 0),
        @("AVD Infra", "AVD Infra > App Attach", 1),
        @("AVD Infra", "AVD Infra > AVD Services URI Health", 2),
        @("AVD Infra", "AVD Infra > Azure Stack HCI", 3),
        @("AVD Infra", "AVD Infra > Health Checks", 4),
        @("AVD Infra", "AVD Infra > Host Pool", 5),
        @("AVD Infra", "AVD Infra > Monitoring", 6),
        @("AVD Infra", "AVD Infra > RDP Shortpath", 7),
        @("AVD Infra", "AVD Infra > Required Endpoints - AVD", 8),
        @("AVD Infra", "AVD Infra > Required Endpoints - Windows 365", 9),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Redirection", 0),
        @("AVD/RDS/W365", "AVD/RDS/W365 > FSLogix", 1),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Multimedia", 2),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Quick Assist / Remote Help", 3),
        @("AVD/RDS/W365", "AVD/RDS/W365 > RDP / Listener", 4),
        @("AVD/RDS/W365", "AVD/RDS/W365 > RDS Roles", 5),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Remote Desktop Clients", 6),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Remote Desktop Licensing", 7),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Session Time Limits", 8),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Teams media optimization", 9),
        @("AVD/RDS/W365", "AVD/RDS/W365 > Windows 365 Boot", 10),
        @("Known Issues", "Known Issues > Event Logs", 0),
        @("Known Issues", "Known Issues > Logon/Logoff", 1),
        @("Logon/Security", "Logon/Security > Authentication / Logon", 0),
        @("Logon/Security", "Logon/Security > Security", 1),
        @("Logon/Security", "Logon/Security > Smart Card", 2),
        @("Networking", "Networking > Core NET", 0),
        @("Networking", "Networking > DNS", 1),
        @("Networking", "Networking > Firewall", 2),
        @("Networking", "Networking > IP Addresses", 3),
        @("Networking", "Networking > Port Usage", 4),
        @("Networking", "Networking > Proxy", 5),
        @("Networking", "Networking > Routing", 6),
        @("Networking", "Networking > VPN", 7),
        @("Other", "Other > Microsoft Office", 0),
        @("Other", "Other > Microsoft OneDrive", 1),
        @("Other", "Other > Printing", 2),
        @("Other", "Other > Third Party", 3),
        @("System", "System > Core", 0),
        @("System", "System > CPU Utilization", 1),
        @("System", "System > Drives", 2),
        @("System", "System > Graphics", 3),
        @("System", "System > Hyper-V Integration", 4),
        @("System", "System > OS Activation / Licensing", 5),
        @("System", "System > SSL / TLS", 6),
        @("System", "System > User Access Control (UAC)", 7)
        @("System", "System > Windows Installer", 8),
        @("System", "System > Windows Search", 9),
        @("System", "System > Windows Updates", 10),
        @("System", "System > WinRM / PowerShell", 11)
    )

    foreach ($pairD in $leftItemsD) { $leftListD.Items.Add($pairD[1]) | Out-Null }

    # Label above the right box
    $lblExcludedD = New-Object System.Windows.Forms.Label
    $lblExcludedD.Location = New-Object System.Drawing.Point(370, 60)
    $lblExcludedD.Size = New-Object System.Drawing.Size(260, 20)
    $lblExcludedD.Text = msrdGetLocalizedText "selectDiag4"
    if ($global:msrdLangID -eq "AR") { $lblExcludedD.RightToLeft = "Yes" } else { $lblExcludedD.RightToLeft = "No" }
    $selectDiagForm.Controls.Add($lblExcludedD)

    $rightListD = New-Object System.Windows.Forms.ListBox
    $rightListD.Location = New-Object System.Drawing.Point(370,80)
    $rightListD.Size = New-Object System.Drawing.Size(250,300)
    $rightListD.HorizontalScrollbar  = $true
    $rightListD.SelectionMode = "MultiExtended"

    $categoriesToVarsD = @{
        "System"           = $script:varsSystem
        "AVD/RDS/W365"     = $script:varsAVDRDS
        "AVD Infra"        = $script:varsInfra
        "Active Directory" = $script:varsAD
        "Networking"       = $script:varsNET
        "Logon/Security"   = $script:varsLogSec
        "Known Issues"     = $script:varsIssues
        "Other"            = $script:varsOther
    }

    # Create buttons
    $btnAddD = New-Object System.Windows.Forms.Button
    $btnAddD.Location = New-Object System.Drawing.Point(290,120)
    $btnAddD.Size = New-Object System.Drawing.Size(60,23)
    $btnAddD.Text = ">"
    $btnAddD.Add_Click({
        $selectedItemsD = $leftListD.SelectedItems
        $itemsToAddD = @()

        foreach ($selectedItemD in $selectedItemsD) {
            $optionD = $leftItemsD | Where-Object { $_[1] -eq $selectedItemD }
            $categoryD = $optionD[0]
            $selectedVarsD = $categoriesToVarsD[$categoryD]
            if ($null -ne $selectedVarsD) {
                $selectedVarsD[$optionD[2]] = $false
            }

            $itemsToAddD += $selectedItemD
        }

        $rightListD.Items.AddRange($itemsToAddD)
        foreach ($itemD in $itemsToAddD) {
            $leftListD.Items.Remove($itemD)
        }

        $rightListD.Sorted = $true
    })

    $btnRemoveD = New-Object System.Windows.Forms.Button
    $btnRemoveD.Location = New-Object System.Drawing.Point(290,160)
    $btnRemoveD.Size = New-Object System.Drawing.Size(60,23)
    $btnRemoveD.Text = "<"
    $btnRemoveD.Add_Click({
        $selectedItemsD = $rightListD.SelectedItems
        $itemsToAddBackD = @()

        foreach ($selectedItemD in $selectedItemsD) {
            $optionD = $leftItemsD | Where-Object { $_[1] -eq $selectedItemD }
            $categoryD = $optionD[0]
            $selectedVarsD = $categoriesToVarsD[$categoryD]
            if ($null -ne $selectedVarsD) {
                $selectedVarsD[$optionD[2]] = $true
            }

            $itemsToAddBackD += $selectedItemD
        }

        $leftListD.Items.AddRange($itemsToAddBackD)
        foreach ($itemD in $itemsToAddBackD) {
            $rightListD.Items.Remove($itemD)
        }

        $leftListD.Sorted = $true
    })

    $selectDiagForm.Controls.Add($leftListD)
    $selectDiagForm.Controls.Add($rightListD)
    $selectDiagForm.Controls.Add($btnAddD)
    $selectDiagForm.Controls.Add($btnRemoveD)

    #endregion diagnostics configuration form


    #region scheduled task configuration form

    $staskForm = New-Object System.Windows.Forms.Form
    $staskForm.Text = msrdGetLocalizedText "schedTaskCreate"
    $staskForm.Icon = $scheduledtaskicon
    $staskForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $staskForm.MinimizeBox = $false
    $staskForm.MaximizeBox = $false
    $staskForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $staskForm.Width = 500
    $staskForm.Height = 400
    if ($global:msrdLangID -eq "AR") { $staskForm.RightToLeft = "Yes" } else { $staskForm.RightToLeft = "No" }

    # controls
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
        $message = msrdGetLocalizedText "schedTaskNote"
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
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo1')" -Color Yellow
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo2') " -Color Cyan -noNewLine
            $selectedDate = $selectedDate.ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
            msrdAddOutputBoxLine "$selectedDate"
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo3') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "$selectedTime"
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo4') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "$frequency"
            if ($frequency -eq "Weekly") {
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo5') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$daysOfWeek"
            }
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo6') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "$machineType"
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo7') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "$machineRole"
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo8') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "$scriptLocation"
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo9') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "$outputLocation"
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo10') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "NT AUTHORITY\SYSTEM"
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo14') " -Color Cyan -noNewLine
            msrdAddOutputBoxLine "$action2`n`n"

        } else {
            if ($frequency -eq "Monthly") {

                # Generate the 8.3 short file name for the script location
                $shortScriptLocation = Get-ShortFileName -Path $scriptLocation
                $shortOutputLocation = Get-ShortFileName -Path $outputLocation

                $scriptParameters2 = "-Machine is$machineType -Role is$machineRole -DiagOnly -AcceptEula -AcceptNotice -SkipAutoUpdate -OutputDir $shortOutputLocation"
                $action2 = "PowerShell.exe -ExecutionPolicy Bypass -File $shortScriptLocation $scriptParameters2"

                $command = "schtasks.exe /Create /TN '" + $taskName + "' /SC MONTHLY /D " + $daysOfWeek + " /F /ST " + $selectedTime + " /MO " + $selectedWeekOfMonth + " /TR '" + $action2 + "' /RU 'NT AUTHORITY\SYSTEM'"
                Invoke-Expression "cmd /c $command"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo11')" -Color Yellow
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo2') " -Color Cyan -noNewLine
                $selectedDate = $selectedDate.ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
                msrdAddOutputBoxLine "$selectedDate"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo3') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$selectedTime"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo4') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$frequency"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo5') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$daysOfWeek"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo12') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$selectedWeekOfMonth"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo6') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$machineType"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo7') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$machineRole"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo8') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$scriptLocation"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo9') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$outputLocation"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo10') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "NT AUTHORITY\SYSTEM"
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo14') " -Color Cyan -noNewLine
                msrdAddOutputBoxLine "$action2`n`n"
            } else {
                msrdAddOutputBoxLine "$(msrdGetLocalizedText 'schedTaskInfo13')" -Color Red
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
    $userContextForm.Width = 420
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
    if ($global:msrdLangID -eq "AR") { $userContextLabel.RightToLeft = "Yes" } else { $userContextLabel.RightToLeft = "No" }
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
                [System.Windows.Forms.MessageBox]::Show("$(msrdGetLocalizedText 'userCon1')`n$msrdUserProfilesDir\$tempUserprof`n`n$(msrdGetLocalizedText 'userCon2') $($userContextBox.Text)", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
        } else {
            $userContextBox.Text = [System.Environment]::UserName; $global:msrdUserprof = [System.Environment]::UserName
        }
        $userContextForm.Close()
        msrdAddOutputBoxLine "$(msrdGetLocalizedText "context3") $($userContextBox.Text)`n" "Yellow"
    })

    $userContextCancel = New-Object System.Windows.Forms.Button
    $userContextCancel.Location = New-Object System.Drawing.Size(310,58)
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
        msrdAddOutputBoxLine "$(msrdGetLocalizedText "context3") $($userContextBox.Text)`n" "Yellow"
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


    function CreateRichTextBox {
        param (
            [string]$Name,
            [System.Windows.Forms.Control]$Container
        )

        $richTextbox = New-Object System.Windows.Forms.RichTextBox
        $richTextbox.Name = $Name
        $richTextbox.Location = [System.Drawing.Point]::new(0, 30)
        $richTextbox.Font = [System.Drawing.Font]::new("Consolas", $global:msrdPsBoxFont)
        $richTextbox.Height = $Container.ClientSize.Height - 30
        $richTextbox.Width = $Container.ClientSize.Width
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

    $global:psBoxLiveDiagSystem = CreateRichTextBox -Name "psBoxLiveDiagSystem" -Container $liveDiagTabSystem
    $global:psBoxLiveDiagAVDRDS = CreateRichTextBox -Name "psBoxLiveDiagAVDRDS" -Container $liveDiagTabAVDRDS
    $global:psBoxLiveDiagAVDInfra = CreateRichTextBox -Name "psBoxLiveDiagAVDInfra" -Container $liveDiagTabAVDInfra
    $global:psBoxLiveDiagAD = CreateRichTextBox -Name "psBoxLiveDiagAD" -Container $liveDiagTabAD
    $global:psBoxLiveDiagNet = CreateRichTextBox -Name "psBoxLiveDiagNet" -Container $liveDiagTabNet
    $global:psBoxLiveDiagLogonSec = CreateRichTextBox -Name "psBoxLiveDiagLogonSec" -Container $liveDiagTabLogonSec
    $global:psBoxLiveDiagIssues = CreateRichTextBox -Name "psBoxLiveDiagIssues" -Container $liveDiagTabIssues
    $global:psBoxLiveDiagOther = CreateRichTextBox -Name "psBoxLiveDiagOther" -Container $liveDiagTabOther

    $global:msrdForm.Controls.Add($liveDiagTab)

    function CreateTabButton {
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
            $section,
            [string]$action
        )

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

        if ($action -eq "Start") {
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
            $global:msrdDiagnosing = $true
            Set-Variable -Name $section -Value $true -Scope Global

		    $psBox.Clear()
            $psBox.SelectionBackColor = "LightBlue"

            $psBox.Font = [System.Drawing.Font]::new("Consolas", $global:msrdPsBoxFont)

            if ($global:msrdLangID -eq "AR") {
                $liveDiagText1a = "$(msrdGetLocalizedText 'liveDiag1') "
                $liveDiagText1b = "${ARhour}:${ARminute}:${ARsecond}.${ARmillisecond} ${ARyear}/${ARmonth}/${ARday}" + "`r`n"

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

            if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "$(msrdGetLocalizedText 'liveDiag1')" }

            $psBox.SelectionBackColor = "Transparent"
		    $psBox.Refresh()

        } elseif ($action -eq "Stop") {
            $global:msrdDiagnosing = $false
            $psBox.AppendText("`n`n`n")
            $psBox.SelectionBackColor = "LightBlue"

            if ($global:msrdLangID -eq "AR") {
                $liveDiagText2a = "$(msrdGetLocalizedText 'liveDiag2') "
                $liveDiagText2b = "${ARhour}:${ARminute}:${ARsecond}.${ARmillisecond} ${ARyear}/${ARmonth}/${ARday}"

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

            if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "$(msrdGetLocalizedText 'liveDiag2')" }

            $psBox.SelectionBackColor = "Transparent"
            $psBox.ScrollToCaret()
            $psBox.Refresh()
            $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
            Set-Variable -Name $section -Value $false -Scope Global

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

    $liveDiagSystemBtn = CreateTabButton -Name "Run all" -container $systemBtnPanel -XPosition 0
    $liveDiagSystemBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"

        msrdDiagDeployment
        msrdDiagCPU
        msrdDiagDrives
        msrdDiagGraphics
        if ($global:msrdTarget) { msrdDiagActivation }
        msrdDiagSSLTLS
        msrdDiagUAC
        msrdDiagInstaller
        if ($global:msrdTarget) { msrdDiagSearch }
        msrdDiagWU
        msrdDiagWinRMPS

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemCoreBtn = CreateTabButton -Name "Core" -container $systemBtnPanel -XPosition 70
    $liveDiagSystemCoreBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagDeployment
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemCPUBtn = CreateTabButton -Name "CPU/Hndl" -container $systemBtnPanel -XPosition 140
    $liveDiagSystemCPUBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagCPU
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemDrivesBtn = CreateTabButton -Name "Drives" -container $systemBtnPanel -XPosition 210
    $liveDiagSystemDrivesBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagDrives
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemGfxBtn = CreateTabButton -Name "Graphics" -container $systemBtnPanel -XPosition 280
    $liveDiagSystemGfxBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagGraphics
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemActivationBtn = CreateTabButton -Name "Activation" -container $systemBtnPanel -XPosition 350
    $liveDiagSystemActivationBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagActivation
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemSSLTLSBtn = CreateTabButton -Name "SSL/TLS" -container $systemBtnPanel -XPosition 420
    $liveDiagSystemSSLTLSBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagSSLTLS
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemUACBtn = CreateTabButton -Name "UAC" -container $systemBtnPanel -XPosition 490
    $liveDiagSystemUACBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagUAC
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemWInstallerBtn = CreateTabButton -Name "Installer" -container $systemBtnPanel -XPosition 560
    $liveDiagSystemWInstallerBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagInstaller
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemWSearchBtn = CreateTabButton -Name "Search" -container $systemBtnPanel -XPosition 630
    $liveDiagSystemWSearchBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagSearch
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemWUpdateBtn = CreateTabButton -Name "Update" -container $systemBtnPanel -XPosition 700
    $liveDiagSystemWUpdateBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagWU
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})

    $liveDiagSystemWinRMPSBtn = CreateTabButton -Name "WinRM/PS" -container $systemBtnPanel -XPosition 770
    $liveDiagSystemWinRMPSBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Start"
        msrdDiagWinRMPS
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagSystem -section msrdLiveDiagSystem -action "Stop"
	})
    #endregion System tab

    #region AVD/RDS tab
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

    $liveDiagAVDRDSBtn = CreateTabButton -Name "Run all" -container $avdrdsBtnPanel -XPosition 0
    $liveDiagAVDRDSBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"

        msrdDiagRedirection
        if ($global:msrdTarget) { msrdDiagFSLogix }
        msrdDiagMultimedia
        msrdDiagQA
        if ($global:msrdTarget) { msrdDiagRDPListener }
        if ($global:msrdTarget -and ($global:msrdOSVer -like "*Windows*Server*")) { msrdDiagRDSRoles }
        if ($global:msrdSource) { msrdDiagRDClient }
        msrdDiagLicensing
        if ($global:msrdTarget) { msrdDiagTimeLimits }
        if ($global:msrdAVD -or $global:msrdW365) { msrdDiagTeams }
        if ($global:msrdW365) { msrdDiagW365 }

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSRedirectionBtn = CreateTabButton -Name "Redirection" -container $avdrdsBtnPanel -XPosition 70
    $liveDiagAVDRDSRedirectionBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagRedirection
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSFSLogixBtn = CreateTabButton -Name "FSLogix" -container $avdrdsBtnPanel -XPosition 140
    $liveDiagAVDRDSFSLogixBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagFSLogix
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSMultimediaBtn = CreateTabButton -Name "Multimedia" -container $avdrdsBtnPanel -XPosition 210
    $liveDiagAVDRDSMultimediaBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagMultimedia
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSQABtn = CreateTabButton -Name "QA/RH" -container $avdrdsBtnPanel -XPosition 280
    $liveDiagAVDRDSQABtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagQA
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSRDPListenerBtn = CreateTabButton -Name "Listener" -container $avdrdsBtnPanel -XPosition 350
    $liveDiagAVDRDSRDPListenerBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagRDPListener
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSRDSRolesBtn = CreateTabButton -Name "RDS Roles" -container $avdrdsBtnPanel -XPosition 420
    $liveDiagAVDRDSRDSRolesBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagRDSRoles
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSRDClientBtn = CreateTabButton -Name "RD Client" -container $avdrdsBtnPanel -XPosition 490
    $liveDiagAVDRDSRDClientBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagRDClient
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSLicensingBtn = CreateTabButton -Name "Licensing" -container $avdrdsBtnPanel -XPosition 560
    $liveDiagAVDRDSLicensingBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagLicensing
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSTimeLimitsBtn = CreateTabButton -Name "Time Limits" -container $avdrdsBtnPanel -XPosition 630
    $liveDiagAVDRDSTimeLimitsBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagTimeLimits
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSTeamsBtn = CreateTabButton -Name "Teams" -container $avdrdsBtnPanel -XPosition 700
    $liveDiagAVDRDSTeamsBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagTeams
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
	})

    $liveDiagAVDRDSW365Btn = CreateTabButton -Name "W365 Boot" -container $avdrdsBtnPanel -XPosition 770
    $liveDiagAVDRDSW365Btn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Start"
        msrdDiagW365
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDRDS -section msrdLiveDiagAVDRDS -action "Stop"
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

    $liveDiagAVDInfraBtn = CreateTabButton -Name "Run all" -container $avdinfraBtnPanel -XPosition 0
    $liveDiagAVDInfraBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"

        if ($global:msrdTarget) {
            if ($global:msrdAVD -or $global:msrdW365) {
                msrdDiagAgentStack
                if ($global:msrdAVD) { msrdDiagAppAttach }
                msrdDiagURIHealth
                if ($global:msrdAVD) { msrdDiagHCI }
                msrdDiagHealthCheck
                msrdDiagHP
            }
            msrdDiagMonitoring
        }
        msrdDiagURL
        msrdDiagShortpath

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraAgentStackBtn = CreateTabButton -Name "Agents" -container $avdinfraBtnPanel -XPosition 70
    $liveDiagAVDInfraAgentStackBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagAgentStack
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraAppAttachBtn = CreateTabButton -Name "App Attach" -container $avdinfraBtnPanel -XPosition 140
    $liveDiagAVDInfraAppAttachBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagAppAttach
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraURIBtn = CreateTabButton -Name "URI Health" -container $avdinfraBtnPanel -XPosition 210
    $liveDiagAVDInfraURIBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagURIHealth
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraHCIBtn = CreateTabButton -Name "HCI" -container $avdinfraBtnPanel -XPosition 280
    $liveDiagAVDInfraHCIBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagHCI
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraHCheckBtn = CreateTabButton -Name "Health Ck" -container $avdinfraBtnPanel -XPosition 350
    $liveDiagAVDInfraHCheckBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagHealthCheck
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraHPBtn = CreateTabButton -Name "Host Pool" -container $avdinfraBtnPanel -XPosition 420
    $liveDiagAVDInfraHPBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagHP
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraMonBtn = CreateTabButton -Name "Monitoring" -container $avdinfraBtnPanel -XPosition 490
    $liveDiagAVDInfraMonBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagMonitoring
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraShortpathBtn = CreateTabButton -Name "Shortpath" -container $avdinfraBtnPanel -XPosition 560
    $liveDiagAVDInfraShortpathBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagShortpath
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
	})

    $liveDiagAVDInfraReqURLBtn = CreateTabButton -Name "AVD EPs" -container $avdinfraBtnPanel -XPosition 630
    $liveDiagAVDInfraReqURLBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Start"
        msrdDiagURL
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAVDInfra -section msrdLiveDiagAVDInfra -action "Stop"
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

    $liveDiagADBtn = CreateTabButton -Name "Run all" -container $adBtnPanel -XPosition 0
    $liveDiagADBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAD -section msrdLiveDiagAD -action "Start"

        msrdDiagEntraJoin
        msrdDiagDC

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAD -section msrdLiveDiagAD -action "Stop"
	})

    $liveDiagADAADJBtn = CreateTabButton -Name "Entra Join" -container $adBtnPanel -XPosition 70
    $liveDiagADAADJBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAD -section msrdLiveDiagAD -action "Start"
        msrdDiagEntraJoin
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAD -section msrdLiveDiagAD -action "Stop"
	})

    $liveDiagADDCBtn = CreateTabButton -Name "Domain" -container $adBtnPanel -XPosition 140
    $liveDiagADDCBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAD -section msrdLiveDiagAD -action "Start"
        msrdDiagDC
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagAD -section msrdLiveDiagAD -action "Stop"
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

    $liveDiagNetBtn = CreateTabButton -Name "Run all" -container $netBtnPanel -XPosition 0
    $liveDiagNetBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"

        msrdDiagNWCore
        msrdDiagDNS
        msrdDiagFirewall
        msrdDiagIPAddresses
        msrdDiagPortUsage
        msrdDiagProxy
        msrdDiagRouting
        msrdDiagVPN

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetNWCoreBtn = CreateTabButton -Name "Core NET" -container $netBtnPanel -XPosition 70
    $liveDiagNetNWCoreBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagNWCore
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetDNSBtn = CreateTabButton -Name "DNS" -container $netBtnPanel -XPosition 140
    $liveDiagNetDNSBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagDNS
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetFirewallBtn = CreateTabButton -Name "Firewall" -container $netBtnPanel -XPosition 210
    $liveDiagNetFirewallBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagFirewall
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetIPBtn = CreateTabButton -Name "IPs" -container $netBtnPanel -XPosition 280
    $liveDiagNetIPBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagIPAddresses
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetPortBtn = CreateTabButton -Name "Port Usage" -container $netBtnPanel -XPosition 350
    $liveDiagNetPortBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagPortUsage
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetProxyBtn = CreateTabButton -Name "Proxy" -container $netBtnPanel -XPosition 420
    $liveDiagNetProxyBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagProxy
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetRoutingBtn = CreateTabButton -Name "Routing" -container $netBtnPanel -XPosition 490
    $liveDiagNetRoutingBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagRouting
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
	})

    $liveDiagNetVPNBtn = CreateTabButton -Name "VPN" -container $netBtnPanel -XPosition 560
    $liveDiagNetVPNBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Start"
        msrdDiagVPN
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagNet -section msrdLiveDiagNet -action "Stop"
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

    $liveDiagLogonSecBtn = CreateTabButton -Name "Run all" -container $logonSecBtnPanel -XPosition 0
    $liveDiagLogonSecBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Start"

        msrdDiagAuth
        msrdDiagSecurity

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Stop"
	})

    $liveDiagLogonSecAuthBtn = CreateTabButton -Name "Auth" -container $logonSecBtnPanel -XPosition 70
    $liveDiagLogonSecAuthBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Start"
        msrdDiagAuth
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Stop"
	})

    $liveDiagLogonSecSecurityBtn = CreateTabButton -Name "Security" -container $logonSecBtnPanel -XPosition 140
    $liveDiagLogonSecSecurityBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Start"
        msrdDiagSecurity
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Stop"
	})

    $liveDiagLogonSecSecurityBtn = CreateTabButton -Name "Smart Card" -container $logonSecBtnPanel -XPosition 210
    $liveDiagLogonSecSecurityBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Start"
        msrdDiagSmartCard
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagLogonSec -section msrdLiveDiagLogonSec -action "Stop"
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

    $liveDiagKnownIssuesBtn = CreateTabButton -Name "Run all" -container $issuesBtnPanel -XPosition 0
    $liveDiagKnownIssuesBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagIssues -section msrdLiveDiagIssues -action "Start"

        if ($global:msrdTarget -and ($global:msrdAVD -or $global:msrdW365)) { msrdDiagAVDIssueEvents }
        if ($global:msrdTarget -and ($global:msrdAVD -or $global:msrdRDS)) {
            msrdDiagRDLicensingIssueEvents
            msrdDiagRDGatewayIssueEvents
        }
        if ($global:msrdTarget) { msrdDiagRDIssueEvents }
        msrdDiagCommonIssueEvents
        if ($global:msrdTarget) { msrdDiagLogonIssues }

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagIssues -section msrdLiveDiagIssues -action "Stop"
	})

    $liveDiagKnownIssues5daysBtn = CreateTabButton -Name "Last 5 days" -container $issuesBtnPanel -XPosition 70
    $liveDiagKnownIssues5daysBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagIssues -section msrdLiveDiagIssues -action "Start"
        if ($global:msrdTarget -and ($global:msrdAVD -or $global:msrdW365)) { msrdDiagAVDIssueEvents }
        if ($global:msrdTarget -and ($global:msrdAVD -or $global:msrdW365)) {
            msrdDiagRDLicensingIssueEvents
            msrdDiagRDGatewayIssueEvents
        }
        if ($global:msrdTarget) { msrdDiagRDIssueEvents }
        msrdDiagCommonIssueEvents
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagIssues -section msrdLiveDiagIssues -action "Stop"
	})

    $liveDiagKnownIssuesLogonBtn = CreateTabButton -Name "Logon" -container $issuesBtnPanel -XPosition 140
    $liveDiagKnownIssuesLogonBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagIssues -section msrdLiveDiagIssues -action "Start"
        msrdDiagLogonIssues
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagIssues -section msrdLiveDiagIssues -action "Stop"
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

    $liveDiagOtherBtn = CreateTabButton -Name "Run all" -container $otherBtnPanel -XPosition 0
    $liveDiagOtherBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Start"

        if ($global:msrdTarget -and ($global:msrdAVD -or $global:msrdW365)) {
            msrdDiagOffice
            msrdDiagOD
        }
        msrdDiagPrinting
        msrdDiagCitrix3P

        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Stop"
	})

    $liveDiagOtherOfficeBtn = CreateTabButton -Name "Office" -container $otherBtnPanel -XPosition 70
    $liveDiagOtherOfficeBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Start"
        msrdDiagOffice
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Stop"
	})

    $liveDiagOtherODBtn = CreateTabButton -Name "OneDrive" -container $otherBtnPanel -XPosition 140
    $liveDiagOtherODBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Start"
        msrdDiagOD
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Stop"
	})

    $liveDiagOtherPrintingBtn = CreateTabButton -Name "Printing" -container $otherBtnPanel -XPosition 210
    $liveDiagOtherPrintingBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Start"
        msrdDiagPrinting
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Stop"
	})

    $liveDiagOtherCitrix3PBtn = CreateTabButton -Name "Citrix/3P" -container $otherBtnPanel -XPosition 280
    $liveDiagOtherCitrix3PBtn.Add_Click({
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Start"
        msrdDiagCitrix3P
        msrdLiveDiagSection -psBox $global:psBoxLiveDiagOther -section msrdLiveDiagOther -action "Stop"
	})
    #endregion LiveDiag

    $global:msrdForm.Controls.Add($global:msrdFormMenu)
    $global:msrdForm.MainMenuStrip = $global:msrdFormMenu
    $global:msrdForm.Controls.Add($buttonRibbon)

    $global:msrdForm.Add_Shown({

        $global:msrdPsBox.Focus()

        #check tools
        if ($global:avdnettestpath -eq "") {
            msrdAddOutputBoxLine ("$(msrdGetLocalizedText 'avdnettestNotFound')`n") -Color "Yellow"
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
            msrdAddOutputBoxLine "$(msrdGetLocalizedText 'autoUpdate') $(msrdGetLocalizedText 'disabled')"
        }

        msrdInitScript -Type GUI
        msrdInitHowTo
    })

    if ($ShowConsole -eq 1) { msrdStartShowConsole; $ConsoleMenuItem.Checked = $true } else { msrdStartHideConsole; $ConsoleMenuItem.Checked = $false }
    if ($global:msrdSilentMode -eq 1) { $SilentModeMenuItem.Checked = $true } else { $SilentModeMenuItem.Checked = $false }
    msrdRefreshUILang $global:msrdLangID

    $global:msrdForm.Add_Closing({
        $global:msrdLiveDiag = $false
        If (($Null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) { Remove-Item $global:msrdTempCommandErrorFile -Force | Out-Null }
        If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($False) | Out-Null }
    })

    $global:msrdForm.ShowDialog() | Out-Null
    msrdStartShowConsole -nocfg $true
}

Export-ModuleMember -Function msrdAddOutputBoxLine, msrdFindFolder, msrdAVDCollectGUI
# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBtumcq8YxNPOqI
# qbk/WKNYDCvjV5DGjzkdBuMzIRfpjqCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG5aRPH31Vv1Qf6nThnVK5vl
# t4pmEI0izsMeTgYmNHfdMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAwT/O6x5lSUW5gh+v+lz2EyOljy10vnqcrXg/osM9u0BpC60ra7M+Hi5q
# 1EAX6gqzJHr1voQfyBx8BjasTAg5G+nNoRytm112ZNaemtFJguwaH8o6vnYKgsLJ
# S+9jWulRxL1N8VpNZpRU/I0CAcrmrOAtSttkhOSzAeeObgsvzfP7Q1H7oqiOsRun
# b7pSiYa3YKH66nIk1o8ZjEMi4+wVM7qV6Ll/qxcA2vCBFxLlgm++cy0yDrzyKgnL
# mkRS6kYNLwfe+KVAVDCG4zWV4rsSCt4D06gf/dojF7rBilqkUBLPhYxPIxrHIvgt
# T44Jhp6xoXNnN9T5ASFwA/U6Q2eSk6GCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCBgPTclISyhsVj1ZiRovo1+4bIUwpPS0DVOZ8Gy419kLAIGZlPX9RgM
# GBMyMDI0MDYxMjE1MDA0MC4wODJaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
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
# IgQgO5kF4pRPBWmT/rXItHVsaATJnR27RU9+MSD4VObnEngwgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCCOPiOfDcFeEBBJAn/mC3MgrT5w/U2z81LYD44Hc34d
# ezCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB3p5I
# npafKEQ9AAEAAAHeMCIEIADg4pUha2+tmkZaUGNLbqkao2c16edPXDl4uEQ80Loj
# MA0GCSqGSIb3DQEBCwUABIICAKlgGsqICmvpXpXbgcwxFIXqBvAAuR0jMzIwQl+/
# Oo/x+X/mSrX+zpt1ZOfOlgCPl6RejfNRhGm/jNqGpj38KYOcu4Aa3DC7ZUd8WFgL
# lDlr27iFTg1UzQl8w/OMd5kMr7RlmUouLGpL/9/24Wb/Y1oqrKjYum+n6j8hO7qJ
# lwe99MTS9c03hpljqTpMflE01CZGDdFQKxRa2iRHsnget6NgMRmo0yE5mcuu/cun
# WViLwUhkcwRVfLxLtjq7Wepity7rCoZCoqxUGE7TEJaQiWTud8FlWE6p8FMgXEyZ
# Dk5DaGDe+NCbEDC9lP80gp6NY0/bmyfDUyCaW1sefeVzTFWR7dYFvs2YnsdcS/dG
# qaaaszZsTT29O2KK9u3RS5w9yq4NrNzHtUE/2gmOT2qCOpw2tmSkhC0jLGvhH9JT
# LMoqZF1+33slMtgcs51KN6zlUfQ209mJPf7VpV5I3tQXM1H7baZ68ieyvo0YGw3o
# DKzaNCxoKvVgrdKGrrCgc9HSRXTNpU0KNydRX1Bse1svX+uxaqqUJPY8OUhgKzxb
# v6ls5qWNb5s8DcoUdh/aoxUUqRLdigBiI7+FtTnWAi5uu8dhhlFspt5Vz6IVNzyX
# rtrkNGAilvmCCvUpdKszlXJuI5CJffgZ2xOSDb0DUIKIwHuL3q3X+9YzKC9hkbnV
# c25H
# SIG # End signature block
