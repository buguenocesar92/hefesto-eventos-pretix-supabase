#!/bin/sh
set -eu
python3 /opt/hefesto/validate.py
exec /usr/local/bin/pretix "$@"
