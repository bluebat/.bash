#!/usr/bin/bash
# Preferred Choices Arrangement
# MIT license, 20250923~20250926
# Wei-Lun Chao <bluebat@member.fsf.org>

# INPUT.txt sample: (lines between COMMENTBLOCKs)
<<COMMENTBLOCK
# choice_code choice_name male_max female_min
A Choice-A 3 1
B Choice-B 3 1
C Choice-C 4
#..Z
# person_number person_name person_gender 1st_prefer 2nd_prefer 3rd_prefer ..9th
1 Person_1 M A B C
2 Person_2 M B C
3 Person_3 F B * *
4 Person_4 F C A *
5 Person_5 M A C B
#..99
COMMENTBLOCK

declare -a Data
declare -A Choice Person Arrange
declare -u Choice_Max=A Prefer_Star
declare -i Person_Max=1 Prefer_Max=1

if test -z "$1"; then
  Data_File=/dev/stdin
elif test -f "$1"; then
  Data_File="$1"
elif test "$1" = -s -o "$1" = --sample; then
  for cc in {A..F}; do
    echo $cc Choice-$cc 7 3
  done
  for pn in {1..27}; do
    echo -n $pn Person_$pn ""
    test $RANDOM -lt 16384 && echo -n M || echo -n F
    choices=ABCDEF
    for pc in 6 5 4; do
      pf=${choices:$(($RANDOM*$pc/32768)):1}
      echo -n "" $pf
      choices=${choices/$pf}
    done
    echo
  done
  exit
else
  echo Preferred Choices Arrangement
  echo "Usage: $0 [-s|--sample|INPUT.txt]"
  exit 1
fi

while read -a Data; do
  case "${Data[0]}" in
    [A-Z])
      Choice[${Data[0]},name]="${Data[1]}"
      test -n "${Data[2]}" && Choice[${Data[0]},male_max]=${Data[2]} || Choice[${Data[0]},male_max]=0
      Choice[${Data[0]},female_min]="${Data[3]}"
      test "${Data[0]}" \> "$Choice_Max" && Choice_Max="${Data[0]}"
      ;;
    [1-9]|[1-9][0-9])
      Person[${Data[0]},name]="${Data[1]}"
      Person[${Data[0]},gender]="${Data[2]}"
      for pf in {1..9}; do
        if test -z "${Data[$(($pf+2))]}"; then
          test $(($pf-1)) -gt $Prefer_Max && Prefer_Max=$(($pf-1))
          break
        else
          Person[${Data[0]},$pf]="${Data[$(($pf+2))]}"
          test "${Data[$(($pf+2))]}" = "*" && Prefer_Star=Y
        fi
      done
      Person[${Data[0]},luck]=0
      test "${Data[0]}" -gt "$Person_Max" && Person_Max="${Data[0]}"
      ;;
  esac
done < $Data_File

for pm in letter star; do
  for pf in {1..9}; do
    for cc in {A..Z}; do
      if test -z "${Choice[$cc,female_min]}"; then
        Person_Gender="MF"
        Gender_Total=${Choice[$cc,male_max]}
      else
        Person_Gender="M F"
        Gender_Total=$((${Choice[$cc,female_min]}+${Choice[$cc,male_max]}))
      fi
      if test $Gender_Total -gt 0; then
        Male_Count=0
        Female_Count=0
        test $pm = letter && Prefer_Value=$cc || Prefer_Value="*"
        for pn in {1..99}; do
          if test "${Person[$pn,$pf]}" = "$Prefer_Value" -a "${Arrange[$pn,$cc]}" != Y; then
            if test "$Person_Gender" = "MF"; then
              let Male_Count+=1
            else
              test "${Person[$pn,gender]}" = M && let Male_Count+=1 || let Female_Count+=1
            fi
          fi
          test $pn -eq $Person_Max && break
        done
        for pg in $Person_Gender; do
          if test -z "${pg##*M*}"; then
            Person_Count=$Male_Count
            Gender_Max=${Choice[$cc,male_max]}
          else
            Person_Count=$Female_Count
            Gender_Max=$((${Choice[$cc,female_min]}+${Choice[$cc,male_max]}))
          fi
          if test $(($Person_Count*$Gender_Max)) -eq 0; then
            true
          elif test $Person_Count -le $Gender_Max; then
            for pn in {1..99}; do
              if test "${Person[$pn,$pf]}" = "$Prefer_Value" -a "${Arrange[$pn,$cc]}" != Y -a -z "${pg##*${Person[$pn,gender]}*}"; then
                Arrange[$pn,$cc]=Y
                let Person[$pn,luck]+=1
                if test -n "${pg##*M*}"; then
                  if test "${Choice[$cc,female_min]}" -gt 0; then
                    let Choice[$cc,female_min]-=1
                  else
                    let Choice[$cc,male_max]-=1
                  fi
                else
                  let Choice[$cc,male_max]-=1
                fi
              fi
              test $pn -eq $Person_Max && break
            done
          else
            while test $Gender_Max -gt 0; do
              for pn in {1..99}; do
                if test "${Person[$pn,$pf]}" = "$Prefer_Value" -a "${Arrange[$pn,$cc]}" != Y -a -z "${pg##*${Person[$pn,gender]}*}" -a $Gender_Max -gt 0; then
                  if test $RANDOM -lt $((32768*$Gender_Max/$Person_Count/(1+${Person[$pn,luck]}))); then
                    Arrange[$pn,$cc]=Y
                    let Person[$pn,luck]+=1
                    if test -n "${pg##*M*}"; then
                      if test "${Choice[$cc,female_min]}" -gt 0; then
                        let Choice[$cc,female_min]-=1
                      else
                        let Choice[$cc,male_max]-=1
                      fi
                    else
                      let Choice[$cc,male_max]-=1
                    fi
                    let Gender_Max-=1 Person_Count-=1
                  fi
                fi
                test $pn -eq $Person_Max && break
              done
            done
          fi
        done
      fi
      test $cc = $Choice_Max && break
    done
    test $pf = $Prefer_Max && break
  done
  test -z "$Prefer_Star" && break
done

for pn in {1..99}; do
  echo -n $pn. ${Person[$pn,name]}"("${Person[$pn,gender]}"): "
  for cc in {A..Z}; do
    test "${Arrange[$pn,$cc]}" = Y && echo -n ${Choice[$cc,name]} ""
    test $cc = $Choice_Max && break
  done
  echo
  test $pn -eq $Person_Max && break
done
echo
for cc in {A..Z}; do
  echo -n $cc. ${Choice[$cc,name]}": "
  for pn in {1..99}; do
    test "${Arrange[$pn,$cc]}" = Y && echo -n ${Person[$pn,name]}"("${Person[$pn,gender]}") "
    test $pn -eq $Person_Max && break
  done
  echo
  test $cc = $Choice_Max && break
done
