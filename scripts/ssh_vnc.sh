
# --- Funções de gerenciamento SSH ---

# Função para ativar o SSH usando raspi-config
rasp_config_ssh() {
    print_log "$(log_aviso)" "$(echo_red "ATIVANDO SSH via raspi-config")"
    sudo raspi-config nonint do_ssh 0 >/dev/null 2>&1 || {
        print_log "$(log_error)" "$(echo_red "ERRO: Falha ao ativar SSH via raspi-config.")"
        return 1
    }
    print_log "$(log_success)" "$(echo_green "SSH ativado com sucesso.")"
}

# Função para ativar um servidor SSH, instalando se necessário.
gerenciar_ssh() {
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
        sudo systemctl enable ssh >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao habilitar o serviço SSH.")"
            return 1
        }
        sudo systemctl start ssh >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao iniciar o serviço SSH.")"
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

# Função para ativar o VNC Server usando raspi-config
rasp_config_vnc() {
    print_log "$(log_aviso)" "$(echo_red "ATIVANDO VNC SERVER via raspi-config")"
    sudo raspi-config nonint do_vnc 0 >/dev/null 2>&1 || {
        print_log "$(log_error)" "$(echo_red "ERRO: Falha ao ativar VNC Server via raspi-config.")"
        return 1
    }

    if ! pgrep -f "vncserver :1"; then
        print_log "$(log_info)" "$(echo_orange "Iniciando sessão VNC padrão...")"
        vncserver :1 -geometry 1024x768 >/dev/null 2>&1
        print_log "$(log_success)" "$(echo_green "Sessão VNC iniciada na tela :1.")"
    else
        print_log "$(log_info)" "$(echo_yellow "Sessão VNC na tela :1 já está em execução.")"
    fi

    print_log "$(log_success)" "$(echo_green "Gerenciamento de VNC concluído.")"
    print_log "$(log_success)" "$(echo_green "VNC Server ativado com sucesso.")"
}

# Função para instalar e ativar um servidor VNC
gerenciar_vnc() {
    print_log "$(log_aviso)" "$(echo_red "GERENCIANDO SERVIÇO VNC")"

    local vnc_package="realvnc-vnc-server"

    if is_installed "$vnc_package"; then
        print_log "$(log_info)" "$(echo_yellow "O pacote $vnc_package já está instalado.")"
    else
        print_log "$(log_aviso)" "$(echo_orange "O pacote $vnc_package não está instalado. Instalando...")"
        apt_update >/dev/null 2>&1
        instalar_programa "$vnc_package" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar $vnc_package.")"
            return 1
        }
        print_log "$(log_success)" "$(echo_green "$vnc_package instalado com sucesso.")"
    fi

    local service_name="vncserver-x11-serviced.service"
    if systemctl is-active --quiet "$service_name"; then
        print_log "$(log_info)" "$(echo_yellow "Serviço VNC ($service_name) já está ativo.")"
    else
        print_log "$(log_info)" "$(echo_orange "Iniciando e habilitando o serviço VNC ($service_name)...")"
        sudo systemctl enable "$service_name" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao habilitar o serviço VNC.")"
            return 1
        }
        sudo systemctl start "$service_name" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao iniciar o serviço VNC.")"
            return 1
        }
        if systemctl is-active --quiet "$service_name"; then
            print_log "$(log_success)" "$(echo_green "Serviço VNC ativado com sucesso.")"
        else
            print_log "$(log_error)" "$(echo_red "Falha ao ativar o VNC Server.")"
            return 1
        fi
    fi

    if ! pgrep -f "vncserver :1"; then
        print_log "$(log_info)" "$(echo_orange "Iniciando sessão VNC padrão...")"
        vncserver :1 -geometry 1024x768 >/dev/null 2>&1
        print_log "$(log_success)" "$(echo_green "Sessão VNC iniciada na tela :1.")"
    else
        print_log "$(log_info)" "$(echo_yellow "Sessão VNC na tela :1 já está em execução.")"
    fi

    print_log "$(log_success)" "$(echo_green "Gerenciamento de VNC concluído.")"
}

