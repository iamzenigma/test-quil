#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <new_version>"
  exit 1
fi

NEW_VERSION=$1
SERVICE_FILE=/etc/systemd/system/ceremonyclient.service

# Stop service
sudo systemctl stop ceremonyclient

# Update repository
cd ~/ceremonyclient
git pull
git checkout release

# Remove old version
cd ~/ceremonyclient/node
sudo rm -v node-*-linux-amd64*

# Get amd64 release
list_url="https://releases.quilibrium.com/release"
base_url="https://releases.quilibrium.com"
file_list=$(curl -s $list_url)
amd64_files=$(echo "$file_list" | grep 'node-.*-linux-amd64')

for file in $amd64_files; do
  wget -qO- "${base_url}/${file}" -O "${file}"
  
  if [ $? -eq 0 ]; then
    echo "Downloaded ${file}"
  else
    echo "Failed to download ${file}"
  fi
done

chmod +x ~/ceremonyclient/node/node-${NEW_VERSION}-linux-amd64

# Replace the version in the service file
sed -i -E "s/node-[0-9]+(\.[0-9]+){1,3}-linux-amd64/node-${NEW_VERSION}-linux-amd64/g" $SERVICE_FILE

echo "Updated version in $SERVICE_FILE to $NEW_VERSION"

# Reload service file
sudo systemctl daemon-reload
sudo systemctl start ceremonyclient
