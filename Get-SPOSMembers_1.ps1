[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteURL,
    [string]$GroupObjectId
)

Connect-SPOService
Connect-AzureAD

$GroupsData = @()
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

if (-not [string]::IsNullOrWhiteSpace($GroupObjectId)) {
    Get-AzureADGroupMember -ObjectId $GroupObjectId
}