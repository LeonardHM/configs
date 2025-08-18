# Função para configurar conexões Wi-Fi
configurar_wifi() {
    print_log "$(log_aviso)" "$(echo_red "CONFIGURANDO CONEXÕES WI-FI")"
    local total=${#WIFI_CONFIGS[@]}
    local current=0

    for config in "${WIFI_CONFIGS[@]}"; do
        IFS=':' read -r ssid senha prioridade <<< "$config"

        print_log "$(log_info)" "$(echo_orange "Conectando e configurando $ssid...")"
        sudo nmcli dev wifi connect "$ssid" password "$senha" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao conectar ao Wi-Fi $ssid.")"
            continue
        }

        # Configurar IPv4 e IPv6
        sudo nmcli connection modify "$ssid" \
            ipv4.method manual \
            ipv4.addresses "$WIFI_IP_ADDRESS" \
            ipv4.gateway "$WIFI_GATEWAY" \
            ipv4.dns "$WIFI_DNS" \
            ipv6.method auto \
            connection.autoconnect-priority "$prioridade" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao modificar a conexão $ssid.")"
            continue
        }
        print_log "$(log_success)" "$(echo_green "$ssid configurado com sucesso.")"
    done

    sudo systemctl restart NetworkManager >/dev/null 2>&1
    print_log "$(log_success)" "$(echo_green "Configuração de Wi-Fi concluída.")"
}

# Função para compartilhar a internet via ETH0 sem Pi-hole
compartilhar_internet() {
    print_log "$(log_aviso)" "$(echo_red "COMPARTILHANDO INTERNET POR ETH0 SEM PI-HOLE")"

    if [ -n "$conexao_lan" ]; then
        print_log "$(log_info)" "$(echo_orange "Ativando compartilhamento de internet na conexão: $conexao_lan")"
        # Ativa o compartilhamento de Internet na conexão identificada
        sudo nmcli con modify "$conexao_lan" ipv4.method shared >/dev/null 2>&1
        # IP estático para eth0
        sudo nmcli con mod "$conexao_lan" ipv4.addresses "$SHARED_IP_ADDRESS" >/dev/null 2>&1
        sudo nmcli con reload "$conexao_lan" >/dev/null 2>&1
        sudo nmcli con up "$conexao_lan" >/dev/null 2>&1

        sudo systemctl restart NetworkManager >/dev/null 2>&1
        print_log "$(log_success)" "$(echo_green "Compartilhamento de Internet ativado com sucesso em: "$conexao_lan"")"
        echo
    else
        print_log "$(log_aviso)" "$(echo_yellow "Nenhuma conexão cabeada ativa encontrada.")"
        echo
	return 1
    fi
}

# Função para compartilhar a internet e instalar/configurar o Pi-hole
compartilhar_internet_pihole(){
    print_log "$(log_aviso)" "$(echo_red "COMPARTILHANDO INTERNET POR ETH0 COM PI-HOLE")"

    # Compartilhar a internet antes de instalar o Pi-hole
    compartilhar_internet || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao compartilhar a internet. Abortando instalação do Pi-hole.")"; return 1; }

    # Instalar dependências
    print_log "$(log_info)" "$(echo_orange "Instalando dependências...")"
    apt_update >/dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive instalar_programa iptables-persistent curl sqlite3 >/dev/null 2>&1 || {
        print_log "$(log_error)" "$(echo_red "ERRO: Falha ao instalar dependências.")"
        return 1
    }
    print_log "$(log_success)" "$(echo_green "Dependências instaladas com sucesso.")"

    # Habilitar encaminhamento de pacotes
    print_log "$(log_info)" "$(echo_orange "Habilitando encaminhamento de pacotes...")"
    sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
    print_log "$(log_success)" "$(echo_green "Encaminhamento de pacotes habilitado.")"

    # Instalar Pi-hole
    print_log "$(log_info)" "$(echo_orange "Iniciando a instalação do Pi-hole...")"
    sudo curl -sSL https://install.pi-hole.net | sudo bash --unattended >/dev/null 2>&1 || {
        print_log "$(log_error)" "$(echo_red "ERRO: Falha na instalação do Pi-hole.")"
        return 1
    }
    print_log "$(log_success)" "$(echo_green "Pi-hole instalado com sucesso.")"

    # Configurar dnsmasq para DHCP e DNS
    print_log "$(log_info)" "$(echo_orange "Configurando dnsmasq para Pi-hole...")"
    cat <<EOF | sudo tee /etc/dnsmasq.d/02-pihole-dhcp.conf >/dev/null
