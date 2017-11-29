DECLARE @ArcStore nvarchar(500)
DECLARE @date varchar(20)
DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)
SET @ArcStore = '\\srvbkp.dc.local\Backup$\Daily\' 
SET @date = LEFT(REPLACE(CONVERT(VARCHAR(11),GETDATE(),120),'-','_'),10)


INSERT INTO @DirTree(subdirectory, depth)
EXEC master.sys.xp_dirtree @ArcStore


DECLARE @Cursor CURSOR
DECLARE @name nvarchar (255)

BEGIN  
	SET @Cursor = CURSOR FOR
	SELECT name FROM master.dbo.sysdatabases WHERE dbid > 4  --name NOT IN ('master','model','msdb','tempdb')
	
	OPEN @Cursor 
    FETCH NEXT FROM @Cursor INTO @name

    WHILE @@FETCH_STATUS = 0
    BEGIN
	
	DECLARE @BckName varchar(100)
	DECLARE @path varchar (200)
	DECLARE @BckPath varchar (200)
	SELECT @BckName = @name+'_backup_'+ @date
	SELECT @path = @ArcStore + @name +'\'
	SELECT @BckPath = @ArcStore + @name +'\'+@BckName+ '.bak'
	

	IF NOT EXISTS (SELECT 1 FROM @DirTree WHERE subdirectory = @name)
	BEGIN
		EXEC master.dbo.xp_create_subdir @Path
	END
	PRINT @BckPath
	PRINT @Path
	--BACKUP DATABASE @name TO  DISK = @BckPath WITH NOFORMAT, NOINIT, CHECKSUM, NAME = @BckName, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10
	
	--RESTORE VERIFYONLY FROM DISK =@BckPath WITH CHECKSUM
	
	FETCH NEXT FROM @Cursor INTO @name
	END; 
	
	CLOSE @Cursor ;
	DEALLOCATE @Cursor;
END;