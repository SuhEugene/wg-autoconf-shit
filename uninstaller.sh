#!/usr/bin/env bash

set -e

echo "Uninstalling..."

echo "Removing wireguard server interface..."
rm /etc/wireguard/wg-server.conf || true

echo "Removing wireguard client interface..."
rm /etc/wireguard/wg-client.conf || true

echo "Uninstalled!"
