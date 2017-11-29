cls
Write-Host "Введите имя пользователя c кого копировать"
$user = Read-Host 
Write-Host "Введите имя пользователя кому копировать"
$user2 = Read-Host 
$login = Get-ADUser -Filter 'Name -like $user'
$login2 = Get-ADUser -Filter 'Name -like $user2'
$cn = $login.DistinguishedName
$adsiuser = [ADSI]"LDAP://$cn"
$groups = @($adsiuser.Memberof)
foreach ($group in $groups) {
Add-ADGroupMember $group -Members $login2
}