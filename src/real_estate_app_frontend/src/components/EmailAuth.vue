<template>
  <div class="email-auth">
    <!-- Authenticated User View -->
    <div v-if="isAuthenticated" class="auth-card auth-success">
      <div class="auth-header">
        <div class="user-avatar">{{ emailInitial }}</div>
        <div class="user-details">
          <span class="email-badge">Verified</span>
          <h3 class="welcome-text">Welcome back!</h3>
          <p class="user-email">{{ email }}</p>
          <div class="principal-container">
            <span class="principal-label">Principal ID:</span>
            <p class="principal-id">{{ principalId }}</p>
          </div>
        </div>
      </div>
      <button @click="logout" class="btn-logout">
        <span class="icon">↩️</span>
        <span>Sign Out</span>
      </button>
    </div>
    
    <!-- Authentication Forms -->
    <div v-else class="auth-card">
      <!-- Card Header -->
      <div class="auth-card-header">
        <div class="tab-buttons">
          <button 
            v-for="tab in tabs" 
            :key="tab.id"
            :class="['tab-button', { active: activeTab === tab.id }]"
            @click="switchTab(tab.id)"
          >
            {{ tab.label }}
          </button>
        </div>
      </div>
      
      <!-- Login Form -->
      <transition name="fade" mode="out-in">
        <div v-if="activeTab === 'login'" class="auth-form" key="login">
          <h2>Welcome Back</h2>
          <p class="form-subtitle">Sign in to continue to ICP Real Estate</p>
          
          <form @submit.prevent="handleLogin">
            <div class="form-group">
              <label for="login-email">Email Address</label>
              <div class="input-wrapper">
                <span class="input-icon">📧</span>
                <input
                  id="login-email"
                  type="email"
                  v-model.trim="loginForm.email"
                  placeholder="Your email"
                  required
                  :class="{ 'input-error': errors.login.email }"
                />
              </div>
              <p v-if="errors.login.email" class="error-text">{{ errors.login.email }}</p>
            </div>
            
            <div class="form-group">
              <div class="label-with-action">
                <label for="login-password">Password</label>
                <a href="#" class="forgot-link" @click.prevent="switchTab('reset')">Forgot?</a>
              </div>
              <div class="input-wrapper">
                <span class="input-icon">🔒</span>
                <input
                  id="login-password"
                  :type="showPassword ? 'text' : 'password'"
                  v-model="loginForm.password"
                  placeholder="Your password"
                  required
                  :class="{ 'input-error': errors.login.password }"
                />
                <button 
                  type="button" 
                  class="password-toggle" 
                  @click="showPassword = !showPassword"
                >
                  {{ showPassword ? '👁️' : '👁️‍🗨️' }}
                </button>
              </div>
              <p v-if="errors.login.password" class="error-text">{{ errors.login.password }}</p>
            </div>
            
            <div class="form-check">
              <input type="checkbox" id="remember-me" v-model="loginForm.remember">
              <label for="remember-me">Remember me for 30 days</label>
            </div>
            
            <button type="submit" class="btn-submit" :disabled="loading">
              <span v-if="loading" class="loader"></span>
              <span v-else>Sign In</span>
            </button>
          </form>
          
          <p v-if="generalError" class="general-error">{{ generalError }}</p>
          
          <div class="form-footer">
            <p>Don't have an account? <a href="#" @click.prevent="switchTab('register')">Create Account</a></p>
          </div>
        </div>
        
        <!-- Register Form -->
        <div v-else-if="activeTab === 'register'" class="auth-form" key="register">
          <h2>Create Account</h2>
          <p class="form-subtitle">Join ICP Real Estate today</p>
          
          <form @submit.prevent="handleRegister">
            <div class="form-group">
              <label for="register-email">Email Address</label>
              <div class="input-wrapper">
                <span class="input-icon">📧</span>
                <input
                  id="register-email"
                  type="email"
                  v-model.trim="registerForm.email"
                  placeholder="Your email"
                  required
                  :class="{ 'input-error': errors.register.email }"
                />
              </div>
              <p v-if="errors.register.email" class="error-text">{{ errors.register.email }}</p>
            </div>
            
            <div class="form-group">
              <label for="register-password">Password</label>
              <div class="input-wrapper">
                <span class="input-icon">🔒</span>
                <input
                  id="register-password"
                  :type="showPassword ? 'text' : 'password'"
                  v-model="registerForm.password"
                  placeholder="Create password (min 8 characters)"
                  required
                  :class="{ 'input-error': errors.register.password }"
                />
                <button 
                  type="button" 
                  class="password-toggle" 
                  @click="showPassword = !showPassword"
                >
                  {{ showPassword ? '👁️' : '👁️‍🗨️' }}
                </button>
              </div>
              <div v-if="registerForm.password" class="password-strength">
                <div class="strength-meter">
                  <div 
                    class="strength-value" 
                    :style="{width: `${passwordStrength.score * 25}%`}"
                    :class="passwordStrength.class"
                  ></div>
                </div>
                <span class="strength-text" :class="passwordStrength.class">
                  {{ passwordStrength.text }}
                </span>
              </div>
              <p v-if="errors.register.password" class="error-text">{{ errors.register.password }}</p>
            </div>
            
            <div class="form-group">
              <label for="register-confirm">Confirm Password</label>
              <div class="input-wrapper">
                <span class="input-icon">🔒</span>
                <input
                  id="register-confirm"
                  :type="showPassword ? 'text' : 'password'"
                  v-model="registerForm.confirmPassword"
                  placeholder="Confirm password"
                  required
                  :class="{ 'input-error': errors.register.confirmPassword }"
                />
              </div>
              <p v-if="errors.register.confirmPassword" class="error-text">{{ errors.register.confirmPassword }}</p>
            </div>
            
            <div class="form-check">
              <input type="checkbox" id="terms" v-model="registerForm.acceptTerms" required>
              <label for="terms">I agree to the <a href="#" @click.prevent="showTerms = true">Terms & Conditions</a></label>
            </div>
            
            <button type="submit" class="btn-submit" :disabled="loading || !registerForm.acceptTerms">
              <span v-if="loading" class="loader"></span>
              <span v-else>Create Account</span>
            </button>
          </form>
          
          <p v-if="generalError" class="general-error">{{ generalError }}</p>
          
          <div class="form-footer">
            <p>Already have an account? <a href="#" @click.prevent="switchTab('login')">Sign In</a></p>
          </div>
        </div>
        
        <!-- Password Reset Form -->
        <div v-else class="auth-form" key="reset">
          <h2>Reset Password</h2>
          <p class="form-subtitle">{{ resetTokenSent ? 'Enter the token sent to your email' : 'We\'ll email you a reset link' }}</p>
          
          <form @submit.prevent="handlePasswordReset">
            <div class="form-group">
              <label for="reset-email">Email Address</label>
              <div class="input-wrapper">
                <span class="input-icon">📧</span>
                <input
                  id="reset-email"
                  type="email"
                  v-model.trim="resetForm.email"
                  placeholder="Your email"
                  required
                  :disabled="resetTokenSent"
                  :class="{ 'input-error': errors.reset.email }"
                />
              </div>
              <p v-if="errors.reset.email" class="error-text">{{ errors.reset.email }}</p>
            </div>
            
            <template v-if="resetTokenSent">
              <div class="form-group">
                <label for="reset-token">Reset Token</label>
                <div class="input-wrapper">
                  <span class="input-icon">🔑</span>
                  <input
                    id="reset-token"
                    type="text"
                    v-model.trim="resetForm.token"
                    placeholder="Enter token from email"
                    required
                    :class="{ 'input-error': errors.reset.token }"
                  />
                </div>
                <p v-if="errors.reset.token" class="error-text">{{ errors.reset.token }}</p>
              </div>
              
              <div class="form-group">
                <label for="new-password">New Password</label>
                <div class="input-wrapper">
                  <span class="input-icon">🔒</span>
                  <input
                    id="new-password"
                    :type="showPassword ? 'text' : 'password'"
                    v-model="resetForm.newPassword"
                    placeholder="Create new password"
                    required
                    :class="{ 'input-error': errors.reset.newPassword }"
                  />
                  <button 
                    type="button" 
                    class="password-toggle" 
                    @click="showPassword = !showPassword"
                  >
                    {{ showPassword ? '👁️' : '👁️‍🗨️' }}
                  </button>
                </div>
                <p v-if="errors.reset.newPassword" class="error-text">{{ errors.reset.newPassword }}</p>
              </div>
              
              <div class="form-group">
                <label for="confirm-new-password">Confirm New Password</label>
                <div class="input-wrapper">
                  <span class="input-icon">🔒</span>
                  <input
                    id="confirm-new-password"
                    :type="showPassword ? 'text' : 'password'"
                    v-model="resetForm.confirmPassword"
                    placeholder="Confirm new password"
                    required
                    :class="{ 'input-error': errors.reset.confirmPassword }"
                  />
                </div>
                <p v-if="errors.reset.confirmPassword" class="error-text">{{ errors.reset.confirmPassword }}</p>
              </div>
            </template>
            
            <button type="submit" class="btn-submit" :disabled="loading">
              <span v-if="loading" class="loader"></span>
              <span v-else>{{ resetTokenSent ? 'Reset Password' : 'Send Reset Link' }}</span>
            </button>
          </form>
          
          <div v-if="resetSuccess" class="success-message">
            <span class="success-icon">✅</span>
            <p>{{ resetSuccess }}</p>
          </div>
          
          <p v-if="generalError" class="general-error">{{ generalError }}</p>
          
          <div class="form-footer">
            <p><a href="#" @click.prevent="switchTab('login')">Back to Sign In</a></p>
          </div>
        </div>
      </transition>
    </div>
    
    <!-- Terms and Conditions Modal -->
    <div v-if="showTerms" class="modal">
      <div class="modal-content">
        <h3>Terms & Conditions</h3>
        <div class="modal-body">
          <p>By creating an account on ICP Real Estate, you agree to our Terms of Service and Privacy Policy.</p>
          <p>We collect and process your data as described in our Privacy Policy. You can manage your privacy settings at any time.</p>
          <p>Your account information will be stored on the Internet Computer blockchain and will be subject to the security properties of the platform.</p>
        </div>
        <button @click="showTerms = false" class="btn-modal-close">Close</button>
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
      principalId: 'Loading principal...',
      activeTab: 'login',
      showPassword: false,
      showTerms: false,
      loading: false,
      generalError: '',
      resetSuccess: '',
      resetTokenSent: false,
      
      tabs: [
        { id: 'login', label: 'Login' },
        { id: 'register', label: 'Register' },
        { id: 'reset', label: 'Reset' }
      ],
      
      loginForm: {
        email: '',
        password: '',
        remember: false
      },
      
      registerForm: {
        email: '',
        password: '',
        confirmPassword: '',
        acceptTerms: false
      },
      
      resetForm: {
        email: '',
        token: '',
        newPassword: '',
        confirmPassword: ''
      },
      
      errors: {
        login: { email: '', password: '' },
        register: { email: '', password: '', confirmPassword: '' },
        reset: { email: '', token: '', newPassword: '', confirmPassword: '' }
      }
    };
  },
  
  computed: {
    emailInitial() {
      if (!this.email) return '?';
      return this.email.charAt(0).toUpperCase();
    },
    
    passwordStrength() {
      if (!this.registerForm.password) {
        return { score: 0, text: '', class: '' };
      }
      
      const password = this.registerForm.password;
      let score = 0;
      
      // Length check
      if (password.length >= 8) score++;
      if (password.length >= 12) score++;
      
      // Complexity checks
      if (/[A-Z]/.test(password)) score++;
      if (/[a-z]/.test(password)) score++;
      if (/[0-9]/.test(password)) score++;
      if (/[^A-Za-z0-9]/.test(password)) score++;
      
      // Adjust final score (max 4)
      score = Math.min(4, score);
      
      const strengthClasses = ['very-weak', 'weak', 'medium', 'strong', 'very-strong'];
      const strengthTexts = ['Very Weak', 'Weak', 'Medium', 'Strong', 'Very Strong'];
      
      return {
        score,
        text: strengthTexts[score],
        class: strengthClasses[score]
      };
    }
  },
  
  async mounted() {
    this.isAuthenticated = await EmailAuthService.checkAuthentication();
    if (this.isAuthenticated) {
      this.email = EmailAuthService.getEmail();
      this.principalId = await EmailAuthService.getPrincipalId();
    }
  },
  
  methods: {
    switchTab(tab) {
      this.activeTab = tab;
      this.resetErrors();
      this.generalError = '';
      this.resetSuccess = '';
    },
    
    resetErrors() {
      this.errors = {
        login: { email: '', password: '' },
        register: { email: '', password: '', confirmPassword: '' },
        reset: { email: '', token: '', newPassword: '', confirmPassword: '' }
      };
    },
    
    validateEmail(email) {
      const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      return re.test(String(email).toLowerCase());
    },
    
    validateLoginForm() {
      let isValid = true;
      this.errors.login = { email: '', password: '' };
      
      if (!this.loginForm.email) {
        this.errors.login.email = 'Email is required';
        isValid = false;
      } else if (!this.validateEmail(this.loginForm.email)) {
        this.errors.login.email = 'Please enter a valid email';
        isValid = false;
      }
      
      if (!this.loginForm.password) {
        this.errors.login.password = 'Password is required';
        isValid = false;
      }
      
      return isValid;
    },
    
    validateRegisterForm() {
      let isValid = true;
      this.errors.register = { email: '', password: '', confirmPassword: '' };
      
      if (!this.registerForm.email) {
        this.errors.register.email = 'Email is required';
        isValid = false;
      } else if (!this.validateEmail(this.registerForm.email)) {
        this.errors.register.email = 'Please enter a valid email';
        isValid = false;
      }
      
      if (!this.registerForm.password) {
        this.errors.register.password = 'Password is required';
        isValid = false;
      } else if (this.registerForm.password.length < 8) {
        this.errors.register.password = 'Password must be at least 8 characters';
        isValid = false;
      } else if (this.passwordStrength.score < 2) {
        this.errors.register.password = 'Please use a stronger password';
        isValid = false;
      }
      
      if (!this.registerForm.confirmPassword) {
        this.errors.register.confirmPassword = 'Please confirm your password';
        isValid = false;
      } else if (this.registerForm.password !== this.registerForm.confirmPassword) {
        this.errors.register.confirmPassword = 'Passwords do not match';
        isValid = false;
      }
      
      return isValid;
    },
    
    validateResetForm() {
      let isValid = true;
      this.errors.reset = { email: '', token: '', newPassword: '', confirmPassword: '' };
      
      if (!this.resetForm.email) {
        this.errors.reset.email = 'Email is required';
        isValid = false;
      } else if (!this.validateEmail(this.resetForm.email)) {
        this.errors.reset.email = 'Please enter a valid email';
        isValid = false;
      }
      
      if (this.resetTokenSent) {
        if (!this.resetForm.token) {
          this.errors.reset.token = 'Token is required';
          isValid = false;
        }
        
        if (!this.resetForm.newPassword) {
          this.errors.reset.newPassword = 'New password is required';
          isValid = false;
        } else if (this.resetForm.newPassword.length < 8) {
          this.errors.reset.newPassword = 'Password must be at least 8 characters';
          isValid = false;
        }
        
        if (!this.resetForm.confirmPassword) {
          this.errors.reset.confirmPassword = 'Please confirm your password';
          isValid = false;
        } else if (this.resetForm.newPassword !== this.resetForm.confirmPassword) {
          this.errors.reset.confirmPassword = 'Passwords do not match';
          isValid = false;
        }
      }
      
      return isValid;
    },
    
    async handleLogin() {
      if (!this.validateLoginForm()) return;
      
      this.loading = true;
      this.generalError = '';
      
      try {
        const success = await EmailAuthService.login(
          this.loginForm.email,
          this.loginForm.password,
          this.loginForm.remember
        );
        
        if (success) {
          this.isAuthenticated = true;
          this.email = EmailAuthService.getEmail();
          this.principalId = EmailAuthService.getPrincipalId();
          this.$emit('login-success');
        } else {
          this.generalError = 'Invalid email or password';
        }
      } catch (err) {
        console.error('Login error:', err);
        this.generalError = 'Login failed. Please try again.';
      } finally {
        this.loading = false;
      }
    },
    
    async handleRegister() {
      if (!this.validateRegisterForm()) return;
      
      this.loading = true;
      this.generalError = '';
      
      try {
        const success = await EmailAuthService.register(
          this.registerForm.email,
          this.registerForm.password
        );
        
        if (success) {
          this.isAuthenticated = true;
          this.email = EmailAuthService.getEmail();
          this.principalId = EmailAuthService.getPrincipalId();
          this.$emit('login-success');
        } else {
          this.generalError = 'Registration failed. Email may already be registered.';
        }
      } catch (err) {
        console.error('Registration error:', err);
        this.generalError = 'Registration failed. Please try again.';
      } finally {
        this.loading = false;
      }
    },
    
    async handlePasswordReset() {
      if (!this.validateResetForm()) return;
      
      this.loading = true;
      this.generalError = '';
      this.resetSuccess = '';
      
      try {
        if (!this.resetTokenSent) {
          // Step 1: Request reset token
          const result = await EmailAuthService.requestPasswordReset(this.resetForm.email);
          if (result) {
            this.resetTokenSent = true;
            this.resetSuccess = 'Reset token sent to your email. Please check your inbox.';
          } else {
            this.generalError = 'Failed to send reset token. Email may not be registered.';
          }
        } else {
          // Step 2: Reset password with token
          const result = await EmailAuthService.resetPassword(
            this.resetForm.email,
            this.resetForm.token,
            this.resetForm.newPassword
          );
          
          if (result) {
            this.resetSuccess = 'Password reset successful. You can now login with your new password.';
            this.resetTokenSent = false;
            this.resetForm = {
              email: this.resetForm.email,
              token: '',
              newPassword: '',
              confirmPassword: ''
            };
            
            // Switch to login tab after 2 seconds
            setTimeout(() => {
              this.switchTab('login');
            }, 2000);
          } else {
            this.generalError = 'Failed to reset password. Invalid token or token expired.';
          }
        }
      } catch (err) {
        console.error('Password reset error:', err);
        this.generalError = 'An error occurred. Please try again.';
      } finally {
        this.loading = false;
      }
    },
    
    async logout() {
      this.loading = true;
      await EmailAuthService.logout();
      this.isAuthenticated = false;
      this.email = '';
      this.principalId = '';
      this.loading = false;
      this.$emit('logout-success');
    }
  }
};
</script>

