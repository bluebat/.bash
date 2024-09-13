#!/bin/sh
# Switch Video Mode by Wei-Lun Chao, 2023-12-20
# xbindkeys -f xbindkeysrc
# "switch-video-mode.sh"
#     XF86Display
# or
#     Mod4 + p

_XRANDR=`xrandr`
if echo "$_XRANDR"|grep '^LVDS[-0-9]* connected' > /dev/null ; then
    _BUILTIN=`echo "$_XRANDR"|grep '^LVDS[-0-9]* connected'|sed 's/ .*//'`
else
    _BUILTIN=`echo "$_XRANDR"|grep '^eDP[-0-9]* '|sed 's/ .*//'`
fi
if echo "$_XRANDR"|grep '^VGA[-0-9]* connected' > /dev/null ; then
    _EXTERNAL=`echo "$_XRANDR"|grep '^VGA[-0-9]* connected'|sed 's/ .*//'`
elif echo "$_XRANDR"|grep '^DP[-0-9]* connected' > /dev/null ; then
    _EXTERNAL=`echo "$_XRANDR"|grep '^DP[-0-9]* connected'|sed 's/ .*//'`
else
    _EXTERNAL=`echo "$_XRANDR"|grep '^HDMI[-0-9]* '|sed 's/ .*//'`
fi
if echo "$_XRANDR"|grep '^'$_BUILTIN' connected [a-z ]*[0-9]*x[0-9]*' > /dev/null ; then
    if echo "$_XRANDR"|grep '^'$_EXTERNAL' connected' > /dev/null ; then
        if echo "$_XRANDR"|grep '^'$_EXTERNAL' connected [a-z ]*[0-9]*x[0-9]*' > /dev/null ; then
            if echo "$_XRANDR"|grep '^'$_EXTERNAL' connected [a-z ]*[0-9]*x[0-9]*+0+0' > /dev/null ; then
                xrandr --output $_BUILTIN --auto --output $_EXTERNAL --auto --right-of $_BUILTIN # mirror to join
            else
                xrandr --output $_BUILTIN --off --output $_EXTERNAL --auto # join to external
            fi
        else
            xrandr --output $_BUILTIN --auto --output $_EXTERNAL --auto --same-as $_BUILTIN # builtin to mirror
        fi
    else
        xrandr --output $_BUILTIN --auto # builtin to builtin
    fi
else
    if echo "$_XRANDR"|grep '^'$_EXTERNAL' connected' > /dev/null ; then
        if echo "$_XRANDR"|grep '^'$_EXTERNAL' connected [a-z ]*[0-9]*x[0-9]*' > /dev/null ; then
            xrandr --output $_BUILTIN --auto --output $_EXTERNAL --off # external to builtin
        else
            xrandr --output $_BUILTIN --auto --output $_EXTERNAL --auto --right-of $_BUILTIN # none to join
        fi
    else
        xrandr --output $_BUILTIN --auto # none to builtin
    fi
fi
