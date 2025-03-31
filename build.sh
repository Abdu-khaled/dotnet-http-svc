#!/bin/bash
set -e  # Exit immediately if any error occurs
exec > >(tee /var/log/user-data.log) 2>&1  # Log all output

# Configuration
REPO_URL="https://github.com/Abdu-khaled/dotnet-http-svc.git"
REPO_DIR="/home/ubuntu/dotnet-http-svc"
SERVICE_NAME="dotnet-http-svc"
DLL_NAME="srv02.dll"  

echo "=== Starting deployment ==="
echo "Current working directory: $(pwd)"

# Update system and install dependencies
echo "=== Updating system packages ==="
apt-get update -y

echo "=== Installing dependencies ==="
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    aspnetcore-runtime-6.0 \
    dotnet-sdk-6.0 \
    git \
    unzip \
    libssl-dev \
    ca-certificates

# Install AWS CLI (useful for EC2 instances)
echo "=== Installing AWS CLI ==="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qq awscliv2.zip
./aws/install --update
rm -rf awscliv2.zip aws/

# Configure Git (as ubuntu user)
echo "=== Configuring Git ==="
sudo -u ubuntu git config --global --add safe.directory '*'

# Clone or update repository
echo "=== Setting up application repository ==="
if [ -d "$REPO_DIR" ]; then
    echo "Repository exists. Pulling latest changes..."
    cd "$REPO_DIR"
    sudo -u ubuntu git pull
else
    echo "Cloning new repository..."
    sudo -u ubuntu git clone "$REPO_URL" "$REPO_DIR"
fi

# Build the application
echo "=== Building .NET application ==="
cd "$REPO_DIR" || { echo "❌ Error: Could not enter $REPO_DIR"; exit 1; }
export DOTNET_CLI_HOME=/tmp
sudo -u ubuntu dotnet restore
sudo -u ubuntu dotnet publish -c Release --self-contained=false --runtime linux-x64

# Create systemd service
echo "=== Creating systemd service ==="
cat > /etc/systemd/system/"$SERVICE_NAME.service" <<EOL
[Unit]
Description=Dotnet HTTP Service

[Service]
User=ubuntu
WorkingDirectory=$REPO_DIR
ExecStart=/usr/bin/dotnet $REPO_DIR/bin/Release/netcoreapp6/linux-x64/$DLL_NAME
Restart=always
RestartSec=5
KillSignal=SIGINT
Environment=DOTNET_CLI_HOME=/tmp
Environment=ASPNETCORE_URLS=http://*:5000
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
EOL

# Enable and start service
echo "=== Enabling and starting service ==="
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Verify service status
echo "=== Service status ==="
systemctl status "$SERVICE_NAME" --no-pager

echo "=== Deployment completed successfully! ==="