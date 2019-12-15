#!/bin/sh
# Удаляем старый lv из vg и создаем новый размером 8Гб
yes | lvremove /dev/VolGroup00/LogVol00
yes | lvcreate -L 8G -n LogVol00 /dev/VolGroup00
# Форматируем созданное устройство
mkfs.xfs /dev/VolGroup00/LogVol00
# Монтируем новое устройство и переносим туда нашу ФС
mkdir /mnt/newroot
mount /dev/VolGroup00/LogVol00 /mnt/newroot
xfsdump -J - /dev/vg_temproot/lv_temproot | xfsrestore -J - /mnt/newroot
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
# Здесь корректировать загрузчие нет необходимости
# Перезагружаемся
reboot
# Продолжение в task_1.2.sh

