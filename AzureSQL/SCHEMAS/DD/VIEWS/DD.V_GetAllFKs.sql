CREATE OR ALTER VIEW V_GetAllFKs AS
SELECT  SCHEMA_NAME(fk_tab.schema_id) + '.' + fk_tab.name     AS "foreign_table"
      , '>-'                                                  AS "rel"
      , SCHEMA_NAME(pk_tab.schema_id) + '.' + pk_tab.name     AS "primary_table"
      , SUBSTRING(D.column_names, 1, LEN(D.column_names) - 1) AS "fk_columns"
      , fk.name                                               AS "fk_constraint_name"
FROM    sys.foreign_keys  AS fk
    INNER JOIN sys.tables AS fk_tab
        ON fk_tab.object_id = fk.parent_object_id
    INNER JOIN sys.tables AS pk_tab
        ON pk_tab.object_id = fk.referenced_object_id
    CROSS APPLY
(
    SELECT  col.name + ', '
    FROM    sys.foreign_key_columns AS fk_c
        INNER JOIN sys.columns   AS col
            ON fk_c.parent_object_id      = col.object_id
               AND  fk_c.parent_column_id = col.column_id
    WHERE   fk_c.parent_object_id         = fk_tab.object_id
            AND fk_c.constraint_object_id = fk.object_id
    ORDER BY col.column_id
    FOR XML PATH('')
)                         AS D(column_names)
ORDER BY SCHEMA_NAME(fk_tab.schema_id) + '.' + fk_tab.name
       , SCHEMA_NAME(pk_tab.schema_id) + '.' + pk_tab.name;



/*
SELECT  OBJECT_NAME(parent_object_id)     AS "FK Table"
      , name                              AS "Foreign Key"
      , OBJECT_NAME(referenced_object_id) AS "PK Table"
FROM    sys.foreign_keys;*/


