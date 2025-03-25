--Exercise 6
--  List All Suppliers with Orders Between 01 Jan 2022 and 31 Aug 2022



CREATE OR REPLACE PROCEDURE supplier_order_summary 
IS
    CURSOR order_cursor IS


    SELECT
        supplier_name,
        contact_name,
        email,
        SUBSTR(c.contact_number,
                              1,
                              INSTR(c.contact_number, ',', 1, 1) - 1) As contact1,
        SUBSTR(c.contact_number,
                                INSTR(c.contact_number, ',', 1, 1) + 2,
                                INSTR(c.contact_number, ',', 1, 2) - INSTR(c.contact_number, ',', 1, 1) - 2) As contact2,


        COUNT(o.order_id) AS total_orders,
        TO_CHAR(SUM(o.total_amount), '999,999,990.00') AS total_amount
    FROM Suppliers s
    JOIN Orders o ON s.supplier_id = o.supplier_id
    JOIN Supp_contacts c ON s.supplier_id = c.supplier_id
    WHERE o.order_date BETWEEN TO_DATE('2022-01-01', 'YYYY-MM-DD') AND TO_DATE('2022-08-31', 'YYYY-MM-DD')
       GROUP BY supplier_name, contact_name, email, SUBSTR(c.contact_number,
                              1,
                              INSTR(c.contact_number, ',', 1, 1) - 1),  SUBSTR(c.contact_number,
                                INSTR(c.contact_number, ',', 1, 1) + 2,
                                INSTR(c.contact_number, ',', 1, 2) - INSTR(c.contact_number, ',', 1, 1) - 2);

BEGIN
    -- Open cursor and loop through results
    FOR rec IN order_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            ' |Supplier name: ' || rec.supplier_name ||
            ' | Contact name: ' || rec.contact_name ||
            ' | Email: ' || rec.email ||
            ' | Supplier Contact No. 1: ' || rec.contact1 ||
            ' | Supplier Contact No. 2: ' || rec.contact2||
            ' | Total Orders: ' || rec.total_orders ||
            ' | Total Amount: ' || rec.total_amount
        );
    END LOOP;

END;


EXEC supplier_order_summary;

