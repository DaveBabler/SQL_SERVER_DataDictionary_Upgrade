SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE [ERR].[DB_EXCEPTION_TANK] ([ErrorID]        [INT]           IDENTITY(1, 1) NOT NULL
                                      , [DatabaseName]   [VARCHAR](80)   NULL
                                      , [UserName]       [VARCHAR](100)  NULL
                                      , [ErrorNumber]    [INT]           NULL
                                      , [ErrorState]     [INT]           NULL
                                      , [ErrorSeverity]  [INT]           NULL
                                      , [ErrorProcedure] [VARCHAR](2000) NULL
                                      , [ErrorMessage]   [VARCHAR](2000) NULL
                                      , [ErrorDateTime]  [DATETIME]      NULL)
WITH (DISTRIBUTION=ROUND_ROBIN, CLUSTERED COLUMNSTORE INDEX);
GO