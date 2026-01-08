# 🚀 IBM TechZone Deployment Guide

Complete guide for automated deployment of IBM AI Platform on PowerVS.

## Overview

Automated infrastructure-as-code deployment creating:
- Public network with SSH access
- PowerVS S1022 (25 cores, 120GB RAM)
- 50GB data volume
- Complete AI platform via cloud-init
- 15+ Docker containers

**Time**: ~20-25 minutes (fully automated)

## Prerequisites

1. IBM Cloud account with PowerVS workspace
2. CentOS-Stream-9 image in workspace
3. IBM Cloud API Key: https://cloud.ibm.com/iam/apikeys
4. HuggingFace token: https://huggingface.co/settings/tokens
5. SSH key pair: ssh-keygen -t ed25519
6. Terraform >= 1.3.0

## Quick Deploy

`ash
export IC_API_KEY="your-key"
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set: workspace_guid, ssh_public_key, huggingface_token
terraform init && terraform apply
terraform output vm_external_ip
`

## Required Configuration

Edit 	erraform.tfvars:
`hcl
workspace_guid    = "your-workspace-guid"
ssh_public_key    = "ssh-ed25519 AAA..."
huggingface_token = "hf_xxx..."
`

## Services & Ports

| Service | Port | URL |
|---------|------|-----|
| Frontend | 2012 | http://IP:2012 |
| Stats API | 8003 | http://IP:8003/docs |
| RAG API | 8004 | http://IP:8004/docs |
| TextoSQL API | 8000 | http://IP:8000/docs |
| Fraud API | 8001 | http://IP:8001/docs |
| PostgreSQL | 8070 | postgresql://postgres:root@IP:8070 |
| Gemma 2B/4B | 8085/8086 | http://IP:808X |
| Mistral 7B | 8088 | http://IP:8088 |
| DeepSeek 8B | 8089 | http://IP:8089 |

## Monitor Deployment

`ash
IP=
ssh root@ "tail -f /var/log/cloud-init-output.log"
ssh root@ "docker ps"
`

## Troubleshooting

**Auth fails**: xport IC_API_KEY="your-key"
**Image not found**: Verify CentOS-Stream-9 in workspace
**Cloud-init fails**: ssh root@ "cat /var/log/cloud-init-output.log"
**Docker issues**: ssh root@ "docker logs <container>"

## Cleanup

`ash
terraform destroy
`

---
**Version**: 1.0.0 | **Status**: Production Ready
