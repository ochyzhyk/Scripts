$DomainControllers = Get-ADDomainController -Filter *

Foreach($DC in $DomainControllers)

 {
Write-Host $DC.Hostname
Get-ADUser -Identity root -Server $DC.Hostname -Properties AccountLockoutTime,LastBadPasswordAttempt,BadPwdCount,LockedOut

}



$DomainControllers = Get-ADDomainController -Filter *

Foreach($DC in $DomainControllers)

{
$events = Get-WinEvent -ComputerName $DC.Hostname -FilterHashtable @{Logname = 'Security';ID=4740}
$events | where {$_.message -like "*user*" } | fl *
}


$a=Get-ADGroup -Filter 'name -like "*user.group*"'
$a.Name | sort 

Get-ADGroupMember -Identity user.group | % name

