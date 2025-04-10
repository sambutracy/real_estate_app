<template>
    <div class="add-property">
      <h2>Add New Property</h2>
      <form @submit.prevent="handleSubmit">
        <div class="form-row">
          <input
            type="text"
            v-model="formData.title"
            placeholder="Property Title"
            required
          />
        </div>
        
        <div class="form-row">
          <textarea
            v-model="formData.description"
            placeholder="Description"
            required
          ></textarea>
        </div>
        
        <div class="form-group">
          <input
            type="number"
            v-model="formData.price"
            placeholder="Price"
            required
          />
          
          <input
            type="text"
            v-model="formData.location"
            placeholder="Location"
            required
          />
        </div>
        
        <div class="form-group">
          <input
            type="number"
            v-model="formData.bedrooms"
            placeholder="Bedrooms"
            required
          />
          
          <input
            type="number"
            v-model="formData.bathrooms"
            placeholder="Bathrooms"
            required
          />
          
          <input
            type="number"
            v-model="formData.squareFootage"
            placeholder="Square Footage"
            required
          />
        </div>
        
        <div class="form-row">
          <input
            type="text"
            v-model="formData.imageUrl"
            placeholder="Image URL"
          />
        </div>
        
        <div class="form-group checkbox-group">
          <label>
            <input
              type="checkbox"
              v-model="formData.forSale"
            />
            For Sale
          </label>
          
          <label>
            <input
              type="checkbox"
              v-model="formData.forRent"
            />
            For Rent
          </label>
        </div>
        
        <button type="submit" :disabled="loading">
          {{ loading ? 'Adding...' : 'Add Property' }}
        </button>
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
        const formattedData = {
          ...this.formData,
          price: Number(this.formData.price),
          bedrooms: Number(this.formData.bedrooms),
          bathrooms: Number(this.formData.bathrooms),
          squareFootage: Number(this.formData.squareFootage)
        };
        this.$emit('submit-property', formattedData);
        
        // Reset form after submission
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
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 30px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }
  
  form {
    display: flex;
    flex-direction: column;
    gap: 15px;
  }
  
  .form-row {
    width: 100%;
  }
  
  .form-group {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
  }
  
  input, textarea, button {
    padding: 10px 15px;
    border: 1px solid #ddd;
    border-radius: 4px;
    width: 100%;
  }
  
  textarea {
    min-height: 100px;
    resize: vertical;
  }
  
  button {
    background-color: #1a73e8;
    color: white;
    border: none;
    cursor: pointer;
    font-weight: bold;
    transition: background-color 0.3s;
  }
  
  button:hover:not(:disabled) {
    background-color: #0d62d1;
  }
  
  button:disabled {
    background-color: #a9a9a9;
    cursor: not-allowed;
  }
  
  .checkbox-group {
    display: flex;
    gap: 20px;
  }
  
  .checkbox-group label {
    display: flex;
    align-items: center;
    gap: 5px;
  }
  
  .checkbox-group input {
    width: auto;
  }
  </style>