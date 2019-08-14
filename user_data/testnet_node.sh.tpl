#! /bin/bash
# output can be found in /var/log/cloud-init-output.log
sudo apt-get update
sudo apt-get install
# install remcli
cd /root
wget https://github.com/Remmeauth/remprotocol/releases/download/0.1.0/remprotocol_0.1.0-ubuntu-18.04_amd64.deb
sudo apt install ./remprotocol_0.1.0-ubuntu-18.04_amd64.deb
# fetch config
wget https://testchain.remme.io/genesis.json
# set up working directory
mkdir data
mkdir config
# create config file
echo 'plugin = eosio::chain_api_plugin
plugin = eosio::net_api_plugin
http-server-address = 0.0.0.0:8888
p2p-listen-endpoint = 0.0.0.0:9876
p2p-peer-address = 167.71.88.152:9877
verbose-http-errors = true
plugin = eosio::producer_plugin
plugin = eosio::producer_api_plugin
producer-name = ${account_name}
signature-provider = ${public_key}=KEY:${private_key}' > ./config/config.ini
# start the node, running in the background
remnode --config-dir ./config/ --data-dir ./data/ --delete-all-blocks --genesis-json genesis.json >> remnode.log 2>&1 &
# initialize wallet
remvault &
remcli wallet create --file walletpass
# wallet is unlocked by default
# remcli wallet unlock < walletpass
# pipe private key as answer to import prompt
echo ${private_key} | remcli wallet import
remcli system regproducer ${account_name} ${public_key} ${domain}