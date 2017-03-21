#---------------Create file with secure string---------------------
#---In popup window need to set your password for authentification-
 
#$Secure = Read-Host -AsSecureString
#$Encrypted = ConvertFrom-SecureString -SecureString $Secure -Key (1..16)
#$Encrypted | Out-File D:\Scripts\Password.txt

#---------------Login to Azure-------------------------------------

$pass = Get-Content D:\Scripts\Password.txt | ConvertTo-SecureString -Key (1..16)
$cred = New-Object -TypeName pscredential –ArgumentList "admin@ulfcomua.onmicrosoft.com", $pass
Login-AzureRmAccount -Credential $cred –TenantId 37bc5f60-6e4e-4094-b24f-2f7448f5a816

#---------------Start VMs------------------------------------------

Start-AzurermVM -ResourceGroupName ULF_RS_01 -Name srv-dc100
Start-Sleep -s 300
Start-AzurermVM -ResourceGroupName ULF_RS_01 -Name srv-adfs01
Start-AzurermVM -ResourceGroupName ULF_RS_01 -Name srv-adfs-prx01
Start-AzurermVM -ResourceGroupName ULF_RS_01 -Name srv-mfa102
Start-AzurermVM -ResourceGroupName ULF_RS_01 -Name SRV-RDS400
