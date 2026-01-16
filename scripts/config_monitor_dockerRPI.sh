install_monitor() {
    print_log "$(log_aviso)" "$(echo_red "INSTALANDO MONITORES MQTT...")"

    # --- 1. Validações e Binários (Fail Fast) ---
    : "${MQTT_BROKER:?Erro: MQTT_BROKER não definido}"
    : "${MQTT_PORT:?Erro: MQTT_PORT não definido}"
    : "${MQTT_TOPIC_DOCKER:?Erro: MQTT_TOPIC_DOCKER não definido}"
    : "${MQTT_USER_DOCKER:?Erro: MQTT_USER_DOCKER não definido}"
    : "${MQTT_PASSWORD:?Erro: MQTT_PASSWORD não definido}"

    local DOCKER_BIN; DOCKER_BIN="$(command -v docker)" || { print_log "$(log_error)" "docker não encontrado"; return 1; }
    local PUB_BIN; PUB_BIN="$(command -v mosquitto_pub)" || { print_log "$(log_error)" "mosquitto_pub não encontrado"; return 1; }
    local SUB_BIN; SUB_BIN="$(command -v mosquitto_sub)" || { print_log "$(log_error)" "mosquitto_sub não encontrado"; return 1; }
    local NC_BIN; NC_BIN="$(command -v nc)" || { print_log "$(log_error)" "nc não encontrado"; return 1; }
    local PYTHON_BIN; PYTHON_BIN="$(command -v python3)" || { print_log "$(log_error)" "python3 não encontrado"; return 1; }

    # --- 2. Definição de Paths ---
    local SCRIPTS_DIR="/opt/docker_mqtt_scripts"
    local ENV_FILE="/etc/docker_mqtt.env"
    local PASS_FILE="/etc/docker_mqtt.pass"
    local REPORTER_SCRIPT="${SCRIPTS_DIR}/docker_reporter.sh"
    local COMMAND_SCRIPT="${SCRIPTS_DIR}/docker_command_listener.sh"
    local RPI_DIR="/opt/RPi-Reporter-MQTT2HA-Daemon"

    sudo mkdir -p "$SCRIPTS_DIR"
    sudo chown root:root "$SCRIPTS_DIR"
    sudo chmod 750 "$SCRIPTS_DIR" # Apenas root e grupo root leem

    {
        # --- 3. Escrita Atômica de Segredos ---
        # Cria arquivos temporários, ajusta permissões e move atomicamente.
        
        # 3.1 ENV FILE (Configurações gerais)
        local TMP_ENV; TMP_ENV=$(mktemp)
        cat <<EOF > "$TMP_ENV"
MQTT_BROKER="${MQTT_BROKER}"
MQTT_PORT="${MQTT_PORT}"
MQTT_USER="${MQTT_USER_DOCKER}"
MQTT_TOPIC="${MQTT_TOPIC_DOCKER}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-60}"
EOF
        sudo chown root:root "$TMP_ENV"
        sudo chmod 600 "$TMP_ENV"
        sudo mv "$TMP_ENV" "$ENV_FILE"

        # 3.2 PASS FILE (Apenas a senha)
        local TMP_PASS; TMP_PASS=$(mktemp)
        echo -n "${MQTT_PASSWORD}" > "$TMP_PASS"
        sudo chown root:root "$TMP_PASS"
        sudo chmod 600 "$TMP_PASS"
        sudo mv "$TMP_PASS" "$PASS_FILE"

        # --- 4. Detecção de Capacidade (--pw-file) ---
        # Define qual estratégia o script gerado usará, sem hardcodar a senha no script.
        local USE_PW_FILE="false"
        if "$PUB_BIN" --help 2>&1 | grep -q -- '--pw-file'; then
            USE_PW_FILE="true"
        fi

        # --- 5. Service: mqtt-ready (Com Timeout Seguro) ---
        local TMP_SVC; TMP_SVC=$(mktemp)
        cat <<EOF > "$TMP_SVC"
[Unit]
Description=Wait for MQTT broker to be ready
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
# Tenta conectar por 30s. Se falhar, sai com 0 para não quebrar o boot, mas loga o erro.
ExecStart=/bin/bash -c 'for i in {1..30}; do ${NC_BIN} -z -w 2 ${MQTT_BROKER} ${MQTT_PORT} && exit 0; sleep 1; done; echo "MQTT Warning: Broker not reachable after 30s"; exit 0'
TimeoutStartSec=35
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        sudo mv "$TMP_SVC" /etc/systemd/system/mqtt-ready.service

        # --- 6. Script: Docker Reporter (Com Monitoramento de Disco Diário) ---
        local containers_line
        containers_line=$(printf '"%s" ' "${CONTAINERS_PARA_MONITORAR[@]}")

        cat <<EOF | sudo tee "$REPORTER_SCRIPT" > /dev/null
#!/bin/bash
set -euo pipefail
trap 'exit 0' SIGINT SIGTERM

# Carregar ambiente
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

DOCKER_BIN="${DOCKER_BIN}"
PUB_BIN="${PUB_BIN}"
PASS_FILE="${PASS_FILE}"

# Autenticação MQTT
AUTH_ARGS=()
if [ "$USE_PW_FILE" = "true" ]; then
    AUTH_ARGS=("--pw-file" "\$PASS_FILE")
else
    AUTH_ARGS=("-P" "\$(< \$PASS_FILE)")
fi

CONTAINERS=(${containers_line})

# Defaults
: "\${MQTT_BROKER:?}"
: "\${MQTT_PORT:?}"
: "\${MQTT_USER:?}"
: "\${MQTT_TOPIC:?}"
INTERVAL="\${INTERVAL_SECONDS:-60}"

# Variável para controlar o loop diário (Inicializa zerado para rodar na primeira vez)
LAST_DISK_CHECK=0
ONE_DAY_SEC=86400

# Função Helper para publicar
mqtt_pub() {
    local subtopic="\$1"
    local msg="\$2"
    "\$PUB_BIN" -h "\$MQTT_BROKER" -p "\$MQTT_PORT" -u "\$MQTT_USER" "\${AUTH_ARGS[@]}" \
        -t "\$MQTT_TOPIC/\$subtopic" -m "\$msg" -r
}

while true; do
    NOW=\$(date +%s)

    # --- BLOCO 1: Monitoramento Diário de Disco (Executa a cada 24h) ---
    if [ \$((NOW - LAST_DISK_CHECK)) -ge \$ONE_DAY_SEC ] || [ "\$LAST_DISK_CHECK" -eq 0 ]; then
        echo "Executando verificação diária de disco..." | systemd-cat -t docker-mqtt-reporter
        
        # 1.1 Totais do Docker (Total em disco real)
        # Tenta pegar o tamanho da pasta root do Docker (geralmente /var/lib/docker)
        TOTAL_SIZE=\$(du -sh /var/lib/docker 2>/dev/null | awk '{print \$1}' || echo "unknown")
        mqtt_pub "system/disk/total_usage" "\$TOTAL_SIZE"

        # 1.2 Detalhes por Objeto (Imagens, Containers, Volumes)
        # Formato output do docker df: "Type  TotalCount  Active  Size  Reclaimable"
        # Parsing linha a linha.
        "\$DOCKER_BIN" system df --format '{{.Type}}|{{.TotalCount}}|{{.Size}}' | while IFS='|' read -r type count size; do
            case "\$type" in
                "Images")
                    mqtt_pub "system/images/count" "\$count"
                    mqtt_pub "system/images/size" "\$size"
                    ;;
                "Containers")
                    mqtt_pub "system/containers/count" "\$count"
                    mqtt_pub "system/containers/size" "\$size"
                    ;;
                "Local Volumes")
                    mqtt_pub "system/volumes/count" "\$count"
                    mqtt_pub "system/volumes/size" "\$size"
                    ;;
                "Build Cache")
                    mqtt_pub "system/cache/size" "\$size"
                    ;;
            esac
        done
        
        LAST_DISK_CHECK=\$NOW
    fi

    # --- BLOCO 2: Monitoramento Rápido (Containers Específicos) ---
    if [ "\${#CONTAINERS[@]}" -gt 0 ]; then
        for name in "\${CONTAINERS[@]}"; do
            STATUS=\$("\$DOCKER_BIN" inspect -f '{{.State.Status}}' "\$name" 2>/dev/null || echo "not_found")
            mqtt_pub "status/\$name" "\$STATUS"

            if [ "\$STATUS" = "running" ]; then
                CPU=\$("\$DOCKER_BIN" stats --no-stream --format "{{.CPUPerc}}" "\$name" 2>/dev/null | sed 's/%//' || echo "0")
                mqtt_pub "container/\$name/cpu_usage" "\$CPU"
            fi
        done
    fi

    sleep "\$INTERVAL"
