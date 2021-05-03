
--find all XXPPQQZZ 
-- individually replace as appropriate 
    CREATE SCHEMA ERR;
  
GO
USE [master];
--[]
CREATE DATABASE [CustomLog] CONTAINMENT = NONE ON PRIMARY (
	NAME = N'CustomLog'
	, FILENAME = N'XXPPQQZZ\CustomLog.mdf'
	, SIZE = 8192 KB
	, MAXSIZE = UNLIMITED
	, FILEGROWTH = 65536 KB
	) LOG ON (
	NAME = N'CustomLog_log'
	, FILENAME = N'XXPPQQZZ\CustomLog_log.ldf'
	, SIZE = 8192 KB
	, MAXSIZE = 2048 GB
	, FILEGROWTH = 65536 KB
	);

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
BEGIN
	EXEC [CustomLog].[dbo].[sp_fulltext_database] @action = 'enable'
END;

ALTER DATABASE [CustomLog] SET ANSI_NULL_DEFAULT OFF;

ALTER DATABASE [CustomLog] SET ANSI_NULLS OFF;

ALTER DATABASE [CustomLog] SET ANSI_PADDING OFF;

ALTER DATABASE [CustomLog] SET ANSI_WARNINGS OFF;

ALTER DATABASE [CustomLog] SET ARITHABORT OFF;

ALTER DATABASE [CustomLog] SET AUTO_CLOSE OFF;

ALTER DATABASE [CustomLog] SET AUTO_SHRINK OFF;

ALTER DATABASE [CustomLog] SET AUTO_UPDATE_STATISTICS ON;

ALTER DATABASE [CustomLog] SET CURSOR_CLOSE_ON_COMMIT OFF;

ALTER DATABASE [CustomLog] SET CURSOR_DEFAULT  GLOBAL;

ALTER DATABASE [CustomLog] SET CONCAT_NULL_YIELDS_NULL OFF;

ALTER DATABASE [CustomLog] SET NUMERIC_ROUNDABORT OFF;

ALTER DATABASE [CustomLog] SET QUOTED_IDENTIFIER OFF;

ALTER DATABASE [CustomLog] SET RECURSIVE_TRIGGERS OFF;

ALTER DATABASE [CustomLog] SET  ENABLE_BROKER;

ALTER DATABASE [CustomLog] SET AUTO_UPDATE_STATISTICS_ASYNC OFF;

ALTER DATABASE [CustomLog] SET DATE_CORRELATION_OPTIMIZATION OFF;

ALTER DATABASE [CustomLog] SET TRUSTWORTHY OFF;

ALTER DATABASE [CustomLog] SET ALLOW_SNAPSHOT_ISOLATION OFF;

ALTER DATABASE [CustomLog] SET PARAMETERIZATION SIMPLE;

ALTER DATABASE [CustomLog] SET READ_COMMITTED_SNAPSHOT OFF;

ALTER DATABASE [CustomLog] SET HONOR_BROKER_PRIORITY OFF;

ALTER DATABASE [CustomLog] SET RECOVERY FULL;

ALTER DATABASE [CustomLog] SET  MULTI_USER;

ALTER DATABASE [CustomLog] SET PAGE_VERIFY CHECKSUM ;

ALTER DATABASE [CustomLog] SET DB_CHAINING OFF;

ALTER DATABASE [CustomLog] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF );

ALTER DATABASE [CustomLog] SET TARGET_RECOVERY_TIME = 60 SECONDS;

ALTER DATABASE [CustomLog] SET DELAYED_DURABILITY = DISABLED;

ALTER DATABASE [CustomLog] SET QUERY_STORE = OFF;

ALTER DATABASE [CustomLog] SET  READ_WRITE;

ALTER DATABASE [CustomLog] 
   COLLATE Latin1_General_CS_AS; --case sensitivity is important damn it! -- Babler


USE [master];
CREATE LOGIN [Owner_CustomLog]
	WITH PASSWORD = N'XXPPQQZZ'
		, DEFAULT_DATABASE = [master]
		, CHECK_EXPIRATION = OFF
		, CHECK_POLICY = OFF;

USE [CustomLog];
CREATE USER [Owner_CustomLog]
FOR LOGIN [Owner_CustomLog];

USE [CustomLog];
ALTER USER [Owner_CustomLog]
	WITH DEFAULT_SCHEMA = [dbo];

USE [CustomLog];
ALTER ROLE [db_owner] ADD MEMBER [Owner_CustomLog];

USE [master];
GRANT CONNECT SQL
	TO [Owner_CustomLog];


USE [master]



CREATE SERVER ROLE [CustomLog_Connecter] AUTHORIZATION [serveradmin]



ALTER SERVER ROLE [CustomLog_Connecter] ADD MEMBER [Owner_CustomLog]



use [master]



GRANT ALTER ON LOGIN::[Owner_CustomLog] TO [CustomLog_Connecter]



use [master]



GRANT CONTROL ON LOGIN::[Owner_CustomLog] TO [CustomLog_Connecter]



use [master]



GRANT VIEW DEFINITION ON LOGIN::[Owner_CustomLog] TO [CustomLog_Connecter]



use [master]



GRANT CONNECT ON ENDPOINT::[TSQL Default TCP] TO [CustomLog_Connecter]



use [master]



GRANT VIEW DEFINITION ON ENDPOINT::[TSQL Default TCP] TO [CustomLog_Connecter]




USE [CustomLog]
GO

/****** Object:  Table [ERR].[DB_EXCEPTION_TANK]    Script Date: 5/2/2021 9:21:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ERR].[DB_EXCEPTION_TANK] (
	[ErrorID] [int] IDENTITY(1, 1) NOT NULL
	, [DatabaseName] [varchar](80) NULL
	, [UserName] [varchar](100) NULL
	, [ErrorNumber] [int] NULL
	, [ErrorState] [int] NULL
	, [ErrorSeverity] [int] NULL
	, [ErrorLine] [int] NULL
	, [ErrorProcedure] [varchar](max) NULL
	, [ErrorMessage] [varchar](max) NULL
	, [ErrorDateTime] [datetime] NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
	, @value = N'This is for logging errors thrown by procedures and adhoc code blocks '
	, @level0type = N'SCHEMA'
	, @level0name = N'ERR'
	, @level1type = N'TABLE'
	, @level1name = N'DB_EXCEPTION_TANK'
GO


USE [Utility];
GO
-- ==========================================================================================
-- Author:		Dave Babler
-- Create date: 2021-01-31
-- Description:	Checks to see based on ***common naming conventions*** if the passed string 
-- 				is likely the name of a view instead of a table
-- 				Since this not going to be a program that will be called typically outside of another proc 
-- 				have left it's name in the traditional fn_ convention.
-- ==========================================================================================
CREATE
	OR

ALTER FUNCTION [DD].[fn_IsThisTheNameOfAView] (
	-- Add the parameters for the function here
	@ustrName NVARCHAR(64)
	)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @bitFlag BIT

	-- First Check to see if the 'table' name starts with a V if not assume not view and throw false flag
	IF LOWER(LEFT(@ustrName, 1)) = 'v'
	BEGIN
		SET @bitFlag = CASE 
				WHEN LOWER(LEFT(@ustrName, 4)) = 'view'
					THEN 1
				WHEN LOWER(LEFT(@ustrName, 3)) = 'viw'
					THEN 1
				WHEN LOWER(LEFT(@ustrName, 2)) = 'vw'
					THEN 1
				WHEN LOWER(LEFT(@ustrName, 2)) = 'v_'
					THEN 1
				ELSE 0
				END
	END
	ELSE
	BEGIN
		SET @bitFlag = 0
	END

	-- Return the result of the function
	RETURN @bitFlag
END
GO


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
/*
	 SELECT UTL.fn_IsThisTheNameOfAView('V_ofDATA'); 
*/
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvUSE [Utility];
GO


-- ======================================================================================
-- Author:		Dave Babler
-- Create date:	11/09/2020
-- Description:	Splits a dot object notation string and passes it out as a table
--              This is effectively a rehash of UTL_fn_DelimListToTable.
--				However, the author felt it was important to hard code the period for saftey, and
-- 				segregated it from functions that might be used in other procs. 
--				If the CTO wishes this method can be scrapped and the other used.
-- 				This does relate to the data dictionary ease of use programs and DD schema; however, 
-- 				Since this not going to be a program that will be called typically outside of another proc 
-- 				have left it's name in the traditional fn_ convention.
-- ======================================================================================
CREATE OR ALTER FUNCTION [DD].[fn_DBSchemaObjCheck] (  
	@strDelimitedStringToParse NVARCHAR(MAX)
	
	)
RETURNS @tblParsedList TABLE (ValueID INT, StringValue NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS)
AS
BEGIN      
DECLARE @charDelimiter CHAR = '.';
WITH RecursiveTable (
	StartingPosition
	, EndingPosition
	)
AS (
	SELECT CAST(1 AS BIGINT) StartingPosition
		, CHARINDEX(@charDelimiter, @strDelimitedStringToParse) EndingPosition
	--gets the first delimiter, the count of chars to the next one
	
	UNION ALL
	
	SELECT EndingPosition + 1
		, CHARINDEX(@charDelimiter, @strDelimitedStringToParse, EndingPosition + 1)
	--next number after the first Delimiter(starting pointer), go to next delimiter & mark that,
	FROM RecursiveTable --recursion calling from inside itself in the Common Table Expression
	WHERE EndingPosition > 0
		--keep going as long as there's more stuff in the list
	)
INSERT INTO @tblParsedList
SELECT ROW_NUMBER() OVER (
		ORDER BY (
				SELECT 1
				)
		) --Hackishway of making a sequential id.
	, TRIM(SUBSTRING(@strDelimitedStringToParse, StartingPosition, COALESCE(NULLIF(EndingPosition, 0), LEN(
				@strDelimitedStringToParse) + 1) - StartingPosition)) --TRIM to get rid of trailing spaces
FROM RecursiveTable
OPTION (MAXRECURSION 0);
                
        /**Here coalesce is what's allowing us to deal with lists where there are spaces around delimiters
         *   'red, orange , yellow,green,blue, purple'   It also helps us grab purple too--Dave Babler */
