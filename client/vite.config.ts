import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 8081,
    host: '127.0.0.1',
    proxy: {
      '/auth': 'http://127.0.0.1:8080',
      '/closings': 'http://127.0.0.1:8080',
      '/webposto': 'http://127.0.0.1:8080',
      '/health': 'http://127.0.0.1:8080',
    },
  },
});
