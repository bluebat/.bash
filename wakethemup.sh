#!/bin/bash
# 20140528~20220630 by Wei-Lun Chao
#
toolName=wakethemup
fileName=$toolName.set
logName=$toolName.`date +%Y%m%d%H%M`
interface=`ip link|grep 'state UP'|sed 's/.: \(.*\):.*/\1/'`
if [ -z "$interface" ] ; then
  echo "No network connection."
  exit 1
fi
if which wol &> /dev/null ; then
  wakeTool="wol"
elif which ether-wake &> /dev/null ; then
  wakeTool="ether-wake -i $interface -b"
elif which wakeonlan &> /dev/null ; then
  wakeTool="wakeonlan"
else
  echo "Please install wol, net-tools or wakeonlan first."
  exit 1
fi

[ -z "$1" ] && testInterval=15 || testInterval="$1"
declare -A mac total sent

function getThem {
  echo -e "\033[31mYou may edit $toolName.set manually.\033[0m"
  if ! [ -f "$toolName.set" ] ; then
    touch "$toolName.set"
  fi
  for index in {0..9} ; do
    if read data1 data2 data3 ; then
      mac[$index]=$data1
      total[$index]=$data2
      sent[$index]=$data3
    else
      mac[$index]='00:00:00:00:00:00'
      total[$index]=100
      sent[$index]=0
    fi
  done < "$toolName.set"
}

function mainMenu {
  local choice=''
  while [ "${choice,}" != 'q' ] ; do
    echo "   MAC                  Total   Sent"
    echo -e "\033[34m====================================\033[0m"
    for index in {0..9} ; do
      echo -e -n "\033[36m$index) \033[0m${mac[$index]}\t"
      echo -e "\033[33m${total[$index]}\t\033[32m${sent[$index]}\033[0m"
    done
    echo -e "\033[34m====================================\033[0m"
    echo -e "\033[36mI)nterval: $testInterval(s)\033[0m"
    echo -e "\033[36mS)tart\033[0m"
    echo -e "\033[36mQ)uit\033[0m"    
    read -p "Your choice [0-9isq]: " -n 1 choice
    echo
    case ${choice,} in
      [[:digit:]]) setThem "$choice" ;;
      i) read -p "Set interval seconds: " testInterval ;;
      s) testStart ;;
    esac
    [ -z "$testInterval" ] && testInterval=15
    echo
  done
}

function setThem {
  local index="$1"
  local choice=''
  while [ "${choice,}" != 'b' ] ; do
    echo -e "\033[34m====================================\033[0m"
    echo -e "   \033[0m${mac[$index]}\t\033[33m${total[$index]}\t\033[32m${sent[$index]}\033[0m"
    echo -e "\033[36mM)AC Address\033[0m"
    echo -e "\033[36mT)otal Times\033[0m"
    echo -e "\033[36mR)eset Sent\033[0m"
    echo -e "\033[36mB)ack to Main\033[0m"    
    read -p "Your choice [mtrb]: " -n 1 choice
    echo
    case ${choice,} in
      m) read -p "MAC address [17 chars]: " mac[$index] ;;
      t) read -p "Total test times: " total[$index] ;;
      r) sent[$index]=0 ;;
    esac
    [ "${#mac[$index]}" -ne 17 ] && mac[$index]='00:00:00:00:00:00'
    [ -z "${total[$index]}" ] && total[$index]='0'
  done
}

function testStart {
  echo
  while true ; do
    local counts=0
    for index in {0..9} ; do
      if [ "${mac[$index]}" != '00:00:00:00:00:00' ] ; then
        local count=$((total[$index]-sent[$index]))
        if [ "$count" -gt 0 ] ; then
          $wakeTool "${mac[$index]}"
          if [ "$wakeTool" != "wol" ] ; then
            echo "Waking up ${mac[$index]}..."
          fi
          echo "`date --iso-8601=seconds` Waking up ${mac[$index]}" >> $logName
          sent[$index]=$((sent[$index]+1))
          counts=$((counts+count-1))
        fi
      fi
    done
    if [ "$counts" -gt 0 ] ; then
      echo -e "\033[1;30mWait $testInterval seconds. Press ESC to break...\033[0m"
      read -s -t "$testInterval" -n 1 choice
      [ "$choice" = `echo -e "\e"` ] && break   
    else
      break
    fi
  done
}

function putThem {
  echo -n > "$fileName"
  for index in {0..9} ; do
    echo "${mac[$index]} ${total[$index]} ${sent[$index]}" >> "$fileName"
  done
}

getThem
mainMenu
putThem
