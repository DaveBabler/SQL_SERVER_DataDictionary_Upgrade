CREATE VIEW DD.V_BlobTablesImplicitExplicitAndTheirIndexes
AS
    WITH GetExplicitBlobTables
      AS (
             SELECT SCHEMA_NAME(tab.schema_id) AS "SchemaName"
                  , tab.name AS "TableName"
                  , col.column_id
                  , col.name AS "ColumnName"
                  , t.name AS "DataType"
                  , col.max_length
                  , col.precision   -- incase we decide NVARCHAR(MAX) is an actual blob
             FROM   sys.tables AS tab
                 INNER JOIN
                 sys.columns AS col
                    ON tab.object_id = col.object_id
                 LEFT JOIN
                 sys.types AS t
                   ON col.user_type_id = t.user_type_id
             WHERE  SCHEMA_NAME(tab.schema_id) NOT IN ( 'cdc', 'jobs_internal', 'dbo', 'sys' )
                    AND t.name IN ( 'TEXT', 'NTEXT', 'IMAGE', 'BINARY', 'VARBINARY' ))
       , GetImplicitBlobTables
      AS (   SELECT SCHEMA_NAME(tab.schema_id) AS "SchemaName"
                  , tab.name AS "TableName"
                  , col.column_id
                  , col.name AS "ColumnName"
                  , t.name AS "DataType"
                  , col.max_length
                  , col.precision   -- incase we decide NVARCHAR(MAX) is an actual blob
             FROM   sys.tables AS tab
                 INNER JOIN
                 sys.columns AS col
                    ON tab.object_id = col.object_id
                 LEFT JOIN
                 sys.types AS t
                   ON col.user_type_id = t.user_type_id
             WHERE  SCHEMA_NAME(tab.schema_id) NOT IN ( 'cdc', 'jobs_internal', 'dbo', 'sys' )
                    AND t.name IN ( 'NVARCHAR', 'VARCHAR' )
                    AND col.max_length = -1)
       , GetComputedColumns
      AS (   SELECT SCHEMA_NAME(o.schema_id) AS "SchemaName"
                  , OBJECT_NAME(c.object_id) AS "TableName"
                  , column_id
                  , c.name AS "ColumnName"
                  , TYPE_NAME(user_type_id) AS "data_type"
                  , definition
             FROM   sys.computed_columns c WITH (NOLOCK)
                 JOIN
                 sys.objects o WITH (NOLOCK)
                   ON o.object_id = c.object_id)
       , GetImplicitBlobIndexList
      AS (   SELECT CAST(i.name AS NVARCHAR(120)) AS "index_name"
                  , SUBSTRING(D.column_names, 1, LEN(D.column_names) - 1) AS "columns"
                  , CASE --MAINT SCRIPT NOT PRODUCTION CUSTOMER SCRIPT more important for DBA to know what's up than speed
                         -- TODO: change this to a TVF because why not set the example. 
                         WHEN i.type = 1 THEN
                             'Clustered index'
                         WHEN i.type = 2 THEN
                             'Nonclustered unique index'
                         WHEN i.type = 3 THEN
                             'XML index'
                         WHEN i.type = 4 THEN
                             'Spatial index'
                         WHEN i.type = 5 THEN
                             'Clustered columnstore index'
                         WHEN i.type = 6 THEN
                             'Nonclustered columnstore index'
                         WHEN i.type = 7 THEN
                             'Nonclustered hash index'
                    END AS "index_type"
                  , CASE
                         WHEN i.is_unique = 1 THEN
                             'Unique'
                         ELSE
                             'Not unique'
                    END AS "unique"
                  , CONCAT('[', SCHEMA_NAME(t.schema_id), ']') + '.' + CONCAT('[', t.name, ']') AS "table_view"
                  , SCHEMA_NAME(t.schema_id) AS "SchemaName"
                  , t.name AS "TableName"
                  , CASE
                         WHEN t.type = 'U' THEN
                             'Table'
                         WHEN t.type = 'V' THEN
                             'View'
                    END AS "object_type"
             FROM   sys.objects AS t WITH (NOLOCK)
                 INNER JOIN
                 sys.indexes AS i WITH (NOLOCK)
                    ON t.object_id = i.object_id
                 CROSS APPLY (   SELECT CONCAT(col.name, ' Type: ', st.name) + ', '
                                 FROM   sys.index_columns AS ic WITH (NOLOCK)
                                     INNER JOIN
                                     sys.columns AS col WITH (NOLOCK)
                                        ON ic.object_id = col.object_id
                                           AND  ic.column_id = col.column_id
                                     INNER JOIN
                                     sys.types AS st WITH (NOLOCK)
                                        ON col.system_type_id = st.system_type_id
                                 WHERE  ic.object_id = t.object_id
                                        AND ic.index_id = i.index_id
                                 ORDER BY key_ordinal
                                 FOR XML PATH('')) AS D(column_names)
                 INNER JOIN
                 sys.schemas AS s
                    ON s.schema_id = t.schema_id
             WHERE  i.index_id > 0
                    AND OBJECT_SCHEMA_NAME(t.object_id) <> 'sys'
                    AND t.type <> 'TF' /*yes! Table Value Functions have indexes, but you can't rebuild them!*/
                    AND s.name <> 'cdc'
                    AND s.name <> 'jobs_internal'
                    AND (   (t.name <> 'ProcessJob')
                            AND t.name <> 'ProcessJobExecution') /*Pulling these from this for now, note we MUST do these in a different area*/
                    AND CONCAT(s.name, t.name) NOT IN ( SELECT  CONCAT(gcc.SchemaName, gcc.TableName)FROM   GetComputedColumns gcc )
                    AND CONCAT(s.name, t.name)IN (   SELECT CONCAT(gbt.SchemaName, gbt.TableName)
                                                     FROM   GetImplicitBlobTables gbt )
                    AND CONCAT(s.name, t.name) NOT IN (   SELECT    CONCAT(gbt.SchemaName, gbt.TableName)
                                                          FROM  GetExplicitBlobTables gbt ))
       , GetExplicitBlobIndexList
      AS (   SELECT CAST(i.name AS NVARCHAR(120)) AS "index_name"
                  , SUBSTRING(D.column_names, 1, LEN(D.column_names) - 1) AS "columns"
                  , CASE --MAINT SCRIPT NOT PRODUCTION CUSTOMER SCRIPT more important for DBA to know what's up than speed
                         -- TODO: change this to a TVF because why not set the example. 
                         WHEN i.type = 1 THEN
                             'Clustered index'
                         WHEN i.type = 2 THEN
                             'Nonclustered unique index'
                         WHEN i.type = 3 THEN
                             'XML index'
                         WHEN i.type = 4 THEN
                             'Spatial index'
                         WHEN i.type = 5 THEN
                             'Clustered columnstore index'
                         WHEN i.type = 6 THEN
                             'Nonclustered columnstore index'
                         WHEN i.type = 7 THEN
                             'Nonclustered hash index'
                    END AS "index_type"
                  , CASE
                         WHEN i.is_unique = 1 THEN
                             'Unique'
                         ELSE
                             'Not unique'
                    END AS "unique"
                  , CONCAT(QUOTENAME(SCHEMA_NAME(t.schema_id)), '.', QUOTENAME(t.name)) AS "table_view"
                  , SCHEMA_NAME(t.schema_id) AS "SchemaName"
                  , t.name AS "TableName"
                  , CASE
                         WHEN t.type = 'U' THEN
                             'Table'
                         WHEN t.type = 'V' THEN
                             'View'
                    END AS "object_type"
             FROM   sys.objects AS t WITH (NOLOCK)
                 INNER JOIN
                 sys.indexes AS i WITH (NOLOCK)
                    ON t.object_id = i.object_id
                 CROSS APPLY (   SELECT CONCAT(col.name, ' Type: ', st.name) + ', '
                                 FROM   sys.index_columns AS ic WITH (NOLOCK)
                                     INNER JOIN
                                     sys.columns AS col WITH (NOLOCK)
                                        ON ic.object_id = col.object_id
                                           AND  ic.column_id = col.column_id
                                     INNER JOIN
                                     sys.types AS st WITH (NOLOCK)
                                        ON col.system_type_id = st.system_type_id
                                 WHERE  ic.object_id = t.object_id
                                        AND ic.index_id = i.index_id
                                 ORDER BY key_ordinal
                                 FOR XML PATH('')) AS D(column_names)
                 INNER JOIN
                 sys.schemas AS s
                    ON s.schema_id = t.schema_id
             WHERE  i.index_id > 0
                    AND OBJECT_SCHEMA_NAME(t.object_id) <> 'sys'
                    AND t.type <> 'TF' /*yes! Table Value Functions have indexes, but you can't rebuild them!*/
                    AND s.name <> 'cdc'
                    AND s.name <> 'jobs_internal'
                    AND (   (t.name <> 'ProcessJob')
                            AND t.name <> 'ProcessJobExecution') /*Pulling these from this for now, note we MUST do these in a different area*/
                    AND CONCAT(s.name, t.name) NOT IN ( SELECT  CONCAT(gcc.SchemaName, gcc.TableName)FROM   GetComputedColumns gcc )
                    AND CONCAT(s.name, t.name) NOT IN (   SELECT    CONCAT(gbt.SchemaName, gbt.TableName)
                                                          FROM  GetImplicitBlobTables gbt )
                    AND CONCAT(s.name, t.name)IN (   SELECT CONCAT(gbt.SchemaName, gbt.TableName)
                                                     FROM   GetExplicitBlobTables gbt ))
    SELECT  gebil.index_name
          , gebil.columns
          , gebil.index_type
          , gebil.[unique]
          , gebil.table_view
          , gebil.SchemaName
          , gebil.TableName
          , gebil.object_type
          , 'Explicit' AS "TypeOfBlob"
    FROM    GetExplicitBlobIndexList gebil
    UNION
    SELECT  gibil.index_name
          , gibil.columns
          , gibil.index_type
          , gibil.[unique]
          , gibil.table_view
          , gibil.SchemaName
          , gibil.TableName
          , gibil.object_type
          , 'Implicit' AS "TypeOfBlob"
    FROM    GetImplicitBlobIndexList gibil;