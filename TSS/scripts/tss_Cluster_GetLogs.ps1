#region    ::::: Help ::::: 

<#  
.SYNOPSIS 
    Script Name:  GetLogs.ps1	
    Purpose:      gather data from Windows Failover Cluster Nodes (default 3 Month back)
    Version:      1.4
    Last Update:  2nd June 2020
    Author:       Josef Holzer 
    Email-Alias:  josefh

.DESCRIPTION
	This script collects data from one or more computers
    If the script runs on a cluster node with cluster service running, it collects data from all cluster nodes

.PARAMETER ComputerNames
	Define on which computers you want to run the script. Default is local host

.PARAMETER LogPathLocal
	Path where we store the data. Default is SystemDrive\MS_DATA\DataTime; e.g. C:\MS_DATA\180925-101214

.PARAMETER HoursBack
	How much hours should we look back in the event data and collect them. Test Default =1 
	
.PARAMETER EventLogNames
	Define the Eventlogs you want to gather; wildcard * is allowed
	Sample: -EventLogNames "System", "Application", "*CSVFS*", "*Smb*", "*winrm*", "*wmi*", "*spaces*" 
    Alternatively define this in the parameter section on top of this script

.EXAMPLE
	GetLogs.ps1  # simply run it without any parameter to collect all data with defaults

.EXAMPLE 
	GetLogs.ps1 -ComputerName H16N4 # run the script data collection on specific computer

.EXAMPLE
    To access the Info´s stored in xml files, do what is done in the following sample
    $Inf= Import-CliXml -path "C:\MS_DATA\190221-121553\H16N1-GeneralInfoPerHost.xml"
    $Inf # lists all Members
    $Inf.Hotfix # Lists installed Hotfixes for example

.EXAMPLE
    checkout 

#>
#endregion ::::: Help :::::

#region    ::::: Changelog - Whats New in this Version :::::
<#
    Changelog started at 20th of April 2020
    Ver 1.3 - What´s new ?
    - Added function CopyFilesInReportsFoldersToLocalComputer -ComputerNames $ComputerNames 
      From each Node additionally collecting all files in "$Env:SystemRoot\Cluster\Reports" (e.g. c:\windows\cluster\reports) to Local MS_DATA Folder 
    - By default collect more "Event Logs"
      - *CSVFS*, *Hyper-V*, "*Smb*", "*spaces*"
    
#>
#endregion ::::: Changelog - Whats New in this Version :::::

#region    ::::: ToDo - Ideas for the future ::::::
<# 
[=== Processing on Customer Site - Data Collection ===]
- Distribute Jobs across Hosts  
- Collect Disk, Volume etc. data
- Create a Map
  - Volume --> Partition --> Disk
  - CSV --> Volume --> Disk --> GUID
- Add most important parts of Get-NetView to GetNetInfoPerHost
- Add Binary Versions - like Get-NetView does this to GetGeneralInfoPerHost

[=== Processing on Engineers Machine ===]
- Extract more simply *.txt files from *.xml files

[=== Data Analysis ===]
  - System Eventlog 
    - find most common events 5120, 1135, 6005 

  - Cluster Log     
    - operational green events
      - Cluster Service started - clussvc.exe started - Mostly you this is due to a reboot
      - The current time is - gives you the local time and the difference to Cluster GMT 
      - The logs were generated using - Tells you if logs were generated in GMT or local time
      - I am the form/join coordinator (offline and lowest number node) - tells you who the coordinator node is 
         
      - GroupMove -Cluster Groups are Moved by cluster service 
      - MoveType::Manual) - Tells you if the Move Group was triggered manually by the customer

    - General Errors, Warnings...
      - ERR  - Errors - Case sensitive
      - WARN - Warnings - Case sensitive
      - critical - Critical Events
      - fatal
      - failed 

    - Critical Events of Clussvc and rhs 
        - terminated, 
        - Cluster service terminated
        - Cluster service has terminated
        - removed from the active failover cluster membership - the node was removed from the active cluster 
        - timeout
        - Timed out
        - STATUS_IO_TIMEOUT
        - deadlock

    - Critical Events - communication Issue
        - as down
        - are down
        - lost communication
        - is broken
        - is no longer accessible
        - Node Disconnected - Node communication to this node does no longer work - Networking issue
        - Disconnected - general look for Disconnected - mostly Physical Disk resource xyz has been disconnected
        - Lost quorum - Lost Cluster Quorum (including votes of witness resource)

    - Critical Events - Isolated, quarantined        
        - isolated - Cluster Node has beem marked as beeing in isolated state 
        - I have been quarantined - The current node says it has been quarantined - node ungracefully leaves cluster 3 times in an hour
        - has been quarantined - Another Node in the cluster has been quarantined
        - 'Start-ClusterNode –ClearQuarantine' - clussvc tried to ClearQuarantine
        - quarantine - General Info on nodes quarantine status 
        
    - Critical Events - Disks
        - SetSharedPRKey: failed - tried to send SCSIReserve Command with Persistent Reservation Shared Key, but failed
        - Reservation.SetPrKey failed - SCSI Persistent Reservation Key failed
        - PR reserve failed, status 170 - SCSI Persistent Reservation failed - so you can´t access the disk
        - Unable to arbitrate - tried to arbitrate a disk - SCSIReserve was sent, but this node could not claim the disk
        
    - Critical Events - CSV
        - is no longer accessible from this cluster node - CSV is no longer accessible from this cluster node
        - is no longer available on this node because of - CSV is no longer available on this node because of - hopefully a reason is mentioned
        - STATUS_CONNECTION_DISCONNECTED - CSV has entered a paused state because of STATUS_CONNECTION_DISCONNECTED
#> 
#endregion ::::: ToDo - Ideas for the future ::::::

#region    ::::: Define Script Input Parameters ::::: 
param(
    $ComputerNames = $env:COMPUTERNAME,	# Pass ComputerNames e.g. H16N1, default is local host name
    [String]$LogPath = "$env:SystemDrive\MS_DATA\" + (Get-Date -Format 'yyMMdd-HHmmss'), # Path where the data on each remote computer will be stored    
    [Int]$HoursBack = 2016,	# Define how much hours we should look back in the eventlogs 1day= 24; 1Week=168, 1Month= 672, 3Month= 2016, 6Month= 4032, 1Year= 8064
    [String]$ClusterName,   # if no ClusterName is passed use local Cluster - implemented in main
    # Define which EventLogNames should be collected; either you pass the full Eventlogname or a mask like "*Hyper*"
    # To check out what the Eventlog names look like for e.g. Hyper-V: Get-WinEvent -ListLog "*Hyper-V*"
    $EventLogNames=(
        "System", 
        #"Application", 
        "*CSVFS*",
        "*Hyper-V*",
        "*Smb*",         
        "*spaces*"        
        #"*winrm*", 
        #"*wmi*", 
        #"Microsoft-Windows-FailoverClustering/Operational" 
    ),

    # Define which cluster validation tests should run on customers Cluster Nodes
    $ClusterValidationTestNames=(
        "Cluster Configuration",
        "Hyper-V Configuration",
        "Inventory","Network",    
        #"Storage",              # Note: Storage Tests will lead to a short interruption of access to disks and should not be run in a production environment 
        "System Configuration"    
    ),

    #region  ::::: Switches ::::: 
    [switch]$NetInfo 		= $True      # If $NetInfo is true, we call GetNetInfoPerHost to collect network related information
    #endregion  ::::: Switches ::::: 
)
#endregion ::::: Define Script Input Parameters :::::

#region    ::::: Define Global Variables ::::: 
    # Section for global variables, which you don´t want to show up in the parameter region        
    [bool]$IsClusSvcRunning = $False	# variable, to save status of cluster service running/stopped 

#endregion ::::: Define Global Variables ::::: 

#region    ::::: Helper Functions :::::

#function Show Progress - Global parameters
$sTimeStampScriptStart= [String](Get-Date -Format 'yyMMdd-HHmmss') # Date as String to be used in Folder Name for Files e.g. MS_DATA\190820-1032
$TimeStampScriptStart = Get-Date				         # get the timestamp, when this script starts
$TimeStampStartSaved  = $Script:TimeStampScriptStart	 # only first time save the script start timestamp

$DebugLogPath         = $LogPath                         # Directory, where the logs are stored
$DebugLogPathFull     = "$DebugLogPath\$sTimeStampScriptStart-ScriptDebug.log"   # FullPath of the Scripts Debug.log
$DebugLogLevel        = 3                                # If DebugLogLevel is 3 everything is logged; 0 is disabled, 1=Light, 2= Medium, 3=All
$DebugLogBuffer       = @()                              # Collect DebugLog Messages in ShowProgress and save them later to a file
$DebugLogCount        = 0                                # Counter for DebugLogs
$DebugLogCountMax     = 50                               # After X Messages Save to file 
$DebugLogToFile       = $True                            # Default is True, so we spew out the Debug Messages to a File 
$RunOnlyOnce          = $True                            # Bool to spew out some Messages only once
$ScriptFullName       = $MyInvocation.InvocationName     # Full Path of the Script Name


