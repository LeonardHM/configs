# Se você veio do Bash, pode ser necessário ajustar seu PATH manualmente.
# Isso permite que scripts em ~/bin e /usr/local/bin sejam executados sem precisar digitar o caminho completo.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Se ao colar URLs ou outros textos no terminal a formatação estiver errada, ative esta opção.
# DISABLE_MAGIC_FUNCTIONS="true"

# Definir manualmente o idioma do sistema. Útil se houver problemas com acentuação ou caracteres especiais.
# export LANG=en_US.UTF-8

# Defina atalhos personalizados para comandos, substituindo os fornecidos pelo Oh-My-Zsh.
# É recomendado armazená-los na pasta ZSH_CUSTOM.
# Para ver todos os atalhos ativos, use o comando `alias`.
#
# Exemplo de atalhos:
# alias zshconfig="mate ~/.zshrc"  # Abre o arquivo de configuração do Zsh no editor mate
# alias ohmyzsh="mate ~/.oh-my-zsh"  # Abre a pasta do Oh-My-Zsh no editor mate

# Restaura o cursor para sua aparência normal após a execução de comandos.
# tput cnorm

# Tema do terminal (descomente e defina um tema se quiser alterar)
# ZSH_THEME="agnoster"

# Ativar correção automática de comandos (descomente para ativar)
# ENABLE_CORRECTION="true"

# Tornar a conclusão de comandos sensível a maiúsculas e minúsculas
# CASE_SENSITIVE="true"

# Permitir que traços (-) e underscores (_) sejam equivalentes na conclusão
# HYPHEN_INSENSITIVE="true"

# Desativar título automático do terminal
# DISABLE_AUTO_TITLE="true"

# Ativar exibição de pontos vermelhos enquanto aguarda a conclusão
# COMPLETION_WAITING_DOTS="true"

# Desativar verificação de arquivos não rastreados em repositórios Git
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Configurar formato da data no histórico de comandos
# HIST_STAMPS="yyyy-mm-dd"



# Caminho da instalacao do oh-my-zsh
export ZSH=$HOME/clone/configs/.oh-my-zsh

# Plugins ativados
plugins=(git
zsh-autosuggestions
zsh-syntax-highlighting)

# Carrega o oh-my-zsh
source $HOME/clone/configs/.oh-my-zsh/oh-my-zsh.sh

# Banner do terminal
bash $HOME/clone/configs/alien
figlet -f $HOME/clone/configs/Sub-Zero "Leozin" | lolcat;
echo

# Configuração do cursor
printf '\e[2 q'

# Configuração do prompt
setopt prompt_subst

PROMPT=$'
\e[0;31m%}┌─[%{\e[1;34m%}%B%{$USER%}%{\e[1;33m%}@%{\e[1;36m%}$(hostname)%b%{\e[0;31m%}]─[%{\e[0;32m%}%(4~|/%2~|%~)%{\e[0;31m%}]%b
%{\e[0;31m%}└──╼ %{\e[1;31m%}%B❯%{\e[1;34m%}❯%{\e[1;90m%}❯%{\e[0m%}%b '

#===========# TERMUX #===========# 
# Check fingerprint
#termux-fingerprint |  grep "AUTH_RESULT_FAILURE" | while read line ; do echo "$line" | exit ; done

