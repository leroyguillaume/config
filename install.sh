#!/bin/bash

script_dir=$(dirname $(readlink -f ${0}))
src_files=(gitconfig zshrc vimrc)
tgt_files=(~/.gitconfig ~/.zshrc ~/.vimrc)

for i in ${!src_files[@]}; do
    src_file=${src_files[$i]}
    tgt_file=${tgt_files[$i]}
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
done
