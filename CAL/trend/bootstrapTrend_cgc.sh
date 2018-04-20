#!/bin/sh

if [ $# != 3 ]; then
        echo "Usage: " $0 " METstart METend datestring"
        exit 0
fi

export datestring=$3

bsub -q long -W 20:00 -o runtrend-${datestring}.log.txt /afs/slac/g/glast/users/chehtman/calibGenCAL_analysis/cal_mon/runtrend_cgc.sh $1 $2 $3
