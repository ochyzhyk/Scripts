$Username = "domain\user"
$Password = ""

$webclient = New-Object Net.WebClient
$webclient.Credentials = New-Object System.Net.Networkcredential($Username, $Password)
$webclient.Proxy = New-Object System.Net.WebProxy("proxy.dc.local", "3128")

iex ($webclient).DownloadString("https://www.google.com.ua")
#iex ($webclient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")

 
$PSVersionTable.PSVersion

Class function
{
    


}