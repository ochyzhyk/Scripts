#$cred = Get-Credential
#$networkCred = $cred.GetNetworkCredential()
$hostnames = #"srv-db109.ulf.local", "srv-db111.ulf.local",
<#"srv-db100.ulf.local",
"srv-db101.ulf.local",
"srv-db102.ulf.local",
"srv-db103.ulf.local",
"srv-db104.ulf.local",
"srv-db105.ulf.local",
"srv-db107.ulf.local",
"srv-db108.ulf.local",
"srv-db109.ulf.local",
"srv-db112.ulf.local",
"srv-db113.ulf.local",
"srv-db115.ulf.local",#>
"srv-db116.ulf.local",
"srv-db117.ulf.local",
"srv-db118.ulf.local",
"srv-db119.ulf.local",
"srv-db120.ulf.local",
"srv-db121.ulf.local",
"srv-db122.ulf.local",
"srv-db123.ulf.local",
"srv-db124.ulf.local",
"srv-db125.ulf.local",
"srv-db126.ulf.local",
"srv-db127.ulf.local",
"srv-db129.ulf.local"
foreach ($hostname in $hostnames) { 
$path = "\\$hostname\C$\Program Files"
$shareh = "\\$hostname\C$"
net use $shareh HindsToast2 /USER:ulf\chyzhyko_m
Copy-Item "D:\Scipts\InstallWinlogbeat\winlogbeat" -destination $path -Recurse -Force
net use $shareh /delete
}

