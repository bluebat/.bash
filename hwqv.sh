#!/bin/bash
# 20140516~20170223 by Wei-Lun Chao

function preRequires {
  echo "A Hardware Quick View Tool"
  for i in lshw hdparm lcdtest monitor-edid sensors setserial pcsc_scan upower ; do
    if ! which $i &>/dev/null ; then
      echo "$i not installed."
    fi
  done
}

function mainMenu {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Quit"
    echo "1) Board"
    echo "2) Network"
    echo "3) Disk"
    echo "4) Sound"
    echo "5) Port"
    echo "6) Power"
    echo "7) DisplayT"
    [ -n "$DISPLAY" ] && echo "8) DisplayX"
    echo "9) Details"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) viewBoard ;;
      2) viewNetwork ;;
      3) viewDisk ;;
      4) viewSound ;;
      5) viewPort ;;
      6) viewPower ;;
      7) viewDisplayT ;;
      8) viewDisplayX ;;
      9) viewDetails ;;
    esac
  done
}

function viewBoard {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) CPU"
    echo "2) BIOS"
    echo "3) Memory"
    echo "4) Clock"
    echo "5) PCI"
    echo "6) Hotplug"
    which sensors &>/dev/null && echo "7) Sensor"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) lscpu ;;
      2) dmidecode -t 0 ;;
      3) free -h ; dmidecode|grep 'Type: DDR' ;;
      4) hwclock ;;
      5) lspci -nn ;;
      6) udevadm monitor --environment --udev ;;
      7) sensors ;;
    esac
  done
}

function viewNetwork {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) Net Chip"
    echo "2) Interface"
    echo "3) Driver"
    echo "4) Wake On"
    echo "5) IP Address"
    echo "6) Ping"
    echo "7) Trace Route"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) lspci -v|sed -n -e '/Ethernet/,/^$/p' -e '/Network/,/^$/p' ;;
      2) ip link ;;
      3) read -p "Interface: " iface ; ethtool -i $iface ;;
      4) read -p "Interface: " iface ; ethtool $iface|grep Wake-on ;;
      5) hostname -I ; dig +short myip.opendns.com @resolver1.opendns.com ;;
      6) read -p "IP or Domain: " host ; ping -c 1 $host ;;
      7) read -p "IP or Domain: " host ; traceroute $host ;;
    esac
  done
}

function viewDisk {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) Disk Chip"
    echo "2) Block"
    echo "3) List"
    echo "4) Used"
    which hdparm &>/dev/null && echo "5) Info"
    which hdparm &>/dev/null && echo "6) Speed"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) lspci|grep -e IDE -e RAID -e SD ;;
      2) lsblk ;;
      3) blkid ;;
      4) df -h ;;
      5) read -p "sda|mmcblk0|..: " devname ; hdparm -i /dev/$devname ;;
      6) read -p "sda|mmcblk0|..: " devname ; hdparm -tT /dev/$devname ;;
    esac
  done
}

function viewSound {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) Cards"
    echo "2) Chip"
    echo "3) Devices"
    echo "4) Mixer"
    echo "5) Driver"
    echo "6) Record Test"
    echo "7) Play Test"
    echo "8) Full list"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) cat /proc/asound/cards ;;
      2) lspci -v|sed -n '/Audio/,/^$/p' ;;
      3) arecord -l;aplay -l ;;
      4) amixer;amixer contents ;;
      5) alsactl --version ;;
      6) arecord -d 6 -f dat test.wav ;;
      7) aplay test.wav ;;
      8) pacmd list|more ;;
    esac
  done
}

function viewPort {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) USB Chip"
    echo "2) USB Device Vendor"
    echo "3) USB Device Type"
    echo "4) PC/SC Scan"
    echo "5) Serial Ports"
    echo "6) COM Read"
    echo "7) COM Write"
    echo "8) LPT Write"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) lspci|grep USB ;;
      2) lsusb ;;
      3) lsusb -t ;;
      4) systemctl restart pcscd;sleep 2;pcsc_scan ;;
      5) dmesg|grep ttyS;setserial -g /dev/ttyS* ;;
      6) read -p "tty0|ttyUSB0|..: " devname ; stty -F /dev/$devname 19200 -parenb cs8 -cstopb ixon ; cat</dev/$devname|od -tx1 -An ;;
      7) read -p "ttyS0|ttyS1|..: " devname ; stty -F /dev/$devname 19200 ; echo ATDT123456 > /dev/$devname ;;
      8) read -p "lp0|usb/lp0|..: " devname ; echo -ne "\rHello World.\r\f" > /dev/$devname ;;
    esac
  done
}

function viewPower {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) UPower Dump"
    echo "2) UPower Wakeups"
    echo "3) Suspend/S3"
    echo "4) Hibernate/S4"
    echo "5) Poweroff/S5"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) upower -d ;;
      2) upower -w ;;
      3) read -p "wake-times sleep-seconds wake-seconds: " wtimes ssec wsec;for i in `seq 1 $wtimes`;do echo $i;rtcwake -m mem -s $ssec;sleep $wsec;done ;;
      4) read -p "wake-times sleep-seconds wake-seconds: " wtimes ssec wsec;for i in `seq 1 $wtimes`;do echo $i;rtcwake -m disk -s $ssec;sleep $wsec;done ;;
      5) read -p "wake-times sleep-seconds wake-seconds: " wtimes ssec wsec;for i in `seq 1 $wtimes`;do echo $i;rtcwake -m off -s $ssec;sleep $wsec;done ;;
    esac
  done
}

function viewDisplayT {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) VGA Chip"
    echo "2) Interface"
    which monitor-edid &>/dev/null && echo "3) EDID data"
    echo "4) X Driver"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) lspci -v|sed -n '/VGA/,/^$/p' ;;
      2) ls /sys/class/drm ;;
      3) monitor-edid ;;
      4) grep -i 'driver for' /var/log/Xorg.0.log ;;
    esac
  done
}

function viewDisplayX {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    echo "1) Resolution"
    echo "2) Interface"
    echo "3) RandR Test"
    echo "4) XInput"
    echo "5) xset"
    echo "6) Render"
    echo "7) ModeLines"
    which lcdtest &>/dev/null && echo "8) LCD Test"
    which edid-decode &>/dev/null && echo "9) EDID data"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) xdpyinfo|grep -A2 dimensions;xdriinfo ;;
      2) xrandr ;;
      3) read -p "800x600|1024x768|.. 1|2|3: " size ori;xrandr -s $size -o $ori;sleep 6;xrandr -s 0 -o 0;echo ;;
      4) xinput ;;
      5) xset -q|more ;;
      6) glxinfo|grep -e 'direct rendering' -e 'OpenGL renderer';vblank_mode=0 timeout 18 glxgears ;;
      7) grep -i modeline /var/log/Xorg.0.log ;;
      8) lcdtest 2>/dev/null ;;
      9) xrandr --prop|edid-decode ;;
    esac
  done
}

function viewDetails {
  local choice=''
  while [ "$choice" != '0' ] ; do
    echo
    echo "0) Go back"
    which lshw &>/dev/null && echo "1) lshw"
    echo "2) Kernel log"
    echo "3) Kernel modules"
    echo "4) dmesg follow"
    read -p "Your choice: " -n 1 choice
    echo
    case $choice in
      1) lshw|more ;;
      2) tail /var/log/messages 2>/dev/null ;;
      3) grep '' /sys/module/*/parameters/*|sed 's|/sys/module/||'|more ;;
      4) dmesg -H --follow ;;
    esac
  done
}

preRequires
mainMenu
