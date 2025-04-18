<template>
  <div class="property-form-container">
    <h2>Add New Property</h2>
    <form @submit.prevent="submitProperty" class="property-form">
      <div class="form-group">
        <label for="title">Title</label>
        <input type="text" id="title" v-model="property.title" required />
      </div>
      
      <div class="form-group">
        <label for="description">Description</label>
        <textarea id="description" v-model="property.description" required></textarea>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="price">Price</label>
          <input type="number" id="price" v-model.number="property.price" required />
        </div>
        
        <div class="form-group">
          <label for="location">Location</label>
          <input type="text" id="location" v-model="property.location" required />
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="bedrooms">Bedrooms</label>
          <input type="number" id="bedrooms" v-model.number="property.bedrooms" required />
        </div>
        
        <div class="form-group">
          <label for="bathrooms">Bathrooms</label>
          <input type="number" id="bathrooms" v-model.number="property.bathrooms" required />
        </div>
        
        <div class="form-group">
          <label for="squareFootage">Square Footage</label>
          <input type="number" id="squareFootage" v-model.number="property.squareFootage" required />
        </div>
      </div>
      
      <div class="form-row checkbox-row">
        <div class="form-group checkbox">
          <input type="checkbox" id="forSale" v-model="property.forSale" />
          <label for="forSale">For Sale</label>
        </div>
        
        <div class="form-group checkbox">
          <input type="checkbox" id="forRent" v-model="property.forRent" />
          <label for="forRent">For Rent</label>
        </div>
      </div>
      
      <div class="form-group">
        <label for="imageUrl">Image URL</label>
        <input type="text" id="imageUrl" v-model="property.imageUrl" required />
      </div>
      
      <button type="submit" :disabled="loading" class="submit-button">
        {{ loading ? 'Adding...' : 'Add Property' }}
      </button>
    </form>
  </div>
</template>

<script>
export default {
  name: 'PropertyForm',
  props: {
    loading: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      property: {
        title: '',
        description: '',
        price: 0,
        imageUrl: '',
        location: '',
        bedrooms: 1,
        bathrooms: 1,
        squareFootage: 0,
        forSale: true,
        forRent: false
      }
    }
  },
  methods: {
    submitProperty() {
      this.$emit('submit-property', { ...this.property });
      // Reset form
      this.property = {
        title: '',
        description: '',
        price: 0,
        imageUrl: '',
        location: '',
        bedrooms: 1,
        bathrooms: 1,
        squareFootage: 0,
        forSale: true,
        forRent: false
      };
    }
  }
}
</script>

<style scoped>
.property-form-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 30px;
  background: white;
  border-radius: 10px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

h2 {
  text-align: center;
  margin-bottom: 25px;
  color: #333;
}

.property-form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.form-group {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.form-row {
  display: flex;
  gap: 15px;
}

label {
  margin-bottom: 5px;
  font-weight: 500;
  color: #555;
}

input, textarea {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

textarea {
  min-height: 120px;
  resize: vertical;
}

.checkbox-row {
  margin: 10px 0;
}

.checkbox {
  flex-direction: row;
  align-items: center;
  gap: 10px;
}

.checkbox input {
  margin-right: 8px;
  width: auto;
}

.submit-button {
  margin-top: 20px;
  padding: 12px;
  background-color: #1a73e8;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

.submit-button:hover {
  background-color: #1557b0;
}

.submit-button:disabled {
  background-color: #92b6e5;
  cursor: not-allowed;
}

@media (max-width: 600px) {
  .form-row {
    flex-direction: column;
    gap: 15px;
  }
}
</style>