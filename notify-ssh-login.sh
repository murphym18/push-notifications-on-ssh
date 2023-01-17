#!/usr/bin/env bash

read_ssh_logs() {
    journalctl -u ssh.service -n 2 -o json | head -n 1 | jq -r '"\(.SYSLOG_TIMESTAMP) \(.MESSAGE)"'
}
export HOME="/root"
if [ "$PAM_TYPE" != "close_session" ]; then
    /root/bin/ntf send --title "NEW ssh login $(whoami)@$(hostname)" --pushover.priority normal "$(read_ssh_logs)"
fi

