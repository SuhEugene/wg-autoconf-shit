#!/usr/bin/env bash

ip link delete wg0 || true
rm /etc/wireguard/private.key || true
