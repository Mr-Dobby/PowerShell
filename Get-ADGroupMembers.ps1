$Filter = ""

Import-Module ActiveDirectory

$Groups = (Get-AdGroup -filter * | where-object {$_.name -like "*$Filter*"} | select-object name -expandproperty name)
$Table = @()

$Record = [ordered]@{
    "Group Name" = ""
    "Name" = ""
    "Username" = ""
}

Foreach ($Group in $Groups) {

    $Arrayofmembers = Get-ADGroupMember -identity $Group | select-object name,samaccountname

foreach ($Member in $Arrayofmembers) {
    $Record."Group Name" = $Group
    $Record."Name" = $Member.name
    $Record."UserName" = $Member.samaccountname
    $objRecord = New-Object PSObject -property $Record
    $Table += $objrecord
  }
}

$Table | Export-Csv "C:\SecurityGroups.csv" -NoTypeInformation
