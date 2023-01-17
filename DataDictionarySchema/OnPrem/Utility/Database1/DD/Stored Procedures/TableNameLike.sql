-- =============================================
-- Author:		Dave Babler
-- Create date: 08/31/2020
-- Description:	This returns a list of tables and comments based on a guessed name
-- Subprocedures: 1. DD.DBSchemaObjectAssignment

-- =============================================
CREATE   PROCEDURE [DD].[TableNameLike] 
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
