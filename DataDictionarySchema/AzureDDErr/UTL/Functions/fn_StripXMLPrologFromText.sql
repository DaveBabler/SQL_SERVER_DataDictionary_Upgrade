-- =============================================
-- Author:      Dave Babler
-- Create Date: 2022-04-01
-- Description: This ugly function is used to strip an xml prologue and is the only way to do this in AzureSQL once something is in the DB
-- =============================================
CREATE   FUNCTION UTL.fn_StripXMLPrologFromText
(
    -- Add the parameters for the function here
    @ustrXMLAsString NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
    BEGIN
        IF PATINDEX('<?xml version=%utf%>', @ustrXMLAsString) > 0
            BEGIN
                SET @ustrXMLAsString = STUFF(
                                                @ustrXMLAsString
                                              , PATINDEX('<?xml version=%utf%>', @ustrXMLAsString)
                                              , CHARINDEX('?>', @ustrXMLAsString) + 1
                                              , ''
                                            );
            END;
        RETURN @ustrXMLAsString;


/*
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
SELECT UTL.fn_StripXMLPrologFromText('<?xml version="1.0" encoding="utf-8"?><MSIACORD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"<MSIACORD>')

vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

    END;