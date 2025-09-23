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
          <input type="text" id="name" v-model.trim="filterName" placeholder="Ex: Garrafa de água...">
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
      <h1>Itens Achados e Perdidos</h1>
      <div v-if="error">{{ error }}</div>
      
      <div v-else-if="posts.length > 0" class="post-list">
        <div v-for="post in posts" :key="post.postId" class="post-card">
          <h3>{{ post.itemName }} - <span :class="post.stat.toLowerCase()">{{ post.stat }}</span></h3>
          <p><strong>Descrição:</strong> {{ post.itemDesc }}</p>
          <p><strong>Local:</strong> {{ post.itemLoc }} | <strong>Data:</strong> {{ post.itemDate }}</p>
          <p><strong>Postado por:</strong> {{ post.posterName }}</p>
          <div class="actions">
            <button @click="markAsReturned(post.postId)" v-if="post.stat !== 'Devolvido'">Marcar como Devolvido</button>
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
}

.filter-sidebar {
  flex: 0 0 280px;
  padding: 1rem;
  border-right: 1px solid #eee;
}

.filter-form .form-group {
  margin-bottom: 1rem;
}

.filter-form label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.filter-form input,
.filter-form select {
  width: 100%;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.button-group {
  margin-top: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.button-group button {
  padding: 10px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}

.search-btn {
  background-color: #4CAF50;
  color: white;
}

.clear-btn {
  background-color: #f44336;
  color: white;
}


.content-area {
  flex-grow: 1;
}

.post-list { display: flex; flex-direction: column; gap: 1rem; }
.post-card { border: 1px solid #ccc; padding: 1rem; border-radius: 8px; }
.actions button { margin-right: 8px; }
.delete-btn { background-color: #ff4d4d; color: white; }
.perdido { color: red; }
.encontrado { color: green; }
.devolvido { color: blue; }
</style>