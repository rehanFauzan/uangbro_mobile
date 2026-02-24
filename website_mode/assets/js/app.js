/* ═══════════════════════════════════════════════════════════
   UangBro Web App — app.js   (Bootstrap Icons Edition)
   ═══════════════════════════════════════════════════════════ */

'use strict';

// ── CONFIG ────────────────────────────────────────────────
const API_BASE = window.location.hostname === 'localhost'
  ? 'http://localhost:8001'
  : window.location.origin + '/backend_api';

// ── STATE ─────────────────────────────────────────────────
const State = {
  token: localStorage.getItem('ub_token') || null,
  username: localStorage.getItem('ub_username') || null,
  email: localStorage.getItem('ub_email') || null,
  userId: localStorage.getItem('ub_user_id') || null,
  profilePhoto: localStorage.getItem('ub_photo') || null,
  transactions: [],
  showBalance: true,
  activeFilter: 'all',
  activePeriod: 'month',
  sortOption: 'date_desc',
  activeTab: 'home',
  categories: JSON.parse(localStorage.getItem('ub_categories') || 'null') || [
    'Makan', 'Transport', 'Belanja', 'Tagihan', 'Hiburan',
    'Kesehatan', 'Gaji', 'Bonus', 'Investasi', 'Hadiah', 'Lainnya'
  ],

  save() {
    const items = { ub_token: this.token, ub_username: this.username, ub_email: this.email, ub_user_id: this.userId, ub_photo: this.profilePhoto };
    Object.entries(items).forEach(([k, v]) => v ? localStorage.setItem(k, v) : localStorage.removeItem(k));
    localStorage.setItem('ub_categories', JSON.stringify(this.categories));
  },

  logout() {
    Object.assign(this, { token: null, username: null, email: null, userId: null, profilePhoto: null, transactions: [] });
    ['ub_token', 'ub_username', 'ub_email', 'ub_user_id', 'ub_photo'].forEach(k => localStorage.removeItem(k));
  }
};

// ── HELPERS ───────────────────────────────────────────────
const $ = id => document.getElementById(id);

function formatRp(n) {
  return 'Rp ' + Math.abs(Number(n) || 0).toLocaleString('id-ID');
}

function formatDate(s) {
  const d = new Date(s);
  return isNaN(d) ? (s || '') : d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
}

function toDateInput(s) {
  const d = new Date(s);
  return isNaN(d) ? new Date().toISOString().slice(0, 10) : d.toISOString().slice(0, 10);
}

const todayISO = () => new Date().toISOString().slice(0, 10);
const genId = () => 'tx-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);

let _toastTimer;
function showToast(msg, type = '') {
  const t = $('toast');
  t.textContent = msg;
  t.className = 'toast' + (type ? ' ' + type : '');
  t.style.display = 'block';
  clearTimeout(_toastTimer);
  _toastTimer = setTimeout(() => t.style.display = 'none', 3200);
}

function showConfirm(title, msg, okLabel = 'Hapus', icon = 'danger') {
  return new Promise(resolve => {
    $('confirm-title').textContent = title;
    $('confirm-message').textContent = msg;
    $('btn-confirm-ok').innerHTML = `<i class="bi bi-check-lg"></i> ${okLabel}`;
    $('modal-confirm').style.display = 'flex';

    function cleanup(val) {
      $('modal-confirm').style.display = 'none';
      resolve(val);
    }
    const onOk = () => { cleanup(true); document.removeEventListener('X', onOk); };
    const onCancel = () => { cleanup(false); document.removeEventListener('X', onCancel); };
    const onOvl = e => { if (e.target === $('modal-confirm')) cleanup(false); };

    $('btn-confirm-ok').onclick = onOk;
    $('btn-confirm-cancel').onclick = onCancel;
    $('modal-confirm').onclick = onOvl;
  });
}

function getRange(period) {
  const now = new Date();
  const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
  let start;
  if (period === 'week') {
    const dow = now.getDay() === 0 ? 6 : now.getDay() - 1;
    start = new Date(now); start.setDate(now.getDate() - dow); start.setHours(0, 0, 0, 0);
  } else if (period === '3month') {
    start = new Date(now.getFullYear(), now.getMonth() - 2, 1);
  } else if (period === '6month') {
    start = new Date(now.getFullYear(), now.getMonth() - 5, 1);
  } else if (period === 'year') {
    start = new Date(now.getFullYear(), 0, 1);
  } else { start = new Date(now.getFullYear(), now.getMonth(), 1); }
  return { start, end };
}

