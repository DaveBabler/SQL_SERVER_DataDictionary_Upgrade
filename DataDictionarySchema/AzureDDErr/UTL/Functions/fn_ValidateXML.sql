/*
==========================================================================================
Author:			Dave Babler
Create Date:	2022-03-22
Description:	Does limited check for well-formed XML has <?xml or <root>.
WARNING:		Would be most wise to use TRY_CAST when passing in a string you want to check to see if it actually is XML
				Instead of when you know for a fact it is XML and just want validity.
==========================================================================================
*/
CREATE FUNCTION [UTL].[fn_ValidateXML]
(
    -- Add the parameters for the function here
    @xmlValueIncoming XML
)
RETURNS BIT
AS
    BEGIN
        DECLARE @intIsXMLValid BIT = 0;

        IF CHARINDEX('<?xml', CONVERT(NVARCHAR(MAX), @xmlValueIncoming)) > 0
            BEGIN
                SET @intIsXMLValid = 1;
            END;
        ELSE IF CHARINDEX('<root>', CONVERT(NVARCHAR(MAX), @xmlValueIncoming)) > 0
                 BEGIN
                     SET @intIsXMLValid = 1;
                 END;
		ELSE IF CHARINDEX('xmlns',  CONVERT(NVARCHAR(MAX), @xmlValueIncoming)) > 0 --highly unlikely anyone uses that not doing XML
                 BEGIN
                     SET @intIsXMLValid = 1;
                 END;
        ELSE
                 BEGIN
                     SET @intIsXMLValid = 0;
                 END;
        RETURN @intIsXMLValid;
/******************************TESTING BLOCK************************************************

	SELECT UTL.fn_ValidateXML(TRY_CONVERT(XML, '<root><shoe> Saucony </shoe></root>')); --TRUE
	SELECT UTL.fn_ValidateXML(TRY_CONVERT(XML, '<shoe> Saucony </shoe>')); --FALSE (yes XML, not WellFormed).
	SELECT UTL.fn_ValidateXML(TRY_CONVERT(XML, '<shoe> Saucony </shue>')); --FALSE
	SELECT UTL.fn_ValidateXML(TRY_CONVERT(XML, 'Saucony')); --FALSE

*******************************************************************************************/

    END;