function ConvertTo-IPv4Integer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    $ip = [System.Net.IPAddress]::Parse($IPAddress)
    $bytes = $ip.GetAddressBytes()
    [array]::Reverse($bytes)
    return [BitConverter]::ToUInt32($bytes, 0)
}

function ConvertFrom-CIDR {
    <#
    .SYNOPSIS
    Expands a CIDR block into individual IPv4 host addresses.

    .PARAMETER CIDR
    CIDR range in the format x.x.x.x/n, for example 192.168.1.0/24.

    .OUTPUTS
    System.String[]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^(?:\d{1,3}\.){3}\d{1,3}/\d{1,2}$')]
        [string]$CIDR
    )

    $parts = $CIDR -split '/'
    if ($parts.Count -ne 2) {
        throw "Invalid CIDR format: '$CIDR'. Expected format x.x.x.x/n"
    }

    $network = $parts[0]
    $maskBits = [int]$parts[1]

    if ($maskBits -lt 0 -or $maskBits -gt 32) {
        throw "Invalid CIDR mask bits '$maskBits'. Valid range is 0-32."
    }

    $null = [System.Net.IPAddress]::Parse($network)
    $networkInt = ConvertTo-IPv4Integer -IPAddress $network

    $mask = [uint32]0
    if ($maskBits -gt 0) {
        for ($bit = 0; $bit -lt $maskBits; $bit++) {
            $mask = $mask -bor ([uint32]1 -shl (31 - $bit))
        }
    }

    $networkBase = [uint32]($networkInt -band $mask)
    $hostCount = [uint64][math]::Pow(2, (32 - $maskBits))

    # /31 and /32 include all addresses; larger networks exclude network+broadcast.
    $startOffset = if ($maskBits -le 30) { [uint64]1 } else { [uint64]0 }
    $endExclusive = if ($maskBits -le 30) { $hostCount - 1 } else { $hostCount }

    $addresses = [System.Collections.Generic.List[string]]::new()

    for ([uint64]$i = $startOffset; $i -lt $endExclusive; $i++) {
        $value = [uint32]($networkBase + $i)
        $bytes = [BitConverter]::GetBytes($value)
        [array]::Reverse($bytes)
        $addresses.Add(([System.Net.IPAddress]::new($bytes)).ToString())
    }

    return $addresses.ToArray()
}

Export-ModuleMember -Function ConvertFrom-CIDR, ConvertTo-IPv4Integer