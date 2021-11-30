
GO
DROP PROCEDURE IF EXISTS DD.AddColumnComment;
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

ALTER PROCEDURE [DD].[ColumnAddComment]
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
DROP TABLE IF EXISTS #__SuppressOutputColumnAddComment;

DECLARE @boolCatchFlag BIT = 0;  -- for catching and throwing a specific error. 
	--set and internally cast the VARIANT, I know it's dumb, but it's what we have to do.
SET @vrtComment = CAST(@strComment AS SQL_VARIANT);   --have to convert this to variant type as that's what the built in sp asks for.

DECLARE @ustrVariantConv NVARCHAR(MAX) = REPLACE(CAST(@vrtComment AS NVARCHAR(MAX)),'''',''''''); 
/** Explanation of the conversion above.
 *	1. 	I wanted to leave this conversion instead of just declaring as NVARCHAR. 
 *		Technically it IS stored as variant, people should be aware of this.
 *	2.	We need to deal with quotes passed in for Contractions such as "can't" which would be passed in as "can''t"
 */


	CREATE TABLE #__SuppressOutputColumnAddComment (
		SuppressedOutput VARCHAR(MAX)
	);
BEGIN TRY
	SET NOCOUNT ON;
		--we do this type of insert to prevent seeing useless selects in the grid view on a SQL developer
	EXEC DD.DBSchemaObjectAssignment @ustrFQON
												, @ustrDatabaseName OUTPUT
												, @ustrSchemaName OUTPUT
												, @ustrTableorObjName OUTPUT;
	
	 /**REVIEW: if it becomes a problem where people are typing in tables wrong  all the time (check the exception log)
	 * we can certainly add the UTL.DD_TableExist first and if that fails just dump the procedure and show an error message
	 * for now though checking for the column will also show bad table names but won't specify that it's the table, just an error
	 	-- Dave Babler 
	 */

	 
	EXEC DD.ColumnExist @ustrTableorObjName
		, @strColumnName
		, @ustrDatabaseName
		, @ustrSchemaName
		, @boolExistFlag OUTPUT
		, @ustrMessageOut OUTPUT;


		/** Next Check to see if the name is for a view instead of a table, alter the function to fit your agency's naming conventions
		 * Not necessary to check this beforehand as the previous calls will work for views and tables due to how
		 * INFORMATION_SCHEMA is set up.  Unfortunately from this point on we'll be playing with Microsoft's sys tables
		  */
		SET @bitIsThisAView = DD.fn_IsThisTheNameOfAView(@ustrTableorObjName);

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
			INSERT INTO #__SuppressOutputColumnAddComment
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
		DROP TABLE IF EXISTS #__SuppressOutputColumnAddComment;
	SET NOCOUNT OFF
END TRY

BEGIN CATCH
	IF @boolCatchFlag = 1
	BEGIN

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
	END
	ELSE
	BEGIN

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
	END

	PRINT 
		'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM ERR.DB_EXCEPTION_TANK
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
		FROM ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________

'




--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 
	DECLARE @ustrFullyQualifiedTable NVARCHAR(64) = N'';
	DECLARE @strColName VARCHAR(64) = '';
	DECLARE @ustrComment NVARCHAR(400) = N'';

	EXEC DD.ColumnAddComment @ustrFullyQualifiedTable
		, @strColName
		, @ustrComment; 

	*/

--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
--dddddddddddddddddddddddddddddddddddddddddddd--DynamicSQLAsRegularBlock--dddddddddddddddddddddddddddddddddddddddddddddd
	/*
	--Place your dynamic SQL block here as normal SQL so others know what you are doing!
	--if you are concatenating to a large block of Dynamic SQL use your best judgement if all of it needs to be down here or not
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
--DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
END CATCH







GO


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





--TESTING BLOCK
/**

DECLARE @ustrTableName NVARCHAR(64) = '';
DECLARE @ustrDBName NVARCHAR(64) = '';
DECLARE @ustrColumnName NVARCHAR(64) = ''
DECLARE @ustrSchemaName NVARCHAR(64) = '';
DECLARE @boolSuccessFlag BIT;
DECLARE @ustrMessageOut NVARCHAR(400);

EXEC [DD].[ColumnExist] @ustrTableName
	, @ustrColumnName
	, @ustrDBName
	, @ustrSchemaName
	, @boolSuccessFlag OUTPUT
	, @ustrMessageOut OUTPUT;

SELECT @boolSuccessFlag
	, @ustrMessageOut;
*/
GO


GO 
--update change ShowColumnComment to a more standardized noun then verb style
DROP PROCEDURE IF EXISTS DD.ShowColumnComment

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
CREATE
	OR

ALTER PROCEDURE [DD].[ColumnShowComment]
	-- Add the parameters for the stored procedure here
	@ustrFQON NVARCHAR(64)
	, @ustrColumnName NVARCHAR(64)
AS
DECLARE @ustrMessageOut NVARCHAR(320)
	, @ustrDatabaseName NVARCHAR(64)
	, @ustrSchemaName NVARCHAR(64)
	, @ustrTableOrObjName NVARCHAR(64)
	, @intRowCount INT
	, @boolExistFlag BIT
	, @dSQLCheckForComment NVARCHAR(MAX)
	, @dSQLPullComment NVARCHAR(MAX)
	, @dSQLPullCommentParameters NVARCHAR(MAX);

DROP TABLE IF EXISTS #__SuppressOutputColumnComment
	CREATE TABLE #__SuppressOutputColumnComment (SuppressedOutput VARCHAR(MAX))

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
                    FROM ' + QUOTENAME(@ustrDatabaseName
			) + '.sys.extended_properties
                    WHERE [major_id] = OBJECT_ID(' + '''' + @ustrDatabaseName + '.' + 
			@ustrSchemaName + '.' + @ustrTableOrObjName + '''' + 
			')
                        AND [name] = N''MS_Description''
                        AND [minor_id] = (
                            SELECT [column_id]
                            FROM ' 
			+ QUOTENAME(@ustrDatabaseName) + '.sys.columns
                            WHERE [name] = ' + '''' + 
			@ustrColumnName + '''' + '
                                AND [object_id] = OBJECT_ID(' + '''' + @ustrDatabaseName 
			+ '.' + @ustrSchemaName + '.' + @ustrTableOrObjName + '''' + ')
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
			SET @dSQLPullComment = 
				N'
                SELECT TOP 1 @ustrMessageOutTemp = CAST(ep.value AS  NVARCHAR(320))
                FROM ' 
				+ QUOTENAME(@ustrDataBaseName) + '.sys.extended_properties AS ep
                INNER JOIN ' + QUOTENAME(
					@ustrDataBaseName) + 
				'.sys.all_objects AS ob
                    ON ep.major_id = ob.object_id
                INNER JOIN ' 
				+ QUOTENAME(@ustrDataBaseName) + 
				'.sys.tables AS st
                    ON ob.object_id = st.object_id
                INNER JOIN ' + 
				QUOTENAME(@ustrDataBaseName) + 
				'.sys.columns AS c	
                    ON ep.major_id = c.object_id
                        AND ep.minor_id = c.column_id
                WHERE st.name = @ustrTableOrObjName
                    AND c.name = @ustrColumnName'
				;
			SET @dSQLPullCommentParameters = 
				N' @ustrColumnName NVARCHAR(64)
                                , @ustrTableOrObjName NVARCHAR(64)
                                , @ustrMessageOutTemp NVARCHAR(320) OUTPUT'
				;

			EXECUTE sp_executesql @dSQLPullComment
				, 
				N'@ustrColumnName NVARCHAR(64)
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
				N' currently has no comments please use DD.ColumnAddComment to add a comment!';
		END

		SELECT @ustrColumnName AS 'ColumnName'
			, @ustrMessageOut AS 'ColumnComment';
	END
	ELSE
	BEGIN
		SET @ustrMessageOut = 'Either the column you typed in: ' + @ustrColumnName + ' or, ' + ' the table you typed in: ' + 
			@ustrFQON + ' ' + 'is invalid, check spelling, try again? ';

		SELECT @ustrMessageOut AS 'NON_LOGGED_ERROR_MESSAGE'
	END
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
			FROM ERR.DB_EXCEPTION_TANK
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
		FROM ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________
'
		;
END CATCH
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 

            DECLARE	@return_value int

            EXEC	@return_value = [DD].[ColumnShowComment]
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
GO



SELECT OBJECT_NAME(qt.objectid) AS ObjectName
	, qs.execution_count AS [Execution Count]
	, qs.execution_count / DATEDIFF(Second, qs.creation_time, GETDATE()) AS [Calls/Second]
	, qs.total_worker_time / qs.execution_count AS [AvgWorkerTime]
	, qs.total_worker_time AS [TotalWorkerTime]
	, qs.total_elapsed_time / qs.execution_count AS [AvgElapsedTime]
	, qs.max_logical_reads
	, qs.max_logical_writes
	, qs.total_physical_reads
	, DATEDIFF(Minute, qs.creation_time, GETDATE()) AS [Age in Cache]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
WHERE qt.[dbid] NOT IN (1, 2, 3, 4)
	AND OBJECT_NAME(qt.objectid) IS NOT NULL
	AND LEFT(OBJECT_NAME(qt.objectid), 2) NOT IN ('sp', 'xp')
	AND OBJECT_NAME(qt.objectid) NOT LIKE '%sqlagent%'
ORDER BY qs.execution_count DESC
OPTION (RECOMPILE);
--to do, put in sp_foreach 	


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
--      			Also, YES I KNOW ABOUT PARSENAME.  I like *my* proc better, thanks!
-- XXPPQQZZ 		YOU FILL THIS IN WITH YOUR VALUES BEFORE STARTING THEN DELETE THIS LINE OF COMMENT!
-- Subprocedures: 	1. [Utility].[DD].[fn_DBSchemaObjCheck]
-- 					2 sp_executesql -- system procedure, dynamic SQL.
--
-- =============================================
CREATE
	OR

ALTER PROCEDURE [DD].[DBSchemaObjectAssignment]
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
	DECLARE @ustrDefaultSchema NVARCHAR(64) = 'XXPPQQZZ';--WE WOULD FILL THIS IN.
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

	PRINT @intDelimCountChecker;

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
	END
	ELSE
	BEGIN
		SET @ustrSchemaName = @ustrDefaultSchema;
		SET @ustrDatabaseName = @ustrDefaultDatabase;
		SET @ustObjectOrTableName = @strQualifiedObjectBeingCalled;
	END

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
-- Subprocedures: 1. DD.TableShowComment
-- 				  2. UTL_fn_DelimListToTable  (already exists, used to have diff name)
-- =============================================
ALTER   PROCEDURE [DD].[Describe]
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
		EXEC DD.DBSchemaObjectAssignment @str_input_TableName
			, @ustrDatabaseName OUTPUT
			, @ustrSchemaName OUTPUT
			, @ustrTableorObjName OUTPUT;



			/**Check to see if the table exists, if it does not we will output an Error Message
        * however since we are not writing anything to the DD we won't go through the whole RAISEEROR 
        * or THROW and CATCH process, a simple output is sufficient. -- Babler
        */



    EXEC DD.TableExist @ustrTableorObjName
	, @ustrDatabaseName
	, @ustrSchemaName
	, @bitSuccessFlag OUTPUT
	, @strMessageOut OUTPUT; 

    IF @bitSuccessFlag = 1

	
	BEGIN
		-- we want to suppress results (perhaps this could be proceduralized as well one to make the table one to kill?)
		CREATE TABLE #__suppress_results (col1 INT);

		EXEC DD.TableShowComment @str_input_TableName
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
                            , ist.TABLE_SCHEMA + ''.'' + pk_tab.name AS ReferencedTable
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
                            AND pk_col.object_id = fk_cols.referenced_object_id
                        LEFT JOIN ' + @ustrDatabaseName +'.INFORMATION_SCHEMA.TABLES ist
                                ON ist.TABLE_NAME = tab.name
                        WHERE fk.name IS NOT NULL
                            AND tab.name = @ustrTableName_d
                            AND ist.TABLE_SCHEMA = @ustrSchemaName_d
                            
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
                                            SELECT '', '' + IndexName
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
                        , CAST(CASE lower(col.IS_NULLABLE)
                                WHEN ''no''
                                    THEN 0
                                ELSE 1
                                END AS BIT) AS IsNullable
                        , COLUMNPROPERTY(OBJECT_ID('' ['' + col.TABLE_SCHEMA + ''].['' + col.TABLE_NAME + ''] ''), col.COLUMN_NAME, '' IsComputed 
                            '') AS IsComputed
                        , COLUMNPROPERTY(OBJECT_ID('' ['' + col.TABLE_SCHEMA + ''].['' + col.TABLE_NAME + ''] ''), col.COLUMN_NAME, '' IsIdentity 
                            '') AS IsIdentity
                        , CAST(ISNULL(pk.is_primary_key, 0) AS BIT) AS IsPrimaryKey
                        , '' FK of: '' + fkeys.ReferencedTable + ''.'' + fkeys.PrimaryKeyColumnName AS ReferencedTablePrimaryKey
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
PRINT CAST(@dSQLBuildDescribe AS NTEXT); 

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
		FROM ##DESCRIBE
        ORDER BY 2; --WE HAVE TO OUTPUT IT. 
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

        
PRINT 
	'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM ERR.DB_EXCEPTION_TANK
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
		FROM ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________
';
END CATCH
GO

-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:		Dave Babler
-- Create date: 2021-05-02
-- Description:	This finds code across database based upon a keyword. 
--              It outputs it to a global temp table for further study.
-- To Do: 		1. Find a better way of dealing with looping through the databases. 
-- 				2. Dump to temp table for further sorting, current tries failed.		
-- ==========================================================================================
CREATE
	OR

ALTER PROCEDURE DD.FindKeyTextAcrossDatabases
	-- Add the parameters for the stored procedure here
	@ustrKeyWord NVARCHAR(1000)
	, @dlistTypeOfCodeToSearch NVARCHAR(40) = NULL
AS
BEGIN TRY
	SET XACT_ABORT ON;-- 
	SET NOCOUNT ON;
		DROP TABLE	IF EXISTS #FindKeyTextAcrossDatabases
		DROP TABLE	IF EXISTS ##FindKeyTextAcrossDatabases
	
		CREATE TABLE ##FindKeyTextAcrossDatabases (
			DBName NVARCHAR(64)
			, SchemaName NVARCHAR(64)
			, ObjectName NVARCHAR(64)
			, ObjectType NVARCHAR(64)
			, DescriptiveObjectType NVARCHAR(64)
			, SourceCode NVARCHAR(MAX)
			);

		CREATE TABLE #__FindKeyTextAcrossDatabases (
			DBName NVARCHAR(64)
			, SchemaName NVARCHAR(64)
			, ObjectName NVARCHAR(64)
			, ObjectType NVARCHAR(64)
			, DescriptiveObjectType NVARCHAR(64)
			, SourceCode NVARCHAR(MAX)
			);

	DECLARE @dSQLStatement NVARCHAR(MAX);

	IF @dlistTypeOfCodeToSearch IS NOT NULL
	BEGIN
		SET @dSQLStatement = 
			N'
            DECLARE @ustrDBNAME NVARCHAR(64);
        IF ''?'' <> ''master'' AND ''?'' <> ''model'' AND ''?'' <> ''msdb'' AND ''?'' <> ''tempdb''
            BEGIN 
            USE [?]
        EXEC DD.FindKeyWordInCode [?], ' 
                    + '''' + @ustrKeyWord + '''' + ',' + '''' + @dlistTypeOfCodeToSearch + '''' + 'END';
	END
	ELSE
	BEGIN 
		--it would end up trying to quote pass a null value which is problematic so just break it out and pass no paramater since it's optional
		SET @dSQLStatement = 
                    N'
            DECLARE @ustrDBNAME NVARCHAR(64);
        IF ''?'' <> ''master'' AND ''?'' <> ''model'' AND ''?'' <> ''msdb'' AND ''?'' <> ''tempdb''
            BEGIN 
            USE [?]
			PRINT ' + '''' + @ustrKeyWord + '''' +'
            
        EXEC DD.FindKeyWordInCode [?], ' 
			+ '''' + @ustrKeyWord + '''' + ' END ';
	END

	--INSERT INTO #__FindKeyTextAcrossDatabases (
	--	DBName
	--	, SchemaName
	--	, ObjectName
	--	, ObjectType
	--	, DescriptiveObjectType
	--	, SourceCode
	--	)
	EXEC sp_MSforeachdb @dSQLStatement
--INSERT INTO ##FindKeyTextAcrossDatabases(
--DBName
--		, SchemaName
--		, ObjectName 
--		, ObjectType
--		, DescriptiveObjectType
--		, SourceCode
--)
	--SELECT 		DBName
	--	, SchemaName
	--	, ObjectName 
	--	, ObjectType
	--	, DescriptiveObjectType
	--	, SourceCode
	--FROM #__FindKeyTextAcrossDatabases

	--select *
	--from ##FindKeyTextAcrossDatabases

	SET XACT_ABORT OFF;-- 
END TRY

BEGIN CATCH
	IF (XACT_STATE()) = - 1 --test to see if we cannot commit
	BEGIN
		PRINT N'The transaction is in an uncommittable state.' + 'Rolling back transaction.'

		ROLLBACK TRANSACTION;

		SET XACT_ABORT OFF;
			-- currently our database has this as default so we need to double check it turns off on fail or success
	END;

	IF (XACT_STATE()) = 1 -- Test if the transaction is committable.  
	BEGIN
		PRINT N'The transaction is committable.' + 'Committing transaction.'

		COMMIT TRANSACTION;

		SET XACT_ABORT OFF;
			-- currently our database has this as default so we need to triple check it turns off on fail or success
	END;

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
GO


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    /*
        
        GO

        DECLARE	@return_value int

        EXEC	@return_value = [DD].[FindKeyTextAcrossDatabases]
                @ustrKeyWord = N'test',
                @dlistTypeOfCodeToSearch = 'P, TF'

        SELECT	'Return Value' = @return_value

GO	
    */
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

		--, (DATALENGTH(@ustrKeyWord) - (DATALENGTH(REPLACE(lower(@ustrKeyWord), lower(SourceCode), ''))/DATALENGTH(@ustrKeyWord))) AS 'APPROXcOUNT'


		
GO

/****** Object:  StoredProcedure [DD].[FindKeyWordInCode]    Script Date: 5/4/2021 8:12:44 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ===============================================================================
-- Author:		Dave Babler
-- Create date: 9/16/2020
-- Description:	Searches through all stored procedures, views, and functions 
--				(based on selection)  for a specific keyword
-- Subprocedures: 1. UTL.fn_DelimListToTable
-- Type Paramaters: P (procedure), FN (Scalar Function), TF (Table Function), TR (Trigger), V (View)
-- ===============================================================================
ALTER PROCEDURE [DD].[FindKeyWordInCode]
	-- Add the parameters for the stored procedure here
	@ustrDBName NVARCHAR(64)
	, @ustrKeyWord NVARCHAR(1000)
	, @dlistTypeOfCodeToSearch VARCHAR(40) = NULL
AS
BEGIN TRY
	SET XACT_ABORT ON;
	SET NOCOUNT ON;

	DECLARE @charComma CHAR(1) = ',' -- I did not want to deal with yet another escape sequence 
		, @TSQLParameterDefinitions NVARCHAR(800)
		, @strKeyWordPrepared NVARCHAR(MAX)
		, @sqlSearchFinal NVARCHAR(MAX) = NULL;

	SET @strKeyWordPrepared = '%' + lower(@ustrKeyWord) + '%';
	PRINT @strKeyWordPrepared
		--gotta add those % sinces for dynamic sql LIKE statments outside of the statement

	IF @ustrDBName IS NULL
		SELECT @ustrDBName = N'Utility';

	-- if it's null at least let the proc loop through the database it lives
	IF @dlistTypeOfCodeToSearch IS NOT NULL
	BEGIN
		/**We join the table valued function to the DD to get the types of functions we want -- Babler */
		SET @sqlSearchFinal = N'
								   SELECT DISTINCT ' + '''' + QUOTENAME(@ustrDBName) + '''' + 
			' COLLATE Latin1_General_CI_AS AS DBName
                                                    , SCHEMA_NAME(schema_id) COLLATE Latin1_General_CI_AS AS SchemaName 
                                                    , o.name COLLATE Latin1_General_CI_AS AS ObjectName
													, o.[type] COLLATE Latin1_General_CI_AS AS ObjectType
													, o.type_desc COLLATE Latin1_General_CI_AS AS DescriptiveObjectType
																										, UTL.fn_CountOccurrencesOfString(m.DEFINITION, '  + '''' + @ustrKeyWord +   '''' +  ')
													, CAST( m.DEFINITION AS NVARCHAR(MAX)) COLLATE Latin1_General_CI_AS AS Definition
												FROM ' 
			+ QUOTENAME(@ustrDBName) + '.sys.sql_modules m
												INNER JOIN  ' + QUOTENAME(@ustrDBName) + 
			'.sys.objects o
													ON m.object_id = o.object_id
												INNER JOIN UTL.fn_DelimListToTable(@dlistTypeOfCodeToSearch_ph, @charComma_ph) AS Q
													ON o.[type] = Q.StringValue COLLATE Latin1_General_CI_AS
												WHERE lower(m.DEFINITION) LIKE ' + '''' + @strKeyWordPrepared + '''' + '
												ORDER BY o.[type]  COLLATE Latin1_General_CI_AS '
			;

		PRINT @sqlSearchFinal;

		SET @TSQLParameterDefinitions = 
			N' @dlistTypeOfCodeToSearch_ph NVARCHAR(24)
												, @charComma_ph CHAR(1)'
			;

		EXEC sp_executesql @sqlSearchFinal
			, @TSQLParameterDefinitions
			, @dlistTypeOfCodeToSearch_ph = @dlistTypeOfCodeToSearch
			, @charComma_ph = @charComma;
	END
	ELSE
	BEGIN
		SET @sqlSearchFinal = N'

                                                    SELECT DISTINCT ' + '''' + QUOTENAME(
				@ustrDBName) + '''' + 
			' COLLATE Latin1_General_CI_AS AS DBName
                                                    , SCHEMA_NAME(schema_id) COLLATE Latin1_General_CI_AS AS SchemaName
                                                    , o.name COLLATE Latin1_General_CI_AS AS ObjectName
                                                    , o.[type] COLLATE Latin1_General_CI_AS AS ObjectType
                                                    , o.type_desc COLLATE Latin1_General_CI_AS AS DescriptiveObjectType
													, UTL.fn_CountOccurrencesOfString(m.DEFINITION, ' +  '''' + @ustrKeyWord +   '''' + ustrKeyWord + ')
                                                    , CAST( m.DEFINITION AS NVARCHAR(MAX)) COLLATE Latin1_General_CI_AS AS Definition
                                                FROM ' 
			+ QUOTENAME(@ustrDBName) + '.sys.sql_modules m
                                               INNER JOIN ' + 
			QUOTENAME(@ustrDBName) + 
			'.sys.objects o
                                                ON m.object_id = o.object_id
                                            WHERE m.DEFINITION LIKE ' + '''' + @strKeyWordPrepared + '''' + '
                                            ORDER BY o.[type]  COLLATE Latin1_General_CI_AS
                                            '
			;

		PRINT @sqlSearchFinal;


		EXEC sp_executesql @sqlSearchFinal

	END
	SET XACT_ABORT OFF;
END TRY

BEGIN CATCH
	IF (XACT_STATE()) = - 1 --test to see if we cannot commit
	BEGIN
		PRINT N'The transaction is in an uncommittable state.' + 'Rolling back transaction. INSIDE KeywordinCode'



		SET XACT_ABORT OFF;
			-- currently our database has this as default so we need to double check it turns off on fail or success
	END;

	IF (XACT_STATE()) = 1 -- Test if the transaction is committable.  
	BEGIN
		PRINT N'The transaction is committable.' + 'Committing transaction.'



		SET XACT_ABORT OFF;
			-- currently our database has this as default so we need to triple check it turns off on fail or success
	END;

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
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/*
		
		GO

		DECLARE	@return_value int

		EXEC	@return_value = [DD].[FindKeyWordInCode]
				@ustrDBName = NULL,
				@ustrKeyWord = N'FOreAch',
				@dlistTypeOfCodeToSearch = NULL

		SELECT	'Return Value' = @return_value

		GO

	*/
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv


GO


-- =============================================
-- Author:		Dave Babler
-- Create date: 2021-05-03
-- Description:	Returns a table of recent edits to the server
-- =============================================
CREATE
	OR

ALTER PROCEDURE DD.ObjectsEditedLast7Days
AS
BEGIN TRY
	DROP TABLE

	IF EXISTS #_ObjectsEdited;
		DROP TABLE

	IF EXISTS ##ObjectsEditedLast7Days
		CREATE TABLE #_ObjectsEdited (
			-- Add the column definitions for the TABLE variable here
			DBName NVARCHAR(MAX)
			, SchemaName NVARCHAR(MAX)
			, ObjectName NVARCHAR(MAX)
			, DescriptiveObjectType NVARCHAR(MAX)
			, DateModifed DATETIME
			)

	DECLARE @dSQLStatement NVARCHAR(MAX);

	SET @dSQLStatement = 
		N'
	USE [?]
	IF DB_Name() = ''Tempdb''BEGIN RETURN END
	SELECT DB_NAME() AS DBName
	, SCHEMA_NAME(schema_id) AS SchemaName
	, so.name AS ObjectName
	, type_desc AS DescriptiveObjectType
	, modify_date AS DateModified
FROM sys.all_objects so
WHERE DATEDIFF(D, modify_date, GETDATE()) < 7'
		;

	INSERT INTO #_ObjectsEdited (
		DBName
		, SchemaName
		, ObjectName
		, TypeOfObject
		, DateModifed
		)
	EXEC sp_MSforeachdb @dSQLStatement

	SELECT *
	INTO ##ObjectsEditedLast7Days
	FROM #_ObjectsEdited;

	SELECT *
	FROM ##ObjectsEditedLast7Days;--WON'T DROP SO YOU CAN FILTER FROM IT

	DROP TABLE #_ObjectsEdited;
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
GO

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
/*
  
        
        EXECUTE	DD.ObjectsEditedLast7Days
        
        SELECT	*
        FROM ##ObjectsEditedLast7Days
        WHERE SchemaName = 'dbo'
    */
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv


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
CREATE OR ALTER PROCEDURE DD.TableAddComment
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

DROP TABLE IF EXISTS #__SuppressOutputTableAddComment; 

DECLARE @boolCatchFlag BIT = 0;  -- for catching and throwing a specific error. 
	--set and internally cast the VARIANT, I know it's dumb, but it's what we have to do.
SET @vrtComment = CAST(@strComment AS SQL_VARIANT);   --have to convert this to variant type as that's what the built in sp asks for.

DECLARE @ustrVariantConv NVARCHAR(MAX) = REPLACE(CAST(@vrtComment AS NVARCHAR(MAX)),'''',''''''); 
/** Explanation of the conversion above.
 *	1. 	I wanted to leave this conversion instead of just declaring as NVARCHAR. 
 *		Technically it IS stored as variant, people should be aware of this.
 *	2.	We need to deal with quotes passed in for Contractions such as "can't" which would be passed in as "can''t"
 */

DROP TABLE IF EXISTS #__SuppressOutputTableAddComment;
CREATE TABLE #__SuppressOutputTableAddComment (
	SuppressedOutput VARCHAR(MAX)
);

BEGIN TRY
	SET NOCOUNT ON;
	--break apart the fully qualified object name
	INSERT INTO #__SuppressOutputTableAddComment
	EXEC [Utility].[DD].[DBSchemaObjectAssignment] @ustrFQON
												, @ustrDatabaseName OUTPUT
												, @ustrSchemaName OUTPUT
												, @ustrTableOrObjName OUTPUT;


	INSERT INTO #__SuppressOutputTableAddComment
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

		INSERT INTO #__SuppressOutputTableAddComment
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
				INSERT INTO #__SuppressOutputTableAddComment
				EXEC sp_executesql @dSQLApplyComment;

	DROP TABLE IF EXISTS #__SuppressOutputTableAddComment;
	SET NOCOUNT OFF
END TRY

BEGIN CATCH
	IF @boolCatchFlag = 1
	BEGIN

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
		, CONCAT( N'Boolean flag thrown!', CAST(ERROR_MESSAGE() AS NVARCHAR(2000)))
		, GETDATE()
		);
	END
	ELSE
	BEGIN

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
	END

	PRINT 
		'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM ERR.DB_EXCEPTION_TANK
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
		FROM ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________

'

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 
	DECLARE @ustrFullyQualifiedTable NVARCHAR(64) = N'';
	DECLARE @ustrComment NVARCHAR(400) = N'';

	EXEC DD.TableAddComment @ustrFullyQualifiedTable
		, @ustrComment; 
	
*/


 --dddddddddddddddddddddddddddddddddddddddddddd--DynamicSQLAsRegularBlock--dddddddddddddddddddddddddddddddddddddddddddddd
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
 --DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD


	--Bibliography
	--   https://stackoverflow.com/questions/20757804/execute-stored-procedure-from-stored-procedure-w-dynamic-sql-capturing-output 



--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
END CATCH;
 


GO


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

EXEC UTL.DD_TableExist @ustrTableName
	, @ustrDBName
	, @ustrSchemaName
	, @boolSuccessFlag OUTPUT
	, @ustrMessageOut OUTPUT;

SELECT @boolSuccessFlag
	, @ustrMessageOut;
*/
GO

-- ================================================
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

	PRINT 
		'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM ERR.DB_EXCEPTION_TANK
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
		FROM ERR.DB_EXCEPTION_TANK et
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


GO
-- Delete old procedure update to noun verb form
DROP PROCEDURE IF EXISTS DD.ShowTableComment;
GO

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

ALTER PROCEDURE DD.TableShowComment @ustrFQON NVARCHAR(200)
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

CREATE TABLE #__SuppressOutputTableShowComment (SuppressedOutput VARCHAR(MAX))

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
									FROM ' + QUOTENAME(@ustrDataBaseName) + '.sys.extended_properties' + 
			' WHERE [major_id] = OBJECT_ID(' + '''' + @ustrDatabaseName + '.' + @ustrSchemaName + '.' + @ustrTableOrObjName + '''' + ')' 
			+ ' AND [name] = N''MS_Description''
										AND [minor_id] = 0';

		INSERT INTO #__SuppressOutputTableShowComment
		EXEC sp_executesql @dSQLCheckForComment;

		SET @intRowCount = @@ROWCOUNT;

		IF @intRowCount != 0
		BEGIN
			SET @dSQLPullComment = N'
								
								SELECT   @ustrMessageOutTemp  = epExtendedProperty
								FROM ' 
				+ QUOTENAME(@ustrDataBaseName) + 
				'.INFORMATION_SCHEMA.TABLES AS t
								INNER JOIN (
									
									SELECT OBJECT_NAME(ep.major_id, DB_ID(' 
				+ '''' + @ustrDataBaseName + '''' + 
				')) AS [epTableName]
										, CAST(ep.Value AS NVARCHAR(320)) AS [epExtendedProperty]
									FROM ' 
				+ QUOTENAME(@ustrDataBaseName) + 
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
				, 
				N' @ustrDatabaseName NVARCHAR(64)
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
			SET @ustrMessageOut = @ustrDataBaseName + '.' + @ustrSchemaName + '.' + @ustrTableOrObjName + 
				N' currently has no comments please use DD.TableAddComment to add comments!';
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
		SET @ustrMessageOut = ' The table you typed in: ' + @ustrTableOrObjName + ' ' + 'is invalid, check spelling, try again? '
			;

		SELECT @ustrMessageOut AS 'NON_LOGGED_ERROR_MESSAGE'
	END
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

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/* 
	DECLARE @ustrFullyQualifiedTable NVARCHAR(64) = N'';
	DECLARE @boolOptionalSuccessFlag BIT = NULL;
	DECLARE @strOptionalMessageOut NVARCHAR(320) = NULL;

	EXEC DD.TableShowComment @ustrFullyQualifiedTable
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
END CATCH

PRINT 
	'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM ERR.DB_EXCEPTION_TANK
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
		FROM ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________

'
GO


----