<# 
    SYNOPSIS: show what we are doing so far; should be placed on top of all other functions
    Owner: josefh/sergeg
#>
function ShowProgress { 
    param(
        $MessageUser = "",		      # pass your own message
        $ForeColor =  "White"	      # default ForeGroundColor is White        
    )
    
    If ($Script:DebugLogLevel -eq 0 ) { Return } # If DebugLogLevel is 0 exit this function imediately      
    
    # Get the function name, that was calling ShowProgress
    function GetFunctionName ([int]$StackNumber = 1) {
        # https://stackoverflow.com/questions/3689543/is-there-a-way-to-retrieve-a-powershell-function-name-from-within-a-function
        return [string]$(Get-PSCallStack)[$StackNumber].FunctionName
    }
    $TimeDisplay = [String](Get-Date -Format 'yyMMdd-HHmmss') # time stamp to display on each action/function call. eg 'yyMMdd-HHmmss'
    $TimeStampCurrent = Get-Date
    $TimeDiffToStart = $TimeStampCurrent - $TimeStampScriptStart		# overall duration since start of script
    $TimeDiffToLast =  $TimeStampCurrent - $Script:TimeStampStartSaved	# time elapsed since the last action
	$Script:TimeStampStartSaved = $TimeStampCurrent						# update/save timestamp to measure next progress duration
    $FuncName =  GetFunctionName -StackNumber 2							# Last Function Name
    [String]$DurScriptDisplay = "" + $TimeDiffToStart.Minutes + ":" + $TimeDiffToStart.Seconds	# " ;Script ran for Min:Sec  = " # display duration since script start
    [String]$DurFunctionDisplay = "" + $TimeDiffToLast.Minutes +  ":" + $TimeDiffToLast.Seconds	# " ;Last Action took Min:Sec= " # display duration of last action or function call
    if (-not ($TimeDiffToLast.TotalSeconds -ge 1) ) { $DurFunctionDisplay = "0:0" }

    
    If ($RunOnlyOnce){ # Only first time write the head line to explain the columns        
        $Description= "Script Started at $sTimeStampScriptStart ScriptFullName:$ScriptFullName on Host:$($Env:ComputerName) "        
        If (-Not ( Test-Path -Path $DebugLogPath ) ){ # if the DebugLogPath does not already exist, e.g. default is c:\MSDATA, then Create it 
            New-Item -Path $DebugLogPath -ItemType Directory
        }
        write-host -fore Green $Description
        $Description | Out-File -FilePath $DebugLogPathFull -Append

        $Description= "TimeStamp    |TimeSinceScriptStarted Min:Sec|DurationOfLastAction Min:Sec|FunctionName| UserMessage"
        <#
            Sample Output
            "TimeStamp   |TimeSinceScriptStarted Min:Sec|DurationOfLastAction Min:Sec|FunctionName| UserMessage"
            190820-103322|0:0                           |0:0                         |CreateFolder| Enter
            190820-103322|0:0|0:0|CreateFolder| ...On Node:H16N2 creating folder: \\H16N2\C$\MS_DATA\190820-103322
            190820-103322|0:0|0:0|CreateFolder| try:CreateFolder: \\H16N2\C$\MS_DATA\190820-103322
            190820-103322|0:0|0:0|CreateFolder| Folder \\H16N2\C$\MS_DATA\190820-103322 could be created successfully
            190820-103322|0:0|0:0|CreateFolder| Exit
        #>
        write-host $Description
        $Description | Out-File -FilePath $DebugLogPathFull -Append
        $Script:RunOnlyOnce= $False
    }
    $FullString= "$TimeDisplay|$DurScriptDisplay|$DurFunctionDisplay|$FuncName| $MessageUser"
    write-host -Fore $ForeColor $FullString
    
    # if $DebugLogToFile is $Ture store Output in the Logfile
    if ($DebugLogToFile){
        $Script:DebugLogCount++
        $Script:DebugLogBuffer+= $FullString
        if ($Script:DebugLogCount -ge $DebugLogCountMax) {
            write-host -ForegroundColor Yellow "Flushing DebugLogBuffer to $DebugLogPathFull"
            $Script:DebugLogBuffer | Out-File -FilePath $DebugLogPathFull -Append

            $Script:DebugLogCount= 0    # Reset DebugLogCount to 0
            $Script:DebugLogBuffer= @() # Reset DebugLogBuffer to empty String        
        }
    }
} # End of ShowProgress

# Checkout if the script runs as admin
function DoIRunAsAdmin{ 
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal `
                        ( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
    if ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) { 
        return $true  
    } 
    else { 
       return $false 
    } 
} 

function CreateFolder { 
    # SYNOPSIS: a general function to create any folder, do some checks and do reporting
    Param(
        $HostName,
        $FolderPath
    )
    ShowProgress "Enter"
    $ErrorActionPreferenceSave =  $ErrorActionPreference # Save the current ErrorActionPreference
    $ErrorActionPreference = 'Stop'   # Change ErrorActionPreferrence to stop in order to prevent the cmdlet to handle the error on its own
    
        if (-not (Test-Path $FolderPath) ){ # if the folder does not already exist
        ShowProgress "...On Node:$HostName creating folder: $FolderPath"

        try{
            ShowProgress "try:CreateFolder: $FolderPath"
            If ($Env:ComputerName -eq $HostName){ # if we are on the local host where we run the script
                New-Item -Path $FolderPath -ItemType Directory | Out-Null	# Create folder on the loacal host, to make it faster and prevent issues with WinRM
            }
            else{
                Invoke-Command -ComputerName $HostName -ScriptBlock {		        # Make it all remote capable 
                    New-Item -Path $Using:FolderPath -ItemType Directory | Out-Null	# Create folder, could be remote and suppress output
                }
            }
            ShowProgress "Folder $FolderPath could be created successfully"  
            #ShowProgress "...On Node:$HostName finished creating folder: $FolderPath"    
        }
        Catch{ # since ErrorActionPreference is on 'Stop' we jump into the catch block if New-Item failed 
            ShowProgress -Fore red "Catch: Error during Folder Creation"  # we ran into an issue 
            ShowProgress -Fore red "Unable to create the Folder $FolderPath on $HostName " 
            ShowProgress -Fore Red "FullQualifiedErrorId: $($Error[0].FullyQualifiedErrorId)"
            ShowProgress -Fore Red "Full ErrorMessage:$_"
            If ($Error[0].FullyQualifiedErrorId -like "AccessDenied*"){ 
                ShowProgress -Fore Magenta "Please check if you are running the powershell host (window) with administrative privileges" 
            }
            If ($Error[0].FullyQualifiedErrorId -like "*server name cannot be resolved*"){                 
                $HostNameFQDN= [System.Net.Dns]::GetHostEntry($HostName).HostName  
                ShowProgress -Fore Magenta "Looks like the Server Name could not be resolved. [System.Net.Dns]::GetHostEntry(`$HostName):$HostNameFQDN "
            }
                        
            ShowProgress -ForeColor Yellow -BackColor Black "Aborting this script now " 
            EXIT           
        }        
    }   
    $ErrorActionPreference = $ErrorActionPreferenceSave
    ShowProgress "Exit"
}



function CreateLogFolderOnHosts { 
# SYNOPSIS: could be only one
    param(
        $ComputerNames,
        $LogPath
    )
    ShowProgress "...Start creating Log folder on Hosts: $ComputerNames"                
    foreach($ComputerName in $ComputerNames){
        ShowProgress "...Start creating Log folder on Host:$ComputerName"                
        $LogPathDollar = $LogPath.Replace(":","$")				# e.g. C:\MS-Data --> C$\MS-Data
        $LogPathUNC = "\\$($ComputerName)\$LogPathDollar"		# e.g. \\H16N2\c$\MS-Data                
        CreateFolder -HostName $ComputerName -FolderPath $LogPathUNC        
    }
    ShowProgress "...Finished creating log folder on hosts"
}  

