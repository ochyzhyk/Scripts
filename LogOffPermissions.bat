for /F %%i in (
D:\Scripts\SRV-RDS170317.txt
) do (start cmd /k psexec \\%%i -u ulf\chyzhyko_m -p DenFunded26 -e D:\Scripts\wmic.bat)

