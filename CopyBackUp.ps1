$n = 5
do {
    $date = (date).AddDays(-$n)
    $n++
}
Until ( $date.DayOfWeek -eq "Saturday" )

$FileDate = $date.ToString("yyyy_MM_dd")
$SrcFolder = "D:\КорсакО", "D:\SnagItOriginal", "D:\HP M5035" 
$RARFile = "D:\Backup_$filedate.zip"
$DestRARFile = "D:\temp"

#set-alias rar "C:\Program Files (x86)\WinRAR\WinRAR.exe"
Set-Alias zip "C:\Program Files\7-Zip\7z.exe"

Get-ChildItem -Path $SrcFolder -Filter *$FileDate* -Recurse | Foreach-Object {
#rar a -hppassword -r -m0 -t -mt4 $RARFile $_.fullname | Wait-Process
zip a $RARFile $_.fullname -ppassword -mx0
}

Move-Item -Path $RARFile -Destination $DestRARFile

$ChkArchive = Test-Path $DestRARFile
$EmailFrom = "BackUp@database"
$EmailTo = "user@dc.local"
$Subject = "Copy weekly backups to Azure"
$BodyOK = "Copying of DataBase backUps was completed successfully `n File: $DestRARFile"
$BodyFail = "Copying of DataBase backUps failed"
$SMTPServer = "10.10.10.10"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)

if ($ChkArchive -eq $True) {
 $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $BodyOK)
 }
 else {
 $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $BodyFail)
 }