# Source: https://github.com/edbarnes-msft/DrDAV/blob/master/Test_MsDavConnection.ps1
<# Script name: tss_MSDavConnection.ps1
Purpose: - check WebDAV/WebClient related settings and connectivity
#>

param(
	[Parameter(Mandatory=$False,Position=0,HelpMessage='Choose a writable output folder location, i.e. C:\Temp\ ')]
	[string]$DataPath = (Split-Path $MyInvocation.MyCommand.Path -Parent)
)

$ScriptVer="2020.07.06"

$deftesturl =  'https://www.myserver.com'

[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
[uri] $testurl = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the http target web folder", "Web Address", $deftesturl)

$logpath = $DataPath
#_#$logpath = $env:TEMP+"\_DavTest"
#_#New-Item -ItemType Directory -Force -Path $logpath > $null
#_#$logfile = $logpath +"\"+$env:COMPUTERNAME+"_"+(Get-Date -Format yyddMMhhmm)+".log"
#$logfile = [Microsoft.VisualBasic.Interaction]::InputBox("Specify the logging file", "Log File", $logfile)
$logfile = $logpath +"\_DavTest_"+$env:COMPUTERNAME+"_"+(Get-Date -Format yyddMMhhmm)+"_v"+$ScriptVer+".txt"

$outputverbose = $false

$WebClientTestSrc = @'
    [DllImport("ieframe.dll", CharSet = CharSet.Auto)]
    static extern int IEIsProtectedModeURL(string pszUrl);   
    public static int GetProtectedMode(string url)
    {
        return IEIsProtectedModeURL(url);
    }
    [DllImport("C:\\Windows\\System32\\wininet.dll", CharSet=CharSet.Auto, SetLastError=true)]
    static extern bool InternetSetCookie(string lpszUrl, string lpszCookieName, string lpszCookieData);
    public static bool SetCookieString(string url, string name, string value)
    {
        if (!InternetSetCookie(url, name, value)) { Console.Write( "Failed to set cookie. Error code: {0}. ", Marshal.GetLastWin32Error()); return false; }
        return true;
    }

    [DllImport("C:\\Windows\\System32\\wininet.dll", CharSet=CharSet.Auto, SetLastError=true)]
    static extern bool InternetGetCookieEx(string pchURL, string pchCookieName, System.Text.StringBuilder pchCookieData, ref System.UInt32 pcchCookieData, int dwFlags, IntPtr lpReserved);
    const int ERROR_NO_MORE_ITEMS = 259;
    const int flags = 0x00003000; // INTERNET_COOKIE_NON_SCRIPT  0x00001000, INTERNET_COOKIE_HTTPONLY 0x00002000
    public static string GetCookieString(string url)
    {
        // Determine the size of the cookie      
        UInt32 datasize = 256*1024; int iResult = 0; 
        System.Text.StringBuilder cookieData = new System.Text.StringBuilder(Convert.ToInt32(datasize));
        if (!InternetGetCookieEx(url, null, cookieData, ref datasize, flags, IntPtr.Zero)) {
            iResult = Marshal.GetLastWin32Error(); // Console.Write( "The request returned error {0}. ", iResult);
            if ((ERROR_NO_MORE_ITEMS == iResult) | (datasize < 0)) return null; // Console.Write( "Datasize {0}. ", datasize);
            // Allocate stringbuilder large enough to hold the cookie    
            cookieData = new System.Text.StringBuilder(Convert.ToInt32(datasize));
            if (!InternetGetCookieEx(url, null, cookieData, ref datasize, flags, IntPtr.Zero)) { Console.Write( "GetCookie request returned error {0}. ", iResult);return null;}
        }
        return cookieData.ToString();
    }

// referencing values from https://github.com/libgit2/libgit2/blob/master/deps/winhttp/winhttp.h
    [DllImport("winhttp.dll", SetLastError=true, CharSet=CharSet.Auto)]
    static extern IntPtr WinHttpOpen( [MarshalAs(UnmanagedType.LPWStr)] string pwszAgent, int   dwAccessType,
            [MarshalAs(UnmanagedType.LPWStr)] string pwszProxy, [MarshalAs(UnmanagedType.LPWStr)] string pwszProxyBypass, int dwFlags );

    [DllImport("winhttp.dll", SetLastError=true, CharSet=CharSet.Auto)]
    static extern IntPtr WinHttpOpenRequest( IntPtr hConnect, [MarshalAs(UnmanagedType.LPWStr)] string pwszVerb, [MarshalAs(UnmanagedType.LPWStr)] string pwszObjectName,
            [MarshalAs(UnmanagedType.LPWStr)] string pwszVersion, [MarshalAs(UnmanagedType.LPWStr)] string pwszReferrer, ref byte[] ppwszAcceptTypes, int dwFlags);

    [DllImport("winhttp.dll", SetLastError=true, CharSet=CharSet.Auto)]
    static extern IntPtr WinHttpConnect(IntPtr hSession, [MarshalAs(UnmanagedType.LPWStr)] string pswzServerName, short nServerPort, int dwReserved);

    [DllImport("winhttp.dll", SetLastError=true, CharSet=CharSet.Auto)]
    static extern bool WinHttpSetOption( IntPtr hInternet, int dwOption, byte[] lpBuffer, int dwBufferLength );

    [DllImport("winhttp.dll", SetLastError=true, CharSet=CharSet.Auto)]
    static extern bool WinHttpSendRequest( IntPtr hRequest, string pwszHeaders, int dwHeadersLength, string lpOptional, uint dwOptionalLength, uint dwTotalLength, int dwContext );

    [DllImport("winhttp.dll", SetLastError=true)]
    static extern bool WinHttpReceiveResponse(IntPtr hRequest, int lpReserved);

    [DllImport("winhttp.dll", SetLastError=true)]
    static extern bool WinHttpCloseHandle(IntPtr hInternet);

    static int WINHTTP_FLAG_SECURE = 0x00800000;
    static int WINHTTP_OPTION_SECURE_PROTOCOLS = 84;
    public static int WINHTTP_FLAG_SECURE_PROTOCOL_SSL3 = 0x00000020;    // decimal 32
    public static int WINHTTP_FLAG_SECURE_PROTOCOL_TLS1 = 0x00000080;    // decimal 128
    public static int WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_1 = 0x00000200;  // decimal 512
    public static int WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_2 = 0x00000800;  // decimal 2048

    static int WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0;
    //static int WINHTTP_ACCESS_TYPE_NO_PROXY = 1;
    //static int WINHTTP_ACCESS_TYPE_NAMED_PROXY = 3;

    static int WINHTTP_OPTION_SECURITY_FLAGS = 31;
    static int SECURITY_FLAG_IGNORE_UNKNOWN_CA = 0x00000100;
    static int SECURITY_FLAG_IGNORE_CERT_DATE_INVALID = 0x00002000;
    static int SECURITY_FLAG_IGNORE_CERT_CN_INVALID = 0x00001000;
    static int SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE = 0x00000200;
    static int SECURITY_FLAG_IGNORE_ALL = SECURITY_FLAG_IGNORE_UNKNOWN_CA|SECURITY_FLAG_IGNORE_CERT_DATE_INVALID|SECURITY_FLAG_IGNORE_CERT_CN_INVALID|SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE;

    static byte[] WINHTTP_DEFAULT_ACCEPT_TYPES = null;
    static string WINHTTP_NO_ADDITIONAL_HEADERS = null;
    static string WINHTTP_NO_REQUEST_DATA = null;
    static string WINHTTP_NO_REFERER = null;
    static string WINHTTP_NO_PROXY_NAME = null;
    static string WINHTTP_NO_PROXY_BYPASS = null;

    public static int TestSsl(string url, short port, int ssl, bool bIgnoreBadCert)
    {
        int iResult = 0;
        IntPtr hSession = WinHttpOpen("WinHTTP SSL Test", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
        if( hSession != null ) {
            IntPtr hConnect = WinHttpConnect( hSession, url, port, 0 );
            if( hConnect != null ) {
                IntPtr hRequest = WinHttpOpenRequest( hConnect, "GET", "/", null, WINHTTP_NO_REFERER, ref WINHTTP_DEFAULT_ACCEPT_TYPES, WINHTTP_FLAG_SECURE);
                if (!WinHttpSetOption( hSession, WINHTTP_OPTION_SECURE_PROTOCOLS, BitConverter.GetBytes(ssl), sizeof(int) )) Console.WriteLine( "Failed to set SSL");
                if ( bIgnoreBadCert ) {
                    if (!WinHttpSetOption( hRequest, WINHTTP_OPTION_SECURITY_FLAGS, BitConverter.GetBytes(SECURITY_FLAG_IGNORE_ALL), sizeof(int) )) Console.WriteLine( "Failed to set Ignore Bad Cert");
                    };
                if (!WinHttpSendRequest( hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0, WINHTTP_NO_REQUEST_DATA, 0, 0, 0 ) ){
                    iResult = Marshal.GetLastWin32Error();
                    Console.Write( "The request returned error {0}. ", iResult);
                    };
                if( hRequest != null ) WinHttpCloseHandle( hRequest );
                };
            if( hConnect != null ) WinHttpCloseHandle( hConnect );
            if( hSession != null ) WinHttpCloseHandle( hSession );
        };
        return iResult;
    }
'@ 

Add-Type -MemberDefinition $WebClientTestSrc  -Namespace WebClientTest -Name WinAPI 

[System.Management.Automation.PSCredential] $altcreds = $null
$auth_ntlm = $false; $auth_nego = $false; $auth_basic =$false; $auth_oauth = $false; $auth_fba = $false
$dblbar = "======================================================"
$wcshellminver7 = "6.1.7601.22498"; $wcminver7 = "6.1.7601.23542"; $winhttpminver7 = "6.1.7601.23375"
$wcminver8GDR = "6.2.9200.17428"; $wcminver8LDR = "6.2.9200.21538"; $winhttpminver8 = "6.2.9200.21797"
$wcminver81 = "6.3.9600.17923"; $wcrecver10 = "10.0.16299.334"
$newlocation = ""
$persistentcookies = ""
$propfindnodecount = 0

function Test-MsDavConnection {
    [CmdletBinding()] 
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true
            )][uri]$WebAddress 
        )
    begin {
        $ProgressPreference = 'SilentlyContinue'
        if ($PSVersionTable.PSVersion.Major -eq 2){ $osverstring = [environment]::OSVersion.Version.ToString() } 
        else { $osverstring = $(Get-CimInstance Win32_OperatingSystem).Version }
        $osver = [int] ([convert]::ToInt32($osverstring.Split('.')[0], 10) + [convert]::ToInt32($osverstring.Split('.')[1], 10))
        $osname = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
        if ($osver -eq 10) { $osname = $osname + " " + (Get-ComputerInfo).WindowsVersion }
        $defaultNPO = ('RDPNP,LanmanWorkstation,webclient')
        $WCfilesize = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WebClient\Parameters").FileSizeLimitInBytes 
        $WCattribsize = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WebClient\Parameters").FileAttributesLimitInBytes 
        $WCtimeout = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WebClient\Parameters").SendReceiveTimeoutInSec  
        $npo = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order").ProviderOrder
        $hnpo = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\NetworkProvider\HwOrder").ProviderOrder
        $WCBasicauth = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WebClient\Parameters").BasicAuthLevel
        $WCAFSL = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WebClient\Parameters").AuthForwardServerList
        if ($WCAFSL.length -eq 0 ) {$WCAFSLOut = "Not configured or empty" } else { $WCAFSLOut = $WCAFSL } 
        $sslprotocols=[string]::Join(" ",([enum]::GetNames([System.Security.Authentication.SslProtocols])|Where-Object{$_ -notmatch 'none|default|ssl2'} ) ) #ssl3|tls|tls11|tls12(|tls13)
        $IgnoreBadCert = $true
        $WCuseragent = "Microsoft-WebDAV-MiniRedir/" + $osverstring
        $fso = New-Object -comobject Scripting.FileSystemObject
        $Webclntdll = $fso.GetFileVersion('C:\Windows\System32\webclnt.dll')
        $Davclntdll = $fso.GetFileVersion('C:\Windows\System32\davclnt.dll')
        $Mrxdavsys = $fso.GetFileVersion('C:\Windows\System32\drivers\mrxdav.sys')
        $Shell32dll = $fso.GetFileVersion('C:\Windows\System32\shell32.dll')
        $WinHttpdll = $fso.GetFileVersion('C:\Windows\System32\winhttp.dll')
        $WebIOdll =  $fso.GetFileVersion('C:\Windows\System32\webio.dll')
        $ProgressPreference = 'Continue'
    }

    process {
        $MsDavConnection = @{
            ClientName=[environment]::MachineName
            ClientOS = $osname
            ClientOSVersion = $osverstring
            ClientWebIO=$WebIOdll
            ClientWinHttp=$WinHttpdll
            ClientShell32=$Shell32dll
            ClientWebclnt=$Webclntdll
            ClientDavclnt=$Davclntdll
            ClientMrxdav=$Mrxdavsys
            ClientNetProviders=$npo
            ServerName=$WebAddress.DnsSafeHost
            ServerPort=$WebAddress.Port
            ServerScheme=$WebAddress.Scheme
            TargetUrl=$WebAddress
            AuthForwardServerList = $WCAFSLOut
            BasicAuthLevel=$WCBasicauth
            FileSizeLimitInBytes = $WCfilesize.ToString("N0")
            FileAttributesLimitInBytes = $WCattribsize.ToString("N0")
            SendReceiveTimeoutInSec = $WCtimeout.ToString("N0")
            Currentuser=$([environment]::UserDomainName + "\" + [environment]::UserName)
            }    

            
            foreach ($i in $MsDavConnection.GetEnumerator()) { Write-ToLogVerbose $($i.Key + " : " + $i.Value).ToString() }
            Write-Host "Microsoft WebClient Service Diagnostic check" -ForegroundColor Yellow -BackgroundColor DarkBlue
            Write-Host ("Client Name =         " + [environment]::MachineName)
            Write-Host ("OS =                  " + $osname)
            Write-Host ("OS version =          " + $osverstring )
            Write-Host "Webclnt.dll version ="$Webclntdll
            Write-Host "Davclnt.dll version ="$Davclntdll
            Write-Host "Mrxdav.sys version = "$Mrxdavsys
            Write-Host "Shell32.dll version ="$Shell32dll
            Write-Host "WinHttp.dll version ="$WinHttpdll
            Write-Host "WebIO.dll version =  "$WebIOdll

            Write-Host
            if ($WebAddress.Host.Length -gt 0) {
                Write-Host "TargetUrl ="$WebAddress
                Write-Host "ServerName ="$WebAddress.DnsSafeHost
                Write-Host "ServerPort ="$WebAddress.Port
                Write-Host "ServerScheme ="$WebAddress.Scheme
                Write-Host
            }
            Write-Host "Network Provider Order =`n`t"$npo
            Write-Host "`nWebClient Parameters:`n`tBasicAuthLevel ="$WCBasicauth
            Write-Host "`tAuthForwardServerList ="$WCAFSL
 

            Write-ToLog ("`n" + $dblbar + "`n")
            

# Fail to Connect
#    1.	WebClient not installed or disabled
        $WCSvc = Get-Service | Where-Object { $_.Name -eq 'webclient' }
        if ($null -ne $WCSvc) 
            { 
                $WCStartNum = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\WebClient").Start 
                switch ($WCStartNum) {
                "2"  { $WCStartType = "Automatic" }
                "3"  { $WCStartType = "Manual" }
                "4"  { $WCStartType = "Disabled" }
                }
                Write-ToLog ("The WebClient service StartUp type is: " + $WCStartType)
                if ( ($WCStartType -ne "Manual" ) -and
                    ($WCStartType -ne "Automatic" ) )
                    { Write-ToLogWarning "WebClient service Start Type should be set to Manual or Automatic." }
                Write-ToLog "Manual is default but Automatic is preferred if the service is used frequently"
            } 
            else
            {
                Write-ToLogWarning "WebClient service is not present"
            }
# File version check
        if ( ($WebAddress.Scheme -eq "https") -and (($osver -eq 7) -or ($osver -eq 8)) ){ # https://support.microsoft.com/en-us/help/3140245
            if ($osver -eq 7) { 
                if ( !((Check-Version $WinHttpdll $winhttpminver7 ) -and (Check-Version $WinHttpdll $winhttpminver7 )) ){ 
                    Write-ToLogWarning ("WinHttp.Dll and WebIO.Dll should be updated to allow highest Secure Protocol versions - https://support.microsoft.com/en-us/help/3140245") 
                    }
                if ( !(Check-Version $Shell32dll $wcshellminver7 ) ){ Write-ToLogWarning ("Shell32.dll should be updated to address a known issue") }
                if ( !((Check-Version $Webclntdll $wcminver7 ) -and (Check-Version $Davclntdll $wcminver7 ) -and (Check-Version $Mrxdavsys $wcminver7 )) ){ 
                    Write-ToLogWarning ("The WebClient files should be updated to allow highest Secure Protocol versions") 
                    }
                }
            if ($osver -eq 8) { 
                if ( !((Check-Version $WinHttpdll $winhttpminver8 ) -and (Check-Version $WinHttpdll $winhttpminver8 )) ){ 
                    Write-ToLogWarning ("WinHttp.Dll and WebIO.Dll should be updated to allow highest Secure Protocol versions - https://support.microsoft.com/en-us/help/3140245") 
                    }
                if ( [convert]::ToInt32($Webclntdll.Split('.')[0], 10) -lt 20000 ) {
                    if ( !((Check-Version $Webclntdll $wcminver8GDR ) -and (Check-Version $Davclntdll $wcminver8GDR )) ){ 
                        Write-ToLogWarning ("The WebClient files should be updated to allow highest Secure Protocol versions") 
                        }
                    } 
                    else {
                        if ( !((Check-Version $Webclntdll $wcminver8LDR ) -and (Check-Version $Davclntdll $wcminver8LDR )) ){ 
                            Write-ToLogWarning ("The WebClient files should be updated to allow highest Secure Protocol versions") 
                        }
                    }
                }
            if ($osver -eq 9) { 
                if ( !((Check-Version $Webclntdll $wcminver81 ) -and (Check-Version $Davclntdll $wcminver81 )) ){ 
                            Write-ToLogWarning ("The WebClient files should be updated to allow highest Secure Protocol versions") 
                    }
                }
    
            }

        if (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | Select-Object -ExpandProperty DefaultSecureProtocols -ErrorAction SilentlyContinue | Out-Null){
            $dsp = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp").DefaultSecureProtocols 
            if ($osver -eq 10) {
                if ($null -ne $dsp ) {Write-ToLogWarning "WinHttp registry entry is: " + $dsp.ToString('x2').ToUpper() }
            } else {
                if ($null -eq $dsp ) {Write-ToLogWarning "WinHttp registry entry is absent" } else { Write-ToLog ("WinHttp registry entry is: " + $dsp.ToString('x2').ToUpper() ) }
            }
        }
        if ([environment]::GetEnvironmentVariable("ProgramFiles(x86)").Length -gt 0){
            if (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp"){
                if (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" | Select-Object -ExpandProperty DefaultSecureProtocols -ErrorAction SilentlyContinue | Out-Null){
                    $dspwow = (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp").DefaultSecureProtocols
                }
            }
            if ($osver -eq 10) {
                if ($null -ne $dspwow ) {Write-ToLogWarning "WinHttp WOW6432 registry entry is: " + $dspwow.ToString('x2').ToUpper() }
            } else {
                if ($null -eq $dspwow ) {Write-ToLogWarning "WinHttp WOW6432 registry entry is absent" } else { Write-ToLog ("WinHttp WOW6432 registry entry is: " + $dspwow.ToString('x2').ToUpper() ) }
            }
        }  
        
                                   
        $strongcrypt = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319").SchUseStrongCrypto
        if ($null -eq $strongcrypt ) {Write-ToLogVerbose "SchUseStrongCrypto registry entry is absent" } else { Write-ToLogVerbose ("SchUseStrongCrypto registry entry for v4 is: " + $strongcrypt) }
        if ([environment]::GetEnvironmentVariable("ProgramFiles(x86)").Length -gt 0){
            $strongcryptwow = (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319").SchUseStrongCrypto
            if ($null -eq $strongcryptwow ) {Write-ToLogVerbose "SchUseStrongCrypto WOW6432 registry entry is absent" } else { Write-ToLogVerbose ("SchUseStrongCrypto WOW6432 registry entry for v4 is: " + $strongcryptwow) }
        }     
           
        $strongcrypt2 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727").SchUseStrongCrypto
        if ($null -eq $strongcrypt2 ) {Write-ToLogVerbose "SchUseStrongCrypto registry entry is absent" } else { Write-ToLogVerbose ("SchUseStrongCrypto registry entry for v2 is: " + $strongcrypt2) }
        if ([environment]::GetEnvironmentVariable("ProgramFiles(x86)").Length -gt 0){
            $strongcryptwow2 = (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727").SchUseStrongCrypto
            if ($null -eq $strongcryptwow2 ) {Write-ToLogVerbose "SchUseStrongCrypto WOW6432 registry entry is absent" } else { Write-ToLogVerbose ("SchUseStrongCrypto WOW6432 registry entry for v2 is: " + $strongcryptwow2) }
        }        
              
        $sysdeftlsver = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727").SystemDefaultTlsVersions
        if ($null -eq $sysdeftlsver ) {Write-ToLogVerbose "SystemDefaultTlsVersions registry entry is absent" } else { Write-ToLogVerbose ("SystemDefaultTlsVersions registry entry is: " + $sysdeftlsver) }
        if ([environment]::GetEnvironmentVariable("ProgramFiles(x86)").Length -gt 0){
            $sysdeftlsverwow = (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727").SystemDefaultTlsVersions
            if ($null -eq $sysdeftlsverwow ) {Write-ToLogVerbose "SystemDefaultTlsVersions WOW6432 registry entry is absent" } else { Write-ToLogVerbose ("SystemDefaultTlsVersions WOW6432 registry entry is: " + $sysdeftlsverwow) }
        }          

        Write-ToLog ("Client Secure Protocols enabled for .Net: " + $sslprotocols.ToUpper() ) 
      
#    2.	Bad Network Provider order
#       a.	WebClient missing from provider order
        $npomsg = "`r`nNetwork Provider Order check: "
        $npocheck = 'Good'
        if ($npo.ToLower() -ne $hnpo.ToLower()) { 
            $npocheck = 'HwOrder doesn''t match Order' 
            Write-ToLogWarning ($npocheck +"`r`n`tOrder: " + $npo + "`r`n`tHwOrder: " + $hnpo)
            }
        if ( !("," + $hnpo +",").ToLower().Contains(",webclient,") -or !("," + $npo +",").ToLower().Contains(",webclient,") ) {
            $npocheck = 'WebClient is missing from provider list' 
            Write-ToLogWarning ($npomsg + $npocheck + "`r`n`tOrder: " + $npo )
            }
#       b.	Third-party providers interfering
        if ( ($npocheck -eq "Good") -and ($npo.ToLower() -ne $defaultnpo.ToLower()) ) { 
            $npocheck = 'Order doesn''t match Default' 
            Write-ToLog ($npomsg + $npocheck + "`r`n`tOrder: " + $npo + "`r`n`tDefault order: $defaultnpo")
            }
        if ( $npocheck -eq "Good") { Write-ToLog ($npomsg + $npocheck) }


        if ($WebAddress.Host.Length -eq 0) {Start-Process ($env:windir + "\explorer.exe")  -ArgumentList $((Get-ChildItem $logfile).DirectoryName) ;Exit}
#==========================================================================
#    Only test below if WebAddress is passed

        $rootweb = $WebAddress.Scheme + "://" + $WebAddress.DnsSafeHost; $matchfound = $false
            
#    3.	Port blocked
        $starttime = Get-Date
        # New-Object System.Net.Sockets.TcpClient($WebAddress.DnsSafeHost,$WebAddress.Port)
        $ns = New-Object System.Net.Sockets.TcpClient
        try { $ns.Connect($WebAddress.DnsSafeHost, $WebAddress.Port ) } catch {}
        $rtt = (New-TimeSpan $starttime $(Get-Date) ).Milliseconds
        if( $ns.Connected) {$testconnection = $true; $ns.Close()}
        $davport = $davport + "Connection to " + $WebAddress.DnsSafeHost + " on port " + $WebAddress.Port + " was " 
        if ($testconnection -eq $true ) { $davport = $davport + "successful and took " + $rtt + " milliseconds" }
        else { $davport = $davport + "not successful"; $rtt=0}
        Write-ToLog $davport

# Internet Settings Security Zone information
# https://support.microsoft.com/en-us/help/182569/internet-explorer-security-zones-registry-entries-for-advanced-users
        $IEZone = [System.Security.Policy.Zone]::CreateFromUrl($WebAddress).SecurityZone
        $IEPMode = [WebClientTest.WinAPI]::GetProtectedMode($WebAddress)
        if ( $IEPMode -eq 0 ) {$ProtectMode = "Enabled"}
        elseif ( $IEPMode -eq 1 ) {$ProtectMode = "Not Enabled"}
        else {$ProtectMode = "Unknown"}

        Write-ToLog ("$WebAddress is in the $IEZone Security Zone and Protect Mode value is " + $ProtectMode + "`r`n")

        $internettestzone = "http://doesntexist.edbarnes.net"
        if([System.Security.Policy.Zone]::CreateFromUrl($internettestzone).SecurityZone -eq "Internet"){
            if ( [WebClientTest.WinAPI]::GetProtectedMode($internettestzone) -ne 0 ) {
            Write-ToLogWarning ("The Internet Security Zone is not enabled for Protect Mode. This is a security risk!`r`n") }
        }
        
        $ActiveXCheck = $(Get-Item -Path ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\" + $IEZone.value__)).GetValue('2000')
        if ( $ActiveXCheck -eq 0 ) {$ActiveXEnabled = "Enabled"}
        elseif ( $ActiveXCheck -eq 1 ) {$ActiveXEnabled = "Prompt"}
        elseif ( $ActiveXCheck -eq 3 ) {$ActiveXEnabled = "Disabled"}
        else {$ActiveXEnabled = "Unknown"}
        Write-ToLogVerbose ("Checking if ActiveX is enabled. Value identified: " + $ActiveXEnabled)

        if ((Test-Path ("HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\" + $IEZone.value__)) -eq $false){
            Write-ToLogVerbose ("No ActiveX Policy found`n")
            }
            else {
            $ActiveXPolicyCheck = $(Get-Item -Path ("HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\" + $IEZone.value__)).GetValue('2000')
            if ( $ActiveXPolicyCheck -eq 0 ) {$ActiveXPolicyEnabled = "Enabled"}
            elseif ( $ActiveXPolicyCheck -eq 1 ) {$ActiveXPolicyEnabled = "Prompt"}
            elseif ( $ActiveXPolicyCheck -eq 3 ) {$ActiveXPolicyEnabled = "Disabled"}
            else {$ActiveXPolicyCheck = "Unknown"}
            Write-ToLogVerbose ("Checking if ActiveX Policy is enabled. Value identified: " + $ActiveXPolicyEnabled +"`n")
            }
      
#    3.	Version of SSL/TLS not supported by destination server
        if ( ($testconnection -eq $true) -and ($WebAddress.Scheme -eq "https") ) {
            $ServerProtocolsAccepted = $null; [int] $iBestSsl = 0;
            if ([WebClientTest.WinAPI]::TestSsl($WebAddress.DnsSafeHost, $WebAddress.Port, 32, $IgnoreBadCert ) -eq 0 ) 
                { Write-ToLogVerbose "The server supports SSL3"; $ServerProtocolsAccepted = $ServerProtocolsAccepted + " SSL3" ; $iBestSsl = 32 ; $sBestSsl = "SSL3" } 
            else { Write-ToLog "The server does not support SSL3" }

            if ([WebClientTest.WinAPI]::TestSsl($WebAddress.DnsSafeHost, $WebAddress.Port, 128, $IgnoreBadCert ) -eq 0 ) 
                { Write-ToLogVerbose "The server supports TLS 1.0"; $ServerProtocolsAccepted = $ServerProtocolsAccepted + " TLS1" ; $iBestSsl = 128 ; $sBestSsl = "TLS1" } 
            else { Write-ToLog "The server does not support TLS 1.0" }

            if ([WebClientTest.WinAPI]::TestSsl($WebAddress.DnsSafeHost, $WebAddress.Port, 512, $IgnoreBadCert ) -eq 0 ) 
                { Write-ToLogVerbose "The server supports TLS 1.1"; $ServerProtocolsAccepted = $ServerProtocolsAccepted + " TLS11" ; $iBestSsl = 512 ; $sBestSsl = "TLS11" } 
            else { Write-ToLog "The server does not support TLS 1.1" }

            if ([WebClientTest.WinAPI]::TestSsl($WebAddress.DnsSafeHost, $WebAddress.Port, 2048, $IgnoreBadCert ) -eq 0 ) 
                { Write-ToLogVerbose "The server supports TLS 1.2"; $ServerProtocolsAccepted = $ServerProtocolsAccepted + " TLS12" ; $iBestSsl = 2048 ; $sBestSsl = "TLS12" } 
            else { Write-ToLog "The server does not support TLS 1.2" }

            if ($null -eq $ServerProtocolsAccepted) {Write-ToLog "No attempted protocols succeeded"}
            else {$ServerProtocolsAccepted = $ServerProtocolsAccepted.Substring(1); Write-ToLog ( "Server supports: " + $ServerProtocolsAccepted.ToUpper() ) }


#    4.	Certificate is expired or doesn't match
            $certcheck = [WebClientTest.WinAPI]::TestSsl($WebAddress.DnsSafeHost, $WebAddress.Port, $iBestSsl, $false )
            if ($certcheck -eq 0 ) 
                { Write-ToLogVerbose "No certificate problem observed"} 
            else { 
                switch ($certcheck ) {
                    "12037"  { Write-ToLog "Certificate Error Invalid Date" }
                    "12038"  { Write-ToLog "Certificate Error Invalid Common Name" }
                    "12044"  { Write-ToLog "Client Authentication Certificate Needed" }
                    "12045"  { Write-ToLog "Certificate CA is Invalid" }
                    "12169"  { Write-ToLog "Invalid Certificate" }      
                    "12179"  { Write-ToLog "Invalid Usage for Certificate" }  
                    default  { Write-ToLog "Certificate failure: $certcheck`r`n"}                 
                    }
                }
            Test-SslCert $WebAddress.DnsSafeHost $WebAddress.Port $sBestSsl
            # Optional ToDo - Check cert chain
            }


#    5.	Bad proxy settings
            Write-ToLogVerbose "TODO: Check proxy config"
#        a.	Proxy misdirection
#        b.	Proxy authentication require
#        [net.httpwebRequest]::GetSystemWebProxy
#
# Failure after connect
#    1.	Failing Authentication
        if ( $testconnection ) {
            Write-ToLog ("`n`n" + $dblbar + "`r`n** Determining authentication mode **")
            $global:newlocation = $WebAddress
            $verb = "HEAD"
            $followredirect = $false
            $addcookies = $false
            $credtype = "Anonymous" # 3 choices = "Anonymous", "DefaultCreds", "AlternateCreds"
            $maxtry = 5
            do {
                $responseresult = SendWebRequest -url $global:newlocation -verb $verb -useragent $WCuseragent -includecookies $addcookies -follow302 $followredirect  -usecreds $credtype
                Write-ToLogVerbose ("Result: $responseresult `r`n")
                switch ($responseresult ) {
                    "SwitchToGET" { $verb = "GET" }
                    "AddCookies"  { $addcookies = $true }
                    "AddFollow302"{ $followredirect = $true }            
                    "AddDefCreds" { $credtype = "DefaultCreds" }
                    "AddAltCreds" { $credtype = "AlternateCreds" }
                    "AuthBasic"   { $authbasic = $true }
                    "AuthWinNego" { $authnego = $true }
                    "AuthWinNTLM" { $authntlm = $true }
                    "AuthFBA"     { $addcookies = $true }
                }
                $maxtry = $maxtry - 1
            } while ( ( $responseresult -notlike "Complete*"  ) -and ($maxtry -gt 0 ) )

            }

#        a.	NTLM or Kerberos - AuthForwardServerList
            if (($global:auth_ntlm -or $global:auth_nego) -and ($rootweb.Contains("."))) { 
            Write-ToLog ("`n`n" + $dblbar + "`r`nWindows Authentication accepted with FQDN url : Testing AuthForwardServerList")
                # Validate target url against AuthForwardServerList
                if ($WCAFSL.length -eq 0 ) {Write-ToLogWarning ("AuthForwardServerList registry value is not configured or empty") }
                    else { 
                        $WCAFSL | ForEach-Object -Process {
                                     if ( $rootweb -like $_ ) {
                                        $matchfound = $true
                                        Write-ToLog ("The path $rootweb was matched to " + $_ )
                                        }
                                     }
                        if ( $matchfound -eq $false ) { Write-ToLogWarning ("The path $rootweb was not matched in AuthForwardServerList.") }
                }
                Write-ToLog ($dblbar + "`r`n`n")
            }
#        b.	Basic - not over SSL
            if ($global:auth_basic) { 
                Write-ToLog ("`n`n" + $dblbar + "`r`nBasic Authentication accepted : Testing BasicAuthLevel`r`n")                
                switch ($WCBasicauth) {
                "0"  {Write-ToLogWarning ("BasicAuthLevel is 0; use of Basic Authentication is disabled" ) }
                "1"  {
                        if ($WebAddress.Scheme -eq "http") {
                            Write-ToLogWarning ("BasicAuthLevel is 1; use of Basic Authentication over HTTP is disabled" ) }
                            else { Write-ToLog ("BasicAuthLevel is 1; use of Basic Authentication over HTTPS is enabled" ) }
                        }
                "2"  {Write-ToLogWarning ("BasicAuthLevel is 2; use of Basic Authentication is enabled for both HTTP and HTTPS - This could be a security risk" ) }
                }
                Write-ToLog ("Note: If Basic Authentication is allowed and used, there will always be a credential prompt`r`n" + $dblbar + "`r`n") 
            }

#        c.	Claims/FBA - No persistent cookie passed
            if ($global:auth_fba) { 
                Write-ToLog ("`n`n" + $dblbar + "`r`nFBA or SAML Claims Authentication accepted : Testing Persistent cookies`r`n") 
                Write-ToLog ("This authentication mode requires a persistent, sharable authentication cookie be available") 
#            i.	Cookie not created persistent
#            ii.	Cookie not stored in shareable location
                if ( $IEPMode -eq 0 ) {Write-ToLogWarning ("Protect Mode is enabled for the $IEZone Security Zone so Persistent cookies cannot be shared.")}
                elseif ( $IEPMode -eq 1 )  {Write-ToLog ("Protect Mode is not enabled for the $IEZone Security Zone so Persistent cookies can be shared.")}
                $global:persistentcookies = [WebClientTest.WinAPI]::GetCookieString($WebAddress) 
                if ($global:persistentcookies.length ) {
                    Write-ToLog ("`r`nPersistent Cookies:`n===================")
                    $global:persistentcookies.split("; ") | ForEach-Object{ 
                         $cookie = $_
                         #if ($cookie.Length -gt 7){ if ($cookie.Substring(0,7) -eq "FedAuth") {$fedauth = $cookie.Substring(8)}  }
                         Write-ToLog "`t$cookie"
                    }
                } else { Write-ToLog "`tNo persistent cookies found" }
                Write-ToLog ( $dblbar + "`r`n")
            }

#    2.	OPTIONS and/or PROPFIND verb blocked
        if ( $testconnection ) {
            Write-ToLog ("`n`n" + $dblbar + "`r`n** Check if OPTIONS or PROPFIND are blocked **")
            $verb = "OPTIONS"
            $responseresult = SendWebRequest -url $WebAddress -verb $verb -useragent $WCuseragent -includecookies $addcookies -follow302 $followredirect  -usecreds $credtype
            $verb = "PROPFIND"
            $responseresult = SendWebRequest -url $WebAddress -verb $verb -useragent $WCuseragent -includecookies $addcookies -follow302 $followredirect  -usecreds $credtype
#    3.	PROPFIND returns bad results
#        a.	XML missing
#        b.	XML malformed/gzipped
#        Checked on every PROPFIND response    
#    4.	Custom header name with space 
#        Checked each time headers are read  
#    5.	Root site access
#        a.	No DAV at root
#        b.	No permissions at root
#        c.	Root site missing 
            if ($rootweb -ne $WebAddress ){
                Write-ToLog ("`n`r`n" + $dblbar + "`r`n** Checking root site access **")
                $verb = "PROPFIND"
                $responseresult = SendWebRequest -url $rootweb -verb $verb -useragent $WCuseragent -includecookies $addcookies -follow302 $followredirect  -usecreds $credtype
            }
        }


#
# Performance
            Write-ToLog ("`r`n" + $dblbar + "`r`n** Performance considerations **")
#    1.	Slow to browse
            $verb = "PROPFIND"
            $responseresult = SendWebRequest -url $WebAddress -verb $verb -useragent $WCuseragent -includecookies $addcookies -follow302 $followredirect -usecreds $credtype -depth 1
            Write-ToLog "Check browsing performance scenarios (by testing number of discovered items)"

#        a.	Read-Only Win32 attribute on SharePoint folders can cause unnecessary PROPFIND on contents.
#        b.	Too many items in the destination folder will result in slow response in Windows Explorer (may appear empty)
            Write-ToLog "`tNumber of items queried: $global:propfindnodecount `r`n"
            if ($global:propfindnodecount -gt 1000) {
                Write-ToLogWarning ("`tA high number of items in the folder have been detected")
                if (($global:propfindnodecount*1000) -gt $WCattribsize){Write-ToLogWarning ("`tIncrease the FileAttributesLimitInBytes value. See KB 912152")}
            Write-ToLog ("Current setting of FileAttributesLimitInBytes is: " + $WCattribsize.ToString("N0") + " bytes`r`n")
            }

#    2.	Uploads fail to complete or are very slow
#        a.	PUT requests are blocked
            # TODO Test PUT
#        b.	File exceeds file size limit
            Write-ToLog ("Current setting of FileSizeLimitInBytes is: " + $WCfilesize.ToString("N0") + " bytes")
#        c.	Upload takes longer than the Timeout setting
            Write-ToLog ("`tUpload throughput is limited to approximately (Filesize / 8kb * RTT)" )
            if ($rtt -gt 0 ) {
                Write-ToLog ("`tCurrent Round Trip Time estimate is: " + $rtt + " milliseconds")
                $WCesttimeupload = ($WCfilesize / 8192 * $rtt)
                Write-ToLog ("`tEstimated time needed to upload a max file size of " +  $WCfilesize.ToString("N0") + " bytes: " + ($WCesttimeupload/1000).ToString("N0") + " seconds" )
            }
            else { Write-ToLog "`tUnable to determine RTT. Consider using PsPing from SysInternals to find the RTT" }

            Write-ToLog ("The current client setting for SendReceiveTimeoutInSec is: " + $WCtimeout )
#        d.	Number of file causes total attribute to exceeds attribute size limit
#        	See 2b below

#    3.	Slow to connect
#        a.	The WebClient service was not already started
          if ($WCStartType -ne "Automatic") { Write-ToLog "For best performance, set the StartUp Type to 'Automatic'" }
#        b.	SMB attempts receive no response before falling through to WebClient
            Write-ToLog "`nTesting SMB and SMB2 connectivity - using UNC will try SMB before using WebDAV and can cause a delay if blocked improperly"

            # New-Object System.Net.Sockets.TcpClient($WebAddress.DnsSafeHost,$WebAddress.Port)
            $ns = New-Object system.net.sockets.tcpclient

			$starttime = Get-Date
            try { $ns.Connect($WebAddress.DnsSafeHost, 139 ) } catch {}
            $smbresponsetime = (New-TimeSpan $starttime $(Get-Date) ).Seconds
            $ns.Close()

            $smb = "`tSMB test connection took " + $smbresponsetime + " seconds"
			if ($smbresponsetime -gt 30) {Write-ToLogWarning ($smb) }
            else { Write-ToLog ($smb) }

            $ns2 = New-Object system.net.sockets.tcpclient
			$starttime2 = Get-Date
            try { $ns2.Connect($WebAddress.DnsSafeHost, 445 ) } catch {}
            $smb2responsetime = (New-TimeSpan $starttime2 $(Get-Date) ).Seconds
            $ns2.Close()

            $smb2 = "`tSMB2 test connection took " + $smb2responsetime + " seconds"
			if ($smb2responsetime -gt 30) {Write-ToLogWarning ($smb2) }
            else { Write-ToLog ($smb2) }


#        c.	Auto-detect proxy unnecessarily selected
            Write-ToLogVerbose "`nTODO: Auto-detect proxy`n"

#        return New-Object PsObject -Property $MsDavConnection
     }

}


function SendWebRequest([uri] $url, [string] $verb, [string] $useragent, $includecookies = $false, $follow302=$true, [SecureString] $usecreds, $depth=0)
{
    if ($depth){$depthnotice = " with Depth of 1"} else { $depthnotice = ""}
    Write-ToLog ($dblbar + "`r`n`r`n" + $verb + " test to $url" + $depthnotice)
    Write-ToLogVerbose ("`tUserAgent: " + $useragent + " Cookies:" + $includecookies + " Follow302:" + $follow302 + " CredType:" + $usecreds)

    [net.httpWebRequest] $req = [net.webRequest]::Create($url)

    $req.CookieContainer = New-Object System.Net.CookieContainer
    if ( $includecookies -eq $true ) {
        $gcresult = [WebClientTest.WinAPI]::GetCookieString($url); 
        if ($gcresult.Length ){ 
            $cookiesread = $gcresult.Split(";")
            $cookiesread | ForEach-Object { $req.CookieContainer.SetCookies($url,$_.Trim()) }
        }
    }

    switch ($usecreds) 
    { 
        "Anonymous" {$req.Credentials = $null }
        "DefaultCreds" {$req.UseDefaultCredentials = $true }
        "AlternateCreds" {
            if ($null -eq $global:altcreds){$global:altcreds = Get-Credential }

            $req.Credentials = $global:altcreds
            }
    }

	$req.AllowAutoRedirect = $follow302
	$req.Method = $verb
    if ( $useragent -ne $null ) {$req.UserAgent = $useragent}
    if ( $req.Method -eq "PROPFIND" ) { $req.Headers["Depth"] = $depth }

	#Get Response
	try {
		[net.httpWebResponse]$res = $req.GetResponse()
	}
	catch {
        if ( ($Error[0].Exception.InnerException).Status -eq 'ProtocolError' ) {
            [net.httpWebResponse]$res = $Error[0].Exception.InnerException.Response
        }
        else {
            $res = $null
            Write-ToLogWarning ( ($Error[0].Exception.InnerException).status)
        }
    }

    Write-ToLogVerbose ("Request Headers:")
    foreach ($h in $req.Headers) { Write-ToLogVerbose ("`t" + $h + ": " + $req.Headers.GetValues($h)) }

    if ($null -ne $res)
    {
        Write-ToLog ("`tResponse Status Code: " + $res.StatusCode.value__ + " " + $res.StatusCode)
        Write-ToLogVerbose ("`tResponse Cookies: " + $res.Cookies.Count)
        foreach ($c in $res.Cookies) { Write-ToLogVerbose ("`t`t" + $c.Name + " " + $c.Value) }

        Write-ToLogVerbose ("`tResponse Headers: " + $res.Headers.Count)
        foreach ($h in $res.Headers)
        {
            
            switch -Wildcard($h){
                "WWW-Authenticate" { 
                    Write-ToLogVerbose ("`t`t" + $h )
                    foreach ($a in $res.Headers.GetValues($h)) {
                        Write-ToLogVerbose "`t`t`t"$a
                        if ($a -like "NTLM*") { $global:auth_ntlm = $true }
                        if ($a -like "Nego*") { $global:auth_nego = $true }
                        if ($a -like "Basic*") { $global:auth_basic = $true }
                        # WWW-Authenticate: IDCRL Type="BPOSIDCRL", EndPoint="/sites/Classic/_vti_bin/idcrl.svc/", RootDomain="sharepoint.com", Policy="MBI"
                        if ($a -like "IDCRL*") { $global:auth_oauth = $true }
                        }
                    Break
                    }
                "MicrosoftSharePointTeamServices" { Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                "Set-Cookie" { 
                    Write-ToLogVerbose ("`t`t" + $h)
                    foreach ($c in $res.Headers.GetValues($h)) {
                        Write-ToLogVerbose ("`t`t`t" + $c)
                        }
                    Break
                    }
                "Allow" { Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                "Date" { Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                "Location" { $newlocation = $res.Headers.GetValues($h) ;Write-ToLogVerbose ("`t`t" + $h + ":`t" + $newlocation) ; Break }
                "Content-Type" { Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                "Content-Encoding" { Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                "request-id" { Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                # X-MSDAVEXT_Error: 917656; Access+denied.+Before+opening+files+in+this+location%2c+you+must+first+browse+to+the+web+site+and+select+the+option+to+login+automatically.
                "X-MSDAVEXT_Error" { 
                    $global:auth_fba = $true ; 
                    if ($includecookies){
                        Write-ToLogWarning ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h))
                    }
                        Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h))
                    Break 
                    }
                "X-FORMS_BASED_AUTH_REQUIRED" { $global:auth_fba = $true ; Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                "FORMS_BASED_AUTH_RETURN_URL" { $global:auth_fba = $true ; Write-ToLogVerbose ("`t`t" + $h + ":`t" + $res.Headers.GetValues($h)) ; Break }
                "*" { Write-ToLogVerbose ("`t`t? " + $h + ": " + $res.Headers.GetValues($h))}
            }
        }
        $statcode = $res.StatusCode.value__ 
        if ( ($verb -eq "PROPFIND") -and (($statcode -eq 200) -or ($statcode -eq 207) ) ) { ReturnBody($res) }

        $res.Close()
    } 

    #Set StatusCheck
    $statuscheck = $null
    if ($statcode -eq 404 ) {
        if ($verb = "HEAD") {$statuscheck = "SwitchToGET" }
        else {$statuscheck = "Complete-404" }
    }
    elseif ($statcode -eq 403 ) {
        if ($includecookies -eq $false ) {$statuscheck = "AddCookies" }
        else {$statuscheck = "Complete-403" }
    }
    elseif ($statcode -eq 401 ) {
        if ($usecreds -eq "Anonymous") {$statuscheck = "AddDefCreds" }
        elseif ($usecreds -eq "DefaultCreds") {$statuscheck = "AddAltCreds" }
        else {$statuscheck = "Complete-401" }
    }
    elseif ($statcode -eq 302 ) { 
        if ($follow302 -eq $false ) {$statuscheck = "AddFollow302" ; Write-ToLog ("Redirected to $newlocation")}
        else {$statuscheck = "Complete-302" }
    }
    elseif ($statcode -eq 200 ) {$statuscheck = "Complete-200" }
    elseif ($statcode -eq 207 ) {$statuscheck = "Complete-207" }
    else {$statuscheck = $("Complete-Unexpected-" + $statcode) }

    return $statuscheck
}


function ReturnBody($response)
{
  if ($response.ContentLength -ge 0) {
        $responsestream = $response.getResponseStream() 
        $streamreader = New-Object IO.StreamReader($responsestream) 
        $body = $streamreader.ReadToEnd() 
        Add-Content $($logpath + "\Response_" + (Get-Date -Format hhmmss) + ".txt")  -Value $body
    }
    # Test if body is valid XML

    # Check for Load or Parse errors when loading the XML file
    $xml = New-Object System.Xml.XmlDocument
    try {
        $xml.LoadXml($body)
        Write-ToLog "`tPROPFIND response is valid XML"
        $nodecnt = $xml.ChildNodes.response.Count - 1
        if ($nodecnt -gt $global:propfindnodecount){
            $global:propfindnodecount = $nodecnt
            Write-ToLogVerbose "`tNumber of items: $nodecnt"
        }
    }
    catch [System.Xml.XmlException] {
        Write-ToLogWarning "PROPFIND response is not valid XML: $($_.toString())"
    }

}

function Check-Version($tval, $bval)
{  $t = $tval.Split("."); $b = $bval.Split(".")
    if ($t[0] -ge $b[0]){
        if ($t[1] -ge $b[1]){
            if ($t[2] -ge $b[2]){
                if ($t[3] -ge $b[3]){ return $true }
            }
        }
    }
    return $false
}

function Test-SslCert {
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromPipeline=$true
        )]$destHostName,
        [Parameter(
            ValueFromPipelineByPropertyName=$true
        )][int]$destPort,
        [ValidateSet("SSL3", "TLS", "TLS11", "TLS12", IgnoreCase = $true)]
        [Parameter(
            ValueFromPipelineByPropertyName=$true
        )]$destProtocol 
    )

    $Callback = { param($sender, $cert, $chain, $errors) return $true }
    $Socket = New-Object System.Net.Sockets.Socket('Internetwork','Stream', 'Tcp')
    $Socket.Connect($destHostName, $destPort)
    try {
        $NetStream = New-Object System.Net.Sockets.NetworkStream($Socket, $true)
        $SslStream = New-Object System.Net.Security.SslStream($NetStream, $true, $Callback)
        $SslStream.AuthenticateAsClient($destHostName,  $null, $destProtocol, $false )
        $RemoteCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]$SslStream.RemoteCertificate
        Write-ToLog  ('Cert info - Host name(s): ' + $RemoteCertificate.DnsNameList)
        Write-ToLog  ('Cert info - Not Before: ' + $RemoteCertificate.NotBefore )
        Write-ToLog  ('Cert info - Not After: ' + $RemoteCertificate.NotAfter )
        Write-ToLog  ('Cert info - Subject: ' + $RemoteCertificate.GetNameInfo(3,$false) )
        #Write-ToLog  ('Cert info - Distinguished Name: ' + $RemoteCertificate.SubjectName.Name )
        Write-ToLog  ('Cert info - Issuer: ' + $RemoteCertificate.GetNameInfo(3,$true) )
        Write-ToLog  ('Cert info - Issuer Distinguished Name: ' + $RemoteCertificate.IssuerName.Name )
        Write-ToLog  ('Cert info - Usage: ' + $RemoteCertificate.EnhancedKeyUsageList )
    } 
    catch {
        $_.Exception
    }
    finally {
        $SslStream.Close()
        $NetStream.Close()
    }
    
}

function Write-ToLog()
{   param( $msg = "`n" )
    Write-Host $msg
    Add-Content $logfile -Value $msg
}
function Write-ToLogVerbose()
{   param( $msg = "`n" )
    if ($global:outputverbose ) { Write-Verbose $msg}
    Add-Content $logfile -Value ("VERBOSE:`t"+$msg)
}
function Write-ToLogWarning()
{   param( $msg = " `n" )
    if ($msg) {	#_#
		Write-Warning $msg
		Add-Content $logfile -Value ($global:dblbar)
		Add-Content $logfile -Value ("WARNING:`n`t"+$msg)
		Add-Content $logfile -Value ($global:dblbar)
	}
}

#_# cls

if ($outputverbose) {
    Test-MsDavConnection -WebAddress $testurl -Verbose }
else { Test-MsDavConnection -WebAddress $testurl }


# SIG # Begin signature block
# MIInzgYJKoZIhvcNAQcCoIInvzCCJ7sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBc+fufQ6aWHPz1
# CwSE+9YB7woyFl5qfH2MK/QXg9wiVaCCDYUwggYDMIID66ADAgECAhMzAAADri01
# UchTj1UdAAAAAAOuMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwODU5WhcNMjQxMTE0MTkwODU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQD0IPymNjfDEKg+YyE6SjDvJwKW1+pieqTjAY0CnOHZ1Nj5irGjNZPMlQ4HfxXG
# yAVCZcEWE4x2sZgam872R1s0+TAelOtbqFmoW4suJHAYoTHhkznNVKpscm5fZ899
# QnReZv5WtWwbD8HAFXbPPStW2JKCqPcZ54Y6wbuWV9bKtKPImqbkMcTejTgEAj82
# 6GQc6/Th66Koka8cUIvz59e/IP04DGrh9wkq2jIFvQ8EDegw1B4KyJTIs76+hmpV
# M5SwBZjRs3liOQrierkNVo11WuujB3kBf2CbPoP9MlOyyezqkMIbTRj4OHeKlamd
# WaSFhwHLJRIQpfc8sLwOSIBBAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhx/vdKmXhwc4WiWXbsf0I53h8T8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMTgzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AGrJYDUS7s8o0yNprGXRXuAnRcHKxSjFmW4wclcUTYsQZkhnbMwthWM6cAYb/h2W
# 5GNKtlmj/y/CThe3y/o0EH2h+jwfU/9eJ0fK1ZO/2WD0xi777qU+a7l8KjMPdwjY
# 0tk9bYEGEZfYPRHy1AGPQVuZlG4i5ymJDsMrcIcqV8pxzsw/yk/O4y/nlOjHz4oV
# APU0br5t9tgD8E08GSDi3I6H57Ftod9w26h0MlQiOr10Xqhr5iPLS7SlQwj8HW37
# ybqsmjQpKhmWul6xiXSNGGm36GarHy4Q1egYlxhlUnk3ZKSr3QtWIo1GGL03hT57
# xzjL25fKiZQX/q+II8nuG5M0Qmjvl6Egltr4hZ3e3FQRzRHfLoNPq3ELpxbWdH8t
# Nuj0j/x9Crnfwbki8n57mJKI5JVWRWTSLmbTcDDLkTZlJLg9V1BIJwXGY3i2kR9i
# 5HsADL8YlW0gMWVSlKB1eiSlK6LmFi0rVH16dde+j5T/EaQtFz6qngN7d1lvO7uk
# 6rtX+MLKG4LDRsQgBTi6sIYiKntMjoYFHMPvI/OMUip5ljtLitVbkFGfagSqmbxK
# 7rJMhC8wiTzHanBg1Rrbff1niBbnFbbV4UDmYumjs1FIpFCazk6AADXxoKCo5TsO
# zSHqr9gHgGYQC2hMyX9MGLIpowYCURx3L7kUiGbOiMwaMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGZ8wghmbAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGXL
# NT8ELSGRZT3ADHVA58gKVxTxTOd4GmxOmV0HrmaEMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAmbOLDeKhxyE4520Ouvomku3K4QjUGIEyIrQA
# OWyaDI18BcPT0GpmSollDEzImtVtPJSochzALkDlf3OVxJeDrPRAuVdLUC2gVeZm
# LPinbbZ3SMicaS4UsQEOFLlES4TxYs/EUmucfbvRo2OXl4mgx0iQbyP79T5svkXT
# eWVYMUh1svbcUEORJspn2Lx502KoipJY5F/gYB025fuhdZ30qI02zBq9Jc10d/H1
# kDBLGNciqSTPJYTLEyTx+lEQflUw/d/iA/UL+UidvFrifZ7Geq5WDFp8piSbVyjO
# ErUiW5sa+3gcE9qbY6xyMu6BHU3MCFtM09ScxYCdjTBbX1e5AqGCFykwghclBgor
# BgEEAYI3AwMBMYIXFTCCFxEGCSqGSIb3DQEHAqCCFwIwghb+AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFZBgsqhkiG9w0BCRABBKCCAUgEggFEMIIBQAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCAmIYnkQ0JTv6rqzeTDzVDZlNTQVOuL/7DW
# I9O8pJA/bQIGZlce/Fx0GBMyMDI0MDYxMjE1MDA0MS4zMDNaMASAAgH0oIHYpIHV
# MIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOjNCRDQtNEI4MC02OUMzMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloIIReDCCBycwggUPoAMCAQICEzMAAAHlj2rA
# 8z20C6MAAQAAAeUwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwHhcNMjMxMDEyMTkwNzM1WhcNMjUwMTEwMTkwNzM1WjCB0jELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9z
# b2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjozQkQ0LTRCODAtNjlDMzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKl7
# 4Drau2O6LLrJO3HyTvO9aXai//eNyP5MLWZrmUGNOJMPwMI08V9zBfRPNcucreIY
# SyJHjkMIUGmuh0rPV5/2+UCLGrN1P77n9fq/mdzXMN1FzqaPHdKElKneJQ8R6cP4
# dru2Gymmt1rrGcNe800CcD6d/Ndoommkd196VqOtjZFA1XWu+GsFBeWHiez/Pllq
# cM/eWntkQMs0lK0zmCfH+Bu7i1h+FDRR8F7WzUr/7M3jhVdPpAfq2zYCA8ZVLNgE
# izY+vFmgx+zDuuU/GChDK7klDcCw+/gVoEuSOl5clQsydWQjJJX7Z2yV+1KC6G1J
# VqpP3dpKPAP/4udNqpR5HIeb8Ta1JfjRUzSv3qSje5y9RYT/AjWNYQ7gsezuDWM/
# 8cZ11kco1JvUyOQ8x/JDkMFqSRwj1v+mc6LKKlj//dWCG/Hw9ppdlWJX6psDesQu
# QR7FV7eCqV/lfajoLpPNx/9zF1dv8yXBdzmWJPeCie2XaQnrAKDqlG3zXux9tNQm
# z2L96TdxnIO2OGmYxBAAZAWoKbmtYI+Ciz4CYyO0Fm5Z3T40a5d7KJuftF6CTocc
# c/Up/jpFfQitLfjd71cS+cLCeoQ+q0n0IALvV+acbENouSOrjv/QtY4FIjHlI5zd
# JzJnGskVJ5ozhji0YRscv1WwJFAuyyCMQvLdmPddAgMBAAGjggFJMIIBRTAdBgNV
# HQ4EFgQU3/+fh7tNczEifEXlCQgFOXgMh6owHwYDVR0jBBgwFoAUn6cVXQBeYl2D
# 9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
# LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQAD
# ggIBADP6whOFjD1ad8GkEJ9oLBuvfjndMyGQ9R4HgBKSlPt3pa0XVLcimrJlDnKG
# gFBiWwI6XOgw82hdolDiMDBLLWRMTJHWVeUY1gU4XB8OOIxBc9/Q83zb1c0RWEup
# gC48I+b+2x2VNgGJUsQIyPR2PiXQhT5PyerMgag9OSodQjFwpNdGirna2rpV23EU
# wFeO5+3oSX4JeCNZvgyUOzKpyMvqVaubo+Glf/psfW5tIcMjZVt0elswfq0qJNQg
# oYipbaTvv7xmixUJGTbixYifTwAivPcKNdeisZmtts7OHbAM795ZvKLSEqXiRUjD
# YZyeHyAysMEALbIhdXgHEh60KoZyzlBXz3VxEirE7nhucNwM2tViOlwI7EkeU5hu
# dctnXCG55JuMw/wb7c71RKimZA/KXlWpmBvkJkB0BZES8OCGDd+zY/T9BnTp8si3
# 6Tql84VfpYe9iHmy7PqqxqMF2Cn4q2a0mEMnpBruDGE/gR9c8SVJ2ntkARy5Sflu
# uJ/MB61yRvT1mUx3lyppO22ePjBjnwoEvVxbDjT1jhdMNdevOuDeJGzRLK9HNmTD
# C+TdZQlj+VMgIm8ZeEIRNF0oaviF+QZcUZLWzWbYq6yDok8EZKFiRR5otBoGLvaY
# FpxBZUE8mnLKuDlYobjrxh7lnwrxV/fMy0F9fSo2JxFmtLgtMIIHcTCCBVmgAwIB
# AgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1
# WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O
# 1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
# hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t
# 1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxq
# D89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmP
# frVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSW
# rAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv
# 231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zb
# r17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYcten
# IPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQc
# xWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17a
# j54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
# n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJ
# oEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01p
# Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYB
# BQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9v
# Q2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3h
# LB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x
# 5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
# y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1A
# oL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbC
# HcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB
# 9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNt
# yo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3
# rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcV
# v7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A24
# 5oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lw
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAtQwggI9AgEBMIIBAKGB2KSB1TCB
# 0jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMk
# TWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjozQkQ0LTRCODAtNjlDMzElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA942iGuYFrsE4wzWD
# d85EpM6RiwqggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOoUES0wIhgPMjAyNDA2MTIyMDIxMDFaGA8yMDI0MDYx
# MzIwMjEwMVowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6hQRLQIBADAHAgEAAgIU
# rDAHAgEAAgIR1DAKAgUA6hVirQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEE
# AYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GB
# AAkJnNlVwIcwLlfwYDaM7JQl1ODL52UAsG2eVJTcreZyVF7wZk37i/8dPes9M8s+
# E9BB8Xyi4xIp1V2SauyU9zrc53q1BzmIxC22ulVMy6E/BBhyXlIRBHXAJ3/x5VBr
# yJbglcY2iAKjO9zlKnw60BcsNm87QjAhZDaZZqaJyrtfMYIEDTCCBAkCAQEwgZMw
# fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHlj2rA8z20C6MAAQAA
# AeUwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAvBgkqhkiG9w0BCQQxIgQgLbW6iJGafWX1erVYZSLrEUP2/8lWdGfSNVlCa7bt
# 5S8wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAVqdP//qjxGFhe2YboEXeb
# 8I/pAof01CwhbxUH9U697TCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAAB5Y9qwPM9tAujAAEAAAHlMCIEIPrz64f8HITj+p5XWojP294P
# 8KgaLUeQajL16WZxd4DMMA0GCSqGSIb3DQEBCwUABIICAIlboFRzjTFXXQLtCvpA
# oB/iCLEr7etmemHobUOhCbMn4Ahom80UbRzJCswWOaL+iqP7B+wVtqfBn4MflWM9
# gmWxXqGOCzaEWFm5i6bIb6nd7/1XO0ovvnEUs6eHwSn7gIP4OoVto86nGOGEXq2i
# 5/auxVzpuyB3P0x0teo93PWTvU0ahONv8wQE1/3oQgrbXF1XC9MYAU39yDvZluK7
# KaC9pn2eWC9SnwKkZiK28mSRyhWi0Cn6QjldZ6nSuVKh4lmCQN7lSmHS3ql6YtjF
# wcXAuTtgQQ1GUJPhOvwWwIgXsk4bMN70qhUJ/uvgY32P7pFiMPF30ekMUr3uZ1tn
# 6XHCbMqjrXTwsrYdya+KdSZqkNuLpESQ0vHhbumqpssJuf/2iQbBeF1tHWCffLRc
# H804tVMRd6KtdLfyGRI2sYwVhw3vFH8z1psDCfBPSz8zQM6lup92QSmMMIoPrn6d
# 9IkarDLYRDpr4gtTiRarFb3zLpPDybmqf5ip0pRtA2tRsyUe7rm3JB2gYeOb57w3
# PbRlnXFT6p74eiTrUhXWJ7Lxx2ziPznmpDQtENa41kdIOQqDGpgNH2hHIxgigPJ/
# ttsaDBaO6l4F+Gucbo5djhzveru5VCiz8VWIv6+b7DHAvOfX15kaOmTihM1gz52Y
# ejRSFWWRpMx6g8frJc8mv4TS
# SIG # End signature block
