#!/usr/bin/env bats
# Tests del punto 3 de la revision: DB_ALLOW_INTERNAL_HOST no debe aparecer
# en el README porque ningun codigo la lee.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto3: README no menciona DB_ALLOW_INTERNAL_HOST" {
    ! grep -q "DB_ALLOW_INTERNAL_HOST" "$REPO_ROOT/README.md"
}

@test "punto3: codigo del kit no lee DB_ALLOW_INTERNAL_HOST" {
    ! grep -rq "DB_ALLOW_INTERNAL_HOST" "$REPO_ROOT/ops" "$REPO_ROOT/scripts" 2>/dev/null
    ! grep -q "DB_ALLOW_INTERNAL_HOST" "$REPO_ROOT/compose.yaml"
}

@test "punto3: README advierte que no hay chequeo de host interno" {
    grep -Eqi "no hay chequeo|sin chequeo" "$REPO_ROOT/README.md"
}