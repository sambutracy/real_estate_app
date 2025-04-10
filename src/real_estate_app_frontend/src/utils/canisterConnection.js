import { Actor, HttpAgent } from '@dfinity/agent';

/**
 * Helper function to connect to the backend canister
 * @returns {Promise<Object>} The initialized backend actor
 */
export async function getBackendActor() {
  try {
    // Import the declarations directly from the .dfx directory which is more reliable
    const backendDid = await import(process.env.CANISTER_ID_REAL_ESTATE_APP_BACKEND 
      ? `/workspace/real_estate_app/.dfx/local/canisters/real_estate_app_backend/real_estate_app_backend.did.js` 
      : '/src/declarations/real_estate_app_backend/real_estate_app_backend.did.js');
    
    const canisterId = process.env.CANISTER_ID_REAL_ESTATE_APP_BACKEND || 
      (await import('/src/declarations/real_estate_app_backend/index.js')).canisterId;
    
    const agent = new HttpAgent();
    
    // In development, we need to fetch the root key
    if (process.env.NODE_ENV !== 'production') {
      await agent.fetchRootKey();
    }
    
    return Actor.createActor(backendDid.idlFactory, {
      agent,
      canisterId,
    });
  } catch (error) {
    console.error('Failed to initialize backend actor:', error);
    throw error;
  }
}