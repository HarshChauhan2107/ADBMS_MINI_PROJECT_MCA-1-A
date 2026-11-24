-- NovaBank | Illustrative sample data (run once after schema/package/views).
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

DECLARE
    v_count NUMBER;
    v_no1 VARCHAR2(20); v_no2 VARCHAR2(20); v_no3 VARCHAR2(20);
    v_no4 VARCHAR2(20); v_no5 VARCHAR2(20);
    v_customer NUMBER;
    v_ref VARCHAR2(24);
BEGIN
    SELECT COUNT(*) INTO v_count FROM bank_accounts;
    IF v_count = 0 THEN
        pkg_bank_ops.open_account('Aarav Mehta','aarav@example.test','9000000001','New Delhi','SAVINGS',25000,v_no1,v_customer);
        pkg_bank_ops.open_account('Ananya Sharma','ananya@example.test','9000000002','Gurugram','CURRENT',120000,v_no2,v_customer);
        pkg_bank_ops.open_account('Kabir Singh','kabir@example.test','9000000003','Faridabad','SAVINGS',8500,v_no3,v_customer);
        pkg_bank_ops.open_account('Riya Kapoor','riya@example.test','9000000004','Noida','SAVINGS',45300,v_no4,v_customer);
        pkg_bank_ops.open_account('Dev Malhotra','dev@example.test','9000000005','Delhi','CURRENT',78000,v_no5,v_customer);

        pkg_bank_ops.deposit(v_no1,3500,'Monthly savings top-up',v_ref);
        pkg_bank_ops.withdraw(v_no2,5000,'Office expenses',v_ref);
        pkg_bank_ops.transfer(v_no1,v_no3,1500,'Family transfer',v_ref);
        pkg_bank_ops.deposit(v_no4,2200,'Cash deposit',v_ref);
        pkg_bank_ops.transfer(v_no5,v_no2,7500,'Vendor settlement',v_ref);
        DBMS_OUTPUT.PUT_LINE('Demo data created. Sample account numbers:');
        DBMS_OUTPUT.PUT_LINE(v_no1 || ' | ' || v_no2 || ' | ' || v_no3 || ' | ' || v_no4 || ' | ' || v_no5);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Seed skipped: bank_accounts already contains data.');
    END IF;
    COMMIT;
END;
/
SELECT
    ACCOUNT_NO,
    FULL_NAME,
    ACCOUNT_TYPE,
    BALANCE,
    STATUS
FROM VW_BANK_ACCOUNTS;