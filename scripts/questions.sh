ask_questions() {
    local var_name="$1"
    local mensagem="$2"
    local tentativas=3
    local resposta=""

    local valor_atual
    valor_atual=$(eval "echo \$$var_name")
    if [[ -n "$valor_atual" && "$valor_atual" =~ ^[YyNn]$ ]]; then
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA '$var_name' JÁ DEFINIDA: '$valor_atual'. PULANDO PERGUNTA.")"
        echo
        return
    fi

    for ((i=tentativas; i>0; i--)); do
        echo_orange "$mensagem (Y/N) [Padrão: N]: "
        read -r resposta
        resposta=$(echo "$resposta" | tr '[:lower:]' '[:upper:]')

        if [[ -z "$resposta" ]]; then
            resposta="N"
        fi

        if [[ "$resposta" =~ ^[YN]$ ]]; then
            eval "$var_name='$resposta'"
            echo
            return
        else
            echo_red "Resposta inválida. Por favor, digite Y ou N."
            echo_red "Tentativas restantes: $((i-1))"
            echo
        fi
    done

    echo_red "Número máximo de tentativas excedido. Considerando resposta N."
    eval "$var_name='N'"
    echo
}


coletar_respostas() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO A COLETA DE RESPOSTAS. Variáveis já definidas serão puladas.")"
    echo

    # P:1.0 CONECTAR AO WI-FI
    ask_questions conectar_wifi "DESEJA SE CONECTAR AO WI-FI?"

    # P:2.0 COMPARTILHAR INTERNET POR ETH0
    ask_questions compartilhar_internet_lan "DESEJA COMPARTILHAR INTERNET POR ETH0?"

    if [[ "$compartilhar_internet_lan" =~ ^[Yy]$ ]]; then
        # P:2.1 COMPARTILHAR INTERNET POR ETH0 E INSTALAR PI-HOLE
        ask_questions instalar_pi_hole "DESEJA INSTALAR PI-HOLE?"
    fi

    # P:3.0 ATUALIZAR SISTEMA
    ask_questions update_system "ESSE SCRIPT NECESSITA DE UM SISTEMA ATUALIZADO. Deseja atualizar programas e sistema?"

    # P:4.0 INSTALAR PROGRAMAS ESSENCIAIS E ZSH
    ask_questions install_basic_zsh "DESEJA INSTALAR PROGRAMAS ESSENCIAIS E ZSH?"

    # P:4.1 pergunta o SISTEMA caso não identifique (depende de install_basic_zsh)
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

    # P:5.0 INSTALAR TEMAS, ICONES E WALLPAPERS
    ask_questions install_theme "DESEJA INSTALAR TEMAS, ICONES E WALLPAPERS?"

    # P:6.0 LISTA DE PROGRAMAS
    if [[ -z "$programas" ]]; then # Assume que é uma string, então apenas verifica se está vazia
        echo_orange "SELECIONE QUAIS PROGRAMAS DESEJA INSTALAR (Heimdall, SCRCPY, PI-APPS)"
        read -p "Digite os programas separados por espaço (por exemplo, Heimdall SCRCPY PI-APPS): " programas
        echo
        # Não normaliza ou define padrão para string de múltiplos valores, pois o usuário pode deixar vazio intencionalmente.
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'programas' JÁ DEFINIDA: '$programas'. PULANDO PERGUNTA.")"
        echo
    fi

    # P:6.1 LISTA DE PROGRAMAS PARA PI-APPS
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

    # P:7.0 ATIVAR SSH
    ask_questions ativar_ssh "DESEJA ATIVAR SSH?"

    # P:8.0 ATIVAR VNC
    ask_questions ativar_vnc "DESEJA ATIVAR VNC SERVER?"

    # P:9.0 HABILITAR DISPLAY TFT
    ask_questions habilitar_tft "DESEJA HABILITAR DISPLAY TFT?"

    # P:10.0 CONFIGURAR RCLONE (GOOGLE DRIVE)
    ask_questions drive "DESEJA CONFIGURAR O RCLONE (GOOGLE DRIVE)?"

    # P:11.0 INSTALAR TRIGGERCMD (COMANDOS PARA ALEXA)
    ask_questions alexa_commands "DESEJA INSTALAR TRIGGERCMD (COMANDOS PARA ALEXA)?"

    # P:12.0 INSTALAR COSMOS SERVER
    ask_questions cosmos "DESEJA INSTALAR COSMOS SERVER?"

    # P:13.0 INSTALAR SERVIDOR DE MINECRAFT JAVA
    ask_questions mine_server "DESEJA INSTALAR SERVIDOR DE MINECRAFT JAVA?"

    # P:14.0 REINICIAR APÓS TERMINAR
    ask_questions reiniciar "DESEJA REINICIAR APÓS TERMINAR?"
}