RETURN --RETURNS @tblParsedList 
END
GO

USE [Utility]
GO

-- ==========================================================================================
-- Author:			Dave Babler
-- Create date: 	2020-08-26
-- Last Updated:	2021-04-24
-- Description:		This makes adding comments to columns in SQLServer far more accessible than before.
--					Special Security Note:
-- 					The code AND [object_id] = OBJECT_ID() should prevent most injection. 
-- 					If it doesn't change to a proper ID the proc will fail.
-- ==========================================================================================
CREATE
	OR

ALTER PROCEDURE [DD].[AddColumnComment]
	-- Add the parameters for the stored procedure here
	@ustrFQON NVARCHAR(64)
	, @strColumnName NVARCHAR(64)
	, @strComment NVARCHAR(360)
AS
/**Note: vrt is for Variant, which is the absurd way SQL Server stores it's Strings in the data dictionary
* supposedly for 'security' --Dave Babler*/
DECLARE @vrtComment SQL_VARIANT
	, @strErrorMessage VARCHAR(MAX)
	, @ustrDatabaseName NVARCHAR(64)
	, @ustrSchemaName NVARCHAR(64)
	, @ustrTableorObjName NVARCHAR(64)
	, @dSQLNotExistCheck NVARCHAR(MAX)
	, @dSQLNotExistCheckProperties NVARCHAR(MAX) -- could recycle previous var, don't want to
	, @dSQLApplyComment NVARCHAR(MAX) -- will use the same  dynamic sql variable name regardless of wether or not we add or update hence 'apply'
	, @intRowCount INT
	, @boolExistFlag BIT
	, @ustrMessageOut NVARCHAR(400)
	, @bitIsThisAView BIT
	, @ustrViewOrTable NVARCHAR(8)
	;
DROP TABLE IF EXISTS #__SuppressOutputAddColumnComment;

DECLARE @boolCatchFlag BIT = 0;  -- for catching and throwing a specific error. 
	--set and internally cast the VARIANT, I know it's dumb, but it's what we have to do.
SET @vrtComment = CAST(@strComment AS SQL_VARIANT);   --have to convert this to variant type as that's what the built in sp asks for.

