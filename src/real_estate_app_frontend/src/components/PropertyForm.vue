<template>
  <div class="add-property">
    <h2>Add New Property</h2>
    <form @submit.prevent="handleSubmit">
      <div class="form-row">
        <div class="form-group">
          <label for="title">Property Title</label>
          <input
            id="title"
            type="text"
            v-model="formData.title"
            placeholder="Enter property title"
            required
          />
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="description">Description</label>
          <textarea
            id="description"
            v-model="formData.description"
            placeholder="Describe the property..."
            required
          ></textarea>
        </div>
      </div>
      
      <div class="form-row two-columns">
        <div class="form-group">
          <label for="price">Price</label>
          <div class="input-with-icon">
            <span class="input-icon">$</span>
            <input
              id="price"
              type="number"
              min="0"
              step="1"
              v-model.number="formData.price"
              placeholder="Enter price (whole number only)"
              required
            />
          </div>
        </div>
        
        <div class="form-group">
          <label for="location">Location</label>
          <input
            id="location"
            type="text"
            v-model="formData.location"
            placeholder="City, State or Address"
            required
          />
        </div>
      </div>
      
      <div class="form-row three-columns">
        <div class="form-group">
          <label for="bedrooms">Bedrooms</label>
          <input
            id="bedrooms"
            type="number"
            v-model="formData.bedrooms"
            placeholder="Bedrooms"
            min="0"
            required
          />
        </div>
        
        <div class="form-group">
          <label for="bathrooms">Bathrooms</label>
          <input
            id="bathrooms"
            type="number"
            v-model="formData.bathrooms"
            placeholder="Bathrooms"
            min="0"
            step="0.5"
            required
          />
        </div>
        
        <div class="form-group">
          <label for="squareFootage">Square Footage</label>
          <input
            id="squareFootage"
            type="number"
            v-model="formData.squareFootage"
            placeholder="Square Footage"
            min="0"
            required
          />
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="imageUrl">Image URL</label>
          <input
            id="imageUrl"
            type="text"
            v-model="formData.imageUrl"
            placeholder="Enter image URL"
          />
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group checkbox-group">
          <div class="checkbox-item">
            <input
              type="checkbox"
              id="forSale"
              v-model="formData.forSale"
            />
            <label for="forSale">For Sale</label>
          </div>
          
          <div class="checkbox-item">
            <input
              type="checkbox"
              id="forRent"
              v-model="formData.forRent"
            />
            <label for="forRent">For Rent</label>
          </div>
        </div>
      </div>
      
      <div class="form-actions">
        <button type="button" class="cancel-btn" @click="resetForm">Cancel</button>
        <button type="submit" class="submit-btn" :disabled="loading">
          {{ loading ? 'Adding Property...' : 'Add Property' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'PropertyForm',
  data() {
    return {
      formData: {
        title: '',
        description: '',
        price: '',
        imageUrl: '',
        location: '',
        bedrooms: '',
        bathrooms: '',
        squareFootage: '',
        forSale: true,
        forRent: false
      }
    }
  },
  props: {
    loading: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    handleSubmit() {
      // Pre-validate the price field to ensure it's a valid positive integer
      const price = Number(this.formData.price);
      if (isNaN(price) || price < 0 || !Number.isInteger(price)) {
        alert('Price must be a valid whole number');
        return;
      }
      
      // Ensure all numeric values are valid positive integers
      const formattedData = {
        ...this.formData,
        price: Math.floor(Math.max(0, Number(this.formData.price))),
        bedrooms: Math.floor(Math.max(0, Number(this.formData.bedrooms))),
        bathrooms: Math.floor(Math.max(0, Number(this.formData.bathrooms))),
        squareFootage: Math.floor(Math.max(0, Number(this.formData.squareFootage))),
      };
      
      this.$emit('submit-property', formattedData);
    },
    resetForm() {
      this.formData = {
        title: '',
        description: '',
        price: '',
        imageUrl: '',
        location: '',
        bedrooms: '',
        bathrooms: '',
        squareFootage: '',
        forSale: true,
        forRent: false
      };
    }
  }
}
</script>

<style scoped>
.add-property {
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

form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-row {
  display: flex;
  gap: 15px;
  width: 100%;
}

.two-columns .form-group {
  width: 50%;
}

.three-columns .form-group {
  width: 33.333%;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
  width: 100%;
}

label {
  font-weight: 500;
  color: #555;
  font-size: 0.9rem;
}

input, textarea, select {
  padding: 12px 15px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  width: 100%;
}

textarea {
  min-height: 120px;
  resize: vertical;
}

.input-with-icon {
  position: relative;
}

.input-icon {
  position: absolute;
  left: 15px;
  top: 50%;
  transform: translateY(-50%);
  color: #666;
}

.input-with-icon input {
  padding-left: 30px;
}

.checkbox-group {
  display: flex;
  gap: 20px;
  margin-top: 10px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.checkbox-item input {
  width: auto;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 15px;
  margin-top: 10px;
}

.cancel-btn, .submit-btn {
  padding: 12px 20px;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.cancel-btn {
  background-color: transparent;
  border: 1px solid #ddd;
  color: #666;
}

.cancel-btn:hover {
  background-color: #f5f5f5;
}

.submit-btn {
  background-color: #1a73e8;
  color: white;
  border: none;
}

.submit-btn:hover:not(:disabled) {
  background-color: #1557b0;
}

.submit-btn:disabled {
  background-color: #a9a9a9;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .form-row {
    flex-direction: column;
  }
  
  .two-columns .form-group,
  .three-columns .form-group {
    width: 100%;
  }
}
</style>