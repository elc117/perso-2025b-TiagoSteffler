<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const API_URL = 'http://localhost:3000'

const posts = ref([]) 
const error = ref(null)

// --- FUNCOES PARA PESQUISA ---
const filterName = ref('')
const filterDate = ref('')
const filterStatus = ref('')
const filterLocation = ref('')

// Busca todos os posts
async function fetchAllPosts() {
  error.value = null
  try {
    const response = await axios.get(`${API_URL}/home`)
    posts.value = response.data
  } catch (e) {
    error.value = 'Falha ao carregar os posts.'
    console.error(e)
  }
}

// Pesquisa pelos filtros
async function performSearch() {
  error.value = null

  const params = {};
  if (filterName.value) params.name = filterName.value;
  if (filterDate.value) params.date = filterDate.value;
  if (filterStatus.value) params.status = filterStatus.value;
  if (filterLocation.value) params.location = filterLocation.value;

  try {
    const response = await axios.get(`${API_URL}/posts/search`, { params });
    posts.value = response.data;
  } catch (e) {
    error.value = 'Falha ao realizar a busca.';
    posts.value = [];
    console.error(e);
  }
}

function clearFilters() {
  filterName.value = ''
  filterDate.value = ''
  filterStatus.value = ''
  filterLocation.value = ''
  fetchAllPosts() // Volta a exibir todos os posts
}


// --- GERENCIAMENTO DE POSTS ---

async function markAsReturned(postId) {
  try {
    await axios.put(`${API_URL}/posts/${postId}`)
    // Atualiza a lista atual
    const currentFiltersActive = filterName.value || filterDate.value || filterStatus.value || filterLocation.value
    if (currentFiltersActive) {
      performSearch()
    } else {
      fetchAllPosts()
    }
  } catch (e) {
    console.error('Falha ao atualizar o post:', e)
  }
}

async function deletePost(postId) {
  if (confirm('Tem certeza que deseja apagar este post?')) {
    try {
      await axios.delete(`${API_URL}/posts/${postId}`)
      // Atualiza a lista atual
      const currentFiltersActive = filterName.value || filterDate.value || filterStatus.value || filterLocation.value
      if (currentFiltersActive) {
        performSearch()
      } else {
        fetchAllPosts()
      }
    } catch (e) {
      console.error('Falha ao apagar o post:', e)
    }
  }
}

// Carrega todos os posts
onMounted(fetchAllPosts)

</script>

<template>
  <div class="page-container">
    <aside class="filter-sidebar">
      <h2>Filtros</h2>
      <form @submit.prevent="performSearch" class="filter-form">
        <div class="form-group">
          <label for="name">Nome do Item</label>
          <input type="text" id="name" v-model.trim="filterName" placeholder="Ex: Garrafa de água">
        </div>
        <div class="form-group">
          <label for="date">A partir da Data</label>
          <input type="date" id="date" v-model="filterDate">
        </div>
        <div class="form-group">
          <label for="status">Status</label>
          <select id="status" v-model="filterStatus">
            <option value="">Todos</option>
            <option value="Perdido">Perdido</option>
            <option value="Encontrado">Encontrado</option>
            <option value="Devolvido">Devolvido</option>
          </select>
        </div>
        <div class="form-group">
          <label for="location">Localização</label>
          <input type="text" id="location" v-model.trim="filterLocation" placeholder="Ex: Shopping">
        </div>

        <div class="button-group">
          <button type="submit" class="search-btn">Pesquisar</button>
          <button type="button" @click="clearFilters" class="clear-btn">Limpar Filtro</button>
        </div>
      </form>
    </aside>

    <main class="content-area">
      <div v-if="error">{{ error }}</div>
      
      <div v-else-if="posts.length > 0" class="post-list">
        <div v-for="post in posts" :key="post.postId" class="post-card">
          <h3>{{ post.itemName }} - <span :class="post.stat.toLowerCase()">{{ post.stat }}</span></h3>
          <p><strong>Descrição:</strong> {{ post.itemDesc }}</p>
          <p><strong>Local:</strong> {{ post.itemLoc }} | <strong>Data:</strong> {{ post.itemDate }}</p>
          <p><strong>Postado por:</strong> {{ post.posterName }}</p>
          <div class="actions">
            <button @click="markAsReturned(post.postId)" v-if="post.stat !== 'Devolvido'" class="return-btn">Marcar como Devolvido</button>
            <button @click="deletePost(post.postId)" class="delete-btn">Apagar</button>
          </div>
        </div>
      </div>
      <div v-else>
        <p>Nenhum item encontrado para os filtros selecionados.</p>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page-container {
  display: flex;
  gap: 2rem;
  color: #333;
}

.filter-sidebar {
  flex: 0 0 280px;
  padding: 1rem;
  border-right: 1px solid #eee;
  background-color: #fff;
}

.filter-form {
  width: 100%;
}

.filter-form .form-group {
  width: 100%;
  margin-bottom: 1rem;
}

.filter-form label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #444;
}

.filter-form input,
.filter-form select {
  display: block;
  width: 100%;
  box-sizing: border-box;
  padding: 8px 10px;
  border: 1px solid #d1d5db;
  background-color: #fff;
  border-radius: 6px;
  outline: none;
  transition: box-shadow 0.15s ease, border-color 0.15s ease;
}

.filter-form input:focus,
.filter-form select:focus {
  border-color: #60a5fa;
  box-shadow: 0 0 0 3px rgba(96, 165, 250, 0.25);
}

.button-group {
  margin-top: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  width: 100%;
}

.button-group button {
  padding: 10px 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 700;
  transition: transform 0.05s ease, filter 0.15s ease;
  width: 100%;
  display: block;
  box-sizing: border-box;
}

.button-group button:hover {
  filter: brightness(0.95);
}

.button-group button:active {
  transform: translateY(1px);
}

.search-btn {
  background-color: #4caf50;
  color: #fff;
}

.clear-btn {
  background-color: #f44336;
  color: #fff;
}

.content-area {
  flex-grow: 1;
}

.content-area h1 {
  background-color: #f2f3f5;
  color: #1f2937;
  padding: 12px 16px;
  border-radius: 10px;
  border: 1px solid #e5e7eb;
  margin: 0 0 1rem 0;
}

.post-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.post-card {
  background-color: #f7f7f7;
  border: 1px solid #e5e7eb;
  padding: 1rem;
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  transition: transform 0.1s ease, box-shadow 0.2s ease;
}

.post-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 18px rgba(0, 0, 0, 0.08);
}

.actions button {
  margin-right: 8px;
}

.delete-btn {
  background-color: #ff4d4d;
  color: #fff;
  border-radius: 10px;
  border: none;
  line-height: 2;
}

.return-btn {
  background-color: #cfcfcf;
  color: #000;
  border-radius: 10px;
  border: none;
  line-height: 2;
}

.perdido,
.encontrado,
.devolvido {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 0.9rem;
  line-height: 1.4;
}

.perdido {
  background-color: #fee2e2;
  color: #b91c1c;
}

.encontrado {
  background-color: #dcfce7;
  color: #166534;
}

.devolvido {
  background-color: #dbeafe;
  color: #1e40af;
}
</style>