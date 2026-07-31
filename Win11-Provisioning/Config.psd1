@{
    SystemCleanup = @{
        RemovePhoneLink = $false
    }

    Privacy = @{
        DisableLocation = $false
    }

    Windows11Cleanup = @{
        DisableRecallIfAvailable = $true
    }

    Explorer = @{
        SeparateProcess = $false
    }

    Taskbar = @{
        SearchMode = 'Hidden' # Hidden | Icon | Box
    }

    StartMenu = @{}

    Appearance = @{
        SmallTaskbarIconsIfSupported = $true
    }

    Locale = @{
        Language = 'da-DK'
        Keyboard = 'da-DK'
        Region = 'DK'
        TimeZone = 'Romance Standard Time'
        Use24HourClock = $true
    }

    OneDrive = @{
        Uninstall = $true
        DisableAutoStartOnly = $false
    }

    Networking = @{}

    Power = @{
        DeviceType = 'Desktop' # Desktop | Laptop
        DisableFastStartup = $false
    }

    Winget = @{
        Packages = @(
            '7zip.7zip',
            'Google.Chrome',
            'Mozilla.Firefox',
            'VideoLAN.VLC',
            'Notepad++.Notepad++',
            'Git.Git',
            'Microsoft.PowerShell',
            'Microsoft.VisualStudioCode',
            'JanDeDobbeleer.OhMyPosh',
            'Docker.DockerDesktop',
            'GitHub.cli',
            'Microsoft.Sysinternals',
            'WinDirStat.WinDirStat'
        )
    }

    WindowsUpdate = @{
        RunWindowsUpdate = $true
        UpdateMicrosoftStoreApps = $true
        UpgradeWingetPackages = $true
    }

    QualityOfLife = @{
        DisableMouseAcceleration = $false
    }

    OptionalFeatures = @{
        Enabled = $false
        RemovePrintToPDF = $false
    }

    Cleanup = @{}
}
