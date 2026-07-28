# Sample to delete a single app
#
# Update July 11, 2024: Made same changes in the GRS logic due to changes in the IME log.
# GetAppGRSHash function based on samples from Andrew (@AndrewZtrhgf) and Rudy Ooms @Mister_MDM 
# https://gist.github.com/ztrhgf/18f1c32220764f79af3da52d9f47d266
# https://call4cloud.nl/2022/07/retry-lola-retry/
#
# Note: Don't got forget to delete any files/installs that the detection method uses on your machine
# Deleting specific application based on its object id
$Path = "HKLM:SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
$UserObjectID = "efd4c448-e6f1-46fa-b083-d87e60ea1274"
$AppID = "8ea44431-bb08-460c-b881-52bdff6a7128"

function GetAppGRSHash {
    param (
        [Parameter(Mandatory = $true)]
        [string] $appId
    )

    $intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | sort LastWriteTime -Descending | select -ExpandProperty FullName

    if (!$intuneLogList) {
        Write-Error "Unable to find any Intune log files. Redeploy will probably not work as expected."
        return
    }

    foreach ($intuneLog in $intuneLogList) {
        $appMatch = Select-String -Path $intuneLog -Pattern "\[Win32App\]\[GRSManager\] App with id: $appId is not expired." -Context 0, 1
        if ($appMatch) {
            foreach ($match in $appMatch) {
                $Hash = ""
                $LineNumber = 0
                $LineNumber = $match.LineNumber
                $Hash = ((Get-Content $intuneLog | Select-Object -Skip $LineNumber -First 1) -split " = ")[1]
                if ($hash) {
                    $hash = $hash.Replace('+','\+')
                    return $hash
                }
            }
        }
    }

    Write-Error "Unable to find App '$appId' GRS hash in any of the Intune log files. Redeploy will probably not work as expected"
}

$GRSHash = GetAppGRSHash -appId $AppID

(Get-ChildItem -Path $Path\$UserObjectID) -match $AppID | Remove-Item -Recurse -Force
(Get-ChildItem -Path $Path\$UserObjectID\GRS) -match $GRSHash | Remove-Item -Recurse -Force

Get-Service -DisplayName "Microsoft Intune Management Extension" | Restart-Service