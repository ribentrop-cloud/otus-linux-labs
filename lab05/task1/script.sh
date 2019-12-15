#!/usr/bin/env bash
#
# Aleksandr Gavrik, 2019, mbfx@mail.ru
#
# Реализация скрипта-аналога вывода команды ps ax.
#
# Сделаем выборку из /proc по PID и создадим из них массив
declare -a pid_list_raw
pid_filter='^[0-9]+$'
dir='/proc'
cd $dir
for pid in *; do
        [[ -e $pid && $pid =~ $pid_filter  ]] || continue
        pid_list_raw[$pid]=$pid
done
unset pid_filter
cd ~
# Сделаем сортировку внутри массива, чтобы вывод был красивый :)
declare -a pid_list
pid_list=(
        $(for pid in "${pid_list_raw[@]}"; do echo $pid
        done | sort -n)
)
unset pid_list_raw
# Выдадим в консоль заголовок
printf "%5s\t%5s\t%4s\t%6s\t%s\n" "PID" "TTY" "STAT" "TIME" "COMMAND"
# Запросим тактовую частоту планировщика, чтобы потом не дергать
clk_tck=$(getconf CLK_TCK)
# Поехали! Для каждого PID в нашем массиве запросим /proc/PID/stat и, впоследствии,
# Извлечем оттуда нужные нам данные, а именно:
# utime[14], stime[15], stat[3], tty_nr[7], cmd[2].
for pid in ${pid_list[@]}; do
        stats=$(cat /proc/$pid/stat)
        statarray=($stats)
        #
        # Блок, отвечающий за TIME
        # TIME представляет из себя сумму utime и stime:
        # utime - время в квантах времени планировщика, которое было запланировано процессу для выполнения в пространстве пользователя
        # stime - время в квантах времени планировщика, которое было запланировано процессу для выполнения в пространстве ядра
        # Кванты времени планировщика на 1 секунду реального времени. Берём из getconf CLK_TCK. Обычно 100.
        utime=${statarray[13]}
        stime=${statarray[14]}
        cputime=$((($utime + $stime) / $clk_tck))
        cpuhour=$(($cputime / 60))
        cpumin=$(($cputime - ($cpuhour * 60)))
        proctime="$cpuhour:$cpumin"
        #
        # Блок, отвечающий за STAT
        # Основное состояние процесса берём из 3-го значения /proc/PID/stat
        stat=${statarray[2]}
        #       
        # Блок, отвечающий за TERM
        # Работает так:
        # 1. берём номер управляющего терминала из 7-го значения /proc/PID/stat;
        # Информация там представлена в виде числа, которое в двоичном виде несёт
        # major и minor версию устройства-терминала в виде:
        # major - биты с 7 по 15; minor - биты с 0 по 7 и с 20 по 31.
        # 2. конвертируем в двоичный вид и реверсим для удобства;
        # 3. берём биты с 7 по 15, реверсим и конвертируем в hex;
        # 4. берём оставшиеся биты, конкатенируем, реверсим и в hex;
        # Теперь у нас есть major и minor нужного управляющего терминала. Ищем его!
        # 5. Делаем поиск в /dev/*: тянем через stat сначала major, а при совпадении - minor номера устройств;
        # 6. Не забываем, что stat отдаёт всё в hex, и ищем совпадение. Если нашли, то отдаём название устройства.
        # (Медленно. но работает).
        tty_raw=${statarray[6]}
        if [[ $tty_raw == 0 ]];
        then
                tty="?"
        else
                tty_bin_rev=$(echo "obase=2;$tty_raw" | bc | rev)
                tty_bin_major=$(echo "${tty_bin_rev:8:15}" | rev)
                tty_major=$(echo "obase=16;ibase=2;${tty_bin_major}" | bc)
                tty_bin_minor=$(echo "${tty_bin_rev:0:7}${tty_bin_rev:20:31}" | rev)
                tty_minor=$(echo "obase=16;ibase=2;${tty_bin_minor}" | bc)

                cd /dev
                for dev_major in * **/*; do
                        find_major=$(stat -c %t $dev_major 2>/dev/null | tr '[:lower:]' '[:upper:]')
                        if [[ $find_major == $tty_major ]];
                        then
                                find_minor=$(stat -c %T $dev_major 2>/dev/null | tr '[:lower:]' '[:upper:]')
                                        if [[ $find_minor == $tty_minor ]];
                                        then
                                                tty="$dev_major" || continue
                                        fi
                        fi
                done
                cd ~
        fi
        #
        # Блок, отвечающий за CMDLINE
        # Берем инфу из /proc/PID/cmdline
        # Если там пусто, то тащим 2-е значение из /proc/PID/stat
        cmd=$(cat /proc/$pid/cmdline)
        if [[ "$cmd" == "" ]]; then
                cmd=${statarray[1]}
        fi
        # Выводим собранную информацию на экран
        printf "%5s\t%5s\t%4s\t%6s\t%s\n" "$pid" "$tty" "$stat" "$proctime" "${cmd:0:56}"
        # И так, пока PIDы не закончатся
        done
sleep 1
exit 0

