$WebClient = New-Object System.Net.WebClient
#$WebClient.Headers.Add("User-Agent","Mozilla/4.0+")        
$WebClient.Proxy = [System.Net.WebRequest]::DefaultWebProxy
$WebClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$WebClient.DownloadFile("http://go.microsoft.com/fwlink/?LinkID=87341&clcid=0x409","D:\install\mpam-fe(x64).exe")
