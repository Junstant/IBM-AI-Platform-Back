# 📦 TechZone Admin Configuration

## Collection Setup

**Type**: Terraform Collection  
**Provider**: IBM Cloud (ibm)  
**Repository**: https://github.com/Junstant/IBM-AI-Platform-Back.git  
**Branch**: main  
**Path**: / (root directory)

## Required Variables

### 1. workspace_guid (required)
- **Type**: String
- **Description**: PowerVS Workspace GUID
- **Validation**: ^[a-f0-9\-]{36}$
- **Help**: Get from IBM Cloud Console → PowerVS → Workspace → Overview

### 2. ssh_public_key (required)
- **Type**: String (multi-line)
- **Description**: SSH public key for instance access
- **Validation**: Must start with ssh-rsa/ssh-ed25519/ecdsa-
- **Help**: Generate with ssh-keygen -t ed25519, then cat ~/.ssh/id_ed25519.pub

### 3. huggingface_token (required)
- **Type**: String (secure/password)
- **Description**: HuggingFace access token for model downloads
- **Sensitive**: Yes
- **Help**: Get from https://huggingface.co/settings/tokens (type: Read)

## Optional Variables

- powervs_region: Dropdown (us-south, us-east, eu-de, eu-gb, jp-tok, au-syd) - Default: us-south
- m_cores: Slider 10-50, step 5 - Default: 25
- m_memory_gb: Slider 64-256, step 16 - Default: 120
- m_sys_type: Dropdown (s922, s1022, e980, e1080) - Default: s1022
- db_password: String (secure) - Default: root

## Outputs to Display

1. **vm_external_ip** - External IP address for all services
2. **ssh_command** - SSH connection command
3. **frontend_url** - Frontend web interface URL
4. **deployment_status** - Deployment progress and information

## Deployment Info

- **Time**: 3-5 min (infrastructure) + 15-20 min (setup) = ~20-25 min total
- **Message**: 
  `
  Your environment is deploying automatically.
  
  Terraform creates infrastructure in 3-5 minutes.
  Cloud-init then runs automated setup (~15-20 min).
  
  Monitor progress: ssh root@<IP> "tail -f /var/log/cloud-init-output.log"
  Frontend available at: http://<IP>:2012
  `

## Prerequisites for Users

1. Active IBM Cloud account
2. PowerVS workspace created in desired region
3. CentOS-Stream-9 image available in workspace
4. HuggingFace account with access token
5. SSH key pair generated

## Testing Checklist

- [ ] Basic deployment with defaults
- [ ] Cloud-init logs show progress without errors
- [ ] ~15 Docker containers running after 20-25 min
- [ ] Frontend accessible on port 2012
- [ ] APIs responding on ports 8000-8004
- [ ] Clean destruction with 	erraform destroy

## Cost Estimation

PowerVS S1022 (Shared):
- 25 cores x .XX/core/hour
- 120GB RAM x .XX/GB/hour
- Public network: .XX/hour
- Storage 50GB: .XX/GB/month

**Estimated**: ~.XX/hour (update with actual IBM pricing)

## Support

- **Issues**: https://github.com/Junstant/IBM-AI-Platform-Back/issues
- **Docs**: See TECHZONE_DEPLOYMENT.md and QUICKSTART.md in repository

---
**Version**: 1.0.0 | **Date**: January 2026 | **Status**: Ready for TechZone
