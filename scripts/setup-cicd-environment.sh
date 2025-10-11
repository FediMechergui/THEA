#!/bin/bash

###############################################################################
# THEA CI/CD Environment Setup Script
# VM: thea-cicd (192.168.1.10)
# Components: Docker, Jenkins, SonarQube, Ansible, Docker Registry
# Version: 1.0.0
# Date: October 3, 2025
###############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║        THEA CI/CD Environment Setup Script               ║"
    echo "║        Version 1.0.0 - October 2025                      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# System information
print_system_info() {
    log_info "System Information:"
    echo "  Hostname: $(hostname)"
    echo "  OS: $(lsb_release -ds)"
    echo "  Kernel: $(uname -r)"
    echo "  CPU Cores: $(nproc)"
    echo "  RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo "  Disk Space: $(df -h / | tail -1 | awk '{print $4}') available"
    echo ""
}

###############################################################################
# STEP 1: System Preparation
###############################################################################
prepare_system() {
    log_info "Step 1: Preparing system..."
    
    # Update system
    log_info "Updating package repositories..."
    apt update -qq
    
    log_info "Upgrading packages..."
    apt upgrade -y -qq
    
    # Install essential packages
    log_info "Installing essential packages..."
    apt install -y \
        curl \
        wget \
        git \
        vim \
        nano \
        htop \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        jq \
        net-tools \
        ufw
    
    # Configure timezone
    log_info "Setting timezone to UTC..."
    timedatectl set-timezone UTC
    
    # Configure system limits
    log_info "Configuring system limits..."
    cat >> /etc/security/limits.conf <<EOF

# Jenkins and Docker limits
jenkins soft nofile 65536
jenkins hard nofile 65536
jenkins soft nproc 32768
jenkins hard nproc 32768
* soft nofile 65536
* hard nofile 65536
EOF
    
    # Configure kernel parameters
    log_info "Configuring kernel parameters..."
    cat >> /etc/sysctl.conf <<EOF

# THEA CI/CD optimizations
vm.max_map_count=262144
fs.file-max=2097152
net.core.somaxconn=65535
net.ipv4.ip_forward=1
EOF
    sysctl -p > /dev/null 2>&1
    
    # Create directory structure
    log_info "Creating directory structure..."
    mkdir -p /opt/{jenkins,docker-registry,sonarqube,scripts,backups}
    mkdir -p /var/lib/jenkins/{workspace,jobs,logs}
    mkdir -p /opt/thea/{logs,uploads,backups,docker-data}
    
    log_success "System preparation completed"
}

###############################################################################
# STEP 2: Install Docker
###############################################################################
install_docker() {
    log_info "Step 2: Installing Docker Engine..."
    
    # Remove old Docker versions
    log_info "Removing old Docker versions..."
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    log_info "Adding Docker GPG key..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    log_info "Adding Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    log_info "Installing Docker Engine..."
    apt update -qq
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        log_info "Added $SUDO_USER to docker group"
    fi
    
    # Configure Docker daemon
    log_info "Configuring Docker daemon..."
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "insecure-registries": ["192.168.1.10:5000"],
  "registry-mirrors": [],
  "live-restore": true,
  "userland-proxy": false,
  "default-address-pools": [
    {
      "base": "172.80.0.0/16",
      "size": 24
    }
  ]
}
EOF
    
    systemctl restart docker
    
    # Verify installation
    docker --version
    docker compose version
    
    log_success "Docker installation completed"
}

