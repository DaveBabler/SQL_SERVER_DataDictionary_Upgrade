BEGIN TRY
    DECLARE @ustrAdHocBlock NVARCHAR(80) = N'⚠️🛑FILL ME IN🛑'; --EXPLAIN BREIFLY WHAT YOU ARE DOING or ORM ModuleName HERE SO IF YOU HAVE ERRORS IT GOES IN THE EXCEPTION TANK
    DECLARE @intShoes INT;

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
          , ISNULL(
                ERROR_PROCEDURE()
              , CONCAT(
                    CONCAT(ERROR_PROCEDURE(), 'AdhocBlock', ': ', @ustrAdHocBlock)
                  , ' '
                  , CONCAT(DB_NAME(), '.', SCHEMA_NAME(), '.', OBJECT_NAME(@@PROCID))))
          , ERROR_MESSAGE()
          , GETDATE());
	PRINT 'Error? Try SELECT * FROM ERR.DB_EXCEPTION_TANK ORDER BY ErrorDateTime DESC;';
    THROW; --SENDS ERROR BACK TO CALLING PROGRAM
END CATCH;

