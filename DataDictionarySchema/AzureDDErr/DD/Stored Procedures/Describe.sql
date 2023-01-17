-- =============================================
-- Author:		        Dave Babler
-- Create date:         08/26/2020
-- Modifed for Azure:	2021-12-15
-- Description:	        This recreates and improves upon Oracle's ANSI DESCRIBE table built in data dictionary proc
-- 				        This will default to the dbo schema unless specified within the input parameter.
-- Subprocedures:       1. DD.TableShowComment
-- 				        2. UTL_fn_DelimListToTable 
-- =============================================
CREATE     PROCEDURE [DD].[Describe]
	-- Add the parameters for the stored procedure here
	@ustrFQON VARCHAR(200) 
	 
AS


DECLARE @strMessageOut NVARCHAR(320)
	, @boolIsTableCommentSet BIT = NULL
	, @strTableComment NVARCHAR(320)
	, @strTableSubComment NVARCHAR(80) --This will be an additional flag warning there is no actual table comment!
	, @bitIsThisAView BIT
	, @bitExistFlag BIT
	, @ustrSchemaName NVARCHAR(64)
	, @ustrTableorObjName NVARCHAR(64)
	, @ustrViewOrTable NVARCHAR(8)
	, @dSQLBuildDescribe NVARCHAR(MAX)
	, @dSQLParamaters NVARCHAR(MAX)
    , @bitSuccessFlag BIT;

