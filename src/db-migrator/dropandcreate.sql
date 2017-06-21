:SETVAR DatabaseName "barmgmt"
:SETVAR DbPassword "baruser"
:SETVAR DbUserName "baruser"

USE master
GO

IF (EXISTS(SELECT name FROM sys.databases WHERE name = '$(DatabaseName)'))
	BEGIN;
		ALTER DATABASE [$(DatabaseName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		ALTER DATABASE [$(DatabaseName)] SET  MULTI_USER;
		DROP DATABASE [$(DatabaseName)];
	END;

IF (NOT EXISTS(SELECT name FROM sys.databases WHERE name = '$(DatabaseName)'))
	BEGIN;
		CREATE DATABASE [$(DatabaseName)];
	END;

IF NOT EXISTS(SELECT * FROM sys.server_principals WHERE name = N'$(DbUsername)')
	BEGIN;
	CREATE LOGIN [$(DbUsername)] WITH PASSWORD=N'$(DbPassword)',DEFAULT_DATABASE=[$(DatabaseName)],
		CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
	END;

-- enable caching
ALTER DATABASE [$(DatabaseName)] SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
-- set simple recovery
ALTER DATABASE [$(DatabaseName)] SET RECOVERY SIMPLE;

-- set up read committed snapshot to prevent table locking during reads
ALTER DATABASE [$(DatabaseName)] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;

USE [$(DatabaseName)]
GO

IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = '$(DbUsername)')
	BEGIN;
		CREATE USER [$(DbUsername)] FOR LOGIN [$(DbUsername)] WITH DEFAULT_SCHEMA=[dbo]
	END;

IF NOT EXISTS(SELECT * FROM sys.schemas WHERE name = 'sql_dependency_starter')
	BEGIN;
		CREATE ROLE sql_dependency_subscriber AUTHORIZATION [dbo];
	END;


IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'sql_dependency_subscriber' AND type = 'R')
	BEGIN;
		-- use dbo schema for authorization
		EXEC('CREATE SCHEMA sql_dependency_subscriber AUTHORIZATION [dbo];')
	END;

IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'sql_dependency_starter' AND type = 'R')
	BEGIN;
		-- use dbo schema for authorization
		EXEC('CREATE SCHEMA sql_dependency_starter AUTHORIZATION [dbo];')
	END;
	
IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'sql_dependency_subscriber' AND type = 'R')
	BEGIN;
		-- use dbo schema for authorization
		CREATE ROLE sql_dependency_subscriber AUTHORIZATION [dbo];
	END;
	
IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'sql_dependency_starter' AND type = 'R')
	BEGIN;
		-- use dbo schema for authorization
		CREATE ROLE sql_dependency_starter AUTHORIZATION [dbo];
	END;

DECLARE @RoleName sysname, @RoleMemberName sysname;

SET @RoleName = N'sql_dependency_subscriber';
IF EXISTS(SELECT * FROM sys.database_principals WHERE name = @RoleName AND type = 'R')
	BEGIN;
		DECLARE MemberCursor CURSOR FOR
		SELECT [name] FROM sys.database_principals 
			WHERE principal_id IN (
			SELECT member_principal_id  FROM sys.database_role_members
			WHERE role_principal_id IN 
			(SELECT principal_id FROM sys.database_principals WHERE [name] = @RoleName AND type = 'R'));
		OPEN MemberCursor;
		FETCH NEXT FROM MemberCursor INTO @RoleMemberName;
		WHILE @@FETCH_STATUS = 0
		BEGIN;
			EXEC sys.sp_droprolemember @rolename = @RoleName, -- sysname
				@membername = @RoleMemberName -- sysname
			FETCH NEXT FROM MemberCursor INTO @RoleMemberName;
		END;
		CLOSE MemberCursor;
		DEALLOCATE MemberCursor;
	END;

SET @RoleName = N'sql_dependency_starter';
IF EXISTS(SELECT * FROM sys.database_principals WHERE name = @RoleName AND type = 'R')
	BEGIN;
		DECLARE MemberCursor CURSOR FOR
		SELECT [name] FROM sys.database_principals 
			WHERE principal_id IN (
			SELECT member_principal_id  FROM sys.database_role_members
			WHERE role_principal_id IN 
			(SELECT principal_id FROM sys.database_principals WHERE [name] = @RoleName AND type = 'R'));
		OPEN MemberCursor;
		FETCH NEXT FROM MemberCursor INTO @RoleMemberName;
		WHILE @@FETCH_STATUS = 0
		BEGIN;
			EXEC sys.sp_droprolemember @rolename = @RoleName, -- sysname
				@membername = @RoleMemberName -- sysname
			FETCH NEXT FROM MemberCursor INTO @RoleMemberName;
		END;
		CLOSE MemberCursor;
		DEALLOCATE MemberCursor;
	END;

-- Permissions needed for [sql_dependency_starter]
GRANT CREATE PROCEDURE to [sql_dependency_starter];
GRANT CREATE QUEUE to [sql_dependency_starter];
GRANT CREATE SERVICE to [sql_dependency_starter];
GRANT REFERENCES ON CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] TO [sql_dependency_starter];
GRANT VIEW DEFINITION TO [sql_dependency_starter];

-- Permissions needed for [sql_dependency_subscriber]
GRANT SELECT to [sql_dependency_subscriber];
GRANT SUBSCRIBE QUERY NOTIFICATIONS TO [sql_dependency_subscriber];
GRANT RECEIVE ON QueryNotificationErrorsQueue TO [sql_dependency_subscriber];
GRANT REFERENCES ON CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] TO  [sql_dependency_subscriber];
EXEC sp_addrolemember 'sql_dependency_subscriber', '$(DbUsername)';

-- Create permissions for our schema
GRANT SELECT ON SCHEMA::[dbo] TO [$(DbUserName)];
GRANT INSERT ON SCHEMA::[dbo] TO [$(DbUserName)];
GRANT UPDATE ON SCHEMA::[dbo] TO [$(DbUserName)];
GRANT DELETE ON SCHEMA::[dbo] TO [$(DbUserName)];
GRANT EXECUTE ON SCHEMA::[dbo] TO [$(DbUserName)];