<template>
    <div class="auth-container">
      <div v-if="isAuthenticated">
        <p class="user-email">{{ email }}</p>
        <button @click="logout" class="logout-btn">Logout</button>
      </div>
      <div v-else>
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
              <label for="login-email">Email</label>
              <input 
                id="login-email"
                type="email" 
                v-model="loginForm.email" 
                required
              />
            </div>
            <div class="form-group">
              <label for="login-password">Password</label>
              <input 
                id="login-password"
                type="password" 
                v-model="loginForm.password" 
                required
              />
            </div>
            <button 
              type="submit" 
              class="submit-btn" 
              :disabled="loading"
            >
              {{ loading ? 'Logging in...' : 'Login' }}
            </button>
            <p v-if="error" class="error">{{ error }}</p>
          </form>
        </div>
        
        <div v-else class="form-container">
          <form @submit.prevent="handleRegister">
            <div class="form-group">
              <label for="register-email">Email</label>
              <input 
                id="register-email"
                type="email" 
                v-model="registerForm.email" 
                required
              />
            </div>
            <div class="form-group">
              <label for="register-password">Password</label>
              <input 
                id="register-password"
                type="password" 
                v-model="registerForm.password" 
                required
              />
            </div>
            <div class="form-group">
              <label for="register-confirm">Confirm Password</label>
              <input 
                id="register-confirm"
                type="password" 
                v-model="registerForm.confirmPassword" 
                required
              />
            </div>
            <button 
              type="submit" 
              class="submit-btn" 
              :disabled="loading || registerForm.password !== registerForm.confirmPassword"
            >
              {{ loading ? 'Registering...' : 'Register' }}
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
        this.$emit('logout-success');
      }
    }
  }
  </script>
  
  <style scoped>
  .auth-container {
    max-width: 400px;
    margin: 0 auto;
    padding: 20px;
    background-color: #f8f9fa;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }
  
  .user-email {
    margin-bottom: 10px;
    font-weight: bold;
  }
  
  .tabs {
    display: flex;
    margin-bottom: 15px;
  }
  
  .tab-btn {
    flex: 1;
    padding: 10px;
    background: none;
    border: none;
    border-bottom: 2px solid #ddd;
    cursor: pointer;
  }
  
  .tab-btn.active {
    border-bottom: 2px solid #1a73e8;
    font-weight: bold;
  }
  
  .form-group {
    margin-bottom: 15px;
  }
  
  label {
    display: block;
    margin-bottom: 5px;
    font-weight: bold;
  }
  
  input {
    width: 100%;
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
  }
  
  .submit-btn, .logout-btn {
    width: 100%;
    padding: 10px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-weight: bold;
  }
  
  .submit-btn {
    background-color: #1a73e8;
    color: white;
  }
  
  .submit-btn:disabled {
    background-color: #a9a9a9;
    cursor: not-allowed;
  }
  
  .logout-btn {
    background-color: #f44336;
    color: white;
  }
  
  .error {
    color: #f44336;
    font-size: 0.9rem;
    margin-top: 10px;
  }
  </style>