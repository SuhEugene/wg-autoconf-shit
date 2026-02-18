#!/usr/bin/env bash

set -e

echo "Uninstalling..."
./uninstaller.sh

echo "Checking ip..."

MY_IP=$1
if [ -z "$MY_IP" ]; then
  echo "Usage: $0 <my_ip>"
  exit 1
fi

echo "You want to use $MY_IP as your IP"
printf "Is that correct? [y/N] "
read -r answer
if [[ "$answer" != "y" ]]; then
  echo "Exiting..."
  exit 1
fi

echo "Installing..."

wg genkey > /etc/wireguard/private.key
ip link add wg0 type wireguard
ip address add 10.7.7.1/24 dev wg0
wg set wg0 private-key /etc/wireguard/private.key

echo "Successfully installed!"
