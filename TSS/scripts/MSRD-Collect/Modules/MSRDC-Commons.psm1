<#
.SYNOPSIS
   MSRD-Collect global functions

.DESCRIPTION
   Module for the MSRD-Collect global functions

.NOTES
   Author     : Robert Klemencz
   Requires   : At least PowerShell 5.1 (This module is not for stand-alone use. It is used automatically from within the main MSRD-Collect.ps1 script)
   Version    : See MSRD-Collect.ps1 version
   Feedback   : Send an e-mail to MSRDCollectTalk@microsoft.com
#>

if (!($global:msrdTSSinUse)) {
    $global:LogLevel = @{
	    'Normal' = 0
	    'Info' = 1
	    'Warning' = 2
	    'Error' = 3
        #'Debug' = 4
	    'ErrorLogFileOnly' = 5
	    'WarnLogFileOnly' = 6
        'InfoLogFileOnly' = 7
        'DiagFileOnly' = 9
    }
}

#region initialization

if (($global:msrdOSVer -like "*Server*2008*") -or ($global:msrdOSVer -like "*Server*2012*") -or ($global:msrdOSVer -like "*Windows 7*")) {
    [string]$global:WinVerMajor = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' CurrentVersion).CurrentVersion
} else {
    [string]$global:WinVerMajor = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' CurrentMajorVersionNumber).CurrentMajorVersionNumber
    [string]$global:WinVerMinor = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' CurrentMinorVersionNumber).CurrentMinorVersionNumber
}

[int]$global:WinVerBuild = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' CurrentBuild).CurrentBuild
[string]$global:WinVerRevision = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' UBR).UBR

function msrdInitScript {
    param ([string]$Type, $isTSS)

    if (!($isTSS)) {
        $initValues = @("$(msrdGetLocalizedText initvalues1a) $global:msrdVersion $(msrdGetLocalizedText initvalues1b) $global:msrdScriptpath",
            "$(msrdGetLocalizedText initvalues1c) $global:msrdCmdLine",
            "$(msrdGetLocalizedText initvalues2)",
            "$(msrdGetLocalizedText initvalues3) $global:msrdLogRoot",
            "$(msrdGetLocalizedText initvalues4) $global:msrdUserprof`n"
        )
        $initValues | ForEach-Object { if ($type -eq 'GUI') { msrdAdd-OutputBoxLine $_ } else { msrdLogMessage $LogLevel.Info $_ } }
    }

    $unsupportedOSMessage = "This Windows release is no longer supported. Please upgrade the machine to a more current, in-service, and supported Windows release."

    if ((($global:WinVerMajor -like "*10*") -and (@("10240", "10586", "14393", "15063", "16299", "17134", "17763", "18362", "18363", "19041", "19042", "19043") -contains $global:WinVerBuild) -and !($global:msrdOSVer -like "*Server*")) -or ($global:msrdOSVer -like "*Windows 8*") -or ($global:msrdOSVer -like "*Windows 7*")) {
        if ($type -eq 'GUI') {
            msrdAdd-OutputBoxLine $unsupportedOSMessage -Color "Yellow"
        } else {
            Write-Warning $unsupportedOSMessage
        }
    }

    $unsupportedOSMessageExt = @{
        "*Server 2008 R2*" = "The Windows Server 2008 R2 Extended Security Update (ESU) Program ended on January 10, 2023. 'Azure only' ESU will end on January 9, 2024. See: <a href='https://learn.microsoft.com/en-us/lifecycle/products/windows-server-2008-r2' target='_blank'>Windows Server 2008 R2</a>. Please upgrade the machine to a more current, in-service, and supported Windows release.`n";
    }

    if ($unsupportedOSMessageExt.ContainsKey($global:msrdOSVer)) {
        if ($type -eq 'GUI') {
            msrdAdd-OutputBoxLine $unsupportedOSMessageExt[$global:msrdOSVer] -Color "Yellow"
        } else {
            Write-Warning $unsupportedOSMessageExt[$global:msrdOSVer]
        }
    }
}

function msrdInitScenarioVars {

    $vars = "vProfiles", "vActivation", "vMSRA", "vSCard", "vIME", "vTeams", "vMSIXAA", "vHCI"
    foreach ($var in $vars) { $var = $script:varsNO }

    $script:dumpProc = $False; $script:pidProc = ""
    $script:traceNet = $False; $global:onlyDiag = $false
}

Function msrdInitFolders {

    if ($global:msrdTSSinUse) {
        $global:msrdLogFolder = "MSRD-Results-" + $env:computername
    } else {
        $global:msrdLogFolder = "MSRD-Results-" + $env:computername +"-" + $(get-date -f yyyyMMdd_HHmmss)
    }

    $global:msrdLogDir = "$global:msrdLogRoot\$global:msrdLogFolder\"
    $global:msrdLogFilePrefix = $env:computername + "_"
    $global:msrdBasicLogFolder = $global:msrdLogDir + $global:msrdLogFilePrefix
    $global:msrdErrorLogFile = $global:msrdBasicLogFolder + "MSRD-Collect-Error.txt"
    $global:msrdTempCommandErrorFile = $global:msrdBasicLogFolder + "MSRD-Collect-CommandError.txt"
    $global:msrdOutputLogFile = $global:msrdBasicLogFolder + "MSRD-Collect-Log.txt"
    $global:msrdEventLogFolder = $global:msrdBasicLogFolder + "EventLogs\"
    $global:msrdNetLogFolder = $global:msrdBasicLogFolder + "Networking\"
    $global:msrdRDSLogFolder = $global:msrdBasicLogFolder + "RDS\"
    $global:msrdAVDLogFolder = $global:msrdBasicLogFolder + "AVD\"
    $global:msrdRegLogFolder = $global:msrdBasicLogFolder + "RegistryKeys\"
    $global:msrdSchtaskFolder = $global:msrdBasicLogFolder + "ScheduledTasks\"
    $global:msrdSysInfoLogFolder = $global:msrdBasicLogFolder + "SystemInfo\"
    $global:msrdGenevaLogFolder = $global:msrdBasicLogFolder + "AVD\Monitoring\"

    if ($global:msrdAVD -or $global:msrdW365) { $global:msrdTechFolder = $global:msrdAVDLogFolder } else { $global:msrdTechFolder = $global:msrdRDSLogFolder }

    try {
        $createfolder = New-Item -itemtype directory -path $global:msrdLogDir -ErrorAction Stop
    }
    catch {
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        $errorMessage = $_.Exception.Message.TrimStart()
        msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_ -fErrorLogFileOnly
    }
}

