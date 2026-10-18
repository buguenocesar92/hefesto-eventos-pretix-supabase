#!/bin/sh
set -eu
python3 /opt/hefesto/validate.py
# Sin SMTP real: backend dummy de Django para no intentar envio. pretix 2026.8
# lee [mail] backend en pretix.cfg y lo aplica a EMAIL_BACKEND de Django.
if [ "${SMTP_READY:-false}" != true ] && [ "${BOOTSTRAP_MODE:-false}" != true ]; then
    export PRETIX_MAIL_BACKEND=django.core.mail.backends.dummy.EmailBackend
fi
exec /usr/local/bin/pretix "$@"
