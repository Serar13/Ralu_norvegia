import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
// The admin dashboard is deployed to the Firebase Hosting target `webadmin`.
// `build.outDir` is `dist`, which firebase.json (target: webadmin) serves.
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    sourcemap: false,
    chunkSizeWarningLimit: 800,
    rollupOptions: {
      output: {
        // Split heavy vendors into their own long-lived chunks for caching.
        manualChunks: {
          react: ['react', 'react-dom', 'react-router-dom'],
          firebase: ['firebase/app', 'firebase/auth', 'firebase/firestore'],
        },
      },
    },
  },
  server: {
    port: 5174,
    open: true,
  },
});
