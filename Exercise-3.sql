-- Exercise 3
-- SQL Procedure to trigger a migration process


-- Sequences
CREATE SEQUENCE CONTACT_SEQ START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE ORDER_SEQ START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE ORDER_LINE_SEQ START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE INVOICE_SEQ START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE SUPPLIER_SEQ START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE ADDRESS_SEQ START WITH 1 INCREMENT BY 1;

SET SERVEROUTPUT ON;




CREATE OR REPLACE PROCEDURE MIGRATION IS

    V_SUPPLIER_ID             NUMBER;
    V_ADDRESS_ID              NUMBER;
    V_ORDER_ID                NUMBER;
    V_ORDER_LINE_ID           NUMBER;
    V_CONTACT_ID              NUMBER;  

    V_STREET_NO               VARCHAR2(255);
    V_STREET_NAME             VARCHAR2(100);
    V_REGION                  VARCHAR2(100);
    V_CITY                    VARCHAR2(20);
    V_COUNTRY                 VARCHAR2(100);

    V_ORDER_DATE              DATE;
    V_INVOICE_DATE            DATE;

    V_CLEANED_INVOICE_AMT     NUMBER(12, 2);
    V_CLEANED_ORDER_TOTAL_AMT NUMBER(12, 2);
    V_CLEANED_ORDER_LINE_AMT  NUMBER(12, 2);
    V_AMOUNT                  VARCHAR2(100);
BEGIN


    FOR REC IN (
        SELECT
            *
        FROM
            XXBCM_ORDER_MGT
    ) LOOP

 -- Extract address 
        V_STREET_NO := SUBSTR(REC.SUPP_ADDRESS,
                              1,
                              INSTR(REC.SUPP_ADDRESS, ',', 1, 1) - 1);

        V_STREET_NAME := SUBSTR(REC.SUPP_ADDRESS,
                                INSTR(REC.SUPP_ADDRESS, ',', 1, 1) + 2,
                                INSTR(REC.SUPP_ADDRESS, ',', 1, 2) - INSTR(REC.SUPP_ADDRESS, ',', 1, 1) - 2);

        V_REGION := SUBSTR(REC.SUPP_ADDRESS,
                           INSTR(REC.SUPP_ADDRESS, ',', 1, 2) + 2,
                           INSTR(REC.SUPP_ADDRESS, ',', 1, 3) - INSTR(REC.SUPP_ADDRESS, ',', 1, 2) - 2);

        V_CITY := SUBSTR(REC.SUPP_ADDRESS,
                         INSTR(REC.SUPP_ADDRESS, ',', 1, 3) + 2,
                         INSTR(REC.SUPP_ADDRESS, ',', 1, 4) - INSTR(REC.SUPP_ADDRESS, ',', 1, 3) - 2);

        V_COUNTRY := SUBSTR(REC.SUPP_ADDRESS,
                            INSTR(REC.SUPP_ADDRESS, ',', -1) + 2);

        

  -- Insert into Suppliers Table
        INSERT INTO SUPPLIERS (
            SUPPLIER_ID,
            SUPPLIER_NAME,
            CONTACT_NAME,
            EMAIL
        ) VALUES ( SUPPLIER_SEQ.NEXTVAL,
                   REC.SUPPLIER_NAME,
                   REC.SUPP_CONTACT_NAME,
                   REC.SUPP_EMAIL ) RETURNING SUPPLIER_ID INTO V_SUPPLIER_ID;


        -- Insert supplier address
        INSERT INTO SUPP_ADDRESS (
            ADDRESS_ID,
            SUPPLIER_ID,
            STREET_NO,
            STREET_NAME,
            REGION,
            CITY,
            COUNTRY
        ) VALUES ( ADDRESS_SEQ.NEXTVAL,
                   V_SUPPLIER_ID,
                   V_STREET_NO,
                   V_STREET_NAME,
                   V_REGION,
                   V_CITY,
                   V_COUNTRY ) RETURNING ADDRESS_ID INTO V_ADDRESS_ID;

        -- Insert supplier contacts
        INSERT INTO SUPP_CONTACTS (
            CONTACT_ID,
            CONTACT_NUMBER,
            SUPPLIER_ID
        ) VALUES ( CONTACT_SEQ.NEXTVAL,
                   REC.SUPP_CONTACT_NUMBER,
                   V_SUPPLIER_ID ) RETURNING CONTACT_ID INTO V_CONTACT_ID;