DECLARE @ustrVariantConv NVARCHAR(MAX) = REPLACE(CAST(@vrtComment AS NVARCHAR(MAX)),'''',''''''); 
/** Explanation of the conversion above.
 *	1. 	I wanted to leave this conversion instead of just declaring as NVARCHAR. 
 *		Technically it IS stored as variant, people should be aware of this.
 *	2.	We need to deal with quotes passed in for Contractions such as "can't" which would be passed in as "can''t"
 */


	CREATE TABLE #__SuppressOutputAddColumnComment (
		SuppressedOutput VARCHAR(MAX)
	);
BEGIN TRY
	SET NOCOUNT ON;
		--we do this type of insert to prevent seeing useless selects in the grid view on a SQL developer
	EXEC Utility.DD.DBSchemaObjectAssignment @ustrFQON
												, @ustrDatabaseName OUTPUT
												, @ustrSchemaName OUTPUT
												, @ustrTableorObjName OUTPUT;
	
	 /**REVIEW: if it becomes a problem where people are typing in tables wrong  all the time (check the exception log)
	 * we can certainly add the Utility.UTL.DD_TableExist first and if that fails just dump the procedure and show an error message
	 * for now though checking for the column will also show bad table names but won't specify that it's the table, just an error
	 	-- Dave Babler 
	 */

	 
	EXEC Utility.DD.ColumnExist @ustrTableorObjName
		, @strColumnName
		, @ustrDatabaseName
		, @ustrSchemaName
		, @boolExistFlag OUTPUT
		, @ustrMessageOut OUTPUT;


		/** Next Check to see if the name is for a view instead of a table, alter the function to fit your agency's naming conventions
		 * Not necessary to check this beforehand as the previous calls will work for views and tables due to how
		 * INFORMATION_SCHEMA is set up.  Unfortunately from this point on we'll be playing with Microsoft's sys tables
		  */
		SET @bitIsThisAView = Utility.DD.fn_IsThisTheNameOfAView(@ustrTableorObjName);

		IF @bitIsThisAView = 0
			SET @ustrViewOrTable = 'TABLE';
		ELSE
			SET @ustrViewOrTable = 'VIEW';

	IF @boolExistFlag = 0
	BEGIN

		SET @boolCatchFlag = 1;



		RAISERROR (
				@ustrMessageOut
				, 11
				, 1
				);
	END
	ELSE
	BEGIN
				/**Here we have to first check to see if a MS_Description Exists
                * If the MS_Description does not exist will will use the ADD procedure to add the comment
                * If the MS_Description tag does exist then we will use the UPDATE procedure to add the comment
                * Normally it's just a simple matter of ALTER TABLE/ALTER COLUMN ADD COMMENT, literally every other system
                * however, Microsoft Has decided to use this sort of registry style of documentation 
                * -- Dave Babler 2020-08-26*/

		SET @intRowCount = NULL;
		SET @dSQLNotExistCheckProperties = N' SELECT NULL
											FROM '
												+ QUOTENAME(@ustrDatabaseName)
											  	+ '.sys.extended_properties'
											  	+ ' WHERE [major_id] = OBJECT_ID('
											  	+ ''''
											  	+ @ustrDatabaseName
											  	+ '.'
											  	+ @ustrSchemaName
											  	+ '.'
											  	+ @ustrTableorObjName
											  	+ ''''
											  	+ ')'
											  	+	' AND [name] = N''MS_Description''		
													  AND [minor_id] =	(				
														  SELECT [column_id]
															FROM '
															+ QUOTENAME(@ustrDatabaseName)
															+ '.sys.columns
															WHERE [name] =  '
												+ ''''
												+ @strColumnName
											  	+ ''''
												+ ' AND [object_id] = OBJECT_ID( '
											  	+ ''''
											  	+ @ustrDatabaseName
											  	+ '.'
											  	+ @ustrSchemaName
											  	+ '.'
											  	+ @ustrTableorObjName
											  	+ ''''
												+								' )   )';
			INSERT INTO #__SuppressOutputAddColumnComment
			EXEC sp_executesql @dSQLNotExistCheckProperties;

			SET @intRowCount = @@ROWCOUNT;

		 --if the row count is zero we know we need to add the property not update it.

			IF @intRowCount = 0 
				BEGIN
					SET @dSQLApplyComment = N'EXEC ' 
											+ @ustrDatabaseName 
											+ '.'
											+ 'sys.sp_addextendedproperty '
											+ '@name = N''MS_Description'' '
											+ ', @value = '
											+ ''''
											+  @ustrVariantConv
											+ ''''
											+ ', @level0type = N''SCHEMA'' '
											+ ', @level0name = N'
											+ ''''
											+ 	@ustrSchemaName
											+ ''''
											+ ', @level1type = N'
											+ ''''
											+ 	@ustrViewOrTable
											+ ''''										
											+ ', @level1name = '
											+ ''''
											+	@ustrTableorObjName
											+ ''''
											+ ', @level2type = N''COLUMN'' '
											+ ', @level2name = N'
											+ ''''
											+  @strColumnName
											+ ''''
											;	



				END
			ELSE 
				BEGIN 
									SET @dSQLApplyComment = N'EXEC ' 
											+ @ustrDatabaseName 
											+ '.'
											+ 'sys.sp_updateextendedproperty '
											+ '@name = N''MS_Description'' '
											+ ', @value = '
											+ ''''
											+  @ustrVariantConv
											+ ''''
											+ ', @level0type = N''SCHEMA'' '
											+ ', @level0name = N'
											+ ''''
											+ 	@ustrSchemaName
											+ ''''
											+ ', @level1type = N'
											+ ''''
											+ 	@ustrViewOrTable
											+ ''''										
											+ ', @level1name = '
											+ ''''
											+	@ustrTableorObjName
											+ ''''
											+ ', @level2type = N''COLUMN'' '
											+ ', @level2name = N'
											+ ''''
											+  @strColumnName
											+ ''''
											;	
				END

	END 

		EXEC sp_executesql @dSQLApplyComment;
		DROP TABLE IF EXISTS #__SuppressOutputAddColumnComment;
	SET NOCOUNT OFF
END TRY

BEGIN CATCH
	IF @boolCatchFlag = 1
	BEGIN

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);
	END
	ELSE
	BEGIN

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);
	END

	PRINT 
		'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM CustomLog.ERR.DB_EXCEPTION_TANK
			)
		SELECT ErrorID
			, DatabaseName
			, UserName
			, ErrorNumber
			, ErrorState
			, ErrorLine
			, ErrorProcedure
			, ErrorMessage
			, ErrorDateTime
		FROM CustomLog.ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________

'
END CATCH


	/*Dynamic Queries
		-- IF NOT EXISTS
			SELECT NULL
				FROM QUOTENAME(@ustrDatabaseName).sys.extended_properties
				WHERE [major_id] = OBJECT_ID(@ustrFQON)
					AND [name] = N'MS_Description'
					AND [minor_id] = (
						SELECT [column_id]
						FROM QUOTENAME(@ustrDatabaseName).sys.columns
						WHERE [name] = @strColumnName
							AND [object_id] = OBJECT_ID(@ustrFQON);

		-- add properties
			EXECUTE sp_addextendedproperty @name = N'MS_Description'
				, @value = @vrtComment
				, @level0type = N'SCHEMA'
				, @level0name = N'dbo'
				, @level1type = N'TABLE'
				, @level1name = @ustrFQON
				, @level2type = N'COLUMN'
				, @level2name = @strColumnName;
		-- update properties
						EXECUTE sp_updateextendedproperty @name = N'MS_Description'
				, @value = @vrtComment
				, @level0type = N'SCHEMA'
				, @level0name = N'dbo'
				, @level1type = N'TABLE'
				, @level1name = @ustrFQON
				, @level2type = N'COLUMN'
				, @level2name = @strColumnName;
	*/










--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 
	DECLARE @ustrFullyQualifiedTable NVARCHAR(64) = N'';
	DECLARE @strColName VARCHAR(64) = '';
	DECLARE @ustrComment NVARCHAR(400) = N'';

	EXEC Utility.DD.AddColumnComment @ustrFullyQualifiedTable
		, @strColName
		, @ustrComment; 

	*/

--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

GO

USE [Utility];
GO
-- ==========================================================================================
-- Author:			Dave Babler
-- Create date: 	2020-08-25
-- Last Edited By:	Dave Babler
-- Last Updated:	2021-04-24
-- Description:		This will either add or wipe and update the comments on a table
-- SubProcedures:	1.	[Utility].[DD].[DBSchemaObjectAssignment]
--					2.  [Utility].[DD].[TableExist]
--					3.	[Utility].[DD].[fn_IsThisTheNameOfAView]
-- TODO: 			Upon update add the old value to some sort of LogTable, along with the user doing it.
-- ==========================================================================================
CREATE OR ALTER PROCEDURE DD.AddTableComment
	-- Add the parameters for the stored procedure here
	@ustrFQON NVARCHAR(200)
	, @strComment NVARCHAR(360)
AS
/**Note: vrt is for Variant, which is the absurd way SQL Server stores it's Strings in the data dictionary
* supposedly for 'security' --Dave Babler*/
DECLARE @vrtComment SQL_VARIANT
	, @strErrorMessage VARCHAR(MAX)
	, @ustrDatabaseName NVARCHAR(64)
	, @ustrSchemaName NVARCHAR(64)
	, @ustrTableOrObjName NVARCHAR(64)
	, @dSQLNotExistCheck NVARCHAR(MAX)
	, @dSQLNotExistCheckProperties NVARCHAR(MAX) -- could recycle previous var, don't want to
	, @dSQLApplyComment NVARCHAR(MAX) -- will use the same  dynamic sql variable name regardless of whether or not we add or update hence 'apply'
	, @intRowCount INT
	, @boolExistFlag BIT
	, @ustrMessageOut NVARCHAR(400)
	, @bitIsThisAView BIT
	, @ustrViewOrTable NVARCHAR(8)
	;

DROP TABLE IF EXISTS #__SuppressOutputAddTableComment; 

DECLARE @boolCatchFlag BIT = 0;  -- for catching and throwing a specific error. 
	--set and internally cast the VARIANT, I know it's dumb, but it's what we have to do.
SET @vrtComment = CAST(@strComment AS SQL_VARIANT);   --have to convert this to variant type as that's what the built in sp asks for.

DECLARE @ustrVariantConv NVARCHAR(MAX) = REPLACE(CAST(@vrtComment AS NVARCHAR(MAX)),'''',''''''); 
/** Explanation of the conversion above.
 *	1. 	I wanted to leave this conversion instead of just declaring as NVARCHAR. 
 *		Technically it IS stored as variant, people should be aware of this.
 *	2.	We need to deal with quotes passed in for Contractions such as "can't" which would be passed in as "can''t"
 */

DROP TABLE IF EXISTS #__SuppressOutputAddTableComment;
CREATE TABLE #__SuppressOutputAddTableComment (
	SuppressedOutput VARCHAR(MAX)
);

BEGIN TRY
	SET NOCOUNT ON;
	--break apart the fully qualified object name
	INSERT INTO #__SuppressOutputAddTableComment
	EXEC [Utility].[DD].[DBSchemaObjectAssignment] @ustrFQON
												, @ustrDatabaseName OUTPUT
												, @ustrSchemaName OUTPUT
												, @ustrTableOrObjName OUTPUT;


	INSERT INTO #__SuppressOutputAddTableComment
	VALUES(NULL);




		/** Next Check to see if the name is for a view instead of a table, alter the function to fit your agency's naming conventions
		 * Not necessary to check this beforehand as the previous calls will work for views and tables due to how
		 * INFORMATION_SCHEMA is set up.  Unfortunately from this point on we'll be playing with Microsoft's sys tables
		  */
		SELECT @bitIsThisAView = [Utility].[DD].[fn_IsThisTheNameOfAView](@ustrTableOrObjName);

		IF @bitIsThisAView = 0
			SET @ustrViewOrTable = 'TABLE';
		ELSE
			SET @ustrViewOrTable = 'VIEW';

			/**Check to see if the column or table actually exists -- Babler*/
	IF @boolExistFlag = 0
	BEGIN
		SET @boolCatchFlag = 1;
		RAISERROR (
				@ustrMessageOut
				, 11
				, 1
				);
	END
ELSE
				/**Here we have to first check to see if a MS_Description Exists
                        * If the MS_Description does not exist will will use the ADD procedure to add the comment
                        * If the MS_Description tag does exist then we will use the UPDATE procedure to add the comment
                        * Normally it's just a simple matter of ALTER TABLE/ALTER COLUMN ADD COMMENT, literally every other system
                        * however, Microsoft Has decided to use this sort of registry style of documentation 
                        * -- Dave Babler 2020-08-26*/

		SET @intRowCount = NULL;
		--future DBA's reading this...I can already hear your wailing and gnashing of teeth about SQL Injection. Stow it, only DBA's and devs will use this, it won't be customer facing.
		SET @dSQLNotExistCheckProperties = N' SELECT NULL
											  FROM 	'
											  + QUOTENAME(@ustrDatabaseName)
											  + '.sys.extended_properties'
											  + ' WHERE [major_id] = OBJECT_ID('
											  + ''''
											  + @ustrDatabaseName
											  + '.'
											  + @ustrSchemaName
											  + '.'
											  + @ustrTableOrObjName
											  + ''''
											  + ')'
											  +	' AND [name] = N''MS_Description''
													AND [minor_id] = 0';

		INSERT INTO #__SuppressOutputAddTableComment
		EXEC sp_executesql @dSQLNotExistCheckProperties;

		SET @intRowCount = @@ROWCOUNT;


		/* do an if rowcount = 0 next */
		IF @intRowCount = 0 
			BEGIN

				SET @dSQLApplyComment = N'EXEC ' 
										+ @ustrDatabaseName 
										+ '.'
										+ 'sys.sp_addextendedproperty '
										+ '@name = N''MS_Description'' '
										+ ', @value = '
										+ ''''
										+  @ustrVariantConv
										+ ''''
										+ ', @level0type = N''SCHEMA'' '
										+ ', @level0name = '
										+ ''''
										+ 	@ustrSchemaName
										+ ''''
										+ ', @level1type = N'
										+ ''''
										+ 	@ustrViewOrTable
										+ ''''										
										+ ', @level1name = '
										+ ''''
										+	@ustrTableOrObjName
										+ '''';
			END
		ELSE
			BEGIN 
				--DYNAMIC SQL FOR UPDATE EXTENDED PROPERTY GOES HERE.
								SET @dSQLApplyComment = N'EXEC ' 
										+ @ustrDatabaseName 
										+ '.'
										+ 'sys.sp_updateextendedproperty  '
										+ '@name = N''MS_Description'' '
										+ ', @value = '
										+ ''''
										+  @ustrVariantConv
										+ ''''
										+ ', @level0type = N''SCHEMA'' '
										+ ', @level0name = '
										+ ''''
										+ 	@ustrSchemaName
										+ ''''
										+ ', @level1type = N'
										+ ''''
										+ 	@ustrViewOrTable
										+ ''''										
										+ ', @level1name = '
										+ ''''
										+	@ustrTableOrObjName
										+ '''';

			END
				INSERT INTO #__SuppressOutputAddTableComment
				EXEC sp_executesql @dSQLApplyComment;

	DROP TABLE IF EXISTS #__SuppressOutputAddTableComment;
	SET NOCOUNT OFF
END TRY

BEGIN CATCH
	IF @boolCatchFlag = 1
	BEGIN

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, CONCAT( N'Boolean flag thrown!', CAST(ERROR_MESSAGE() AS NVARCHAR(2000)))
		, GETDATE()
		);
	END
	ELSE
	BEGIN

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);
	END

	PRINT 
		'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM CustomLog.ERR.DB_EXCEPTION_TANK
			)
		SELECT ErrorID
			, DatabaseName
			, UserName
			, ErrorNumber
			, ErrorState
			, ErrorLine
			, ErrorProcedure
			, ErrorMessage
			, ErrorDateTime
		FROM CustomLog.ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________

'
END CATCH;
	/*Dynamic Queries
		-- properties if not exists

					SELECT NULL
					FROM QUOTENAME(@ustrDatabaseName).SYS.EXTENDED_PROPERTIES
					WHERE [major_id] = OBJECT_ID(@ustrTableOrObjName)
						AND [name] = N'MS_Description'
						AND [minor_id] = 0

        -- add the properties  if they don't exist
                --be advised trying to run this without dynamic sql call will not work.
            
		      EXECUTE @ustrDatabaseName.sp_addextendedproperty @name = N'MS_Description'
		          , @value = @vrtComment
		          , @level0type = N'SCHEMA'
		          , @level0name = @ustrSchemaName
		          , @level1type = N'TABLE'
		          , @level1name = @ustrFQON;

        -- replace the properties  if they already exist
                --be advised trying to run this without dynamic sql call will not work.
              EXECUTE @ustrDatabaseName.sp_updateextendedproperty @name = N'MS_Description'
		          , @value = @vrtComment
		          , @level0type = N'SCHEMA'
		          , @level0name = N'dbo'
		          , @level1type = N'TABLE'
		          , @level1name = @ustrFQON;
            
		*/

	--Bibliography
	--   https://stackoverflow.com/questions/20757804/execute-stored-procedure-from-stored-procedure-w-dynamic-sql-capturing-output 

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 
	DECLARE @ustrFullyQualifiedTable NVARCHAR(64) = N'';
	DECLARE @ustrComment NVARCHAR(400) = N'';

	EXEC Utility.DD.AddTableComment @ustrFullyQualifiedTable
		, @ustrComment; 
	
*/

--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

GO

USE [Utility];
GO

-- ==========================================================================================
-- Author:		    Dave Babler
-- Create date:     08/25/2020
-- Last Modified:   01/29/2020
-- Description:	    Checks to see if column in table exists 
--                  use output Boolean for logic flow in other procedures
-- 					This will work just fine for Views without further modification.
-- ==========================================================================================
CREATE
	OR

ALTER PROCEDURE [DD].[ColumnExist] @ustrTableName NVARCHAR(64)
	, @ustrColumnName NVARCHAR(64)
	, @ustrDBName NVARCHAR(64) --SHOULD BE PASSED IN FROM ANOTHER PROC
	, @ustrSchemaName NVARCHAR(64) --SHOULD BE PASSED IN FROM ANOTHER PROC
	, @boolSuccessFlag BIT OUTPUT
	, @ustrMessageOut NVARCHAR(400) = NULL OUTPUT
AS
SET NOCOUNT ON;

BEGIN TRY
	/** If the column doesn't exist we're going to output a message and throw a false flag,
     *  ELSE we'll throw a true flag so external operations can commence
     * Dave Babler 2020-08-26  */

	DROP TABLE IF EXISTS #__suppressColExistDynamicOutput;
	CREATE TABLE #__suppressColExistDynamicOutput(
		HoldingCol NVARCHAR(MAX)
	); -- this table is for shutting down the useless output that sometimes happens with dynamic SQL

	DECLARE @ustrQuotedDB NVARCHAR(128) = N'' + QUOTENAME(@ustrDBName) + '';
	DECLARE @intRowCount INT;
	DECLARE @SQLCheckForTable NVARCHAR(1000) = 'SELECT NULL
                               FROM ' + @ustrQuotedDB + 
		'.INFORMATION_SCHEMA.COLUMNS 
                               WHERE TABLE_NAME = @ustrTable 
                                    AND TABLE_SCHEMA = @ustrSchema
                                    	AND COLUMN_NAME = @ustrColumn'
		;


	
	INSERT INTO #__suppressColExistDynamicOutput
	EXECUTE sp_executesql @SQLCheckForTable
		, N'@ustrTable NVARCHAR(64), 
            @ustrSchema NVARCHAR(64),
            @ustrColumn NVARCHAR(64)'
		, @ustrTable = @ustrTableName
		, @ustrSchema = @ustrSchemaName
        , @ustrColumn = @ustrColumnName;


	SET @intRowCount = @@ROWCOUNT; 

    IF @intRowCount <> 1
	BEGIN
		SET @boolSuccessFlag = 0;
		SET @ustrMessageOut = @ustrColumnName + ' of ' + @ustrTableName + ' does not exist, check spelling, try again?';
	END
	ELSE
	BEGIN
		SET @boolSuccessFlag = 1;
		SET @ustrMessageOut = NULL;
	END
	DROP TABLE #__suppressColExistDynamicOutput;
	SET NOCOUNT OFF;
END TRY

BEGIN CATCH

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);
END CATCH;





--TESTING BLOCK
/**

DECLARE @ustrTableName NVARCHAR(64) = '';
DECLARE @ustrDBName NVARCHAR(64) = '';
DECLARE @ustrColumnName NVARCHAR(64) = ''
DECLARE @ustrSchemaName NVARCHAR(64) = '';
DECLARE @boolSuccessFlag BIT;
DECLARE @ustrMessageOut NVARCHAR(400);

EXEC Utility.[DD].[ColumnExist] @ustrTableName
	, @ustrColumnName
	, @ustrDBName
	, @ustrSchemaName
	, @boolSuccessFlag OUTPUT
	, @ustrMessageOut OUTPUT;

SELECT @boolSuccessFlag
	, @ustrMessageOut;
*/

GO

USE [Utility]
GO
/****** Object:  StoredProcedure [DD].[DBSchemaObjectAssignment]    Script Date: 4/28/2021 3:32:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:			Dave Babler
-- Create date: 	11/09/2020
-- Description:		This procedure determines which database schema and object are being called, 
--              	and will output those to the correct calling procedure.
--              	REMINDER: the way to call objects is and always has been as such
--              	DBNAME.SCHEMA.OBJECT, and continues to be so.
-- Subprocedures: 	1. [Utility].[DD].[fn_DBSchemaObjCheck]
-- 					2 sp_executesql -- system procedure, dynamic SQL.
--
-- =============================================
ALTER	  PROCEDURE [DD].[DBSchemaObjectAssignment]
	-- Add the parameters for the stored procedure here
	@strQualifiedObjectBeingCalled NVARCHAR(200) --64*3+UP TO 2 PERIODS TO NEXT OCTET
	, @ustrDatabaseName NVARCHAR(64) = NULL OUTPUT
	, @ustrSchemaName NVARCHAR(64) = NULL OUTPUT
	, @ustObjectOrTableName NVARCHAR(64) = NULL OUTPUT
AS
BEGIN TRY
	DROP TABLE

	IF EXISTS #tblObjectBreakdown;
		DECLARE @intDelimCountChecker INT = 0;
	DECLARE @bitDatabaseExists BIT = 0;
	DECLARE @bitSchemaExists BIT = 0;
	DECLARE @intNumPiecesEntered INT = 0;
	DECLARE @ustrDefaultSchema NVARCHAR(64) = 'XXPPQQZZ';
	DECLARE @ustrDefaultDatabase NVARCHAR(64) = 'XXPPQQZZ';
	DECLARE @intDesiredPiece INT;
	DECLARE @ustrSQLToExecute NVARCHAR(4000);-- highly unlikely it would be longer in this proc.
	DECLARE @uDynamSQLParams NVARCHAR(2000) = N'@intDesiredPiece_ph INT, @ustrObjectFromTemp_ph NVARCHAR(64) OUTPUT';
		--we use this "p"lace "h"older in dyanmicSQL.

	CREATE TABLE #tblObjectBreakdown (
		intPosition INT
		, ustrObjectPiece NVARCHAR(64)
		);

	SET NOCOUNT ON;
	--GET MAX COUNT OF ROWID USE THAT TO DETERMINE LOGIC  IF NO PERIODS SKIP LOGIC USE DEFAULTS
	SET @intDelimCountChecker = CHARINDEX('.', @strQualifiedObjectBeingCalled);


	IF @intDelimCountChecker > 0
	BEGIN
		-- shove the broken apart string into a temp table using TVF so we can manipulate the data.
		INSERT INTO #tblObjectBreakdown
		SELECT *
		FROM [Utility].[DD].[fn_DBSchemaObjCheck](@strQualifiedObjectBeingCalled);

		SELECT @intNumPiecesEntered = MAX(intPosition)
		FROM #tblObjectBreakdown;
				SET @ustrSQLTOExecute = 
				N'SELECT @ustrObjectFromTemp_ph = ustrObjectPiece 
                                            FROM #tblObjectBreakdown
                                            WHERE intPosition = @intDesiredPiece_ph'
				;
		IF @intNumPiecesEntered = 3
			/*Ostensibly all 3 pieces are entered so let's check that and then assign them */
		BEGIN
			/**Normally I disapprove of directly injecting table, schema, or object names into dynamic SQL.
                    * In this case, we are ok because all we are using a temporary table that WE built, and we are assigning variables
                    * and as such it should be cool.  Dave Babler 2020-11-15 */
			--rip through the pieces and assign them to outputs
	
			SET @intDesiredPiece = 1;

			EXEC sp_executesql @ustrSQLTOExecute
				, @uDynamSQLParams
				, @ustrObjectFromTemp_ph = @ustrDataBaseName OUTPUT --grabs database name
				, @intDesiredPiece_ph = @intDesiredPiece;
			SET @intDesiredPiece = 2;

			EXEC sp_executesql @ustrSQLTOExecute
				, @uDynamSQLParams
				, @ustrObjectFromTemp_ph = @ustrSchemaName OUTPUT --grabs schema name
				, @intDesiredPiece_ph = @intDesiredPiece;
			SET @intDesiredPiece = 3;

			EXEC sp_executesql @ustrSQLTOExecute
				, @uDynamSQLParams
				, @ustrObjectFromTemp_ph = @ustObjectOrTableName OUTPUT --grabs object name
				, @intDesiredPiece_ph = @intDesiredPiece;
		END
		ELSE IF @intNumPiecesEntered = 2
		BEGIN
			-- SET THE DATABASE TO THE DEFAULT DATABASE
			SET @ustrDataBaseName = @ustrDefaultDatabase;
			SET @intDesiredPiece = 1;

			EXEC sp_executesql @ustrSQLTOExecute
				, @uDynamSQLParams
				, @ustrObjectFromTemp_ph = @ustrSchemaName OUTPUT --grabs schema name
				, @intDesiredPiece_ph = @intDesiredPiece;

			SET @intDesiredPiece = 2;

			EXEC sp_executesql @ustrSQLTOExecute
				, @uDynamSQLParams
				, @ustrObjectFromTemp_ph = @ustObjectOrTableName OUTPUT --grabs object name
				, @intDesiredPiece_ph = @intDesiredPiece;
		END
			ELSE
	BEGIN
		SET @ustrSchemaName = @ustrDefaultSchema;
		SET @ustrDatabaseName = @ustrDefaultDatabase;
		SET @ustObjectOrTableName = @strQualifiedObjectBeingCalled;

			--check info schema to make sure the schmea and the db actually exist.
	END

	END
	SET NOCOUNT OFF;
END TRY


BEGIN CATCH

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE() + OBJECT_NAME(@@PROCID)
		, ERROR_MESSAGE()
		, GETDATE()
		);
END CATCH;


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/*   
		DECLARE @ustrDatabaseName NVARCHAR(64)
			, @ustrSchemaName NVARCHAR(64)
			, @ustObjectOrTableName NVARCHAR(64);

		EXEC DD.DBSchemaObjectAssignment 'ADB.SOMESCHEMA.ATABLEORVIEW'
			, @ustrDatabaseName OUTPUT
			, @ustrSchemaName OUTPUT
			, @ustObjectOrTableName OUTPUT;

		SELECT @ustrDatabaseName
			, @ustrSchemaName
			, @ustObjectOrTableName;

 */

--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
GO


USE [Utility]
GO
/****** Object:  StoredProcedure [DD].[Describe]    Script Date: 4/28/2021 10:44:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dave Babler
-- Create date: 08/26/2020
-- Description:	This recreates and improves upon Oracle's ANSI DESCRIBE table built in data dictionary proc
-- 				This will default to the dbo schema unless specified within the input parameter.
-- Subprocedures: 1. DD.ShowTableComment
-- 				  2. UTL_fn_DelimListToTable  (already exists, used to have diff name)
-- =============================================
CREATE OR ALTER   PROCEDURE [DD].[Describe]
	-- Add the parameters for the stored procedure here
	@str_input_TableName VARCHAR(200) 
	 
AS


DECLARE @strMessageOut NVARCHAR(320)
	, @boolIsTableCommentSet BIT = NULL
	, @strTableComment NVARCHAR(320)
	, @strTableSubComment NVARCHAR(80) --This will be an additional flag warning there is no actual table comment!
	, @bitIsThisAView BIT
	, @bitExistFlag BIT
	, @ustrDatabaseName NVARCHAR(64)
	, @ustrSchemaName NVARCHAR(64)
	, @ustrTableorObjName NVARCHAR(64)
	, @ustrViewOrTable NVARCHAR(8)
	, @dSQLBuildDescribe NVARCHAR(MAX)
	, @dSQLParamaters NVARCHAR(MAX)
    , @bitSuccessFlag BIT;

BEGIN TRY
SET NOCOUNT ON;
		DROP TABLE IF EXISTS ##DESCRIBE;  --for future output to temp tables ignore for now
	/** First check to see if a schema was specified in the input paramater, schema.table, else default to dbo. -- Babler*/
		EXEC Utility.DD.DBSchemaObjectAssignment @str_input_TableName
			, @ustrDatabaseName OUTPUT
			, @ustrSchemaName OUTPUT
			, @ustrTableorObjName OUTPUT;



			/**Check to see if the table exists, if it does not we will output an Error Message
        * however since we are not writing anything to the DD we won't go through the whole RAISEEROR 
        * or THROW and CATCH process, a simple output is sufficient. -- Babler
        */



    EXEC Utility.DD.TableExist @ustrTableorObjName
	, @ustrDatabaseName
	, @ustrSchemaName
	, @bitSuccessFlag OUTPUT
	, @strMessageOut OUTPUT; 

    IF @bitSuccessFlag = 1

	
	BEGIN
		-- we want to suppress results (perhaps this could be proceduralized as well one to make the table one to kill?)
		CREATE TABLE #__suppress_results (col1 INT);

		EXEC Utility.DD.ShowTableComment @str_input_TableName
			, @boolIsTableCommentSet OUTPUT
			, @strTableComment OUTPUT;

		IF @boolIsTableCommentSet = 0
		BEGIN
			SET @strTableSubComment = 'RECTIFY MISSING TABLE COMMENT -->';
		END
		ELSE
		BEGIN
			SET @strTableSubComment = 'TABLE COMMENT --> ';
		END
		SET @dSQLBuildDescribe  = CAST(N' '  AS NVARCHAR(MAX)) + 
                    N'WITH fkeys
                    AS (
                        SELECT col.name AS NameofFKColumn
                            , schema_name(pk_tab.schema_id) + ''.'' + pk_tab.name AS ReferencedTable
                            , pk_col.name AS PrimaryKeyColumnName
                            , delete_referential_action_desc AS ReferentialDeleteAction
                            , update_referential_action_desc AS ReferentialUpdateAction
                        FROM ' + @ustrDatabaseName + '.sys.tables tab
                        INNER JOIN ' + @ustrDatabaseName + '.sys.columns col
                            ON col.object_id = tab.object_id
                        LEFT JOIN ' + @ustrDatabaseName + '.sys.foreign_key_columns fk_cols
                            ON fk_cols.parent_object_id = tab.object_id
                                AND fk_cols.parent_column_id = col.column_id
                        LEFT JOIN ' + @ustrDatabaseName + '.sys.foreign_keys fk
                            ON fk.object_id = fk_cols.constraint_object_id
                        LEFT JOIN ' + @ustrDatabaseName + '.sys.tables pk_tab
                            ON pk_tab.object_id = fk_cols.referenced_object_id
                        LEFT JOIN ' + @ustrDatabaseName + '.sys.columns pk_col
                            ON pk_col.column_id = fk_cols.referenced_column_id
                            AND pk_col.column_id = fk_cols.referenced_object_id
                        WHERE fk.name IS NOT NULL
                            AND tab.name = @ustrTableName_d
                            AND pk_tab.schema_id = SCHEMA_ID(@ustrSchemaName_d)
                        )
                        , pk
                    AS (
                        SELECT SCHEMA_NAME(o.schema_id) AS TABLE_SCHEMA
                            , o.name AS TABLE_NAME
                            , c.name AS COLUMN_NAME
                            , i.is_primary_key
                        FROM ' + @ustrDatabaseName + '.sys.indexes AS i
                        INNER JOIN ' + @ustrDatabaseName + '.sys.index_columns AS ic
                            ON i.object_id = ic.object_id
                                AND i.index_id = ic.index_id
                        INNER JOIN ' + @ustrDatabaseName + '.sys.objects AS o
                            ON i.object_id = o.object_id
                        LEFT JOIN ' + @ustrDatabaseName + '.sys.columns AS c
                            ON ic.object_id = c.object_id
                                AND c.column_id = ic.column_id
                        WHERE i.is_primary_key = 1
                        )
                        , indStart
                    AS (
                        SELECT TableName = t.name
                            , IndexName = ind.name
                            , IndexId = ind.index_id
                            , ColumnId = ic.index_column_id
                            , ColumnName = col.name
                        FROM ' + @ustrDatabaseName + '.sys.indexes ind
                        INNER JOIN ' + @ustrDatabaseName + '.sys.index_columns ic
                            ON ind.object_id = ic.object_id
                                AND ind.index_id = ic.index_id
                        INNER JOIN ' + @ustrDatabaseName + '.sys.columns col
                            ON ic.object_id = col.object_id
                                AND ic.column_id = col.column_id
                        INNER JOIN ' + @ustrDatabaseName + '.sys.tables t
                            ON ind.object_id = t.object_id
                        WHERE ind.is_primary_key = 0
                            AND ind.is_unique = 0
                            AND ind.is_unique_constraint = 0
                            AND t.is_ms_shipped = 0
                            AND t.Name = @ustrTableName_d
                        )
                        , indexList
                    AS (
                        SELECT i2.TableName
                            , i2.IndexName
                            , i2.IndexId
                            , i2.ColumnId
                            , i2.ColumnName
                            , (
                                SELECT SUBSTRING((
                                            SELECT ''
                                                , '' + IndexName
                                            FROM indStart i1
                                            WHERE i1.ColumnName = i2.ColumnName
                                            FOR XML PATH('''')
                                            ), 2, 200000)
                                ) AS IndexesRowIsInvolvedIn
                            , ROW_NUMBER() OVER (
                                PARTITION BY LOWER(ColumnName) ORDER BY ColumnId
                                ) AS RowNum
                        FROM indStart i2
                        )
                    SELECT col.COLUMN_NAME AS ColumnName
                        , col.ORDINAL_POSITION AS OrdinalPosition
                        , col.DATA_TYPE AS DataType
                        , col.CHARACTER_MAXIMUM_LENGTH AS MaxLength
                        , col.NUMERIC_PRECISION AS NumericPrecision
                        , col.NUMERIC_SCALE AS NumericScale
                        , col.DATETIME_PRECISION AS DatePrecision
                        , col.COLUMN_DEFAULT AS DefaultSetting
                        , CAST(CASE col.IS_NULLABLE
                                WHEN '' NO ''
                                    THEN 0
                                ELSE 1
                                END AS BIT) AS IsNullable
                        , COLUMNPROPERTY(OBJECT_ID('' ['' + col.TABLE_SCHEMA + ''].['' + col.TABLE_NAME + ''] ''), col.COLUMN_NAME, '' IsComputed 
                            '') AS IsComputed
                        , COLUMNPROPERTY(OBJECT_ID('' ['' + col.TABLE_SCHEMA + ''].['' + col.TABLE_NAME + ''] ''), col.COLUMN_NAME, '' IsIdentity 
                            '') AS IsIdentity
                        , CAST(ISNULL(pk.is_primary_key, 0) AS BIT) AS IsPrimaryKey
                        , '' FK

                    of: '' + fkeys.ReferencedTable + ''.'' + fkeys.PrimaryKeyColumnName AS ReferencedTablePrimaryKey
                        , col.COLLATION_NAME AS CollationName
                        , s.value AS Description
                        , indexList.IndexesRowIsInvolvedIn
                    INTO ##DESCRIBE --GLOBAL TEMP 
                    FROM ' + @ustrDatabaseName +'.INFORMATION_SCHEMA.COLUMNS AS col
                    LEFT JOIN pk
                        ON col.TABLE_NAME = pk.TABLE_NAME
                            AND col.TABLE_SCHEMA = pk.TABLE_SCHEMA
                            AND col.COLUMN_NAME = pk.COLUMN_NAME
                    LEFT JOIN ' + @ustrDatabaseName + '.sys.extended_properties s
                        ON s.major_id = OBJECT_ID(col.TABLE_CATALOG + ''.'' + col.TABLE_SCHEMA + ''.'' + col.TABLE_NAME)
                            AND s.minor_id = col.ORDINAL_POSITION
                            AND s.name = ''MS_Description''
                            AND s.class = 1
                    LEFT JOIN fkeys AS fkeys
                        ON col.COLUMN_NAME = fkeys.NameofFKColumn
                    LEFT JOIN indexList
                        ON col.COLUMN_NAME = indexList.ColumnName
                            AND indexList.RowNum = 1
                    WHERE col.TABLE_NAME = @ustrTableName_d
                        AND col.TABLE_SCHEMA = @ustrSchemaName_d

                        	UNION ALL
		
		SELECT TOP 1 @ustrTableName_d
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, @strTableSubComment_d
			, @strTableComment_d
			, NULL --list of indexes 
		ORDER BY 2 

