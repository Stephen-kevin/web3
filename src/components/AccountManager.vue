<script setup>
import { ref, reactive, watch } from 'vue';
import { ethers } from 'ethers';
import { TronWeb } from 'tronweb';

const currentAccount = ref(null);
const privateKey = ref('');
const showPrivateKey = ref(false);
const activeTab = ref('create');
const errorMessage = ref('');

const networks = [
  { name: '以太坊主网', chainId: 1, rpc: 'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', type: 'ethereum' },
  { name: 'Goerli测试网', chainId: 5, rpc: 'https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', type: 'ethereum' },
  { name: 'Sepolia测试网', chainId: 11155111, rpc: 'https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', type: 'ethereum' },
  { name: 'Polygon主网', chainId: 137, rpc: 'https://polygon-rpc.com', type: 'ethereum' },
  { name: '波场主网', chainId: 195, rpc: 'https://api.trongrid.io', type: 'tron' },
  { name: '波场测试网', chainId: 194, rpc: 'https://api.shasta.trongrid.io', type: 'tron' },
];

const selectedNetwork = ref(networks[4]);

const erc20Tokens = [
  { symbol: 'USDT', address: '0xdAC17F958D2ee523a2206206994597C13D831ec7', decimals: 6 },
  { symbol: 'USDC', address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', decimals: 6 },
  { symbol: 'LINK', address: '0x514910771AF9Ca656af840dff83E8264EcF986CA', decimals: 18 },
];

const trc20Tokens = [
  { symbol: 'USDT', address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t', decimals: 6 },
  { symbol: 'USDC', address: 'TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8', decimals: 6 },
  { symbol: 'BTT', address: 'TAFjULxiVgT4qWk6UZwjqwZXTSaGaqnVp4', decimals: 18 },
];

const tokenList = ref(erc20Tokens);
const selectedToken = ref(tokenList.value[0]);
const spenderAddress = ref('');
const approveAmount = ref('');
const allowanceAmount = ref('0.00');
const txHash = ref('');
const isApproving = ref(false);

const balances = reactive({
 native: '0.00',
 tokens: []
});
const isLoading = ref(false);

function generatePrivateKey() {
 const array = new Uint8Array(32);
 crypto.getRandomValues(array);
 let privateKey = '';
 for (const byte of array) {
 privateKey += byte.toString(16).padStart(2, '0');
 }
 return privateKey;
}

function privateKeyToTronAddress(privateKey) {
 const keyWithPrefix = privateKey.startsWith('0x') ? privateKey : '0x' + privateKey;
 const signingKey = new ethers.SigningKey(keyWithPrefix);
 const publicKey = signingKey.compressedPublicKey;
 const publicKeyBytes = hexStringToBytes(publicKey.slice(2));
 return publicKeyToAddress(publicKeyBytes);
}

function hexStringToBytes(hex) {
 const bytes = new Uint8Array(hex.length / 2);
 for (let i = 0; i < bytes.length; i++) {
 bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
 }
 return bytes;
}

async function publicKeyToAddress(publicKeyBytes) {
 const sha256Hash = await crypto.subtle.digest('SHA-256', publicKeyBytes);
 const ripemd160Hash = ripemd160(new Uint8Array(sha256Hash));
 const versionBytes = new Uint8Array(21);
 versionBytes[0] = 0x41;
 versionBytes.set(ripemd160Hash, 1);
 const doubleHash = await crypto.subtle.digest('SHA-256', versionBytes);
 const checksum = await crypto.subtle.digest('SHA-256', new Uint8Array(doubleHash));
 const checksumBytes = new Uint8Array(checksum).slice(0, 4);
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

watch(selectedNetwork, (newNetwork) => {
  tokenList.value = newNetwork.type === 'tron' ? trc20Tokens : erc20Tokens;
  selectedToken.value = tokenList.value[0];
  if (currentAccount.value) {
    fetchBalances();
  }
});

async function createAccount() {
 try {
 isLoading.value = true;
 if (selectedNetwork.value.type === 'tron') {
 const privateKey = generatePrivateKey();
 const address = await privateKeyToTronAddress(privateKey);
 currentAccount.value = {
 address: address,
 privateKey: privateKey,
 mnemonic: null,
 type: 'tron'
 };
 } else {
      const wallet = ethers.Wallet.createRandom();
      currentAccount.value = {
        address: wallet.address,
        privateKey: wallet.privateKey,
        mnemonic: wallet.mnemonic.phrase,
        type: 'ethereum'
      };
    }
    await fetchBalances();
    errorMessage.value = '';
  }
  catch (error) {
    errorMessage.value = '创建账号失败: ' + error.message;
  }
  finally {
    isLoading.value = false;
  }
}

async function importAccount() {
  try {
    isLoading.value = true;
    if (!privateKey.value.trim()) {
      throw new Error('请输入私钥');
    }
    if (selectedNetwork.value.type === 'tron') {
      const { default: TronWeb } = await import('tronweb');
      const tronWeb = new TronWeb({
        fullHost: selectedNetwork.value.rpc
      });
      const address = tronWeb.address.fromPrivateKey(privateKey.value.trim());
      currentAccount.value = {
        address: address,
        privateKey: privateKey.value.trim(),
        mnemonic: null,
        type: 'tron'
      };
    } else {
      const wallet = new ethers.Wallet(privateKey.value.trim());
      currentAccount.value = {
        address: wallet.address,
        privateKey: wallet.privateKey,
        mnemonic: null,
        type: 'ethereum'
      };
    }
    await fetchBalances();
    privateKey.value = '';
    errorMessage.value = '';
  }
  catch (error) {
    errorMessage.value = '导入账号失败: ' + error.message;
  }
  finally {
    isLoading.value = false;
  }
}

function exportAccount() {
  if (!currentAccount.value) return;
  const dataStr = JSON.stringify({
    address: currentAccount.value.address,
    privateKey: currentAccount.value.privateKey,
    mnemonic: currentAccount.value.mnemonic,
    type: currentAccount.value.type,
    exportedAt: new Date().toISOString()
  }, null, 2);
  const blob = new Blob([dataStr], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `wallet-${currentAccount.value.address.slice(0, 8)}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    alert('已复制到剪贴板');
  });
}

async function fetchBalances() {
  if (!currentAccount.value) return;
  try {
    isLoading.value = true;
    if (selectedNetwork.value.type === 'tron') {
      const { default: TronWeb } = await import('tronweb');
      const tronWeb = new TronWeb({
        fullHost: selectedNetwork.value.rpc,
      });
      const balance = await tronWeb.trx.getBalance(currentAccount.value.address);
      balances.native = (balance / 1000000).toFixed(6);
      balances.tokens = await fetchTrc20Balances(tronWeb);
    } else {
      const provider = new ethers.JsonRpcProvider(selectedNetwork.value.rpc);
      const balance = await provider.getBalance(currentAccount.value.address);
      balances.native = ethers.formatEther(balance);
      balances.tokens = await fetchErc20Balances(provider);
    }
  }
  catch (error) {
    console.error('获取余额失败:', error);
    balances.native = '0.00';
    balances.tokens = [];
  }
  finally {
    isLoading.value = false;
  }
}

async function fetchErc20Balances(provider) {
  const results = [];
  for (const token of tokenList.value) {
    try {
      const contract = new ethers.Contract(token.address, [
        'function balanceOf(address) view returns (uint256)',
        'function decimals() view returns (uint8)'
      ], provider);
      const balance = await contract.balanceOf(currentAccount.value.address);
      const decimals = await contract.decimals();
      results.push({
        ...token,
        balance: ethers.formatUnits(balance, decimals)
      });
    }
    catch (error) {
      results.push({
        ...token,
        balance: '0.00'
      });
    }
  }
  return results;
}

async function fetchTrc20Balances(tronWeb) {
  const results = [];
  for (const token of tokenList.value) {
    try {
      const contract = await tronWeb.contract().at(token.address);
      const balance = await contract.balanceOf(currentAccount.value.address).call();
      results.push({
        ...token,
        balance: (balance / Math.pow(10, token.decimals)).toFixed(token.decimals)
      });
    }
    catch (error) {
      results.push({
        ...token,
        balance: '0.00'
      });
    }
  }
  return results;
}

function truncateAddress(address) {
  return address.slice(0, 6) + '...' + address.slice(-4);
}

async function getAllowance() {
  if (!currentAccount.value || !spenderAddress.value.trim()) {
    allowanceAmount.value = '0.00';
    return;
  }
  try {
    isLoading.value = true;
    if (selectedNetwork.value.type === 'tron') {
      const { default: TronWeb } = await import('tronweb');
      const tronWeb = new TronWeb({
        fullHost: selectedNetwork.value.rpc,
      });
      const contract = await tronWeb.contract().at(selectedToken.value.address);
      const allowance = await contract.allowance(currentAccount.value.address, spenderAddress.value.trim()).call();
      allowanceAmount.value = (allowance / Math.pow(10, selectedToken.value.decimals)).toFixed(selectedToken.value.decimals);
    } else {
      const provider = new ethers.JsonRpcProvider(selectedNetwork.value.rpc);
      const contract = new ethers.Contract(selectedToken.value.address, [
        'function allowance(address owner, address spender) view returns (uint256)'
      ], provider);
      const allowance = await contract.allowance(currentAccount.value.address, spenderAddress.value.trim());
      allowanceAmount.value = ethers.formatUnits(allowance, selectedToken.value.decimals);
    }
  }
  catch (error) {
    console.error('查询授权失败:', error);
    allowanceAmount.value = '0.00';
  }
  finally {
    isLoading.value = false;
  }
}

async function approve() {
  if (!currentAccount.value || !spenderAddress.value.trim() || !approveAmount.value.trim()) {
    errorMessage.value = '请填写完整信息';
    return;
  }
  try {
    isApproving.value = true;
    errorMessage.value = '';
    txHash.value = '';
    if (selectedNetwork.value.type === 'tron') {
      const { default: TronWeb } = await import('tronweb');
      const tronWeb = new TronWeb({
        fullHost: selectedNetwork.value.rpc,
        privateKey: currentAccount.value.privateKey
      });
      const contract = await tronWeb.contract().at(selectedToken.value.address);
      const amount = Math.floor(parseFloat(approveAmount.value.trim()) * Math.pow(10, selectedToken.value.decimals));
      const tx = await contract.approve(spenderAddress.value.trim(), amount).send();
      txHash.value = tx.transaction;
      await tronWeb.trx.getTransaction(txHash.value);
    } else {
      const provider = new ethers.JsonRpcProvider(selectedNetwork.value.rpc);
      const wallet = new ethers.Wallet(currentAccount.value.privateKey, provider);
      const contract = new ethers.Contract(selectedToken.value.address, [
        'function approve(address spender, uint256 amount) returns (bool)'
      ], wallet);
      const amount = ethers.parseUnits(approveAmount.value.trim(), selectedToken.value.decimals);
      const tx = await contract.approve(spenderAddress.value.trim(), amount);
      txHash.value = tx.hash;
      await tx.wait();
    }
    await getAllowance();
    approveAmount.value = '';
  }
  catch (error) {
    errorMessage.value = '授权失败: ' + error.message;
  }
  finally {
    isApproving.value = false;
  }
}

async function revokeApproval() {
  if (!currentAccount.value || !spenderAddress.value.trim()) {
    errorMessage.value = '请填写合约地址';
    return;
  }
  try {
    isApproving.value = true;
    errorMessage.value = '';
    txHash.value = '';
    if (selectedNetwork.value.type === 'tron') {
      const { default: TronWeb } = await import('tronweb');
      const tronWeb = new TronWeb({
        fullHost: selectedNetwork.value.rpc,
        privateKey: currentAccount.value.privateKey
      });
      const contract = await tronWeb.contract().at(selectedToken.value.address);
      const tx = await contract.approve(spenderAddress.value.trim(), 0).send();
      txHash.value = tx.transaction;
      await tronWeb.trx.getTransaction(txHash.value);
    } else {
      const provider = new ethers.JsonRpcProvider(selectedNetwork.value.rpc);
      const wallet = new ethers.Wallet(currentAccount.value.privateKey, provider);
      const contract = new ethers.Contract(selectedToken.value.address, [
        'function approve(address spender, uint256 amount) returns (bool)'
      ], wallet);
      const tx = await contract.approve(spenderAddress.value.trim(), 0);
      txHash.value = tx.hash;
      await tx.wait();
    }
    allowanceAmount.value = '0.00';
  }
  catch (error) {
    errorMessage.value = '撤销授权失败: ' + error.message;
  }
  finally {
    isApproving.value = false;
  }
}

function getExplorerUrl(txHash) {
  if (selectedNetwork.value.type === 'tron') {
    return `https://tronscan.io/#/transaction/${txHash}`;
  }
  if (selectedNetwork.value.chainId === 1) {
    return `https://etherscan.io/tx/${txHash}`;
  }
  if (selectedNetwork.value.name === 'Polygon主网') {
    return `https://polygonscan.com/tx/${txHash}`;
  }
  if (selectedNetwork.value.name === 'Goerli测试网') {
    return `https://goerli.etherscan.io/tx/${txHash}`;
  }
  return `https://sepolia.etherscan.io/tx/${txHash}`;
}
</script>

<template>
  <div class="account-manager">
    <div class="tabs">
      <button v-for="tab in [{ key: 'create', label: '创建账号' }, { key: 'import', label: '导入账号' }]" :key="tab.key"
        :class="['tab-btn', { active: activeTab === tab.key }]" @click="activeTab = tab.key">
        {{ tab.label }}
      </button>
    </div>

    <div v-if="errorMessage" class="error-message">
      {{ errorMessage }}
    </div>

    <div v-if="activeTab === 'create'" class="tab-content">
      <div class="card">
        <h3>创建新账号</h3>
        <p class="description">选择网络后点击下方按钮生成新的钱包</p>
        <div class="input-group">
          <label>选择网络</label>
          <select v-model="selectedNetwork" class="input-field">
            <option v-for="network in networks" :key="network.chainId" :value="network">
              {{ network.name }} ({{ network.type === 'tron' ? 'TRC20' : 'ERC20' }})
            </option>
          </select>
        </div>
        <button class="btn-primary" @click="createAccount" :disabled="isLoading">
          {{ isLoading ? '创建中...' : '创建账号' }}
        </button>
      </div>
    </div>

    <div v-if="activeTab === 'import'" class="tab-content">
      <div class="card">
        <h3>导入账号</h3>
        <p class="description">通过私钥导入已有的钱包</p>
        <div class="input-group">
          <label>选择网络</label>
          <select v-model="selectedNetwork" class="input-field">
            <option v-for="network in networks" :key="network.chainId" :value="network">
              {{ network.name }} ({{ network.type === 'tron' ? 'TRC20' : 'ERC20' }})
            </option>
          </select>
        </div>
        <div class="input-group">
          <label>私钥</label>
          <input type="password" v-model="privateKey" placeholder="请输入您的私钥" class="input-field" />
        </div>
        <button class="btn-primary" @click="importAccount" :disabled="isLoading || !privateKey.trim()">
          {{ isLoading ? '导入中...' : '导入账号' }}
        </button>
      </div>
    </div>

    <div v-if="currentAccount" class="account-section">
      <div class="card account-info">
        <div class="card-header">
          <h3>账号信息</h3>
          <button class="btn-secondary" @click="exportAccount">
            导出账号
          </button>
        </div>

        <div class="info-row">
          <span class="label">地址</span>
          <div class="value-group">
            <span class="value">{{ currentAccount.address }}</span>
            <button class="copy-btn" @click="copyToClipboard(currentAccount.address)">复制</button>
          </div>
        </div>

        <div class="info-row">
          <span class="label">私钥</span>
          <div class="value-group">
            <span class="value private-key">{{ showPrivateKey ? currentAccount.privateKey : '************************'
              }}</span>
            <button class="copy-btn" @click="copyToClipboard(currentAccount.privateKey)">复制</button>
          </div>
          <label class="toggle-label">
            <input type="checkbox" v-model="showPrivateKey" />
            <span>显示私钥</span>
          </label>
        </div>

        <div v-if="currentAccount.mnemonic" class="info-row">
          <span class="label">助记词</span>
          <div class="mnemonic-display">
            {{ currentAccount.mnemonic }}
          </div>
        </div>

        <div class="info-row">
          <span class="label">网络类型</span>
          <span class="value">{{ currentAccount.type === 'tron' ? '波场 (TRC20)' : '以太坊 (ERC20)' }}</span>
        </div>
      </div>

      <div class="card balance-info">
        <div class="card-header">
          <h3>余额信息</h3>
          <select v-model="selectedNetwork" @change="fetchBalances" class="network-select">
            <option v-for="network in networks" :key="network.chainId" :value="network">
              {{ network.name }}
            </option>
          </select>
        </div>

        <div class="balance-card">
          <div class="balance-icon">{{ selectedNetwork.type === 'tron' ? 'TRX' : 'Ξ' }}</div>
          <div class="balance-details">
            <span class="balance-label">{{ selectedNetwork.type === 'tron' ? 'TRX 余额' : 'ETH 余额' }}</span>
            <span class="balance-value">{{ balances.native }}</span>
          </div>
        </div>

        <div class="token-list">
          <h4>{{ selectedNetwork.type === 'tron' ? 'TRC20 代币余额' : 'ERC20 代币余额' }}</h4>
          <div v-for="token in balances.tokens" :key="token.symbol" class="token-item">
            <span class="token-symbol">{{ token.symbol }}</span>
            <span class="token-balance">{{ token.balance }}</span>
          </div>
        </div>
      </div>

      <div class="card approval-card">
        <div class="card-header">
          <h3>{{ selectedNetwork.type === 'tron' ? 'TRC20 合约授权' : 'ERC20 合约授权' }}</h3>
        </div>

        <div class="approval-section">
          <div class="input-group">
            <label>选择代币</label>
            <select v-model="selectedToken" class="input-field">
              <option v-for="token in tokenList" :key="token.symbol" :value="token">
                {{ token.symbol }}
              </option>
            </select>
          </div>

          <div class="input-group">
            <label>授权合约地址</label>
            <input type="text" v-model="spenderAddress"
              :placeholder="selectedNetwork.type === 'tron' ? 'TX...' : '0x...'" class="input-field"
              @blur="getAllowance" />
          </div>

          <div class="input-group">
            <label>当前授权额度</label>
            <div class="input-field readonly">
              {{ allowanceAmount }} {{ selectedToken.symbol }}
            </div>
          </div>

          <div class="input-group">
            <label>授权金额</label>
            <input type="number" v-model="approveAmount" placeholder="输入授权金额" class="input-field" step="0.000001" />
          </div>

          <div class="btn-group">
            <button class="btn-primary" @click="approve"
              :disabled="isApproving || !spenderAddress.trim() || !approveAmount.trim()">
              {{ isApproving ? '授权中...' : '授权' }}
            </button>
            <button class="btn-danger" @click="revokeApproval" :disabled="isApproving || !spenderAddress.trim()">
              {{ isApproving ? '撤销中...' : '撤销授权' }}
            </button>
          </div>

          <div v-if="txHash" class="tx-info">
            <span class="tx-label">交易哈希:</span>
            <a :href="getExplorerUrl(txHash)" target="_blank" class="tx-hash">
              {{ truncateAddress(txHash) }}
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.account-manager {
  max-width: 600px;
  margin: 0 auto;
}

.tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 24px;
}

.tab-btn {
  flex: 1;
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: #94a3b8;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tab-btn:hover {
  background: rgba(255, 255, 255, 0.15);
}

.tab-btn.active {
  background: #60a5fa;
  color: white;
}

.card {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 20px;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.card h3 {
  color: #ffffff;
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 16px 0;
}

.card-header h3 {
  margin-bottom: 0;
}

.description {
  color: #94a3b8;
  font-size: 14px;
  margin-bottom: 20px;
}

.input-group {
  margin-bottom: 20px;
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
}

.input-field::placeholder {
  color: #475569;
}

.btn-primary {
  width: 100%;
  padding: 14px 24px;
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(59, 130, 246, 0.3);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary {
  padding: 10px 20px;
  background: rgba(255, 255, 255, 0.1);
  color: #e2e8f0;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.15);
}

.error-message {
  background: rgba(239, 68, 68, 0.15);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 8px;
  padding: 12px 16px;
  color: #f87171;
  font-size: 14px;
  margin-bottom: 20px;
}

.info-row {
  margin-bottom: 16px;
}

.info-row:last-child {
  margin-bottom: 0;
}

.label {
  display: block;
  color: #94a3b8;
  font-size: 13px;
  margin-bottom: 8px;
}

.value-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.value {
  flex: 1;
  padding: 12px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  color: #ffffff;
  font-family: monospace;
  font-size: 14px;
  word-break: break-all;
}

.value.private-key {
  font-family: monospace;
  font-size: 13px;
}

.copy-btn {
  padding: 8px 16px;
  background: rgba(96, 165, 250, 0.2);
  color: #60a5fa;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.copy-btn:hover {
  background: rgba(96, 165, 250, 0.3);
}

.toggle-label {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  color: #94a3b8;
  font-size: 13px;
  cursor: pointer;
}

.toggle-label input {
  cursor: pointer;
}

.mnemonic-display {
  padding: 12px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  color: #fbbf24;
  font-family: monospace;
  font-size: 13px;
  line-height: 1.6;
  word-break: break-all;
}

.network-select {
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  color: #ffffff;
  font-size: 13px;
  cursor: pointer;
}

.balance-card {
  display: flex;
  align-items: center;
  gap: 16px;
  background: linear-gradient(135deg, rgba(96, 165, 250, 0.1) 0%, rgba(59, 130, 246, 0.1) 100%);
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 20px;
}

.balance-icon {
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  color: white;
  font-weight: bold;
}

.balance-details {
  display: flex;
  flex-direction: column;
}

.balance-label {
  color: #94a3b8;
  font-size: 13px;
}

.balance-value {
  color: #ffffff;
  font-size: 28px;
  font-weight: 700;
}

.token-list h4 {
  color: #94a3b8;
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 12px;
}

.token-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  margin-bottom: 8px;
}

.token-item:last-child {
  margin-bottom: 0;
}

.token-symbol {
  color: #e2e8f0;
  font-weight: 500;
}

.token-balance {
  color: #ffffff;
  font-family: monospace;
}

.approval-card {
  margin-top: 20px;
}

.btn-group {
  display: flex;
  gap: 12px;
  margin-top: 20px;
}

.btn-group .btn-primary {
  flex: 2;
}

.btn-danger {
  flex: 1;
  padding: 14px 24px;
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-danger:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(239, 68, 68, 0.3);
}

.btn-danger:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.input-field.readonly {
  pointer-events: none;
  opacity: 0.7;
}

.tx-info {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  padding: 12px;
  background: rgba(34, 197, 94, 0.1);
  border-radius: 8px;
}

.tx-label {
  color: #22c55e;
  font-size: 13px;
}

.tx-hash {
  color: #4ade80;
  font-family: monospace;
  font-size: 13px;
  text-decoration: none;
}

.tx-hash:hover {
  text-decoration: underline;
}
</style>
