const isDemo = document.body.dataset.demoMode === 'true';
const INR = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 2 });
const $ = (s, root = document) => root.querySelector(s);
const $$ = (s, root = document) => [...root.querySelectorAll(s)];

async function api(path, options = {}) {
  const response = await fetch(path, { headers: { 'Content-Type': 'application/json' }, ...options });
  const data = await response.json().catch(() => ({}));
  if (!response.ok || data.ok === false) throw new Error(data.error || `Request failed (${response.status})`);
  return data;
}
function money(value) { return INR.format(Number(value || 0)); }
function initials(name='NA') { return name.split(/\s+/).slice(0,2).map(x => x[0]).join('').toUpperCase(); }
function escapeHtml(value='') { return String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function toast(title, detail='', error=false) {
  const node = document.createElement('div'); node.className = `toast${error ? ' error' : ''}`;
  node.innerHTML = `<strong>${escapeHtml(title)}</strong>${detail ? `<small>${escapeHtml(detail)}</small>` : ''}`;
  $('#toastRegion').append(node); setTimeout(() => node.remove(), 4200);
}

async function loadDashboard() {
  const data = await api('/api/dashboard');
  $('#totalBalance').textContent = money(data.total_balance);
  $('#totalAccounts').textContent = Number(data.total_accounts || 0).toLocaleString('en-IN');
  $('#totalCustomers').textContent = Number(data.total_customers || 0).toLocaleString('en-IN');
  $('#todayTransactions').textContent = Number(data.transactions_today || 0).toLocaleString('en-IN');
  $('#frozenCount').textContent = `${data.frozen_accounts || 0} frozen account${Number(data.frozen_accounts) === 1 ? '' : 's'}`;
  $('#monthVolume').textContent = `${money(data.monthly_volume || 0)} monthly movement`;
}

async function loadAccounts(search='') {
  const data = await api(`/api/accounts?search=${encodeURIComponent(search)}`);
  const rows = data.accounts || [];
  $('#accountCount').textContent = `${rows.length} account${rows.length === 1 ? '' : 's'}`;
  $('#accountRows').innerHTML = rows.length ? rows.map(a => `
    <tr>
      <td><div class="holder-cell"><span class="mini-avatar">${escapeHtml(initials(a.full_name))}</span><span><span class="holder-name">${escapeHtml(a.full_name)}</span><span class="holder-email">${escapeHtml(a.email || 'No email on file')}</span></span></div></td>
      <td><span class="type-pill ${a.account_type === 'CURRENT' ? 'current' : ''}">${escapeHtml(a.account_type)}</span></td>
      <td><span class="account-number">${escapeHtml(a.account_no)}</span></td>
      <td><span class="balance-cell">${money(a.balance)}</span></td>
      <td><span class="status-pill ${String(a.status).toLowerCase()}">${escapeHtml(a.status)}</span></td>
      <td><div class="account-action-menu"><button data-action="DEPOSIT" data-account="${escapeHtml(a.account_no)}" title="Deposit">＋</button><button data-action="WITHDRAWAL" data-account="${escapeHtml(a.account_no)}" title="Withdraw">−</button><button data-action="STATUS" data-account="${escapeHtml(a.account_no)}" data-status="${escapeHtml(a.status)}" title="Freeze or activate" ${a.status === 'CLOSED' ? 'disabled' : ''}>⋯</button><button class="close-account-action" data-action="CLOSE" data-account="${escapeHtml(a.account_no)}" title="Close account" ${a.status === 'CLOSED' ? 'disabled' : ''}>×</button></div></td>
    </tr>`).join('') : '<tr><td colspan="6" class="empty-cell">No matching accounts found.</td></tr>';
}

function readableType(type) {
  return ({OPENING:'Account opened',DEPOSIT:'Deposit received',WITHDRAWAL:'Cash withdrawal',TRANSFER_IN:'Transfer received',TRANSFER_OUT:'Transfer sent'})[type] || type;
}
function txnIcon(type) { return type === 'DEPOSIT' || type === 'OPENING' || type === 'TRANSFER_IN' ? ['in','↓'] : type === 'WITHDRAWAL' ? ['out','↑'] : ['move','⇄']; }
async function loadTransactions() {
  const data = await api('/api/transactions?limit=7'); const rows = data.transactions || [];
  $('#transactionRows').innerHTML = rows.length ? rows.map(t => {
    const [tone, icon] = txnIcon(t.txn_type);
    const stamp = t.created_at ? new Date(t.created_at).toLocaleString('en-IN', {day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}) : '';
    const positive = ['DEPOSIT','OPENING','TRANSFER_IN'].includes(t.txn_type);
    return `<div class="activity-item"><span class="txn-icon ${tone}">${icon}</span><span class="txn-main"><strong>${readableType(t.txn_type)} · ${escapeHtml(t.full_name || t.account_no)}</strong><small>${escapeHtml(t.description || '')} · ${escapeHtml(stamp)}</small></span><span class="txn-account">${escapeHtml(t.account_no || '')}</span><span class="txn-amount ${positive ? 'in' : ''}">${positive ? '+' : '−'}${money(t.amount)}<small>${escapeHtml(t.txn_ref || '')}</small></span></div>`;
  }).join('') : '<div class="empty-cell">No transaction entries yet.</div>';
}
async function refreshAll() {
  try { await Promise.all([loadDashboard(), loadAccounts($('#accountSearch').value), loadTransactions()]); }
  catch (error) { toast('Unable to load dashboard', error.message, true); }
}

const backdrop = $('#modalBackdrop');
function closeModal() { backdrop.classList.remove('open'); backdrop.setAttribute('aria-hidden','true'); $('#modalBody').innerHTML = ''; }
function showModal(title, content) {
  $('#modalTitle').textContent = title; $('#modalBody').innerHTML = content;
  backdrop.classList.add('open'); backdrop.setAttribute('aria-hidden','false');
  const first = $('input,select', $('#modalBody')); if (first) first.focus();
}
function accountOptions(selected='') {
  return api('/api/accounts').then(data => (data.accounts || []).map(a => `<option value="${escapeHtml(a.account_no)}" ${a.account_no === selected ? 'selected' : ''}>${escapeHtml(a.full_name)} · ${escapeHtml(a.account_no)} (${escapeHtml(a.status)})</option>`).join(''));
}
function modalButtons(label='Continue') { return `<div class="modal-actions"><button type="button" class="secondary-btn" id="cancelModal">Cancel</button><button type="submit" class="submit-btn" id="submitModal">${label}</button></div>`; }

async function openAccountModal() {
  showModal('Open a new account', `<form id="operationForm"><div class="form-grid">
    <div class="field full"><label>Customer full name *</label><input name="full_name" required minlength="2" placeholder="e.g. Aditi Verma"></div>
    <div class="field"><label>Email address</label><input type="email" name="email" placeholder="name@example.com"></div>
    <div class="field"><label>Phone number</label><input name="phone" maxlength="20" placeholder="Mobile number"></div>
    <div class="field"><label>Account type *</label><select name="account_type"><option value="SAVINGS">Savings</option><option value="CURRENT">Current</option></select></div>
    <div class="field"><label>Opening balance (₹)</label><input type="number" name="opening_balance" min="0" step="0.01" value="1000"></div>
    <div class="field full"><label>Address</label><textarea name="address" placeholder="Customer address"></textarea></div>
  </div>${modalButtons('Create account')}<p class="form-note">The account number is generated by the database sequence. The initial amount is recorded as an opening ledger entry.</p></form>`);
  $('#operationForm').addEventListener('submit', submitCreateAccount);
}
async function openMoneyModal(kind, accountNo='') {
  const options = await accountOptions(accountNo);
  const isTransfer = kind === 'TRANSFER';
  const title = kind === 'DEPOSIT' ? 'Deposit funds' : kind === 'WITHDRAWAL' ? 'Withdraw funds' : 'Transfer between accounts';
  showModal(title, `<form id="operationForm"><div class="form-grid">
    ${isTransfer ? `<div class="field full"><label>From account *</label><select name="from_account" required>${options}</select></div><div class="field full"><label>To account *</label><select name="to_account" required>${options}</select></div>` : `<div class="field full"><label>Account *</label><select name="account_no" required>${options}</select></div>`}
    <div class="field full"><label>Amount (₹) *</label><input type="number" name="amount" min="0.01" step="0.01" required placeholder="Enter amount"></div>
    <div class="field full"><label>Description</label><input name="description" maxlength="250" placeholder="Purpose of this transaction"></div>
  </div>${modalButtons(isTransfer ? 'Transfer funds' : kind === 'DEPOSIT' ? 'Confirm deposit' : 'Confirm withdrawal')}<p class="form-note">${isTransfer ? 'Both accounts must be active. The transfer is recorded as a linked debit and credit.' : 'A successful transaction updates the account balance and creates a permanent ledger entry.'}</p></form>`);
  $('#operationForm').addEventListener('submit', e => submitMoney(e, kind));
}
async function submitCreateAccount(event) {
  event.preventDefault(); const button = $('#submitModal'); button.disabled = true; button.textContent = 'Creating…';
  try {
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());
    const result = await api('/api/accounts', {method:'POST', body:JSON.stringify(data)});
    closeModal(); toast('Account created', result.account_no ? `Account number: ${result.account_no}` : result.account.account_no);
    await refreshAll();
  } catch(error) { toast('Account not created', error.message, true); button.disabled = false; button.textContent = 'Create account'; }
}
async function submitMoney(event, kind) {
  event.preventDefault(); const button = $('#submitModal'); button.disabled = true; button.textContent = 'Processing…';
  try {
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());
    const endpoint = kind === 'TRANSFER' ? 'TRANSFER' : kind;
    const result = await api(`/api/transactions/${endpoint}`, {method:'POST', body:JSON.stringify(data)});
    closeModal(); toast('Transaction successful', result.txn_ref ? `Reference: ${result.txn_ref}` : result.message);
    await refreshAll();
  } catch(error) { toast('Transaction declined', error.message, true); button.disabled = false; button.textContent = kind === 'TRANSFER' ? 'Transfer funds' : kind === 'DEPOSIT' ? 'Confirm deposit' : 'Confirm withdrawal'; }
}

