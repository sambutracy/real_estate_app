// Global API version interceptor
export function setupApiInterceptor() {
  const originalFetch = window.fetch;
  
  window.fetch = function(input, init) {
    // Fix any /api/v3/ URLs to use /api/v2/ instead
    if (typeof input === 'string' && input.includes('/api/v3/')) {
      console.log('Intercepted v3 API call, redirecting to v2:', input);
      input = input.replace('/api/v3/', '/api/v2/');
    }
    
    // Special handling for GET/HEAD requests with bodies (which is invalid)
    if (init && init.body && 
        (!init.method || init.method === 'GET' || init.method === 'HEAD')) {
      console.warn('Fixing invalid request with GET/HEAD containing body');
      // Convert to POST if there's a body
      init.method = 'POST';
    }
    
    return originalFetch(input, init);
  };
  
  console.log('API interceptor installed with GET/HEAD fix');
}