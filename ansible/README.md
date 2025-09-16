# THEA Backend - Ansible Deployment

This directory contains the complete Ansible automation for deploying THEA Backend microservices to production, staging, and development environments.

## 📋 Prerequisites

### System Requirements
- **Ansible**: 2.10+
- **Python**: 3.8+
- **SSH access** to target servers
- **sudo privileges** on target servers

### Target Server Requirements
- **Ubuntu 20.04+** or **CentOS 7+**
- **4GB RAM minimum** (8GB recommended)
- **2 CPU cores minimum** (4 cores recommended)
- **50GB disk space** minimum
- **Docker** and **docker-compose** support

## 🚀 Quick Start

### 1. Install Ansible
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# CentOS/RHEL
sudo yum install ansible

# macOS
brew install ansible

# Or using pip
pip install ansible
```

### 2. Configure SSH Access
```bash
# Generate SSH key pair (if not already done)
ssh-keygen -t ed25519 -C "thea-deployment"

# Copy public key to target servers
ssh-copy-id ubuntu@your-server-ip

# Test SSH connection
ssh ubuntu@your-server-ip
```

### 3. Configure Inventory
Edit `inventory.ini` with your server details:
```ini
[production]
prod-server-1 ansible_host=your-prod-server-ip ansible_user=ubuntu

[staging]
staging-server-1 ansible_host=your-staging-server-ip ansible_user=ubuntu
```

### 4. Configure Secrets
```bash
# Encrypt the secrets file
ansible-vault encrypt vars/secrets.yml

# Edit encrypted secrets
ansible-vault edit vars/secrets.yml
```

### 5. Deploy
```bash
# Deploy to production
ansible-playbook -i inventory.ini deploy.yml --limit production

# Deploy to staging
ansible-playbook -i inventory.ini deploy.yml --limit staging

# Deploy to development
ansible-playbook -i inventory.ini deploy.yml --limit development
```

## 📁 Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.ini            # Server inventory
├── deploy.yml              # Main deployment playbook
├── vars/                   # Variables directory
│   ├── production.yml      # Production environment variables
│   ├── staging.yml         # Staging environment variables
│   ├── development.yml     # Development environment variables
│   └── secrets.yml         # Encrypted secrets (Ansible Vault)
├── roles/                  # Ansible roles
│   ├── common/             # Common server setup
│   │   ├── tasks/
│   │   ├── handlers/
│   │   └── templates/
│   ├── docker/             # Docker deployment
│   │   ├── tasks/
│   │   └── templates/
│   ├── nodejs_backend/     # Node.js backend specific tasks
│   ├── fastapi_ocr/        # FastAPI OCR specific tasks
│   ├── rag_chatbot/        # RAG Chatbot specific tasks
│   ├── monitoring/         # Monitoring setup
│   ├── security/           # Security hardening
│   └── backup/             # Backup configuration
└── README.md               # This file
```

## 🎯 Deployment Environments

### Production Environment
- **Security**: Maximum security hardening
- **Monitoring**: Full monitoring stack
- **Backups**: Automated daily backups
- **SSL**: HTTPS enabled
- **Ports**: Standard production ports

### Staging Environment
- **Security**: Moderate security
- **Monitoring**: Full monitoring stack
- **Backups**: Automated backups
- **SSL**: Optional HTTPS
- **Ports**: Non-standard ports to avoid conflicts

### Development Environment
- **Security**: Minimal security for development
- **Monitoring**: Basic monitoring
- **Backups**: Manual backups only
- **SSL**: Disabled
- **Ports**: Standard development ports

## 🔧 Configuration

### Environment Variables
All configuration is managed through environment-specific variable files:

- `vars/production.yml` - Production configuration
- `vars/staging.yml` - Staging configuration
- `vars/development.yml` - Development configuration

### Secrets Management
Sensitive data is stored in an encrypted Ansible Vault file:

- `vars/secrets.yml` - Encrypted secrets file

