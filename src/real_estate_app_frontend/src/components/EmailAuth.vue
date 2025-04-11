<template>
  <div class="auth-container">
    <div v-if="isAuthenticated" class="auth-profile">
      <div class="user-info">
        <span class="email-badge">Email</span>
        <p class="user-email">{{ email }}</p>
        <p class="principal-id">{{ principalId }}</p>
      </div>
      <button @click="logout" class="logout-btn">
        <span class="btn-icon">↩️</span>
        Logout
      </button>
    </div>
    <div v-else class="auth-card">
      <div class="tabs">
        <button 
          :class="['tab-btn', { active: activeTab === 'login' }]" 
          @click="activeTab = 'login'"
        >
          Login
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'register' }]" 
          @click="activeTab = 'register'"
        >
          Register
        </button>
      </div>
      
      <div v-if="activeTab === 'login'" class="form-container">
        <form @submit.prevent="handleLogin">
          <div class="form-group">
            <label for="login-email">Email Address</label>
            <input 
              id="login-email"
              type="email" 
              v-model="loginForm.email" 
              placeholder="Your email"
              required
            />
          </div>
          <div class="form-group">
            <label for="login-password">Password</label>
            <input 
              id="login-password"
              type="password" 
              v-model="loginForm.password"
              placeholder="Your password" 
              required
            />
          </div>
          <button 
            type="submit" 
            class="submit-btn" 
            :disabled="loading"
          >
            <span v-if="loading" class="loading-spinner"></span>
            <span v-else>Login</span>
          </button>
          <p v-if="error" class="error">{{ error }}</p>
        </form>
      </div>
      
      <div v-else class="form-container">
        <form @submit.prevent="handleRegister">
          <div class="form-group">
            <label for="register-email">Email Address</label>
            <input 
              id="register-email"
              type="email" 
              v-model="registerForm.email"
              placeholder="Your email"
              required
            />
          </div>
          <div class="form-group">
            <label for="register-password">Password</label>
            <input 
              id="register-password"
              type="password" 
              v-model="registerForm.password"
              placeholder="Create password"
              required
            />
          </div>
          <div class="form-group">
            <label for="register-confirm">Confirm Password</label>
            <input 
              id="register-confirm"
              type="password" 
              v-model="registerForm.confirmPassword"
              placeholder="Confirm password"
              required
            />
          </div>
          <button 
            type="submit" 
            class="submit-btn" 
            :disabled="loading || registerForm.password !== registerForm.confirmPassword"
          >
            <span v-if="loading" class="loading-spinner"></span>
            <span v-else>Create Account</span>
          </button>
          <p v-if="error" class="error">{{ error }}</p>
          <p v-if="registerForm.password !== registerForm.confirmPassword" class="error">
            Passwords do not match
          </p>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import EmailAuthService from '../services/EmailAuthService';

