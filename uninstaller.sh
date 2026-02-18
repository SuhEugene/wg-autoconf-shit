#!/usr/bin/env bash

set -e

echo "Uninstalling..."

echo "Removing wireguard interface..."
ip link delete wg0 || true

echo "Removing wireguard key..."
rm /etc/wireguard/private.key || true

echo "Uninstalled!"
