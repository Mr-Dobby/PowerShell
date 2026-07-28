#.\Get-DistributionGroupMembers.ps1 `
#   -CSVPath "C:\Reports\Groups.csv"
param(
    [string]$CSVPath = ".\DistributionGroupMembers.csv"
)

If (Test-Path $CSVPath) { Remove-Item $CSVPath}
 
#Get All Office 365 Groups
$O365Groups = Get-UnifiedGroup
ForEach ($Group in $O365Groups) { 
    Write-Host "Group Name:" $Group.DisplayName -ForegroundColor Green
    Get-UnifiedGroupLinks -Identity $Group.Id -LinkType Members | Select-Object DisplayName,PrimarySmtpAddress
 
    #Get Group Members and export to CSV
    Get-UnifiedGroupLinks -Identity $Group.Id -LinkType Members | Select-Object @{Name="Group Name";Expression={$Group.DisplayName}},`
         @{Name="User Name";Expression={$_.DisplayName}}, PrimarySmtpAddress | Export-CSV $CSVPath -NoTypeInformation -Append
}