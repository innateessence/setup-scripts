#!/bin/bash

function runtime_check(){
	if [[ $(whoami) != "root" ]]; then
		echo "[-] Error: Must run this script as root   :("
		exit 1
	fi
}

function init_vars(){
	devices=($(sudo fdisk -l | grep -Eo 'sd[a-zA-Z]' | sort -u | tr '\n' ' '))
	disk=${devices[-1]}
	wipe=1 # True
	quiet=0 # False
	no_confirm=0 # False
}

function parse_args(){
while [ ${#} != 0 ]; do
	case "${1}" in
		-h | --help)
			echo "Help text"
			exit 0;;
		--no-confirm)
			no_confirm=1 # int as bool
			shift;;
		--no-wipe)
			wipe=0
			shift;;
		-d | --disk)
			disk=${2}
			shift 2;;
		-q | --quiet)
			quiet=1
			shift;;
	esac
done
}

function prompt(){
	fdisk -l | grep 'dev'
	echo "Current SD card is: $disk"
	echo "[!] Be sure you have the right device [!]"
	echo "[!] All data will be destroyed on the device [!]"
	echo "[Q] You can exit by typing q or quit"
	read -r -p "Proceed with $disk? [Y/n] " response
	response=${response,,}
	if [[ $response =~ ^(yes|y) ]]; then
		: # do nothing
	fi
	if [[ $response =~ ^(no|n) ]]; then
		change_disk_label
	fi
	if [[ $response =~ ^(q|quit|bye|exit) ]]; then
		exit 0
	fi
}

function change_disk_label(){
	fdisk -l | grep 'dev'
	echo "Please correct the Device Label:"
	read -r -p "$ /dev/" disk
	if [[ $disk =~ ^(q|quit|bye|exit) ]]; then
		exit 0
	fi
	echo "[+] SD Card set to: $disk"
	prompt
}

function wipe_sdcard(){
	echo "[+] Wiping SD card"
	dd if=/dev/zero of=/dev/"$disk" bs=4M status=progress
}

function partition_sd_card(){
	echo "[+] Creating SD Card patitions"
	fdisk /dev/"$disk"<<EOF
o
n
p
1

+100M
t
c
n
p
2


w
EOF
}

function create_filesystems(){
	echo '[+] Creating FileSystems'
	mkdir /mnt/"$disk" -p
	mkfs.vfat /dev/"$disk"1
	mkfs.ext4 /dev/"$disk"2
	mount /dev/"$disk"2 /mnt/"$disk"
	mkdir /mnt/"$disk"/boot
	mount /dev/"$disk"1 /mnt/"$disk"/boot
}

function install(){
	old_pwd=$(pwd)
	cd "/home/jack/Downloads/OS/rpi"
	ArchLinuxARM="ArchLinuxARM-rpi-2-latest.tar.gz"
	if [ ! -f $ArchLinuxARM ]; then
		echo "[!] Missing ArchLinuxARM pkg!"
		echo "[+] Downloading ArchLinux ARM"
		wget -c http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
	fi
	echo "[+] Expanding ArchLinux ARM onto FileSystem"
	bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C /mnt/"$disk" && sync
	cd $old_pwd
	#mv root/boot/* boot
}

function cleanup(){
	echo "[+] Cleaning Up"
	umount /mnt/"$disk"/boot /mnt/"$disk"
	echo "[+] Complete! Check for errors!"
	#rm /mnt/"$disk" -r
}

function post_install_setup(){
	echo "[+] Setting up qemu-arm-static binary"
	cp "/usr/bin/qemu-arm-static" "/mnt/$disk/usr/bin"
	cat<<EOF > /mnt/$disk/root/post_install.sh
#!/usr/bin/env bash

function aur_install() {
	#TODO: I need git installed first!
	git clone https://aur.archlinux.org/$pkg.git
	cd $pkg
	makepkg -sri --skipinteg --skippgpcheck
	cd ..
	rm -rf $pkg
}

# function Main() {
# pkgs to install
# aur_pkgs=(cower pacaur)
# for pkg in $aur_pkgs; do
# 	post_install_setup_aur_install
# 	echo "[+] Installed  $pkg"
# 	sleep 1
# echo "[+] pacaur installed! Defaulting to pacaur"
# pkgs=(sudo git vim python python-pip python-virtualenv)
#for pkg in $pkgs; do
#	post_install_setup_aur_install
	#TODO On failed pacaur install, fallback to post_install_setup_aur_install
	#TODO On failed post_install_setup_aur_install; echo $pkg >> failed_pkgs.log
#}
EOF
	# chroot "/mnt/$disk" "/bin/bash"
	# Chroot active, Install shit, Setup system automatically before it even touches a pi!
	# Change to root user to setup system!
	# Scratch that, It'd be easier to just make a seperate script to run on the pi itself.
}


function Main(){
	runtime_check
	init_vars
	parse_args "${@}"
	if [[ $no_confirm -eq 0 ]]; then
		prompt
	fi
	if [[ $wipe -eq 1 ]]; then
		wipe_sdcard
	fi
	partition_sd_card
	create_filesystems
	install
	if [[ $post_install -eq 0 ]]; then
		cleanup
		exit 0
	else
		post_install_setup
	fi
	echo "[+] Installation Complete!"
	echo "[!] Login with alarm:alarm or root:root"
}

Main "${@}"


