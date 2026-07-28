<#
    .Synopsis
        Reset incorrect ACL on Home Folders
    .DESCRIPTION
        Reset incorrect ACL on an existing set of Home Folders.  It must be run on the FileServer that contains the home folders
        You can omit the domain parameter and it will default to the login domain.
    .EXAMPLE
        Set-HomeFolderACL -Domain 'example.com' -Path 'C:\home\folder\path'
    .EXAMPLE
        Another example of how to use this cmdlet
    .Requires
        VERSION 3
        ELEVATION
#>
function Set-HomeFolderACL{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false)]
        [String]$Domain=$env:USERDOMAIN,
        [Parameter(Mandatory=$true)]
        [String]$Path
    )
    Begin {
        $folders = Get-ChildItem $Path
    }
    Process {
        foreach ($user in $folders){
            $username = New-Object System.Security.Principal.NTAccount("$domain", "$user.Name")
            $folder = Get-Acl $user.FullName

            $folder.SetOwner($username)
            Set-Acl -AclObject $folder -Path $user.FullName
            #Owner object set on users folder next we do all files and folders inside  
            $files = Get-ChildItem -Recurse $user.FullName
            
            foreach ($file in $files) {
                $fixed = Get-Acl $file.FullName
                $fixed.SetOwner($username)
                Set-Acl -AclObject $fixed -Path $file.FullName
            }
        }
    }
}