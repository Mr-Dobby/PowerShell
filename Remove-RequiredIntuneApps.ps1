#usage
# .\Remove-RequiredIntuneApps.ps1 -AppID "766ff284-6a2d-4a4a-b734-402c9f339bbb"

param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$AppID
)

$Path = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"

# Purposely not skipping the 00000000-0000-0000-0000-000000000000 entry
# This is used when an app is device-assigned, or runs in system context
$Users = (Get-ChildItem -Path $Path).Name | Where-Object { $_ -like "*-*-*-*-*" }

foreach ($User in $Users) {
    $Name = $User -replace "HKEY_LOCAL_MACHINE","HKLM:"
    $UserID = $User.Split("\")[-1]

    $Applications = Get-ChildItem -Path $Name | Where-Object { $_.Name -like "*$AppID*" }

    foreach ($App in $Applications) {
        $AppName = $App.Name -replace "HKEY_LOCAL_MACHINE","HKLM:"
        Write-Host "App found: $AppName"
        Remove-Item -Path $AppName -Recurse -Force -Verbose
    }

    $GRSPath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\$UserID\GRS"

    if (Test-Path $GRSPath) {
        $GRSes = Get-ChildItem -Path $GRSPath

        foreach ($GRS in $GRSes) {
            $GRSProps = $GRS | Get-ItemProperty
            $Count = $GRSProps.PSObject.Properties.Count

            if ($Count -gt 5) {
                $TotalKey = $GRSProps.PSObject.Properties.Name | Where-Object { $_ -like "*-*-*-*-*" }

                if ($TotalKey -like "*$AppID*") {
                    $PathToRemove = $GRS.Name -replace "HKEY_LOCAL_MACHINE","HKLM:"
                    Write-Host "GRS entry found: $PathToRemove"
                    Remove-Item -Path $PathToRemove -Recurse -Force -Verbose
                }
            }
        }
    }
}

Get-Service -DisplayName "Microsoft Intune Management Extension" | Restart-Service -Verbose