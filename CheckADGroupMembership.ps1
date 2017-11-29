$names = Get-Content -Encoding utf8 "D:\names.txt"
foreach ($name in $names) {
#$name = "user"
#Write-Host "$name"
$bool=Get-ADGroupMember "CN=group,OU=GROUPS,OU=INFRASTRUTURE,DC=dc,DC=local" | Select-Object name | Where-Object {$_ -match "$name"}
if (!$bool) {
Write-Host "$name not exist"
}
<#else{
Write-Host "not exist"
}#>
}