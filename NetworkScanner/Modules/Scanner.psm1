function New-NetworkResult {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [Parameter(Mandatory)]
        [string]$Status,
        [string]$Hostname = '',
        [Nullable[long]]$ResponseTime = $null,
        [string]$MACAddress = '',
        [string]$OpenPorts = ''
    )

    [PSCustomObject]@{
        IPAddress     = $IPAddress
        Status        = $Status
        Hostname      = $Hostname
        ResponseTime  = $ResponseTime
        MACAddress    = $MACAddress
        OpenPorts     = $OpenPorts
        ScanTime      = Get-Date
    }
}

function Test-SubnetFormat {
    param([Parameter(Mandatory)][string]$Subnet)
    $Subnet -match '^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){2}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$'
}

function Resolve-HostNameSafe {
    param([Parameter(Mandatory)][string]$IPAddress)
    try {
        [System.Net.Dns]::GetHostEntry($IPAddress).HostName
    }
    catch {
        ''
    }
}

function Test-TcpPorts {
    param(
        [Parameter(Mandatory)][string]$IPAddress,
        [Parameter(Mandatory)][int[]]$Ports,
        [Parameter(Mandatory)][int]$Timeout
    )

    $openPorts = [System.Collections.Generic.List[int]]::new()

    foreach ($port in $Ports | Sort-Object -Unique) {
        if ($port -lt 1 -or $port -gt 65535) {
            continue
        }

        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            $task = $client.ConnectAsync($IPAddress, $port)
            if ($task.Wait($Timeout) -and $client.Connected) {
                $openPorts.Add($port)
            }
        }
        catch {
            # ignore port exceptions
        }
        finally {
            $client.Dispose()
        }
    }

    return ($openPorts.ToArray() -join ',')
}

function Test-NetworkHost {
    param(
        [Parameter(Mandatory)][string]$IPAddress,
        [Parameter(Mandatory)][int]$Timeout,
        [Parameter(Mandatory)][bool]$ResolveDNS,
        [Parameter(Mandatory)][bool]$ShowMac,
        [Parameter(Mandatory)][bool]$ScanPorts,
        [int[]]$Ports
    )

    $ping = [System.Net.NetworkInformation.Ping]::new()
    try {
        $reply = $ping.Send($IPAddress, $Timeout)
        if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
            $hostname = if ($ResolveDNS) { Resolve-HostNameSafe -IPAddress $IPAddress } else { '' }
            $mac = if ($ShowMac) { Get-MacAddress -IPAddress $IPAddress } else { '' }
            $openPorts = if ($ScanPorts -and $Ports -and $Ports.Count -gt 0) {
                Test-TcpPorts -IPAddress $IPAddress -Ports $Ports -Timeout $Timeout
            }
            else {
                ''
            }

            return New-NetworkResult `
                -IPAddress $IPAddress `
                -Status 'Online' `
                -Hostname $hostname `
                -ResponseTime ([long]$reply.RoundtripTime) `
                -MACAddress $mac `
                -OpenPorts $openPorts
        }
    }
    catch {
        # host is treated as offline
    }
    finally {
        $ping.Dispose()
    }

    return New-NetworkResult -IPAddress $IPAddress -Status 'Offline'
}

