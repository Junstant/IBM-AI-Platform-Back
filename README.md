# 🤖 IBM AI Platform Backend

Artificial intelligence platform with multiple LLM models, PostgreSQL, and specialized APIs.

## 🚀 Deployment Options

### Option 1: Automated Deployment on IBM PowerVS (TechZone) ⭐ RECOMMENDED

**Perfect for production environments and demos**

```bash
# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Complete workspace_guid, ssh_public_key, huggingface_token

# 2. Deploy (takes ~20-25 minutes)
export IC_API_KEY="your-ibm-cloud-api-key"
terraform init
terraform apply

# 3. Get external IP
terraform output vm_external_ip
```

📖 **Complete guide**: [TECHZONE_DEPLOYMENT.md](TECHZONE_DEPLOYMENT.md)  
⚡ **Quick start**: [QUICKSTART.md](QUICKSTART.md)

**Features**:
- ✅ Fully automated infrastructure (public network, VM, storage)
- ✅ Auto-configuration of external IP in environment variables
- ✅ Downloads setup.sh and deploys automatically
- ✅ Ready in ~20-25 minutes without manual intervention

---

### Option 2: Manual Installation (Local/VMs)

**For development and testing on existing machines**

```bash
# Clone the repository
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# Create a .env file with the required configuration
cp .env.example .env
vim .env  # Configure VITE_API_HOST and other variables

# Run the automatic installation
chmod +x setup.sh
sudo ./setup.sh
```

**Requirements**:
- CentOS/RHEL/Rocky Linux 8/9 or Ubuntu 20.04+
- 20+ GB RAM
- 50+ GB available disk
- Docker 24.0+

## 🎯 Services

- **Frontend**: `http://localhost:2012`
- **Fraud API**: `http://localhost:8001/docs`
- **TextoSQL API**: `http://localhost:8000/docs`
- **Stats API**: `http://localhost:8003/docs`
- **RAG API**: `http://localhost:8004/docs`
- **PostgreSQL**: `localhost:8070`
- **Milvus**: `localhost:19530`

## 🗄️ Databases

- **ai_platform_stats**: Metrics and statistics
- **banco_global**: Demo for a fictitious bank
- **bank_transactions**: Fraud detection
- **ai_platform_rag**: Vectors and embeddings
- **ferreteria_weitzler**: TextoSQL demo (real Chilean hardware store)

## 🧠 LLM Models

| Model | Port | Size | Specialty |
|-------|------|------|-----------|
| **Gemma 2B** | 8085 | ~1.5GB | Fast responses |
| **Gemma 4B** | 8086 | ~3GB | Balance between speed and quality |
| **Arctic text2sql 7b** | 8087 | 4.68GB | Text to SQL |
| **Mistral 7B** | 8088 | ~5GB | General tasks |
| **DeepSeek 8B** | 8089 | ~6GB | Logical reasoning |

## 📝 Useful Commands

```bash
# View service logs
docker-compose logs -f [service]

# Restart services
docker-compose restart

# Check status
docker-compose ps

# Stop services
docker-compose down

# View resource usage
docker stats
```

## 🤝 Contribute

Read [CONTRIBUTING.md](CONTRIBUTING.md) to learn about the contribution guidelines.

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for more details.