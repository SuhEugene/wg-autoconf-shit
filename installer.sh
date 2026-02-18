#!/usr/bin/env bash

./uninstaller.sh

MY_IP=$1
if [ -z "$MY_IP" ]; then
  echo "Usage: $0 <my_ip>"
  exit 1
fi

wg genkey > /etc/wireguard/private.key
ip link add wg0 type wireguard
ip address add 10.7.7.1/24 dev wg0
wg set wg0 private-key /etc/wireguard/private.key
