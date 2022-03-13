CREATE OR ALTER VIEW DD.V_GetPKs
AS

SELECT    i.name                                                                  AS "IndexName"
                  , OBJECT_NAME(ic.object_id)                                               AS "TableName"
                  , COL_NAME(ic.object_id, ic.column_id)                                    AS "ColumnName"
                 
          FROM  sys.indexes                AS i
              INNER JOIN sys.index_columns AS ic
                  ON i.object_id    = ic.object_id
                     AND i.index_id = ic.index_id
          WHERE i.is_primary_key = 1;