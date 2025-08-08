server_mine() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO INSTALAÇÃO DO SERVIDOR DE MINECRAFT")"

    # Instala Temurin (Java)
    print_log "$(log_info)" "$(echo_orange "Instalando Temurin (Java Development Kit) 21...")"
    instalar_programa wget apt-transport-https gpg >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar dependências.")"; return 1; }
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null
    echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
    sudo apt update >/dev/null 2>&1
    instalar_programa temurin-21-jdk >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar Temurin-21-jdk.")"; return 1; }
    print_log "$(log_success)" "$(echo_green "Temurin (Java) 21 instalado com sucesso.")"

    # Criar os diretórios principais
    print_log "$(log_info)" "$(echo_orange "Criando diretórios para o servidor de Minecraft...")"
    mkdir -p "$PLUGIN_MINE_DIR" "$DATAPACK_MINE_DIR" >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao criar diretórios.")"; return 1; }
    print_log "$(log_success)" "$(echo_green "Diretórios criados com sucesso.")"

    # Adicionar o arquivo eula.txt
    print_log "$(log_info)" "$(echo_orange "Configurando o EULA...")"
    if [ ! -f "$MINE_DIR/eula.txt" ]; then
        echo "eula=true" > "$MINE_DIR/eula.txt"
        print_log "$(log_success)" "$(echo_green "Arquivo eula.txt criado com sucesso.")"
    else
        print_log "$(log_aviso)" "$(echo_yellow "Arquivo eula.txt já existe. Pulando...")"
    fi

    # Ajustar permissões do diretório do servidor
    print_log "$(log_info)" "$(echo_orange "Ajustando permissões do servidor...")"
    chmod -R 755 "$MINE_DIR" >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao ajustar permissões.")"; return 1; }
    chown -R $(whoami):$(whoami) "$MINE_DIR" >/dev/null 2>&1 || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao ajustar o proprietário dos arquivos.")"; return 1; }
    print_log "$(log_success)" "$(echo_green "Permissões ajustadas com sucesso.")"

    # Baixar plugins
    print_log "$(log_info)" "$(echo_orange "Baixando plugins...")"
    cd "$PLUGIN_MINE_DIR" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao entrar no diretório de plugins.")"; return 1; }
    
    # Plugins Principais
    wget -qO Geyser-Spigot.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot &
    wget -qO Floodgate-Spigot.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot &
    wget -qO ViaVersion-5.1.1.jar https://github.com/ViaVersion/ViaVersion/releases/download/5.1.1/ViaVersion-5.1.1.jar &
    wget -qO Chunky-1.4.28.jar https://cdn.modrinth.com/data/fALzjamp/versions/ytBhnGfO/Chunky-Bukkit-1.4.28.jar &
    wget -qO BlueMap-5.5.jar https://cdn.modrinth.com/data/swbUV1cr/versions/Ap3wfaNh/bluemap-5.5-spigot.jar &
    wget -qO MiniMotd-2.1.2.jar https://cdn.modrinth.com/data/16vhQOQN/versions/f3kxL9Ht/minimotd-bukkit-2.1.2.jar &
    wget -qO ImageFrame-1.7.9.0.jar https://cdn.modrinth.com/data/lJFOpcEj/versions/ncDUW32A/ImageFrame-1.7.9.0.jar &
    wget -qO Waypoints-4.5.5.jar https://cdn.modrinth.com/data/1c2olKOU/versions/K4tng5ly/waypoints-4.5.5.jar &
    wget -qO HoloMobHealth-2.3.8.0.jar https://cdn.modrinth.com/data/UitDglMl/versions/RQUC5uZJ/HoloMobHealth-2.3.8.0.jar &
    wget -qO ToolStats-1.8.3.jar https://cdn.modrinth.com/data/oBZj9E15/versions/8I7Hfeku/toolstats-1.8.3.jar &
    wget -qO DropHead.jar https://cdn.modrinth.com/data/glYcmYBi/versions/fxhACC9m/Drop%20Head%202.0.0%20%281.14-1.21.1%29.jar &
    wget -qO CraftableInvFrames-2.2.9.jar https://cdn.modrinth.com/data/wtE6hwEA/versions/EyhfEnOO/craftableinvframes-2.2.9.jar &
    wget -qO VanillaMiniMaps-1.0.1.jar https://cdn.modrinth.com/data/J8xFITpi/versions/hfUSq7Jz/vanillaminimaps-1.0.1.jar &
    wget -qO SeeMore-1.0.2.jar https://cdn.modrinth.com/data/IEt1Yy3F/versions/QXCh3qCi/SeeMore-1.0.2.jar &
    wget -qO Sleeper.jar https://cdn.modrinth.com/data/Kt3eUOUy/versions/93CEj3T6/Sleeper.jar &
    wget -qO FancyHolograms-2.4.0.jar https://cdn.modrinth.com/data/5QNgOj66/versions/9hQyZvao/FancyHolograms-2.4.0.jar &
    wget -qO ProtocolLib.jar https://github.com/dmulloy2/ProtocolLib/releases/download/5.3.0/ProtocolLib.jar &
    
    # PlayerDoll
    wget -qO PlayerDoll-Main-2.0.jar https://cdn.modrinth.com/data/n3s2JUTc/versions/s7Hrlk5i/PlayerDoll-Main-2.0.jar &
    
    wait
    print_log "$(log_success)" "$(echo_green "Plugins baixados com sucesso.")"

    print_log "$(log_info)" "$(echo_orange "Configurando PlayerDoll...")"
    mkdir -p PlayerDoll/addon >/dev/null 2>&1
    cd PlayerDoll/addon || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao entrar no diretório do PlayerDoll.")"; return 1; }
    wget -q https://cdn.modrinth.com/data/n3s2JUTc/versions/s7Hrlk5i/Addon-Doll-v1_21_R1-Mojang-Mapping.jar &
    wget -q https://cdn.modrinth.com/data/n3s2JUTc/versions/s7Hrlk5i/Addon-Wrapper-1202_1211-Mojang-Mapping.jar &
    
    wait
    print_log "$(log_success)" "$(echo_green "Addons do PlayerDoll baixados.")"

    # Baixar datapacks
    print_log "$(log_info)" "$(echo_orange "Baixando datapacks...")"
    cd "$DATAPACK_MINE_DIR" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao entrar no diretório de datapacks.")"; return 1; }

    wget -qO Terralith.zip https://cdn.modrinth.com/data/8oi3bsk5/versions/tnavs2WP/Terralith_1.21_v2.5.6.zip &
    wget -qO Dungeons-and-Taverns.zip https://cdn.modrinth.com/data/tpehi7ww/versions/8o3mS993/Dungeons%20and%20Taverns%20v4.5.zip &
    wget -qO Nullscape.zip https://cdn.modrinth.com/data/LPjGiSO4/versions/SFDfNp0O/Nullscape_1.21_v1.2.9.zip &
    wget -qO Incendium.zip https://cdn.modrinth.com/data/ZVzW5oNS/versions/aBrsXiTU/Incendium_1.21_UNSUPPORTED_PORT_v5.4.3.zip &
    wget -qO Dynamic-Lights.zip https://cdn.modrinth.com/data/7YjclEGc/versions/tjRhVcS8/dynamiclights-v1.8.4-mc1.17x-1.21x-datapack.zip &
    wget -qO Create-Structures.zip https://cdn.modrinth.com/data/IAnP4np7/versions/GHYR6eCT/Create%20Structures%20-%20v0.1.1%20-%201.20.1.zip &
    wget -qO Saturated.zip https://cdn.modrinth.com/data/eBiNxmRM/versions/ZKEBvwmG/saturated-open-beta-v22.zip &
    wget -qO DropHead-2.0_1.14-1.21.3.zip https://cdn.modrinth.com/data/glYcmYBi/versions/6a8KWZ7I/Drop%20Head%202.0%20%281.14-1.21.3%29.zip &
    wget -qO StackableHeads-1.2.1_1.21-1.21.3.zip https://cdn.modrinth.com/data/o2nO79dr/versions/Y98h7NWs/Stackable%20Heads%201.2.1%20%281.21-1.21.3%29.zip &

    wait
    print_log "$(log_success)" "$(echo_green "Datapacks baixados com sucesso.")"

    cd "$MINE_DIR" || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao entrar no diretório principal do Minecraft.")"; return 1; }

    # Baixar ícone do servidor
    wget -qO server-icon.png https://i.ibb.co/3WrSfhf/title.png &

    # Baixar a versão mais recente do Purpur
    print_log "$(log_info)" "$(echo_orange "Baixando a versão mais recente do Purpur...")"
    BASE_URL="https://api.purpurmc.org/v2/purpur"

    # Obter as versões disponíveis
    VERSIONS=$(curl -s "$BASE_URL" | sed -n 's/.*"versions":\[\([^]]*\)\].*/\1/p' | tr ',' '\n' | tr -d '"')

    # Verificar se as versões foram obtidas
    if [ -z "$VERSIONS" ]; then
        print_log "$(log_error)" "$(echo_red "Erro: Não foi possível obter a lista de versões disponíveis do Purpur.")"
        return 1
    fi

    # Exibir as versões disponíveis
    echo "Versões disponíveis:"
    echo "$VERSIONS" | nl -w2 -s'. '

    # Solicitar ao usuário para selecionar uma versão
    echo
    read -p "Digite o número da versão desejada (ou pressione Enter para a mais recente): " USER_CHOICE

    # Determinar a versão escolhida ou usar a mais recente
    if [ -z "$USER_CHOICE" ]; then
        SELECTED_VERSION=$(echo "$VERSIONS" | tail -n 1)
    else
        SELECTED_VERSION=$(echo "$VERSIONS" | sed -n "${USER_CHOICE}p")
    fi

    # Verificar se a versão escolhida é válida
    if [ -z "$SELECTED_VERSION" ]; then
        print_log "$(log_error)" "$(echo_red "Erro: Escolha inválida.")"
        return 1
    fi

    print_log "$(log_info)" "$(echo_yellow "Versão escolhida: $SELECTED_VERSION")"

    LATEST_FILE="$MINE_DIR/purpur-$SELECTED_VERSION-latest.jar"

    # Remover arquivos antigos
    print_log "$(log_info)" "$(echo_orange "Removendo arquivos de versão antigos...")"
    find "$MINE_DIR" -type f -name 'purpur-*.jar' ! -name "purpur-$SELECTED_VERSION-latest.jar" -exec rm -f {} \;
    print_log "$(log_success)" "$(echo_green "Arquivos antigos removidos.")"

    # Baixar somente se ainda não estiver no diretório
    if [ -f "$LATEST_FILE" ]; then
        print_log "$(log_aviso)" "$(echo_yellow "A versão escolhida ($SELECTED_VERSION) já está instalada. Pulando o download.")"
    else
        print_log "$(log_info)" "$(echo_orange "Baixando Purpur versão $SELECTED_VERSION...")"
        curl -o "$LATEST_FILE" "$BASE_URL/$SELECTED_VERSION/latest/download" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_log "$(log_success)" "$(echo_green "Download concluído: $LATEST_FILE")"
        else
            print_log "$(log_error)" "$(echo_red "Erro: Falha no download do Purpur.")"
            return 1
        fi
    fi

    # Atualizar link simbólico para a última versão
    print_log "$(log_info)" "$(echo_orange "Atualizando link simbólico...")"
    ln -sf "$LATEST_FILE" "$MINE_DIR/purpur-latest.jar"
    print_log "$(log_success)" "$(echo_green "Link simbólico atualizado: purpur-latest.jar -> $LATEST_FILE")"

    # Preparar e iniciar o servidor
    print_log "$(log_info)" "$(echo_orange "Iniciando o servidor Minecraft com PurPur $SELECTED_VERSION...")"
    java -Xmx7G -Xms1G -jar "$MINE_DIR/purpur-latest.jar" nogui
    print_log "$(log_success)" "$(echo_green "Servidor iniciado. Para parar, pressione Ctrl+C no terminal.")"

    print_log "$(log_success)" "$(echo_green "INSTALAÇÃO E CONFIGURAÇÃO DO SERVIDOR DE MINECRAFT CONCLUÍDAS.")"
}