function Start-NetworkScan {
    <#
    .SYNOPSIS
    Performs an IPv4 network scan across a CIDR block or a subnet range.

    .DESCRIPTION
    Supports PowerShell 7 parallel scanning (ForEach-Object -Parallel) with a
    Windows PowerShell 5.1 sequential fallback.
    #>
    [CmdletBinding(DefaultParameterSetName = 'CIDR')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'CIDR')]
        [string]$CIDR,

        [Parameter(Mandatory, ParameterSetName = 'Range')]
        [string]$Subnet,

        [Parameter(ParameterSetName = 'Range')]
        [ValidateRange(0, 255)]
        [int]$Start = 1,

        [Parameter(ParameterSetName = 'Range')]
        [ValidateRange(0, 255)]
        [int]$End = 254,

        [ValidateRange(1, 1024)]
        [int]$Threads = 50,

        [ValidateRange(50, 20000)]
        [int]$Timeout = 700,

        [switch]$ResolveDNS,
        [switch]$ShowMac,
        [switch]$ShowOffline,
        [switch]$ScanPorts,
        [int[]]$Ports = @(22, 80, 443, 3389)
    )

    if ($PSCmdlet.ParameterSetName -eq 'Range') {
        if (-not (Test-SubnetFormat -Subnet $Subnet)) {
            throw "Invalid subnet '$Subnet'. Use first three octets, example: 192.168.1"
        }
        if ($Start -gt $End) {
            throw "Start value ($Start) must be less than or equal to End value ($End)."
        }
    }

    $addresses = if ($PSCmdlet.ParameterSetName -eq 'CIDR') {
        ConvertFrom-CIDR -CIDR $CIDR
    }
    else {
        $Start..$End | ForEach-Object { "$Subnet.$_" }
    }

    if (-not $addresses -or $addresses.Count -eq 0) {
        throw 'No addresses generated from the provided target.'
    }

    $results = [System.Collections.Generic.List[object]]::new()
    $total = $addresses.Count
    $completed = 0

    $useParallel = $PSVersionTable.PSVersion.Major -ge 7

    if ($useParallel) {
        $parallelScript = {
            $IPAddress = [string]$_

            function Resolve-HostNameInternal {
                param([string]$IP)
                try { [System.Net.Dns]::GetHostEntry($IP).HostName } catch { '' }
            }

            function Get-MacAddressInternal {
                param([string]$IP)
                try {
                    $line = arp -a | Select-String -SimpleMatch $IP | Select-Object -First 1
                    if (-not $line) { return '' }
                    $match = [regex]::Match($line.ToString(), '(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}')
                    if ($match.Success) { return $match.Value.ToUpperInvariant() }
                    ''
                }
                catch {
                    ''
                }
            }

            function Test-TcpPortsInternal {
                param([string]$IP, [int[]]$Ports, [int]$Timeout)

                $open = [System.Collections.Generic.List[int]]::new()
                foreach ($port in $Ports | Sort-Object -Unique) {
                    if ($port -lt 1 -or $port -gt 65535) { continue }
                    $client = [System.Net.Sockets.TcpClient]::new()
                    try {
                        $task = $client.ConnectAsync($IP, $port)
                        if ($task.Wait($Timeout) -and $client.Connected) {
                            $open.Add($port)
                        }
                    }
                    catch { }
                    finally { $client.Dispose() }
                }

                $open.ToArray() -join ','
            }

            $ping = [System.Net.NetworkInformation.Ping]::new()
            try {
                $reply = $ping.Send($IPAddress, $using:Timeout)
                if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                    $hostname = if ($using:ResolveDNS) { Resolve-HostNameInternal -IP $IPAddress } else { '' }
                    $mac = if ($using:ShowMac) { Get-MacAddressInternal -IP $IPAddress } else { '' }
                    $openPorts = if ($using:ScanPorts -and $using:Ports -and $using:Ports.Count -gt 0) {
                        Test-TcpPortsInternal -IP $IPAddress -Ports $using:Ports -Timeout $using:Timeout
                    }
                    else {
                        ''
                    }

                    return [PSCustomObject]@{
                        IPAddress     = $IPAddress
                        Status        = 'Online'
                        Hostname      = $hostname
                        ResponseTime  = [long]$reply.RoundtripTime
                        MACAddress    = $mac
                        OpenPorts     = $openPorts
                        ScanTime      = Get-Date
                    }
                }
            }
            catch { }
            finally { $ping.Dispose() }

            [PSCustomObject]@{
                IPAddress     = $IPAddress
                Status        = 'Offline'
                Hostname      = ''
                ResponseTime  = $null
                MACAddress    = ''
                OpenPorts     = ''
                ScanTime      = Get-Date
            }
        }

        $addresses |
            ForEach-Object -Parallel $parallelScript -ThrottleLimit $Threads |
            ForEach-Object {
                $completed++
                Write-Progress -Activity 'Scanning Network' -Status "$completed of $total" -PercentComplete (($completed / $total) * 100)

                if ($_.Status -eq 'Online' -or $ShowOffline) {
                    $results.Add($_)
                }
            }
    }
    else {
        foreach ($ip in $addresses) {
            $completed++
            Write-Progress -Activity 'Scanning Network' -Status "$completed of $total" -PercentComplete (($completed / $total) * 100)

            $result = Test-NetworkHost -IPAddress $ip -Timeout $Timeout -ResolveDNS ([bool]$ResolveDNS) -ShowMac ([bool]$ShowMac) -ScanPorts ([bool]$ScanPorts) -Ports $Ports
            if ($result.Status -eq 'Online' -or $ShowOffline) {
                $results.Add($result)
            }
        }
    }

    Write-Progress -Activity 'Scanning Network' -Completed

    return $results.ToArray() | Sort-Object {
        try { [version]$_.IPAddress }
        catch { [version]'0.0.0.0' }
    }
}

Export-ModuleMember -Function Start-NetworkScan