<#
    .SYNOPSIS
    Microsoft CSS ADPerf data collection script.
    .DESCRIPTION
    The Microsoft CSS ADPerf data collection scripts are used to diagnose Active Directory related issues on Domain Controllers and member servers.

    The output of this data collection will be in C:\ADPerfData

    .PARAMETER Scenario
    Select one of the following scenarios. (0 - 10)
    0: Interactive
    1: High CPU
    2: High CPU Trigger Start
    3: High Memory
    4: High Memory Trigger Start
    5: High LSASS handles
    6: Out of ATQ threads on Domain Controller (always trigger start)
    7: Source of DC workload
    8: Baseline performance (5 minutes)
    9: Long Term Baseline performance
    10: Stop tracing providers (run this if you previously cancelled before script completion)


    .PARAMETER DelayStop
    The number of minutes after the triggered condition has been met that the data collection should stop. (0 - 30)

    If parameter not specified the delay will be 5 minutes in trigger scenarios.
    .PARAMETER Threshold
    The % resource utilization by lsass that will trigger the stop condition. (20 - 100)

    - Used in scenario 2 for CPU threshold.
    - Used in scenario 4 for memory threshold.

    This parameter must be specified in scenario 2 or 4.

    .PARAMETER DumpPreference
    Preferrence for procdump collection. (Full, MiniPlus)
    - Full      : procdump -ma
    - MiniPlus  : procdump -mp

    Use MiniPlus when retrieving Full dumps takes too long. WARNING: You may experience incompleted call stacks with this option.

    .PARAMETER Verbose
    This parameter specifies additional script logging. Not additional data collection

    .PARAMETER NtdsaiTrace
    This parameter specifies wether NTDSAI Etw tracing should run in the scenarios 1 and 3

    .EXAMPLE
    .\ADPerfDataCollection.ps1                                              # Interactive
    .EXAMPLE
    .\ADPerfDataCollection.ps1 -Scenario Cpu                                  # High CPU data collection
    .EXAMPLE
    .\ADPerfDataCollection.ps1 -Scenario MemoryTrigger -DelayStop 5 -Threshold 80    # High Memory Trigger stop at 80% utilization with 5 minute delay
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
Param(
    [ValidateSet("HighCpu", "HighCpuTrigger", "HighMemory", "HighMemoryTrigger", "HighHandle", "ATQ", "Baseline", "BaselineLong", "SDW", "Stop", "Interactive",
        # Including numbers for backwards compat
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "10")]
    [string]$Scenario = "Interactive",
    [ValidateRange(0, 30)]
    [int]$DelayStop = 0,
    [ValidateRange(20, 99)]
    [int]$Threshold = 0,
    [ValidateSet("Full", "MiniPlus")]
    [string]$DumpPreference = "Full",
    [string]$DataPath = "$((Get-Location).Path)\ADPerfData",
    [switch]$AcceptEULA,
    [ValidateSet(
        'DSEVENT', 'JET', 'Core', 'LDAP', 'DRA', 'DBLayer',
        'DSAEXCEPT', 'DRSSERV', 'BATCHBRACKET', 'ATQ', 'JETBACK',
        'NTDSUTIL', 'SAMDS', 'KCC', 'QO', 'INSTALL', 'DSAPI'
    )]
    [ValidateNotNullOrEmpty()]
    [string[]]$NtdsaiTrace
)

