#!/bin/sh
# Устанавливаем xfsdump
yum install xfsdump -y
# Создаем на sdb logival volume на весь его размер
pvcreate /dev/sdb
vgcreate vg_temproot /dev/sdb
lvcreate -l +100%FREE -n lv_temproot /dev/vg_temproot
# Форматируем созданное устройство
mkfs.xfs /dev/vg_temproot/lv_temproot
# Монтируем новое устройство и переносим туда нашу ФС
mkdir /mnt/newroot
mount /dev/vg_temproot/lv_temproot /mnt/newroot
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt/newroot
# Подготавливаем ФСы для будущего chroot
mount --bind /proc /mnt/newroot/proc
mount --bind /dev /mnt/newroot/dev
mount --bind /sys /mnt/newroot/sys
mount --bind /run /mnt/newroot/run 
mount --bind /boot /mnt/newroot/boot
# Используя chroot к будущему корню обновляем конфигурацию загрузчика
chroot /mnt/newroot grub2-mkconfig -o /boot/grub2/grub.cfg
# Обновляем initramfs через dracut. Добавлять ничего не надо.
dracut -f /boot/initramfs-$(uname -r).img $(uname -r)
# Корректируем конфигурацию загрузчика, чтобы потом загрузиться с нового раздела.
sed -i 's/rd.lvm.lv=VolGroup00\/LogVol00/rd.lvm.lv=vg_temproot\/lv_temproot/' /boot/grub2/grub.cfg
# Перезагружаемся
reboot
# Продолжение в task_1.1.sh

