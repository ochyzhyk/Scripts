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
$SrcFolderLUCANET = "D:\Backup_LUCANET\Standart\Weekly\Backup $FileDateLUCANET"
$SrcFolder = "D:\Backup_OTHER\Weekly\Srv-drmdb01\ULFPROD",
"D:\Backup_OTHER\Weekly\Srv-drmdb01\DirectumBase2",
"D:\Backup_OTHER\Weekly\Srv-db116\ConsolidationDB",
"D:\Backup_OTHER\Weekly\Srv-db116\DocflowDB",
"D:\Backup_OTHER\Weekly\Srv-db117\UMAP",
"D:\Backup_OTHER\Weekly\Srv-db112\Treasury_ULF",
"D:\Backup_MEAT\Weekly\Srv-db103\meat_cb",
"D:\Backup_OTHER\Weekly\Srv-db116\MDM_NCI",
"D:\Backup_RISE\Weekly\Srv-db101\RiseTOVDB",
"D:\Backup_OTHER\Weekly\Srv-db116\Itilium_82DB",
"D:\Backup_OTHER\Weekly\Srv-db116\U001_ULF_OwnershipStructureDB",
"D:\Backup_RISE\Weekly\Srv-db101\RiseDB",
"D:\Backup_RISE\Weekly\Srv-db101\Rise_auditDB",
"D:\Backup_MEAT\Weekly\Srv-db103\meat_cb"
$RARFile = "D:\Backup_$FileDateSat.zip"
$DestRARFile = "\\srv-bkp05\Backup_SQL\srv-bkp03\Backup_$FileDateSat.zip"

#set-alias rar "C:\Program Files\WinRAR\WinRAR.exe"

Set-Alias zip "C:\Program Files\7-Zip\7z.exe"

Get-ChildItem -Path $SrcFolder -Filter *$FileDateSat* -Recurse | Foreach-Object {
#rar a -hpxQUoY3Mbz4vQCcZ4y31g -r -m0 -t -mt4 $SrcRARFile $_.fullname | Wait-Process
zip a $RARFile $_.fullname -pxQUoY3Mbz4vQCcZ4y31g -mmt -mx0
}

Get-ChildItem -Path $SrcFolder -Filter *$FileDateSun* -Recurse | Foreach-Object {
#rar a -hpxQUoY3Mbz4vQCcZ4y31g -r -m0 -t -mt4 $SrcRARFile $_.fullname | Wait-Process
zip a $RARFile $_.fullname -pxQUoY3Mbz4vQCcZ4y31g -mmt -mx0
}

zip a $RARFile $SrcFolderLUCANET -pxQUoY3Mbz4vQCcZ4y31g -mmt -mx0

#rar a -hpxQUoY3Mbz4vQCcZ4y31g -r -m0 -t -mt4 $SrcRARFile $SrcFolder1 | Wait-Process

Move-Item -Path $RARFile -Destination $DestRARFile

$ChkArchive = Test-Path $DestRARFile
$EmailFrom = "BackUp@database"
$EmailTo = "list_departments_IT_sysadmins@ulf.com.ua"
$Subject = "Copy weekly backups to Azure"
$BodyOK = "Copying of DataBase backUps was completed successfully `n File: $DestRARFile"
$BodyFail = "Copying of DataBase backUps failed"
$SMTPServer = "10.9.130.11"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)

if ($ChkArchive -eq $True) {
 $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $BodyOK)
 }
 else {
 $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $BodyFail)
 }