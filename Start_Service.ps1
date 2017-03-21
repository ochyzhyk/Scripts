cls
$hostnames = Get-Content "D:\Scipts\ALL_servers.csv"
foreach ($hostname in $hostnames) { 
Write-Host $hostname
Invoke-Command -ComputerName $hostname -ScriptBlock { 
Start-Service -Name "Zabbix Agent"
}
}