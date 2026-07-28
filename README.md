# PowerShell Administration Scripts

A collection of PowerShell scripts for Windows, Active Directory, Exchange Online, Microsoft 365, Azure AD, Intune, and troubleshooting tasks.

> ⚠️ Warning: Several scripts in this repository perform destructive actions such as registry modifications, application removal, Intune remediation, or device deletion. Always test before production use.

---

# Contents

- Windows Administration
- Active Directory
- Exchange Online
- Microsoft 365 & Azure AD
- Intune
- Identity Protection
- Utility Scripts

---

# Windows Administration

## ResetWindowsSearchBox.ps1

Resets the Windows Search experience by clearing Search/Cortana cache data and restarting associated processes.

### Usage

Run PowerShell as Administrator:

```powershell
.\ResetWindowsSearchBox.ps1
```

### What it does

- Stops Explorer and Search processes
- Clears Search/Cortana caches
- Removes Search testability registry keys
- Restarts Windows Search components

### Requirements

- Local Administrator
- Windows 10/11

---

## Disable-SmartScreen.ps1

Disables Microsoft Defender SmartScreen through registry policies.

### Usage

```powershell
.\Disable-SmartScreen.ps1
```

### What it does

- Disables Windows SmartScreen
- Disables Edge SmartScreen protection

### Warning

Reduces endpoint security.

---

## GhostRemover.ps1

Lists or removes hidden ("ghost") devices from Device Manager.

### Usage

List ghost devices:

```powershell
.\GhostRemover.ps1 -ListGhostDevicesOnly
```

List all devices:

```powershell
.\GhostRemover.ps1 -ListDevicesOnly
```

Remove ghost devices:

```powershell
.\GhostRemover.ps1 -Force
```

Remove only network devices:

```powershell
.\GhostRemover.ps1 -NarrowByClass Net -Force
```

### Features

- Device enumeration
- Ghost device detection
- Device removal
- Filtering by class and name

### Warning

Device removals cannot easily be undone.

---

## Remove-GoogleChrome.ps1

Aggressively removes Google Chrome and associated artifacts.

### Usage

Run as Administrator:

```powershell
.\Remove-GoogleChrome.ps1
```

### What it does

- Stops Chrome processes
- Executes multiple uninstall methods
- Removes registry entries
- Deletes remaining files and folders

### Warning

Highly destructive script.

---

## DANGER_Stress-Test_cpu-usage1.ps1

Generates heavy CPU load using background jobs.

### Usage

```powershell
.\DANGER_Stress-Test_cpu-usage1.ps1 -NumHyperCores 8
```

### Parameters

```text
NumHyperCores
```

Number of logical CPU cores to stress.

### Warning

May cause overheating and system instability.

---

## DANGER_Stress-Test_cpu-usage2.ps1

CPU stress test with temperature monitoring.

### Usage

```powershell
.\DANGER_Stress-Test_cpu-usage2.ps1
```

or

```powershell
Test-StressCPU -Time 10
```

### Parameters

```text
Time
```

Stress-test duration in minutes.

---

## Get-ACLPermissions.ps1

Reports NTFS permissions on folders.

### Usage

```powershell
.\Get-ACLPermissions.ps1
```

Optional CSV export:

```powershell
$Output | Export-Csv ACLReport.csv -NoTypeInformation
```

### Output

- Folder Name
- User/Group
- Permission
- Inherited Status

---

## Remove-LiteralPath.ps1

Deletes files or folders containing special characters or trailing spaces.

### Usage

Modify path:

```powershell
Remove-Item -LiteralPath "\\?\E:\Path\To\File "
```

Run:

```powershell
.\Remove-LiteralPath.ps1
```

---

# Active Directory

## All_AD_Groups-and-members.ps1

Exports all AD groups and their members into a matrix-based CSV.

### Usage

```powershell
.\All_AD_Groups-and-members.ps1
```

### Output

```text
GroupReport.csv
```

### Requirements

```powershell
Import-Module ActiveDirectory
```

---

## Get-ADGroupMembers.ps1

Exports group membership information to CSV.

### Usage

Filter groups:

```powershell
$Filter = "IT"
```

Run:

```powershell
.\Get-ADGroupMembers.ps1
```

### Output

```text
SecurityGroups.csv
```

Contains:

- Group Name
- User Name
- SamAccountName

---

## All_OU_Users-General.ps1

Exports user information from selected Organizational Units.

### Usage

Populate the Distinguished Names array:

```powershell
$DNs = @(
    "OU=Users,DC=contoso,DC=com"
)
```

Run:

```powershell
.\All_OU_Users-General.ps1
```

### Output

CSV containing:

- User details
- Contact information
- Department
- Manager
- Account status
- Last logon date

---

# Exchange Online

## Get-EverySingleInboxRule.ps1

Retrieves Inbox Rules from all Exchange mailboxes.

### Usage

```powershell
Connect-ExchangeOnline

.\Get-EverySingleInboxRule.ps1
```

### Output

- Mailbox Name
- Rule Name
- Description
- Priority

---

## MailboxPermissions.ps1

Exports mailbox delegation permissions.

### Usage

```powershell
.\MailboxPermissions.ps1
```

