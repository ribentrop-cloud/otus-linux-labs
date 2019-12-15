Предисловие:

здесь представлены файлы Vagrant и скрипт для автоматического успешного развёртывания
в виртуальной машине. Для Vagrant использованы следующие патчи:

vagrant-vbguest (vagrant plugin install vagrant-vbguest) - автоустановка VBoxGuestAdd

vagrant-reload (vagrant plugin install vagrant-reload) - перезагрузка в provisioning

Результирующие файлы прикреплены в директориях result.


Лабораторная работа 1.


1. "Грязный метод"


https://github.com/mbfx/otus-linux/tree/master/lab1/dirty_method


Берём ядро, кладём в /usr/src/kernels/*, собираем под root, делаем make install.
Грузимся - работает, но некоторые пакеты теперь хотят зависимости, которых нет,
и собрать их автоматически не получается из-за отсуствия kernel-devel пакетов.
Например, собрать автоматом Vbox Guest Additions не получается - всё теперь
надо делать руками, а как-то не хочется. Но работает.


2. Метод с RPM-пакетами


https://github.com/mbfx/otus-linux/tree/master/lab1/clean_method


Берём ядро, кладём в домашнюю директорию, собираем (создается окружение rpmbuild).
Получаем RPMы kernel-*.rpm, kernel-headers-*.rpm, kernel-devel-*.rpm
и RPM с исходным кодом (*.src.rpm). Удобно устанавливать\распространять\удалять.

