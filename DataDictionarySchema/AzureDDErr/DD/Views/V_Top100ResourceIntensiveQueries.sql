CREATE    VIEW DD.V_Top100ResourceIntensiveQueries
AS
SELECT          TOP (100)
                DB_NAME(t.[dbid])                           AS [Database Name]
              , LEFT(t.[text], 50)                          AS [Short Query Text]
              , qs.total_worker_time                        AS [Total Worker Time]
              , qs.min_worker_time                          AS [Min Worker Time]
              , qs.total_worker_time / qs.execution_count   AS [Avg Worker Time]
              , qs.max_worker_time                          AS [Max Worker Time]
              , qs.min_elapsed_time                         AS [Min Elapsed Time]
              , qs.total_elapsed_time / qs.execution_count  AS [Avg Elapsed Time]
              , qs.max_elapsed_time                         AS [Max Elapsed Time]
              , qs.min_logical_reads                        AS [Min Logical Reads]
              , qs.total_logical_reads / qs.execution_count AS [Avg Logical Reads]
              , qs.max_logical_reads                        AS [Max Logical Reads]
              , qs.last_execution_time                      AS [Last Executed ]
              , qs.execution_count                          AS [Execution Count]
              , qs.creation_time                            AS [Creation Time]
              , t.[text]                                    AS [Query Text]
              , qp.query_plan                               AS [Query Plan] -- uncomment out these columns if not copying results to Excel

FROM            sys.dm_exec_query_stats           AS qs WITH (NOLOCK)
    CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
    CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
--WHERE           qs.last_execution_time
--BETWEEN         '2021-06-28' AND '2021-06-29'
ORDER BY        qs.max_worker_time DESC
              , qs.max_logical_reads DESC
;