#!/usr/bin/bash
# Taiwan NHI IC Card Detector, (C) 2024 by Wei-Lun Chao, MIT License.
# Using tw-nhi-icc-service:
# https://github.com/magiclen/tw-nhi-icc-service

pkill tw-nhi-icc-serv
cd /usr/libexec/tw-nhi-icc-detector
./tw-nhi-icc-service &
while true ; do
    _DATA=`curl http://127.0.0.1:8000 | sed -e 's|\[{\(.*\)}]|\1|' -e 'y|:,|= |' -e 's|"||g' -e 's|.*card_no|card_no|g'`
    if [ -z "${_DATA}" -o "${_DATA}" = '[]' ] ; then
        sleep 5
    else
        eval ${_DATA}
        card_no=`sed 's|\(....\)\(....\)|\1 \2 |' <<< $card_no`
        birth_date=`expr ${birth_date:0:4} - 1911`/${birth_date:5:2}/${birth_date:8:2}
        [ ${sex} = 'M' ] && sex='👨'  || sex='👩'
        sed -e "s|0000 0000 0000|${card_no}|" -e "s|NAME|${full_name}|" -e "s|A123456789|${id_no}|" -e "s|99/99/99|${birth_date}|" -e "s|@|${sex}|" tw-nhi-icc.svg > /tmp/tw-nhi-icc.svg
        yad --picture --filename=/tmp/tw-nhi-icc.svg \
            --on-top --center --width=610 --height=358 \
            --title="National Health Insurance Card" \
            --no-buttons --timeout=5 --timeout-indicator=bottom
        rm -f /tmp/tw-nhi-icc.svg
    fi
done
