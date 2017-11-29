$MachineName = Gc "C:\Users\user\Desktop\srv.txt"
foreach ($srv in $MachineName) {
    #$srv = "srv122"
    $usersPath = "\\$srv\C$\users"
    $users = @( Get-ChildItem $usersPath -Exclude Администратор, Public)
    $users
    foreach ($user in $users) {
        $login = Get-ADUser $user.name
        Write-Host $login.DistinguishedName
        if (($login.enabled -eq $false) -and ($login.DistinguishedName -like "*,OU=Корзина (уволеные пользователи),DC=dc,DC=local")) {
            $ProfilePath = "C:\Users\"+$user.name
            Get-WmiObject Win32_UserProfile -ComputerName $srv | Where-Object {($_.LocalPath -like $ProfilePath)} | % {$_.Delete()}
            Write-Host "User profile has been deleted:" $ProfilePath}
        else {
            Write-Host "Not disabled"
        } 
    }
}