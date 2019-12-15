Комментарии и ход решения в комментариях скрипта.
Provisioning в vagrant тут не сделан.

Выполнять сначала provision.sh, а после перезагрузки provision2.sh
chroot.sh выполнять не нужно, он выполняется сам из первого скрипта.

Вывод lsblk до:

[vagrant@lab2s2 ~]$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0  42G  0 disk


Вывод lsblk после:

[root@lab2s2 vagrant]# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda       8:0    0   40G  0 disk
└─sda1    8:1    0   40G  0 part
  └─md0   9:0    0 39.8G  0 raid1 /
sdb       8:16   0   42G  0 disk
└─sdb1    8:17   0 39.9G  0 part
  └─md0   9:0    0 39.8G  0 raid1 /

