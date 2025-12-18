install_monitor() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO A INSTALAÇÃO E CONFIGURAÇÃO DOS MONITORES MQTT...")"

    # fazer verificção se o usuario passou os argumentos necessarios

    DOCKER_REPORTER_SCRIPT="/opt/docker_mqtt_scripts/docker_reporter.sh"
    REPORTER_SERVICE_FILE="/etc/systemd/system/docker-mqtt-reporter.service"
    DOCKER_COMMAND_LISTENER_SCRIPT="/opt/docker_mqtt_scripts/docker_command_listener.sh"
    COMMAND_SERVICE_FILE="/etc/systemd/system/docker-mqtt-command.service"
    RPI_REPORTER_DIR="/opt/RPi-Reporter-MQTT2HA-Daemon"
    RPI_REPORTER_SERVICE_LINK="/etc/systemd/system/isp-rpi-reporter.service"

    instalar_programa mosquitto-clients python3 python3-pip python3-tzlocal python3-sdnotify python3-colorama python3-unidecode python3-apt python3-paho-mqtt python3-requests

    # Executar todas as etapas em um único processo em segundo plano
    {
        # --- Configuração do Docker Reporter ---
        if [ ! -f "${DOCKER_REPORTER_SCRIPT}" ]; then
            sudo mkdir -p /opt/docker_mqtt_scripts/ || { print_log "$(log_error)" "$(echo_red "Falha ao criar diretório para scripts do Docker.")" && exit 1; }
            sudo bash -c "cat << 'EOF_REPORTER_SCRIPT' > ${DOCKER_REPORTER_SCRIPT}
#!/bin/bash
# Este script coleta informações de monitoramento do Docker e as publica em um broker MQTT.

MQTT_BROKER=\"${MQTT_BROKER}\"
MQTT_PORT=\"${MQTT_PORT}\"
MQTT_USER=\"${MQTT_USER_DOCKER}\"
MQTT_PASSWORD='${MQTT_PASSWORD}'
MQTT_TOPIC=\"${MQTT_TOPIC_DOCKER}\"
INTERVAL_SECONDS=${INTERVAL_SECONDS}

# Containers monitorados (lista simples, mais eficiente)
CONTAINERS=\"$(printf '%s ' \"${CONTAINERS_PARA_MONITORAR[@]}\")\"

mqtt_publish() {
    mosquitto_pub \\
        -h \"\$MQTT_BROKER\" \\
        -p \"\$MQTT_PORT\" \\
        -t \"\$1\" \\
        -m \"\$2\" \\
        -r \\
        -u \"\$MQTT_USER\" \\
        -P \"\$MQTT_PASSWORD\"
}

get_docker_metrics() {

    # 1) CPU (e memória opcional) – coleta em lote
    docker stats --no-stream --format \"{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}\" \$CONTAINERS 2>/dev/null |
    while IFS=\"|\" read -r name cpu mem; do
        mqtt_publish \"\${MQTT_TOPIC}/container/\${name}/cpu_usage\" \"\$cpu\"
        # Se quiser memória no futuro:
        # mqtt_publish \"\${MQTT_TOPIC}/container/\${name}/mem_usage\" \"\$mem\"
    done

    # 2) Status dos containers
    for c in \$CONTAINERS; do
        STATUS=\$(docker inspect -f '{{.State.Status}}' \"\$c\" 2>/dev/null || echo \"not_found\")
        mqtt_publish \"\${MQTT_TOPIC}/status/\${c}\" \"\$STATUS\"
    done

    # 3) Uso de disco Docker (simples e leve)
    docker system df --format \"{{.Type}}|{{.TotalCount}}|{{.Size}}\" 2>/dev/null |
    while IFS=\"|\" read -r type count size; do
        case \"\$type\" in
            Images)
                mqtt_publish \"\${MQTT_TOPIC}/disk/images_count\" \"\$count\"
                mqtt_publish \"\${MQTT_TOPIC}/disk/images_used\" \"\$size\"
                ;;
            Containers)
                mqtt_publish \"\${MQTT_TOPIC}/disk/containers_count\" \"\$count\"
                mqtt_publish \"\${MQTT_TOPIC}/disk/containers_used\" \"\$size\"
                ;;
            \"Local Volumes\")
                mqtt_publish \"\${MQTT_TOPIC}/disk/volumes_count\" \"\$count\"
                mqtt_publish \"\${MQTT_TOPIC}/disk/volumes_used\" \"\$size\"
                ;;
        esac
    done
}

