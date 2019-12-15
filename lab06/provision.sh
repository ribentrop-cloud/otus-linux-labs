#!/usr/bin/env bash
# Устанавливаем минимально необходимые пакеты
yes | yum install -y -q wget rpmdevtools rpm-build tree yum-utils createrepo
# Переходим в домашний каталог пользователя
cd ~
# Будем собирать httpd последней на данный момент версии со своими опциями.
# Тянем исходники с сайта apache.org
wget http://mirror.linux-ia64.org/apache/httpd/httpd-2.4.39.tar.bz2 --directory-prefix=$HOME --quiet
wget https://www-us.apache.org/dist/apr/apr-1.7.0.tar.bz2 --directory-prefix=$HOME --quiet
wget https://www-us.apache.org/dist//apr/apr-util-1.6.1.tar.bz2 --directory-prefix=$HOME --quiet
# Делаем из архива с tar.bz2 пакет SRPM и устанавливаем его.
rpmbuild -ts httpd-2.4.39.tar.bz2 1>/dev/null
rpmbuild -ts apr-1.7.0.tar.bz2 1>/dev/null
rpmbuild -ts apr-util-1.6.1.tar.bz2 1>/dev/null
# Установим полученный SRPM и получим в дереве rpmbuild архив с исходниками и spec-файл
rpm -i $HOME/rpmbuild/SRPMS/httpd-2.4.39-1.src.rpm
rpm -i $HOME/rpmbuild/SRPMS/apr-1.7.0-1.src.rpm
rpm -i $HOME/rpmbuild/SRPMS/apr-util-1.6.1-1.src.rpm
# Исходный архив нам уже не нужен
rm $HOME/httpd-2.4.39.tar.bz2
rm $HOME/apr-1.7.0.tar.bz2
rm $HOME/apr-util-1.6.1.tar.bz2
tree ~
# Установим все зависимости, перечисленные в spec-файле
yes | yum install -y -q epel-release
yes | yum-builddep -y -q $HOME/rpmbuild/SPECS/httpd.spec
yes | yum-builddep -y -q $HOME/rpmbuild/SPECS/apr.spec
yes | yum-builddep -y -q $HOME/rpmbuild/SPECS/apr-util.spec
# Добавим в spec файл опции поддержки ldap и lua в режиме shared
sed -i 's/--disable-imagemap/--disable-imagemap --enable-ldap=shared --enable-lua=shared/' $HOME/rpmbuild/SPECS/httpd.spec
# ^_^ Починим баг spec-файла версии 2.4.39
sed -i '/%{_libdir}\/httpd\/modules\/mod_watchdog.so/a %{_libdir}\/httpd\/modules\/mod_socache_redis.so' $HOME/rpmbuild/SPECS/httpd.spec
# Установим окружение для сборки
yes | yum install -y -q cpp gcc 
# Собираем требуемые для основной сборки пакеты
rpmbuild --clean -bb $HOME/rpmbuild/SPECS/apr.spec
rpmbuild --clean -bb $HOME/rpmbuild/SPECS/apr-util.spec
# Устанавливаем вручную только что собранные последние версии нужных пакетов
yum -y -q remove apr apr-devel apr-util apr-util-devel
sudo rpm -i rpmbuild/RPMS/x86_64/apr-1.7.0-1.x86_64.rpm
sudo rpm -i rpmbuild/RPMS/x86_64/apr-devel-1.7.0-1.x86_64.rpm
sudo rpm -i rpmbuild/RPMS/x86_64/apr-util-1.6.1-1.x86_64.rpm
sudo rpm -i rpmbuild/RPMS/x86_64/apr-util-devel-1.6.1-1.x86_64.rpm
yes | yum install -y -q mailcap
# Собираем httpd и устанавливаем его
rpmbuild --clean -bb $HOME/rpmbuild/SPECS/httpd.spec
sudo rpm -i rpmbuild/RPMS/x86_64/httpd-2.4.39-1.x86_64.rpm
# Теперь у нас есть собранный apache 2.4.39 - на нём и развернем репозиторий.
# Сначала сделаем локальный репозиторий из наших пакетов.
mkdir $HOME/own_rpm_repo
mkdir $HOME/own_rpm_repo/x86_64
cp $HOME/rpmbuild/RPMS/x86_64/*.rpm $HOME/own_rpm_repo/x86_64
createrepo $HOME/own_rpm_repo
# Теперь подготовим корень apache и запишем туда копию локального репозитория
rm -rf /var/www/html/*
mkdir /var/www/html/own_rpm_repo
chmod 777 /var/www/html/own_rpm_repo
cp -r $HOME/own_rpm_repo/* /var/www/html/own_rpm_repo
# Включим apache и проверим его работу
systemctl enable httpd
systemctl start httpd
systemctl status httpd
curl http://localhost/own_rpm_repo/
# Теперь добавим наш репозиторий в список системных репозиториев
touch /etc/yum.repos.d/own_rpm_repo.repo
echo "[own_rpm_repo]" > /etc/yum.repos.d/own_rpm_repo.repo
echo "name=own_rpm_repo" >> /etc/yum.repos.d/own_rpm_repo.repo
echo "baseurl=http://localhost/own_rpm_repo/" >> /etc/yum.repos.d/own_rpm_repo.repo
echo "enabled=1" >> /etc/yum.repos.d/own_rpm_repo.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/own_rpm_repo.repo
# Проверим, что наш репозиторий виден: сделаем запрос по yum и отфильтруем наш репозиторий
yum list | grep own_rpm_repo
# Видим там наши пакеты :)
# Переустановим оттуда пакеты apr* и apr-util*, которые мы ставили вручную
yum -y -q reinstall apr apr-devel apr-util apr-util-devel
# Работает!
# Осталось только почистить мусор из rpmbuild, если там что-то осталось
rm -rf $HOME/rpmbuild/BUILD/*
rm -rf $HOME/rpmbuild/BUILDROOT/*
##
### Теперь начнем работать с docker
##
# Установим docker и необходимое для его работы компоненты
yes | yum install -y -q yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yes | yum install -y -q docker-ce docker-ce-cli containerd.io
# Запустим docker и проверим его работоспособность
systemctl enable docker
systemctl start docker
systemctl status docker
docker run hello-world
docker rmi hello-world
# Запустим ранее написанный dockerfile и проверим его на работоспособность
# Этот файл берет образ официальный образ centos и устанавливает туда httpd из нашего репозитория
docker build /vagrant/ -t httpd:v1
# Запускаем и проверяем
docker run -p8080:80 -dit httpd:v1
curl http://localhost:8080/
# Работает!
# Теперь запушим наш образ на DockerHub
# Сделаем корректные тэги 
# docker tag httpd:v1 mbfx/otus_lab6_httpd:v1
# Залогинимся
# sudo docker login
# И пушим :)
# sudo docker push mbfx/otus_lab6_httpd:v1
# Смотреть тут https://hub.docker.com/r/mbfx/otus_lab6_httpd
# 
# А теперь попробуем очистить кеш docker, скачать наш образ и запустить его
yes | docker rmi mbfx/otus_lab6_httpd:v1 -f
docker run -p8081:80 -dit mbfx/otus_lab6_httpd:v1
curl http://localhost:8081/
# Работает!
exit 0

