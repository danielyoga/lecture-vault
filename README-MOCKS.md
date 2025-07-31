# Mock Tokens Deployment Guide

Panduan ini menjelaskan cara deploy dan menggunakan mock tokens (MockWETH, MockWBTC, MockUSDC) untuk development lokal.

## 🚀 Quick Start

### 1. Start Anvil
```bash
anvil
```

### 2. Deploy All Mock Tokens + Reksadana
```bash
./deploy-with-mocks.sh
```

### 3. Manual Deployment (Alternative)
```bash
forge script script/DeployReksadanaWithMocks.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## 📦 Deployed Contracts

Setelah deployment berhasil, Anda akan mendapat address seperti:

```
- Reksadana: 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
- MockUSDC: 0x5FbDB2315678afecb367f032d93F642f64180aa3
- MockWETH: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
- MockWBTC: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

## 💰 Initial Balances

### Deployer (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
- 1,000,000 USDC (1M USDC)
- 1,000 WETH
- 100 WBTC

### Router (0xE592427A0AEce92De3Edee1F18E0157C05861564)
- 10,000,000 USDC (untuk swap simulation)
- 10,000 WETH (untuk swap simulation)
- 1,000 WBTC (untuk swap simulation)

## 🔧 Mock Contracts Features

### MockUSDC
- Standard ERC20 token
- 6 decimals
- `mint(address, uint256)` function untuk mint tokens
- `burn(uint256)` function untuk burn tokens

### MockWETH
- Standard ERC20 token
- 18 decimals (seperti ETH)
- `mint(address, uint256)` function
- `mintToRouter(address, uint256)` function untuk router
- `burn(uint256)` function

### MockWBTC
- Standard ERC20 token
- 8 decimals (seperti Bitcoin)
- `mint(address, uint256)` function
- `mintToRouter(address, uint256)` function untuk router
- `burn(uint256)` function

## 🎯 Usage Examples

### Mint More USDC
```bash
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
    "mint(address,uint256)" \
    YOUR_ADDRESS \
    1000000000000 \
    --private-key YOUR_PRIVATE_KEY \
    --rpc-url http://localhost:8545
```

### Check Balance
```bash
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
    "balanceOf(address)" \
    YOUR_ADDRESS \
    --rpc-url http://localhost:8545
```

### Mint WETH
```bash
cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 \
    "mint(address,uint256)" \
    YOUR_ADDRESS \
    1000000000000000000000 \
    --private-key YOUR_PRIVATE_KEY \
    --rpc-url http://localhost:8545
```

## 🔄 Frontend Integration

Update file `ss-lisk-frontend/lib/contracts.ts`:

```typescript
export const CONTRACT_ADDRESSES = {
  REKSADANA: "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318",
  MOCK_USDC: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
  MOCK_WETH: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", 
  MOCK_WBTC: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
} as const;
```

## 🧪 Testing

Semua mock contracts sudah terintegrasi dengan test suite. Jalankan test dengan:

```bash
forge test
```

## 📝 Notes

1. **Address akan berubah** setiap kali Anvil di-restart
2. **Private key default Anvil** sudah di-hardcode di script
3. **Mock tokens** hanya untuk development, jangan gunakan di production
4. **Router balance** sudah di-setup untuk simulasi swap
5. **Chainlink price feeds** masih menggunakan address asli (untuk testing)

## 🚨 Security Warning

⚠️ **JANGAN GUNAKAN PRIVATE KEY INI DI MAINNET!**

Private key yang digunakan adalah default Anvil key yang sudah public. Hanya gunakan untuk development lokal.

## 🆘 Troubleshooting

### Anvil tidak berjalan
```bash
lsof -i :8545  # Check if Anvil is running
anvil          # Start Anvil
```

### Deployment gagal
1. Pastikan Anvil berjalan
2. Pastikan tidak ada process lain yang menggunakan port 8545
3. Restart Anvil jika perlu

### Frontend tidak connect
1. Update contract addresses di `contracts.ts`
2. Restart frontend development server
3. Refresh browser dan reconnect MetaMask 