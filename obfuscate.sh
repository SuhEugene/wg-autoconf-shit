#!/usr/bin/env bash

set -e

KEY=$(openssl rand -hex 16)

read ip port <<< $(awk -F '[ =:]' '/^Endpoint=/{print $2, $3}' /etc/wireguard/wg-client.conf)
sed -i 's/^\(Endpoint\s*=\s*\)\(.*\)/\1127.0.0.1:5555/' /etc/wireguard/wg-client.conf
sed -i 's/^\(#ListenPort\s*=\s*\)\(.*\)/ListenPort=5554/' /etc/wireguard/wg-client.conf

cat <<EOF > ./wg-obfuscator.client.conf
source-lport = 5555
target = $ip:$port
static-bindings = 127.0.0.1:5554:5553
key = $KEY
EOF

server_port=$(awk -F '=' '/^ListenPort/{print $2}' /etc/wireguard/wg-server.conf | tr -d ' ')
sed -i 's/^\(ListenPort\s*=\s*\)\(.*\)/\15555/' /etc/wireguard/wg-server.conf
sed -i 's/^\(#Endpoint\s*=\s*\)\(.*\)/Endpoint=127.0.0.1:5554/' /etc/wireguard/wg-server.conf

cat <<EOF > ./wg-obfuscator.server.conf
source-lport = $server_port
target = 127.0.0.1:5555
static-bindings = 127.0.0.1:5553:5554
key = $KEY
EOF

echo "Which file to copy?"
echo "1. Client config"
echo "2. Server config"
echo "3. None"

read -r choice
case $choice in
  1)
    cp ./wg-obfuscator.client.conf /etc/wg-obfuscator.conf
    ;;
  2)
    cp ./wg-obfuscator.server.conf /etc/wg-obfuscator.conf
    ;;
  *)
    ;;
esac
