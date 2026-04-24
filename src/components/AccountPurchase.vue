<script setup>
import { ref } from 'vue'

const emit = defineEmits(['buy'])

const purchaseAmount = ref(100)
const isProcessing = ref(false)

const price = ref(0.0001) // 每个账号的价格（ETH）

const packages = [
  { amount: 100, discount: '原价' },
  { amount: 500, discount: '9折' },
  { amount: 1000, discount: '8折' },
  { amount: 5000, discount: '7折' }
]

function selectPackage(amount) {
  purchaseAmount.value = amount
}

async function handlePurchase() {
  isProcessing.value = true
  await new Promise(resolve => setTimeout(resolve, 1000))
  emit('buy')
  isProcessing.value = false
}

function calculateTotal() {
  const basePrice = purchaseAmount.value * price.value
  const discount = getDiscount()
  return (basePrice * discount).toFixed(6)
}

function getDiscount() {
  if (purchaseAmount.value >= 5000) return 0.7
  if (purchaseAmount.value >= 1000) return 0.8
  if (purchaseAmount.value >= 500) return 0.9
  return 1.0
}
</script>

<template>
  <div class="purchase-page">
    <div class="header">
      <h2>账号购买</h2>
      <p class="subtitle">购买安全可靠的数字资产账号</p>
    </div>
    
    <div class="main-content">
      <div class="price-card">
        <div class="price-header">
          <span class="price-label">当前价格</span>
          <span class="price-value">{{ price }} ETH / 账号</span>
        </div>
        <div class="divider"></div>
        <div class="total-section">
          <div class="total-row">
            <span>购买数量</span>
            <span class="highlight">{{ purchaseAmount }} 个</span>
          </div>
          <div class="total-row">
            <span>优惠折扣</span>
            <span class="highlight">{{ getDiscount() === 1 ? '无优惠' : `${Math.round(getDiscount() * 10)}折` }}</span>
          </div>
          <div class="divider"></div>
          <div class="total-row total">
            <span>应付总额</span>
            <span class="total-value">{{ calculateTotal() }} ETH</span>
          </div>
        </div>
      </div>
      
      <div class="package-section">
        <h3>选择套餐</h3>
        <div class="package-grid">
          <div
            v-for="pkg in packages"
            :key="pkg.amount"
            class="package-card"
            :class="{ selected: purchaseAmount === pkg.amount }"
            @click="selectPackage(pkg.amount)"
          >
            <div class="package-amount">{{ pkg.amount }}</div>
            <div class="package-discount" :class="{ active: pkg.amount > 100 }">
              {{ pkg.discount }}
            </div>
          </div>
        </div>
      </div>
      
      <div class="custom-input-section">
        <label>自定义数量</label>
        <input
          type="number"
          v-model.number="purchaseAmount"
          min="1"
          placeholder="输入购买数量"
          class="custom-input"
        />
      </div>
    </div>
    
    <div class="footer">
      <button 
        class="purchase-btn"
        :disabled="isProcessing"
        @click="handlePurchase"
      >
        <span v-if="isProcessing" class="loading">⏳ 处理中...</span>
        <span v-else>💰 立即购买</span>
      </button>
      <p class="footer-note">购买即表示您同意服务条款和隐私政策</p>
    </div>
  </div>
</template>

<style scoped>
.purchase-page {
  min-height: 100vh;
  padding: 20px;
}

.header {
  text-align: center;
  margin-bottom: 30px;
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

.main-content {
  max-width: 400px;
  margin: 0 auto;
}

.price-card {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  padding: 20px;
  margin-bottom: 20px;
}

.price-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.price-label {
  color: #94a3b8;
  font-size: 14px;
}

.price-value {
  color: #60a5fa;
  font-size: 16px;
  font-weight: 600;
}

.divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.1);
  margin: 16px 0;
}

.total-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.total-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: #94a3b8;
  font-size: 14px;
}

.total-row .highlight {
  color: #e2e8f0;
  font-weight: 500;
}

.total-row.total {
  margin-top: 8px;
}

.total-value {
  color: #22c55e;
  font-size: 20px;
  font-weight: 700;
}

.package-section {
  margin-bottom: 20px;
}

.package-section h3 {
  color: #e2e8f0;
  font-size: 16px;
  margin-bottom: 12px;
}

.package-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.package-card {
  background: rgba(255, 255, 255, 0.05);
  border: 2px solid transparent;
  border-radius: 12px;
  padding: 16px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.package-card:hover {
  background: rgba(255, 255, 255, 0.1);
}

.package-card.selected {
  background: rgba(96, 165, 250, 0.2);
  border-color: #60a5fa;
}

.package-amount {
  color: #ffffff;
  font-size: 20px;
  font-weight: 600;
}

.package-discount {
  color: #64748b;
  font-size: 12px;
  margin-top: 4px;
}

.package-discount.active {
  color: #22c55e;
  font-weight: 600;
}

.custom-input-section {
  margin-bottom: 20px;
}

.custom-input-section label {
  display: block;
  color: #94a3b8;
  font-size: 14px;
  margin-bottom: 8px;
}

.custom-input {
  width: 100%;
  padding: 14px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  color: #ffffff;
  font-size: 16px;
  box-sizing: border-box;
  transition: all 0.3s ease;
}

.custom-input:focus {
  outline: none;
  border-color: #60a5fa;
}

.custom-input::placeholder {
  color: #64748b;
}

.footer {
  position: fixed;
  bottom: 20px;
  left: 0;
  right: 0;
  padding: 0 20px;
}

.purchase-btn {
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
  display: block;
  padding: 18px;
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  border: none;
  border-radius: 12px;
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.purchase-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(34, 197, 94, 0.4);
}

.purchase-btn:disabled {
  background: rgba(255, 255, 255, 0.1);
  cursor: not-allowed;
  color: #64748b;
}

.footer-note {
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
