-- NovaBank | Reporting views
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

CREATE OR REPLACE VIEW vw_bank_accounts AS
SELECT a.account_id, a.account_no, c.customer_id, c.full_name,
       c.email, c.phone, c.address, a.account_type, a.balance,
       a.status, a.opened_on, a.created_at, a.updated_at
  FROM bank_accounts a
  JOIN bank_customers c ON c.customer_id = a.customer_id;

CREATE OR REPLACE VIEW vw_transaction_history AS
SELECT t.txn_id, t.txn_ref, a.account_no, c.full_name,
       t.txn_type, t.amount, t.balance_after, t.description,
       t.related_account_no, t.created_at
  FROM bank_transactions t
  JOIN bank_accounts a ON a.account_id = t.account_id
  JOIN bank_customers c ON c.customer_id = a.customer_id;

CREATE OR REPLACE VIEW vw_dashboard_metrics AS
SELECT (SELECT COUNT(*) FROM bank_accounts WHERE status <> 'CLOSED') AS total_accounts,
       (SELECT COUNT(DISTINCT customer_id) FROM bank_accounts WHERE status <> 'CLOSED') AS total_customers,
       (SELECT NVL(SUM(balance),0) FROM bank_accounts WHERE status <> 'CLOSED') AS total_balance,
       (SELECT COUNT(*) FROM bank_transactions
         WHERE created_at >= CAST(TRUNC(SYSDATE) AS TIMESTAMP)) AS transactions_today,
       (SELECT COUNT(*) FROM bank_accounts WHERE status = 'FROZEN') AS frozen_accounts
  FROM dual;

PROMPT Reporting views created successfully.
