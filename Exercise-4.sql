create or replace PROCEDURE Get_Order_Summary_Report 
IS
    CURSOR order_cursor IS
        SELECT 
            TO_NUMBER(REGEXP_SUBSTR(o.order_ref, '\d+')) AS Order_Reference,  -- Remove 'PO' prefix
            TO_CHAR(TO_DATE (o.ORDER_DATE, 'DD-MM-YYYY' ), 'MON-YYYY') AS Order_Period,  -- Format Order Date as MON-YYYY
            INITCAP(s.supplier_name) AS Supplier_Name,  -- Capitalize first letter of each word
            TO_CHAR(o.total_amount, '999,999,990.00') AS Order_Total_Amount,  -- Format amount
            o.order_status AS Order_Status,
            i.invoice_ref AS Invoice_Reference,
            TO_CHAR(i.invoice_amt, '999,999,990.00') AS Invoice_Total_Amount,  -- Format amount
            CASE
                WHEN COUNT(CASE WHEN i.invoice_status = 'Pending' THEN 1 END) > 0 THEN 'To follow up'
                WHEN COUNT(CASE WHEN i.invoice_status IS NULL OR i.invoice_status = '' THEN 1 END) > 0 THEN 'To verify'
                WHEN COUNT(CASE WHEN i.invoice_status = 'Paid' THEN 1 END) = COUNT(*) THEN 'OK'
                ELSE 'Unknown'
            END AS Action
        FROM Orders o
        JOIN Suppliers s ON o.supplier_id = s.supplier_id
        JOIN Invoices i ON o.order_id = i.order_id
        GROUP BY o.order_ref, o.order_date, s.supplier_name, o.total_amount, o.order_status, i.invoice_ref, i.invoice_amt
        ORDER BY o.order_date DESC;  -- Latest orders first

BEGIN
    -- Open cursor and loop through results
    FOR rec IN order_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Order Reference: ' || rec.Order_Reference ||
            ' | Order Period: ' || rec.Order_Period ||
            ' | Supplier Name: ' || rec.Supplier_Name ||
            ' | Order Total Amount: ' || rec.Order_Total_Amount ||
            ' | Order Status: ' || rec.Order_Status ||
            ' | Invoice Reference: ' || rec.Invoice_Reference ||
            ' | Invoice Total Amount: ' || rec.Invoice_Total_Amount ||
            ' | Action: ' || rec.Action
        );
    END LOOP;
END;

EXEC Get_Order_Summary_Report;