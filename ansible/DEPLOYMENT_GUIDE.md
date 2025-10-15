# THEA Ansible Deployment Guide

## Overview

This Ansible deployment automates the setup of the THEA microservices architecture across multiple VMs as defined in `VirtualBox_Setup_Guide.md`.

## Architecture

```
                          ┌─────────────────────┐
                          │  thea-cicd          │
                          │  (192.168.1.10)     │
                          │  CI/CD + Registry   │
                          └─────────────────────┘
                                    │
                                    │ Ansible
                                    ▼
              ┌─────────────────────────────────────┐
              │                                     │
    ┌─────────▼─────────┐              ┌──────────▼────────┐
    │ thea-loadbalancer │              │   thea-app1       │
    │ (192.168.1.40)    │◄────────────►│   (192.168.1.50)  │
    │ Nginx LB          │   Primary    │   Docker Services │
    └───────────────────┘              └───────────────────┘
              │                                     │
              │                                     │
              │                        ┌────────────▼────────┐
              └───────────────────────►│   thea-app2         │
                         Backup        │   (192.168.1.60)    │
                                      │   Docker Services   │
                                      └─────────────────────┘
```

## Prerequisites

### 1. VMs Setup

Ensure all VMs are created and networked according to `VirtualBox_Setup_Guide.md`:

- ✅ thea-cicd (192.168.1.10) - Current VM
- ✅ thea-loadbalancer (192.168.1.40) - Load balancer
- ✅ thea-app1 (192.168.1.50) - Primary application server
- ✅ thea-app2 (192.168.1.60) - Backup application server

### 2. Docker Images in Local Registry

Ensure images are pushed to `localhost:5000`:

```bash
curl http://localhost:5000/v2/_catalog
```

Expected output:
```json
{
  "repositories": [
    "nodejs_backend_thea-backend",
    "rag_chatbot",
    "thea_fastapi-ocr",
    "thea_fastapi-ocr-worker"
  ]
}
```

### 3. Network Connectivity

Test connectivity from thea-cicd to all VMs:

```bash
ping -c 2 192.168.1.40  # thea-loadbalancer
ping -c 2 192.168.1.50  # thea-app1
ping -c 2 192.168.1.60  # thea-app2
```

## Deployment Steps

### Step 1: Set Up SSH Keys

Run the SSH key distribution script to enable passwordless SSH:

```bash
cd /home/vboxuser/Downloads/THEA/ansible
./setup-ssh-keys.sh
```

This will:
- Copy your SSH public key to all target VMs
- Test SSH connectivity
- Enable passwordless authentication

**Note:** You'll need to enter the password for each VM (default: your vboxuser password)

### Step 2: Verify Inventory

Check that Ansible can reach all hosts:

```bash
ansible all -i inventory.ini -m ping
```

Expected output:
```
thea-loadbalancer | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
thea-app1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
thea-app2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Step 3: Review Configuration

Edit `vars/development.yml` to customize settings if needed:

- Service ports
- Database credentials
- Resource limits
- Domain names

### Step 4: Run Deployment

Deploy to development environment:

```bash
ansible-playbook -i inventory.ini deploy.yml -e "env=development"
```

This will:
1. Deploy Docker containers on thea-app1 (primary)
2. Deploy Docker containers on thea-app2 (backup)
3. Configure Nginx load balancer on thea-loadbalancer
4. Set up health checks and monitoring

### Step 5: Verify Deployment

Check service status through the load balancer:

```bash
# Health check
curl http://192.168.1.40/health

# Node.js Backend
curl http://192.168.1.40:3000/health

# FastAPI OCR
curl http://192.168.1.40:8000/health

