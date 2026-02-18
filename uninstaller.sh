#!/usr/bin/env bash

set -e

echo "Uninstalling..."

echo "Removing wireguard internal interface..."
rm /etc/wireguard/wg-internal.conf || true

echo "Removing wireguard external interface..."
rm ~/wg-external.conf || true

echo "Uninstalled!"
