cls
Write-Host "Введите имя пользователя"
$user = Read-Host 
$login = Get-ADUser -Filter 'Name -like $user'
$cn = $login.DistinguishedName
$adsiuser = [ADSI]"LDAP://$cn"
[array]$groups = @($adsiuser.Memberof | ? {$_ -like "*group*"}) 
$groups
$count = Read-Host
$switch = 'switch ($count) {'
$i = 1
foreach ($group in $groups) {
   $switch += "`n`t$i {""Remove from $group""}"
   $i++
}
$switch += "`n}"
Invoke-Expression $switch