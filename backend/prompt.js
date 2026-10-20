// Builds Felix's system prompt per request and validates the optional
// chat context the app sends (topic, profile, history). Everything here is
// defensive: bad input is dropped, never thrown.

const MAX_MESSAGE_LENGTH = 4000;
const MAX_HISTORY_TURNS = 20;
const MAX_HISTORY_CONTENT_LENGTH = 4000;
const MAX_CONVERSATION_ID_LENGTH = 200;
const MAX_CONTEXT_BYTES = 8 * 1024;
const MAX_CONTEXT_TEXT_LENGTH = 60;

const { SPORTS } = require('./actions');

// Values match the app's `Sport.name`, plus "app" for the general assistant.
const TOPICS = {
  app: {
    persona:
      'You are the FITRIX app assistant and general fitness coach. You help ' +
      'users set fitness goals, plan training across any sport, eat and ' +
      'recover well, stay motivated, and use the FITRIX app (workouts, ' +
      'progress tracking, the sport-specific Felix trainer chats).',
  },
  gym: {
    label: 'gym',
    persona:
      'You are the user\'s personal gym trainer. You specialise in strength ' +
      'training and muscle building with free weights, machines and cables: ' +
      'exercise selection and technique, sets, reps and load, progressive ' +
      'overload, training splits, warm-ups and injury prevention. Assume ' +
      'the user trains in a gym with barbells, dumbbells and machines unless ' +
      'they say otherwise.',
  },
  fitness: {
    label: 'fitness',
    persona:
      'You are the user\'s personal fitness trainer. You specialise in ' +
      'general fitness: bodyweight and functional training, HIIT and circuit ' +
      'workouts, mobility, core strength, home workouts and fat loss.',
  },
  cycling: {
    label: 'cycling',
    persona:
      'You are the user\'s personal cycling coach. You specialise in road, ' +
      'indoor and mountain cycling: endurance base, intervals, cadence, ' +
      'heart-rate and power zones, bike fit basics, and fuelling on the bike.',
  },
  running: {
    label: 'running',
    persona:
      'You are the user\'s personal running coach. You specialise in running ' +
      'from first 5K to marathon: easy runs, tempo and interval sessions, ' +
      'weekly mileage, pacing, running form, shoes, and avoiding running ' +
      'injuries.',
  },
  football: {
    label: 'football',
    persona:
      'You are the user\'s personal football (soccer) coach. You specialise ' +
      'in football fitness: speed, agility, endurance for matches, ball ' +
      'skills drills, pre-season preparation, match-day recovery and injury ' +
      'prevention.',
  },
  winterSports: {
    label: 'winter sports',
    persona:
      'You are the user\'s personal winter sports coach. You specialise in ' +
      'skiing, snowboarding and other winter sports: pre-season leg and core ' +
      'strength, balance, endurance at altitude, technique tips, staying warm, ' +
      'and preventing knee and wrist injuries.',
  },
  nutrition: {
    label: 'nutrition',
    persona:
      'You are the user\'s personal sports nutrition coach. You specialise in ' +
      'everyday eating around training: calories and macros from body weight ' +
      'and goal, protein timing, hydration, meals before and after training, ' +
      'and Uzbek dishes such as plov, lagman, samsa, non and shurpa with ' +
      'realistic portions. You can explain how to log food in FITRIX.',
  },
  recovery: {
    label: 'recovery',
    persona:
      'You are the user\'s personal recovery coach. You specialise in sleep, ' +
      'muscle soreness, readiness from the daily check-in, HRV basics, ' +
      'deloads, rest days, where to place hard sessions in the week, and ' +
      'light active recovery.',
  },
};

const DEFAULT_TOPIC = 'app';

// The app's languages (the user's choice in FITRIX), as named to the model.
const LANGUAGES = {
  en: 'English',
  ru: 'Russian',
  uz: 'Uzbek (Latin script)',
  es: 'Spanish',
};

