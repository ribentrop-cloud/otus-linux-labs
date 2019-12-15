#!/bin/sh
# Отметим тома sdd и sde для использования в lvm 
pvcreate /dev/sdd /dev/sde
# Создадним vg из sdd и sde
vgcreate VolGroup01 /dev/sdd /dev/sde
# Создадим зеркальный том lvm 
lvcreate -L 900M -m 1 -n LogVol03Var /dev/VolGroup01
# Отформатируем его
mkfs.xfs /dev/VolGroup01/LogVol03Var
# Смонтируем на временную точку и скопируем туда данные
mkdir /mnt/newvar
mount /dev/VolGroup01/LogVol03Var/ /mnt/newvar
cp --preserve=context -rfp /var/* /mnt/newvar/
# Удалим старые данные и перемонтируем том на постоянное место + fstab
rm -rf /var/*
umount /mnt/newvar
mount /dev/VolGroup01/LogVol03Var /var/
echo 'UUID='`blkid /dev/VolGroup01/LogVol03Var -s UUID -o value`' /var           xfs    defaults        0 0' >> /etc/fstab
# Третье задание выполнено.
#
#
reboot


