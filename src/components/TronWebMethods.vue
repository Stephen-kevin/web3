<template>
  <div class="tronweb-methods">
    <div class="header">
      <h2>TronWeb 方法测试</h2>
      <p class="subtitle">点击按钮调用 TronWeb API，查看输出结果</p>
      
      <div class="connection-status">
        <span :class="isConnected ? 'connected' : 'disconnected'">
          {{ isConnected ? '🟢 已连接' : '🔴 未连接' }}
        </span>
        <span v-if="currentNode" class="node-info">当前节点: {{ currentNode }}</span>
        <button v-if="!isConnected" class="connect-btn" @click="connectWallet">
          连接钱包
        </button>
        <span v-else class="address">{{ currentAddress }}</span>
      </div>
      
      <div class="node-selector">
        <label>选择节点:</label>
        <select v-model="currentNode" @change="switchNode" class="node-select">
          <option v-for="node in nodes" :key="node.url" :value="node.name">
            {{ node.name }}
          </option>
        </select>
        <button class="refresh-btn" @click="refreshConnection">🔄 刷新连接</button>
      </div>
    </div>
    
    <div class="input-section" v-if="methods.some(m => m.requiresInput)">
      <label>输入参数</label>
      <input 
        v-model="inputValue"
        type="text" 
        class="input-field"
        placeholder="根据选择的方法输入参数..."
      />
    </div>
    
    <div class="methods-grid">
      <button
        v-for="method in methods"
        :key="method.name"
        class="method-btn"
        :class="{ disabled: !isConnected && method.requiresInput }"
        @click="handleMethodClick(method)"
      >
        <div class="method-name">{{ method.name }}</div>
        <div class="method-desc">{{ method.description }}</div>
      </button>
    </div>
    
    <div class="output-section">
      <div class="output-header">
        <span>输出结果</span>
        <button class="clear-btn" @click="clearLogs">清空</button>
      </div>
      <div class="output-logs">
        <div
          v-for="(log, index) in outputLogs"
          :key="index"
          class="log-item"
          :class="log.type"
        >
          <span class="log-time">[{{ log.timestamp }}]</span>
          <span class="log-message">{{ log.message }}</span>
        </div>
        <div v-if="outputLogs.length === 0" class="empty-logs">
          点击上方按钮开始测试...
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import TronWeb from 'tronweb'

