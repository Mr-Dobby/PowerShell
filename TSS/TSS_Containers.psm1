<#
.SYNOPSIS
	This module is part of TSS FW and implements support for tracing Container scenarios


.DESCRIPTION
	This module is part of TSS FW and implements support for tracing Container scenarios


.NOTES
	Dev. Lead: wiaftrin, milanmil
	Authors		: wiaftrin, milanmil
	Requires	: PowerShell V4(Supported from Windows 8.1/Windows Server 2012 R2)
	Version		: see $global:TssVerDateCONTAINERS

.LINK
	TSS https://internal.evergreen.microsoft.com/en-us/help/4619187

#>

<# latest changes

::  2023.10.10.0 [we] _Containers: replaced TSS.ps1 with $($global:ScriptName)
#>

[cmdletbinding(PositionalBinding = $false, DefaultParameterSetName = "Default")]
param(
[Parameter(ParameterSetName = "Default")]
[string]$containerId
)

$global:TssVerDateCON= "2023.10.10.0"

#region event_logs_registry

	$_EVENTLOG_LIST_START = @(
		# LOGNAME!FLAG1|FLAG2|FLAG3
		"Application!NONE"
		"System!NONE"
		"Microsoft-Windows-CAPI2/Operational!CLEAR|SIZE|EXPORT"
		"Microsoft-Windows-Kerberos/Operational!CLEAR"
		"Microsoft-Windows-Kerberos-key-Distribution-Center/Operational!DEFAULT"
		"Microsoft-Windows-Kerberos-KdcProxy/Operational!DEFAULT"
		"Microsoft-Windows-WebAuth/Operational!DEFAULT"
		"Microsoft-Windows-WebAuthN/Operational!EXPORT"
		"Microsoft-Windows-CertPoleEng/Operational!CLEAR"
		"Microsoft-Windows-IdCtrls/Operational!EXPORT"
		"Microsoft-Windows-User Control Panel/Operational!EXPORT"
		"Microsoft-Windows-Authentication/AuthenticationPolicyFailures-DomainController!DEFAULT"
		"Microsoft-Windows-Authentication/ProtectedUser-Client!DEFAULT"
		"Microsoft-Windows-Authentication/ProtectedUserFailures-DomainController!DEFAULT"
		"Microsoft-Windows-Authentication/ProtectedUserSuccesses-DomainController!DEFAULT"
		"Microsoft-Windows-Biometrics/Operational!EXPORT"
		"Microsoft-Windows-LiveId/Operational!EXPORT"
		"Microsoft-Windows-AAD/Analytic!DEFAULT"
		"Microsoft-Windows-AAD/Operational!EXPORT"
		"Microsoft-Windows-User Device Registration/Debug!DEFAULT"
		"Microsoft-Windows-User Device Registration/Admin!EXPORT"
		"Microsoft-Windows-HelloForBusiness/Operational!EXPORT"
		"Microsoft-Windows-Shell-Core/Operational!DEFAULT"
		"Microsoft-Windows-WMI-Activity/Operational!DEFAULT"
		"Microsoft-Windows-GroupPolicy/Operational!DEFAULT"
		"Microsoft-Windows-Crypto-DPAPI/Operational!EXPORT"
		"Microsoft-Windows-Containers-CCG/Admin!NONE"
	)
	$_EVENTLOG_LIST_STOP = @(
	# LOGNAME!FLAGS
	"Application!DEFAULT"
	"System!DEFAULT"
	"Microsoft-Windows-CAPI2/Operational!NONE"
	"Microsoft-Windows-Kerberos/Operational!NONE"
	"Microsoft-Windows-Kerberos-key-Distribution-Center/Operational!NONE"
	"Microsoft-Windows-Kerberos-KdcProxy/Operational!NONE"
	"Microsoft-Windows-WebAuth/Operational!NONE"
	"Microsoft-Windows-WebAuthN/Operational!ENABLE"
	"Microsoft-Windows-CertPoleEng/Operational!NONE"
	"Microsoft-Windows-IdCtrls/Operational!ENABLE"
	"Microsoft-Windows-User Control Panel/Operational!NONE"
	"Microsoft-Windows-Authentication/AuthenticationPolicyFailures-DomainController!NONE"
	"Microsoft-Windows-Authentication/ProtectedUser-Client!NONE"
	"Microsoft-Windows-Authentication/ProtectedUserFailures-DomainController!NONE"
	"Microsoft-Windows-Authentication/ProtectedUserSuccesses-DomainController!NONE"
	"Microsoft-Windows-Biometrics/Operational!ENABLE"
	"Microsoft-Windows-LiveId/Operational!ENABLE"
	"Microsoft-Windows-AAD/Analytic!NONE"
	"Microsoft-Windows-AAD/Operational!ENABLE"
	"Microsoft-Windows-User Device Registration/Debug!NONE"
	"Microsoft-Windows-User Device Registration/Admin!ENABLE"
	"Microsoft-Windows-HelloForBusiness/Operational!ENABLE"
	"Microsoft-Windows-Shell-Core/Operational!ENABLE"
	"Microsoft-Windows-WMI-Activity/Operational!ENABLE"
	"Microsoft-Windows-GroupPolicy/Operational!DEFAULT"
	"Microsoft-Windows-Crypto-DPAPI/Operational!ENABLE"
	"Microsoft-Windows-Containers-CCG/Admin!ENABLE"
	"Microsoft-Windows-CertificateServicesClient-Lifecycle-System/Operational!ENABLE"
	"Microsoft-Windows-CertificateServicesClient-Lifecycle-User/Operational!ENABLE"
)

$_REG_ADD_START = @(
	# KEY!NAME!TYPE!VALUE
	"HKLM\SYSTEM\CurrentControlSet\Control\Lsa\NegoExtender\Parameters!InfoLevel!REG_DWORD!0xFFFF"
	"HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Pku2u\Parameters!InfoLevel!REG_DWORD!0xFFFF"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!SPMInfoLevel!REG_DWORD!0xC43EFF"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!LogToFile!REG_DWORD!1"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!NegEventMask!REG_DWORD!0xF"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!LspDbgInfoLevel!REG_DWORD!0x41C24800"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!LspDbgTraceOptions!REG_DWORD!0x1"
)




