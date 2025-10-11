#!/bin/bash

###############################################################################
# THEA Jenkins Configuration Script
# Run this after initial Jenkins setup is complete
# This script configures Jenkins for THEA CI/CD pipeline
###############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        THEA Jenkins Configuration Script                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

###############################################################################
# Install Jenkins Plugins via CLI
###############################################################################
install_jenkins_plugins() {
    log_info "Installing Jenkins plugins..."
    
    JENKINS_URL="http://localhost:8080"
    JENKINS_CLI="/var/lib/jenkins/jenkins-cli.jar"
    
    # Download Jenkins CLI
    if [ ! -f "$JENKINS_CLI" ]; then
        log_info "Downloading Jenkins CLI..."
        wget -q -O $JENKINS_CLI $JENKINS_URL/jnlpJars/jenkins-cli.jar
    fi
    
    # List of required plugins
    PLUGINS=(
        "docker-plugin"
        "docker-workflow"
        "pipeline-stage-view"
        "workflow-aggregator"
        "git"
        "github"
        "sonar"
        "ansible"
        "nodejs"
        "credentials-binding"
        "slack"
        "junit"
        "jacoco"
        "snyk-security-scanner"
        "prometheus"
        "dashboard-view"
        "build-timeout"
        "timestamper"
        "ws-cleanup"
        "ssh-agent"
        "pipeline-utility-steps"
    )
    
    log_info "Note: Install plugins manually via Jenkins UI:"
    log_info "  1. Go to: http://192.168.1.10:8080/pluginManager/available"
    log_info "  2. Install the following plugins:"
    for plugin in "${PLUGINS[@]}"; do
        echo "     - $plugin"
    done
    
    log_success "Plugin list generated"
}

