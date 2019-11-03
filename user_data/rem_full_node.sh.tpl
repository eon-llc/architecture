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
mkdir -p /external
mkdir -p /external/rem
mkdir -p /external/rocksdb
# if volume is brand new, create a file system
# to completely wipe a file system use: sudo wipefs --all --force /dev/xvdf
if [ "$(sudo file -s /dev/xvdf)" == "/dev/xvdf: data" ]; then sudo mkfs -t ext4 /dev/xvdf; fi
# mount the volume
sudo mount /dev/xvdf /external
echo UUID=$(findmnt -fn -o UUID /dev/xvdf) /external ext4 defaults,nofail 0 2 >> /etc/fstab
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
remnode --config-dir /root/config/ --data-dir /external/rem/ --state-history-dir /external/rem/shpdata --disable-replay-opts >> /external/rem/remnode.log 2>&1 &
#---------------------------------
# INSTALL HISTORY TOOLS
# https://eosio.github.io/history-tools/build-ubuntu-1804.html
#---------------------------------
# install build environment
apt update && apt install -y wget gnupg
cd ~
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
cat <<EOT >>/etc/apt/sources.list
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic main
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main
EOT

apt update && apt install -y \
    autoconf2.13        \
    build-essential     \
    bzip2               \
    cargo               \
    clang-8             \
    git                 \
    libgmp-dev          \
    libpq-dev           \
    lld-8               \
    lldb-8              \
    ninja-build         \
    nodejs              \
    npm                 \
    pkg-config          \
    postgresql-server-dev-all \
    python2.7-dev       \
    python3-dev         \
    rustc               \
    zlib1g-dev

update-alternatives --install /usr/bin/clang clang /usr/bin/clang-8 100
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-8 100

# build boost
cd ~
wget https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz
tar xf boost_1_70_0.tar.gz
cd boost_1_70_0
./bootstrap.sh
./b2 toolset=clang -j10 install

# build cmake
cd ~
wget https://github.com/Kitware/CMake/releases/download/v3.14.5/cmake-3.14.5.tar.gz
tar xf cmake-3.14.5.tar.gz
cd cmake-3.14.5
./bootstrap --parallel=10
make -j10
make -j10 install

# install CDT
cd ~
wget https://github.com/EOSIO/eosio.cdt/releases/download/v1.6.2/eosio.cdt_1.6.2-1-ubuntu-18.04_amd64.deb
sudo apt install -y ./eosio.cdt_1.6.2-1-ubuntu-18.04_amd64.deb

# build history tools
cd ~
git clone --recursive https://github.com/EOSIO/history-tools.git
cd history-tools
mkdir build
cd build
cmake -GNinja -DCMAKE_CXX_COMPILER=clang++-8 -DCMAKE_C_COMPILER=clang-8 ..
bash -c "cd ../src && npm install node-fetch"
ninja
#---------------------------------
# NGINX REVERSE PROXY
#---------------------------------
apt-get install nginx -y
unlink /etc/nginx/sites-enabled/default
echo 'server {
    listen 443 ssl;
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name rem.eon.llc;

    types {
        application/wasm wasm;
        text/html html;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    location /v1/ {
        proxy_pass http://127.0.0.1:8888;
    }

    location /wasmql/ {
        proxy_pass http://127.0.0.1:8880;
    }
}' > /etc/nginx/sites-available/reverse-proxy.conf
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo systemctl enable nginx
#---------------------------------
# INSTALL AND INIT SSL CERT
#---------------------------------
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
nohup ~/history-tools/build/combo-rocksdb --rdb-database /external/rocksdb &> /dev/null &
echo "---CREATING REBOOT INSTRUCTIONS---"
# restart all processes on reboot, resize mounted volume
echo '#!/bin/bash
sudo resize2fs /dev/xvdf
remnode --config-dir /root/config/ --data-dir /external/rem/ --state-history-dir /external/rem/shpdata --disable-replay-opts >> /external/rem/remnode.log 2>&1 &
nohup ~/history-tools/build/combo-rocksdb --rdb-database /external/rocksdb &> /dev/null &
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
RequiresMountsFor=/external
Requires=network-online.target network.target external.mount

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
cd ~
sudo apt autoremove -y
sudo rm boost_1_70_0.tar.gz \
    cmake-3.14.5.tar.gz \
    eosio.cdt_1.6.2-1-ubuntu-18.04_amd64.deb \
    remprotocol_0.2.1-1_amd64.deb