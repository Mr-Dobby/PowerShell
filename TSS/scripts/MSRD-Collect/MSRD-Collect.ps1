<#
.SYNOPSIS
    Simplify data collection and diagnostics for troubleshooting Microsoft Remote Desktop (RDP/RDS/AVD/W365) related issues and a convenient method for submitting and following quick & easy action plans.

.DESCRIPTION
    This script is designed to gather information to assist Microsoft Customer Support Services (CSS) in troubleshooting issues you may be experiencing with Microsoft Remote Desktop solutions.
    The collected data may contain Personally Identifiable Information (PII) and/or sensitive data, such as (but not limited to) IP addresses, PC names and user names.
    The script will save the collected data in a subfolder and compress the results into a ZIP file.
    Neither the folder nor the ZIP file are automatically sent to Microsoft.
    You can send the ZIP file to Microsoft CSS using a secure file transfer tool. Please discuss this with your support professional and address any concerns you may have.
    Find our privacy statement here: https://privacy.microsoft.com/en-US/privacystatement

    Run 'Get-Help .\MSRD-Collect.ps1 -Full' for more details.

    USAGE SUMMARY:
    Run the script on Windows source or target machines as required by the scenario you're investigating.

    The script has multiple module (.psm1) files located in a "Modules" folder. This folder, along with its underlying .psm1 files, must remain in the same folder as the main MSRD-Collect.ps1 file for the script to function correctly. Download the MSRD-Collect.zip package from the official public download location (https://aka.ms/MSRD-Collect) and extract all files from it, not just the MSRD-Collect.ps1.
    The script will import the necessary module(s) dynamically when specific data is being invoked. Manual import of the modules is not required.

    When launched without any command line parameters, the script will start in GUI mode where you can select one or more data collection or diagnostics scenarios.
    If you prefer to run the script without a GUI or to automate data collection/diagnostics, use command line parameters.
    Diagnostics will run regardless if other data collection scenarios have been selected.

    For more information see the MSRD-Collect-ReadMe.txt file.

.NOTES
    Author           : Robert Klemencz (Microsoft CSS)
    Requires         : At least PowerShell version 5.1 and to be run elevated
    Version          : See: $global:msrdVersion

.LINK
    Download: https://aka.ms/MSRD-Collect
    Feedback: https://aka.ms/MSRD-Collect-Feedback

.PARAMETER Machine
    Indicates the context/environment in which the machine is used. This is a mandatory parameter when not using the GUI.
    Based on the provided value, only data specific to that context/environment will be collected.
    Available values are:
        isAVD      : Azure Virtual Desktop
        isRDS      : Remote Desktop Services or direct (non-AVD/non-W365) RDP connection
        isW365     : Windows 365 Cloud PC

.PARAMETER Role
    Indicates the role of the machine in the given context/environment. This is a mandatory parameter when not using the GUI.
    Based on the provided value, only data specific to that role will be collected.
    Available values are:
        isSource   : Source machine from where you connect to other machines using a Remote Desktop client
        isTarget   : Target machine to which you connect to or a server with any RDS role installed

.PARAMETER Core
    Collect general data for troubleshooting AVD/RDS/W365 issues. Diagnostics will run at the end.

.PARAMETER Profiles
    Collect Core + specific data for troubleshooting 'User Profiles' issues. Diagnostics will run at the end.

.PARAMETER Activation
    Collect Core + specific data for troubleshooting 'OS Licensing/Activation' issues. Diagnostics will run at the end.

.PARAMETER MSRA
    Collect Core + specific data for troubleshooting 'Remote Assistance/Quick Assist/Remote Help' issues. Diagnostics will run at the end.

.PARAMETER SCard
    Collect Core + specific data for troubleshooting 'Smart Card' issues. Diagnostics will run at the end.

.PARAMETER IME
    Collect Core + specific data for troubleshooting 'Input Method' issues. Diagnostics will run at the end.

.PARAMETER Teams
    Collect Core + specific data for troubleshooting 'Teams Media Optimization' issues. Diagnostics will run at the end. (AVD/W365 only)

.PARAMETER MSIXAA
    [Deprecated, please use 'AppAttach' instead] Collect Core + specific data for troubleshooting 'App Attach' issues. Diagnostics will run at the end. (AVD ony)

.PARAMETER AppAttach
    Collect Core + specific data for troubleshooting 'App Attach' issues. Diagnostics will run at the end. (AVD only)

.PARAMETER HCI
    Collect Core + specific data for troubleshooting 'Azure Stack HCI' issues. Diagnostics will run at the end. (AVD only)

.PARAMETER DumpPID
    Collect Core + a process dump based on the provided PID. Diagnostics will run at the end.

.PARAMETER NetTrace
    Collect a network trace.

.PARAMETER DiagOnly
    Skip collecting troubleshooting data (even if any other parameters are specificed) and only perform diagnostics.

.PARAMETER AcceptEula
    Silently accept the Microsoft Diagnostic Tools End User License Agreement.

.PARAMETER AcceptNotice
    Silently accept the Important Notice message displayed when the script is launched.

.PARAMETER OutputDir
    ​​​​​​Specify an existing directory where to store the collected files. By default, the script will store the collected data under "C:\MS_DATA".

.PARAMETER UserContext
    Specify the username in whose context some of the data (e.g. RDClientAutoTrace, Teams settings) will be collected. By default, the script will use the admin's username who launched it.

.PARAMETER SkipAutoUpdate
    Skip the automatic update check on launch for the current instance of the script (can be used for both GUI and command line mode).

.PARAMETER LiteMode
    The script will open with a "Lite Mode" UI, regardless of the Config\MSRDC-Config.cfg settings.

.PARAMETER AssistMode
    The script will read out loud some of the key information and steps performed during data collection/diagnostics.

.PARAMETER SilentMode
    Verbose output (detailed steps or encountered errors) will not be displayed during data collection.

.OUTPUTS
    By default, all collected data are stored in a subfolder under C:\MS_DATA. You can change this location by using the "-OutputDir" command line parameter or from the "Advanced Mode" UI.
#>

param ([ValidateSet('isAVD', 'isRDS', 'isW365')][string]$Machine, [ValidateSet('isSource', 'isTarget')][string]$Role,
    [switch]$Core = $false, [switch]$Profiles = $false, [switch]$Activation = $false, [switch]$MSRA = $false, [switch]$SCard = $false, [switch]$IME = $false,
    [switch]$Teams = $false, [switch]$MSIXAA = $false, [switch]$AppAttach = $false, [switch]$HCI = $false, [int]$DumpPID, [switch]$DiagOnly = $false, [switch]$NetTrace = $false,
    [switch]$AcceptEula, [switch]$AcceptNotice = $false, [switch]$SkipAutoUpdate = $false, [switch]$LiteMode = $false, [switch]$AudioAssistMode = $false, [switch]$SilentMode = $false,
    [ValidateScript({
        if (Test-Path $_ -PathType Container) { $true } else { throw "Invalid folder path. '$_' does not exist or is not a valid folder." }
    })][string]$OutputDir,
    [ValidateScript({
        $profilePath = Join-Path (Split-Path $env:USERPROFILE) $_
        if (Test-Path -Path $profilePath -PathType Container) { $true } else { throw "Invalid username. A local profile folder for user '$_' does not exist or could not be accessed." }
    })][string]$UserContext)


#Check if the current user is an administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Warning "This script needs to be run as Administrator"
    Exit 1
}

