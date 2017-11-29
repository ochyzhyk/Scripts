#$ErrorActionPreference = "SilentlyContinue"
& "C:\Program Files\Microsoft Azure Recovery Services Agent\bin\wabadmin.msc" 
Start-Sleep -s 5
Switch-AzureMode AzureResourceManager
Import-module MSOnlineBackup 
$src_dir = "\\Bushmakin-pc\iso"
$dst_dir = "C:\Destination\"
$file = Get-ChildItem $src_dir  | where {([datetime]::now - $_.lastwritetime).TotalHours -lt 24}   #-Include *.bak -Exclude *.trn 
 if (!$file) 
 {
$EmailFrom = "bushmakinandrey@gmail.com"
$EmailTo = "andrey.bushmakin@syntegra.com.ua" 
$Subject = "Notification from XYZ" 
$Body = "this is a notification from XYZ Notifications.." 
$SMTPServer = "smtp.gmail.com" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("bushmakinandrey@gmail.com", "superpassword"); 
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
 } 
 else
 {
cd $src_dir
Copy-Item $file -Destination $dst_dir 
Get-OBPolicy | Start-OBBackup
Write-Host 'Backup done!!!'
Stop-Process -name "mmc"
 }