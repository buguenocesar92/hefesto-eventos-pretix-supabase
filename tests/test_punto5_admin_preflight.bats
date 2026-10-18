#!/usr/bin/env bats
# Tests del punto 5 de la revision: el README debe explicar como crear
# el administrador (servicio migrate, sin start.sh) y los requisitos
# del rol para que ops/preflight.sql pase.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto5a: README explica crear admin por CLI contra el servicio migrate" {
    grep -Eq "migrate" "$REPO_ROOT/README.md"
    grep -Eq "createsuperuser" "$REPO_ROOT/README.md"
}

@test "punto5a: README indica que el admin se crea antes del primer arranque de app" {
    grep -Eq "antes del primer arranque|servicio migrate" "$REPO_ROOT/README.md"
}

@test "punto5b: README dice que el rol debe llamarse pretix_app" {
    grep -Eq "pretix_app" "$REPO_ROOT/README.md"
}

@test "punto5b: README dice que el rol debe ser NOINHERIT" {
    grep -Eqi "NOINHERIT|no.inherit" "$REPO_ROOT/README.md"
}

@test "punto5b: README dice que el rol debe ser dueno de mvp_<slug>" {
    grep -Eq "mvp_" "$REPO_ROOT/README.md"
}