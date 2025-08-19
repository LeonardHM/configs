echo_colors_exemples() {
print_log "$(log_info)" "$(echo_yellow "...")"
print_log "$(log_info)" "$(echo_orange "...")"
print_log "$(log_info)" "$(echo_red "...")"

print_log "$(log_aviso)" "$(echo_orange "...")"
print_log "$(log_aviso)" "$(echo_red "...")"

print_log "$(log_error)" "$(echo_red "...")"

print_log "$(log_success)" "$(echo_green "...")"


Tipo de Log	    Cor de Saída 	Finalidade e Exemplos

log_info	    echo_yellow	    Informação Simples: Mensagens de baixo impacto, como etapas concluídas ou puladas.
log_info	    echo_orange	    Informação de Alerta: Mensagens informativas que marcam o início de uma ação que não é fatal, mas que requer atenção.
log_info	    echo_red	    Informação Perigosa: Mensagens informativas que marcam o início de uma ação com potencial risco, que o usuário deve prestar atenção.

log_aviso	    echo_orange	    Aviso de Alerta: Problemas não-fatais que exigem atenção ou uma configuração manual.
log_aviso	    echo_red	    Aviso de Extremo Risco: Ações perigosas que impactarão diretamente o sistema, mas não são erros de execução.

log_error	    echo_red	    Erro: Falhas críticas que interrompem a execução do script.

log_success	    echo_green	    Sucesso: Ações concluídas com êxito.

}


# --- Funções de Cor ---
echo_green() { echo -e "\033[38;5;40m$1\033[0m"; }
echo_red() { echo -e "\033[38;5;196m$1\033[0m"; }
echo_orange() { echo -e "\033[38;5;202m$1\033[0m"; }
echo_yellow() { echo -e "\033[38;5;226m$1\033[0m"; }


# --- Funções de Log ---
log_info() { 
    if [[ -n "$1" ]]; then
        echo -e "\033[48;5;226m\033[30m[INFO]\033[0m $1"
    else
        echo -e "\033[48;5;226m\033[30m[INFO]\033[0m"
    fi
}

log_success() {
    if [[ -n "$1" ]]; then
        echo -e "\033[48;5;46m\033[30m[SUCESSO]\033[0m $1"
    else
        echo -e "\033[48;5;46m\033[30m[SUCESSO]\033[0m"
    fi
}

log_error() {
    if [[ -n "$1" ]]; then
        echo -e "\033[48;5;196m\033[97m[ERRO]\033[0m $1"
    else
        echo -e "\033[48;5;196m\033[97m[ERRO]\033[0m"
    fi
}

log_aviso() {
    if [[ -n "$1" ]]; then
        echo -e "\033[48;5;208m\033[30m[AVISO]\033[0m $1"
    else
        echo -e "\033[48;5;208m\033[30m[AVISO]\033[0m"
    fi
}


# --- Função para Combinar Prefixos e Cores ---
print_log() {
    local prefix="$1"
    local message="$2"
    echo -e "$prefix $message"
}


COLOR_RESET="\e[0m"
DELAY=0.0015

# --- Gradiente com delay e centralização ---
gradient_line() {
  local text="$1"
  local len="${#text}"
  local start_r=255 start_g=0 start_b=0
  local end_r=255 end_g=127 end_b=0
  local term_width=$(tput cols)
  local padding=$(( (term_width - len) / 2 ))

  printf "%*s" "$padding" ""

  for ((i=0; i<len; i++)); do
    local r=$((start_r))
    local g=$((start_g + i * (end_g - start_g) / len))
    local b=$((start_b + i * (end_b - start_b) / len))
    echo -ne "\e[38;2;${r};${g};${b}m${text:$i:1}${COLOR_RESET}"
    sleep $DELAY
  done
  echo
}

# --- Exibe o ASCII com gradiente e centralizado ---
show_ascii_logo() {
  local ascii_lines=(
"⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆"
"  ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦"
"          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄"
"           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄"
"           ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀"
"     ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄"
"   ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄"
"   ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄"
"    ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄"
"     ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆"
"      ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⣀⣀⣤⣾⡿⠃"
  ) 
  for line in "${ascii_lines[@]}"; do
    gradient_line "$line"
  done
}

