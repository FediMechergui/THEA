# Nessus and OWASP ZAP Setup Guide for THEA CI/CD

## Overview
This guide will install and configure Nessus (vulnerability scanner) and OWASP ZAP (web application security scanner) on thea-cicd to work with the THEA infrastructure.

---

## Part 1: Install Nessus

### Step 1: Download and Install Nessus Essentials

```bash
# Create directory for security tools
sudo mkdir -p /opt/security-tools
cd /opt/security-tools

# Download Nessus (Ubuntu/Debian version)
# Go to https://www.tenable.com/downloads/nessus and get the download link
# For Ubuntu 22.04 (AMD64):
wget https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.8.3-ubuntu1404_amd64.deb

# Install Nessus
sudo dpkg -i Nessus-10.8.3-ubuntu1404_amd64.deb

# Start Nessus service
sudo systemctl start nessusd
sudo systemctl enable nessusd

# Check status
sudo systemctl status nessusd
```

### Step 2: Configure Nessus

```bash
# Nessus will be available at: https://localhost:8834
# Wait for Nessus to initialize (takes 2-3 minutes)

echo "Waiting for Nessus to start..."
sleep 120

# Check if Nessus is ready
curl -k https://localhost:8834
```

**Manual Configuration Steps:**
1. Open browser and navigate to: `https://192.168.1.10:8834`
2. Choose "Nessus Essentials" (free for up to 16 IPs)
3. Get activation code from: https://www.tenable.com/products/nessus/nessus-essentials
4. Create admin user credentials
5. Wait for plugin compilation (15-30 minutes)

### Step 3: Configure Nessus for THEA Environment

Create a scan configuration file:

```bash
# Create Nessus scan targets file
cat > /opt/security-tools/nessus-targets.txt << 'EOF'
# THEA Infrastructure Targets
192.168.1.10    # thea-cicd
192.168.1.40    # thea-loadbalancer

# THEA Services
192.168.1.10:3000    # Node.js Backend
192.168.1.10:8000    # FastAPI OCR
192.168.1.10:8001    # RAG Chatbot
192.168.1.10:3010    # Grafana
192.168.1.10:9090    # Prometheus
192.168.1.10:3307    # MySQL
192.168.1.10:6379    # Redis
192.168.1.10:5432    # PostgreSQL

# Load Balancer
192.168.1.40:80      # Nginx
192.168.1.40:3000    # Backend proxy
192.168.1.40:8000    # OCR proxy
192.168.1.40:8001    # Chatbot proxy
EOF
```

### Step 4: Create Nessus Scan Script

```bash
cat > /opt/security-tools/run-nessus-scan.sh << 'EOF'
#!/bin/bash
# Automated Nessus scan trigger

NESSUS_URL="https://localhost:8834"
REPORT_DIR="/opt/security-tools/reports/nessus"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$REPORT_DIR"

echo "=== THEA Nessus Scan - $TIMESTAMP ==="
echo "Nessus web interface: $NESSUS_URL"
echo "Login and configure scans manually or use Nessus API"
echo ""
echo "Recommended Scans:"
echo "1. Basic Network Scan - All THEA infrastructure"
echo "2. Web Application Tests - Services on ports 3000, 8000, 8001"
echo "3. Advanced Scan - Deep vulnerability assessment"
echo ""
echo "Reports will be saved to: $REPORT_DIR"
EOF

chmod +x /opt/security-tools/run-nessus-scan.sh
```

---

## Part 2: Install OWASP ZAP

### Step 1: Install OWASP ZAP

```bash
# Install Java (required for ZAP)
sudo apt update
sudo apt install -y default-jdk

# Download and install OWASP ZAP
cd /opt/security-tools

# Get latest version from https://www.zaproxy.org/download/
wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz

# Extract
tar -xvf ZAP_2.15.0_Linux.tar.gz
sudo mv ZAP_2.15.0 /opt/zaproxy

# Create symlink
sudo ln -s /opt/zaproxy/zap.sh /usr/local/bin/zap

# Make executable
sudo chmod +x /opt/zaproxy/zap.sh
```

### Step 2: Configure ZAP for Headless Operation

