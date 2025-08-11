install_docker() {
    print_log "$(log_aviso)" "$(echo_red "INSTALANDO DOCKER...")"
    echo

    # 1. Verificar se a arquitetura e a distro são suportadas
    if [[ "$SISTEMA_TIPO" == "termux" || "$SISTEMA_TIPO" == "desconhecido" ]]; then
        print_log "$(log_aviso)" "$(echo_orange "Distribuição ($SISTEMA_TIPO) não suportada para configuração automática do Docker.")"
        return 1
    fi


   # Verifica a instalação do Docker
    if ! command -v docker &> /dev/null; then

        # Define as variáveis do debconf para iptables-persistent
        sudo debconf-set-selections <<EOF >/dev/null 2>&1
        iptables-persistent iptables-persistent/autosave_v4 boolean true
        iptables-persistent iptables-persistent/autosave_v6 boolean true
EOF

        instalar_programa "${server_install[@]}"
    else
        print_log "$(log_success)" "$(echo_green "Docker já está instalado.")"
        echo
    fi



    # Executar todas as etapas de instalação em um único processo em segundo plano
    {
        local REPO_URL="https://download.docker.com/linux/$DISTRO_NAME"
        local REPO_FILE="/etc/apt/sources.list.d/docker.list"
        local REPO_ENTRY="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $REPO_URL $DISTRO_CODENAME stable"

        # Apenas configura o repositório se ele ainda não existir
        if ! grep -Fxq "$REPO_ENTRY" "$REPO_FILE" 2>/dev/null; then
            apt_update >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao atualizar o apt.")" && exit 1; }
            instalar_programa ca-certificates curl >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar dependências do repositório.")" && exit 1; }
            sudo install -m 0755 -d /etc/apt/keyrings >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar diretório de chaves.")" && exit 1; }
            sudo curl -fsSL "$REPO_URL/gpg" -o /etc/apt/keyrings/docker.asc >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao baixar a chave GPG do Docker.")" && exit 1; }
            sudo chmod a+r /etc/apt/keyrings/docker.asc || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao definir permissões da chave GPG.")" && exit 1; }
            echo "$REPO_ENTRY" | sudo tee "$REPO_FILE" > /dev/null || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao configurar o repositório Docker.")" && exit 1; }
            apt_update >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao atualizar o apt após a configuração do repositório.")" && exit 1; }
        fi

        local packages="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
        apt_update >/dev/null 2>&1 && instalar_programa $packages >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar pacotes do Docker.")" && exit 1; }

    } & # Executar tudo em um único processo em segundo plano
    local pid=$!

    if show_progress "INSTALANDO DOCKER..." $pid; then
        print_log "$(log_success)" "$(echo_green "DOCKER INSTALADO COM SUCESSO!")"
        echo
    else
        print_log "$(log_error)" "$(echo_red "A instalação do Docker falhou em uma das etapas.")"
        return 1
    fi
}

cloudflare_tunnel() {

    install_docker

    print_log "$(log_aviso)" "$(echo_red "INSTALANDO CLOUDFLARE TUNNEL")"

    # Verifica se existe um contêiner do Cloudflare Tunnel
    if sudo docker ps -a --filter "ancestor=cloudflare/cloudflared:latest" --format "{{.ID}}" | grep -q .; then
        # Se existe, verifica se ele está rodando
        if sudo docker ps --filter "ancestor=cloudflare/cloudflared:latest" --format "{{.ID}}" | grep -q .; then
            print_log "$(log_success)" "$(echo_green "Cloudflare Tunnel já está instalado e rodando.")"
        else
            print_log "$(log_aviso)" "$(echo_orange "Cloudflare Tunnel instalado, mas não está rodando. Reiniciando...")"
            # Pega o ID do contêiner e o inicia
            sudo docker start $(sudo docker ps -a --filter "ancestor=cloudflare/cloudflared:latest" --format "{{.ID}}" | head -n 1) >/dev/null 2>&1
            print_log "$(log_info)" "$(echo_yellow "Cloudflare Tunnel instalado, mas não está rodando. Reiniciando...")"
        fi
    else
        # Se não encontrou nenhuma instância, instala uma nova
        exec 3>&1
        {
            sudo docker run -d \
                --name cloudflared-tunnel \
                --restart always \
                cloudflare/cloudflared:latest \
                tunnel --no-autoupdate run --token "$CLOUDFLARE_TOKEN" \
                >/dev/null 2>&1
        } 2>&1 &
        local pid=$!

        if show_progress "CONFIGURANDO CLOUDFLARE TUNNEL..." $pid; then
            print_log "$(log_success)" "$(echo_green "CLOUDFLARE TUNNEL INSTALADO COM SUCESSO!")"
        else
            print_log "$(log_error)" "$(echo_red "ERRO AO INSTALAR CLOUDFLARE TUNNEL")"
            return 1
        fi
    fi
}


