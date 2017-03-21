$names = Get-Content -Encoding utf8 "D:\names.txt"
foreach ($name in $names) {
#$name = "Адаменко Микола Йосипович"
#Write-Host "$name"
$bool=Get-ADGroupMember "CN=_RDS.1C.UAH.Distributions,OU=_RDS,OU=App,OU=GROUPS,OU=INFRASTRUTURE,DC=ulf,DC=local" | Select-Object name | Where-Object {$_ -match "$name"}
if (!$bool) {
Write-Host "$name not exist"
}
<#else{
Write-Host "not exist"
}#>
}