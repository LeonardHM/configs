# Conteúdo desejado para commands.json
read -r -d '' COMMANDS_CONTENT << EOM
[
  {"trigger":"Reiniciar Rasperry","command":"sudo reboot","ground":"background","voice":"reiniciar raspberry","allowParams": "false"},
  {"trigger":"Desligar TV","command":"echo 'standby 0' | cec-client -s","ground":"background","voice":"desligar tv","allowParams": "false"},
  {"trigger":"Ligar TV","command":"echo 'on 0' | cec-client -s","ground":"background","voice":"ligar tv","allowParams": "false"},
  {"trigger":"HDMI 1","command":"echo 'txn 1f:82:10:00' | cec-client -s","ground":"background","voice":"hdmi 1","allowParams": "false"},
  {"trigger":"HDMI 2","command":"echo 'txn 1f:82:20:00' | cec-client -s","ground":"background","voice":"hdmi 2","allowParams": "false"},
  {"trigger":"PC","command":"sudo pinctrl 6 op; sleep 0.1; sudo pinctrl 6 ip","ground":"background","voice":"pc","allowParams": "false"},
  {"trigger":"Ligar Computador","command":"echo 'on 0' | cec-client -s; sudo pinctrl 6 op; sleep 0.1; sudo pinctrl 6 ip","ground":"background","voice":"ligar computador","allowParams": "false"},
  {"trigger":"Desligar Computador","command":"echo 'standby 0' | cec-client -s; sudo pinctrl 6 op; sleep 0.1; sudo pinctrl 6 ip","ground":"background","voice":"desligar computador","allowParams": "false"}
]
EOM

# Atenção: Ajuste a 'PHRASE_TO_CHECK' se você mudar significativamente os comandos.
# Escolha uma frase única que seja improvável de mudar e que represente a versão "correta" dos seus comandos.
# IMPORTANTE: Use aspas simples para proteger a string para o bash -c, e aspas duplas internas para o grep encontrar a string exata no JSON.
PHRASE_TO_CHECK='"reiniciar raspberry"'


