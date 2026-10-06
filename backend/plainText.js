// The app shows replies as plain text, but small models still like to emit
// markdown despite the system prompt. This strips the common bits
// (**bold**, # headings, "* " bullets) from a reply as it streams in.
//
// Markers can be split across tokens ("*" then "*bold"), so a trailing run
// of "*" / "#" is held back until the next chunk (or flush) arrives.

function createPlainTextFilter() {
  let pending = '';
  let atLineStart = true;

  function clean(text) {
    // Prefix a newline when the chunk starts a line so "^" rules apply.
    const prefix = atLineStart ? '\n' : ' ';
    const out = (prefix + text)
      .replace(/\*\*/g, '')
      .replace(/(\n[ \t]*)#{1,6}[ \t]+/g, '$1')
      .replace(/(\n[ \t]*)\*[ \t]+/g, '$1- ')
      .slice(1);
    if (out) atLineStart = out.endsWith('\n');
    return out;
  }

  return {
    /** Returns the cleaned text that can be emitted for [delta]. */
    push(delta) {
      const text = pending + delta;
      const held = /[*#]+$/.exec(text);
      pending = held ? held[0] : '';
      return clean(held ? text.slice(0, held.index) : text);
    },
    /** Returns whatever was held back, at the end of the reply. */
    flush() {
      const text = pending;
      pending = '';
      return text ? clean(text) : '';
    },
  };
}

function toPlainText(text) {
  const filter = createPlainTextFilter();
  return filter.push(text) + filter.flush();
}

module.exports = { createPlainTextFilter, toPlainText };
