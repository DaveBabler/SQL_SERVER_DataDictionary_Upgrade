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


