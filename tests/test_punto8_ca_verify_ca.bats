#!/usr/bin/env bats
# Tests del punto 8 de la revision: preflight.sh y validate.py deben
# exigir la CA tanto con verify-full como con verify-ca.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "punto8: preflight.sh exige CA con verify-full y verify-ca" {
    grep -q "verify-full|verify-ca" "$REPO_ROOT/ops/preflight.sh"
}

@test "punto8: validate.py exige CA con verify-full y verify-ca" {
    # Debe chequear ambos modos para sslrootcert.
    grep -Eq "verify-full.*verify-ca|verify-ca.*verify-full" "$REPO_ROOT/ops/validate.py"
}

@test "punto8: preflight.sh no exige CA con disable" {
    # El case solo cubre verify-full|verify-ca; disable queda fuera.
    case_line="$(grep -n 'verify-full|verify-ca' "$REPO_ROOT/ops/preflight.sh" | head -1)"
    [ -n "$case_line" ]
}

@test "punto8: validate.py no exige CA con disable" {
    # La condicion no debe incluir disable.
    ! grep -Eq "verify-full.*disable.*verify-ca|verify-ca.*disable.*verify-full" "$REPO_ROOT/ops/validate.py"
}