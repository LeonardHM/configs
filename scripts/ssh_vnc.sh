# --- Funções de gerenciamento SSH ---

# Função para ativar o SSH usando raspi-config
ssh_rasp_config() {
    print_log "$(log_aviso)" "$(echo_red "ATIVANDO SSH via raspi-config")"
    sudo raspi-config nonint do_ssh 0 >/dev/null 2>&1 || {
        print_log "$(log_error)" "$(echo_red "ERRO: Falha ao ativar SSH via raspi-config.")"
        return 1
    }
    print_log "$(log_success)" "$(echo_green "SSH ativado com sucesso.")"
}

# Função para ativar um servidor SSH, instalando se necessário.
ssh_others() {
    print_log "$(log_aviso)" "$(echo_red "GERENCIANDO SERVIÇO SSH")"

    if is_installed "openssh-server"; then
        print_log "$(log_info)" "$(echo_yellow "openssh-server já está instalado.")"
    else
        print_log "$(log_aviso)" "$(echo_orange "O pacote openssh-server não está instalado. Instalando...")"
        apt_update >/dev/null 2>&1
        instalar_programa openssh-server >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar openssh-server.")"
            return 1
        }
        print_log "$(log_success)" "$(echo_green "openssh-server instalado com sucesso.")"
    fi

    if systemctl is-active --quiet ssh; then
        print_log "$(log_info)" "$(echo_yellow "Serviço SSH já está ativo.")"
    else
        print_log "$(log_info)" "$(echo_orange "Iniciando e habilitando o serviço SSH...")"
        sudo systemctl enable --now ssh >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao iniciar e habilitar o serviço SSH.")"
            return 1
        }
        if systemctl is-active --quiet ssh; then
            print_log "$(log_success)" "$(echo_green "Serviço SSH ativado com sucesso.")"
        else
            print_log "$(log_error)" "$(echo_red "Falha ao ativar o SSH.")"
            return 1
        fi
    fi
    print_log "$(log_success)" "$(echo_green "Gerenciamento de SSH concluído.")"
}


# --- Funções de gerenciamento VNC ---

# Função principal para gerenciar ou iniciar uma sessão VNC
gerenciar_sessao_vnc() {
    local vnc_method="$1"
    local vnc_log_file="$HOME/.vnc/raspberrypi:1.log"

    # 1. Verifica se já existe uma sessão ativa
    local vnc_pid=$(pgrep -f "Xvnc" | head -n 1)

    if [ -n "$vnc_pid" ]; then
        local vnc_ip=$(grep "New desktop is" "$vnc_log_file" 2>/dev/null | awk '{print $NF}' | tr -d '()')
        print_log "$(log_success)" "$(echo_green "Sessão VNC já está em execução usando ($vnc_method) em: $vnc_ip, PID: $vnc_pid")"
        print_log "$(log_info)" "$(echo_yellow "Para parar o VNC Server: vncserver -kill :1 ou sudo kill $vnc_pid")"
        return 0
    fi

    # 2. Se não existe sessão, inicia uma nova
    print_log "$(log_info)" "$(echo_orange "Iniciando nova sessão VNC ($vnc_method)...")"

    case "$vnc_method" in
        "raspi-config"|"realvnc")
            vncserver-virtual :1 -geometry 1024x768 >/dev/null 2>&1 &
            local vnc_pid=$!
            ;;
        "tightvnc")
            vncserver :1 -geometry 1024x768 >/dev/null 2>&1 &
            local vnc_pid=$!
            ;;
        *)
            print_log "$(log_error)" "$(echo_red "Método VNC não reconhecido: $vnc_method")"
            return 1
            ;;
    esac

    # 3. Aguarda inicialização
    sleep 5

    # 4. Verifica se o processo realmente iniciou
    if ! kill -0 "$vnc_pid" 2>/dev/null; then
        print_log "$(log_error)" "$(echo_red "Falha ao iniciar o processo VNC (PID: $vnc_pid)")"
        return 1
    fi

    # 5. Pega o PID real do Xvnc (caso seja wrapper)
    local xvnc_pid=$(pgrep -P "$vnc_pid" | head -n 1)
    [ -n "$xvnc_pid" ] && vnc_pid="$xvnc_pid"

    # 6. Aguarda o log até 10s
    local tries=0
    while [ ! -f "$vnc_log_file" ] && [ $tries -lt 10 ]; do
        sleep 1
        ((tries++))
    done

    if [ ! -f "$vnc_log_file" ]; then
        print_log "$(log_error)" "$(echo_red "Log VNC não encontrado em $vnc_log_file")"
        return 1
    fi

    # 7. Obtém o IP da sessão
    local vnc_ip=$(grep "New desktop is" "$vnc_log_file" | awk '{print $NF}' | tr -d '()')
    if [ -z "$vnc_ip" ]; then
        print_log "$(log_error)" "$(echo_red "Falha ao obter o IP da sessão VNC.")"
        return 1
    fi

    # 8. Exibe status final
    print_log "$(log_success)" "$(echo_green "Sessão VNC iniciada usando ($vnc_method) em: $vnc_ip, PID: $vnc_pid")"
    print_log "$(log_info)" "$(echo_yellow "Para parar o VNC Server: vncserver -kill :1 ou sudo kill $vnc_pid")"
}

# Ativa o VNC via raspi-config e chama gerenciador
vnc_rasp_config() {
    print_log "$(log_aviso)" "$(echo_red "ATIVANDO VNC SERVER via raspi-config")"
    if sudo raspi-config nonint do_vnc 0 >/dev/null 2>&1; then
        gerenciar_sessao_vnc "raspi-config"
    else
        print_log "$(log_error)" "$(echo_red "ERRO: Falha ao ativar VNC Server via raspi-config.")"
        return 1
    fi
}

# Ativa qualquer outro servidor VNC instalado
vnc_others() {
    local vnc_service="$1"
    local vnc_method="$2"

    if systemctl is-active --quiet "$vnc_service"; then
        print_log "$(log_info)" "$(echo_yellow "Serviço VNC ($vnc_service) já está ativo.")"
    else
        print_log "$(log_info)" "$(echo_orange "Iniciando e habilitando o serviço VNC ($vnc_service)...")"
        if sudo systemctl enable --now "$vnc_service" >/dev/null 2>&1; then
            print_log "$(log_success)" "$(echo_green "Serviço VNC ($vnc_service) ativado com sucesso.")"
        else
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao habilitar/iniciar o serviço VNC.")"
            return 1
        fi
    fi

    gerenciar_sessao_vnc "$vnc_method"
}

