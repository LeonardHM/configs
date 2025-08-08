configurar_home_assistant() {
    print_log "$(log_aviso)" "$(echo_red "INICIANDO A CONFIGURAÇÃO DO HOME ASSISTANT...")"

    CONTAINER_NAME="Home-Assistant"

    {
        # 1. Instalar HACS (Home Assistant Community Store)
        if ! docker exec -it "$CONTAINER_NAME" bash -c "[ -d \"/config/custom_components/hacs\" ]" &> /dev/null; then
            docker exec -it "$CONTAINER_NAME" bash -c "wget -O - https://get.hacs.xyz | bash -" || {
                print_log "$(log_error)" "$(echo_red "ERRO: Falha na instalação do HACS.")"
                exit 1
            }
        fi

        # 2. Instalar TvTime
        if [ ! -d "$HA_CC_PATH/TvTime" ]; then
            cd /tmp || { print_log "$(log_error)" "$(echo_red "ERRO: Falha ao mudar para o diretório /tmp.")" && exit 1; }
            git clone https://github.com/Ghau/TvTime.git tvtime_temp >/dev/null 2>&1 || {
                print_log "$(log_error)" "$(echo_red "ERRO: Falha ao clonar o repositório TvTime.")"
                exit 1
            }
            sudo rm -rf "$HA_CC_PATH/TvTime"
            sudo cp -r tvtime_temp/custom_components/TvTime "$HA_CC_PATH/" || {
                print_log "$(log_error)" "$(echo_red "ERRO: Falha ao copiar os arquivos do TvTime.")"
                exit 1
            }
            sudo rm -rf tvtime_temp
        fi

        # 3. Configurar configuration.yaml
        if ! grep -q "yahoofinance:" "$HA_CONFIG_PATH/configuration.yaml" 2>/dev/null; then
            sudo bash -c "cat << 'EOF' >> \"$HA_CONFIG_PATH/configuration.yaml\"
$(cat << 'CONFIG_BLOCK'

default_config:

http:
  use_x_forwarded_for: True
  trusted_proxies:
    - !env_var PROXY_HOSTNAME

frontend:
  themes: !include_dir_merge_named themes

lovelace:
  mode: yaml

yahoofinance:
  scan_interval:
    minutes: 5
  decimal_places: 2
  symbols:
    - BTC-USD
    - symbol: BTC-EUR
      target_currency: BRL
    - symbol: USDBRL=X
    - ETH-USD
    - symbol: ETH-EUR
      target_currency: BRL

# --- INPUT_BOOLEANS ---
input_boolean:
  tv_status_home_assistant:
    name: Estado da TV
    initial: off
    icon: mdi:television

  computer_status_home_assistant:
    name: Status Computador Sala
    initial: off
    icon: mdi:monitor

# --- INPUT_SELECTS ---
input_select:
  tv_hdmi_input:
    name: Entrada HDMI TV Sala
    options:
      - "01"
      - "02"
    initial: "02"
    icon: mdi:hdmi-port

# --- SCRIPTS ---
script:
  tv_toggle_action:
    alias: Controlar Ligacao e Desligacao da TV
    sequence:
      - service: input_boolean.toggle
        target:
          entity_id: input_boolean.tv_status_home_assistant
      - delay: 0.1
      - choose:
          - conditions:
              - condition: state
                entity_id: input_boolean.tv_status_home_assistant
                state: 'on'
            sequence:
              - service: button.press
                target:
                  entity_id: button.rpi_raspberrypi_ligar_tv
          - conditions:
              - condition: state
                entity_id: input_boolean.tv_status_home_assistant
                state: 'off'
            sequence:
              - service: button.press
                target:
                  entity_id: button.rpi_raspberrypi_desligar_tv

  computer_toggle_action:
    alias: Controlar Ligacao e Desligacao do Computador
    sequence:
      - service: input_boolean.toggle
        target:
          entity_id: input_boolean.computer_status_home_assistant
      - delay: 0.1
      - choose:
          - conditions:
              - condition: state
                entity_id: input_boolean.computer_status_home_assistant
                state: 'on'
            sequence:
              - service: button.press
                target:
                  entity_id: button.rpi_raspberrypi_ligar_computador
          - conditions:
              - condition: state
                entity_id: input_boolean.computer_status_home_assistant
                state: 'off'
            sequence:
              - service: button.press
                target:
                  entity_id: button.rpi_raspberrypi_desligar_computador

# --- AUTOMATIONS ---
automation:
  - alias: "Controlar Entrada HDMI da TV"
    trigger:
      - platform: state
        entity_id: input_select.tv_hdmi_input
    action:
      - choose:
          - conditions:
              - condition: state
                entity_id: input_select.tv_hdmi_input
                state: '01'
            sequence:
              - service: button.press
                target:
                  entity_id: button.rpi_raspberrypi_hdmi_1
          - conditions:
              - condition: state
                entity_id: input_select.tv_hdmi_input
                state: '02'
            sequence:
              - service: button.press
                target:
                  entity_id: button.rpi_raspberrypi_hdmi_2

  - id: 'turn_on_tv_with_computer'
    alias: 'Ligar Estado da TV ao Ligar Computador'
    description: 'Muda o input_boolean da TV para ON quando o computador é ligado.'
    trigger:
      - platform: state
        entity_id: input_boolean.computer_status_home_assistant
        to: 'on'
    condition: []
    action:
      - service: input_boolean.turn_on
        target:
          entity_id: input_boolean.tv_status_home_assistant
    mode: single

  - id: 'sync_tv_state_with_computer'
    alias: 'Sincronizar Estado da TV com Computador'
    description: 'Sincroniza o estado do input_boolean da TV com o estado do computador (visual).'
    trigger:
      - platform: state
        entity_id: input_boolean.computer_status_home_assistant
    condition: []
    action:
      - choose:
          - conditions:
              - condition: state
                entity_id: input_boolean.computer_status_home_assistant
                state: 'on'
            sequence:
              - service: input_boolean.turn_on
                target:
                  entity_id: input_boolean.tv_status_home_assistant
          - conditions:
              - condition: state
                entity_id: input_boolean.computer_status_home_assistant
                state: 'off'
            sequence:
              - service: input_boolean.turn_off
                target:
                  entity_id: input_boolean.tv_status_home_assistant
        default: []
    mode: single

template:
  - sensor:
      - name: "RPI RAM Uso Porcentagem"
        unique_id: rpi_ram_use_prcnt
        unit_of_measurement: "%"
        state: "{{ state_attr('sensor.rpi_raspberrypi_monitor', 'mem_used_prcnt') }}"
        state_class: measurement

      - name: "RPI CPU Temperatura"
        unique_id: rpi_cpu_temp_c
        unit_of_measurement: "°C"
        state: "{{ state_attr('sensor.rpi_raspberrypi_monitor', 'temp_cpu_c') }}"
        device_class: temperature
        state_class: measurement

      - name: "RPI GPU Temperatura"
        unique_id: rpi_gpu_temp_c
        unit_of_measurement: "°C"
        state: "{{ state_attr('sensor.rpi_raspberrypi_monitor', 'temp_gpu_c') }}"
        device_class: temperature
        state_class: measurement

      - name: "RPI Disco Livre GB"
        unique_id: rpi_disk_free_gb
        unit_of_measurement: "GB"
        availability: >
          {{ state_attr('sensor.rpi_raspberrypi_monitor', 'fs_total_gb') is not none and
             state_attr('sensor.rpi_raspberrypi_monitor', 'fs_free_prcnt') is not none }}
        state: >
          {% set total_gb = state_attr('sensor.rpi_raspberrypi_monitor', 'fs_total_gb') | float(0) %}
          {% set free_prcnt = state_attr('sensor.rpi_raspberrypi_monitor', 'fs_free_prcnt') | float(0) %}
          {{ (total_gb * (free_prcnt / 100)) | round(2) }}
        device_class: data_size
        state_class: measurement

      - name: "RPI Disco Total GB"
        unique_id: rpi_disk_total_gb
        unit_of_measurement: "GB"
        state: "{{ state_attr('sensor.rpi_raspberrypi_monitor', 'fs_total_gb') | float(0) }}"
        device_class: data_size
        state_class: measurement

      - name: "RPI Disco Usado Porcentagem"
        unique_id: rpi_disk_used_prcnt
        unit_of_measurement: "%"
        state: "{{ state_attr('sensor.rpi_raspberrypi_monitor', 'fs_used_prcnt') | float(0) }}"
        device_class: percentage
        state_class: measurement

mqtt:
  sensor:
    # --- Uso de Disco do Docker ---
    - unique_id: docker_total_disk_usage
      name: "Docker Total Disk Usage"
      state_topic: "home/nodes/docker/disk/total_usage"
      unit_of_measurement: "GB"
      value_template: "{{ value | regex_replace(find='GB', replace='') | float(0) }}"
      device_class: "data_size"
      state_class: measurement
      suggested_display_precision: 2
      icon: mdi:harddisk-full

    - unique_id: docker_disk_images_used
      name: "Docker Disk Images Used"
      state_topic: "home/nodes/docker/disk/images_used"
      unit_of_measurement: "GB"
      value_template: "{{ value | replace('GB', '') | float(0) }}"
      device_class: "data_size"
      state_class: measurement
      suggested_display_precision: 2
      icon: mdi:image-multiple-outline

    - unique_id: docker_images_count
      name: "Docker Images Count"
      state_topic: "home/nodes/docker/disk/images_count"
      unit_of_measurement: "imagens"
      value_template: "{{ value | int(0) }}"
      icon: mdi:numeric
      state_class: measurement
      suggested_display_precision: 0

    - unique_id: docker_disk_containers_used
      name: "Docker Disk Containers Used"
      state_topic: "home/nodes/docker/disk/containers_used"
      unit_of_measurement: "GB"
      value_template: "{{ value | replace('GB', '') | float(0) }}"
      device_class: "data_size"
      state_class: measurement
      suggested_display_precision: 2
      icon: mdi:box-cutter

    - unique_id: docker_containers_count
      name: "Docker Containers Count"
      state_topic: "home/nodes/docker/disk/containers_count"
      unit_of_measurement: "contêineres"
      value_template: "{{ value | int(0) }}"
      icon: mdi:numeric-box-multiple-outline
      state_class: measurement
      suggested_display_precision: 0

    - unique_id: docker_disk_volumes_used
      name: "Docker Disk Volumes Used"
      state_topic: "home/nodes/docker/disk/volumes_used"
      unit_of_measurement: "GB"
      value_template: "{{ value | replace('GB', '') | float(0) }}"
      device_class: "data_size"
      state_class: measurement
      suggested_display_precision: 2
      icon: mdi:database

    - unique_id: docker_volumes_count
      name: "Docker Volumes Count"
      state_topic: "home/nodes/docker/disk/volumes_count"
      unit_of_measurement: "volumes"
      value_template: "{{ value | int(0) }}"
      icon: mdi:numeric-positive-1
      state_class: measurement
      suggested_display_precision: 0

    # --- Status e Uso de CPU dos Contêineres ---
    # Home Assistant
    - name: "Home Assistant Status"
      state_topic: "home/nodes/docker/status/Home-Assistant"
      icon: mdi:home-assistant
      unique_id: home_assistant_status

    - name: "Home Assistant CPU Usage"
      state_topic: "home/nodes/docker/container/Home-Assistant/cpu_usage"
      unit_of_measurement: "%"
      value_template: "{{ value | replace('%', '') | float(0) }}"
      icon: mdi:cpu-64-bit
      unique_id: home_assistant_cpu_usage

    # Doku
    - name: "Doku Status"
      state_topic: "home/nodes/docker/status/Doku"
      icon: mdi:book-open-page-variant
      unique_id: doku_status
    - name: "Doku CPU Usage"
      state_topic: "home/nodes/docker/container/Doku/cpu_usage"
      unit_of_measurement: "%"
      value_template: "{{ value | replace('%', '') | float(0) }}"
      icon: mdi:cpu-64-bit
      unique_id: doku_cpu_usage

    # EMQX
    - name: "EMQX Status"
      state_topic: "home/nodes/docker/status/EMQX"
      icon: mdi:broker-mqtt
      unique_id: emqx_status
    - name: "EMQX CPU Usage"
      state_topic: "home/nodes/docker/container/EMQX/cpu_usage"
      unit_of_measurement: "%"
      value_template: "{{ value | replace('%', '') | float(0) }}"
      icon: mdi:cpu-64-bit
      unique_id: emqx_cpu_usage

    # IT-Tools
    - name: "IT-Tools Status"
      state_topic: "home/nodes/docker/status/IT-Tools"
      icon: mdi:tools
      unique_id: it_tools_status
    - name: "IT-Tools CPU Usage"
      state_topic: "home/nodes/docker/container/IT-Tools/cpu_usage"
      unit_of_measurement: "%"
      value_template: "{{ value | replace('%', '') | float(0) }}"
      icon: mdi:cpu-64-bit
      unique_id: it_tools_cpu_usage

    # Openspeedtest
    - name: "Openspeedtest Status"
      state_topic: "home/nodes/docker/status/Openspeedtest"
      icon: mdi:speedometer
      unique_id: openspeedtest_status
    - name: "Openspeedtest CPU Usage"
      state_topic: "home/nodes/docker/container/Openspeedtest/cpu_usage"
      unit_of_measurement: "%"
      value_template: "{{ value | replace('%', '') | float(0) }}"
      icon: mdi:cpu-64-bit
      unique_id: openspeedtest_cpu_usage

    # Immich
    - name: "Immich Status"
      state_topic: "home/nodes/docker/status/Immich"
      icon: mdi:image-multiple
      unique_id: immich_status
    - name: "Immich CPU Usage"
      state_topic: "home/nodes/docker/container/Immich/cpu_usage"
      unit_of_measurement: "%"
      value_template: "{{ value | replace('%', '') | float(0) }}"
      icon: mdi:cpu-64-bit
      unique_id: immich_cpu_usage

   # Cloudflared
    - name: "Cloudflared Status"
      state_topic: "home/nodes/docker/status/Cloudflared"
      icon: mdi:cloud-flare
      unique_id: cloudflared_status
    - name: "Cloudflared CPU Usage"
      state_topic: "home/nodes/docker/container/Cloudflared/cpu_usage"
      unit_of_measurement: "%"
      value_template: "{{ value | replace('%', '') | float(0) }}"
      icon: mdi:cpu-64-bit
      unique_id: cloudflared_cpu_usage

CONFIG_BLOCK
)
EOF" || {
                print_log "$(log_error)" "$(echo_red "ERRO: Falha ao adicionar configurações ao configuration.yaml.")"
                exit 1
            }
        else
            print_log "$(log_info)" "$(echo_yellow "Configurações do configuration.yaml já estão no arquivo. Pulando.")"
        fi

        # 4. Reiniciar o contêiner Home Assistant
        print_log "$(log_info)" "$(echo_orange "Reiniciando o contêiner Home Assistant...")"
        docker restart "$CONTAINER_NAME" >/dev/null 2>&1 || {
            print_log "$(log_error)" "$(echo_red "ERRO: Falha ao reiniciar o contêiner Home Assistant.")"
            exit 1
        }

    } &

    local pid=$!
    if show_progress "CONFIGURANDO HOME ASSISTANT..." $pid; then
        print_log "$(log_success)" "$(echo_green "HOME ASSISTANT CONFIGURADO COM SUCESSO!")"
    else
        print_log "$(log_error)" "$(echo_red "A configuração do Home Assistant falhou em uma das etapas.")"
        return 1
    fi
}
