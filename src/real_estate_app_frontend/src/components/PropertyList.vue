<template>
    <div class="property-listings">
      <h2>Property Listings</h2>
      <div v-if="loading" class="loading">
        <p>Loading properties...</p>
      </div>
      <div v-else-if="properties.length === 0" class="no-properties">
        <p>No properties found.</p>
      </div>
      <div v-else class="property-grid">
        <div v-for="property in properties" :key="property.id" class="property-card">
          <img :src="property.imageUrl || 'https://via.placeholder.com/300x200'" :alt="property.title" />
          <div class="property-info">
            <h3>{{ property.title }}</h3>
            <p class="location">{{ property.location }}</p>
            <p class="price">${{ formatNumber(property.price) }}</p>
            <p class="specs">
              {{ property.bedrooms }} bd | {{ property.bathrooms }} ba | {{ property.squareFootage }} sqft
            </p>
            <div class="tags">
              <span v-if="property.forSale" class="tag sale">For Sale</span>
              <span v-if="property.forRent" class="tag rent">For Rent</span>
            </div>
            <p class="description">{{ property.description }}</p>
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
      }
    }
  }
  </script>
  
  <style scoped>
  .property-listings {
    margin-bottom: 30px;
  }
  
  .property-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 20px;
  }
  
  .property-card {
    border: 1px solid #ddd;
    border-radius: 8px;
    overflow: hidden;
    transition: transform 0.3s;
  }
  
  .property-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
  }
  
  .property-card img {
    width: 100%;
    height: 200px;
    object-fit: cover;
  }
  
  .property-info {
    padding: 15px;
  }
  
  .property-info h3 {
    margin-bottom: 5px;
    color: #1a73e8;
  }
  
  .location {
    color: #666;
    font-size: 0.9rem;
    margin-bottom: 10px;
  }
  
  .price {
    font-weight: bold;
    font-size: 1.2rem;
    margin-bottom: 5px;
    color: #333;
  }
  
  .specs {
    color: #666;
    margin-bottom: 10px;
    font-size: 0.9rem;
  }
  
  .tags {
    display: flex;
    gap: 10px;
    margin-bottom: 10px;
  }
  
  .tag {
    font-size: 0.8rem;
    padding: 3px 8px;
    border-radius: 4px;
    display: inline-block;
  }
  
  .tag.sale {
    background-color: #e3f2fd;
    color: #1565c0;
  }
  
  .tag.rent {
    background-color: #e8f5e9;
    color: #2e7d32;
  }
  
  .description {
    font-size: 0.9rem;
    color: #666;
    margin-top: 10px;
  }
  
  .loading, .no-properties {
    padding: 30px;
    text-align: center;
    color: #666;
  }
  </style>