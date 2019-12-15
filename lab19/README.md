#### Split-DNS

#### Задание

 - взять стенд https://github.com/erlong15/vagrant-bind
   - zones: dns.lab, reverse dns.lab and ddns.lab
   - ns01 (192.168.50.10) - master, recursive, allows update to ddns.lab
   - ns02 (192.168.50.11) - slave, recursive
   - client (192.168.50.15) - used to test the env, runs rndc and nsupdate
   - zone transfer: TSIG key
 - добавить еще один сервер client2
   - client2 (192.168.50.16)

 - завести в зоне dns.lab
   - имя web1, которое смотрит на client
   - имя web2, которое смотрит на client2

 - завести еще одну зону newdns.lab
 - завести в зоне newdns.lab
   - имя www, которое смотрит на обоих клиентов

 - настроить split-dns
   - client - видит обе зоны, но в зоне dns.lab только web1
   - client2 - видит только зону dns.lab

Дополнительно:
 - настроить все без выключения selinux

#### Решение.

1. Добавляем сервер [client2](Vagrantfile#L32-L35);
2. Заводим имена web1 и web2 как [CNAME](provisioning/files/ns01/named.dns.lab#L20-L21) на client и client2;
3. Не забудем про [PTR-записи](provisioning/files/ns01/named.50.168.192.rev#L22-L23);
4. Заводим новую зону [newdns.lab](provisioning/files/ns01/named.newdns.lab#L1-L19);
5. Не забудем про [PTR-записи](provisioning/files/ns01/named.50.168.192.rev#L24-L27) - за них у нас будут отвечать серверы зоны dns.lab;
6. Заводим зоне newdns.lab [имя www](provisioning/files/ns01/named.newdns.lab#L20-L21), которое смотрит на обоих клиентов; 
7. Настроим split-DNS:
 - Создадим привязки(acl) для view на [master](provisioning/files/ns01/named.conf#L46-L52) и на [slave](provisioning/files/ns02/named.conf#L46-L52);
 - Создадим отдельный [файл зоны для view client](provisioning/files/ns01/named.dns.lab.view1);
 - Создадим view для client на [master](provisioning/files/ns01/named.conf#L60-L102) и на [slave](provisioning/files/ns02/named.conf#L60-L101);
 - Создадим view для client2 на [master](provisioning/files/ns01/named.conf#L104-L131) и на [slave](provisioning/files/ns02/named.conf#L103-L131);
 - Создадим default view (для всех остальных запросов) на [master](provisioning/files/ns01/named.conf#L133-L175) и на [slave](provisioning/files/ns02/named.conf#L133-L174);
8. SELinux дополнительно настраивать нет необходимости, т.к. достаточно положить файлы зон в заранее подготовленные для них места согласно документации:
 - /var/named/ для держателей master-zones;
 - /var/named/dynamic/ для зон, поддерживающих динамическое обновление;
 - /var/named/slaves/ для поддержки slave-zones.

P.S. Dynamic DNS, трансфер зон с ns01 на ns02 и удаленное управление через rndc с client работают.