# Loop principal
while true; do
    if systemctl is-active --quiet docker; then
        get_docker_metrics
    fi
    sleep \"\$INTERVAL_SECONDS\"
done
EOF_REPORTER_SCRIPT" || { print_log "$(log_error)" "$(echo_red "Falha ao criar o script docker_reporter.sh.")" && exit 1; }
            sudo chmod +x "${DOCKER_REPORTER_SCRIPT}" || { print_log "$(log_error)" "$(echo_red "Falha ao tornar o script docker_reporter.sh executável.")" && exit 1; }
        fi

        if [ ! -f "${REPORTER_SERVICE_FILE}" ]; then
            sudo bash -c "cat << 'EOF_REPORTER_SERVICE' > ${REPORTER_SERVICE_FILE}
[Unit]
Description=Docker MQTT Reporter Service
After=network.target docker.service mqtt.service

[Service]
ExecStart=/opt/docker_mqtt_scripts/docker_reporter.sh
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF_REPORTER_SERVICE" || { print_log "$(log_error)" "$(echo_red "Falha ao criar o arquivo de serviço do Docker Reporter.")" && exit 1; }
        fi

        # --- Configuração do Docker Command Listener ---
        if [ ! -f "${DOCKER_COMMAND_LISTENER_SCRIPT}" ]; then
            sudo bash -c "cat << 'EOF_COMMAND_SCRIPT' > ${DOCKER_COMMAND_LISTENER_SCRIPT}
#!/bin/bash
MQTT_BROKER=\"${MQTT_BROKER}\"
MQTT_PORT=\"${MQTT_PORT}\"
MQTT_USER=\"${MQTT_USER_DOCKER}\"
MQTT_PASSWORD='${MQTT_PASSWORD}'
MQTT_COMMAND_TOPIC=\"${MQTT_TOPIC_DOCKER}/command/#\"
mosquitto_sub -h \"\$MQTT_BROKER\" -p \"\$MQTT_PORT\" -u \"\$MQTT_USER\" -P \"\$MQTT_PASSWORD\" -t \"\$MQTT_COMMAND_TOPIC\" -q 1 | while read -r payload; do
    command=\$(echo \"\$payload\" | awk '{print \$1}')
    container_name=\$(echo \"\$payload\" | awk '{print \$2}')
    if [ -z \"\$command\" ] || [ -z \"\$container_name\" ]; then
        continue
    fi
    case \"\$command\" in
        \"start\")
            docker start \"\$container_name\"
            ;;
        \"stop\")
            docker stop \"\$container_name\"
            ;;
        \"restart\")
            docker restart \"\$container_name\"
            ;;
        *)
            ;;
    esac
done
EOF_COMMAND_SCRIPT" || { print_log "$(log_error)" "$(echo_red "Falha ao criar o script docker_command_listener.sh.")" && exit 1; }
            sudo chmod +x "${DOCKER_COMMAND_LISTENER_SCRIPT}" || { print_log "$(log_error)" "$(echo_red "Falha ao tornar o script docker_command_listener.sh executável.")" && exit 1; }
        fi

        if [ ! -f "${COMMAND_SERVICE_FILE}" ]; then
            sudo bash -c "cat << 'EOF_COMMAND_SERVICE' > ${COMMAND_SERVICE_FILE}
[Unit]
Description=Docker MQTT Command Listener Service
After=network.target docker.service mqtt.service

[Service]
ExecStart=/opt/docker_mqtt_scripts/docker_command_listener.sh
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF_COMMAND_SERVICE" || { print_log "$(log_error)" "$(echo_red "Falha ao criar o arquivo de serviço do Docker Command Listener.")" && exit 1; }
        fi

        # --- Configuração do RPi-Reporter ---
        if [ ! -d "${RPI_REPORTER_DIR}" ]; then

            sudo git clone https://github.com/ironsheep/RPi-Reporter-MQTT2HA-Daemon.git "${RPI_REPORTER_DIR}" >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao clonar o repositório do RPi-Reporter.")" && exit 1; }

            sudo pip install --break-system-packages -r "${RPI_REPORTER_DIR}/requirements.txt" >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar dependências do RPi-Reporter.")" && exit 1; }
            
            sudo cp "${RPI_REPORTER_DIR}/config.ini.dist" "${RPI_REPORTER_DIR}/config.ini" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar o arquivo de configuração do RPi-Reporter.")" && exit 1; }

            # Comenta as seções [Commands] e [MQTT] existentes no arquivo inicial para evitar o erro de seção duplicada.
            sudo sed -i '/^\[Commands\]/s/^/#&/' "${RPI_REPORTER_DIR}/config.ini"
            sudo sed -i '/^\[MQTT\]/s/^/#&/' "${RPI_REPORTER_DIR}/config.ini"


            sudo bash -c "cat << EOF_RPI_CONFIG >> "${RPI_REPORTER_DIR}/config.ini"


