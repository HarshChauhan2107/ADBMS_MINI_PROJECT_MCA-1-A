# NovaBank — Expected sample results

These reference values are calculated from the five fictional records and package calls in `database/04_seed_demo.sql`. They are **expected outputs**, not evidence that Oracle was executed on your computer. Your own SQL Developer results and screenshots should be used in the final submission.

## Account directory after a clean seed

| Account number | Account holder | Type | Expected balance | Status |
|---|---|---|---:|---|
| NB0100000001 | Aarav Mehta | SAVINGS | ₹27,000.00 | ACTIVE |
| NB0100000002 | Ananya Sharma | CURRENT | ₹1,22,500.00 | ACTIVE |
| NB0100000003 | Kabir Singh | SAVINGS | ₹10,000.00 | ACTIVE |
| NB0100000004 | Riya Kapoor | SAVINGS | ₹47,500.00 | ACTIVE |
| NB0100000005 | Dev Malhotra | CURRENT | ₹70,500.00 | ACTIVE |
| | **Total** | | **₹2,77,500.00** | |

Riya Kapoor's account is set to `FROZEN` only in the dashboard preview store. The Oracle seed script does not freeze an account, so all five Oracle-seeded accounts are `ACTIVE` unless your group changes one during testing.

## Expected ledger metrics

- Opening entries: 5
- Further ledger entries: 7, including two rows for each transfer
- Total ledger rows: 12
- Total amount represented by all ledger rows: ₹3,05,500.00 (transfer debit and credit rows are both counted in this display metric)
- Total live account balance: ₹2,77,500.00

## Expected PL/SQL test suite output

After running `database/05_test_suite.sql`, the block should print PASS messages for account opening, deposit, withdrawal, paired transfer, insufficient-funds rejection, non-zero-balance closure rejection, zero-balance closure and audit logging. The script rolls back its temporary test data at the end. Review SQL Developer's Script Output for compilation or runtime errors.

## Screenshot capture suggestions

1. `SELECT * FROM vw_dashboard_metrics;`
2. Account directory query result.
3. Latest `vw_transaction_history` rows showing both sides of a transfer.
4. `05_test_suite.sql` Script Output with all PASS lines.
5. Live dashboard after setting `DEMO_MODE=false` and connecting to Oracle.

The screenshots currently in `screenshots/` are labelled illustrative preview-mode interface views. Replace or supplement them with your own Oracle-backed evidence before academic submission.
