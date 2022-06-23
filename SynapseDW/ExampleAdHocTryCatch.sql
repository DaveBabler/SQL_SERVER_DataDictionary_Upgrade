BEGIN TRY
    DECLARE @ustrAdHocBlock NVARCHAR(80) = N'⚠️🛑FILL ME IN🛑'; --EXPLAIN BREIFLY WHAT YOU ARE DOING or ORM ModuleName HERE SO IF YOU HAVE ERRORS IT GOES IN THE EXCEPTION TANK
    DECLARE @intShoes INT;


    SELECT  @intShoes = 1 / 0;



END TRY
BEGIN CATCH
    DECLARE @ustrDBName NVARCHAR(80) = DB_NAME();
    DECLARE @ustrSuser NVARCHAR(80) = SUSER_SNAME(); --sadly ORIGINAL_LOGIN() is not availible for Synapse.
    DECLARE @intErrorNumber INT = ERROR_NUMBER();
    DECLARE @intErrorState INT = ERROR_STATE();
    DECLARE @intErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ustrErrorProcedure NVARCHAR(800) = ISNULL(
                                                    ERROR_PROCEDURE()
                                                  , CONCAT(
                                                        CONCAT(ERROR_PROCEDURE(), N'AdhocBlock', N': ', @ustrAdHocBlock)
                                                      , ' '
                                                      , CONCAT(DB_NAME(), N'.', SCHEMA_NAME())));

    DECLARE @ustrErrorMessage NVARCHAR(1600) = ERROR_MESSAGE();
    DECLARE @dtCurrentDate DATETIME2 = GETDATE();

    INSERT INTO ERR.DB_EXCEPTION_TANK ([DatabaseName]
                                     , [UserName]
                                     , [ErrorNumber]
                                     , [ErrorState]
                                     , [ErrorSeverity]
                                     , [ErrorProcedure]
                                     , [ErrorMessage]
                                     , [ErrorDateTime])
    VALUES (@ustrDBName
          , @ustrSuser
          , @intErrorNumber
          , @intErrorState
          , @intErrorSeverity
          , @ustrErrorProcedure
          , @ustrErrorMessage
          , @dtCurrentDate);
    PRINT 'Error? Try SELECT * FROM ERR.DB_EXCEPTION_TANK ORDER BY ErrorDateTime DESC;';
    THROW; --SENDS ERROR BACK TO CALLING PROGRAM
END CATCH;



