#requires -RunAsAdministrator
#requires -Version 5
#requires -Modules SmbShare,NetAdapter

<#	# File: tss_SMB_Fix-SmbBindings.ps1
	# Version: 2022.12.30.0
	
    .SYNOPSIS

    Repairs missing ms_server (SMB Server) bindings for network adapters. Fixes LanmanServer (SMB Server), LanmanWorkstation (SMB Client), NetBT (NetBIOS over TCP/IP) binding balance.

    .DESCRIPTION

    Fix-SvrBinding (the "script") was built in association with KBxxx, which is an issue discovered after the adapter binding for 
    the SMB subsystem in Windows was moved to a new API. The RASMAN (VPN) subsystem has not been migrated, which causes unbalanced
    bindings in the Linkage registry keys for the following services:

       - LanmanServer (Server service, which is the SMB server in Windows)
       - LanmanWorkstation (LanmanWorkstation service, which is the SMB client in Windows)
       - NetBT (NetBIOS over TCP/IP driver, which is needed for legacy SMBv1 over NetBIOS support)

    The script performs the following checks and repairs, when an issue is found on a Windows system.

       Fix 1:
       - Finds network adapter bindings where ms_server (SMB Server) is bound/installed and Enabled == True
       - Compares the list of ms_server bound adapters to the bindings in the Linkage registry keys using the adapter's DeviceID GUID
       - Bindings are automatically generated and added to the registry for any network adapter missing bindings
       - The Server service is then restarted; unless, the noSvrRestart parameter was set when the script was run
       - This fixes currently installed network adapters that should be bound to ms_server, but are not binding at boot due to the bug

       Fix 2:
       - The bindings in each Linkage registry key are scanned and compared
       - Any missing bindings are added to the appropriate Linkage registry value
       - This fix balances the Linkage bindings to prevent future network adapter additions or reinstallations from experiencing the binding bug

    Please note that this does not fix the fundamental code defect in Windows. The code defect will be addressed in a future update to Windows.
    The script is meant to restore functionality to Windows systems affected by the issue.

    IMPORTANT NOTE:

    The script needs to be run after installing a new VPN adapter, or any new VPN-based software that installs a VPN virtual adapter.
    The code defect is caused by the VPN subsystem (RASMAN) using a legacy set of APIs that does not create all the necessary
    bindings needed to bind a network adapter to SMB server. The issue could, therefore, reappear until the code defect is patched.

    .PARAMETER noSvrRestart
    
    Prevents the Server service (LanmanServer, or the SMB Server service) from being restarted after a network adapter bindings is added. The default is FALSE, when the parameter is not present, and the Server service is restarted as a result.

    .EXAMPLE

     .\tss_SMB_Fix-SmbBindings.ps1

    Runs the script normally. The Server service will be restarted if network adapter bindings are added.
    
    .EXAMPLE

     .\tss_SMB_Fix-SmbBindings.ps1 -noSvrRestart

    Runs the script, but will prevent the Server service from being restarted if a network adapter bindings is added.

    .INPUTS

    None.

    .OUTPUTS

    A log file is created on the user desktop.

#>

[CmdletBinding()]
param (
    # The Server service is restarted, by default, when an adapter binding is added/fixed. 
    # Adding this parameter will prevent the Server service restart. 
    # The Server service must be manually restarted, or the system rebooted, for adapter binding changes to take effect when this parameter is set.
    [switch]$noSvrRestart,
	[string]$DataPath = $global:LogFolder,
	[switch]$AcceptEula 
)

$FixSmbBindingsVer = "2022.12.30.0"			# dated version number
if ([String]::IsNullOrEmpty($DataPath)) {$DataPath="c:\MS_DATA"}

############################
###                      ###
###     DECLARATIONS     ###
###                      ###
############################
#region

# set logging options
$script:dataPath = $DataPath	#"$env:USERPROFILE\Desktop"
$script:logName = "$env:ComputerName`_Fix_SmbBindings_$(Get-Date -format "yyyyMMdd_HHmmss")`.log"

# the three registry paths to search
[string[]]$linkagePaths =   'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Linkage',
                            'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Linkage',
                            'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Linkage'

# initial order and list of linkage values to test against
[string[]]$testOrder = "Bind","Export","Route"

#endregion

############################
###                      ###
###       FUNCTIONS      ###
###                      ###
############################
#region 

# FUNCTION: Get-TimeStamp
# PURPOSE:  Returns a timestamp string

function Get-TimeStamp 
{
    return "$(Get-Date -format "yyyyMMdd_HHmmss_ffff")"
} # end Get-TimeStamp


# FUNCTION: Write-Log
# PURPOSE:  Writes script information to a log file and to the screen when -Verbose is set.

function Write-Log {
    param ([string]$text, [switch]$tee = $false, [string]$foreColor = $null)

    $foreColors = "Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow"
	$LogFilePath = "$script:dataPath\$script:logName"
	
    # check the log file, create if missing
    $isPath = Test-Path $LogFilePath
    if (!$isPath) {
        "$(Get-TimeStamp): Log started" | Out-File $LogFilePath -Force
        "$(Get-TimeStamp): Local log file path: $($LogFilePath)" | Out-File $LogFilePath -Force
        Write-Verbose "Local log file path: $($LogFilePath)"
    }
    
    # write to log
    "$(Get-TimeStamp): $text" | Out-File $LogFilePath -Append

    # write text verbosely
    Write-Verbose $text

    if ($tee)
    {
        # make sure the foreground color is valid
        if ($foreColors -contains $foreColor -and $foreColor)
        {
            Write-Host -ForegroundColor $foreColor $text
        } else {
            Write-Host $text
        }        
    }
} # end Write-Log


