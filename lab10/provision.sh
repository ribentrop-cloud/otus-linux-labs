#!/usr/bin/bash
#
# Aleksandr Gavrik, mbfx@mail.ru, 2019
#
# Установим docker и необходимые для его работы компоненты
echo "Устанавливаем docker"
yes | yum install -y -q yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yes | yum install -y -q docker-ce docker-ce-cli containerd.io
# Запустим docker и проверим его работоспособность
echo "Запускаем docker и проверяем"
systemctl enable docker
systemctl start docker
systemctl status docker
# Запустим ранее написанный dockerfile и проверим его на работоспособность
# Этот файл берет образ официальный образ centos и устанавливает туда httpd из нашего репозитория
echo "Собираем образ nginx"
docker build /vagrant/task1/ -t mbfx/otus_lab10_task1_nginx:v1
# Запускаем и проверяем
echo "Запускаем собранный образ nginx"
docker run -d -p 8080:80 --name task1 mbfx/otus_lab10_task1_nginx:v1 1>/dev/null
sleep 3
echo "Делаем запрос к nginx в контейнере"
curl http://localhost:8080/ 2>/dev/null
echo "Останавливаем и удаляем остановленный контейнер"
docker stop task1 1>/dev/null
docker rm task1 1>/dev/null
# Работает!
# Теперь запушим наш образ на DockerHub
# sudo docker login
# sudo docker push mbfx/otus_lab10_task1_nginx:v1
# Смотреть тут https://hub.docker.com/r/mbfx/otus_lab10_task1_nginx
# 
# А теперь попробуем очистить кеш docker, скачать наш образ и запустить его
echo "Удаляем образ nginx из кеша"
yes | docker rmi mbfx/otus_lab10_task1_nginx:v1 -f 1>/dev/null
echo "Запускам образ nginx, получая его из docker hub"
docker run -d -p 8080:80 --name task1 mbfx/otus_lab10_task1_nginx:v1 1>/dev/null
sleep 3
echo "Делаем запрос к nginx в контейнере"
curl http://localhost:8080/ 2>/dev/null
# Работает!
echo "Останавливаем и удаляем остановленный контейнер"
docker stop task1 1>/dev/null
docker rm task1 1>/dev/null
echo "Первое задание выполнено. Жём 10 сек и начинаем выполнять дополнительное"
#
#
# Устанавливаем docker-compose
echo "Устанавливаем docker compose"
yes | yum install -y -q epel-release
yes | yum install -y -q python-pip
pip install --upgrade pip 1>/dev/null
pip install docker-compose 1>/dev/null
docker-compose version
# Запускаем
echo "Запускаем docker-compose файл. Заранее собранные образы подтянутся из docker hub"
cd /vagrant/task2
docker-compose up -d
# Проверим, отдается ли нам php info
echo "Проверяем работоспособность."
sleep 3
curl http://localhost:8080/ 2>/dev/null
exit 0