function inRange(tx, range) {
  const d = new Date(tx.date);
  return d >= range.start && d <= range.end;
}

function categoryIcon(cat) {
  const map = {
    makan: 'bi-cup-hot', transport: 'bi-car-front', belanja: 'bi-cart3',
    tagihan: 'bi-receipt', hiburan: 'bi-controller', kesehatan: 'bi-heart-pulse',
    gaji: 'bi-briefcase', bonus: 'bi-gift', investasi: 'bi-graph-up-arrow',
    hadiah: 'bi-gift2', lainnya: 'bi-three-dots'
  };
  return map[(cat || '').toLowerCase()] || 'bi-tag';
}

// ── API ───────────────────────────────────────────────────
const Api = {
  _h(extra = {}) {
    const h = { 'Content-Type': 'application/json', ...extra };
    if (State.token) h['Authorization'] = 'Bearer ' + State.token;
    return h;
  },
  // Token dikirim via URL agar bekerja di InfinityFree (nginx sering strip Authorization header)
  _url(url) {
    if (!State.token) return API_BASE + url;
    const sep = url.includes('?') ? '&' : '?';
    return API_BASE + url + sep + 'token=' + encodeURIComponent(State.token);
  },
  async _parseJson(r, url) {
    const text = await r.text();
    try {
      return JSON.parse(text);
    } catch (e) {
      console.error('Non-JSON response from', url, ':', text.substring(0, 300));
      const preview = text.trim().substring(0, 120) || '(empty)';
      return { status: 'error', message: 'Server error: ' + preview };
    }
  },
  async post(url, body) {
    // Sertakan token di body JSON sebagai fallback paling andal (InfinityFree)
    const enrichedBody = State.token ? { ...body, _token: State.token } : body;
    const r = await fetch(this._url(url), { method: 'POST', headers: this._h(), body: JSON.stringify(enrichedBody) });
    return this._parseJson(r, url);
  },
  async get(url) {
    const r = await fetch(this._url(url), { headers: this._h() });
    return this._parseJson(r, url);
  },
  async del(url) {
    const r = await fetch(this._url(url), { method: 'DELETE', headers: this._h() });
    return this._parseJson(r, url);
  },
  login: (u, p) => Api.post('/login.php', { username: u, password: p }),
  register: (u, p, e) => Api.post('/register.php', { username: u, password: p, email: e }),
  getTransactions: () => Api.get('/transaction_api.php'),
  saveTx: tx => Api.post('/transaction_api.php', tx),
  deleteTx: id => Api.del('/transaction_api.php?id=' + id),
  updateProfile: (u, img) => {
    const body = { username: u };
    if (img) body.image_base64 = btoa(String.fromCharCode(...new Uint8Array(img)));
    return Api.post('/update_profile.php', body);
  },
  resetPassword: (u, p) => Api.post('/reset_password.php', { username: u, password: p }),
};

// ── ROUTER: pages ─────────────────────────────────────────
function showPage(pageId) {
  ['page-login', 'page-register', 'page-forgot', 'page-app'].forEach(id => {
    const el = $(id);
    if (el) el.style.display = 'none';
  });
  const p = $(pageId);
  if (!p) return;
  // Auth pages need flex, app page needs block
  p.style.display = pageId === 'page-app' ? 'block' : 'flex';
}

// ── ROUTER: tabs ──────────────────────────────────────────
function showTab(tabName) {
  ['home', 'history', 'targets', 'profile'].forEach(t => {
    const tab = $('tab-' + t);
    if (tab) tab.style.display = 'none';
  });
  const tab = $('tab-' + tabName);
  if (tab) tab.style.display = 'block';
  State.activeTab = tabName;

  // Update bottom nav active state
  document.querySelectorAll('.nav-item[data-tab]').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === tabName);
  });

  // Update AppBar title
  const titles = { home: 'UangBro', history: 'Riwayat', targets: 'Target', profile: 'Profil Saya' };
  $('appbar-title').textContent = titles[tabName] || 'UangBro';

  // Render content
  if (tabName === 'home') renderHome();
  if (tabName === 'history') renderHistory();
  if (tabName === 'profile') renderProfile();
}

