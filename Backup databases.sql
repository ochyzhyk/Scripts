DECLARE @command varchar(8000)

SELECT @command = 'IF ''?'' NOT IN (''master'', ''msdb'', ''tempdb'', ''model'')
BEGIN USE [?] EXEC(''
DECLARE @date varchar(20)
DECLARE @name varchar(100)
DECLARE @path varchar (1000)
SELECT @date = REPLACE(CONVERT(VARCHAR(11),GETDATE(),120),''''-'''',''''_'''')
SELECT @name = ''''?''''+''''_backup_'''' + @date
SELECT @path = ''''\\srvbkp.dc.local\Backup$\Daily\'''' + ''''?''''+''''\''''+ @name + ''''.bak''''
BACKUP DATABASE [?] TO  DISK = @path WITH NOFORMAT, NOINIT, CHECKSUM, NAME = @name, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10
RESTORE VERIFYONLY FROM DISK = @path WITH CHECKSUM
'') END'
EXEC sp_MSforeachdb @command