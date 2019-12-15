#### MySQL: развернуть proxysql

#### Задание

Дана машина vmnested (10.51.21.7) на которой нужно настроить proxysql для Percona xtraDB cluster, который включает в себя:
  - xtrabd01 (10.51.21.10);
  - xtrabd02 (10.51.21.11);
  - xtrabd03 (10.51.21.12).

#### Выполнение

#### Установка и запуск

Добавляем репозиторий:
```
cat <<EOF | tee /etc/yum.repos.d/proxysql.repo
[proxysql_repo]
name= ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.0.x/centos/\$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/repo_pub_key
EOF
```

Устанавливаем proxysql:
```
yum install proxysql
```

Не забываем, что для работы proxysql использует клиент mysql. Установите нужную версию. В общем случае выглядит так:
```
yum install mysql-client
```

Проверим установленную версию:
(на момент написания этой заметки актуальная версия - 2.0.6)
```
proxysql --version
```

Запуск, остановка и автозагрузка управляются через systemctl.
```
systemctl enable proxysql
systemctl start proxysql
```
Также есть альтернативный способ останавливать и перезапускать proxysql через интерфейс администратора.

#### Первичная настройка

Настройка proysql может производиться двумя способами: первоначальная, через конфигурационный файл, и основная - непосредственно через интерфейс администратора. Поскольку мы уже запустили proxysql с параметрами по-умолчанию, то дальнейшая настройка будет через интерфейс администратора, но всегда можно реинициализировать proxysql из файла командой ```service proxysql initial```.

Вход в интерфейс администратора:
```
mysql -u admin -padmin -h 127.0.0.1 -P6032 --prompt='Admin> '
```

Как видно, логин и пароль по-умолчанию: admin/admin. Сменим его.
```
UPDATE global_variables SET variable_value='admin:admin_password' WHERE variable_name='admin-admin_credentials';
```
Здесь важно понять, что изменения в данном случае не будут приняты сразу, т.к. конфигурация proxysql имеет несколько уровней: memory, runtime & disk. Сейчас мы внесли изменения на уровень memory. Чтобы изменения вступили в силу, нужно скопировать их в уровень runtime командой:
```
LOAD ADMIN VARIABLES TO RUNTIME;
```
А для сохранения использовать команду:
```
SAVE ADMIN VARIABLES TO DISK;
```
При этом нужно обратить внимание, что сейчас мы произвели действия с командой группой переменных ADMIN, которые отвечают за администрирование. Помимо этой группы, есть ещё другие группы: MYSQL SERVERS, MYSQL QUERY RULES, MYSQL VARIABLES и MYSQL USERS.

Вход в интерфейс администратора с новым паролем:
```
mysql -u admin -p -h 127.0.0.1 -P6032 --prompt='Admin> '
```
Текущий статус нод можно проверить командой:
```
SELECT * FROM mysql_servers;
```
Но сейчас там ничего нет :)

#### Настройка мониторинга нод кластера

Для начала создадим на нодах(!) пользователя, которому будет разрешено получать сведения о состоянии групп репликации:
```
CREATE USER 'monitor'@'10.51.21.7' IDENTIFIED BY 'monitor_password';
GRANT SELECT on sys.* to 'monitor'@'10.51.21.7';
GRANT USAGE ON *.* TO 'monitor'@'10.51.21.7';
FLUSH PRIVILEGES;
```
При корректно настроенной репликации эти сведения достаточно будет ввести на мастер-ноде и они реплицируются на остальные серверы в этом кластере.

Теперь нужно создать или обновить пользователя для мониторинга внутри самого proxysql:
```
UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='monitor_password' WHERE variable_name='mysql-monitor_password';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

proxysql хранит данные мониторинга в собственной базе данных:
```
SHOW DATABASES;
SHOW TABLES FROM monitor;
```
Можно получить оттуда разного рода информацию, например, так:
```
SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 10;
SELECT * FROM monitor.mysql_server_ping_log ORDER BY time_start_us DESC LIMIT 10;
```
Но сейчас там ничего нет, т.к. ноды не добавлены. Сделаем.

#### Менеджмент нод внутри proxysql

Добавим ноды в группу для чтения (первой ноде повысим приоритет):
```
INSERT INTO mysql_servers(hostgroup_id,hostname,port,weight) VALUES (3,'10.51.21.10',3306,100);
INSERT INTO mysql_servers(hostgroup_id,hostname,port,weight) VALUES (3,'10.51.21.11',3306,50);
INSERT INTO mysql_servers(hostgroup_id,hostname,port,weight) VALUES (3,'10.51.21.12',3306,50);
```
Просмотрим их статус:
```
SELECT * FROM mysql_servers;
SELECT hostgroup_id, hostname, port, status FROM mysql_servers;
```
И здесь мы впервые сталкиваемся с понятием hostgroup. Группы хостов в proxysql - это, фактически, роли, которые назначаются нодам. Виды хостгрупп могут различаться в зависимости от того, к какому кластеру вы пытаетесь прикрутить proxysql: для классической master/slave async/semi-async репликации ипользуются writer_hostgroup/reader_hostgroup в таблице mysql_replication_hostgroups, в случае групповой репликации или кластера InnoDB используются 4 роли (writer_hostgroup, backup_writer_hostgroup, reader_hostgroup, offline_hostgroup) из таблицы mysql_group_replication_hostgroups. В нашем же случае (Percona XtraDB Cluster/Galera Cluster) используется mysql_galera_hostgroups с группами writer_hostgroup, backup_writer_hostgroup, reader_hostgroup, offline_hostgroup. Сейчас мы:
- назначим группу 1 на запись (сюда будут автоматом добавлены ноды из группы 3 с установленным set global read_only = 0 в количестве, не превышающем ограничение, которое будет установлено ниже);
- назначим использование нод группы 2 на запись, если ноды группы 1 недоступны (также ноды этой группы могут использоваться на чтение, если на этих нодах стоит set global read_only = 0);
- назначим группу 3 на чтение (также сюда попадут ноды с установенным set global read_only = 1);
- назначим группу 4 как группу недоступных хостов;
- включим эту конфигурацию;
- ограничим максимальное количество нод в группе 1 (остальные будут помещены в группу 2 автоматически);
- разрешим автоматическое удаление ноды из группы 3 при её назначении в группу 1;
- зададим максимальное количество записей, на которое может отстать нода перед тем, как её переведут в состояние OFFLINE).
```
INSERT INTO mysql_galera_hostgroups(writer_hostgroup, backup_writer_hostgroup, reader_hostgroup, offline_hostgroup, active, max_writers, writer_is_also_reader, max_transactions_behind, comment) VALUES (1, 2, 3, 4, 1, 1, 0, 20, 'Percona XtraDB Cluster');
SELECT * FROM mysql_galera_hostgroups\G
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

