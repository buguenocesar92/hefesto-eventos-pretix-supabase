#!/usr/bin/env bats
# Tests del punto 6 de la revision: el README debe advertir que las
# instalaciones manuales previas deben fijar COMPOSE_PROJECT_NAME para
# conservar los volumenes files y redis_data.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto6: README menciona fijar COMPOSE_PROJECT_NAME=hefesto-eventos" {
    grep -Eq "COMPOSE_PROJECT_NAME=hefesto-eventos" "$REPO_ROOT/README.md"
}

@test "punto6: README explica que sin esa variable los volumenes cambian de nombre" {
    grep -Eqi "volumen" "$REPO_ROOT/README.md"
    grep -Eq "files|redis_data" "$REPO_ROOT/README.md"
}

@test "punto6: compose.yaml raiz no declara name fijo" {
    ! grep -q "^name:" "$REPO_ROOT/compose.yaml"
}