$a=Get-Random -minimum 1001 -maximum 9999
$a
$b=Read-Host -Prompt "enter code"
if ($a = $b) {
    Write-Host "True"
    }
    else {
    Write-Host "False"
    }