# Reg Delete
$_REG_DELETE = @(
	# KEY!NAME
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!SPMInfoLevel"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!LogToFile"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!NegEventMask"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA\NegoExtender\Parameters!InfoLevel"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA\Pku2u\Parameters!InfoLevel"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!LspDbgInfoLevel"
	"HKLM\SYSTEM\CurrentControlSet\Control\LSA!LspDbgTraceOptions"
	"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Diagnostics!GPSvcDebugLevel"
)

# Reg Query
$_REG_QUERY = @(
	# KEY!CHILD!FILENAME
	# File will be written ending with <FILENAME>-key.txt
	# If the export already exists it will be appended
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa!CHILDREN!Lsa"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies!CHILDREN!Polices"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System!CHILDREN!SystemGP"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer!CHILDREN!Lanmanserver"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation!CHILDREN!Lanmanworkstation"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon!CHILDREN!Netlogon"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL!CHILDREN!Schannel"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Cryptography!CHILDREN!Cryptography-HKLMControl"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography!CHILDREN!Cryptography-HKLMSoftware"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Cryptography!CHILDREN!Cryptography-HKLMSoftware-Policies"
	"HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Cryptography!CHILDREN!Cryptography-HKCUSoftware-Policies"
	"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Cryptography!CHILDREN!Cryptography-HKCUSoftware"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\SmartCardCredentialProvider!CHILDREN!SCardCredentialProviderGP"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication!CHILDREN!Authentication"
	"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Authentication!CHILDREN!Authentication-Wow64"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon!CHILDREN!Winlogon"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Winlogon!CHILDREN!Winlogon-CCS"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore!CHILDREN!Idstore-Config"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityCRL!CHILDREN!Idstore-Config"
	"HKEY_USERS\.Default\Software\Microsoft\IdentityCRL!CHILDREN!Idstore-Config"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Kdc!CHILDREN!KDC"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\KPSSVC!CHILDREN!KDCProxy"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin!CHILDREN!RegCDJ"
	"HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin!CHILDREN!RegWPJ"
	"HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC!CHILDREN!RegAADNGC"
	"HKEY_LOCAL_MACHINE\Software\Policies\Windows\WorkplaceJoin!CHILDREN!REGWPJ-Policy"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Winbio!CHILDREN!Wbio"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WbioSrvc!CHILDREN!Wbiosrvc"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Biometrics!CHILDREN!Wbio-Policy"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\EAS\Policies!CHILDREN!EAS"
	"HKEY_CURRENT_USER\SOFTWARE\Microsoft\SCEP!CHILDREN!Scep"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SQMClient!CHILDREN!MachineId"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Policies\PassportForWork!CHILDREN!NgcPolicyIntune"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork!CHILDREN!NgcPolicyGp"
	"HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\PassportForWork!CHILDREN!NgcPolicyGpUser"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Cryptography\Ngc!CHILDREN!NgcCryptoConfig"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\current\device\DeviceLock!CHILDREN!DeviceLockPolicy"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Policies\PassportForWork\SecurityKey!CHILDREN!FIDOPolicyIntune"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FIDO!CHILDREN!FIDOGp"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Rpc!CHILDREN!RpcGP"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters!CHILDREN!NTDS"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LDAP!CHILDREN!LdapClient"
	"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard!CHILDREN!DeviceGuard"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCMSetup!CHILDREN!CCMSetup"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM!CHILDREN!CCM"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727!NONE!DotNET-TLS"
	"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319!NONE!DotNET-TLS"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319!NONE!DotNET-TLS"
	"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727!NONE!DotNET-TLS"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedPC!NONE!SharedPC"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess!NONE!Passwordless"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Authz!CHILDREN!Authz"
	"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp!NONE!WinHttp-TLS"
	"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp!NONE!WinHttp-TLS"
	"HKEY_LOCAL_MACHINE\Software\Microsoft\Enrollments!CHILDREN!MDMEnrollments"
	"HKEY_LOCAL_MACHINE\Software\Microsoft\EnterpriseResourceManager!CHILDREN!MDMEnterpriseResourceManager"
	"HKEY_CURRENT_USER\Software\Microsoft\SCEP!CHILDREN!MDMSCEP-User"
	"HKEY_CURRENT_USER\S-1-5-18\Software\Microsoft\SCEP!CHILDREN!MDMSCEP-SystemUser"
)

#endregion event_logs_registry

#region container_functions

function Invoke-Container {

	[Cmdletbinding(DefaultParameterSetName = "Default")]
	param(
		[Parameter(Mandatory = $true)]
		[string]$ContainerId,
		[switch]$Nano,
		[Parameter(ParameterSetName = "PreTraceDir")]
		[switch]$PreTrace,
		[Parameter(ParameterSetName = "AuthDir")]
		[switch]$AuthDir,
		[switch]$UseCmd,
		[switch]$Record,
		[switch]$Silent,
		[Parameter(Mandatory = $true)]
		[string]$Command,
		[string]$WorkingFolder
	)

	<#
	$Workingdir = $_BASE_LOG_DIR #"C:\AuthScripts"
	if ($PreTrace) {
		$Workingdir += "\authlogs\PreTraceLogs"
	}

	if ($AuthDir) {
		$Workingdir += "\authlogs"
	}
	#>

	If($PSBoundParameters.ContainsKey("WorkingFolder")) {
		$Workingdir = $WorkingFolder
	}
	else {
		$Workingdir = "c:\TSS" #in TSS all commands, by default, run in TSS, otherwise use $WorkingFolder
	}




	Write-Verbose "Running Container command: $Command"
	if ($Record) {
		if ($Nano) {
			docker exec -u Administrator -w $Workingdir $ContainerId cmd /c "$Command" *>> $_CONTAINER_DIR\container-output.txt
		}
		elseif ($UseCmd) {
			docker exec -w $Workingdir $ContainerId cmd /c "$Command" *>> $_CONTAINER_DIR\container-output.txt
		}
		else {
			docker exec -w $Workingdir $ContainerId powershell -ExecutionPolicy Unrestricted "$Command" *>> $_CONTAINER_DIR\container-output.txt
		}
	}
	elseif ($Silent) {
		if ($Nano) {
			docker exec -u Administrator -w $Workingdir $ContainerId cmd /c "$Command" *>> Out-Null
		}
		elseif ($UseCmd) {
			docker exec -w $Workingdir $ContainerId cmd /c "$Command" *>> Out-Null
		}
		else {
			docker exec -w $Workingdir $ContainerId powershell -ExecutionPolicy Unrestricted "$Command" *>> Out-Null
		}
	}
	else {
		$Result = ""
		if ($Nano) {
			$Result = docker exec -u Administrator -w $Workingdir $ContainerId cmd /c "$Command"
		}
		elseif ($UseCmd) {
			$Result = docker exec -w $Workingdir $ContainerId cmd /c "$Command"
		}
		else {
			$Result = docker exec -w $Workingdir $ContainerId powershell -ExecutionPolicy Unrestricted "$Command"
		}
		return $Result
	}
}

