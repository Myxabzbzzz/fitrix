const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { createActionFilter, parseAction, validateAction, extractAction } = require('./actions');
const { validateImages } = require('./images');
const { createPlainTextFilter } = require('./plainText');
const { buildSystemPrompt } = require('./prompt');

const block = (obj) => `<fitrix-action>${JSON.stringify(obj)}</fitrix-action>`;

// ---- stream filter ----

function run(chunks) {
  const f = createActionFilter();
  const visible = chunks.map((c) => f.push(c)).join('') + f.flush();
  return { visible, block: f.block() };
}

test('filter holds back a block split across chunks at every position', () => {
  const full = 'Done. Tap the button.\n' + block({ type: 'weight', mode: 'set', amount: 80 });
  for (let i = 1; i < full.length; i++) {
    const r = run([full.slice(0, i), full.slice(i)]);
    assert.equal(r.visible, 'Done. Tap the button.', `split at ${i}`);
    assert.ok(r.block.startsWith('<fitrix-action'), `split at ${i}`);
  }
  const r = run(full.split(''));
  assert.equal(r.visible, 'Done. Tap the button.');
  assert.deepEqual(parseAction(r.block), { type: 'weight', mode: 'set', kg: 80 });
});

test('filter passes text with a lone "<" or partial tag prefix through at the end', () => {
  assert.equal(run(['a < b ', 'and <fitrix']).visible, 'a < b and <fitrix');
  assert.equal(run(['x', '<', 'b>y']).visible, 'x<b>y');
  assert.equal(run(['plain text only']).block, null);
});

test('block never reaches text through the plain-text pipeline', () => {
  const a = createActionFilter();
  const p = createPlainTextFilter();
  const chunks = ['Eat **well**.\n<fitrix-', 'action>{"type":"meal_plan",', '"meals":[]}</fitrix-act', 'ion>'];
  const text = chunks.map((c) => p.push(a.push(c))).join('') + p.push(a.flush()) + p.flush();
  assert.equal(text, 'Eat well.');
});

test('unterminated block is dropped', () => {
  const r = run(['hi <fitrix-action>{"type":"weight"']);
  assert.equal(r.visible, 'hi');
  assert.equal(parseAction(r.block), null);
});

// ---- validation ----

test('weight: delta and set in kg, lb converted to kg rounded to 0.1', () => {
  assert.deepEqual(validateAction({ type: 'weight', mode: 'delta', amount: 3, unit: 'kg' }),
    { type: 'weight', mode: 'delta', kg: 3 });
  assert.deepEqual(validateAction({ type: 'weight', mode: 'delta', amount: -6, unit: 'lb' }),
    { type: 'weight', mode: 'delta', kg: -2.7 });
  assert.deepEqual(validateAction({ type: 'weight', mode: 'set', amount: 180, unit: 'lbs' }),
    { type: 'weight', mode: 'set', kg: 81.6 });
  assert.deepEqual(validateAction({ type: 'weight', mode: 'set', amount: 78.54 }),
    { type: 'weight', mode: 'set', kg: 78.5 });
});

test('weight: limits and bad shapes are rejected', () => {
  const w = (o) => validateAction({ type: 'weight', unit: 'kg', ...o });
  assert.equal(w({ mode: 'set', amount: 19.9 }), null);
  assert.equal(w({ mode: 'set', amount: 400.1 }), null);
  assert.notEqual(w({ mode: 'set', amount: 400 }), null);
  assert.notEqual(w({ mode: 'set', amount: 20 }), null);
  assert.equal(w({ mode: 'delta', amount: 50.1 }), null);
  assert.equal(w({ mode: 'delta', amount: -50.1 }), null);
  assert.notEqual(w({ mode: 'delta', amount: -50 }), null);
  assert.equal(w({ mode: 'delta', amount: 0 }), null);
  assert.equal(w({ mode: 'add', amount: 3 }), null);
  assert.equal(w({ mode: 'set', amount: '80' }), null);
  assert.equal(w({ mode: 'set', amount: 80, unit: 'stone' }), null);
  assert.equal(w({ mode: 'set' }), null);
  // 150 lb delta = 68 kg > 50
  assert.equal(validateAction({ type: 'weight', mode: 'delta', amount: 150, unit: 'lb' }), null);
});

const plan = (over = {}) => ({
  type: 'workout_plan',
  sport: 'gym',
  templates: [{ name: 'Upper', exercises: [{ name: 'Bench', sets: 4, reps: 8, kg: 60 }] }],
  ...over,
});

test('workout_plan: valid, kg optional, whitespace trimmed', () => {
  assert.deepEqual(validateAction(plan()), plan());
  const noKg = plan({ templates: [{ name: ' Legs ', exercises: [{ name: 'Squat', sets: 3, reps: 10 }] }] });
  assert.deepEqual(validateAction(noKg).templates, [{ name: 'Legs', exercises: [{ name: 'Squat', sets: 3, reps: 10 }] }]);
});

