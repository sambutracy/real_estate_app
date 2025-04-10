<template>
  <div class="auth-container">
    <div v-if="isAuthenticated" class="auth-profile">
      <div class="auth-info">
        <span class="auth-badge">NFID</span>
        <p class="principal-id">{{ principalId }}</p>
      </div>
      <button @click="logout" class="logout-btn">
        <span class="btn-icon">↩️</span>
        Logout
      </button>
    </div>
    <div v-else class="login-options">
      <button @click="login" class="login-btn nfid-btn">
        <span class="btn-icon">🔐</span>
        Login with NFID
      </button>
    </div>
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
        // Always use 'nfid' for authentication now
        const success = await AuthService.login('nfid');
        if (success) {
          this.isAuthenticated = true;
          this.principalId = AuthService.getPrincipalText();
          this.$emit('login-success');
        }
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
  width: 100%;
  max-width: 500px;
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

.auth-info {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.auth-badge {
  background-color: #6200ea;
  color: white;
  font-size: 0.7rem;
  font-weight: bold;
  padding: 3px 8px;
  border-radius: 10px;
  margin-bottom: 5px;
  display: inline-block;
}

.principal-id {
  font-size: 0.85rem;
  color: var(--gray);
  font-family: monospace;
  background-color: var(--light);
  padding: 4px 8px;
  border-radius: 4px;
  word-break: break-all;
}

.login-options {
  display: flex;
  justify-content: center;
}

.login-btn, .logout-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px 25px;
  border-radius: var(--border-radius);
  cursor: pointer;
  font-weight: 500;
  border: none;
  transition: all 0.2s ease;
}

.login-btn.nfid-btn {
  background-color: #6200ea;
  color: white;
  box-shadow: 0 4px 12px rgba(98, 0, 234, 0.3);
}

.login-btn.nfid-btn:hover {
  background-color: #520bc4;
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(98, 0, 234, 0.4);
}

.logout-btn {
  background-color: white;
  color: var(--danger);
  border: 1px solid #fecaca;
}

.logout-btn:hover {
  background-color: #fee2e2;
}

.btn-icon {
  margin-right: 8px;
  font-size: 1.1em;
}

@media (max-width: 500px) {
  .auth-profile {
    flex-direction: column;
    gap: 15px;
  }
  
  .auth-info {
    align-items: center;
  }
  
  .login-btn, .logout-btn {
    width: 100%;
  }
}
</style>