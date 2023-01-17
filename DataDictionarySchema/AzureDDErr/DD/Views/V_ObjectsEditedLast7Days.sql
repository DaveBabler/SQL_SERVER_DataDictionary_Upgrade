-- =============================================
-- Author:		Dave Babler
-- Create date: 2021-05-03
-- Edited for Azure: 2021-12-14
-- Description:	Returns a table of recent edits to the server
-- =============================================
CREATE      VIEW [DD].[V_ObjectsEditedLast7Days]
AS
    SELECT  DB_NAME()              AS DBName
          , SCHEMA_NAME(schema_id) AS SchemaName
          , so.name                AS ObjectName
          , type_desc              AS DescriptiveObjectType
          , modify_date            AS DateModified
    FROM    sys.all_objects so
    WHERE   DATEDIFF(D, modify_date, GETDATE()) < 7;


   /* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   
        SELECT  *
        FROM    DD.V_ObjectsEditedLast7Days
        ORDER BY DateModified DESC

vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv   */