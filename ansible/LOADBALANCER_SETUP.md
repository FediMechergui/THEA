# Setting Up thea-loadbalancer VM

## Issue
SSH connection to thea-loadbalancer (192.168.1.40) is being refused. The VM is pingable but SSH service is not running.

## Solution

You need to access the thea-loadbalancer VM console directly (through VirtualBox) and set up SSH.

### Steps on thea-loadbalancer VM Console:

1. **Access the VM console in VirtualBox**
   - Click on `thea-loadbalancer` VM
   - Start it if not running
   - Access the console

2. **Log in to the VM**
   - Use your credentials

3. **Install and start SSH server:**
   ```bash
   # Install OpenSSH server
   sudo apt update
   sudo apt install -y openssh-server
   
   # Start and enable SSH service
   sudo systemctl start ssh
   sudo systemctl enable ssh
   
   # Check status
   sudo systemctl status ssh
   ```

4. **Configure firewall (if enabled):**
   ```bash
   # Allow SSH
   sudo ufw allow ssh
   sudo ufw allow from 192.168.1.0/24 to any
   ```

5. **Verify SSH is listening:**
   ```bash
   sudo netstat -tlnp | grep :22
   # Or
   sudo ss -tlnp | grep :22
   ```

6. **Test from thea-cicd:**
   ```bash
   # Back on thea-cicd, try SSH
   ssh vboxuser@192.168.1.40
   ```

## Alternative: Deploy Locally Only (No Load Balancer)

If you prefer to deploy everything on thea-cicd only and skip the load balancer for now:

### Option 1: Use Root Docker Compose

```bash
cd /home/vboxuser/Downloads/THEA
docker compose up -d
```

This will start all services on thea-cicd using the main docker-compose.yml.

### Option 2: Deploy with Ansible (localhost only)

Create a simpler inventory:

```bash
cd /home/vboxuser/Downloads/THEA/ansible
cat > inventory-localhost.ini << 'EOF'
[app_servers]
localhost ansible_connection=local

[development]
localhost

[all:vars]
ansible_python_interpreter=/usr/bin/python3

[development:vars]
env=development
domain=localhost
primary_app_server=localhost
backup_app_server=localhost
EOF
```

Then deploy:
```bash
ansible-playbook -i inventory-localhost.ini deploy.yml -e "env=development" --skip-tags nginx
```

## Recommended Approach

**For now, I recommend:**

1. **Quick Start - Just use Docker Compose:**
   ```bash
   cd /home/vboxuser/Downloads/THEA
   docker compose up -d
   ```

2. **Access services locally:**
   - Node.js: http://localhost:3000
   - OCR: http://localhost:8000
   - Chatbot: http://localhost:8001
   - Grafana: http://localhost:3010
   - Prometheus: http://localhost:9090

3. **Later, when ready to set up load balancer:**
   - Configure SSH on thea-loadbalancer (steps above)
   - Run `./setup-ssh-lb.sh`
   - Deploy with `ansible-playbook -i inventory-local.ini deploy-local.yml`

## What's Already Working

You have:
- ✅ Docker registry on thea-cicd with all images
- ✅ Jenkins configured
- ✅ SonarQube running
- ✅ All microservices built and ready

You can start using the system right away with Docker Compose!

