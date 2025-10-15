# Kali Linux Security Machine (thea-security) Setup Guide

## Overview
This guide will help you integrate the Kali Linux security machine into the THEA network infrastructure for security scanning, penetration testing, and monitoring.

## Network Configuration

### IP Address Assignment
- **Hostname**: `thea-security`
- **App Network IP**: `192.168.1.30`
- **Management Network IP**: `10.0.2.30`
- **Role**: Security scanning, vulnerability assessment, penetration testing
- **Network Interfaces**:
  - `eth0`: NAT (Internet access)
  - `eth1`: Internal Network (thea-app-network - 192.168.1.30)
  - `eth2`: Internal Network (thea-mgmt-network - 10.0.2.30)

---

## Step 1: Configure Network Interfaces

### Edit Network Configuration
```bash
# Become root
sudo su -

# Backup current network configuration
cp /etc/network/interfaces /etc/network/interfaces.backup

# Edit network interfaces
nano /etc/network/interfaces
```

### Network Interfaces Configuration
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

### Apply Network Configuration
```bash
# Restart networking service
systemctl restart networking

# Or reboot if needed
# reboot

# Verify network interfaces
ip addr show
ip route show
```

---

## Step 2: Configure Hostname

```bash
# Set hostname
hostnamectl set-hostname thea-security

# Verify hostname
hostnamectl
hostname
```

---

## Step 3: Configure /etc/hosts

```bash
# Edit hosts file
nano /etc/hosts
```

### Add THEA Network Hosts
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

## Step 4: Install Required Security Tools

Kali Linux comes with many tools pre-installed, but ensure you have these:

```bash
# Update system
apt update && apt upgrade -y

# Install additional tools if needed
apt install -y \
    nmap \
    nikto \
    sqlmap \
    metasploit-framework \
    burpsuite \
    wireshark \
    tcpdump \
    hydra \
    john \
    hashcat \
    aircrack-ng \
    gobuster \
    dirb \
    wpscan \
    nuclei \
    subfinder \
    httpx \
    ffuf

# Install Docker for containerized security tools
apt install -y docker.io docker-compose
systemctl enable docker
systemctl start docker

# Install OWASP ZAP
apt install -y zaproxy

# Install Trivy for container scanning
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
apt update
apt install -y trivy
```

---

## Step 5: SSH Configuration

### Generate SSH Key for thea-security
```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_thea -C "thea-security@thea.local"

# Display public key
cat ~/.ssh/id_ed25519_thea.pub
```

### Copy SSH Key to Other VMs
```bash
# Copy to thea-cicd
ssh-copy-id -i ~/.ssh/id_ed25519_thea.pub vboxuser@192.168.1.10

# Copy to thea-loadbalancer
ssh-copy-id -i ~/.ssh/id_ed25519_thea.pub vboxuser@192.168.1.40

# Test SSH connections
ssh vboxuser@192.168.1.10 "hostname"
ssh vboxuser@192.168.1.40 "hostname"
```

### Configure SSH Client
```bash
# Create/edit SSH config
nano ~/.ssh/config
```

```bash
Host thea-cicd
    HostName 192.168.1.10
    User vboxuser
    IdentityFile ~/.ssh/id_ed25519_thea
    StrictHostKeyChecking no

Host thea-loadbalancer
    HostName 192.168.1.40
    User vboxuser
    IdentityFile ~/.ssh/id_ed25519_thea
    StrictHostKeyChecking no

Host thea-app1
    HostName 192.168.1.50
    User vboxuser
    IdentityFile ~/.ssh/id_ed25519_thea
    StrictHostKeyChecking no

Host thea-app2
    HostName 192.168.1.60
    User vboxuser
    IdentityFile ~/.ssh/id_ed25519_thea
    StrictHostKeyChecking no
```

```bash
# Set proper permissions
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519_thea
chmod 644 ~/.ssh/id_ed25519_thea.pub
```

---

## Step 6: Configure Firewall (iptables)

```bash
# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow from THEA network
iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Save iptables rules
apt install -y iptables-persistent
netfilter-persistent save
```

---

## Step 7: Verify Connectivity

```bash
# Test ping to all VMs (App Network)
ping -c 3 192.168.1.10  # thea-cicd
ping -c 3 192.168.1.20  # thea-monitor
ping -c 3 192.168.1.40  # thea-loadbalancer
ping -c 3 192.168.1.50  # thea-app1
ping -c 3 192.168.1.60  # thea-app2

# Test ping to all VMs (Management Network)
ping -c 3 10.0.2.10     # thea-cicd-mgmt
ping -c 3 10.0.2.20     # thea-monitor-mgmt
ping -c 3 10.0.2.40     # thea-loadbalancer-mgmt

# Test SSH connections
ssh vboxuser@thea-cicd "hostname"
ssh vboxuser@thea-loadbalancer "hostname"

# Test service endpoints
curl http://192.168.1.10:3000/health
curl http://192.168.1.40/health
```

---

## Step 8: Set Up Security Scanning Scripts

