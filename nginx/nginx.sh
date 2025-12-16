#!/bin/bash

# Este script ha sido desarrollado por Moska

# Este script crea el servidor web con nginx y una
# pagina con dominio, los certificados firmados tienen
# que estar en /etc/ssl/certs y /etc/ssl/private

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

# Global variable to hold the PID of the spinner function
SPINNER_PID=

# Function to draw the spinner animation
function start_spinner {
    # Define the spinner frames
    local spin='/-\|'
    # Define the message to display
    local message="$1"
    
    # 2>&1 means redirect stderr (2) to stdout (1)
    # The while loop runs in the background
    (
        # Turn off case-insensitive matching for shopt (if it were on)
        # Toggles behavior of shell options
        trap "echo -e \"\n\n\"" SIGINT # Handle Ctrl+C gracefully
        
        while :
        do
            # Cycle through the spinner frames
            for i in $(seq 0 3); do
                # Get the current frame character
                local char=${spin:i:1}
                # Print the frame, overwrite the line using \r (carriage return)
                printf "\r$message... %s" "$char"
                sleep 0.1
            done
        done
    ) &

    # Store the PID of the background process so we can kill it later
    SPINNER_PID=$!
    # Disown the process so it doesn't get a SIGHUP when the script ends,
    # though we intend to kill it explicitly.
    disown
}

# Function to stop the spinner and clean up
function stop_spinner {
    # Check if the spinner process ID is set and running
    if [[ -n "$SPINNER_PID" ]]; then
        # Kill the background process
        kill $SPINNER_PID 2>/dev/null
        
        # Clear the line and move the cursor to the beginning
        printf "\r%40s\r" ""
        SPINNER_PID=
    fi
}


# Script
function check_nginx() {
    if dpkg -s nginx &>/dev/null; then
        echo " nginx instalado, saltando instalacion"
    else
        start_spinner " Instalando nginx"
        apt install nginx -y > /dev/null
        stop_spinner
    fi
}


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
    if [ -f /etc/ssl/private/${domain}.key ] && [ -f /etc/ssl/certs/${domain}.crt ]; then
        echo " $domain key y crt existen, puedes continuar"
    else
        echo " $domain key y crt no existe, ejecuta ./certs.sh en tu ca"
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
        listen [::]:80;# Global variable to hold the PID of the spinner function

        server_name $domain www.$domain;

        return 302 https://\$server_name\$request_uri;
    }" > /etc/nginx/sites-available/$domain
    cp /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    echo -e "<!DOCTYPE html>
    <html lang="es">
        <title>Moska</title>
        <body>
            <h1>Bienvenido a tu dominio!</h1>
            <p>Esta es la pagina default de tu dominio: $domain</p>
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
# Check if nginx is installed
check_nginx
# Checking for user domain
newcomer
# Check if domain key and crt exist
check_ssl
# Configuration of nginx's https
vhost_https_server_config

systemctl restart nginx >>/dev/null 2>&1
nginx -t >>/dev/null 2>&1