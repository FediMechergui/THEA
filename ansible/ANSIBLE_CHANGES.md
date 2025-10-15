# THEA Ansible Configuration - Changes Summary

## Date: October 12, 2025

## Overview
Updated the Ansible deployment configuration to support multi-VM architecture as defined in VirtualBox_Setup_Guide.md. The deployment now properly distributes services across load balancer and application servers.

## Key Changes

### 1. Inventory Configuration (`inventory.ini`)
**Changes:**
- Restructured inventory to reflect actual VM architecture
- Added proper host groups: `cicd_servers`, `loadbalancer_servers`, `app_servers`, `monitoring_servers`, `security_servers`
- Configured proper IP addresses from internal network (192.168.1.0/24)
- Set up development environment with thea-app1 (primary) and thea-app2 (backup)

**Before:** Generic placeholder inventory  
**After:** Specific VM-based inventory matching VirtualBox setup

### 2. Ansible Configuration (`ansible.cfg`)
**Changes:**
- Updated `remote_user` from `ubuntu` to `vboxuser`
- Changed SSH key path to `~/.ssh/thea-ansible-key`
- Fixed deprecated `collections_paths` to `collections_path`
- Added `deprecation_warnings = False`
- Added `allow_world_readable_tmpfiles = True` for local development

### 3. Main Deployment Playbook (`deploy.yml`)
**Changes:**
- Split into two separate plays:
  1. Application servers play (thea-app1, thea-app2)
  2. Load balancer play (thea-loadbalancer)
- Updated host targeting from `all` to specific groups
- Removed redundant package installations for local connections
- Added proper service distribution messaging
- Configured load balancer with upstream server references

### 4. Docker Role (`roles/docker/`)
**Changes:**
- Updated image pulling to separate infrastructure images from THEA microservices
- Added support for local registry images (`localhost:5000/*`)
- Changed Docker Compose execution from ansible module to shell command (avoiding deprecated module)
- Added directory creation for application data
- Updated file ownership from hardcoded `ubuntu` to `{{ ansible_user }}`
- Added prometheus.yml copy task

**Templates:**
- `docker-compose.yml.j2`: 
  - Changed from `build:` to `image:` directives
  - Updated to use local registry images
  - Removed deprecated `version:` field
  - Fixed Celery worker commands to match actual app structure

### 5. New Nginx Load Balancer Role (`roles/nginx/`)
**Created:**
- `tasks/main.yml` - Nginx deployment tasks
- `handlers/main.yml` - Nginx restart handlers
- `templates/nginx.conf.j2` - Comprehensive Nginx configuration with:
  - Upstream definitions for all services
  - Health check endpoints
  - Load balancing with least_conn algorithm
  - Automatic failover to backup server
  - Service-specific proxy configurations
  - Proper timeout settings for long-running requests
- `templates/docker-compose-nginx.yml.j2` - Dockerized Nginx deployment

**Features:**
- Least connections load balancing algorithm
- Automatic health checks
- Backup server failover configuration
- Port forwarding for all THEA services (3000, 8000, 8001, 9090, 3010)

### 6. Common Role (`roles/common/`)
**Changes:**
- Made firewall configuration conditional (`when: ansible_connection != "local"`)
- Prevented firewall setup on development localhost deployments
- Maintained security for remote deployments

### 7. Development Variables (`vars/development.yml`)
**Changes:**
- Added `docker_registry: localhost:5000`
- Added `use_local_registry: true`
- Variables already properly configured for multi-server architecture

### 8. New Files Created

#### `setup-ssh-keys.sh`
- Automated SSH key distribution script
- Copies SSH public key to all target VMs
- Tests connectivity after setup
- Color-coded output for clarity

#### `DEPLOYMENT_GUIDE.md`
- Comprehensive deployment documentation
- Architecture diagrams
- Step-by-step deployment instructions
- Troubleshooting guide
- Service access information

## Architecture Summary

