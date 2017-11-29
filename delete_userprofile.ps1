#$MachineName = Gc "C:\Users\user\Desktop\srv.txt"

$MachineName = @(
"srv113.dc.local",
"srv120.dc.local",
"srv123.dc.local",
"srv125.dc.local",
"srv126.dc.local",
"srv129.dc.local",
"srv106.dc.local"
)
foreach ($a in $MachineName) {
Get-WmiObject Win32_UserProfile -ComputerName $a | Where-Object {($_.LocalPath -like "*user")} | % {$_.Delete()}
Write-Host $a
}