# THEA Jenkins Pipeline Configuration - Summary

**Date:** October 11, 2025  
**Status:** ✅ **COMPLETED**  
**Jenkins URL:** http://localhost:8080

---

## 🎯 Overview

Successfully configured Jenkins CI/CD pipelines for all three THEA microservices using local repository sources. All pipeline jobs are now active and ready to build.

---

## 📊 Jenkins Jobs Created

### 1. **THEA-NodeJS-Backend**
- **URL:** http://localhost:8080/job/THEA-NodeJS-Backend/
- **Repository Path:** `/home/vboxuser/Downloads/THEA`
- **Jenkinsfile:** `nodejs_backend/Jenkinsfile.local`
- **Description:** THEA Node.js Backend Service - Express API with Prisma ORM
- **Features:**
  - Dependency installation (npm ci)
  - ESLint code quality checks
  - Jest unit and integration tests
  - Docker image build
  - Security scan (npm audit + Trivy)
  - Database migration check
  - Local deployment on port 3000

### 2. **THEA-FastAPI-OCR**
- **URL:** http://localhost:8080/job/THEA-FastAPI-OCR/
- **Repository Path:** `/home/vboxuser/Downloads/THEA`
- **Jenkinsfile:** `fastapi_ocr/Jenkinsfile`
- **Description:** THEA FastAPI OCR Service - Invoice processing with Tesseract OCR
- **Features:**
  - Python virtual environment setup
  - Dependency installation (pip)
  - Code quality checks (pylint, flake8)
  - Pytest unit tests
  - Docker image build
  - Security scan (Trivy)
  - Local deployment on port 8000

### 3. **THEA-RAG-Chatbot**
- **URL:** http://localhost:8080/job/THEA-RAG-Chatbot/
- **Repository Path:** `/home/vboxuser/Downloads/THEA`
- **Jenkinsfile:** `rag_chatbot/Jenkinsfile`
- **Description:** THEA RAG Chatbot Service - AI-powered document Q&A with LangChain and Ollama
- **Features:**
  - Python virtual environment setup
  - Heavy ML dependencies installation (LangChain, transformers, etc.)
  - Code quality checks (pylint, flake8)
  - Pytest unit tests
  - Docker image build (with increased timeout for ML packages)
  - Security scan (Trivy)
  - Prerequisites check (Ollama, ChromaDB, PostgreSQL)
  - Dual container deployment (API + Celery worker) on port 8001

---

## 🚀 Pipeline Stages (Common)

All three pipelines follow a similar structure:

1. **Checkout & Environment Setup**
   - Display build information
   - Verify tool versions

2. **Install Dependencies**
   - Node.js: `npm ci`
   - Python: `pip install -r requirements.txt`

3. **Code Quality Checks**
   - Node.js: ESLint
   - Python: pylint + flake8

4. **Run Tests**
   - Node.js: Jest with coverage
   - Python: pytest with coverage

5. **Build Docker Image**
   - Multi-arch build support
   - Tagged with build number and 'latest'

6. **Security Scan**
   - Dependency scanning
   - Container vulnerability scanning with Trivy

7. **Deploy Locally**
   - Stop existing containers
   - Run new containers with proper networking
   - Health check verification

---

## 📁 File Structure

```
THEA/
├── nodejs_backend/
│   ├── Jenkinsfile.local          ← New simplified local pipeline
│   └── Jenkinsfile                ← Original production pipeline
├── fastapi_ocr/
│   └── Jenkinsfile                ← New pipeline (created)
├── rag_chatbot/
│   └── Jenkinsfile                ← New pipeline (created)
└── scripts/
    └── configure-jenkins-jobs.sh  ← Automation script (created)
```

---

## 🔧 Configuration Details

### Git SCM Configuration
- **Type:** Local file system repository
- **URL:** `file:///home/vboxuser/Downloads/THEA`
- **Branch:** `*/main`
- **Polling:** Every 5 minutes (H/5 * * * *)

