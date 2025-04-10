import { AuthClient } from "@dfinity/auth-client";
import { HttpAgent } from "@dfinity/agent";

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
          // Use the standard II canister ID for local development
          identityProvider: process.env.NODE_ENV === "production"
            ? "https://identity.ic0.app"
            : `http://localhost:4943/?canisterId=${process.env.INTERNET_IDENTITY_CANISTER_ID || "rdmx6-jaaaa-aaaaa-aaadq-cai"}`,
          // IMPORTANT: This makes sure you return to your app after authentication
          onSuccess: () => {
            this.identity = this.authClient.getIdentity();
            console.log("Login successful. Principal:", this.identity.getPrincipal().toString());
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

export default new AuthService();