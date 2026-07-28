$UserProperty = @{n="User";e={(New-Object System.Security.Principal.SecurityIdentifier $_.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])}}
$TypeProperty = @{n="Action";e={if($_.EventID -eq 7001) {"Logon"} else {"Logoff"}}}
$TimeProeprty = @{n="Time";e={$_.TimeGenerated}}

Get-EventLog System -Source Microsoft-Windows-Winlogon | select $UserProperty,$TypeProperty,$TimeProeprty