###############################################################################
# STEP 3: Set Up Docker Registry
###############################################################################
setup_docker_registry() {
    log_info "Step 3: Setting up Docker Registry..."
    
    # Create registry directories
    mkdir -p /opt/docker-registry/{data,certs,auth}
    
    # Create docker-compose file for registry
    cat > /opt/docker-registry/docker-compose.yml <<EOF
version: '3.8'

services:
  registry:
    image: registry:2
    container_name: docker-registry
    restart: always
    ports:
      - "5000:5000"
    environment:
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
      REGISTRY_STORAGE_DELETE_ENABLED: "true"
    volumes:
      - /opt/docker-registry/data:/data
    networks:
      - thea-network

  registry-ui:
    image: joxit/docker-registry-ui:latest
    container_name: registry-ui
    restart: always
    ports:
      - "5001:80"
    environment:
      REGISTRY_TITLE: "THEA Docker Registry"
      REGISTRY_URL: "http://registry:5000"
      DELETE_IMAGES: "true"
      SHOW_CONTENT_DIGEST: "true"
      NGINX_PROXY_PASS_URL: "http://registry:5000"
      SINGLE_REGISTRY: "true"
    depends_on:
      - registry
    networks:
      - thea-network

networks:
  thea-network:
    driver: bridge
EOF
    
    # Start registry
    log_info "Starting Docker Registry..."
    cd /opt/docker-registry
    docker compose up -d
    
    # Wait for registry to be ready
    sleep 10
    
    # Test registry
    if curl -s http://localhost:5000/v2/_catalog > /dev/null; then
        log_success "Docker Registry is running on port 5000"
        log_info "Registry UI available at: http://192.168.1.10:5001"
    else
        log_error "Docker Registry failed to start"
        return 1
    fi
}

###############################################################################
# STEP 4: Install Java (for Jenkins and SonarQube)
###############################################################################
install_java() {
    log_info "Step 4: Installing Java..."
    
    # Install OpenJDK 17
    log_info "Installing OpenJDK 17..."
    apt install -y openjdk-17-jdk
    
    # Set JAVA_HOME
    echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/environment
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/environment
    
    # Verify installation
    java -version
    
    log_success "Java installation completed"
}

###############################################################################
# STEP 5: Install Jenkins
###############################################################################
install_jenkins() {
    log_info "Step 5: Installing Jenkins..."
    
    # Add Jenkins repository key
    log_info "Adding Jenkins repository..."
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    # Install Jenkins
    log_info "Installing Jenkins..."
    apt update -qq
    apt install -y jenkins
    
    # Start and enable Jenkins
    systemctl start jenkins
    systemctl enable jenkins
    
    # Wait for Jenkins to start
    log_info "Waiting for Jenkins to start..."
    sleep 30
    
    # Get initial admin password
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
        log_success "Jenkins installation completed"
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║              JENKINS INITIAL ADMIN PASSWORD               ║"
        echo "╠═══════════════════════════════════════════════════════════╣"
        echo "║ Password: ${JENKINS_PASSWORD}                                       ║"
        echo "║ URL: http://192.168.1.10:8080                            ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        echo ""
        echo "$JENKINS_PASSWORD" > /opt/jenkins/initial-admin-password.txt
    else
        log_warning "Could not retrieve Jenkins initial password"
    fi
}

###############################################################################
# STEP 6: Set Up SonarQube with PostgreSQL
###############################################################################
setup_sonarqube() {
    log_info "Step 6: Setting up SonarQube..."
    
    # Create SonarQube directories
    mkdir -p /opt/sonarqube/{data,extensions,logs,postgresql,postgresql-data}
    
    # Create docker-compose file for SonarQube
    cat > /opt/sonarqube/docker-compose.yml <<EOF
version: '3.8'

services:
  postgresql:
    image: postgres:13-alpine
    container_name: sonarqube-postgres
    restart: always
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar123
      POSTGRES_DB: sonarqube
    volumes:
      - /opt/sonarqube/postgresql-data:/var/lib/postgresql/data
    networks:
      - sonarqube-network

  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    restart: always
    depends_on:
      - postgresql
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://postgresql:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar123
    volumes:
      - /opt/sonarqube/data:/opt/sonarqube/data
      - /opt/sonarqube/extensions:/opt/sonarqube/extensions
      - /opt/sonarqube/logs:/opt/sonarqube/logs
    networks:
      - sonarqube-network

networks:
  sonarqube-network:
    driver: bridge
EOF
    
    # Set proper permissions
    chown -R 999:999 /opt/sonarqube/data /opt/sonarqube/extensions /opt/sonarqube/logs
    
    # Start SonarQube
    log_info "Starting SonarQube (this may take a few minutes)..."
    cd /opt/sonarqube
    docker compose up -d
    
    log_info "Waiting for SonarQube to initialize..."
    sleep 60
    
    log_success "SonarQube setup completed"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                   SONARQUBE ACCESS INFO                   ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║ URL: http://192.168.1.10:9000                            ║"
    echo "║ Default Username: admin                                   ║"
    echo "║ Default Password: admin                                   ║"
    echo "║ (You will be prompted to change on first login)          ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
}

