// Builds Felix's system prompt per request and validates the optional
// chat context the app sends (topic, profile, history). Everything here is
// defensive: bad input is dropped, never thrown.

const MAX_MESSAGE_LENGTH = 4000;
const MAX_HISTORY_TURNS = 20;
const MAX_HISTORY_CONTENT_LENGTH = 4000;
const MAX_CONVERSATION_ID_LENGTH = 200;

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

const ACTION_RULES = `App actions. The app turns a special block into a confirmation button; nothing changes until the user taps it. The block is REQUIRED in the three cases below, and forbidden otherwise.
After your visible reply, add a new line with exactly one block: <fitrix-action>{JSON}</fitrix-action>
The JSON must be valid (balanced brackets, commas between items), and the block is the very last thing in your message. Never mention the block or its format in the visible text.

Case 1 - the user says their weight changed or gives their weight ("I gained 3 kg", "I'm 82 kg now", "lost 6 lb", "я набрал 3 кг", "похудел на 2 кг"). Reply with one short sentence of reaction, then:
<fitrix-action>{"type":"weight","mode":"delta","amount":3,"unit":"kg"}</fitrix-action>
amount is negative when they lost weight. For a new total weight use mode "set" and the total as amount, for example {"type":"weight","mode":"set","amount":82,"unit":"kg"}. unit is "kg" or "lb", as the user said.

Case 2 - you write out a concrete multi-day workout plan (several named sessions with exercises). Reply with the plan as plain lines, then:
<fitrix-action>{"type":"workout_plan","sport":"gym","templates":[
{"name":"Upper body","exercises":[{"name":"Bench press","sets":4,"reps":8,"kg":60},{"name":"Push-ups","sets":3,"reps":15}]},
{"name":"Legs","exercises":[{"name":"Squat","sets":4,"reps":10,"kg":80},{"name":"Plank","sets":3,"reps":1}]}
]}</fitrix-action>
sport is one of gym, fitness, cycling, running, football, winterSports. The block repeats the same plan; every session is exactly {"name":…,"exercises":[…]}, sessions are separated by commas, and the brackets must balance. Limits: 1-7 templates, 1-12 exercises each, sets 1-10, reps 1-100, kg optional (leave it out for bodyweight). Write names in the user's language.

Case 3 - you write out a concrete day of meals. Reply with the meals as plain lines, then:
<fitrix-action>{"type":"meal_plan","meals":[{"name":"Breakfast","items":"Oatmeal, banana, 2 eggs","kcal":520}]}</fitrix-action>
1-8 meals, one kcal number per meal. Write names and items in the user's language.

Never skip the block in these cases, even when the visible text already lists everything: without it the user gets no button.
In these cases end the visible text (before the block) with a short invitation in the user's language, like "Tap the button below to add it." Do not ask a follow-up question in these cases.`;

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

/** Felix's system prompt for one request. */
function buildSystemPrompt(topic, profile, language) {
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
  buildSystemPrompt,
};
