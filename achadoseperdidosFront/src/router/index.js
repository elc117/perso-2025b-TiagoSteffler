import { createRouter, createWebHistory } from 'vue-router'
import PostListView from '../views/PostList.vue' 
import CreatePostView from '../views/CreatePost.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/', 
      name: 'home',
      component: PostListView
    },
    {
      path: '/create', 
      name: 'create',
      component: CreatePostView
    }
  ]
})

export default router