#Check if the script is running in PowerShell ISE
if ($host.Name -eq "Windows PowerShell ISE Host") {
	Write-Warning "Running MSRD-Collect in PowerShell ISE is not supported. Please run it from a regular elevated PowerShell console."
	Exit 1
}

#Check PS Version
$OSVersion = [environment]::OSVersion.Version
If($PSVersionTable.PSVersion.Major -le 4) {
	Write-Warning "MSRD-Collect requires at least PowerShell version 5.1."
	Write-Warning "... running on OS version: $OSVersion with PowerShell version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
	Write-Warning "Please update your PowerShell version to version 5.1 or higher!"
    $host.ui.RawUI.ForegroundColor = "Cyan"
	Write-Output "`nSee: https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-5.1`n`n"
    $host.ui.RawUI.ForegroundColor = $global:msrdConsoleColor
    Exit 1
}

#Check if the 'Modules' folder exists in the script folder
if (-not (Test-Path -Path "$PSScriptRoot\Modules" -PathType Container)) {
    Write-Warning "The 'Modules' folder is missing from the script folder. Please make sure that you have extracted all the files from the ZIP archive and that you launch MSRD-Collect.ps1 from within the same folder that contains the script's 'Modules' subfolder. See MSRD-Collect-ReadMe.txt for more details."
    Exit 1
}

#Unlock module files if valid
$fileNamesToUnblock = @(
    "MSRDC-Activation.psm1", "MSRDC-Core.psm1", "MSRDC-Diagnostics.psm1", "MSRDC-FwFunctions.psm1", "MSRDC-FwGUI.psm1",
    "MSRDC-FwGUILite.psm1", "MSRDC-FwHtml.psm1", "MSRDC-HCI.psm1", "MSRDC-IME.psm1", "MSRDC-AppAttach.psm1", "MSRDC-MSRA.psm1", "MSRDC-Profiles.psm1",
    "MSRDC-SCard.psm1", "MSRDC-Teams.psm1", "MSRDC-Tracing.psm1", "MSRDC-WU.psm1"
)
Get-ChildItem -Recurse -Path $global:msrdScriptpath\Modules\MSRDC*.psm1 | ForEach-Object {
    if ($_.Name -in $fileNamesToUnblock) {
        Try {
            Unblock-File $_.FullName -Confirm:$false -ErrorAction Stop
        } Catch {
            Write-Warning "Failed to unblock file: $($_.FullName) - $($_.Exception.Message)"
        }
    }
}

#Limiting scenarios for command line
if (($Role -eq "isSource") -and ($Profiles -or $Activation -or $IME -or $Teams -or $MSIXAA -or $AppAttach -or $HCI)) {
        Write-Warning "Machine role 'isSource' only supports the following scenarios: -Core, -MSRA, -SCard, -DumpPID, -DiagOnly, -NetTrace. Adjust the command line and try again."
        Exit 1
}

if ($Role -eq "isTarget") {
    if (($Machine -eq "isRDS") -and ($Teams -or $MSIXAA -or $AppAttach -or $HCI)) {
        Write-Warning "Machine type 'isRDS' with machine role 'isTarget' only supports the following scenarios: -Core, -Profiles, -Activation, -MSRA, -SCard, -IME, -DumpPID, -DiagOnly, -NetTrace. Adjust the command line and try again."
        Exit 1
    } elseif (($Machine -eq "isW365") -and ($MSIXAA -or $AppAttach -or $HCI)) {
        Write-Warning "Machine type 'isW365' with machine role 'isTarget' only supports the following scenarios: -Core, -Profiles, -Activation, -MSRA, -SCard, -IME, -Teams, -DumpPID, -DiagOnly, -NetTrace. Adjust the command line and try again."
        Exit 1
    }
}

if ($MSIXAA) {
    if ($AppAttach) {
		Write-Warning "You are using both '-MSIXAA' and '-AppAttach' command line parameters together. The command line parameter '-MSIXAA' is deprecated and has been replaced by '-AppAttach'. '-MSIXAA' will be ignored and the script will continue using '-AppAttach' only. Start using '-AppAttach' going forward when troubleshooting issues with either the legacy AVD 'MSIX App Attach' or the new AVD 'App Attach'. The '-MSIXAA' command line parameter will be removed in a future script version."
        $MSIXAA = $false
	} else {
        Write-Warning "The command line parameter '-MSIXAA' is deprecated and has been replaced by '-AppAttach'. This time the script will continue using it (similar to '-AppAttach'), but start using '-AppAttach' going forward when troubleshooting issues with either the legacy AVD 'MSIX App Attach' or the new AVD 'App Attach'. The '-MSIXAA' command line parameter will be removed in a future script version."
    }
}


###Global variables
$global:msrdVersion = "240517.4"
$global:msrdDevLevel = "Prod"
$global:msrdScriptpath = $PSScriptRoot
$global:msrdConsoleColor = $host.ui.RawUI.ForegroundColor
$global:msrdVersioncheck = $false
$global:msrdGUI = $false
$global:msrdLiveDiag = $false
$global:msrdProgress = 0
$global:msrdTSSinUse = $MyInvocation.PSCommandPath -like "*TSS_UEX.psm1"
if ($PSSenderInfo) { $global:msrdCmdLine = "n/a" } else { $global:msrdCmdLine = $MyInvocation.Line } #for selfupdate restart
$global:msrdOSVer = (Get-CimInstance Win32_OperatingSystem).Caption
$global:msrdFQDN = [System.Net.Dns]::GetHostByName($env:computerName).HostName
$global:msrdCollecting = $False
$global:msrdDiagnosing = $False


