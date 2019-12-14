#! /bin/bash
# output can be found in /var/log/cloud-init-output.log
echo "---RUNNING UPDATES & INSTALLS---"
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install golang-go -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo apt-get install -y postgresql postgresql-contrib
sudo apt-get install unzip -y
sudo apt-get install libwww-perl libdatetime-perl -y
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
# POSTGRESQL SETUP
#---------------------------------
# stop the process before modifying config
echo "---STOPPING PSQL---"
sudo systemctl stop postgresql
# if new setup move default data into new location
if [ ! -d "/data/postgresql" ]; then sudo rsync -av /var/lib/postgresql /data; fi
# enable psql password auth
sudo sed -i "s:local *all *all.*:host  all  all  0.0.0.0/0 md5\nlocal  all  all  peer:" /etc/postgresql/10/main/pg_hba.conf
# point config directory to new location
sudo sed -i "s:data_directory.*:data_directory = '/data/postgresql/10/main':" /etc/postgresql/10/main/postgresql.conf
# allow remote connections
sudo sed -i "s:#listen_addresses.*:listen_addresses = '*':" /etc/postgresql/10/main/postgresql.conf
# restart process for changes to take effect
echo "---STARTING PSQL---"
sudo systemctl start postgresql
# create DB and user for benchmarks
echo "---RUNNING SETUP QUERIES---"
sudo -u postgres psql -c "CREATE DATABASE ${benchmark_db};"
sudo -u postgres psql -c "CREATE USER ${benchmark_user} PASSWORD '${benchmark_pass}';"
# create table for benchmarks
sudo -u postgres psql -d ${benchmark_db} -c "CREATE TABLE ${benchmark_table}(
   id SERIAL PRIMARY KEY,
   producer VARCHAR (50) NOT NULL,
   cpu_usage_us INT NOT NULL,
   transaction_id VARCHAR (355) UNIQUE NOT NULL,
   block_num INT NOT NULL,
   created_on TIMESTAMPTZ NOT NULL
);"
sudo -u postgres psql -c "ALTER DATABASE ${benchmark_db} OWNER TO ${benchmark_user};"
sudo -u postgres psql -d ${benchmark_db} -c "ALTER TABLE ${benchmark_table} OWNER TO ${benchmark_user};"
sudo -u postgres psql -d ${benchmark_db} -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${benchmark_user};"
sudo -u postgres psql -d ${benchmark_db} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${benchmark_user};"
# create DB and user for benchmarks
echo "---RUNNING SETUP QUERIES---"
sudo -u postgres psql -c "CREATE DATABASE ${alert_db};"
sudo -u postgres psql -c "CREATE USER ${alert_user} PASSWORD '${alert_pass}';"
# create table for benchmarks
sudo -u postgres psql -d alert -c "CREATE TABLE ${telegram_table}(
   id SERIAL PRIMARY KEY,
   telegram_id INT NOT NULL,
   accounts text[] DEFAULT '{}' NOT NULL,
   editing BOOLEAN DEFAULT FALSE NOT NULL,
   adding BOOLEAN DEFAULT TRUE NOT NULL,
   last_check timestamp(3) with time zone,
   settings json
);"
sudo -u postgres psql -c "ALTER DATABASE ${alert_db} OWNER TO ${alert_user};"
sudo -u postgres psql -d ${alert_db} -c "ALTER TABLE ${telegram_table} OWNER TO ${alert_user};"
sudo -u postgres psql -d ${alert_db} -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${alert_user};"
sudo -u postgres psql -d ${alert_db} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${alert_user};"
#---------------------------------
# BENCHMARK API BACKEND SETUP
#---------------------------------
echo "---INSTALLING BACKEND API---"
mkdir -p /root/go/cache
export GOPATH=/root/go
export GOCACHE=/root/go/cache
cd ~
git clone https://github.com/eon-llc/rem-benchmark-api.git
cd rem-benchmark-api/
sudo go get -v -u github.com/lib/pq
sudo go get -v -u github.com/gorilla/mux
sudo go get -v -u github.com/joho/godotenv
echo "DB_NAME=${benchmark_db}
TABLE_NAME=${benchmark_table}
DB_HOST=127.0.0.1
DB_USER=${benchmark_user}
DB_PASS=${benchmark_pass}
DB_PORT=${benchmark_db_port}" > ./.env
go build main.go
# run benchmark as a service
echo '[Unit]
Description=Benchmark API service
DefaultDependencies=no
After=postgresql.service
RequiresMountsFor=/data
Requires=postgresql.service network.target data.mount

[Service]
Type=simple
ExecStart=/root/rem-benchmark-api/main
Restart=always
RestartSec=1

[Install]
WantedBy=postgresql.service' > /etc/systemd/system/benchmark_api.service
systemctl daemon-reload
systemctl enable benchmark_api
systemctl restart benchmark_api
#---------------------------------
# ALERT BOT API BACKEND
#---------------------------------
echo "---ALERT API BACKEND---"
cd ~
git clone https://github.com/eon-llc/rem-alert-api.git
cd rem-alert-api/
sudo go get -v -u github.com/lib/pq
sudo go get -v -u github.com/gorilla/mux
sudo go get -v -u github.com/joho/godotenv
sudo go get -v -u github.com/parnurzeal/gorequest
echo "DB_NAME=${alert_db}
TABLE_NAME=${telegram_table}
DB_HOST=127.0.0.1
DB_USER=${alert_user}
DB_PASS=${alert_pass}
DB_PORT=${alert_db_port}" > ./.env
go build main.go
# run benchmark as a service
echo '[Unit]
Description=Alert API service
DefaultDependencies=no
After=postgresql.service
RequiresMountsFor=/data
Requires=postgresql.service network.target data.mount

[Service]
Type=simple
ExecStart=/root/rem-alert-api/main
Restart=always
RestartSec=1

[Install]
WantedBy=postgresql.service' > /etc/systemd/system/alert_api.service
systemctl daemon-reload
systemctl enable alert_api
systemctl restart alert_api
#---------------------------------
# NGINX REVERSE PROXY
#---------------------------------
echo "---INSTALLING NGINX REVERSE PROXY---"
cd ~
apt-get install nginx -y
unlink /etc/nginx/sites-enabled/default
echo '
proxy_cache_path /tmp/cache keys_zone=cache:10m levels=1:2 inactive=600s max_size=100m;
proxy_cache_key $scheme$request_method$host$request_uri;

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    gzip on;
    gzip_types application/json;
    gzip_min_length 128;
    gunzip on;

    location / {
        proxy_cache_valid 200 10m;

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

    location /alerts {
        proxy_pass http://127.0.0.1:8090;
    }
}' > /etc/nginx/sites-available/reverse-proxy.conf
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo systemctl enable nginx
#---------------------------------
# MOUNT VOLUME ON REBOOT
#---------------------------------
echo "---CREATING REBOOT INSTRUCTIONS---"
echo '#!/bin/bash
sudo resize2fs /dev/xvdf
exit 0' > /etc/rc.local
sudo chmod +x /etc/rc.local
echo "---SETUP COMPLETE---"