-- NovaBank | Queries for the project demonstration, report and viva
-- Run as BANKAPP after install.sql and 04_seed_demo.sql.
SET LINESIZE 220;
SET PAGESIZE 100;

PROMPT === DASHBOARD METRICS ===
SELECT * FROM vw_dashboard_metrics;

PROMPT === ACCOUNT DIRECTORY ===
SELECT account_no, full_name, account_type, balance, status, opened_on
  FROM vw_bank_accounts
 ORDER BY account_no;

PROMPT === LEDGER ENTRIES ===
SELECT txn_ref, account_no, full_name, txn_type, amount, balance_after,
       description, related_account_no, created_at
  FROM vw_transaction_history
 ORDER BY created_at DESC, txn_id DESC;

PROMPT === ACCOUNT STATUS AUDIT ===
SELECT audit_id, account_id, old_status, new_status, changed_at, changed_by
  FROM bank_audit_log
 ORDER BY changed_at DESC, audit_id DESC;

PROMPT === TOTAL BALANCE CROSS-CHECK ===
SELECT SUM(balance) AS total_account_balance
  FROM bank_accounts
 WHERE status <> 'CLOSED';