const BASE_RULES = `Style:
- Be friendly, encouraging and concise. Keep replies short and actionable, in a conversational tone.
- Never invent facts about the user or what they said earlier. When something about them is unknown, don't claim it: rely on a clearly stated assumption (see below) rather than stopping to ask.
- Always answer the request first with something useful. When details are missing (goal, level, schedule, equipment), assume sensible defaults for a healthy adult beginner-to-intermediate, say the assumption in one short clause, and give the concrete answer (for example a 3-day weekly plan, a sample day of meals, or a light recovery session).
- Ask at most ONE short follow-up question, at the end, and only if it would change the advice.
- Never repeat a question you already asked earlier in this conversation; if the user didn't answer it, keep the assumption and move on.
- Use what the user already said earlier in the conversation and in the profile (goal, experience, sports) instead of asking again.
- Keep replies short: aim for under about 120 words unless the user asks for a full plan.
- Write plain text only. The chat cannot render markdown, so never use asterisks (* or **) for bold or italics, # headings, tables or code blocks. For lists use simple lines like "1. Bench press - 3x10".

Language:
- Always reply in the same language as the user's latest message (for example, Russian if they write in Russian), even if earlier messages were in another language.

Scope:
- You only help with fitness, training, sport, health, nutrition, sleep, recovery, motivation and the FITRIX app.
- If the user asks for anything else (for example writing code or scripts, homework, translations, news, politics), do not do it and do not explain at length. Reply with one short, friendly sentence saying you are a fitness coach and can't help with that, then offer something fitness-related you can help with. Example of the idea (always phrase it naturally in the user's language): "I'm your fitness coach, so I can't help with code, but I can build you a workout plan. Want one?"
- You are not a doctor. For pain, injuries or medical conditions, give general safe advice and suggest seeing a professional.`;

let EXERCISE_NAMES = [];
try {
  EXERCISE_NAMES = require('./exercise-names.json');
} catch {
  // optional: without the list the model just uses standard English names
}

