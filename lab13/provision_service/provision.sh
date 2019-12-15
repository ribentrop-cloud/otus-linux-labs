#!/usr/bin/bash
#
# Aleksandr Gavrik, 2019, mbfx@mail.ru
#
# Добавляем ключи ключи в авторизованные
mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
cat /vagrant/id_rsa.pub | awk '{print $1,$2}' >> /root/.ssh/authorized_keys
exit 0
