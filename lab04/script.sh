#!/usr/bin/env VAR=VALUE bash
#
# Aleksandr Gavrik, mbfx@mail.ru, 2019
#
# Задание: написать скрипт для крона, который раз в час присылает на заданную почту:
# 1.    Список IP адресов с момента последнего запуска скрипта
#       с которых было наибольшее количество запросов (с указанием количества таких запросов);
# 2.    Список запращиваемых адресов с наибольшим количеством запросов
#       с момента последнего запуска скрипта;
# 3.    Все ошибки c момента последнего запуска скрипта;
# 4.    Cписок всех кодов возврата с указанием их количества с момента последнего запуска скрипта;
# 5.    Обработанный скриптом временной диапазон;
# 6.    Должна быть реализована защита от мультизапуска.
# 7.    (Дополнительно) В скрипте использовать trap, функции, sed и find.
#
#
# Объявляем переменные.
SCRIPTTIME=`date +%d/%b/%Y:%T" "%z`
LOCKFILE=/var/run/nginx_log_parser.pid
WORKINGDIR=/var/nginx_log_parser
HISTORYDIR=$WORKINGDIR'/history'
if [ -z $1 ] ;
        then
        echo "No file specified for analysis!"
        exit 1
fi
#
# Проверяем, есть ли путь к рабочим каталогам и создаем их, если нет.
if [ ! -d $WORKINGDIR ] ;
        then
        mkdir -p $WORKINGDIR
fi
if [ ! -d $HISTORYDIR ] ;
        then
        mkdir -p $HISTORYDIR
fi
#
# Объявляем пути до рабочих файлов
LASTRUNFILE=$WORKINGDIR'/nginx_log_parser.lastrun'
WORKFILE=$WORKINGDIR'/nginx_log_parser.tmp'
RESULTFILE=$WORKINGDIR'/nginx_log_parser.result'
#
# Объявляем целевой файл для анализа и проверяем его существование
TARGETFILE=$1
if [ ! -e $1 ] ;
        then
        echo "$1 is not exists!"; exit 1
fi
if [ -d $1 ] ;
        then
        echo "$1 is a directory!"; exit 1
fi
#
# Проверяем наличие указанного почтового адреса, иначе root@localhost
ADDRESS=$2
if [ -z $ADDRESS ] ;
        then
        ADDRESS=root@otuslinux.localdomain
fi
#
# Делаем простую проверку адреса почты
emailcheck() {
        echo "Checking email."
        echo "$1" | egrep --quiet "^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+"
        if [ $? -ne 0 ] ;
                then
                echo "Invalid email address!"
                exit 1
                else
                echo "Email check - OK!"
        fi
}
#
# Проверяем корректность введенного почтового адреса
if [ $ADDRESS != 'root@otuslinux.localdomain' ]
        then
        emailcheck $ADDRESS
fi
#
# Защита от мультизапуска:
# Запретим перезапись файлов через перенаправление вывода и
# и попробуем записать в lockfile наш pid.
# Если операция завершится с exitcode != 0, значит файл существует - выходим
set -C
echo $$ > $LOCKFILE 2>/dev/null || { echo "Lockfile $LOCKFILE exists!"; exit 1; }
set +C
#
# Используем trap:
# При выходе удаляем lockfile и мусор
trap "rm -f $LOCKFILE $WORKFILE; exit" INT TERM EXIT
#
# Фиксируем время начала и потом запишем в рабочий файл
BEGINTIME=$SCRIPTTIME
#
# С помоью find находим старые файлы и удаляем их
find $WORKFILE 2>/dev/null && rm -f $WORKFILE
find $RESULTFILE 2>/dev/null && rm -f $RESULTFILE
#
# Проверяем наличие файла с меткой о последнем запуске
# и создаём его, если таковой отсутствует, добавляя туда метку
# начала анализа с 01.01.1970, т.е. всего лога
if [ ! -e $LASTRUNFILE ] ;
        then
        echo "$LASTRUNFILE is bad or not exist. Analysing from begin."
        touch $LASTRUNFILE
        echo "01/Jan/1970:00:00:01 +0000" > $LASTRUNFILE
fi
#
# Сообщаем о времени. с которого начнётся анализ лога
LASTTIME=`tail -n 1 $LASTRUNFILE`
echo "Start analysing from $LASTTIME"
#
# Копируем данные из источника в рабочий файл
cat $1 > $WORKFILE
#
# Добавляем в файл временную метку для сортировки, сортируем м отрезаем лишнее
echo "0.0.0.0 - - [$LASTTIME] specialmark1" >> $WORKFILE
echo "0.0.0.0 - - [$BEGINTIME] specialmark2" >> $WORKFILE
sort -o $WORKFILE -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n $WORKFILE
sed -i '0,/specialmark1/d' $WORKFILE
sed -i '/specialmark2/,$d' $WORKFILE
#
# Пишем функцию, которой передадим файл для анализа и файл для записи результата
analyse() {
        FTARGETFILE=$1
        FRESULTFILE=$2
        ASTART=`head -n 1 $1 |awk '{print $4,$5}'`
        AFINISH=`tail -n 1 $1 |awk '{print $4,$5}'`
        echo "---" > $2
        echo "Script start time - $BEGINTIME" >> $2
        echo "Log has been analyzed from $ASTART to $AFINISH" >> $2
        echo "---" >> $2
        echo "The list of addresses with the most requests to the server (top 10 req-IP pairs)" >> $2
        cat $1 |awk '{print $1}' |sort |uniq -c |sort -rn| head >> $2
        echo "---" >> $2
        echo "The list of server resources with the most requests from the clients (top 10 req-res pairs)" >> $2
        cat $1 |awk '{print $7}' |sort |uniq -c |sort -rn| head >> $2
        echo "---" >> $2
        echo "Total number of errors (status codes 4xx and 5xx, number-code pairs)" >> $2
        cat $1 |awk '{print $9}' |grep -E "[4-5]{1}[0-9][0-9]" |sort |uniq -c |sort -rn >> $2
        echo "---" >> $2
        echo "The list of status codes with their total number (number-code pairs)" >> $2
        cat $1 |awk '{print $9}' |sort |uniq -c |sort -rn >> $2
        echo "---" >> $2
}
#
# Выполняем анализ и отправляем письмо
analyse $WORKFILE $RESULTFILE
cat $RESULTFILE | mail -s "Message fron NGINX parser" $ADDRESS
#
# Делаем копию отправленного файла, прибираемся и ставим метку последнего запуска
cp $RESULTFILE $HISTORYDIR'/nginx_log_parser-'`date +%d%b%Y-%T`'.result'
rm -f $RESULTFILE
echo $BEGINTIME > $LASTRUNFILE
exit 0

