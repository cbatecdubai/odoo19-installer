# odoo19-installer
One-command installer for Odoo CE 19 with SSL, WebSocket, VoIP and production setup
# Odoo CE 19 – One-Command Professional Installer

Production-ready installer for **Odoo Community Edition 19**.

This script deploys a complete ERP server automatically on a **fresh Ubuntu VPS**.

Included in the installation:

• Odoo 19 Community Edition
• PostgreSQL database server
• Python virtual environment
• Nginx reverse proxy (no :8069 in URL)
• WebSocket / longpolling support (notifications & VoIP ready)
• Dynamic workers based on CPU
• Correct wkhtmltopdf for PDF reports
• Firewall configuration
• Systemd auto-start service

The installer works with **server IP or domain name**.

---

# Recommended Server

Minimum recommended configuration:

Ubuntu **22.04 LTS**
2 CPU
4 GB RAM
40 GB SSD

This installer is designed for **fresh servers only**.

---

# Install Odoo 19 (One Command)

SSH into your server and run:

```bash
bash <(curl -s https://raw.githubusercontent.com/cbatecdubai/odoo19-installer/main/scripts/install_odoo19.sh)
```

The installation usually takes **3–6 minutes** depending on the server speed.

---

# Access Odoo

After installation open your browser.

If you use the server IP:

```
http://SERVER-IP
```

If you use a domain pointing to the server:

```
http://your-domain
```

Example:

```
http://192.168.1.20
```

or

```
http://erp.example.com
```

---

# What the Installer Configures Automatically

The script performs the following tasks:

Install system dependencies
Install PostgreSQL database server
Create Odoo system user
Download Odoo 19 source code
Create Python virtual environment
Install Python dependencies
Configure Odoo service
Enable automatic server start
Install patched wkhtmltopdf
Configure Nginx reverse proxy
Enable WebSocket for real-time notifications
Enable firewall rules
Calculate optimal workers based on CPU

All steps run automatically.

---

# Internal Ports

Odoo runs internally on:

```
8069
```

But users access it through Nginx via:

```
http://SERVER-IP
```

or

```
http://your-domain
```

---

# Important Notes

This installer is intended for:

• ERP deployments
• CRM systems
• business automation servers

It is designed for **fast, stable Odoo production setups**.

Always install on a **clean Ubuntu server**.

---

# License

MIT License