dhcp-authoritative
dhcp-range=$DHCP_RANGE,24h
dhcp-option=option:router,$PIHOLE_DNS
dhcp-option=3,$PIHOLE_DNS  # Gateway
dhcp-option=6,$PIHOLE_DNS  # Servidor DNS
dhcp-leasefile=/etc/pihole/dhcp.leases
domain=lan
local=/lan/
EOF
    print_log "$(log_success)" "$(echo_green "dnsmasq configurado.")"

	# Define a porta do webserver Pi-Hole
	print_log "$(log_info)" "$(echo_orange "Configurando a porta do webserver Pi-hole...")"
	sudo sed -i 's/^\s*port\s*=\s*".*"/port = "49999o,[::]:49999o,50000os,[::]:50000os"/' /etc/pihole/pihole.toml >/dev/null 2>&1
	print_log "$(log_success)" "$(echo_green "Porta do webserver Pi-hole configurada.")"

    # Adicionando as blocklists ao banco de dados
    print_log "$(log_info)" "$(echo_orange "Adicionando blocklists ao Pi-hole...")"
    local DB_PATH="/etc/pihole/gravity.db"
    sudo cp /etc/pihole/gravity.db /etc/pihole/gravity.db.bak >/dev/null 2>&1
    sudo chmod 664 "$DB_PATH" >/dev/null 2>&1

    # Lista de blocklists https://firebog.net
    BLOCKLISTS=(
        "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
        "https://v.firebog.net/hosts/static/w3kbl.txt"
        "https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt"
        "https://someonewhocares.org/hosts/zero/hosts"
        "https://raw.githubusercontent.com/VeleSila/yhosts/master/hosts"
        "https://winhelp2002.mvps.org/hosts.txt"
        "https://v.firebog.net/hosts/neohostsbasic.txt"
        "https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt"
        "https://paulgb.github.io/BarbBlock/blacklists/hosts-file.txt"
        "https://adaway.org/hosts.txt"
        "https://v.firebog.net/hosts/AdguardDNS.txt"
        "https://v.firebog.net/hosts/Admiral.txt"
        "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
        "https://v.firebog.net/hosts/Easylist.txt"
        "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
        "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
        "https://v.firebog.net/hosts/Easyprivacy.txt"
        "https://v.firebog.net/hosts/Prigent-Ads.txt"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
        "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
        "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
        "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt"
        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt"
        "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt"
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
        "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
        "https://v.firebog.net/hosts/Prigent-Crypto.txt"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
        "https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt"
        "https://phishing.army/download/phishing_army_blocklist_extended.txt"
        "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
        "https://v.firebog.net/hosts/RPiList-Malware.txt"
        "https://v.firebog.net/hosts/RPiList-Phishing.txt"
        "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
        "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
        "https://urlhaus.abuse.ch/downloads/hostfile/"
        "https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt"
        "https://v.firebog.net/hosts/Prigent-Malware.txt"
    )

    for URL in "${BLOCKLISTS[@]}"; do
        sudo sqlite3 "$DB_PATH" "INSERT OR IGNORE INTO adlist (address, enabled) VALUES ('$URL', 1);" >/dev/null 2>&1
    done
    print_log "$(log_success)" "$(echo_green "Blocklists adicionadas com sucesso.")"

    # Atualizando a lista de gravidade
    print_log "$(log_info)" "$(echo_orange "Atualizando a lista de gravidade do Pi-hole...")"
    sudo pihole -g >/dev/null 2>&1
    print_log "$(log_success)" "$(echo_green "Lista de gravidade atualizada.")"

    # Atualiza senha do pi-hole
    print_log "$(log_aviso)" "$(echo_red "DEFINA UMA SENHA PARA O PI-HOLE")"
    sudo pihole setpassword
    print_log "$(log_success)" "$(echo_green "SENHA CONFIGURADA COM SUCESSO.")"

    # Reiniciar o serviço Pi-hole
    print_log "$(log_info)" "$(echo_orange "Reiniciando o serviço Pi-hole...")"
    sudo systemctl restart pihole-FTL >/dev/null 2>&1
    print_log "$(log_success)" "$(echo_green "Serviço Pi-hole reiniciado.")"

    # Configurar iptables para NAT
    print_log "$(log_info)" "$(echo_orange "Configurando regras de iptables para NAT...")"
    sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
    sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
    sudo iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    print_log "$(log_success)" "$(echo_green "Regras de iptables aplicadas.")"

    # Salvar regras de iptables
    print_log "$(log_info)" "$(echo_orange "Salvando regras de iptables...")"
    sudo sh -c "iptables-save > /etc/iptables/rules.v4"
    print_log "$(log_success)" "$(echo_green "Regras salvas.")"

    # Concluir configuração
    print_log "$(log_success)" "$(echo_green "=== Configuração do Pi-hole e compartilhamento de internet concluída! ===")"
    print_log "$(log_aviso)" "$(echo_yellow "Reinicie o Raspberry Pi para garantir que todas as alterações sejam aplicadas.")"
}

