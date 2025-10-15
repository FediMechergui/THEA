#!/bin/bash
# Automated Nessus and OWASP ZAP Installation for THEA

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   THEA Security Tools Installation (Nessus + OWASP ZAP)     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running on thea-cicd
if [ "$(hostname)" != "thea-cicd" ]; then
    echo "⚠ Warning: This script should be run on thea-cicd"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create directories
echo "[1/8] Creating directories..."
sudo mkdir -p /opt/security-tools/reports/{nessus,zap}
sudo chown -R $USER:$USER /opt/security-tools

# Install dependencies
echo "[2/8] Installing dependencies..."
sudo apt update
sudo apt install -y default-jdk wget curl python3-pip

# Install ZAP Python client
echo "[3/8] Installing OWASP ZAP Python client..."
sudo pip3 install python-owasp-zap-v2.4

# Download and install OWASP ZAP
echo "[4/8] Downloading OWASP ZAP..."
cd /opt/security-tools

if [ ! -f "ZAP_2.15.0_Linux.tar.gz" ]; then
    wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz
fi

if [ ! -d "/opt/zaproxy" ]; then
    echo "[5/8] Installing OWASP ZAP..."
    tar -xzf ZAP_2.15.0_Linux.tar.gz
    sudo mv ZAP_2.15.0 /opt/zaproxy
    sudo ln -sf /opt/zaproxy/zap.sh /usr/local/bin/zap
    sudo chmod +x /opt/zaproxy/zap.sh
else
    echo "[5/8] OWASP ZAP already installed, skipping..."
fi

# Generate ZAP API key
echo "[6/8] Generating ZAP API key..."
ZAP_API_KEY=$(openssl rand -hex 16)
echo "ZAP API Key: $ZAP_API_KEY" | tee /opt/security-tools/zap-api-key.txt

# Create ZAP start script
echo "[7/8] Creating ZAP startup script..."
cat > /opt/security-tools/start-zap.sh << 'EOF'
#!/bin/bash
# Start OWASP ZAP in daemon mode

ZAP_PORT=8080
API_KEY=$(cat /opt/security-tools/zap-api-key.txt | grep "ZAP API Key:" | cut -d' ' -f4)

if pgrep -f "zap.sh.*daemon" > /dev/null; then
    echo "ZAP is already running"
    exit 0
fi

echo "Starting OWASP ZAP on port $ZAP_PORT..."
nohup /opt/zaproxy/zap.sh -daemon -host 0.0.0.0 -port $ZAP_PORT -config api.key=$API_KEY -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true > /opt/security-tools/zap.log 2>&1 &

sleep 5
if pgrep -f "zap.sh.*daemon" > /dev/null; then
    echo "✓ ZAP started successfully"
    echo "  API available at http://localhost:$ZAP_PORT"
    echo "  API Key: $API_KEY"
else
    echo "✗ Failed to start ZAP. Check /opt/security-tools/zap.log"
fi
EOF

chmod +x /opt/security-tools/start-zap.sh

# Create ZAP scanning script
echo "[8/8] Creating security scanning scripts..."
cat > /opt/security-tools/zap-scan-thea.py << 'PYEOF'
#!/usr/bin/env python3
"""OWASP ZAP Scanner for THEA Infrastructure"""

from zapv2 import ZAPv2
import time
import sys
import os
from datetime import datetime

# ZAP Configuration
ZAP_HOST = 'localhost'
ZAP_PORT = 8080

# Read API key
try:
    with open('/opt/security-tools/zap-api-key.txt', 'r') as f:
        API_KEY = f.read().split(': ')[1].strip()
except Exception as e:
    print(f"Error reading API key: {e}")
    sys.exit(1)

# Initialize ZAP client
zap = ZAPv2(apikey=API_KEY, proxies={
    'http': f'http://{ZAP_HOST}:{ZAP_PORT}',
    'https': f'http://{ZAP_HOST}:{ZAP_PORT}'
})

# THEA Targets
TARGETS = {
    'nodejs_backend': 'http://192.168.1.10:3000',
    'fastapi_ocr': 'http://192.168.1.10:8000',
    'rag_chatbot': 'http://192.168.1.10:8001',
    'grafana': 'http://192.168.1.10:3010',
    'prometheus': 'http://192.168.1.10:9090',
    'loadbalancer': 'http://192.168.1.40',
}

def scan_target(name, url):
    """Scan a target URL with ZAP"""
    print(f"\n[+] Scanning {name}: {url}")
    
    try:
        # Spider the target
        print(f"  [*] Spidering {url}...")
        scan_id = zap.spider.scan(url)
        
        while int(zap.spider.status(scan_id)) < 100:
            progress = zap.spider.status(scan_id)
            print(f"  [*] Spider progress: {progress}%", end='\r')
            time.sleep(2)
        print(f"  [✓] Spider completed      ")
        
        # Active scan
        print(f"  [*] Active scanning {url}...")
        scan_id = zap.ascan.scan(url)
        
        while int(zap.ascan.status(scan_id)) < 100:
            progress = zap.ascan.status(scan_id)
            print(f"  [*] Scan progress: {progress}%", end='\r')
            time.sleep(5)
        print(f"  [✓] Active scan completed  ")
        
        return True
        
    except Exception as e:
        print(f"  [✗] Error scanning {name}: {str(e)}")
        return False

