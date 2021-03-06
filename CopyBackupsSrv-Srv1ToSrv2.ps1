$n = 2
do {
    $saturday = (date).AddDays(-$n)
    $n++
}
Until ( $saturday.DayOfWeek -eq "Saturday" )

$m = 2
do {
    $sunday = (date).AddDays(-$m)
    $m++
}
Until ( $sunday.DayOfWeek -eq "Sunday" )

$FileDateSat = $saturday.ToString("yyyy_MM_dd")
$FileDateSun = $sunday.ToString("yyyy_MM_dd")
$FileDateLUCANET = $sunday.ToString("yyyy-MM-dd")
#$FileDate = "2016_10_2"
$SrcFolder = "D:\Backup\Weekly\",
"D:\Backup\Daily\"
$RARFile = "D:\Backup_$FileDateSat.zip"
$DestRARFile = "\\srvbkp\Backup\Backup_$FileDateSat.zip"

#set-alias rar "C:\Program Files\WinRAR\WinRAR.exe"

Set-Alias zip "C:\Program Files\7-Zip\7z.exe"

Get-ChildItem -Path $SrcFolder -Filter *$FileDateSat* -Recurse | Foreach-Object {
#rar a -hp<key> -r -m0 -t -mt4 $SrcRARFile $_.fullname | Wait-Process
zip a $RARFile $_.fullname -p<key> -mmt -mx0
}

Get-ChildItem -Path $SrcFolder -Filter *$FileDateSun* -Recurse | Foreach-Object {
#rar a -hp<key> -r -m0 -t -mt4 $SrcRARFile $_.fullname | Wait-Process
zip a $RARFile $_.fullname -p<key> -mmt -mx0
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