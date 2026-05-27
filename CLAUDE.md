# CLAUDE.md — Rummikub Helper

## Project Overview

A single-page vanilla JavaScript web app for tracking Rummikub game scores. The UI and all text are in Brazilian Portuguese. It runs entirely in the browser with no backend; state is persisted to `localStorage`.

Live app: https://abnerfilipe.github.io/rummikub-helper/

---

## Tech Stack

| Tool | Role |
|------|------|
| Vite | Dev server and bundler |
| Jest + jsdom | Unit / integration tests |
| Playwright | Smoke tests (requires running server) |
| Tailwind CSS | Styling (loaded via CDN in `index.html`) |
| GitHub Actions | CI/CD — deploys to GitHub Pages on `main` push |

No framework. No npm runtime dependencies — only `devDependencies`.

---

## Repository Layout

```
index.html            Main HTML (very large — ~165 KB, contains all UI markup and Tailwind classes)
styles.css            Custom CSS (animations, timer-critical, toast, badge-pulse, etc.)
src/
  app.js              All application logic (~2 100 lines)
  main.js             Vite entry point — just imports app.js + HMR stub
__tests__/
  app.test.js         Jest unit tests (loads index.html via jsdom, evals app.js)
test/
  smoke.js            Playwright smoke test (headless Chromium, screenshots to tmp/smoke/)
docs/                 Vite build output — what gets deployed to GitHub Pages
  assets/             Hashed JS/CSS bundles
vite.config.js        Vite config (outDir: docs, base: ./)
jest.config.cjs       Jest config (environment: jsdom, timeout: 10 000 ms)
jest.setup.js         Polyfills TextEncoder/TextDecoder for jsdom
.github/workflows/
  deploy.yml          Builds on push to main → deploys docs/ to gh-pages branch
```

---

## Architecture: `src/app.js`

The entire runtime lives in a handful of plain objects, all exposed on `window` so `onclick` attributes in `index.html` can reach them.

### Core Objects

| Object | Purpose |
|--------|---------|
| `State` | Single source of truth. Reads/writes `localStorage`. Initialises on load. |
| `UI` | Non-persisted view state (leaderboard open/expanded, editing player index). |
| `Sound` | Web Audio API wrapper. `tick()` (countdown warning) and `alarm()` (time up). |
| `Timer` | Countdown timer, play/pause/reset, UI updates, expiry handling with rules. |
| `TileCalc` | Modal for entering remaining tiles per player; computes negative scores. |
| `Render` | All DOM updates — `table()`, `totals()`, `leaderboard()`, `actionButton()`, etc. |
| `Actions` | User-triggered mutations — add/remove/reorder players, input handling, round flow. |
| `GameLimits` | Constants: `MIN_PLAYERS = 2`, `MAX_PLAYERS = 6`. |

### State Schema (`localStorage` key: `rummi_v7_game`)

```js
{
  players: string[],          // player names, ordered
  rounds: string[][],         // rounds[roundIdx][playerIdx] = score string or ""
  currIdx: number,            // index of the active round
  editingIdx: number | null,  // non-null while editing a past round
  locked: boolean,            // true once game started (no more player adds)
  started: boolean,           // derived/persisted; same semantics as locked
  tileDetails: {},            // "rIdx-pIdx" → number[14] tile counts per cell
  roundWinners: {},           // "rIdx" → playerIdx for each round's winner
  turnIdx: number,            // whose turn it currently is
  timeRule: string,           // 'official' | 'alternative' | 'impatient' | 'custom'
  turnAutoRotate: boolean,    // auto-advance timer to next player on expiry
  confirmExpiry: boolean,     // show confirm dialog on time expiry
  roundPenalties: {},         // rIdx → { playerIdx: drawCount }
  turnHistory: {},            // rIdx → { playerIdx: [{start, end, durationSeconds, penaltyApplied, penaltyConfirmed, reason}] }
  events: Array,              // game event log (max 200 entries), each { ts, msg }
}
```

