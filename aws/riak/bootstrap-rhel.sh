#!/bin/bash
set -e

# Set the local private ip
LOCAL_IP=$(curl http://instance-data/latest/meta-data/local-ipv4)

# Read the package path
PACKAGE=$(cat /tmp/package | tr -d '\n')
PACKAGE_FILE_NAME=$(basename $PACKAGE)

echo "Installing dependencies..."
sudo yum install -y wget

echo "Fetching Riak..."
wget $PACKAGE

echo "Installing Riak..."
sudo yum install -y $PACKAGE_FILE_NAME 

echo "Set Riak to start on boot"
sudo /sbin/chkconfig riak on

echo "Setting ulimit..."
echo 'riak soft nofile 65536' | sudo tee --append /etc/security/limits.conf
echo 'riak hard nofile 65536' | sudo tee --append /etc/security/limits.conf
echo "$USER soft nofile 65536" | sudo tee --append /etc/security/limits.conf
echo "$USER hard nofile 65536" | sudo tee --append /etc/security/limits.conf

echo "Configuring Riak..."
echo "nodename = riak@$LOCAL_IP" | sudo tee --append /etc/riak/riak.conf
echo "listener.http.internal = $LOCAL_IP:8098" | sudo tee --append /etc/riak/riak.conf
echo "listener.protobuf.internal = $LOCAL_IP:8087" | sudo tee --append /etc/riak/riak.conf
sudo sed -i "s/127.0.0.1/$LOCAL_IP/" /etc/riak/riak_shell.config

echo "Starting Riak..."
sudo riak start
sudo riak ping
