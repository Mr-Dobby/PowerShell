[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias('UPN','UserPrincipalName')]
    [string]$UserEmail,
    [datetime]$StartDate = (Get-Date).AddMonths(-2),
    [datetime]$EndDate = (Get-Date),
    [string]$ExportPath = "C:\Path\to\export\login_logs.csv"
)

Connect-AzureAD

$loginLogs = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$UserEmail' and CreatedDateTime ge $StartDate and CreatedDateTime le $EndDate" -Top 5000
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
$loginInfo | Export-Csv -Path $ExportPath -NoTypeInformation
