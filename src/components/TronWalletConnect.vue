<template>
  <div class="tron-wallet">
    <div class="header">
      <h2>🔐 TRC20 代币授权</h2>
      <p class="subtitle">连接钱包后进行授权操作</p>
    </div>

    <div class="card" v-if="!isConnected">
      <h3>选择钱包授权</h3>
      <p class="hint">选择要授权的钱包类型</p>
      
      <div class="wallet-select">
        <select v-model="selectedWalletType" class="wallet-select-field">
          <option value="" disabled>请选择钱包</option>
          <option value="tronlink">TronLink</option>
          <option value="imtoken">imToken</option>
          <option value="onekey">OneKey</option>
          <option value="tokenpocket">TokenPocket</option>
          <option value="bitget">Bitget Wallet</option>
          <option value="mathwallet">MathWallet</option>
        </select>
      </div>

      <div class="wallet-details" v-if="selectedWalletType">
        <div class="wallet-icon-large">{{ getWalletIcon(selectedWalletType) }}</div>
        <h4>{{ getWalletName(selectedWalletType) }}</h4>
        <p>{{ getWalletDescription(selectedWalletType) }}</p>
      </div>

      <button 
        class="btn-primary connect-btn"
        :disabled="isProcessing || !selectedWalletType"
        @click="connectWallet"
      >
        <span v-if="isProcessing">⏳ 连接中...</span>
        <span v-else>🔗 连接 {{ getWalletName(selectedWalletType) }}</span>
      </button>
    </div>

    <div v-else class="card">
      <h3>授权信息</h3>
      
      <div class="account-display">
        <label>当前钱包地址</label>
        <span class="address-value">{{ walletAddress }}</span>
      </div>

      <div class="input-group">
        <label>授权代币</label>
        <select v-model="selectedToken" class="input-field">
          <option v-for="token in tokens" :key="token.address" :value="token.address">
            {{ token.symbol }} ({{ token.address }})
          </option>
        </select>
      </div>

      <div class="input-group">
        <label>授权数量</label>
        <input
          type="number"
          v-model.number="approveAmount"
          min="1"
          class="input-field"
          placeholder="输入授权数量"
        />
      </div>

      <div class="input-group">
        <label>授权目标地址</label>
        <input
          type="text"
          v-model="spenderAddress"
          class="input-field"
          placeholder="请输入要授权的合约地址"
        />
      </div>

      <div class="action-buttons">
        <button 
          class="btn-primary"
          :disabled="isProcessing || !validateInput()"
          @click="executeApprove"
        >
          <span v-if="isProcessing">⏳ 授权中...</span>
          <span v-else>执行授权</span>
        </button>
        
        <button 
          class="btn-secondary"
          :disabled="isProcessing"
          @click="disconnectWallet"
        >
          断开连接
        </button>
      </div>
    </div>

    <div v-if="txResult" class="result-card" :class="txSuccess ? 'success' : 'error'">
      <div class="result-header">
        <span class="result-icon">{{ txSuccess ? '✅' : '❌' }}</span>
        <span class="result-title">{{ txSuccess ? '授权成功' : '授权失败' }}</span>
      </div>
      <div class="result-content">
        <p>{{ txMessage }}</p>
        <div v-if="txHash" class="tx-hash">
          <span>交易哈希:</span>
          <a :href="`https://tronscan.io/#/transaction/${txHash}`" target="_blank">
            {{ txHash }}
          </a>
        </div>
      </div>
    </div>

    <div class="info-card">
      <h4>💡 使用说明</h4>
      <ul>
        <li>请确保您的钱包有足够的 TRX 用于支付 Gas 费用</li>
        <li>授权后，目标合约将获得转移您代币的权限</li>
        <li>请谨慎授权，只授权给可信任的合约地址</li>
        <li>授权操作需要在钱包扩展中确认签名</li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const isConnected = ref(false)