###############################################################################
# STEP 7: Install Ansible
###############################################################################
install_ansible() {
    log_info "Step 7: Installing Ansible..."
    
    # Add Ansible repository
    log_info "Adding Ansible PPA..."
    add-apt-repository -y ppa:ansible/ansible
    apt update -qq
    
    # Install Ansible
    log_info "Installing Ansible and dependencies..."
    apt install -y ansible sshpass
    
    # Create Ansible directory structure
    mkdir -p /etc/ansible
    mkdir -p /opt/ansible/{inventory,playbooks,roles,scripts}
    
    # Create Ansible configuration
    cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
inventory = /opt/ansible/inventory/hosts
host_key_checking = False
remote_user = ansible
private_key_file = /opt/ansible/ssh/id_rsa
retry_files_enabled = False
log_path = /opt/ansible/logs/ansible.log
interpreter_python = auto_silent

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
    
    # Create inventory file
    cat > /opt/ansible/inventory/hosts <<EOF
# THEA Infrastructure Inventory

[cicd]
thea-cicd ansible_host=192.168.1.10

[monitoring]
thea-monitor ansible_host=192.168.1.20

[security]
thea-security ansible_host=192.168.1.30

[loadbalancer]
thea-loadbalancer ansible_host=192.168.1.40

[app_servers]
thea-app1 ansible_host=192.168.1.50
thea-app2 ansible_host=192.168.1.60

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
    
    # Create SSH directory for Ansible
    mkdir -p /opt/ansible/ssh
    mkdir -p /opt/ansible/logs
    
    # Verify installation
    ansible --version
    
    log_success "Ansible installation completed"
    log_info "Ansible inventory: /opt/ansible/inventory/hosts"
    log_info "Ansible config: /etc/ansible/ansible.cfg"
}

###############################################################################
# STEP 8: Configure Firewall
###############################################################################
configure_firewall() {
    log_info "Step 8: Configuring firewall..."
    
    # Reset UFW to default
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow 22/tcp comment 'SSH'
    
    # Allow Jenkins
    ufw allow 8080/tcp comment 'Jenkins'
    ufw allow 50000/tcp comment 'Jenkins Agent'
    
    # Allow Docker Registry
    ufw allow 5000/tcp comment 'Docker Registry'
    ufw allow 5001/tcp comment 'Registry UI'
    
    # Allow SonarQube
    ufw allow 9000/tcp comment 'SonarQube'
    
    # Allow from internal networks
    ufw allow from 192.168.1.0/24 comment 'Internal App Network'
    ufw allow from 10.0.2.0/24 comment 'Internal Mgmt Network'
    
    # Enable firewall
    ufw --force enable
    
    log_success "Firewall configured"
    ufw status verbose
}

###############################################################################
# STEP 9: Install Additional Tools
###############################################################################
install_additional_tools() {
    log_info "Step 9: Installing additional tools..."
    
    # Install Node.js (for Node.js backend builds)
    log_info "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    node --version
    npm --version
    
    # Install Python 3 and pip (for FastAPI builds)
    log_info "Installing Python 3 and pip..."
    apt install -y python3 python3-pip python3-venv
    python3 --version
    pip3 --version
    
    # Install Git LFS
    log_info "Installing Git LFS..."
    apt install -y git-lfs
    git lfs install
    
    # Install build-essential
    log_info "Installing build tools..."
    apt install -y build-essential
    
    log_success "Additional tools installed"
}

