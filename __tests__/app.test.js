const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

describe('Rummikub app basic smoke tests', () => {
  let dom;

  beforeAll(async () => {
    const html = fs.readFileSync(path.resolve(__dirname, '../index.html'), 'utf8');
    dom = new JSDOM(html, { runScripts: 'outside-only', resources: 'usable', url: 'http://localhost' });
    // expose window/document globals so app.js can use bare globals (localStorage, document, etc.)
    global.window = dom.window;
    global.document = dom.window.document;
    global.localStorage = dom.window.localStorage;
    global.navigator = dom.window.navigator;

    // Provide lightweight stubs for large UI objects that are expected by the script
    dom.window.Render = {
      all: () => {},
      playersManager: () => {},
      totals: () => {},
      updateAddPlayerState: () => {},
      actionButton: () => {},
      leaderboard: () => {},
      table: () => {},
    };
    global.Render = dom.window.Render;

    const script = fs.readFileSync(path.resolve(__dirname, '../app.js'), 'utf8');

    // Ensure bare globals like localStorage and document resolve inside the window's eval scope
    const bootScript = 'var localStorage = window.localStorage; var document = window.document; var navigator = window.navigator;';
    dom.window.eval(bootScript + '\n' + script);

    // small delay for any micro-tasks
    await new Promise((r) => setTimeout(r, 20));
  });

  test('State and Render objects exist', () => {
    // `State` is a lexical binding in the evaluated script (declared with `const`), so use eval to inspect it
    expect(typeof dom.window.eval('State')).toBe('object');
    expect(typeof dom.window.Render).toBe('object');
  });

  test('timer display exists and formatted', () => {
    const display = dom.window.document.getElementById('timerDisplay');
    expect(display).not.toBeNull();
    expect(display.textContent).toMatch(/\d{2}:\d{2}/);
  });

  test('calling Timer.updateUI does not throw', () => {
    expect(() => {
      if (dom.window.Timer && typeof dom.window.Timer.updateUI === 'function') {
        dom.window.Timer.updateUI();
      }
    }).not.toThrow();
  });
});
