#!/bin/bash
Discord=true
url="https://discord.com/api/webhooks/yourhook"
plot=$(find /media/tempdir -type f -name "*.plot")

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
  touch /media/tempdir/movingfiles.lock

  ## Moving the plot files listed in $yourfilenames to destination - /media/chia a mergerfs Pool. ##
  if [ "${Discord}" = true ]; then
      message="Move started at $(date '+%Y-%m-%d_%H:%M:%S') of file(s)."
      discord_message $message
  fi

  mv /media/tempdir/*.plot /media/chia/farm

  ##  Move complete, removing lock file ##
  rm /media/tempdir/movingfiles.lock

  ## Lock file removed, copy complete ##
  if [ "${Discord}" = true ]; then
    message="Move finished at $(date '+%Y-%m-%d_%H:%M:%S') of file(s)."
    discord_message ${message}
  fi
fi
