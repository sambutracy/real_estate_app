<template>
  <div class="app-container">
    <header>
      <h1>ICP Real Estate</h1>
    </header>
    
    <div class="auth-methods">
      <h2>Choose Authentication Method</h2>
      <div class="auth-tabs">
        <button 
          :class="['auth-tab', { active: authMethod === 'internet-identity' }]" 
          @click="authMethod = 'internet-identity'"
        >
          Internet Identity
        </button>
        <button 
          :class="['auth-tab', { active: authMethod === 'email' }]" 
          @click="authMethod = 'email'"
        >
          Email & Password
        </button>
      </div>
      
      <div v-if="authMethod === 'internet-identity'" class="auth-container">
        <AuthButtons 
          @login-success="handleIILoginSuccess" 
          @logout-success="handleIILogoutSuccess" 
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
      authMethod: 'internet-identity', // 'internet-identity' or 'email'
      real_estate_app_backend: null
    }
  },
  async mounted() {
    console.log('App mounted');
    
    try {
      // Simple approach - directly create the actor with hardcoded values
      // This is more reliable for initial development
      const agent = new HttpAgent();
      
      // Create the actor directly - this is a simpler approach that's less likely to have path issues
      // You'll need to replace the canisterId with your actual canister ID
      this.real_estate_app_backend = Actor.createActor(
        // Simplified method during development - you can update this later
        ({ IDL }) => {
          return IDL.Service({
            'getAllProperties': IDL.Func([], [IDL.Vec(IDL.Record({
              'id': IDL.Text,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Float64,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat8,
              'bathrooms': IDL.Nat8,
              'squareFootage': IDL.Nat32,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool,
              'owner': IDL.Principal
            }))], ['query']),
            'createProperty': IDL.Func([
              IDL.Text,  // title
              IDL.Text,  // description
              IDL.Float64, // price
              IDL.Text,  // imageUrl
              IDL.Text,  // location
              IDL.Nat8,  // bedrooms
              IDL.Nat8,  // bathrooms
              IDL.Nat32, // squareFootage
              IDL.Bool,  // forSale
              IDL.Bool   // forRent
            ], [IDL.Text], []),
            'searchByLocation': IDL.Func([IDL.Text], [IDL.Vec(IDL.Record({
              'id': IDL.Text,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Float64,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat8,
              'bathrooms': IDL.Nat8,
              'squareFootage': IDL.Nat32,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool,
              'owner': IDL.Principal
            }))], ['query']),
            'filterProperties': IDL.Func([
              IDL.Vec(IDL.Nat8),  // minBedrooms
              IDL.Vec(IDL.Float64), // maxPrice
              IDL.Vec(IDL.Bool),  // forSale
              IDL.Vec(IDL.Bool)   // forRent
            ], [IDL.Vec(IDL.Record({
              'id': IDL.Text,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Float64,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat8,
              'bathrooms': IDL.Nat8,
              'squareFootage': IDL.Nat32,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool,
              'owner': IDL.Principal
            }))], ['query'])
          });
        },
        {
          agent,
          canisterId: 'bkyz2-fmaaa-aaaaa-qaaaq-cai', // Your canister ID from the error message
        }
      );
      
      // Check if user is already authenticated with either method
      const iiAuthenticated = await AuthService.initialize();
      const emailAuthenticated = await EmailAuthService.checkAuthentication();
      
      if (iiAuthenticated) {
        this.isAuthenticated = true;
        this.authMethod = 'internet-identity';
      } else if (emailAuthenticated) {
        this.isAuthenticated = true;
        this.authMethod = 'email';
      }
      
      this.fetchProperties();
    } catch (err) {
      this.error = 'Failed to connect to backend. Please check import paths.';
      console.error(err);
      this.loading = false;
    }
  },
  methods: {
    // Update all methods to use this.real_estate_app_backend
    handleIILoginSuccess() {
      this.isAuthenticated = true;
      this.fetchProperties();
    },
    handleIILogoutSuccess() {
      this.isAuthenticated = false;
    },
    handleEmailLoginSuccess() {
      this.isAuthenticated = true;
      this.fetchProperties();
    },
    handleEmailLogoutSuccess() {
      this.isAuthenticated = false;
    },
    
    async fetchProperties() {
      if (!this.real_estate_app_backend) {
        this.error = 'Backend connection not established';
        return;
      }
      
      try {
        this.loading = true;
        this.error = null;
        const result = await this.real_estate_app_backend.getAllProperties();
        this.properties = result;
        this.loading = false;
      } catch (err) {
        this.error = 'Failed to fetch properties';
        this.loading = false;
        console.error(err);
      }
    },
    
    async createProperty(propertyData) {
      if (!this.real_estate_app_backend) {
        this.error = 'Backend connection not established';
        return;
      }
      
      try {
        this.formLoading = true;
        this.error = null;
        
        // Use the authenticated identity
        if (this.authMethod === 'internet-identity') {
          // For Internet Identity, the Principal is automatically used
          await this.real_estate_app_backend.createProperty(
            propertyData.title,
            propertyData.description,
            propertyData.price,
            propertyData.imageUrl,
            propertyData.location,
            propertyData.bedrooms,
            propertyData.bathrooms,
            propertyData.squareFootage,
            propertyData.forSale,
            propertyData.forRent
          );
        } else {
          // For email auth, we might need to pass the token
          const token = EmailAuthService.getToken();
          if (!token) {
            throw new Error("Authentication token missing");
          }
          
          await this.real_estate_app_backend.createProperty(
            propertyData.title,
            propertyData.description,
            propertyData.price,
            propertyData.imageUrl,
            propertyData.location,
            propertyData.bedrooms,
            propertyData.bathrooms,
            propertyData.squareFootage,
            propertyData.forSale,
            propertyData.forRent
          );
        }
        
        this.formLoading = false;
        // Refresh property list
        this.fetchProperties();
      } catch (err) {
        this.error = 'Failed to create property listing';
        this.formLoading = false;
        console.error(err);
      }
    },
    
    async applyFilters(filters) {
      if (!this.real_estate_app_backend) {
        this.error = 'Backend connection not established';
        return;
      }
      
      try {
        this.loading = true;
        this.error = null;
        
        // If location filter is set, use the search by location function
        if (filters.location) {
          const results = await this.real_estate_app_backend.searchByLocation(filters.location);
          this.properties = results;
          this.loading = false;
          return;
        }
        
        // Otherwise use the filter function
        const minBedrooms = filters.minBedrooms !== null ? [filters.minBedrooms] : [];
        const maxPrice = filters.maxPrice !== null ? [filters.maxPrice] : [];
        const forSale = filters.forSale ? [true] : [];
        const forRent = filters.forRent ? [true] : [];
        
        const results = await this.real_estate_app_backend.filterProperties(
          minBedrooms,
          maxPrice,
          forSale,
          forRent
        );
        
        this.properties = results;
        this.loading = false;
      } catch (err) {
        this.error = 'Failed to filter properties';
        this.loading = false;
        console.error(err);
      }
    }
  }
}
</script>

<style>
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

body {
  background-color: #f5f5f5;
  color: #333;
  line-height: 1.6;
}

.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

header {
  margin-bottom: 30px;
  text-align: center;
}

h1 {
  color: #1a73e8;
  margin-bottom: 10px;
}

.error-message {
  background-color: #ffebee;
  color: #c62828;
  padding: 10px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.auth-methods {
  margin-bottom: 30px;
  background-color: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.auth-tabs {
  display: flex;
  margin-bottom: 20px;
}

.auth-tab {
  flex: 1;
  padding: 10px;
  background: none;
  border: none;
  border-bottom: 2px solid #ddd;
  cursor: pointer;
}

.auth-tab.active {
  border-bottom: 2px solid #1a73e8;
  font-weight: bold;
}

.auth-container {
  padding: 20px;
  background-color: white;
  border-radius: 4px;
}

.login-prompt {
  text-align: center;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  margin-top: 20px;
}
</style>