Timer config (`localStorage` key: `rummi_v7_timer`): `{ d: seconds, s: soundEnabled }`.

### Round Scoring Rules

- All players enter their remaining tile values as **negative** numbers.
- The winner's score is automatically calculated as the **negative sum of all other players' scores** (making the total always 0 per round).
- When one cell is empty and the action button is pressed, the winner modal auto-calculates and fills the missing score.
- `TileCalc` computes tile totals and writes them as negative values into the score cell.

### Game Flow

1. Add players (2–6).
2. Click "Iniciar Rodada" (or start timer) — locks the player list and opens scoring.
3. Each round: fill in tile counts via `TileCalc` modal, then click "Concluir Rodada".
4. After all rounds are finished (`currIdx >= rounds.length`), the game-over modal appears.
5. Past rounds can be edited via the pencil icon; `editingIdx` tracks which round is being edited.

---

## Development Workflows

### Install dependencies
```sh
npm install
```

### Start dev server
```sh
npm run dev
# Vite serves on http://localhost:5173
```

### Production build
```sh
npm run build
# Output goes to docs/ (what GitHub Pages serves)
```

### Run unit tests
```sh
npm test           # jest --runInBand (single thread)
npm run test:watch # watch mode
```

### Smoke test (requires a running server)
```sh
npm run build && npx vite preview &
SMOKE_URL=http://localhost:4173/ node test/smoke.js
# Screenshots land in tmp/smoke/
```

---

## Testing Conventions

- **Unit tests** live in `__tests__/`. They load `index.html` via jsdom, eval `src/app.js`, and call app code through `dom.window.eval(...)`. The `Render` object is stubbed out (no-ops) because DOM layout is not tested.
- Tests are intentionally lightweight smoke-level checks; they don't cover every action.
- Jest uses `jsdom` environment. `jest.setup.js` polyfills `TextEncoder`/`TextDecoder`.
- `jest --runInBand` is required (single-file app evals into a shared jsdom context).

---

## HTML Conventions (`index.html`)

- **Inline `onclick`** attributes call globals: `Actions.*`, `TileCalc.*`, `Timer.*`, `Render.*`.
- `escapeHtml()` in `app.js` is used whenever user-supplied strings are interpolated into HTML template literals to prevent XSS.
- Tailwind CSS classes are applied directly. No build-time purge — the CDN version includes the full stylesheet.
- Dynamic HTML is rendered by `Render.*` methods that write `innerHTML` on container elements (e.g., `#tableBody`, `#leaderboardList`, `#tileGrid`).
- UI text is in **Portuguese (pt-BR)**. Keep all user-facing strings in Portuguese.

---

## CI/CD

`.github/workflows/deploy.yml` triggers on every push to `main`:
1. `npm ci` — install deps.
2. `npm run build` — Vite builds to `docs/`.
3. `peaceiris/actions-gh-pages` publishes `docs/` to the `gh-pages` branch.

The live site picks up changes within a minute of merging to `main`.

---

## Key Conventions for AI Assistants

- **No framework migrations**: this is intentionally vanilla JS. Do not introduce React, Vue, or any runtime library.
- **Portuguese UI text**: all labels, toasts, modal titles, and error messages must stay in pt-BR.
- **Global window objects**: the app relies on `window.Actions`, `window.State`, etc. Any new object that needs to be callable from inline HTML handlers must be assigned to `window`.
- **localStorage key is versioned**: the key `rummi_v7_game` includes a version. If the state schema changes in a breaking way, bump the version and add migration logic in `State.init()`.
- **Scores are always summed to zero per round**: preserve this invariant in any round-scoring changes. The winner's score = negative sum of all others.
- **Build output is `docs/`**: never change `outDir` in `vite.config.js` without also updating the deploy workflow.
- **`escapeHtml()` is required** whenever user names or messages are inserted into innerHTML strings. Do not bypass this.
- **`jest --runInBand`**: do not remove this flag. Tests share a single jsdom instance and must run serially.
