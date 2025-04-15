import { idlFactory } from "../../../declarations/auth/auth.did.js";
import { Actor, HttpAgent } from "@dfinity/agent";
import { canisterId as authCanisterId } from "../../../declarations/auth/index.js";

// Ensure the host function is properly implemented
const getHost = () => {
  if (import.meta.env.PROD) return undefined;
  
  const hostname = window.location.hostname;
  const isCodespaces = hostname.includes('github.dev') || 
                      hostname.includes('githubpreview') ||
                      hostname.includes('codespaces') ||
                      hostname.endsWith('.github.dev');
  
  if (isCodespaces) {
    // Return the full URL to port 8000
    return `${window.location.protocol}//${hostname.replace(/:\d+$/, '')}:8000`;
  }
  
  return "http://127.0.0.1:8000";
};

// Change to async initialization pattern
const agent = new HttpAgent({ host: getHost() });

// Add console logs
console.log("Agent created with host:", getHost());
console.log("Auth canister ID:", authCanisterId);

// Fix the root key fetching - use immediate async function
(async () => {
  if (process.env.NODE_ENV !== "production") {
    try {
      await agent.fetchRootKey();
      console.log("Root key successfully fetched");
    } catch (err) {
      console.error("Failed to fetch root key:", err);
    }
  }
})();

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

  // Update the getPrincipal method to use stored principal
  async getPrincipal() {
    // If we have the principal ID cached, return it
    if (this.principalId) {
      return this.principalId;
    }
    
    // Try to get from localStorage
    const storedPrincipal = localStorage.getItem("auth_principal");
    if (storedPrincipal) {
      this.principalId = storedPrincipal;
      return storedPrincipal;
    }
    
    // As a last resort, get from backend
    if (this.token) {
      try {
        const principal = await auth.getPrincipalFromToken(this.token);
        this.principalId = principal;
        localStorage.setItem("auth_principal", principal);
        return principal;
      } catch (error) {
        console.error("Error getting principal ID:", error);
        return "Error getting principal";
      }
    }
    
    return "Not authenticated";
  }
  
  getPrincipalText() {
    return this.principalId || "Not authenticated";
  }

  // Update the login method to handle the new return value with principal
  async login(email, password) {
    try {
      console.log("Attempting login with email:", email);
      const result = await auth.login(email, password);
      console.log("Login response:", result);
      
      if (result && result.length >= 2) {
        this.token = result[0];
        this.email = email;
        this.principalId = result[1];  // Store the principal ID
        
        const expiry = Date.now() + (7 * 24 * 60 * 60 * 1000); // 7 days
        this.tokenExpiry = expiry;

        localStorage.setItem("auth_token", this.token);
        localStorage.setItem("auth_email", email);
        localStorage.setItem("auth_token_expiry", this.tokenExpiry);
        localStorage.setItem("auth_principal", this.principalId);
        
        return true;
      }
      return false;
    } catch (error) {
      console.error("Detailed login error:", error);
      return false;
    }
  }

  async loginWithDelegation(email, password) {
    // This will be implemented later
    console.warn("Delegation not yet implemented");
    return false;
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