-- NovaBank | Business logic package
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

CREATE OR REPLACE PACKAGE pkg_bank_ops AS
    PROCEDURE open_account(
        p_full_name       IN  VARCHAR2,
        p_email           IN  VARCHAR2,
        p_phone           IN  VARCHAR2,
        p_address         IN  VARCHAR2,
        p_account_type    IN  VARCHAR2,
        p_opening_balance IN  NUMBER,
        p_account_no      OUT VARCHAR2,
        p_customer_id     OUT NUMBER
    );

    PROCEDURE deposit(
        p_account_no IN VARCHAR2,
        p_amount     IN NUMBER,
        p_description IN VARCHAR2,
        p_txn_ref    OUT VARCHAR2
    );

    PROCEDURE withdraw(
        p_account_no IN VARCHAR2,
        p_amount     IN NUMBER,
        p_description IN VARCHAR2,
        p_txn_ref    OUT VARCHAR2
    );

    PROCEDURE transfer(
        p_from_account IN VARCHAR2,
        p_to_account   IN VARCHAR2,
        p_amount       IN NUMBER,
        p_description  IN VARCHAR2,
        p_txn_ref      OUT VARCHAR2
    );

    PROCEDURE set_account_status(
        p_account_no IN VARCHAR2,
        p_new_status IN VARCHAR2
    );

    PROCEDURE close_account(p_account_no IN VARCHAR2);
END pkg_bank_ops;
/

