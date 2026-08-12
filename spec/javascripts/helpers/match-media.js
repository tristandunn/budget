/*
 * Stub matchMedia with the given reduced-motion result, which specs can change
 * per test via `window.matchMedia.returns`. jsdom has no matchMedia, so define
 * it rather than stub it. Defining also removes it on restore, keeping the
 * property out of the other spec files.
 */
global.stubMatchMedia = (matches) => {
  sinon.define(window, "matchMedia", sinon.stub().returns({ "matches": matches }));
};
