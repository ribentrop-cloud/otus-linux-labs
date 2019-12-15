#!/bin/sh
# Перейдём в домашний каталог
cd /home/vagrant
# Создадим пару тестовых файлов
touch test{1..2}
# В один из файлов запишем некое известное содержимое
echo 'test1' > test1
# Создадим snapshot
sudo lvcreate -L 1G -s -n Home_snapshot /dev/VolGroup00/LogVol02Home
# Добавим ещё пару файлов
touch test3
# В новый файл добавим что-нибудь, а в старом - изменим. Один удалим.
echo 'test2' > test1
echo 'test2' > test3
rm -f test2
# Откатимся на snapshot - отмонтируем раздел, произведёи слияние, примонтируем.
cd /
umount /home
lvconvert --merge /dev/VolGroup00/Home_snapshot
mount -a
# Проверка
ls -l /home/vagrant
cat /home/vagrant/test1
# Файлов созданных после snapshot нет, а старые восстановлены сместе с  содержимым.
# Приберёмся.
rm -f /home/vagrant/test{1..3}
# Четвертое и шестое задания выполнены
#
#

