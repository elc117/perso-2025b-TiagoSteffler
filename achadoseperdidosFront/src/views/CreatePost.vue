<script setup>
import { ref } from 'vue'
import axios from 'axios'

const API_URL = 'http://localhost:3000'

const newItem = ref({
  itemName: '',
  itemDesc: '',
  itemLoc: '',
  itemDate: '',
  posterName: '',
  stat: 'Perdido' // Valor padrao
})

const message = ref('')

async function submitPost() {
  try {
    // newItem.value = JSON esperado
    const response = await axios.post(`${API_URL}/posts`, newItem.value)
    message.value = `Sucesso! ${response.data}`
    
    newItem.value = { itemName: '', itemDesc: '', itemLoc: '', itemDate: '', posterName: '', stat: 'Perdido' };
  } catch (e) {
    message.value = 'Erro ao criar o post.'
    console.error(e)
  }
}
</script>

<template>
  <div class="container">
    <h2>Cadastrar Novo Item</h2>
    <form @submit.prevent="submitPost">
      <input type="text" v-model="newItem.itemName" placeholder="Nome do item" required><br>
      <textarea v-model="newItem.itemDesc" placeholder="Descrição" required></textarea><br>
      <input type="text" v-model="newItem.itemLoc" placeholder="Local" required><br>
      <input type="date" v-model="newItem.itemDate" required><br>
      <input type="text" v-model="newItem.posterName" placeholder="Seu nome" required><br>
      <select v-model="newItem.stat">
        <option value="Perdido">Perdido</option>
        <option value="Encontrado">Encontrado</option>
      </select><br>
      <button type="submit">Criar Post</button>
    </form>
    <p v-if="message">{{ message }}</p>
  </div>
</template>

<style scoped>
.container {
  color: #333;
  max-width: 480px;
  margin: auto;
}

h2 {
  background-color: #f2f3f5;
  color: #1f2937;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid #e5e7eb;
  margin-bottom: 1rem;
}

form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 480px;
  background: #f7f7f7;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

input[type="text"],
input[type="date"],
select,
textarea {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #d1d5db;
  background-color: #fff;
  border-radius: 6px;
  outline: none;
  transition: box-shadow 0.15s ease, border-color 0.15s ease;
}

textarea { min-height: 90px; }

input:focus,
select:focus,
textarea:focus {
  border-color: #60a5fa;
  box-shadow: 0 0 0 3px rgba(96, 165, 250, 0.25);
}

button[type="submit"] {
  padding: 10px 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 700;
  background-color: #4caf50;
  color: #fff;
  transition: transform 0.05s ease, filter 0.15s ease;
}

button[type="submit"]:hover { filter: brightness(0.95); }
button[type="submit"]:active { transform: translateY(1px); }

p {
  margin-top: 0.75rem;
  font-weight: 600;
}
</style>