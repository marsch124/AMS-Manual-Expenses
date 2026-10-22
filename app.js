(function () {
  const { parseExpense, currencyForTimeZone } = window.ExpenseParser;
  const $ = (id) => document.getElementById(id);
  const STORE = 'expenses.v1';
  const PREFS = 'expenses.prefs.v1';

  const load = (key, fallback) => {
    try { return JSON.parse(localStorage.getItem(key)) ?? fallback; } catch { return fallback; }
  };
  const save = (key, value) => localStorage.setItem(key, JSON.stringify(value));

  let expenses = load(STORE, []);
  const prefs = load(PREFS, { currency: 'SEK', lang: 'en-US', manualCurrency: false });
  let editingId = null;

  // ---- Currency from where the phone is ----
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const tzCurrency = currencyForTimeZone(tz);
  if (!prefs.manualCurrency && tzCurrency) prefs.currency = tzCurrency;

  function renderCurrency() {
    $('currencyBtn').textContent = prefs.currency;
    const place = tz.split('/').pop().replace(/_/g, ' ');
    $('currencyHint').textContent = prefs.manualCurrency
      ? `Default currency set by you (tap ${prefs.currency} to switch, hold to go back to automatic).`
      : tzCurrency
        ? `Automatic: phone time zone is ${place}, so ${prefs.currency} is the default.`
        : `Time zone ${place} is not mapped to SEK or EUR; using ${prefs.currency}. Tap to switch.`;
  }
  $('currencyBtn').addEventListener('click', () => {
    if (holdTimer === 'fired') { holdTimer = null; return; }
    prefs.currency = prefs.currency === 'SEK' ? 'EUR' : 'SEK';
    prefs.manualCurrency = true;
    save(PREFS, prefs); renderCurrency();
  });
  let holdTimer;
  $('currencyBtn').addEventListener('pointerdown', () => {
    holdTimer = setTimeout(() => {
      prefs.manualCurrency = false;
      if (tzCurrency) prefs.currency = tzCurrency;
      save(PREFS, prefs); renderCurrency();
      holdTimer = 'fired';
    }, 800);
  });
  $('currencyBtn').addEventListener('pointerup', () => clearTimeout(holdTimer));

  // ---- Clock ----
  function tick() {
    const d = new Date();
    $('clock').textContent = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    $('date').textContent = d.toLocaleDateString([], { weekday: 'long', day: 'numeric', month: 'long' }) + ` · ${tz}`;
  }
  tick(); setInterval(tick, 10000);

  // ---- Formatting helpers ----
  const money = (n, cur) => new Intl.NumberFormat(undefined, { style: 'currency', currency: cur }).format(n);
  const pad = (n) => String(n).padStart(2, '0');
  const toLocalInput = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
  const sameDay = (a, b) => a.toDateString() === b.toDateString();

  // ---- Preview / edit ----
  function showPreview(entry, heard) {
    $('heard').textContent = heard || '—';
    $('pDesc').value = entry.description || '';
    $('pAmount').value = entry.amount ?? '';
    $('pCur').value = entry.currency;
    $('pTime').value = toLocalInput(new Date(entry.time));
    $('deleteBtn').hidden = !editingId;
    $('preview').hidden = false;
    $('preview').scrollIntoView({ behavior: 'smooth', block: 'center' });
    if (entry.amount == null) $('pAmount').focus();
  }
  function hidePreview() { $('preview').hidden = true; editingId = null; }

  function handleText(text) {
    if (!text.trim()) return;
    editingId = null;
    const r = parseExpense(text, prefs.currency);
    showPreview(r, text);
  }

  $('saveBtn').addEventListener('click', () => {
    const amount = Number(String($('pAmount').value).replace(',', '.'));
    if (!amount || amount < 0) { $('pAmount').focus(); return; }
    const entry = {
      id: editingId || (crypto.randomUUID ? crypto.randomUUID() : String(Date.now())),
      description: $('pDesc').value.trim() || 'Expense',
      amount: Math.round(amount * 100) / 100,
      currency: $('pCur').value,
      time: new Date($('pTime').value).toISOString(),
      timeZone: tz,
      heard: $('heard').textContent,
    };
    expenses = expenses.filter((e) => e.id !== entry.id).concat(entry);
    save(STORE, expenses);
    hidePreview(); $('textInput').value = ''; render();
  });
  $('cancelBtn').addEventListener('click', hidePreview);
  $('deleteBtn').addEventListener('click', () => {
    if (!confirm('Delete this expense?')) return;
    expenses = expenses.filter((e) => e.id !== editingId);
    save(STORE, expenses); hidePreview(); render();
  });

  $('textForm').addEventListener('submit', (e) => { e.preventDefault(); handleText($('textInput').value); });

  // ---- List ----
  function render() {
    const today = new Date();
    const items = expenses.filter((e) => sameDay(new Date(e.time), today))
      .sort((a, b) => new Date(b.time) - new Date(a.time));
    $('list').replaceChildren(...items.map((e) => {
      const li = document.createElement('li');
      const left = document.createElement('div');
      const title = document.createElement('div');
      title.textContent = e.description;
      const time = document.createElement('div');
      time.className = 'muted small';
      time.textContent = new Date(e.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      left.append(title, time);
      const amt = document.createElement('div');
      amt.className = 'amt';
      amt.textContent = money(e.amount, e.currency);
      li.append(left, amt);
      li.addEventListener('click', () => { editingId = e.id; showPreview(e, e.heard); });
      return li;
    }));
    $('empty').hidden = items.length > 0;
    const sums = {};
    for (const e of items) sums[e.currency] = (sums[e.currency] || 0) + e.amount;
    $('totals').innerHTML = '';
    for (const [cur, sum] of Object.entries(sums)) {
      const div = document.createElement('div');
      div.textContent = money(sum, cur);
      $('totals').append(div);
    }
  }

  // ---- Export ----
  $('exportBtn').addEventListener('click', () => {
    const q = (s) => `"${String(s).replace(/"/g, '""')}"`;
    const rows = [['Date', 'Time', 'Description', 'Amount', 'Currency', 'Time zone']];
    for (const e of [...expenses].sort((a, b) => new Date(a.time) - new Date(b.time))) {
      const d = new Date(e.time);
      rows.push([toLocalInput(d).slice(0, 10), toLocalInput(d).slice(11), e.description, e.amount.toFixed(2), e.currency, e.timeZone]);
    }
    const csv = rows.map((r) => r.map(q).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `expenses-${toLocalInput(new Date()).slice(0, 10)}.csv`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  });

  // ---- Dictation ----
  $('langSel').value = prefs.lang;
  $('langSel').addEventListener('change', () => { prefs.lang = $('langSel').value; save(PREFS, prefs); });

  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  let rec = null;
  let listening = false;
  if (!SR) {
    $('micBtn').disabled = true;
    $('micBtn').style.opacity = 0.4;
    $('micStatus').textContent = 'Voice button not supported in this browser. Tap the text field and use the microphone key on your keyboard instead.';
  }
  $('micBtn').addEventListener('click', () => {
    if (!SR) return;
    if (listening) { rec.stop(); return; }
    rec = new SR();
    rec.lang = prefs.lang;
    rec.interimResults = true;
    rec.continuous = false;
    let finalText = '';
    rec.onstart = () => { listening = true; $('micBtn').classList.add('listening'); $('micStatus').textContent = 'Listening…'; };
    rec.onresult = (ev) => {
      let interim = '';
      for (const r of ev.results) (r.isFinal ? (finalText = r[0].transcript) : (interim += r[0].transcript));
      $('micStatus').textContent = finalText || interim || 'Listening…';
      $('textInput').value = finalText || interim;
    };
    rec.onerror = (ev) => {
      $('micStatus').textContent = ev.error === 'not-allowed'
        ? 'Microphone access was denied. Allow it in Settings, or use keyboard dictation.'
        : `Dictation error: ${ev.error}`;
    };
    rec.onend = () => {
      listening = false;
      $('micBtn').classList.remove('listening');
      const text = finalText || $('textInput').value;
      if (text.trim()) { $('micStatus').textContent = 'Check and save:'; handleText(text); }
      else if ($('micStatus').textContent === 'Listening…') $('micStatus').textContent = 'Nothing heard. Try again.';
    };
    rec.start();
  });

  renderCurrency();
  render();

  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
})();