```bash
# Create ZAP configuration directory
mkdir -p ~/.ZAP

# Create ZAP API key
ZAP_API_KEY=$(openssl rand -hex 16)
echo "ZAP API Key: $ZAP_API_KEY" | tee /opt/security-tools/zap-api-key.txt

# Start ZAP in daemon mode
cat > /opt/security-tools/start-zap.sh << 'EOF'
#!/bin/bash
# Start OWASP ZAP in daemon mode

ZAP_PORT=8080
API_KEY=$(cat /opt/security-tools/zap-api-key.txt | grep "ZAP API Key:" | cut -d' ' -f4)

echo "Starting OWASP ZAP on port $ZAP_PORT..."
/opt/zaproxy/zap.sh -daemon -host 0.0.0.0 -port $ZAP_PORT -config api.key=$API_KEY -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true &

echo "ZAP started. API available at http://localhost:$ZAP_PORT"
echo "API Key: $API_KEY"
EOF

chmod +x /opt/security-tools/start-zap.sh
```

### Step 3: Create ZAP Scanning Scripts

```bash
# Install ZAP Python client
sudo pip3 install python-owasp-zap-v2.4

# Create THEA web app scan script
cat > /opt/security-tools/zap-scan-thea.py << 'EOF'
#!/usr/bin/env python3
"""
OWASP ZAP Scanner for THEA Infrastructure
"""

from zapv2 import ZAPv2
import time
import sys
from datetime import datetime

# ZAP Configuration
ZAP_HOST = 'localhost'
ZAP_PORT = 8080

# Read API key
with open('/opt/security-tools/zap-api-key.txt', 'r') as f:
    API_KEY = f.read().split(': ')[1].strip()

# Initialize ZAP client
zap = ZAPv2(apikey=API_KEY, proxies={'http': f'http://{ZAP_HOST}:{ZAP_PORT}', 'https': f'http://{ZAP_HOST}:{ZAP_PORT}'})

# THEA Targets
TARGETS = {
    'nodejs_backend': 'http://192.168.1.10:3000',
    'fastapi_ocr': 'http://192.168.1.10:8000',
    'rag_chatbot': 'http://192.168.1.10:8001',
    'grafana': 'http://192.168.1.10:3010',
    'prometheus': 'http://192.168.1.10:9090',
    'loadbalancer': 'http://192.168.1.40',
    'lb_nodejs': 'http://192.168.1.40:3000',
    'lb_ocr': 'http://192.168.1.40:8000',
    'lb_chatbot': 'http://192.168.1.40:8001',
}

def scan_target(name, url):
    """Scan a target URL with ZAP"""
    print(f"\n[+] Scanning {name}: {url}")
    
    try:
        # Spider the target
        print(f"  [*] Spidering {url}...")
        scan_id = zap.spider.scan(url)
        
        # Wait for spider to complete
        while int(zap.spider.status(scan_id)) < 100:
            print(f"  [*] Spider progress: {zap.spider.status(scan_id)}%")
            time.sleep(2)
        
        print(f"  [✓] Spider completed")
        
        # Active scan
        print(f"  [*] Active scanning {url}...")
        scan_id = zap.ascan.scan(url)
        
        # Wait for active scan to complete
        while int(zap.ascan.status(scan_id)) < 100:
            print(f"  [*] Scan progress: {zap.ascan.status(scan_id)}%")
            time.sleep(5)
        
        print(f"  [✓] Active scan completed")
        
        return True
        
    except Exception as e:
        print(f"  [✗] Error scanning {name}: {str(e)}")
        return False

def generate_report():
    """Generate HTML report"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_dir = '/opt/security-tools/reports/zap'
    import os
    os.makedirs(report_dir, exist_ok=True)
    
    report_file = f'{report_dir}/zap_report_{timestamp}.html'
    
    print(f"\n[+] Generating report: {report_file}")
    
    html_report = zap.core.htmlreport()
    with open(report_file, 'w') as f:
        f.write(html_report)
    
    print(f"[✓] Report saved to {report_file}")
    
    # Print summary
    alerts = zap.core.alerts()
    print(f"\n=== Scan Summary ===")
    print(f"Total alerts: {len(alerts)}")
    
    risk_counts = {'High': 0, 'Medium': 0, 'Low': 0, 'Informational': 0}
    for alert in alerts:
        risk = alert.get('risk', 'Informational')
        risk_counts[risk] = risk_counts.get(risk, 0) + 1
    
    print(f"High: {risk_counts['High']}")
    print(f"Medium: {risk_counts['Medium']}")
    print(f"Low: {risk_counts['Low']}")
    print(f"Informational: {risk_counts['Informational']}")

def main():
    print("=== OWASP ZAP Scanner for THEA Infrastructure ===")
    print(f"Timestamp: {datetime.now()}")
    
    # Check if ZAP is running
    try:
        print(f"\n[+] Checking ZAP status...")
        version = zap.core.version
        print(f"[✓] ZAP is running (version: {version})")
    except Exception as e:
        print(f"[✗] Cannot connect to ZAP. Is it running?")
        print(f"    Start ZAP with: /opt/security-tools/start-zap.sh")
        sys.exit(1)
    
    # Scan all targets
    for name, url in TARGETS.items():
        scan_target(name, url)
    
    # Generate report
    generate_report()
    
    print("\n[✓] THEA security scan completed!")

if __name__ == '__main__':
    main()
EOF

chmod +x /opt/security-tools/zap-scan-thea.py
```

