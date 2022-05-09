#!/bin/bash

function run {
    ${@} >> ${log_file} 2>&1
    exit_status=${?}
    if [ ${exit_status} -ne 0 ]; then
        echo "${@} exited with status ${exit_status}. See ${log_file} for details."
        exit 2
    fi
}

if [ ${USER} != "root" ]; then
    >&2 echo "This script must be run as root"
    exit 1
fi

log_file=/tmp/install-$(date '+%H%M%S').log

home=$(eval echo ~${SUDO_USER})
shell=$(cat /etc/passwd | grep ${SUDO_USER} | awk -F : '{print $7}')
script_dirpath=$(dirname $(readlink -f ${0}))
files_dirpath=${script_dirpath}/files

packages=(curl direnv htop vim zsh)

tf_docs_version=0.16.0

# config files
for config_filename in $(ls ${files_dirpath}); do
    src_filepath=${files_dirpath}/${config_filename}
    tgt_filepath=${home}/.${config_filename}
    if [[ ! -f ${tgt_filepath} && ! -L ${tgt_filepath} ]]; then
        ln -s ${src_filepath} ${tgt_filepath}
    else
        if [ -L ${tgt_filepath} ] && readlink -f ${tgt_filepath} > /dev/null; then
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
echo -n "Updating apt cache... "
run apt update
echo "✓"
echo -n "Installing ${packages[@]}... "
run apt install -y ${packages}
echo "✓"

# oh my zsh
if [ ${shell} != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh ${SUDO_USER}
    echo "Shell changed to zsh"
fi
if [ ! -d ${home}/.oh-my-zsh ]; then
    echo -n "Cloning oh-my-zsh... "
    run git clone ${home}/.oh-my-zsh
    echo "✓"
fi

# openvpn - update-systemd-resolved
if [[ -d /etc/openvpn && $(sudo systemctl is-active systemd-resolved) == "active" ]]; then
    echo -n "Installing update-systemd-resolved... "
    mkdir -p /etc/openvpn/sh
    curl https://raw.githubusercontent.com/jonathanio/update-systemd-resolved/master/update-systemd-resolved > /etc/openvpn/sh/update-systemd-resolved 2>> ${log_file}
    chmod +x /etc/openvpn/sh/update-systemd-resolved
    echo "✓"
fi

# tfswitch
echo -n "Installing terraform-switcher... "
curl -fL https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh 2>> ${log_file} | bash >> ${log_file} 2>&1
echo "✓"

# terraform-docs
echo -n "Installing terraform-docs v${tf_docs_version}... "
curl -fLo /tmp/terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v${tf_docs_version}/terraform-docs-v${tf_docs_version}-$(uname)-amd64.tar.gz 2>> ${log_file}
tar xf /tmp/terraform-docs.tar.gz -C /tmp
chmod +x /tmp/terraform-docs
mv /tmp/terraform-docs /usr/local/bin
echo "✓"
