<script setup>import { ref, onMounted } from 'vue';
import { ethers } from 'ethers';
const account = ref(null);
const isLoading = ref(false);
const errorMessage = ref('');
const accountsList = ref([]);
const showPrivateKeys = ref(true);
const selectedAccountId = ref(null);
onMounted(() => {
 const saved = localStorage.getItem('tron-accounts');
 if (saved) {
 accountsList.value = JSON.parse(saved);
 }
});
function saveAccounts() {
 localStorage.setItem('tron-accounts', JSON.stringify(accountsList.value));
}
function generatePrivateKey() {
 const array = new Uint8Array(32);
 crypto.getRandomValues(array);
 let privateKey = '';
 for (const byte of array) {
 privateKey += byte.toString(16).padStart(2, '0');
 }
 return privateKey;
}
function hexStringToBytes(hex) {
 const bytes = new Uint8Array(hex.length / 2);
 for (let i = 0; i < bytes.length; i++) {
 bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
 }
 return bytes;
}
function publicKeyToAddress(publicKeyBytes) {
 const sha256Hash = ethers.sha256(ethers.getBytes(publicKeyBytes));
 const sha256Bytes = hexStringToBytes(sha256Hash.slice(2));
 const ripemd160Hash = ripemd160(sha256Bytes);
 const versionBytes = new Uint8Array(21);
 versionBytes[0] = 0x41;
 versionBytes.set(ripemd160Hash, 1);
 const doubleHash = ethers.sha256(ethers.getBytes(versionBytes));
 const checksum = ethers.sha256(ethers.getBytes(hexStringToBytes(doubleHash.slice(2))));
 const checksumBytes = hexStringToBytes(checksum.slice(2)).slice(0, 4);
 const fullBytes = new Uint8Array(25);
 fullBytes.set(versionBytes, 0);
 fullBytes.set(checksumBytes, 21);
 return base58Encode(fullBytes);
}
function ripemd160(data) {
 const K = [
 0x00000000, 0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC,
 0xA953FD4E, 0x50A28BE6, 0x5C4DD124, 0x6D703EF3,
 0x7A6D76E9, 0x00000000, 0x5A827999, 0x6ED9EBA1,
 0x8F1BBCDC, 0xA953FD4E, 0x50A28BE6, 0x5C4DD124,
 0x6D703EF3, 0x7A6D76E9, 0x00000000, 0x5A827999,
 0x6ED9EBA1, 0x8F1BBCDC, 0xA953FD4E, 0x50A28BE6,
 0x5C4DD124, 0x6D703EF3, 0x7A6D76E9, 0x00000000,
 0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xA953FD4E
 ];
 const ROL = (x, n) => ((x << n) | (x >>> (32 - n))) >>> 0;
 const f = [
 (x, y, z) => (x ^ y ^ z),
 (x, y, z) => ((x & y) | (~x & z)),
 (x, y, z) => ((x | ~y) ^ z),
 (x, y, z) => ((x & z) | (y & ~z)),
 (x, y, z) => (x ^ (y | ~z))
 ];
 const r = [
 [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
 [7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8],
 [3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12],
 [1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2],
 [4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13]
 ];
 const s = [
 [11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8],
 [7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12],
 [11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5],
 [11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12],
 [9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6]
 ];
 let h0 = 0x67452301;
 let h1 = 0xEFCDAB89;
 let h2 = 0x98BADCFE;
 let h3 = 0x10325476;
 let h4 = 0xC3D2E1F0;
 const padded = new Uint8Array(((data.length + 8) >>> 6 << 6) + 64);
 padded.set(data);
 padded[data.length] = 0x80;
 const bits = (data.length * 8) >>> 0;
 padded[padded.length - 8] = bits >>> 24;
 padded[padded.length - 7] = bits >>> 16;
 padded[padded.length - 6] = bits >>> 8;
 padded[padded.length - 5] = bits;
 padded[padded.length - 4] = bits >>> 56;
 padded[padded.length - 3] = bits >>> 48;
 padded[padded.length - 2] = bits >>> 40;
 padded[padded.length - 1] = bits >>> 32;
 for (let i = 0; i < padded.length; i += 64) {
 const w = new Uint32Array(16);
 for (let j = 0; j < 16; j++) {
 w[j] = (padded[i + j * 4] << 24) | (padded[i + j * 4 + 1] << 16) |
 (padded[i + j * 4 + 2] << 8) | padded[i + j * 4 + 3];
 }
 let a = h0, b = h1, c = h2, d = h3, e = h4;
 for (let j = 0; j < 80; j++) {
 const t = (((a + f[j >>> 4](b, c, d) + w[r[j >>> 4][j & 15]] + K[j]) >>> 0) + e) >>> 0;
 const newE = d;
 d = c;
 c = ROL(b, s[j >>> 4][j & 15]);
 b = a;
 a = t;
 e = newE;
 }
 h0 = (h0 + a) >>> 0;
 h1 = (h1 + b) >>> 0;
 h2 = (h2 + c) >>> 0;
 h3 = (h3 + d) >>> 0;
 h4 = (h4 + e) >>> 0;
 }
 const result = new Uint8Array(20);
 result[0] = h0 >>> 24;
 result[1] = h0 >>> 16;
 result[2] = h0 >>> 8;
 result[3] = h0;
 result[4] = h1 >>> 24;
 result[5] = h1 >>> 16;
 result[6] = h1 >>> 8;
 result[7] = h1;
 result[8] = h2 >>> 24;
 result[9] = h2 >>> 16;
 result[10] = h2 >>> 8;
 result[11] = h2;
 result[12] = h3 >>> 24;
 result[13] = h3 >>> 16;
 result[14] = h3 >>> 8;
 result[15] = h3;
 result[16] = h4 >>> 24;
 result[17] = h4 >>> 16;
 result[18] = h4 >>> 8;
 result[19] = h4;
 return result;
}
const ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
function base58Encode(bytes) {
 let num = BigInt('0x' + Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join(''));
 let result = '';
 const base = BigInt(58);
 while (num > 0) {
 const remainder = num % base;
 result = ALPHABET[Number(remainder)] + result;
 num = num / base;
 }
 const leadingZeros = Array.from(bytes).filter(b => b === 0).length;
 return '1'.repeat(leadingZeros) + result;
}
async function createTronAccount() {
 try {
 isLoading.value = true;
 errorMessage.value = '';
 const privateKey = generatePrivateKey();
 const keyWithPrefix = privateKey.startsWith('0x') ? privateKey : '0x' + privateKey;
 const signingKey = new ethers.SigningKey(keyWithPrefix);
 const publicKey = signingKey.compressedPublicKey;
 const publicKeyBytes = hexStringToBytes(publicKey.slice(2));
 const address = publicKeyToAddress(publicKeyBytes);
 const newAccount = {
 id: Date.now().toString(),
 address: address,
 privateKey: privateKey,
 publicKey: publicKey,
 createdAt: new Date().toISOString()
 };
 account.value = newAccount;
 accountsList.value.unshift(newAccount);
 saveAccounts();
 }
 catch (error) {
 errorMessage.value = '创建账号失败: ' + error.message;
 console.error(error);
 }
 finally {
 isLoading.value = false;
 }
}
function copyToClipboard(text) {
 navigator.clipboard.writeText(text).then(() => {
 alert('已复制到剪贴板');
 });
}
function exportAccount(acc) {
 const exportAccount = acc || account.value;
 if (!exportAccount)
 return;
 const dataStr = JSON.stringify({
 address: exportAccount.address,
 privateKey: exportAccount.privateKey,
 publicKey: exportAccount.publicKey,
 type: 'tron',
 exportedAt: new Date().toISOString()
 }, null, 2);
 const blob = new Blob([dataStr], { type: 'application/json' });
 const url = URL.createObjectURL(blob);
 const a = document.createElement('a');
 a.href = url;
 a.download = `tron-wallet-${exportAccount.address.slice(0, 8)}.json`;
 document.body.appendChild(a);
 a.click();
 document.body.removeChild(a);
 URL.revokeObjectURL(url);
}
function deleteAccount(id) {
 if (confirm('确定要删除这个账户吗？此操作不可恢复！')) {
 accountsList.value = accountsList.value.filter(acc => acc.id !== id);
 saveAccounts();
 if (selectedAccountId.value === id) {
 selectedAccountId.value = null;
 }
 }
}
function importAccountFromFile(event) {
 const file = event.target.files[0];
 if (!file)
 return;
 const reader = new FileReader();
 reader.onload = (e) => {
 try {
 const data = JSON.parse(e.target.result);
 if (data.type === 'tron' && data.address && data.privateKey) {
 const importedAccount = {
 id: Date.now().toString(),
 address: data.address,
 privateKey: data.privateKey,
 publicKey: data.publicKey || '',
 createdAt: data.exportedAt || new Date().toISOString()
 };
 accountsList.value.unshift(importedAccount);
 saveAccounts();
 account.value = importedAccount;
 alert('账户导入成功！');
 }
 else {
 alert('无效的账户文件格式');
 }
 }
 catch (error) {
 alert('导入失败: ' + error.message);
 }
 };
 reader.readAsText(file);
 event.target.value = '';
}
function exportAllAccounts() {
 if (accountsList.value.length === 0) {
 alert('没有账户可导出');
 return;
 }
 const dataStr = JSON.stringify({
 type: 'tron-wallet-collection',
 accounts: accountsList.value,
 exportedAt: new Date().toISOString()
 }, null, 2);
 const blob = new Blob([dataStr], { type: 'application/json' });
 const url = URL.createObjectURL(blob);
 const a = document.createElement('a');
 a.href = url;
 a.download = `tron-wallets-${Date.now()}.json`;
 document.body.appendChild(a);
 a.click();
 document.body.removeChild(a);
 URL.revokeObjectURL(url);
}
function clearAllAccounts() {
 if (confirm('确定要清空所有账户吗？此操作不可恢复！')) {
 accountsList.value = [];
 saveAccounts();
 account.value = null;
 selectedAccountId.value = null;
 }
}
</script>

<template>
  <div class="tron-creator">
    <div class="card main-card">
      <div class="card-header">
        <h2>波场账户创建</h2>
        <span class="network-badge">TRON</span>
      </div>
      
      <p class="description">点击下方按钮创建新的波场账户</p>
      
      <div class="action-buttons">
        <button class="btn-create" @click="createTronAccount" :disabled="isLoading">
          <span class="btn-icon">⚡</span>
          {{ isLoading ? '创建中...' : '创建波场账户' }}
        </button>
        <label class="btn-import">
          <span class="btn-icon">📥</span>
          导入账户
          <input type="file" accept=".json" @change="importAccountFromFile" class="file-input" />
        </label>
      </div>

      <div v-if="errorMessage" class="error-message">
        {{ errorMessage }}
      </div>

      <div v-if="account" class="account-result">
        <h3>账户信息</h3>
        
        <div class="info-item">
          <label>地址</label>
          <div class="value-row">
            <span class="value">{{ account.address }}</span>
            <button class="copy-btn" @click="copyToClipboard(account.address)">复制</button>
          </div>
        </div>

        <div class="info-item">
          <label>私钥</label>
          <div class="value-row">
            <span class="value private-key">{{ account.privateKey }}</span>
            <button class="copy-btn" @click="copyToClipboard(account.privateKey)">复制</button>
          </div>
        </div>

        <div class="info-item">
          <label>公钥</label>
          <div class="value-row">
            <span class="value public-key">{{ account.publicKey }}</span>
            <button class="copy-btn" @click="copyToClipboard(account.publicKey)">复制</button>
          </div>
        </div>

        <div class="info-item">
          <label>创建时间</label>
          <span class="value">{{ new Date(account.createdAt).toLocaleString() }}</span>
        </div>

        <button class="btn-export" @click="exportAccount">
          导出此账户
        </button>
      </div>
    </div>

    <div class="card accounts-list-card" v-if="accountsList.length > 0">
      <div class="card-header">
        <h3>账户列表</h3>
        <div class="list-actions">
          <button class="action-btn" @click="exportAllAccounts">
            <span>📥</span> 导出全部
          </button>
          <button class="action-btn danger" @click="clearAllAccounts">
            <span>🗑️</span> 清空
          </button>
        </div>
      </div>

      <div class="accounts-grid">
        <div 
          v-for="acc in accountsList" 
          :key="acc.id"
          class="account-card"
          :class="{ selected: selectedAccountId === acc.id }"
          @click="selectedAccountId = acc.id; account = acc"
        >
          <div class="account-header">
            <span class="account-icon">💎</span>
            <div class="account-info">
              <div class="account-address">{{ acc.address }}</div>
              <div class="account-date">{{ new Date(acc.createdAt).toLocaleDateString() }}</div>
            </div>
            <div class="account-actions">
              <button class="mini-btn" @click.stop="copyToClipboard(acc.address)" title="复制地址">
                📋
              </button>
              <button class="mini-btn" @click.stop="exportAccount(acc)" title="导出账户">
                📥
              </button>
              <button class="mini-btn danger" @click.stop="deleteAccount(acc.id)" title="删除账户">
                🗑️
              </button>
            </div>
          </div>
          
          <div class="account-details">
            <div class="detail-row">
              <span class="detail-label">私钥:</span>
              <span class="detail-value private">{{ acc.privateKey }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">公钥:</span>
              <span class="detail-value">{{ acc.publicKey }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="card empty-state" v-else>
      <div class="empty-icon">📭</div>
      <p>暂无账户</p>
      <p class="empty-hint">点击上方按钮创建或导入账户</p>
    </div>
  </div>
</template>

<style scoped>
.tron-creator {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.card {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 20px;
  padding: 24px;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.main-card {
  order: 1;
}

.accounts-list-card {
  order: 2;
}

.empty-state {
  order: 2;
  text-align: center;
  padding: 40px;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.empty-state p {
  color: #94a3b8;
  margin: 8px 0;
}

.empty-hint {
  font-size: 14px;
  color: #64748b;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.card-header h2 {
  color: #ffffff;
  font-size: 24px;
  font-weight: 600;
  margin: 0;
}

.card-header h3 {
  color: #ffffff;
  font-size: 18px;
  font-weight: 600;
  margin: 0;
}

.network-badge {
  background: linear-gradient(135deg, #00BF63 0%, #00D4AA 100%);
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  color: #1a1a2e;
}

.description {
  color: #94a3b8;
  font-size: 14px;
  margin-bottom: 20px;
}

.action-buttons {
  display: flex;
  gap: 12px;
}

.btn-create {
  flex: 1;
  padding: 16px 24px;
  background: linear-gradient(135deg, #00BF63 0%, #00D4AA 100%);
  color: #1a1a2e;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-create:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 191, 99, 0.4);
}

.btn-create:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-import {
  padding: 16px 20px;
  background: rgba(96, 165, 250, 0.2);
  color: #60a5fa;
  border: 1px solid rgba(96, 165, 250, 0.3);
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-import:hover {
  background: rgba(96, 165, 250, 0.3);
}

.file-input {
  display: none;
}

.btn-icon {
  font-size: 18px;
}

.error-message {
  background: rgba(239, 68, 68, 0.15);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 8px;
  padding: 12px 16px;
  color: #f87171;
  font-size: 14px;
  margin-top: 16px;
}

.account-result {
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.account-result h3 {
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 16px;
}

.info-item {
  margin-bottom: 14px;
}

.info-item label {
  display: block;
  color: #94a3b8;
  font-size: 12px;
  margin-bottom: 6px;
}

.value-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.value {
  flex: 1;
  padding: 10px 12px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  color: #ffffff;
  font-family: monospace;
  font-size: 13px;
  word-break: break-all;
}

.value.private-key {
  color: #fbbf24;
}

.value.public-key {
  color: #60a5fa;
}

.copy-btn {
  padding: 6px 12px;
  background: rgba(96, 165, 250, 0.2);
  color: #60a5fa;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  white-space: nowrap;
}

.copy-btn:hover {
  background: rgba(96, 165, 250, 0.3);
}

.btn-export {
  width: 100%;
  padding: 12px 24px;
  background: rgba(255, 255, 255, 0.1);
  color: #e2e8f0;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 16px;
}

.btn-export:hover {
  background: rgba(255, 255, 255, 0.15);
}

.list-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.1);
  color: #e2e8f0;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 4px;
}

.action-btn:hover {
  background: rgba(255, 255, 255, 0.15);
}

.action-btn.danger {
  background: rgba(239, 68, 68, 0.2);
  color: #f87171;
}

.action-btn.danger:hover {
  background: rgba(239, 68, 68, 0.3);
}

.accounts-grid {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.account-card {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid transparent;
}

.account-card:hover {
  background: rgba(255, 255, 255, 0.08);
}

.account-card.selected {
  border-color: #00BF63;
  background: rgba(0, 191, 99, 0.1);
}

.account-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.account-icon {
  font-size: 24px;
}

.account-info {
  flex: 1;
}

.account-address {
  color: #ffffff;
  font-family: monospace;
  font-size: 13px;
  word-break: break-all;
}

.account-date {
  color: #64748b;
  font-size: 12px;
  margin-top: 2px;
}

.account-actions {
  display: flex;
  gap: 6px;
}

.mini-btn {
  padding: 6px;
  background: rgba(255, 255, 255, 0.1);
  color: #94a3b8;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.3s ease;
}

.mini-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  color: #e2e8f0;
}

.mini-btn.danger {
  color: #f87171;
}

.mini-btn.danger:hover {
  background: rgba(239, 68, 68, 0.2);
}

.account-details {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.detail-row {
  display: flex;
  gap: 12px;
  margin-bottom: 8px;
}

.detail-row:last-child {
  margin-bottom: 0;
}

.detail-label {
  color: #94a3b8;
  font-size: 12px;
  min-width: 40px;
}

.detail-value {
  flex: 1;
  color: #e2e8f0;
  font-family: monospace;
  font-size: 12px;
  word-break: break-all;
}

.detail-value.private {
  color: #fbbf24;
}
</style>