$a=Get-ADComputer -LDAPFilter "(Name=*SRV-RDS*)" # -Properties ipv4Address, OperatingSystem, OperatingSystemServicePack | Format-List name
$a.name | Out-File D:\Scripts\SRV-RDS170317.csv