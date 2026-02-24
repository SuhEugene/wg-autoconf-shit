#!/usr/bin/env bash

set -e

if [[ $# -le 1 ]]; then
  echo "Usage: $0 <remote_user@host> [client_id]" >&2
  exit 2
fi

CLIENT_ID=$2
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

if [[ ! -f "./out/wg-client.$CLIENT_ID.conf" ]]; then
  echo "Client config ./out/wg-client.$CLIENT_ID.conf not found"
  exit 1
fi

if [[ ! -f "./out/wg-obfuscator.client.conf" ]]; then
  echo "Client config ./out/wg-obfuscator.client.conf not found"
  exit 1
fi

echo "Copying ./out/wg-client.$CLIENT_ID.conf to $1"
./copy-to-remote.sh $1 ./out/wg-client.$CLIENT_ID.conf /etc/wireguard/wg-client.conf

echo "Copying ./out/wg-obfuscator.client.conf to $1"
./copy-to-remote.sh $1 ./out/wg-obfuscator.client.conf /etc/wg-obfuscator.conf

echo "Done."
