psexec \\srv09 -d powershell -command "& {Enable-PSRemoting -force}"
Enter-PSSession -ComputerName srv09
(get-item -Path "C:\Windows\System32\mstsc.exe").versioninfo | select ProductVersion | Out-File \\share\psexec.txt