### Create scanning directory
```bash
mkdir -p /opt/thea-security
cd /opt/thea-security
```

### Network Scan Script
```bash
cat > /opt/thea-security/network-scan.sh << 'EOF'
#!/bin/bash
# THEA Network Security Scan

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="/opt/thea-security/reports"
mkdir -p "$REPORT_DIR"

echo "=== THEA Network Security Scan - $TIMESTAMP ==="

# Nmap scan of THEA network
echo "[+] Running Nmap scan..."
nmap -sV -sC -p- -oN "$REPORT_DIR/nmap_scan_$TIMESTAMP.txt" 192.168.1.0/24

# Service-specific scans
echo "[+] Scanning Node.js Backend..."
nmap -p 3000 -sV --script=http-enum,http-headers 192.168.1.10 -oN "$REPORT_DIR/nodejs_scan_$TIMESTAMP.txt"

echo "[+] Scanning FastAPI OCR..."
nmap -p 8000 -sV --script=http-enum,http-headers 192.168.1.10 -oN "$REPORT_DIR/fastapi_scan_$TIMESTAMP.txt"

echo "[+] Scanning Load Balancer..."
nmap -p 80,443,3000,8000,8001,9090,3010 -sV 192.168.1.40 -oN "$REPORT_DIR/loadbalancer_scan_$TIMESTAMP.txt"

echo "[+] Scan complete. Reports saved to $REPORT_DIR"
EOF

chmod +x /opt/thea-security/network-scan.sh
```

### Vulnerability Scan Script
```bash
cat > /opt/thea-security/vuln-scan.sh << 'EOF'
#!/bin/bash
# THEA Vulnerability Scan

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="/opt/thea-security/reports"
mkdir -p "$REPORT_DIR"

echo "=== THEA Vulnerability Scan - $TIMESTAMP ==="

# Nikto web vulnerability scan
echo "[+] Running Nikto on Node.js Backend..."
nikto -h http://192.168.1.10:3000 -o "$REPORT_DIR/nikto_nodejs_$TIMESTAMP.txt"

echo "[+] Running Nikto on FastAPI..."
nikto -h http://192.168.1.10:8000 -o "$REPORT_DIR/nikto_fastapi_$TIMESTAMP.txt"

echo "[+] Running Nikto on Load Balancer..."
nikto -h http://192.168.1.40 -o "$REPORT_DIR/nikto_lb_$TIMESTAMP.txt"

# Nuclei scan
if command -v nuclei &> /dev/null; then
    echo "[+] Running Nuclei..."
    nuclei -u http://192.168.1.10:3000 -o "$REPORT_DIR/nuclei_$TIMESTAMP.txt"
fi

echo "[+] Vulnerability scan complete. Reports saved to $REPORT_DIR"
EOF

chmod +x /opt/thea-security/vuln-scan.sh
```

### Container Security Scan Script
```bash
cat > /opt/thea-security/container-scan.sh << 'EOF'
#!/bin/bash
# THEA Container Security Scan using Trivy

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="/opt/thea-security/reports"
mkdir -p "$REPORT_DIR"

REGISTRY="192.168.1.10:5000"

echo "=== THEA Container Security Scan - $TIMESTAMP ==="

# Scan Node.js Backend
echo "[+] Scanning nodejs_backend..."
trivy image --severity HIGH,CRITICAL "$REGISTRY/nodejs_backend_thea-backend:latest" > "$REPORT_DIR/trivy_nodejs_$TIMESTAMP.txt"

# Scan FastAPI OCR
echo "[+] Scanning fastapi-ocr..."
trivy image --severity HIGH,CRITICAL "$REGISTRY/thea_fastapi-ocr:latest" > "$REPORT_DIR/trivy_fastapi_$TIMESTAMP.txt"

# Scan RAG Chatbot
echo "[+] Scanning rag_chatbot..."
trivy image --severity HIGH,CRITICAL "$REGISTRY/rag_chatbot:latest" > "$REPORT_DIR/trivy_rag_$TIMESTAMP.txt"

echo "[+] Container scan complete. Reports saved to $REPORT_DIR"
EOF

chmod +x /opt/thea-security/container-scan.sh
```

### Configure Docker to use insecure registry
```bash
cat > /etc/docker/daemon.json << 'EOF'
{
  "insecure-registries": ["192.168.1.10:5000"]
}
EOF

systemctl restart docker
```

---

## Step 9: Set Up Automated Scanning (Optional)

```bash
# Add to crontab for automated scans
crontab -e
```

```bash
# Daily network scan at 2 AM
0 2 * * * /opt/thea-security/network-scan.sh >> /var/log/thea-security-scan.log 2>&1

# Weekly vulnerability scan on Sundays at 3 AM
0 3 * * 0 /opt/thea-security/vuln-scan.sh >> /var/log/thea-security-vuln.log 2>&1

# Daily container scan at 4 AM
0 4 * * * /opt/thea-security/container-scan.sh >> /var/log/thea-security-container.log 2>&1
```

---

## Step 10: Configure Monitoring Dashboard