#Check if the included tools are available and valid
if ($global:msrdTSSinUse) {
    $global:msrdToolsFolder = "$global:ScriptFolder\BIN"

    if (Test-Path -Path "$global:msrdToolsFolder\avdnettest.exe") {
        $global:avdnettestpath = "$global:msrdToolsFolder\avdnettest.exe"
    } else {
        $global:avdnettestpath = ""
    }

    if (Test-Path -Path "$global:msrdToolsFolder\procdump.exe") {
        $global:msrdProcDumpExe = "$global:msrdToolsFolder\procdump.exe"
    } else {
        $global:msrdProcDumpExe = ""
    }

    if (Test-Path -Path "$global:msrdToolsFolder\psping.exe") {
        $global:msrdPsPingExe = "$global:msrdToolsFolder\psping.exe"
    } else {
        $global:msrdPsPingExe = ""
    }

} else {
    $global:msrdToolsFolder = "$global:msrdScriptpath\Tools"
    if (Test-Path -Path "$global:msrdToolsFolder\avdnettest.exe") {
        $global:avdnettestpath = "$global:msrdToolsFolder\avdnettest.exe"
    } else {
        $tssToolsFolder = $global:msrdScriptpath -ireplace [regex]::Escape("\scripts\MSRD-Collect"), "\BIN"
        if (Test-Path -Path "$tssToolsFolder\avdnettest.exe") {
            $global:msrdToolsFolder = "$tssToolsFolder\"
            $global:avdnettestpath = "$tssToolsFolder\avdnettest.exe"
        } else {
            $global:avdnettestpath = ""
        }
    }

    $global:msrdToolsFolder = "$global:msrdScriptpath\Tools"
    if (Test-Path -Path "$global:msrdToolsFolder\procdump.exe") {
        $global:msrdProcDumpExe = "$global:msrdToolsFolder\procdump.exe"
    } else {
        $tssToolsFolder = $global:msrdScriptpath -ireplace [regex]::Escape("\scripts\MSRD-Collect"), "\BIN"
        if (Test-Path -Path "$tssToolsFolder\procdump.exe") {
            $global:msrdToolsFolder = "$tssToolsFolder\"
            $global:msrdProcDumpExe = "$tssToolsFolder\procdump.exe"
        } else {
            $global:msrdProcDumpExe = ""
        }
    }

    $global:msrdToolsFolder = "$global:msrdScriptpath\Tools"
    if (Test-Path -Path "$global:msrdToolsFolder\psping.exe") {
        $global:msrdPsPingExe = "$global:msrdToolsFolder\psping.exe"
    } else {
        $tssToolsFolder = $global:msrdScriptpath -ireplace [regex]::Escape("\scripts\MSRD-Collect"), "\BIN"
        if (Test-Path -Path "$tssToolsFolder\psping.exe") {
            $global:msrdToolsFolder = "$tssToolsFolder\"
            $global:msrdPsPingExe = "$tssToolsFolder\psping.exe"
        } else {
            $global:msrdPsPingExe = ""
        }
    }
}

function msrdVerifyToolsSignature {
	Param ($filepath)

    try {
	    $signature = Get-AuthenticodeSignature -FilePath $filepath -ErrorAction SilentlyContinue
	    $cert = $signature.SignerCertificate
	    $issuer = $cert.Issuer

	    if ($signature.Status -ne "Valid") {
		    Write-Warning "'$filepath' does not have a valid signature. Stopping script execution. Make sure you download and unpack the full package of MSRD-Collect or TSS only from the official download locations."
		    Exit 1
	    }

	    if (($issuer -ne "CN=Microsoft Code Signing PCA 2011, O=Microsoft Corporation, L=Redmond, S=Washington, C=US") -and ($issuer -ne "CN=Microsoft Windows Production PCA 2011, O=Microsoft Corporation, L=Redmond, S=Washington, C=US") -and ($issuer -ne "CN=Microsoft Code Signing PCA, O=Microsoft Corporation, L=Redmond, S=Washington, C=US") -and ($issuer -ne "CN=Microsoft Code Signing PCA 2010, O=Microsoft Corporation, L=Redmond, S=Washington, C=US") -and ($issuer -ne "CN=Microsoft Development PCA 2014, O=Microsoft Corporation, L=Redmond, S=Washington, C=US")) {
		    Write-Warning "'$filepath' does not have a valid signature. Stopping script execution. Make sure you download and unpack the full package of MSRD-Collect or TSS only from the official download locations."
		    Exit 1
	    }
    } catch {
		Write-Warning "Failed to verify the signature of '$filepath'. Stopping script execution. Make sure you download and unpack the full package of MSRD-Collect or TSS only from the official download locations."
		Exit 1
    }
}

if ($global:avdnettestpath -ne "") { msrdVerifyToolsSignature $global:avdnettestpath }
if ($global:msrdProcDumpExe -ne "") { msrdVerifyToolsSignature $global:msrdProcDumpExe }
if ($global:msrdPsPingExe -ne "") { msrdVerifyToolsSignature $global:msrdPsPingExe }


#Read config file
$msrdConfigFile = "$global:msrdScriptpath\Config\MSRDC-Config.cfg"
if (Test-Path -Path $msrdConfigFile) {
	try {
		$msrdConfigData = Get-Content $msrdConfigFile | Out-String
        $msrdConfig = ConvertFrom-StringData $msrdConfigData
	} catch {
		Write-Warning "Could not read the Config\MSRDC-Config.cfg config file. Please make sure that the file exists and that it is not corrupted. Exiting."
		Exit 1
	}
} else {
	Write-Warning "Could not find the Config\MSRDC-Config.cfg config file. Please make sure that the file exists and that it is not corrupted. Exiting."
	Exit 1
}

if ($global:msrdProcDumpExe -eq "") {
    $global:msrdProcDumpVer = "1.0"
} else {
    if ($msrdConfig.ProcDumpVersion -match "\d{2}\.\d{1}$") {
        $global:msrdProcDumpVer = $msrdConfig.ProcDumpVersion
    } else {
		Write-Warning "Unsupported value found for 'ProcDumpVersion' in Config\MSRDC-Config.cfg. The value has to be of format XY.Z, where X, Y and Z are numbers (e.g. 11.0). Exiting."
		Exit 1
	}
}

if ($global:msrdPsPingExe -eq "") {
    $global:msrdPsPingVer = "1.0"
} else {
    if ($msrdConfig.PsPingVersion -match "\d{1}\.\d{2}$") {
        $global:msrdPsPingVer = $msrdConfig.PsPingVersion
    } else {
		Write-Warning "Unsupported value found for 'PsPingVersion' in Config\MSRDC-Config.cfg. The value has to be of format X.YZ, where X, Y and Z are numbers (e.g. 2.12). Exiting."
		Exit 1
	}
}

if (@(0, 1) -contains $msrdConfig.ShowConsoleWindow) {
    $msrdShowConsole = $msrdConfig.ShowConsoleWindow
} else {
    Write-Warning "Unsupported value found for 'ShowConsoleWindow' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	Exit 1
}

if (@(0, 1) -contains $msrdConfig.MaximizeWindow) {
    $msrdMaximizeWindow = $msrdConfig.MaximizeWindow
} else {
    Write-Warning "Unsupported value found for 'MaximizeWindow' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	Exit 1
}