test('workout_plan: limits', () => {
  const ex = (o = {}) => ({ name: 'E', sets: 3, reps: 10, ...o });
  const tpl = (n = 'T', exercises = [ex()]) => ({ name: n, exercises });
  assert.equal(validateAction(plan({ sport: 'chess' })), null);
  assert.equal(validateAction(plan({ templates: [] })), null);
  assert.equal(validateAction(plan({ templates: Array(8).fill(tpl()) })), null);
  assert.notEqual(validateAction(plan({ templates: Array(7).fill(tpl()) })), null);
  assert.equal(validateAction(plan({ templates: [tpl('T', [])] })), null);
  assert.equal(validateAction(plan({ templates: [tpl('T', Array(13).fill(ex()))] })), null);
  assert.notEqual(validateAction(plan({ templates: [tpl('T', Array(12).fill(ex()))] })), null);
  for (const bad of [{ sets: 0 }, { sets: 11 }, { sets: 2.5 }, { reps: 0 }, { reps: 101 }, { kg: -1 }, { kg: 501 }, { name: '' }, { name: 'x'.repeat(101) }]) {
    assert.equal(validateAction(plan({ templates: [tpl('T', [ex(bad)])] })), null, JSON.stringify(bad));
  }
  assert.notEqual(validateAction(plan({ templates: [tpl('T', [ex({ sets: 10, reps: 100, kg: 500 })])] })), null);
  assert.equal(validateAction(plan({ templates: [tpl('x'.repeat(101))] })), null);
});

test('meal_plan: valid and limits', () => {
  const meal = (o = {}) => ({ name: 'Breakfast', items: 'Oatmeal, eggs', kcal: 520, ...o });
  const mp = (meals) => validateAction({ type: 'meal_plan', meals });
  assert.deepEqual(mp([meal()]), { type: 'meal_plan', meals: [meal()] });
  assert.equal(mp([]), null);
  assert.equal(mp(Array(9).fill(meal())), null);
  assert.notEqual(mp(Array(8).fill(meal())), null);
  assert.equal(mp([meal({ kcal: 3001 })]), null);
  assert.equal(mp([meal({ kcal: -1 })]), null);
  assert.notEqual(mp([meal({ kcal: 0 })]), null);
  assert.equal(mp([meal({ items: 'x'.repeat(201) })]), null);
  assert.notEqual(mp([meal({ items: 'x'.repeat(200) })]), null);
  assert.equal(mp([meal({ name: 'x'.repeat(101) })]), null);
  assert.equal(mp([meal({ kcal: '500' })]), null);
});

test('a missing comma between adjacent objects is repaired, other bad JSON is not', () => {
  const ok = '<fitrix-action>{"type":"meal_plan","meals":[{"name":"A","items":"x","kcal":1}{"name":"B","items":"y","kcal":2}]}</fitrix-action>';
  assert.equal(parseAction(ok).meals.length, 2);
  assert.equal(parseAction('<fitrix-action>{"type":"meal_plan","meals":[{"name":"A"}}]}</fitrix-action>'), null);
});

test('unknown types, non-objects and bad JSON are dropped', () => {
  assert.equal(validateAction({ type: 'delete_account' }), null);
  assert.equal(validateAction(null), null);
  assert.equal(validateAction([]), null);
  assert.equal(parseAction('<fitrix-action>not json</fitrix-action>'), null);
  assert.equal(parseAction(null), null);
});

test('extractAction handles a full non-stream reply', () => {
  const r = extractAction('Noted!\n' + block({ type: 'weight', mode: 'delta', amount: 3, unit: 'kg' }));
  assert.equal(r.text, 'Noted!');
  assert.deepEqual(r.action, { type: 'weight', mode: 'delta', kg: 3 });
  assert.equal(r.hadBlock, true);
});

// ---- prompt ----

test('system prompt includes the action rules', () => {
  const p = buildSystemPrompt('gym', null, 'en');
  for (const s of ['<fitrix-action>', '"type":"weight"', 'workout_plan', 'meal_plan', 'winterSports', 'confirm it with the button']) {
    assert.ok(p.includes(s), s);
  }
});

// ---- images ----

const jpeg = (bytes = 100) => Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(bytes)]).toString('base64');

test('validateImages: accepts none, empty, one JPEG', () => {
  assert.deepEqual(validateImages(undefined), { images: [] });
  assert.deepEqual(validateImages([]), { images: [] });
  const img = jpeg();
  assert.deepEqual(validateImages([img]), { images: [img] });
});

test('validateImages: rejects bad input with 400 and oversize with 413', () => {
  assert.equal(validateImages('x').status, 400);
  assert.equal(validateImages([jpeg(), jpeg()]).status, 400);
  assert.equal(validateImages([5]).status, 400);
  assert.equal(validateImages(['data:image/jpeg;base64,' + jpeg()]).status, 400);
  assert.equal(validateImages(['not base64!!']).status, 400);
  assert.equal(validateImages([Buffer.from('hello world').toString('base64')]).status, 400); // not a JPEG
  assert.equal(validateImages([jpeg(1.5 * 1024 * 1024)]).status, 413);
  assert.equal(validateImages([jpeg(1.5 * 1024 * 1024 - 3)]).images.length, 1);
});

// ---- HTTP: stream/non-stream with stub Ollama ----

const ollamaRequests = [];
const fallbackRequests = [];
let fallbackMode = 'ok';
let fallbackFoodMode = false;
let fallbackWeightMode = false;
const PLAN_TEXT =
  'Plan:\nDay 1 - Legs\n- Squat 4x10\n- Lunge 3x12\nDay 2 - Upper\n- Bench 4x8\n- Row 3x10\nTap the button below to add it.';
