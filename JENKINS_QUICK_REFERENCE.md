# THEA Jenkins - Quick Reference Card

## 🚀 Access Points

```
Jenkins UI:       http://localhost:8080
Node.js Backend:  http://localhost:8080/job/THEA-NodeJS-Backend/
FastAPI OCR:      http://localhost:8080/job/THEA-FastAPI-OCR/
RAG Chatbot:      http://localhost:8080/job/THEA-RAG-Chatbot/
```

## 📝 Pipeline Files

```bash
nodejs_backend/Jenkinsfile.local    # Node.js pipeline
fastapi_ocr/Jenkinsfile             # OCR pipeline
rag_chatbot/Jenkinsfile             # RAG pipeline
```

## 🔧 Useful Commands

### Jenkins Control
```bash
sudo systemctl status jenkins       # Check status
sudo systemctl restart jenkins      # Restart Jenkins
sudo journalctl -u jenkins -f       # View logs
```

### Trigger Builds
```bash
# Via Web UI - Click "Build Now"

# Via API (if authentication configured)
curl -X POST http://localhost:8080/job/THEA-NodeJS-Backend/build
curl -X POST http://localhost:8080/job/THEA-FastAPI-OCR/build
curl -X POST http://localhost:8080/job/THEA-RAG-Chatbot/build
```

### Rebuild All Jobs
```bash
cd /home/vboxuser/Downloads/THEA
sudo ./scripts/configure-jenkins-jobs.sh
```

### Docker Management
```bash
docker ps                           # List running containers
docker logs -f <container-name>     # View container logs
docker network ls                   # List networks
docker image prune -a -f            # Clean old images
```

## 🐳 Service Endpoints

```
Node.js Backend:  http://localhost:3000/health
FastAPI OCR:      http://localhost:8000/health
RAG Chatbot:      http://localhost:8001/health
```

## 📊 Build Times (Approximate)

```
Node.js Backend:  5-10 minutes
FastAPI OCR:      8-12 minutes
RAG Chatbot:      25-35 minutes (heavy ML dependencies)
```

## 🔍 Troubleshooting

### Jenkins Not Accessible
```bash
sudo systemctl start jenkins
sudo ufw allow 8080/tcp
curl http://localhost:8080
```

### Build Failures
```bash
# Check logs
sudo tail -f /var/lib/jenkins/jobs/<job-name>/builds/<build-num>/log

# Check Docker network
docker network inspect thea-network

# Verify repository
ls -la /home/vboxuser/Downloads/THEA
```

### Permission Issues
```bash
sudo chown -R jenkins:jenkins /var/lib/jenkins/jobs
sudo chmod -R 755 /var/lib/jenkins/jobs
```

## 📁 Important Directories

```
Jenkins Home:     /var/lib/jenkins
Jobs Directory:   /var/lib/jenkins/jobs
Workspace:        /var/lib/jenkins/workspace
Repository:       /home/vboxuser/Downloads/THEA
```

## 🎯 Pipeline Stages

```
1. Checkout & Setup
2. Install Dependencies
3. Code Quality Checks
4. Run Tests
5. Build Docker Image
6. Security Scan
7. Deploy Locally
8. Health Check
```

## 🔐 Security Scans Included

- npm audit (Node.js)
- Trivy (Container scanning)
- ESLint (Code quality)
- pylint/flake8 (Python quality)

---
**Created:** October 11, 2025
**Last Updated:** October 11, 2025
