cls
Write-Host "Введите имя пользователя"
$user = Read-Host 
$login = Get-ADUser -Filter 'Name -like $user'
#$login
Write-Host "Обработка пользователя "$login.SamAccountName"..."
Disable-ADAccount -Identity $login.SamAccountName
Move-ADObject -Identity $login.DistinguishedName -TargetPath "OU=Корзина (уволеные пользователи),DC=ulf,DC=local"
$login = Get-ADUser -Filter 'Name -like $user'
Write-Host $login.DistinguishedName
if ($login.enabled -eq $false) {
    Write-Host "Обліковий запис заблоковано"}
    else {
    Write-Host "Not disabled"
    } 