const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const outDir = path.resolve(__dirname, '../tmp/smoke');
  fs.mkdirSync(outDir, { recursive: true });
  const logs = [];

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();

  page.on('console', (msg) => {
    logs.push({ type: 'console:' + msg.type(), text: msg.text() });
    console.log(`[console:${msg.type()}] ${msg.text()}`);
  });
  page.on('pageerror', (err) => {
    logs.push({ type: 'pageerror', text: String(err && err.stack ? err.stack : err) });
    console.error('[pageerror]', err);
  });

  const url = process.env.SMOKE_URL || 'http://localhost:8000/';
  console.log('Opening', url);

  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
  } catch (e) {
    console.error('Failed to load page:', e.message || e);
    logs.push({ type: 'loaderror', text: String(e) });
  }

  // Give the page a moment to run any startup scripts
  await page.waitForTimeout(800);

  const screenshotPath = path.join(outDir, 'screenshot.png');
  await page.screenshot({ path: screenshotPath, fullPage: true });
  console.log('Screenshot saved to', screenshotPath);

  const logPath = path.join(outDir, 'console.log');
  fs.writeFileSync(logPath, logs.map(l => `[${l.type}] ${l.text}`).join('\n'));
  console.log('Console log saved to', logPath);

  const hasError = logs.some(l => l.type === 'console:error' || l.type === 'pageerror' || l.type === 'loaderror');

  await browser.close();

  if (hasError) {
    console.error('Smoke test detected errors (see logs).');
    process.exit(2);
  }

  console.log('Smoke test completed with no errors.');
  process.exit(0);
})();