cls
$hostnames = @(Get-ADComputer -LDAPFilter "(Name=*SRV*)")#Get-Content "D:\Scipts\ALL_servers.csv"
foreach ($hostname in $hostnames) { 
Write-Host $hostname.name
Invoke-Command -ComputerName $hostname.name -ScriptBlock { 
get-Service -Name "Zabbix Agent"
}
}