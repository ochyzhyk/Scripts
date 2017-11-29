DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)

INSERT INTO @DirTree(subdirectory, depth)
EXEC master.sys.xp_dirtree '\\srv.dc.local\Backup$\Daily\'
SELECT subdirectory FROM @DirTree
SELECT * FROM master.dbo.sysdatabases