import { idlFactory } from "../../../declarations/auth/auth.did.js";
import { Actor, HttpAgent } from "@dfinity/agent";
import { canisterId as authCanisterId } from "../../../declarations/auth/index.js";

// Create the auth actor with the correct canister ID
const agent = new HttpAgent({
  host: import.meta.env.PROD ? undefined : "http://localhost:8000"
});

// Fetch root key for local dev environment
if (!import.meta.env.PROD) {
  try {
    agent.fetchRootKey();
  } catch (err) {
    console.warn("Unable to fetch root key. Error:", err);
  }
}

// Create actor with the correct canister ID from your deployment
const auth = Actor.createActor(idlFactory, {
  agent,
  canisterId: authCanisterId
});

class EmailAuthService {
  constructor() {
    try {
      this.token = localStorage.getItem("auth_token") || null;
      this.email = localStorage.getItem("auth_email") || null;
      this.tokenExpiry = localStorage.getItem("auth_token_expiry") || null;
      this.principalId = localStorage.getItem("auth_principal") || null;
    } catch (error) {
      console.error("Error accessing localStorage:", error);
      this.token = null;
      this.email = null;
      this.tokenExpiry = null;
      this.principalId = null;
    }
  }

  isTokenExpired() {
    if (!this.tokenExpiry) return true;
    return Date.now() > parseInt(this.tokenExpiry);
  }

  isAuthenticated() {
    return !!this.token && !this.isTokenExpired();
  }

  async checkAuthentication() {
    if (!this.token || this.isTokenExpired()) return false;
    
    try {
      const isValid = await auth.verifySession(this.token);
      if (!isValid) {
        this.logout();
        return false;
      }
      return true;
    } catch (error) {
      console.error("Error verifying session:", error);
      this.logout();
      return false;
    }
  }

  async register(email, password) {
    try {
      const success = await auth.register(email, password);
      if (success) {
        return await this.login(email, password);
      }
      return false;
    } catch (error) {
      console.error("Registration error:", error);
      return false;
    }
  }

  async getPrincipal() {
    if (!this.token) return "Not authenticated";
    
    // If we already have the principal ID cached, return it
    if (this.principalId) return this.principalId;
    
    try {
      // Call the backend method to get the principal ID from token
      const principal = await auth.getPrincipalFromToken(this.token);
      this.principalId = principal;
      localStorage.setItem("auth_principal", principal);
      return principal;
    } catch (error) {
      console.error("Error getting principal ID:", error);
      return "Error getting principal";
    }
  }
  
  getPrincipalText() {
    return this.principalId || "Not authenticated";
  }

  async login(email, password) {
    try {
      console.log("Attempting login with email:", email);
      const result = await auth.login(email, password);
      console.log("Login response:", result);
      if (result && result.length > 0) {
        this.token = result[0];
        this.email = email;

        const expiry = result[1] || Date.now() + 3600 * 1000;
        this.tokenExpiry = expiry;

        localStorage.setItem("auth_token", this.token);
        localStorage.setItem("auth_email", email);
        localStorage.setItem("auth_token_expiry", this.tokenExpiry);
        
        // Get and store principal ID
        const principal = await this.getPrincipal();
        
        return true;
      }
      return false;
    } catch (error) {
      console.error("Detailed login error:", error);
      return false;
    }
  }

  async logout() {
    if (this.token) {
      try {
        await auth.logout(this.token);
      } catch (error) {
        console.error("Logout error:", error);
      }
    }
    
    this.token = null;
    this.email = null;
    this.tokenExpiry = null;
    this.principalId = null;
    localStorage.removeItem("auth_token");
    localStorage.removeItem("auth_email");
    localStorage.removeItem("auth_token_expiry");
    localStorage.removeItem("auth_principal");
  }

  getEmail() {
    return this.email;
  }

  getToken() {
    return this.token;
  }
}

export default new EmailAuthService();