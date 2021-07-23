#!/bin/bash
SOURCE_DIR=/media/tempdir
DESTINATION_DIR=/media/chia/farm
Discord=true
url="https://discord.com/api/webhooks/yourhook"
plot=$(find ${SOURCE_DIR} -type f -name "*.plot")
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

if [ "${remove_solo_plots}" = true ]; then
  if [ -e delete_solo_plot.log ];
    break
  else
    find ${DESTINATION_DIR} -name "*.plot" -type f -mtime ${days_to_collect_list} > delete-old-plots.log
    # Make a list that will not change as this process runs
    cp delete_solo_plots.log master-list.log
    if [ "${Discord}" = true ]; then
      message="List of solo plots to remove on ${HOSTNAME} generated."
      discord_message $message
    fi
  fi
fi

if [[ ( -n $plot ) ]]; then
  if [ -e /media/tempdir/movingfiles.lock ]; then
     echo "Move job already running...exiting"
     exit
  fi
  ## Creating lock file ##
  touch ${SOURCE_DIR}/movingfiles.lock

  ## Moving the plot file(s) listed in $plots to destination - /media/chia a mergerfs Pool. ##
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
    #mv ${eachplot} ${DESTINATION_DIR}
    rsync --remove-source-files --progress --partial --human-readable ${eachplot} ${DESTINATION_DIR}
    # Remove a solo plot now the pool plot copied, if applicable.
    if [ "${remove_solo_plots}" = true ]; then
      read -r line < delete-old-plots.log
      #or: line=$(sed -n '1p' delete-old-plots.log)
      rm -f ${line}
      if [ "${Discord}" = true ]; then
        message="Removed solo plot ${line} on ${HOSTNAME}."
        discord_message $message
      fi
      ### This command removes the first line from the file.
      sed -i '1d' delete-old-plots.log
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
