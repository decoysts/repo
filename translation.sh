#!/bin/bash

# ПЕРЕХОД В ДИРЕКТОРИЮ WEB-СЕРВЕРА
cd /var/www/html/

# ОБЪЯВЛЕНИЕ МАССИВА С КАМЕРАМИ
camArray=()
camArray[0]="rtsp://username:password@ipAddress:port"

for cams in "${camArray[@]}"; do

    # ИЗВЛЕЧЕНИЕ ДАННЫХ
    ipCam=$(echo $cams | sed 's|.*@||' | sed -r 's/:.+//')
    ipCamPort=$(echo $cams | sed 's|.*@||' | sed -r 's/\/.+//')
    
    # Создаем папку для HLS-файлов конкретной камеры
    mkdir -p $ipCamPort

    # ПРОВЕРКА ЗАПУЩЕННОГО ПРОЦЕССА
    checkTranslation=$(ps aux | grep "$ipCamPort" | grep "libx264" | grep -v grep | wc -l)

    if [[ $checkTranslation -eq 0 ]]
    then
        echo "Start cam: $ipCamPort"
        
        # ЗАПУСК ТРАНСЛЯЦИИ (HLS)
        # -vf scale=640:360 - уменьшаем разрешение для экономии трафика
        # -b:v 1000k - битрейт видео
        # -hls_time 2 - длительность чанка 2 секунды
        # -hls_list_size 10 - хранить только последние 10 сегментов в плейлисте
        ffmpeg -rtsp_transport tcp -i "$cams" -c:v libx264 -vf scale=640:360 -r 20 -b:v 1000k -an -preset veryfast -g 50 \
        -hls_time 2 -hls_list_size 10 -hls_flags delete_segments \
        -hls_segment_filename "/var/www/html/$ipCamPort/segment_%03d.ts" \
        "/var/www/html/$ipCamPort/stream.m3u8" > /dev/null 2>&1 &
    else
        echo "Cam work: $ipCamPort"
    fi

done