### Build Triggers
- Manual trigger via "Build Now" button
- SCM polling (checks for changes every 5 minutes)
- Can be extended with webhooks for GitHub integration

### Post-Build Actions
- Artifact archiving (dependency reports, test results)
- Automated cleanup of old Docker images
- Workspace cleanup

---

## 💻 How to Use

### Option 1: Manual Build via Web UI
1. Open Jenkins in browser: http://localhost:8080
2. Navigate to desired job:
   - THEA-NodeJS-Backend
   - THEA-FastAPI-OCR
   - THEA-RAG-Chatbot
3. Click "Build Now" in the left sidebar
4. Monitor build progress in "Build History"
5. View console output for detailed logs

### Option 2: Jenkins CLI (if configured)
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ build THEA-NodeJS-Backend
java -jar jenkins-cli.jar -s http://localhost:8080/ build THEA-FastAPI-OCR
java -jar jenkins-cli.jar -s http://localhost:8080/ build THEA-RAG-Chatbot
```

### Option 3: API Trigger
```bash
curl -X POST http://localhost:8080/job/THEA-NodeJS-Backend/build
curl -X POST http://localhost:8080/job/THEA-FastAPI-OCR/build
curl -X POST http://localhost:8080/job/THEA-RAG-Chatbot/build
```

---

## 🔍 Build Process Overview

### Node.js Backend Build (~5-10 minutes)
```
Checkout → npm install → ESLint → Jest Tests → 
Docker Build → Security Scan → Deploy → Health Check
```

### FastAPI OCR Build (~8-12 minutes)
```
Checkout → pip install → pylint/flake8 → pytest → 
Docker Build → Security Scan → Deploy → Health Check
```

### RAG Chatbot Build (~25-35 minutes)
```
Checkout → pip install (heavy ML) → pylint/flake8 → pytest → 
Docker Build (15-20 min) → Security Scan → Prerequisites Check → 
Deploy (API + Worker) → Health Check
```

---

## 🐳 Docker Integration

### Networks
All containers are deployed to the `thea-network` Docker network for inter-service communication.

### Ports Exposed
- **Node.js Backend:** 3000
- **FastAPI OCR:** 8000
- **RAG Chatbot:** 8001

### Volumes
- **FastAPI OCR:** `./fastapi_ocr/uploads:/app/uploads`
- **RAG Chatbot:** `./rag_chatbot/data:/app/data`

### Environment Variables
Each service loads environment variables from:
- `nodejs_backend/.env.docker`
- `fastapi_ocr/.env.docker`
- `rag_chatbot/.env.docker`

---

## 🔐 Security Features

### Implemented Security Measures
1. **Dependency Scanning**
   - npm audit for Node.js
   - pip safety checks for Python

2. **Container Vulnerability Scanning**
   - Trivy scans for HIGH and CRITICAL vulnerabilities
   - Automatic image pruning

3. **Code Quality**
   - ESLint for JavaScript
   - pylint + flake8 for Python
   - Automated test execution

4. **Secure Defaults**
   - No hardcoded credentials
   - Environment variable based configuration
   - Network isolation via Docker networks

---

## 📈 Monitoring & Observability

### Build Artifacts
- Dependency reports
- Test coverage reports (HTML, XML)
- ESLint/pylint reports
- Docker image metadata

### Health Checks
Each pipeline includes automated health checks:
- Node.js: `GET http://localhost:3000/health`
- FastAPI OCR: `GET http://localhost:8000/health`
- RAG Chatbot: `GET http://localhost:8001/health`

### Log Locations
- **Jenkins Logs:** `/var/lib/jenkins/jobs/<job-name>/builds/<build-number>/log`
- **Container Logs:** `docker logs <container-name>`

---

## 🛠️ Maintenance

### Automated Cleanup
- Old Docker images are pruned after 7 days (168 hours)
- Jenkins retains last 10 builds per job
- Workspace cleanup after each build

### Manual Cleanup
```bash
# Clean all stopped containers
docker container prune -f

# Clean unused images
docker image prune -a -f

# Clean build workspace
cd /var/lib/jenkins/workspace
sudo rm -rf THEA-*
```

