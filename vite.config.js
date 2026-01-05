import { defineConfig } from 'vite';

export default defineConfig({
  // Use relative base so GitHub Pages serving from a repo subpath works reliably
  base: './',
  build: {
    outDir: 'docs',
    emptyOutDir: true,
  },
});
