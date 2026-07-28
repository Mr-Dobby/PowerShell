Write-Host "Closing all instances of Google Chrome..."
cmd /c taskkill /IM Chrome.exe /F

#Identify version and GUID of Google Chrome
Write-Host "Identifying Google Chrome location..."
$AppInfo = Get-WmiObject Win32_Product -Filter "Name Like 'Google Chrome'"
$ChromeVer = $AppInfo.Version
$GUID = $AppInfo.IdentifyingNumber
Write-Host "Google Chrome is installed as version:" $ChromeVer
Write-Host "Google Chrome has GUID of:" $GUID


#Uninstall using MSIEXEC
Write-Host "Attempting uninstall using MSIEXEC..."
& ${env:WINDIR}\System32\msiexec /x $GUID /Quiet /Passive /NoRestart


#Uninstall using Setup.exe uninstaller
Write-Host "Attempting uninstall using Setup.exe uninstaller..."
if (Test-Path -Path C:\Progra~1\Google\Chrome\Application\$ChromeVer\Installer\) {
    Write-Host "Google Chrome is installed as 64-bit program..."
    & "C:\Program Filses\Google\Chrome\Application\$ChromeVer\Installer\setup.exe" --uninstall --multi-install --chrome --system-level --force-uninstall
}
if (Test-Path -Path C:\Progra~2\Google\Chrome\Application\$ChromeVer\Installer\) {
    Write-Host "Google Chrome is installed as 32-bit program..."
    & "C:\Program Filses (x86)\Google\Chrome\Application\$ChromeVer\Installer\setup.exe" --uninstall --multi-install --chrome --system-level --force-uninstall
}

#Uninstall using WMIC
Write-Host "Attempting uninstall using WMIC..."
wmic product where "name like 'Google Chrome'" call uninstall /nointeractive


#Look for Google Chrome in HKEY_CLASSES_ROOT\Installer\Products\
Write-Host "Deleting Google Chrome folder from HKLM:\Software\Classes\Installer\Products\"
$RegPath = "HKLM:\Software\Classes\Installer\Products\"

$ChromeRegKey = Get-ChildItem -Path $RegPath | Get-ItemProperty | Where-Object {$_.ProductName -match "Google Chrome"}
    
Write-Host "Product name found:" $ChromeRegKey.ProductName
Write-Host "Folder name found:" $ChromeRegKey.PSChildName

if (!$ChromeRegKey.PSChildName) {
    Write-Host "Google Chrome not found in HKEY_CLASSES_ROOT\Installer\Products\"
} 
if ($ChromeRegKey.PSChildName) {
    $ChromeDirToDelete = "HKLM:\Software\Classes\Installer\Products\" + $ChromeRegKey.PSChildName
    Write-Host "Google Chrome directory to delete:" $ChromeDirToDelete
    Remove-Item -Path $ChromeDirToDelete -Force -Recurse
}

