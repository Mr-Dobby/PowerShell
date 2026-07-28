

$idRef = [System.Security.Principal.SecurityIdentifier]("AC")   
$access = [System.Security.AccessControl.RegistryRights]"ReadKey"
$inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$propagation = [System.Security.AccessControl.PropagationFlags]"None"
$type = [System.Security.AccessControl.AccessControlType]"Allow"
$rule = New-Object System.Security.AccessControl.RegistryAccessRule($idRef,$access,$inheritance,$propagation,$type)

$folder = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$acl = Get-Acl $folder
try {
    $acl.AddAccessRule($rule)
    $acl |Set-Acl
} catch { }

$folder = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
$acl = Get-Acl $folder
try {
    $acl.AddAccessRule($rule)
    $acl |Set-Acl
} catch { }

taskkill /F /IM explorer.exe

Get-AppXPackage *Microsoft.Windows.Search* |
ForEach-Object {
Add-AppxPackage -DisableDevelopmentMode -ForceApplicationShutdown -Register "$($_.InstallLocation)\AppXManifest.xml"
}
Get-AppXPackage *MicrosoftWindows.Client.CBS* |
ForEach-Object {
Add-AppxPackage -DisableDevelopmentMode -ForceApplicationShutdown -Register "$($_.InstallLocation)\AppXManifest.xml"
}
Get-AppXPackage *Microsoft.Windows.ShellExperienceHost* |
ForEach-Object {
Add-AppxPackage -DisableDevelopmentMode -ForceApplicationShutdown -Register "$($_.InstallLocation)\AppXManifest.xml"
}
Get-AppXPackage *Microsoft.AAD.BrokerPlugin* |
ForEach-Object {
Add-AppxPackage -DisableDevelopmentMode -ForceApplicationShutdown -Register "$($_.InstallLocation)\AppXManifest.xml"
}
Get-AppXPackage *Microsoft.AccountsControl* |
ForEach-Object {
Add-AppxPackage -DisableDevelopmentMode -ForceApplicationShutdown -Register "$($_.InstallLocation)\AppXManifest.xml"
}

Get-AppXPackage *Microsoft.Windows.CloudExperienceHost* |
ForEach-Object {
Add-AppxPackage -DisableDevelopmentMode -ForceApplicationShutdown -Register "$($_.InstallLocation)\AppXManifest.xml"
}

if (-not (Get-AppxPackage Microsoft.AAD.BrokerPlugin)) { Add-AppxPackage -Register "$env:windir\SystemApps\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\Appxmanifest.xml" -DisableDevelopmentMode -ForceApplicationShutdown } Get-AppxPackage Microsoft.AAD.BrokerPlugin

start explorer.exe


