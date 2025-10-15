# THEA Partial Deployment Guide
## Deploy with Load Balancer Only

## Current Setup
- ✅ **thea-cicd** (192.168.1.10) - Running (you are here)
- ✅ **thea-loadbalancer** (192.168.1.40) - Running
- ❌ **thea-app1** (192.168.1.50) - Not available
- ❌ **thea-app2** (192.168.1.60) - Not available

## What This Deployment Does

1. **Deploys all services on thea-cicd** (current VM):
   - Node.js Backend
   - FastAPI OCR Service
   - RAG Chatbot
   - MySQL, Redis, RabbitMQ, MinIO
   - PostgreSQL, ChromaDB, Ollama
   - Prometheus, Grafana

2. **Configures Nginx load balancer on thea-loadbalancer**:
   - Sets up Nginx in Docker
   - Routes traffic to services on thea-cicd (192.168.1.10)
   - Ready for future expansion to app1/app2

## Prerequisites

### 1. Check Load Balancer Connectivity

```bash
ping -c 3 192.168.1.40
```

Should show successful pings.

### 2. Verify Docker Registry

```bash
curl http://localhost:5000/v2/_catalog
```

Should show your images:
- `nodejs_backend_thea-backend`
- `thea_fastapi-ocr`
- `rag_chatbot`

## Deployment Steps

### Step 1: Set Up SSH Key for Load Balancer

```bash
cd /home/vboxuser/Downloads/THEA/ansible
./setup-ssh-lb.sh
```

You'll be prompted for the password of thea-loadbalancer.

### Step 2: Verify Ansible Connectivity

```bash
ansible all -i inventory-local.ini -m ping
```

Expected output:
```
thea-cicd | SUCCESS => { "ping": "pong" }
thea-loadbalancer | SUCCESS => { "ping": "pong" }
```

### Step 3: Deploy!

```bash
ansible-playbook -i inventory-local.ini deploy-local.yml -e "env=development"
```

This will:
1. Deploy Docker services on thea-cicd (~10-15 minutes)
2. Configure Nginx load balancer on thea-loadbalancer (~2 minutes)

### Step 4: Verify Deployment

**Check services on thea-cicd:**
```bash
# Locally
curl http://localhost:3000/health
curl http://localhost:8000/health
curl http://localhost:8001/health

# From load balancer's perspective
curl http://192.168.1.10:3000/health
curl http://192.168.1.10:8000/health
curl http://192.168.1.10:8001/health
```

**Check load balancer:**
```bash
# Load balancer health
curl http://192.168.1.40/health

# Services through load balancer
curl http://192.168.1.40:3000/health
curl http://192.168.1.40:8000/health
curl http://192.168.1.40:8001/health
```

## Accessing Your Services

### Through Load Balancer (Recommended)

Use the load balancer IP (192.168.1.40):

- **Node.js API:** http://192.168.1.40:3000
- **OCR Service:** http://192.168.1.40:8000
- **Chatbot:** http://192.168.1.40:8001
- **Grafana:** http://192.168.1.40:3010 (admin/admin)
- **Prometheus:** http://192.168.1.40:9090

### Direct Access (Local)

Or access directly on thea-cicd:

- **Node.js API:** http://localhost:3000 or http://192.168.1.10:3000
- **OCR Service:** http://localhost:8000 or http://192.168.1.10:8000
- **Chatbot:** http://localhost:8001 or http://192.168.1.10:8001
- **Grafana:** http://localhost:3010 or http://192.168.1.10:3010
- **Prometheus:** http://localhost:9090 or http://192.168.1.10:9090
- **RabbitMQ Management:** http://localhost:15672 (guest/guest)
- **MinIO Console:** http://localhost:9001 (minioadmin/minioadmin)

## Architecture

```
                    Internet
                        │
                        ▼
              ┌─────────────────┐
              │  thea-cicd      │
              │  192.168.1.10   │
              │                 │
              │  ┌────────────┐ │
              │  │ Registry   │ │
              │  │ :5000      │ │
              │  └────────────┘ │
              │                 │
              │  ┌────────────┐ │
              │  │ Services   │ │
              │  │ :3000-8001 │ │
              │  └────────────┘ │
              └────────┬────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │  thea-loadbalancer      │
         │  192.168.1.40           │
         │                         │
         │  ┌────────────────────┐ │
         │  │  Nginx             │ │
         │  │  Routes to         │ │
         │  │  192.168.1.10      │ │
         │  └────────────────────┘ │
         └─────────────────────────┘
                       │
                       ▼
                  Your Browser
```

## Troubleshooting

### Can't SSH to Load Balancer

```bash
# Try manual SSH first
ssh vboxuser@192.168.1.40

# If host key issues
ssh-keygen -R 192.168.1.40
./setup-ssh-lb.sh
```

### Load Balancer Can't Reach Services

```bash
# From load balancer, test connectivity
ssh vboxuser@192.168.1.40
ping 192.168.1.10
curl http://192.168.1.10:3000/health
```

If this fails, check firewall on thea-cicd:
```bash
sudo ufw status
sudo ufw allow from 192.168.1.0/24 to any
```

### Services Not Starting on thea-cicd

```bash
# Check Docker containers
docker ps
docker compose -f /opt/thea/docker-compose.yml ps

# Check logs
docker compose -f /opt/thea/docker-compose.yml logs --tail=50
```

### Load Balancer Returns 502

This usually means Nginx can't reach the backend. Check:

1. Services are running on thea-cicd: `curl http://192.168.1.10:3000/health`
2. Nginx config is correct: SSH to load balancer and check `/opt/nginx/conf/nginx.conf`
3. Nginx container is running: `ssh vboxuser@192.168.1.40 "cd /opt/nginx && docker compose ps"`

## Scaling Out Later

When thea-app1 and thea-app2 become available:

1. **Update inventory:**
   - Use `inventory.ini` instead of `inventory-local.ini`
   
2. **Redeploy:**
   ```bash
   ansible-playbook -i inventory.ini deploy.yml -e "env=development"
   ```

3. **Load balancer will automatically:**
   - Route to thea-app1 (primary)
   - Failover to thea-app2 (backup)
   - Stop using thea-cicd for app services

## Current State

After this deployment:
- ✅ All services running on thea-cicd
- ✅ Load balancer configured and routing traffic
- ✅ High availability ready (just add app1/app2 later)
- ✅ Monitoring and metrics active

## Next Steps

1. ✅ Run `./setup-ssh-lb.sh`
2. ✅ Deploy with `ansible-playbook -i inventory-local.ini deploy-local.yml -e "env=development"`
3. ⏳ Test services through load balancer
4. ⏳ Configure Grafana dashboards
5. ⏳ Set up monitoring alerts
6. ⏳ When ready, power on app1/app2 and scale out

---

**Ready to deploy?** Start with `./setup-ssh-lb.sh`! 🚀
