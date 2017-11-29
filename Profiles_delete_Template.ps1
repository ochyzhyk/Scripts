$MachineName = @(Get-ADComputer -filter {name -like "SRV1*"} 
    -SearchBase "OU=SERVERS,OU=INFRASTRUTURE,DC=dc,DC=local" -Properties * | 
    % {(get-date($_.LastLogonDate)).ToString("dd.MM.yyyy") -gt (Get-date).adddays(-20).ToString("dd.MM.yyyy")})
foreach ($srv in $MachineName) {
    $srv = "srv123"
    $usersPath = "\\$srv\C$\users"
    $users = @( Get-ChildItem $usersPath -Exclude Администратор, Public, TEMP*)
    foreach ($user in $users) {
        $login = Get-ADUser $user.name
        $ProfilePath = $usersPath +"\"+$user.name
        Write-Host $login.DistinguishedName
        if (($login.enabled -eq $false) -and (($login.DistinguishedName -like "*,OU=Корзина (уволеные пользователи),DC=dc,DC=local") -or ($login.DistinguishedName -like "*,OU=USERS,OU=INFRASTRUTURE,DC=dc,DC=local"))) {
            Get-WmiObject Win32_UserProfile -ComputerName $srv | Where-Object {($_.LocalPath -like $ProfilePath)} | % {$_.Delete()}
            }
        else {
            Get-childitem $ProfilePath\AppData\Local\1C\1cv8 -Filter "*-*-*-*-*" | Remove-Item -Recurse -Force 
        } 
    }
}