$MachineName = @(Get-ADComputer -SearchBase "OU=SERVERS,OU=INFRASTRUTURE,DC=dc,DC=local" -Filter 'name -like "srv1*" -or name -like "srv2*"' | % name)
#Gc "C:\Users\user\Desktop\rds.txt"
foreach ($srv in $MachineName) {
    Write-Host $srv
    $usersPath = "\\$srv\C$\users"
    $users = @( Get-ChildItem $usersPath -Exclude Администратор, Public, TEMP*, MSSQL*)
    foreach ($user in $users) {
        $login = Get-ADUser $user.Name
        Write-Host $login.DistinguishedName
        if (($login.enabled -eq $false) -and (($login.DistinguishedName -like "*,OU=Корзина (уволеные пользователи),DC=dc,DC=local") -or ($login.DistinguishedName -like "OU=USERS,OU=INFRASTRUTURE,DC=dc,DC=local"))) {
            $ProfilePath = "C:\Users\"+$user.name
            Get-WmiObject Win32_UserProfile -ComputerName $srv | Where-Object {($_.LocalPath -like $ProfilePath)} | % {$_.Delete()}
            Write-Host "User profile has been deleted:" $ProfilePath}
        if (Test-Path $user\AppData\Local\1C) {
            Get-childitem $user\AppData\Local\1C\1cv8 -Filter "*-*-*-*-*" | Remove-Item -Recurse -Force
        } 
    }
}