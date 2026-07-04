import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
// The landing site is deployed to the Firebase Hosting target `site`.
// `build.outDir` is `dist`, which is what firebase.json (target: site) serves.
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    sourcemap: false,
    chunkSizeWarningLimit: 800,
    rollupOptions: {
      output: {
        manualChunks: {
          react: ['react', 'react-dom'],
          firebase: ['firebase/app'],
        },
      },
    },
  },
  server: {
    port: 5173,
    open: true,
  },
});
