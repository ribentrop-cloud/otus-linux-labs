#!/usr/bin/bash
#
# Aleksandr Gavrik, 2019, mbfx@mail.ru
#
# Включаем маршрутизацию "второй сети Vagrant" через default gateway.
# Теперь можно обращаться на https://freeipa.mydomain.test (192.168.11.117) с любой машины в сети
# Если, конечно, настроен DNS
echo "add default gateway..."
sudo nmcli connection modify "System eth1" +ipv4.gateway "192.168.11.1" ipv4.route-metric 1
sleep 3
sudo systemctl restart network
exit 0