export default {
  name: 'TronWebMethods',
  data() {
    return {
      tronWeb: null,
      isConnected: false,
      currentAddress: '',
      outputLogs: [],
      inputValue: '',
      currentNode: '',
      nodes: [
        { name: 'TronGrid Mainnet', url: 'https://api.trongrid.io' },
        { name: 'TronGrid Nile Testnet', url: 'https://nile.trongrid.io' },
        { name: 'TronBox', url: 'https://api.tronbox.io' }
      ],
      usdtAddresses: {
        mainnet: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
        nile: 'TQe2Yh9zDUKWdE4cwk34EHvZ2e2SUdsX9e'
      },
      methods: [
        { name: '获取账户余额', method: 'getBalance', description: '查询当前账户的 TRX 余额', requiresInput: false },
        { name: '获取账户信息', method: 'getAccount', description: '查询账户详细信息', requiresInput: false },
        { name: '获取交易记录', method: 'getTransactions', description: '查询最近的交易记录', requiresInput: false },
        { name: '获取区块信息', method: 'getBlock', description: '查询最新区块信息', requiresInput: false },
        { name: '查询 USDT 余额', method: 'getUsdtBalance', description: '查询当前账户的 USDT 余额', requiresInput: false },
        { name: '获取代币余额', method: 'getTokenBalance', description: '查询指定代币余额', requiresInput: true, inputPlaceholder: '代币合约地址' },
        { name: '获取代币信息', method: 'getTokenInfo', description: '查询代币详细信息', requiresInput: true, inputPlaceholder: '代币合约地址' },
        { name: '转账 TRX', method: 'sendTrx', description: '向指定地址转账 TRX', requiresInput: true, inputPlaceholder: '目标地址,金额(TRX)' },
        { name: '调用合约方法', method: 'callContract', description: '调用智能合约方法', requiresInput: true, inputPlaceholder: '合约地址,方法名,参数' },
        { name: '获取网络信息', method: 'getNetwork', description: '查询当前网络信息', requiresInput: false }
      ]
    }
  },
  mounted() {
    this.initTronWeb()
  },
  methods: {
    async initTronWeb() {
      try {
        if (window.tronWeb && window.tronWeb.ready) {
          this.tronWeb = window.tronWeb
          this.currentAddress = window.tronWeb.defaultAddress.base58
          this.isConnected = true
          this.addLog('success', '已连接到 TronLink 钱包')
          return
        }
        await this.tryConnectToNode()
      } catch (error) {
        this.addLog('error', `初始化失败: ${error.message}`)
      }
    },
    async tryConnectToNode() {
      for (const node of this.nodes) {
        try {
          this.tronWeb = new TronWeb({ fullHost: node.url })
          await this.tronWeb.isConnected()
          this.currentNode = node.name
          this.addLog('success', `成功连接到节点: ${node.name}`)
          this.addLog('info', '使用公共节点，部分功能需要连接钱包')
          return
        } catch (error) {
          this.addLog('error', `节点 ${node.name} 连接失败: ${error.message}`)
        }
      }
      throw new Error('所有节点连接失败，请检查网络连接')
    },
    async handleMethodClick(methodInfo) {
      if (!this.tronWeb) {
        this.addLog('error', 'TronWeb 未初始化')
        return
      }
      this.addLog('info', `正在调用: ${methodInfo.name}`)
      try {
        let result
        switch (methodInfo.method) {
          case 'getBalance':
            result = await this.getBalance()
            break
          case 'getAccount':
            result = await this.getAccount()
            break
          case 'getTransactions':
            result = await this.getTransactions()
            break
          case 'getBlock':
            result = await this.getBlock()
            break
          case 'getUsdtBalance':
            result = await this.getUsdtBalance()
            break
          case 'getTokenBalance':
            result = await this.getTokenBalance(this.inputValue)
            break
          case 'getTokenInfo':
            result = await this.getTokenInfo(this.inputValue)
            break
          case 'sendTrx':
            result = await this.sendTrx(this.inputValue)
            break
          case 'callContract':
            result = await this.callContract(this.inputValue)
            break
          case 'getNetwork':
            result = await this.getNetwork()
            break
          default:
            result = '未知方法'
        }
        this.addLog('success', `成功: ${this.formatResult(result)}`)
      } catch (error) {
        this.addLog('error', `失败: ${error.message}`)
      }
    },
    async getBalance() {
      if (!this.isConnected || !this.currentAddress) {
        throw new Error('请先连接钱包')
      }
      this.addLog('info', `查询余额: ${this.currentAddress}`)
      try {
        const balance = await this.tronWeb.trx.getBalance(this.currentAddress)
        if (balance === null || balance === undefined) {
          return '0 TRX (账户可能不存在)'
        }
        return `${(balance / 1000000).toFixed(6)} TRX`
      } catch (error) {
        this.addLog('error', `余额查询失败: ${error.message}`)
        throw error
      }
    },
    async getAccount() {
      if (!this.isConnected || !this.currentAddress) {
        throw new Error('请先连接钱包')
      }
      this.addLog('info', `查询账户: ${this.currentAddress}`)
      try {
        const [account, resources, balance] = await Promise.all([
          this.tronWeb.trx.getAccount(this.currentAddress).catch(() => null),
          this.tronWeb.trx.getAccountResources(this.currentAddress).catch(() => null),
          this.tronWeb.trx.getBalance(this.currentAddress).catch(() => 0)
        ])
        
        if (!account || Object.keys(account).length === 0) {
          if (!this.isValidAddress(this.currentAddress)) {
            throw new Error(`无效的地址格式: ${this.currentAddress}`)
          }
          return JSON.stringify({
            status: 'empty',
            message: '该账户在当前网络上不存在或没有任何交易记录',
            address: this.currentAddress,
            balance: `${(balance / 1000000).toFixed(6)} TRX`
          }, null, 2)
        }
        
        const accountData = {
          address: account.address || account.addressHex || this.currentAddress,
          balance: `${(balance / 1000000).toFixed(6)} TRX`,
          balanceRaw: balance
        }
        
        if (resources) {
          accountData.bandwidth = resources.bandwidth || resources.freeNetUsed || 0
          accountData.energy = resources.energy || resources.usedEnergy || 0
        }
        
        if (account.type) {
          accountData.accountType = account.type === 0 ? '普通账户' : '合约账户'
        }
        
        if (account.ownerCount !== undefined) {
          accountData.ownerCount = account.ownerCount
        }
        
        if (account.contractType !== undefined) {
          accountData.isContract = true
        }
        
        return JSON.stringify(accountData, null, 2)
      } catch (error) {
        this.addLog('error', `API 调用错误: ${error.message}`)
        throw error
      }
    },
    isValidAddress(address) {
      if (!address || typeof address !== 'string') {
        return false
      }
      const base58Regex = /^[1-9A-HJ-NP-Za-km-z]{34}$/
      const hexRegex = /^0x[0-9a-fA-F]{40}$/
      return base58Regex.test(address) || hexRegex.test(address)
    },
    async getTransactions() {
      if (!this.isConnected || !this.currentAddress) {
        throw new Error('请先连接钱包')
      }
      this.addLog('info', `查询交易记录: ${this.currentAddress}`)
      try {
        const transactions = await this.tronWeb.trx.getTransactions(this.currentAddress, 5)
        if (!transactions || transactions.length === 0) {
          return JSON.stringify({
            status: 'empty',
            message: '该账户暂无交易记录',
            address: this.currentAddress
          }, null, 2)
        }
        const simplified = transactions.map(tx => ({
          txID: tx.txID,
          type: tx.contractType || tx.type,
          timestamp: tx.timestamp,
          blockNumber: tx.blockNumber
        }))
        return JSON.stringify(simplified, null, 2)
      } catch (error) {
        this.addLog('error', `交易记录查询失败: ${error.message}`)
        throw error
      }
    },
    async getBlock() {
      const block = await this.tronWeb.trx.getBlock('latest')
      return JSON.stringify({
        blockNumber: block.number,
        timestamp: block.timestamp,
        transactions: block.transactions ? block.transactions.length : 0
      }, null, 2)
    },
    async getUsdtBalance() {
      if (!this.isConnected || !this.currentAddress) {
        throw new Error('请先连接钱包')
      }
      try {
        const isMainnet = await this.detectNetwork()
        const usdtAddress = isMainnet ? this.usdtAddresses.mainnet : this.usdtAddresses.nile
        this.addLog('info', `查询 USDT 余额: ${this.currentAddress}`)
        this.addLog('info', `USDT 合约地址: ${usdtAddress} (${isMainnet ? '主网' : '测试网'})`)
        const contract = await this.tronWeb.contract().at(usdtAddress)
        const balance = await contract.balanceOf(this.currentAddress).call()
        if (!balance || balance.eq(0)) {
          return '0 USDT'
        }
        const decimals = await contract.decimals().call()
        const formattedBalance = (balance.toNumber() / Math.pow(10, decimals)).toFixed(decimals)
        return `${formattedBalance} USDT`
      } catch (error) {
        this.addLog('error', `USDT 查询失败: ${error.message}`)
        throw new Error(`USDT 查询失败: ${error.message}`)
      }
    },
    async detectNetwork() {
      try {
        if (this.tronWeb.trx.getNetwork) {
          const network = await this.tronWeb.trx.getNetwork()
          return network === 'mainnet'
        } else if (this.tronWeb.currentProvider && this.tronWeb.currentProvider.host) {
          const host = this.tronWeb.currentProvider.host
          return host.includes('api.trongrid.io') && !host.includes('nile')
        } else {
          return true
        }
      } catch (e) {
        return true
      }
    },
    async getTokenBalance(contractAddress) {
      if (!contractAddress) {
        throw new Error('请输入代币合约地址')
      }
      if (!this.isConnected || !this.currentAddress) {
        throw new Error('请先连接钱包')
      }
      try {
        this.addLog('info', `查询代币余额: ${contractAddress}`)
        const contract = await this.tronWeb.contract().at(contractAddress)
        const balance = await contract.balanceOf(this.currentAddress).call()
        const decimals = await contract.decimals().call()
        if (!balance || balance.eq(0)) {
          return '0 (最小单位)'
        }
        const formattedBalance = (balance.toNumber() / Math.pow(10, decimals)).toFixed(decimals)
        return `${formattedBalance} (原始: ${balance.toString()}, 小数位: ${decimals})`
      } catch (error) {
        this.addLog('error', `代币余额查询失败: ${error.message}`)
        throw new Error(`代币余额查询失败: ${error.message}`)
      }
    },
    async getTokenInfo(contractAddress) {
      if (!contractAddress) {
        throw new Error('请输入代币合约地址')
      }
      try {
        this.addLog('info', `查询代币信息: ${contractAddress}`)
        const contract = await this.tronWeb.contract().at(contractAddress)
        const [name, symbol, decimals, totalSupply] = await Promise.all([
          contract.name().call(),
          contract.symbol().call(),
          contract.decimals().call(),
          contract.totalSupply().call()
        ])
        const formattedSupply = (totalSupply.toNumber() / Math.pow(10, decimals)).toFixed(decimals)
        return JSON.stringify({
          address: contractAddress,
          name: name || '未知',
          symbol: symbol || '未知',
          decimals: decimals,
          totalSupply: formattedSupply,
          totalSupplyRaw: totalSupply.toString()
        }, null, 2)
      } catch (error) {
        this.addLog('error', `代币信息查询失败: ${error.message}`)
        throw new Error(`代币信息查询失败: ${error.message}`)
      }
    },
    async sendTrx(input) {
      const [address, amount] = input.split(',')
      if (!address || !amount) {
        throw new Error('格式错误: 目标地址,金额(TRX)')
      }
      if (!this.isConnected) {
        throw new Error('请先连接钱包')
      }
      const result = await this.tronWeb.trx.sendTransaction(address, this.tronWeb.toSun(amount))
      return `交易哈希: ${result}`
    },
    async callContract(input) {
      const [contractAddress, method, params] = input.split(',')
      if (!contractAddress || !method) {
        throw new Error('格式错误: 合约地址,方法名,参数')
      }
      if (!this.isConnected) {
        throw new Error('请先连接钱包')
      }
      const contract = await this.tronWeb.contract().at(contractAddress)
      const result = await contract[method](...(params ? params.split('|') : [])).call()
      return JSON.stringify(result, null, 2)
    },
    async getNetwork() {
      const network = await this.tronWeb.trx.getNetwork()
      return JSON.stringify(network, null, 2)
    },
    addLog(type, message) {
      const timestamp = new Date().toLocaleTimeString()
      this.outputLogs.unshift({ type, message, timestamp })
      if (this.outputLogs.length > 50) {
        this.outputLogs.pop()
      }
    },
    formatResult(result) {
      if (typeof result === 'object') {
        return JSON.stringify(result, null, 2)
      }
      return String(result)
    },
    clearLogs() {
      this.outputLogs = []
    },
    connectWallet() {
      if (window.tronWeb && window.tronWeb.ready) {
        this.tronWeb = window.tronWeb
        this.currentAddress = window.tronWeb.defaultAddress.base58
        this.isConnected = true
        this.addLog('success', `已连接钱包: ${this.currentAddress}`)
      } else {
        window.location.href = 'tronlink://'
        setTimeout(() => {
          window.open('https://www.tronlink.org/', '_blank')
        }, 1000)
      }
    },
    async switchNode() {
      const node = this.nodes.find(n => n.name === this.currentNode)
      if (node) {
        try {
          this.tronWeb = new TronWeb({ fullHost: node.url })
          await this.tronWeb.isConnected()
          this.addLog('success', `已切换到节点: ${node.name}`)
        } catch (error) {
          this.addLog('error', `切换节点失败: ${error.message}`)
        }
      }
    },
    async refreshConnection() {
      this.addLog('info', '正在刷新连接...')
      await this.initTronWeb()
    }
  }
}
</script>

