$hostnames = Get-Content D:\Scipts\serverlist.csv
foreach ($hostname in $hostnames) { 
#Out-File -FilePath D:\tasks.csv $hostname -Append
Invoke-Command -ComputerName $hostname -ScriptBlock {schtasks.exe /query /FO LIST /V} | Out-File -FilePath D:\tasks.csv -Append default
}