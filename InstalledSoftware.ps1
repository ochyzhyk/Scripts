CLS
$hostnames = Get-Content D:\Scipts\srv-apps.csv
foreach ($hostname in $hostnames) { 
Add-Content D:\users.txt "`n=========================================================================`n`nList of users on $hostname :" 
#[Console]::OutputEncoding = [System.Text.Encoding]::utf8
Invoke-Command -cn $hostname -scriptblock { net localgroup администраторы } | Out-File D:\users.txt -Append default
}



<#Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |`
Select-Object DisplayName <#, DisplayVersion, Publisher, InstallDate |` 
Format-Table –AutoSize  | Where-Object {$_.DisplayName -match "Native Client"}}
} #2>&1 | Out-File D:\Native.txt #>