<style scoped>
.tronweb-methods {
  padding: 20px;
  max-width: 800px;
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

.connection-status {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 16px;
}

.connection-status span {
  font-size: 14px;
  font-weight: 500;
}

.connected {
  color: #22c55e;
}

.disconnected {
  color: #ef4444;
}

.connect-btn {
  padding: 8px 16px;
  background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
  border: none;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  cursor: pointer;
}

.address {
  font-family: monospace;
  font-size: 12px;
  color: #60a5fa;
}

.node-info {
  font-size: 12px;
  color: #fbbf24;
  background: rgba(251, 191, 36, 0.1);
  padding: 4px 8px;
  border-radius: 4px;
}

.node-selector {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 12px;
  flex-wrap: wrap;
}

.node-selector label {
  color: #94a3b8;
  font-size: 13px;
}

.node-select {
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  color: #ffffff;
  font-size: 13px;
  cursor: pointer;
}

.node-select:focus {
  outline: none;
  border-color: #60a5fa;
}

.refresh-btn {
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  color: #94a3b8;
  font-size: 13px;
  cursor: pointer;
}

.refresh-btn:hover {
  background: rgba(255, 255, 255, 0.1);
}

.input-section {
  margin-bottom: 20px;
}

.input-section label {
  display: block;
  color: #94a3b8;
  font-size: 14px;
  margin-bottom: 8px;
}

.input-field {
  width: 100%;
  padding: 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  box-sizing: border-box;
}

.input-field:focus {
  outline: none;
  border-color: #60a5fa;
}

.methods-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
  margin-bottom: 24px;
}

.method-btn {
  padding: 16px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
}

.method-btn:hover:not(.disabled) {
  background: rgba(255, 255, 255, 0.1);
  border-color: #60a5fa;
}

.method-btn.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.method-name {
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.method-desc {
  color: #94a3b8;
  font-size: 12px;
}

.output-section {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  padding: 16px;
}

.output-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.output-header span {
  color: #e2e8f0;
  font-size: 14px;
  font-weight: 500;
}

.clear-btn {
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 6px;
  color: #94a3b8;
  font-size: 12px;
  cursor: pointer;
}

.clear-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

.output-logs {
  max-height: 300px;
  overflow-y: auto;
}

.log-item {
  padding: 8px 12px;
  margin-bottom: 8px;
  border-radius: 6px;
  font-size: 13px;
}

.log-item.info {
  background: rgba(59, 130, 246, 0.2);
  color: #93c5fd;
}

.log-item.success {
  background: rgba(34, 197, 94, 0.2);
  color: #86efac;
}

.log-item.error {
  background: rgba(239, 68, 68, 0.2);
  color: #fca5a5;
}

.log-time {
  margin-right: 8px;
  opacity: 0.7;
}

.empty-logs {
  color: #64748b;
  text-align: center;
  padding: 20px;
}
</style>
