#$hostnames = "srv44.dc.local", "srv52.dc.local"
#Get-Content D:\Scipts\srv-apps.csv


$hostnames = Get-ADDomainController -Filter *
foreach ($hostname in $hostnames) { 
Write-Host $hostname.Name
Invoke-Command -ComputerName $hostname.Name -ScriptBlock { 
Start-Service -Name "winlogbeat"
}
}