'
	;


	-- FOR OUTPUTTING AND DEBUGGING THE DYNAMIC SQL 👇

    --SELECT CAST('<root><![CDATA[' + @dSQLBuildDescribe + ']]></root>' AS XML)


	SET @dSQLParamaters = '@ustrDatabaseName_d NVARCHAR(64)
, @ustrSchemaName_d NVARCHAR(64)
, @ustrTableName_d NVARCHAR(64)
, @strTableSubComment_d VARCHAR(2000)
, @strTableComment_d VARCHAR(2000)';


EXEC sp_executesql @dSQLBuildDescribe
, @dSQLParamaters
, @ustrDatabaseName_d = @ustrDatabaseName
, @ustrSchemaName_d = @ustrSchemaName
, @ustrTableName_d = @ustrTableorObjName
, @strTableSubComment_d = @strTableSubComment
, @strTableComment_d = @strTableComment;


		/**Why this trashy garbage Dave? 
		* 1. I didn't have time to come up with a fake pass through TVF, nor would I want
		* 		what should just be a simple command and execute to have to go through the garbage
		* 		of having to SELECT out of a TVF.
		* 2. If we want to be able to select from our now 'much better than' ANSI DESCRIBE 
		*	 then we have to output the table like this. 
		* 3. Be advised if multiple people run this at the same time the global temp table will change!
		* 4.  Future iterations could allow someone to choose their own global temp table name, but again, 
		*	 I WANT SIMPLICITY ON THE CALL, even if the code itself is quite complex!
		* -- Dave Babler 2020-09-28
		*/


 
		SELECT *
		FROM ##DESCRIBE; --WE HAVE TO OUTPUT IT. 
	END


	ELSE
	BEGIN
		SET @strMessageOut = ' The table you typed in: ' + @ustrTableorObjName + ' ' + 'is invalid, check spelling, try again? ';

		SELECT @strMessageOut AS 'NON_LOGGED_ERROR_MESSAGE'
	END

		DROP TABLE
		IF EXISTS #__suppress_results;

		SET NOCOUNT OFF;
	END TRY

