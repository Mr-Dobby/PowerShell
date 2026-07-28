function Sort-ScanResults {
    param([Parameter(Mandatory)][array]$Results)
    $Results | Sort-Object {
        try { [version]$_.IPAddress }
        catch { [version]'0.0.0.0' }
    }
}

function Export-NetworkScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Results,

        [Parameter(Mandatory)]
        [string]$OutputFolder,

        [switch]$Txt,
        [switch]$Csv,
        [switch]$Json,
        [switch]$Html
    )

    if (-not (Test-Path -LiteralPath $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    }

    if (-not ($Txt -or $Csv -or $Json -or $Html)) {
        Write-Warning 'No export format selected. Use -Txt, -Csv, -Json, and/or -Html.'
        return @()
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $baseName = "NetworkScan_$timestamp"
    $createdFiles = [System.Collections.Generic.List[string]]::new()
    $ordered = Sort-ScanResults -Results $Results

    if ($Txt) {
        $txtPath = Join-Path $OutputFolder "$baseName.txt"
        Export-NetworkScanTxt -Results $ordered -Path $txtPath
        $createdFiles.Add($txtPath)
    }

    if ($Csv) {
        $csvPath = Join-Path $OutputFolder "$baseName.csv"
        Export-NetworkScanCsv -Results $ordered -Path $csvPath
        $createdFiles.Add($csvPath)
    }

    if ($Json) {
        $jsonPath = Join-Path $OutputFolder "$baseName.json"
        Export-NetworkScanJson -Results $ordered -Path $jsonPath
        $createdFiles.Add($jsonPath)
    }

    if ($Html) {
        $htmlPath = Join-Path $OutputFolder "$baseName.html"
        Export-NetworkScanHtml -Results $ordered -Path $htmlPath
        $createdFiles.Add($htmlPath)
    }

    return $createdFiles.ToArray()
}

function Export-NetworkScanTxt {
    param(
        [array]$Results,
        [string]$Path
    )

    $online = ($Results | Where-Object Status -eq 'Online').Count
    $offline = ($Results | Where-Object Status -eq 'Offline').Count

    $output = @(
        '=============================================================='
        'Network Scan Report'
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        '=============================================================='
        ''
        "Online Devices : $online"
        "Offline Devices: $offline"
        ''
        'IP Address`tStatus`tHostname`tLatency(ms)`tMAC`tOpen Ports'
    )

    foreach ($item in $Results) {
        $output += "$($item.IPAddress)`t$($item.Status)`t$($item.Hostname)`t$($item.ResponseTime)`t$($item.MACAddress)`t$($item.OpenPorts)"
    }

    $output | Set-Content -Path $Path -Encoding UTF8
    Write-Host "TXT report saved: $Path" -ForegroundColor Green
}

function Export-NetworkScanCsv {
    param(
        [array]$Results,
        [string]$Path
    )

    $Results |
        Select-Object IPAddress, Status, Hostname, ResponseTime, MACAddress, OpenPorts, ScanTime |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $Path

    Write-Host "CSV report saved: $Path" -ForegroundColor Green
}

function Export-NetworkScanJson {
    param(
        [array]$Results,
        [string]$Path
    )

    $Results |
        ConvertTo-Json -Depth 6 |
        Set-Content -Path $Path -Encoding UTF8

    Write-Host "JSON report saved: $Path" -ForegroundColor Green
}

function Export-NetworkScanHtml {
    param(
        [array]$Results,
        [string]$Path
    )

    $online = ($Results | Where-Object Status -eq 'Online').Count
    $offline = ($Results | Where-Object Status -eq 'Offline').Count

    $rows = foreach ($item in $Results) {
        $class = if ($item.Status -eq 'Online') { 'online' } else { 'offline' }
        $icon = if ($item.Status -eq 'Online') { '🟢' } else { '🔴' }

        $ip = [System.Net.WebUtility]::HtmlEncode([string]$item.IPAddress)
        $status = [System.Net.WebUtility]::HtmlEncode([string]$item.Status)
        $hostname = [System.Net.WebUtility]::HtmlEncode([string]$item.Hostname)
        $latency = [System.Net.WebUtility]::HtmlEncode([string]$item.ResponseTime)
        $mac = [System.Net.WebUtility]::HtmlEncode([string]$item.MACAddress)
        $ports = [System.Net.WebUtility]::HtmlEncode([string]$item.OpenPorts)

        @"
<tr>
  <td>$ip</td>
  <td class="$class">$icon $status</td>
  <td>$hostname</td>
  <td>$latency</td>
  <td>$mac</td>
  <td>$ports</td>
</tr>
"@
    }

    $html = @"
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Network Scan Report</title>
  <style>
    body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; background: #f7f9fc; }
    h1 { margin-bottom: 0.4rem; }
    .meta { margin: 0.35rem 0; }
    table { border-collapse: collapse; width: 100%; background: white; }
    th, td { border: 1px solid #d9d9d9; padding: 8px; }
    th { background: #0078d7; color: white; cursor: pointer; user-select: none; }
    tr:nth-child(even) { background: #f3f6fb; }
    .online { color: #1f7a1f; font-weight: 700; }
    .offline { color: #b30000; font-weight: 700; }
  </style>
  <script>
    function sortTable(n) {
      const table = document.getElementById('scanTable');
      let switching = true;
      let dir = table.getAttribute('data-sort-dir') === 'asc' ? 'desc' : 'asc';
      while (switching) {
        switching = false;
        const rows = table.rows;
        for (let i = 1; i < rows.length - 1; i++) {
          let shouldSwitch = false;
          const x = rows[i].getElementsByTagName('TD')[n].innerText.toLowerCase();
          const y = rows[i + 1].getElementsByTagName('TD')[n].innerText.toLowerCase();
          if ((dir === 'asc' && x > y) || (dir === 'desc' && x < y)) {
            shouldSwitch = true;
            break;
          }
        }
        if (shouldSwitch) {
          rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
          switching = true;
        }
      }
      table.setAttribute('data-sort-dir', dir);
    }
  </script>
</head>
<body>
  <h1>Network Scan Report</h1>
  <div class="meta"><b>Generated:</b> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>
  <div class="meta"><b>Online:</b> $online</div>
  <div class="meta"><b>Offline:</b> $offline</div>
  <br />
  <table id="scanTable" data-sort-dir="asc">
    <tr>
      <th onclick="sortTable(0)">IP</th>
      <th onclick="sortTable(1)">Status</th>
      <th onclick="sortTable(2)">Hostname</th>
      <th onclick="sortTable(3)">Latency (ms)</th>
      <th onclick="sortTable(4)">MAC</th>
      <th onclick="sortTable(5)">Open Ports</th>
    </tr>
    $($rows -join "`n")
  </table>
</body>
</html>
"@

    $html | Set-Content -Path $Path -Encoding UTF8
    Write-Host "HTML report saved: $Path" -ForegroundColor Green
}

Export-ModuleMember -Function Export-NetworkScan