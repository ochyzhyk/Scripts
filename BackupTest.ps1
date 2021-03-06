$n = 0
do {
    $date = (date).AddDays(-$n)
    $n++
}
Until ( $date.DayOfWeek -eq "Saturday" )
$FileDate=$date.ToString("yyyy_MM_dd")
$SrcFolder = "D:\КорсакО", 
"D:\SnagItOriginal",
"D:\HP M5035"
$RARFile = "D:\Backup_$filedate.rar"
$DestRARFile = "D:\temp\Backup_$filedate.rar"

set-alias rar "C:\Program Files (x86)\WinRAR\WinRAR.exe"

Get-ChildItem -Path $SrcFolder -Filter *$FileDate* -Recurse | Foreach-Object {
rar a -hppassword -r -m0 -t -mt4 $RARFile $_.fullname | Wait-Process
}

Move-Item -Path $RARFile -Destination $DestRARFile

#$ChkArchive = Test-Path $DestRARFile
#$EmailFrom = "BackUp@database"
#$EmailTo = "user@dc.local"
#$Subject = "Copy weekly backups to Azure"
#$BodyOK = "Copying of DataBase backUps was completed successfully `n File: $DestRARFile"
#$BodyFail = "Copying of DataBase backUps failed"
#$SMTPServer = "10.10.10.10"
#$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)

#if ($ChkArchive -eq $True) {
# $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $BodyOK)
# }
# else {
# $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $BodyFail)
# }