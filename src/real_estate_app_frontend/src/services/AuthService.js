import { AuthClient } from "@dfinity/auth-client";
import { HttpAgent, Actor } from "@dfinity/agent";
import { idlFactory as backendIdlFactory } from "../../../declarations/real_estate_app_backend/real_estate_app_backend.did.js";
import { canisterId as backendCanisterId } from "../../../declarations/real_estate_app_backend/index.js";

class AuthService {
  constructor() {
    this.authClient = null;
    this.identity = null;
  }

  async initialize() {
    try {
      this.authClient = await AuthClient.create();
      const isAuthenticated = await this.authClient.isAuthenticated();
      
      if (isAuthenticated) {
        this.identity = this.authClient.getIdentity();
        console.log("User is authenticated with principal:", this.identity.getPrincipal().toString());
        return true;
      }
      return false;
    } catch (error) {
      console.error("Error initializing auth client:", error);
      return false;
    }
  }

  async login() {
    try {
      return new Promise((resolve) => {
        this.authClient.login({
          // Always use NFID for authentication
          identityProvider: this.getIdentityProviderUrl(),
          // Maximum authentication expiration time (30 days)
          maxTimeToLive: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000),
          // Ensure we get redirected back to our app after authentication
          derivationOrigin: window.location.origin,
          onSuccess: () => {
            this.identity = this.authClient.getIdentity();
            console.log("NFID Login successful. Principal:", this.identity.getPrincipal().toString());
            resolve(true);
          },
          onError: (error) => {
            console.error("Login failed:", error);
            resolve(false);
          }
        });
      });
    } catch (error) {
      console.error("Error during login:", error);
      return false;
    }
  }
  
  getIdentityProviderUrl() {
    return "https://nfid.one/authenticate/";
  }

  async logout() {
    try {
      await this.authClient.logout();
      this.identity = null;
      return true;
    } catch (error) {
      console.error("Error during logout:", error);
      return false;
    }
  }

  getIdentity() {
    return this.identity;
  }

  getPrincipalText() {
    if (!this.identity) return 'Not authenticated';
    return this.identity.getPrincipal().toString();
  }

  isAuthenticated() {
    return this.authClient?.isAuthenticated() || false;
  }
}

const agent = new HttpAgent();
const backendActor = Actor.createActor(backendIdlFactory, {
  agent,
  canisterId: backendCanisterId
});

export default new AuthService();