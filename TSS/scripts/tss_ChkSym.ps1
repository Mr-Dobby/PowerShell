#***************************************************
# modified version of tss_ChkSym.ps1 for usage in TSS
# Version 1.0.1cmd.exe /c
# Date: 7/15/2019
# Author: +waltere 2019.07.15, sabieler 2024.01.29 (TSS version)
# Description:  This file will use Checksym.exe to list all file versions on the local machine
#***************************************************

PARAM($ChkSymRange="All", $ChkSymPrefix="_sym", $FolderName=$null, $FileMask=$null, $ChkSymSuffix=$null, $FileDescription = $null, $ChkSymOutFolder=$null, [switch] $Recursive, [switch] $SkipCheckSymExe)

$ComputerName = $env:COMPUTERNAME
$LogPrefix = "ChkSym"
$ChkSymExe = $global:ChecksymExe
$IsSkipChecksymExe = ($SkipCheckSymExe.IsPresent)
if ($ChkSymOutFolder -and $ChkSymOutFolder[-1] -ne '\') { $ChkSymOutFolder += '\' }

if (($Env:PROCESSOR_ARCHITECTURE -eq 'ARM') -and (-not($IsSkipChecksymExe))){
	Logwarn 'Skipping running chksym executable since it is not supported in ' + $Env:PROCESSOR_ARCHITECTURE + ' architecture.'
	$IsSkipChecksymExe=$true
}
if($IsSkipChecksymExe){
	Logwarn "External chksym executable not be used since $ChkSymExe does not exist"
}

$Error.Clear() | Out-Null

# Import-LocalizedData -BindingVariable LocalsCheckSym -FileName DC_ChkSym
# using psobject instead
$LocalsCheckSym = New-Object PSObject
Add-Member -InputObject $LocalsCheckSym -MemberType NoteProperty -Name 'ID_FileVersionInfo' -Value "File Version Information (ChkSym)"

Trap [Exception]
{
	$errorMessage = $_.Exception.Message
	$errorCode = $_.Exception.ErrorRecord.FullyQualifiedErrorId
	$line = $_.InvocationInfo.PositionMessage
	#"[DC_ChkSym] Error " + $errorCode + " on line " + $line + ": $errorMessage running dc_chksym.ps1" | WriteTo-StdOut -ShortFormat
	LogWarn "Error $errorCode on line $($line): $errorMessage running $global:ScriptsFolder\tss_ChkSym.ps1"
	$Error.Clear() | Out-Null
}

function GetExchangeInstallFolder{
	If ((Test-Path "HKLM:SOFTWARE\Microsoft\ExchangeServer\v14") -eq $true){
		[System.IO.Path]::GetDirectoryName((get-itemproperty HKLM:\SOFTWARE\Microsoft\ExchangeServer\v14\Setup).MsiInstallPath)
	} ElseIf ((Test-Path "HKLM:SOFTWARE\Microsoft\Exchange\v8.0") -eq $true) {
		[System.IO.Path]::GetDirectoryName((get-itemproperty HKLM:\SOFTWARE\Microsoft\Exchange\Setup).MsiInstallPath)
	} Else {
		$null
	}
}

function GetDPMInstallFolder{
	if ((Test-Path "HKLM:SOFTWARE\Microsoft\Microsoft Data Protection Manager\Setup") -eq $true)
	{
		return [System.IO.Path]::GetDirectoryName((get-itemproperty HKLM:\SOFTWARE\Microsoft\Microsoft Data Protection Manager\Setup).InstallPath)
	}
	else
	{
		return $null
	}
}


Function FileExistOnFolder($PathToScan, $FileMask, [switch] $Recursive){
	Trap [Exception] {
		$ErrorStd = "[FileExistOnFolder] The following error ocurred when checking if a file exists on a folder:`n"
		$errorMessage = $_.Exception.Message
		$errorCode = $_.Exception.ErrorRecord.FullyQualifiedErrorId
		$line = $_.InvocationInfo.PositionMessage
		# "$ErrorStd Error " + $errorCode + " on line " + $line + ": $errorMessage`n   Path: $PathToScan`n   FileMask: $FileMask"
		LogWarnFile "$ErrorStd Error $errorCode on line $($line): $errorMessage`n Path: $PathToScan`n FileMask: $FileMask"
		$error.Clear
		continue
	}

	$AFileExist = $false

	if (Test-Path $PathToScan)
	{
		foreach ($mask in $FileMask) {
			if ($AFileExist -eq $false) {
				if ([System.IO.Directory]::Exists($PathToScan)) {
					if ($Recursive.IsPresent)
					{
						$Files = [System.IO.Directory]::GetFiles($PathToScan, $mask,[System.IO.SearchOption]::AllDirectories)
					} else {
						$Files = [System.IO.Directory]::GetFiles($PathToScan, $mask,[System.IO.SearchOption]::TopDirectoryOnly)
					}
					$AFileExist = ($Files.Count -ne 0)
				}
			}
		}
	}
	return $AFileExist
}

Function GetAllRunningDriverFilePath([string] $DriverName){
	$driversPath = "HKLM:System\currentcontrolset\services\"+$DriverName
	if(Test-Path $driversPath){
		$ImagePath = (Get-ItemProperty ("HKLM:System\currentcontrolset\services\"+$DriverName)).ImagePath
	}
	if($null -eq $ImagePath){
		$driversPath = "system32\drivers\"+$DriverName+".sys"
		$ImagePath = join-path $env:windir $driversPath
		if(-not(Test-Path $ImagePath))
		{
			Loginfo "$($Driver.Name) not exist in the system32\drivers\" Red
		}
	}
	else{
		if($ImagePath.StartsWith("\SystemRoot\")){
			$ImagePath = $ImagePath.Remove(0,12)
		}
		elseif($ImagePath.StartsWith("\??\")){
			$ImagePath = $ImagePath.Remove(0,14)
		}
		$ImagePath = join-path $env:windir $ImagePath
	}
	return $ImagePath
}

Function PrintTXTCheckSymInfo([PSObject]$OutPut, $StringBuilder, [switch]$S, [switch]$R){
	if($null -ne $OutPut.Processes)
	{
		[void]$StringBuilder.Append("*******************************************************************************`r`n")
		[void]$StringBuilder.Append("[PROCESSES] - Printing Process Information for "+$OutPut.Processes.Count +" Processes.`r`n")
		[void]$StringBuilder.Append("[PROCESSES] - Context: System Process(es)`r`n")
		[void]$StringBuilder.Append("*******************************************************************************`r`n")

		Foreach($Process in $OutPut.Processes)
		{
			$Index = 1
			[void]$StringBuilder.Append("-----------------------------------------------------------`r`n")
			[void]$StringBuilder.Append("Process Name ["+$Process.ProcessName.ToUpper()+".EXE] - PID="+$Process.Id +" - "+ $Process.Modules.Count +" modules recorded`r`n")
			[void]$StringBuilder.Append("-----------------------------------------------------------`r`n")
			foreach($mod in $Process.Modules)
			{
				if($null -ne $mod.FileName)
				{
					[void]$StringBuilder.Append("Module[  "+$Index+"] [" + $mod.FileName+"]`r`n")
					if($R.IsPresent)
					{
						$FileItem = Get-ItemProperty $mod.FileName
						[void]$StringBuilder.Append("  Company Name:      " + $FileItem.VersionInfo.CompanyName	+"`r`n")
						[void]$StringBuilder.Append("  File Description:  " + $FileItem.VersionInfo.FileDescription +"`r`n")
						[void]$StringBuilder.Append("  Product Version:   " + $FileItem.VersionInfo.ProductVersion+"`r`n")
						[void]$StringBuilder.Append("  File Version:      " + $FileItem.VersionInfo.FileVersion+"`r`n")
						[void]$StringBuilder.Append("  File Size (bytes): " + $FileItem.Length+"`r`n")
						[void]$StringBuilder.Append("  File Date:         " + $FileItem.LastWriteTime+"`r`n")

					}

					if($S.IsPresent)
					{

					}
					[void]$StringBuilder.Append("`r`n")
					$Index+=1
				}
			}
		}
	}

	if($null -ne $OutPut.Drivers)
	{
		[void]$StringBuilder.Append("*******************************************************************************`r`n")
		[void]$StringBuilder.Append( "[KERNEL-MODE DRIVERS] - Printing Module Information for "+$OutPut.Drivers.Count +" Modules.`r`n")
		[void]$StringBuilder.Append( "[KERNEL-MODE DRIVERS] - Context: Kernel-Mode Driver(s)`r`n")
		[void]$StringBuilder.Append( "*******************************************************************************`r`n")
		$Index = 1
		Foreach($Driver in $OutPut.Drivers)
		{
			$DriverFilePath = GetAllRunningDriverFilePath $Driver.Name
			[void]$StringBuilder.Append("Module[  "+$Index+"] [" + $DriverFilePath+"]`r`n")

			if($R.IsPresent)
			{
				$FileItem = Get-ItemProperty $DriverFilePath
				if(($null -ne $FileItem.VersionInfo.CompanyName) -and ($FileItem.VersionInfo.CompanyName -ne ""))
				{
					[void]$StringBuilder.Append("  Company Name:      " + $FileItem.VersionInfo.CompanyName	+"`r`n")
				}

				if(($null -ne $FileItem.VersionInfo.FileDescription) -and ($FileItem.VersionInfo.FileDescription.trim() -ne ""))
				{
					[void]$StringBuilder.Append("  File Description:  " + $FileItem.VersionInfo.FileDescription +"`r`n")
				}

				if(($null -ne $FileItem.VersionInfo.ProductVersion) -and ($FileItem.VersionInfo.ProductVersion -ne ""))
				{
					[void]$StringBuilder.Append("  Product Version:   " + $FileItem.VersionInfo.ProductVersion+"`r`n")
				}

				if(($null -ne $FileItem.VersionInfo.FileVersion) -and ($FileItem.VersionInfo.FileVersion -ne ""))
				{
					[void]$StringBuilder.Append("  File Version:      " + $FileItem.VersionInfo.FileVersion+"`r`n"	)
				}
				[void]$StringBuilder.Append("  File Size (bytes): " + $FileItem.Length+"`r`n")
				[void]$StringBuilder.Append("  File Date:         " + $FileItem.LastWriteTime+"`r`n")
			}

			if($S.IsPresent)
			{

			}

			[void]$StringBuilder.Append("`r`n")
			$Index+=1
		}
	}

	if($null -ne $OutPut.Files)
	{
		[void]$StringBuilder.Append("*******************************************************************************`r`n")
		[void]$StringBuilder.Append("[FILESYSTEM MODULES] - Printing Module Information for "+$OutPut.Files.Count +" Modules.`r`n")
		[void]$StringBuilder.Append("[FILESYSTEM MODULES] - Context: Filesystem Modules`r`n")
		[void]$StringBuilder.Append("*******************************************************************************`r`n")
		$Index = 1
		Foreach($File in $OutPut.Files)
		{
			[void]$StringBuilder.Append("Module[  "+$Index+"] [" + $File+"]`r`n")
			if($R.IsPresent)
			{
				$FileItem = Get-ItemProperty $File
				if(($null -ne $FileItem.VersionInfo.CompanyName) -and ($FileItem.VersionInfo.CompanyName -ne ""))
				{
					[void]$StringBuilder.Append("  Company Name:      " + $FileItem.VersionInfo.CompanyName	+"`r`n")
				}

				if(($null -ne $FileItem.VersionInfo.FileDescription) -and ($FileItem.VersionInfo.FileDescription.trim() -ne ""))
				{
					[void]$StringBuilder.Append("  File Description:  " + $FileItem.VersionInfo.FileDescription +"`r`n")
				}

				if(($null -ne $FileItem.VersionInfo.ProductVersion) -and ($FileItem.VersionInfo.ProductVersion -ne ""))
				{
					[void]$StringBuilder.Append("  Product Version:   " + $FileItem.VersionInfo.ProductVersion+"`r`n")
				}

				if(($null -ne $FileItem.VersionInfo.FileVersion) -and ($FileItem.VersionInfo.FileVersion -ne ""))
				{
					[void]$StringBuilder.Append("  File Version:      " + $FileItem.VersionInfo.FileVersion+"`r`n"	)
				}
				[void]$StringBuilder.Append("  File Size (bytes): " + $FileItem.Length+"`r`n")
				[void]$StringBuilder.Append("  File Date:         " + $FileItem.LastWriteTime+"`r`n")
			}

			if($S.IsPresent)
			{

			}
			[void]$StringBuilder.Append("`r`n")
			$Index+=1
		}
	}
}

Function PrintCSVCheckSymInfo([PSObject]$OutPut, $StringBuilder, [switch]$S, [switch]$R){
	[void]$StringBuilder.Append("Create:,"+[DateTime]::Now+"`r`n")
	[void]$StringBuilder.Append("Computer:,"+ $ComputerName+"`r`n`r`n")

	if($null -ne $OutPut.Processes)
	{
		[void]$StringBuilder.Append("[PROCESSES]`r`n")
		[void]$StringBuilder.Append(",Process Name,Process ID,Module Path,Symbol Status,Checksum,Time/Date Stamp,Time/Date String,Size Of Image,DBG Pointer,PDB Pointer,PDB Signature,PDB Age,Product Version,File Version,Company Name,File Description,File Size,File Time/Date Stamp (High),File Time/Date Stamp (Low),File Time/Date String,Local DBG Status,Local DBG,Local PDB Status,Local PDB`r`n")
		Foreach($Process in $OutPut.Processes)
		{
			if($null -ne $Process.Modules)
			{
				foreach($mod in $Process.Modules)
				{
					if($null -ne $mod.FileName)
					{
						[void]$StringBuilder.Append("," +$Process.Name+".EXE,"+$Process.Id+",")
						[void]$StringBuilder.Append( $mod.FileName+",")
						if($S.IsPresent)
						{
							[void]$StringBuilder.Append("SYMBOLS_PDB,,,,,,,,,")
						}
						else
						{
							[void]$StringBuilder.Append("SYMBOLS_No,,,,,,,,,")
						}

						if($R.IsPresent)
						{
							$FileItem = Get-ItemProperty $mod.FileName
							[void]$StringBuilder.Append( "("+$FileItem.VersionInfo.ProductVersion.Replace(",",".")+"	),("+$FileItem.VersionInfo.FileVersion.Replace(",",".")+"	),"+$FileItem.VersionInfo.CompanyName.Replace(",",".")+","+$FileItem.VersionInfo.FileDescription.Replace(",",".")+","+$FileItem.Length+",,,"+$FileItem.LastWriteTime+",,,,,`r`n")
						}
						else
						{
							[void]$StringBuilder.Append( ",,,,,,,,,,,,`r`n")
						}
					}
				}
			}
		}
	}

	if($null -ne $OutPut.Drivers)
	{
		[void]$StringBuilder.Append("[KERNEL-MODE DRIVERS]`r`n")
		[void]$StringBuilder.Append(",,,Module Path,Symbol Status,Checksum,Time/Date Stamp,Time/Date String,Size Of Image,DBG Pointer,PDB Pointer,PDB Signature,PDB Age,Product Version,File Version,Company Name,File Description,File Size,File Time/Date Stamp (High),File Time/Date Stamp (Low),File Time/Date String,Local DBG Status,Local DBG,Local PDB Status,Local PDB`r`n")
		Foreach($Driver in $OutPut.Drivers)
		{
			$DriverFilePath = GetAllRunningDriverFilePath $Driver.Name
			[void]$StringBuilder.Append(",,," +$DriverFilePath+",")
			if($S.IsPresent)
			{
				[void]$StringBuilder.Append("SYMBOLS_PDB,,,,,,,,,")
			}
			else
			{
				[void]$StringBuilder.Append("SYMBOLS_NO,,,,,,,,,")
			}

			if($R.IsPresent)
			{
				$DriverItem = Get-ItemProperty $DriverFilePath
				if($null -ne $DriverItem.VersionInfo.ProductVersion)
				{
					[void]$StringBuilder.Append("("+$DriverItem.VersionInfo.ProductVersion.Replace(",",".")+"),("+$DriverItem.VersionInfo.FileVersion.Replace(",",".")+"),"+$DriverItem.VersionInfo.CompanyName.Replace(",",".")+","+$DriverItem.VersionInfo.FileDescription.Replace(",",".")+","+$DriverItem.Length+",,,"+$DriverItem.LastWriteTime+",,,,,`r`n")
				}
				else
				{
					[void]$StringBuilder.Append(",,,,"+$DriverItem.Length+",,,"+$DriverItem.LastWriteTime+",,,,,`r`n")
				}
			}
			else
			{
				[void]$StringBuilder.Append(",,,,,,,,,,,,`r`n")
			}
		}
	}

	if($null -ne $OutPut.Files)
	{
		[void]$StringBuilder.Append("[FILESYSTEM MODULES]`r`n")
		[void]$StringBuilder.Append(",,,Module Path,Symbol Status,Checksum,Time/Date Stamp,Time/Date String,Size Of Image,DBG Pointer,PDB Pointer,PDB Signature,PDB Age,Product Version,File Version,Company Name,File Description,File Size,File Time/Date Stamp (High),File Time/Date Stamp (Low),File Time/Date String,Local DBG Status,Local DBG,Local PDB Status,Local PDB`r`n")
		Foreach($File in $OutPut.Files)
		{
			[void]$StringBuilder.Append(",,," +$File+",")
			if($S.IsPresent)
			{
				[void]$StringBuilder.Append("SYMBOLS_PDB,,,,,,,,,")
			}
			else
			{
				[void]$StringBuilder.Append("SYMBOLS_NO,,,,,,,,,")
			}

			if($R.IsPresent)
			{
				$FileItem = Get-ItemProperty $File
				if($null -ne $FileItem.VersionInfo.ProductVersion)
				{
					[void]$StringBuilder.Append("("+$FileItem.VersionInfo.ProductVersion.Replace(",",".")+"	),("+$FileItem.VersionInfo.FileVersion.Replace(",",".")+"	),"+$FileItem.VersionInfo.CompanyName.Replace(",",".")+","+$FileItem.VersionInfo.FileDescription.Replace(",",".")+","+$FileItem.Length+",,,"+$FileItem.LastWriteTime+",,,,,`r`n")
				}
				else
				{
					[void]$StringBuilder.Append(",,,,"+$FileItem.Length+",,,"+$FileItem.LastWriteTime+",,,,,`r`n")
				}
			}
			else
			{
				[void]$StringBuilder.Append(",,,,,,,,,,,,`r`n")
			}
		}
	}
}

Function PSChkSym ([string]$PathToScan="", [array]$FileMask = "*.*", [string]$O2="", [String]$P ="", [switch]$D, [switch]$F, [switch]$F2, [switch]$S, [switch]$R){
	# Check the system information
	#  P ----- get the process information, can give a * get all process info or give a process name get the specific process
	#  D ----- get the all local running drivers infor
	#  F ----- search the top level folder to get the files
	#  F2 ---- search the all level from folder, Recursive
	#  S ----- get Symbol Information
	#  R ----- get the Version and File-System Information
	#  O2 ---- Out the result to the file
	Trap [Exception] {

		$ErrorStd = "[PSChkSym] The following error ocurred when getting the file from a folder:`n"
		$errorMessage = $_.Exception.Message
		$errorCode = $_.Exception.ErrorRecord.FullyQualifiedErrorId
		$line = $_.InvocationInfo.PositionMessage
		#"$ErrorStd Error " + $errorCode + " on line " + $line + ": $errorMessage`n   Path: $PathToScan`n   FileMask: $FileMask" | WriteTo-StdOut -ShortFormat
		LogWarnFile "$ErrorStd Error $errorCode on line  $($line): $errorMessage`n Path: $PathToScan`n FileMask: $FileMask"
		$error.Clear
		continue
	}

	$OutPutObject = New-Object PSObject
	$SbCSVFormat = New-Object -TypeName System.Text.StringBuilder
	$SbTXTFormat = New-Object -TypeName System.Text.StringBuilder
	[void]$SbTXTFormat.Append("***** COLLECTION OPTIONS *****`r`n")

	if($P -ne "")
	{
		[void]$SbTXTFormat.Append("Collect Information From Running Processes`r`n")
		if($P -eq "*")
		{
			[void]$SbTXTFormat.Append("    -P *     (Query all local processes) `r`n")

			$Processes = [System.Diagnostics.Process]::GetProcesses()
		}
		else
		{
			[void]$SbTXTFormat.Append("    -P $P     (Query for specific process by name) `r`n" )

			$Processes = [System.Diagnostics.Process]::GetProcessesByName($P)
		}
	}

	if($D.IsPresent)
	{
		[void]$SbTXTFormat.Append("    -D     (Query all local device drivers) `r`n")
		Add-Type -assemblyname System.ServiceProcess
		$DeviceDrivers = [System.ServiceProcess.ServiceController]::GetDevices() | where-object {$_.Status -eq "Running"}
		# $DeviceDrivers = GetAllRunningDriverFileName
	}

	if($F.IsPresent -or $F2.IsPresent)
	{
		[void]$SbTXTFormat.Append("Collect Information From File(s) Specified by the User`r`n")
		[void]$SbTXTFormat.Append("   -F $PathToScan\$FileMask`r`n")
		if($F.IsPresent)
		{
			Foreach($Mask in $FileMask)
			{
				$Files += [System.IO.Directory]::GetFiles($PathToScan, $Mask,[System.IO.SearchOption]::TopDirectoryOnly)
			}
		}
		else
		{
			Foreach($Mask in $FileMask)
			{
				$Files += [System.IO.Directory]::GetFiles($PathToScan, $Mask,[System.IO.SearchOption]::AllDirectories)
			}
		}
	}

	[void]$SbTXTFormat.Append("***** INFORMATION CHECKING OPTIONS *****`r`n")
	if($S.IsPresent -or $R.IsPresent)
	{
		if($S.IsPresent)
		{

			[void]$SbTXTFormat.Append("Output Symbol Information From Modules`r`n")
			[void]$SbTXTFormat.Append("   -S `r`n")
		}

		if($R.IsPresent)
		{
			[void]$SbTXTFormat.Append("Collect Version and File-System Information From Modules`r`n")
			[void]$SbTXTFormat.Append("   -R `r`n")
		}
	}
	else
	{
		[void]$SbTXTFormat.Append("Output Symbol Information From Modules`r`n")
		[void]$SbTXTFormat.Append("   -S `r`n")
		[void]$SbTXTFormat.Append("Collect Version and File-System Information From Modules`r`n")
		[void]$SbTXTFormat.Append("   -R `r`n")
	}

	[void]$SbTXTFormat.Append("***** OUTPUT OPTIONS *****`r`n")
	[void]$SbTXTFormat.Append("Output Results to STDOUT`r`n")
	[void]$SbTXTFormat.Append("Output Collected Module Information To a CSV File`r`n")

	if($O2 -ne "")
	{
		$OutFiles = $O2.Split('>')
		[void]$SbTXTFormat.Append("   -O "+$OutFiles[0]+" `r`n")
	}

	## Add-Member -inputobject $OutPutObject -membertype noteproperty -name "Processes" -value $Processes
	## Add-Member -inputobject $OutPutObject -membertype noteproperty -name "Drivers" -value $DeviceDrivers
	## Add-Member -inputobject $OutPutObject -membertype noteproperty -name "Files" -value $Files

	if(($S.IsPresent -and $R.IsPresent) -or (-not$S.IsPresent -and -not$R.IsPresent))
	{
		PrintTXTCheckSymInfo -OutPut $OutPutObject $SbTXTFormat -S -R
		PrintCSVCheckSymInfo -OutPut $OutPutObject $SbCSVFormat -S -R
	}
	elseif($S.IsPresent -and -not$R.IsPresent)
	{
		PrintTXTCheckSymInfo -OutPut $OutPutObject $SbTXTFormat -S
		PrintCSVCheckSymInfo -OutPut $OutPutObject $SbCSVFormat -S
	}
	else
	{
		PrintTXTCheckSymInfo -OutPut $OutPutObject $SbTXTFormat -R
		PrintCSVCheckSymInfo -OutPut $OutPutObject $SbCSVFormat -R
	}

	foreach($out in $OutFiles)
	{
		if($out.EndsWith("CSV",[StringComparison]::InvariantCultureIgnoreCase))
		{
			$SbCSVFormat.ToString() | Out-File $out -Encoding "utf8"
		}
		else
		{
			if(Test-Path $out)
			{
				$SbTXTFormat.ToString() | Out-File $out -Encoding "UTF8" -Append
			}
			else
			{
				$SbTXTFormat.ToString() | Out-File $out -Encoding "UTF8"
			}
		}
	}
}

Function RunChkSym ([string]$PathToScan="", [array]$FileMask = "*.*", [string]$Output="", [boolean]$Recursive=$false, [string]$Arguments="", [string]$Description="", [boolean]$SkipChksymExe=$false){
	if (($Arguments -ne "") -or (Test-Path ($PathToScan)))
	{
		if ($PathToScan -ne "")
		{
			$eOutput = $Output
			ForEach ($scFileMask in $FileMask){ #
				$eFileMask = ($scFileMask.replace("*.*","")).toupper()
				$eFileMask = ($eFileMask.replace("*.",""))
				$eFileMask = ($eFileMask.replace(".*",""))
				if (($eFileMask -ne "") -and (Test-Path ("$eOutput.*") )) {$eOutput += ("_" + $eFileMask)}
				$symScanPath += ((Join-Path -Path $PathToScan -ChildPath $scFileMask) + ";")
			}
		}

		if ($Description -ne "")
		{
			$FileDescription = $Description
		} else {
			$fdFileMask = [string]::join(";",$FileMask)
			if ($fdFileMask -contains ";") {
				$FileDescription = $PathToScan + " [" + $fdFileMask + "]"
			} else {
				$FileDescription = (Join-Path $PathToScan $fdFileMask)
			}
		}

		if ($Arguments -ne "")
		{
			$eOutput = $Output
			# Write-DiagProgress -Activity $LocalsCheckSym.ID_FileVersionInfo -Status $Description
			Loginfo "Activity: $($LocalsCheckSym.ID_FileVersionInfo), Status: $Description" White
			if(-not($SkipChksymExe))
			{
				$CommandToExecute = "cmd.exe /c $ChkSymExe $Arguments"
			}
			else
			{
				# Calling the method to implement the functionalities
				$Arguments = $Arguments.Substring(0,$Arguments.IndexOf("-O2")+4) +"$Output.CSV>$Output.TXT"
				Invoke-Expression "PSChkSym  $Arguments"
			}
		}
		else {
			# Write-DiagProgress -Activity $LocalsCheckSym.ID_FileVersionInfo -Status ($FileDescription)# + " Recursive: " + $Recursive)
			Loginfo "Activity: $($LocalsCheckSym.ID_FileVersionInfo), Status: $FileDescription" White
			if ($Recursive -eq $true) {
				$F = "-F2"
				$AFileExistOnFolder = (FileExistOnFolder -PathToScan $PathToScan -FileMask $scFileMask -Recursive)
			} else {
				$F = "-F"
				$AFileExistOnFolder = (FileExistOnFolder -PathToScan $PathToScan -FileMask $scFileMask)

			}
			if ($AFileExistOnFolder)
			{
				if(-not($SkipChksymExe))
				{
					$CommandToExecute = "cmd.exe /c $ChkSymExe $F `"$symScanPath`" -R -S -O2 `"$eOutput.CSV`" > `"$eOutput.TXT`""
				}
				else
				{
					# Calling the method to implement the functionalities
					if($F -eq "-F2")
					{
						PSChkSym -PathToScan $PathToScan -FileMask $FileMask -F2 -S -R -O2 "$eOutput.CSV>$eOutput.TXT"
					}
					else
					{
						PSChkSym -PathToScan $PathToScan -FileMask $FileMask -F -S -R -O2 "$eOutput.CSV>$eOutput.TXT"
					}
				}
			}
			else
			{
				Logwarn "Chksym did not run against path '$PathToScan' since there are no files with mask ($scFileMask) on system"
				$CommandToExecute = ""
			}
		}
		if ($CommandToExecute -ne "") {
			#RunCmD -commandToRun $CommandToExecute -sectionDescription "File Version Information (ChkSym)" -filesToCollect ("$eOutput.*") -fileDescription $FileDescription -BackgroundExecution
			$Commands = @(
				$CommandToExecute
			)
			RunCommands "$LogPrefix" $Commands -ThrowException:$False -ShowMessage:$True
		}
	}
	else {
		LogWarn "Chksym did not run against path '$PathToScan', because path does not exist"
	}
}

### Main ###
# Check if using $FolderName or $ChkSymRangeString
if (($null -ne $FolderName) -and ($null -ne $FileMask) -and ($null -ne $ChkSymSuffix)) {
	$OutputBase = $ChkSymOutFolder + $ComputerName + $ChkSymPrefix + $ChkSymSuffix
	$IsRecursive = ($Recursive.IsPresent)
	RunChkSym -PathToScan $FolderName -FileMask $FileMask -Output $OutputBase -Description $FileDescription -Recursive $IsRecursive -CallChksymExe $IsSkipChecksymExe
} else {
	[array] $RunChkSym = $null
	Foreach ($ChkSymRangeString in $ChkSymRange)
	{
		if ($ChkSymRangeString -eq "All")
		{
			$RunChkSym += "ProgramFilesSys", "Drivers", "System32DLL", "System32Exe", "System32SYS", "Spool", "iSCSI", "Process", "RunningDrivers", "Cluster"
		} else {
			$RunChkSym += $ChkSymRangeString
		}
	}

	switch ($RunChkSym)	{
		"ProgramFilesSys" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_ProgramFiles_SYS"
			RunChkSym -PathToScan "$Env:ProgramFiles" -FileMask "*.sys" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			if (($Env:PROCESSOR_ARCHITECTURE -eq "AMD64") -or $Env:PROCESSOR_ARCHITECTURE -eq "IA64")  {
				$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_ProgramFilesx86_SYS"
				RunChkSym -PathToScan (${Env:ProgramFiles(x86)}) -FileMask "*.sys" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
			}
		"Drivers" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_Drivers"
			RunChkSym -PathToScan "$Env:SystemRoot\System32\drivers" -FileMask "*.*" -Output $OutputBase -Recursive $false -SkipChksymExe $IsSkipChecksymExe
			}
		"System32DLL" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_System32_DLL"
			RunChkSym -PathToScan "$Env:SystemRoot\System32" -FileMask "*.DLL" -Output $OutputBase -Recursive $false -SkipChksymExe $IsSkipChecksymExe
			if (($Env:PROCESSOR_ARCHITECTURE -eq "AMD64") -or $Env:PROCESSOR_ARCHITECTURE -eq "IA64")  {
				$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_SysWOW64_DLL"
				RunChkSym -PathToScan "$Env:SystemRoot\SysWOW64" -FileMask "*.dll" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
			}
		"System32Exe" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_System32_EXE"
			RunChkSym -PathToScan "$Env:SystemRoot\System32" -FileMask "*.EXE" -Output $OutputBase -Recursive $false -SkipChksymExe $IsSkipChecksymExe
			if (($Env:PROCESSOR_ARCHITECTURE -eq "AMD64") -or $Env:PROCESSOR_ARCHITECTURE -eq "IA64")  {
				$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_SysWOW64_EXE"
				RunChkSym -PathToScan "$Env:SystemRoot\SysWOW64" -FileMask "*.exe" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
			}
		"System32SYS" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_System32_SYS"
			RunChkSym -PathToScan "$Env:SystemRoot\System32" -FileMask "*.SYS" -Output $OutputBase -Recursive $false -SkipChksymExe $IsSkipChecksymExe
			if (($Env:PROCESSOR_ARCHITECTURE -eq "AMD64") -or $Env:PROCESSOR_ARCHITECTURE -eq "IA64")  {
				$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_SysWOW64_SYS"
				RunChkSym -PathToScan "$Env:SystemRoot\SysWOW64" -FileMask "*.sys" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
			}
		"Spool" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_PrintSpool"
			RunChkSym -PathToScan "$Env:SystemRoot\System32\Spool" -FileMask "*.*" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
		}
		"Cluster" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_Cluster"
			RunChkSym -PathToScan "$Env:SystemRoot\Cluster" -FileMask "*.*" -Output $OutputBase -Recursive $false -SkipChksymExe $IsSkipChecksymExe
		}
		"iSCSI" {
			if(Test-Path "$Env:ProgramFiles\Microsoft iSNS Server" ) {
				$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_MS_iSNS"
				RunChkSym -PathToScan "$Env:ProgramFiles\Microsoft iSNS Server" -FileMask "*.*" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_MS_iSCSI"
			RunChkSym -PathToScan "$Env:SystemRoot\System32" -FileMask "iscsi*.*" -Output $OutputBase -Recursive $false -SkipChksymExe $IsSkipChecksymExe
		}
		"Process" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_Process"
#we#		Get-Process |                                             Format-Table -Property "Handles","NPM","PM","WS","VM","CPU","Id","ProcessName","StartTime",@{ Label = "Running Time";Expression={(GetAgeDescription -TimeSpan (new-TimeSpan $_.StartTime))}} -AutoSize | Out-File "$OutputBase.txt" -Encoding "UTF8" -Width 200
			Get-Process | where-object  {$_.ProcessName -ne "idle"} | Format-Table -Property "Handles","NPM","PM","WS","VM","CPU","Id","ProcessName","StartTime",@{ Label = "Running Time";Expression={(GetAgeDescription -TimeSpan (new-TimeSpan $($_).StartTime))}} -AutoSize | Out-File "$OutputBase.txt" -Encoding "UTF8" -Width 200

			"--------------------------------" | Out-File "$OutputBase.txt" -Encoding "UTF8" -append
			tasklist -svc | Out-File "$OutputBase.txt" -Encoding "UTF8" -append -EA SilentlyContinue
			"--------------------------------" | Out-File "$OutputBase.txt" -Encoding "UTF8" -append
			RunChkSym -Output $OutputBase -Arguments "-P * -R -O2 `"$OutputBase.CSV`" >> `"$OutputBase.TXT`"" -Description "Running Processes" -SkipChksymExe $IsSkipChecksymExe
		}
		"RunningDrivers" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_RunningDrivers"
			RunChkSym -Output $OutputBase -Arguments "-D -R -S -O2 `"$OutputBase.CSV`" > `"$OutputBase.TXT`"" -Description "Running Drivers" -SkipChksymExe $IsSkipChecksymExe
		}
		"InetSrv" {
			$inetSrvPath = (join-path $env:systemroot "system32\inetsrv")
			$OutputBase = "$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_InetSrv"
			RunChkSym -PathToScan $inetSrvPath -FileMask ("*.exe","*.dll") -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
		}
		"Exchange" {
			$ExchangeFolder = GetExchangeInstallFolder
			if ($null -ne $ExchangeFolder){
				$OutputBase = "$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_Exchange"
				RunChkSym -PathToScan $ExchangeFolder -FileMask ("*.exe","*.dll") -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			} else {
				"Chksym did not run against Exchange since it could not find Exchange server installation folder" | WriteTo-StdOut -ShortFormat
			}
		}
		"DPM" {
			$DPMFolder = GetDPMInstallFolder
			If ($null -ne $DPMFolder)
			{
				$DPMFolder = Join-Path $DPMFolder "bin"
				$OutputBase= "$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_DPM"
				RunChkSym -PathToScan $DPMFolder -FileMask("*.exe","*.dll") -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			} else {
				"Chksym did not run against DPM since it could not find the DPM installation folder" | WriteTo-StdOut -ShortFormat
			}
		}
		"WinSxsDLL" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_WinSxS_DLL"
			RunChkSym -PathToScan "$Env:SystemRoot\WinSxS" -FileMask "*.DLL" -Output $OutputBase -Recursive $True -SkipChksymExe $IsSkipChecksymExe
			}
		"WinSxsEXE" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_WinSxS_EXE"
			RunChkSym -PathToScan "$Env:SystemRoot\WinSxS" -FileMask "*.EXE" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
		"WinSxsSYS" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_WinSxS_SYS"
			RunChkSym -PathToScan "$Env:SystemRoot\WinSxS" -FileMask "*.SYS" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
		"RefAssmDLL" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_RefAssm_DLL"
			RunChkSym -PathToScan "$Env:programfiles\Reference Assemblies" -FileMask "*.DLL" -Output $OutputBase -Recursive $true -SkipChksymExe $IsSkipChecksymExe
			}
		"DotNETDLL" {
			$OutputBase="$ChkSymOutFolder$ComputerName$ChkSymPrefix" + "_DotNET_DLL"
			RunChkSym -PathToScan "$Env:SystemRoot\Microsoft.NET" -FileMask "*.DLL" -Output $OutputBase -Recursive $True -SkipChksymExe $IsSkipChecksymExe
			}
	}
}
# SIG # Begin signature block
# MIInvwYJKoZIhvcNAQcCoIInsDCCJ6wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAvR8CbVVsoXIhG
# rqjW6/EjCnmJT9mzSuJyT0BvFI4pGKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA3PPMtKuePL/WcJHUTtXiJp
# euBq5Ou0VpHQvm3QXZWnMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAg21LSiKW168KBa0XFnPGqm2PuSs4WSaFCtmJrwtQSGe6x5hujXk4R1Lk
# CINX59hv6Etq/gBMP+bftHX5NMhwiAMHRRO8nX2JBIkJI9J09rjW2btDj7+bgwAx
# zh2T2kRpMxVrnVmOuTY2o51PRiRyU3Yr2pLlDFalLvvVvcDIoezDxjIeL/CZJJ39
# eJ7CaILRJG4j1L+cFjobg0klifSWv2tPv2ART+qOVK2sZ/rOnfiIXLBEijK3JwRe
# ww8AbrhlCYT4bWhV+7vzN1Lrad4Nv8aU4LXYTPIEm4rogalAXQStJs5FL64OJNp0
# 8trIanKwDApKU+WyBATzSEhycSt9f6GCFykwghclBgorBgEEAYI3AwMBMYIXFTCC
# FxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFZBgsq
# hkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCCblLfI+AMH9jThiWP/EZbDJ0nPmt42FjOEbVERlJdxtwIGZlcW3VjP
# GBMyMDI0MDYxMjE1MDAzOS44MTVaMASAAgH0oIHYpIHVMIHSMQswCQYDVQQGEwJV
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
# IgQg/FoMpNuztv6kbKkFmjxNYFng6n5Tqg2X7joyeX/xR58wgfoGCyqGSIb3DQEJ
# EAIvMYHqMIHnMIHkMIG9BCAz1COr5bD+ZPdEgQjWvcIWuDJcQbdgq8Ndj0xyMuYm
# KjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB49+9
# m5ocaIMiAAEAAAHjMCIEINsd2aW1Y7wtnrogb26/8zWtZkK5NN+chuZAiFvrXewx
# MA0GCSqGSIb3DQEBCwUABIICALzvARVzivcqzLS0BWo4QQkqhnpeHAwUnps91uoP
# edQ3RXbkjNDVzp6q1RVyxfAx7/ZF7wTOk6xqOBlGpmx4RIrg7qGL+tyT8xYtSDag
# 6axKvY/rvYdX0x5nd8tFrOg3YEt2pJippx+UhguMqh0ywdzUQDVKTKv+pFha8cVs
# WXZnLfsO+9u2DdthSsEhVrxmDf55dqZdHxNqWnzQ9ChjfqKHklz8uWIhGjKB6AZX
# kuwGWKxcy+djqws1lxMLP1wb+lXdu7nJRGUs3f1vdD+hmAJe4xXoVmPgVhPQDO+1
# NAKjvdiEaCpBaqNgFwbKQtSPR1sZWwspYN+uAm9jjp5K7HMty1EQc6SsK0gucqdm
# oq3p3C1OGcNw0iFqTGtBl6N9fvCGw/MCauQXzss6YS94IcYcl0ugefmOeEiUEi0i
# mTeDIY5g+e5cVMgE2pEdBoAUB6PZ3eir1cwtk0OQkxIo0S9CBX2nswzK2nGL3Wsx
# Mn/6+pRKx6w/jzAKk9PB9Fe4qBABeOHodoubDusel1jxGC1idXlsUMbOthOLE0zF
# gvt1jzGG0VuVXGSqA4i/wIkbCucMTK5KqsFHG7c4nIkJXH72oMEeKRaiAhNb0d6U
# e1mey6hkF5gV3UzaNRlchs3S10L6kkmcbQQGbgifgUJWB4/lq6N/1kskywBR+dBV
# QtIR
# SIG # End signature block
