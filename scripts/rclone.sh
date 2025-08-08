configurar_rclone() {
    print_log "$(log_aviso)" "$(echo_red "CONFIGURANDO RCLONE")"

    # Atualizar sistema e instalar pacotes necessários
    print_log "$(log_info)" "$(echo_orange "Atualizando o sistema e instalando pacotes necessários...")"
    apt_update >/dev/null 2>&1
    instalar_programa rclone fuse3 >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar rclone e/ou fuse3.")"; return 1; }
    print_log "$(log_success)" "$(echo_green "rclone e fuse3 instalados com sucesso.")"

    # Criar diretórios
    print_log "$(log_info)" "$(echo_orange "Criando diretórios necessários...")"
    mkdir -p $HOME/.config/rclone || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar diretório de configuração do rclone.")"; return 1; }
    sudo chmod 777 $HOME/.config
    sudo mkdir -p /media/GDrive || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar diretório de montagem /media/GDrive.")"; return 1; }
    print_log "$(log_success)" "$(echo_green "Diretórios criados com sucesso.")"

    # Criar arquivo de configuração do rclone
    print_log "$(log_info)" "$(echo_orange "Criando arquivo de configuração do rclone...")"
    cat <<EOL > $HOME/.config/rclone/rclone.conf
[GDrive]
type = drive
${RCLONE_CONFIG[0]}
${RCLONE_CONFIG[1]}
scope = drive
token =
EOL
    print_log "$(log_success)" "$(echo_green "Arquivo de configuração criado.")"

    # Configurar montagem
    print_log "$(log_info)" "$(echo_orange "Configurando a montagem e o serviço...")"
    sudo ln -s /usr/bin/fusermount /usr/bin/fusermount3 2>/dev/null || true
    sudo rclone config reconnect GDrive: --auto-confirm >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao reconectar a configuração do rclone.")"; return 1; }
    sudo rclone mount GDrive:/ /media/GDrive --vfs-cache-mode full --vfs-cache-max-age 12h --vfs-cache-max-size 1G --allow-other &
    print_log "$(log_success)" "$(echo_green "Montagem do Google Drive configurada.")"

    # Criar serviço systemd
    print_log "$(log_info)" "$(echo_orange "Criando o serviço systemd para rclone...")"
    sudo tee /etc/systemd/system/rclone.service > /dev/null <<EOL
[Unit]
Description=Mount Google Drive with rclone
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount GDrive:/ /media/GDrive --vfs-cache-mode full --vfs-cache-max-age 12h --vfs-cache-max-size 1G --allow-other
ExecStop=/bin/fusermount -u /media/GDrive
Restart=always
User=$USER

[Install]
WantedBy=default.target
EOL
    print_log "$(log_success)" "$(echo_green "Serviço systemd criado.")"

    # Habilitar serviço
    print_log "$(log_info)" "$(echo_orange "Habilitando e iniciando o serviço rclone...")"
    sudo systemctl enable rclone.service >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao habilitar o serviço rclone.")"; return 1; }
    sudo systemctl start rclone.service >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao iniciar o serviço rclone.")"; return 1; }
    print_log "$(log_success)" "$(echo_green "CONFIGURAÇÃO DO RCLONE CONCLUÍDA. O SERVIÇO FOI HABILITADO E INICIADO PARA INICIAR AUTOMATICAMENTE.")"
}

