#!/bin/bash
# SSH Key Setup for thea-loadbalancer
# Simplified version for partial deployment

set -e

SSH_KEY="$HOME/.ssh/thea-ansible-key.pub"
SSH_USER="vboxuser"
LB_IP="192.168.1.40"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== THEA SSH Key Setup for Load Balancer ===${NC}"
echo ""

if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}Error: SSH key not found at $SSH_KEY${NC}"
    exit 1
fi

echo -e "${YELLOW}Copying SSH key to thea-loadbalancer ($LB_IP)...${NC}"
echo -e "${YELLOW}You will be prompted for the password.${NC}"
echo ""

if ssh-copy-id -i "$SSH_KEY" "$SSH_USER@$LB_IP" 2>/dev/null; then
    echo -e "${GREEN}✅ Successfully copied key to thea-loadbalancer${NC}"
else
    echo -e "${RED}❌ Failed to copy key to thea-loadbalancer${NC}"
    echo -e "${YELLOW}Trying with verbose output...${NC}"
    ssh-copy-id -i "$SSH_KEY" "$SSH_USER@$LB_IP"
fi

echo ""
echo -e "${YELLOW}Testing SSH connection...${NC}"

if ssh -i "${SSH_KEY%.pub}" -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$LB_IP" "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH connection successful!${NC}"
else
    echo -e "${RED}❌ SSH connection failed${NC}"
    echo -e "${YELLOW}Try manually: ssh $SSH_USER@$LB_IP${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Done! You can now run the deployment.${NC}"
