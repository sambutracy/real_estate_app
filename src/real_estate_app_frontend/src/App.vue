<template>
  <div class="app-container">
    <header>
      <h1>ICP Real Estate</h1>
    </header>
    
    <div class="auth-methods">
      <h2>Choose Authentication Method</h2>
      <div class="auth-tabs">
        <button 
          :class="['auth-tab', { active: authMethod === 'nfid' }]" 
          @click="authMethod = 'nfid'"
        >
          NFID
        </button>
        <button 
          :class="['auth-tab', { active: authMethod === 'email' }]" 
          @click="authMethod = 'email'"
        >
          Email & Password
        </button>
      </div>
      
      <div v-if="authMethod === 'nfid'" class="auth-container">
        <AuthButtons 
          @login-success="handleNFIDLoginSuccess" 
          @logout-success="handleNFIDLogoutSuccess" 
        />
      </div>
      
      <div v-else class="auth-container">
        <EmailAuth 
          @login-success="handleEmailLoginSuccess" 
          @logout-success="handleEmailLogoutSuccess" 
        />
      </div>
    </div>
    
    <div v-if="error" class="error-message">{{ error }}</div>
    
    <PropertyFilter 
      :loading="loading" 
      @apply-filters="applyFilters" 
    />
    
    <PropertyList 
      :properties="properties" 
      :loading="loading" 
    />
    
    <PropertyForm 
      v-if="isAuthenticated"
      :loading="formLoading" 
      @submit-property="createProperty" 
    />
    <div v-else class="login-prompt">
      <p>Please login to add property listings.</p>
    </div>
  </div>
</template>

<script>
import { Actor, HttpAgent } from '@dfinity/agent';
import PropertyList from './components/PropertyList.vue';
import PropertyForm from './components/PropertyForm.vue';
import PropertyFilter from './components/PropertyFilter.vue';
import AuthButtons from './components/AuthButtons.vue';
import EmailAuth from './components/EmailAuth.vue';
import AuthService from './services/AuthService';
import EmailAuthService from './services/EmailAuthService';

