install_monitor() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO A INSTALAÇÃO E CONFIGURAÇÃO DOS MONITORES MQTT...")"

    local DOCKER_REPORTER_SCRIPT="/opt/docker_mqtt_scripts/docker_reporter.sh"
    local REPORTER_SERVICE_FILE="/etc/systemd/system/docker-mqtt-reporter.service"
    local DOCKER_COMMAND_LISTENER_SCRIPT="/opt/docker_mqtt_scripts/docker_command_listener.sh"
    local COMMAND_SERVICE_FILE="/etc/systemd/system/docker-mqtt-command.service"
    local RPI_REPORTER_DIR="/opt/RPi-Reporter-MQTT2HA-Daemon"
    local RPI_REPORTER_SERVICE_LINK="/etc/systemd/system/isp-rpi-reporter.service"

    # Executar todas as etapas em um único processo em segundo plano
    {
        # --- Configuração do Docker Reporter ---
        if [ ! -f "${DOCKER_REPORTER_SCRIPT}" ]; then
            sudo mkdir -p /opt/docker_mqtt_scripts/ || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar diretório para scripts do Docker.")" && exit 1; }
            sudo bash -c "cat << 'EOF_REPORTER_SCRIPT' > ${DOCKER_REPORTER_SCRIPT}