<style scoped>
.email-auth {
  width: 100%;
  max-width: 500px;
  margin: 0 auto;
  position: relative;
}

.auth-card {
  background-color: white;
  border-radius: 12px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.auth-success {
  padding: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

.auth-header {
  display: flex;
  align-items: center;
  gap: 16px;
  width: 100%;
}

.user-avatar {
  width: 50px;
  height: 50px;
  background-color: var(--primary);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: 600;
}

.user-details {
  flex: 1;
}

.welcome-text {
  margin: 4px 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--dark);
}

.user-email {
  font-size: 14px;
  color: var(--gray);
  word-break: break-all;
}

.email-badge {
  background-color: var(--success);
  color: white;
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 10px;
  display: inline-block;
  margin-bottom: 4px;
}

.principal-container {
  margin-top: 8px;
  background-color: var(--light);
  border-radius: 6px;
  padding: 8px;
}

.principal-label {
  font-size: 0.75rem;
  color: var(--gray);
  display: block;
  margin-bottom: 2px;
}

.principal-id {
  font-size: 0.8rem;
  color: var(--dark);
  font-family: monospace;
  word-break: break-all;
}

.btn-logout {
  width: 100%;
  background-color: white;
  color: var(--danger);
  border: 1px solid rgba(239, 68, 68, 0.2);
  padding: 12px;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: all 0.2s;
}

.btn-logout:hover {
  background-color: rgba(239, 68, 68, 0.05);
}

.auth-card-header {
  padding: 8px;
  border-bottom: 1px solid var(--gray-light);
}

.tab-buttons {
  display: flex;
  background-color: var(--light);
  border-radius: 8px;
  padding: 4px;
}

.tab-button {
  flex: 1;
  padding: 10px;
  background: none;
  border: none;
  border-radius: 6px;
  font-weight: 500;
  color: var(--gray);
  cursor: pointer;
  transition: all 0.2s;
}

.tab-button.active {
  background-color: white;
  color: var(--primary);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.auth-form {
  padding: 24px;
}

.auth-form h2 {
  font-size: 20px;
  font-weight: 600;
  color: var(--dark);
  margin-bottom: 8px;
}

.form-subtitle {
  color: var(--gray);
  font-size: 14px;
  margin-bottom: 24px;
}

.form-group {
  margin-bottom: 20px;
}

.label-with-action {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

label {
  display: block;
  margin-bottom: 8px;
  font-size: 14px;
  font-weight: 500;
  color: var(--dark);
}

.forgot-link {
  font-size: 13px;
  color: var(--primary);
  text-decoration: none;
}

.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 12px;
  font-size: 16px;
  color: var(--gray);
}

input[type="email"],
input[type="password"],
input[type="text"] {
  width: 100%;
  padding: 12px 40px 12px 40px;
  border: 1px solid var(--gray-light);
  border-radius: 8px;
  font-size: 15px;
  transition: all 0.2s;
}

input:focus {
  outline: none;
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
}

input.input-error {
  border-color: var(--danger);
}

.password-toggle {
  position: absolute;
  right: 12px;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 16px;
  color: var(--gray);
}

.error-text {
  margin-top: 6px;
  color: var(--danger);
  font-size: 13px;
}

.password-strength {
  margin-top: 8px;
}

.strength-meter {
  height: 4px;
  background-color: #eee;
  border-radius: 2px;
  overflow: hidden;
  margin-bottom: 4px;
}

.strength-value {
  height: 100%;
  border-radius: 2px;
  transition: width 0.3s;
}

.strength-text {
  font-size: 12px;
}

.very-weak { background-color: #ff4a4a; color: #ff4a4a; }
.weak { background-color: #ffa64a; color: #ffa64a; }
.medium { background-color: #ffee4a; color: #b0a500; }
.strong { background-color: #4ade80; color: #16a34a; }
.very-strong { background-color: #3b82f6; color: #2563eb; }

.form-check {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 20px;
}

.form-check label {
  margin-bottom: 0;
  font-size: 14px;
  font-weight: normal;
  color: var(--gray);
}

.form-check a {
  color: var(--primary);
  text-decoration: none;
}

.btn-submit {
  width: 100%;
  background-color: var(--primary);
  color: white;
  border: none;
  padding: 12px;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  position: relative;
  transition: all 0.2s;
}

.btn-submit:hover:not(:disabled) {
  background-color: var(--primary-dark);
  transform: translateY(-1px);
}

.btn-submit:disabled {
  background-color: var(--gray-light);
  color: var(--gray);
  cursor: not-allowed;
}

.loader {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: spin 0.8s ease-in-out infinite;
}

.general-error {
  margin-top: 16px;
  padding: 10px;
  background-color: rgba(239, 68, 68, 0.1);
  border-radius: 8px;
  color: var(--danger);
  font-size: 14px;
  text-align: center;
}

.success-message {
  margin-top: 16px;
  padding: 12px;
  background-color: rgba(16, 185, 129, 0.1);
  border-radius: 8px;
  color: var(--success);
  display: flex;
  align-items: center;
  gap: 8px;
}

.success-icon {
  font-size: 18px;
}

.form-footer {
  margin-top: 24px;
  text-align: center;
  font-size: 14px;
  color: var(--gray);
}

.form-footer a {
  color: var(--primary);
  text-decoration: none;
  font-weight: 500;
}

/* Modal */
.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
}

.modal-content {
  background-color: white;
  border-radius: 12px;
  padding: 24px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-content h3 {
  margin-bottom: 16px;
  font-size: 18px;
  color: var(--dark);
}

.modal-body {
  margin-bottom: 20px;
}

.modal-body p {
  margin-bottom: 12px;
  font-size: 14px;
  color: var(--gray);
}

.btn-modal-close {
  width: 100%;
  background-color: var(--gray-light);
  color: var(--dark);
  border: none;
  padding: 12px;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
}

/* Animations */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@media (max-width: 500px) {
  .auth-card {
    border-radius: 0;
    box-shadow: none;
  }
  
  .auth-form {
    padding: 20px 16px;
  }
}
</style>