USE [Utility]
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
-- Subprocedures: 1. Utility.UTL.fn_DelimListToTable
-- Type Paramaters: P (procedure), FN (Scalar Function), TF (Table Function), TR (Trigger), V (View)
-- ===============================================================================
ALTER PROCEDURE [DD].[FindKeyWordInCode]
	-- Add the parameters for the stored procedure here
	@ustrDBName NVARCHAR(64)
	, @ustrKeyWord NVARCHAR(1000)
	, @dlistTypeOfCodeToSearch VARCHAR(40) = NULL
AS
BEGIN TRY
	SET NOCOUNT ON;

	DECLARE @charComma CHAR(1) = ',' -- I did not want to deal with yet another escape sequence 
		, @TSQLParameterDefinitions NVARCHAR(800)
		, @strKeyWordPrepared NVARCHAR(MAX)
		, @sqlSearchFinal NVARCHAR(MAX) = NULL;

	SET @strKeyWordPrepared = '%' + lower(@ustrKeyWord) + '%';
		--gotta add those % sinces for dynamic sql LIKE statments outside of the statement

	IF @ustrDBName IS NULL
		SELECT @ustrDBName = N'Utility';

	-- if it's null at least let the proc loop through the database it lives
	IF @dlistTypeOfCodeToSearch IS NOT NULL
	BEGIN
		/**We join the table valued function to the DD to get the types of functions we want -- Babler */
		SET @sqlSearchFinal = N'
								   SELECT DISTINCT ' + '''' + QUOTENAME(@ustrDBName) + '''' + 
			' AS DBName
                                                    , SCHEMA_NAME(schema_id) AS SchemaName
                                                    , o.name
													, o.[type]
													, o.type_desc
													, m.DEFINITION
												FROM ' 
			+ QUOTENAME(@ustrDBName) + '.sys.sql_modules m
												INNER JOIN  ' + QUOTENAME(@ustrDBName) + 
			'.sys.all_objects o
													ON m.object_id = o.object_id
												INNER JOIN Utility.UTL.fn_DelimListToTable(@dlistTypeOfCodeToSearch_ph, @charComma_ph) AS Q
													ON o.[type] = Q.StringValue COLLATE Latin1_General_CI_AS_KS_WS
												WHERE lower(m.DEFINITION) LIKE @strKeyWord_ph
												ORDER BY o.[type] '
			;

		PRINT @sqlSearchFinal;

		SET @TSQLParameterDefinitions = 
			N'@strKeyWord_ph NVARCHAR(MAX)
												, @dlistTypeOfCodeToSearch_ph NVARCHAR(24)
												, @charComma_ph CHAR(1)'
			;

		EXEC sp_executesql @sqlSearchFinal
			, @TSQLParameterDefinitions
			, @strKeyWord_ph = @strKeyWordPrepared
			, @dlistTypeOfCodeToSearch_ph = @dlistTypeOfCodeToSearch
			, @charComma_ph = @charComma;
	END
	ELSE
	BEGIN
		SET @sqlSearchFinal = N'

                                                    SELECT DISTINCT ' + '''' + QUOTENAME(
				@ustrDBName) + '''' + 
			' AS DBName
                                                    , SCHEMA_NAME(schema_id) AS SchemaName
                                                    , o.name
                                                    , o.[type]
                                                    , o.type_desc
                                                    , m.DEFINITION
                                                FROM ' 
			+ QUOTENAME(@ustrDBName) + '.sys.sql_modules m
                                               INNER JOIN ' + 
			QUOTENAME(@ustrDBName) + 
			'.sys.all_objects o
                                                ON m.object_id = o.object_id
                                            WHERE m.DEFINITION LIKE @strKeyWord_ph
                                            ORDER BY o.[type]
                                            '
			;

		PRINT @sqlSearchFinal;

		SET @TSQLParameterDefinitions = N'@strKeyWord_ph NVARCHAR(MAX)';

		EXEC sp_executesql @sqlSearchFinal
			, @TSQLParameterDefinitions
			, @strKeyWord_ph = @strKeyWordPrepared;
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
		;
END CATCH
