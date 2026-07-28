param( 
    [string]$DataPath,
    [switch]$AcceptEula,
    [switch]$SkipLogs,
    [switch]$Trace,
    [switch]$Network,
    [switch]$RPC,
    [switch]$ProcMon,
    [switch]$PSR
)
<#
COM-COLLECT
ALIAS : bpostaci, maporcol
Date  : 15/11/2023

  Updates:
        v1.0 | Initial release
        v1.1 | 2023-11-23 Marius Porcolean (maporcol@microsoft.com)
            - Improved logic for collecting dumps. Previous logic resulted in dumps from irrelevant processes too.
            - Use already existing function Export-RegistryKey instead of Export-RegistryKey2 & instead of "manual work"
            - Use already existing function Export-EventLog instead of "manual work"
            - Use already existing function Invoke-CustomCommand instead of "manual work"
            - Eliminate ExpRegFeatureManagement function & just use Export-RegistryKey instead
        
        v1.2 | 2024-05-20 Marius Porcolean (maporcol@microsoft.com)
            - Integrate COM-Collect with the "standard" Collect-Commons.psm1 module, in order to work within TSS (i.e: add some necessary functions in COM-Collect itself)


#>

$SCRIPT_VERSION = "1.2"
$toolName = "COM-Collect"

write-host "" -ForegroundColor Magenta 
write-host "  _____  ____    __  ___" -ForegroundColor Magenta
write-host " / ___/ / __ \  /  |/  /" -ForegroundColor Magenta
write-host "/ /__  / /_/ / / /|_/ /" -ForegroundColor Magenta
write-host "\___/  \____/ /_/  /_/" -ForegroundColor Magenta
write-host ""
write-host ""
write-host "  _____  ____    __    __    ____  _____ ______" -ForegroundColor Magenta
write-host " / ___/ / __ \  / /   / /   / __/ / ___//_  __/" -ForegroundColor Magenta
write-host "/ /__  / /_/ / / /__ / /__ / _/  / /__   / /" -ForegroundColor Magenta
write-host "\___/  \____/ /____//____//___/  \___/  /_/" -ForegroundColor Magenta
write-host " "
write-host "[Version:" $SCRIPT_VERSION"]"
write-host ""


#####################################################################
##################### SPECIFIC FUNCTIONS START ######################
#####################################################################
function Get-UserConfirmation {
    $confirmation = $null

    while ($confirmation -notin 'Y', 'N') {
        $confirmation = Read-Host "Do you want to continue? [Y/N]"

        if ($confirmation -notin 'Y', 'N') {
            Write-Host "Invalid input. Please enter 'Y' for Yes or 'N' for No."
        }
    }

    return $confirmation
}

Function Get-GUIDFromInputString {
    param (
        [string]$inputString
    )

    # Define a regular expression pattern to match the GUID
    $pattern = '\{[0-9A-Fa-f-]+\}'

    # Use Select-String to find and extract the GUID from the string
    $guidMatch = $inputString | Select-String -Pattern $pattern

    # Extract the matched GUID from the result
    if ($guidMatch) {
        $guid = $guidMatch.Matches.Value
        return $guid
    }
    else {
        return $null
    }
}

function IsNumeric($text) {
    $null = [Double]::TryParse($text, [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$null)
    return $?
}

# for the Diag part
Function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [Parameter()]
        [ValidateSet('Error', 'Warning', 'Pass', 'Info')]
        [string] $Type = $null
    )
    
    $Color = $null
    switch ($Type) {
        "Error" {
            $Message = (Get-Date).ToString("yyyyMMdd-HH:mm:ss.fff") + "    " + "[ERROR]   " + $Message
            $Color = 'Magenta'
        }
        "Warning" {
            $Message = (Get-Date).ToString("yyyyMMdd-HH:mm:ss.fff") + "    " + "[WARNING] " + $Message
            $Color = 'Yellow'
        }
        "Pass" {
            $Message = (Get-Date).ToString("yyyyMMdd-HH:mm:ss.fff") + "    " + "[PASS]    " + $Message
            $Color = 'Green'
        }
        Default {
            $Message = (Get-Date).ToString("yyyyMMdd-HH:mm:ss.fff") + "    " + "[INFO]    " + $Message
        }
    }
    if ([string]::IsNullOrEmpty($Color)) {
        Write-Host $Message
    } 
    else {
        Write-Host $Message -ForegroundColor $Color
    }
    if (!($NoLogFile)) {
        $Message | Out-File -FilePath $diagfile -Append
    }
}

Function Start-Traces {
    Invoke-CustomCommand "ipconfig /flushdns"
    Invoke-CustomCommand "nbtstat -R"
    Invoke-CustomCommand "KList purge"

    # initialize ETW trace with 
    # COMSVCS provider
    Invoke-CustomCommand "logman create trace '$traceName' -ow -o '$($TracesDir)COM-Trace-$($env:COMPUTERNAME).etl' -p '{B46FA1AD-B22D-4362-B072-9F5BA07B046D}' 0xFFFFFFFFFFFFFFFF 0xFF -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 2048 -ets"
    
    # COMADMIN provider
    Invoke-CustomCommand "logman update trace '$traceName' -p '{A0C4702B-51F7-4ea9-9C74-E39952C694B8}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"

    # DCOMSCM provider
    Invoke-CustomCommand "logman update trace '$traceName' -p '{9474a749-a98d-4f52-9f45-5b20247e4f01}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"

    # OLE32 provider
    Invoke-CustomCommand "reg add HKEY_LOCAL_MACHINE\Software\Microsoft\OLE\Tracing /v ExecutablesToTrace /t REG_MULTI_SZ /d * /f"
    Invoke-CustomCommand "logman update trace '$traceName' -p '{bda92ae8-9f11-4d49-ba1d-a4c2abca692e}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"


    # start RPC tracing if selected
    if ($RPC) {
        # Microsoft-Windows-RPC
        Invoke-CustomCommand "logman update trace '$traceName' -p '{6AD52B32-D609-4BE9-AE07-CE8DAE937E39}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"

        # Microsoft-Windows-RPC-Events
        Invoke-CustomCommand "logman update trace '$traceName' -p '{F4AED7C7-A898-4627-B053-44A7CAA12FCD}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"

        # Microsoft-Windows-RPCSS
        Invoke-CustomCommand "logman update trace '$traceName' -p '{D8975F88-7DDB-4ED0-91BF-3ADF48C48E0C}' 0xFFFFFFFFFFFFFFFF 0xFF -ets"
    }
    if ($Network) {
        Invoke-CustomCommand "netsh trace start capture=yes scenario=netconnection maxsize=1024 report=disabled tracefile='$($TracesDir)NETCAP-$($env:COMPUTERNAME).etl'"
    }  
    if ($ProcMon) {
        Invoke-CustomCommand "start $($Root)\Procmon.exe '/AcceptEula /Quiet /Minimized /BackingFile $($TracesDir)$($env:COMPUTERNAME).PML'"
    }
    if ($PSR) {
        Invoke-CustomCommand "psr.exe /start /output $($TracesDir)PSR_$($env:COMPUTERNAME)_.zip /maxsc 99 /sc 1 /gui 1"
        Write-Host -ForegroundColor Yellow "WARNING: You selected the -PSR flag. This activates the Problem Steps Recorder tool, which automatically collects screenshots & information about steps performed (e.g: user left-clicked in text area of CMD.exe, user clicked close on Event Viewer, etc). Please avoid displaying sensitive information like passwords or other things."
    }

    Write-Log "Live captures started"
}

