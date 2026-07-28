function Test-StressCPU {
    [CmdletBinding()]
    param (
        $global:highTemp = 0,
        $global:lowTemp = 0,
        $global:numberOfTemps = 0,
        $Time = 1
    )
    
    begin {
        #add logging with high, low, temp gauges

        # Get cpu temp and if above certain C then warn
        function Get-Temperature {
            $thermalZone = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" #
            $returnTemp = @()

            # Process temps
            foreach ($temp in $thermalZone.CurrentTemperature) {
                $currentTempKelvin = ($temp / 10)
                $currentTempCelsius = [math]::round($currentTempKelvin - 273.15)
                $currentTempFahrenheit = [math]::round((9 / 5) * $currentTempCelsius + 32)
                $returnTemp += "$currentTempCelsius" + " °C | " + "$currentTempFahrenheit" + " °F"
                $global:numberOfTemps = ($returnTemp).count
            }
            foreach ($return in $returnTemp) {
                if ($return -ge "50") {
                    Write-Host "$return" -ForegroundColor Red
                    $global:highTemp++
                }
                else {
                    Write-Host "$return" -ForegroundColor Green
                    $global:lowTemp++
                }
            }
        }

        # Test stress CPU
        function Test-StressCPU {
            ForEach ($core in 1..$env:NUMBER_OF_PROCESSORS) {
                Start-Job -Name "CPU$core" -ScriptBlock {
                    $result = 1;
                    foreach ($loopnumber in 1..2147483647) {
                        $result = 1;
                        foreach ($number in 1..2147483647) {
                            $result = $result * $number
                        } # foreach number
                        $result
                    }# Foreach loopnumber
                }# Create jobs
            }# Foreach core
        }# Function Test-StressCPU

        #Runs the actual functions and keeps track of the timeout period
        function Test-CPULoad {
            $timeout = New-TimeSpan -Minutes $Time
            $sw = [diagnostics.stopwatch]::StartNew()
            Test-StressCPU
            while ($sw.elapsed -lt $timeout) {
                Clear-Host
                Write-Warning -Message "Stress Testing CPU in Progress..."
                Get-Temperature         
                Start-Sleep -Seconds 15
            }
            $cpuJobs = Get-Job -Name "CPU*"
            foreach ($job in $cpuJobs) {
                Stop-Job -Name $job.name
                Remove-Job -Name $job.name
            }
        }
    }
    
    process {
        Test-CPULoad
    }
    
    end {
        Write-Verbose -message "CPU Stress Test Complete..." -Verbose
        $half = (($time*4)/2)
        if ($highTemp -gt $half){
            Write-Host "CPU temperatures rose to/above 50°C for $((($highTemp/$global:numberOfTemps)/($time*4))*100)% of the time" -ForegroundColor Red
        }else {
            Write-Host "CPU temperatures stayed below 50°C for $((($lowTemp/$global:numberOfTemps)/($time*4))*100)% of the time" -ForegroundColor Green
        }
    }
}
Test-StressCPU