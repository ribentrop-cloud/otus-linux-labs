#!/bin/sh
# Устанавливаем zfs on linux
yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm
sed -i '4s/enabled=1/enabled=0/' /etc/yum.repos.d/zfs.repo
sed -i '12s/enabled=0/enabled=1/' /etc/yum.repos.d/zfs.repo
yum install -y zfs
# Проверяем, подгрузился ли модуль
lsmod | grep zfs
# Подгружаем на всякий случай
modprobe zfs
# Снова проверяем
lsmod | grep zfs
# Создаем зеркальный пул из sdd и sde
zpool create zfstest mirror /dev/sdd /dev/sde
# Добавляем в пул том для кеширования (L2ARC)
zpool add zfstest cache /dev/sdc
# Добавляем в пул том для логов (SLOG)
zpool add zfstest log /dev/sdb
# Смотрим, как это все выглядит
zpool list
#
zpool status -v
#
lsblk
#
df -h
#
zfs list
# Смотрим, есть ли снепшоты (конечно же, нет)
zfs list -t snapshot
# Проверим, куда по-умолчанию смонтирована ФС
zfs get mountpoint
# Перепривяжем ФС к /opt
zfs set mountpoint=/opt zfstest
# Создадим тестовую группу файлов
touch /opt/test{1..2}
echo zfs1 > /opt/test1
echo zfs1 > /opt/test2
cat /opt/test{1..2}
# Сделаем снепшот
zfs snapshot zfstest@snaptest
# Проверим, появился ли снимок
zfs list -t snapshot
# Изменим файлы тестовой группы
touch /opt/test{3..4}
echo zfs2 > /opt/test1
echo zfs2 > /opt/test2
echo zfs2 > /opt/test3
echo zfs2 > /opt/test4
cat /opt/test{1..4}
# Сделаем откат
zfs rollback zfstest@snaptest
# Проверим файлы и их содержимое
ls -la /opt
cat /opt/test{1..2}
# Всё ОК!
# Удалим снимок
zfs destroy zfstest@snaptest