CREATE OR REPLACE PACKAGE BODY pkg_bank_ops AS

    PROCEDURE validate_amount(p_amount IN NUMBER) IS
    BEGIN
        IF p_amount IS NULL OR p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Amount must be greater than zero.');
        END IF;
    END validate_amount;

    PROCEDURE write_transaction(
        p_account_id         IN  NUMBER,
        p_txn_type           IN  VARCHAR2,
        p_amount             IN  NUMBER,
        p_balance_after      IN  NUMBER,
        p_description        IN  VARCHAR2,
        p_related_account_no IN  VARCHAR2,
        p_txn_ref            OUT VARCHAR2
    ) IS
    BEGIN
        p_txn_ref := 'TXN' || LPAD(seq_bank_txn_ref.NEXTVAL, 12, '0');
        INSERT INTO bank_transactions (
            txn_ref, account_id, txn_type, amount, balance_after,
            description, related_account_no
        ) VALUES (
            p_txn_ref, p_account_id, p_txn_type, ROUND(p_amount,2),
            ROUND(p_balance_after,2), SUBSTR(p_description,1,250),
            p_related_account_no
        );
    END write_transaction;

    PROCEDURE open_account(
        p_full_name       IN  VARCHAR2,
        p_email           IN  VARCHAR2,
        p_phone           IN  VARCHAR2,
        p_address         IN  VARCHAR2,
        p_account_type    IN  VARCHAR2,
        p_opening_balance IN  NUMBER,
        p_account_no      OUT VARCHAR2,
        p_customer_id     OUT NUMBER
    ) IS
        v_account_id NUMBER;
        v_opening    NUMBER := NVL(p_opening_balance,0);
        v_txn_ref    VARCHAR2(24);
        v_type       VARCHAR2(12) := UPPER(TRIM(p_account_type));
    BEGIN
        IF p_full_name IS NULL OR LENGTH(TRIM(p_full_name)) < 2 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Enter a valid customer name.');
        END IF;
        IF v_type NOT IN ('SAVINGS','CURRENT') THEN
            RAISE_APPLICATION_ERROR(-20003, 'Account type must be SAVINGS or CURRENT.');
        END IF;
        IF v_opening < 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Opening balance cannot be negative.');
        END IF;

        INSERT INTO bank_customers(full_name, email, phone, address)
        VALUES (TRIM(p_full_name), TRIM(p_email), TRIM(p_phone), TRIM(p_address))
        RETURNING customer_id INTO p_customer_id;

        p_account_no := 'NB' || LPAD(seq_bank_account_no.NEXTVAL, 10, '0');
        INSERT INTO bank_accounts(account_no, customer_id, account_type, balance)
        VALUES (p_account_no, p_customer_id, v_type, 0)
        RETURNING account_id INTO v_account_id;

        IF v_opening > 0 THEN
            UPDATE bank_accounts SET balance = ROUND(v_opening,2)
            WHERE account_id = v_account_id;
            write_transaction(v_account_id, 'OPENING', v_opening, v_opening,
                'Initial account funding', NULL, v_txn_ref);
        END IF;
    END open_account;

    PROCEDURE deposit(
        p_account_no IN VARCHAR2,
        p_amount     IN NUMBER,
        p_description IN VARCHAR2,
        p_txn_ref    OUT VARCHAR2
    ) IS
        v_account_id NUMBER;
        v_balance    NUMBER;
        v_status     VARCHAR2(10);
        v_new_balance NUMBER;
    BEGIN
        validate_amount(p_amount);
        SELECT account_id, balance, status
          INTO v_account_id, v_balance, v_status
          FROM bank_accounts
         WHERE account_no = UPPER(TRIM(p_account_no))
         FOR UPDATE;

        IF v_status <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20005, 'Only active accounts can receive deposits.');
        END IF;
        v_new_balance := ROUND(v_balance + p_amount,2);
        UPDATE bank_accounts SET balance = v_new_balance WHERE account_id = v_account_id;
        write_transaction(v_account_id, 'DEPOSIT', p_amount, v_new_balance,
            NVL(p_description,'Cash deposit'), NULL, p_txn_ref);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Account number not found.');
    END deposit;

    PROCEDURE withdraw(
        p_account_no IN VARCHAR2,
        p_amount     IN NUMBER,
        p_description IN VARCHAR2,
        p_txn_ref    OUT VARCHAR2
    ) IS
        v_account_id NUMBER;
        v_balance    NUMBER;
        v_status     VARCHAR2(10);
        v_new_balance NUMBER;
    BEGIN
        validate_amount(p_amount);
        SELECT account_id, balance, status
          INTO v_account_id, v_balance, v_status
          FROM bank_accounts
         WHERE account_no = UPPER(TRIM(p_account_no))
         FOR UPDATE;

        IF v_status <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20007, 'Only active accounts can make withdrawals.');
        END IF;
        IF v_balance < p_amount THEN
            RAISE_APPLICATION_ERROR(-20008, 'Insufficient balance.');
        END IF;
        v_new_balance := ROUND(v_balance - p_amount,2);
        UPDATE bank_accounts SET balance = v_new_balance WHERE account_id = v_account_id;
        write_transaction(v_account_id, 'WITHDRAWAL', p_amount, v_new_balance,
            NVL(p_description,'Cash withdrawal'), NULL, p_txn_ref);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20009, 'Account number not found.');
    END withdraw;

    PROCEDURE transfer(
        p_from_account IN VARCHAR2,
        p_to_account   IN VARCHAR2,
        p_amount       IN NUMBER,
        p_description  IN VARCHAR2,
        p_txn_ref      OUT VARCHAR2
    ) IS
        v_from_id       NUMBER;
        v_to_id         NUMBER;
        v_first_id      NUMBER;
        v_second_id     NUMBER;
        v_from_balance  NUMBER;
        v_to_balance    NUMBER;
        v_from_status   VARCHAR2(10);
        v_to_status     VARCHAR2(10);
        v_dummy_balance NUMBER;
        v_dummy_status  VARCHAR2(10);
        v_out_ref       VARCHAR2(24);
        v_in_ref        VARCHAR2(24);
        v_from_new      NUMBER;
        v_to_new        NUMBER;
        v_from_no       VARCHAR2(20) := UPPER(TRIM(p_from_account));
        v_to_no         VARCHAR2(20) := UPPER(TRIM(p_to_account));
    BEGIN
        validate_amount(p_amount);
        IF v_from_no = v_to_no THEN
            RAISE_APPLICATION_ERROR(-20010, 'Source and destination accounts must be different.');
        END IF;

        BEGIN
            SELECT account_id INTO v_from_id FROM bank_accounts WHERE account_no = v_from_no;
            SELECT account_id INTO v_to_id FROM bank_accounts WHERE account_no = v_to_no;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20011, 'Source or destination account was not found.');
        END;

        -- Lock in account_id order to reduce deadlock risk for concurrent transfers.
        v_first_id := LEAST(v_from_id, v_to_id);
        v_second_id := GREATEST(v_from_id, v_to_id);
        SELECT balance, status INTO v_dummy_balance, v_dummy_status
          FROM bank_accounts WHERE account_id = v_first_id FOR UPDATE;
        SELECT balance, status INTO v_dummy_balance, v_dummy_status
          FROM bank_accounts WHERE account_id = v_second_id FOR UPDATE;

        SELECT balance, status INTO v_from_balance, v_from_status
          FROM bank_accounts WHERE account_id = v_from_id;
        SELECT balance, status INTO v_to_balance, v_to_status
          FROM bank_accounts WHERE account_id = v_to_id;

        IF v_from_status <> 'ACTIVE' OR v_to_status <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20012, 'Both accounts must be active to transfer funds.');
        END IF;
        IF v_from_balance < p_amount THEN
            RAISE_APPLICATION_ERROR(-20013, 'Insufficient balance for transfer.');
        END IF;

        v_from_new := ROUND(v_from_balance - p_amount,2);
        v_to_new := ROUND(v_to_balance + p_amount,2);
        UPDATE bank_accounts SET balance = v_from_new WHERE account_id = v_from_id;
        UPDATE bank_accounts SET balance = v_to_new WHERE account_id = v_to_id;

        write_transaction(v_from_id, 'TRANSFER_OUT', p_amount, v_from_new,
            NVL(p_description,'Account transfer'), v_to_no, v_out_ref);
        write_transaction(v_to_id, 'TRANSFER_IN', p_amount, v_to_new,
            NVL(p_description,'Account transfer'), v_from_no, v_in_ref);
        p_txn_ref := v_out_ref;
    END transfer;

    PROCEDURE set_account_status(
        p_account_no IN VARCHAR2,
        p_new_status IN VARCHAR2
    ) IS
        v_status VARCHAR2(10) := UPPER(TRIM(p_new_status));
    BEGIN
        IF v_status NOT IN ('ACTIVE','FROZEN') THEN
            RAISE_APPLICATION_ERROR(-20014, 'Status can only be changed to ACTIVE or FROZEN.');
        END IF;
        UPDATE bank_accounts
           SET status = v_status
         WHERE account_no = UPPER(TRIM(p_account_no))
           AND status <> 'CLOSED';
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20015, 'Account not found or already closed.');
        END IF;
    END set_account_status;

    PROCEDURE close_account(p_account_no IN VARCHAR2) IS
        v_balance NUMBER;
        v_status VARCHAR2(10);
    BEGIN
        SELECT balance, status INTO v_balance, v_status
          FROM bank_accounts
         WHERE account_no = UPPER(TRIM(p_account_no))
         FOR UPDATE;
        IF v_status = 'CLOSED' THEN
            RAISE_APPLICATION_ERROR(-20016, 'Account is already closed.');
        END IF;
        IF v_balance <> 0 THEN
            RAISE_APPLICATION_ERROR(-20017, 'Transfer or withdraw the remaining balance before closing the account.');
        END IF;
        UPDATE bank_accounts SET status = 'CLOSED'
         WHERE account_no = UPPER(TRIM(p_account_no));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20018, 'Account number not found.');
    END close_account;
END pkg_bank_ops;
/

SHOW ERRORS PACKAGE pkg_bank_ops;
SHOW ERRORS PACKAGE BODY pkg_bank_ops;
PROMPT PL/SQL package compiled. Review SHOW ERRORS output before proceeding.