commands_alexa() {
    local USER_TOKEN="$1"

    print_log "$(log_aviso)" "$(echo_red "CONFIGURANDO INTEGRAÇÃO COM ALEXA...")"

    PINCTRL_PATH=$(command -v pinctrl)
    if [ -z "$PINCTRL_PATH" ]; then
        print_log "$(log_error)" "$(echo_red "O programa pinctrl não foi encontrado! Por favor, instale-o.")"
        echo
        exit 1
    fi

    SUDOERS_FILE="/etc/sudoers.d/triggercmd"
    if ! sudo grep -q "$PINCTRL_PATH" "$SUDOERS_FILE" 2>/dev/null; then
        echo "$(whoami) ALL=(ALL) NOPASSWD: $PINCTRL_PATH, /sbin/reboot" | sudo tee -a "$SUDOERS_FILE" >/dev/null
        if [ $? -ne 0 ]; then
            print_log "$(log_error)" "$(echo_red "Erro ao adicionar permissões ao sudoers. Verifique suas permissões de root.")"
            echo
            exit 1
        fi
    fi

    echo
    instalar_programa cec-utils npm nodejs
    echo

    # Define o diretório de configuração para root
    CONFIG_DIR="/root/.TRIGGERcmdData"
    TOKEN_FILE="$CONFIG_DIR/token.tkn"
    COMMANDS_FILE="$CONFIG_DIR/commands.json"
    COMPUTERID_FILE="$CONFIG_DIR/computerid.cfg"

    # Garante que o diretório de configuração exista e tenha as permissões corretas
    sudo mkdir -p "$CONFIG_DIR"
    sudo chown root:root "$CONFIG_DIR"
    sudo chmod 700 "$CONFIG_DIR"

    # === VERIFICAR E CRIAR O ARQUIVO DE COMANDOS PERSONALIZADOS ===
    # Verifica se o arquivo de comandos existe E se contém a frase-chave, executando grep como root
    if sudo -E bash -c "[ -f \"$COMMANDS_FILE\" ] && grep -q '$PHRASE_TO_CHECK' \"$COMMANDS_FILE\""; then
        print_log "$(log_info)" "$(echo_yellow "Arquivo de comandos ('$COMMANDS_FILE') já está correto. Pulando recriação.")"
    else
        print_log "$(log_aviso)" "$(echo_orange "Arquivo de comandos ('$COMMANDS_FILE') ausente ou incorreto. Criando/Atualizando...")"
        echo "$COMMANDS_CONTENT" | sudo tee "$COMMANDS_FILE" >/dev/null
        if [ $? -ne 0 ]; then
            print_log "$(log_error)" "$(echo_red "Erro ao configurar os comandos do TriggerCMD em  '$COMMANDS_FILE'.")"
            exit 1
        fi
        print_log "$(log_success)" "$(echo_green "Arquivo de comandos criado/atualizado com sucesso.")"
    fi

    # Instala TriggerCMD se não existir
    if ! command -v triggercmdagent &>/dev/null; then
        (
            wget -q https://s3.amazonaws.com/triggercmdagents/triggercmdagent_1.0.1_all.deb -O /tmp/triggercmdagent.deb
            if [ $? -ne 0 ]; then
                exit 1
            fi
            sudo dpkg -i /tmp/triggercmdagent.deb
            if [ $? -ne 0 ]; then
                exit 2
            fi
        ) >/tmp/triggercmd_install.log 2>&1 &

        PID_INSTALL=$!

        if ! show_progress "Instalando TriggerCMD..." "$PID_INSTALL"; then
            local install_status=$?
            if [ "$install_status" -eq 1 ]; then
                print_log "$(log_error)" "$(echo_red "Erro ao baixar o TriggerCMD. Verifique sua conexão com a internet ou o link. Consulte /tmp/triggercmd_install.log")"
            elif [ "$install_status" -eq 2 ]; then
                print_log "$(log_error)" "$(echo_red "Erro ao instalar o TriggerCMD. Consulte /tmp/triggercmd_install.log para mais detalhes")"
            else
                print_log "$(log_error)" "$(echo_red "Um erro inesperado ocorreu durante a instalação do TriggerCMD. Consulte /tmp/triggercmd_install.log")"
            fi
            exit 1
        fi
    else
        print_log "$(log_info)" "$(echo_yellow "TriggerCMD já instalado. Pulando instalação.")"
    fi

    sudo rm -f "$TOKEN_FILE" "$COMPUTERID_FILE" &>/dev/null

    tmpfile=$(mktemp)


    # === Lógica para o token ===
    # Prioriza o token passado como argumento/variável.
    if [ -n "$USER_TOKEN" ]; then
        print_log "$(log_info)" "$(echo_yellow "Token fornecido via argumento/variável. Salvando/Atualizando...")"
        echo -n "$USER_TOKEN" > "$tmpfile"
        chmod 600 "$tmpfile"
        sudo triggercmdagent < "$tmpfile" &>/dev/null &
        rm -f "$tmpfile"
        print_log "$(log_success)" "$(echo_green "Token salvo em $TOKEN_FILE")"
        echo
    elif [ -f "$TOKEN_FILE" ]; then
        # Se nenhum token foi passado como argumento, mas o arquivo existe, usa o existente.
        print_log "$(log_info)" "$(echo_yellow "Token já existe em $TOKEN_FILE. Pulando solicitação interativa.")"
        sudo triggercmdagent < "$TOKEN_FILE" &>/dev/null &
    else
        # Se nenhum token foi passado e o arquivo não existe, solicita interativamente.
        print_log "$(log_aviso)" "$(echo_orange "Nenhum token encontrado. Solicitando...")"
        read -p "Digite o token do TriggerCMD: " INTERACTIVE_TOKEN

        echo -n "$INTERACTIVE_TOKEN" > "$tmpfile"
        chmod 600 "$tmpfile"
        sudo triggercmdagent < "$tmpfile" &>/dev/null &
        rm -f "$tmpfile"

        print_log "$(log_success)" "$(echo_green "Token salvo em $TOKEN_FILE")"
        echo
    fi

    # ativa o agent e o daemon
    # Verifica se o daemon do TriggerCMD já está instalado, ativo e habilitado.
    if systemctl is-active --quiet triggercmdagent && systemctl is-enabled --quiet triggercmdagent; then
        print_log "$(log_info)" "$(echo_yellow "Daemon do TriggerCMD já está instalado, ativo e habilitado. Pulando instalação.")"
        sudo systemctl restart triggercmdagent.service
    else
        # Se não estiver instalado, ativo ou habilitado, inicia o processo de instalação em segundo plano
        print_log "$(log_info)" "$(echo_orange "Daemon do TriggerCMD inativo ou ausente. Ativando e verificando instalação...")"

        (sudo sh /usr/share/triggercmdagent/app/src/installdaemon.sh >/tmp/triggercmd_daemon.log 2>&1) &
        PID_DAEMON=$!
        if ! show_progress "Instalando daemon do TriggerCMD..." "$PID_DAEMON"; then
            print_log "$(log_error)" "$(echo_red "Erro ao instalar o daemon do TriggerCMD. Consulte /tmp/triggercmd_daemon.log para mais detalhes")"
            echo
            exit 1
        fi
    fi

    print_log "$(log_success)" "$(echo_green "Configuração da Alexa com TriggerCMD concluída com sucesso!")"
    echo
}


uninstall_triggercmd() {
    ############ DESISTALAR ##############
    print_log "$(log_aviso)" "$(echo_red "Desistalando TriggerCMD...")"
    sudo systemctl stop triggercmdagent
    sudo systemctl disable triggercmdagent
    sudo service triggercmdagent stop
    sudo apt-get purge triggercmdagent
    sudo rm -rf /usr/share/triggercmdagent
    sudo rm -rf /root/.TRIGGERcmdData
    sudo rm -rf ~/.TRIGGERcmdData
    sudo rm /etc/sudoers.d/triggercmd
    sudo rm -f /tmp/triggercmdagent.deb
    sudo rm /tmp/triggercmd_install.log
    sudo rm /tmp/triggercmd_daemon.log
    sudo apt-get clean
    sudo apt update
}