###############################################################################
# Create Jenkins Pipeline Configuration
###############################################################################
create_pipeline_config() {
    log_info "Creating Jenkins pipeline configuration..."
    
    mkdir -p /opt/jenkins/pipelines
    
    # Create Jenkinsfile for Node.js Backend
    cat > /opt/jenkins/pipelines/Jenkinsfile.nodejs <<'EOF'
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = '192.168.1.10:5000'
        IMAGE_NAME = 'thea-nodejs-backend'
        SONAR_HOST_URL = 'http://192.168.1.10:9000'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/FediMechergui/THEA.git'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                dir('nodejs_backend') {
                    sh 'npm ci'
                }
            }
        }
        
        stage('Lint') {
            steps {
                dir('nodejs_backend') {
                    sh 'npm run lint || true'
                }
            }
        }
        
        stage('Test') {
            steps {
                dir('nodejs_backend') {
                    sh 'npm test'
                }
            }
            post {
                always {
                    junit 'nodejs_backend/junit.xml'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                dir('nodejs_backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            sonar-scanner \
                                -Dsonar.projectKey=thea-nodejs-backend \
                                -Dsonar.sources=src \
                                -Dsonar.tests=tests \
                                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                        '''
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                dir('nodejs_backend') {
                    sh """
                        docker build -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} .
                        docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                sh """
                    docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                """
            }
        }
        
        stage('Deploy to Dev') {
            steps {
                ansiblePlaybook(
                    playbook: '/opt/ansible/playbooks/deploy-nodejs.yml',
                    inventory: '/opt/ansible/inventory/hosts',
                    extras: "-e 'image_tag=${BUILD_NUMBER} environment=dev'"
                )
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
EOF
    
    # Create Jenkinsfile for FastAPI OCR
    cat > /opt/jenkins/pipelines/Jenkinsfile.fastapi <<'EOF'
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = '192.168.1.10:5000'
        IMAGE_NAME = 'thea-fastapi-ocr'
        SONAR_HOST_URL = 'http://192.168.1.10:9000'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/FediMechergui/THEA.git'
            }
        }
        
        stage('Setup Python') {
            steps {
                dir('fastapi_ocr') {
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install -r requirements.txt
                    '''
                }
            }
        }
        
        stage('Lint') {
            steps {
                dir('fastapi_ocr') {
                    sh '''
                        . venv/bin/activate
                        flake8 app/ --max-line-length=120 || true
                    '''
                }
            }
        }
        
        stage('Test') {
            steps {
                dir('fastapi_ocr') {
                    sh '''
                        . venv/bin/activate
                        pytest tests/ --junitxml=junit.xml --cov=app --cov-report=xml
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                dir('fastapi_ocr') {
                    sh """
                        docker build -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} .
                        docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                sh """
                    docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                """
            }
        }
        
        stage('Deploy to Dev') {
            steps {
                ansiblePlaybook(
                    playbook: '/opt/ansible/playbooks/deploy-fastapi.yml',
                    inventory: '/opt/ansible/inventory/hosts',
                    extras: "-e 'image_tag=${BUILD_NUMBER} environment=dev'"
                )
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
EOF
    
    log_success "Pipeline configurations created in /opt/jenkins/pipelines/"
}

###############################################################################
# Create Ansible Deployment Playbooks
###############################################################################
create_ansible_playbooks() {
    log_info "Creating Ansible deployment playbooks..."
    
    mkdir -p /opt/ansible/playbooks
    
    # Node.js deployment playbook
    cat > /opt/ansible/playbooks/deploy-nodejs.yml <<'EOF'
---
- name: Deploy THEA Node.js Backend
  hosts: app_servers
  become: yes
  vars:
    registry_url: "192.168.1.10:5000"
    image_name: "thea-nodejs-backend"
    container_name: "thea-backend"
    
  tasks:
    - name: Pull latest image from registry
      docker_image:
        name: "{{ registry_url }}/{{ image_name }}"
        tag: "{{ image_tag | default('latest') }}"
        source: pull
        
    - name: Stop existing container
      docker_container:
        name: "{{ container_name }}"
        state: stopped
      ignore_errors: yes
      
    - name: Remove existing container
      docker_container:
        name: "{{ container_name }}"
        state: absent
      ignore_errors: yes
      
    - name: Start new container
      docker_container:
        name: "{{ container_name }}"
        image: "{{ registry_url }}/{{ image_name }}:{{ image_tag | default('latest') }}"
        state: started
        restart_policy: always
        ports:
          - "3000:3000"
        env_file: /opt/thea/.env
        networks:
          - name: thea-network
        
    - name: Wait for application to be ready
      uri:
        url: "http://localhost:3000/health"
        status_code: 200
      register: result
      until: result.status == 200
      retries: 30
      delay: 10
EOF
    
    # FastAPI deployment playbook
    cat > /opt/ansible/playbooks/deploy-fastapi.yml <<'EOF'
---
- name: Deploy THEA FastAPI OCR
  hosts: app_servers
  become: yes
  vars:
    registry_url: "192.168.1.10:5000"
    image_name: "thea-fastapi-ocr"
    container_name: "thea-ocr"
    
  tasks:
    - name: Pull latest image
      docker_image:
        name: "{{ registry_url }}/{{ image_name }}"
        tag: "{{ image_tag | default('latest') }}"
        source: pull
        
    - name: Stop existing container
      docker_container:
        name: "{{ container_name }}"
        state: stopped
      ignore_errors: yes
      
    - name: Remove existing container
      docker_container:
        name: "{{ container_name }}"
        state: absent
      ignore_errors: yes
      
    - name: Start new container
      docker_container:
        name: "{{ container_name }}"
        image: "{{ registry_url }}/{{ image_name }}:{{ image_tag | default('latest') }}"
        state: started
        restart_policy: always
        ports:
          - "8000:8000"
        env_file: /opt/thea/.env.ocr
        networks:
          - name: thea-network
        volumes:
          - /opt/thea/uploads:/app/uploads
EOF
    
    log_success "Ansible playbooks created in /opt/ansible/playbooks/"
}

###############################################################################
# Create Jenkins Job DSL
###############################################################################
create_jenkins_jobs() {
    log_info "Creating Jenkins job configurations..."
    
    mkdir -p /opt/jenkins/jobs
    
    cat > /opt/jenkins/jobs/create-jobs.groovy <<'EOF'
// Jenkins Job DSL for THEA Pipeline Jobs

// Node.js Backend Pipeline
pipelineJob('THEA-NodeJS-Backend') {
    description('THEA Node.js Backend CI/CD Pipeline')
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/FediMechergui/THEA.git')
                        credentials('github-credentials')
                    }
                    branch('main')
                }
            }
            scriptPath('nodejs_backend/Jenkinsfile')
        }
    }
    
    triggers {
        githubPush()
    }
}