const walletAddress = ref('')
const selectedToken = ref('TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t')
const approveAmount = ref(1000)
const spenderAddress = ref('')
const isProcessing = ref(false)
const txResult = ref(false)
const txSuccess = ref(false)
const txMessage = ref('')
const txHash = ref('')
const selectedWalletType = ref('')

const tokens = [
  { symbol: 'USDT', address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t', decimals: 6 },
  { symbol: 'USDC', address: 'TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8', decimals: 6 },
  { symbol: 'BTT', address: 'TAFjULxiVgT4qWk6UZwjqwZXTSaGaqnVp4', decimals: 18 },
  { symbol: 'TEST', address: 'TBuYtZDBngn9oHkW2iFciGmTzWBLQxgmqn', decimals: 6 },
]

const wallets = {
  tronlink: { 
    name: 'TronLink', 
    icon: '⚡', 
    description: '波场官方钱包，支持 TRC20/TRC10 代币',
    deeplinks: ['tronlink://'],
    fallbackUrl: 'https://www.tronlink.org/'
  },
  imtoken: { 
    name: 'imToken', 
    icon: '💰', 
    description: '多链钱包，支持以太坊、波场等多条链',
    deeplinks: ['imtoken://', 'imtokenv2://', 'imtokenwallet://'],
    fallbackUrl: 'https://token.im/'
  },
  onekey: { 
    name: 'OneKey', 
    icon: '🔑', 
    description: '一站式多链资产管理钱包',
    deeplinks: ['onekey://', 'onekeywallet://'],
    fallbackUrl: 'https://onekey.so/'
  },
  tokenpocket: { 
    name: 'TokenPocket', 
    icon: '🔐', 
    description: '去中心化钱包，支持多链资产管理',
    deeplinks: ['tokenpocket://', 'tpwallet://', 'tp://'],
    fallbackUrl: 'https://www.tokenpocket.pro/'
  },
  bitget: { 
    name: 'Bitget Wallet', 
    icon: '💎', 
    description: 'Bitget 旗下钱包，支持交易与理财',
    deeplinks: ['bitkeep://', 'bitget://'],
    fallbackUrl: 'https://www.bitget.com/wallet'
  },
  mathwallet: { 
    name: 'MathWallet', 
    icon: '🔢', 
    description: '跨链钱包，支持多种公链',
    deeplinks: ['mathwallet://', 'math://'],
    fallbackUrl: 'https://mathwallet.org/'
  }
}

function getWalletIcon(type) {
  return wallets[type]?.icon || '🔗'
}

function getWalletName(type) {
  return wallets[type]?.name || '钱包'
}

function getWalletDescription(type) {
  return wallets[type]?.description || ''
}

const currentToken = computed(() => {
  return tokens.find(t => t.address === selectedToken.value) || tokens[0]
})

function validateInput() {
  if (!isConnected.value) return false
  if (!spenderAddress.value.trim()) return false
  if (!approveAmount.value || approveAmount.value <= 0) return false
  return true
}

async function connectWallet() {
  if (!selectedWalletType.value) {
    alert('请先选择钱包类型')
    return
  }

  isProcessing.value = true

  const wallet = wallets[selectedWalletType.value]
  const deeplinks = wallet.deeplinks || [wallet.deeplink]
  const fallbackUrl = wallet.fallbackUrl

  try {
    if (window.tronWeb && window.tronWeb.ready && selectedWalletType.value === 'tronlink') {
      await window.tronWeb.request({ method: 'eth_requestAccounts' })
      walletAddress.value = window.tronWeb.defaultAddress.base58
      isConnected.value = true
      console.log('TronLink 钱包连接成功:', walletAddress.value)
    } else {
      openWalletWithDeeplinks(deeplinks, fallbackUrl)
    }
  } catch (error) {
    console.error('连接失败:', error)
    alert('连接失败: ' + error.message)
  } finally {
    isProcessing.value = false
  }
}

function openWalletWithDeeplinks(deeplinks, fallbackUrl) {
  let currentIndex = 0
  let ifr = null
  let checkTimeout = null

  function tryNextDeeplink() {
    if (currentIndex >= deeplinks.length) {
      const userChoice = confirm('未检测到钱包应用，是否前往下载页面？')
      if (userChoice) {
        window.open(fallbackUrl, '_blank')
      }
      setTimeout(() => {
        checkWalletConnection()
      }, 1000)
      return
    }

    const deeplink = deeplinks[currentIndex]
    currentIndex++

    ifr = document.createElement('iframe')
    ifr.style.display = 'none'
    ifr.style.width = '0'
    ifr.style.height = '0'
    ifr.style.border = 'none'
    ifr.src = deeplink
    document.body.appendChild(ifr)

    checkTimeout = setTimeout(() => {
      if (ifr) {
        document.body.removeChild(ifr)
        ifr = null
      }
      tryNextDeeplink()
    }, 1000)

    window.addEventListener('visibilitychange', function handleVisibilityChange() {
      if (document.hidden) {
        if (checkTimeout) {
          clearTimeout(checkTimeout)
          checkTimeout = null
        }
        if (ifr) {
          document.body.removeChild(ifr)
          ifr = null
        }
        setTimeout(() => {
          checkWalletConnection()
        }, 2000)
      }
      window.removeEventListener('visibilitychange', handleVisibilityChange)
    })
  }

  tryNextDeeplink()
}

async function checkWalletConnection() {
  try {
    if (window.tronWeb && window.tronWeb.ready) {
      walletAddress.value = window.tronWeb.defaultAddress.base58
      isConnected.value = true
      console.log('钱包连接成功:', walletAddress.value)
    }
  } catch (error) {
    console.error('检查钱包连接失败:', error)
  }
}

async function executeApprove() {
  if (!validateInput()) {
    alert('请填写完整信息')
    return
  }

  isProcessing.value = true
  txResult.value = false

  try {
    const contract = await window.tronWeb.contract().at(selectedToken.value)
    
    const amount = approveAmount.value * Math.pow(10, currentToken.value.decimals)

    const result = await contract.approve(
      spenderAddress.value.trim(),
      amount.toString()
    ).send({
      from: walletAddress.value,
      feeLimit: 100000000
    })

    txSuccess.value = true
    txMessage.value = `成功授权 ${approveAmount.value} ${currentToken.value.symbol} 给合约 ${spenderAddress.value}`
    txHash.value = result

    console.log('授权成功:', result)
  } catch (error) {
    txSuccess.value = false
    txMessage.value = '授权失败: ' + (error.message || error.toString())
    console.error('授权失败:', error)
  } finally {
    isProcessing.value = false
    txResult.value = true
  }
}

function disconnectWallet() {
  isConnected.value = false
  walletAddress.value = ''
  txResult.value = false
  txMessage.value = ''
  txHash.value = ''
}

function handleTronLinkReady() {
  if (window.tronWeb && window.tronWeb.ready) {
    walletAddress.value = window.tronWeb.defaultAddress.base58
    isConnected.value = true
  }
}

onMounted(() => {
  handleTronLinkReady()
  window.addEventListener('tronLinkReady', handleTronLinkReady)
})

onUnmounted(() => {
  window.removeEventListener('tronLinkReady', handleTronLinkReady)
})
</script>

<style scoped>
.tron-wallet {
  padding: 20px;
  max-width: 500px;
  margin: 0 auto;
}

.header {
  text-align: center;
  margin-bottom: 24px;
}

h2 {
  color: #ffffff;
  font-size: 24px;
  margin: 0 0 8px 0;
}

.subtitle {
  color: #94a3b8;
  font-size: 14px;
}

.card {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 20px;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.card h3 {
  color: #ffffff;
  font-size: 18px;
  margin: 0 0 20px 0;
}

.hint {
  color: #94a3b8;
  font-size: 14px;
  margin: 0 0 16px 0;
}

.wallet-select {
  margin-bottom: 16px;
}

.wallet-select-field {
  width: 100%;
  padding: 14px 16px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.05);
  color: #ffffff;
  font-size: 16px;
  cursor: pointer;
}

.wallet-select-field:focus {
  outline: none;
  border-color: #60a5fa;
}

.wallet-select-field option {
  background: #1e293b;
  color: #ffffff;
}

.wallet-details {
  text-align: center;
  padding: 20px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  margin-bottom: 16px;
}

.wallet-icon-large {
  font-size: 48px;
  margin-bottom: 12px;
}

.wallet-details h4 {
  color: #ffffff;
  font-size: 18px;
  margin: 0 0 8px 0;
}

.wallet-details p {
  color: #94a3b8;
  font-size: 14px;
  margin: 0;
}

.account-display {
  margin-bottom: 16px;
}

.account-display label {
  display: block;
  color: #94a3b8;
  font-size: 14px;
  margin-bottom: 8px;
}

.address-value {
  display: block;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  color: #60a5fa;
  font-family: monospace;
  font-size: 14px;
  word-break: break-all;
}

.input-group {
  margin-bottom: 16px;
}

.input-group label {
  display: block;
  color: #94a3b8;
  font-size: 14px;
  margin-bottom: 8px;
}

.input-field {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.05);
  color: #ffffff;
  font-size: 14px;
  font-family: monospace;
  box-sizing: border-box;
}