### Install and configure ELK Stack or simple monitoring
```bash
# Create monitoring script
cat > /opt/thea-security/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring dashboard

while true; do
    clear
    echo "=== THEA Security Monitoring Dashboard ==="
    echo "Timestamp: $(date)"
    echo ""
    
    echo "=== VM Status ==="
    ping -c 1 -W 1 192.168.1.10 &>/dev/null && echo "[✓] thea-cicd (192.168.1.10)" || echo "[✗] thea-cicd (192.168.1.10)"
    ping -c 1 -W 1 192.168.1.40 &>/dev/null && echo "[✓] thea-loadbalancer (192.168.1.40)" || echo "[✗] thea-loadbalancer (192.168.1.40)"
    ping -c 1 -W 1 192.168.1.50 &>/dev/null && echo "[✓] thea-app1 (192.168.1.50)" || echo "[✗] thea-app1 (192.168.1.50)"
    ping -c 1 -W 1 192.168.1.60 &>/dev/null && echo "[✓] thea-app2 (192.168.1.60)" || echo "[✗] thea-app2 (192.168.1.60)"
    echo ""
    
    echo "=== Service Status ==="
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.10:3000/health 2>/dev/null | grep -q 200 && echo "[✓] Node.js Backend (port 3000)" || echo "[✗] Node.js Backend (port 3000)"
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.10:8000/health 2>/dev/null | grep -q 200 && echo "[✓] FastAPI OCR (port 8000)" || echo "[✗] FastAPI OCR (port 8000)"
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.10:8001/health 2>/dev/null | grep -q 200 && echo "[✓] RAG Chatbot (port 8001)" || echo "[✗] RAG Chatbot (port 8001)"
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.40/health 2>/dev/null | grep -q 200 && echo "[✓] Load Balancer (port 80)" || echo "[✗] Load Balancer (port 80)"
    echo ""
    
    echo "Press Ctrl+C to exit"
    sleep 5
done
EOF

chmod +x /opt/thea-security/monitor.sh
```

---

## Step 11: Update Ansible Inventory (On thea-cicd)

SSH back to thea-cicd and update Ansible inventory to include security machine:

```bash
# On thea-cicd
nano /home/vboxuser/Downloads/THEA/ansible/inventory.ini
```

Add:
```ini
[security]
thea-security ansible_host=192.168.1.30 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519_thea
```

---

## Quick Command Reference

### On thea-security machine:

```bash
# Check network
ip addr show
ip route show
hostname

# Test connectivity
ping -c 3 thea-cicd
ping -c 3 thea-loadbalancer

# Run security scans
/opt/thea-security/network-scan.sh
/opt/thea-security/vuln-scan.sh
/opt/thea-security/container-scan.sh

# Monitor services
/opt/thea-security/monitor.sh

# View scan reports
ls -lh /opt/thea-security/reports/
```

---

## Verification Checklist

- [ ] Hostname set to `thea-security`
- [ ] Network interfaces configured (eth0, eth1, eth2)
- [ ] IP address 192.168.1.30 assigned to eth1 (App Network)
- [ ] IP address 10.0.2.30 assigned to eth2 (Management Network)
- [ ] /etc/hosts updated with all THEA hosts
- [ ] Can ping all VMs
- [ ] SSH keys generated and distributed
- [ ] Can SSH to thea-cicd and thea-loadbalancer
- [ ] Docker installed and configured
- [ ] Security tools installed
- [ ] Scanning scripts created and executable
- [ ] Can access THEA services via curl
- [ ] Firewall configured

---

## Next Steps

1. **Run initial security assessment**
   ```bash
   /opt/thea-security/network-scan.sh
   ```

2. **Perform vulnerability scan**
   ```bash
   /opt/thea-security/vuln-scan.sh
   ```

3. **Scan container images**
   ```bash
   /opt/thea-security/container-scan.sh
   ```

4. **Review reports**
   ```bash
   cd /opt/thea-security/reports
   ls -lh
   ```

5. **Set up continuous monitoring** using the monitoring dashboard or integrate with Grafana on thea-cicd

---

## Security Notes

- Keep Kali Linux updated regularly: `apt update && apt upgrade`
- Secure SSH keys with strong passphrases
- Only run authorized security scans
- Document all findings in scan reports
- Coordinate with team before running aggressive scans
- Follow responsible disclosure practices

---

## Troubleshooting

### Network not working
```bash
systemctl restart networking
# or
reboot
```

### Can't reach services
```bash
# Check firewall on target VMs
ssh vboxuser@192.168.1.10 "sudo iptables -L -n"

# Check if services are running
ssh vboxuser@192.168.1.10 "docker ps"
```

### SSH connection issues
```bash
# Verify SSH key permissions
ls -l ~/.ssh/
chmod 600 ~/.ssh/id_ed25519_thea
```

---

## Support

For issues or questions, refer to:
- THEA documentation in `/home/vboxuser/Downloads/THEA/`
- Security scan reports in `/opt/thea-security/reports/`
- System logs: `/var/log/`

---

**Last Updated**: October 13, 2025
