--create procedure to insert order child status
create procedure load_status
as
begin
    INSERT INTO STATUS (STATUS_ID, LABEL) VALUES ('STAT_2', 'RECEIVED');
    INSERT INTO STATUS (STATUS_ID, LABEL) VALUES ('STAT_3', 'CANCELLED');
end;


--create procedure to insert invoice status
create procedure load_inv_status
as
begin
INSERT INTO INV_STATUS (STATUS_ID, LABEL) VALUES ('STATINV_1', 'Paid');
INSERT INTO INV_STATUS (STATUS_ID, LABEL) VALUES ('STATINV_3', 'Pending');
end;

-- create procedure to insert Orders
CREATE OR replace procedure add_orders
as
begin
insert into ORDERS(
    OR_ID,
    OR_REF,
    OR_DESC,
    OR_DATE,
    OR_STATUS,
    SUPPLIERS_ID,
    TOTAL_AMOUNT
    )
select 
'ORD'||ORDERS_SEQ.nextval,
xx.ORDER_REF,
xx.ORDER_DESCRIPTION,
ConvertDate(xx.ORDER_DATE),
xx.ORDER_STATUS,
(SELECT 
   S.Suppliers_ID 
	FROM Suppliers s 
   where s.SUP_NAME = xx.SUPPLIER_NAME)
   as SUPPLIERS_ID,
ConvertToNumberFn(xx.ORDER_TOTAL_AMOUNT)
from XXBCM_ORDER_MGT xx
where xx.ORDER_LINE_AMOUNT is null;
end;

-- create procedure to insert Orders_Detail
create procedure add_orders_detail
as
begin
insert into ORDERS_DETAIL(
    OR_D_ID,
    OR_D_LINE_AMOUNT,
    OR_D_DESC,
    OR_D_REF,
    OR_ID,
    STATUS_ID
    )
select
'ORD_L'||ORDERS_DETAIL_SEQ.nextval,
ConvertToNumberFn(xx.ORDER_LINE_AMOUNT),
xx.ORDER_DESCRIPTION,
xx.ORDER_REF,
(SELECT 
   O.OR_ID 
   FROM ORDERS O 
   where O.OR_REF = SUBSTR(xx.ORDER_REF, 1, INSTR(xx.ORDER_REF, '-') - 1))
   as OR_ID,
case
   when xx.ORDER_STATUS = 'Received' then 'STAT_2'
   when xx.ORDER_STATUS = 'Cancelled' then 'STAT_3'
   else 'STAT_0'
end as STATUS_ID
from XXBCM_ORDER_MGT xx
where xx.ORDER_LINE_AMOUNT is not null;
end;


--create view using for insert Suppliers
create or replace view suppliers_distinct as 
(
    SELECT DISTINCT
        SUPPLIER_NAME,
        SUPP_ADDRESS,
        SUPP_EMAIL,
        SUPP_CONTACT_NUMBER,
        SUPP_CONTACT_NAME
    FROM 
        XXBCM_ORDER_MGT;
);

-- create procedure to insert Suppliers
CREATE OR REPLACE PROCEDURE InsertIntoSuppliers
AS
BEGIN
    INSERT INTO SUPPLIERS (
        SUPPLIERS_ID,
        SUP_NAME,
        SUP_ADDRESS,
        SUP_EMAIL,
        SUP_CONTACT_NUMBER,
        SUP_CONTACT_NAME
    )
    SELECT  
        'SUP-'||SUPPLIER_SEQ.NEXTVAL,
        SUPPLIER_NAME,
        SUPP_ADDRESS,
        SUPP_EMAIL,
        checkContact(SUPP_CONTACT_NUMBER) AS SUPP_CONTACT_NUMBER,
        SUPP_CONTACT_NAME
    FROM 
        suppliers_distinct;
END;

-- create procedure to insert INVOICE
CREATE OR REPLACE PROCEDURE InsertIntoInvoices
AS
BEGIN
    INSERT INTO INVOICE (
        INV_ID,
        INV_REF,
        INV_DATE,
        INV_STATUS,
        INV_HOLD_REASON,
        INV_DESC,
        INV_AMOUNT,
        SUPPLIERS_ID,
        OR_ID 
    )
    SELECT 
        'INV-'||INVOICE_SEQ.NEXTVAL INVOICE_ID,
        X.INVOICE_REFERENCE,
        ConvertDate(X.INVOICE_DATE) AS INVOICE_DATE,
        (SELECT STAT.STATUS_ID FROM inv_status STAT WHERE STAT.LABEL = X.INVOICE_STATUS) AS STATUS_ID,
        X.INVOICE_HOLD_REASON,
        X.INVOICE_DESCRIPTION,
        ConvertToNumberFn (X.INVOICE_AMOUNT) as INVOICE_AMOUNT,
        (SELECT S.SUPPLIERS_ID FROM SUPPLIERS S WHERE S.SUP_NAME = X.SUPPLIER_NAME) AS SUPPLIERS_ID,
        (SELECT O.OR_ID  FROM ORDERS O WHERE O.OR_REF =  SUBSTR(X.ORDER_REF, 1, INSTR(X.ORDER_REF, '-') - 1)) AS OR_ID
    FROM
        XXBCM_ORDER_MGT X WHERE x.INVOICE_REFERENCE  IS NOT null;
END;


CREATE PROCEDURE load_all
AS
BEGIN
    CALL load_status();
    CALL load_inv_status();
    CALL InsertIntoSuppliers();
    CALL add_orders();
    CALL add_orders_detail();
    CALL InsertIntoInvoices();
END;
