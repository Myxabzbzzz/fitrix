// Safety net for small models that write a plan but forget the action block:
// detect "this reply looks like a plan" and ask Ollama once, with a JSON
// schema, to convert the visible text into the action.

const { SPORTS, validateAction } = require('./actions');

const SET_REP = /\d+\s*[x×х]\s*\d+|подход|\bsets?\b/i;
const KCAL = /\d+\s*(kcal|ккал|kkal)/i;
const SESSION_HEADER =
  /^\s*(?:\d+[.)]\s*)?(?:(?:day|день|kun|workout|session|тренировка|занятие|dia|día)\s*\d+|(?:понедельник|вторник|среда|четверг|пятница|суббота|воскресенье|monday|tuesday|wednesday|thursday|friday|saturday|sunday|lunes|martes|mi[eé]rcoles|jueves|viernes|s[aá]bado|domingo|dushanba|seshanba|chorshanba|payshanba|juma|shanba|yakshanba)\b)/i;

/** 'workout_plan' | 'meal_plan' | null for a finished visible reply. */
function looksLikePlan(text) {
  if (typeof text !== 'string' || !text) return null;
  const lines = text.split('\n');
  const setLines = lines.filter((l) => SET_REP.test(l)).length;
  if (setLines >= 4) return 'workout_plan';
  // Compact plans: one session per line, exercises comma-separated.
  const richLines = lines.filter((l) => (l.match(/\d+\s*[x×х]\s*\d+/gi) || []).length >= 3).length;
  if (richLines >= 2) return 'workout_plan';
  if (setLines >= 3) {
    let headers = 0;
    lines.forEach((l, i) => {
      if (SET_REP.test(l)) return;
      if (SESSION_HEADER.test(l)) headers++;
      else if (/^\s*\d+[.)]\s+\S/.test(l) && /^\s*[-•]/.test(lines[i + 1] || '')) headers++;
      else if (/^\s*[^-•\s].{0,60}:\s*$/.test(l) && /^\s*[-•\d]/.test(lines[i + 1] || '')) headers++;
    });
    if (headers >= 2) return 'workout_plan';
  }
  if (lines.filter((l) => KCAL.test(l)).length >= 3) return 'meal_plan';
  return null;
}

// ---- food-log intent (from the USER's message) ----
// Conservative: a past-tense eating verb plus a quantity or a known food.
// Questions, plan/recipe requests and workout talk never trigger.
const EAT_VERB = new RegExp(
  [
    '\\b(?:i|i\'ve|ive)\\s+(?:just\\s+|also\\s+)?(?:had|ate|eaten|drank|drunk)\\b',
    '\\b(?:had|ate)\\s+(?:for\\s+)?(?:breakfast|lunch|dinner|supper)\\b',
    '(?:на\\s+)?(?:завтрак|обед|ужин|перекус)\\p{L}*\\s+(?:был|была|было|были)(?![\\p{L}])',
    '(?:съел|съела|съели|поел|поела|скушал|скушала|выпил|выпила|позавтракал|позавтракала|пообедал|пообедала|поужинал|поужинала|перекусил|перекусила)',
    '\\b(?:yedim|yeb\\s+oldim|ichdim|nonushta\\s+qildim|tushlik\\s+qildim|kechki\\s+ovqat\\s+qildim)',
    '\\b(?:com[ií]|he\\s+comido|desayun[eé]|almorc[eé]|cen[eé]|merend[eé]|beb[ií]|tom[eé])(?![\\p{L}])',
  ].join('|'),
  'iu'
);
// \b is ASCII-only in JS, so word edges are spelled with Unicode lookarounds.
const L = '(?<![\\p{L}])';
const R = '(?![\\p{L}])';
const QUESTION = new RegExp(
  '\\?|' + L + '(?:what|how|should|can i|could i|is it|do i|which|сколько|что|как|можно ли|стоит ли|какой|какая|qancha|nima|qanday|necha|cu[aá]nt[oa]s?|qu[eé]|c[oó]mo|puedo|debo)' + R,
  'iu'
);
const PLAN_OR_RECIPE = new RegExp(
  L + '(?:plan|recipe|menu|diet|ration|ratsion|retsept|dieta|receta|men[uú]|составь|посоветуй|бы)' + R + '|план|рецепт|меню|рацион|диет',
  'iu'
);
const NUMBER_WORD = new RegExp(
  L + '(?:one|two|three|four|five|six|half|bir|ikki|uch|to[\'‘’]rt|besh|yarim|un|una|dos|tres|cuatro|cinco|medio|один|одна|одно|два|две|три|четыре|пять|полтора|половин\\S*|пару)' + R,
  'iu'
);
const FOOD_WORD = new RegExp(
  '(?<![\\p{L}])(?:egg|toast|bread|rice|chicken|beef|pasta|oat|banana|apple|milk|cheese|salad|soup|potato|fish|steak|yogurt|pizza|burger|sandwich|' +
    'яйц|яичниц|хлеб|бутерброд|рис|кури|говяд|гречк|греч|овсянк|каш|творог|молок|сыр|салат|суп|картоф|рыб|банан|яблок|мяс|макарон|пельмен|' +
    'tuxum|non|lepyoshka|guruch|tovuq|go[\'\u2018\u2019]sht|sut|qatiq|palov|osh|baliq|' +
    'huevo|pan|arroz|pollo|carne|pasta|leche|queso|ensalada|sopa|pescado|manzana|pl[aá]tano)',
  'iu'
);
const WORKOUT_TALK = new RegExp(
  L + '(?:workout|training|sets?|reps?|run|ran|gym|km)' + R + '|тренировк|подход|повторен|пробежал|mashq|entren',
  'iu'
);

