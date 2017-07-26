#!/bin/bash
set -eo pipefail

sudo dnctl pipe 1 config bw 10Mbit/s

make all

sudo dnctl -f flush
sudo pfctl -f /etc/pf.conf