#!/bin/bash
#
# Aleksandr Gavrik, mbfx@mail.ru, 2019
#
# Vagrant provision script: перемещаем раздел /boot на / c lvm
#
# Создадим временный каталог для содержимого каталога boot и переместим содержимое в него
mkdir /boot_to_lvm
cp --preserve=context -rfp /boot/ /boot_to_lvm/
# Размонтируем существующий раздел boot
umount /boot
# Вернём создержимое из временного каталога
cp --preserve=context -rfp /boot_to_lvm/boot/ /
# Внесём изменения в систему для того, чтобы наша система загрузилась с /
# Сделаем резервную копию и обновим fstab
cp /etc/fstab /etc/fstab.backup.boot_to_lvm
sed -i '/\/boot/d' /etc/fstab
# Сделаем резервную копию и обновим шаблон grub:
# Добавим туда модуль lvm и опции, указывающие на наш vg
cp /etc/default/grub /etc/default/grub.backup.boot_to_lvm
sed -i 's/ rhgb quiet/ rhgb quiet rd.auto=1 rd.lvm=1 rd.lvm.vg=VolGroup00/' /etc/default/grub
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