###############################################################################
# STEP 10: Create Helper Scripts
###############################################################################
create_helper_scripts() {
    log_info "Step 10: Creating helper scripts..."
    
    # Docker Registry Helper
    cat > /opt/scripts/docker-registry-helper.sh <<'EOF'
#!/bin/bash
# Docker Registry Helper Script

REGISTRY="192.168.1.10:5000"

case "$1" in
    list)
        echo "Images in registry:"
        curl -s http://$REGISTRY/v2/_catalog | jq -r '.repositories[]'
        ;;
    tags)
        if [ -z "$2" ]; then
            echo "Usage: $0 tags <image-name>"
            exit 1
        fi
        echo "Tags for $2:"
        curl -s http://$REGISTRY/v2/$2/tags/list | jq -r '.tags[]'
        ;;
    delete)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 delete <image-name> <tag>"
            exit 1
        fi
        DIGEST=$(curl -sI -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            http://$REGISTRY/v2/$2/manifests/$3 | grep Docker-Content-Digest | awk '{print $2}' | tr -d '\r')
        curl -X DELETE http://$REGISTRY/v2/$2/manifests/$DIGEST
        echo "Deleted $2:$3"
        ;;
    *)
        echo "Docker Registry Helper"
        echo "Usage: $0 {list|tags|delete}"
        echo "  list              - List all images"
        echo "  tags <image>      - List tags for an image"
        echo "  delete <img> <tag> - Delete an image tag"
        ;;
esac
EOF
    chmod +x /opt/scripts/docker-registry-helper.sh
    
    # Jenkins Helper
    cat > /opt/scripts/jenkins-helper.sh <<'EOF'
#!/bin/bash
# Jenkins Helper Script

JENKINS_URL="http://localhost:8080"

case "$1" in
    status)
        systemctl status jenkins
        ;;
    logs)
        journalctl -u jenkins -f
        ;;
    restart)
        sudo systemctl restart jenkins
        echo "Jenkins restarted"
        ;;
    password)
        if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
            cat /var/lib/jenkins/secrets/initialAdminPassword
        else
            echo "Initial password file not found"
        fi
        ;;
    *)
        echo "Jenkins Helper"
        echo "Usage: $0 {status|logs|restart|password}"
        ;;
esac
EOF
    chmod +x /opt/scripts/jenkins-helper.sh
    
    # SonarQube Helper
    cat > /opt/scripts/sonarqube-helper.sh <<'EOF'
#!/bin/bash
# SonarQube Helper Script

cd /opt/sonarqube

case "$1" in
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f sonarqube
        ;;
    restart)
        docker compose restart sonarqube
        echo "SonarQube restarted"
        ;;
    stop)
        docker compose stop
        ;;
    start)
        docker compose up -d
        ;;
    *)
        echo "SonarQube Helper"
        echo "Usage: $0 {status|logs|restart|stop|start}"
        ;;
esac
EOF
    chmod +x /opt/scripts/sonarqube-helper.sh
    
    # System Health Check
    cat > /opt/scripts/health-check.sh <<'EOF'
#!/bin/bash
# THEA CI/CD Health Check Script

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         THEA CI/CD Environment Health Check              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Docker
echo "🐳 Docker:"
if systemctl is-active --quiet docker; then
    echo "  ✅ Docker is running"
    docker --version
else
    echo "  ❌ Docker is not running"
fi
echo ""

# Docker Registry
echo "📦 Docker Registry:"
if curl -s http://localhost:5000/v2/_catalog > /dev/null 2>&1; then
    echo "  ✅ Registry is accessible on port 5000"
    echo "  Images: $(curl -s http://localhost:5000/v2/_catalog | jq -r '.repositories | length')"
else
    echo "  ❌ Registry is not accessible"
fi
echo ""

# Jenkins
echo "🔧 Jenkins:"
if systemctl is-active --quiet jenkins; then
    echo "  ✅ Jenkins is running"
    echo "  URL: http://192.168.1.10:8080"
else
    echo "  ❌ Jenkins is not running"
fi
echo ""