function MoveDataFromAllComputersToLocalComputer { 
# SYNOPSIS: move remotly collected data to local folder, e.g. C:\MS_DATA\180925-101214
    param(
        $ComputerNames        
    )
    ShowProgress "Enter"
    $LocalHost = $env:COMPUTERNAME    
    $LogPathLocal = $Script:LogPath   # LogPath e.g. c:\MS_DATA
    $ErrorActionPreferenceSave =  $ErrorActionPreference # Save the current ErrorActionPreference
    $ErrorActionPreference = 'Stop'   # Change ErrorActionPreferrence to stop in order to prevent the cmdlet to handle the error on its own
    $WaitSec = 10                     # Wait for a couple of seconds; default 10 seconds

    ShowProgress "...Start moving all data files from all Hosts:$ComputerNames to local Host:$LocalHost"                
    foreach($ComputerName in $ComputerNames){
        if (-not ($ComputerName -eq $LocalHost) ){            
            $LogPathDollar = $LogPath.Replace(":","$")                  # e.g. $LogPath = C:\MS_DATA --> C$\MS_DATA
            $LogPathRemoteUNC   = "\\$($ComputerName)\$LogPathDollar"   # e.g. \\H16N2\c$\MS_DATA               
            ShowProgress "...Start moving files from $LogPathRemoteUNC to $LogPathLocal"   

            # Sometimes the remote path is not reachable, so we check out and handle this one time
            # if it becomes a reoccuring issue we should run this in a loop and try several times 
            if ( !(Test-Path -Path $LogPathRemoteUNC) ){
                ShowProgress -Fore DarkMagenta "Catch: Could not reach remote Path: $LogPathRemoteUNC"  # we had an issue - lets wait and do the move then
                ShowProgress -Fore DarkMagenta "Let´s wait for some seconds:$WaitSec ... and try again" 
                Start-Sleep -Seconds $WaitSec # Wait for a couple of seconds if the path is not available immediately               
            } 
            # if the path is available
            ShowProgress "Finally: Moving Remote files to Local Host "                
            ShowProgress "...trying to collect all data files from all Hosts:$ComputerNames and move to local Host:$LocalHost ..."
            Move-Item -Path $LogPathRemoteUNC\* -Destination $LogPathLocal  # Move Files to Local Path   
                                        
        }
    }
    $ErrorActionPreference = $ErrorActionPreferenceSave
    ShowProgress "...Finished moving all data files from all Hosts:$ComputerNames to local Host:$LocalHost"                
    ShowProgress "Exit"
}

function CopyFilesInReportsFoldersToLocalComputer{
    # SYNOPSIS: Copy files in "C:\Windows\Cluster\Reports" from each node to local folder, e.g. C:\MS_DATA\180925-101214
    #Validation Reports, #Cluster\reports, #reports, #test-cluster 
    param(
        $ComputerNames        
    )
    ShowProgress "Enter"
    $LocalHost = $env:COMPUTERNAME    
    $LogPathLocal = $Script:LogPath   # LogPath e.g. c:\MS_DATA
    $ErrorActionPreferenceSave =  $ErrorActionPreference # Save the current ErrorActionPreference
    $ErrorActionPreference = 'Stop'   # Change ErrorActionPreferrence to stop in order to prevent the cmdlet to handle the error on its own
    $WaitSec = 10                     # Wait for a couple of seconds; default 10 seconds

    ShowProgress "...Start Copying all files in '`$Env:SystemRoot\Windows\Cluster\Reports' from each node:$ComputerNames to local Host:$LocalHost"                
    foreach($ComputerName in $ComputerNames){        
        $ReportsPath       = "$Env:SystemRoot\Cluster\Reports"   # Reports Path on the current Node "C:\Windows\Cluster\Reports"
        $ReportsPathDollar = $ReportsPath.Replace(":","$")       # e.g. $ReportsPathDollar= "C$\Windows\Cluster\Reports"
        $ReportsPathUNC= "\\$($ComputerName)\$ReportsPathDollar"       # e.g. = $ReportsPathUNC= "H16N2\C$\Windows\Cluster\Reports"
        ShowProgress "...Start copying files from $ReportsPathUNC to $LogPathLocal"   

        # Sometimes the remote path is not reachable, so we check out and handle this one time
        # if it becomes a reoccuring issue we should run this in a loop and try several times 
        if ( !(Test-Path -Path $ReportsPathUNC) ){
            ShowProgress -Fore DarkMagenta "Catch: Could not reach remote Path: $ReportsPathUNC"  # we had an issue - lets wait and do the move then
            ShowProgress -Fore DarkMagenta "Let´s wait for some seconds:$WaitSec ... and try again" 
            Start-Sleep -Seconds $WaitSec # Wait for a couple of seconds if the path is not available immediately               
        } 
        # if the path is available
        ShowProgress "Finally: Copying Remote files to Local Host "                
        ShowProgress "...trying to copy all files in $ReportsPath to $LogPathLocal"
        $ReportsFolder= "$LogPathLocal\$ComputerName\Reports"
        CreateFolder -HostName $env:COMPUTERNAME -FolderPath $ReportsFolder
        Copy-Item "$ReportsPathUNC\*" -Destination $ReportsFolder            # Copy Reports Folder to e.g. c:\MS_DATA\H16\Reports        
    }
    $ErrorActionPreference = $ErrorActionPreferenceSave
    ShowProgress "...Finished Copying all files in $($ReportsPathUNC) to $($ReportsFolder)"                
    ShowProgress "Exit"
} #Endof CopyFilesInReportsFoldersToLocalComputer
    

#endregion ::::: Helper Functions :::::

#region    ::::: Worker Functions to Collect Computer specific Data for each host  Eventlogs, OSVersion... ::::::

function GetEventLogs {
# SYNOPSIS: collect eventlogs from all machines
    param(
        $ComputerNames,                 # the name or a list of names of the computers, local or remote you want to gather Eventlogs from
        $HoursBack = $Script:HoursBack, # Define how much hours we should look back in the logs; Default is script scope variable $HoursBack
        $LogNames                       # list of event log names; either you pass the full Event Log name like "System" or a mask like "*Hyper*"
                                        # Sample: $EventLogNames=("System", "Application", "*CSVFS*")
    )
    ShowProgress "Enter"
    foreach($ComputerName in $ComputerNames){
        # Gather all EventLogs from current ComputerName, extract only last # of hours
        # Walk through each LogName in LogNames e.g. ("System", "Application", "*CSVFS*")
        foreach($LogName in $LogNames){        
            $LogFamilyNames = Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue  # $LogFamilyNames could be a mask representing several Logs - a LogFamily - e.g. *SMB*

            # if the LogName does not exist on this computer spew out a message
            If ( $Null -eq $LogFamilyNames) {
                ShowProgress -Fore DarkMagenta "Could not find the following Log on this Computer: $LogName"
            }

            # if a Pattern like *SMB* has been passed - walk through each Logname         
            foreach($LogFamilyName in $LogFamilyNames){ # Microsoft-Windows-SmbClient/Audit, Microsoft-Windows-SMBServer/Audit and so on
                $LogFileName = ($LogFamilyName.LogName).Replace("/","_") # Replace Forward Slash in EventLogNames with UnderScore

                $LogPathDollar = $LogPath.Replace(":","$")            # e.g. C:\MS-Data --> C$\MS-Data
                $LogPathUNC   = "\\$($ComputerName)\$LogPathDollar"  # e.g. \\H16N2\c$\MS-Data                
                    
                $LogFileNameXML =  "$LogPathUNC\$ComputerName" + "_" + $LogFileName + ".XML"
                $LogFileNameTXT =  "$LogPathUNC\$ComputerName" + "_" + $LogFileName + ".Log"
                $LogFileNameEvtx = "$LogPathUNC\$ComputerName" + "_" + $LogFileName + ".evtx"
                
                #Gather SystemEventlogs
                ShowProgress "...Start gathering EventLog:$($LogFamilyName.LogName) for Computer:$ComputerName"

                # Collecting EventLogs respecting HoursBack
                $StartTime = (Get-Date).AddHours(-$HoursBack) 
                # Using a Filter Hash Table to filter events that match $MinutesBack
                # More Info:  https://blogs.technet.microsoft.com/heyscriptingguy/2014/06/03/use-filterhashtable-to-filter-event-log-with-powershell/
                $Evts = Get-WinEvent -ComputerName $ComputerName -ErrorAction SilentlyContinue  -FilterHashtable @{Logname=$LogFamilyName.LogName; StartTime=$StartTime}

                #Sorting Events and selecting properties we really need
                $EvtsSorted = $Evts | Sort-Object TimeCreated -Descending | Select-Object MachineName, LevelDisplayName, TimeCreated, ProviderName, Id, LogName, Message 
                                      
                # Export Events to deserialized *.xml file
                $EvtsSorted | Export-CliXml -Path $LogFileNameXML
                # Export Events as simple *.txt file
                $EvtsSorted | Export-Csv -Path $LogFileNameTXT -NoTypeInformation
                            
                # Gathering Eventlogs in old style *.evtx with wevtutil.exe 
                ShowProgress "...Gathering *.evtx with Old-Style-Tool:wevtutil"
                $MilliSecondsBack = $HoursBack * 60 * 60 * 1000
                wevtutil.exe /remote:$ComputerName epl $LogFamilyName.LogName $LogFileNameEvtx /q:"*[System[TimeCreated[timediff(@SystemTime) <=$MilliSecondsBack]]]" /ow:true

                <# Gathering Eventlogs in the old style as *.txt - not fully checked yet
                   wevtutil qe Application /c:3 /rd:true /f:text
                   https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/wevtutil
                #>
                        
                ShowProgress "...Finished gathering $($LogFamilyName.LogName) for Computer:$ComputerName"
                ShowProgress "-----------------------------"
            }            
        }
    }
    ShowProgress "Exit"
}

