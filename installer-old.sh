#!/usr/bin/env bash

set -e

echo "Checking ip..."

INTERNAL_SERVER_IP=10.0.0.1
INTERNAL_CLIENT_IP=10.0.0.2

MY_IP=$1

while [ true ]; do
  if [ -z "$MY_IP" ]; then
    printf "Enter IP subnet: 10."
    read -r MY_IP
  fi
  if [[ ! $MY_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Wrong IP format"
    MY_IP=""
    continue
  fi
  echo "IP will look like this: 10.$MY_IP.1"
  INTERNAL_SERVER_IP=10.$MY_IP.1
  INTERNAL_CLIENT_IP=10.$MY_IP.2
  printf "Is that correct? [y/N] "
  read -r answer
  if [[ "$answer" != "y" ]]; then
    MY_IP=""
    continue
  fi
  break
done

PUBLIC_SERVER_PORT=$2
while [ true ]; do
  printf "Public server port: "
  if [ -z "$PUBLIC_SERVER_PORT" ]; then
    read -r PUBLIC_SERVER_PORT
  else
    echo "$PUBLIC_SERVER_PORT"
  fi
  if [[ $PUBLIC_SERVER_PORT -lt 1000 ]] || [[ $PUBLIC_SERVER_PORT -gt 65535 ]]; then
    echo "Port must be between 1000 and 65535"
    PUBLIC_SERVER_PORT=""
    continue
  fi
  if [ -z "$PUBLIC_SERVER_PORT" ]; then
    PUBLIC_SERVER_PORT=""
    continue
  fi
  break
done

OBFUSCATOR_PORT=$3
while [ true ]; do
  printf "Obfuscator port: "
  if [ -z "$OBFUSCATOR_PORT" ]; then
    read -r OBFUSCATOR_PORT
  else
    echo "$OBFUSCATOR_PORT"
  fi
  if [[ $OBFUSCATOR_PORT -lt 1000 ]] || [[ $OBFUSCATOR_PORT -gt 65535 ]]; then
    echo "Port must be between 1000 and 65535"
    OBFUSCATOR_PORT=""
    continue
  fi
  if [[ $SERVER_PORT == $OBFUSCATOR_PORT ]]; then
    echo "Obfuscator port must be different from listen port"
    OBFUSCATOR_PORT=""
    continue
  fi
  if [ -z "$OBFUSCATOR_PORT" ]; then
    OBFUSCATOR_PORT=""
    continue
  fi
  break
done

PLACEHOLDER_IP=$(curl -s https://api.ipify.org)
PUBLIC_SERVER_IP=$4
while [ true ]; do
  printf "Server IP ($PLACEHOLDER_IP): "
  if [ -z "$PUBLIC_SERVER_IP" ]; then
    read -r PUBLIC_SERVER_IP
  else
    echo "$PUBLIC_SERVER_IP"
  fi
  if [ -z "$PUBLIC_SERVER_IP" ]; then
    printf "Set to $PLACEHOLDER_IP? [y/N] "
    PUBLIC_SERVER_IP=""
    read -r answer
    if [[ "$answer" != "y" ]]; then
      continue
    fi
    PUBLIC_SERVER_IP=$PLACEHOLDER_IP
  fi
  if [[ $PUBLIC_SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    break
  fi
  echo "Invalid IP"
  PUBLIC_SERVER_IP=""
done

echo "Generating keys..."

SERVER_KEY_PRIVATE=$(wg genkey)
CLIENT_KEY_PRIVATE=$(wg genkey)
SERVER_KEY_PUBLIC=$(echo $SERVER_KEY_PRIVATE | wg pubkey)
CLIENT_KEY_PUBLIC=$(echo $CLIENT_KEY_PRIVATE | wg pubkey)
OBFUSCATOR_KEY=$(openssl rand -hex 24)

if [ -z "$SERVER_KEY_PRIVATE" ] || [ -z "$CLIENT_KEY_PRIVATE" ] || [ -z "$SERVER_KEY_PUBLIC" ] || [ -z "$CLIENT_KEY_PUBLIC" ] || [ -z "$OBFUSCATOR_KEY" ]; then
  echo "Failed to generate keys"
  exit 1
fi

echo "Generating configs..."

INTERNAL_SERVER_IP_CIDR=10.$MY_IP.0/24

do_sed() {
  file_from=$1
  file_to=$2
  sed "s#OBFUSCATOR_PORT#$OBFUSCATOR_PORT#g" $file_from > $file_to
  sed -i "s#OBFUSCATOR_KEY#$OBFUSCATOR_KEY#g" $file_to

  sed -i "s#PUBLIC_SERVER_IP#$PUBLIC_SERVER_IP#g" $file_to
  sed -i "s#PUBLIC_SERVER_PORT#$PUBLIC_SERVER_PORT#g" $file_to

  sed -i "s#INTERNAL_SERVER_IP_CIDR#$INTERNAL_SERVER_IP_CIDR#g" $file_to
  sed -i "s#INTERNAL_CLIENT_IP#$INTERNAL_CLIENT_IP#g" $file_to
  sed -i "s#INTERNAL_SERVER_IP#$INTERNAL_SERVER_IP#g" $file_to

  sed -i "s#CLIENT_KEY_PRIVATE#$CLIENT_KEY_PRIVATE#g" $file_to
  sed -i "s#CLIENT_KEY_PUBLIC#$CLIENT_KEY_PUBLIC#g" $file_to

  sed -i "s#SERVER_KEY_PRIVATE#$SERVER_KEY_PRIVATE#g" $file_to 
  sed -i "s#SERVER_KEY_PUBLIC#$SERVER_KEY_PUBLIC#g" $file_to
}

mkdir -p out

do_sed ./templates/wg.server.part1.conf ./out/wg-server.part1.conf
do_sed ./templates/wg.server.part2.conf ./out/wg-server.part2.conf
cat ./out/wg-server.part1.conf > ./out/wg-server.conf
cat ./out/wg-server.part2.conf >> ./out/wg-server.conf
rm ./out/wg-server.part1.conf
rm ./out/wg-server.part2.conf

do_sed ./templates/wg-obfuscator.server.conf ./out/wg-obfuscator.server.conf
do_sed ./templates/wg.client.conf ./out/wg-client.conf
do_sed ./templates/wg-obfuscator.client.conf ./out/wg-obfuscator.client.conf

echo "Successfully generated!"