```
thea-cicd (192.168.1.10)
    ↓ [Ansible Deployment]
    ├─→ thea-loadbalancer (192.168.1.40) [Nginx]
    │       ↓
    │   Load balances between:
    │       ├─→ thea-app1 (192.168.1.50) [Primary]
    │       └─→ thea-app2 (192.168.1.60) [Backup]
    │
    ├─→ thea-app1 (192.168.1.50)
    │   ├── nodejs-backend (localhost:5000/nodejs_backend_thea-backend)
    │   ├── fastapi-ocr (localhost:5000/thea_fastapi-ocr)
    │   ├── rag-chatbot (localhost:5000/rag_chatbot)
    │   ├── MySQL, Redis, RabbitMQ, MinIO
    │   ├── PostgreSQL, ChromaDB, Ollama
    │   └── Prometheus, Grafana
    │
    └─→ thea-app2 (192.168.1.60)
        └── [Same services as thea-app1]
```

## Service Endpoints

### Through Load Balancer (Recommended)
- Node.js API: http://192.168.1.40:3000
- OCR Service: http://192.168.1.40:8000
- Chatbot: http://192.168.1.40:8001
- Grafana: http://192.168.1.40:3010
- Prometheus: http://192.168.1.40:9090

### Direct Access (Development/Debug)
- thea-app1: http://192.168.1.50:[port]
- thea-app2: http://192.168.1.60:[port]

## Docker Registry

**Location:** thea-cicd (192.168.1.10:5000)

**Images:**
- `localhost:5000/nodejs_backend_thea-backend:latest`
- `localhost:5000/thea_fastapi-ocr:latest`
- `localhost:5000/rag_chatbot:latest`

## Next Steps

1. **Before Deployment:**
   - Ensure all VMs (thea-loadbalancer, thea-app1, thea-app2) are running
   - Verify network connectivity between VMs
   - Run `./setup-ssh-keys.sh` to configure SSH access

2. **Deployment:**
   ```bash
   cd /home/vboxuser/Downloads/THEA/ansible
   ansible-playbook -i inventory.ini deploy.yml -e "env=development"
   ```

3. **Verification:**
   - Check load balancer: `curl http://192.168.1.40/health`
   - Test service access through load balancer
   - Verify failover by stopping thea-app1 services

4. **Post-Deployment:**
   - Configure monitoring alerts
   - Set up automated backups
   - Document operational procedures
   - Train team on deployment process

## Testing Status

- ✅ Playbook syntax validated
- ✅ Inventory structure verified
- ✅ SSH keys generated
- ⏳ SSH key distribution (run setup-ssh-keys.sh)
- ⏳ Actual deployment (requires VMs to be running)
- ⏳ Service verification
- ⏳ Load balancer failover testing

## Files Modified

1. `ansible/inventory.ini` - VM inventory
2. `ansible/ansible.cfg` - Ansible configuration
3. `ansible/deploy.yml` - Main playbook
4. `ansible/vars/development.yml` - Development variables
5. `ansible/roles/common/tasks/main.yml` - Common tasks
6. `ansible/roles/docker/tasks/main.yml` - Docker deployment
7. `ansible/roles/docker/templates/docker-compose.yml.j2` - Compose template

## Files Created

1. `ansible/roles/nginx/tasks/main.yml` - Nginx tasks
2. `ansible/roles/nginx/handlers/main.yml` - Nginx handlers
3. `ansible/roles/nginx/templates/nginx.conf.j2` - Nginx config
4. `ansible/roles/nginx/templates/docker-compose-nginx.yml.j2` - Nginx compose
5. `ansible/setup-ssh-keys.sh` - SSH setup script
6. `ansible/DEPLOYMENT_GUIDE.md` - Deployment documentation
7. `ansible/ANSIBLE_CHANGES.md` - This file

## Notes

- All changes maintain backward compatibility with single-host deployment
- Load balancer uses least connections algorithm for optimal distribution
- Automatic failover configured for high availability
- Docker images pulled from local registry (192.168.1.10:5000)
- All services configured with health checks
- Nginx configured with appropriate timeouts for OCR processing

## Security Improvements

- SSH key-based authentication (no passwords)
- Firewall configuration conditional on environment
- Services isolated on internal network
- Secrets management ready for ansible-vault encryption
