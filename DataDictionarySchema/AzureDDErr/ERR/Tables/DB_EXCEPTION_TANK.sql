CREATE TABLE [ERR].[DB_EXCEPTION_TANK] (
    [ErrorID]        INT            IDENTITY (1, 1) NOT NULL,
    [DatabaseName]   VARCHAR (80)   NULL,
    [UserName]       VARCHAR (100)  NULL,
    [CodeAuthor]     NVARCHAR (80)  NULL,
    [ErrorNumber]    INT            NULL,
    [ErrorState]     INT            NULL,
    [ErrorSeverity]  INT            NULL,
    [ErrorLine]      INT            NULL,
    [ErrorProcedure] NVARCHAR (800) NULL,
    [ErrorMessage]   VARCHAR (MAX)  NULL,
    [ErrorDateTime]  DATETIME       NULL,
    CONSTRAINT [PK_ErrExceptionTank_ErrorID] PRIMARY KEY CLUSTERED ([ErrorID] ASC)
);




GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is for logging errors thrown by procedures and adhoc code blocks ', @level0type = N'SCHEMA', @level0name = N'ERR', @level1type = N'TABLE', @level1name = N'DB_EXCEPTION_TANK';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'When code is executed by a DBA or Service Account this is the original author of the code.', @level0type = N'SCHEMA', @level0name = N'ERR', @level1type = N'TABLE', @level1name = N'DB_EXCEPTION_TANK', @level2type = N'COLUMN', @level2name = N'CodeAuthor';

