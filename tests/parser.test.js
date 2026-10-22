const test = require('node:test');
const assert = require('node:assert');
const { parseExpense, currencyForTimeZone } = require('../parser.js');

const now = new Date(2026, 9, 22, 15, 45);
const cases = [
  ['Coffee 45 kronor', 'Coffee', 45, 'SEK'],
  ['Lunch 12,50 euro', 'Lunch', 12.5, 'EUR'],
  ['Taxi 12 euros 50', 'Taxi', 12.5, 'EUR'],
  ['Taxi 12 euro and 50 cents', 'Taxi', 12.5, 'EUR'],
  ['I paid 129 kr for lunch at Max', 'Lunch at Max', 129, 'SEK'],
  ['€8.90 sandwich', 'Sandwich', 8.9, 'EUR'],
  ['Groceries 1,234 Swedish crowns', 'Groceries', 1234, 'SEK'],
  ['Parking 40', 'Parking', 40, 'SEK'],
  ['Kaffe och bulle 65 kronor', 'Kaffe och bulle', 65, 'SEK'],
  ['Zugticket 23,40 Euro', 'Zugticket', 23.4, 'EUR'],
  ['Lunch for 2 people 340 kronor', 'Lunch for 2 people', 340, 'SEK'],
  ['Dinner 85 euros at 7 pm', 'Dinner', 85, 'EUR'],
  ['Bensin 650 kr klockan 9.15', 'Bensin', 650, 'SEK'],
];
for (const [input, desc, amount, cur] of cases) {
  test(input, () => {
    const r = parseExpense(input, 'SEK', now);
    assert.strictEqual(r.description, desc);
    assert.strictEqual(r.amount, amount);
    assert.strictEqual(r.currency, cur);
  });
}

test('time is now when not spoken', () => {
  const r = parseExpense('Coffee 45 kr', 'SEK', now);
  assert.strictEqual(r.time.getHours(), 15);
  assert.strictEqual(r.timeGiven, false);
});
test('spoken time "at 7 pm"', () => {
  const r = parseExpense('Dinner 85 euros at 7 pm', 'SEK', now);
  assert.strictEqual(r.time.getHours(), 19);
});
test('spoken time "klockan 9.15"', () => {
  const r = parseExpense('Bensin 650 kr klockan 9.15', 'SEK', now);
  assert.deepStrictEqual([r.time.getHours(), r.time.getMinutes()], [9, 15]);
});
test('yesterday', () => {
  const r = parseExpense('Yesterday taxi 300 kronor', 'SEK', now);
  assert.strictEqual(r.time.getDate(), 21);
  assert.strictEqual(r.description, 'Taxi');
});
test('no amount', () => {
  const r = parseExpense('Coffee', 'EUR', now);
  assert.strictEqual(r.amount, null);
  assert.strictEqual(r.currency, 'EUR');
});
test('time zones', () => {
  assert.strictEqual(currencyForTimeZone('Europe/Stockholm'), 'SEK');
  assert.strictEqual(currencyForTimeZone('Europe/Vienna'), 'EUR');
  assert.strictEqual(currencyForTimeZone('America/New_York'), null);
});