function Check-ContainerIsNano {
	param($ContainerId)

	# This command is finicky and cannot use a powershell variable for the command
	$ContainerBase = Invoke-Container -ContainerId $containerId -UseCmd -Command "reg query `"hklm\software\microsoft\windows nt\currentversion`" /v EditionID"
	Write-Verbose "Container Base: $ContainerBase"
	# We only check for nano server as it is the most restrictive
	if ($ContainerBase -like "*Nano*") {
		return $true
	}
	else {
		return $false
	}
}

function Get-ContainersInfo {

	param($ContainerId)
	Get-NetFirewallProfile > $_CONTAINER_DIR\firewall_profile.txt
	Get-NetConnectionProfile >> $_CONTAINER_DIR\firewall_profile.txt
	netsh advfirewall firewall show rule name=* > $_CONTAINER_DIR\firewall_rules.txt
	netsh wfp show filters file=$_CONTAINER_DIR\wfpfilters.xml 2>&1 | Out-Null
	docker ps > $_CONTAINER_DIR\container-info.txt
	docker inspect $(docker ps -q) >> $_CONTAINER_DIR\container-info.txt
	docker network ls > $_CONTAINER_DIR\container-network-info.txt
	docker network inspect $(docker network ls -q) >> $_CONTAINER_DIR\container-network-info.txt

	docker top $containerId > $_CONTAINER_DIR\container-top.txt
	docker logs $containerId > $_CONTAINER_DIR\container-logs.txt

	wevtutil.exe set-log "Microsoft-Windows-Containers-CCG/Admin" /enabled:false 2>&1 | Out-Null
	wevtutil.exe export-log "Microsoft-Windows-Containers-CCG/Admin" $_CONTAINER_DIR\Containers-CCG_Admin.evtx /overwrite:true 2>&1 | Out-Null
	wevtutil.exe set-log "Microsoft-Windows-Containers-CCG/Admin" /enabled:true /rt:false /q:true 2>&1 | Out-Null
	Get-EventLog -LogName Application -Source Docker -After (Get-Date).AddMinutes(-30)  | Sort-Object Time | Export-CSV $_CONTAINER_DIR\docker_events.csv

}

function Check-ContainsScripts {
	param(
		$ContainerId,
		[switch]$IsNano
	)

	if ($IsNano) {
		$Result = Invoke-Container -ContainerId $containerId -Nano -Command "if exist auth.wprp (echo true)"

		if ($Result -eq "True") {

			$Result = Invoke-Container -ContainerId $containerId -Nano -Command "type auth.wprp"
			$Result = $Result[1]
			if (!$Result.Contains($_Authscriptver)) {
				$InnerScriptVersion = $Result.Split(" ")[1].Split("=")[1].Trim("`"")
				Write-Host "$ContainerId Script Version mismatch" Yellow
				Write-Host "Container Host Version: $_Authscriptver" Yellow
				Write-Host "Container Version: $InnerScriptVersion" Yellow
				return $false
			}
			Out-File -FilePath $_CONTAINER_DIR\script-info.txt -InputObject "SCRIPT VERSION: $_Authscriptver"
			return $true
		}
		else {
			return $false
		}
	}
	else {
		$StartResult = Invoke-Container -ContainerId $containerId -Command "Test-Path $($global:ScriptName)" -WorkingFolder "C:\TSS\TSSv2"
		$StopResult = Invoke-Container -ContainerId $containerId -Command "Test-Path $($global:ScriptName)" -WorkingFolder "C:\TSS\TSSv2"
		if ($StartResult -eq "True" -and $StopResult -eq "True") {
			# Checking script version
			<#
			$InnerScriptVersion = Invoke-Container -ContainerId $containerId -Command ".\start-auth.ps1 -accepteula -version"
			if ($InnerScriptVersion -ne $_Authscriptver) {
				Write-Host "$ContainerId Script Version mismatch" -ForegroundColor Yellow
				Write-Host "Container Host Version: $_Authscriptver" -ForegroundColor Yellow
				Write-Host "Container Version: $InnerScriptVersion" -ForegroundColor Yellow
				return $false
			}
			else {
				Out-File -FilePath $_CONTAINER_DIR\script-info.txt -InputObject "SCRIPT VERSION: $_Authscriptver"
				return $true
			}#>			
			return $true
		}
		else {
			#Write-Host "Container: $ContainerId missing tracing scripts!" -ForegroundColor Yellow
			return $false
		}
	}
}

function Check-GMSA-Stop {
	param($ContainerId)

	$CredentialString = docker inspect -f "{{ .HostConfig.SecurityOpt }}" $ContainerId

	if ($CredentialString -ne "[]") {
		Write-Verbose "GMSA Credential String: $CredentialString"
		# NOTE(will): We need to check if we have RSAT installed
		if ((Get-Command "Test-ADServiceAccount" -ErrorAction "SilentlyContinue") -ne $null) {
			$ServiceAccountName = $(docker inspect -f "{{ .Config.Hostname }}" $ContainerId)
			$Result = "`nSTOP:`n`nRunning Test-ADServiceAccount $ServiceAccountName`nResult:"
			try {
				$Result += Test-ADServiceAccount -Identity $ServiceAccountName -Verbose -ErrorAction SilentlyContinue
			}
			catch {
				$Result += "Unable to find object with identity $containerId"
			}

			Out-File $_CONTAINER_DIR\gMSATest.txt -InputObject $Result -Append
		}

		$CredentialName = $CredentialString.Replace("[", "").Replace("]", "")
		$CredentialName = $CredentialName.Split("//")[-1]
		$CredentialObject = Get-CredentialSpec | Where-Object { $_.Name -eq $CredentialName }
		Copy-Item $CredentialObject.Path $_CONTAINER_DIR
	}
}

