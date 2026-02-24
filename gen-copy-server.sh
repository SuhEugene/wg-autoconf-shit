#!/usr/bin/env bash

set -e

if [[ ! -f "./out/wg-server.conf" ]]; then
  echo "Server config ./out/wg-server.conf not found"
  exit 1
fi

if [[ ! -f "./out/wg-obfuscator.server.conf" ]]; then
  echo "Server config ./out/wg-obfuscator.server.conf not found"
  exit 1
fi

echo "Copying ./out/wg-server.conf to /etc/wireguard/wg-server.conf"
cp ./out/wg-server.conf /etc/wireguard/wg-server.conf

echo "Copying ./out/wg-obfuscator.server.conf to /etc/wg-obfuscator.conf"
cp ./out/wg-obfuscator.server.conf /etc/wg-obfuscator.conf

echo "Done."
