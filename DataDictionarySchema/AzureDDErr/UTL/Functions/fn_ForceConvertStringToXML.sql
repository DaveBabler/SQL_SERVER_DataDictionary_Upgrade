
-- ==========================================================================================
-- Author:			Dave Babler
-- Create Date:		2022-03-09
-- Description:		This converts a string into a customized XML document and outputs it as a variable.
-- ==========================================================================================
CREATE   FUNCTION [UTL].[fn_ForceConvertStringToXML]
(
    -- Add the parameters for the function here
    @ustrIncomingValue NVARCHAR(MAX)
  , @ustrXMLRowName    NVARCHAR(64) = NULL
  , @ustrXMLRootName   NVARCHAR(64) = NULL
)
RETURNS XML
AS
    BEGIN
        -- Declare the return variable here
        DECLARE @xmlReturnedValue XML;
        IF @ustrXMLRowName IS NULL
            BEGIN
                SELECT  @ustrXMLRowName = 'RowData';
            END;
        IF @ustrXMLRootName IS NULL
            BEGIN
                SELECT  @ustrXMLRootName = 'Root';
            END;


        -- Add the T-SQL statements to compute the return value here
        SELECT  @xmlReturnedValue = CAST(REPLACE(
                                                    REPLACE(
                                                               CAST(CAST((
                                                                             SELECT     @ustrIncomingValue AS "*"
                                                                             FOR XML PATH('ZZZHoldingRowZZZ'), ROOT('ZZZHoldingRootZZZ'), ELEMENTS XSINIL
                                                                         ) AS XML) AS NVARCHAR(MAX))
                                                             , 'ZZZHoldingRowZZZ'
                                                             , @ustrXMLRowName
                                                           )
                                                  , 'ZZZHoldingRootZZZ'
                                                  , @ustrXMLRootName
                                                ) AS XML);

        -- Return the result of the function
        RETURN @xmlReturnedValue;

    /*
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^TESTING BLOCK^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   DECLARE @xmlReturnedValue NVARCHAR(MAX) = 'requestId	result.element.0.id	result.element.0.status	result.element.1.id	result.element.1.status	result.element.2.reasons.element.code	result.element.2.reasons.element.message	result.element.2.status	success
e42b#14272d07d78	50	created	51	created	1005	Lead already exists	skipped	true
';
   DECLARE @ustrXMLRowName NVARCHAR(64) = 'FireFoxError';
   DECLARE @ustrXMLRootName NVARCHAR(64) = 'Root';
	SELECT  UTL.fn_ForceConvertStringToXMLRow(@xmlReturnedValue, @ustrXMLRowName, @ustrXMLRootName) AS "XMLValue";
	SELECT  UTL.fn_ForceConvertStringToXMLRow(@xmlReturnedValue, DEFAULT, DEFAULT) AS "XMLValue with NULL defaults";
vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

    END;