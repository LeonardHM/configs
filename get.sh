#!/bin/bash

# Este script atua como um 'bootloader' para o sistema de configuração.
# Ele garante que as dependências básicas estejam instaladas e que o repositório
# de configurações seja clonado ou atualizado antes de executar o script principal.

# --- Variáveis de Configuração ---
INSTALL_BASE_DIR="$HOME/clone"
REPO_URL="https://github.com/LeonardHM/configs.git"
CLONED_REPO_DIR="$INSTALL_BASE_DIR/configs"

# --- Funções de Cor ---
# Essas funções apenas definem as cores para serem usadas pelo sistema de log.
echo_green() { echo -e "\033[38;5;40m$1\033[0m"; }
echo_red() { echo -e "\033[38;5;196m$1\033[0m"; }
echo_orange() { echo -e "\033[38;5;202m$1\033[0m"; }
echo_yellow() { echo -e "\033[38;5;226m$1\033[0m"; }

# --- Funções de Log ---
# Funções para gerar os prefixos de log coloridos.
# A função log_error encerra o script com um status de erro.
log_info() { echo -e "\033[48;5;226m\033[30m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[48;5;46m\033[30m[SUCESSO]\033[0m $1"; }
log_error() { echo -e "\033[48;5;196m\033[97m[ERRO]\033[0m $1" ; }
log_aviso() { echo -e "\033[48;5;208m\033[30m[AVISO]\033[0m $1"; }

# --- Nova Função para Combinar Prefixos e Cores ---
# Usa as funções de log e as de cor para uma saída mais consistente.
print_log() {
    local prefix="$1"
    local message="$2"
    echo -e "$prefix $message"
}
clear
# --- Funções para o Fluxo do Script ---

# Instala as dependências necessárias para o script.
instalar_dependencias() {
    local skip_git="$1"
    print_log "$(log_aviso)" "$(echo_red "Verificando e instalando dependências básicas...")"

    # Atualiza a lista de pacotes antes de instalar.
    sudo apt-get update >/dev/null 2>&1 || print_log "$(log_error)" "$(echo_red "Falha ao atualizar a lista de pacotes.")"

    # Itera sobre os comandos a serem instalados.
    for cmd in git nano; do
        # Se o comando for `git` e a flag `--skip_git` estiver definida, pule a instalação.
        if [[ "$cmd" == "git" ]] && [[ "$skip_git" == "true" ]]; then
            print_log "$(log_info)" "$(echo_yellow "Instalação do git pulada por solicitação do usuário.")"
            continue
        fi

        # Se o comando não estiver instalado, instale-o.
        if ! command -v "$cmd" &>/dev/null; then
            print_log "$(log_info)" "$(echo_orange "Instalando $cmd...")"
            sudo apt-get install -y "$cmd" >/dev/null 2>&1 || print_log "$(log_error)" "$(echo_red "Falha ao instalar $cmd.")"
        fi
    done

    # --- BLOCO DE VERIFICAÇÃO ---
    if [[ "$skip_git" == "true" ]]; then
        if ! command -v git &>/dev/null; then
            print_log "$(log_error)" "$(echo_red "O Git não está instalado e a instalação foi pulada. O script não pode continuar.")"
            exit 1
        fi
    fi

    print_log "$(log_success)" "$(echo_green "Dependências básicas verificadas e instaladas.")"
}


# Clona ou atualiza o repositório de configurações.
configurar_repositorio() {
    print_log "$(log_info)" "$(echo_red "Configurando ambiente de instalação em $INSTALL_BASE_DIR...")"

    # Cria o diretório base e ajusta as permissões.
    sudo mkdir -p "$INSTALL_BASE_DIR" || print_log "$(log_error)" "$(echo_red "Falha ao criar diretório base: $INSTALL_BASE_DIR")"
    sudo chown -R "$(id -u):$(id -g)" "$INSTALL_BASE_DIR"

    if [ ! -d "$CLONED_REPO_DIR" ]; then
        print_log "$(log_info)" "$(echo_yellow "Clonando o repositório de configurações ($REPO_URL) para $CLONED_REPO_DIR...")"
        git clone --quiet "$REPO_URL" "$CLONED_REPO_DIR" || print_log "$(log_error)" "$(echo_red "Falha ao clonar o repositório.")"
    else
        print_log "$(log_info)" "$(echo_yellow "Repositório já existe em $CLONED_REPO_DIR. Atualizando...")"
        (cd "$CLONED_REPO_DIR" && git pull --quiet) || print_log "$(log_aviso)" "$(echo_orange "Falha ao atualizar o repositório. Continuado assim mesmo.")"
    fi
    print_log "$(log_success)" "$(echo_green "Repositório configurado com sucesso.")"
}


# --- Execução do Script ---
main() {
    local ARGS=("$@")
    local skip_git="false"
    local main_sh_args=() # Nova array para armazenar argumentos para main.sh

    # Processa os argumentos para verificar a flag --skip_git
    for arg in "${ARGS[@]}"; do
        if [[ "$arg" == "--skip_git" ]]; then
            skip_git="true"
        else
            # Adiciona o argumento para a nova array, se não for --skip_git
            main_sh_args+=("$arg")
        fi
    done

    instalar_dependencias "$skip_git"
    configurar_repositorio

    # Executa o script principal (`main.sh`) com os argumentos filtrados.
    print_log "$(log_info)" "$(echo_green "Iniciando a execução do script principal ($CLONED_REPO_DIR/main.sh)...")"
    exec sudo -E "$CLONED_REPO_DIR/main.sh" "${main_sh_args[@]}"
}

# Executa a função principal do script com todos os argumentos.
main "$@"