function Check-GMSA-Start {
	param($ContainerId)

	$CredentialString = docker inspect -f "{.HostConfig.SecurityOpt}" $ContainerId
	if ($CredentialString -ne "[]") {
		Write-Verbose "GMSA Credential String: $CredentialString"
		# We need to check if we have Test-ADServiceAccount
		if ((Get-Command "Test-ADServiceAccount" -ErrorAction "SilentlyContinue") -ne $null) {
			$ServiceAccountName = $(docker inspect -f "{{ .Config.Hostname }}" $ContainerId)
			$Result = "START:`n`nRunning: Test-ADServiceAccount $ServiceAccountName`nResult:"

			try {
				$Result += Test-ADServiceAccount -Identity $ServiceAccountName -Verbose -ErrorAction SilentlyContinue
			}
			catch {
				$Result += "Unable to find object with identity $containerId"
			}

			Out-File $_CONTAINER_DIR\gMSATest.txt -InputObject $Result
		}
	}
}

function Generate-WPRP {
	param($ContainerId)
	$Header = @"
<?xml version="1.0" encoding="utf-8"?>
<WindowsPerformanceRecorder Version="$_Authscriptver" Author="Microsoft Corporation" Copyright="Microsoft Corporation" Company="Microsoft Corporation">
  <Profiles>

"@
	$Footer = @"
  </Profiles>
</WindowsPerformanceRecorder>
"@


	$Netmon = "{2ED6006E-4729-4609-B423-3EE7BCD678EF}"

	$ProviderList = (("NGC", $NGC),
	 ("Biometric", $Biometric),
	 ("LSA", $LSA),
	 ("Ntlm_CredSSP", $Ntlm_CredSSP),
	 ("Kerberos", $Kerberos),
	 ("KDC", $KDC),
	 ("SSL", $SSL),
	 ("WebAuth", $WebAuth),
	 ("Smartcard", $Smartcard),
	 ("CredprovAuthui", $CredprovAuthui),
	 ("AppX", $AppX),
	 ("SAM", $SAM),
	 ("kernel", $Kernel),
	 ("Netmon", $Netmon))

	# NOTE(will): Checking if Client SKU
	$ClientSKU = Invoke-Container -ContainerId $ContainerId -Nano -Command "reg query HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions /v ProductType | findstr WinNT"
	if ($ClientSKU -ne $null) {
		$ProviderList.Add(("CryptNcryptDpapi", $CryptNcryptDpapi))
	}

	foreach ($Provider in $ProviderList) {
		$ProviderName = $Provider[0]
		$Header += @"
	<EventCollector Id="EventCollector$ProviderName" Name="EventCollector$ProviderName">
	  <BufferSize Value="64" />
	  <Buffers Value="4" />
	</EventCollector>

"@
	}

	$Header += "`n`n"

	# Starting on provider generation

	foreach ($Provider in $ProviderList) {
		$ProviderCount = 0
		$ProviderName = $Provider[0]

		foreach ($ProviderItem in $Provider[1]) {
			$ProviderParams = $ProviderItem.Split("!")
			$ProviderGuid = $ProviderParams[0].Replace("{", '').Replace("}", '')
			$ProviderFlags = $ProviderParams[1]

			$Header += @"
	<EventProvider Id="$ProviderName$ProviderCount" Name="$ProviderGuid"/>

"@
			$ProviderCount++
		}
	}

	# Generating profiles
	foreach ($Provider in $ProviderList) {
		$ProviderName = $Provider[0]
		$Header += @"
  <Profile Id="$ProviderName.Verbose.File" Name="$ProviderName" Description="$ProviderName.1" LoggingMode="File" DetailLevel="Verbose">
	<Collectors>
	  <EventCollectorId Value="EventCollector$ProviderName">
		<EventProviders>

"@
		$ProviderCount = 0
		for ($i = 0; $i -lt $Provider[1].Count; $i++) {
			$Header += "`t`t`t<EventProviderId Value=`"$ProviderName$ProviderCount`" />`n"
			$ProviderCount++
		}

		$Header += @"
		</EventProviders>
	  </EventCollectorId>
	</Collectors>
  </Profile>
  <Profile Id="$ProviderName.Light.File" Name="$ProviderName" Description="$ProviderName.1" Base="$ProviderName.Verbose.File" LoggingMode="File" DetailLevel="Light" />
  <Profile Id="$ProviderName.Verbose.Memory" Name="$ProviderName" Description="$ProviderName.1" Base="$ProviderName.Verbose.File" LoggingMode="Memory" DetailLevel="Verbose" />
  <Profile Id="$ProviderName.Light.Memory" Name="$ProviderName" Description="$ProviderName.1" Base="$ProviderName.Verbose.File" LoggingMode="Memory" DetailLevel="Light" />

"@

		# Keep track of the providers that are currently running
		Out-File -FilePath "$_CONTAINER_DIR\RunningProviders.txt" -InputObject "$ProviderName" -Append
	}


	$Header += $Footer

	# Writing to a file
	Out-file -FilePath "auth.wprp" -InputObject $Header -Encoding ascii

}

