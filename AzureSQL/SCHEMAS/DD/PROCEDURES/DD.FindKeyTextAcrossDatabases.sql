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
        EXEC Utility.DD.FindKeyWordInCode [?], ' 
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
            
        EXEC Utility.DD.FindKeyWordInCode [?], ' 
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
        USE [Utility]
        GO

        DECLARE	@return_value int

        EXEC	@return_value = [DD].[FindKeyTextAcrossDatabases]
                @ustrKeyWord = N'test',
                @dlistTypeOfCodeToSearch = 'P, TF'

        SELECT	'Return Value' = @return_value

GO	
    */
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv