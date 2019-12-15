#!/usr/bin/bash
#
# Aleksandr Gavrik, 2019, mbfx@mail.ru
#
# Добавляем ключи виртуальных машин в известные на локальной машине (чтобы ansible не ругался)
echo "SSH-keyscan..."
sed -i '/^192.168.11.121/d' ~/.ssh/known_hosts
ssh-keyscan -t rsa 192.168.11.121 >> ~/.ssh/known_hosts 2>/dev/null
exit 0