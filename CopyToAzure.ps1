$bak_path = "D:\"
$blobContext = New-AzureStorageContext -StorageAccountName "<name>" -StorageAccountKey "<key>"
$file=get-childitem -path $bak_path -Filter "*.zip" | 
    where-object { -not $_.PSIsContainer } | 
    sort-object -Property $_.CreationTime | 
    select-object -last 1
Set-AzureStorageBlobContent -File $file.fullname -Container "conteainer" -Blob $file.name -Context $blobContext -Force