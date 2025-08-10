#!/bin/bash

# Versão do script
SCRIPT_VERSION="1.0.6"
SINCE_DATE="01/09/2021"
CURRENT_DATE="08/08/2025"
CREATOR="LeonardHM"

# =============================================================================

### USE ESSES COMANDOS MANUALMENTE EM CASO DE ERROS ###
# sudo kill (processo que esta com erro)
# sudo dpkg --configure -a
# sudo apt --fix-broken install

# sudo raspi-config nonint do_expand_rootfs  # PARA EXPANDIR MEMORIA INTERNA QUANDO DISPONIVEL #

# =============================================================================

# PARA MATRIX DE LED
# instalar_programa python3-pip # PARA CONTROLAR ARQUIVO py
# pip install --break-system-packages luma.led_matrix
# sudo raspi-config nonint do_spi 0

# =============================================================================

# ===============================================
# SCRIPT PRINCIPAL
# ===============================================

# --- Variáveis Internas do Script ---
SCRIPTS_FOLDER="$HOME/clone/configs/scripts"
VARIABLES_FILE="$SCRIPTS_FOLDER/variaveis.sh"
declare -a CLI_VARS_SET=() # Array para rastrear variáveis definidas via CLI
export ORIGINAL_USER="$SUDO_USER"


# Importação das outras funções e execução
source "$SCRIPTS_FOLDER/alexa_triggercmd.sh"
source "$SCRIPTS_FOLDER/config_HA.sh"
source "$SCRIPTS_FOLDER/config_basics.sh"
source "$SCRIPTS_FOLDER/config_monitor_dockerRPI.sh"
source "$SCRIPTS_FOLDER/cosmos_docker.sh"
source "$SCRIPTS_FOLDER/rclone.sh"
source "$SCRIPTS_FOLDER/ssh_vnc.sh"
source "$SCRIPTS_FOLDER/questions.sh"
source "$SCRIPTS_FOLDER/server_mine.sh"
source "$SCRIPTS_FOLDER/tools.sh"
source "$SCRIPTS_FOLDER/variaveis.sh"
source "$SCRIPTS_FOLDER/wifi_eth_pihole.sh"

detectar_sistema

