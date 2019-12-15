#### NFSv4 & SAMBA

#### Задание

- развернуть NFSv4 и SAMBA;
- выделить несколько директорий и прописать их в exports/smb.conf с разными параметрами;
- проверить подключение с другой машины;
- настроить автомонтирование.

Дополнительно:
- использовать Kerberos.

#### Выполнение

#### Установка NFSv4
Ставим NFS и разрешаем его работу по сети:
```
yum install nfs-utils -y
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --reload
```
Отредактируем файл ```/etc/sysconfig/nfs``` так, чтобы использовать только NFSv4:
```
RPCNFSDARGS="-N2 -N3 -V4"
RPCMOUNTDOPTS="-N2 -N3 -V4 -u"
```
Перезапустим nfs-config для переконфигурации NFS:
```
systemctl restart nfs-config
```
Принудительно отключим сервисы, связанные с NFSv3 и ниже:
```
systemctl stop rpcbind.service rpc-statd.service rpcbind.socket
systemctl disable rpcbind.service rpc-statd.service rpcbind.socket
systemctl mask rpcbind.service rpc-statd.service rpcbind.socket
```
Включаем NFS
```
systemctl start nfs-server.service
systemctl enable nfs-server.service
```

#### Настройка NFSv4 на сервере
Создадим пару директорий:
```
sudo mkdir -p /var/nfs/dir1
sudo mkdir -p /var/nfs/dir2
```
И экспортируем их в NFS посредством добавления в файл /etc/exports
```
cat /etc/exports
/var/nfs/dir1 10.51.21.10(rw,sync,no_root_squash) 10.51.21.11(rw,async,root_squash) 10.51.21.12(ro,sync,no_root_squash)
/var/nfs/dir2 10.51.21.8/29(rw,sync,root_squash)
```
На что здесь обратить внимание:
- каждая директория экспортируется отдельной строкой;
- в каждой строке указывается имя сервера(FQDN как вариант) или его IP-адрес (или группа имён и адресов через пробел, или IP-подсеть);
- к каждому имени/адресу или их группе указаны в скобках параметы экспорта (серверные параметры).


#### Настройка NFSv4 на клиенте
Ручное монтирование c подробностями:
```
mount -v -t nfs4 10.51.21.7:/var/nfs/dir1 /mnt/nfs/dir1 -o sec=sys,vers=4.1,noatime
```
Обратите внимание на опции, в частности, на sec=sys: она требуется для принудительного указания типа аутентификации - в данном случае это AUTH_SYS.

Автомонтирование через /etc/fstab:
```
10.51.21.7:/var/nfs/dir1 /mnt/nfs/dir1 nfs4 defaults,sec=sys 0 0
10.51.21.7:/var/nfs/dir2 /mnt/nfs/dir2 nfs4 defaults,sec=sys,noatime 0 0
```

На уже смонтированные устройства можно натравить ```/usr/lib/systemd/system-generators/systemd-fstab-generator```, который проанализировав ```/etc/fstab``` в директорию ```/tmp``` положит готовые юниты для systemd. Их преимущество в том, что монтирование fstab не всегда проходит в нужные момент загрузки ОС, а в systemd можно указать конретные зависимоти от которых будет зависеть запуск юнитов монтирования устройств.


#### Использование ACL и NFSv4
Установка:
```
yum install nfs4-acl-tools
```
Предварительная настройка: в файле /etc/idmapd.conf указать Domain (например Domain=localhost).

Используются команды ```nfs4_getfacl``` и ```nfs4_setfacl```, например, на клиенте:
```
[otus@host ]$ cd /mnt/nfs/dir1
[otus@host dir1]$ touch nfs4acl_test
[otus@host dir1]$ nfs4_getfacl nfs4acl_test

# file: nfs4acl_test2
A::OWNER@:rwatTcCy
A::GROUP@:rwatcy
A::EVERYONE@:rtcy

[otus@host dir1]$ nfs4_setfacl -a A::otus@localdomain:RX nfs4acl_test
[otus@host dir1]$ nfs4_editfacl nfs4acl_test
```


#### Развёртывание Kerberos DC и Realm
Обязательные предварительные требования:
- синхронизированное время;
- доступность хостов по FQDN (hosts или DNS).
Установка 
```
yum install krb5-server krb5-workstation pam_krb5
```
Приведём файл ```/var/kerberos/krb5kdc/kdc.conf``` к виду:
```
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 LOCALDOMAIN = {
  default_principal_flags = +preauth
  master_key_type = aes256-cts
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }
```
Приведём файл ```/etc/krb5.conf``` к виду:
```
includedir /etc/krb5.conf.d/

[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_ccache_name = KEYRING:persistent:%{uid}
```
Приведём файл ```/etc/krb5.conf.d/localdomain``` к виду:
```
[libdefaults]
 dns_lookup_kdc = false
 default_realm = LOCALDOMAIN

[realms]
 LOCALDOMAIN = {
  kdc = 10.51.21.7:88
  admin_server = 10.51.21.7:749
 }

[domain_realm]
 vmnested.localdomain = LOCALDOMAIN
 xtradb01.localdomain = LOCALDOMAIN
 .localdomain = LOCALDOMAIN
 localdomain = LOCALDOMAIN

[appdefaults]
pam = {
debug = false
ticket_lifetime = 36000
renew_lifetime = 36000
forwardable = true
krb4_convert = false
validate = true
}
```
Также введём ограничения на управление базой данных Kerberos в файле ```/var/kerberos/krb5kdc/kadm5.acl```:
```
*/admin@LOCALDOMAIN     *
```
Теперь можно приступить к инициализации базы данных Kerberos (не забудьте мастер-пароль!):
```
kdb5_util create -r LOCALDOMAIN -s
```
Теперь можно включить соответствующие службы и разрешить их автозапуск:
```
systemctl enable krb5kdc kadmin
systemctl start krb5kdc kadmin
```
И не забыть про firewall:
```
firewall-cmd --permanent --add-service=kerberos
firewall-cmd --reload
```
Тут есть нюанс: это правило разрешит доступ по портам 88/tcp и 88/udp, а нам ещё могут понадобиться 464/tcp (password management) и 749/tcp (Kerberos administration).


