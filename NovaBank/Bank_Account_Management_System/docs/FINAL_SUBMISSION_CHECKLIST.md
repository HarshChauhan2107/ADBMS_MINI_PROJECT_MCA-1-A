# NovaBank — Final Submission Checklist

Complete these checks before uploading the project to the course portal.

## Group and report details

- [ ] Replace `[University / College Name]`, department, course, semester and faculty guide placeholders.
- [ ] Enter all three students' actual names and roll numbers.
- [ ] Collect signatures/date details if required by the institution.
- [ ] Review the contribution table and record each member's actual work.
- [ ] Update the GitHub URL in the report after the repository exists.

## Oracle database evidence

- [ ] Create the `BANKAPP` user in the correct PDB.
- [ ] Run `database/install.sql` as `BANKAPP` using Run Script (F5) or SQLcl.
- [ ] Confirm the package compiles without errors.
- [ ] Run `database/04_seed_demo.sql` once.
- [ ] Run `database/05_test_suite.sql` and save the Script Output.
- [ ] Run `database/06_report_queries.sql` and capture the relevant query outputs.
- [ ] Capture a query result from `VW_BANK_ACCOUNTS`.
- [ ] Capture a query result from `VW_TRANSACTION_HISTORY`.
- [ ] Change an account status and capture `BANK_AUDIT_LOG`.
- [ ] Capture successful and rejected operations in the Oracle-backed dashboard.
- [ ] Enter observed results, date, tester and evidence filenames in the report and test record.

## Application evidence

- [ ] Set `DEMO_MODE=false` in `.env`.
- [ ] Confirm the browser can open `http://127.0.0.1:5000`.
- [ ] Demonstrate account creation, deposit, withdrawal, transfer, freeze/reactivation and zero-balance account closure.
- [ ] Confirm insufficient funds and frozen-account operations are rejected.
- [ ] Capture updated screenshots from the actual Oracle-backed application.

## GitHub hygiene

- [ ] Upload the SQL/PLSQL, Python, HTML, CSS, JavaScript, README and documents.
- [ ] Do not upload `.env`, passwords, real personal/bank data or `.venv`.
- [ ] Verify `.gitignore` is active.
- [ ] Add all group members as collaborators/contributors if required.
- [ ] Test the repository URL from a private/incognito browser.
- [ ] Tag the final submission version after testing.

## Academic review

- [ ] All three members can explain the project's purpose and their own contribution.
- [ ] The two non-coding members can explain primary key, foreign key, view, sequence, trigger and transaction in simple terms.
- [ ] The technical lead can explain PL/SQL package procedures, row locking and paired transfer entries.
- [ ] The group can clearly distinguish illustrative preview screenshots from actual Oracle test evidence.
