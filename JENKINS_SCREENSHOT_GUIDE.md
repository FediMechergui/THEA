# Jenkins Screenshot Guide

## 🔐 Jenkins Credentials

```
URL:      http://localhost:8080
Username: admin
Password: admin123
```

**Credentials saved in:** `/home/vboxuser/jenkins-credentials.txt`

---

## 📸 Screenshots to Take

### 1. Jenkins Dashboard (Main View)
**URL:** http://localhost:8080

**What to capture:**
- All three pipeline jobs listed:
  - THEA-NodeJS-Backend
  - THEA-FastAPI-OCR
  - THEA-RAG-Chatbot
- Build history (if any builds have been run)
- Overall Jenkins interface

**Steps:**
1. Login with credentials above
2. You should see the main dashboard
3. Take screenshot of the full page

---

### 2. Node.js Backend Job
**URL:** http://localhost:8080/job/THEA-NodeJS-Backend/

**What to capture:**
- Job name and description
- "Build Now" button
- Recent builds list
- Pipeline configuration

**Steps:**
1. Click on "THEA-NodeJS-Backend" from dashboard
2. Take screenshot of job page
3. Click "Build Now" to trigger a build
4. Take screenshot of build in progress

---

### 3. Node.js Backend Build Stages
**URL:** http://localhost:8080/job/THEA-NodeJS-Backend/[build-number]/

**What to capture:**
- Stage View showing all pipeline stages:
  - Checkout & Environment Setup
  - Install Dependencies
  - Code Quality Checks
  - Run Tests
  - Build Docker Image
  - Security Scan
  - Database Migration Check
  - Deploy Locally
- Console output (optional)

