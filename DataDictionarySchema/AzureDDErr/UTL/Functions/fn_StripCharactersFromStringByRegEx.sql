/*
 ==========================================================================
 Aut;hor:		Dave Babler
 Create date: 	2022-01-31
 Description:	This takes a string and a regular expression and 
				passes it to a paramaterized query for removing unwanted characters.
WARNING:		The use of this function is straight up RBAR.  You can mitigate that to an extent
				with a bulk UPDATE to a temp table instead of a raw select with this from the 
				primary table, but even then you're still RBAR.  Watch your resource consumption.
				IF YOU MUST DO SOMETHING LIKE THIS IT IS PREFERABLE TO DO IT OUTSIDE THE DATABASE 
				UNLESS YOU ARE DOING A FULL TABLE UPDATE.
REFERENCE:		This was lightly modfied from the solution provided here:
				https://stackoverflow.com/questions/1007697/how-to-strip-all-non-alphabetic-characters-from-string-in-sql-server
==========================================================================
*/
CREATE   FUNCTION UTL.fn_StripCharactersFromStringByRegEx 
(
	-- Add the parameters for the function here
	@ustrToClean NVARCHAR(MAX)
	, @strRegEx VARCHAR(256)
)
RETURNS NVARCHAR(MAX)
AS

    BEGIN
        SET @strRegEx = '%[' + @strRegEx + ']%';

        WHILE PATINDEX(@strRegEx, @ustrToClean) > 0
        SET @ustrToClean = STUFF(@ustrToClean, PATINDEX(@strRegEx, @ustrToClean), 1, '');

        RETURN @ustrToClean;
    END;

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--TESTING BLOCK--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	/*
		SELECT UTL.fn_StripCharactersFromStringByRegEx('Uy3mv+$jkKm6n&v%bd&M', '^a-z'); --keep only alpha
		SELECT UTL.fn_StripCharactersFromStringByRegEx('Uy3mv+$jkKm6n&v%bd&M', '^0-9') -- keep only numeric
		SELECT UTL.fn_StripCharactersFromStringByRegEx('Uy3mv+$jkKm6n&v%bd&M', '^a-z0-9'); --keep only alphanum
		SELECT UTL.fn_StripCharactersFromStringByRegEx('Uy3mv+$jkKm6n&v%bd&M', 'a-z0-9'); --keep only special charachters
        GO
    */
	--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv