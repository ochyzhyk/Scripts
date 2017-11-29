$list = @(gc -Path "C:\Test\LIstServers.txt")
foreach ($srv in $list)
{
$serv= $srv.Replace(" ","") 
[string]$a = Test-NetConnection -CommonTCPPort RDP -ComputerName $serv | select ComputerName,TcpTestSucceeded  
$b = $a.Split("{",";","}","=")
$b[2],$b[4] -join " " | out-file -FilePath C:\test\LIstServersTF.txt -Append
#write-host $c # | out-file -FilePath C:\test\LIstServersTF.txt -Append
}


#if($flag -like "*True*")
#{
#write "$serv  True" #| Out-File -FilePath "D:\Scripts\LIstServersTF.txt" -Append
#} else {
#write "$serv  False" #| Out-File -FilePath "D:\Scripts\LIstServersTF.txt" -Append
#}
#}