#josefh- needs to be overworked
function GetStorageInfoPerHost{
    param(
        $ComputerNames
    )
    ShowProgress "Enter"
    $LogPathLocal = $Script:LogPath

    #Stor physical disks and the StorageNode they are connected to
    $AllStorageNodeDisks=@()
    $NodeDisks=@()
    
    ShowProgress "Enter"    
    $StorageNodes= Get-StorageNode
    foreach($StorageNode in $StorageNodes){
        $Dsks= $StorageNode | Get-PhysicalDisk -PhysicallyConnected
        foreach($Dsk in $Dsks){
            $Dsk | Add-Member -NotePropertyName StorageNodeName         -NotePropertyValue $StorageNode.Name            
            $NodeDisks+=$Dsk                
        }
        $NodeDisks | Export-CliXML -Path "$LogPathLocal\$($StorageNode.Name)-DisksPhysicallyConnected.xml"                    
        $AllStorageNodeDisks+= $NodeDisks 
        $NodeDisks= @()
    }               

    #gather additional data on storage
    foreach($ComputerName in $ComputerNames){           
        $StorSubSysClus      = Get-StorageSubSystem *Cluster*
        
        ShowProgress "$StorSubSysClus | Debug-StorageSubSystem"
        try{   $StorDebugOut= $StorSubSysClus | Debug-StorageSubSystem -ErrorAction Stop } # stop so that the error is not handled by the cmdlet
        catch{ write-host -ForegroundColor Cyan "FullQualifiedErrorId: $($Error[0].Exception)" }

        # Define our own Storage Information Object $StorInf, that takes all Info around Storage 
        $StorInf= [PSCustomObject][ordered]@{  
            #S2D Info
            S2D                   = Get-ClusterS2D
            S2DClusParam          = Get-Cluster | Select-Object S2D* # S2DBusTypes= 134144 -> S2D            
                
            #Physical Disks - # Interessting props Get-PhysicalDisk | select SerialNumber, CanPool, CannotPoolReason, LogicalSectorSize, PhysicalSectorSize | ft
            GetPhysicalDisk          = Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-PhysicalDisk }
            DisksPhysicallyConnected = $AllStorageNodeDisks # Physical Disks Connected to which Node + Node Name                        

            #Storage Subsystem
            StorSubSysClus        = $StorSubSysClus
            StorJob               = $StorSubSysClus | Get-StorageJob           
            StorDebugOut          = $StorDebugOut
        }

        # Check if we have a Health Resource
        $HealthResourceType= Get-ClusterResource | Where-Object {$_.ResourceType -like "*Health*"    }
        if ($Null -ne $HealthResourceType){ # if we have a Health Resource 
            ShowProgress "Found a Health Resource on this cluster - Storing Storage Info"

            #Cluster Health 
            $StorInf | Add-Member -NotePropertyName StorHealthAction  -NotePropertyValue ($StorSubSysClus | Get-StorageHealthAction  )
            $StorInf | Add-Member -NotePropertyName StorHealthSetting -NotePropertyValue ($StorSubSysClus | Get-StorageHealthSetting )
            $StorInf | Add-Member -NotePropertyName StorHealthReport  -NotePropertyValue ($StorSubSysClus | Get-StorageHealthReport  ) # deprecated in 2019 - Use Get-ClusterPerformanceHistory instead. 
            $StorInf | Add-Member -NotePropertyName HealthResParam    -NotePropertyValue (Get-ClusterResource Health | Get-ClusterParameter)
            $StorInf | Add-Member -NotePropertyName HealthResParamVal -NotePropertyValue ((Get-ClusterResource Health | Get-ClusterParameter).Value )            
        }

        # Export Info from each Node in a Separate File
        ShowProgress "Export Storage from Host: $ComputerName"
        $StorInf | Export-CliXML -Path "$LogPathLocal\$ComputerName-StorageInfoPerHost.xml"
        ShowProgress "...Finished Gathering GeneralInfoPerHost - stored in $LogPathLocal\$ComputerName-StorageInfoPerHost.xml"; write-host
    }
    ShowProgress "Exit"
}

function GetClusterPerformanceHistory{
<# $P=Import-CliXml -path "C:\MS_DATA\200204-083456\H19N1-ClusPerf.xml"
   ($P.Disks).Description | Group | Sort Name # To get disks listed on each Node
   ($P.Disks | Where Description -like "H19N1-Disk2001") | ft Desc*, SizeInGB, Time, MetricId,Value # To get values per a special disk
#>
    param(
        $ClusterName,
        $ComputerNames
    )
    ShowProgress "Enter"
    $LogPathLocal = $Script:LogPath

    # Check if it is 2019 Server with CU Oct 2019 or higher 
    $OS= (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion")
    $ReleaseId= [Int]$OS.ReleaseId
    $ReleaseIdMin= 1809 # 1809= 2019 Server + CU Oct 2019 
    if ($ReleaseId -lt $ReleaseIdMin){        
        ShowProgress -ForeColor Magenta "In this OS we did not implement Get-ClusterPerf"
        ShowProgress -ForeColor Magenta "OS:$($OS.ProductName); Build:$($OS.CurrentBuild); ReleaseId:$ReleaseId"
        ShowProgress -ForeColor Magenta "Exiting this function GetClusterPerformanceHistory"
        Return # Exit this function
    }



    if ($ClusterName -eq ""){    # if no cluster name was passed
        $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
    }
    
    # Define empty arrays to take ClusterPerformanceHistory types 
          
    foreach($ComputerName in $ComputerNames){         
        ShowProgress "Collecting ClusterPerformanceHistory for Computer: $ComputerName"

        ShowProgress "Get-VM | Get-ClusterPerf"
        $VMs= Get-VM -CimSession $ComputerName        
        If ( $Null -ne $VMs ){
            $ClusPerfVMs=@()
            $ClusPerfVHDs=@()
            foreach($VM in $VMs){
                # Get-ClusterPerf Counters for each VM             
                $V= $VM | Get-ClusterPerf
                $V | Add-Member -NotePropertyName VMName         -NotePropertyValue $VM.VMName
                $V | Add-Member -NotePropertyName VMId         -NotePropertyValue $VM.VMId
                $V | Add-Member -NotePropertyName State         -NotePropertyValue $VM.State
                $ClusPerfVMs+= $V

                $VHDs= $VM | Select-Object VMId | Get-VHD -CimSession $ComputerName | Get-ClusterPerf 
                $ClusPerfVHDs+= $VHD | Get-ClusterPerf
            }
        }

        
        ShowProgress "Get-PhysicalDisk | Get-ClusterPerf"
        $PhysicalDisks= Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-PhysicalDisk }
        $ClusPerfDisks=@()
        foreach($PhysicalDisk in $PhysicalDisks){        
            ShowProgress "Get-PhysicalDisk | Get-ClusterPerf - Disk $($PhysicalDisk.Description)"    
            try{
                $Dsk= $PhysicalDisk | Get-ClusterPerf
                $Dsk | Add-Member -NotePropertyName UniqueId         -NotePropertyValue $PhysicalDisk.UniqueId
                $Dsk | Add-Member -NotePropertyName PhysicalLocation -NotePropertyValue $PhysicalDisk.PhysicalLocation
                $Dsk | Add-Member -NotePropertyName Description      -NotePropertyValue $PhysicalDisk.Description
                $Dsk | Add-Member -NotePropertyName SizeInGB         -NotePropertyValue ($PhysicalDisk.Size/1024/1024/1024) # in GB
                $ClusPerfDisks+= $Dsk
            }
            catch{
                write-host -ForegroundColor Cyan "FullQualifiedErrorId: $($Error[0].Exception)"
            }
        }
        
        ShowProgress "Get-NetAdapter | Get-ClusterPerf"
        $NetAdapters= Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-NetAdapter }
        $ClusPerfNetAdapters=@()
        foreach($NetAdapter in $NetAdapters){            
            try{ 
                $Nic= $NetAdapter | Get-ClusterPerf
                $Nic | Add-Member -NotePropertyName Name         -NotePropertyValue $NetAdapter.Name
                $Nic | Add-Member -NotePropertyName LinkSpeed         -NotePropertyValue $NetAdapter.LinkSpeed
                $Nic | Add-Member -NotePropertyName DeviceID         -NotePropertyValue $NetAdapter.DeviceID
                $Nic | Add-Member -NotePropertyName SystemName         -NotePropertyValue $NetAdapter.SystemName                
                $ClusPerfNetAdapters+= $Nic
            }
            catch{
                write-host -ForegroundColor Cyan "FullQualifiedErrorId: $($Error[0].Exception)"
            }
                
        }
                
        ShowProgress "Get-Volume | Get-ClusterPerf"
        $Volumes= Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-Volume }
        $ClusPerfVolumes=@()
        foreach($Volume in $Volumes){            
            try{
                $Vol= $Volume | Get-ClusterPerf
                $Vol | Add-Member -NotePropertyName ObjectId         -NotePropertyValue $NetAdapter.ObjectId
                $Vol | Add-Member -NotePropertyName UniqueId         -NotePropertyValue $NetAdapter.UniqueId
                $Vol | Add-Member -NotePropertyName SizeInGB         -NotePropertyValue ($NetAdapter.Size/1024/1024/1024)
                $Vol | Add-Member -NotePropertyName FileSystemType   -NotePropertyValue $NetAdapter.FileSystemType
                $ClusPerfVolumes+= $Vol
            }            
            Catch{
                write-host -ForegroundColor Cyan "FullQualifiedErrorId: $($Error[0].Exception)"
            }    
        }

        ShowProgress "Get-ClusterNode | Get-ClusterPerf Node: $ComputerName"            
        try{
            $ClusPerfClusterNode= Get-ClusterNode $ComputerName | Get-ClusterPerf 
        }            
        Catch{
            write-host -ForegroundColor Cyan "FullQualifiedErrorId: $($Error[0].Exception)"
        }
 
        ShowProgress "Get-Cluster | Get-ClusterPerf"
        try{
            $ClusPerfCluster= Get-Cluster -Name $ClusterName | Get-ClusterPerf
        }            
        Catch{
            write-host -ForegroundColor Cyan "FullQualifiedErrorId: $($Error[0].Exception)"
        }
        
        $ClusPerf= [PSCustomObject][ordered]@{ 
            Cluster      = $ClusPerfCluster
            ClusterNode  = $ClusPerfClusterNode
            Disks        = $ClusPerfDisks
            NetAdapters  = $ClusPerfNetAdapters
            VMs          = $ClusPerfVMs
            VHDs         = $ClusPerfVHDs
            Volumes      = $ClusPerfVolumes
        }
        # Export all ClusterPerformanceHistory Info in xml File
        ShowProgress "Export ClusterPerformanceHistory: $ComputerName"
        $ClusPerf | Export-CliXML -Path "$LogPathLocal\$ComputerName-ClusPerf.xml"
        ShowProgress "...Finished Gathering ClusterPerformanceHistory - stored in $LogPathLocal\$ComputerName-ClusterPerformanceHistory.xml"; write-host

    } # foreach($ComputerName in $ComputerNames){   
} # function GetClusterPerformanceHistory{

