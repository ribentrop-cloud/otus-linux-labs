#
# Aleksandr Gavrik, mbfx@mail.ru, 2019
#
# Скрипт, который добавляет модуль в initrd
#
# Подготовим место под наш модуль и добавим его в dracut
mkdir /usr/lib/dracut/modules.d/01testmodule
cp /vagrant/task3/module-setup.sh /usr/lib/dracut/modules.d/01testmodule/module-setup.sh
chmod +x /usr/lib/dracut/modules.d/01testmodule/module-setup.sh
cp /vagrant/task3/testmodule.sh /usr/lib/dracut/modules.d/01testmodule/testmodule.sh
chmod +x /usr/lib/dracut/modules.d/01testmodule/testmodule.sh
# Обновим образ initrd
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
# Выключим режим тихой загрузки в grub
cp /etc/default/grub /etc/default/grub.backup.task3
sed -i "s/ rhgb quiet//g" /etc/default/grub
# Обновим конфигурацию загрузчика, чтобы применилось выключение тихого режима
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.backup.task3
grub2-mkconfig -o /boot/grub2/grub.cfg
# Можно перезагружаться и проверять!