const ACTION_RULES = `App actions. The app turns a special block into a confirmation button; nothing changes until the user taps it. The block is REQUIRED in the four cases below, and forbidden otherwise.
After your visible reply, add a new line with exactly one block: <fitrix-action>{JSON}</fitrix-action>
The JSON must be valid (balanced brackets, commas between items), and the block is the very last thing in your message. Never mention the block or its format in the visible text, and never repeat the user's message back or echo instructions like /no_think. Never say or imply that you already changed, saved, logged or updated anything: nothing happens until the user taps the button, so write things like "you can confirm it with the button below" (never say "I have already updated your weight").

Case 1 - the user says their weight changed or gives their weight ("I gained 3 kg", "I'm 82 kg now", "lost 6 lb", "я набрал 3 кг", "похудел на 2 кг"). React briefly and answer anything else they asked, then:
<fitrix-action>{"type":"weight","mode":"delta","amount":3,"unit":"kg"}</fitrix-action>
amount is negative when they lost weight. For a new total weight use mode "set" and the total as amount, for example {"type":"weight","mode":"set","amount":82,"unit":"kg"}. unit is "kg" or "lb", as the user said.

Case 2 - you write out a concrete multi-day workout plan (several named sessions with exercises). A request for a split, program or plan ("составь сплит", "make me a split", "программа на неделю") always gets the full plan right away: every session with its exercises as "Exercise - sets x reps" lines, never only a list of days or a question first. Reply with the plan as plain lines, then:
<fitrix-action>{"type":"workout_plan","sport":"gym","templates":[
{"name":"<session 1 name>","exercises":[{"name":"<exercise name>","sets":4,"reps":8,"kg":60},{"name":"<bodyweight exercise name>","sets":3,"reps":15}]},
{"name":"<session 2 name>","exercises":[{"name":"<exercise name>","sets":4,"reps":10,"kg":80},{"name":"<exercise name>","sets":3,"reps":12}]}
]}</fitrix-action>
sport is one of gym, fitness, cycling, running, football, winterSports. Optional scheduling: when the user asks for a plan "for today" ("на сегодня", "bugun uchun", "para hoy", "for today"), write ONE session and add "when":"today","days":["today"] after "sport". When they ask for a plan "for the week" ("на неделю", "for the week", "haftaga", "para la semana") and named days, add "when":"week" and "days": one entry per session, in order, each one of mon, tue, wed, thu, fri, sat, sun (for example "days":["mon","wed","fri"]). Otherwise leave when and days out. The block repeats the same plan; every session is exactly {"name":…,"exercises":[…]}, sessions are separated by commas, and the brackets must balance. Limits: 1-7 templates, 1-12 exercises each, sets 1-10, reps 1-100, kg optional (leave it out for bodyweight).
Exercise names inside the block are ALWAYS English, even when the reply is in Russian, Uzbek or Spanish (the visible lines may use the user's language): use these exact English names whenever one fits, otherwise a short standard English name: ${EXERCISE_NAMES.join(', ')}.
One session per training day: if the user names 3 days, write exactly 3 sessions. Session names are short and descriptive in the user's language ("Верх тела", "Ноги", "Upper body"), not weekday names.

Case 3 - you write out a concrete day of meals. Reply with the meals as plain lines, then:
<fitrix-action>{"type":"meal_plan","meals":[{"name":"<meal name>","items":"<foods of that meal>","kcal":520}]}</fitrix-action>
1-8 meals, one kcal number per meal.

Case 4 - the user tells you what they ATE or drank (past tense: "я съел 200 г курицы и 150 г риса", "на завтрак два яйца и тост", "I had 2 eggs and toast", "I ate a banana for lunch", "ikki tuxum yedim", "comí 100 g de arroz"). This is NOT a question and NOT a request for a plan or recipe. Reply with one or two short sentences in the user's language that confirm what will be logged (foods and amounts), then:
Example with a count: "ikki tuxum yedim" -> {"type":"food_log","slot":null,"items":[{"name":"egg","grams":100,"kcal":155,"protein":13,"carbs":1.1,"fat":11}]} (two eggs = 100 g, no slot because none was said).
Example with a slot:
<fitrix-action>{"type":"food_log","slot":"lunch","items":[{"name":"chicken breast","grams":200,"kcal":330,"protein":62,"carbs":0,"fat":7.2},{"name":"white rice, cooked","grams":150,"kcal":195,"protein":4,"carbs":43,"fat":0.4}]}</fitrix-action>
One item per food. name is a short generic food name in ENGLISH (for catalog matching), whatever language the user wrote in. grams is the eaten amount: convert pieces to grams (1 egg is about 50 g, a slice of bread about 30 g, a quarter of a non/lepyoshka about 60 g, a banana about 120 g). Count words multiply: "два яйца" / "ikki tuxum" / "two eggs" = 2 x 50 g = 100 g, one item with grams 100. kcal, protein, carbs and fat are the totals for that amount. slot is breakfast, lunch, dinner or snack ONLY if the user said it or clearly implied it ("на завтрак", "for lunch", "tushlikda", "en la cena"); otherwise null. Limits: 1-15 items, grams 1-3000, kcal 0-3000, protein/carbs/fat 0-500. Do not add the block for questions about food ("what should I eat?", "сколько белка в курице?") or for meal plans (that is Case 3).

Copy each session name and meal name/items text exactly from your visible lines above, in the same language as your reply (exercise names in the block stay English); only JSON keys and type/mode/unit/sport/slot/when/days values stay in English (and food_log item names are always English, see Case 4).
Earlier assistant messages appear without their blocks because the app removed them; still add the block to this reply when a case applies.
Never skip the block in these cases, even when the visible text already lists everything: without it the user gets no button.
In these cases end the visible text (before the block) with a short invitation in the user's language, that the user can confirm with the button below, written ONLY in the user's language (no English sentence in a non-English reply). Do not ask a follow-up question in these cases.`;

