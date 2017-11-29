Import-Module -Name posh-ssh
Get-Module -ListAvailable

#New-SSHSession -ComputerName "10.10.10.101"
#Invoke-SSHCommand -Index 2 -Command "showpd -c" | select -ExpandProperty Output
Function Get-UnmapSpace {
$out = @(Invoke-SSHCommand -Index 0 -Command "showvv -showcols Name,Reclaimed_Usr_MB" | select -ExpandProperty Output)
$out = $out.Where({$_ -like "3PAR-VV01*"})
#$out
foreach ($a in $out)
{
$b = $a.split(" ")
Write-Host $b[0] ([convert]::ToInt32($b[10], 10)/1024)
}
}

Get-UnmapSpace

#New-SSHSession -ComputerName "esxhost"
Function Grep {
Invoke-SSHCommand -Index 1 -Command "lsof | grep -i .asyncUnmapFile" | select -ExpandProperty Output
}
Grep

Function Unmap {
Invoke-SSHCommand -Index 1 -Command "esxcli storage  vmfs unmap -l DS04-VD01\ \(SSD\) && esxcli storage  vmfs unmap -l DS04-VD03\ \(SSD\)" | select -ExpandProperty Output
}
Unmap

#New-SSHSession -ComputerName "10.10.10.100"
Invoke-SSHCommand -Index 0 -Command "curl -XGET 'localhost:9200/_cat/indices?v&pretty'" | select -ExpandProperty Output


curl -XDELETE 'localhost:9200/winlogbeat-2017.03.20?pretty'
"curl -XGET 'localhost:9200/_cat/indices?v&pretty'"
curl -XGET 'localhost:9200/_cat/indices/win*?v&h=index'


#Get-Command -Module Posh-SSH
#remove-SSHSession -SessionId 0
#Get-SSHSession