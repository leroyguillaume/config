#!/bin/bash

set -e

if [ ${USER} != "root" ]; then
    >&2 echo "This script must be run as root"
    exit 1
fi

home=$(eval echo ~${SUDO_USER})
script_dir=$(dirname $(readlink -f ${0}))
src_files=(gitconfig zshrc vimrc)
tgt_files=(${home}/.gitconfig ${home}/.zshrc ${home}/.vimrc)

for i in ${!src_files[@]}; do
    src_file=${src_files[$i]}
    tgt_file=${tgt_files[$i]}
    if [ ! -L ${tgt_file} ]; then
        if [ ! -f ${tgt_file} ]; then
            ln -s ${script_dir}/${src_file} ${tgt_file}
        else
            while true; do
                read -p "${tgt_file} already exists. Do you want to override it? [d/y/N] " override
                if [ -z "${override}" ]; then
                    override=n
                fi
                case ${override} in
                    d)
                        diff --color ${tgt_file} ${src_file}
                        ;;
                    n)
                        break
                        ;;
                    y)
                        rm ${tgt_file}
                        ln -s ${script_dir}/${src_file} ${tgt_file}
                        break
                        ;;
                esac
            done
        fi
    fi
done

apt update
apt install -y curl vim zsh

if [[ -d /etc/openvpn && $(sudo systemctl is-active systemd-resolved) == "active" ]]; then
    mkdir -p /etc/openvpn/sh
    curl https://raw.githubusercontent.com/jonathanio/update-systemd-resolved/master/update-systemd-resolved > /etc/openvpn/sh/update-systemd-resolved
    chmod +x /etc/openvpn/sh/update-systemd-resolved
fi