-- INVOICES
        V_AMOUNT := NVL(
            UPPER(REC.INVOICE_AMOUNT),
            0
        );
        V_CLEANED_INVOICE_AMT := TO_NUMBER ( REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(V_AMOUNT, 'I', 1),
                    'S',
                    '5'
                ),
                'O',
                '0'
            ),
            ',',
            '.'
        ) );

    -- ORDER LINE AMOUNT
        V_AMOUNT := NVL(
            UPPER(REC.ORDER_LINE_AMOUNT),
            0
        );
        V_CLEANED_ORDER_LINE_AMT := TO_NUMBER ( REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(V_AMOUNT, 'I', 1),
                    'S',
                    '5'
                ),
                'O',
                '0'
            ),
            ',',
            '.'
        ) );

        -- ORDER TOTAL AMOUNT
        V_AMOUNT := NVL(
            UPPER(REC.ORDER_TOTAL_AMOUNT),
            0
        );
        V_CLEANED_ORDER_TOTAL_AMT := TO_NUMBER ( REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(V_AMOUNT, 'I', 1),
                    'S',
                    '5'
                ),
                'O',
                '0'
            ),
            ',',
            '.'
        ) );

        V_ORDER_DATE := TO_DATE ( REC.ORDER_DATE, 'DD-MM-YYYY' );
        DBMS_OUTPUT.PUT_LINE(V_ORDER_DATE);
 -- Insert into Orders Table
        INSERT INTO ORDERS (
            ORDER_ID,
            ORDER_REF,
            ORDER_DATE,
            TOTAL_AMOUNT,
            ORDER_STATUS,
            SUPPLIER_ID
        ) VALUES ( ORDER_SEQ.NEXTVAL,
                   REC.ORDER_REF,
                   V_ORDER_DATE,
                   NVL(V_CLEANED_ORDER_TOTAL_AMT, 0),
                   REC.ORDER_STATUS,
                   V_SUPPLIER_ID ) RETURNING ORDER_ID INTO V_ORDER_ID;

-- Insert into Order_Lines Table
        INSERT INTO ORDER_LINES (
            ORDER_LINE_ID,
            ORDER_ID,
            ORDER_LINE_AMT,
            ORDER_DESC
        ) VALUES ( ORDER_LINE_SEQ.NEXTVAL,
                   V_ORDER_ID,
                   V_CLEANED_ORDER_LINE_AMT, 
                   REC.ORDER_DESCRIPTION ) RETURNING ORDER_LINE_ID INTO V_ORDER_LINE_ID;

        IF rec.INVOICE_DATE IS NULL 
        THEN
        V_INVOICE_DATE := SYSDATE;
        ELSE
        V_INVOICE_DATE := TO_DATE ( REC.INVOICE_DATE, 'DD-MM-YYYY' );
END IF;
        INSERT INTO INVOICES (
            INVOICE_ID,
            ORDER_ID,
            ORDER_LINE_ID,
            INVOICE_REF,
            INVOICE_DATE,
            INVOICE_STATUS,
            HOLD_REASON,
            INVOICE_AMT,
            INVOICE_DESC
        ) VALUES ( INVOICE_SEQ.NEXTVAL,
                   V_ORDER_ID,
                   V_ORDER_LINE_ID,
                   REC.INVOICE_REFERENCE,
                   V_INVOICE_DATE,  
                   REC.INVOICE_STATUS,
                   REC.INVOICE_HOLD_REASON,
                   V_CLEANED_INVOICE_AMT,
                   REC.INVOICE_DESCRIPTION );

    END LOOP;

    COMMIT;
END;
/

EXEC migration;
