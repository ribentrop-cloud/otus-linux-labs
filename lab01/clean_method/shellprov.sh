#!/bin/sh
cd $HOME
sudo yum -y install wget
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.36.tar.xz --directory-prefix=$HOME --quiet
tar xf $HOME/linux-4.19.36.tar.xz --directory=$HOME
cp /boot/config-`uname -r` $HOME/linux-4.19.36/.config
sudo yum -y install gcc bison flex elfutils-libelf-devel bc openssl-devel perl rpm-build
cd $HOME/linux-4.19.36
yes "" | make oldconfig 1>/dev/null
make -j$((`nproc`+1)) rpm-pkg 1>/dev/null
sudo rpm -ivh --quiet $HOME/rpmbuild/RPMS/x86_64/kernel-4.19.36-1.x86_64.rpm
sudo rpm -ivh --quiet $HOME/rpmbuild/RPMS/x86_64/kernel-devel-4.19.36-1.x86_64.rpm
sudo rpm -iUh --quiet $HOME/rpmbuild/RPMS/x86_64/kernel-headers-4.19.36-1.x86_64.rpm
sudo rpm -ivh --quiet $HOME/rpmbuild/SRPMS/kernel-4.19.36-1.src.rpm
sudo grub2-set-default 0