// ── LOAD TRANSACTIONS ─────────────────────────────────────
async function loadTransactions() {
  try {
    const data = await Api.getTransactions();
    if (Array.isArray(data)) {
      State.transactions = data.map(tx => ({ ...tx, amount: parseFloat(tx.amount) || 0 }));
    }
  } catch (e) {
    console.warn('Gagal memuat transaksi:', e);
  }
}

// ── AUTH ──────────────────────────────────────────────────
function storeAuthData(data, username, email) {
  State.token = data.api_token;
  State.username = data.username || username;
  State.email = data.email || email || '';
  State.userId = data.user_id ? String(data.user_id) : null;
  State.save();
}

function setupAuth() {
  // Password toggles (delegated)
  document.addEventListener('click', e => {
    const btn = e.target.closest('.toggle-pass');
    if (!btn) return;
    const inp = $(btn.dataset.target);
    if (!inp) return;
    inp.type = inp.type === 'password' ? 'text' : 'password';
    const icon = btn.querySelector('i');
    if (icon) icon.className = 'bi bi-' + (inp.type === 'password' ? 'eye' : 'eye-slash');
  });

  // ─ Login ─
  $('form-login').addEventListener('submit', async e => {
    e.preventDefault();
    const username = $('login-username').value.trim();
    const password = $('login-password').value;
    $('login-error').textContent = '';
    if (!username || !password) { $('login-error').textContent = 'Username dan password wajib diisi.'; return; }

    const btn = $('btn-login');
    btn.disabled = true;
    btn.querySelector('.btn-text').textContent = 'Memproses...';
    try {
      const data = await Api.login(username, password);
      if (data.status === 'success' && data.api_token) {
        storeAuthData(data, username, '');
        await loadTransactions();
        enterApp();
      } else {
        $('login-error').textContent = data.message || 'Username atau password salah.';
      }
    } catch {
      $('login-error').textContent = 'Tidak dapat terhubung ke server (' + API_BASE + ').';
      //  $('login-error').textContent = 'Tidak dapat terhubung ke server (localhost:8001).';
    } finally {
      btn.disabled = false;
      btn.querySelector('.btn-text').textContent = 'Masuk';
    }
  });

  // ─ Register ─
  $('form-register').addEventListener('submit', async e => {
    e.preventDefault();
    const username = $('reg-username').value.trim();
    const email = $('reg-email').value.trim();
    const password = $('reg-password').value;
    $('register-error').textContent = '';

    if (!username) { $('register-error').textContent = 'Masukkan username.'; return; }
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { $('register-error').textContent = 'Email tidak valid.'; return; }
    if (password.length < 6) { $('register-error').textContent = 'Password minimal 6 karakter.'; return; }

    const btn = $('btn-register');
    btn.disabled = true;
    btn.querySelector('.btn-text').textContent = 'Mendaftar...';
    try {
      const data = await Api.register(username, password, email);
      if (data.status === 'success' && data.api_token) {
        storeAuthData(data, username, email);
        await loadTransactions();
        enterApp();
      } else {
        $('register-error').textContent = data.message || 'Registrasi gagal. Coba username lain.';
      }
    } catch {
      $('register-error').textContent = 'Tidak dapat terhubung ke server (' + API_BASE + ').';
    } finally {
      btn.disabled = false;
      btn.querySelector('.btn-text').textContent = 'Daftar Sekarang';
    }
  });

  // ─ Forgot ─
  $('form-forgot').addEventListener('submit', async e => {
    e.preventDefault();
    const username = $('forgot-username').value.trim();
    const msgEl = $('forgot-msg');
    if (!username) { msgEl.textContent = 'Masukkan username.'; return; }
    msgEl.style.color = '';
    try {
      const data = await fetch(API_BASE + '/forgot_password.php', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username })
      }).then(r => r.json());
      if (data.status === 'success') {
        msgEl.style.color = 'var(--success)';
        msgEl.textContent = data.message || 'Cek email Anda untuk instruksi reset.';
      } else {
        msgEl.textContent = data.message || 'Gagal mengirim reset password.';
      }
    } catch { msgEl.textContent = 'Tidak dapat terhubung ke server.'; }
  });

  // ─ Nav links ─
  $('goto-register').addEventListener('click', e => { e.preventDefault(); showPage('page-register'); });
  $('goto-login').addEventListener('click', e => { e.preventDefault(); showPage('page-login'); });
  $('goto-forgot').addEventListener('click', e => { e.preventDefault(); showPage('page-forgot'); });
  $('goto-login-from-forgot').addEventListener('click', e => { e.preventDefault(); showPage('page-login'); });
}