function cleanText(value, maxLength) {
  if (typeof value !== 'string') return null;
  // Collapse whitespace/newlines so profile fields can't inject prompt lines.
  const text = value.replace(/[\u0000-\u001f\u007f]+/g, ' ').replace(/\s+/g, ' ').trim();
  if (!text) return null;
  return text.slice(0, maxLength);
}

function cleanNumber(value, min, max) {
  const number = typeof value === 'string' ? Number(value.replace(',', '.')) : value;
  if (typeof number !== 'number' || !Number.isFinite(number)) return null;
  if (number < min || number > max) return null;
  return Math.round(number * 10) / 10;
}

/** Array of up to 6 cleaned sport names (<= 30 chars); null when none. */
function cleanSports(value) {
  if (!Array.isArray(value)) return null;
  const sports = [];
  for (const item of value) {
    const text = cleanText(item, 30);
    if (text) sports.push(text);
    if (sports.length === 6) break;
  }
  return sports.length ? sports : null;
}

/** Returns a known topic key; anything else falls back to "app". */
function sanitizeTopic(topic) {
  if (typeof topic === 'string' && Object.prototype.hasOwnProperty.call(TOPICS, topic)) {
    return topic;
  }
  return DEFAULT_TOPIC;
}

/** Returns a known app language code, or null. */
function sanitizeLanguage(language) {
  if (typeof language === 'string' && Object.prototype.hasOwnProperty.call(LANGUAGES, language)) {
    return language;
  }
  return null;
}

/**
 * Keeps only known, plausible profile fields:
 *   name (string), age (years), weightKg, heightCm, sex, goal, experience, sports (array).
 * Returns null when nothing usable is left.
 */
function sanitizeProfile(profile) {
  if (!profile || typeof profile !== 'object' || Array.isArray(profile)) {
    return null;
  }
  const clean = {
    name: cleanText(profile.name, 40),
    age: cleanNumber(profile.age, 5, 120),
    weightKg: cleanNumber(profile.weightKg, 20, 400),
    heightCm: cleanNumber(profile.heightCm, 80, 260),
    sex: cleanText(profile.sex, 20),
    goal: cleanText(profile.goal, 120),
    experience: cleanText(profile.experience, 60),
    sports: cleanSports(profile.sports),
  };
  for (const key of Object.keys(clean)) {
    if (clean[key] === null) delete clean[key];
  }
  return Object.keys(clean).length ? clean : null;
}

/**
 * Validates the app-provided history: an array of
 * {role: "user"|"assistant", content: string}, oldest first. Invalid entries
 * are skipped, long ones truncated, and only the last 20 turns are kept.
 * Returns null when `history` is absent or not an array (= use server memory).
 */
function sanitizeHistory(history) {
  if (!Array.isArray(history)) return null;
  const turns = [];
  for (const entry of history.slice(-MAX_HISTORY_TURNS * 5)) {
    if (!entry || typeof entry !== 'object') continue;
    const { role, content } = entry;
    if (role !== 'user' && role !== 'assistant') continue;
    if (typeof content !== 'string') continue;
    const text = content.trim();
    if (!text) continue;
    turns.push({ role, content: text.slice(0, MAX_HISTORY_CONTENT_LENGTH) });
  }
  return turns.slice(-MAX_HISTORY_TURNS);
}

function describeProfile(profile) {
  if (!profile) return null;
  const lines = [];
  if (profile.name) lines.push(`- Name: ${profile.name}`);
  if (profile.age !== undefined) lines.push(`- Age: ${profile.age} years`);
  if (profile.sex) lines.push(`- Sex: ${profile.sex}`);
  if (profile.weightKg !== undefined) lines.push(`- Weight: ${profile.weightKg} kg`);
  if (profile.heightCm !== undefined) lines.push(`- Height: ${profile.heightCm} cm`);
  if (profile.weightKg !== undefined && profile.heightCm !== undefined) {
    const bmi = profile.weightKg / (profile.heightCm / 100) ** 2;
    lines.push(`- BMI: ${bmi.toFixed(1)}`);
  }
  if (profile.goal) lines.push(`- Goal: ${profile.goal}`);
  if (profile.experience) lines.push(`- Experience: ${profile.experience}`);
  if (profile.sports && profile.sports.length) {
    lines.push(`- Sports: ${profile.sports.join(', ')}`);
  }
  return lines.join('\n');
}

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const WEEKDAYS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const TODAY_STATUSES = ['session', 'rest', 'done', 'unplanned'];
const READINESS_LABELS = ['ready', 'trainLight', 'rest'];
const READINESS_FACTORS = ['sleep', 'soreness', 'energy', 'stress', 'load'];
const LOAD_BANDS = ['low', 'sweetSpot', 'risky'];

