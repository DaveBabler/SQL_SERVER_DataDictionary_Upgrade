
CREATE VIEW DD.V_AgentJobsByInterval
AS
	SELECT S.name AS JobName
		 , SS.name AS ScheduleName
		 , CASE (SS.freq_type)
			   WHEN 1 THEN 'Once'
			   WHEN 4 THEN 'Daily'
			   WHEN 8 THEN
		 (CASE
			   WHEN (SS.freq_recurrence_factor > 1) THEN
			   'Every ' + CONVERT(VARCHAR(3), SS.freq_recurrence_factor) + ' Weeks'
			   ELSE 'Weekly'
		   END
		 )
			   WHEN 16 THEN
		 (CASE
			   WHEN (SS.freq_recurrence_factor > 1) THEN
			   'Every ' + CONVERT(VARCHAR(3), SS.freq_recurrence_factor) + ' Months'
			   ELSE 'Monthly'
		   END
		 )
			   WHEN 32 THEN 'Every ' + CONVERT(VARCHAR(3), SS.freq_recurrence_factor) + ' Months' -- RELATIVE
			   WHEN 64 THEN 'SQL Startup'
			   WHEN 128 THEN 'SQL Idle'
			   ELSE '??'
		   END AS Frequency
		 , CASE
			   WHEN (SS.freq_type = 1) THEN 'One time only'
			   WHEN
				   (
					   SS.freq_type = 4
					   AND SS.freq_interval = 1
				   ) THEN 'Every Day'
			   WHEN
				   (
					   SS.freq_type = 4
					   AND SS.freq_interval > 1
				   ) THEN 'Every ' + CONVERT(VARCHAR(10), SS.freq_interval) + ' Days'
			   WHEN (SS.freq_type = 8) THEN
				   (
					   SELECT 'Weekly Schedule' = MIN(F.D1 + F.D2 + F.D3 + F.D4 + F.D5 + F.D6 + F.D7)
					   FROM
						   (
							   SELECT ss.schedule_id
									, ss.freq_interval
									, 'D1' = CASE WHEN (ss.freq_interval & 1 <> 0) THEN 'Sun ' ELSE '' END
									, 'D2' = CASE WHEN (ss.freq_interval & 2 <> 0) THEN 'Mon ' ELSE '' END
									, 'D3' = CASE WHEN (ss.freq_interval & 4 <> 0) THEN 'Tue ' ELSE '' END
									, 'D4' = CASE WHEN (ss.freq_interval & 8 <> 0) THEN 'Wed ' ELSE '' END
									, 'D5' = CASE WHEN (ss.freq_interval & 16 <> 0) THEN 'Thu ' ELSE '' END
									, 'D6' = CASE WHEN (ss.freq_interval & 32 <> 0) THEN 'Fri ' ELSE '' END
									, 'D7' = CASE WHEN (ss.freq_interval & 64 <> 0) THEN 'Sat ' ELSE '' END
							   FROM msdb..sysschedules AS ss
							   WHERE ss.freq_type = 8
						   ) AS F
					   WHERE F.schedule_id = SJ.schedule_id
				   )
			   WHEN (SS.freq_type = 16) THEN 'Day ' + CONVERT(VARCHAR(2), SS.freq_interval)
			   WHEN (SS.freq_type = 32) THEN
				   (
					   SELECT WS.freq_rel + WS.WDAY
					   FROM
						   (
							   SELECT SS.schedule_id
									, 'freq_rel' = CASE (SS.freq_relative_interval)
													   WHEN 1 THEN 'First'
													   WHEN 2 THEN 'Second'
													   WHEN 4 THEN 'Third'
													   WHEN 8 THEN 'Fourth'
													   WHEN 16 THEN 'Last'
													   ELSE '??'
												   END
									, 'WDAY' = CASE (SS.freq_interval)
												   WHEN 1 THEN ' Sun'
												   WHEN 2 THEN ' Mon'
												   WHEN 3 THEN ' Tue'
												   WHEN 4 THEN ' Wed'
												   WHEN 5 THEN ' Thu'
												   WHEN 6 THEN ' Fri'
												   WHEN 7 THEN ' Sat'
												   WHEN 8 THEN ' Day'
												   WHEN 9 THEN ' Weekday'
												   WHEN 10 THEN ' Weekend'
												   ELSE '??'
											   END
							   FROM msdb..sysschedules AS SS
							   WHERE SS.freq_type = 32
						   ) AS WS
					   WHERE WS.schedule_id = SS.schedule_id
				   )
		   END AS Interval
		 , CASE (SS.freq_subday_type)
			   WHEN 1 THEN
			   LEFT(STUFF(
							 (STUFF(
									   (REPLICATE('0', 6 - LEN(SS.active_start_time)))
									   + CONVERT(VARCHAR(6), SS.active_start_time)
									 , 3
									 , 0
									 , ':'
								   )
							 )
						   , 6
						   , 0
						   , ':'
						 ), 8)
			   WHEN 2 THEN 'Every ' + CONVERT(VARCHAR(10), SS.freq_subday_interval) + ' seconds'
			   WHEN 4 THEN 'Every ' + CONVERT(VARCHAR(10), SS.freq_subday_interval) + ' minutes'
			   WHEN 8 THEN 'Every ' + CONVERT(VARCHAR(10), SS.freq_subday_interval) + ' hours'
			   ELSE '??'
		   END AS Time
		 , CASE SJ.next_run_date
			   WHEN 0 THEN CAST('n/a' AS CHAR(10))
			   ELSE
			   CONVERT(CHAR(10), CONVERT(DATETIME, CONVERT(CHAR(8), SJ.next_run_date)), 120) + ' '
			   + LEFT(STUFF(
							   (STUFF(
										 (REPLICATE('0', 6 - LEN(SJ.next_run_time)))
										 + CONVERT(VARCHAR(6), SJ.next_run_time)
									   , 3
									   , 0
									   , ':'
									 )
							   )
							 , 6
							 , 0
							 , ':'
						   ), 8)
		   END AS NextRunTime
	FROM
		msdb.dbo.sysjobs AS S
	LEFT JOIN msdb.dbo.sysjobschedules AS SJ
		   ON S.job_id = SJ.job_id
	LEFT JOIN msdb.dbo.sysschedules AS SS
		   ON SS.schedule_id = SJ.schedule_id;
GO