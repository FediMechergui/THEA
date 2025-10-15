# THEA Ansible Deployment - Quick Start

## ✅ What's Been Fixed

Based on your VirtualBox setup, the Ansible playbook has been completely reconfigured to:

1. **Deploy to the correct VMs:**
   - `thea-loadbalancer` (192.168.1.40) - Nginx load balancer
   - `thea-app1` (192.168.1.50) - Primary application server
   - `thea-app2` (192.168.1.60) - Backup application server

2. **Use local Docker registry:**
   - All microservice images pulled from `localhost:5000` (thea-cicd)
   - No building on target servers, uses pre-built images

3. **Configure Nginx load balancer:**
   - Load balances between thea-app1 (primary) and thea-app2 (backup)
   - Automatic failover on server failure
   - Health checks for all services

4. **Proper user and SSH configuration:**
   - Uses `vboxuser` instead of `ubuntu`
   - SSH key authentication configured
   - No password prompts during deployment

## 📋 Prerequisites Checklist

Before running the playbook, ensure:

- [ ] All VMs are running:
  ```bash
  ping -c 2 192.168.1.40  # thea-loadbalancer
  ping -c 2 192.168.1.50  # thea-app1
  ping -c 2 192.168.1.60  # thea-app2
  ```

- [ ] Docker images are in local registry:
  ```bash
  curl http://localhost:5000/v2/_catalog
  ```
  Should show: `nodejs_backend_thea-backend`, `rag_chatbot`, `thea_fastapi-ocr`

- [ ] You're on the thea-cicd VM (192.168.1.10)

## 🚀 Deployment Steps

### Step 1: Set Up SSH Access

Run the SSH key distribution script:

```bash
cd /home/vboxuser/Downloads/THEA/ansible
./setup-ssh-keys.sh
```

**What it does:**
- Copies your SSH public key to all target VMs
- Tests SSH connectivity
- Enables passwordless authentication

**Note:** You'll be prompted for the password of each VM.

### Step 2: Verify Connectivity

Test that Ansible can reach all hosts:

```bash
ansible all -i inventory.ini -m ping
```

**Expected output:**
```
thea-loadbalancer | SUCCESS => { "ping": "pong" }
thea-app1 | SUCCESS => { "ping": "pong" }
thea-app2 | SUCCESS => { "ping": "pong" }
```

### Step 3: Deploy!

Run the deployment playbook:

```bash
ansible-playbook -i inventory.ini deploy.yml -e "env=development"
```

**What happens:**
1. Deploys Docker services to thea-app1 (10-15 minutes)
2. Deploys Docker services to thea-app2 (10-15 minutes)
3. Configures Nginx load balancer on thea-loadbalancer (1-2 minutes)
4. Runs health checks on all services

### Step 4: Verify Deployment

Check that services are accessible through the load balancer:

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

## 🌐 Access Your Services

### Through Load Balancer (Recommended)

All services are accessed via `192.168.1.40`:

- **Node.js API:** http://192.168.1.40:3000
- **OCR Service:** http://192.168.1.40:8000
- **Chatbot:** http://192.168.1.40:8001
- **Grafana:** http://192.168.1.40:3010 (admin/admin)
- **Prometheus:** http://192.168.1.40:9090

### Direct Access (If Needed)

**Primary (thea-app1):** http://192.168.1.50:[port]  
**Backup (thea-app2):** http://192.168.1.60:[port]

- RabbitMQ Management: port 15672 (guest/guest)
- MinIO Console: port 9001 (minioadmin/minioadmin)

## 🔧 Common Issues

### SSH Connection Failed

**Problem:** Can't SSH to VMs

**Solution:**
```bash
# Check if VMs are reachable
ping 192.168.1.40

# Try manual SSH
ssh vboxuser@192.168.1.40

# If needed, remove old host keys
ssh-keygen -R 192.168.1.40
ssh-keygen -R 192.168.1.50
ssh-keygen -R 192.168.1.60
```

### Docker Images Not Found

**Problem:** Ansible can't pull images from registry

**Solution:**
```bash
# Make sure registry is accessible from app servers
ssh vboxuser@192.168.1.50
curl http://192.168.1.10:5000/v2/_catalog

# If not, check firewall on thea-cicd
sudo ufw status
sudo ufw allow 5000/tcp
```

### Services Not Starting

**Problem:** Docker containers fail to start

**Solution:**
```bash
# SSH to app server
ssh vboxuser@192.168.1.50

# Check container logs
cd /opt/thea
docker compose ps
docker compose logs [service-name]

# Restart services
docker compose restart
```

### Load Balancer Returns 502

**Problem:** Nginx returns 502 Bad Gateway

**Solution:**
```bash
# Check if backend services are running
curl http://192.168.1.50:3000/health
curl http://192.168.1.60:3000/health

# Check Nginx logs
ssh vboxuser@192.168.1.40
cd /opt/nginx
docker compose logs nginx
```

## 📊 Monitoring

Access Grafana dashboards:

1. Open: http://192.168.1.40:3010
2. Login: admin / admin
3. View pre-configured dashboards for:
   - Node.js Backend metrics
   - Docker container stats
   - System resources
   - API response times

## 🔄 Updating Services

When you update code and rebuild images:

```bash
# 1. Build new images on thea-cicd
cd /home/vboxuser/Downloads/THEA/nodejs_backend
docker build -t nodejs_backend_thea-backend:latest .

# 2. Push to registry
docker tag nodejs_backend_thea-backend:latest localhost:5000/nodejs_backend_thea-backend:latest
docker push localhost:5000/nodejs_backend_thea-backend:latest

# 3. Redeploy (pulls new images and restarts)
cd /home/vboxuser/Downloads/THEA/ansible
ansible-playbook -i inventory.ini deploy.yml -e "env=development"
```

## 📚 More Documentation

- **Detailed Guide:** `DEPLOYMENT_GUIDE.md`
- **Changes Summary:** `ANSIBLE_CHANGES.md`
- **VirtualBox Setup:** `../VirtualBox_Setup_Guide.md`

## ✨ Architecture

```
                    Internet
                        │
                        ▼
              ┌─────────────────┐
              │  thea-cicd      │
              │  192.168.1.10   │
              │  CI/CD+Registry │
              └────────┬────────┘
                       │ Ansible
                       ▼
         ┌─────────────────────────┐
         │  thea-loadbalancer      │
         │  192.168.1.40           │
         │  Nginx Load Balancer    │
         └─────────┬───────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌───────────────┐    ┌───────────────┐
│  thea-app1    │    │  thea-app2    │
│  192.168.1.50 │    │  192.168.1.60 │
│  PRIMARY      │    │  BACKUP       │
└───────────────┘    └───────────────┘
```

## 🎯 What's Next?

1. ✅ Run `./setup-ssh-keys.sh`
2. ✅ Deploy with `ansible-playbook`
3. ⏳ Configure monitoring alerts
4. ⏳ Set up automated backups
5. ⏳ Integrate with Jenkins CI/CD
6. ⏳ Add SSL/TLS certificates

---

**Ready to deploy?** Start with Step 1 above! 🚀
