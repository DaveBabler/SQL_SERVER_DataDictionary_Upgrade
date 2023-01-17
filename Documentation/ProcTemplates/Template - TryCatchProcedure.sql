/*

=============================================
Author:			Your Name
Create Date:	XXXX-MM-DD
SubProcedures:	only custom procs and functions not system ones go here
Description:	Quality Description goes here
=============================================

*/
CREATE OR ALTER PROCEDURE schema.ProcedureDoesWhat (
    -- Add the parameters for the stored procedure here
       @intShoes INT

)
AS
    BEGIN TRY

    SELECT  @intShoes = 1 / 0;



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
	/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



THIS IS AN EXAMPLE OF A PROPERLY FORMED TESTING BLOCK 
THIS IS HOW IT SHOULD LOOK WHEN DONE.



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


