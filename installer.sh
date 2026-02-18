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

echo <<EOF
[Interface]
Address = $IP_INTERNAL/32
ListenPort = $LISTEN_PORT
PrivateKey = $KEY_INTERNAL
PostUp = iptables -t nat -A POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE
PostUp = ip rule add from `ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | grep -v "inet6" | head -n 1 | awk '/inet/ {print $2}' | awk -F/ '{print $1}'` table main
PostDown = iptables -t nat -D POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE
PostDown = ip rule del from `ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | grep -v "inet6" | head -n 1 | awk '/inet/ {print $2}' | awk -F/ '{print $1}'` table main
EOF > /etc/wireguard/wg-internal.conf

echo <<EOF
[Interface]
Address=$IP_EXTERNAL/32
PrivateKey=$KEY_EXTERNAL
PostUp = iptables -t nat -A POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o `ip route | awk '/default/ {print $5; exit}'` -j MASQUERADE

[Peer]
PublicKey=$PUBKEY_EXTERNAL
AllowedIPs=10.$MY_IP.0/24
Endpoint=$CURRENT_SERVER_IP:$LISTEN_PORT
PersistentKeepalive=25
EOF > /etc/wireguard/wg-external.conf


echo "Successfully installed!"
