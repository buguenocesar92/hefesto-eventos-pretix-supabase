from pretix.settings import *

LOGGING['handlers']['mail_admins']['include_html'] = True
STORAGES["staticfiles"]["BACKEND"] = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'

# --- Hefesto: correo desactivado sin SMTP ---
# Copia literal del production_settings.py de pretix/standalone:2026.8.0 (arriba)
# mas este bloque. Sin SMTP confirmado (SMTP_READY!=true) se usa el backend
# dummy de Django: no se intenta ningun envio. compose.yaml lo monta en app y
# periodic sobre /pretix/src/production_settings.py.
import os as _hefesto_os
if (_hefesto_os.environ.get('SMTP_READY', 'false') != 'true'
        and _hefesto_os.environ.get('BOOTSTRAP_MODE', 'false') != 'true'):
    EMAIL_BACKEND = 'django.core.mail.backends.dummy.EmailBackend'
