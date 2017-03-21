cls
$servers = "srv-drmdb01.ulf.local" #Get-Content "D:\Scipts\serverList.csv"
$localgroup = "Администраторы"
foreach ($server in $servers) {
$Group= [ADSI]"WinNT://$Server/$LocalGroup,group"
$members = $Group.psbase.Invoke("Members")

$members | ForEach { 
$admGroup = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) | where {$_ -Match "\.Admins"} }
$srvname = $server.Split(".")
$srv = $srvname[0]
$ADGroup= [ADSI]"WinNT://ulf.local/g-$srv.Admins"

if(!$admGroup) {
    $Group.PSBase.Invoke("Add",$ADGroup.PSBase.Path)
    Write-Host "Group g-$srv.Admins added to local administrators"
}


$members | ForEach {
$name = $_.GetType().InvokeMember("Name", 'GetProperty',  $null, $_, $null)
$Class = $_.GetType().InvokeMember("Class", 'GetProperty',  $null, $_, $null)
$path = $_.GetType().InvokeMember("ADsPath", 'GetProperty',  $null, $_, $null)
if ($Class -match "User" -and $path -match "ULF") {
    Add-ADGroupMember "g-$srv.Admins" "$name"
    Write-Host "User $name added to group g-$srv.Admins"
    $ADUsers= [ADSI]"WinNT://ulf.local/$name"
    $Group.PSBase.Invoke("Remove",$ADUsers.PSBase.Path)
    Write-Host "User $name removed from local administrators"
    }
}

$User= [ADSI]"WinNT://ulf.local/u-svc-$srv"
$bool = $Group.IsMember($User.PSBase.Path)
if ($bool -eq $false) {
    Add-ADGroupMember "g-$srv.Admins" "u-svc-$srv"
    Write-Host "User u-svc-$srv added to group g-$srv.Admins"
    }
}
