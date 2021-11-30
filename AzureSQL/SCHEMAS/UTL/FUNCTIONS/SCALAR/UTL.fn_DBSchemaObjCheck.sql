USE [Utility]
GO

/****** Object:  UserDefinedFunction [DD].[fn_DBSchemaObjCheck]    Script Date: 5/19/2021 9:30:07 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- ======================================================================================
-- Author:		Dave Babler
-- Create date:	11/09/2020
-- Description:	Splits a dot object notation string and passes it out as a table
--              This is effectively a rehash of UTL_fn_DelimListToTable.
--				However, the author felt it was important to hard code the period for saftey, and
-- 				segregated it from functions that might be used in other procs. 
--				If the CTO wishes this method can be scrapped and the other used.
-- 				This does relate to the data dictionary ease of use programs and DD schema; however, 
-- 				Since this not going to be a program that will be called typically outside of another proc 
-- 				have left it's name in the traditional fn_ convention.
--              YES, THE AUTHOR IS AWARE OF THE SQL SERVER PARSENAME FUNCTIONALITY
--              I *LIKE MINE* BETTER, (for now)
--              I fully reserve the right to alther the code back to PARSENAME in the future
--              Please pay attention to releases in github!
-- ======================================================================================
CREATE OR ALTER   FUNCTION [DD].[fn_DBSchemaObjCheck] (  
	@strDelimitedStringToParse NVARCHAR(MAX)
	
	)
RETURNS @tblParsedList TABLE (ValueID INT, StringValue NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS)
AS
BEGIN      
DECLARE @charDelimiter CHAR = '.';
WITH RecursiveTable (
	StartingPosition
	, EndingPosition
	)
AS (
	SELECT CAST(1 AS BIGINT) StartingPosition
		, CHARINDEX(@charDelimiter, @strDelimitedStringToParse) EndingPosition
	--gets the first delimiter, the count of chars to the next one
	
	UNION ALL
	
	SELECT EndingPosition + 1
		, CHARINDEX(@charDelimiter, @strDelimitedStringToParse, EndingPosition + 1)
	--next number after the first Delimiter(starting pointer), go to next delimiter & mark that,
	FROM RecursiveTable --recursion calling from inside itself in the Common Table Expression
	WHERE EndingPosition > 0
		--keep going as long as there's more stuff in the list
	)
INSERT INTO @tblParsedList
SELECT ROW_NUMBER() OVER (
		ORDER BY (
				SELECT 1
				)
		) --Hackishway of making a sequential id.
	, TRIM(SUBSTRING(@strDelimitedStringToParse, StartingPosition, COALESCE(NULLIF(EndingPosition, 0), LEN(
				@strDelimitedStringToParse) + 1) - StartingPosition)) --TRIM to get rid of trailing spaces
FROM RecursiveTable
OPTION (MAXRECURSION 0);
                
        /**Here coalesce is what's allowing us to deal with lists where there are spaces around delimiters
         *   'red, orange , yellow,green,blue, purple'   It also helps us grab purple too--Dave Babler */
RETURN --RETURNS @tblParsedList 
END
GO


