#!/bin/bash
# SSH Key Distribution Script for THEA Infrastructure
# This script copies the Ansible SSH key to all THEA VMs

set -e

SSH_KEY="$HOME/.ssh/thea-ansible-key.pub"
SSH_USER="vboxuser"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== THEA SSH Key Distribution ===${NC}"
echo ""

if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}Error: SSH key not found at $SSH_KEY${NC}"
    echo "Please generate the key first using:"
    echo "  ssh-keygen -t ed25519 -C 'ansible@thea-cicd' -f ~/.ssh/thea-ansible-key"
    exit 1
fi

echo -e "${YELLOW}This script will copy your SSH key to the following VMs:${NC}"
echo "  - thea-loadbalancer (192.168.1.40)"
echo "  - thea-app1 (192.168.1.50)"
echo "  - thea-app2 (192.168.1.60)"
echo ""
echo -e "${YELLOW}You will be prompted for the password for each VM.${NC}"
echo ""

# Array of VMs to configure
declare -A VMS
VMS[thea-loadbalancer]="192.168.1.40"
VMS[thea-app1]="192.168.1.50"
VMS[thea-app2]="192.168.1.60"

# Copy SSH key to each VM
for vm_name in "${!VMS[@]}"; do
    vm_ip="${VMS[$vm_name]}"
    echo -e "${GREEN}Copying SSH key to $vm_name ($vm_ip)...${NC}"
    
    if ssh-copy-id -i "$SSH_KEY" "$SSH_USER@$vm_ip" 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully copied key to $vm_name${NC}"
    else
        echo -e "${RED}❌ Failed to copy key to $vm_name${NC}"
        echo -e "${YELLOW}Note: If this is the first connection, you need to accept the host key fingerprint.${NC}"
    fi
    echo ""
done

echo -e "${GREEN}=== SSH Key Distribution Complete ===${NC}"
echo ""
echo -e "${YELLOW}Testing connections...${NC}"
echo ""

# Test SSH connectivity
for vm_name in "${!VMS[@]}"; do
    vm_ip="${VMS[$vm_name]}"
    if ssh -i "${SSH_KEY%.pub}" -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$vm_ip" "echo 'SSH OK'" 2>/dev/null; then
        echo -e "${GREEN}✅ $vm_name: SSH connection successful${NC}"
    else
        echo -e "${RED}❌ $vm_name: SSH connection failed${NC}"
    fi
done

echo ""
echo -e "${GREEN}Done! You can now run Ansible playbooks.${NC}"