// FastAPI OCR Pipeline
pipelineJob('THEA-FastAPI-OCR') {
    description('THEA FastAPI OCR Service CI/CD Pipeline')
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/FediMechergui/THEA.git')
                        credentials('github-credentials')
                    }
                    branch('main')
                }
            }
            scriptPath('fastapi_ocr/Jenkinsfile')
        }
    }
    
    triggers {
        githubPush()
    }
}

// RAG Chatbot Pipeline
pipelineJob('THEA-RAG-Chatbot') {
    description('THEA RAG Chatbot Service CI/CD Pipeline')
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/FediMechergui/THEA.git')
                        credentials('github-credentials')
                    }
                    branch('main')
                }
            }
            scriptPath('rag_chatbot/Jenkinsfile')
        }
    }
}

// Complete Stack Deployment
pipelineJob('THEA-Deploy-Full-Stack') {
    description('Deploy complete THEA application stack')
    
    parameters {
        choiceParam('ENVIRONMENT', ['dev', 'staging', 'production'], 'Deployment environment')
        stringParam('VERSION', 'latest', 'Version to deploy')
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    stages {
                        stage('Deploy Services') {
                            parallel {
                                stage('Node.js Backend') {
                                    steps {
                                        build job: 'THEA-NodeJS-Backend'
                                    }
                                }
                                stage('FastAPI OCR') {
                                    steps {
                                        build job: 'THEA-FastAPI-OCR'
                                    }
                                }
                                stage('RAG Chatbot') {
                                    steps {
                                        build job: 'THEA-RAG-Chatbot'
                                    }
                                }
                            }
                        }
                    }
                }
            ''')
            sandbox()
        }
    }
}
EOF
    
    log_info "Job DSL created: /opt/jenkins/jobs/create-jobs.groovy"
    log_info "Import this in Jenkins: Manage Jenkins > Script Console"
}

###############################################################################
# Create SonarQube Scanner Configuration
###############################################################################
create_sonar_scanner_config() {
    log_info "Creating SonarQube Scanner configuration..."
    
    # Create sonar-scanner properties for Node.js
    cat > /opt/jenkins/sonar-scanner-nodejs.properties <<'EOF'
sonar.projectKey=thea-nodejs-backend
sonar.projectName=THEA Node.js Backend
sonar.projectVersion=1.0
sonar.sources=src
sonar.tests=tests
sonar.sourceEncoding=UTF-8
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.testExecutionReportPaths=test-report.xml
sonar.exclusions=node_modules/**,coverage/**,dist/**
EOF
    
    # Create sonar-scanner properties for FastAPI
    cat > /opt/jenkins/sonar-scanner-fastapi.properties <<'EOF'
sonar.projectKey=thea-fastapi-ocr
sonar.projectName=THEA FastAPI OCR
sonar.projectVersion=1.0
sonar.sources=app
sonar.tests=tests
sonar.sourceEncoding=UTF-8
sonar.python.coverage.reportPaths=coverage.xml
sonar.exclusions=venv/**,__pycache__/**
EOF
    
    log_success "SonarQube scanner configurations created"
}

###############################################################################
# Create Documentation
###############################################################################
create_documentation() {
    log_info "Creating Jenkins configuration documentation..."
    
    cat > /opt/jenkins/JENKINS_CONFIGURATION_GUIDE.md <<'EOF'
# THEA Jenkins Configuration Guide

## Initial Setup Checklist

### 1. Jenkins Initial Configuration
- [ ] Access Jenkins at http://192.168.1.10:8080
- [ ] Use initial admin password from: /opt/jenkins/initial-admin-password.txt
- [ ] Complete setup wizard
- [ ] Create admin user

### 2. Install Required Plugins
Navigate to: Manage Jenkins > Plugin Manager > Available

**Essential Plugins:**
- Docker Pipeline
- Docker
- SonarQube Scanner
- Ansible
- Git
- GitHub
- Pipeline
- Pipeline: Stage View
- Credentials Binding
- JUnit
- Jacoco
- Snyk Security Scanner
- Prometheus Metrics
- Slack Notification (optional)

### 3. Configure Global Tools
Navigate to: Manage Jenkins > Global Tool Configuration

**JDK:**
- Name: JDK-17
- JAVA_HOME: /usr/lib/jvm/java-17-openjdk-amd64

**Node.js:**
- Name: NodeJS-18
- Install automatically from nodejs.org
- Version: 18.19.0

**SonarQube Scanner:**
- Name: SonarScanner
- Install automatically
- Version: Latest

**Ansible:**
- Name: Ansible
- Path: /usr/bin/ansible

### 4. Configure Credentials
Navigate to: Manage Jenkins > Credentials > System > Global credentials

**Required Credentials:**

1. **Docker Registry** (Username with password)
   - ID: docker-registry
   - Username: admin
   - Password: <registry-password>
   - Description: Docker Registry Credentials

2. **GitHub** (Username with password or Token)
   - ID: github-credentials
   - Username: FediMechergui
   - Token: <github-token>
   - Description: GitHub Repository Access

3. **SonarQube** (Secret text)
   - ID: sonarqube-token
   - Secret: <sonar-token>
   - Description: SonarQube Authentication Token

4. **Ansible SSH Key** (SSH Username with private key)
   - ID: ansible-ssh-key
   - Username: ansible
   - Private Key: <ssh-private-key>
   - Description: Ansible Deployment Key

### 5. Configure SonarQube Server
Navigate to: Manage Jenkins > Configure System > SonarQube servers

- Name: SonarQube
- Server URL: http://192.168.1.10:9000
- Server authentication token: sonarqube-token (from credentials)

### 6. Configure Docker
Navigate to: Manage Jenkins > Configure System > Docker

**Docker Cloud:**
- Name: docker
- Docker Host URI: unix:///var/run/docker.sock
- Enabled: ✓

### 7. Create Pipeline Jobs

**Method 1: Using Jenkins UI**
1. New Item > Pipeline
2. Enter name: THEA-NodeJS-Backend
3. Pipeline section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: https://github.com/FediMechergui/THEA.git
   - Credentials: github-credentials
   - Branch: main
   - Script Path: nodejs_backend/Jenkinsfile

**Method 2: Using Job DSL**
1. Manage Jenkins > Script Console
2. Paste content from: /opt/jenkins/jobs/create-jobs.groovy
3. Run script

### 8. Configure Webhooks (GitHub)
In GitHub repository settings:
1. Go to Settings > Webhooks > Add webhook
2. Payload URL: http://192.168.1.10:8080/github-webhook/
3. Content type: application/json
4. Events: Just the push event
5. Active: ✓

### 9. Generate SonarQube Token
1. Login to SonarQube: http://192.168.1.10:9000
2. My Account > Security > Generate Token
3. Add token to Jenkins credentials (sonarqube-token)

### 10. Configure Ansible SSH Access
```bash
# On Jenkins server
sudo -u jenkins ssh-keygen -t rsa -b 4096 -f /var/lib/jenkins/.ssh/id_rsa -N ""

# Copy public key to app servers
ssh-copy-id -i /var/lib/jenkins/.ssh/id_rsa.pub ansible@192.168.1.50
ssh-copy-id -i /var/lib/jenkins/.ssh/id_rsa.pub ansible@192.168.1.60
```

## Testing the Pipeline

### Manual Test
1. Go to THEA-NodeJS-Backend job
2. Click "Build Now"
3. Monitor console output
4. Verify stages complete successfully

### Automatic Test (GitHub Push)
1. Make a commit to the repository
2. Push to GitHub
3. Webhook should trigger Jenkins build
4. Monitor build status

## Troubleshooting

### Docker Permission Issues
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Ansible Connection Issues
```bash
# Test Ansible connection
sudo -u jenkins ansible app_servers -m ping -i /opt/ansible/inventory/hosts
```

### SonarQube Connection Issues
```bash
# Test SonarQube API
curl http://192.168.1.10:9000/api/system/status
```

### Registry Push Issues
```bash
# Test registry access
docker pull hello-world
docker tag hello-world 192.168.1.10:5000/hello-world
docker push 192.168.1.10:5000/hello-world
```

## Monitoring

### Jenkins Logs
```bash
sudo journalctl -u jenkins -f
```

### Docker Logs
```bash
docker logs -f <container-name>
```

### Build Artifacts Location
```
/var/lib/jenkins/jobs/THEA-NodeJS-Backend/builds/<build-number>/
```

## Backup

Daily backups are scheduled at 2 AM:
```bash
# Manual backup
sudo /opt/scripts/backup-cicd.sh

# Backup location
/opt/backups/
```

## Security Best Practices

1. Change default Jenkins admin password
2. Enable CSRF protection
3. Configure Jenkins security realm
4. Use credentials plugin for secrets
5. Enable audit logging
6. Regular security updates
7. Restrict job permissions
8. Use HTTPS (configure reverse proxy)

## Performance Optimization

1. Increase Jenkins Java heap size
2. Configure build executors (2 per CPU core)
3. Use Docker for isolated builds
4. Clean old builds regularly
5. Use Jenkins workspace cleanup plugin
6. Configure build timeouts

## Useful Commands

```bash
# Jenkins service
sudo systemctl status jenkins
sudo systemctl restart jenkins

# Health check
/opt/scripts/health-check.sh

# View logs
sudo journalctl -u jenkins -f

# Jenkins CLI
java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080/ help
```
EOF
    
    log_success "Documentation created: /opt/jenkins/JENKINS_CONFIGURATION_GUIDE.md"
}

###############################################################################
# Main Execution
###############################################################################
main() {
    log_info "Starting THEA Jenkins configuration..."
    echo ""
    
    install_jenkins_plugins
    echo ""
    
    create_pipeline_config
    echo ""
    
    create_ansible_playbooks
    echo ""
    
    create_jenkins_jobs
    echo ""
    
    create_sonar_scanner_config
    echo ""
    
    create_documentation
    echo ""
    
    log_success "Jenkins configuration completed!"
    echo ""
    echo "📄 Configuration guide: /opt/jenkins/JENKINS_CONFIGURATION_GUIDE.md"
    echo "🔧 Pipeline configs: /opt/jenkins/pipelines/"
    echo "📜 Ansible playbooks: /opt/ansible/playbooks/"
    echo "🔨 Job DSL script: /opt/jenkins/jobs/create-jobs.groovy"
    echo ""
    echo "Next steps:"
    echo "  1. Complete Jenkins initial setup wizard"
    echo "  2. Install required plugins"
    echo "  3. Configure credentials"
    echo "  4. Create pipeline jobs"
    echo ""
}

main
