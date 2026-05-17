#!/bin/sh
ROOTFS_DIR=$(pwd)
ARCH=$(uname -m)

# Използваме локалния файл, който вече имаш в папката
if [ "$ARCH" = "x86_64" ]; then
    PROOT_LOCAL="$ROOTFS_DIR/proot-x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    PROOT_LOCAL="$ROOTFS_DIR/proot-aarch64"
else
    echo "Неподдържана архитектура: $ARCH"
    exit 1
fi

# Проверка дали файлът съществува
if [ ! -f "$PROOT_LOCAL" ]; then
    echo "Грешка: Не намерих локален proot файл ($PROOT_LOCAL)!"
    exit 1
fi

# Даваме му права за изпълнение за всеки случай
chmod +x "$PROOT_LOCAL"

ALPINE_VER="3.20.0"
ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/${ARCH}/alpine-minirootfs-${ALPINE_VER}-${ARCH}.tar.gz"

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    echo "========================================="
    echo " Сваляне на Alpine Linux rootfs (~5MB)..."
    echo "========================================="
    # Свалянето на самия Linux (tar.gz) обикновено не се блокира от Binder
    wget -q --show-progress -O /tmp/alpine.tar.gz "$ROOTFS_URL" || curl -L "$ROOTFS_URL" -o /tmp/alpine.tar.gz
    
    echo "\nРаzarхивиране на файловата система..."
    tar -xzf /tmp/alpine.tar.gz -C "$ROOTFS_DIR"
    rm /tmp/alpine.tar.gz
    
    mkdir -p "$ROOTFS_DIR/etc"
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > "$ROOTFS_DIR/etc/resolv.conf"
    touch "$ROOTFS_DIR/.installed"
fi

echo "========================================="
echo " Влизане в Alpine Linux (Custom Shell)"
echo "========================================="
export PROOT_NO_SECCOMP=1

# Вместо да пускаме стандартния интерактивен shell, 
# правим наш собствен безкраен цикъл, който чете команди безопасно.
exec "$PROOT_LOCAL" \
    -r "$ROOTFS_DIR" \
    -0 \
    -b /dev \
    -b /proc \
    -b /sys \
    -w /root \
    /bin/sh -c 'while printf "alpine-root# "; read cmd; do eval "$cmd"; done'
