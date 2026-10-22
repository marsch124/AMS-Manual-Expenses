// Turns a dictated sentence into { description, amount, currency, time }.
// Understands English, Swedish and German keywords.
(function (root) {
  const CURRENCY_WORDS = {
    EUR: ['euros', 'euro', 'eur', '€', 'cents', 'cent'],
    SEK: ['swedish crowns', 'swedish kronor', 'kronor', 'kronan', 'krona', 'kronen', 'krone',
          'crowns', 'crown', 'sek', 'kr', 'spänn', 'öre'],
  };

  // Words that carry no meaning for the description.
  const FILLER = [
    'i spent', 'i paid', 'spent', 'paid', 'cost', 'costs', 'for', 'on', 'at', 'a', 'an', 'the',
    'and', 'och', 'und', 'jag betalade', 'betalade', 'kostade', 'för', 'på', 'ich habe', 'bezahlt',
    'für', 'ausgegeben', 'today', 'idag', 'heute', 'yesterday', 'igår', 'gestern',
  ];

  const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  // Ordered longest-first so "swedish crowns" wins over "crowns".
  const currencyList = Object.entries(CURRENCY_WORDS)
    .flatMap(([code, words]) => words.map((w) => ({ code, w })))
    .sort((a, b) => b.w.length - a.w.length);
  const currencyAlt = currencyList.map((c) => escape(c.w)).join('|');
  const wordRe = (alt) => new RegExp(`(^|[^\\p{L}])(${alt})(?=$|[^\\p{L}])`, 'giu');

  function currencyOf(word) {
    const hit = currencyList.find((c) => c.w === word.toLowerCase());
    return hit ? hit.code : null;
  }

  // "1,234" -> 1234, "12,50" -> 12.5, "12.5" -> 12.5
  function toNumber(raw) {
    let s = raw.replace(/\s/g, '');
    if (/^\d{1,3}([.,]\d{3})+$/.test(s)) return Number(s.replace(/[.,]/g, ''));
    return Number(s.replace(',', '.'));
  }

  function extractTime(text, now) {
    const t = new Date(now);
    let found = false;
    let out = text;

    const dayWords = /(^|[^\p{L}])(yesterday|igår|i går|gestern)(?=$|[^\p{L}])/iu;
    if (dayWords.test(out)) {
      t.setDate(t.getDate() - 1);
      found = true;
    }

    // "at 2 pm", "at 14:30", "klockan 14", "kl. 9.15", "um 14 Uhr", "2:30 pm"
    const timeRe = /(?:\b(?:at|around|klockan|kl\.?|um|gegen)\s+(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?|uhr)?)|(?:\b(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?|uhr)(?![\p{L}]))/iu;
    const m = out.match(timeRe);
    if (m) {
      let h = Number(m[1] ?? m[4]);
      const min = Number(m[2] ?? m[5] ?? 0);
      const suffix = (m[3] ?? m[6] ?? '').toLowerCase().replace(/\./g, '');
      if (suffix === 'pm' && h < 12) h += 12;
      if (suffix === 'am' && h === 12) h = 0;
      if (h <= 23 && min <= 59) {
        t.setHours(h, min, 0, 0);
        found = true;
        out = out.replace(m[0], ' ');
      }
    }
    return { time: t, timeGiven: found, rest: out };
  }

  function parseExpense(input, defaultCurrency, now = new Date()) {
    const original = (input || '').trim();
    let { time, timeGiven, rest } = extractTime(original, now);

    // Find every number and remember its position.
    const numRe = /\d{1,3}(?:[ .,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?/g;
    const nums = [...rest.matchAll(numRe)].map((m) => ({
      raw: m[0], value: toNumber(m[0]), start: m.index, end: m.index + m[0].length,
    }));

    const curs = [...rest.matchAll(wordRe(currencyAlt))].map((m) => ({
      code: currencyOf(m[2]), word: m[2].toLowerCase(),
      start: m.index + m[1].length, end: m.index + m[0].length,
    }));

    // Pick the number sitting right next to a currency word; otherwise the largest number.
    let amountNum = null;
    let currency = null;
    let used = [];
    for (const c of curs) {
      if (c.word === 'cents' || c.word === 'cent' || c.word === 'öre') continue;
      const after = nums.find((n) => n.start >= c.end && rest.slice(c.end, n.start).trim() === '');
      const before = [...nums].reverse().find((n) => n.end <= c.start && rest.slice(n.end, c.start).trim() === '');
      const n = before || after;
      if (n) { amountNum = n; currency = c.code; used.push(c); break; }
    }
    if (!amountNum && nums.length) {
      amountNum = nums.reduce((a, b) => (b.value > a.value ? b : a));
    }
    if (!currency && curs.length) currency = curs[0].code;

    let amount = amountNum ? amountNum.value : null;
    const removeRanges = [];
    if (amountNum) removeRanges.push([amountNum.start, amountNum.end]);

    // "12 euros 50" / "12 euro and 50 cents" / "45 kronor och 50 öre"
    if (amountNum && Number.isInteger(amount)) {
      const tail = rest.slice(amountNum.end);
      const m = tail.match(new RegExp(`^\\s*(?:${currencyAlt})\\s*(?:and|och|und)?\\s*(\\d{1,2})(?:\\s*(?:cents?|öre))?(?=$|[^\\p{L}\\d])`, 'iu'));
      if (m) {
        amount += Number(m[1]) / 100;
        removeRanges.push([amountNum.end, amountNum.end + m[0].length]);
      }
    }

    // Build the description from what is left.
    let desc = rest;
    for (const [s, e] of removeRanges.sort((a, b) => b[0] - a[0])) desc = desc.slice(0, s) + ' ' + desc.slice(e);
    desc = desc.replace(wordRe(currencyAlt), '$1 ');
    desc = desc.replace(/(^|[^\p{L}])(yesterday|igår|i går|gestern)(?=$|[^\p{L}])/giu, '$1 ');
    desc = desc.replace(/[,.;:!?]+/g, ' ').replace(/\s+/g, ' ').trim();
    // Strip filler words only at the start and end, so "coffee and cake" stays intact.
    const fillerAlt = FILLER.map(escape).sort((a, b) => b.length - a.length).join('|');
    const edge = new RegExp(`^(?:(?:${fillerAlt})\\s+)+|(?:\\s+(?:${fillerAlt}))+$`, 'iu');
    let prev;
    do { prev = desc; desc = desc.replace(edge, '').trim(); } while (desc !== prev);
    if (desc && FILLER.includes(desc.toLowerCase())) desc = '';
    if (desc) desc = desc.charAt(0).toUpperCase() + desc.slice(1);

    if (amount !== null) amount = Math.round(amount * 100) / 100;

    return {
      description: desc,
      amount,
      currency: currency || defaultCurrency,
      currencySpoken: Boolean(currency),
      time,
      timeGiven,
      original,
    };
  }

  // Currency from the phone's time zone (iPhone sets this automatically from location).
  const EURO_ZONES = [
    'Europe/Vienna', 'Europe/Berlin', 'Europe/Busingen', 'Europe/Paris', 'Europe/Madrid', 'Europe/Rome',
    'Europe/Amsterdam', 'Europe/Brussels', 'Europe/Lisbon', 'Europe/Dublin', 'Europe/Helsinki',
    'Europe/Mariehamn', 'Europe/Athens', 'Europe/Luxembourg', 'Europe/Monaco', 'Europe/Tallinn',
    'Europe/Riga', 'Europe/Vilnius', 'Europe/Bratislava', 'Europe/Ljubljana', 'Europe/Malta',
    'Asia/Nicosia', 'Asia/Famagusta', 'Europe/Nicosia', 'Europe/Zagreb', 'Europe/Andorra',
    'Europe/San_Marino', 'Europe/Vatican', 'Europe/Podgorica', 'Atlantic/Madeira', 'Atlantic/Azores',
    'Atlantic/Canary', 'Africa/Ceuta',
  ];

  function currencyForTimeZone(tz) {
    if (tz === 'Europe/Stockholm') return 'SEK';
    if (EURO_ZONES.includes(tz)) return 'EUR';
    return null;
  }

  const api = { parseExpense, currencyForTimeZone };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.ExpenseParser = api;
})(typeof window !== 'undefined' ? window : globalThis);
