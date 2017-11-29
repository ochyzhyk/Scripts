$name = "user_test"
$user = Get-ADUser -Filter {name -like $name}
#$aduser = "LDAP://{0}" -f $user.DistinguishedName
#[adsi]$adsiuser = $aduser
[adsi]$adsiuser = "LDAP://{0}" -f $user.DistinguishedName
$adsiuser | gm -Force
#$aduser.Add("g-svc-ovpn1-mail_rds")
$adsiuser.Username.add("user_test")
#$aduser.setinfo
$adsiuser.put("EmployeeID", "user_test") #| select *
$adsiuser.setinfo()
$adsiuser.RefreshCache()

##########Рабочий код##########

[ADSI]$OU = "LDAP://CN=Users,DC=dc,DC=local"
$new = $ou.create("user","CN=user_test")
$new.put("sAMAccountName", "user_test")
$new.put("EmployeeID", "123456789")
$new.put("userAccountControl", "546")  ##546 - account disabled, 544 - enabled
$new.put("userPrincipalName", "user_test@dc.local")
$ou | gm -Force
$new.setinfo()
$new.refreshcache()

[string]$group = (Get-ADGroup -Filter {name -like "group"}).DistinguishedName
$group.GetType()
[adsi]$group = "LDAP://$group"
$group.Member
$group.Member.Add(($new.distinguishedName).ToString())
$group.psbase.CommitChanges()

##########Рабочий код##########

$new | select *

Get-Module -ListAvailable

Import-Module -Name ActiveDirectory