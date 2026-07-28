$ModuleRoot = Split-Path $MyInvocation.MyCommand.Path

Get-ChildItem "$ModuleRoot\Modules\*.psm1" | ForEach-Object {
    Import-Module $_.FullName -DisableNameChecking -Force
}

Export-ModuleMember -Function *-*