# RAG Chatbot
curl http://192.168.1.40:8001/health
```

## Accessing Services

All services are accessible through the load balancer (192.168.1.40):

### Main Services
- **Node.js Backend API:** http://192.168.1.40:3000
- **FastAPI OCR Service:** http://192.168.1.40:8000
- **RAG Chatbot:** http://192.168.1.40:8001

### Monitoring & Management
- **Grafana Dashboards:** http://192.168.1.40:3010
  - Username: `admin`
  - Password: `admin` (change on first login)
- **Prometheus Metrics:** http://192.168.1.40:9090

### Direct Access to App Servers

If needed, you can access services directly:

**thea-app1 (Primary):**
- Node.js: http://192.168.1.50:3000
- OCR: http://192.168.1.50:8000
- Chatbot: http://192.168.1.50:8001
- RabbitMQ: http://192.168.1.50:15672
- MinIO: http://192.168.1.50:9000

**thea-app2 (Backup):**
- Node.js: http://192.168.1.60:3000
- OCR: http://192.168.1.60:8000
- Chatbot: http://192.168.1.60:8001
- RabbitMQ: http://192.168.1.60:15672
- MinIO: http://192.168.1.60:9000

## Load Balancer Configuration

The Nginx load balancer is configured with:

- **Load Balancing Algorithm:** Least Connections
- **Health Checks:** Automatic
- **Failover:** Automatic to backup server (thea-app2)
- **Session Affinity:** None (stateless design)

## Ansible Playbook Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.ini            # VM inventory
├── deploy.yml               # Main deployment playbook
├── setup-ssh-keys.sh        # SSH key distribution script
├── vars/
│   ├── development.yml      # Dev environment vars
│   ├── production.yml       # Prod environment vars
│   └── secrets.yml          # Sensitive data (encrypt with ansible-vault)
└── roles/
    ├── common/              # Common setup tasks
    │   ├── tasks/
    │   ├── templates/
    │   └── handlers/
    ├── docker/              # Docker deployment
    │   ├── tasks/
    │   └── templates/
    └── nginx/               # Nginx load balancer
        ├── tasks/
        ├── templates/
        └── handlers/
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connectivity manually
ssh -i ~/.ssh/thea-ansible-key vboxuser@192.168.1.40

# Check SSH key permissions
chmod 600 ~/.ssh/thea-ansible-key
chmod 644 ~/.ssh/thea-ansible-key.pub
```

### Docker Images Not Found

Ensure the Docker registry is accessible from app servers:

```bash
# On thea-app1 or thea-app2
curl http://192.168.1.10:5000/v2/_catalog
```

If not accessible, check network configuration and firewall rules.

### Service Health Check Failures

Check Docker container logs:

```bash
# SSH to app server
ssh thea-app1

# Check running containers
docker ps

# View logs
docker logs <container-name>
```

### Load Balancer Not Responding

Check Nginx status:

```bash
# SSH to load balancer
ssh thea-loadbalancer

# Check Nginx container
cd /opt/nginx
docker compose logs nginx

# Test Nginx configuration
docker compose exec nginx nginx -t
```

## Updating Deployment

To update services after code changes:

1. Build new Docker images on thea-cicd
2. Push to local registry
3. Re-run deployment:

```bash
ansible-playbook -i inventory.ini deploy.yml -e "env=development" --tags "docker"
```

## Rolling Back

To rollback to a previous version:

1. Tag previous images in registry
2. Update docker-compose template to use specific tags
3. Redeploy

## Security Considerations

- 🔒 SSH keys are used for authentication (no passwords)
- 🔒 Secrets should be encrypted using `ansible-vault`
- 🔒 Firewall rules limit access between VMs
- 🔒 Services communicate on internal network (192.168.1.0/24)

## Next Steps

1. ✅ Complete SSH key setup
2. ✅ Run deployment
3. ⏳ Configure monitoring alerts
4. ⏳ Set up automated backups
5. ⏳ Implement CI/CD integration
6. ⏳ Configure SSL/TLS certificates

## Support

For issues or questions, refer to:
- `VirtualBox_Setup_Guide.md` - Infrastructure setup
- `README.md` - Project overview
- `JENKINS_PIPELINES_SETUP.md` - CI/CD configuration