Function Stop-Traces {
    Write-Log "Stopping live captures..."
    Invoke-CustomCommand "logman stop '$traceName' -ets"
    Invoke-CustomCommand "reg delete HKEY_LOCAL_MACHINE\Software\Microsoft\OLE\Tracing /v ExecutablesToTrace /f"

    if ($Network) {
        Invoke-CustomCommand "netsh trace stop"
    }  
    if ($ProcMon) {
        Invoke-CustomCommand "start $($Root)\Procmon.exe '/Terminate'"
    }
    if ($PSR) {
        Invoke-CustomCommand "psr.exe /stop"
    }

    Invoke-CustomCommand "tasklist /svc" -DestinationFile ("Traces\tasklist-$env:COMPUTERNAME.txt")
}

#####################################################################
###################### SPECIFIC FUNCTIONS END #######################
#####################################################################

$global:Root = Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path
try {
    Import-Module ($global:Root + "\Collect-Commons.psm1") -Force -DisableNameChecking -ErrorAction Stop
}
catch {
    Write-Host "Unable to import the helper module, can't continue without it! Exiting..." -ForegroundColor Red
    Write-Host ($_.Exception.Message) -ForegroundColor Red
    exit
}

# Deny execution if not running as admin
Deny-IfNotAdmin

# Check parameters
# Reject execution if tracing parameters are specified without the main trace flag
if (!$Trace -and ($RPC -or $Network -or $PSR -or $ProcMon)) {
    Write-Host -ForegroundColor Yellow "WARNING: You selected a parameter for tracing, but did not specify the main -Trace flag. Please try again, including -Trace. Consider also checking out the examples, following the instructions in the REMARKS section below."
}
# Reject execution if -SkipLog specified, but -Trace was not. Makes no sense to run.
if ($SkipLog -and !$Trace) {
    Write-Host -ForegroundColor Yellow "WARNING: You selected a parameter for tracing, but did not specify the main -Trace flag. Please try again, including -Trace. Consider also checking out the examples, following the instructions in the REMARKS section below."
}


$resName = "$($toolName -replace "Collect","Results")-" + $env:computername + "-" + $(get-date -f yyyyMMdd_HHmmss)
# Check if a destination folder was explicitly requested
if ($DataPath) {
    if (-not (Test-Path $DataPath)) {
        Write-Host "The folder $DataPath does not exist. Please make sure to specify a folder that exists." -ForegroundColor Yellow
        exit
    }
    $global:resDir = $DataPath + "\" + $resName
}
else {
    $global:resDir = $global:Root + "\" + $resName
}

New-Item -ItemType Directory -Path $global:resDir | Out-Null
$global:outfile = $global:resDir + "\script-output.txt"
$global:errfile = $global:resDir + "\script-errors.txt"
$global:diagfile = $global:resDir + "\COM-COMPLUS-DCOM-Diag.txt"

Write-Log ("Command line:" + $MyInvocation.Line)

# License Agreement
if ($AcceptEula) {
    Write-Log "AcceptEula switch specified, silently continuing"
    $eulaAccepted = ShowEULAIfNeeded $toolName 2
}
else {
    $eulaAccepted = ShowEULAIfNeeded $toolName 0
    if ($eulaAccepted -ne "Yes") {
        Write-Log "EULA declined, exiting"
        exit
    }
}
Write-Log "EULA accepted, continuing"


# Start traces if "selected"
if ($Trace) {
    $TracesDir = $global:resDir + "\Traces\"
    New-Item -ItemType Directory -Path $TracesDir | Out-Null
    $traceName = "COM-Trace"
    Start-Traces
    Write-Host -ForegroundColor Cyan "Press ENTER to stop the live captures, after reproducing the issue..." 
    Read-Host
    Stop-Traces
}

if ($SkipLogs) {
    Write-Host -ForegroundColor Yellow "SkipLogs parameter specified, exiting now."
    exit
}

Write-log "Getting list of processes & services"
$WMI_AVAILABLE = $false; 
$result = ListProcsAndSvcs
if ($result -eq $false) {
    Write-Log "To run this script correctly WMI should be working, but it appears to be not. Please investigate why WMI is not working."
    Write-Host "Do you still want to continue, despite WMI not working?" -ForegroundColor Yellow
    $choice = Get-UserConfirmation
    if ( ($choice -eq 'Y') -or ($choice -eq 'y')) {
        Write-Log "Continue selected, going ahead without WMI."
    }
    else {
        Write-Log "Stop selected, exiting..."
        exit 
    }
}
else {
    Write-Log "WMI is OK"
    $WMI_AVAILABLE = $true
}

Write-log "Getting MSINFO32"
Start-Process -FilePath "msinfo32.exe" -ArgumentList "/nfo $($global:resDir + "\msinfo32.nfo")"
Get-ComputerInfo | Out-File -FilePath  ($global:resDir + "\computerinfo.txt")

Export-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\Ole" -DestinationFile "reg-Ole.reg.txt"
Export-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\Rpc" -DestinationFile "reg-Rpc.reg.txt"
Export-RegistryKey -KeyPath "SOFTWARE\Policies\Microsoft\Windows NT\Rpc" -DestinationFile "reg-Rpc-Policies.reg.txt"

Invoke-CustomCommand -Command "WHOAMI /all" -DestinationFile "WHOAMI.txt"
Invoke-CustomCommand -Command "netstat -anob" -DestinationFile "netstat.txt"
Invoke-CustomCommand -Command "ipconfig /all" -DestinationFile "ipconfig.txt"
Invoke-CustomCommand -Command "sc.exe query" -DestinationFile "Services-SCQuery.txt"
Invoke-CustomCommand -Command "sc.exe queryex comsysapp" -DestinationFile "ComSysAppConfig.txt"
Invoke-CustomCommand -Command "driverquery /v" -DestinationFile "drivers.txt"
Invoke-CustomCommand -Command "gpresult /h" -DestinationFile "gpresult.html"
Invoke-CustomCommand -Command "gpresult /r" -DestinationFile "gpresult.txt"

