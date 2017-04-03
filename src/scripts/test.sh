#! /bin/sh

OUTPUTS=`ls *.output | grep -v -e elemnum -e unittest`

grep ' unexpected \(failures\|passes\):' ${OUTPUTS} | \
    grep -v '\(failures\|passes\): 0'
test $? -eq 1