// ── ENTER APP ─────────────────────────────────────────────
function enterApp() {
  showPage('page-app');
  showTab('home');
}

// ── HOME RENDER ───────────────────────────────────────────
function computeSummary() {
  const now = new Date();
  const mStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const dStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let bal = 0, mIn = 0, mEx = 0, dIn = 0, dEx = 0;
  State.transactions.forEach(tx => {
    const d = new Date(tx.date), a = tx.amount;
    const inc = tx.type === 'income';
    if (inc) bal += a; else bal -= a;
    if (d >= mStart) inc ? (mIn += a) : (mEx += a);
    if (d >= dStart) inc ? (dIn += a) : (dEx += a);
  });
  return { bal, mIn, mEx, dIn, dEx };
}

function renderHome() {
  const { bal, mIn, mEx, dIn, dEx } = computeSummary();

  // Greeting
  $('welcome-name').textContent = State.username || 'Pengguna';
  syncHomeAvatar();

  // Balance
  const balEl = $('balance-amount');
  if (State.showBalance) {
    balEl.textContent = formatRp(bal);
    balEl.style.color = bal >= 0 ? 'var(--neutral-high)' : 'var(--danger)';
  } else {
    balEl.textContent = 'Rp ••••••••';
    balEl.style.color = 'var(--neutral-high)';
  }

  $('monthly-income').textContent = formatRp(mIn);
  $('monthly-expense').textContent = formatRp(mEx);
  $('daily-income').textContent = formatRp(dIn);
  $('daily-expense').textContent = formatRp(dEx);

  // Recent
  const recent = [...State.transactions].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 5);
  renderTxList($('recent-tx-list'), recent, false);
}

function syncHomeAvatar() {
  const av = $('home-avatar');
  if (!av) return;
  if (State.profilePhoto) {
    av.innerHTML = `<img src="${State.profilePhoto}" alt="avatar" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" />`;
  } else {
    av.textContent = (State.username || 'U')[0].toUpperCase();
  }
}

// ── HISTORY RENDER ────────────────────────────────────────
function renderHistory() {
  renderComparison();
  renderTopCategories();
  renderHistoryList();
}

function renderComparison() {
  const range = getRange(State.activePeriod);
  const ms = range.end - range.start;
  const prevEnd = new Date(range.start.getTime() - 1);
  const prevStart = new Date(prevEnd.getTime() - ms);
  const sum = (arr) => arr.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
  const cur = sum(State.transactions.filter(t => inRange(t, range)));
  const prv = sum(State.transactions.filter(t => inRange(t, { start: prevStart, end: prevEnd })));
  const diff = cur - prv;
  const pct = prv > 0 ? diff / prv * 100 : (cur > 0 ? 100 : 0);
  const up = diff >= 0;
  const labels = { month: 'Bulan Ini', week: 'Minggu Ini', '3month': '3 Bulan', '6month': '6 Bulan', year: 'Tahun Ini' };

  $('comparison-card').innerHTML = `
    <div class="cmp-row">
      <div>
        <small><i class="bi bi-bar-chart-line"></i> Perbandingan Pengeluaran — ${labels[State.activePeriod] || ''}</small>
        <strong>${formatRp(cur)}</strong>
        <small>Periode sebelumnya: ${formatRp(prv)}</small>
      </div>
      <div style="text-align:right;">
        <div class="cmp-badge" style="color:${up ? 'var(--danger)' : 'var(--success)'}">
          <i class="bi bi-arrow-${up ? 'up' : 'down'}-circle-fill"></i> ${Math.abs(pct).toFixed(0)}%
        </div>
        <div class="cmp-label muted">${up ? 'Lebih boros' : 'Lebih hemat'}</div>
      </div>
    </div>`;
}