# SonarQube
echo "📊 SonarQube:"
if curl -s http://localhost:9000/api/system/status | grep -q "UP"; then
    echo "  ✅ SonarQube is running"
    echo "  URL: http://192.168.1.10:9000"
else
    echo "  ❌ SonarQube is not running"
fi
echo ""

# Ansible
echo "📜 Ansible:"
if command -v ansible &> /dev/null; then
    echo "  ✅ Ansible is installed"
    ansible --version | head -n 1
else
    echo "  ❌ Ansible is not installed"
fi
echo ""

# Disk Space
echo "💾 Disk Space:"
df -h / | tail -1 | awk '{print "  Available: " $4 " (" $5 " used)"}'
echo ""

# Memory
echo "🧠 Memory:"
free -h | grep Mem | awk '{print "  Available: " $7 " / " $2}'
echo ""

echo "Health check completed at $(date)"
EOF
    chmod +x /opt/scripts/health-check.sh
    
    # Add scripts to PATH
    echo 'export PATH=$PATH:/opt/scripts' >> /etc/profile
    
    log_success "Helper scripts created in /opt/scripts/"
}

###############################################################################
# STEP 11: Create Backup Script
###############################################################################
create_backup_script() {
    log_info "Step 11: Creating backup script..."
    
    cat > /opt/scripts/backup-cicd.sh <<'EOF'
#!/bin/bash
# THEA CI/CD Backup Script

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="thea-cicd-backup-$DATE.tar.gz"

echo "Starting backup at $(date)"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup Jenkins
echo "Backing up Jenkins..."
tar -czf $BACKUP_DIR/jenkins-$DATE.tar.gz -C /var/lib jenkins/

# Backup Docker Registry
echo "Backing up Docker Registry..."
tar -czf $BACKUP_DIR/registry-$DATE.tar.gz -C /opt/docker-registry data/

# Backup SonarQube
echo "Backing up SonarQube..."
tar -czf $BACKUP_DIR/sonarqube-$DATE.tar.gz -C /opt/sonarqube data/ postgresql-data/

# Backup Ansible
echo "Backing up Ansible..."
tar -czf $BACKUP_DIR/ansible-$DATE.tar.gz -C /opt ansible/

# Backup scripts
echo "Backing up scripts..."
tar -czf $BACKUP_DIR/scripts-$DATE.tar.gz -C /opt scripts/

# Create combined backup
echo "Creating combined backup..."
cd $BACKUP_DIR
tar -czf $BACKUP_FILE jenkins-$DATE.tar.gz registry-$DATE.tar.gz sonarqube-$DATE.tar.gz ansible-$DATE.tar.gz scripts-$DATE.tar.gz

# Cleanup individual backups
rm -f jenkins-$DATE.tar.gz registry-$DATE.tar.gz sonarqube-$DATE.tar.gz ansible-$DATE.tar.gz scripts-$DATE.tar.gz

# Keep only last 7 backups
ls -t $BACKUP_DIR/thea-cicd-backup-*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup completed: $BACKUP_FILE"
echo "Backup size: $(du -h $BACKUP_DIR/$BACKUP_FILE | cut -f1)"
EOF
    chmod +x /opt/scripts/backup-cicd.sh
    
    # Add to crontab for daily backups at 2 AM
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/scripts/backup-cicd.sh >> /opt/backups/backup.log 2>&1") | crontab -
    
    log_success "Backup script created and scheduled"
}

