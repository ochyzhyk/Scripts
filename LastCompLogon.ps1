Get-ADComputer -Filter { name -Like '*wks-it01*' } -Properties lastlogontimestamp | 
Select-Object @{n="Computer";e={$_.Name}}, @{Name="Lastlogon"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}
