#!/bin/bash

# СКРИПТ ДЛЯ АВТОМАТИЧЕСКОЙ ЗАПИСИ RTSP-ПОТОКОВ С IP-КАМЕР

# Создаём массив с адресами камер
camArray=()
camArray[0]="rtsp://username:password@ipAddress:port"

# Цикл for перебирает все элементы массива camArray
for cams in "${camArray[@]}"; do

    # ИЗВЛЕЧЕНИЕ IP-АДРЕСА КАМЕРЫ (БЕЗ ПОРТА)
    ipCam=$(echo $cams | sed 's|.*@||' | sed -r 's/:.+//')

    # ИЗВЛЕЧЕНИЕ IP-АДРЕСА С ПОРТОМ
    ipCamPort=$(echo $cams | sed 's|.*@||' | sed -r 's/\/.+//')

    # ПРЕОБРАЗОВАНИЕ ПОРТА ДЛЯ ИМЕНИ ПАПКИ (замена : на -)
    ipCamPortT=${ipCamPort//:/-}

    # СОЗДАНИЕ ДИРЕКТОРИИ ДЛЯ ЗАПИСЕЙ
    mkdir -p "/rec/$ipCamPortT"
    cd "/rec/$ipCamPortT"

    # УСТАНОВКА ПРАВ ДОСТУПА
    chmod 0777 *

    # ФОРМИРОВАНИЕ ИМЕНИ ФАЙЛА ДЛЯ ЗАПИСИ
    # Пример: rec_19-04-26_14-30_14-40_001.mp4
    cur_date="rec_$(date +"%d-%m-%y")_$(date +"%H-%M")_$(date -d "now + 10 minutes" +"%H-%M")_%03d.mp4"

    # ПРОВЕРКА: ЗАПИСЬ ДЛЯ ЭТОЙ КАМЕРЫ УЖЕ ЗАПУЩЕНА?
    checkTranslation=$(ps aux | grep "$ipCamPort -c copy" | grep -v grep | wc -l)

    # УСЛОВНЫЙ ОПЕРАТОР: ЗАПУСКАЕМ ЗАПИСЬ, ЕСЛИ ОНА НЕ ЗАПУЩЕНА
    if [[ $checkTranslation -eq 0 ]]
    then
        echo "Start rec cam: $ipCamPort Folder: $ipCamPortT URL: $cams"
        
        # ЗАПУСК FFMPEG В ФОНОВОМ РЕЖИМЕ
        # -rtsp_transport tcp - использование TCP вместо UDP
        # -c copy - копирование потока без перекодирования (низкая нагрузка на ЦП)
        # -an - отключение звука
        # -f segment - разбивка на части
        # -segment_time 600 - длительность сегмента 600 сек (10 мин)
        ffmpeg -rtsp_transport tcp -i "$cams" -c copy -an -f segment -segment_time 600 -reset_timestamps 1 "$cur_date" > /dev/null 2>&1 &
    else
        echo "Rec work: $ipCamPort"
    fi

done