done
EOF
        sudo chown root:root "$REPORTER_SCRIPT"
        sudo chmod 750 "$REPORTER_SCRIPT"        

        # --- 7. Script: Command Listener ---
        cat <<EOF | sudo tee "$COMMAND_SCRIPT" > /dev/null
#!/bin/bash
set -euo pipefail
# Mata mosquitto_sub filho ao receber sinal
trap 'pkill -P \$\$ 2>/dev/null || true; exit 0' SIGINT SIGTERM

[ -f "$ENV_FILE" ] && . "$ENV_FILE"

DOCKER_BIN="${DOCKER_BIN}"
SUB_BIN="${SUB_BIN}"
PASS_FILE="${PASS_FILE}"

AUTH_ARGS=()
if [ "$USE_PW_FILE" = "true" ]; then
    AUTH_ARGS=("--pw-file" "\$PASS_FILE")
else
    AUTH_ARGS=("-P" "\$(< \$PASS_FILE)")
fi

# Loop com Process Substitution (seguro para traps)
while read -r payload; do
    cmd=\$(awk '{print \$1}' <<< "\$payload")
    target=\$(awk '{print \$2}' <<< "\$payload")
    
    if [[ "\$cmd" =~ ^(start|stop|restart)\$ ]] && [ -n "\$target" ]; then
        echo "Executando: docker \$cmd \$target"
        "\$DOCKER_BIN" "\$cmd" "\$target" || true
    fi