export default {
  name: 'App',
  components: {
    PropertyList,
    PropertyForm,
    PropertyFilter,
    AuthButtons,
    EmailAuth
  },
  data() {
    return {
      properties: [],
      loading: true,
      formLoading: false,
      error: null,
      isAuthenticated: false,
      authMethod: 'nfid', // Changed default from 'internet-identity' to 'nfid'
      real_estate_app_backend: null
    }
  },
  async mounted() {
    console.log('App mounted');
    
    // Add a timeout to prevent infinite loading
    const timeout = setTimeout(() => {
      if (this.loading) {
        this.loading = false;
        this.error = 'Connection timeout. Please refresh the page.';
        console.error('Connection timeout');
      }
    }, 10000); // 10 second timeout
    
    try {
      // Initialize the backend actor
      const agent = new HttpAgent();
      
      if (process.env.NODE_ENV !== "production") {
        await agent.fetchRootKey().catch(e => {
          console.error("Failed to fetch root key:", e);
        });
      }
      
      // Create the backend actor
      this.real_estate_app_backend = Actor.createActor(
        ({ IDL }) => {
          return IDL.Service({
            'getAllProperties': IDL.Func([], [IDL.Vec(IDL.Record({
              'id': IDL.Nat,
              'owner': IDL.Principal,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Nat,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat,
              'bathrooms': IDL.Nat,
              'squareFootage': IDL.Nat,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool
            }))], ['query']),
            'createProperty': IDL.Func([
              IDL.Text,  // title
              IDL.Text,  // description
              IDL.Nat,   // price
              IDL.Text,  // imageUrl
              IDL.Text,  // location
              IDL.Nat,   // bedrooms
              IDL.Nat,   // bathrooms
              IDL.Nat,   // squareFootage
              IDL.Bool,  // forSale
              IDL.Bool   // forRent
            ], [IDL.Nat], []),
            'getProperty': IDL.Func([IDL.Nat], [IDL.Opt(IDL.Record({
              'id': IDL.Nat,
              'owner': IDL.Principal,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Nat,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat,
              'bathrooms': IDL.Nat,
              'squareFootage': IDL.Nat,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool
            }))], ['query']),
            'filterProperties': IDL.Func([
              IDL.Opt(IDL.Nat),  // minBedrooms
              IDL.Opt(IDL.Nat),  // maxPrice
              IDL.Opt(IDL.Bool), // forSale
              IDL.Opt(IDL.Bool)  // forRent
            ], [IDL.Vec(IDL.Record({
              'id': IDL.Nat,
              'owner': IDL.Principal,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Nat,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat,
              'bathrooms': IDL.Nat,
              'squareFootage': IDL.Nat,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool
            }))], ['query']),
            'searchByLocation': IDL.Func([IDL.Text], [IDL.Vec(IDL.Record({
              'id': IDL.Nat,
              'owner': IDL.Principal,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Nat,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat,
              'bathrooms': IDL.Nat,
              'squareFootage': IDL.Nat,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool
            }))], ['query']),
            'whoami': IDL.Func([IDL.Principal], [IDL.Text], ['query'])
          });
        },
        {
          agent,
          canisterId: 'uzt4z-lp777-77774-qaabq-cai',
        }
      );
      
      // Check if user is already authenticated with either method
      try {
        // Check NFID authentication
        const nfidAuthenticated = await AuthService.initialize();
        
        if (nfidAuthenticated) {
          this.isAuthenticated = true;
          this.authMethod = 'nfid';
          this.fetchProperties();
        } else {
          // Check email authentication
          const emailAuthenticated = await EmailAuthService.checkAuthentication();
          
          if (emailAuthenticated) {
            this.isAuthenticated = true;
            this.authMethod = 'email';
            this.fetchProperties();
          }
        }
      } catch (err) {
        console.error('Authentication error:', err);
      }
    } catch (err) {
      console.error('Initialization error:', err);
      this.error = 'Failed to initialize application';
    } finally {
      clearTimeout(timeout);
      this.loading = false;
    }
  },
  methods: {
    async fetchProperties() {
      if (!this.real_estate_app_backend) {
        this.error = 'Backend connection not established';
        this.loading = false;
        return;
      }
      
      try {
        this.loading = true;
        this.error = null;
        
        const propertyPromise = this.real_estate_app_backend.getAllProperties();
        const result = await propertyPromise;
        this.properties = result;
      } catch (err) {
        console.error('Error fetching properties:', err);
        this.error = 'Failed to load properties';
      } finally {
        this.loading = false;
      }
    },
    
    async createProperty(propertyData) {
      try {
        this.formLoading = true;
        this.error = null;
        
        // Convert all values to appropriate types
        const price = Number(propertyData.price);
        const bedrooms = Number(propertyData.bedrooms);
        const bathrooms = Number(propertyData.bathrooms);
        const squareFootage = Number(propertyData.squareFootage);
        
        console.log('Creating property with values:', {
          title: propertyData.title,
          description: propertyData.description,
          price,
          imageUrl: propertyData.imageUrl,
          location: propertyData.location,
          bedrooms,
          bathrooms,
          squareFootage,
          forSale: propertyData.forSale,
          forRent: propertyData.forRent
        });
        
        const result = await this.real_estate_app_backend.createProperty(
          propertyData.title,
          propertyData.description,
          price,
          propertyData.imageUrl,
          propertyData.location,
          bedrooms,
          bathrooms,
          squareFootage,
          propertyData.forSale,
          propertyData.forRent
        );
        
        await this.fetchProperties();
        return result;
      } catch (err) {
        console.error('Error creating property:', err);
        this.error = 'Failed to create property: ' + err.message;
        throw err;
      } finally {
        this.formLoading = false;
      }
    },
    
    async applyFilters(filters) {
      try {
        this.loading = true;
        this.error = null;
        
        const result = await this.real_estate_app_backend.filterProperties(
          filters.minBedrooms ? [filters.minBedrooms] : [],
          filters.maxPrice ? [filters.maxPrice] : [],
          filters.forSale !== null ? [filters.forSale] : [],
          filters.forRent !== null ? [filters.forRent] : []
        );
        
        this.properties = result;
      } catch (err) {
        console.error('Error applying filters:', err);
        this.error = 'Failed to filter properties';
      } finally {
        this.loading = false;
      }
    },
    
    handleNFIDLoginSuccess() {
      this.isAuthenticated = true;
      this.fetchProperties();
    },
    
    handleNFIDLogoutSuccess() {
      this.isAuthenticated = false;
    },
    
    async handleEmailLoginSuccess() {
      this.isAuthenticated = true;
      
      // Re-create the backend actor with the authenticated identity
      try {
        const agent = new HttpAgent();
        
        if (process.env.NODE_ENV !== "production") {
          await agent.fetchRootKey().catch(e => {
            console.error("Failed to fetch root key:", e);
          });
        }
        
        // Use the correct backend canister ID
        this.real_estate_app_backend = Actor.createActor(
          // Same IDL definition as before
          ({ IDL }) => { /* ... existing IDL code ... */ },
          {
            agent,
            canisterId: 'uzt4z-lp777-77774-qaabq-cai', // Correct ID
          }
        );
      } catch (err) {
        console.error("Failed to update agent for email auth:", err);
      }
      
      this.fetchProperties();
    },
    
    handleEmailLogoutSuccess() {
      this.isAuthenticated = false;
    }
  }
}
</script>

