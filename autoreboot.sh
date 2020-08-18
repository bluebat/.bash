#!/bin/bash
AUTOFILE=$HOME/.config/autostart/autoreboot.desktop
SETFILE=$HOME/.autoreboot
if [ $# -gt 0 ] ; then
  echo COUNTS=$1 > $SETFILE
  echo COUNT=0 >> $SETFILE
fi

if [ -f $AUTOFILE ] ; then
  if [ -f $SETFILE ] ; then
    source $SETFILE
  else
    COUNTS=10
    COUNT=0
  fi
  let COUNT=COUNT+1
  echo COUNTS=$COUNTS > $SETFILE
  echo COUNT=$COUNT >> $SETFILE
else
  cat > $AUTOFILE << EOF
[Desktop Entry]
Type=Application
Name=Auto Reboot
Exec=autoreboot
EOF
  echo COUNTS=$COUNTS > $SETFILE
  echo COUNT=$COUNT >> $SETFILE
  sleep 1
  sync
  reboot
fi

if which notify-send ; then
  notify-send "Auto Reboot $COUNT/$COUNTS times!"
elif which yad ; then
  yad --text="Auto Reboot\n$COUNT/$COUNTS times!" --undecorated &
elif which zenity ; then
  zenity --info --text="Auto Reboot\n$COUNT/$COUNTS times!" &
else
  echo "Auto Reboot $COUNT/$COUNTS times!"
fi

if [ "$COUNT" -lt "$COUNTS" ] ; then
  sleep 10
  reboot
else
  rm -f $AUTOFILE
  rm -f $SETFILE
fi
