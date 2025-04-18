<template>
  <div class="property-list">
    <h2 class="section-title">Available Properties</h2>
    
    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>Loading properties...</p>
    </div>
    
    <div v-else-if="!properties || properties.length === 0" class="no-properties">
      <p>No properties found</p>
    </div>
    
    <div v-else class="properties-grid">
      <div v-for="property in properties" :key="property.id" class="property-card">
        <div class="property-image">
          <img :src="property.imageUrl || '/placeholder-property.jpg'" alt="Property Image">
          <div class="property-badges">
            <span v-if="property.forSale" class="badge sale-badge">For Sale</span>
            <span v-if="property.forRent" class="badge rent-badge">For Rent</span>
          </div>
        </div>
        
        <div class="property-content">
          <h3 class="property-title">{{ property.title }}</h3>
          <div class="property-location">
            <i class="location-icon"></i>
            {{ property.location }}
          </div>
          
          <div class="property-price">${{ formatPrice(property.price) }}</div>
          
          <div class="property-specs">
            <span class="spec"><i class="bed-icon"></i> {{ property.bedrooms }} bd</span>
            <span class="spec"><i class="bath-icon"></i> {{ property.bathrooms }} ba</span>
            <span class="spec"><i class="size-icon"></i> {{ property.squareFootage }} sq ft</span>
          </div>
          
          <p class="property-description">{{ truncateDescription(property.description) }}</p>
          
          <button class="view-details">View Details</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    properties: {
      type: Array,
      default: () => []
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    formatPrice(price) {
      return price.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    },
    truncateDescription(description) {
      return description.length > 100 ? description.substring(0, 100) + '...' : description;
    }
  }
}
</script>

<style scoped>
.property-list {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.section-title {
  font-size: 2rem;
  margin-bottom: 30px;
  color: #333;
  font-weight: 600;
  text-align: center;
}

.properties-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 30px;
}

.property-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
  transition: transform 0.3s, box-shadow 0.3s;
}

.property-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
}

.property-image {
  position: relative;
  height: 220px;
  overflow: hidden;
}

.property-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.5s;
}

.property-card:hover .property-image img {
  transform: scale(1.05);
}

.property-badges {
  position: absolute;
  top: 15px;
  right: 15px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.badge {
  padding: 6px 12px;
  border-radius: 30px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: uppercase;
}

.sale-badge {
  background-color: #4caf50;
  color: white;
}

.rent-badge {
  background-color: #2196f3;
  color: white;
}

.property-content {
  padding: 20px;
}

.property-title {
  font-size: 1.3rem;
  font-weight: 600;
  margin-bottom: 10px;
  color: #333;
}

.property-location {
  display: flex;
  align-items: center;
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 15px;
}

.location-icon::before {
  content: "📍";
  margin-right: 6px;
}

.property-price {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1a73e8;
  margin-bottom: 15px;
}

.property-specs {
  display: flex;
  justify-content: space-between;
  margin-bottom: 15px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.spec {
  display: flex;
  align-items: center;
  color: #666;
  font-size: 0.9rem;
}

.bed-icon::before {
  content: "🛏️";
  margin-right: 5px;
}

.bath-icon::before {
  content: "🚿";
  margin-right: 5px;
}

.size-icon::before {
  content: "📏";
  margin-right: 5px;
}

.property-description {
  color: #666;
  font-size: 0.9rem;
  line-height: 1.5;
  margin-bottom: 20px;
  height: 80px;
  overflow: hidden;
}

.view-details {
  width: 100%;
  background-color: #1a73e8;
  color: white;
  border: none;
  padding: 12px;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

.view-details:hover {
  background-color: #1557b0;
}

.loading-container {
  text-align: center;
  padding: 40px;
}

.loading-spinner {
  display: inline-block;
  width: 50px;
  height: 50px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-radius: 50%;
  border-top-color: #1a73e8;
  animation: spin 1s ease-in-out infinite;
  margin-bottom: 15px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.no-properties {
  text-align: center;
  padding: 40px;
  color: #666;
  font-size: 1.1rem;
}
</style>