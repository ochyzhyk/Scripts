cls
$username = Read-Host
$MachineName = @("srv112", "srv122", "srv127", "srv135", "srv136", "srv137", "srv138", "srv139", "srv140", "srv141", "srv142","srv143")
foreach ($srv in $MachineName) {
Get-childitem \\$srv\C$\Users\$username\AppData\Local\1C\1cv8 -Filter "*-*-*-*-*" | Remove-Item -Recurse -Force
}