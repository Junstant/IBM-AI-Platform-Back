# 🤖 IBM AI Platform Backend

Artificial intelligence platform with multiple LLM models, PostgreSQL, and specialized APIs.

## 🚀 Deployment

**Automated installation on existing machines**

```bash
# Clone the repository
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# Run the automatic installation (auto-configures .env with external IP)
chmod +x setup.sh
sudo ./setup.sh

# If you need to configure manually, edit .env:
# vim .env  # Set TOKEN_HUGGHINGFACE and other variables
```

**Requirements**:
- CentOS/RHEL/Rocky Linux 8/9 or Ubuntu 20.04+
- 20+ GB RAM
- 50+ GB available disk
- Docker 24.0+
- HuggingFace token: https://huggingface.co/settings/tokens

**Features**:
- ✅ Auto-detects external IP and configures VITE_API_HOST
- ✅ Copies .env.example to .env automatically
- ✅ Installs Docker, Docker Compose, and all dependencies
- ✅ Deploys 15+ containers (APIs, LLMs, databases)
- ✅ Ready in ~15-20 minutes

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