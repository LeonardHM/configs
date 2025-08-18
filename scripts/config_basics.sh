config_zsh() {
    print_log "$(log_info)" "$(echo_red "CONFIGURANDO ZSH")"

    # Executa tudo em um único subshell
    (
        # Verifica e limpa instalação corrompida
        if [ -d "$ZSH_DIR" ] && [ ! -f "$ZSH_SCRIPT" ]; then
            print_log "$(log_info)" "$(echo_orange "Detectada instalação incompleta. Preparando reinstalação...")"
            rm -rf "$ZSH_DIR" >/dev/null 2>&1
        fi

        # Instalação do Oh My Zsh
        if [ ! -d "$ZSH_DIR" ]; then
            # Configura zsh como shell padrão
            sudo chsh -s "$(which zsh)" "$USER" >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "Erro ao trocar o shell para ZSH. Certifique-se de que o ZSH está instalado.")"
                exit 1
            }

            # Instala Oh My Zsh silenciosamente
            ZSH="$ZSH_DIR" sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1
        fi

        # Configura o .zshrc
        if [ -f "$HOME/.zshrc" ]; then
            cp -f "$HOME/.zshrc" "$HOME/.zshrc.bak" >/dev/null 2>&1
        fi
        cp -f "$CLONE_DIR/configs/.zshrc" "$HOME/" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "Falha ao copiar .zshrc")"
            exit 1
        }

        # Configura plugins
        mkdir -p "$PLUGIN_ZSH_DIR" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "Erro ao criar diretório para plugins.")"
            exit 1
        }

        for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting"; do
            if [ ! -d "$PLUGIN_ZSH_DIR/$plugin" ]; then
                git clone -q "https://github.com/zsh-users/$plugin" "$PLUGIN_ZSH_DIR/$plugin" || {
                    print_log "$(log_error)" "$(echo_red "Erro ao instalar o plugin '$plugin'.")"
                    exit 1
                }
            else
                git -C "$PLUGIN_ZSH_DIR/$plugin" pull -q || {
                    print_log "$(log_error)" "$(echo_red "Erro ao atualizar o plugin '$plugin'.")"
                    exit 1
                }
            fi
        done
    ) &
    local pid=$!

    # Spinner único para toda a configuração
    if show_progress "Configurando ZSH..." "$pid"; then
        print_log "$(log_success)" "$(echo_green "ZSH configurado com sucesso!")"
        echo
    else
        print_log "$(log_error)" "$(echo_red "Erro na configuração do ZSH")"
        echo
        return 1
    fi
}


# fazer verificação do bashrc
# Função para copiar arquivo bash
func_geral() {
    if [ -f "$HOME/.bashrc" ]; then
        cp -f "$HOME/.bashrc" "$HOME/.bashrc.bak" >/dev/null 2>&1
    fi
    print_log "$(log_info)" "$(echo_orange "Copiando .bashrc para o diretório do usuário...")"  
    cp -f $CLONE_DIR/configs/.bashrc "$HOME/" || { print_log "$(log_error)" "$(echo_red "Falha ao copiar .bashrc")"; exit 1; }
    print_log "$(log_success)" "$(echo_green "Arquivo .bashrc copiado com sucesso.")"
    echo
}


# Função para termux
func_termux() {
    (
        pkg install root-repo x11-repo termux-api "${zsh_install[@]}" -y >/dev/null 2>&1
        cp -fr $CLONE_DIR/configs/.termux "$HOME/"
        cp -f $CLONE_DIR/configs/.termux_authinfo "$HOME/"
        sed -i 's/^#\\(termux-fingerprint.*\\)$/\\1/' "$HOME/.zshrc"
    ) &
    local pid=$!

    if ! show_progress "Configurando Termux" "$pid"; then
        print_log "$(log_error)" "$(echo_red "ESSE COMANDO É PARA TERMUX")"; exit 1;
    fi

    print_log "$(log_success)" "Arquivos de configuração do Termux copiados."
    config_zsh
}

