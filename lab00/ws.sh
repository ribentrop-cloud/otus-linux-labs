#!/usr/bin/bash

echo "Installing wget..."
yes | yum -y -q install wget

echo "Installing VBox repo..."
if [[ ! -e /etc/yum.repos.d/virtualbox.repo ]]
        then
        wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo --directory-prefix=/etc/yum.repos.d/ --quiet
        else
        echo "virtualbox.repo file exist!"
fi

echo "Installing epel repo..."
yes | yum -y -q install epel-release

echo "Installing VBox & prereqs..."
yes | yum -y -q install dkms
yes | yum -y -q groupinstall "Development Tools"
yes | yum -y -q install kernel-devel
yes | yum -y -q install VirtualBox-5.2
usermod -a -G vboxusers mbfx

echo "Installing Vagrant..."
yes | yum -y -q install https://releases.hashicorp.com/vagrant/2.2.4/vagrant_2.2.4_x86_64.rpm

echo "Installing user soft&env..."
yes | yum -y -q install git vim


