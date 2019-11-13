#! /bin/bash
# output can be found in /var/log/cloud-init-output.log
echo "---RUNNING UPDATES & INSTALLS---"
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo apt install python-pip -y
sudo apt install python-psycopg2 -y
sudo pip install requests
sudo apt-get install jq -y
#---------------------------------
# MOUNT EXTERNAL VOLUME
#---------------------------------
echo "---MOUNTING EXTERNAL VOLUME---"
mkdir -p /data
# if volume is brand new, create a file system
# to completely wipe a file system use: sudo wipefs --all --force /dev/xvdf
if [ "$(sudo file -s /dev/xvdf)" == "/dev/xvdf: data" ]; then sudo mkfs -t ext4 /dev/xvdf; fi
# mount the volume
sudo mount /dev/xvdf /data
echo UUID=$(findmnt -fn -o UUID /dev/xvdf) /data ext4 defaults,nofail 0 2 >> /etc/fstab
mkdir -p /data/rem
#---------------------------------
# SET UP NODE MONITORING
#---------------------------------
echo "---SETTING UP NODE MONITORING---"
cd ~
git clone https://github.com/eon-llc/rem-utils.git
cd /root/rem-utils/node-monitor/
chmod +x node-monitor.sh
sudo sed -i "s|DISCORD_CHANNEL=.*|DISCORD_CHANNEL='${discord_channel}'|" config.conf
sudo sed -i "s|NODE_NAME=.*|NODE_NAME='Full'|" config.conf
sudo sed -i "s|IS_BP=.*|IS_BP=false|" config.conf
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
echo 'plugin = eosio::http_plugin
plugin = eosio::chain_plugin
plugin = eosio::chain_api_plugin
plugin = eosio::net_api_plugin
plugin = eosio::state_history_plugin
state-history-dir = "/data/rem/shpdata"
trace-history = true
chain-state-history = true
state-history-endpoint = 0.0.0.0:8080
abi-serializer-max-time-ms = 15000
chain-state-db-size-mb =  100480
http-validate-host = false
http-server-address = 0.0.0.0:8888
p2p-listen-endpoint = 0.0.0.0:9876
verbose-http-errors = true' > ./config/config.ini
# remove self from peers before appending to config
sed -e '/# https:\/\/eon.llc/,+2d' /root/rem-utils/peer-lists/testnet.ini >> ./config/config.ini
# start the node, running in the background
# if we need to delete all blocks: --delete-all-blocks --genesis-json /root/genesis.json
# if "database dirty flag set": --replay-blockchain --hard-replay-blockchain
remnode --config-dir /root/config/ --data-dir /data/rem/ --state-history-dir /data/rem/shpdata --disable-replay-opts >> /data/rem/remnode.log 2>&1 &
#---------------------------------
# INSTALL HYPERION HISTORY API
# https://github.com/boscore/Hyperion-History-API/blob/master/INSTALL.md
#---------------------------------
echo "---INSTALL HYPERION HISTORY API---"
# install nodejs
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y nodejs

# install pm2
sudo npm install pm2@latest -g
sudo pm2 startup

