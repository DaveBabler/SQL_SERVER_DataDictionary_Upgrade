CREATE OR ALTER VIEW DD.V_NonPrimaryKeyCols AS 

/*Provides a way for inexperienced data dictionary scholars to grab all
non primary key fields*/
WITH getPKs
   AS (   SELECT    i.name                                                                  AS "IndexName"
                  , OBJECT_NAME(ic.object_id)                                               AS "TableName"
                  , COL_NAME(ic.object_id, ic.column_id)                                    AS "ColumnName"
                  , CONCAT(OBJECT_NAME(ic.object_id), COL_NAME(ic.object_id, ic.column_id)) AS "ConcattedAttribute"
          FROM  sys.indexes                AS i
              INNER JOIN sys.index_columns AS ic
                  ON i.object_id    = ic.object_id
                     AND i.index_id = ic.index_id
          WHERE i.is_primary_key = 1)
    , getALLCols
   AS (   SELECT    s.name                     AS "schema"
                  , t.[name]                   AS "Table"
                  , c.[name]                   AS "Column"
                  , CONCAT(t.[name], c.[name]) AS "ConcattedAttribute"
          FROM  sys.schemas          AS s
              INNER JOIN sys.tables  AS t
                  ON s.schema_id    = t.schema_id
              INNER JOIN sys.columns AS c
                  ON t.object_id    = c.object_id
              INNER JOIN sys.types   AS d
                  ON c.user_type_id = d.user_type_id
          WHERE s.name <> 'sys')
SELECT  ac.[schema]
      , ac.[Table]
      , ac.[Column]
FROM    getALLCols AS ac
WHERE   NOT EXISTS
(
    SELECT  1
    FROM    getPKs AS pk
    WHERE   pk.ConcattedAttribute = ac.ConcattedAttribute
);

