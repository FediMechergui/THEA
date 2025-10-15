# THEA Security Machine Quick Setup

## Network Configuration for thea-security (Kali Linux)

### IP Addresses:
- **App Network (eth1)**: 192.168.1.30
- **Management Network (eth2)**: 10.0.2.30

---

## Quick Setup Commands

### 1. Configure Network Interfaces
```bash
sudo nano /etc/network/interfaces
```

Paste this configuration:
```bash
# Loopback interface
auto lo
iface lo inet loopback

# NAT interface (eth0) - for internet access
auto eth0
iface eth0 inet dhcp

# Internal Network interface (eth1) - THEA App Network
auto eth1
iface eth1 inet static
    address 192.168.1.30
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4

# Internal Network interface (eth2) - THEA Management Network
auto eth2
iface eth2 inet static
    address 10.0.2.30
    netmask 255.255.255.0
```

Apply changes:
```bash
sudo systemctl restart networking
# or reboot if needed
sudo reboot
```

---

### 2. Set Hostname
```bash
sudo hostnamectl set-hostname thea-security
```

---

### 3. Configure /etc/hosts
```bash
sudo nano /etc/hosts
```

Paste this:
```bash
127.0.0.1       localhost
127.0.1.1       thea-security

# THEA App Network
192.168.1.10    thea-cicd
192.168.1.20    thea-monitor
192.168.1.30    thea-security
192.168.1.40    thea-loadbalancer
192.168.1.50    thea-app1
192.168.1.60    thea-app2

# THEA Management Network
10.0.2.10       thea-cicd-mgmt
10.0.2.20       thea-monitor-mgmt
10.0.2.30       thea-security-mgmt
10.0.2.40       thea-loadbalancer-mgmt
10.0.2.50       thea-app1-mgmt
10.0.2.60       thea-app2-mgmt

# THEA Services (via thea-cicd)
192.168.1.10    nodejs-backend.thea
192.168.1.10    fastapi-ocr.thea
192.168.1.10    rag-chatbot.thea
192.168.1.10    grafana.thea
192.168.1.10    prometheus.thea

# Load Balancer endpoints
192.168.1.40    api.thea
192.168.1.40    thea.local
```

---

### 4. Verify Network Configuration
```bash
# Check IP addresses
ip addr show

# Test connectivity to app network
ping -c 3 192.168.1.10
ping -c 3 192.168.1.20
ping -c 3 192.168.1.40

# Test connectivity to management network
ping -c 3 10.0.2.10
ping -c 3 10.0.2.20
ping -c 3 10.0.2.40

# Test internet connectivity
ping -c 3 8.8.8.8

# Check hostname
hostname
hostnamectl
```

---

### 5. Configure SSH
```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_thea -C "thea-security@thea.local"

# Copy to other VMs
ssh-copy-id -i ~/.ssh/id_ed25519_thea.pub vboxuser@192.168.1.10
ssh-copy-id -i ~/.ssh/id_ed25519_thea.pub vboxuser@192.168.1.20
ssh-copy-id -i ~/.ssh/id_ed25519_thea.pub vboxuser@192.168.1.40

# Test SSH
ssh -i ~/.ssh/id_ed25519_thea vboxuser@192.168.1.10 "hostname"
ssh -i ~/.ssh/id_ed25519_thea vboxuser@192.168.1.40 "hostname"
```

---

### 6. Install Docker
```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Configure insecure registry
sudo tee /etc/docker/daemon.json << EOF
{
  "insecure-registries": ["192.168.1.10:5000"]
}
EOF

sudo systemctl restart docker
```

---

### 7. Test THEA Services Access
```bash
# Test Node.js Backend
curl http://192.168.1.10:3000/health

# Test FastAPI OCR
curl http://192.168.1.10:8000/health

# Test RAG Chatbot
curl http://192.168.1.10:8001/health

# Test Load Balancer
curl http://192.168.1.40/health

# Test via load balancer ports
curl http://192.168.1.40:3000/health
curl http://192.168.1.40:8000/health
curl http://192.168.1.40:8001/health
```

---

## VirtualBox Network Adapter Settings

Make sure your thea-security VM has these adapters configured in VirtualBox:

| Adapter | Type | Name | Network |
|---------|------|------|---------|
| Adapter 1 | NAT | - | Internet access |
| Adapter 2 | Internal Network | thea-app-network | 192.168.1.30 |
| Adapter 3 | Internal Network | thea-mgmt-network | 10.0.2.30 |

---

## Verification Checklist

```bash
# Run all checks at once
echo "=== Network Interfaces ==="
ip addr show | grep -E "eth|inet "

echo -e "\n=== Hostname ==="
hostname

echo -e "\n=== App Network Connectivity ==="
ping -c 2 192.168.1.10 && echo "✓ thea-cicd reachable" || echo "✗ thea-cicd unreachable"
ping -c 2 192.168.1.40 && echo "✓ thea-loadbalancer reachable" || echo "✗ thea-loadbalancer unreachable"

echo -e "\n=== Management Network Connectivity ==="
ping -c 2 10.0.2.10 && echo "✓ thea-cicd-mgmt reachable" || echo "✗ thea-cicd-mgmt unreachable"
ping -c 2 10.0.2.20 && echo "✓ thea-monitor-mgmt reachable" || echo "✗ thea-monitor-mgmt unreachable"

echo -e "\n=== Service Health Checks ==="
curl -s http://192.168.1.10:3000/health | grep -q status && echo "✓ Node.js Backend OK" || echo "✗ Node.js Backend FAIL"
curl -s http://192.168.1.40/health | grep -q OK && echo "✓ Load Balancer OK" || echo "✗ Load Balancer FAIL"

echo -e "\n=== Docker Status ==="
docker --version && echo "✓ Docker installed" || echo "✗ Docker not installed"
sudo systemctl is-active docker && echo "✓ Docker running" || echo "✗ Docker not running"
```

---

## Next Steps

Once networking is confirmed, proceed with security scanning setup from the full guide:
- `/home/vboxuser/Downloads/THEA/KALI_SECURITY_SETUP_GUIDE.md`

---

**Quick troubleshooting:**
- If network doesn't work: `sudo systemctl restart networking` or `sudo reboot`
- If SSH fails: Check SSH key permissions `chmod 600 ~/.ssh/id_ed25519_thea`
- If can't reach services: Check firewall on target VM
- If Docker registry fails: Verify insecure-registries in `/etc/docker/daemon.json`
