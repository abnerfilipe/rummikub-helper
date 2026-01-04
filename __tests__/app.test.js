const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

describe('Rummikub app basic smoke tests', () => {
  let dom;

  beforeAll(async () => {
    const html = fs.readFileSync(path.resolve(__dirname, '../index.html'), 'utf8');
    dom = new JSDOM(html, { runScripts: 'outside-only', resources: 'usable' });
    const script = fs.readFileSync(path.resolve(__dirname, '../app.js'), 'utf8');

    // Evaluate app.js inside the JSDOM window
    dom.window.eval(script);

    // small delay for any micro-tasks
    await new Promise((r) => setTimeout(r, 20));
  });

  test('State and Render objects exist', () => {
    expect(typeof dom.window.State).toBe('object');
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
