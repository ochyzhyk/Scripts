#To create a new custom PowerShell drive for a vSphere datastore:
#Connect to an ESX/ESXi host or vCenter Server using PowerCLI:

Connect-VIServer -Server ServerNameOrIPAddress

#Get a datastore object:

$datastore = Get-Datastore "MyDatastoreName"

#Create a new PowerShell drive, such as ds:, that maps to $datastore:

New-PSDrive -Location $datastore -Name ds -PSProvider VimDatastore -Root "\"

#Change locations into the PowerShell drive using the Set-Location command:

#Set-Location PowerShellDriveName:\

Set-Location ds:\

#Copy the source file or directory to a destination using the Copy-DatastoreItem command:

Copy-DatastoreItem "\\srv05\install$\ISO\Windows Server\W2K12R2_EN.ISO" ds:\ISO