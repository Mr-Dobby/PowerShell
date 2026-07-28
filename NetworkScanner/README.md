# NetworkScanner

PowerShell network scanner with CIDR/range support, optional DNS/MAC lookup, optional port scanning, progress display, colorized output, and multi-format report exports.

## Features

- Scan by CIDR or subnet range
- Adjustable timeout and thread count
- DNS hostname lookup (`-ResolveDNS`)
- MAC lookup (`-ShowMac`)
- Optional offline host output (`-ShowOffline`)
- Optional TCP port scan (`-ScanPorts -Ports ...`)
- Progress bar and colorized terminal output
- Timestamped TXT / CSV / JSON / HTML reports
- PowerShell 7 parallel scanning, 5.1-compatible fallback

## Structure

```
NetworkScanner/
├── NetworkScanner.ps1
├── NetworkScanner.psm1
├── NetworkScanner.psd1
├── Modules/
│   ├── Scanner.psm1
│   ├── Export.psm1
│   ├── CIDR.psm1
│   ├── Utilities.psm1
│   ├── Logger.psm1
│   └── MacLookup.psm1
└── Reports/
```

## Usage

From inside the `NetworkScanner` folder:

- Scan CIDR:
	- `./NetworkScanner.ps1 -CIDR 192.168.1.0/24`

- Scan subnet range:
	- `./NetworkScanner.ps1 -Subnet 192.168.1 -Start 100 -End 150`

- Use more threads (PowerShell 7+):
	- `./NetworkScanner.ps1 -CIDR 192.168.0.0/24 -Threads 100`

- Include offline devices:
	- `./NetworkScanner.ps1 -CIDR 192.168.1.0/24 -ShowOffline`

- Enable DNS/MAC lookups:
	- `./NetworkScanner.ps1 -CIDR 192.168.1.0/24 -ResolveDNS -ShowMac`

- Scan common ports:
	- `./NetworkScanner.ps1 -CIDR 192.168.1.0/24 -ScanPorts -Ports 22,80,443,3389`

- Export all report types:
	- `./NetworkScanner.ps1 -CIDR 10.0.0.0/24 -SaveTxt -SaveCsv -SaveJson -SaveHtml`

## Notes

- On PowerShell 7+, scanning runs in parallel and respects `-Threads`.
- On Windows PowerShell 5.1, scanning runs sequentially for compatibility.
- Large CIDR blocks can take significant time and generate many results.
