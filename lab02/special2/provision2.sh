#!/bin/sh
# Снова root
# Копируем структуру разделов с sdb на sda
sfdisk -d /dev/sdb | sfdisk /dev/sda
# Добавляем старый диск как RAID member
mdadm /dev/md0 --add /dev/sda1
# На всякий случай обновим конфигурацию grub
grub2-mkconfig -o /boot/grub2/grub.cfg
# И переустановим загрузчик на sda, чтобы можно было грузиться с любой из дисков.
grub2-install /dev/sda
# Запланируем проверку при следующей перезагрузке. На всякий случай.
touch /forcefsck

