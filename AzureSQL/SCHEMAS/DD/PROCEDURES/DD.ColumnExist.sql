
GO

-- ==========================================================================================
-- Author:		    	Dave Babler
-- Create date:     	08/25/2020
-- Modified for Azure:  12/02/2021
-- Description:	    	Checks to see if column in table exists 
--                  	use output Boolean for logic flow in other procedures
-- 						This will work just fine for Views without further modification.
-- ==========================================================================================
CREATE
	OR

ALTER PROCEDURE [DD].[ColumnExist] @ustrTableName NVARCHAR(64)
	, @ustrColumnName NVARCHAR(64)
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

	DECLARE @intRowCount INT;
	DECLARE @SQLCheckForTable NVARCHAR(1000) = 'SELECT NULL
                               FROM INFORMATION_SCHEMA.COLUMNS 
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
		THROW;
END CATCH;





--TESTING BLOCK
/**

DECLARE @ustrTableName NVARCHAR(64) = '';
DECLARE @ustrColumnName NVARCHAR(64) = ''
DECLARE @ustrSchemaName NVARCHAR(64) = '';
DECLARE @boolSuccessFlag BIT;
DECLARE @ustrMessageOut NVARCHAR(400);

EXEC [DD].[ColumnExist] @ustrTableName
	, @ustrColumnName
	, @ustrSchemaName
	, @boolSuccessFlag OUTPUT
	, @ustrMessageOut OUTPUT;

SELECT @boolSuccessFlag
	, @ustrMessageOut;
*/
GO