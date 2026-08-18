<#
.SYNOPSIS
  Audits Microsoft Entra authentication method registration and optionally
  enables the Microsoft Authenticator registration campaign.

.DESCRIPTION
  Performs the following:

  1. Retrieves authentication-method registration details for users.
  2. Identifies SSPR-enabled users who are not SSPR registered.
  3. Separately identifies administrators who require attention.
  4. Displays the authentication methods currently registered.
  5. Retrieves the Authentication Methods Policy.
  6. Optionally enables the Microsoft Authenticator registration campaign.
  7. Re-reads the policy after any modification.
  8. Generates a self-contained HTML audit dashboard.
  9. Exports the Authentication Methods Policy to JSON.

.NOTES
  Requires:
   - PowerShell 7.0+
   - Microsoft.Graph.Authentication
   - Microsoft.Graph.Reports
   - Microsoft.Graph.Identity.SignIns
   - Appropriate Microsoft Graph permissions
   - Authentication Policy Administrator (or equivalent) to modify
    the Authentication Methods Policy

  Microsoft SSPR timeline:
   - Registration campaign: July 6, 2026
   - Enforcement: September 7, 2026

  IMPORTANT:
   Review the audit results and Authentication Methods Policy before
   enabling the registration campaign in production.

  Use -WhatIf to test the script without changing the policy.

.EXAMPLE
  .\Entra-SSPR-Audit.ps1

  Runs the audit and enables the registration campaign.

.EXAMPLE
  .\Entra-SSPR-Audit.ps1 -EnableRegistrationCampaign:$false

  Runs the audit only. No policy changes are made.

.EXAMPLE
  .\Entra-SSPR-Audit.ps1 -WhatIf

  Runs the script while showing what policy change would be made.

#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OutputPath = ".\Entra-SSPR-Audit",

    [bool]$EnableRegistrationCampaign = $true,

    [ValidateSet("microsoftAuthenticator", "fido2")]
    [string]$CampaignAuthenticationMethod = "microsoftAuthenticator",

    [ValidateRange(0, 14)]
    [int]$SnoozeDurationInDays = 1
)

$ErrorActionPreference = "Stop"