BEGIN TRY
SET NOCOUNT ON;
		DROP TABLE IF EXISTS ##DESCRIBE;  --for future output to temp tables ignore for now
	/** First check to see if a schema was specified in the input paramater, schema.table, else default to dbo. -- Babler*/

        SET @ustrTableorObjName = PARSENAME(@ustrFQON, 1)
        IF PARSENAME(@ustrFQON, 2) IS NOT NULL
            BEGIN
                SET @ustrSchemaName = PARSENAME(@ustrFQON, 2)
            END
        ELSE
            BEGIN
                SET @ustrSchemaName = 'dbo';
            END

			/**Check to see if the table exists, if it does not we will output an Error Message
        * however since we are not writing anything to the DD we won't go through the whole RAISEEROR 
        * or THROW and CATCH process, a simple output is sufficient. -- Babler
        */



    EXEC DD.TableExist @ustrTableorObjName
	, @ustrSchemaName
	, @bitSuccessFlag OUTPUT
	, @strMessageOut OUTPUT; 

    IF @bitSuccessFlag = 1

	
	BEGIN
		-- we want to suppress results (perhaps this could be proceduralized as well one to make the table one to kill?)
		CREATE TABLE #__suppress_results (col1 INT);

		EXEC DD.TableShowComment @ustrFQON
			, @boolIsTableCommentSet OUTPUT
			, @strTableComment OUTPUT;

		IF @boolIsTableCommentSet = 0
		BEGIN
			SET @strTableSubComment = 'RECTIFY MISSING TABLE COMMENT -->';
		END
		ELSE
		BEGIN
			SET @strTableSubComment = 'TABLE COMMENT --> ';
		END
		SET @dSQLBuildDescribe  = CAST(N' '  AS NVARCHAR(MAX)) + 
                    N'WITH fkeys
                    AS (
                        SELECT col.name AS NameofFKColumn
                            , ist.TABLE_SCHEMA + ''.'' + pk_tab.name AS ReferencedTable
                            , pk_col.name AS PrimaryKeyColumnName
                            , delete_referential_action_desc AS ReferentialDeleteAction
                            , update_referential_action_desc AS ReferentialUpdateAction
                        FROM ' + 'sys.tables tab
                        INNER JOIN ' + 'sys.columns col
                            ON col.object_id = tab.object_id
                        LEFT JOIN ' + 'sys.foreign_key_columns fk_cols
                            ON fk_cols.parent_object_id = tab.object_id
                                AND fk_cols.parent_column_id = col.column_id
                        LEFT JOIN ' + 'sys.foreign_keys fk
                            ON fk.object_id = fk_cols.constraint_object_id
                        LEFT JOIN ' + 'sys.tables pk_tab
                            ON pk_tab.object_id = fk_cols.referenced_object_id
                        LEFT JOIN ' + 'sys.columns pk_col
                            ON pk_col.column_id = fk_cols.referenced_column_id
                            AND pk_col.object_id = fk_cols.referenced_object_id
                        LEFT JOIN ' +'INFORMATION_SCHEMA.TABLES ist
                                ON ist.TABLE_NAME = tab.name
                        WHERE fk.name IS NOT NULL
                            AND tab.name = @ustrTableName_d
                            AND ist.TABLE_SCHEMA = @ustrSchemaName_d
                            
                        )
                        , pk
                    AS (
                        SELECT SCHEMA_NAME(o.schema_id) AS TABLE_SCHEMA
                            , o.name AS TABLE_NAME
                            , c.name AS COLUMN_NAME
                            , i.is_primary_key
                        FROM ' + 'sys.indexes AS i
                        INNER JOIN ' + 'sys.index_columns AS ic
                            ON i.object_id = ic.object_id
                                AND i.index_id = ic.index_id
                        INNER JOIN ' + 'sys.objects AS o
                            ON i.object_id = o.object_id
                        LEFT JOIN ' + 'sys.columns AS c
                            ON ic.object_id = c.object_id
                                AND c.column_id = ic.column_id
                        WHERE i.is_primary_key = 1
                        )
                        , indStart
                    AS (
                        SELECT TableName = t.name
                            , IndexName = ind.name
                            , IndexId = ind.index_id
                            , ColumnId = ic.index_column_id
                            , ColumnName = col.name
                        FROM ' + 'sys.indexes ind
                        INNER JOIN ' + 'sys.index_columns ic
                            ON ind.object_id = ic.object_id
                                AND ind.index_id = ic.index_id
                        INNER JOIN ' + 'sys.columns col
                            ON ic.object_id = col.object_id
                                AND ic.column_id = col.column_id
                        INNER JOIN ' + 'sys.tables t
                            ON ind.object_id = t.object_id
                        WHERE ind.is_primary_key = 0
                            AND ind.is_unique = 0
                            AND ind.is_unique_constraint = 0
                            AND t.is_ms_shipped = 0
                            AND t.Name = @ustrTableName_d
                        )
                        , indexList
                    AS (
                        SELECT i2.TableName
                            , i2.IndexName
                            , i2.IndexId
                            , i2.ColumnId
                            , i2.ColumnName
                            , (
                                SELECT SUBSTRING((
                                            SELECT '', '' + IndexName
                                            FROM indStart i1
                                            WHERE i1.ColumnName = i2.ColumnName
                                            FOR XML PATH('''')
                                            ), 2, 200000)
                                ) AS IndexesRowIsInvolvedIn
                            , ROW_NUMBER() OVER (
                                PARTITION BY LOWER(ColumnName) ORDER BY ColumnId
                                ) AS RowNum
                        FROM indStart i2
                        )
                    SELECT DISTINCT col.COLUMN_NAME AS ColumnName
                        , col.ORDINAL_POSITION AS OrdinalPosition
                        , col.DATA_TYPE AS DataType
                        , col.CHARACTER_MAXIMUM_LENGTH AS MaxLength
                        , col.NUMERIC_PRECISION AS NumericPrecision
                        , col.NUMERIC_SCALE AS NumericScale
                        , col.DATETIME_PRECISION AS DatePrecision
                        , col.COLUMN_DEFAULT AS DefaultSetting
                        , CAST(CASE lower(col.IS_NULLABLE)
                                WHEN ''no''
                                    THEN 0
                                ELSE 1
                                END AS BIT) AS IsNullable
                        , COLUMNPROPERTY(OBJECT_ID('' ['' + col.TABLE_SCHEMA + ''].['' + col.TABLE_NAME + ''] ''), col.COLUMN_NAME, '' IsComputed 
                            '') AS IsComputed
                        , COLUMNPROPERTY(OBJECT_ID('' ['' + col.TABLE_SCHEMA + ''].['' + col.TABLE_NAME + ''] ''), col.COLUMN_NAME, '' IsIdentity 
                            '') AS IsIdentity
                        , CAST(ISNULL(pk.is_primary_key, 0) AS BIT) AS IsPrimaryKey
                        , '' FK of: '' + fkeys.ReferencedTable + ''.'' + fkeys.PrimaryKeyColumnName AS ReferencedTablePrimaryKey
                        , col.COLLATION_NAME AS CollationName
                        , s.value AS Description
                        , indexList.IndexesRowIsInvolvedIn
                    INTO ##DESCRIBE --GLOBAL TEMP 
                    FROM ' +'INFORMATION_SCHEMA.COLUMNS AS col
                    LEFT JOIN pk
                        ON col.TABLE_NAME = pk.TABLE_NAME
                            AND col.TABLE_SCHEMA = pk.TABLE_SCHEMA
                            AND col.COLUMN_NAME = pk.COLUMN_NAME
                    LEFT JOIN ' + 'sys.extended_properties s
                        ON s.major_id = OBJECT_ID(col.TABLE_CATALOG + ''.'' + col.TABLE_SCHEMA + ''.'' + col.TABLE_NAME)
                            AND s.minor_id = col.ORDINAL_POSITION
                            AND s.name = ''MS_Description''
                            AND s.class = 1
                    LEFT JOIN fkeys AS fkeys
                        ON col.COLUMN_NAME = fkeys.NameofFKColumn
                    LEFT JOIN indexList
                        ON col.COLUMN_NAME = indexList.ColumnName
                            AND indexList.RowNum = 1
                    WHERE col.TABLE_NAME = @ustrTableName_d
                        AND col.TABLE_SCHEMA = @ustrSchemaName_d

                        	UNION ALL
		
		SELECT TOP 1 @ustrTableName_d
			, NULL
			, N''<<--- TableName''
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, NULL
			, @strTableSubComment_d
			, @strTableComment_d
			, NULL --list of indexes 
		ORDER BY 2 

'
	;
--PRINT CAST(@dSQLBuildDescribe AS NTEXT); 

	-- FOR OUTPUTTING AND DEBUGGING THE DYNAMIC SQL 👇

    --SELECT CAST('<root><![CDATA[' + @dSQLBuildDescribe + ']]></root>' AS XML)


	SET @dSQLParamaters = '@ustrSchemaName_d NVARCHAR(64)
, @ustrTableName_d NVARCHAR(64)
, @strTableSubComment_d VARCHAR(2000)
, @strTableComment_d VARCHAR(2000)';


EXEC sp_executesql @dSQLBuildDescribe
, @dSQLParamaters
, @ustrSchemaName_d = @ustrSchemaName
, @ustrTableName_d = @ustrTableorObjName
, @strTableSubComment_d = @strTableSubComment
, @strTableComment_d = @strTableComment;


		/**Why this trashy garbage Dave? 
		* 1. I didn't have time to come up with a fake pass through TVF, nor would I want
		* 		what should just be a simple command and execute to have to go through the garbage
		* 		of having to SELECT out of a TVF.
		* 2. If we want to be able to select from our now 'much better than' ANSI DESCRIBE 
		*	 then we have to output the table like this. 
		* 3. Be advised if multiple people run this at the same time the global temp table will change!
		* 4.  Future iterations could allow someone to choose their own global temp table name, but again, 
		*	 I WANT SIMPLICITY ON THE CALL, even if the code itself is quite complex!
		* -- Dave Babler 2020-09-28
		*/


 
		SELECT *
		FROM ##DESCRIBE
        ORDER BY 2; --WE HAVE TO OUTPUT IT. 
	END


	ELSE
	BEGIN
		SET @strMessageOut = ' The table you typed in: ' + @ustrTableorObjName + ' ' + 'is invalid, check spelling, try again? ';

		SELECT @strMessageOut AS 'NON_LOGGED_ERROR_MESSAGE'
	END

		DROP TABLE
		IF EXISTS #__suppress_results;

		SET NOCOUNT OFF;
	END TRY

BEGIN CATCH
	INSERT INTO ERR.DB_EXCEPTION_TANK (
		[DatabaseName]
		, [UserName]
		, [ErrorNumber]
		, [ErrorState]
		, [ErrorSeverity]
		, [ErrorLine]
		, [ErrorProcedure]
		, [ErrorMessage]
		, [ErrorDateTime]
		)
	VALUES (
		DB_NAME()
		, SUSER_SNAME()
		, ERROR_NUMBER()
		, ERROR_STATE()
		, ERROR_SEVERITY()
		, ERROR_LINE()
		, ERROR_PROCEDURE()
		, ERROR_MESSAGE()
		, GETDATE()
		);

        
PRINT 
	'Please check the DB_EXCEPTION_TANK an error has been raised. 
		The query between the lines below will likely get you what you need.

		_____________________________


		WITH mxe
		AS (
			SELECT MAX(ErrorID) AS MaxError
			FROM ERR.DB_EXCEPTION_TANK
			)
		SELECT ErrorID
			, DatabaseName
			, UserName
			, ErrorNumber
			, ErrorState
			, ErrorLine
			, ErrorProcedure
			, ErrorMessage
			, ErrorDateTime
		FROM ERR.DB_EXCEPTION_TANK et
		INNER JOIN mxe
			ON et.ErrorID = mxe.MaxError

		_____________________________
';
END CATCH