DECLARE @command varchar(8000)

SELECT @command = 'IF ''?'' NOT IN (''master'', ''msdb'', ''tempdb'', ''model'')
BEGIN USE [?] EXEC(''
DECLARE @DataPath nvarchar(500)
DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)
SELECT @DataPath = ''''\\srvbkp.dc.local\Backup$\Daily\'''' + ''''?''''
INSERT INTO @DirTree(subdirectory, depth)
EXEC master.sys.xp_dirtree ''''\\srvbkp.dc.local\Backup$\Daily\''''
IF NOT EXISTS (SELECT 1 FROM @DirTree WHERE subdirectory = ''''?'''')
EXEC master.dbo.xp_create_subdir @DataPath
'') END'
EXEC sp_MSforeachdb @command

--EXEC master.dbo.xp_create_subdir @DataPath