#---------------Create file with secure string---------------------
#---In popup window need to set your password for authentification-
 
#$Secure = Read-Host -AsSecureString
#$Encrypted = ConvertFrom-SecureString -SecureString $Secure -Key (1..16)
#$Encrypted | Out-File D:\Scripts\Password.txt

#---------------Login to Azure-------------------------------------

$pass = Get-Content D:\Scripts\Password.txt | ConvertTo-SecureString -Key (1..16)
$cred = New-Object -TypeName pscredential –ArgumentList "login@tenant.com", $pass
Connect-MsolService -Credential $cred # –TenantId <id>

#---------------Start VMs------------------------------------------
import-Module msonline


$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$excelWB = $excel.Workbooks.Add()
$excelWS = $excel.Worksheets.Item(1)

#$excelWS.Cells | gm -Force
#$excel
[string []] $properties = @("DisplayName","ФИО","Должность","Департамент","Компания","Лицензия","UPN")
for ([int]$i=1; $i -le ([string []] $properties).Count; $i++)
{
    $excelWS.Cells.Item(1,$i) = "{0}" -f $properties[$i-1]
    $excelWS.Cells.Item(1,$i).Interior.ColorIndex = 15
    $excelWS.Cells.Item(1,$i).Borders.linestyle = 1
    $excelWS.Cells.Item(1,$i).Borders.Weight = 2
}

$users = @(Get-MsolUser -MaxResults 9000 | ? isLicensed -eq $true)
[int]$n = 2
$users | foreach({
    $licences = $_.Licenses.accountskuid
    if($licences.count -gt 1)
    {
        for ([int]$i=0; $i -lt $licences.count; $i++){
            $license += $licences[$i]+" "
        }
        $licences = $license
        $license = ""
    }
    $upn = $_.UserPrincipalName
    $dn = $_.DisplayName
    $bc = $_.BlockCredential
    $title = $_.title
    $dep = $_.Department
    $aduser = "user" #get-aduser $dn -property decription,company
    $fio = "desc" #$aduser.description
    $company = "Comp" #$aduser.company
    $userProperties = @($dn,$fio,$title,$dep,$company,$licences,$upn)
    for ([int]$k=1; $k -le ([string []] $userProperties).Count; $k++)
    {        
        $excelWS.Cells.Item($n,$k) = "{0}" -f $userProperties[$k-1]
        $excelWS.Columns($k).Autofit() 
    }
    $n++
})


$users = Get-MsolUser -UserPrincipalName login@tenant.com | Where-Object {$_.isLicensed -eq $true}
$user.Licenses.accountskuid
