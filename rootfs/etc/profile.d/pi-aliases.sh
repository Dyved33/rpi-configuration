# Handy aliases for interactive login shells (SSH sessions)
case "$-" in *i*) ;; *) return 0 ;; esac
alias ll='ls -lah --color=auto'
alias update='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'
alias temp='vcgencmd measure_temp'
alias myip='ip -4 -br addr'
alias ports='sudo ss -tulpn'
alias logs='journalctl -xe --no-pager | tail -n 100'
alias status='pi-status'
