#!/bin/bash
# Check Seat, (C) 2022 by Wei-Lun Chao, MIT License.
# Requires: yad, xdotool
_SEAT=${DISPLAY:0-1}
_USERNAME=""
_PASSWORD=""
_SLEEPTIME=58
if [ -z "$1" ]; then
    _IMAGEFILE=/usr/share/check-seat/default.*
else
    _IMAGEFILE=/usr/share/check-seat/$1.*
fi

function _checkpassword {
    _OK="false"
    if [ "$1" = 'this_hour' ]; then
        _RANGES="${_HOUR}1 ${_HOUR}2 $((_HOUR-1))2"
    else
        _RANGES="${_HOUR}2"
    fi
    for _RESERVE in $_RANGES; do
        _CHECKSUM=$(echo "${HOSTNAME}${_SEAT}${_USERNAME}${_DATE}${_RESERVE}" | sum | sed 's/ .*//')
        echo $_CHECKSUM >> /tmp/checksum-$_USERNAME #DEBUG
        [ "$_PASSWORD" = "$_CHECKSUM" ] && _OK="true"
    done
    echo "$_OK"
}


while true; do
    _DATE=$(date +%Y%m%d)
    _HOUR=$(date +%H)
    _MINUTE=$(date +%M)
    if [ -z "$_PASSWORD" ]; then
        _ACTIVEWINDOW=$(xdotool getactivewindow)
        [ -n "$_ACTIVEWINDOW" ] && xdotool windowminimize "$_ACTIVEWINDOW"
        _OPTIONS=$(yad --on-top --no-escape --fullscreen --image="$_IMAGEFILE" --image-on-top \
            --form --field='<span font="24">Username: </span>' "" --field='<span font="24">Password: </span>':H "" \
            --button='<span font="16">Reboot</span>!gtk-refresh':1 --button='<span font="16">To Desktop</span>!gtk-apply':0)
        _EXITCODE=$?
        if [ "$_EXITCODE" -eq 0 ]; then
            _USERNAME=$(echo "$_OPTIONS" | awk -F '|' '{ print $1 }')
            _PASSWORD=$(echo "$_OPTIONS" | awk -F '|' '{ print $2 }')
        else
            sync
            reboot
        fi
        [ -n "$_ACTIVEWINDOW" ] && xdotool windowmap "$_ACTIVEWINDOW"
        
        if ! $(_checkpassword this_hour); then
            _USERNAME=""
            _PASSWORD=""
        fi
    elif [ "$_MINUTE" = '00' ]; then
        if ! $(_checkpassword this_hour); then
            _USERNAME=""
            _PASSWORD=""
        else
            sleep "$_SLEEPTIME"
        fi
    elif [ "$_MINUTE" = '55' ]; then
        if ! $(_checkpassword next_hour); then
            _ACTIVEWINDOW=$(xdotool getactivewindow)
            [ -n "$_ACTIVEWINDOW" ] && xdotool windowminimize "$_ACTIVEWINDOW"
            yad --on-top --title="Attention" --image='dialog-warning' \
                --text='<span font="24">\nYour reservation will end in 5 minutes,\nPlease save your data ASAP!\nBooking the next time slot for continuance.</span>' \
                --fixed --timeout=$((_SLEEPTIME*4)) --button='<span font="16">OK</span>!gtk-ok'
            [ -n "$_ACTIVEWINDOW" ] && xdotool windowmap "$_ACTIVEWINDOW"
        fi
        sleep "$_SLEEPTIME"
    else
        sleep "$_SLEEPTIME"
        #xprintidle
    fi
done
