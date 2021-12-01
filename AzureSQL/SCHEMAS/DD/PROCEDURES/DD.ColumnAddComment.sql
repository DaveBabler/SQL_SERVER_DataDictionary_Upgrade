
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
CREATE OR ALTER PROCEDURE [DD].[ColumnAddComment]
    -- Add the parameters for the stored procedure here
    @ustrFQON      NVARCHAR(64)
  , @strColumnName NVARCHAR(64)
  , @strComment    NVARCHAR(360)
AS
    /**Note: vrt is for Variant, which is the absurd way SQL Server stores it's Strings in the data dictionary
* supposedly for 'security' --Dave Babler*/
    DECLARE @vrtComment                  SQL_VARIANT
          , @strErrorMessage             VARCHAR(MAX)
          , @ustrDatabaseName            NVARCHAR(64)
          , @ustrSchemaName              NVARCHAR(64)
          , @ustrTableorObjName          NVARCHAR(64)
          , @dSQLNotExistCheck           NVARCHAR(MAX)
          , @dSQLNotExistCheckProperties NVARCHAR(MAX)  -- could recycle previous var, don't want to
          , @dSQLApplyComment            NVARCHAR(MAX)  -- will use the same  dynamic sql variable name regardless of wether or not we add or update hence 'apply'
          , @intRowCount                 INT
          , @boolExistFlag               BIT
          , @ustrMessageOut              NVARCHAR(400)
          , @bitIsThisAView              BIT
          , @ustrViewOrTable             NVARCHAR(8);
    DROP TABLE IF EXISTS #__SuppressOutputColumnAddComment;

    DECLARE @boolCatchFlag BIT = 0; -- for catching and throwing a specific error. 
    --set and internally cast the VARIANT, I know it's dumb, but it's what we have to do.
    SET @vrtComment = CAST(@strComment AS SQL_VARIANT); --have to convert this to variant type as that's what the built in sp asks for.

    DECLARE @ustrVariantConv NVARCHAR(MAX) = REPLACE(CAST(@vrtComment AS NVARCHAR(MAX)), '''', '''''');
    /** Explanation of the conversion above.
 *	1. 	I wanted to leave this conversion instead of just declaring as NVARCHAR. 
 *		Technically it IS stored as variant, people should be aware of this.
 *	2.	We need to deal with quotes passed in for Contractions such as "can't" which would be passed in as "can''t"
 */


    CREATE TABLE #__SuppressOutputColumnAddComment
    (
        SuppressedOutput VARCHAR(MAX)
    );
    BEGIN TRY
        SET NOCOUNT ON;
        --we do this type of insert to prevent seeing useless selects in the grid view on a SQL developer
        SET @ustrTableorObjName = PARSENAME(@ustrFQON, 1)
        SET @ustrSchemaName = PARSENAME(@ustrFQON, 2)
        SET @ustrDatabaseName = PARSENAME(@ustrFQON, 3)


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



                RAISERROR(@ustrMessageOut, 11, 1);
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
											FROM sys.extended_properties'
                                                   + ' WHERE [major_id] = OBJECT_ID(' + '''' + @ustrDatabaseName + '.'
                                                   + @ustrSchemaName + '.' + @ustrTableorObjName + '''' + ')'
                                                   + ' AND [name] = N''MS_Description''		
													  AND [minor_id] =	(				
														  SELECT [column_id]
															FROM sys.columns
															WHERE [name] =  ' + '''' + @strColumnName + ''''
                                                   + ' AND [object_id] = OBJECT_ID( ' + '''' + @ustrDatabaseName + '.'
                                                   + @ustrSchemaName + '.' + @ustrTableorObjName + '''' + ' )   )';
                INSERT INTO #__SuppressOutputColumnAddComment
                EXEC sp_executesql @dSQLNotExistCheckProperties;

                SET @intRowCount = @@ROWCOUNT;

                --if the row count is zero we know we need to add the property not update it.

                IF @intRowCount = 0
                    BEGIN
                        SET @dSQLApplyComment = N'EXEC sys.sp_addextendedproperty '
                                                + '@name = N''MS_Description'' ' + ', @value = ' + ''''
                                                + @ustrVariantConv + '''' + ', @level0type = N''SCHEMA'' '
                                                + ', @level0name = N' + '''' + @ustrSchemaName + ''''
                                                + ', @level1type = N' + '''' + @ustrViewOrTable + ''''
                                                + ', @level1name = ' + '''' + @ustrTableorObjName + ''''
                                                + ', @level2type = N''COLUMN'' ' + ', @level2name = N' + ''''
                                                + @strColumnName + '''';



                    END
                ELSE
                    BEGIN
                        SET @dSQLApplyComment = N'EXEC sys.sp_updateextendedproperty '
                                                + '@name = N''MS_Description'' ' + ', @value = ' + ''''
                                                + @ustrVariantConv + '''' + ', @level0type = N''SCHEMA'' '
                                                + ', @level0name = N' + '''' + @ustrSchemaName + ''''
                                                + ', @level1type = N' + '''' + @ustrViewOrTable + ''''
                                                + ', @level1name = ' + '''' + @ustrTableorObjName + ''''
                                                + ', @level2type = N''COLUMN'' ' + ', @level2name = N' + ''''
                                                + @strColumnName + '''';
                    END

            END

        EXEC sp_executesql @dSQLApplyComment;
        DROP TABLE IF EXISTS #__SuppressOutputColumnAddComment;
        SET NOCOUNT OFF
    END TRY
    BEGIN CATCH
        IF @boolCatchFlag = 1
            BEGIN

                INSERT INTO ERR.DB_EXCEPTION_TANK
                (
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
                VALUES (DB_NAME()
                      , SUSER_SNAME()
                      , ERROR_NUMBER()
                      , ERROR_STATE()
                      , ERROR_SEVERITY()
                      , ERROR_LINE()
                      , ERROR_PROCEDURE()
                      , ERROR_MESSAGE()
                      , GETDATE());
            END
        ELSE
            BEGIN

                INSERT INTO ERR.DB_EXCEPTION_TANK
                (
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
                VALUES (DB_NAME()
                      , SUSER_SNAME()
                      , ERROR_NUMBER()
                      , ERROR_STATE()
                      , ERROR_SEVERITY()
                      , ERROR_LINE()
                      , ERROR_PROCEDURE()
                      , ERROR_MESSAGE()
                      , GETDATE());
            END

        PRINT 'Please check the DB_EXCEPTION_TANK an error has been raised. 
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
 

	EXEC DD.ColumnAddComment @ustrFQON
		, @strColumnName
		, @ustrComment; 

	*/

    --vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    --dddddddddddddddddddddddddddddddddddddddddddd--DynamicSQLAsRegularBlock--dddddddddddddddddddddddddddddddddddddddddddddd
    /*
	--Place your dynamic SQL block here as normal SQL so others know what you are doing!
	--if you are concatenating to a large block of Dynamic SQL use your best judgement if all of it needs to be down here or not
			-- IF NOT EXISTS
			SELECT NULL
				FROM extended_properties
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