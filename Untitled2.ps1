﻿#$webclient = New-Object System.Net.WebClient
#$url = "https://github.com/darkoperator/Posh-SSH/archive/master.zip"
#Write-Host "Downloading latest version of Posh-SSH from $url" -ForegroundColor Cyan
$file = "$($env:TEMP)\Posh-SSH.zip"
#$webclient.DownloadFile($url,$file)
#Write-Host "File saved to $file" -ForegroundColor Green
$targetondisk = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
New-Item -ItemType Directory -Force -Path $targetondisk | out-null
$shell_app=new-object -com shell.application
$zip_file = $shell_app.namespace($file)
Write-Host "Uncompressing the Zip file to $($targetondisk)" -ForegroundColor Cyan
$destination = $shell_app.namespace($targetondisk)
$destination.Copyhere($zip_file.items(), 0x10)
Write-Host "Renaming folder" -ForegroundColor Cyan
Rename-Item -Path ($targetondisk+"\Posh-SSH-master") -NewName "Posh-SSH" -Force
Write-Host "Module has been installed" -ForegroundColor Green
Import-Module -Name posh-ssh
Get-Command -Module Posh-SSH