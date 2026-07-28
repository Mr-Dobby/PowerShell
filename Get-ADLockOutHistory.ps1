$username = "" # Username
$domainControllers = @("DC01", "DC02") # Domain controllers to check
$lockoutEvents = @{}
#$startDate = (Get-Date).AddMonths(-3) # Used for time filter - undo line 9
#$endDate = Get-Date                   # Used for time filter - undo line 9
foreach ($dc in $domainControllers) {
    try {
        $events = Get-WinEvent -ComputerName $dc -LogName Security -FilterXPath "*[System[(EventID=4740)]]" -ErrorAction Stop
#        $events = Get-WinEvent -ComputerName $dc -LogName Security -FilterXPath "*[System[(EventID=4740) and TimeCreated[@SystemTime>='$($startDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))' and @SystemTime<='$($endDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))']]]" -ErrorAction Stop


        foreach ($event in $events) {
            if ($event.Properties[0].Value -like "*$username*") {
                if (-not $lockoutEvents.ContainsKey($dc)) {
                    $lockoutEvents[$dc] = @()
                }
                $lockoutEvents[$dc] += $event
            }
        }
    } catch {
       Write-Warning "$dc - $_"
    }
}

foreach ($dc in $lockoutEvents.Keys) {
  Write-Host "Checking criteria on $dc"
    foreach ($event in $lockoutEvents[$dc]) {
        Write-Host "Time: $($event.TimeCreated)"
        Write-Host "Account Name: $($event.Properties[0].Value)"
        Write-Host "Caller Computer Name: $($event.Properties[1].Value)"
        Write-Host "Lockout Reason: $($event.Message)"
        Write-Host "`n----------------------------------------------------`n"
    }
}