### Service Configuration
Each service has its own environment file template:

- `roles/docker/templates/nodejs_backend/.env.docker.j2`
- `roles/docker/templates/fastapi_ocr/.env.docker.j2`
- `roles/docker/templates/rag_chatbot/.env.docker.j2`

## 📊 Monitoring & Observability

### Grafana Dashboards
- **URL**: `http://your-server:3010`
- **Credentials**: Configured in secrets
- **Dashboards**: System metrics, application metrics, Docker metrics

### Prometheus Metrics
- **URL**: `http://your-server:9090`
- **Metrics**: All services expose Prometheus metrics
- **Alerting**: Configurable alerting rules

### Service Health Checks
- **Node.js Backend**: `http://your-server:3000/health`
- **FastAPI OCR**: `http://your-server:8000/health`
- **RAG Chatbot**: `http://your-server:8001/health`

## 🔒 Security Features

### Server Hardening
- **Firewall**: UFW configured with minimal open ports
- **SSH**: Key-based authentication only
- **Updates**: Automatic security updates
- **Monitoring**: Intrusion detection

### Application Security
- **SSL/TLS**: HTTPS encryption
- **Secrets**: Encrypted storage
- **Access Control**: JWT authentication
- **Rate Limiting**: DDoS protection

### Docker Security
- **Non-root containers**: Services run as non-root users
- **Secrets**: Docker secrets for sensitive data
- **Network isolation**: Custom Docker networks
- **Resource limits**: CPU and memory limits

## 🔄 Maintenance Tasks

### Updating Services
```bash
# Update all services
ansible-playbook -i inventory.ini deploy.yml --tags update

# Update specific service
ansible-playbook -i inventory.ini deploy.yml --tags nodejs_backend
```

### Backup Operations
```bash
# Create manual backup
ansible-playbook -i inventory.ini deploy.yml --tags backup

# Restore from backup
ansible-playbook -i inventory.ini deploy.yml --tags restore
```

### Monitoring
```bash
# Check service status
ansible-playbook -i inventory.ini deploy.yml --tags status

# View logs
ansible-playbook -i inventory.ini deploy.yml --tags logs
```

## 🚨 Troubleshooting

### Common Issues

#### SSH Connection Failed
```bash
# Test SSH connection
ssh -i ~/.ssh/thea-deploy-key ubuntu@your-server

# Check SSH service
ansible -i inventory.ini production -m service -a "name=ssh state=started"
```

#### Docker Deployment Failed
```bash
# Check Docker service
ansible -i inventory.ini production -m service -a "name=docker state=started"

# Check disk space
ansible -i inventory.ini production -m shell -a "df -h"
```

#### Service Not Starting
```bash
# Check service logs
ansible -i inventory.ini production -m shell -a "docker-compose -f /opt/thea/docker-compose.yml logs"

# Check service health
ansible -i inventory.ini production -m uri -a "url=http://localhost:3000/health"
```

### Log Locations
- **Ansible logs**: `/var/log/ansible.log`
- **Application logs**: `/opt/thea/logs/`
- **Docker logs**: `docker-compose logs`
- **System logs**: `/var/log/syslog`

## 📞 Support

### Documentation
- [THEA Backend API Docs](./../README.md)
- [Docker Compose Setup](./../docker-compose.yml)
- [Testing Report](./../THEA_TESTING_REPORT.md)

### Getting Help
1. Check the logs: `ansible-playbook -i inventory.ini deploy.yml -v`
2. Review the testing report for known issues
3. Check service health endpoints
4. Review Grafana dashboards for metrics

## 🔄 Version History

- **v1.0.0**: Initial Ansible deployment setup
- Complete microservices deployment automation
- Multi-environment support (dev/staging/prod)
- Security hardening and monitoring
- Backup and recovery procedures

---

**Deployment Guide Version**: 1.0.0
**Last Updated**: September 16, 2025
**THEA Backend Version**: Latest