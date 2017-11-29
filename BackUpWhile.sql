DECLARE @ArcStore nvarchar(1000)
DECLARE @date varchar(20)
DECLARE @Name varchar(100)
DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)
DECLARE @i int
DECLARE @RowNum int
DECLARE @BckName varchar(100)
DECLARE @path varchar (200)
DECLARE @BckPath varchar (200)

SET @ArcStore = '\\srvbkp.dc.local\Backup\Daily\'  -- Storage for archives
SET @date = LEFT(REPLACE(CONVERT(VARCHAR(11),GETDATE(),120),'-','_'),10)
Select @RowNum = MAX(dbid) FROM master.dbo.sysdatabases

set @i=5
WHILE @RowNum >= @i
BEGIN

	SELECT @Name = name from master.dbo.sysdatabases where dbid = @i
	IF (@Name IS NULL)
	BEGIN
		GOTO NEXT
	END
	
	SELECT @BckName = @name+'_backup_'+ @date
	SELECT @path = @ArcStore + @name +'\'
	SELECT @BckPath = @ArcStore + @name +'\'+@BckName+ '.bak'
	
	
	IF NOT EXISTS (SELECT 1 FROM @DirTree WHERE subdirectory = @name)
	BEGIN
		EXEC master.dbo.xp_create_subdir @Path
	END
	
	--PRINT @BckPath
	--PRINT @Path
	BACKUP DATABASE @name TO  DISK = @BckPath WITH NOFORMAT, NOINIT, CHECKSUM, NAME = @BckName, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10
	
	RESTORE VERIFYONLY FROM DISK = @BckPath WITH CHECKSUM
	
	--PRINT @Name
	NEXT:
	set @i = @i+1
	SET @Name = NULL
END