install_cosmos() {
    print_log "$(log_aviso)" "$(echo_red "INSTALANDO COSMOS CLOUD...")"
    echo

    if [ -z "$SISTEMA_ARCH" ] || [ "$SISTEMA_ARCH" = "desconhecido" ]; then
        print_log "$(log_error)" "$(echo_red "ERRO: A arquitetura do sistema não foi detectada. Execute 'detectar_sistema' primeiro.")"
        return 1
    fi


    # Define as variáveis do debconf para iptables-persistent
    sudo debconf-set-selections <<EOF >/dev/null 2>&1
    iptables-persistent iptables-persistent/autosave_v4 boolean true
    iptables-persistent iptables-persistent/autosave_v6 boolean true
EOF

    instalar_programa "${server_install[@]}"


    # Executar todas as etapas de instalação em um único processo em segundo plano
    {
        # Instalar MergerFS
        local MERGERFS_VERSION="2.40.2"
        local DEB_NAME="mergerfs_${MERGERFS_VERSION}.${DISTRO_NAME}-${DISTRO_CODENAME}_${SISTEMA_ARCH}.deb"
        local DEB_URL="https://github.com/trapexit/mergerfs/releases/download/${MERGERFS_VERSION}/${DEB_NAME}"

        if ! [ -f "/tmp/$DEB_NAME" ]; then
            wget -q "$DEB_URL" -O "/tmp/$DEB_NAME"
        fi

        sudo dpkg -i "/tmp/$DEB_NAME" >/dev/null 2>&1 || sudo apt-get install -f -y >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar o MergerFS.")" && exit 1; }
        sudo rm "/tmp/$DEB_NAME"

        # Configurar firewall e serviços
        sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao configurar regra do firewall (porta 80).")" && exit 1; }
        sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao configurar regra do firewall (porta 443).")" && exit 1; }
        sudo iptables -A INPUT -p udp --dport 4242 -j ACCEPT || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao configurar regra do firewall (porta 4242).")" && exit 1; }
        sudo iptables-save > /etc/iptables/rules.v4 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao salvar regras do firewall.")" && exit 1; }
        systemctl enable --now avahi-daemon >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao iniciar/habilitar avahi-daemon.")" && exit 1; }

        # Download e verificação do binário do Cosmos
        local LATEST_RELEASE=$(curl -s https://api.github.com/repos/azukaar/Cosmos-Server/releases/latest | grep "tag_name" | cut -d '"' -f 4)
        local ZIP_FILE="cosmos-cloud-${LATEST_RELEASE#v}-${SISTEMA_ARCH}.zip"

        sudo mkdir -p /opt/cosmos || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar diretório /opt/cosmos.")" && exit 1; }
        curl -sSL "https://github.com/azukaar/Cosmos-Server/releases/download/${LATEST_RELEASE}/${ZIP_FILE}" -o "/tmp/${ZIP_FILE}" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao baixar binário do Cosmos.")" && exit 1; }
        curl -sSL "https://github.com/azukaar/Cosmos-Server/releases/download/${LATEST_RELEASE}/${ZIP_FILE}.md5" -o "/tmp/${ZIP_FILE}.md5" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao baixar o arquivo MD5.")" && exit 1; }

        cd /tmp
        if ! md5sum -c "${ZIP_FILE}.md5" >/dev/null 2>&1; then
            print_log "$(log_error)" "$(echo_red "ERRO: Verificação de MD5 falhou.")"
            exit 1
        fi

        sudo unzip -oq "${ZIP_FILE}" -d /opt/cosmos >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao extrair o binário do Cosmos.")" && exit 1; }

        LATEST_RELEASE_NO_V=${LATEST_RELEASE#v}

        # Se for arm64, renomeia a pasta
        if [ "$SISTEMA_ARCH" == "arm64" ]; then
        mv "/opt/cosmos/cosmos-cloud-${LATEST_RELEASE_NO_V}-arm64" "/opt/cosmos/cosmos-cloud-${LATEST_RELEASE_NO_V}"
        fi

        # Move todo o conteúdo para a raiz de /opt/cosmos
        mv "/opt/cosmos/cosmos-cloud-${LATEST_RELEASE_NO_V}/"* /opt/cosmos/
        rmdir "/opt/cosmos/cosmos-cloud-${LATEST_RELEASE_NO_V}"


        sudo chmod +x /opt/cosmos/cosmos || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao definir permissões do binário.")" && exit 1; }
        sudo rm -f "${ZIP_FILE}" "${ZIP_FILE}.md5"

        # Instalar e iniciar o serviço do Systemd
        if systemctl list-unit-files | grep -q "^CosmosCloud.service"; then
            print_status "Serviço CosmosCloud já existe. Pulando instalação..."
        else
            sudo /opt/cosmos/cosmos service install >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar o serviço Systemd do Cosmos.")" && exit 1; }
        fi

        sudo systemctl daemon-reload >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao recarregar o Systemd.")" && exit 1; }
        sudo systemctl enable --now CosmosCloud >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao iniciar o serviço CosmosCloud.")" && exit 1; }


    } & # Executar tudo em um único processo em segundo plano

    local pid=$!

    if show_progress "INSTALANDO COSMOS..." $pid; then
        print_log "$(log_success)" "$(echo_green "COSMOS CLOUD INSTALADO COM SUCESSO!")"
    else
        print_log "$(log_error)" "$(echo_red "A instalação do Cosmos falhou em uma das etapas.")"
        return 1
    fi
}

