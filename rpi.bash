# -*- mode:shell-script;coding:utf-8 -*-
# sudo apt-get install xclip keychain aptitude autocutsel
# put in ~/.bashrc
# source /home/pi/rpi-configs/rpi.bash

export HISTIGNORE="pwd:ls:cd"
shopt -s histappend
PROMPT_COMMAND="$PROMPT_COMMAND;history -a; history -n"
# Have lots of history
HISTSIZE=100000         # remember the last 100000 commands
HISTFILESIZE=100000     # start truncating commands after 100000 lines
HISTCONTROL=ignoreboth  # ignoreboth is shorthand for ignorespace and     ignoredups

xset b off
xset b 0 0 0

alias reboute="sudo reboot -dfi"
halte() {
    for device in /media/vrx/*
    do umount $device;
    done;
    sudo shutdown -h now
}

# install
alias fs='aptitude search'
alias fi='sudo aptitude install'
alias fri='sudo aptitude reinstall'
alias fu='sudo aptitude update'
alias fr='sudo aptitude remove'


alias cd='cd -P'
alias clear="clear && printf '\e[3J'" # also clear scrollback !!
alias mdp8="pwgen -1 8"
alias mdp12="pwgen -1 12"


alias ll='ls -alh'
alias e='emacs -nw -q '
alias em='emacs -nw  '
alias se='sudo emacs -nw -q '
alias sem='sudo emacs -nw  '

alias kk='sudo kill -9 '
alias black="/usr/bin/fbsetroot -solid black"
alias rezjack='rezound --audio-method=jack'

# LISP
export PATH=$PATH:$HOME/.roswell/bin
alias repl='cl-repl'

# EXPORTS
export EDITOR='emacs -nw -rv -q '
export PATH=$PATH:$HOME/.local/bin

# -i : case insensitive !
ch () {
		ack -i -Q "$1" $ackignore
}

# replace with ack-perl
rp () {
		ack -l "$1" $ackignore | xargs perl -pi -E "s/$1/$2/g"
}

ff () {
    find ./ -iname "*$1*"
}


f () {
		ps -xo pid,ppid,stat,command |grep "$1"
}

# kill
k () {
    # sudo ps ax | grep "$1" | awk '{print $1}' | xargs -i kill -9 {} 2&>/dev/null
		ps -ef |grep "$1" |grep -v grep |awk '{print $2}' |xargs kill -9
    # sudo ps ax | grep "$1" | awk '{print $1}' | xargs  kill -9 $1
}
alias ccd="cd -P "

# TERMINAL
export PS1="\[\e[31m\][\[\e[m\]\[\e[38;5;172m\]\u\[\e[m\]@\[\e[38;5;153m\]\h\[\e[m\] \[\e[38;5;214m\]\W\[\e[m\]\[\e[31m\]]\[\e[m\]\\$ "
export PROMPT_COMMAND='echo -ne "\033]0;${PWD}\007"'

echo "rpi start dbus"
eval `dbus-launch --auto-syntax`
export DBUS_SESSION_BUS_PID DBUS_SESSION_BUS_ADDRESS
echo "rpi finished dbus"