<style>
/* Global styles and variables */
:root {
  --primary: #4f46e5;
  --primary-dark: #4338ca;
  --secondary: #06b6d4;
  --dark: #1e293b;
  --light: #f8fafc;
  --gray: #64748b;
  --gray-light: #e2e8f0;
  --success: #10b981;
  --warning: #f59e0b;
  --danger: #ef4444;
  --border-radius: 8px;
  --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --font: 'Inter', system-ui, -apple-system, sans-serif;
}

/* Reset and base styles */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: var(--font);
  background-color: #f5f7fa;
  color: var(--dark);
  line-height: 1.6;
}

/* Main container */
.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  background-color: white;
  box-shadow: var(--shadow);
  border-radius: var(--border-radius);
  margin-top: 20px;
  margin-bottom: 20px;
}

/* Header styling */
header {
  text-align: center;
  margin-bottom: 40px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--gray-light);
}

header h1 {
  font-size: 2.4rem;
  color: var(--primary);
  font-weight: 700;
}

/* Authentication section */
.auth-methods {
  margin-bottom: 40px;
  text-align: center;
  background-color: var(--light);
  padding: 25px;
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
}

.auth-methods h2 {
  font-size: 1.4rem;
  margin-bottom: 20px;
  color: var(--dark);
}

.auth-tabs {
  display: flex;
  justify-content: center;
  margin-bottom: 25px;
  background-color: white;
  border-radius: 50px;
  padding: 5px;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.auth-tab {
  padding: 12px 25px;
  border: none;
  background-color: transparent;
  cursor: pointer;
  margin: 0 5px;
  border-radius: 50px;
  font-weight: 500;
  transition: all 0.2s ease;
  color: var(--gray);
}

.auth-tab.active {
  background-color: var(--primary);
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(79, 70, 229, 0.2);
}

.auth-tab:hover:not(.active) {
  background-color: var(--gray-light);
  color: var(--dark);
}

.auth-container {
  margin-top: 20px;
}

/* Login prompt */
.login-prompt {
  text-align: center;
  margin: 30px 0;
  padding: 40px 20px;
  background-color: var(--light);
  border-radius: var(--border-radius);
  border: 1px dashed var(--gray-light);
}

.login-prompt p {
  font-size: 1.1rem;
  color: var(--gray);
}

/* Error message */
.error-message {
  color: var(--danger);
  padding: 15px;
  margin: 20px 0;
  background-color: #fee2e2;
  border-radius: var(--border-radius);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.error-message::before {
  content: "⚠️";
  margin-right: 10px;
  font-size: 1.2rem;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .app-container {
    padding: 15px;
    margin-top: 10px;
    margin-bottom: 10px;
  }
  
  .auth-tabs {
    flex-direction: column;
    max-width: 100%;
    border-radius: var(--border-radius);
  }
  
  .auth-tab {
    margin: 5px 0;
    border-radius: var(--border-radius);
  }
}
</style>