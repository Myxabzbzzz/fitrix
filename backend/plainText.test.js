const test = require('node:test');
const assert = require('node:assert/strict');
const { createPlainTextFilter, toPlainText } = require('./plainText');

function stream(chunks) {
  const filter = createPlainTextFilter();
  return chunks.map((c) => filter.push(c)).join('') + filter.flush();
}

test('strips bold, headings and star bullets', () => {
  assert.equal(
    toPlainText('### Plan\n1. **Warm-up (5 mins):** jog\n* Squats - 3x10\n  * Rows'),
    'Plan\n1. Warm-up (5 mins): jog\n- Squats - 3x10\n  - Rows'
  );
});

test('handles markers split across streamed chunks', () => {
  assert.equal(
    stream(['Eat ', '*', '*130', ' g*', '*', ' daily.\n', '##', ' Tips\n', '*', ' sleep']),
    'Eat 130 g daily.\nTips\n- sleep'
  );
});

test('leaves plain text, numbers and mid-line symbols alone', () => {
  const text = 'Привет! 1. Bench press - 3x10\n2. 5*3 reps, #1 tip: rest.';
  assert.equal(stream(text.split('')), text);
  assert.equal(stream([text]), text);
});
