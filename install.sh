#!/bin/bash

set -e

if [ ${USER} != "root" ]; then
    >&2 echo "This script must be run as root"
    exit 1
fi

home=$(eval echo ~${SUDO_USER})
shell=$(cat /etc/passwd | grep ${SUDO_USER} | awk -F : '{print $7}')
script_dirpath=$(dirname $(readlink -f ${0}))
files_dirpath=${script_dirpath}/files

# config files
for config_filename in $(ls ${files_dirpath}); do
    src_filepath=${files_dirpath}/${config_filename}
    tgt_filepath=${home}/.${config_filename}
    if [[ ! -f ${tgt_filepath} && ! -L ${tgt_filepath} ]]; then
        ln -s ${src_filepath} ${tgt_filepath}
    else
        if [ -L ${tgt_filepath} ] && readlink -f ${tgt_filepath}; then
            actual_tgt=$(readlink -f ${tgt_filepath})
        fi
        if [[ -z ${actual_tgt} || ${actual_tgt} != ${src_filepath} ]]; then
            while true; do
                read -p "${tgt_filepath} already exists. Do you want to override it? [d/y/N] " override
                if [ -z "${override}" ]; then
                    override=n
                fi
                case ${override} in
                    d)
                        diff --color ${tgt_filepath} ${src_filepath}
                        ;;
                    n)
                        break
                        ;;
                    y)
                        rm ${tgt_filepath}
                        ln -s ${src_filepath} ${tgt_filepath}
                        break
                        ;;
                esac
            done
        fi
    fi
done

# tools
apt update
apt install -y curl direnv vim zsh

# oh my zsh
if [ ${shell} != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh ${SUDO_USER}
fi
if [ ! -d ${home}/.oh-my-zsh ]; then
    git clone ${home}/.oh-my-zsh
fi

# openvpn - update-systemd-resolved
if [[ -d /etc/openvpn && $(sudo systemctl is-active systemd-resolved) == "active" ]]; then
    mkdir -p /etc/openvpn/sh
    curl https://raw.githubusercontent.com/jonathanio/update-systemd-resolved/master/update-systemd-resolved > /etc/openvpn/sh/update-systemd-resolved
    chmod +x /etc/openvpn/sh/update-systemd-resolved
fi

# tfswitch
curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
