import { Actor, HttpAgent } from '@dfinity/agent';
import { IDL } from '@dfinity/candid';  // Add this import

// Try to import the declarations, but provide fallbacks if they don't exist
let authCanisterId;
let createAuthActor;

try {
  // Try to get the canister ID from the declarations
  const authModule = await import("../../../declarations/auth/index.js");
  authCanisterId = authModule.canisterId;
  createAuthActor = authModule.createActor;
  console.log("Imported auth canister ID:", authCanisterId);
} catch (error) {
  console.warn("Could not import auth declarations, using fallback approach");
  
  // If we're in development, we'll use a local canister ID
  // This should match what's in your dfx.json for the auth canister
  authCanisterId = process.env.NODE_ENV === "production" 
    ? "uxrrr-q7777-77774-qaaaq-cai" 
    : "uxrrr-q7777-77774-qaaaq-cai"; // Use the deployed canister ID
  
  console.log("Using fallback auth canister ID:", authCanisterId);
}

// Create the auth actor
const createAuthClient = async () => {
  try {
    const agent = new HttpAgent({
      host: process.env.NODE_ENV === "production" ? undefined : "http://localhost:4943",
    });
    
    // Only fetch the root key in development
    if (process.env.NODE_ENV !== "production") {
      await agent.fetchRootKey();
    }
    
    // If we have the createActor function from the declarations, use it
    if (createAuthActor) {
      return createAuthActor(authCanisterId, { agent });
    } 
    
    // Otherwise, create a basic actor
    // You'll need to provide the interface of your auth canister
    return Actor.createActor(
      ({ 
        login: IDL.Func([IDL.Text, IDL.Text], [IDL.Opt(IDL.Text)], []),
        logout: IDL.Func([IDL.Text], [IDL.Bool], []),
        register: IDL.Func([IDL.Text, IDL.Text], [IDL.Bool], []),
        verifySession: IDL.Func([IDL.Text], [IDL.Bool], ["query"]),
        getPrincipalFromToken: IDL.Func([IDL.Text], [IDL.Text], []),
        requestPasswordReset: IDL.Func([IDL.Text], [IDL.Bool], []),
        resetPassword: IDL.Func([IDL.Text, IDL.Text, IDL.Text], [IDL.Bool], [])
      }),
      {
        agent,
        canisterId: authCanisterId
      }
    );
  } catch (error) {
    console.error("Error creating auth client:", error);
    throw error;
  }
};

// Replace the auth client initialization with this synchronized approach
let authPromise = createAuthClient();
let auth = null;

class EmailAuthService {
  constructor() {
    this.token = this.getStoredToken();
    this.email = localStorage.getItem("auth_email") || null;
    this.expiryTime = localStorage.getItem("auth_expiry") 
      ? parseInt(localStorage.getItem("auth_expiry")) 
      : 0;
    
    // Initialize auth client immediately
    this.initAuth();
  }
  
  async initAuth() {
    try {
      auth = await authPromise;
      console.log("Auth client initialized successfully");
    } catch (error) {
      console.error("Failed to initialize auth client:", error);
    }
  }
  
  // Ensure auth is initialized before any API call
  async ensureAuth() {
    if (!auth) {
      auth = await authPromise;
    }
    return auth;
  }

  // Secure token storage in either localStorage or sessionStorage
  getStoredToken() {
    // Try to get token from sessionStorage (temporary session)
    const sessionToken = sessionStorage.getItem("auth_token");
    if (sessionToken) return sessionToken;
    
    // Try to get token from localStorage (persistent)
    const localToken = localStorage.getItem("auth_token");
    
    // Check token expiry
    const expiryTime = localStorage.getItem("auth_expiry");
    if (localToken && expiryTime) {
      // If token is expired, remove it
      if (Date.now() > parseInt(expiryTime)) {
        this.clearStoredTokens();
        return null;
      }
      return localToken;
    }
    
    return null;
  }
  
  setStoredToken(token, email, remember = false) {
    this.token = token;
    this.email = email;
    
    if (remember) {
      // If "remember me" is checked, store in localStorage with expiry
      const expiryTime = Date.now() + (30 * 24 * 60 * 60 * 1000); // 30 days
      localStorage.setItem("auth_token", token);
      localStorage.setItem("auth_email", email);
      localStorage.setItem("auth_expiry", expiryTime.toString());
      this.expiryTime = expiryTime;
    } else {
      // Otherwise store in sessionStorage (cleared when browser is closed)
      sessionStorage.setItem("auth_token", token);
      localStorage.setItem("auth_email", email);
    }
  }
  
  clearStoredTokens() {
    sessionStorage.removeItem("auth_token");
    localStorage.removeItem("auth_token");
    localStorage.removeItem("auth_email");
    localStorage.removeItem("auth_expiry");
    this.token = null;
    this.email = null;
    this.expiryTime = 0;
  }

  isAuthenticated() {
    return !!this.token;
  }

  async checkAuthentication() {
    if (!this.token) return false;
    
    try {
      const authClient = await this.ensureAuth();
      const isValid = await authClient.verifySession(this.token);
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
      const authClient = await this.ensureAuth();
      const success = await authClient.register(email, password);
      if (success) {
        return await this.login(email, password);
      }
      return false;
    } catch (error) {
      console.error("Registration error:", error);
      return false;
    }
  }

  async login(email, password, remember = false) {
    try {
      const authClient = await this.ensureAuth();
      const tokenOpt = await authClient.login(email, password);
      if (tokenOpt && tokenOpt.length > 0) {
        this.setStoredToken(tokenOpt[0], email, remember);
        return true;
      }
      return false;
    } catch (error) {
      console.error("Login error:", error);
      return false;
    }
  }

  async logout() {
    if (this.token) {
      try {
        const authClient = await this.ensureAuth();
        await authClient.logout(this.token);
      } catch (error) {
        console.error("Logout error:", error);
      }
    }
    
    this.clearStoredTokens();
  }

  getEmail() {
    return this.email;
  }

  getToken() {
    return this.token;
  }

  // Add this new method right after getToken()
  async getPrincipalId() {
    if (!this.token) return 'Not authenticated';
    
    try {
      const authClient = await this.ensureAuth();
      // Get the principal ID from the auth canister
      const principal = await authClient.getPrincipalFromToken(this.token);
      return principal;
    } catch (error) {
      console.error("Error getting principal ID:", error);
      return 'Error retrieving principal';
    }
  }

  async requestPasswordReset(email) {
    try {
      const authClient = await this.ensureAuth();
      const result = await authClient.requestPasswordReset(email);
      return result;
    } catch (error) {
      console.error("Password reset request error:", error);
      return false;
    }
  }

  async resetPassword(email, token, newPassword) {
    try {
      const authClient = await this.ensureAuth();
      const result = await authClient.resetPassword(email, token, newPassword);
      return result;
    } catch (error) {
      console.error("Password reset error:", error);
      return false;
    }
  }
  
  // Get user profile details
  async getUserProfile() {
    if (!this.token) return null;
    
    try {
      // This would be implemented in your auth canister
      // const profile = await auth.getUserProfile(this.token);
      // return profile;
      
      // For now, just return basic info
      return {
        email: this.email,
        lastLogin: new Date().toISOString()
      };
    } catch (error) {
      console.error("Get profile error:", error);
      return null;
    }
  }
}

export default new EmailAuthService();