# Função para pc
func_pc() {
    print_log "$(log_info)" "Iniciando configuração completa para PC..."

    # Vivaldi
    (
        if ! grep -q "http://repo.vivaldi.com/stable/deb/" /etc/apt/sources.list; then
            sudo sh -c 'echo "deb http://repo.vivaldi.com/stable/deb/ stable main" >> /etc/apt/sources.list'
            wget -q -O - http://repo.vivaldi.com/stable/linux_signing_key.pub | sudo apt-key add -

            # COMENTAR "deb [arch=amd64] https://repo.vivaldi.com/stable/deb/ stable main" no arquivo /etc/apt/sources.list.d/vivaldi.list
            sudo sed -i 's|^deb \[arch=amd64\] https://repo.vivaldi.com/stable/deb/ stable main|#deb [arch=amd64] https://repo.vivaldi.com/stable/deb/ stable main|g' "/etc/apt/sources.list.d/vivaldi.list"
        fi
    ) &
    local pid1=$!
    if ! show_progress "Adicionando repositório Vivaldi" "$pid1"; then
        print_log "$(log_error)" "$(echo_red "Falha ao adicionar repositório Vivaldi.")"
    fi



    # PPAs (deve perguntar se o usuario realmente quer instalar individualmente, sem -y)
    (sudo add-apt-repository ppa:kisak/kisak-mesa >/dev/null 2>&1) &
    local pid2=$!
    if ! show_progress "Adicionando PPA do MESA" "$pid2"; then
        print_log "$(log_error)" "$(echo_red "Falha ao adicionar PPA do MESA.")"
    fi

    (sudo add-apt-repository ppa:danielrichter2007/grub-customizer >/dev/null 2>&1) &
    local pid3=$!
    if ! show_progress "Adicionando PPA do Grub Customizer" "$pid3"; then
        print_log "$(log_error)" "$(echo_red "Falha ao adicionar PPA do Grub Customizer.")"
    fi

    (sudo rm "/etc/apt/preferences.d/nosnap.pref" >/dev/null 2>&1) &
    local pid4=$!
    if ! show_progress "Removendo configurações do Snap" "$pid4"; then
        print_log "$(log_error)" "$(echo_red "Falha ao remover configurações do Snap.")"
    fi

    (sudo add-apt-repository ppa:zhangsongcui3371/fastfetch >/dev/null 2>&1) &
    local pid5=$!
    if ! show_progress "Adicionando PPA do Fastfetch" "$pid5"; then
        print_log "$(log_error)" "$(echo_red "Falha ao adicionar PPA do Fastfetch.")"
    fi

    # Atualização de pacotes
    apt_update


    # Programas
    (flatpak install flathub com.rtosta.zapzap -y >/dev/null 2>&1) &
    local pid7=$!
    if ! show_progress "Instalando Zapzap via Flatpak" "$pid7"; then
        print_log "$(log_error)" "$(echo_red "Falha ao instalar Zapzap.")"
    fi

    # Telegram
    (
      wget -O "$CLONE_DIR/telegram.tar.xz" https://telegram.org/dl/desktop/linux >/dev/null 2>&1
      tar xf "$CLONE_DIR/telegram.tar.xz" -C "$CLONE_DIR" >/dev/null 2>&1
    ) &

    local pid8=$!
    if ! show_progress "Instalando Telegram" "$pid8"; then
        print_log "$(log_error)" "$(echo_red "Falha ao instalar Telegram.")"
    fi

    # Instalação via APT
    instalar_programa grub-customizer vivaldi-stable gparted gpart ppa-purge snapd wine-installer winetricks fastfetch inxi python3-pip

    # Remoção de programas
    (sudo apt purge sticky onboard firefox mintchat -y >/dev/null 2>&1) &
    local pid11=$!
    if ! show_progress "Removendo programas indesejados" "$pid11"; then
        print_log "$(log_error)" "$(echo_red "Falha ao remover programas.")"
    fi

    # Upgrade do sistema
    apt_upgrade

    print_log "$(log_success)" "Configuração de PC finalizada."


    #https://cinnamon-spices.linuxmint.com/files/applets/gpaste-reloaded@feuerfuchs.eu.zip?time=1738175810
    #sudo apt install gpaste-2 gir1.2-gpaste-2


    #https://cinnamon-spices.linuxmint.com/files/applets/Cinnamenu@json.zip?time=1738175945


    #https://cinnamon-spices.linuxmint.com/files/applets/show-hide-applets@mohammad-sn.zip?time=1738176079

}

# Função para pc e raspberry
func_pc_rasp() {
    instalar_programa "${zsh_install[@]}"
    echo
    config_zsh
}

