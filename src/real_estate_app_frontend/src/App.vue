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
    
    // Add a timeout to prevent infinite loading
    const timeout = setTimeout(() => {
      if (this.loading) {
        this.loading = false;
        this.error = 'Connection timeout. Please refresh the page.';
        console.error('Connection timeout');
      }
    }, 10000); // 10 second timeout
    
    try {
      // Simple approach - directly create the actor with hardcoded values
      const agent = new HttpAgent();
      
      // IMPORTANT: For local development, we need to fetch the root key
      // This is required for signature verification
      if (process.env.NODE_ENV !== "production") {
        await agent.fetchRootKey().catch(e => {
          console.error("Failed to fetch root key:", e);
          // Continue even if this fails
        });
      }
      
      // Create the actor with the properly initialized agent
      this.real_estate_app_backend = Actor.createActor(
        // Use your existing IDL definition...
        ({ IDL }) => {
          // Your IDL interface definition
          return IDL.Service({
            'getAllProperties': IDL.Func([], [IDL.Vec(IDL.Record({
              'id': IDL.Nat,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Nat,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat,
              'bathrooms': IDL.Nat,
              'squareFootage': IDL.Nat,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool,
              'owner': IDL.Principal
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
            'searchByLocation': IDL.Func([IDL.Text], [IDL.Vec(IDL.Record({
              'id': IDL.Nat,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Nat,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat,
              'bathrooms': IDL.Nat,
              'squareFootage': IDL.Nat,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool,
              'owner': IDL.Principal
            }))], ['query']),
            'filterProperties': IDL.Func([
              IDL.Vec(IDL.Nat),  // minBedrooms
              IDL.Vec(IDL.Nat),  // maxPrice
              IDL.Vec(IDL.Bool), // forSale
              IDL.Vec(IDL.Bool)  // forRent
            ], [IDL.Vec(IDL.Record({
              'id': IDL.Nat,
              'title': IDL.Text,
              'description': IDL.Text,
              'price': IDL.Nat,
              'imageUrl': IDL.Text,
              'location': IDL.Text,
              'bedrooms': IDL.Nat,
              'bathrooms': IDL.Nat,
              'squareFootage': IDL.Nat,
              'forSale': IDL.Bool,
              'forRent': IDL.Bool,
              'owner': IDL.Principal
            }))], ['query'])
          });
        },
        {
          agent,
          canisterId: 'be2us-64aaa-aaaaa-qaabq-cai', // Updated with your new canister ID
        }
      );
      
      // Handle authentication in try/catch blocks to prevent hanging
      try {
        const iiAuthenticated = await AuthService.initialize();
        this.isAuthenticated = iiAuthenticated;
        if (iiAuthenticated) {
          this.fetchProperties();
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
    }
  }
}
</script>

<style>
.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

header {
  text-align: center;
  margin-bottom: 30px;
}

.auth-methods {
  margin-bottom: 30px;
  text-align: center;
}

.auth-tabs {
  display: flex;
  justify-content: center;
  margin-bottom: 20px;
}

.auth-tab {
  padding: 10px 20px;
  border: none;
  background-color: #f0f0f0;
  cursor: pointer;
  margin: 0 5px;
}

.auth-tab.active {
  background-color: #007bff;
  color: white;
}

.auth-container {
  margin-top: 20px;
}

.login-prompt {
  text-align: center;
  margin: 20px 0;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 5px;
}

.error-message {
  color: red;
  padding: 10px;
  margin: 10px 0;
  background-color: #ffeeee;
  border: 1px solid #ffcccc;
  border-radius: 5px;
}
</style>