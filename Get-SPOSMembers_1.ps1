Connect-SPOService
Connect-AzureAD

$GroupsData = @()
$SiteURL = " SPO SITE"
$SiteGroups = Get-SPOSiteGroup -Site $SiteURL

foreach($Group in $SiteGroups) {
    Write-host "Group:"$Group.Title
    
    Get-SPOSiteGroup -Site $SiteURL -Group $Group.Title | Select-Object -ExpandProperty Users
    
    $GroupsData += New-Object PSObject -Property @{
        'Site URL' = $SiteURL
        'Group Name' = $Group.Title
        'Users' = $Group.Users -join ","
    }
}

Get-AzureADGroupMember -ObjectId ""