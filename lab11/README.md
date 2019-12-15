#### PAM


##### Задание:
- Запретить всем пользователям, кроме группы admin логин в выходные и праздничные дни.

##### Решение:
- [YAML-файл с комментарими](ansible_repo/roles/only_admin_on_weekends/tasks/main.yml)
- [Шаблон скрипта проверки](ansible_repo/roles/only_admin_on_weekends/templates/isdayoff_check.sh.j2)
- Развёртывается автоматически с помощью Ansible в Vagrant.
- Для проверки использовать:
  - Обычный пользователь: ```test_pam``` (пароль ```test_pam```);
  - Пользователь группы admin: ```test_pam_admin``` (пароль ```test_pam_admin```)


##### Дополнительно:
- Дать конкретному пользователю право работать с докером и возможность рестартить докер сервис.

##### Решение:
- [YAML-файл с комментарими](ansible_repo/roles/docker_mgmt/tasks/main.yml)
- [Шаблон sudoers](ansible_repo/roles/docker_mgmt/templates/sudoers.j2)
- Развёртывается автоматически с помощью Ansible в Vagrant.
- Для проверки использовать:
  - Пользователь группы admin **без прав root**: ```test_pam_admin``` (пароль ```test_pam_admin```)
    - Может использовать команды ```docker *```
    - Может использовать ```sudo systemctl restart docker.service```
