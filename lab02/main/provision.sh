#!/bin/sh
# Устанавливаем необходимые пакеты
yum install -y mdadm gdisk hdparm smartmontools

# Делаем RAID10 из 4 дисков и немного ждём
mdadm --create /dev/md0 -l 10 -n 4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
sleep 10
cat /proc/mdstat
sleep 3

# Создаём таблицу разделов GPT и 5 разделов
sgdisk --clear /dev/md0
sgdisk -n 1:34:100000 -n 2:100001:300000 -n 3:300001:500000 -n 4:500001:700000 -n 5:700001:1015741 /dev/md0
sgdisk --print /dev/md0

# Форматируем каждый из созданных разделов,
# создаем под них точки монтирования
# и добавляем нужные строки в fstab
for var in {1..5}
do
mkfs.ext4 /dev/md0p$var
sleep 1
mkdir /mnt/raid10_$var
echo 'UUID='`blkid /dev/md0p$var -s UUID -o value`' /mnt/raid10_'$var'           ext4    defaults        0 1' >> /etc/fstab
done

# Монтируем всё что есть
mount -a

# Симулируем отказ двух жестких дисков из RAID10
# Удаляем их из массива, добавляем новые и немного ждём.
echo 1 > /sys/block/sdc/device/delete
echo 1 > /sys/block/sdd/device/delete
#mdadm /dev/md0 --fail /dev/sdc
#mdadm /dev/md0 --fail /dev/sdd
#mdadm /dev/md0 --remove /dev/sdc
#mdadm /dev/md0 --remove /dev/sdd
mdadm /dev/md0 --add /dev/sdf
mdadm /dev/md0 --add /dev/sdg
echo 'Time to resync...'
sleep 30
# Смотрим на то, что получилось в итоге
cat /proc/mdstat
lsblk

