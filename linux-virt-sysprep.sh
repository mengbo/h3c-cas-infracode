#!/bin/bash
# Does the equivalent of sysprep for linux boxes to prepare them for cloning.
# Based on https://gist.github.com/AfroThundr3007730/ff5229c5b1f9a018091b14ceac95aa55

say() {
    printf '%s: %s\n' "$(date -u +%FT%TZ)" "$@"
}

clean_packages() {
    say 'Clearing package.'
    if [[ $FEDORA_DERIV == true ]]; then
        /usr/bin/yum clean all -q &> /dev/null
        /bin/rm -rf /var/cache/yum/*
    elif [[ $DEBIAN_DERIV == true ]]; then
        /usr/bin/apt clean &> /dev/null
        /bin/rm -rf /var/cache/apt/archives/*
    fi
    return 0
}

clean_logs() {
    say 'Clearing old logs.'
    /usr/sbin/logrotate -f /etc/logrotate.conf
    /usr/bin/find /var/log -type f -regextype posix-extended -regex \
        ".*/*(-[0-9]{8}|.[0-9]|.gz)$" -delete
    /bin/rm -rf /var/log/journal && /bin/mkdir /var/log/journal
    /bin/rm -f /var/log/dmesg.old
    /bin/rm -f /var/log/anaconda/*

    say 'Clearing audit logs.'
    [ -f "/var/log/audit/audit.log" ] && \
        : > /var/log/audit/audit.log
    : > /var/log/wtmp
    : > /var/log/lastlog
    : > /var/log/grubby
    
    return 0
}

clean_files() {
    say 'Cleaning out temp directories.'
    /bin/rm -rf /tmp/*
    /bin/rm -rf /var/tmp/*
    /bin/rm -rf /var/cache/*

    say 'Cleaning up root home directory.'
    unset HISTFILE
    /bin/rm -f /root/.bash_history
    /bin/rm -f /root/anaconda-ks.cfg
    /bin/rm -rf /root/.ssh/
    /bin/rm -rf /root/.gnupg/

    return 0
}

DEB_SSH_OVERRIDE_CONF=$(cat << EOF
# https://www.cyberciti.biz/faq/howto-regenerate-openssh-host-keys/
[Service]
ExecStartPre=
ExecStartPre=-/usr/bin/ssh-keygen -A
ExecStartPre=/usr/sbin/sshd -t
EOF
)
clean_ssh_keys() {
    say 'Removing SSH host keys.'
    rm -f /etc/ssh/ssh_host_*

    if [[ $DEBIAN_DERIV == true ]]; then
        mkdir -p /etc/systemd/system/ssh.service.d
        echo "$DEB_SSH_OVERRIDE_CONF" > \
            /etc/systemd/system/ssh.service.d/regenerate-ssh-host-keys.conf
    fi

    return 0
}

generalize() {
    say 'Clearing machine-id.'
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id
    ln -s /etc/machine-id /var/lib/dbus/machine-id

    say 'Removing random-seed.'
    /bin/rm -f /var/lib/systemd/random-seed

    return 0
}

sysprep() {
    source /etc/os-release
    if [[ $ID =~ (fedora|rhel|centos|kylin|openEuler) || $ID_LIKE =~ (fedora|rhel|centos) ]]; then
        FEDORA_DERIV=true
    elif [[ $ID =~ (debian|ubuntu|mint) || $ID_LIKE =~ (debian|ubuntu|mint) ]]; then
        DEBIAN_DERIV=true
    else
        say 'An unknown base linux distribution was detected.'
        say 'This script works with Debian and Fedora based distros.'
        exit 1
    fi

    say 'Stopping logging and auditing daemons.'
    /bin/systemctl stop rsyslog.service
    /usr/sbin/service auditd stop

    clean_packages

    clean_logs

    clean_files

    clean_ssh_keys

    generalize

    say 'End of sysprep.'

    exit 0
}

# Only execute if not being sourced
[[ ${BASH_SOURCE[0]} == "$0" ]] && sysprep "$@"