###############################################################################
# STEP 12: Generate Configuration Summary
###############################################################################
generate_summary() {
    log_info "Step 12: Generating configuration summary..."
    
    SUMMARY_FILE="/opt/thea/SETUP_SUMMARY.txt"
    
    cat > $SUMMARY_FILE <<EOF
═══════════════════════════════════════════════════════════════
    THEA CI/CD Environment Setup Summary
    Generated: $(date)
    Hostname: $(hostname)
    IP Address: 192.168.1.10
═══════════════════════════════════════════════════════════════

🐳 DOCKER
  Status: $(systemctl is-active docker)
  Version: $(docker --version)
  Compose: $(docker compose version)
  Registry: http://192.168.1.10:5000
  Registry UI: http://192.168.1.10:5001

🔧 JENKINS
  Status: $(systemctl is-active jenkins)
  URL: http://192.168.1.10:8080
  Home: /var/lib/jenkins
  Initial Password: $(cat /opt/jenkins/initial-admin-password.txt 2>/dev/null || echo "Not found")
  
📊 SONARQUBE
  URL: http://192.168.1.10:9000
  Default Login: admin / admin (change on first login)
  Database: PostgreSQL (containerized)
  Data Directory: /opt/sonarqube/data

📜 ANSIBLE
  Version: $(ansible --version | head -n 1)
  Config: /etc/ansible/ansible.cfg
  Inventory: /opt/ansible/inventory/hosts
  Playbooks: /opt/ansible/playbooks

🛠️ ADDITIONAL TOOLS
  Java: $(java -version 2>&1 | head -n 1)
  Node.js: $(node --version)
  NPM: $(npm --version)
  Python: $(python3 --version)
  Git: $(git --version)

📁 IMPORTANT DIRECTORIES
  Jenkins: /var/lib/jenkins
  Docker Registry: /opt/docker-registry
  SonarQube: /opt/sonarqube
  Ansible: /opt/ansible
  Scripts: /opt/scripts
  Backups: /opt/backups

🔥 FIREWALL RULES
$(ufw status verbose | grep -E '(To|From)')

🚀 HELPER SCRIPTS
  Health Check: /opt/scripts/health-check.sh
  Docker Registry: /opt/scripts/docker-registry-helper.sh
  Jenkins: /opt/scripts/jenkins-helper.sh
  SonarQube: /opt/scripts/sonarqube-helper.sh
  Backup: /opt/scripts/backup-cicd.sh

📝 NEXT STEPS
  1. Access Jenkins at http://192.168.1.10:8080
  2. Complete Jenkins setup wizard
  3. Install recommended plugins:
     - Docker Pipeline
     - SonarQube Scanner
     - Ansible
     - Git
     - Pipeline
  4. Configure Jenkins credentials for Docker, Git, and SonarQube
  5. Access SonarQube at http://192.168.1.10:9000 and change password
  6. Generate SonarQube token for Jenkins integration
  7. Configure Ansible SSH keys for deployment targets
  8. Set up Jenkins pipeline using Jenkinsfile from repository

═══════════════════════════════════════════════════════════════
EOF
    
    log_success "Summary generated: $SUMMARY_FILE"
}

###############################################################################
# MAIN EXECUTION
###############################################################################
main() {
    print_banner
    check_root
    print_system_info
    
    log_info "Starting THEA CI/CD Environment Setup..."
    echo ""
    
    # Execute all steps
    prepare_system
    echo ""
    
    install_docker
    echo ""
    
    setup_docker_registry
    echo ""
    
    install_java
    echo ""
    
    install_jenkins
    echo ""
    
    setup_sonarqube
    echo ""
    
    install_ansible
    echo ""
    
    configure_firewall
    echo ""
    
    install_additional_tools
    echo ""
    
    create_helper_scripts
    echo ""
    
    create_backup_script
    echo ""
    
    generate_summary
    echo ""
    
    # Final health check
    /opt/scripts/health-check.sh
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  SETUP COMPLETED!                         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📄 Full summary available at: /opt/thea/SETUP_SUMMARY.txt${NC}"
    echo ""
    echo -e "${BLUE}Important URLs:${NC}"
    echo "  Jenkins:        http://192.168.1.10:8080"
    echo "  SonarQube:      http://192.168.1.10:9000"
    echo "  Docker Registry: http://192.168.1.10:5000"
    echo "  Registry UI:    http://192.168.1.10:5001"
    echo ""
    echo -e "${YELLOW}⚠️  Please reboot the system for all changes to take effect.${NC}"
    echo -e "${YELLOW}   Run: sudo reboot${NC}"
    echo ""
}

# Run main function
main
EOF
