import { auth } from "../../../declarations/auth/index.js";

class EmailAuthService {
  constructor() {
    this.token = localStorage.getItem("auth_token") || null;
    this.email = localStorage.getItem("auth_email") || null;
  }

  isAuthenticated() {
    return !!this.token;
  }

  async checkAuthentication() {
    if (!this.token) return false;
    
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
      const tokenOpt = await auth.login(email, password);
      if (tokenOpt && tokenOpt.length > 0) {
        this.token = tokenOpt[0];
        this.email = email;
        localStorage.setItem("auth_token", this.token);
        localStorage.setItem("auth_email", email);
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
        await auth.logout(this.token);
      } catch (error) {
        console.error("Logout error:", error);
      }
    }
    
    this.token = null;
    this.email = null;
    localStorage.removeItem("auth_token");
    localStorage.removeItem("auth_email");
  }

  getEmail() {
    return this.email;
  }

  getToken() {
    return this.token;
  }
}

export default new EmailAuthService();