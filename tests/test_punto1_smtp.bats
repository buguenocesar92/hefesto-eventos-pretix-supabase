#!/usr/bin/env bats
# Tests del punto 1 de la revision: la desactivacion de SMTP debe ocurrir
# en ops/start.sh y ops/periodic.sh, no en ops/validate.py.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto1: validate.py no debe setear PRETIX_MAIL_BACKEND" {
    ! grep -q "PRETIX_MAIL_BACKEND" "$REPO_ROOT/ops/validate.py"
}

@test "punto1: validate.py no debe mutar el bloque SMTP cuando SMTP_READY=false" {
    ! grep -q "os.environ\[.PRETIX_MAIL_BACKEND.\]" "$REPO_ROOT/ops/validate.py"
}

@test "punto1: start.sh debe exportar PRETIX_MAIL_BACKEND cuando SMTP_READY=false y no bootstrap" {
    grep -Eq 'SMTP_READY.*!=.*true' "$REPO_ROOT/ops/start.sh"
    grep -Eq 'BOOTSTRAP_MODE.*!=.*true' "$REPO_ROOT/ops/start.sh"
    grep -q "PRETIX_MAIL_BACKEND" "$REPO_ROOT/ops/start.sh"
}

@test "punto1: periodic.sh debe exportar PRETIX_MAIL_BACKEND cuando SMTP_READY=false y no bootstrap" {
    grep -Eq 'SMTP_READY.*!=.*true' "$REPO_ROOT/ops/periodic.sh"
    grep -Eq 'BOOTSTRAP_MODE.*!=.*true' "$REPO_ROOT/ops/periodic.sh"
    grep -q "PRETIX_MAIL_BACKEND" "$REPO_ROOT/ops/periodic.sh"
}

@test "punto1: start.sh exporta PRETIX_MAIL_BACKEND antes del exec" {
    # La exportacion debe aparecer antes de la linea de exec.
    awk '/PRETIX_MAIL_BACKEND/{found=NR; next} /^exec /{exec_line=NR; exit} END{exit !(found && exec_line && found < exec_line)}' "$REPO_ROOT/ops/start.sh"
}

@test "punto1: periodic.sh exporta PRETIX_MAIL_BACKEND antes del bucle" {
    # La exportacion debe aparecer antes del while.
    awk '/PRETIX_MAIL_BACKEND/{found=NR; next} /^while/{loop_line=NR; exit} END{exit !(found && loop_line && found < loop_line)}' "$REPO_ROOT/ops/periodic.sh"
}