# FUNCTION: Update-LinkBinding
# PURPOSE:  Updates a Linkage binding list, given a path path, list name (Bind, Export, Route), and the binding(s) to add.

function Update-LinkBinding
{
    param ( [string]$regPath,
            [string[]]$arrAdd, 
            [string]$listName)
    
    Write-Log "Updating linakge binding:`nPath: $regPath`nAdditions: $($arrAdd | Out-String)`nList: $listName"
    
    # get the route list
    [string[]]$routeList = (Get-ItemProperty -Path $regPath -Name $listName)."$listName"

    foreach ($strAdd in $arrAdd)
    {
        # update the string[]
        $routeList += $strAdd
    }

    # update the registry
    try {
        Set-ItemProperty -Path $regPath -Name $listName -Value $routeList -ErrorAction Stop    
    }
    catch {
        Write-Log "ERROR: Could not update $regPath\$listName`: $($Error[0].ToString())"
        return $false
    }

    
    # check that the add was successful
    $routeList = (Get-ItemProperty -Path $regPath -Name $listName)."$listName"
    if ($routeList -contains $strAdd)
    {
        # hurray, it worked!
        Write-Log "Updates were successful."
        return $true
    } else {
        # oops, something done broke
        Write-Log "Updates failed for an unknown reason."
        return $false
    }

    # if we get here then something went horribly wrong and false is returned
    return $false
} #end Update-LinkBinding


