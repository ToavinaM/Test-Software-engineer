ALTER SESSION SET NLS_DATE_LANGUAGE = 'ENGLISH';
CREATE OR REPLACE FUNCTION get_all_refinvoice(v_or_id IN varchar2) 
RETURN VARCHAR2 IS  
    v_or_ref_concat VARCHAR2(255); 
BEGIN
    SELECT 
        LISTAGG( i.inv_ref, '|') WITHIN GROUP (ORDER BY inv_date)
    INTO v_or_ref_concat
    FROM 
        INVOICE i
        JOIN ORDERS o ON i.or_id = o.or_id 
    WHERE 
        i.or_id =v_or_id
        ; 
    RETURN v_or_ref_concat; 
END;
/
CREATE OR REPLACE FUNCTION get_refINVOICE_by_order(v_or_id IN varchar2) 
RETURN VARCHAR2 IS  
    v_or_ref VARCHAR2(255); 
BEGIN
    SELECT 
        'inv_' ||min(o.or_ref)
    INTO v_or_ref
    FROM 
        INVOICE i
        JOIN ORDERS o ON i.or_id = o.or_id 
    WHERE 
        i.or_id = v_or_id
        ; 
    RETURN v_or_ref; 
END;
/
CREATE OR REPLACE FUNCTION get_amount_INVOICE_by_order(v_or_id IN varchar2) 
RETURN NUMBER IS  
    v_inv_amount NUMBER (30,2); 
BEGIN
    SELECT 
        SUM(nvl(i.inv_amount,0))
    INTO v_inv_amount
    FROM 
        INVOICE i
    WHERE 
        i.or_id = v_or_id; 
    RETURN v_inv_amount; 
END;      
/
   ---------bien     
      CREATE OR REPLACE FUNCTION get_status_inv(p_order_id IN VARCHAR) RETURN VARCHAR2 IS
    v_status_count NUMBER;
   v_status_count2 NUMBER;
BEGIN
	  SELECT COUNT(*)
    INTO v_status_count
    FROM INVOICE
    WHERE or_id = p_order_id
      AND inv_status = 'STA-3';
     IF v_status_count > 0 THEN
        RETURN 'To follow up';
    END IF;
 
    SELECT COUNT(*)
    INTO v_status_count
    FROM INVOICE
    WHERE or_id = p_order_id
      AND (inv_status IS NULL OR inv_status = '');

    IF v_status_count > 0 THEN
        RETURN 'To verify';
    END IF;
   
    SELECT COUNT(*)
    INTO v_status_count
    FROM INVOICE
    WHERE or_id = p_order_id ;
   
        SELECT COUNT(*)
    INTO v_status_count2
    FROM INVOICE
    WHERE or_id = p_order_id
    AND inv_status <> 'STA-1';
    IF (v_status_count2 = 0 AND v_status_count > 0) THEN
        RETURN 'OK';
    END IF;

    RETURN 'Unknown Status';
END;
/
---------------------------

CREATE  OR REPLACE view respond4 AS 
 SELECT 
      	TO_NUMBER(REGEXP_SUBSTR(xo.or_ref, '\d+')) AS order_reference,
      	TO_CHAR(xo.OR_DATE , 'MON-YYYY') AS ORDER_date,
      	xo.OR_DATE AS order_date_date,
      	xo.or_desc AS  ORDER_description,
      	 TO_CHAR(xo.total_amount, 'FM999,999,999.00')
        AS 	order_total_amount,
        xo.total_amount AS order_total_amount_nbr,
      	or_status AS orders_status ,
      	INITCAP(xs.sup_name) AS supplier_name,
      	 get_refINVOICE_by_order(xo.or_id) AS invoice_reference,
         TO_CHAR(get_amount_INVOICE_by_order(xo.OR_ID), 'FM999,999,999.00') AS invoice_amount,
        get_status_inv(xo.OR_ID) AS ACTION ,
         xo.suppliers_id,
         xo.or_id
       FROM 
      	orders  xo,
      	SUPPLIERS  xs 
      	WHERE 
      		xo.suppliers_id=xs.suppliers_id(+)
      	ORDER BY xo.OR_DATE DESC
      	;
      	
  --------
  
      CREATE OR REPLACE VIEW respond5 as
      SELECT ORDER_REFERENCE ,
       TO_CHAR(order_date_date, 'Month DD, YYYY') AS order_date ,
       SUPPLIER_NAME ,
       ORDER_TOTAL_AMOUNT ,
       orders_status ,
     get_all_refinvoice(or_id) AS all_invoice_references
FROM (
    SELECT 
       r.*,
        RANK() OVER (ORDER BY order_total_amount DESC) AS rnk -- Pas de conversion nécessaire ici
    FROM respond4 r 
)
WHERE rnk = 2;

----------
CREATE OR REPLACE VIEW respond6 AS 
SELECT
sup_name,
SUP_CONTACT_NAME,
data1.*,
REPLACE(REPLACE((REGEXP_SUBSTR((SUP_CONTACT_NUMBER), '[^,]+', 1, 1)), ' ', ''), '.', '') AS contact1,
REPLACE(REPLACE((REGEXP_SUBSTR((SUP_CONTACT_NUMBER), '[^,]+', 1, 2)), ' ', ''), '.', '') AS contact2
 FROM (SELECT suppliers_id ,
sum(order_total_amount_nbr) AS order_total_amount ,
count(order_reference) AS total_order
FROM  respond4  v 
WHERE	v.order_date_date BETWEEN TO_DATE('01-JAN-2022', 'DD-MON-YYYY') AND TO_DATE('31-AUG-2022', 'DD-MON-YYYY')
GROUP BY suppliers_id)data1,
suppliers s 
WHERE s.suppliers_id= data1.suppliers_id
;