### Output

```text
MailboxesUserHasAccessTo_<timestamp>.csv
```

Contains:

- Mailbox
- User
- Access Rights

---

## MailboxesForUser.ps1

Generates mailbox access reports.

### Usage

Single user:

```powershell
.\MailboxesForUser.ps1 -UPN user@contoso.com
```

Full Access only:

```powershell
.\MailboxesForUser.ps1 `
    -UPN user@contoso.com `
    -FullAccess
```

CSV input:

```powershell
.\MailboxesForUser.ps1 -CSV users.csv
```

### Reports

- Full Access
- Send As
- Send On Behalf

---

## Set-MailboxFolderPermissions_For_Multiple_Users.ps1

Sets default Calendar permissions for all users.

### Usage

```powershell
.\Set-MailboxFolderPermissions_For_Multiple_Users.ps1
```

### Permission Config

```powershell
$Permission = "Reviewer"
```

### Notes

The script currently includes:

```powershell
-WhatIf
```

No actual changes are performed until removed.

---

## Get-MailboxFolderSearchParameters.ps1

Generates FolderID search parameters for Purview / eDiscovery searches.

### Usage

```powershell
.\Get-MailboxFolderSearchParameters.ps1
```

When prompted, enter:

```text
user@contoso.com
```

or

```text
https://tenant.sharepoint.com/sites/SiteName
```

### Use Cases

- Purview Content Search
- eDiscovery investigations

---

## Get-MultiUserFolderIDseDiscovery.ps1

Generates FolderID search strings for multiple mailboxes.

### Usage

Create:

```csv
UserSMTP
user1@contoso.com
user2@contoso.com
```

Save as:

```text
Users_GatherFolderID.csv
```

Run:

```powershell
.\Get-MultiUserFolderIDseDiscovery.ps1
```

---

# Microsoft 365 & Azure AD

## Get-DistributionGroupMembers.ps1

Exports Microsoft 365 Group membership information.

### Usage

```powershell
Connect-ExchangeOnline

.\Get-DistributionGroupMembers.ps1
```

### Output

- Group Name
- User Name
- Primary SMTP Address

---

## Get-LicensedUserMailboxes.ps1

Exports licensed mailbox-enabled users.

### Usage

```powershell
.\Get-LicensedUserMailboxes.ps1
```

### Output

```text
C:\LicensedUserMailboxes.csv
```

Contains:

- Display Name
- UPN
- Mail Address
- License Count

---

## Get-AzureADUserLoginLogs.ps1

Exports Azure AD sign-in activity.

### Usage

Set target user:

```powershell
$userEmail = "user@contoso.com"
```

Run:

```powershell
.\Get-AzureADUserLoginLogs.ps1
```

### Output

- Login Time
- Source IP
- Client Application
- Authentication Result

---

# Intune

## Get-DeviceManagementScripts.ps1

Downloads PowerShell scripts stored in Intune.

### Usage

Download all scripts:

```powershell
Get-DeviceManagementScripts `
    -FolderPath C:\Temp
```

Download a specific script:

```powershell
Get-DeviceManagementScripts `
    -FolderPath C:\Temp `
    -FileName ScriptName.ps1
```

### Requirements

```powershell
Install-Module Microsoft.Graph.Intune
```

---

## Remove-RequiredIntuneApps.ps1

Forces an Intune Win32 application to redeploy.

### Usage

Update:

```powershell
$AppID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Run as Administrator:

```powershell
.\Remove-RequiredIntuneApps.ps1
```

### What it does

- Deletes Intune app detection state
- Removes GRS records
- Restarts IME service

---

## DriveMapper.ps1

Maps network drives using predefined SMB shares.

### Usage

Configure:

```powershell
$dnsDomainName = "corp.contoso.com"

$new_driveMappingConfig += @{
    DriveLetter = "P"
    UNCPath     = "\\server\share"
    Description = "Projects"
}
```

Run:

```powershell
.\DriveMapper.ps1
```

### Features

- DNS validation
- Persistent mappings
- Drive label assignment
- Mapping correction

---

# Identity Protection

## Get-AzureADIPRiskyUser.ps1

Retrieves Azure AD Identity Protection risky users.

### Usage

Retrieve all high-risk users:

```powershell
Get-AzureADIPRiskyUser `
    -RiskLevel High `
    -All
```

Return only User IDs:

```powershell
Get-AzureADIPRiskyUser `
    -RiskLevel High `
    -All `
    -AsUserIds
```

---

## Invoke-AzureADIPDismissRiskyUser.ps1

Dismisses risky-user findings.

### Usage

```powershell
Invoke-AzureADIPDismissRiskyUser `
    -UserIds $UserIds
```

### Required Scope

```text
IdentityRiskyUser.ReadWrite.All
```

---

## Invoke-AzureADIPConfirmCompromisedRiskyUser.ps1

Marks risky users as compromised.

### Usage

```powershell
Invoke-AzureADIPConfirmCompromisedRiskyUser `
    -UserIds $UserIds
```

### Required Scope

```text
IdentityRiskyUser.ReadWrite.All
```

---

## Set-RegistryPath

Placeholder script.

### Status

No code present.
``