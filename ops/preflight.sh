#!/bin/sh
set -eu
[ "$SUPABASE_DEDICATED_CONFIRMED" = true ] || { echo 'Confirmar proyecto exclusivo'; exit 1; }
[ "$SUPABASE_DATA_API_DISABLED" = true ] || { echo 'Desactivar Data API y confirmar'; exit 1; }
# La CA solo es obligatoria cuando sslmode=verify-full; con disable u otros
# modos la conexion no exige sslrootcert.
if [ "${PGSSLMODE:-verify-full}" = "verify-full" ]; then
    [ -s "$PGSSLROOTCERT" ] || { echo 'Falta CA DB'; exit 1; }
fi
psql --no-psqlrc -v ON_ERROR_STOP=1 -f /opt/hefesto/preflight.sql
