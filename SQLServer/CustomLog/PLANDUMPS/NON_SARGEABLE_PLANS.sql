USE [CustomLog]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [PLANDUMPS].[NON_SARGEABLE_PLANS](
	[PlanID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](128) NOT NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [nvarchar](128) NULL,
	[ColumnName] [nvarchar](128) NULL,
	[Query] [nvarchar](max) NULL,
	[QueryPlan] [xml] NULL,
	[ScanType] [nvarchar](9) NOT NULL,
	[ScalarString] [nvarchar](128) NULL,
	[DateOfDiscovery] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PlanID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [PLANDUMPS].[NON_SARGEABLE_PLANS] ADD  DEFAULT (CONVERT([date],getdate())) FOR [DateOfDiscovery]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'TableHoldsPlans that currently exist that can be found through the DATA DICTIONARY and are NON SARGEable, any table or index scans, and scalar operators  ' , @level0type=N'SCHEMA',@level0name=N'PLANDUMPS', @level1type=N'TABLE',@level1name=N'NON_SARGEABLE_PLANS'
GO

