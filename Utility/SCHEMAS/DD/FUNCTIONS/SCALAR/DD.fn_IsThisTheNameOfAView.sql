USE [Utility];
GO
-- ==========================================================================================
-- Author:		Dave Babler
-- Create date: 2021-01-31
-- Description:	Checks to see based on ***common naming conventions*** if the passed string 
-- 				is likely the name of a view instead of a table
-- 				Since this not going to be a program that will be called typically outside of another proc 
-- 				have left it's name in the traditional fn_ convention.
-- ==========================================================================================
CREATE
	OR

ALTER FUNCTION [DD].[fn_IsThisTheNameOfAView] (
	-- Add the parameters for the function here
	@ustrName NVARCHAR(64)
	)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @bitFlag BIT

	-- First Check to see if the 'table' name starts with a V if not assume not view and throw false flag
	IF LOWER(LEFT(@ustrName, 1)) = 'v'
	BEGIN
		SET @bitFlag = CASE 
				WHEN LOWER(LEFT(@ustrName, 4)) = 'view'
					THEN 1
				WHEN LOWER(LEFT(@ustrName, 3)) = 'viw'
					THEN 1
				WHEN LOWER(LEFT(@ustrName, 2)) = 'vw'
					THEN 1
				WHEN LOWER(LEFT(@ustrName, 2)) = 'v_'
					THEN 1
				ELSE 0
				END
	END
	ELSE
	BEGIN
		SET @bitFlag = 0
	END

	-- Return the result of the function
	RETURN @bitFlag
END
GO


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
/*
	 SELECT UTL.fn_IsThisTheNameOfAView('V_ofDATA'); 
*/
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

GO