#!/usr/bin/env bash

set -e

echo "Uninstalling..."
./uninstaller.sh

echo "Checking ip..."

IP_INTERNAL=10.0.0.1
IP_EXTERNAL=10.0.0.2

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

LISTEN_PORT=$2
while [ true ]; do
  printf "Port to listen: "
  if [ -z "$LISTEN_PORT" ]; then
    read -r LISTEN_PORT
  else
    echo "$LISTEN_PORT"
  fi
  if [[ $LISTEN_PORT -lt 1000 ]] || [[ $LISTEN_PORT -gt 65535 ]]; then
    echo "Port must be between 1000 and 65535"
    LISTEN_PORT=""
    continue
  fi
  if [ -z "$LISTEN_PORT" ]; then
    LISTEN_PORT=""
    continue
  fi
  break
done

PLACEHOLDER_IP=$(curl -s https://api.ipify.org)
while [ true ]; do
  printf "Server IP: "
  read -r CURRENT_SERVER_IP
  if [ -z "$CURRENT_SERVER_IP" ]; then
    printf "Set to $PLACEHOLDER_IP? [y/N] "
    CURRENT_SERVER_IP=$PLACEHOLDER_IP
    read -r answer
    if [[ "$answer" != "y" ]]; then
      continue
    fi
  fi
  if [[ $CURRENT_SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    break
  fi
  echo "Invalid IP"
done

echo "Generating keys..."

KEY_INTERNAL=$(wg genkey)
KEY_EXTERNAL=$(wg genkey)
PUBKEY_INTERNAL=$(echo $KEY_INTERNAL | wg pubkey)
PUBKEY_EXTERNAL=$(echo $KEY_EXTERNAL | wg pubkey)

if [ -z "$KEY_INTERNAL" ] || [ -z "$KEY_EXTERNAL" ]; then
  echo "Failed to generate keys"
  exit 1
fi

echo "Writing configs..."

cat <<INTEOF > /etc/wireguard/wg-internal.conf
[Interface]
Address = $IP_INTERNAL/32
ListenPort = $LISTEN_PORT
PrivateKey = $KEY_INTERNAL
PostUp = iptables -t nat -A POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE
PostUp = ip rule add from `ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | grep -v "inet6" | head -n 1 | awk '/inet/ {print $2}' | awk -F/ '{print $1}'` table main
PostDown = iptables -t nat -D POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE
PostDown = ip rule del from `ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | grep -v "inet6" | head -n 1 | awk '/inet/ {print $2}' | awk -F/ '{print $1}'` table main

[Peer]
PublicKey = $PUBKEY_EXTERNAL
AllowedIPs = $IP_EXTERNAL/32
INTEOF

cat <<EXEOF > ~/wg-external.conf
[Interface]
Address=$IP_EXTERNAL/32
PrivateKey=$KEY_EXTERNAL
PostUp = iptables -t nat -A POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE

[Peer]
PublicKey=$PUBKEY_INTERNAL
AllowedIPs=10.$MY_IP.0/24
Endpoint=$CURRENT_SERVER_IP:$LISTEN_PORT
PersistentKeepalive=25
EXEOF

echo "Successfully installed!"