function renderTopCategories() {
  const range = getRange(State.activePeriod);
  const totals = {};
  State.transactions.filter(t => t.type === 'expense' && inRange(t, range))
    .forEach(t => { totals[t.category] = (totals[t.category] || 0) + t.amount; });
  const sorted = Object.entries(totals).sort((a, b) => b[1] - a[1]).slice(0, 5);
  const max = sorted.length ? sorted[0][1] : 1;

  $('top-categories').innerHTML = `<h4><i class="bi bi-bar-chart"></i> Top Kategori Pengeluaran</h4>` + (
    sorted.length === 0
      ? '<small class="muted">Tidak ada pengeluaran di periode ini.</small>'
      : sorted.map(([cat, amt]) => `
          <div class="cat-row">
            <div class="cat-name">${cat}</div>
            <div class="cat-bar-wrap"><div class="cat-bar" style="width:${(amt / max * 100).toFixed(1)}%"></div></div>
            <div class="cat-amount">${formatRp(amt)}</div>
          </div>`).join('')
  );
}

function renderHistoryList() {
  const query = ($('search-input').value || '').toLowerCase().trim();
  const range = getRange(State.activePeriod);
  $('btn-clear-search').style.display = query ? 'flex' : 'none';

  let list = State.transactions.filter(tx => {
    if (State.activeFilter === 'income' && tx.type !== 'income') return false;
    if (State.activeFilter === 'expense' && tx.type !== 'expense') return false;
    if (!inRange(tx, range)) return false;
    if (query && !`${tx.category} ${tx.description || ''} ${tx.amount} ${tx.date}`.toLowerCase().includes(query)) return false;
    return true;
  });

  const sortFns = {
    date_desc: (a, b) => new Date(b.date) - new Date(a.date),
    date_asc: (a, b) => new Date(a.date) - new Date(b.date),
    amount_desc: (a, b) => b.amount - a.amount,
    amount_asc: (a, b) => a.amount - b.amount,
  };
  list.sort(sortFns[State.sortOption] || sortFns.date_desc);

  renderTxList($('history-tx-list'), list, true);
}

// ── TRANSACTION LIST ──────────────────────────────────────
function renderTxList(container, txs, showActions) {
  if (!container) return;
  if (!txs.length) {
    container.innerHTML = `<div class="empty-list">
      <i class="bi bi-inbox empty-icon"></i>
      <p>Belum ada transaksi</p>
    </div>`;
    return;
  }

  container.innerHTML = txs.map(tx => {
    const isExp = tx.type === 'expense';
    const colorCls = isExp ? 'expense-text' : 'income-text';
    const bgCls = isExp ? 'expense-bg' : 'income-bg';
    const arrowIcon = isExp ? 'bi-arrow-up-circle-fill' : 'bi-arrow-down-circle-fill';
    const sign = isExp ? '- ' : '+ ';
    const actions = showActions ? `
      <div class="tx-actions">
        <button class="tx-btn" data-id="${tx.id}" data-action="edit" title="Edit">
          <i class="bi bi-pencil"></i>
        </button>
        <button class="tx-btn danger" data-id="${tx.id}" data-action="delete" title="Hapus">
          <i class="bi bi-trash3"></i>
        </button>
      </div>` : '';

    return `
      <div class="tx-item">
        <div class="tx-avatar ${bgCls}">
          <i class="bi ${arrowIcon}"></i>
        </div>
        <div class="tx-info">
          <div class="tx-category">${tx.category}</div>
          <div class="tx-desc">${tx.description || formatDate(tx.date)}</div>
        </div>
        <div class="tx-right">
          <div class="tx-amount ${colorCls}">${sign}${formatRp(tx.amount)}</div>
          <div class="tx-date">${formatDate(tx.date)}</div>
        </div>
        ${actions}
      </div>`;
  }).join('');

  container.querySelectorAll('.tx-btn').forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      const { id, action } = btn.dataset;
      if (action === 'delete') deleteTx(id);
      if (action === 'edit') openEditTx(id);
    });
  });
}

// ── TRANSACTION FORM ──────────────────────────────────────
let _txType = 'expense';
const EXP_CATS = ['Makan', 'Transport', 'Belanja', 'Tagihan', 'Hiburan', 'Kesehatan', 'Lainnya'];
const INC_CATS = ['Gaji', 'Bonus', 'Investasi', 'Hadiah', 'Lainnya'];

function buildCatOptions(selected = '') {
  const defaults = _txType === 'expense' ? EXP_CATS : INC_CATS;
  const all = [...new Set([...defaults, ...State.categories])];
  return '<option value="">Pilih Kategori</option>' +
    all.map(c => `<option value="${c}" ${c === selected ? 'selected' : ''}>${c}</option>`).join('');
}

