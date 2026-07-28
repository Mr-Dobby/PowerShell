<#
.SYNOPSIS
   Scenario module for collecting Microsoft Remote Desktop Profiles related data

.DESCRIPTION
   Collect Profiles related troubleshooting data (incl. FSLogix, OneDrive)

.NOTES
   Author     : Robert Klemencz
   Requires   : MSRD-Collect.ps1
   Version    : See MSRD-Collect.ps1 version
   Feedback   : https://aka.ms/MSRD-Collect-Feedback
#>

$msrdLogPrefix = "Profiles"
$ProfilesLogFolder = $global:msrdBasicLogFolder + "Profiles\"
$FSLogixLogFolder = $ProfilesLogFolder + "FSLogix\"

Function msrdGetFSLogixLogFiles {
    Param([Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$LogFilePath,
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$LogFileDestination)

    #get FSLogix log files
    msrdLogMessage $LogLevel.Normal -LogPrefix $msrdLogPrefix -Message "Copy-Item $LogFilePath"
    if (Test-path -path "$LogFilePath") {
        Try {
            msrdCreateLogFolder $LogFileDestination
            Copy-Item $LogFilePath $LogFileDestination -Recurse -ErrorAction Continue 2>&1 | Out-Null
        } Catch {
            $failedCommand = $_.InvocationInfo.Line.TrimStart()
            msrdLogException ("$(msrdGetLocalizedText "errormsg") $failedCommand") -ErrObj $_
        }
    } else {
        msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'$LogFilePath' folder not found"
    }
}

Function msrdGetFSLogixCompact {

    #get FSLogix compact action logs
    msrdLogMessage $LogLevel.Normal -LogPrefix $msrdLogPrefix -Message "FSLogix VHD compaction events"
    $startTime = (Get-Date).AddDays(-5)

    $diskCompactionEvents = Get-WinEvent -FilterHashtable @{StartTime = $startTime; logname = 'Microsoft-FSLogix-Apps/Operational'; id = 57} -ErrorAction SilentlyContinue

    if ($diskCompactionEvents) {
        $compactionMetrics = $diskCompactionEvents | Select-Object `
            @{l="Timestamp";e={$_.TimeCreated}},`
            @{l="Path";e={$_.Properties[0].Value}},`
            @{l="WasCompacted";e={$_.Properties[1].Value}},`
            @{l="TimeSpent(ms)";e={[math]::round($_.Properties[7].Value,2)}},`
            @{l="MaxSupportedSize(MB)";e={[math]::round($_.Properties[2].Value,2)}},`
            @{l="MinSupportedSize(MB)";e={[math]::round($_.Properties[3].Value,2)}},`
            @{l="InitialSize(MB)";e={[math]::round($_.Properties[4].Value,2)}},`
            @{l="FinalSize(MB)";e={[math]::round($_.Properties[5].Value,2)}},`
            @{l="SavedSpace(MB)";e={[math]::round($_.Properties[6].Value,2)}}

        $compactionMetrics | Out-File -FilePath ($FSLogixLogFolder + $global:msrdLogFilePrefix + "vhdCompactionEvents.txt") -Append
    } else {
        msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "FSLogix VHD compaction events not found"
    }
}

Function msrdGetFSLogixRedirXML {

    #get FSLogix redirection xml information
    msrdLogMessage $LogLevel.Normal -LogPrefix $msrdLogPrefix -Message "FSLogix Redirections XML"

    if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "RedirXMLSourceFolder") {
        $pxml = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\FSLogix\Profiles\" -name "RedirXMLSourceFolder"
        $pxmlfile = $pxml + "\redirections.xml"
        $pxmlout = $FSLogixLogFolder + $env:computername + "_redirections.xml"

        if (Test-Path -Path $pxmlfile) {
            Try {
                Copy-Item $pxmlfile $pxmlout -ErrorAction Continue 2>&1 | Out-Null
            } Catch {
                msrdLogException ("Error: An exception occurred in msrdGetFSLogixRedirXML $pxmlfile.") -ErrObj $_
            }
        } else {
            msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'$pxmlfile' log not found"
        }
    } else {
        msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "RedirXMLSourceFolder registry key not found"
    }
}

Function msrdGetProfilesRegKeys {

    msrdCreateLogFolder $msrdRegLogFolder
    $regs = @{
        'HKCU:\SOFTWARE\Microsoft\Office' = 'SW-MS-Office'
        'HKLM:\SOFTWARE\Microsoft\OneDrive' = 'SW-MS-OneDrive'
        'HKCU:\SOFTWARE\Microsoft\OneDrive' = 'SW-MS-OneDrive'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers' = 'SW-MS-Win-CV-Auth-CredProviders'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' = 'SW-MS-Win-CV-Explorer-ShellFolders'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' = 'SW-MS-Win-CV-Explorer-ShellFolders'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' = 'SW-MS-Win-CV-Explorer-UserShellFolders'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' = 'SW-MS-Win-CV-Explorer-UserShellFolders'
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' = 'SW-MS-WinNT-CV-ProfileList'
        'HKLM:\SOFTWARE\Microsoft\Windows Search' = 'SW-MS-WindowsSearch'
        'HKCU:\Volatile Environment' = 'VolatileEnvironment'
    }

    if ($global:msrdAVD -or $global:msrdRDS) {
        $regs += @{
            'HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI\Disk&Ven_Msft&Prod_Virtual_Disk' = 'System-CCS-Enum-SCSI-ProdVirtualDisk'
            'HKLM:\SOFTWARE\FSLogix' = 'SW-FSLogix'
            'HKCU:\SOFTWARE\FSLogix' = 'SW-FSLogix'
        }
    }

    msrdGetRegKeys -LogPrefix $msrdLogPrefix -RegHashtable $regs
}

Function msrdGetProfilesEventLogs {

    msrdCreateLogFolder $global:msrdEventLogFolder
    $logs = @{
        'Microsoft-Windows-User Profile Service/Operational' = 'UserProfileService-Operational'
    }

    if ($global:msrdAVD -or $global:msrdRDS) {
        $logs += @{
            'Microsoft-Windows-VHDMP-Operational' = 'VHDMP-Operational'
            'Microsoft-FSLogix-Apps/Admin' = 'FSLogix-Apps-Admin'
            'Microsoft-FSLogix-Apps/Operational' = 'FSLogix-Apps-Operational'
            'Microsoft-FSLogix-CloudCache/Admin' = 'FSLogix-CloudCache-Admin'
            'Microsoft-FSLogix-CloudCache/Operational' = 'FSLogix-CloudCache-Operational'
        }

        $eventlog = "Microsoft-Windows-Ntfs/Operational"
        msrdLogMessage $LogLevel.Normal -LogPrefix $msrdLogPrefix -Message "Filtered $eventlog event logs"
        $ntfslog = $global:msrdEventLogFolder + $env:computername + "_NTFS_filtered.evtx"

        if (Get-WinEvent -ListLog $eventlog -ErrorAction SilentlyContinue) {
            Try {
                wevtutil epl $eventlog $ntfslog "/q:*[System[(EventID=4 or EventID=142)]]"
            } Catch {
                msrdLogException "Error: An error occurred while exporting the NTFS logs" -ErrObj $_
            }
        } else {
            msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "Event log '$eventlog' not found"
        }
    }

    msrdGetEventLogs -LogPrefix $msrdLogPrefix -EventHashtable $logs
}

Function msrdGetFSLogixData {

    if (Test-path -path "$env:ProgramFiles\FSLogix") {

        msrdCreateLogFolder $FSLogixLogFolder
        msrdGetFSLogixCompact
        msrdGetFSLogixRedirXML

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Logging\" -value "LogDir") {
            $fslogixlogsloc = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\FSLogix\Logging\" -name "LogDir"
        } else {
            $fslogixlogsloc = "$env:ProgramData\FSLogix\Logs"
        }

        if (Test-Path -path $fslogixlogsloc) {
            msrdGetFSLogixLogFiles -LogFilePath "$fslogixlogsloc\*" -LogFileDestination ($FSLogixLogFolder + "Logs")

            $Commands = @(
                "tree '$fslogixlogsloc' /f 2>&1 | Out-File -Append '" + $FSLogixLogFolder + "Logs\" + $global:msrdLogFilePrefix + "tree_ProgFiles-FSLogixLogs.txt'"
            )
            msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
        } else {
            msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'$fslogixlogsloc' folder not found"
        }

        $fslogixrulesloc = "$env:ProgramFiles\FSLogix\Apps\Rules"
        if (Test-Path -path $fslogixrulesloc) {
            msrdCreateLogFolder ($FSLogixLogFolder + "AppsRules")
            msrdGetFSLogixLogFiles -LogFilePath "$fslogixrulesloc\*" -LogFileDestination ($FSLogixLogFolder + "AppsRules")

            $Commands = @(
                "tree '$fslogixrulesloc' /f 2>&1 | Out-File -Append '" + $FSLogixLogFolder + "AppsRules\" + $global:msrdLogFilePrefix + "tree_ProgFiles-FSLogixAppsRules.txt'"
            )
            msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
        } else {
            msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'$fslogixrulesloc' folder not found"
        }

        $fslogixCompiledrulesloc = "$env:ProgramFiles\FSLogix\Apps\CompiledRules"
        if (Test-Path -path $fslogixCompiledrulesloc) {
            msrdCreateLogFolder ($FSLogixLogFolder + "AppsRules")
            $Commands = @(
                "tree '$fslogixCompiledrulesloc' /f 2>&1 | Out-File -Append '" + $FSLogixLogFolder + "AppsRules\" + $global:msrdLogFilePrefix + "tree_ProgFiles-FSLogixAppsCompiledRules.txt'"
            )
            msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
        } else {
            msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'$fslogixCompiledrulesloc' folder not found"
        }

        $fslogixfrxloc = "$env:ProgramFiles\FSLogix\Apps\frx.exe"
        if (Test-path -path $fslogixfrxloc) {
            $Commands = @(
                "cmd /c '$fslogixfrxloc' version 2>&1 | Out-File -Append '" + $FSLogixLogFolder + $global:msrdLogFilePrefix + "frx-list.txt'"
                "cmd /c '$fslogixfrxloc' list-redirects 2>&1 | Out-File -Append '" + $FSLogixLogFolder + $global:msrdLogFilePrefix + "frx-list.txt'"
                "cmd /c '$fslogixfrxloc' list-rules 2>&1 | Out-File -Append '" + $FSLogixLogFolder + $global:msrdLogFilePrefix + "frx-list.txt'"
            )
            msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
        } else {
            msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'$fslogixfrxloc' not found"
        }

        #if applicable, removing accountname and account key from the exported CCDLocations reg key for security reasons
        $ccdRegOutP = $msrdRegLogFolder + $global:msrdLogFilePrefix + "HKLM-SW-FSLogix.txt"
        if (Test-Path -path $ccdRegOutP) {
            $ccdContentP = Get-Content -Path $ccdRegOutP
            $ccdReplaceP = foreach ($ccdItemP in $ccdContentP) {
                if ($ccdItemP -like "*CCDLocations*") {
                    $var1P = $ccdItemP -split ";"
                    $var2P = foreach ($varItemP in $var1P) {
                                if ($varItemP -like "AccountName=*") { $varItemP = "AccountName=xxxxxxxxxxxxxxxx"; $varItemP }
                                elseif ($varItemP -like "AccountKey=*") { $varItemP = "AccountKey=xxxxxxxxxxxxxxxx"; $varItemP }
                                else { $varItemP }
                            }
                    $var3P = $var2P -join ";"
                    $var3P
                } else {
                    $ccdItemP
                }
            }
            $ccdReplaceP | Set-Content -Path $ccdRegOutP
        }

        $ccdRegOutO = $msrdRegLogFolder + $global:msrdLogFilePrefix + "HKLM-SW-Policies.txt"
        if (Test-Path -path $ccdRegOutO) {
            $ccdContentO = Get-Content -Path $ccdRegOutO
            $ccdReplaceO = foreach ($ccdItemO in $ccdContentO) {
                if ($ccdItemO -like "*CCDLocations*") {
                    $var1O = $ccdItemO -split ";"
                    $var2O = foreach ($varItemO in $var1O) {
                                if ($varItemO -like "AccountName=*") { $varItemO = "AccountName=xxxxxxxxxxxxxxxx"; $varItemO }
                                elseif ($varItemO -like "AccountKey=*") { $varItemO = "AccountKey=xxxxxxxxxxxxxxxx"; $varItemO }
                                else { $varItemO }
                            }
                    $var3O = $var2O -join ";"
                    $var3O
                } else {
                    $ccdItemO
                }
            }
            $ccdReplaceO | Set-Content -Path $ccdRegOutO
        }

        msrdGetLocalGroupMembership -logPrefix $msrdLogPrefix -groupName "FSLogix ODFC Exclude List" -outputFile ($FSLogixLogFolder + $global:msrdLogFilePrefix + "LocalGroupsMembership.txt")
        msrdGetLocalGroupMembership -logPrefix $msrdLogPrefix -groupName "FSLogix ODFC Include List" -outputFile ($FSLogixLogFolder + $global:msrdLogFilePrefix + "LocalGroupsMembership.txt")
        msrdGetLocalGroupMembership -logPrefix $msrdLogPrefix -groupName "FSLogix Profile Exclude List" -outputFile ($FSLogixLogFolder + $global:msrdLogFilePrefix + "LocalGroupsMembership.txt")
        msrdGetLocalGroupMembership -logPrefix $msrdLogPrefix -groupName "FSLogix Profile Include List" -outputFile ($FSLogixLogFolder + $global:msrdLogFilePrefix + "LocalGroupsMembership.txt")

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "VHDLocations") {
            $pvhd = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\FSLogix\Profiles\" -name "VHDLocations"

            $Commands = @(
                "icacls $pvhd 2>&1 | Out-File -Append " + $FSLogixLogFolder + $global:msrdLogFilePrefix + "folderPermissions.txt"
            )
            msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
        }

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -value "VHDLocations") {
            $ovhd = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC\" -name "VHDLocations"

            $Commands = @(
                "icacls $ovhd 2>&1 | Out-File -Append " + $FSLogixLogFolder + $global:msrdLogFilePrefix + "folderPermissions.txt"
            )
            msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
        }


        #Collecting AAD Kerberos Auth for FSLogix
        $Commands = @(
                "klist get krbtgt 2>&1 | Out-File -Append " + $ProfilesLogFolder + $global:msrdLogFilePrefix + "klist-get-krbtgt.txt"
            )
        msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True

        if (msrdTestRegistryValue -path "HKLM:\SOFTWARE\FSLogix\Profiles\" -value "VHDLocations") {
                $pvhd = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\FSLogix\Profiles\" -name "VHDLocations" -ErrorAction SilentlyContinue
                $pconPath = $pvhd.split("\")[2]
                if ($pconPath) {
                    $Commands = @(
                        "klist get cifs/$pconPath 2>&1 | Out-File -Append " + $FSLogixLogFolder + $global:msrdLogFilePrefix + "klist-get-cifs-ProfileVHDLocations.txt"
                    )
                    msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True
                }
        } else {
            msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'HKLM:\SOFTWARE\FSLogix\Profiles\VHDLocations' not found. Skipping 'klist get cifs/...'"
        }

        $fslpnpout = $FSLogixLogFolder + $global:msrdLogFilePrefix + "PnpUtil-export-pnpstate.pnp"
        $Commands = @(
            "pnputil /export-pnpstate '$fslpnpout' 2>&1 | Out-Null"
        )
        msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray $Commands -ThrowException:$False -ShowMessage:$True -ShowError:$True

    } else {
        msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "'$env:ProgramFiles\FSLogix' folder not found"
    }
}

#Collect VHDX config consistency
Function msrdVirtualDiskRegConsistency {

    $registryPath = "HKLM:\System\CurrentControlSet\Enum\SCSI\Disk&Ven_Msft&Prod_Virtual_Disk"
    $headerVDRC = @"
======================================
"Consistency check for '$registryPath\' (relevant for mounting UPD or FSlogix profile disks)
======================================`n
"@
    $headerVDRC | Out-File -Append ($ProfilesLogFolder + $global:msrdLogFilePrefix + "VirtualDiskRegConsistency.txt")

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
                "[WARNING] Subkey $($item.PSChildName) is missing the following critical registry value(s): '$missingString'" | Out-File -Append ($ProfilesLogFolder + $global:msrdLogFilePrefix + "VirtualDiskRegConsistency.txt")
                $missingCounter += 1
            } else {
                "Subkey $($item.PSChildName) has all expected registry values (ClassGUID, Mfg, Service) present" | Out-File -Append ($ProfilesLogFolder + $global:msrdLogFilePrefix + "VirtualDiskRegConsistency.txt")
            }
        }

        if ($missingCounter -eq 0) {
            "`n`n--------------------------------------`nNo missing registry values found under '$registryPath'" | Out-File -Append ($ProfilesLogFolder + $global:msrdLogFilePrefix + "VirtualDiskRegConsistency.txt")
        } else {
            "`n`n--------------------------------------`n[WARNING] $missingCounter subkeys are missing one or more critical registry values. Users may run into issues while mounting their UPD or FSLogix profile disks during logon." | Out-File -Append ($ProfilesLogFolder + $global:msrdLogFilePrefix + "VirtualDiskRegConsistency.txt")
        }
    } else {
		msrdLogMessage $LogLevel.WarnLogFileOnly -LogPrefix $msrdLogPrefix -Message "Registry path '$registryPath' was not found"
    }
}