/** True when the user's message reads like "I ate X" (so a food_log fits). */
function looksLikeFoodLog(text) {
  if (typeof text !== 'string' || !text.trim()) return false;
  if (QUESTION.test(text) || PLAN_OR_RECIPE.test(text)) return false;
  if (!EAT_VERB.test(text)) return false;
  if (FOOD_WORD.test(text)) return true;
  if (WORKOUT_TALK.test(text)) return false;
  return /\d/.test(text) || NUMBER_WORD.test(text);
}

// ---- weight statements (from the USER's message) ----
const WEIGHT_NUM = /\d+(?:[.,]\d+)?\s*(?:kg|kgs|kilo\w*|кг|килограмм\w*|lbs?|pounds?|фунт\w*|funt)(?![\p{L}])/iu;
const WEIGHT_VERB = new RegExp(
  L + '(?:gained|lost|put\\s+on|weigh|weighing|i\'m|im|набрал\\p{L}*|поправил\\p{L}*|похудел\\p{L}*|скинул\\p{L}*|сбросил\\p{L}*|вешу|вес|ozdim|semirdim|vaznim|vazn\\p{L}*|subí|bajé|peso|engordé|adelgacé|pesas?)' + R,
  'iu'
);

/** True when the user states a weight or weight change with a number and unit. */
function looksLikeWeightChange(text) {
  if (typeof text !== 'string' || !text.trim()) return false;
  if (QUESTION.test(text) || PLAN_OR_RECIPE.test(text)) return false;
  return WEIGHT_NUM.test(text) && WEIGHT_VERB.test(text);
}

// ---- workout-plan request (from the USER's message) ----
const PLAN_REQUEST = new RegExp(
  L + '(?:plans?|split|splits|program(?:me)?s?|routines?|workouts?|sessions?|rutinas?|programas?|entrenamientos?|reja\\p{L}*|dastur\\p{L}*|mashg[\'‘’]ulot\\p{L}*|распиши\\p{L}*|составь\\p{L}*)' + R +
    '|' + L + '(?:план(?!к|ир)|сплит|программ(?!ист)|тренировк|распиш|состав(?:ь|ьте))',
  'iu'
);
const MEAL_PLAN = new RegExp(
  '(?:meal|diet|food|nutrition)\\s+plans?|plan\\s+de\\s+(?:comidas?|dieta)|план\\p{L}*\\s+питани|ovqat\\s+reja',
  'iu'
);
const REQUEST_VERB = new RegExp(
  L + '(?:make|build|create|give|write|design|suggest|haz\\p{L}*|crea|dame|dise[ñn]a|tuz\\p{L}*|ber|yoz\\p{L}*|taklif\\p{L}*|составь\\p{L}*|распиши\\p{L}*|сдела\\p{L}*|подбер\\p{L}*|дай\\p{L}*|предложи\\p{L}*)' + R,
  'iu'
);

