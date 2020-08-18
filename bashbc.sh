#!/usr/bin/bash
# A command-line calculator in pure BASH
# (c) 2016 Wei-Lun Chao <bluebat@member.fsf.org>, GPL.
# https://speakerdeck.com/bluebat/a-command-line-calculator-in-pure-bash
# v1.0, 2014-3-25, for C+-*/C and C^(Z/2)
# v1.1, 2016-10-20, tweak n++ and shiftScale

shopt -s extglob
if [ "$scale" -ge 0 -a "$scale" -le 5 ] 2>/dev/null ; then
  declare -i shiftScale="$scale"
else
  declare -i shiftScale=3
fi
declare -i pid=$$

function findOperator {
  declare -l exprStr=$1
  declare -i exprLevel=0
  declare -i posAdd=-1
  declare -i posSub=-1
  declare -i posMul=-1
  declare -i posDiv=-1
  declare -i posPow=-1
  declare -i posFound=-1
  declare -i i=0
  while [ "$i" -lt ${#exprStr} ] ; do
    exprChar=${exprStr:$i:1}
    if [ \"$exprChar\" = '"("' ] ; then
      let exprLevel++
    elif  [ \"$exprChar\" = '")"' ] ; then
      let exprLevel--
    elif [ "$exprLevel" -eq 0 ] ; then
      if [ \"$exprChar\" = '"+"' ] ; then
        posAdd=$i
      elif [ \"$exprChar\" = '"-"' ] ; then
        posSub=$i
      elif [ \"$exprChar\" = '"*"' ] ; then
        posMul=$i
      elif [ \"$exprChar\" = '"/"' ] ; then
        posDiv=$i
      elif [ \"$exprChar\" = '"^"' -a "$posPow" -eq -1 ] ; then
        posPow=$i
      fi
    fi
    let i++
  done
  if [ $posAdd -gt 0 ] ; then
    posFound=$posAdd
  elif [ $posSub -gt 0 ] ; then
    posFound=$posSub
  elif [ $posMul -gt -1 ] ; then
    posFound=$posMul
  elif [ $posDiv -gt -1 ] ; then
    posFound=$posDiv
  elif [ $posPow -gt -1 ] ; then
    posFound=$posPow
  elif [ $posAdd -eq 0 -o $posSub -eq 0 ] ; then
    posFound=0
  fi
  echo $posFound
}

function shiftLeft {
  declare -l valFloat=$1
  declare -i valLen=${#valFloat}
  declare -i shiftLen=$shiftScale\*$2
  declare -l shiftStr=`printf '%0*d' $shiftLen`
  declare -i posPoint=-1
  declare -i valRound=0
  declare -i i=0
  while [ "$i" -lt "$valLen" ] ; do
    if [ "${valFloat:$i:1}" = '.' ] ; then
      posPoint=$i
    fi
    let i++
  done
  declare -l valStr=$valFloat$shiftStr
  if [ "$posPoint" -ne -1 ] ; then
    valStr=${valStr/./}
    if [ "${valStr:$posPoint+$shiftLen:1}" -gt 4 ] ; then
      valRound=1
    fi
    valStr=${valStr:0:$posPoint+$shiftLen}
  fi
  if [ "${valStr:0:1}" = '-' ] ; then
    declare -i valInt=-10#${valStr:1}-$valRound
  else
    declare -i valInt=10#$valStr+$valRound
  fi
  echo $valInt
}

function shiftRight {
  if [ "$1" -lt 0 ] ; then
    declare -l valInt=${1:1}
    declare -i negative=1
  else
    declare -l valInt=$1
    declare -i negative=0
  fi
  declare -i valLen=${#valInt}
  declare -i shiftLen=$shiftScale\*$2
  declare -l shiftStr=`printf '%0*d' $shiftLen`
  if [ "$valLen" -gt "$shiftLen" ] ; then
    declare -l valStr=$valInt
  else
    declare -l valStr=${shiftStr:0:$shiftLen+1-$valLen}$valInt
  fi
  valLen=${#valStr}
  declare -l valFloat=${valStr:0:$valLen-$shiftLen}.${valStr:$valLen-$shiftLen:$shiftLen}
  if [ "$negative" -eq 1 ] ; then
    valFloat=-$valFloat
  fi
  valFloat=${valFloat%%?(.)*(0)}
  echo $valFloat
}

function complexAdd {
  declare -i valReal=`shiftLeft $1 1`+`shiftLeft $3 1`
  declare -i valImag=`shiftLeft $2 1`+`shiftLeft $4 1`
  declare -l exprReal=`shiftRight $valReal 1`
  declare -l exprImag=`shiftRight $valImag 1`
  echo $exprReal $exprImag
}
function complexSub {
  declare -i valReal=`shiftLeft $1 1`-`shiftLeft $3 1`
  declare -i valImag=`shiftLeft $2 1`-`shiftLeft $4 1`
  declare -l exprReal=`shiftRight $valReal 1`
  declare -l exprImag=`shiftRight $valImag 1`
  echo $exprReal $exprImag
}
function complexMul {
  declare -i valReal=`shiftLeft $1 1`\*`shiftLeft $3 1`-`shiftLeft $2 1`\*`shiftLeft $4 1`
  declare -i valImag=`shiftLeft $1 1`\*`shiftLeft $4 1`+`shiftLeft $2 1`\*`shiftLeft $3 1`
  declare -l exprReal=`shiftRight $valReal 2`
  declare -l exprImag=`shiftRight $valImag 2`
  echo $exprReal $exprImag
}
function complexDiv {
  declare -i valDeno=`shiftLeft $3 1`\*`shiftLeft $3 1`+`shiftLeft $4 1`\*`shiftLeft $4 1`
  declare -i valReal=`shiftLeft $1 1`\*`shiftLeft $3 1`+`shiftLeft $2 1`\*`shiftLeft $4 1`
  declare -i valImag=`shiftLeft $2 1`\*`shiftLeft $3 1`-`shiftLeft $1 1`\*`shiftLeft $4 1`
  if [ "$valDeno" -eq 0 ] ; then
    echo -n "Divide by zero. " >&2
    echo 0 0
    kill -9 $pid
    exit 1
  fi
  valReal=`shiftLeft $valReal 1`/$valDeno
  valImag=`shiftLeft $valImag 1`/$valDeno
  declare -l exprReal=`shiftRight $valReal 1`
  declare -l exprImag=`shiftRight $valImag 1`
  echo $exprReal $exprImag
}
function realSqrt {
  declare -l exprReal=1
  if [ "${1:0:1}" = '-' ] ; then
    declare -l valReal=${1:1}
  else
    declare -l valReal=$1
  fi
  declare -i valTemp=0
  declare -i i=0
  while [ "$i" -lt 10 ] ; do
    valTemp=`shiftLeft $exprReal 1`+`shiftLeft $valReal 2`/`shiftLeft $exprReal 1`
    valTemp=`shiftLeft $valTemp 1`/2
    exprReal=`shiftRight $valTemp 2`
    let i++
  done
  if [ "${1:0:1}" = '-' ] ; then
    echo 0 $exprReal
  elif [ "$1" = '0' ] ; then
    echo 0 0
  else
    echo $exprReal 0
  fi
}
function complexPow {
  declare -l exprVal="1 0"
  declare -i i=0
  if [ "${3%.5}" != "$3" -a "$4" = '0' ] ; then
    declare -i valPow=`shiftLeft $3 1`*2
    exprPow=`shiftRight $valPow 1`
    if [ "${1:0:1}" = '-' ] ; then
      declare -l exprTemp=-`complexPow ${1:1} $2 $exprPow $4`
    else
      declare -l exprTemp=`complexPow $1 $2 $exprPow $4`
    fi
    declare -l tempReal=${exprTemp% *}
    declare -l tempImag=${exprTemp#* }
    if [ "$2" = '0' ] ; then
      exprVal=`realSqrt $tempReal`
      echo $exprVal
    else
      declare -i valAbs=`shiftLeft $tempReal 1`\*`shiftLeft $tempReal 1`+`shiftLeft $tempImag 1`\*`shiftLeft $tempImag 1`
      exprAbs=`shiftRight $valAbs 2`
      exprAbs=`realSqrt $exprAbs`
      exprAbs=${exprAbs% 0}
      declare -i valReal=`shiftLeft $exprAbs 1`/2+`shiftLeft $tempReal 1`/2
      exprReal=`shiftRight $valReal 1`
      exprReal=`realSqrt $exprReal`
      exprReal=${exprReal% 0}
      declare -i valImag=`shiftLeft $exprAbs 1`/2-`shiftLeft $tempReal 1`/2
      exprImag=`shiftRight $valImag 1`
      exprImag=`realSqrt $exprImag`
      exprImag=${exprImag% 0}
      if [ "${2:0:1}" = '-' ] ; then
        exprImag=-$exprImag
      fi
      echo $exprReal $exprImag
    fi
  elif [ "$3" != "${3/./}" -o "$4" != '0' ] ; then
    echo -n "Unsupported. " >&2
    echo 0 0
    kill -9 $pid
    exit 1
  else
    if [ "$3" -lt 0 ] ; then
      declare -i valDeno=`shiftLeft $1 1`\*`shiftLeft $1 1`+`shiftLeft $2 1`\*`shiftLeft $2 1`
      declare -i valReal=`shiftLeft $1 3`/$valDeno
      declare -i valImag=-1\*`shiftLeft $2 3`/$valDeno
      declare -l exprReal=`shiftRight $valReal 1`
      declare -l exprImag=`shiftRight $valImag 1`
      declare -i exprPow=-1\*$3
    else
      declare -l exprReal=$1
      declare -l exprImag=$2
      declare -i exprPow=$3
    fi
    while [ "$i" -lt "$exprPow" ] ; do
      exprVal=`complexMul $exprVal $exprReal $exprImag`
      let i++
    done
    echo $exprVal
  fi
}

function complexIn {
  declare -l exprStr=$1
  declare -i exprLen=${#exprStr}
  declare -l exprVal="0 0"
  if [ "$exprLen" -ne 0 ] ; then
    if [ "${exprStr:$exprLen-1}" = 'i' ] ; then
      if [ "$exprLen" -eq 1 ] ; then
        exprVal="0 1"
      else
        exprVal="0 ${exprStr%i}"
      fi
    else
      exprVal="$exprStr 0"
    fi
  fi
  echo $exprVal
}

function complexOut {
  declare -l exprReal=`shiftLeft $1 1`
  declare -l exprImag=`shiftLeft $2 1`
  declare -l exprStr=''
  declare -l shiftStr=`printf '%0*d' $shiftScale`
  if [ "$exprImag" -eq 0 -o "$exprReal" -ne 0 ] ; then
    exprStr=`shiftRight $exprReal 1`
  fi
  if [ "$exprImag" -ne 0 ] ; then
    if [ "$exprImag" -gt 0 -a "$exprReal" -ne 0 ] ; then
      exprStr+='+'
    fi
    if [ "$exprImag" -eq -1$shiftStr ] ; then
      exprStr+='-'
    elif [ "$exprImag" -ne 1$shiftStr ] ; then
      exprStr+=`shiftRight $exprImag 1`
    fi
    exprStr+='i'
  fi
  echo $exprStr
}

function exprEval {
  declare -l exprStr=$1
  declare -i exprLen=${#exprStr}
  declare -i posFound=`findOperator $exprStr`
  declare -l exprVal="0 0"
  if [ "$posFound" -ne -1 ] ; then
    declare -l exprLeft=${exprStr:0:$posFound}
    declare -l valLeft=`exprEval $exprLeft`
    declare -l exprRight=${exprStr:$posFound+1}
    declare -l valRight=`exprEval $exprRight`
    case "${exprStr:$posFound:1}" in
      '+') exprVal=`complexAdd $valLeft $valRight` ;;
      '-') exprVal=`complexSub $valLeft $valRight` ;;
      '*') exprVal=`complexMul $valLeft $valRight` ;;
      '/') exprVal=`complexDiv $valLeft $valRight` ;;
      '^') exprVal=`complexPow $valLeft $valRight` ;;
    esac
  elif [ \"${exprStr:0:1}\" = '"("' -a \"${exprStr:$exprLen-1}\" = '")"' ] ; then
    exprStr=${exprStr:1:$exprLen-2}
    exprVal=`exprEval $exprStr`
  else
    exprVal=`complexIn $exprStr`
  fi
  echo $exprVal
}

if [ $# -eq 0 ] ; then
  echo "A command-line calculator in pure BASH"
  echo "(c) 2016 Wei-Lun Chao <bluebat@member.fsf.org>, GPL."
  echo "Usage: [scale=0..(3)..5] bashbc ARITH_EXPR"
  exit 1
else
  declare -l exprStr=`printf '%s' "$*"`
  declare -l exprVal=`exprEval ${exprStr//[[:space:]]/}`
  complexOut $exprVal
fi
