# ⚡ Quick Start - 15 Minute Deployment

## Prerequisites
- Linux server (CentOS/RHEL/Ubuntu)
- 20+ GB RAM, 50+ GB disk
- SSH access (root or sudo)
- HuggingFace token: https://huggingface.co/settings/tokens

## Deploy in 3 Steps

```bash
# 1. Clone repository
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# 2. Run automated setup
sudo ./setup.sh

# 3. Enter HuggingFace token when prompted
# (The script auto-detects your external IP)
```

## Access Services

```bash
# Frontend
http://<your-server-ip>:2012

# APIs
http://<your-server-ip>:8003/docs  # Stats
http://<your-server-ip>:8004/docs  # RAG
http://<your-server-ip>:8000/docs  # TextoSQL
http://<your-server-ip>:8001/docs  # Fraud
```

## Verify Deployment

```bash
docker ps  # Check all containers are running
curl http://localhost:8003/health  # Test health endpoint
```

## Cleanup

```bash
cd IBM-AI-Platform-Back
docker-compose down -v
```

📖 **Full guide**: [TECHZONE_DEPLOYMENT.md](TECHZONE_DEPLOYMENT.md)