# --- Função Principal de Execução ---
main() {
    # Inicializa variáveis para o novo fluxo
    local COMMAND=
    local EXPERT_MODE=false
    local FAST_MODE=false

    # ===============================================
    # PROCESSAMENTO DE ARGUMENTOS DA LINHA DE COMANDO (UNIFICADO)
    # ===============================================
    for arg in "$@"; do
        case "$arg" in
            # Flags de modo
            "--expert") EXPERT_MODE=true ;;
            "--fast") FAST_MODE=true ;;
            # Variáveis de configuração
            --conectar_wifi=*) conectar_wifi="${arg#*=}" ;;
            --compartilhar_internet_lan=*) compartilhar_internet_lan="${arg#*=}" ;;
            --instalar_pi_hole=*) instalar_pi_hole="${arg#*=}" ;;
            --WIFI_CONFIGS=*)
                IFS=',' read -ra WIFI_CONFIGS <<< "${arg#*=}"
                ;;
            --WIFI_IP_ADDRESS=*) WIFI_IP_ADDRESS="${arg#*=}" ;;
            --WIFI_GATEWAY=*) WIFI_GATEWAY="${arg#*=}" ;;
            --WIFI_DNS=*) WIFI_DNS="${arg#*=}" ;;
            --SHARED_IP_ADDRESS=*) SHARED_IP_ADDRESS="${arg#*=}" ;;
            --DHCP_RANGE=*) DHCP_RANGE="${arg#*=}" ;;
            --PIHOLE_DNS=*) PIHOLE_DNS="${arg#*=}" ;;
            --conexao_lan=*) conexao_lan="${arg#*=}" ;;
            --CLOUDFLARE_TOKEN=*) CLOUDFLARE_TOKEN="${arg#*=}" ;;
            --RCLONE_CONFIG=*)
                IFS=',' read -ra RCLONE_CONFIG <<< "${arg#*=}"
                ;;
            --MQTT_BROKER=*) MQTT_BROKER="${arg#*=}" ;;
            --MQTT_PORT=*) MQTT_PORT="${arg#*=}" ;;
            --MQTT_USER_DOCKER=*) MQTT_USER_DOCKER="${arg#*=}" ;;
            --MQTT_USER_RPI=*) MQTT_USER_RPI="${arg#*=}" ;;
            --MQTT_PASSWORD=*) MQTT_PASSWORD="${arg#*=}" ;;
            --MQTT_TOPIC_DOCKER=*) MQTT_TOPIC_DOCKER="${arg#*=}" ;;
            --MQTT_TOPIC_RPI=*) MQTT_TOPIC_RPI="${arg#*=}" ;;
            --INTERVAL_SECONDS=*) INTERVAL_SECONDS="${arg#*=}" ;;
            --CONTAINERS_PARA_MONITORAR=*)
                IFS=',' read -ra CONTAINERS_PARA_MONITORAR <<< "${arg#*=}"
                ;;
            # Variáveis de perguntas
            --update_system=*) update_system="${arg#*=}" ;;
            --install_basic_zsh=*) install_basic_zsh="${arg#*=}" ;;
            --install_theme=*) install_theme="${arg#*=}" ;;
            --programas=*) programas="${arg#*=}" ;;
            --pi_apps_programas=*) pi_apps_programas="${arg#*=}" ;;
            --ativar_ssh=*) ativar_ssh="${arg#*=}" ;;
            --ativar_vnc=*) ativar_vnc="${arg#*=}" ;;
            --habilitar_tft=*) habilitar_tft="${arg#*=}" ;;
            --drive=*) drive="${arg#*=}" ;;
            --alexa_commands=*) alexa_commands="${arg#*=}" ;;

            --cosmos=*) cosmos="${arg#*=}" ;;
            --mine_server=*) mine_server="${arg#*=}" ;;
            --reiniciar=*) reiniciar="${arg#*=}" ;;
            *)
                if [[ "$arg" != "--" ]]; then
                    COMMAND="$arg"
                fi
                ;;
        esac
    done

    echo
    echo
    show_ascii_logo
    show_banner_info
    echo
    echo

    # --- Lógica de Fluxo de Execução ---
    # 1. Modo Expert: Executa um comando específico, mas apenas se a flag --expert for passada.
    if [[ -n "$COMMAND" ]]; then
        if [[ "$EXPERT_MODE" == true ]]; then
            if type -t "$COMMAND" >/dev/null; then
                print_log "$(log_info)" "$(echo_orange "Modo Expert ativado. Executando função dedicada: '$COMMAND'")"
                "$COMMAND"
                # cada função tem tem seu log de sucesso
                # print_log "$(log_success)" "$(echo_green "Execução de '$COMMAND' concluída.")"
                exit 0
            else
                print_log "$(log_error)" "$(echo_red "Comando desconhecido: '$COMMAND'")"
            fi
        else
            print_log "$(log_error)" "$(echo_red "A flag --expert é necessária para executar a função dedicada '$COMMAND'.")"
        fi
    fi


    echo_green "SISTEMA DETECTADO: $SISTEMA_TIPO ($SISTEMA_ARCH) | Distro: $DISTRO_NOME / $DISTRO_NAME ($DISTRO_CODENAME)"
    echo

    # 2. Modo Fast: Pula todas as perguntas.
    if [[ "$FAST_MODE" == true ]]; then

        print_log "$(log_aviso)" "$(echo_red "Modo de instalação rápida (--fast) ativado. Pulando perguntas interativas.")"
    else
        print_log "$(log_info)" "$(echo_orange "Iniciando modo interativo...")"
        # Chama a sua função para coletar as respostas interativas
        coletar_respostas
    fi

    # ===============================================
    # EXECUÇÃO DAS FUNÇÕES COM BASE NAS VARIÁVEIS
    # ===============================================
    print_log "$(log_info)" "$(echo_yellow "Iniciando a execução das funções de instalação...")"
    echo

    # Conectar e configurar Wi-Fi
    if [[ "$conectar_wifi" =~ ^[Yy]$ ]]; then
        configurar_wifi
    fi

    # Compartilhar internet via LAN, com ou sem Pi-hole
    if [[ "$compartilhar_internet_lan" =~ ^[Yy]$ ]]; then
        if [[ "$instalar_pi_hole" =~ ^[Yy]$ ]]; then
            # print_log "$(log_aviso)" "$(echo_red "Iniciando compartilhamento de internet com Pi-hole...")"
            compartilhar_internet_pihole
        else
            # print_log "$(log_aviso)" "$(echo_red "Iniciando compartilhamento de internet sem Pi-hole...")"
            compartilhar_internet
        fi
    fi

    # Atualizar o sistema
    if [[ "$update_system" =~ ^[Yy]$ ]]; then
        print_log "$(log_aviso)" "$(echo_red "ATUALIZANDO O SISTEMA")"
        apt_update
        apt_upgrade
    fi

    # Instalar programas básicos e Zsh
    if [[ "$install_basic_zsh" =~ ^[Yy]$ ]]; then
        print_log "$(log_aviso)" "$(echo_red "CONFIGURANDO PROGRAMAS ESSENCIAIS")"

        case "$SISTEMA_TIPO" in
            *[Pp][Cc]*)
                apt_update
                instalar_programa "${basic_install[@]}"
                echo
                func_geral
                func_pc
                func_pc_rasp
                ;;
            *[Rr][Aa][Ss][Pp][Bb][Ee][Rr][Rr][Yy]*)
                apt_update
                print_log "$(log_aviso)" "$(echo_red "INSTALANDO PROGRAMAS BÁSICOS.")"
                instalar_programa "${basic_install[@]}"
                echo
                func_geral
                func_pc_rasp
                ;;
            *[Tt][Ee][Rr][Mm][Uu][Xx]*)
                pkg update -qq
                pkg install "${basic_install[@]}"
                echo
                func_geral
                func_termux
                ;;
            *)
                print_log "$(log_aviso)" "$(echo_yellow "Sistema não detectado ou tipo desconhecido. Pulando instalação de programas básicos.")"
                ;;
        esac
    fi

    # Configurar o tema
    if [[ "$install_theme" =~ ^[Yy]$ ]]; then
        config_theme
    fi

    # Instalar programas específicos
    if [[ "$programas" =~ .*[Hh][Ee][Ii][Mm][Dd][Aa][Ll].* ]]; then
        print_log "$(log_aviso)" "$(echo_red "INSTALANDO HEIMDALL")"
        instalar_programa "heimdall-flash-frontend"
    fi

    if [[ "$programas" =~ .*[Ss][Cc][Rr][Cc][Pp][Yy].* ]]; then
        print_log "$(log_aviso)" "$(echo_red "INSTALANDO SCRCPY")"
        instalar_programa ffmpeg libsdl2-2.0-0 adb wget git gcc pkg-config meson ninja-build libsdl2-dev libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev libswresample-dev libusb-1.0-0 libusb-1.0-0-dev

        local scrcpy_dir="$HOME/clone/scrcpy"
        mkdir -p "$HOME/clone"
        if [ ! -d "$scrcpy_dir" ]; then
            cd "$HOME/clone"
            git clone --quiet https://github.com/Genymobile/scrcpy
        fi
        cd "$scrcpy_dir" || { print_log "$(log_error)" "Erro: Não foi possível entrar no diretório do Scrcpy."; exit 1; }
        ./install_release.sh
        cd || exit
    fi

    if [[ "$programas" =~ .*([Pp][Ii]-?[Aa][Pp][Pp][Ss]).* ]]; then
        print_log "$(log_aviso)" "$(echo_red "INSTALANDO PI-APPS")"
        wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash
    fi

    # Instalar programas do Pi-Apps
    if [[ "$pi_apps_programas" =~ .*[Mm][Ii][Nn][Ee][Cc][Rr][Aa][Ff][Tt].* ]]; then
        print_log "$(log_aviso)" "$(echo_red "INSTALANDO MINECRAFT")"
        local install_script
        if [[ "$$SISTEMA_ARCH" == "armv6l" || "$$SISTEMA_ARCH" == "armv7l" ]]; then
            install_script='/home/pi-apps/apps/Minecraft Java/install-32'
        elif [[ "$$SISTEMA_ARCH" == "aarch64" || "$$SISTEMA_ARCH" == "x86_64" ]]; then
            install_script='/home/pi-apps/apps/Minecraft Java/install-64'
        else
            install_script='/home/pi-apps/apps/Minecraft Java/install'
        fi
        if [ -f "$install_script" ]; then
            bash "$install_script"
        else
            print_log "$(log_error)" "$(echo_red "ERRO: Script de instalação do Minecraft não encontrado para a arquitetura $$SISTEMA_ARCH.")"
        fi
    fi

    if [[ "$pi_apps_programas" =~ .*[Vv][Ii][Vv][Aa][Ll][Dd][Ii].* ]]; then
        print_log "$(log_aviso)" "$(echo_red "INSTALANDO VIVALDI")"
        local install_script
        if [[ "$$SISTEMA_ARCH" == "armv6l" || "$$SISTEMA_ARCH" == "armv7l" ]]; then
            install_script='/home/pi-apps/Vivaldi/install-32'
        elif [[ "$$SISTEMA_ARCH" == "aarch64" || "$$SISTEMA_ARCH" == "x86_64" ]]; then
            install_script='/home/pi-apps/Vivaldi/install-64'
        else
            install_script='/home/pi-apps/Vivaldi/install'
        fi
        if [ -f "$install_script" ]; then
            bash "$install_script"
        else
            print_log "$(log_error)" "$(echo_red "ERRO: Script de instalação do Vivaldi não encontrado para a arquitetura $$SISTEMA_ARCH.")"
        fi
    fi

    # Ativar SSH
    if [[ "$ativar_ssh" =~ ^[Yy]$ ]]; then
        if [[ "$SISTEMA_TIPO" == "RASPBERRY" ]]; then
            rasp_config_ssh
        else
            gerenciar_ssh
        fi
    fi

    # Ativar VNC
    if [[ "$ativar_vnc" =~ ^[Yy]$ ]]; then
        if [[ "$SISTEMA_TIPO" == "RASPBERRY" ]]; then
            rasp_config_vnc
        else
            gerenciar_vnc
        fi
    fi

    # Habilitar Display TFT
    if [[ "$habilitar_tft" =~ ^[Yy]$ ]]; then
        if ! grep -q "dtoverlay=piscreen" /boot/firmware/config.txt; then
            print_log "$(log_info)" "$(echo_orange "Habilitando display TFT no config.txt...")"
            echo "dtoverlay=piscreen,drm,speed=10000000" | sudo tee -a /boot/firmware/config.txt >/dev/null
            print_log "$(log_success)" "$(echo_green "Display TFT habilitado.")"
            echo
        else
            print_log "$(log_aviso)" "$(echo_yellow "Display TFT já está habilitado.")"
            echo
        fi
    fi

    # Configurar Google Drive com rclone
    if [[ $drive =~ ^[Yy]$ ]]; then
        configurar_rclone
        # deu sucesso mesmo com erro
        # print_log "$(log_success)" "$(echo_green "Google Drive configurado com sucesso.")"
    fi

    # Configurar comandos Alexa
    if [[ $alexa_commands =~ ^[Yy]$ ]]; then
        commands_alexa
    fi

    # Configurar Servidor Cosmos
    if [[ $cosmos =~ ^[Yy]$ ]]; then
        servidor_config
        cloudflare_tunnel
    fi

    # Configurar Servidor de Minecraft
    if [[ $mine_server =~ ^[Yy]$ ]]; then
        server_mine
    fi

    # Reiniciar o sistema
    if [[ "$reiniciar" =~ ^[Yy]$ ]]; then
        print_log "$(log_aviso)" "$(echo_red "REINICIANDO O SISTEMA...")"
        sudo reboot
    fi
}

# Executa a nova função principal
main "$@"

