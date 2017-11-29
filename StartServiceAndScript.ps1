$hostnames = Get-Content D:\Scipts\serverList.csv
foreach ($hostname in $hostnames) { 
Write-Host $hostname
#psexec  -u domain\user -p password "\\$hostname" -s powershell -f "C:\Program Files\winlogbeat\install-service-winlogbeat.ps1"
#psexec  -u domain\user -p password "\\$hostname" -s 'powershell Restart-Service -Name "SQLServerAgent"'
Invoke-Command -cn $hostname -scriptblock { Restart-Service -Name "SQLServerAgent" }
}