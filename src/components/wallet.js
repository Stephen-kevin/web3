import TronWeb from "tronweb";
import WalletConnectProvider from "@walletconnect/web3-provider";

// 1. 创建 WalletConnect + TronWeb
export async function connectWallet() {
  const provider = new WalletConnectProvider({
    rpc: {
      1: "https://api.trongrid.io"
    }
  });

  // 生成 URI（用于唤起 imToken）
  await provider.enable();

  const tronWeb = new TronWeb({
    fullHost: "https://api.trongrid.io",
    provider
  });

  return { tronWeb, provider };
}

// 2. 唤起 imToken（DeepLink）
export function openImToken(uri) {
  const link = `imtokenv2://wc?uri=${encodeURIComponent(uri)}`;
  window.location.href = link;
}

// 3. TRC20 授权 approve
export async function approveToken(tronWeb, tokenAddress, spender, amount) {
  const contract = await tronWeb.contract().at(tokenAddress);

  const tx = await contract.approve(
    spender,
    amount
  ).send({
    feeLimit: 100_000_000
  });

  return tx;
}