/** True when the user's message asks for a workout plan or session. */
function asksForWorkoutPlan(text) {
  if (typeof text !== 'string' || !PLAN_REQUEST.test(text)) return false;
  if (MEAL_PLAN.test(text)) return false;
  if (QUESTION.test(text) && !REQUEST_VERB.test(text)) return false;
  return true;
}

const str = { type: 'string' };
const SCHEMAS = {
  weight: {
    type: 'object',
    properties: {
      mode: { type: 'string', enum: ['set', 'delta'] },
      amount: { type: 'number' },
      unit: { type: 'string', enum: ['kg', 'lb'] },
    },
    required: ['mode', 'amount', 'unit'],
  },
  food_log: {
    type: 'object',
    properties: {
      slot: { type: ['string', 'null'], enum: ['breakfast', 'lunch', 'dinner', 'snack', null] },
      items: {
        type: 'array',
        minItems: 1,
        maxItems: 15,
        items: {
          type: 'object',
          properties: {
            name: str,
            grams: { type: 'number' },
            kcal: { type: 'number' },
            protein: { type: 'number' },
            carbs: { type: 'number' },
            fat: { type: 'number' },
          },
          required: ['name', 'grams', 'kcal', 'protein', 'carbs', 'fat'],
        },
      },
    },
    required: ['slot', 'items'],
  },
  workout_plan: {
    type: 'object',
    properties: {
      sport: { type: 'string', enum: SPORTS },
      when: { type: ['string', 'null'], enum: ['today', 'week', null] },
      days: { type: 'array', items: { type: 'string', enum: ['today', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] } },
      templates: {
        type: 'array',
        minItems: 1,
        maxItems: 7,
        items: {
          type: 'object',
          properties: {
            name: str,
            exercises: {
              type: 'array',
              minItems: 1,
              maxItems: 12,
              items: {
                type: 'object',
                properties: {
                  name: str,
                  sets: { type: 'integer' },
                  reps: { type: 'integer' },
                  kg: { type: 'number' },
                },
                required: ['name', 'sets', 'reps'],
              },
            },
          },
          required: ['name', 'exercises'],
        },
      },
    },
    required: ['sport', 'templates'],
  },
  meal_plan: {
    type: 'object',
    properties: {
      meals: {
        type: 'array',
        minItems: 1,
        maxItems: 8,
        items: {
          type: 'object',
          properties: { name: str, items: str, kcal: { type: 'integer' } },
          required: ['name', 'items', 'kcal'],
        },
      },
    },
    required: ['meals'],
  },
};

/**
 * One non-streamed structured call. Returns a validated action or null
 * (never throws: a failure just means "no button").
 *   post(url, body, config) is axios.post.
 */
async function extractPlanAction({ post, url, model, kind, text, defaultSport, timeout, signal }) {
  try {
    const res = await post(
      `${url}/api/chat`,
      {
        model,
        stream: false,
        think: false,
        format: SCHEMAS[kind],
        options: { temperature: 0 },
        messages: [
          {
            role: 'system',
            content:
              (kind === 'food_log' || kind === 'weight' ? 'Convert the user message to JSON. ' : 'Convert this plan to JSON; copy names exactly. Keep the language of the text. ') +
              (kind === 'weight'
                ? 'mode "delta" when the user gained or lost some amount (amount is negative for a loss); mode "set" when they state their total weight now. unit is kg or lb as the user said.'
                : kind === 'food_log'
                ? 'The user says what they ate. List each food as one item: name is a short generic food name in ENGLISH; grams is the eaten amount (egg = 50 g, slice of bread = 30 g, a quarter of non/lepyoshka = 60 g); kcal, protein, carbs, fat are totals for that amount. slot is breakfast, lunch, dinner or snack only if the user said it, otherwise null.'
                : kind === 'workout_plan'
                ? `One template per training session; sport is one of ${SPORTS.join(', ')}` +
                  (defaultSport ? ` (use ${defaultSport})` : '') +
                  '; use 1 rep for timed holds. Set when to "today" only if the plan is for today (then exactly one template), "week" if for the week, else null.'
                : 'One entry per meal with its kcal.'),
          },
          { role: 'user', content: text },
        ],
      },
      { timeout, signal }
    );
    const raw = JSON.parse(res.data?.message?.content || '');
    return validateAction({ ...raw, type: kind }, { defaultSport });
  } catch {
    return null;
  }
}

module.exports = { looksLikePlan, asksForWorkoutPlan, looksLikeFoodLog, looksLikeWeightChange, extractPlanAction };
