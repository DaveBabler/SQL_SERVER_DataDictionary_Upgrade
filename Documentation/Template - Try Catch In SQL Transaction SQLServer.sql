BEGIN TRY
	SET XACT_ABORT ON;-- 

	BEGIN TRANSACTION

	UPDATE NECRONOMICON
	SET DemonsSummonedPerActivation = (12 / 0);

	COMMIT;

	SET XACT_ABORT OFF;-- 
END TRY

BEGIN CATCH
	IF (XACT_STATE()) = - 1 --test to see if we cannot commit
	BEGIN
		PRINT N'The transaction is in an uncommittable state.' + 'Rolling back transaction.'

		ROLLBACK TRANSACTION;

		SET XACT_ABORT OFF;
			-- currently our database has this as default so we need to double check it turns off on fail or success
	END;

	IF (XACT_STATE()) = 1 -- Test if the transaction is committable.  
	BEGIN
		PRINT N'The transaction is committable.' + 'Committing transaction.'

		COMMIT TRANSACTION;

		SET XACT_ABORT OFF;
			-- currently our database has this as default so we need to triple check it turns off on fail or success
	END;

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

	THROW;
END CATCH;
GO


