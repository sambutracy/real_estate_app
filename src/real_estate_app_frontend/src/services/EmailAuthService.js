import { idlFactory } from "../../../declarations/auth/auth.did.js";
import { Actor, HttpAgent } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
// Import the correct canister ID from the generated declarations
import { canisterId as authCanisterId } from "../../../declarations/auth/index.js";
import { createActor } from "../../../declarations/auth";

// Add this function at the top of the file, before the EmailAuthService class

// Helper function to generate a token on client side
function generateToken() {
  const timestamp = Date.now();
  const randomPart = Math.floor(Math.random() * 1000000);
  return `${timestamp}-${randomPart}`;
}

// Replace your existing getHost function with this:
const getHost = () => {
  if (process.env.NODE_ENV === "production") return undefined;
  
  const hostname = window.location.hostname;
  console.log("Current hostname:", hostname);
  
  // More specific Codespaces detection
  if (hostname.includes('github.dev') || 
      hostname.includes('githubpreview') || 
      hostname.includes('codespaces') || 
      hostname.endsWith('.app.github.dev')) {
    
    // Use the window.location.origin for the base URL, but replace port with 8000
    // Format example: https://yourname-yourproject-1234.app.github.dev:3000 → https://yourname-yourproject-1234.app.github.dev:8000
    const currentUrl = window.location.origin;
    const icUrl = currentUrl.replace(/:\d+$/, ':8000');
    
    console.log("REMOTE ENVIRONMENT DETECTED!");
    console.log("Using remote IC URL:", icUrl);
    return icUrl;
  }
  
  console.log("LOCAL ENVIRONMENT DETECTED");
  return "http://localhost:8000";  // Try changing to port 8000 
};

// Add this right after the getHost function but before creating the agent
const forceRemoteMode = false; // Set to true to force remote URL for testing

const agent = new HttpAgent({ 
  host: forceRemoteMode ? 
    window.location.origin.replace(/:\d+$/, ':8000') : 
    getHost() 
});

console.log("FORCED HOST URL:", agent._host);

// Add this right after creating the agent
console.log("Agent host:", getHost());
console.log("Auth canister ID:", authCanisterId);

// Fetch root key for local dev environment
if (process.env.NODE_ENV !== "production") {
  try {
    agent.fetchRootKey();
    console.log("Root key fetched successfully");
  } catch (err) {
    console.warn("Unable to fetch root key. Error:", err);
  }
}

// Log the canister ID we're using
console.log("Using auth canister ID:", authCanisterId);

// Create actor with the CORRECT canister ID
const auth = Actor.createActor(idlFactory, {
  agent,
  canisterId: authCanisterId // Use the imported ID instead of hardcoded placeholder
});

// Add a simple test function
window.testAuthCanister = async () => {
  try {
    console.log("Testing auth canister connectivity...");
    const response = await fetch(`${getHost()}/api/v2/status`);
    console.log("IC replica status response:", response.status);
    const data = await response.text();
    console.log("IC replica data:", data);
  } catch (error) {
    console.error("IC connectivity test failed:", error);
  }
};

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
      
      // Create agent with the correct API version
      const loginAgent = new HttpAgent({ 
        host: "http://localhost:8000"
      });
      loginAgent._isLocalReplica = true; // Skip certificate verification for local dev

      // Special configuration for v2 API
      loginAgent._apiVersion = "v2"; // Force API v2 - use _apiVersion directly
      
      if (process.env.NODE_ENV !== "production") {
        try {
          await loginAgent.fetchRootKey();
          console.log("Root key fetched successfully");
        } catch (e) {
          console.warn("Using alternative root key method");
        }
      }
      
      // Use createActor helper instead of manual Actor.createActor
      const authActor = createActor(authCanisterId, { agent: loginAgent });
      
      const result = await authActor.login(email, password);
      console.log("Login response:", result);
      
      // Handle the Result type correctly
      // After successful login
      if (result && "ok" in result) {
        this.email = email;
        this.token = generateToken();
        
        // Make sure we get the ORIGINAL principal from the backend
        if (typeof result.ok.principal === 'string') {
          this.principalId = result.ok.principal;
          console.log("Principal from backend (string):", this.principalId);
        } else if (result.ok.principal._isPrincipal) {
          this.principalId = result.ok.principal.toText();
          console.log("Principal from backend (Principal object):", this.principalId);
        } else {
          console.log("Full principal object from backend:", result.ok.principal);
          try {
            // Try getting it from an array representation
            if (Array.isArray(result.ok.principal)) {
              const principal = Principal.fromUint8Array(new Uint8Array(result.ok.principal));
              this.principalId = principal.toText();
            } else {
              this.principalId = String(result.ok.principal);
            }
          } catch (e) {
            console.error("Error processing principal:", e);
            this.principalId = String(result.ok.principal);
          }
        }
        
        console.log("Principal ID length:", this.principalId.length);
        // Add right after setting the principalId
        console.log("FINAL PRINCIPAL TO USE:", this.principalId);
        console.log("PRINCIPAL LENGTH:", this.principalId.length);
        if (this.principalId.length < 20) {
          console.warn("WARNING: Principal appears to be truncated!");
        } else {
          console.log("Principal has proper length - authentication should work correctly");
        }
        // Rest of the login code...
        
        this.tokenExpiry = Date.now() + (7 * 24 * 60 * 60 * 1000); // 7 days
        
        localStorage.setItem("auth_token", this.token);
        localStorage.setItem("auth_email", email);
        localStorage.setItem("auth_token_expiry", this.tokenExpiry.toString());
        localStorage.setItem("auth_principal", this.principalId);
        
        // Update user principal with a retry
        console.log("Using original principal from backend, no overwriting.");
        
        return true;
      } else if (result && "err" in result) {
        console.error("Login error:", result.err);
        return false;
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

  // Add these functions for better principal handling
  getPrincipalFromText(principalText) {
    try {
      return Principal.fromText(principalText);
    } catch (e) {
      console.error("Invalid principal text:", e);
      return null;
    }
  }

  // Add this method to EmailAuthService class
  getSharedAgent() {
    // Create a new agent with the same identity
    const sharedAgent = new HttpAgent({ 
      host: "http://localhost:8000"
    });
    
    // Force API version v2
    sharedAgent._apiVersionSupported = "v2";
    
    // If we have principal ID, set it
    if (this.principalId) {
      console.log("Setting shared agent with principal:", this.principalId);
    }
    
    return sharedAgent;
  }
}

export default new EmailAuthService();