#!/usr/bin/env bash
# Verifica que el compose del kit cumple el contrato de Coolify.
# - Genera un .env temporal con valores ficticios por cada ${VAR} del compose.
# - Renderiza el compose con docker compose config --format json.
# - Comprueba los puntos 1 y 2 del contrato (sin privileges, sin name fijos).
# - Para supabase-pg: comprueba que DB_NAME y DB_SSLMODE lleguen al render.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d -p "${TMPDIR:-/tmp}")"
trap 'rm -rf "$WORK"' EXIT

COMPOSES=("compose.yaml")

# Variables que se tratan como host/URL en el .env ficticio.
HOST_VARS_REGEX='^(DB_HOST|PUBLIC_URL|SMTP_HOST|MAIL_FROM)$'

# Extrae los nombres de variables ${VAR}, ${VAR:-x}, ${VAR:?x} del compose.
extract_vars() {
    grep -oE '\$\{[A-Z_][A-Z0-9_]*(:[^}]*)?\}' "$1" \
        | sed -E 's/^\$\{([A-Z_][A-Z0-9_]*).*/\1/' \
        | sort -u
}

# Genera un .env ficticio en $2 a partir del compose $1.
gen_env() {
    local src="$1" out="$2"
    : > "$out"
    while IFS= read -r v; do
        [ -z "$v" ] && continue
        if [[ "$v" =~ $HOST_VARS_REGEX ]]; then
            echo "$v=https://ejemplo.invalid" >> "$out"
        else
            echo "$v=x1234567890abcdef1234567890abcdef" >> "$out"
        fi
    done < <(extract_vars "$src")
    # Para supabase-pg, además DB_SSLMODE=disable y DB_NAME=mvp_prueba.
    echo "DB_SSLMODE=disable" >> "$out"
    echo "DB_NAME=mvp_prueba" >> "$out"
}

# Falla si el YAML tiene un name: explícito a nivel raíz o en redes/volúmenes.
check_named() {
    local src="$1" failures=0
    # Root name:
    if grep -qE '^name:' "$src"; then
        echo "FAIL: raiz: name fijo declarado en YAML"
        failures=$((failures + 1))
    fi
    # Networks/volumes con name:
    if grep -qE '^[[:space:]]+name:' "$src"; then
        echo "FAIL: YAML: name fijo declarado en red o volumen"
        failures=$((failures + 1))
    fi
    return "$failures"
}

# Comprueba contrato punto 1 sobre los servicios sin profiles del render.
check_no_profile_violations() {
    local rendered="$1" failures=0
    local services
    services="$(jq -r '
            .services
            | to_entries[]
            | select((.value.profiles // []) | length == 0)
            | .key
        ' "$rendered")"
    while IFS= read -r svc; do
        [ -z "$svc" ] && continue
        # ports / container_name / privileged / cap_add / devices / security_opt.
        for field in ports container_name cap_add devices; do
            local n
            n="$(jq -r --arg s "$svc" --arg f "$field" \
                '(.services[$s][$f] // []) | length' "$rendered")"
            if [ "$n" != "0" ]; then
                echo "FAIL: $svc: campo prohibido $field presente"
                failures=$((failures + 1))
            fi
        done
        local priv
        priv="$(jq -r --arg s "$svc" '.services[$s].privileged // false' "$rendered")"
        if [ "$priv" = "true" ]; then
            echo "FAIL: $svc: privileged activo"
            failures=$((failures + 1))
        fi
        local nm pid ipc
        nm="$(jq -r --arg s "$svc" '.services[$s].network_mode // ""' "$rendered")"
        pid="$(jq -r --arg s "$svc" '.services[$s].pid // ""' "$rendered")"
        ipc="$(jq -r --arg s "$svc" '.services[$s].ipc // ""' "$rendered")"
        [ "$nm" = "host" ] && { echo "FAIL: $svc: network_mode host"; failures=$((failures + 1)); }
        [ "$pid" = "host" ] && { echo "FAIL: $svc: pid host"; failures=$((failures + 1)); }
        [ "$ipc" = "host" ] && { echo "FAIL: $svc: ipc host"; failures=$((failures + 1)); }
        local secopt
        secopt="$(jq -r --arg s "$svc" '.services[$s].security_opt // [] | .[]' "$rendered" || true)"
        if [ -n "$secopt" ] && printf '%s\n' "$secopt" | grep -q "unconfined"; then
            echo "FAIL: $svc: security_opt unconfined"
            failures=$((failures + 1))
        fi
        # binds fuera del repo o docker.sock.
        local binds
        binds="$(jq -r --arg s "$svc" '
            (.services[$s].volumes // [])[]
            | select(type == "object")
            | .source // empty
        ' "$rendered")"
        while IFS= read -r b; do
            [ -z "$b" ] && continue
            case "$b" in
                /var/run/docker.sock)
                    echo "FAIL: $svc: bind docker.sock"
                    failures=$((failures + 1))
                    ;;
                /*)
                    if [[ "$b" != "$REPO_ROOT"* ]]; then
                        echo "FAIL: $svc: bind fuera del repo ($b)"
                        failures=$((failures + 1))
                    fi
                    ;;
            esac
        done <<< "$binds"
    done <<< "$services"
    return "$failures"
}

# Para supabase-pg: el DSN debe llegar al servicio web como PRETIX_DATABASE_NAME
# y PRETIX_DATABASE_SSLMODE. Se valida con jq sobre services.app.environment.
check_supabase_pg_values() {
    local rendered="$1" failures=0
    if ! jq -e '.services.app.environment.PRETIX_DATABASE_NAME=="mvp_prueba" and .services.app.environment.PRETIX_DATABASE_SSLMODE=="disable"' "$rendered" > /dev/null 2>&1; then
        echo "FAIL: app: DB_NAME/DB_SSLMODE no llegan al servicio web"
        failures=$((failures + 1))
    fi
    return "$failures"
}

main() {
    local failed=0
    for compose in "${COMPOSES[@]}"; do
        local path="$REPO_ROOT/$compose"
        if [ ! -f "$path" ]; then
            echo "FAIL: no existe $path"
            failed=1
            continue
        fi
        local base env rendered
        base="$(basename "$compose" .yaml)"
        env="$WORK/$base.env"
        rendered="$WORK/$base.json"
        gen_env "$path" "$env"
        if ! docker compose --project-directory "$REPO_ROOT" \
                -f "$path" --env-file "$env" \
                config --format json > "$rendered" 2> "$WORK/$base.err"; then
            echo "FAIL: $compose no renderiza:"
            sed 's/^/  /' "$WORK/$base.err"
            failed=1
            continue
        fi
        local rc=0
        check_named "$path" || rc=1
        check_no_profile_violations "$rendered" || rc=1
        check_supabase_pg_values "$rendered" || rc=1
        if [ "$rc" -eq 0 ]; then
            echo "OK: $compose"
        else
            failed=1
        fi
    done
    exit "$failed"
}

main "$@"