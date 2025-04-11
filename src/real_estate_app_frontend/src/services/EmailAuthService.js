import { idlFactory } from "../../../declarations/auth/auth.did.js";
import { Actor, HttpAgent } from "@dfinity/agent";

// Create the auth actor directly without using createActor from declarations
// This ensures we use exactly the ID we specify
const agent = new HttpAgent({
  host: process.env.NODE_ENV === "production" ? undefined : "http://localhost:4943"
});

// Fetch root key for local dev environment
if (process.env.NODE_ENV !== "production") {
  try {
    agent.fetchRootKey();
  } catch (err) {
    console.warn("Unable to fetch root key. Error:", err);
  }
}

// Create actor with explicit canister ID from canister_ids.json
const auth = Actor.createActor(idlFactory, {
  agent,
  canisterId: "uxrrr-q7777-77774-qaaaq-cai"
});

class EmailAuthService {
  constructor() {
    try {
      this.token = localStorage.getItem("auth_token") || null;
      this.email = localStorage.getItem("auth_email") || null;
      this.tokenExpiry = localStorage.getItem("auth_token_expiry") || null;
    } catch (error) {
      console.error("Error accessing localStorage:", error);
      this.token = null;
      this.email = null;
      this.tokenExpiry = null;
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

  async login(email, password) {
    try {
      console.log("Attempting login with email:", email);
      const result = await auth.login(email, password);
      console.log("Login response:", result);
      if (result && result.length > 0) {
        this.token = result[0];
        this.email = email;

        // Assuming backend returns expiry or set a default expiry
        const expiry = result[1] || Date.now() + 3600 * 1000; // Default 1 hour
        this.tokenExpiry = expiry;

        localStorage.setItem("auth_token", this.token);
        localStorage.setItem("auth_email", email);
        localStorage.setItem("auth_token_expiry", this.tokenExpiry);
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
    localStorage.removeItem("auth_token");
    localStorage.removeItem("auth_email");
    localStorage.removeItem("auth_token_expiry");
  }

  getEmail() {
    return this.email;
  }

  getToken() {
    return this.token;
  }
}

export default new EmailAuthService();