# create folders
Function msrdCreateLogFolder {
    Param(
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Path,
        $TimeStamp
    )

    If (!(Test-Path -Path $Path)) {
        $p = $Path.TrimEnd('\')
        Try {
            if ($TimeStamp -eq "No") {
                $LogMessage = "$(msrdGetLocalizedText "logfoldermsg") $p"
            } else {

                if ($global:msrdLangID -eq "AR") {
                    $date = Get-Date
                    $day = $date.Day.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                    $month = $date.Month.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                    $year = $date.Year.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                    $hour = $date.Hour.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                    $minute = $date.Minute.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                    $second = $date.Second.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                    $millisecond = $date.Millisecond.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                    $datemsg = "${hour}:${minute}:${second}.${millisecond} ${year}/${month}/${day}"
                } else {
			        $datemsg = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
		        }

                $LogMessage = $datemsg + " $(msrdGetLocalizedText "logfoldermsg") $p"
            }

            if ($global:msrdGUI) {
                msrdAdd-OutputBoxLine $LogMessage "Yellow"
            } else {
                $host.ui.RawUI.ForegroundColor = "Yellow"
                Write-Output $LogMessage
                $host.ui.RawUI.ForegroundColor = $global:msrdConsoleColor
            }

            if ($global:msrdCollecting -or $global:msrdDiagnosing) {
                $LogMessage | Out-File -Append $global:msrdOutputLogFile
            }

            New-Item -Path $Path -ItemType Directory | Out-Null
        } Catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            $errorMessage = $_.Exception.Message.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_ -fErrorLogFileOnly
            if ($global:msrdGUI) {
                msrdAdd-OutputBoxLine ("Error in $failedCommand $errorMessage") "Magenta"
            } else {
                msrdLogMessage $LogLevel.Warning ("Error in $failedCommand $errorMessage")
            }
            return
        }
    } else {
        msrdLogMessage $LogLevel.WarnLogFileOnly "$Path $(msrdGetLocalizedText "logfolderexistmsg")"
    }
}

function msrdGetLocalizedText ($textID) {

    $textIDlang = $textID + $global:msrdLangID
	$LangTextNode = $global:msrdLangText.LangV1.lang | Where-Object {$_.id -eq $textIDlang}

	if($LangTextNode -ne $null) {
		$LangTextCode = @()
		$LangTextCode += $LangTextNode."#text"
        if ($LangTextCode -like "*&amp;*") { $LangTextCode = $LangTextCode.replace("&amp;","&") }
		return $LangTextCode
	} else {
        $textIDlang = $textID + "EN"
	    $LangTextNode = $global:msrdLangText.LangV1.lang | Where-Object {$_.id -eq $textIDlang}
        if($LangTextNode -ne $null) {
		    $LangTextCode = @()
		    $LangTextCode += $LangTextNode."#text"
            if ($LangTextCode -like "*&amp;*") { $LangTextCode = $LangTextCode.replace("&amp;","&") }
		    return $LangTextCode
        }
    }
	return $null
}

function msrdGetSysInternalsProcDump {

    try {
        $PDurl = 'https://github.com/MicrosoftDocs/sysinternals/blob/main/sysinternals/downloads/procdump.md'

        $PDWSProxy = New-Object System.Net.WebProxy
        $PDWSWebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $PDWSWebSession.Proxy = $PDWSProxy
        $PDWSWebSession.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $PDresponse = Invoke-WebRequest -Uri $PDurl -WebSession $PDWSWebSession -UseBasicParsing -TimeoutSec 30

        if ($PDresponse) {
            # Use the regular expression to extract the Procdump version
            $regexPattern = 'ProcDump v([\d\.]+)'
            $PDmatches = [regex]::Matches($PDresponse.Content, $regexPattern)

            if ($PDmatches.Count -gt 0) {
                # The version number should be in the first capturing group of the first match
                $PDonlineVersion = $PDmatches[0].Groups[1].Value
            }

            if ($PDonlineVersion -and ([version]$PDonlineVersion -gt [version]$global:msrdProcDumpVer)) {

                if ($global:msrdProcDumpVer -eq "1.0") {
                    $PDnotice = "This MSRD-Collect version is missing ProcDump.exe.`nIt is recommended to redownload the full MSRD-Collect (or TSS) package or download the latest version of ProcDump ($PDonlineVersion) from SysInternals.`nDo you want to download ProcDump from SysInternals now?"
                } else {
                    $PDnotice = "This MSRD-Collect version comes with ProcDump version $global:msrdProcDumpVer.`nA newer version of ProcDump ($PDonlineVersion) from SysInternals is available for download.`nDo you want to update the local ProcDump version now?"
                }

                $PDresult = [System.Windows.Forms.MessageBox]::Show($PDnotice, "New ProcDump version available", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)

                if ($PDresult -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $PDzipFile = Join-Path $env:TEMP 'Procdump.zip'
                    $PDdownloadUrl = 'https://download.sysinternals.com/files/Procdump.zip'
                    Invoke-WebRequest -Uri $PDdownloadUrl -OutFile $PDzipFile
                    $PDunzippedFolder = Join-Path $env:TEMP 'Procdump'
                    Expand-Archive -Path $PDzipFile -DestinationPath $PDunzippedFolder -Force
                    msrdCreateLogFolder -msrdLogFolder "$global:msrdScriptpath\Tools" -TimeStamp No

                    Copy-Item -Path (Join-Path $PDunzippedFolder "procdump.exe") -Destination $global:msrdToolsFolder -Force
                    $global:msrdProcDumpExe = "$global:msrdScriptpath\Tools\procdump.exe"
                    Remove-Item $PDzipFile
                    Remove-Item $PDunzippedFolder -Recurse -Force

                    #update procdump version in .cfg file
                    msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "ProcDumpVersion" -value $PDonlineVersion
                    $global:msrdProcDumpVer = $PDonlineVersion

                    $PDdownloadmsg = "ProcDump version $PDonlineVersion has been downloaded and extracted to $global:msrdToolsFolder`nConfig file has been updated"
                    if ($global:msrdGUI) {
                        msrdAdd-OutputBoxLine $PDdownloadmsg -Color Yellow
                    } else {
                        msrdLogMessage $LogLevel.Info $PDdownloadmsg
                    }
                } else {
                    if ($global:msrdProcDumpVer -eq "1.0") {
                        $noPDdownloadmsg = "You have chosen not to download the latest available ProcDump version ($PDonlineVersion) from SysInternals. It will not be possible to collect process dumps using MSRD-Collect"
                    } else {
                        $noPDdownloadmsg = "You have chosen not to download the latest available ProcDump version ($PDonlineVersion) from SysInternals. The current, local version $global:msrdProcDumpVer will be used when needed"
                    }
                    if ($global:msrdGUI) {
                        msrdAdd-OutputBoxLine $noPDdownloadmsg -Color Yellow
                    } else {
                        msrdLogMessage $LogLevel.Info $noPDdownloadmsg
                    }
                }

            } else {
                if ($global:msrdGUI) {
                    msrdAdd-OutputBoxLine ("$(msrdGetLocalizedText "PDvercheck1") ($global:msrdProcDumpVer)") -Color Lightgreen
                } else {
                    msrdLogMessage $LogLevel.Info ("$(msrdGetLocalizedText "PDvercheck1") ($global:msrdProcDumpVer)") -Color Green
                }
            }

            $PDWSProxy = $null

        } else {
            $global:msrdSetWarning = $true
            msrdLogMessage DiagFileOnly -Type "Text" -col 3 -Message "ProcDump version information could not be retrieved." -circle "red"
        }
    } catch {
        $global:aucfail = $true
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        $errorMessage = $_.Exception.Message.TrimStart()
        if ($global:msrdGUI) {
            msrdAdd-OutputBoxLine ("Error in $failedCommand $errorMessage") "Magenta"
        } else {
            msrdLogMessage $LogLevel.Warning ("Error in $failedCommand $errorMessage")
        }
    }
}