# --- Banner com informações e gradiente ---
show_banner_info() {
  local lines=(
    "Criador: $CREATOR"
    "Versão: $SCRIPT_VERSION"
    "Criado em: $SINCE_DATE"
    "Atualizado em: $CURRENT_DATE"
  )

  local max_len=0
  for line in "${lines[@]}"; do
    (( ${#line} > max_len )) && max_len=${#line}
  done

  local padding=4
  local width=$((max_len + padding))
  local top="╔$(printf '═%.0s' $(seq 1 $width))╗"
  local mid="╠$(printf '═%.0s' $(seq 1 $width))╣"
  local bot="╚$(printf '═%.0s' $(seq 1 $width))╝"
  local title="SCRIPT INFO"
  local term_width=$(tput cols)
  local total_line="║$(printf '%*s' $(( (width - ${#title}) / 2 )) )$title$(printf '%*s' $(( (width - ${#title} + 1) / 2 )) )║"

  gradient_line "$top"
  gradient_line "$total_line"
  gradient_line "$mid"

  for line in "${lines[@]}"; do
    local label="${line%%:*}"
    local value="${line#*: }"
    local content=" ${label}: ${value}"
    local spaces=$((width - ${#content}))
    local full_line="║${content}$(printf '%*s' $spaces '')║"
    gradient_line "$full_line"
  done

  gradient_line "$bot"
}

handle_error() {
    local line_no=$1
    echo_red "Erro ocorreu na linha: ${line_no}"
}
trap 'handle_error ${LINENO}' ERR


# ==============================================================================
# FUNÇÃO GLOBAL DE PROGRESSO
# ==============================================================================
show_progress() {
    local msg="$1"
    local pid="$2"
    local delay=0.1
    local spinstr='-\|/'
    local current_status

    set +m

    while ps -p "$pid" > /dev/null 2>&1; do
        for i in $(seq 0 3); do
            printf "\r\033[36m[%c]\033[0m %s" "${spinstr:$i:1}" "$msg"
            sleep "$delay"
        done
    done

    wait "$pid" 2>/dev/null
    current_status=$?

    printf "\r\033[K"
    if [ "$current_status" -eq 0 ]; then
        printf "\033[32m[✓]\033[0m %s\n" "$msg"
        return 0
    else
        printf "\033[31m[X]\033[0m %s\n" "$msg"
        return 1
    fi
}

# ==============================================================================
# FUNÇÃO PARA ATUALIZAÇÃO DOS REPOSITÓRIOS
# ==============================================================================
apt_update() {
    # Inicia a atualização em segundo plano
    exec 3>&1
    { sudo apt-get update -qq; } 2>&1 &
    local pid=$!

    # Mostra o spinner enquanto a atualização roda
    if show_progress "Atualizando repositórios..." "$pid"; then
        # Conta pacotes atualizáveis
        local count
        count=$(apt list --upgradable 2>/dev/null | wc -l)
        count=$((count - 1))

        if [[ "$count" -gt 0 ]]; then
            print_log "$(log_info)" "$(echo_orange "$count pacotes podem ser atualizados.")"
        else
            print_log "$(log_success)" "$(echo_green "Nenhum pacote precisa ser atualizado.")"
        fi

        # Retorna o valor apenas se a função for chamada em contexto de captura
        if [[ -t 1 ]]; then
            : # nada a fazer, evita imprimir no terminal
        else
            echo "$count"
        fi
    else
        print_log "$(log_error)" "$(echo_red "Erro ao atualizar os repositórios.")"
        return 1
    fi
}


# ==============================================================================
# FUNÇÃO PARA ATUALIZAÇÃO DOS PROGRAMAS E SISTEMA
# ==============================================================================
apt_upgrade() {
    local upgrade_count="$1"

    # executa tudo em subshell e captura o PID
    (
        # Verifica se há atualizações a serem feitas
        if [[ "$upgrade_count" -le 0 ]]; then
            return 0
        fi

        # Mostra pacotes que serão atualizados, removidos e instalados
        sudo apt upgrade --assume-no | grep -E "removido|remove" || true

        # Executa as atualizações
        sudo apt upgrade -y -qq >/dev/null 2>&1
        sudo apt full-upgrade -y -qq >/dev/null 2>&1
        sudo apt dist-upgrade -y -qq >/dev/null 2>&1
    ) &
    local pid=$!

    if ! show_progress "Atualizando sistema..." "$pid"; then
        print_log "$(log_error)" "$(echo_red "Erro ao atualizar o sistema. Verifique o log para detalhes.")"
        return 1
    fi

    print_log "$(log_success)" "$(echo_green "Sistema atualizado.")"
    return 0
}









# ==============================================================================
# FUNÇÃO PARA ATUALIZAÇÃO DOS REPOSITORIOS
# ==============================================================================
apt_update2() {
    # Inicia a atualização em segundo plano
    exec 3>&1
    { sudo apt-get update -qq; } 2>&1 &
    local pid=$!

    # Mostra o spinner enquanto a atualização roda
    if show_progress "Atualizando repositórios..." "$pid"; then
        # Conta pacotes atualizáveis
        local count
        count=$(apt list --upgradable 2>/dev/null | wc -l)
        count=$((count - 1))

        if [[ "$count" -gt 0 ]]; then
            print_log "$(log_info)" "$(echo_orange "$count pacotes podem ser atualizados.")"
        else
            print_log "$(log_success)" "$(echo_green "Nenhum pacote precisa ser atualizado.")"
        fi

        # Retorna o valor apenas se a função for chamada em contexto de captura
        if [[ -t 1 ]]; then
            : # nada a fazer, evita imprimir no terminal
        else
            echo "$count"
        fi
    else
        print_log "$(log_error)" "$(echo_red "Erro ao atualizar os repositórios.")"
        return 1
    fi
}


# ==============================================================================
# FUNÇÃO PARA ATUALIZAÇÃO DOS PROGRAMAS E SISTEMA
# ==============================================================================
apt_upgrade2() {
    local upgrade_count="$1"

    # executa tudo em subshell e captura o PID
    (
        # Verifica se há atualizações a serem feitas
        if [[ "$upgrade_count" -le 0 ]]; then
            return 0
        fi

        # Mostra pacotes que serão atualizados, removidos e instalados
        sudo apt upgrade --assume-no | grep -E "removido|remove" || true

        # Executa as atualizações
        sudo apt upgrade -y -qq >/dev/null 2>&1
        sudo apt full-upgrade -y -qq >/dev/null 2>&1
        sudo apt dist-upgrade -y -qq >/dev/null 2>&1
    ) &
    local pid=$!

    if ! show_progress "Atualizando sistema..." "$pid"; then
        print_log "$(log_error)" "$(echo_red "Erro ao atualizar o sistema. Verifique o log para detalhes.")"
        return 1
    fi

    print_log "$(log_success)" "$(echo_green "Sistema atualizado.")"
    return 0
}




#apt_update ja sabe quantos programas precisa atualiza e se nao precisa, ja tem o proprio spinner. apos apt_update  executado, saberemos se podemos prosseguir para apt_upgrade. ou seja a logica e se update_system for sim, ele chama apt_update que atualiza o repositorio conta os pacotes e exibe o proprio spinner. se apt_update informar que a atualizacoes a serem feitas, entao apt_upgrade e chamado com seu proprio spinner






# ==============================================================================
# FUNÇÃO PARA ATUALIZAÇÃO COMPLETA DO SISTEMA
# ==============================================================================
update_full_system() {
    print_log "$(log_aviso)" "$(echo_red "ATUALIZANDO REPOSITÓRIOS E PACOTES DO SISTEMA")"

    # Etapa 1: Atualiza os repositórios (isso pode ser monitorado pelo spinner)
    exec 3>&1
    { sudo apt-get update -qq; } 2>&1 &
    local pid=$!

    if ! show_progress "Atualizando repositórios..." "$pid"; then
        print_log "$(log_error)" "$(echo_red "Erro ao atualizar os repositórios.")"
        return 1
    fi

    # Etapa 2: Conta os pacotes e exibe a mensagem de log
    local count
    count=$(apt list --upgradable 2>/dev/null | wc -l)
    count=$((count - 1))

    if [[ "$count" -le 0 ]]; then
        print_log "$(log_success)" "$(echo_green "Nenhum pacote precisa ser atualizado.")"
        echo
        return 0
    fi

    # Se houver pacotes, exibe a contagem
    print_log "$(log_info)" "$(echo_orange "$count pacotes podem ser atualizados.")"

    # Etapa 3: Inicia a atualização dos pacotes (monitorado por outro spinner)
    exec 3>&1
    {
        # Mostra pacotes que serão atualizados, removidos e instalados
        sudo apt upgrade --assume-no | grep -E "removido|remove" || true
        
        # Executa a atualização
        sudo apt upgrade -y -qq >/dev/null 2>&1
        sudo apt full-upgrade -y -qq >/dev/null 2>&1
        sudo apt dist-upgrade -y -qq >/dev/null 2>&1
    } 2>&1 &
    local pid_upgrade=$!

    if ! show_progress "Atualizando sistema..." "$pid_upgrade"; then
        print_log "$(log_error)" "$(echo_red "Erro ao atualizar o sistema. Verifique o log para detalhes.")"
        return 1
    fi

    print_log "$(log_success)" "$(echo_green "Sistema atualizado.")"
    echo
    return 0
}







# ==============================================================================
# FUNÇÃO PARA VERIFICAÇÃO DE PROGRAMAS INSTALADOS
# ==============================================================================
is_installed() {
    dpkg -l | grep -q "^ii  $1" 2>/dev/null
}


# ==============================================================================
# FUNÇÃO PARA INSTALAÇÃO DE PROGRAMAS
# ==============================================================================
instalar_programa() {
    local programas_instalados=()
    local programas_sucesso=()
    local programas_erro=()

    for programa in "$@"; do
        programa_maiusculo=$(echo "$programa" | tr '[:lower:]' '[:upper:]')

        if is_installed "$programa"; then
            programas_instalados+=("$programa_maiusculo")
        else
            exec 3>&1
            {
                sudo apt-get install -y -qq "$programa" </dev/null >/dev/null 2>&1
            } 2>&1 &
            local pid=$!

            if show_progress "INSTALANDO $programa_maiusculo..." $pid; then
                programas_sucesso+=("$programa_maiusculo")
            else
                programas_erro+=("$programa_maiusculo")
            fi
        fi
    done

    # Exibir resultados agrupados
    if (( ${#programas_instalados[@]} == 1 )); then
        echo_green "${programas_instalados[0]} JÁ ESTÁ INSTALADO."
    elif (( ${#programas_instalados[@]} > 1 )); then
        echo_green "$(printf "%s " "${programas_instalados[@]}") JÁ ESTÃO INSTALADOS."
    fi

    if (( ${#programas_sucesso[@]} == 1 )); then
        echo_green "${programas_sucesso[0]} INSTALADO COM SUCESSO."
    elif (( ${#programas_sucesso[@]} > 1 )); then
        echo_green "$(printf "%s " "${programas_sucesso[@]}") INSTALADOS COM SUCESSO."
    fi

    if (( ${#programas_erro[@]} == 1 )); then
        echo_red "ERRO AO INSTALAR ${programas_erro[0]}."
    elif (( ${#programas_erro[@]} > 1 )); then
        echo_red "ERRO AO INSTALAR: $(printf "%s " "${programas_erro[@]}")."
    fi
}


# ==============================================================================
# FUNÇÃO PARA DETECÇÃO AUTOMÁTICA DO SISTEMA
# ==============================================================================
detectar_sistema() {
    echo_red "DETECTANDO SISTEMA E ARQUITETURA..."

    local arch_raw=$(uname -m)

    case "$arch_raw" in
        "x86_64"|"amd64") SISTEMA_ARCH="amd64" ;;
        "aarch64") SISTEMA_ARCH="arm64" ;;
        "armv7l") SISTEMA_ARCH="armhf" ;;
        *) SISTEMA_ARCH="desconhecido" ;;
    esac

    if command -v termux-info >/dev/null 2>&1; then
        SISTEMA_TIPO="TERMUX"
        DISTRO_NOME="Termux"
        DISTRO_CODENAME="unknown"
    # Adicionamos a lógica para padronizar a detecção do Raspberry Pi para "RASP"
    elif grep -qi "raspberry" /proc/device-tree/model 2>/dev/null; then
        SISTEMA_TIPO="RASPBERRY"
        DISTRO_NOME="RaspberryPi"

        if [ -f /etc/os-release ]; then
            source /etc/os-release
            DISTRO_NAME=${ID:-unknown}
            DISTRO_CODENAME=${VERSION_CODENAME:-unknown}
        fi
    elif [ -f /etc/os-release ]; then
        source /etc/os-release
        # Padroniza a detecção para "PC" se for Linux genérico
        SISTEMA_TIPO="PC"
        DISTRO_NOME=${ID}
        DISTRO_CODENAME=${VERSION_CODENAME:-unknown}

        case "$DISTRO_CODENAME" in
            lunar|mantic|wilma|xia) DISTRO_CODENAME="jammy" ;;
            bullseye|buster) DISTRO_CODENAME="bookworm" ;;
        esac
    else
        SISTEMA_TIPO="desconhecido"
        DISTRO_NOME="unknown"
        DISTRO_CODENAME="unknown"
    fi

    if [[ "$SISTEMA_TIPO" == "desconhecido" || "$SISTEMA_ARCH" == "desconhecido" ]]; then
        echo_red "ERRO: Não foi possível detectar o sistema ou arquitetura de forma precisa."
        return 1
    fi

    return 0
}


# ==============================================================================
# FUNÇÃO PARA PERGUNTAS
# ==============================================================================
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
        echo_orange "$mensagem (Y/N):"
        read -r resposta
        resposta=$(echo "$resposta" | tr '[:lower:]' '[:upper:]')

        if [[ -z "$resposta" ]]; then
            resposta="N"
        fi

        if [[ "$resposta" =~ ^[YN]$ ]]; then
            eval "$var_name='$resposta'"
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

