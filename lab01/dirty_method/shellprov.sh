#!/bin/sh
sudo yum -y -q install wget
sudo wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.36.tar.xz --directory-prefix=/usr/src/kernels/ --quiet
sudo tar xf /usr/src/kernels/linux-4.19.36.tar.xz --directory=/usr/src/kernels/
sudo cp /boot/config-`uname -r` /usr/src/kernels/linux-4.19.36/.config
sudo yum -y -q install gcc bison flex elfutils-libelf-devel bc openssl-devel perl
cd /usr/src/kernels/linux-4.19.36/
sudo make clean
yes "" | sudo make oldconfig 1>/dev/null
sudo make -j$((`nproc`+1)) 1>/dev/null
sudo make -j$((`nproc`+1)) modules_install 1>/dev/null
sudo make install
sudo make -j$((`nproc`+1)) headers_install
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0