# FUNCTION: Add-NetBindLink
# PURPOSE:  Adds network adapter bindings to a Bind linkage list, give the Linkage reg path, adapter GUID, and list name (which should be Bind)
function Add-NetBindLink
{
    param ($regPath, $guid, $listName)
    
    Write-Log "Building new bindings for $guid in $regPath\$listName`."

    # get the service
    $serviceName = $regPath.Split('\')[-2]

    if ($serviceName -eq "NetBT")
    {
        [string[]]$arrAdd = "\Device\Tcpip6_$guid",
                            "\Device\Tcpip_$guid"
    } else {
        [string[]]$arrAdd = "\Device\Tcpip_$guid",
                            "\Device\NetBT_Tcpip_$guid",
                            "\Device\Tcpip6_$guid",
                            "\Device\NetBT_Tcpip6_$guid"
    }
    
    return (Update-LinkBinding -regPath $regPath -arrAdd $arrAdd -listName $listName)
} #end Add-NetBindLink


# FUNCTION: Add-NetExportLink
# PURPOSE:  Adds network adapter bindings to a Bind linkage list, give the Linkage reg path, adapter GUID, and list name (which should be Export)

function Add-NetExportLink
{
    param ($regPath, $guid, $listName)

    Write-Log "Building new bindings for $guid in $regPath\$listName`."

    # get the service
    $serviceName = $regPath.Split('\')[-2]

    if ($serviceName -eq "NetBT")
    {
        [string[]]$arrAdd = "\Device\$serviceName`_Tcpip6_$guid",
                            "\Device\$serviceName`_Tcpip_$guid"
    } else {
        [string[]]$arrAdd = "\Device\$serviceName`_Tcpip_$guid",
                            "\Device\$serviceName`_NetBT_Tcpip_$guid",
                            "\Device\$serviceName`_Tcpip6_$guid",
                            "\Device\$serviceName`_NetBT_Tcpip6_$guid"
    }
    
    return (Update-LinkBinding -regPath $regPath -arrAdd $arrAdd -listName $listName)
} #end Add-NetExportLink


# FUNCTION: Add-NetRouteLink
# PURPOSE:  Adds network adapter bindings to a Bind linkage list, give the Linkage reg path, adapter GUID, and list name (which should be Route)

function Add-NetRouteLink
{
    param ($regPath, $guid, $listName)

    Write-Log "Building new bindings for $guid in $regPath\$listName`."

    # get the service
    $serviceName = $regPath.Split('\')[-2]

    if ($serviceName -eq "NetBT")
    {
        [string[]]$arrAdd = "`"Tcpip6`" `"$guid`"",
                            "`"Tcpip`" `"$guid`""
    } else {
        [string[]]$arrAdd = "`"Tcpip`" `"$guid`"",
                            "`"NetBT`" `"Tcpip`" `"$guid`"",
                            "`"Tcpip6`" `"$guid`"",
                            "`"NetBT`" `"Tcpip6`" `"$guid`""
    }
    
    return (Update-LinkBinding -regPath $regPath -arrAdd $arrAdd -listName $listName)
} #end Add-NetRouteLink


# FUNCTION: Get-Bind2Obj 
# PURPOSE:  Converts the Bind linkage lists into a custome set of PSObjects used to compare and update linkage lists

function Get-Bind2Obj 
{
    param ($bindObj)

    $results = @()

    foreach ($obj in $bindObj)
    {
        if ($obj -match '_')
        {
            $guid = $obj.Split('_')[-1]
            $provider = $obj.Split('\')[-1].Split('{')[0]
            $comparand = "$provider$guid"
        } else {
            $guid = $provider = $comparand = $obj.Split('\')[-1]
        }

        <#
            Each object contains the structure needed to compare, update, or diagnose binding issues.

            List = The list name where the object was created from
            FullName = The unmodified binding string
            Guid = The adapter DeviceID Guid associated with the binding, or the network provider name when no GUID is listed
            Proiver = Protocol(s) in the binding, in a common format since each list has a unique format. _<prot>[_<prot>]_  Examples: _Tcpip_, _NetBT_Tcpip6_
            Comparand = A combination of provider and GUID that makes the binding unique, but in a common format: <provider><guid>, NetbiosSmb
        #>
        
        $tmpObj = [PSCustomObject]@{
            List = "Bind"
            FullName = $obj
            Guid = $guid
            Provider = $provider
            Comparand = $comparand
        }
        $results  += $tmpObj
    }

    return $results 
} #end Get-Bind2Obj 


# FUNCTION: Get-Export2Obj 
# PURPOSE:  Converts the Export linkage lists into a custome set of PSObjects used to compare and update linkage lists

function Get-Export2Obj 
{
    param ($exportObj,$linkName)

    $results = @()

    foreach ($obj in $exportObj)
    {
        if ($obj -notmatch 'NetbiosSmb')
        {
            $guid = $obj.Split('_')[-1]
            
            switch -Regex ($obj)
            {
                "^.*NetBT.*$" {
                    $provider = $obj.Split('\')[-1].Split('{')[0] -replace "NetBT_",""        
                }

                "^.*LanmanServer.*$" {
                    $provider = $obj.Split('\')[-1].Split('{')[0] -replace "LanmanServer_",""        
                }

                "^.*LanmanWorkstation_.*$" {
                    $provider = $obj.Split('\')[-1].Split('{')[0] -replace "LanmanWorkstation_",""        
                }

                default {
                    $provider = $obj.Split('\')[-1].Split('{')[0]
                }
            }
            
            $comparand = "$provider$guid"
        } else {
            switch -Regex ($obj)
            {
                "^.*NetBT.*$" {
                    $guid = $provider = $comparand = $obj.Split('\')[-1].Split('{')[0] -replace "NetBT_",""        
                }

                "^.*LanmanServer.*$" {
                    $guid = $provider = $comparand = $obj.Split('\')[-1].Split('{')[0] -replace "LanmanServer_",""        
                }

                "^.*LanmanWorkstation_.*$" {
                    $guid = $provider = $comparand = $obj.Split('\')[-1].Split('{')[0] -replace "LanmanWorkstation_",""        
                }

                default {
                    $provider = $obj.Split('\')[-1].Split('{')[0]
                }
            }
        }

        <#
            Each object contains the structure needed to compare, update, or diagnose binding issues.

            List = The list name where the object was created from
            FullName = The unmodified binding string
            Guid = The adapter DeviceID Guid associated with the binding, or the network provider name when no GUID is listed
            Proiver = Protocol(s) in the binding, in a common format since each list has a unique format. _<prot>[_<prot>]_  Examples: _Tcpip_, _NetBT_Tcpip6_
            Comparand = A combination of provider and GUID that makes the binding unique, but in a common format: <provider><guid>, NetbiosSmb
        #>

        $tmpObj = [PSCustomObject]@{
            List = "Export"
            FullName = $obj
            Guid = $guid
            Provider = $provider
            Comparand = $comparand
        }
        $results += $tmpObj
    }

    return $results 
} #end Get-Export2Obj


# FUNCTION: Get-Route2Obj 
# PURPOSE:  Converts the Route linkage lists into a custome set of PSObjects used to compare and update linkage lists

function Get-Route2Obj 
{
    param ($routeObj)

    # stores the resulting object array
    $results = @()

    # loop through each Route binding
    foreach ($obj in $routeObj)
    {
        # bindings with a { have a GUID, and need parsing
        if ($obj -match '{')
        {
            # the last object is the DeviceID GUID
            $guid = $obj.Split(' ')[-1].Trim('"')
            $values = $obj.Split(' ')

            # generate a common provider string
            $provider = ($values | Where-Object {$_ -notmatch $guid} | ForEach-Object {$_.Trim('"')}) -join "_"
            $provider = "$provider`_"

            # create the comparand
            $comparand = ($obj.Split(' ') | ForEach-Object {$_.Trim('"')}) -join '_'

        } else {
            $guid = $provider = $comparand = $obj.Trim('"')
        }

        <#
            Each object contains the structure needed to compare, update, or diagnose binding issues.

            List = The list name where the object was created from
            FullName = The unmodified binding string
            Guid = The adapter DeviceID Guid associated with the binding, or the network provider name when no GUID is listed
            Proiver = Protocol(s) in the binding, in a common format since each list has a unique format. _<prot>[_<prot>]_  Examples: _Tcpip_, _NetBT_Tcpip6_
            Comparand = A combination of provider and GUID that makes the binding unique, but in a common format: <provider><guid>, NetbiosSmb
        #>

        $tmpObj = [PSCustomObject]@{
            List = "Route"
            FullName = $obj
            Guid = $guid
            Provider = $provider
            Comparand = $comparand
        }
        $results += $tmpObj
    }

    # return the array of objects
    return $results 
} #end Get-Route2Obj


# FUNCTION: Add-BindLinkage
# PURPOSE:  Adds a missing binding to a Bind Linkage list, given a path and a difference object from Get-Link

function Add-BindLinkage
{
    param ($regPath, $diffObj)

    ## generate the string to add
    if ($diffObj.MissingObj.Provider -eq 'NetbiosSmb')
    {
        $strAdd = "\Device\NetbiosSmb"
    } else {
        $strAdd = "\Device\$($diffObj.MissingObj.Comparand)"
    }
    
    # update the binding and return the result
    return (Update-LinkBinding -regPath $regPath -arrAdd $strAdd -listName "$($diffObj.MissingFrom)")
} #end Add-BindLinkage


# FUNCTION: Add-ExportLinkage
# PURPOSE:  Adds a missing binding to a Export Linkage list, given a path and a difference object from Get-Link

function Add-ExportLinkage
{
    param ($regPath, $diffObj)

    ## generate the string to add
    # get the service
    $serviceName = $regPath.Split('\')[-2]

    if ($diffObj.MissingObj.Provider -eq 'NetbiosSmb')
    {
        $strAdd = "\Device\$serviceName`_NetbiosSmb"
    } else {
        $strAdd = "\Device\$serviceName`_$($diffObj.MissingObj.Comparand)"
    }
    
    # update the binding and return the result
    return (Update-LinkBinding -regPath $regPath -arrAdd $strAdd -listName "$($diffObj.MissingFrom)")
} #end Add-ExportLinkage


# FUNCTION: Add-RouteLinkage
# PURPOSE:  Adds a missing binding to a Route Linkage list, given a path and a difference object from Get-Link

function Add-RouteLinkage
{
    param ($regPath, $diffObj)

    ## generate the string to add
    if ($diffObj.MissingObj.Provider -eq 'NetbiosSmb')
    {
        $strAdd = '"NetbiosSmb"'
    } else {
        $tmpProvider = ($diffObj.MissingObj.Provider.Split('_') | Where-Object {$_ -ne ""} | ForEach-Object {"`"$_`""}) -join ' '
        $strAdd = "$tmpProvider `"$($diffObj.MissingObj.Guid)`""
        $strAdd = $strAdd.Trim(" ")
    }

    # update the binding and return the result
    return (Update-LinkBinding -regPath $regPath -arrAdd $strAdd -listName "$($diffObj.MissingFrom)")
} #end Add-RouteLinkage


# FUNCTION: Get-Link 
# PURPOSE:  Gets a difference object for a Linkage list, given a reg path to a Linkage key.

function Get-Link 
{
    param ($link)

    # get the type of linkage value
    $linkName = $link | Get-Member -Type NoteProperty | Where-Object Name -notmatch "^PS.*$" | ForEach-Object {$_.Name}
    
    # call the appropriate Get-Bind2xxxxx function and return the result
    switch ($linkName) {
        "bind" {  
            # parse the bind list
            return (Get-Bind2Obj $link."$linkName" $linkName)

            break
        }

        "Export" {
            # parse the export list
            return (Get-Export2Obj $link."$linkName" $linkName)

            break
        }

        "Route" {
            # parse the route list
            return (Get-Route2Obj $link."$linkName" $linkName)

            break
        }
        default {
            Write-Host "Unknown link type: $linkName" 
            return $false
        }
    }

    # just in case something went wrong
    return $false
} #end Get-Link 


# FUNCTION: Get-ListDiff
# PURPOSE:  Compares link1 to link2, and returns a list of missing bindings that are not in link2 but are in link1. Accepts two difference objects from Get-Link.

function Get-ListDiff
{
    param ($link1, $link2)

    # convert the raw value to objects
    $list1 = Get-Link $link1
    $list2 = Get-Link $link2

    # stores a list of differences
    $diffList = @()

    # search through each value in list1 and see if it exists in list 2
    foreach ($item in $list1)
    {
        if ($list2.Comparand -notcontains $item.Comparand)
        {
            # add to diffList
            $tmpObj = [PSCustomObject]@{
                MissingFrom = $($list2[0].List)
                MissingObj = $item
            }

            $diffList += $tmpObj
        }
    }

    # return the diffList, if populated; otherwise, return $false
    if ($diffList)
    {
        #Write-Host "`nSource list:$($list2 | Format-List | Out-String)"
        return $diffList
    } else {
        return $false
    }
} #end Get-ListDiff

function ShowEULAIfNeeded($toolName, $mode) {
	$eulaRegPath = "HKCU:Software\Microsoft\CESDiagnosticTools"
	$eulaAccepted = "No"
	$eulaValue = $toolName + " EULA Accepted"
	if (Test-Path $eulaRegPath) {
		$eulaRegKey = Get-Item $eulaRegPath
		$eulaAccepted = $eulaRegKey.GetValue($eulaValue, "No")
	}
	else {
		$eulaRegKey = New-Item $eulaRegPath
	}
	if ($mode -eq 2) {
		# silent accept
		$eulaAccepted = "Yes"
		$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
	}
	else {
		if ($eulaAccepted -eq "No") {
			$eulaAccepted = ShowEULAPopup($mode)
			if ($eulaAccepted -eq [System.Windows.Forms.DialogResult]::Yes) {
				$eulaAccepted = "Yes"
				$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
			}
		}
	}
	return $eulaAccepted
}

#endregion FUNCTIONS


############################
###                      ###
###         MAIN         ###
###                      ###
############################
#  region MAIN   =====================================

## EULA
# Show EULA if needed.
If ($AcceptEULA.IsPresent) {
	$eulaAccepted = ShowEULAIfNeeded "SMB_Fix-SmbBindings" 2  # Silent accept mode.
}
Else {
	$eulaAccepted = ShowEULAIfNeeded "SMB_Fix-SmbBindings" 0  # Show EULA popup at first run.
}
if ($eulaAccepted -eq "No") {
	Write-Error "EULA not accepted, exiting!"
	exit -1
}

##### NIC BINDING #####
#region

<#
if ($AcceptEula) {
  Write-Log "AcceptEula switch specified, silently continuing"
  $eulaAccepted = ShowEULAIfNeeded "SMB_Fix-SmbBindings" 2
} else {
  $eulaAccepted = ShowEULAIfNeeded "SMB_Fix-SmbBindings" 0
  if($eulaAccepted -ne "Yes")
   {
     Write-Log "EULA declined, exiting"
     exit
   }
 }
Write-Log "EULA accepted, continuing"
#>

# get all net adapters, excluding adapters that are not bound to ms_server (Enabled = False)
$svrBingings = Get-NetAdapterBinding -ComponentID ms_server | Where-Object Enabled
$srvNetAdptrs =  Get-NetAdapter | Where-Object {$svrBingings.InterfaceAlias -contains $_.InterfaceAlias}
Write-Log "Net adapters bound to ms_server:`n$(($srvNetAdptrs | Sort-Object | Select-Object Name,InterfaceDescription,InterfaceAlias,InterfaceIndex,DeviceID) | Out-String)`n"

# get all net adapters, excluding adapters that are not bound to ms_msclient (Enabled = False). This is currently for monitoring purposes only.
$cliBingings = Get-NetAdapterBinding -ComponentID ms_msclient | Where-Object Enabled
$cliNetAdptrs =  Get-NetAdapter | Where-Object {$cliBingings.InterfaceAlias -contains $_.InterfaceAlias}
Write-Log "Net adapters bound to ms_msclient:`n$(($cliNetAdptrs | Sort-Object | Select-Object Name,InterfaceDescription,InterfaceAlias,InterfaceIndex,DeviceID) | Out-String)`n"

Write-Log "Checking bindings for net adapters." -tee -foreColor Green

# monitors whether a link was updated. Needed for logging and restarting Server.
$wasNicBindUpdated = $false

# lopp through each Linkage key location
foreach ($link in $linkagePaths)
{
    Write-Log "Testing NICs against: $link" -foreColor Yellow -tee

    # backup the reg value
    $backupReg = Get-Item $link
    $serviceName = $link.Split('\')[-2]
    $backupTimeStamp = Get-TimeStamp
    reg export $($backupReg.Name) "$PSScriptRoot\$serviceName`_$backupTimeStamp`.reg" /y | Out-Null

    # verify that the backup completed in a manner that is compatible with non-English localizations of Windows
    $isRegBackup = Get-Item "$PSScriptRoot\$serviceName`_$backupTimeStamp`.reg" -EA SilentlyContinue
    #create a regex pattern for the link. With -replace, the matching pattern is a regex expression, the replacement string is literal, so -replace '\\','\\' replaces a single backslash (\) with the double backslash (\\) needed for the select-string match later on
    [regex]$regLink = "^\[$(($link -replace "HKLM:", "HKEY_LOCAL_MACHINE") -replace '\\','\\')\]$"

    # make sure the file exists
    if (-not $isRegBackup)
    {
        Write-Log "CRITICAL: Failed to backup the $serviceName registry key." -tee -foreColor Red
        exit
    } 
    # 0-2 bytes is the size of an empty TXT doc, fail if it seems empty
    elseif ($isRegBackup.Length -le 2) 
    {
        Write-Log "CRITICAL: Failed to write data to the $serviceName registry file: $PSScriptRoot\$serviceName`_$backupTimeStamp`.reg" -tee -foreColor Red
        exit
    }
    # make sure the right link is in the content of the reg file. Key names are not localized so this is a safe operation.
    elseif (-NOT (Get-Content $isRegBackup | Select-String $regLink))
    {
        Write-Log "CRITICAL: Could not validate the $serviceName registry backup: $PSScriptRoot\$serviceName`_$backupTimeStamp`.reg" -tee -foreColor Red
        exit
    }
    

    # loop through each list in the testOrder
    foreach ($list in $testOrder)
    {
        # get the linkage list        
        $bndLinkage = Get-ItemProperty -Path $link -Name $list
        
        Write-Log "All bindings for $list`:`n`r$(($bndLinkage."$list" | Sort-Object) -join "`n`r")`n`r"

        # loop through list of adapters to find missing bindings
        foreach ($adapter in $srvNetAdptrs)
        {
            Write-Log "Checking bindings for $($adapter.Name) `n`rDescription: $($adapter.InterfaceDescription) `n`rGUID: $($adapter.DeviceID) `n`rStatus: $($adapter.Status)"
            
            # this looks for the DeviceID GUID in the linkage list
            $tmpBnd = $bndLinkage."$list" | Where-Object {$_ -match $adapter.DeviceID}

            # no results means the DeviceID GUID is missing and needs to be added...
            if (-not $tmpBnd)
            {
                Write-Log "$($adapter.Name) was not found on the $serviceName $list list.`n" -tee -foreColor Red

                # this switch is used to make the correct function call, based on which linkage list is being tested
                switch ($list)
                {
                    "Export" {
                        Write-Log "Adding Export link(s) for $($adapter.Name)."
                        $result = Add-NetExportLink -regPath $link -guid "$($adapter.DeviceID)" -listName $list

                        break
                    }

                    "Route" {
                        Write-Log "Adding Route link(s) for $($adapter.Name)."
                        $result = Add-NetRouteLink -regPath $link -guid "$($adapter.DeviceID)" -listName $list

                        break
                    }

                    "Bind" {
                        Write-Log "Adding Bind link(s) for $($adapter.Name)."
                        $result = Add-NetBindLink -regPath $link -guid "$($adapter.DeviceID)" -listName $list

                        break
                    }

                    default { Write-Log "`nSomething didn't work right...time to bail."; exit }
                } #end switch list

                # writes logging based on the result of adding the missing binding
                if ($result)
                {
                    Write-Log "Successfully added link(s) for $($adapter.Name) in $list" -tee -foreColor Green
                    # set wasNicBindUpdated to true so the Server service can be restarted
                    $wasNicBindUpdated = $true
                } else {
                    Write-Log "ERROR: Could not add link(s) for $($adapter.Name) in $list." -tee -foreColor Red
                }
            # ... a tmpBnd result means the binding is on the list
            } else
            {
                Write-Log "$($adapter.Name) was found on the $serviceName $list list.`n"
            } #end if (-not $tmpBnd)
        } #end adapter-srvNetAdptrs foreach
    } #end list-TestOrder foreach
} #end link-Linkage foreach

# check whether the Server service needs to be restarted
if ($wasNicBindUpdated)
{
    # test whether noSvrRestart was set and log accordingly
    if (-not $noSvrRestart)
    {
        Write-Log "Restarting the Server service."
        Restart-Service LanmanServer -Force
    } else {
        Write-Log "`nnoSvrRestart was set from the command line and a network adapter binding was added. The Server service was not restarted.`n`nThe server service must be manually restarted, or the system rebooted, for the fix to take effect.`n`n" -tee -foreColor Yellow
    }
} else {
    Write-Log "There were no missing network adapter bindings found - no modifications were necessary." -tee -foreColor Green
}
#endregion


##### RESYNC LINKAGE #####
#region

### make sure all the linkage bindings are synced ###

Write-Log "Testing whether the linkage lists are balanced." -tee -foreColor Yellow

# was a link updated? needed for logging purposes. A reboot is not needed after linkage bindings are balanced.
[bool]$wasLinkUpdated = $false

# loop through all Linkage paths
foreach ($link in $linkagePaths)
{
    Write-Log "`nValidating linkage lists for: $link" -ForegroundColor Green
    
    # loop throug the three binding lists
    foreach ($list in $testOrder)
    {
        #Write-Host "`nTest order:`n$($testOrder | fl | out-string)"
        for($i = 1; $i -lt $testOrder.Count; $i++)
        {
            # get the linkage values of the first list in testOrder, and then either the second or last list
            $sourceList = Get-ItemProperty -Path $link -Name $list
            $destList = Get-ItemProperty -Path $link -Name $testOrder[$i]

            Write-Log "`nComparing $list to $($testOrder[$i])"

            # look for differences in the two lists
            $difference = Get-ListDiff $sourceList $destList

            # add missing bindings when differences are found
            if ($difference)
            {
                Write-Log "`nThe following differences between $list and $($testOrder[$i]) were found:`n$($difference | Format-List | Out-String)" -tee

                # there could be more than one difference, so loop through all of them
                foreach ($diff in $difference)
                {
                    # call the appropriae function to add the missing binding, bases on the MissingFrom value in the difference object
                    switch ($diff.MissingFrom)
                    {
                        "Export" {
                            Write-Log "Updating Export link."
                            $result = Add-ExportLinkage $link $diff

                            break
                        }

                        "Route" {
                            Write-Log "Updating Route link."
                            $result = Add-RouteLinkage $link $diff

                            break
                        }

                        "Bind" {
                            Write-Log "Updating Bind link."
                            $result = Add-BindLinkage $link $diff

                            break
                        }

                        default { Write-Log "`nSomething didn't work right...time to bail."; exit }
                    } #end switch ($diff.MissingFrom)

                    # log based on results
                    if ($result)
                    {
                        Write-Log "Updated $($diff.MissingFrom) link successfully." -tee -foreColor Green
                        $wasLinkUpdated = $true
                    } else {
                        Write-Log "ERROR: Updating $($diff.MissingFrom) link failed." -tee -foreColor Red
                    }
                } #end foreach ($diff in $difference)
            } else {
                Write-Log "`nNo differences between $list and $($testOrder[$i]) were found"
            }
        } #end for($i = 1; $i -lt $testOrder.Count; $i++)

        ## Rotate the test order.
        ## This algorithm modifies the testOrder so that all linkage list combinations for each Linkage key is tested without duplication.
        # put the middle list into the first (0th) position in tmpTestOrder
        [string[]]$tmpTestOrder = $testOrder[1]
        
        # this loop puts the last testOrder item second and the first testOrder time last in the tmpTestOrder array
        for($i = 2; $i -le $testOrder.Count; $i++)
        {
            if ($i -eq $testOrder.Count)
            {
                $x = 0
            } else {
                $x = $i
            }

            $tmpTestOrder += $testOrder[$x]
        }

        # make tmpTestOrder the new testOrder
        $testOrder = $tmpTestOrder

        #set tmpTestOrder to null
        $tmpTestOrder = $null
    } #end foreach ($list in $testOrder)
} #end foreach ($link in $linkagePaths)

# log to console that there were no binding issues if wasLinkUpdated is still false
if (-not $wasLinkUpdated)
{
    Write-Log "System linkage is balanced - no modifications were necessary." -tee -foreColor Green
}

#endregion

# New final step. 
# We use PowerShell to "wiggle" the binding. RS2 seems to lose the binding on reboot unless PowerShell is used to disable/enable the binding.
# This code is run only when there was a need to fix a NIC binding, and after everything has been balanced/fixed.
if ($wasNicBindUpdated)
{
    Write-Log "Resetting the ms_server bindings with PowerShell to ensure the changes work after a reboot."
    
    # loop through list of adapters to find missing bindings
    foreach ($adapter in $srvNetAdptrs)
    {
        Disable-NetAdapterBinding -Name $($adapter.Name) -ComponentID ms_server -PassThru | Out-String | Write-Log
        Enable-NetAdapterBinding -Name $($adapter.Name) -ComponentID ms_server -PassThru | Out-String | Write-Log
    }
}

Write-Log "=> Please upload $script:dataPath\$script:logName to our upload site (MS workspace) for analysis." -tee -foreColor Cyan


# SIG # Begin signature block
# MIIoKgYJKoZIhvcNAQcCoIIoGzCCKBcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD1A6lfGNxnOaNk
# EC/ZnjFSsJFoHV6y2MdCY+wKReZfZaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINHadoU3FGtezQ5k3MnA64Gk
# CVkPv9Ndk7T/zfR3Rw4lMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAXKvGmyO4y0rhwsVsqH5YVpOL/MLcgRMt6UNcYsMOe58yxoqPaRjjHo0M
# HayklbZhyUDxHbiL7mC5QJmUOQTrLmzXJ/FQk6Hatnk1iZAtHZMldXX9KpORCLPh
# ZkJWmdnlE+0xbqd6Mjiumoc/H7KFn4p+1DNXMkEN7Zn9/tFbDPLaGmgaU+ZI81HZ
# GBLYZSJTQZYQWn2GPcG6ShlhAMUmubA0AsXEAqgQMMSIY835nZJs57TvTzj07aND
# JcRpBGXgHbofOkQXIDorAvAr0YlMRNJ1Si2AufCzcoTKTuffWOe227grRR1ibVwu
# 9VsMOgX37FQiuIHsmccbHASCpcDwE6GCF5QwgheQBgorBgEEAYI3AwMBMYIXgDCC
# F3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFSBgsq
# hkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCCvITUyIrTYLGMIMM8dp82CN2RL0sa1ppH0JRoT68mgFAIGZkZX1jEP
# GBMyMDI0MDYxMjE1MDAzOC4zMjNaMASAAgH0oIHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wg
# ghHqMIIHIDCCBQigAwIBAgITMwAAAebZQp7qAPh94QABAAAB5jANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1
# MTVaFw0yNTAzMDUxODQ1MTVaMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC9vph84tgluEzm/wpNKlAjcElGzflvKADZ1D+2d/ie
# YYEtF2HKMrKGFDOLpLWWG5DEyiKblYKrE2nt540OGu35Zx0gXJBE0zWanZEAjCjt
# 4eGBi+uakZsk70zHTQHHyfP+B3m2BSSNFPhgsVIPp6vo/9t6OeNezIwX5E5+VwEG
# 37nZgEexQF2fQZYbxQ1AauqDvRdXsSpK1dh1UBt9EaMszuucaR5nMwQN6sDjG99F
# zdK9Atzbn4SmlsoLUtRAh/768sKd0Y1hMmKVHwIX8/4JuURUBRZ0JWu0NYQBp8kh
# ku18Q8CAQ500tFB7VH3pD8zoA4lcA7JkxTGoPKrufm+lRZAA4iMgbcLZ2P/xSdnK
# FxU8vL31RoNlZJiGL5MqTXvvyBLz+MRP4En9Nye1N8x/lJD1stdNo5wJG+mgXsE/
# zfzg2GaVqQczFHg0Nl8bpIqnNFUReQRq3C1jVYMCScegNzHeYtw5OmZ/7eVnRmjX
# lCsLvdsxOzc1YVn6nZLkQD5y31HYrB9iIHuswhaMv2hJNNjVndkpWy934PIZuWTM
# k360kjXPFwl2Wv1Tzm9tOrCq8+l408KIL6J+efoGNkR8YB3M+u1tYeVDO/TcObGH
# xaGFB6QZxAUpnfB5N/MmBNxMOqzG1N8QiwW8gtjjMJiFBf6iYYrCjtRwF7IPdQLF
# tQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFOUEMXntN54+11ZM+Qu7Q5rg3Fc9MB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBhbuogTapRsuwSkaFMQ6dyu8ZCYUpWQ8iI
# rbi40tU2hK6pHgu0hj0z/9zFRRx5DfhukjvbjA/dS5VYfxz1EIbPlt897MJ2sBGO
# 2YLYwYelfJpDwbB0XS9Zkrqpzq6X/lmDQDn3G5vcYpYQCJ55LLvyFlJ195AVo4Wy
# 8UX5p7g9W3MgNHQMpM+EV64+cszj4Ho5aQmeKGtKy7w72eRY/vWDuptrvzruFNmK
# CIt12UcA5BOsXp1Ptkjx2yRsCj77DSml0zVYjqW/ISWkrGjyeVJ+khzctxaLkklV
# wCxigokD6fkWby0hCEKTOTPMzhugPIAcxcHsR2sx01YRa9pH2zvddsuBEfSFG6Cj
# 0QSvEZ/M9mJ+h4miaQSR7AEbVGDbyRKkYn80S+3AmRlh3ZOe+BFqJ57OXdeIDSHb
# vHzJ7oTqG896l3eUhPsZg69fNgxTxlvRNmRE/+61Yj7Z1uB0XYQP60rsMLdTlVYE
# yZUl5MLTL5LvqFozZlS2Xoji4BEP6ddVTzmHJ4odOZMWTTeQ0IwnWG98vWv/roPe
# gCr1G61FVrdXLE3AXIft4ZN4ZkDTnoAhPw7DZNPRlSW4TbVj/Lw0XvnLYNwMUA9o
# uY/wx9teTaJ8vTkbgYyaOYKFz6rNRXZ4af6e3IXwMCffCaspKUXC72YMu5W8L/zy
# TxsNUEgBbTCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# MCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjMzMDMtMDVFMC1EOTQ3MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQDi
# WNBeFJ9jvaErN64D1G86eL0mu6CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hPEJTAiGA8yMDI0MDYxMjA2NTIy
# MVoYDzIwMjQwNjEzMDY1MjIxWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDqE8Ql
# AgEAMAcCAQACAgzLMAcCAQACAhN9MAoCBQDqFRWlAgEAMDYGCisGAQQBhFkKBAIx
# KDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZI
# hvcNAQELBQADggEBAIAlF48QzlI0/nUHE309In7Re3wMMsGVjJvH8QyDFSgdoxa7
# iAmmbjxSHDj6ROWkpC+pwCh+5mnmtyOY+qgPJEZEcevGQOsMAgxSDwgFkjGjLOH1
# 0ANMGpv4Lgoff15oV0kg8+vW2w/iCzmazenro/KU2s6jZ27cpZ1OxWwThafsEoZa
# HcAVrR5ltkJExcEgSxfLnFTE9citlY/FGfJPAoPLArf9as9MesxZrnhwS1Rdd46z
# fa2R/Wt/seKge8aJHEJfs3QRx4M+hhQUVBnsyUrMImxMvXTW9w442Q6+6RTSZb8e
# tmYaQLmFut1dPrTkvFtMH2B/ScfASx1jnJLzzY4xggQNMIIECQIBATCBkzB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAebZQp7qAPh94QABAAAB5jAN
# BglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8G
# CSqGSIb3DQEJBDEiBCBRmcuMMXfZtjfChe7thIAFKKnxNNFEanCXHwEWUDwGSDCB
# +gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIM+7o4aoHrMJaG8gnLO1q16hIYcR
# noy6FnOCbnSD0sZZMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAHm2UKe6gD4feEAAQAAAeYwIgQgy6KmSaERUFw5zM8ixrWjedEWrCkX
# YG0+8JQBRQ+GJXIwDQYJKoZIhvcNAQELBQAEggIAj03X/76sLVZH5OmbIoeeNNpy
# 8+adzDX2dg8GC9lqnbbVnZ9SSYusE31aCS0t9AUFxFFeKkzvefWB+C+eF5fc9Ocu
# K0pzB3taLSvtdJQP018nKu+RE6783iKNNIFiR3dqjmkaxOVXRzJ3eAT1Ac85fslS
# RQ2ptFBndt9Il/OflxEZ9hmfbieqKAze+ceAyaJHRoCPemnOqwNSlhp5vPs+AnTx
# kzv1snxCE/5emv2GH7Wx+uhlKoHGWULakaMi4WLAxfE+9s2pqv+/nVdWvCE0/vYH
# 1PsULT+0YncItiAp//N+fd7vEPdrlU+3Nrvt5IEjF9a4K+xzeHfx0HJuOLawCTnS
# qsEXGHsYheVHv4PnUZZwcL27WB+1VhimbjOMu93l9VfLe1SfB+ZhQLSBDbCn285y
# fNnhN6nP44iBRe8+6w5L8UBLoE3WuCAn2O2K3ku4YccIeJ8VLG3rUMmqjEGsZlCG
# 9XzL5QYG7pMkS2aYA/ZJfWIaYFOWRRzsuqamDNZ9C1yIUc/IXC9BhyWPOObM9JiR
# G+NdGCgNPTVoLyPhQCeYpnj8Tp9+mrWvjDVpSyMSObOmKTf8QWbfHbjJfdDDbCRv
# 8zjCRmaVvV+d+mT2Y0vIvGX/bmIrxmm8jtXVYKOIwmEtlJyfayLY09zDF0F1nd89
# Ok3WMUjE6k7vD+uilOM=
# SIG # End signature block
