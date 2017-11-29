#$hostnames = "srv44.dc.local", "srv52.dc.local"
#Get-Content D:\Scipts\srv-apps.csv
$hostnames = Get-ADDomainController -Filter *
foreach ($hostname in $hostnames) { 
#$dc = $hostname.Name
Write-Host $hostname.Name
Invoke-Command -ComputerName $hostname.Name -ScriptBlock { 
cd 'C:\Program Files\winlogbeat'
.\install-service-winlogbeat.ps1
}
}