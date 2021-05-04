SELECT OBJECT_NAME(qt.objectid) AS ObjectName
	, qs.execution_count AS [Execution Count]
	, qs.execution_count / DATEDIFF(Second, qs.creation_time, GETDATE()) AS [Calls/Second]
	, qs.total_worker_time / qs.execution_count AS [AvgWorkerTime]
	, qs.total_worker_time AS [TotalWorkerTime]
	, qs.total_elapsed_time / qs.execution_count AS [AvgElapsedTime]
	, qs.max_logical_reads
	, qs.max_logical_writes
	, qs.total_physical_reads
	, DATEDIFF(Minute, qs.creation_time, GETDATE()) AS [Age in Cache]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
WHERE qt.[dbid] NOT IN (1, 2, 3, 4)
	AND OBJECT_NAME(qt.objectid) IS NOT NULL
	AND LEFT(OBJECT_NAME(qt.objectid), 2) NOT IN ('sp', 'xp')
	AND OBJECT_NAME(qt.objectid) NOT LIKE '%sqlagent%'
ORDER BY qs.execution_count DESC
OPTION (RECOMPILE);
--to do, put in sp_foreach 