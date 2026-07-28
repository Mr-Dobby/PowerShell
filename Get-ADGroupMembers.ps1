#####################
#
# By RALBE
#
#####################

$Filter = ""

Import-Module ActiveDirectory

$Groups = (Get-AdGroup -filter * | Where {$_.name -like "*$Filter*"} | select name -expandproperty name)
$Table = @()

$Record = [ordered]@{
    "Group Name" = ""
    "Name" = ""
    "Username" = ""
}

Foreach ($Group in $Groups) {

    $Arrayofmembers = Get-ADGroupMember -identity $Group | select name,samaccountname

foreach ($Member in $Arrayofmembers) {
    $Record."Group Name" = $Group
    $Record."Name" = $Member.name
    $Record."UserName" = $Member.samaccountname
    $objRecord = New-Object PSObject -property $Record
    $Table += $objrecord
  }
}

$Table | Export-Csv "C:\Users\itradm\Documents\CSV Files\SecurityGroups.csv" -NoTypeInformation