servidor_config() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO A CONFIGURAÇÃO DO SERVIDOR COSMOS...")"
    echo

    local instalacao_completa=true

    # A. Verificação e Instalação do Docker
    if ! command -v docker &> /dev/null; then
        cloudflare_tunnel
        instalacao_completa=false
    else
        print_log "$(log_success)" "$(echo_green "Docker já está instalado.")"
        echo
    fi

    # B. Verificação e Instalação do Cosmos
    if [ ! -f "/opt/cosmos/cosmos" ]; then
        install_cosmos
        instalacao_completa=false
    else
        print_log "$(log_success)" "$(echo_green "Cosmos Cloud já está instalado.")"
    fi

    # C. Etapa de Configuração: Só prossegue se ambos os serviços estiverem instalados.
    if [ "$instalacao_completa" = false ]; then
        echo "====================================================="
        echo_red "         INFORMAÇÃO IMPORTANTE"
        echo "A instalação do Docker e do Cosmos foram concluídas."
        echo "Para continuar a configuração, por favor, instale o Home Assistant ou outros"
        echo "contêineres manualmente e, em seguida, execute este script novamente."
        echo "====================================================="
        return 0
    fi

    print_log "$(log_success)" "$(echo_green "Serviços principais (Docker e Cosmos) já estão instalados. Prosseguindo para a configuração...")"

    # Verificar se o contêiner do Home Assistant existe para a configuração
    if ! docker ps -a --format "{{.Names}}" | grep -q "Home-Assistant"; then
        echo "====================================================="
        print_log "$(log_error)" "$(echo_red "INFORMAÇÃO IMPORTANTE:")"
        print_log "$(log_error)" "$(echo_red "Não foi possível detectar o contêiner 'Home-Assistant'.")"
        echo "Por favor, instale-o manualmente para que a configuração possa ser concluída."
        echo "====================================================="
        return 0
    fi

    print_log "$(log_success)" "$(echo_green "Contêiner 'Home-Assistant' detectado. Prosseguindo com a configuração...")"

    configurar_home_assistant

    install_monitor

    print_log "$(log_success)" "$(echo_green "Configuração concluída com sucesso!")"
}

