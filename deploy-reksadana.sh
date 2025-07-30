#!/bin/bash

# Deploy Reksadana Contract to Lisk Sepolia
# Make sure to replace YOUR_WALLET_ADDRESS and YOUR_PRIVATE_KEY with your actual values

echo "🚀 Deploying Reksadana Contract to Lisk Sepolia..."

# Check if .env file exists and has PRIVATE_KEY
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please create one with your PRIVATE_KEY"
    echo "Example: echo 'PRIVATE_KEY=your_private_key_here' > .env"
    exit 1
fi

# Load environment variables
source .env

if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
    echo "❌ Please set your actual PRIVATE_KEY in the .env file"
    exit 1
fi

# Get wallet address from private key
WALLET_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
echo "📝 Wallet Address: $WALLET_ADDRESS"

# Deploy the contract
echo "🔨 Deploying Reksadana contract..."
forge script script/Reksadana.s.sol:ReksadanaScript \
  --rpc-url https://rpc.sepolia-api.lisk.com \
  --broadcast \
  --sender $WALLET_ADDRESS \
  --private-key $PRIVATE_KEY

echo "✅ Deployment complete!"
echo "📋 Check the broadcast folder for deployment details" 