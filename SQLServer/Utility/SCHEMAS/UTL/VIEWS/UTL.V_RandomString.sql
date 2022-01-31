USE [Utility];
GO

/****** Object:  View [UTL].[V_RandomString]    Script Date: 1/30/2022 2:43:05 PM ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO



CREATE VIEW [UTL].[V_RandomString]
AS
    SELECT  CAST((
                     SELECT CAST(CRYPT_GEN_RANDOM(64) AS VARBINARY(64))
                     FOR XML PATH(''), BINARY BASE64
                 ) AS NVARCHAR(64)) AS "RandomString";
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description'
                              , @value = N'Does as advertised, generates a random string. Use within Scalar Functions to get around SQL Server''s idiotic limitations.'
                              , @level0type = N'SCHEMA'
                              , @level0name = N'UTL'
                              , @level1type = N'VIEW'
                              , @level1name = N'V_RandomString';
GO