const ollama = http.createServer((req, res) => {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    const data = JSON.parse(body || '{}');
    if (!data.messages?.length) return res.end('{}');
    if (data.format) {
      fallbackRequests.push(data);
      if (fallbackMode === 'hang') return;
      res.writeHead(200, { 'Content-Type': 'application/json' });
      if (fallbackWeightMode) {
        return res.end(JSON.stringify({ message: { content: JSON.stringify({ mode: 'delta', amount: 3, unit: 'kg' }) } }));
      }
      if (fallbackFoodMode) {
        return res.end(JSON.stringify({ message: { content: JSON.stringify({
          slot: null,
          items: [{ name: 'egg', grams: 100, kcal: 155, protein: 13, carbs: 1, fat: 11 }],
        }) } }));
      }
      return res.end(JSON.stringify({ message: { content: JSON.stringify({
        sport: 'gym',
        templates: [{ name: 'Day A', exercises: [{ name: 'Squat', sets: '4', reps: '8-12' }] }],
      }) } }));
    }
    ollamaRequests.push(data);
    const last = data.messages[data.messages.length - 1].content;
    const reply = last.startsWith('weight')
      ? 'Noted, +3 kg.\nTap the button below.\n' + block({ type: 'weight', mode: 'delta', amount: 3, unit: 'kg' })
      : last.startsWith('bad')
        ? 'Sure.\n' + block({ type: 'weight', mode: 'set', amount: 5 })
        : last.startsWith('plan')
        ? PLAN_TEXT
        : last.startsWith('recplan')
        ? PLAN_TEXT
        : /train hard|workout plan|recovery workout|20 минут/.test(last)
        ? 'Here you go.\n' + block({ type: 'workout_plan', sport: 'gym', templates: [{ name: 'Day A', exercises: [{ name: 'Squat', sets: 3, reps: 8 }] }] })
        : 'plain reply';
    if (data.stream) {
      res.writeHead(200, { 'Content-Type': 'application/x-ndjson' });
      // Many small chunks so the tag is split across deltas.
      for (let i = 0; i < reply.length; i += 3) {
        res.write(JSON.stringify({ message: { content: reply.slice(i, i + 3) } }) + '\n');
      }
      res.end(JSON.stringify({ done: true }) + '\n');
    } else {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: { content: reply } }));
    }
  });
});

let base;
let appServer;
test.before(async () => {
  await new Promise((r) => ollama.listen(0, '127.0.0.1', r));
  process.env.OLLAMA_URL = `http://127.0.0.1:${ollama.address().port}`;
  process.env.OLLAMA_MODEL = 'text-model';
  process.env.OLLAMA_VISION_MODEL = 'vision-model';
  process.env.FALLBACK_TIMEOUT_MS = '300';
  const { createApp } = require('./server');
  appServer = await new Promise((r) => {
    const s = createApp({ rateLimit: 0 }).listen(0, '127.0.0.1', () => r(s));
  });
  base = `http://127.0.0.1:${appServer.address().port}`;
});
test.after(() => {
  appServer.close();
  ollama.closeAllConnections();
  ollama.close();
});

