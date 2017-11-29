$servers = Get-Content "D:\Scipts\serverList.csv"
foreach ($server in $servers){
Add-Content "D:\Databases.txt" "===================================================`n $server"
<#$selects = Get-Content "D:\Scipts\select.sql"
foreach ($select in $selects) {#>
Invoke-Sqlcmd -Query "SELECT name FROM master.dbo.sysdatabases"  -ServerInstance "$server" -Username "user" -Password "Password" | Out-File default -FilePath "D:\Databases.txt" -Append #}
}