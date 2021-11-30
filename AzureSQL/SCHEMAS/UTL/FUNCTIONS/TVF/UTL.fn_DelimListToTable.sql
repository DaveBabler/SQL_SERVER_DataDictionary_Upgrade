
GO
---this comment exists only to force it near the top of the heap in a github pull request---babler
-- ======================================================================================
-- Author:		Dave Babler
-- Create date:	09/15/2020
-- Description:	Splits a (small) delimited list into a single column table 
--              thus allowing the table to be used in an "IN" clause in a different
--              query, procedure, or function. 
-- 				This procedure is sadly, very useful in many different situations.
--				WARNING: TABLE VARIABLES SHOULD BE ≈1000 records or less! 
-- 				If you have more, don't use this function, make a temp table!
-- ======================================================================================
CREATE OR ALTER FUNCTION [UTL].[fn_DelimListToTable] (  
	@strDelimitedStringToParse NVARCHAR(MAX)
    , @charDelimiter CHAR(1)
)
RETURNS @tblParsedList TABLE (ValueID INT, StringValue NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS)
AS

BEGIN      
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