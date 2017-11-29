$date = (get-date).ToString("dd.MM.yyyy")
$OutFile =  "D:\Scripts\3PARFailedDisks\3PAR_Failed_disk_{0}.txt" -f $date

#Import-Module -Name posh-ssh
Import-Module -Name ".\Posh-SSH" -Verbose
New-SSHSession -ComputerName "10.10.10.10"

$a = (Get-SSHSession | select -Last 1).SessionId
#$a = $a.SessionId

$cmds = @(
    "showsys",
    "showversion",
    "showpd -c",
    "showpd -failed -degraded",
    "showpd -i",
    "showpd -s"
    "servicemag status -d"
)

"`n#$([DateTime]::Now.ToString())" | Out-File -FilePath $OutFile

foreach ($cmd in $cmds)
{
"`n#$cmd" | Out-File -FilePath $OutFile -Append
Invoke-SSHCommand -Index $a -Command "$cmd" | select -ExpandProperty Output | Out-File -FilePath $OutFile -Append
}

Remove-SSHSession -SessionId $a
