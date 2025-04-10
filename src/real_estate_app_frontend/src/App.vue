<template>
  <div class="app-container">
    <header>
      <h1>ICP Real Estate</h1>
    </header>
    
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
      :loading="formLoading" 
      @submit-property="createProperty" 
    />
  </div>
</template>

<script>
import { real_estate_app_backend } from '../../../declarations/real_estate_app_backend';
import PropertyList from './components/PropertyList.vue';
import PropertyForm from './components/PropertyForm.vue';
import PropertyFilter from './components/PropertyFilter.vue';

export default {
  name: 'App',
  components: {
    PropertyList,
    PropertyForm,
    PropertyFilter
  },
  data() {
    return {
      properties: [],
      loading: true,
      formLoading: false,
      error: null
    }
  },
  mounted() {
    this.fetchProperties();
  },
  methods: {
    async fetchProperties() {
      try {
        this.loading = true;
        this.error = null;
        const result = await real_estate_app_backend.getAllProperties();
        this.properties = result;
        this.loading = false;
      } catch (err) {
        this.error = 'Failed to fetch properties';
        this.loading = false;
        console.error(err);
      }
    },
    
    async createProperty(propertyData) {
      try {
        this.formLoading = true;
        this.error = null;
        
        await real_estate_app_backend.createProperty(
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
      try {
        this.loading = true;
        this.error = null;
        
        // If location filter is set, use the search by location function
        if (filters.location) {
          const results = await real_estate_app_backend.searchByLocation(filters.location);
          this.properties = results;
          this.loading = false;
          return;
        }
        
        // Otherwise use the filter function
        const minBedrooms = filters.minBedrooms !== null ? [filters.minBedrooms] : [];
        const maxPrice = filters.maxPrice !== null ? [filters.maxPrice] : [];
        const forSale = filters.forSale ? [true] : [];
        const forRent = filters.forRent ? [true] : [];
        
        const results = await real_estate_app_backend.filterProperties(
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
</style>