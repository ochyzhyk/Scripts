#$cred = Get-Credential
#$networkCred = $cred.GetNetworkCredential()
$hostnames = #"srv109.dc.local", "srv111.dc.local",
<#"srv100.dc.local",
"srv101.dc.local",
"srv102.dc.local",
"srv103.dc.local",
"srv104.dc.local",
"srv105.dc.local",
"srv107.dc.local",
"srv108.dc.local",
"srv109.dc.local",
"srv112.dc.local",
"srv113.dc.local",
"srv115.dc.local",#>
"srv116.dc.local",
"srv117.dc.local",
"srv118.dc.local",
"srv119.dc.local",
"srv120.dc.local",
"srv121.dc.local",
"srv122.dc.local",
"srv123.dc.local",
"srv124.dc.local",
"srv125.dc.local",
"srv126.dc.local",
"srv127.dc.local",
"srv129.dc.local"
foreach ($hostname in $hostnames) { 
$path = "\\$hostname\C$\Program Files"
$shareh = "\\$hostname\C$"
net use $shareh password /USER:domain\user
Copy-Item "D:\Scipts\InstallWinlogbeat\winlogbeat" -destination $path -Recurse -Force
net use $shareh /delete
}

