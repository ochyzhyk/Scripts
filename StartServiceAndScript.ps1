$hostnames = Get-Content D:\Scipts\serverList.csv
foreach ($hostname in $hostnames) { 
Write-Host $hostname
#psexec  -u ulf\chyzhyko_m -p HindsToast2 "\\$hostname" -s powershell -f "C:\Program Files\winlogbeat\install-service-winlogbeat.ps1"
#psexec  -u ulf\chyzhyko_m -p HindsToast2 "\\$hostname" -s 'powershell Restart-Service -Name "SQLServerAgent"'
Invoke-Command -cn $hostname -scriptblock { Restart-Service -Name "SQLServerAgent" }
}