#!/usr/bin/env bats
# Tests del punto 9 de la revision: la verificacion final debe capturar
# el exit code real del script, no el de tee. PIPESTATUS[0] con
# set -o pipefail, o ejecutar el script sin pipe, debe reportar 0 cuando
# todo pasa y !=0 cuando falla.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto9: el script devuelve exit 0 cuando todo pasa (sin pipe)" {
    bash "$REPO_ROOT/scripts/coolify-check.sh" > /dev/null 2>&1
}

@test "punto9: PIPESTATUS[0] captura exit 0 cuando el script pasa" {
    set -o pipefail
    bash "$REPO_ROOT/scripts/coolify-check.sh" 2>&1 | tee "$BATS_TEST_TMPDIR/out.log" > /dev/null
    [ "${PIPESTATUS[0]}" -eq 0 ]
}

@test "punto9: PIPESTATUS[0] captura exit !=0 cuando un comando falla" {
    set -o pipefail
    bash -c 'exit 7' > "$BATS_TEST_TMPDIR/out.log" 2>&1 || true
    # Llamamos manualmente al wrapper para inspeccionar PIPESTATUS.
    bash -c 'set -o pipefail; bash -c "exit 7" 2>&1 | tee /dev/null > /dev/null; echo "${PIPESTATUS[0]}"' > "$BATS_TEST_TMPDIR/exit.txt"
    captured="$(cat "$BATS_TEST_TMPDIR/exit.txt")"
    [ "$captured" -eq 7 ]
}

@test "punto9: el chequeo check_no_profile_violations detecta ports prohibidos" {
    rendered="$BATS_TEST_TMPDIR/bad.json"
    cat > "$rendered" <<'JSON'
{
  "services": {
    "app": {
      "environment": {"PRETIX_DATABASE_NAME": "wrong", "PRETIX_DATABASE_SSLMODE": "verify-full"},
      "ports": ["80:80"]
    }
  }
}
JSON
    # Carga solo la funcion check_no_profile_violations desde el script.
    source <(sed -n '/^check_no_profile_violations()/,/^}/p' "$REPO_ROOT/scripts/coolify-check.sh")
    run check_no_profile_violations "$rendered"
    [ "$status" -ne 0 ]
}