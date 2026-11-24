# NovaBank — Three-Member Presentation Guide

A suggested 6–8 minute presentation plan. Replace generic roles with the members' actual names.

## Speaker split

| Speaker | Time | Present these parts | Preparation level |
|---|---:|---|---|
| Member 2 — Documentation and design | 1.5–2 min | Introduction, problem statement, objectives, scope, ER diagram and normalisation summary | No coding needed; understand the entities and relationships |
| Member 1 — Technical lead | 2.5–3 min | Oracle tables and constraints, sequences, PL/SQL package, triggers, row locking, transfer ledger and transaction commit | Strong technical understanding |
| Member 3 — Testing and presentation | 2–2.5 min | Dashboard tour, sample account creation, deposit/withdraw/transfer demo, test evidence, limitations, GitHub link and conclusion | Follow the run sheet and test checklist |

## Suggested slide sequence

1. **Title and team** — Bank Account Management System (NovaBank), course, guide and three members.
2. **Problem and objectives** — explain why a structured system is needed to manage account balances and transaction history.
3. **Scope and features** — opening accounts, deposit, withdrawal, transfer, freeze/reactivation and closure checks.
4. **ER diagram** — explain BANK_CUSTOMERS, BANK_ACCOUNTS, BANK_TRANSACTIONS and BANK_AUDIT_LOG and their one-to-many relationships.
5. **Oracle database implementation** — explain keys, constraints, sequences, indexes, views and triggers.
6. **PL/SQL transaction logic** — explain SELECT FOR UPDATE, positive-amount checks, sufficient balance checks and paired transfer entries.
7. **Dashboard demonstration** — show the account list, quick action forms, statuses and recent ledger activity.
8. **Testing and conclusion** — show the actual test output and screenshots from the Oracle-backed environment, then summarise limitations and future improvements.

## Live demonstration run sheet

Before the presentation:

- Confirm Oracle Database and the correct PDB are running.
- Confirm the application `.env` contains valid `BANKAPP` credentials and `DEMO_MODE=false`.
- Confirm the seed script has been run once.
- Run `database/05_test_suite.sql` and save the Script Output.
- Run `database/06_report_queries.sql` to prepare query outputs for the report.
- Start `run_windows.bat` and open `http://127.0.0.1:5000`.
- Use only fictional sample names and data.

During the demo:

1. Show the dashboard totals and customer directory.
2. Open a test account with a small opening balance.
3. Deposit ₹500 and show the balance change.
4. Withdraw ₹200 and show the new balance.
5. Transfer ₹100 to another active account and show both transfer ledger entries.
6. Freeze the account; attempt a money action and show the rejection.
7. Reactivate the account and show the audit log in SQL Developer.
8. Show `VW_TRANSACTION_HISTORY`, `VW_DASHBOARD_METRICS` and the safe account-closure rule (zero balance required).

## Simple explanations for non-coding members

- **Primary key:** a unique identifier for each row in a table.
- **Foreign key:** a link that ensures a related row exists in another table.
- **Sequence:** a database object that generates unique numbers.
- **Stored procedure:** a named PL/SQL routine that performs a database task.
- **Trigger:** a database routine that runs automatically when a specified event occurs.
- **View:** a saved query that presents data in a reusable way.
- **Transaction:** a unit of work that should complete together or be rolled back.

## Questions the group should be ready for

- Why do we store customer and account information in separate tables?
- Why is account balance constrained to be non-negative?
- What can happen if two users withdraw from the same account at the same time?
- Why does a transfer create two ledger rows?
- What happens when the application is in preview mode?
- Which screenshots and tests prove that the Oracle-backed implementation works?
