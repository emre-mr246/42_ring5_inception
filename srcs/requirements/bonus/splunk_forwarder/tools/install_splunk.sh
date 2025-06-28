#!/bin/bash

SPLUNK_USER="${SPLUNK_USER}"
SPLUNK_INDEX="${SPLUNK_INDEX}"
LOG_PATH="${LOG_PATH}"
SPLUNK_PASS=$(cat /run/secrets/splunk_forwarder_pass)
SPLUNK_SERVER=$(cat /run/secrets/splunk_server_ip)

echo "Installing Splunk Universal Forwarder..."
tar -xzf /tmp/splunkforwarder.tgz -C /opt
rm /tmp/splunkforwarder.tgz

echo "export SPLUNK_HOME=/opt/splunkforwarder" >> ~/.bashrc

echo "Configuring Splunk Universal Forwarder..."
mkdir -p "/opt/splunkforwarder/etc/system/local"

echo "Creating user-seed.conf..."
cat > "/opt/splunkforwarder/etc/system/local/user-seed.conf" <<EOF
[user_info]
USERNAME = $SPLUNK_USER
PASSWORD = $SPLUNK_PASS
EOF

echo "Configuring SSL certificate validation..."
cat > "/opt/splunkforwarder/etc/system/local/server.conf" <<EOF
[sslConfig]
enableSplunkdSSL = true
sslVerifyServerCert = true
EOF

echo "Creating secure splunk-launch.conf..."
cat > "/opt/splunkforwarder/etc/splunk-launch.conf" <<EOF
SPLUNK_HOME=/opt/splunkforwarder
SPLUNK_SERVER_NAME=Splunkd
SPLUNK_WEB_NAME=splunkweb
PYTHONHTTPSVERIFY=1
EOF

cd /opt/splunkforwarder/bin

echo "Starting Splunk Universal Forwarder for initial setup..."
./splunk start --accept-license --answer-yes --no-prompt

tee "/opt/splunkforwarder/etc/system/local/inputs.conf" > /dev/null <<EOF
[monitor://$LOG_PATH]
disabled = false
index = $SPLUNK_INDEX
followTail = 1
recursive = true
EOF

tee "/opt/splunkforwarder/etc/system/local/outputs.conf" > /dev/null <<EOF
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = $SPLUNK_SERVER

[tcpout-server://$SPLUNK_SERVER]
sendCookedData = true
EOF

echo "Stopping Splunk for foreground configuration..."
./splunk stop

echo "Splunk Universal Forwarder installed and configured successfully."