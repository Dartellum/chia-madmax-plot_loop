#!/bin/bash
SOURCE_DIR=/mnt/NVME3
Discord=false
url="https://discord.com/api/webhooks/yourhook"
plot=$(find ${SOURCE_DIR} -type f -name "*.plot")
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
                       #"${mergerfschiapool}"
                      )
# If your final location for farming is not the root of the drive, put folder with trailing slash
# here. Example: farm/. Does need trailing slash. If no directory, leave the blank.
farm_folder=
###### Section for settings to removing existing sole plots based on time stamp
remove_solo_plots=false
###### Set this to the number of days in the past to collect the list of plots.
###### Example, last solo plot was 16 days ago and now pool plots are generated. The +15 will
###### grab the files dated 15 days from the run time of this move. This list is now set and will
###### not collect again unless the file delete-old-plots.log is renamed or deleted.
days_to_collect_list=+15

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
       echo "The Mount Point ${j} on ${HOSTNAME} has used ${used}."
     else
       dest=${j}/${farm_folder};
       echo "New Mount Point on ${HOSTNAME} is ${dest}."
       break;
     fi
  done
  if [ "${Discord}" = true ]; then
     message="Final destination for ${HOSTNAME} is set to: ${dest}. If blank, no usable space found."
     discord_message ${message}
  fi
}

disk_space
if [[ -z $dest ]]; then
  echo "No drive space found on ${HOSTNAME} for final destination!"
  message="No space on ${HOSTNAME}'s drives."
  discord_message ${message}
  exit
fi

if [ "${remove_solo_plots}" = true ]; then
  if [ -e delete-old-plots-${dest}.log ]; then
    break
  else
    folder=$(echo ${dest} | sed 's/\(.*\)\/\(.*\)\/\(.*\)$/\2/')
    find ${dest} -name "*.plot" -type f -mtime ${days_to_collect_list} > delete-old-plots-${folder}.log
    # Make a list that will not change as this process runs
    cp delete-old-plots-${folder}.log master-list-${folder}.log
    if [ "${Discord}" = true ]; then
      message="List of solo plots to remove on ${HOSTNAME} generated."
      discord_message $message
    fi
  fi
fi

if [[ ( -n $plot ) ]]; then
  if [ -e ${SOURCE_DIR}/movingfiles.lock ]; then
     echo "Move job already running...exiting"
     exit
  fi
  ## Creating lock file ##
  touch ${SOURCE_DIR}/movingfiles.lock

  ## Moving the plot file(s) listed in $plots to destination. ##
  if [ "${Discord}" = true ]; then
      message="Move on ${HOSTNAME} started at $(date '+%Y-%m-%d_%H:%M:%S') of file(s)."
      discord_message $message
  fi

  plots="$SOURCE_DIR"/*.plot

  for eachplot in ${plots};
  do
    if [ "${Discord}" = true ]; then
      message="Moving ${eachplot} on ${HOSTNAME} to farm. Started $(date '+%Y-%m-%d_%H:%M:%S')."
      discord_message $message
    fi
    #mv ${eachplot} ${dest} #${DESTINATION_DIR}
    rsync --remove-source-files --progress --partial --human-readable ${eachplot} ${dest}
    # Remove a solo plot now the pool plot copied, if applicable.
    if [ "${remove_solo_plots}" = true ]; then
      read -r line < delete-old-plots-${dest}.log
      #or: line=$(sed -n '1p' delete-old-plots-${dest}.log)
      rm -f ${line}
      if [ "${Discord}" = true ]; then
        message="Removed solo plot ${line} on ${HOSTNAME}."
        discord_message $message
      fi
      ### This command removes the first line from the file.
      sed -i '1d' delete-old-plots-${folder}.log
    fi
  done

  ##  Move complete, removing lock file ##
  rm ${SOURCE_DIR}/movingfiles.lock

  ## Lock file removed, copy complete ##
  if [ "${Discord}" = true ]; then
    message="Move on ${HOSTNAME} of plot(s) finished at $(date '+%Y-%m-%d_%H:%M:%S')."
    discord_message ${message}
  fi
fi

#UNSET section
unset folder
unset message