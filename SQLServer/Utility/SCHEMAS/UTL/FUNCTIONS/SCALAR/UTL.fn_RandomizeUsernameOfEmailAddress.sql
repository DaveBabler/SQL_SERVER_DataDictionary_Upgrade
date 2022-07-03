SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/*
    ==========================================================================================
    Author:		Dave Babler
    Create date: 2022-01-30
    Description:	Takes the Username (pre '@' symbol) of an email address, and replaces it with a randomized text string.  
    			    This is likely to be run within a stored procedure and never on production data.
					This limits the length of the username to 20 max as a constant but this can be expaned to 64
					Why no SELECT of a GUID with some text play? Because as of date the documentation states
						"The GUID generation algorithm was designed for uniqueness. 
						 It was not designed for randomness or for unpredictability, "(Microsoft, 2012). 
    SubProcedures:  UTL.fn_StripCharactersFromStringByRegEx 
	WARNING:		The use of this function is straight up RBAR.  You can mitigate that to an extent
					with a bulk UPDATE to a temp table instead of a raw select with this from the 
					primary table, but even then you're still RBAR.  Watch your resource consumption.
	REFERENCE:		https://devblogs.microsoft.com/oldnewthing/20120523-00/?p=7553#:~:text=The%20GUID%20generation%20algorithm%20was,for%20randomness%20or%20for%20unpredictability.&text=Definitely%20not%20random.
    ==========================================================================================
*/
CREATE OR ALTER FUNCTION DUTIL.fn_RandomizeUsernameOfEmailAddress
(
    -- Add the parameters for the function here
    @nstrEmailAddress NVARCHAR(2000)
)
RETURNS NVARCHAR(2000)
AS
    BEGIN
        DECLARE @nstrRandomizedUserName NVARCHAR(64)
              , @nstrRanomizedUserEmail NVARCHAR(2000);

        SELECT  TOP (1) @nstrRandomizedUserName = UTL.fn_StripCharactersFromStringByRegEx(
                                                                                             LEFT(vrs.RandomString, 20)
                                                                                           , '^a-z0-9'
                                                                                         )
        FROM    Utility.UTL.V_RandomString AS vrs
        ORDER BY vrs.RandomString;




        SELECT  @nstrRanomizedUserEmail = REPLACE(
                                                     @nstrEmailAddress
                                                   , LEFT(@nstrEmailAddress, CHARINDEX('@', @nstrEmailAddress) - 1)
                                                   , @nstrRandomizedUserName
                                                 );


        RETURN @nstrRanomizedUserEmail;

    END;
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
/*
		SELECT DUTIL.fn_RandomizeUsernameOfEmailAddress ('SOMEEMAIL@SomeDomain.gbg')
        GO
    */
--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv


GO




