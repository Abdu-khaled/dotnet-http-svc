# .NET HTTP Service on AWS EC2

## Overview
This project automates the deployment of a .NET 6.0 HTTP service on AWS EC2, configuring it to listen on a specified port through the instance's public IP. The solution uses EC2 User Data scripts for zero-touch deployment.

## Key Features
- **Automated deployment** via EC2 User Data scripts
- **Self-healing service** with systemd auto-restart
- **Port-configurable** HTTP endpoint (default: 5000)
- **Production-ready** with proper service isolation
- **Comprehensive logging** for easy troubleshooting

## Deployment Architecture
```
[Internet]
    |
[EC2 Instance]
    ├── Security Group (Ports 22/5000)
    ├── .NET 6.0 Runtime
    └── Systemd Service
        └── Your .NET Application
            └── Listening on *:5000
```

## Quick Start
1. Launch EC2 instance (Ubuntu 22.04)
2. Configure Security Group to allow:
   - SSH (Port 22) from your IP
   - HTTP (Port 5000) from 0.0.0.0/0
3. Paste the User Data script during launch
4. Access service at `http://<EC2_PUBLIC_IP>:5000`

## Maintenance
**Update Service:**
```bash
cd /home/ubuntu/dotnet-http-svc
git pull
sudo systemctl restart dotnet-http-svc
```

**View Logs:**
```bash
journalctl -u dotnet-http-svc -f
```

## Customization
| Variable          | Description                          | Default Value              |
|-------------------|--------------------------------------|----------------------------|
| `REPO_URL`        | GitHub repository URL                | Your .NET project repo     |
| `PORT`            | HTTP listening port                 | 5000                       |
| `DLL_NAME`        | Entry point DLL                     | srv02.dll                  |

## Best Practices
- Use Elastic IP for static public IP
- Configure CloudWatch for log aggregation
- Consider HTTPS termination (via ALB or NGINX)

## Troubleshooting
```bash
# Check initialization logs
cat /var/log/user-data.log

# Verify service status
systemctl status dotnet-http-svc

# Test connectivity
curl -v http://localhost:5000
```

## Security Notes
- Service runs under non-root `ubuntu` user
- Regular security updates via `unattended-upgrades`
- Network restricted to necessary ports only

This automated solution provides a robust foundation for hosting .NET web services on AWS, with production-grade reliability and minimal maintenance overhead.