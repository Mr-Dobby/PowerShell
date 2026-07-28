# Create a log of all results everytime this script runs
#.\DriveMapper.ps1 `
#    -DnsDomainName corp.contoso.com `
#    -ConfigFile .\Mappings.json
Start-Transcript -Path "C:\DriveMapping.log"

# Fill in your local active directory domain name
param(
    [string]$DnsDomainName,
    [string]$ConfigFile
)

# Create a loop for all drive maps
$new_driveMappingConfig=@()

# Drive map 1, copy below 5 lines for additional drive letters
$new_driveMappingConfig+= [PSCUSTOMOBJECT]@{
    DriveLetter = "P"
    UNCPath= "\\entire\path\to\folder"
    Description="P-Drive"
}

## To add more, simply copy box above and fill in data.
# Don't change anything below this line

$connected = $false
$retries = 0
$maxRetries = 3

Write-Output "Starting script..."

do {
    if (Resolve-DnsName $dnsDomainName -ErrorAction SilentlyContinue) {
        $connected=$true
    } else {
        $retries++
        Write-Warning "Cannot resolve: $dnsDomainName, assuming no connection to fileserver"
        Start-Sleep -Seconds 3
        if ($retries -eq $maxRetries) {
            Throw "Exceeded maximum numbers of retries ($maxRetries) to resolve dns name ($dnsDomainName)"
        }
    }
} while (-not ($Connected))



#Map drives

#$Mappeddrives = Get-PSDrive | Where-Object {($_.Provider -like "*Filesystem") -and ($_.DisplayRoot -like "\\*")}
$MappedDrives = Get-SmbMapping

foreach ($new_driveMapping in $new_driveMappingConfig) {
    #$new_driveMapping
    $drive_created = $false
    ### CHECK if THERE IS ANY NETWORKDRIVES MAPPED AND if THEY HAVE A LOCALPATH EQ REPLACEMENT
    if ( (-not [string]::IsNullOrEmpty($MappedDrives)) -and ($($MappedDrives.LocalPath).Replace(":","") -contains $New_driveMapping.driveletter)  ) {
        Write-Host "Drive exits: $($New_driveMapping.driveletter)" -ForegroundColor Yellow

        ## FIND THE ALREADY ADD LOCALPATH THAT MATCH THE NEW OBJECT'S PATH
        $old_root = $MappedDrives | Where-Object {$($_.LocalPath).Replace(":","") -EQ $new_driveMapping.DriveLetter}


        ## CHECK if THE OLD MAPPED DRIVE HAS THE SAME DRIVELETTER, BUT OTHER REMOTEPATH
        ## THEN IT REMOVE THE OLD MAPPED DRIVE AND REPLACE IT
        ## else NOTHING
        if (($new_driveMapping.UNCPath -ne $old_root.RemotePath) -and ($new_driveMapping.DriveLetter -eq ($old_root.LocalPath).Replace(":",""))) {
            write-host $removed -ForegroundColor Red
            try {
                write-host "Removing SMBMapping $($old_root.LocalPath)" -ForegroundColor red
                Invoke-Command -scriptblock { net use $($old_root.LocalPath) /delete }  | Out-Null
                $removed = $true
            } CATCH {
                Write-Warning "Cannot remove $($old_root.LocalPath)"
            }

            if ($removed) {
                write-host "new drives $($new_driveMapping.driveletter)" -ForegroundColor Green
                try {
                    Invoke-Command -ScriptBlock { net use "$($new_driveMapping.DriveLetter):" $new_driveMapping.UNCPath /persistent:yes } | out-null
                    $drive_created = $true
                } CATCH {
                    Write-Warning "Cannot set new-drive: $($new_driveMapping.driveletter) - $($new_driveMapping.UNcpath)"
                }
            }
        } else {
            Write-host "Drive already exists" -ForegroundColor Green
            $drive_created = $true
        }

    } else {
        ### ADD NEW DRIVE AS NO ON EXISTS
        try {
            write-host "new drives $($new_driveMapping.driveletter)" -ForegroundColor Green
            Invoke-Command -ScriptBlock { net use "$($new_driveMapping.DriveLetter):" $new_driveMapping.UNCPath /persistent:yes } | out-null
            $drive_created = $true
        } CATCH {
            Write-Warning "Cannot set new-drive: $($new_driveMapping.driveletter) - $($new_driveMapping.UNcpath)"
        }
    }

    ### CHANGE DESCRIPTION ON FOLDER
    if ($drive_created -eq $true) {
        Get-childItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2" |
        Where-Object  {$_.name.Split("\")[-1] -like $($new_driveMapping.UNCPath.Replace("\","#"))} |
        ForEach-Object {
            set-ItemProperty $($_.Name.replace("HKEY_CURRENT_USER","HKCU:")) -Name "_labelFromReg" -Value $($new_driveMapping.Description)
        }
    }

}

#Get-SmbMapping
Stop-Transcript