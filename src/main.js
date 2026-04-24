import { createApp } from 'vue'
import App from './App.vue'
import { Buffer } from 'buffer'
import process from "process";

window.Buffer = Buffer;
window.process = process;
window.global = window;
if (typeof window !== 'undefined') {
  window.Buffer = Buffer
  if (typeof window.global === 'undefined') {
    window.global = window
  }
}

createApp(App).mount('#app')
