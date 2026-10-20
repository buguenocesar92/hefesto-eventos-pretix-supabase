#!/usr/bin/env bats
# Tests del punto 4 de la revision: el README no debe afirmar que
# scripts/coolify-check.sh se ejecuta en CI antes de mergear a main;
# en el repo no hay CI configurado.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto4: README no menciona CI ni merge a main para coolify-check.sh" {
    ! grep -Eqi "CI antes de mergear|mergear a .main.|antes de mergear" "$REPO_ROOT/README.md"
}

@test "punto4: README dice como invocar el script a mano" {
    grep -Eq "bash scripts/coolify-check.sh" "$REPO_ROOT/README.md"
    grep -Eq "docker compose" "$REPO_ROOT/README.md"
    grep -Eq "\\bjq\\b" "$REPO_ROOT/README.md"
}