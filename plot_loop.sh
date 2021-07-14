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
tempdir=/media/plots-02/temp/
tempdir2=/media/plots/temp/
pool= #Do not use with pool_contract_puzzle_hash
farm=
pool_contract_puzzle_hash=
tmptoggle=false
rmulti2=1
log=/home/chia/chialogs
dest1=/media/plots-02
dest2=/media/plots-03
declare -a final_dest=(
                       "${dest1}"
                       "${dest2}"
                      )
max=95%
farm_folder=farm/ # disk_space check only works with mount points.
Discord=false
url=(Your web hook here)

discord_message () {
  json_payload=$(jq -nc --arg message "$message" '
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
       echo "New Mount Point is ${dest}." |tee -a ${log}/${1}_plot-${2}.log;
       break;
     fi
  done
  if [ "${Discord}" = true ]; then
     message="Final destination for ${HOSTNAME} is set to: ${dest}. If blank, no usable space found."
     discord_message ${message}
}

# Main run loop
while [ $i -le $count ];
do

   dt=$(date '+%Y-%m-%d_%H_%M_%S');
   disk_space ${dt} ${i}
   if [[ -z $dest ]]; then
     echo "No drive space found on {HOSTNAME} for final destination!" |tee -a ${log}/${dt}_plot-${i}.log;
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
