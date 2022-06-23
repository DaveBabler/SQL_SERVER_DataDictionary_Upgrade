BEGIN TRY
	DECLARE @intShoes INT

	SELECT @intShoes = 1 / 0;
END TRY

BEGIN CATCH
	INSERT INTO CustomLog.ERR.DB_EXCEPTION_TANK (
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
		, ISNULL(ERROR_PROCEDURE(), CONCAT (
				ERROR_PROCEDURE()
				, ' '
				, CONCAT (
					DB_NAME()
					, '.'
					, SCHEMA_NAME()
					, '.'
					, OBJECT_NAME(@@PROCID)
					)
				))
		, ERROR_MESSAGE()
		, GETDATE()
		);
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		/*
			DECLARE	
			
			SET	
			
			EXECUTE	
			
			SELECT	
		*/
	--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	--dddddddddddddddddddddddddddddddddddddddddddd--DynamicSQLAsRegularBlock--dddddddddddddddddddddddddddddddddddddddddddddd
		/*
		--Place your dynamic SQL block here as normal SQL so others know what you are doing!
		--if you are concatenating to a large block of Dynamic SQL use your best judgement if all of it needs to be down here or not
				
				
		*/
	--DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
	THROW
END CATCH;

