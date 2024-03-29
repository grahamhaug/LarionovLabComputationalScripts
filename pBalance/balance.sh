#!/bin/bash

### COLORS FOR FUN FORMATTING ###
RED='\033[0;31m'
GREEN='\033[0;32m'
PURP='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#get current SU balance from map file
kinetics=$(grep '822917' /usr/local/etc/projectbalance.map | awk '{print $2}')
mechanistic=$(grep '821091' /usr/local/etc/projectbalance.map | awk '{print $2}')
computational=$(grep '822286' /usr/local/etc/projectbalance.map | awk '{print $2}')
excited=$(grep '822917' /usr/local/etc/projectbalance.map | awk '{print $2}')
ermler=$(grep '800705' /usr/local/etc/projectbalance.map | awk '{print $2}')

#grabs fairshare for active allocations
function fairshare {
sshare -a -A Mechanistic-Studies,Kinetics-of-selectiv,Computational-Analys,Excited-state-reacti,SOCI-Xmers -u rdg758
}

#get current values for each allocation
fsKinetics=$(fairshare | awk 'FNR == 8 {print $7}')
fsMech=$(fairshare | awk 'FNR == 10 {print $7}')
fsComp=$(fairshare | awk 'FNR == 4 {print $7}')
fsExcited=$(fairshare | awk 'FNR == 6 {print $7}')
fsSOCI=$(fairshare | awk 'FNR == 12 {print $7}')

printf "\n Allocation      SU Balance     Fairshare"
printf "\n ========================================"
printf '\n Kinetics: \t%10.2f\t%8.4f\n Mechanistic: \t%10.2f\t%8.4f\n Computational: %10.2f\t%8.4f\n Excited: \t%10.2f\t%8.4f\n Ermler: \t%10.2f\t%8.4f\n' "$kinetics" "$fsKinetics" "$mechanistic" "$fsMech" "$computational" "$fsComp" "$excited" "$fsExcited" "$ermler" "$fsSOCI"
echo ""

