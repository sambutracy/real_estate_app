// At the top of main.js
import { setupApiInterceptor } from './apiInterceptor';

// Add this at the top of main.js - Global API version and certificate fix
const originalFetch = window.fetch;
window.fetch = function(input, init) {
  // Replace any v3 API calls with v2
  if (typeof input === 'string' && input.includes('/api/v3/')) {
    console.log('Intercepted v3 API call, redirecting to v2');
    input = input.replace('/api/v3/', '/api/v2/');
  }
  return originalFetch(input, init);
};

// Setup API interceptor before anything else
setupApiInterceptor();

import { createApp } from 'vue';
import App from './App.vue';
createApp(App).mount('#app');
