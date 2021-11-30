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

	INSERT INTO ERR.DB_EXCEPTION_TANK (
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
*/
GO