async function closeAccount(accountNo) {
  if (!confirm(`Close account ${accountNo}? The account must have a zero balance.`)) return;
  try { await api(`/api/accounts/${encodeURIComponent(accountNo)}/close`, {method:'POST'}); toast('Account closed', `${accountNo} has been closed.`); await refreshAll(); }
  catch(error) { toast('Account not closed', error.message, true); }
}

async function toggleStatus(accountNo, current) {
  const status = current === 'FROZEN' ? 'ACTIVE' : 'FROZEN';
  if (!confirm(`${status === 'FROZEN' ? 'Freeze' : 'Activate'} account ${accountNo}?`)) return;
  try { await api(`/api/accounts/${encodeURIComponent(accountNo)}/status`, {method:'PATCH', body:JSON.stringify({status})}); toast('Account updated', `${accountNo} is now ${status.toLowerCase()}.`); await refreshAll(); }
  catch(error) { toast('Status not changed', error.message, true); }
}

$('#openAccountBtn').addEventListener('click', openAccountModal);
$('#closeModal').addEventListener('click', closeModal);
backdrop.addEventListener('click', e => { if (e.target && e.target.id === 'cancelModal') closeModal(); });
backdrop.addEventListener('click', e => { if (e.target === backdrop) closeModal(); });
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });
$('#accountSearch').addEventListener('input', e => loadAccounts(e.target.value).catch(err => toast('Search failed', err.message, true)));
$('#viewAllAccounts').addEventListener('click', () => { $('#accounts').scrollIntoView({behavior:'smooth'}); $('#accountSearch').focus(); });
$('#refreshTransactions').addEventListener('click', () => loadTransactions().catch(err => toast('Refresh failed', err.message, true)));
$$('[data-quick]').forEach(btn => btn.addEventListener('click', () => openMoneyModal(btn.dataset.quick).catch(err => toast('Unable to open form', err.message, true))));
$('#accountRows').addEventListener('click', e => {
  const btn = e.target.closest('button[data-action]'); if (!btn) return;
  if (btn.dataset.action === 'STATUS') toggleStatus(btn.dataset.account, btn.dataset.status);
  else if (btn.dataset.action === 'CLOSE') closeAccount(btn.dataset.account);
  else openMoneyModal(btn.dataset.action, btn.dataset.account).catch(err => toast('Unable to open form', err.message, true));
});
$$('.nav-link').forEach(link => link.addEventListener('click', () => { $$('.nav-link').forEach(x => x.classList.remove('active')); link.classList.add('active'); $('#sidebar').classList.remove('open'); }));
$('#mobileMenu').addEventListener('click', () => $('#sidebar').classList.toggle('open'));
$('#connectionLabel').textContent = isDemo ? 'Preview environment' : 'Oracle connection';
$('#currentDate').textContent = new Date().toLocaleDateString('en-IN', {weekday:'long', day:'2-digit', month:'long', year:'numeric'}).toUpperCase();
refreshAll();
