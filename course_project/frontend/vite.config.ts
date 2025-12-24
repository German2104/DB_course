import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const backendTarget = process.env.BACKEND_URL || 'http://localhost:8000'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': backendTarget
    }
  },
  test: {
    environment: 'jsdom',
    setupFiles: './src/setupTests.ts'
  }
})
