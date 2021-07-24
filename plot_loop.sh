#!/bin/bash
# Variables
i=1

# Only arg passed in is how many times to run, if blank, uses default in this script
if [ ! -z $1 ];
then
  count=$1 # $1 was given
else
  count=2 # $1 was not given
fi

threads=4
buckets=256
buckets3=${buckets}
tempdir=/mnt/NVME3/
tempdir2=/mnt/ram/
pool= #Do not use with pool_contract_puzzle_hash
farm=
pool_contract_puzzle_hash=
tmptoggle=false
rmulti2=1
log=/home/chia/chialogs
# Not using as leaving plot on ${tempdir}
dest1=/mnt/D1
dest2=/mnt/D2
dest3=/mnt/D3
dest4=/mnt/D4
dest5=/mnt/D5
dest6=/mnt/D6
dest7=/mnt/D7
dest8=/mnt/D8
dest9=/mnt/D9
dest10=/mnt/D10
mergerfschiapool=
#########################################
# However, leaving in to check the space for those that want to set the loop to a high number
# and exit when destination(s) filled.
declare -a final_dest=(
                       "${dest1}"
                       "${dest2}"
                       "${dest3}"
                       "${dest4}"
                       "${dest5}"
                       "${dest6}"
                       "${dest7}"
                       "${dest8}"
                       "${dest9}"
                       "${dest10}"
max=95%
farm_folder=/ # disk_space check only works with mount points.
Discord=false
url=(Your web hook here)

discord_message () {
  json_payload=$(jq -nc --arg message "${message}" '
     {
       "content" : "\($message)"
     }')

     curl -i \
          -H "Content-Type: application/json" \
          -X POST \
          --data "$json_payload" \
          $url > /dev/null 2>&1
}

disk_space () {

   # Check drive space on dest
  for j in "${final_dest[@]}"
  do
    used=$(df -Ph | grep -G ${j} | awk {'print $5'});
     if [ ${used%?} -ge ${max%?} ];
     then
       dest='' # In case it was set on a run and now is not valid.
       echo "The Mount Point ${j} on ${HOSTNAME} has used ${used} at ${1}." |tee -a ${log}/${1}_plot-${2}.log;
     else
       dest=${j}/${farm_folder};
       echo "New Mount Point on ${HOSTNAME} is ${dest}." |tee -a ${log}/${1}_plot-${2}.log;
       break;
     fi
  done
  if [ "${Discord}" = true ]; then
     message="Final destination for ${HOSTNAME} is set to: ${dest}. If blank, no usable space found."
     discord_message ${message}
  fi
}

# Main run loop
while [ $i -le $count ];
do

   dt=$(date '+%Y-%m-%d_%H_%M_%S');
   disk_space ${dt} ${i}
   if [[ -z $dest ]]; then
     echo "No drive space found on ${HOSTNAME} for final destination!" |tee -a ${log}/${dt}_plot-${i}.log;
     message="No space on ${HOSTNAME}'s drives."
     discord_message ${message}
     exit
   fi

   # Remove any tmp files leftover
   rm -rf ${tempdir}/*.tmp
   rm -rf ${tempdir2}/*.tmp

   echo "Currently plotting number ${i} of ${count} on ${HOSTNAME}. Started on ${dt}." |tee -a ${log}/${dt}_plot-${i}.log
   echo "Log file name is ${log}/${dt}_plot-${i}.log."
   ## discord webhook
   if [ "${Discord}" = true ]; then
     message="Plot ${i} of ${count} on ${HOSTNAME} started at $(date '+%Y-%m-%d_%H:%M:%S')."
     discord_message ${message}
   fi

   ./chia-plotter/build/chia_plot \
   -r ${threads} \
   -u ${buckets} \
   -v ${buckets3} \
   -t ${tempdir} \
   -2 ${tempdir2} \
   -f ${farm} \
   -c ${pool_contract_puzzle_hash} \
   -G ${tmptoggle} \
   -K ${rmulti2} \
   |tee -a ${log}/${dt}_plot-${i}.log
   echo "Plot ${i} of ${count} on ${HOSTNAME} finished at $(date '+%Y-%m-%d_%H:%M:%S')." |tee -a ${log}/${dt}_plot-${i}.log
   echo #Insert a blank line between runs
   ## discord webhook
   if [ "${Discord}" = true ]; then
     message="Plot ${i} of ${count} on ${HOSTNAME} finished at $(date '+%Y-%m-%d_%H:%M:%S')."
     discord_message ${message}
  fi
  i=$(($i=1))
done