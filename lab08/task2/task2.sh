#!/usr/bin/bash
#
# Aleksandr Gavrik, mbfx@mail.ru, 2019
#
# Скрипт, который переименовывает VG под установленной системой.
#
# Объявляем переменные, в т.ч. получаем имя vg текущего корня
TARGETVGNAME="RenamedVolGroup00"
EXISTVGNAME="`mount | awk '$3=="/" {print $1}' | cut -d"/" -f4 | cut -d"-" -f1`"
# Переименовываем vg
yes | vgrename $EXISTVGNAME $TARGETVGNAME
# Делаем резервные копии
cp -f /etc/fstab /etc/fstab.backup
cp -f /etc/default/grub /etc/default/grub.backup
# Меняем старое имя на новое в fstab и шаблоне grub
sed -i "s/$EXISTVGNAME/$TARGETVGNAME/g" /etc/fstab
sed -i "s/$EXISTVGNAME/$TARGETVGNAME/g" /etc/default/grub
# По идее тут надо сгенерировать grub.cfg из шаблона с помощью grub2-mkconfig, но ...
# вот так не работает, т.к. / примонтирован по старому vg и grub2-probe не может на помочь.
# Значит сделаем руками: снимен резервную копию
cp -f /boot/grub2/grub.cfg /boot/grub2/grub.cfg.backup
# И внесем нужные изменения
sed -i "s/$EXISTVGNAME/$TARGETVGNAME/g" /boot/grub2/grub.cfg
# Пересоздадим initrd, чтобы начальный образ знал про новый vg
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
# Сделаем relable для файловой системы, а то потом в ssh не зайдём.
touch /.autorelabel
# Всё, можно перезагружаться.
