$bak_path = "D:\"
$blobContext = New-AzureStorageContext -StorageAccountName "ulffiles" -StorageAccountKey "Mb8V+SDJQNFlcitPO/kXA0k+RZWmyhd0mgMCC8JnYVfj6vbdPD1rkdf/bWvYfIH7vT55ZhqVVC5yiOC+kY7lPA=="
$file=get-childitem -path $bak_path -Filter "*.zip" | 
    where-object { -not $_.PSIsContainer } | 
    sort-object -Property $_.CreationTime | 
    select-object -last 1
Set-AzureStorageBlobContent -File $file.fullname -Container "backupazure01" -Blob $file.name -Context $blobContext -Force