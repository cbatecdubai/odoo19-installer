#!/bin/bash

set -e

echo "Starting Odoo 19 CE installation..."

# Make sure script runs as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo "Updating system..."

apt update -y
apt upgrade -y

echo "Installing base dependencies..."

apt install -y git curl wget build-essential software-properties-common \
python3 python3-pip python3-venv python3-dev \
libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev \
libjpeg-dev libpq-dev libffi-dev libssl-dev \
postgresql nginx wkhtmltopdf node-less npm

echo "Base system prepared."