if ($WMI_AVAILABLE) {
    CollectSystemInfoWMI 
    tasklist /svc  | out-file -FilePath ($global:resDir + "\tasklist.txt")


    Write-Log "COM Security"
    $Reg = [WMIClass]"\\.\root\default:StdRegProv"
    $DCOMMachineLaunchRestriction = $Reg.GetBinaryValue(2147483650, "software\microsoft\ole", "MachineLaunchRestriction").uValue
    $DCOMMachineAccessRestriction = $Reg.GetBinaryValue(2147483650, "software\microsoft\ole", "MachineAccessRestriction").uValue
    $DCOMDefaultLaunchPermission = $Reg.GetBinaryValue(2147483650, "software\microsoft\ole", "DefaultLaunchPermission").uValue
    $DCOMDefaultAccessPermission = $Reg.GetBinaryValue(2147483650, "software\microsoft\ole", "DefaultAccessPermission").uValue

    # Convert the current permissions to SDDL
    $converter = new-object system.management.ManagementClass Win32_SecurityDescriptorHelper
    "Default Access Permission = " + ($converter.BinarySDToSDDL($DCOMDefaultAccessPermission)).SDDL | Out-File -FilePath ($global:resDir + "\COMSecurity.txt") -Append
    "Default Launch Permission = " + ($converter.BinarySDToSDDL($DCOMDefaultLaunchPermission)).SDDL | Out-File -FilePath ($global:resDir + "\COMSecurity.txt") -Append
    "Machine Access Restriction = " + ($converter.BinarySDToSDDL($DCOMMachineAccessRestriction)).SDDL | Out-File -FilePath ($global:resDir + "\COMSecurity.txt") -Append
    "Machine Launch Restriction = " + ($converter.BinarySDToSDDL($DCOMMachineLaunchRestriction)).SDDL | Out-File -FilePath ($global:resDir + "\COMSecurity.txt") -Append

    # HOTFIXES
    try {
        Write-Log ("Retrieve installed updates from Win32_QuickFixEngineering class.")
        @($Line, 'This file contains the output from WMI class "win32_quickfixengineering"', $Line) | Out-File -FilePath ($global:resDir + "\" + $Prefix + 'WindowsUpdate_Hotfixes.txt')
        Get-CimInstance -ClassName win32_quickfixengineering | Out-File -FilePath ($global:resDir + "\" + "$($Prefix)WindowsUpdate_Hotfixes.txt") -Append
        # Get update id list with wmic, replaced
        # wmic qfe list full /format:texttable >> ($Prefix+"Hotfix-WMIC.txt") 2>> $ErrorFile
    }
    catch { Write-Log ("[$LogPrefixWU] Failed to retrieve installed Updates from Win32_QuickFixEngineering class.") $_ }

    # DTC transactions
    Get-DtcTransactionsStatistics | out-file -FilePath ($global:resDir + "\" + "com_DtcTransactionsStatistics.txt") 
}
else {
    CollectSystemInfoNoWMI 
}


#APPLICATION /SYSTEM LOGS 
Export-EventLog -LogName "Application"
Export-EventLog -LogName "System"

#FLTMC
fltmc filters | out-file -filepath ($global:resDir + "\fltmc_filters.txt")
fltmc volumes | out-file -filepath ($global:resDir + "\fltmc_volumes.txt")
fltmc instances | out-file -filepath ($global:resDir + "\fltmc_instances.txt")


#FEATURE overrides
Export-RegistryKey -KeyPath "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" -DestinationFile "reg-Feature-KIR-Overrides.txt"


#EXPORT REGISTRY KEYS
New-PSDrive -Name "HKCR" -PSProvider Registry -Root "HKEY_CLASSES_ROOT" | Out-Null
Export-RegistryKey -KeyPath "HKCR:\AppID"                    -DestinationFile "com_appid.reg.txt"
Export-RegistryKey -KeyPath "HKCR:\ActivatableClasses"       -DestinationFile "com_activatibles.reg.txt"
Export-RegistryKey -KeyPath "HKCR:\Interface"                -DestinationFile "com_interface.reg.txt"
Export-RegistryKey -KeyPath "HKCR:\CLSID"                    -DestinationFile "com_clsid.reg.txt"
Export-RegistryKey -KeyPath "HKCR:\Wow6432Node\CLSID"        -DestinationFile "com_wow64_clsid.reg.txt"
Export-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\COM3"  -DestinationFile "com3.reg.txt"
Export-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\MSDTC" -DestinationFile "msdtc.reg.txt"


#GET ALL COM CLASS  HKLM:\Software\Classes
Write-Log "GET all COM classes in HKLM:\Software\Classes"
$output = Get-ChildItem HKLM:\Software\Classes -ErrorAction SilentlyContinue | Where-Object {
    $_.PSChildName -match '^\w+\.\w+$' -and (Test-Path -Path "$($_.PSPath)\CLSID")
} | ForEach-Object {
    $clsid = (Get-ItemProperty -Path "$($_.PSPath)\CLSID").'(default)'
    [PSCustomObject]@{
        'CLSID'       = $clsid
        'PSChildName' = $_.PSChildName
    }
} | Format-Table -AutoSize

$output | out-file -FilePath ($global:resDir + "\" + "com_classes.txt") 


#COM+ APPS
# List of properties
$properties = @(
    "AccessChecksLevel",
    "Activation",
    "ApplicationAccessChecksEnabled",
    "ApplicationDirectory",
    "ApplicationProxy",
    "ApplicationProxyServerName",
    "AppPartitionID",
    "Authentication",
    "AuthenticationCapability",
    "Changeable",
    "CommandLine",
    "ConcurrentApps",
    "CreatedBy",
    "CRMEnabled",
    "CRMLogFile",
    "Deleteable",
    "Description",
    "DumpEnabled",
    "DumpOnException",
    "DumpOnFailfast",
    "DumpPath",
    "EventsEnabled",
    "ID",
    "Identity",
    "ImpersonationLevel",
    "IsEnabled",
    "IsSystem",
    "MaxDumpCount",
    "Name",
    "QCAuthenticateMsgs",
    "QCListenerMaxThreads",
    "QueueListenerEnabled",
    "QueuingEnabled",
    "RecycleActivationLimit",
    "RecycleCallLimit",
    "RecycleExpirationTimeout",
    "RecycleLifetimeLimit",
    "RecycleMemoryLimit",
    "Replicable",
    "RunForever",
    "ServiceName",
    "ShutdownAfter",
    "SoapActivated",
    "SoapBaseUrl",
    "SoapMailTo",
    "SoapVRoot",
    "SRPEnabled",
    "SRPTrustLevel"
)


$comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog")
$applications = $comAdmin.GetCollection("Applications") 
$applications.Populate() 

$applications | out-file -FilePath ($global:resDir + "\complus_applications.txt")


$stringBuilder = New-Object System.Text.StringBuilder

foreach ($application in $applications) {
    # Add properties and values to the StringBuilder
    foreach ($p in $properties) {
        [void] $stringBuilder.Append($p.PadRight(30, ' ')) 
        [void] $stringBuilder.Append(":") 
        [void] $stringBuilder.AppendLine($application.Value($p)); 
    }
    [void]$stringBuilder.AppendLine(); 
    [void]$stringBuilder.AppendLine();   

}

$resultString = $stringBuilder.ToString()
$resultString | out-file -FilePath ($global:resDir + "\complus_applications_props.txt") 


$appList = @{}
$applications | ForEach-Object {
    $appList.Add($_.Value("ID"), $_.Name)
}

$appInstances = $comAdmin.GetCollection("ApplicationInstances")
$appInstances.Populate()
$appInstanceList = @{}
$appProcessList = @{}
$appInstances | ForEach-Object {
    $appValue = $_.Value("Application")
    $ProcessID = $_.Value("ProcessID") 
    $appInstanceList.Add($appValue, $appList[$appValue])
    $appProcessList.Add($appValue, $ProcessID)
}

$output = $appList.Keys | ForEach-Object {
    New-Object PSObject -Property @{
        "Name"    = $appList[$_]
        "ID"      = $_
        "Running" = $appInstanceList.ContainsKey($_)
        "PID"     = $appProcessList[$_]
    }
}

$output | out-file -FilePath ($global:resDir + "\" + "complus_appInstances.txt") 



$output = foreach ($AppObject in $applications) {
    "`nApplication  $($appObject.key)   $($appObject.Name)    ID: $($appObject.Value("Identity"))"
    $Components = $applications.GetCollection("Components", $AppObject.Key) 
    $Components.populate()
    $components | foreach-object {
        "Component    $($_.key)   $($_.Name)" }
}

$output | out-file -FilePath ($global:resDir + "\" + "complus_components.txt") 


# DLLHOST DUMPS 
Write-Log "Collecing the dumps of dllhost.exe processes"
if ($WMI_AVAILABLE) {
    $dllhosts = New-Object 'System.Collections.Generic.Dictionary[int,String]'
    $proc = ExecQuery -Namespace "root\cimv2" -Query "select Name, ProcessId,  CommandLine from Win32_Process Where Name LIKE 'dllhost%'"
    foreach ($p in $proc) {
        $g = Get-GUIDFromInputString $p.CommandLine
        $dllhosts.Add($p.ProcessId, $g); 
    }

    if ($dllhosts.Count -gt 0) {
        foreach ($appPID in $dllhosts.Keys) {
            $guid = $dllhosts[$appPID]; 
            Write-Host "Dump -> $appPID $guid" 
            $filename = "DllHost_" + $guid 
            CreateProcDump $appPID $global:resDir $filename
        }
    }
    else {
        Write-Log "No dllhost.exe processes found"
    }
}
else {
    # IN CASE NO WMI 
    # DUMP OF DLLHOSTs 
    $list = get-process -Name "dllhost" -ErrorAction SilentlyContinue 2>>$global:errfile
    if (($list | Measure-Object).count -gt 0) {
        foreach ($proc in $list) {
            Write-Log ("Found dllhost.exe with PID " + $proc.Id)

            CreateProcDump $proc.id $global:resDir
        }
    } 
    else {
        Write-Log "No dllhost.exe processes found"
    }
}

# WINMGMT DUMP 
Write-Log "Collecting dump of the svchost process hosting the WinMgmt service"
$pidsvcWmi = FindServicePid "winmgmt"
if ($pidsvcWmi) {
    Write-Log "Found the PID using FindServicePid"
    CreateProcDump $pidsvcWmi $global:resDir "svchost-WinMgmt"
}
else {
    Write-Log "Cannot find the PID using FindServicePid, looping through processes..."
    $list = Get-Process
    $found = $false
    if (($list) -and ($list.Count -gt 0)) {
        foreach ($proc in $list) {
            $prov = Get-Process -Id $proc.id -Module -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq "wmisvc.dll" } 
            if (($prov) -and ($prov.Count -gt 0)) {
                Write-Log "Found the PID having wmisvc.dll loaded"
                CreateProcDump $proc.Id $global:resDir "svchost-WinMgmt"
                $found = $true
                break
            }
        }
    }
    if (-not $found) {
        Write-Log "Cannot find any process having wmisvc.dll loaded, probably the WMI service is not running"
    }
}

# RPCSS & DCOMLAUNCH DUMP
Write-Log "Collecting dump of the svchost process hosting the RpcSs/EptMapper & DcomLaunch services"
$pidsvcRpcSs = FindServicePid "RpcSs"
$pidsvcDcomLaunch = FindServicePid "DcomLaunch"
if ($pidsvcRpcSs -and $pidsvcDcomLaunch) {
    Write-Log "Found the PIDs using FindServicePid"
    CreateProcDump $pidsvcRpcSs $global:resDir "RpcSs-EptMapper"
    CreateProcDump $pidsvcDcomLaunch $global:resDir "DcomLaunch"
}
elseif ($WMI_AVAILABLE) {
    $RpcSs = Get-CimInstance -Class Win32_Service -Filter "Name LIKE 'rpcss'"
    if ($RpcSs) {
        CreateProcDump $RpcSs.ProcessId $global:resDir "RpcSs"
    }
    else {
        Write-Log "Unable to find the RpcSs service."
    }

    $DcomLaunch = Get-CimInstance -Class Win32_Service -Filter "Name LIKE 'DcomLaunch'"
    if ($DcomLaunch) {
        CreateProcDump $DcomLaunch.ProcessId $global:resDir "DcomLaunch"
    }
    else {
        Write-Log "Unable to find the DcomLaunch service."
    }
}
else {
    Write-Log "Cannot find the PIDs using FindServicePid, looping through processes..."
    $list = Get-Process
    $found = $false
    if (($list) -and ($list.Count -gt 0)) {
        foreach ($proc in $list) {
            $prov = Get-Process -Id $proc.Id -Module -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq "rpcss.dll" } 
            if (($prov) -and ($prov.Count -gt 0)) {
                Write-Log "Found PID $($proc.Id) having rpcss.dll loaded, getting dump."
                CreateProcDump $proc.Id $global:resDir "RpcSs-DLL"
                $found = $true
            }
        }
    }
    if (-not $found) {
        Write-Log "Cannot find any process having rpcss.dll loaded, probably the services are not running."
    }
}


# EVENTSYSTEM DUMP 
Write-Log "Collecting dump of the svchost process hosting the COM+ Event System service"
$pidsvcEvtSystem = FindServicePid "EventSystem"
if ($pidsvcWmi) {
    Write-Log "Found the PID using FindServicePid."
    CreateProcDump $pidsvcEvtSystem $global:resDir "EventSystem"
}
elseif ($WMI_AVAILABLE) {
    $proc = Get-CimInstance -Class Win32_Service -Filter "Name LIKE 'EventSystem'"
    if ($proc) {
        CreateProcDump $proc.ProcessId $global:resDir "EventSystem"
    }
}
else {
    Write-Log "Couldn't get dump of EventSystem service."
}


# COPY SYSTEM COM DUMPS 
$sourceFolder = "$env:SystemRoot\system32\com\dmp"
# Check if the source folder exists & it's not empty
if ((Test-Path $sourceFolder) -and (Get-ChildItem $sourceFolder)) {
    # Check if the destination folder exists, and create it if not
    if (-not (Test-Path $($global:resDir + "\comdumps"))) {
        New-Item -ItemType Directory -Path $($global:resDir + "\comdumps") -Force | Out-Null
    }
    # Copy files from the source to the destination
    Copy-Item -Path "$sourceFolder\*" -Destination $($global:resDir + "\comdumps")  -Force
    Write-Log "System Com Dump Files copied successfully."
}
else {
    Write-Log "System Com Dump folder does not exist or it exists but it's empty."
}

# Wait for MSINFO to finish, if not already, as sometimes it can take a long time. Don't wait for more than 2 minutes though.
Write-Log "Waiting for msinfo32 collection if not already finished..."
Wait-Process msinfo32 -Timeout 120 -ErrorAction SilentlyContinue

#DIAGNOSTICS 
# from WMI-RPC-DCOM-Diag.ps1 by Marius Porcolean (maporcol)
Write-Host "
#####################################################################
############################ DIAG START #############################
#####################################################################
"

# Check OS version & get IPs
$OSVer = [environment]::OSVersion.Version.Major + [environment]::OSVersion.Version.Minor * 0.1
if ($OSVer -gt 6.1) {

    $versionRegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    Write-LogMessage "Host: $($env:COMPUTERNAME)"
    Write-LogMessage "Running on: $($versionRegKey.ProductName)"
    Write-LogMessage "Current build number: $($versionRegKey.CurrentBuildNumber).$($versionRegKey.UBR)"
    Write-LogMessage "Build details: $($versionRegKey.BuildLabEx)"

    # TODO - try to determine when the last CU was installed...not the best option...
    # tried getting the last write time of the build number in the registry, but that's not possible... 
    # can only get a LastWriteTime for a regkey, not for a regvalue
    # https://devblogs.microsoft.com/scripting/use-powershell-to-access-registry-last-modified-time-stamp/
    $xmlQuery = @'
    <QueryList>
        <Query Id="0" Path="Setup">
            <Select Path="Setup">*[System[(EventID=2)]][UserData[CbsPackageChangeState[(Client='UpdateAgentLCU' or Client='WindowsUpdateAgent') and (ErrorCode='0x0')]]]</Select>
        </Query>
    </QueryList>
'@
    $lastSuccessfulCU = Get-WinEvent -MaxEvents 1 -FilterXml $xmlQuery  -ErrorAction SilentlyContinue
    if ($lastSuccessfulCU) {
        if ($lastSuccessfulCU.TimeCreated -le ((Get-Date).AddDays(-90))) {
            Write-LogMessage -Type Warning "This device looks like it may not have had cumulative updates installed recently. Check current build number ($($versionRegKey.UBR)) vs the build number in the latest KBs for this OS."
        }
        Write-LogMessage "The most recent successfully installed cumulative update was $($lastSuccessfulCU.Properties[0].Value), $(((Get-Date) - $lastSuccessfulCU.TimeCreated).Days) days ago @ $($lastSuccessfulCU.TimeCreated)."
    }
    else {
        Write-LogMessage -Type Warning "Could not detect any successful cumulative update installation events. Check current build number ($($versionRegKey.UBR)) vs the build number in the latest KBs for this OS."
    }

    $psver = $PSVersionTable.PSVersion.Major.ToString() + $PSVersionTable.PSVersion.Minor.ToString()
    if ($psver -lt "51") {
        Write-LogMessage -Type Warning "Windows Management Framework version $($PSVersionTable.PSVersion.ToString()) is no longer supported"
    }
    else { 
        Write-LogMessage "Windows Management Framework version is $($PSVersionTable.PSVersion.ToString())"
    }
    Write-LogMessage "Running PowerShell build $($PSVersionTable.BuildVersion.ToString())"

    $iplist = Get-NetIPAddress
    Write-LogMessage "IP addresses of this machine: $(foreach ($ip in $iplist) {$ip.ToString() +' |'})"
}
else {
    Write-LogMessage -Type Warning "This is a legacy OS, please consider updating to a newer supported version."
}

Write-LogMessage "-------------------------"
Write-LogMessage "Checking domain / workgroup settings..."

# Check if machine is part of a domain or not
$computerSystem = Get-CimInstance -ClassName "Win32_ComputerSystem"
switch ($computerSystem.DomainRole) {
    0 { $role = "Standalone Workstation" }
    1 { $role = "Member Workstation" }
    2 { $role = "Standalone Server" }
    3 { $role = "Member Server" }
    4 { $role = "Backup Domain Controller" }
    5 { $role = "Primary Domain Controller" }
    Default { $role = "Unknown" }
}
if ($computerSystem.PartOfDomain) {
    Write-LogMessage "The machine is part of domain: '$($computerSystem.Domain)', having the role of '$($role)'."

    # TODO - more checks for domain joined machines

}
else {
    Write-LogMessage -Type Warning "The machine is not joined to a domain, it is a '$($role)'."

    # TODO - more checks for non-domain joined (WORKGROUP) machines

}

Write-LogMessage "-------------------------"
Write-LogMessage "Checking services..."

# check WMI, RPCSS, DcomLaunch services
$services = Get-Service EventSystem, COMSysApp, RPCSS, RpcEptMapper, DcomLaunch, Winmgmt
if ($services) {
    foreach ($service in $Services) {
        $msg = "The '$($service.DisplayName)' service is $($service.Status)."
        if ($service.Status -eq 'Running') {
            Write-LogMessage -Type Pass $msg
        }
        else {
            Write-LogMessage -Type Error $msg
        }
        if (($service.Name -eq 'COMSysApp') -and ($service.StartType -ne 'Manual')) {
            Write-LogMessage -Type Warning "The service also does not have its default StartupType. Default: Manual. Current setting: $($service.StartType)."
        }
        elseif (($service.Name -ne 'COMSysApp') -and ($service.StartType -ne 'Automatic')) {
            Write-LogMessage -Type Warning "The service also does not have its default StartupType. Default: Automatic. Current setting: $($service.StartType)."
        }
    }
}
else {
    Write-LogMessage -Type Error "Could not check the status of the services, please look into this!"
}   


Write-LogMessage "-------------------------"
Write-LogMessage "Checking COM+ settings..."

# Check if COM+ is on
$enableComPlus = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\COM3").'Com+Enabled'
if ([string]::IsNullOrEmpty($enableComPlus)) {
    Write-LogMessage -Type Warning "Could not check COM+, please check manually @ HKLM:\SOFTWARE\Microsoft\COM3."
}
else {
    if ($enableComPlus -eq 1) {
        Write-LogMessage -Type Pass "COM+ is enabled."
    }
    elseif ($enableComPlus -eq 0) {
        Write-LogMessage -Type Error "COM+ is NOT enabled."
    }
}

# Check if COM+ remote access is on
$remoteComPlus = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\COM3").RemoteAccessEnabled
if ([string]::IsNullOrEmpty($remoteComPlus)) {
    Write-LogMessage -Type Warning "Could not check COM+ remote access, please check manually @ HKLM:\SOFTWARE\Microsoft\COM3."
}
else {
    if ($remoteComPlus -eq 1) {
        Write-LogMessage -Type Warning "COM+ remote access is enabled. By default it is off."
    }
    elseif ($remoteComPlus -eq 0) {
        Write-LogMessage -Type Pass "COM+ remote access is not enabled. This is ok, by default it is off."
    }
}


Write-LogMessage "-------------------------"
Write-LogMessage "Checking RPC settings..."

# Check if the Restrict Unauthenticated RPC clients policy is on or not
$restrictRpcClients = (Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Rpc" -ErrorAction SilentlyContinue).RestrictRemoteClients
if ([string]::IsNullOrEmpty($restrictRpcClients)) {
    Write-LogMessage -Type Pass "RPC restrictions via policy are not in place."
}
else {
    switch ($restrictRpcClients) {
        0 { Write-LogMessage "The RPC restriction policy is set to 'None', so all connections are allowed." }
        1 { Write-LogMessage "The RPC restriction policy is set to 'Authenticated', so only Authenticated RPC Clients are allowed. Exemptions are granted to interfaces that have requested them." }
        2 { Write-LogMessage -Type Warning "The RPC restriction policy is set to 'Authenticated without exceptions', so only Authenticated RPC Clients are allowed, with NO exceptions. This is known to cause on the client some very tricky to investigate 'access denied' errors." }
        Default { Write-LogMessage -Type Error "The RPC restriction policy seems to be present, but its value seems to be wrong. It should be 0, 1 or 2, but is actually $($restrictRpcClients)." }
    }
}


# Check if RPC Endpoint Mapper Client Authentication is on or not
$authEpResolution = (Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Rpc" -ErrorAction SilentlyContinue).EnableAuthEpResolution
if (([string]::IsNullOrEmpty($authEpResolution)) -or ($authEpResolution -eq 0)) {
    Write-LogMessage -Type Pass "RPC Endpoint Mapper Client Authentication is not configured or disabled."
}
elseif ($authEpResolution -eq 1) {
    Write-LogMessage -Type Warning "RPC Endpoint Mapper Client Authentication is enabled, which may cause some issues with applications/components that do not know how to handle this."
}

# Check internet settings for RPC to see if there's a restricted port range
$rpcPortsRestriction = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Rpc\Internet" -ErrorAction SilentlyContinue).UseInternetPorts
if (([string]::IsNullOrEmpty($rpcPortsRestriction)) -or ($rpcPortsRestriction -eq "N")) {
    Write-LogMessage -Type Pass "RPC ports are not restricted."
}
elseif ($rpcPortsRestriction -eq "Y") {
    $rpcPorts = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Rpc\Internet" -ErrorAction SilentlyContinue).Ports
    Write-LogMessage -Type Warning "RPC ports are restricted. This may cause issues with RPC/DCOM connections. The usable port range is defined to '$($rpcPorts.ToString())'."
}

# Check actual dynamic port range
$intSettings = Get-NetTCPSetting -SettingName Internet
if ($null -eq $intSettings) {
    Write-LogMessage -Type Warning "The Internet TCP dynamic port range could not be read, please have a close look."
}
elseif ($intSettings.DynamicPortRangeStartPort -eq 49152 -and $intSettings.DynamicPortRangeNumberOfPorts -eq 16384) {
    Write-LogMessage -Type Pass "The Internet TCP dynamic port range is the default."
}
else {
    Write-LogMessage -Type Warning "The Internet TCP dynamic port range is NOT the default, please have a closer look."
}


Write-LogMessage "-------------------------"
Write-LogMessage "Checking DCOM settings..."

# Check if DCOM is enabled 
$ole = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Ole"
if ($ole.EnableDCOM -eq "Y") {
    Write-LogMessage -Type Pass "DCOM is enabled."
}
else {
    Write-LogMessage -Type Error "DCOM is NOT enabled! Check the settings."
}

# Check default DCOM Launch & Activation / Access permissions
$defaultPermissions = @(
    @{
        name   = 'Everyone'
        short  = 'WD'
        sid    = 'S-1-1-0'
        launch = 'A;;CCDCSW;;;' 
        access = 'A;;CCDCLC;;;'
    }
    @{
        name   = 'Administrators'
        short  = 'BA'
        sid    = 'S-1-5-32-544'
        launch = 'A;;CCDCLCSWRP;;;'
    }
    @{
        name   = 'Distributed COM Users'
        short  = 'CD'
        sid    = 'S-1-5-32-562'
        launch = 'A;;CCDCLCSWRP;;;'
        access = 'A;;CCDCLC;;;'
    }
    @{
        name   = 'Performance Log Users'
        short  = 'LU'
        sid    = 'S-1-5-32-559'
        launch = 'A;;CCDCLCSWRP;;;'
        access = 'A;;CCDCLC;;;'
    }
    @{
        name   = 'All Application Packages'
        short  = 'AC'
        sid    = 'S-1-15-2-1'
        launch = 'A;;CCDCSW;;;'
        access = 'A;;CCDC;;;'
    }
)

# Get current permissions from registry
$launchRestriction = (([wmiclass]"Win32_SecurityDescriptorHelper").BinarySDToSDDL($ole.MachineLaunchRestriction)).SDDL
$accessRestriction = (([wmiclass]"Win32_SecurityDescriptorHelper").BinarySDToSDDL($ole.MachineAccessRestriction)).SDDL

# Compare current vs default permissions
foreach ($permission in $defaultPermissions.GetEnumerator()) {
    if ($permission.launch) {
        if ($launchRestriction.Contains($permission.launch + $permission.short) -or $launchRestriction.Contains($permission.launch + $permission.sid)) {
            Write-LogMessage -Type Pass "The '$($permission.name)' group is present in Launch & Activation with default permissions."
        }
        else {
            Write-LogMessage -Type Error "The '$($permission.name)' group is NOT present in Launch & Activation with default permissions, please verify."
        }
    }

    if ($permission.access) {
        if ($accessRestriction.Contains($permission.access + $permission.short) -or $accessRestriction.Contains($permission.access + $permission.sid)) {
            Write-LogMessage -Type Pass "The '$($permission.name)' group is present in Access with default permissions."
        }
        else {
            Write-LogMessage -Type Error "The '$($permission.name)' group is NOT present in Access with default permissions, please verify."
        }
    }

    $localGroup = Get-LocalGroup -SID $permission.sid -ErrorAction SilentlyContinue
    if ($localGroup -and !($localGroup.Name -eq $permission.name)) {
        Write-LogMessage -Type Warning "The name of the group is not the original English one (current name: '$($localGroup.Name)'). This is usually because the OS is in a different language & it can cause confusion in some situations, so please be aware / keep this in mind."
    }
}

# Check enabled DCOM protocols
$protocols = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Rpc" -ErrorAction SilentlyContinue).'DCOM Protocols'
if ([string]::IsNullOrEmpty($protocols)) {
    Write-LogMessage -Type Warning "No protocols specified for DCOM."
}
else {
    Write-LogMessage "Enabled protocols: $($protocols)"
    if ($protocols.Contains("ncacn_ip_tcp")) {
        Write-LogMessage -Type Pass "The list of enabled protocols contains 'ncacn_ip_tcp', which should be present by default."
    }
    else {
        Write-LogMessage -Type Error "The list of enabled protocols does NOT contain 'ncacn_ip_tcp', which should be present by default."
    }
}

# Check DcomScmRemoteCallFlags
if ([string]::IsNullOrEmpty($ole.DCOMSCMRemoteCallFlags)) {
    Write-LogMessage -Type Pass "DCOMSCMRemoteCallFlags is not configured in the registry and by default it should not be there. That is ok."
}
else {
    Write-LogMessage -Type Warning "DCOMSCMRemoteCallFlags is configured in the registry with value '$($ole.DCOMSCMRemoteCallFlags)', while it should not be there by default. This does not necessarily mean there is a problem, nevertheless, please check the documentation:`nhttps://learn.microsoft.com/en-us/windows/win32/com/dcomscmremotecallflags"
}

# Check LegacyAuthenticationLevel
if ([string]::IsNullOrEmpty($ole.LegacyAuthenticationLevel)) {
    Write-LogMessage -Type Pass "LegacyAuthenticationLevel is not configured in the registry, so the default is used. That is ok."
}
else {
    Write-LogMessage -Type Warning "LegacyAuthenticationLevel is configured in the registry with value '$($ole.LegacyAuthenticationLevel)', while it should not be there by default. This should not be a problem, though, as we are raising the authentication level in the OS anyway, due to the DCOM hardening. Nevertheless, please check the documentation:`nhttps://learn.microsoft.com/en-us/windows/win32/com/legacyauthenticationlevel"
}

# Check LegacyImpersonationLevel
if ([string]::IsNullOrEmpty($ole.LegacyImpersonationLevel) -or ($ole.LegacyImpersonationLevel -eq 2)) {
    Write-LogMessage -Type Pass "LegacyImpersonationLevel is using the default value. That is ok."
}
else {
    Write-LogMessage -Type Warning "LegacyImpersonationLevel is configured in the registry with value '$($ole.LegacyImpersonationLevel)', while it should be '2' by default. Please check the documentation:`nhttps://learn.microsoft.com/en-us/windows/win32/com/legacyimpersonationlevel"
}

# Check DCOM hardening registry keys
$requireIntegrityAuthLevel = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Ole\AppCompat" -ErrorAction SilentlyContinue).RequireIntegrityActivationAuthenticationLevel
if ([string]::IsNullOrEmpty($requireIntegrityAuthLevel)) {
    Write-LogMessage -Type Pass "RequireIntegrityActivationAuthenticationLevel is not set in the registry. That is ok."
}
else {
    Write-LogMessage -Type Warning "RequireIntegrityActivationAuthenticationLevel is set in the registry to '$requireIntegrityAuthLevel'. Check info in public KB5004442.`nhttps://support.microsoft.com/en-us/topic/kb5004442-manage-changes-for-windows-dcom-server-security-feature-bypass-cve-2021-26414-f1400b52-c141-43d2-941e-37ed901c769c"
}

$raiseAuthLevel = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Ole\AppCompat" -ErrorAction SilentlyContinue).RaiseActivationAuthenticationLevel
if ([string]::IsNullOrEmpty($raiseAuthLevel)) {
    Write-LogMessage -Type Pass "RaiseActivationAuthenticationLevel is not set in the registry. That is ok."
}
else {
    Write-LogMessage -Type Warning "RaiseActivationAuthenticationLevel is set in the registry to '$raiseAuthLevel'. Check info in public KB5004442.`nhttps://support.microsoft.com/en-us/topic/kb5004442-manage-changes-for-windows-dcom-server-security-feature-bypass-cve-2021-26414-f1400b52-c141-43d2-941e-37ed901c769c"
}

$disableHardeningLogging = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Ole\AppCompat" -ErrorAction SilentlyContinue).DisableAuthenticationLevelHardeningLog
if ([string]::IsNullOrEmpty($disableHardeningLogging) -or ($disableHardeningLogging -eq 0)) {
    Write-LogMessage -Type Pass "Hardening related logging is turned on. That is ok, it should be on by default."
}
else {
    Write-LogMessage -Type Error "Hardening related logging is turned off. This is a problem, because you may have failing DCOM calls which you are not aware of. Please turn the logging back on by removing the DisableAuthenticationLevelHardeningLog entry from regkey 'HKLM:\SOFTWARE\Microsoft\Ole\AppCompat'."
}

# Check for any DCOM hardening events (IDs 10036/10037/10038)
$sysEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ID      = 10036, 10037, 10038
} -ErrorAction SilentlyContinue
if (!$sysEvents) {
    Write-LogMessage -Type Pass "Did not detect any DCOM hardening related events (10036, 10037, 10038) in the System log."
}
else {
    if ($sysEvents.Id.Contains(10036)) {
        Write-LogMessage -Type Warning "Events with ID 10036 detected in the System event log. This device seems to be acting as a DCOM server & is rejecting some incoming connections, please check."
        
        # Print the most recent 5 of them
        Write-LogMessage "Here are the most recent ones:"
        foreach ($event in ($sysEvents | Where-Object { $_.Id -eq 10036 } | Select-Object -First 5)) {
            Write-LogMessage "$($event.TimeCreated) - $($event.Message)"
        }
    }
    if ($sysEvents.Id.Contains(10037)) {
        Write-LogMessage -Type Warning "Events with ID 10037 detected in the System event log. This device seems to be acting as a DCOM client with explicitly set auth level & failing, please check."
          
        # Print the most recent 5 of them
        Write-LogMessage "Here are the most recent ones:"
        foreach ($event in ($sysEvents | Where-Object { $_.Id -eq 10037 } | Select-Object -First 5)) {
            Write-LogMessage "$($event.TimeCreated) - $($event.Message)"
        }
    }
    if ($sysEvents.Id.Contains(10038)) {
        Write-LogMessage -Type Warning "Events with ID 10038 detected in the System event log. This device seems to be acting as a DCOM client with default auth level & failing, please check."
    
        # Print the most recent 5 of them
        Write-LogMessage "Here are the most recent ones:"
        foreach ($event in ($sysEvents | Where-Object { $_.Id -eq 10038 } | Select-Object -First 5)) {
            Write-LogMessage "$($event.TimeCreated) - $($event.Message)"
        }
    }
}

Write-Host "
#####################################################################
############################# DIAG END ##############################
#####################################################################
"
# SIG # Begin signature block
# MIInzgYJKoZIhvcNAQcCoIInvzCCJ7sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIYgytwihJslxM
# okPTbJBoTaJKo5mhC/mf+rOGm8VlgaCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEID7j
# W9BVpmu7o2kCSCX55tsLImT+MV/oXHBm6L5sONa1MEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAQFhLDr/H/RjAxH4j4yoDoO4AJI7t8qPO7FZ7
# 367tDbuegYc9MsonbgpMsaGCfBs5+Ui+R3ZZ1BwTXWqW84/yFtr6jyeEhWQeQ2EJ
# skazbBfSHx9+pSrmiPzu/3670jfJbLzG5UcxnjudL42us0A5wMHSg1SdGy13UIk4
# xw1G2LIWq3oW5UDM55BTjpDTGWBOG1/POhiwElkqEpj/wIl9i/tQam6y5khLYv1R
# oB7JOcpE4F8uxXYkUNHNf08dq88499yXp+0TGK4da/4pksr9YN+7E4B5DYn/GDZE
# 40ofB8cBZqjafMupT5OxfTNXrdWyuUuyKOWMgO27eftXlqpBgKGCFykwghclBgor
# BgEEAYI3AwMBMYIXFTCCFxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFZBgsqhkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCAJxXtW5+v8lZL77Qv5nlj8DnqWh00ZPpjP
# p7vu2eAz6AIGZlce/FxCGBMyMDI0MDYxMjE1MDA0MC4zODdaMASAAgH0oIHYpIHV
# MIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOjNCRDQtNEI4MC02OUMzMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHlj2rA
# 8z20C6MAAQAAAeUwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwHhcNMjMxMDEyMTkwNzM1WhcNMjUwMTEwMTkwNzM1WjCB0jELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9z
# b2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjozQkQ0LTRCODAtNjlDMzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKl7
# 4Drau2O6LLrJO3HyTvO9aXai//eNyP5MLWZrmUGNOJMPwMI08V9zBfRPNcucreIY
# SyJHjkMIUGmuh0rPV5/2+UCLGrN1P77n9fq/mdzXMN1FzqaPHdKElKneJQ8R6cP4
# dru2Gymmt1rrGcNe800CcD6d/Ndoommkd196VqOtjZFA1XWu+GsFBeWHiez/Pllq
# cM/eWntkQMs0lK0zmCfH+Bu7i1h+FDRR8F7WzUr/7M3jhVdPpAfq2zYCA8ZVLNgE
# izY+vFmgx+zDuuU/GChDK7klDcCw+/gVoEuSOl5clQsydWQjJJX7Z2yV+1KC6G1J
# VqpP3dpKPAP/4udNqpR5HIeb8Ta1JfjRUzSv3qSje5y9RYT/AjWNYQ7gsezuDWM/
# 8cZ11kco1JvUyOQ8x/JDkMFqSRwj1v+mc6LKKlj//dWCG/Hw9ppdlWJX6psDesQu
# QR7FV7eCqV/lfajoLpPNx/9zF1dv8yXBdzmWJPeCie2XaQnrAKDqlG3zXux9tNQm
# z2L96TdxnIO2OGmYxBAAZAWoKbmtYI+Ciz4CYyO0Fm5Z3T40a5d7KJuftF6CTocc
# c/Up/jpFfQitLfjd71cS+cLCeoQ+q0n0IALvV+acbENouSOrjv/QtY4FIjHlI5zd
# JzJnGskVJ5ozhji0YRscv1WwJFAuyyCMQvLdmPddAgMBAAGjggFJMIIBRTAdBgNV
# HQ4EFgQU3/+fh7tNczEifEXlCQgFOXgMh6owHwYDVR0jBBgwFoAUn6cVXQBeYl2D
# 9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
# LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQAD
# ggIBADP6whOFjD1ad8GkEJ9oLBuvfjndMyGQ9R4HgBKSlPt3pa0XVLcimrJlDnKG
# gFBiWwI6XOgw82hdolDiMDBLLWRMTJHWVeUY1gU4XB8OOIxBc9/Q83zb1c0RWEup
# gC48I+b+2x2VNgGJUsQIyPR2PiXQhT5PyerMgag9OSodQjFwpNdGirna2rpV23EU
# wFeO5+3oSX4JeCNZvgyUOzKpyMvqVaubo+Glf/psfW5tIcMjZVt0elswfq0qJNQg
# oYipbaTvv7xmixUJGTbixYifTwAivPcKNdeisZmtts7OHbAM795ZvKLSEqXiRUjD
# YZyeHyAysMEALbIhdXgHEh60KoZyzlBXz3VxEirE7nhucNwM2tViOlwI7EkeU5hu
# dctnXCG55JuMw/wb7c71RKimZA/KXlWpmBvkJkB0BZES8OCGDd+zY/T9BnTp8si3
# 6Tql84VfpYe9iHmy7PqqxqMF2Cn4q2a0mEMnpBruDGE/gR9c8SVJ2ntkARy5Sflu
# uJ/MB61yRvT1mUx3lyppO22ePjBjnwoEvVxbDjT1jhdMNdevOuDeJGzRLK9HNmTD
# C+TdZQlj+VMgIm8ZeEIRNF0oaviF+QZcUZLWzWbYq6yDok8EZKFiRR5otBoGLvaY
# FpxBZUE8mnLKuDlYobjrxh7lnwrxV/fMy0F9fSo2JxFmtLgtMIIHcTCCBVmgAwIB
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
# aGFsZXMgVFNTIEVTTjozQkQ0LTRCODAtNjlDMzElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA942iGuYFrsE4wzWD
# d85EpM6RiwqggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOoUES0wIhgPMjAyNDA2MTIyMDIxMDFaGA8yMDI0MDYx
# MzIwMjEwMVowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6hQRLQIBADAHAgEAAgIU
# rDAHAgEAAgIR1DAKAgUA6hVirQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
# AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GB
# AAkJnNlVwIcwLlfwYDaM7JQl1ODL52UAsG2eVJTcreZyVF7wZk37i/8dPes9M8s+
# E9BB8Xyi4xIp1V2SauyU9zrc53q1BzmIxC22ulVMy6E/BBhyXlIRBHXAJ3/x5VBr
# yJbglcY2iAKjO9zlKnw60BcsNm87QjAhZDaZZqaJyrtfMYIEDTCCBAkCAQEwgZMw
# fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHlj2rA8z20C6MAAQAA
# AeUwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAvBgkqhkiG9w0BCQQxIgQgdt+cYXhnoLFxdkY7zM5vgNJ8WGALEpPNxVWwvfoA
# ZLIwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAVqdP//qjxGFhe2YboEXeb
# 8I/pAof01CwhbxUH9U697TCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAAB5Y9qwPM9tAujAAEAAAHlMCIEIPrz64f8HITj+p5XWojP294P
# 8KgaLUeQajL16WZxd4DMMA0GCSqGSIb3DQEBCwUABIICAH7e5SMTdj3zfu77B/Yq
# 182T4hQthyNGjDxOV1No/qyPsOhwOgHOoI0CkeVRK4hS0qmsn4n3Eu9ImKWy4MiG
# 9bKL/hgIWkSPLh6iepeuqtmtUQnGFY9B9ghKfCaO/jMKYpaKEyfzmsgpZjgHtCoo
# NK4oxlZOTCWNtC7zQG4GdHnFWhh+yWBcGT4MI04xI7V/98/LxjdGE7kUwomaJ8th
# BzSvzzxxq0B4RqwFjrQdw+rId5sqL2wxPMmJD/+FT6Rw4RJe8QME0v5fjIH9MXC2
# ZwmeNlomjIcw4FIECkTUi6wSZh4obq/RPJE/zVxavBnqkT4cU8bFa3l/CaCooETo
# 9yI9MppaKc/S01/LmNMsDHrXujR8vHeG5M/v6VAmswyzq0RWD8Y3sQXchfe9igV2
# IApS8CoTGOTEfk3Oyzd37+cpXiAIljgZsFuGsVV39cefmMlSfRgMML/ozjGEgbcS
# q7m6bCn95go4Fj7+Y5RoZcPYFNJGoYenECMt29G5S5//TsrLBYaoi6wG5iuVAe+l
# LBOWlb5OK/VqfAcp/d2z8pcz1PVC1YfSGlWiDUjL9eToPRExNfwkd9Iqg9p//7Rl
# eoP3hSBLUtEk2IRf1qcjWBqfY5d6OmwvByHjQYQOvcaL5VQ7+XiwzBWIVjSJ3xEO
# l6HEP6GIXEyY3ZQdLfASzGR0
# SIG # End signature block