if (@("AR","CN","CS","DE","EN","ES","FR","HU","NL","IT","JP","PT","RO","TR") -contains $msrdConfig.UILanguage) {
    $global:msrdLangID = $msrdConfig.UILanguage
} else {
    Write-Warning "Unsupported value found for 'UILanguage' in Config\MSRDC-Config.cfg. Supported values are AR, CN, CS, DE, EN, ES, FR, HU, NL, IT, JP, PT, RO or TR. Exiting."
	Exit 1
}

if (@(0, 1) -contains $msrdConfig.PlaySounds) {
    $global:msrdPlaySounds = $msrdConfig.PlaySounds
} else {
	Write-Warning "Unsupported value found for 'PlaySounds' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	Exit 1
}

if (@(10, 12, 14, 16) -contains $msrdConfig.PsBoxFont) {
    $global:msrdPsBoxFont = $msrdConfig.PsBoxFont
} else {
	Write-Warning "Unsupported value found for 'PsBoxFont' in Config\MSRDC-Config.cfg. Supported values are 10, 12, 14 or 16. Exiting."
	Exit 1
}

if (-not $global:msrdTSSinUse) {
    if ($LiteMode) {
        $msrdGUILite = 1
    } else {
        if (@(0, 1) -contains $msrdConfig.UILiteMode) {
            $msrdGUILite = $msrdConfig.UILiteMode
        } else {
            Write-Warning "Unsupported value found for 'UILiteMode' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	        Exit 1
        }
    }

    if ($AudioAssistMode) {
        $global:msrdAudioAssistMode = 1
    } else {
        if (@(0, 1) -contains $msrdConfig.AudioAssistMode) {
            $global:msrdAudioAssistMode = $msrdConfig.AudioAssistMode
        } else {
		    Write-Warning "Unsupported value found for 'AudioAssistMode' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	        Exit 1
	    }
    }
}

#Silent mode init
if (-not $global:msrdTSSinUse) {
    if ($global:msrdAudioAssistMode -eq 1) {
        $global:msrdSilentMode = 0
    } else {
        if ($SilentMode) {
	        $global:msrdSilentMode = 1
        } else {
            if (@(0, 1) -contains $msrdConfig.SilentMode) {
                $global:msrdSilentMode = $msrdConfig.SilentMode
            } else {
                Write-Warning "Unsupported value found for 'SilentMode' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	            Exit 1
            }
        }
    }
}

# Check if auto update check should be performed
if ($SkipAutoUpdate) {
    $global:msrdAutoVerCheck = 0
    Write-Output "SkipAutoUpdate switch specified, automatic update check on script launch will be skipped"
} else {

    if (@(0, 1) -contains $msrdConfig.AutomaticVersionCheck) {
        $global:msrdAutoVerCheck = $msrdConfig.AutomaticVersionCheck
    } else {
		Write-Warning "Unsupported value found for 'AutomaticVersionCheck' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	    Exit 1
	}

    if (@(0, 1) -contains $msrdConfig.ScriptSelfUpdate) {
        $global:msrdScriptSelfUpdate = $msrdConfig.ScriptSelfUpdate
    } else {
        Write-Warning "Unsupported value found for 'ScriptSelfUpdate' in Config\MSRDC-Config.cfg. Supported values are 0 or 1. Exiting."
	    Exit 1
    }
}


#Localization init
$localizationFilePath = Join-Path $global:msrdScriptpath "Config\Localization\MSRDC-Fw$($global:msrdLangID).xml"

if (Test-Path -Path $localizationFilePath) {
	try {
		[xml] $global:msrdLangText = Get-Content -Path $localizationFilePath -Encoding UTF8 -ErrorAction Stop

        # Create a hashtable to store the mappings
        $global:msrdTextHashtable = @{}

        # Populate the hashtable
        foreach ($langNode in $global:msrdLangText.LangV1.lang) {
            $textID = $langNode.id
            $message = $langNode."#text"
            if ($message -like "*&amp;*") {
                $message = $message.replace("&amp;", "&")
            }
            $global:msrdTextHashtable[$textID] = $message
        }
	}
	catch {
		Write-Warning "Could not read the Config\Localization\MSRDC-Fw$($global:msrdLangID).xml file: $_. Please make sure that the file exists and that it is not corrupted."
		Exit 1
	}
} else {
	Write-Warning "Could not find the Config\Localization\MSRDC-Fw$($global:msrdLangID).xml file. Please make sure that the file exists and that it is not corrupted."
	Exit 1
}

#Output folder init
If ($OutputDir) {
    $global:msrdLogRoot = $OutputDir
} else {
    if ($global:msrdTSSinUse) { $global:msrdLogRoot = $global:LogFolder } else { $global:msrdLogRoot = "C:\MS_DATA" }
}

#User context init
if ($UserContext) { $global:msrdUserprof = $UserContext } else { $global:msrdUserprof = $env:USERNAME }


