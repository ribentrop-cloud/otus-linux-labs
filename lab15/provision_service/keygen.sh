#!/usr/bin/env bash
#
# Aleksandr Gavrik, 2019, mbfx@mail.ru
#
# Скрипт генерации ключей, если таковых ещё нет.
#
echo "RSA keys checker and generator..."

KEYNAME="id_rsa"
PASSPHRASE=""

if [ -f "$HOME/.ssh/$KEYNAME" ] ; # Проверяем наличие уже готовых ключей
        then
        echo "File $KEYNAME exist in $HOME/.ssh"
        if [ -f "$HOME/.ssh/$KEYNAME" ] ; # Если есть, то будем использовать их
            then
            echo "Copy file from $HOME/.ssh to $PWD"
            cp -b $HOME/.ssh/$KEYNAME* $PWD/
        fi
	else
    echo "Generating keys in $HOME/.ssh" # А если нет, то сделаем новые
	ssh-keygen -q -t rsa -N "$PASSPHRASE" -f "$HOME/.ssh/$KEYNAME"
    echo "Copy keyfile from $HOME/.ssh to $PWD"
    cp -b $HOME/.ssh/$KEYNAME* $PWD/ # И будем использовать новые
fi
echo "RSA keys checker and generator... done."
#
# Скрипт генерации ключей для bacula.
#
MKEYNAME="master.key"
MCERTNAME="master.cert"
FDKEYNAME="fd.key"
FDCERTNAME="fd.cert"

if [ -f "$MKEYNAME" ] ;
        then
        echo "File $MKEYNAME exist."
        else
        openssl genrsa -out $MKEYNAME 2048
        openssl req -new -key $MKEYNAME -x509 -out $MCERTNAME -subj '/C=RU/ST=Kaliningrad/L=Kaliningrad/O=OTUS/OU=LinuxAdmin/CN=bserver'
fi
if [ -f "$FDKEYNAME" ] ;
        then
        echo "File $FDKEYNAME exist."
        else
        openssl genrsa -out $FDKEYNAME 2048
        openssl req -new -key $FDKEYNAME -x509 -out $FDCERTNAME -subj '/C=RU/ST=Kaliningrad/L=Kaliningrad/O=OTUS/OU=LinuxAdmin/CN=bserver'
fi
cp $MCERTNAME ansible_repo/roles/install_fd/files/master.cert
cat $FDKEYNAME $FDCERTNAME > ansible_repo/roles/install_fd/files/fd.pem
exit 0