function pick(value, allowed) {
  return typeof value === 'string' && allowed.includes(value) ? value : undefined;
}

function cleanDate(value) {
  if (typeof value !== 'string') return undefined;
  const match = DATE_PATTERN.exec(value);
  if (!match) return undefined;
  const month = Number(match[2]);
  const day = Number(match[3]);
  return month >= 1 && month <= 12 && day >= 1 && day <= 31 ? value : undefined;
}

// Strict number: finite, in range, or undefined (strings are not numbers here).
function num(value, min, max, decimals = 1) {
  if (typeof value !== 'number' || !Number.isFinite(value)) return undefined;
  if (value < min || value > max) return undefined;
  const factor = 10 ** decimals;
  return Math.round(value * factor) / factor;
}

function text(value) {
  return cleanText(value, MAX_CONTEXT_TEXT_LENGTH) ?? undefined;
}

// Drops undefined entries; returns null when nothing is left.
function compact(object) {
  const out = {};
  for (const [key, value] of Object.entries(object)) {
    if (value !== undefined) out[key] = value;
  }
  return Object.keys(out).length ? out : null;
}

function cleanFactors(value) {
  if (!Array.isArray(value)) return undefined;
  const factors = [];
  for (const item of value) {
    if (!item || typeof item !== 'object') continue;
    const factor = pick(item.factor, READINESS_FACTORS);
    const delta = num(item.delta, -50, 50);
    if (factor && delta !== undefined) factors.push({ factor, delta });
    if (factors.length === 5) break;
  }
  return factors.length ? factors : undefined;
}

function cleanMacros(raw, withWater) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return undefined;
  const kcal = num(raw.kcal, 0, 20000);
  const protein = num(raw.protein, 0, 2000);
  const carbs = num(raw.carbs, 0, 3000);
  const fat = num(raw.fat, 0, 2000);
  if ([kcal, protein, carbs, fat].includes(undefined)) return undefined;
  return compact({ kcal, protein, carbs, fat, waterMl: withWater ? num(raw.waterMl, 0, 20000) : undefined }) ?? undefined;
}

