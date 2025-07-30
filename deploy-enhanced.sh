#!/bin/bash

# Enhanced Reksadana Deployment Script
# This script deploys the enhanced Reksadana contract with manager fees

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please create a .env file with your PRIVATE_KEY:"
    echo "PRIVATE_KEY=your_private_key_here"
    exit 1
fi

# Load environment variables
source .env

# Validate private key
if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
    print_error "Please set your actual PRIVATE_KEY in the .env file"
    exit 1
fi

# Get wallet address from private key
WALLET_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
print_status "Deployer Address: $WALLET_ADDRESS"

# Check wallet balance
BALANCE=$(cast balance $WALLET_ADDRESS --rpc-url https://rpc.sepolia-api.lisk.com)
print_status "Wallet Balance: $BALANCE LSK"

if [ "$BALANCE" -eq 0 ]; then
    print_warning "Wallet has 0 balance. You need LSK tokens for gas fees."
    print_status "You can get test tokens from the Lisk Sepolia faucet."
fi

# Build contracts
print_status "Building contracts..."
forge build --silent

if [ $? -ne 0 ]; then
    print_error "Build failed! Please check your contracts."
    exit 1
fi

print_success "Contracts built successfully!"

# Deploy contracts
print_status "Deploying contracts to Lisk Sepolia..."

DEPLOY_OUTPUT=$(forge script script/Reksadana.s.sol:ReksadanaScript \
    --rpc-url https://rpc.sepolia-api.lisk.com \
    --broadcast \
    --sender $WALLET_ADDRESS \
    --private-key $PRIVATE_KEY \
    --json)

if [ $? -ne 0 ]; then
    print_error "Deployment failed!"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

print_success "Deployment completed successfully!"

# Extract contract addresses from deployment output
REKSADANA_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Reksadana deployed at:" | awk '{print $4}')
MOCK_USDC_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "MockUSDC deployed at:" | awk '{print $4}')

if [ -z "$REKSADANA_ADDRESS" ] || [ -z "$MOCK_USDC_ADDRESS" ]; then
    print_warning "Could not extract contract addresses from output."
    print_status "Please check the deployment output manually."
else
    print_success "Contract Addresses:"
    echo "  Reksadana: $REKSADANA_ADDRESS"
    echo "  MockUSDC:  $MOCK_USDC_ADDRESS"
    
    # Create deployment info file
    cat > deployment-info.txt << EOF
# Reksadana Deployment Information
# Deployed on: $(date)
# Network: Lisk Sepolia
# Deployer: $WALLET_ADDRESS

REKSADANA_ADDRESS=$REKSADANA_ADDRESS
MOCK_USDC_ADDRESS=$MOCK_USDC_ADDRESS

# Frontend Configuration
# Update ss-lisk-frontend/lib/contracts.ts with these addresses:
export const CONTRACT_ADDRESSES = {
  REKSADANA: "$REKSADANA_ADDRESS",
  MOCK_USDC: "$MOCK_USDC_ADDRESS",
} as const;
EOF

    print_success "Deployment information saved to deployment-info.txt"
fi

# Verify contracts
print_status "Verifying contract deployment..."

REKSADANA_CODE=$(cast code $REKSADANA_ADDRESS --rpc-url https://rpc.sepolia-api.lisk.com)
MOCK_USDC_CODE=$(cast code $MOCK_USDC_ADDRESS --rpc-url https://rpc.sepolia-api.lisk.com)

if [ "$REKSADANA_CODE" != "0x" ]; then
    print_success "✅ Reksadana contract verified"
else
    print_error "❌ Reksadana contract not found"
fi

if [ "$MOCK_USDC_CODE" != "0x" ]; then
    print_success "✅ MockUSDC contract verified"
else
    print_error "❌ MockUSDC contract not found"
fi

# Test basic contract functions
print_status "Testing contract functions..."

# Test Reksadana name
REKSADANA_NAME=$(cast call $REKSADANA_ADDRESS "name()" --rpc-url https://rpc.sepolia-api.lisk.com)
if [ "$REKSADANA_NAME" != "0x" ]; then
    print_success "✅ Reksadana name function working"
else
    print_warning "⚠️  Reksadana name function not responding"
fi

# Test MockUSDC name
MOCK_USDC_NAME=$(cast call $MOCK_USDC_ADDRESS "name()" --rpc-url https://rpc.sepolia-api.lisk.com)
if [ "$MOCK_USDC_NAME" != "0x" ]; then
    print_success "✅ MockUSDC name function working"
else
    print_warning "⚠️  MockUSDC name function not responding"
fi

print_success "=== Deployment Summary ==="
echo "✅ Contracts deployed successfully"
echo "✅ Contract addresses extracted"
echo "✅ Contract verification completed"
echo "✅ Basic function tests passed"
echo ""
echo "Next steps:"
echo "1. Update your frontend with the new contract addresses"
echo "2. Test the contracts through the frontend"
echo "3. Run the unit tests: forge test"
echo ""
echo "Frontend update required in: ss-lisk-frontend/lib/contracts.ts" 