#http://jongurgul.com/blog/get-stringhash-get-filehash/
$string = "30066900050"
Function Get-StringHash([String] $String,$HashName = "MD5")
{
    $StringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
        [Void]$StringBuilder.Append($_.ToString("x2"))
    }
$StringBuilder.ToString()
}

Get-StringHash