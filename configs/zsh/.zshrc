# -----------------------------------------------
# Environment Variables
# -----------------------------------------------
export PATH="${PATH}:${HOME}/bin:"
export ZSH=${HOME}/.oh-my-zsh
export TERM='xterm-256color'

# -----------------------------------------------
# Oh My ZSH Configuration
# -----------------------------------------------
ZSH_THEME='spaceship'
plugins=(git)
source $ZSH/oh-my-zsh.sh

# -----------------------------------------------
# Aliases
# -----------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls='grc --colour=auto ls --color=always'
alias lk="ls -lah *"
alias ll="ls -lh $@"
alias l="ls -lah $@"
alias cp="cp -av"
alias mv="mv -vf"
alias mkdir="/bin/mkdir -pv"
alias sudo='sudo '

alias ports="netstat -pantul"
alias ipconfig="ifconfig $@"
alias gipv4="grep -oE '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'"
alias sipv4="sort -n -u -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4"
alias getips="gipv4 | sipv4"
alias show_all_colors='for code in {000..255};do print -P -- "$code: %F{$code}This is how your text would look like%f";done'

alias axel="axel -a"
alias header="curl -l"

alias sha1="openssl sha1"
alias md5="openssl md5"

alias rand512="dd if=/dev/urandom bs=64k count=1 2>/dev/null | sha512sum - | cut -d' ' -f 1"
alias rand256="dd if=/dev/urandom bs=64k count=1 2>/dev/null | sha256sum - | cut -d' ' -f 1"
alias rand64="dd if=/dev/urandom bs=64 count=1 2>/dev/null | base64 -w 96"
alias rand32="dd if=/dev/urandom bs=64k count=1 2>/dev/null | md5sum - | cut -c 1-8"
alias randmd5="dd if=/dev/urandom bs=64 count=1 2>/dev/null | md5sum - | cut -d' ' -f 1"

alias nmapp="nmap --reason --open --stats-every 3m --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit"
alias wgetasie7='wget -U "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 6.0; en-US)"'
alias wgetasie8='wget -U "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; .NET CLR 3.5.30729)"'
# -----------------------------------------------
# Functions
# -----------------------------------------------
ipx() {
    if [ -z $1 ]; then
        curl "ipinfo.io"
    else
        curl "ipinfo.io/${@}"
    fi
}
get_external_ip() {
    echo -en "Method 0\tipinfo.io\t";curl -s http://ipinfo.io/ip
    echo -en "Method 1\tdns lookup\t";dig +short @resolver1.opendns.com myip.opendns.com
    echo -en "Method 2\tdns lookup\t";dig +short @208.67.222.222 myip.opendns.com
}
crt_subdomains() { curl -s https://crt.sh\?q\=%25.$1 | awk -v pattern="<TD>.*$1" '$0 ~ pattern {gsub("<[^>]*>","");gsub(//,""); print}' | sort -u }
crt_certs() { curl -s https://crt.sh\?q\=%25.$1 | awk '/\?id=[0-9]*/{nr[NR]; nr[NR+1]; nr[NR+3]; nr[NR+4]}; NR in nr' | sed 's/<TD style="text-align:center"><A href="?id=//g' | sed 's#">[0-9]*</A></TD>##g' | sed 's#<TD style="text-align:center">##g' | sed 's#</TD>##g' | sed 's#<TD>##g' | sed 's#<A style=["a-z: ?=0-9-]*>##g' | sed 's#</A>##g' | sed 'N;N;N;s/\n/\t\t/g' }
crt_toCSV() {
    echo 'ID,Logged At,Identity,Issuer Name' > $1.csv
    curl -s https://crt.sh\?q\=%25.$1 | awk '/\?id=[0-9]*/{nr[NR]; nr[NR+1]; nr[NR+3]; nr[NR+4]}; NR in nr' | sed 's/<TD style="text-align:center"><A href="?id=//g' | sed 's#">[0-9]*</A></TD>##g' | sed 's#<TD style="text-align:center">##g' | sed 's#</TD>##g' | sed 's#<TD>##g' | sed 's#<A style=["a-z: ?=0-9-]*>##g' | sed 's#</A>##g' | sed 's/,/;/g' | sed 'N;N;N;s/\n/,/g' | sed 's/,[ ]*/,/g' | sed 's/^[ ]*//g' >> $1.csv
}
checksums() { echo -n "md5: ";md5sum "${@}";echo -n "sha1: ";sha1sum "${@}";echo -n "sha256: ";sha256sum "${@}";echo -n "sha512: ";sha512sum "${@}"; }
mount_vmshare() { vmhgfs-fuse .host:/ /mnt/host }
# -----------------------------------------------
# Sourcing
# -----------------------------------------------
[[ -s "/etc/grc.zsh" ]] && source /etc/grc.zsh