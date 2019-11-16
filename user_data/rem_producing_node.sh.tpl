#! /bin/bash
# output can be found in /var/log/cloud-init-output.log
echo "---RUNNING UPDATES & INSTALLS---"
sudo apt update
sudo apt upgrade -y DEBIAN_FRONTEND=noninteractive
sudo apt-get install jq -y
sudo apt-get install unzip -y
sudo apt-get install libwww-perl libdatetime-perl -y
#---------------------------------
# MOUNT EXTERNAL VOLUME
#---------------------------------
# create mount directory, mount, resize, mount on reboot
echo "---MOUNTING EXTERNAL VOLUME---"
mkdir -p /data
# if volume is brand new, create a file system
# to completely wipe a file system use: sudo wipefs --all --force /dev/nvme1n1
if [ "$(sudo file -s /dev/nvme1n1)" == "/dev/nvme1n1: data" ]; then sudo mkfs -t ext4 /dev/nvme1n1; fi
# mount the volume
sudo mount /dev/nvme1n1 /data
echo UUID=$(findmnt -fn -o UUID /dev/nvme1n1) /data ext4 defaults,nofail 0 2 >> /etc/fstab
#---------------------------------
# SET UP AWS MONITORING
#---------------------------------
echo "---SETTING UP AWS MONITORING---"
cd ~
curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip && \
rm CloudWatchMonitoringScripts-1.2.2.zip && \
cd aws-scripts-mon
echo 'AWSAccessKeyId=${cw_access_key}
AWSSecretKey=${cw_secret_key}' > awscreds.conf
(crontab -l ; echo "*/5 * * * * /root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --disk-space-util --disk-space-used --disk-space-avail --disk-path=/ --disk-path=/data --from-cron") | crontab -
#---------------------------------
# SET UP NODE MONITORING
#---------------------------------
echo "---SETTING UP NODE MONITORING---"
cd ~
git clone https://github.com/eon-llc/rem-utils.git
cd /root/rem-utils/node-monitor/
chmod +x node-monitor.sh
sudo sed -i "s|DISCORD_CHANNEL=.*|DISCORD_CHANNEL='${discord_channel}'|" config.conf
sudo sed -i "s|NODE_NAME=.*|NODE_NAME='Producer'|" config.conf
sudo sed -i "s|IS_BP=.*|IS_BP=true|" config.conf
sudo sed -i "s|ACCOUNT_NAME=.*|ACCOUNT_NAME='${account_name}'|" config.conf
sudo sed -i "s|PERMISSION_NAME=.*|PERMISSION_NAME='${permission_name}'|" config.conf
./node-monitor.sh &>/dev/null &
#---------------------------------
# INSTALL REMCLI
#---------------------------------
echo "---INSTALLING REMCLI---"
cd ~
wget https://github.com/Remmeauth/remprotocol/releases/download/0.2.1/remprotocol_0.2.1-1_amd64.deb
sudo apt install ./remprotocol_0.2.1-1_amd64.deb
# fetch config
wget https://testchain.remme.io/genesis.json
# set up working directory
mkdir -p ./config
# create config file
echo "---CONFIGURING REMCLI---"
echo 'plugin = eosio::chain_api_plugin
plugin = eosio::net_api_plugin
chain-state-db-size-mb = 100480
reversible-blocks-db-size-mb = 10480
http-server-address = 0.0.0.0:8888
p2p-listen-endpoint = 0.0.0.0:9876
verbose-http-errors = true
plugin = eosio::producer_plugin
plugin = eosio::producer_api_plugin
producer-name = ${account_name}
signature-provider = ${public_key}=KEY:${private_key}

plugin = eosio::eth_swap_plugin
swap-authority = ${account_name}@${permission_name}
swap-signing-key = ${private_key}
eth-wss-provider = ${eth_wss_provider}
eth_swap_contract_address=0x39882ab5105b1d627e6aed3ff39c1b004a18e207
return_chain_id=ethropsten

plugin = eosio::rem_oracle_plugin
cryptocompare-apikey = ${cryptocompare_api_key}
oracle-authority = ${account_name}@${permission_name}
oracle-signing-key = ${private_key}
' > ./config/config.ini
# remove self from peers before appending to config
sed -e '/# https:\/\/eon.llc/,+2d' /root/rem-utils/peer-lists/testnet.ini >> ./config/config.ini
#---------------------------------
# START PROCESSES
#---------------------------------
# start the node, running in the background
echo "---STARTING PROCESSES---"
# if we need to delete all blocks: --delete-all-blocks --genesis-json /root/genesis.json
# if "database dirty flag set": --replay-blockchain --hard-replay-blockchain
remnode --config-dir /root/config/ --data-dir /data/ >> /data/remnode.log 2>&1 &
# make sure this process is restarted on reboot
echo '#!/bin/bash
sudo resize2fs /dev/nvme1n1
remnode --config-dir /root/config/ --data-dir /data/ >> /data/remnode.log 2>&1 &
exit 0' > /etc/rc.local
sudo chmod +x /etc/rc.local
# initialize wallet
remvault &
remcli wallet create --file walletpass
# wallet is unlocked by default
# remcli wallet unlock < walletpass
# pipe private key as answer to import prompt
echo ${private_key} | remcli wallet import
#---------------------------------
#SET UP GRACEFUL SHUTDOWN
#---------------------------------
echo "---SET UP GRACEFUL SHUTDOWN---"
echo '#!/bin/sh

echo "starting to shut down on $(date)" >> /data/shutdown.txt

remnode_pid=$(pgrep remnode)

if [ ! -z "$remnode_pid" ]; then
    if ps -p $remnode_pid > /dev/null; then
        kill -SIGINT $remnode_pid
    fi

    while ps -p $remnode_pid > /dev/null; do
        sleep 1
    done
fi

echo "shut down on $(date)" >> /data/shutdown.txt

' > /root/node_shutdown.sh
echo '[Unit]
Description=Gracefully shut down remnode to avoid database dirty flag
DefaultDependencies=no
After=poweroff.target shutdown.target reboot.target halt.target kexec.target
Requires=network-online.target network.target

[Service]
Type=oneshot
ExecStop=/root/node_shutdown.sh
RemainAfterExit=yes
KillMode=none

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/node_shutdown.service
sudo chmod +x /root/node_shutdown.sh
systemctl daemon-reload
systemctl enable node_shutdown
systemctl restart node_shutdown
#---------------------------------
#CLEANUP
#---------------------------------
echo "---CLEANING UP---"
cd ~
sudo apt autoremove -y
sudo rm remprotocol_0.1.0-ubuntu-18.04_amd64.deb
echo "---SETUP COMPLETE---"