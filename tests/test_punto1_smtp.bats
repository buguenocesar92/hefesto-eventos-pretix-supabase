#!/usr/bin/env bats
# Punto 1 de la revision: sin SMTP real (SMTP_READY!=true) el EMAIL_BACKEND
# efectivo de pretix debe ser el dummy de Django. Se comprueba importando la
# configuracion real dentro de la imagen fijada por digest.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
IMG='pretix/standalone:2026.8.0@sha256:ec17c2f761f7ad51e6dfc71d5036ea3241f8abf867cc66e015093b24c03c77de'
DUMMY='django.core.mail.backends.dummy.EmailBackend'
MARK='# --- Hefesto: correo desactivado sin SMTP ---'
MOUNT='./ops/production_settings.py:/pretix/src/production_settings.py:ro'

# Imprime settings.EMAIL_BACKEND efectivo con SMTP_READY=$1 y BOOTSTRAP_MODE=$2.
email_backend() {
    docker run --rm --entrypoint sh \
        -e PRETIX_DJANGO_SECRET=x \
        -e PRETIX_PRETIX_DATADIR=/tmp/pretixdata \
        -e SMTP_READY="$1" -e BOOTSTRAP_MODE="$2" \
        -v "$REPO_ROOT/ops/production_settings.py:/pretix/src/production_settings.py:ro" \
        -v "$REPO_ROOT/ops/pretix.cfg:/etc/pretix/pretix.cfg:ro" \
        "$IMG" -c 'cd /pretix/src && DJANGO_SETTINGS_MODULE=production_settings python3 -c "from django.conf import settings; print(settings.EMAIL_BACKEND)"' \
        | tail -n 1
}

# Imprime el bloque del servicio $1 de compose.yaml.
service_block() {
    awk -v s="  $1:" '$0==s{f=1;next} /^  [a-z]+:$/{f=0} /^[a-z]/{f=0} f' "$REPO_ROOT/compose.yaml"
}

@test "punto1: SMTP_READY=false deja EMAIL_BACKEND dummy" {
    b="$(email_backend false false)"
    echo "EMAIL_BACKEND=$b"
    [ "$b" = "$DUMMY" ]
}

@test "punto1: SMTP_READY=true conserva el backend original de pretix" {
    b="$(email_backend true false)"
    echo "EMAIL_BACKEND=$b"
    [ -n "$b" ]
    [ "$b" != "$DUMMY" ]
}

@test "punto1: BOOTSTRAP_MODE=true conserva el backend original de pretix" {
    b="$(email_backend false true)"
    echo "EMAIL_BACKEND=$b"
    [ -n "$b" ]
    [ "$b" != "$DUMMY" ]
}

@test "punto1: ops/production_settings.py empieza con el original de la imagen sin cambios" {
    orig="$(docker run --rm --entrypoint cat "$IMG" /pretix/src/production_settings.py)"
    ours="$(awk -v m="$MARK" '$0==m{exit} {print}' "$REPO_ROOT/ops/production_settings.py")"
    [ -n "$orig" ]
    [ "$orig" = "$ours" ]
    grep -qxF "$MARK" "$REPO_ROOT/ops/production_settings.py"
}

@test "punto1: app y periodic montan ops/production_settings.py; migrate no" {
    service_block app | grep -qF -- "$MOUNT"
    service_block periodic | grep -qF -- "$MOUNT"
    ! service_block migrate | grep -qF -- "$MOUNT"
    [ "$(grep -cF -- "$MOUNT" "$REPO_ROOT/compose.yaml")" -eq 2 ]
}

@test "punto1: no queda el mecanismo no comprobado PRETIX_MAIL_BACKEND" {
    ! grep -q "PRETIX_MAIL_BACKEND" "$REPO_ROOT/ops/start.sh"
    ! grep -q "PRETIX_MAIL_BACKEND" "$REPO_ROOT/ops/periodic.sh"
    ! grep -q "PRETIX_MAIL_BACKEND" "$REPO_ROOT/ops/validate.py"
}
