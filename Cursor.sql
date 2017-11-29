-----Script does three operations:
-- 1.Create folder if it does not exist.
-- 2.Backups all user databases.
-- 3.Verify archeves with checksum.

DECLARE @ArcStore nvarchar(1000)
DECLARE @date varchar(20)
DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)
SET @ArcStore = '\\srvbkp.dc.local\Backup$\Daily\'  -- Storage for archives
SET @date = REPLACE(CONVERT(VARCHAR(11),GETDATE()-1,120),'-','_')

-- Checks folders for archive on file storage and inserts their names into temporary table.  
INSERT INTO @DirTree(subdirectory, depth)
EXEC master.sys.xp_dirtree @ArcStore

-- Uses cursor, counts user databases and performs actions for each. 
DECLARE @Cursor CURSOR
DECLARE @name nvarchar (500)

BEGIN  
	SET @Cursor = CURSOR FOR
	SELECT name FROM master.dbo.sysdatabases WHERE name NOT IN
	('master', 'tempdb', 'msdb', 'model')
	
	OPEN @Cursor 
    FETCH NEXT FROM @Cursor INTO @name

    WHILE @@FETCH_STATUS = 0
    BEGIN
	
	DECLARE @BckName varchar(100)
	DECLARE @path varchar (1000)
	DECLARE @BckPath varchar (1000)
	DECLARE @SQL varchar (1000)
	SELECT @BckName = @name+'_backup_'+ @date
	SELECT @path = @ArcStore + @name +'\'
	SELECT @BckPath = @ArcStore + @name +'\'+@BckName+'.bak'
	
	-- Create folder for archive if it does not exist. 
	IF NOT EXISTS (SELECT 1 FROM @DirTree WHERE subdirectory = @name)
	BEGIN
		EXEC master.dbo.xp_create_subdir @Path
	END
	
	-- Backup user databases.
	SET @SQL = 'BACKUP DATABASE ['+ @name +'] TO  DISK = '+@BckPath+' WITH NOFORMAT, NOINIT, CHECKSUM, NAME = '+@BckName+', SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10'
    --PRINT @SQL
    EXECUTE master.sys.sp_executesql @sql
   
    -- Verify archives.
    RESTORE VERIFYONLY FROM DISK = @BckPath WITH CHECKSUM
	
	FETCH NEXT FROM @Cursor INTO @name
    END; 
    
    CLOSE @Cursor;
    DEALLOCATE @Cursor;
END;