#!/bin/bash
# Este script coleta informações de monitoramento do Docker e as publica em um broker MQTT.
MQTT_BROKER=\"${MQTT_BROKER}\"
MQTT_PORT=\"${MQTT_PORT}\"
MQTT_USER=\"${MQTT_USER_DOCKER}\"
MQTT_PASSWORD='${MQTT_PASSWORD}'
MQTT_TOPIC=\"${MQTT_TOPIC_DOCKER}\"
INTERVAL_SECONDS=${INTERVAL_SECONDS}
CONTAINERS_PARA_MONITORAR=(
$(printf '  "%s"\n' "${CONTAINERS_PARA_MONITORAR[@]}")
)
mqtt_publish() {
    local topic=\"\$1\"
    local message=\"\$2\"
    mosquitto_pub -h \"\$MQTT_BROKER\" -p \"\$MQTT_PORT\" -t \"\$topic\" -m \"\$message\" -r -u \"\$MQTT_USER\" -P \"\$MQTT_PASSWORD\"
}
size_to_bytes() {
    local size_str=\"\$1\"
    local value=\$(echo \"\$size_str\" | sed 's/[^0-9.]//g')
    local unit=\$(echo \"\$size_str\" | sed 's/[0-9.]//g')
    case \"\$unit\" in
        \"B\") echo \"\$value\" ;;
        \"kB\") echo \"\$value * 1024\" | bc ;;
        \"MB\") echo \"\$value * 1024 * 1024\" | bc ;;
        \"GB\") echo \"\$value * 1024 * 1024 * 1024\" | bc ;;
        \"TB\") echo \"\$value * 1024 * 1024 * 1024 * 1024\" | bc ;;
        *) echo \"0\" ;;
    esac
}
bytes_to_gb() {
    local bytes=\"\$1\"
    echo \"scale=2; \$bytes / (1024 * 1024 * 1024)\" | bc
}
get_docker_disk_usage() {
    local df_output_raw=\$(docker system df 2>/dev/null)
    local images_line=\$(echo \"\$df_output_raw\" | grep \"^Images\")
    local images_count=\$(echo \"\$images_line\" | awk '{print \$2}')
    local images_used_str=\$(echo \"\$images_line\" | awk '{print \$4}')
    if [ -z \"\$images_count\" ]; then images_count=\"0\"; fi
    if [ -z \"\$images_used_str\" ]; then images_used_str=\"0B\"; fi
    mqtt_publish \"\${MQTT_TOPIC}/disk/images_used\" \"\$images_used_str\"
    mqtt_publish \"\${MQTT_TOPIC}/disk/images_count\" \"\$images_count\"
    local containers_line=\$(echo \"\$df_output_raw\" | grep \"^Containers\")
    local containers_count=\$(echo \"\$containers_line\" | awk '{print \$2}')
    local containers_used_str=\$(echo \"\$containers_line\" | awk '{print \$4}')
    if [ -z \"\$containers_count\" ]; then containers_count=\"0\"; fi
    if [ -z \"\$containers_used_str\" ]; then containers_used_str=\"0B\"; fi
    mqtt_publish \"\${MQTT_TOPIC}/disk/containers_used\" \"\$containers_used_str\"
    mqtt_publish \"\${MQTT_TOPIC}/disk/containers_count\" \"\$containers_count\"
    local volumes_line=\$(echo \"\$df_output_raw\" | grep \"^Local Volumes\")
    local volumes_count=\$(echo \"\$volumes_line\" | awk '{print \$3}')
    local volumes_used_str=\$(echo \"\$volumes_line\" | awk '{print \$5}')
    if [ -z \"\$volumes_count\" ]; then volumes_count=\"0\"; fi
    if [ -z \"\$volumes_used_str\" ]; then volumes_used_str=\"0B\"; fi
    mqtt_publish \"\${MQTT_TOPIC}/disk/volumes_used\" \"\$volumes_used_str\"
    mqtt_publish \"\${MQTT_TOPIC}/disk/volumes_count\" \"\$volumes_count\"
    local total_bytes=0
    total_bytes=\$(echo \"\$total_bytes + \$(size_to_bytes \"\$images_used_str\")\" | bc)
    total_bytes=\$(echo \"\$total_bytes + \$(size_to_bytes \"\$containers_used_str\")\" | bc)
    total_bytes=\$(echo \"\$total_bytes + \$(size_to_bytes \"\$volumes_used_str\")\" | bc)
    local TOTAL_USAGE_GB=\$(bytes_to_gb \"\$total_bytes\")
    mqtt_publish \"\${MQTT_TOPIC}/disk/total_usage\" \"\${TOTAL_USAGE_GB}GB\"
}
get_container_stats() {
    for container_name in \"\${CONTAINERS_PARA_MONITORAR[@]}\"; do
        CONTAINER_STATUS=\$(docker inspect -f '{{.State.Status}}' \"\$container_name\" 2>/dev/null)
        if [ -n \"\$CONTAINER_STATUS\" ]; then
            STATS=\$(docker stats --no-stream --format \"{{.Name}}|{{.CPUPerc}}\" \"\$container_name\" 2>/dev/null)
            if [ -n \"\$STATS\" ]; then
                IFS=\"|\" read -r name cpu_perc <<< \"\$STATS\"
                mqtt_publish \"\${MQTT_TOPIC}/container/\${name}/cpu_usage\" \"\$cpu_perc\"
                mqtt_publish \"\${MQTT_TOPIC}/status/\${name}\" \"\$CONTAINER_STATUS\"
            else
                mqtt_publish \"\${MQTT_TOPIC}/container/\${container_name}/cpu_usage\" \"N/A\"
                mqtt_publish \"\${MQTT_TOPIC}/status/\${container_name}\" \"\$CONTAINER_STATUS\"
            fi
        else
            mqtt_publish \"\${MQTT_TOPIC}/container/\${container_name}/cpu_usage\" \"N/A\"
            mqtt_publish \"\${MQTT_TOPIC}/status/\${container_name}\" \"not_found\"
        fi
    done
}
while true; do
    get_docker_disk_usage
    get_container_stats
    sleep \"\$INTERVAL_SECONDS\"
done
EOF_REPORTER_SCRIPT" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar o script docker_reporter.sh.")" && exit 1; }
            sudo chmod +x "${DOCKER_REPORTER_SCRIPT}" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao tornar o script docker_reporter.sh executável.")" && exit 1; }
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
EOF_REPORTER_SERVICE" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar o arquivo de serviço do Docker Reporter.")" && exit 1; }
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
EOF_COMMAND_SCRIPT" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar o script docker_command_listener.sh.")" && exit 1; }
            sudo chmod +x "${DOCKER_COMMAND_LISTENER_SCRIPT}" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao tornar o script docker_command_listener.sh executável.")" && exit 1; }
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
EOF_COMMAND_SERVICE" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar o arquivo de serviço do Docker Command Listener.")" && exit 1; }
        fi

        # --- Configuração do RPi-Reporter ---
        if [ ! -d "${RPI_REPORTER_DIR}" ]; then

            sudo git clone https://github.com/ironsheep/RPi-Reporter-MQTT2HA-Daemon.git "${RPI_REPORTER_DIR}" >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao clonar o repositório do RPi-Reporter.")" && exit 1; }
            cd "${RPI_REPORTER_DIR}" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao mudar para o diretório do RPi-Reporter.")" && exit 1; }

            pip install --break-system-packages -r requirements.txt >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar dependências do RPi-Reporter.")" && exit 1; }
            sudo cp config.{ini.dist,ini} || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar o arquivo de configuração do RPi-Reporter.")" && exit 1; }

            sudo bash -c "cat << 'EOF_RPI_CONFIG' >> ${RPI_REPORTER_DIR}/config.ini

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

hostname = \"${MQTT_BROKER}\"
port = \"${MQTT_PORT}\"
username = \"${MQTT_USER_RPI}\"
password = '${MQTT_PASSWORD}'
base_topic = \"${MQTT_TOPIC_RPI}\"

EOF_RPI_CONFIG" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao adicionar configurações ao config.ini.")" && exit 1; }
        fi

        sudo usermod daemon -a -G video || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao adicionar o usuário 'daemon' ao grupo 'video'.")" && exit 1; }

        if [ ! -L "${RPI_REPORTER_SERVICE_LINK}" ]; then
            sudo ln -s "${RPI_REPORTER_DIR}/isp-rpi-reporter.service" "${RPI_REPORTER_SERVICE_LINK}" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar o link simbólico do serviço do RPi-Reporter.")" && exit 1; }
        fi

        # --- Ativar e Iniciar Serviços ---
        sudo systemctl daemon-reload || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao recarregar o daemon do systemd.")" && exit 1; }

        sudo systemctl enable docker-mqtt-reporter.service docker-mqtt-command.service isp-rpi-reporter.service >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao habilitar serviços de monitoramento.")" && exit 1; }
        sudo systemctl start docker-mqtt-reporter.service docker-mqtt-command.service isp-rpi-reporter.service >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao iniciar serviços de monitoramento.")" && exit 1; }

    } & # Executar tudo em um único processo em segundo plano
    local pid=$!

    if show_progress "INSTALANDO E CONFIGURANDO MONITORAMENTO..." $pid; then
        print_log "$(log_success)" "$(echo_green "MONITORAMENTO CONFIGURADO COM SUCESSO!")"
    else
        print_log "$(log_error)" "$(echo_red "A configuração do monitoramento falhou em uma das etapas.")"
        return 1
    fi
}