BEGIN CATCH
	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);

        
PRINT 
	'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM CustomLog.ERR.DB_EXCEPTION_TANK
			)
		SELECT ErrorID
			, DatabaseName
			, UserName
			, ErrorNumber
			, ErrorState
			, ErrorLine
			, ErrorProcedure
			, ErrorMessage
			, ErrorDateTime
		FROM CustomLog.ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________
';
END CATCH
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================================
-- Author:			Dave Babler
-- Create date: 	2020-08-25
-- Last Edited By:	Dave Babler
-- Last Updated:	2021-04-24
-- Description:	    This procedure makes viewing comments on a single column much more accessible.
-- Subprocedures: 	1. [Utility].[UTL].[fn_SuppressOutput]
-- 					2. [Utility].[DD].[DBSchemaObjectAssignment]
-- 					3. [Utility].[DD].[ColumnExist]
--  				4. [Utility].[DD].[fn_IsThisTheNameOfAView]
-- ==========================================================================================
CREATE OR ALTER  PROCEDURE [DD].[ShowColumnComment] 
	-- Add the parameters for the stored procedure here
	@ustrFQON NVARCHAR(64)
	, @ustrColumnName NVARCHAR(64)
AS


DECLARE @ustrMessageOut NVARCHAR(320)
, @ustrDatabaseName NVARCHAR(64) 
, @ustrSchemaName NVARCHAR(64)
, @ustrTableOrObjName  NVARCHAR(64)
, @intRowCount INT
, @boolExistFlag BIT
, @dSQLCheckForComment NVARCHAR(MAX)
, @dSQLPullComment NVARCHAR(MAX)
, @dSQLPullCommentParameters NVARCHAR(MAX); 
DROP TABLE IF EXISTS #__SuppressOutputColumnComment
CREATE TABLE #__SuppressOutputColumnComment(
	SuppressedOutput VARCHAR(MAX)
)
BEGIN TRY
EXEC [Utility].[DD].[DBSchemaObjectAssignment] @ustrFQON
	, @ustrDatabaseName OUTPUT
	, @ustrSchemaName OUTPUT
	, @ustrTableOrObjName OUTPUT;