# Collecting User Profiles troubleshooting data
Function msrdCollectUEX_AVDProfilesLog {
    param( [bool[]]$varsProfiles )

    if ($true -contains $varsProfiles) {
        if ($global:msrdSilentMode -eq 1) { msrdLogMessage $LogLevel.Normal "`n" -NoDate } else { " " | Out-File -Append $global:msrdOutputLogFile }
        msrdLogMessage $LogLevel.Info "$(msrdGetLocalizedText 'profilesmsg')" -silentException
        msrdCreateLogFolder $ProfilesLogFolder
    }

    if ($varsProfiles[0]) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collect User Profiles related event logs" }
        msrdGetProfilesEventLogs
    } #profiles event logs

    if ($varsProfiles[1]) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collect User Profiles related registry keys" }
        msrdGetProfilesRegKeys
    } #profiles reg keys

    if ($varsProfiles[2]) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collect WhoAmI information" }
        msrdRunCommands -LogPrefix $msrdLogPrefix -CmdletArray ("Whoami /all 2>&1 | Out-File -Append '" + $ProfilesLogFolder + $global:msrdLogFilePrefix + "WhoAmI-all.txt'") -ThrowException:$False -ShowMessage:$True -ShowError:$True
    } #whoami information

    if ($varsProfiles[3] -and ($global:msrdAVD -or $global:msrdRDS)) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collect FSLogix data" }
        msrdGetFSLogixData
    } #fslogix logs

    if ($varsProfiles[4] -and ($global:msrdAVD -or $global:msrdRDS)) {
        if ($global:msrdAudioAssistMode -eq 1) { msrdLogMessageAssistMode "Collect Virtual Disk registry consistency information" }
        msrdVirtualDiskRegConsistency
    } #virtual disk registry consistency
}

