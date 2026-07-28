# Collect-Commons 20230623

Function Write-Log {
  param( [string] $msg )

  $msg = (get-date).ToString("yyyyMMdd HH:mm:ss.fff") + " " + $msg
  Write-Host $msg
  $msg | Out-File -FilePath $global:outfile -Append
}

Function ExecQuery {
  param(
    [string] $NameSpace,
    [string] $Query
  )
  Write-Log ("Executing query " + $Query)
  if ($PSVersionTable.psversion.ToString() -ge "3.0") {
    $ret = Get-CimInstance -Namespace $NameSpace -Query $Query -ErrorAction Continue 2>>$errfile
  } else {
    $ret = Get-WmiObject -Namespace $NameSpace -Query $Query -ErrorAction Continue 2>>$errfile
  }
  Write-Log (($ret | Measure-Object).count.ToString() + " results")
  return $ret
}

if ($PSVersionTable.PSEdition -eq "Core") {
  Add-Type -MemberDefinition @'
  [DllImport("kernel32.dll", SetLastError = true, CallingConvention = CallingConvention.Winapi)] [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool IsWow64Process(
    [In] System.IntPtr hProcess,
    [Out, MarshalAs(UnmanagedType.Bool)] out bool wow64Process);
'@ -Name NativeMethods -Namespace Kernel32
}

Function Get-ProcBitness {
  param ([int] $id)
  $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
  if ($proc) {
    if ($PSVersionTable.PSEdition -eq "Core") {
      $is32Bit = [int]0
      if ([Kernel32.NativeMethods]::IsWow64Process($proc.Handle, [ref]$is32Bit)) {
        if ($is32Bit) {
          return "(x86)"
        } else {
          return "(x64)"
        }
      } else {
        return ""
      }
    } else {
      $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
      if ($proc) {
        Return ("(" + $proc.StartInfo.EnvironmentVariables["PROCESSOR_ARCHITECTURE"] + ")")
      } else {
        Return ""
      }
    }
  } else {
    return ""
  }
}

Function Get-LocalGroupNameBySid {
  param ($SIDString)

  $group = New-Object System.Security.Principal.SecurityIdentifier($SIDString)

  if ($group -ne $null) {
    return $group.Translate([System.Security.Principal.NTAccount]).Value -replace '.+\\'
  } else {
    return $null
  }
}

Function Get-LocalGroupMembers {
  param ($name)
  $ADSI = [ADSI]"WinNT://./$name,group"
  $members = $ADSI.Invoke("Members") | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
  return $members
}

Function GetOwnerCim{
  param( $prc )
  $ret = Invoke-CimMethod -InputObject $prc -MethodName GetOwner
  return ($ret.Domain + "\" + $ret.User)
}

Function GetOwnerWmi{
  param( $prc )
  $ret = $prc.GetOwner()
  return ($ret.Domain + "\" + $ret.User)
}

Function ArchiveLog {
  param( [string] $LogName )
  $cmd = "wevtutil al """+ $global:resDir + "\" + $env:computername + "-" + $LogName + ".evtx"" /l:en-us >>""" + $global:outfile + """ 2>>""" + $errfile + """"
  Write-Log $cmd
  Invoke-Expression $cmd
}

Function Win10Ver {
  param(
    [string] $Build
  )

  # See https://www.osgwiki.com/wiki/WSD_Wiki-CFE_Decrypting_Windows_Release_Names

  if ($build -eq 14393) {
    return " (RS1 / 1607)"
  } elseif ($build -eq 15063) {
    return " (RS2 / 1703)"
  } elseif ($build -eq 16299) {
    return " (RS3 / 1709)"
  } elseif ($build -eq 17134) {
    return " (RS4 / 1803)"
  } elseif ($build -eq 17763) {
    return " (RS5 / 1809)"
  } elseif ($build -eq 18362) {
    return " (19H1 / 1903)"
  } elseif ($build -eq 18363) {
    return " (19H2 / 1909)"    
  } elseif ($build -eq 19041) {
    return " (2004 / vb)"  
  } elseif ($build -eq 19042) {
    return " (20H2 / vb)"  
  } elseif ($build -eq 19043) {
    return " (21H1 / vb)"  
  } elseif ($build -eq 19044) {
    return " (21H2 / vb)"  
  } elseif ($build -eq 19045) {
    return " (22H2 / vb)"  
  } elseif ($build -eq 20348) {
    return " (21H1 / fe)"  
  } elseif ($build -eq 22000) {
    return " (21H2 / co / sv)"  
  } elseif ($build -eq 22621) {
    return " (22H2 / ni / sv2)"  
  }
}

Function ListProcsAndSvcs {
  $proc = ExecQuery -Namespace "root\cimv2" -Query "select Name, CreationDate, ProcessId, ParentProcessId, SessionId, WorkingSetSize, UserModeTime, KernelModeTime, ThreadCount, HandleCount, CommandLine, ExecutablePath from Win32_Process"
  if ($PSVersionTable.psversion.ToString() -ge "3.0") {
    $StartTime= @{e={$_.CreationDate.ToString("yyyyMMdd HH:mm:ss")};n="Start time"}
    $Owner = @{N="User";E={(GetOwnerCim($_))}}
  } else {
    $StartTime= @{n='StartTime';e={$_.ConvertToDateTime($_.CreationDate)}}
    $Owner = @{N="User";E={(GetOwnerWmi($_))}}
  }

  if ($proc) {
    $proc | Sort-Object Name |
    Format-Table -AutoSize -property @{e={$_.ProcessId};Label="PID"}, @{e={$_.ParentProcessId};n="Parent"}, Name, @{e={$_.SessionId};n="Session"},
    @{N="WorkingSet";E={"{0:N0}" -f ($_.WorkingSetSize/1kb)};a="right"},
    @{e={[DateTime]::FromFileTimeUtc($_.UserModeTime).ToString("HH:mm:ss")};n="UserTime"}, @{e={[DateTime]::FromFileTimeUtc($_.KernelModeTime).ToString("HH:mm:ss")};n="KernelTime"},
    @{N="Threads";E={$_.ThreadCount}}, @{N="Handles";E={($_.HandleCount)}}, $StartTime, $Owner, CommandLine |
    Out-String -Width 500 | Out-File -FilePath ($global:resDir + "\processes.txt")

    Write-Log "Retrieving file version of running binaries"
    $binlist = $proc | Group-Object -Property ExecutablePath
    foreach ($file in $binlist) {
      if ($file.Name) {
        FileVersion -Filepath ($file.name) -Log $true
      }
    }

    Write-Log "Collecting services details"
    $svc = ExecQuery -NameSpace "root\cimv2" -Query "select  ProcessId, DisplayName, StartMode,State, Name, PathName, StartName from Win32_Service"

    if ($svc) {
      $svc | Sort-Object DisplayName | Format-Table -AutoSize -Property ProcessId, DisplayName, StartMode,State, Name, PathName, StartName |
      Out-String -Width 400 | Out-File -FilePath ($global:resDir + "\services.txt")
    }
    return $true
  } else {
    return $false
  }
}

Function CollectSystemInfoNoWMI {
  Write-Log "Collecting system information"
  $pad = 27

  $ctr = Get-Counter -Counter "\Memory\Pool Paged Bytes" -ErrorAction Continue 2>>$global:errfile
  $PoolPaged = $ctr.CounterSamples[0].CookedValue 
  $ctr = Get-Counter -Counter "\Memory\Pool Nonpaged Bytes" -ErrorAction Continue 2>>$global:errfile
  $PoolNonPaged = $ctr.CounterSamples[0].CookedValue 
  $proc = Get-Process | Select-Object Name, ID, Handles, @{Name='ThreadCount';Expression ={$_.Threads.Count}}

  "Computer name".PadRight($pad) + " : " + $env:COMPUTERNAME | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Processor".PadRight($pad) + " : " + $env:PROCESSOR_IDENTIFIER | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Processors cores".PadRight($pad) + " : " + $env:NUMBER_OF_PROCESSORS | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Pool Paged / NonPaged".PadRight($pad) + " : " + ("{0:N0}" -f ($PoolPaged/1mb)) + " MB / " + ("{0:N0}" -f ($PoolNonPaged/1mb)) + " MB" | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Total number of processes".PadRight($pad) + " : " + ("{0:N0}" -f ($proc.Count))| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Total number of threads".PadRight($pad) + " : " + ("{0:N0}" -f ($proc | Measure-Object -Property ThreadCount -Sum).Sum)| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Total number of handles".PadRight($pad) + " : " + ("{0:N0}" -f ($proc | Measure-Object -Property Handles -Sum).Sum)| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Operating System".PadRight($pad) + " : " + [System.Environment]::OSVersion.VersionString | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Build Number".PadRight($pad) + " : " + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ubr + (Win10Ver $OS.BuildNumber)| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Time zone".PadRight($pad) + " : " + [System.TimeZoneInfo]::Local.DisplayName | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Local time".PadRight($pad) + " : " + (Get-Date) | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "NetBIOS Domain name".PadRight($pad) + " : " + (GetNBDomainName) | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append

  ExpEnvVar

  Invoke-CustomCommand -Command "dsregcmd /status" -DestinationFile "DSRegStatus.txt"
}

Function CollectSystemInfoWMI {
  Write-Log "Collecting system information"
  $pad = 27
  $OS = ExecQuery -Namespace "root\cimv2" -Query "select Caption, CSName, OSArchitecture, BuildNumber, InstallDate, LastBootUpTime, LocalDateTime, TotalVisibleMemorySize, FreePhysicalMemory, SizeStoredInPagingFiles, FreeSpaceInPagingFiles, MUILanguages from Win32_OperatingSystem"
  $CS = ExecQuery -Namespace "root\cimv2" -Query "select Model, Manufacturer, SystemType, NumberOfProcessors, NumberOfLogicalProcessors, TotalPhysicalMemory, DNSHostName, Domain, DomainRole from Win32_ComputerSystem"
  $BIOS = ExecQuery -Namespace "root\cimv2" -query "select BIOSVersion, Manufacturer, ReleaseDate, SMBIOSBIOSVersion from Win32_BIOS"
  $TZ = ExecQuery -Namespace "root\cimv2" -Query "select Description from Win32_TimeZone"
  $PR = ExecQuery -Namespace "root\cimv2" -Query "select Name, Caption from Win32_Processor"
  $proc = Get-Process | Select-Object Name, ID, Handles, @{Name='ThreadCount';Expression ={$_.Threads.Count}}

  $ctr = Get-Counter -Counter "\Memory\Pool Paged Bytes" -ErrorAction Continue 2>>$global:errfile
  $PoolPaged = $ctr.CounterSamples[0].CookedValue 
  $ctr = Get-Counter -Counter "\Memory\Pool Nonpaged Bytes" -ErrorAction Continue 2>>$global:errfile
  $PoolNonPaged = $ctr.CounterSamples[0].CookedValue 

  "Computer name".PadRight($pad) + " : " + $OS.CSName | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Model".PadRight($pad) + " : " + $CS.Model | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Manufacturer".PadRight($pad) + " : " + $CS.Manufacturer | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "BIOS Version".PadRight($pad) + " : " + $BIOS.BIOSVersion | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "BIOS Manufacturer".PadRight($pad) + " : " + $BIOS.Manufacturer | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "BIOS Release date".PadRight($pad) + " : " + $BIOS.ReleaseDate | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "SMBIOS Version".PadRight($pad) + " : " + $BIOS.SMBIOSBIOSVersion | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "SystemType".PadRight($pad) + " : " + $CS.SystemType | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Processor".PadRight($pad) + " : " + $PR.Name + " / " + $PR.Caption | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Processors physical/logical".PadRight($pad) + " : " + $CS.NumberOfProcessors + " / " + $CS.NumberOfLogicalProcessors | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Memory physical/visible".PadRight($pad) + " : " + ("{0:N0}" -f ($CS.TotalPhysicalMemory/1mb)) + " MB / " + ("{0:N0}" -f ($OS.TotalVisibleMemorySize/1kb)) + " MB" | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Pool Paged / NonPaged".PadRight($pad) + " : " + ("{0:N0}" -f ($PoolPaged/1mb)) + " MB / " + ("{0:N0}" -f ($PoolNonPaged/1mb)) + " MB" | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Free physical memory".PadRight($pad) + " : " + ("{0:N0}" -f ($OS.FreePhysicalMemory/1kb)) + " MB" | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Paging files size / free".PadRight($pad) + " : " + ("{0:N0}" -f ($OS.SizeStoredInPagingFiles/1kb)) + " MB / " + ("{0:N0}" -f ($OS.FreeSpaceInPagingFiles/1kb)) + " MB" | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Total number of processes".PadRight($pad) + " : " + ("{0:N0}" -f ($proc.Count))| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Total number of threads".PadRight($pad) + " : " + ("{0:N0}" -f ($proc | Measure-Object -Property ThreadCount -Sum).Sum)| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Total number of handles".PadRight($pad) + " : " + ("{0:N0}" -f ($proc | Measure-Object -Property Handles -Sum).Sum)| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Operating System".PadRight($pad) + " : " + $OS.Caption + " " + $OS.OSArchitecture | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Build Number".PadRight($pad) + " : " + $OS.BuildNumber + "." + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ubr + (Win10Ver $OS.BuildNumber)| Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Time zone".PadRight($pad) + " : " + $TZ.Description | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Language packs".PadRight($pad) + " : " + ($OS.MUILanguages -join " ") | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Install date".PadRight($pad) + " : " + $OS.InstallDate | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Last boot time".PadRight($pad) + " : " + $OS.LastBootUpTime | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "Local time".PadRight($pad) + " : " + $OS.LocalDateTime | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "DNS Hostname".PadRight($pad) + " : " + $CS.DNSHostName | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "DNS Domain name".PadRight($pad) + " : " + $CS.Domain | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  "NetBIOS Domain name".PadRight($pad) + " : " + (GetNBDomainName) | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append
  $roles = "Standalone Workstation", "Member Workstation", "Standalone Server", "Member Server", "Backup Domain Controller", "Primary Domain Controller"
  "Domain role".PadRight($pad) + " : " + $roles[$CS.DomainRole] | Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append

  $drives = @()
  $drvtype = "Unknown", "No Root Directory", "Removable Disk", "Local Disk", "Network Drive", "Compact Disc", "RAM Disk"
  $Vol = ExecQuery -NameSpace "root\cimv2" -Query "select * from Win32_LogicalDisk"
  foreach ($disk in $vol) {
    $drv = New-Object PSCustomObject
    $drv | Add-Member -type NoteProperty -name Letter -value $disk.DeviceID 
    $drv | Add-Member -type NoteProperty -name DriveType -value $drvtype[$disk.DriveType]
    $drv | Add-Member -type NoteProperty -name VolumeName -value $disk.VolumeName 
    $drv | Add-Member -type NoteProperty -Name TotalMB -Value ($disk.size)
    $drv | Add-Member -type NoteProperty -Name FreeMB -value ($disk.FreeSpace)
    $drives += $drv
  }
  $drives | 
  Format-Table -AutoSize -property Letter, DriveType, VolumeName, @{N="TotalMB";E={"{0:N0}" -f ($_.TotalMB/1MB)};a="right"}, @{N="FreeMB";E={"{0:N0}" -f ($_.FreeMB/1MB)};a="right"} |
  Out-File -FilePath ($global:resDir + "\SystemInfo.txt") -Append

  ExpEnvVar

  Invoke-CustomCommand -Command "dsregcmd /status" -DestinationFile "DSRegStatus.txt"
}

Function ExpEnvVar {
  Write-Log "Exporing environment variables"
  $env = Get-ChildItem env:
  foreach ($var in $env) {
    ($var.name  + " = " + $var.Value) | Out-File -FilePath ($global:resDir + "\EnvironmentVariables.txt") -Append
  }
}

Function ExpRegFeatureManagement {
  Write-Log "Exporting registry key HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides "
  $cmd = "reg export ""HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides "" """+ $global:resDir + "\FeatureManagement.reg.txt"" /y >>""" + $global:outfile + """ 2>>""" + $global:errfile + """"
  Invoke-Expression $cmd
}

Add-Type -MemberDefinition @"
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetApiBufferFree(IntPtr Buffer);
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern int NetGetJoinInformation(
  string server,
  out IntPtr NameBuffer,
  out int BufferType);
"@ -Namespace Win32Api -Name NetApi32

Function GetNBDomainName {
  $pNameBuffer = [IntPtr]::Zero
  $joinStatus = 0
  $apiResult = [Win32Api.NetApi32]::NetGetJoinInformation(
    $null,               # lpServer
    [Ref] $pNameBuffer,  # lpNameBuffer
    [Ref] $joinStatus    # BufferType
  )
  if ( $apiResult -eq 0 ) {
    [Runtime.InteropServices.Marshal]::PtrToStringAuto($pNameBuffer)
    [Void] [Win32Api.NetApi32]::NetApiBufferFree($pNameBuffer)
  }
}

$UserDumpCode=@'
using System;
using System.Runtime.InteropServices;

namespace MSCOLLECT
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

        public static bool GenerateUserDump(uint ProcessID, string dumpFileName)
        {
            System.IO.FileStream fileStream = System.IO.File.OpenWrite(dumpFileName);

            if (fileStream == null)
            {
                return false;
            }

            // 0x1F0FFF = PROCESS_ALL_ACCESS
            IntPtr ProcessHandle = OpenProcess(0x1F0FFF, false, ProcessID);

            if(ProcessHandle == null)
            {
                return false;
            }

            MINIDUMP_TYPE Flags =
                MINIDUMP_TYPE.MiniDumpWithFullMemory |
                MINIDUMP_TYPE.MiniDumpWithFullMemoryInfo |
                MINIDUMP_TYPE.MiniDumpWithHandleData |
                MINIDUMP_TYPE.MiniDumpWithUnloadedModules |
                MINIDUMP_TYPE.MiniDumpWithThreadInfo;

            bool Result = MiniDumpWriteDump(ProcessHandle,
                                 ProcessID,
                                 fileStream.SafeFileHandle,
                                 (uint)Flags,
                                 IntPtr.Zero,
                                 IntPtr.Zero,
                                 IntPtr.Zero);

            fileStream.Close();
            return Result;
        }
    }
}
'@
add-type -TypeDefinition $UserDumpCode -Language CSharp

Function CreateProcDump {
  param( $ProcID, $DumpFolder, $filename)
  if (-not (Test-Path $DumpFolder)) {
    Write-host ("The folder " + $DumpFolder + " does not exist")
    return $false
  }
  $DumpCreated = $false

  $proc = Get-Process -ID $ProcID
  if (-not $proc) {
    Write-Log "The process with PID $ProcID is not running"
    return $false
  }
  if (-not $Filename) { $filename = $proc.Name }
  $DumpFile = $DumpFolder + "\" + $filename + "-" + $ProcID + "_" + (get-date).ToString("yyyyMMdd_HHmmss") + ".dmp"
  
  if (Test-Path ($global:root + "\procdump.exe")) {
    $ProcDumpPath = $global:root + "\procdump.exe"
    Write-Log ("ProcDump found in " + $ProcDumpPath)
  } else {
    if (Test-Path (($global:root | Split-Path) + "\bin\procdump.exe")) {
      $ProcDumpPath = ($global:root | Split-Path) + "\bin\procdump.exe"
      Write-Log ("ProcDump found in " + $ProcDumpPath)
    }
  }

  if ($ProcDumpPath) {
    $cmd = "&""" + $ProcDumpPath + """ -accepteula -ma $ProcID """ + $DumpFile + """ >>""" + $global:outfile + """ 2>>""" + $errfile + """"
    Write-Log $cmd
    Invoke-Expression $cmd

    if (Test-Path $DumpFile) {
      if ((Get-Item $DumpFile).length -gt 1000) {
        $DumpCreated = $true
        Write-Log "Successfully created $DumpFile with ProcDump"
      } else {
        Write-Log "The created dump file is too small, removing it"
        Remove-Item $DumpFile
      }
    } else {
      Write-Log "Cannot find the dump file"
    }
  }

  if (-not $DumpCreated) {
    Write-Log "Cannot create the dump with ProcDump, trying the backup method"
    if ([MSCOLLECT.UserDump]::GenerateUserDump($ProcID, $DumpFile)) {
      Write-Log ("The dump for the Process ID $ProcID was generated as $DumpFile")
    } else {
      Write-Log "Failed to create the dump for the Process ID $ProcID"
    }
  }
}

$FindPIDCode=@'
using System;
using System.ServiceProcess;
using System.Diagnostics;
using System.Threading;
using System.Runtime.InteropServices;

namespace MSCOLLECT {
  public static class FindService {

    public static void Main(){
	  // empty function
	}

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct SERVICE_STATUS_PROCESS {
      public int serviceType;
      public int currentState;
      public int controlsAccepted;
      public int win32ExitCode;
      public int serviceSpecificExitCode;
      public int checkPoint;
      public int waitHint;
      public int processID;
      public int serviceFlags;
    }

    [DllImport("advapi32.dll")]
    public static extern bool QueryServiceStatusEx(IntPtr serviceHandle, int infoLevel, IntPtr buffer, int bufferSize, out int bytesNeeded);

    public static int FindServicePid(string SvcName) {
      ServiceController sc = new ServiceController(SvcName);
      if (sc == null) {
        return -1;
      }
                  
      IntPtr zero = IntPtr.Zero;
      int SC_STATUS_PROCESS_INFO = 0;
      int ERROR_INSUFFICIENT_BUFFER = 0;

      Int32 dwBytesNeeded;
      System.IntPtr hs = sc.ServiceHandle.DangerousGetHandle();

      // Call once to figure the size of the output buffer.
      QueryServiceStatusEx(hs, SC_STATUS_PROCESS_INFO, zero, 0, out dwBytesNeeded);
      if (Marshal.GetLastWin32Error() == ERROR_INSUFFICIENT_BUFFER) {
        // Allocate required buffer and call again.
        zero = Marshal.AllocHGlobal((int)dwBytesNeeded);

        if (QueryServiceStatusEx(hs, SC_STATUS_PROCESS_INFO, zero, dwBytesNeeded, out dwBytesNeeded)) {
          SERVICE_STATUS_PROCESS ssp = (SERVICE_STATUS_PROCESS)Marshal.PtrToStructure(zero, typeof(SERVICE_STATUS_PROCESS));
          return (int)ssp.processID;
        }
      }
      return -1;
    }
  }
}
'@
if ($PSVersionTable.PSEdition -eq "Core") {
  add-type -TypeDefinition $FindPIDCode -Language CSharp -ReferencedAssemblies System.ServiceProcess.ServiceController, System.ComponentModel.Primitives
} else {
  add-type -TypeDefinition $FindPIDCode -Language CSharp -ReferencedAssemblies System.ServiceProcess
}

Function FindServicePid {
  param( $SvcName)
  try {
    $pidsvc = [MSCOLLECT.FindService]::FindServicePid($SvcName)
    return $pidsvc
  }
  catch {
    return $null
  }
}

Function FileVersion {
  param(
    [string] $FilePath,
    [bool] $Log = $false
  )
  if (Test-Path -Path $FilePath) {
    $fileobj = Get-item $FilePath
    $filever = $fileobj.VersionInfo.FileMajorPart.ToString() + "." + $fileobj.VersionInfo.FileMinorPart.ToString() + "." + $fileobj.VersionInfo.FileBuildPart.ToString() + "." + $fileobj.VersionInfo.FilePrivatepart.ToString()

    if ($log) {
      $LogFile = $global:resDir + "\FilesVersion.csv"
      if (-not (Test-Path -Path $LogFile)) {
        "File,Version,Date,Manufacturer,Description" | Out-File -FilePath ($LogFile)
      }
      ($FilePath + "," + $filever + "," + $fileobj.CreationTime.ToString("yyyyMMdd HH:mm:ss") + "," + $fileobj.VersionInfo.CompanyName + "," + $fileobj.VersionInfo.FileDescription) | Out-File -FilePath ($LogFile) -Append
    }
    return $filever | Out-Null
  } else {
    return ""
  }
}

Function FindSep {
  param( [string]$FindIn, [string]$Left,[string]$Right )

  if ($left -eq "") {
    $Start = 0
  } else {
    $Start = $FindIn.IndexOf($Left) 
    if ($Start -gt 0 ) {
      $Start = $Start + $Left.Length
    } else {
       return ""
    }
  }

  if ($Right -eq "") {
    $End = $FindIn.Substring($Start).Length
  } else {
    $End = $FindIn.Substring($Start).IndexOf($Right)
    if ($end -le 0) {
      return ""
    }
  }
  $Found = $FindIn.Substring($Start, $End)
  return $Found
}

[void][System.Reflection.Assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')

function ShowEULAPopup($mode)
{
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

function ShowEULAIfNeeded($toolName, $mode)
{
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
        New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force | Out-Null
	}
	else
	{
		if($eulaAccepted -eq "No")
		{
			$eulaAccepted = ShowEULAPopup($mode)
			if($eulaAccepted -eq [System.Windows.Forms.DialogResult]::Yes)
			{
	        		$eulaAccepted = "Yes"
	        		New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force | Out-Null
			}
		}
	}
	return $eulaAccepted
}

function Export-RegistryKey {
  param (
    [string]$KeyPath,
    [string]$DestinationFile
  )

  if (Test-Path -Path $KeyPath) {
    Write-Log "Exporting registry key ${KeyPath}"
    $cmd = "reg export ""$($KeyPath -replace ':','')"" """ + $global:resDir + "\${DestinationFile}""" + $global:RdrOut + $global:RdrErr
    Invoke-Expression $cmd
  }
  else {
    Write-Log "The ${KeyPath} registry key does not exist on this device."
  }
}

function Export-EventLog {
  param (
    [string]$LogName
  )
  if (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue) {
    $cmd = "wevtutil epl ""${LogName}"" """ + $resDir + "\" + $env:computername + "-$($LogName -replace '/','_').evtx""" + $global:RdrOut + $global:RdrErr
    Write-Log $cmd
    Invoke-Expression $cmd
    ArchiveLog ($LogName -replace '/', '_')
  }
} 

function Invoke-CustomCommand {
  param (
    [string]$Command,
    [string]$DestinationFile
  )
  
  Write-Log "Getting ${Command} output."
  if ([string]::IsNullOrEmpty($DestinationFile)) {
    $cmd = "${Command}" + $global:RdrErr
  } 
  else {
    $cmd = "${Command} >""" + $global:resDir + "\${DestinationFile}""" + $global:RdrErr
  }
  Write-Log $cmd
  Invoke-Expression ($cmd) | Out-File -FilePath $global:outfile -Append
}

function Deny-IfNotAdmin {
  $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
  if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
    Write-Output "This script needs to be run as Administrator"
    exit
  }
  
} 

Function DecodeError ($res) {
  $out = Invoke-Expression ("certutil /error " + $res)
  return $out[1].Substring($out[1].IndexOf(":")+2)
}

Export-ModuleMember -Function *

# SIG # Begin signature block
# MIIoOQYJKoZIhvcNAQcCoIIoKjCCKCYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1HCq8//osug9e
# ZRC+kSQ7V61gRzmHb3kw21lyQeiJhKCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGgowghoGAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINAN
# DsVMYDOk5n8e7/kaf09I7XkDvw1KWMsM7fV2F0KLMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAC2My33pRqRp43mn+Tl9wndEXL8derGpPYvae
# joq3gvIGHEiFQ6kmzdjhNw8rXMdthluiEICPqU04n0fPS9KzzBN5JppXQWWMYq46
# mPrEv9o3t0uwsKab9PEvJL66wPSGiNUmEbq+//mxCf6zUe88uL0YEje+5VFyF/0X
# 2kFMpVTJaewWxdRDr7NZy5aGJ8IwqOudBr7VaT79HZU5HoI4OLM/QoGhPO+zgDLo
# rmqfImZ4MeCKwi07y2A0HS5y0d/0+ym0dvx17TbSVPlVYlIsOqqV+wGeraHBDU+c
# 70AyKKb1fYYrr+usuzEP4YYu1NrEDHfm4yFnuTbtZnbgzzQBgKGCF5QwgheQBgor
# BgEEAYI3AwMBMYIXgDCCF3wGCSqGSIb3DQEHAqCCF20wghdpAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFSBgsqhkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCAVl63ukwaZdvZpHmtzknikxb8OpGktM2ZY
# BawWRRkXuAIGZkYbygs6GBMyMDI0MDYxMjE1MDA0My40MTRaMASAAgH0oIHRpIHO
# MIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
# IFRTUyBFU046REMwMC0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFNlcnZpY2WgghHqMIIHIDCCBQigAwIBAgITMwAAAehQsIDPK3KZTQAB
# AAAB6DANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDAeFw0yMzEyMDYxODQ1MjJaFw0yNTAzMDUxODQ1MjJaMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046REMwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDhQXdE0WzXG7wzeC9SGdH6
# eVwdGlF6YgpU7weOFBkpW9yuEmJSDE1ADBx/0DTuRBaplSD8CR1QqyQmxRDD/Cdv
# DyeZFAcZ6l2+nlMssmZyC8TPt1GTWAUt3GXUU6g0F0tIrFNLgofCjOvm3G0j482V
# utKS4wZT6bNVnBVsChr2AjmVbGDN/6Qs/EqakL5cwpGel1te7UO13dUwaPjOy0Wi
# 1qYNmR8i7T1luj2JdFdfZhMPyqyq/NDnZuONSbj8FM5xKBoar12ragC8/1CXaL1O
# MXBwGaRoJTYtksi9njuq4wDkcAwitCZ5BtQ2NqPZ0lLiQB7O10Bm9zpHWn9x1/Hm
# dAn4koMWKUDwH5sd/zDu4vi887FWxm54kkWNvk8FeQ7ZZ0Q5gqGKW4g6revV2IdA
# xBobWdorqwvzqL70WdsgDU/P5c0L8vYIskUJZedCGHM2hHIsNRyw9EFoSolDM+yC
# edkz69787s8nIp55icLfDoKw5hak5G6MWF6d71tcNzV9+v9RQKMa6Uwfyquredd5
# sqXWCXv++hek4A15WybIc6ufT0ilazKYZvDvoaswgjP0SeLW7mvmcw0FELzF1/uW
# aXElLHOXIlieKF2i/YzQ6U50K9dbhnMaDcJSsG0hXLRTy/LQbsOD0hw7FuK0nmzo
# tSx/5fo9g7fCzoFjk3tDEwIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFPo5W8o980kM
# fRVQba6T34HwelLaMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQCWfcJm2rwXtPi7
# 4km6PKAkni9+BWotq+QtDGgeT5F3ro7PsIUNKRkUytuGqI8thL3Jcrb03x6DOppY
# JEA+pb6o2qPjFddO1TLqvSXrYm+OgCLL+7+3FmRmfkRu8rHvprab0O19wDbukgO8
# I5Oi1RegMJl8t5k/UtE0Wb3zAlOHnCjLGSzP/Do3ptwhXokk02IvD7SZEBbPboGb
# tw4LCHsT2pFakpGOBh+ISUMXBf835CuVNfddwxmyGvNSzyEyEk5h1Vh7tpwP7z7r
# J+HsiP4sdqBjj6Avopuf4rxUAfrEbV6aj8twFs7WVHNiIgrHNna/55kyrAG9Yt19
# CPvkUwxYK0uZvPl2WC39nfc0jOTjivC7s/IUozE4tfy3JNkyQ1cNtvZftiX3j5Dt
# +eLOeuGDjvhJvYMIEkpkV68XLNH7+ZBfYa+PmfRYaoFFHCJKEoRSZ3PbDJPBiEhZ
# 9yuxMddoMMQ19Tkyftot6Ez0XhSmwjYBq39DvBFWhlyDGBhrU3GteDWiVd9YGSB2
# WnxuFMy5fbAK6o8PWz8QRMiptXHK3HDBr2wWWEcrrgcTuHZIJTqepNoYlx9VRFvj
# /vCXaAFcmkW1nk7VE+owaXr5RJjryDq9ubkyDq1mdrF/geaRALXcNZbfNXIkhXzX
# A6a8CiamcQW/DgmLJpiVQNriZYCHIDCCB3EwggVZoAMCAQICEzMAAAAVxedrngKb
# SZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIy
# NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXI
# yjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjo
# YH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1y
# aa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v
# 3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pG
# ve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viS
# kR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYr
# bqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlM
# jgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSL
# W6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AF
# emzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIu
# rQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIE
# FgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWn
# G1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEW
# M2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5
# Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBi
# AEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV
# 9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3Js
# Lm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAx
# MC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2
# LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv
# 6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZn
# OlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1
# bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4
# rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU
# 6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDF
# NLB62FD+CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/
# HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdU
# CbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKi
# excdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTm
# dHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZq
# ELQdVTNYs6FwZvKhggNNMIICNQIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkRDMDAtMDVF
# MC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMK
# AQEwBwYFKw4DAhoDFQCMJG4vg0juMOVn2BuKACUvP80FuqCBgzCBgKR+MHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hQw0TAi
# GA8yMDI0MDYxMjE0MzYwMVoYDzIwMjQwNjEzMTQzNjAxWjB0MDoGCisGAQQBhFkK
# BAExLDAqMAoCBQDqFDDRAgEAMAcCAQACAgpIMAcCAQACAhN7MAoCBQDqFYJRAgEA
# MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAI
# AgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBANyFm/zzwrqsT9wmHgViAd44Yn5n
# 4xoLXjAYVf/vcUsCEqMRCT5+E/Df3aqCr/B/pOWgJG6BXLWKvdOTethEMbFdvFGL
# GSnNjuHf3Ba3AoEjHInWPPyE4lXmMTLX79aXfcvtJbkzCTscqyDvv4/zrhMyxOEF
# prGxePqCifryaV2xVeG+OWyDbrSVuC53cGsMXmoRGeKBzmuqm4eXjD72jLUNq4Sg
# OJ6b1TJ0NCOFdd8mdsVjW1sPrVU5oFICmIa12wLb8ugT6Gy2iIi5iP5IJ7joGNUZ
# IK0vlxAv+mGFdR3odPPrl/0/v/b5JPvA09Q313ibmLF03twlHNIxIzD7XTwxggQN
# MIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAehQ
# sIDPK3KZTQABAAAB6DANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0G
# CyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDyI+gPjBUaUGGjBgNDwil/RbiN
# y8pmz/8p73N8GHr9cjCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EICrS2sTV
# AoQggkHR59pNqige0xfJT2J3U8W1Sc8H+OsdMIGYMIGApH4wfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAHoULCAzytymU0AAQAAAegwIgQgfeoHCcym
# 0bxAUe5hY41knHjcDv30RbGqY0XQ6xvnFLwwDQYJKoZIhvcNAQELBQAEggIAl2fK
# g4D7+W4H/6oY0/yqeJaH8FNeBRZ8W2gI8hqShQl8Puoq151e/1coBLsJkIE7TYq1
# lbofssKtGJzX+AL257YpR5Mn98LdeEVvJKOHKifRrXMLHLqP1GCX2FvL6wlPNG6r
# md7bjshEBWT3SMxk6NFluiE49mTjcknsgukLRPV09qvwlNxPkdjGTMQdzBY6suEP
# tu68fiFcZamHXBOVEyy2v+qyGtw2f40IfbtQW+opwjAje4aRpgdhVRBW0VURN9Fq
# PPKQ/Wucw1ELSKl0SEVDdPJYDCSYY4iJJQ/GVnPg9GEz/wOa8jAwK5Y41MOJ44M4
# 1FPWZWF/ZcxfqKaEG6O0Nxy2UaSTe7tz5SIUrqMgiFX9x8N6gLEBVTZyOf6CAzzm
# MPXl0ZD0rA9fDM8E0C2URAw/0zbJiE+mFFFKpixV914mwedTqc0YNCTwKlnJ7ek+
# LjOdVnKQfqFGHRxHfY186wsdYPBo+CCZI43LzgEcfcUaw8ZRFJ0+CytRjnVVaVih
# m/nHSnqDtpb6dhPZ6F2ftGfgRbba8GWEPrVwFKcizuu7DsKQj/naIDjruNiMg/n7
# D/jOu3V/WPz5Z6+rNTbDeOns1E+hC8jjKr8vw/9XD3tlXG1itN2ym/YWpRekNqyW
# RLGBYSh7aSS65VKy4njuW7oChvvN8HfmB32yho4=
# SIG # End signature block
