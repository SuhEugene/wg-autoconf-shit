#!/usr/bin/env bash

set -e

echo "Uninstalling..."
./uninstaller.sh

echo "Checking ip..."

IP_INTERNAL=10.0.0.1
IP_EXTERNAL=10.0.0.2

IP_IS_FINAL=0
MY_IP=$1

while [ true ]; do
  if [ -z "$MY_IP" ]; then
    printf "Enter IP subnet: 10."
    read -r MY_IP
  fi
  echo "IP will look like this: 10.$MY_IP.1"
  IP_INTERNAL=10.$MY_IP.1
  IP_EXTERNAL=10.$MY_IP.2
  printf "Is that correct? [y/N] "
  read -r answer
  if [[ "$answer" != "y" ]]; then
    MY_IP=""
    continue
  fi
  break
done

echo "Installing..."

wg genkey > /etc/wireguard/private.key
ip link add wg0 type wireguard
ip address add 10.7.7.1/24 dev wg0
wg set wg0 private-key /etc/wireguard/private.key

echo "Successfully installed!"