EXEC [Utility].[DD].[ColumnExist] @ustrTableOrObjName
	, @ustrColumnName
	, @ustrDatabaseName
	, @ustrSchemaName
	, @boolExistFlag OUTPUT
	, @ustrMessageOut OUTPUT;

    IF @boolExistFlag = 1
       BEGIN 
    
                /**Check to see if the column has the extened properties on it.
                 *If it does not  will ultimately ask someone to please create 
                 * the comment on the column -- Babler */
                SET @intRowCount = 0;
                SET @dSQLCheckForComment = N'
                    SELECT 1
                    FROM ' + QUOTENAME(@ustrDatabaseName) + '.sys.extended_properties
                    WHERE [major_id] = OBJECT_ID('  
                    	                      + ''''
											  + @ustrDatabaseName
											  + '.'
											  + @ustrSchemaName
											  + '.'
											  + @ustrTableOrObjName
											  + ''''
                                         + ')
                        AND [name] = N''MS_Description''
                        AND [minor_id] = (
                            SELECT [column_id]
                            FROM ' + QUOTENAME(@ustrDatabaseName) + '.sys.columns
                            WHERE [name] = ' 
                            + ''''
                            + @ustrColumnName 
                            + ''''
                            +'
                                AND [object_id] = OBJECT_ID('  
                    	                      + ''''
											  + @ustrDatabaseName
											  + '.'
											  + @ustrSchemaName
											  + '.'
											  + @ustrTableOrObjName
											  + ''''
                                         + ')
                            )
                    ';
                                    PRINT @intRowCount
                PRINT @dSQLCheckForComment
                INSERT INTO #__SuppressOutputColumnComment
                EXEC sp_executesql @dSQLCheckForComment;
                
                SET @intRowCount = @@ROWCOUNT
                PRINT @intRowCount;
        IF @intRowCount = 1
            BEGIN
            SET @dSQLPullComment = N'
                SELECT TOP 1 @ustrMessageOutTemp = CAST(ep.value AS  NVARCHAR(320))
                FROM '
                + QUOTENAME(@ustrDataBaseName)
                + '.sys.extended_properties AS ep
                INNER JOIN '
                + QUOTENAME(@ustrDataBaseName)
                + '.sys.all_objects AS ob
                    ON ep.major_id = ob.object_id
                INNER JOIN '
                + QUOTENAME(@ustrDataBaseName)
                +'.sys.tables AS st
                    ON ob.object_id = st.object_id
                INNER JOIN '
                + QUOTENAME(@ustrDataBaseName)
                +'.sys.columns AS c	
                    ON ep.major_id = c.object_id
                        AND ep.minor_id = c.column_id
                WHERE st.name = @ustrTableOrObjName
                    AND c.name = @ustrColumnName';
                SET @dSQLPullCommentParameters = 
                    N' @ustrColumnName NVARCHAR(64)
                                , @ustrTableOrObjName NVARCHAR(64)
                                , @ustrMessageOutTemp NVARCHAR(320) OUTPUT'
                    ;

                EXECUTE sp_executesql @dSQLPullComment
                , N'@ustrColumnName NVARCHAR(64)
                            , @ustrTableOrObjName NVARCHAR(64)
                            , @ustrMessageOutTemp NVARCHAR(320) OUTPUT'
                , @ustrColumnName = @ustrColumnName
                , @ustrTableOrObjName = @ustrTableOrObjName
                , @ustrMessageOutTemp = @ustrMessageOut OUTPUT;


                    PRINT @ustrMessageOut
            END
            ELSE
            BEGIN
                SET @ustrMessageOut = @ustrFQON + ' ' + @ustrColumnName + 
                    N' currently has no comments please use Utility.DD.AddColumnComment to add a comment!';
            END

            SELECT @ustrColumnName AS 'ColumnName'
                , @ustrMessageOut AS 'ColumnComment';
        END
    ELSE 
        BEGIN
         SET @ustrMessageOut = 'Either the column you typed in: ' + @ustrColumnName + ' or, '
                            + ' the table you typed in: ' + @ustrFQON + ' '
                            + 'is invalid, check spelling, try again? ';
         SELECT @ustrMessageOut AS 'NON_LOGGED_ERROR_MESSAGE'
        END

END TRY

BEGIN CATCH
	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE() + OBJECT_NAME(@@PROCID)
		, ERROR_MESSAGE()
		, GETDATE()
		);

        
PRINT 
	'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM CustomLog.ERR.DB_EXCEPTION_TANK
			)
		SELECT ErrorID
			, DatabaseName
			, UserName
			, ErrorNumber
			, ErrorState
			, ErrorLine
			, ErrorProcedure
			, ErrorMessage
			, ErrorDateTime
		FROM CustomLog.ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________
';
END CATCH
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 

            DECLARE	@return_value int

            EXEC	@return_value = Utility.[DD].[ShowColumnComment]
                    @ustrFQON = N'Galactic.dbo.WorkDone',
                    @ustrColumnName = N'Description'

            SELECT	'Return Value' = @return_value

            GO

*/
	--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~DYNAMIC SQL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/* 
SELECT NULL
FROM SYS.EXTENDED_PROPERTIES
WHERE [major_id] = OBJECT_ID(@ustrFQON)
	AND [name] = N'MS_Description'
	AND [minor_id] = (
		SELECT [column_id]
		FROM SYS.COLUMNS
		WHERE [name] = @ustrColumnName
			AND [object_id] = OBJECT_ID(@ustrFQON)
		);

SELECT TOP 1 @ustrMessageOutTemp = CAST(ep.value AS NVARCHAR(320))
FROM [DatabaseName].sys.extended_properties AS ep
INNER JOIN [DatabaseName].sys.all_objects AS ob
	ON ep.major_id = ob.object_id
INNER JOIN [DatabaseName].sys.tables AS st
	ON ob.object_id = st.object_id
INNER JOIN [DatabaseName].sys.columns AS c
	ON ep.major_id = c.object_id
		AND ep.minor_id = c.column_id
WHERE st.name = @ustrFQON
	AND c.name = @ustrColumnName
   
  */

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                 

-- ================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:			Dave Babler
-- Create date: 	2020-08-25
-- Last Edited By:	Dave Babler
-- Last Updated:	2021-04-24
-- Description:		Checks to see if table comments exist
-- Subprocedures: 	1. [Utility].[UTL].[fn_SuppressOutput]
-- 					2. [Utility].[DD].[DBSchemaObjectAssignment]
-- 					3. [Utility].[DD].[TableExist]
--  				4. [Utility].[DD].[fn_IsThisTheNameOfAView]
-- ==========================================================================================
CREATE
	OR

