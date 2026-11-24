-- NovaBank | Smoke / business-rule tests
-- Run as BANKAPP after installing the schema and package.
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

DECLARE
    v_source VARCHAR2(20);
    v_target VARCHAR2(20);
    v_customer NUMBER;
    v_ref VARCHAR2(24);
    v_balance NUMBER;
    v_audit_count NUMBER;
    v_status VARCHAR2(10);
    v_failed BOOLEAN := FALSE;
BEGIN
    pkg_bank_ops.open_account('Test Source','source@example.test','9111111111','Test address','SAVINGS',10000,v_source,v_customer);
    pkg_bank_ops.open_account('Test Target','target@example.test','9222222222','Test address','CURRENT',5000,v_target,v_customer);

    pkg_bank_ops.deposit(v_source,2500,'Test deposit',v_ref);
    SELECT balance INTO v_balance FROM bank_accounts WHERE account_no = v_source;
    IF v_balance <> 12500 THEN RAISE_APPLICATION_ERROR(-20991,'Deposit test failed.'); END IF;

    pkg_bank_ops.withdraw(v_source,1500,'Test withdrawal',v_ref);
    SELECT balance INTO v_balance FROM bank_accounts WHERE account_no = v_source;
    IF v_balance <> 11000 THEN RAISE_APPLICATION_ERROR(-20992,'Withdrawal test failed.'); END IF;

    pkg_bank_ops.transfer(v_source,v_target,2000,'Test transfer',v_ref);
    SELECT balance INTO v_balance FROM bank_accounts WHERE account_no = v_source;
    IF v_balance <> 9000 THEN RAISE_APPLICATION_ERROR(-20993,'Transfer debit test failed.'); END IF;
    SELECT balance INTO v_balance FROM bank_accounts WHERE account_no = v_target;
    IF v_balance <> 7000 THEN RAISE_APPLICATION_ERROR(-20994,'Transfer credit test failed.'); END IF;

    -- The following operation must be rejected for insufficient funds.
    BEGIN
        pkg_bank_ops.withdraw(v_source,999999,'Expected rejection',v_ref);
        v_failed := TRUE;
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE NOT IN (-20008) THEN RAISE; END IF;
    END;
    IF v_failed THEN RAISE_APPLICATION_ERROR(-20995,'Insufficient-funds rule was not enforced.'); END IF;

    -- A non-zero account must not be closed.
    v_failed := FALSE;
    BEGIN
        pkg_bank_ops.close_account(v_source);
        v_failed := TRUE;
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20017 THEN RAISE; END IF;
    END;
    IF v_failed THEN RAISE_APPLICATION_ERROR(-20996,'Non-zero account was incorrectly closed.'); END IF;

    -- Empty the account, close it, and verify the audit trigger recorded the change.
    pkg_bank_ops.withdraw(v_source,9000,'Final balance clearance',v_ref);
    pkg_bank_ops.close_account(v_source);
    SELECT status, account_id INTO v_status, v_customer
      FROM bank_accounts WHERE account_no = v_source;
    IF v_status <> 'CLOSED' THEN RAISE_APPLICATION_ERROR(-20997,'Zero-balance account close test failed.'); END IF;
    SELECT COUNT(*) INTO v_audit_count FROM bank_audit_log
     WHERE account_id = v_customer AND old_status = 'ACTIVE' AND new_status = 'CLOSED';
    IF v_audit_count <> 1 THEN RAISE_APPLICATION_ERROR(-20998,'Account close audit entry was not written.'); END IF;

    DBMS_OUTPUT.PUT_LINE('PASS: account opening and initial funding');
    DBMS_OUTPUT.PUT_LINE('PASS: deposit updates account balance');
    DBMS_OUTPUT.PUT_LINE('PASS: withdrawal updates account balance');
    DBMS_OUTPUT.PUT_LINE('PASS: transfer debits source and credits destination');
    DBMS_OUTPUT.PUT_LINE('PASS: insufficient-funds withdrawal is rejected');
    DBMS_OUTPUT.PUT_LINE('PASS: non-zero account closure is rejected');
    DBMS_OUTPUT.PUT_LINE('PASS: zero-balance account closure and audit logging');
    DBMS_OUTPUT.PUT_LINE('TEST ACCOUNT NUMBERS: ' || v_source || ' / ' || v_target);
    ROLLBACK; -- Test accounts and transactions are removed after successful test.
END;
/
