#!/bin/sh
yes | lvcreate -L 1G -n LogVol04ext4 /dev/VolGroup00 1>/dev/null
mkfs.ext4 /dev/VolGroup00/LogVol04ext4 1>/dev/null
mkdir /mnt/vg00lv04_ext4
echo 'UUID='`blkid /dev/VolGroup00/LogVol04ext4 -s UUID -o value`' /mnt/vg00lv04_ext4           ext4    defaults        0 0' >> /etc/fstab
mount -a
touch /mnt/vg00lv04_ext4/test1
yes | lvcreate -L 1G -n LogVol05ext4 /dev/VolGroup00 1>/dev/null
mkfs.ext4 /dev/VolGroup00/LogVol05ext4 1>/dev/null
mkdir /mnt/vg00lv05_ext4
echo 'UUID='`blkid /dev/VolGroup00/LogVol05ext4 -s UUID -o value`' /mnt/vg00lv05_ext4           ext4    ro        0 0' >> /etc/fstab
mount -a
touch /mnt/vg00lv05_ext4/test1

sed -i '/mnt\/vg00lv04_ext4/d' /etc/fstab
sed -i '/mnt\/vg00lv05_ext4/d' /etc/fstab
umount /mnt/vg00lv04_ext4
umount /mnt/vg00lv05_ext4
yes | lvremove /dev/VolGroup00/LogVol04ext4
yes | lvremove /dev/VolGroup00/LogVol05ext4