[void][System.Reflection.Assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')

#Main functions init
Import-Module -Name "$PSScriptRoot\Modules\MSRDC-FwFunctions" -DisableNameChecking -Force -Scope Global

# check if the current user is domain admin vs local admin
try {
    $userIsDomainAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Domain Admins')
    if ($userIsDomainAdmin) {
        $global:msrdAdminlevel = "Domain Admin"
    } else {
        $global:msrdAdminlevel = "Local Admin"
    }
} catch {
    $global:msrdAdminlevel = "Local Admin"
    Write-Warning "Failed to determine administrative privileges: $($_.Exception.InnerException.Message)Defaulting to 'Local Admin'. If you need to collect Domain related information, make sure that the user running the script is a member of the 'Domain Admins' group and that a Domain Controller is reachable over the network."
}


# EULA
function msrdShowEULAPopup($mode) {
    $EULA = New-Object -TypeName System.Windows.Forms.Form
    $richTextBox1 = New-Object System.Windows.Forms.RichTextBox
    $btnAcknowledge = New-Object System.Windows.Forms.Button
    $btnCancel = New-Object System.Windows.Forms.Button

    $EULA.SuspendLayout()
    $EULA.Name = "EULA"
    $EULA.Text = "Microsoft Diagnostic Tools End User License Agreement"

    $richTextBox1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $richTextBox1.Location = New-Object System.Drawing.Point(12,12)
    $richTextBox1.Name = "richTextBox1"
    $richTextBox1.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $richTextBox1.Size = New-Object System.Drawing.Size(776, 397)
    $richTextBox1.TabIndex = 0
    $richTextBox1.ReadOnly=$True
    $richTextBox1.Add_LinkClicked({Start-Process -FilePath $_.LinkText})
    $richTextBox1.Rtf = @"
{\rtf1\ansi\ansicpg1252\deff0\nouicompat{\fonttbl{\f0\fswiss\fprq2\fcharset0 Segoe UI;}{\f1\fnil\fcharset0 Calibri;}{\f2\fnil\fcharset0 Microsoft Sans Serif;}}
{\colortbl ;\red0\green0\blue255;}
{\*\generator Riched20 10.0.19041}{\*\mmathPr\mdispDef1\mwrapIndent1440 }\viewkind4\uc1
\pard\widctlpar\f0\fs19\lang1033 MICROSOFT SOFTWARE LICENSE TERMS\par
Microsoft Diagnostic Scripts and Utilities\par
\par
{\pict{\*\picprop}\wmetafile8\picw26\pich26\picwgoal32000\pichgoal15
0100090000035000000000002700000000000400000003010800050000000b0200000000050000
000c0202000200030000001e000400000007010400040000000701040027000000410b2000cc00
010001000000000001000100000000002800000001000000010000000100010000000000000000
000000000000000000000000000000000000000000ffffff00000000ff040000002701ffff0300
00000000
}These license terms are an agreement between you and Microsoft Corporation (or one of its affiliates). IF YOU COMPLY WITH THESE LICENSE TERMS, YOU HAVE THE RIGHTS BELOW. BY USING THE SOFTWARE, YOU ACCEPT THESE TERMS.\par
{\pict{\*\picprop}\wmetafile8\picw26\pich26\picwgoal32000\pichgoal15
0100090000035000000000002700000000000400000003010800050000000b0200000000050000
000c0202000200030000001e000400000007010400040000000701040027000000410b2000cc00
010001000000000001000100000000002800000001000000010000000100010000000000000000
000000000000000000000000000000000000000000ffffff00000000ff040000002701ffff0300
00000000
}\par
\pard
{\pntext\f0 1.\tab}{\*\pn\pnlvlbody\pnf0\pnindent0\pnstart1\pndec{\pntxta.}}
\fi-360\li360 INSTALLATION AND USE RIGHTS. Subject to the terms and restrictions set forth in this license, Microsoft Corporation (\ldblquote Microsoft\rdblquote ) grants you (\ldblquote Customer\rdblquote  or \ldblquote you\rdblquote ) a non-exclusive, non-assignable, fully paid-up license to use and reproduce the script or utility provided under this license (the "Software"), solely for Customer\rquote s internal business purposes, to help Microsoft troubleshoot issues with one or more Microsoft products, provided that such license to the Software does not include any rights to other Microsoft technologies (such as products or services). \ldblquote Use\rdblquote  means to copy, install, execute, access, display, run or otherwise interact with the Software. \par
\pard\widctlpar\par
\pard\widctlpar\li360 You may not sublicense the Software or any use of it through distribution, network access, or otherwise. Microsoft reserves all other rights not expressly granted herein, whether by implication, estoppel or otherwise. You may not reverse engineer, decompile or disassemble the Software, or otherwise attempt to derive the source code for the Software, except and to the extent required by third party licensing terms governing use of certain open source components that may be included in the Software, or remove, minimize, block, or modify any notices of Microsoft or its suppliers in the Software. Neither you nor your representatives may use the Software provided hereunder: (i) in a way prohibited by law, regulation, governmental order or decree; (ii) to violate the rights of others; (iii) to try to gain unauthorized access to or disrupt any service, device, data, account or network; (iv) to distribute spam or malware; (v) in a way that could harm Microsoft\rquote s IT systems or impair anyone else\rquote s use of them; (vi) in any application or situation where use of the Software could lead to the death or serious bodily injury of any person, or to physical or environmental damage; or (vii) to assist, encourage or enable anyone to do any of the above.\par
\par
\pard\widctlpar\fi-360\li360 2.\tab DATA. Customer owns all rights to data that it may elect to share with Microsoft through using the Software. You can learn more about data collection and use in the help documentation and the privacy statement at {{\field{\*\fldinst{HYPERLINK https://aka.ms/privacy }}{\fldrslt{https://aka.ms/privacy\ul0\cf0}}}}\f0\fs19 . Your use of the Software operates as your consent to these practices.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 3.\tab FEEDBACK. If you give feedback about the Software to Microsoft, you grant to Microsoft, without charge, the right to use, share and commercialize your feedback in any way and for any purpose.\~ You will not provide any feedback that is subject to a license that would require Microsoft to license its software or documentation to third parties due to Microsoft including your feedback in such software or documentation. \par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 4.\tab EXPORT RESTRICTIONS. Customer must comply with all domestic and international export laws and regulations that apply to the Software, which include restrictions on destinations, end users, and end use. For further information on export restrictions, visit {{\field{\*\fldinst{HYPERLINK https://aka.ms/exporting }}{\fldrslt{https://aka.ms/exporting\ul0\cf0}}}}\f0\fs19 .\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360\qj 5.\tab REPRESENTATIONS AND WARRANTIES. Customer will comply with all applicable laws under this agreement, including in the delivery and use of all data. Customer or a designee agreeing to these terms on behalf of an entity represents and warrants that it (i) has the full power and authority to enter into and perform its obligations under this agreement, (ii) has full power and authority to bind its affiliates or organization to the terms of this agreement, and (iii) will secure the permission of the other party prior to providing any source code in a manner that would subject the other party\rquote s intellectual property to any other license terms or require the other party to distribute source code to any of its technologies.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360\qj 6.\tab DISCLAIMER OF WARRANTY. THE SOFTWARE IS PROVIDED \ldblquote AS IS,\rdblquote  WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL MICROSOFT OR ITS LICENSORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\par
\pard\widctlpar\qj\par
\pard\widctlpar\fi-360\li360\qj 7.\tab LIMITATION ON AND EXCLUSION OF DAMAGES. IF YOU HAVE ANY BASIS FOR RECOVERING DAMAGES DESPITE THE PRECEDING DISCLAIMER OF WARRANTY, YOU CAN RECOVER FROM MICROSOFT AND ITS SUPPLIERS ONLY DIRECT DAMAGES UP TO U.S. $5.00. YOU CANNOT RECOVER ANY OTHER DAMAGES, INCLUDING CONSEQUENTIAL, LOST PROFITS, SPECIAL, INDIRECT, OR INCIDENTAL DAMAGES. This limitation applies to (i) anything related to the Software, services, content (including code) on third party Internet sites, or third party applications; and (ii) claims for breach of contract, warranty, guarantee, or condition; strict liability, negligence, or other tort; or any other claim; in each case to the extent permitted by applicable law. It also applies even if Microsoft knew or should have known about the possibility of the damages. The above limitation or exclusion may not apply to you because your state, province, or country may not allow the exclusion or limitation of incidental, consequential, or other damages.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 8.\tab BINDING ARBITRATION AND CLASS ACTION WAIVER. This section applies if you live in (or, if a business, your principal place of business is in) the United States.  If you and Microsoft have a dispute, you and Microsoft agree to try for 60 days to resolve it informally. If you and Microsoft can\rquote t, you and Microsoft agree to binding individual arbitration before the American Arbitration Association under the Federal Arbitration Act (\ldblquote FAA\rdblquote ), and not to sue in court in front of a judge or jury. Instead, a neutral arbitrator will decide. Class action lawsuits, class-wide arbitrations, private attorney-general actions, and any other proceeding where someone acts in a representative capacity are not allowed; nor is combining individual proceedings without the consent of all parties. The complete Arbitration Agreement contains more terms and is at {{\field{\*\fldinst{HYPERLINK https://aka.ms/arb-agreement-4 }}{\fldrslt{https://aka.ms/arb-agreement-4\ul0\cf0}}}}\f0\fs19 . You and Microsoft agree to these terms. \par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 9.\tab LAW AND VENUE. If U.S. federal jurisdiction exists, you and Microsoft consent to exclusive jurisdiction and venue in the federal court in King County, Washington for all disputes heard in court (excluding arbitration). If not, you and Microsoft consent to exclusive jurisdiction and venue in the Superior Court of King County, Washington for all disputes heard in court (excluding arbitration).\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 10.\tab ENTIRE AGREEMENT. This agreement, and any other terms Microsoft may provide for supplements, updates, or third-party applications, is the entire agreement for the software.\par
\pard\sa200\sl276\slmult1\f1\fs22\lang9\par
\pard\f2\fs17\lang2057\par
}
"@
    $richTextBox1.BackColor = [System.Drawing.Color]::White
    $btnAcknowledge.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnAcknowledge.Location = New-Object System.Drawing.Point(544, 415)
    $btnAcknowledge.Name = "btnAcknowledge";
    $btnAcknowledge.Size = New-Object System.Drawing.Size(119, 23)
    $btnAcknowledge.TabIndex = 1
    $btnAcknowledge.Text = "Accept"
    $btnAcknowledge.UseVisualStyleBackColor = $True
    $btnAcknowledge.Add_Click({$EULA.DialogResult=[System.Windows.Forms.DialogResult]::Yes})

    $btnCancel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnCancel.Location = New-Object System.Drawing.Point(669, 415)
    $btnCancel.Name = "btnCancel"
    $btnCancel.Size = New-Object System.Drawing.Size(119, 23)
    $btnCancel.TabIndex = 2
    if($mode -ne 0)
    {
	    $btnCancel.Text = "Close"
    }
    else
    {
	    $btnCancel.Text = "Decline"
    }
    $btnCancel.UseVisualStyleBackColor = $True
    $btnCancel.Add_Click({$EULA.DialogResult=[System.Windows.Forms.DialogResult]::No})

    $EULA.AutoScaleDimensions = New-Object System.Drawing.SizeF(6.0, 13.0)
    $EULA.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    $EULA.ClientSize = New-Object System.Drawing.Size(800, 450)
    $EULA.Controls.Add($btnCancel)
    $EULA.Controls.Add($richTextBox1)
    if($mode -ne 0)
    {
	    $EULA.AcceptButton=$btnCancel
    }
    else
    {
        $EULA.Controls.Add($btnAcknowledge)
	    $EULA.AcceptButton=$btnAcknowledge
        $EULA.CancelButton=$btnCancel
    }
    $EULA.ResumeLayout($false)
    $EULA.Size = New-Object System.Drawing.Size(800, 650)

    Return ($EULA.ShowDialog())
}

function msrdShowEULAIfNeeded($toolName, $mode) {
	$eulaRegPath = "HKCU:Software\Microsoft\CESDiagnosticTools"
	$eulaAccepted = "No"
	$eulaValue = $toolName + " EULA Accepted"
	if(Test-Path $eulaRegPath)
	{
		$eulaRegKey = Get-Item $eulaRegPath
		$eulaAccepted = $eulaRegKey.GetValue($eulaValue, "No")
	}
	else
	{
		$eulaRegKey = New-Item $eulaRegPath
	}
	if($mode -eq 2) # silent accept
	{
		$eulaAccepted = "Yes"
       		$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
	}
	else
	{
		if($eulaAccepted -eq "No")
		{
			$eulaAccepted = msrdShowEULAPopup($mode)
			if($eulaAccepted -eq [System.Windows.Forms.DialogResult]::Yes)
			{
	        		$eulaAccepted = "Yes"
	        		$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
			}
		}
	}
	return $eulaAccepted
}


function msrdCleanUpandExit {
    if (($null -ne $global:msrdTempCommandErrorFile) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) {
        Remove-Item -Path $global:msrdTempCommandErrorFile -Force -ErrorAction SilentlyContinue
    }

    if ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($false) | Out-Null }
    if ($global:msrdForm) { $global:msrdForm.Close() }
    Exit
}

# This function disable quick edit mode. If the mode is enabled, console output will hang when key input or strings are selected.
# So disable the quick edit mode during running script and re-enable it after script is finished.
$QuickEditCode=@"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Runtime.InteropServices;


public static class msrdDisableConsoleQuickEdit
{

    const uint ENABLE_QUICK_EDIT = 0x0040;

    // STD_INPUT_HANDLE (DWORD): -10 is the standard input device.
    const int STD_INPUT_HANDLE = -10;

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll")]
    static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

    [DllImport("kernel32.dll")]
    static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

    public static bool SetQuickEdit(bool SetEnabled)
    {

        IntPtr consoleHandle = GetStdHandle(STD_INPUT_HANDLE);

        // get current console mode
        uint consoleMode;
        if (!GetConsoleMode(consoleHandle, out consoleMode))
        {
            // ERROR: Unable to get console mode.
            return false;
        }

        // Clear the quick edit bit in the mode flags
        if (SetEnabled)
        {
            consoleMode &= ~ENABLE_QUICK_EDIT;
        }
        else
        {
            consoleMode |= ENABLE_QUICK_EDIT;
        }

        // set the new mode
        if (!SetConsoleMode(consoleHandle, consoleMode))
        {
            // ERROR: Unable to set console mode
            return false;
        }

        return true;
    }
}
"@

Try {
    Add-Type -TypeDefinition $QuickEditCode -Language CSharp -ErrorAction Stop | Out-Null
    $global:fQuickEditCodeExist = $True
} Catch {
    $global:fQuickEditCodeExist = $False
}


#region ##### MAIN #####

[System.Windows.Forms.Application]::EnableVisualStyles()

# Disabling quick edit mode as somethimes this causes the script stop working until enter key is pressed.
If ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($True) | Out-Null }

$notice = "========= Microsoft CSS Diagnostics Script =========`n
This Data Collection is for troubleshooting reported issues for the given scenarios.
Once you have started this script please wait until all data has been collected.`n`n
============= IMPORTANT NOTICE =============`n
This script is designed to collect information that will help Microsoft Customer Support Services (CSS) troubleshoot an issue you may be experiencing with Microsoft Remote Desktop solutions.`n
The collected data may contain Personally Identifiable Information (PII) and/or sensitive data, such as (but not limited to) IP addresses; PC names; and user names.`n
The script will save the collected data in a folder (default C:\MS_DATA) and also compress the results into a ZIP file.
This folder and its contents or the ZIP file are not automatically sent to Microsoft.`n
You can send the ZIP file to Microsoft CSS using a secure file transfer tool - Please discuss this with your support professional and also any concerns you may have.`n
Find our privacy statement at: https://privacy.microsoft.com/en-US/privacystatement`n
"

if (!($global:msrdTSSinUse)) {
    if ($AcceptEula) {
        Write-Output "$(msrdGetLocalizedText "eulaSilentOK")"
        $eulaAccepted = msrdShowEULAIfNeeded "MSRD-Collect" 2
    } else {
        $eulaAccepted = msrdShowEULAIfNeeded "MSRD-Collect" 0
        if ($eulaAccepted -ne "Yes") {
            Write-Output "$(msrdGetLocalizedText "eulaNotOK")"
            msrdCleanUpandExit
        }
        Write-Output "$(msrdGetLocalizedText "eulaOK")"
    }

    if ($AcceptNotice) {
        Write-Output "$(msrdGetLocalizedText "noticeSilentOK")`n"
    } else {
        $wshell = New-Object -ComObject Wscript.Shell
        $answer = $wshell.Popup("$notice",0,"Are you sure you want to continue?",4+32)
        if ($answer -eq 7) {
            Write-Warning "$(msrdGetLocalizedText "notApproved")`n"
            msrdCleanUpandExit
        }
        Write-Output "$(msrdGetLocalizedText "noticeOK")`n"
    }
}

if ($Core -or $Profiles -or $Activation -or $MSIXAA -or $AppAttach -or $MSRA -or $IME -or $HCI -or $Teams -or $SCard -or $DiagOnly -or $NetTrace -or $DumpPID) {
    if ($Machine) {
        if ($Role) {
            switch($Machine) {
                'isRDS' { $global:msrdRDS = $true; $global:msrdAVD = $false; $global:msrdW365 = $false }
                'isAVD' { $global:msrdRDS = $false; $global:msrdAVD = $true; $global:msrdW365 = $false }
                'isW365' { $global:msrdRDS = $false; $global:msrdAVD = $false; $global:msrdW365 = $true }
            }

            switch($Role) {
                'isSource' { $global:msrdSource = $true; $global:msrdTarget = $false }
                'isTarget' { $global:msrdSource = $false; $global:msrdTarget = $true }
            }

            msrdInitFolders

            if ($global:avdnettestpath -eq "") { msrdLogMessage $LogLevel.Warning "$(msrdGetLocalizedText 'avdnettestNotFound')`n" } #if avdnettest.exe is missing

            if (-not $global:msrdTSSinUse) {
                if ($global:msrdDevLevel -eq "Insider") {
                    msrdLogMessage $LogLevel.Info "$(msrdGetLocalizedText "starting") - v$msrdVersion (INSIDER Build - For Testing Purposes Only !)`n" -Color "Cyan"
                } else {
                    msrdLogMessage $LogLevel.Info "$(msrdGetLocalizedText "starting") - v$msrdVersion`n" -Color "Cyan"
                }

                if ($global:msrdAutoVerCheck -eq 1) {
                    if ($global:msrdScriptSelfUpdate -eq 1) {
                        msrdCheckVersion ($msrdVersion) -selfUpdate
                    } else {
                        msrdCheckVersion ($msrdVersion)
                    }
                } else {
                    msrdLogMessage $LogLevel.Normal "INFO: Automatic update check on script launch is Disabled"
                }
            }

            if ($UserContext) { msrdLogMessage $LogLevel.Info "INFO: UserContext switch has been specified with value: $UserContext`n" }

            if ($PSSenderInfo) {
                msrdLogMessage $LogLevel.Info "INFO: The script is running in a remote PowerShell session" -Color "Yellow"
                msrdLogMessage $LogLevel.Info "INFO: ConnectedUser: $($PSSenderInfo.ConnectedUser)" -Color "Yellow"
                msrdLogMessage $LogLevel.Info "INFO: RunAsUser: $($PSSenderInfo.RunAsUser)" -Color "Yellow"
            }

            msrdInitScript

            $varsNO = @(,$false * 1)

            msrdInitScenarioVars
            $dumpProc = $false
            $pidProc = ""
            $global:onlyDiag = $false

            $vCore = @(,$true * 12)

            if ($Profiles) { $vProfiles = @(,$true * 5) }
            if ($Activation) { $vActivation = @(,$true * 3) }
            if ($MSRA) { $vMSRA = @(,$true * 6) }
            if ($SCard) { $vSCard = @(,$true * 3) }
            if ($IME) { $vIME = @(,$true * 3) }
            if ($Teams) { $vTeams = @(,$true * 4) }
            if ($MSIXAA) { $vMSIXAA = @(,$true * 1) }
            if ($AppAttach) { $vMSIXAA = @(,$true * 1) }
            if ($HCI) { $vHCI = @(,$true * 1) }
            if ($DumpPID) { $pidProc = $DumpPID; $dumpProc = $true }
            if ($DiagOnly) {
                $vCore = $varsNO; $global:onlyDiag = $true;
                if ($Core -or $Profiles -or $Activation -or $MSIXAA -or $AppAttach -or $MSRA -or $IME -or $HCI -or $Teams -or $SCard -or $NetTrace -or $DumpPID) {
                    msrdLogMessage $LogLevel.Warning "Scenario 'DiagOnly' has been specified together with other scenarios. All scenarios will be ignored and only Diagnostics will run.`n"
                }
            }

            if (-not $DiagOnly) {

                #data collection
                $parameters = @{
                    varsCore = $vCore
                    varsProfiles = $vProfiles
                    varsActivation = $vActivation
                    varsMSRA = $vMSRA
                    varsSCard = $vSCard
                    varsIME = $vIME
                    varsTeams = $vTeams
                    varsMSIXAA = $vMSIXAA
                    varsHCI = $vHCI
                    traceNet = $NetTrace
                    dumpProc = $dumpProc
                    pidProc = $pidProc
                }
                msrdCollectData @parameters

            }

            $varsSystem = @(,$true * 12)
            $varsAVDRDS = @(,$true * 11)
            $varsInfra = @(,$true * 10)
            $varsAD = @(,$true * 2)
            $varsNET = @(,$true * 8)
            $varsLogSec = @(,$true * 3)
            $varsIssues = @(,$true * 2)
            $varsOther = @(,$true * 4)

            #diagnostics
            $parameters = @{
                varsSystem = $varsSystem
                varsAVDRDS = $varsAVDRDS
                varsInfra = $varsInfra
                varsAD = $varsAD
                varsNET = $varsNET
                varsLogSec = $varsLogSec
                varsIssues = $varsIssues
                varsOther = $varsOther
            }
            msrdCollectDataDiag @parameters

            msrdArchiveData -varsCore $vCore

        } else {
            Write-Warning "Please include the '-Role' parameter to indicate the role of the machine in the selected remote desktop solution, or run the script without any parameters (= GUI mode).`nSupported values for the '-Role' parameter: 'isSource', 'isTarget'.`nSee MSRD-Collect-ReadMe.txt for more details.`nExiting..."
            Exit
        }
    } else {
        Write-Warning "Please include the '-Machine' parameter to indicate the type of environment from where data should be collected, or run the script without any parameters (= GUI mode).`nSupported values for the '-Machine' parameter: 'isAVD', 'isRDS', 'isW365'.`nSee MSRD-Collect-ReadMe.txt for more details.`nExiting..."
        Exit
    }

} else {
    if (-not $global:msrdTSSinUse) {

$code = @"
using System;
using System.Runtime.InteropServices;

namespace System
{
    public class IconExtractor
    {
        public static System.Drawing.Icon Extract(string file, int number, bool largeIcon)
        {
            IntPtr large;
            IntPtr small;
            ExtractIconEx(file, number, out large, out small, 1);
            try
            {
                // Create a copy of the icon to avoid handle ownership issues
                var extractedIcon = (System.Drawing.Icon)System.Drawing.Icon.FromHandle(largeIcon ? large : small).Clone();

                // Release the handles obtained from ExtractIconEx
                DestroyIcon(large);
                DestroyIcon(small);

                return extractedIcon;
            }
            catch
            {
                return null;
            }
        }

        [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
        private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern bool DestroyIcon(IntPtr handle);
    }
}
"@

        if ($PSVersionTable.PSVersion.Major -eq 5) {
            Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
        } else {
            Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing.Common,System.Drawing
        }

        Add-Type -AssemblyName System.Windows.Forms

        $global:msrdRDS = $false; $global:msrdAVD = $false; $global:msrdW365 = $false
        $global:msrdSource = $false; $global:msrdTarget = $false


#Load dlls into context of the current console session
 Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

        if ($msrdGUILite -eq 1) {
            Import-Module -Name "$PSScriptRoot\Modules\MSRDC-FwGUILite" -DisableNameChecking -Force
            msrdAVDCollectGUILite -ShowConsole $msrdShowConsole
        } else {
            Import-Module -Name "$PSScriptRoot\Modules\MSRDC-FwGUI" -DisableNameChecking -Force
            msrdAVDCollectGUI -ShowConsole $msrdShowConsole -MaximizeWindow $msrdMaximizeWindow
        }
    }
}
#endregion ##### MAIN #####
# SIG # Begin signature block
# MIIoLQYJKoZIhvcNAQcCoIIoHjCCKBoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYCf8aFuz+6o8N
# H1xorZl2mN0if/Vwg1UPvRVMDDMzIqCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICI8vuym/883vEFQKKMtdT2R
# 9rbR6PKpXe0HLVxqYU+eMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAmO1Q5AdU5xNR/51dp8WN6yEJBUbqidY5j6S3bWZviLOrb+IrJf1S957I
# SV+DYqJRaZIoMIYA7qnzQzD8oXaSOq2qqezjra81git4DEMvo0BsPdcSkWQokv5X
# UbhAsvjkKAdeBdbVNWus1dkOFIbzfj8WTxDIP0CndCHSOpgB1xL2BEVoPLg5P+Uu
# Cr2St2iAzuTpF9WcpShb+p/7YA1KmJrwabHsc+wcX8JxGbtPy0Lh7YGQm/Owa8J/
# 6ivC/3/yHP5uxKiqMEkpKvLIg3bz/ZH3Rgsnz8aEIP2ZitSzJe8wV7sXCr0rUHtB
# +WYWZGj4dEyRIo4ykv6ZUt6aOZoPBKGCF5cwgheTBgorBgEEAYI3AwMBMYIXgzCC
# F38GCSqGSIb3DQEHAqCCF3AwghdsAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAsmQGENye7otCxKRm153y6snTuIaE2u+NNOcbFCU6IHQIGZkYsf+8a
# GBMyMDI0MDYxMjE1MDAzOC43OTVaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
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
# MC8GCSqGSIb3DQEJBDEiBCBGcxwfqtpKWrsDqsX5PGocodjVXbcEaSMwWjLSYtIY
# KjCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EII0uDWg0CFseKxK3A16l1wrI
# wrsSDrXZ6xSf0F4xbMo5MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTACEzMAAAHt4V/L1felXXMAAQAAAe0wIgQg78GZUuvOaAxFZfQzyWJdNbhw
# SWZv3xxQFU3XxQWbtOkwDQYJKoZIhvcNAQELBQAEggIAiDQMNNhhoZ43r/lZst5j
# K6pyulXKnijz/HMVxP7waKop7w2B8f9f8YxiOvzUDDXBbsm1RDSJKvNzk3BLE8t/
# veNcI9pXIo3GgiTtyiByvseZT74ba8ajQXMGxaS1m1HVDmjkCCmkJFHxFGUdX9RN
# E5u59MHCNEMrkHctDHXRhBBE3BSFutPavCh4bwqvoUgMWu2jBtZpgGye+gmVo+Bd
# n1HDTntzkEydv9+nPUv+VlK05JQbHTK2okLxfiHLfUcA+EunOEUJ26lAvMqY/8/k
# 5GP+hBlCgrD52G2k1eyq/EsRmXai5l5fpbEmiBujQ2G/DJmYXZIft0GrDctUmgj9
# E/gJYuc0pfwXDIpqzdiGBfsduBhjhSbGUEC7x0GyLtwGjlICHUhLeX9t1hBCccyw
# pl7cb2OCr02qZnQltWzo0JaTlk/9RgZF/JYggEnhiS+hP8hUS5MOFTLXpvacaMN1
# 8rVoy7rZDCRT4eBO1unmPfCorAsKDaj4gGZ5hYiboEv050I4b6iK2+IiZpmiYmOC
# uXG6s9XB4NWzlK6gIjymWEpGdCw7oOv3Rj6H+Fbf1sZBqYVcV7BVraDFnAtnsY0U
# lOcBdbpC9KlJK1Z0D6wBKwJzikDjUvVHIVUT7iccadUzoPl//rah+g97ZAwHk99v
# PDR+J9Ec/u86v7u4n3YOcBE=
# SIG # End signature block
