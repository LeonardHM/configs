# ~/.bashrc: executed by bash(1) for non-login shells.
# Veja exemplos em /usr/share/doc/bash/examples/startup-files (no pacote bash-doc)

# Se não estiver rodando de forma interativa, não faça nada
# [[ $- != *i* ]] && return
case $- in
    *i*) ;; # Se o shell for interativo, continue
      *) return;; # Caso contrário, saia
esac

# Configuração do comportamento do histórico
HISTCONTROL=ignoreboth # Evita históricos duplicados e entradas iniciadas com espaço
shopt -s histappend # Adiciona ao histórico existente em vez de sobrescrevê-lo
HISTSIZE=4096 # Define o número de comandos armazenados no histórico em memória
HISTFILESIZE=16384 # Define o número máximo de comandos armazenados no histórico em disco

# Verifica o tamanho da janela após cada comando
shopt -s checkwinsize

# Habilita recursos avançados do shell
shopt -s globstar # Expande ** para corresponder a todos os arquivos em subdiretórios
shopt -s cmdhist # Armazena comandos multilinhas como uma única entrada no histórico
shopt -s histverify # Permite editar comandos do histórico antes de executá-los

# Define o arquivo de histórico com base no tipo de usuário
if [ "$(id -u)" = "0" ]; then # Verifica se o usuário é root
    export HISTFILE="$HOME/.bash_root_history"
else
    export HISTFILE="$HOME/.bash_history"
fi

# Define o estilo do cursor
printf '\e[4 q'

# Personalização do prompt
NAME=$(whoami) # Obtém o nome do usuário atual
PROMPT_DIRTRIM=2 # Limita a exibição do caminho atual a 2 diretórios
if [ "$(id -u)" = "0" ]; then # Prompt para root
    PS1="\[\e[0;31m\]\w\[\e[0m\] \\[\e[0;97m\]\$\[\e[0m\] "
else # Prompt para usuários comuns
    PS1="
\[\033[0;31m\]┌─[\[\033[1;34m\]$NAME\[\033[1;33m\]@\[\033[1;36m\]termux\[\033[0;31m\]]─[\[\033[0;32m\]\w\[\033[0;31m\]]
\[\033[0;31m\]└──╼ \\[\e[1;31m\]❯\[\e[1;34m\]❯\[\e[1;90m\]❯\[\033[0m\] "
fi
PS2='> ' # Prompt secundário
PS3='> ' # Prompt para seleções interativas
PS4='+ ' # Prompt de depuração

# Título do terminal para terminais do tipo xterm
case "$TERM" in
    xterm*|rxvt*)
        if [ "$(id -u)" = "0" ]; then
            PS1="\[\e]0;termux (root): \w\a\]$PS1"
        else
            PS1="\[\e]0;termux: \w\a\]$PS1"
        fi
        ;;
    *) ;;
    # Não altera o título para outros tipos de terminal
esac

# Saída colorida e aliases para 'ls' e 'grep'
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
fi
alias grep='grep --color=auto' # Realça correspondências em grep
alias egrep='egrep --color=auto' # Realça correspondências em egrep
alias fgrep='fgrep --color=auto' # Realça correspondências em fgrep
alias ls='ls --color=auto' # Ativa cores para ls
alias ll='ls -alF' # Lista arquivos detalhadamente
alias la='ls -A' # Lista todos os arquivos, exceto os ocultos padrão
alias l='ls -CF' # Lista arquivos em colunas

# Ferramentas alternativas para 'ls' e 'cat'
if command -v exa >/dev/null 2>&1; then # Verifica se 'exa' está instalado
    alias ls='exa'
    alias ll='exa -l'
    alias la='exa -a'
    alias l='exa -F'
fi
if command -v bat >/dev/null 2>&1; then # Verifica se 'bat' está instalado
    alias cat='bat --style=plain'
fi

# Aliases de segurança
alias cp='cp -i' # Solicita confirmação antes de sobrescrever
alias mv='mv -i' # Solicita confirmação antes de mover
alias rm='rm -i' # Solicita confirmação antes de remover
alias ln='ln -i' # Solicita confirmação antes de criar links simbólicos

# Carrega aliases personalizados, se disponíveis
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Habilita conclusão programável
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


exec zsh # Inicia o shell zsh como padrão