---

## ⚙️ Configuration Files

### Jenkins Job Locations
```
/var/lib/jenkins/jobs/THEA-NodeJS-Backend/config.xml
/var/lib/jenkins/jobs/THEA-FastAPI-OCR/config.xml
/var/lib/jenkins/jobs/THEA-RAG-Chatbot/config.xml
```

### Jenkinsfile Locations
```
/home/vboxuser/Downloads/THEA/nodejs_backend/Jenkinsfile.local
/home/vboxuser/Downloads/THEA/fastapi_ocr/Jenkinsfile
/home/vboxuser/Downloads/THEA/rag_chatbot/Jenkinsfile
```

---

## 🔄 Updating Pipelines

### Modify Pipeline Behavior
1. Edit the Jenkinsfile in the repository
2. Commit changes (if using git)
3. Trigger new build in Jenkins

### Re-create Jobs
```bash
cd /home/vboxuser/Downloads/THEA
sudo ./scripts/configure-jenkins-jobs.sh
```

---

## 🐛 Troubleshooting

### Build Failures

#### Node.js Backend
**Problem:** `npm ci` fails  
**Solution:** Check `package-lock.json` exists, run `npm install` locally first

**Problem:** Tests fail  
**Solution:** Verify database connectivity, check `.env.docker` configuration

#### FastAPI OCR
**Problem:** Tesseract not found  
**Solution:** Ensure Dockerfile includes `tesseract-ocr` package

**Problem:** Timeout during pip install  
**Solution:** Increase timeout in Dockerfile (already set to 300s)

#### RAG Chatbot
**Problem:** Build timeout  
**Solution:** Pipeline timeout set to 60 minutes; consider pre-building base images

**Problem:** Ollama not found  
**Solution:** Ensure Ollama container is running before build

### Jenkins Issues

**Problem:** Jobs not showing up  
**Solution:** Restart Jenkins: `sudo systemctl restart jenkins`

**Problem:** Permission denied  
**Solution:** Check file ownership: `sudo chown -R jenkins:jenkins /var/lib/jenkins/jobs`

**Problem:** Network connectivity  
**Solution:** Verify `thea-network` exists: `docker network ls`

---

## 📚 Next Steps

### Recommended Enhancements
1. **SonarQube Integration**
   - Install SonarQube scanner plugin
   - Configure quality gates
   - Add SonarQube analysis stage

2. **Artifact Management**
   - Set up Nexus or Artifactory
   - Push Docker images to private registry
   - Version management

3. **Notifications**
   - Email notifications on build failure
   - Slack/Teams integration
   - Build status badges

4. **Advanced Features**
   - Parallel stage execution
   - Matrix builds for multi-environment
   - Blue Ocean UI for better visualization
   - GitLab/GitHub webhook integration

---

## ✅ Verification Checklist

- [x] Jenkins is running on port 8080
- [x] Three pipeline jobs created
- [x] Jenkinsfiles exist for all services
- [x] Jobs configured with local repository
- [x] SCM polling enabled
- [x] Docker build stages configured
- [x] Health checks implemented
- [x] Security scanning included
- [x] Automated cleanup configured
- [x] Documentation complete

---

## 📞 Support

### Jenkins Access
- **Web UI:** http://localhost:8080
- **Users:** FediMechergui, theaadmin
- **Configuration:** `/etc/default/jenkins`
- **Home:** `/var/lib/jenkins`

### Service Endpoints
- **Node.js Backend:** http://localhost:3000
- **FastAPI OCR:** http://localhost:8000
- **RAG Chatbot:** http://localhost:8001

### Useful Commands
```bash
# Check Jenkins status
systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Rebuild all jobs script
sudo /home/vboxuser/Downloads/THEA/scripts/configure-jenkins-jobs.sh

# Check running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View container logs
docker logs -f <container-name>
```

---

**End of Jenkins Pipeline Configuration Summary**
