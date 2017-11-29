$servers = Get-Content "D:\Scipts\serverList.csv"
ForEach ($server in $servers){
    $srvname = $server.Split(".")
    $srv = $srvname[0]
    $group = "$srv"
    #Get-ADGroup $group.Group
    try { Get-ADGroup $group }
    catch { Write-Host "$group not found" -ForegroundColor Red }

}