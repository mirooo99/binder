#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                      Foxytoux INSTALLER"
  echo "#"
  echo "#                           Copyright (C) 2024, RecodeStudios.Cloud"
  echo "#"
  echo "#"
  echo "#######################################################################################"

  read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu
fi

case $install_ubuntu in
  [yY][eE][sS])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

# РЕДАКТИРАНАТА ЧАСТ: Вместо да теглим през wget и да дава Killed, ползваме локалния файл
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  
  if [ -f "$ROOTFS_DIR/proot-${ARCH}" ]; then
    echo "Копиране на локалния файл proot-${ARCH}..."
    cp "$ROOTFS_DIR/proot-${ARCH}" "$ROOTFS_DIR/usr/local/bin/proott"
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proott"
  else
    echo "Грешка: Файлът proot-${ARCH} не е намерен в тази папка!"
    exit 1
  fi
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin
  touch "$ROOTFS_DIR/.installed"
fi

CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

clear
display_gg

unset LD_PRELOAD
export PROOT_NO_SECCOMP=1

mkdir -p "$ROOTFS_DIR/roott"

exec $ROOTFS_DIR/usr/local/bin/proott \
  -r "$ROOTFS_DIR" \
  -0 \
  -w /roott \
  /bin/sh
