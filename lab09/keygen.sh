#!/usr/bin/bash
#
# Aleksandr Gavrik, 2019, mbfx@mail.ru
#
# Скрипт генерации ключей, если таковых ещё нет.
#
echo "Running RSA keys generator."

CURRENTDIR=$PWD
KEYNAME="id_rsa"
PASSPHRASE=""

if [ -f "$PWD/$KEYNAME" ] ;
        then
        echo "File $KEYNAME exist! Exiting."
        exit 0

	else
	ssh-keygen -q -t rsa -N "$PASSPHRASE" -f "$PWD/$KEYNAME"
fi
exit 0
