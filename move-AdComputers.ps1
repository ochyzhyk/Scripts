#iex -Command {"query session /server:srv00"}



function Test-Srv
{
    $srvs = @( Get-ADComputer -SearchBase "OU=INFRASTRUTURE,DC=dc,DC=local" -filter 'name -like "srv*"' )
    foreach ($srv in $srvs)
    {
        Test-NetConnection -ComputerName $srv.name -CommonTCPPort RDP -OutVariable out
        if ($out.TcpTestSucceeded -like "False") {
            "{0} {1} {2} {3}" -f $out.computername, $out.RemoteAddress, $out.TcpTestSucceeded, $srv.DistinguishedName | Out-File "D:\testresult.txt" -Append
            [adsi]$adsiComp = "LDAP://{0}" -f $srv.DistinguishedName
            $adsiComp.MoveTo("LDAP://OU=Корзина (old comp),DC=dc,DC=local")
            $adsiComp.InvokeSet("AccountDisabled", $true)
            $adsiComp.SetInfo()
            Remove-DnsServerResourceRecord -ComputerName "srv" -ZoneName "dc.local" -RRType A -Name $srv.name -Force
        }
    }
}

Test-Srv

#$out