def generate_report():
    """Generate HTML report"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_dir = '/opt/security-tools/reports/zap'
    os.makedirs(report_dir, exist_ok=True)
    
    report_file = f'{report_dir}/zap_report_{timestamp}.html'
    
    print(f"\n[+] Generating report: {report_file}")
    
    html_report = zap.core.htmlreport()
    with open(report_file, 'w') as f:
        f.write(html_report)
    
    print(f"[✓] Report saved to {report_file}")
    
    # Print summary
    alerts = zap.core.alerts()
    print(f"\n╔═══════════════════════════════════╗")
    print(f"║      Scan Summary                 ║")
    print(f"╠═══════════════════════════════════╣")
    print(f"║ Total alerts: {len(alerts):<19} ║")
    
    risk_counts = {'High': 0, 'Medium': 0, 'Low': 0, 'Informational': 0}
    for alert in alerts:
        risk = alert.get('risk', 'Informational')
        risk_counts[risk] = risk_counts.get(risk, 0) + 1
    
    print(f"║ High:         {risk_counts['High']:<19} ║")
    print(f"║ Medium:       {risk_counts['Medium']:<19} ║")
    print(f"║ Low:          {risk_counts['Low']:<19} ║")
    print(f"║ Info:         {risk_counts['Informational']:<19} ║")
    print(f"╚═══════════════════════════════════╝")
    
    return report_file

def main():
    print("╔════════════════════════════════════════════════════════╗")
    print("║  OWASP ZAP Scanner for THEA Infrastructure            ║")
    print("╚════════════════════════════════════════════════════════╝")
    print(f"Timestamp: {datetime.now()}\n")
    
    # Check if ZAP is running
    try:
        version = zap.core.version
        print(f"[✓] ZAP is running (version: {version})\n")
    except Exception as e:
        print(f"[✗] Cannot connect to ZAP. Is it running?")
        print(f"    Start ZAP with: /opt/security-tools/start-zap.sh")
        sys.exit(1)
    
    # Scan all targets
    success_count = 0
    for name, url in TARGETS.items():
        if scan_target(name, url):
            success_count += 1
    
    # Generate report
    report_file = generate_report()
    
    print(f"\n[✓] THEA security scan completed!")
    print(f"    Scanned {success_count}/{len(TARGETS)} targets successfully")
    print(f"    Report: {report_file}")

if __name__ == '__main__':
    main()
PYEOF

chmod +x /opt/security-tools/zap-scan-thea.py

# Create security dashboard
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
if systemctl is-active --quiet nessusd 2>/dev/null; then
    echo "[✓] Nessus is running"
    echo "    URL: https://192.168.1.10:8834"
else
    echo "[✗] Nessus is not installed/running"
    echo "    Download from: https://www.tenable.com/downloads/nessus"
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
    "192.168.1.10:3010:Grafana"
    "192.168.1.10:9090:Prometheus"
    "192.168.1.40:80:Load Balancer"
)

for service in "${services[@]}"; do
    IFS=: read -r host port name <<< "$service"
    if timeout 2 bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null; then
        echo "[✓] $name ($host:$port)"
    else
        echo "[✗] $name ($host:$port)"
    fi
done
echo ""

# Recent scan reports
echo "=== Recent Security Reports ==="
if [ -d /opt/security-tools/reports/zap ]; then
    echo "ZAP Reports:"
    ls -lht /opt/security-tools/reports/zap/*.html 2>/dev/null | head -3 | awk '{print "  " $9 " (" $6 " " $7 " " $8 ")"}' || echo "  No reports yet"
fi
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║ Quick Commands                                               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║ Start ZAP:          /opt/security-tools/start-zap.sh        ║"
echo "║ ZAP Full Scan:      /opt/security-tools/zap-scan-thea.py    ║"
echo "║ Stop ZAP:           pkill -f 'zap.sh.*daemon'                ║"
echo "║ Nessus Web UI:      https://192.168.1.10:8834               ║"
echo "║ Grafana Dashboard:  http://192.168.1.10:3010                ║"
echo "║ Prometheus:         http://192.168.1.10:9090                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
EOF

chmod +x /opt/security-tools/security-dashboard.sh

# Add alias to bashrc
if ! grep -q "alias security-dashboard" ~/.bashrc; then
    echo "alias security-dashboard='/opt/security-tools/security-dashboard.sh'" >> ~/.bashrc
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 Installation Complete! ✓                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Next Steps:"
echo ""
echo "1. Install Nessus (manual download required):"
echo "   Visit: https://www.tenable.com/downloads/nessus"
echo "   Then: sudo dpkg -i Nessus-*.deb"
echo "   Start: sudo systemctl start nessusd"
echo "   Access: https://192.168.1.10:8834"
echo ""
echo "2. Start OWASP ZAP:"
echo "   /opt/security-tools/start-zap.sh"
echo ""
echo "3. Run security scan:"
echo "   /opt/security-tools/zap-scan-thea.py"
echo ""
echo "4. View security dashboard:"
echo "   /opt/security-tools/security-dashboard.sh"
echo "   (or use: security-dashboard after reloading shell)"
echo ""
echo "All tools installed in: /opt/security-tools/"
echo "Reports saved to: /opt/security-tools/reports/"
echo ""