try {
    Add-Type @'
    using System;
    using System.Threading;
    using System.Runtime.InteropServices;

    namespace MSDATA
    {
	    public static class UserDump
	    {
		    [DllImport("kernel32.dll")]
		    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, uint dwProcessID);
		    [DllImport("dbghelp.dll", EntryPoint = "MiniDumpWriteDump", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
		    public static extern bool MiniDumpWriteDump(IntPtr hProcess, uint processId, SafeHandle hFile, uint dumpType, IntPtr expParam, IntPtr userStreamParam, IntPtr callbackParam);

		    private enum MINIDUMP_TYPE
		    {
			    MiniDumpNormal = 0x00000000,
			    MiniDumpWithDataSegs = 0x00000001,
			    MiniDumpWithFullMemory = 0x00000002,
			    MiniDumpWithHandleData = 0x00000004,
			    MiniDumpFilterMemory = 0x00000008,
			    MiniDumpScanMemory = 0x00000010,
			    MiniDumpWithUnloadedModules = 0x00000020,
			    MiniDumpWithIndirectlyReferencedMemory = 0x00000040,
			    MiniDumpFilterModulePaths = 0x00000080,
			    MiniDumpWithProcessThreadData = 0x00000100,
			    MiniDumpWithPrivateReadWriteMemory = 0x00000200,
			    MiniDumpWithoutOptionalData = 0x00000400,
			    MiniDumpWithFullMemoryInfo = 0x00000800,
			    MiniDumpWithThreadInfo = 0x00001000,
			    MiniDumpWithCodeSegs = 0x00002000
		    };

            public enum DumpType
            {
                Full,
                MiniPlus
            };

            public static bool GenerateUserDump(uint ProcessID, string dumpPath, string ProcessName, int count, int seconds)
		    {
                string dumpFileName;
                bool Result = false;

			    // 0x1F0FFF = PROCESS_ALL_ACCESS
			    IntPtr ProcessHandle = OpenProcess(0x1F0FFF, false, ProcessID);

			    MINIDUMP_TYPE Flags =
				    MINIDUMP_TYPE.MiniDumpWithFullMemory |
				    MINIDUMP_TYPE.MiniDumpWithFullMemoryInfo |
				    MINIDUMP_TYPE.MiniDumpWithHandleData |
				    MINIDUMP_TYPE.MiniDumpWithUnloadedModules |
				    MINIDUMP_TYPE.MiniDumpWithThreadInfo;

                if(count == 1)
                {
                    dumpFileName = dumpPath + "\\" + ProcessName + "_" + (DateTime.Now).ToString("yyyyMMddHHmmss") + ".dmp";
                    System.IO.FileStream fileStream = System.IO.File.OpenWrite(dumpFileName);
                    if(null == fileStream)
                        return false;
                    Console.WriteLine("Writing " + dumpFileName);
                    Result = MiniDumpWriteDump(ProcessHandle,
						    ProcessID,
						    fileStream.SafeFileHandle,
						    (uint)Flags,
						    IntPtr.Zero,
						    IntPtr.Zero,
						    IntPtr.Zero);
                    if(false == Result)
                        Console.WriteLine("MiniDumpWriteDump failed with " + Marshal.GetLastWin32Error());
                    fileStream.Close();
                }
                else
                {
                    for(int i = 0; i < count; i++)
                    {
                        dumpFileName = dumpPath + "\\" + ProcessName + "_" + (DateTime.Now).ToString("yyyyMMddHHmmss") + "_" + i + ".dmp";
                        System.IO.FileStream fileStream = System.IO.File.OpenWrite(dumpFileName);
                        if(null == fileStream)
                            return false;
                        Console.WriteLine("Writing " + dumpFileName);
                        Result = MiniDumpWriteDump(ProcessHandle,
							    ProcessID,
							    fileStream.SafeFileHandle,
							    (uint)Flags,
							    IntPtr.Zero,
							    IntPtr.Zero,
							    IntPtr.Zero);
                        fileStream.Close();
                        if(false == Result)
                            Console.WriteLine("MiniDumpWriteDump failed with " + Marshal.GetLastWin32Error());
                        Thread.Sleep(seconds * 1000);
                    }
                }

			    return Result;
		    }
	    }
    }
'@
}
catch {
    if ($_.Exception.Message -ne "Cannot add type. The type name 'MSDATA.UserDump' already exists.") {
        throw $_
    }
}

#region Globals

$Script:Version = "2.20241005"
$Script:CurrentOSVersion = [System.Environment]::OSVersion.Version
$Script:ADPerfLog = "ADPerf.log"
$Script:FieldEngineering = "0"
$Script:NetLogonDBFlags = "0"
$Script:ADPerfFolder = $DataPath
$Script:CertDataPath = $null
$Script:CryptoDataPath = $null
$Script:Custom1644 = $false
$Script:CustomADDSUsed = $false
$Script:TriggerScenario = $false
$Script:TriggeredTimerLength = 5
$Script:TriggerThreshold = 50
$Script:Interactive = $false
$Script:IsDC = $false
$Script:CollectPerfCounterName = $null
$Script:CollectLSASSDump = $false
$Script:ComponentStack = New-Object System.Collections.Stack
$Script:ComponentStack.Push("Main")
$Script:SupportedScenarios = (
    "Interactive",
    "HighCpu",
    "HighCpuTrigger",
    "HighMemory",
    "HighMemoryTrigger",
    "HighHandle",
    "ATQ",
    "SDW",
    "Baseline",
    "BaselineLong",
    "Stop"
)

#endregion

#region Helper functions
function Push-Component {
    param(
        [string]$Component
    )
    $Script:ComponentStack.Push($Component)
}

function Pop-Component {
    $Script:ComponentStack.Pop() | Out-Null
}

function Write-Log {
    param(
        [string]$Msg,
        [switch]$IsDebugOutput,
        [ValidateSet("Info", "Error", "Important")]
        [string]$Channel = "Info"
    )

    switch ($Channel) {
        "Info" { $Color = [System.ConsoleColor]::White }
        "Error" { $Color = [System.ConsoleColor]::Yellow }
        "Important" { $Color = [System.ConsoleColor]::Cyan }
    }

    #Print only if both script switch 'Debug' and message ir marked as $IsDebugOutput [$IsDebugOutput needed to print the Component]
    if ($IsDebugOutput) {
        Write-Debug "[$($Script:ComponentStack.Peek())] $Msg"
    }#Always print regular messages
    else {
        Write-Host "[$($Script:ComponentStack.Peek())] $Msg" -ForegroundColor $Color
    }
}

function Invoke-Process {
    param(
        [string]$ProcessName,
        [string]$Arg,
        [switch]$Async,
        [switch]$Silent
    )
    Push-Component "IP"
    Write-Log "Running: `"$ProcessName $Arg`" Async:($Async)" -IsDebugOutput
    $ps = New-Object System.Diagnostics.Process
    $ps.StartInfo.Filename = $ProcessName
    $ps.StartInfo.Arguments = " $Arg"
    $ps.StartInfo.RedirectStandardOutput = $Silent
    $ps.StartInfo.UseShellExecute = $false
    $ps.start() | Out-Null
    if (!$Async) {
        $ps.WaitForExit()
    }
    Pop-Component
    return $ps.ExitCode
}

function Stop-Logman {
    param(
        [string]$SessionName
    )
    Push-Component "SL"
    Write-Log "Running: `"logman.exe stop $SessionName -ets`" " -IsDebugOutput
    Pop-Component
    return Invoke-Process -ProcessName "logman.exe" -Arg "stop $SessionName -ets"
}

function ADPerfMenu {
    Write-Host ""
    Write-Host ""
    Write-Host "============AD Perf Data Collection Tool=============="
    Write-Host "1: High CPU"
    Write-Host "2: High CPU Trigger Start"
    Write-Host "3: High Memory"
    Write-Host "4: High Memory Trigger Start"
    Write-Host "5: High LSASS handles"
    Write-Host "6: Out of ATQ threads on Domain Controller (always trigger start)"
    Write-Host "7: Source of DC workload"
    Write-Host "8: Baseline performance (5 minutes)"
    Write-Host "9: Long Term Baseline performance"
    Write-Host "10: Stop tracing providers (run this if you previously cancelled before script completion)"
    Write-Host "q: Press Q  or Enter to quit"
}

Function ConvertToLocalPerfCounterName {
    [OutputType([Array])]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$PerfCounterList
    )
    Push-Component "PERFCOUNTER"

    # Initialize the hashtable from the registry if we haven't already
    if (!$Script:PerfcounterHashInitialized) {
        Push-Component "PERFCOUNTERINIT"

        $englishNamesReg = Get-ItemPropertyValue "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Perflib\009" -Name Counter
        $localNamesReg = Get-ItemPropertyValue "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage" -Name Counter

        if ($null -eq $englishNamesReg -or $null -eq $localNamesReg) {
            # This should never happen
            Write-Log "Couldn't find the registry keys for the counter names" -Channel "Error"
            Pop-Component
            return $PerfCounterList
        }

        # For english names, use the counter name as the key
        $i = 0
        while ($i -lt ($englishNamesReg.Count - 1)) {
            $counterID = $englishNamesReg[$i++]
            $counterName = $englishNamesReg[$i++]

            #Write-Log "Adding pair: $counterName, $counterID" -IsDebugOutput

            # There were entries where the same name was mapped to different IDs
            # Ignoring the duplicate ones for now
            if ($Script:engNameHashtable.ContainsKey($counterName)) {
                Write-Log "Counter name already exists: $counterName" -IsDebugOutput
                continue
            }
            # Counter name doesn't exist in the hashtable. Add it
            $Script:engNameHashtable.Add($counterName, $counterID)
        }

        # For local names, use the counter ID as the key
        $i = 0
        while ($i -lt ($localNamesReg.Count - 1)) {
            $counterID = $localNamesReg[$i++]
            $counterName = $localNamesReg[$i++]

            # Bug 28308
            # There are scenarios where the same ID can have multiple names.
            # We'll ignore the duplicates for now. May need to reivist this if this causes problems.
            if ($Script:locNameHashtable.ContainsKey($counterID)) {
                Write-Log "Counter ID already exists: $counterID" -IsDebugOutput
                continue
            }
            # Counter ID doesn't exist in the hashtable. Add it
            $Script:locNameHashtable.Add($counterID, $counterName)
        }

        $Script:PerfcounterHashInitialized = $true
        Pop-Component
    }

    $LocalizedCounterSetNameArray = @()
    foreach ($originalCounter in $PerfCounterList) {

        # Parse out the counter name to query on
        $CounterType = 0
        $EnglishCounterName = $originalCounter

        # Case for '<CounterName>(*)\*'
        if ($EnglishCounterName.contains("(*)\*")) {
            $EnglishCounterName = $EnglishCounterName -replace '^\\', '' # Remove first '\'.
            $EnglishCounterName = $EnglishCounterName -replace '\(\*\)\\\*', ''
            $CounterType = 1
        }
        # Case for '<CounterName>(<XXX>*)\*' // ex. \Process(WmiPrvSE*)\Handle
        elseif ($EnglishCounterName -match "\\.*\(.*\*\)\\.*") {
            # Cut out the latter part to combine later
            $Token = $EnglishCounterName -split "\("    # split to "\Process" and "WmiPrvSE*)\Handle"
            $InstanceAndCounterName = "(" + $Token[1]   # (WmiPrvSE*)\Handle

            $EnglishCounterName = $EnglishCounterName -replace '^\\', ''  # Remove first '\'.
            $EnglishCounterName = $EnglishCounterName -replace '\(.*', '' # Remove the part after the counter name
            $CounterType = 2
        }
        # Case for '<CounterName>\*'
        elseif ($EnglishCounterName.contains("\*")) {
            $EnglishCounterName = $EnglishCounterName -replace '^\\', '' # Remove first '\'.
            $EnglishCounterName = $EnglishCounterName -replace '\\\*', ''
            $CounterType = 3
        }
        else {
            Write-Log "Invalid counter set name ($EnglishCounterName) is passed. Ignoring." -Channel "Info"
            continue
        }

        # Look up the counter ID from the english name
        $counterID = $Script:engNameHashtable[$EnglishCounterName]

        if ($null -ne $counterID) {
            # Now find the localized counter name
            $localCounterName = $Script:locNameHashtable[$counterID]

            if ($null -ne $localCounterName) {
                # Converting to localized counter name using counter id.
                #Write-Log "Adding $localCounterName to counter array" -IsDebugOutput
                switch ($CounterType) {
                    1 { $LocalizedCounterSetNameArray += "\" + $localCounterName + "(*)\*" }
                    2 { $LocalizedCounterSetNameArray += "\" + $localCounterName + $InstanceAndCounterName }
                    3 { $LocalizedCounterSetNameArray += "\" + $localCounterName + "\*" }
                }
            }
            else {
                # Coudln't find a localized name. Use the passed in english name
                Write-Log "Couldn't find localized name for `"$EnglishCounterName`". Using English name." -Channel "Info"
                $LocalizedCounterSetNameArray += $originalCounter
            }
        }
        else {
            # Couldn't find the counter in the Perflib\009 registry. Use the passed in English name
            Write-Log "Couldn't find `"$EnglishCounterName`" in the registry. Using English name." -Channel "Info"
            $LocalizedCounterSetNameArray += $originalCounter
        }
    }

    Pop-Component
    return $LocalizedCounterSetNameArray
}

function GetPerformanceCounters {
    param (
        [Parameter()]
        [string]$Name,
        [switch]$All
    )

    if ($null -eq $Script:PerfCountersMap) {
        $perfCountersCommon = ConvertToLocalPerfCounterName(@("\LogicalDisk(*)\*",
                "\Memory\*",
                "\Cache\*",
                "\Network Interface(*)\*",
                "\DirectoryServices(*)\*",
                "\Netlogon(*)\*",
                "\Database(lsass)\*",
                "\Paging File(*)\*",
                "\PhysicalDisk(*)\*",
                "\Processor(*)\*",
                "\Processor Information(*)\*",
                "\Process(*)\*",
                "Redirector\*",
                "\Server\*",
                "\System\*",
                "\Server Work Queues(*)\*",
                "\DC Locator (Client)(*)\*",
                "\DC Locator (DC)\*",
                "\DC Locator (Netlogon)(*)\*",
                "\LDAP Client(*)\*"))

        # We currently use the same set of counters for all scenarios
        # We can change this in the future if needed (e.g. remove counters for non-DCs)

        $Script:PerfCountersMap = @{
            PerfLogLong  = @{
                Counters       = $perfCountersCommon;
                SampleInterval = "00:05:00"
            };

            PerfLogShort = @{
                Counters       = $perfCountersCommon;
                SampleInterval = "00:00:05"
            };

            PerfLogNonDc = @{
                Counters       = $perfCountersCommon;
                SampleInterval = "00:00:05"
            };
        }
    }

    if ($All) {
        # Return all counters
        return $Script:PerfCountersMap
    }
    else {
        # Return only the specified counter
        return $Script:PerfCountersMap[$CounterName]
    }
}

function GetETWProviders {
    param (
        [Parameter()]
        [string]$TraceName,
        [switch]$All
    )

    if ($null -eq $Script:ETWProvidersMap) {
        $Script:ETWProvidersMap = @{
            Kerberos     = @{
                Providers = @{
                    '{6B510852-3583-4e2d-AFFE-A67F9F223438}' = @{
                        BitMask = '0x7ffffff'
                        Level   = '0xff'
                    }
                    '{60A7AB7A-BC57-43E9-B78A-A1D516577AE3}' = @{
                        BitMask = '0xffffff'
                        Level   = '0xff'
                    }
                    '{FACB33C4-4513-4C38-AD1E-57C1F6828FC0}' = @{
                        BitMask = '0xffffffff'
                        Level   = '0xff'
                    }
                    '{97A38277-13C0-4394-A0B2-2A70B465D64F}' = @{
                        BitMask = '0xff'
                        Level   = '0xff'
                    }
                    '{8a4fc74e-b158-4fc1-a266-f7670c6aa75d}' = @{
                        BitMask = '0xffffffffffffffff'
                        Level   = '0xff'
                    }
                    '{98E6CFCB-EE0A-41E0-A57B-622D4E1B30B1}' = @{
                        BitMask = '0xffffffffffffffff'
                        Level   = '0xff'
                    }
                }
                IsRunning = $false
            }

            Ntlm_CredSSP = @{
                Providers = @{
                    '{5BBB6C18-AA45-49b1-A15F-085F7ED0AA90}' = @{
                        BitMask = '0x5ffDf'
                        Level   = '0xff'
                    }
                    '{AC69AE5B-5B21-405F-8266-4424944A43E9}' = @{
                        BitMask = '0xffffffff'
                        Level   = '0xff'
                    }
                    '{6165F3E2-AE38-45D4-9B23-6B4818758BD9}' = @{
                        BitMask = '0xffffffff'
                        Level   = '0xff'
                    }
                    '{AC43300D-5FCC-4800-8E99-1BD3F85F0320}' = @{
                        BitMask = '0xffffffffffffffff'
                        Level   = '0xff'
                    }
                    '{DAA6CAF5-6678-43f8-A6FE-B40EE096E06E}' = @{
                        BitMask = '0xffffffffffffffff'
                        Level   = '0xff'
                    }
                }
                IsRunning = $false
            }

            SSL          = @{
                Providers = @{
                    '{37D2C3CD-C5D4-4587-8531-4696C44244C8}' = @{
                        BitMask = '0x4000ffff'
                        Level   = '0xff'
                    }
                }
                IsRunning = $false
            }

            NTDSAI       = @{
                Providers = @{
                    '{90717974-98DB-4E28-8100-E84200E22B3F}' = @{
                        BitMask = '0x0'
                        Level   = '0xff'
                    }
                }
                IsRunning = $false
            }

            SDW          = @{
                Providers = @{
                    '{9A7D7195-B713-4092-BDC5-58F4352E9563}' = @{
                        BitMask = '0xffffffffffffffff'
                        Level   = '0xff'
                    }
                    'Microsoft-Windows-LDAP-Client'          = @{
                        BitMask = '0xffffffffffffffff'
                        Level   = '0xff'
                    }
                    'Microsoft-Windows-Kernel-Process'       = @{
                        BitMask = '0x10'
                        Level   = '0xff'
                    }
                }
            }
        }
    }


    if ($All) {
        # Return all Etw
        return $Script:ETWProvidersMap
    }
    else {
        # Return only the specified Etw
        return $Script:ETWProvidersMap[$TraceName]
    }
}

function SetNtdsaiEtwOptions {

    Push-Component "NTDSAI"
    Write-Log "Setting the options for NTDSAI capture..."

    # OS version (RS4)
    $RS4Version = [System.Version]::new(10, 0, 17134, 0)
    $W2012R2Version = [System.Version]::new(6, 3, 9600, 0)

    $bitmaskHashtable = @{
        'DSEVENT'      = @{ # Use only when all event logs are traced
            'Value'            = 0x0001
            'MinimumOSVersion' = $W2012R2Version
        }
        'JET'          = @{
            'Value'            = 0x0002
            'MinimumOSVersion' = $W2012R2Version
        }
        'Core'         = @{
            'Value'            = 0x0004
            'MinimumOSVersion' = $W2012R2Version
        }
        'LDAP'         = @{
            'Value'            = 0x0008
            'MinimumOSVersion' = $W2012R2Version
        }
        'DRA'          = @{ # This is for Replication
            'Value'            = 0x0010
            'MinimumOSVersion' = $W2012R2Version
        }
        'DBLayer'      = @{
            'Value'            = 0x0020
            'MinimumOSVersion' = $W2012R2Version
        }
        'DSAEXCEPT'    = @{ # Use only when all calls to RaiseDsaExcept are traced
            'Value'            = 0x0040
            'MinimumOSVersion' = $W2012R2Version
        }
        'DRSSERV'      = @{
            'Value'            = 0x0080
            'MinimumOSVersion' = $W2012R2Version
        }
        'BATCHBRACKET' = @{ # Only to be used while attempting to catch bug #572
            'Value'            = 0x0100
            'MinimumOSVersion' = $W2012R2Version
        }
        'ATQ'          = @{
            'Value'            = 0x0200
            'MinimumOSVersion' = $W2012R2Version
        }
        'JETBACK'      = @{
            'Value'            = 0x0400
            'MinimumOSVersion' = $W2012R2Version
        }
        'NTDSUTIL'     = @{
            'Value'            = 0x0800
            'MinimumOSVersion' = $W2012R2Version
        }
        'SAMDS'        = @{
            'Value'            = 0x1000
            'MinimumOSVersion' = $W2012R2Version
        }
        'KCC'          = @{ # RS4 and Newer Only
            'Value'            = 0x2000
            'MinimumOSVersion' = $RS4Version
        }
        'QO'           = @{ # Use for query optimizer (Pre-RS4 this is Bit 13 and you would pass 0x2000)
            'Value'            = 0x4000
            'MinimumOSVersion' = $W2012R2Version
        }
        'INSTALL'      = @{ # Use for install and boot (RS4 and Newer Only)
            'Value'            = 0x8000
            'MinimumOSVersion' = $RS4Version
        }
        'DSAPI'        = @{ # Use for DSAPI calls (including NTDSAPI) (RS4 and Newer Only)
            'Value'            = 0x10000
            'MinimumOSVersion' = $RS4Version
        }
    }

    # Split the $NtdsaiTrace string into an array of options and ensure the array contains only unique values
    $NtdsaiTrace = $NtdsaiTrace -split ',' | ForEach-Object { $_.Trim() }
    $NtdsaiTrace = $NtdsaiTrace | Select-Object -Unique

    # Calculate the bitmask options value
    $BitmaskValue = $NtdsaiTrace | ForEach-Object {
        $bitmask = $bitmaskHashtable[$_]['Value']

        if ($_ -eq 'QO') {
            if ($Script:CurrentOSVersion -ge $RS4Version) {
                # RS4 (Windows Server 2019) or newer
                $bitmask
            }
            else {
                0x2000
            }
        }
        else {
            $bitmask
        }
    } | Measure-Object -Sum | Select-Object -ExpandProperty Sum

    $HexBitmaskValue = "0x{0:X}" -f [int]$BitmaskValue

    Write-Log "Selected options: $($NtdsaiTrace -join ', ')"
    Write-Log "Selected NTDSAI options Bitmask value: $HexBitmaskValue"

    # Check if global ETWProviders variable already exists.
    if (-not($Script:ETWProvidersMap)) { GetETWProviders }

    # Update the 'NTDSAI' provider Bitmask value in the global hashtable
    $Script:ETWProvidersMap['NTDSAI']['Providers']['{90717974-98DB-4E28-8100-E84200E22B3F}']['BitMask'] = $HexBitmaskValue

    Pop-Component
}

#endregion

#region Scenarios
function HighCpuDataCollection {

    Push-Component "HighCpu"
    Write-Log "Gathering Data"

    StartCommonTasksCollection

    if ($Script:IsDC) {
        HighCpuDataCollectionDC
    }
    Else {
        HighCpuDataCollectionNonDC
    }

    StartNetTrace

    if ($Script:TriggerScenario) {
        Write-Host "Collecting Data for $Script:TriggeredTimerLength minutes"
        $sleepTime = 60000 * [int]$Script:TriggeredTimerLength
        Start-Sleep -m $sleepTime
    }
    else {
        Read-Host "Ensure you have had enough time for the issue to reproduce and then press The Enter Key to Stop tracing..."
    }

    GetProcDumps -Count 1 -Seconds 5

    StopWPR "-Stop `"$Script:DataPath\WPR.ETL`""
    StopNetTrace
    StopCommonTasksCollection
    StopETWTracing

    if (!$Script:IsDC) {

        StopPerfLogs -CounterName $Script:CollectPerfCounterName

        Invoke-Process -ProcessName "wevtutil.exe" -Arg "epl SYSTEM `"$Script:DataPath\System.evtx`" /ow:true" | Out-Null
        Invoke-Process -ProcessName "wevtutil.exe" -Arg "epl APPLICATION `"$Script:DataPath\Application.evtx`" /ow:true" | Out-Null
        Invoke-Process -ProcessName "wevtutil.exe" -Arg "epl Microsoft-Windows-GroupPolicy/Operational `"$Script:DataPath\GroupPolicy.evtx`" /ow:true" | Out-Null
        Invoke-Process -ProcessName "wevtutil.exe" -Arg "set-log Microsoft-Windows-CAPI2/Operational /enabled:false" | Out-Null
        Invoke-Process -ProcessName "wevtutil.exe" -Arg "epl Microsoft-Windows-CAPI2/Operational `"$Script:DataPath\Capi2_Oper.evtx`" /ow:true" | Out-Null

        $Script:CryptoDataPath = "$Script:DataPath\CryptoKeys"

        $exists = Test-Path $Script:CryptoDataPath
        if (!$exists) {
            New-Item $CryptoDataPath -type directory | Out-Null
        }


        reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Cryptography" /s > "$Script:CryptoDataPath\Cryptography-HKLMControl-key.txt" 2>&1 | Out-Null
        reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography" /s > "$Script:CryptoDataPath\Cryptography-HKLMSoftware-key.txt" 2>&1 | Out-Null
        reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Cryptography" /s > "$Script:CryptoDataPath\Cryptography-HKLMSoftware-Policies-key.txt" 2>&1 | Out-Null
        reg query "HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Cryptography" /s > "$Script:CryptoDataPath\Cryptography-HKCUSoftware-Policies-key.txt" 2>&1 | Out-Null
        reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Cryptography" /s > "$Script:CryptoDataPath\Cryptography-HKCUSoftware-key.txt" 2>&1 | Out-Null
        reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" /s > "$Script:CryptoDataPath\Schannel-key.txt" 2>&1 | Out-Null

        $Script:CertDataPath = "$Script:DataPath\Certinfo"

        $exists = Test-Path $Script:CertDataPath
        if (!$exists) {
            New-Item $CertDataPath -type directory | Out-Null
        }

        Add-Content -Path "$Script:CertDataPath\Machine-Store.txt" -Value (certutil -v -silent -store my 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\User-Store.txt" -Value (certutil -v -silent -user -store my 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Scinfo.txt" -Value (Certutil -v -silent -scinfo 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Tpm-Cert-Info.txt" -Value (certutil -tpminfo 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\CertMY_SmartCard.txt" -Value (certutil.exe -v -silent -user -store my "Microsoft Smart Card Key Storage Provider" 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Cert_MPassportKey.txt" -Value (Certutil -v -silent -user -key -csp "Microsoft Passport Key Storage Provider" 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Homegroup-Machine-Store.txt" -Value (certutil -v -silent -store "Homegroup Machine Certificates" 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\NTAuth-store.txt" -Value (certutil -v -enterprise -store NTAuth 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Machine-Root-AD-store.txt" -Value (certutil -v -store -enterprise root 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Machine-Root-Registry-store.txt" -Value (certutil -v -store root 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Machine-Root-GP-Store.txt" -Value (certutil -v -silent -store -grouppolicy root 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Machine-Root-ThirdParty-Store.txt" -Value (certutil -v -store authroot 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Machine-CA-AD-store.txt" -Value (certutil -v -store -enterprise ca 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Machine-CA-Registry-store.txt" -Value (certutil -v -store ca 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Machine-CA-GP-Store.txt" -Value (certutil -v -silent -store -grouppolicy ca 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Cert-template-cache-machine.txt" -Value (certutil -v -template 2>&1) | Out-Null
        Add-Content -Path "$Script:CertDataPath\Cert-template-cache-user.txt" -Value (certutil -v -template -user 2>&1) | Out-Null

        gpresult /h "`"$Script:DataPath\gpresult.html`""
        Add-Content -Path "$Script:DataPath\netstat.txt" -Value (netstat -ano 2>&1) | Out-Null
    }

    Write-Log "Data Gathered"
    Pop-Component
}

function HighCpuDataCollectionDC {

    Push-Component "DCHighCPU"
    Write-Log "Gathering Data for DCHighCPU"

    GetProcDumps -Count 1 -Seconds 5

    StartWPR "-Start GeneralProfile -Start CPU"

    Write-Log "Gathering data"
    #ETW NTDSAI
    if ($NtdsaiTrace) {

        #Set NTDSAI BITMASK and LEVEL options
        SetNtdsaiEtwOptions
        #Start the NTDSAI ETW capture
        StartETWTracing -TraceName "NTDSAI"
    }

    Write-Log "Gathering data"
    Pop-Component
}

function HighCpuDataCollectionNonDC {

    Push-Component "NonDCHighCPU"
    Write-Log "Gathering Data for NonDCHighCPU"

    Invoke-Process -ProcessName "wevtutil.exe" -Arg "set-log Microsoft-Windows-CAPI2/Operational /enabled:true /rt:false /q:true" | Out-Null

    GetProcDumps -Count 1 -Seconds 5

    StartWPR "-Start GeneralProfile -Start CPU -Start VirtualAllocation -Start Network"

    if (-Not ($Script:TriggerScenario)) {
        $Script:CollectPerfCounterName = "PerfLogNonDc"
        StartPerfLog -CounterName $Script:CollectPerfCounterName
        Write-Log "Collecting Perf Counters"
    }

    StartETWTracing -TraceName "Kerberos"
    StartETWTracing -TraceName "Ntlm_CredSSP"
    StartETWTracing -TraceName "SSL"

    Write-Log "Gathered data"
    Pop-Component
}

function HighCpuDataCollectionTriggerstart {
    Push-Component "HighCpuTrigger"
    Write-Log "Gathering Data"

    if ($Script:Interactive) {
        while ($true) {
            $CPUThreshold = Read-Host "CPU Percent Threshold(50-99)"
            if ([int]$CPUThreshold -gt 20 -and [int]$CPUThreshold -lt 100) {
                $Script:TriggerThreshold = $CPUThreshold
                break
            }
            else {
                Write-Host "Invalid Input"
            }
        }

        $dataCollectionTime = Read-Host "How long in minutes to collect data after trigger is met?"
        if ([int]$dataCollectionTime -gt 0 -and [int]$dataCollectionTime -lt 31) {
            $Script:TriggeredTimerLength = $dataCollectionTime
        }

        $Script:TriggerScenario = $true
    }

    if (!$Script:IsDC) {
        $Script:CollectPerfCounterName = "PerfLogNonDc"
        StartPerfLog -CounterName $Script:CollectPerfCounterName
        Write-Log "Collecting Perf Counters"
    }

    Write-Log "Waiting for high cpu condition of greater than $Script:TriggerThreshold`0%..."
    while ($true) {
        $CPUValue = Get-Counter -Counter "\Processor Information(_Total)\% Processor Time" -SampleInterval 5 -MaxSamples 1
        if ($CPUValue.CounterSamples.CookedValue -gt $Script:TriggerThreshold) {
            Write-Log "CPU Usage is Greater than $Script:TriggerThreshold`0% - Starting Data Collection...." -Channel "Important"
            break
        }
    }

    HighCpuDataCollection
    Pop-Component
}

function HighMemoryDataCollection {
    Push-Component "HighMemory"
    Write-Host "Gathering Data"

    StartCommonTasksCollection

    $RS5Version = [System.Version]::new(10, 0, 17763, 0)

    # only collect Heap snapshot on 2019 and above
    if ($Script:CurrentOSVersion -ge $RS5Version) {
        $lsassProcess = Get-Process "lsass"
        $lsassPid = $lsassProcess.Id.ToString()

        # Heap snapshot should be done with PID. With name requires the process to start after heap snapshots is enabled
        StartWPR "-snapshotconfig heap -pid $lsassPid enable"
        StartWPR "-Start VirtualAllocation -start heapsnapshot -filemode"
        StartWPR "-singlesnapshot heap $lsassPid"
    }
    else {
        StartWPR "-Start VirtualAllocation -filemode"
    }


    if ($Script:IsDC) {
        GetRootDSEArenaInfoAndThreadStates
    }

    #ETW NTDSAI
    if ($NtdsaiTrace) {

        #Set NTDSAI BITMASK and LEVEL options
        SetNtdsaiEtwOptions
        #Start the NTDSAI ETW capture
        StartETWTracing -TraceName "NTDSAI"
    }

    GetProcDumps -ForceDump

    if ($Script:TriggerScenario) {
        Write-Host "Collecting Data for $Script:TriggeredTimerLength minutes"
        $sleepTime = 60000 * [int]$Script:TriggeredTimerLength
        Start-Sleep -m $sleepTime
    }
    else {
        Read-Host "Ensure you have had enough time for the issue to reproduce and then press The Enter Key to Stop tracing..."
    }
    StopETWTracing

    if ($Script:CurrentOSVersion -ge $RS5Version) {
        StartWPR "-singlesnapshot heap $lsassPid"
        StopWPR "-snapshotconfig heap -pid $lsassPid disable"
    }

    StopWPR "-Stop `"$Script:DataPath\WPR.ETL`""



    StopCommonTasksCollection

    if ($Script:IsDC) {
        GetRootDSEArenaInfoAndThreadStates
    }

    if ((!$Script:IsDC) -and ($Script:TriggerScenario)) {
        StopPerfLogs -CounterName $Script:CollectPerfCounterName
    }

    Pop-Component
}

function HighMemoryDataCollectionTriggerStart {
    Push-Component "HighMemoryTrigger"
    Write-Log "Gathering Data"

    if ($Script:Interactive) {
        while ($true) {
            $MemoryThreshold = Read-Host "Memory Percent Threshold(50-99)"

            if ([int]$MemoryThreshold -gt 20 -and [int]$MemoryThreshold -lt 100) {
                $Script:TriggerThreshold = $MemoryThreshold
                break
            }
            else {
                Write-Host "Invalid Input"
            }
        }

        $dataCollectionTime = Read-Host "How long in minutes to collect data after trigger is met?"
        if ([int]$dataCollectionTime -gt 0 -and [int]$dataCollectionTime -lt 31) {
            $Script:TriggeredTimerLength = $dataCollectionTime
        }

        $Script:TriggerScenario = $true
    }

    if (!$Script:IsDC) {
        $Script:CollectPerfCounterName = "PerfLogNonDc"
        StartPerfLog -CounterName $Script:CollectPerfCounterName
    }

    Write-Log "Waiting for high memory condition of greater than $Script:TriggerThreshold`0%..."

    while ($true) {
        $CommittedBytesInUse = Get-Counter -Counter "\Memory\% Committed Bytes In Use" -SampleInterval 5 -MaxSamples 1

        if ($CommittedBytesInUse.CounterSamples.CookedValue -gt $Script:TriggerThreshold) {
            Write-Log "Committed Bytes in Use Percentage is Greater than $Script:TriggerThreshold`0% - Starting Data Collection...." -Channel "Important"
            break
        }
    }

    HighMemoryDataCollection
    Pop-Component
}

function HighLsassHandleCountDataCollection {
    Push-Component "HighLsassHandle"
    Write-Log "Gathering Data"
    StartCommonTasksCollection
    StartWPR "-Start Handle"
    GetProcDumps
    StartPerfLog -CounterName "PerfLogLong"
    StartPerfLog -CounterName "PerfLogShort"

    if ($Script:TriggerScenario) {
        Write-Host "Collecting data for $Script:TriggeredTimerLength minutes"
        $sleepTime = 60000 * [int]$Script:TriggeredTimerLength
        Start-Sleep -m $sleepTime
    }
    else {
        Read-Host "Ensure you have had enough time for the issue to reproduce and then press The Enter Key to stop tracing..."
    }
    GetProcDumps
    StopPerfLogs -CounterName "PerfLogLong"
    StopPerfLogs -CounterName "PerfLogShort"
    StopWPR "-Stop `"$Script:DataPath\WPR.ETL`""
    StopCommonTasksCollection
    Pop-Component
}

function ATQThreadDataCollection {
    Push-Component "ATQ"
    Write-Log "Gathering Data"
    Write-Log "Waiting for ATQ Threads being exhausted..."

    while ($true) {
        $LdapAtqThreads = Get-Counter -Counter "\DirectoryServices(NTDS)\ATQ Threads LDAP" -SampleInterval 5 -MaxSamples 1
        $OtherAtqThreads = Get-Counter -Counter "\DirectoryServices(NTDS)\ATQ Threads Other" -SampleInterval 5 -MaxSamples 1
        $TotalAtqThreads = Get-Counter -Counter "\DirectoryServices(NTDS)\ATQ Threads Total" -SampleInterval 5 -MaxSamples 1

        if ($LdapAtqThreads.CounterSamples.CookedValue + $OtherAtqThreads.CounterSamples.CookedValue -eq $TotalAtqThreads.CounterSamples.CookedValue) {
            Write-Log "ATQ Threads are depleted - Starting Data Collection..." -Channel "Important"
            break
        }
    }

    GetProcDumps -Count 3 -Seconds 5 -ForceDump
    StartCommonTasksCollection
    Write-Log "Please wait around 5 minutes while we collect traces.  The collection will automatically stop after the time has elapsed"
    $sleepTime = 60000 * 5
    Start-Sleep -m $sleepTime
    StopCommonTasksCollection
    Pop-Component
}

function SourceDcWorkloadCollection {
    Push-Component "SDW"
    Write-Log "Gathering Data"
    StartCommonTasksCollection
    StartNetTrace
    StartETWTracing -TraceName "SDW"
    StartWmiTrace
    StartGpsvcLog
    StartWPR "-Start GeneralProfile -Start CPU -Start Network"
    StartProcmon

    Read-Host "Ensure you have enough time for the issue to reproduce then press The Enter Key to stop tracing..."
    StopProcmon
    StopWPR "-Stop `"$Script:DataPath\WPR.etl`""
    GetProcDumps -Process "Winmgmt_Svc"
    StopCommonTasksCollection
    StopGpsvcLog
    StopETWTracing -TraceName "SDW"
    StopWmiTrace
    StopSamClientTrace
    StopWPR "-Stop `"$Script:DataPath\WPR.ETL`""
    StopNetTrace

    #Copying scenario specific data files
    Invoke-Process -ProcessName "wevtutil.exe" -Arg "epl Microsoft-Windows-GroupPolicy/Operational `"$Script:DataPath\GPOperational.evtx`" /ow:true" | Out-Null
    gpresult /h "`"$Script:DataPath\gpresult.html`""
    Pop-Component
}

function BaseLineDataCollection {
    Push-Component "Baseline"
    Write-Log "Gathering Performance Data"

    if ($Script:IsDC) {
        Enable1644RegKeys -useCustomValues $true -searchTimeValue 1 -expSearchResultsValue 0 -inEfficientSearchResultsValue 0
    }

    StartCommonTasksCollection
    StartWPR "-Start GeneralProfile -Start CPU -Start Heap -Start VirtualAllocation"

    Write-Log "Please wait around 5 minutes while we collect performance baseline traces.  The collection will automatically stop after the time has elapsed"

    $sleepTime = 60000 * 5
    Start-Sleep -m $sleepTime

    StopWPR "-Stop `"$Script:DataPath\WPR.ETL`""
    StopCommonTasksCollection
    Pop-Component
}

function LongBaseLineCollection {
    Push-Component "BaselineLong"
    Write-Host "Gathering Performance Data"

    if ($Script:IsDC) {
        Enable1644RegKeys -useCustomValues $true
    }

    StartADDiagnostics
    StartPerfLog -CounterName "PerfLogLong"
    StartPerfLog -CounterName "PerfLogShort"

    $NetlogonParamKey = Get-ItemProperty  -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters"
    $Script:NetLogonDBFlags = $NetlogonParamKey.DBFlag

    Read-Host "Ensure you have had enough time for a good baseline and then press The Enter Key to Stop tracing..."
    StopADDiagnostics
    StopPerfLogs -CounterName "PerfLogLong"
    StopPerfLogs -CounterName "PerfLogShort"
    Pop-Component
}

function StopFailedTracing {
    Push-Component "StopAll"

    ## A previous collection failed or was cancelled prematurely this option will just attempt to stop everything that might still be running
    StopProcmon
    StopWPR
    $customADDSxml = Test-Path "$PSScriptRoot\ADDS.xml"
    if ($customADDSxml) {
        $Script:CustomADDSUsed = $true
    }

    # Set the ETW traces info into the script scope and Stop all Etw traces and
    # set all traces as running so they can be stop
    GetETWProviders -All | Out-Null
    $Script:ETWProvidersMap.Values | ForEach-Object { $_.IsRunning = $true }
    StopETWTracing

    #Set the Performance Counters info into the script scope and Stop all Performance Counters
    GetPerformanceCounters -All | Out-Null
    StopPerfLogs

    #Stop common: Disable1644RegKeys, StopADDiagnostics, StopSamSrvTracing, StopLSATracing
    StopCommonTasksCollection

    #Stop others
    StopRadar
    StopNetTrace
    StopWmiTrace
    StopSamClientTrace
    StopWPR "-Stop `"$Script:DataPath\WPR.ETL`""
    StopGpsvcLog

    if ($Script:CustomADDSUsed) {
        ## have to clean up the source folder otherwise the subsequent runs will fail as it will try to re-use existing folder name
        Write-log "Deleting custom ADDS data collector set"
        $perflogPath = "C:\PerfLogs\Enhanced-ADDS"
        Get-ChildItem $perflogPath | Sort-Object CreationTime -Descending | Select-Object -First 1 | Remove-Item -Recurse -Force
        Invoke-Logman -Arg "delete `"Enhanced Active Directory Diagnostics`"" | Out-Null
    }
    Pop-Component
}

#end region

#region Methods

function StartCommonTasksCollection {
    Push-Component "COMMON"
    Write-Log -Msg "Starting"
    if (!$Script:Custom1644 -and $Script:IsDC) {
        Write-Log "Custom1644: $Script:Custom1644 DC: $Script:DC" -IsDebugOutput
        Enable1644RegKeys
    }

    Write-Log -Msg "Turning on Netlogon Debug flags"
    $NetlogonParamKey = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters"
    $Script:NetLogonDBFlags = $NetlogonParamKey.DBFlag
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters" -Name "DBFlag" -Value 0x2080ffff -PropertyType DWORD -Force | Out-Null

    if ($Script:IsDC) {
        StartADDiagnostics
        StartSamSrvTracing
    }
    StartLSATracing
    Write-Log -Msg "Started"
    Pop-Component
}

function StopCommonTasksCollection {
    Push-Component "COMMON"
    Write-Log -Msg "Stopping"
    if ($Script:ISDC) {
        Disable1644RegKeys
        StopADDiagnostics
        StopSamSrvTracing
    }

    StopLSATracing
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters" -Name "DBFlag" -Value $Script:NetLogonDBFlags -PropertyType DWORD -Force | Out-Null
    if (Test-Path "$env:SystemRoot\Debug\Netlogon.log") {
        Copy-Item -Path "$env:SystemRoot\Debug\Netlogon.log" -Destination $Script:DataPath -Force
    }

    $NetlogonBakExists = Test-Path "$env:SystemRoot\Debug\Netlogon.bak"
    if ($NetlogonBakExists) {
        Copy-Item -Path "$env:SystemRoot\Debug\Netlogon.bak" -Destination $Script:DataPath -Force
    }

    Write-Log -Msg "Stopped"
    Pop-Component
}

function GetRootDSEArenaInfoAndThreadStates {
    Push-Component "RootDSE"
    Write-Log "Getting Arena Info and Thread State Info..."
    Import-Module ActiveDirectory
    $LdapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection(New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($env:computername, 389))

    $msDSArenaInfoReq = New-Object System.DirectoryServices.Protocols.SearchRequest
    $msDSArenaInfoReq.Filter = "(objectclass=*)"
    $msDSArenaInfoReq.Scope = "Base"
    $msDSArenaInfoReq.Attributes.Add("msDS-ArenaInfo") | Out-Null

    $msDSArenaInfoResp = $LdapConnection.SendRequest($msDSArenaInfoReq)

    (($msDSArenaInfoResp.Entries[0].Attributes["msds-ArenaInfo"].GetValues([string]))[0]) | Out-File "$Script:DataPath\msDs-ArenaInfo.txt" -Append

    Add-Content -Path "$Script:DataPath\msDs-ArenaInfo.txt" -Value "=========================================================="

    $msDSArenaInfoReq.Attributes.Clear()
    $msDSArenaInfoReq.Attributes.Add("msds-ThreadStates") | Out-Null

    $msDSThreadStatesResp = $LdapConnection.SendRequest($msDSArenaInfoReq)

    (($msDSThreadStatesResp.Entries[0].Attributes["msds-ThreadStates"].GetValues([string]))[0]) | Out-File "$Script:DataPath\msDs-ThreadStates.txt" -Append

    Add-Content -Path "$Script:DataPath\msDs-ThreadStates.txt" -Value "=========================================================="
    Pop-Component
}

function GetProcDumps {
    param(
        [int]$Count = 1,
        [int]$Seconds,
        [switch]$ForceDump,
        [string]$Process = "lsass"
    )
    Push-Component "Procdump"

    # Check if Lsass dump can be collected:
    # isRealtimeProtectionOn and isRunAsPplOn can't be true
    if ($Script:ADPerfDump -or $ForceDump) {
        if (-not $Script:isRealtimeProtectionOn -and -not $script:isRunAsPplOn) {

            Write-Log "Collecting $Process Process Dump...."
            $DumpPID = 0
            if ($Process.Contains("_Svc")) {
                # We are assuming this is a Windows service
                $ServiceName = $Process.Replace("_Svc", "")
                $DumpPID = (Get-WmiObject -Class Win32_Service -Filter "NAME LIKE `"$ServiceName`"").ProcessId
            }
            else {
                $DumpPID = (Get-Process -Name $Process).Id
            }
            $procdumpArgs = "$DumpPID "

            if ($Script:DumpType -eq "MiniPlus") {
                $procdumpArgs += "-mp "
            }
            else {
                $procdumpArgs += "-ma "
            }

            if ($Count -eq 1) { $procdumpArgs += " -a -r 3 -AcceptEula `"$Script:DataPath`"" }
            else { $procdumpArgs += "-n $Count -s $Seconds -a -r 3 -AcceptEula `"$Script:DataPath`"" }

            $procdump = Test-Path "$PSScriptRoot\procdump.exe"

            if ($procdump) {
                try {
                    Invoke-Process -ProcessName "$PSScriptRoot\procdump.exe" -Arg $procdumpArgs | Out-Null
                }
                catch [System.Management.Automation.MethodInvocationException] {
                    Write-Log "$_
                    Collecting process dumps failed.
                    Please check the following
                        1.  Do you have 3rd party AV blocking process dumps?
                        2.  Do you have Shadow stack enabled" -Color "Yellow" -Channel "Error"
                }
            }
            else {
                Write-Log "Procdump.exe not found in script root, using MSDATA"
                $Result = [MSDATA.UserDump]::GenerateUserDump($DumpPID, $Script:DataPath, $Process, $Count, $Seconds) | Out-Null
                if ($false -eq $Result) {
                    Write-Log "Collecting process dumps failed.
                    Please check the following
                        1.  Do you have 3rd party AV blocking process dumps?
                        2.  Do you have Shadow stack enabled" -Color "Yellow" -Channel "Error"
                }
            }
        }
        else {
            Write-Log "Skipping Lsass Dump capture..." -Channel "Important"
        }
    }
    Pop-Component
}

function StartWPR {
    param(
        [string]$arg
    )
    Push-Component "WPR"
    Write-Log "Starting with args: $arg"
    Invoke-Process -ProcessName "wpr.exe" -Arg $arg | Out-Null
    Write-Log "Started"
    Pop-Component
}

function StopWPR {
    param(
        [parameter(Mandatory = $true)]
        [string]$arg
    )

    Push-Component "WPR"
    Write-Log "Stopping"

    # OS version (Windows Server 2022)
    $osVersion2022 = [System.Version]::new(10, 0, 20348, 0)

    # Check if OS version is equal or great then 2022 and add the -skipPdbGen parameter to the WPR stop command.
    if (($Script:CurrentOSVersion -ge $osVersion2022) -and ($arg -Contains "-Stop")) {
        $arg += " -skipPdbGen"
    }

    Invoke-Process -ProcessName "wpr.exe" -Arg $arg | Out-Null

    Write-Log "Stopped"
    Pop-Component
}

function StartADDiagnostics {
    Push-Component "ADDS"
    Write-Log "Starting ADDS Diagnostics"
    ##Import custom data collector set xml if it exists
    $customADDSxml = Test-Path "$PSScriptRoot\ADDS.xml"
    $StartArgs = "start `"system\Active Directory Diagnostics`" -ets -as"

    if ($customADDSxml) {
        Write-Log "Custom Data Collector Set Found - Importing..."
        $result = Invoke-Logman -Arg "-import -name `"Enhanced Active Directory Diagnostics`" -xml `"$PSScriptRoot\ADDS.xml`""
        if ($result -eq 0x803000b7) {
            Write-Log "Custom Data Collector already exists. Removing and reimporting"
            Invoke-Logman -Arg "delete `"Enhanced Active Directory Diagnostics`"" | Out-Null
            Get-ChildItem "C:\PerfLogs\Enhanced-ADDS" | Remove-Item -Recurse -Force
            Invoke-Logman -Arg "-import -name `"Enhanced Active Directory Diagnostics`" -xml `"$PSScriptRoot\ADDS.xml`"" | Out-Null
        }

        $Script:CustomADDSUsed = $true
        Write-Log "Custom Data Collector Set Imported"
        $StartArgs = "start `"Enhanced Active Directory Diagnostics`""
    }

    Invoke-Logman -Arg $StartArgs | Out-Null
    Write-Log "Started ADDS Diagnostics"
    Pop-Component
}

function StopADDiagnostics {
    Push-Component "ADDS"
    Write-Log "Stopping. This may take a moment..."
    if ($Script:CustomADDSUsed) {
        $StartArgs = "stop `"Enhanced Active Directory Diagnostics`""
    }
    else {
        $StartArgs = "stop `"system\Active Directory Diagnostics`" -ets"
    }
    $result = Invoke-Logman -Arg $StartArgs
    if ($result -ne 0) {
        Write-Log $("logman.exe $StartArgs failed with exit code: 0x{0:X}" -f $result) -Channel "Error"

        # Check for PLA_E_DCS_NOT_RUNNING == AD Diag wasn't started
        if ($result -eq 0x80300104) {
            Write-Log $("AD Diag was never started") -Channel Error
            return
        }
    }

    $perflogPath = "C:\PerfLogs\ADDS"
    if ($Script:CustomADDSUsed) {
        $perflogPath = "C:\PerfLogs\Enhanced-ADDS"
    }

    # We are assuming the most recent folder is the one we want.
    # If this is not the case, we will need to add logic to find the correct folder (e.g. looking at last modified date)
    $ADDataCollectorPath = Get-ChildItem $perflogPath | Sort-Object CreationTime -Descending | Select-Object -First 1 -ErrorAction SilentlyContinue

    ## just a fail safe in case for whatever reason the custom ADDS data collector import failed
    if (!$ADDataCollectorPath) {
        Write-Log "AD Data Collector path was not found... skipping" -Channel "Important"
        return
    }

    $Attempts = 0;
    $ReportPath = "$($ADDataCollectorPath.Fullname)\Report.html"
    Write-Log "Waiting for report.html creation to be complete. This process can take a while (max wait time is 30 minutes)"
    while ($true) {
        $reportcomplete = Test-Path $ReportPath
        if ($reportcomplete -or [int]$Attempts -eq 60) {
            break
        }
        Start-Sleep -Seconds 30
        $Attempts = [int]$Attempts + 1
    }

    if ([int]$Attempts -eq 60) {
        Write-Log "Waited 30 minutes and the report is still not generated. Copying just the raw data that is available" -Channel "Error"
    }
    else {
        Write-Log "Report.html compile completed"
    }

    Get-ChildItem $perflogPath | Sort-Object CreationTime -Descending | Select-Object -First 1 | Copy-Item -Destination $Script:DataPath -Recurse -Force
    if ($Script:CustomADDSUsed) {
        ## have to clean up the source folder otherwise the subsequent runs will fail as it will try to re-use existing folder name
        Get-ChildItem $perflogPath | Sort-Object CreationTime -Descending | Select-Object -First 1 | Remove-Item -Recurse -Force
        Invoke-Logman -Arg "delete `"Enhanced Active Directory Diagnostics`"" | Out-Null
    }

    Write-Log "Stopped"
    Pop-Component
}

function StartETWTracing {
    param(
        [string]$TraceName
    )

    Push-Component "ETW"
    Write-Log "Starting $TraceName ETW Tracing"

    $ETWProviders = GetETWProviders -TraceName $TraceName

    [string]$ETWStartArgs = "start $Tracename -o `"$Script:DataPath\$TraceName.etl`" -ets"

    Invoke-Logman -Arg $ETWStartArgs | Out-Null
    #Set the trace Running property on
    $Script:ETWProvidersMap[$TraceName].IsRunning = $true
    if ($ETWProviders["Providers"]) {
        foreach ($Provider in $ETWProviders["Providers"].GetEnumerator()) {
            $GUID = $Provider.Name
            $Bitmask = $Provider.Value.BitMask
            $Level = $Provider.Value.Level
            [string]$ETWUpdateArgs = "update trace $Tracename -p $GUID $Bitmask $Level -ets"
            Invoke-Logman -Arg $ETWUpdateArgs | Out-Null
        }
    }

    Write-Log "$TraceName Tracing Started"
    Pop-Component
}

function StopETWTracing {
    param(
        [string]$TraceName
    )

    Push-Component "ETW"
    Write-Log "Stopping ETW Traces..."

    #If a tracename was passed, stop only that trace
    if ($TraceName) {
        Write-Log "Stopping $TraceName ETW Trace"
        Stop-Logman -SessionName $TraceName | Out-Null
        $Script:ETWProvidersMap[$TraceName].IsRunning = $false
    }
    else {
        #Else stop all running traces
        $ETWEnum = (GetETWProviders -All).GetEnumerator()
        foreach ($etw in $ETWEnum) {

            if ($etw.Value.IsRunning -eq $true) {
                $trace = $etw.Name
                Write-Log "Stopping ETW Trace: $trace"
                Stop-Logman -SessionName $trace | Out-Null
                $Script:ETWProvidersMap[$trace].IsRunning = $false
            }
        }
    }

    Write-Log "ETW traces stopped"
    Pop-Component
}

function StartPerfLog {

    param(
        [string]$CounterName
    )

    Push-Component "PERF"
    Write-Log "Starting Performance Counters"

    $Script:CollectPerfCounters = $true
    $PerfCounters = GetPerformanceCounters -Name $CounterName

    if ($PerfCounters["Counters"]) {
        $Counters = "";
        foreach ($Counter in $PerfCounters["Counters"]) {
            $Counters += $("`"" + $Counter + "`" ")
        }
    }

    [string]$CreateCounterArgs = "create counter $CounterName -o `"$Script:DataPath\$CounterName.blg`" -f bincirc -v mmddhhmm -max 300 -c $Counters -si $($PerfCounters["SampleInterval"])"

    Invoke-Logman -Arg $CreateCounterArgs | Out-Null

    $StartArg = "start $CounterName"

    Invoke-Logman -Arg $StartArg | Out-Null

    Write-Log "Counters Started"
    Pop-Component
}

function StopPerfLogs {
    param(
        [string]$CounterName
    )

    Push-Component "PERF"
    Write-Log "Stopping Performance Counters"

    #If a CounterName was passed, stop only that Counter
    if ($CounterName) {
        Write-Log "Stopping $CounterName Performance Counter"

        $StopArgs = "stop $CounterName"
        $DeleteArgs = "delete $CounterName"

        Invoke-Logman -Arg $StopArgs | Out-Null
        Invoke-Logman -Arg $DeleteArgs | Out-Null
    }
    else {
        #Else stop all running traces
        $PerfCounterEnum = $Script:PerfCountersMap.GetEnumerator()
        foreach ($counterSet in $PerfCounterEnum) {

            $counter = $counterSet.Name
            Write-Log "Stopping Performance Counter: $counter"

            $StopArgs = "stop $counter"
            $DeleteArgs = "delete $counter"

            Invoke-Logman -Arg $StopArgs | Out-Null
            Invoke-Logman -Arg $DeleteArgs | Out-Null
        }
    }

    Write-Log "Performance Counters Stopped"
    Pop-Component
}

function Invoke-Logman {
    param(
        [string]$Arg,
        [switch]$Silent
    )
    Push-Component "IL"
    Write-Log "Running: `"logman.exe $Arg`"" -IsDebugOutput
    Pop-Component
    return Invoke-Process -ProcessName "logman.exe" -Arg $Arg -Silent:$Silent
}

function StartLSATracing {
    Push-Component "Lsa"
    Write-Log "Starting"
    $result = Invoke-Logman -Arg "start LsaTrace -p {D0B639E0-E650-4D1D-8F39-1580ADE72784} 0x40141F -o `"$Script:DataPath\LsaTrace.etl`" -ets"
    if ($result -eq 0x803000b7) {
        Write-Log "Tracing exists. Restarting LsaTrace.exe" -Channel "Important"
        Stop-Logman -SessionName "LsaTrace" | Out-Null
        Invoke-Logman -Arg "start LsaTrace -p {D0B639E0-E650-4D1D-8F39-1580ADE72784} 0x40141F -o `"$Script:DataPath\LsaTrace.etl`" -ets" | Out-Null
    }
    Write-Log "ETW Started"
    $LSA = Get-ItemProperty  -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA

    if ($null -eq $LSA.LspDbgTraceOptions) {
        #Create the value and then set it to TRACE_OPTION_LOG_TO_FILE = 0x1,
        New-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA -Name 'LspDbgTraceOptions' -PropertyType DWord -Value '0x1'
    }
    elseif ($LSA.LspDbgTraceOptions -ne '0x1') {
        #Set the existing value to 1
        Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA -Name 'LspDbgTraceOptions' '0x00320001'
    }
    if ($null -eq $LSA.LspDbgInfoLevel) {
        New-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA -Name 'LspDbgInfoLevel' -PropertyType DWord -Value '0xF000800'
    }
    elseif ($LSA.LspDbgInfoLevel -ne '0xF000800') {
        Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA -Name 'LspDbgInfoLevel' -Value '0xF000800'
    }
    Write-Log "LSP Started"
    Write-Log "Started"
    Pop-Component
}

function StopLSATracing {
    Push-Component "Lsa"
    Write-Log "Stopping"
    Stop-Logman -SessionName "LsaTrace" | Out-Null
    Write-Log "ETW Stopped"
    Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA -Name 'LspDbgTraceOptions'  -Value '0x0'
    Write-Log "LSP Stopped"
    Copy-Item -Path "$env:SystemRoot\Debug\lsp.log" -Destination $Script:DataPath -Force
    Write-Log "Stopped"
    Pop-Component
}

function StartSamSrvTracing {
    Push-Component "SamSrv"
    Write-Log "Starting"
    $result = Invoke-Logman -Arg "create trace SamSrv -p {F2969C49-B484-4485-B3B0-B908DA73CEBB} 0xffffffffffffffff 0xff -ow -o `"$Script:DataPath\SamSrv.etl`" -ets"
    if ($result -eq 0x803000b7) {
        Write-Log "Tracing already exists. Restarting SamSrv.etl" -Channel "Important"
        Stop-Logman -SessionName "SamSrv" | Out-Null
        Invoke-Logman -Arg "create trace SamSrv -p {F2969C49-B484-4485-B3B0-B908DA73CEBB} 0xffffffffffffffff 0xff -ow -o `"$Script:DataPath\SamSrv.etl`" -ets" | Out-Null
    }
    Write-Log "Started"
    Pop-Component
}

function StopSamSrvTracing {
    Push-Component "SamSrv"
    Write-Log "Stopping"
    Stop-Logman -SessionName "SamSrv" | Out-Null
    Write-Log "Stopped"
    Pop-Component
}

function StartNetTrace {
    Push-Component "Netsh"
    Write-Log "Starting"
    # Start dummy capture to ensure driver is loaded
    Invoke-Process -ProcessName "netsh.exe" -Arg "trace start capture=yes maxsize=1 report=disabled" -Silent | Out-Null
    Invoke-Process -ProcessName "netsh.exe" -Arg "trace stop" -Silent | Out-Null
    Invoke-Process -ProcessName "netsh.exe" -Arg "trace start capture=yes report=disabled tracefile=`"$Script:DataPath\nettrace.etl`"" | Out-Null
    Write-Log "Started"
    Pop-Component
}

function StopNetTrace {
    Push-Component "Netsh"
    Write-Log "Stopping"
    Invoke-Process -ProcessName "netsh.exe" -Arg "trace stop" | Out-Null
    Write-Log "Stopped"
    Pop-Component
}

function StartWmiTrace {
    Push-Component "SamWMI"
    Write-Log "Starting"
    $result = Invoke-Logman -Arg "create trace SamWMI -p {1FF6B227-2CA7-40F9-9A66-980EADAA602E} 0xffffffffffffffff 0xff -ow -o `"$Script:DataPath\SamWMI.etl`" -ets"
    if ($result -eq 0x803000b7) {
        Write-Log "Tracing already exists. Restarting SamSrv.etl" -Channel "Important"
        Stop-Logman -SessionName "SamWMI" | Out-Null
        Invoke-Logman -Arg "create trace SamWMI -p {1FF6B227-2CA7-40F9-9A66-980EADAA602E} 0xffffffffffffffff 0xff -ow -o `"$Script:DataPath\SamWMI.etl`" -ets" | Out-Null
    }
    Write-Log "Started"
    Pop-Component
}

function StopWmiTrace {
    Push-Component "SamWMI"
    Write-Log "Stopping"
    Stop-Logman -SessionName "SamWMI" | Out-Null
    Write-Log "Stopped"
    Pop-Component
}

function StartSamClientTrace {
    Push-Component "SamClient"
    Write-Log "Starting"
    $result = Invoke-Logman -Arg "create trace SamClient -p {9A7D7195-B713-4092-BDC5-58F4352E9563} 0xffffffffffffffff 0xff -ow -o `"$Script:DataPath\SamClient.etl`" -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 1024 -ets"
    if ($result -eq 0x803000b7) {
        Write-Log "Tracing already exists. Restarting SamClient.etl" -Channel "Important"
        Stop-Logman "SamClient" | Out-Null
        Invoke-Logman -Arg "create trace SamClient -p {9A7D7195-B713-4092-BDC5-58F4352E9563} 0xffffffffffffffff 0xff -ow -o `"$Script:DataPath\SamClient.etl`" -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 1024 -ets" | Out-Null
    }
    Write-Log "Started"
    Pop-Component
}

function StopSamClientTrace {
    Push-Component "SamClient"
    Write-Log "Stopping"
    Stop-Logman -SessionName "SamClient" | Out-Null
    Write-Log "Stopped"
    Pop-Component
}

function StartGpsvcLog {
    Push-Component "GpSvc"
    Write-Log "Starting"
    $GpSvcLogPath = "C:\Windows\Debug\Usermode"
    $GpSvcPath = "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Diagnostics"
    if (!(Test-Path $GpSvcLogPath)) {
        Write-Log "Creating log directory"
        New-Item "C:\Windows\Debug\Usermode" -Type Directory | Out-Null
    }

    $GPDiagnostics = Get-ItemProperty -Path $GpSvcPath -ErrorAction SilentlyContinue
    if ($null -eq $GPDiagnostics) {
        New-Item $GpSvcPath -Force
    }
    if ($null -eq $GPDiagnostics.GPSvcDebugLevel) {
        New-ItemProperty -Path $GpSvcPath -Name "GPSvcDebugLevel" -Value '0x30002' -PropertyType DWord
    }
    elseif ($GPDiagnostics.GPSvcDebugLevel -ne '0x30002') {
        Set-ItemProperty -Path $GpSvcPath -Name "GPSvcDebugLevel" -Value '0x30002'
    }
    Write-Log "Started"
    Pop-Component
}

function StopGpsvcLog {
    Push-Component "GpSvc"
    Write-Log "Stopping"
    $GpSvcPath = "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Diagnostics"
    Set-ItemProperty -Path $GpSvcPath -Name "GPSvcDebugLevel" -Value '0'

    # On Scenario/selection 10/stop, we can't copy the file to a folder because the scenario Stop folder is not created.
    # This option is used only to stop running traces.
    if ($Selection -ne "Stop" -and (Test-Path "C:\Windows\Debug\Usermode\gpsvc.log")) {
        Copy-Item -Path "C:\Windows\Debug\Usermode\gpsvc.log" -Destination "$Script:DataPath\gpsvc.log"
    }

    Write-Log "Stopped"
    Pop-Component
}

function StartProcmon {
    Push-Component "Procmon"
    $procmon = Test-Path "$PSScriptRoot\procmon.exe"
    if ($procmon) {
        Write-Log "Found procmon starting"
        Invoke-Process -ProcessName "$PSScriptRoot\procmon.exe" -Arg "/minimized /backingfile `"$Script:DataPath\procmon.pml`" /accepteula" -Async | Out-Null
    }
    else {
        Write-Log "Failed to find procmon in `"$PSScriptRoot\procmon.exe)`"" -Channel "Important"
    }
    Pop-Component
}

function PreTraceVerification {

    Push-Component "SecVerify"
    # Setting script-scoped variables to hold the Security verification results
    [bool]$Script:isRunAsPplOn = $true
    [bool]$Script:isRealtimeProtectionOn = $true

    # Per session variable to collect LSASS DUmps. (High Memory Scenarios will collect by default)
    $Script:ADPerfDump = $env:ADPERFDUMP

    #### Check-LsaProtections ###
    try {
        # Get Kernel-General ID12 for boot time
        $BootTime = ((Get-WinEvent -LogName "System" -FilterXPath "*[System[EventID=12 and Provider[@Name='Microsoft-Windows-Kernel-General']]]" -MaxEvents 1 -ErrorAction SilentlyContinue).Properties[-1].Value).ToString("o")

        # Get Winint ID12 Events after lastboot
        $Wininit12EventValue = (Get-WinEvent -FilterHashtable @{ Id = 12; LogName = "System"; ProviderName = "Microsoft-Windows-Wininit"; starttime = $BootTime } -MaxEvents 1 -ErrorAction SilentlyContinue).Properties.Value

        if ($Wininit12EventValue -and $Wininit12EventValue -eq 4) {
            #LSASS.exe was started as a protected process with level: 4.
            $Script:isRunAsPplOn = $true
        }
        else {
            #RunasPPL is disabled.
            $Script:isRunAsPplOn = $false
        }
    }
    catch {
        #If something goes wrong we return true and log the error
        Write-Log "Exception checking Check-LsaProtections.`nException info: $($_.Exception)" -Channel "Error"
        $Script:isRunAsPplOn = $true
    }

    #### Check-WindowsDefender ####
    try {
        #First check to see if MsMpEng is running
        $DefenderCheck = Get-Process MsMpEng -ErrorAction SilentlyContinue
        if ($null -eq $DefenderCheck) {
            #Defender isn't running
            Write-Log "Defender isn't running" -IsDebugOutput
            $Script:isRealtimeProtectionOn = $false
        }
        else {
            #Defender is running

            #Check and see if realtime protection is disabled
            $RealTimeProtectionDisabled = (Get-MpPreference).DisableRealtimeMonitoring

            if ($RealTimeProtectionDisabled -eq $true) {
                $Script:isRealtimeProtectionOn = $false #Real time Protection is off
                Write-Log "Real time Protection is off" -IsDebugOutput
            }
            else {
                $Script:isRealtimeProtectionOn = $true #Real time Protection is on
                Write-Log "Real time Protection is on" -IsDebugOutput
            }
        }
    }
    catch {
        #If something goes wrong we return true and log the error
        Write-Log "Exception checking Check-WindowsDefender.`nException info: $($_.Exception)" -Channel "Error"
        $Script:isRealtimeProtectionOn = $true
    }

    <#Check-ShadowStack            // Disabling this check for the time being
    try {
        #Get ProcessMitigations Module info
        $ProcessMitigationsModule = Get-Module -Name ProcessMitigations

        #Check if module is available.
        if ($ProcessMitigationsModule) {
            #Get Process mitigations configuration
            $Mitigations = Get-ProcessMitigation -Name "lsass" -RunningProcesses

            #Check if UserShadowStacks are enabled
            if( $Mitigations.UserShadowStack.UserShadowStack -eq [Microsoft.Samples.PowerShell.Commands.OPTIONVALUE]::ON){
                Write-Log "Lsass UserShadowStacks is enabled" -IsDebugOutput
                $isShadowStacksOn = $true
            }
            else{
                Write-Log "Lsass UserShadowStacks is disabled" -IsDebugOutput
                $isShadowStacksOn = $false
            }
        }
        else {#ProcessMitigations module not available, Return false. (Probably 2016 or lower)
            Write-Log "ProcessMitigations module not available, Return false. (Probably O.S. version 2016 or lower)" -IsDebugOutput
            $isShadowStacksOn = $false
        }
    }
    catch {#If something goes wrong we return true and log the error
        Write-Log "Exception checking ShadowStacks.`nException info: $($_.Exception)" -IsDebugOutput
        $isShadowStacksOn = $true

    }#>

    Write-Log "IsRunAsPplOn: $($Script:isRunAsPplOn) | IsRealtimeProtectionOn: $($Script:isRealtimeProtectionOn)" -Channel "Important"
    Pop-Component
}

function StopProcmon {
    Push-Component "Procmon"
    $procmon = Test-Path "$PSScriptRoot\procmon.exe"
    if ($procmon) {
        Write-Log "Stopping procmon"
        Invoke-Process -ProcessName "$PSScriptRoot\procmon.exe" -Arg "/terminate" | Out-Null
    }
    Pop-Component
}

function Enable1644RegKeys {
    param(
        [bool]$useCustomValues = $false,
        $searchTimeValue = "50",
        $expSearchResultsValue = "10000",
        $inEfficientSearchResultsValue = "1000"
    )
    Push-Component "EVENT1644"
    Write-Log "Starting"
    ##make sure the Event Log is at least 50MB

    $DirSvcLog = Get-WmiObject -Class Win32_NTEventLogFile -Filter "LogFileName = 'Directory Service'"
    $MinLogSize = 50 * 1024 * 1024
    if ($DirSvcLog.MaxFileSize -lt $MinLogSize) {
        Write-Log "Increasing the Directory Service Event Log Size to 50MB"
        Limit-EventLog -LogName "Directory Service" -MaximumSize 50MB
    }

    $registryPathFieldEngineering = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics"
    $fieldEngineering = "15 Field Engineering"
    $fieldEngineeringValue = "5"

    $DiagnosticsKey = Get-ItemProperty -Path $registryPathFieldEngineering
    $Script:FieldEngineering = $DiagnosticsKey."15 Field Engineering"

    New-ItemProperty -Path $registryPathFieldEngineering -Name $fieldEngineering -Value $fieldEngineeringValue -PropertyType DWORD -Force | Out-Null
    if ($useCustomValues) {
        Write-Log "Using custom values"
        $registryPathParameters = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
        $thresholdsKey = Get-ItemProperty -Path $registryPathParameters

        ##Only set custom thresholds if there are none previously defined by customer
        if (($null -eq $thresholdsKey."Search Time Threshold (msecs)") -and ($null -eq $thresholdsKey."Expensive Search Results Threshold") -and ($null -eq $thresholdsKey."Inefficient Search Results Threshold")) {
            $searchTime = "Search Time Threshold (msecs)"
            New-ItemProperty -Path $registryPathParameters -Name $searchTime -Value $searchTimeValue -PropertyType DWORD -Force | Out-Null

            $expSearchResults = "Expensive Search Results Threshold"
            New-ItemProperty -Path $registryPathParameters -Name $expSearchResults -Value $expSearchResultsValue -PropertyType DWORD -Force | Out-Null

            $inEfficientSearchResults = "Inefficient Search Results Threshold"
            New-ItemProperty -Path $registryPathParameters -Name $inEfficientSearchResults -Value $inEfficientSearchResultsValue -PropertyType DWORD -Force | Out-Null

            $Script:Custom1644 = $true
        }
    }

    Write-Log "Started"
    Pop-Component
}

function Disable1644RegKeys {
    Push-Component "EVENT1644"
    Write-Log "Stopping"
    $registryPathFieldEngineering = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics"
    $fieldEngineering = "15 Field Engineering"

    New-ItemProperty -Path $registryPathFieldEngineering -Name $fieldEngineering -Value $Script:FieldEngineering -PropertyType DWORD -Force | Out-Null

    if ($Script:Custom1644) {
        ##Safest to just remove these entries so it reverts back to default
        $registryPathParameters = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
        $searchTime = "Search Time Threshold (msecs)"
        Remove-ItemProperty -Path $registryPathParameters -Name $searchTime
        $expSearchResults = "Expensive Search Results Threshold"
        Remove-ItemProperty -Path $registryPathParameters -Name $expSearchResults
        $inEfficientSearchResults = "Inefficient Search Results Threshold"
        Remove-ItemProperty -Path $registryPathParameters -Name $inEfficientSearchResults
    }
    Write-Log "Stopped"
    Pop-Component
}

function CollectAuxData {
    Push-Component "Aux"
    ##Copy Directory Services Event Log
    Write-Log "Collecting data"
    if ($Script:ISDC) {
        Write-Log "Collecting DC Logs"
        dcdiag /v | Out-File "$Script:DataPath\DCDiag.txt"
        Copy-Item -Path "$env:SystemRoot\System32\Winevt\Logs\Directory Service.evtx" -Destination $Script:DataPath
        Copy-Item -Path "$env:SystemRoot\system32\ntdsai.dll" -Destination $Script:DataPath
        Copy-Item -Path "$env:SystemRoot\system32\ntdsatq.dll" -Destination $Script:DataPath

        #NDTS Database file report
        $NTDSDIT = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Database log files path" -ErrorAction SilentlyContinue
        if ($null -ne $NTDSDIT.'Database log files path') {
            $DITReport = @()
            Get-ChildItem -Path $NTDSDIT.'Database log files path' | ForEach-Object {
                $DITReport += [PSCustomObject]@{
                    Name = $_.FullName
                    Size = '{0:N0} KB' -f ($_.Length / 1KB)
                }
            }
            $DITReport | Out-File "$Script:DataPath\dbsize.txt"
        }
    }

    Write-Log "Collecting general information"
    ipconfig /all | Out-File "$Script:DataPath\ipconfig.txt"
    ipconfig /displaydns | Out-File "$Script:DataPath\dns.txt"
    tasklist /svc | Out-File "$Script:DataPath\tasklist.txt"
    tasklist /v /fo csv | Out-File "$Script:DataPath\Tasklist.csv"
    netstat -anoq | Out-File "$Script:DataPath\Netstat.txt"
    Copy-Item "$env:SystemRoot\system32\samsrv.dll" -Destination $Script:DataPath
    Copy-Item "$env:SystemRoot\system32\lsasrv.dll" -Destination $Script:DataPath

    Write-Log "Collected"
    Pop-Component
}

function StopFailedTracing {
    Push-Component "StopAll"
    ## A previous collection failed or was cancelled prematurely this option will just attempt to stop everything that might still be running
    StopProcmon
    StopWPR "-Stop `"$Script:DataPath\WPR.ETL`""
    $customADDSxml = Test-Path "$PSScriptRoot\ADDS.xml"
    if ($customADDSxml) {
        $Script:CustomADDSUsed = $true
    }
    StopPerfLogs $true
    StopPerfLogs $false
    StopCommonTasksCollection
    StopLSATracing
    StopSamSrvTracing
    StopNetTrace
    StopWmiTrace
    StopGpsvcLog
    StopETWTracing

    if ($Script:CustomADDSUsed) {
        ## have to clean up the source folder otherwise the subsequent runs will fail as it will try to re-use existing folder name
        $perflogPath = "C:\PerfLogs\Enhanced-ADDS"
        Get-ChildItem $perflogPath | Sort-Object CreationTime -Descending | Select-Object -First 1 | Remove-Item -Recurse -Force
        Invoke-Logman -Arg "delete `"Enhanced Active Directory Diagnostics`"" | Out-Null
    }
    Pop-Component
}

[void][System.Reflection.Assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')

function ShowEULAPopup($mode) {
    $EULA = New-Object -TypeName System.Windows.Forms.Form
    $richTextBox1 = New-Object System.Windows.Forms.RichTextBox
    $btnAcknowledge = New-Object System.Windows.Forms.Button
    $btnCancel = New-Object System.Windows.Forms.Button

    $EULA.SuspendLayout()
    $EULA.Name = "EULA"
    $EULA.Text = "Microsoft Diagnostic Tools End User License Agreement"

    $richTextBox1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $richTextBox1.Location = New-Object System.Drawing.Point(12, 12)
    $richTextBox1.Name = "richTextBox1"
    $richTextBox1.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $richTextBox1.Size = New-Object System.Drawing.Size(776, 397)
    $richTextBox1.TabIndex = 0
    $richTextBox1.ReadOnly = $True
    $richTextBox1.Add_LinkClicked({ Start-Process -FilePath $_.LinkText })
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
    $btnAcknowledge.Add_Click({ $EULA.DialogResult = [System.Windows.Forms.DialogResult]::Yes })

    $btnCancel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnCancel.Location = New-Object System.Drawing.Point(669, 415)
    $btnCancel.Name = "btnCancel"
    $btnCancel.Size = New-Object System.Drawing.Size(119, 23)
    $btnCancel.TabIndex = 2
    if ($mode -ne 0) {
        $btnCancel.Text = "Close"
    }
    else {
        $btnCancel.Text = "Decline"
    }
    $btnCancel.UseVisualStyleBackColor = $True
    $btnCancel.Add_Click({ $EULA.DialogResult = [System.Windows.Forms.DialogResult]::No })

    $EULA.AutoScaleDimensions = New-Object System.Drawing.SizeF(6.0, 13.0)
    $EULA.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    $EULA.ClientSize = New-Object System.Drawing.Size(800, 450)
    $EULA.Controls.Add($btnCancel)
    $EULA.Controls.Add($richTextBox1)
    if ($mode -ne 0) {
        $EULA.AcceptButton = $btnCancel
    }
    else {
        $EULA.Controls.Add($btnAcknowledge)
        $EULA.AcceptButton = $btnAcknowledge
        $EULA.CancelButton = $btnCancel
    }
    $EULA.ResumeLayout($false)
    $EULA.Size = New-Object System.Drawing.Size(800, 650)

    Return ($EULA.ShowDialog())
}

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
        New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force | Out-Null
    }
    else {
        if ($eulaAccepted -eq "No") {
            $eulaAccepted = ShowEULAPopup($mode)
            if ($eulaAccepted -eq [System.Windows.Forms.DialogResult]::Yes) {
                $eulaAccepted = "Yes"
                New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force | Out-Null
            }
        }
    }
    return $eulaAccepted
}
#end region

#Region MAIN

## EULA
if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
    Start-Transcript -Path $Script:ADPerfLog
}

