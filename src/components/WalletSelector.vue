<script setup>
import { ref } from 'vue'

const emit = defineEmits(['select', 'back'])

const wallets = [
  {
    name: 'imToken',
    icon: '💰',
    description: '全球领先的数字资产钱包',
    color: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    deeplink: 'https://token.im/gateway'
  },
  {
    name: 'TokenPocket',
    icon: '🔐',
    description: '多链资产管理钱包',
    color: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
    deeplink: 'https://www.tokenpocket.pro/'
  },
  {
    name: 'Bitget Wallet',
    icon: '💎',
    description: 'Bitget 官方钱包',
    color: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
    deeplink: 'https://www.bitget.com/wallet'
  },
  {
    name: 'TronLink',
    icon: '⚡',
    description: '波场官方钱包',
    color: 'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)',
    deeplink: 'https://www.tronlink.org/'
  }
]

const selectedWallet = ref(null)
const isProcessing = ref(false)

function selectWallet(wallet) {
  selectedWallet.value = wallet
}

function confirmWallet() {
  if (!selectedWallet.value) return
  
  isProcessing.value = true
  
  setTimeout(() => {
    const wallet = selectedWallet.value
    
    if (wallet.name === 'imToken') {
      window.location.href = 'imtoken://'
    } else if (wallet.name === 'TokenPocket') {
      window.location.href = 'tokenpocket://'
    } else if (wallet.name === 'Bitget Wallet') {
      window.location.href = 'bitkeep://'
    } else if (wallet.name === 'TronLink') {
      window.location.href = 'tronlink://'
    }
    
    setTimeout(() => {
      window.open(wallet.deeplink, '_blank')
      isProcessing.value = false
    }, 1000)
    
    emit('select', wallet)
  }, 500)
}

function goBack() {
  emit('back')
}
</script>

<template>
  <div class="wallet-selector">
    <div class="header">
      <button class="back-btn" @click="goBack">
        ← 返回
      </button>
      <h2>选择钱包</h2>
      <p class="subtitle">请选择您使用的钱包进行购买</p>
    </div>
    
    <div class="wallet-grid">
      <div
        v-for="wallet in wallets"
        :key="wallet.name"
        class="wallet-card"
        :class="{ selected: selectedWallet?.name === wallet.name }"
        :style="{ background: wallet.color }"
        @click="selectWallet(wallet)"
      >
        <div class="wallet-icon">{{ wallet.icon }}</div>
        <div class="wallet-info">
          <h3>{{ wallet.name }}</h3>
          <p>{{ wallet.description }}</p>
        </div>
        <div class="check-icon" v-if="selectedWallet?.name === wallet.name">✓</div>
      </div>
    </div>
    
    <div class="footer">
      <button 
        class="confirm-btn" 
        :disabled="!selectedWallet || isProcessing"
        @click="confirmWallet"
      >
        <span v-if="isProcessing" class="loading">⏳ 正在跳转...</span>
        <span v-else>确认选择</span>
      </button>
      <p class="hint-text">点击后将打开对应钱包应用进行授权</p>
    </div>
  </div>
</template>

<style scoped>
.wallet-selector {
  min-height: 100vh;
  padding: 20px;
}

.header {
  text-align: center;
  margin-bottom: 30px;
}

.back-btn {
  position: absolute;
  left: 20px;
  top: 20px;
  padding: 10px 16px;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 10px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.3s ease;
}

.back-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  color: #ffffff;
}

h2 {
  font-size: 28px;
  color: #ffffff;
  margin-bottom: 8px;
}

.subtitle {
  color: #94a3b8;
  font-size: 14px;
}

.wallet-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
  max-width: 400px;
  margin: 0 auto;
}

.wallet-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  border: 2px solid transparent;
}

.wallet-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
}

.wallet-card.selected {
  border-color: #ffffff;
  box-shadow: 0 0 20px rgba(255, 255, 255, 0.3);
}

.wallet-icon {
  width: 50px;
  height: 50px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}

.wallet-info h3 {
  color: #ffffff;
  font-size: 18px;
  margin: 0 0 4px 0;
}

.wallet-info p {
  color: rgba(255, 255, 255, 0.8);
  font-size: 13px;
  margin: 0;
}

.check-icon {
  margin-left: auto;
  width: 28px;
  height: 28px;
  background: rgba(255, 255, 255, 0.9);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #000000;
  font-weight: bold;
}

.footer {
  position: fixed;
  bottom: 20px;
  left: 0;
  right: 0;
  padding: 0 20px;
}

.confirm-btn {
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
  display: block;
  padding: 16px;
  background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
  border: none;
  border-radius: 12px;
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.confirm-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(96, 165, 250, 0.4);
}

.confirm-btn:disabled {
  background: rgba(255, 255, 255, 0.1);
  cursor: not-allowed;
  color: #64748b;
}

.hint-text {
  text-align: center;
  color: #64748b;
  font-size: 12px;
  margin-top: 12px;
}

.loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
</style>