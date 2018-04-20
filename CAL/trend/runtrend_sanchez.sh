#!/bin/sh

if [ $# != 3 ]; then
        echo "Usage: " $0 " METstart METend dateString"
        exit 0
fi

cd /afs/slac/g/glast/users/chehtman/calibGenCAL_analysis/cal_mon/

source ./setup_env.sh

export dateString=$3
export METstart=$1
export METend=$2

echo ${LD_LIBRARY_PATH}

export cal_mon_dir=$PWD

cd /usr/tmp/

if [ -d chehtman ]; then

    cd chehtman

else

mkdir chehtman
echo " created folder /usr/tmp/chehtman "
cd chehtman
fi

export cal_mon_tmp=$PWD
cd ${cal_mon_dir}


if [ ! -e $dateString ]; then
    mkdir $dateString
fi

cd $dateString
mkdir sanchez
cp /afs/slac/g/glast/users/chehtman/calibGenCAL_analysis/cal_mon/fixed_files/* .


cd ${cal_mon_tmp}
mkdir sanchez-$dateString
mv ${cal_mon_dir}/$dateString/*.dat sanchez-$dateString
cd sanchez-$dateString
${cal_mon_dir}/Cal_thres_mon.py ${METstart} ${METend}

rm r*.root

cp *.png ${cal_mon_dir}/$dateString/sanchez

# update the dat files (since Cal_thresh_mon.py depends on updated files for speed)

cd ${cal_mon_dir}/fixed_files
mkdir $dateString
mv fhemon.dat  flemon.dat lacmon.dat  lacmonneg.dat  lacmonpos.dat $dateString
cd ${cal_mon_tmp}/sanchez-$dateString
cp fhemon.dat  flemon.dat lacmon.dat  lacmonneg.dat  lacmonpos.dat ${cal_mon_dir}/fixed_files
