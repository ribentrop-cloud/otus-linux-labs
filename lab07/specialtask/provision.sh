#!/usr/bin/env bash
# Устанавливаем Atlassian Jira
#
# Обновим ОС и установим удобные нам инструменты
echo "Скачиваем и устанавливаем обновления + wget."
yes | yum -y -q update &>/dev/null
yes | yum -y -q install wget &>/dev/null
# Создадим каталог для программы
mkdir /opt/atlassian
cd /opt/atlassian/
# Скачаем инсталлятор и разрешим его запуск
echo "Скачиваем и устанавливаем Atlassian Jira."
wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.2.1-x64.bin --directory-prefix=/opt/atlassian/ --quiet
chmod +x /opt/atlassian/atlassian-jira-software-8.2.1-x64.bin
# Установим программу, используя подготовленный заранее файл ответов
cp /vagrant/jira/response.varfile /opt/atlassian/response.varfile
bash /opt/atlassian/atlassian-jira-software-8.2.1-x64.bin -q -varfile /opt/atlassian/response.varfile
# Установим рекомендуемую СУБД для Jira
echo "Скачиваем и устанавливаем postgresql."
yes | yum -y -q install postgresql-server &>/dev/null
# Экспортируем переменную для файлов pgsql
echo "Настроиваем postgresql."
export PGDATA=/var/lib/pgsql/data
# Инициализируем СУБД
postgresql-setup initdb
# Включаем СУБД
systemctl enable postgresql
systemctl start postgresql
# Конфигурируем СУБД для Jira заранее подготовленным файлом
echo "Настраиваем postgresql для работы с Jira."
sudo -u postgres psql -f /vagrant/jira/jiradb.sql
# Копируем заранее подготовленный файл конфигурации БД для Jira
# Это подравленный под наши нужды сэмпл с сайта atlassian
echo "Настраиваем Jira для работы с postgresql."
cp /vagrant/jira/dbconfig.xml /var/atlassian/application-data/jira/dbconfig.xml
# Устанавливаем nginx (сделаем reverse-proxy https, что уж)
echo "Скачиваем и устанавливаем nginx."
yes | yum -y -q install epel-release &>/dev/null
yes | yum -y -q install nginx &>/dev/null
# Разрешаем устанавливать внешние соединения (selinux)
echo "SELinux - разрешаем подключения по сети."
setsebool -P httpd_can_network_connect 1
# Добавим в коннектор jira информацию о прокси
echo "Настраиваем Jira для работы с nginx."
sed -i 's/bindOnInit="false"/bindOnInit="false" proxyName="192.168.11.110" proxyPort="443" scheme="https" secure="true"/' /opt/atlassian/jira/conf/server.xml
# Добавим заранее подготовленные конфигурационные файлы nginx
echo "Настраиваем nginx для работы с Jira."
mv /etc/nginx/nginx.conf /etc/nginx/nginx.backup
cp /vagrant/nginx/nginx.conf /etc/nginx/nginx.conf
cp /vagrant/nginx/nonssl.conf /etc/nginx/conf.d/nonssl.conf
cp /vagrant/nginx/jira.conf /etc/nginx/conf.d/jira.conf
# Сделаем самоподписанный ssl сертификат
echo "Генерируем и устанавливаем самоподписанный сертификат для nginx."
mkdir /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/jira.key -out /etc/nginx/ssl/jira.crt -subj "/C=RU/ST=Kaliningrad/L=Kaliningrad/O=localhost/OU=localmachine/CN=localhost" &>/dev/null
# Внесем изменения в pg_hba.conf - нам нужен md5 для локальных соединений
echo "Конфигурируем postgresql использовать md5 для локальных соединений."
sed -i 's/127.0.0.1\/32            ident/127.0.0.1\/32            md5/' /var/lib/pgsql/data/pg_hba.conf
sed -i 's/::1\/128                 ident/::1\/128                 md5/' /var/lib/pgsql/data/pg_hba.conf
# Включим и перезапустим nginx/postgresql и jira (пока используем init.d совместимые скрипты для проверки)
echo "Перезапускаем СУБД postgresql."
systemctl restart postgresql
sleep 3
echo "Включаем nginx."
systemctl enable nginx
systemctl start nginx
#
# Приступим-с.
#
# Выключим systemd jira
echo "Выключаем Jira."
systemctl stop jira
systemctl disable jira
# Сделаем бекап оригинального catalina.sh
echo "Заменяем тот костыль на наш любимый: catalina.sh"
mv /opt/atlassian/jira/bin/catalina.sh /opt/atlassian/jira/bin/catalina.backup
# Поместим на его место переписанный catalina.sh под systemd
cp /vagrant/catalina.sh /opt/atlassian/jira/bin/catalina.sh
chmod +x /opt/atlassian/jira/bin/catalina.sh
# Скопируем заранее подготовленный jira.service и jira-pre.service
echo "Размещаем файлы systemd для запуска Jira."
cp /vagrant/jira.service /etc/systemd/system/jira.service
cp /vagrant/jira-pre.service /etc/systemd/system/jira-pre.service
# Создадим пустой EnvironmentFile и дадим на него права пользователю jira
touch /etc/sysconfig/jiraenv
chown jira /etc/sysconfig/jiraenv
# Перестраиваем systemd
echo "Включаем Jira. Ждём 30 сек до проверки."
systemctl daemon-reload
# Включаем, поехали!
systemctl enable jira
systemctl start jira
sleep 30
echo "Проверяем."
systemctl status jira
sleep 5
echo "Выключаем. Ждём 30 сек до проверки."
systemctl stop jira
sleep 30
systemctl status jira
echo "Выполнено!"
exit 0

