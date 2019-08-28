#! /bin/bash
# output can be found in /var/log/cloud-init-output.log
sudo apt update
sudo apt upgrade -y DEBIAN_FRONTEND=noninteractive
sudo apt autoremove -y
# create mount directory, mount, resize, mount on reboot
mkdir /data
# if volume is brand new: sudo mkfs -t ext4 /dev/nvme1n1
sudo mount /dev/nvme1n1 /data
sudo resize2fs /dev/nvme1n1
echo /dev/nvme1n1 /data ext4 defaults,nofail 0 2 >> /etc/fstab
# install remcli
cd /root
wget https://github.com/Remmeauth/remprotocol/releases/download/0.1.0/remprotocol_0.1.0-ubuntu-18.04_amd64.deb
sudo apt install ./remprotocol_0.1.0-ubuntu-18.04_amd64.deb
# fetch config
wget https://testchain.remme.io/genesis.json
# set up working directory
mkdir config
# create config file
echo 'plugin = eosio::chain_api_plugin
plugin = eosio::net_api_plugin
plugin = eosio::wallet_api_plugin
http-server-address = 0.0.0.0:8888
p2p-listen-endpoint = 0.0.0.0:9876
p2p-peer-address = ${rem_peer_address}
verbose-http-errors = true
plugin = eosio::producer_plugin
plugin = eosio::producer_api_plugin
producer-name = ${account_name}
signature-provider = ${public_key}=KEY:${private_key}' > ./config/config.ini
# start the node, running in the background
remnode --config-dir ./config/ --data-dir /data/ --genesis-json genesis.json >> /data/remnode.log 2>&1 &
# make sure this process is restarted on reboot, resize mounted volume
echo '#!/bin/sh -e
sudo resize2fs /dev/nvme1n1
remnode --config-dir ./config/ --data-dir /data/ >> /data/remnode.log 2>&1 &
exit 0' > /etc/rc.local
sudo chmod +x /etc/rc.local
# initialize wallet
remvault &
remcli wallet create --file walletpass
# wallet is unlocked by default
# remcli wallet unlock < walletpass
# pipe private key as answer to import prompt
echo ${private_key} | remcli wallet import
remcli system regproducer ${account_name} ${public_key} ${domain}
remcli system voteproducer prods ${account_name} ${account_name}