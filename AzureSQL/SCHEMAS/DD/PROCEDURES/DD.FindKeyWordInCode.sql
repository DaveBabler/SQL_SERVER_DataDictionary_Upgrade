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