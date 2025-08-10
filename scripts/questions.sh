perguntar_confirmacao() {
    local var_name="$1"
    local mensagem="$2"

    local valor_atual
    valor_atual=$(eval "echo \$$var_name")

    if [[ -n "$valor_atual" && "$valor_atual" =~ ^[YyNn]$ ]]; then
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA '$var_name' JÁ DEFINIDA: '$valor_atual'. PULANDO PERGUNTA.")"
        echo
        return
    fi

    echo_orange "$mensagem (Y/N): "
    read resposta
    resposta=$(echo "$resposta" | tr '[:lower:]' '[:upper:]')
    eval "$var_name=${resposta:-N}"
    echo
}


coletar_respostas() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO A COLETA DE RESPOSTAS. Variáveis já definidas serão puladas.")"
    echo

    # P:1.0
    perguntar_confirmacao conectar_wifi "DESEJA SE CONECTAR AO WI-FI?"

    # P:2.0
    perguntar_confirmacao compartilhar_internet_lan "DESEJA COMPARTILHAR INTERNET POR ETH0?"

    if [[ "$compartilhar_internet_lan" =~ ^[Yy]$ ]]; then
        # P:2.1
        perguntar_confirmacao instalar_pi_hole "DESEJA INSTALAR PI-HOLE?"
    fi

    # Atualizar Sistema
    perguntar_confirmacao update_system "ESSE SCRIPT NECESSITA DE UM SISTEMA ATUALIZADO. Deseja atualizar programas e sistema?"

    # P:3.0
    perguntar_confirmacao install_basic_zsh "DESEJA INSTALAR PROGRAMAS ESSENCIAIS E ZSH?"

    if [[ "$install_basic_zsh" =~ ^[Yy]$ ]]; then
        # Detecta sistema
        if [[ -z "$SISTEMA_TIPO" || ! "$SISTEMA_TIPO" =~ ^(PC|RASPBERRY|TERMUX)$ ]]; then
            while true; do
                echo_orange "ESTA EXECUTANDO QUAL SISTEMA? (PC, RASP, TERMUX)"
                read -p "Digite o SISTEMA (PC, RASP ou TERMUX): " sistema
                sistema=$(echo "$sistema" | tr '[:lower:]' '[:upper:]')
                case "$sistema" in
                    PC)
                        echo_green "Sistema identificado como: PC"
                        SISTEMA_TIPO="PC"
                        break
                        ;;
                    RASP|RPI|RASPBERRY)
                        echo_green "Sistema identificado como: RASPBERRY"
                        SISTEMA_TIPO="RASPBERRY"
                        break
                        ;;
                    TERMUX)
                        echo_green "Sistema identificado como: TERMUX"
                        SISTEMA_TIPO="TERMUX"
                        break
                        ;;
                    CANCELAR)
                        echo_red "Função cancelada pelo usuário."
                        return 1
                        ;;
                    *)
                        echo_red "Opção inválida. Digite PC, RASP, TERMUX ou CANCELAR."
                        ;;
                esac
            done
        else
            print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'SISTEMA_TIPO' JÁ DEFINIDA: '$SISTEMA_TIPO'. PULANDO PERGUNTA.")"
            echo
        fi
    fi

    # P:4.0
    perguntar_confirmacao install_theme "DESEJA INSTALAR TEMAS?"

    # P:6.0 - lista de programas
    if [[ -z "$programas" ]]; then
        echo_orange "SELECIONE QUAIS PROGRAMAS DESEJA INSTALAR (Heimdall, SCRCPY, PI-APPS)"
        read -p "Digite os programas separados por espaço: " programas
        echo
    else
        print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'programas' JÁ DEFINIDA: '$programas'. PULANDO PERGUNTA.")"
        echo
    fi

    # P:6.1
    if [[ "$programas" =~ .*[Pp][Ii]-[Aa][Pp][Pp][Ss].* ]]; then
        perguntar_confirmacao instalar_pi_apps "DESEJA INSTALAR PROGRAMAS DO PI-APPS?"

        if [[ "$instalar_pi_apps" =~ ^[Yy]$ ]]; then
            if [[ -z "$pi_apps_programas" ]]; then
                echo_orange "QUAIS PROGRAMAS DESEJA INSTALAR? (Minecraft, Vivaldi)"
                read -p "Digite os programas separados por espaço: " pi_apps_programas
                echo
            else
                print_log "$(log_info)" "$(echo_yellow "RESPOSTA PARA 'pi_apps_programas' JÁ DEFINIDA: '$pi_apps_programas'. PULANDO PERGUNTA.")"
            fi
        fi
    fi

    # P:7.0
    perguntar_confirmacao ativar_ssh "DESEJA ATIVAR SSH?"

    # P:8.0
    perguntar_confirmacao ativar_vnc "DESEJA ATIVAR VNC SERVER?"

    # P:9.0
    perguntar_confirmacao habilitar_tft "DESEJA HABILITAR DISPLAY TFT?"

    # P:10.0
    perguntar_confirmacao drive "DESEJA CONFIGURAR O GOOGLE DRIVE COM RCLONE?"

    # P:11.0
    perguntar_confirmacao alexa_commands "DESEJA INSTALAR TRIGGERCMD (COMANDOS PARA ALEXA)?"

    # P:14.0
    perguntar_confirmacao cosmos "DESEJA INSTALAR COSMOS SERVER?"

    # P:15.0
    perguntar_confirmacao mine_server "DESEJA INSTALAR SERVIDOR DE MINECRAFT JAVA?"

    # P:17.0
    perguntar_confirmacao reiniciar "DESEJA REINICIAR APÓS TERMINAR?"
}

