create or replace PROCEDURE second_highest_order IS
CURSOR order_cursor IS

    SELECT *
    FROM (
        SELECT
            REGEXP_REPLACE(order_ref, '^PO', '') AS order_reference,
            TO_CHAR(TO_DATE (ORDER_DATE, 'DD-MM-YYYY' ), 'Month DD, YYYY') AS order_date,
            UPPER(supplier_name) AS supplier_name,
            TO_CHAR(total_amount, '999,999,990.00') AS order_total_amount,
            order_status,
            LISTAGG(invoice_ref, '|') WITHIN GROUP (ORDER BY invoice_ref) AS invoice_references,
        ROW_NUMBER() OVER (ORDER BY total_amount DESC) As Row_Num
        FROM Orders o
        JOIN Suppliers s ON s.SUPPLIER_ID = o.ORDER_ID
        JOIN Invoices i ON o.order_id = i.order_id
        GROUP BY REGEXP_REPLACE(order_ref, '^PO', ''), order_date, supplier_name, TO_CHAR(TOTAL_AMOUNT, '999,999,990.00'), order_status, total_amount
        ORDER BY order_total_amount DESC
    )
    WHERE Row_Num = 2;
BEGIN
      FOR rec IN order_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Order Reference: ' || rec.order_reference ||
            ' | Order Date: ' || rec.order_date ||
            ' | Supplier Name: ' || rec.supplier_name ||
            ' | Order Total Amount: ' || rec.order_total_amount ||
            ' | Order Status: ' || rec.order_status ||
            ' | Invoice Reference: ' || rec.invoice_references
        );
    END LOOP;
END;

EXEC second_highest_order;