# Gather all FirewallRules with respect to a Firewall Name Filter and return as 1 object $oFirewall
Function GetFirewallRules{
    param(
        $ComputerName,
        $FireWallNameFilter # e.g. "Cluster" # "*" gets all Firewall Rules, but you can add your filter e.g. "cluster"
    )
    ShowProgress "Enter"
    # Gather Infos you need for your object 
    $FireWallRules= Get-NetFirewallRule -CimSession $ComputerName | Where-Object { $_.DisplayName -like "*$FireWallNameFilter*" }
    $FirewallPorts= Get-NetFirewallPortFilter -CimSession $ComputerName

    $oFireWall= @()   # Create an empty array to add your Firewall Objects one by one

    ForEach($FireWallRule in $FireWallRules){        # Walk through each FirewallRule 
        ForEach($FirewallPort in $FirewallPorts){    # Walk through each Firewall Port 
            if ($FireWallPort.InstanceId -eq $FireWallRule.Id){  # check if Id´s do match 
                
                # old way to create your own Powershell Object: $F= New-Object PSObject -Property @{ 
                $F= [PSCustomObject][ordered]@{ # Create your own Object with your properties ordered
                    FWName=         $FireWallRule.Name
                    FWDisplayName=  $FireWallRule.DisplayName
                    FWDirection=    $FireWallRule.Direction
                    FWEnabled=      $FireWallRule.Enabled
                    FWProfile=      $FireWallRule.Profile

                    PTProtol=       $FireWallPort.Protocol
                    PTLocalPort=    $FireWallPort.LocalPort
                    PTRemotePort=   $FirewallPort.RemotePort
                }
                $oFirewall+= $F   # Add the current object to the Array
            }
        }
    }
    ShowProgress "Exit"
    Return $oFirewall #return the whole array to the global scope 
} # End GetFirewallRules
    
function GetMsInfo32nfo{ 
    param(
        $ComputerNames
    )
    ShowProgress "Enter"
    $LogPathLocal = $Script:LogPath
    foreach($ComputerName in $ComputerNames){
        msinfo32.exe /nfo "$LogPathLocal\$ComputerName-msinfo32.nfo" /Computer $ComputerName      
    }
    ShowProgress "Exit"
}


