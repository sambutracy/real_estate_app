<template>
    <section class="filters">
      <h2>Find Your Perfect Property</h2>
      <div class="filter-controls">
        <input 
          type="text" 
          placeholder="Location" 
          v-model="locationFilter"
        />
        <input 
          type="number" 
          placeholder="Min Bedrooms" 
          v-model="minBedroomsFilter"
        />
        <input 
          type="number" 
          placeholder="Max Price" 
          v-model="maxPriceFilter"
        />
        <label>
          <input 
            type="checkbox" 
            v-model="showForSale"
          />
          For Sale
        </label>
        <label>
          <input 
            type="checkbox" 
            v-model="showForRent"
          />
          For Rent
        </label>
        <button @click="applyFilters" :disabled="loading">
          {{ loading ? 'Filtering...' : 'Apply Filters' }}
        </button>
      </div>
    </section>
  </template>
  
  <script>
  export default {
    name: 'PropertyFilter',
    data() {
      return {
        locationFilter: '',
        minBedroomsFilter: '',
        maxPriceFilter: '',
        showForSale: true,
        showForRent: true
      }
    },
    props: {
      loading: {
        type: Boolean,
        default: false
      }
    },
    methods: {
      applyFilters() {
        const filters = {
          location: this.locationFilter,
          minBedrooms: this.minBedroomsFilter ? Number(this.minBedroomsFilter) : null,
          maxPrice: this.maxPriceFilter ? Number(this.maxPriceFilter) : null,
          forSale: this.showForSale,
          forRent: this.showForRent
        };
        
        this.$emit('apply-filters', filters);
      }
    }
  }
  </script>
  
  <style scoped>
  .filters {
    background: white;
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 30px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }
  
  .filter-controls {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    align-items: center;
  }
  
  .filter-controls input[type="text"],
  .filter-controls input[type="number"] {
    padding: 8px 12px;
    border: 1px solid #ddd;
    border-radius: 4px;
    flex: 1;
    min-width: 120px;
  }
  
  .filter-controls label {
    display: flex;
    align-items: center;
    gap: 5px;
  }
  
  button {
    background-color: #1a73e8;
    color: white;
    border: none;
    cursor: pointer;
    font-weight: bold;
    transition: background-color 0.3s;
    padding: 8px 15px;
    border-radius: 4px;
  }
  
  button:hover:not(:disabled) {
    background-color: #0d62d1;
  }
  
  button:disabled {
    background-color: #a9a9a9;
    cursor: not-allowed;
  }
  </style>