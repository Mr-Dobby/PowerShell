function Get-MacAddress {
    param(
        [string]$IPAddress
    )

    try {
        $line = arp -a |
            Select-String -SimpleMatch $IPAddress |
            Select-Object -First 1

        if (-not $line) {
            return ''
        }

        $match = [regex]::Match($line.ToString(), '(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}')
        if ($match.Success) {
            return $match.Value.ToUpperInvariant()
        }

        ''
    }
    catch {
        ''
    }
}

Export-ModuleMember -Function Get-MacAddress