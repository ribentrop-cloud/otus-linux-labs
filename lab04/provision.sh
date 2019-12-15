#!/usr/bin/env VAR=VALUE bash
# Устанавливаем nginx
if [ ! -e /etc/yum.repos.d/nginx.repo ] ;
	then
	echo '[nginx]' > /etc/yum.repos.d/nginx.repo
	echo 'name=nginx repo' >> /etc/yum.repos.d/nginx.repo
	echo 'baseurl=http://nginx.org/packages/centos/$releasever/$basearch/' >> /etc/yum.repos.d/nginx.repo
	echo 'gpgcheck=0' >> /etc/yum.repos.d/nginx.repo
	echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo
fi
yes | yum -y update
yes | yum -y install nginx wget mailx
# Проверяем, есть ли тестовые логи для скрипта
# Если нет, то ставим их и адаптируем под работу в настоящем времени
if [ ! -d /var/log/nginx ] ;
	then
	mkdir /var/log/nginx
fi
if [ ! -e /var/log/nginx/nginx_logs ] ;
	then
	wget https://raw.githubusercontent.com/elastic/examples/master/Common%20Data%20Formats/nginx_logs/nginx_logs --quiet -O /var/log/nginx/nginx_logs
fi
sed -i 's/2015/2019/' /var/log/nginx/nginx_logs
# Развертываем парсер логов, и прописываем в crontab
cp /vagrant/script.sh /usr/local/bin/nginx_parser.sh
echo "0 * * * * root bash /usr/local/bin/nginx_parser.sh /var/log/nginx/nginx_logs" >> /etc/crontab
systemctl restart crond

