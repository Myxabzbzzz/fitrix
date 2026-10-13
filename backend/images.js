// Validation of the optional `images` field of a chat request.

const MAX_IMAGES = 1;
const MAX_IMAGE_BYTES = 1.5 * 1024 * 1024; // decoded
const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;

/**
 * Returns { images } (array of base64 strings, possibly empty) or
 * { error, status } with status 400 (malformed) or 413 (too large).
 */
function validateImages(value) {
  if (value === undefined || value === null) return { images: [] };
  if (!Array.isArray(value)) {
    return { status: 400, error: 'images must be an array' };
  }
  if (value.length === 0) return { images: [] };
  if (value.length > MAX_IMAGES) {
    return { status: 400, error: `At most ${MAX_IMAGES} image per message` };
  }
  const images = [];
  for (const item of value) {
    if (typeof item !== 'string' || !item) {
      return { status: 400, error: 'images must be base64 strings' };
    }
    if (item.startsWith('data:')) {
      return { status: 400, error: 'images must be raw base64 without a data: prefix' };
    }
    if (item.length % 4 !== 0 || !BASE64.test(item)) {
      return { status: 400, error: 'Image is not valid base64' };
    }
    const padding = item.endsWith('==') ? 2 : item.endsWith('=') ? 1 : 0;
    if ((item.length / 4) * 3 - padding > MAX_IMAGE_BYTES) {
      return { status: 413, error: 'Image is too large (max 1.5 MB)' };
    }
    const head = Buffer.from(item.slice(0, 8), 'base64');
    if (head.length < 3 || head[0] !== 0xff || head[1] !== 0xd8) {
      return { status: 400, error: 'Image must be a JPEG' };
    }
    images.push(item);
  }
  return { images };
}

module.exports = { validateImages, MAX_IMAGES, MAX_IMAGE_BYTES };