function Start-NanoTrace {
	param($ContainerId)

	# Event Logs
	foreach ($EventLog in $_EVENTLOG_LIST_START) {
		$EventLogParams = $EventLog.Split("!")
		$EventLogName = $EventLogParams[0]
		$EventLogOptions = $EventLogParams[1]

		$ExportLogName += ".evtx"

		if ($EventLogOptions -ne "NONE") {
			Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "wevtutil set-log $EventLogName /enabled:true /rt:false /q:true"

			if ($EventLogOptions.Contains("EXPORT")) {
				$ExportName = $EventLogName.Replace("Microsoft-Windows-", "").Replace(" ", "_").Replace("/", "_")
				Invoke-Container -ContainerId $ContainerId -Nano -Record -PreTrace -Command "wevtutil export-log $EventLogName $ExportName /overwrite:true"
			}
			if ($EventLogOptions.Contains("CLEAR")) {
				Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "wevtutil clear-log $EventLogName"
			}
			if ($EventLogOptions.Contains("SIZE")) {
				Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "wevtutil set-log $EventLogName /ms:102400000"
			}
		}
	}

	# Reg Add
	foreach ($RegAction in $_REG_ADD_START) {
		$RegParams = $RegAction.Split("!")
		$RegKey = $RegParams[0]
		$RegName = $RegParams[1]
		$RegType = $RegParams[2]
		$RegValue = $RegParams[3]

		Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "reg add $RegKey /v $RegName /t $RegType /d $RegValue /f"
	}

	Get-Content "$_CONTAINER_DIR\RunningProviders.txt" | ForEach-Object {
		Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "wpr -start auth.wprp!$_ -instancename $_"
	}


}

function Stop-NanoTrace {
	param($ContainerId)

	Get-Content "$_CONTAINER_DIR\RunningProviders.txt" | ForEach-Object {
		Invoke-Container -ContainerId $ContainerId -Nano -AuthDir -Record -Command "wpr -stop $_`.etl -instancename $_"
	}

	# Cleaning up registry keys
	foreach ($RegDelete in $_REG_DELETE) {
		$DeleteParams = $RegDelete.Split("!")
		$DeleteKey = $DeleteParams[0]
		$DeleteValue = $DeleteParams[1]
		Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "reg delete `"$DeleteKey`" /v $DeleteValue /f"
	}

	# Querying registry keys
	foreach ($RegQuery in $_REG_QUERY) {
		$QueryParams = $RegQuery.Split("!")
		$QueryKey = $QueryParams[0]
		$QueryOptions = $QueryParams[1]
		$QueryOutput = $QueryParams[2]

		$QueryOutput = "$QueryOutput`-key.txt"
		$AppendFile = Invoke-Container -ContainerId $ContainerId -AuthDir -Nano -Command "if exist $QueryOutput (echo True)"

		Write-Verbose "Append Result: $AppendFile"
		$Redirect = "> $QueryOutput"

		if ($AppendFile -eq "True") {
			$Redirect = ">> $QueryOutput"
		}


		if ($QueryOptions -eq "CHILDREN") {
			Invoke-Container -ContainerId $ContainerId -AuthDir -Nano -Record -Command "reg query `"$QueryKey`" /s $Redirect"
		}
		else {
			Invoke-Container -ContainerId $ContainerId -AuthDir -Nano -Record -Command "reg query `"$QueryKey`" $Redirect"
		}

	}

	foreach ($EventLog in $_EVENTLOG_LIST_STOP) {
		$EventLogParams = $EventLog.Split("!")
		$EventLogName = $EventLogParams[0]
		$EventLogOptions = $EventLogParams[1]

		$ExportName = $EventLogName.Replace("Microsoft-Windows-", "").Replace(" ", "_").Replace("/", "_")

		if ($EventLogOptions -ne "DEFAULT") {
			Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "wevtutil set-log $EventLogName /enabled:false"
		}

		Invoke-Container -ContainerId $ContainerId -Nano -Record -AuthDir -Command "wevtutil export-log $EventLogName $ExportName.evtx /overwrite:true"

		if ($EventLogOptions -eq "ENABLE") {
			Invoke-Container -ContainerId $ContainerId -Nano -Record -Command "wevtutil set-log $EventLogName /enabled:true /rt:false" *>> $_CONTAINER_DIR\container-output.txt
		}
	}
}
#endregion container_functions

#region FW_functions

