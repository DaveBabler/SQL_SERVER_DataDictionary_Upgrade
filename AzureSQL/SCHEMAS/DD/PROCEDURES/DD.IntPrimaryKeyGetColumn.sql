/*

=============================================
Author:      Dave Babler
Create Date: 2022-07-02
Description: This returns the name of a primary key column if it has an INT type
=============================================

*/
CREATE OR ALTER PROCEDURE DD.IntPrimaryKeyGetColumn (
    -- Add the parameters for the stored procedure here
    @ustrSchemaName           NVARCHAR(80)
  , @ustrTableName            NVARCHAR(80)
  , @ustrPrimaryKeyColumnName NVARCHAR(80) OUTPUT
  , @ustrPrimaryKeyDataType   NVARCHAR(80) OUTPUT)
AS
    BEGIN TRY
        DECLARE @tSQLGetPKName NVARCHAR(1600);

        SET @tSQLGetPKName = N'SELECT @ustrPrimaryKeyColumnName = C.COLUMN_NAME
							  , @ustrPrimaryKeyDataType = COL.DATA_TYPE
						FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS T
							JOIN
							INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C
							  ON C.CONSTRAINT_NAME = T.CONSTRAINT_NAME
							LEFT JOIN
							INFORMATION_SCHEMA.COLUMNS AS COL
							  ON COL.COLUMN_NAME = C.COLUMN_NAME
								  AND COL.TABLE_SCHEMA = C.TABLE_SCHEMA
								 AND COL.TABLE_NAME = C.TABLE_NAME
						WHERE   T.CONSTRAINT_TYPE = ''PRIMARY KEY''
						AND C.TABLE_NAME = @ustrTableName
						AND C.TABLE_SCHEMA = @ustrSchemaName
						AND COL.DATA_TYPE  LIKE ' + '''' +'%int%' + '''';



        EXEC sys.sp_executesql @stmt = @tSQLGetPKName
                             , @params = N' @ustrSchemaName           NVARCHAR(80)
			 , @ustrTableName            NVARCHAR(80)
			 , @ustrPrimaryKeyColumnName NVARCHAR(80) OUTPUT
			 , @ustrPrimaryKeyDataType   NVARCHAR(80) OUTPUT'
                             , @ustrSchemaName = @ustrSchemaName
                             , @ustrTableName = @ustrTableName
                             , @ustrPrimaryKeyColumnName = @ustrPrimaryKeyColumnName OUTPUT
                             , @ustrPrimaryKeyDataType = @ustrPrimaryKeyDataType OUTPUT;




    END TRY
    BEGIN CATCH
        INSERT INTO ERR.DB_EXCEPTION_TANK ([DatabaseName]
                                         , [UserName]
                                         , [ErrorNumber]
                                         , [ErrorState]
                                         , [ErrorSeverity]
                                         , [ErrorLine]
                                         , [ErrorProcedure]
                                         , [ErrorMessage]
                                         , [ErrorDateTime])
        VALUES (DB_NAME()
              , SUSER_SNAME()
              , ERROR_NUMBER()
              , ERROR_STATE()
              , ERROR_SEVERITY()
              , ERROR_LINE()
              , ERROR_PROCEDURE()
              , ERROR_MESSAGE()
              , GETDATE());
    END CATCH;
	/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
DECLARE @return_value             INT
      , @ustrPrimaryKeyColumnName NVARCHAR(80)
      , @ustrPrimaryKeyDataType   NVARCHAR(80)
      , @ustrSchemaName           NVARCHAR(80)
      , @ustrTableName            NVARCHAR(80);


		EXEC @return_value = [DD].[IntPrimaryKeyGetColumn] @ustrSchemaName = N'Party'
														 , @ustrTableName = N'Party'
														 , @ustrPrimaryKeyColumnName = @ustrPrimaryKeyColumnName OUTPUT
														 , @ustrPrimaryKeyDataType = @ustrPrimaryKeyDataType OUTPUT;

		SELECT  @ustrPrimaryKeyColumnName AS "@ustrPrimaryKeyColumnName"
			  , @ustrPrimaryKeyDataType AS "@ustrPrimaryKeyDataType";
	
	
	vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv*/
GO


