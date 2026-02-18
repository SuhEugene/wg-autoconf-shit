#!/usr/bin/env bash

set -e

echo "Uninstalling..."

echo "Removing wireguard internal interface..."
rm /etc/wireguard/wg-internal.conf

echo "Removing wireguard external interface..."
rm /etc/wireguard/wg-external.conf

echo "Uninstalled!"
