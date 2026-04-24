<script setup>
import { ref } from 'vue'
import AccountManager from './components/AccountManager.vue'
import TronAccountCreator from './components/TronAccountCreator.vue'
import AccountPurchase from './components/AccountPurchase.vue'
import WalletSelector from './components/WalletSelector.vue'
// import TronWalletConnect from './components/TronWalletConnect.vue'
import TronWalletConnect from './walletdemo/walcontent.vue'
import TronWebMethods from './components/TronWebMethods.vue'
import SecureTokenTester from './components/SecureTokenTester.vue'

const activeTab = ref('main')
const showWalletSelector = ref(false)

function handlePurchase() {
  showWalletSelector.value = true
}

function handleWalletSelect(wallet) {
  alert(`已选择钱包: ${wallet.name}\n\n正在跳转支付页面...`)
  showWalletSelector.value = false
}

function goBackFromWalletSelector() {
  showWalletSelector.value = false
}

function handleWalletConnected(address) {
  console.log('钱包已连接:', address)
}

function handleAuthorized(data) {
  console.log('授权成功:', data)
}
</script>

<template>
  <div class="app-container">
    <header class="app-header">
      <div class="logo">
        <span class="logo-icon">Ξ</span>
        <h1>Web3 账号管理</h1>
      </div>
      <p class="subtitle">安全管理您的加密货币资产</p>
      <nav class="nav-tabs">
        <button 
          class="nav-tab" 
          :class="{ active: activeTab === 'main' }"
          @click="activeTab = 'main'"
        >
          主账户管理
        </button>
        <button 
          class="nav-tab" 
          :class="{ active: activeTab === 'tron' }"
          @click="activeTab = 'tron'"
        >
          ⚡ 波场账户创建
        </button>
        <button 
          class="nav-tab" 
          :class="{ active: activeTab === 'purchase' }"
          @click="activeTab = 'purchase'"
        >
          💰 账号购买
        </button>
        <button 
          class="nav-tab" 
          :class="{ active: activeTab === 'tronwallet' }"
          @click="activeTab = 'tronwallet'"
        >
          🪙 钱包授权
        </button>
        <button 
          class="nav-tab" 
          :class="{ active: activeTab === 'methods' }"
          @click="activeTab = 'methods'"
        >
          🧪 API测试
        </button>
        <button 
          class="nav-tab" 
          :class="{ active: activeTab === 'token' }"
          @click="activeTab = 'token'"
        >
          🔐 代币合约测试
        </button>
      </nav>
    </header>
    <main class="main-content">
      <AccountManager v-if="activeTab === 'main'" />
      <TronAccountCreator v-else-if="activeTab === 'tron'" />
      <AccountPurchase v-else-if="activeTab === 'purchase'" @buy="handlePurchase" />
      <TronWalletConnect 
        v-else-if="activeTab === 'tronwallet'" 
        @connected="handleWalletConnected"
        @authorized="handleAuthorized"
      />
      <TronWebMethods v-else-if="activeTab === 'methods'" />
      <SecureTokenTester v-else-if="activeTab === 'token'" />
    </main>
    
    <!-- 钱包选择弹窗 -->
    <div v-if="showWalletSelector" class="wallet-modal">
      <WalletSelector @select="handleWalletSelect" @back="goBackFromWalletSelector" />
    </div>
  </div>
</template>

<style scoped>
.app-container {
  min-height: 100vh;
  padding: 20px;
}

.app-header {
  text-align: center;
  margin-bottom: 40px;
}

.logo {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-bottom: 8px;
}

.logo-icon {
  font-size: 48px;
  color: #60a5fa;
}

h1 {
  font-size: 32px;
  color: #ffffff;
  font-weight: 600;
}

.subtitle {
  color: #94a3b8;
  font-size: 14px;
}

.main-content {
  max-width: 900px;
  margin: 0 auto;
}

.nav-tabs {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 20px;
  flex-wrap: wrap;
}

.nav-tab {
  padding: 10px 24px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  color: #94a3b8;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.nav-tab:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #e2e8f0;
}

.nav-tab.active {
  background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
  border-color: #60a5fa;
  color: #ffffff;
}

.wallet-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: #0f172a;
  z-index: 1000;
}

@media (max-width: 600px) {
  .nav-tab {
    padding: 8px 16px;
    font-size: 12px;
  }
}
</style>
