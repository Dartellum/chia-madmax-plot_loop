#!/bin/bash
# Variables
dest="" # Need to reset to empty

# Only arg passed in is how many times to run, if blank, uses default in this script
if [ ! -z $1 ];
then
  count=$1 # $1 was given
else
  count=2 # $1 was not given
fi
echo "count is $count."
threads=4
buckets=256
buckets3=${buckets}
tempdir=/media/plots-02/temp/
tempdir2=/media/plots/temp/
pool=
farm=
tmptoggle=false
log=/home/chia/chialogs
dest1=/media/plots-02
dest2=/media/plots-03
declare -a final_dest=(
                       "${dest1}"
                       "${dest2}"
                      )
max=95%
farm_folder=farm/ # disk_space check only works with mount points.

disk_space () {
   # Check drive space on dest
  for j in "${final_dest[@]}"
  do
    used=$(df -Ph | grep -G ${j} | awk {'print $5'});
     if [ ${used%?} -ge ${max%?} ];
     then
       dest=”” # In case it was set on a run and now is not valid.
       echo "The Mount Point ${j} on $(hostname) has used ${used} at $1." |tee -a ${log}/${1}_plot-${2}.log;
     else
       dest=${j}/${farm_folder};
       echo "New Mount Point is $dest." |tee -a ${log}/${1}_plot-${2}.log;
       break;
     fi
  done
}

# Main run loop
for i in $(seq 1 $count);
do

   dt=$(date '+%Y-%m-%d_%H_%M_%S');
   disk_space ${dt} ${i}
   if [[ -z $dest ]]; then
     echo "No drive space found for final destination!" |tee -a ${log}/${dt}_plot-${i}.log;
     exit
   fi

   # Remove any tmp files leftover
   rm -rf ${tempdir}*.tmp
   rm -rf ${tempdir2}*.tmp

   echo "Currently plotting number ${i} of ${count} and started on ${dt}." |tee -a ${log}/${dt}_plot-${i}.log
   ./chia-plotter/build/chia_plot \
   -r ${threads} \
   -u ${buckets} \
   -v ${buckets3} \
   -t ${tempdir} \
   -2 ${tempdir2} \
   -d ${dest} \
   -p ${pool} \
   -f ${farm} \
   -G ${tmptoggle} \
   |tee -a ${log}/${dt}_plot-${i}.log
   echo "Time plot $i finished is $(date '+%H:%M:%S')." |tee -a ${log}/${dt_plot}-${i}.log
done
