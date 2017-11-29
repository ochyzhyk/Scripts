Clear-Content -Path "C:\Users\user\Documents\output.txt"
$bak_path = "\\srvbkp\Backup\"
$blobContext = New-AzureStorageContext -StorageAccountName "name" -StorageAccountKey "key"
$files=get-childitem -path $bak_path -Filter "*.zip" | 
    where-object { -not $_.PSIsContainer } | 
    sort-object -Property LastWriteTime | 
    select-object -last 1 
#Set-AzureStorageBlobContent -File $file.fullname -Container "backupazure" -Blob $file.name -Context $blobContext -Force -ErrorVariable a 
Set-AzureStorageFileContent -Source $file.fullname -ShareName "<name>" -Path "\\<name>.file.core.windows.net" -Context $BlobContext -Force -ErrorVariable a
Out-File -FilePath "C:\Users\user\Documents\output.txt" -InputObject $a -Append

$output = Get-content -Path "C:\Users\user\Documents\output.txt" | 
Select-Object -First 1
$EmailFrom = "srv@database"
$EmailTo = "user@dc.local"
$Subject = "Copy weekly backups to Azure"
$Bodyfail = "Copying of DataBase backup failed with result: `n$output"
$BodyOK = "Copying of DataBase backup comleted successfully. `nFile: $files"
$SMTPServer = "10.10.10.10"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
if (!$a) {
 $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $BodyOK)
 }
 else {
 $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Bodyfail)
 }
#$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