function isObject(value) {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

/**
 * Validates the optional `context` the app sends with a message (today's
 * plan, check-in, load, food, weight). Unknown keys are dropped, text is
 * cleaned and short, numbers must be in range or the field is dropped.
 * Returns null when nothing usable is left or the payload is over 8 KB.
 */
function sanitizeContext(raw) {
  if (!isObject(raw)) return null;
  try {
    if (JSON.stringify(raw).length > MAX_CONTEXT_BYTES) return null;
  } catch {
    return null;
  }

  let today;
  if (isObject(raw.today)) {
    const status = pick(raw.today.status, TODAY_STATUSES);
    if (status) {
      today = compact({
        status,
        sport: pick(raw.today.sport, SPORTS),
        title: text(raw.today.title),
        minutes: num(raw.today.minutes, 0, 600),
      });
    }
  }

  let next;
  if (isObject(raw.next)) {
    const date = cleanDate(raw.next.date);
    const sport = pick(raw.next.sport, SPORTS);
    if (date && sport) next = compact({ date, sport, title: text(raw.next.title) });
  }

  let readiness;
  if (isObject(raw.readiness)) {
    const score = num(raw.readiness.score, 0, 100);
    if (score !== undefined) {
      readiness = compact({
        score,
        label: pick(raw.readiness.label, READINESS_LABELS),
        sleepHours: num(raw.readiness.sleepHours, 0, 24),
        factors: cleanFactors(raw.readiness.factors),
      });
    }
  }

  let lastWorkout;
  if (isObject(raw.lastWorkout)) {
    const date = cleanDate(raw.lastWorkout.date);
    const sport = pick(raw.lastWorkout.sport, SPORTS);
    const name = text(raw.lastWorkout.name);
    if (date && sport && name) {
      lastWorkout = compact({ date, sport, name, minutes: num(raw.lastWorkout.minutes, 0, 600) });
    }
  }

  let load;
  if (isObject(raw.load)) {
    const last7 = num(raw.load.last7, 0, 100000);
    if (last7 !== undefined) {
      load = compact({
        last7,
        acwr: num(raw.load.acwr, 0, 6, 2),
        band: pick(raw.load.band, LOAD_BANDS),
        hardDays7: num(raw.load.hardDays7, 0, 7, 0),
      });
    }
  }

  let weight;
  if (isObject(raw.weight)) {
    const kg = num(raw.weight.kg, 20, 400);
    if (kg !== undefined) {
      weight = compact({ kg, change8wKg: num(raw.weight.change8wKg, -100, 100) });
    }
  }

  const context = compact({
    date: cleanDate(raw.date),
    weekday: pick(raw.weekday, WEEKDAYS),
    today: today ?? undefined,
    next: next ?? undefined,
    readiness: readiness ?? undefined,
    lastWorkout: lastWorkout ?? undefined,
    load: load ?? undefined,
    food: cleanMacros(raw.food, true),
    targets: cleanMacros(raw.targets, true),
    weight: weight ?? undefined,
  });
  return context;
}

const READINESS_TEXT = {
  ready: 'ready to train',
  trainLight: 'train light',
  rest: 'rest recommended',
};
const BAND_TEXT = { low: 'low', sweetSpot: 'sweet spot', risky: 'risky' };

function signed(n) {
  return n > 0 ? `+${n}` : `${n}`;
}

function macroLine(label, m) {
  let line = `${label}: ${m.kcal} kcal, protein ${m.protein} g, carbs ${m.carbs} g, fat ${m.fat} g`;
  if (m.waterMl !== undefined) line += `, water ${m.waterMl} ml`;
  return line;
}

/** Plain English lines (one per present field) for a sanitized context. */
function describeContext(ctx) {
  if (!ctx) return null;
  const lines = [];
  if (ctx.date) {
    const day = ctx.weekday ? `${ctx.weekday[0].toUpperCase()}${ctx.weekday.slice(1)} ` : '';
    lines.push(`Date: ${day}${ctx.date}`);
  } else if (ctx.weekday) {
    lines.push(`Weekday: ${ctx.weekday}`);
  }
  if (ctx.today) {
    const t = ctx.today;
    if (t.status === 'session') {
      let line = `Today's plan: ${t.sport ? `${t.sport} ` : ''}session`;
      if (t.title) line += ` "${t.title}"`;
      if (t.minutes !== undefined) line += `, ${t.minutes} min`;
      lines.push(line);
    } else if (t.status === 'rest') {
      lines.push('Today: rest day');
    } else if (t.status === 'done') {
      lines.push('Today: planned session already done');
    } else {
      lines.push('Plan: no sessions planned');
    }
  }
  if (ctx.next) {
    const n = ctx.next;
    lines.push(`Next session: ${n.sport}${n.title ? ` "${n.title}"` : ''} on ${n.date}`);
  }
  if (ctx.readiness) {
    const r = ctx.readiness;
    let line = `Check-in today: readiness ${r.score}/100`;
    if (r.label) line += ` (${READINESS_TEXT[r.label]})`;
    if (r.sleepHours !== undefined) line += `, slept ${r.sleepHours} h`;
    if (r.factors) {
      line += `; factors: ${r.factors.map((f) => `${f.factor} ${signed(f.delta)}`).join(', ')}`;
    }
    lines.push(line);
  }
  if (ctx.lastWorkout) {
    const w = ctx.lastWorkout;
    let line = `Last workout: ${w.sport} "${w.name}" on ${w.date}`;
    if (w.minutes !== undefined) line += `, ${w.minutes} min`;
    lines.push(line);
  }
  if (ctx.load) {
    const l = ctx.load;
    let line = `Training load: ${l.last7} AU in 7 days`;
    if (l.acwr !== undefined) {
      line += `, ACWR ${l.acwr}`;
      if (l.band) line += ` (${BAND_TEXT[l.band]})`;
    } else if (l.band) {
      line += ` (${BAND_TEXT[l.band]})`;
    }
    if (l.hardDays7 !== undefined) line += `, hard days ${l.hardDays7}/7`;
    lines.push(line);
  }
  if (ctx.food) lines.push(macroLine('Eaten today', ctx.food));
  if (ctx.targets) lines.push(macroLine('Daily targets', ctx.targets));
  if (ctx.weight) {
    let line = `Body weight: ${ctx.weight.kg} kg`;
    if (ctx.weight.change8wKg !== undefined) {
      line += `, change over 8 weeks ${signed(ctx.weight.change8wKg)} kg`;
    }
    lines.push(line);
  }
  return lines.length ? lines.join('\n') : null;
}

/** Felix's system prompt for one request. */
function buildSystemPrompt(topic, profile, language, context) {
  const config = TOPICS[sanitizeTopic(topic)];
  const parts = [
    `You are Felix, a personal AI fitness coach in the FITRIX app. ${config.persona}`,
  ];
  if (config.label) {
    parts.push(
      `This chat is dedicated to ${config.label}. Answer from a ${config.label} ` +
        'coach\'s point of view and relate advice back to the user\'s ' +
        `${config.label} training. General fitness, nutrition and recovery ` +
        'questions are fine too.'
    );
  }
  const about = describeProfile(profile);
  if (about) {
    parts.push(
      'What you know about the user from their FITRIX profile:\n' +
        `${about}\n` +
        'Use these numbers when they matter (for example protein or calories ' +
        'per kg of body weight, training loads, pacing) and don\'t ask for ' +
        'data you already have. Address the user by name occasionally.'
    );
  }
  const today = describeContext(context);
  if (today) {
    parts.push(
      'Today in the user\'s FITRIX app (current data the app sent with this message):\n' +
        `${today}\n` +
        'Use these facts when they matter instead of asking for them. Anything ' +
        'not listed is unknown: don\'t invent it. Never say you already changed the plan or logs; to propose a change, use the app action block described below.'
    );
  }
  parts.push(BASE_RULES);
  const appLanguage = LANGUAGES[sanitizeLanguage(language)];
  if (appLanguage) {
    parts.push(
      `The user's FITRIX app is set to ${appLanguage}. Use ${appLanguage} ` +
        'for greetings and whenever the language of their message is unclear ' +
        '(a number, an emoji, a single word); a message clearly written in ' +
        'another language still gets a reply in that language.'
    );
  }
  // Last, so a small model still has the block format fresh when it answers.
  parts.push(ACTION_RULES);
  if (SPORTS.includes(sanitizeTopic(topic))) {
    parts.push(
      `This is a ${config.label} chat: in a workout_plan block use "sport":"${sanitizeTopic(topic)}".`
    );
  } else if (config.label) {
    parts.push(
      `This is a ${config.label} chat: add a workout_plan block only when the user explicitly asks for a workout plan or session; questions about whether or how hard to train get advice without a block.`
    );
  }
  return parts.join('\n\n');
}

module.exports = {
  MAX_MESSAGE_LENGTH,
  MAX_HISTORY_TURNS,
  MAX_CONVERSATION_ID_LENGTH,
  TOPICS,
  sanitizeTopic,
  sanitizeProfile,
  sanitizeHistory,
  sanitizeLanguage,
  sanitizeContext,
  describeContext,
  buildSystemPrompt,
};
