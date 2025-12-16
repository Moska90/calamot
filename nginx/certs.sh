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

# Global variable to hold the PID of the spinner function
SPINNER_PID=
SCRIPT_DIR="$(pwd)"

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

function newcomer() {
    clear
    echo -e "$LMAGENTA"
    echo -e "Bienvenido a el script modular de VHOSTING con SFTP hecho por Moska$RESET"

    echo -e " Quieres instalar el ca? [Y/n]"
    read -p " > " install_cert
}

function install_ca() {
    foo="${install_cert:=Y}"
    case $install_cert in
        0 | [Yy]|[Ss])
            start_spinner " Instalando CA, ten paciencia"

            apt update >>/dev/null 2>&1
            apt install easy-rsa -y >>/dev/null 2>&1

            stop_spinner
            echo " Easy-rsa instalado ✅"

            ln -s /usr/share/easy-rsa/ ~/
            chmod 700 ~/easy-rsa

            start_spinner " Iniciando el pki y el ca"
            cd ~/easy-rsa/
            ./easyrsa --batch init-pki >>/dev/null 2>&1
            ./easyrsa --batch build-ca nopass >>/dev/null 2>&1
            cd $SCRIPT_DIR
            stop_spinner
        ;;

        1 | [Nn])
            echo " Cual es la ubicación de tu CA?"
            find /root /home /usr/share -name easy-rsa | grep -v '/usr/share/doc'
            read -p " > " ca_dir
        ;;
    esac
}

function gen_crt() {
    echo " Cual es tu dominio?"
    read -p " > " domain

    mkdir -p ~/certs/$domain
    cd ~/certs/$domain
    openssl genrsa -out ${domain}.key
    openssl req -new -key ${domain}.key -out ${domain}.req -subj "/CN=$domain/"

    foo="${ca_dir:=$HOME/easy-rsa}"
    cd $ca_dir
    ./easyrsa import-req ~/certs/$domain/${domain}.req $domain >>/dev/null 2>&1
    ./easyrsa --batch sign-req server $domain >>/dev/null 2>&1
    cp pki/issued/${domain}.crt ~/certs/$domain/
    echo " Tu crt esta en ~/certs/$domain/"
}

# Modular part
# User start
newcomer
# CA Server
install_ca
# Crt and key
gen_crt