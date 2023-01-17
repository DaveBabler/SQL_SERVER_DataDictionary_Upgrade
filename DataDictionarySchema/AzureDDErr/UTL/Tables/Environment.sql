CREATE TABLE [UTL].[Environment] (
    [EnvironmentID]   INT           IDENTITY (1, 1) NOT NULL,
    [EnvironmentName] NVARCHAR (64) NOT NULL,
    CONSTRAINT [PK_UTL_EnvironmentID] PRIMARY KEY CLUSTERED ([EnvironmentID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The generic environment where whatever we''re tagging this to is', @level0type = N'SCHEMA', @level0name = N'UTL', @level1type = N'TABLE', @level1name = N'Environment', @level2type = N'COLUMN', @level2name = N'EnvironmentName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'This holds environments where our programs live such as test, dev, dblab, synapse, etc.', @level0type = N'SCHEMA', @level0name = N'UTL', @level1type = N'TABLE', @level1name = N'Environment';