Export-ModuleMember -Function msrdCollectUEX_AVDProfilesLog
# SIG # Begin signature block
# MIInvgYJKoZIhvcNAQcCoIInrzCCJ6sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDP+zDK7cu5o0BH
# zBArz1bSYXQUfXR1VTQ3Z1109S2T8qCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGZ4wghmaAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILnK8XPd35zamEAf/Drl5PfY
# 0df7NICloGq6+NZ4OXV7MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAFhOCIFHBbV4WHM+tNbZ/AZMaSAH8ZxYxe9nw3v1IyPQ6+Z3l+X/lJNjK
# w92a0lCvxDId+O+xs8i/IVjEJhfKcR9jBmWen68Gsm3vPxvNAfxwhjEr/n1GmVR0
# yu9pqMoKumSETRVaDtzDyR12/1lmnnhcRcJm6qSn+K6sNqZtRvp05JuW2Adx09K9
# q2Yys5/dPH/axspoYqhisIslaQW7V5Zfgt3q9nij+DUCjkzAHi4toXTGsECiVRY5
# OmeIFw4z9sRsFIf4XELo/nTafA1BnWORGsFbXw43TKBE8mU/DEprJfrkRjouq/wI
# 65PtLU19mJApIHsUB4aau03rVyt6d6GCFygwghckBgorBgEEAYI3AwMBMYIXFDCC
# FxAGCSqGSIb3DQEHAqCCFwEwghb9AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFYBgsq
# hkiG9w0BCRABBKCCAUcEggFDMIIBPwIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCCO75vVbTViJxR146anwXsdfWWoYDiDCzWue06ZmPy4nQIGZlcnzspH
# GBIyMDI0MDYxMjE1MDA0MC4wNlowBIACAfSggdikgdUwgdIxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVs
# YW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046
# MTc5RS00QkIwLTgyNDYxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2WgghF4MIIHJzCCBQ+gAwIBAgITMwAAAeDU/B8TFR9+XQABAAAB4DANBgkq
# hkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEw
# MTIxOTA3MTlaFw0yNTAxMTAxOTA3MTlaMIHSMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVy
# YXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjE3OUUtNEJC
# MC04MjQ2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArIec86HFu9EBOcaNv/p+4GGH
# dkvOi0DECB0tpn/OREVR15IrPI23e2qiswrsYO9xd0qz6ogxRu96eUf7Dneyw9rq
# tg/vrRm4WsAGt+x6t/SQVrI1dXPBPuNqsk4SOcUwGn7KL67BDZOcm7FzNx4bkUMe
# sgjqwXoXzv2U/rJ1jQEFmRn23f17+y81GJ4DmBSe/9hwz9sgxj9BiZ30XQH55sVi
# L48fgCRdqE2QWArzk4hpGsMa+GfE5r/nMYvs6KKLv4n39AeR0kaV+dF9tDdBcz/n
# +6YE4obgmgVjWeJnlFUfk9PT64KPByqFNue9S18r437IHZv2sRm+nZO/hnBjMR30
# D1Wxgy5mIJJtoUyTvsvBVuSWmfDhodYlcmQRiYm/FFtxOETwVDI6hWRK4pzk5Znb
# 5Yz+PnShuUDS0JTncBq69Q5lGhAGHz2ccr6bmk5cpd1gwn5x64tgXyHnL9xctAw6
# aosnPmXswuobBTTMdX4wQ7wvUWjbMQRDiIvgFfxiScpeiccZBpxIJotmi3aTIlVG
# wVLGfQ+U+8dWnRh2wIzN16LD2MBnsr2zVbGxkYQGsr+huKlfq7GMSnJQD2ZtU+WO
# VvdHgxYjQTbEj80zoXgBzwJ5rHdhYtP5pYJl6qIgwvHLJZmD6LUpjxkTMx41MoIQ
# jnAXXDGqvpPX8xCj7y0CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBRwXhc/bp1X7xK6
# ygDVddDZMNKZ0jAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Ny
# bC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYI
# KwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
# MDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAwBPODpH8DSV07syo
# bEPVUmOLnJUDWEdvQdzRiO2/taTFDyLB9+W6VflSzri0Pf7c1PUmSmFbNoBZ/bAp
# 0DDflHG1AbWI43ccRnRfbed17gqD9Z9vHmsQeRn1vMqdH/Y3kDXr7D/WlvAnN19F
# yclPdwvJrCv+RiMxZ3rc4/QaWrvS5rhZQT8+jmlTutBFtYShCjNjbiECo5zC5Fyb
# oJvQkF5M4J5EGe0QqCMp6nilFpC3tv2+6xP3tZ4lx9pWiyaY+2xmxrCCekiNsFrn
# m0d+6TS8ORm1sheNTiavl2ez12dqcF0FLY9jc3eEh8I8Q6zOq7AcuR+QVn/1vHDz
# 95EmV22i6QejXpp8T8Co/+yaYYmHllHSmaBbpBxf7rWt2LmQMlPMIVqgzJjNRLRI
# RvKsNn+nYo64oBg2eCWOI6WWVy3S4lXPZqB9zMaOOwqLYBLVZpe86GBk2YbDjZIU
# HWpqWhrwpq7H1DYccsTyB57/muA6fH3NJt9VRzshxE2h2rpHu/5HP4/pcq06DIKp
# b/6uE+an+fsWrYEZNGRzL/+GZLfanqrKCWvYrg6gkMlfEWzqXBzwPzqqVR4aNTKj
# uFXLlW/ID7LSYacQC4Dzm2w5xQ+XPBYXmy/4Hl/Pfk5bdfhKmTlKI26WcsVE8zlc
# KxIeq9xsLxHerCPbDV68+FnEO40wggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZ
# AAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVa
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1
# V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9
# alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmv
# Haus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928
# jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3t
# pK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEe
# HT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26o
# ElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4C
# vEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ug
# poMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXps
# xREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0C
# AwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYE
# FCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtT
# NRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5o
# dG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
# AEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZW
# y4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5t
# aWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAt
# MDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0y
# My5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pc
# FLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpT
# Td2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0j
# VOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3
# +SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmR
# sqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSw
# ethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5b
# RAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmx
# aQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsX
# HRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0
# W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0
# HVUzWLOhcGbyoYIC1DCCAj0CAQEwggEAoYHYpIHVMIHSMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFu
# ZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjE3
# OUUtNEJCMC04MjQ2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
# aWNloiMKAQEwBwYFKw4DAhoDFQBt89HV8FfofFh/I/HzNjMlTl8hDKCBgzCBgKR+
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA
# 6hQaATAiGA8yMDI0MDYxMjIwNTg0MVoYDzIwMjQwNjEzMjA1ODQxWjB0MDoGCisG
# AQQBhFkKBAExLDAqMAoCBQDqFBoBAgEAMAcCAQACAgS8MAcCAQACAhQrMAoCBQDq
# FWuBAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMH
# oSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAJOhBeFYP+MfkbTKuNqYt
# OP2SDkowHbprJ+d5WF0FTFR6hbfVx6QEIudKiE9LxjH0iQDMBYqNr7XSxC7JzXfI
# QQ5URfwR1XuAdQ7NC11ZX1tWSxqbX1tqEeezTkt7WZkF0dJKHvFjL6SgUAUyS+Er
# i9MKmrQ6AxdJcGZgf3r/hqoxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
# dGFtcCBQQ0EgMjAxMAITMwAAAeDU/B8TFR9+XQABAAAB4DANBglghkgBZQMEAgEF
# AKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEi
# BCBuzhwdmsiIWqsecu58ZhGwhJTvO9znrgcr2P6qWgKxsTCB+gYLKoZIhvcNAQkQ
# Ai8xgeowgecwgeQwgb0EIOPuUr/yOeVtOM+9zvsMIJJvhNkClj2cmbnCGwr/aQrB
# MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHg1Pwf
# ExUffl0AAQAAAeAwIgQgEr5HX2GWSpvIqvl/4AXucppozy+Ej8kCSK6JHGKDNNMw
# DQYJKoZIhvcNAQELBQAEggIAD8x8q69ZjtG9KjZoUxZGncUVA7+2hj/n1J9/Vg8R
# QRIJE1ssrMwbOjE28UytXb3flvcfuIPJBski1zS2X/EG1biPKxbN2FPBEoEBQhI7
# L/kPNItnK4BUDuHQ8Gv5Aqkxi3Nk6MMnXbpFcoxZWH2cx8F+ZJnIxYfk6GOSveAJ
# bIgvkShq9u10QGZ+hTVPeIDraTpEQxbmhoLSpJGOrTBNmGh8SyJ6tsfTivR70HnE
# ykDxsAo5fQVztbftTmyh3DaosLA6Kn2fEoYLT4SvsuPGu5v3CU/DHrkDOfMDJjqB
# G9XhBnLQ3D3hDffL07Nu1PoEyBmesXjqNjg6e5++/wpNhWVEAsV6ucfzeYz3OqCL
# UXhWJw56EXhhlbULA66VPvnJu5ByaowibChCxzmu50XCCti4/0Fwzdr9r8GHDxG2
# fZJYjHjJaCIAmPcyRCi+7mhyThKs/qweCXrmFJCPks3Y4O4ZZ2b2CgC/oFMmf9pO
# kHEyCuk4+qm7Gj3dFZHg2d4+mI6b+i7fbytJAjipnXdWe0OI4546meqPSsqDDBpt
# KHQokc8vrg5ODxo2cXw+CClL63Y3DKxZbHZphRPbrZqTECxmYTtKJykgqcDzuiFx
# Wl202lnjQ7vJuHeKcdjXavFIfiiifdeRQ8PIFQlyqW5GLtYaavJCcSQi96IYT+Os
# eAE=
# SIG # End signature block
