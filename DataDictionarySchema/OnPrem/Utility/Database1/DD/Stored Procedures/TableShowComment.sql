
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
	

 PROCEDURE [DD].[TableShowComment] @ustrFQON NVARCHAR(200)
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

CREATE TABLE #__SuppressOutputTableShowComment(
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
										
					INSERT INTO #__SuppressOutputTableShowComment
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
				N' currently has no comments please use Utility.DD.TableAddComment to add comments!';
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

	EXEC Utility.DD.TableShowComment @ustrFullyQualifiedTable
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