export default {
  name: 'EmailAuth',
  data() {
    return {
      isAuthenticated: false,
      email: '',
      principalId: 'Not authenticated',
      activeTab: 'login',
      loginForm: {
        email: '',
        password: ''
      },
      registerForm: {
        email: '',
        password: '',
        confirmPassword: ''
      },
      loading: false,
      error: ''
    }
  },
  async mounted() {
    this.isAuthenticated = await EmailAuthService.checkAuthentication();
    if (this.isAuthenticated) {
      this.email = EmailAuthService.getEmail();
      this.principalId = await EmailAuthService.getPrincipal();
    }
  },
  methods: {
    async handleLogin() {
      this.loading = true;
      this.error = '';
      
      try {
        const success = await EmailAuthService.login(
          this.loginForm.email, 
          this.loginForm.password
        );
        
        if (success) {
          this.isAuthenticated = true;
          this.email = EmailAuthService.getEmail();
          this.principalId = await EmailAuthService.getPrincipal();
          this.$emit('login-success');
        } else {
          this.error = 'Invalid email or password';
        }
      } catch (err) {
        this.error = 'Login failed. Please try again.';
        console.error(err);
      } finally {
        this.loading = false;
      }
    },
    
    async handleRegister() {
      if (this.registerForm.password !== this.registerForm.confirmPassword) {
        this.error = 'Passwords do not match';
        return;
      }
      
      this.loading = true;
      this.error = '';
      
      try {
        const success = await EmailAuthService.register(
          this.registerForm.email, 
          this.registerForm.password
        );
        
        if (success) {
          this.isAuthenticated = true;
          this.email = EmailAuthService.getEmail();
          this.principalId = await EmailAuthService.getPrincipal();
          this.$emit('login-success');
        } else {
          this.error = 'Registration failed. Email may already be registered.';
        }
      } catch (err) {
        this.error = 'Registration failed. Please try again.';
        console.error(err);
      } finally {
        this.loading = false;
      }
    },
    
    async logout() {
      await EmailAuthService.logout();
      this.isAuthenticated = false;
      this.email = '';
      this.principalId = 'Not authenticated';
      this.$emit('logout-success');
    }
  }
}
</script>

<style scoped>
.auth-container {
  max-width: 480px;
  margin: 0 auto;
}

.auth-profile {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: white;
  padding: 15px 20px;
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
}

.user-info {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.email-badge {
  background-color: var(--primary);
  color: white;
  font-size: 0.7rem;
  font-weight: bold;
  padding: 3px 8px;
  border-radius: 10px;
  margin-bottom: 5px;
  display: inline-block;
}

.user-email {
  font-weight: 500;
  color: var(--dark);
}

.principal-id {
  font-size: 0.8rem;
  color: var(--gray);
  word-break: break-all;
  margin-top: 5px;
}

.auth-card {
  background-color: white;
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
  overflow: hidden;
}

.tabs {
  display: flex;
  border-bottom: 1px solid var(--gray-light);
}

.tab-btn {
  flex: 1;
  padding: 15px;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--gray);
  transition: all 0.2s ease;
}

.tab-btn.active {
  color: var(--primary);
  border-bottom: 2px solid var(--primary);
  background-color: var(--light);
}

.form-container {
  padding: 25px;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 6px;
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--dark);
}

input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--gray-light);
  border-radius: 6px;
  font-size: 0.95rem;
  transition: border-color 0.2s ease;
}

input:focus {
  outline: none;
  border-color: var(--primary);
  box-shadow: 0 0 0 2px rgba(79, 70, 229, 0.2);
}

.submit-btn, .logout-btn {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  font-size: 0.95rem;
  position: relative;
}

.submit-btn {
  background-color: var(--primary);
  color: white;
  transition: all 0.2s ease;
}

.submit-btn:hover:not(:disabled) {
  background-color: var(--primary-dark);
}

.submit-btn:disabled {
  background-color: var(--gray-light);
  cursor: not-allowed;
  color: var(--gray);
}

.logout-btn {
  background-color: white;
  color: var(--danger);
  border: 1px solid #fecaca;
  display: flex;
  align-items: center;
  justify-content: center;
}

.logout-btn:hover {
  background-color: #fee2e2;
}

.btn-icon {
  margin-right: 8px;
  font-size: 1.1em;
}

.error {
  color: var(--danger);
  font-size: 0.85rem;
  margin-top: 12px;
  background-color: #fee2e2;
  padding: 8px 12px;
  border-radius: 4px;
  display: flex;
  align-items: center;
}

.error::before {
  content: "⚠️";
  margin-right: 8px;
}

.loading-spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255,255,255,0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: spin 1s ease-in-out infinite;
  position: absolute;
  left: calc(50% - 10px);
  top: calc(50% - 10px);
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@media (max-width: 500px) {
  .auth-profile {
    flex-direction: column;
    gap: 15px;
  }
  
  .user-info {
    align-items: center;
  }
}
</style>