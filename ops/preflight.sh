#!/bin/sh
set -eu
[ "$SUPABASE_DEDICATED_CONFIRMED" = true ] || { echo 'Confirmar proyecto exclusivo'; exit 1; }
[ "$SUPABASE_DATA_API_DISABLED" = true ] || { echo 'Desactivar Data API y confirmar'; exit 1; }
[ -s "$PGSSLROOTCERT" ] || { echo 'Falta CA DB'; exit 1; }
psql --no-psqlrc -v ON_ERROR_STOP=1 -f /opt/hefesto/preflight.sql
