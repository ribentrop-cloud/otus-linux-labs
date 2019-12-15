#!/bin/sh
# Для такой операции нужен, конечно же, root 
# Устанавливаем mdadm
yum install -y mdadm --quiet
# Создаем на sdb таблицу разделов и раздел sdb1.
# Не забываем, что нужно оставить немного места под grub
# и не превысить размер соседнего тома, чтобы потом сделать RAID.
echo '1,5200,L,*;' | sfdisk /dev/sdb
sleep 2
# Создаём из sdb1 RAID1 в состоянии degraded.
# Второй диск подключим после переноса системы. 
yes | mdadm --create /dev/md0 --level=1 --raid-disks=2 missing /dev/sdb1
sleep 2
# Создаем на /dev/md0 идентичную /dev/sda1 файловую систему
mkfs.xfs /dev/md0
sleep 2
# Готовим каталоги для нового и старого корня. Монтируем их.
mkdir /mnt/oldroot
mkdir /tmp/oldsys
mount /dev/md0 /mnt/oldroot
mount /dev/sda1 /tmp/oldsys
# Делаем резервную копию default grub config
cp /etc/default/grub /etc/default/grub.bak
# Добавляем в default grub config GRUB_CMDLINE_LINUX опцию rd.auto=1
# Так у нас включится автосборка специальных устройств, raid в частности. 
sed -i 's/crashkernel=auto/crashkernel=auto rd.auto=1/' /etc/default/grub
# Обновляем текущий initramfs через dracut
# добавляем туда модуль mdraid и драйвер raid1
dracut --add="mdraid" --add-drivers="raid1" -f /boot/initramfs-$(uname -r).img $(uname -r)
# Переносим всё содержимое старого корня в новый с сохранением контекста selinux
cp --preserve=context -rfp /tmp/oldsys/* /mnt/oldroot/
# Сделаем контекстные ссылки на каталоги со всякими tmpfs и ... сделаем chroot
mount --bind /proc /mnt/oldroot/proc
mount --bind /dev /mnt/oldroot/dev
mount --bind /sys /mnt/oldroot/sys
mount --bind /run /mnt/oldroot/run 
chroot /mnt/oldroot ./vagrant/chroot.sh
#
# Технически, тут можно уходить на перезагрузку,
# лезть в BIOS и грузиться с другого жесткого диска
# Но у нас нет такой возможности.
# Поэтому переопределим загрузочный диск из grub.
# Сейчас у нас есть правильная конфигурация в новом окружении.
# Ею и воспользуемся.
# Сделаем резервные копии настроек grub и fstab
#
mv /etc/fstab /etc/fstab.bak
mv /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak
# И скопируем корректные настройки.
cp /mnt/oldroot/etc/fstab /etc/fstab
cp /mnt/oldroot/boot/grub2/grub.cfg /boot/grub2/grub.cfg
# Всё отмонтируем и немного проберём за собой
umount -R /mnt/oldroot
sleep 2
rm -r /mnt/oldroot
# Поехали!
reboot

