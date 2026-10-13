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

const str = { type: 'string' };
const SCHEMAS = {
  workout_plan: {
    type: 'object',
    properties: {
      sport: { type: 'string', enum: SPORTS },
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
              'Convert this plan to JSON; copy names exactly. Keep the language of the text. ' +
              (kind === 'workout_plan'
                ? `One template per training session; sport is one of ${SPORTS.join(', ')}` +
                  (defaultSport ? ` (use ${defaultSport})` : '') +
                  '; use 1 rep for timed holds.'
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

module.exports = { looksLikePlan, extractPlanAction };
