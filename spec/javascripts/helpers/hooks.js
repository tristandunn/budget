/*
 * Reset the shared environment after every example. A single JSDOM window and
 * document are created once in `helpers.js` and reused for the whole run, so
 * anything a spec leaves behind is visible to every later spec. Several
 * controllers branch on document-wide state, such as an open dialog, which
 * makes a stray node change an unrelated example's result.
 *
 * Restoring sinon first unwraps any stub on a node before that node is
 * dropped. Specs still need their own `disconnect` call, since clearing the
 * document does not remove a listener bound to the document itself.
 */
export const mochaHooks = {
  afterEach() {
    sinon.restore();

    document.head.replaceChildren();
    document.body.replaceChildren();
    localStorage.clear();
  }
};
