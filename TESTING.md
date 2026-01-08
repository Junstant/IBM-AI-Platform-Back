# 🧪 Testing Guide

## Quick Validation

### Terraform Validation
```bash
terraform fmt -check
terraform validate
terraform plan
```

### Deploy Test
```bash
export IC_API_KEY="your-key"
terraform apply
IP=$(terraform output -raw vm_external_ip)
```

### Monitor Cloud-init
```bash
ssh root@$IP "tail -f /var/log/cloud-init-output.log"
ssh root@$IP "cloud-init status"
```

### Verify Services
```bash
ssh root@$IP "docker ps"  # Should show ~15 containers
ssh root@$IP "docker ps -q | wc -l"
```

### API Testing
```bash
curl http://$IP:2012  # Frontend
curl http://$IP:8003/health  # Stats API
curl http://$IP:8004/health  # RAG API
curl http://$IP:8000/docs  # TextoSQL API
```

## System Resources
```bash
ssh root@$IP "df -h"  # Disk space
ssh root@$IP "docker system df"  # Docker usage
ssh root@$IP "netstat -tuln | grep LISTEN"  # Open ports
```

## Troubleshooting

**Cloud-init not complete**: ssh root@ "journalctl -u cloud-init -n 100"
**Container not starting**: ssh root@ "docker logs <container>"
**Disk full**: ssh root@ "docker system prune -af"
**Re-run setup**: ssh root@ "cd /root && ./setup.sh"

## Cleanup
```bash
terraform state pull > backup.json
terraform destroy
```

## Success Criteria

- [x] 	erraform apply completes without errors
- [x] VM has external IP assigned
- [x] Cloud-init status: done
- [x] ~15 Docker containers running
- [x] Frontend accessible on :2012
- [x] APIs responding on :8000-8004

---
**Test Duration**: ~5-10 minutes
