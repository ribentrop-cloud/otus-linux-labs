#!/bin/bash
#
# Aleksandr Gavrik, mbfx@mail.ru, 2019
#
# Vagrant provision script: перемещаем раздел /boot на lvm
#
# Создадим временный каталог для содержимого каталога boot и переместим содержимое в него
mkdir /boot_to_lvm
cp --preserve=context -rfp /boot/ /boot_to_lvm/
# Размонтируем существующий раздел boot, добавим раздел в существующий vg и создадим а нем новый lv
umount /boot
yes | pvcreate /dev/sda2
vgextend VolGroup00 /dev/sda2
lvcreate -L 900M -n boot VolGroup00
# Произведём форматирование нового раздела, примонтируем его и вернём создержимое из временног каталога
mkfs.ext2 /dev/VolGroup00/boot
mount /dev/VolGroup00/boot /boot
cp --preserve=context -rfp /boot_to_lvm/boot/ /
# Внесём изменения в систему для того, чтобы наша система загрузилась с нового boot
# Сделаем резервную копию и обновим fstab
cp /etc/fstab /etc/fstab.backup.boot_to_lvm
sed -i '/\/boot/d' /etc/fstab
echo "/dev/mapper/VolGroup00-boot	/boot           ext2    defaults        0 0" >> /etc/fstab
# Сделаем резервную копию и обновим шаблон grub:
# Добавим туда модуль lvm и опции, указывающие на наш новый lv
cp /etc/default/grub /etc/default/grub.backup.boot_to_lvm
sed -i 's/ rhgb quiet/ rhgb quiet rd.auto=1 rd.lvm=1 rd.lvm.vg=VolGroup00 rd.lvm.lv=VolGroup00\/boot/' /etc/default/grub
echo "GRUB_PRELOAD_MODULES=\"lvm\"" >> /etc/default/grub
# Сделаем резервную копию и перегенерируем конфигурацию загрузчика
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.boot_to_lvm
grub2-mkconfig -o /boot/grub2/grub.cfg
# Переустановим загрузчик
grub2-install /dev/sda
# Приберёмся
#rm -rf /boot_to_lvm
#rm -f /boot/grub2/grub.cfg.boot_to_lvm
#rm -f /etc/default/grub.backup.boot_to_lvm
#rm -f /etc/fstab.backup.boot_to_lvm
# Ну вот и всё. Перезагружаемся.
echo "Reboot..."
reboot
