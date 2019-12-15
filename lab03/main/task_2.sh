#!/bin/sh
# Создадим lv для домашнего каталога
lvcreate -L 4G -n LogVol02Home /dev/VolGroup00
# Отформатируем его
mkfs.xfs /dev/VolGroup00/LogVol02Home
# Смонтируем том на временную точку, скопируем туда содержимое home.
mkdir /mnt/newhome
mount /dev/VolGroup00/LogVol02Home /mnt/newhome
cp --preserve=context -rfp /home/* /mnt/newhome/
# Сразу приберёмся. И перемонтируем том с временной точки на постоянную с прописываение в fstab.
rm -rf /home/*
umount /mnt/newhome
mount /dev/VolGroup00/LogVol02Home /home/
echo 'UUID='`blkid /dev/VolGroup00/LogVol02Home -s UUID -o value`' /home           xfs    defaults        0 0' >> /etc/fstab
# Второе задание выполнено.
reboot