ALTER PROCEDURE DD.ShowTableComment @ustrFQON NVARCHAR(200)
	, @boolOptionalSuccessFlag BIT = NULL OUTPUT
	, @strOptionalMessageOut NVARCHAR(320) = NULL OUTPUT
	/** The success flag will be used when passing this to other procedures to see if table comments exist.
	 * The optional message out will be used when passing from proc to proc to make things more proceduralized.
	 * --Dave Babler 08/26/2020  */
AS
DECLARE @ustrMessageOut NVARCHAR(320)
	, @intRowCount INT
	, @bitSuppressVisualOutput BIT
	, @bitIsThisAView BIT
	, @bitExistFlag BIT
	, @ustrDatabaseName NVARCHAR(64)
	, @ustrSchemaName NVARCHAR(64)
	, @ustrTableOrObjName NVARCHAR(64)
	, @ustrViewOrTable NVARCHAR(8)
	, @dSQLCheckForComment NVARCHAR(MAX)
	, @dSQLPullComment NVARCHAR(MAX)
	, @dSQLPullCommentParameters NVARCHAR(MAX)
	, @dSQLInternalVariantOutput SQL_VARIANT;

CREATE TABLE #__SuppressOutputShowTableComment(
	SuppressedOutput VARCHAR(MAX)
)

BEGIN TRY
	/**First with procedures that are stand alone/embedded hybrids, determine if we need to suppress output by 
  * populating the data for that variable 
  * --Dave Babler */
	SELECT @bitSuppressVisualOutput = [Utility].[UTL].[fn_SuppressOutput]();

	--first blow apart the fully qualified object name
	EXEC [Utility].[DD].[DBSchemaObjectAssignment] @ustrFQON
		, @ustrDatabaseName OUTPUT
		, @ustrSchemaName OUTPUT
		, @ustrTableOrObjName OUTPUT;


		/** Next Check to see if the name is for a view instead of a table, alter the function to fit your agency's naming conventions
		 * Not necessary to check this beforehand as the previous calls will work for views and tables due to how
		 * INFORMATION_SCHEMA is set up.  Unfortunately from this point on we'll be playing with Microsoft's sys tables
		  */
		SET @bitIsThisAView = [Utility].[DD].[fn_IsThisTheNameOfAView](@ustrTableOrObjName);

		IF @bitIsThisAView = 0
			SET @ustrViewOrTable = 'TABLE';
		ELSE
			SET @ustrViewOrTable = 'VIEW';

	EXEC [Utility].[DD].[TableExist] @ustrTableOrObjName
		, @ustrDatabaseName
		, @ustrSchemaName
		, @bitExistFlag OUTPUT
		, @ustrMessageOut OUTPUT;
		PRINT @ustrMessageOut;
	IF @bitExistFlag = 1
	BEGIN

				/**Check to see if the table has the extened properties on it.
                        *If it does not  will ultimately ask someone to please create 
                        * the comment on the table -- Babler */
		SET @dSQLCheckForComment = N' SELECT 1
									FROM '
									+ QUOTENAME(@ustrDataBaseName)
									+ '.sys.extended_properties'
									+ ' WHERE [major_id] = OBJECT_ID('
									+ ''''
									+ @ustrDatabaseName
									+ '.'
									+ @ustrSchemaName
									+ '.'
									+ @ustrTableOrObjName
									+''''
									+')'
									+ ' AND [name] = N''MS_Description''
										AND [minor_id] = 0';
										
					INSERT INTO #__SuppressOutputShowTableComment
					EXEC sp_executesql @dSQLCheckForComment;
					SET @intRowCount = @@ROWCOUNT;
		IF @intRowCount != 0
		BEGIN
				SET @dSQLPullComment = N'
								
								SELECT   @ustrMessageOutTemp  = epExtendedProperty
								FROM ' + QUOTENAME(
						@ustrDataBaseName) + 
					'.INFORMATION_SCHEMA.TABLES AS t
								INNER JOIN (
									
									SELECT OBJECT_NAME(ep.major_id, DB_ID(' + '''' + 
					@ustrDataBaseName + '''' + 
					')) AS [epTableName]
										, CAST(ep.Value AS NVARCHAR(320)) AS [epExtendedProperty]
									FROM ' + QUOTENAME(
						@ustrDataBaseName) + 
					'.sys.extended_properties ep
									WHERE ep.name = N''MS_Description'' 
										AND ep.minor_id = 0 
									
								) AS tp
									ON t.TABLE_NAME = tp.epTableName
								WHERE TABLE_TYPE = ''BASE TABLE''
								AND tp.epTableName = @ustrTableOrObjName
									AND t.TABLE_CATALOG = @ustrDatabaseName
									AND t.TABLE_SCHEMA = @ustrSchemaName'
					;


PRINT @dSQLPullComment

			SET @dSQLPullCommentParameters = 
				N' @ustrDatabaseName NVARCHAR(64)
				, @ustrSchemaName NVARCHAR(64)
				, @ustrTableOrObjName NVARCHAR(64)
				, @ustrMessageOutTemp NVARCHAR(320) OUTPUT'
				;
				EXECUTE sp_executesql @dSQLPullComment
					, N' @ustrDatabaseName NVARCHAR(64)
				, @ustrSchemaName NVARCHAR(64)
				, @ustrTableOrObjName NVARCHAR(64)
				, @ustrMessageOutTemp NVARCHAR(320) OUTPUT'
					, @ustrDatabaseName = @ustrDatabaseName
					, @ustrSchemaName = @ustrSchemaName
					, @ustrTableOrObjName = @ustrTableOrObjName
					, @ustrMessageOutTemp = @ustrMessageOut OUTPUT;


			PRINT @ustrMessageOut


			SET @boolOptionalSuccessFlag = 1;--Let any calling procedures know that there is in fact
			SET @strOptionalMessageOut = @ustrMessageOut;
		END
		ELSE
		BEGIN
			SET @boolOptionalSuccessFlag = 0;--let any proc calling know that there is no table comments yet.
			SET @ustrMessageOut = @ustrDataBaseName + '.' + @ustrSchemaName + '.'+  @ustrTableOrObjName + 
				N' currently has no comments please use Utility.DD.AddTableComment to add comments!';
			SET @strOptionalMessageOut = @ustrMessageOut;
		END

		IF @bitSuppressVisualOutput = 0
		BEGIN
			SELECT @ustrTableOrObjName AS 'Table Name'
				, @ustrMessageOut AS 'TableComment';
		END
	END
	ELSE
	BEGIN
		SET @ustrMessageOut = ' The table you typed in: ' + @ustrTableOrObjName + ' ' + 'is invalid, check spelling, try again? ';

		SELECT @ustrMessageOut AS 'NON_LOGGED_ERROR_MESSAGE'
	END
END TRY

BEGIN CATCH
	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);
END CATCH

PRINT 
	'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM CustomLog.ERR.DB_EXCEPTION_TANK
			)
		SELECT ErrorID
			, DatabaseName
			, UserName
			, ErrorNumber
			, ErrorState
			, ErrorLine
			, ErrorProcedure
			, ErrorMessage
			, ErrorDateTime
		FROM CustomLog.ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________

'
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 
	DECLARE @ustrFullyQualifiedTable NVARCHAR(64) = N'';
	DECLARE @boolOptionalSuccessFlag BIT = NULL;
	DECLARE @strOptionalMessageOut NVARCHAR(320) = NULL;

	EXEC Utility.DD.ShowTableComment @ustrFullyQualifiedTable
		, @boolOptionalSuccessFlag OUTPUT
		, @strOptionalMessageOut OUTPUT;

	SELECT @boolOptionalSuccessFlag AS N'Success 🚩'
		, @strOptionalMessageOut AS 'Optional Output Message';

*/
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
--~~~~~~~~~~~~~~~~~~~~~~~~~DYNAMIC SQL~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/* 
;WITH tp (
	epTableName
	, epExtendedProperty
	)
AS (
	SELECT OBJECT_NAME(ep.major_id) AS [epTableName]
		, ep.Value AS [epExtendedProperty]
	FROM @ustDatabaseName.sys.extended_properties ep
	WHERE ep.name = N'MS_Description' --sql serverabsurdly complex version of COMMENT
		AND ep.minor_id = 0 --prevents showing column comments
	)
SELECT TOP 1 @ustrMessageOut = CAST(tp.epExtendedProperty AS NVARCHAR(320))
FROM INFORMATION_SCHEMA.TABLES AS t
INNER JOIN tp
	ON t.TABLE_NAME = tp.epTableName
WHERE TABLE_TYPE = N'BASE TABLE'
	AND tp.epTableName = @ustrTableOrObjName
	AND t.TABLE_CATALOG = @ustrDatabaseName
	AND t.TABLE_SCHEMA = @ustrSchemaName;
	 */
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GO


