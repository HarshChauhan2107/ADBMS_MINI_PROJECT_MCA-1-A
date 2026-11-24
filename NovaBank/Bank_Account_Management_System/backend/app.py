"""NovaBank educational bank account management dashboard.

Oracle is the source of truth. Set DEMO_MODE=true only for a temporary,
non-persistent interface preview when an Oracle database is not yet configured.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any

from flask import Flask, jsonify, render_template, request

ROOT = Path(__file__).resolve().parents[1]
try:
    from dotenv import load_dotenv
    load_dotenv(ROOT / '.env')
except ImportError:
    pass
sys.path.insert(0, str(Path(__file__).resolve().parent))
from demo_store import DemoStore  # noqa: E402

app = Flask(__name__, template_folder=str(ROOT / 'templates'), static_folder=str(ROOT / 'static'))
app.config['JSON_SORT_KEYS'] = False
DEMO_MODE = os.getenv('DEMO_MODE', 'false').lower() in ('1', 'true', 'yes', 'on')
_demo_store = DemoStore() if DEMO_MODE else None


def _oracle_module():
    try:
        import oracledb  # type: ignore
        return oracledb
    except ImportError as exc:
        raise RuntimeError('Oracle Python driver is missing. Run: pip install -r requirements.txt') from exc


def get_connection():
    if DEMO_MODE:
        raise RuntimeError('Database connection is not used in preview mode.')
    user = os.getenv('ORACLE_USER', 'BANKAPP')
    password = os.getenv('ORACLE_PASSWORD', '')
    dsn = os.getenv('ORACLE_DSN', 'localhost:1521/FREEPDB1')
    if not password:
        raise RuntimeError('ORACLE_PASSWORD is not set. Copy .env.example to .env and configure your database login.')
    oracle = _oracle_module()
    return oracle.connect(user=user, password=password, dsn=dsn)


def _json_value(value: Any):
    if hasattr(value, 'isoformat'):
        return value.isoformat()
    return value


def query_rows(sql: str, binds: dict | None = None) -> list[dict]:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, binds or {})
            names = [d[0].lower() for d in cur.description]
            return [{k: _json_value(v) for k, v in zip(names, row)} for row in cur.fetchall()]


def call_package(procedure: str, args: list):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.callproc(procedure, args)
        conn.commit()


def request_data() -> dict:
    return request.get_json(silent=True) or {}


def api_error(exc: Exception, status: int = 400):
    message = str(exc).strip()
    # Oracle often prefixes useful application errors with ORA-20xxx.
    return jsonify({'ok': False, 'error': message}), status


@app.get('/')
def index():
    return render_template('index.html', demo_mode=DEMO_MODE)


@app.get('/api/health')
def health():
    if DEMO_MODE:
        return jsonify({'ok': True, 'mode': 'DEMO PREVIEW', 'database': 'in-memory sample data; changes reset on restart'})
    try:
        rows = query_rows('SELECT 1 AS connected FROM dual')
        return jsonify({'ok': True, 'mode': 'ORACLE', 'database': 'connected' if rows else 'unknown'})
    except Exception as exc:
        return api_error(exc, 503)


@app.get('/api/dashboard')
def dashboard():
    try:
        if DEMO_MODE:
            return jsonify({'ok': True, **_demo_store.dashboard()})
        rows = query_rows('SELECT * FROM vw_dashboard_metrics')
        data = rows[0] if rows else {}
        # The month amount is calculated from the transaction ledger for the UI trend label.
        month = query_rows("""SELECT NVL(SUM(amount),0) AS monthly_volume
            FROM bank_transactions WHERE created_at >= CAST(TRUNC(SYSDATE,'MM') AS TIMESTAMP)""")
        data['monthly_volume'] = month[0]['monthly_volume'] if month else 0
        return jsonify({'ok': True, **data})
    except Exception as exc:
        return api_error(exc, 503)


@app.get('/api/accounts')
def accounts():
    try:
        search = request.args.get('search', '').strip()
        if DEMO_MODE:
            rows = _demo_store.list_accounts(search)
        else:
            rows = query_rows("""SELECT account_no, full_name, email, phone, address,
                account_type, balance, status, opened_on
                FROM vw_bank_accounts
                WHERE (:q IS NULL OR UPPER(account_no) LIKE '%' || UPPER(:q) || '%'
                   OR UPPER(full_name) LIKE '%' || UPPER(:q) || '%')
                ORDER BY created_at DESC""", {'q': search or None})
        return jsonify({'ok': True, 'accounts': rows})
    except Exception as exc:
        return api_error(exc, 503)


@app.get('/api/transactions')
def transactions():
    try:
        account_no = request.args.get('account_no')
        limit = max(1, min(int(request.args.get('limit', 30)), 200))
        if DEMO_MODE:
            rows = _demo_store.list_transactions(account_no, limit)
        else:
            binds = {'account_no': account_no, 'row_limit': limit}
            rows = query_rows("""SELECT txn_ref, account_no, full_name, txn_type, amount,
                balance_after, description, related_account_no, created_at
                FROM (SELECT * FROM vw_transaction_history
                      WHERE (:account_no IS NULL OR account_no = :account_no)
                      ORDER BY created_at DESC)
                WHERE ROWNUM <= :row_limit""", binds)
        return jsonify({'ok': True, 'transactions': rows})
    except Exception as exc:
        return api_error(exc, 400)


@app.post('/api/accounts')
def create_account():
    data = request_data()
    try:
        if DEMO_MODE:
            account = _demo_store.create_account(data)
            return jsonify({'ok': True, 'account': account, 'message': 'Account created in preview mode.'}), 201
        oracle = _oracle_module()
        with get_connection() as conn:
            with conn.cursor() as cur:
                account_no = cur.var(oracle.STRING, size=20)
                customer_id = cur.var(oracle.NUMBER)
                cur.callproc('pkg_bank_ops.open_account', [
                    data.get('full_name'), data.get('email'), data.get('phone'), data.get('address'),
                    data.get('account_type', 'SAVINGS'), float(data.get('opening_balance') or 0),
                    account_no, customer_id
                ])
            conn.commit()
        return jsonify({'ok': True, 'account_no': account_no.getvalue(),
                        'customer_id': customer_id.getvalue(), 'message': 'Account opened successfully.'}), 201
    except Exception as exc:
        return api_error(exc)


@app.post('/api/transactions/<kind>')
def create_transaction(kind: str):
    data = request_data()
    kind = kind.upper()
    try:
        if kind == 'TRANSFER':
            if DEMO_MODE:
                result = _demo_store.transfer(data)
                return jsonify({'ok': True, **result, 'message': 'Transfer completed in preview mode.'})
            oracle = _oracle_module()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    txn_ref = cur.var(oracle.STRING, size=24)
                    cur.callproc('pkg_bank_ops.transfer', [data.get('from_account'), data.get('to_account'),
                        float(data.get('amount') or 0), data.get('description'), txn_ref])
                conn.commit()
            return jsonify({'ok': True, 'txn_ref': txn_ref.getvalue(), 'message': 'Transfer completed successfully.'})

        if kind not in ('DEPOSIT', 'WITHDRAWAL'):
            return api_error(ValueError('Unsupported transaction type.'))
        if DEMO_MODE:
            result = _demo_store.transact(kind, data)
            return jsonify({'ok': True, **result, 'message': f'{kind.title()} completed in preview mode.'})
        oracle = _oracle_module()
        procedure = 'pkg_bank_ops.deposit' if kind == 'DEPOSIT' else 'pkg_bank_ops.withdraw'
        with get_connection() as conn:
            with conn.cursor() as cur:
                txn_ref = cur.var(oracle.STRING, size=24)
                cur.callproc(procedure, [data.get('account_no'), float(data.get('amount') or 0),
                                         data.get('description'), txn_ref])
            conn.commit()
        return jsonify({'ok': True, 'txn_ref': txn_ref.getvalue(), 'message': f'{kind.title()} completed successfully.'})
    except Exception as exc:
        return api_error(exc)


@app.patch('/api/accounts/<account_no>/status')
def update_status(account_no: str):
    data = request_data()
    status = str(data.get('status', '')).upper()
    try:
        if DEMO_MODE:
            account = _demo_store.set_status(account_no, status)
        else:
            call_package('pkg_bank_ops.set_account_status', [account_no, status])
            rows = query_rows('SELECT account_no, status FROM bank_accounts WHERE account_no = :no', {'no': account_no})
            account = rows[0] if rows else {'account_no': account_no, 'status': status}
        return jsonify({'ok': True, 'account': account, 'message': f'Account status changed to {status}.'})
    except Exception as exc:
        return api_error(exc)


@app.post('/api/accounts/<account_no>/close')
def close_account(account_no: str):
    try:
        if DEMO_MODE:
            account = _demo_store.close_account(account_no)
        else:
            call_package('pkg_bank_ops.close_account', [account_no])
            rows = query_rows('SELECT account_no, status FROM bank_accounts WHERE account_no = :no', {'no': account_no})
            account = rows[0] if rows else {'account_no': account_no, 'status': 'CLOSED'}
        return jsonify({'ok': True, 'account': account, 'message': 'Account closed successfully.'})
    except Exception as exc:
        return api_error(exc)


@app.errorhandler(404)
def not_found(_error):
    if request.path.startswith('/api/'):
        return jsonify({'ok': False, 'error': 'API endpoint not found.'}), 404
    return 'Page not found', 404


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=int(os.getenv('PORT', '5000')), debug=os.getenv('FLASK_DEBUG', 'false').lower() == 'true')
