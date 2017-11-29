cls
$servers = "srv.dc.local" #Get-Content "D:\Scipts\serverList.csv"
$localgroup = "Администраторы"
foreach ($server in $servers) {
$Group= [ADSI]"WinNT://$Server/$LocalGroup,group"
$members = $Group.psbase.Invoke("Members")

$members | ForEach { 
$admGroup = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) | where {$_ -Match "\.Admins"} }
$srvname = $server.Split(".")
$srv = $srvname[0]
$ADGroup= [ADSI]"WinNT://dc.local/g-$srv.Admins"

if(!$admGroup) {
    $Group.PSBase.Invoke("Add",$ADGroup.PSBase.Path)
    Write-Host "Group g-$srv.Admins added to local administrators"
}


$members | ForEach {
$name = $_.GetType().InvokeMember("Name", 'GetProperty',  $null, $_, $null)
$Class = $_.GetType().InvokeMember("Class", 'GetProperty',  $null, $_, $null)
$path = $_.GetType().InvokeMember("ADsPath", 'GetProperty',  $null, $_, $null)
if ($Class -match "User" -and $path -match "DC") {
    Add-ADGroupMember "$srv.Admins" "$name"
    Write-Host "User $name added to group $srv.Admins"
    $ADUsers= [ADSI]"WinNT://dc.local/$name"
    $Group.PSBase.Invoke("Remove",$ADUsers.PSBase.Path)
    Write-Host "User $name removed from local administrators"
    }
}

$User= [ADSI]"WinNT://dc.local/$srv"
$bool = $Group.IsMember($User.PSBase.Path)
if ($bool -eq $false) {
    Add-ADGroupMember "$srv.Admins" "$srv"
    Write-Host "User $srv added to group $srv.Admins"
    }
}