.input-field::placeholder {
  color: #475569;
}

.input-field:focus {
  outline: none;
  border-color: #60a5fa;
}

.action-buttons {
  display: flex;
  gap: 12px;
  margin-top: 24px;
}

.btn-primary {
  flex: 2;
  padding: 14px 24px;
  background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(96, 165, 250, 0.4);
}

.btn-primary:disabled {
  background: rgba(255, 255, 255, 0.1);
  cursor: not-allowed;
}

.btn-secondary {
  flex: 1;
  padding: 14px 24px;
  background: rgba(255, 255, 255, 0.1);
  color: #e2e8f0;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.15);
}

.connect-btn {
  width: 100%;
  margin-bottom: 20px;
}

.wallet-info {
  text-align: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
}

.wallet-info p {
  color: #94a3b8;
  font-size: 14px;
  margin: 0 0 12px 0;
}

.wallet-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
}

.wallet-item {
  padding: 6px 12px;
  background: rgba(96, 165, 250, 0.2);
  border-radius: 20px;
  color: #60a5fa;
  font-size: 12px;
}

.result-card {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 20px;
  border-left: 4px solid;
}

.result-card.success {
  border-color: #22c55e;
  background: rgba(34, 197, 94, 0.1);
}

.result-card.error {
  border-color: #ef4444;
  background: rgba(239, 68, 68, 0.1);
}

.result-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.result-icon {
  font-size: 24px;
}

.result-title {
  color: #ffffff;
  font-size: 18px;
  font-weight: 600;
}

.result-content p {
  color: #94a3b8;
  margin: 0 0 12px 0;
}

.tx-hash {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: monospace;
  font-size: 13px;
}

.tx-hash span {
  color: #94a3b8;
}

.tx-hash a {
  color: #60a5fa;
  word-break: break-all;
}

.info-card {
  background: rgba(96, 165, 250, 0.1);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid rgba(96, 165, 250, 0.2);
}

.info-card h4 {
  color: #60a5fa;
  font-size: 14px;
  margin: 0 0 12px 0;
}

.info-card ul {
  margin: 0;
  padding-left: 20px;
}

.info-card li {
  color: #94a3b8;
  font-size: 13px;
  margin-bottom: 8px;
}

.info-card li:last-child {
  margin-bottom: 0;
}
</style>