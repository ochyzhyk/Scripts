for /F %%i in (
D:\Scripts\SRV170317.txt
) do (start cmd /k psexec \\%%i -u domain\user -p password -e D:\Scripts\wmic.bat)

