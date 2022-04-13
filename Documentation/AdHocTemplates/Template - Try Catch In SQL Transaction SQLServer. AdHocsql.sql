BEGIN TRY
    SET XACT_ABORT ON;
    DECLARE @ustrAdHocBlock NVARCHAR(80) = N'⚠️🛑FILL ME IN🛑'; --EXPLAIN BREIFLY WHAT YOU ARE DOING HERE  or ORM ModuleName SO IF YOU HAVE ERRORS IT GOES IN THE EXCEPTION TANK

    DROP TABLE IF EXISTS #NECRONOMICON;
    BEGIN TRANSACTION;

    CREATE TABLE #NECRONOMICON (DemonSummonActivation       INT IDENTITY(1, 1) PRIMARY KEY
                              , DemonsSummonedPerActivation INT);

    INSERT INTO #NECRONOMICON (DemonsSummonedPerActivation)
    VALUES (12)
         , (5)
         , (99999999);

    UPDATE  #NECRONOMICON
    SET DemonsSummonedPerActivation = (12 / 0);

    COMMIT;

    SET XACT_ABORT OFF; -- 
END TRY
BEGIN CATCH
    IF (XACT_STATE()) = -1 --test to see if we cannot commit
        BEGIN
            PRINT N'The transaction is in an uncommittable state.' + 'Rolling back transaction.';

            ROLLBACK TRANSACTION;

            SET XACT_ABORT OFF;
        -- currently our database has this as default so we need to double check it turns off on fail or success
        END;

    IF (XACT_STATE()) = 1 -- Test if the transaction is committable.  
        BEGIN
            PRINT N'The transaction is committable.' + 'Committing transaction.';

            COMMIT TRANSACTION;

            SET XACT_ABORT OFF;
        -- currently our database has this as default so we need to triple check it turns off on fail or success
        END;

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
GO