Write-Host "ADPerfCollector v$Script:Version"

# Show EULA if needed.
If ($AcceptEULA) {
    $eulaAccepted = ShowEULAIfNeeded "AD Perf Data Collection Tool" 2  # Silent accept mode.
}
Else {
    $eulaAccepted = ShowEULAIfNeeded "AD Perf Data Collection Tool" 0  # Show EULA popup at first run.
}

if ($eulaAccepted -eq "No") {
    Write-Error "EULA not accepted, exiting!"
    exit -1
}

#Data save Location
try {
    $exists = Test-Path $Script:ADPerfFolder
    if ($exists) {
        Write-Log "`"$Script:ADPerfFolder`" Already exists - using existing folder"
    }
    else {
        New-Item $Script:ADPerfFolder -Type Directory -ErrorAction Stop | Out-Null
        Write-Log "Created AD Perf Data Folder"
    }
}
catch {
    Write-Log "Error handling save path script switch: (Path:`"$($Script:ADPerfFolder)`")`nExceptionMessage$($_.Exception.Message)"
    Write-Log "Terminating script execution."
    break
}

# Normalizing backwards compatibility
try {
    $ScenarioNumber = [Convert]::ToInt32($Scenario, 10)
    $Scenario = $Script:SupportedScenarios[$ScenarioNumber]
}
catch {
    # NOP
}

# Create hashtables for the english and local perf counter names
$Script:engNameHashtable = @{}
$Script:locNameHashtable = @{}
$Script:PerfcounterHashInitialized = $false

if ($Scenario -eq "Interactive") {
    ADPerfMenu
    $Script:Interactive = $true
    $Choice = Read-Host "Choose the scenario you are troubleshooting"
    if ($Choice.ToLower() -eq "q") { return }
    $Selection = $Script:SupportedScenarios[$Choice]
    if ($null -eq $Selection -or "Interactive" -eq $Selection) {
        Write-Error "Invalid selection $Selection"
        return
    }
}
else {
    $Selection = $Scenario
    # Checking for thresholds
    if (($Selection -eq "CpuTrigger" -or $Selection -eq "MemoryTrigger") -and $Threshold -eq 0) {
        throw "FATAL: -Threshold must be supplied in scenarios CpuTrigger & MemoryTrigger"
    }

    if ($Threshold -ne 0) {
        $Script:TriggerThreshold = $Threshold
        $Script:TriggerScenario = $true
    }

    if ($DelayStop -ne 0) {
        $Script:TriggerScenario = $true
        $Script:TriggeredTimerLength = $DelayStop
    }
}

$DateTime = Get-Date -Format yyyyMMddTHHmmss
$Script:DataPath = "$Script:ADPerfFolder\$env:computername`_$DateTime`_Scenario_$Selection"

if ($Selection -ne "Stop") {
    New-Item $Script:DataPath -Type Directory | Out-Null
}

$ComputerInfo = Get-ComputerInfo

# Get machine role
if (Get-Service NTDS -ErrorAction SilentlyContinue) {
    $Script:IsDC = $true
    Write-Log "Detected running on Domain Controller"
}
else {
    Write-Log "Detected running on Client or Member Server"
}

$Script:DumpType = $DumpPreference

# Run Security verifications and set script-scoped variables for later use
PreTraceVerification

switch ($Selection) {
    "HighCpu" { HighCpuDataCollection }
    "HighCpuTrigger" { HighCpuDataCollectionTriggerStart }
    "HighMemory" { HighMemoryDataCollection }
    "HighMemoryTrigger" { HighMemoryDataCollectionTriggerStart }
    "HighHandle" { HighLsassHandleCountDataCollection }
    "ATQ" {
        if (!$Script:IsDC) { throw "This scenario is only supported on Domain Controllers" }
        ATQThreadDataCollection
    }
    "SDW" { SourceDcWorkloadCollection }
    "Baseline" { BaseLineDataCollection }
    "BaselineLong" { LongBaseLineCollection }
    "Stop" { StopFailedTracing }
    'q' {}
}

if ($Selection -ne "Stop") {
    Write-Log "Copying Data to `"$Script:ADPerfFolder`" and performing cleanup"
    CollectAuxData
    Write-Log "Data copy is finished, please zip the `"$Script:DataPath`" folder and upload to DTM"
}

if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
    Stop-Transcript
    Move-Item $Script:ADPerfLog $Script:DataPath
}

##MAIN

# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCEs5LbSJOSKtAZ
# 0BXgE0mksTbtIy80Ne51e0xyBxtHkKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOfS/XzcXYld4ubDHo4JaGg/
# khfs2sINo9XXQAxfYDlDMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEArbo2Hmfi/i3z7SsR4QZFjBzQ5LV1z4FhSaqCQXvREXjzaZJ4dNUZ4C/K
# v4BkttPCZDcj5YpRdQG4maJ5Yatl0Ue9Sek5kJH7AFDW2ugW8m1JD1WSBq4zKFf2
# EgxfNMcBzheRovjCc0gHdleMViNoHC1IArpLPc4hOyNUpLoSPLRAZN0e08VCotyf
# CWVCnAx20NcFyQ0FB8Q8IqFNRnY6T2/DFjkwJuzYyXc8pSyZmBu8nfI7zKEPBX7D
# XIPnZwBxFAiOZdN1NHZGGm8S/412LZc5sPIFAINhwsscahHhBztNEAjlw+SoGoZ8
# 29auCkSofQP6tCK6MTf4cRHGr6Tbi6GCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCCFdyBVU7WxkoPohl3NGvpaZcULYeLIlCOMADzHeLFIzAIGZlc8wh8B
# GBMyMDI0MDYxMjE1MDAzNy4yOTVaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# Ojg2REYtNEJCQy05MzM1MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHdXVcdldStqhsAAQAAAd0wDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjMx
# MDEyMTkwNzA5WhcNMjUwMTEwMTkwNzA5WjCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo4NkRGLTRC
# QkMtOTMzNTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKhOA5RE6i53nHURH4lnfKLp
# +9JvipuTtctairCxMUSrPSy5CWK2DtriQP+T52HXbN2g7AktQ1pQZbTDGFzK6d03
# vYYNrCPuJK+PRsP2FPVDjBXy5mrLRFzIHHLaiAaobE5vFJuoxZ0ZWdKMCs8acjhH
# UmfaY+79/CR7uN+B4+xjJqwvdpU/mp0mAq3earyH+AKmv6lkrQN8zgrcbCgHwsqv
# vqT6lEFqYpi7uKn7MAYbSeLe0pMdatV5EW6NVnXMYOTRKuGPfyfBKdShualLo88k
# G7qa2mbA5l77+X06JAesMkoyYr4/9CgDFjHUpcHSODujlFBKMi168zRdLerdpW0b
# BX9EDux2zBMMaEK8NyxawCEuAq7++7ktFAbl3hUKtuzYC1FUZuUl2Bq6U17S4CKs
# qR3itLT9qNcb2pAJ4jrIDdll5Tgoqef5gpv+YcvBM834bXFNwytd3ujDD24P9Dd8
# xfVJvumjsBQQkK5T/qy3HrQJ8ud1nHSvtFVi5Sa/ubGuYEpS8gF6GDWN5/KbveFk
# dsoTVIPo8pkWhjPs0Q7nA5+uBxQB4zljEjKz5WW7BA4wpmFm24fhBmRjV4Nbp+n7
# 8cgAjvDSfTlA6DYBcv2kx1JH2dIhaRnSeOXePT6hMF0Il598LMu0rw35ViUWcAQk
# UNUTxRnqGFxz5w+ZusMDAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUbqL1toyPUdpF
# yyHSDKWj0I4lw/EwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAC5U2bINLgXIHWbM
# cqVuf9jkUT/K8zyLBvu5h8JrqYR2z/eaO2yo1Ooc9Shyvxbe9GZDu7kkUzxSyJ1I
# ZksZZw6FDq6yZNT3PEjAEnREpRBL8S+mbXg+O4VLS0LSmb8XIZiLsaqZ0fDEcv3H
# eA+/y/qKnCQWkXghpaEMwGMQzRkhGwcGdXr1zGpQ7HTxvfu57xFxZX1MkKnWFENJ
# 6urd+4teUgXj0ngIOx//l3XMK3Ht8T2+zvGJNAF+5/5qBk7nr079zICbFXvxtidN
# N5eoXdW+9rAIkS+UGD19AZdBrtt6dZ+OdAquBiDkYQ5kVfUMKS31yHQOGgmFxuCO
# zTpWHalrqpdIllsy8KNsj5U9sONiWAd9PNlyEHHbQZDmi9/BNlOYyTt0YehLbDov
# mZUNazk79Od/A917mqCdTqrExwBGUPbMP+/vdYUqaJspupBnUtjOf/76DAhVy8e/
# e6zR98PkplmliO2brL3Q3rD6+ZCVdrGM9Rm6hUDBBkvYh+YjmGdcQ5HB6WT9Rec8
# +qDHmbhLhX4Zdaard5/OXeLbgx2f7L4QQQj3KgqjqDOWInVhNE1gYtTWLHe4882d
# /k7Lui0K1g8EZrKD7maOrsJLKPKlegceJ9FCqY1sDUKUhRa0EHUW+ZkKLlohKrS7
# FwjdrINWkPBgbQznCjdE2m47QjTbMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
# NkRGLTRCQkMtOTMzNTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUANiNHGWXbNaDPxnyiDbEOciSjFhCggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOoULvUwIhgPMjAyNDA2MTIyMjI4MDVaGA8yMDI0MDYxMzIyMjgwNVowdDA6Bgor
# BgEEAYRZCgQBMSwwKjAKAgUA6hQu9QIBADAHAgEAAgIDcDAHAgEAAgISpDAKAgUA
# 6hWAdQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAID
# B6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAEsES+vkY7RFE4pSdasf
# FUsfB5sIj176Yd2zfIg+0dpukCHJO0pPcS+PotSR6sgDDlSWByoCpgngzP80vUzN
# 6XraWMbKj8Z1tPZYlgAw/n3QSRlY5pPdJjwiRL8XLeACp7WHSoaCEDvuSuIsu6qK
# 7v+6t2p+OBYgNeP0C7YetvOoMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBIDIwMTACEzMAAAHdXVcdldStqhsAAQAAAd0wDQYJYIZIAWUDBAIB
# BQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQx
# IgQgKaNq5AGGd2ZJUarhwjOeyB+Wig7bXzK88kOf07+KIo0wgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCBh/w4tmmWsT3iZnHtH0Vk37UCN02lRxY+RiON6wDFj
# ZjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB3V1X
# HZXUraobAAEAAAHdMCIEIKoFwkM2tcXe/hLiUvslXtKcxZcG0TYigMieaAZ8DoRm
# MA0GCSqGSIb3DQEBCwUABIICAAAw4djRHT9IRAmHOpZHTRrlq32lJ6r2SFlU1Ifp
# /32M1yt+Vydp7hp6+VVn+JjPckq6b9TtKt6z9WiRS2J1yOBpjkQj7ktZwCFTDneM
# LDKQ0yLcHp2qtDDEqi3YhNS3jhMbPvIvEVK2ACP8MbdGK4YcIm7n6J4hw0tw7Upv
# YEGj7zWAVSbkWw2RvlqezkTRg8wYm0BsRNTkDZ05mUoSjH4JevkJRuW053ZjWdES
# A+RqZp5S9VvkAEvqbuK39BBMRaffN1X0h747+hm04KGi6OBzvKYEYP6DNdOmA523
# OdrITddNxoydNnGobAJ+1lBZhJR4ZLN3OYvv/V+zrDMlKO4Zr5XmHzHTJKuVNaYE
# WBJ+ZV++/GPj+8cwlQlQfUVKQJ8QLkBdvj7wZuEbCFdxSbFRdHIzFz4mSC6mDG6/
# 32sfaLJzhTkxl50+sLBn27u9wSJZFcm9Yq7fRxGwzqUe8CIr1cLg6h3eKgmL5wRT
# 5LyoofOiagVaYZ1Xc+lqlZIWDEfxrG7isf9ma+kLwets7Kxq3t2sCLI7ad2dKtlj
# hZ4mQ1KX+hPNEmzjcpMe2s6YnvDj15HMame+dYB79Hq/RFK0P9wHaLfz/UZFNwTd
# hqhEZX3O8mK0/Gi++nefFoqKTwd6jgf6B0V5ycoplUDkff0iKM7jcwAYCT+xeZFh
# RdM5
# SIG # End signature block