Remove-Item -Path "HKCR:\AppID\{708860E0-F641-4611-8895-7D867DD3675B}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\GoogleUpdate.PolicyStatus" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\GoogleUpdate.PolicyStatus.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\Interface\{1B9063E4-3882-485E-8797-F28A0240782F}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\Interface\{6DFFE7FE-3153-4AF1-95D8-F8FCCA97E56B}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\Interface\{DDD4B5D4-FD54-497C-8789-0830F29A60EE}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\Interface\{FCE48F77-C677-4012-8A1A-54D2E2BC07BD}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\WOW6432Node\CLSID\{9F3F5F5D-721A-4B19-9B5D-69F664C1A591}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\WOW6432Node\Interface\{1B9063E4-3882-485E-8797-F28A0240782F}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\WOW6432Node\Interface\{6DFFE7FE-3153-4AF1-95D8-F8FCCA97E56B}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\WOW6432Node\Interface\{79E0C401-B7BC-4DE5-8104-71350F3A9B67}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\WOW6432Node\Interface\{DDD4B5D4-FD54-497C-8789-0830F29A60EE}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKCR:\WOW6432Node\Interface\{FCE48F77-C677-4012-8A1A-54D2E2BC07BD}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\.htm\OpenWithProgids\ChromeHTML" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\.html\OpenWithProgids\ChromeHTML" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\.shtm\OpenWithProgids\ChromeHTML" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\.webp\OpenWithProgids\ChromeHTML" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\.webp\ShellEx\{BB2E617C-0920-11d1-9A0B-00C04FC2D6C1}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\.xht\OpenWithProgids\ChromeHTML" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\.xhtml\OpenWithProgids\ChromeHTML" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\AppID\{4EB61BAC-A3B6-9581-655041EF4D69}\" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\AppID\{9465B4B4-5216-4042-9A2C-754D3BCDC410}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\AppID\GoogleUpdate.exe" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\ChromeHTML" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Classes\Clients\StartMenuInternet\Google Chrome" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\CLSID\{9D6AA569-9F30-41AD-885A-346685C74928}\InprocServer32HKLM:\SOFTWARE\Classes\GoogleUpdate.CoCreateAsync" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.CoCreateAsync.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.CoreClass" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.CoreClass.1" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.CredentialDialogMachine" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.CredentialDialogMachine.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.OnDemandCOMClassMachine" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.OnDemandCOMClassMachine.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.OnDemandCOMClassMachineFallback" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.OnDemandCOMClassMachineFallback.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.OnDemandCOMClassSvc" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.OnDemandCOMClassSvc.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.ProcessLauncher" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.ProcessLauncher.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3COMClassService" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3COMClassService.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3WebMachine" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3WebMachine.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3WebMachineFallback" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3WebMachineFallback.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3WebSvc" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\GoogleUpdate.Update3WebSvc.1.0" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{084D78A8-B084-4E14-A629-A2C419B0E3D9}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{0CD01D1E-4A1C-489D-93B9-9B6672877C57}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{128C2DA6-2BC0-44C0-B3F6-4EC22E647964}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{18D0F672-18B4-48E6-AD36-6E6BF01DBBC4}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{19692F10-ADD2-4EFF-BE54-E61C62E40D13}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{1C642CED-CA3B-4013-A9DF-CA6CE5FF6503}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{247954F9-9EDC-4E68-8CC3-150C2B89EADF}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{2D363682-561D-4C3A-81C6-F2F82107562A}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{2E629606-312A-482F-9B12-2C4ABF6F0B6D}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{31AC3F11-E5EA-4A85-8A3D-8E095A39C27B}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{3D05F64F-71E3-48A5-BF6B-83315BC8AE1F}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{494B20CF-282E-4BDD-9F5D-B70CB09D351E}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{49D7563B-2DDB-4831-88C8-768A53833837}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{4DE778FE-F195-4EE3-9DAB-FE446C239221}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{4E223325-C16B-4EEB-AEDC-19AA99A237FA}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{5B25A8DC-1780-4178-A629-6BE8B8DEFAA2}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{6DB17455-4E85-46E7-9D23-E555E4B005AF}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{76F7B787-A67C-4C73-82C7-31F5E3AABC5C}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{79E0C401-B7BC-4DE5-8104-71350F3A9B67}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{8476CE12-AE1F-4198-805C-BA0F9B783F57}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{909489C2-85A6-4322-AA56-D25278649D67}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{B3A47570-0A85-4AEA-8270-529D47899603}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{BCDCB538-01C0-46D1-A6A7-52F4D021C272}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{D106AB5F-A70E-400E-A21B-96208C1D8DBB}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{DAB1D343-1B2A-47F9-B445-93DC50704BFE}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{DCAB8386-4F03-4DBD-A366-D90BC9F68DE6}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{DD42475D-6D46-496A-924E-BD5630B4CBBA}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Interface\{FE908CDD-22BB-472A-9870-1A0390E42F36}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{25461599-633D-42B1-84FB-7CD68D026E53}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{4EB61BAC-A3B6-4760-9581-655041EF4D69}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{534F5323-3569-4F42-919D-1E1CF93E5BF6}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{598FE0E5-E02D-465D-9A9D-37974A28FD42}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{6F8BD55B-E83D-4A47-85BE-81FFA8057A69}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{7DE94008-8AFD-4C70-9728-C6FBFFF6A73E}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{8A1D4361-2C08-4700-A351-3EAA9CBFF5E4}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{9465B4B4-5216-4042-9A2C-754D3BCDC410}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{9B2340A0-4068-43D6-B404-32E27217859D}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{9D6AA569-9F30-41AD-885A-346685C74928}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{ABC01078-F197-4B0B-ADBC-CFE684B39C82}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{B3D28DBD-0DFA-40E4-8071-520767BADC7E}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{E225E692-4B47-4777-9BED-4FD7FE257F0E}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{084D78A8-B084-4E14-A629-A2C419B0E3D9}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{0CD01D1E-4A1C-489D-93B9-9B6672877C57}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{128C2DA6-2BC0-44C0-B3F6-4EC22E647964}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{18D0F672-18B4-48E6-AD36-6E6BF01DBBC4}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{19692F10-ADD2-4EFF-BE54-E61C62E40D13}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{1C642CED-CA3B-4013-A9DF-CA6CE5FF6503}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{247954F9-9EDC-4E68-8CC3-150C2B89EADF}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{2D363682-561D-4C3A-81C6-F2F82107562A}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{2E629606-312A-482F-9B12-2C4ABF6F0B6D}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{31AC3F11-E5EA-4A85-8A3D-8E095A39C27B}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{3D05F64F-71E3-48A5-BF6B-83315BC8AE1F}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{494B20CF-282E-4BDD-9F5D-B70CB09D351E}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{49D7563B-2DDB-4831-88C8-768A53833837}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{4DE778FE-F195-4EE3-9DAB-FE446C239221}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{4E223325-C16B-4EEB-AEDC-19AA99A237FA}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{5B25A8DC-1780-4178-A629-6BE8B8DEFAA2}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{6DB17455-4E85-46E7-9D23-E555E4B005AF}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{76F7B787-A67C-4C73-82C7-31F5E3AABC5C}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{8476CE12-AE1F-4198-805C-BA0F9B783F57}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{909489C2-85A6-4322-AA56-D25278649D67}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{B3A47570-0A85-4AEA-8270-529D47899603}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{BCDCB538-01C0-46D1-A6A7-52F4D021C272}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{D106AB5F-A70E-400E-A21B-96208C1D8DBB}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{DAB1D343-1B2A-47F9-B445-93DC50704BFE}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{DCAB8386-4F03-4DBD-A366-D90BC9F68DE6}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{DD42475D-6D46-496A-924E-BD5630B4CBBA}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Wow6432Node\Interface\{FE908CDD-22BB-472A-9870-1A0390E42F36}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Clients\StartMenuInternet\Google Chrome" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Google" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{8A69D345-D564-463c-AFF1-A69D9E530F96}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\ActiveSync\WebAuth\Gmail" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\S-0-0-00-0000000000-0000000000-000000000-000\MSI\{A49A0C51-914A-36A0-B6C2-D34A4BF8710A}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\IdentityCRL\ThrottleCache" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\MediaPlayer\ShimInclusionList\chrome.exe" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GoogleUpdate.exe" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{18635495-7837-4E21-AAE0-78E9D85A7805}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{21C02D29-38ED-478E-9D06-6C2F4C21CF75}" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\GoogleUpdateTaskMachineCore" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\GoogleUpdateTaskMachineUA" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\NonPackaged\C:#Program Files (x86)#Google#Chrome#Application#chrome.exe" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\UFH\ARP" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\Micrsoft\IntuneManagementExtension\Inventories\0000900334a13d6d54fa42b947e821487ea200000904\Name - Google Chrome" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\RegisteredApplications\Google Chrome - Software\Clients\StartMenuInternet\Google Chrome\Capabilties" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\WOW6432Node\Clients\StartMenuInternet\Google Chrome" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Google" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\Software\WOW6432Node\RegsiteredApplications\Google Chrome - Software\Clients\StartMenuInternet\Google" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SYSTEM\ControlSet001\Services\gupdate" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SYSTEM\ControlSet001\Services\gupdatem" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SYSTEM\Setup\FirstBoot\Services\GoogleChromeElevationService" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SYSTEM\Setup\FirstBoot\Services\gupdate" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKLM:\SYSTEM\Setup\FirstBoot\Services\gupdatem" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKU:\S-1-5-19\SOFTWARE\Google" -recurse -force #-erroraction silentlycontinue
Remove-Item -Path "HKU:\S-1-5-20\SOFTWARE\Google" -recurse -force #-erroraction silentlycontinue


Remove-Item -Path "C:\Program Filses\Google\Chrome\" -Force -Recurse
Remove-Item -Path "C:\Program Filses (x86)\Google\Chrome\" -Force -Recurse

Write-Host "Uninstall operations have all completed." -fore green
