#!/bin/sh
# Touchpad Toggle by Wei-Lun Chao, 2024-01-04
# xmodmap -e 'keycode 93 = XF86TouchpadToggle'
# xbindkeys -f xbindkeysrc
# "touchpad-toggle.sh"
#     Control+Mod4 + XF86TouchpadToggle

_DEVICE=`xinput|grep -i 'touchpad'|sed 's/.*id=\([0-9]*\).*/\1/'`
if test -n "$_DEVICE" ; then
    if xinput list-props "$_DEVICE"|grep 'Device Enabled.*1$' > /dev/null ; then
        xinput disable "$_DEVICE"
    else
        xinput enable "$_DEVICE"
    fi
fi
