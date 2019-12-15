Первые шаги с Ansible


Подготовить [стенд на Vagrant](Vagrantfile) как минимум с одним сервером. На этом сервере, используя ansible playbook, необходимо развернуть nginx со следующими условиями:
- использовать [модуль yum/apt](ansible_repo/roles/install_nginx/tasks/main.yml);
- конфигурационные файлы сделать из [шаблона jinja2](ansible_repo/roles/install_nginx/templates/nginx.conf.j2) с перемененными;
- установить [nginx в enabled](ansible_repo/roles/install_nginx/tasks/main.yml) в systemd;
- использовать [notify для старта nginx](ansible_repo/roles/install_nginx/handlers/main.yml) после установки;
- nginx должен слушать на 8080 (использовать [переменные в ansible](ansible_repo/host_vars/server1.yml)).


Дополнительно: сделать все вышеперечисленное в виде [роли ansible](ansible_repo/start.yml) (не playbook).


