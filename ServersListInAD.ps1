$a=Get-ADComputer -LDAPFilter "(Name=*SRV*)" # -Properties ipv4Address, OperatingSystem, OperatingSystemServicePack | Format-List name
$a.name | Out-File D:\Scripts\SRV.txt