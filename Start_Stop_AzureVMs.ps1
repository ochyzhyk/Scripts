#---------------Create file with secure string---------------------
#---In popup window need to set your password for authentification-
 
#$Secure = Read-Host -AsSecureString
#$Encrypted = ConvertFrom-SecureString -SecureString $Secure -Key (1..16)
#$Encrypted | Out-File D:\Scripts\Password.txt

#---------------Login to Azure-------------------------------------

$pass = Get-Content D:\Scripts\Password.txt | ConvertTo-SecureString -Key (1..16)
$cred = New-Object -TypeName pscredential –ArgumentList "admin@<tenant>.onmicrosoft.com", $pass
Login-AzureRmAccount -Credential $cred –TenantId <id>

#---------------Start VMs------------------------------------------

Start-AzurermVM -ResourceGroupName RS_01 -Name server
Start-Sleep -s 300