function FWStart-ContainerTracing
{
	Param(
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$containerId,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$TSSScriptsSourceFolderonHost,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$TSSScriptTargetFolderInContainer,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$TSSStartCommandToExecInContainer,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$TSSWorkingFolderInContainer
	)
	EnterFunc $MyInvocation.MyCommand.Name

	# Confirm that docker is in our path
	$DockerExists = (Get-Command "docker.exe" -ErrorAction SilentlyContinue) -ne $null
	if ($DockerExists) {
		LogInfo "Docker.exe found"
		$RunningContainers = $(docker ps -q)
		if ($containerId -in $RunningContainers) {
			LogInfo "$containerId found"
			$_CONTAINER_DIR = "$_BASE_C_DIR`-$containerId"
			if ((Test-Path $_CONTAINER_DIR\started.txt)) {
				LogInfo "Container tracing already started. Please run $($global:ScriptName) -stop to stop the tracing and start tracing again"
					exit
				}
			New-Item $_CONTAINER_DIR -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
			Remove-Item $_CONTAINER_DIR\* -Recurse -ErrorAction SilentlyContinue | Out-Null

			# Confirm the running container base image
			if (Check-ContainerIsNano -ContainerId $containerId) {

				LogInfo "Container Image is NanoServer"
				Out-File -FilePath $_CONTAINER_DIR\container-base.txt -InputObject "Nano"

				# We need to use the wprp for the auth data collection
				if (!(Test-Path "$_CONTAINER_DIR\auth.wprp") -and !(Test-Path "$_CONTAINER_DIR\RunningProviders.txt")) {
					Generate-WPRP -ContainerId $containerId
				}

				# Checking if the container has the tracing scripts
				if (Check-ContainsScripts -ContainerId $containerId -IsNano) {
					LogInfo "Starting container tracing - please wait..."
					Start-NanoTrace -ContainerId $containerId
				}
				else {
					LogInfo "Container: $containerId missing tracing script!" Yellow
					# $_BASE_LOG_DIR could be used insted of C:\authscripts
					LogInfo "Please copy the auth.wprp into the $TSSScriptTargetFolderInContainer\TSSv2 directory in the container then run $($global:ScriptName) -containerId $containerId $TSSCommand again
	Example:
	`tdocker stop $containerId
	`tdocker cp auth.wprp $containerId`:\$TSSScriptTargetFolderInContainer
	`tdocker start $containerId
	`t.\$($global:ScriptName) -containerId $containerId $TSSStartCommandToExecInContainer" Yellow
						return
				}

			}
			else {
				LogInfo "Container Image is Standard"
				Out-File -FilePath $_CONTAINER_DIR\container-base.txt -InputObject "Standard"

				if (Check-ContainsScripts -ContainerId $containerId) {
					LogInfo "Starting container tracing - please wait..."
					Invoke-Container -ContainerId $ContainerId -Record -Command "TSSv2\$($global:ScriptName) $TSSStartCommandToExecInContainer"
				}
				else {

				LogInfo "Copy TSS script to container started."
				docker stop $containerId 2>&1 | Out-Null
				docker cp $TSSScriptsSourceFolderonHost $containerId`:\$TSSScriptTargetFolderInContainer 2>&1 | Out-Null
				docker start $containerId 2>&1 | Out-Null
				LogInfo "Copy TSS script to container completed."
				LogInfo "Starting trace command $($global:ScriptName) $TSSStartCommandToExecInContainer"
				Invoke-Container -ContainerId $ContainerId -Record -Command "TSSv2\$($global:ScriptName) $TSSStartCommandToExecInContainer"
				LogInfo "TSS Tracing started, tracing runs, please use $($global:ScriptName) -Stop command to stop tracing"
				<#
					LogInfo "Please copy $TSSScriptsSourceFolderonHost into the $TSSScriptTargetFolderInContainer directory in the container and run TSS.ps1 -containerId $containerId $TSSStartCommandToExecInContainer again
	Example:
	`tdocker stop $containerId
	`tdocker cp $TSSScriptsSourceFolderonHost $containerId`:\$TSSScriptTargetFolderInContainer
	`tdocker start $containerId
	`tdocker exec -w $TSSWorkingFolderInContainer $containerId powershell -ExecutionPolicy Unrestricted `".\TSS.ps1 $TSSStartCommandToExecInContainer`"" Yellow
	#>
					exit #return
				}
			}
		}
		else {
			LogInfo "Failed to find $containerId"
			return
		}
	}
	else {
		LogInfo "Unable to find docker.exe in system path."
		return
	}

	Check-GMSA-Start -ContainerId $containerId

	# Start Container Logging
	$installedBuildVer = New-Object System.Version([version]$Global:OS_Version)
	$minPktMonBuildVer = New-Object System.Version([version]("10.0.17763.1852"))
	if ($($installedBuildVer.CompareTo($minPktMonBuildVer)) -ge 0) { # if installed Build version is greater than OS Build 17763.1852 from KB5000854
		pktmon start --capture -f $_CONTAINER_DIR\Pktmon.etl -s 4096 2>&1 | Out-Null
	}
	else {
		netsh trace start capture=yes persistent=yes report=disabled maxsize=4096 scenario=NetConnection traceFile=$_CONTAINER_DIR\netmon.etl | Out-Null
	}

	Add-Content -Path $_CONTAINER_DIR\script-info.txt -Value ("Data collection started on: " + (Get-Date -Format "yyyy/MM/dd HH:mm:ss"))
	Add-Content -Path $_CONTAINER_DIR\started.txt -Value "Started"

	return	
}

