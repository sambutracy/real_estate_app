import { fileURLToPath, URL } from 'url';
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import fs from 'fs';
import path from 'path';

// Function to dynamically read canister IDs from the canister_ids.json file
function getCanisterIds() {
  const canisterIdsPath = path.resolve(__dirname, '../../.dfx/local/canister_ids.json');
  let canisterIds = {};
  
  try {
    if (fs.existsSync(canisterIdsPath)) {
      const canisterIdsFile = fs.readFileSync(canisterIdsPath, 'utf-8');
      canisterIds = JSON.parse(canisterIdsFile);
    }
  } catch (error) {
    console.warn("Could not get canister IDs from .dfx/local/canister_ids.json");
  }
  
  return {
    'process.env.CANISTER_ID_REAL_ESTATE_APP_BACKEND': 
      JSON.stringify(canisterIds?.real_estate_app_backend?.local || 'be2us-64aaa-aaaaa-qaabq-cai'),
    'process.env.CANISTER_ID_AUTH': 
      JSON.stringify(canisterIds?.auth?.local || 'bkyz2-fmaaa-aaaaa-qaaaq-cai'),
    'process.env.CANISTER_ID_INTERNET_IDENTITY': 
      JSON.stringify(canisterIds?.internet_identity?.local || 'bd3sg-teaaa-aaaaa-qaaba-cai')
  };
}

export default defineConfig({
  build: {
    emptyOutDir: true,
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: 'globalThis',
      },
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
    host: '0.0.0.0',
    port: 3000,
  },
  plugins: [vue()],
  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'development'),
    ...getCanisterIds()
  },
  resolve: {
    alias: [
      { find: 'declarations', replacement: fileURLToPath(new URL('../declarations', import.meta.url)) },
      { find: '@', replacement: fileURLToPath(new URL('./src', import.meta.url)) },
    ],
    dedupe: ['@dfinity/agent'],
  }
});
