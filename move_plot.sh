#!/bin/bash
SOURCE_DIR=/media/tempdir
DESTINATION_DIR=/media/chia/farm
Discord=true
url="https://discord.com/api/webhooks/yourhook"
plot=$(find ${SOURCE_DIR} -type f -name "*.plot")

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
    #mv /media/tempdir/${eachplot} ${DESTINATION_DIR}
    rsync --remove-source-files --progress --partial --human-readable ${eachplot} ${DESTINATION_DIR}
  done

  ##  Move complete, removing lock file ##
  rm ${SOURCE_DIR}/movingfiles.lock

  ## Lock file removed, copy complete ##
  if [ "${Discord}" = true ]; then
    message="Move on ${HOSTNAME} of plot(s) finished at $(date '+%Y-%m-%d_%H:%M:%S')."
    discord_message ${message}
  fi
fi