const post = (path, body) =>
  fetch(base + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

async function ndjson(res) {
  return (await res.text()).trim().split('\n').map((l) => JSON.parse(l));
}

test('stream: block hidden from deltas, action sent before done', async () => {
  const res = await post('/chat/stream', { message: 'weight up', conversationId: 's1', history: [] });
  const events = await ndjson(res);
  const text = events.filter((e) => e.delta).map((e) => e.delta).join('');
  assert.equal(text, 'Noted, +3 kg.\nTap the button below.');
  assert.ok(!text.includes('fitrix'));
  const kinds = events.map((e) => Object.keys(e)[0]);
  assert.deepEqual(kinds.slice(-2), ['action', 'done']);
  assert.equal(kinds.filter((k) => k === 'action').length, 1);
  assert.deepEqual(events.find((e) => e.action).action, { type: 'weight', mode: 'delta', kg: 3 });
});

test('stream: invalid action is dropped but text still streams', async () => {
  const events = await ndjson(await post('/chat/stream', { message: 'bad one', conversationId: 's2', history: [] }));
  assert.equal(events.filter((e) => e.delta).map((e) => e.delta).join(''), 'Sure.');
  assert.ok(!events.some((e) => e.action));
  assert.ok(events.some((e) => e.done));
});

test('non-stream /chat returns action', async () => {
  const json = await (await post('/chat', { message: 'weight up', conversationId: 'n1', history: [] })).json();
  assert.equal(json.reply, 'Noted, +3 kg.\nTap the button below.');
  assert.deepEqual(json.action, { type: 'weight', mode: 'delta', kg: 3 });
  const plainJson = await (await post('/chat', { message: 'hello', conversationId: 'n2', history: [] })).json();
  assert.deepEqual(plainJson, { reply: 'plain reply' });
});

test('image: switches model for that request only, images on current message only', async () => {
  const img = jpeg();
  ollamaRequests.length = 0;
  let res = await post('/chat/stream', {
    message: 'what is this',
    conversationId: 'i1',
    history: [{ role: 'user', content: 'earlier' }, { role: 'assistant', content: 'ok' }],
    images: [img],
  });
  assert.equal(res.status, 200);
  await res.text();
  let req = ollamaRequests.at(-1);
  assert.equal(req.model, 'vision-model');
  const withImages = req.messages.filter((m) => m.images);
  assert.equal(withImages.length, 1);
  assert.equal(req.messages.at(-1).images[0], img);

  // Server-memory path: next turn without image uses the text model and
  // never replays the photo.
  await (await post('/chat', { message: 'with photo', conversationId: 'i2', images: [img] })).text();
  await (await post('/chat', { message: 'followup', conversationId: 'i2' })).text();
  req = ollamaRequests.at(-1);
  assert.equal(req.model, 'text-model');
  assert.ok(!req.messages.some((m) => m.images));
});

test('image: oversize is 413 with JSON error, malformed is 400, Ollama untouched', async () => {
  ollamaRequests.length = 0;
  let res = await post('/chat/stream', {
    message: 'x', conversationId: 'i3', images: [jpeg(1.6 * 1024 * 1024)],
  });
  assert.equal(res.status, 413);
  const json = await res.json();
  assert.match(json.error, /too large/i);
  assert.ok(json.message);
  res = await post('/chat', { message: 'x', conversationId: 'i3', images: [jpeg(), jpeg()] });
  assert.equal(res.status, 400);
  assert.equal(ollamaRequests.length, 0);
});

test('text after the block is shown; a second block is dropped', () => {
  const b = block({ type: 'weight', mode: 'set', amount: 80 });
  const text = `Nice!\n${b}\n  Tap below.\n${b}`;
  for (let i = 1; i < text.length; i++) {
    const r = run([text.slice(0, i), text.slice(i)]);
    assert.equal(r.visible, 'Nice!\nTap below.', `split at ${i}`);
    assert.deepEqual(parseAction(r.block), { type: 'weight', mode: 'set', kg: 80 });
  }
});

// ---- fallback, coercion, sport default, fences ----

test('looksLikePlan recognises workouts and meals, not chit-chat', () => {
  const { looksLikePlan } = require('./fallback');
  assert.equal(looksLikePlan(PLAN_TEXT), 'workout_plan');
  assert.equal(looksLikePlan('Завтрак: каша - 400 ккал\nОбед: суп - 500 ккал\nУжин: рыба - 450 ккал'), 'meal_plan');
  assert.equal(looksLikePlan('Day 1 is rest. Squat 3x10 is good.'), null);
  assert.equal(looksLikePlan('Drink water and sleep 8 hours.'), null);
});

test('stream: plan without a block triggers the structured fallback', async () => {
  fallbackRequests.length = 0;
  fallbackMode = 'ok';
  const events = await ndjson(await post('/chat/stream', { message: 'plan please', conversationId: 'f1', history: [] }));
  assert.equal(fallbackRequests.length, 1);
  assert.equal(fallbackRequests[0].options.temperature, 0);
  assert.equal(fallbackRequests[0].think, false);
  assert.ok(fallbackRequests[0].format.properties.templates);
  const kinds = events.map((e) => Object.keys(e)[0]);
  assert.deepEqual(kinds.slice(-2), ['action', 'done']);
  // "4" and "8-12" are coerced
  assert.deepEqual(events.find((e) => e.action).action, {
    type: 'workout_plan', sport: 'gym',
    templates: [{ name: 'Day A', exercises: [{ name: 'Squat', sets: 4, reps: 8 }] }],
  });
});

test('non-stream /chat uses the fallback too', async () => {
  fallbackMode = 'ok';
  const json = await (await post('/chat', { message: 'plan please', conversationId: 'f2', history: [] })).json();
  assert.equal(json.action.type, 'workout_plan');
});

test('fallback timeout: done without action', async () => {
  fallbackRequests.length = 0;
  fallbackMode = 'hang';
  const events = await ndjson(await post('/chat/stream', { message: 'plan please', conversationId: 'f3', history: [] }));
  assert.equal(fallbackRequests.length, 1);
  assert.ok(!events.some((e) => e.action));
  assert.deepEqual(events.at(-1), { done: true });
  fallbackMode = 'ok';
});

test('non-plan reply makes no fallback call', async () => {
  fallbackRequests.length = 0;
  await (await post('/chat/stream', { message: 'hello', conversationId: 'f4', history: [] })).text();
  assert.equal(fallbackRequests.length, 0);
});

test('sport chat: the topic stands in for a missing sport; vision request has no think', async () => {
  const b = JSON.stringify({ type: 'workout_plan', templates: [{ name: 'A', exercises: [{ name: 'X', sets: '3', reps: '10-12', kg: '20' }] }] });
  const ok = parseAction(`<fitrix-action>${b}</fitrix-action>`, { defaultSport: 'running' });
  assert.equal(ok.sport, 'running');
  assert.deepEqual(ok.templates[0].exercises[0], { name: 'X', sets: 3, reps: 10, kg: 20 });
  assert.equal(parseAction(`<fitrix-action>${b}</fitrix-action>`), null);
  assert.equal(parseAction(`<fitrix-action>${b.replace('"10-12"', '"lots"')}</fitrix-action>`, { defaultSport: 'gym' }), null);
  assert.ok(buildSystemPrompt('running', null, 'en').includes('"sport":"running"'));

  ollamaRequests.length = 0;
  await (await post('/chat', { message: 'what is this', conversationId: 'v1', history: [], images: [jpeg()] })).text();
  assert.ok(!('think' in ollamaRequests.at(-1)));
  await (await post('/chat', { message: 'hello', conversationId: 'v2', history: [] })).text();
  assert.equal(ollamaRequests.at(-1).think, false);
});

test('code fences around a block are removed, also when split', () => {
  const b = block({ type: 'weight', mode: 'set', amount: 80 });
  const text = 'Noted.\n```json\n' + b + '\n```\nGood luck!';
  for (let i = 1; i < text.length; i++) {
    const r = run([text.slice(0, i), text.slice(i)]);
    assert.equal(r.visible, 'Noted.\nGood luck!', `split at ${i}`);
  }
});

test('prompt: placeholders, language copy rule and removed-blocks note', () => {
  const p = buildSystemPrompt('app', null, 'ru');
  assert.ok(p.includes('Copy each session name and meal name/items text exactly'));
  assert.ok(p.includes('without their blocks'));
  assert.ok(p.includes('<session 1 name>'));
});

// ---- food_log + workout when/days ----

const foodItem = { name: 'chicken breast', grams: 200, kcal: 330, protein: 62, carbs: 0, fat: 7.2 };
const food = (over = {}) => ({ type: 'food_log', slot: 'lunch', items: [foodItem], ...over });

test('food_log: accepts the contract example, slot null, and trims names', () => {
  assert.deepEqual(validateAction(food()), food());
  assert.equal(validateAction(food({ slot: null })).slot, null);
  assert.equal(validateAction(food({ slot: undefined })).slot, null);
  assert.equal(validateAction(food({ items: [{ ...foodItem, name: ' egg ' }] })).items[0].name, 'egg');
  for (const slot of ['breakfast', 'dinner', 'snack']) assert.equal(validateAction(food({ slot })).slot, slot);
});

test('food_log: rejects out-of-range numbers, bad slot, bad name, bad item count', () => {
  const bad = (o) => assert.equal(validateAction(food({ items: [{ ...foodItem, ...o }] })), null, JSON.stringify(o));
  bad({ grams: 0 });
  bad({ grams: 5000 });
  bad({ kcal: 9000 });
  bad({ kcal: -1 });
  bad({ protein: 501 });
  bad({ carbs: -1 });
  bad({ fat: 'x' });
  bad({ name: 5 });
  bad({ name: '' });
  assert.equal(validateAction(food({ items: [] })), null);
  assert.equal(validateAction(food({ items: Array(16).fill(foodItem) })), null);
  assert.ok(validateAction(food({ items: Array(15).fill(foodItem) })));
  assert.equal(validateAction(food({ slot: 'brunch' })), null);
  assert.equal(validateAction(food({ items: 'egg' })), null);
});

const tpl = (n = 'A') => ({ name: n, exercises: [{ name: 'Squat', sets: 3, reps: 5 }] });
const wp = (o) => ({ type: 'workout_plan', sport: 'gym', templates: [tpl()], ...o });

test('workout_plan: when/days are optional and validated', () => {
  assert.deepEqual(validateAction(wp()), { type: 'workout_plan', sport: 'gym', templates: [tpl()] });
  assert.deepEqual(validateAction(wp({ when: null })).when, null);
  const ok = validateAction(wp({ when: 'today', days: ['today'] }));
  assert.equal(ok.when, 'today');
  assert.deepEqual(ok.days, ['today']);
  const week = validateAction(wp({ when: 'week', templates: [tpl('A'), tpl('B')], days: ['mon', 'thu'] }));
  assert.deepEqual(week.days, ['mon', 'thu']);
  assert.equal(validateAction(wp({ when: 'today', templates: [tpl('A'), tpl('B')] })), null);
  assert.equal(validateAction(wp({ when: 'month' })), null);
  assert.equal(validateAction(wp({ templates: [tpl('A'), tpl('B')], days: ['mon'] })), null);
  assert.equal(validateAction(wp({ days: ['funday'] })), null);
  assert.equal(validateAction(wp({ days: 'mon' })), null);
});

test('prompt documents Case 4 food_log (ru + en) and when/days', () => {
  const p = buildSystemPrompt('app', null, 'en');
  assert.match(p, /Case 4/);
  assert.match(p, /"type":"food_log"/);
  assert.match(p, /я съел/i);
  assert.match(p, /I (had|ate)/);
  assert.match(p, /50 g/);
  assert.match(p, /"when":"today"/);
  assert.match(p, /на сегодня/);
  assert.match(p, /bugun uchun/);
  assert.match(p, /para hoy/);
});

test('looksLikeFoodLog: past-tense eating in en/ru/uz/es', () => {
  const { looksLikeFoodLog } = require('./fallback');
  for (const t of [
    'я съел 200 г курицы и 150 г риса',
    'ikki tuxum yedim',
    'comí 100 g de arroz',
    'I had 2 eggs and toast',
    'на завтрак съела два яйца и бутерброд',
    'I ate a banana',
    'Hoy desayuné 2 huevos',
    'tushlikda 200 g guruch yedim',
    'выпил 300 мл молока',
    'на обед был плов 300г',
  ]) assert.equal(looksLikeFoodLog(t), true, t);
  for (const t of [
    'what should I eat?',
    'сколько белка в курице?',
    'составь план питания',
    'give me a recipe with 2 eggs',
    'I had a great workout',
    'I did 3 sets of squats',
    'я съел бы что-нибудь, посоветуй',
    'can I eat 200 g of rice after training?',
    'qancha oqsil bor tuxumda?',
    '¿qué debo comer?',
    'make a meal plan for the week',
    '',
    null,
  ]) assert.equal(looksLikeFoodLog(t), false, String(t));
});

test('food_log fallback: user message triggers the schema call', async () => {
  fallbackRequests.length = 0;
  fallbackFoodMode = true;
  const events = await ndjson(await post('/chat/stream', { message: 'I had 2 eggs and toast', conversationId: 'fl1', history: [] }));
  fallbackFoodMode = false;
  assert.equal(fallbackRequests.length, 1);
  assert.ok(fallbackRequests[0].format.properties.items);
  assert.equal(fallbackRequests[0].messages.at(-1).content, 'I had 2 eggs and toast');
  const a = events.find((e) => e.action).action;
  assert.equal(a.type, 'food_log');
  assert.equal(a.slot, null);
  assert.equal(a.items[0].name, 'egg');
});

// ---- live-test fixes: weight fallback, schedule inference, prompt honesty ----

test('looksLikeWeightChange: statements yes, questions/unrelated no', () => {
  const { looksLikeWeightChange } = require('./fallback');
  for (const t of [
    'я набрал 3 кг', 'похудел на 2 кг', 'я вешу 82 кг', 'скинула 4 кг', 'теперь мой вес 70 кг',
    'I gained 3 kg', 'I lost 6 lb', "I'm 82 kg now", 'I weigh 80 kg', 'I put on 2 kg',
    '3 kg ga ozdim', 'vaznim 75 kg', '2 kg semirdim',
    'subí 3 kg', 'bajé 2 kg', 'mi peso es 70 kg', 'engordé 3 kg',
  ]) assert.equal(looksLikeWeightChange(t), true, t);
  for (const t of [
    'сколько мне весить?', 'how much should I weigh', 'lost my keys', 'I lost my motivation',
    'как быстро набрать 3 кг?', 'я съел 200 г курицы', 'жим 80 кг', '', null,
  ]) assert.equal(looksLikeWeightChange(t), false, String(t));
});

test('inferSchedule: when and days from the user message', () => {
  const { inferSchedule } = require('./actions');
  const plan = (n) => ({ type: 'workout_plan', sport: 'gym', templates: Array.from({ length: n }, (_, i) => tpl('S' + i)) });
  assert.equal(inferSchedule(plan(1), 'составь план тренировки на сегодня').when, 'today');
  assert.deepEqual(inferSchedule(plan(1), 'plan for today').days, ['today']);
  for (const t of ['bugun uchun mashq', 'plan para hoy']) assert.equal(inferSchedule(plan(1), t).when, 'today', t);
  const w = inferSchedule(plan(3), 'составь план тренировок на неделю, пн ср пт');
  assert.equal(w.when, 'week');
  assert.deepEqual(w.days, ['mon', 'wed', 'fri']);
  assert.deepEqual(inferSchedule(plan(2), 'plan for the week: tuesday and saturday').days, ['tue', 'sat']);
  assert.deepEqual(inferSchedule(plan(2), 'haftaga, dushanba va juma').days, ['mon', 'fri']);
  assert.deepEqual(inferSchedule(plan(2), 'para la semana, lunes y jueves').days, ['mon', 'thu']);
  assert.deepEqual(inferSchedule(plan(2), 'на неделю: вторник и воскресенье').days, ['tue', 'sun']);
  // count mismatch: no days
  assert.equal(inferSchedule(plan(2), 'на неделю пн ср пт').days, undefined);
  // today with 2 templates: when stays unset
  assert.equal(inferSchedule(plan(2), 'на сегодня').when, undefined);
  // model's own values are kept
  const own = { ...plan(1), when: 'week' };
  assert.equal(inferSchedule(own, 'на сегодня').when, 'week');
  // non-plans pass through
  const wt = { type: 'weight', mode: 'set', kg: 80 };
  assert.deepEqual(inferSchedule(wt, 'на сегодня'), wt);
  assert.equal(inferSchedule(null, 'x'), null);
});

test('prompt: no English-only invitation, no claims of changes, catalog names, egg math', () => {
  const p = buildSystemPrompt('gym', null, 'ru');
  assert.doesNotMatch(p, /Tap the button below/);
  assert.match(p, /never say .*already/i);
  assert.match(p, /Bench press/);
  assert.match(p, /ikki tuxum/);
  assert.match(p, /100 g/);
  assert.match(p, /not weekday names/i);
});

test('weight fallback: user message recovers a missing weight block', async () => {
  fallbackRequests.length = 0;
  fallbackWeightMode = true;
  const events = await ndjson(await post('/chat/stream', { message: 'я набрал 3 кг', conversationId: 'wf1', history: [] }));
  fallbackWeightMode = false;
  assert.equal(fallbackRequests.length, 1);
  assert.deepEqual(events.find((e) => e.action).action, { type: 'weight', mode: 'delta', kg: 3 });
});

test('refineAction: food slot only when the user said it; schedule still applied', () => {
  const { refineAction } = require('./actions');
  assert.equal(refineAction(food({ slot: 'breakfast' }), 'ikki tuxum yedim').slot, null);
  for (const t of ['на обед был плов 300г', 'for lunch I had rice', 'tushlikda guruch yedim', 'cené arroz', 'позавтракал яйцами'])
    assert.equal(refineAction(food({ slot: 'lunch' }), t).slot, 'lunch', t);
  assert.equal(refineAction(food({ slot: null }), 'на обед рис').slot, null);
  const p = refineAction({ type: 'workout_plan', sport: 'gym', templates: [tpl()] }, 'на сегодня');
  assert.equal(p.when, 'today');
  assert.equal(refineAction(null, 'x'), null);
});

test('looksLikePlan: four set/rep lines without headers is still a workout plan', () => {
  const { looksLikePlan } = require('./fallback');
  const t = 'Понедельник, среда, пятница:\n1. Жим лежа – 4 подхода по 8-10 повторений\n2. Тяга штанги – 4 подхода по 8-10\n3. Отжимания – 3 подхода по 12-15\n4. Планка – 3 подхода';
  assert.equal(looksLikePlan(t), 'workout_plan');
  assert.equal(looksLikePlan('Сделай 3 подхода приседаний.'), null);
});

test('refineAction: egg count words multiply a single-egg item', () => {
  const { refineAction } = require('./actions');
  const egg = { type: 'food_log', slot: null, items: [{ name: 'egg', grams: 50, kcal: 70, protein: 6.5, carbs: 0.6, fat: 5.4 }] };
  for (const t of ['ikki tuxum yedim', 'я съел два яйца', 'I had 2 eggs', 'comí dos huevos', '3 ta tuxum yedim']) {
    const n = /3/.test(t) ? 3 : 2;
    const it = refineAction(egg, t).items[0];
    assert.equal(it.grams, 50 * n, t);
    assert.equal(it.kcal, 70 * n, t);
  }
  assert.equal(refineAction(egg, 'I had an egg').items[0].grams, 50);
  const done = { ...egg, items: [{ ...egg.items[0], grams: 100 }] };
  assert.equal(refineAction(done, 'I had 2 eggs').items[0].grams, 100);
});

test('inferSchedule: named days alone schedule the week when they match the plan', () => {
  const { inferSchedule } = require('./actions');
  const plan = (n) => ({ type: 'workout_plan', sport: 'gym', templates: Array.from({ length: n }, (_, i) => tpl('S' + i)) });
  const ru = inferSchedule(plan(3), 'составь план на пн ср пт');
  assert.equal(ru.when, 'week');
  assert.deepEqual(ru.days, ['mon', 'wed', 'fri']);
  const en = inferSchedule(plan(3), '3-day split, Monday Wednesday Friday');
  assert.equal(en.when, 'week');
  assert.deepEqual(en.days, ['mon', 'wed', 'fri']);
  // count mismatch and no week word: nothing inferred
  const mism = inferSchedule(plan(2), 'составь план на пн ср пт');
  assert.equal(mism.when, undefined);
  assert.equal(mism.days, undefined);
  // the model's own "today" is kept
  const own = { ...plan(1), when: 'today', days: ['today'] };
  assert.deepEqual(inferSchedule(own, 'на понедельник'), own);
});

test('inferSchedule: a single plan for today wins over a week word', () => {
  const { inferSchedule } = require('./actions');
  const plan = (n) => ({ type: 'workout_plan', sport: 'gym', templates: Array.from({ length: n }, (_, i) => tpl('S' + i)) });
  const p = inferSchedule(plan(1), 'план на сегодня, тренируюсь 3 раза в неделю');
  assert.equal(p.when, 'today');
  assert.deepEqual(p.days, ['today']);
  assert.equal(inferSchedule(plan(1), "today's workout, I train 4 times a week").when, 'today');
  // several templates: still the week
  assert.equal(inferSchedule(plan(3), 'на сегодня и на неделю').when, 'week');
});

test('refineAction: weight delta sign follows the user words', () => {
  const { refineAction } = require('./actions');
  const d = (kg) => ({ type: 'weight', mode: 'delta', kg });
  for (const t of ['похудел на 2 кг', 'я похудела на 2 кг', 'скинул 2 кг', 'скинула 2кг', 'сбросил 2 кг', 'сбросила 2 кг',
    'I lost 2 kg', '2 kg ozdim', 'bajé 2 kg', 'adelgacé 2 kg', 'perdí 2 kg']) {
    assert.deepEqual(refineAction(d(2), t), d(-2), t);
    assert.deepEqual(refineAction(d(-2), t), d(-2), t);
  }
  for (const t of ['набрал 2 кг', 'набрала 2 кг', 'поправился на 2 кг', 'I gained 2 kg', 'put on 2 kg', '2 kg semirdim', 'subí 2 kg', 'engordé 2 kg']) {
    assert.deepEqual(refineAction(d(-2), t), d(2), t);
    assert.deepEqual(refineAction(d(2), t), d(2), t);
  }
  // no direction word, or both: unchanged
  assert.deepEqual(refineAction(d(-2), 'вес минус 2 кг'), d(-2));
  assert.deepEqual(refineAction(d(2), 'похудел, потом набрал 2 кг'), d(2));
  // set mode untouched
  const set = { type: 'weight', mode: 'set', kg: 80 };
  assert.deepEqual(refineAction(set, 'похудел до 80 кг'), set);
});

// ---- live fix: compact plans, unrequested plans in nutrition/recovery ----

test('looksLikePlan: compact one-session-per-line plan is a workout plan', () => {
  const { looksLikePlan } = require('./fallback');
  const t =
    '1. Верх тела - Bench press 4x8, Barbell row 4x8, Dumbbell fly 3x12\n' +
    '2. Низ тела - Squat 4x8, Lunge 3x12, Calf raise 3x15\n' +
    '3. Всё тело - Deadlift 3x5, Pull-up 3x8, Plank 3x1';
  assert.equal(looksLikePlan(t), 'workout_plan');
  assert.equal(looksLikePlan('Bench press 4x8, Row 4x8, Fly 3x12, Curl 3x12'), null);
});

test('asksForWorkoutPlan: plan requests yes, advice questions no', () => {
  const { asksForWorkoutPlan } = require('./fallback');
  for (const s of [
    'Составь мне сплит на 3 дня', 'Распиши программу на неделю', 'Make me a 4-day split',
    'plan for today', 'Bugun uchun mashg‘ulot rejasi', 'Hazme una rutina',
  ]) assert.equal(asksForWorkoutPlan(s), true, s);
  for (const s of [
    'Могу ли я сегодня тренироваться тяжело?', 'How hard should I train today?', 'Сколько белка мне нужно?',
  ]) assert.equal(asksForWorkoutPlan(s), false, s);
});

async function actionEvents(topic, message, id) {
  const events = await ndjson(await post('/chat/stream', { message, conversationId: id, history: [], topic }));
  return events.filter((e) => e.action);
}

test('stream: recovery drops an unrequested workout_plan, keeps a requested one', async () => {
  assert.equal((await actionEvents('recovery', 'Can I train hard today?', 'lf1')).length, 0);
  assert.equal((await actionEvents('recovery', 'Make me a recovery workout plan', 'lf2')).length, 1);
  assert.equal((await actionEvents('gym', 'Can I train hard today?', 'lf3')).length, 1);
});

test('non-stream: recovery drops an unrequested workout_plan', async () => {
  const j = await (await post('/chat', { message: 'Can I train hard today?', conversationId: 'lf4', history: [], topic: 'nutrition' })).json();
  assert.equal(j.action, undefined);
  const k = await (await post('/chat', { message: 'Make me a recovery workout plan', conversationId: 'lf5', history: [], topic: 'recovery' })).json();
  assert.equal(k.action.type, 'workout_plan');
});

test('looksLikePlan: compact rule needs numeric NxM, 3+ per line on 2+ lines', () => {
  const { looksLikePlan } = require('./fallback');
  assert.equal(looksLikePlan('Try 3x10 vs 5x5 today.\nOr 4x8 and 2x12.'), null);
  assert.equal(looksLikePlan('3 sets of squats. 2 sets of rows.\n4 sets of curls. 5 sets of fly.'), null);
  assert.equal(looksLikePlan('3 подхода жима, 2 подхода тяги.\n3 подхода приседа, 2 подхода выпадов.'), null);
});

test('asksForWorkoutPlan: false positives and misses', () => {
  const { asksForWorkoutPlan } = require('./fallback');
  for (const s of [
    'Можно ли мне сегодня на тренировку?', 'Should I skip my workout today?', 'Is my session today too heavy?',
    'Составь план питания', 'Make me a meal plan', 'Можно ли делать планку?', 'Я планирую отдых',
    'Make a diet plan', 'Plan de comidas por favor', 'Ovqat rejasi tuzib ber',
  ]) assert.equal(asksForWorkoutPlan(s), false, s);
  for (const s of [
    'Can you make me a recovery workout?', 'Составьте мне план тренировки', 'Распишите программу',
    'Give me some recovery workouts', 'Hazme unas rutinas', 'Tiklanish dasturini tuzib ber',
  ]) assert.equal(asksForWorkoutPlan(s), true, s);
});

test('recovery: unrequested plan-looking reply makes no extraction call', async () => {
  fallbackRequests.length = 0;
  const events = await ndjson(await post('/chat/stream', { message: 'recplan please', conversationId: 'lf6', history: [], topic: 'recovery' }));
  assert.ok(!events.some((e) => e.action));
  assert.equal(fallbackRequests.length, 0);
});

test('recovery: previous user request makes a follow-up count as requested', async () => {
  const events = await ndjson(await post('/chat/stream', {
    message: '20 минут', conversationId: 'lf7', topic: 'recovery',
    history: [
      { role: 'user', content: 'Составь восстановительную тренировку' },
      { role: 'assistant', content: 'На сколько минут?' },
    ],
  }));
  assert.equal(events.filter((e) => e.action).length, 1);
});
