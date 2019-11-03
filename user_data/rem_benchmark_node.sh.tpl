#! /bin/bash
# output can be found in /var/log/cloud-init-output.log
echo "---RUNNING UPDATES & INSTALLS---"
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install golang-go -y
sudo apt-get upgrade -y DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y postgresql postgresql-contrib
#---------------------------------
# MOUNT EXTERNAL VOLUME
#---------------------------------
echo "---MOUNTING EXTERNAL VOLUME---"
mkdir external
# if volume is brand new: sudo mkfs -t ext4 /dev/xvdf
sudo mount /dev/xvdf /external
sudo resize2fs /dev/xvdf
echo /dev/xvdf /external ext4 defaults,nofail 0 2 >> /etc/fstab
#---------------------------------
# POSTGRESQL SETUP
#---------------------------------
# stop the process before modifying config
echo "---STOPPING PSQL---"
sudo systemctl stop postgresql
# if new setup move default data into new location: sudo rsync -av /var/lib/postgresql /external
# enable psql password auth
sudo sed -i "s:local *all *all.*:host  all  all  0.0.0.0/0 md5\nlocal  all  all  peer:" /etc/postgresql/10/main/pg_hba.conf
# point config directory to new location
sudo sed -i "s:data_directory.*:data_directory = '/external/postgresql/10/main':" /etc/postgresql/10/main/postgresql.conf
# allow remote connections
sudo sed -i "s:#listen_addresses.*:listen_addresses = '*':" /etc/postgresql/10/main/postgresql.conf
# restart process for changes to take effect
echo "---STARTING PSQL---"
sudo systemctl start postgresql
sudo systemctl status postgresql
# create DB and user
echo "---RUNNING SETUP QUERIES---"
sudo -u postgres psql -c "CREATE DATABASE ${benchmark_db};"
sudo -u postgres psql -c "CREATE USER ${benchmark_user} PASSWORD '${benchmark_pass}';"
# create table
sudo -u postgres psql -d $benchmark_db -c "CREATE TABLE ${benchmark_table}(
   id SERIAL PRIMARY KEY,
   producer VARCHAR (50) NOT NULL,
   cpu_usage_us INT NOT NULL,
   transaction_id VARCHAR (355) UNIQUE NOT NULL,
   block_num INT NOT NULL,
   created_on TIMESTAMPTZ NOT NULL
);"
sudo -u postgres psql -c "ALTER DATABASE ${benchmark_db} OWNER TO ${benchmark_user};"
sudo -u postgres psql -d $benchmark_db -c "ALTER TABLE ${benchmark_table} OWNER TO ${benchmark_user};"
sudo -u postgres psql -d $benchmark_db -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${benchmark_user};"
sudo -u postgres psql -d $benchmark_db -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${benchmark_user};"
#---------------------------------
# BENCHMARK API BACKEND SETUP
#---------------------------------
echo "---INSTALLING BACKEND API---"
cd ~
git clone https://github.com/eon-llc/rem-benchmark-api.git
cd rem-benchmark-api/
sudo go get -u github.com/lib/pq
sudo go get -u github.com/gorilla/mux
sudo go get -u github.com/joho/godotenv
echo "DB_NAME=vmlucgke
TABLE_NAME=benchmarks
DB_HOST=127.0.0.1
DB_USER=oalabncu
DB_PASS=8gHvnpKDdBPXa44XjzmAMAwmCtLCfgei3qwiDUkq
DB_PORT=5432" > ./.env
go build main.go
nohup ./main &
#---------------------------------
# NGINX REVERSE PROXY
#---------------------------------
echo "---INSTALLING NGINX REVERSE PROXY---"
cd ~
apt-get install nginx -y
unlink /etc/nginx/sites-enabled/default
echo 'proxy_cache_path /tmp/cache keys_zone=cache:10m levels=1:2 inactive=600s max_size=100m;
proxy_cache_key $scheme$request_method$host$request_uri;
proxy_cache_valid 200 10m;

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    gzip on;
    gzip_types application/json;
    gzip_min_length 128;
    gunzip on;

    location / {
        proxy_cache cache;
        proxy_cache_lock on;
        proxy_buffering on;
        proxy_cache_use_stale updating;

        proxy_http_version 1.1;

        proxy_ignore_headers X-Accel-Expires;
        proxy_ignore_headers Expires;
        proxy_ignore_headers Cache-Control;
        proxy_ignore_headers Set-Cookie;

        proxy_hide_header X-Accel-Expires;
        proxy_hide_header Expires;
        proxy_hide_header Cache-Control;
        proxy_hide_header Pragma;

        add_header Access-Control-Allow-Origin *;
        add_header X-Cache $upstream_cache_status;

        proxy_pass http://127.0.0.1:8080;
    }
}' > /etc/nginx/sites-available/reverse-proxy.conf
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo systemctl enable nginx
#---------------------------------
# MOUNT VOLUME ON REBOOT
#---------------------------------
echo "---CREATING REBOOT INSTRUCTIONS---"
echo '#!/bin/sh -e
sudo resize2fs /dev/xvdf
exit 0' > /etc/rc.local
sudo chmod +x /etc/rc.local
echo "---SETUP COMPLETE---"