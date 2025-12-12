#!/bin/bash

# Este script ha sido desarrollado por Moska

# La manera de utilizarlo es comentar aquellas lineas indicadas
# para dejar de hacer ciertas tareas por ejemplo

# Comment this line if you want to unable sftp configuration
# Uncomment this line if you want to enable sftp configuration

# sftp_configuration

# la linea sftp_configuration la deberiamos comentar o no según nuestro interes

################################################################################################

LRED="\e[91m"
LGREEN="\e[92m"
LYELLOW="\e[93m"
LBLUE="\e[94m"
LMAGENTA="\e[95m"
LCYAN="\e[96m"
LGREY="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

# Script
function newcomer() {
    clear
    echo -e "$LMAGENTA"
    echo -e "Bienvenido a el script modular de VHOSTING con SFTP hecho por Moska$RESET"
    echo -e " Cual es tu dominio?"
    read -p " > " domain

    # Directory creation
    mkdir -p /var/www/$domain/html
}

function check_ssl() {
    if [ -f ${domain}.key ] && [ -f ${domain}.crt ]; then
        echo " $domain key y crt existen, puedes continuar"
    else
        echo " $domain key y crt no existe, ejecuta./certs.sh en tu ca"
        exit
    fi
}

function vhost_https_server_config() {
    echo -e "
    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl_certificate /etc/ssl/certs/$domain.crt;
        ssl_certificate_key /etc/ssl/private/$domain.key;
        include snippets/ssl-params.conf;

        root /var/www/$domain/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $domain www.$domain;

        location / {
                try_files \$uri \$uri/ =404;
        }
    }
    server {
        listen 80;
        listen [::]:80;

        server_name $domain www.$domain;

        return 302 https://\$server_name\$request_uri;
    }" > /etc/nginx/sites-available/$domain
    cp /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    echo -e "<!DOCTYPE html>
    <html lang="es">
        <title>PRIME TEAM</title>
        <body>
            <h1>Bienvenido a tu dominio!</h1>
            <p>Esta es la pagina default de $user,
            para editar tu pagina web entra por SFTP.</p>
        </body>
    </html>" > /var/www/$domain/html/index.html

    echo -e "
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection \"1; mode=block\";
    " > /etc/nginx/snippets/ssl-params.conf

    cp dhparam.pem /etc/nginx/
}

# Zona del script modular
# Checking for user domain
newcomer
# Check if domain key and crt exist
check_ssl
# Configuration of nginx's https
# vhost_https_server_config

# systemctl restart nginx
# nginx -t