function ConvertTo-HtmlSafe {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function ConvertTo-EntraAuditHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Audit,

        [Parameter(Mandatory)]
        [array]$UsersRequiringAttention,

        [Parameter(Mandatory)]
        $AuthenticationMethodsPolicy,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [string]$CampaignAuthenticationMethod,

        [Parameter(Mandatory)]
        [int]$SnoozeDurationInDays,

        [Parameter(Mandatory)]
        [bool]$CampaignChangeRequested
    )

    $TotalUsers = $Audit.Count

    $AdminCount = @(
        $Audit | Where-Object {
            $_.IsAdministrator -eq $true
        }
    ).Count

    $SSPREnabledCount = @(
        $Audit | Where-Object {
            $_.IsSSPREnabled -eq $true
        }
    ).Count

    $SSPRRegisteredCount = @(
        $Audit | Where-Object {
            $_.IsSSPRRegistered -eq $true
        }
    ).Count

    $MFACapableCount = @(
        $Audit | Where-Object {
            $_.IsMFACapable -eq $true
        }
    ).Count

    $MFARegisteredCount = @(
        $Audit | Where-Object {
            $_.IsMFARegistered -eq $true
        }
    ).Count

    $PasswordlessCapableCount = @(
        $Audit | Where-Object {
            $_.IsPasswordlessCapable -eq $true
        }
    ).Count

    $AttentionCount = @($UsersRequiringAttention).Count

    $AdminAttentionCount = @(
        $UsersRequiringAttention | Where-Object {
            $_.IsAdministrator -eq $true
        }
    ).Count

    $Campaign = $null

    if ($null -ne $AuthenticationMethodsPolicy.RegistrationEnforcement) {
        $Campaign = $AuthenticationMethodsPolicy.RegistrationEnforcement.AuthenticationMethodsRegistrationCampaign
    }

    if ($null -ne $Campaign) {
        $CampaignState = [string]$Campaign.State
        $ActualSnoozeDuration = $Campaign.SnoozeDurationInDays
        $EnforceAfterSnoozes = $Campaign.EnforceRegistrationAfterAllowedSnoozes
        $IncludeTargets = @($Campaign.IncludeTargets)
        $ExcludeTargets = @($Campaign.ExcludeTargets)
    }
    else {
        $CampaignState = "Not configured"
        $ActualSnoozeDuration = "N/A"
        $EnforceAfterSnoozes = "N/A"
        $IncludeTargets = @()
        $ExcludeTargets = @()
    }

    $ActualTargetedMethod = $null

    if ($IncludeTargets.Count -gt 0) {
        $ActualTargetedMethod = $IncludeTargets |
            Select-Object -First 1 |
            ForEach-Object {
                $_.TargetedAuthenticationMethod
            }
    }

    if ([string]::IsNullOrWhiteSpace($ActualTargetedMethod)) {
        $ActualTargetedMethod = $CampaignAuthenticationMethod
    }

    $TargetDescriptions = @(
        foreach ($Target in $IncludeTargets) {
            $TargetId = ConvertTo-HtmlSafe $Target.Id
            $TargetType = ConvertTo-HtmlSafe $Target.TargetType

            if ($Target.Id -eq "all_users") {
                "All users"
            }
            else {
                "$TargetType : $TargetId"
            }
        }
    )

    if ($TargetDescriptions.Count -eq 0) {
        $TargetDescriptions = @("None configured")
    }

    $ExcludedDescriptions = @(
        foreach ($Target in $ExcludeTargets) {
            $TargetId = ConvertTo-HtmlSafe $Target.Id
            $TargetType = ConvertTo-HtmlSafe $Target.TargetType

            if ($Target.Id -eq "all_users") {
                "All users"
            }
            else {
                "$TargetType : $TargetId"
            }
        }
    )

    if ($ExcludedDescriptions.Count -eq 0) {
        $ExcludedDescriptions = @("None")
    }

    $UserRows = foreach ($User in (
        $Audit |
            Sort-Object `
                @{Expression = "IsAdministrator"; Descending = $true},
                UserPrincipalName
    )) {
        $DisplayName = ConvertTo-HtmlSafe $User.DisplayName
        $UPN = ConvertTo-HtmlSafe $User.UserPrincipalName
        $Methods = ConvertTo-HtmlSafe $User.RegisteredAuthenticationMethods

        if ($User.IsAdministrator -eq $true) {
            $AdminBadge = '<span class="badge badge-admin">ADMIN</span>'
        }
        else {
            $AdminBadge = ""
        }

        if ($User.IsSSPRRegistered -eq $true) {
            $StatusClass = "status-good"
            $StatusText = "Registered"
        }
        elseif ($User.IsSSPREnabled -eq $true) {
            $StatusClass = "status-warning"
            $StatusText = "Needs attention"
        }
        else {
            $StatusClass = "status-neutral"
            $StatusText = "Not required"
        }

        if ($User.IsMFARegistered -eq $true) {
            $MfaHtml = '<span class="yes">Yes</span>'
        }
        else {
            $MfaHtml = '<span class="no">No</span>'
        }

        if ($User.IsPasswordlessCapable -eq $true) {
            $PasswordlessHtml = '<span class="yes">Yes</span>'
        }
        else {
            $PasswordlessHtml = '<span class="no">No</span>'
        }

@"
<tr>
    <td>
        <strong>$DisplayName</strong>
        <br>
        <span class="upn">$UPN</span>
    </td>
    <td>$AdminBadge</td>
    <td>
        <span class="status $StatusClass">$StatusText</span>
    </td>
    <td>$MfaHtml</td>
    <td>$PasswordlessHtml</td>
    <td>$Methods</td>
    <td>$($User.RegisteredAuthenticationMethodCount)</td>
</tr>
"@
    }

    $UserRows = $UserRows -join "`n"

    $AttentionRows = foreach ($User in (
        $UsersRequiringAttention |
            Sort-Object `
                @{Expression = "IsAdministrator"; Descending = $true},
                UserPrincipalName
    )) {
        $DisplayName = ConvertTo-HtmlSafe $User.DisplayName
        $UPN = ConvertTo-HtmlSafe $User.UserPrincipalName
        $Methods = ConvertTo-HtmlSafe $User.RegisteredAuthenticationMethods

        if ($User.IsAdministrator -eq $true) {
            $Priority = '<span class="priority critical">ADMINISTRATOR</span>'
            $RowClass = "attention-critical"
            $UserTypeDisplay = "Administrator"
        }
        else {
            $Priority = '<span class="priority warning">ACTION REQUIRED</span>'
            $RowClass = "attention-warning"
            $UserTypeDisplay = "Standard user"
        }

@"
<tr class="$RowClass">
    <td>
        <strong>$DisplayName</strong>
        <br>
        <span class="upn">$UPN</span>
    </td>
    <td>$Priority</td>
    <td>$Methods</td>
    <td>$UserTypeDisplay</td>
</tr>
"@
    }

    $AttentionRows = $AttentionRows -join "`n"

    if ($AttentionCount -eq 0) {
        $AttentionRows = @"
<tr>
    <td colspan="4" class="empty-state">
        <div class="success-icon">✓</div>
        <strong>No users require attention</strong>
        <br>
        All SSPR-enabled users are currently SSPR registered.
    </td>
</tr>
"@
    }

    $PolicyRows = foreach ($Method in @($AuthenticationMethodsPolicy.AuthenticationMethodConfigurations)) {
        $MethodId = ConvertTo-HtmlSafe $Method.Id
        $MethodState = ConvertTo-HtmlSafe $Method.State

        if ($Method.State -eq "enabled") {
            $StateClass = "status-good"
        }
        elseif ($Method.State -eq "disabled") {
            $StateClass = "status-neutral"
        }
        else {
            $StateClass = "status-warning"
        }

@"
<tr>
    <td><strong>$MethodId</strong></td>
    <td>
        <span class="status $StateClass">$MethodState</span>
    </td>
</tr>
"@
    }

    $PolicyRows = $PolicyRows -join "`n"

    if ($CampaignState -eq "enabled") {
        $CampaignStatusClass = "status-good"
    }
    elseif ($CampaignState -eq "disabled") {
        $CampaignStatusClass = "status-neutral"
    }
    else {
        $CampaignStatusClass = "status-warning"
    }

    if ($CampaignChangeRequested) {
        $ChangeDescription = "Campaign modification was successfully submitted by this script."
    }
    else {
        $ChangeDescription = "No campaign modification was made by this script."
    }

    $Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $GeneratedUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")

    $EnforceHtml = if ($EnforceAfterSnoozes -is [bool]) {
        if ($EnforceAfterSnoozes) {
            '<span class="yes">Yes</span>'
        }
        else {
            '<span class="no">No</span>'
        }
    }
    else {
        ConvertTo-HtmlSafe $EnforceAfterSnoozes
    }

    $IncludedHtml = (
        $TargetDescriptions |
            ForEach-Object {
                ConvertTo-HtmlSafe $_
            }
    ) -join " &nbsp; • &nbsp; "

    $ExcludedHtml = (
        $ExcludedDescriptions |
            ForEach-Object {
                ConvertTo-HtmlSafe $_
            }
    ) -join " &nbsp; • &nbsp; "

    $Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Microsoft Entra SSPR Audit</title>
<style>
:root {
    --blue:#0078d4;
    --blue-dark:#005a9e;
    --background:#f4f7fb;
    --card:#fff;
    --text:#1f2937;
    --muted:#64748b;
    --border:#e2e8f0;
    --green:#16a34a;
    --green-bg:#dcfce7;
    --orange:#d97706;
    --orange-bg:#fef3c7;
    --red:#dc2626;
    --red-bg:#fee2e2;
    --shadow:0 4px 18px rgba(15,23,42,.06);
}
* { box-sizing:border-box; }
html { scroll-behavior:smooth; }
body {
    margin:0;
    background:var(--background);
    color:var(--text);
    font-family:"Segoe UI",Arial,Helvetica,sans-serif;
    line-height:1.5;
}
.header {
    background:linear-gradient(135deg,var(--blue-dark),var(--blue));
    color:white;
    padding:45px 50px;
    box-shadow:0 4px 20px rgba(0,0,0,.15);
}
.header-content {
    max-width:1500px;
    margin:0 auto;
}
.header h1 {
    margin:0 0 8px;
    font-size:32px;
    font-weight:600;
}
.header p {
    margin:6px 0;
    color:#dbeafe;
}
.header .generated {
    margin-top:18px;
    font-size:13px;
    color:#bfdbfe;
}
.container {
    max-width:1500px;
    margin:35px auto;
    padding:0 25px;
}
.cards {
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(200px,1fr));
    gap:18px;
    margin-bottom:30px;
}
.card {
    background:var(--card);
    border:1px solid var(--border);
    border-radius:14px;
    padding:22px;
    box-shadow:var(--shadow);
    position:relative;
    overflow:hidden;
}
.card::before {
    content:"";
    position:absolute;
    left:0;
    top:0;
    bottom:0;
    width:4px;
    background:var(--blue);
}
.card-green::before { background:var(--green); }
.card-orange::before { background:var(--orange); }
.card-red::before { background:var(--red); }
.card-title {
    color:var(--muted);
    font-size:12px;
    font-weight:700;
    text-transform:uppercase;
    letter-spacing:.06em;
}
.card-value {
    font-size:34px;
    font-weight:700;
    margin-top:7px;
    line-height:1.1;
}
.card-blue .card-value { color:var(--blue); }
.card-green .card-value { color:var(--green); }
.card-orange .card-value { color:var(--orange); }
.card-red .card-value { color:var(--red); }
.section {
    background:white;
    border:1px solid var(--border);
    border-radius:14px;
    margin-bottom:25px;
    overflow:hidden;
    box-shadow:var(--shadow);
}
.section-header {
    padding:20px 25px;
    border-bottom:1px solid var(--border);
    background:#f8fafc;
}
.section-header h2 {
    margin:0;
    font-size:20px;
    font-weight:650;
}
.section-header p {
    margin:5px 0 0;
    color:var(--muted);
    font-size:14px;
}
.section-body { padding:25px; }
.campaign {
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(190px,1fr));
    gap:15px;
}
.campaign-item {
    padding:18px;
    border-radius:10px;
    background:#f8fafc;
    border:1px solid var(--border);
}
.campaign-label {
    color:var(--muted);
    font-size:12px;
    font-weight:600;
}
.campaign-value {
    margin-top:6px;
    font-weight:650;
    font-size:16px;
}
.campaign-note {
    margin-top:20px;
    padding:14px 16px;
    background:#eff6ff;
    border:1px solid #bfdbfe;
    border-radius:8px;
    color:#1e40af;
    font-size:13px;
}
.status {
    display:inline-block;
    padding:5px 10px;
    border-radius:999px;
    font-size:12px;
    font-weight:650;
    white-space:nowrap;
}
.status-good {
    color:#166534;
    background:var(--green-bg);
}
.status-warning {
    color:#92400e;
    background:var(--orange-bg);
}
.status-neutral {
    color:#475569;
    background:#e2e8f0;
}
.badge {
    display:inline-block;
    padding:4px 8px;
    border-radius:6px;
    font-size:10px;
    font-weight:750;
    letter-spacing:.04em;
}
.badge-admin {
    color:#991b1b;
    background:var(--red-bg);
}
.priority {
    display:inline-block;
    padding:5px 9px;
    border-radius:6px;
    font-size:10px;
    font-weight:750;
    letter-spacing:.03em;
}
.priority.critical {
    color:#991b1b;
    background:var(--red-bg);
}
.priority.warning {
    color:#92400e;
    background:var(--orange-bg);
}
.table-wrapper { overflow-x:auto; }
table {
    width:100%;
    border-collapse:collapse;
}
th {
    text-align:left;
    background:#f8fafc;
    color:#475569;
    font-size:11px;
    text-transform:uppercase;
    letter-spacing:.05em;
    padding:13px 15px;
    border-bottom:2px solid var(--border);
    white-space:nowrap;
}
td {
    padding:14px 15px;
    border-bottom:1px solid var(--border);
    vertical-align:middle;
}
tbody tr:hover td { background:#f8fafc; }
.attention-critical td { background:#fffafa; }
.attention-warning td { background:#fffdf7; }
.upn {
    color:var(--muted);
    font-size:12px;
    word-break:break-all;
}
.yes {
    color:var(--green);
    font-weight:650;
}
.no {
    color:var(--red);
    font-weight:650;
}
.search {
    width:100%;
    padding:13px 16px;
    margin-bottom:20px;
    border:1px solid var(--border);
    border-radius:8px;
    font-size:14px;
    outline:none;
    background:white;
}
.search:focus {
    border-color:var(--blue);
    box-shadow:0 0 0 3px rgba(0,120,212,.12);
}
.empty-state {
    text-align:center;
    padding:50px!important;
    color:var(--muted);
}
.success-icon {
    width:48px;
    height:48px;
    border-radius:50%;
    background:var(--green-bg);
    color:var(--green);
    display:flex;
    align-items:center;
    justify-content:center;
    margin:0 auto 12px;
    font-size:25px;
    font-weight:bold;
}
.timeline {
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
    gap:15px;
}
.timeline-item {
    padding:18px;
    border:1px solid var(--border);
    border-radius:10px;
    background:#f8fafc;
}
.timeline-date {
    font-size:18px;
    font-weight:700;
    color:var(--blue);
}
.timeline-label {
    margin-top:5px;
    color:var(--muted);
    font-size:13px;
}
.footer {
    text-align:center;
    color:var(--muted);
    font-size:12px;
    padding:30px;
}
@media (max-width:800px) {
    .header { padding:30px 20px; }
    .header h1 { font-size:25px; }
    .container { padding:0 12px; }
    .section-body { padding:15px; }
    table { min-width:850px; }
}
</style>
</head>
<body>
<header class="header">
<div class="header-content">
<h1>Microsoft Entra SSPR Audit</h1>
<p>Authentication Method Registration &amp; Registration Campaign Dashboard</p>
<p class="generated">Generated: $Generated &nbsp; | &nbsp; $GeneratedUtc</p>
</div>
</header>

<main class="container">

<div class="cards">

<div class="card card-blue">
<div class="card-title">Total Users</div>
<div class="card-value">$TotalUsers</div>
</div>

<div class="card">
<div class="card-title">Administrators</div>
<div class="card-value">$AdminCount</div>
</div>

<div class="card card-blue">
<div class="card-title">SSPR Enabled</div>
<div class="card-value">$SSPREnabledCount</div>
</div>

<div class="card card-green">
<div class="card-title">SSPR Registered</div>
<div class="card-value">$SSPRRegisteredCount</div>
</div>

<div class="card card-orange">
<div class="card-title">Needs Attention</div>
<div class="card-value">$AttentionCount</div>
</div>

<div class="card card-red">
<div class="card-title">Admins Needing Attention</div>
<div class="card-value">$AdminAttentionCount</div>
</div>

</div>

<section class="section">
<div class="section-header">
<h2>Authentication Registration Overview</h2>
<p>Additional authentication registration statistics.</p>
</div>

<div class="section-body">
<div class="campaign">

<div class="campaign-item">
<div class="campaign-label">MFA Capable</div>
<div class="campaign-value">$MFACapableCount</div>
</div>

<div class="campaign-item">
<div class="campaign-label">MFA Registered</div>
<div class="campaign-value">$MFARegisteredCount</div>
</div>

<div class="campaign-item">
<div class="campaign-label">Passwordless Capable</div>
<div class="campaign-value">$PasswordlessCapableCount</div>
</div>

<div class="campaign-item">
<div class="campaign-label">SSPR Registration Gap</div>
<div class="campaign-value">$AttentionCount</div>
</div>

</div>
</div>
</section>

<section class="section">
<div class="section-header">
<h2>Registration Campaign</h2>
<p>Current Microsoft Entra authentication registration campaign configuration.</p>
</div>

<div class="section-body">

<div class="campaign">

<div class="campaign-item">
<div class="campaign-label">Status</div>
<div class="campaign-value">
<span class="status $CampaignStatusClass">$(ConvertTo-HtmlSafe $CampaignState)</span>
</div>
</div>

<div class="campaign-item">
<div class="campaign-label">Targeted Authentication Method</div>
<div class="campaign-value">$(ConvertTo-HtmlSafe $ActualTargetedMethod)</div>
</div>

<div class="campaign-item">
<div class="campaign-label">Snooze Duration</div>
<div class="campaign-value">$(ConvertTo-HtmlSafe $ActualSnoozeDuration) day(s)</div>
</div>

<div class="campaign-item">
<div class="campaign-label">Enforce After Allowed Snoozes</div>
<div class="campaign-value">$EnforceHtml</div>
</div>

</div>

<div class="campaign-note">
<strong>Included targets:</strong>
$IncludedHtml
<br><br>
<strong>Excluded targets:</strong>
$ExcludedHtml
<br><br>
$(ConvertTo-HtmlSafe $ChangeDescription)
</div>

</div>
</section>

<section class="section">
<div class="section-header">
<h2>Users Requiring Attention</h2>
<p>SSPR-enabled users who are not currently SSPR registered. Administrators are highlighted separately.</p>
</div>

<div class="section-body">
<div class="table-wrapper">
<table>
<thead>
<tr>
<th>User</th>
<th>Priority</th>
<th>Registered Authentication Methods</th>
<th>User Type</th>
</tr>
</thead>
<tbody>
$AttentionRows
</tbody>
</table>
</div>
</div>
</section>

<section class="section">
<div class="section-header">
<h2>Authentication Methods Policy</h2>
<p>Authentication methods currently configured in Microsoft Entra.</p>
</div>

<div class="section-body">
<div class="table-wrapper">
<table>
<thead>
<tr>
<th>Authentication Method</th>
<th>State</th>
</tr>
</thead>
<tbody>
$PolicyRows
</tbody>
</table>
</div>
</div>
</section>

<section class="section">
<div class="section-header">
<h2>Authentication Method Registration</h2>
<p>Complete registration status for all users returned by Microsoft Graph.</p>
</div>

<div class="section-body">

<input
    type="text"
    id="userSearch"
    class="search"
    placeholder="Search users, UPNs or authentication methods..."
    onkeyup="filterUsers()"
/>

<div class="table-wrapper">
<table id="usersTable">
<thead>
<tr>
<th>User</th>
<th>Role</th>
<th>SSPR Status</th>
<th>MFA Registered</th>
<th>Passwordless Capable</th>
<th>Registered Authentication Methods</th>
<th>Method Count</th>
</tr>
</thead>
<tbody>
$UserRows
</tbody>
</table>
</div>

</div>
</section>

<section class="section">
<div class="section-header">
<h2>Microsoft SSPR Timeline</h2>
<p>Key dates for the 2026 SSPR authentication-method registration change.</p>
</div>

<div class="section-body">
<div class="timeline">

<div class="timeline-item">
<div class="timeline-date">July 6, 2026</div>
<div class="timeline-label">Registration campaign starts</div>
</div>

<div class="timeline-item">
<div class="timeline-date">September 7, 2026</div>
<div class="timeline-label">SSPR enforcement</div>
</div>

</div>
</div>
</section>

</main>

<footer class="footer">
Microsoft Entra SSPR Audit &nbsp; • &nbsp; Generated $Generated
</footer>

<script>
function filterUsers() {
    const input = document.getElementById("userSearch").value.toLowerCase();
    const table = document.getElementById("usersTable");
    const rows = table.getElementsByTagName("tbody")[0].getElementsByTagName("tr");

    for (let i = 0; i < rows.length; i++) {
        const text = rows[i].innerText.toLowerCase();
        rows[i].style.display = text.includes(input) ? "" : "none";
    }
}
</script>

</body>
</html>
"@

    $Html | Set-Content -LiteralPath $OutputPath -Encoding UTF8

    return $OutputPath
}

try {
    if (-not (Test-Path -LiteralPath $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    $HtmlReportPath = Join-Path `
        $OutputPath `
        "Entra-SSPR-Audit-$Timestamp.html"

    $PolicyReportPath = Join-Path `
        $OutputPath `
        "AuthenticationMethodsPolicy-$Timestamp.json"

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " Microsoft Entra SSPR Authentication Method Audit" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $RequiredModules = @(
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Reports",
        "Microsoft.Graph.Identity.SignIns"
    )

    foreach ($Module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $Module)) {
            Write-Host "Installing module: $Module" -ForegroundColor Yellow

            Install-Module `
                -Name $Module `
                -Scope CurrentUser `
                -Force `
                -AllowClobber `
                -ErrorAction Stop
        }

        Import-Module $Module -ErrorAction Stop
    }

    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

    $Scopes = @(
        "AuditLog.Read.All",
        "Policy.Read.All",
        "Policy.ReadWrite.AuthenticationMethod"
    )

    Connect-MgGraph -Scopes $Scopes -NoWelcome

    $Context = Get-MgContext

    if ($null -eq $Context) {
        throw "Microsoft Graph connection was not established."
    }

    Write-Host "Connected to tenant: $($Context.TenantId)" -ForegroundColor Green
    Write-Host ""

    Write-Host "Retrieving authentication-method registration details..." -ForegroundColor Cyan

    $RegistrationDetails = @(
        Get-MgReportAuthenticationMethodUserRegistrationDetail -All
    )

    if ($RegistrationDetails.Count -eq 0) {
        throw "No authentication registration details were returned."
    }

    Write-Host "Users returned: $($RegistrationDetails.Count)" -ForegroundColor Green
    Write-Host ""

    Write-Host "Normalizing registration data..." -ForegroundColor Cyan

    $Audit = @(
        foreach ($User in $RegistrationDetails) {
            $Methods = @(
                $User.MethodsRegistered
            ) | Where-Object {
                $null -ne $_ -and $_.ToString().Trim() -ne ""
            }

            [PSCustomObject]@{
                UserPrincipalName = $User.UserPrincipalName
                DisplayName = $User.UserDisplayName
                UserType = $User.UserType
                IsAdministrator = [bool]$User.IsAdmin
                IsSSPREnabled = [bool]$User.IsSsprEnabled
                IsSSPRRegistered = [bool]$User.IsSsprRegistered
                IsMFACapable = [bool]$User.IsMfaCapable
                IsMFARegistered = [bool]$User.IsMfaRegistered
                IsPasswordlessCapable = [bool]$User.IsPasswordlessCapable
                RegisteredAuthenticationMethods = ($Methods -join "; ")
                RegisteredAuthenticationMethodCount = $Methods.Count
                LastUpdated = $User.LastUpdatedDateTime
            }
        }
    )

    Write-Host "Audit objects created: $($Audit.Count)" -ForegroundColor Green
    Write-Host ""

    Write-Host "Identifying users requiring attention..." -ForegroundColor Cyan

    $UsersRequiringAttention = @(
        $Audit | Where-Object {
            $_.IsSSPREnabled -eq $true -and
            $_.IsSSPRRegistered -ne $true
        }
    )

    $TotalUsers = $Audit.Count

    $AdminCount = @(
        $Audit | Where-Object {
            $_.IsAdministrator -eq $true
        }
    ).Count

    $SSPREnabledCount = @(
        $Audit | Where-Object {
            $_.IsSSPREnabled -eq $true
        }
    ).Count

    $SSPRRegisteredCount = @(
        $Audit | Where-Object {
            $_.IsSSPRRegistered -eq $true
        }
    ).Count

    $NoSSPRRegistrationCount = $UsersRequiringAttention.Count

    $AdminsRequiringAttention = @(
        $UsersRequiringAttention | Where-Object {
            $_.IsAdministrator -eq $true
        }
    ).Count

    Write-Host ""
    Write-Host "---------------- Audit Summary ----------------" -ForegroundColor Cyan
    Write-Host "Total users:                         $TotalUsers"
    Write-Host "Administrators:                     $AdminCount"
    Write-Host "SSPR-enabled users:                 $SSPREnabledCount"
    Write-Host "SSPR-registered users:              $SSPRRegisteredCount"
    Write-Host "Users requiring attention:          $NoSSPRRegistrationCount"
    Write-Host "Administrators requiring attention: $AdminsRequiringAttention"
    Write-Host ""

    if ($NoSSPRRegistrationCount -gt 0) {
        Write-Host "Users requiring attention:" -ForegroundColor Yellow

        $UsersRequiringAttention |
            Select-Object `
                UserPrincipalName,
                DisplayName,
                IsAdministrator,
                IsSSPREnabled,
                IsSSPRRegistered,
                RegisteredAuthenticationMethods |
            Format-Table -AutoSize
    }
    else {
        Write-Host "All SSPR-enabled users are currently SSPR registered." -ForegroundColor Green
    }

    Write-Host ""

    Write-Host "Retrieving Authentication Methods Policy..." -ForegroundColor Cyan

    $AuthenticationMethodsPolicy = Get-MgPolicyAuthenticationMethodPolicy

    if ($null -eq $AuthenticationMethodsPolicy) {
        throw "Unable to retrieve the Authentication Methods Policy."
    }

    Write-Host ""
    Write-Host "Configured authentication methods:" -ForegroundColor Cyan
    Write-Host ""

    @($AuthenticationMethodsPolicy.AuthenticationMethodConfigurations) |
        Select-Object Id, State |
        Format-Table -AutoSize

    Write-Host ""

    $Campaign = $null

    if ($null -ne $AuthenticationMethodsPolicy.RegistrationEnforcement) {
        $Campaign = $AuthenticationMethodsPolicy.RegistrationEnforcement.AuthenticationMethodsRegistrationCampaign
    }

    if ($null -ne $Campaign) {
        Write-Host "Current registration campaign configuration:" -ForegroundColor Cyan

        $Campaign |
            Select-Object `
                State,
                SnoozeDurationInDays,
                EnforceRegistrationAfterAllowedSnoozes |
            Format-List
    }
    else {
        Write-Host "No registration campaign configuration was returned." -ForegroundColor Yellow
    }

    $CampaignChangeRequested = $false

    if ($EnableRegistrationCampaign) {
        Write-Host ""
        Write-Host "Preparing registration campaign configuration..." -ForegroundColor Cyan

        $CampaignConfiguration = @{
            registrationEnforcement = @{
                authenticationMethodsRegistrationCampaign = @{
                    snoozeDurationInDays = $SnoozeDurationInDays
                    enforceRegistrationAfterAllowedSnoozes = $true
                    state = "enabled"
                    excludeTargets = @()
                    includeTargets = @(
                        @{
                            id = "all_users"
                            targetType = "group"
                            targetedAuthenticationMethod = $CampaignAuthenticationMethod
                        }
                    )
                }
            }
        }

        $ActionDescription = "Enable $CampaignAuthenticationMethod registration campaign for all users"

        if ($PSCmdlet.ShouldProcess("Microsoft Entra tenant", $ActionDescription)) {
            Write-Host ""
            Write-Host "Enabling registration campaign..." -ForegroundColor Yellow

            Update-MgPolicyAuthenticationMethodPolicy `
                -BodyParameter $CampaignConfiguration `
                -ErrorAction Stop

            $CampaignChangeRequested = $true

            Write-Host ""
            Write-Host "Registration campaign update submitted successfully." -ForegroundColor Green
            Write-Host "Authentication method: $CampaignAuthenticationMethod"
            Write-Host "Snooze duration:       $SnoozeDurationInDays day(s)"
            Write-Host "Enforce after snoozes: Yes"
        }
        else {
            Write-Host ""
            Write-Host "WhatIf mode: registration campaign was NOT changed." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host ""
        Write-Host "Audit-only mode selected." -ForegroundColor Yellow
        Write-Host "Registration campaign was NOT changed."
    }

    Write-Host ""
    Write-Host "Re-reading Authentication Methods Policy..." -ForegroundColor Cyan

    $AuthenticationMethodsPolicy = Get-MgPolicyAuthenticationMethodPolicy

    if ($null -eq $AuthenticationMethodsPolicy) {
        throw "Unable to re-read the Authentication Methods Policy."
    }

    $AuthenticationMethodsPolicy |
        ConvertTo-Json -Depth 50 |
        Set-Content `
            -LiteralPath $PolicyReportPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "Policy exported to:" -ForegroundColor Green
    Write-Host "  $PolicyReportPath"
    Write-Host ""

    Write-Host "Generating HTML audit dashboard..." -ForegroundColor Cyan

    $GeneratedHtml = ConvertTo-EntraAuditHtml `
        -Audit $Audit `
        -UsersRequiringAttention $UsersRequiringAttention `
        -AuthenticationMethodsPolicy $AuthenticationMethodsPolicy `
        -OutputPath $HtmlReportPath `
        -CampaignAuthenticationMethod $CampaignAuthenticationMethod `
        -SnoozeDurationInDays $SnoozeDurationInDays `
        -CampaignChangeRequested $CampaignChangeRequested

    if (-not (Test-Path -LiteralPath $GeneratedHtml)) {
        throw "HTML report was not created successfully."
    }

    Write-Host ""
    Write-Host "HTML audit dashboard created:" -ForegroundColor Green
    Write-Host "  $GeneratedHtml"
    Write-Host ""

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " Audit completed." -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Reports:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  HTML audit dashboard:"
    Write-Host "    $HtmlReportPath"
    Write-Host ""
    Write-Host "  Authentication Methods Policy:"
    Write-Host "    $PolicyReportPath"
    Write-Host ""

    Write-Host "Microsoft SSPR timeline:" -ForegroundColor Cyan
    Write-Host "  Registration campaign: July 6, 2026"
    Write-Host "  Enforcement:           September 7, 2026"
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
finally {
    if ($null -ne (Get-MgContext)) {
        Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Cyan
        Disconnect-MgGraph | Out-Null
    }
}
