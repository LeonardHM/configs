coletar_respostas() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO A COLETA DE RESPOSTAS. Variáveis já definidas serão puladas.")"
    echo

    # P:1.0 - conectar_wifi
    # Verifica se a variável já está definida e não é vazia, ou se não é Y/N válido.
    if [[ -z "$conectar_wifi" || ! "$conectar_wifi" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA SE CONECTAR AO WI-FI? (Y/N)"
        read -p "Digite Y para sim ou N para não: " conectar_wifi
        echo
        conectar_wifi=$(echo "$conectar_wifi" | tr '[:lower:]' '[:upper:]') # Normaliza para maiúscula
        conectar_wifi=${conectar_wifi:-N} # Define N como padrão se a entrada for vazia
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'conectar_wifi' JÁ DEFINIDA: '$conectar_wifi'. PULANDO PERGUNTA.")"
        echo
    fi

    # P:2.0 - compartilhar_internet_lan
    if [[ -z "$compartilhar_internet_lan" || ! "$compartilhar_internet_lan" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA COMPARTILHAR INTERNET POR ETH0? (Y/N)"
        read -p "Digite Y para sim ou N para não: " compartilhar_internet_lan
        echo
        compartilhar_internet_lan=$(echo "$compartilhar_internet_lan" | tr '[:lower:]' '[:upper:]')
        compartilhar_internet_lan=${compartilhar_internet_lan:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'compartilhar_internet_lan' JÁ DEFINIDA: '$compartilhar_internet_lan'. PULANDO PERGUNTA.")"
        echo
    fi

    if [[ "$compartilhar_internet_lan" =~ ^[Yy]$ ]]; then
        # P:2.1 - instalar_pi_hole (depende de compartilhar_internet_lan)
        if [[ -z "$instalar_pi_hole" || ! "$instalar_pi_hole" =~ ^[YyNn]$ ]]; then
            echo_orange "DESEJA INSTALAR PI-HOLE? (Y/N)"
            read -p "Digite Y para sim ou N para não: " instalar_pi_hole
            echo
            instalar_pi_hole=$(echo "$instalar_pi_hole" | tr '[:lower:]' '[:upper:]')
            instalar_pi_hole=${instalar_pi_hole:-N}
        else
            print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'instalar_pi_hole' JÁ DEFINIDA: '$instalar_pi_hole'. PULANDO PERGUNTA.")"
            echo
        fi
    fi

    # P: Atualizar Sistema
    if [[ -z "$update_system" || ! "$update_system" =~ ^[YyNn]$ ]]; then
        echo_red "ESSE SCRIPT NECESSITA DE UM SISTEMA ATUALIZADO."
        read -p "Digite Y para atualizar programas e sistema ou N para continuar: " update_system
        echo
        update_system=$(echo "$update_system" | tr '[:lower:]' '[:upper:]')
        update_system=${update_system:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'update_system' JÁ DEFINIDA: '$update_system'. PULANDO PERGUNTA.")"
        echo
    fi

    # P:3.0 - install_basic_zsh
    if [[ -z "$install_basic_zsh" || ! "$install_basic_zsh" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA INSTALAR PROGRAMAS BASICOS E ZSH?"
        read -p "Digite Y para sim ou N para não: " install_basic_zsh
        echo
        install_basic_zsh=$(echo "$install_basic_zsh" | tr '[:lower:]' '[:upper:]')
        install_basic_zsh=${install_basic_zsh:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'install_basic_zsh' JÁ DEFINIDA: '$install_basic_zsh'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:3.1 - SISTEMA (depende de install_basic_zsh)
    if [[ "$install_basic_zsh" =~ ^[Yy]$ ]]; then
        # Checa se a variável 'SISTEMA_TIPO' (da detecção) já está definida e é um dos valores válidos
        if [[ -z "$SISTEMA_TIPO" || ! "$SISTEMA_TIPO" =~ ^(PC|RASPBERRY|TERMUX)$ ]]; then
            while true; do
                echo_orange "ESTA EXECUTANDO QUAL SISTEMA? (PC, RASP, TERMUX)"
                read -p "Digite o SISTEMA (PC, RASP ou TERMUX): " sistema

                sistema=$(echo "$sistema" | tr '[:lower:]' '[:upper:]')
                case "$sistema" in
                    PC)
                        echo_green "Sistema identificado como: PC"
                        echo
                        break
                        ;;
                    RASP|RPI|RASPBERRY)
                        echo_green "Sistema identificado como: RASPBERRY"
                        echo
                        break
                        ;;
                    TERMUX)
                        echo_green "Sistema identificado como: TERMUX"
                        echo
                        break
                        ;;
                    CANCELAR)
                        echo_red "Função cancelada pelo usuário."
                        echo
                        return 1
                        ;;
                    *)
                        echo_red "Sistema não identificado. Por favor, digite uma das opções válidas: PC, RASP ou TERMUX ou digite 'CANCELAR' para sair."
                        echo
                        ;;
                esac
            done
        else
            # Mensagem de log para quando a variável 'sistema' já está definida e é válida
            print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'sistema_tipo' JÁ DEFINIDA: '$SISTEMA_TIPO'. PULANDO PERGUNTA.")"

            echo
        fi
    fi

    # --- P:4.0 - install_theme
    if [[ -z "$install_theme" || ! "$install_theme" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA INSTALAR TEMAS?"
        read -p "Digite Y para sim ou N para não: " install_theme
        echo
        install_theme=$(echo "$install_theme" | tr '[:lower:]' '[:upper:]')
        install_theme=${install_theme:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'install_theme' JÁ DEFINIDA: '$install_theme'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:5.0 (Vazio no seu script) ---

    # P:6.0 - programas (lista de programas)
    if [[ -z "$programas" ]]; then # Assume que é uma string, então apenas verifica se está vazia
        echo_orange "SELECIONE QUAIS PROGRAMAS DESEJA INSTALAR (Heimdall, SCRCPY, PI-APPS)"
        read -p "Digite os programas separados por espaço (por exemplo, Heimdall SCRCPY PI-APPS): " programas
        echo
        # Não normaliza ou define padrão para string de múltiplos valores, pois o usuário pode deixar vazio intencionalmente.
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'programas' JÁ DEFINIDA: '$programas'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:6.1 - instalar_pi_apps (depende de programas conter PI-APPS) ---
    if [[ "$programas" =~ .*[Pp][Ii]-[Aa][Pp][Pp][Ss].* ]]; then
        if [[ -z "$instalar_pi_apps" || ! "$instalar_pi_apps" =~ ^[YyNn]$ ]]; then
            echo_orange "DESEJA INSTALAR PROGRAMAS DO PI-APPS? (Y/N)"
            read -p "Digite Y para sim ou N para não: " instalar_pi_apps
            instalar_pi_apps=$(echo "$instalar_pi_apps" | tr '[:lower:]' '[:upper:]')
            instalar_pi_apps=${instalar_pi_apps:-N}
        else
            print_log "$(log_info)" "$(echo_yellow 'RESPOSTA PARA 'instalar_pi_apps' JÁ DEFINIDA. PULANDO PERGUNTA.')"
        fi

        # --- P:6.2 - pi_apps_programas (depende de instalar_pi_apps) ---
        if [[ "$instalar_pi_apps" =~ ^[Yy]$ ]]; then
            if [[ -z "$pi_apps_programas" ]]; then # Assume que é uma string de múltiplos valores
                echo_orange "QUAIS PROGRAMAS DESEJA INSTALAR? (Minecraft Vivaldi)"
                read -p "Digite os programas separados por espaço (por exemplo, Minecraft Vivaldi): " pi_apps_programas
            else
                print_log "$(log_info)" "$(echo_yellow 'RESPOSTA PARA 'pi_apps_programas' JÁ DEFINIDA. PULANDO PERGUNTA.')"
            fi
        fi
    fi

    # --- P:7.0 - ativar_ssh ---
    if [[ -z "$ativar_ssh" || ! "$ativar_ssh" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA ATIVAR SSH? (Y/N)"
        read -p "Digite Y para sim ou N para não: " ativar_ssh
        echo
        ativar_ssh=$(echo "$ativar_ssh" | tr '[:lower:]' '[:upper:]')
        ativar_ssh=${ativar_ssh:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'ativar_ssh' JÁ DEFINIDA: '$ativar_ssh'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:8.0 - ativar_vnc ---
    if [[ -z "$ativar_vnc" || ! "$ativar_vnc" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA ATIVAR VNC SERVER? (Y/N)"
        read -p "Digite Y para sim ou N para não: " ativar_vnc
        echo
        ativar_vnc=$(echo "$ativar_vnc" | tr '[:lower:]' '[:upper:]')
        ativar_vnc=${ativar_vnc:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'ativar_vnc' JÁ DEFINIDA: '$ativar_vnc'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:9.0 - habilitar_tft ---
    if [[ -z "$habilitar_tft" || ! "$habilitar_tft" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA HABILITAR DISPLAY TFT? (Y/N)"
        read -p "Digite Y para sim ou N para não: " habilitar_tft
        echo
        habilitar_tft=$(echo "$habilitar_tft" | tr '[:lower:]' '[:upper:]')
        habilitar_tft=${habilitar_tft:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'habilitar_tft' JÁ DEFINIDA: '$habilitar_tft'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:10.0 - drive (Rclone) ---
    if [[ -z "$drive" || ! "$drive" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA CONFIGURAR O GOOGLE DRIVE COM RCLONE? (Y/N)"
        read -p "Digite Y para sim ou N para não: " drive
        echo
        drive=$(echo "$drive" | tr '[:lower:]' '[:upper:]')
        drive=${drive:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'drive' JÁ DEFINIDA: '$drive'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:11.0 - alexa_commands ---
    if [[ -z "$alexa_commands" || ! "$alexa_commands" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA INSTALAR TRIGGERCMD(COMANDOS PARA ALEXA)? (Y/N)"
        read -p "Digite Y para sim ou N para não: " alexa_commands
        echo
        alexa_commands=$(echo "$alexa_commands" | tr '[:lower:]' '[:upper:]')
        alexa_commands=${alexa_commands:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'alexa_commands' JÁ DEFINIDA: '$alexa_commands'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:12.0 - docker ---
    if [[ -z "$docker" || ! "$docker" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA INSTALAR DOCKER? (Y/N)"
        read -p "Digite Y para sim ou N para não: " docker
        echo
        docker=$(echo "$docker" | tr '[:lower:]' '[:upper:]')
        docker=${docker:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'docker' JÁ DEFINIDA: '$docker'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:13.0 - cloudflare ---
    if [[ -z "$cloudflare" || ! "$cloudflare" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA INSTALAR CLOUDFLARE? (Y/N)"
        read -p "Digite Y para sim ou N para não: " cloudflare
        echo
        cloudflare=$(echo "$cloudflare" | tr '[:lower:]' '[:upper:]')
        cloudflare=${cloudflare:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'cloudflare' JÁ DEFINIDA: '$cloudflare'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:14.0 - cosmos ---
    if [[ -z "$cosmos" || ! "$cosmos" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA INSTALAR COSMOS SERVER? (Y/N)"
        read -p "Digite Y para sim ou N para não: " cosmos
        echo
        cosmos=$(echo "$cosmos" | tr '[:lower:]' '[:upper:]')
        cosmos=${cosmos:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'cosmos' JÁ DEFINIDA: '$cosmos'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:15.0 - mine_server ---
    if [[ -z "$mine_server" || ! "$mine_server" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA INSTALAR SERVIDOR DE MINECRAFT JAVA? (Y/N)"
        read -p "Digite Y para sim ou N para não: " mine_server
        echo
        mine_server=$(echo "$mine_server" | tr '[:lower:]' '[:upper:]')
        mine_server=${mine_server:-N}
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'mine_server' JÁ DEFINIDA: '$mine_server'. PULANDO PERGUNTA.")"
        echo
    fi

    # --- P:16.0 (Vazio no seu script) ---

    # --- P:17.0 - reiniciar ---
    if [[ -z "$reiniciar" || ! "$reiniciar" =~ ^[YyNn]$ ]]; then
        echo_orange "DESEJA REINICIAR APOS TERMINAR?"
        read -p "Digite Y para reiniciar ou pressione Enter para sair: " reiniciar
        echo
        reiniciar=$(echo "$reiniciar" | tr '[:lower:]' '[:upper:]')
        reiniciar=${reiniciar:-N} # Padrão para N se Enter for pressionado
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'reiniciar' JÁ DEFINIDA: '$reiniciar'. PULANDO PERGUNTA.")"
        echo
    fi
}
