Connect-SPOService -Url "" #Sharepoint admin login
Connect-AzureAD
 
# Get dynamic group members
$groupId = "" #Object ID from Azure
$group = Get-AzureADGroup -ObjectId $groupId
$members = Get-AzureADGroupMember -ObjectId $group.ObjectId
 
# Get SharePoint sites
$sites = Get-SPOSite -Limit All
 
# Check access for each site
$accessSites = @()
foreach ($site in $sites) {
    $siteUrl = $site.Url
    $siteGroups = Get-SPOSiteGroup -Site $siteUrl
    foreach ($siteGroup in $siteGroups) {
        if ($siteGroup.LoginName -eq $group.Mail) {
            $accessSites += $siteUrl
            break
        }
    }
}
 
# Display access sites
Write-Host "Group $($group.DisplayName) has access to the following SharePoint sites:"
foreach ($accessSite in $accessSites) {
    Write-Host $accessSite
} 
