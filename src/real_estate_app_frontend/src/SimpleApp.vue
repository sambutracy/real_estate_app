<template>
  <div class="app-container">
    <header>
      <h1>ICP Real Estate</h1>
    </header>
    <p>Welcome to ICP Real Estate Application</p>
    <button @click="testConnection">Test Backend Connection</button>
    <p v-if="connectionStatus">{{ connectionStatus }}</p>
  </div>
</template>

<script>
export default {
  name: 'App',
  data() {
    return {
      connectionStatus: null
    }
  },
  methods: {
    async testConnection() {
      this.connectionStatus = "Attempting to connect to backend...";
      try {
        // We'll try to import the backend here
        const backend = await import('../../declarations/real_estate_app_backend/index.js');
        this.connectionStatus = "Successfully imported backend module";
      } catch (err) {
        this.connectionStatus = "Error connecting to backend: " + err.message;
        console.error(err);
      }
    }
  }
}
</script>

<style>
.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  font-family: Arial, sans-serif;
}

header {
  margin-bottom: 30px;
  text-align: center;
}

h1 {
  color: #1a73e8;
}

button {
  background-color: #1a73e8;
  color: white;
  border: none;
  padding: 10px 15px;
  border-radius: 4px;
  cursor: pointer;
  margin: 20px 0;
}

button:hover {
  background-color: #0d62d1;
}
</style>
