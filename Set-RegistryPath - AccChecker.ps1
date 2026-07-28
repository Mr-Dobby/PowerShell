$registryPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\powerpoint\accchecker'
$Name = "alttext"
$value = "0" ##REDACTED

#Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope LocalMachine

If (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType string -Force | Out-Null
    Write-Output "Ran script. Set: $registryPath \$Name=$value" | Out-File "$env:USERPROFILE\AccChecker.txt"
} else {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType string -Force | Out-Null
    Write-Output "Ran script. Set: $registryPath \$Name=$value" | Out-File "$env:USERPROFILE\AccChecker.txt"
}