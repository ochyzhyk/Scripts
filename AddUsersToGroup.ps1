function Add-UserToGroup ($Group)
    {  
    Add-ADGroupMember $group -Members $login
    Write-Host "Пользователь:`n"$login.SamAccountName `n"Добавлен в групу `n$Group"
    }

function Remove-UserSwitch ($groups)
{
   
    $switch = "`n`$ct = Read-Host"
    $switch += "`nswitch (`$ct) {"
    $i = 1
    
    foreach ($gr in $groups) {
        
        $a = $gr.IndexOf("-") - 1
        $b = $gr.IndexOf(",")
        $gr = $gr.Substring($a, $b - $a )

        $write += "`n`t$i Удалить из $gr"
        $switch += "`n`t$i {""Удаление из $gr"";  Remove-UserFromGroup (""$gr"")}"
        $i++
        }
    $switch += "`n}"
    write $write
    #write $switch
    Invoke-Expression $switch
}

function Remove-UserFromGroup ($gr)
    {
    #foreach ($gr in $groups) {
        
    #    $a = $gr.IndexOf("-") - 1
    #    $b = $gr.IndexOf(",")
    #    $gr = $gr.Substring($a, $b - $a )
                     
        $title = "Удаление пользователя из группы $gr"
        $message = "Удаление пользователя из группы $gr"
        
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
           "Пользователь удален из группы."
                $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
           "Отмена удаления пользователя из группы."
        
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, $message, $options, 0)
        
        
        switch ($result)
            {
            0 {Remove-ADGroupMember -Identity $gr -Members $login 
                    "Пользователь $login удален из группы. $gr"}
            1 {"Отмена удаления."}
            }
        }
    # }

 


###-------------------------------------------------------------

do {
cls

Write-Host "Введите имя пользователя"
$user = Read-Host
write ""

$login = Get-ADUser -Filter 'Name -like $user'
$cn = $login.DistinguishedName
$adsiuser = [ADSI]"LDAP://$cn"
$groups = $adsiuser.Memberof | ? {$_ -like "*g-svc-ovpn1*"} 

 

if ($groups)
{
    foreach ($gr in $groups)
        {
        $a = $gr.IndexOf("-") - 1
        $b = $gr.IndexOf(",")
        $gr = $gr.Substring($a, $b - $a )
        $SamAccountName = $login.SamAccountName
        write "Пользователю $SamAccountName предоставлен доступ к $gr"
        write "---------------------------------------------------------------------"
    }
}
    
Write-Host "`n`nДля предоставления доступа выберите групу`n 
    1 - mail_rds 
    2 - sharepoint 
    3 - lucanet 
    4 - fullaccess 
    5 - regadmin 
    6 - mail_rds_GPS
    7 - Удалить из группы`n"

$count = Read-Host

switch ($count)
    {
        1 {; Add-UserToGroup ("mail_rds")}
        2 {; Add-UserToGroup ("sharepoint")}
        3 {; Add-UserToGroup ("lucanet")}
        4 {; Add-UserToGroup ("fullaccess")}
        5 {; Add-UserToGroup ("regadmins")}
        6 {; Add-UserToGroup ("mail_rds_GPS")}
#        7 {; Remove-UserFromGroup  }
        7 {; Remove-UserSwitch ($groups)}
        default {"Выберите группу"}
    }
 
 Write-Host "Для выхода нажмите 'q' Для продолжения 'Enter' "
 
 $exit = Read-Host

 switch ($exit)
    {
        q {"Выход"; $flag = $false}
        default{$flag = $true}
    }
 }
 while ($flag)

