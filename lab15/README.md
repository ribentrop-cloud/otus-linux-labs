#### Резервное копирование

##### Задание

Настроить стенд Vagrant с двумя виртуальными машинами: server и client.

Настроить политику резервного копирования директории /etc с сервера client:
 - Полное резервное копирование - 1 раз в день;
 - Инкрементальное резервное копирование - каждые 10 минут;
 - Дифференциальное резервное копирование - каждые 30 минут.
Убедиться в работоспособности системы резервного копирования, запустив её на 2 часа. 

Для проверки предъявить вывод команд list jobs и list files jobid=<id>, а также сами конфиги bacula-*

Дополнительно:
 - настроить опции сжатия, шифрования и дедупликации. 

##### Результат

Все можно проверить на стенде (Vagrant + ansible provisioner).

Привожу скриншоты:
  - Вывод команды [list jobs](pics/list_jobs.png)
  - Окончание вывода команды [list files jobid=1](pics/list_files_jobid_1.png)
  - Отметки о включенных функциях [сжатия, шифрования](pics/compress_and_encrypt.png)
  - Отметки о включенной файловой(!) дедупликации:
    - [Базовое задание](pics/file_dedupl_base.png)
    - [Следующее задание](pics/file_dedupl_job2.png)