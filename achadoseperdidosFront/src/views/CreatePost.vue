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
  <div>
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
form { display: flex; flex-direction: column; gap: 10px; max-width: 400px; }
</style>