[Commands]

Desligar_TV = /bin/bash -c \"echo 'standby 0' | cec-client -s\"

Ligar_TV = /bin/bash -c \"echo 'on 0' | cec-client -s\"

HDMI_1 = /bin/bash -c \"echo 'txn 1f:82:10:00' | cec-client -s\"

HDMI_2 = /bin/bash -c \"echo 'txn 1f:82:20:00' | cec-client -s\"

Reiniciar_Rasperry = sudo /sbin/reboot

PC = /bin/bash -c \"sudo pinctrl 6 op; sleep 0.1; sudo pinctrl 6 ip\"

Ligar_Computador = /bin/bash -c \"echo 'on 0' | cec-client -s; sudo pinctrl 6 op; sleep 0.1; sudo pinctrl 6 ip\"

Desligar_Computador = /bin/bash -c \"echo 'standby 0' | cec-client -s; sudo pinctrl 6 op; sleep 0.1; sudo pinctrl 6 ip\"


[MQTT]

hostname = ${MQTT_BROKER}
port = ${MQTT_PORT}
username = ${MQTT_USER_RPI}
password = ${MQTT_PASSWORD}
base_topic = ${MQTT_TOPIC_RPI}

EOF_RPI_CONFIG" || { print_log "$(log_error)" "$(echo_red "Falha ao adicionar configurações ao config.ini.")" && exit 1; }
        fi

        sudo usermod daemon -a -G video || { print_log "$(log_error)" "$(echo_red "Falha ao adicionar o usuário 'daemon' ao grupo 'video'.")" && exit 1; }

        if [ ! -L "${RPI_REPORTER_SERVICE_LINK}" ]; then
            sudo ln -s "${RPI_REPORTER_DIR}/isp-rpi-reporter.service" "${RPI_REPORTER_SERVICE_LINK}" || { print_log "$(log_error)" "$(echo_red "Falha ao criar o link simbólico do serviço do RPi-Reporter.")" && exit 1; }
        fi

        # --- Ativar e Iniciar Serviços ---
        sudo systemctl daemon-reload || { print_log "$(log_error)" "$(echo_red "Falha ao recarregar o daemon do systemd.")" && exit 1; }

        sudo systemctl enable docker-mqtt-reporter.service docker-mqtt-command.service isp-rpi-reporter.service >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "Falha ao habilitar serviços de monitoramento.")" && exit 1; }
        sudo systemctl start docker-mqtt-reporter.service docker-mqtt-command.service isp-rpi-reporter.service >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "Falha ao iniciar serviços de monitoramento.")" && exit 1; }

    } & # Executar tudo em um único processo em segundo plano
    local pid=$!

    if show_progress "INSTALANDO E CONFIGURANDO MONITORAMENTO..." $pid; then
        print_log "$(log_success)" "$(echo_green "MONITORAMENTO CONFIGURADO COM SUCESSO!")"
    else
        print_log "$(log_error)" "$(echo_red "A configuração do monitoramento falhou em uma das etapas.")"
        return 1
    fi
}

