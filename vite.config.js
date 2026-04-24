import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { nodePolyfills } from 'vite-plugin-node-polyfills'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [
    vue(),
    nodePolyfills({
      include: ['buffer', 'crypto', 'http', 'https', 'os', 'url', 'stream'],
      exclude: [],
      overrides: {
        buffer: true,
      }
    })
  ],
  optimizeDeps: {
    force: true,
    include: ['buffer', '@walletconnect/web3-provider', '@walletconnect/utils']
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  define: {
    'global': 'globalThis'
  },
  server: {
    host: '0.0.0.0',
    port: 5173,
    open: false
  }
})
