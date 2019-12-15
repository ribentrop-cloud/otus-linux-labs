#!/usr/bin/bash
#
# Aleksandr Gavrik, 2019, mbfx@mail.ru
#
# Добавляем ключи виртуальных машин в известные на локальной машине (чтобы ansible не ругался)
echo "SSH-keyscan..."
ssh-keyscan -t rsa 192.168.11.117 >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -t rsa 192.168.11.118 >> ~/.ssh/known_hosts 2>/dev/null
exit 0
