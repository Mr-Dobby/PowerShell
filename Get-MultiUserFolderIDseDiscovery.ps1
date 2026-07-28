#########################################################################################################
 #This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
 #THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS OR A PARTICULAR PURPOSE. 
 #We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
 # (1) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
 # (2) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
 # (3) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorney's fees, that arise or result from the use or distribution of the Sample Code.
 #########################################################################################################
 " "
 write-host "***********************************************"
 write-host "Security & Compliance Center   " -foregroundColor yellow
 write-host "eDiscovery cases - FolderID report         " -foregroundColor yellow
 write-host "***********************************************"
 " "

 #prompt users to specify a path to store the output files
 $time = get-date -Format dd-MM-yyyy_hh.mm
 $Path = Read-Host 'Enter a folder path to save the report to a .csv file (filename is created automatically).'
 $inputPath = $Path + '\' + 'Users_GatherFolderID.csv'
 $outputpath = $Path + '\' + 'FileID Report' + ' ' + $time + '.csv'

 #Imports list of users
 #User List needs column "UserSMTP" with values of each mailbox's SMTP address.
 $users = Import-CSV $inputPath

 function add-tofolderidreport {
     Param(
         [string]$UserEmail,
         [String]$FolderName,
         [String]$FolderID,
         [String]$ConvertedFolderQuery
     )

     $addRow = New-Object PSObject
     Add-Member -InputObject $addRow -MemberType NoteProperty -Name "User Email" -Value $useremail
     Add-Member -InputObject $addRow -MemberType NoteProperty -Name "Folder Name" -Value $FolderName
     Add-Member -InputObject $addRow -MemberType NoteProperty -Name "Native Folder ID" -Value $FolderID
     Add-Member -InputObject $addRow -MemberType NoteProperty -Name "Converted Folder Query" -Value $ConvertedFolderQuery

     $folderIDReport = $addRow | Select-Object "User Email", "Folder Name", "Native Folder ID", "Converted Folder Query"
     $folderIDReport | export-csv -path $outputPath -notypeinfo -append -Encoding ascii
 }

 #get information on the cases and pass values to the FolderID report function
 foreach ($u in $users) {
     $userAddress = $u.UserSMTP
     " "
     write-host "Gathering list of Folders for User:" $userAddress -ForegroundColor Yellow
     " "
     if ($userAddress.IndexOf("@") -ige 0) {
         # List the folder Ids for the target mailbox
         $emailAddress = $userAddress
         # Connect to Exchange Online PowerShell
         $folderQueries = @()
         $folderStatistics = Get-MailboxFolderStatistics $emailAddress -IncludeSoftDeletedRecipients
         foreach ($folderStatistic in $folderStatistics) {
             $folderId = $folderStatistic.FolderId;
             $folderPath = $folderStatistic.FolderPath;
             $encoding = [System.Text.Encoding]::GetEncoding("us-ascii")
             $nibbler = $encoding.GetBytes("0123456789ABCDEF");
             $folderIdBytes = [Convert]::FromBase64String($folderId);
             $indexIdBytes = New-Object byte[] 48;
             $indexIdIdx = 0;
             $folderIdBytes | select -skip 23 -First 24 | % { $indexIdBytes[$indexIdIdx++] = $nibbler[$_ -shr 4]; $indexIdBytes[$indexIdIdx++] = $nibbler[$_ -band 0xF] }
             $folderQuery = "folderid:$($encoding.GetString($indexIdBytes))";
             $folderStat = New-Object PSObject
             Add-Member -InputObject $folderStat -MemberType NoteProperty -Name FolderPath -Value $folderPath
             Add-Member -InputObject $folderStat -MemberType NoteProperty -Name FolderQuery -Value $folderQuery
             $folderQueries += $folderStat

             #add information to Report
             add-tofolderidreport -UserEmail $emailAddress -FolderName $folderPath -FolderID $folderId -ConvertedFolderQuery $folderQuery
         }

         #Outputs Exchange Folders for Single User
         Write-Host "-----Exchange Folders-----" -ForegroundColor Yellow
         $folderQueries | ft

     }

 }

 #Provides Path of Report
 " "
 Write-Host "----- Report Output Available at:" "$outputpath" " -----" -ForegroundColor Yellow
 " "