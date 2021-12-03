
GO
-- ==========================================================================================
-- Author:			Dave Babler
-- Create date: 	2020-08-25
-- Last Edited By:	Dave Babler
-- Last Updated:	2021-12-03
-- Description:		This will either add or wipe and update the comments on a table
-- SubProcedures:	1.	[Utility].[DD].[fn_IsThisTheNameOfAView]
--					2.  [Utility].[DD].[TableExist]
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
        SET @ustrTableorObjName = PARSENAME(@ustrFQON, 1)
        SET @ustrSchemaName = PARSENAME(@ustrFQON, 2)
        SET @ustrDatabaseName = PARSENAME(@ustrFQON, 3)


	--trashy Babler trick  to stop  unneeded output since  we need to leave NOCOUNT ON
	INSERT INTO #__SuppressOutputTableAddComment
	VALUES(NULL);




		/** Next Check to see if the name is for a view instead of a table, alter the function to fit your agency's naming conventions
		 * Not necessary to check this beforehand as the previous calls will work for views and tables due to how
		 * INFORMATION_SCHEMA is set up.  Unfortunately from this point on we'll be playing with Microsoft's sys tables
		  */
		SELECT @bitIsThisAView = [DD].[fn_IsThisTheNameOfAView](@ustrTableOrObjName);

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