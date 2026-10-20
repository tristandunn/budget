import * as chai from "chai";
import sinon from "sinon";
import sinonChai from "sinon-chai";
import { JSDOM } from "jsdom";

chai.use(sinonChai);

global.expect = chai.expect;
global.sinon  = sinon.createSandbox();
global.window = new JSDOM("", {
  "pretendToBeVisual": true,
  "url": "http://localhost"
}).window;

global.document     = global.window.document;
global.localStorage = global.window.localStorage;

// Parse the stylesheets so the first style lookup does not slow down tests.
global.window.getComputedStyle(global.document.body);