### Step 4: Create Quick Scan Script (Baseline)

```bash
cat > /opt/security-tools/zap-baseline-scan.sh << 'EOF'
#!/bin/bash
# OWASP ZAP Baseline Scan for THEA

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="/opt/security-tools/reports/zap"
mkdir -p "$REPORT_DIR"

echo "=== OWASP ZAP Baseline Scan - $TIMESTAMP ==="

# Targets to scan
TARGETS=(
    "http://192.168.1.10:3000"
    "http://192.168.1.10:8000"
    "http://192.168.1.10:8001"
    "http://192.168.1.40"
)

for target in "${TARGETS[@]}"; do
    echo "[+] Scanning $target..."
    
    # Run baseline scan using Docker
    docker run --rm \
        --network host \
        -v "$REPORT_DIR:/zap/wrk/:rw" \
        ghcr.io/zaproxy/zaproxy:stable \
        zap-baseline.py \
        -t "$target" \
        -r "baseline_$(echo $target | tr ':/' '__')_${TIMESTAMP}.html" \
        -J "baseline_$(echo $target | tr ':/' '__')_${TIMESTAMP}.json"
done

echo "[✓] Baseline scans completed. Reports in $REPORT_DIR"
EOF

chmod +x /opt/security-tools/zap-baseline-scan.sh
```

---

## Part 3: Integration with Existing Prometheus/Grafana

### Update Prometheus to Monitor Security Tools

```bash
# Add to prometheus configuration
cat >> /opt/thea/prometheus.yml << 'EOF'

  # Nessus monitoring
  - job_name: 'nessus'
    static_configs:
      - targets: ['localhost:8834']
        labels:
          service: 'nessus'

  # ZAP monitoring
  - job_name: 'zap'
    static_configs:
      - targets: ['localhost:8080']
        labels:
          service: 'zap'
EOF

# Restart Prometheus
cd /opt/thea
docker compose restart prometheus
```

---

## Part 4: Create Unified Security Dashboard

```bash
cat > /opt/security-tools/security-dashboard.sh << 'EOF'
#!/bin/bash
# THEA Security Tools Dashboard

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         THEA Security Tools Dashboard                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check Nessus
echo "=== Nessus Status ==="
if systemctl is-active --quiet nessusd; then
    echo "[✓] Nessus is running"
    echo "    URL: https://192.168.1.10:8834"
else
    echo "[✗] Nessus is not running"
    echo "    Start with: sudo systemctl start nessusd"
fi
echo ""

# Check ZAP
echo "=== OWASP ZAP Status ==="
if pgrep -f "zap.sh.*daemon" > /dev/null; then
    echo "[✓] ZAP is running"
    echo "    URL: http://192.168.1.10:8080"
    if [ -f /opt/security-tools/zap-api-key.txt ]; then
        echo "    API Key: $(grep 'ZAP API Key' /opt/security-tools/zap-api-key.txt | cut -d' ' -f4)"
    fi
else
    echo "[✗] ZAP is not running"
    echo "    Start with: /opt/security-tools/start-zap.sh"
fi
echo ""

# Check THEA services
echo "=== THEA Services Status ==="
services=(
    "192.168.1.10:3000:Node.js Backend"
    "192.168.1.10:8000:FastAPI OCR"
    "192.168.1.10:8001:RAG Chatbot"
    "192.168.1.40:80:Load Balancer"
)

for service in "${services[@]}"; do
    IFS=: read -r host port name <<< "$service"
    if curl -s -o /dev/null -w "%{http_code}" "http://${host}:${port}/health" 2>/dev/null | grep -q "200"; then
        echo "[✓] $name ($host:$port)"
    else
        echo "[✗] $name ($host:$port)"
    fi
done
echo ""

# Recent scan reports
echo "=== Recent Security Reports ==="
if [ -d /opt/security-tools/reports ]; then
    echo "Nessus Reports:"
    ls -lht /opt/security-tools/reports/nessus/ 2>/dev/null | head -5 || echo "  No reports yet"
    echo ""
    echo "ZAP Reports:"
    ls -lht /opt/security-tools/reports/zap/ 2>/dev/null | head -5 || echo "  No reports yet"
fi
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║ Quick Commands                                               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║ Start ZAP:          /opt/security-tools/start-zap.sh        ║"
echo "║ ZAP Full Scan:      /opt/security-tools/zap-scan-thea.py    ║"
echo "║ ZAP Baseline Scan:  /opt/security-tools/zap-baseline-scan.sh║"
echo "║ Nessus Web UI:      https://192.168.1.10:8834               ║"
echo "║ Grafana Dashboard:  http://192.168.1.10:3010                ║"
echo "║ Prometheus:         http://192.168.1.10:9090                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
EOF

chmod +x /opt/security-tools/security-dashboard.sh

# Create alias for easy access
echo "alias security-dashboard='/opt/security-tools/security-dashboard.sh'" >> ~/.bashrc
```

