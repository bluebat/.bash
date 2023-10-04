#!/bin/bash
# 20170116~20231003 by Wei-Lun Chao
# MIT License
modprobe snd_pcsp &>/dev/null
export PS1='\[\e[1;33m\]\u@\w> \[\e[0m\]'
if [ "${0##*.}" = sh ] ; then
  export SETFILE=`dirname $0`/autoexec.set
  export LOGFILE=`dirname $0`/autoexec.log
  export OPTPATH=`dirname $0`
else
  export SETFILE=$HOME/autoexec.set
  export LOGFILE=$HOME/autoexec.log
  export OPTPATH=/opt
fi

case ${LANG%%.*} in
  cmn_TW|zh_TW)
    _description="Linux 自動執行測試程式"
    _modify="修改 ${OPTPATH}/firstrun 內容以插入自動程序，或者："
    _usage="用法："
    _applications="應用："
    _hwqv="硬體資訊快速檢視"
    _wakethemup="發送網路喚醒管理"
    _stress="監看壓力測試"
    _delay="延遲"
    _to_exec="以執行"
    _times="次"
    _repeat="重複"
    _times_delay="次，延遲"
    _seconds="秒"
    ;;
  yue_*|zh_HK)
    _description="Linux 自行測試程序"
    _modify="修改 ${OPTPATH}/firstrun 內容俾攝入自動架步，定抑："
    _usage="用法："
    _applications="應用："
    _hwqv="硬件資訊快脆望埋"
    _wakethemup="寄出網絡喚醒打理"
    _stress="監視笮力測試"
    _delay="褪"
    _to_exec="俾行"
    _times="次"
    _repeat="重複"
    _times_delay="次，褪"
    _seconds="秒"
    ;;
  *)
    _description="Linux Automatic Test Program"
    _modify="Modify ${OPTPATH}/firstrun to insert automatic procedure, or:"
    _usage="Usage:"
    _applications="Applicaitons:"
    _hwqv="HardWare Quick View"
    _wakethemup="WakeOnLan Manager"
    _stress="Stress Test Monitor"
    _delay="Delay"
    _to_exec=" to Execute"
    _times="Times"
    _repeat="Repeated"
    _times_delay="Times, Delay"
    _seconds="Seconds"
    ;;
esac

function about {
  clear
  echo -ne "\033[32m"
  if which banner &>/dev/null ; then
    banner "Firstrun"
  else
    echo -n "FIRSTRUN: "
  fi
  echo "${_description}"
  echo "#######################################################"
  echo -e "\033[36m${_modify}\033[0m"
  echo -e "\033[33m${_usage}\033[0m"
  echo -e '\t'$0' reboot 100 [10]'
  echo -e '\t'$0' rtcwake3 50 [10]'
  echo -e '\t'$0' rtcwake5 50 [10]'
  echo -e '\t'$0' suspend 20 [10]'
  echo -e '\t'$0' dpms 15 [10]'
  echo -e '\t'$0' poweroff 10 [10]'
  echo -e '\t'$0' reset'
  echo -e "\033[33m${_applications}\033[0m"
  which hwqv >/dev/null && echo -e "\thwqv #${_hwqv}"
  which wakethemup >/dev/null && echo -e "\twakethemup #${_wakethemup}"
  which stress >/dev/null && echo -e "\tstress -c 2 & top ; pkill stress #${_stress}"
  which dd >/dev/null && echo -e "\tdd if=/dev/sda | gzip -c > ${OPTPATH}/sata-or-usb.dd.gz"
  which dd >/dev/null && echo -e "\tdd if=/dev/mmcblk0 | zip ${OPTPATH}/emmc-or-sd.img.zip -"
  which gunzip >/dev/null && echo -e "\tgunzip -c ${OPTPATH}/sata-or-usb.dd.gz | dd of=/dev/sda"
  which unzip >/dev/null && echo -e "\tunzip -p ${OPTPATH}/emmc-or-sd.img.zip | dd of=/dev/mmcblk0"
  echo -ne "\033[36m"
  ip addr | grep -A 1 link/ether | sed 's/^ *//'
  echo -e "\033[0m"
}

function autorun {
  if [ -f $SETFILE ] ; then
    source $SETFILE
    rm -f $SETFILE
    sync
    if [ $COUNT -le $TOTAL ] ; then
      if [ $COUNT -ne 0 ] ; then
        DATETIME=`date +'%F %T'`
        if [ -z "$DISPLAY" ] ; then
          echo $COUNT: $DATETIME
          echo
          echo $COUNT: $DATETIME >> $LOGFILE
        else
          DISPLAYS=`xrandr|grep ' connected'|sed 's/ connected.*//'|tr '\n' ' '`
          echo $COUNT: $DATETIME @ $DISPLAYS
          echo
          echo $COUNT: $DATETIME @ $DISPLAYS >> $LOGFILE
        fi
        sync
      fi
      let COUNT=COUNT+1
      echo COMMAND=$COMMAND > $SETFILE
      echo TOTAL=$TOTAL >> $SETFILE
      echo COUNT=$COUNT >> $SETFILE
      echo INTERVAL=$INTERVAL >> $SETFILE
      if [ $COUNT -le $TOTAL ] ; then
        echo -e "${_delay} $INTERVAL ${_seconds}${to_exec} ${COMMAND^^}: $COUNT/$TOTAL ..."
        sleep $INTERVAL
        case $COMMAND in
          reboot)
            reboot
            ;;
          rtcwake3)
            rtcwake -m mem -s 6
            autorun
            ;;
          rtcwake5)
            rtcwake -m off -s 6 ; systemctl poweroff
            ;;
          suspend)
            systemctl suspend
            sleep 1
            autorun
            ;;
          dpms)
            xset dpms force suspend
            while true ; do
              sleep 1
              [ `xprintidle` -lt 900 ] && break
            done
            autorun
            ;;
          poweroff)
            systemctl poweroff
            sleep 1
            ;;
        esac
      else
        more $LOGFILE
        exec bash
      fi
    fi
  else
    about
    exec bash
  fi
}

if [ -z "$1" ] ; then
  COMMAND=""
  TOTAL=0
  COUNT=0
  cd ${OPTPATH}
  ROOTFS=`grep -o '\(http\|https\|tftp\)://[^ ]*' /proc/cmdline`
  if [ -n "$ROOTFS" ] ; then
    curl -f -s `dirname "$ROOTFS"`/firstrun -o firstrun
    if ! [ -s firstrun ] ; then
      timeout 2 nc -l -o firstrun
    fi
  fi
  if [ -s firstrun ] ; then
    source firstrun
  else
    rm -f firstrun
  fi
  cd
  autorun
elif [ "$1" = reboot -o "$1" = rtcwake3 -o "$1" = rtcwake5 -o "$1" = suspend -o "$1" = poweroff -a "$2" -gt 0 &>/dev/null ] ; then
  echo COMMAND=$1 > $SETFILE
  echo TOTAL=$2 >> $SETFILE
  echo COUNT=0 >> $SETFILE
  echo INTERVAL=${3:-10} >> $SETFILE
  echo "${1^^}: ${_repeated} $2 ${_times_delay} ${3:-10} ${_seconds}" > $LOGFILE
  autorun
else
  if [ "$1" = reset ] ; then
    cat $SETFILE
    rm -i $SETFILE
  fi
  about
  if pgrep fbterm &>/dev/null ; then
    exec bash
  fi
fi
