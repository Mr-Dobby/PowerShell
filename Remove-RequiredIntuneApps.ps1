# Sample to delete a single app
#
# Update January 1, 2026: Made more changes in the GRS logic. 
# Credit to David Bolding: https://therandomadmin.com/2025/01/01/force-intune-apps-to-redeploy/
$Path = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
$AppID = "766ff284-6a2d-4a4a-b734-402c9f339bbb"
 
# Purposely not skipping the 00000000-0000-0000-0000-000000000000 entry
# This is used when an app is device-assigned, or runs in system context
$Users = (Get-ChildItem -Path "$Path").name | Where-Object {($_ -like "*-*-*-*-*")}
 
foreach ($user in $Users) {
    $Name = $User -replace "HKEY_LOCAL_MACHINE","HKLM:"
    $UserID = $user.split("\")[-1]
    $Applications = Get-ChildItem -Path $Name | Where-Object {$_.name -like "*$($AppID)*"}
    foreach ($App in $Applications) {
        $AppName = $App -replace "HKEY_LOCAL_MACHINE","HKLM:"
        Write-Host "App found"
        remove-item -Path $AppName -Recurse -Verbose -force
    }
    $GRSPath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\$UserID\GRS"
    $GRSes = Get-childitem -path $GRSPath
    foreach ($GRS in $GRSes) {
        $GRSProps = $GRS | Get-ItemProperty
        $Count = $GRSProps.psobject.Properties.count 
        if ($Count.count -gt 5) {
            $TotalKey = $GRSProps.psobject.Properties.name | where-object {$_ -like "*-*-*-*-*"}
            if ($TotalKey -like "*$($AppID)*") {
                Write-Host "GRS Entry found, path to remove $PathToRemove"
                $PathToRemove = $GRS.name -replace "HKEY_LOCAL_MACHINE","HKLM:"
                Remove-Item -Path $PathToRemove -Recurse -Force -Verbose
            }
        }
    }
}
Get-Service -DisplayName "Microsoft Intune Management Extension" | Restart-Service -Verbose
