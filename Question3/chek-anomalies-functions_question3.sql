----CREATE FUNCTION TO CHECK ALL ANOMAMIES IN CONTACT
 CREATE OR REPLACE FUNCTION checkContact (
    input_string IN VARCHAR2
) RETURN VARCHAR2 IS
    temp_string VARCHAR2(2000);
    output_number VARCHAR2(2000);
BEGIN
    temp_string := REPLACE(input_string, 'l', '1');
    temp_string := REPLACE(temp_string, 'o', '0');
    temp_string := REPLACE(temp_string, 'O', '0');
    temp_string := REPLACE(temp_string, 's', '5');
    temp_string := REPLACE(temp_string, 'S', '5');
    temp_string := REPLACE(temp_string, 'i', '1');
    temp_string := REPLACE(temp_string, 'I', '1');
    
    -- Suppression des virgules, espaces, et points
    temp_string := REPLACE(temp_string, ' ', '');
    temp_string := REPLACE(temp_string, '.', '');

    -- Conversion de la chaîne résultante en nombre
    BEGIN
        output_number := temp_string;
    EXCEPTION
        WHEN OTHERS THEN
            -- Si la conversion échoue, retourner NULL
            output_number := NULL;
    END;
    
    RETURN output_number;

END checkContact;

----CREATE FUNCTION TO CHECK ALL ANOMAMIES IN NUMBER
 CREATE OR REPLACE FUNCTION ConvertToNumberFn (
    input_string IN VARCHAR2
) RETURN NUMBER IS
    temp_string VARCHAR2(2000);
    output_number NUMBER;
BEGIN
    temp_string := REPLACE(input_string, 'l', '1');
    temp_string := REPLACE(temp_string, 'o', '0');
    temp_string := REPLACE(temp_string, 'O', '0');
    temp_string := REPLACE(temp_string, 's', '5');
    temp_string := REPLACE(temp_string, 'S', '5');
    temp_string := REPLACE(temp_string, 'i', '1');
    temp_string := REPLACE(temp_string, 'I', '1');
    
    -- Suppression des virgules, espaces, et points
    temp_string := REPLACE(temp_string, ',', '');
    temp_string := REPLACE(temp_string, ' ', '');
    temp_string := REPLACE(temp_string, '.', '');

    -- Conversion de la chaîne résultante en nombre
    BEGIN
        output_number := TO_NUMBER(temp_string);
    EXCEPTION
        WHEN OTHERS THEN
            -- Si la conversion échoue, retourner NULL
            output_number := NULL;
    END;
    
    RETURN output_number;
END ConvertToNumberFn;

----CREATE FUNCTION TO CHECK ALL ANOMAMIES IN DATE	
CREATE OR REPLACE FUNCTION ConvertDate (
    invoice_date_string IN VARCHAR2
) RETURN DATE IS
    output_date DATE;
BEGIN
    IF REGEXP_LIKE(invoice_date_string, '^\d{2}-[A-Z]{3}-\d{4}$') THEN
        output_date := TO_DATE(invoice_date_string, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=ENGLISH');
    ELSIF REGEXP_LIKE(invoice_date_string, '^\d{2}-\d{2}-\d{4}$') THEN
        output_date := TO_DATE(invoice_date_string, 'DD-MM-YYYY');
    ELSE
        RETURN NULL;
    END IF;
    RETURN output_date;
END ConvertDate;
