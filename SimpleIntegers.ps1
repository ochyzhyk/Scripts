[int []] $a = 333, 11, 26, 79, 15647
[int []] $b = 2, 3, 5, 7

foreach ( $i in $a )
{
    [string] $result = ""
    foreach ($j in $b)
    {
        [int] $c = $i % $j
        $result = $result + [Convert]::ToString($c)
    }
    if (!$result.Contains("0"))
        {
         "{0} is simple integer" -f $i
        }
} 

class test
{
    [string] test2()
    {
        return "test"
    }

}

$test = New-Object test
$test.test2()


Add-Type -AssemblyName Microsoft.ActiveDirectory.Management
$users = New-Object Microsoft.ActiveDirectory.Management.ADUser
$users.SamAccountName = ""
$users.psobject.Properties
$users.Enabled
$users.GivenName = ""
$users | gm -force . = 'displayName = ""'
New-ADUser $users

$users = Get-ADUser -Filter "SamAccountName -like ''"
$users.DistinguishedName



$user = "SamAccountName = test"
$users = new-object Microsoft.ActiveDirectory.Management.ADUser 
$users.DistinguishedName
Get-ADUser | Get-Member

add-type -AssemblyName "System.Windows.Forms"
$massagebox = new-object System.Windows.Forms.MessageBox
[System.Windows.Forms.MessageBox]::Show(

Add-Type -AssemblyName PresentationCore,PresentationFramework
$ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
$MessageIcon = [System.Windows.MessageBoxImage]::Question
$MessageBody = "Are you sure you want to delete the log file?"
$MessageTitle = "Confirm Deletion"
 
$Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
 
Write-Host "Your choice is $Result"


$env:PSModulePath

$ErrorActionPreference
Get-Content -Path C:\File\*


$name = ""
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, (Get-ADDomain).Name)
#$ctx | gm -Force
$user = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($ctx,[System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName, $Name)
$user | gm -Force
New-aduser -Name ""
$user = Get-ADUser -Filter {Name -like ""}
$user.GivenName = ""
$user.UserPrincipalName = ""
$user.EmailAddress = ""
$user.set_MiddleName("")
$user.set_Enabled($True)
$user.Save
Set-ADUser -Identity $name

get-aduser -Filter {name -like ""}