USE [Utility]
GO
/****** Object:  StoredProcedure [DD].[TableExist]    Script Date: 4/28/2021 3:08:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		    Dave Babler
-- Create date:     08/25/2020
-- Last Modified:   11/23/2020
-- Description:	    Checks to see if table exists use output boolean for logic flow in other procedures
-- =============================================
ALTER
	

 PROCEDURE [DD].[TableExist] @ustrTableName NVARCHAR(64)
	, @ustrDBName NVARCHAR(64)
	, --SHOULD BE PASSED IN FROM ANOTHER PROC
	@ustrSchemaName NVARCHAR(64)
	, --SHOULD BE PASSED IN FROM ANOTHER PROC
	@boolSuccessFlag BIT OUTPUT
	, @ustrMessageOut NVARCHAR(400) = NULL OUTPUT
AS
SET NOCOUNT ON;

BEGIN TRY
	/** If the table doesn't exist we're going to output a message and throw a false flag,
     *  ELSE we'll throw a true flag so external operations can commence
     * Dave Babler 2020-08-26  */
	DECLARE @ustrOutGoingMessageEnd NVARCHAR(48) = N' does not exist, check spelling, try again?';
	DECLARE @ustrQuotedDB NVARCHAR(128) = N'' + QUOTENAME(@ustrDBName) + '';
	DECLARE @intRowCount INT;
	DECLARE @SQLCheckForTable NVARCHAR(1000) = 'SELECT 1 
                               FROM ' + @ustrQuotedDB + 
		'.INFORMATION_SCHEMA.TABLES 
                               WHERE TABLE_NAME = @ustrTable 
                                    AND TABLE_SCHEMA = @ustrSchema'
		;
	DROP TABLE IF EXISTS #__beQuiet ;
	CREATE TABLE #__beQuiet (Shhhh INT)---Suppresses output

	IF DB_ID(@ustrDBName) IS NOT NULL
	BEGIN 
	INSERT INTO #__beQuiet
	EXECUTE sp_executesql @SQLCheckForTable
		, N'@ustrTable NVARCHAR(64), @ustrSchema NVARCHAR(64)'
		, @ustrTable = @ustrTableName
		, @ustrSchema = @ustrSchemaName;



	SET @intRowCount = @@ROWCOUNT; 



	IF @intRowCount <> 1
	BEGIN
		SET @boolSuccessFlag = 0;
		SET @ustrMessageOut = @ustrTableName + @ustrOutGoingMessageEnd;
	END
	ELSE
	BEGIN
		SET @boolSuccessFlag = 1;
		SET @ustrMessageOut = NULL;
	END
	END
	ELSE 
	BEGIN 
		SET @ustrMessageOut = @ustrDBName + @ustrOutGoingMessageEnd;
	END
	SET NOCOUNT OFF;
	DROP TABLE #__beQuiet;
END TRY

BEGIN CATCH

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);
END CATCH;
/**
 Dynamic SQL in this procedure
SELECT 1
FROM QUOTENAME(@ustrQuotedDB).INFORMATION_SCHEMA.TABLES
WHERE 	TABLE_NAME = @ustrTable 
    AND TABLE_SCHEMA = @ustrSchema
*/

--TESTING BLOCK
/**
DECLARE @ustrTableName NVARCHAR(64) = '';
DECLARE @ustrDBName NVARCHAR(64) = '';
DECLARE @ustrSchemaName NVARCHAR(64) = '';
DECLARE @boolSuccessFlag BIT;
DECLARE @ustrMessageOut NVARCHAR(400);

EXEC Utility.UTL.DD_TableExist @ustrTableName
	, @ustrDBName
	, @ustrSchemaName
	, @boolSuccessFlag OUTPUT
	, @ustrMessageOut OUTPUT;

SELECT @boolSuccessFlag
	, @ustrMessageOut;
*/-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dave Babler
-- Create date: 08/31/2020
-- Description:	This returns a list of tables and comments based on a guessed name
-- Subprocedures: 1. DD.DBSchemaObjectAssignment

-- =============================================
CREATE OR ALTER PROCEDURE DD.TableNameLike 
	-- Add the parameters for the stored procedure here
	@strTableGuess NVARCHAR(194) --64*3+2periods 

AS
BEGIN TRY 
    SET NOCOUNT ON;




 /** Always lowercase fuzzy paramaters 
 *  You do not know the name; therefore,
 *  you cannot be sure of the case! -- Dave Babler */
-- DECLARE @strTableNameLower NVARCHAR(64) = lower(@strTableGuess);--System Funcs always ALL CAPS except lower because its 'lower'
-- DECLARE @strTableNameLowerFuzzy NVARCHAR(80) = '%' + @strTableNameLower + '%';  --split to to declare to show work, can be done one line

DECLARE @strTableNameLowerFuzzy NVARCHAR(80)
    , @ustrDatabaseName NVARCHAR(64)
	, @ustrSchemaName NVARCHAR(64)
	, @ustrObjectName NVARCHAR(64);


EXEC DD.DBSchemaObjectAssignment @strTableGuess, @ustrDatabaseName OUTPUT, @ustrSchemaName OUTPUT, @ustrObjectName OUTPUT;







SET @strTableNameLowerFuzzy = '%' + lower(@ustrObjectName) +'%';

/**When creating dynamic SQL leave one fully working example with filled in paramaters
* This way when the next person to come along to debug it sees it they know exactly what you are looking for
* I recommend putting it at the end of the code commented out with it's variable name so it doesn't create 
* code clutter. --Dave Babler */



DECLARE @SQLStatementFindTables AS NVARCHAR(1000);


SET @SQLStatementFindTables = 'SELECT 	sysObj.name AS "TableName"
	                            , ep.value AS "TableDescription" 
                                FROM '+ QUOTENAME(@ustrDatabaseName) +'.sys.sysobjects sysObj
                                INNER JOIN ' + QUOTENAME(@ustrDatabaseName)  +'.sys.tables sysTbl
                                    ON sysTbl.object_id = sysObj.id
                                LEFT JOIN '+  QUOTENAME(@ustrDatabaseName)  +'.sys.extended_properties ep
                                    ON ep.major_id = sysObj.id
                                        AND ep.name = ''MS_Description''
                                        AND ep.minor_id = 0
                                WHERE lower(sysObj.name) LIKE @strTbl';

EXECUTE sp_executesql @SQLStatementFindTables, N'@strTbl NVARCHAR(80)', @strTbl = @strTableNameLowerFuzzy;


SET NOCOUNT OFF;





END TRY
BEGIN CATCH

	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);

	PRINT 
		'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM CustomLog.ERR.DB_EXCEPTION_TANK
			)
		SELECT ErrorID
			, DatabaseName
			, UserName
			, ErrorNumber
			, ErrorState
			, ErrorLine
			, ErrorProcedure
			, ErrorMessage
			, ErrorDateTime
		FROM CustomLog.ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________

'
END CATCH;

--@SQLStatementFindTables working example is below.
-- SELECT --t.id                        as  "object_id",
-- 	sysObj.name AS "TableName"
-- 	, ep.value AS "TableDescription"
-- FROM sysobjects sysObj
-- INNER JOIN sys.tables sysTbl
-- 	ON sysTbl.object_id = sysObj.id
-- LEFT JOIN sys.extended_properties ep
-- 	ON ep.major_id = sysObj.id
-- 		AND ep.name = 'MS_Description'
-- 		AND ep.minor_id = 0
-- WHERE lower(sysObj.name) LIKE '%tank%'



--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 
    DECLARE @return_value INT

    EXEC @return_value = [DD].[TableNameLike] @strTableGuess = N'Galactic.dbo.transmon'

    SELECT 'Return Value' = @return_value`


	*/

--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
GO


USE [Utility];
GO

-- =============================================
-- Author:		Dave Babler
-- Create date: 08/26/2020
-- Description:	This can be used as a hack to suppress output of a stored procedure temporarily.  
--				It works like this: You call the fake temp table in this procedure in your wrapping proc, 
--				Then in any proc that you want to use either as an embedded procedure or a stand alone 
--				procedure you check this function for a 1 if it is a 1 you bypass output, if it is a 0  you show output.
-- =============================================
CREATE FUNCTION [UTL].[fn_SuppressOutput] (
	-- NO PARAMATERS NEEDED
	-- REMINDER EXCEPTION HANDLING WITH TRY CATCH DOES NOT WORK IN FUNCTIONS
	)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @bitSuppress BIT

	/**what do we do when you have output that you may want to suppress in another situation?
	 * Unlike Oracle we cannot suppress results, 
	 * So let's fake it!  Create a suppress results temp table in your calling proc and then 
	 * call this proc, finally drop your suppress results temp table in your calling proc when done
	 * that way this procedure is still useful as a stand alone proc.  
	 * RATHER THAN HAVING TO MEMORIZE THIS WEIRD TABLE NAME let's just memorize if this returns a 1 we suppress!
	 * -- Dave Babler 08/26/2020  */
	IF OBJECT_ID('tempdb..#__suppress_results') IS NULL
	BEGIN
		SET @bitSuppress = 0;
	END
	ELSE
	BEGIN
		SET @bitSuppress = 1;
	END

	-- Return the result of the function
	RETURN @bitSuppress
END
GO


USE [Utility];
GO
---this comment exists only to force it near the top of the heap in a github pull request---babler
-- ======================================================================================
-- Author:		Dave Babler
-- Create date:	09/15/2020
-- Description:	Splits a (small) delimited list into a single column table 
--              thus allowing the table to be used in an "IN" clause in a different
--              query, procedure, or function. 
-- 				This procedure is sadly, very useful in many different situations.
--				WARNING: TABLE VARIABLES SHOULD BE ≈1000 records or less! 
-- 				If you have more, don't use this function, make a temp table!
-- ======================================================================================
CREATE OR ALTER FUNCTION [UTL].[fn_DelimListToTable] (  
	@strDelimitedStringToParse NVARCHAR(MAX)
    , @charDelimiter CHAR(1)
)
RETURNS @tblParsedList TABLE (ValueID INT, StringValue NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS)
AS

BEGIN      
WITH RecursiveTable (
	StartingPosition
	, EndingPosition
	)
AS (
	SELECT CAST(1 AS BIGINT) StartingPosition
		, CHARINDEX(@charDelimiter, @strDelimitedStringToParse) EndingPosition
	--gets the first delimiter, the count of chars to the next one
	
	UNION ALL
	
	SELECT EndingPosition + 1
		, CHARINDEX(@charDelimiter, @strDelimitedStringToParse, EndingPosition + 1)
	--next number after the first Delimiter(starting pointer), go to next delimiter & mark that,
	FROM RecursiveTable --recursion calling from inside itself in the Common Table Expression
	WHERE EndingPosition > 0
		--keep going as long as there's more stuff in the list
	)
INSERT INTO @tblParsedList
SELECT ROW_NUMBER() OVER (
		ORDER BY (
				SELECT 1
				)
		) --Hackishway of making a sequential id.
	, TRIM(SUBSTRING(@strDelimitedStringToParse, StartingPosition, COALESCE(NULLIF(EndingPosition, 0), LEN(
				@strDelimitedStringToParse) + 1) - StartingPosition)) --TRIM to get rid of trailing spaces
FROM RecursiveTable
OPTION (MAXRECURSION 0);
                
        /**Here coalesce is what's allowing us to deal with lists where there are spaces around delimiters
         *   'red, orange , yellow,green,blue, purple'   It also helps us grab purple too--Dave Babler */
RETURN --RETURNS @tblParsedList 
END