function FWStop-ContainerTracing
{
	Param(
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$containerId,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$TSSStopCommandToExecInContainer,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$TSSWorkingFolderInContainer
	)
	EnterFunc $MyInvocation.MyCommand.Name

	$_CONTAINER_DIR = "$_BASE_C_DIR`-$containerId"

   # no need to check this again
   # if (!(Test-Path "$_CONTAINER_DIR\started.txt")) {
   #		 LogInfo "Container tracing already started. Please run TSS.ps1 $TSSStopCommandToExecInContainer to stop the tracing and start tracing again"
   #		 return
   #  }

	LogInfo "Stopping Container tracing"
	$RunningContainers = $(docker ps -q)
	if ($containerId -in $RunningContainers) {
		LogInfo "$containerId Found"
		LogInfo "Stopping data collection..."
		if ((Get-Content $_CONTAINER_DIR\container-base.txt) -eq "Nano") {
			LogInfo "Stopping Nano container data collection"
			# NOTE(will) Stop the wprp
			Stop-NanoTrace -ContainerId $containerId
		}
		else {
			LogInfo "Stopping Standard container data collection"
			Invoke-Container -ContainerId $containerId -Record -Command "TSSv2\$($global:ScriptName) $($TSSStopCommandToExecInContainer)"
		}
	}
	else {
		LogInfo "Failed to find $containerId"
		return
	}

	LogInfo "`Collecting Container Host Device configuration information, please wait..."
	Check-GMSA-Stop -ContainerId $containerId
	Get-ContainersInfo -ContainerId $containerId

	# Stop Pktmon
	if ((Get-HotFix | Where-Object { $_.HotFixID -gt "KB5000854" -and $_.Description -eq "Update" } | Measure-object).Count -ne 0) { #we# better check for OS Build 17763.1852 or higher!
		pktmon stop 2>&1 | Out-Null
		pktmon list -a > $_CONTAINER_DIR\pktmon_components.txt
	}
	else {
		# consider removing it and using TSS FW for network trace 
		netsh trace stop | Out-Null
	}

	Add-Content -Path $_CONTAINER_DIR\script-info.txt -Value ("Data collection stopped on: " + (Get-Date -Format "yyyy/MM/dd HH:mm:ss"))
	if ((Test-Path $_CONTAINER_DIR\started.txt)) {
		Remove-Item -Path $_CONTAINER_DIR\started.txt -Force | Out-Null
		}



	LogInfo "The tracing is stopping, please wait..."
	docker stop $containerId 2>&1 | Out-Null
	docker cp $containerId`:\MS_DATA $_CONTAINER_DIR 2>&1 | Out-Null
	docker start $containerId 2>&1 | Out-Null
	LogInfo "Data copied to $_CONTAINER_DIR"
	docker exec --privileged $containerId cmd /c rd /s /q C:\TSS
	docker exec --privileged $containerId cmd /c rd /s /q c:\MS_DATA
	LogInfo "The tracing has been completed, please find the data in $_CONTAINER_DIR on the host machine."

	<#Please copy the collected data to the logging directory"
		LogInfo "Example:
	`tdocker stop $containerId
	`tdocker cp $containerId`:\MS_DATA $_CONTAINER_DIR
	`tdocker start $containerId" Yellow
	 #>
	 return

}


function global:FWEnter-ContainerTracing
{
	Param(
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$fwcontainerId,
		[parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$fwTSSScriptsSourceFolderonHost,
		[parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$fwTSSScriptTargetFolderInContainer,
		[parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$fwTSSStartCommandToExecInContainer,
		[parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[String]$fwTSSStopCommandToExecInContainer
	)
	EnterFunc $MyInvocation.MyCommand.Name


	$_BASE_LOG_DIR = "C:\MS_DATA" #$global:LogFolder #".\authlogs"
	$_LOG_DIR = $_BASE_LOG_DIR
	$_CH_LOG_DIR = "$_BASE_LOG_DIR\container-host"
	$_BASE_C_DIR = "$_BASE_LOG_DIR`-container"
	$_C_LOG_DIR = "$_BASE_LOG_DIR\container"

	$TSScontainerId = $fwcontainerId 
	$TSSScriptsSourceFolderonHost = (Get-Location).Path #Split-Path (Get-Location).Path -parent
	$TSSScriptTargetFolderInContainer =  "TSS" # we should always use "TSS", if required use $fwTSSScriptTargetFolderInContainer
	$TSSWorkingFolderInContainer = "$fwTSSScriptTargetFolderInContainer\TSSv2"
	$TSSStartCommandToExecInContainer = $fwTSSStartCommandToExecInContainer
	$TSSStopCommandToExecInContainer = $fwTSSStopCommandToExecInContainer

	if (($TSSStartCommandToExecInContainer -ne "") -and ($TSSStopCommandToExecInContainer -ne ""))
	{
		LogInfo ("Invalid Call to FWEnter-ContainerTracing: please specify start or stop tracing command, not both of them at the same time")
		Exit
	}

	if ($TSSStartCommandToExecInContainer -ne "")
	{
	FWStart-ContainerTracing -containerId $TSScontainerId -TSSScriptsSourceFolderonHost $TSSScriptsSourceFolderonHost `
			-TSSScriptTargetFolderInContainer $TSSScriptTargetFolderInContainer -TSSStartCommandToExecInContainer $TSSStartCommandToExecInContainer -TSSWorkingFolderInContainer $TSSWorkingFolderInContainer
	}
	elseif ($TSSStopCommandToExecInContainer -ne "")
	{
		FWStop-ContainerTracing -containerId $TSScontainerId -TSSStopCommandToExecInContainer $TSSStopCommandToExecInContainer -TSSWorkingFolderInContainer $TSSWorkingFolderInContainer
	}
	else
	{
		LogInfo ("Please specify either start or stop command")
	}

}

#endregion FW_functions

Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *


# SIG # Begin signature block
# MIIoPAYJKoZIhvcNAQcCoIIoLTCCKCkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCblBjx4unD4+H1
# tG/2eGceARcx2lhuheKOXyBS2B3owKCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC0b
# iaqHKhaMNOV/PYU4ynEehJhC7Vx9B66GrhEtGCKtMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAwCPo+MnHDxDozaj+QGHIz+//4R3E41mBeVdh
# 4ZCDZermOHox3D6QFAjQ9eA4luYDNE4ER0WH5A15Y6Ldg2W10V6UVwfgS2IlXHFl
# lZAKI7gh/WdrKs4KA30aIb75WD5AQ1at4/BDzSvdShoNxq7tLxsdG6AAcCdOpYRK
# 5BENG7L8LB3nEQb3XSjIRZ/z0h53JXdhAXdhnn8jE/5GMfe59ED6s7n4EiuONi87
# gc60/pzCpLpWlD1PihI1bVO3QzHpuYUR68bAoBkrEfZPTp5PwMljkcek8nnB5yH/
# +6//OCv+7dTPvWaKm/OtnbgFW3NLoegAq3xk0kRrmmoTkNhYKqGCF5cwgheTBgor
# BgEEAYI3AwMBMYIXgzCCF38GCSqGSIb3DQEHAqCCF3AwghdsAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFSBgsqhkiG9w0BCRABBKCCAUEEggE9MIIBOQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCCN4W/nKS4/+F407NzxNgdP+12G+7Z46L3c
# Cxq7ryfoSwIGZkYCnHMoGBMyMDI0MDYxMjE0NTg0OC4zNjFaMASAAgH0oIHRpIHO
# MIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
# IFRTUyBFU046QTAwMC0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFNlcnZpY2WgghHtMIIHIDCCBQigAwIBAgITMwAAAevgGGy1tu847QAB
# AAAB6zANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDAeFw0yMzEyMDYxODQ1MzRaFw0yNTAzMDUxODQ1MzRaMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTAwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDBFWgh2lbgV3eJp01oqiaF
# BuYbNc7hSKmktvJ15NrB/DBboUow8WPOTPxbn7gcmIOGmwJkd+TyFx7KOnzrxnoB
# 3huvv91fZuUugIsKTnAvg2BU/nfN7Zzn9Kk1mpuJ27S6xUDH4odFiX51ICcKl6EG
# 4cxKgcDAinihT8xroJWVATL7p8bbfnwsc1pihZmcvIuYGnb1TY9tnpdChWr9EARu
# Co3TiRGjM2Lp4piT2lD5hnd3VaGTepNqyakpkCGV0+cK8Vu/HkIZdvy+z5EL3ojT
# dFLL5vJ9IAogWf3XAu3d7SpFaaoeix0e1q55AD94ZwDP+izqLadsBR3tzjq2RfrC
# NL+Tmi/jalRto/J6bh4fPhHETnDC78T1yfXUQdGtmJ/utI/ANxi7HV8gAPzid9TY
# jMPbYqG8y5xz+gI/SFyj+aKtHHWmKzEXPttXzAcexJ1EH7wbuiVk3sErPK9MLg1X
# b6hM5HIWA0jEAZhKEyd5hH2XMibzakbp2s2EJQWasQc4DMaF1EsQ1CzgClDYIYG6
# rUhudfI7k8L9KKCEufRbK5ldRYNAqddr/ySJfuZv3PS3+vtD6X6q1H4UOmjDKdjo
# W3qs7JRMZmH9fkFkMzb6YSzr6eX1LoYm3PrO1Jea43SYzlB3Tz84OvuVSV7NcidV
# tNqiZeWWpVjfavR+Jj/JOQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFHSeBazWVcxu
# 4qT9O5jT2B+qAerhMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQCDdN8voPd8C+VW
# ZP3+W87c/QbdbWK0sOt9Z4kEOWng7Kmh+WD2LnPJTJKIEaxniOct9wMgJ8yQywR8
# WHgDOvbwqdqsLUaM4NrertI6FI9rhjheaKxNNnBZzHZLDwlkL9vCEDe9Rc0dGSVd
# 5Bg3CWknV3uvVau14F55ESTWIBNaQS9Cpo2Opz3cRgAYVfaLFGbArNcRvSWvSUbe
# I2IDqRxC4xBbRiNQ+1qHXDCPn0hGsXfL+ynDZncCfszNrlgZT24XghvTzYMHcXio
# LVYo/2Hkyow6dI7uULJbKxLX8wHhsiwriXIDCnjLVsG0E5bR82QgcseEhxbU2d1R
# VHcQtkUE7W9zxZqZ6/jPmaojZgXQO33XjxOHYYVa/BXcIuu8SMzPjjAAbujwTawp
# azLBv997LRB0ZObNckJYyQQpETSflN36jW+z7R/nGyJqRZ3HtZ1lXW1f6zECAeP+
# 9dy6nmcCrVcOqbQHX7Zr8WPcghHJAADlm5ExPh5xi1tNRk+i6F2a9SpTeQnZXP50
# w+JoTxISQq7vBij2nitAsSLaVeMqoPi+NXlTUNZ2NdtbFr6Iir9ZK9ufaz3FxfvD
# Zo365vLOozmQOe/Z+pu4vY5zPmtNiVIcQnFy7JZOiZVDI5bIdwQRai2quHKJ6ltU
# dsi3HjNnieuE72fT4eWhxtmnN5HYCDCCB3EwggVZoAMCAQICEzMAAAAVxedrngKb
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
# ELQdVTNYs6FwZvKhggNQMIICOAIBATCB+aGB0aSBzjCByzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
# Y2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkEwMDAtMDVF
# MC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMK
# AQEwBwYFKw4DAhoDFQCABol1u1wwwYgUtUowMnqYvbul3qCBgzCBgKR+MHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUAAgUA6hQXoDAi
# GA8yMDI0MDYxMjEyNDgzMloYDzIwMjQwNjEzMTI0ODMyWjB3MD0GCisGAQQBhFkK
# BAExLzAtMAoCBQDqFBegAgEAMAoCAQACAgTeAgH/MAcCAQACAhXRMAoCBQDqFWkg
# AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSCh
# CjAIAgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAD346r/S01DVyLJLxj17gzIQ
# KD5LQ7/U5REvu1lKBpz4G+gA471IxFfO2TDAH1J5WOkeMEysyh9O5+qYjq2eaKV4
# j+XN9eyYI8Qe/9Jz+ZuM3cTNsPAVRbbaTZlizEsm+58GR99qM7CaDUCWWxr6AeKE
# 7zEeprENPKRgqQXmFDn1Giwdn384PXdnwShXFNtSfu4JC0UsvF3DpzvrORpNKdjt
# qt3mJDDqGAqXUV1+jN02dBDS2SNwekFM+hnD2GxtxbpYGXCdv/8KvTsqzTHM+P23
# A9tn3Q939DdGrfhAZdzSLsY9bDsaw7gorVgkV6rJi+cEB6FYwu+pSrBdV/qXwqMx
# ggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAA
# AevgGGy1tu847QABAAAB6zANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkD
# MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCAh/gLXLq6RDBmI3BT1NNmR
# o88yLc4tFTG197pDjgF/cTCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIM63
# a75faQPhf8SBDTtk2DSUgIbdizXsz76h1JdhLCz4MIGYMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHr4BhstbbvOO0AAQAAAeswIgQgrG8k
# wtai/J8ST/xSNgTY1PHrlYOs8Vkg46gnVoU16f8wDQYJKoZIhvcNAQELBQAEggIA
# Sfzsf8rFOpHYeEivPRkusBFYPJUPduEzKZkZ2Kun5Di8gcl6SysbBEiWVZKZ+89l
# K7Mp+mdnrrPL3e8j6ery/aB6An3i0FegmkMkCLmaayoc1xI0YRIHPeyOWVCplSNG
# uLaUzPP6rzVDofjfMklzI+Kg5HcSBpOhaR6jS479xMBleucZQZGGp9RT/BVPtVoN
# Fi3lSZXLlbrGKbC0FRGkdvzGPXSPzX/+dF/v265zZMcNmB7o/JdfScbFYi0H+mDG
# 3pboKcOrbe5dMG4ezCeuS6mDmaLzHIKiwfLz46NCNlZYvNWzM2wPSppxHyKPR+HT
# bYXQ2mHsF/gB9nH/VO0hMPnf06fjcEXqeJNzhteg4BBlZvTtWMQ6kRo6Oe4hXA63
# 9sLn1fqeBYi5M8kV2BoQkGV+S4KVtSvv47k24wsNzaj18ACHyHENxhSRNnfTRT6X
# TaLlHdVMVd6ZOdIyCQHk4wUw3zpCPMq6youY31yqN8dBQjV81S6smgHW/8uL2X4M
# HmmspObhngdqNDRXYqlrH0P5RQOvVF1t4AaUqfTZZLLTb9iN0LiV7XIgvKH9/zt+
# 9Z3HLLN6nDK3r6QWIesGzhI2plB6Cvgmru/nvcg0VdALeRlsvflevrL6/4Pat46Q
# cg5Pvi06cpLNsCSABhImVdn/SJFbEJkmLrlx2X5/MFc=
# SIG # End signature block
