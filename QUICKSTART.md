# ⚡ Quick Start - 5 Minute Deployment

## Prerequisites
- IBM Cloud account with PowerVS workspace
- Terraform >= 1.3.0
- IBM Cloud API Key
- HuggingFace token

## Deploy in 5 Steps

```bash
# 1. Export credentials
export IC_API_KEY="your-ibm-cloud-api-key"

# 2. Clone and configure
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back
cp terraform.tfvars.example terraform.tfvars

# 3. Edit terraform.tfvars (only 3 required values)
vim terraform.tfvars
# workspace_guid, ssh_public_key, huggingface_token

# 4. Deploy
terraform init
terraform apply -auto-approve

# 5. Get IP and wait 20-25 minutes
terraform output vm_external_ip
```

## Access
```
Frontend: http://<IP>:2012
SSH: ssh root@<IP>
```

## Cleanup
```bash
terraform destroy -auto-approve
```

📖 **Full guide**: [TECHZONE_DEPLOYMENT.md](TECHZONE_DEPLOYMENT.md)