#### Создание базовых principals на сервере KDC
Зайдем в локальный интерфейс управления Kerberos и создадим там принципала администратора:
```
kadmin.local
addprinc root/admin
```
Теперь там же добавим имя хоста-KDC в базу данных Kerberos, а также сделаем локальную копию только что созданных ключей из базы Kerberos в файл ```/etc/krb5.keytab```. 
```
addprinc -randkey host/vmnested.localdomain
ktadd host/vmnested.localdomain
```


#### Подключение клиента в Realm
Обязательные предварительные требования:
- синхронизированное время;
- доступность хостов по FQDN (hosts или DNS).
Установка 
```
yum install krb5-workstation pam_krb5
```
Приведём файл ```/etc/krb5.conf``` к тому же виду, что и на сервере.
Приведём файл ```/etc/krb5.conf.d/localdomain``` к тому же виду, что и на сервере.
Создадим клиентского принципала (для работы kadmin должен быть открыт порт 749/tcp на сервере):
```
kadmin
addprinc -randkey host/xtradb01.localdomain
ktadd host/xtradb01.localdomain
```


#### Интеграция NFSv4 и аутентификации Kerberos
Создадим принципал сервиса на сервере:
```
kadmin
addprinc -randkey nfs/vmnested.localdomain
ktadd nfs/vmnested.localdomain
```
Добавим в /etc/exports требование аутентификации клиентов по Kerberos, например, так:
```
/var/nfs/dir3 xtradb01.localdomain(rw,sync,root_squash,sec=krb5p)
```
Возможные параметры sec:
- krb5 - только аутентификация;
- krb5i - аутентификация и проверка целостности;
- krb5p - аутентификация, проверка целостности и шифрование трафика NFS.

Теперь создадим принипала сервиса на клиенте:
```
kadmin
addprinc -randkey nfs/xtradb01.localdomain
ktadd nfs/xtradb01.localdomain
```
Для монтирования ресурсов NFS с аутентификацией Kerberos также используется параметр sec:
```
cat /etc/fstab
vmnested.localdomain:/var/nfs/dir3 /mnt/nfs/dir3 nfs4 sec=krb5p 0 0
```
Теперь аутентифицированные пользователи смогут использовать принципал сервиса для доверенного подключения к NFSv4. 


#### Установка SAMBA
Установка:
```
yum install samba 
```
Разрешим работу сервисов SMB по сети:
```
firewall-cmd --permanent --zone=public --add-service=samba
firewall-cmd --reload
```
Откорректируем настройки служб, т.к. nmbd нам не нужен:
```
systemctl stop nmb.service
systemctl disable nmb.service
systemctl mask nmb.service
systemctl start smb.service
systemctl enable smb.service
```


#### Настройка сервера SAMBA
Создадим директорию для тестирования:
```
sudo mkdir -p /var/smb/dir1
```

Основной конфигурационный файл /etc/samba/smb.conf. Настроим его:
```
[global]
        workgroup = LOCALDOMAIN
        security = user
        passdb backend = tdbsam

[dir1]
        comment = dir1 example
        path = /var/samba/dir1
        browseable = Yes
        read only = No
```
SAMBA имеет очень много настроек и плагинов, позволяющих тонко настроить систему. Настройки меняются от версии к версии, поэтому тут лчуше обратиться к документации.
Применения параметров без рестарта службы и их предварительная проверка производятся командой ```testparm```.
Здесь стоит обратить внимание, что при установленном параметре security = user сервер SAMBA аутентифицирует пользователей исходя из информации, которая хранился в её(!) отдельной базе данных (управляется ```smbpasswd```), т.е. аутентификация идёт средствами SAMBA, а права доступа к файловой системе проверяются отдельно, но обычно для удобства лучше назначить системным пользователям и пользователям SAMBA одинаковые учетки. Альтернатива - централизованные системы управления пользователями.


#### Использование SAMBA на клиенте
```
yum install samba-client
```
SAMBA-клиент позволяет получать список ресурсов с сервера SAMBA и подключаться к нему.
```
smbclient -L 10.51.21.7 -U%
smbclient //vmnested.localdomain/dir1 -U otus
```
Используя cifs можно монтировать ресурсы SAMBA как обычные устройства:
```
yum install cifs-utils
mount -t cifs //vmnested.localdomain/dir1 /mnt/smb/dir2 -o user=otus
```
Также можно использовать автомонтирование /etc/fstab
```
cat /etc/fstab
//vmnested.localdomain/dir1 /mnt/smb/dir1 cifs credentials=/root/.smb,iocharset=utf8 0 0
```
И также на уже смонтированные устройства можно натравить ```/usr/lib/systemd/system-generators/systemd-fstab-generator```, который проанализировав ```/etc/fstab``` в директорию ```/tmp``` положит готовые юниты для systemd.