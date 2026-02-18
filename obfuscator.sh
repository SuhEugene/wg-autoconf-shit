#!/usr/bin/env bash

set -e

COMMAND_MISSING=false
if ! command -v git &> /dev/null; then
  echo "git is not installed"
  COMMAND_MISSING=true
fi
if ! command -v make &> /dev/null; then
  echo "make is not installed"
  COMMAND_MISSING=true
fi
if ! command -v gcc &> /dev/null; then
  echo "gcc is not installed"
  COMMAND_MISSING=true
fi
if $COMMAND_MISSING; then
  exit 1
fi

git clone https://github.com/ClusterM/wg-obfuscator.git /tmp/wg-obfuscator
cd /tmp/wg-obfuscator
make

printf "Run \"sudo make install\" to install? [y/N] "
read -r answer
if [[ "$answer" != "y" ]]; then
  exit 1
fi
sudo make install
