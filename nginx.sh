#!/bin/bash

# Este script ha sido desarrollado por PRIME TEAM

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

# Execution checkers & Basic functions
function passwd-check() {
        if [[ "$passwd" == "$passwd2" ]]; then
                return 0
        else
                return 1
        fi
}
function test-email() {
        local validezemail="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

        if [[ "$email" =~ $validezemail ]]; then
                return 0
        else
                return 1
        fi
}

# Script
function newcomer() {
    clear
    echo -e "$LMAGENTA"
    echo -e "Bienvenido a el script modular de VHOSTING con SFTP hecho por PRIME TEAM$RESET"
    echo -e "Por favor escriba su nombre de usuario"
    read -p ">" user

    while true; do
        unset passwd
        unset passwd2
        echo -n "Introduzca su contraseña: "
        stty -echo
        PROMPT=""
        CHARCOUNT=0
            while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
            do
                if [[ $CHAR == $'\0' ]] ; then
                    break
                fi
                if [[ $CHAR == $'\177' ]] ; then
                    if [ $CHARCOUNT -gt 0 ] ; then
                        CHARCOUNT=$((CHARCOUNT-1))
                        PROMPT=$'\b \b'
                        passwd="${passwd%?}"
                    else
                        PROMPT=''
                    fi
                elif [[ $CHAR == $'\n' ]] ; then
                    break
                else
                    CHARCOUNT=$((CHARCOUNT+1))
                    PROMPT='*'
                    passwd+="$CHAR"
                fi
            done
            echo
            echo -n "Vuelve a introducir la contraseña: "
            PROMPT=""
            CHARCOUNT=0
            while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
            do
                if [[ $CHAR == $'\0' ]] ; then
                    break
                fi
                if [[ $CHAR == $'\177' ]] ; then
                    if [ $CHARCOUNT -gt 0 ] ; then
                        CHARCOUNT=$((CHARCOUNT-1))
                        PROMPT=$'\b \b'
                        passwd2="${passwd2%?}"
                    else
                        PROMPT=''
                    fi
                else
                    CHARCOUNT=$((CHARCOUNT+1))
                    PROMPT='*'
                    passwd2+="$CHAR"
                fi
            done
        passwd-check
        if [ $? -eq 0 ]; then
            stty echo
            echo
            break
        else
            echo
            echo "La contraseña que has escrito no es correcta, por favor escribela de nuevo."
        fi
    done
    useradd -m "$user" >>/dev/null 2>&1
    passwd "$user" <<< "$passwd"$'\n'$passwd >>/dev/null 2>&1

    echo -e " Cual es tu dominio?"
    read -p ">" domain

    while true; do
        echo "Por favor escriba su email: "
        read email

        test-email "$email"
        if [ $? -eq 0 ]; then
                break
        else
                echo "El e-mail que has escrito no es correcto, por favor escribalo de nuevo."
        fi
    done

    # Directory creation
    mkdir -p /var/www/$domain/html
}
function sftp_configuration() {

    chmod 755 /var/www/$domain
    chmod -R 775 /var/www/$domain/html/
    chown -R root:$user /var/www/$domain/

    echo -e "
    Match Group $user
        ChrootDirectory /var/www/$domain
        ForceCommand internal-sftp
        PubkeyAuthentication yes
        PasswordAuthentication yes
        PermitTTY no" >> /etc/ssh/sshd_config

    systemctl restart sshd
}
function ssl_ssk() {
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "/etc/ssl/private/$domain.key" -out "/etc/ssl/certs/$domain.crt" -subj "/C=ES/ST=Catalunya/L=Barcelona/O=PRIME TEAM/OU=PRIME TEAM/CN=$domain/emailAddress=$email"
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

# User and passwd creation
newcomer
# Creation of an sftp user and password
sftp_configuration
# Creation of a self-signed certificate
ssl_ssk
# Configuration of nginx's https
vhost_https_server_config

systemctl restart nginx sshd
nginx -t
