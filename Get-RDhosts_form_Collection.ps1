Import-Module -Name RemoteDesktop
Get-RDServer -ConnectionBroker 'srvCB'
$a = Get-RDSessionHost -CollectionName "Collection1" | select -Property SessionHost
foreach ($b in $a) {
nslookup $b.SessionHost | select -last 3
}

#Get-RDUserSession -connectionbroker "srv-rds100.ulf.local"