# Options:
# .\script.ps1 -Mode Validate
# .\script.ps1 -Mode Both -WhatIfMode
# .\script.ps1 -Mode Update -WhatIfMode:$false
# .\script.ps1 -Mode Rollback -WhatIfMode
# .\script.ps1 -Mode Rollback -WhatIfMode:$false
# you may need to adjust fields

param(
    [ValidateSet("Validate", "Update", "Both", "Rollback")]
    [string]$Mode = "Validate",

    [switch]$WhatIfMode = $true
)

Test-ADModule

$CsvPath        = "C:\AD_Users.csv"
$ReportPath     = "C:\AD_Users_Validation.csv"
$HtmlReportPath = "C:\AD_Users_Report.html"
$ChangeLogPath  = "C:\AD_Users_ChangeLog.csv"

function Test-ADModule {

    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw "ActiveDirectory module is not installed on this system. Install RSAT: Active Directory tools."
    }

    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "ActiveDirectory module loaded successfully." -ForegroundColor Green
    }
    catch {
        throw "Failed to import ActiveDirectory module: $($_.Exception.Message)"
    }
}

function Normalize($v) {
    if ($null -eq $v) { return "" }
    return $v.ToString().Trim()
}

function Compare-Fields($field, $csv, $ad) {

    $csvN = Normalize $csv
    $adN  = Normalize $ad

    if ($csvN -eq "" -and $adN -eq "") { return $null }

    [PSCustomObject]@{
        Field  = $field
        CSV    = $csvN
        AD     = $adN
        Match  = ($csvN -eq $adN)
    }
}

$doValidate = $Mode -in "Validate","Both"
$doUpdate   = $Mode -in "Update","Both"

$results   = @()
$changeLog = @()

if ($Mode -eq "Rollback") {

    $log = Import-Csv $ChangeLogPath

    foreach ($entry in $log) {

        $user = Get-ADUser -Filter "UserPrincipalName -eq '$($entry.UserPrincipalName)'" -ErrorAction SilentlyContinue
        if (-not $user) { continue }

        $update = @{ $entry.Field = $entry.OldValue }

        if ($WhatIfMode) {
            Write-Host "[WHATIF ROLLBACK] $($entry.UserPrincipalName) $($entry.Field)" -ForegroundColor Cyan
        }
        else {
            Set-ADUser -Identity $user @update
            Write-Host "Rolled back $($entry.UserPrincipalName) $($entry.Field)" -ForegroundColor Green
        }
    }

    return
}

foreach ($u in Import-Csv $CsvPath -Delimiter ";") {

    $ad = Get-ADUser -Filter "UserPrincipalName -eq '$($u.UserPrincipalName)'" -Properties Description,DisplayName,EmailAddress,GivenName,Initials,MobilePhone,Office,Surname,Title

    if (-not $ad) {
        $results += [PSCustomObject]@{
            UserPrincipalName = $u.UserPrincipalName
            Status = "Not Found"
            Details = ""
        }
        continue
    }

    $fields = "Description","DisplayName","EmailAddress","GivenName","Initials","MobilePhone","Office","Surname","Title"

    $diffs = @()
    $updates = @{}

    foreach ($f in $fields) {

        $cmp = Compare-Fields $f $u.$f $ad.$f
        if (-not $cmp) { continue }

        $diffs += $cmp

        if (-not $cmp.Match) {
            $updates[$f] = Normalize $u.$f

            $changeLog += [PSCustomObject]@{
                UserPrincipalName = $u.UserPrincipalName
                Field = $f
                OldValue = $cmp.AD
                NewValue = $cmp.CSV
                Time = Get-Date
            }
        }
    }

    if ($doUpdate -and $updates.Count -gt 0) {

        if ($WhatIfMode) {
            Write-Host "[WHATIF] $($u.UserPrincipalName) would be updated" -ForegroundColor Cyan
        }
        else {
            Set-ADUser -Identity $ad @updates
            Write-Host "Updated $($u.UserPrincipalName)" -ForegroundColor Green
        }
    }

    $results += [PSCustomObject]@{
        UserPrincipalName = $u.UserPrincipalName
        MismatchCount = ($diffs | Where-Object { -not $_.Match }).Count
        Details = $diffs
    }
}

if ($doValidate) {
    $results | Export-Csv $ReportPath -NoTypeInformation -Encoding UTF8
}

if ($changeLog.Count -gt 0) {
    $changeLog | Export-Csv $ChangeLogPath -NoTypeInformation -Encoding UTF8
}

if ($doValidate) {

$html = @"
<html>
<head>
<style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 6px; }
th { background: #222; color: white; }
.ok { background: #70ff70; }
.bad { background: #ff7777; }
</style>
</head>
<body>
<h2>AD Validation Report</h2>
<p>Generated: $(Get-Date)</p>
<table>
<tr>
<th>User</th><th>Field</th><th>CSV</th><th>AD</th><th>Status</th>
</tr>
"@

foreach ($r in $results) {
    foreach ($d in $r.Details) {

        $class = if ($d.Match) { "ok" } else { "bad" }
        $status = if ($d.Match) { "Match" } else { "Mismatch" }

        $html += "<tr class='$class'>
<td>$($r.UserPrincipalName)</td>
<td>$($d.Field)</td>
<td>$($d.CSV)</td>
<td>$($d.AD)</td>
<td>$status</td>
</tr>"
    }
}

$html += "</table></body></html>"

$html | Out-File $HtmlReportPath -Encoding UTF8

Write-Host "HTML report created: $HtmlReportPath" -ForegroundColor Green
}