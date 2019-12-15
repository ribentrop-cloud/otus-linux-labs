#!/usr/bin/env bash
#
# Первое задание!
# Ставим отправитель почты для извещений
yes | yum -y -q install mailx
# Развертываем монитор слова в логах
cp /vagrant/task1/mbfx_logmon.service /etc/systemd/system/mbfx_logmon.service
cp /vagrant/task1/mbfx_logmon.timer /etc/systemd/system/mbfx_logmon.timer
cp /vagrant/task1/mbfx_logmon /etc/sysconfig/mbfx_logmon
# Вручную мы этот скрипт врядли будем запускать, поэтому расположим его в каталоге для приложений
cp /vagrant/task1/mbfx_logmon.sh /opt/mbfx_logmon.sh
# Развернём тестовый файл
cp /vagrant/task1/monitor.log /var/log/mbfx_monitor_test.log
# Включим
systemctl daemon-reload
systemctl enable mbfx_logmon.service
systemctl enable mbfx_logmon.timer
systemctl start mbfx_logmon.service
systemctl start mbfx_logmon.timer
# Подождём и проверим
echo "Wait 30 sec for testing."
sleep 35
systemctl status mbfx_logmon.service
systemctl status mbfx_logmon.timer
# Первое задание выполнено!
#
# Второе задание!
# Подключаем epel и ставим spawn-fcgi
yes | yum -y -q install epel-release
yes | yum -y -q install spawn-fcgi
# Для корректной работы нам нужно приложение,
# которое поддерживает интерфейс CGI (FastCGI, в частности)
# Пусть это будет apache2 с соответствующим модулем (httpd, mod_fcgid)
yes | yum -y -q install httpd mod_fcgid
rpm -ql spawn-fcgi
# Анализ файлов из пакета spawn-fcgi показывает, что он имеет скрипт init.d
# и, внезапно, файл /etc/sysconfig/spawn-cgi с закомментированными параметрами-примерами
# Значит дальше будет чуть проще: нам подходят параметры из примера. Раскомментируем.
sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi
# По ходу нам понадобится php ...
yes | yum -y -q install php php-cli
# Установим подготовленный unit-файл
cp /vagrant/task2/spawn-fcgi.service /etc/systemd/system/spawn-fcgi.service
# Включим
systemctl enable spawn-fcgi
systemctl start spawn-fcgi
# И проверим
systemctl status spawn-fcgi
# Работает!
# Второе задание выполнено!
#
# Третье задание!
#
# Для запуска нескольких (пары) инстансов apache нам потребуется 2 разынх конфига,
# т.к. нам нужны как минимум 2 разных PID и 2 разных порта для прослушивания
# для нацеливания на разные конфиги будем использовать опцию %I
# в /usr/lib ломать ничего не будем - скопируем в административный каталог и будем делать всё там
cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
sed -i 's/EnvironmentFile=\/etc\/sysconfig\/httpd/EnvironmentFile=\/etc\/sysconfig\/httpd-config-%I/' /etc/systemd/system/httpd@.service
sed -i 's/Description=The Apache HTTP Server/Description=The Apache HTTP Server (multiconfig edition by mbfx)/' /etc/systemd/system/httpd@.service
# Подготовим файлы конфигураций httpd
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-1.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-2.conf
# Делаем бекапы исходных файлов
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.backup
# Настроим первый веб-сервер
#sed -i 's/Listen 80/Listen 80/' /etc/httpd/conf/httpd-1.conf
sed -i 's/"logs\/error_log"/"logs\/error_log-1"/' /etc/httpd/conf/httpd-1.conf
sed -i 's/"logs\/access_log"/"logs\/access_log-1"/' /etc/httpd/conf/httpd-1.conf
sed -i '/ServerRoot "\/etc\/httpd"/a PidFile \/var\/run\/httpd-1.pid' /etc/httpd/conf/httpd-1.conf
# Настроим второй веб-сервер
sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd-2.conf
sed -i 's/"logs\/error_log"/"logs\/error_log-2"/' /etc/httpd/conf/httpd-2.conf
sed -i 's/"logs\/access_log"/"logs\/access_log-2"/' /etc/httpd/conf/httpd-2.conf
sed -i '/ServerRoot "\/etc\/httpd"/a PidFile \/var\/run\/httpd-2.pid' /etc/httpd/conf/httpd-2.conf
# Включаем окружение в systemd для наших httpd
cp /etc/sysconfig/httpd /etc/sysconfig/httpd-config-1
sed -i 's/#OPTIONS=/OPTIONS=-f \/etc\/httpd\/conf\/httpd-1.conf/' /etc/sysconfig/httpd-config-1
cp /etc/sysconfig/httpd /etc/sysconfig/httpd-config-2
sed -i 's/#OPTIONS=/OPTIONS=-f \/etc\/httpd\/conf\/httpd-2.conf/' /etc/sysconfig/httpd-config-2
# Снова бекапы исходных файлов
mv /etc/sysconfig/httpd /etc/sysconfig/httpd.backup
# Выключаем основной httpd
systemctl disable httpd
systemctl daemon-reload
# Включаем наши новые httpdшки 
systemctl enable httpd@1
systemctl enable httpd@2
systemctl start httpd@1
sleep 3
systemctl start httpd@2
sleep 3
# Проверяем запуск
systemctl status httpd@1
systemctl status httpd@2
# Смотрим слушаются ли наши порты.
ss -tpnl | grep httpd | awk '{print $1,$4,$6}'
# Работает!
# Третье задание выполнено.
exit 0
