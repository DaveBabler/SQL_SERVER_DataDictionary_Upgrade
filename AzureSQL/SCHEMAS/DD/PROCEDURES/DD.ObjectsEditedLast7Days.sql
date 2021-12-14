
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
'
		;

	INSERT INTO #_ObjectsEdited (
		DBName
		, SchemaName
		, ObjectName
		, DescriptiveObjectType
		, DateModifed
		)
	SELECT DB_NAME() AS DBName
	, SCHEMA_NAME(schema_id) AS SchemaName
	, so.name AS ObjectName
	, type_desc AS DescriptiveObjectType
	, modify_date AS DateModified
FROM sys.all_objects so
WHERE DATEDIFF(D, modify_date, GETDATE()) < 7;

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
