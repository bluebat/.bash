#!/bin/bash
# 5x5 Bingo Cards Checker.
# Public Domain, 20150204~20160121
# Wei-Lun Chao <bluebat@member.fsf.org>

declare TOOLNAME=bingocheck
declare CARDS=0
declare LOG=''
declare -a VALUE BINGO
declare -A NUM MATCH CHECK
CHECK[0,0]=0 CHECK[0,1]=1 CHECK[0,2]=2 CHECK[0,3]=3 CHECK[0,4]=4
CHECK[1,0]=5 CHECK[1,1]=6 CHECK[1,2]=7 CHECK[1,3]=8 CHECK[1,4]=9
CHECK[2,0]=10 CHECK[2,1]=11 CHECK[2,2]=12 CHECK[2,3]=13 CHECK[2,4]=14
CHECK[3,0]=15 CHECK[3,1]=16 CHECK[3,2]=17 CHECK[3,3]=18 CHECK[3,4]=19
CHECK[4,0]=20 CHECK[4,1]=21 CHECK[4,2]=22 CHECK[4,3]=23 CHECK[4,4]=24
CHECK[5,0]=0 CHECK[5,1]=5 CHECK[5,2]=10 CHECK[5,3]=15 CHECK[5,4]=20
CHECK[6,0]=1 CHECK[6,1]=6 CHECK[6,2]=11 CHECK[6,3]=16 CHECK[6,4]=21
CHECK[7,0]=2 CHECK[7,1]=7 CHECK[7,2]=12 CHECK[7,3]=17 CHECK[7,4]=22
CHECK[8,0]=3 CHECK[8,1]=8 CHECK[8,2]=13 CHECK[8,3]=18 CHECK[8,4]=23
CHECK[9,0]=4 CHECK[9,1]=9 CHECK[9,2]=14 CHECK[9,3]=19 CHECK[9,4]=24
CHECK[10,0]=0 CHECK[10,1]=6 CHECK[10,2]=12 CHECK[10,3]=18 CHECK[10,4]=24
CHECK[11,0]=4 CHECK[11,1]=8 CHECK[11,2]=12 CHECK[11,3]=16 CHECK[11,4]=20
         
if [ -f "$TOOLNAME.tab" ] ; then
  echo -e "\033[36m* Reading $TOOLNAME.tab ...\033[0m"
  CARD=0
  while read -a VALUE ; do
    for SITE in {0..24} ; do
      NUM[$CARD,$SITE]=${VALUE[$SITE]}
      if [ "${VALUE[$SITE]}" = '**' ] ; then
        MATCH[$CARD,$SITE]=true
      else
        MATCH[$CARD,$SITE]=false
      fi
    done
    BINGO[$CARD]=0
    CARD=$((CARD+1))
    CARDS=$CARD
  done < "$TOOLNAME.tab"
else
  echo -e "\033[36m* $TOOLNAME.tab not found.\033[0m"
fi

while true ; do
  echo -n "25 Numbers (two-digits, ** for free)"
  printf "%.s " {1..44}
  echo "Lines"
  echo -e -n "\033[32m"
  printf "%.s=" {1..85}
  echo -e "\033[0m"
  CARD=0
  while [ "$CARD" -lt "$CARDS" ] ; do
    for SITE in {0..24} ; do
      if "${MATCH[$CARD,$SITE]}" ; then
        echo -e -n "\033[33m${NUM[$CARD,$SITE]} "
      else
        echo -e -n "\033[0m${NUM[$CARD,$SITE]} "
      fi
    done
    echo -e "\t\033[31m${BINGO[$CARD]}\033[0m"
    CARD=$((CARD+1))
  done
  echo -e -n "\033[32m"
  printf "%.s=" {1..85}
  echo -e "\033[0m"
  echo -e "Drawn numbers->\033[33m$LOG\033[0m"
  echo -e "\033[36m00) Quit Bingo Checker\033[0m"
  echo -e "\033[36mNumbers) Add Card Numbers\033[0m"
  echo -e "\033[36m--) Reset Card Numbers\033[0m"
  echo -e "\033[36m??) Two-digits Drawn Number\033[0m"
  read -p "Your input: " -a VALUE
  echo
  case ${VALUE[@]} in
    00)
       break
       ;;
    --)
       CARDS=0
       ;;
    ??)
       LOG="$LOG $VALUE"
       CARD=0
       while [ "$CARD" -lt "$CARDS" ] ; do
         for SITE in {0..24} ; do
           if [ "${NUM[$CARD,$SITE]}" = "$VALUE" ] ; then
             MATCH[$CARD,$SITE]=true
           fi
         done
         LINES=0
         for LINE in {0..11} ; do
           POINTS=0
           for POINT in {0..4} ; do
             if "${MATCH[$CARD,${CHECK[$LINE,$POINT]}]}" ; then
               POINTS=$((POINTS+1))
             fi
           done
           if [ "$POINTS" -eq 5 ] ; then
             LINES=$((LINES+1))
           fi
         done
         BINGO[$CARD]=$LINES
         CARD=$((CARD+1))
       done
       ;;
    *)
       if [ "${#VALUE[@]}" -eq 25 ] ; then
         for SITE in {0..24} ; do
           NUM[$CARDS,$SITE]=${VALUE[$SITE]}
           if [ "${VALUE[$SITE]}" = '**' ] ; then
             MATCH[$CARDS,$SITE]=true
           else
             MATCH[$CARDS,$SITE]=false
           fi
         done
         BINGO[$CARDS]=0
         CARDS=$((CARDS+1))
       fi
       ;;
  esac
  echo
done

echo -n > "$TOOLNAME.tab"
CARD=0
while [ "$CARD" -lt "$CARDS" ] ; do
  for SITE in {0..24} ; do
    echo -n "${NUM[$CARD,$SITE]} " >> "$TOOLNAME.tab"
  done
  echo >> "$TOOLNAME.tab"
  CARD=$((CARD+1))
done
