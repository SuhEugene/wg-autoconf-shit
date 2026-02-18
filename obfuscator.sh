#!/usr/bin/env bash

set -e

git clone https://github.com/ClusterM/wg-obfuscator.git /tmp/wg-obfuscator
cd /tmp/wg-obfuscator
make

printf "Run \"sudo make install\" to install? [y/N] "
read -r answer
if [[ "$answer" != "y" ]]; then
  exit 1
fi
sudo make install
