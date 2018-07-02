#!/bin/bash

function parse_args(){
    while [[ ! ${#} -eq 0 ]]; do
        case ${1} in
            -h | -? | --help)
                help_output
                exit 0
        esac
    done
}

function help_output(){
    echo "Usage: "
    echo "[!] su -s /system/bin/sh" 
    echo "sh $0"
}

function make_filesystem (){
    # TODO: Finish this up, I forget why this doesn't work but it doesn't work as expected (Or is unfinished)
    filename="archlinuxarm-aarch64-latest.tar.gz"
    cd /data/local
    mkdir arch
    cd arch
    if [[ ! -f $filename ]]; then wget http://os.archlinuxarm.org/os/$filename ; fi
    echo "[+] unpacking"
    tar xzf arch*.tar.gz
    rm arch*.tar.gz
    echo "[+] building fs"
    mount -o bind /dev dev
    mount -t proc proc proc
    mount -t sysfs sysfs sys
    ln -s /proc/self/fd dev/fd
}

function Main(){
    parse_args ${@}
    make_filesystem    
}

Main ${@}

