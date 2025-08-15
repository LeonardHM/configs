# 🤖 Automação de Configuração de Servidor

Este projeto oferece um conjunto de scripts em Bash para automatizar a configuração de um servidor Linux, com foco em distribuições baseadas no Debian.

* \[x\] `Raspberry / Debian - Linux Mint - Termux`

> 💡 Existem funções específicas para Termux e Linux Mint.

---

### 💻 Recursos Principais

- **Instalação de Programas**: Zsh, ferramentas básicas e utilitários de monitoramento.
- **Gerenciamento de Rede**: Conexão Wi-Fi, compartilhamento de internet via LAN e Pi-hole.
- **Docker & Cloud**: Instalação de Docker, Docker Compose, Cloudflare Tunnel e monitoramento via MQTT.
- **Serviços**: Cosmos Cloud, servidor Minecraft, Rclone (Google Drive).
- **Home Assistant**: Instalação automatizada do HACS e componentes essenciais.
- **Acesso Remoto**: SSH e VNC Server prontos para uso.

---

### 📚 Índice

- [❓ Como Usar](#-como-usar)
- [🚀 Modos de Execução](#-modos-de-execu%C3%A7%C3%A3o)
- [⚙️ Variáveis de Opções](#%EF%B8%8F-vari%C3%A1veis-de-op%C3%A7%C3%B5es)
- [🛠️ Variáveis de Configurações](#%EF%B8%8F-vari%C3%A1veis-de-configura%C3%A7%C3%B5es)
- [🚫 Comandos para EXPERT](#-comandos-para-expert-fun%C3%A7%C3%B5es-espec%C3%ADfica)
- [🚼 Exemplos de Uso](#-exemplos-de-uso)
- [📬 Contribuições e Suporte](#-contribuições-e-suporte)

---

### ❓ Como Usar
**Instalação rápida:**
 Este comando baixa, instala dependências e executa o script automaticamente.
```bash
curl -fsSL https://raw.githubusercontent.com/LeonardHM/configs/refs/heads/caceta/get.sh -o get.sh && sudo -E bash get.sh && rm get.sh
```
> use "sudo -E bash get.sh --skip_git" caso você ja tenha git instalado

> rm get.sh não é estritamente necessário, mas mantém tudo limpo (apaga o arquivo após a execução)

---

### 🚀 Modos de Execução

#### **Modo Interativo (Padrão)**
 Executa o script fazendo perguntas para você.
```bash
sudo -E bash get.sh
```

#### **Modo Interativo + Variáveis**
 Executa o script fazendo perguntas para você, porém pula a pergunta relacionada a variavel
```bash
sudo -E bash get.sh --conectar_wifi=y --cosmos=n
```

#### **Modo Rápido (`--fast`)**
 Pula todas as perguntas e usa apenas as variáveis passadas na linha de comando.
```bash
sudo -E bash get.sh --fast --docker=y --ativar_ssh=n
```

#### **Modo Expert (`--expert`)**
 Executa apenas UMA função específica do script.
```bash
sudo -E bash get.sh --expert config_zsh
```

---

**Sintaxe PADRÃO:** `sudo -E bash get.sh` <br>
**Sintaxe PADRÃO + VARIÁVEIS:** `sudo -E bash get.sh --variavel=valor --outra_variavel=valor` <br>
**Sintaxe FAST:** `sudo -E bash get.sh --fast --variavel=valor --outra_variavel=valor` <br>
**Sintaxe EXPERT:** `sudo -E bash get.sh --expert nome_da_função`

---

### ⚙️ Variáveis de Opções

| Badge | Variável | Valor | Descrição | Configuração |
| :---: | :--- | :--- | :--- | :--- |
| ![80%](https://img.shields.io/badge/80%25-yellow) | `--conectar_wifi` | `y\|n` | Conecta à rede Wi-Fi configurada. | `--WIFI_CONFIGS --WIFI_IP_ADDRESS --WIFI_GATEWAY --WIFI_DNS` |
| ![100%](https://img.shields.io/badge/100%25-brightgreen) | `--compartilhar_internet_lan` | `y\|n` | Habilita o compartilhamento de internet pela porta Ethernet. | `--SHARED_IP_ADDRESS` |
| | `--instalar_pi_hole` | `y\|n` | Instala o Pi-hole junto com o compartilhamento de internet. | `--SHARED_IP_ADDRESS --DHCP_RANGE --PIHOLE_DNS` |
| ![80%](https://img.shields.io/badge/80%25-yellow) | `--update_system` | `y\|n` | Atualiza todos os pacotes e o sistema. |
| ![100%](https://img.shields.io/badge/100%25-brightgreen) | `--install_basic_zsh` | `y\|n` | Instala programas básicos e o Zsh. |
| ![100%](https://img.shields.io/badge/100%25-brightgreen) | `--install_theme` | `y\|n` | Instala temas, ícones e wallpapers. [![GitHub](https://img.shields.io/badge/CUSTOM-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/LeonardHM/custom) |
| | `--programas` | `"prog1 prog2"` | Instala programas específicos (ex: `"Heimdall SCRCPY PI-APPS"`). |
| | `--pi_apps_programas` | `"prog1 prog2"` | Instala programas do Pi-Apps (ex: `"Minecraft Vivaldi"`). <br> **Observação:** Esta variável só terá efeito se a variável `--programas` incluir `PI-APPS`. |
| | `--ativar_ssh` | `y\|n` | Ativa e configura o acesso SSH. |
| | `--ativar_vnc` | `y\|n` | Ativa e configura o VNC Server. |
| ![100%](https://img.shields.io/badge/100%25-brightgreen) | `--habilitar_tft` | `y\|n` | Habilita o display TFT no Raspberry Pi. |
| | `--drive` | `y\|n` | Configura o Google Drive com Rclone. | `--RCLONE_CONFIG` |
| ![80%](https://img.shields.io/badge/80%25-yellow)) | `--alexa_commands` | `y\|n` | Instala TriggerCMD para comandos da Alexa. | `--TRIGGERCMD_TOKEN` |
| | `--cosmos` | `y\|n` | Instala Cosmos Cloud Server. [![GitHub](https://img.shields.io/badge/COSMOS--SERVER-100000?style=for-the-badge&logo=github&logoColor=white&label=)](https://github.com/azukaar/cosmos-server) | `--CLOUDFLARE_TOKEN` |
| | `--mine_server` | `y\|n` | Instala um servidor de Minecraft Java. |
| ![100%](https://img.shields.io/badge/100%25-brightgreen) | `--reiniciar` | `y\|n` | Reinicia o sistema após a finalização do script. |

> 💡 **Dica:** Os badges indicam o nível de implementação da função.
> - ![100%](https://img.shields.io/badge/100%25-brightgreen) 100% funcional
> - ![80%](https://img.shields.io/badge/80%25-yellow) em desenvolvimento
> - ![50%](https://img.shields.io/badge/50%25-orange) parcial
> - ![20%](https://img.shields.io/badge/20%25-red) básico ou incompleto

---

### 🛠️ Variáveis de Configurações

| Variável | Valor | Exemplo | Descrição |
| :--- | :--- | :--- | :--- |
| `--WIFI_CONFIGS` | `""<SSID:PSK:PRIORITY>","<SSID:PSK:PRIORITY>""` | `""teSt1:123456789:7","test2-5G:abcdef:9""` | Define as redes Wi-Fi a serem configuradas. |
| `--WIFI_IP_ADDRESS` | `<IP/CIDR>` | `192.168.15.20/24` | Define o endereço IP para a conexão Wi-Fi. |
| `--WIFI_GATEWAY` | `<IP>` | `192.168.15.1` | Define o gateway padrão para a conexão Wi-Fi. |
| `--WIFI_DNS` | `<DNS1>,<DNS2>` | `8.8.8.8,1.1.1.1` | Define os servidores DNS para a conexão Wi-Fi. |
| `--SHARED_IP_ADDRESS` | `<IP/CIDR>` | `192.168.1.1/24` | Define o endereço IP para o compartilhamento de internet. |
| `--DHCP_RANGE` | `<IP_inicial>,<IP_final>` | `192.168.1.10,192.168.1.200` | Define o intervalo de IPs para o DHCP. |
| `--PIHOLE_DNS` | `<IP>` | `192.168.1.1` | Define o DNS para o Pi-hole. |
| `--CLOUDFLARE_TOKEN` | `<token>` | `abcdef1234567890` | Define o token do Cloudflare Tunnel. |
| `--RCLONE_CONFIG` | `<client_id>,<client_secret>` | `"client_id=abcde12345,client_secret=abcde12345"` | Define as credenciais do Rclone. |
| `--TRIGGERCMD_TOKEN` | `"<token>"` | Define o token do TriggerCMD. |
| `--MQTT_BROKER` | `<IP>` | `192.168.1.1` | Define o endereço do broker MQTT. |
| `--MQTT_PORT` | `<porta>` | `1883` | Define a porta do broker MQTT. |
| `--MQTT_USER_DOCKER` | `<usuario>` | `docker_user` | Define o usuário MQTT para o Docker. |
| `--MQTT_USER_RPI` | `<usuario>` | `raspberry_user` | Define o usuário MQTT para o Raspberry Pi. |
| `--MQTT_PASSWORD` | `<senha>` | `psk.mqtt` | Define a senha do MQTT. |
| `--MQTT_TOPIC_DOCKER` | `<topico>` | `home/nodes/docker` | Define o tópico MQTT para o Docker. |
| `--MQTT_TOPIC_RPI` | `<topico>` | `home/nodes/raspberrypi` | Define o tópico MQTT para o Raspberry Pi. |
| `--INTERVAL_SECONDS` | `<segundos>` | `10` | Define o intervalo de monitoramento do MQTT. |
| `--CONTAINERS_PARA_MONITORAR` | `<container1>,<container2>` | `"Home-Assistant,EMQX"` | Define os contêineres para monitoramento MQTT. <br> **Observação:** Cuidado com letras maiúsculas e minúsculas. |


---

### 🚫 Comandos para EXPERT (funções específica)

| Comando | Descrição |
| :--- | :--- |
| `uninstall_triggercmd` | Desinstalar TriggerCMD. |
| `config_zsh` | Instala e Configura o ZSN. |
| `install_docker` | Instala o Docker. |
| `cloudflare_tunnel` | Instala Docker e Cloudflare-Tunnel. |
| `configurar_home_assistant` | Configura HA (HACS, configuration.yaml, etc.) |
| `install_monitor` | Instala e configura o monitoramento do Docker e MQTT. |

---

### 🚼 **Exemplos de Uso:**

**Todas as Variáveis Desativadas:**
```bash
sudo -E bash get.sh \
  --conectar_wifi=n --compartilhar_internet_lan=n --instalar_pi_hole=n \
  --update_system=n --install_basic_zsh=n --install_theme=n --ativar_ssh=n \
  --ativar_vnc=n --habilitar_tft=n --drive=n --alexa_commands=n --docker=n \
  --cloudflare=n --cosmos=n --mine_server=n --reiniciar=n
```

**Configuração de WiFi e Rclone:**
```bash
sudo -E bash get.sh \
  --conectar_wifi=y \
  --WIFI_CONFIGS=""teSt1:123456789:7","test2-5G:abcdef:9"" \
  --WIFI_IP_ADDRESS="192.168.15.20/24" \
  --drive=y \
  --RCLONE_CONFIG="client_id=abcde12345,client_secret=abcde12345"
```

---

## 📬 Contribuições e Suporte

Fique à vontade para abrir issues ou enviar pull requests com melhorias ou correções.

Se este projeto te ajudou, ⭐️ dê uma estrela!

---

> Desenvolvido com 💻, café ☕ e paciência 🧘 por Leonardo Henrique