function setTxType(type) {
  _txType = type;
  document.querySelectorAll('.segment').forEach(s => {
    s.classList.toggle('active', s.dataset.type === type);
    if (s.dataset.type === 'income') s.classList.toggle('income', type === 'income' && s.classList.contains('active'));
  });
  $('tx-category').innerHTML = buildCatOptions();
}

function openTxModal(type = 'expense', tx = null) {
  $('modal-tx-title').innerHTML = `<i class="bi bi-${tx ? 'pencil-square' : 'plus-circle'}"></i> ${tx ? 'Edit' : 'Tambah'} Transaksi`;
  $('tx-id').value = tx ? tx.id : '';
  $('tx-amount').value = tx ? tx.amount : '';
  $('tx-description').value = tx ? (tx.description || '') : '';
  $('tx-date').value = tx ? toDateInput(tx.date) : todayISO();
  setTxType(tx ? tx.type : type);
  if (tx) $('tx-category').value = tx.category;
  $('modal-transaction').style.display = 'flex';
  setTimeout(() => $('tx-amount').focus(), 100);
}

function closeTxModal() { $('modal-transaction').style.display = 'none'; }

function openEditTx(id) {
  const tx = State.transactions.find(t => t.id === id);
  if (tx) openTxModal(tx.type, tx);
}

