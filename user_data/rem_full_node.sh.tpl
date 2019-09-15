#! /bin/bash
# output can be found in /var/log/cloud-init-output.log
sudo apt update
sudo apt upgrade -y DEBIAN_FRONTEND=noninteractive
#---------------------------------
# MOUNT EXTERNAL VOLUME
#---------------------------------
mkdir external
mkdir external/rem
mkdir external/rocksdb
# if volume is brand new: sudo mkfs -t ext4 /dev/xvdf
sudo mount /dev/xvdf /external
sudo resize2fs /dev/xvdf
echo /dev/xvdf /external ext4 defaults,nofail 0 2 >> /etc/fstab
#---------------------------------
# INSTALL REMCLI
#---------------------------------
cd ~
wget https://github.com/Remmeauth/remprotocol/releases/download/0.1.0/remprotocol_0.1.0-ubuntu-18.04_amd64.deb
sudo apt install ./remprotocol_0.1.0-ubuntu-18.04_amd64.deb
# fetch config
wget https://testchain.remme.io/genesis.json
# set up working directory
mkdir config
# create config file
echo 'plugin = eosio::http_plugin
plugin = eosio::chain_plugin
plugin = eosio::chain_api_plugin
plugin = eosio::net_api_plugin
plugin = eosio::state_history_plugin
abi-serializer-max-time-ms = 15000
chain-state-db-size-mb =  4096
http-validate-host = false
http-server-address = 0.0.0.0:8888
p2p-listen-endpoint = 0.0.0.0:9876
p2p-peer-address = ${rem_peer_address}
verbose-http-errors = true' > ./config/config.ini
# start the node, running in the background
remnode --config-dir ./config/ --data-dir /external/rem/ --state-history-dir /external/rem/shpdata --disable-replay-opts --genesis-json genesis.json >> /external/rem/remnode.log 2>&1 &
#---------------------------------
# INSTALL HISTORY TOOLS
# https://eosio.github.io/history-tools/build-ubuntu-1804.html
#---------------------------------
# install build environment
sudo apt install -y wget gnupg
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
apt install -y ./eosio.cdt_1.6.2-1-ubuntu-18.04_amd64.deb

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
# START PROCESSES
#---------------------------------
# set environment variables
nohup ~/history-tools/build/combo-rocksdb --rdb-database /external/rocksdb &> /dev/null &
# restart all processes on reboot, resize mounted volume
echo '#!/bin/sh -e
sudo resize2fs /dev/xvdf
remnode --config-dir ./config/ --data-dir /external/rem/ --disable-replay-opts >> /external/rem/remnode.log 2>&1 &
nohup ~/history-tools/build/combo-rocksdb --rdb-database /external/rocksdb &> /dev/null &
exit 0' > /etc/rc.local
sudo chmod +x /etc/rc.local
#---------------------------------
#CLEANUP
#---------------------------------
cd ~
sudo apt autoremove -y
sudo rm boost_1_70_0.tar.gz \
    cmake-3.14.5.tar.gz \
    eosio.cdt_1.6.1-1_amd64.deb \
    remprotocol_0.1.0-ubuntu-18.04_amd64.deb