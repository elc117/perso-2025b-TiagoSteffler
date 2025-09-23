<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <header>
    <nav>
      <RouterLink to="/">Ver Itens</RouterLink>
      <RouterLink to="/create">Cadastrar Novo Item</RouterLink>
    </nav>
  </header>

  <main>
    <RouterView />
  </main>
</template>

<style scoped>
header {
  line-height: 1.5;
  border-bottom: 1px solid #ccc;
  padding: 1rem;
}

nav {
  display: flex;
  gap: 1rem;
  font-size: 1.2rem;
}
</style>