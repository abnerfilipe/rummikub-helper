// Entry module for Vite
import '../app.js';

// HMR stub: if module changes, re-run or log
if (import.meta.hot) {
  import.meta.hot.accept(() => {
    // For now, rely on the app module to attach to window globals
    console.log('HMR: src/main.js accepted');
  });
}
