#!/bin/bash

###############################################################################
# Jenkins Password Reset Script
# This script resets the Jenkins admin password
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    exit 1
fi

log_info "Creating Jenkins admin user with known credentials..."

# Create a Groovy script to set up the admin user
cat > /tmp/jenkins-admin-setup.groovy << 'GROOVY_SCRIPT'
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Create security realm
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()

println "Admin user created with username: admin, password: admin123"
GROOVY_SCRIPT

# Copy the script to Jenkins home
cp /tmp/jenkins-admin-setup.groovy /var/lib/jenkins/init.groovy.d/admin-setup.groovy
chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/admin-setup.groovy
chmod 644 /var/lib/jenkins/init.groovy.d/admin-setup.groovy

log_success "Groovy script created"
log_info "Restarting Jenkins..."

systemctl restart jenkins

log_info "Waiting for Jenkins to start..."
sleep 20

# Wait for Jenkins to be ready
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/login" | grep -q "200"; then
        log_success "Jenkins is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo -n "."
    sleep 2
done
echo ""

# Clean up the groovy script
rm -f /var/lib/jenkins/init.groovy.d/admin-setup.groovy

log_success "Jenkins admin user configured!"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              JENKINS CREDENTIALS                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Jenkins URL:  http://localhost:8080"
echo "  Username:     admin"
echo "  Password:     admin123"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Save credentials to file
cat > /home/vboxuser/jenkins-credentials.txt << EOF
JENKINS CREDENTIALS
===================

URL:      http://localhost:8080
Username: admin
Password: admin123

Created:  $(date)
EOF

chown vboxuser:vboxuser /home/vboxuser/jenkins-credentials.txt
log_success "Credentials saved to: /home/vboxuser/jenkins-credentials.txt"
