-- ===============================================================================
-- Author:		Dave Babler
-- Create date: 9/16/2020
-- Description:	Searches through all stored procedures, views, and functions 
--				(based on selection)  for a specific keyword
-- Subprocedures: 1. Utility.UTL.fn_DelimListToTable
-- Type Paramaters: P (procedure), FN (Scalar Function), TF (Table Function), TR (Trigger), V (View)
-- ===============================================================================
CREATE OR ALTER PROCEDURE DD.FindKeyWordInCode
	-- Add the parameters for the stored procedure here
	@strKeyWord NVARCHAR(MAX)
	, @dlistTypeOfCodeToSearch VARCHAR(40) = NULL
AS
BEGIN TRY
SET NOCOUNT ON;

DECLARE @charComma CHAR(1) = ',' -- I did not want to deal with yet another escape sequence 
	, @TSQLParameterDefinitions NVARCHAR(800)
	, @strKeyWordPrepared NVARCHAR(MAX)
	, @sqlSearchFinal NVARCHAR(MAX) = NULL;
	
SET @strKeyWordPrepared =   '%' + @strKeyWord + '%'; --gotta add those % sinces for dynamic sql LIKE statments outside of the statement


	IF @dlistTypeOfCodeToSearch IS NOT NULL
		BEGIN
		/**We join the table valued function to the DD to get the types of functions we want -- Babler */
			SET @sqlSearchFinal = 
								   N'SELECT DISTINCT o.name
													, o.[type]
													, o.type_desc
													, m.DEFINITION
												FROM sys.sql_modules m
												INNER JOIN sys.all_objects o
													ON m.object_id = o.object_id
												INNER JOIN Utility.UTL.fn_DelimListToTable(@dlistTypeOfCodeToSearch_ph, @charComma_ph) AS Q
													ON o.[type] = Q.StringValue COLLATE Latin1_General_CI_AS_KS_WS
												WHERE m.DEFINITION LIKE @strKeyWord_ph
												ORDER BY o.[type] ';
			SET @TSQLParameterDefinitions = N'@strKeyWord_ph NVARCHAR(MAX)
												, @dlistTypeOfCodeToSearch_ph NVARCHAR(24)
												, @charComma_ph CHAR(1)';
			EXEC sp_executesql @sqlSearchFinal
								, @TSQLParameterDefinitions
								, @strKeyWord_ph = @strKeyWordPrepared
								, @dlistTypeOfCodeToSearch_ph = @dlistTypeOfCodeToSearch
								, @charComma_ph = @charComma;
		END
	ELSE
		BEGIN
			SET @sqlSearchFinal = 
									N'SELECT DISTINCT o.name
													, o.[type]
													, o.type_desc
													, m.DEFINITION
												FROM sys.sql_modules m
												INNER JOIN sys.objects o
													ON m.object_id = o.object_id
												WHERE m.DEFINITION LIKE @strKeyWord_ph
												ORDER BY o.[type] ' ;

				SET @TSQLParameterDefinitions = N'@strKeyWord_ph NVARCHAR(MAX)';
				EXEC sp_executesql @sqlSearchFinal
									, @TSQLParameterDefinitions
									, @strKeyWord_ph = @strKeyWordPrepared;
		END
		



END TRY

BEGIN CATCH
	INSERT INTO dbo.DB_EXCEPTION_TANK
	VALUES (
		SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_PROCEDURE()
		, ERROR_LINE()
		, ERROR_MESSAGE()
		, GETDATE()
		);
END CATCH;
	/** SELECT DISTINCT o.name
*   	, o.[type]
*   	, o.type_desc
*   	, m.DEFINITION
*   FROM sys.sql_modules m
*   INNER JOIN sys.objects o
*   	ON m.object_id = o.object_id
*   WHERE m.DEFINITION LIKE '%PAY%' 
*   	--do not need to convert to lower on this DD deals with that for us in this and only this type of case.
*   	AND o.[type] IN ('P', 'TF', 'FN', 'V');
 */
