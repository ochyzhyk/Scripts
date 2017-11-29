#$cred = Get-Credential
#$networkCred = $cred.GetNetworkCredential()
#$hostnames = "srv44.dc.local", "srv52.dc.local", "srv130.dc.local" 
#Get-Content D:\Scipts\srv-apps.csv


$hostnames = Get-ADDomainController -Filter *
foreach ($hostname in $hostnames) { 
$dc = $hostname.Name

#$dc }

$path = "\\$dc\C$\Program Files\"
$shareh = "\\$dc\C$"

#net use $shareh $networkCred.Password /USER:$networkCred.UserName
#net use $shareh password /USER:domain\user
#Copy-Item "D:\Scipts\Installwinlogbeat.ps1" -destination $path -Recurse -Force

Copy-Item "D:\Scripts\InstallWinlogbeat\winlogbeat" -destination $path -Recurse -Force

#net use $shareh /delete

}

