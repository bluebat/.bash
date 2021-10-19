#!/bin/bash
# 20170116~20211018 by Wei-Lun Chao
#
modprobe snd_pcsp
export PS1='\[\e[1;33m\]\u@\w> \[\e[0m\]'
export SETFILE=$HOME/autoexec.set

case ${LANG%%.*} in
  cmn_TW|zh_TW)
    _description="Linux 自動執行測試程式"
    _modify="修改 /opt/firstrun 內容以插入自動程序，或者："
    _usage="用法："
    _applications="應用："
    _hwqv="硬體資訊快速檢視"
    _wakethemup="發送網路喚醒管理"
    _stress="監看壓力測試"
    _wait="等待"
    _to_exec="以執行"
    _executed="已執行"
    _times="次"
    _repeat="重複"
    _times_wait="次，等待"
    _seconds="秒"
    ;;
  yue_*)
    _description="Linux 自行測試程序"
    _modify="修改 /opt/firstrun 內容俾攝入自動架步，定抑："
    _usage="用法："
    _applications="應用："
    _hwqv="硬件資訊快脆望埋"
    _wakethemup="寄出網絡喚醒打理"
    _stress="監視笮力測試"
    _wait="等緊"
    _to_exec="俾行"
    _executed="已行"
    _times="次"
    _repeat="重複"
    _times_wait="次，等緊"
    _seconds="秒"
    ;;
  *)
    _description="Linux Automatic Test Program"
    _modify="Modify /opt/firstrun to insert automatic procedure, or:"
    _usage="Usage:"
    _applications="Applicaitons:"
    _hwqv="HardWare Quick View"
    _wakethemup="WakeOnLan Manager"
    _stress="Stress Test Monitor"
    _wait="Waiting"
    _to_exec=" to Execute"
    _executed="Executed"
    _times="Times"
    _repeat="Repeated"
    _times_wait="Times, Waiting"
    _seconds="Seconds"
    ;;
esac

function about {
  clear
  echo -ne "\033[32m"
  banner "Firstrun"
  echo "${_description}"
  echo "#######################################################"
  echo -e "\033[36m${_modify}\033[0m"
  echo -e "\033[33m${_usage}\033[0m"
  echo -e '\tautoexec reboot 100 [10]'
  echo -e '\tautoexec rtcwake 50 [10]'
  echo -e '\tautoexec suspend 20 [10]'
  echo -e '\tautoexec poweroff 10 [10]'
  echo -e "\033[33m${_applications}\033[0m"
  echo -e "\thwqv #${_hwqv}"
  echo -e "\twakethemup #${_wakethemup}"
  echo -e "\tstress -c 2 & top ; pkill stress #${_stress}"
  echo -e '\tdd if=/dev/sda | gzip -c > /opt/sata-or-usb.dd.gz'
  echo -e '\tdd if=/dev/mmcblk0 | zip /opt/emmc-or-sd.img.zip -'
  echo -e '\tgunzip -c /opt/sata-or-usb.dd.gz | dd of=/dev/sda'
  echo -e '\tunzip -p /opt/emmc-or-sd.img.zip | dd of=/dev/mmcblk0'
  echo -ne "\033[36m"
  ip addr | grep -A 1 link/ether | sed 's/^ *//'
  echo -e "\033[0m"
}

function autorun {
  if [ -f $SETFILE ] ; then
    source $SETFILE
    rm -f $SETFILE
    sync
    let COUNT=COUNT+1
    if [ $COUNT -le $TOTAL ] ; then
      echo -e "${_wait} $INTERVAL ${_seconds}${to_exec} ${COMMAND^^}: $COUNT/$TOTAL ..."
      sleep $INTERVAL
      echo COMMAND=$COMMAND > $SETFILE
      echo TOTAL=$TOTAL >> $SETFILE
      echo COUNT=$COUNT >> $SETFILE
      echo INTERVAL=$INTERVAL >> $SETFILE
      echo $COUNT: `date +%c` >> $HOME/autoexec.log
      sync      
      case $COMMAND in
        reboot)
          reboot
          ;;
        rtcwake)
          rtcwake -m mem -s 4 &>/dev/null
          autorun
          ;;
        suspend)
          systemctl suspend
          sleep 1
          autorun
          ;;
        poweroff)
          systemctl poweroff
          sleep 1
          ;;
      esac
    else
      about
      echo -e "${_executed} ${COMMAND^^}: $TOTAL ${_times}"
      exec bash
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
  cd /opt
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
else
  if [ "$1" = reboot -o "$1" = rtcwake -o "$1" = suspend -o "$1" = poweroff -a "$2" -gt 0 &>/dev/null ] ; then
    echo COMMAND=$1 > $SETFILE
    echo TOTAL=$2 >> $SETFILE
    echo COUNT=0 >> $SETFILE
    echo INTERVAL=${3:-10} >> $SETFILE
    echo "${1^^}: ${_repeated} $2 ${_times_wait} ${3:-10} ${_seconds}" > $HOME/autoexec.log
    autorun
  else
    about
    if pgrep fbterm &>/dev/null ; then
      exec bash
    fi
  fi
fi
