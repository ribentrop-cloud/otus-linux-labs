# Подправим нашу будущую систему, а именно
# Уберем лишнее из fstab и добавим нужное
sed -i '/UUID/s/^/#/' /etc/fstab
echo 'UUID='`blkid /dev/md0 -s UUID -o value`' /           xfs    defaults        0 0' >> /etc/fstab
# Сделаем резервную копию настроек загрузчика
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak
# И обновим его настройки под существующие реалии
grub2-mkconfig -o /boot/grub2/grub.cfg
sleep 2
# Установим загрузчик наш новый диск.
grub2-install /dev/sdb
# С chroot закончили.
exit