done < <("\$SUB_BIN" -h "\$MQTT_BROKER" -p "\$MQTT_PORT" -u "\$MQTT_USER" "\${AUTH_ARGS[@]}" -t "\$MQTT_TOPIC/command/#")
EOF
        sudo chown root:root "$COMMAND_SCRIPT"
        sudo chmod 750 "$COMMAND_SCRIPT"

        # --- 8. Units Systemd (Hardening + Health Check) ---
        for type in "reporter" "command"; do
            local script_path="$REPORTER_SCRIPT"
            [ "$type" == "command" ] && script_path="$COMMAND_SCRIPT"
            
            # ExecStartPre:
            # 1. Verifica se docker binário é executável
            # 2. Verifica conectividade básica TCP com broker (fail-fast)
            
            local SVC_TMP; SVC_TMP=$(mktemp)
            cat <<EOF > "$SVC_TMP"
[Unit]
Description=Docker MQTT ${type^}
Wants=mqtt-ready.service
After=docker.service mqtt-ready.service network-online.target

[Service]
EnvironmentFile=${ENV_FILE}
ExecStart=${script_path}
# Health Checks antes de iniciar
ExecStartPre=/usr/bin/test -x ${DOCKER_BIN}
ExecStartPre=/bin/bash -c '${NC_BIN} -z -w 2 \${MQTT_BROKER} \${MQTT_PORT} || exit 0' 

Restart=always
RestartSec=30
TimeoutStartSec=35
KillMode=control-group
User=root

# Hardening (Ajuste conforme necessário)
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=yes
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
            sudo mv "$SVC_TMP" "/etc/systemd/system/docker-mqtt-${type}.service"
        done

        # --- 9. RPi-Reporter e Link ---
        if [ ! -d "$RPI_DIR" ]; then
            sudo git clone https://github.com/ironsheep/RPi-Reporter-MQTT2HA-Daemon.git "$RPI_DIR" || print_log "$(log_error)" "Clone RPi falhou"
            sudo "$PYTHON_BIN" -m pip install --break-system-packages -r "${RPI_DIR}/requirements.txt" || print_log "$(log_error)" "Pip RPi falhou"
        fi
        if [ -f "${RPI_DIR}/isp-rpi-reporter.service" ]; then
            sudo ln -sf "${RPI_DIR}/isp-rpi-reporter.service" /etc/systemd/system/isp-rpi-reporter.service
        fi

        # --- 10. Ativação com Verificação de Erro ---
        if compgen -G "${SCRIPTS_DIR}/*.sh" >/dev/null; then
            sudo chmod +x "${SCRIPTS_DIR}"/*.sh
        fi

        sudo systemctl daemon-reload
        local srv_list=(mqtt-ready.service docker-mqtt-reporter.service docker-mqtt-command.service isp-rpi-reporter.service)
        
        for srv in "${srv_list[@]}"; do
            # Verifica se o arquivo unit existe antes de tentar ativar (evita erro no isp-rpi se não clonou)
            if systemctl list-unit-files "$srv" >/dev/null 2>&1 || [ -f "/etc/systemd/system/$srv" ]; then
                if ! sudo systemctl enable "$srv" >/dev/null 2>&1; then
                     print_log "$(log_error)" "Aviso: Não foi possível habilitar $srv"
                fi
                if ! sudo systemctl restart "$srv" >/dev/null 2>&1; then
                     print_log "$(log_error)" "ERRO: Falha ao iniciar $srv. Verificando logs..."
                     sudo journalctl -u "$srv" -n 20 --no-pager
                else
                     print_log "$(log_info)" "Serviço iniciado: $srv"
                fi
            fi
        done

    } &
    local pid=$!
    show_progress "MONITORAMENTO CONFIGURADO COM SUCESSO." "$pid"
}