# Função para configurar temas, ícones e wallpapers.
config_theme() {
    print_log "$(log_info)" "$(echo_orange "Clonando / Atualizando repositórios de temas, ícones e wallpapers...")"
    echo_orange "Flat-Remix, Flat-Remix-GTK, LeonardHM/custom"
    # Cria um subshell para executar as operações em segundo plano.
    # O `&` no final envia o subshell para o background, e seu PID é armazenado.
    (
        # Clona ou atualiza o repositório Flat-Remix
        if [ ! -d "$CLONE_DIR/flat-remix" ]; then
            git clone --quiet "https://github.com/daniruiz/flat-remix" "$CLONE_DIR/flat-remix" >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "Falha ao clonar Flat-Remix.")"
                exit 1
            }
        else
            git config --global --add safe.directory "$CLONE_DIR/flat-remix"
            sudo git -C "$CLONE_DIR/flat-remix" pull --quiet >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "Falha ao atualizar Flat-Remix.")"
                exit 1
            }
        fi

        # Clona ou atualiza o repositório Flat-Remix-GTK
        if [ ! -d "$CLONE_DIR/flat-remix-gtk" ]; then
            git clone --quiet "https://github.com/daniruiz/flat-remix-gtk" "$CLONE_DIR/flat-remix-gtk" >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "Falha ao clonar Flat-Remix-GTK.")"
                exit 1
            }
        else
            git config --global --add safe.directory "$CLONE_DIR/flat-remix-gtk"
            sudo git -C "$CLONE_DIR/flat-remix-gtk" pull --quiet >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "Falha ao atualizar Flat-Remix-GTK.")"
                exit 1
            }
        fi

        # Cria os diretórios necessários.
        mkdir -p "$HOME/.icons"
        mkdir -p "$HOME/.themes"

        # Clona ou atualiza o repositório LeonardHM/custom
        if [ ! -d "$CLONE_DIR/custom" ]; then
            git clone --quiet "https://github.com/LeonardHM/custom" "$CLONE_DIR/custom" >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "Falha ao clonar LeonardHM/custom")"
                exit 1
            }
        else
            git config --global --add safe.directory "$CLONE_DIR/custom"
            sudo git -C "$CLONE_DIR/custom" pull --quiet >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "Falha ao atualizar LeonardHM/custom")"
                exit 1
            }
        fi

        # Sincroniza o diretório de ícones, sobrescrevendo apenas os arquivos que mudaram
        rsync -a "$CLONE_DIR/custom/.icons/" "$HOME/.icons/" || {
            print_log "$(log_error)" "$(echo_red "Falha ao sincronizar $CLONE_DIR/custom/.icons/ para $HOME/.icons")"
            exit 1
        }

        # Sincroniza o diretório de ícones Flat-Remix
        rsync -a "$CLONE_DIR/flat-remix/Flat-Remix-Blue-Dark" "$HOME/.icons/" || {
            # Mensagem de erro corrigida para 'sincronizar'
            print_log "$(log_error)" "$(echo_red "Falha ao sincronizar $CLONE_DIR/flat-remix/Flat-Remix-Blue-Dark para $HOME/.icons/")"
            exit 1
        }

        # Sincroniza o diretório de temas
        rsync -a "$CLONE_DIR/custom/.themes/" "$HOME/.themes/" || {
            print_log "$(log_error)" "$(echo_red "Falha ao sincronizar $CLONE_DIR/custom/.themes/ para $HOME/.themes/")"
            exit 1
        }

        # Copia os temas Flat-Remix-GTK.
        for theme in "Flat-Remix-GTK-Blue-Dark" "Flat-Remix-GTK-Blue-Dark-Solid" "Flat-Remix-GTK-Blue-Darkest" "Flat-Remix-GTK-Blue-Darkest-Solid"; do
            rsync -a "$CLONE_DIR/flat-remix-gtk/themes/$theme" "$HOME/.themes/" || {
                print_log "$(log_error)" "$(echo_red "Falha ao sincronizar $CLONE_DIR/flat-remix-gtk/themes/$theme para $HOME/.themes/")"
                exit 1
            }
        done



    ) & # Executa todo o bloco acima em segundo plano.
    local pid=$! # Armazena o PID do processo em segundo plano.

    # Exibe o spinner e espera a conclusão do processo.
    if ! show_progress "Clonando e configurando temas, ícones e wallpapers..." "$pid"; then
        print_log "$(log_error)" "$(echo_red "ERRO: O processo de configuração de temas falhou. Verifique os logs acima.")"
        return 1
    fi

    # Se o processo em segundo plano for concluído com sucesso, exibe a mensagem final.
    print_log "$(log_success)" "$(echo_green "Temas, ícones e wallpapers copiados com sucesso.")"
    echo
    return 0
}

