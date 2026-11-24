"""In-memory preview data. This is UI demonstration mode, not the Oracle database."""
from datetime import datetime
from threading import RLock


class DemoStore:
    def __init__(self):
        self.lock = RLock()
        self.next_no = 100000006
        self.next_txn = 10
        self.accounts = [
            self._account('NB0100000001', 'Aarav Mehta', 'aarav@example.test', '9000000001', 'SAVINGS', 27000, 'ACTIVE', 'New Delhi'),
            self._account('NB0100000002', 'Ananya Sharma', 'ananya@example.test', '9000000002', 'CURRENT', 122500, 'ACTIVE', 'Gurugram'),
            self._account('NB0100000003', 'Kabir Singh', 'kabir@example.test', '9000000003', 'SAVINGS', 10000, 'ACTIVE', 'Faridabad'),
            self._account('NB0100000004', 'Riya Kapoor', 'riya@example.test', '9000000004', 'SAVINGS', 47500, 'FROZEN', 'Noida'),
            self._account('NB0100000005', 'Dev Malhotra', 'dev@example.test', '9000000005', 'CURRENT', 70500, 'ACTIVE', 'Delhi'),
        ]
        self.transactions = []
        now = datetime.now()
        # All seed rows are created on the current date, matching the Oracle seed script.
        opening_balances = [25000, 120000, 8500, 45300, 78000]
        for idx, amount in enumerate(opening_balances):
            self._txn(self.accounts[idx], 'OPENING', amount, 'Initial account funding',
                      now, balance_after=amount)
        self._txn(self.accounts[0], 'DEPOSIT', 3500, 'Monthly savings top-up',
                  now, balance_after=28500)
        self._txn(self.accounts[1], 'WITHDRAWAL', 5000, 'Office expenses',
                  now, balance_after=115000)
        self._txn(self.accounts[0], 'TRANSFER_OUT', 1500, 'Family transfer',
                  now, self.accounts[2]['account_no'], balance_after=27000)
        self._txn(self.accounts[2], 'TRANSFER_IN', 1500, 'Family transfer',
                  now, self.accounts[0]['account_no'], balance_after=10000)
        self._txn(self.accounts[3], 'DEPOSIT', 2200, 'Cash deposit',
                  now, balance_after=47500)
        self._txn(self.accounts[4], 'TRANSFER_OUT', 7500, 'Vendor settlement',
                  now, self.accounts[1]['account_no'], balance_after=70500)
        self._txn(self.accounts[1], 'TRANSFER_IN', 7500, 'Vendor settlement',
                  now, self.accounts[4]['account_no'], balance_after=122500)

    @staticmethod
    def _account(no, name, email, phone, kind, balance, status, address):
        return {'account_no': no, 'full_name': name, 'email': email, 'phone': phone,
                'account_type': kind, 'balance': float(balance), 'status': status,
                'address': address, 'opened_on': datetime.now().date().isoformat()}

    def _txn(self, account, typ, amount, desc, stamp=None, related=None, balance_after=None):
        self.next_txn += 1
        ref = f'TXN{self.next_txn:012d}'
        entry = {'txn_ref': ref, 'account_no': account['account_no'],
                 'full_name': account['full_name'], 'txn_type': typ,
                 'amount': float(amount), 'balance_after': float(account['balance'] if balance_after is None else balance_after),
                 'description': desc, 'related_account_no': related,
                 'created_at': (stamp or datetime.now()).isoformat(timespec='seconds')}
        self.transactions.insert(0, entry)
        return ref

    def dashboard(self):
        active = [a for a in self.accounts if a['status'] != 'CLOSED']
        today = datetime.now().date().isoformat()
        return {'total_accounts': len(active), 'total_customers': len(active),
                'total_balance': sum(a['balance'] for a in active),
                'transactions_today': sum(1 for t in self.transactions if t['created_at'].startswith(today)),
                'frozen_accounts': sum(1 for a in active if a['status'] == 'FROZEN'),
                'monthly_volume': sum(t['amount'] for t in self.transactions)}

    def list_accounts(self, search=''):
        q = search.lower().strip()
        with self.lock:
            return [dict(a) for a in self.accounts if not q or q in ' '.join(str(v) for v in a.values()).lower()]

    def list_transactions(self, account_no=None, limit=50):
        with self.lock:
            rows = self.transactions
            if account_no:
                rows = [t for t in rows if t['account_no'] == account_no.upper()]
            return [dict(t) for t in rows[:limit]]

    def create_account(self, data):
        with self.lock:
            name = data.get('full_name', '').strip()
            kind = data.get('account_type', 'SAVINGS').upper()
            opening = round(float(data.get('opening_balance') or 0), 2)
            if len(name) < 2: raise ValueError('Please enter a valid customer name.')
            if kind not in ('SAVINGS', 'CURRENT'): raise ValueError('Choose Savings or Current account.')
            if opening < 0: raise ValueError('Opening balance cannot be negative.')
            no = f'NB{self.next_no:010d}'
            self.next_no += 1
            account = self._account(no, name, data.get('email',''), data.get('phone',''), kind, opening, 'ACTIVE', data.get('address',''))
            self.accounts.insert(0, account)
            if opening > 0: self._txn(account, 'OPENING', opening, 'Initial account funding')
            return dict(account)

    def transact(self, kind, data):
        with self.lock:
            no = data.get('account_no', '').upper()
            account = next((a for a in self.accounts if a['account_no'] == no), None)
            if not account: raise ValueError('Account number not found.')
            amount = round(float(data.get('amount') or 0), 2)
            if amount <= 0: raise ValueError('Amount must be greater than zero.')
            if account['status'] != 'ACTIVE': raise ValueError('Only active accounts can transact.')
            if kind == 'WITHDRAWAL' and account['balance'] < amount: raise ValueError('Insufficient balance.')
            if kind == 'DEPOSIT': account['balance'] = round(account['balance'] + amount, 2)
            else: account['balance'] = round(account['balance'] - amount, 2)
            ref = self._txn(account, kind, amount, data.get('description') or kind.title())
            return {'txn_ref': ref, 'balance': account['balance']}

    def transfer(self, data):
        with self.lock:
            src_no, dst_no = data.get('from_account','').upper(), data.get('to_account','').upper()
            if src_no == dst_no: raise ValueError('Source and destination must be different.')
            src = next((a for a in self.accounts if a['account_no'] == src_no), None)
            dst = next((a for a in self.accounts if a['account_no'] == dst_no), None)
            if not src or not dst: raise ValueError('Source or destination account was not found.')
            amount = round(float(data.get('amount') or 0), 2)
            if amount <= 0: raise ValueError('Amount must be greater than zero.')
            if src['status'] != 'ACTIVE' or dst['status'] != 'ACTIVE': raise ValueError('Both accounts must be active.')
            if src['balance'] < amount: raise ValueError('Insufficient balance for transfer.')
            src['balance'] = round(src['balance'] - amount, 2)
            dst['balance'] = round(dst['balance'] + amount, 2)
            ref = self._txn(src, 'TRANSFER_OUT', amount, data.get('description') or 'Account transfer', related=dst_no)
            self._txn(dst, 'TRANSFER_IN', amount, data.get('description') or 'Account transfer', related=src_no)
            return {'txn_ref': ref, 'source_balance': src['balance'], 'destination_balance': dst['balance']}

    def close_account(self, account_no):
        with self.lock:
            account = next((a for a in self.accounts if a['account_no'] == account_no.upper()), None)
            if not account or account['status'] == 'CLOSED':
                raise ValueError('Account not found or already closed.')
            if account['balance'] != 0:
                raise ValueError('Transfer or withdraw the remaining balance before closing the account.')
            account['status'] = 'CLOSED'
            return dict(account)

    def set_status(self, account_no, status):
        with self.lock:
            account = next((a for a in self.accounts if a['account_no'] == account_no.upper()), None)
            if not account or account['status'] == 'CLOSED': raise ValueError('Account not found or already closed.')
            status = status.upper()
            if status not in ('ACTIVE','FROZEN'): raise ValueError('Status must be ACTIVE or FROZEN.')
            account['status'] = status
            return dict(account)