**Steps:**
1. From the job page, click on the latest build number (e.g., #1)
2. Wait for build to complete (or capture in progress)
3. Take screenshot showing the stage view
4. Optionally, click "Console Output" and take screenshot

---

### 4. FastAPI OCR Job
**URL:** http://localhost:8080/job/THEA-FastAPI-OCR/

**What to capture:**
- Job name and description
- Pipeline configuration
- Build history

**Steps:**
1. Click on "THEA-FastAPI-OCR" from dashboard
2. Take screenshot of job page
3. Click "Build Now"
4. Take screenshot of build stages

---

### 5. FastAPI OCR Build Stages
**URL:** http://localhost:8080/job/THEA-FastAPI-OCR/[build-number]/

**What to capture:**
- Stage View with all stages:
  - Checkout & Environment Setup
  - Install Dependencies
  - Code Quality Checks
  - Run Tests
  - Build Docker Image
  - Security Scan
  - Deploy Locally

---

### 6. RAG Chatbot Job
**URL:** http://localhost:8080/job/THEA-RAG-Chatbot/

**What to capture:**
- Job name and description
- Pipeline configuration
- Build history

**Steps:**
1. Click on "THEA-RAG-Chatbot" from dashboard
2. Take screenshot of job page
3. Click "Build Now"
4. Take screenshot of build stages (this will take 25-35 minutes)

---

### 7. RAG Chatbot Build Stages
**URL:** http://localhost:8080/job/THEA-RAG-Chatbot/[build-number]/

**What to capture:**
- Stage View with all stages:
  - Checkout & Environment Setup
  - Install Dependencies (long running - ML packages)
  - Code Quality Checks
  - Run Tests
  - Build Docker Image (15-20 minutes)
  - Security Scan
  - Check Prerequisites
  - Deploy Locally

---

## 🎯 Quick Screenshot Checklist

- [ ] Jenkins Dashboard with all 3 jobs
- [ ] THEA-NodeJS-Backend job page
- [ ] THEA-NodeJS-Backend build stages
- [ ] THEA-NodeJS-Backend console output (optional)
- [ ] THEA-FastAPI-OCR job page
- [ ] THEA-FastAPI-OCR build stages
- [ ] THEA-FastAPI-OCR console output (optional)
- [ ] THEA-RAG-Chatbot job page
- [ ] THEA-RAG-Chatbot build stages
- [ ] THEA-RAG-Chatbot console output (optional)

---

## 🚀 How to Trigger Builds

### Option 1: Via Web UI (Recommended)
1. Login to Jenkins: http://localhost:8080
2. Click on job name
3. Click "Build Now" in the left sidebar
4. Watch the build progress in real-time

### Option 2: Via Command Line
```bash
# Node.js Backend
curl -X POST http://admin:admin123@localhost:8080/job/THEA-NodeJS-Backend/build

# FastAPI OCR
curl -X POST http://admin:admin123@localhost:8080/job/THEA-FastAPI-OCR/build

# RAG Chatbot
curl -X POST http://admin:admin123@localhost:8080/job/THEA-RAG-Chatbot/build
```

---

## 📊 Build Status Indicators

- **Blue ball** ✅ - Build successful
- **Red ball** ❌ - Build failed
- **Grey ball** ⚪ - Build not run yet
- **Blue animation** 🔵 - Build in progress
- **Yellow ball** ⚠️ - Build unstable

---

## 🔍 Viewing Build Details

### Stage View
- Shows visual representation of all pipeline stages
- Color-coded status for each stage
- Duration time for each stage
- Click on stage to see logs

### Console Output
1. Click on build number (e.g., #1, #2)
2. Click "Console Output" in left sidebar
3. See real-time logs of the entire build process

### Test Results
1. Click on build number
2. Click "Test Results" (if tests were run)
3. View detailed test reports

### Artifacts
1. Click on build number
2. Click "Artifacts" to download:
   - Dependency reports
   - Test coverage reports
   - Build logs

---

## 💡 Pro Tips for Screenshots

1. **Full Page Screenshots**
   - Use browser extension or F12 Developer Tools
   - Capture full page, not just visible area

2. **High Resolution**
   - Zoom to 100% or 90% for optimal clarity
   - Don't zoom too much or too little

3. **Timing**
   - For "in progress" shots, capture when stages are visible
   - For "completed" shots, wait for all stages to finish

4. **Multiple Angles**
   - Take both job page and individual build pages
   - Capture both stage view and console output

5. **Annotations** (optional)
   - Use screenshot tool to add arrows or highlights
   - Point out important features

---

## 📝 Screenshot File Naming Convention

Suggested naming:
```
jenkins-dashboard.png
jenkins-nodejs-job-page.png
jenkins-nodejs-build-stages.png
jenkins-nodejs-console-output.png
jenkins-ocr-job-page.png
jenkins-ocr-build-stages.png
jenkins-ocr-console-output.png
jenkins-rag-job-page.png
jenkins-rag-build-stages.png
jenkins-rag-console-output.png
```

---

## 🛠️ Troubleshooting

### Can't Login
- Username: `admin`
- Password: `admin123`
- If still can't login, run: `sudo /home/vboxuser/Downloads/THEA/scripts/jenkins-reset-password.sh`

### Jobs Not Showing
- Refresh the browser (F5)
- Clear browser cache
- Restart Jenkins: `sudo systemctl restart jenkins`

### Build Stuck
- Check console output for errors
- Verify Docker is running: `docker ps`
- Check disk space: `df -h`

### Screenshot Tool Not Working
- Try built-in: `gnome-screenshot` or `spectacle`
- Use browser: Right-click → Inspect → Ctrl+Shift+P → "Capture full size screenshot"
- Use command line: `scrot -d 5 jenkins-screenshot.png`

---

## 📞 Quick Access Commands

```bash
# Open Jenkins in browser
xdg-open http://localhost:8080

# View credentials
cat /home/vboxuser/jenkins-credentials.txt

# Check Jenkins status
systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Check running containers (deployed services)
docker ps
```

---

**Ready to take screenshots!** 📸

Login at: http://localhost:8080
Username: admin
Password: admin123
