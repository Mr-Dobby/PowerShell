function Get-DirectReports {
    param(
        [string]$ManagerUPN
    )

    $Reports = Get-MgUserDirectReport -UserId $ManagerUPN -All

    $Results = foreach ($Report in $Reports) {
        $User = Get-MgUser -UserId $Report.Id

        [PSCustomObject]@{
            Manager    = $ManagerUPN
            Name       = $User.DisplayName
            UPN        = $User.UserPrincipalName
            Department = $User.Department
            JobTitle   = $User.JobTitle
        }
    }

    $ExportPath = Read-Host "Enter export path (or press Enter for .\DirectReports.csv)"

    if ([string]::IsNullOrWhiteSpace($ExportPath)) {
        $ExportPath = ".\DirectReports.csv"
    }

    $Results | Export-Csv $ExportPath -NoTypeInformation

    Write-Host "`nFound $($Results.Count) direct reports." -ForegroundColor Green
    Write-Host "Exported to $ExportPath" -ForegroundColor Green
}

function Get-FullHierarchy {

    $Users = Get-MgUser -All

    $Results = foreach ($User in $Users) {

        try {
            $Manager = Get-MgUserManager -UserId $User.Id -ErrorAction Stop

            [PSCustomObject]@{
                UserName    = $User.DisplayName
                UserUPN     = $User.UserPrincipalName
                ManagerName = $Manager.AdditionalProperties.displayName
                ManagerId   = $Manager.Id
            }
        }
        catch {
            [PSCustomObject]@{
                UserName    = $User.DisplayName
                UserUPN     = $User.UserPrincipalName
                ManagerName = "No Manager"
                ManagerId   = ""
            }
        }
    }

    $ExportPath = Read-Host "Enter export path (or press Enter for .\OrgHierarchy.csv)"

    if ([string]::IsNullOrWhiteSpace($ExportPath)) {
        $ExportPath = ".\OrgHierarchy.csv"
    }

    $Results | Export-Csv $ExportPath -NoTypeInformation

    Write-Host "`nProcessed $($Results.Count) users." -ForegroundColor Green
    Write-Host "Exported to $ExportPath" -ForegroundColor Green
}

# Connect once
Connect-MgGraph -Scopes User.Read.All

do {
    Clear-Host

    Write-Host "======================================="
    Write-Host "  Entra ID Reporting Structure Tool"
    Write-Host "======================================="
    Write-Host ""
    Write-Host "1. Export Full Organization Hierarchy"
    Write-Host "2. Get Direct Reports for Manager"
    Write-Host "3. Exit"
    Write-Host ""

    $Choice = Read-Host "Select an option"

    switch ($Choice) {

        "1" {
            Get-FullHierarchy
            Pause
        }

        "2" {
            $ManagerUPN = Read-Host "Enter Manager UPN"

            if ($ManagerUPN) {
                Get-DirectReports -ManagerUPN $ManagerUPN
            }

            Pause
        }

        "3" {
            break
        }

        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }

} while ($Choice -ne "3")

Disconnect-MgGraph