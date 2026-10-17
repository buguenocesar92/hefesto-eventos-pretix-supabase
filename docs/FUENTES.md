# Fuentes · consultadas 2026-10-16
- https://github.com/pretix/pretix/tree/v2026.8.0
- https://github.com/pretix/pretix/blob/v2026.8.0/deployment/docker/pretix.bash
- https://github.com/pretix/pretix/blob/v2026.8.0/deployment/docker/supervisord/pretixtask.conf
- https://github.com/pretix/pretix/blob/v2026.8.0/src/pretix/settings.py
- https://github.com/pretix/pretix/blob/v2026.8.0/src/pretix/base/models/auth.py
- https://docs.pretix.eu/self-hosting/config/
- https://docs.pretix.eu/self-hosting/installation/docker_smallscale/
- https://docs.pretix.eu/self-hosting/installation/general/
- https://hub.docker.com/r/pretix/standalone/tags
- https://supabase.com/docs/guides/database/connecting-to-postgres

Versión elegida: etiqueta publicada 2026.8.0, fijada por digest; no se usa latest de desarrollo. La documentación web puede avanzar respecto a esa etiqueta; las opciones críticas se contrastan con settings/entrypoint de v2026.8.0. Este kit adapta despliegue/configuración y limita Celery a dos procesos sin modificar el código del motor.

Conexión PostgreSQL/sslmode/sslrootcert son opciones nativas. La ruta Supabase preparada no implica una prueba ejecutada: debe validarse con las migraciones exactas y el entorno real. No se sustituyen locks por un pool transaccional ni se usan réplicas para inventario.
