import { AuthClient } from "@dfinity/auth-client";
import { Principal } from "@dfinity/principal";

// Default host for Internet Identity in local development
const II_LOCAL_HOST = "http://localhost:4943/?canisterId=rdmx6-jaaaa-aaaaa-aaadq-cai"; 
// Mainnet host for Internet Identity
const II_MAINNET_HOST = "https://identity.ic0.app";

class AuthService {
  constructor() {
    this.authClient = null;
    this.identity = null;
  }

  async initialize() {
    this.authClient = await AuthClient.create();
    if (await this.authClient.isAuthenticated()) {
      this.identity = await this.authClient.getIdentity();
      return true;
    }
    return false;
  }

  async login() {
    return new Promise((resolve, reject) => {
      this.authClient.login({
        identityProvider: process.env.DFX_NETWORK === "local" ? II_LOCAL_HOST : II_MAINNET_HOST,
        onSuccess: () => {
          this.authClient.getIdentity().then(identity => {
            this.identity = identity;
            resolve(identity);
          });
        },
        onError: (error) => {
          reject(error);
        }
      });
    });
  }

  async logout() {
    if (this.authClient) {
      await this.authClient.logout();
      this.identity = null;
      return true;
    }
    return false;
  }

  getIdentity() {
    return this.identity;
  }

  getPrincipal() {
    if (this.identity) {
      return this.identity.getPrincipal();
    }
    return null;
  }

  getPrincipalText() {
    const principal = this.getPrincipal();
    if (principal) {
      return principal.toString();
    }
    return "Not authenticated";
  }
}

export default new AuthService();