#### Пользователь для проксирования

Для начала создадим на нодах(!) пользователя для подключения proxysql (используются те же учетные данные, что и при подключении приложения к proxysql):
```
CREATE USER 'proxysql_user'@'%' IDENTIFIED BY 'proxysql_user_password';
GRANT ALL PRIVILEGES on 'otus-test'.* to 'proxysql_user'@'%';
FLUSH PRIVILEGES;
```
Создадим пользователя на proxysql(!), которым будут подключаться наши приложения:
```
INSERT INTO mysql_users(username, password, active, default_hostgroup, max_connections, comment) VALUES ('proxysql_user', 'proxysql_user_password', 1, 1, 20000, 'to Percona XtraDB Cluster');
SELECT * FROM mysql_users WHERE username='proxysql_user'\G
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```
Здесь мы сразу указываем, что все запросы будут обрабатываться хостгруппой 1, кроме тех, что обрабатываются в рамках специальных очередей (о них читайте в документации).

#### Проверка

Напомню, что итого у нас 3 ноды в режиме multi-master, перед которыми стоит proxysql, проксирующий запросы на запись на ноду 1, а запросы на чтение на ноды 2 и 3.
Проведём тестирование пакетом sysbench:
```
yum install sysbench
sysbench --mysql-host=127.0.0.1 --mysql-port=6033 --mysql-user=proxysql_user --mysql_password='proxysql_user_password' --db-driver=mysql --mysql-db='otus-test' /usr/share/sysbench/oltp_read_write.lua prepare
```
В один поток:
```
sysbench --mysql-host=127.0.0.1 --mysql-port=6033 --mysql-user=proxysql_user --mysql_password='proxysql_user_password' --threads=1 --db-driver=mysql --mysql-db='otus-test' /usr/share/sysbench/oltp_read_write.lua run

sysbench 1.0.17 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 1
Initializing random number generator from current time


Initializing worker threads...

Threads started!

SQL statistics:
    queries performed:
        read:                            10836
        write:                           2995
        other:                           1649
        total:                           15480
    transactions:                        774    (77.33 per sec.)
    queries:                             15480  (1546.67 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          10.0060s
    total number of events:              774

Latency (ms):
         min:                                    9.39
         avg:                                   12.92
         max:                                   62.96
         95th percentile:                       20.74
         sum:                                 9999.25

Threads fairness:
    events (avg/stddev):           774.0000/0.00
    execution time (avg/stddev):   9.9993/0.00
```

В 10 потоков:
```
sysbench --mysql-host=127.0.0.1 --mysql-port=6033 --mysql-user=proxysql_user --mysql_password='proxysql_user_password' --threads=10 --db-driver=mysql --mysql-db='otus-test' /usr/share/sysbench/oltp_read_write.lua run

sysbench 1.0.17 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 10
Initializing random number generator from current time


Initializing worker threads...

Threads started!

SQL statistics:
    queries performed:
        read:                            30716
        write:                           8601
        other:                           4555
        total:                           43872
    transactions:                        2192   (218.51 per sec.)
    queries:                             43872  (4373.38 per sec.)
    ignored errors:                      2      (0.20 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          10.0292s
    total number of events:              2192

Latency (ms):
         min:                                   16.16
         avg:                                   45.71
         max:                                  152.34
         95th percentile:                       68.05
         sum:                               100198.01

Threads fairness:
    events (avg/stddev):           219.2000/1.60
    execution time (avg/stddev):   10.0198/0.01
```
Отдельно отмечу, что если настроить proxysql так, чтобы запросы на запись обрабатывались сразу 3 нодами, то ноды при нагрузке просто-напросто передерутся из-за блокировок. Выглядеть это будет так:
```
FATAL: mysql_stmt_execute() returned error 1317 (Query execution was interrupted) for query 'UPDATE sbtest1 SET k=k+1 WHERE id=?'
FATAL: `thread_run' function failed: /usr/share/sysbench/oltp_common.lua:458: SQL error, errno = 1317, state = '70100': Query execution was interrupted
Error in my_thread_global_end(): 1 threads didn't exit
```
Также proxysql поддерживает autofailover - можно повыключать некоторые ноды и погонять тесты. Текущее состояние нод в proxysql посмотреть можно так:
```
SELECT hostgroup_id,hostname,port,status FROM runtime_mysql_servers;
```