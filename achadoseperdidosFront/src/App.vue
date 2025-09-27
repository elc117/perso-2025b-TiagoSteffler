<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <header>
    <div class="header-inner">
      <div class="site-title">Achados e Perdidos</div>
      <nav>
        <RouterLink to="/">Ver Itens</RouterLink>
        <RouterLink to="/create">Cadastrar Novo Item</RouterLink>
      </nav>
    </div>
  </header>

  <main class="app-main">
    <RouterView />
  </main>
</template>


<style scoped>
.app-main { padding: 16px; }

header, main { color: #333; }

header {
  line-height: 1.5;
  border-bottom: 1px solid #e5e7eb;
  background-color: #f2f3f5;
  padding: 12px 16px;
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.site-title {
  font-weight: 700;
  font-size: 1.75rem;
  color: #1f2937;
}

nav {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  font-size: 1.05rem;
}

nav a {
  color: #374151;
  text-decoration: none;
  padding: 8px 12px;
  border-radius: 8px;
  font-weight: 600;
  transition: filter 0.15s ease, transform 0.05s ease, background-color 0.15s ease;
}

nav a:hover {
  background-color: #e5e7eb;
}

nav a:active {
  transform: translateY(1px);
}

.router-link-active,
.router-link-exact-active {
  background-color: #dbeafe;
  color: #1e40af !important;
}
</style>