function GetGeneralInfoPerHost{
    param(
        $ComputerNames
    )
    ShowProgress "Enter"
    $LogPathLocal = $Script:LogPath
    foreach($ComputerName in $ComputerNames){       
        # Read Current Windows Version from the Registry 
        $WinNTKey              = Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" }
        $WinVer                = $WinNTKey | Select-Object ProductName, InstallationType, ReleaseId, CurrentMajorVersionNumber, CurrentMinorVersionNumber, CurrentBuild, BuildBranch, BuildLab, UBR
        $WinVerGUI             = "$($WinVer.ProductName) - Microsoft Windows $($WinVer.InstallationType) - Version $($WinVer.ReleaseId) (OS Build $($WinVer.CurrentBuild).$($WinVer.UBR)) "
        $VerifierQuery         = Invoke-Command -ComputerName $ComputerName -ScriptBlock { verifier.exe /query } # 
        $VerifierQuerySettings = Invoke-Command -ComputerName $ComputerName -ScriptBlock { verifier.exe /querysettings } # 
        $CrashControlRegKey    = Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-ItemProperty -path "HKLM:System\CurrentControlSet\Control\CrashControl"} # Read Dump Type from Registry        

        <# $DumpType
            "HKLM:System\CurrentControlSet\Control\CrashControl\CrashDumpEnabled"          
            $DumpType: None 0x0, Complete memory dump 0x1, Kernel memory dump 0x2, Small memory dump 0x3, Automatic Memory Dump 0x7, 
            if CrashDumpEnabled is 0x1 and a Key FilterPages shows up and is 0x1, then the UI shows "Active Memory Dump"
            if CrashDumpEnabled is 0x1 and a Key FilterPages does not show up, then the UI shows "Complete Memory Dump"

            Automatic memory dump 0x7 (Default 2012/ 2012R2 and beyond )
            https://blogs.technet.microsoft.com/askcore/2012/09/12/windows-8-and-windows-server-2012-automatic-memory-dump/
        #>        
        if ($CrashControlRegKey.CrashDumpEnabled -eq 0) { $DumpType= "None" }
        if ($CrashControlRegKey.CrashDumpEnabled -eq 2) { $DumpType= "Kernel Memory Dump" }
        if ($CrashControlRegKey.CrashDumpEnabled -eq 3) { $DumpType= "Small Memory Dump" }
        if ($CrashControlRegKey.CrashDumpEnabled -eq 7) { $DumpType= "Automatic Memory Dump" }
        
        if ( ($CrashControlRegKey.CrashDumpEnabled -eq 1) -and  ($Null -eq $CrashControlRegKey.FilterPages) ) { $DumpType= "Complete Memory Dump" } # Complete Memory Dump
        if ( ($CrashControlRegKey.CrashDumpEnabled -eq 1) -and  ($CrashControlRegKey.FilterPages -eq 1)     ) { $DumpType= "Active Memory Dump" }       # Active Memory Dump
        
        $ComputerInfo          = if ($PSVersionTable.PSVersion.Major -ge 5) { 
                                     Invoke-Command -ComputerName $ComputerName -ScriptBlock {  Get-ComputerInfo }
                                }
                                else{ 
                                     "No ComputerInfo as Get-ComputerInfo only works with PS Ver. > 5" 
                                }

        # Get All Firewall Rules
        ShowProgress "Collecting FirewallRules on Host $ComputerName"
        $oFireWallRules= GetFirewallRules -FireWallNameFilter "*" -ComputerName $ComputerName 


        $Process=  Get-Process
        $Service= Get-Service

        # Store typical Commands that can later be used to analyze data in the Exported *.xml file
        $Commands=
        ("
  `$I= Import-CliXml -path 'FullPathToYourXMLFile' e.g. `$I= Import-CliXML -path `"C:\MS_DATA\191113-113833\H16N1-GeneralInfoPerHost.xml`"
  `$I.Hotfix
  `$I.CrashControlRegKey
  `$I.FirewallRules | sort FWDirection | Select-Object FWDirection, FWName, FWDisplayName, PTProtol, PTLocalPort | Out-GridView
        ")

        # Create the custom Object to put all Info together
        $GenInf= [PSCustomObject][ordered]@{  
            HostName=              $ComputerName
            Hotfix=                Get-Hotfix -ComputerName $ComputerName            
            WinVer=                $WinVer
            WinVerGUI=             $WinVerGUI            
            PSVersionTable=        $PSVersionTable    
            VerifierQuery=         $VerifierQuery
            VerifierQuerySettings= $VerifierQuerySettings 
            CrashControlRegKey=    $CrashControlRegKey
            DumpType=              $DumpType             
            ComputerInfo=          $ComputerInfo
            FirewallRules=         $oFireWallRules
            Process=               $Process
            Service=               $Service
            Commands=              $Commands
        }        
        # Export Info from each Node in a Separate File
        ShowProgress "Export General Info: HostName, Hotfix, Winver, ComputerInfo, PSVersionTable from Host: $ComputerName"
        $GenInf | Export-CliXML -Path "$Script:LogPath\$ComputerName-GeneralInfoPerHost.xml"
        ShowProgress "...Finished Gathering GeneralInfoPerHost - stored in $LogPathLocal\$ComputerName-GeneralInfoPerHost.xml"; write-host
                        
    }    
    ShowProgress "Exit"
}

function GetNetInfoPerHost{
# SYNOPSIS: collect network related info on each host
    param(
            $ComputerNames           
    )
    ShowProgress "Enter"
    if ($Script:NetInfo -eq $false) { RETURN } # if the switch $NetInfo is false exit this function and do not collect any Net-data here
    $LogPathLocal = $Script:LogPath   # LogPath e.g. C:\MS_DATA
    foreach($ComputerName in $ComputerNames){          
        
        ShowProgress "...Start gathering network info on Computer:$ComputerName "

        $net = [PSCustomObject][ordered]@{  
            ComputerName =     $ComputerName
            NetIpconfig =      Get-NetIPConfiguration -CimSession $ComputerName
            Ipconfig =         Ipconfig /all
            IpconfigDNS =      Ipconfig /DisplayDNS

            SmbMultichannelConnection = Get-SmbMultichannelConnection -CimSession $ComputerName
            SmbServerConfiguration = Get-SmbServerConfiguration -CimSession $ComputerName
            SmbConnection = Get-SmbConnection -CimSession $ComputerName
            SmbSession = Get-SmbSession -CimSession $ComputerName
            SmbBandWidthLimit = Get-SmbBandWidthLimit -CimSession $ComputerName -ErrorAction SilentlyContinue
            SmbServerNetworkInterface = Get-SmbServerNetworkInterface -CimSession $ComputerName
            SmbMultichannelConstraint = Get-SmbMultichannelConstraint -CimSession $ComputerName
            SmbWitnessClient = Get-SmbWitnessClient -CimSession $ComputerName

            NIC = Get-NetAdapter -CimSession $ComputerName
            NICAdv = Get-NetAdapterAdvancedProperty -CimSession $ComputerName -Name *
            NICBind = Get-NetAdapterBinding -CimSession $ComputerName –Name *
            NICRxTx = Get-NetAdapterChecksumOffload -CimSession $ComputerName -Name *
            NICHW = Get-NetAdapterHardwareInfo -CimSession $ComputerName -Name *
            NICRIpsec = Get-NetAdapterIPsecOffload -CimSession $ComputerName -Name *
            NICLso = Get-NetAdapterLso -CimSession $ComputerName -Name *
            NICQos = Get-NetAdapterQos -CimSession $ComputerName –Name *

            NICREnc = Get-NetAdapterEncapsulatedPacketTaskOffload -CimSession $ComputerName -Name *
            NICRdma = Get-NetAdapterRdma -CimSession $ComputerName –Name *
            NICRsc = Get-NetAdapterRsc -CimSession $ComputerName –Name *
            NICRss = Get-NetAdapterRss -CimSession $ComputerName –Name *
            NICSriov = Get-NetAdapterSriov -CimSession $ComputerName –Name *
            NICVmqQueue = Get-NetAdapterVmqQueue -CimSession $ComputerName –Name *
            NICVmq = Get-NetAdapterVmq -CimSession $ComputerName –Name *
        }
        
        # Export Info from each Node in a Separate File
        $net | Export-CliXML -Path "$LogPathLocal\$ComputerName-NetInfoPerHost.xml"
        ShowProgress "...Finished gathering network Info per computer and stored in $LogPathLocal\$ComputerName-NetInfoPerHost.xml"        
        ShowProgress "Exit"
    }
}    
#endregion ::::: Workerfunctions to Collect Computer specific Data for each host  Eventlogs, OSVersion... ::::::

#region    ::::: Worker Functions to collect Cluster specific Info :::::: 

function IfClusterGetNodeNames{ 
# SYNOPSIS: Test nodes connection and create a list of reachable nodes
    ShowProgress "Enter"
    $ErrorActionPreferenceNow= $ErrorActionPreference
    $ErrorActionPreference= 'Stop'
	$LocalComputerName = $env:COMPUTERNAME
    # Checkout if the cluster service is answering on this node
    try{ 
        # Check if the cluster service is running 
        if ( (Get-Service -Name ClusSvc).Status -eq "Running"  ){
            ShowProgress -Fore Green "Cluster Service is running on this computer: $LocalComputerName"
            $Script:IsClusSvcRunning = $True
        }
        else { # if we are on a cluster, but the cluster service is not running we land here
            $Script:IsClusSvcRunning= $False
            ShowProgress -Fore DarkMagenta "Cluster Service 'clussvc' is not running on this computer " 
            ShowProgress "Exit" # Exit this loop if cluster service is not running
            RETURN $LocalComputerName # Return local ComputerName, if this computer is not running cluster service to gather Logs from this Host
        }
    } 
    
    catch{ # if we are not on a cluster at all we are landing here 
        ShowProgress -Fore DarkMagenta " 'Get-Service -Name ClusSvc' did not answer - looks if we have no Cluster Service on this computer " 
        ShowProgress "Exit"
        RETURN $LocalComputerName # Return local ComputerName, if this computer is not running cluster service to gather Logs from this Host
    }
    # if cluster service did not answer we do not reach the following code 

    # if cluster service answered we reached this code and will Test Network Connections to all Cluster Nodes
    ShowProgress "...Start testing if we can reach the Cluster Nodes over the network"
    $GoodNodeNames = @()  # Cluster Nodes we can reach over the network
    $BadNodeNames =  @()  # Cluster Nodes we can not reach over the network

    $ClusterNodeNames= (Get-ClusterNode).NodeName
    foreach($ClusterNodeName in $ClusterNodeNames){ 
        if (Test-Connection -ComputerName $ClusterNodeName -Count 1 -Quiet){ # test network connection
            $GoodNodeNames += $ClusterNodeName
        }
        else {
            $BadNodeNames += $ClusterNodeName
        }
    }
    $Nodes = [PSCustomObject]@{
        Good = $GoodNodeNames
        Bad =  $BadNodeNames
    }
        
    ShowProgress -Fore Green   "   - Could connect to Cluster Nodes: $($Nodes.Good)"
    if ( '' -ne ($Nodes.Bad) ){ # if we could not connect to all Nodes and have Bad Nodes...
        ShowProgress -Fore Red "   - Could not connect to Cluster Nodes: $($Nodes.Bad)" # ...show bad nodes
    }
    else{
        ShowProgress "   - Could connect to all Cluster Nodes" -ForeColor "green"

    }
    ShowProgress "...Finished testing network connection to Cluster Nodes"
    $ErrorActionPreference= $ErrorActionPreferenceNow
    ShowProgress "Exit"
    Return $Nodes.Good # Return only the Good Nodes we can reach    
}

Function GetClusterLogs{
    param(
        $ClusterName,                     # could be replaced by the Cluster Name as string to run remotely
        $HoursBack=   $Script:HoursBack   # How much Minutes should we look back in the logs - it´s defined in the main chapter
    )
    ShowProgress "Enter"
    If (!($IsClusSvcRunning)){
         ShowProgress "Exit" 
         RETURN # Exit this function
    }
    if ($ClusterName -eq ""){    # if no cluster name was passed
        $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
    }

    ShowProgress "...Start Gathering Cluster Logs for Cluster Name:$ClusterName"

    # Gather ClusterLogs from All Nodes
    $MinutesBack= $HoursBack * 60
    Get-ClusterLog -Cluster $ClusterName -TimeSpan $MinutesBack -Destination $Script:LogPath -UseLocalTime
    ShowProgress "...Finished Gathering Cluster Logs for Cluster Name:$ClusterName";write-host
    ShowProgress "Exit"
}

Function GetClusterHealthLogs{
    param(
        $ClusterName,                     # could be replaced by the Cluster Name as string to run remotely
        $HoursBack=   $Script:HoursBack   # How much Minutes should we look back in the logs - it´s defined in the main chapter
    )
    ShowProgress "Enter"
    If (!($IsClusSvcRunning)){
         ShowProgress "Exit" 
         RETURN # Exit this function
    }
    if ($ClusterName -eq ""){    # if no cluster name was passed
        $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
    }

    ShowProgress "...Start Gathering Cluster Health Logs for Cluster Name:$ClusterName"

    # Gather ClusterLogs from All Nodes
    $MinutesBack= $HoursBack * 60
    Get-ClusterLog -Cluster $ClusterName -TimeSpan $MinutesBack -Destination $Script:LogPath -UseLocalTime -Health
    ShowProgress "...Finished Gathering Cluster Health Logs for Cluster Name:$ClusterName";write-host
    ShowProgress "Exit"
}

function GetClusNet{ # Get all Cluster Network Info and add Livmigration Networks + LM Order and put it in one object
    param(
        $ClusterName
    )
    
    ShowProgress "Enter"
    If (!($IsClusSvcRunning)){
         ShowProgress "Clussvc is not running"
         ShowProgress "Exit" 
         RETURN # Exit this function if clussvc is not running
    }
    if ($ClusterName -eq ""){    # if no cluster name was passed
        $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
    }

    $ResourceTypeVM= Get-ClusterResourceType -Cluster $ClusterName "Virtual Machine" | Get-ClusterParameter
    $ClusterNetworks=  Get-ClusterNetwork -Cluster $ClusterName
    $LiveMigrationExludeNetworks= Get-ClusterResourceType -Cluster $ClusterName "Virtual Machine" | Get-ClusterParameter MigrationExcludeNetworks
    $LiveMigrationNetworkOrder  = (Get-ClusterResourceType -Cluster $ClusterName "Virtual Machine" | Get-ClusterParameter MigrationNetworkOrder).Value.split(";")


    $ClusNet= @()
    foreach($ClusterNetwork in $ClusterNetworks){
        $i=0
        foreach($LMNetOrder in $LiveMigrationNetworkOrder){
            if ($ClusterNetwork.Id -eq $LMNetOrder){
                $LiveMigrationOrder= $i
                BREAK
            }
            else{
                $LiveMigrationOrder= "no LM"
            }
            $i++
        }
        
        foreach($LiveMigrationExludeNetwork in $LiveMigrationExludeNetworks){
            $UsedForLiveMigration= $True
            if ($ClusterNetwork.Id -eq $LiveMigrationExludeNetwork.value){
                $UsedForLiveMigration= $False
            }
                        
            $L= [PSCustomObject][ordered]@{
                Address               = $ClusterNetwork.Address
                AddressMask           = $ClusterNetwork.AddressMask
                AutoMetric            = $ClusterNetwork.AutoMetric
                Cluster               = $ClusterNetwork.Cluster
                Description           = $ClusterNetwork.Description
                Id                    = $ClusterNetwork.Id
                Ipv4Addresses         = $ClusterNetwork.Ipv4Addresses
                Ipv4PrefixLengths     = $ClusterNetwork.Ipv4PrefixLengths
                Ipv6Addresses         = $ClusterNetwork.Ipv6Addresses
                Ipv6PrefixLengths     = $ClusterNetwork.Ipv6PrefixLengths
                Metric                = $ClusterNetwork.Metric
                Name                  = $ClusterNetwork.Name
                Role                  = $ClusterNetwork.Role
                State                 = $ClusterNetwork.State
                IsUsedForLiveMigration= $UsedForLiveMigration
                LiveMigrationOrder  = $LiveMigrationOrder

            }
            $ClusNet+=$L        
        }
    }
    ShowProgress "Exit"
    Return $ClusNet
}

function GetClusterInfo{
    param(
        $ClusterName        
    )
    $LogPathLocal = $Script:LogPath
    ShowProgress "Enter"
    If (!($IsClusSvcRunning)){
         ShowProgress "Exit" 
         RETURN # Exit this function if clussvc is not running
    }
    if ($ClusterName -eq ""){    # if no cluster name was passed
        $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
    }

    $C= New-Object PSObject -Property @{ # Create your own Object with your properties 
        Name=           $ClusterName
        CSV=            Get-ClusterSharedVolume
        CSVParm=        Get-ClusterSharedVolume | Get-ClusterParameter
        CSVState=       Get-ClusterSharedVolumeState
        Group=          Get-ClusterGroup
        Net=            Get-ClusterNetwork
        NetplusLM=      GetClusNet -ClusterName $ClusterName
        NIC=            Get-ClusterNetworkInterface
        Node=           Get-ClusterNode
        Param=          Get-Cluster -Name $ClusterName | Format-List *
        Quorum=         Get-ClusterQuorum
        Res=            Get-ClusterResource
    }
    # Export Cluster Info 
    $FileName= "$LogPathLocal\$($ClusterName)_ClusterInfo.XML"
    $C | Export-Clixml -Path $FileName
    
    # Create "$LogPathLocal\DependencyReports"
    ShowProgress "...Start creating folder $LogPathLocal\DependencyReports"                
    $LogPathDollar = $LogPathLocal.Replace(":","$")				# e.g. C:\MS-Data --> C$\MS-Data
    $LogPathUNC = "\\$($ComputerName)\$LogPathDollar"		# e.g. \\H16N2\c$\MS-Data        
    CreateFolder -HostName $Env:ComputerName -FolderPath $DebugLogPath\DependencyReports

    # Create Dependency Reports and save to LogPathLocal    
    $ClusterGroups= $C.Group
    ForEach($ClusterGroup in $ClusterGroups){
        Get-ClusterResourceDependencyReport -Group $ClusterGroup -ErrorAction SilentlyContinue | Copy-Item -Destination "$LogPathLocal\DependencyReports"
        Rename-Item -Path "$LogPathLocal\DependencyReports\$($ClusterGroup.Id).htm" -NewName "$ClusterGroup-ClusGroupDependencyRep.htm" -ErrorAction SilentlyContinue
    }
    ShowProgress "...Finished Gathering ClusterInfo - stored in  $FileName "
    ShowProgress "...Finished Gathering DependencyReports - stored in  $LogPathLocal\DependencyReports" ; write-host
    ShowProgress "Exit"
}

# Collect Cluster Hive and other files you need specific to cluster Nodes
function GetClusterHives{
    param(
        $ClusterName        
    )

    ShowProgress "Enter"
    If (!($IsClusSvcRunning)){
         ShowProgress "Exit" 
         RETURN # Exit this function if clussvc is not running
    }
    if ($ClusterName -eq ""){    # if no cluster name was passed
        $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
    }

    $ClusterNodes= Get-ClusterNode -Cluster $ClusterName
            
    ForEach($ClusterNode in $ClusterNodes){                     # Walk through each ClusterNode 
        $HiveFileUNCPath= $Script:LogPath.Replace(":","$")        # C:\MS-Data --> C$\MS-Data
        $RemotePath= "\\$($ClusterNode.Name)\$HiveFileUNCPath"  # \\H16N2\c$\MS-Data
                
        # Saving the cluster Hive of the current Node
        $TimeStamp= [String](Get-Date -Format 'yyMMdd-hhmmss')          # Create a Timestamp for the Cluster Hive File
        $ClusterHiveFileName    = "$ClusterNode-Cluster-$TimeStamp.Hiv" # let´s add a time stamp to the cluster Hive File Name to make it unique
        $ClusterHiveFileNameFull= "$RemotePath\$ClusterHiveFileName" # e.g. \\H16N2\c$\MS-Data\H16N2-Cluster-180705-103933.Hiv
                
        # Export Cluster Hive on the remote node
        Invoke-Command -ComputerName $ClusterNode.Name -ScriptBlock { Invoke-Expression "REG SAVE 'HKLM\cluster' $Using:ClusterHiveFileNameFull" }

        # Move Cluster Hive later from remote node to local node we run the script from
        ShowProgress "...Finished Gathering ClusterHives - stored in $Script:LogPath "; write-host

        ShowProgress "Exit"
    }
}

function GetClusterValidationInfo{
    param(
        $ClusterName,
        $TestNames= $ClusterValidationTestNames 
    )
    ShowProgress "Enter"
    If (!($IsClusSvcRunning)){ # if the cluster service is not running on this node where the script runs, exit this function
         ShowProgress "Exit" 
         RETURN # Exit this function
    }
    if ($ClusterName -eq ""){    # if no cluster name was passed
        $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
    }

    # Extension .htm is added automatically 
    Test-Cluster -Cluster $ClusterName -Include $TestNames -ReportName "$LogPathLocal\$ClusterName-Validation-Report" 
    ShowProgress "Exit"
}

function 5120 {
    # SYNOPSIS:  collect data for symptom System Event ID 5120
    ShowProgress "Enter"    
    # to be defined
    ShowProgress "Exit"
}

#endregion    ::::: Worker Functions to collect Cluster specific Info ::::::

#region    ===== MAIN - Preparations    ==================================================
ShowProgress -Fore Green "Script Start..."

# Checkout if we are running with elevated privileges
$RunningAsAdmin= DoIRunAsAdmin
If ($RunningAsAdmin -eq $False){
    ShowProgress -Fore Red         "The script does not run in privileged (admin) mode"
    ShowProgress -Fore DarkMagenta "so we can´t query the cluster service, can´t create a log folder, debuglogfile and so on... "
    ShowProgress -Fore DarkMagenta "Please run again in privileged mode as admin"
    ShowProgress -Fore Red         "Exiting script now !"
    EXIT # Exit the script now as it doesn´t make sense to run this script in non privileged mode
}

ShowProgress -Fore Green "Running functions that should go quickly now ..."

if ($ClusterName -eq ""){    # if no cluster name was passed
    $ClusterName= (Get-Cluster).Name  # Get local cluster name on this host
}

#josefh - needs to be overworked in order to do the check on a remote cluster as well
$ComputerNames = IfClusterGetNodeNames # Check if Cluster Service answers on the current computer; if yes get the node names we can reach over network else return local computername


ShowProgress "...running data collection on ComputerNames: $ComputerNames"
if ($IsClusSvcRunning) { # if script runs on a cluster create the LogFolder $LogPath on all Cluster Nodes
    CreateLogFolderOnHosts -ComputerNames $ComputerNames -LogPath $LogPath 
}	
else { # else if the cluster service is not running create LogFolder $LogPath on local host
    CreateFolder -HostName "$env:ComputerName" -FolderPath $LogPath
}
#endregion ===== MAIN - Preparations    ==================================================

#region    ===== MAIN - Workerfunctions ==================================================
#    Run ::::: Worker Functions to collect general Info ::::::
#
ShowProgress -Fore Green "Running functions that take longer now ..."
GetEventLogs          -ComputerNames $ComputerNames -HoursBack $HoursBack -LogNames $EventLogNames
GetStorageInfoPerHost -ComputerNames $ComputerNames # Storage, Disk, Volume...
GetGeneralInfoPerHost -ComputerNames $ComputerNames # HostName, Hotfix, Winver etc. 
GetNetInfoPerHost     -ComputerNames $ComputerNames # Ipconfig, Smb*, NIC* etc. 
GetMsInfo32nfo        -ComputerNames $ComputerNames
#    End ::::: Worker Functions to collect general Info ::::::


#    Run ::::: Worker Functions to collect Cluster specific Info ::::::
GetClusterLogs       -ClusterName $ClusterName
GetClusterHealthLogs -ClusterName $ClusterName
GetClusterInfo       -ClusterName $ClusterName
GetClusterHives      -ClusterName $ClusterName
#GetClusterValidationInfo -ClusterName $ClusterName # -TestNames look for $ClusterValidationTestNames in parameter section
#GetClusterPerformanceHistory -ClusterName $ClusterName -ComputerNames $ComputerNames
#    End ::::: Worker Functions to collect Cluster specific Info ::::::


#    Administrative Tasks
MoveDataFromAllComputersToLocalComputer  -ComputerNames $ComputerNames
CopyFilesInReportsFoldersToLocalComputer -ComputerNames $ComputerNames # From each node - copy all files in c:\windows\cluster\reports to Local MS_DATA Folder 
#


#    End of Script Messages
$ScriptDuration= ( (Get-Date) - $TimeStampScriptStart ) # Calculate how long the script ran
ShowProgress -Fore Green "Script ran for Min:Sec - $($ScriptDuration.Minutes):$($ScriptDuration.Seconds) "
$DebugLogCount= $DebugLogCountMax # to flush $DebugLogBuffer to the Logfile
ShowProgress -Fore Green "Exit Script - End of Script Logs can be found in: $LogPath"
#
#endregion ===== MAIN - Workerfunctions ==================================================
# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBIbvvVQNwa4mFg
# a9BGGLD5DpbH06bPvgJhk9o0MjGwEqCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIETpWrNC7SmMUFIo5/S6U9Zf
# qNIh7D/OJ6r84pwinL9oMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAdJ//gx9PGOuExyuiBFwUs2ye1xVlXfB7be48trQqaNLNSxjwxHx6/vo8
# X0yiaBD4Hu9s1nkWTQcmXuiM1Q2UvzTRvEqd0tVGCtm4emynjReLVyldt730IzJM
# Kt0Uuorbqffiy7OQ7hdLmxEGmcpvDjQyGBgX6D95QNhumKXH1beTyXRJfo6ZcQK4
# v+phM0A44zN8aPsFps2nsBobkRwxu1T7iSKLpHBSucFLNsPeksGM80yOk9GqDij7
# J1Q3sOImR8wKD9ryKMW1DLR4XYkvVTBB2EDStqFQmaixndwr1DroaxWXAt+QxtVr
# +PtCqE6wvuLNCGWS5Qp4qk3yRzVvPaGCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAwRRL9ZTEjPYjzX+L+FsPVymwa9vE70VA0mayzB7wxpQIGZlcW3Vim
# GBMyMDI0MDYxMjE1MDAzOC4xMzNaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
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
# IgQgboOiH2naIpbhpsHuPQ8ospQC40cBaJe0zRmDqkwY15MwgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCAz1COr5bD+ZPdEgQjWvcIWuDJcQbdgq8Ndj0xyMuYm
# KjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB49+9
# m5ocaIMiAAEAAAHjMCIEINsd2aW1Y7wtnrogb26/8zWtZkK5NN+chuZAiFvrXewx
# MA0GCSqGSIb3DQEBCwUABIICAAwxwtkyFYsbVfMVFhBuPJcK3QXA58KiBxUk1L95
# GnsJwCvvbLdLaOjoX7eOe1o8vEZzaxU5XBwjD5V0I50vLf1k6NADtUITlYQCfFii
# VN0YJ4Py+c+viQ4Egeu/quB7p2QxIqIXsw72VQn9JwD8lGDFS3PosNOjuIPtaekm
# nRMmiiHFnr5jp38FzgiD0U480Ep8kl6VIjUe3dYYVe+8FhtqJlkKFKM2C+WfHH7c
# Yc0NIPpolShoXNNx6eFNdk0UIXrWqDkt4Nbxg57SMputmLhD+DSUIXlSGQH9Kt6C
# +xdScaFtRRt1Llh3DTeLNud3GZVRDTvuy/ra1R5JjNi1P4zVIdBfvpPfhh1XHuV6
# zMU1sxMCrwXHRYBNIgKptVP5NKefl+cbjmnlKHY0WxR2SVnn+S1W4vUllYDa4Kmh
# VE54VWPgKz04KrRCqARV+FaauCLyslfA8UP0fqstOvYeQcTIiazfI0e+FGQoP1l3
# PK7Tc1RXz0KZ6I8GiN+9fGRKzTo5T9gKINPCzCX1hjA+zv4Wkk3nkDh8AAmEZGaM
# KG63CDowuSGJ0+AJB0qwmxElErHom2UWtxcRY3FNFsV0niCs/6SQDg1O8slS3+Me
# VcGWGml0z+6ogd6a9goFaO8fT4HIv16EFAbVe+hC3oVd6aWKb0dBmeehE+zYqJG+
# z7nh
# SIG # End signature block
