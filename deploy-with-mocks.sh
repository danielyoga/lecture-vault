#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Reksadana with Mock Tokens to Anvil...${NC}"
echo ""

# Check if Anvil is running
if ! lsof -i :8545 > /dev/null 2>&1; then
    echo -e "${RED}❌ Anvil is not running on port 8545${NC}"
    echo -e "${YELLOW}💡 Please start Anvil first: anvil${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Anvil is running${NC}"

# Deploy contracts
echo -e "${BLUE}📦 Deploying contracts...${NC}"
forge script script/DeployReksadanaWithMocks.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Deployment successful!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Next steps:${NC}"
    echo "1. Update your frontend contract addresses"
    echo "2. Restart your frontend development server"
    echo "3. Connect your MetaMask to Anvil network"
    echo ""
    echo -e "${BLUE}💡 Contract addresses are shown above${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi 