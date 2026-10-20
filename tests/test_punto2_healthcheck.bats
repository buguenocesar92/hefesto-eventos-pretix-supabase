#!/usr/bin/env bats
# Tests del punto 2 de la revision: healthcheck real en app y descripcion
# coherente en README.md.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto2: app tiene bloque healthcheck en compose.yaml" {
    # Renderizar compose y comprobar que app.services.healthcheck existe.
    bash "$REPO_ROOT/scripts/coolify-check.sh" > /dev/null 2>&1 || true
    rendered="$BATS_TEST_TMPDIR/compose.json"
    envfile="$BATS_TEST_TMPDIR/.env"
    : > "$envfile"
    for v in DB_HOST DB_PASSWORD DJANGO_SECRET PUBLIC_URL SMTP_HOST MAIL_FROM SUPABASE_DEDICATED_CONFIRMED SUPABASE_DATA_API_DISABLED; do
        case "$v" in
            DB_HOST|PUBLIC_URL|SMTP_HOST|MAIL_FROM) echo "$v=https://ejemplo.invalid" >> "$envfile" ;;
            *) echo "$v=x1234567890abcdef1234567890abcdef" >> "$envfile" ;;
        esac
    done
    echo "DB_SSLMODE=disable" >> "$envfile"
    echo "DB_NAME=mvp_prueba" >> "$envfile"
    docker compose --project-directory "$REPO_ROOT" \
        -f "$REPO_ROOT/compose.yaml" --env-file "$envfile" \
        config --format json > "$rendered" 2> /dev/null
    n="$(jq -r '.services.app.healthcheck.test // [] | length' "$rendered")"
    [ "$n" -gt 0 ]
}

@test "punto2: healthcheck de app no usa credenciales" {
    envfile="$BATS_TEST_TMPDIR/.env"
    rendered="$BATS_TEST_TMPDIR/compose.json"
    : > "$envfile"
    for v in DB_HOST DB_PASSWORD DJANGO_SECRET PUBLIC_URL SMTP_HOST MAIL_FROM SUPABASE_DEDICATED_CONFIRMED SUPABASE_DATA_API_DISABLED; do
        case "$v" in
            DB_HOST|PUBLIC_URL|SMTP_HOST|MAIL_FROM) echo "$v=https://ejemplo.invalid" >> "$envfile" ;;
            *) echo "$v=x1234567890abcdef1234567890abcdef" >> "$envfile" ;;
        esac
    done
    echo "DB_SSLMODE=disable" >> "$envfile"
    echo "DB_NAME=mvp_prueba" >> "$envfile"
    docker compose --project-directory "$REPO_ROOT" \
        -f "$REPO_ROOT/compose.yaml" --env-file "$envfile" \
        config --format json > "$rendered" 2> /dev/null
    ! jq -r '.services.app.healthcheck.test | join(" ")' "$rendered" | grep -Eq 'PRETIX_DATABASE_PASSWORD|DJANGO_SECRET|SMTP_PASSWORD|REEMPLAZAR'
}

@test "punto2: README no dice que start.sh cubre el healthcheck" {
    ! grep -q "ya queda cubierto por el" "$REPO_ROOT/README.md"
    ! grep -q "start.sh.*standalone" "$REPO_ROOT/README.md"
}

@test "punto2: README describe el healthcheck real con HTTP /healthcheck/" {
    grep -q "/healthcheck/" "$REPO_ROOT/README.md"
}