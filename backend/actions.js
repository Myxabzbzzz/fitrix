// Felix "actions": the model appends one <fitrix-action>{JSON}</fitrix-action>
// block after its visible text. This module hides that block from the
// streamed text, then parses and strictly validates it. Invalid actions are
// dropped (null), never repaired beyond unit normalisation.

const OPEN_TAG = '<fitrix-action';
const CLOSE_TAG = '</fitrix-action>';

const SPORTS = ['gym', 'fitness', 'cycling', 'running', 'football', 'winterSports'];
const SLOTS = ['breakfast', 'lunch', 'dinner', 'snack'];
const DAYS = ['today', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const LB_TO_KG = 0.4536;
const FENCE_TAIL = /[ \t]*`{1,3}[a-zA-Z]*[ \t]*\n?[ \t]*$/;

const round1 = (n) => Math.round(n * 10) / 10;
const isNum = (v) => typeof v === 'number' && Number.isFinite(v);
const isInt = (v, min, max) => Number.isInteger(v) && v >= min && v <= max;
const isText = (v, max) => typeof v === 'string' && v.trim().length > 0 && v.trim().length <= max;

/**
 * Splits streamed text into visible text and the action block. Anything from
 * "<fitrix-action" on is held back, even when the tag is split across chunks.
 *   push(chunk) -> visible text to emit now
 *   flush()     -> visible text still held back at the end
 *   block()     -> raw text of the action block (or null if none appeared)
 */
function createActionFilter() {
  let held = '';
  let firstBlock = null;
  let openBlock = null; // text of the block being read, once its tag opened
  let afterBlock = false; // a block just closed; next text starts a new line
  let emitted = false; // any visible text sent yet

  function visibleText(text) {
    if (!text) return '';
    emitted = true;
    return text;
  }

  return {
    push(chunk) {
      let text = held + chunk;
      held = '';
      let out = '';
      for (;;) {
        if (openBlock !== null) {
          // Inside a block: swallow until the closing tag; models sometimes
          // put a closing sentence after it, which is shown as normal text.
          const from = Math.max(0, openBlock.length - (CLOSE_TAG.length - 1));
          openBlock += text;
          const end = openBlock.indexOf(CLOSE_TAG, from);
          if (end < 0) return out;
          text = openBlock.slice(end + CLOSE_TAG.length);
          if (firstBlock === null) firstBlock = openBlock.slice(0, end + CLOSE_TAG.length);
          openBlock = null;
          afterBlock = true;
          continue;
        }
        if (afterBlock) {
          // The text before the block was trimmed; separate it from what follows.
          text = text.trimStart();
          if (/^`{1,2}$/.test(text)) {
            held = text; // maybe the start of a closing fence
            return out;
          }
          text = text.replace(/^```[a-zA-Z]*[ \t]*\n?/, '').trimStart();
          if (text) {
            afterBlock = false;
            if (emitted) text = '\n' + text;
          }
        }
        const at = text.indexOf(OPEN_TAG);
        if (at >= 0) {
          // A code fence line right before the block is dropped with it.
          out += visibleText(text.slice(0, at).replace(FENCE_TAIL, '').trimEnd());
          openBlock = text.slice(at);
          text = '';
          const end = openBlock.indexOf(CLOSE_TAG);
          if (end < 0) return out;
          text = openBlock.slice(end + CLOSE_TAG.length);
          if (firstBlock === null) firstBlock = openBlock.slice(0, end + CLOSE_TAG.length);
          openBlock = null;
          afterBlock = true;
          continue;
        }
        // Keep a trailing partial "<fitrix-act…" until we know what it is.
        let keep = 0;
        for (let n = Math.min(OPEN_TAG.length - 1, text.length); n > 0; n--) {
          if (OPEN_TAG.startsWith(text.slice(text.length - n))) {
            keep = n;
            break;
          }
        }
        // Trailing whitespace is held too, so a newline before a block never
        // leaks out as a trailing blank line.
        let safe = text.slice(0, text.length - keep);
        // A trailing code fence line may belong to a block that follows.
        const fence = FENCE_TAIL.exec(safe);
        if (fence) {
          keep += safe.length - fence.index;
          safe = safe.slice(0, fence.index);
        }
        const visible = safe.trimEnd();
        held = text.slice(visible.length);
        return out + visibleText(visible);
      }
    },
    flush() {
      const rest = held.trimEnd();
      held = '';
      return rest;
    },
    /** Raw text of the first complete block (null if none, or unterminated). */
    block() {
      return firstBlock;
    },
    /** True when a block tag appeared at all, even if never closed. */
    sawBlock() {
      return firstBlock !== null || openBlock !== null;
    },
  };
}

/** Parses the raw block and returns a validated action, or null. */
function parseAction(block, opts) {
  if (typeof block !== 'string') return null;
  const start = block.indexOf('>');
  const end = block.indexOf(CLOSE_TAG);
  if (start < 0 || end < start) return null;
  const json = block.slice(start + 1, end).trim();
  let raw;
  try {
    raw = JSON.parse(json);
  } catch {
    // Small models often forget the comma between two adjacent objects
    // ("}{"), which is never valid JSON. That is the only repair we make.
    try {
      raw = JSON.parse(json.replace(/\}\s*\{"/g, '},{"'));
    } catch {
      return null;
    }
  }
  return validateAction(raw, opts);
}

/** Validates one action object; returns the normalised shape or null. */
function validateAction(raw, { defaultSport } = {}) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  switch (raw.type) {
    case 'weight':
      return validateWeight(raw);
    case 'workout_plan':
      return validateWorkoutPlan(raw, defaultSport);
    case 'meal_plan':
      return validateMealPlan(raw);
    case 'food_log':
      return validateFoodLog(raw);
    default:
      return null;
  }
}

/**
 * Numbers as models write them: 8, "8", "8-12" (-> 8), "62,5". Anything
 * else is returned unchanged and fails validation.
 */
function coerceNumber(value) {
  if (typeof value !== 'string') return value;
  const m = /^\s*(\d+(?:[.,]\d+)?)\s*(?:[-\u2013\u2014]\s*\d+(?:[.,]\d+)?)?\s*$/.exec(value);
  return m ? Number(m[1].replace(',', '.')) : value;
}

function validateWeight(raw) {
  if (raw.mode !== 'set' && raw.mode !== 'delta') return null;
  // The model sends amount+unit; a plain kg value is accepted too.
  let amount = raw.amount;
  let unit = raw.unit;
  if (amount === undefined && raw.kg !== undefined) {
    amount = raw.kg;
    unit = 'kg';
  }
  if (!isNum(amount)) return null;
  if (unit === undefined || unit === null) unit = 'kg';
  if (typeof unit !== 'string') return null;
  unit = unit.toLowerCase();
  let kg;
  if (unit === 'kg') kg = round1(amount);
  else if (unit === 'lb' || unit === 'lbs') kg = round1(amount * LB_TO_KG);
  else return null;

  if (raw.mode === 'set') {
    if (kg < 20 || kg > 400) return null;
  } else if (kg === 0 || kg < -50 || kg > 50) {
    return null;
  }
  return { type: 'weight', mode: raw.mode, kg };
}

function validateWorkoutPlan(raw, defaultSport) {
  // In a sport chat the chat's sport stands in for a missing/invalid one.
  const sport = SPORTS.includes(raw.sport) ? raw.sport : defaultSport;
  if (!SPORTS.includes(sport)) return null;
  const { templates } = raw;
  if (!Array.isArray(templates) || templates.length < 1 || templates.length > 7) return null;
  const out = [];
  for (const t of templates) {
    if (!t || typeof t !== 'object' || !isText(t.name, 100)) return null;
    if (!Array.isArray(t.exercises) || t.exercises.length < 1 || t.exercises.length > 12) {
      return null;
    }
    const exercises = [];
    for (const e of t.exercises) {
      if (!e || typeof e !== 'object' || !isText(e.name, 100)) return null;
      const sets = coerceNumber(e.sets);
      const reps = coerceNumber(e.reps);
      if (!isInt(sets, 1, 10) || !isInt(reps, 1, 100)) return null;
      const exercise = { name: e.name.trim(), sets, reps };
      if (e.kg !== undefined && e.kg !== null) {
        const kg = coerceNumber(e.kg);
        if (!isNum(kg) || kg < 0 || kg > 500) return null;
        exercise.kg = round1(kg);
      }
      exercises.push(exercise);
    }
    out.push({ name: t.name.trim(), exercises });
  }
  const plan = { type: 'workout_plan', sport, templates: out };
  // Optional scheduling hints; absent/null keeps the old behaviour.
  if (raw.when !== undefined && raw.when !== null) {
    if (raw.when !== 'today' && raw.when !== 'week') return null;
    if (raw.when === 'today' && out.length !== 1) return null;
  }
  if (raw.when !== undefined) plan.when = raw.when;
  if (raw.days !== undefined && raw.days !== null) {
    if (!Array.isArray(raw.days) || raw.days.length !== out.length) return null;
    if (!raw.days.every((d) => DAYS.includes(d))) return null;
    plan.days = [...raw.days];
  }
  return plan;
}

function validateFoodLog(raw) {
  let slot = raw.slot === undefined ? null : raw.slot;
  if (slot !== null && !SLOTS.includes(slot)) return null;
  const { items } = raw;
  if (!Array.isArray(items) || items.length < 1 || items.length > 15) return null;
  const out = [];
  for (const it of items) {
    if (!it || typeof it !== 'object' || !isText(it.name, 100)) return null;
    const grams = coerceNumber(it.grams);
    const kcal = coerceNumber(it.kcal);
    const protein = coerceNumber(it.protein);
    const carbs = coerceNumber(it.carbs);
    const fat = coerceNumber(it.fat);
    if (!isNum(grams) || grams < 1 || grams > 3000) return null;
    if (!isNum(kcal) || kcal < 0 || kcal > 3000) return null;
    for (const m of [protein, carbs, fat]) {
      if (!isNum(m) || m < 0 || m > 500) return null;
    }
    out.push({
      name: it.name.trim(),
      grams: round1(grams),
      kcal: Math.round(kcal),
      protein: round1(protein),
      carbs: round1(carbs),
      fat: round1(fat),
    });
  }
  return { type: 'food_log', slot, items: out };
}

function validateMealPlan(raw) {
  const { meals } = raw;
  if (!Array.isArray(meals) || meals.length < 1 || meals.length > 8) return null;
  const out = [];
  for (const m of meals) {
    if (!m || typeof m !== 'object' || !isText(m.name, 100) || !isText(m.items, 200)) {
      return null;
    }
    if (!isNum(m.kcal) || m.kcal < 0 || m.kcal > 3000) return null;
    out.push({ name: m.name.trim(), items: m.items.trim(), kcal: Math.round(m.kcal) });
  }
  return { type: 'meal_plan', meals: out };
}

/** Non-streaming helper: { text, action, hadBlock } from a full reply. */
function extractAction(content, opts) {
  const filter = createActionFilter();
  const text = filter.push(content) + filter.flush();
  const block = filter.block();
  return { text, action: parseAction(block, opts), hadBlock: filter.sawBlock() };
}

module.exports = {
  createActionFilter,
  parseAction,
  validateAction,
  extractAction,
  SPORTS,
};
