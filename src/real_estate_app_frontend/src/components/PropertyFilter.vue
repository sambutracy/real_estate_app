<template>
  <section class="filters">
    <h2>Find Your Perfect Property</h2>
    <div class="filter-container">
      <div class="search-box">
        <input 
          type="text" 
          placeholder="Search by location..." 
          v-model="locationFilter"
        />
        <button class="search-button" @click="applyFilters">
          <i class="search-icon"></i>
        </button>
      </div>
      
      <div class="filter-controls">
        <div class="filter-group">
          <label>Bedrooms</label>
          <select v-model="minBedroomsFilter">
            <option value="">Any</option>
            <option value="1">1+</option>
            <option value="2">2+</option>
            <option value="3">3+</option>
            <option value="4">4+</option>
            <option value="5">5+</option>
          </select>
        </div>
        
        <div class="filter-group">
          <label>Max Price</label>
          <select v-model="maxPriceFilter">
            <option value="">Any</option>
            <option value="100000">$100,000</option>
            <option value="250000">$250,000</option>
            <option value="500000">$500,000</option>
            <option value="750000">$750,000</option>
            <option value="1000000">$1,000,000</option>
            <option value="2000000">$2,000,000+</option>
          </select>
        </div>
        
        <div class="filter-group checkbox-group">
          <div class="checkbox-item">
            <input 
              type="checkbox" 
              id="for-sale" 
              v-model="showForSale"
            />
            <label for="for-sale">For Sale</label>
          </div>
          
          <div class="checkbox-item">
            <input 
              type="checkbox" 
              id="for-rent" 
              v-model="showForRent"
            />
            <label for="for-rent">For Rent</label>
          </div>
        </div>
        
        <button 
          class="apply-filters-btn" 
          @click="applyFilters" 
          :disabled="loading"
        >
          {{ loading ? 'Filtering...' : 'Apply Filters' }}
        </button>
      </div>
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
    },
    resetFilters() {
      this.locationFilter = '';
      this.minBedroomsFilter = '';
      this.maxPriceFilter = '';
      this.showForSale = true;
      this.showForRent = true;
      this.applyFilters();
    }
  }
}
</script>

<style scoped>
.filters {
  background: white;
  border-radius: 10px;
  padding: 25px;
  margin-bottom: 30px;
  box-shadow: 0 2px 15px rgba(0, 0, 0, 0.08);
}

h2 {
  margin-bottom: 20px;
  color: #333;
  font-size: 1.5rem;
}

.filter-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.search-box {
  position: relative;
  display: flex;
}

.search-box input {
  flex: 1;
  padding: 12px 15px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
}

.search-button {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: #1a73e8;
  cursor: pointer;
}

.search-icon::before {
  content: "🔍";
}

.filter-controls {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
  align-items: end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filter-group label {
  font-weight: 500;
  color: #555;
  font-size: 0.9rem;
}

.filter-group select {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 6px;
  background-color: white;
}

.checkbox-group {
  display: flex;
  flex-direction: row;
  gap: 15px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 5px;
}

.checkbox-item input {
  margin: 0;
}

.apply-filters-btn {
  padding: 10px 15px;
  background-color: #1a73e8;
  color: white;
  border: none;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.apply-filters-btn:hover:not(:disabled) {
  background-color: #1557b0;
}

.apply-filters-btn:disabled {
  background-color: #a9a9a9;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .filter-controls {
    grid-template-columns: 1fr;
  }
  
  .checkbox-group {
    margin-top: 10px;
  }
}
</style>