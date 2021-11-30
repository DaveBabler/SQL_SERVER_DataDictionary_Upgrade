
GO

-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:		Dave Babler
-- Create date: 2021-05-04
-- Description:	This counts the number of times a string appears in another string 
--				400 char limit, need more, find a different way
-- ==========================================================================================
CREATE
	OR

ALTER FUNCTION UTL.fn_CountOccurrencesOfString (
	-- Add the parameters for the function here
	@ustrSearchingThis NVARCHAR(MAX)
	, @ustrSearchingFor NVARCHAR(400)
	)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @intCountReturn INT;

	-- Add the T-SQL statements to compute the return value here
	SELECT @intCountReturn = (LEN(@ustrSearchingThis) - LEN(REPLACE(lower(@ustrSearchingThis), lower(@ustrSearchingFor), ''))
			) / LEN(@ustrSearchingFor)

	-- Return the result of the function
	RETURN @intCountReturn
END
GO

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
/*
        SELECT [UTL].[fn_CountOccurrencesOfString]
                    ('IloveDOGS dogseatingfood DOGGIES, Doggy, doggies dogsarebetterthanpeople'
                      ,'DoG') AS N'≈NumberOfHits';
        GO
    */
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv



