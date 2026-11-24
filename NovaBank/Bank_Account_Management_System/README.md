# NovaBank — Bank Account Management System (ADBMS Mini Project)

A university-level Advanced Database Management Systems mini project using **Oracle SQL, PL/SQL, Python Flask and a responsive web interface**. The database is the system of record; the web layer calls the stored PL/SQL package rather than updating account balances with ad-hoc SQL.

> **Educational use only.** This project is a classroom prototype. It is not a production banking system and must never be used with real customer or financial data.

## 1. What the project does

- Register a customer and open a Savings or Current account.
- Generate a unique bank account number using an Oracle sequence.
- Deposit and withdraw money with positive-amount, active-account and sufficient-balance checks.
- Transfer money between two accounts as one database transaction, with a debit entry and a matching credit entry.
- Freeze/reactivate an account; account-status changes are captured in an audit table.
- Close an account only when its balance is zero (available from the account actions menu).
- Display account summaries, dashboard metrics and recent transaction history.
- Preserve transaction history as an append-only ledger.

## 2. Technology stack

| Layer | Technology | Purpose |
|---|---|---|
| Database | Oracle Database 19c+ / XE / Free | Relational storage, constraints, sequences, indexes and transactions |
| Business logic | PL/SQL package `PKG_BANK_OPS` | Validated and reusable account operations |
| Reporting | Oracle views | Dashboard, account list and transaction history |
| Web bridge | Python 3.10+ and Flask | HTTP API and Oracle connectivity |
| Oracle driver | python-oracledb (Thin mode) | Connect Python to Oracle without a separate Oracle Client install |
| User interface | HTML, CSS and JavaScript | Responsive, colourful dashboard and operation forms |

## 3. Project structure

```text
Bank_Account_Management_System/
├── database/
│   ├── 01_schema.sql          # Tables, constraints, sequences, indexes, triggers
│   ├── 02_package.sql         # PKG_BANK_OPS specification and body
│   ├── 03_views.sql           # Reporting views
│   ├── 04_seed_demo.sql       # Illustrative sample records
│   ├── 05_test_suite.sql      # PL/SQL smoke and business-rule tests
│   ├── 06_report_queries.sql  # Queries for screenshots and viva demonstration
│   └── install.sql            # Main installation script
├── backend/
│   ├── app.py                 # Flask routes and Oracle package integration
│   └── demo_store.py          # Temporary in-memory preview only
├── templates/index.html      # Dashboard layout and forms container
├── static/css/styles.css     # Theme, responsive layout and components
├── static/js/app.js          # Dashboard behaviour and API calls
├── docs/                     # Report, source appendix, test and presentation guides
├── screenshots/              # Illustrative dashboard and form preview images
├── .env.example              # Oracle connection template
├── requirements.txt
└── run_windows.bat            # Windows setup/launch helper
```

## 4. Requirements

1. Windows 10/11 (the included launcher is for Windows).
2. Python 3.10 or later.
3. Oracle Database 19c or later, Oracle Database Express Edition, or Oracle Database Free with a pluggable database available.
4. Oracle SQL Developer or SQLcl/SQL*Plus to run the database scripts.
5. A browser such as Chrome or Edge.

The Python Oracle driver uses Thin mode by default, so a separate Oracle Instant Client is normally not required for this project.

## 5. Database setup

### Step A — Create the project schema user

Open SQL Developer and connect to your local PDB service as `SYSTEM` (use the service name for your installation). Run the following once, changing the password to one of your own:

```sql
CREATE USER BANKAPP IDENTIFIED BY "Choose_A_Strong_Password_123";
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE TO BANKAPP;
ALTER USER BANKAPP QUOTA UNLIMITED ON USERS;
```

For Oracle Database Free the local PDB service is commonly `FREEPDB1`; for older XE installations it is commonly `XEPDB1`. Confirm the service name displayed by your own Oracle installation before connecting.

### Step B — Install tables and PL/SQL

1. Connect to the PDB as `BANKAPP`.
2. Open `database/install.sql` in SQL Developer.
3. Set the SQL Developer working directory to the `database` folder (or run the scripts from that folder using SQLcl).
4. Use **Run Script (F5)**, not the single-statement Run button.
5. Review the Script Output for `PL/SQL package compiled` and confirm there are no `SHOW ERRORS` messages.
6. Run `database/04_seed_demo.sql` to add five illustrative accounts and sample transactions.
7. Optional: run `database/05_test_suite.sql`. The test block prints PASS lines and rolls its test records back at the end.

To inspect the created objects, run:

```sql
SELECT object_name, object_type, status
FROM user_objects
ORDER BY object_type, object_name;

SELECT * FROM vw_dashboard_metrics;
SELECT account_no, full_name, account_type, balance, status
FROM vw_bank_accounts ORDER BY account_no;
```

## 6. Run the web dashboard on Windows

1. Copy `.env.example` and name the copy `.env` (the Windows launcher creates the copy if it does not exist).
2. Edit `.env` and set the password and service name for your `BANKAPP` Oracle user. Example:

```dotenv
ORACLE_USER=BANKAPP
ORACLE_PASSWORD=your_actual_password
ORACLE_DSN=localhost:1521/FREEPDB1
DEMO_MODE=false
```

3. Double-click `run_windows.bat`, or open Command Prompt in the project folder and run it.
4. The script creates a virtual environment, installs dependencies and starts Flask.
5. Open `http://127.0.0.1:5000` in Chrome or Edge.

The server is local to your computer. Keep the terminal open while using the dashboard; press `Ctrl+C` to stop it.

### Preview before Oracle is ready

Set `DEMO_MODE=true` in `.env`, save and restart `run_windows.bat`. This starts an in-memory sample dataset so the interface and forms can be explored. It is **not Oracle storage**: preview changes reset when the Python server restarts. Change it back to `false` for the assessed Oracle-backed project.

## 7. Suggested demonstration sequence

1. Show the dashboard totals and sample customer accounts.
2. Open a new Savings account with a small opening balance; point out the database-generated account number.
3. Deposit ₹500 into that account and show the new balance.
4. Withdraw ₹200 and show the balance adjustment.
5. Transfer ₹100 to another active account; show that the source is debited and the destination is credited.
6. Freeze the account and demonstrate that a money operation is rejected.
7. Reactivate the account and show the latest transaction entries.
8. In SQL Developer, display `BANK_TRANSACTIONS`, `BANK_AUDIT_LOG` and the reporting views.

Use fictional names and data only. Do not enter real bank details or personal information.

## 8. Database design summary

| Table | Main purpose | Key relationships |
|---|---|---|
| `BANK_CUSTOMERS` | Customer identity and contact details | One customer can own multiple accounts |
| `BANK_ACCOUNTS` | Account number, type, status and current balance | Many accounts belong to one customer |
| `BANK_TRANSACTIONS` | Immutable financial activity ledger | Each transaction belongs to one account |
| `BANK_AUDIT_LOG` | Records account status changes | Each audit entry references an account |

**Views:** `VW_BANK_ACCOUNTS`, `VW_TRANSACTION_HISTORY`, `VW_DASHBOARD_METRICS`.

**Sequences:** `SEQ_BANK_ACCOUNT_NO`, `SEQ_BANK_TXN_REF`.

**Triggers:** `TRG_BANK_ACCOUNTS_BU` updates the timestamp and logs a status change; `TRG_BANK_TXN_IMMUTABLE` prevents modification or deletion of ledger rows.

**PL/SQL package:** `PKG_BANK_OPS` contains `OPEN_ACCOUNT`, `DEPOSIT`, `WITHDRAW`, `TRANSFER`, `SET_ACCOUNT_STATUS` and `CLOSE_ACCOUNT`.

## 9. Three-member work distribution

This allocation deliberately gives the two members with limited coding experience meaningful ownership without asking them to write complex PL/SQL.

| Member | Primary role | Assigned work | Coding load |
|---|---|---|---|
| Member 1 — Technical lead | Database and integration | Create Oracle user; run and explain schema scripts; explain package, constraints, triggers and transactions; connect Flask to Oracle; fix technical issues | High |
| Member 2 — Documentation and design | Report and database documentation | Prepare abstract, objectives, scope, requirement analysis, ER diagram, data dictionary, screenshots with captions, conclusion and bibliography; verify names and formatting in report | Low / no coding |
| Member 3 — Testing and presentation | Test coordinator and demo presenter | Follow run instructions; execute seed and test scripts; record PASS output; test the interface with the test checklist; prepare slide/demo flow; add screenshots and repository link; maintain contribution log | Low / no coding |

**Fair contribution evidence:** each member should keep a dated activity log, attend project discussions, understand their own section and be able to explain at least the basic project flow. Members 2 and 3 should learn the meaning of primary key, foreign key, stored procedure, trigger, transaction and view, even though they are not expected to write them.

### Recommended work schedule

| Phase | Member 1 | Member 2 | Member 3 |
|---|---|---|---|
| Requirements | Confirm technical scope and database needs | Draft problem statement and objectives | Prepare user workflow and feature checklist |
| Design | Create tables, relationships and package plan | Draw ER diagram and data dictionary | Prepare test cases and sample data sheet |
| Build | Implement SQL/PLSQL and integration | Organise report and screenshots | Run supplied scripts and report issues |
| Test | Fix database/integration defects | Proofread report against actual features | Execute checklist and record results |
| Submission | Explain database logic | Finalise project report | Prepare demo, repository structure and presentation |

Replace the generic member labels with the actual group members' names and roll numbers before submission.

## 10. Testing checklist

| Test ID | Action | Expected result |
|---|---|---|
| TC-01 | Open an account with a valid customer name | A unique account number is generated |
| TC-02 | Open an account with a negative opening balance | Rejected with a validation error |
| TC-03 | Deposit a positive amount into an active account | Balance increases and a DEPOSIT row is written |
| TC-04 | Withdraw an amount within available balance | Balance decreases and a WITHDRAWAL row is written |
| TC-05 | Withdraw more than the available balance | Rejected; balance remains unchanged |
| TC-06 | Transfer between two active accounts | Source decreases, destination increases and paired rows are written |
| TC-07 | Transfer to the same account | Rejected |
| TC-08 | Freeze an account and attempt a deposit/withdrawal | Money operation is rejected |
| TC-09 | Reactivate a frozen account | Account status becomes ACTIVE |
| TC-10 | Close an account with a non-zero balance | Rejected |
| TC-11 | Change an account status | A row is added to BANK_AUDIT_LOG |
| TC-12 | Update/delete a transaction row directly | Trigger rejects the change |

Record the actual result, date, tester and screenshot name for each of the 13 cases in the report before submission. Run `database/06_report_queries.sql` to prepare account, ledger and audit evidence for the report and viva.

## 11. Transaction and integrity decisions

- Foreign keys preserve customer-account and account-transaction relationships.
- Check constraints limit account types, statuses, non-negative balances and positive transaction amounts.
- `SELECT ... FOR UPDATE` locks accounts while deposit, withdrawal and transfer logic is executed.
- Transfers lock accounts in ascending internal account ID order to reduce deadlock risk.
- The Flask layer commits only after the PL/SQL call succeeds; failed calls return an error and do not intentionally commit partial changes.
- Ledger rows are append-only in this educational model. A correction should be represented by a compensating transaction rather than rewriting history.
- The demo mode is strictly in-memory and does not replace the Oracle database implementation.

## 12. Limitations and future improvements

This classroom prototype omits real authentication/authorisation, encryption key management, regulatory controls, payment network integration, interest accrual, KYC workflows, cheque clearing, loan services, rate limiting and production monitoring. Before any real-world use, the application would need a security review, audited access control, secure secret management, tested backup/recovery, operational monitoring and compliance approval. Possible academic extensions include roles, beneficiary management, monthly statements, interest calculation, stored procedures for recurring deposits, and Oracle APEX reporting.

## 13. GitHub submission checklist

1. Create a repository named `adbms-bank-account-management-system`.
2. Upload the project folder contents, including SQL, Python, templates, static files, README and report.
3. Do **not** upload `.env`, passwords, real customer data, `.venv` or cache folders. `.gitignore` is already included.
4. Add all three members as contributors/collaborators where required by the course.
5. Add the repository URL in the report's GitHub submission field and verify that it opens in a private/incognito browser if the repository is public.
6. Add a release/tag such as `v1.0-submission` after the final tested version is uploaded.

## 14. Academic integrity and submission note

Use this package as a working project base and learning aid. Before submission, each group member should run the project, replace placeholders with their actual details, capture fresh screenshots from their own Oracle-backed environment, record real test results, and make sure they can explain the code and database design during the viva. The included UI screenshots are illustrative preview-mode captures, not proof of a live Oracle database connection.