# install ElasticSearch
# curl http://localhost:9200
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch -y
sudo service elasticsearch stop
sed -i "s/#cluster.name:.*/cluster.name: boshyperion/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/#bootstrap.memory_lock:.*/bootstrap.memory_lock: true/" /etc/elasticsearch/elasticsearch.yml
sed -i "s|path.data:.*|path.data: /data/elasticsearch|" /etc/elasticsearch/elasticsearch.yml
sed -i "s|path.logs:.*|path.logs: /data/elasticsearch/log|" /etc/elasticsearch/elasticsearch.yml
sed -i "s|/var/lib/elasticsearch|/data/elasticsearch|g" /etc/elasticsearch/jvm.options
sed -i "s|/var/log/elasticsearch|/data/elasticsearch/log|g" /etc/elasticsearch/jvm.options
sudo mv /var/lib/elasticsearch /data
mkdir -p /data/elasticsearch/log
chown elasticsearch:elasticsearch /data/elasticsearch/log
sudo mv /var/log/elasticsearch/* /data/elasticsearch/log

mkdir /etc/systemd/system/elasticsearch.service.d
echo -e "[Service]\nLimitMEMLOCK=infinity" > /etc/systemd/system/elasticsearch.service.d/override.conf
sudo systemctl daemon-reload

sudo service elasticsearch start
sudo systemctl enable elasticsearch

# install Kibana
# curl http://localhost:5601 -v
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.4.0-amd64.deb
sudo apt install ./kibana-7.4.0-amd64.deb
sudo /lib/systemd/systemd-sysv-install enable kibana
sudo systemctl enable kibana
sudo service kibana start

# Install RabbitMQ
# curl http://localhost:15672 -v
sudo apt-get install curl gnupg -y
# Install RabbitMQ signing key
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo apt-key add -
# Add Bintray repositories that provision latest RabbitMQ and Erlang 21.x releases
sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
## Installs the latest Erlang 21.x release.
## Change component to "erlang" to install the latest version (22.x or later).
## "bionic" as distribution name should work for any later Ubuntu or Debian release.
## See the release to distribution mapping table in RabbitMQ doc guides to learn more.
deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang-21.x
deb https://dl.bintray.com/rabbitmq/debian bionic main
EOF
# Update package indices
sudo apt-get update -y
# Install rabbitmq-server and its dependencies
sudo apt-get install rabbitmq-server -y --fix-missing
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl add_vhost /hyperion
sudo rabbitmqctl add_user ${hyperion_user} ${hyperion_pass}
sudo rabbitmqctl set_user_tags ${hyperion_user} administrator
sudo rabbitmqctl set_permissions -p /hyperion ${hyperion_user} ".*" ".*" ".*"
sudo service rabbitmq-server stop
echo 'RABBITMQ_MNESIA_BASE=/data/rabbitmq/mnesia
RABBITMQ_LOG_BASE=/data/rabbitmq/log
' > /etc/rabbitmq/rabbitmq-env.conf
mkdir -p /data/rabbitmq
sudo chown rabbitmq:rabbitmq /data/rabbitmq/
sudo mv -v /var/lib/rabbitmq/* /data/rabbitmq/
sudo service rabbitmq-server start

# install Redis
sudo apt install redis-server -y
sudo systemctl restart redis.service

# install Hyperion Indexer
# sudo pm2 logs
sudo chown -R $USER:$(id -gn $USER) ~/.config

git clone https://github.com/Remmeauth/Hyperion-History-API.git
cd Hyperion-History-API
npm install
cp example-ecosystem.config.js ecosystem.config.js
cp example-connections.json connections.json
sed -i '0,/name:/{s/"user":.*,/"user": "${hyperion_user}",/}' connections.json
sed -i '0,/name:/{s/"pass":.*,/"pass": "${hyperion_pass}",/}' connections.json
sed -i 's/"eos": {/"rem": {/' connections.json
sed -i "s/SERVER_NAME:.*,/SERVER_NAME: 'rem.eon.llc',/" ecosystem.config.js
sed -i "s/CHAIN:.*,/CHAIN: 'rem',/" ecosystem.config.js
sed -i "s/SYSTEM_DOMAIN:.*,/SYSTEM_DOMAIN: 'rem',/" ecosystem.config.js
#---------------------------------
# NGINX REVERSE PROXY
#---------------------------------
echo "---NGINX REVERSE PROXY---"
# sudo nginx -t
apt-get install nginx -y
unlink /etc/nginx/sites-enabled/default
echo 'server {
    listen 443 ssl;
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name rem.eon.llc;

    client_max_body_size 500m;
    access_log /var/log/nginx/api.boscore.io.access.log;
    error_log /var/log/nginx/api.boscore.io.error.log;

    # add_header "Access-Control-Allow-Origin" "*";
    # add_header "Access-Control-Allow-Credentials" "true";
    add_header "Access-Control-Allow-Headers" "Origin, X-Requested-With, Content-Type, Authorization, X-Custom-Header, token, timestamp, version";
    add_header "Access-Control-Expose-Headers" "*";
    add_header "Access-Control-Allow-Methods" "*";
    add_header "Access-Control-Max-Age" 600;
    add_header "Allow" "GET, HEAD, POST, PUT, DELETE, TRACE, OPTIONS, PATCH";
    add_header "Vary" "Origin";

    location / {
        proxy_pass http://127.0.0.1:8888/v1/chain/get_info;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
        proxy_headers_hash_bucket_size 128;
    }

    location /v2 {
        proxy_pass http://127.0.0.1:7000/v2;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
        proxy_headers_hash_bucket_size 128;
    }

    location /v1/history {
        proxy_pass http://127.0.0.1:7000/v1/history;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
        proxy_headers_hash_bucket_size 128;
    }

    location /v1 {
        proxy_pass http://127.0.0.1:8888;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
        proxy_headers_hash_bucket_size 128;
    }
}' > /etc/nginx/sites-available/reverse-proxy.conf
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo systemctl enable nginx
#---------------------------------
# INSTALL AND INIT SSL CERT
#---------------------------------
echo "---INSTALL AND INIT SSL CERT---"
sudo apt-get install software-properties-common -y
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt-get update
sudo apt-get install certbot python-certbot-nginx -y
sudo certbot --nginx --noninteractive --agree-tos --email support@eon.llc --domains rem.eon.llc
sudo certbot renew --dry-run
#---------------------------------
# INSTALL BENCHMARK SCRIPT
#---------------------------------
echo "---INSTALLING BENCHMARK SCRIPT---"
cd ~
# initialize wallet
remvault &
remcli wallet create --file walletpass
# wallet is unlocked by default
# remcli wallet unlock < walletpass
# pipe private key as answer to import prompt
echo ${benchmark_private_key} | remcli wallet import
# configure benchmark script
git clone https://github.com/eon-llc/rem-benchmark.git
cd /root/rem-benchmark/scripts/
chmod +x benchmark-check.sh
sed -i "s/conn =.*/conn = psycopg2.connect(database='${benchmark_db}', user='${benchmark_user}', password='${benchmark_pass}', host='${benchmark_db_ip}', port='${benchmark_db_port}')/" log_to_db.py
sed -i "s/table_name =.*/table_name = '${benchmark_table}'/" log_to_db.py
./benchmark-check.sh &>/dev/null &
#---------------------------------
# START PROCESSES
#---------------------------------
# set environment variables
nohup ~/history-tools/build/combo-rocksdb --rdb-database /data/rocksdb &> /dev/null &
echo "---CREATING REBOOT INSTRUCTIONS---"
# restart all processes on reboot, resize mounted volume
echo '#!/bin/bash
sudo resize2fs /dev/xvdf
remnode --config-dir /root/config/ --data-dir /data/rem/ --state-history-dir /data/rem/shpdata --disable-replay-opts >> /data/rem/remnode.log 2>&1 &
nohup ~/history-tools/build/combo-rocksdb --rdb-database /data/rocksdb &> /dev/null &
exit 0' > /etc/rc.local
sudo chmod +x /etc/rc.local
#---------------------------------
#SET UP GRACEFUL SHUTDOWN
#---------------------------------
echo "---SET UP GRACEFUL SHUTDOWN---"
echo '#!/bin/sh

remnode_pid=$(pgrep remnode)

if [ ! -z "$remnode_pid" ]; then
    if ps -p $remnode_pid > /dev/null; then
        kill -SIGINT $remnode_pid
    fi

    while ps -p $remnode_pid > /dev/null; do
        sleep 1
    done
fi
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
sudo rm kibana-7.4.0-amd64.deb \
    eosio.cdt_1.6.2-1-ubuntu-18.04_amd64.deb \
    remprotocol_0.2.1-1_amd64.deb
echo "---SETUP COMPLETE---"