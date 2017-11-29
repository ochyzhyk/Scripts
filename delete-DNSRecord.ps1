$row = @(gc "D:\testresult.txt")
$row.foreach({
$srvrec = @(($_).Split(" "))
#$srvrec[0]
Remove-DnsServerResourceRecord -ComputerName "srvDC" -ZoneName "dc.local" -RRType A -Name $srvrec[0] -Force
})