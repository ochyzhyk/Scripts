$servers= @(Get-ADComputer -Filter 'name -like "srv-dc*"')
foreach ($srv in $servers)
{
$serv = $srv.Name
$serv
#$split = $srv.Split(',')
#$serv = $split[1]
#$serv
$cmd = "query session /server:$serv"
iex $cmd
}