---

## Part 5: Automated Security Scanning

```bash
# Create comprehensive scan script
cat > /opt/security-tools/full-security-scan.sh << 'EOF'
#!/bin/bash
# Full THEA Security Assessment

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/opt/security-tools/reports/full_scan_${TIMESTAMP}.log"

echo "=== THEA Full Security Scan - $TIMESTAMP ===" | tee "$LOG_FILE"

# 1. Start ZAP if not running
if ! pgrep -f "zap.sh.*daemon" > /dev/null; then
    echo "[+] Starting OWASP ZAP..." | tee -a "$LOG_FILE"
    /opt/security-tools/start-zap.sh
    sleep 30
fi

# 2. Run ZAP scans
echo "[+] Running OWASP ZAP scans..." | tee -a "$LOG_FILE"
/opt/security-tools/zap-scan-thea.py 2>&1 | tee -a "$LOG_FILE"

# 3. Nessus scan reminder
echo "[+] Nessus Scan Info:" | tee -a "$LOG_FILE"
echo "    Login to https://192.168.1.10:8834 to run Nessus scans" | tee -a "$LOG_FILE"

# 4. Generate summary
echo "" | tee -a "$LOG_FILE"
echo "=== Scan Summary ===" | tee -a "$LOG_FILE"
echo "Timestamp: $TIMESTAMP" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "ZAP Reports: /opt/security-tools/reports/zap/" | tee -a "$LOG_FILE"
echo "Nessus Reports: https://192.168.1.10:8834" | tee -a "$LOG_FILE"

echo "[✓] Full security scan completed!" | tee -a "$LOG_FILE"
EOF

chmod +x /opt/security-tools/full-security-scan.sh
```

---

## Installation Commands Summary

Run these commands on **thea-cicd**:

```bash
# 1. Create directories
sudo mkdir -p /opt/security-tools/reports/{nessus,zap}

# 2. Download and install Nessus (manual download needed)
# Visit: https://www.tenable.com/downloads/nessus
# Then: sudo dpkg -i Nessus-*.deb && sudo systemctl start nessusd

# 3. Install Java for ZAP
sudo apt update && sudo apt install -y default-jdk

# 4. Download and install ZAP
cd /opt/security-tools
wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz
tar -xvf ZAP_2.15.0_Linux.tar.gz
sudo mv ZAP_2.15.0 /opt/zaproxy
sudo ln -s /opt/zaproxy/zap.sh /usr/local/bin/zap

# 5. Install ZAP Python client
sudo pip3 install python-owasp-zap-v2.4

# 6. Generate ZAP API key
ZAP_API_KEY=$(openssl rand -hex 16)
echo "ZAP API Key: $ZAP_API_KEY" | sudo tee /opt/security-tools/zap-api-key.txt
```

---

## Quick Start Guide

```bash
# 1. View security dashboard
/opt/security-tools/security-dashboard.sh

# 2. Start OWASP ZAP
/opt/security-tools/start-zap.sh

# 3. Run baseline security scan
/opt/security-tools/zap-baseline-scan.sh

# 4. Run full ZAP scan
/opt/security-tools/zap-scan-thea.py

# 5. Access Nessus
firefox https://192.168.1.10:8834

# 6. Run comprehensive security assessment
/opt/security-tools/full-security-scan.sh
```

---

## Access URLs

- **Nessus**: https://192.168.1.10:8834
- **OWASP ZAP**: http://192.168.1.10:8080
- **Grafana**: http://192.168.1.10:3010
- **Prometheus**: http://192.168.1.10:9090
- **Node.js Backend**: http://192.168.1.10:3000
- **Load Balancer**: http://192.168.1.40

---

## Next Steps

1. Complete Nessus activation at https://192.168.1.10:8834
2. Start ZAP and run initial baseline scans
3. Review security reports in `/opt/security-tools/reports/`
4. Configure automated scanning schedule
5. Integrate findings with CI/CD pipeline
