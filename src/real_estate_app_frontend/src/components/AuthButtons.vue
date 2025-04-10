<template>
    <div class="auth-container">
      <div v-if="isAuthenticated">
        <p class="principal-id">{{ principalId }}</p>
        <button @click="logout" class="logout-btn">Logout</button>
      </div>
      <button v-else @click="login" class="login-btn">
        Login with Internet Identity
      </button>
    </div>
  </template>
  
  <script>
  import AuthService from '../services/AuthService';
  
  export default {
    name: 'AuthButtons',
    data() {
      return {
        isAuthenticated: false,
        principalId: 'Not authenticated'
      }
    },
    async mounted() {
      this.isAuthenticated = await AuthService.initialize();
      if (this.isAuthenticated) {
        this.principalId = AuthService.getPrincipalText();
      }
    },
    methods: {
      async login() {
        try {
          await AuthService.login();
          this.isAuthenticated = true;
          this.principalId = AuthService.getPrincipalText();
          this.$emit('login-success');
        } catch (error) {
          console.error('Login failed:', error);
        }
      },
      async logout() {
        await AuthService.logout();
        this.isAuthenticated = false;
        this.principalId = 'Not authenticated';
        this.$emit('logout-success');
      }
    }
  }
  </script>
  
  <style scoped>
  .auth-container {
    margin-bottom: 20px;
    display: flex;
    justify-content: flex-end;
    align-items: center;
  }
  
  .principal-id {
    font-size: 0.8rem;
    color: #555;
    margin-right: 10px;
  }
  
  .login-btn, .logout-btn {
    padding: 8px 15px;
    border-radius: 4px;
    cursor: pointer;
    font-weight: bold;
    border: none;
  }
  
  .login-btn {
    background-color: #1a73e8;
    color: white;
  }
  
  .logout-btn {
    background-color: #f44336;
    color: white;
  }
  </style>