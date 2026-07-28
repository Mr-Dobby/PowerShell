#$KeyPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity"
#$ValueName = "EnableADAL"
#$ValueData = "1"
 
# try {
#    Get-ItemProperty -Path $KeyPath -Name $valueName -ErrorAction Stop
# }
# catch [System.Management.Automation.ItemNotFoundException] {
#     New-Item -Path $KeyPath -Force
#     New-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -Force
# }
# catch {
#     Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -Type String -Force
# }

$ol = New-Object -ComObject Outlook.Application
if ($ol.Version -ge 16 ) {

  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity" -Name "EnableADAL" -Value "1"  -PropertyType "DWORD"
  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity" -Name "DisableAADWAM" -Value "1"  -PropertyType "DWORD"
  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity" -Name "DisableADALatopWAMOverride" -Value "1"  -PropertyType "DWORD"

  } Else {

  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\Identity" -Name "EnableADAL" -Value ”1”  -PropertyType "DWORD"
  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\Identity" -Name "DisableAADWAM" -Value ”1”  -PropertyType "DWORD"
  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\Identity" -Name "DisableADALatopWAMOverride" -Value ”1”  -PropertyType "DWORD"
  
}