function msrdProcDumpVerCheck {

    if ($global:msrdProcDumpExe -eq "") {
        $noPDmsg = "ProcDump.exe could not be found. It will not be possible to collect a Process Dump through MSRD-Collect unless ProcDump.exe is available."
        if ($global:msrdGUI) {
            msrdAdd-OutputBoxLine $noPDmsg -Color Yellow
        } else {
            msrdLogMessage $LogLevel.Info $noPDmsg
        }
    }

    msrdGetSysInternalsProcDump

    if ($global:msrdGUI) { msrdAdd-OutputBoxLine ("") } else { msrdLogMessage $LogLevel.Info "`n" -NoDate }
}
#endregion initialization

#region messages
Function msrdLogMessage {
    param(
        [ValidateNotNullOrEmpty()][Int]$Level = $LogLevel.Normal,
        [string]$Message,
        [string]$Color,
		[Switch]$noDate,
        [Switch]$addAssist,
        [string]$LogPrefix
    )

    If (!(Test-Path -Path $global:msrdLogDir)) { msrdCreateLogFolder $global:msrdLogDir }

    $global:msrdPerc = "{0:P}" -f ($global:msrdProgress/100)

    $LogConsole = $True

    if ($LogPrefix) {
        if ($global:msrdLangID -eq "AR") {
            $Message = "$Message [$LogPrefix]"
        } else {
            $Message = "[$LogPrefix] $Message"
        }
    }

    switch ($Level) {
        '0' { $MessageColor = 'White' } # Normal
        '1' { $MessageColor = 'Yellow' } # Info
        '2' { $MessageColor = 'Magenta'; $Levelstr = 'WARNING' } # Warning
        '3' { $MessageColor = 'Red'; $LogConsole = $False; $Levelstr = 'ERROR' } # Error
        '5' { $LogConsole = $False; $Levelstr = 'ERROR' } # ErrorLogFileOnly
        '6' { $LogConsole = $False; $Levelstr = 'WARNING' } # WarnLogFileOnly
        '7' { $LogConsole = $False; $Levelstr = 'INFO' } # InfoLogFileOnly
    }

    if ($Color) { $MessageColor = $Color }

    if ($global:msrdLiveDiag) {
        if ($global:msrdLiveDiagSystem) {
            $liveDiagBox = $liveDiagPsBoxSystem
        } elseif ($global:msrdLiveDiagAVDRDS) {
            $liveDiagBox = $liveDiagPsBoxAVDRDS
        } elseif ($global:msrdLiveDiagAVDInfra) {
            $liveDiagBox = $liveDiagPsBoxAVDInfra
        } elseif ($global:msrdLiveDiagAD) {
            $liveDiagBox = $liveDiagPsBoxAD
        } elseif ($global:msrdLiveDiagNet) {
            $liveDiagBox = $liveDiagPsBoxNet
        } elseif ($global:msrdLiveDiagLogonSec) {
            $liveDiagBox = $liveDiagPsBoxLogonSec
        } elseif ($global:msrdLiveDiagIssues) {
            $liveDiagBox = $liveDiagPsBoxIssues
        } elseif ($global:msrdLiveDiagOther) {
            $liveDiagBox = $liveDiagPsBoxOther
        }
    }

    $Index = 1
    # In case of Warning/Error/Debug, add line and function name to message.
    If ($Level -eq $LogLevel.Error -or $Level -eq $LogLevel.ErrorLogFileOnly -or $Level -eq $LogLevel.Warning -or $Level -eq $LogLevel.WarnLogFileOnly) {
        $CallStack = Get-PSCallStack
        $CallerInfo = $CallStack[$Index]
		$2ndCallerInfo = $CallStack[$Index+1]
		$3rdCallerInfo = $CallStack[$Index+2]

        if ($CallerInfo.FunctionName -like "*msrdLogMessage") { $CallerInfo = $2ndCallerInfo }
        if ($CallerInfo.FunctionName -like "*msrdLogException") { $CallerInfo = $3rdCallerInfo }
        $FuncName = $CallerInfo.FunctionName
        If ($FuncName -eq "<ScriptBlock>") { $FuncName = "Main" }

        if ($global:msrdLangID -eq "AR") {
            $date = Get-Date
            $day = $date.Day.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
            $month = $date.Month.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
            $year = $date.Year.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
            $hour = $date.Hour.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
            $minute = $date.Minute.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
            $second = $date.Second.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
            $millisecond = $date.Millisecond.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
            $datemsg = "${hour}:${minute}:${second}.${millisecond} ${year}/${month}/${day}"
        } else {
			$datemsg = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
		}

        $LogMessage = ($datemsg + ' [' + $FuncName + '(' + $CallerInfo.ScriptLineNumber + ')] ' + $Levelstr + ": " + $Message)

        # log to warning or error file
        if ($Level -eq $LogLevel.WarnLogFileOnly -or $Level -eq $LogLevel.Warning) {
            $LogMessage | Out-File -Append $global:msrdOutputLogFile
        } else {
            $LogMessage | Out-File -Append $global:msrdErrorLogFile
        }

    } elseif ($Level -eq $LogLevel.InfoLogFileOnly) {

            if ($global:msrdLangID -eq "AR") {
                $date = Get-Date
                $day = $date.Day.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $month = $date.Month.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $year = $date.Year.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $hour = $date.Hour.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $minute = $date.Minute.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $second = $date.Second.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $millisecond = $date.Millisecond.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $datemsg = "${year}/${month}/${day} ${hour}:${minute}:${second}.${millisecond}"
            } else {
			    $datemsg = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
		    }

            $LogMessage = ($datemsg + ' ' + $Levelstr + ": " + $Message)
            $LogMessage | Out-File -Append $global:msrdOutputLogFile
    } else {
        if($noDate){
			$LogMessage = $Message
		} else {

            if ($global:msrdLangID -eq "AR") {
                $date = Get-Date
                $day = $date.Day.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $month = $date.Month.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $year = $date.Year.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $hour = $date.Hour.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $minute = $date.Minute.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $second = $date.Second.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $millisecond = $date.Millisecond.ToString().Replace('1', '١').Replace('2', '٢').Replace('3', '٣').Replace('4', '٤').Replace('5', '٥').Replace('6', '٦').Replace('7', '٧').Replace('8', '٨').Replace('9', '٩').Replace('0', '٠')
                $datemsg = "${year}/${month}/${day} ${hour}:${minute}:${second}.${millisecond}"
            } else {
			    $datemsg = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
		    }

            $LogMessage = $datemsg + " " + $Message
        }
    }

    # percent progress
    if (($Level -eq $LogLevel.Normal) -or ($Level -eq $LogLevel.Info)) {
        [decimal]$global:msrdProgress = $global:msrdProgress + $global:msrdProgstep

        if (!$global:msrdGUI -and !($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible) -and ($global:msrdCollecting -or $global:msrdDiagnosing)) {
            Write-Progress -Activity "$(msrdGetLocalizedText "collecting1") $global:msrdProgScenario $(msrdGetLocalizedText "collecting2")" -Status "$global:msrdPerc complete:" -PercentComplete $global:msrdProgress
        } elseif ($global:msrdGUI -or ($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) {
            if (($global:msrdCollecting) -and !($global:msrdDiagnosing)) {
                $global:msrdProgbar.PerformStep()
                $global:msrdStatusBarLabel.Text = "$(msrdGetLocalizedText "collecting1") $global:msrdProgScenario $(msrdGetLocalizedText "collecting2")"
            } elseif ($global:msrdVersioncheck) {
                $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "checkupd"
            }

            if (!($global:msrdCollecting) -and !($global:msrdDiagnosing) -and !($global:msrdVersioncheck)) {
                $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
            }
        }
    }

    if ($LogConsole) {
        If ($global:msrdGUI) {
            if ($global:msrdLiveDiag) {
                $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                $liveDiagBox.SelectionLength = 0
                $liveDiagBox.AppendText("$LogMessage`r`n")
                $liveDiagBox.SelectionStart = $liveDiagBox.TextLength
                $liveDiagBox.ScrollToCaret()
                $liveDiagBox.Refresh()
            } else {
                $msrdPsBox.SelectionStart = $msrdPsBox.TextLength
                $msrdPsBox.SelectionLength = 0
                $msrdPsBox.SelectionColor = $MessageColor
                $msrdPsBox.AppendText("$LogMessage`r`n")
                $msrdPsBox.SelectionStart = $msrdPsBox.TextLength
                $msrdPsBox.SelectionColor = $MessageColor
                $msrdPsBox.ScrollToCaret()
                $msrdPsBox.Refresh()
            }
        } else {
            $host.ui.RawUI.ForegroundColor = $MessageColor
            Write-Output $LogMessage
            $host.ui.RawUI.ForegroundColor = $global:msrdConsoleColor
        }
        $LogMessage | Out-File -Append $global:msrdOutputLogFile
    }

    if (($global:msrdAssistMode -eq 1) -and (($Level -eq $LogLevel.Info) -or $addAssist)) {
        msrdLogMessageAssistMode $Message
    }
}

Function msrdLogMessageAssistMode {
    param( [ValidateNotNullOrEmpty()][string] $Message )

    if ($global:msrdAssistMode -eq 1) {
        Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak("$Message")
    }
}

Function msrdLogException {
    param([parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$Message, [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][System.Management.Automation.ErrorRecord]$ErrObj, [switch]$fErrorLogFileOnly = $false)

    $ErrorCode = "0x" + [Convert]::ToString($ErrObj.Exception.HResult,16)
    $ExternalException = [System.ComponentModel.Win32Exception]$ErrObj.Exception.HResult
    $ErrorMessage = $Message + "`n" `
        + "Command/Function: " + $ErrObj.CategoryInfo.Activity + " failed with $ErrorCode => " + $ExternalException.Message + "`n" `
        + $ErrObj.CategoryInfo.Reason + ": " + $ErrObj.Exception.Message + "`n" `
        + "ScriptStack:" + "`n" `
        + $ErrObj.ScriptStackTrace `
        + "`n`n"
    
    if (-not $global:msrdLiveDiag) {
        If ($fErrorLogFileOnly) {
            msrdLogMessage $LogLevel.ErrorLogFileOnly $ErrorMessage
        } else {
            msrdLogMessage $LogLevel.Error $ErrorMessage
        }
    }
}
#endregion messages

#region progress
Function msrdProgressStatusInit {
    Param(
        [ValidateNotNullOrEmpty()][int]$divider
    )

    $global:msrdProgress = 1
    $global:msrdProgstep = 100/$divider
    $global:msrdPerc = 1
    if ($global:msrdGUI -or ($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) {
        $global:msrdProgbar.Value = 1
        $global:msrdProgbar.Minimum = 1
        $global:msrdProgbar.Maximum = $divider
    }
}

Function msrdProgressStatusEnd {

    $global:msrdProgress = 100
    $global:msrdPerc = 100
}
#endregion progress

#region versioncheck
Function msrdVersionInt($verString) {
    $verSplit = $verString -split '\.'
    $vFull = 0
    for ($i = 0; $i -lt $verSplit.Count; $i++) {
        $vFull = ($vFull * 256) + [int]$verSplit[$i]
    }
    return $vFull
}

Function msrdCheckVersion($verCurrent, [switch]$selfUpdate) {
    $global:aucfail = $false

    if ($global:msrdGUI) {
        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "wait"
        msrdAdd-OutputBoxLine "$(msrdGetLocalizedText "vercheck1")"
    } else {
        msrdLogMessage $LogLevel.Normal "$(msrdGetLocalizedText "vercheck1")"
    }
    try {
        $global:msrdVersioncheck = $true
        $WebClient = New-Object System.Net.WebClient
        $verNew = $WebClient.DownloadString('https://cesdiagtools.blob.core.windows.net/windows/MSRD-Collect.ver')
        $verNew = $verNew.TrimEnd([char]0x0a, [char]0x0d)
        [long] $lNew = msrdVersionInt($verNew)
        [long] $lCur = msrdVersionInt($verCurrent)
        if($lNew -gt $lCur) {
            if ($global:msrdGUI) {
                $global:msrdForm.Text = 'MSRD-Collect (v' + $verCurrent + ') - $(msrdGetLocalizedText "vercheck2")'
            }

            if ($selfUpdate) {
                $updnotice = "$(msrdGetLocalizedText "vercheck3") v"+$verNew+" ($(msrdGetLocalizedText "vercheck4") v"+$verCurrent+").`n`n$(msrdGetLocalizedText "vercheck5")`n`n$(msrdGetLocalizedText "selfupdate1")"
            } else {
                $updnotice = "$(msrdGetLocalizedText "vercheck3") v"+$verNew+" ($(msrdGetLocalizedText "vercheck4") v"+$verCurrent+").`n`n$(msrdGetLocalizedText "vercheck5")`n`n$(msrdGetLocalizedText "vercheck5b")"
            }

            $wshell = New-Object -ComObject Wscript.Shell
            $answer = $wshell.Popup("$updnotice",0,"$(msrdGetLocalizedText "vercheck6")",4+32)
            if ($answer -eq 6) {

                if ($selfUpdate) {
                    $UpdLogFile = $global:msrdScriptpath + "\MSRD-Collect-UpdateLog.txt"

                    $msrdZipFile = Join-Path $env:TEMP 'MSRD-Collect_download.zip'
		            $msrdDownloadUrl = 'https://cesdiagtools.blob.core.windows.net/windows/MSRD-Collect.zip'

                    (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " " + "$(msrdGetLocalizedText "selfupdate2") (v$verCurrent -> v$verNew) $(msrdGetLocalizedText "selfupdate3") $env:username`n" | Out-File -Append $UpdLogFile

                    $selfUpdateMsg = "$(msrdGetLocalizedText "selfupdate4")"
                    if ($global:msrdGUI) {
		                msrdAdd-OutputBoxLine $selfUpdateMsg -Color Yellow
                    } else {
                        msrdLogMessage $LogLevel.Info ("$selfUpdateMsg")
                    }
		            (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " " + $selfUpdateMsg | Out-File -Append $UpdLogFile
                    Start-BitsTransfer $msrdDownloadUrl -Destination $msrdZipFile -ErrorAction SilentlyContinue | Out-File -Append $UpdLogFile

		            #save current config and update
                    $selfUpdateMsg = "$(msrdGetLocalizedText "selfupdate5") $global:msrdScriptpath\MSRD-Collect.cfg_backup"
                    if ($global:msrdGUI) {
		                msrdAdd-OutputBoxLine $selfUpdateMsg -Color Yellow
                    } else {
                        msrdLogMessage $LogLevel.Info ("$selfUpdateMsg")
                    }
                    (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " " + $selfUpdateMsg | Out-File -Append $UpdLogFile
		            Copy-Item ($global:msrdScriptpath + "\MSRD-Collect.cfg") ($global:msrdScriptpath + "\MSRD-Collect.cfg_backup") -Force -ErrorAction SilentlyContinue | Out-File -Append $UpdLogFile

                    $selfUpdateMsg = "$(msrdGetLocalizedText "selfupdate6") $ENV:temp\MSRD-Collect_download.zip"
                    if ($global:msrdGUI) {
                        msrdAdd-OutputBoxLine $selfUpdateMsg -Color Yellow
                    } else {
                        msrdLogMessage $LogLevel.Info ("$selfUpdateMsg")
                    }
                    (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " " + $selfUpdateMsg | Out-File -Append $UpdLogFile
                    Expand-archive -LiteralPath $msrdZipFile -DestinationPath $global:msrdScriptpath -Force

                    $selfUpdateMsg = "$(msrdGetLocalizedText "selfupdate7")"
                    if ($global:msrdGUI) {
		                msrdAdd-OutputBoxLine $selfUpdateMsg -Color Yellow
                    } else {
                        msrdLogMessage $LogLevel.Info ("$selfUpdateMsg")
                    }
		            (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " " + $selfUpdateMsg | Out-File -Append $UpdLogFile
                    Move-Item ($global:msrdScriptpath + "\MSRD-Collect.cfg_backup") ($global:msrdScriptpath + "\MSRD-Collect.cfg") -Force -ErrorAction SilentlyContinue | Out-File -Append $UpdLogFile

                    $selfUpdateMsg = "$(msrdGetLocalizedText "selfupdate8")"
                    if ($global:msrdGUI) {
                        msrdAdd-OutputBoxLine $selfUpdateMsg -Color Yellow
                    } else {
                        msrdLogMessage $LogLevel.Info ("$selfUpdateMsg")
                    }
                    (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " " + $selfUpdateMsg | Out-File -Append $UpdLogFile
		            Remove-Item $msrdZipFile -ErrorAction SilentlyContinue | Out-File -Append $UpdLogFile

                    # Restart the script
                    $selfUpdateMsg = "$(msrdGetLocalizedText "selfupdate9")`n"
                    if ($global:msrdGUI) {
                        msrdAdd-OutputBoxLine $selfUpdateMsg -Color Lightgreen
                    } else {
                        msrdLogMessage $LogLevel.Info ("$selfUpdateMsg") -Color Green
                    }
                    (Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff") + " " + $selfUpdateMsg + "`n" | Out-File -Append $UpdLogFile
                    $global:msrdCollectcount = 0

                    try {
                        Start-Process PowerShell.exe -ArgumentList "$global:msrdCmdLine" -NoNewWindow
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

                } else {
                    Write-Output "$(msrdGetLocalizedText "vercheck7")"
                    Start-Process https://aka.ms/MSRD-Collect
                    if (($global:msrdTempCommandErrorFile -ne $null) -and (Test-Path -Path $global:msrdTempCommandErrorFile)) {
                        Remove-Item -Path $global:msrdTempCommandErrorFile -Force -ErrorAction SilentlyContinue
                    }

                    if ($global:fQuickEditCodeExist) { [msrdDisableConsoleQuickEdit]::SetQuickEdit($false) | Out-Null }
                    if ($global:msrdGUI) { $global:msrdForm.Close() } else { Exit }
                }

            } else {
                if ($global:msrdGUI) {
                    msrdAdd-OutputBoxLine ("$(msrdGetLocalizedText "vercheck8")") -Color Yellow
                } else {
                    msrdLogMessage $LogLevel.Info ("$(msrdGetLocalizedText "vercheck8")")
                }
            }

        } else {
            if ($global:msrdGUI) {
                msrdAdd-OutputBoxLine ("$(msrdGetLocalizedText "vercheck9") (v"+$verCurrent+")") -Color Lightgreen
            } else {
                msrdLogMessage $LogLevel.Info ("$(msrdGetLocalizedText "vercheck9") (v"+$verCurrent+")") -Color Green
            }
        }

    } catch {
        $global:aucfail = $true
        $failedCommand = $_.InvocationInfo.Line.TrimStart()
        $errorMessage = $_.Exception.Message.TrimStart()
        if ($global:msrdGUI) {
            msrdAdd-OutputBoxLine ("Error in $failedCommand $errorMessage") "Magenta"
        } else {
            msrdLogMessage $LogLevel.Warning ("Error in $failedCommand $errorMessage")
        }
    }

    msrdProcDumpVerCheck

    if ($global:aucfail) {
        $disupd = "Automatic update check failed, possibily due to limited or no internet access.`n`nWould you like to disable automatic update check?`n`nYou can always enabled it again from the Tools menu (Check for Update on launch)."
        $dushell = New-Object -ComObject Wscript.Shell
        $duanswer = $dushell.Popup("$disupd",0,"Disable automatic update check",4+48)
        if ($duanswer -eq 6) {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "AutomaticVersionCheck" -value 0
            $global:msrdAutoVerCheck = 0
            if ($global:msrdGUI) {
                msrdAdd-OutputBoxLine "Automatic update check on script launch is Disabled`n"
                $global:AutoVerCheckMenuItem.Checked = $false
            } else {
                msrdLogMessage $LogLevel.Info ("Automatic update check on script launch is Disabled`n")
            }
        } else {
            msrdUpdateConfigFile -configFile "MSRD-Collect.cfg" -key "AutomaticVersionCheck" -value 1
            $global:msrdAutoVerCheck = 1
            if ($global:msrdGUI) {
                msrdAdd-OutputBoxLine "Automatic update check on script launch is Enabled`n"
                $global:AutoVerCheckMenuItem.Checked = $true
            } else {
                msrdLogMessage $LogLevel.Info ("Automatic update check on script launch is Enabled`n")
            }
        }
    }

    if ($global:msrdGUI) {
        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
    }

    $global:msrdVersioncheck = $false
}

#endregion versioncheck

#region collecting
Function msrdTestRegistryValue {
    param ([parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Path, [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Value)

    try {
        return (Get-ItemProperty -Path $Path -ErrorAction Stop).$Value -ne $null
    }
    catch {
        return $false
    }
}

Function msrdRunCommands {
    param(
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$LogPrefix,
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$CmdletArray,
        [parameter(Mandatory=$true)][Bool]$ThrowException,
        [parameter(Mandatory=$true)][Bool]$ShowMessage,
        [parameter(Mandatory=$true)][Bool]$ShowError
    )

    ForEach($CommandLine in $CmdletArray){
        # Get file name of output file. This is used later to add command header line.
		$HasOutFile = $CommandLine -like "*Out-File*"
		If($HasOutFile){
			$OutputFile = $Null
			$Token = $CommandLine -split ' '
			$OutputFileCandidate = $Token[$Token.count-1] # Last token should be output file.
			If($OutputFileCandidate -match '\.txt' -or $OutputFileCandidate -match '\.log'){
				$OutputFile = $OutputFileCandidate
                $OutputFile = $OutputFile -replace "'",""
			}
		}

        $tmpMsg = $CommandLine -replace " \| Out-File.*$","" -replace " \| Out-Null.*$","" -replace "\-ErrorAction Stop","" -replace "\-ErrorAction SilentlyContinue","" -replace "\-ErrorAction Ignore",""
        $CmdlineForDisplayMessage = $tmpMsg -replace "' '(.*?)' /y","'" -replace "' '(.*?)' 2>&1","'" -replace " 2>&1","" -replace " --log-file.*$","" -replace " -zip.*$",""

        Try {
            If ($ShowMessage) { msrdLogMessage $LogLevel.Normal -LogPrefix $LogPrefix -Message $CmdlineForDisplayMessage }

            # There are some cases where Invoke-Expression does not reset $global:LASTEXITCODE and $global:LASTEXITCODE has old error value.
			# Hence we initialize the $global:LASTEXITCODE(PowerShell managed value) if it has error before running command.
			If($Null -ne $global:LASTEXITCODE -and $global:LASTEXITCODE -ne 0){
				$global:LASTEXITCODE = 0
			}

            # Add a header if there is an output file.
			If ($Null -ne $OutputFile){
				"======================================" | Out-File -Append $OutputFile
				"$((Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")) : $CmdlineForDisplayMessage" | Out-File -Append $OutputFile
				"======================================`n" | Out-File -Append $OutputFile
			}

            # Run actual command here.
			# We redirect all streams to temporary error file as some commands output an error to warning stream(3) and others are to error stream(2).
            Invoke-Expression -Command $CommandLine -ErrorAction Stop *> $global:msrdTempCommandErrorFile

            # It is possible $global:LASTEXITCODE becomes null in some sucessful case, so perform null check and examine error code.
            If ($Null -ne $global:LASTEXITCODE -and $global:LASTEXITCODE -ne 0 -and $global:LASTEXITCODE -ne -2){ # procdump may exit with 0xfffffffe = -2
                $Message = "An error happened during running `'$CommandLine` " + '(Error=0x' + [Convert]::ToString($global:LASTEXITCODE,16) + ')'
                msrdLogMessage $LogLevel.ErrorLogFileOnly $Message
                If (Test-Path -Path $global:msrdTempCommandErrorFile) {
                    # Always log error to error file.
                    Get-Content $global:msrdTempCommandErrorFile -ErrorAction Ignore | Out-File -Append $global:msrdErrorLogFile
                    # If -ShowError:$True, show the error to console.
                    If ($ShowError) {
                        $host.ui.RawUI.ForegroundColor = "Red"
                        Write-Output "$Message"
                        Write-Output ('---------- ERROR MESSAGE ----------')
                        Get-Content $global:msrdTempCommandErrorFile -ErrorAction Ignore
                        Write-Output ('-----------------------------------')
                        $host.ui.RawUI.ForegroundColor = $global:msrdConsoleColor
                    }
                }
                Remove-Item $global:msrdTempCommandErrorFile -Force -ErrorAction Ignore | Out-Null
                If ($ThrowException) { Throw($Message) }
            } else {
                Remove-Item $global:msrdTempCommandErrorFile -Force -ErrorAction Ignore | Out-Null
            }

        } Catch {
            If ($ThrowException) {
                Throw $_   # Leave the error handling to upper function.
            } Else {
                $Message = "An error happened in Invoke-Expression with $CommandLine"
                msrdLogException ($Message) -ErrObj $_ -fErrorLogFileOnly
                If ($ShowError){
                    $host.ui.RawUI.ForegroundColor = "Red"
                    Write-Output ("ERROR: $Message")
                    Write-Output ('---------- ERROR MESSAGE ----------')
                    Write-Output $_
                    Write-Output ('-----------------------------------')
                    $host.ui.RawUI.ForegroundColor = $global:msrdConsoleColor
                }
                Continue
            }
        }
    }
}

function msrdCollectData {
    param([bool[]]$varsCore, [bool[]]$varsProfiles, [bool[]]$varsActivation, [bool[]]$varsMSRA, [bool[]]$varsSCard, [bool[]]$varsIME, [bool[]]$varsTeams, [bool[]]$varsMSIXAA, [bool[]]$varsHCI, [bool]$traceNet, [bool]$dumpProc, [int]$pidProc, [switch]$skipDiagCounter = $false)

    $global:msrdCollecting = $True
    $global:msrdDiagnosing = $False
    Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-CommonsCollect" -DisableNameChecking -Force -Scope Global

    # init progress indicator
    $msrdDivider = 1
    if ($traceNet) { $msrdDivider++ }
    if ($true -in $varsCore) { $msrdDivider += 247 }
    if ($true -in $varsProfiles) { $msrdDivider += 55 }
    if ($true -in $varsActivation) { $msrdDivider += 3 }
    if ($true -in $varsMSRA) { $msrdDivider += 9 }
    if ($true -in $varsSCard) { $msrdDivider += 9 }
    if ($true -in $varsIME) { $msrdDivider += 36 }
    if ($true -in $varsTeams) { $msrdDivider += 4 }
    if ($true -in $varsMSIXAA) { $msrdDivider += 3 }
    if ($true -in $varsHCI) { $msrdDivider += 5 }
    if ((-not $global:onlyDiag) -and (-not $skipDiagCounter)) { $msrdDivider += 74 } #diagnostics

    msrdProgressStatusInit $msrdDivider

    if ($traceNet) {
        $global:msrdProgScenario = "Tracing"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Tracing" -DisableNameChecking -Force
        msrdRunUEX_NetTracing
        Remove-Module MSRDC-Tracing
    }

    if ($true -in $varsCore) {
        $global:msrdProgScenario = "Core"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Html" -DisableNameChecking -Force -Scope Global
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Core" -DisableNameChecking -Force
        if (-not $global:msrdRDS) { msrdCloseMSRDC }
        msrdCollectUEX_AVDCoreLog -varsCore $varsCore -dumpProc $dumpProc -pidProc $pidProc
        Remove-Module MSRDC-Core
    }

    if ($true -in $varsProfiles) {
        $global:msrdProgScenario = "Profiles"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Profiles" -DisableNameChecking -Force
        msrdCollectUEX_AVDProfilesLog -varsProfiles $varsProfiles
        Remove-Module MSRDC-Profiles
    }

    if ($true -in $varsActivation) {
        $global:msrdProgScenario = "Activation"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Activation" -DisableNameChecking -Force
        msrdCollectUEX_AVDActivationLog -varsActivation $varsActivation
        Remove-Module MSRDC-Activation
    }

    if ($true -in $varsMSRA) {
        $global:msrdProgScenario = "Remote Assistance"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-MSRA" -DisableNameChecking -Force
        msrdCollectUEX_AVDMSRALog -varsMSRA $varsMSRA
        Remove-Module MSRDC-MSRA
    }

    if ($true -in $varsSCard) {
        $global:msrdProgScenario = "Smart Card"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-SCard" -DisableNameChecking -Force
        msrdCollectUEX_AVDSCardLog -varsSCard $varsSCard
        Remove-Module MSRDC-SCard
    }

    if ($true -in $varsIME) {
        $global:msrdProgScenario = "IME"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-IME" -DisableNameChecking -Force
        msrdCollectUEX_AVDIMELog -varsIME $varsIME
        Remove-Module MSRDC-IME
    }

    if ($true -in $varsTeams) {
        $global:msrdProgScenario = "Teams"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Teams" -DisableNameChecking -Force
        msrdCollectUEX_AVDTeamsLog -varsTeams $varsTeams
        Remove-Module MSRDC-Teams
    }

    if ($true -in $varsMSIXAA) {
        $global:msrdProgScenario = "MSIX App Attach"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-MSIXAA" -DisableNameChecking -Force
        msrdCollectUEX_AVDMSIXAALog -varsMSIXAA $varsMSIXAA
        Remove-Module MSRDC-MSIXAA
    }

    if ($true -in $varsHCI) {
        $global:msrdProgScenario = "Azure Stack HCI"
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-HCI" -DisableNameChecking -Force
        msrdCollectUEX_AVDHCILog -varsHCI $varsHCI
        Remove-Module MSRDC-HCI
    }

    $global:msrdCollecting = $False
    msrdLogMessage $LogLevel.Info -Message "$(msrdGetLocalizedText "fdcmsg")`n" -Color "Cyan"

    if ($skipDiagCounter) { msrdProgressStatusEnd }

    Remove-Module MSRDC-CommonsCollect

    [System.GC]::Collect()
}

Function msrdCollectDataDiag {
    param ([bool[]]$varsSystem, [bool[]]$varsAVDRDS, [bool[]]$varsInfra, [bool[]]$varsAD, [bool[]]$varsNET, [bool[]]$varsLogSec, [bool[]]$varsIssues, [bool[]]$varsOther)

    if ($global:onlyDiag) {
        msrdProgressStatusInit 74
    }

    if (-not (Get-Module -Name MSRDC-Html)) {
        Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Html" -DisableNameChecking -Force -Scope Global
    }

    $global:msrdDiagnosing = $True
    $global:msrdProgScenario = "Diagnostics"

    Import-Module -Name "$global:msrdScriptpath\Modules\MSRDC-Diag" -DisableNameChecking -Force
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
    msrdRunUEX_RDDiag @parameters

    "`n`n" | Out-File -Append $global:msrdOutputLogFile

    msrdLogMessage $LogLevel.Info "$(msrdGetLocalizedText "fdiagmsg")`n" -Color "Cyan"

    $global:msrdDiagnosing = $False
    if ($global:msrdGUI -or ($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) {
        $global:msrdProgbar.Value = $global:msrdProgbar.Maximum;
        $global:msrdStatusBarLabel.Text = "$(msrdGetLocalizedText "wait")"
    }

    Remove-Module MSRDC-Html

    msrdProgressStatusEnd
}

Function msrdArchiveData {
    param( [bool[]]$varsCore )

    $mspathnfo = $global:msrdSysInfoLogFolder + $global:msrdLogFilePrefix + "Msinfo32.nfo"
    $dllpath = $global:msrdSysInfoLogFolder + $global:msrdLogFilePrefix + "System32_DLL.txt"
    $gpresultpath = $global:msrdSysInfoLogFolder + $global:msrdLogFilePrefix + "Gpresult.html"
    $powercfgpath = $global:msrdSysInfoLogFolder + $global:msrdLogFilePrefix + "PowerReport.html"
    $acttime = 0
    $waittime = 20000
    $maxtime = 180000
    $nfoproc = Get-Process msinfo32 -ErrorAction SilentlyContinue

    if ($global:msrdGUI -or ($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) {
        $global:msrdProgbar.Visible = $false
        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "arcmsg"
    }

    if (!($global:onlyDiag)) {
        while ($varsCore[7] -and (!(Test-Path $mspathnfo) -or !(Test-Path $dllpath) -or !(Test-Path $gpresultpath) -or !(Test-Path $powercfgpath) -or ($nfoproc))) {
            if ($acttime -lt $maxtime) {
                msrdLogMessage $LogLevel.Normal -Message "$(msrdGetLocalizedText "bgjob1msg")" -Color "White"
                Start-Sleep -m $waittime
                $acttime += $waittime
                $nfoproc = Get-Process msinfo32 -ErrorAction SilentlyContinue
            } else {
                msrdLogMessage $LogLevel.Warning -Message "$(msrdGetLocalizedText "bgjob2msg")`n"
                $nfoproc = Get-Process msinfo32 -ErrorAction SilentlyContinue
                if ($nfoproc) {
                    $nfoproc.CloseMainWindow() | Out-Null
                }
                Start-Sleep 5
                if (!$nfoproc.HasExited) { $nfoproc | Stop-Process -Force }
                Break
            }
        }
        Get-Job | Wait-Job | Remove-Job
    }

    $destination = "$global:msrdLogRoot\$msrdLogFolder.zip"

    msrdLogMessage $LogLevel.Info "$(msrdGetLocalizedText "archmsg")" -Color "Cyan"

    Try {
        Add-Type -Assembly 'System.IO.Compression.FileSystem'
		[System.IO.Compression.ZipFile]::CreateFromDirectory($global:msrdLogDir, $destination)
    } Catch {
		$ErrorMessage = "An exception occurred during log folder compression`n" + $_.Exception.Message
		msrdLogException $ErrorMessage $_ -fErrorLogFileOnly
		Return
	}

    if ($global:msrdGUI -or ($global:msrdGUIformLite -and $global:msrdGUIformLite.Visible)) {
        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
    }

    if (Test-path -path $destination) {
        if ($global:msrdGUI) {
            msrdLogMessage $LogLevel.Normal "$(msrdGetLocalizedText "zipmsg") $destination`n" -Color "#00ff00" -addAssist
        } else {
            msrdLogMessage $LogLevel.Normal "$(msrdGetLocalizedText "zipmsg") $destination`n" -Color "Green" -addAssist
        }
        if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Logon" }
    } else {
        msrdLogMessage $LogLevel.Warning "$(msrdGetLocalizedText "ziperrormsg") $global:msrdLogRoot\$msrdLogFolder`n" -addAssist
        if ($global:msrdPlaySounds -eq 1) { msrdPlaySystemSound "Windows Exclamation" }
    }
    msrdLogMessage $LogLevel.Normal "$(msrdGetLocalizedText "dtmmsg")`n" -Color "White" -addAssist

    Remove-Module MSRDC-Diag -ErrorAction SilentlyContinue

    explorer $global:msrdLogRoot

    if ($global:msrdGUI) {
        $global:msrdStatusBarLabel.Text = msrdGetLocalizedText "Ready"
        $global:msrdCollectcount = 1
    }

    [System.GC]::Collect()
}

function msrdUpdateConfigFile {
    Param([string]$configFile,[string]$key,[string]$value)

    $configpath = "$global:msrdScriptpath\$configFile"

    (Get-Content $configpath) | ForEach-Object {
        if ($_ -like "$key=*") {
            $_ = "$key=" + $value
        }
        $_
    } | Set-Content $configFile
}



# Function to play a system sound
function msrdPlaySystemSound([string]$soundName)
{
    $SoundPath = "C:\Windows\Media\" + $soundName + ".wav"

    $player = New-Object System.Media.SoundPlayer
    $player.SoundLocation = $SoundPath
    $player.Load()
    $player.Play()
}

# Function restart

function msrdRestart {
    Write-Host "Display language changed. Restarting script to apply changes.`n" -ForegroundColor Yellow
    try {
        Start-Process PowerShell.exe -ArgumentList "$global:msrdCmdLine" -NoNewWindow
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
}

#endregion collecting

Export-ModuleMember -Function *
# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCATavU23NkzbLDf
# 6raI95yZtIwEUsxeyCPYBU9sDO3EpqCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILq5Siiyhkk5AWl+j4nhsau6
# N9yf6hzl+gE6qxIFzAFIMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAJZOHFpPJffWKpwTwxW5d7YHw6+lj+jutXkqbfsfS6YPkJ6m1rqBRCwOk
# RvVXd7mCYaxFkL4i8hc++hhJOrmGpvbdDiFLFqI9JohDovlTQWY/bfMUelVpSl8N
# nobraTo5bhrAegfRc9UviOoCTNygwat6VGEyBfuWBkbDAP880nMrMTKRcM8Q6OEH
# IBcqLctXlSGhrCe7B4HjTiFQnxHxTwf42RWLfc9vQ5PgpWPeKCkX41f4h6laVx5k
# v73RP8ZJmmtMZoykQHWpG8Etj/yYGTKpLWvq1nN6tsNEiZ/n8WTl+JoyLzXoYN3J
# +MXbyIS+M0FXWdygAXJiaSR6O1sRXKGCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCB95T/G2py/7QoL/DYUOu3mxVnvr7qnhW96YAsjyU+4DQIGZlcW3Vio
# GBMyMDI0MDYxMjE1MDAzOC4xNThaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OjhENDEtNEJGNy1CM0I3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHj372bmhxogyIAAQAAAeMwDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMx
# MDEyMTkwNzI5WhcNMjUwMTEwMTkwNzI5WjCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo4RDQxLTRC
# RjctQjNCNzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL6kDWgeRp+fxSBUD6N/yuEJ
# pXggzBeNG5KB8M9AbIWeEokJgOghlMg8JmqkNsB4Wl1NEXR7cL6vlPCsWGLMhyqm
# scQu36/8h2bx6TU4M8dVZEd6V4U+l9gpte+VF91kOI35fOqJ6eQDMwSBQ5c9ElPF
# UijTA7zV7Y5PRYrS4FL9p494TidCpBEH5N6AO5u8wNA/jKO94Zkfjgu7sLF8SUdr
# c1GRNEk2F91L3pxR+32FsuQTZi8hqtrFpEORxbySgiQBP3cH7fPleN1NynhMRf6T
# 7XC1L0PRyKy9MZ6TBWru2HeWivkxIue1nLQb/O/n0j2QVd42Zf0ArXB/Vq54gQ8J
# IvUH0cbvyWM8PomhFi6q2F7he43jhrxyvn1Xi1pwHOVsbH26YxDKTWxl20hfQLdz
# z4RVTo8cFRMdQCxlKkSnocPWqfV/4H5APSPXk0r8Cc/cMmva3g4EvupF4ErbSO0U
# NnCRv7UDxlSGiwiGkmny53mqtAZ7NLePhFtwfxp6ATIojl8JXjr3+bnQWUCDCd5O
# ap54fGeGYU8KxOohmz604BgT14e3sRWABpW+oXYSCyFQ3SZQ3/LNTVby9ENsuEh2
# UIQKWU7lv7chrBrHCDw0jM+WwOjYUS7YxMAhaSyOahpbudALvRUXpQhELFoO6tOx
# /66hzqgjSTOEY3pu46BFAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUsa4NZr41Fbeh
# Z8Y+ep2m2YiYqQMwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBALe+my6p1NPMEW1t
# 70a8Y2hGxj6siDSulGAs4UxmkfzxMAic4j0+GTPbHxk193mQ0FRPa9dtbRbaezV0
# GLkEsUWTGF2tP6WsDdl5/lD4wUQ76ArFOencCpK5svE0sO0FyhrJHZxMLCOclvd6
# vAIPOkZAYihBH/RXcxzbiliOCr//3w7REnsLuOp/7vlXJAsGzmJesBP/0ERqxjKu
# dPWuBGz/qdRlJtOl5nv9NZkyLig4D5hy9p2Ec1zaotiLiHnJ9mlsJEcUDhYj8PnY
# nJjjsCxv+yJzao2aUHiIQzMbFq+M08c8uBEf+s37YbZQ7XAFxwe2EVJAUwpWjmtJ
# 3b3zSWTMmFWunFr2aLk6vVeS0u1MyEfEv+0bDk+N3jmsCwbLkM9FaDi7q2HtUn3z
# 6k7AnETc28dAvLf/ioqUrVYTwBrbRH4XVFEvaIQ+i7esDQicWW1dCDA/J3xOoCEC
# V68611jriajfdVg8o0Wp+FCg5CAUtslgOFuiYULgcxnqzkmP2i58ZEa0rm4LZymH
# BzsIMU0yMmuVmAkYxbdEDi5XqlZIupPpqmD6/fLjD4ub0SEEttOpg0np0ra/MNCf
# v/tVhJtz5wgiEIKX+s4akawLfY+16xDB64Nm0HoGs/Gy823ulIm4GyrUcpNZxnXv
# E6OZMjI/V1AgSAg8U/heMWuZTWVUMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
# RDQxLTRCRjctQjNCNzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUAPYiXu8ORQ4hvKcuE7GK0COgxWnqggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOoUCBUwIhgPMjAyNDA2MTIxOTQyMTNaGA8yMDI0MDYxMzE5NDIxM1owdDA6Bgor
# BgEEAYRZCgQBMSwwKjAKAgUA6hQIFQIBADAHAgEAAgIMKjAHAgEAAgIR2jAKAgUA
# 6hVZlQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAID
# B6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAB2H26nt42o/vxK3P/MZ
# kPl4scck4Vuby4sQf3ugEZiJdQ/U+VoU8CKkkYmk/mM5yVMD4hOlzpQqPVQHQFNz
# YtAwacWJR5o9K1XGKU+rSoRKtrGTW8eOLxYEmaQOVZfJir3WiJk1yDYLVDS2Xkbt
# MkcqVhAjyeGff5rNCAS1dyv6MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBIDIwMTACEzMAAAHj372bmhxogyIAAQAAAeMwDQYJYIZIAWUDBAIB
# BQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
# IgQg3841xRy/x8C8Q0ZPQMY3wP8aAFLYtQxiqzaowwzNwHEwgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCAz1COr5bD+ZPdEgQjWvcIWuDJcQbdgq8Ndj0xyMuYm
# KjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB49+9
# m5ocaIMiAAEAAAHjMCIEINsd2aW1Y7wtnrogb26/8zWtZkK5NN+chuZAiFvrXewx
# MA0GCSqGSIb3DQEBCwUABIICAEVLgGR/22tr244Zr63yRyXDMoTW0Q11gipWbIET
# Zp3YDLSRJ9FKE5adlrOA/tr/zCkxUH5mJhPKxQwTaqCRQKeYAVZZBc/VXD9IaKW3
# CX++UeC0GvkaqGiALgNHxK/RUBb+HkC7CmfNU+dja6bF1oz95Pi6fZploidN59po
# /Hq0CjLwk9f2FAlgiFVjkr3i9E+IR7iHHIqVpU3+ZfxRwACemZ5652UrymHeW216
# LP34PDdw3mO57+24WcUuxSJLorpPCASnhXfe0c046PdmtoocbINpcZ2nW0sTxuQ+
# W0Iss9oDXfOCNEzw2YMKZdhr/tJfZvgBH9oupNUiqJ2xZJ0bU3v6LScFknAKLKGD
# purr2WdWSZw8pzmD01PK5YIdISndYi7/Kv8iVBJd3Zx1ZfJZlVikQxj0fV0q6BrA
# hjIuFmtWqy1WQZ7PN6EdeMPVfJzzCLKfyjC2n+YHdGP8DSOAWE6Fgz7YhJrFO0Yl
# ewhAJ4FyV/Szg4vdphXmKFY9zOmctT9haTHDHidoNOaPjRjLg6A9yY5afOyLl8yx
# DDxp8Rc4eOuv9Fcx7NyiLOzj4vLDFWg/6s+NRfaHbKz8JMg5KQUN1EAHsampbm8i
# tM3NzxJ//OPg6ZpFvUMirsIbqQAx9JpXuAr0j+LupBYYvlt8ueEnm7WN2w6bjnbY
# w95e
# SIG # End signature block
