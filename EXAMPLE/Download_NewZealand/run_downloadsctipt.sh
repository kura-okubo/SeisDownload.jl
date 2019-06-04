#!/usr/local/bin/zsh
while getopts ":hn:" OPT
do
  case $OPT in
    n) OPT_FLAG_n=1;OPT_VALUE_n="$OPTARG" ;;
    h) echo  "option: -n num of mpi processors";exit 0;;
    :) echo  "[ERROR] Option argument is undefined.";;   #
    \?) echo "[ERROR] Undefined options.";;
  esac
done

shift $(($OPTIND - 1))
if [[ -n "${OPT_FLAG_n+UNDEF}" ]];then
  echo "num of processors="${OPT_VALUE_n}
  np=${OPT_VALUE_n}
else
  echo "np = 1 [default]. use -n for assign num of np."
  np=1
fi

#specify absolute path to julia
mpirun -np ${np} /Applications/Julia-1.1.app/Contents/Resources/julia/bin/julia ./exec.jl
