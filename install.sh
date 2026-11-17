#!/usr/bin/env bash
# Gambit install script — Ubuntu 24.04
# Installs Gambit as a systemd service running on port 5001.
# Usage: bash install.sh

set -e

REPO_URL="https://github.com/bsookying/Gambit-The-Syslog-Generator"
INSTALL_DIR="$HOME/gambit"
SERVICE_NAME="gambit"
PORT=5001

echo "==> Updating packages..."
sudo apt-get update -y

echo "==> Installing system dependencies..."
sudo apt-get install -y git python3 python3-pip python3-venv

echo "==> Cloning Gambit to $INSTALL_DIR..."
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "    Repo already present — pulling latest..."
    git -C "$INSTALL_DIR" pull origin main
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo "==> Creating Python virtual environment..."
python3 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet
"$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt" --quiet

echo "==> Writing systemd unit file..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=Gambit Syslog Generator
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/venv/bin/python3 ${INSTALL_DIR}/Gambit.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "==> Enabling and starting Gambit service..."
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

echo ""
echo "=============================="
echo " Gambit is up:"
echo " http://$(hostname -I | awk '{print $1}'):${PORT}"
echo "=============================="
sudo systemctl status ${SERVICE_NAME} --no-pager
