Connect-AzureAD
$userEmail = ""
$startDate = (Get-Date).AddMonths(-2)
$endDate = Get-Date

$loginLogs = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$userEmail' and CreatedDateTime ge $startDate and CreatedDateTime le $endDate" -Top 5000
$loginInfo = foreach ($log in $loginLogs) {
    $properties = @{
        "CreationDate" = $log.CreatedDateTime
        "ClientIP" = $log.IPAddress
        "UserType" = $log.UserType
        "ResultStatus" = $log.Status
        "ClientInfo" = $log.ClientAppUsed
    }
    New-Object -TypeName PSObject -Property $properties
}

$loginInfo | Format-Table -AutoSize
$loginInfo | Export-Csv -Path "C:\Path\to\export\login_logs.csv" -NoTypeInformation
