FROM centos:centos7.6.1810
MAINTAINER mbfx
RUN touch /etc/yum.repos.d/own_rpm_repo.repo && \
    echo "[own_rpm_repo]" > /etc/yum.repos.d/own_rpm_repo.repo && \
    echo "name=own_rpm_repo" >> /etc/yum.repos.d/own_rpm_repo.repo && \
    echo "baseurl=http://192.168.11.108/own_rpm_repo/" >> /etc/yum.repos.d/own_rpm_repo.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/own_rpm_repo.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/own_rpm_repo.repo && \
    yum-config-manager --disable * && \
    yum-config-manager --enable own_rpm_repo && \
    yes | yum install -y httpd
COPY index.html /var/www/html/
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
EXPOSE 80

