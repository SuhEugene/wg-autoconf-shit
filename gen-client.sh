#!/usr/bin/env bash

set -e

CLIENT_ID=$3
while [ true ]; do
  printf "Client id: "
  if [ -z "$CLIENT_ID" ]; then
    read -r CLIENT_ID
  else
    echo "$CLIENT_ID"
  fi
  if [[ $CLIENT_ID -lt 2 ]] || [[ $CLIENT_ID -gt 254 ]]; then
    echo "Client id must be between 2 and 254"
    CLIENT_ID=""
    continue
  fi
  if [ -z "$CLIENT_ID" ]; then
    CLIENT_ID=""
    continue
  fi
  break
done

CLIENT_KEY_PRIVATE=$(wg genkey)
CLIENT_KEY_PUBLIC=$(echo $CLIENT_KEY_PRIVATE | wg pubkey)

do_sed() {
  file_from=$1
  file_to=$2

  echo "Generating config $file_to"

  cp $file_from $file_to

  sed -i "s#CLIENT_ID#$CLIENT_ID#g" $file_to
  sed -i "s#CLIENT_KEY_PRIVATE#$CLIENT_KEY_PRIVATE#g" $file_to
  sed -i "s#CLIENT_KEY_PUBLIC#$CLIENT_KEY_PUBLIC#g" $file_to
}

do_sed ./out/wg-client.conf ./out/wg-client.$CLIENT_ID.conf
do_sed ./out/work/wg-server.part2.conf ./out/work/wg-server.client.$CLIENT_ID.conf

echo "Merging all clients to ./out/wg-server.conf"
cat ./out/work/wg-server.part1.conf > ./out/wg-server.conf
cat ./out/work/wg-server.client.*.conf >> ./out/wg-server.conf
