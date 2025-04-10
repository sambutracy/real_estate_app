<template>
  <div class="property-listings">
    <h2>Property Listings</h2>
    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>Loading properties...</p>
    </div>
    <div v-else-if="properties.length === 0" class="no-properties">
      <p>No properties found. Try adjusting your filters or add a new property.</p>
    </div>
    <div v-else class="property-grid">
      <div v-for="property in properties" :key="property.id" class="property-card">
        <div class="property-image">
          <img :src="property.imageUrl || 'https://via.placeholder.com/400x300?text=No+Image'" :alt="property.title" />
          <div class="property-tags">
            <span v-if="property.forSale" class="tag sale">For Sale</span>
            <span v-if="property.forRent" class="tag rent">For Rent</span>
          </div>
        </div>
        <div class="property-info">
          <h3>{{ property.title }}</h3>
          <p class="location"><i class="icon location-icon"></i>{{ property.location }}</p>
          <p class="price">${{ formatNumber(property.price) }}</p>
          <div class="property-specs">
            <span><i class="icon bed-icon"></i>{{ property.bedrooms }} bd</span>
            <span><i class="icon bath-icon"></i>{{ property.bathrooms }} ba</span>
            <span><i class="icon size-icon"></i>{{ property.squareFootage }} sqft</span>
          </div>
          <p class="description">{{ truncateDescription(property.description) }}</p>
          <button class="view-details">View Details</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'PropertyList',
  props: {
    properties: {
      type: Array,
      required: true
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    formatNumber(num) {
      return num.toLocaleString();
    },
    truncateDescription(text) {
      return text.length > 100 ? text.substring(0, 100) + '...' : text;
    }
  }
}
</script>

<style scoped>
.property-listings {
  margin-bottom: 40px;
}

.property-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 25px;
}

.property-card {
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s, box-shadow 0.3s;
  background-color: white;
}

.property-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
}

.property-image {
  position: relative;
  height: 200px;
}

.property-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.property-tags {
  position: absolute;
  top: 15px;
  left: 15px;
  display: flex;
  gap: 8px;
}

.tag {
  font-size: 0.75rem;
  font-weight: bold;
  padding: 5px 10px;
  border-radius: 4px;
}

.tag.sale {
  background-color: #e3f2fd;
  color: #1565c0;
}

.tag.rent {
  background-color: #e8f5e9;
  color: #2e7d32;
}

.property-info {
  padding: 20px;
}

.property-info h3 {
  font-size: 1.3rem;
  margin-bottom: 10px;
  color: #333;
}

.location {
  color: #666;
  font-size: 0.95rem;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
}

.price {
  font-weight: bold;
  font-size: 1.5rem;
  margin-bottom: 12px;
  color: #1a73e8;
}

.property-specs {
  display: flex;
  gap: 15px;
  margin-bottom: 15px;
  color: #555;
  font-size: 0.9rem;
}

.property-specs span {
  display: flex;
  align-items: center;
}

.description {
  color: #666;
  font-size: 0.9rem;
  line-height: 1.5;
  margin-bottom: 15px;
}

.view-details {
  background-color: #1a73e8;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.view-details:hover {
  background-color: #1557b0;
}

.loading-container {
  text-align: center;
  padding: 40px;
  color: #666;
}

.loading-spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #1a73e8;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 15px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.no-properties {
  text-align: center;
  padding: 40px;
  color: #666;
  background-color: #f8f9fa;
  border-radius: 8px;
}
</style>