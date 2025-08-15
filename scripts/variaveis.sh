#!/bin/bash

# ===============================================
# ARQUIVO DE VARIÁVEIS DE CONFIGURAÇÃO
#
# Edite este arquivo para definir caminhos, nomes de contêineres,
# usuários, senhas, etc., antes de executar o script principal.
# ===============================================

# --- CONFIGURAÇÕES DE PERGUNTAS INTERATIVAS (com valores padrão) ---
# Estas variáveis são as que o script main.sh pergunta ao usuário.
# Defina um valor padrão aqui, que pode ser sobrescrito por CLI ou Nano.


# --- CONFIGURAÇÕES GERAIS (podem ser alteradas via CLI/Nano) ---

# Configurações de WiFi {SSID:PSK:PRIORITY}
# Defina como array vazio se não houver redes padrão, ou com seus valores.
WIFI_CONFIGS=(
    "teSt:123456789:7"
    "test-5G:abcdef:9"
)

# IPs para a conexão Wi-Fi
WIFI_IP_ADDRESS="192.168.15.20/24"
WIFI_GATEWAY="192.168.15.1"
WIFI_DNS="8.8.8.8,8.8.4.4"

# IPs para compartilhamento de internet
SHARED_IP_ADDRESS="192.168.1.1/24"
DHCP_RANGE="192.168.1.10,192.168.1.200"
PIHOLE_DNS="192.168.1.1"

# Compartilhar internet por eth
# tornar mais modular para aceitar outras conexões além da 1
conexao_lan=$(nmcli connection show | grep -E "Conexão cabeada 1|Wired connection 1" | awk '{print $1,$2,$3}')

# Token Cloudflared Tunnel
CLOUDFLARE_TOKEN="abcde12345"

# Tokens e chaves do rclone (array de strings)
RCLONE_CONFIG=(
    "client_id=abcde12345"
    "client_secret=abcde12345"
)

# Token TriggerCMD
TRIGGERCMD_TOKEN=""

# Variaveis para controle MQTT Docker
MQTT_BROKER="192.168.1.1"
MQTT_PORT="1883"
MQTT_USER_DOCKER="docker_user"
MQTT_USER_RPI="raspberry_user"
MQTT_PASSWORD='psk.mqtt' # Cuidado com aspas simples se o valor tiver caracteres especiais
MQTT_TOPIC_DOCKER="home/nodes/docker"
MQTT_TOPIC_RPI="home/nodes/raspberrypi"
INTERVAL_SECONDS=10


CONTAINERS_PARA_MONITORAR=(
    "Home-Assistant"
    "Doku"
    "EMQX"
    "IT-Tools"
    "Openspeedtest"
    "Immich"
    "Cloudflared"
)


# Variaveis de Diretórios
CLONE_DIR="$HOME/clone"

ZSH_DIR="$CLONE_DIR/configs/.oh-my-zsh"
ZSH_SCRIPT="$ZSH_DIR/oh-my-zsh.sh"
PLUGIN_ZSH_DIR="$ZSH_DIR/custom/plugins"

MINE_DIR="$CLONE_DIR/mine-server"
PLUGIN_MINE_DIR="$MINE_DIR/plugins"
DATAPACK_MINE_DIR="$MINE_DIR/datapacks"

HA_CONFIG_PATH="/var/lib/docker/volumes/Home-Assistant-config/_data"
HA_CC_PATH="$HA_CONFIG_PATH/custom_components"

# Variaveis de instalação
basic_install=("btop" "neofetch" "git" "wget" "speedtest-cli" "mc" "tree")

zsh_install=("zsh" "lolcat" "figlet" "toilet")

server_install=("git" "bc" "mosquitto-clients" "python3" "python3-pip" "python3-tzlocal" "python3-sdnotify" "python3-colorama" "python3-unidecode" "python3-paho-mqtt" "python3-apt" "python3-requests" "snapraid" "unzip" "wget" "avahi-daemon" "avahi-utils" "iptables-persistent" "fuse")

