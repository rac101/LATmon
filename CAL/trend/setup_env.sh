export INST_DIR=/afs/slac/g/glast/users/chehtman/pass8_GR-v20r09p09_asym_rhel6-64/applications/
export CONFIGVAR=redhat6-x86_64-64bit-gcc44-Debug
source ${INST_DIR}/bin/${CONFIGVAR}/_setup.sh
export CALIBGENCALROOT=${INST_DIR}/calibGenCAL
export XMLBASEXMLPATH=${BASE_DIR}/xmlBase/xml
export PYTHONPATH=${PYTHONPATH}:${GLAST_EXT}/python/2.7.2/lib/python2.7
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/afs/slac/g/glast/users/chehtman/calibGenCAL_analysis/cal_mon/usr/lib
