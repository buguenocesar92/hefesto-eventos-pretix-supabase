#!/bin/sh
set -eu
python3 /opt/hefesto/validate.py
# Ejecutar nativo cada 60 s despues de finalizar; un solo periodic por instalacion.
while :; do
  /usr/local/bin/pretix cron || exit $?
  sleep 60 &
  wait $!
done
