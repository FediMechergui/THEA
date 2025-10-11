#!/bin/bash

###############################################################################
# Jenkins Job Configuration Script for THEA Microservices
# This script creates Jenkins pipeline jobs for all three THEA microservices
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JENKINS_URL="http://localhost:8080"
JENKINS_HOME="/var/lib/jenkins"
JOBS_DIR="${JENKINS_HOME}/jobs"
REPO_PATH="/home/vboxuser/Downloads/THEA"

# Function to print colored messages
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

# Function to create Jenkins job config
create_job_config() {
    local job_name=$1
    local service_path=$2
    local jenkinsfile_path=$3
    local description=$4
    
    cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>${description}</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github@1.34.1">
      <projectUrl>${REPO_PATH}</projectUrl>
      <displayName></displayName>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.7.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>file://${REPO_PATH}</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>${jenkinsfile_path}</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Create Jenkins jobs
create_jenkins_jobs() {
    log_info "Creating Jenkins pipeline jobs..."
    
    # Job 1: Node.js Backend
    log_info "Creating Node.js Backend pipeline job..."
    local nodejs_job_dir="${JOBS_DIR}/THEA-NodeJS-Backend"
    sudo mkdir -p "${nodejs_job_dir}"
    create_job_config \
        "THEA-NodeJS-Backend" \
        "nodejs_backend" \
        "nodejs_backend/Jenkinsfile.local" \
        "THEA Node.js Backend Service - Express API with Prisma ORM" \
        | sudo tee "${nodejs_job_dir}/config.xml" > /dev/null
    log_success "Node.js Backend job created"
    
    # Job 2: FastAPI OCR
    log_info "Creating FastAPI OCR pipeline job..."
    local ocr_job_dir="${JOBS_DIR}/THEA-FastAPI-OCR"
    sudo mkdir -p "${ocr_job_dir}"
    create_job_config \
        "THEA-FastAPI-OCR" \
        "fastapi_ocr" \
        "fastapi_ocr/Jenkinsfile" \
        "THEA FastAPI OCR Service - Invoice processing with Tesseract OCR" \
        | sudo tee "${ocr_job_dir}/config.xml" > /dev/null
    log_success "FastAPI OCR job created"
    
    # Job 3: RAG Chatbot
    log_info "Creating RAG Chatbot pipeline job..."
    local rag_job_dir="${JOBS_DIR}/THEA-RAG-Chatbot"
    sudo mkdir -p "${rag_job_dir}"
    create_job_config \
        "THEA-RAG-Chatbot" \
        "rag_chatbot" \
        "rag_chatbot/Jenkinsfile" \
        "THEA RAG Chatbot Service - AI-powered document Q&A with LangChain and Ollama" \
        | sudo tee "${rag_job_dir}/config.xml" > /dev/null
    log_success "RAG Chatbot job created"
    
    # Set correct permissions
    log_info "Setting correct permissions..."
    sudo chown -R jenkins:jenkins "${JOBS_DIR}"
    sudo chmod -R 755 "${JOBS_DIR}"
}

# Restart Jenkins
restart_jenkins() {
    log_info "Restarting Jenkins to load new jobs..."
    sudo systemctl restart jenkins
    
    log_info "Waiting for Jenkins to start..."
    sleep 15
    
    # Wait for Jenkins to be ready
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" "${JENKINS_URL}/login" | grep -q "200"; then
            log_success "Jenkins is ready!"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""
}

# Display job URLs
display_job_info() {
    log_success "Jenkins jobs created successfully!"
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           THEA Jenkins Pipeline Jobs Created               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Access your Jenkins jobs at:"
    echo ""
    echo "1. Node.js Backend:"
    echo "   ${JENKINS_URL}/job/THEA-NodeJS-Backend/"
    echo ""
    echo "2. FastAPI OCR:"
    echo "   ${JENKINS_URL}/job/THEA-FastAPI-OCR/"
    echo ""
    echo "3. RAG Chatbot:"
    echo "   ${JENKINS_URL}/job/THEA-RAG-Chatbot/"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "To trigger builds manually:"
    echo "  - Open each job URL in a browser"
    echo "  - Click 'Build Now' in the left sidebar"
    echo ""
    echo "Jenkinsfiles location:"
    echo "  - nodejs_backend/Jenkinsfile.local"
    echo "  - fastapi_ocr/Jenkinsfile"
    echo "  - rag_chatbot/Jenkinsfile"
    echo ""
}

# Main execution
main() {
    log_info "Starting Jenkins job configuration for THEA microservices..."
    
    check_permissions
    create_jenkins_jobs
    restart_jenkins
    display_job_info
    
    log_success "All done! Your Jenkins pipelines are ready."
}

# Run main function
main
