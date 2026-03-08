#!/bin/bash

set -e

echo "Starting Odoo 19 CE professional installation..."

if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit
fi

ODOO_USER="odoo"
ODOO_HOME="/opt/$ODOO_USER"
ODOO_HOME_EXT="$ODOO_HOME/odoo-server"
ODOO_VERSION="19.0"
CUSTOM_ADDONS="$ODOO_HOME/custom_addons"

echo "Updating system..."

apt update -y
apt upgrade -y

echo "Installing dependencies..."

apt install -y git curl wget build-essential \
python3 python3-pip python3-venv python3-dev \
libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev \
libjpeg-dev libpq-dev libffi-dev libssl-dev \
postgresql nginx ufw

echo "Installing correct wkhtmltopdf..."

wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb
apt install -y ./wkhtmltox_0.12.6.1-3.jammy_amd64.deb
rm wkhtmltox_0.12.6.1-3.jammy_amd64.deb

echo "Opening firewall..."

ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

echo "Starting PostgreSQL..."

systemctl enable postgresql
systemctl start postgresql

echo "Creating Odoo user..."

if id "$ODOO_USER" >/dev/null 2>&1; then
  echo "Odoo user exists"
else
  adduser --system --home=$ODOO_HOME --group $ODOO_USER
fi

sudo -u postgres createuser -s $ODOO_USER || true

echo "Installing Odoo source..."

mkdir -p $ODOO_HOME_EXT
mkdir -p $CUSTOM_ADDONS

chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME

sudo -u $ODOO_USER git clone https://github.com/odoo/odoo \
--depth 1 \
--branch $ODOO_VERSION \
$ODOO_HOME_EXT

echo "Creating Python environment..."

sudo -u $ODOO_USER python3 -m venv $ODOO_HOME/venv

echo "Installing Python requirements..."

sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install wheel
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install -r $ODOO_HOME_EXT/requirements.txt

echo "Calculating optimal workers..."

CPU=$(nproc)
WORKERS=$((CPU * 2 + 1))

echo "Creating Odoo configuration..."

cat <<EOF > /etc/odoo.conf
[options]

admin_passwd = admin

db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False

addons_path = $ODOO_HOME_EXT/addons,$CUSTOM_ADDONS

logfile = /var/log/odoo.log

proxy_mode = True

workers = $WORKERS
longpolling_port = 8072

limit_memory_soft = 2147483648
limit_memory_hard = 2684354560
limit_time_cpu = 600
limit_time_real = 1200

http_port = 8069

EOF

touch /var/log/odoo.log
chown $ODOO_USER:$ODOO_USER /var/log/odoo.log

echo "Creating systemd service..."

cat <<EOF > /etc/systemd/system/odoo.service
[Unit]
Description=Odoo19
After=postgresql.service

[Service]
Type=simple
User=$ODOO_USER
ExecStart=$ODOO_HOME/venv/bin/python3 $ODOO_HOME_EXT/odoo-bin -c /etc/odoo.conf
Restart=always
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable odoo
systemctl start odoo

echo "Configuring nginx..."

cat <<EOF > /etc/nginx/sites-available/odoo
upstream odoo {
    server 127.0.0.1:8069;
}

upstream odoochat {
    server 127.0.0.1:8072;
}

server {

    listen 80;
    server_name _;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    client_max_body_size 200M;

    location / {

        proxy_pass http://odoo;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

    }

    location /longpolling {

        proxy_pass http://odoochat;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

    }

}
EOF

ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx

echo "--------------------------------------"
echo "Odoo 19 installation completed"
echo ""
echo "Open your browser:"
echo "http://SERVER-IP"
echo "or"
echo "http://your-domain"
echo "--------------------------------------"