async function deleteTx(id) {
  const tx = State.transactions.find(t => t.id === id);
  const ok = await showConfirm(
    'Hapus Transaksi?',
    tx ? `Hapus transaksi "${tx.category}" sebesar ${formatRp(tx.amount)}?` : 'Transaksi ini akan dihapus permanen.',
    'Hapus'
  );
  if (!ok) return;
  try {
    const res = await Api.deleteTx(id);
    if (res.status === 'success') {
      State.transactions = State.transactions.filter(t => t.id !== id);
      showToast('Transaksi dihapus', 'success');
      if (State.activeTab === 'home') renderHome();
      else renderHistory();
    } else showToast(res.message || 'Gagal menghapus', 'error');
  } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

function setupTxForm() {
  // Segment buttons
  document.querySelectorAll('.segment').forEach(seg => {
    seg.addEventListener('click', () => setTxType(seg.dataset.type));
  });

  $('btn-cancel-tx').addEventListener('click', closeTxModal);
  $('modal-transaction').addEventListener('click', e => {
    if (e.target === $('modal-transaction')) closeTxModal();
  });

  $('form-transaction').addEventListener('submit', async e => {
    e.preventDefault();
    const amount = parseFloat($('tx-amount').value);
    const category = $('tx-category').value;
    const desc = $('tx-description').value.trim();
    const date = $('tx-date').value;
    const existId = $('tx-id').value;

    if (!amount || amount <= 0) { showToast('Masukkan nominal yang valid', 'error'); return; }
    if (!category) { showToast('Pilih kategori terlebih dahulu', 'error'); return; }
    if (!date) { showToast('Pilih tanggal', 'error'); return; }

    const txId = existId || genId();
    const tx = { id: txId, type: _txType, amount, category, description: desc, date };

    try {
      const res = await Api.saveTx(tx);
      if (res.status === 'success' || (res.message || '').includes('berhasil')) {
        const idx = State.transactions.findIndex(t => t.id === txId);
        if (idx >= 0) State.transactions[idx] = tx;
        else State.transactions.unshift(tx);
        closeTxModal();
        showToast(existId ? 'Transaksi diperbarui ✓' : 'Transaksi disimpan ✓', 'success');
        if (State.activeTab === 'home') renderHome(); else renderHistory();
      } else {
        showToast(res.message || 'Gagal menyimpan', 'error');
      }
    } catch (err) { showToast('Error: ' + err.message, 'error'); }
  });
}

// ── PROFILE RENDER ────────────────────────────────────────
function renderProfile() {
  $('profile-username').textContent = State.username || 'Pengguna';
  const emailEl = $('profile-email');
  emailEl.innerHTML = `<i class="bi bi-envelope"></i> ${State.email || '-'}`;

  const av = $('profile-avatar');
  if (State.profilePhoto) {
    av.innerHTML = `<img src="${State.profilePhoto}" alt="foto" />`;
  } else {
    av.textContent = (State.username || 'U')[0].toUpperCase();
  }
}

function setupProfile() {
  // Edit Profile
  $('btn-edit-profile').addEventListener('click', () => {
    $('edit-username').value = State.username || '';
    $('profile-edit-error').textContent = '';
    $('modal-profile').style.display = 'flex';
  });
  $('btn-edit-profile-photo').addEventListener('click', () => $('btn-edit-profile').click());
  $('btn-cancel-profile').addEventListener('click', () => $('modal-profile').style.display = 'none');
  $('modal-profile').addEventListener('click', e => { if (e.target === $('modal-profile')) $('modal-profile').style.display = 'none'; });

  $('form-profile').addEventListener('submit', async e => {
    e.preventDefault();
    const name = $('edit-username').value.trim();
    if (!name) { $('profile-edit-error').textContent = 'Username tidak boleh kosong.'; return; }
    try {
      const res = await Api.updateProfile(name, null);
      if (res.status === 'success') {
        State.username = res.username || name;
        State.save();
        $('modal-profile').style.display = 'none';
        renderProfile(); renderHome();
        showToast('Profile diperbarui ✓', 'success');
      } else $('profile-edit-error').textContent = res.message || 'Gagal update profile.';
    } catch { $('profile-edit-error').textContent = 'Tidak dapat terhubung ke server.'; }
  });

  // Change Password
  $('btn-change-password').addEventListener('click', () => {
    $('pass-username').value = State.username || '';
    $('pass-new').value = $('pass-confirm').value = '';
    $('pass-error').textContent = '';
    $('modal-password').style.display = 'flex';
  });
  $('btn-cancel-pass').addEventListener('click', () => $('modal-password').style.display = 'none');
  $('modal-password').addEventListener('click', e => { if (e.target === $('modal-password')) $('modal-password').style.display = 'none'; });

  $('form-password').addEventListener('submit', async e => {
    e.preventDefault();
    const user = $('pass-username').value.trim();
    const np = $('pass-new').value;
    const cp = $('pass-confirm').value;
    $('pass-error').textContent = '';
    if (!user || !np || !cp) { $('pass-error').textContent = 'Semua field wajib diisi.'; return; }
    if (np.length < 6) { $('pass-error').textContent = 'Password minimal 6 karakter.'; return; }
    if (np !== cp) { $('pass-error').textContent = 'Konfirmasi password tidak cocok.'; return; }
    try {
      const res = await Api.resetPassword(user, np);
      if (res.status === 'success') {
        $('modal-password').style.display = 'none';
        showToast('Password berhasil diubah ✓', 'success');
      } else $('pass-error').textContent = res.message || 'Gagal mengubah password.';
    } catch { $('pass-error').textContent = 'Tidak dapat terhubung ke server.'; }
  });

  // Categories
  $('btn-manage-categories').addEventListener('click', () => {
    renderCatList(); $('modal-categories').style.display = 'flex';
  });
  $('btn-close-categories').addEventListener('click', () => $('modal-categories').style.display = 'none');
  $('modal-categories').addEventListener('click', e => { if (e.target === $('modal-categories')) $('modal-categories').style.display = 'none'; });

  $('btn-add-category').addEventListener('click', addCategory);
  $('new-category-input').addEventListener('keydown', e => { if (e.key === 'Enter') { e.preventDefault(); addCategory(); } });

  // Export
  $('btn-profile-export').addEventListener('click', exportCsv);

  // Reset data
  $('btn-reset-data').addEventListener('click', async () => {
    const ok = await showConfirm('Reset Semua Data?', 'Semua transaksi akan dihapus permanen. Tindakan ini tidak bisa dibatalkan!', 'Reset');
    if (!ok) return;
    let count = 0;
    for (const tx of [...State.transactions]) {
      try { await Api.deleteTx(tx.id); count++; } catch { }
    }
    State.transactions = [];
    showToast(`${count} transaksi dihapus`, 'success');
    renderHome();
  });

  // Logout
  $('btn-logout').addEventListener('click', async () => {
    const ok = await showConfirm('Logout?', 'Kamu akan keluar dari akun ini.', 'Logout');
    if (!ok) return;
    State.logout();
    $('login-username').value = $('login-password').value = '';
    $('login-error').textContent = '';
    showPage('page-login');
  });
}

function addCategory() {
  const val = $('new-category-input').value.trim();
  if (!val) return;
  if (!State.categories.includes(val)) { State.categories.push(val); State.save(); }
  $('new-category-input').value = '';
  renderCatList();
}

function renderCatList() {
  const list = $('categories-list');
  if (State.categories.length === 0) {
    list.innerHTML = '<p class="muted" style="padding:8px 0">Belum ada kategori kustom.</p>';
    return;
  }
  list.innerHTML = State.categories.map((c, i) => `
    <div class="category-chip">
      <span><i class="bi bi-tag"></i> ${c}</span>
      <button data-index="${i}" title="Hapus"><i class="bi bi-x-lg"></i></button>
    </div>`).join('');
  list.querySelectorAll('button').forEach(btn => {
    btn.addEventListener('click', () => {
      State.categories.splice(+btn.dataset.index, 1);
      State.save(); renderCatList();
    });
  });
}

// ── EXPORT CSV ────────────────────────────────────────────
function exportCsv() {
  const rows = [['ID', 'Tipe', 'Nominal', 'Kategori', 'Deskripsi', 'Tanggal']];
  State.transactions.forEach(tx => {
    rows.push([tx.id, tx.type, tx.amount, tx.category, tx.description || '', tx.date]);
  });
  const csv = rows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n');
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = Object.assign(document.createElement('a'), { href: url, download: `transaksi_uangbro_${todayISO()}.csv` });
  a.click();
  URL.revokeObjectURL(url);
  showToast('Export CSV berhasil ↓', 'success');
}

// ── SETUP APP EVENTS ──────────────────────────────────────
function setupApp() {
  // Bottom nav — tab switching
  document.querySelectorAll('.nav-item[data-tab]').forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.dataset.tab;
      if (tab) showTab(tab);
    });
  });

  // FAB — open transaction modal
  $('fab-add').addEventListener('click', () => openTxModal('expense'));

  // Home quick buttons
  $('btn-add-income').addEventListener('click', () => openTxModal('income'));
  $('btn-add-expense').addEventListener('click', () => openTxModal('expense'));

  // Home avatar quick-go to profile tab
  $('home-avatar').addEventListener('click', () => showTab('profile'));

  // See all → history tab
  $('btn-see-all').addEventListener('click', () => showTab('history'));

  // Balance toggle
  $('toggle-balance').addEventListener('click', () => {
    State.showBalance = !State.showBalance;
    $('toggle-balance-icon').className = 'bi bi-' + (State.showBalance ? 'eye' : 'eye-slash');
    renderHome();
  });

  // History: search
  $('search-input').addEventListener('input', renderHistoryList);
  $('btn-clear-search').addEventListener('click', () => {
    $('search-input').value = '';
    $('btn-clear-search').style.display = 'none';
    renderHistoryList();
  });

  // History: period
  $('period-selector').addEventListener('click', e => {
    const btn = e.target.closest('.period-btn');
    if (!btn) return;
    document.querySelectorAll('.period-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    State.activePeriod = btn.dataset.period;
    renderHistory();
  });

  // History: filter chips
  document.querySelectorAll('.chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      State.activeFilter = chip.dataset.filter;
      renderHistoryList();
    });
  });

  // History: sort
  $('sort-select').addEventListener('change', () => {
    State.sortOption = $('sort-select').value;
    renderHistoryList();
  });

  // History: export
  $('btn-export-csv').addEventListener('click', exportCsv);

  // Notification bell (placeholder)
  $('btn-notif').addEventListener('click', () => showToast('Tidak ada notifikasi baru', ''));

  // Transaction form
  setupTxForm();

  // Profile
  setupProfile();
}

// ── INIT ──────────────────────────────────────────────────
async function init() {
  // Hide splash after 1.2s
  setTimeout(() => {
    const splash = $('splash-screen');
    splash.style.opacity = '0';
    setTimeout(() => {
      splash.style.display = 'none';
      $('app').style.display = 'block';

      // Setup semua event listener dulu, baru tentukan halaman mana yg ditampilkan
      setupApp();
      setupAuth();

      if (State.token) {
        loadTransactions().then(() => {
          enterApp();
        }).catch(() => enterApp());
      } else {
        showPage('page-login');
      }
    }, 400);
  }, 1200);
}

// Bootstrap
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
