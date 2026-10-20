#!/usr/bin/env bats
# Tests del punto 7 de la revision: scripts/coolify-check.sh debe
# comprobar los valores DB_NAME y DB_SSLMODE en services.app.environment
# con jq, no por grep sobre JSON renderizado.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto7: el script consulta PRETIX_DATABASE_NAME por jq" {
    grep -q "PRETIX_DATABASE_NAME" "$REPO_ROOT/scripts/coolify-check.sh"
}

@test "punto7: el script consulta PRETIX_DATABASE_SSLMODE por jq" {
    grep -q "PRETIX_DATABASE_SSLMODE" "$REPO_ROOT/scripts/coolify-check.sh"
}

@test "punto7: el script accede a services.app.environment con jq" {
    grep -qE "\.services\.app\.environment|services\[.app.\]\.environment" "$REPO_ROOT/scripts/coolify-check.sh"
}

@test "punto7: el chequeo de supabase-pg ya no depende solo de grep" {
    # Ninguna funcion de chequeo debe quedarse solo con grep -q sobre el JSON.
    ! awk '
        /check_supabase_pg_values/ {in_fn=1}
        in_fn {print}
        in_fn && /^}/ {in_fn=0; exit}
    ' "$REPO_ROOT/scripts/coolify-check.sh" | grep -qE 'grep.*disable|grep.*mvp_prueba'
}

@test "punto7: el script emite el mensaje app: DB_NAME/DB_SSLMODE no llegan al servicio web" {
    grep -q "DB_NAME/DB_SSLMODE no llegan al servicio web" "$REPO_ROOT/scripts/coolify-check.sh"
}